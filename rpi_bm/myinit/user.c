#include "../lib/lib.h"

int main(void)
{
    uint64_t counter = 0;

    while (1) {
        if (counter % 10000000 == 0) {
            printf("User process %u\r\n", counter);
        }
        counter++;
    }

    return 0;
}