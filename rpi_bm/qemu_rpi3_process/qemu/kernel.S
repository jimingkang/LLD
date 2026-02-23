
kernel.elf:     file format elf64-littleaarch64


Disassembly of section .text:

ffff000000080000 <start>:

.section .text
.global start

start:
    mrs x0, mpidr_el1
ffff000000080000:	d53800a0 	mrs	x0, mpidr_el1
    and x0, x0, #3
ffff000000080004:	92400400 	and	x0, x0, #0x3
    cmp x0, #0
ffff000000080008:	f100001f 	cmp	x0, #0x0
    beq kernel_entry
ffff00000008000c:	54000040 	b.eq	ffff000000080014 <kernel_entry>  // b.none

ffff000000080010 <end>:

end:
    b end
ffff000000080010:	14000000 	b	ffff000000080010 <end>

ffff000000080014 <kernel_entry>:

kernel_entry:
    mrs x0, currentel
ffff000000080014:	d5384240 	mrs	x0, currentel
    lsr x0, x0, #2
ffff000000080018:	d342fc00 	lsr	x0, x0, #2
    cmp x0, #2
ffff00000008001c:	f100081f 	cmp	x0, #0x2
    bne end
ffff000000080020:	54ffff81 	b.ne	ffff000000080010 <end>  // b.any

    msr sctlr_el1, xzr
ffff000000080024:	d518101f 	msr	sctlr_el1, xzr
    mov x0, #(1 << 31)
ffff000000080028:	d2b00000 	mov	x0, #0x80000000            	// #2147483648
    msr hcr_el2, x0
ffff00000008002c:	d51c1100 	msr	hcr_el2, x0

    mov x0, #0b1111000101
ffff000000080030:	d28078a0 	mov	x0, #0x3c5                 	// #965
    msr spsr_el2, x0
ffff000000080034:	d51c4000 	msr	spsr_el2, x0

    adr x0, el1_entry
ffff000000080038:	10000060 	adr	x0, ffff000000080044 <el1_entry>
    msr elr_el2, x0
ffff00000008003c:	d51c4020 	msr	elr_el2, x0

    eret
ffff000000080040:	d69f03e0 	eret

ffff000000080044 <el1_entry>:

el1_entry:
    mov sp, #0x80000
ffff000000080044:	b26d03ff 	mov	sp, #0x80000               	// #524288

    bl setup_vm
ffff000000080048:	94000801 	bl	ffff00000008204c <setup_vm>
    bl enable_mmu
ffff00000008004c:	940007f4 	bl	ffff00000008201c <enable_mmu>

    ldr x0, =FS_BASE
ffff000000080050:	58000280 	ldr	x0, ffff0000000800a0 <ret_from_fork+0xc>
    ldr x1, =bss_start
ffff000000080054:	580002a1 	ldr	x1, ffff0000000800a8 <ret_from_fork+0x14>
    ldr x2, =FS_SIZE
ffff000000080058:	580002c2 	ldr	x2, ffff0000000800b0 <ret_from_fork+0x1c>
    bl memcpy
ffff00000008005c:	9400004f 	bl	ffff000000080198 <memcpy>

    ldr x0, =bss_start
ffff000000080060:	58000240 	ldr	x0, ffff0000000800a8 <ret_from_fork+0x14>
    ldr x1, =bss_end
ffff000000080064:	580002a1 	ldr	x1, ffff0000000800b8 <ret_from_fork+0x24>
    sub x2, x1, x0
ffff000000080068:	cb000022 	sub	x2, x1, x0
    mov x1, #0
ffff00000008006c:	d2800001 	mov	x1, #0x0                   	// #0
    bl memset
ffff000000080070:	94000039 	bl	ffff000000080154 <memset>

    ldr x0, =vector_table
ffff000000080074:	58000260 	ldr	x0, ffff0000000800c0 <ret_from_fork+0x2c>
    msr vbar_el1, x0
ffff000000080078:	d518c000 	msr	vbar_el1, x0
    
    mov x0, #0xffff000000000000
ffff00000008007c:	d2ffffe0 	mov	x0, #0xffff000000000000    	// #-281474976710656
    add sp, sp, x0
ffff000000080080:	8b2063ff 	add	sp, sp, x0

    ldr x0, =KMain
ffff000000080084:	58000220 	ldr	x0, ffff0000000800c8 <ret_from_fork+0x34>
    blr x0
ffff000000080088:	d63f0000 	blr	x0

ffff00000008008c <halt>:

halt:
    wfi
ffff00000008008c:	d503207f 	wfi
    b halt
ffff000000080090:	17ffffff 	b	ffff00000008008c <halt>

ffff000000080094 <ret_from_fork>:
    
.global ret_from_fork
ret_from_fork:
    mov x0, x19
ffff000000080094:	aa1303e0 	mov	x0, x19
    blr x0
ffff000000080098:	d63f0000 	blr	x0
ffff00000008009c:	00000000 	.inst	0x00000000 ; undefined
ffff0000000800a0:	30000000 	.word	0x30000000
ffff0000000800a4:	ffff0000 	.word	0xffff0000
ffff0000000800a8:	0008de10 	.word	0x0008de10
ffff0000000800ac:	ffff0000 	.word	0xffff0000
ffff0000000800b0:	031b6000 	.word	0x031b6000
ffff0000000800b4:	00000000 	.word	0x00000000
ffff0000000800b8:	0008e0e8 	.word	0x0008e0e8
ffff0000000800bc:	ffff0000 	.word	0xffff0000
ffff0000000800c0:	00081000 	.word	0x00081000
ffff0000000800c4:	ffff0000 	.word	0xffff0000
ffff0000000800c8:	000800d0 	.word	0x000800d0
ffff0000000800cc:	ffff0000 	.word	0xffff0000

ffff0000000800d0 <KMain>:
#include "stddef.h"
#include "process.h"
#include "syscall.h"

void KMain(void)
{
ffff0000000800d0:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffff0000000800d4:	910003fd 	mov	x29, sp
    init_uart();
ffff0000000800d8:	94000105 	bl	ffff0000000804ec <init_uart>
    printk("Hello, Raspberry pi\r\n");
ffff0000000800dc:	90000060 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff0000000800e0:	91012000 	add	x0, x0, #0x48
ffff0000000800e4:	940001f2 	bl	ffff0000000808ac <printk>
    printk("We are at EL %u\r\n", (uint64_t)get_el());
ffff0000000800e8:	94000011 	bl	ffff00000008012c <get_el>
ffff0000000800ec:	12001c00 	and	w0, w0, #0xff
ffff0000000800f0:	92401c00 	and	x0, x0, #0xff
ffff0000000800f4:	aa0003e1 	mov	x1, x0
ffff0000000800f8:	90000060 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff0000000800fc:	91018000 	add	x0, x0, #0x60
ffff000000080100:	940001eb 	bl	ffff0000000808ac <printk>

    init_memory();
ffff000000080104:	94002a1d 	bl	ffff00000008a978 <init_memory>
    init_fs();
ffff000000080108:	94002bdf 	bl	ffff00000008b084 <init_fs>
    init_system_call();
ffff00000008010c:	94002fb9 	bl	ffff00000008bff0 <init_system_call>
    init_timer();
ffff000000080110:	9400065c 	bl	ffff000000081a80 <init_timer>
    init_interrupt_controller();
ffff000000080114:	94000642 	bl	ffff000000081a1c <init_interrupt_controller>
    init_process();
ffff000000080118:	94002dba 	bl	ffff00000008b800 <init_process>
    enable_irq();
ffff00000008011c:	94000618 	bl	ffff00000008197c <enable_irq>
ffff000000080120:	d503201f 	nop
ffff000000080124:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffff000000080128:	d65f03c0 	ret

ffff00000008012c <get_el>:
.global memmove
.global memcmp
.global get_el

get_el:
    mrs x0, currentel
ffff00000008012c:	d5384240 	mrs	x0, currentel
    lsr x0, x0, #2
ffff000000080130:	d342fc00 	lsr	x0, x0, #2
    ret
ffff000000080134:	d65f03c0 	ret

ffff000000080138 <delay>:

delay:
    subs x0, x0, #1
ffff000000080138:	f1000400 	subs	x0, x0, #0x1
    bne delay
ffff00000008013c:	54ffffe1 	b.ne	ffff000000080138 <delay>  // b.any
    ret
ffff000000080140:	d65f03c0 	ret

ffff000000080144 <out_word>:

out_word:
    str w1, [x0]
ffff000000080144:	b9000001 	str	w1, [x0]
    ret
ffff000000080148:	d65f03c0 	ret

ffff00000008014c <in_word>:

in_word:
    ldr w0, [x0]
ffff00000008014c:	b9400000 	ldr	w0, [x0]
    ret
ffff000000080150:	d65f03c0 	ret

ffff000000080154 <memset>:

memset:
    cmp x2, #0
ffff000000080154:	f100005f 	cmp	x2, #0x0
    beq memset_end
ffff000000080158:	54000080 	b.eq	ffff000000080168 <memset_end>  // b.none

ffff00000008015c <set>:

set:
    strb w1, [x0], #1
ffff00000008015c:	38001401 	strb	w1, [x0], #1
    subs x2, x2, #1
ffff000000080160:	f1000442 	subs	x2, x2, #0x1
    bne set
ffff000000080164:	54ffffc1 	b.ne	ffff00000008015c <set>  // b.any

ffff000000080168 <memset_end>:

memset_end:
    ret
ffff000000080168:	d65f03c0 	ret

ffff00000008016c <memcmp>:

memcmp:
    mov x3, x0
ffff00000008016c:	aa0003e3 	mov	x3, x0
    mov x0, #0
ffff000000080170:	d2800000 	mov	x0, #0x0                   	// #0

ffff000000080174 <compare>:

compare:
    cmp x2, #0
ffff000000080174:	f100005f 	cmp	x2, #0x0
    beq memcmp_end
ffff000000080178:	540000e0 	b.eq	ffff000000080194 <memcmp_end>  // b.none

    ldrb w4, [x3], #1
ffff00000008017c:	38401464 	ldrb	w4, [x3], #1
    ldrb w5, [x1], #1
ffff000000080180:	38401425 	ldrb	w5, [x1], #1
    sub x2, x2, #1
ffff000000080184:	d1000442 	sub	x2, x2, #0x1
    cmp w4, w5
ffff000000080188:	6b05009f 	cmp	w4, w5
    beq compare
ffff00000008018c:	54ffff40 	b.eq	ffff000000080174 <compare>  // b.none

    mov x0, #1
ffff000000080190:	d2800020 	mov	x0, #0x1                   	// #1

ffff000000080194 <memcmp_end>:

memcmp_end:
    ret
ffff000000080194:	d65f03c0 	ret

ffff000000080198 <memcpy>:

memmove:
memcpy:
    cmp x2, #0
ffff000000080198:	f100005f 	cmp	x2, #0x0
    beq memcpy_end
ffff00000008019c:	54000220 	b.eq	ffff0000000801e0 <memcpy_end>  // b.none

    mov x4, #1
ffff0000000801a0:	d2800024 	mov	x4, #0x1                   	// #1

    cmp x1, x0
ffff0000000801a4:	eb00003f 	cmp	x1, x0
    bhs copy
ffff0000000801a8:	54000102 	b.cs	ffff0000000801c8 <copy>  // b.hs, b.nlast
    add x3, x1, x2
ffff0000000801ac:	8b020023 	add	x3, x1, x2
    cmp x3, x0
ffff0000000801b0:	eb00007f 	cmp	x3, x0
    bls copy
ffff0000000801b4:	540000a9 	b.ls	ffff0000000801c8 <copy>  // b.plast

ffff0000000801b8 <overlap>:

overlap:
    sub x3, x2, #1
ffff0000000801b8:	d1000443 	sub	x3, x2, #0x1
    add x0, x0, x3
ffff0000000801bc:	8b030000 	add	x0, x0, x3
    add x1, x1, x3
ffff0000000801c0:	8b030021 	add	x1, x1, x3
    neg x4, x4
ffff0000000801c4:	cb0403e4 	neg	x4, x4

ffff0000000801c8 <copy>:

copy:
    ldrb w3, [x1]
ffff0000000801c8:	39400023 	ldrb	w3, [x1]
    strb w3, [x0]
ffff0000000801cc:	39000003 	strb	w3, [x0]
    add x0, x0, x4
ffff0000000801d0:	8b040000 	add	x0, x0, x4
    add x1, x1, x4
ffff0000000801d4:	8b040021 	add	x1, x1, x4

    subs x2, x2, #1
ffff0000000801d8:	f1000442 	subs	x2, x2, #0x1
    bne copy
ffff0000000801dc:	54ffff61 	b.ne	ffff0000000801c8 <copy>  // b.any

ffff0000000801e0 <memcpy_end>:

memcpy_end:
    ret
ffff0000000801e0:	d65f03c0 	ret

ffff0000000801e4 <append_list_tail>:
#include "process.h"
#include "stddef.h"
#include "debug.h"

void append_list_tail(struct HeadList *list, struct List *item)
{
ffff0000000801e4:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff0000000801e8:	910003fd 	mov	x29, sp
ffff0000000801ec:	f9000fe0 	str	x0, [sp, #24]
ffff0000000801f0:	f9000be1 	str	x1, [sp, #16]
    item->next = NULL;
ffff0000000801f4:	f9400be0 	ldr	x0, [sp, #16]
ffff0000000801f8:	f900001f 	str	xzr, [x0]

    if (is_list_empty(list)) {
ffff0000000801fc:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000080200:	9400002f 	bl	ffff0000000802bc <is_list_empty>
ffff000000080204:	12001c00 	and	w0, w0, #0xff
ffff000000080208:	7100001f 	cmp	w0, #0x0
ffff00000008020c:	54000100 	b.eq	ffff00000008022c <append_list_tail+0x48>  // b.none
        list->next = item;
ffff000000080210:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000080214:	f9400be1 	ldr	x1, [sp, #16]
ffff000000080218:	f9000001 	str	x1, [x0]
        list->tail = item;
ffff00000008021c:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000080220:	f9400be1 	ldr	x1, [sp, #16]
ffff000000080224:	f9000401 	str	x1, [x0, #8]
    }
    else {
        list->tail->next = item;
        list->tail = item;
    }
}
ffff000000080228:	14000008 	b	ffff000000080248 <append_list_tail+0x64>
        list->tail->next = item;
ffff00000008022c:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000080230:	f9400400 	ldr	x0, [x0, #8]
ffff000000080234:	f9400be1 	ldr	x1, [sp, #16]
ffff000000080238:	f9000001 	str	x1, [x0]
        list->tail = item;
ffff00000008023c:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000080240:	f9400be1 	ldr	x1, [sp, #16]
ffff000000080244:	f9000401 	str	x1, [x0, #8]
}
ffff000000080248:	d503201f 	nop
ffff00000008024c:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff000000080250:	d65f03c0 	ret

ffff000000080254 <remove_list_head>:

struct List* remove_list_head(struct HeadList *list)
{
ffff000000080254:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff000000080258:	910003fd 	mov	x29, sp
ffff00000008025c:	f9000fe0 	str	x0, [sp, #24]
    struct List *item;

    if (is_list_empty(list)) {
ffff000000080260:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000080264:	94000016 	bl	ffff0000000802bc <is_list_empty>
ffff000000080268:	12001c00 	and	w0, w0, #0xff
ffff00000008026c:	7100001f 	cmp	w0, #0x0
ffff000000080270:	54000060 	b.eq	ffff00000008027c <remove_list_head+0x28>  // b.none
        return NULL;
ffff000000080274:	d2800000 	mov	x0, #0x0                   	// #0
ffff000000080278:	1400000f 	b	ffff0000000802b4 <remove_list_head+0x60>
    }

    item = list->next;
ffff00000008027c:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000080280:	f9400000 	ldr	x0, [x0]
ffff000000080284:	f90017e0 	str	x0, [sp, #40]
    list->next = item->next;
ffff000000080288:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008028c:	f9400001 	ldr	x1, [x0]
ffff000000080290:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000080294:	f9000001 	str	x1, [x0]
    
    if (list->next == NULL) {
ffff000000080298:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008029c:	f9400000 	ldr	x0, [x0]
ffff0000000802a0:	f100001f 	cmp	x0, #0x0
ffff0000000802a4:	54000061 	b.ne	ffff0000000802b0 <remove_list_head+0x5c>  // b.any
        list->tail = NULL;
ffff0000000802a8:	f9400fe0 	ldr	x0, [sp, #24]
ffff0000000802ac:	f900041f 	str	xzr, [x0, #8]
    }
    
    return item;
ffff0000000802b0:	f94017e0 	ldr	x0, [sp, #40]
}
ffff0000000802b4:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff0000000802b8:	d65f03c0 	ret

ffff0000000802bc <is_list_empty>:

bool is_list_empty(struct HeadList *list)
{
ffff0000000802bc:	d10043ff 	sub	sp, sp, #0x10
ffff0000000802c0:	f90007e0 	str	x0, [sp, #8]
    return (list->next == NULL);
ffff0000000802c4:	f94007e0 	ldr	x0, [sp, #8]
ffff0000000802c8:	f9400000 	ldr	x0, [x0]
ffff0000000802cc:	f100001f 	cmp	x0, #0x0
ffff0000000802d0:	1a9f17e0 	cset	w0, eq  // eq = none
ffff0000000802d4:	12001c00 	and	w0, w0, #0xff
}
ffff0000000802d8:	910043ff 	add	sp, sp, #0x10
ffff0000000802dc:	d65f03c0 	ret

ffff0000000802e0 <remove_list>:

struct List* remove_list(struct HeadList *list, int wait)
{
ffff0000000802e0:	d100c3ff 	sub	sp, sp, #0x30
ffff0000000802e4:	f90007e0 	str	x0, [sp, #8]
ffff0000000802e8:	b90007e1 	str	w1, [sp, #4]
    struct List *current = list->next;
ffff0000000802ec:	f94007e0 	ldr	x0, [sp, #8]
ffff0000000802f0:	f9400000 	ldr	x0, [x0]
ffff0000000802f4:	f90017e0 	str	x0, [sp, #40]
    struct List *prev = (struct List*)list;
ffff0000000802f8:	f94007e0 	ldr	x0, [sp, #8]
ffff0000000802fc:	f90013e0 	str	x0, [sp, #32]
    struct List *item = NULL;
ffff000000080300:	f9000fff 	str	xzr, [sp, #24]

    while (current != NULL) {
ffff000000080304:	14000020 	b	ffff000000080384 <remove_list+0xa4>
        if (((struct Process*)current)->wait == wait) {
ffff000000080308:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008030c:	b9401000 	ldr	w0, [x0, #16]
ffff000000080310:	b94007e1 	ldr	w1, [sp, #4]
ffff000000080314:	6b00003f 	cmp	w1, w0
ffff000000080318:	540002c1 	b.ne	ffff000000080370 <remove_list+0x90>  // b.any
            prev->next = current->next;
ffff00000008031c:	f94017e0 	ldr	x0, [sp, #40]
ffff000000080320:	f9400001 	ldr	x1, [x0]
ffff000000080324:	f94013e0 	ldr	x0, [sp, #32]
ffff000000080328:	f9000001 	str	x1, [x0]
            item = current;
ffff00000008032c:	f94017e0 	ldr	x0, [sp, #40]
ffff000000080330:	f9000fe0 	str	x0, [sp, #24]

            if (list->next == NULL) {
ffff000000080334:	f94007e0 	ldr	x0, [sp, #8]
ffff000000080338:	f9400000 	ldr	x0, [x0]
ffff00000008033c:	f100001f 	cmp	x0, #0x0
ffff000000080340:	54000081 	b.ne	ffff000000080350 <remove_list+0x70>  // b.any
                list->tail = NULL;
ffff000000080344:	f94007e0 	ldr	x0, [sp, #8]
ffff000000080348:	f900041f 	str	xzr, [x0, #8]
            }
            else if (current->next == NULL) {
                list->tail = prev;
            }

            break;
ffff00000008034c:	14000012 	b	ffff000000080394 <remove_list+0xb4>
            else if (current->next == NULL) {
ffff000000080350:	f94017e0 	ldr	x0, [sp, #40]
ffff000000080354:	f9400000 	ldr	x0, [x0]
ffff000000080358:	f100001f 	cmp	x0, #0x0
ffff00000008035c:	540001c1 	b.ne	ffff000000080394 <remove_list+0xb4>  // b.any
                list->tail = prev;
ffff000000080360:	f94007e0 	ldr	x0, [sp, #8]
ffff000000080364:	f94013e1 	ldr	x1, [sp, #32]
ffff000000080368:	f9000401 	str	x1, [x0, #8]
            break;
ffff00000008036c:	1400000a 	b	ffff000000080394 <remove_list+0xb4>
        }

        prev = current;
ffff000000080370:	f94017e0 	ldr	x0, [sp, #40]
ffff000000080374:	f90013e0 	str	x0, [sp, #32]
        current = current->next;    
ffff000000080378:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008037c:	f9400000 	ldr	x0, [x0]
ffff000000080380:	f90017e0 	str	x0, [sp, #40]
    while (current != NULL) {
ffff000000080384:	f94017e0 	ldr	x0, [sp, #40]
ffff000000080388:	f100001f 	cmp	x0, #0x0
ffff00000008038c:	54fffbe1 	b.ne	ffff000000080308 <remove_list+0x28>  // b.any
ffff000000080390:	14000002 	b	ffff000000080398 <remove_list+0xb8>
            break;
ffff000000080394:	d503201f 	nop
    }

    return item;
ffff000000080398:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008039c:	9100c3ff 	add	sp, sp, #0x30
ffff0000000803a0:	d65f03c0 	ret

ffff0000000803a4 <write_char>:
#include "uart.h"
#include "lib.h"

void write_char(unsigned char c)
{
ffff0000000803a4:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff0000000803a8:	910003fd 	mov	x29, sp
ffff0000000803ac:	39007fe0 	strb	w0, [sp, #31]
    while (in_word(UART0_FR) & (1 << 3)) { }
ffff0000000803b0:	d503201f 	nop
ffff0000000803b4:	d2820300 	mov	x0, #0x1018                	// #4120
ffff0000000803b8:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff0000000803bc:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff0000000803c0:	97ffff63 	bl	ffff00000008014c <in_word>
ffff0000000803c4:	121d0000 	and	w0, w0, #0x8
ffff0000000803c8:	7100001f 	cmp	w0, #0x0
ffff0000000803cc:	54ffff41 	b.ne	ffff0000000803b4 <write_char+0x10>  // b.any
    out_word(UART0_DR, c);
ffff0000000803d0:	39407fe0 	ldrb	w0, [sp, #31]
ffff0000000803d4:	2a0003e1 	mov	w1, w0
ffff0000000803d8:	d2820000 	mov	x0, #0x1000                	// #4096
ffff0000000803dc:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff0000000803e0:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff0000000803e4:	97ffff58 	bl	ffff000000080144 <out_word>
}
ffff0000000803e8:	d503201f 	nop
ffff0000000803ec:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff0000000803f0:	d65f03c0 	ret

ffff0000000803f4 <read_char>:

unsigned char read_char(void)
{
ffff0000000803f4:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffff0000000803f8:	910003fd 	mov	x29, sp
    return in_word(UART0_DR);
ffff0000000803fc:	d2820000 	mov	x0, #0x1000                	// #4096
ffff000000080400:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff000000080404:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000080408:	97ffff51 	bl	ffff00000008014c <in_word>
ffff00000008040c:	12001c00 	and	w0, w0, #0xff
}
ffff000000080410:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffff000000080414:	d65f03c0 	ret

ffff000000080418 <write_string>:

void write_string(const char *string)
{
ffff000000080418:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008041c:	910003fd 	mov	x29, sp
ffff000000080420:	f9000fe0 	str	x0, [sp, #24]
    for (int i = 0; string[i] != '\0'; i++) {
ffff000000080424:	b9002fff 	str	wzr, [sp, #44]
ffff000000080428:	14000009 	b	ffff00000008044c <write_string+0x34>
        write_char(string[i]);
ffff00000008042c:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff000000080430:	f9400fe1 	ldr	x1, [sp, #24]
ffff000000080434:	8b000020 	add	x0, x1, x0
ffff000000080438:	39400000 	ldrb	w0, [x0]
ffff00000008043c:	97ffffda 	bl	ffff0000000803a4 <write_char>
    for (int i = 0; string[i] != '\0'; i++) {
ffff000000080440:	b9402fe0 	ldr	w0, [sp, #44]
ffff000000080444:	11000400 	add	w0, w0, #0x1
ffff000000080448:	b9002fe0 	str	w0, [sp, #44]
ffff00000008044c:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff000000080450:	f9400fe1 	ldr	x1, [sp, #24]
ffff000000080454:	8b000020 	add	x0, x1, x0
ffff000000080458:	39400000 	ldrb	w0, [x0]
ffff00000008045c:	7100001f 	cmp	w0, #0x0
ffff000000080460:	54fffe61 	b.ne	ffff00000008042c <write_string+0x14>  // b.any
    }
}
ffff000000080464:	d503201f 	nop
ffff000000080468:	d503201f 	nop
ffff00000008046c:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff000000080470:	d65f03c0 	ret

ffff000000080474 <uart_handler>:

void uart_handler(void)
{
ffff000000080474:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff000000080478:	910003fd 	mov	x29, sp
    uint32_t status = in_word(UART0_MIS);
ffff00000008047c:	d2820800 	mov	x0, #0x1040                	// #4160
ffff000000080480:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff000000080484:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000080488:	97ffff31 	bl	ffff00000008014c <in_word>
ffff00000008048c:	b9001fe0 	str	w0, [sp, #28]

    if (status & (1 << 4)) {
ffff000000080490:	b9401fe0 	ldr	w0, [sp, #28]
ffff000000080494:	121c0000 	and	w0, w0, #0x10
ffff000000080498:	7100001f 	cmp	w0, #0x0
ffff00000008049c:	54000220 	b.eq	ffff0000000804e0 <uart_handler+0x6c>  // b.none
        char ch = read_char();
ffff0000000804a0:	97ffffd5 	bl	ffff0000000803f4 <read_char>
ffff0000000804a4:	39006fe0 	strb	w0, [sp, #27]

        if (ch == '\r') {
ffff0000000804a8:	39406fe0 	ldrb	w0, [sp, #27]
ffff0000000804ac:	7100341f 	cmp	w0, #0xd
ffff0000000804b0:	540000a1 	b.ne	ffff0000000804c4 <uart_handler+0x50>  // b.any
            write_string("\r\n");
ffff0000000804b4:	90000060 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff0000000804b8:	9101e000 	add	x0, x0, #0x78
ffff0000000804bc:	97ffffd7 	bl	ffff000000080418 <write_string>
ffff0000000804c0:	14000003 	b	ffff0000000804cc <uart_handler+0x58>
        }
        else {
            write_char(ch);
ffff0000000804c4:	39406fe0 	ldrb	w0, [sp, #27]
ffff0000000804c8:	97ffffb7 	bl	ffff0000000803a4 <write_char>
        }
        
        out_word(UART0_ICR, (1 << 4));
ffff0000000804cc:	52800201 	mov	w1, #0x10                  	// #16
ffff0000000804d0:	d2820880 	mov	x0, #0x1044                	// #4164
ffff0000000804d4:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff0000000804d8:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff0000000804dc:	97ffff1a 	bl	ffff000000080144 <out_word>
    }
}
ffff0000000804e0:	d503201f 	nop
ffff0000000804e4:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff0000000804e8:	d65f03c0 	ret

ffff0000000804ec <init_uart>:


void init_uart(void)
{
ffff0000000804ec:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffff0000000804f0:	910003fd 	mov	x29, sp
    out_word(UART0_CR, 0);
ffff0000000804f4:	52800001 	mov	w1, #0x0                   	// #0
ffff0000000804f8:	d2820600 	mov	x0, #0x1030                	// #4144
ffff0000000804fc:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff000000080500:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000080504:	97ffff10 	bl	ffff000000080144 <out_word>
    out_word(UART0_IBRD, 26);
ffff000000080508:	52800341 	mov	w1, #0x1a                  	// #26
ffff00000008050c:	d2820480 	mov	x0, #0x1024                	// #4132
ffff000000080510:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff000000080514:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000080518:	97ffff0b 	bl	ffff000000080144 <out_word>
    out_word(UART0_FBRD, 0);
ffff00000008051c:	52800001 	mov	w1, #0x0                   	// #0
ffff000000080520:	d2820500 	mov	x0, #0x1028                	// #4136
ffff000000080524:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff000000080528:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff00000008052c:	97ffff06 	bl	ffff000000080144 <out_word>
    out_word(UART0_LCRH, (1 << 5) | (1 << 6));
ffff000000080530:	52800c01 	mov	w1, #0x60                  	// #96
ffff000000080534:	d2820580 	mov	x0, #0x102c                	// #4140
ffff000000080538:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff00000008053c:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000080540:	97ffff01 	bl	ffff000000080144 <out_word>
    out_word(UART0_IMSC, (1 << 4));
ffff000000080544:	52800201 	mov	w1, #0x10                  	// #16
ffff000000080548:	d2820700 	mov	x0, #0x1038                	// #4152
ffff00000008054c:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff000000080550:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000080554:	97fffefc 	bl	ffff000000080144 <out_word>
    out_word(UART0_CR, (1 << 0) | (1 << 8) | (1 << 9));
ffff000000080558:	52806021 	mov	w1, #0x301                 	// #769
ffff00000008055c:	d2820600 	mov	x0, #0x1030                	// #4144
ffff000000080560:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff000000080564:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000080568:	97fffef7 	bl	ffff000000080144 <out_word>
}
ffff00000008056c:	d503201f 	nop
ffff000000080570:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffff000000080574:	d65f03c0 	ret

ffff000000080578 <read_string>:
#include "stdint.h"
#include "stdarg.h"
#include "uart.h"

static int read_string(char *buffer, int position, const char *string)
{
ffff000000080578:	d100c3ff 	sub	sp, sp, #0x30
ffff00000008057c:	f9000fe0 	str	x0, [sp, #24]
ffff000000080580:	b90017e1 	str	w1, [sp, #20]
ffff000000080584:	f90007e2 	str	x2, [sp, #8]
    int index = 0;
ffff000000080588:	b9002fff 	str	wzr, [sp, #44]

    for (index = 0; string[index] != '\0'; index++) {
ffff00000008058c:	b9002fff 	str	wzr, [sp, #44]
ffff000000080590:	1400000f 	b	ffff0000000805cc <read_string+0x54>
        buffer[position++] = string[index];
ffff000000080594:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff000000080598:	f94007e1 	ldr	x1, [sp, #8]
ffff00000008059c:	8b000021 	add	x1, x1, x0
ffff0000000805a0:	b94017e0 	ldr	w0, [sp, #20]
ffff0000000805a4:	11000402 	add	w2, w0, #0x1
ffff0000000805a8:	b90017e2 	str	w2, [sp, #20]
ffff0000000805ac:	93407c00 	sxtw	x0, w0
ffff0000000805b0:	f9400fe2 	ldr	x2, [sp, #24]
ffff0000000805b4:	8b000040 	add	x0, x2, x0
ffff0000000805b8:	39400021 	ldrb	w1, [x1]
ffff0000000805bc:	39000001 	strb	w1, [x0]
    for (index = 0; string[index] != '\0'; index++) {
ffff0000000805c0:	b9402fe0 	ldr	w0, [sp, #44]
ffff0000000805c4:	11000400 	add	w0, w0, #0x1
ffff0000000805c8:	b9002fe0 	str	w0, [sp, #44]
ffff0000000805cc:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff0000000805d0:	f94007e1 	ldr	x1, [sp, #8]
ffff0000000805d4:	8b000020 	add	x0, x1, x0
ffff0000000805d8:	39400000 	ldrb	w0, [x0]
ffff0000000805dc:	7100001f 	cmp	w0, #0x0
ffff0000000805e0:	54fffda1 	b.ne	ffff000000080594 <read_string+0x1c>  // b.any
    }

    return index;
ffff0000000805e4:	b9402fe0 	ldr	w0, [sp, #44]
}
ffff0000000805e8:	9100c3ff 	add	sp, sp, #0x30
ffff0000000805ec:	d65f03c0 	ret

ffff0000000805f0 <hex_to_string>:

static int hex_to_string(char *buffer, int position, uint64_t digits)
{
ffff0000000805f0:	d10183ff 	sub	sp, sp, #0x60
ffff0000000805f4:	f9000fe0 	str	x0, [sp, #24]
ffff0000000805f8:	b90017e1 	str	w1, [sp, #20]
ffff0000000805fc:	f90007e2 	str	x2, [sp, #8]
    char digits_buffer[25];
    char digits_map[16] = "0123456789ABCDEF";
ffff000000080600:	90000060 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff000000080604:	91020000 	add	x0, x0, #0x80
ffff000000080608:	a9400400 	ldp	x0, x1, [x0]
ffff00000008060c:	a90287e0 	stp	x0, x1, [sp, #40]
    int size = 0;
ffff000000080610:	b9005fff 	str	wzr, [sp, #92]
    
    do {
        digits_buffer[size++] = digits_map[digits % 16];
ffff000000080614:	f94007e0 	ldr	x0, [sp, #8]
ffff000000080618:	92400c01 	and	x1, x0, #0xf
ffff00000008061c:	b9405fe0 	ldr	w0, [sp, #92]
ffff000000080620:	11000402 	add	w2, w0, #0x1
ffff000000080624:	b9005fe2 	str	w2, [sp, #92]
ffff000000080628:	9100a3e2 	add	x2, sp, #0x28
ffff00000008062c:	38616842 	ldrb	w2, [x2, x1]
ffff000000080630:	93407c00 	sxtw	x0, w0
ffff000000080634:	9100e3e1 	add	x1, sp, #0x38
ffff000000080638:	38206822 	strb	w2, [x1, x0]
        digits /= 16;
ffff00000008063c:	f94007e0 	ldr	x0, [sp, #8]
ffff000000080640:	d344fc00 	lsr	x0, x0, #4
ffff000000080644:	f90007e0 	str	x0, [sp, #8]
    } while (digits != 0);
ffff000000080648:	f94007e0 	ldr	x0, [sp, #8]
ffff00000008064c:	f100001f 	cmp	x0, #0x0
ffff000000080650:	54fffe21 	b.ne	ffff000000080614 <hex_to_string+0x24>  // b.any

    for (int i = size-1; i >= 0; i--) {
ffff000000080654:	b9405fe0 	ldr	w0, [sp, #92]
ffff000000080658:	51000400 	sub	w0, w0, #0x1
ffff00000008065c:	b9005be0 	str	w0, [sp, #88]
ffff000000080660:	1400000e 	b	ffff000000080698 <hex_to_string+0xa8>
        buffer[position++] = digits_buffer[i];
ffff000000080664:	b94017e0 	ldr	w0, [sp, #20]
ffff000000080668:	11000401 	add	w1, w0, #0x1
ffff00000008066c:	b90017e1 	str	w1, [sp, #20]
ffff000000080670:	93407c00 	sxtw	x0, w0
ffff000000080674:	f9400fe1 	ldr	x1, [sp, #24]
ffff000000080678:	8b000020 	add	x0, x1, x0
ffff00000008067c:	b9805be1 	ldrsw	x1, [sp, #88]
ffff000000080680:	9100e3e2 	add	x2, sp, #0x38
ffff000000080684:	38616841 	ldrb	w1, [x2, x1]
ffff000000080688:	39000001 	strb	w1, [x0]
    for (int i = size-1; i >= 0; i--) {
ffff00000008068c:	b9405be0 	ldr	w0, [sp, #88]
ffff000000080690:	51000400 	sub	w0, w0, #0x1
ffff000000080694:	b9005be0 	str	w0, [sp, #88]
ffff000000080698:	b9405be0 	ldr	w0, [sp, #88]
ffff00000008069c:	7100001f 	cmp	w0, #0x0
ffff0000000806a0:	54fffe2a 	b.ge	ffff000000080664 <hex_to_string+0x74>  // b.tcont
    }

    buffer[position++] = 'H';
ffff0000000806a4:	b94017e0 	ldr	w0, [sp, #20]
ffff0000000806a8:	11000401 	add	w1, w0, #0x1
ffff0000000806ac:	b90017e1 	str	w1, [sp, #20]
ffff0000000806b0:	93407c00 	sxtw	x0, w0
ffff0000000806b4:	f9400fe1 	ldr	x1, [sp, #24]
ffff0000000806b8:	8b000020 	add	x0, x1, x0
ffff0000000806bc:	52800901 	mov	w1, #0x48                  	// #72
ffff0000000806c0:	39000001 	strb	w1, [x0]

    return size + 1;
ffff0000000806c4:	b9405fe0 	ldr	w0, [sp, #92]
ffff0000000806c8:	11000400 	add	w0, w0, #0x1
}
ffff0000000806cc:	910183ff 	add	sp, sp, #0x60
ffff0000000806d0:	d65f03c0 	ret

ffff0000000806d4 <udecimal_to_string>:

static int udecimal_to_string(char *buffer, int position, uint64_t digits)
{
ffff0000000806d4:	d10183ff 	sub	sp, sp, #0x60
ffff0000000806d8:	f9000fe0 	str	x0, [sp, #24]
ffff0000000806dc:	b90017e1 	str	w1, [sp, #20]
ffff0000000806e0:	f90007e2 	str	x2, [sp, #8]
    char digits_map[10] = "0123456789";
ffff0000000806e4:	90000060 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff0000000806e8:	91024001 	add	x1, x0, #0x90
ffff0000000806ec:	910123e0 	add	x0, sp, #0x48
ffff0000000806f0:	f9400022 	ldr	x2, [x1]
ffff0000000806f4:	f9000002 	str	x2, [x0]
ffff0000000806f8:	79401021 	ldrh	w1, [x1, #8]
ffff0000000806fc:	79001001 	strh	w1, [x0, #8]
    char digits_buffer[25];
    int size = 0;
ffff000000080700:	b9005fff 	str	wzr, [sp, #92]

    do {
        digits_buffer[size++] = digits_map[digits % 10];
ffff000000080704:	f94007e2 	ldr	x2, [sp, #8]
ffff000000080708:	b202e7e0 	mov	x0, #0xcccccccccccccccc    	// #-3689348814741910324
ffff00000008070c:	f29999a0 	movk	x0, #0xcccd
ffff000000080710:	9bc07c40 	umulh	x0, x2, x0
ffff000000080714:	d343fc01 	lsr	x1, x0, #3
ffff000000080718:	aa0103e0 	mov	x0, x1
ffff00000008071c:	d37ef400 	lsl	x0, x0, #2
ffff000000080720:	8b010000 	add	x0, x0, x1
ffff000000080724:	d37ff800 	lsl	x0, x0, #1
ffff000000080728:	cb000041 	sub	x1, x2, x0
ffff00000008072c:	b9405fe0 	ldr	w0, [sp, #92]
ffff000000080730:	11000402 	add	w2, w0, #0x1
ffff000000080734:	b9005fe2 	str	w2, [sp, #92]
ffff000000080738:	910123e2 	add	x2, sp, #0x48
ffff00000008073c:	38616842 	ldrb	w2, [x2, x1]
ffff000000080740:	93407c00 	sxtw	x0, w0
ffff000000080744:	9100a3e1 	add	x1, sp, #0x28
ffff000000080748:	38206822 	strb	w2, [x1, x0]
        digits /= 10;
ffff00000008074c:	f94007e1 	ldr	x1, [sp, #8]
ffff000000080750:	b202e7e0 	mov	x0, #0xcccccccccccccccc    	// #-3689348814741910324
ffff000000080754:	f29999a0 	movk	x0, #0xcccd
ffff000000080758:	9bc07c20 	umulh	x0, x1, x0
ffff00000008075c:	d343fc00 	lsr	x0, x0, #3
ffff000000080760:	f90007e0 	str	x0, [sp, #8]
    } while (digits != 0);
ffff000000080764:	f94007e0 	ldr	x0, [sp, #8]
ffff000000080768:	f100001f 	cmp	x0, #0x0
ffff00000008076c:	54fffcc1 	b.ne	ffff000000080704 <udecimal_to_string+0x30>  // b.any

    for (int i = size-1; i >= 0; i--) {
ffff000000080770:	b9405fe0 	ldr	w0, [sp, #92]
ffff000000080774:	51000400 	sub	w0, w0, #0x1
ffff000000080778:	b9005be0 	str	w0, [sp, #88]
ffff00000008077c:	1400000e 	b	ffff0000000807b4 <udecimal_to_string+0xe0>
        buffer[position++] = digits_buffer[i];
ffff000000080780:	b94017e0 	ldr	w0, [sp, #20]
ffff000000080784:	11000401 	add	w1, w0, #0x1
ffff000000080788:	b90017e1 	str	w1, [sp, #20]
ffff00000008078c:	93407c00 	sxtw	x0, w0
ffff000000080790:	f9400fe1 	ldr	x1, [sp, #24]
ffff000000080794:	8b000020 	add	x0, x1, x0
ffff000000080798:	b9805be1 	ldrsw	x1, [sp, #88]
ffff00000008079c:	9100a3e2 	add	x2, sp, #0x28
ffff0000000807a0:	38616841 	ldrb	w1, [x2, x1]
ffff0000000807a4:	39000001 	strb	w1, [x0]
    for (int i = size-1; i >= 0; i--) {
ffff0000000807a8:	b9405be0 	ldr	w0, [sp, #88]
ffff0000000807ac:	51000400 	sub	w0, w0, #0x1
ffff0000000807b0:	b9005be0 	str	w0, [sp, #88]
ffff0000000807b4:	b9405be0 	ldr	w0, [sp, #88]
ffff0000000807b8:	7100001f 	cmp	w0, #0x0
ffff0000000807bc:	54fffe2a 	b.ge	ffff000000080780 <udecimal_to_string+0xac>  // b.tcont
    }

    return size;
ffff0000000807c0:	b9405fe0 	ldr	w0, [sp, #92]
}
ffff0000000807c4:	910183ff 	add	sp, sp, #0x60
ffff0000000807c8:	d65f03c0 	ret

ffff0000000807cc <decimal_to_string>:

static int decimal_to_string(char *buffer, int position, int64_t digits)
{
ffff0000000807cc:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff0000000807d0:	910003fd 	mov	x29, sp
ffff0000000807d4:	f90017e0 	str	x0, [sp, #40]
ffff0000000807d8:	b90027e1 	str	w1, [sp, #36]
ffff0000000807dc:	f9000fe2 	str	x2, [sp, #24]
    int size = 0;
ffff0000000807e0:	b9003fff 	str	wzr, [sp, #60]

    if (digits < 0) {
ffff0000000807e4:	f9400fe0 	ldr	x0, [sp, #24]
ffff0000000807e8:	f100001f 	cmp	x0, #0x0
ffff0000000807ec:	540001ca 	b.ge	ffff000000080824 <decimal_to_string+0x58>  // b.tcont
        digits = -digits;
ffff0000000807f0:	f9400fe0 	ldr	x0, [sp, #24]
ffff0000000807f4:	cb0003e0 	neg	x0, x0
ffff0000000807f8:	f9000fe0 	str	x0, [sp, #24]
        buffer[position++] = '-';
ffff0000000807fc:	b94027e0 	ldr	w0, [sp, #36]
ffff000000080800:	11000401 	add	w1, w0, #0x1
ffff000000080804:	b90027e1 	str	w1, [sp, #36]
ffff000000080808:	93407c00 	sxtw	x0, w0
ffff00000008080c:	f94017e1 	ldr	x1, [sp, #40]
ffff000000080810:	8b000020 	add	x0, x1, x0
ffff000000080814:	528005a1 	mov	w1, #0x2d                  	// #45
ffff000000080818:	39000001 	strb	w1, [x0]
        size = 1;
ffff00000008081c:	52800020 	mov	w0, #0x1                   	// #1
ffff000000080820:	b9003fe0 	str	w0, [sp, #60]
    }

    size += udecimal_to_string(buffer, position, (uint64_t)digits);
ffff000000080824:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000080828:	aa0003e2 	mov	x2, x0
ffff00000008082c:	b94027e1 	ldr	w1, [sp, #36]
ffff000000080830:	f94017e0 	ldr	x0, [sp, #40]
ffff000000080834:	97ffffa8 	bl	ffff0000000806d4 <udecimal_to_string>
ffff000000080838:	2a0003e1 	mov	w1, w0
ffff00000008083c:	b9403fe0 	ldr	w0, [sp, #60]
ffff000000080840:	0b010000 	add	w0, w0, w1
ffff000000080844:	b9003fe0 	str	w0, [sp, #60]
    return size;
ffff000000080848:	b9403fe0 	ldr	w0, [sp, #60]
}
ffff00000008084c:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff000000080850:	d65f03c0 	ret

ffff000000080854 <write_console>:

void write_console(const char *buffer, int size)
{
ffff000000080854:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff000000080858:	910003fd 	mov	x29, sp
ffff00000008085c:	f9000fe0 	str	x0, [sp, #24]
ffff000000080860:	b90017e1 	str	w1, [sp, #20]
    for (int i = 0; i < size; i++) {
ffff000000080864:	b9002fff 	str	wzr, [sp, #44]
ffff000000080868:	14000009 	b	ffff00000008088c <write_console+0x38>
        write_char(buffer[i]);
ffff00000008086c:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff000000080870:	f9400fe1 	ldr	x1, [sp, #24]
ffff000000080874:	8b000020 	add	x0, x1, x0
ffff000000080878:	39400000 	ldrb	w0, [x0]
ffff00000008087c:	97fffeca 	bl	ffff0000000803a4 <write_char>
    for (int i = 0; i < size; i++) {
ffff000000080880:	b9402fe0 	ldr	w0, [sp, #44]
ffff000000080884:	11000400 	add	w0, w0, #0x1
ffff000000080888:	b9002fe0 	str	w0, [sp, #44]
ffff00000008088c:	b9402fe1 	ldr	w1, [sp, #44]
ffff000000080890:	b94017e0 	ldr	w0, [sp, #20]
ffff000000080894:	6b00003f 	cmp	w1, w0
ffff000000080898:	54fffeab 	b.lt	ffff00000008086c <write_console+0x18>  // b.tstop
    }
}
ffff00000008089c:	d503201f 	nop
ffff0000000808a0:	d503201f 	nop
ffff0000000808a4:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff0000000808a8:	d65f03c0 	ret

ffff0000000808ac <printk>:

int printk(const char *format, ...)
{
ffff0000000808ac:	d11283ff 	sub	sp, sp, #0x4a0
ffff0000000808b0:	a9007bfd 	stp	x29, x30, [sp]
ffff0000000808b4:	910003fd 	mov	x29, sp
ffff0000000808b8:	f9000fe0 	str	x0, [sp, #24]
ffff0000000808bc:	f90237e1 	str	x1, [sp, #1128]
ffff0000000808c0:	f9023be2 	str	x2, [sp, #1136]
ffff0000000808c4:	f9023fe3 	str	x3, [sp, #1144]
ffff0000000808c8:	f90243e4 	str	x4, [sp, #1152]
ffff0000000808cc:	f90247e5 	str	x5, [sp, #1160]
ffff0000000808d0:	f9024be6 	str	x6, [sp, #1168]
ffff0000000808d4:	f9024fe7 	str	x7, [sp, #1176]
    char buffer[1024];
    int buffer_size = 0;
ffff0000000808d8:	b9045fff 	str	wzr, [sp, #1116]
    int64_t integer = 0;
ffff0000000808dc:	f9022bff 	str	xzr, [sp, #1104]
    char *string = 0;
ffff0000000808e0:	f90227ff 	str	xzr, [sp, #1096]
    va_list args;

    va_start(args, format);
ffff0000000808e4:	911283e0 	add	x0, sp, #0x4a0
ffff0000000808e8:	f90017e0 	str	x0, [sp, #40]
ffff0000000808ec:	911283e0 	add	x0, sp, #0x4a0
ffff0000000808f0:	f9001be0 	str	x0, [sp, #48]
ffff0000000808f4:	911183e0 	add	x0, sp, #0x460
ffff0000000808f8:	f9001fe0 	str	x0, [sp, #56]
ffff0000000808fc:	128006e0 	mov	w0, #0xffffffc8            	// #-56
ffff000000080900:	b90043e0 	str	w0, [sp, #64]
ffff000000080904:	b90047ff 	str	wzr, [sp, #68]

    for (int i = 0; format[i] != '\0'; i++) {
ffff000000080908:	b9045bff 	str	wzr, [sp, #1112]
ffff00000008090c:	140000b1 	b	ffff000000080bd0 <printk+0x324>
        if (format[i] != '%') {
ffff000000080910:	b9845be0 	ldrsw	x0, [sp, #1112]
ffff000000080914:	f9400fe1 	ldr	x1, [sp, #24]
ffff000000080918:	8b000020 	add	x0, x1, x0
ffff00000008091c:	39400000 	ldrb	w0, [x0]
ffff000000080920:	7100941f 	cmp	w0, #0x25
ffff000000080924:	54000180 	b.eq	ffff000000080954 <printk+0xa8>  // b.none
            buffer[buffer_size++] = format[i];
ffff000000080928:	b9845be0 	ldrsw	x0, [sp, #1112]
ffff00000008092c:	f9400fe1 	ldr	x1, [sp, #24]
ffff000000080930:	8b000021 	add	x1, x1, x0
ffff000000080934:	b9445fe0 	ldr	w0, [sp, #1116]
ffff000000080938:	11000402 	add	w2, w0, #0x1
ffff00000008093c:	b9045fe2 	str	w2, [sp, #1116]
ffff000000080940:	39400022 	ldrb	w2, [x1]
ffff000000080944:	93407c00 	sxtw	x0, w0
ffff000000080948:	910123e1 	add	x1, sp, #0x48
ffff00000008094c:	38206822 	strb	w2, [x1, x0]
ffff000000080950:	1400009d 	b	ffff000000080bc4 <printk+0x318>
        }
        else {
            switch (format[++i]) {
ffff000000080954:	b9445be0 	ldr	w0, [sp, #1112]
ffff000000080958:	11000400 	add	w0, w0, #0x1
ffff00000008095c:	b9045be0 	str	w0, [sp, #1112]
ffff000000080960:	b9845be0 	ldrsw	x0, [sp, #1112]
ffff000000080964:	f9400fe1 	ldr	x1, [sp, #24]
ffff000000080968:	8b000020 	add	x0, x1, x0
ffff00000008096c:	39400000 	ldrb	w0, [x0]
ffff000000080970:	7101e01f 	cmp	w0, #0x78
ffff000000080974:	54000180 	b.eq	ffff0000000809a4 <printk+0xf8>  // b.none
ffff000000080978:	7101e01f 	cmp	w0, #0x78
ffff00000008097c:	5400110c 	b.gt	ffff000000080b9c <printk+0x2f0>
ffff000000080980:	7101d41f 	cmp	w0, #0x75
ffff000000080984:	54000500 	b.eq	ffff000000080a24 <printk+0x178>  // b.none
ffff000000080988:	7101d41f 	cmp	w0, #0x75
ffff00000008098c:	5400108c 	b.gt	ffff000000080b9c <printk+0x2f0>
ffff000000080990:	7101901f 	cmp	w0, #0x64
ffff000000080994:	54000880 	b.eq	ffff000000080aa4 <printk+0x1f8>  // b.none
ffff000000080998:	7101cc1f 	cmp	w0, #0x73
ffff00000008099c:	54000c20 	b.eq	ffff000000080b20 <printk+0x274>  // b.none
ffff0000000809a0:	1400007f 	b	ffff000000080b9c <printk+0x2f0>
                case 'x':
                    integer = va_arg(args, int64_t);
ffff0000000809a4:	b94043e1 	ldr	w1, [sp, #64]
ffff0000000809a8:	f94017e0 	ldr	x0, [sp, #40]
ffff0000000809ac:	7100003f 	cmp	w1, #0x0
ffff0000000809b0:	540000ab 	b.lt	ffff0000000809c4 <printk+0x118>  // b.tstop
ffff0000000809b4:	91003c01 	add	x1, x0, #0xf
ffff0000000809b8:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff0000000809bc:	f90017e1 	str	x1, [sp, #40]
ffff0000000809c0:	1400000d 	b	ffff0000000809f4 <printk+0x148>
ffff0000000809c4:	11002022 	add	w2, w1, #0x8
ffff0000000809c8:	b90043e2 	str	w2, [sp, #64]
ffff0000000809cc:	b94043e2 	ldr	w2, [sp, #64]
ffff0000000809d0:	7100005f 	cmp	w2, #0x0
ffff0000000809d4:	540000ad 	b.le	ffff0000000809e8 <printk+0x13c>
ffff0000000809d8:	91003c01 	add	x1, x0, #0xf
ffff0000000809dc:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff0000000809e0:	f90017e1 	str	x1, [sp, #40]
ffff0000000809e4:	14000004 	b	ffff0000000809f4 <printk+0x148>
ffff0000000809e8:	f9401be2 	ldr	x2, [sp, #48]
ffff0000000809ec:	93407c20 	sxtw	x0, w1
ffff0000000809f0:	8b000040 	add	x0, x2, x0
ffff0000000809f4:	f9400000 	ldr	x0, [x0]
ffff0000000809f8:	f9022be0 	str	x0, [sp, #1104]
                    buffer_size += hex_to_string(buffer, buffer_size, (uint64_t)integer);
ffff0000000809fc:	f9422be1 	ldr	x1, [sp, #1104]
ffff000000080a00:	910123e0 	add	x0, sp, #0x48
ffff000000080a04:	aa0103e2 	mov	x2, x1
ffff000000080a08:	b9445fe1 	ldr	w1, [sp, #1116]
ffff000000080a0c:	97fffef9 	bl	ffff0000000805f0 <hex_to_string>
ffff000000080a10:	2a0003e1 	mov	w1, w0
ffff000000080a14:	b9445fe0 	ldr	w0, [sp, #1116]
ffff000000080a18:	0b010000 	add	w0, w0, w1
ffff000000080a1c:	b9045fe0 	str	w0, [sp, #1116]
                    break;
ffff000000080a20:	14000069 	b	ffff000000080bc4 <printk+0x318>

                case 'u':
                    integer = va_arg(args, int64_t);
ffff000000080a24:	b94043e1 	ldr	w1, [sp, #64]
ffff000000080a28:	f94017e0 	ldr	x0, [sp, #40]
ffff000000080a2c:	7100003f 	cmp	w1, #0x0
ffff000000080a30:	540000ab 	b.lt	ffff000000080a44 <printk+0x198>  // b.tstop
ffff000000080a34:	91003c01 	add	x1, x0, #0xf
ffff000000080a38:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff000000080a3c:	f90017e1 	str	x1, [sp, #40]
ffff000000080a40:	1400000d 	b	ffff000000080a74 <printk+0x1c8>
ffff000000080a44:	11002022 	add	w2, w1, #0x8
ffff000000080a48:	b90043e2 	str	w2, [sp, #64]
ffff000000080a4c:	b94043e2 	ldr	w2, [sp, #64]
ffff000000080a50:	7100005f 	cmp	w2, #0x0
ffff000000080a54:	540000ad 	b.le	ffff000000080a68 <printk+0x1bc>
ffff000000080a58:	91003c01 	add	x1, x0, #0xf
ffff000000080a5c:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff000000080a60:	f90017e1 	str	x1, [sp, #40]
ffff000000080a64:	14000004 	b	ffff000000080a74 <printk+0x1c8>
ffff000000080a68:	f9401be2 	ldr	x2, [sp, #48]
ffff000000080a6c:	93407c20 	sxtw	x0, w1
ffff000000080a70:	8b000040 	add	x0, x2, x0
ffff000000080a74:	f9400000 	ldr	x0, [x0]
ffff000000080a78:	f9022be0 	str	x0, [sp, #1104]
                    buffer_size += udecimal_to_string(buffer, buffer_size, (uint64_t)integer);
ffff000000080a7c:	f9422be1 	ldr	x1, [sp, #1104]
ffff000000080a80:	910123e0 	add	x0, sp, #0x48
ffff000000080a84:	aa0103e2 	mov	x2, x1
ffff000000080a88:	b9445fe1 	ldr	w1, [sp, #1116]
ffff000000080a8c:	97ffff12 	bl	ffff0000000806d4 <udecimal_to_string>
ffff000000080a90:	2a0003e1 	mov	w1, w0
ffff000000080a94:	b9445fe0 	ldr	w0, [sp, #1116]
ffff000000080a98:	0b010000 	add	w0, w0, w1
ffff000000080a9c:	b9045fe0 	str	w0, [sp, #1116]
                    break;
ffff000000080aa0:	14000049 	b	ffff000000080bc4 <printk+0x318>

                case 'd':
                    integer = va_arg(args, int64_t);
ffff000000080aa4:	b94043e1 	ldr	w1, [sp, #64]
ffff000000080aa8:	f94017e0 	ldr	x0, [sp, #40]
ffff000000080aac:	7100003f 	cmp	w1, #0x0
ffff000000080ab0:	540000ab 	b.lt	ffff000000080ac4 <printk+0x218>  // b.tstop
ffff000000080ab4:	91003c01 	add	x1, x0, #0xf
ffff000000080ab8:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff000000080abc:	f90017e1 	str	x1, [sp, #40]
ffff000000080ac0:	1400000d 	b	ffff000000080af4 <printk+0x248>
ffff000000080ac4:	11002022 	add	w2, w1, #0x8
ffff000000080ac8:	b90043e2 	str	w2, [sp, #64]
ffff000000080acc:	b94043e2 	ldr	w2, [sp, #64]
ffff000000080ad0:	7100005f 	cmp	w2, #0x0
ffff000000080ad4:	540000ad 	b.le	ffff000000080ae8 <printk+0x23c>
ffff000000080ad8:	91003c01 	add	x1, x0, #0xf
ffff000000080adc:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff000000080ae0:	f90017e1 	str	x1, [sp, #40]
ffff000000080ae4:	14000004 	b	ffff000000080af4 <printk+0x248>
ffff000000080ae8:	f9401be2 	ldr	x2, [sp, #48]
ffff000000080aec:	93407c20 	sxtw	x0, w1
ffff000000080af0:	8b000040 	add	x0, x2, x0
ffff000000080af4:	f9400000 	ldr	x0, [x0]
ffff000000080af8:	f9022be0 	str	x0, [sp, #1104]
                    buffer_size += decimal_to_string(buffer, buffer_size, integer);
ffff000000080afc:	910123e0 	add	x0, sp, #0x48
ffff000000080b00:	f9422be2 	ldr	x2, [sp, #1104]
ffff000000080b04:	b9445fe1 	ldr	w1, [sp, #1116]
ffff000000080b08:	97ffff31 	bl	ffff0000000807cc <decimal_to_string>
ffff000000080b0c:	2a0003e1 	mov	w1, w0
ffff000000080b10:	b9445fe0 	ldr	w0, [sp, #1116]
ffff000000080b14:	0b010000 	add	w0, w0, w1
ffff000000080b18:	b9045fe0 	str	w0, [sp, #1116]
                    break;
ffff000000080b1c:	1400002a 	b	ffff000000080bc4 <printk+0x318>

                case 's':
                    string = va_arg(args, char*);
ffff000000080b20:	b94043e1 	ldr	w1, [sp, #64]
ffff000000080b24:	f94017e0 	ldr	x0, [sp, #40]
ffff000000080b28:	7100003f 	cmp	w1, #0x0
ffff000000080b2c:	540000ab 	b.lt	ffff000000080b40 <printk+0x294>  // b.tstop
ffff000000080b30:	91003c01 	add	x1, x0, #0xf
ffff000000080b34:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff000000080b38:	f90017e1 	str	x1, [sp, #40]
ffff000000080b3c:	1400000d 	b	ffff000000080b70 <printk+0x2c4>
ffff000000080b40:	11002022 	add	w2, w1, #0x8
ffff000000080b44:	b90043e2 	str	w2, [sp, #64]
ffff000000080b48:	b94043e2 	ldr	w2, [sp, #64]
ffff000000080b4c:	7100005f 	cmp	w2, #0x0
ffff000000080b50:	540000ad 	b.le	ffff000000080b64 <printk+0x2b8>
ffff000000080b54:	91003c01 	add	x1, x0, #0xf
ffff000000080b58:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff000000080b5c:	f90017e1 	str	x1, [sp, #40]
ffff000000080b60:	14000004 	b	ffff000000080b70 <printk+0x2c4>
ffff000000080b64:	f9401be2 	ldr	x2, [sp, #48]
ffff000000080b68:	93407c20 	sxtw	x0, w1
ffff000000080b6c:	8b000040 	add	x0, x2, x0
ffff000000080b70:	f9400000 	ldr	x0, [x0]
ffff000000080b74:	f90227e0 	str	x0, [sp, #1096]
                    buffer_size += read_string(buffer, buffer_size, string);
ffff000000080b78:	910123e0 	add	x0, sp, #0x48
ffff000000080b7c:	f94227e2 	ldr	x2, [sp, #1096]
ffff000000080b80:	b9445fe1 	ldr	w1, [sp, #1116]
ffff000000080b84:	97fffe7d 	bl	ffff000000080578 <read_string>
ffff000000080b88:	2a0003e1 	mov	w1, w0
ffff000000080b8c:	b9445fe0 	ldr	w0, [sp, #1116]
ffff000000080b90:	0b010000 	add	w0, w0, w1
ffff000000080b94:	b9045fe0 	str	w0, [sp, #1116]
                    break;
ffff000000080b98:	1400000b 	b	ffff000000080bc4 <printk+0x318>

                default:
                    buffer[buffer_size++] = '%';
ffff000000080b9c:	b9445fe0 	ldr	w0, [sp, #1116]
ffff000000080ba0:	11000401 	add	w1, w0, #0x1
ffff000000080ba4:	b9045fe1 	str	w1, [sp, #1116]
ffff000000080ba8:	93407c00 	sxtw	x0, w0
ffff000000080bac:	910123e1 	add	x1, sp, #0x48
ffff000000080bb0:	528004a2 	mov	w2, #0x25                  	// #37
ffff000000080bb4:	38206822 	strb	w2, [x1, x0]
                    i--;
ffff000000080bb8:	b9445be0 	ldr	w0, [sp, #1112]
ffff000000080bbc:	51000400 	sub	w0, w0, #0x1
ffff000000080bc0:	b9045be0 	str	w0, [sp, #1112]
    for (int i = 0; format[i] != '\0'; i++) {
ffff000000080bc4:	b9445be0 	ldr	w0, [sp, #1112]
ffff000000080bc8:	11000400 	add	w0, w0, #0x1
ffff000000080bcc:	b9045be0 	str	w0, [sp, #1112]
ffff000000080bd0:	b9845be0 	ldrsw	x0, [sp, #1112]
ffff000000080bd4:	f9400fe1 	ldr	x1, [sp, #24]
ffff000000080bd8:	8b000020 	add	x0, x1, x0
ffff000000080bdc:	39400000 	ldrb	w0, [x0]
ffff000000080be0:	7100001f 	cmp	w0, #0x0
ffff000000080be4:	54ffe961 	b.ne	ffff000000080910 <printk+0x64>  // b.any
            }
        }
    }

    write_console(buffer, buffer_size);
ffff000000080be8:	910123e0 	add	x0, sp, #0x48
ffff000000080bec:	b9445fe1 	ldr	w1, [sp, #1116]
ffff000000080bf0:	97ffff19 	bl	ffff000000080854 <write_console>
    va_end(args);

    return buffer_size;
ffff000000080bf4:	b9445fe0 	ldr	w0, [sp, #1116]
ffff000000080bf8:	a9407bfd 	ldp	x29, x30, [sp]
ffff000000080bfc:	911283ff 	add	sp, sp, #0x4a0
ffff000000080c00:	d65f03c0 	ret

ffff000000080c04 <error_check>:
#include "debug.h"
#include "print.h"

void error_check(char *file, uint64_t line)
{
ffff000000080c04:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff000000080c08:	910003fd 	mov	x29, sp
ffff000000080c0c:	f9000fe0 	str	x0, [sp, #24]
ffff000000080c10:	f9000be1 	str	x1, [sp, #16]
    printk("\r\n-----------------------------------\r\n");
ffff000000080c14:	90000060 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff000000080c18:	91028000 	add	x0, x0, #0xa0
ffff000000080c1c:	97ffff24 	bl	ffff0000000808ac <printk>
    printk("                    ERROR CHECK");
ffff000000080c20:	90000060 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff000000080c24:	91032000 	add	x0, x0, #0xc8
ffff000000080c28:	97ffff21 	bl	ffff0000000808ac <printk>
    printk("\r\n-----------------------------------\r\n");
ffff000000080c2c:	90000060 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff000000080c30:	91028000 	add	x0, x0, #0xa0
ffff000000080c34:	97ffff1e 	bl	ffff0000000808ac <printk>
    printk("Assertion Failed [%s: %u]\r\n", file, line);
ffff000000080c38:	f9400be2 	ldr	x2, [sp, #16]
ffff000000080c3c:	f9400fe1 	ldr	x1, [sp, #24]
ffff000000080c40:	90000060 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff000000080c44:	9103a000 	add	x0, x0, #0xe8
ffff000000080c48:	97ffff19 	bl	ffff0000000808ac <printk>

    while (1) { }
ffff000000080c4c:	14000000 	b	ffff000000080c4c <error_check+0x48>
	...

ffff000000081000 <vector_table>:
.global swap
.global sync_handler
.balign 0x800
vector_table:
current_el_sp0_sync:
    b error
ffff000000081000:	14000235 	b	ffff0000000818d4 <error>
ffff000000081004:	d503201f 	nop
ffff000000081008:	d503201f 	nop
ffff00000008100c:	d503201f 	nop
ffff000000081010:	d503201f 	nop
ffff000000081014:	d503201f 	nop
ffff000000081018:	d503201f 	nop
ffff00000008101c:	d503201f 	nop
ffff000000081020:	d503201f 	nop
ffff000000081024:	d503201f 	nop
ffff000000081028:	d503201f 	nop
ffff00000008102c:	d503201f 	nop
ffff000000081030:	d503201f 	nop
ffff000000081034:	d503201f 	nop
ffff000000081038:	d503201f 	nop
ffff00000008103c:	d503201f 	nop
ffff000000081040:	d503201f 	nop
ffff000000081044:	d503201f 	nop
ffff000000081048:	d503201f 	nop
ffff00000008104c:	d503201f 	nop
ffff000000081050:	d503201f 	nop
ffff000000081054:	d503201f 	nop
ffff000000081058:	d503201f 	nop
ffff00000008105c:	d503201f 	nop
ffff000000081060:	d503201f 	nop
ffff000000081064:	d503201f 	nop
ffff000000081068:	d503201f 	nop
ffff00000008106c:	d503201f 	nop
ffff000000081070:	d503201f 	nop
ffff000000081074:	d503201f 	nop
ffff000000081078:	d503201f 	nop
ffff00000008107c:	d503201f 	nop

ffff000000081080 <current_el_sp0_irq>:

.balign 0x80
current_el_sp0_irq:
    b error
ffff000000081080:	14000215 	b	ffff0000000818d4 <error>
ffff000000081084:	d503201f 	nop
ffff000000081088:	d503201f 	nop
ffff00000008108c:	d503201f 	nop
ffff000000081090:	d503201f 	nop
ffff000000081094:	d503201f 	nop
ffff000000081098:	d503201f 	nop
ffff00000008109c:	d503201f 	nop
ffff0000000810a0:	d503201f 	nop
ffff0000000810a4:	d503201f 	nop
ffff0000000810a8:	d503201f 	nop
ffff0000000810ac:	d503201f 	nop
ffff0000000810b0:	d503201f 	nop
ffff0000000810b4:	d503201f 	nop
ffff0000000810b8:	d503201f 	nop
ffff0000000810bc:	d503201f 	nop
ffff0000000810c0:	d503201f 	nop
ffff0000000810c4:	d503201f 	nop
ffff0000000810c8:	d503201f 	nop
ffff0000000810cc:	d503201f 	nop
ffff0000000810d0:	d503201f 	nop
ffff0000000810d4:	d503201f 	nop
ffff0000000810d8:	d503201f 	nop
ffff0000000810dc:	d503201f 	nop
ffff0000000810e0:	d503201f 	nop
ffff0000000810e4:	d503201f 	nop
ffff0000000810e8:	d503201f 	nop
ffff0000000810ec:	d503201f 	nop
ffff0000000810f0:	d503201f 	nop
ffff0000000810f4:	d503201f 	nop
ffff0000000810f8:	d503201f 	nop
ffff0000000810fc:	d503201f 	nop

ffff000000081100 <current_el_sp0_fiq>:

.balign 0x80
current_el_sp0_fiq:
    b error
ffff000000081100:	140001f5 	b	ffff0000000818d4 <error>
ffff000000081104:	d503201f 	nop
ffff000000081108:	d503201f 	nop
ffff00000008110c:	d503201f 	nop
ffff000000081110:	d503201f 	nop
ffff000000081114:	d503201f 	nop
ffff000000081118:	d503201f 	nop
ffff00000008111c:	d503201f 	nop
ffff000000081120:	d503201f 	nop
ffff000000081124:	d503201f 	nop
ffff000000081128:	d503201f 	nop
ffff00000008112c:	d503201f 	nop
ffff000000081130:	d503201f 	nop
ffff000000081134:	d503201f 	nop
ffff000000081138:	d503201f 	nop
ffff00000008113c:	d503201f 	nop
ffff000000081140:	d503201f 	nop
ffff000000081144:	d503201f 	nop
ffff000000081148:	d503201f 	nop
ffff00000008114c:	d503201f 	nop
ffff000000081150:	d503201f 	nop
ffff000000081154:	d503201f 	nop
ffff000000081158:	d503201f 	nop
ffff00000008115c:	d503201f 	nop
ffff000000081160:	d503201f 	nop
ffff000000081164:	d503201f 	nop
ffff000000081168:	d503201f 	nop
ffff00000008116c:	d503201f 	nop
ffff000000081170:	d503201f 	nop
ffff000000081174:	d503201f 	nop
ffff000000081178:	d503201f 	nop
ffff00000008117c:	d503201f 	nop

ffff000000081180 <current_el_sp0_serror>:

.balign 0x80
current_el_sp0_serror:
    b error
ffff000000081180:	140001d5 	b	ffff0000000818d4 <error>
ffff000000081184:	d503201f 	nop
ffff000000081188:	d503201f 	nop
ffff00000008118c:	d503201f 	nop
ffff000000081190:	d503201f 	nop
ffff000000081194:	d503201f 	nop
ffff000000081198:	d503201f 	nop
ffff00000008119c:	d503201f 	nop
ffff0000000811a0:	d503201f 	nop
ffff0000000811a4:	d503201f 	nop
ffff0000000811a8:	d503201f 	nop
ffff0000000811ac:	d503201f 	nop
ffff0000000811b0:	d503201f 	nop
ffff0000000811b4:	d503201f 	nop
ffff0000000811b8:	d503201f 	nop
ffff0000000811bc:	d503201f 	nop
ffff0000000811c0:	d503201f 	nop
ffff0000000811c4:	d503201f 	nop
ffff0000000811c8:	d503201f 	nop
ffff0000000811cc:	d503201f 	nop
ffff0000000811d0:	d503201f 	nop
ffff0000000811d4:	d503201f 	nop
ffff0000000811d8:	d503201f 	nop
ffff0000000811dc:	d503201f 	nop
ffff0000000811e0:	d503201f 	nop
ffff0000000811e4:	d503201f 	nop
ffff0000000811e8:	d503201f 	nop
ffff0000000811ec:	d503201f 	nop
ffff0000000811f0:	d503201f 	nop
ffff0000000811f4:	d503201f 	nop
ffff0000000811f8:	d503201f 	nop
ffff0000000811fc:	d503201f 	nop

ffff000000081200 <current_el_spn_sync>:

.balign 0x80
current_el_spn_sync:
    b sync_handler
ffff000000081200:	1400017a 	b	ffff0000000817e8 <sync_handler>
ffff000000081204:	d503201f 	nop
ffff000000081208:	d503201f 	nop
ffff00000008120c:	d503201f 	nop
ffff000000081210:	d503201f 	nop
ffff000000081214:	d503201f 	nop
ffff000000081218:	d503201f 	nop
ffff00000008121c:	d503201f 	nop
ffff000000081220:	d503201f 	nop
ffff000000081224:	d503201f 	nop
ffff000000081228:	d503201f 	nop
ffff00000008122c:	d503201f 	nop
ffff000000081230:	d503201f 	nop
ffff000000081234:	d503201f 	nop
ffff000000081238:	d503201f 	nop
ffff00000008123c:	d503201f 	nop
ffff000000081240:	d503201f 	nop
ffff000000081244:	d503201f 	nop
ffff000000081248:	d503201f 	nop
ffff00000008124c:	d503201f 	nop
ffff000000081250:	d503201f 	nop
ffff000000081254:	d503201f 	nop
ffff000000081258:	d503201f 	nop
ffff00000008125c:	d503201f 	nop
ffff000000081260:	d503201f 	nop
ffff000000081264:	d503201f 	nop
ffff000000081268:	d503201f 	nop
ffff00000008126c:	d503201f 	nop
ffff000000081270:	d503201f 	nop
ffff000000081274:	d503201f 	nop
ffff000000081278:	d503201f 	nop
ffff00000008127c:	d503201f 	nop

ffff000000081280 <current_el_spn_irq>:

.balign 0x80
current_el_spn_irq:
    b irq_handler
ffff000000081280:	1400017a 	b	ffff000000081868 <irq_handler>
ffff000000081284:	d503201f 	nop
ffff000000081288:	d503201f 	nop
ffff00000008128c:	d503201f 	nop
ffff000000081290:	d503201f 	nop
ffff000000081294:	d503201f 	nop
ffff000000081298:	d503201f 	nop
ffff00000008129c:	d503201f 	nop
ffff0000000812a0:	d503201f 	nop
ffff0000000812a4:	d503201f 	nop
ffff0000000812a8:	d503201f 	nop
ffff0000000812ac:	d503201f 	nop
ffff0000000812b0:	d503201f 	nop
ffff0000000812b4:	d503201f 	nop
ffff0000000812b8:	d503201f 	nop
ffff0000000812bc:	d503201f 	nop
ffff0000000812c0:	d503201f 	nop
ffff0000000812c4:	d503201f 	nop
ffff0000000812c8:	d503201f 	nop
ffff0000000812cc:	d503201f 	nop
ffff0000000812d0:	d503201f 	nop
ffff0000000812d4:	d503201f 	nop
ffff0000000812d8:	d503201f 	nop
ffff0000000812dc:	d503201f 	nop
ffff0000000812e0:	d503201f 	nop
ffff0000000812e4:	d503201f 	nop
ffff0000000812e8:	d503201f 	nop
ffff0000000812ec:	d503201f 	nop
ffff0000000812f0:	d503201f 	nop
ffff0000000812f4:	d503201f 	nop
ffff0000000812f8:	d503201f 	nop
ffff0000000812fc:	d503201f 	nop

ffff000000081300 <current_el_spn_fiq>:

.balign 0x80
current_el_spn_fiq:
    b error
ffff000000081300:	14000175 	b	ffff0000000818d4 <error>
ffff000000081304:	d503201f 	nop
ffff000000081308:	d503201f 	nop
ffff00000008130c:	d503201f 	nop
ffff000000081310:	d503201f 	nop
ffff000000081314:	d503201f 	nop
ffff000000081318:	d503201f 	nop
ffff00000008131c:	d503201f 	nop
ffff000000081320:	d503201f 	nop
ffff000000081324:	d503201f 	nop
ffff000000081328:	d503201f 	nop
ffff00000008132c:	d503201f 	nop
ffff000000081330:	d503201f 	nop
ffff000000081334:	d503201f 	nop
ffff000000081338:	d503201f 	nop
ffff00000008133c:	d503201f 	nop
ffff000000081340:	d503201f 	nop
ffff000000081344:	d503201f 	nop
ffff000000081348:	d503201f 	nop
ffff00000008134c:	d503201f 	nop
ffff000000081350:	d503201f 	nop
ffff000000081354:	d503201f 	nop
ffff000000081358:	d503201f 	nop
ffff00000008135c:	d503201f 	nop
ffff000000081360:	d503201f 	nop
ffff000000081364:	d503201f 	nop
ffff000000081368:	d503201f 	nop
ffff00000008136c:	d503201f 	nop
ffff000000081370:	d503201f 	nop
ffff000000081374:	d503201f 	nop
ffff000000081378:	d503201f 	nop
ffff00000008137c:	d503201f 	nop

ffff000000081380 <current_el_spn_serror>:

.balign 0x80
current_el_spn_serror:
    b error
ffff000000081380:	14000155 	b	ffff0000000818d4 <error>
ffff000000081384:	d503201f 	nop
ffff000000081388:	d503201f 	nop
ffff00000008138c:	d503201f 	nop
ffff000000081390:	d503201f 	nop
ffff000000081394:	d503201f 	nop
ffff000000081398:	d503201f 	nop
ffff00000008139c:	d503201f 	nop
ffff0000000813a0:	d503201f 	nop
ffff0000000813a4:	d503201f 	nop
ffff0000000813a8:	d503201f 	nop
ffff0000000813ac:	d503201f 	nop
ffff0000000813b0:	d503201f 	nop
ffff0000000813b4:	d503201f 	nop
ffff0000000813b8:	d503201f 	nop
ffff0000000813bc:	d503201f 	nop
ffff0000000813c0:	d503201f 	nop
ffff0000000813c4:	d503201f 	nop
ffff0000000813c8:	d503201f 	nop
ffff0000000813cc:	d503201f 	nop
ffff0000000813d0:	d503201f 	nop
ffff0000000813d4:	d503201f 	nop
ffff0000000813d8:	d503201f 	nop
ffff0000000813dc:	d503201f 	nop
ffff0000000813e0:	d503201f 	nop
ffff0000000813e4:	d503201f 	nop
ffff0000000813e8:	d503201f 	nop
ffff0000000813ec:	d503201f 	nop
ffff0000000813f0:	d503201f 	nop
ffff0000000813f4:	d503201f 	nop
ffff0000000813f8:	d503201f 	nop
ffff0000000813fc:	d503201f 	nop

ffff000000081400 <lower_el_aarch64_sync>:

.balign 0x80
lower_el_aarch64_sync:
    b sync_handler
ffff000000081400:	140000fa 	b	ffff0000000817e8 <sync_handler>
ffff000000081404:	d503201f 	nop
ffff000000081408:	d503201f 	nop
ffff00000008140c:	d503201f 	nop
ffff000000081410:	d503201f 	nop
ffff000000081414:	d503201f 	nop
ffff000000081418:	d503201f 	nop
ffff00000008141c:	d503201f 	nop
ffff000000081420:	d503201f 	nop
ffff000000081424:	d503201f 	nop
ffff000000081428:	d503201f 	nop
ffff00000008142c:	d503201f 	nop
ffff000000081430:	d503201f 	nop
ffff000000081434:	d503201f 	nop
ffff000000081438:	d503201f 	nop
ffff00000008143c:	d503201f 	nop
ffff000000081440:	d503201f 	nop
ffff000000081444:	d503201f 	nop
ffff000000081448:	d503201f 	nop
ffff00000008144c:	d503201f 	nop
ffff000000081450:	d503201f 	nop
ffff000000081454:	d503201f 	nop
ffff000000081458:	d503201f 	nop
ffff00000008145c:	d503201f 	nop
ffff000000081460:	d503201f 	nop
ffff000000081464:	d503201f 	nop
ffff000000081468:	d503201f 	nop
ffff00000008146c:	d503201f 	nop
ffff000000081470:	d503201f 	nop
ffff000000081474:	d503201f 	nop
ffff000000081478:	d503201f 	nop
ffff00000008147c:	d503201f 	nop

ffff000000081480 <lower_el_aarch64_irq>:

.balign 0x80
lower_el_aarch64_irq:
    b irq_handler
ffff000000081480:	140000fa 	b	ffff000000081868 <irq_handler>
ffff000000081484:	d503201f 	nop
ffff000000081488:	d503201f 	nop
ffff00000008148c:	d503201f 	nop
ffff000000081490:	d503201f 	nop
ffff000000081494:	d503201f 	nop
ffff000000081498:	d503201f 	nop
ffff00000008149c:	d503201f 	nop
ffff0000000814a0:	d503201f 	nop
ffff0000000814a4:	d503201f 	nop
ffff0000000814a8:	d503201f 	nop
ffff0000000814ac:	d503201f 	nop
ffff0000000814b0:	d503201f 	nop
ffff0000000814b4:	d503201f 	nop
ffff0000000814b8:	d503201f 	nop
ffff0000000814bc:	d503201f 	nop
ffff0000000814c0:	d503201f 	nop
ffff0000000814c4:	d503201f 	nop
ffff0000000814c8:	d503201f 	nop
ffff0000000814cc:	d503201f 	nop
ffff0000000814d0:	d503201f 	nop
ffff0000000814d4:	d503201f 	nop
ffff0000000814d8:	d503201f 	nop
ffff0000000814dc:	d503201f 	nop
ffff0000000814e0:	d503201f 	nop
ffff0000000814e4:	d503201f 	nop
ffff0000000814e8:	d503201f 	nop
ffff0000000814ec:	d503201f 	nop
ffff0000000814f0:	d503201f 	nop
ffff0000000814f4:	d503201f 	nop
ffff0000000814f8:	d503201f 	nop
ffff0000000814fc:	d503201f 	nop

ffff000000081500 <lower_el_aarch64_fiq>:

.balign 0x80
lower_el_aarch64_fiq:
    b error
ffff000000081500:	140000f5 	b	ffff0000000818d4 <error>
ffff000000081504:	d503201f 	nop
ffff000000081508:	d503201f 	nop
ffff00000008150c:	d503201f 	nop
ffff000000081510:	d503201f 	nop
ffff000000081514:	d503201f 	nop
ffff000000081518:	d503201f 	nop
ffff00000008151c:	d503201f 	nop
ffff000000081520:	d503201f 	nop
ffff000000081524:	d503201f 	nop
ffff000000081528:	d503201f 	nop
ffff00000008152c:	d503201f 	nop
ffff000000081530:	d503201f 	nop
ffff000000081534:	d503201f 	nop
ffff000000081538:	d503201f 	nop
ffff00000008153c:	d503201f 	nop
ffff000000081540:	d503201f 	nop
ffff000000081544:	d503201f 	nop
ffff000000081548:	d503201f 	nop
ffff00000008154c:	d503201f 	nop
ffff000000081550:	d503201f 	nop
ffff000000081554:	d503201f 	nop
ffff000000081558:	d503201f 	nop
ffff00000008155c:	d503201f 	nop
ffff000000081560:	d503201f 	nop
ffff000000081564:	d503201f 	nop
ffff000000081568:	d503201f 	nop
ffff00000008156c:	d503201f 	nop
ffff000000081570:	d503201f 	nop
ffff000000081574:	d503201f 	nop
ffff000000081578:	d503201f 	nop
ffff00000008157c:	d503201f 	nop

ffff000000081580 <lower_el_aarch64_serror>:

.balign 0x80
lower_el_aarch64_serror:
    b error
ffff000000081580:	140000d5 	b	ffff0000000818d4 <error>
ffff000000081584:	d503201f 	nop
ffff000000081588:	d503201f 	nop
ffff00000008158c:	d503201f 	nop
ffff000000081590:	d503201f 	nop
ffff000000081594:	d503201f 	nop
ffff000000081598:	d503201f 	nop
ffff00000008159c:	d503201f 	nop
ffff0000000815a0:	d503201f 	nop
ffff0000000815a4:	d503201f 	nop
ffff0000000815a8:	d503201f 	nop
ffff0000000815ac:	d503201f 	nop
ffff0000000815b0:	d503201f 	nop
ffff0000000815b4:	d503201f 	nop
ffff0000000815b8:	d503201f 	nop
ffff0000000815bc:	d503201f 	nop
ffff0000000815c0:	d503201f 	nop
ffff0000000815c4:	d503201f 	nop
ffff0000000815c8:	d503201f 	nop
ffff0000000815cc:	d503201f 	nop
ffff0000000815d0:	d503201f 	nop
ffff0000000815d4:	d503201f 	nop
ffff0000000815d8:	d503201f 	nop
ffff0000000815dc:	d503201f 	nop
ffff0000000815e0:	d503201f 	nop
ffff0000000815e4:	d503201f 	nop
ffff0000000815e8:	d503201f 	nop
ffff0000000815ec:	d503201f 	nop
ffff0000000815f0:	d503201f 	nop
ffff0000000815f4:	d503201f 	nop
ffff0000000815f8:	d503201f 	nop
ffff0000000815fc:	d503201f 	nop

ffff000000081600 <lower_el_aarch32_sync>:

.balign 0x80
lower_el_aarch32_sync:
    b error
ffff000000081600:	140000b5 	b	ffff0000000818d4 <error>
ffff000000081604:	d503201f 	nop
ffff000000081608:	d503201f 	nop
ffff00000008160c:	d503201f 	nop
ffff000000081610:	d503201f 	nop
ffff000000081614:	d503201f 	nop
ffff000000081618:	d503201f 	nop
ffff00000008161c:	d503201f 	nop
ffff000000081620:	d503201f 	nop
ffff000000081624:	d503201f 	nop
ffff000000081628:	d503201f 	nop
ffff00000008162c:	d503201f 	nop
ffff000000081630:	d503201f 	nop
ffff000000081634:	d503201f 	nop
ffff000000081638:	d503201f 	nop
ffff00000008163c:	d503201f 	nop
ffff000000081640:	d503201f 	nop
ffff000000081644:	d503201f 	nop
ffff000000081648:	d503201f 	nop
ffff00000008164c:	d503201f 	nop
ffff000000081650:	d503201f 	nop
ffff000000081654:	d503201f 	nop
ffff000000081658:	d503201f 	nop
ffff00000008165c:	d503201f 	nop
ffff000000081660:	d503201f 	nop
ffff000000081664:	d503201f 	nop
ffff000000081668:	d503201f 	nop
ffff00000008166c:	d503201f 	nop
ffff000000081670:	d503201f 	nop
ffff000000081674:	d503201f 	nop
ffff000000081678:	d503201f 	nop
ffff00000008167c:	d503201f 	nop

ffff000000081680 <lower_el_aarch32_irq>:

.balign 0x80
lower_el_aarch32_irq:
    b error
ffff000000081680:	14000095 	b	ffff0000000818d4 <error>
ffff000000081684:	d503201f 	nop
ffff000000081688:	d503201f 	nop
ffff00000008168c:	d503201f 	nop
ffff000000081690:	d503201f 	nop
ffff000000081694:	d503201f 	nop
ffff000000081698:	d503201f 	nop
ffff00000008169c:	d503201f 	nop
ffff0000000816a0:	d503201f 	nop
ffff0000000816a4:	d503201f 	nop
ffff0000000816a8:	d503201f 	nop
ffff0000000816ac:	d503201f 	nop
ffff0000000816b0:	d503201f 	nop
ffff0000000816b4:	d503201f 	nop
ffff0000000816b8:	d503201f 	nop
ffff0000000816bc:	d503201f 	nop
ffff0000000816c0:	d503201f 	nop
ffff0000000816c4:	d503201f 	nop
ffff0000000816c8:	d503201f 	nop
ffff0000000816cc:	d503201f 	nop
ffff0000000816d0:	d503201f 	nop
ffff0000000816d4:	d503201f 	nop
ffff0000000816d8:	d503201f 	nop
ffff0000000816dc:	d503201f 	nop
ffff0000000816e0:	d503201f 	nop
ffff0000000816e4:	d503201f 	nop
ffff0000000816e8:	d503201f 	nop
ffff0000000816ec:	d503201f 	nop
ffff0000000816f0:	d503201f 	nop
ffff0000000816f4:	d503201f 	nop
ffff0000000816f8:	d503201f 	nop
ffff0000000816fc:	d503201f 	nop

ffff000000081700 <lower_el_aarch32_fiq>:

.balign 0x80
lower_el_aarch32_fiq:
    b error
ffff000000081700:	14000075 	b	ffff0000000818d4 <error>
ffff000000081704:	d503201f 	nop
ffff000000081708:	d503201f 	nop
ffff00000008170c:	d503201f 	nop
ffff000000081710:	d503201f 	nop
ffff000000081714:	d503201f 	nop
ffff000000081718:	d503201f 	nop
ffff00000008171c:	d503201f 	nop
ffff000000081720:	d503201f 	nop
ffff000000081724:	d503201f 	nop
ffff000000081728:	d503201f 	nop
ffff00000008172c:	d503201f 	nop
ffff000000081730:	d503201f 	nop
ffff000000081734:	d503201f 	nop
ffff000000081738:	d503201f 	nop
ffff00000008173c:	d503201f 	nop
ffff000000081740:	d503201f 	nop
ffff000000081744:	d503201f 	nop
ffff000000081748:	d503201f 	nop
ffff00000008174c:	d503201f 	nop
ffff000000081750:	d503201f 	nop
ffff000000081754:	d503201f 	nop
ffff000000081758:	d503201f 	nop
ffff00000008175c:	d503201f 	nop
ffff000000081760:	d503201f 	nop
ffff000000081764:	d503201f 	nop
ffff000000081768:	d503201f 	nop
ffff00000008176c:	d503201f 	nop
ffff000000081770:	d503201f 	nop
ffff000000081774:	d503201f 	nop
ffff000000081778:	d503201f 	nop
ffff00000008177c:	d503201f 	nop

ffff000000081780 <lower_el_aarch32_serror>:

.balign 0x80
lower_el_aarch32_serror:
    b error
ffff000000081780:	14000055 	b	ffff0000000818d4 <error>

ffff000000081784 <pstart>:

pstart:
    mov sp, x0
ffff000000081784:	9100001f 	mov	sp, x0

ffff000000081788 <trap_return>:


trap_return:
    ldp x0, x1, [sp, #(16 * 17)]
ffff000000081788:	a95107e0 	ldp	x0, x1, [sp, #272]
    msr elr_el1, x0
ffff00000008178c:	d5184020 	msr	elr_el1, x0
    msr spsr_el1, x1
ffff000000081790:	d5184001 	msr	spsr_el1, x1
    kernel_exit
ffff000000081794:	a94f03fe 	ldp	x30, x0, [sp, #240]
ffff000000081798:	d5184100 	msr	sp_el0, x0
ffff00000008179c:	a94007e0 	ldp	x0, x1, [sp]
ffff0000000817a0:	a9410fe2 	ldp	x2, x3, [sp, #16]
ffff0000000817a4:	a94217e4 	ldp	x4, x5, [sp, #32]
ffff0000000817a8:	a9431fe6 	ldp	x6, x7, [sp, #48]
ffff0000000817ac:	a94427e8 	ldp	x8, x9, [sp, #64]
ffff0000000817b0:	a9452fea 	ldp	x10, x11, [sp, #80]
ffff0000000817b4:	a94637ec 	ldp	x12, x13, [sp, #96]
ffff0000000817b8:	a9473fee 	ldp	x14, x15, [sp, #112]
ffff0000000817bc:	a94847f0 	ldp	x16, x17, [sp, #128]
ffff0000000817c0:	a9494ff2 	ldp	x18, x19, [sp, #144]
ffff0000000817c4:	a94a57f4 	ldp	x20, x21, [sp, #160]
ffff0000000817c8:	a94b5ff6 	ldp	x22, x23, [sp, #176]
ffff0000000817cc:	a94c67f8 	ldp	x24, x25, [sp, #192]
ffff0000000817d0:	a94d6ffa 	ldp	x26, x27, [sp, #208]
ffff0000000817d4:	a94e77fc 	ldp	x28, x29, [sp, #224]
ffff0000000817d8:	910483ff 	add	sp, sp, #0x120
ffff0000000817dc:	d69f03e0 	eret

ffff0000000817e0 <enter_user>:
.global enter_user
enter_user:
    // x0 = tf
    // 直接跳到 trap_return（不用 bl）
     mov sp, x0
ffff0000000817e0:	9100001f 	mov	sp, x0
    b  trap_return    
ffff0000000817e4:	17ffffe9 	b	ffff000000081788 <trap_return>

ffff0000000817e8 <sync_handler>:
sync_handler:
    kernel_entry
ffff0000000817e8:	d10483ff 	sub	sp, sp, #0x120
ffff0000000817ec:	a90007e0 	stp	x0, x1, [sp]
ffff0000000817f0:	a9010fe2 	stp	x2, x3, [sp, #16]
ffff0000000817f4:	a90217e4 	stp	x4, x5, [sp, #32]
ffff0000000817f8:	a9031fe6 	stp	x6, x7, [sp, #48]
ffff0000000817fc:	a90427e8 	stp	x8, x9, [sp, #64]
ffff000000081800:	a9052fea 	stp	x10, x11, [sp, #80]
ffff000000081804:	a90637ec 	stp	x12, x13, [sp, #96]
ffff000000081808:	a9073fee 	stp	x14, x15, [sp, #112]
ffff00000008180c:	a90847f0 	stp	x16, x17, [sp, #128]
ffff000000081810:	a9094ff2 	stp	x18, x19, [sp, #144]
ffff000000081814:	a90a57f4 	stp	x20, x21, [sp, #160]
ffff000000081818:	a90b5ff6 	stp	x22, x23, [sp, #176]
ffff00000008181c:	a90c67f8 	stp	x24, x25, [sp, #192]
ffff000000081820:	a90d6ffa 	stp	x26, x27, [sp, #208]
ffff000000081824:	a90e77fc 	stp	x28, x29, [sp, #224]
ffff000000081828:	d5384100 	mrs	x0, sp_el0
ffff00000008182c:	a90f03fe 	stp	x30, x0, [sp, #240]
    mrs x0, esr_el1
ffff000000081830:	d5385200 	mrs	x0, esr_el1
    lsr x1, x0, #26
ffff000000081834:	d35afc01 	lsr	x1, x0, #26
    cmp x1, #0b010101
ffff000000081838:	f100543f 	cmp	x1, #0x15
    mov x2, #1
ffff00000008183c:	d2800022 	mov	x2, #0x1                   	// #1
    mov x3, #3
ffff000000081840:	d2800063 	mov	x3, #0x3                   	// #3
    csel x0, x2, x3, ne
ffff000000081844:	9a831040 	csel	x0, x2, x3, ne  // ne = any
    handler_entry
ffff000000081848:	d5385201 	mrs	x1, esr_el1
ffff00000008184c:	a91007e0 	stp	x0, x1, [sp, #256]
ffff000000081850:	d5384020 	mrs	x0, elr_el1
ffff000000081854:	d5384001 	mrs	x1, spsr_el1
ffff000000081858:	a91107e0 	stp	x0, x1, [sp, #272]
ffff00000008185c:	910003e0 	mov	x0, sp
ffff000000081860:	94000106 	bl	ffff000000081c78 <handler>
ffff000000081864:	17ffffc9 	b	ffff000000081788 <trap_return>

ffff000000081868 <irq_handler>:

irq_handler:
    kernel_entry
ffff000000081868:	d10483ff 	sub	sp, sp, #0x120
ffff00000008186c:	a90007e0 	stp	x0, x1, [sp]
ffff000000081870:	a9010fe2 	stp	x2, x3, [sp, #16]
ffff000000081874:	a90217e4 	stp	x4, x5, [sp, #32]
ffff000000081878:	a9031fe6 	stp	x6, x7, [sp, #48]
ffff00000008187c:	a90427e8 	stp	x8, x9, [sp, #64]
ffff000000081880:	a9052fea 	stp	x10, x11, [sp, #80]
ffff000000081884:	a90637ec 	stp	x12, x13, [sp, #96]
ffff000000081888:	a9073fee 	stp	x14, x15, [sp, #112]
ffff00000008188c:	a90847f0 	stp	x16, x17, [sp, #128]
ffff000000081890:	a9094ff2 	stp	x18, x19, [sp, #144]
ffff000000081894:	a90a57f4 	stp	x20, x21, [sp, #160]
ffff000000081898:	a90b5ff6 	stp	x22, x23, [sp, #176]
ffff00000008189c:	a90c67f8 	stp	x24, x25, [sp, #192]
ffff0000000818a0:	a90d6ffa 	stp	x26, x27, [sp, #208]
ffff0000000818a4:	a90e77fc 	stp	x28, x29, [sp, #224]
ffff0000000818a8:	d5384100 	mrs	x0, sp_el0
ffff0000000818ac:	a90f03fe 	stp	x30, x0, [sp, #240]
    mov x0, #2
ffff0000000818b0:	d2800040 	mov	x0, #0x2                   	// #2
    handler_entry
ffff0000000818b4:	d5385201 	mrs	x1, esr_el1
ffff0000000818b8:	a91007e0 	stp	x0, x1, [sp, #256]
ffff0000000818bc:	d5384020 	mrs	x0, elr_el1
ffff0000000818c0:	d5384001 	mrs	x1, spsr_el1
ffff0000000818c4:	a91107e0 	stp	x0, x1, [sp, #272]
ffff0000000818c8:	910003e0 	mov	x0, sp
ffff0000000818cc:	940000eb 	bl	ffff000000081c78 <handler>
ffff0000000818d0:	17ffffae 	b	ffff000000081788 <trap_return>

ffff0000000818d4 <error>:

error:
    kernel_entry
ffff0000000818d4:	d10483ff 	sub	sp, sp, #0x120
ffff0000000818d8:	a90007e0 	stp	x0, x1, [sp]
ffff0000000818dc:	a9010fe2 	stp	x2, x3, [sp, #16]
ffff0000000818e0:	a90217e4 	stp	x4, x5, [sp, #32]
ffff0000000818e4:	a9031fe6 	stp	x6, x7, [sp, #48]
ffff0000000818e8:	a90427e8 	stp	x8, x9, [sp, #64]
ffff0000000818ec:	a9052fea 	stp	x10, x11, [sp, #80]
ffff0000000818f0:	a90637ec 	stp	x12, x13, [sp, #96]
ffff0000000818f4:	a9073fee 	stp	x14, x15, [sp, #112]
ffff0000000818f8:	a90847f0 	stp	x16, x17, [sp, #128]
ffff0000000818fc:	a9094ff2 	stp	x18, x19, [sp, #144]
ffff000000081900:	a90a57f4 	stp	x20, x21, [sp, #160]
ffff000000081904:	a90b5ff6 	stp	x22, x23, [sp, #176]
ffff000000081908:	a90c67f8 	stp	x24, x25, [sp, #192]
ffff00000008190c:	a90d6ffa 	stp	x26, x27, [sp, #208]
ffff000000081910:	a90e77fc 	stp	x28, x29, [sp, #224]
ffff000000081914:	d5384100 	mrs	x0, sp_el0
ffff000000081918:	a90f03fe 	stp	x30, x0, [sp, #240]
    mov x0, #0
ffff00000008191c:	d2800000 	mov	x0, #0x0                   	// #0
    handler_entry
ffff000000081920:	d5385201 	mrs	x1, esr_el1
ffff000000081924:	a91007e0 	stp	x0, x1, [sp, #256]
ffff000000081928:	d5384020 	mrs	x0, elr_el1
ffff00000008192c:	d5384001 	mrs	x1, spsr_el1
ffff000000081930:	a91107e0 	stp	x0, x1, [sp, #272]
ffff000000081934:	910003e0 	mov	x0, sp
ffff000000081938:	940000d0 	bl	ffff000000081c78 <handler>
ffff00000008193c:	17ffff93 	b	ffff000000081788 <trap_return>

ffff000000081940 <read_timer_freq>:

read_timer_freq:
    mrs x0, CNTFRQ_EL0
ffff000000081940:	d53be000 	mrs	x0, cntfrq_el0
    ret
ffff000000081944:	d65f03c0 	ret

ffff000000081948 <set_timer_interval>:

set_timer_interval:
    msr CNTP_TVAL_El0, x0
ffff000000081948:	d51be200 	msr	cntp_tval_el0, x0
    ret
ffff00000008194c:	d65f03c0 	ret

ffff000000081950 <enable_timer>:

enable_timer:
    stp x29, x30, [sp, #-16]!
ffff000000081950:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!

    bl read_timer_freq
ffff000000081954:	97fffffb 	bl	ffff000000081940 <read_timer_freq>
    mov x1, #100
ffff000000081958:	d2800c81 	mov	x1, #0x64                  	// #100
    udiv x0, x0, x1
ffff00000008195c:	9ac10800 	udiv	x0, x0, x1
    bl set_timer_interval
ffff000000081960:	97fffffa 	bl	ffff000000081948 <set_timer_interval>

    mov x0, #1
ffff000000081964:	d2800020 	mov	x0, #0x1                   	// #1
    msr CNTP_CTL_EL0, x0
ffff000000081968:	d51be220 	msr	cntp_ctl_el0, x0

    ldp x29, x30, [sp], #16
ffff00000008196c:	a8c17bfd 	ldp	x29, x30, [sp], #16
    ret
ffff000000081970:	d65f03c0 	ret

ffff000000081974 <read_timer_status>:

read_timer_status:
    mrs x0, CNTP_CTL_EL0
ffff000000081974:	d53be220 	mrs	x0, cntp_ctl_el0
    ret
ffff000000081978:	d65f03c0 	ret

ffff00000008197c <enable_irq>:

enable_irq:
    msr daifclr, #2
ffff00000008197c:	d50342ff 	msr	daifclr, #0x2
    ret
ffff000000081980:	d65f03c0 	ret

ffff000000081984 <swap>:

swap:
    sub	sp,  sp,  #(12 * 8)
ffff000000081984:	d10183ff 	sub	sp, sp, #0x60
	stp	x19, x20, [sp, #(16 * 0)]
ffff000000081988:	a90053f3 	stp	x19, x20, [sp]
	stp	x21, x22, [sp, #(16 * 1)]
ffff00000008198c:	a9015bf5 	stp	x21, x22, [sp, #16]
	stp	x23, x24, [sp, #(16 * 2)]
ffff000000081990:	a90263f7 	stp	x23, x24, [sp, #32]
	stp	x25, x26, [sp, #(16 * 3)]
ffff000000081994:	a9036bf9 	stp	x25, x26, [sp, #48]
	stp	x27, x28, [sp, #(16 * 4)]
ffff000000081998:	a90473fb 	stp	x27, x28, [sp, #64]
	stp	x29, x30, [sp, #(16 * 5)]
ffff00000008199c:	a9057bfd 	stp	x29, x30, [sp, #80]

    mov x2, sp
ffff0000000819a0:	910003e2 	mov	x2, sp
    str x2, [x0]
ffff0000000819a4:	f9000002 	str	x2, [x0]
    mov sp, x1
ffff0000000819a8:	9100003f 	mov	sp, x1

    ldp	x19, x20, [sp, #(16 * 0)]
ffff0000000819ac:	a94053f3 	ldp	x19, x20, [sp]
	ldp	x21, x22, [sp, #(16 * 1)]
ffff0000000819b0:	a9415bf5 	ldp	x21, x22, [sp, #16]
	ldp	x23, x24, [sp, #(16 * 2)]
ffff0000000819b4:	a94263f7 	ldp	x23, x24, [sp, #32]
	ldp	x25, x26, [sp, #(16 * 3)]
ffff0000000819b8:	a9436bf9 	ldp	x25, x26, [sp, #48]
	ldp	x27, x28, [sp, #(16 * 4)]
ffff0000000819bc:	a94473fb 	ldp	x27, x28, [sp, #64]
	ldp	x29, x30, [sp, #(16 * 5)]
ffff0000000819c0:	a9457bfd 	ldp	x29, x30, [sp, #80]
    add sp,  sp,  #(12 * 8)
ffff0000000819c4:	910183ff 	add	sp, sp, #0x60

    ret
ffff0000000819c8:	d65f03c0 	ret

ffff0000000819cc <swap_new>:

swap_new:
    stp x19, x20, [sp, #(16 * 0)]
ffff0000000819cc:	a90053f3 	stp	x19, x20, [sp]
    stp x21, x22, [sp, #(16 * 1)]
ffff0000000819d0:	a9015bf5 	stp	x21, x22, [sp, #16]
    stp x23, x24, [sp, #(16 * 2)]
ffff0000000819d4:	a90263f7 	stp	x23, x24, [sp, #32]
    stp x25, x26, [sp, #(16 * 3)]
ffff0000000819d8:	a9036bf9 	stp	x25, x26, [sp, #48]
    stp x27, x28, [sp, #(16 * 4)]
ffff0000000819dc:	a90473fb 	stp	x27, x28, [sp, #64]
    stp x29, x30, [sp, #(16 * 5)]
ffff0000000819e0:	a9057bfd 	stp	x29, x30, [sp, #80]

    // prev->context = sp
    mov x2, sp
ffff0000000819e4:	910003e2 	mov	x2, sp
    str x2, [x0]
ffff0000000819e8:	f9000002 	str	x2, [x0]

    // sp = current->context
    mov sp, x1
ffff0000000819ec:	9100003f 	mov	sp, x1

    ldp x19, x20, [sp, #(16 * 0)]
ffff0000000819f0:	a94053f3 	ldp	x19, x20, [sp]
    ldp x21, x22, [sp, #(16 * 1)]
ffff0000000819f4:	a9415bf5 	ldp	x21, x22, [sp, #16]
    ldp x23, x24, [sp, #(16 * 2)]
ffff0000000819f8:	a94263f7 	ldp	x23, x24, [sp, #32]
    ldp x25, x26, [sp, #(16 * 3)]
ffff0000000819fc:	a9436bf9 	ldp	x25, x26, [sp, #48]
    ldp x27, x28, [sp, #(16 * 4)]
ffff000000081a00:	a94473fb 	ldp	x27, x28, [sp, #64]
    ldp x29, x30, [sp, #(16 * 5)]
ffff000000081a04:	a9457bfd 	ldp	x29, x30, [sp, #80]

    ret
ffff000000081a08:	d65f03c0 	ret

ffff000000081a0c <get_ticks>:
static uint32_t timer_interval = 0;
static uint64_t ticks = 0;

uint64_t get_ticks(void)
{
    return ticks;
ffff000000081a0c:	90000060 	adrp	x0, ffff00000008d000 <_binary_user_bin_start+0x200>
ffff000000081a10:	91386000 	add	x0, x0, #0xe18
ffff000000081a14:	f9400000 	ldr	x0, [x0]
}
ffff000000081a18:	d65f03c0 	ret

ffff000000081a1c <init_interrupt_controller>:

void init_interrupt_controller(void)
{
ffff000000081a1c:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffff000000081a20:	910003fd 	mov	x29, sp
    out_word(DISABLE_BASIC_IRQS, 0xffffffff);
ffff000000081a24:	12800001 	mov	w1, #0xffffffff            	// #-1
ffff000000081a28:	d2964480 	mov	x0, #0xb224                	// #45604
ffff000000081a2c:	f2a7e000 	movk	x0, #0x3f00, lsl #16
ffff000000081a30:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000081a34:	97fff9c4 	bl	ffff000000080144 <out_word>
    out_word(DISABLE_IRQS_1, 0xffffffff);
ffff000000081a38:	12800001 	mov	w1, #0xffffffff            	// #-1
ffff000000081a3c:	d2964380 	mov	x0, #0xb21c                	// #45596
ffff000000081a40:	f2a7e000 	movk	x0, #0x3f00, lsl #16
ffff000000081a44:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000081a48:	97fff9bf 	bl	ffff000000080144 <out_word>
    out_word(DISABLE_IRQS_2, 0xffffffff);
ffff000000081a4c:	12800001 	mov	w1, #0xffffffff            	// #-1
ffff000000081a50:	d2964400 	mov	x0, #0xb220                	// #45600
ffff000000081a54:	f2a7e000 	movk	x0, #0x3f00, lsl #16
ffff000000081a58:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000081a5c:	97fff9ba 	bl	ffff000000080144 <out_word>

    out_word(ENABLE_IRQS_2, (1 << 25));
ffff000000081a60:	52a04001 	mov	w1, #0x2000000             	// #33554432
ffff000000081a64:	d2964280 	mov	x0, #0xb214                	// #45588
ffff000000081a68:	f2a7e000 	movk	x0, #0x3f00, lsl #16
ffff000000081a6c:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000081a70:	97fff9b5 	bl	ffff000000080144 <out_word>
}
ffff000000081a74:	d503201f 	nop
ffff000000081a78:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffff000000081a7c:	d65f03c0 	ret

ffff000000081a80 <init_timer>:

void init_timer(void)
{
ffff000000081a80:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffff000000081a84:	910003fd 	mov	x29, sp
    timer_interval = read_timer_freq() / 100;
ffff000000081a88:	97ffffae 	bl	ffff000000081940 <read_timer_freq>
ffff000000081a8c:	2a0003e1 	mov	w1, w0
ffff000000081a90:	5290a3e0 	mov	w0, #0x851f                	// #34079
ffff000000081a94:	72aa3d60 	movk	w0, #0x51eb, lsl #16
ffff000000081a98:	9ba07c20 	umull	x0, w1, w0
ffff000000081a9c:	d360fc00 	lsr	x0, x0, #32
ffff000000081aa0:	53057c01 	lsr	w1, w0, #5
ffff000000081aa4:	90000060 	adrp	x0, ffff00000008d000 <_binary_user_bin_start+0x200>
ffff000000081aa8:	91384000 	add	x0, x0, #0xe10
ffff000000081aac:	b9000001 	str	w1, [x0]
    enable_timer();
ffff000000081ab0:	97ffffa8 	bl	ffff000000081950 <enable_timer>
    out_word(CNTP_EL0, (1 << 1));
ffff000000081ab4:	52800041 	mov	w1, #0x2                   	// #2
ffff000000081ab8:	d2800800 	mov	x0, #0x40                  	// #64
ffff000000081abc:	f2a80000 	movk	x0, #0x4000, lsl #16
ffff000000081ac0:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000081ac4:	97fff9a0 	bl	ffff000000080144 <out_word>
}
ffff000000081ac8:	d503201f 	nop
ffff000000081acc:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffff000000081ad0:	d65f03c0 	ret

ffff000000081ad4 <check_sleep_list>:

void check_sleep_list(void)
{
ffff000000081ad4:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff000000081ad8:	910003fd 	mov	x29, sp
    struct ProcessControl *pc = get_pc();
ffff000000081adc:	94002582 	bl	ffff00000008b0e4 <get_pc>
ffff000000081ae0:	f90017e0 	str	x0, [sp, #40]
    struct List *cur = pc->wait_list.next;
ffff000000081ae4:	f94017e0 	ldr	x0, [sp, #40]
ffff000000081ae8:	f9400c00 	ldr	x0, [x0, #24]
ffff000000081aec:	f9001fe0 	str	x0, [sp, #56]
    struct List *prev = (struct List*)&pc->wait_list;
ffff000000081af0:	f94017e0 	ldr	x0, [sp, #40]
ffff000000081af4:	91006000 	add	x0, x0, #0x18
ffff000000081af8:	f9001be0 	str	x0, [sp, #48]

    while (cur != 0) {
ffff000000081afc:	14000027 	b	ffff000000081b98 <check_sleep_list+0xc4>

        struct Process *p = (struct Process*)cur;
ffff000000081b00:	f9401fe0 	ldr	x0, [sp, #56]
ffff000000081b04:	f90013e0 	str	x0, [sp, #32]

        p->wait--;
ffff000000081b08:	f94013e0 	ldr	x0, [sp, #32]
ffff000000081b0c:	b9401000 	ldr	w0, [x0, #16]
ffff000000081b10:	51000401 	sub	w1, w0, #0x1
ffff000000081b14:	f94013e0 	ldr	x0, [sp, #32]
ffff000000081b18:	b9001001 	str	w1, [x0, #16]

        if (p->wait <= 0) {
ffff000000081b1c:	f94013e0 	ldr	x0, [sp, #32]
ffff000000081b20:	b9401000 	ldr	w0, [x0, #16]
ffff000000081b24:	7100001f 	cmp	w0, #0x0
ffff000000081b28:	540002ec 	b.gt	ffff000000081b84 <check_sleep_list+0xb0>

            struct List *next = cur->next;
ffff000000081b2c:	f9401fe0 	ldr	x0, [sp, #56]
ffff000000081b30:	f9400000 	ldr	x0, [x0]
ffff000000081b34:	f9000fe0 	str	x0, [sp, #24]

            prev->next = next;
ffff000000081b38:	f9401be0 	ldr	x0, [sp, #48]
ffff000000081b3c:	f9400fe1 	ldr	x1, [sp, #24]
ffff000000081b40:	f9000001 	str	x1, [x0]
            if (next == 0)
ffff000000081b44:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000081b48:	f100001f 	cmp	x0, #0x0
ffff000000081b4c:	54000081 	b.ne	ffff000000081b5c <check_sleep_list+0x88>  // b.any
                pc->wait_list.tail = prev;
ffff000000081b50:	f94017e0 	ldr	x0, [sp, #40]
ffff000000081b54:	f9401be1 	ldr	x1, [sp, #48]
ffff000000081b58:	f9001001 	str	x1, [x0, #32]

            p->state = PROC_READY;
ffff000000081b5c:	f94013e0 	ldr	x0, [sp, #32]
ffff000000081b60:	52800061 	mov	w1, #0x3                   	// #3
ffff000000081b64:	b9000c01 	str	w1, [x0, #12]
            append_list_tail(&pc->ready_list, cur);
ffff000000081b68:	f94017e0 	ldr	x0, [sp, #40]
ffff000000081b6c:	91002000 	add	x0, x0, #0x8
ffff000000081b70:	f9401fe1 	ldr	x1, [sp, #56]
ffff000000081b74:	97fff99c 	bl	ffff0000000801e4 <append_list_tail>

            cur = next;
ffff000000081b78:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000081b7c:	f9001fe0 	str	x0, [sp, #56]
            continue;
ffff000000081b80:	14000006 	b	ffff000000081b98 <check_sleep_list+0xc4>
        }

        prev = cur;
ffff000000081b84:	f9401fe0 	ldr	x0, [sp, #56]
ffff000000081b88:	f9001be0 	str	x0, [sp, #48]
        cur = cur->next;
ffff000000081b8c:	f9401fe0 	ldr	x0, [sp, #56]
ffff000000081b90:	f9400000 	ldr	x0, [x0]
ffff000000081b94:	f9001fe0 	str	x0, [sp, #56]
    while (cur != 0) {
ffff000000081b98:	f9401fe0 	ldr	x0, [sp, #56]
ffff000000081b9c:	f100001f 	cmp	x0, #0x0
ffff000000081ba0:	54fffb01 	b.ne	ffff000000081b00 <check_sleep_list+0x2c>  // b.any
    }
}
ffff000000081ba4:	d503201f 	nop
ffff000000081ba8:	d503201f 	nop
ffff000000081bac:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff000000081bb0:	d65f03c0 	ret

ffff000000081bb4 <timer_interrupt_handler>:

static void timer_interrupt_handler(void)
{
ffff000000081bb4:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff000000081bb8:	910003fd 	mov	x29, sp
    uint32_t status = read_timer_status();
ffff000000081bbc:	97ffff6e 	bl	ffff000000081974 <read_timer_status>
ffff000000081bc0:	b9001fe0 	str	w0, [sp, #28]
    if (status & (1 << 2)) {
ffff000000081bc4:	b9401fe0 	ldr	w0, [sp, #28]
ffff000000081bc8:	121e0000 	and	w0, w0, #0x4
ffff000000081bcc:	7100001f 	cmp	w0, #0x0
ffff000000081bd0:	540003e0 	b.eq	ffff000000081c4c <timer_interrupt_handler+0x98>  // b.none
        ticks++;
ffff000000081bd4:	90000060 	adrp	x0, ffff00000008d000 <_binary_user_bin_start+0x200>
ffff000000081bd8:	91386000 	add	x0, x0, #0xe18
ffff000000081bdc:	f9400000 	ldr	x0, [x0]
ffff000000081be0:	91000401 	add	x1, x0, #0x1
ffff000000081be4:	90000060 	adrp	x0, ffff00000008d000 <_binary_user_bin_start+0x200>
ffff000000081be8:	91386000 	add	x0, x0, #0xe18
ffff000000081bec:	f9000001 	str	x1, [x0]
         wake_up(-1);
ffff000000081bf0:	12800000 	mov	w0, #0xffffffff            	// #-1
ffff000000081bf4:	9400283a 	bl	ffff00000008bcdc <wake_up>
       // check_sleep_list();
        if (ticks % 100 == 0) {
ffff000000081bf8:	90000060 	adrp	x0, ffff00000008d000 <_binary_user_bin_start+0x200>
ffff000000081bfc:	91386000 	add	x0, x0, #0xe18
ffff000000081c00:	f9400002 	ldr	x2, [x0]
ffff000000081c04:	d342fc41 	lsr	x1, x2, #2
ffff000000081c08:	d29eb860 	mov	x0, #0xf5c3                	// #62915
ffff000000081c0c:	f2ab8500 	movk	x0, #0x5c28, lsl #16
ffff000000081c10:	f2d851e0 	movk	x0, #0xc28f, lsl #32
ffff000000081c14:	f2e51ea0 	movk	x0, #0x28f5, lsl #48
ffff000000081c18:	9bc07c20 	umulh	x0, x1, x0
ffff000000081c1c:	d342fc01 	lsr	x1, x0, #2
ffff000000081c20:	aa0103e0 	mov	x0, x1
ffff000000081c24:	d37ff800 	lsl	x0, x0, #1
ffff000000081c28:	8b010000 	add	x0, x0, x1
ffff000000081c2c:	d37df000 	lsl	x0, x0, #3
ffff000000081c30:	8b010000 	add	x0, x0, x1
ffff000000081c34:	d37ef400 	lsl	x0, x0, #2
ffff000000081c38:	cb000041 	sub	x1, x2, x0
           // printk("timer %d \r\n", ticks);
        }

        set_timer_interval(timer_interval);
ffff000000081c3c:	90000060 	adrp	x0, ffff00000008d000 <_binary_user_bin_start+0x200>
ffff000000081c40:	91384000 	add	x0, x0, #0xe10
ffff000000081c44:	b9400000 	ldr	w0, [x0]
ffff000000081c48:	97ffff40 	bl	ffff000000081948 <set_timer_interval>
    }
}
ffff000000081c4c:	d503201f 	nop
ffff000000081c50:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff000000081c54:	d65f03c0 	ret

ffff000000081c58 <get_irq_number>:

static uint32_t get_irq_number(void)
{
ffff000000081c58:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffff000000081c5c:	910003fd 	mov	x29, sp
    return in_word(IRQ_BASIC_PENDING);
ffff000000081c60:	d2964000 	mov	x0, #0xb200                	// #45568
ffff000000081c64:	f2a7e000 	movk	x0, #0x3f00, lsl #16
ffff000000081c68:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000081c6c:	97fff938 	bl	ffff00000008014c <in_word>
}
ffff000000081c70:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffff000000081c74:	d65f03c0 	ret

ffff000000081c78 <handler>:

void handler(struct TrapFrame *tf)
{
ffff000000081c78:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff000000081c7c:	910003fd 	mov	x29, sp
ffff000000081c80:	f9000fe0 	str	x0, [sp, #24]
    uint32_t irq;
    int schedule = 0;
ffff000000081c84:	b9002fff 	str	wzr, [sp, #44]

    switch (tf->trapno) {
ffff000000081c88:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000081c8c:	f9408000 	ldr	x0, [x0, #256]
ffff000000081c90:	f1000c1f 	cmp	x0, #0x3
ffff000000081c94:	54000540 	b.eq	ffff000000081d3c <handler+0xc4>  // b.none
ffff000000081c98:	f1000c1f 	cmp	x0, #0x3
ffff000000081c9c:	5400056c 	b.gt	ffff000000081d48 <handler+0xd0>
ffff000000081ca0:	f100041f 	cmp	x0, #0x1
ffff000000081ca4:	54000080 	b.eq	ffff000000081cb4 <handler+0x3c>  // b.none
ffff000000081ca8:	f100081f 	cmp	x0, #0x2
ffff000000081cac:	54000160 	b.eq	ffff000000081cd8 <handler+0x60>  // b.none
ffff000000081cb0:	14000026 	b	ffff000000081d48 <handler+0xd0>
        case 1:
            printk("sync error at %x: %x\r\n", tf->elr, tf->esr);
ffff000000081cb4:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000081cb8:	f9408801 	ldr	x1, [x0, #272]
ffff000000081cbc:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000081cc0:	f9408400 	ldr	x0, [x0, #264]
ffff000000081cc4:	aa0003e2 	mov	x2, x0
ffff000000081cc8:	f0000040 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff000000081ccc:	91042000 	add	x0, x0, #0x108
ffff000000081cd0:	97fffaf7 	bl	ffff0000000808ac <printk>
            while (1) { }
ffff000000081cd4:	14000000 	b	ffff000000081cd4 <handler+0x5c>
            break;

        case 2:
            irq = in_word(CNTP_STATUS_EL0);
ffff000000081cd8:	d2800c00 	mov	x0, #0x60                  	// #96
ffff000000081cdc:	f2a80000 	movk	x0, #0x4000, lsl #16
ffff000000081ce0:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000081ce4:	97fff91a 	bl	ffff00000008014c <in_word>
ffff000000081ce8:	b9002be0 	str	w0, [sp, #40]
            if (irq & (1 << 1)) {
ffff000000081cec:	b9402be0 	ldr	w0, [sp, #40]
ffff000000081cf0:	121f0000 	and	w0, w0, #0x2
ffff000000081cf4:	7100001f 	cmp	w0, #0x0
ffff000000081cf8:	540000a0 	b.eq	ffff000000081d0c <handler+0x94>  // b.none
                timer_interrupt_handler();
ffff000000081cfc:	97ffffae 	bl	ffff000000081bb4 <timer_interrupt_handler>
                schedule = 1;
ffff000000081d00:	52800020 	mov	w0, #0x1                   	// #1
ffff000000081d04:	b9002fe0 	str	w0, [sp, #44]
                else {
                    printk("unknown irq\r\n");
                    while (1) { }
                }
            }
            break;
ffff000000081d08:	14000014 	b	ffff000000081d58 <handler+0xe0>
                irq = get_irq_number();
ffff000000081d0c:	97ffffd3 	bl	ffff000000081c58 <get_irq_number>
ffff000000081d10:	b9002be0 	str	w0, [sp, #40]
                if (irq & (1 << 19)) {
ffff000000081d14:	b9402be0 	ldr	w0, [sp, #40]
ffff000000081d18:	120d0000 	and	w0, w0, #0x80000
ffff000000081d1c:	7100001f 	cmp	w0, #0x0
ffff000000081d20:	54000060 	b.eq	ffff000000081d2c <handler+0xb4>  // b.none
                    uart_handler();
ffff000000081d24:	97fff9d4 	bl	ffff000000080474 <uart_handler>
            break;
ffff000000081d28:	1400000c 	b	ffff000000081d58 <handler+0xe0>
                    printk("unknown irq\r\n");
ffff000000081d2c:	f0000040 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff000000081d30:	91048000 	add	x0, x0, #0x120
ffff000000081d34:	97fffade 	bl	ffff0000000808ac <printk>
                    while (1) { }
ffff000000081d38:	14000000 	b	ffff000000081d38 <handler+0xc0>

        case 3:
            system_call(tf);
ffff000000081d3c:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000081d40:	94002888 	bl	ffff00000008bf60 <system_call>
    printk(" trapno= %d\n", tf->trapno);
    printk(" esr   = 0x%x\n", tf->esr);
    printk(" elr   = 0x%x\n", tf->elr);
    printk(" spsr  = 0x%x\n", tf->spsr);
    */
            break;
ffff000000081d44:	14000005 	b	ffff000000081d58 <handler+0xe0>

        default:
            printk("unknown exception\r\n");
ffff000000081d48:	f0000040 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff000000081d4c:	9104c000 	add	x0, x0, #0x130
ffff000000081d50:	97fffad7 	bl	ffff0000000808ac <printk>
            while (1) { }
ffff000000081d54:	14000000 	b	ffff000000081d54 <handler+0xdc>
    }

    if (schedule == 1) {
ffff000000081d58:	b9402fe0 	ldr	w0, [sp, #44]
ffff000000081d5c:	7100041f 	cmp	w0, #0x1
ffff000000081d60:	54000041 	b.ne	ffff000000081d68 <handler+0xf0>  // b.any
        yield();
ffff000000081d64:	940027aa 	bl	ffff00000008bc0c <yield>
    }
ffff000000081d68:	d503201f 	nop
ffff000000081d6c:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff000000081d70:	d65f03c0 	ret
	...

ffff000000082000 <read_pgd>:
.global load_pgd
.global read_pgd
.global pgd_ttbr0
.global pgd_ttbr1
read_pgd:
    mrs x0, ttbr0_el1
ffff000000082000:	d5382000 	mrs	x0, ttbr0_el1
    ret
ffff000000082004:	d65f03c0 	ret

ffff000000082008 <load_pgd>:

load_pgd:
    msr ttbr0_el1, x0
ffff000000082008:	d5182000 	msr	ttbr0_el1, x0
    tlbi vmalle1is
ffff00000008200c:	d508831f 	tlbi	vmalle1is
    dsb ish
ffff000000082010:	d5033b9f 	dsb	ish
    isb
ffff000000082014:	d5033fdf 	isb

    ret
ffff000000082018:	d65f03c0 	ret

ffff00000008201c <enable_mmu>:

enable_mmu:
    adr x0, pgd_ttbr1
ffff00000008201c:	10007f20 	adr	x0, ffff000000083000 <pgd_ttbr1>
    msr ttbr1_el1, x0
ffff000000082020:	d5182020 	msr	ttbr1_el1, x0

    adr x0, pgd_ttbr0
ffff000000082024:	10027ee0 	adr	x0, ffff000000087000 <pgd_ttbr0>
    msr ttbr0_el1, x0
ffff000000082028:	d5182000 	msr	ttbr0_el1, x0

    ldr x0, =MAIR_ATTR
ffff00000008202c:	5803fea0 	ldr	x0, ffff00000008a000 <pmd_ttbr0+0x1000>
    msr mair_el1, x0
ffff000000082030:	d518a200 	msr	mair_el1, x0

    ldr x0, =TCR_VALUE
ffff000000082034:	5803fea0 	ldr	x0, ffff00000008a008 <pmd_ttbr0+0x1008>
    msr tcr_el1, x0
ffff000000082038:	d5182040 	msr	tcr_el1, x0

    mrs x0, sctlr_el1
ffff00000008203c:	d5381000 	mrs	x0, sctlr_el1
    orr x0, x0, #1
ffff000000082040:	b2400000 	orr	x0, x0, #0x1
    msr sctlr_el1, x0
ffff000000082044:	d5181000 	msr	sctlr_el1, x0
    
    ret
ffff000000082048:	d65f03c0 	ret

ffff00000008204c <setup_vm>:


setup_vm:
setup_kvm:
    adr x0, pgd_ttbr1
ffff00000008204c:	10007da0 	adr	x0, ffff000000083000 <pgd_ttbr1>
    adr x1, pud_ttbr1
ffff000000082050:	1000fd81 	adr	x1, ffff000000084000 <pud_ttbr1>
    orr x1, x1, #3
ffff000000082054:	b2400421 	orr	x1, x1, #0x3

    str x1, [x0]
ffff000000082058:	f9000001 	str	x1, [x0]

    adr x0, pud_ttbr1
ffff00000008205c:	1000fd20 	adr	x0, ffff000000084000 <pud_ttbr1>
    adr x1, pmd_ttbr1
ffff000000082060:	10017d01 	adr	x1, ffff000000085000 <pmd_ttbr1>
    orr x1, x1, #3
ffff000000082064:	b2400421 	orr	x1, x1, #0x3
    str x1, [x0]
ffff000000082068:	f9000001 	str	x1, [x0]

    mov x2, #0x34000000
ffff00000008206c:	d2a68002 	mov	x2, #0x34000000            	// #872415232
    adr x1, pmd_ttbr1
ffff000000082070:	10017c81 	adr	x1, ffff000000085000 <pmd_ttbr1>
    mov x0, #(1 << 10 | 1 << 2 | 1 << 0)
ffff000000082074:	d28080a0 	mov	x0, #0x405                 	// #1029

ffff000000082078 <loop1>:

loop1:
    str x0, [x1], #8
ffff000000082078:	f8008420 	str	x0, [x1], #8
    add x0, x0, #PAGE_SIZE
ffff00000008207c:	91480000 	add	x0, x0, #0x200, lsl #12
    cmp x0, x2
ffff000000082080:	eb02001f 	cmp	x0, x2
    blo loop1
ffff000000082084:	54ffffa3 	b.cc	ffff000000082078 <loop1>  // b.lo, b.ul, b.last

    mov x2, #0x40000000
ffff000000082088:	d2a80002 	mov	x2, #0x40000000            	// #1073741824
    mov x0, #0x3f000000
ffff00000008208c:	d2a7e000 	mov	x0, #0x3f000000            	// #1056964608

    adr x3, pmd_ttbr1
ffff000000082090:	10017b83 	adr	x3, ffff000000085000 <pmd_ttbr1>
    lsr x1, x0, #(21 - 3)
ffff000000082094:	d352fc01 	lsr	x1, x0, #18
    add x1, x1, x3
ffff000000082098:	8b030021 	add	x1, x1, x3

    orr x0, x0, #1
ffff00000008209c:	b2400000 	orr	x0, x0, #0x1
    orr x0, x0, #(1 << 10)
ffff0000000820a0:	b2760000 	orr	x0, x0, #0x400

ffff0000000820a4 <loop2>:

loop2:
    str x0, [x1], #8
ffff0000000820a4:	f8008420 	str	x0, [x1], #8
    add x0, x0, #PAGE_SIZE
ffff0000000820a8:	91480000 	add	x0, x0, #0x200, lsl #12
    cmp x0, x2
ffff0000000820ac:	eb02001f 	cmp	x0, x2
    blo loop2
ffff0000000820b0:	54ffffa3 	b.cc	ffff0000000820a4 <loop2>  // b.lo, b.ul, b.last

    adr x0, pud_ttbr1
ffff0000000820b4:	1000fa60 	adr	x0, ffff000000084000 <pud_ttbr1>
    add x0, x0, #(1 * 8)
ffff0000000820b8:	91002000 	add	x0, x0, #0x8
    adr x1, pmd2_ttbr1
ffff0000000820bc:	1001fa21 	adr	x1, ffff000000086000 <pmd2_ttbr1>
    orr x1, x1, #3
ffff0000000820c0:	b2400421 	orr	x1, x1, #0x3
    str x1, [x0]
ffff0000000820c4:	f9000001 	str	x1, [x0]

    mov x2, #0x41000000
ffff0000000820c8:	d2a82002 	mov	x2, #0x41000000            	// #1090519040
    mov x0, #0x40000000
ffff0000000820cc:	d2a80000 	mov	x0, #0x40000000            	// #1073741824

    adr x1, pmd2_ttbr1
ffff0000000820d0:	1001f981 	adr	x1, ffff000000086000 <pmd2_ttbr1>
    orr x0, x0, #1
ffff0000000820d4:	b2400000 	orr	x0, x0, #0x1
    orr x0, x0, #(1 << 10)
ffff0000000820d8:	b2760000 	orr	x0, x0, #0x400

ffff0000000820dc <loop3>:

loop3:
    str x0, [x1], #8
ffff0000000820dc:	f8008420 	str	x0, [x1], #8
    add x0, x0, #PAGE_SIZE
ffff0000000820e0:	91480000 	add	x0, x0, #0x200, lsl #12
    cmp x0, x2
ffff0000000820e4:	eb02001f 	cmp	x0, x2
    blo loop3
ffff0000000820e8:	54ffffa3 	b.cc	ffff0000000820dc <loop3>  // b.lo, b.ul, b.last

ffff0000000820ec <setup_uvm>:


setup_uvm:
    adr x0, pgd_ttbr0
ffff0000000820ec:	100278a0 	adr	x0, ffff000000087000 <pgd_ttbr0>
    adr x1, pud_ttbr0
ffff0000000820f0:	1002f881 	adr	x1, ffff000000088000 <pud_ttbr0>
    orr x1, x1, #3
ffff0000000820f4:	b2400421 	orr	x1, x1, #0x3
    str x1, [x0]
ffff0000000820f8:	f9000001 	str	x1, [x0]

    adr x0, pud_ttbr0
ffff0000000820fc:	1002f820 	adr	x0, ffff000000088000 <pud_ttbr0>
    adr x1, pmd_ttbr0
ffff000000082100:	10037801 	adr	x1, ffff000000089000 <pmd_ttbr0>
    orr x1, x1, #3
ffff000000082104:	b2400421 	orr	x1, x1, #0x3
    str x1, [x0]
ffff000000082108:	f9000001 	str	x1, [x0]

    adr x1, pmd_ttbr0
ffff00000008210c:	100377a1 	adr	x1, ffff000000089000 <pmd_ttbr0>
    mov x0, #(1 << 10 | 1 << 2 | 1 << 0)
ffff000000082110:	d28080a0 	mov	x0, #0x405                 	// #1029
    str x0, [x1]
ffff000000082114:	f9000020 	str	x0, [x1]

    ret
ffff000000082118:	d65f03c0 	ret
ffff00000008211c:	d503201f 	nop
ffff000000082120:	d503201f 	nop
ffff000000082124:	d503201f 	nop
ffff000000082128:	d503201f 	nop
ffff00000008212c:	d503201f 	nop
ffff000000082130:	d503201f 	nop
ffff000000082134:	d503201f 	nop
ffff000000082138:	d503201f 	nop
ffff00000008213c:	d503201f 	nop
ffff000000082140:	d503201f 	nop
ffff000000082144:	d503201f 	nop
ffff000000082148:	d503201f 	nop
ffff00000008214c:	d503201f 	nop
ffff000000082150:	d503201f 	nop
ffff000000082154:	d503201f 	nop
ffff000000082158:	d503201f 	nop
ffff00000008215c:	d503201f 	nop
ffff000000082160:	d503201f 	nop
ffff000000082164:	d503201f 	nop
ffff000000082168:	d503201f 	nop
ffff00000008216c:	d503201f 	nop
ffff000000082170:	d503201f 	nop
ffff000000082174:	d503201f 	nop
ffff000000082178:	d503201f 	nop
ffff00000008217c:	d503201f 	nop
ffff000000082180:	d503201f 	nop
ffff000000082184:	d503201f 	nop
ffff000000082188:	d503201f 	nop
ffff00000008218c:	d503201f 	nop
ffff000000082190:	d503201f 	nop
ffff000000082194:	d503201f 	nop
ffff000000082198:	d503201f 	nop
ffff00000008219c:	d503201f 	nop
ffff0000000821a0:	d503201f 	nop
ffff0000000821a4:	d503201f 	nop
ffff0000000821a8:	d503201f 	nop
ffff0000000821ac:	d503201f 	nop
ffff0000000821b0:	d503201f 	nop
ffff0000000821b4:	d503201f 	nop
ffff0000000821b8:	d503201f 	nop
ffff0000000821bc:	d503201f 	nop
ffff0000000821c0:	d503201f 	nop
ffff0000000821c4:	d503201f 	nop
ffff0000000821c8:	d503201f 	nop
ffff0000000821cc:	d503201f 	nop
ffff0000000821d0:	d503201f 	nop
ffff0000000821d4:	d503201f 	nop
ffff0000000821d8:	d503201f 	nop
ffff0000000821dc:	d503201f 	nop
ffff0000000821e0:	d503201f 	nop
ffff0000000821e4:	d503201f 	nop
ffff0000000821e8:	d503201f 	nop
ffff0000000821ec:	d503201f 	nop
ffff0000000821f0:	d503201f 	nop
ffff0000000821f4:	d503201f 	nop
ffff0000000821f8:	d503201f 	nop
ffff0000000821fc:	d503201f 	nop
ffff000000082200:	d503201f 	nop
ffff000000082204:	d503201f 	nop
ffff000000082208:	d503201f 	nop
ffff00000008220c:	d503201f 	nop
ffff000000082210:	d503201f 	nop
ffff000000082214:	d503201f 	nop
ffff000000082218:	d503201f 	nop
ffff00000008221c:	d503201f 	nop
ffff000000082220:	d503201f 	nop
ffff000000082224:	d503201f 	nop
ffff000000082228:	d503201f 	nop
ffff00000008222c:	d503201f 	nop
ffff000000082230:	d503201f 	nop
ffff000000082234:	d503201f 	nop
ffff000000082238:	d503201f 	nop
ffff00000008223c:	d503201f 	nop
ffff000000082240:	d503201f 	nop
ffff000000082244:	d503201f 	nop
ffff000000082248:	d503201f 	nop
ffff00000008224c:	d503201f 	nop
ffff000000082250:	d503201f 	nop
ffff000000082254:	d503201f 	nop
ffff000000082258:	d503201f 	nop
ffff00000008225c:	d503201f 	nop
ffff000000082260:	d503201f 	nop
ffff000000082264:	d503201f 	nop
ffff000000082268:	d503201f 	nop
ffff00000008226c:	d503201f 	nop
ffff000000082270:	d503201f 	nop
ffff000000082274:	d503201f 	nop
ffff000000082278:	d503201f 	nop
ffff00000008227c:	d503201f 	nop
ffff000000082280:	d503201f 	nop
ffff000000082284:	d503201f 	nop
ffff000000082288:	d503201f 	nop
ffff00000008228c:	d503201f 	nop
ffff000000082290:	d503201f 	nop
ffff000000082294:	d503201f 	nop
ffff000000082298:	d503201f 	nop
ffff00000008229c:	d503201f 	nop
ffff0000000822a0:	d503201f 	nop
ffff0000000822a4:	d503201f 	nop
ffff0000000822a8:	d503201f 	nop
ffff0000000822ac:	d503201f 	nop
ffff0000000822b0:	d503201f 	nop
ffff0000000822b4:	d503201f 	nop
ffff0000000822b8:	d503201f 	nop
ffff0000000822bc:	d503201f 	nop
ffff0000000822c0:	d503201f 	nop
ffff0000000822c4:	d503201f 	nop
ffff0000000822c8:	d503201f 	nop
ffff0000000822cc:	d503201f 	nop
ffff0000000822d0:	d503201f 	nop
ffff0000000822d4:	d503201f 	nop
ffff0000000822d8:	d503201f 	nop
ffff0000000822dc:	d503201f 	nop
ffff0000000822e0:	d503201f 	nop
ffff0000000822e4:	d503201f 	nop
ffff0000000822e8:	d503201f 	nop
ffff0000000822ec:	d503201f 	nop
ffff0000000822f0:	d503201f 	nop
ffff0000000822f4:	d503201f 	nop
ffff0000000822f8:	d503201f 	nop
ffff0000000822fc:	d503201f 	nop
ffff000000082300:	d503201f 	nop
ffff000000082304:	d503201f 	nop
ffff000000082308:	d503201f 	nop
ffff00000008230c:	d503201f 	nop
ffff000000082310:	d503201f 	nop
ffff000000082314:	d503201f 	nop
ffff000000082318:	d503201f 	nop
ffff00000008231c:	d503201f 	nop
ffff000000082320:	d503201f 	nop
ffff000000082324:	d503201f 	nop
ffff000000082328:	d503201f 	nop
ffff00000008232c:	d503201f 	nop
ffff000000082330:	d503201f 	nop
ffff000000082334:	d503201f 	nop
ffff000000082338:	d503201f 	nop
ffff00000008233c:	d503201f 	nop
ffff000000082340:	d503201f 	nop
ffff000000082344:	d503201f 	nop
ffff000000082348:	d503201f 	nop
ffff00000008234c:	d503201f 	nop
ffff000000082350:	d503201f 	nop
ffff000000082354:	d503201f 	nop
ffff000000082358:	d503201f 	nop
ffff00000008235c:	d503201f 	nop
ffff000000082360:	d503201f 	nop
ffff000000082364:	d503201f 	nop
ffff000000082368:	d503201f 	nop
ffff00000008236c:	d503201f 	nop
ffff000000082370:	d503201f 	nop
ffff000000082374:	d503201f 	nop
ffff000000082378:	d503201f 	nop
ffff00000008237c:	d503201f 	nop
ffff000000082380:	d503201f 	nop
ffff000000082384:	d503201f 	nop
ffff000000082388:	d503201f 	nop
ffff00000008238c:	d503201f 	nop
ffff000000082390:	d503201f 	nop
ffff000000082394:	d503201f 	nop
ffff000000082398:	d503201f 	nop
ffff00000008239c:	d503201f 	nop
ffff0000000823a0:	d503201f 	nop
ffff0000000823a4:	d503201f 	nop
ffff0000000823a8:	d503201f 	nop
ffff0000000823ac:	d503201f 	nop
ffff0000000823b0:	d503201f 	nop
ffff0000000823b4:	d503201f 	nop
ffff0000000823b8:	d503201f 	nop
ffff0000000823bc:	d503201f 	nop
ffff0000000823c0:	d503201f 	nop
ffff0000000823c4:	d503201f 	nop
ffff0000000823c8:	d503201f 	nop
ffff0000000823cc:	d503201f 	nop
ffff0000000823d0:	d503201f 	nop
ffff0000000823d4:	d503201f 	nop
ffff0000000823d8:	d503201f 	nop
ffff0000000823dc:	d503201f 	nop
ffff0000000823e0:	d503201f 	nop
ffff0000000823e4:	d503201f 	nop
ffff0000000823e8:	d503201f 	nop
ffff0000000823ec:	d503201f 	nop
ffff0000000823f0:	d503201f 	nop
ffff0000000823f4:	d503201f 	nop
ffff0000000823f8:	d503201f 	nop
ffff0000000823fc:	d503201f 	nop
ffff000000082400:	d503201f 	nop
ffff000000082404:	d503201f 	nop
ffff000000082408:	d503201f 	nop
ffff00000008240c:	d503201f 	nop
ffff000000082410:	d503201f 	nop
ffff000000082414:	d503201f 	nop
ffff000000082418:	d503201f 	nop
ffff00000008241c:	d503201f 	nop
ffff000000082420:	d503201f 	nop
ffff000000082424:	d503201f 	nop
ffff000000082428:	d503201f 	nop
ffff00000008242c:	d503201f 	nop
ffff000000082430:	d503201f 	nop
ffff000000082434:	d503201f 	nop
ffff000000082438:	d503201f 	nop
ffff00000008243c:	d503201f 	nop
ffff000000082440:	d503201f 	nop
ffff000000082444:	d503201f 	nop
ffff000000082448:	d503201f 	nop
ffff00000008244c:	d503201f 	nop
ffff000000082450:	d503201f 	nop
ffff000000082454:	d503201f 	nop
ffff000000082458:	d503201f 	nop
ffff00000008245c:	d503201f 	nop
ffff000000082460:	d503201f 	nop
ffff000000082464:	d503201f 	nop
ffff000000082468:	d503201f 	nop
ffff00000008246c:	d503201f 	nop
ffff000000082470:	d503201f 	nop
ffff000000082474:	d503201f 	nop
ffff000000082478:	d503201f 	nop
ffff00000008247c:	d503201f 	nop
ffff000000082480:	d503201f 	nop
ffff000000082484:	d503201f 	nop
ffff000000082488:	d503201f 	nop
ffff00000008248c:	d503201f 	nop
ffff000000082490:	d503201f 	nop
ffff000000082494:	d503201f 	nop
ffff000000082498:	d503201f 	nop
ffff00000008249c:	d503201f 	nop
ffff0000000824a0:	d503201f 	nop
ffff0000000824a4:	d503201f 	nop
ffff0000000824a8:	d503201f 	nop
ffff0000000824ac:	d503201f 	nop
ffff0000000824b0:	d503201f 	nop
ffff0000000824b4:	d503201f 	nop
ffff0000000824b8:	d503201f 	nop
ffff0000000824bc:	d503201f 	nop
ffff0000000824c0:	d503201f 	nop
ffff0000000824c4:	d503201f 	nop
ffff0000000824c8:	d503201f 	nop
ffff0000000824cc:	d503201f 	nop
ffff0000000824d0:	d503201f 	nop
ffff0000000824d4:	d503201f 	nop
ffff0000000824d8:	d503201f 	nop
ffff0000000824dc:	d503201f 	nop
ffff0000000824e0:	d503201f 	nop
ffff0000000824e4:	d503201f 	nop
ffff0000000824e8:	d503201f 	nop
ffff0000000824ec:	d503201f 	nop
ffff0000000824f0:	d503201f 	nop
ffff0000000824f4:	d503201f 	nop
ffff0000000824f8:	d503201f 	nop
ffff0000000824fc:	d503201f 	nop
ffff000000082500:	d503201f 	nop
ffff000000082504:	d503201f 	nop
ffff000000082508:	d503201f 	nop
ffff00000008250c:	d503201f 	nop
ffff000000082510:	d503201f 	nop
ffff000000082514:	d503201f 	nop
ffff000000082518:	d503201f 	nop
ffff00000008251c:	d503201f 	nop
ffff000000082520:	d503201f 	nop
ffff000000082524:	d503201f 	nop
ffff000000082528:	d503201f 	nop
ffff00000008252c:	d503201f 	nop
ffff000000082530:	d503201f 	nop
ffff000000082534:	d503201f 	nop
ffff000000082538:	d503201f 	nop
ffff00000008253c:	d503201f 	nop
ffff000000082540:	d503201f 	nop
ffff000000082544:	d503201f 	nop
ffff000000082548:	d503201f 	nop
ffff00000008254c:	d503201f 	nop
ffff000000082550:	d503201f 	nop
ffff000000082554:	d503201f 	nop
ffff000000082558:	d503201f 	nop
ffff00000008255c:	d503201f 	nop
ffff000000082560:	d503201f 	nop
ffff000000082564:	d503201f 	nop
ffff000000082568:	d503201f 	nop
ffff00000008256c:	d503201f 	nop
ffff000000082570:	d503201f 	nop
ffff000000082574:	d503201f 	nop
ffff000000082578:	d503201f 	nop
ffff00000008257c:	d503201f 	nop
ffff000000082580:	d503201f 	nop
ffff000000082584:	d503201f 	nop
ffff000000082588:	d503201f 	nop
ffff00000008258c:	d503201f 	nop
ffff000000082590:	d503201f 	nop
ffff000000082594:	d503201f 	nop
ffff000000082598:	d503201f 	nop
ffff00000008259c:	d503201f 	nop
ffff0000000825a0:	d503201f 	nop
ffff0000000825a4:	d503201f 	nop
ffff0000000825a8:	d503201f 	nop
ffff0000000825ac:	d503201f 	nop
ffff0000000825b0:	d503201f 	nop
ffff0000000825b4:	d503201f 	nop
ffff0000000825b8:	d503201f 	nop
ffff0000000825bc:	d503201f 	nop
ffff0000000825c0:	d503201f 	nop
ffff0000000825c4:	d503201f 	nop
ffff0000000825c8:	d503201f 	nop
ffff0000000825cc:	d503201f 	nop
ffff0000000825d0:	d503201f 	nop
ffff0000000825d4:	d503201f 	nop
ffff0000000825d8:	d503201f 	nop
ffff0000000825dc:	d503201f 	nop
ffff0000000825e0:	d503201f 	nop
ffff0000000825e4:	d503201f 	nop
ffff0000000825e8:	d503201f 	nop
ffff0000000825ec:	d503201f 	nop
ffff0000000825f0:	d503201f 	nop
ffff0000000825f4:	d503201f 	nop
ffff0000000825f8:	d503201f 	nop
ffff0000000825fc:	d503201f 	nop
ffff000000082600:	d503201f 	nop
ffff000000082604:	d503201f 	nop
ffff000000082608:	d503201f 	nop
ffff00000008260c:	d503201f 	nop
ffff000000082610:	d503201f 	nop
ffff000000082614:	d503201f 	nop
ffff000000082618:	d503201f 	nop
ffff00000008261c:	d503201f 	nop
ffff000000082620:	d503201f 	nop
ffff000000082624:	d503201f 	nop
ffff000000082628:	d503201f 	nop
ffff00000008262c:	d503201f 	nop
ffff000000082630:	d503201f 	nop
ffff000000082634:	d503201f 	nop
ffff000000082638:	d503201f 	nop
ffff00000008263c:	d503201f 	nop
ffff000000082640:	d503201f 	nop
ffff000000082644:	d503201f 	nop
ffff000000082648:	d503201f 	nop
ffff00000008264c:	d503201f 	nop
ffff000000082650:	d503201f 	nop
ffff000000082654:	d503201f 	nop
ffff000000082658:	d503201f 	nop
ffff00000008265c:	d503201f 	nop
ffff000000082660:	d503201f 	nop
ffff000000082664:	d503201f 	nop
ffff000000082668:	d503201f 	nop
ffff00000008266c:	d503201f 	nop
ffff000000082670:	d503201f 	nop
ffff000000082674:	d503201f 	nop
ffff000000082678:	d503201f 	nop
ffff00000008267c:	d503201f 	nop
ffff000000082680:	d503201f 	nop
ffff000000082684:	d503201f 	nop
ffff000000082688:	d503201f 	nop
ffff00000008268c:	d503201f 	nop
ffff000000082690:	d503201f 	nop
ffff000000082694:	d503201f 	nop
ffff000000082698:	d503201f 	nop
ffff00000008269c:	d503201f 	nop
ffff0000000826a0:	d503201f 	nop
ffff0000000826a4:	d503201f 	nop
ffff0000000826a8:	d503201f 	nop
ffff0000000826ac:	d503201f 	nop
ffff0000000826b0:	d503201f 	nop
ffff0000000826b4:	d503201f 	nop
ffff0000000826b8:	d503201f 	nop
ffff0000000826bc:	d503201f 	nop
ffff0000000826c0:	d503201f 	nop
ffff0000000826c4:	d503201f 	nop
ffff0000000826c8:	d503201f 	nop
ffff0000000826cc:	d503201f 	nop
ffff0000000826d0:	d503201f 	nop
ffff0000000826d4:	d503201f 	nop
ffff0000000826d8:	d503201f 	nop
ffff0000000826dc:	d503201f 	nop
ffff0000000826e0:	d503201f 	nop
ffff0000000826e4:	d503201f 	nop
ffff0000000826e8:	d503201f 	nop
ffff0000000826ec:	d503201f 	nop
ffff0000000826f0:	d503201f 	nop
ffff0000000826f4:	d503201f 	nop
ffff0000000826f8:	d503201f 	nop
ffff0000000826fc:	d503201f 	nop
ffff000000082700:	d503201f 	nop
ffff000000082704:	d503201f 	nop
ffff000000082708:	d503201f 	nop
ffff00000008270c:	d503201f 	nop
ffff000000082710:	d503201f 	nop
ffff000000082714:	d503201f 	nop
ffff000000082718:	d503201f 	nop
ffff00000008271c:	d503201f 	nop
ffff000000082720:	d503201f 	nop
ffff000000082724:	d503201f 	nop
ffff000000082728:	d503201f 	nop
ffff00000008272c:	d503201f 	nop
ffff000000082730:	d503201f 	nop
ffff000000082734:	d503201f 	nop
ffff000000082738:	d503201f 	nop
ffff00000008273c:	d503201f 	nop
ffff000000082740:	d503201f 	nop
ffff000000082744:	d503201f 	nop
ffff000000082748:	d503201f 	nop
ffff00000008274c:	d503201f 	nop
ffff000000082750:	d503201f 	nop
ffff000000082754:	d503201f 	nop
ffff000000082758:	d503201f 	nop
ffff00000008275c:	d503201f 	nop
ffff000000082760:	d503201f 	nop
ffff000000082764:	d503201f 	nop
ffff000000082768:	d503201f 	nop
ffff00000008276c:	d503201f 	nop
ffff000000082770:	d503201f 	nop
ffff000000082774:	d503201f 	nop
ffff000000082778:	d503201f 	nop
ffff00000008277c:	d503201f 	nop
ffff000000082780:	d503201f 	nop
ffff000000082784:	d503201f 	nop
ffff000000082788:	d503201f 	nop
ffff00000008278c:	d503201f 	nop
ffff000000082790:	d503201f 	nop
ffff000000082794:	d503201f 	nop
ffff000000082798:	d503201f 	nop
ffff00000008279c:	d503201f 	nop
ffff0000000827a0:	d503201f 	nop
ffff0000000827a4:	d503201f 	nop
ffff0000000827a8:	d503201f 	nop
ffff0000000827ac:	d503201f 	nop
ffff0000000827b0:	d503201f 	nop
ffff0000000827b4:	d503201f 	nop
ffff0000000827b8:	d503201f 	nop
ffff0000000827bc:	d503201f 	nop
ffff0000000827c0:	d503201f 	nop
ffff0000000827c4:	d503201f 	nop
ffff0000000827c8:	d503201f 	nop
ffff0000000827cc:	d503201f 	nop
ffff0000000827d0:	d503201f 	nop
ffff0000000827d4:	d503201f 	nop
ffff0000000827d8:	d503201f 	nop
ffff0000000827dc:	d503201f 	nop
ffff0000000827e0:	d503201f 	nop
ffff0000000827e4:	d503201f 	nop
ffff0000000827e8:	d503201f 	nop
ffff0000000827ec:	d503201f 	nop
ffff0000000827f0:	d503201f 	nop
ffff0000000827f4:	d503201f 	nop
ffff0000000827f8:	d503201f 	nop
ffff0000000827fc:	d503201f 	nop
ffff000000082800:	d503201f 	nop
ffff000000082804:	d503201f 	nop
ffff000000082808:	d503201f 	nop
ffff00000008280c:	d503201f 	nop
ffff000000082810:	d503201f 	nop
ffff000000082814:	d503201f 	nop
ffff000000082818:	d503201f 	nop
ffff00000008281c:	d503201f 	nop
ffff000000082820:	d503201f 	nop
ffff000000082824:	d503201f 	nop
ffff000000082828:	d503201f 	nop
ffff00000008282c:	d503201f 	nop
ffff000000082830:	d503201f 	nop
ffff000000082834:	d503201f 	nop
ffff000000082838:	d503201f 	nop
ffff00000008283c:	d503201f 	nop
ffff000000082840:	d503201f 	nop
ffff000000082844:	d503201f 	nop
ffff000000082848:	d503201f 	nop
ffff00000008284c:	d503201f 	nop
ffff000000082850:	d503201f 	nop
ffff000000082854:	d503201f 	nop
ffff000000082858:	d503201f 	nop
ffff00000008285c:	d503201f 	nop
ffff000000082860:	d503201f 	nop
ffff000000082864:	d503201f 	nop
ffff000000082868:	d503201f 	nop
ffff00000008286c:	d503201f 	nop
ffff000000082870:	d503201f 	nop
ffff000000082874:	d503201f 	nop
ffff000000082878:	d503201f 	nop
ffff00000008287c:	d503201f 	nop
ffff000000082880:	d503201f 	nop
ffff000000082884:	d503201f 	nop
ffff000000082888:	d503201f 	nop
ffff00000008288c:	d503201f 	nop
ffff000000082890:	d503201f 	nop
ffff000000082894:	d503201f 	nop
ffff000000082898:	d503201f 	nop
ffff00000008289c:	d503201f 	nop
ffff0000000828a0:	d503201f 	nop
ffff0000000828a4:	d503201f 	nop
ffff0000000828a8:	d503201f 	nop
ffff0000000828ac:	d503201f 	nop
ffff0000000828b0:	d503201f 	nop
ffff0000000828b4:	d503201f 	nop
ffff0000000828b8:	d503201f 	nop
ffff0000000828bc:	d503201f 	nop
ffff0000000828c0:	d503201f 	nop
ffff0000000828c4:	d503201f 	nop
ffff0000000828c8:	d503201f 	nop
ffff0000000828cc:	d503201f 	nop
ffff0000000828d0:	d503201f 	nop
ffff0000000828d4:	d503201f 	nop
ffff0000000828d8:	d503201f 	nop
ffff0000000828dc:	d503201f 	nop
ffff0000000828e0:	d503201f 	nop
ffff0000000828e4:	d503201f 	nop
ffff0000000828e8:	d503201f 	nop
ffff0000000828ec:	d503201f 	nop
ffff0000000828f0:	d503201f 	nop
ffff0000000828f4:	d503201f 	nop
ffff0000000828f8:	d503201f 	nop
ffff0000000828fc:	d503201f 	nop
ffff000000082900:	d503201f 	nop
ffff000000082904:	d503201f 	nop
ffff000000082908:	d503201f 	nop
ffff00000008290c:	d503201f 	nop
ffff000000082910:	d503201f 	nop
ffff000000082914:	d503201f 	nop
ffff000000082918:	d503201f 	nop
ffff00000008291c:	d503201f 	nop
ffff000000082920:	d503201f 	nop
ffff000000082924:	d503201f 	nop
ffff000000082928:	d503201f 	nop
ffff00000008292c:	d503201f 	nop
ffff000000082930:	d503201f 	nop
ffff000000082934:	d503201f 	nop
ffff000000082938:	d503201f 	nop
ffff00000008293c:	d503201f 	nop
ffff000000082940:	d503201f 	nop
ffff000000082944:	d503201f 	nop
ffff000000082948:	d503201f 	nop
ffff00000008294c:	d503201f 	nop
ffff000000082950:	d503201f 	nop
ffff000000082954:	d503201f 	nop
ffff000000082958:	d503201f 	nop
ffff00000008295c:	d503201f 	nop
ffff000000082960:	d503201f 	nop
ffff000000082964:	d503201f 	nop
ffff000000082968:	d503201f 	nop
ffff00000008296c:	d503201f 	nop
ffff000000082970:	d503201f 	nop
ffff000000082974:	d503201f 	nop
ffff000000082978:	d503201f 	nop
ffff00000008297c:	d503201f 	nop
ffff000000082980:	d503201f 	nop
ffff000000082984:	d503201f 	nop
ffff000000082988:	d503201f 	nop
ffff00000008298c:	d503201f 	nop
ffff000000082990:	d503201f 	nop
ffff000000082994:	d503201f 	nop
ffff000000082998:	d503201f 	nop
ffff00000008299c:	d503201f 	nop
ffff0000000829a0:	d503201f 	nop
ffff0000000829a4:	d503201f 	nop
ffff0000000829a8:	d503201f 	nop
ffff0000000829ac:	d503201f 	nop
ffff0000000829b0:	d503201f 	nop
ffff0000000829b4:	d503201f 	nop
ffff0000000829b8:	d503201f 	nop
ffff0000000829bc:	d503201f 	nop
ffff0000000829c0:	d503201f 	nop
ffff0000000829c4:	d503201f 	nop
ffff0000000829c8:	d503201f 	nop
ffff0000000829cc:	d503201f 	nop
ffff0000000829d0:	d503201f 	nop
ffff0000000829d4:	d503201f 	nop
ffff0000000829d8:	d503201f 	nop
ffff0000000829dc:	d503201f 	nop
ffff0000000829e0:	d503201f 	nop
ffff0000000829e4:	d503201f 	nop
ffff0000000829e8:	d503201f 	nop
ffff0000000829ec:	d503201f 	nop
ffff0000000829f0:	d503201f 	nop
ffff0000000829f4:	d503201f 	nop
ffff0000000829f8:	d503201f 	nop
ffff0000000829fc:	d503201f 	nop
ffff000000082a00:	d503201f 	nop
ffff000000082a04:	d503201f 	nop
ffff000000082a08:	d503201f 	nop
ffff000000082a0c:	d503201f 	nop
ffff000000082a10:	d503201f 	nop
ffff000000082a14:	d503201f 	nop
ffff000000082a18:	d503201f 	nop
ffff000000082a1c:	d503201f 	nop
ffff000000082a20:	d503201f 	nop
ffff000000082a24:	d503201f 	nop
ffff000000082a28:	d503201f 	nop
ffff000000082a2c:	d503201f 	nop
ffff000000082a30:	d503201f 	nop
ffff000000082a34:	d503201f 	nop
ffff000000082a38:	d503201f 	nop
ffff000000082a3c:	d503201f 	nop
ffff000000082a40:	d503201f 	nop
ffff000000082a44:	d503201f 	nop
ffff000000082a48:	d503201f 	nop
ffff000000082a4c:	d503201f 	nop
ffff000000082a50:	d503201f 	nop
ffff000000082a54:	d503201f 	nop
ffff000000082a58:	d503201f 	nop
ffff000000082a5c:	d503201f 	nop
ffff000000082a60:	d503201f 	nop
ffff000000082a64:	d503201f 	nop
ffff000000082a68:	d503201f 	nop
ffff000000082a6c:	d503201f 	nop
ffff000000082a70:	d503201f 	nop
ffff000000082a74:	d503201f 	nop
ffff000000082a78:	d503201f 	nop
ffff000000082a7c:	d503201f 	nop
ffff000000082a80:	d503201f 	nop
ffff000000082a84:	d503201f 	nop
ffff000000082a88:	d503201f 	nop
ffff000000082a8c:	d503201f 	nop
ffff000000082a90:	d503201f 	nop
ffff000000082a94:	d503201f 	nop
ffff000000082a98:	d503201f 	nop
ffff000000082a9c:	d503201f 	nop
ffff000000082aa0:	d503201f 	nop
ffff000000082aa4:	d503201f 	nop
ffff000000082aa8:	d503201f 	nop
ffff000000082aac:	d503201f 	nop
ffff000000082ab0:	d503201f 	nop
ffff000000082ab4:	d503201f 	nop
ffff000000082ab8:	d503201f 	nop
ffff000000082abc:	d503201f 	nop
ffff000000082ac0:	d503201f 	nop
ffff000000082ac4:	d503201f 	nop
ffff000000082ac8:	d503201f 	nop
ffff000000082acc:	d503201f 	nop
ffff000000082ad0:	d503201f 	nop
ffff000000082ad4:	d503201f 	nop
ffff000000082ad8:	d503201f 	nop
ffff000000082adc:	d503201f 	nop
ffff000000082ae0:	d503201f 	nop
ffff000000082ae4:	d503201f 	nop
ffff000000082ae8:	d503201f 	nop
ffff000000082aec:	d503201f 	nop
ffff000000082af0:	d503201f 	nop
ffff000000082af4:	d503201f 	nop
ffff000000082af8:	d503201f 	nop
ffff000000082afc:	d503201f 	nop
ffff000000082b00:	d503201f 	nop
ffff000000082b04:	d503201f 	nop
ffff000000082b08:	d503201f 	nop
ffff000000082b0c:	d503201f 	nop
ffff000000082b10:	d503201f 	nop
ffff000000082b14:	d503201f 	nop
ffff000000082b18:	d503201f 	nop
ffff000000082b1c:	d503201f 	nop
ffff000000082b20:	d503201f 	nop
ffff000000082b24:	d503201f 	nop
ffff000000082b28:	d503201f 	nop
ffff000000082b2c:	d503201f 	nop
ffff000000082b30:	d503201f 	nop
ffff000000082b34:	d503201f 	nop
ffff000000082b38:	d503201f 	nop
ffff000000082b3c:	d503201f 	nop
ffff000000082b40:	d503201f 	nop
ffff000000082b44:	d503201f 	nop
ffff000000082b48:	d503201f 	nop
ffff000000082b4c:	d503201f 	nop
ffff000000082b50:	d503201f 	nop
ffff000000082b54:	d503201f 	nop
ffff000000082b58:	d503201f 	nop
ffff000000082b5c:	d503201f 	nop
ffff000000082b60:	d503201f 	nop
ffff000000082b64:	d503201f 	nop
ffff000000082b68:	d503201f 	nop
ffff000000082b6c:	d503201f 	nop
ffff000000082b70:	d503201f 	nop
ffff000000082b74:	d503201f 	nop
ffff000000082b78:	d503201f 	nop
ffff000000082b7c:	d503201f 	nop
ffff000000082b80:	d503201f 	nop
ffff000000082b84:	d503201f 	nop
ffff000000082b88:	d503201f 	nop
ffff000000082b8c:	d503201f 	nop
ffff000000082b90:	d503201f 	nop
ffff000000082b94:	d503201f 	nop
ffff000000082b98:	d503201f 	nop
ffff000000082b9c:	d503201f 	nop
ffff000000082ba0:	d503201f 	nop
ffff000000082ba4:	d503201f 	nop
ffff000000082ba8:	d503201f 	nop
ffff000000082bac:	d503201f 	nop
ffff000000082bb0:	d503201f 	nop
ffff000000082bb4:	d503201f 	nop
ffff000000082bb8:	d503201f 	nop
ffff000000082bbc:	d503201f 	nop
ffff000000082bc0:	d503201f 	nop
ffff000000082bc4:	d503201f 	nop
ffff000000082bc8:	d503201f 	nop
ffff000000082bcc:	d503201f 	nop
ffff000000082bd0:	d503201f 	nop
ffff000000082bd4:	d503201f 	nop
ffff000000082bd8:	d503201f 	nop
ffff000000082bdc:	d503201f 	nop
ffff000000082be0:	d503201f 	nop
ffff000000082be4:	d503201f 	nop
ffff000000082be8:	d503201f 	nop
ffff000000082bec:	d503201f 	nop
ffff000000082bf0:	d503201f 	nop
ffff000000082bf4:	d503201f 	nop
ffff000000082bf8:	d503201f 	nop
ffff000000082bfc:	d503201f 	nop
ffff000000082c00:	d503201f 	nop
ffff000000082c04:	d503201f 	nop
ffff000000082c08:	d503201f 	nop
ffff000000082c0c:	d503201f 	nop
ffff000000082c10:	d503201f 	nop
ffff000000082c14:	d503201f 	nop
ffff000000082c18:	d503201f 	nop
ffff000000082c1c:	d503201f 	nop
ffff000000082c20:	d503201f 	nop
ffff000000082c24:	d503201f 	nop
ffff000000082c28:	d503201f 	nop
ffff000000082c2c:	d503201f 	nop
ffff000000082c30:	d503201f 	nop
ffff000000082c34:	d503201f 	nop
ffff000000082c38:	d503201f 	nop
ffff000000082c3c:	d503201f 	nop
ffff000000082c40:	d503201f 	nop
ffff000000082c44:	d503201f 	nop
ffff000000082c48:	d503201f 	nop
ffff000000082c4c:	d503201f 	nop
ffff000000082c50:	d503201f 	nop
ffff000000082c54:	d503201f 	nop
ffff000000082c58:	d503201f 	nop
ffff000000082c5c:	d503201f 	nop
ffff000000082c60:	d503201f 	nop
ffff000000082c64:	d503201f 	nop
ffff000000082c68:	d503201f 	nop
ffff000000082c6c:	d503201f 	nop
ffff000000082c70:	d503201f 	nop
ffff000000082c74:	d503201f 	nop
ffff000000082c78:	d503201f 	nop
ffff000000082c7c:	d503201f 	nop
ffff000000082c80:	d503201f 	nop
ffff000000082c84:	d503201f 	nop
ffff000000082c88:	d503201f 	nop
ffff000000082c8c:	d503201f 	nop
ffff000000082c90:	d503201f 	nop
ffff000000082c94:	d503201f 	nop
ffff000000082c98:	d503201f 	nop
ffff000000082c9c:	d503201f 	nop
ffff000000082ca0:	d503201f 	nop
ffff000000082ca4:	d503201f 	nop
ffff000000082ca8:	d503201f 	nop
ffff000000082cac:	d503201f 	nop
ffff000000082cb0:	d503201f 	nop
ffff000000082cb4:	d503201f 	nop
ffff000000082cb8:	d503201f 	nop
ffff000000082cbc:	d503201f 	nop
ffff000000082cc0:	d503201f 	nop
ffff000000082cc4:	d503201f 	nop
ffff000000082cc8:	d503201f 	nop
ffff000000082ccc:	d503201f 	nop
ffff000000082cd0:	d503201f 	nop
ffff000000082cd4:	d503201f 	nop
ffff000000082cd8:	d503201f 	nop
ffff000000082cdc:	d503201f 	nop
ffff000000082ce0:	d503201f 	nop
ffff000000082ce4:	d503201f 	nop
ffff000000082ce8:	d503201f 	nop
ffff000000082cec:	d503201f 	nop
ffff000000082cf0:	d503201f 	nop
ffff000000082cf4:	d503201f 	nop
ffff000000082cf8:	d503201f 	nop
ffff000000082cfc:	d503201f 	nop
ffff000000082d00:	d503201f 	nop
ffff000000082d04:	d503201f 	nop
ffff000000082d08:	d503201f 	nop
ffff000000082d0c:	d503201f 	nop
ffff000000082d10:	d503201f 	nop
ffff000000082d14:	d503201f 	nop
ffff000000082d18:	d503201f 	nop
ffff000000082d1c:	d503201f 	nop
ffff000000082d20:	d503201f 	nop
ffff000000082d24:	d503201f 	nop
ffff000000082d28:	d503201f 	nop
ffff000000082d2c:	d503201f 	nop
ffff000000082d30:	d503201f 	nop
ffff000000082d34:	d503201f 	nop
ffff000000082d38:	d503201f 	nop
ffff000000082d3c:	d503201f 	nop
ffff000000082d40:	d503201f 	nop
ffff000000082d44:	d503201f 	nop
ffff000000082d48:	d503201f 	nop
ffff000000082d4c:	d503201f 	nop
ffff000000082d50:	d503201f 	nop
ffff000000082d54:	d503201f 	nop
ffff000000082d58:	d503201f 	nop
ffff000000082d5c:	d503201f 	nop
ffff000000082d60:	d503201f 	nop
ffff000000082d64:	d503201f 	nop
ffff000000082d68:	d503201f 	nop
ffff000000082d6c:	d503201f 	nop
ffff000000082d70:	d503201f 	nop
ffff000000082d74:	d503201f 	nop
ffff000000082d78:	d503201f 	nop
ffff000000082d7c:	d503201f 	nop
ffff000000082d80:	d503201f 	nop
ffff000000082d84:	d503201f 	nop
ffff000000082d88:	d503201f 	nop
ffff000000082d8c:	d503201f 	nop
ffff000000082d90:	d503201f 	nop
ffff000000082d94:	d503201f 	nop
ffff000000082d98:	d503201f 	nop
ffff000000082d9c:	d503201f 	nop
ffff000000082da0:	d503201f 	nop
ffff000000082da4:	d503201f 	nop
ffff000000082da8:	d503201f 	nop
ffff000000082dac:	d503201f 	nop
ffff000000082db0:	d503201f 	nop
ffff000000082db4:	d503201f 	nop
ffff000000082db8:	d503201f 	nop
ffff000000082dbc:	d503201f 	nop
ffff000000082dc0:	d503201f 	nop
ffff000000082dc4:	d503201f 	nop
ffff000000082dc8:	d503201f 	nop
ffff000000082dcc:	d503201f 	nop
ffff000000082dd0:	d503201f 	nop
ffff000000082dd4:	d503201f 	nop
ffff000000082dd8:	d503201f 	nop
ffff000000082ddc:	d503201f 	nop
ffff000000082de0:	d503201f 	nop
ffff000000082de4:	d503201f 	nop
ffff000000082de8:	d503201f 	nop
ffff000000082dec:	d503201f 	nop
ffff000000082df0:	d503201f 	nop
ffff000000082df4:	d503201f 	nop
ffff000000082df8:	d503201f 	nop
ffff000000082dfc:	d503201f 	nop
ffff000000082e00:	d503201f 	nop
ffff000000082e04:	d503201f 	nop
ffff000000082e08:	d503201f 	nop
ffff000000082e0c:	d503201f 	nop
ffff000000082e10:	d503201f 	nop
ffff000000082e14:	d503201f 	nop
ffff000000082e18:	d503201f 	nop
ffff000000082e1c:	d503201f 	nop
ffff000000082e20:	d503201f 	nop
ffff000000082e24:	d503201f 	nop
ffff000000082e28:	d503201f 	nop
ffff000000082e2c:	d503201f 	nop
ffff000000082e30:	d503201f 	nop
ffff000000082e34:	d503201f 	nop
ffff000000082e38:	d503201f 	nop
ffff000000082e3c:	d503201f 	nop
ffff000000082e40:	d503201f 	nop
ffff000000082e44:	d503201f 	nop
ffff000000082e48:	d503201f 	nop
ffff000000082e4c:	d503201f 	nop
ffff000000082e50:	d503201f 	nop
ffff000000082e54:	d503201f 	nop
ffff000000082e58:	d503201f 	nop
ffff000000082e5c:	d503201f 	nop
ffff000000082e60:	d503201f 	nop
ffff000000082e64:	d503201f 	nop
ffff000000082e68:	d503201f 	nop
ffff000000082e6c:	d503201f 	nop
ffff000000082e70:	d503201f 	nop
ffff000000082e74:	d503201f 	nop
ffff000000082e78:	d503201f 	nop
ffff000000082e7c:	d503201f 	nop
ffff000000082e80:	d503201f 	nop
ffff000000082e84:	d503201f 	nop
ffff000000082e88:	d503201f 	nop
ffff000000082e8c:	d503201f 	nop
ffff000000082e90:	d503201f 	nop
ffff000000082e94:	d503201f 	nop
ffff000000082e98:	d503201f 	nop
ffff000000082e9c:	d503201f 	nop
ffff000000082ea0:	d503201f 	nop
ffff000000082ea4:	d503201f 	nop
ffff000000082ea8:	d503201f 	nop
ffff000000082eac:	d503201f 	nop
ffff000000082eb0:	d503201f 	nop
ffff000000082eb4:	d503201f 	nop
ffff000000082eb8:	d503201f 	nop
ffff000000082ebc:	d503201f 	nop
ffff000000082ec0:	d503201f 	nop
ffff000000082ec4:	d503201f 	nop
ffff000000082ec8:	d503201f 	nop
ffff000000082ecc:	d503201f 	nop
ffff000000082ed0:	d503201f 	nop
ffff000000082ed4:	d503201f 	nop
ffff000000082ed8:	d503201f 	nop
ffff000000082edc:	d503201f 	nop
ffff000000082ee0:	d503201f 	nop
ffff000000082ee4:	d503201f 	nop
ffff000000082ee8:	d503201f 	nop
ffff000000082eec:	d503201f 	nop
ffff000000082ef0:	d503201f 	nop
ffff000000082ef4:	d503201f 	nop
ffff000000082ef8:	d503201f 	nop
ffff000000082efc:	d503201f 	nop
ffff000000082f00:	d503201f 	nop
ffff000000082f04:	d503201f 	nop
ffff000000082f08:	d503201f 	nop
ffff000000082f0c:	d503201f 	nop
ffff000000082f10:	d503201f 	nop
ffff000000082f14:	d503201f 	nop
ffff000000082f18:	d503201f 	nop
ffff000000082f1c:	d503201f 	nop
ffff000000082f20:	d503201f 	nop
ffff000000082f24:	d503201f 	nop
ffff000000082f28:	d503201f 	nop
ffff000000082f2c:	d503201f 	nop
ffff000000082f30:	d503201f 	nop
ffff000000082f34:	d503201f 	nop
ffff000000082f38:	d503201f 	nop
ffff000000082f3c:	d503201f 	nop
ffff000000082f40:	d503201f 	nop
ffff000000082f44:	d503201f 	nop
ffff000000082f48:	d503201f 	nop
ffff000000082f4c:	d503201f 	nop
ffff000000082f50:	d503201f 	nop
ffff000000082f54:	d503201f 	nop
ffff000000082f58:	d503201f 	nop
ffff000000082f5c:	d503201f 	nop
ffff000000082f60:	d503201f 	nop
ffff000000082f64:	d503201f 	nop
ffff000000082f68:	d503201f 	nop
ffff000000082f6c:	d503201f 	nop
ffff000000082f70:	d503201f 	nop
ffff000000082f74:	d503201f 	nop
ffff000000082f78:	d503201f 	nop
ffff000000082f7c:	d503201f 	nop
ffff000000082f80:	d503201f 	nop
ffff000000082f84:	d503201f 	nop
ffff000000082f88:	d503201f 	nop
ffff000000082f8c:	d503201f 	nop
ffff000000082f90:	d503201f 	nop
ffff000000082f94:	d503201f 	nop
ffff000000082f98:	d503201f 	nop
ffff000000082f9c:	d503201f 	nop
ffff000000082fa0:	d503201f 	nop
ffff000000082fa4:	d503201f 	nop
ffff000000082fa8:	d503201f 	nop
ffff000000082fac:	d503201f 	nop
ffff000000082fb0:	d503201f 	nop
ffff000000082fb4:	d503201f 	nop
ffff000000082fb8:	d503201f 	nop
ffff000000082fbc:	d503201f 	nop
ffff000000082fc0:	d503201f 	nop
ffff000000082fc4:	d503201f 	nop
ffff000000082fc8:	d503201f 	nop
ffff000000082fcc:	d503201f 	nop
ffff000000082fd0:	d503201f 	nop
ffff000000082fd4:	d503201f 	nop
ffff000000082fd8:	d503201f 	nop
ffff000000082fdc:	d503201f 	nop
ffff000000082fe0:	d503201f 	nop
ffff000000082fe4:	d503201f 	nop
ffff000000082fe8:	d503201f 	nop
ffff000000082fec:	d503201f 	nop
ffff000000082ff0:	d503201f 	nop
ffff000000082ff4:	d503201f 	nop
ffff000000082ff8:	d503201f 	nop
ffff000000082ffc:	d503201f 	nop

ffff000000083000 <pgd_ttbr1>:
	...

ffff000000084000 <pud_ttbr1>:
	...

ffff000000085000 <pmd_ttbr1>:
	...

ffff000000086000 <pmd2_ttbr1>:
	...

ffff000000087000 <pgd_ttbr0>:
	...

ffff000000088000 <pud_ttbr0>:
	...

ffff000000089000 <pmd_ttbr0>:
	...
ffff00000008a000:	00004400 	.word	0x00004400
ffff00000008a004:	00000000 	.word	0x00000000
ffff00000008a008:	80100010 	.word	0x80100010
ffff00000008a00c:	00000000 	.word	0x00000000

ffff00000008a010 <free_region>:
extern char end;
void load_pgd(uint64_t map);


static void free_region(uint64_t v, uint64_t e)
{
ffff00000008a010:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008a014:	910003fd 	mov	x29, sp
ffff00000008a018:	f9000fe0 	str	x0, [sp, #24]
ffff00000008a01c:	f9000be1 	str	x1, [sp, #16]
    for (uint64_t start = PA_UP(v); start + PAGE_SIZE <= e; start += PAGE_SIZE) {
ffff00000008a020:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008a024:	b24053e0 	mov	x0, #0x1fffff              	// #2097151
ffff00000008a028:	8b000020 	add	x0, x1, x0
ffff00000008a02c:	926ba800 	and	x0, x0, #0xffffffffffe00000
ffff00000008a030:	f90017e0 	str	x0, [sp, #40]
ffff00000008a034:	1400000c 	b	ffff00000008a064 <free_region+0x54>
        if (start + PAGE_SIZE <= MEMORY_END) {
ffff00000008a038:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008a03c:	91480001 	add	x1, x0, #0x200, lsl #12
ffff00000008a040:	d2a60000 	mov	x0, #0x30000000            	// #805306368
ffff00000008a044:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff00000008a048:	eb00003f 	cmp	x1, x0
ffff00000008a04c:	54000068 	b.hi	ffff00000008a058 <free_region+0x48>  // b.pmore
            kfree(start);
ffff00000008a050:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008a054:	9400000d 	bl	ffff00000008a088 <kfree>
    for (uint64_t start = PA_UP(v); start + PAGE_SIZE <= e; start += PAGE_SIZE) {
ffff00000008a058:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008a05c:	91480000 	add	x0, x0, #0x200, lsl #12
ffff00000008a060:	f90017e0 	str	x0, [sp, #40]
ffff00000008a064:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008a068:	91480000 	add	x0, x0, #0x200, lsl #12
ffff00000008a06c:	f9400be1 	ldr	x1, [sp, #16]
ffff00000008a070:	eb00003f 	cmp	x1, x0
ffff00000008a074:	54fffe22 	b.cs	ffff00000008a038 <free_region+0x28>  // b.hs, b.nlast
        }
    }
}
ffff00000008a078:	d503201f 	nop
ffff00000008a07c:	d503201f 	nop
ffff00000008a080:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff00000008a084:	d65f03c0 	ret

ffff00000008a088 <kfree>:

void kfree(uint64_t v)
{
ffff00000008a088:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008a08c:	910003fd 	mov	x29, sp
ffff00000008a090:	f9000fe0 	str	x0, [sp, #24]
    ASSERT(v % PAGE_SIZE == 0);
ffff00000008a094:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a098:	92405000 	and	x0, x0, #0x1fffff
ffff00000008a09c:	f100001f 	cmp	x0, #0x0
ffff00000008a0a0:	540000a0 	b.eq	ffff00000008a0b4 <kfree+0x2c>  // b.none
ffff00000008a0a4:	d2800421 	mov	x1, #0x21                  	// #33
ffff00000008a0a8:	d0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008a0ac:	91052000 	add	x0, x0, #0x148
ffff00000008a0b0:	97ffdad5 	bl	ffff000000080c04 <error_check>
    ASSERT(v >= (uint64_t)&end);
ffff00000008a0b4:	f0000000 	adrp	x0, ffff00000008d000 <_binary_user_bin_start+0x200>
ffff00000008a0b8:	f946e800 	ldr	x0, [x0, #3536]
ffff00000008a0bc:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008a0c0:	eb00003f 	cmp	x1, x0
ffff00000008a0c4:	540000a2 	b.cs	ffff00000008a0d8 <kfree+0x50>  // b.hs, b.nlast
ffff00000008a0c8:	d2800441 	mov	x1, #0x22                  	// #34
ffff00000008a0cc:	d0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008a0d0:	91052000 	add	x0, x0, #0x148
ffff00000008a0d4:	97ffdacc 	bl	ffff000000080c04 <error_check>
    ASSERT(v + PAGE_SIZE <= MEMORY_END);
ffff00000008a0d8:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a0dc:	91480001 	add	x1, x0, #0x200, lsl #12
ffff00000008a0e0:	d2a60000 	mov	x0, #0x30000000            	// #805306368
ffff00000008a0e4:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff00000008a0e8:	eb00003f 	cmp	x1, x0
ffff00000008a0ec:	540000a9 	b.ls	ffff00000008a100 <kfree+0x78>  // b.plast
ffff00000008a0f0:	d2800461 	mov	x1, #0x23                  	// #35
ffff00000008a0f4:	d0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008a0f8:	91052000 	add	x0, x0, #0x148
ffff00000008a0fc:	97ffdac2 	bl	ffff000000080c04 <error_check>

    struct Page *page_address = (struct Page*)v;
ffff00000008a100:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a104:	f90017e0 	str	x0, [sp, #40]
    page_address->next = free_memory.next;
ffff00000008a108:	f0000000 	adrp	x0, ffff00000008d000 <_binary_user_bin_start+0x200>
ffff00000008a10c:	91388000 	add	x0, x0, #0xe20
ffff00000008a110:	f9400001 	ldr	x1, [x0]
ffff00000008a114:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008a118:	f9000001 	str	x1, [x0]
    free_memory.next = page_address;
ffff00000008a11c:	f0000000 	adrp	x0, ffff00000008d000 <_binary_user_bin_start+0x200>
ffff00000008a120:	91388000 	add	x0, x0, #0xe20
ffff00000008a124:	f94017e1 	ldr	x1, [sp, #40]
ffff00000008a128:	f9000001 	str	x1, [x0]
}
ffff00000008a12c:	d503201f 	nop
ffff00000008a130:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff00000008a134:	d65f03c0 	ret

ffff00000008a138 <kalloc>:

void* kalloc(void)
{
ffff00000008a138:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008a13c:	910003fd 	mov	x29, sp
    struct Page *page_address = free_memory.next;
ffff00000008a140:	f0000000 	adrp	x0, ffff00000008d000 <_binary_user_bin_start+0x200>
ffff00000008a144:	91388000 	add	x0, x0, #0xe20
ffff00000008a148:	f9400000 	ldr	x0, [x0]
ffff00000008a14c:	f9000fe0 	str	x0, [sp, #24]

    if (page_address != NULL) {
ffff00000008a150:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a154:	f100001f 	cmp	x0, #0x0
ffff00000008a158:	54000420 	b.eq	ffff00000008a1dc <kalloc+0xa4>  // b.none
        ASSERT((uint64_t)page_address % PAGE_SIZE == 0);
ffff00000008a15c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a160:	92405000 	and	x0, x0, #0x1fffff
ffff00000008a164:	f100001f 	cmp	x0, #0x0
ffff00000008a168:	540000a0 	b.eq	ffff00000008a17c <kalloc+0x44>  // b.none
ffff00000008a16c:	d28005e1 	mov	x1, #0x2f                  	// #47
ffff00000008a170:	d0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008a174:	91052000 	add	x0, x0, #0x148
ffff00000008a178:	97ffdaa3 	bl	ffff000000080c04 <error_check>
        ASSERT((uint64_t)page_address >= (uint64_t)&end);
ffff00000008a17c:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008a180:	f0000000 	adrp	x0, ffff00000008d000 <_binary_user_bin_start+0x200>
ffff00000008a184:	f946e800 	ldr	x0, [x0, #3536]
ffff00000008a188:	eb00003f 	cmp	x1, x0
ffff00000008a18c:	540000a2 	b.cs	ffff00000008a1a0 <kalloc+0x68>  // b.hs, b.nlast
ffff00000008a190:	d2800601 	mov	x1, #0x30                  	// #48
ffff00000008a194:	d0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008a198:	91052000 	add	x0, x0, #0x148
ffff00000008a19c:	97ffda9a 	bl	ffff000000080c04 <error_check>
        ASSERT((uint64_t)page_address + PAGE_SIZE <= MEMORY_END);
ffff00000008a1a0:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a1a4:	91480001 	add	x1, x0, #0x200, lsl #12
ffff00000008a1a8:	d2a60000 	mov	x0, #0x30000000            	// #805306368
ffff00000008a1ac:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff00000008a1b0:	eb00003f 	cmp	x1, x0
ffff00000008a1b4:	540000a9 	b.ls	ffff00000008a1c8 <kalloc+0x90>  // b.plast
ffff00000008a1b8:	d2800621 	mov	x1, #0x31                  	// #49
ffff00000008a1bc:	d0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008a1c0:	91052000 	add	x0, x0, #0x148
ffff00000008a1c4:	97ffda90 	bl	ffff000000080c04 <error_check>
        
        free_memory.next = page_address->next;
ffff00000008a1c8:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a1cc:	f9400001 	ldr	x1, [x0]
ffff00000008a1d0:	f0000000 	adrp	x0, ffff00000008d000 <_binary_user_bin_start+0x200>
ffff00000008a1d4:	91388000 	add	x0, x0, #0xe20
ffff00000008a1d8:	f9000001 	str	x1, [x0]
    }

    return page_address;
ffff00000008a1dc:	f9400fe0 	ldr	x0, [sp, #24]
}
ffff00000008a1e0:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008a1e4:	d65f03c0 	ret

ffff00000008a1e8 <checkmm>:

void checkmm(void)
{
ffff00000008a1e8:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008a1ec:	910003fd 	mov	x29, sp
    struct Page *v = free_memory.next;
ffff00000008a1f0:	f0000000 	adrp	x0, ffff00000008d000 <_binary_user_bin_start+0x200>
ffff00000008a1f4:	91388000 	add	x0, x0, #0xe20
ffff00000008a1f8:	f9400000 	ldr	x0, [x0]
ffff00000008a1fc:	f90017e0 	str	x0, [sp, #40]
    uint64_t size = 0;
ffff00000008a200:	f90013ff 	str	xzr, [sp, #32]
    uint64_t i = 0;
ffff00000008a204:	f9000fff 	str	xzr, [sp, #24]

    while (v != NULL) {
ffff00000008a208:	1400000f 	b	ffff00000008a244 <checkmm+0x5c>
        size += PAGE_SIZE;
ffff00000008a20c:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008a210:	91480000 	add	x0, x0, #0x200, lsl #12
ffff00000008a214:	f90013e0 	str	x0, [sp, #32]
        printk("%d base is %x \r\n", i++, v);
ffff00000008a218:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a21c:	91000401 	add	x1, x0, #0x1
ffff00000008a220:	f9000fe1 	str	x1, [sp, #24]
ffff00000008a224:	f94017e2 	ldr	x2, [sp, #40]
ffff00000008a228:	aa0003e1 	mov	x1, x0
ffff00000008a22c:	d0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008a230:	91056000 	add	x0, x0, #0x158
ffff00000008a234:	97ffd99e 	bl	ffff0000000808ac <printk>
        v = v->next;
ffff00000008a238:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008a23c:	f9400000 	ldr	x0, [x0]
ffff00000008a240:	f90017e0 	str	x0, [sp, #40]
    while (v != NULL) {
ffff00000008a244:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008a248:	f100001f 	cmp	x0, #0x0
ffff00000008a24c:	54fffe01 	b.ne	ffff00000008a20c <checkmm+0x24>  // b.any
    }

    printk("memory size is %u \r\n", size/1024/1024);
ffff00000008a250:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008a254:	d354fc00 	lsr	x0, x0, #20
ffff00000008a258:	aa0003e1 	mov	x1, x0
ffff00000008a25c:	d0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008a260:	9105c000 	add	x0, x0, #0x170
ffff00000008a264:	97ffd992 	bl	ffff0000000808ac <printk>
}
ffff00000008a268:	d503201f 	nop
ffff00000008a26c:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff00000008a270:	d65f03c0 	ret

ffff00000008a274 <find_pgd_entry>:

static uint64_t* find_pgd_entry(uint64_t map, uint64_t v, int alloc, uint64_t attribute)
{
ffff00000008a274:	a9bb7bfd 	stp	x29, x30, [sp, #-80]!
ffff00000008a278:	910003fd 	mov	x29, sp
ffff00000008a27c:	f90017e0 	str	x0, [sp, #40]
ffff00000008a280:	f90013e1 	str	x1, [sp, #32]
ffff00000008a284:	b9001fe2 	str	w2, [sp, #28]
ffff00000008a288:	f9000be3 	str	x3, [sp, #16]
    uint64_t *ptr = (uint64_t*)map;
ffff00000008a28c:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008a290:	f90023e0 	str	x0, [sp, #64]
    void *addr = NULL;
ffff00000008a294:	f90027ff 	str	xzr, [sp, #72]
    unsigned int index = (v >> 39) & 0x1ff;
ffff00000008a298:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008a29c:	d367fc00 	lsr	x0, x0, #39
ffff00000008a2a0:	12002000 	and	w0, w0, #0x1ff
ffff00000008a2a4:	b9003fe0 	str	w0, [sp, #60]

    if (ptr[index] & ENTRY_V) {
ffff00000008a2a8:	b9403fe0 	ldr	w0, [sp, #60]
ffff00000008a2ac:	d37df000 	lsl	x0, x0, #3
ffff00000008a2b0:	f94023e1 	ldr	x1, [sp, #64]
ffff00000008a2b4:	8b000020 	add	x0, x1, x0
ffff00000008a2b8:	f9400000 	ldr	x0, [x0]
ffff00000008a2bc:	92400000 	and	x0, x0, #0x1
ffff00000008a2c0:	f100001f 	cmp	x0, #0x0
ffff00000008a2c4:	54000160 	b.eq	ffff00000008a2f0 <find_pgd_entry+0x7c>  // b.none
        addr = (void*)P2V(PDE_ADDR(ptr[index]));
ffff00000008a2c8:	b9403fe0 	ldr	w0, [sp, #60]
ffff00000008a2cc:	d37df000 	lsl	x0, x0, #3
ffff00000008a2d0:	f94023e1 	ldr	x1, [sp, #64]
ffff00000008a2d4:	8b000020 	add	x0, x1, x0
ffff00000008a2d8:	f9400000 	ldr	x0, [x0]
ffff00000008a2dc:	92748c01 	and	x1, x0, #0xfffffffff000
ffff00000008a2e0:	d2ffffe0 	mov	x0, #0xffff000000000000    	// #-281474976710656
ffff00000008a2e4:	8b000020 	add	x0, x1, x0
ffff00000008a2e8:	f90027e0 	str	x0, [sp, #72]
ffff00000008a2ec:	14000018 	b	ffff00000008a34c <find_pgd_entry+0xd8>
    }
    else if (alloc == 1) {
ffff00000008a2f0:	b9401fe0 	ldr	w0, [sp, #28]
ffff00000008a2f4:	7100041f 	cmp	w0, #0x1
ffff00000008a2f8:	540002a1 	b.ne	ffff00000008a34c <find_pgd_entry+0xd8>  // b.any
        addr = kalloc();
ffff00000008a2fc:	97ffff8f 	bl	ffff00000008a138 <kalloc>
ffff00000008a300:	f90027e0 	str	x0, [sp, #72]
        if (addr != NULL) {
ffff00000008a304:	f94027e0 	ldr	x0, [sp, #72]
ffff00000008a308:	f100001f 	cmp	x0, #0x0
ffff00000008a30c:	54000200 	b.eq	ffff00000008a34c <find_pgd_entry+0xd8>  // b.none
            memset(addr, 0, PAGE_SIZE);
ffff00000008a310:	52a00402 	mov	w2, #0x200000              	// #2097152
ffff00000008a314:	52800001 	mov	w1, #0x0                   	// #0
ffff00000008a318:	f94027e0 	ldr	x0, [sp, #72]
ffff00000008a31c:	97ffd78e 	bl	ffff000000080154 <memset>
            ptr[index] = (V2P(addr) | attribute | TABLE_ENTRY);
ffff00000008a320:	f94027e1 	ldr	x1, [sp, #72]
ffff00000008a324:	d2e00020 	mov	x0, #0x1000000000000       	// #281474976710656
ffff00000008a328:	8b000021 	add	x1, x1, x0
ffff00000008a32c:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008a330:	aa000021 	orr	x1, x1, x0
ffff00000008a334:	b9403fe0 	ldr	w0, [sp, #60]
ffff00000008a338:	d37df000 	lsl	x0, x0, #3
ffff00000008a33c:	f94023e2 	ldr	x2, [sp, #64]
ffff00000008a340:	8b000040 	add	x0, x2, x0
ffff00000008a344:	b27f0021 	orr	x1, x1, #0x2
ffff00000008a348:	f9000001 	str	x1, [x0]
        }
    }

    return addr;
ffff00000008a34c:	f94027e0 	ldr	x0, [sp, #72]
}
ffff00000008a350:	a8c57bfd 	ldp	x29, x30, [sp], #80
ffff00000008a354:	d65f03c0 	ret

ffff00000008a358 <find_pud_entry>:

static uint64_t* find_pud_entry(uint64_t map, uint64_t v, int alloc, uint64_t attribute)
{
ffff00000008a358:	a9bb7bfd 	stp	x29, x30, [sp, #-80]!
ffff00000008a35c:	910003fd 	mov	x29, sp
ffff00000008a360:	f90017e0 	str	x0, [sp, #40]
ffff00000008a364:	f90013e1 	str	x1, [sp, #32]
ffff00000008a368:	b9001fe2 	str	w2, [sp, #28]
ffff00000008a36c:	f9000be3 	str	x3, [sp, #16]
    uint64_t *ptr = NULL;
ffff00000008a370:	f90023ff 	str	xzr, [sp, #64]
    void *addr = NULL;
ffff00000008a374:	f90027ff 	str	xzr, [sp, #72]
    unsigned int index = (v >> 30) & 0x1ff;
ffff00000008a378:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008a37c:	d35efc00 	lsr	x0, x0, #30
ffff00000008a380:	12002000 	and	w0, w0, #0x1ff
ffff00000008a384:	b9003fe0 	str	w0, [sp, #60]

    ptr = find_pgd_entry(map, v, alloc, attribute);
ffff00000008a388:	f9400be3 	ldr	x3, [sp, #16]
ffff00000008a38c:	b9401fe2 	ldr	w2, [sp, #28]
ffff00000008a390:	f94013e1 	ldr	x1, [sp, #32]
ffff00000008a394:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008a398:	97ffffb7 	bl	ffff00000008a274 <find_pgd_entry>
ffff00000008a39c:	f90023e0 	str	x0, [sp, #64]
    if (ptr == NULL) {
ffff00000008a3a0:	f94023e0 	ldr	x0, [sp, #64]
ffff00000008a3a4:	f100001f 	cmp	x0, #0x0
ffff00000008a3a8:	54000061 	b.ne	ffff00000008a3b4 <find_pud_entry+0x5c>  // b.any
        return NULL;
ffff00000008a3ac:	d2800000 	mov	x0, #0x0                   	// #0
ffff00000008a3b0:	1400002b 	b	ffff00000008a45c <find_pud_entry+0x104>
    }

    if (ptr[index] & ENTRY_V) {
ffff00000008a3b4:	b9403fe0 	ldr	w0, [sp, #60]
ffff00000008a3b8:	d37df000 	lsl	x0, x0, #3
ffff00000008a3bc:	f94023e1 	ldr	x1, [sp, #64]
ffff00000008a3c0:	8b000020 	add	x0, x1, x0
ffff00000008a3c4:	f9400000 	ldr	x0, [x0]
ffff00000008a3c8:	92400000 	and	x0, x0, #0x1
ffff00000008a3cc:	f100001f 	cmp	x0, #0x0
ffff00000008a3d0:	54000160 	b.eq	ffff00000008a3fc <find_pud_entry+0xa4>  // b.none
        addr = (void*)P2V(PDE_ADDR(ptr[index]));
ffff00000008a3d4:	b9403fe0 	ldr	w0, [sp, #60]
ffff00000008a3d8:	d37df000 	lsl	x0, x0, #3
ffff00000008a3dc:	f94023e1 	ldr	x1, [sp, #64]
ffff00000008a3e0:	8b000020 	add	x0, x1, x0
ffff00000008a3e4:	f9400000 	ldr	x0, [x0]
ffff00000008a3e8:	92748c01 	and	x1, x0, #0xfffffffff000
ffff00000008a3ec:	d2ffffe0 	mov	x0, #0xffff000000000000    	// #-281474976710656
ffff00000008a3f0:	8b000020 	add	x0, x1, x0
ffff00000008a3f4:	f90027e0 	str	x0, [sp, #72]
ffff00000008a3f8:	14000018 	b	ffff00000008a458 <find_pud_entry+0x100>
    }
    else if (alloc == 1) {
ffff00000008a3fc:	b9401fe0 	ldr	w0, [sp, #28]
ffff00000008a400:	7100041f 	cmp	w0, #0x1
ffff00000008a404:	540002a1 	b.ne	ffff00000008a458 <find_pud_entry+0x100>  // b.any
        addr = kalloc();
ffff00000008a408:	97ffff4c 	bl	ffff00000008a138 <kalloc>
ffff00000008a40c:	f90027e0 	str	x0, [sp, #72]
        if (addr != NULL) {
ffff00000008a410:	f94027e0 	ldr	x0, [sp, #72]
ffff00000008a414:	f100001f 	cmp	x0, #0x0
ffff00000008a418:	54000200 	b.eq	ffff00000008a458 <find_pud_entry+0x100>  // b.none
            memset(addr, 0, PAGE_SIZE);
ffff00000008a41c:	52a00402 	mov	w2, #0x200000              	// #2097152
ffff00000008a420:	52800001 	mov	w1, #0x0                   	// #0
ffff00000008a424:	f94027e0 	ldr	x0, [sp, #72]
ffff00000008a428:	97ffd74b 	bl	ffff000000080154 <memset>
            ptr[index] = (V2P(addr) | attribute | TABLE_ENTRY);
ffff00000008a42c:	f94027e1 	ldr	x1, [sp, #72]
ffff00000008a430:	d2e00020 	mov	x0, #0x1000000000000       	// #281474976710656
ffff00000008a434:	8b000021 	add	x1, x1, x0
ffff00000008a438:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008a43c:	aa000021 	orr	x1, x1, x0
ffff00000008a440:	b9403fe0 	ldr	w0, [sp, #60]
ffff00000008a444:	d37df000 	lsl	x0, x0, #3
ffff00000008a448:	f94023e2 	ldr	x2, [sp, #64]
ffff00000008a44c:	8b000040 	add	x0, x2, x0
ffff00000008a450:	b27f0021 	orr	x1, x1, #0x2
ffff00000008a454:	f9000001 	str	x1, [x0]
        }
    }

    return addr;
ffff00000008a458:	f94027e0 	ldr	x0, [sp, #72]
}
ffff00000008a45c:	a8c57bfd 	ldp	x29, x30, [sp], #80
ffff00000008a460:	d65f03c0 	ret

ffff00000008a464 <map_page>:

bool map_page(uint64_t map, uint64_t v, uint64_t pa, uint64_t attribute)
{
ffff00000008a464:	a9bb7bfd 	stp	x29, x30, [sp, #-80]!
ffff00000008a468:	910003fd 	mov	x29, sp
ffff00000008a46c:	f90017e0 	str	x0, [sp, #40]
ffff00000008a470:	f90013e1 	str	x1, [sp, #32]
ffff00000008a474:	f9000fe2 	str	x2, [sp, #24]
ffff00000008a478:	f9000be3 	str	x3, [sp, #16]
    uint64_t vstart = PA_DOWN(v);
ffff00000008a47c:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008a480:	926ba800 	and	x0, x0, #0xffffffffffe00000
ffff00000008a484:	f90027e0 	str	x0, [sp, #72]
    uint64_t *ptr = NULL;
ffff00000008a488:	f90023ff 	str	xzr, [sp, #64]

    ASSERT(vstart + PAGE_SIZE < MEMORY_END);
ffff00000008a48c:	f94027e0 	ldr	x0, [sp, #72]
ffff00000008a490:	91480001 	add	x1, x0, #0x200, lsl #12
ffff00000008a494:	12ba0000 	mov	w0, #0x2fffffff            	// #805306367
ffff00000008a498:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff00000008a49c:	eb00003f 	cmp	x1, x0
ffff00000008a4a0:	540000a9 	b.ls	ffff00000008a4b4 <map_page+0x50>  // b.plast
ffff00000008a4a4:	d2800f41 	mov	x1, #0x7a                  	// #122
ffff00000008a4a8:	d0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008a4ac:	91052000 	add	x0, x0, #0x148
ffff00000008a4b0:	97ffd9d5 	bl	ffff000000080c04 <error_check>
    ASSERT(pa % PAGE_SIZE == 0);
ffff00000008a4b4:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a4b8:	92405000 	and	x0, x0, #0x1fffff
ffff00000008a4bc:	f100001f 	cmp	x0, #0x0
ffff00000008a4c0:	540000a0 	b.eq	ffff00000008a4d4 <map_page+0x70>  // b.none
ffff00000008a4c4:	d2800f61 	mov	x1, #0x7b                  	// #123
ffff00000008a4c8:	d0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008a4cc:	91052000 	add	x0, x0, #0x148
ffff00000008a4d0:	97ffd9cd 	bl	ffff000000080c04 <error_check>
    ASSERT(pa + PAGE_SIZE <= V2P(MEMORY_END));
ffff00000008a4d4:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a4d8:	91480001 	add	x1, x0, #0x200, lsl #12
ffff00000008a4dc:	d2a60000 	mov	x0, #0x30000000            	// #805306368
ffff00000008a4e0:	eb00003f 	cmp	x1, x0
ffff00000008a4e4:	540000a9 	b.ls	ffff00000008a4f8 <map_page+0x94>  // b.plast
ffff00000008a4e8:	d2800f81 	mov	x1, #0x7c                  	// #124
ffff00000008a4ec:	d0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008a4f0:	91052000 	add	x0, x0, #0x148
ffff00000008a4f4:	97ffd9c4 	bl	ffff000000080c04 <error_check>

    ptr = find_pud_entry(map, vstart, 1, attribute);
ffff00000008a4f8:	f9400be3 	ldr	x3, [sp, #16]
ffff00000008a4fc:	52800022 	mov	w2, #0x1                   	// #1
ffff00000008a500:	f94027e1 	ldr	x1, [sp, #72]
ffff00000008a504:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008a508:	97ffff94 	bl	ffff00000008a358 <find_pud_entry>
ffff00000008a50c:	f90023e0 	str	x0, [sp, #64]
    if (ptr == NULL) {
ffff00000008a510:	f94023e0 	ldr	x0, [sp, #64]
ffff00000008a514:	f100001f 	cmp	x0, #0x0
ffff00000008a518:	54000061 	b.ne	ffff00000008a524 <map_page+0xc0>  // b.any
        return false;
ffff00000008a51c:	52800000 	mov	w0, #0x0                   	// #0
ffff00000008a520:	1400001a 	b	ffff00000008a588 <map_page+0x124>
    }

    unsigned int index = (vstart >> 21) & 0x1ff;
ffff00000008a524:	f94027e0 	ldr	x0, [sp, #72]
ffff00000008a528:	d355fc00 	lsr	x0, x0, #21
ffff00000008a52c:	12002000 	and	w0, w0, #0x1ff
ffff00000008a530:	b9003fe0 	str	w0, [sp, #60]
    ASSERT((ptr[index] & ENTRY_V) == 0);
ffff00000008a534:	b9403fe0 	ldr	w0, [sp, #60]
ffff00000008a538:	d37df000 	lsl	x0, x0, #3
ffff00000008a53c:	f94023e1 	ldr	x1, [sp, #64]
ffff00000008a540:	8b000020 	add	x0, x1, x0
ffff00000008a544:	f9400000 	ldr	x0, [x0]
ffff00000008a548:	92400000 	and	x0, x0, #0x1
ffff00000008a54c:	f100001f 	cmp	x0, #0x0
ffff00000008a550:	540000a0 	b.eq	ffff00000008a564 <map_page+0x100>  // b.none
ffff00000008a554:	d2801081 	mov	x1, #0x84                  	// #132
ffff00000008a558:	d0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008a55c:	91052000 	add	x0, x0, #0x148
ffff00000008a560:	97ffd9a9 	bl	ffff000000080c04 <error_check>

    ptr[index] = (pa | attribute | BLOCK_ENTRY);
ffff00000008a564:	b9403fe0 	ldr	w0, [sp, #60]
ffff00000008a568:	d37df000 	lsl	x0, x0, #3
ffff00000008a56c:	f94023e1 	ldr	x1, [sp, #64]
ffff00000008a570:	8b000020 	add	x0, x1, x0
ffff00000008a574:	f9400fe2 	ldr	x2, [sp, #24]
ffff00000008a578:	f9400be1 	ldr	x1, [sp, #16]
ffff00000008a57c:	aa010041 	orr	x1, x2, x1
ffff00000008a580:	f9000001 	str	x1, [x0]

    return true;
ffff00000008a584:	52800020 	mov	w0, #0x1                   	// #1
}
ffff00000008a588:	a8c57bfd 	ldp	x29, x30, [sp], #80
ffff00000008a58c:	d65f03c0 	ret

ffff00000008a590 <free_page>:

void free_page(uint64_t map, uint64_t vstart)
{
ffff00000008a590:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008a594:	910003fd 	mov	x29, sp
ffff00000008a598:	f9000fe0 	str	x0, [sp, #24]
ffff00000008a59c:	f9000be1 	str	x1, [sp, #16]
    unsigned int index;
    uint64_t *ptr = NULL;
ffff00000008a5a0:	f90017ff 	str	xzr, [sp, #40]

    ASSERT(vstart % PAGE_SIZE == 0);
ffff00000008a5a4:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008a5a8:	92405000 	and	x0, x0, #0x1fffff
ffff00000008a5ac:	f100001f 	cmp	x0, #0x0
ffff00000008a5b0:	540000a0 	b.eq	ffff00000008a5c4 <free_page+0x34>  // b.none
ffff00000008a5b4:	d2801201 	mov	x1, #0x90                  	// #144
ffff00000008a5b8:	d0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008a5bc:	91052000 	add	x0, x0, #0x148
ffff00000008a5c0:	97ffd991 	bl	ffff000000080c04 <error_check>

    ptr = find_pud_entry(map, vstart, 0, 0);
ffff00000008a5c4:	d2800003 	mov	x3, #0x0                   	// #0
ffff00000008a5c8:	52800002 	mov	w2, #0x0                   	// #0
ffff00000008a5cc:	f9400be1 	ldr	x1, [sp, #16]
ffff00000008a5d0:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a5d4:	97ffff61 	bl	ffff00000008a358 <find_pud_entry>
ffff00000008a5d8:	f90017e0 	str	x0, [sp, #40]

    if (ptr != NULL) {
ffff00000008a5dc:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008a5e0:	f100001f 	cmp	x0, #0x0
ffff00000008a5e4:	54000360 	b.eq	ffff00000008a650 <free_page+0xc0>  // b.none
        index = (vstart >> 21) & 0x1ff;
ffff00000008a5e8:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008a5ec:	d355fc00 	lsr	x0, x0, #21
ffff00000008a5f0:	12002000 	and	w0, w0, #0x1ff
ffff00000008a5f4:	b90027e0 	str	w0, [sp, #36]

        if (ptr[index] & ENTRY_V) {
ffff00000008a5f8:	b94027e0 	ldr	w0, [sp, #36]
ffff00000008a5fc:	d37df000 	lsl	x0, x0, #3
ffff00000008a600:	f94017e1 	ldr	x1, [sp, #40]
ffff00000008a604:	8b000020 	add	x0, x1, x0
ffff00000008a608:	f9400000 	ldr	x0, [x0]
ffff00000008a60c:	92400000 	and	x0, x0, #0x1
ffff00000008a610:	f100001f 	cmp	x0, #0x0
ffff00000008a614:	540001e0 	b.eq	ffff00000008a650 <free_page+0xc0>  // b.none
            kfree(P2V(PTE_ADDR(ptr[index])));
ffff00000008a618:	b94027e0 	ldr	w0, [sp, #36]
ffff00000008a61c:	d37df000 	lsl	x0, x0, #3
ffff00000008a620:	f94017e1 	ldr	x1, [sp, #40]
ffff00000008a624:	8b000020 	add	x0, x1, x0
ffff00000008a628:	f9400000 	ldr	x0, [x0]
ffff00000008a62c:	926b6801 	and	x1, x0, #0xffffffe00000
ffff00000008a630:	d2ffffe0 	mov	x0, #0xffff000000000000    	// #-281474976710656
ffff00000008a634:	8b000020 	add	x0, x1, x0
ffff00000008a638:	97fffe94 	bl	ffff00000008a088 <kfree>
            ptr[index] = 0;
ffff00000008a63c:	b94027e0 	ldr	w0, [sp, #36]
ffff00000008a640:	d37df000 	lsl	x0, x0, #3
ffff00000008a644:	f94017e1 	ldr	x1, [sp, #40]
ffff00000008a648:	8b000020 	add	x0, x1, x0
ffff00000008a64c:	f900001f 	str	xzr, [x0]
        }
    }
}
ffff00000008a650:	d503201f 	nop
ffff00000008a654:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff00000008a658:	d65f03c0 	ret

ffff00000008a65c <free_pmd>:

static void free_pmd(uint64_t map)
{
ffff00000008a65c:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff00000008a660:	910003fd 	mov	x29, sp
ffff00000008a664:	f9000fe0 	str	x0, [sp, #24]
    uint64_t *pgd = (uint64_t*)map;
ffff00000008a668:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a66c:	f9001be0 	str	x0, [sp, #48]
    uint64_t *pud = NULL;
ffff00000008a670:	f90017ff 	str	xzr, [sp, #40]

    for (int i = 0; i < 512; i++) {
ffff00000008a674:	b9003fff 	str	wzr, [sp, #60]
ffff00000008a678:	14000033 	b	ffff00000008a744 <free_pmd+0xe8>
        if (pgd[i] & ENTRY_V) {
ffff00000008a67c:	b9803fe0 	ldrsw	x0, [sp, #60]
ffff00000008a680:	d37df000 	lsl	x0, x0, #3
ffff00000008a684:	f9401be1 	ldr	x1, [sp, #48]
ffff00000008a688:	8b000020 	add	x0, x1, x0
ffff00000008a68c:	f9400000 	ldr	x0, [x0]
ffff00000008a690:	92400000 	and	x0, x0, #0x1
ffff00000008a694:	f100001f 	cmp	x0, #0x0
ffff00000008a698:	54000500 	b.eq	ffff00000008a738 <free_pmd+0xdc>  // b.none
            pud = (uint64_t*)P2V(PDE_ADDR(pgd[i]));
ffff00000008a69c:	b9803fe0 	ldrsw	x0, [sp, #60]
ffff00000008a6a0:	d37df000 	lsl	x0, x0, #3
ffff00000008a6a4:	f9401be1 	ldr	x1, [sp, #48]
ffff00000008a6a8:	8b000020 	add	x0, x1, x0
ffff00000008a6ac:	f9400000 	ldr	x0, [x0]
ffff00000008a6b0:	92748c01 	and	x1, x0, #0xfffffffff000
ffff00000008a6b4:	d2ffffe0 	mov	x0, #0xffff000000000000    	// #-281474976710656
ffff00000008a6b8:	8b000020 	add	x0, x1, x0
ffff00000008a6bc:	f90017e0 	str	x0, [sp, #40]

            for (int j = 0; j < 512; j++) {
ffff00000008a6c0:	b9003bff 	str	wzr, [sp, #56]
ffff00000008a6c4:	1400001a 	b	ffff00000008a72c <free_pmd+0xd0>
                if (pud[j] & ENTRY_V) {
ffff00000008a6c8:	b9803be0 	ldrsw	x0, [sp, #56]
ffff00000008a6cc:	d37df000 	lsl	x0, x0, #3
ffff00000008a6d0:	f94017e1 	ldr	x1, [sp, #40]
ffff00000008a6d4:	8b000020 	add	x0, x1, x0
ffff00000008a6d8:	f9400000 	ldr	x0, [x0]
ffff00000008a6dc:	92400000 	and	x0, x0, #0x1
ffff00000008a6e0:	f100001f 	cmp	x0, #0x0
ffff00000008a6e4:	540001e0 	b.eq	ffff00000008a720 <free_pmd+0xc4>  // b.none
                    kfree(P2V(PDE_ADDR(pud[j])));
ffff00000008a6e8:	b9803be0 	ldrsw	x0, [sp, #56]
ffff00000008a6ec:	d37df000 	lsl	x0, x0, #3
ffff00000008a6f0:	f94017e1 	ldr	x1, [sp, #40]
ffff00000008a6f4:	8b000020 	add	x0, x1, x0
ffff00000008a6f8:	f9400000 	ldr	x0, [x0]
ffff00000008a6fc:	92748c01 	and	x1, x0, #0xfffffffff000
ffff00000008a700:	d2ffffe0 	mov	x0, #0xffff000000000000    	// #-281474976710656
ffff00000008a704:	8b000020 	add	x0, x1, x0
ffff00000008a708:	97fffe60 	bl	ffff00000008a088 <kfree>
                    pud[j] = 0;
ffff00000008a70c:	b9803be0 	ldrsw	x0, [sp, #56]
ffff00000008a710:	d37df000 	lsl	x0, x0, #3
ffff00000008a714:	f94017e1 	ldr	x1, [sp, #40]
ffff00000008a718:	8b000020 	add	x0, x1, x0
ffff00000008a71c:	f900001f 	str	xzr, [x0]
            for (int j = 0; j < 512; j++) {
ffff00000008a720:	b9403be0 	ldr	w0, [sp, #56]
ffff00000008a724:	11000400 	add	w0, w0, #0x1
ffff00000008a728:	b9003be0 	str	w0, [sp, #56]
ffff00000008a72c:	b9403be0 	ldr	w0, [sp, #56]
ffff00000008a730:	7107fc1f 	cmp	w0, #0x1ff
ffff00000008a734:	54fffcad 	b.le	ffff00000008a6c8 <free_pmd+0x6c>
    for (int i = 0; i < 512; i++) {
ffff00000008a738:	b9403fe0 	ldr	w0, [sp, #60]
ffff00000008a73c:	11000400 	add	w0, w0, #0x1
ffff00000008a740:	b9003fe0 	str	w0, [sp, #60]
ffff00000008a744:	b9403fe0 	ldr	w0, [sp, #60]
ffff00000008a748:	7107fc1f 	cmp	w0, #0x1ff
ffff00000008a74c:	54fff98d 	b.le	ffff00000008a67c <free_pmd+0x20>
                }
            }
        }
    }
}
ffff00000008a750:	d503201f 	nop
ffff00000008a754:	d503201f 	nop
ffff00000008a758:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff00000008a75c:	d65f03c0 	ret

ffff00000008a760 <free_pud>:

static void free_pud(uint64_t map)
{
ffff00000008a760:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008a764:	910003fd 	mov	x29, sp
ffff00000008a768:	f9000fe0 	str	x0, [sp, #24]
    uint64_t *ptr = (uint64_t*)map;
ffff00000008a76c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a770:	f90013e0 	str	x0, [sp, #32]

    for (int i = 0; i < 512; i++) {
ffff00000008a774:	b9002fff 	str	wzr, [sp, #44]
ffff00000008a778:	1400001a 	b	ffff00000008a7e0 <free_pud+0x80>
        if (ptr[i] & ENTRY_V) {
ffff00000008a77c:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff00000008a780:	d37df000 	lsl	x0, x0, #3
ffff00000008a784:	f94013e1 	ldr	x1, [sp, #32]
ffff00000008a788:	8b000020 	add	x0, x1, x0
ffff00000008a78c:	f9400000 	ldr	x0, [x0]
ffff00000008a790:	92400000 	and	x0, x0, #0x1
ffff00000008a794:	f100001f 	cmp	x0, #0x0
ffff00000008a798:	540001e0 	b.eq	ffff00000008a7d4 <free_pud+0x74>  // b.none
            kfree(P2V(PDE_ADDR(ptr[i])));
ffff00000008a79c:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff00000008a7a0:	d37df000 	lsl	x0, x0, #3
ffff00000008a7a4:	f94013e1 	ldr	x1, [sp, #32]
ffff00000008a7a8:	8b000020 	add	x0, x1, x0
ffff00000008a7ac:	f9400000 	ldr	x0, [x0]
ffff00000008a7b0:	92748c01 	and	x1, x0, #0xfffffffff000
ffff00000008a7b4:	d2ffffe0 	mov	x0, #0xffff000000000000    	// #-281474976710656
ffff00000008a7b8:	8b000020 	add	x0, x1, x0
ffff00000008a7bc:	97fffe33 	bl	ffff00000008a088 <kfree>
            ptr[i] = 0;
ffff00000008a7c0:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff00000008a7c4:	d37df000 	lsl	x0, x0, #3
ffff00000008a7c8:	f94013e1 	ldr	x1, [sp, #32]
ffff00000008a7cc:	8b000020 	add	x0, x1, x0
ffff00000008a7d0:	f900001f 	str	xzr, [x0]
    for (int i = 0; i < 512; i++) {
ffff00000008a7d4:	b9402fe0 	ldr	w0, [sp, #44]
ffff00000008a7d8:	11000400 	add	w0, w0, #0x1
ffff00000008a7dc:	b9002fe0 	str	w0, [sp, #44]
ffff00000008a7e0:	b9402fe0 	ldr	w0, [sp, #44]
ffff00000008a7e4:	7107fc1f 	cmp	w0, #0x1ff
ffff00000008a7e8:	54fffcad 	b.le	ffff00000008a77c <free_pud+0x1c>
        }
    }
}
ffff00000008a7ec:	d503201f 	nop
ffff00000008a7f0:	d503201f 	nop
ffff00000008a7f4:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff00000008a7f8:	d65f03c0 	ret

ffff00000008a7fc <free_pgd>:

static void free_pgd(uint64_t map)
{
ffff00000008a7fc:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008a800:	910003fd 	mov	x29, sp
ffff00000008a804:	f9000fe0 	str	x0, [sp, #24]
    kfree(map);
ffff00000008a808:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a80c:	97fffe1f 	bl	ffff00000008a088 <kfree>
}
ffff00000008a810:	d503201f 	nop
ffff00000008a814:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008a818:	d65f03c0 	ret

ffff00000008a81c <free_vm>:

void free_vm(uint64_t map)
{
ffff00000008a81c:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008a820:	910003fd 	mov	x29, sp
ffff00000008a824:	f9000fe0 	str	x0, [sp, #24]
    free_page(map, 0x400000);
ffff00000008a828:	d2a00801 	mov	x1, #0x400000              	// #4194304
ffff00000008a82c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a830:	97ffff58 	bl	ffff00000008a590 <free_page>
    free_pmd(map);
ffff00000008a834:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a838:	97ffff89 	bl	ffff00000008a65c <free_pmd>
    free_pud(map);
ffff00000008a83c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a840:	97ffffc8 	bl	ffff00000008a760 <free_pud>
    free_pgd(map);
ffff00000008a844:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a848:	97ffffed 	bl	ffff00000008a7fc <free_pgd>
}
ffff00000008a84c:	d503201f 	nop
ffff00000008a850:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008a854:	d65f03c0 	ret

ffff00000008a858 <load_user_embedded>:
extern char _binary_init_bin_start[];
extern char _binary_init_bin_end[];

void load_user_embedded(uint64_t addr)
{
ffff00000008a858:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008a85c:	910003fd 	mov	x29, sp
ffff00000008a860:	f9000fe0 	str	x0, [sp, #24]
    uint64_t size =
        _binary_init_bin_end - _binary_init_bin_start;
ffff00000008a864:	f0000000 	adrp	x0, ffff00000008d000 <_binary_user_bin_start+0x200>
ffff00000008a868:	f946f801 	ldr	x1, [x0, #3568]
ffff00000008a86c:	f0000000 	adrp	x0, ffff00000008d000 <_binary_user_bin_start+0x200>
ffff00000008a870:	f946f400 	ldr	x0, [x0, #3560]
ffff00000008a874:	cb000020 	sub	x0, x1, x0
    uint64_t size =
ffff00000008a878:	f90017e0 	str	x0, [sp, #40]

    memcpy((void*)addr, _binary_init_bin_start, size);
ffff00000008a87c:	f9400fe3 	ldr	x3, [sp, #24]
ffff00000008a880:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008a884:	2a0003e2 	mov	w2, w0
ffff00000008a888:	f0000000 	adrp	x0, ffff00000008d000 <_binary_user_bin_start+0x200>
ffff00000008a88c:	f946f401 	ldr	x1, [x0, #3560]
ffff00000008a890:	aa0303e0 	mov	x0, x3
ffff00000008a894:	97ffd641 	bl	ffff000000080198 <memcpy>
}
ffff00000008a898:	d503201f 	nop
ffff00000008a89c:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff00000008a8a0:	d65f03c0 	ret

ffff00000008a8a4 <setup_uvm>:


bool setup_uvm(uint64_t map, char *file_name)
{
ffff00000008a8a4:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008a8a8:	910003fd 	mov	x29, sp
ffff00000008a8ac:	f9000fe0 	str	x0, [sp, #24]
ffff00000008a8b0:	f9000be1 	str	x1, [sp, #16]
    bool status = false;
ffff00000008a8b4:	3900bfff 	strb	wzr, [sp, #47]
    void *page = kalloc();
ffff00000008a8b8:	97fffe20 	bl	ffff00000008a138 <kalloc>
ffff00000008a8bc:	f90013e0 	str	x0, [sp, #32]

    if (page != NULL) {
ffff00000008a8c0:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008a8c4:	f100001f 	cmp	x0, #0x0
ffff00000008a8c8:	540003e0 	b.eq	ffff00000008a944 <setup_uvm+0xa0>  // b.none
        memset(page, 0, PAGE_SIZE);
ffff00000008a8cc:	52a00402 	mov	w2, #0x200000              	// #2097152
ffff00000008a8d0:	52800001 	mov	w1, #0x0                   	// #0
ffff00000008a8d4:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008a8d8:	97ffd61f 	bl	ffff000000080154 <memset>
        status = map_page(map, 0x400000, V2P(page), ENTRY_V | USER | NORMAL_MEMORY | ENTRY_ACCESSED);
ffff00000008a8dc:	f94013e1 	ldr	x1, [sp, #32]
ffff00000008a8e0:	d2e00020 	mov	x0, #0x1000000000000       	// #281474976710656
ffff00000008a8e4:	8b000020 	add	x0, x1, x0
ffff00000008a8e8:	d28088a3 	mov	x3, #0x445                 	// #1093
ffff00000008a8ec:	aa0003e2 	mov	x2, x0
ffff00000008a8f0:	d2a00801 	mov	x1, #0x400000              	// #4194304
ffff00000008a8f4:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a8f8:	97fffedb 	bl	ffff00000008a464 <map_page>
ffff00000008a8fc:	3900bfe0 	strb	w0, [sp, #47]

        if (status == true) {
ffff00000008a900:	3940bfe0 	ldrb	w0, [sp, #47]
ffff00000008a904:	7100001f 	cmp	w0, #0x0
ffff00000008a908:	54000160 	b.eq	ffff00000008a934 <setup_uvm+0x90>  // b.none
            if (load_file(file_name, (uint64_t)page) == -1) {
ffff00000008a90c:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008a910:	aa0003e1 	mov	x1, x0
ffff00000008a914:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008a918:	940001b4 	bl	ffff00000008afe8 <load_file>
ffff00000008a91c:	3100041f 	cmn	w0, #0x1
ffff00000008a920:	54000121 	b.ne	ffff00000008a944 <setup_uvm+0xa0>  // b.any
                free_vm(map);
ffff00000008a924:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a928:	97ffffbd 	bl	ffff00000008a81c <free_vm>
                return false;
ffff00000008a92c:	52800000 	mov	w0, #0x0                   	// #0
ffff00000008a930:	14000006 	b	ffff00000008a948 <setup_uvm+0xa4>
            }
           // load_user_embedded((uint64_t)page);
           // status = true;
        }
        else {
            kfree((uint64_t)page);
ffff00000008a934:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008a938:	97fffdd4 	bl	ffff00000008a088 <kfree>
            free_vm(map);
ffff00000008a93c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a940:	97ffffb7 	bl	ffff00000008a81c <free_vm>
        }
    }

    return status;
ffff00000008a944:	3940bfe0 	ldrb	w0, [sp, #47]
}
ffff00000008a948:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff00000008a94c:	d65f03c0 	ret

ffff00000008a950 <switch_vm>:

void switch_vm(uint64_t map)
{
ffff00000008a950:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008a954:	910003fd 	mov	x29, sp
ffff00000008a958:	f9000fe0 	str	x0, [sp, #24]
    load_pgd(V2P(map));
ffff00000008a95c:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008a960:	d2e00020 	mov	x0, #0x1000000000000       	// #281474976710656
ffff00000008a964:	8b000020 	add	x0, x1, x0
ffff00000008a968:	97ffdda8 	bl	ffff000000082008 <load_pgd>
}
ffff00000008a96c:	d503201f 	nop
ffff00000008a970:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008a974:	d65f03c0 	ret

ffff00000008a978 <init_memory>:

void init_memory(void)
{
ffff00000008a978:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffff00000008a97c:	910003fd 	mov	x29, sp
    free_region((uint64_t)&end, MEMORY_END);
ffff00000008a980:	f0000000 	adrp	x0, ffff00000008d000 <_binary_user_bin_start+0x200>
ffff00000008a984:	f946e800 	ldr	x0, [x0, #3536]
ffff00000008a988:	d2a60001 	mov	x1, #0x30000000            	// #805306368
ffff00000008a98c:	f2ffffe1 	movk	x1, #0xffff, lsl #48
ffff00000008a990:	97fffda0 	bl	ffff00000008a010 <free_region>
     kernel_pgd = (uint64_t)pgd_ttbr1; 
ffff00000008a994:	f0000000 	adrp	x0, ffff00000008d000 <_binary_user_bin_start+0x200>
ffff00000008a998:	f946e401 	ldr	x1, [x0, #3528]
ffff00000008a99c:	f0000000 	adrp	x0, ffff00000008d000 <_binary_user_bin_start+0x200>
ffff00000008a9a0:	f946f000 	ldr	x0, [x0, #3552]
ffff00000008a9a4:	f9000001 	str	x1, [x0]
    //checkmm();
}
ffff00000008a9a8:	d503201f 	nop
ffff00000008a9ac:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffff00000008a9b0:	d65f03c0 	ret

ffff00000008a9b4 <get_fs_bpb>:
#include "lib.h"
#include "debug.h"


static struct BPB* get_fs_bpb(void)
{
ffff00000008a9b4:	d10043ff 	sub	sp, sp, #0x10
    uint32_t lba = *(uint32_t*)(FS_BASE + 0x1be + 8);
ffff00000008a9b8:	d28038c0 	mov	x0, #0x1c6                 	// #454
ffff00000008a9bc:	f2a60000 	movk	x0, #0x3000, lsl #16
ffff00000008a9c0:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff00000008a9c4:	b9400000 	ldr	w0, [x0]
ffff00000008a9c8:	b9000fe0 	str	w0, [sp, #12]

    return (struct BPB*)(FS_BASE + lba * 512);
ffff00000008a9cc:	b9400fe0 	ldr	w0, [sp, #12]
ffff00000008a9d0:	53175800 	lsl	w0, w0, #9
ffff00000008a9d4:	2a0003e1 	mov	w1, w0
ffff00000008a9d8:	d2a60000 	mov	x0, #0x30000000            	// #805306368
ffff00000008a9dc:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff00000008a9e0:	8b000020 	add	x0, x1, x0
}
ffff00000008a9e4:	910043ff 	add	sp, sp, #0x10
ffff00000008a9e8:	d65f03c0 	ret

ffff00000008a9ec <get_fat_table>:

static uint16_t *get_fat_table(void)
{
ffff00000008a9ec:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008a9f0:	910003fd 	mov	x29, sp
    struct BPB* p = get_fs_bpb();
ffff00000008a9f4:	97fffff0 	bl	ffff00000008a9b4 <get_fs_bpb>
ffff00000008a9f8:	f9000fe0 	str	x0, [sp, #24]
    uint32_t offset = (uint32_t)p->reserved_sector_count * p->bytes_per_sector;
ffff00000008a9fc:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008aa00:	79401c00 	ldrh	w0, [x0, #14]
ffff00000008aa04:	2a0003e1 	mov	w1, w0
ffff00000008aa08:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008aa0c:	7840b000 	ldurh	w0, [x0, #11]
ffff00000008aa10:	1b007c20 	mul	w0, w1, w0
ffff00000008aa14:	b90017e0 	str	w0, [sp, #20]

    return (uint16_t *)((uint8_t*)p + offset);
ffff00000008aa18:	b94017e0 	ldr	w0, [sp, #20]
ffff00000008aa1c:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008aa20:	8b000020 	add	x0, x1, x0
}
ffff00000008aa24:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008aa28:	d65f03c0 	ret

ffff00000008aa2c <get_cluster_value>:

static uint16_t get_cluster_value(uint32_t cluster_index)
{
ffff00000008aa2c:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008aa30:	910003fd 	mov	x29, sp
ffff00000008aa34:	b9001fe0 	str	w0, [sp, #28]
    uint16_t *fat_table = get_fat_table();
ffff00000008aa38:	97ffffed 	bl	ffff00000008a9ec <get_fat_table>
ffff00000008aa3c:	f90017e0 	str	x0, [sp, #40]

    return fat_table[cluster_index];
ffff00000008aa40:	b9401fe0 	ldr	w0, [sp, #28]
ffff00000008aa44:	d37ff800 	lsl	x0, x0, #1
ffff00000008aa48:	f94017e1 	ldr	x1, [sp, #40]
ffff00000008aa4c:	8b000020 	add	x0, x1, x0
ffff00000008aa50:	79400000 	ldrh	w0, [x0]
}
ffff00000008aa54:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff00000008aa58:	d65f03c0 	ret

ffff00000008aa5c <get_cluster_offset>:

static uint32_t get_cluster_offset(uint32_t index)
{
ffff00000008aa5c:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff00000008aa60:	910003fd 	mov	x29, sp
ffff00000008aa64:	b9001fe0 	str	w0, [sp, #28]
    uint32_t res_size;
    uint32_t fat_size;
    uint32_t dir_size;

    ASSERT(index >= 2);
ffff00000008aa68:	b9401fe0 	ldr	w0, [sp, #28]
ffff00000008aa6c:	7100041f 	cmp	w0, #0x1
ffff00000008aa70:	540000a8 	b.hi	ffff00000008aa84 <get_cluster_offset+0x28>  // b.pmore
ffff00000008aa74:	d2800481 	mov	x1, #0x24                  	// #36
ffff00000008aa78:	d0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008aa7c:	91062000 	add	x0, x0, #0x188
ffff00000008aa80:	97ffd861 	bl	ffff000000080c04 <error_check>

    struct BPB* p = get_fs_bpb();
ffff00000008aa84:	97ffffcc 	bl	ffff00000008a9b4 <get_fs_bpb>
ffff00000008aa88:	f9001fe0 	str	x0, [sp, #56]

    res_size = (uint32_t)p->reserved_sector_count * p->bytes_per_sector;
ffff00000008aa8c:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008aa90:	79401c00 	ldrh	w0, [x0, #14]
ffff00000008aa94:	2a0003e1 	mov	w1, w0
ffff00000008aa98:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008aa9c:	7840b000 	ldurh	w0, [x0, #11]
ffff00000008aaa0:	1b007c20 	mul	w0, w1, w0
ffff00000008aaa4:	b90037e0 	str	w0, [sp, #52]
    fat_size = (uint32_t)p->fat_count * p->sectors_per_fat * p->bytes_per_sector;
ffff00000008aaa8:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008aaac:	39404000 	ldrb	w0, [x0, #16]
ffff00000008aab0:	2a0003e1 	mov	w1, w0
ffff00000008aab4:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008aab8:	79402c00 	ldrh	w0, [x0, #22]
ffff00000008aabc:	1b007c20 	mul	w0, w1, w0
ffff00000008aac0:	f9401fe1 	ldr	x1, [sp, #56]
ffff00000008aac4:	7840b021 	ldurh	w1, [x1, #11]
ffff00000008aac8:	1b017c00 	mul	w0, w0, w1
ffff00000008aacc:	b90033e0 	str	w0, [sp, #48]
    dir_size = (uint32_t)p->root_entry_count * sizeof(struct DirEntry);
ffff00000008aad0:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008aad4:	78411000 	ldurh	w0, [x0, #17]
ffff00000008aad8:	531b6800 	lsl	w0, w0, #5
ffff00000008aadc:	b9002fe0 	str	w0, [sp, #44]

    return res_size + fat_size + dir_size +
ffff00000008aae0:	b94037e1 	ldr	w1, [sp, #52]
ffff00000008aae4:	b94033e0 	ldr	w0, [sp, #48]
ffff00000008aae8:	0b000021 	add	w1, w1, w0
ffff00000008aaec:	b9402fe0 	ldr	w0, [sp, #44]
ffff00000008aaf0:	0b000021 	add	w1, w1, w0
        (index - 2) * ((uint32_t)p->sectors_per_cluster * p->bytes_per_sector);
ffff00000008aaf4:	b9401fe0 	ldr	w0, [sp, #28]
ffff00000008aaf8:	51000802 	sub	w2, w0, #0x2
ffff00000008aafc:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008ab00:	39403400 	ldrb	w0, [x0, #13]
ffff00000008ab04:	2a0003e3 	mov	w3, w0
ffff00000008ab08:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008ab0c:	7840b000 	ldurh	w0, [x0, #11]
ffff00000008ab10:	1b007c60 	mul	w0, w3, w0
ffff00000008ab14:	1b007c40 	mul	w0, w2, w0
    return res_size + fat_size + dir_size +
ffff00000008ab18:	0b000020 	add	w0, w1, w0
}
ffff00000008ab1c:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff00000008ab20:	d65f03c0 	ret

ffff00000008ab24 <get_cluster_size>:

static uint32_t get_cluster_size(void)
{
ffff00000008ab24:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008ab28:	910003fd 	mov	x29, sp
    struct BPB* bpb = get_fs_bpb();
ffff00000008ab2c:	97ffffa2 	bl	ffff00000008a9b4 <get_fs_bpb>
ffff00000008ab30:	f9000fe0 	str	x0, [sp, #24]

    return (uint32_t)bpb->bytes_per_sector * bpb->sectors_per_cluster;
ffff00000008ab34:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008ab38:	7840b000 	ldurh	w0, [x0, #11]
ffff00000008ab3c:	2a0003e1 	mov	w1, w0
ffff00000008ab40:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008ab44:	39403400 	ldrb	w0, [x0, #13]
ffff00000008ab48:	1b007c20 	mul	w0, w1, w0
}
ffff00000008ab4c:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008ab50:	d65f03c0 	ret

ffff00000008ab54 <get_root_directory_count>:

static uint32_t get_root_directory_count(void)
{
ffff00000008ab54:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008ab58:	910003fd 	mov	x29, sp
    struct BPB* bpb = get_fs_bpb();
ffff00000008ab5c:	97ffff96 	bl	ffff00000008a9b4 <get_fs_bpb>
ffff00000008ab60:	f9000fe0 	str	x0, [sp, #24]

    return bpb->root_entry_count;
ffff00000008ab64:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008ab68:	78411000 	ldurh	w0, [x0, #17]
}
ffff00000008ab6c:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008ab70:	d65f03c0 	ret

ffff00000008ab74 <get_root_directory>:

static struct DirEntry *get_root_directory(void)
{
ffff00000008ab74:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008ab78:	910003fd 	mov	x29, sp
    struct BPB *p; 
    uint32_t offset; 

    p = get_fs_bpb();
ffff00000008ab7c:	97ffff8e 	bl	ffff00000008a9b4 <get_fs_bpb>
ffff00000008ab80:	f9000fe0 	str	x0, [sp, #24]
    offset = (p->reserved_sector_count + (uint32_t)p->fat_count * p->sectors_per_fat) * p->bytes_per_sector;
ffff00000008ab84:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008ab88:	79401c00 	ldrh	w0, [x0, #14]
ffff00000008ab8c:	2a0003e1 	mov	w1, w0
ffff00000008ab90:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008ab94:	39404000 	ldrb	w0, [x0, #16]
ffff00000008ab98:	2a0003e2 	mov	w2, w0
ffff00000008ab9c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008aba0:	79402c00 	ldrh	w0, [x0, #22]
ffff00000008aba4:	1b007c40 	mul	w0, w2, w0
ffff00000008aba8:	0b000020 	add	w0, w1, w0
ffff00000008abac:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008abb0:	7840b021 	ldurh	w1, [x1, #11]
ffff00000008abb4:	1b017c00 	mul	w0, w0, w1
ffff00000008abb8:	b90017e0 	str	w0, [sp, #20]

    return (struct DirEntry *)((uint8_t*)p + offset);
ffff00000008abbc:	b94017e0 	ldr	w0, [sp, #20]
ffff00000008abc0:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008abc4:	8b000020 	add	x0, x1, x0
}
ffff00000008abc8:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008abcc:	d65f03c0 	ret

ffff00000008abd0 <is_file_name_equal>:

static bool is_file_name_equal(struct DirEntry *dir_entry, char *name, char *ext)
{
ffff00000008abd0:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff00000008abd4:	910003fd 	mov	x29, sp
ffff00000008abd8:	f90017e0 	str	x0, [sp, #40]
ffff00000008abdc:	f90013e1 	str	x1, [sp, #32]
ffff00000008abe0:	f9000fe2 	str	x2, [sp, #24]
    bool status = false;
ffff00000008abe4:	3900ffff 	strb	wzr, [sp, #63]

    if (memcmp(dir_entry->name, name, 8) == 0 &&
ffff00000008abe8:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008abec:	52800102 	mov	w2, #0x8                   	// #8
ffff00000008abf0:	f94013e1 	ldr	x1, [sp, #32]
ffff00000008abf4:	97ffd55e 	bl	ffff00000008016c <memcmp>
ffff00000008abf8:	7100001f 	cmp	w0, #0x0
ffff00000008abfc:	54000141 	b.ne	ffff00000008ac24 <is_file_name_equal+0x54>  // b.any
        memcmp(dir_entry->ext, ext, 3) == 0) {
ffff00000008ac00:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008ac04:	91002000 	add	x0, x0, #0x8
ffff00000008ac08:	52800062 	mov	w2, #0x3                   	// #3
ffff00000008ac0c:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008ac10:	97ffd557 	bl	ffff00000008016c <memcmp>
    if (memcmp(dir_entry->name, name, 8) == 0 &&
ffff00000008ac14:	7100001f 	cmp	w0, #0x0
ffff00000008ac18:	54000061 	b.ne	ffff00000008ac24 <is_file_name_equal+0x54>  // b.any
        status = true;
ffff00000008ac1c:	52800020 	mov	w0, #0x1                   	// #1
ffff00000008ac20:	3900ffe0 	strb	w0, [sp, #63]
    }

    return status;
ffff00000008ac24:	3940ffe0 	ldrb	w0, [sp, #63]
}
ffff00000008ac28:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff00000008ac2c:	d65f03c0 	ret

ffff00000008ac30 <split_path>:

static bool split_path(char *path, char *name, char *ext)
{
ffff00000008ac30:	d100c3ff 	sub	sp, sp, #0x30
ffff00000008ac34:	f9000fe0 	str	x0, [sp, #24]
ffff00000008ac38:	f9000be1 	str	x1, [sp, #16]
ffff00000008ac3c:	f90007e2 	str	x2, [sp, #8]
    int i;

    for (i = 0; i < 8 && path[i] != '.' && path[i] != '\0'; i++) {
ffff00000008ac40:	b9002fff 	str	wzr, [sp, #44]
ffff00000008ac44:	14000014 	b	ffff00000008ac94 <split_path+0x64>
        if (path[i] == '/') {
ffff00000008ac48:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff00000008ac4c:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008ac50:	8b000020 	add	x0, x1, x0
ffff00000008ac54:	39400000 	ldrb	w0, [x0]
ffff00000008ac58:	7100bc1f 	cmp	w0, #0x2f
ffff00000008ac5c:	54000061 	b.ne	ffff00000008ac68 <split_path+0x38>  // b.any
            return false;
ffff00000008ac60:	52800000 	mov	w0, #0x0                   	// #0
ffff00000008ac64:	1400004e 	b	ffff00000008ad9c <split_path+0x16c>
        }

        name[i] = path[i];
ffff00000008ac68:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff00000008ac6c:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008ac70:	8b000021 	add	x1, x1, x0
ffff00000008ac74:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff00000008ac78:	f9400be2 	ldr	x2, [sp, #16]
ffff00000008ac7c:	8b000040 	add	x0, x2, x0
ffff00000008ac80:	39400021 	ldrb	w1, [x1]
ffff00000008ac84:	39000001 	strb	w1, [x0]
    for (i = 0; i < 8 && path[i] != '.' && path[i] != '\0'; i++) {
ffff00000008ac88:	b9402fe0 	ldr	w0, [sp, #44]
ffff00000008ac8c:	11000400 	add	w0, w0, #0x1
ffff00000008ac90:	b9002fe0 	str	w0, [sp, #44]
ffff00000008ac94:	b9402fe0 	ldr	w0, [sp, #44]
ffff00000008ac98:	71001c1f 	cmp	w0, #0x7
ffff00000008ac9c:	540001ac 	b.gt	ffff00000008acd0 <split_path+0xa0>
ffff00000008aca0:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff00000008aca4:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008aca8:	8b000020 	add	x0, x1, x0
ffff00000008acac:	39400000 	ldrb	w0, [x0]
ffff00000008acb0:	7100b81f 	cmp	w0, #0x2e
ffff00000008acb4:	540000e0 	b.eq	ffff00000008acd0 <split_path+0xa0>  // b.none
ffff00000008acb8:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff00000008acbc:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008acc0:	8b000020 	add	x0, x1, x0
ffff00000008acc4:	39400000 	ldrb	w0, [x0]
ffff00000008acc8:	7100001f 	cmp	w0, #0x0
ffff00000008accc:	54fffbe1 	b.ne	ffff00000008ac48 <split_path+0x18>  // b.any
    }

    if (path[i] == '.') {
ffff00000008acd0:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff00000008acd4:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008acd8:	8b000020 	add	x0, x1, x0
ffff00000008acdc:	39400000 	ldrb	w0, [x0]
ffff00000008ace0:	7100b81f 	cmp	w0, #0x2e
ffff00000008ace4:	540004a1 	b.ne	ffff00000008ad78 <split_path+0x148>  // b.any
        i++;
ffff00000008ace8:	b9402fe0 	ldr	w0, [sp, #44]
ffff00000008acec:	11000400 	add	w0, w0, #0x1
ffff00000008acf0:	b9002fe0 	str	w0, [sp, #44]
        
        for (int j = 0; j < 3 && path[i] != '\0'; i++, j++) {
ffff00000008acf4:	b9002bff 	str	wzr, [sp, #40]
ffff00000008acf8:	14000017 	b	ffff00000008ad54 <split_path+0x124>
            if (path[i] == '/') {
ffff00000008acfc:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff00000008ad00:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008ad04:	8b000020 	add	x0, x1, x0
ffff00000008ad08:	39400000 	ldrb	w0, [x0]
ffff00000008ad0c:	7100bc1f 	cmp	w0, #0x2f
ffff00000008ad10:	54000061 	b.ne	ffff00000008ad1c <split_path+0xec>  // b.any
                return false;
ffff00000008ad14:	52800000 	mov	w0, #0x0                   	// #0
ffff00000008ad18:	14000021 	b	ffff00000008ad9c <split_path+0x16c>
            }

            ext[j] = path[i];
ffff00000008ad1c:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff00000008ad20:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008ad24:	8b000021 	add	x1, x1, x0
ffff00000008ad28:	b9802be0 	ldrsw	x0, [sp, #40]
ffff00000008ad2c:	f94007e2 	ldr	x2, [sp, #8]
ffff00000008ad30:	8b000040 	add	x0, x2, x0
ffff00000008ad34:	39400021 	ldrb	w1, [x1]
ffff00000008ad38:	39000001 	strb	w1, [x0]
        for (int j = 0; j < 3 && path[i] != '\0'; i++, j++) {
ffff00000008ad3c:	b9402fe0 	ldr	w0, [sp, #44]
ffff00000008ad40:	11000400 	add	w0, w0, #0x1
ffff00000008ad44:	b9002fe0 	str	w0, [sp, #44]
ffff00000008ad48:	b9402be0 	ldr	w0, [sp, #40]
ffff00000008ad4c:	11000400 	add	w0, w0, #0x1
ffff00000008ad50:	b9002be0 	str	w0, [sp, #40]
ffff00000008ad54:	b9402be0 	ldr	w0, [sp, #40]
ffff00000008ad58:	7100081f 	cmp	w0, #0x2
ffff00000008ad5c:	540000ec 	b.gt	ffff00000008ad78 <split_path+0x148>
ffff00000008ad60:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff00000008ad64:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008ad68:	8b000020 	add	x0, x1, x0
ffff00000008ad6c:	39400000 	ldrb	w0, [x0]
ffff00000008ad70:	7100001f 	cmp	w0, #0x0
ffff00000008ad74:	54fffc41 	b.ne	ffff00000008acfc <split_path+0xcc>  // b.any
        }
    }

    if (path[i] != '\0') {        
ffff00000008ad78:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff00000008ad7c:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008ad80:	8b000020 	add	x0, x1, x0
ffff00000008ad84:	39400000 	ldrb	w0, [x0]
ffff00000008ad88:	7100001f 	cmp	w0, #0x0
ffff00000008ad8c:	54000060 	b.eq	ffff00000008ad98 <split_path+0x168>  // b.none
        return false;
ffff00000008ad90:	52800000 	mov	w0, #0x0                   	// #0
ffff00000008ad94:	14000002 	b	ffff00000008ad9c <split_path+0x16c>
    }

    return true;
ffff00000008ad98:	52800020 	mov	w0, #0x1                   	// #1
}
ffff00000008ad9c:	9100c3ff 	add	sp, sp, #0x30
ffff00000008ada0:	d65f03c0 	ret

ffff00000008ada4 <search_file>:

static uint32_t search_file(char *path)
{
ffff00000008ada4:	a9bb7bfd 	stp	x29, x30, [sp, #-80]!
ffff00000008ada8:	910003fd 	mov	x29, sp
ffff00000008adac:	f9000fe0 	str	x0, [sp, #24]
    char name[8] = {"        "};
ffff00000008adb0:	b203c3e0 	mov	x0, #0x2020202020202020    	// #2314885530818453536
ffff00000008adb4:	f9001be0 	str	x0, [sp, #48]
    char ext[3] =  {"   "};
ffff00000008adb8:	d0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008adbc:	91064001 	add	x1, x0, #0x190
ffff00000008adc0:	9100a3e0 	add	x0, sp, #0x28
ffff00000008adc4:	79400022 	ldrh	w2, [x1]
ffff00000008adc8:	79000002 	strh	w2, [x0]
ffff00000008adcc:	39400821 	ldrb	w1, [x1, #2]
ffff00000008add0:	39000801 	strb	w1, [x0, #2]
    uint32_t root_entry_count;
    struct DirEntry *dir_entry; 

    bool status = split_path(path, name, ext);
ffff00000008add4:	9100a3e1 	add	x1, sp, #0x28
ffff00000008add8:	9100c3e0 	add	x0, sp, #0x30
ffff00000008addc:	aa0103e2 	mov	x2, x1
ffff00000008ade0:	aa0003e1 	mov	x1, x0
ffff00000008ade4:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008ade8:	97ffff92 	bl	ffff00000008ac30 <split_path>
ffff00000008adec:	39012fe0 	strb	w0, [sp, #75]

    if (status == true) {
ffff00000008adf0:	39412fe0 	ldrb	w0, [sp, #75]
ffff00000008adf4:	7100001f 	cmp	w0, #0x0
ffff00000008adf8:	54000640 	b.eq	ffff00000008aec0 <search_file+0x11c>  // b.none
        root_entry_count = get_root_directory_count();
ffff00000008adfc:	97ffff56 	bl	ffff00000008ab54 <get_root_directory_count>
ffff00000008ae00:	b90047e0 	str	w0, [sp, #68]
        dir_entry = get_root_directory();
ffff00000008ae04:	97ffff5c 	bl	ffff00000008ab74 <get_root_directory>
ffff00000008ae08:	f9001fe0 	str	x0, [sp, #56]
        
        for (uint32_t i = 0; i < root_entry_count; i++) {
ffff00000008ae0c:	b9004fff 	str	wzr, [sp, #76]
ffff00000008ae10:	14000028 	b	ffff00000008aeb0 <search_file+0x10c>
            if (dir_entry[i].name[0] == ENTRY_EMPTY || dir_entry[i].name[0] == ENTRY_DELETED)
ffff00000008ae14:	b9404fe0 	ldr	w0, [sp, #76]
ffff00000008ae18:	d37be800 	lsl	x0, x0, #5
ffff00000008ae1c:	f9401fe1 	ldr	x1, [sp, #56]
ffff00000008ae20:	8b000020 	add	x0, x1, x0
ffff00000008ae24:	39400000 	ldrb	w0, [x0]
ffff00000008ae28:	7100001f 	cmp	w0, #0x0
ffff00000008ae2c:	54000360 	b.eq	ffff00000008ae98 <search_file+0xf4>  // b.none
ffff00000008ae30:	b9404fe0 	ldr	w0, [sp, #76]
ffff00000008ae34:	d37be800 	lsl	x0, x0, #5
ffff00000008ae38:	f9401fe1 	ldr	x1, [sp, #56]
ffff00000008ae3c:	8b000020 	add	x0, x1, x0
ffff00000008ae40:	39400000 	ldrb	w0, [x0]
ffff00000008ae44:	7103941f 	cmp	w0, #0xe5
ffff00000008ae48:	54000280 	b.eq	ffff00000008ae98 <search_file+0xf4>  // b.none
                continue;

            if (dir_entry[i].attributes == 0xf) {
ffff00000008ae4c:	b9404fe0 	ldr	w0, [sp, #76]
ffff00000008ae50:	d37be800 	lsl	x0, x0, #5
ffff00000008ae54:	f9401fe1 	ldr	x1, [sp, #56]
ffff00000008ae58:	8b000020 	add	x0, x1, x0
ffff00000008ae5c:	39402c00 	ldrb	w0, [x0, #11]
ffff00000008ae60:	71003c1f 	cmp	w0, #0xf
ffff00000008ae64:	540001e0 	b.eq	ffff00000008aea0 <search_file+0xfc>  // b.none
                continue;
            }

            if (is_file_name_equal(&dir_entry[i], name, ext)) {
ffff00000008ae68:	b9404fe0 	ldr	w0, [sp, #76]
ffff00000008ae6c:	d37be800 	lsl	x0, x0, #5
ffff00000008ae70:	f9401fe1 	ldr	x1, [sp, #56]
ffff00000008ae74:	8b000020 	add	x0, x1, x0
ffff00000008ae78:	9100a3e2 	add	x2, sp, #0x28
ffff00000008ae7c:	9100c3e1 	add	x1, sp, #0x30
ffff00000008ae80:	97ffff54 	bl	ffff00000008abd0 <is_file_name_equal>
ffff00000008ae84:	12001c00 	and	w0, w0, #0xff
ffff00000008ae88:	7100001f 	cmp	w0, #0x0
ffff00000008ae8c:	540000c0 	b.eq	ffff00000008aea4 <search_file+0x100>  // b.none
                return i;
ffff00000008ae90:	b9404fe0 	ldr	w0, [sp, #76]
ffff00000008ae94:	1400000c 	b	ffff00000008aec4 <search_file+0x120>
                continue;
ffff00000008ae98:	d503201f 	nop
ffff00000008ae9c:	14000002 	b	ffff00000008aea4 <search_file+0x100>
                continue;
ffff00000008aea0:	d503201f 	nop
        for (uint32_t i = 0; i < root_entry_count; i++) {
ffff00000008aea4:	b9404fe0 	ldr	w0, [sp, #76]
ffff00000008aea8:	11000400 	add	w0, w0, #0x1
ffff00000008aeac:	b9004fe0 	str	w0, [sp, #76]
ffff00000008aeb0:	b9404fe1 	ldr	w1, [sp, #76]
ffff00000008aeb4:	b94047e0 	ldr	w0, [sp, #68]
ffff00000008aeb8:	6b00003f 	cmp	w1, w0
ffff00000008aebc:	54fffac3 	b.cc	ffff00000008ae14 <search_file+0x70>  // b.lo, b.ul, b.last
            }
        }
    }

    return 0xffffffff;
ffff00000008aec0:	12800000 	mov	w0, #0xffffffff            	// #-1
}
ffff00000008aec4:	a8c57bfd 	ldp	x29, x30, [sp], #80
ffff00000008aec8:	d65f03c0 	ret

ffff00000008aecc <read_raw_data>:

static uint32_t read_raw_data(uint32_t cluster_index, char *buffer, uint32_t size)
{
ffff00000008aecc:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff00000008aed0:	910003fd 	mov	x29, sp
ffff00000008aed4:	b9001fe0 	str	w0, [sp, #28]
ffff00000008aed8:	f9000be1 	str	x1, [sp, #16]
ffff00000008aedc:	b9001be2 	str	w2, [sp, #24]
    struct BPB* bpb;
    char *data;
    uint32_t read_size = 0;
ffff00000008aee0:	b9003fff 	str	wzr, [sp, #60]
    uint32_t cluster_size; 
    uint32_t index; 
    
    bpb = get_fs_bpb();
ffff00000008aee4:	97fffeb4 	bl	ffff00000008a9b4 <get_fs_bpb>
ffff00000008aee8:	f9001be0 	str	x0, [sp, #48]
    cluster_size = get_cluster_size();
ffff00000008aeec:	97ffff0e 	bl	ffff00000008ab24 <get_cluster_size>
ffff00000008aef0:	b9002fe0 	str	w0, [sp, #44]
    index = cluster_index;
ffff00000008aef4:	b9401fe0 	ldr	w0, [sp, #28]
ffff00000008aef8:	b9003be0 	str	w0, [sp, #56]

    if (index < 2) {
ffff00000008aefc:	b9403be0 	ldr	w0, [sp, #56]
ffff00000008af00:	7100041f 	cmp	w0, #0x1
ffff00000008af04:	540004e8 	b.hi	ffff00000008afa0 <read_raw_data+0xd4>  // b.pmore
        return 0xffffffff;
ffff00000008af08:	12800000 	mov	w0, #0xffffffff            	// #-1
ffff00000008af0c:	1400002a 	b	ffff00000008afb4 <read_raw_data+0xe8>
    }
    
    while (read_size < size) {
        data  = (char *)((uint64_t)bpb + get_cluster_offset(index));
ffff00000008af10:	b9403be0 	ldr	w0, [sp, #56]
ffff00000008af14:	97fffed2 	bl	ffff00000008aa5c <get_cluster_offset>
ffff00000008af18:	2a0003e1 	mov	w1, w0
ffff00000008af1c:	f9401be0 	ldr	x0, [sp, #48]
ffff00000008af20:	8b000020 	add	x0, x1, x0
ffff00000008af24:	f90013e0 	str	x0, [sp, #32]
        index = get_cluster_value(index);
ffff00000008af28:	b9403be0 	ldr	w0, [sp, #56]
ffff00000008af2c:	97fffec0 	bl	ffff00000008aa2c <get_cluster_value>
ffff00000008af30:	12003c00 	and	w0, w0, #0xffff
ffff00000008af34:	b9003be0 	str	w0, [sp, #56]
        
        if (index >= 0xfff7) {
ffff00000008af38:	b9403be1 	ldr	w1, [sp, #56]
ffff00000008af3c:	529ffec0 	mov	w0, #0xfff6                	// #65526
ffff00000008af40:	6b00003f 	cmp	w1, w0
ffff00000008af44:	54000169 	b.ls	ffff00000008af70 <read_raw_data+0xa4>  // b.plast
            memcpy(buffer, data, size - read_size);
ffff00000008af48:	b9401be1 	ldr	w1, [sp, #24]
ffff00000008af4c:	b9403fe0 	ldr	w0, [sp, #60]
ffff00000008af50:	4b000020 	sub	w0, w1, w0
ffff00000008af54:	2a0003e2 	mov	w2, w0
ffff00000008af58:	f94013e1 	ldr	x1, [sp, #32]
ffff00000008af5c:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008af60:	97ffd48e 	bl	ffff000000080198 <memcpy>
            read_size += size - read_size;
ffff00000008af64:	b9401be0 	ldr	w0, [sp, #24]
ffff00000008af68:	b9003fe0 	str	w0, [sp, #60]
            break;
ffff00000008af6c:	14000011 	b	ffff00000008afb0 <read_raw_data+0xe4>
        }

        memcpy(buffer, data, cluster_size);
ffff00000008af70:	b9402fe2 	ldr	w2, [sp, #44]
ffff00000008af74:	f94013e1 	ldr	x1, [sp, #32]
ffff00000008af78:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008af7c:	97ffd487 	bl	ffff000000080198 <memcpy>

        buffer += cluster_size;
ffff00000008af80:	b9402fe0 	ldr	w0, [sp, #44]
ffff00000008af84:	f9400be1 	ldr	x1, [sp, #16]
ffff00000008af88:	8b000020 	add	x0, x1, x0
ffff00000008af8c:	f9000be0 	str	x0, [sp, #16]
        read_size += cluster_size;
ffff00000008af90:	b9403fe1 	ldr	w1, [sp, #60]
ffff00000008af94:	b9402fe0 	ldr	w0, [sp, #44]
ffff00000008af98:	0b000020 	add	w0, w1, w0
ffff00000008af9c:	b9003fe0 	str	w0, [sp, #60]
    while (read_size < size) {
ffff00000008afa0:	b9403fe1 	ldr	w1, [sp, #60]
ffff00000008afa4:	b9401be0 	ldr	w0, [sp, #24]
ffff00000008afa8:	6b00003f 	cmp	w1, w0
ffff00000008afac:	54fffb23 	b.cc	ffff00000008af10 <read_raw_data+0x44>  // b.lo, b.ul, b.last
    }

    return read_size;
ffff00000008afb0:	b9403fe0 	ldr	w0, [sp, #60]
}
ffff00000008afb4:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff00000008afb8:	d65f03c0 	ret

ffff00000008afbc <read_file>:

static uint32_t read_file(uint32_t cluster_index, void *buffer, uint32_t size)
{
ffff00000008afbc:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008afc0:	910003fd 	mov	x29, sp
ffff00000008afc4:	b9001fe0 	str	w0, [sp, #28]
ffff00000008afc8:	f9000be1 	str	x1, [sp, #16]
ffff00000008afcc:	b9001be2 	str	w2, [sp, #24]
    return read_raw_data(cluster_index, buffer, size);
ffff00000008afd0:	b9401be2 	ldr	w2, [sp, #24]
ffff00000008afd4:	f9400be1 	ldr	x1, [sp, #16]
ffff00000008afd8:	b9401fe0 	ldr	w0, [sp, #28]
ffff00000008afdc:	97ffffbc 	bl	ffff00000008aecc <read_raw_data>
}
ffff00000008afe0:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008afe4:	d65f03c0 	ret

ffff00000008afe8 <load_file>:

int load_file(char *path, uint64_t addr)
{
ffff00000008afe8:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff00000008afec:	910003fd 	mov	x29, sp
ffff00000008aff0:	f9000fe0 	str	x0, [sp, #24]
ffff00000008aff4:	f9000be1 	str	x1, [sp, #16]
    uint32_t index;
    uint32_t file_size;
    uint32_t cluster_index;
    struct DirEntry *dir_entry;
    int ret = -1;
ffff00000008aff8:	12800000 	mov	w0, #0xffffffff            	// #-1
ffff00000008affc:	b9003fe0 	str	w0, [sp, #60]
    
    index = search_file(path);
ffff00000008b000:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b004:	97ffff68 	bl	ffff00000008ada4 <search_file>
ffff00000008b008:	b9003be0 	str	w0, [sp, #56]

    if (index != 0xffffffff) {
ffff00000008b00c:	b9403be0 	ldr	w0, [sp, #56]
ffff00000008b010:	3100041f 	cmn	w0, #0x1
ffff00000008b014:	54000320 	b.eq	ffff00000008b078 <load_file+0x90>  // b.none
        
        dir_entry = get_root_directory();
ffff00000008b018:	97fffed7 	bl	ffff00000008ab74 <get_root_directory>
ffff00000008b01c:	f9001be0 	str	x0, [sp, #48]
        file_size = dir_entry[index].file_size;
ffff00000008b020:	b9403be0 	ldr	w0, [sp, #56]
ffff00000008b024:	d37be800 	lsl	x0, x0, #5
ffff00000008b028:	f9401be1 	ldr	x1, [sp, #48]
ffff00000008b02c:	8b000020 	add	x0, x1, x0
ffff00000008b030:	b9401c00 	ldr	w0, [x0, #28]
ffff00000008b034:	b9002fe0 	str	w0, [sp, #44]
        cluster_index = dir_entry[index].cluster_index;
ffff00000008b038:	b9403be0 	ldr	w0, [sp, #56]
ffff00000008b03c:	d37be800 	lsl	x0, x0, #5
ffff00000008b040:	f9401be1 	ldr	x1, [sp, #48]
ffff00000008b044:	8b000020 	add	x0, x1, x0
ffff00000008b048:	79403400 	ldrh	w0, [x0, #26]
ffff00000008b04c:	b9002be0 	str	w0, [sp, #40]
        
        if (read_file(cluster_index, (void*)addr, file_size) == file_size) {
ffff00000008b050:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008b054:	b9402fe2 	ldr	w2, [sp, #44]
ffff00000008b058:	aa0003e1 	mov	x1, x0
ffff00000008b05c:	b9402be0 	ldr	w0, [sp, #40]
ffff00000008b060:	97ffffd7 	bl	ffff00000008afbc <read_file>
ffff00000008b064:	2a0003e1 	mov	w1, w0
ffff00000008b068:	b9402fe0 	ldr	w0, [sp, #44]
ffff00000008b06c:	6b01001f 	cmp	w0, w1
ffff00000008b070:	54000041 	b.ne	ffff00000008b078 <load_file+0x90>  // b.any
            ret = 0;
ffff00000008b074:	b9003fff 	str	wzr, [sp, #60]
        }
    }

    return ret;
ffff00000008b078:	b9403fe0 	ldr	w0, [sp, #60]
}
ffff00000008b07c:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff00000008b080:	d65f03c0 	ret

ffff00000008b084 <init_fs>:

void init_fs(void)
{
ffff00000008b084:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008b088:	910003fd 	mov	x29, sp
    uint8_t *p = (uint8_t*)get_fs_bpb();
ffff00000008b08c:	97fffe4a 	bl	ffff00000008a9b4 <get_fs_bpb>
ffff00000008b090:	f9000fe0 	str	x0, [sp, #24]

    if (p[0x1fe] != 0x55 || p[0x1ff] != 0xaa) {
ffff00000008b094:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b098:	9107f800 	add	x0, x0, #0x1fe
ffff00000008b09c:	39400000 	ldrb	w0, [x0]
ffff00000008b0a0:	7101541f 	cmp	w0, #0x55
ffff00000008b0a4:	540000c1 	b.ne	ffff00000008b0bc <init_fs+0x38>  // b.any
ffff00000008b0a8:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b0ac:	9107fc00 	add	x0, x0, #0x1ff
ffff00000008b0b0:	39400000 	ldrb	w0, [x0]
ffff00000008b0b4:	7102a81f 	cmp	w0, #0xaa
ffff00000008b0b8:	54000100 	b.eq	ffff00000008b0d8 <init_fs+0x54>  // b.none
        printk("invalid signature\n");
ffff00000008b0bc:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b0c0:	91066000 	add	x0, x0, #0x198
ffff00000008b0c4:	97ffd5fa 	bl	ffff0000000808ac <printk>
        ASSERT(0);
ffff00000008b0c8:	d2801b01 	mov	x1, #0xd8                  	// #216
ffff00000008b0cc:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b0d0:	91062000 	add	x0, x0, #0x188
ffff00000008b0d4:	97ffd6cc 	bl	ffff000000080c04 <error_check>
    }
}
ffff00000008b0d8:	d503201f 	nop
ffff00000008b0dc:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008b0e0:	d65f03c0 	ret

ffff00000008b0e4 <get_pc>:
static struct ProcessControl pc;
void pstart(struct TrapFrame *tf);

struct ProcessControl* get_pc(void)
{
    return &pc;
ffff00000008b0e4:	f0000000 	adrp	x0, ffff00000008e000 <process_table+0x1d0>
ffff00000008b0e8:	91018000 	add	x0, x0, #0x60
}
ffff00000008b0ec:	d65f03c0 	ret

ffff00000008b0f0 <find_unused_process>:

static struct Process* find_unused_process(void)
{
ffff00000008b0f0:	d10043ff 	sub	sp, sp, #0x10
    struct Process *process = NULL;
ffff00000008b0f4:	f90007ff 	str	xzr, [sp, #8]

    for (int i = 0; i < NUM_PROC; i++) {
ffff00000008b0f8:	b90007ff 	str	wzr, [sp, #4]
ffff00000008b0fc:	14000019 	b	ffff00000008b160 <find_unused_process+0x70>
        if (process_table[i].state == PROC_UNUSED) {
ffff00000008b100:	d0000000 	adrp	x0, ffff00000008d000 <_binary_user_bin_start+0x200>
ffff00000008b104:	9138c002 	add	x2, x0, #0xe30
ffff00000008b108:	b98007e1 	ldrsw	x1, [sp, #4]
ffff00000008b10c:	aa0103e0 	mov	x0, x1
ffff00000008b110:	d37df000 	lsl	x0, x0, #3
ffff00000008b114:	cb010000 	sub	x0, x0, x1
ffff00000008b118:	d37df000 	lsl	x0, x0, #3
ffff00000008b11c:	8b000040 	add	x0, x2, x0
ffff00000008b120:	b9400c00 	ldr	w0, [x0, #12]
ffff00000008b124:	7100001f 	cmp	w0, #0x0
ffff00000008b128:	54000161 	b.ne	ffff00000008b154 <find_unused_process+0x64>  // b.any
            process = &process_table[i];
ffff00000008b12c:	b98007e1 	ldrsw	x1, [sp, #4]
ffff00000008b130:	aa0103e0 	mov	x0, x1
ffff00000008b134:	d37df000 	lsl	x0, x0, #3
ffff00000008b138:	cb010000 	sub	x0, x0, x1
ffff00000008b13c:	d37df000 	lsl	x0, x0, #3
ffff00000008b140:	d0000001 	adrp	x1, ffff00000008d000 <_binary_user_bin_start+0x200>
ffff00000008b144:	9138c021 	add	x1, x1, #0xe30
ffff00000008b148:	8b010000 	add	x0, x0, x1
ffff00000008b14c:	f90007e0 	str	x0, [sp, #8]
            break;
ffff00000008b150:	14000007 	b	ffff00000008b16c <find_unused_process+0x7c>
    for (int i = 0; i < NUM_PROC; i++) {
ffff00000008b154:	b94007e0 	ldr	w0, [sp, #4]
ffff00000008b158:	11000400 	add	w0, w0, #0x1
ffff00000008b15c:	b90007e0 	str	w0, [sp, #4]
ffff00000008b160:	b94007e0 	ldr	w0, [sp, #4]
ffff00000008b164:	7100241f 	cmp	w0, #0x9
ffff00000008b168:	54fffccd 	b.le	ffff00000008b100 <find_unused_process+0x10>
        }
    }

    return process;
ffff00000008b16c:	f94007e0 	ldr	x0, [sp, #8]
}
ffff00000008b170:	910043ff 	add	sp, sp, #0x10
ffff00000008b174:	d65f03c0 	ret

ffff00000008b178 <idle_thread>:
 void idle_thread(void)
{
ffff00000008b178:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffff00000008b17c:	910003fd 	mov	x29, sp
  
    for (;;) {
        printk("idle_thread\r\n");
ffff00000008b180:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b184:	9106c000 	add	x0, x0, #0x1b0
ffff00000008b188:	97ffd5c9 	bl	ffff0000000808ac <printk>
       schedule();     // 有 ready 进程就切走
ffff00000008b18c:	94000276 	bl	ffff00000008bb64 <schedule>
    for (;;) {
ffff00000008b190:	17fffffc 	b	ffff00000008b180 <idle_thread+0x8>

ffff00000008b194 <init_idle_process>:
    }
}

 void init_idle_process(void)
{
ffff00000008b194:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008b198:	910003fd 	mov	x29, sp
    struct Process *process;
    struct ProcessControl *process_control;
    struct HeadList *list;

    process = find_unused_process();
ffff00000008b19c:	97ffffd5 	bl	ffff00000008b0f0 <find_unused_process>
ffff00000008b1a0:	f9000fe0 	str	x0, [sp, #24]
    ASSERT(process == &process_table[0]);
ffff00000008b1a4:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008b1a8:	d0000000 	adrp	x0, ffff00000008d000 <_binary_user_bin_start+0x200>
ffff00000008b1ac:	9138c000 	add	x0, x0, #0xe30
ffff00000008b1b0:	eb00003f 	cmp	x1, x0
ffff00000008b1b4:	540000a0 	b.eq	ffff00000008b1c8 <init_idle_process+0x34>  // b.none
ffff00000008b1b8:	d2800641 	mov	x1, #0x32                  	// #50
ffff00000008b1bc:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b1c0:	91070000 	add	x0, x0, #0x1c0
ffff00000008b1c4:	97ffd690 	bl	ffff000000080c04 <error_check>

    process->state = PROC_RUNNING;
ffff00000008b1c8:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b1cc:	52800041 	mov	w1, #0x2                   	// #2
ffff00000008b1d0:	b9000c01 	str	w1, [x0, #12]
    process->pid = 0;
ffff00000008b1d4:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b1d8:	b900081f 	str	wzr, [x0, #8]
    //process->page_map = P2V(read_pgd());
    
    // 1. 给 idle 分配 kernel stack
    process->stack = (uint64_t)kalloc();
ffff00000008b1dc:	97fffbd7 	bl	ffff00000008a138 <kalloc>
ffff00000008b1e0:	aa0003e1 	mov	x1, x0
ffff00000008b1e4:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b1e8:	f9001401 	str	x1, [x0, #40]
    ASSERT(process->stack != 0);
ffff00000008b1ec:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b1f0:	f9401400 	ldr	x0, [x0, #40]
ffff00000008b1f4:	f100001f 	cmp	x0, #0x0
ffff00000008b1f8:	540000a1 	b.ne	ffff00000008b20c <init_idle_process+0x78>  // b.any
ffff00000008b1fc:	d2800741 	mov	x1, #0x3a                  	// #58
ffff00000008b200:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b204:	91070000 	add	x0, x0, #0x1c0
ffff00000008b208:	97ffd67f 	bl	ffff000000080c04 <error_check>
    memset((void*)process->stack, 0, PAGE_SIZE);
ffff00000008b20c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b210:	f9401400 	ldr	x0, [x0, #40]
ffff00000008b214:	52a00402 	mov	w2, #0x200000              	// #2097152
ffff00000008b218:	52800001 	mov	w1, #0x0                   	// #0
ffff00000008b21c:	97ffd3ce 	bl	ffff000000080154 <memset>

    // 2. 构造 kernel context (x19..x30)
    process->context =process->stack + PAGE_SIZE - sizeof(struct TrapFrame) - 12*8;
ffff00000008b220:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b224:	f9401401 	ldr	x1, [x0, #40]
ffff00000008b228:	d29fd000 	mov	x0, #0xfe80                	// #65152
ffff00000008b22c:	f2a003e0 	movk	x0, #0x1f, lsl #16
ffff00000008b230:	8b000021 	add	x1, x1, x0
ffff00000008b234:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b238:	f9000c01 	str	x1, [x0, #24]


    // 3. 第一次调度进来时从 idle_thread 开始执行
    *(uint64_t*)(process->context + 11*8) = (uint64_t)idle_thread;
ffff00000008b23c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b240:	f9400c00 	ldr	x0, [x0, #24]
ffff00000008b244:	91016000 	add	x0, x0, #0x58
ffff00000008b248:	aa0003e1 	mov	x1, x0
ffff00000008b24c:	90000000 	adrp	x0, ffff00000008b000 <load_file+0x18>
ffff00000008b250:	9105e000 	add	x0, x0, #0x178
ffff00000008b254:	f9000020 	str	x0, [x1]

    // 4. trapframe（可选，但推荐）
    process->tf = (struct TrapFrame*)(process->stack + PAGE_SIZE - sizeof(struct TrapFrame));
ffff00000008b258:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b25c:	f9401401 	ldr	x1, [x0, #40]
ffff00000008b260:	d29fdc00 	mov	x0, #0xfee0                	// #65248
ffff00000008b264:	f2a003e0 	movk	x0, #0x1f, lsl #16
ffff00000008b268:	8b000020 	add	x0, x1, x0
ffff00000008b26c:	aa0003e1 	mov	x1, x0
ffff00000008b270:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b274:	f9001801 	str	x1, [x0, #48]
   memset(process->tf, 0, sizeof(*process->tf));
ffff00000008b278:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b27c:	f9401800 	ldr	x0, [x0, #48]
ffff00000008b280:	52802402 	mov	w2, #0x120                 	// #288
ffff00000008b284:	52800001 	mov	w1, #0x0                   	// #0
ffff00000008b288:	97ffd3b3 	bl	ffff000000080154 <memset>

    // 5. idle 使用 kernel 页表（不要 read_pgd）
    process->page_map = kernel_pgd;
ffff00000008b28c:	d0000000 	adrp	x0, ffff00000008d000 <_binary_user_bin_start+0x200>
ffff00000008b290:	f946f000 	ldr	x0, [x0, #3552]
ffff00000008b294:	f9400001 	ldr	x1, [x0]
ffff00000008b298:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b29c:	f9001001 	str	x1, [x0, #32]
   
  

    process_control = get_pc();
ffff00000008b2a0:	97ffff91 	bl	ffff00000008b0e4 <get_pc>
ffff00000008b2a4:	f9000be0 	str	x0, [sp, #16]
    process_control->current_process = process;
ffff00000008b2a8:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008b2ac:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008b2b0:	f9000001 	str	x1, [x0]
    //printk("idle: stack=%x tf=%x ctx=%x lr(slot)=%x pgd=%x\n",process->stack,(uint64_t)process->tf,process->context,*(uint64_t*)(process->context + 88),process->page_map);
   // list = &process_control->ready_list;
   // process->state = PROC_READY;
   // append_list_tail(list, (struct List*)process);
}
ffff00000008b2b4:	d503201f 	nop
ffff00000008b2b8:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008b2bc:	d65f03c0 	ret

ffff00000008b2c0 <alloc_new_process>:

static struct Process* alloc_new_process(void)
{
ffff00000008b2c0:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008b2c4:	910003fd 	mov	x29, sp
    struct Process *process;

    process = find_unused_process();
ffff00000008b2c8:	97ffff8a 	bl	ffff00000008b0f0 <find_unused_process>
ffff00000008b2cc:	f9000fe0 	str	x0, [sp, #24]
    ASSERT(process == &process_table[1]);
ffff00000008b2d0:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008b2d4:	d0000000 	adrp	x0, ffff00000008d000 <_binary_user_bin_start+0x200>
ffff00000008b2d8:	9139a000 	add	x0, x0, #0xe68
ffff00000008b2dc:	eb00003f 	cmp	x1, x0
ffff00000008b2e0:	540000a0 	b.eq	ffff00000008b2f4 <alloc_new_process+0x34>  // b.none
ffff00000008b2e4:	d2800b41 	mov	x1, #0x5a                  	// #90
ffff00000008b2e8:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b2ec:	91070000 	add	x0, x0, #0x1c0
ffff00000008b2f0:	97ffd645 	bl	ffff000000080c04 <error_check>

    process->stack = (uint64_t)kalloc();
ffff00000008b2f4:	97fffb91 	bl	ffff00000008a138 <kalloc>
ffff00000008b2f8:	aa0003e1 	mov	x1, x0
ffff00000008b2fc:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b300:	f9001401 	str	x1, [x0, #40]
    ASSERT(process->stack != 0);
ffff00000008b304:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b308:	f9401400 	ldr	x0, [x0, #40]
ffff00000008b30c:	f100001f 	cmp	x0, #0x0
ffff00000008b310:	540000a1 	b.ne	ffff00000008b324 <alloc_new_process+0x64>  // b.any
ffff00000008b314:	d2800ba1 	mov	x1, #0x5d                  	// #93
ffff00000008b318:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b31c:	91070000 	add	x0, x0, #0x1c0
ffff00000008b320:	97ffd639 	bl	ffff000000080c04 <error_check>
    memset((void*)process->stack, 0, PAGE_SIZE);
ffff00000008b324:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b328:	f9401400 	ldr	x0, [x0, #40]
ffff00000008b32c:	52a00402 	mov	w2, #0x200000              	// #2097152
ffff00000008b330:	52800001 	mov	w1, #0x0                   	// #0
ffff00000008b334:	97ffd388 	bl	ffff000000080154 <memset>

    process->state = PROC_INIT;
ffff00000008b338:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b33c:	52800021 	mov	w1, #0x1                   	// #1
ffff00000008b340:	b9000c01 	str	w1, [x0, #12]
    process->pid = pid_num++;
ffff00000008b344:	d0000000 	adrp	x0, ffff00000008d000 <_binary_user_bin_start+0x200>
ffff00000008b348:	9136e000 	add	x0, x0, #0xdb8
ffff00000008b34c:	b9400000 	ldr	w0, [x0]
ffff00000008b350:	11000402 	add	w2, w0, #0x1
ffff00000008b354:	d0000001 	adrp	x1, ffff00000008d000 <_binary_user_bin_start+0x200>
ffff00000008b358:	9136e021 	add	x1, x1, #0xdb8
ffff00000008b35c:	b9000022 	str	w2, [x1]
ffff00000008b360:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008b364:	b9000820 	str	w0, [x1, #8]


    // ret-> context  ; eret(el1->el0) ->tf
    process->context = process->stack + PAGE_SIZE - sizeof(struct TrapFrame) - 12*8;
ffff00000008b368:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b36c:	f9401401 	ldr	x1, [x0, #40]
ffff00000008b370:	d29fd000 	mov	x0, #0xfe80                	// #65152
ffff00000008b374:	f2a003e0 	movk	x0, #0x1f, lsl #16
ffff00000008b378:	8b000021 	add	x1, x1, x0
ffff00000008b37c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b380:	f9000c01 	str	x1, [x0, #24]
    *(uint64_t*)(process->context + 11*8) = (uint64_t)trap_return;
ffff00000008b384:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b388:	f9400c00 	ldr	x0, [x0, #24]
ffff00000008b38c:	91016000 	add	x0, x0, #0x58
ffff00000008b390:	aa0003e1 	mov	x1, x0
ffff00000008b394:	d0000000 	adrp	x0, ffff00000008d000 <_binary_user_bin_start+0x200>
ffff00000008b398:	f946ec00 	ldr	x0, [x0, #3544]
ffff00000008b39c:	f9000020 	str	x0, [x1]
    process->tf = (struct TrapFrame*)(process->stack + PAGE_SIZE - sizeof(struct TrapFrame));
ffff00000008b3a0:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b3a4:	f9401401 	ldr	x1, [x0, #40]
ffff00000008b3a8:	d29fdc00 	mov	x0, #0xfee0                	// #65248
ffff00000008b3ac:	f2a003e0 	movk	x0, #0x1f, lsl #16
ffff00000008b3b0:	8b000020 	add	x0, x1, x0
ffff00000008b3b4:	aa0003e1 	mov	x1, x0
ffff00000008b3b8:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b3bc:	f9001801 	str	x1, [x0, #48]
    process->tf->elr = 0x400000;
ffff00000008b3c0:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b3c4:	f9401800 	ldr	x0, [x0, #48]
ffff00000008b3c8:	d2a00801 	mov	x1, #0x400000              	// #4194304
ffff00000008b3cc:	f9008801 	str	x1, [x0, #272]
    process->tf->sp0 = 0x400000 + PAGE_SIZE;
ffff00000008b3d0:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b3d4:	f9401800 	ldr	x0, [x0, #48]
ffff00000008b3d8:	d2a00c01 	mov	x1, #0x600000              	// #6291456
ffff00000008b3dc:	f9007c01 	str	x1, [x0, #248]
    process->tf->spsr = 0;
ffff00000008b3e0:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b3e4:	f9401800 	ldr	x0, [x0, #48]
ffff00000008b3e8:	f9008c1f 	str	xzr, [x0, #280]

    process->page_map = (uint64_t)kalloc();
ffff00000008b3ec:	97fffb53 	bl	ffff00000008a138 <kalloc>
ffff00000008b3f0:	aa0003e1 	mov	x1, x0
ffff00000008b3f4:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b3f8:	f9001001 	str	x1, [x0, #32]
    ASSERT(process->page_map != 0);
ffff00000008b3fc:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b400:	f9401000 	ldr	x0, [x0, #32]
ffff00000008b404:	f100001f 	cmp	x0, #0x0
ffff00000008b408:	540000a1 	b.ne	ffff00000008b41c <alloc_new_process+0x15c>  // b.any
ffff00000008b40c:	d2800da1 	mov	x1, #0x6d                  	// #109
ffff00000008b410:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b414:	91070000 	add	x0, x0, #0x1c0
ffff00000008b418:	97ffd5fb 	bl	ffff000000080c04 <error_check>
    memset((void*)process->page_map, 0, PAGE_SIZE);
ffff00000008b41c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b420:	f9401000 	ldr	x0, [x0, #32]
ffff00000008b424:	52a00402 	mov	w2, #0x200000              	// #2097152
ffff00000008b428:	52800001 	mov	w1, #0x0                   	// #0
ffff00000008b42c:	97ffd34a 	bl	ffff000000080154 <memset>

    return process;
ffff00000008b430:	f9400fe0 	ldr	x0, [sp, #24]
}
ffff00000008b434:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008b438:	d65f03c0 	ret

ffff00000008b43c <init_user_process>:

static void init_user_process(void)
{
ffff00000008b43c:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008b440:	910003fd 	mov	x29, sp
    struct Process *process;
    struct ProcessControl *process_control;
    struct HeadList *list;

    process = alloc_new_process();
ffff00000008b444:	97ffff9f 	bl	ffff00000008b2c0 <alloc_new_process>
ffff00000008b448:	f90017e0 	str	x0, [sp, #40]
    ASSERT(process != NULL);
ffff00000008b44c:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b450:	f100001f 	cmp	x0, #0x0
ffff00000008b454:	540000a1 	b.ne	ffff00000008b468 <init_user_process+0x2c>  // b.any
ffff00000008b458:	d2800f41 	mov	x1, #0x7a                  	// #122
ffff00000008b45c:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b460:	91070000 	add	x0, x0, #0x1c0
ffff00000008b464:	97ffd5e8 	bl	ffff000000080c04 <error_check>

    ASSERT(setup_uvm((uint64_t)process->page_map, "INIT.BIN"));
ffff00000008b468:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b46c:	f9401002 	ldr	x2, [x0, #32]
ffff00000008b470:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b474:	91074001 	add	x1, x0, #0x1d0
ffff00000008b478:	aa0203e0 	mov	x0, x2
ffff00000008b47c:	97fffd0a 	bl	ffff00000008a8a4 <setup_uvm>
ffff00000008b480:	12001c00 	and	w0, w0, #0xff
ffff00000008b484:	52000000 	eor	w0, w0, #0x1
ffff00000008b488:	12001c00 	and	w0, w0, #0xff
ffff00000008b48c:	7100001f 	cmp	w0, #0x0
ffff00000008b490:	540000a0 	b.eq	ffff00000008b4a4 <init_user_process+0x68>  // b.none
ffff00000008b494:	d2800f81 	mov	x1, #0x7c                  	// #124
ffff00000008b498:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b49c:	91070000 	add	x0, x0, #0x1c0
ffff00000008b4a0:	97ffd5d9 	bl	ffff000000080c04 <error_check>

    process_control = get_pc();
ffff00000008b4a4:	97ffff10 	bl	ffff00000008b0e4 <get_pc>
ffff00000008b4a8:	f90013e0 	str	x0, [sp, #32]
    list = &process_control->ready_list;
ffff00000008b4ac:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008b4b0:	91002000 	add	x0, x0, #0x8
ffff00000008b4b4:	f9000fe0 	str	x0, [sp, #24]

    process->state = PROC_READY;
ffff00000008b4b8:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b4bc:	52800061 	mov	w1, #0x3                   	// #3
ffff00000008b4c0:	b9000c01 	str	w1, [x0, #12]
    append_list_tail(list, (struct List*)process);
ffff00000008b4c4:	f94017e1 	ldr	x1, [sp, #40]
ffff00000008b4c8:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b4cc:	97ffd346 	bl	ffff0000000801e4 <append_list_tail>
}
ffff00000008b4d0:	d503201f 	nop
ffff00000008b4d4:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff00000008b4d8:	d65f03c0 	ret

ffff00000008b4dc <alloc_new_process2>:

static struct Process* alloc_new_process2(void (*fn)(void))
{
ffff00000008b4dc:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008b4e0:	910003fd 	mov	x29, sp
ffff00000008b4e4:	f9000fe0 	str	x0, [sp, #24]
    struct Process *process;

    process = find_unused_process();
ffff00000008b4e8:	97ffff02 	bl	ffff00000008b0f0 <find_unused_process>
ffff00000008b4ec:	f90017e0 	str	x0, [sp, #40]
    ASSERT(process != NULL);
ffff00000008b4f0:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b4f4:	f100001f 	cmp	x0, #0x0
ffff00000008b4f8:	540000a1 	b.ne	ffff00000008b50c <alloc_new_process2+0x30>  // b.any
ffff00000008b4fc:	d2801141 	mov	x1, #0x8a                  	// #138
ffff00000008b500:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b504:	91070000 	add	x0, x0, #0x1c0
ffff00000008b508:	97ffd5bf 	bl	ffff000000080c04 <error_check>

    // kernel stack
    process->stack = (uint64_t)kalloc();
ffff00000008b50c:	97fffb0b 	bl	ffff00000008a138 <kalloc>
ffff00000008b510:	aa0003e1 	mov	x1, x0
ffff00000008b514:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b518:	f9001401 	str	x1, [x0, #40]
    ASSERT(process->stack != 0);
ffff00000008b51c:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b520:	f9401400 	ldr	x0, [x0, #40]
ffff00000008b524:	f100001f 	cmp	x0, #0x0
ffff00000008b528:	540000a1 	b.ne	ffff00000008b53c <alloc_new_process2+0x60>  // b.any
ffff00000008b52c:	d28011c1 	mov	x1, #0x8e                  	// #142
ffff00000008b530:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b534:	91070000 	add	x0, x0, #0x1c0
ffff00000008b538:	97ffd5b3 	bl	ffff000000080c04 <error_check>
    memset((void*)process->stack, 0, PAGE_SIZE);
ffff00000008b53c:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b540:	f9401400 	ldr	x0, [x0, #40]
ffff00000008b544:	52a00402 	mov	w2, #0x200000              	// #2097152
ffff00000008b548:	52800001 	mov	w1, #0x0                   	// #0
ffff00000008b54c:	97ffd302 	bl	ffff000000080154 <memset>

    process->state = PROC_INIT;
ffff00000008b550:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b554:	52800021 	mov	w1, #0x1                   	// #1
ffff00000008b558:	b9000c01 	str	w1, [x0, #12]
    process->pid = pid_num++;
ffff00000008b55c:	d0000000 	adrp	x0, ffff00000008d000 <_binary_user_bin_start+0x200>
ffff00000008b560:	9136e000 	add	x0, x0, #0xdb8
ffff00000008b564:	b9400000 	ldr	w0, [x0]
ffff00000008b568:	11000402 	add	w2, w0, #0x1
ffff00000008b56c:	d0000001 	adrp	x1, ffff00000008d000 <_binary_user_bin_start+0x200>
ffff00000008b570:	9136e021 	add	x1, x1, #0xdb8
ffff00000008b574:	b9000022 	str	w2, [x1]
ffff00000008b578:	f94017e1 	ldr	x1, [sp, #40]
ffff00000008b57c:	b9000820 	str	w0, [x1, #8]
    /*
     * kernel context:
     * x19..x30 (12 regs)
     */
    process->context =process->stack + PAGE_SIZE - sizeof(struct TrapFrame) - 12*8;

ffff00000008b580:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b584:	f9401401 	ldr	x1, [x0, #40]
ffff00000008b588:	d29fd000 	mov	x0, #0xfe80                	// #65152
ffff00000008b58c:	f2a003e0 	movk	x0, #0x1f, lsl #16
ffff00000008b590:	8b000021 	add	x1, x1, x0
    process->context =process->stack + PAGE_SIZE - sizeof(struct TrapFrame) - 12*8;
ffff00000008b594:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b598:	f9000c01 	str	x1, [x0, #24]
    // return to trap_return when scheduled first time
    *(uint64_t*)(process->context + 11*8) = (uint64_t)fn;

ffff00000008b59c:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b5a0:	f9400c00 	ldr	x0, [x0, #24]
ffff00000008b5a4:	91016000 	add	x0, x0, #0x58
ffff00000008b5a8:	aa0003e1 	mov	x1, x0
ffff00000008b5ac:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b5b0:	f9000020 	str	x0, [x1]
    // kernel trapframe
    process->tf =(struct TrapFrame*)(process->stack + PAGE_SIZE - sizeof(struct TrapFrame));

ffff00000008b5b4:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b5b8:	f9401401 	ldr	x1, [x0, #40]
ffff00000008b5bc:	d29fdc00 	mov	x0, #0xfee0                	// #65248
ffff00000008b5c0:	f2a003e0 	movk	x0, #0x1f, lsl #16
ffff00000008b5c4:	8b000020 	add	x0, x1, x0
ffff00000008b5c8:	aa0003e1 	mov	x1, x0
ffff00000008b5cc:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b5d0:	f9001801 	str	x1, [x0, #48]
    memset(process->tf, 0, sizeof(*process->tf));

ffff00000008b5d4:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b5d8:	f9401800 	ldr	x0, [x0, #48]
ffff00000008b5dc:	52802402 	mov	w2, #0x120                 	// #288
ffff00000008b5e0:	52800001 	mov	w1, #0x0                   	// #0
ffff00000008b5e4:	97ffd2dc 	bl	ffff000000080154 <memset>
     */


    // kernel page table for now
    process->page_map = kernel_pgd;

ffff00000008b5e8:	d0000000 	adrp	x0, ffff00000008d000 <_binary_user_bin_start+0x200>
ffff00000008b5ec:	f946f000 	ldr	x0, [x0, #3552]
ffff00000008b5f0:	f9400001 	ldr	x1, [x0]
ffff00000008b5f4:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b5f8:	f9001001 	str	x1, [x0, #32]
    return process;
}
ffff00000008b5fc:	f94017e0 	ldr	x0, [sp, #40]
static void create_kernel_process(void (*fn)(void))
ffff00000008b600:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff00000008b604:	d65f03c0 	ret

ffff00000008b608 <create_kernel_process>:
{
    struct Process *process;
ffff00000008b608:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff00000008b60c:	910003fd 	mov	x29, sp
ffff00000008b610:	f9000fe0 	str	x0, [sp, #24]
    struct ProcessControl *process_control;
    struct HeadList *list;

    process = alloc_new_process2(fn);
    ASSERT(process != NULL);
ffff00000008b614:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b618:	97ffffb1 	bl	ffff00000008b4dc <alloc_new_process2>
ffff00000008b61c:	f9001fe0 	str	x0, [sp, #56]

ffff00000008b620:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008b624:	f100001f 	cmp	x0, #0x0
ffff00000008b628:	540000a1 	b.ne	ffff00000008b63c <create_kernel_process+0x34>  // b.any
ffff00000008b62c:	d28016c1 	mov	x1, #0xb6                  	// #182
ffff00000008b630:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b634:	91070000 	add	x0, x0, #0x1c0
ffff00000008b638:	97ffd573 	bl	ffff000000080c04 <error_check>
   // ASSERT(setup_uvm((uint64_t)process->page_map, "init.bin"));

    process_control = get_pc();
    list = &process_control->ready_list;
ffff00000008b63c:	97fffeaa 	bl	ffff00000008b0e4 <get_pc>
ffff00000008b640:	f9001be0 	str	x0, [sp, #48]

ffff00000008b644:	f9401be0 	ldr	x0, [sp, #48]
ffff00000008b648:	91002000 	add	x0, x0, #0x8
ffff00000008b64c:	f90017e0 	str	x0, [sp, #40]
    process->state = PROC_READY;
    append_list_tail(list, (struct List*)process);
ffff00000008b650:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008b654:	52800061 	mov	w1, #0x3                   	// #3
ffff00000008b658:	b9000c01 	str	w1, [x0, #12]
    printk("user1: stack=%x tf=%x ctx=%x pgd=%x\n", 
ffff00000008b65c:	f9401fe1 	ldr	x1, [sp, #56]
ffff00000008b660:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b664:	97ffd2e0 	bl	ffff0000000801e4 <append_list_tail>
    process->stack, (uint64_t)process->tf, process->context, process->page_map);
ffff00000008b668:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008b66c:	f9401401 	ldr	x1, [x0, #40]
}
ffff00000008b670:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008b674:	f9401800 	ldr	x0, [x0, #48]
    process->stack, (uint64_t)process->tf, process->context, process->page_map);
ffff00000008b678:	aa0003e5 	mov	x5, x0
ffff00000008b67c:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008b680:	f9400c02 	ldr	x2, [x0, #24]
ffff00000008b684:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008b688:	f9401000 	ldr	x0, [x0, #32]
ffff00000008b68c:	aa0003e4 	mov	x4, x0
ffff00000008b690:	aa0203e3 	mov	x3, x2
ffff00000008b694:	aa0503e2 	mov	x2, x5
ffff00000008b698:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b69c:	91078000 	add	x0, x0, #0x1e0
ffff00000008b6a0:	97ffd483 	bl	ffff0000000808ac <printk>

ffff00000008b6a4:	d503201f 	nop
ffff00000008b6a8:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff00000008b6ac:	d65f03c0 	ret

ffff00000008b6b0 <set_ttbr0>:

static inline void set_ttbr0(uint64_t pgd_va)
{
    uint64_t pgd_pa = V2P(pgd_va);
ffff00000008b6b0:	d10083ff 	sub	sp, sp, #0x20
ffff00000008b6b4:	f90007e0 	str	x0, [sp, #8]
    __asm__ volatile(
ffff00000008b6b8:	f94007e1 	ldr	x1, [sp, #8]
ffff00000008b6bc:	d2e00020 	mov	x0, #0x1000000000000       	// #281474976710656
ffff00000008b6c0:	8b000020 	add	x0, x1, x0
ffff00000008b6c4:	f9000fe0 	str	x0, [sp, #24]
        "dsb ish\n"
ffff00000008b6c8:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b6cc:	d5033b9f 	dsb	ish
ffff00000008b6d0:	d5182000 	msr	ttbr0_el1, x0
ffff00000008b6d4:	d508831f 	tlbi	vmalle1is
ffff00000008b6d8:	d5033b9f 	dsb	ish
ffff00000008b6dc:	d5033fdf 	isb
        :
        : "r"(pgd_pa)
        : "memory"
    );
}

ffff00000008b6e0:	d503201f 	nop
ffff00000008b6e4:	910083ff 	add	sp, sp, #0x20
ffff00000008b6e8:	d65f03c0 	ret

ffff00000008b6ec <move_to_user_mode>:

void move_to_user_mode(struct Process *p)
{
      struct Process *process;
ffff00000008b6ec:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008b6f0:	910003fd 	mov	x29, sp
ffff00000008b6f4:	f9000fe0 	str	x0, [sp, #24]
    struct ProcessControl *process_control;
    struct HeadList *list;
    p->page_map = (uint64_t)kalloc();
    memset((void*)p->page_map, 0, PAGE_SIZE);
ffff00000008b6f8:	97fffa90 	bl	ffff00000008a138 <kalloc>
ffff00000008b6fc:	aa0003e1 	mov	x1, x0
ffff00000008b700:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b704:	f9001001 	str	x1, [x0, #32]

ffff00000008b708:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b70c:	f9401000 	ldr	x0, [x0, #32]
ffff00000008b710:	52a00402 	mov	w2, #0x200000              	// #2097152
ffff00000008b714:	52800001 	mov	w1, #0x0                   	// #0
ffff00000008b718:	97ffd28f 	bl	ffff000000080154 <memset>
    uint64_t stack_top = p->stack + PAGE_SIZE;
    p->tf = (struct TrapFrame *)(stack_top - sizeof(struct TrapFrame));
ffff00000008b71c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b720:	f9401400 	ldr	x0, [x0, #40]
ffff00000008b724:	91480000 	add	x0, x0, #0x200, lsl #12
ffff00000008b728:	f90017e0 	str	x0, [sp, #40]
    memset(p->tf, 0, sizeof(*p->tf));
ffff00000008b72c:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b730:	d1048000 	sub	x0, x0, #0x120
ffff00000008b734:	aa0003e1 	mov	x1, x0
ffff00000008b738:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b73c:	f9001801 	str	x1, [x0, #48]
    p->tf->elr  = 0x400000;
ffff00000008b740:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b744:	f9401800 	ldr	x0, [x0, #48]
ffff00000008b748:	52802402 	mov	w2, #0x120                 	// #288
ffff00000008b74c:	52800001 	mov	w1, #0x0                   	// #0
ffff00000008b750:	97ffd281 	bl	ffff000000080154 <memset>
    p->tf->sp0  = 0x400000 + PAGE_SIZE;
ffff00000008b754:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b758:	f9401800 	ldr	x0, [x0, #48]
ffff00000008b75c:	d2a00801 	mov	x1, #0x400000              	// #4194304
ffff00000008b760:	f9008801 	str	x1, [x0, #272]
    p->tf->spsr = 0;
ffff00000008b764:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b768:	f9401800 	ldr	x0, [x0, #48]
ffff00000008b76c:	d2a00c01 	mov	x1, #0x600000              	// #6291456
ffff00000008b770:	f9007c01 	str	x1, [x0, #248]

ffff00000008b774:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b778:	f9401800 	ldr	x0, [x0, #48]
ffff00000008b77c:	f9008c1f 	str	xzr, [x0, #280]

  

    ASSERT(setup_uvm(p->page_map, "USER.BIN"));
    set_ttbr0(p->page_map);
ffff00000008b780:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b784:	f9401002 	ldr	x2, [x0, #32]
ffff00000008b788:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b78c:	91082001 	add	x1, x0, #0x208
ffff00000008b790:	aa0203e0 	mov	x0, x2
ffff00000008b794:	97fffc44 	bl	ffff00000008a8a4 <setup_uvm>
ffff00000008b798:	12001c00 	and	w0, w0, #0xff
ffff00000008b79c:	52000000 	eor	w0, w0, #0x1
ffff00000008b7a0:	12001c00 	and	w0, w0, #0xff
ffff00000008b7a4:	7100001f 	cmp	w0, #0x0
ffff00000008b7a8:	540000a0 	b.eq	ffff00000008b7bc <move_to_user_mode+0xd0>  // b.none
ffff00000008b7ac:	d2801cc1 	mov	x1, #0xe6                  	// #230
ffff00000008b7b0:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b7b4:	91070000 	add	x0, x0, #0x1c0
ffff00000008b7b8:	97ffd513 	bl	ffff000000080c04 <error_check>
    enter_user(p->tf);
ffff00000008b7bc:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b7c0:	f9401000 	ldr	x0, [x0, #32]
ffff00000008b7c4:	97ffffbb 	bl	ffff00000008b6b0 <set_ttbr0>
    // 5) 让该进程下一次被调度时走 trap_return -> eret
ffff00000008b7c8:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b7cc:	f9401800 	ldr	x0, [x0, #48]
ffff00000008b7d0:	97ffd804 	bl	ffff0000000817e0 <enter_user>

ffff00000008b7d4 <kthread1>:



void kthread1(void)
{
    printk("kthread1 start\n");
ffff00000008b7d4:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffff00000008b7d8:	910003fd 	mov	x29, sp

ffff00000008b7dc:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b7e0:	91086000 	add	x0, x0, #0x218
ffff00000008b7e4:	97ffd432 	bl	ffff0000000808ac <printk>
    move_to_user_mode(get_pc()->current_process);

ffff00000008b7e8:	97fffe3f 	bl	ffff00000008b0e4 <get_pc>
ffff00000008b7ec:	f9400000 	ldr	x0, [x0]
ffff00000008b7f0:	97ffffbf 	bl	ffff00000008b6ec <move_to_user_mode>
 

    // 永远不会再回来
    //while (1);
}
void init_process(void)
ffff00000008b7f4:	d503201f 	nop
ffff00000008b7f8:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffff00000008b7fc:	d65f03c0 	ret

ffff00000008b800 <init_process>:
{
    init_idle_process();
ffff00000008b800:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffff00000008b804:	910003fd 	mov	x29, sp
    init_user_process();
ffff00000008b808:	97fffe63 	bl	ffff00000008b194 <init_idle_process>
    
ffff00000008b80c:	97ffff0c 	bl	ffff00000008b43c <init_user_process>
    create_kernel_process(kthread1);
   
ffff00000008b810:	90000000 	adrp	x0, ffff00000008b000 <load_file+0x18>
ffff00000008b814:	911f5000 	add	x0, x0, #0x7d4
ffff00000008b818:	97ffff7c 	bl	ffff00000008b608 <create_kernel_process>
}

ffff00000008b81c:	d503201f 	nop
ffff00000008b820:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffff00000008b824:	d65f03c0 	ret

ffff00000008b828 <switch_process>:
 void switch_process(struct Process *prev, struct Process *current)
{
   // printk("new current :id=%d, stack=%x ctx=%x pgd=%x\n", current->pid, current->stack, current->context, current->page_map);
ffff00000008b828:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008b82c:	910003fd 	mov	x29, sp
ffff00000008b830:	f9000fe0 	str	x0, [sp, #24]
ffff00000008b834:	f9000be1 	str	x1, [sp, #16]

    switch_vm(current->page_map);
  //  printk("before swap: prev pid=%d ,prev->context=%x next pid=%d next->context=%x\n",prev->pid, prev->context,current->pid, current->context);
ffff00000008b838:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008b83c:	f9401000 	ldr	x0, [x0, #32]
ffff00000008b840:	97fffc44 	bl	ffff00000008a950 <switch_vm>
    swap(&prev->context, current->context);
  //  printk("after swap: prev pid=%d prev->context=%x\n", prev->pid, prev->context);
ffff00000008b844:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b848:	91006002 	add	x2, x0, #0x18
ffff00000008b84c:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008b850:	f9400c00 	ldr	x0, [x0, #24]
ffff00000008b854:	aa0003e1 	mov	x1, x0
ffff00000008b858:	aa0203e0 	mov	x0, x2
ffff00000008b85c:	97ffd84a 	bl	ffff000000081984 <swap>
}

ffff00000008b860:	d503201f 	nop
ffff00000008b864:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008b868:	d65f03c0 	ret

ffff00000008b86c <dump_context>:
   void dump_context(const char *tag, struct Process *p)
{
    struct cpu_context *ctx;
ffff00000008b86c:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008b870:	910003fd 	mov	x29, sp
ffff00000008b874:	f9000fe0 	str	x0, [sp, #24]
ffff00000008b878:	f9000be1 	str	x1, [sp, #16]

    if (!p) {
        printk("[%s] process = NULL\n", tag);
ffff00000008b87c:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008b880:	f100001f 	cmp	x0, #0x0
ffff00000008b884:	540000c1 	b.ne	ffff00000008b89c <dump_context+0x30>  // b.any
        return;
ffff00000008b888:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008b88c:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b890:	9108a000 	add	x0, x0, #0x228
ffff00000008b894:	97ffd406 	bl	ffff0000000808ac <printk>
    }
ffff00000008b898:	1400007c 	b	ffff00000008ba88 <dump_context+0x21c>

    ctx = (struct cpu_context *)p->context;

ffff00000008b89c:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008b8a0:	f9400c00 	ldr	x0, [x0, #24]
ffff00000008b8a4:	f90017e0 	str	x0, [sp, #40]
    printk("[%s] pid=%d proc=%x\n", tag, p->pid, p);
    printk(" context addr = 0x%x\n", p->context);
ffff00000008b8a8:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008b8ac:	b9400800 	ldr	w0, [x0, #8]
ffff00000008b8b0:	f9400be3 	ldr	x3, [sp, #16]
ffff00000008b8b4:	2a0003e2 	mov	w2, w0
ffff00000008b8b8:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008b8bc:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b8c0:	91090000 	add	x0, x0, #0x240
ffff00000008b8c4:	97ffd3fa 	bl	ffff0000000808ac <printk>
    printk(" stack base = %x\n", p->stack);
ffff00000008b8c8:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008b8cc:	f9400c00 	ldr	x0, [x0, #24]
ffff00000008b8d0:	aa0003e1 	mov	x1, x0
ffff00000008b8d4:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b8d8:	91096000 	add	x0, x0, #0x258
ffff00000008b8dc:	97ffd3f4 	bl	ffff0000000808ac <printk>
    printk(" stack top  = %x\n", p->stack + PAGE_SIZE);
ffff00000008b8e0:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008b8e4:	f9401400 	ldr	x0, [x0, #40]
ffff00000008b8e8:	aa0003e1 	mov	x1, x0
ffff00000008b8ec:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b8f0:	9109c000 	add	x0, x0, #0x270
ffff00000008b8f4:	97ffd3ee 	bl	ffff0000000808ac <printk>
    printk(" context    = %x (size=%d)\n",p->context, sizeof(struct cpu_context));
ffff00000008b8f8:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008b8fc:	f9401400 	ldr	x0, [x0, #40]
ffff00000008b900:	91480000 	add	x0, x0, #0x200, lsl #12
ffff00000008b904:	aa0003e1 	mov	x1, x0
ffff00000008b908:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b90c:	910a2000 	add	x0, x0, #0x288
ffff00000008b910:	97ffd3e7 	bl	ffff0000000808ac <printk>
    printk(" trapframe  = %x (size=%d)\n",p->tf, sizeof(struct TrapFrame));
ffff00000008b914:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008b918:	f9400c00 	ldr	x0, [x0, #24]
ffff00000008b91c:	d2800c02 	mov	x2, #0x60                  	// #96
ffff00000008b920:	aa0003e1 	mov	x1, x0
ffff00000008b924:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b928:	910a8000 	add	x0, x0, #0x2a0
ffff00000008b92c:	97ffd3e0 	bl	ffff0000000808ac <printk>

ffff00000008b930:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008b934:	f9401800 	ldr	x0, [x0, #48]
ffff00000008b938:	d2802402 	mov	x2, #0x120                 	// #288
ffff00000008b93c:	aa0003e1 	mov	x1, x0
ffff00000008b940:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b944:	910b0000 	add	x0, x0, #0x2c0
ffff00000008b948:	97ffd3d9 	bl	ffff0000000808ac <printk>
    if (!ctx) {
        printk("  context is NULL\n");
ffff00000008b94c:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b950:	f100001f 	cmp	x0, #0x0
ffff00000008b954:	540000a1 	b.ne	ffff00000008b968 <dump_context+0xfc>  // b.any
        return;
ffff00000008b958:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b95c:	910b8000 	add	x0, x0, #0x2e0
ffff00000008b960:	97ffd3d3 	bl	ffff0000000808ac <printk>
    }
ffff00000008b964:	14000049 	b	ffff00000008ba88 <dump_context+0x21c>

    printk("  x19 = 0x%x\n", ctx->x19);
    printk("  x20 = 0x%x\n", ctx->x20);
ffff00000008b968:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b96c:	f9400000 	ldr	x0, [x0]
ffff00000008b970:	aa0003e1 	mov	x1, x0
ffff00000008b974:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b978:	910be000 	add	x0, x0, #0x2f8
ffff00000008b97c:	97ffd3cc 	bl	ffff0000000808ac <printk>
    printk("  x21 = 0x%x\n", ctx->x21);
ffff00000008b980:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b984:	f9400400 	ldr	x0, [x0, #8]
ffff00000008b988:	aa0003e1 	mov	x1, x0
ffff00000008b98c:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b990:	910c2000 	add	x0, x0, #0x308
ffff00000008b994:	97ffd3c6 	bl	ffff0000000808ac <printk>
    printk("  x22 = 0x%x\n", ctx->x22);
ffff00000008b998:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b99c:	f9400800 	ldr	x0, [x0, #16]
ffff00000008b9a0:	aa0003e1 	mov	x1, x0
ffff00000008b9a4:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b9a8:	910c6000 	add	x0, x0, #0x318
ffff00000008b9ac:	97ffd3c0 	bl	ffff0000000808ac <printk>
    printk("  x23 = 0x%x\n", ctx->x23);
ffff00000008b9b0:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b9b4:	f9400c00 	ldr	x0, [x0, #24]
ffff00000008b9b8:	aa0003e1 	mov	x1, x0
ffff00000008b9bc:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b9c0:	910ca000 	add	x0, x0, #0x328
ffff00000008b9c4:	97ffd3ba 	bl	ffff0000000808ac <printk>
    printk("  x24 = 0x%\n", ctx->x24);
ffff00000008b9c8:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b9cc:	f9401000 	ldr	x0, [x0, #32]
ffff00000008b9d0:	aa0003e1 	mov	x1, x0
ffff00000008b9d4:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b9d8:	910ce000 	add	x0, x0, #0x338
ffff00000008b9dc:	97ffd3b4 	bl	ffff0000000808ac <printk>
    printk("  x25 = 0x%x\n", ctx->x25);
ffff00000008b9e0:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b9e4:	f9401400 	ldr	x0, [x0, #40]
ffff00000008b9e8:	aa0003e1 	mov	x1, x0
ffff00000008b9ec:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008b9f0:	910d2000 	add	x0, x0, #0x348
ffff00000008b9f4:	97ffd3ae 	bl	ffff0000000808ac <printk>
    printk("  x26 = 0x%x\n", ctx->x26);
ffff00000008b9f8:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b9fc:	f9401800 	ldr	x0, [x0, #48]
ffff00000008ba00:	aa0003e1 	mov	x1, x0
ffff00000008ba04:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008ba08:	910d6000 	add	x0, x0, #0x358
ffff00000008ba0c:	97ffd3a8 	bl	ffff0000000808ac <printk>
    printk("  x27 = 0x%x\n", ctx->x27);
ffff00000008ba10:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008ba14:	f9401c00 	ldr	x0, [x0, #56]
ffff00000008ba18:	aa0003e1 	mov	x1, x0
ffff00000008ba1c:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008ba20:	910da000 	add	x0, x0, #0x368
ffff00000008ba24:	97ffd3a2 	bl	ffff0000000808ac <printk>
    printk("  x28 = 0x%x\n", ctx->x28);
ffff00000008ba28:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008ba2c:	f9402000 	ldr	x0, [x0, #64]
ffff00000008ba30:	aa0003e1 	mov	x1, x0
ffff00000008ba34:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008ba38:	910de000 	add	x0, x0, #0x378
ffff00000008ba3c:	97ffd39c 	bl	ffff0000000808ac <printk>
    printk("  fp  = 0x%x\n", ctx->fp);
ffff00000008ba40:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008ba44:	f9402400 	ldr	x0, [x0, #72]
ffff00000008ba48:	aa0003e1 	mov	x1, x0
ffff00000008ba4c:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008ba50:	910e2000 	add	x0, x0, #0x388
ffff00000008ba54:	97ffd396 	bl	ffff0000000808ac <printk>
    printk("  lr  = 0x%x\n", ctx->lr);
ffff00000008ba58:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008ba5c:	f9402800 	ldr	x0, [x0, #80]
ffff00000008ba60:	aa0003e1 	mov	x1, x0
ffff00000008ba64:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008ba68:	910e6000 	add	x0, x0, #0x398
ffff00000008ba6c:	97ffd390 	bl	ffff0000000808ac <printk>
}
ffff00000008ba70:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008ba74:	f9402c00 	ldr	x0, [x0, #88]
ffff00000008ba78:	aa0003e1 	mov	x1, x0
ffff00000008ba7c:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008ba80:	910ea000 	add	x0, x0, #0x3a8
ffff00000008ba84:	97ffd38a 	bl	ffff0000000808ac <printk>

ffff00000008ba88:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff00000008ba8c:	d65f03c0 	ret

ffff00000008ba90 <dump_backtrace>:
void dump_backtrace(void)
{
    uint64_t fp, lr;
ffff00000008ba90:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff00000008ba94:	910003fd 	mov	x29, sp
    int depth = 0;

ffff00000008ba98:	b90037ff 	str	wzr, [sp, #52]
    __asm__ volatile ("mov %0, x29" : "=r"(fp));

ffff00000008ba9c:	aa1d03e0 	mov	x0, x29
ffff00000008baa0:	f9001fe0 	str	x0, [sp, #56]
    printk("=== kernel backtrace ===\n");

ffff00000008baa4:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008baa8:	910ee000 	add	x0, x0, #0x3b8
ffff00000008baac:	97ffd380 	bl	ffff0000000808ac <printk>
    while (fp && depth < 16) {
        uint64_t *frame = (uint64_t *)fp;
ffff00000008bab0:	14000018 	b	ffff00000008bb10 <dump_backtrace+0x80>

ffff00000008bab4:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008bab8:	f90017e0 	str	x0, [sp, #40]
        uint64_t prev_fp = frame[0];
        uint64_t ret_addr = frame[1];
ffff00000008babc:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008bac0:	f9400000 	ldr	x0, [x0]
ffff00000008bac4:	f90013e0 	str	x0, [sp, #32]

ffff00000008bac8:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008bacc:	f9400400 	ldr	x0, [x0, #8]
ffff00000008bad0:	f9000fe0 	str	x0, [sp, #24]
        printk(" #%d: fp=%x  lr=%x\n", depth, fp, ret_addr);

ffff00000008bad4:	f9400fe3 	ldr	x3, [sp, #24]
ffff00000008bad8:	f9401fe2 	ldr	x2, [sp, #56]
ffff00000008badc:	b94037e1 	ldr	w1, [sp, #52]
ffff00000008bae0:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008bae4:	910f6000 	add	x0, x0, #0x3d8
ffff00000008bae8:	97ffd371 	bl	ffff0000000808ac <printk>
        // 防御性检查：必须在内核栈范围
        if (!is_kernel_address(ret_addr))
            break;
ffff00000008baec:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008baf0:	94000013 	bl	ffff00000008bb3c <is_kernel_address>
ffff00000008baf4:	7100001f 	cmp	w0, #0x0
ffff00000008baf8:	540001a0 	b.eq	ffff00000008bb2c <dump_backtrace+0x9c>  // b.none

        fp = prev_fp;
        depth++;
ffff00000008bafc:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008bb00:	f9001fe0 	str	x0, [sp, #56]
    }
ffff00000008bb04:	b94037e0 	ldr	w0, [sp, #52]
ffff00000008bb08:	11000400 	add	w0, w0, #0x1
ffff00000008bb0c:	b90037e0 	str	w0, [sp, #52]
        uint64_t *frame = (uint64_t *)fp;
ffff00000008bb10:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008bb14:	f100001f 	cmp	x0, #0x0
ffff00000008bb18:	540000c0 	b.eq	ffff00000008bb30 <dump_backtrace+0xa0>  // b.none
ffff00000008bb1c:	b94037e0 	ldr	w0, [sp, #52]
ffff00000008bb20:	71003c1f 	cmp	w0, #0xf
ffff00000008bb24:	54fffc8d 	b.le	ffff00000008bab4 <dump_backtrace+0x24>
}
int is_kernel_address(uint64_t addr)
ffff00000008bb28:	14000002 	b	ffff00000008bb30 <dump_backtrace+0xa0>

ffff00000008bb2c:	d503201f 	nop
int is_kernel_address(uint64_t addr)
ffff00000008bb30:	d503201f 	nop
ffff00000008bb34:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff00000008bb38:	d65f03c0 	ret

ffff00000008bb3c <is_kernel_address>:
{
    return (addr & 0xFFFF000000000000UL) == 0xFFFF000000000000UL;
ffff00000008bb3c:	d10043ff 	sub	sp, sp, #0x10
ffff00000008bb40:	f90007e0 	str	x0, [sp, #8]
}
ffff00000008bb44:	f94007e0 	ldr	x0, [sp, #8]
ffff00000008bb48:	92503c01 	and	x1, x0, #0xffff000000000000
ffff00000008bb4c:	d2ffffe0 	mov	x0, #0xffff000000000000    	// #-281474976710656
ffff00000008bb50:	eb00003f 	cmp	x1, x0
ffff00000008bb54:	1a9f17e0 	cset	w0, eq  // eq = none
ffff00000008bb58:	12001c00 	and	w0, w0, #0xff

ffff00000008bb5c:	910043ff 	add	sp, sp, #0x10
ffff00000008bb60:	d65f03c0 	ret

ffff00000008bb64 <schedule>:

 void schedule(void)
{
    struct Process *prev_proc;
ffff00000008bb64:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008bb68:	910003fd 	mov	x29, sp
    struct Process *current_proc;
    struct ProcessControl *process_control;
    struct HeadList *list;

    process_control = get_pc();
    list = &process_control->ready_list;
ffff00000008bb6c:	97fffd5e 	bl	ffff00000008b0e4 <get_pc>
ffff00000008bb70:	f90013e0 	str	x0, [sp, #32]
    prev_proc = process_control->current_process;
ffff00000008bb74:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008bb78:	91002000 	add	x0, x0, #0x8
ffff00000008bb7c:	f9000fe0 	str	x0, [sp, #24]

ffff00000008bb80:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008bb84:	f9400000 	ldr	x0, [x0]
ffff00000008bb88:	f9000be0 	str	x0, [sp, #16]
    if (is_list_empty(list)) {
        current_proc = &process_table[0];
ffff00000008bb8c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008bb90:	97ffd1cb 	bl	ffff0000000802bc <is_list_empty>
ffff00000008bb94:	12001c00 	and	w0, w0, #0xff
ffff00000008bb98:	7100001f 	cmp	w0, #0x0
ffff00000008bb9c:	540000a0 	b.eq	ffff00000008bbb0 <schedule+0x4c>  // b.none
    }
ffff00000008bba0:	d0000000 	adrp	x0, ffff00000008d000 <_binary_user_bin_start+0x200>
ffff00000008bba4:	9138c000 	add	x0, x0, #0xe30
ffff00000008bba8:	f90017e0 	str	x0, [sp, #40]
ffff00000008bbac:	14000004 	b	ffff00000008bbbc <schedule+0x58>
    else {
        current_proc = (struct Process*)remove_list_head(list);
    }
ffff00000008bbb0:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008bbb4:	97ffd1a8 	bl	ffff000000080254 <remove_list_head>
ffff00000008bbb8:	f90017e0 	str	x0, [sp, #40]

    current_proc->state = PROC_RUNNING;
    process_control->current_process = current_proc;
ffff00000008bbbc:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008bbc0:	52800041 	mov	w1, #0x2                   	// #2
ffff00000008bbc4:	b9000c01 	str	w1, [x0, #12]

ffff00000008bbc8:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008bbcc:	f94017e1 	ldr	x1, [sp, #40]
ffff00000008bbd0:	f9000001 	str	x1, [x0]
  printk("===== schedule =====\n");

ffff00000008bbd4:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008bbd8:	910fc000 	add	x0, x0, #0x3f0
ffff00000008bbdc:	97ffd334 	bl	ffff0000000808ac <printk>
dump_context("current process ", prev_proc);
 //  dump_context("next", current_proc);
ffff00000008bbe0:	f9400be1 	ldr	x1, [sp, #16]
ffff00000008bbe4:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008bbe8:	91102000 	add	x0, x0, #0x408
ffff00000008bbec:	97ffff20 	bl	ffff00000008b86c <dump_context>
   dump_backtrace();

ffff00000008bbf0:	97ffffa8 	bl	ffff00000008ba90 <dump_backtrace>

    switch_process(prev_proc, current_proc);
}
ffff00000008bbf4:	f94017e1 	ldr	x1, [sp, #40]
ffff00000008bbf8:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008bbfc:	97ffff0b 	bl	ffff00000008b828 <switch_process>
/*1
ffff00000008bc00:	d503201f 	nop
ffff00000008bc04:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff00000008bc08:	d65f03c0 	ret

ffff00000008bc0c <yield>:
|                              |
+------------------------------+  stack
低地址*/
void yield(void)
{
    struct Process *process;
ffff00000008bc0c:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008bc10:	910003fd 	mov	x29, sp
    struct ProcessControl *process_control;
    struct HeadList *list;

    process_control = get_pc();
    list = &process_control->ready_list;
ffff00000008bc14:	97fffd34 	bl	ffff00000008b0e4 <get_pc>
ffff00000008bc18:	f90017e0 	str	x0, [sp, #40]

ffff00000008bc1c:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008bc20:	91002000 	add	x0, x0, #0x8
ffff00000008bc24:	f90013e0 	str	x0, [sp, #32]
    if (is_list_empty(list)) {
        return;
ffff00000008bc28:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008bc2c:	97ffd1a4 	bl	ffff0000000802bc <is_list_empty>
ffff00000008bc30:	12001c00 	and	w0, w0, #0xff
ffff00000008bc34:	7100001f 	cmp	w0, #0x0
ffff00000008bc38:	54000201 	b.ne	ffff00000008bc78 <yield+0x6c>  // b.any
    }

    process = process_control->current_process;
    process->state = PROC_READY;
ffff00000008bc3c:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008bc40:	f9400000 	ldr	x0, [x0]
ffff00000008bc44:	f9000fe0 	str	x0, [sp, #24]

ffff00000008bc48:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008bc4c:	52800061 	mov	w1, #0x3                   	// #3
ffff00000008bc50:	b9000c01 	str	w1, [x0, #12]
    if (process->pid != 0) {
        append_list_tail(list, (struct List*)process);
ffff00000008bc54:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008bc58:	b9400800 	ldr	w0, [x0, #8]
ffff00000008bc5c:	7100001f 	cmp	w0, #0x0
ffff00000008bc60:	54000080 	b.eq	ffff00000008bc70 <yield+0x64>  // b.none
    }
ffff00000008bc64:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008bc68:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008bc6c:	97ffd15e 	bl	ffff0000000801e4 <append_list_tail>

    schedule();
}
ffff00000008bc70:	97ffffbd 	bl	ffff00000008bb64 <schedule>
ffff00000008bc74:	14000002 	b	ffff00000008bc7c <yield+0x70>
    }
ffff00000008bc78:	d503201f 	nop
void sleep(int wait)
ffff00000008bc7c:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff00000008bc80:	d65f03c0 	ret

ffff00000008bc84 <sleep>:
{
    struct Process *process;
ffff00000008bc84:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008bc88:	910003fd 	mov	x29, sp
ffff00000008bc8c:	b9001fe0 	str	w0, [sp, #28]
    struct ProcessControl *process_control;

    process_control = get_pc();
    process = process_control->current_process;
ffff00000008bc90:	97fffd15 	bl	ffff00000008b0e4 <get_pc>
ffff00000008bc94:	f90017e0 	str	x0, [sp, #40]
    process->state = PROC_SLEEP;
ffff00000008bc98:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008bc9c:	f9400000 	ldr	x0, [x0]
ffff00000008bca0:	f90013e0 	str	x0, [sp, #32]
    process->wait = wait;
ffff00000008bca4:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008bca8:	52800081 	mov	w1, #0x4                   	// #4
ffff00000008bcac:	b9000c01 	str	w1, [x0, #12]

ffff00000008bcb0:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008bcb4:	b9401fe1 	ldr	w1, [sp, #28]
ffff00000008bcb8:	b9001001 	str	w1, [x0, #16]
    append_list_tail(&process_control->wait_list, (struct List*)process);
    schedule();
ffff00000008bcbc:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008bcc0:	91006000 	add	x0, x0, #0x18
ffff00000008bcc4:	f94013e1 	ldr	x1, [sp, #32]
ffff00000008bcc8:	97ffd147 	bl	ffff0000000801e4 <append_list_tail>
}
ffff00000008bccc:	97ffffa6 	bl	ffff00000008bb64 <schedule>

ffff00000008bcd0:	d503201f 	nop
ffff00000008bcd4:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff00000008bcd8:	d65f03c0 	ret

ffff00000008bcdc <wake_up>:
void wake_up(int wait)
{
    struct Process *process;
ffff00000008bcdc:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff00000008bce0:	910003fd 	mov	x29, sp
ffff00000008bce4:	b9001fe0 	str	w0, [sp, #28]
    struct ProcessControl *process_control;
    struct HeadList *ready_list;
    struct HeadList *wait_list;

    process_control = get_pc();
    ready_list = &process_control->ready_list;
ffff00000008bce8:	97fffcff 	bl	ffff00000008b0e4 <get_pc>
ffff00000008bcec:	f9001be0 	str	x0, [sp, #48]
    wait_list = &process_control->wait_list;
ffff00000008bcf0:	f9401be0 	ldr	x0, [sp, #48]
ffff00000008bcf4:	91002000 	add	x0, x0, #0x8
ffff00000008bcf8:	f90017e0 	str	x0, [sp, #40]

ffff00000008bcfc:	f9401be0 	ldr	x0, [sp, #48]
ffff00000008bd00:	91006000 	add	x0, x0, #0x18
ffff00000008bd04:	f90013e0 	str	x0, [sp, #32]
    process = (struct Process*)remove_list(wait_list, wait);

ffff00000008bd08:	b9401fe1 	ldr	w1, [sp, #28]
ffff00000008bd0c:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008bd10:	97ffd174 	bl	ffff0000000802e0 <remove_list>
ffff00000008bd14:	f9001fe0 	str	x0, [sp, #56]
    while (process != NULL) {
        process->state = PROC_READY;
ffff00000008bd18:	1400000b 	b	ffff00000008bd44 <wake_up+0x68>
        append_list_tail(ready_list, (struct List*)process);
ffff00000008bd1c:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008bd20:	52800061 	mov	w1, #0x3                   	// #3
ffff00000008bd24:	b9000c01 	str	w1, [x0, #12]
        process = (struct Process*)remove_list(wait_list, wait);
ffff00000008bd28:	f9401fe1 	ldr	x1, [sp, #56]
ffff00000008bd2c:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008bd30:	97ffd12d 	bl	ffff0000000801e4 <append_list_tail>
    }
ffff00000008bd34:	b9401fe1 	ldr	w1, [sp, #28]
ffff00000008bd38:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008bd3c:	97ffd169 	bl	ffff0000000802e0 <remove_list>
ffff00000008bd40:	f9001fe0 	str	x0, [sp, #56]
        process->state = PROC_READY;
ffff00000008bd44:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008bd48:	f100001f 	cmp	x0, #0x0
ffff00000008bd4c:	54fffe81 	b.ne	ffff00000008bd1c <wake_up+0x40>  // b.any
}

ffff00000008bd50:	d503201f 	nop
ffff00000008bd54:	d503201f 	nop
ffff00000008bd58:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff00000008bd5c:	d65f03c0 	ret

ffff00000008bd60 <exit>:
void exit(void)
{
    struct Process *process;
ffff00000008bd60:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008bd64:	910003fd 	mov	x29, sp
    struct ProcessControl *process_control;

    process_control = get_pc();
    process = process_control->current_process;
ffff00000008bd68:	97fffcdf 	bl	ffff00000008b0e4 <get_pc>
ffff00000008bd6c:	f9000fe0 	str	x0, [sp, #24]
    process->state = PROC_KILLED;
ffff00000008bd70:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008bd74:	f9400000 	ldr	x0, [x0]
ffff00000008bd78:	f9000be0 	str	x0, [sp, #16]
    process->wait = process->pid;
ffff00000008bd7c:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008bd80:	528000a1 	mov	w1, #0x5                   	// #5
ffff00000008bd84:	b9000c01 	str	w1, [x0, #12]

ffff00000008bd88:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008bd8c:	b9400801 	ldr	w1, [x0, #8]
ffff00000008bd90:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008bd94:	b9001001 	str	w1, [x0, #16]
    append_list_tail(&process_control->kill_list, (struct List*)process);

ffff00000008bd98:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008bd9c:	9100a000 	add	x0, x0, #0x28
ffff00000008bda0:	f9400be1 	ldr	x1, [sp, #16]
ffff00000008bda4:	97ffd110 	bl	ffff0000000801e4 <append_list_tail>
    wake_up(-3);
    schedule();
ffff00000008bda8:	12800040 	mov	w0, #0xfffffffd            	// #-3
ffff00000008bdac:	97ffffcc 	bl	ffff00000008bcdc <wake_up>
}
ffff00000008bdb0:	97ffff6d 	bl	ffff00000008bb64 <schedule>

ffff00000008bdb4:	d503201f 	nop
ffff00000008bdb8:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008bdbc:	d65f03c0 	ret

ffff00000008bdc0 <wait>:
void wait(int pid)
{
    struct Process *process;
ffff00000008bdc0:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff00000008bdc4:	910003fd 	mov	x29, sp
ffff00000008bdc8:	b9001fe0 	str	w0, [sp, #28]
    struct ProcessControl *process_control;
    struct HeadList *list;

    process_control = get_pc();
    list = &process_control->kill_list;
ffff00000008bdcc:	97fffcc6 	bl	ffff00000008b0e4 <get_pc>
ffff00000008bdd0:	f9001fe0 	str	x0, [sp, #56]

ffff00000008bdd4:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008bdd8:	9100a000 	add	x0, x0, #0x28
ffff00000008bddc:	f9001be0 	str	x0, [sp, #48]
    while (1) {
        if (!is_list_empty(list)) {
            process = (struct Process*)remove_list(list, pid);
ffff00000008bde0:	f9401be0 	ldr	x0, [sp, #48]
ffff00000008bde4:	97ffd136 	bl	ffff0000000802bc <is_list_empty>
ffff00000008bde8:	12001c00 	and	w0, w0, #0xff
ffff00000008bdec:	52000000 	eor	w0, w0, #0x1
ffff00000008bdf0:	12001c00 	and	w0, w0, #0xff
ffff00000008bdf4:	7100001f 	cmp	w0, #0x0
ffff00000008bdf8:	54000360 	b.eq	ffff00000008be64 <wait+0xa4>  // b.none
            if (process != NULL) {
ffff00000008bdfc:	b9401fe1 	ldr	w1, [sp, #28]
ffff00000008be00:	f9401be0 	ldr	x0, [sp, #48]
ffff00000008be04:	97ffd137 	bl	ffff0000000802e0 <remove_list>
ffff00000008be08:	f90017e0 	str	x0, [sp, #40]
                ASSERT(process->state == PROC_KILLED);
ffff00000008be0c:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008be10:	f100001f 	cmp	x0, #0x0
ffff00000008be14:	54000280 	b.eq	ffff00000008be64 <wait+0xa4>  // b.none
                kfree(process->stack);
ffff00000008be18:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008be1c:	b9400c00 	ldr	w0, [x0, #12]
ffff00000008be20:	7100141f 	cmp	w0, #0x5
ffff00000008be24:	540000a0 	b.eq	ffff00000008be38 <wait+0x78>  // b.none
ffff00000008be28:	d2803c21 	mov	x1, #0x1e1                 	// #481
ffff00000008be2c:	b0000000 	adrp	x0, ffff00000008c000 <init_system_call+0x10>
ffff00000008be30:	91070000 	add	x0, x0, #0x1c0
ffff00000008be34:	97ffd374 	bl	ffff000000080c04 <error_check>
                free_vm(process->page_map);
ffff00000008be38:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008be3c:	f9401400 	ldr	x0, [x0, #40]
ffff00000008be40:	97fff892 	bl	ffff00000008a088 <kfree>
                memset(process, 0, sizeof(struct Process));
ffff00000008be44:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008be48:	f9401000 	ldr	x0, [x0, #32]
ffff00000008be4c:	97fffa74 	bl	ffff00000008a81c <free_vm>
                break;
ffff00000008be50:	52800702 	mov	w2, #0x38                  	// #56
ffff00000008be54:	52800001 	mov	w1, #0x0                   	// #0
ffff00000008be58:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008be5c:	97ffd0be 	bl	ffff000000080154 <memset>
            }
ffff00000008be60:	14000004 	b	ffff00000008be70 <wait+0xb0>
        }

        sleep(-3);
    }
ffff00000008be64:	12800040 	mov	w0, #0xfffffffd            	// #-3
ffff00000008be68:	97ffff87 	bl	ffff00000008bc84 <sleep>
            process = (struct Process*)remove_list(list, pid);
ffff00000008be6c:	17ffffdd 	b	ffff00000008bde0 <wait+0x20>
ffff00000008be70:	d503201f 	nop
ffff00000008be74:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff00000008be78:	d65f03c0 	ret

ffff00000008be7c <sys_write>:
#include "process.h"

static SYSTEMCALL system_calls[10];

static int sys_write(int64_t *argptr)
{
ffff00000008be7c:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008be80:	910003fd 	mov	x29, sp
ffff00000008be84:	f9000fe0 	str	x0, [sp, #24]
    write_console((char*)argptr[0], (int)argptr[1]);
ffff00000008be88:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008be8c:	f9400000 	ldr	x0, [x0]
ffff00000008be90:	aa0003e2 	mov	x2, x0
ffff00000008be94:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008be98:	91002000 	add	x0, x0, #0x8
ffff00000008be9c:	f9400000 	ldr	x0, [x0]
ffff00000008bea0:	2a0003e1 	mov	w1, w0
ffff00000008bea4:	aa0203e0 	mov	x0, x2
ffff00000008bea8:	97ffd26b 	bl	ffff000000080854 <write_console>
    return (int)argptr[1];
ffff00000008beac:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008beb0:	91002000 	add	x0, x0, #0x8
ffff00000008beb4:	f9400000 	ldr	x0, [x0]
}
ffff00000008beb8:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008bebc:	d65f03c0 	ret

ffff00000008bec0 <sys_sleep>:

static int sys_sleep(int64_t *argptr)
{
ffff00000008bec0:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff00000008bec4:	910003fd 	mov	x29, sp
ffff00000008bec8:	f9000fe0 	str	x0, [sp, #24]
    uint64_t ticks;
    uint64_t old_ticks;
    uint64_t sleep_ticks = argptr[0];
ffff00000008becc:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008bed0:	f9400000 	ldr	x0, [x0]
ffff00000008bed4:	f9001be0 	str	x0, [sp, #48]

    ticks = get_ticks();
ffff00000008bed8:	97ffd6cd 	bl	ffff000000081a0c <get_ticks>
ffff00000008bedc:	f9001fe0 	str	x0, [sp, #56]
    old_ticks = ticks;
ffff00000008bee0:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008bee4:	f90017e0 	str	x0, [sp, #40]

    while (ticks - old_ticks < sleep_ticks) {
ffff00000008bee8:	14000005 	b	ffff00000008befc <sys_sleep+0x3c>
        sleep(-1);
ffff00000008beec:	12800000 	mov	w0, #0xffffffff            	// #-1
ffff00000008bef0:	97ffff65 	bl	ffff00000008bc84 <sleep>
        ticks = get_ticks();
ffff00000008bef4:	97ffd6c6 	bl	ffff000000081a0c <get_ticks>
ffff00000008bef8:	f9001fe0 	str	x0, [sp, #56]
    while (ticks - old_ticks < sleep_ticks) {
ffff00000008befc:	f9401fe1 	ldr	x1, [sp, #56]
ffff00000008bf00:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008bf04:	cb000020 	sub	x0, x1, x0
ffff00000008bf08:	f9401be1 	ldr	x1, [sp, #48]
ffff00000008bf0c:	eb00003f 	cmp	x1, x0
ffff00000008bf10:	54fffee8 	b.hi	ffff00000008beec <sys_sleep+0x2c>  // b.pmore
    }

    return 0;
ffff00000008bf14:	52800000 	mov	w0, #0x0                   	// #0
}
ffff00000008bf18:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff00000008bf1c:	d65f03c0 	ret

ffff00000008bf20 <sys_exit>:

static int sys_exit(int64_t *argptr)
{
ffff00000008bf20:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008bf24:	910003fd 	mov	x29, sp
ffff00000008bf28:	f9000fe0 	str	x0, [sp, #24]
    exit();
ffff00000008bf2c:	97ffff8d 	bl	ffff00000008bd60 <exit>
    return 0;
ffff00000008bf30:	52800000 	mov	w0, #0x0                   	// #0
}
ffff00000008bf34:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008bf38:	d65f03c0 	ret

ffff00000008bf3c <sys_wait>:

static int sys_wait(int64_t *argptr)
{
ffff00000008bf3c:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008bf40:	910003fd 	mov	x29, sp
ffff00000008bf44:	f9000fe0 	str	x0, [sp, #24]
    wait(argptr[0]);
ffff00000008bf48:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008bf4c:	f9400000 	ldr	x0, [x0]
ffff00000008bf50:	97ffff9c 	bl	ffff00000008bdc0 <wait>
    return 0;
ffff00000008bf54:	52800000 	mov	w0, #0x0                   	// #0
}
ffff00000008bf58:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008bf5c:	d65f03c0 	ret

ffff00000008bf60 <system_call>:

void system_call(struct TrapFrame *tf)
{
ffff00000008bf60:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff00000008bf64:	910003fd 	mov	x29, sp
ffff00000008bf68:	f9000fe0 	str	x0, [sp, #24]
    int64_t i = tf->x8;
ffff00000008bf6c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008bf70:	f9402000 	ldr	x0, [x0, #64]
ffff00000008bf74:	f9001fe0 	str	x0, [sp, #56]
    int64_t param_count = tf->x0;
ffff00000008bf78:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008bf7c:	f9400000 	ldr	x0, [x0]
ffff00000008bf80:	f9001be0 	str	x0, [sp, #48]
    int64_t *argptr = (int64_t*)tf->x1;
ffff00000008bf84:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008bf88:	f9400400 	ldr	x0, [x0, #8]
ffff00000008bf8c:	f90017e0 	str	x0, [sp, #40]

    if (param_count < 0 || i < 0 || i > 3) {
ffff00000008bf90:	f9401be0 	ldr	x0, [sp, #48]
ffff00000008bf94:	f100001f 	cmp	x0, #0x0
ffff00000008bf98:	540000eb 	b.lt	ffff00000008bfb4 <system_call+0x54>  // b.tstop
ffff00000008bf9c:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008bfa0:	f100001f 	cmp	x0, #0x0
ffff00000008bfa4:	5400008b 	b.lt	ffff00000008bfb4 <system_call+0x54>  // b.tstop
ffff00000008bfa8:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008bfac:	f1000c1f 	cmp	x0, #0x3
ffff00000008bfb0:	540000ad 	b.le	ffff00000008bfc4 <system_call+0x64>
        tf->x0 = -1;
ffff00000008bfb4:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008bfb8:	92800001 	mov	x1, #0xffffffffffffffff    	// #-1
ffff00000008bfbc:	f9000001 	str	x1, [x0]
        return;
ffff00000008bfc0:	1400000a 	b	ffff00000008bfe8 <system_call+0x88>
    }

    tf->x0 = system_calls[i](argptr);
ffff00000008bfc4:	f0000000 	adrp	x0, ffff00000008e000 <process_table+0x1d0>
ffff00000008bfc8:	91026000 	add	x0, x0, #0x98
ffff00000008bfcc:	f9401fe1 	ldr	x1, [sp, #56]
ffff00000008bfd0:	f8617801 	ldr	x1, [x0, x1, lsl #3]
ffff00000008bfd4:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008bfd8:	d63f0020 	blr	x1
ffff00000008bfdc:	93407c01 	sxtw	x1, w0
ffff00000008bfe0:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008bfe4:	f9000001 	str	x1, [x0]
}
ffff00000008bfe8:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff00000008bfec:	d65f03c0 	ret

ffff00000008bff0 <init_system_call>:

void init_system_call(void)
{
    system_calls[0] = sys_write;
ffff00000008bff0:	f0000000 	adrp	x0, ffff00000008e000 <process_table+0x1d0>
ffff00000008bff4:	91026000 	add	x0, x0, #0x98
ffff00000008bff8:	90000001 	adrp	x1, ffff00000008b000 <load_file+0x18>
ffff00000008bffc:	9139f021 	add	x1, x1, #0xe7c
ffff00000008c000:	f9000001 	str	x1, [x0]
    system_calls[1] = sys_sleep;
ffff00000008c004:	d0000000 	adrp	x0, ffff00000008e000 <process_table+0x1d0>
ffff00000008c008:	91026000 	add	x0, x0, #0x98
ffff00000008c00c:	f0ffffe1 	adrp	x1, ffff00000008b000 <load_file+0x18>
ffff00000008c010:	913b0021 	add	x1, x1, #0xec0
ffff00000008c014:	f9000401 	str	x1, [x0, #8]
    system_calls[2] = sys_exit;
ffff00000008c018:	d0000000 	adrp	x0, ffff00000008e000 <process_table+0x1d0>
ffff00000008c01c:	91026000 	add	x0, x0, #0x98
ffff00000008c020:	f0ffffe1 	adrp	x1, ffff00000008b000 <load_file+0x18>
ffff00000008c024:	913c8021 	add	x1, x1, #0xf20
ffff00000008c028:	f9000801 	str	x1, [x0, #16]
    system_calls[3] = sys_wait;
ffff00000008c02c:	d0000000 	adrp	x0, ffff00000008e000 <process_table+0x1d0>
ffff00000008c030:	91026000 	add	x0, x0, #0x98
ffff00000008c034:	f0ffffe1 	adrp	x1, ffff00000008b000 <load_file+0x18>
ffff00000008c038:	913cf021 	add	x1, x1, #0xf3c
ffff00000008c03c:	f9000c01 	str	x1, [x0, #24]
}
ffff00000008c040:	d503201f 	nop
ffff00000008c044:	d65f03c0 	ret
