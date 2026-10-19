#ifndef MINIOS_T113_SEMAPHORE_H
#define MINIOS_T113_SEMAPHORE_H

#include "wait.h"

struct semaphore {
    int32_t count;
    struct wait_queue_head wait;
};

#define SEMAPHORE_INIT(value) { (value), WAIT_QUEUE_HEAD_INIT }

void sema_init(struct semaphore *sem, uint32_t value);
int down_trylock(struct semaphore *sem);
void down(struct semaphore *sem);
void up(struct semaphore *sem);

#endif
