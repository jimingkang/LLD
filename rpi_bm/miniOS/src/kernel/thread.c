/*#include <pcb.h>
#include <common.h>
thread_ctx_t* create_thread(void (*entry)(void*), void* arg, uint64_t* stack_top) {
    //thread_ctx_t* ctx = (thread_ctx_t*)(stack - sizeof(thread_ctx_t));
    
    // Align stack to 16 bytes
    stack_top = (uint64_t*)((uint64_t)stack_top & ~0xF);
    thread_ctx_t* ctx = (thread_ctx_t*)(stack_top - sizeof(thread_ctx_t)/8);
    // Initialize context
    memzero(ctx, 0, sizeof(thread_ctx_t));
    ctx->pc = (uint64_t)entry;  // Thread entry point
    ctx->sp = (uint64_t)stack_top;  // Stack top
    ctx->cpsr = 0x340;          // DAIF=0, EL1t (SP_EL1)
    
    // Pass argument (in x0 for AAPCS64)
    ctx->x19 = (uint64_t)arg;   // Or use x0 for first arg
    
    return ctx;
}

uint64_t* allocate_thread_stack() {
    static uint64_t next_stack = STACK_REGION_START;
    uint64_t* stack = (uint64_t*)(next_stack + 0x2000 - 16); // Top of 8KB region
    next_stack += 0x2000; // Advance by 8KB
    
    // Add guard page after each stack
   // create_mapping(next_stack, next_stack, MT_NONE); // Unmapped
    
    return stack;
}

*/