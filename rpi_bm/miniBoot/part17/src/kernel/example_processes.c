#include "process.h"
#include "printf.h"
#include "timer.h"

// Example process 1 - Simple counter
void process1_main(void) {
    int counter = 0;
    
    printf("Process 1 started (PID: %d)\n", get_current_process()->pid);
    
    while (1) {
        printf("Process 1: Counter = %d\n", counter++);
        timer_sleep(1000);  // Sleep for 1 second
        
        // Voluntarily yield CPU after every 5 iterations
        if (counter % 5 == 0) {
            printf("Process 1: Yielding CPU\n");
            process_yield();
        }
        
        // Terminate after 20 iterations
        if (counter >= 20) {
            printf("Process 1: Terminating\n");
            break;
        }
    }
    
    printf("Process 1 finished\n");
}

// Example process 2 - Simple printer
void process2_main(void) {
    int iterations = 0;
    
    printf("Process 2 started (PID: %d)\n", get_current_process()->pid);
    
    while (1) {
        printf("Process 2: Hello from process 2! (iteration %d)\n", iterations++);
        timer_sleep(800);   // Sleep for 0.8 seconds
        
        // Yield every 3 iterations
        if (iterations % 3 == 0) {
            printf("Process 2: Yielding CPU\n");
            process_yield();
        }
        
        // Terminate after 15 iterations
        if (iterations >= 15) {
            printf("Process 2: Terminating\n");
            break;
        }
    }
    
    printf("Process 2 finished\n");
}

// Example process 3 - CPU-intensive task
void process3_main(void) {
    int calculations = 0;
    volatile long sum = 0;
    
    printf("Process 3 started (PID: %d) - CPU intensive task\n", get_current_process()->pid);
    
    while (1) {
        // Perform some CPU-intensive calculations
        for (int i = 0; i < 100000; i++) {
            sum += i * i;
        }
        
        calculations++;
        
        if (calculations % 10 == 0) {
            printf("Process 3: Completed %d calculation cycles (sum = %ld)\n", 
                   calculations, sum);
        }
        
        // This process is more CPU intensive and yields less frequently
        if (calculations % 50 == 0) {
            printf("Process 3: Yielding CPU after intense computation\n");
            process_yield();
        }
        
        // Terminate after 100 calculation cycles
        if (calculations >= 100) {
            printf("Process 3: Terminating after %d calculations\n", calculations);
            break;
        }
    }
    
    printf("Process 3 finished with final sum: %ld\n", sum);
}

// Process monitoring task
void monitor_process_main(void) {
    int monitor_count = 0;
    
    printf("Monitor process started (PID: %d)\n", get_current_process()->pid);
    
    while (1) {
        timer_sleep(5000);  // Monitor every 5 seconds
        
        printf("\n=== Process Monitor Report ===\n");
        print_process_info();
        printf("===============================\n\n");
        
        monitor_count++;
        
        // Run monitor for 10 cycles (50 seconds)
        if (monitor_count >= 10) {
            printf("Monitor process: Shutting down after %d reports\n", monitor_count);
            break;
        }
    }
    
    printf("Monitor process finished\n");
}