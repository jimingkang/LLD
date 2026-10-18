#include "platform.h"
#include "sched.h"
#include "fs/vfs.h"
#include "fs/minifs.h"
#include "driver_model.h"

extern uint8_t __kernel_reserved_end[];

extern uint8_t __minifs_image_start[];
extern uint8_t __minifs_image_end[];

void kernel_main(uint32_t dram_size)
{
    t113_uart_init();
    t113_uart_puts("\nminiOS kernel: executing from DDR\n");
    t113_uart_puts("kernel entry=0x40200000 current-PC=");
    uint32_t pc;
    __asm__ volatile("mov %0, pc" : "=r"(pc));
    t113_uart_puthex(pc);
    t113_uart_putc('\n');

    t113_mmu_init();
    t113_uart_puts("MMU: SCTLR=");
    t113_uart_puthex(t113_mmu_is_enabled());
    t113_uart_puts(" TTBR0=");
    t113_uart_puthex(t113_mmu_ttbr0());
    t113_uart_putc('\n');

    uint32_t pool_base = ((uint32_t)(uintptr_t)__kernel_reserved_end + 0xfffu) & ~0xfffu;
    uint32_t dram_end = 0x40000000u + dram_size;
    if (pool_base >= dram_end) {
        t113_uart_puts("PANIC: kernel consumes all DDR\n");
        for (;;)
            __asm__ volatile("wfi");
    }
    t113_page_alloc_init(pool_base, dram_end - pool_base);
    t113_driver_core_init();

    t113_gic_init();
    t113_sched_init();
    t113_vfs_init();
    if (t113_minifs_mount_vfs(__minifs_image_start,
                             (uint32_t)(__minifs_image_end -
                                        __minifs_image_start)) < 0) {
        t113_uart_puts("PANIC: cannot mount embedded minifs\n");
        for (;;)
            __asm__ volatile("wfi");
    }
    struct vfs_file *init_file = t113_vfs_open("/init", VFS_O_RDONLY);
    uint32_t init_pages = init_file
                        ? (t113_vfs_file_size(init_file) + 4095u) / 4096u : 0;
    void *init_image = init_pages ? t113_alloc_pages(init_pages, 1) : 0;
    int init_size = init_image
                  ? t113_vfs_read(init_file, init_image,
                                  t113_vfs_file_size(init_file)) : -1;
    t113_vfs_close(init_file);
    int init_pid = init_size < 0 ? -1
                 : t113_create_init_user_process(init_image,
                                                 (uint32_t)init_size);
    if (init_image)
        t113_free_pages(init_image, init_pages);
    if (init_pid < 0) {
        t113_uart_puts("PANIC: cannot load /init from minifs\n");
        for (;;)
            __asm__ volatile("wfi");
    }
    t113_timer0_init();
    t113_uart_puts("GIC + Timer0 IRQ ready: expect one tick per second\n");
    __asm__ volatile("cpsie i" ::: "memory");
    for (;;)
        __asm__ volatile("wfi");
}
