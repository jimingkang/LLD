#include <stdio.h>
#include <unistd.h>

int main(int argc, char **argv)
{
    const char *path = argc > 1 ? argv[1] : "/";
    struct dirent entry;
    for (unsigned int index = 0;; ++index) {
        int result = readdir(path, index, &entry);
        if (result == 0)
            return 0;
        if (result < 0) {
            printf("ls: cannot read %s\n", path);
            return 1;
        }
        printf("%c %u %u %s\n", entry.d_type == 1u ? 'd' : '-',
               entry.d_ino, entry.d_size, entry.d_name);
    }
}
