#include <mem.h>
#include <peripherals/base.h>
#include <mm.h>
#include <mmu.h>
#include <printf.h>
#include <sched.h>
// 全局页目录指针（需在链接脚本中定义对齐）
typedef uint64_t pte_T;  // 正确：pte_T 是整数类型
extern pte_T pg_dir[] __attribute__((aligned(PAGE_SIZE)));
#define NULL 0
static u16 mem_map [ PAGING_PAGES ] = {0,};

void *allocate_memory(int bytes) {
    int pages = bytes / PAGE_SIZE;

    if (bytes % PAGE_SIZE) {
        pages++;
    }

    return get_free_pages(pages);
}

void free_memory(void *base) {
    u64 page_num = (((u64)base) - LOW_MEMORY) / PAGE_SIZE;
    int pages = mem_map[page_num];

    printf("free_memory at address %X page num: %d pages: %d\n", base, page_num, pages);

    for (int i=0; i<pages; i++) {
        mem_map[page_num + i] = 0;
    }
}

void *get_free_pages(int num_pages) {
    int start_index = 0;
    int count = 0;
 //jimmy aset i=10
    for (int i=0; i<PAGING_PAGES; i++) {
        if (mem_map[i] == 0) {
            //not yet allocated...
            if (!count) {
                start_index = i;
            }

            count++;

            if (count == num_pages) {
                mem_map[start_index] = count; //number of pages allocated

                for (int c=1; c<count; c++) {
                    mem_map[c + start_index] = 1;
                }

                void *p = (void *)(LOW_MEMORY + (start_index * PAGE_SIZE));

                printf("get_free_pages returning %d pages starting at %d at address %X\n", count, start_index, p);

                return p;
            }
        } else {
            count = 0;
        }
    }
}

void *memcpy(void *dest, const void *src, u32 n) {
    //simple implementation...
    u8 *bdest = (u8 *)dest;
    u8 *bsrc = (u8 *)src;

    for (int i=0; i<n; i++) {
        bdest[i] = bsrc[i];
    }

    return dest;
}
    
void* alloc_page() {
    return (void*)get_free_pages(1);  // 分配 1 页（4KB）
}

//user_virtual mem

//unsigned long alloc_user_pgd(void) {
  //  unsigned long pgd_phys = get_free_page(); // 获取物理页
   // pgd_t *pgd_virt = phys_to_virt(pgd_phys);
    
    // 清零新页表
   // memzero(pgd_virt, 0, PAGE_SIZE);
    
    // 复制内核映射（高地址空间）
   // for (int i = KERNEL_PGD_INDEX; i < PTRS_PER_PGD; i++) {
   //     pgd_virt[i] = init_mm.pgd[i];
   // }
    
  //  return pgd_phys;
//}

pud_t *pud_offset(pgd_t *pgd, unsigned long addr) {
    return (pud_t *)(pgd_val(*pgd) & ~(PAGE_SIZE-1)) + ((addr >> 30) & 0x1ff);
}
int pgd_table(pgd_t pgd) {
    return (pgd_val(pgd) & PGD_TYPE_MASK) == PGD_TYPE_TABLE;
}
 unsigned long pgd_index(unsigned long address)
{
    /*
     * 计算地址在PGD中的索引
     * 
     * PGD索引 = (address >> PGDIR_SHIFT) & (PTRS_PER_PGD - 1)
     * 
     * 其中：
     * - PGDIR_SHIFT 是PGD级别的位移量
     * - PTRS_PER_PGD 是PGD中的条目数
     */
    return (address >> PGDIR_SHIFT) & (PTRS_PER_PGD - 1);
}

// 分配并初始化一个新的PGD（顶级页表）
pgd_t *alloc_new_pgd(void)
{
    // 1. 分配一个页面作为PGD
    pgd_t *pgd = (pgd_t *)allocate_kernel_page();
    if (!pgd) {
        printf("Failed to allocate new PGD\n");
        return NULL;
    }
    
    // 2. 清空整个PGD
    memzero(pgd, PAGE_SIZE);
    
    // 3. 如果需要，可以在这里初始化一些固定映射
    // 例如设备内存映射等
    
    printf("Allocated new PGD at 0x%x\n", (unsigned long)pgd);
    return pgd;
}

unsigned long allocate_kernel_page() {
	unsigned long page = get_free_page();
	if (page == 0) {
		return 0;
	}
	return page + VA_START;
}



