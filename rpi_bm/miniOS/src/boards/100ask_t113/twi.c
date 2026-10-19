/*
 * Allwinner TWI (I2C) controller, sun6i-a31 / sun20i-d1 flavour of the
 * Marvell mv64xxx core, driven by polling (no IRQ). Each probed controller
 * registers a numbered i2c_adapter; the TWI index is derived from the MMIO
 * base so "twi2" becomes i2c adapter 2.
 *
 * Differences from the classic mv64xxx that matter here:
 *   - INT_FLAG is write-1-to-clear (writing it also lets the state machine
 *     continue), and
 *   - SCL = Fin / (10 * (M + 1) * 2^N)   (N base 0), Fin = APB1 = 24 MHz.
 */
#include "platform.h"
#include "platform_device.h"
#include "i2c.h"
#include "twi.h"
#include "board.h"

#define TWI_ADDR    0x00u
#define TWI_XADDR   0x04u
#define TWI_DATA    0x08u
#define TWI_CNTR    0x0cu
#define TWI_STAT    0x10u
#define TWI_CCR     0x14u
#define TWI_SRST    0x18u
#define TWI_EFR     0x1cu
#define TWI_LCR     0x20u

#define CNTR_A_ACK      (1u << 2)
#define CNTR_INT_FLAG   (1u << 3)
#define CNTR_M_STP      (1u << 4)
#define CNTR_M_STA      (1u << 5)
#define CNTR_BUS_EN     (1u << 6)

/* TWI_LCR: manual line control, used for bus recovery. */
#define LCR_SDA_CTL_EN  (1u << 0)
#define LCR_SDA_CTL     (1u << 1)
#define LCR_SCL_CTL_EN  (1u << 2)
#define LCR_SCL_CTL     (1u << 3)
#define LCR_SDA_STATE   (1u << 4)
#define LCR_SCL_STATE   (1u << 5)

#define STAT_START          0x08u
#define STAT_RESTART        0x10u
#define STAT_ADDR_W_ACK     0x18u
#define STAT_ADDR_W_NACK    0x20u
#define STAT_DATA_W_ACK     0x28u
#define STAT_ADDR_R_ACK     0x40u
#define STAT_ADDR_R_NACK    0x48u
#define STAT_DATA_R_ACK     0x50u
#define STAT_DATA_R_NACK    0x58u
#define STAT_IDLE           0xf8u

#define TWI_APB_HZ      24000000u
#define TWI_TIMEOUT_US  10000u

struct t113_twi {
    uint32_t base;
    uint32_t last_stat;         /* STAT seen when the last step failed */
    int last_err;
    const struct t113_twi_platform_data *pdata;
    uint32_t ccr;               /* restored after a soft reset */
    int stuck_reported;         /* print "SDA stuck" once per episode */
    struct i2c_adapter adap;
};

static struct t113_twi twi_ctrl[I2C_MAX_ADAPTERS];

static const char *const twi_names[I2C_MAX_ADAPTERS] = {
    "twi0", "twi1", "twi2", "twi3",
};

static inline uint32_t twi_rd(struct t113_twi *t, uint32_t reg)
{
    return mmio_read32(t->base + reg);
}

static inline void twi_wr(struct t113_twi *t, uint32_t reg, uint32_t v)
{
    mmio_write32(t->base + reg, v);
}

static int twi_wait_flag(struct t113_twi *t)
{
    for (uint32_t us = 0; us < TWI_TIMEOUT_US; ++us) {
        if (twi_rd(t, TWI_CNTR) & CNTR_INT_FLAG)
            return 0;
        t113_udelay(1);
    }
    return -ETIMEDOUT;
}

/* Wait for the next state and compare STAT; remember failures for dump. */
static int twi_check(struct t113_twi *t, uint32_t expect)
{
    if (twi_wait_flag(t) < 0) {
        t->last_stat = twi_rd(t, TWI_STAT);
        t->last_err = -ETIMEDOUT;
        return -ETIMEDOUT;
    }
    uint32_t stat = twi_rd(t, TWI_STAT);
    if (stat == expect)
        return 0;
    t->last_stat = stat;
    t->last_err = -EIO;
    return -EIO;
}

/* Kick the state machine with `bits` (clearing a pending INT_FLAG). */
static int twi_step(struct t113_twi *t, uint32_t bits, uint32_t expect)
{
    twi_wr(t, TWI_CNTR, CNTR_BUS_EN | CNTR_INT_FLAG | bits);
    return twi_check(t, expect);
}

