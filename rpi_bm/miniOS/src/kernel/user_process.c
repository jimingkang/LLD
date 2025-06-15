#include "fork.h"
#include "printf.h"
#include "utils.h"
#include "sched.h"
#include "mm.h"
#include "mem.h"
#include <mmu.h>

const char msg[] __attribute__((section(".user.rodata"))) = 
    "Hello from user_process!\n";
	
	const char err[] __attribute__((section(".user.rodata"))) = 
    	"Error during fork\n\r";

__attribute__((section(".user.text")))
void loop(char* str)
{
	char buf[2] = {""};
	while (1){
		for (int i = 0; i < 5; i++){
		//	buf[0] = str[i];
			call_sys_write("hello\n\r");
			user_delay(1000000);
		}
	}
}
__attribute__((section(".user.text")))
void user_process(){

	//call_sys_write(msg);
	loop(err);
	//int pid = call_sys_fork();
	//if (pid < 0) {
	//	call_sys_write(err);
	//	call_sys_exit();
	//	return;
	//}
	//if (pid == 0){
	//	loop(msg);
	//} else {
	//	loop(err);
	//}
    
    /*
	unsigned long stack = call_sys_malloc();
	if (stack < 0) {
		//printf("Error while allocating stack for process 1\n\r");
		return;
	}
*/
        
    /*
    unsigned long a=123;
	int err = call_sys_clone((unsigned long)&process, a, stack);
	if (err < 0){
	//	printf("Error while clonning process 1\n\r");
		return;
	} 
    */
          /*
	stack = call_sys_malloc();
	if (stack < 0) {
		printf("Error while allocating stack for process 1\n\r");
		return;
	}
    unsigned long b=456;
	err = call_sys_clone((unsigned long)&process, b, stack);
	if (err < 0){
		printf("Error while clonning process 2\n\r");
		return;
	} 
        */
	call_sys_exit();
}