unsigned long allocate_user_page(struct task_struct *task, unsigned long va, int prot) {
    unsigned long page = get_free_page();
    if (!page) {
        return 0;
    }
    
    /* Map with user-accessible permissions */
    map_page(task, va, page, prot | PTE_USER);
    return va ? va : (page + VA_START);
}
void map_table_entry(unsigned long *pte, unsigned long va, unsigned long pa) {
	unsigned long index = va >> PAGE_SHIFT;
	index = index & (PTRS_PER_TABLE - 1);
	unsigned long entry = pa | MMU_PTE_FLAGS; 
	pte[index] = entry;
}

unsigned long map_table(unsigned long *table, unsigned long shift, unsigned long va, int* new_table) {
	unsigned long index = va >> shift;
	index = index & (PTRS_PER_TABLE - 1);
	if (!table[index]){
		*new_table = 1;
		unsigned long next_level_table = get_free_page();
		unsigned long entry = next_level_table | MM_TYPE_PAGE_TABLE;
		table[index] = entry;
		return next_level_table;
	} else {
		*new_table = 0;
	}
	return table[index] & PAGE_MASK;
}



void map_page(struct task_struct *task, unsigned long va, unsigned long page){
	unsigned long pgd;

    
	if (!task->mm->pgd) {
		task->mm->pgd = get_free_page();
		task->mm->kernel_pages[++task->mm->kernel_pages_count] = task->mm->pgd;
	}
	pgd = task->mm->pgd;
	int new_table;
	unsigned long pud = map_table((unsigned long *)(pgd + VA_START), PGD_SHIFT, va, &new_table);
	if (new_table) {
		task->mm->kernel_pages[++task->mm->kernel_pages_count] = pud;
	}
	unsigned long pmd = map_table((unsigned long *)(pud + VA_START) , PUD_SHIFT, va, &new_table);
	if (new_table) {
		task->mm->kernel_pages[++task->mm->kernel_pages_count] = pmd;
	}
	unsigned long pte = map_table((unsigned long *)(pmd + VA_START), PMD_SHIFT, va, &new_table);
	if (new_table) {
		task->mm->kernel_pages[++task->mm->kernel_pages_count] = pte;
	}
	map_table_entry((unsigned long *)(pte + VA_START), va, page);
	struct user_page p = {page, va};
	task->mm->user_pages[task->mm->user_pages_count++] = p;
}
unsigned long get_free_page()
{
	for (int i = 0; i < PAGING_PAGES; i++){
		if (mem_map[i] == 0){
			mem_map[i] = 1;
			unsigned long page = LOW_MEMORY + i*PAGE_SIZE;
			memzero(page + VA_START, PAGE_SIZE);
			return page;
		}
	}
	return 0;
}

void free_page(unsigned long p){
	mem_map[(p - LOW_MEMORY) / PAGE_SIZE] = 0;
}



//Jimmy add

