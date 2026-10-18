#include "fork.h"
#include "printf.h"
#include "utils.h"
#include "sched.h"
#include "mm.h"
#include "mem.h"
#include "user_sys.h"
#include <mmu.h>


const char msg[] __attribute__((section(".user.rodata"))) = "Hello";
const char err[] __attribute__((section(".user.rodata"))) = "Err";
__attribute__((section(".user.text")))
void user_main(void){
	while (1){
	for (int i = 0; i < 5; i++){
		//	buf[0] = str[i];
			call_sys_write(msg);
			user_delay(1000000);
		}	
	}
}
__attribute__((section(".user.text")))
void loop(const char *str)
{
	char buf[2] = {""};
	while (1){
		for (int i = 0; i < 5; i++){
		//	buf[0] = str[i];
			call_sys_write(msg);
			user_delay(1000000);
		}
	}
}

__attribute__((section(".user.text")))
void user_process() 
{
	call_sys_write(msg);
	int pid = call_sys_fork();
	if (pid < 0) {
		call_sys_write(err);
		call_sys_exit();
		return;
	}
	if (pid == 0){
		loop(msg);
	} else {
		loop(err);
	}
}

static const char msg2[] __attribute__((section(".user2.rodata"))) =
    "user image 2\n";

__attribute__((section(".user2.text")))
void user_process2(void)
{
    for (;;) {
        register const char *x0 asm("x0") = msg2;
        register unsigned long x8 asm("x8") = 0;
        asm volatile("svc #0" : "+r"(x0) : "r"(x8) : "memory");

        for (volatile unsigned long delay_count = 0;
             delay_count < 1000000; delay_count++) {
        }
    }
}
