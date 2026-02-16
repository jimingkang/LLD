#include "hardware.h"
#include "process.h"
#include "user_process.h"


void hardware_init(void) {
   init_uart();

   // gpio_init();
    timer_init();
   irq_init();
    process_init();
}

void kernel_main(void) {
    uart_puts("\n=== Raspberry Pi 3 Bare Metal Kernel with User Process Management ===\n");
    uart_puts("Hardware initialized successfully!\n");
    uart_puts("MMU enabled with page tables\n");
    uart_puts("Timer interrupts enabled\n");
    uart_puts("User process management initialized\n");
    uart_puts("System ready!\n\n");
    
    // Test GPIO LED (pin 18)
    gpio_pin_set_output(18);
    
    process_create("UserProc1", user_process_1, 5);
    process_create("UserProc2", user_process_2, 3);
    process_create("UserProc3", user_process_3, 7);
    
    uart_puts("Created 3 user processes running in EL0\n");
    print_process_list();
    
    // Start first process
    process_schedule();
    
    int led_state = 0;
    while (1) {
        // Toggle LED every 5 seconds
        if (get_timer_ticks() % 5 == 0 && get_timer_ticks() > 0) {
            if (led_state) {
                gpio_pin_clear(18);
                uart_puts("[KERNEL] LED OFF\n");
                led_state = 0;
            } else {
                gpio_pin_set(18);
                uart_puts("[KERNEL] LED ON\n");
                led_state = 1;
            }
            
            // Wait to avoid multiple toggles
            delay(1000000);
        }
        
        // Echo any received characters
        if (!(*UART0_FR & (1 << 4))) {
            unsigned char c = uart_getc();
            if (c == 'p' || c == 'P') {
                print_process_list();
            } else {
                uart_puts("[KERNEL] Received: ");
                uart_putc(c);
                uart_puts(" (Press 'p' for process list)\n");
            }
        }
        
        process_schedule();
        
        // Small delay to prevent busy waiting
        for (volatile int i = 0; i < 100000; i++);
    }
}
