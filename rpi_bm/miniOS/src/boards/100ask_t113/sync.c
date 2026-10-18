#include "sched.h"
#include "wait.h"
#include "mutex.h"
#include "semaphore.h"

static void wait_enqueue_locked(struct wait_queue_head *queue,
                                struct t113_task *task)
{
    task->wait_next = 0;
    if (queue->tail)
        queue->tail->wait_next = task;
    else
        queue->head = task;
    queue->tail = task;
    task->state = T113_TASK_BLOCKED;
}

static struct t113_task *wait_dequeue_locked(struct wait_queue_head *queue)
{
    struct t113_task *task = queue->head;
    if (!task)
        return 0;
    queue->head = task->wait_next;
    if (!queue->head)
        queue->tail = 0;
    task->wait_next = 0;
    return task;
}

void init_waitqueue_head(struct wait_queue_head *queue)
{
    spin_lock_init(&queue->lock);
    queue->head = 0;
    queue->tail = 0;
}

void wait_queue_sleep(struct wait_queue_head *queue)
{
    uint32_t flags = spin_lock_irqsave(&queue->lock);
    wait_enqueue_locked(queue, t113_current);
    spin_unlock_irqrestore(&queue->lock, flags);
    t113_sched_yield();
}

int wake_up_one(struct wait_queue_head *queue)
{
    uint32_t flags = spin_lock_irqsave(&queue->lock);
    struct t113_task *task = wait_dequeue_locked(queue);
    if (task)
        task->state = T113_TASK_RUNNING;
    spin_unlock_irqrestore(&queue->lock, flags);
    return task != 0;
}

uint32_t wake_up_all(struct wait_queue_head *queue)
{
    uint32_t count = 0;
    uint32_t flags = spin_lock_irqsave(&queue->lock);
    struct t113_task *task;
    while ((task = wait_dequeue_locked(queue)) != 0) {
        task->state = T113_TASK_RUNNING;
        ++count;
    }
    spin_unlock_irqrestore(&queue->lock, flags);
    return count;
}

void mutex_init(struct mutex *mutex)
{
    mutex->owner = 0;
    init_waitqueue_head(&mutex->wait);
}

int mutex_trylock(struct mutex *mutex)
{
    uint32_t flags = spin_lock_irqsave(&mutex->wait.lock);
    int acquired = mutex->owner == 0;
    if (acquired)
        mutex->owner = t113_current;
    spin_unlock_irqrestore(&mutex->wait.lock, flags);
    return acquired;
}

int mutex_lock(struct mutex *mutex)
{
    for (;;) {
        uint32_t flags = spin_lock_irqsave(&mutex->wait.lock);
        if (!mutex->owner) {
            mutex->owner = t113_current;
            spin_unlock_irqrestore(&mutex->wait.lock, flags);
            return 0;
        }
        if (mutex->owner == t113_current) {
            spin_unlock_irqrestore(&mutex->wait.lock, flags);
            return -1; /* Non-recursive mutex. */
        }
        wait_enqueue_locked(&mutex->wait, t113_current);
        spin_unlock_irqrestore(&mutex->wait.lock, flags);
        t113_sched_yield();
    }
}

int mutex_unlock(struct mutex *mutex)
{
    uint32_t flags = spin_lock_irqsave(&mutex->wait.lock);
    if (mutex->owner != t113_current) {
        spin_unlock_irqrestore(&mutex->wait.lock, flags);
        return -1;
    }
    mutex->owner = 0;
    struct t113_task *task = wait_dequeue_locked(&mutex->wait);
    if (task)
        task->state = T113_TASK_RUNNING;
    spin_unlock_irqrestore(&mutex->wait.lock, flags);
    return 0;
}

void sema_init(struct semaphore *sem, uint32_t value)
{
    sem->count = (int32_t)value;
    init_waitqueue_head(&sem->wait);
}

int down_trylock(struct semaphore *sem)
{
    uint32_t flags = spin_lock_irqsave(&sem->wait.lock);
    int acquired = sem->count > 0;
    if (acquired)
        --sem->count;
    spin_unlock_irqrestore(&sem->wait.lock, flags);
    return acquired;
}

void down(struct semaphore *sem)
{
    for (;;) {
        uint32_t flags = spin_lock_irqsave(&sem->wait.lock);
        if (sem->count > 0) {
            --sem->count;
            spin_unlock_irqrestore(&sem->wait.lock, flags);
            return;
        }
        wait_enqueue_locked(&sem->wait, t113_current);
        spin_unlock_irqrestore(&sem->wait.lock, flags);
        t113_sched_yield();
    }
}

void up(struct semaphore *sem)
{
    uint32_t flags = spin_lock_irqsave(&sem->wait.lock);
    ++sem->count;
    struct t113_task *task = wait_dequeue_locked(&sem->wait);
    if (task)
        task->state = T113_TASK_RUNNING;
    spin_unlock_irqrestore(&sem->wait.lock, flags);
}
