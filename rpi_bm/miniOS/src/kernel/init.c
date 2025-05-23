/*struct mm_struct init_mm = {
    .mm_rb          = RB_ROOT,
    .pgd            = swapper_pg_dir,  // 内核主页表物理地址
    .mm_users       = ATOMIC_INIT(2),  // 引用计数
    .mm_count       = ATOMIC_INIT(1),
    .mmap_lock      = __SPIN_LOCK_UNLOCKED(init_mm.mmap_lock),
    .page_table_lock = __SPIN_LOCK_UNLOCKED(init_mm.page_table_lock),
    .mmlist         = LIST_HEAD_INIT(init_mm.mmlist),
};

void  paging_init(void) {
    // 1. 初始化 swapper_pg_dir
    map_kernel();  // 建立内核代码/数据的映射
    map_mem();     // 映射物理内存

    // 2. 加载 TTBR1
    cpu_switch_mm(swapper_pg_dir, &init_mm);
}

*/