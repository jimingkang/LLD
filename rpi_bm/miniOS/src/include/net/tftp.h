#ifndef MINIOS_NET_TFTP_H
#define MINIOS_NET_TFTP_H

#include <stdint.h>

#define TFTP_PORT       69u
#define TFTP_BLOCK_SIZE 512u

enum tftp_state { TFTP_IDLE, TFTP_RRQ_SENT, TFTP_RECEIVING, TFTP_COMPLETE, TFTP_ERROR };

struct tftp_client {
    const char *filename;
    uint8_t *image;
    uint32_t capacity;
    uint32_t size;
    uint16_t next_block;
    uint16_t server_port;
    enum tftp_state state;
    int error_code;
};

void tftp_client_init(struct tftp_client *c, const char *filename,
                      void *image, uint32_t capacity);
/* Build RRQ or ACK UDP payload. Returns payload bytes, or a negative error. */
int tftp_client_rrq(struct tftp_client *c, void *packet, uint32_t capacity);
/* Consume one UDP payload and build ACK in reply. Returns reply bytes;
 * zero means no reply and a negative value means error.  A final DATA packet
 * still returns 4 because RFC 1350 requires its ACK to be transmitted; test
 * c->state == TFTP_COMPLETE after sending that ACK. */
int tftp_client_input(struct tftp_client *c, uint16_t source_port,
                      const void *packet, uint32_t length,
                      void *reply, uint32_t reply_capacity);

#endif
