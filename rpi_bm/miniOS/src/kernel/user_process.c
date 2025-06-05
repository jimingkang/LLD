#include "fork.h"
#include "printf.h"
#include "utils.h"
#include "sched.h"
#include "mm.h"
#include "mem.h"
#include <mmu.h>

__attribute__((section(".user.text")))
void process(char *array)
{
	while (1){
		for (int i = 0; i < 5; i++){
			uart_send(array[i]);
			delay(1000000);
		}
	}
}
__attribute__((section(".user.text")))
void user_process(){
while (1){
		for (int i = 0; i < 5; i++){
			uart_send(i);
			delay(1000000);
		}
	}
	//char buf[30] = {0};
  //  char i=80;
	//tfp_sprintf();
	//call_sys_write(10);
    
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