static void twi_stop(struct t113_twi *t)
{
    twi_wr(t, TWI_CNTR, CNTR_BUS_EN | CNTR_INT_FLAG | CNTR_M_STP);
    for (uint32_t us = 0; us < TWI_TIMEOUT_US; ++us) {
        if (!(twi_rd(t, TWI_CNTR) & CNTR_M_STP) &&
            twi_rd(t, TWI_STAT) == STAT_IDLE)
            return;
        t113_udelay(1);
    }
}

/*
 * I2C bus recovery: a slave interrupted mid-byte (power-up glitch, reset of
 * the master) can keep SDA low forever and the controller then can't issue
 * START. Switch SCL/SDA to plain GPIOs, clock SCL by hand (open-drain style:
 * drive low / release to input) up to 9 times until the slave lets go of
 * SDA, generate a STOP, then hand the pins back to the TWI function.
 * pins[0] must be SCL and pins[1] SDA (board data order).
 */
static void od_release(uint32_t port, uint32_t pin)
{
    t113_gpio_set_function(port, pin, T113_GPIO_IN);
}

static void od_low(uint32_t port, uint32_t pin)
{
    t113_gpio_set_value(port, pin, 0);
    t113_gpio_set_function(port, pin, T113_GPIO_OUT);
}

static int twi_bus_recover(struct t113_twi *t)
{
    if (twi_rd(t, TWI_LCR) & LCR_SDA_STATE) {
        t->stuck_reported = 0;
        return 0;
    }

    int verbose = !t->stuck_reported;
    t->stuck_reported = 1;
    const struct t113_twi_platform_data *pd = t->pdata;
    if (!pd || pd->num_pins < 2) {
        if (verbose)
            t113_uart_puts("twi: SDA stuck low, no pin data for recovery\n");
        return -EBUSY;
    }
    const struct t113_pin *scl = &pd->pins[0], *sda = &pd->pins[1];

    if (verbose) {
        t113_uart_puts(t->adap.name);
        t113_uart_puts(": SDA stuck low, GPIO recovery: SDA after each SCL pulse =");
    }
    od_release(scl->port, scl->pin);
    od_release(sda->port, sda->pin);
    t113_udelay(10);

    int pulses = 0;
    for (; pulses < 9; ++pulses) {
        if (t113_gpio_get_value(sda->port, sda->pin))
            break;
        od_low(scl->port, scl->pin);
        t113_udelay(10);
        od_release(scl->port, scl->pin);
        t113_udelay(10);
        if (verbose)
            t113_uart_putc(t113_gpio_get_value(sda->port, sda->pin) ? '1' : '0');
    }
    /* STOP: SDA low while SCL high, then release SDA. */
    od_low(scl->port, scl->pin);
    t113_udelay(10);
    od_low(sda->port, sda->pin);
    t113_udelay(10);
    od_release(scl->port, scl->pin);
    t113_udelay(10);
    od_release(sda->port, sda->pin);
    t113_udelay(10);

    uint32_t scl_lvl = t113_gpio_get_value(scl->port, scl->pin);
    uint32_t sda_lvl = t113_gpio_get_value(sda->port, sda->pin);

    /* Back to TWI function and a clean controller state. */
    t113_pinmux_apply(pd->pins, pd->num_pins);
    twi_wr(t, TWI_SRST, 1u);
    for (uint32_t us = 0; us < TWI_TIMEOUT_US && (twi_rd(t, TWI_SRST) & 1u); ++us)
        t113_udelay(1);
    twi_wr(t, TWI_CCR, t->ccr);
    twi_wr(t, TWI_EFR, 0);
    twi_wr(t, TWI_CNTR, CNTR_BUS_EN);

    int ok = sda_lvl && (twi_rd(t, TWI_LCR) & LCR_SDA_STATE);
    if (ok)
        t->stuck_reported = 0;
    if (verbose || ok) {
        t113_uart_puts(verbose ? "\n" : "");
        t113_uart_puts(t->adap.name);
        t113_uart_puts(ok ? ": bus recovered, SDA high (GPIO SCL="
                          : ": SDA still low after recovery (GPIO SCL=");
        t113_uart_putc(scl_lvl ? '1' : '0');
        t113_uart_puts(" SDA=");
        t113_uart_putc(sda_lvl ? '1' : '0');
        t113_uart_puts(")\n");
    }
    return ok ? 0 : -EBUSY;
}

static int twi_start(struct t113_twi *t, int repeated)
{
    if (!repeated) {
        if (twi_bus_recover(t) < 0)
            return -EBUSY;
        /* First START: no INT_FLAG pending, so don't write it. */
        twi_wr(t, TWI_CNTR, CNTR_BUS_EN | CNTR_M_STA);
        return twi_check(t, STAT_START);
    }
    return twi_step(t, CNTR_M_STA, STAT_RESTART);
}

