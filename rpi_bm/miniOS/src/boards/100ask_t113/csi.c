/*
 * T113 CSIC parallel (DVP) camera interface — framework stage.
 *
 * Probe does the SoC-side bring-up a sensor needs before it can talk:
 *   - CSI bus clock gate on + reset deasserted   (CCU 0x0c1c)
 *   - NCSI0 pins PE0..PE11 muxed to function 2   (board platform data)
 *   - CSI master clock 0 = HOSC 24 MHz / M -> sensor XCLK on PE3 (CCU 0x0c08)
 *
 * Not done yet (needed for frame capture): CSI_TOP module clock (0x0c04,
 * from a PLL), MBUS gate for the capture DMA, parser/VINC programming and
 * the CSI/VINC interrupts.
 */
#include "platform.h"
#include "platform_device.h"
#include "camera.h"
#include "board.h"

#define CSI_BGR_GATE        (1u << 0)
#define CSI_BGR_RST         (1u << 16)
#define MCLK_GATE           (1u << 31)
#define MCLK_SRC_SHIFT      24u
#define MCLK_SRC_MASK       (7u << MCLK_SRC_SHIFT)
#define MCLK_SRC_HOSC       0u
#define MCLK_M_MASK         0x1fu

#define HOSC_HZ             24000000u
#define T113_NUM_CSI        1u

struct t113_csi {
    uint32_t top_base;
    uint32_t parser_base;
    uint32_t dma_base;
    int irq_parser;
    int irq_dma;
    uint32_t mclk_hz;
    int mclk_on;
};

static struct t113_csi csi_state[T113_NUM_CSI];

int t113_csi_mclk_running(uint32_t id)
{
    return id < T113_NUM_CSI && csi_state[id].mclk_on;
}

static uint32_t csi_mclk_enable(uint32_t hz)
{
    if (!hz || hz > HOSC_HZ)
        hz = HOSC_HZ;
    uint32_t div = (HOSC_HZ + hz - 1u) / hz;            /* never overclock */
    if (div > MCLK_M_MASK + 1u)
        div = MCLK_M_MASK + 1u;
    uint32_t v = mmio_read32(T113_CCU_CSI_MCLK0);
    v &= ~(MCLK_GATE | MCLK_SRC_MASK | MCLK_M_MASK);
    v |= (MCLK_SRC_HOSC << MCLK_SRC_SHIFT) | (div - 1u);
    mmio_write32(T113_CCU_CSI_MCLK0, v);
    mmio_write32(T113_CCU_CSI_MCLK0, v | MCLK_GATE);
    return HOSC_HZ / div;
}

static int t113_csi_probe(struct platform_device *pdev)
{
    const struct t113_csi_platform_data *pdata = pdev->dev.platform_data;
    const struct resource *top =
        platform_get_resource_byname(pdev, IORESOURCE_MEM, "top");
    const struct resource *parser =
        platform_get_resource_byname(pdev, IORESOURCE_MEM, "csi0");
    const struct resource *dma =
        platform_get_resource_byname(pdev, IORESOURCE_MEM, "vinc0");

    if (!pdata || !top || !parser || !dma ||
        top->start != T113_CSI_TOP_BASE || parser->start != T113_CSI0_BASE)
        return -ENODEV;

    struct t113_csi *csi = &csi_state[0];
    csi->top_base = top->start;
    csi->parser_base = parser->start;
    csi->dma_base = dma->start;
    csi->irq_parser = platform_get_irq(pdev, 0);
    csi->irq_dma = platform_get_irq(pdev, 1);

    uint32_t bgr = mmio_read32(T113_CCU_CSI_BGR);
    mmio_write32(T113_CCU_CSI_BGR, bgr & ~CSI_BGR_RST);
    mmio_write32(T113_CCU_CSI_BGR, bgr | CSI_BGR_GATE | CSI_BGR_RST);

    t113_pinmux_apply(pdata->pins, pdata->num_pins);

    csi->mclk_hz = csi_mclk_enable(pdata->mclk_hz);
    csi->mclk_on = 1;

    platform_set_drvdata(pdev, csi);
    platform_dev_info(pdev, "DVP pins + bus clock on, MCLK running");
    t113_uart_puts("csi0: mclk ");
    t113_uart_puthex(csi->mclk_hz);
    t113_uart_puts(" Hz (capture path not enabled yet)\n");
    return 0;
}

static void t113_csi_remove(struct platform_device *pdev)
{
    struct t113_csi *csi = platform_get_drvdata(pdev);

    mmio_write32(T113_CCU_CSI_MCLK0,
                 mmio_read32(T113_CCU_CSI_MCLK0) & ~MCLK_GATE);
    csi->mclk_on = 0;
}

static const struct of_device_id t113_csi_of_match[] = {
    { .compatible = "allwinner,sun8iw20p1-csi" },
    { 0 },
};

struct platform_driver t113_csi_driver = {
    .probe = t113_csi_probe,
    .remove = t113_csi_remove,
    .driver = { .name = "sunxi-csi" },
    .of_match_table = t113_csi_of_match,
};
