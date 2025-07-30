#include "utils.h"
#include "printf.h"
#include "entry.h"
#include "peripherals/irq.h"
#include "peripherals/aux.h"
#include "mini_uart.h"
#include "timer.h"
#include "mem.h"

const char entry_error_messages[16][32] = {
	"SYNC_INVALID_EL1t",
	"IRQ_INVALID_EL1t",		
	"FIQ_INVALID_EL1t",		
	"ERROR_INVALID_EL1T",		

	"SYNC_INVALID_EL1h",
	"IRQ_INVALID_EL1h",		
	"FIQ_INVALID_EL1h",		
	"ERROR_INVALID_EL1h",		

	"SYNC_INVALID_EL0_64",		
	"IRQ_INVALID_EL0_64",		
	"FIQ_INVALID_EL0_64",		
	"ERROR_INVALID_EL0_64",	

	"SYNC_INVALID_EL0_32",		
	"IRQ_INVALID_EL0_32",		
	"FIQ_INVALID_EL0_32",		
	"ERROR_INVALID_EL0_32"	
};

void show_invalid_entry_message(u32 type, u64 esr, u64 address,u64 elr) {
    printf("ERROR CAUGHT: %d, ESR: %x,ELR: %x, Address: %x, %x ,\n", 
        type, esr,elr, address,entry_error_messages[type]);

        // In el0_sync_handler
// In el0_sync_handler
    if (esr >> 26 == 0x20) { // Instruction Abort
        unsigned long far, elr, spsr, ttbr0, ttbr1, sctlr;
        __asm__ volatile("mrs %0, FAR_EL1\n\t" : "=r"(far));
        __asm__ volatile("mrs %0, ELR_EL1\n\t" : "=r"(elr));
        __asm__ volatile("mrs %0, SPSR_EL1\n\t" : "=r"(spsr));
        __asm__ volatile("mrs %0, TTBR0_EL1\n\t" : "=r"(ttbr0));
        __asm__ volatile("mrs %0, TTBR1_EL1\n\t" : "=r"(ttbr1));
        __asm__ volatile("mrs %0, SCTLR_EL1\n\t" : "=r"(sctlr));
        printf("EL0 Instruction Abort: FAR=0x%x, ELR=0x%x, SPSR=0x%x, TTBR0_EL1=0x%x, TTBR1_EL1=0x%x, SCTLR_EL1=0x%x\n",
            far, elr, spsr, ttbr0, ttbr1, sctlr);
        unsigned long *pgd_virt = (unsigned long *)__va(ttbr0);
        printf("EL0: PGD read via __va(0x%x)=0x%x: [0]=0x%x\n",ttbr0,pgd_virt, pgd_virt[0]);
    // unsigned long *kernel_pgd = (unsigned long *)__va(0x9e000);
        //int pgd_index = (0x1006000 >> 39) & 0x1FF;

    //  printf("EL0: Kernel PGD[%d] for 0x1004000 = 0x%x\n", pgd_index, kernel_pgd[pgd_index]);
        while (1);
    }  
}

void enable_interrupt_controller() {
    #if RPI_VERSION == 4
        REGS_IRQ->irq0_enable_0 = AUX_IRQ | SYS_TIMER_IRQ_1 | SYS_TIMER_IRQ_3;
    #endif

    #if RPI_VERSION == 3
        REGS_IRQ->irq0_enable_1 = AUX_IRQ | SYS_TIMER_IRQ_1 | SYS_TIMER_IRQ_3;
    #endif
}

void handle_irq() {
    u32 irq;

#if RPI_VERSION == 4
    irq = REGS_IRQ->irq0_pending_0;
#endif

#if RPI_VERSION == 3
    irq = REGS_IRQ->irq0_pending_1;
#endif

    while(irq) {
        if (irq & AUX_IRQ) {
            irq &= ~AUX_IRQ;

            while((REGS_AUX->mu_iir & 4) == 4) {
                printf("UART Recv: ");
                uart_send(uart_recv());
                printf("\n");
            }
        }

        if (irq & SYS_TIMER_IRQ_1) {
            irq &= ~SYS_TIMER_IRQ_1;

            handle_timer_1();
        }

        if (irq & SYS_TIMER_IRQ_3) {
            irq &= ~SYS_TIMER_IRQ_3;

            handle_timer_3();
        }
    }

}