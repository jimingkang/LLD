#ifndef MINIOS_NET_IEEE80211_H
#define MINIOS_NET_IEEE80211_H

#include <stdint.h>

/* IEEE 802.11 frame format, after Linux include/linux/ieee80211.h. */

#define IEEE80211_FCTL_FTYPE        0x000cu
#define IEEE80211_FCTL_STYPE        0x00f0u
#define IEEE80211_FCTL_TODS         0x0100u
#define IEEE80211_FCTL_FROMDS       0x0200u
#define IEEE80211_FCTL_PROTECTED    0x4000u
#define IEEE80211_FCTL_ORDER        0x8000u

#define IEEE80211_FTYPE_MGMT        0x0000u
#define IEEE80211_FTYPE_CTL         0x0004u
#define IEEE80211_FTYPE_DATA        0x0008u

/* management */
#define IEEE80211_STYPE_ASSOC_REQ   0x0000u
#define IEEE80211_STYPE_ASSOC_RESP  0x0010u
#define IEEE80211_STYPE_REASSOC_RESP 0x0030u
#define IEEE80211_STYPE_PROBE_RESP  0x0050u
#define IEEE80211_STYPE_BEACON      0x0080u
#define IEEE80211_STYPE_DISASSOC    0x00a0u
#define IEEE80211_STYPE_AUTH        0x00b0u
#define IEEE80211_STYPE_DEAUTH      0x00c0u
/* data: bit 0x40 = no payload (null), bit 0x80 = QoS */
#define IEEE80211_STYPE_DATA        0x0000u
#define IEEE80211_STYPE_NULLFUNC    0x0040u
#define IEEE80211_STYPE_QOS_DATA    0x0080u

/* struct ieee80211_hdr_3addr: fc, duration, addr1..3, seq_ctrl */
#define IEEE80211_HDR_3ADDR_LEN     24u
#define IEEE80211_QOS_CTL_LEN       2u
#define IEEE80211_HT_CTL_LEN        4u
#define IEEE80211_FCS_LEN           4u
/* management frame body offsets (after the 24-byte header) */
#define IEEE80211_BEACON_IES        12u  /* timestamp 8, interval 2, cap 2 */

#define IEEE80211_CCMP_HDR_LEN      8u
#define IEEE80211_CCMP_MIC_LEN      8u
#define IEEE80211_TKIP_IV_LEN       8u
#define IEEE80211_TKIP_TAIL_LEN     12u  /* Michael MIC 8 + ICV 4 */

/* information elements */
#define WLAN_EID_SSID               0u
#define WLAN_EID_SUPP_RATES         1u
#define WLAN_EID_DS_PARAMS          3u
#define WLAN_EID_TIM                5u
#define WLAN_EID_RSN                48u
#define WLAN_EID_EXT_SUPP_RATES     50u

#define WLAN_CAPABILITY_ESS             0x0001u
#define WLAN_CAPABILITY_PRIVACY         0x0010u
#define WLAN_CAPABILITY_SHORT_PREAMBLE  0x0020u
#define WLAN_CAPABILITY_SHORT_SLOT_TIME 0x0400u

#define WLAN_AUTH_OPEN                  0u
#define WLAN_STATUS_SUCCESS             0u
#define WLAN_REASON_DEAUTH_LEAVING      3u

/* RSN suite selectors (OUI 00-0f-ac + type) */
#define WLAN_CIPHER_SUITE_TKIP      0x000fac02u
#define WLAN_CIPHER_SUITE_CCMP      0x000fac04u
#define WLAN_AKM_SUITE_PSK          0x000fac02u

#define WLAN_KEY_LEN_CCMP           16u
#define WLAN_KEY_LEN_TKIP           32u

static inline uint32_t ieee80211_ftype(uint16_t fc)
{
    return fc & IEEE80211_FCTL_FTYPE;
}

static inline uint32_t ieee80211_stype(uint16_t fc)
{
    return fc & IEEE80211_FCTL_STYPE;
}

static inline int ieee80211_is_mgmt(uint16_t fc)
{
    return ieee80211_ftype(fc) == IEEE80211_FTYPE_MGMT;
}

static inline int ieee80211_is_data(uint16_t fc)
{
    return ieee80211_ftype(fc) == IEEE80211_FTYPE_DATA;
}

static inline int ieee80211_is_data_qos(uint16_t fc)
{
    return ieee80211_is_data(fc) && (fc & IEEE80211_STYPE_QOS_DATA);
}

static inline int ieee80211_has_protected(uint16_t fc)
{
    return (fc & IEEE80211_FCTL_PROTECTED) != 0;
}

/* net/wireless/util.c */
uint32_t ieee80211_hdrlen(uint16_t fc);

#endif
