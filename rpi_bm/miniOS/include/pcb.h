#include <common.h>
typedef struct {
    uint64_t x19, x20, x21, x22, x23, x24, x25, x26, x27, x28; // Callee-saved
    uint64_t fp, sp;            // Frame pointer, Stack pointer
    uint64_t pc;                // Program counter (entry point)
    uint64_t cpsr;              // PSTATE (DAIF + mode bits)
} thread_ctx_t;
#define STACK_REGION_START 0x00280000
thread_ctx_t* create_thread(void (*entry)(void*), void* arg, uint64_t* stack);
void thread_switch(thread_ctx_t* current, thread_ctx_t* next);
void first_thread_switch(thread_ctx_t* new_thread);
uint64_t* allocate_thread_stack() ;