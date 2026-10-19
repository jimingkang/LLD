#ifndef MINIOS_T113_MUTEX_H
#define MINIOS_T113_MUTEX_H

#include "wait.h"

struct mutex {
    struct t113_task *owner;
    struct wait_queue_head wait;
};

#define MUTEX_INIT { 0, WAIT_QUEUE_HEAD_INIT }

void mutex_init(struct mutex *mutex);
int mutex_trylock(struct mutex *mutex);
int mutex_lock(struct mutex *mutex);
int mutex_unlock(struct mutex *mutex);

#endif
