/* Read-only sysfs projection of the miniOS kobject/device/driver model. */
#include "fs/sysfs.h"
#include "fs/vfs.h"
#include "device.h"
#include "driver_model.h"

#define SYSFS_MAGIC       0x62656572u
#define SYSFS_PARTS       8u
#define SYSFS_VALUE_MAX 256u

struct sysfs_path {
    uint32_t count;
    char part[SYSFS_PARTS][VFS_NAME_MAX + 1u];
};

static const struct inode_operations sysfs_iops;
static const struct file_operations sysfs_dir_fops;
static const struct file_operations sysfs_file_fops;

static int text_equal(const char *a, const char *b)
{
    while (*a && *a == *b) { ++a; ++b; }
    return *a == *b;
}

static uint32_t text_length(const char *s)
{
    uint32_t n = 0;
    while (s && s[n]) ++n;
    return n;
}

static uint32_t path_id(const char *path)
{
    uint32_t hash = 2166136261u;
    while (*path) {
        hash ^= (uint8_t)*path++;
        hash *= 16777619u;
    }
    return hash ? hash : 1u;
}

static int split_path(const char *path, struct sysfs_path *result)
{
    const char *p = path;
    result->count = 0;
    if (!p || p[0] != '/' || p[1] != 's' || p[2] != 'y' ||
        p[3] != 's' || (p[4] && p[4] != '/'))
        return -1;
    p += 4;
    while (*p == '/') ++p;
    while (*p) {
        if (result->count == SYSFS_PARTS)
            return -1;
        uint32_t n = 0;
        while (p[n] && p[n] != '/') {
            if (n == VFS_NAME_MAX)
                return -1;
            result->part[result->count][n] = p[n];
            ++n;
        }
        if (!n)
            return -1;
        result->part[result->count][n] = 0;
        ++result->count;
        p += n;
        while (*p == '/') ++p;
    }
    return 0;
}

static int append_text(char *buf, uint32_t cap, uint32_t *used,
                       const char *text)
{
    while (*text) {
        if (*used + 1u >= cap)
            return -1;
        buf[(*used)++] = *text++;
    }
    buf[*used] = 0;
    return 0;
}

static int append_char(char *buf, uint32_t cap, uint32_t *used, char value)
{
    if (*used + 1u >= cap)
        return -1;
    buf[(*used)++] = value;
    buf[*used] = 0;
    return 0;
}

static int device_model_path(const struct sysfs_path *path, uint32_t count,
                             char *buf, uint32_t cap)
{
    uint32_t used = 0;
    buf[0] = 0;
    for (uint32_t i = 0; i < count; ++i) {
        if (append_char(buf, cap, &used, '/') < 0 ||
            append_text(buf, cap, &used, path->part[i]) < 0)
            return -1;
    }
    return 0;
}

struct find_device_context {
    const char *path;
    struct device *device;
};

static int find_device_callback(struct kobject *kobj, void *data)
{
    struct find_device_context *context = data;
    char path[VFS_PATH_MAX];
    if (kobject_get_path(kobj, path, sizeof(path)) >= 0 &&
        text_equal(path, context->path)) {
        context->device = get_device(to_dev(kobj));
        return 1;
    }
    return 0;
}

static struct device *find_device_path(const char *path)
{
    struct find_device_context context = { path, 0 };
    kset_for_each(t113_devices_kset(), find_device_callback, &context);
    return context.device;
}

static struct bus_type *find_bus(const char *name)
{
    struct kobject *kobj = kset_find_obj(t113_buses_kset(), name);
    return kobj ? container_of(kobj, struct bus_type, kobj) : 0;
}

static void put_bus(struct bus_type *bus)
{
    if (bus)
        kobject_put(&bus->kobj);
}

struct find_driver_context {
    const char *name;
    struct device_driver *driver;
};

