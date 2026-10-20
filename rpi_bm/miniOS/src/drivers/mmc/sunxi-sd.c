/*
 * Minimal SD card block reader shared by miniBoot and miniOS: SMHC0 on
 * PF0..PF5, 1-bit bus,
 * polling, CPU FIFO access, CMD17 single-block reads only.
 *
 * Register layout per U-Boot drivers/mmc/sunxi_mmc.h (NCAT2: FIFO at
 * +0x200), clocks per mainline ccu-sun20i-d1.c (mmc0 mod clock 0x830 with a
 * fixed /2 post-divider, bus gate/reset 0x84c bit 0 / bit 16).
 */
#include "platform.h"
#include "sd.h"
#ifdef MINIOS_KERNEL
#include "mutex.h"
static struct mutex sd_lock;
#define SD_LOCK()   mutex_lock(&sd_lock)
#define SD_UNLOCK() mutex_unlock(&sd_lock)
#else
#define SD_LOCK()   ((void)0)
#define SD_UNLOCK() ((void)0)
#endif

#define SMHC0_BASE      0x04020000u
#define CCU_MMC0_CLK    (T113_CCU_BASE + 0x830u)
#define CCU_MMC_BGR     (T113_CCU_BASE + 0x84cu)
#define PF_CFG0         (T113_PIO_BASE + 5u * 0x30u + 0x00u)
#define PF_PULL0        (T113_PIO_BASE + 5u * 0x30u + 0x24u)

#define GCTRL           0x000u
#define CLKCR           0x004u
#define TMOUT           0x008u
#define WIDTH           0x00cu
#define BLKSZ           0x010u
#define BYTECNT         0x014u
#define CMD             0x018u
#define ARG             0x01cu
#define RESP0           0x020u
#define RINT            0x038u
#define STATUS          0x03cu
#define NTSR            0x05cu
#define HWRST           0x078u
#define FIFO            0x200u

#define GCTRL_RESET     0x7u
#define GCTRL_AHB       (1u << 31)
#define CLK_ENABLE      (1u << 16)
#define CLK_MASK_D0     (1u << 31)

#define C_RESP          (1u << 6)
#define C_LONG          (1u << 7)
#define C_CRC           (1u << 8)
#define C_DATA          (1u << 9)
#define C_WRITE         (1u << 10)
#define C_WAIT_PRE      (1u << 13)
#define C_INIT          (1u << 15)
#define C_UPCLK         (1u << 21)
#define C_START         (1u << 31)

#define R_CMD_DONE      (1u << 2)
#define R_DATA_OVER     (1u << 3)
#define R_RESP_TMO      (1u << 8)
#define R_ERR           0xbfc2u

#define S_FIFO_EMPTY    (1u << 2)
#define S_FIFO_FULL     (1u << 3)
#define S_CARD_BUSY     (1u << 9)

#define SRC_HZ          12000000u       /* HOSC 24 MHz, /2 post-div */

static uint32_t rca;
static int high_capacity;
static int ready;

static inline uint32_t rd(uint32_t r) { return mmio_read32(SMHC0_BASE + r); }
static inline void wr(uint32_t r, uint32_t v) { mmio_write32(SMHC0_BASE + r, v); }

/* Rough busy-wait; the SPL has no timer set up. ~1 us at >= 400 MHz. */
static void spin_us(uint32_t us)
{
    for (volatile uint32_t i = 0; i < us * 100u; ++i) { }
}

static int reset_ctrl(void)
{
    wr(GCTRL, GCTRL_RESET);
    for (int i = 0; i < 100000; ++i)
        if (!(rd(GCTRL) & GCTRL_RESET))
            return 0;
    return -1;
}

static int update_clk(void)
{
    wr(CMD, C_START | C_UPCLK | C_WAIT_PRE);
    for (int i = 0; i < 1000000; ++i) {
        if (!(rd(CMD) & C_START)) {
            wr(RINT, 0xffffffffu);
            return 0;
        }
    }
    return -1;
}

