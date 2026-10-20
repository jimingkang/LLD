/* RFC 1350 read-only TFTP engine. UDP/IP transport is deliberately separate. */
#include "device.h"
#include "net/tftp.h"

#define TFTP_RRQ   1u
#define TFTP_DATA  3u
#define TFTP_ACK   4u
#define TFTP_ERROR 5u

static uint16_t be16(const uint8_t *p) { return ((uint16_t)p[0] << 8) | p[1]; }
static void put_be16(uint8_t *p, uint16_t v) { p[0] = v >> 8; p[1] = v; }

void tftp_client_init(struct tftp_client *c, const char *filename,
                      void *image, uint32_t capacity)
{
    c->filename = filename; c->image = image; c->capacity = capacity;
    c->size = 0; c->next_block = 1; c->server_port = TFTP_PORT;
    c->state = TFTP_IDLE; c->error_code = 0;
}

int tftp_client_rrq(struct tftp_client *c, void *packet, uint32_t capacity)
{
    uint8_t *p = packet;
    uint32_t off = 2, i = 0;
    static const char mode[] = "octet";
    if (!c || !packet || !c->filename || !c->image || capacity < 10u)
        return -EINVAL;
    put_be16(p, TFTP_RRQ);
    while (c->filename[i]) {
        if (off + 2u >= capacity) return -EINVAL;
        p[off++] = (uint8_t)c->filename[i++];
    }
    p[off++] = 0;
    for (i = 0; i < sizeof(mode); ++i) {
        if (off >= capacity) return -EINVAL;
        p[off++] = (uint8_t)mode[i];
    }
    c->state = TFTP_RRQ_SENT;
    return (int)off;
}

int tftp_client_input(struct tftp_client *c, uint16_t source_port,
                      const void *packet, uint32_t length,
                      void *reply, uint32_t reply_capacity)
{
    const uint8_t *p = packet;
    uint8_t *ack = reply;
    if (!c || !p || length < 4u || !ack || reply_capacity < 4u)
        return -EINVAL;
    uint16_t op = be16(p), block = be16(p + 2);
    if (op == TFTP_ERROR) {
        c->error_code = block; c->state = TFTP_ERROR;
        return -EIO;
    }
    if (op != TFTP_DATA)
        return 0;
    if (c->state == TFTP_RRQ_SENT) c->server_port = source_port;
    if (source_port != c->server_port) return 0;
    if (block == (uint16_t)(c->next_block - 1u)) {
        put_be16(ack, TFTP_ACK); put_be16(ack + 2, block);
        return 4;                       /* duplicate DATA: repeat ACK */
    }
    if (block != c->next_block) return 0;
    uint32_t data_len = length - 4u;
    if (data_len > TFTP_BLOCK_SIZE || c->size + data_len > c->capacity) {
        c->state = TFTP_ERROR; c->error_code = 3; /* disk full */
        return -ENOSPC;
    }
    for (uint32_t i = 0; i < data_len; ++i) c->image[c->size + i] = p[4 + i];
    c->size += data_len;
    put_be16(ack, TFTP_ACK); put_be16(ack + 2, block);
    ++c->next_block;
    c->state = data_len < TFTP_BLOCK_SIZE ? TFTP_COMPLETE : TFTP_RECEIVING;
    return 4;
}