/*
// Memory mapping functions
int map_user_stack(struct task_struct *tsk, unsigned long stack_vaddr, unsigned long size)
{
    // 1. Validate stack range
    if (stack_vaddr < LOW_MEMORY || (stack_vaddr + size) > HIGH_MEMORY) {
        return -EFAULT;
    }

    // 2. Map each stack page
    for (unsigned long va = stack_vaddr; va < stack_vaddr + size; va += PAGE_SIZE) {
        unsigned long pa = get_free_page();
        if (!pa) {
            // Cleanup already mapped pages
            while (va > stack_vaddr) {
                va -= PAGE_SIZE;
                unmap_page(tsk->mm.pgd, va);
            }
            return -ENOMEM;
        }

        if (map_page(tsk->mm.pgd, va, pa, PTE_VALID | PTE_USER | PTE_WRITABLE) != 0) {
            free_page(pa);
            while (va > stack_vaddr) {
                va -= PAGE_SIZE;
                unmap_page(tsk->mm.pgd, va);
            }
            return -ENOMEM;
        }

        memzero(va, PAGE_SIZE);  // Clear the page
    }

    // 3. Add guard page
    if (map_page(tsk->mm.pgd, stack_vaddr - PAGE_SIZE, 0, PTE_NONE) != 0) {
        // Cleanup stack pages if guard page fails
        for (unsigned long va = stack_vaddr; va < stack_vaddr + size; va += PAGE_SIZE) {
            unmap_page(tsk->mm.pgd, va);
        }
        return -ENOMEM;
    }

    tsk->mm.stack_start = stack_vaddr;
    tsk->mm.stack_end = stack_vaddr + size;
    return 0;
}

// Helper function to map a single page
int map_page(pgd_t *pgd, unsigned long va, unsigned long pa, unsigned long flags)
{
    pte_T *pte;
    
    // Get PTE entry (allocates page tables if needed)
    pte = pte_alloc(pgd, va);
    if (!pte) return -1;
    
    // Set the PTE
    *pte = pa | flags | pte_TYPE_PAGE;
    
    // Flush TLB
    flush_tlb_page(va);
    
    return 0;
}

// Page table entry allocation
pte_T *pte_alloc(pgd_t *pgd, unsigned long va)
{
    pud_t *pud;
    pmd_t *pmd;
    
    // Walk page tables
    pud = pud_offset(pgd, va);
    if (!pud_present(*pud)) {
        unsigned long pud_page = get_free_page();
        if (!pud_page) return NULL;
        set_pud(pud, __pud(pud_page | PTE_VALID | pte_TABLE));
    }
    
    pmd = pmd_offset(pud, va);
    if (!pmd_present(*pmd)) {
        unsigned long pmd_page = get_free_page();
        if (!pmd_page) return NULL;
        set_pmd(pmd, __pmd(pmd_page | PTE_VALID | pte_TABLE));
    }
    
    return pte_offset_kernel(pmd, va);
}

*/
#define TD_VALID                   (1 << 0)
#define TD_BLOCK                   (0 << 1)
#define TD_TABLE                   (1 << 1)
#define TD_ACCESS                  (1 << 10)
#define TD_KERNEL_PERMS            (1L << 54)
#define TD_INNER_SHARABLE          (3 << 8)

#define TD_KERNEL_TABLE_FLAGS      (TD_TABLE | TD_VALID)
#define TD_KERNEL_BLOCK_FLAGS      (TD_ACCESS | TD_INNER_SHARABLE | TD_KERNEL_PERMS | (MATTR_NORMAL_NC_INDEX << 2) | TD_BLOCK | TD_VALID)
#define TD_DEVICE_BLOCK_FLAGS      (TD_ACCESS | TD_INNER_SHARABLE | TD_KERNEL_PERMS | (MATTR_DEVICE_nGnRnE_INDEX << 2) | TD_BLOCK | TD_VALID)

#define MATTR_DEVICE_nGnRnE        0x0
#define MATTR_NORMAL_NC            0x44
#define MATTR_DEVICE_nGnRnE_INDEX  0
#define MATTR_NORMAL_NC_INDEX      1
#define MAIR_EL1_VAL               ((MATTR_NORMAL_NC << (8 * MATTR_NORMAL_NC_INDEX)) | MATTR_DEVICE_nGnRnE << (8 * MATTR_DEVICE_nGnRnE_INDEX))

#define ID_MAP_PAGES           6
#define ID_MAP_TABLE_SIZE      (ID_MAP_PAGES * PAGE_SIZE)
#define KERNEL_MAP_PAGES           3
#define KERNEL_MAP_TABLE_SIZE      (KERNEL_MAP_PAGES * PAGE_SIZE)
#define ENTRIES_PER_TABLE      512
#define PGD_SHIFT              (PAGE_SHIFT + 3 * TABLE_SHIFT)
#define PUD_SHIFT              (PAGE_SHIFT + 2 * TABLE_SHIFT)
#define PMD_SHIFT              (PAGE_SHIFT + TABLE_SHIFT)
#define PUD_ENTRY_MAP_SIZE     (1 << PUD_SHIFT)


