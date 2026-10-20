#ifndef MINIOS_T113_WAIT_H
#define MINIOS_T113_WAIT_H

#include "spinlock.h"

struct t113_task;

struct wait_queue_head {
    spinlock_t lock;
    struct t113_task *head;
    struct t113_task *tail;
};

#define WAIT_QUEUE_HEAD_INIT { SPINLOCK_INIT, 0, 0 }

void init_waitqueue_head(struct wait_queue_head *queue);
void wait_queue_sleep(struct wait_queue_head *queue);
/* Caller holds queue->lock with IRQ state returned by spin_lock_irqsave(). */
void wait_queue_sleep_locked(struct wait_queue_head *queue,
                             uint32_t irq_flags);
int wake_up_one(struct wait_queue_head *queue);
uint32_t wake_up_all(struct wait_queue_head *queue);

#endif
