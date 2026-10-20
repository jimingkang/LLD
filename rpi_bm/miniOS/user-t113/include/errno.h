#ifndef MINIOS_ERRNO_H
#define MINIOS_ERRNO_H

extern int errno;

#define EPERM   1
#define ENOENT  2
#define EIO     5
#define ECHILD  10
#define ENOMEM  12
#define EFAULT  14
#define EBUSY   16
#define ENODEV  19
#define EINVAL  22
#define ENOSPC  28
#define ENOSYS  38
#define ETIMEDOUT 110

#endif