/*
void map_kernel_text() {
    u64 start = (u64)__text_start & PAGE_MASK;
    u64 end   = ((u64)__text_end + PAGE_SIZE - 1) & PAGE_MASK;

    for (u64 addr = start; addr < end; addr += PAGE_SIZE) {
        map_user_page(addr, addr, KERNEL_EXEC_FLAGS);  // 1:1 映射代码段
    }
}


void map_user_page(u64 task_pgd,u64 va, u64 pa, u64 flags) {
   
    //u64 *pgd = (u64 *)id_pgd_addr();  // 顶级页表基地址
 u64 *pgd = (u64 *)task_pgd;  

    u64 pgd_idx = (va >> 39) & 0x1FF;
    u64 pud_idx = (va >> 30) & 0x1FF;
    u64 pmd_idx = (va >> 21) & 0x1FF;
    u64 pte_idx = (va >> 12) & 0x1FF;
    printf(" pgd_idx:%x,pud_idx:%x,pmd_idx:%x,pte_idx:%x\n",pgd_idx,pud_idx,pmd_idx,pte_idx);

    u64 *pud, *pmd, *pte;

    if (!(pgd[pgd_idx] & 1)) {
        pud = alloc_page();
        memzero((u64)pud, PAGE_SIZE);
        pgd[pgd_idx] = __pa(pud) | TD_KERNEL_TABLE_FLAGS;
        printf(" pud%x\n",__pa(pud));  
    
    } else {
       // pud = (u64 *)((u64)pgd[pgd_idx] & PAGE_MASK + KERNEL_VIRT_OFFSET);
     //   pud = (u64 *)(((u64)pgd[pgd_idx] & PAGE_MASK) + KERNEL_VIRT_OFFSET);
         pud = (u64 *)__va(pgd[pgd_idx] & PAGE_MASK);
       printf(" else pud%x\n",pud); 
    }
printf(" before pmd%x\n",__pa(pmd));  
    if (!(pud[pud_idx] & 1)) {
        pmd = alloc_page();
        memzero((u64)pmd, PAGE_SIZE);
        pud[pud_idx] = __pa(pmd) | TD_KERNEL_TABLE_FLAGS;
              printf(" if pmd%x\n",__pa(pmd));  
    }
     else{
        //pmd = (u64 *)((u64)pud[pud_idx] & PAGE_MASK + KERNEL_VIRT_OFFSET);
      //  pmd = (u64 *)(((u64)pud[pud_idx] & PAGE_MASK) + KERNEL_VIRT_OFFSET);
        
         pmd = (u64 *)__va(pud[pud_idx] & PAGE_MASK);
        printf("else pmd %x\n",pmd);  
 
    }
    printf(" after  pmd%x\n",__pa(pmd));  

    if (!(pmd[pmd_idx] & 1)) {
        pte = alloc_page();
        memzero((u64)pte, PAGE_SIZE);
        pmd[pmd_idx] = __pa(pte) | TD_KERNEL_TABLE_FLAGS;
          printf("if pte %x\n",pte);
    } else {
      //  pte = (u64 *)((u64)pmd[pmd_idx] & PAGE_MASK + KERNEL_VIRT_OFFSET);
       // pte = (u64 *)(((u64)pmd[pmd_idx] & PAGE_MASK) + KERNEL_VIRT_OFFSET);
         pte = (u64 *)__va(pmd[pmd_idx] & PAGE_MASK);
    printf("else pte %x\n",pte);
    }
    


    printf("map_user_page:\n");

    printf("  pgd = %x, pud = %x, pmd = %x, pte = %x\n",__pa(pgd), __pa(pud), __pa(pmd), __pa(pte));
    printf("  pte_idx = 0x%x, write to = 0x%x\n", pte_idx, (u64)&pte[pte_idx]);
        // 最终 PTE 设置
    pte[pte_idx] = (pa & PAGE_MASK) | flags;
}


*/

void create_table_entry(u64 tbl, u64 next_tbl, u64 va, u64 shift, u64 flags) {
    u64 table_index = va >> shift;
    table_index &= (ENTRIES_PER_TABLE - 1);
    u64 descriptor = next_tbl | flags;
    *((u64 *)(tbl + (table_index << 3))) = descriptor;
}

