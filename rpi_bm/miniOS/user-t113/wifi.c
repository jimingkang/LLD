#include <stdio.h>
#include <unistd.h>

/* wifi: (re)connect using /boot/wifi.txt, then get an address by DHCP
 * unless wifi.txt sets a static one. */
int main(void)
{
    if (netctl(NETCTL_WIFI, 0, 0, 0) < 0) {
        puts("wifi: connect failed");
        return 1;
    }
    netctl(NETCTL_STATUS, 0, 0, 0);
    return 0;
}
