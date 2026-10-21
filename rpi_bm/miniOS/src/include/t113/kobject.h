#ifndef MINIOS_T113_KOBJECT_H
#define MINIOS_T113_KOBJECT_H

#include <stdint.h>
#include "list.h"
#include "spinlock.h"

/*
 * Lightweight kobject/kset, modelled after Linux. sysfs projects this
 * in-memory topology under /sys without making kobject depend on VFS:
 *   - parent    : position in the (virtual) directory tree, used for paths
 *   - kset      : membership list, used for iteration / lookup by name
 * A kobject may have a parent that differs from its kset (e.g. a driver is
 * a member of the global "drivers" kset but lives under bus/xxx/drivers).
 */

struct kobject;
struct kset;

struct kobj_type {
    void (*release)(struct kobject *kobj);
};

struct kref {
    uint32_t refs;
    spinlock_t lock;
};

struct kobject {
    const char *name;
    struct kobject *parent;
    struct kset *kset;
    const struct kobj_type *ktype;
    struct kref ref;
    struct list_head entry;     /* node in kset->members */
    uint32_t state_added;       /* kobject_add() succeeded */
    uint32_t state_in_kset;     /* linked into kset->members */
};

struct kset {
    struct kobject kobj;
    struct list_head members;
    spinlock_t lock;
};

#define to_kset(k) container_of(k, struct kset, kobj)

void kobject_init(struct kobject *kobj, const struct kobj_type *ktype);
/* parent == 0 && kset != 0  =>  the kset itself becomes the parent. */
int kobject_add(struct kobject *kobj, struct kset *kset,
                struct kobject *parent, const char *name);
void kobject_del(struct kobject *kobj);
struct kobject *kobject_get(struct kobject *kobj);
void kobject_put(struct kobject *kobj);

static inline const char *kobject_name(const struct kobject *kobj)
{
    return kobj->name;
}

/* Build "/a/b/c" from the parent chain. Returns length or -1 if too small. */
int kobject_get_path(const struct kobject *kobj, char *buf, uint32_t size);

void kset_init(struct kset *kset, const struct kobj_type *ktype);
int kset_register(struct kset *kset, struct kobject *parent,
                  const char *name);
void kset_unregister(struct kset *kset);
/* Returns a referenced kobject (kobject_put() it) or 0. */
struct kobject *kset_find_obj(struct kset *kset, const char *name);
/* Calls fn for each member in insertion order; stops on a non-zero return. */
int kset_for_each(struct kset *kset,
                  int (*fn)(struct kobject *kobj, void *data), void *data);

#endif