static int find_driver_callback(struct device_driver *driver, void *data)
{
    struct find_driver_context *context = data;
    if (!text_equal(driver->name, context->name))
        return 0;
    kobject_get(&driver->kobj);
    context->driver = driver;
    return 1;
}

static struct device_driver *find_driver(struct bus_type *bus,
                                         const char *name)
{
    struct find_driver_context context = { name, 0 };
    bus_for_each_drv(bus, find_driver_callback, &context);
    return context.driver;
}

static void put_driver(struct device_driver *driver)
{
    if (driver)
        kobject_put(&driver->kobj);
}

static int is_device_attribute(const char *name)
{
    return text_equal(name, "name") || text_equal(name, "bus") ||
           text_equal(name, "driver") || text_equal(name, "path");
}

static const struct device_attribute *find_device_attribute(
    const struct device *device, const char *name)
{
    for (uint32_t i = 0; device && i < device->num_attributes; ++i)
        if (text_equal(device->attributes[i].name, name))
            return &device->attributes[i];
    return 0;
}

static int is_driver_attribute(const char *name)
{
    return text_equal(name, "name") || text_equal(name, "bound");
}

/* Return VFS_NODE_DIR/VFS_NODE_FILE, or 0 when the path does not exist. */
static uint32_t sysfs_path_type(const struct sysfs_path *path)
{
    if (!path->count)
        return VFS_NODE_DIR;
    if (path->count == 1u &&
        (text_equal(path->part[0], "devices") ||
         text_equal(path->part[0], "bus")))
        return VFS_NODE_DIR;

    if (text_equal(path->part[0], "devices")) {
        char model[VFS_PATH_MAX];
        if (device_model_path(path, path->count, model, sizeof(model)) < 0)
            return 0;
        struct device *device = find_device_path(model);
        if (device) {
            put_device(device);
            return VFS_NODE_DIR;
        }
        if (path->count < 3u ||
            device_model_path(path, path->count - 1u,
                              model, sizeof(model)) < 0)
            return 0;
        device = find_device_path(model);
        if (!device)
            return 0;
        int exists = is_device_attribute(path->part[path->count - 1u]) ||
                     find_device_attribute(
                         device, path->part[path->count - 1u]);
        put_device(device);
        return exists ? VFS_NODE_FILE : 0;
    }

    if (!text_equal(path->part[0], "bus") || path->count < 2u)
        return 0;
    struct bus_type *bus = find_bus(path->part[1]);
    if (!bus)
        return 0;
    uint32_t type = 0;
    if (path->count == 2u)
        type = VFS_NODE_DIR;
    else if (path->count == 3u &&
             (text_equal(path->part[2], "devices") ||
              text_equal(path->part[2], "drivers")))
        type = VFS_NODE_DIR;
    else if (path->count == 3u && text_equal(path->part[2], "name"))
        type = VFS_NODE_FILE;
    else if (path->count == 4u && text_equal(path->part[2], "devices")) {
        struct device *device = bus_find_device_by_name(bus, path->part[3]);
        if (device) {
            type = VFS_NODE_DIR;
            put_device(device);
        }
    } else if (path->count == 5u &&
               text_equal(path->part[2], "devices")) {
        struct device *device = bus_find_device_by_name(bus, path->part[3]);
        if (device && (is_device_attribute(path->part[4]) ||
                       find_device_attribute(device, path->part[4]))) {
            type = VFS_NODE_FILE;
        }
        put_device(device);
    } else if (path->count == 4u && text_equal(path->part[2], "drivers")) {
        struct device_driver *driver = find_driver(bus, path->part[3]);
        if (driver) {
            type = VFS_NODE_DIR;
            put_driver(driver);
        }
    } else if (path->count == 5u &&
               text_equal(path->part[2], "drivers") &&
               is_driver_attribute(path->part[4])) {
        struct device_driver *driver = find_driver(bus, path->part[3]);
        if (driver) {
            type = VFS_NODE_FILE;
            put_driver(driver);
        }
    }
    put_bus(bus);
    return type;
}

