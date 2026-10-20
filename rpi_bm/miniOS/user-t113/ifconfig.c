#include <stdio.h>
#include <string.h>
#include <unistd.h>

/* ifconfig                         show wlan0
 * ifconfig dhcp                    request an address
 * ifconfig <ip> <netmask> [gw]     set a static address */
int main(int argc, char **argv)
{
    int r;
    if (argc == 1)
        r = netctl(NETCTL_STATUS, 0, 0, 0);
    else if (argc == 2 && !strcmp(argv[1], "dhcp"))
        r = netctl(NETCTL_DHCP, 0, 0, 0);
    else if (argc == 3 || argc == 4)
        r = netctl(NETCTL_STATIC, argv[1], argv[2], argc == 4 ? argv[3] : 0);
    else {
        puts("usage: ifconfig [dhcp | ip netmask [gateway]]");
        return 1;
    }
    if (r < 0) {
        puts("ifconfig: failed");
        return 1;
    }
    if (argc > 1)
        netctl(NETCTL_STATUS, 0, 0, 0);
    return 0;
}
