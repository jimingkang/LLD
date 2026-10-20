#ifndef MINIOS_NET_WPA_H
#define MINIOS_NET_WPA_H

#include "net/netdevice.h"

/*
 * In-kernel WPA2-PSK supplicant: the job of user-space wpa_supplicant
 * plus its DHCP hook in Linux.  It reads /boot/wifi.txt, picks the BSS
 * from a cfg80211 scan, builds the RSN element, connects through
 * cfg80211, runs the EAPOL key handshakes over the control port,
 * installs the keys, opens the port and configures IPv4.
 *
 * /boot/wifi.txt:
 *     ssid=MyNetwork
 *     psk=passphrase
 *     ip=192.168.1.50          (optional: static address instead of DHCP)
 *     netmask=255.255.255.0
 *     gateway=192.168.1.1
 */

void wpa_supplicant_init(void);
/* Full connect on an 802.11 device; takes the network lock itself. */
int wpa_supplicant_connect(struct net_device *dev);

#endif
