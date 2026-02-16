#include "syscall.h"

void user_process_1(void) {
    int count = 0;
    while (count < 10) {
        user_print("User Process 1 running\n");
        count++;
        user_yield();  // Yield to other processes
    }
    user_print("User Process 1 finished\n");
    user_exit();
}

void user_process_2(void) {
    int count = 0;
    while (count < 8) {
        user_print("User Process 2 executing\n");
        count++;
        user_yield();
    }
    user_print("User Process 2 finished\n");
    user_exit();
}

void user_process_3(void) {
    int count = 0;
    while (count < 6) {
        user_print("User Process 3 active\n");
        count++;
        user_yield();
    }
    user_print("User Process 3 finished\n");
    user_exit();
}
