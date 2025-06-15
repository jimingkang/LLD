#include <mem.h>
#include <peripherals/base.h>
#include <mm.h>
#include <mmu.h>
#include <printf.h>
#include <fork.h>
#include <sched.h>
// 全局页目录指针（需在链接脚本中定义对齐）
typedef uint64_t pte_T;  // 正确：pte_T 是整数类型
extern pte_T pg_dir[] __attribute__((aligned(PAGE_SIZE)));
#define NULL 0
static u16 mem_map [ PAGING_PAGES ] = {0,};



void *allocate_memory(int bytes) {
    printf("allocate_memory");
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

unsigned long allocate_pagetable_page() {
    unsigned long phys = get_free_page();
    if (!phys) return 0;
    memzero(__va(phys), PAGE_SIZE);  // 内核态可访问初始化
    return phys;
}


unsigned long allocate_kernel_page() {
   // printf("allocate_kernel_page\r\n");
	unsigned long page = get_free_page();
	if (page == 0) {
		return 0;
        
	}
    void *kva = __va(page);  
     memzero(kva, PAGE_SIZE);
	return page+VA_START ;
}
unsigned long map_table_level(unsigned long parent_va, int shift,
                              unsigned long va, int *new_tbl)
{
    unsigned long index = (va >> shift) & LEVEL_MASK;   // LEVEL_MASK = 0x1ff
    unsigned long entry_addr = parent_va + (index << 3);

    unsigned long entry_val;
    asm volatile("ldr %0, [%1]" : "=r"(entry_val) : "r"(entry_addr));

    if ((entry_val & VALID_BIT) == 0) {
        // 需要新分配一个表页
        unsigned long new_table_pa = get_free_page();
        if (!new_table_pa) {
            *new_tbl = 0;
            return 0;
        }
        // 清零物理页的新表
        memzero((void *)__va(new_table_pa), PAGE_SIZE);

        // 构造 entry：把“物理地址”+“属性标志”一并写到这一项里
        unsigned long new_entry = (new_table_pa & ~(PAGE_SIZE - 1)) | VALID_BIT | TABLE_BIT;
        asm volatile("str %0, [%1]" :: "r"(new_entry), "r"(entry_addr));
  // crucial barrier:
        asm volatile("dsb ish\n isb" ::: "memory");
        *new_tbl = 1;
        // **这里必须返回物理页号 (对齐到 4 KB)**
        return (new_table_pa & ~(PAGE_SIZE - 1));
    } else {
        // 已经存在下一层表页。entry_val 带了标志位，需要去掉低 12 位才拿到 PA
        unsigned long child_table_pa = entry_val & ~(PAGE_SIZE - 1);
        *new_tbl = 0;
        return child_table_pa;
    }
}
/*
unsigned long map_table_level(unsigned long table_va, unsigned long shift, unsigned long va, int *new_table)
{
    unsigned long *table = (unsigned long *)table_va;
    unsigned long index = (va >> shift) & LEVEL_MASK;
    unsigned long desc = table[index];

    if ((desc & 0x3) == 0) {
        //说明这一项为空，需要分配新页做下一级表 
        unsigned long new_pa = get_free_page();
        if (!new_pa) {
            *new_table = 0;
            return 0; // 分配失败 
        }
        /// 清零新分配的页表页 
        memzero((void *)__va(new_pa),  PAGE_SIZE);

        // 写入“Table Descriptor” = new_pa | 0b11 
        table[index] = (new_pa & ~((unsigned long)(PAGE_SIZE - 1))) | DESCRIPTOR_TABLE;
        *new_table = 1;
        return new_pa;   /// 下一层页表的物理页号 
    }

    // 如果已有 Descriptor，就返回其高位 PA，低 12 位掩去 
    *new_table = 0;
    return desc & ~((unsigned long)(PAGE_SIZE - 1));
}
*/

#define PTE_DESCRIPTOR_PAGE   (3UL << 0) 
#define PTE_VALID       (1UL << 0)        // 有效位
#define PTE_AF          (1UL << 10)       // Access Flag
#define PTE_ATTR_IDX0   (0UL << 2)        // AttrIndx = 0：Normal WBWA
#define PTE_ATTR_IDX1   (1UL << 2)        //// MAIR index 1 = Normal, WB cache
#define PTE_SH_INNER    (3UL << 8)      // Inner-shareable
//#define PTE_AP_EL0_RW   (1UL << 7)        // 
#define PTE_AP_EL0_RX  (0UL << 6) 
#define PTE_PXN         (1UL << 53)       // 禁止 EL1 执行（用户代码页用）
#define PTE_UXN_MASK   (1 << 54)  // UXN 位

#define USER_FLAGS_CODE  ( \
      (3UL<<0)         /* valid + page */       \
    | PTE_ATTR_IDX0                       \
    | (3UL<<8)         /* inner-shareable */  \
    | (1UL<<10)        /* AF */              \
    | (2UL<<6)         /* AP=10 (EL0 R-only) */ \
    | (1UL<<53)        /* PXN */             \
)
unsigned long allocate_user_page(struct task_struct *task, unsigned long va, int prot) {

  struct mm_struct *mm = task->mm;

    /* 1. 如果顶层 PGD 还没分配，就先分配一页物理内存作为 PGD */
    if (!mm->pgd) {
        unsigned long new_pgd_pa = get_free_page();
        if (!new_pgd_pa) {
            printf("Failed to alloc PGD page\n\r");
            return 0;
        }
        /* 清零 PGD 页面 */
        memzero((void *)__va(new_pgd_pa), PAGE_SIZE);
        mm->pgd = new_pgd_pa;
        mm->kernel_pages[ mm->kernel_pages_count++ ] = new_pgd_pa;
    }

    /* 2. 按四级页表逐层分配/查找 */

    /* 2.1 PGD → PUD */
    unsigned long pgd_pa = mm->pgd;
    unsigned long *pgd_va = (unsigned long *)__va(pgd_pa);
    int new_tbl;

    unsigned long pud_pa = map_table_level((unsigned long)pgd_va,
                                           PGD_SHIFT, va, &new_tbl);
    if (!pud_pa) {
        printf("Failed at PGD→PUD for VA=0x%x\n\r", va);
        return 0;
    }

    /* 2.2 PUD → PMD */
    unsigned long *pud_va = (unsigned long *)__va(pud_pa);
    unsigned long pmd_pa = map_table_level((unsigned long)pud_va,
                                           PUD_SHIFT, va, &new_tbl);
    if (!pmd_pa) {
        printf("Failed at PUD→PMD for VA=0x%x\n\r", va);
        return 0;
    }

    /* 2.3 PMD → PTE */
    unsigned long *pmd_va = (unsigned long *)__va(pmd_pa);
    unsigned long pte_pa = map_table_level((unsigned long)pmd_va,
                                           PMD_SHIFT, va, &new_tbl);
    if (!pte_pa) {
        printf("Failed at PMD→PTE for VA=0x%x\n\r", va);
        return 0;
    }

    /* 3. 在 PTE 中写入数据页描述符 */
    unsigned long *pte_va = (unsigned long *)__va(pte_pa);
    unsigned long pte_index = (va >> PTE_SHIFT) & LEVEL_MASK;
      printf("Mapping VA=0x%x → PTE page phys=0x%x, virt=%x, pte_index=%d, old PTE=0x%x\n",
           va, pte_pa, pte_va, pte_index, pte_va[pte_index]);

    /* 3.1 分配一个“用户数据页”物理地址 */
    unsigned long new_data_pa = get_free_page();
    if (!new_data_pa) {
        printf("Failed to alloc user data page for VA=0x%x\n\r", va);
        return 0;
    }
    /* 清零新分配的数据页 */
    memzero((void *)__va(new_data_pa), PAGE_SIZE);

 unsigned long flags = //(unsigned long)prot|
                         PTE_DESCRIPTOR_PAGE
                         | PTE_AF
                         | PTE_ATTR_IDX0
                         |PTE_SH_INNER

                        ;
    // 如果想让 EL0 可读执行（示例），就加上 PTE_AP_EL0_RX；并加 PXN 禁止 EL1
   flags |= PTE_AP_EL0_RX |PTE_PXN|PTE_UXN_MASK; 

flags=USER_FLAGS_CODE;


    /* 3.2 写入 PTE = data_pa | prot */
    pte_va[pte_index] = (new_data_pa & ~(PAGE_SIZE - 1)) |  (flags );// (flags );

      {
        unsigned long final_entry = pte_va[pte_index];
        unsigned long mapped_pa   = final_entry & ~(PAGE_SIZE - 1);
        printf("  Written PTE[%d] = 0x%x → physical page = 0x%x, flags = 0x%x\n",
               pte_index, final_entry, mapped_pa, ( (flags )));
    }
    /* 4. 记录“用户数据页” */
    mm->user_pages[ mm->user_pages_count++ ].phys_addr = new_data_pa;
    mm->user_pages[ mm->user_pages_count   ].virt_addr = va;

    /* 5. 返回 新分配的“用户数据页”PA */
    return new_data_pa;
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


void map_page(struct task_struct *task, unsigned long va, unsigned long pa, int prot) {
    if (!task || !task->mm) {
        printf("Invalid task or mm_struct\n\r");
        return;
    }

    if (!task->mm->pgd) {
        task->mm->pgd = get_free_page();
        task->mm->kernel_pages[++task->mm->kernel_pages_count] = task->mm->pgd;
    }
        int new_table;
        unsigned long pgd_pa = task->mm->pgd;
        unsigned long *pgd = (unsigned long *)__va(pgd_pa);
        unsigned long pud = map_table(pgd, PGD_SHIFT, va, &new_table);
    
  //unsigned long pgd = task->mm->pgd;
    // PGD -> PUD
    //unsigned long pud = map_table((unsigned long *)(pgd + VA_START), PGD_SHIFT, va, &new_table);
    if (new_table)
        task->mm->kernel_pages[++task->mm->kernel_pages_count] = pud;

    // PUD -> PMD
     unsigned long pud_pa = __pa(pud);
    unsigned long pmd = map_table((unsigned long *)__va(pgd_pa), PUD_SHIFT, va, &new_table);
    if (new_table)
        task->mm->kernel_pages[++task->mm->kernel_pages_count] = pmd;

    // PMD -> PTE
      unsigned long pmd_pa = __pa(pmd);
    unsigned long pte = map_table((unsigned long *)__va(pmd_pa), PMD_SHIFT, va, &new_table);
    if (new_table)
        task->mm->kernel_pages[++task->mm->kernel_pages_count] = pte;

    // 设置 PTE 表项，使用传入的 prot 权限
       unsigned long ptd_pa = __pa(pte);
     unsigned long *pte_va=  (unsigned long *)__va(pmd_pa);
    unsigned long index = (va >> PAGE_SHIFT) & (PTRS_PER_TABLE - 1);
    pte_va[index] = pa | prot;

    // 记录 user page 映射
    struct user_page p = { pa, va };
    task->mm->user_pages[task->mm->user_pages_count++] = p;

    unsigned long pgd_index = va >> PGD_SHIFT;
    printf("VA=0x%x → PGD[%x]\n", va, pgd_index);
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
void free_user_memory(struct mm_struct *mm) {
    // 释放用户空间页面
    for (int i = 0; i < mm->user_pages_count; i++) {
        free_page(mm->user_pages[i].phys_addr);  // 物理地址
    }

    // 释放内核页表结构（例如PTE、PMD、PUD等）
    for (int i = 0; i <= mm->kernel_pages_count; i++) {
        free_page(mm->kernel_pages[i]);
    }

    // 释放 PGD 自身
    if (mm->pgd) {
        free_page(mm->pgd);
        mm->pgd = 0;
    }

    mm->user_pages_count = 0;
    mm->kernel_pages_count = -1;
}



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


void dump_pte(pgd_t *pgd_base, unsigned long va) {
    int pgd_index = (va >> PGD_SHIFT) & (PTRS_PER_TABLE - 1);
    int pud_index = (va >> PUD_SHIFT) & (PTRS_PER_TABLE - 1);
    int pmd_index = (va >> PMD_SHIFT) & (PTRS_PER_TABLE - 1);
    int pte_index = (va >> PAGE_SHIFT) & (PTRS_PER_TABLE - 1);

    pgd_t pgd = pgd_base[pgd_index];
    if (!(pgd_val(pgd) & PTE_VALID)) {
        printf("PGD[%d] invalid\n\r", pgd_index);
        return;
    }
    printf("PGD[%d] = 0x%x\n\r", pgd_index, pgd_val(pgd));

    pud_t *pud_base = (pud_t *)__va(pgd_val(pgd) & PAGE_MASK);
    pud_t pud = pud_base[pud_index];
    if (!(pud_val(pud) & PTE_VALID)) {
        printf("  PUD[%d] invalid\n\r", pud_index);
        return;
    }
    printf("  PUD[%d] = 0x%x\n\r", pud_index, pud_val(pud));

    pmd_t *pmd_base = (pmd_t *)__va(pud_val(pud) & PAGE_MASK);
    pmd_t pmd = pmd_base[pmd_index];
    if (!(pmd_val(pmd) & PTE_VALID)) {
        printf("    PMD[%d] invalid\n\r", pmd_index);
        return;
    }
    printf("    PMD[%d] = 0x%x\n\r", pmd_index, pmd_val(pmd));

    if ((pmd_val(pmd) & PTE_TABLE) == 0) {
        printf("    PMD[%d] is block mapping\n\r", pmd_index);
        return;
    }

    pte_t *pte_base = (pte_t *)__va(pmd_val(pmd) & PAGE_MASK);
    pte_t pte = pte_base[pte_index];
    if (!(pte_val(pte) & PTE_VALID)) {
        printf("      PTE[%d] invalid\n\r", pte_index);
        return;
    }
    printf("      PTE[%d] = 0x%x\n\r", pte_index, pte_val(pte));
    printf("      VA 0x%x → PA 0x%x\n\r", va, pte_val(pte) & PAGE_MASK);
}


 int pud_none(uint64_t pud_entry)
{
    return (pud_entry & 0x3) == 0;  // 低两位为0 → 无效表项
}
int pud_bad(uint64_t pud_entry)
{
    // 一般只允许 Table 类型（0b11）
    return (pud_entry & 0x3) != 0x3;
}
void pud_populate(uint64_t *pud, uint64_t *new_pmd)
{
    uint64_t pmd_phys = (uint64_t)new_pmd;  // 如果是恒等映射，否则使用 __pa()
    *pud = (pmd_phys & ~0x3F) | PUD_TYPE_TABLE;
}
int pmd_none(pmd_t pmd)
{
    return pmd_val(pmd) == 0;
}
int pmd_bad(pmd_t pmd)
{
    return (pmd_val(pmd) & PMD_TYPE_MASK) != PMD_TYPE_TABLE;
}
void pmd_populate(pmd_t *pmdp, pte_t *pte)
{
    set_pmd(pmdp, __pmd(__pa(pte) | PMD_TYPE_TABLE));
}
void set_pmd(pmd_t *pmdp, pmd_t pmd)
{
    *pmdp = pmd;
   __asm__ volatile ("dsb ishst" ::: "memory");
    __asm__ volatile ("isb" ::: "memory");
}
int pte_index(unsigned long addr) {
    return (addr >> PAGE_SHIFT) & (PTRS_PER_PTE - 1);
}
pte_t *pte_offset_map(pmd_t *pmd, unsigned long addr) {
    return (pte_t *)__va(pmd_val(*pmd) & PAGE_MASK) + pte_index(addr);
}

 int pte_present(pte_t pte) {
    return pte_val(pte) & PTE_VALID;
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
#define PTRS_PER_LEVEL 512
void debug_pgd(unsigned long pgd_pa)
{
    // 1) 把 pgd_pa（物理地址）映射到内核虚拟地址
    uint64_t *pgd_va = (uint64_t *)__va(pgd_pa);
    if (!pgd_va) {
        printf("debug_pgd: invalid pgd physical address 0x%x\n", pgd_pa);
        return;
    }

    printf("---- debug_pgd: PGD phys=0x%x, virt=%p ----\n",
           pgd_pa, pgd_va);

    // 2) 按照 uint64_t 数组依次读取每个条目
    for (int idx = 0; idx < 512; idx++) {
        uint64_t entry = pgd_va[idx];
        // 检查 Valid 位（bit0）是否为 1
        if ((entry & 0x1) == 0)
            continue;
        printf("PGD[%d] = 0x%x\n", idx, (unsigned long)entry);
    }

    printf("---- end of debug_pgd ----\n");
}
static void debug_pte(uint64_t pmd_entry)
{
    unsigned long pte_pa = (unsigned long)(pmd_entry & ~0xFFFULL);
    uint64_t *pte_va = (uint64_t *)__va(pte_pa);
    if (!pte_va) {
        printf("      debug_pte: invalid PTE phys=0x%x\n", pte_pa);
        return;
    }
    printf("      -- PTE page phys=0x%x, virt=%x --\n", pte_pa, pte_va);

   for (int i = 0; i < PTRS_PER_LEVEL; i++) {
    uint64_t entry = pte_va[i];
    if ((entry & 0x1) == 0) continue;
    printf("        PTE[%d] = 0x%x → physical page = 0x%x\n", i, (unsigned long)entry, (unsigned long)(entry & ~0xFFFULL));
    }
}

static void debug_pmd(uint64_t pud_entry) {
    unsigned long pmd_pa = (unsigned long)(pud_entry & ~0xFFFULL);
    uint64_t *pmd_va = (uint64_t *)__va(pmd_pa);
    if (!pmd_va) {
        printf("    debug_pmd: invalid PMD page phys=0x%x\n", pmd_pa);
        return;
    }
    printf("    -- PMD page phys=0x%x, virt=%p --\n", pmd_pa, pmd_va);

    for (int i = 0; i < PTRS_PER_LEVEL; i++) {
        uint64_t entry = pmd_va[i];
        if ((entry & 0x1) == 0) continue;

        if ((entry & 0x3) == 0x3) {
            printf("    PMD[%d] = 0x%x (Table)\n", i, (unsigned long)entry);
            debug_pte(entry);   // 无论 i 是 2 还是 63，都能打印对应的 PTE
        } else {
            printf("    PMD[%3d] = 0x%x (Block mapping)\n", i, (unsigned long)entry);
        }
    }
}

static void debug_pud(uint64_t pgd_entry)
{
    unsigned long pud_pa = (unsigned long)(pgd_entry & ~0xFFFULL);
    uint64_t *pud_va = (uint64_t *)__va(pud_pa);
    if (!pud_va) {
        printf("  debug_pud: invalid PUD phys=0x%x\n", pud_pa);
        return;
    }
    printf("  -- PUD page phys=0x%x, virt=%x --\n", pud_pa, pud_va);

    int idx = (0x400000 >> 30) & 0x1FF;  // PUD 索引
    uint64_t entry = pud_va[idx];
    if ((entry & 0x1) == 0) {
        printf("  PUD[%d] not valid (0x%x)\n", idx, (unsigned long)entry);
    } else if ((entry & 0x3) == 0x3) {
        // bit[1]=1，指向 PMD
        printf("  PUD[%d] = 0x%x (Table)\n", idx, (unsigned long)entry);
        debug_pmd(entry);
    } else {
        // Block descriptor，页大小可能是 1GB
        printf("  PUD[%3d] = 0xx (Block mapping)\n", idx, (unsigned long)entry);
    }
}

void debug_pgd_recursive(unsigned long pgd_pa)
{
    uint64_t *pgd_va = (uint64_t *)__va(pgd_pa);
    printf("---- begin debug_pgd_recursive: PGD phys=0x%x ----\n", pgd_pa);
    for (int i = 0; i < PTRS_PER_LEVEL; i++) {
        uint64_t entry = pgd_va[i];
        if ((entry & 0x1) == 0) 
            continue;

        printf("PGD[%d] = 0x%x\n", i, (unsigned long)entry);
        if ((entry & 0x3) == 0x3) {
            // bit[1]=1，指向 PUD
            debug_pud(entry);
        } else {
            // Block descriptor，也可能是一整块 512GB 映射
            printf("  PGD[%d] = 0x%x (Block mapping)\n", i, (unsigned long)entry);
        }
    }
    printf("----  end debug_pgd_recursive  ----\n");
}

void dump_pt_regs(struct pt_regs *regs) {
    printf("Dumping pt_regs at %x:\r\n", regs);
    printf("  PC (ELR_EL1)  : 0x%x\r\n", regs->pc);
    printf("  SP (SP_EL0)    : 0x%x\r\n", regs->sp);
    printf("  PSTATE (SPSR) : 0x%x\r\n", regs->pstate);

    // 可选：打印其他寄存器（x0-x30）
    for (int i = 0; i < 31; i++) {
        printf("  x%d: 0x%x\n", i, regs->regs[i]);
    }
}

// 获取 PTE（返回 NULL 如果未找到）
pte_t *get_pte(uint64_t *pgd, uint64_t va) {
    uint64_t *p4d, *pud, *pmd;

    // 1. 获取 P4D (PGD[VA[47:39]])
    p4d = (uint64_t *)(pgd[(va >> 39) & 0x1FF] & ~0xFFF);
    if (!(p4d[0] & PTE_VALID) || !(p4d[0] & PTE_TABLE)) {
        return 0;  // 无效 P4D
    }

    // 2. 获取 PUD (P4D[VA[38:30]])
    pud = (uint64_t *)(p4d[(va >> 30) & 0x1FF] & ~0xFFF);
    if (!(pud[0] & PTE_VALID) || !(pud[0] & PTE_TABLE)) {
        return 0;  // 无效 PUD
    }

    // 3. 获取 PMD (PUD[VA[29:21]])
    pmd = (uint64_t *)(pud[(va >> 21) & 0x1FF] & ~0xFFF);
    if (!(pmd[0] & PTE_VALID) || !(pmd[0] & PTE_TABLE)) {
        return 0;  // 无效 PMD
    }

    // 4. 获取 PTE (PMD[VA[20:12]])
    pte_t *pte = (pte_t *)(pmd[(va >> 12) & 0x1FF] & ~0xFFF);
   /// if (!(pte[0] & PTE_VALID)) {
   //     return 0;  // 无效 PTE
   // }

    return &pte[va & 0x1FF];  // 返回具体的 PTE
}

void dump_pgd(pgd_t *pgd) {
    int i;
    printf("Dumping PGD @ %x:\n", pgd);
    for (i = 0; i < PTRS_PER_PGD; i++) {
        pgd_t entry = pgd[i];
        if (!pgd_none(entry)) {  // 忽略空条目
            printf("PGD[%d]: val = 0x%x, present = %d\n", 
                   i, pgd_val(entry), pgd_present(entry));
        }
    }
}


void print_user_mapping(pgd_t *pgd, unsigned long va) {
    // 1. 解析 PGD
    unsigned long pgd_idx = (va >> PGD_SHIFT) & (PTRS_PER_PGD - 1);
    pgd_t pgd_e = pgd[pgd_idx];
    printf("PGD[%u] = 0x%x\n", pgd_idx, pgd_val(pgd_e));

    if (!pgd_present(pgd_e)) {
        printf("  PGD entry not present\n");
        return;
    }

    // 2. 解析 PUD
    pud_t *pud_va = pud_offset(&pgd_e, va);  // 注意：pgd_offset 参数应为 pgd_t*
    unsigned long pud_idx = (va >> PUD_SHIFT) & (PTRS_PER_PUD - 1);
    pud_t pud_e = pud_va[pud_idx];
    printf("  PUD[%u] = 0x%x\n", pud_idx, pud_val(pud_e));

    if (!pud_present(pud_e)) {
        printf("  PUD entry not present\n");
        return;
    }

    // 3. 解析 PMD
    pmd_t *pmd_va = pmd_offset(pud_va, va);
    unsigned long pmd_idx = (va >> PMD_SHIFT) & (PTRS_PER_PMD - 1);
    pmd_t pmd_e = pmd_va[pmd_idx];
    printf("    PMD[%u] = 0x%x\n", pmd_idx, pmd_val(pmd_e));

    if (!pmd_present(pmd_e)) {
        printf("    PMD entry not present\n");
        return;
    }

    // 4. 解析 PTE
    pte_t *pte_va = pte_offset_kernel(pmd_va, va);
    unsigned long pte_idx = (va >> PAGE_SHIFT) & (PTRS_PER_PTE - 1);
    pte_t pte_e = pte_va[pte_idx];
    printf("      PTE[%u] = 0x%x\n", pte_idx, pte_val(pte_e));

    if (!pte_valid(pte_e)) {
        printf("      PTE not valid\n");
    } else {
        phys_addr_t pa = pte_val(pte_e) & PAGE_MASK;
        printf("      Mapped VA: 0x%x → PA: 0x%x\n", va, pa);
    }
}