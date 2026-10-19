#ifndef MINIOS_NET_XRADIO_STA_H
#define MINIOS_NET_XRADIO_STA_H

#include <stdint.h>

/* Configure the XR829 MAC and perform the initial directed scan. */
int xradio_sta_start(const void *sdd, uint32_t sdd_len);

#endif
