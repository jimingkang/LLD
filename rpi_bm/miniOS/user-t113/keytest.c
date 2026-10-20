#include <fcntl.h>
#include <input.h>
#include <stdio.h>
#include <unistd.h>

int main(void)
{
    int fd = open("/dev/key0", O_RDONLY);
    if (fd < 0) {
        printf("keytest: cannot open /dev/key0\n");
        return 1;
    }
    printf("keytest: press the USER key beside RESET\n");
    for (;;) {
        struct input_event event;
        int bytes = read(fd, &event, sizeof(event));
        if (bytes != (int)sizeof(event)) {
            printf("keytest: read failed\n");
            return 1;
        }
        if (event.type == EV_KEY)
            printf("key code=%u %s time=%u ms\n", event.code,
                   event.value ? "pressed" : "released", event.time_ms);
    }
}
