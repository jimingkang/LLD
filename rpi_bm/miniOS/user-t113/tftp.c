#include <stdio.h>
#include <string.h>
#include <unistd.h>

/* tftp <server-ip> [remote-file] [local-path]
 * With only the server address, fetch the standard development image and
 * install it under the same name miniBoot reads from the FAT32 bootfs. */
int main(int argc, char **argv)
{
    char local[128];
    const char *remote;
    const char *base;

    if (argc < 2 || argc > 4) {
        puts("usage: tftp server-ip [remote-file] [local-path]");
        puts("  default: kernel_minios.img -> /boot/kernel_minios.img");
        return 1;
    }

    remote = argc >= 3 ? argv[2] : "kernel_minios.img";
    base = strrchr(remote, '/');
    base = base ? base + 1 : remote;
    if (argc == 4) {
        size_t n = strlen(argv[3]);
        if (!strcmp(argv[3], "/boot"))
            snprintf(local, sizeof(local), "/boot/%s", base);
        else if (n && argv[3][n - 1] == '/')
            snprintf(local, sizeof(local), "%s%s", argv[3], base);
        else
            snprintf(local, sizeof(local), "%s", argv[3]);
    } else if (argc == 2) {
        snprintf(local, sizeof(local), "/boot/kernel_minios.img");
    } else {
        snprintf(local, sizeof(local), "/boot/%s", base);
    }
    int size = tftp(argv[1], remote, local);
    if (size < 0) {
        printf("tftp: failed\n");
        return 1;
    }
    printf("tftp: %d bytes -> %s\n", size, local);
    return 0;
}