static int twi_xfer_msg(struct t113_twi *t, struct i2c_msg *msg, int first)
{
    int read = (msg->flags & I2C_M_RD) != 0;
    int ret = twi_start(t, !first);
    if (ret < 0)
        return ret;

    twi_wr(t, TWI_DATA, (uint32_t)(msg->addr << 1) | (read ? 1u : 0u));
    ret = twi_step(t, 0, read ? STAT_ADDR_R_ACK : STAT_ADDR_W_ACK);
    if (ret < 0)
        return ret == -EIO ? -ENXIO : ret;      /* address NACK: no chip */

    for (uint16_t i = 0; i < msg->len; ++i) {
        if (read) {
            int last = i + 1u == msg->len;
            ret = twi_step(t, last ? 0 : CNTR_A_ACK,
                           last ? STAT_DATA_R_NACK : STAT_DATA_R_ACK);
            if (ret < 0)
                return ret;
            msg->buf[i] = (uint8_t)twi_rd(t, TWI_DATA);
        } else {
            twi_wr(t, TWI_DATA, msg->buf[i]);
            ret = twi_step(t, 0, STAT_DATA_W_ACK);
            if (ret < 0)
                return ret;
        }
    }
    return 0;
}

static int twi_master_xfer(struct i2c_adapter *adap, struct i2c_msg *msgs,
                           int num)
{
    struct t113_twi *t = adap->algo_data;
    int ret = 0;

    for (int i = 0; i < num && ret == 0; ++i)
        ret = twi_xfer_msg(t, &msgs[i], i == 0);
    twi_stop(t);
    return ret < 0 ? ret : num;
}

static const char *twi_stat_name(uint32_t stat)
{
    switch (stat) {
    case 0x00: return "bus error";
    case STAT_START: return "START sent";
    case STAT_RESTART: return "RESTART sent";
    case STAT_ADDR_W_ACK: return "addr+W ACK";
    case STAT_ADDR_W_NACK: return "addr+W NACK (no chip at address)";
    case STAT_DATA_W_ACK: return "data ACK";
    case 0x30: return "data NACK";
    case 0x38: return "arbitration lost";
    case STAT_ADDR_R_ACK: return "addr+R ACK";
    case STAT_ADDR_R_NACK: return "addr+R NACK";
    case STAT_DATA_R_ACK: return "data read, ACK";
    case STAT_DATA_R_NACK: return "data read, NACK";
    case STAT_IDLE: return "idle";
    default: return "?";
    }
}

/* TWI_LCR bit4 = SDA level, bit5 = SCL level (both should idle high). */
static void twi_dump(struct i2c_adapter *adap)
{
    struct t113_twi *t = adap->algo_data;
    uint32_t lcr = twi_rd(t, TWI_LCR);

    t113_uart_puts(adap->name);
    t113_uart_puts(": last fail stat ");
    t113_uart_puthex(t->last_stat);
    t113_uart_puts(" (");
    t113_uart_puts(twi_stat_name(t->last_stat));
    t113_uart_puts(t->last_err == -ETIMEDOUT ? ", timeout" : "");
    t113_uart_puts(")\n");
    t113_uart_puts(adap->name);
    t113_uart_puts(": CNTR ");
    t113_uart_puthex(twi_rd(t, TWI_CNTR));
    t113_uart_puts(" STAT ");
    t113_uart_puthex(twi_rd(t, TWI_STAT));
    t113_uart_puts(" CCR ");
    t113_uart_puthex(twi_rd(t, TWI_CCR));
    t113_uart_puts(" LCR ");
    t113_uart_puthex(lcr);
    t113_uart_puts(" SDA=");
    t113_uart_putc((lcr & (1u << 4)) ? '1' : '0');
    t113_uart_puts(" SCL=");
    t113_uart_putc((lcr & (1u << 5)) ? '1' : '0');
    t113_uart_puts("\n");
    if (!(lcr & (3u << 4)))
        t113_uart_puts("  -> SDA/SCL both low: no pull-up / module unpowered / jumper on EMAC?\n");
    else if (!(lcr & (1u << 4)) || !(lcr & (1u << 5)))
        t113_uart_puts("  -> one line held low: bus stuck or wiring problem\n");

    /*
     * The board config enables the SoC's internal pull-ups, so "high" alone
     * doesn't prove anything is attached. Drop them briefly: if the lines
     * stay high, an external pull-up (camera module / carrier board) is
     * really connected to PE12/PE13.
     */
    const struct t113_twi_platform_data *pd = t->pdata;
    if (!pd || !pd->num_pins)
        return;
    for (uint32_t i = 0; i < pd->num_pins; ++i)
        t113_gpio_set_pull(pd->pins[i].port, pd->pins[i].pin, T113_PULL_NONE);
    t113_udelay(500);
    uint32_t ext = twi_rd(t, TWI_LCR);
    for (uint32_t i = 0; i < pd->num_pins; ++i)
        t113_gpio_set_pull(pd->pins[i].port, pd->pins[i].pin, pd->pins[i].pull);

    t113_uart_puts(adap->name);
    t113_uart_puts(": internal pull-ups off -> SDA=");
    t113_uart_putc((ext & (1u << 4)) ? '1' : '0');
    t113_uart_puts(" SCL=");
    t113_uart_putc((ext & (1u << 5)) ? '1' : '0');
    t113_uart_puts((ext & (3u << 4)) == (3u << 4)
                   ? "  (external pull-ups present on the SoC side)\n"
                   : "  (NO external pull-up on PE12/13)\n");
}