void create_block_map(u64 pmd, u64 vstart, u64 vend, u64 pa) {
    vstart >>= SECTION_SHIFT;
    vstart &= (ENTRIES_PER_TABLE -1);

    vend >>= SECTION_SHIFT;
    vend--;
    vend &= (ENTRIES_PER_TABLE - 1);

    pa >>= SECTION_SHIFT;
    pa <<= SECTION_SHIFT;

    do {
        u64 _pa = pa;

        if (pa >= DEVICE_START) {
            _pa |= TD_DEVICE_BLOCK_FLAGS;
        } else {
            _pa |= TD_KERNEL_BLOCK_FLAGS;
        }

        *((u64 *)(pmd + (vstart << 3))) = _pa;
        pa += SECTION_SIZE;
        vstart++;
    } while(vstart <= vend);
}

 pte_t set_pte_ap(pte_t pte, unsigned long ap) {
    // 清除原有的 AP 位（AP[2:1] 在 bit[7:6]）
    pte_val(pte) &= ~(0b11 << 6);
    // 设置新的 AP 权限
    pte_val(pte) |= (ap & (0b11 << 6));
    return pte;
}
pmd_t *pmd_offset(pud_t *pud, unsigned long addr)
{
    return (pmd_t *)pud_page_vaddr(*pud) + pmd_index(addr);
}
bool pmd_present(pmd_t pmd)
{
    return pmd_val(pmd) & PMD_TYPE_MASK;  // Check if entry is a table or block
}
pte_t *pte_offset_kernel(pmd_t *pmd, unsigned long addr)
{
    return (pte_t *)pmd_page_vaddr(*pmd) + PTE_INDEX(addr);
}
phys_addr_t pud_page_paddr(pud_t pud)
{
    return pud_val(pud) & PHYS_MASK & PAGE_MASK;
}
void *pud_page_vaddr(pud_t pud)
{
    return (void *)__va(pud_page_paddr(pud));
}
//unsigned long pte_index(unsigned long addr) {
//    return (addr >> PTE_SHIFT) & PTE_INDEX_MASK;
//}
phys_addr_t pmd_page_paddr(pmd_t pmd)
{
    return pmd_val(pmd) & PHYS_MASK & PAGE_MASK;
}

void *pmd_page_vaddr(pmd_t pmd)
{
    return (void *)__va(pmd_page_paddr(pmd));
}

unsigned long pmd_index(unsigned long addr) {
    return (addr >> PMD_SHIFT) & PMD_INDEX_MASK;
}

void init_mmu() {


    u64 id_pgd = id_pgd_addr();

    memzero(id_pgd, ID_MAP_TABLE_SIZE);

    u64 map_base = 0;
    u64 tbl = id_pgd;
    u64 next_tbl = tbl + PAGE_SIZE;

    create_table_entry(tbl, next_tbl, map_base, PGD_SHIFT, TD_KERNEL_TABLE_FLAGS);

    tbl += PAGE_SIZE;
    next_tbl += PAGE_SIZE;

    u64 block_tbl = tbl;

    for (u64 i=0; i<4; i++) {
        create_table_entry(tbl, next_tbl, map_base, PUD_SHIFT, TD_KERNEL_TABLE_FLAGS);

        next_tbl += PAGE_SIZE;
        map_base += PUD_ENTRY_MAP_SIZE;

        block_tbl += PAGE_SIZE;

        u64 offset = BLOCK_SIZE * i;
        create_block_map(block_tbl, offset, offset + BLOCK_SIZE, offset);
    }
}
void init_kernel_mmu() {


    u64 kernel_pgd = kernel_pgd_addr();
    memzero(kernel_pgd, KERNEL_MAP_TABLE_SIZE);
    u64 tbl = kernel_pgd;
    // 映射内核代码段（只读）
    map_kernel_region(tbl, KERNEL_CODE_START, PHYS_CODE_START, (size_t)(KERNEL_CODE_END - KERNEL_CODE_START));
    // 映射内核数据段（读写）
    map_kernel_region(tbl, KERNEL_DATA_START, PHYS_DATA_START, (size_t)(KERNEL_DATA_END - KERNEL_DATA_START));
}