static void set_clock(uint32_t hz)
{
    uint32_t div = (SRC_HZ + 2u * hz - 1u) / (2u * hz);
    if (hz >= SRC_HZ)
        div = 0;                        /* bypass: 12 MHz */
    uint32_t v = rd(CLKCR) & ~CLK_ENABLE;
    wr(CLKCR, v | CLK_MASK_D0);
    update_clk();
    v = (v & ~0xffu) | div;
    wr(CLKCR, v | CLK_ENABLE | CLK_MASK_D0);
    update_clk();
    wr(CLKCR, v | CLK_ENABLE);
}

/* flags: C_RESP / C_LONG / C_CRC; returns 0 or -1, resp in *r0. */
static int send_cmd(uint32_t idx, uint32_t arg, uint32_t flags, uint32_t *r0)
{
    uint32_t c = C_START | idx | flags;
    if (idx == 0)
        c |= C_INIT;
    wr(RINT, 0xffffffffu);
    wr(ARG, arg);
    wr(CMD, c);
    for (int i = 0; i < 2000000; ++i) {
        uint32_t ri = rd(RINT);
        if (ri & R_ERR) {
            reset_ctrl();
            update_clk();
            wr(RINT, 0xffffffffu);
            return (ri & R_RESP_TMO) ? -2 : -1;
        }
        if (ri & R_CMD_DONE) {
            if (r0)
                *r0 = (flags & C_LONG) ? rd(RESP0 + 12) : rd(RESP0);
            wr(RINT, 0xffffffffu);
            return 0;
        }
    }
    return -1;
}

static int sd_init_unlocked(void)
{
    uint32_t r = 0;

    /* clocks, pins (PF0..PF5 func 2, pull-up except CLK = PF2) */
    uint32_t bgr = mmio_read32(CCU_MMC_BGR);
    mmio_write32(CCU_MMC_BGR, bgr & ~(1u << 16));
    spin_us(10);
    mmio_write32(CCU_MMC_BGR, bgr | 1u | (1u << 16));
    mmio_write32(CCU_MMC0_CLK, 1u << 31);
    mmio_write32(PF_CFG0, (mmio_read32(PF_CFG0) & 0xff000000u) | 0x00222222u);
    mmio_write32(PF_PULL0, (mmio_read32(PF_PULL0) & ~0xfffu) | 0x545u);

    if (reset_ctrl() < 0)
        return -1;
    wr(HWRST, 0);
    spin_us(10);
    wr(HWRST, 1);
    wr(NTSR, rd(NTSR) | (1u << 31));
    wr(TMOUT, 0xffffff40u);
    wr(WIDTH, 0);
    set_clock(400000u);

    send_cmd(0, 0, 0, 0);                                   /* GO_IDLE */
    int v2 = send_cmd(8, 0x1aa, C_RESP | C_CRC, &r) == 0 && (r & 0xfff) == 0x1aa;

    for (int i = 0; ; ++i) {                                /* ACMD41 */
        if (send_cmd(55, 0, C_RESP | C_CRC, 0) < 0)
            return -2;
        if (send_cmd(41, (v2 ? 0x40000000u : 0u) | 0x00ff8000u, C_RESP, &r) < 0)
            return -3;
        if (r & (1u << 31))
            break;
        if (i > 1000)
            return -4;
        spin_us(1000);
    }
    high_capacity = (r >> 30) & 1;

    if (send_cmd(2, 0, C_RESP | C_LONG | C_CRC, 0) < 0)      /* ALL_SEND_CID */
        return -5;
    if (send_cmd(3, 0, C_RESP | C_CRC, &r) < 0)              /* SEND_RCA */
        return -6;
    rca = r >> 16;
    if (send_cmd(7, rca << 16, C_RESP | C_CRC, 0) < 0)       /* SELECT */
        return -7;
    for (int i = 0; i < 1000000 && (rd(STATUS) & S_CARD_BUSY); ++i) { }
    if (!high_capacity && send_cmd(16, 512, C_RESP | C_CRC, 0) < 0)
        return -8;

    set_clock(SRC_HZ);                                      /* 12 MHz */
    ready = 1;
    return high_capacity ? 2 : 1;
}

