#ifndef	_USER_SYS_H
#define	_USER_SYS_H

#define __NR_syscalls	    4

#define SYS_WRITE_NUMBER    0 		// syscal numbers 
#define SYS_MALLOC_NUMBER   1 	
#define SYS_CLONE_NUMBER    2 	
#define SYS_EXIT_NUMBER     3 	

#ifndef __ASSEMBLER__


void user_delay(unsigned long count);
void call_sys_write(const char *buf);
int call_sys_fork(void);
int call_sys_spawn(unsigned long image_id);
int call_sys_clone(unsigned long fn, unsigned long arg, unsigned long stack);
unsigned long call_sys_malloc();
void call_sys_exit() ;
void user_process(void);


#endif
#endif  /*_SYS_H */
