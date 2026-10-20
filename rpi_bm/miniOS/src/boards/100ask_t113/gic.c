#include "platform.h"
#include "platform_device.h"
#include "board.h"

#define GICD_CTLR          (T113_GIC_DIST_BASE + 0x000u)
#define GICD_TYPER         (T113_GIC_DIST_BASE + 0x004u)
#define GICD_IGROUPR(n)    (T113_GIC_DIST_BASE + 0x080u + 4u * (n))
#define GICD_ISENABLER(n)  (T113_GIC_DIST_BASE + 0x100u + 4u * (n))
#define GICD_ICENABLER(n)  (T113_GIC_DIST_BASE + 0x180u + 4u * (n))
#define GICD_ISPENDR(n)    (T113_GIC_DIST_BASE + 0x200u + 4u * (n))
#define GICD_ICPENDR(n)    (T113_GIC_DIST_BASE + 0x280u + 4u * (n))
#define GICD_ISACTIVER(n)  (T113_GIC_DIST_BASE + 0x300u + 4u * (n))
#define GICD_IPRIORITYR(n) (T113_GIC_DIST_BASE + 0x400u + 4u * (n))
#define GICD_ITARGETSR(n)  (T113_GIC_DIST_BASE + 0x800u + 4u * (n))
#define GICD_ICFGR(n)      (T113_GIC_DIST_BASE + 0xc00u + 4u * (n))

#define GICC_CTLR          (T113_GIC_CPU_BASE + 0x000u)
#define GICC_PMR           (T113_GIC_CPU_BASE + 0x004u)
#define GICC_BPR           (T113_GIC_CPU_BASE + 0x008u)
#define GICC_IAR           (T113_GIC_CPU_BASE + 0x00cu)
#define GICC_EOIR          (T113_GIC_CPU_BASE + 0x010u)
#define GICC_RPR           (T113_GIC_CPU_BASE + 0x014u)
#define GICC_HPPIR         (T113_GIC_CPU_BASE + 0x018u)

static inline void io_barrier(void)
{
    __asm__ volatile("dsb sy\n\tisb" ::: "memory");
}

void t113_gic_init(void)
{
    uint32_t lines;

    mmio_write32(GICC_CTLR, 0);
    mmio_write32(GICD_CTLR, 0);
    io_barrier();

    lines = ((mmio_read32(GICD_TYPER) & 0x1fu) + 1u) * 32u;
    if (lines > 1020u)
        lines = 1020u;

    /* SPIs are Group 0, level-triggered, routed to CPU0, and initially off. */
    for (uint32_t irq = 32; irq < lines; irq += 32) {
        mmio_write32(GICD_IGROUPR(irq / 32u), 0);
        mmio_write32(GICD_ICENABLER(irq / 32u), 0xffffffffu);
        mmio_write32(GICD_ICPENDR(irq / 32u), 0xffffffffu);
    }
    for (uint32_t irq = 32; irq < lines; irq += 16)
        mmio_write32(GICD_ICFGR(irq / 16u), 0);
    for (uint32_t irq = 32; irq < lines; irq += 4) {
        mmio_write32(GICD_IPRIORITYR(irq / 4u), 0xa0a0a0a0u);
        mmio_write32(GICD_ITARGETSR(irq / 4u), 0x01010101u);
    }

    mmio_write32(GICC_PMR, 0xf0u);
    mmio_write32(GICC_BPR, 0);
    mmio_write32(GICD_CTLR, 1u);
    mmio_write32(GICC_CTLR, 1u);
    io_barrier();
}

void t113_gic_enable_irq(uint32_t irq)
{
    mmio_write32(GICD_ISENABLER(irq / 32u), 1u << (irq % 32u));
    io_barrier();
}

uint32_t t113_gic_acknowledge(void)
{
    return mmio_read32(GICC_IAR);
}

void t113_gic_end_irq(uint32_t irq_ack)
{
    mmio_write32(GICC_EOIR, irq_ack);
    io_barrier();
}

uint32_t t113_gic_irq_state(uint32_t irq)
{
    uint32_t bit = 1u << (irq % 32u);
    uint32_t state = 0;
    if (mmio_read32(GICD_ISPENDR(irq / 32u)) & bit)
        state |= 1u;
    if (mmio_read32(GICD_ISACTIVER(irq / 32u)) & bit)
        state |= 2u;
    if (mmio_read32(GICD_ISENABLER(irq / 32u)) & bit)
        state |= 4u;
    return state;
}

uint32_t t113_gic_running_priority(void)
{
    return mmio_read32(GICC_RPR);
}

uint32_t t113_gic_highest_pending(void)
{
    return mmio_read32(GICC_HPPIR);
}

/*
 * Platform driver binding for the GIC. t113_gic_init() is still called
 * explicitly from kernel_main() (after the driver core is up), so probe only
 * validates the distributor/CPU-interface windows against the addresses the
 * code above is compiled with.
 */
struct t113_gic_chip {
    uint32_t dist_base;
    uint32_t cpu_base;
};

static struct t113_gic_chip gic_chip;

static int t113_gic_probe(struct platform_device *pdev)
{
    const struct resource *dist =
        platform_get_resource_byname(pdev, IORESOURCE_MEM, "dist");
    const struct resource *cpu =
        platform_get_resource_byname(pdev, IORESOURCE_MEM, "cpu");

    if (!dist || !cpu || dist->start != T113_GIC_DIST_BASE ||
        cpu->start != T113_GIC_CPU_BASE)
        return -ENODEV;
    gic_chip.dist_base = dist->start;
    gic_chip.cpu_base = cpu->start;
    platform_set_drvdata(pdev, &gic_chip);
    platform_dev_info(pdev, "bound (init deferred to t113_gic_init)");
    return 0;
}

static const struct of_device_id t113_gic_of_match[] = {
    { .compatible = "arm,cortex-a7-gic" },
    { .compatible = "arm,gic-400" },
    { 0 },
};

struct platform_driver t113_gic_driver = {
    .probe = t113_gic_probe,
    .driver = { .name = "gic-v2" },
    .of_match_table = t113_gic_of_match,
};