static const struct i2c_algorithm twi_algo = {
    .master_xfer = twi_master_xfer,
    .dump = twi_dump,
};

/* Pick M (4 bits) and N (3 bits) for the requested SCL rate. */
static uint32_t twi_ccr(uint32_t hz)
{
    for (uint32_t n = 0; n < 8u; ++n) {
        uint32_t div = 10u * (1u << n) * hz;
        uint32_t m = (TWI_APB_HZ + div - 1u) / div;     /* round SCL down */
        if (m >= 1u && m - 1u <= 15u)
            return ((m - 1u) << 3) | n;
    }
    return (15u << 3) | 7u;
}

static int t113_twi_probe(struct platform_device *pdev)
{
    const struct t113_twi_platform_data *pdata = pdev->dev.platform_data;
    const struct resource *mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);

    if (!mem || mem->start < T113_TWI0_BASE ||
        (mem->start - T113_TWI0_BASE) % T113_TWI_STRIDE)
        return -ENODEV;
    uint32_t idx = (mem->start - T113_TWI0_BASE) / T113_TWI_STRIDE;
    if (idx >= I2C_MAX_ADAPTERS)
        return -ENODEV;

    struct t113_twi *t = &twi_ctrl[idx];
    t->base = mem->start;

    /* Bus clock gate on, reset deasserted. */
    uint32_t bgr = mmio_read32(T113_CCU_TWI_BGR);
    mmio_write32(T113_CCU_TWI_BGR, bgr & ~(1u << (16u + idx)));
    mmio_write32(T113_CCU_TWI_BGR, bgr | (1u << idx) | (1u << (16u + idx)));

    if (pdata)
        t113_pinmux_apply(pdata->pins, pdata->num_pins);

    twi_wr(t, TWI_SRST, 1u);
    for (uint32_t us = 0; us < TWI_TIMEOUT_US && (twi_rd(t, TWI_SRST) & 1u); ++us)
        t113_udelay(1);
    t->ccr = twi_ccr(pdata && pdata->bus_hz ? pdata->bus_hz : 100000u);
    twi_wr(t, TWI_CCR, t->ccr);
    twi_wr(t, TWI_EFR, 0);
    twi_wr(t, TWI_CNTR, CNTR_BUS_EN);

    t->pdata = pdata;
    t->adap.name = twi_names[idx];
    twi_bus_recover(t);
    t->adap.nr = (int)idx;
    t->adap.name = twi_names[idx];
    t->adap.algo = &twi_algo;
    t->adap.algo_data = t;
    t->adap.dev = &pdev->dev;
    int ret = i2c_add_numbered_adapter(&t->adap);
    if (ret < 0)
        return ret;

    platform_set_drvdata(pdev, &t->adap);
    platform_dev_info(pdev, "i2c adapter registered, polling mode");
    return 0;
}

static void t113_twi_remove(struct platform_device *pdev)
{
    struct i2c_adapter *adap = platform_get_drvdata(pdev);
    struct t113_twi *t = adap->algo_data;

    i2c_del_adapter(adap);
    twi_wr(t, TWI_CNTR, 0);
}

static const struct of_device_id t113_twi_of_match[] = {
    { .compatible = "allwinner,sun20i-d1-i2c" },
    { .compatible = "allwinner,sun6i-a31-i2c" },
    { 0 },
};

struct platform_driver t113_twi_driver = {
    .probe = t113_twi_probe,
    .remove = t113_twi_remove,
    .driver = { .name = "mv64xxx_i2c" },
    .of_match_table = t113_twi_of_match,
};
