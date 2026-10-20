#ifndef MINIOS_T113_IRQ_H
#define MINIOS_T113_IRQ_H

#include <stdint.h>

typedef void (*t113_irq_fn)(uint32_t irq, void *data);

void t113_irq_init(void);
int t113_request_irq(uint32_t irq, t113_irq_fn handler, void *data);
int t113_irq_dispatch(uint32_t irq);

#endif
