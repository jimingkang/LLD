#include "irq.h"
#include "spinlock.h"

#define T113_NR_IRQS 160u

struct irq_action {
    t113_irq_fn handler;
    void *data;
};

static struct irq_action actions[T113_NR_IRQS];
static spinlock_t irq_lock = SPINLOCK_INIT;

void t113_irq_init(void)
{
    spin_lock_init(&irq_lock);
    for (uint32_t i = 0; i < T113_NR_IRQS; ++i) {
        actions[i].handler = 0;
        actions[i].data = 0;
    }
}

int t113_request_irq(uint32_t irq, t113_irq_fn handler, void *data)
{
    if (irq >= T113_NR_IRQS || !handler)
        return -1;
    uint32_t flags = spin_lock_irqsave(&irq_lock);
    if (actions[irq].handler) {
        spin_unlock_irqrestore(&irq_lock, flags);
        return -1;
    }
    actions[irq].handler = handler;
    actions[irq].data = data;
    spin_unlock_irqrestore(&irq_lock, flags);
    return 0;
}

int t113_irq_dispatch(uint32_t irq)
{
    if (irq >= T113_NR_IRQS || !actions[irq].handler)
        return 0;
    actions[irq].handler(irq, actions[irq].data);
    return 1;
}
