#include "kobject.h"

static int string_equal(const char *a, const char *b)
{
    if (!a || !b)
        return 0;
    while (*a && *a == *b) {
        ++a;
        ++b;
    }
    return *a == *b;
}

static uint32_t string_length(const char *s)
{
    uint32_t n = 0;
    while (s && s[n])
        ++n;
    return n;
}

void kobject_init(struct kobject *kobj, const struct kobj_type *ktype)
{
    kobj->name = 0;
    kobj->parent = 0;
    kobj->kset = 0;
    kobj->ktype = ktype;
    kobj->ref.refs = 1;
    spin_lock_init(&kobj->ref.lock);
    INIT_LIST_HEAD(&kobj->entry);
    kobj->state_added = 0;
    kobj->state_in_kset = 0;
}

struct kobject *kobject_get(struct kobject *kobj)
{
    if (!kobj)
        return 0;
    uint32_t flags = spin_lock_irqsave(&kobj->ref.lock);
    if (!kobj->ref.refs) {
        spin_unlock_irqrestore(&kobj->ref.lock, flags);
        return 0;
    }
    ++kobj->ref.refs;
    spin_unlock_irqrestore(&kobj->ref.lock, flags);
    return kobj;
}

void kobject_del(struct kobject *kobj)
{
    if (!kobj || !kobj->state_added)
        return;
    struct kset *kset = kobj->kset;
    if (kset) {
        uint32_t flags = spin_lock_irqsave(&kset->lock);
        if (kobj->state_in_kset) {
            list_del_init(&kobj->entry);
            kobj->state_in_kset = 0;
        }
        spin_unlock_irqrestore(&kset->lock, flags);
    }
    kobj->state_added = 0;
}

void kobject_put(struct kobject *kobj)
{
    if (!kobj)
        return;
    uint32_t flags = spin_lock_irqsave(&kobj->ref.lock);
    if (!kobj->ref.refs) {
        spin_unlock_irqrestore(&kobj->ref.lock, flags);
        return;
    }
    int release = --kobj->ref.refs == 0;
    spin_unlock_irqrestore(&kobj->ref.lock, flags);
    if (!release)
        return;

    kobject_del(kobj);
    struct kobject *parent = kobj->parent;
    kobj->parent = 0;
    if (kobj->ktype && kobj->ktype->release)
        kobj->ktype->release(kobj);
    kobject_put(parent);
}

int kobject_add(struct kobject *kobj, struct kset *kset,
                struct kobject *parent, const char *name)
{
    if (!kobj || !name || !*name || kobj->state_added)
        return -1;
    if (!parent && kset)
        parent = &kset->kobj;
    kobj->name = name;
    kobj->kset = kset;
    if (kset) {
        uint32_t flags = spin_lock_irqsave(&kset->lock);
        struct list_head *node;
        list_for_each(node, &kset->members) {
            struct kobject *member = list_entry(node, struct kobject, entry);
            if (string_equal(member->name, name)) {
                spin_unlock_irqrestore(&kset->lock, flags);
                kobj->kset = 0;
                return -1;
            }
        }
        list_add_tail(&kobj->entry, &kset->members);
        kobj->state_in_kset = 1;
        spin_unlock_irqrestore(&kset->lock, flags);
    }
    kobj->parent = kobject_get(parent);
    kobj->state_added = 1;
    return 0;
}

int kobject_get_path(const struct kobject *kobj, char *buf, uint32_t size)
{
    uint32_t len = 0;
    const struct kobject *k;

    if (!kobj || !buf || !size)
        return -1;
    for (k = kobj; k; k = k->parent)
        len += 1 + string_length(k->name);
    if (len + 1 > size)
        return -1;

    buf[len] = '\0';
    uint32_t pos = len;
    for (k = kobj; k; k = k->parent) {
        uint32_t n = string_length(k->name);
        pos -= n;
        for (uint32_t i = 0; i < n; ++i)
            buf[pos + i] = k->name[i];
        buf[--pos] = '/';
    }
    return (int)len;
}

void kset_init(struct kset *kset, const struct kobj_type *ktype)
{
    kobject_init(&kset->kobj, ktype);
    INIT_LIST_HEAD(&kset->members);
    spin_lock_init(&kset->lock);
}

int kset_register(struct kset *kset, struct kobject *parent,
                  const char *name)
{
    return kobject_add(&kset->kobj, 0, parent, name);
}

void kset_unregister(struct kset *kset)
{
    if (kset)
        kobject_put(&kset->kobj);
}

struct kobject *kset_find_obj(struct kset *kset, const char *name)
{
    if (!kset || !name)
        return 0;
    uint32_t flags = spin_lock_irqsave(&kset->lock);
    struct list_head *node;
    struct kobject *found = 0;
    list_for_each(node, &kset->members) {
        struct kobject *member = list_entry(node, struct kobject, entry);
        if (string_equal(member->name, name)) {
            found = kobject_get(member);
            break;
        }
    }
    spin_unlock_irqrestore(&kset->lock, flags);
    return found;
}

int kset_for_each(struct kset *kset,
                  int (*fn)(struct kobject *kobj, void *data), void *data)
{
    if (!kset || !fn)
        return -1;
    int ret = 0;
    uint32_t flags = spin_lock_irqsave(&kset->lock);
    struct list_head *node;
    list_for_each(node, &kset->members) {
        ret = fn(list_entry(node, struct kobject, entry), data);
        if (ret)
            break;
    }
    spin_unlock_irqrestore(&kset->lock, flags);
    return ret;
}