static int sysfs_lookup(struct inode *directory, struct dentry *child)
{
    (void)directory;
    struct sysfs_path path;
    if (split_path(child->d_path, &path) < 0)
        return -1;
    uint32_t type = sysfs_path_type(&path);
    if (!type)
        return -1;
    return t113_vfs_bind_inode(child, path_id(child->d_path), 0, type, 0, 0,
                               &sysfs_iops,
                               type == VFS_NODE_DIR ? &sysfs_dir_fops
                                                    : &sysfs_file_fops);
}

static void fill_dirent(struct vfs_dirent *entry, const char *parent,
                        const char *name, uint32_t type)
{
    char path[VFS_PATH_MAX];
    uint32_t used = 0;
    path[0] = 0;
    append_text(path, sizeof(path), &used, parent);
    if (!used || path[used - 1u] != '/')
        append_char(path, sizeof(path), &used, '/');
    append_text(path, sizeof(path), &used, name);
    entry->id = path_id(path);
    entry->type = type;
    entry->size = 0;
    uint32_t n = 0;
    while (name[n] && n < VFS_NAME_MAX) {
        entry->name[n] = name[n];
        ++n;
    }
    entry->name[n] = 0;
}

struct nth_kobject_context {
    uint32_t wanted;
    uint32_t seen;
    const struct device *parent;
    struct kobject *found;
};

static int nth_device_child(struct kobject *kobj, void *data)
{
    struct nth_kobject_context *context = data;
    struct device *device = to_dev(kobj);
    if (device->parent != context->parent)
        return 0;
    if (context->seen++ != context->wanted)
        return 0;
    context->found = kobj;
    return 1;
}

static int nth_kobject(struct kobject *kobj, void *data)
{
    struct nth_kobject_context *context = data;
    if (context->seen++ != context->wanted)
        return 0;
    context->found = kobj;
    return 1;
}

struct nth_device_context {
    uint32_t wanted;
    uint32_t seen;
    struct device *found;
};

static int nth_bus_device(struct device *device, void *data)
{
    struct nth_device_context *context = data;
    if (context->seen++ != context->wanted)
        return 0;
    context->found = device;
    return 1;
}

struct nth_driver_context {
    uint32_t wanted;
    uint32_t seen;
    struct device_driver *found;
};

static int nth_bus_driver(struct device_driver *driver, void *data)
{
    struct nth_driver_context *context = data;
    if (context->seen++ != context->wanted)
        return 0;
    context->found = driver;
    return 1;
}

