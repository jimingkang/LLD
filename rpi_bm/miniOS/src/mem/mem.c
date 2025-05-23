#include <mem.h>
#include <peripherals/base.h>
#include <mm.h>
#include <mmu.h>
#include <printf.h>
#include <sched.h>



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

    
	if (!task->mm.pgd) {
		task->mm.pgd = get_free_page();
		task->mm.kernel_pages[++task->mm.kernel_pages_count] = task->mm.pgd;
	}
	pgd = task->mm.pgd;
	int new_table;
	unsigned long pud = map_table((unsigned long *)(pgd + VA_START), PGD_SHIFT, va, &new_table);
	if (new_table) {
		task->mm.kernel_pages[++task->mm.kernel_pages_count] = pud;
	}
	unsigned long pmd = map_table((unsigned long *)(pud + VA_START) , PUD_SHIFT, va, &new_table);
	if (new_table) {
		task->mm.kernel_pages[++task->mm.kernel_pages_count] = pmd;
	}
	unsigned long pte = map_table((unsigned long *)(pmd + VA_START), PMD_SHIFT, va, &new_table);
	if (new_table) {
		task->mm.kernel_pages[++task->mm.kernel_pages_count] = pte;
	}
	map_table_entry((unsigned long *)(pte + VA_START), va, page);
	struct user_page p = {page, va};
	task->mm.user_pages[task->mm.user_pages_count++] = p;
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
