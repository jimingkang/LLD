#ifndef	_SYS_H
#define	_SYS_H

#define __NR_syscalls	    4
#define SYS_WRITE_NUMBER    0 		// syscal numbers 
#define SYS_MALLOC_NUMBER   1 	
#define SYS_CLONE_NUMBER    2 	
#define SYS_EXIT_NUMBER     3 



#define NR_SYSCALLS  4
#define SYS_WRITE_NUM          0
#define SYS_FORK_NUM           1
#define SYS_EXIT_NUM           2
#define SYS_SPAWN_NUM          3


#ifndef __ASSEMBLER__

void sys_write(char * buf);
int sys_fork(u64 stack);
void sys_exit();
int sys_spawn(u64 image_id);

void handle_user_page_fault(u64 addr, u64 esr) ;



#endif
#endif  /*_SYS_H */