static int sysfs_readdir(struct inode *inode, const char *raw_path,
                         uint32_t index, struct vfs_dirent *entry)
{
    (void)inode;
    struct sysfs_path path;
    if (split_path(raw_path, &path) < 0)
        return -1;
    if (!path.count) {
        if (index == 0u) fill_dirent(entry, raw_path, "devices", VFS_NODE_DIR);
        else if (index == 1u) fill_dirent(entry, raw_path, "bus", VFS_NODE_DIR);
        else return 0;
        return 1;
    }

    if (text_equal(path.part[0], "devices")) {
        struct device *parent = 0;
        if (path.count > 1u) {
            char model[VFS_PATH_MAX];
            if (device_model_path(&path, path.count, model, sizeof(model)) < 0)
                return -1;
            parent = find_device_path(model);
            if (!parent)
                return -1;
        }
        struct nth_kobject_context context = { index, 0, parent, 0 };
        kset_for_each(t113_devices_kset(), nth_device_child, &context);
        if (context.found) {
            fill_dirent(entry, raw_path, kobject_name(context.found),
                        VFS_NODE_DIR);
            put_device(parent);
            return 1;
        }
        uint32_t child_count = context.seen;
        static const char *const attrs[] = { "name", "bus", "driver", "path" };
        uint32_t attr_index = index - child_count;
        if (!parent || attr_index >= 4u + parent->num_attributes) {
            put_device(parent);
            return 0;
        }
        const char *name = attr_index < 4u
                         ? attrs[attr_index]
                         : parent->attributes[attr_index - 4u].name;
        fill_dirent(entry, raw_path, name, VFS_NODE_FILE);
        put_device(parent);
        return 1;
    }

    if (!text_equal(path.part[0], "bus"))
        return -1;
    if (path.count == 1u) {
        struct nth_kobject_context context = { index, 0, 0, 0 };
        kset_for_each(t113_buses_kset(), nth_kobject, &context);
        if (!context.found)
            return 0;
        fill_dirent(entry, raw_path, kobject_name(context.found), VFS_NODE_DIR);
        return 1;
    }

    struct bus_type *bus = find_bus(path.part[1]);
    if (!bus)
        return -1;
    if (path.count == 2u) {
        static const char *const entries[] = { "devices", "drivers", "name" };
        static const uint32_t types[] = {
            VFS_NODE_DIR, VFS_NODE_DIR, VFS_NODE_FILE
        };
        if (index >= 3u) {
            put_bus(bus);
            return 0;
        }
        fill_dirent(entry, raw_path, entries[index], types[index]);
        put_bus(bus);
        return 1;
    }
    if (path.count == 3u && text_equal(path.part[2], "devices")) {
        struct nth_device_context context = { index, 0, 0 };
        bus_for_each_dev(bus, nth_bus_device, &context);
        if (context.found)
            fill_dirent(entry, raw_path, dev_name(context.found), VFS_NODE_DIR);
        put_bus(bus);
        return context.found ? 1 : 0;
    }
    if (path.count == 3u && text_equal(path.part[2], "drivers")) {
        struct nth_driver_context context = { index, 0, 0 };
        bus_for_each_drv(bus, nth_bus_driver, &context);
        if (context.found)
            fill_dirent(entry, raw_path, context.found->name, VFS_NODE_DIR);
        put_bus(bus);
        return context.found ? 1 : 0;
    }
    if (path.count == 4u && text_equal(path.part[2], "devices")) {
        static const char *const attrs[] = { "name", "bus", "driver", "path" };
        struct device *device = bus_find_device_by_name(bus, path.part[3]);
        uint32_t count = device ? 4u + device->num_attributes : 0u;
        if (index < count) {
            const char *name = index < 4u
                             ? attrs[index]
                             : device->attributes[index - 4u].name;
            fill_dirent(entry, raw_path, name, VFS_NODE_FILE);
        }
        put_device(device);
        put_bus(bus);
        return index < count ? 1 : 0;
    }
    if (path.count == 4u && text_equal(path.part[2], "drivers")) {
        static const char *const attrs[] = { "name", "bound" };
        if (index < 2u)
            fill_dirent(entry, raw_path, attrs[index], VFS_NODE_FILE);
        put_bus(bus);
        return index < 2u ? 1 : 0;
    }
    put_bus(bus);
    return -1;
}

static int show_device(struct device *device, const char *attribute,
                       char *buf, uint32_t cap)
{
    uint32_t used = 0;
    buf[0] = 0;
    if (text_equal(attribute, "name"))
        append_text(buf, cap, &used, dev_name(device));
    else if (text_equal(attribute, "bus"))
        append_text(buf, cap, &used, device->bus ? device->bus->name : "(none)");
    else if (text_equal(attribute, "driver"))
        append_text(buf, cap, &used,
                    device->driver ? device->driver->name : "(none)");
    else if (text_equal(attribute, "path")) {
        if (kobject_get_path(&device->kobj, buf, cap) < 0)
            return -1;
        used = text_length(buf);
    } else {
        const struct device_attribute *device_attribute =
            find_device_attribute(device, attribute);
        if (!device_attribute || !device_attribute->show)
            return -1;
        return device_attribute->show(device, buf, cap);
    }
    if (append_char(buf, cap, &used, '\n') < 0)
        return -1;
    return (int)used;
}

