#ifndef	_USER_H
#define	_USER_H

void user_process1(char *array);
void user_process();
void loop();
extern unsigned long user_begin[];
extern unsigned long  user_data_begin[];
extern unsigned long user_end[];
//extern char user_begin[];

//extern char user_end[];

#endif  /*_USER_H */