void map_kernel_region(uint64_t *pgd, uint64_t virt_start, uint64_t phys_start, size_t size) {
    uint64_t virt_end = virt_start + size;
    while (virt_start < virt_end) {
        // 逐级填充页表项（以2MB大页为例）
        uint64_t *pud = get_next_table(pgd, virt_start, LEVEL_PGD);
        uint64_t *pmd = get_next_table(pud, virt_start, LEVEL_PUD);
        uint64_t *pte = get_next_table(pmd, virt_start, LEVEL_PMD);
        
        // 直接映射为2MB大页（属性：特权只读/读写）
        *pte = (phys_start & 0xFFE00000) | 
               (ATTR_S1_IDX_DEVICE << 2) |  // 设备内存属性（MAIR索引）
               (0b01 << 10) |               // AF=1（已访问）
               (0b11 << 8)  |               // SH=内部共享
               (0b01 << 6)  |               // AP=内核读写，用户无访问
               (0b1 << 0);                  // 有效块描述符
        
        virt_start += 2 * 1024 * 1024;      // 步进2MB
        phys_start += 2 * 1024 * 1024;
    }
}
uint64_t *get_next_table(uint64_t *current_table, uint64_t vaddr, PageTableLevel level) {
    // 计算当前层级的页表索引
    int shift = 39 - level * 9;
    uint64_t index = (vaddr >> shift) & 0x1FF;  // 9位索引

    // 若表项无效，分配新页表
    if (!(current_table[index] & 0x1)) {
        uint64_t *new_table = alloc_page();  // 分配4KB页
        memzero(new_table, 4096);
        current_table[index] = (uint64_t)new_table | 0x3;  // 有效且为页表描述符
    }

    // 返回下一级页表物理地址（清除低12位属性）
    return (uint64_t*)(current_table[index] & ~0xFFF);
}




/* 创建页表项 */
static pte_T* pgd_create_table_entry(pte_T* tbl, uint64_t virt_addr, int level_shift) 
{
    // 计算当前层级的索引（9位）
    int index = (virt_addr >> level_shift) & (PTRS_PER_TABLE - 1);
    
    // 如果表项不存在则分配新页表
    if (!(tbl[index] & 0x1)) {
        pte_T* new_table = alloc_page();
        memzero(new_table, PAGE_SIZE);
        tbl[index] = (uint64_t)new_table | MM_TYPE_PAGE_TABLE;
    }
    
    // 返回下一级页表地址（清除低12位属性）
    return (pte_T*)(tbl[index] & ~(0xFFF));
}

/* 递归创建多级页表结构 */
static pte_T* create_pgd_entries(uint64_t virt_addr) 
{
    pte_T* current = pg_dir;
    
    // 处理PGD级别（Level 0）
    current = pgd_create_table_entry(current, virt_addr, PGD_SHIFT);
    // 处理PUD级别（Level 1）
    current = pgd_create_table_entry(current, virt_addr, PUD_SHIFT);
    // 处理PMD级别（Level 2）
    current = pgd_create_table_entry(current, virt_addr, PMD_SHIFT);
    
    return current;  // 返回PMD级别页表指针
}

/* 创建块映射（2MB大页） */
static void pgd_create_block_map(pte_T* pmd, uint64_t phys, 
                            uint64_t start_va, uint64_t end_va, 
                            uint64_t flags) 
{
    start_va >>= SECTION_SHIFT;
    end_va >>= SECTION_SHIFT;
    phys >>= SECTION_SHIFT;

    for (uint64_t idx = start_va; idx <= end_va; idx++) {
        pmd[idx] = (phys << SECTION_SHIFT) | flags | 0x1; // 有效块描述符
        phys++;
    }
}

/* 主初始化函数 
void __create_page_tables(void) 
{

    // 1. 清零页目录
    memzero(pg_dir, PAGE_SIZE);

    // 2. 创建内核映射的页表结构
    pte_T* pmd = create_pgd_entries(VA_START);

    // 低地址恒等映射（0x0 ~ 0x8000000
        pgd_create_block_map(pmd, 
                    0x0,                            // 物理起始地址
                    0x0,                       // 虚拟起始地址
                    0x8000000,     // 虚拟结束地址
                    MMU_FLAGS);
    // 3. 映射内核区域（物理0 -> VA_START）
    pgd_create_block_map(pmd, 
                    0x0,                            // 物理起始地址
                    VA_START,                       // 虚拟起始地址
                    VA_START + KERNEL_SIZE - 1,     // 虚拟结束地址
                    MMU_FLAGS);

    // 4. 映射设备内存区域
    pmd = create_pgd_entries(VA_START + DEVICE_BASE);
    pgd_create_block_map(pmd,
                    DEVICE_BASE,                    // 设备物理基址
                    VA_START + DEVICE_BASE,         // 设备虚拟基址
                    VA_START + DEVICE_END - 1,
                    MMU_DEVICE_FLAGS);

    // 5. 刷新TLB和缓存
   // __asm__ __volatile__ (
    //    "dsb sy\n"
    //    "tlbi vmalle1is\n"
     //   "dsb sy\n"
     //   "isb"
  //  );
}
*/
