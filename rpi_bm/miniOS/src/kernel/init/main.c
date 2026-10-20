#include "kernel/boot.h"
#include "platform.h"
#include "sched.h"
#include "fs/vfs.h"
#include "fs/minifs.h"
#include "fs/devfs.h"
#include "fs/bootfs.h"
#include "driver_model.h"

static int start_init_process(void)
{
    struct vfs_file *file = t113_vfs_open("/init", VFS_O_RDONLY);
    uint32_t size = file ? t113_vfs_file_size(file) : 0;
    uint32_t pages = (size + 4095u) / 4096u;
    void *image = pages ? t113_alloc_pages(pages, 1) : 0;
    int bytes = image ? t113_vfs_read(file, image, size) : -1;
    t113_vfs_close(file);

    int pid = bytes < 0 ? -1
            : t113_create_init_user_process(image, (uint32_t)bytes);
    if (image)
        t113_free_pages(image, pages);
    return pid;
}

/* Common subsystem ordering. Hardware setup is supplied by platform hooks. */
void kernel_boot(uint32_t page_pool_base, uint32_t physical_memory_end)
{
    if (page_pool_base >= physical_memory_end)
        kernel_platform_panic("invalid physical page pool");
    t113_page_alloc_init(page_pool_base,
                         physical_memory_end - page_pool_base);

    t113_vfs_init();
    if (t113_bootfs_mount_vfs() < 0)
        kernel_platform_panic("cannot mount boot filesystem at /boot");
    if (t113_minifs_mount_rootdev() < 0)
        kernel_platform_panic("cannot mount root filesystem");
    if (t113_devfs_init() < 0)
        kernel_platform_panic("cannot mount devfs at /dev");

    t113_driver_core_init();
    kernel_platform_interrupt_init();
    t113_sched_init();
    kernel_platform_console_irq_init();

    if (start_init_process() < 0)
        kernel_platform_panic("cannot load /init");

    kernel_platform_timer_init();
    kernel_platform_enable_interrupts();
    for (;;)
        kernel_platform_idle();
}
