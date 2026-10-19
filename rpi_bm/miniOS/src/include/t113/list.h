#ifndef MINIOS_T113_LIST_H
#define MINIOS_T113_LIST_H

#include <stdint.h>

struct list_head {
    struct list_head *next;
    struct list_head *prev;
};

#define LIST_HEAD_INIT(name) { &(name), &(name) }
#define LIST_HEAD(name) struct list_head name = LIST_HEAD_INIT(name)

static inline void INIT_LIST_HEAD(struct list_head *head)
{
    head->next = head;
    head->prev = head;
}

static inline int list_empty(const struct list_head *head)
{
    return head->next == head;
}

static inline void __list_add(struct list_head *node,
                              struct list_head *prev,
                              struct list_head *next)
{
    next->prev = node;
    node->next = next;
    node->prev = prev;
    prev->next = node;
}

static inline void list_add(struct list_head *node, struct list_head *head)
{
    __list_add(node, head, head->next);
}

static inline void list_add_tail(struct list_head *node,
                                 struct list_head *head)
{
    __list_add(node, head->prev, head);
}

static inline void list_del_init(struct list_head *node)
{
    node->prev->next = node->next;
    node->next->prev = node->prev;
    INIT_LIST_HEAD(node);
}

#define offsetof_member(type, member) __builtin_offsetof(type, member)
#define container_of(ptr, type, member) \
    ((type *)((char *)(ptr) - offsetof_member(type, member)))

#define list_entry(ptr, type, member) container_of(ptr, type, member)

#define list_for_each(pos, head) \
    for ((pos) = (head)->next; (pos) != (head); (pos) = (pos)->next)

#define list_for_each_safe(pos, n, head) \
    for ((pos) = (head)->next, (n) = (pos)->next; (pos) != (head); \
         (pos) = (n), (n) = (pos)->next)

#endif