struct bound_context {
    char *buf;
    uint32_t cap;
    uint32_t used;
};

static int show_bound_device(struct device *device, void *data)
{
    struct bound_context *context = data;
    if (context->used && append_char(context->buf, context->cap,
                                     &context->used, ' ') < 0)
        return -1;
    return append_text(context->buf, context->cap, &context->used,
                       dev_name(device));
}

static int show_driver(struct device_driver *driver, const char *attribute,
                       char *buf, uint32_t cap)
{
    uint32_t used = 0;
    buf[0] = 0;
    if (text_equal(attribute, "name")) {
        if (append_text(buf, cap, &used, driver->name) < 0)
            return -1;
    } else if (text_equal(attribute, "bound")) {
        struct bound_context context = { buf, cap, 0 };
        if (driver_for_each_device(driver, show_bound_device, &context) < 0)
            return -1;
        used = context.used;
    } else {
        return -1;
    }
    if (append_char(buf, cap, &used, '\n') < 0)
        return -1;
    return (int)used;
}

static int sysfs_generate(const struct sysfs_path *path,
                          char *buf, uint32_t cap)
{
    if (path->count >= 3u && text_equal(path->part[0], "devices")) {
        char model[VFS_PATH_MAX];
        if (device_model_path(path, path->count - 1u,
                              model, sizeof(model)) < 0)
            return -1;
        struct device *device = find_device_path(model);
        if (!device)
            return -1;
        int result = show_device(device, path->part[path->count - 1u],
                                 buf, cap);
        put_device(device);
        return result;
    }
    if (path->count < 3u || !text_equal(path->part[0], "bus"))
        return -1;
    struct bus_type *bus = find_bus(path->part[1]);
    if (!bus)
        return -1;
    int result = -1;
    if (path->count == 3u && text_equal(path->part[2], "name")) {
        uint32_t used = 0;
        buf[0] = 0;
        if (append_text(buf, cap, &used, bus->name) == 0 &&
            append_char(buf, cap, &used, '\n') == 0)
            result = (int)used;
    } else if (path->count == 5u &&
               text_equal(path->part[2], "devices")) {
        struct device *device = bus_find_device_by_name(bus, path->part[3]);
        if (device) {
            result = show_device(device, path->part[4], buf, cap);
            put_device(device);
        }
    } else if (path->count == 5u &&
               text_equal(path->part[2], "drivers")) {
        struct device_driver *driver = find_driver(bus, path->part[3]);
        if (driver) {
            result = show_driver(driver, path->part[4], buf, cap);
            put_driver(driver);
        }
    }
    put_bus(bus);
    return result;
}

static int sysfs_read(struct file *file, void *destination, uint32_t count)
{
    if (!file || !file->f_dentry || !destination)
        return -1;
    struct sysfs_path path;
    if (split_path(file->f_dentry->d_path, &path) < 0)
        return -1;
    char value[SYSFS_VALUE_MAX];
    int length = sysfs_generate(&path, value, sizeof(value));
    if (length < 0)
        return -1;
    if (file->f_pos >= (uint32_t)length)
        return 0;
    uint32_t available = (uint32_t)length - file->f_pos;
    if (count > available)
        count = available;
    char *out = destination;
    for (uint32_t i = 0; i < count; ++i)
        out[i] = value[file->f_pos + i];
    return (int)count;
}

static const struct inode_operations sysfs_iops = {
    .lookup = sysfs_lookup,
};

static const struct file_operations sysfs_dir_fops = {
    .readdir = sysfs_readdir,
};

static const struct file_operations sysfs_file_fops = {
    .read = sysfs_read,
};

int t113_sysfs_init(void)
{
    return t113_vfs_mount_fs("/sys", SYSFS_MAGIC, 0, 0,
                             &sysfs_iops, &sysfs_dir_fops);
}
