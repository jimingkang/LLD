#include <mem.h>
#include <peripherals/base.h>
#include <mm.h>
#include <mmu.h>
#include <printf.h>



extern char __text_start[];
extern char __text_end[];
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
    pte_t *pte;
    
    // Get PTE entry (allocates page tables if needed)
    pte = pte_alloc(pgd, va);
    if (!pte) return -1;
    
    // Set the PTE
    *pte = pa | flags | PTE_TYPE_PAGE;
    
    // Flush TLB
    flush_tlb_page(va);
    
    return 0;
}

// Page table entry allocation
pte_t *pte_alloc(pgd_t *pgd, unsigned long va)
{
    pud_t *pud;
    pmd_t *pmd;
    
    // Walk page tables
    pud = pud_offset(pgd, va);
    if (!pud_present(*pud)) {
        unsigned long pud_page = get_free_page();
        if (!pud_page) return NULL;
        set_pud(pud, __pud(pud_page | PTE_VALID | PTE_TABLE));
    }
    
    pmd = pmd_offset(pud, va);
    if (!pmd_present(*pmd)) {
        unsigned long pmd_page = get_free_page();
        if (!pmd_page) return NULL;
        set_pmd(pmd, __pmd(pmd_page | PTE_VALID | PTE_TABLE));
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
#define ENTRIES_PER_TABLE      512
#define PGD_SHIFT              (PAGE_SHIFT + 3 * TABLE_SHIFT)
#define PUD_SHIFT              (PAGE_SHIFT + 2 * TABLE_SHIFT)
#define PMD_SHIFT              (PAGE_SHIFT + TABLE_SHIFT)
#define PUD_ENTRY_MAP_SIZE     (1 << PUD_SHIFT)



void map_kernel_text() {
    u64 start = (u64)__text_start & PAGE_MASK;
    u64 end   = ((u64)__text_end + PAGE_SIZE - 1) & PAGE_MASK;

    for (u64 addr = start; addr < end; addr += PAGE_SIZE) {
        map_user_page(addr, addr, KERNEL_EXEC_FLAGS);  // 1:1 映射代码段
    }
}
void old4_map_user_page(u64 va, u64 pa, u64 flags) {
    u64 *pgd = (u64 *)__va(id_pgd_addr());  // 顶层页表必须用虚拟地址访问

    u64 pgd_idx = (va >> 39) & 0x1FF;
    u64 pud_idx = (va >> 30) & 0x1FF;
    u64 pmd_idx = (va >> 21) & 0x1FF;
    u64 pte_idx = (va >> 12) & 0x1FF;

    u64 *pud, *pmd, *pte;

    // === 第一级 PGD → PUD ===
    if (!(pgd[pgd_idx] & 1)) {
        u64 pud_phys = (u64)alloc_page();
        memzero((u64)__va(pud_phys), PAGE_SIZE);
        pgd[pgd_idx] = pud_phys | TD_KERNEL_TABLE_FLAGS;
    }
    pud = (u64 *)__va(pgd[pgd_idx] & PAGE_MASK);

    // === 第二级 PUD → PMD ===
    if (!(pud[pud_idx] & 1)) {
        u64 pmd_phys = (u64)alloc_page();
        memzero((u64)__va(pmd_phys), PAGE_SIZE);
        pud[pud_idx] = pmd_phys | TD_KERNEL_TABLE_FLAGS;
    }
    pmd = (u64 *)__va(pud[pud_idx] & PAGE_MASK);

    // === 第三级 PMD → PTE ===
    if (!(pmd[pmd_idx] & 1)) {
        u64 pte_phys = (u64)alloc_page();
        memzero((u64)__va(pte_phys), PAGE_SIZE);
        pmd[pmd_idx] = pte_phys | TD_KERNEL_TABLE_FLAGS;
    }
    pte = (u64 *)__va(pmd[pmd_idx] & PAGE_MASK);

    // === 最终设置 PTE ===
    pte[pte_idx] = (pa & PAGE_MASK) | flags;
}
void old3_map_user_page(u64 va, u64 pa, u64 flags) {
    u64 *pgd = (u64 *)__va(id_pgd_addr());  // id_pgd 已知是物理地址 → 转虚拟

    u64 pgd_idx = (va >> 39) & 0x1FF;
    u64 pud_idx = (va >> 30) & 0x1FF;
    u64 pmd_idx = (va >> 21) & 0x1FF;
    u64 pte_idx = (va >> 12) & 0x1FF;

    u64 *pud, *pmd, *pte;

    // PGD -> PUD
    if (!(pgd[pgd_idx] & 1)) {
        pud = (u64 *)alloc_page();
        memzero((u64)__va((u64)pud), PAGE_SIZE);
        pgd[pgd_idx] = __pa((u64)pud) | TD_KERNEL_TABLE_FLAGS;
    } else {
        pud = (u64 *)__va(pgd[pgd_idx] & PAGE_MASK);
    }

    // PUD -> PMD
    if (!(pud[pud_idx] & 1)) {
        pmd = (u64 *)alloc_page();
        memzero((u64)__va((u64)pmd), PAGE_SIZE);
        pud[pud_idx] = __pa((u64)pmd) | TD_KERNEL_TABLE_FLAGS;
    } else {
        pmd = (u64 *)__va(pud[pud_idx] & PAGE_MASK);
    }

    // PMD -> PTE
    if (!(pmd[pmd_idx] & 1)) {
        pte = (u64 *)alloc_page();
        memzero((u64)__va((u64)pte), PAGE_SIZE);
        pmd[pmd_idx] = __pa((u64)pte) | TD_KERNEL_TABLE_FLAGS;
    } else {
        pte = (u64 *)__va(pmd[pmd_idx] & PAGE_MASK);
    }

   printf("map_user_page:\n");
    printf("  va = 0x%lx, pa = 0x%lx\n", va, pa);
    printf("  pgd = %x, pud = %x, pmd = %x, pte = %x\n",__pa(pgd), __pa(pud), __pa(pmd), __pa(pte));
    printf("  pte_idx = 0x%lx, write to = 0x%lx\n", pte_idx, (u64)&pte[pte_idx]);
    // 最终 PTE 设置
    printf("map_user_page:\n");
    // 设置最终 PTE 映射
    pte[pte_idx] = (pa & PAGE_MASK) | flags;
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


void old_map_user_page(u64 va, u64 pa, u64 flags)
{
    // 三级页表构造：PGD → PUD → PMD → PTE
    u64 *pgd = (u64 *)id_pgd_addr();

    u64 pgd_idx = (va >> 39) & 0x1FF;
    u64 pud_idx = (va >> 30) & 0x1FF;
    u64 pmd_idx = (va >> 21) & 0x1FF;
    u64 pte_idx = (va >> 12) & 0x1FF;

    u64 *pud = alloc_page();  pgd[pgd_idx] = (u64)pud | TD_KERNEL_TABLE_FLAGS;
    u64 *pmd = alloc_page();  pud[pud_idx] = (u64)pmd | TD_KERNEL_TABLE_FLAGS;
    u64 *pte = alloc_page();  pmd[pmd_idx] = (u64)pte | TD_KERNEL_TABLE_FLAGS;

    pte[pte_idx] = (pa & PAGE_MASK) | flags;
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
   // map_kernel_text();  // ✅ 加上这一行
    //printf("mapping .text from 0x%lx to 0x%lx\n", (u64)__text_start, (u64)__text_end);

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
