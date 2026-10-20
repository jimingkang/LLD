#ifndef MINIOS_NET_IF_ETHER_H
#define MINIOS_NET_IF_ETHER_H

/* Ethernet II definitions, after Linux include/uapi/linux/if_ether.h. */

#define ETH_ALEN        6u
#define ETH_HLEN        14u
#define ETH_DATA_LEN    1500u
#define ETH_FRAME_LEN   (ETH_HLEN + ETH_DATA_LEN)

#define ETH_P_IP        0x0800u
#define ETH_P_ARP       0x0806u
#define ETH_P_PAE       0x888eu         /* 802.1X / EAPOL */

#endif
