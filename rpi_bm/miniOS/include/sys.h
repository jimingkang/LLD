#ifndef	_SYS_H
#define	_SYS_H

#define __NR_syscalls	    4

#define SYS_WRITE_NUMBER    0 		// syscal numbers 
#define SYS_MALLOC_NUMBER   1 	
#define SYS_CLONE_NUMBER    2 	
#define SYS_EXIT_NUMBER     3 	

#ifndef __ASSEMBLER__

void sys_write(char * buf) __attribute__((section(".user.text")));
int sys_fork() __attribute__((section(".user.text")));

void call_sys_write(char * buf) __attribute__((section(".user.text")));
int call_sys_clone(unsigned long fn, unsigned long arg, unsigned long stack) __attribute__((section(".user.text")));
unsigned long call_sys_malloc() __attribute__((section(".user.text")));
void call_sys_exit() __attribute__((section(".user.text")));
 void user_process() __attribute__((section(".user.text")));
void process(char *array) __attribute__((section(".user.text"))) ;

#endif
#endif  /*_SYS_H */