int t113_sd_init(void)
{
#ifdef MINIOS_KERNEL
    mutex_init(&sd_lock);
#endif
    SD_LOCK();
    int result = sd_init_unlocked();
    SD_UNLOCK();
    return result;
}

static int read_block(uint32_t lba, uint32_t *dst)
{
    wr(GCTRL, rd(GCTRL) | GCTRL_AHB);
    wr(BLKSZ, 512);
    wr(BYTECNT, 512);
    wr(RINT, 0xffffffffu);
    wr(ARG, high_capacity ? lba : lba * 512u);
    wr(CMD, C_START | 17u | C_RESP | C_CRC | C_DATA | C_WAIT_PRE);

    uint32_t words = 0;
    for (int spins = 0; words < 128 && spins < 4000000; ++spins) {
        if (rd(RINT) & R_ERR)
            break;
        while (words < 128 && !(rd(STATUS) & S_FIFO_EMPTY))
            dst[words++] = rd(FIFO);
    }
    for (int i = 0; i < 4000000; ++i) {
        uint32_t ri = rd(RINT);
        if (ri & R_ERR)
            break;
        if ((ri & (R_CMD_DONE | R_DATA_OVER)) == (R_CMD_DONE | R_DATA_OVER)) {
            wr(RINT, 0xffffffffu);
            return words == 128 ? 0 : -1;
        }
    }
    reset_ctrl();
    update_clk();
    wr(RINT, 0xffffffffu);
    return -1;
}

static int sd_read_unlocked(uint32_t lba, uint32_t count, void *buf)
{
    uint32_t *dst = (uint32_t *)buf;
    if (!ready || ((uintptr_t)buf & 3u))
        return -1;
    for (uint32_t i = 0; i < count; ++i, dst += 128) {
        int tries = 3;
        while (read_block(lba + i, dst) < 0)
            if (--tries == 0)
                return -1;
    }
    return 0;
}

int t113_sd_read(uint32_t lba, uint32_t count, void *buf)
{
    SD_LOCK();
    int result = sd_read_unlocked(lba, count, buf);
    SD_UNLOCK();
    return result;
}

static int write_block(uint32_t lba, const uint32_t *src)
{
    wr(GCTRL, rd(GCTRL) | GCTRL_AHB);
    wr(BLKSZ, 512);
    wr(BYTECNT, 512);
    wr(RINT, 0xffffffffu);
    wr(ARG, high_capacity ? lba : lba * 512u);
    wr(CMD, C_START | 24u | C_RESP | C_CRC | C_DATA | C_WRITE | C_WAIT_PRE);

    uint32_t words = 0;
    for (int spins = 0; words < 128 && spins < 4000000; ++spins) {
        if (rd(RINT) & R_ERR)
            break;
        while (words < 128 && !(rd(STATUS) & S_FIFO_FULL))
            wr(FIFO, src[words++]);
    }
    for (int i = 0; i < 4000000; ++i) {
        uint32_t ri = rd(RINT);
        if (ri & R_ERR)
            break;
        if ((ri & (R_CMD_DONE | R_DATA_OVER)) == (R_CMD_DONE | R_DATA_OVER)) {
            while (rd(STATUS) & S_CARD_BUSY) { }
            wr(RINT, 0xffffffffu);
            return words == 128 ? 0 : -1;
        }
    }
    reset_ctrl();
    update_clk();
    wr(RINT, 0xffffffffu);
    return -1;
}

static int sd_write_unlocked(uint32_t lba, uint32_t count, const void *buf)
{
    const uint32_t *src = (const uint32_t *)buf;
    if (!ready || ((uintptr_t)buf & 3u))
        return -1;
    for (uint32_t i = 0; i < count; ++i, src += 128) {
        int tries = 3;
        while (write_block(lba + i, src) < 0)
            if (--tries == 0)
                return -1;
    }
    return 0;
}

int t113_sd_write(uint32_t lba, uint32_t count, const void *buf)
{
    SD_LOCK();
    int result = sd_write_unlocked(lba, count, buf);
    SD_UNLOCK();
    return result;
}
