
kernel.elf:     file format elf64-littleaarch64


Disassembly of section .text:

ffff000000080000 <start>:
ffff000000080000:	d53800a0 	mrs	x0, mpidr_el1
ffff000000080004:	92400400 	and	x0, x0, #0x3
ffff000000080008:	f100001f 	cmp	x0, #0x0
ffff00000008000c:	54000040 	b.eq	ffff000000080014 <kernel_entry>  // b.none

ffff000000080010 <end>:
ffff000000080010:	14000000 	b	ffff000000080010 <end>

ffff000000080014 <kernel_entry>:
ffff000000080014:	d5384240 	mrs	x0, currentel
ffff000000080018:	d342fc00 	lsr	x0, x0, #2
ffff00000008001c:	f1000c1f 	cmp	x0, #0x3
ffff000000080020:	540000c0 	b.eq	ffff000000080038 <el3_entry>  // b.none
ffff000000080024:	f100081f 	cmp	x0, #0x2
ffff000000080028:	540001a0 	b.eq	ffff00000008005c <el2_entry>  // b.none
ffff00000008002c:	f100041f 	cmp	x0, #0x1
ffff000000080030:	54000260 	b.eq	ffff00000008007c <el1_entry>  // b.none
ffff000000080034:	17fffff7 	b	ffff000000080010 <end>

ffff000000080038 <el3_entry>:
ffff000000080038:	d2808000 	mov	x0, #0x400                 	// #1024
ffff00000008003c:	b27c0400 	orr	x0, x0, #0x30
ffff000000080040:	b2400000 	orr	x0, x0, #0x1
ffff000000080044:	d51e1100 	msr	scr_el3, x0
ffff000000080048:	d2807920 	mov	x0, #0x3c9                 	// #969
ffff00000008004c:	d51e4000 	msr	spsr_el3, x0
ffff000000080050:	10000060 	adr	x0, ffff00000008005c <el2_entry>
ffff000000080054:	d51e4020 	msr	elr_el3, x0
ffff000000080058:	d69f03e0 	eret

ffff00000008005c <el2_entry>:
ffff00000008005c:	d518101f 	msr	sctlr_el1, xzr
ffff000000080060:	d2b00000 	mov	x0, #0x80000000            	// #2147483648
ffff000000080064:	d51c1100 	msr	hcr_el2, x0
ffff000000080068:	d28078a0 	mov	x0, #0x3c5                 	// #965
ffff00000008006c:	d51c4000 	msr	spsr_el2, x0
ffff000000080070:	10000060 	adr	x0, ffff00000008007c <el1_entry>
ffff000000080074:	d51c4020 	msr	elr_el2, x0
ffff000000080078:	d69f03e0 	eret

ffff00000008007c <el1_entry>:
ffff00000008007c:	b26d03ff 	mov	sp, #0x80000               	// #524288
ffff000000080080:	940007f5 	bl	ffff000000082054 <setup_vm>
ffff000000080084:	940007e6 	bl	ffff00000008201c <enable_mmu>
ffff000000080088:	58000280 	ldr	x0, ffff0000000800d8 <ret_from_fork+0xc>
ffff00000008008c:	580002a1 	ldr	x1, ffff0000000800e0 <ret_from_fork+0x14>
ffff000000080090:	580002c2 	ldr	x2, ffff0000000800e8 <ret_from_fork+0x1c>
ffff000000080094:	94000051 	bl	ffff0000000801d8 <memcpy>
ffff000000080098:	580002c0 	ldr	x0, ffff0000000800f0 <ret_from_fork+0x24>
ffff00000008009c:	580002e1 	ldr	x1, ffff0000000800f8 <ret_from_fork+0x2c>
ffff0000000800a0:	cb000022 	sub	x2, x1, x0
ffff0000000800a4:	d2800001 	mov	x1, #0x0                   	// #0
ffff0000000800a8:	9400003b 	bl	ffff000000080194 <memset>
ffff0000000800ac:	580002a0 	ldr	x0, ffff000000080100 <ret_from_fork+0x34>
ffff0000000800b0:	d518c000 	msr	vbar_el1, x0
ffff0000000800b4:	d2ffffe0 	mov	x0, #0xffff000000000000    	// #-281474976710656
ffff0000000800b8:	8b2063ff 	add	sp, sp, x0
ffff0000000800bc:	58000260 	ldr	x0, ffff000000080108 <ret_from_fork+0x3c>
ffff0000000800c0:	d63f0000 	blr	x0

ffff0000000800c4 <halt>:
ffff0000000800c4:	d503207f 	wfi
ffff0000000800c8:	17ffffff 	b	ffff0000000800c4 <halt>

ffff0000000800cc <ret_from_fork>:
ffff0000000800cc:	aa1303e0 	mov	x0, x19
ffff0000000800d0:	d63f0000 	blr	x0
ffff0000000800d4:	00000000 	udf	#0
ffff0000000800d8:	30000000 	adr	x0, ffff0000000800d9 <ret_from_fork+0xd>
ffff0000000800dc:	ffff0000 	.inst	0xffff0000 ; undefined
ffff0000000800e0:	0008d2bc 	.inst	0x0008d2bc ; undefined
ffff0000000800e4:	ffff0000 	.inst	0xffff0000 ; undefined
ffff0000000800e8:	031b6000 	.inst	0x031b6000 ; undefined
ffff0000000800ec:	00000000 	udf	#0
ffff0000000800f0:	0008d2c0 	.inst	0x0008d2c0 ; undefined
ffff0000000800f4:	ffff0000 	.inst	0xffff0000 ; undefined
ffff0000000800f8:	0008d5a0 	.inst	0x0008d5a0 ; undefined
ffff0000000800fc:	ffff0000 	.inst	0xffff0000 ; undefined
ffff000000080100:	00081000 	.inst	0x00081000 ; undefined
ffff000000080104:	ffff0000 	.inst	0xffff0000 ; undefined
ffff000000080108:	00080110 	.inst	0x00080110 ; undefined
ffff00000008010c:	ffff0000 	.inst	0xffff0000 ; undefined

ffff000000080110 <KMain>:
ffff000000080110:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffff000000080114:	910003fd 	mov	x29, sp
ffff000000080118:	94000107 	bl	ffff000000080534 <init_uart>
ffff00000008011c:	90000060 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff000000080120:	91018000 	add	x0, x0, #0x60
ffff000000080124:	9400021e 	bl	ffff00000008099c <printk>
ffff000000080128:	94000011 	bl	ffff00000008016c <get_el>
ffff00000008012c:	12001c00 	and	w0, w0, #0xff
ffff000000080130:	92401c00 	and	x0, x0, #0xff
ffff000000080134:	aa0003e1 	mov	x1, x0
ffff000000080138:	90000060 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008013c:	9101e000 	add	x0, x0, #0x78
ffff000000080140:	94000217 	bl	ffff00000008099c <printk>
ffff000000080144:	94002a0e 	bl	ffff00000008a97c <init_memory>
ffff000000080148:	94002bd3 	bl	ffff00000008b094 <init_fs>
ffff00000008014c:	94002faf 	bl	ffff00000008c008 <init_system_call>
ffff000000080150:	9400064c 	bl	ffff000000081a80 <init_timer>
ffff000000080154:	94000632 	bl	ffff000000081a1c <init_interrupt_controller>
ffff000000080158:	94002dad 	bl	ffff00000008b80c <init_process>
ffff00000008015c:	94000608 	bl	ffff00000008197c <enable_irq>
ffff000000080160:	d503201f 	nop
ffff000000080164:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffff000000080168:	d65f03c0 	ret

ffff00000008016c <get_el>:
ffff00000008016c:	d5384240 	mrs	x0, currentel
ffff000000080170:	d342fc00 	lsr	x0, x0, #2
ffff000000080174:	d65f03c0 	ret

ffff000000080178 <delay>:
ffff000000080178:	f1000400 	subs	x0, x0, #0x1
ffff00000008017c:	54ffffe1 	b.ne	ffff000000080178 <delay>  // b.any
ffff000000080180:	d65f03c0 	ret

ffff000000080184 <out_word>:
ffff000000080184:	b9000001 	str	w1, [x0]
ffff000000080188:	d65f03c0 	ret

ffff00000008018c <in_word>:
ffff00000008018c:	b9400000 	ldr	w0, [x0]
ffff000000080190:	d65f03c0 	ret

ffff000000080194 <memset>:
ffff000000080194:	f100005f 	cmp	x2, #0x0
ffff000000080198:	54000080 	b.eq	ffff0000000801a8 <memset_end>  // b.none

ffff00000008019c <set>:
ffff00000008019c:	38001401 	strb	w1, [x0], #1
ffff0000000801a0:	f1000442 	subs	x2, x2, #0x1
ffff0000000801a4:	54ffffc1 	b.ne	ffff00000008019c <set>  // b.any

ffff0000000801a8 <memset_end>:
ffff0000000801a8:	d65f03c0 	ret

ffff0000000801ac <memcmp>:
ffff0000000801ac:	aa0003e3 	mov	x3, x0
ffff0000000801b0:	d2800000 	mov	x0, #0x0                   	// #0

ffff0000000801b4 <compare>:
ffff0000000801b4:	f100005f 	cmp	x2, #0x0
ffff0000000801b8:	540000e0 	b.eq	ffff0000000801d4 <memcmp_end>  // b.none
ffff0000000801bc:	38401464 	ldrb	w4, [x3], #1
ffff0000000801c0:	38401425 	ldrb	w5, [x1], #1
ffff0000000801c4:	d1000442 	sub	x2, x2, #0x1
ffff0000000801c8:	6b05009f 	cmp	w4, w5
ffff0000000801cc:	54ffff40 	b.eq	ffff0000000801b4 <compare>  // b.none
ffff0000000801d0:	d2800020 	mov	x0, #0x1                   	// #1

ffff0000000801d4 <memcmp_end>:
ffff0000000801d4:	d65f03c0 	ret

ffff0000000801d8 <memcpy>:
ffff0000000801d8:	f100005f 	cmp	x2, #0x0
ffff0000000801dc:	54000220 	b.eq	ffff000000080220 <memcpy_end>  // b.none
ffff0000000801e0:	d2800024 	mov	x4, #0x1                   	// #1
ffff0000000801e4:	eb00003f 	cmp	x1, x0
ffff0000000801e8:	54000102 	b.cs	ffff000000080208 <copy>  // b.hs, b.nlast
ffff0000000801ec:	8b020023 	add	x3, x1, x2
ffff0000000801f0:	eb00007f 	cmp	x3, x0
ffff0000000801f4:	540000a9 	b.ls	ffff000000080208 <copy>  // b.plast

ffff0000000801f8 <overlap>:
ffff0000000801f8:	d1000443 	sub	x3, x2, #0x1
ffff0000000801fc:	8b030000 	add	x0, x0, x3
ffff000000080200:	8b030021 	add	x1, x1, x3
ffff000000080204:	cb0403e4 	neg	x4, x4

ffff000000080208 <copy>:
ffff000000080208:	39400023 	ldrb	w3, [x1]
ffff00000008020c:	39000003 	strb	w3, [x0]
ffff000000080210:	8b040000 	add	x0, x0, x4
ffff000000080214:	8b040021 	add	x1, x1, x4
ffff000000080218:	f1000442 	subs	x2, x2, #0x1
ffff00000008021c:	54ffff61 	b.ne	ffff000000080208 <copy>  // b.any

ffff000000080220 <memcpy_end>:
ffff000000080220:	d65f03c0 	ret

ffff000000080224 <append_list_tail>:
ffff000000080224:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff000000080228:	910003fd 	mov	x29, sp
ffff00000008022c:	f9000fe0 	str	x0, [sp, #24]
ffff000000080230:	f9000be1 	str	x1, [sp, #16]
ffff000000080234:	f9400be0 	ldr	x0, [sp, #16]
ffff000000080238:	f900001f 	str	xzr, [x0]
ffff00000008023c:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000080240:	94000031 	bl	ffff000000080304 <is_list_empty>
ffff000000080244:	12001c00 	and	w0, w0, #0xff
ffff000000080248:	12000000 	and	w0, w0, #0x1
ffff00000008024c:	7100001f 	cmp	w0, #0x0
ffff000000080250:	54000100 	b.eq	ffff000000080270 <append_list_tail+0x4c>  // b.none
ffff000000080254:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000080258:	f9400be1 	ldr	x1, [sp, #16]
ffff00000008025c:	f9000001 	str	x1, [x0]
ffff000000080260:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000080264:	f9400be1 	ldr	x1, [sp, #16]
ffff000000080268:	f9000401 	str	x1, [x0, #8]
ffff00000008026c:	14000008 	b	ffff00000008028c <append_list_tail+0x68>
ffff000000080270:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000080274:	f9400400 	ldr	x0, [x0, #8]
ffff000000080278:	f9400be1 	ldr	x1, [sp, #16]
ffff00000008027c:	f9000001 	str	x1, [x0]
ffff000000080280:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000080284:	f9400be1 	ldr	x1, [sp, #16]
ffff000000080288:	f9000401 	str	x1, [x0, #8]
ffff00000008028c:	d503201f 	nop
ffff000000080290:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff000000080294:	d65f03c0 	ret

ffff000000080298 <remove_list_head>:
ffff000000080298:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008029c:	910003fd 	mov	x29, sp
ffff0000000802a0:	f9000fe0 	str	x0, [sp, #24]
ffff0000000802a4:	f9400fe0 	ldr	x0, [sp, #24]
ffff0000000802a8:	94000017 	bl	ffff000000080304 <is_list_empty>
ffff0000000802ac:	12001c00 	and	w0, w0, #0xff
ffff0000000802b0:	12000000 	and	w0, w0, #0x1
ffff0000000802b4:	7100001f 	cmp	w0, #0x0
ffff0000000802b8:	54000060 	b.eq	ffff0000000802c4 <remove_list_head+0x2c>  // b.none
ffff0000000802bc:	d2800000 	mov	x0, #0x0                   	// #0
ffff0000000802c0:	1400000f 	b	ffff0000000802fc <remove_list_head+0x64>
ffff0000000802c4:	f9400fe0 	ldr	x0, [sp, #24]
ffff0000000802c8:	f9400000 	ldr	x0, [x0]
ffff0000000802cc:	f90017e0 	str	x0, [sp, #40]
ffff0000000802d0:	f94017e0 	ldr	x0, [sp, #40]
ffff0000000802d4:	f9400001 	ldr	x1, [x0]
ffff0000000802d8:	f9400fe0 	ldr	x0, [sp, #24]
ffff0000000802dc:	f9000001 	str	x1, [x0]
ffff0000000802e0:	f9400fe0 	ldr	x0, [sp, #24]
ffff0000000802e4:	f9400000 	ldr	x0, [x0]
ffff0000000802e8:	f100001f 	cmp	x0, #0x0
ffff0000000802ec:	54000061 	b.ne	ffff0000000802f8 <remove_list_head+0x60>  // b.any
ffff0000000802f0:	f9400fe0 	ldr	x0, [sp, #24]
ffff0000000802f4:	f900041f 	str	xzr, [x0, #8]
ffff0000000802f8:	f94017e0 	ldr	x0, [sp, #40]
ffff0000000802fc:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff000000080300:	d65f03c0 	ret

ffff000000080304 <is_list_empty>:
ffff000000080304:	d10043ff 	sub	sp, sp, #0x10
ffff000000080308:	f90007e0 	str	x0, [sp, #8]
ffff00000008030c:	f94007e0 	ldr	x0, [sp, #8]
ffff000000080310:	f9400000 	ldr	x0, [x0]
ffff000000080314:	f100001f 	cmp	x0, #0x0
ffff000000080318:	1a9f17e0 	cset	w0, eq	// eq = none
ffff00000008031c:	12001c00 	and	w0, w0, #0xff
ffff000000080320:	910043ff 	add	sp, sp, #0x10
ffff000000080324:	d65f03c0 	ret

ffff000000080328 <remove_list>:
ffff000000080328:	d100c3ff 	sub	sp, sp, #0x30
ffff00000008032c:	f90007e0 	str	x0, [sp, #8]
ffff000000080330:	b90007e1 	str	w1, [sp, #4]
ffff000000080334:	f94007e0 	ldr	x0, [sp, #8]
ffff000000080338:	f9400000 	ldr	x0, [x0]
ffff00000008033c:	f90017e0 	str	x0, [sp, #40]
ffff000000080340:	f94007e0 	ldr	x0, [sp, #8]
ffff000000080344:	f90013e0 	str	x0, [sp, #32]
ffff000000080348:	f9000fff 	str	xzr, [sp, #24]
ffff00000008034c:	14000020 	b	ffff0000000803cc <remove_list+0xa4>
ffff000000080350:	f94017e0 	ldr	x0, [sp, #40]
ffff000000080354:	b9401000 	ldr	w0, [x0, #16]
ffff000000080358:	b94007e1 	ldr	w1, [sp, #4]
ffff00000008035c:	6b00003f 	cmp	w1, w0
ffff000000080360:	540002c1 	b.ne	ffff0000000803b8 <remove_list+0x90>  // b.any
ffff000000080364:	f94017e0 	ldr	x0, [sp, #40]
ffff000000080368:	f9400001 	ldr	x1, [x0]
ffff00000008036c:	f94013e0 	ldr	x0, [sp, #32]
ffff000000080370:	f9000001 	str	x1, [x0]
ffff000000080374:	f94017e0 	ldr	x0, [sp, #40]
ffff000000080378:	f9000fe0 	str	x0, [sp, #24]
ffff00000008037c:	f94007e0 	ldr	x0, [sp, #8]
ffff000000080380:	f9400000 	ldr	x0, [x0]
ffff000000080384:	f100001f 	cmp	x0, #0x0
ffff000000080388:	54000081 	b.ne	ffff000000080398 <remove_list+0x70>  // b.any
ffff00000008038c:	f94007e0 	ldr	x0, [sp, #8]
ffff000000080390:	f900041f 	str	xzr, [x0, #8]
ffff000000080394:	14000012 	b	ffff0000000803dc <remove_list+0xb4>
ffff000000080398:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008039c:	f9400000 	ldr	x0, [x0]
ffff0000000803a0:	f100001f 	cmp	x0, #0x0
ffff0000000803a4:	540001c1 	b.ne	ffff0000000803dc <remove_list+0xb4>  // b.any
ffff0000000803a8:	f94007e0 	ldr	x0, [sp, #8]
ffff0000000803ac:	f94013e1 	ldr	x1, [sp, #32]
ffff0000000803b0:	f9000401 	str	x1, [x0, #8]
ffff0000000803b4:	1400000a 	b	ffff0000000803dc <remove_list+0xb4>
ffff0000000803b8:	f94017e0 	ldr	x0, [sp, #40]
ffff0000000803bc:	f90013e0 	str	x0, [sp, #32]
ffff0000000803c0:	f94017e0 	ldr	x0, [sp, #40]
ffff0000000803c4:	f9400000 	ldr	x0, [x0]
ffff0000000803c8:	f90017e0 	str	x0, [sp, #40]
ffff0000000803cc:	f94017e0 	ldr	x0, [sp, #40]
ffff0000000803d0:	f100001f 	cmp	x0, #0x0
ffff0000000803d4:	54fffbe1 	b.ne	ffff000000080350 <remove_list+0x28>  // b.any
ffff0000000803d8:	14000002 	b	ffff0000000803e0 <remove_list+0xb8>
ffff0000000803dc:	d503201f 	nop
ffff0000000803e0:	f9400fe0 	ldr	x0, [sp, #24]
ffff0000000803e4:	9100c3ff 	add	sp, sp, #0x30
ffff0000000803e8:	d65f03c0 	ret

ffff0000000803ec <write_char>:
ffff0000000803ec:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff0000000803f0:	910003fd 	mov	x29, sp
ffff0000000803f4:	39007fe0 	strb	w0, [sp, #31]
ffff0000000803f8:	d503201f 	nop
ffff0000000803fc:	d2820300 	mov	x0, #0x1018                	// #4120
ffff000000080400:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff000000080404:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000080408:	97ffff61 	bl	ffff00000008018c <in_word>
ffff00000008040c:	121d0000 	and	w0, w0, #0x8
ffff000000080410:	7100001f 	cmp	w0, #0x0
ffff000000080414:	54ffff41 	b.ne	ffff0000000803fc <write_char+0x10>  // b.any
ffff000000080418:	39407fe0 	ldrb	w0, [sp, #31]
ffff00000008041c:	2a0003e1 	mov	w1, w0
ffff000000080420:	d2820000 	mov	x0, #0x1000                	// #4096
ffff000000080424:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff000000080428:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff00000008042c:	97ffff56 	bl	ffff000000080184 <out_word>
ffff000000080430:	d503201f 	nop
ffff000000080434:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff000000080438:	d65f03c0 	ret

ffff00000008043c <read_char>:
ffff00000008043c:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffff000000080440:	910003fd 	mov	x29, sp
ffff000000080444:	d2820000 	mov	x0, #0x1000                	// #4096
ffff000000080448:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff00000008044c:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000080450:	97ffff4f 	bl	ffff00000008018c <in_word>
ffff000000080454:	12001c00 	and	w0, w0, #0xff
ffff000000080458:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffff00000008045c:	d65f03c0 	ret

ffff000000080460 <write_string>:
ffff000000080460:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff000000080464:	910003fd 	mov	x29, sp
ffff000000080468:	f9000fe0 	str	x0, [sp, #24]
ffff00000008046c:	b9002fff 	str	wzr, [sp, #44]
ffff000000080470:	14000009 	b	ffff000000080494 <write_string+0x34>
ffff000000080474:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff000000080478:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008047c:	8b000020 	add	x0, x1, x0
ffff000000080480:	39400000 	ldrb	w0, [x0]
ffff000000080484:	97ffffda 	bl	ffff0000000803ec <write_char>
ffff000000080488:	b9402fe0 	ldr	w0, [sp, #44]
ffff00000008048c:	11000400 	add	w0, w0, #0x1
ffff000000080490:	b9002fe0 	str	w0, [sp, #44]
ffff000000080494:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff000000080498:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008049c:	8b000020 	add	x0, x1, x0
ffff0000000804a0:	39400000 	ldrb	w0, [x0]
ffff0000000804a4:	7100001f 	cmp	w0, #0x0
ffff0000000804a8:	54fffe61 	b.ne	ffff000000080474 <write_string+0x14>  // b.any
ffff0000000804ac:	d503201f 	nop
ffff0000000804b0:	d503201f 	nop
ffff0000000804b4:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff0000000804b8:	d65f03c0 	ret

ffff0000000804bc <uart_handler>:
ffff0000000804bc:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff0000000804c0:	910003fd 	mov	x29, sp
ffff0000000804c4:	d2820800 	mov	x0, #0x1040                	// #4160
ffff0000000804c8:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff0000000804cc:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff0000000804d0:	97ffff2f 	bl	ffff00000008018c <in_word>
ffff0000000804d4:	b9001fe0 	str	w0, [sp, #28]
ffff0000000804d8:	b9401fe0 	ldr	w0, [sp, #28]
ffff0000000804dc:	121c0000 	and	w0, w0, #0x10
ffff0000000804e0:	7100001f 	cmp	w0, #0x0
ffff0000000804e4:	54000220 	b.eq	ffff000000080528 <uart_handler+0x6c>  // b.none
ffff0000000804e8:	97ffffd5 	bl	ffff00000008043c <read_char>
ffff0000000804ec:	39006fe0 	strb	w0, [sp, #27]
ffff0000000804f0:	39406fe0 	ldrb	w0, [sp, #27]
ffff0000000804f4:	7100341f 	cmp	w0, #0xd
ffff0000000804f8:	540000a1 	b.ne	ffff00000008050c <uart_handler+0x50>  // b.any
ffff0000000804fc:	90000060 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff000000080500:	91024000 	add	x0, x0, #0x90
ffff000000080504:	97ffffd7 	bl	ffff000000080460 <write_string>
ffff000000080508:	14000003 	b	ffff000000080514 <uart_handler+0x58>
ffff00000008050c:	39406fe0 	ldrb	w0, [sp, #27]
ffff000000080510:	97ffffb7 	bl	ffff0000000803ec <write_char>
ffff000000080514:	52800201 	mov	w1, #0x10                  	// #16
ffff000000080518:	d2820880 	mov	x0, #0x1044                	// #4164
ffff00000008051c:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff000000080520:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000080524:	97ffff18 	bl	ffff000000080184 <out_word>
ffff000000080528:	d503201f 	nop
ffff00000008052c:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff000000080530:	d65f03c0 	ret

ffff000000080534 <init_uart>:
ffff000000080534:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff000000080538:	910003fd 	mov	x29, sp
ffff00000008053c:	52800001 	mov	w1, #0x0                   	// #0
ffff000000080540:	d2820600 	mov	x0, #0x1030                	// #4144
ffff000000080544:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff000000080548:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff00000008054c:	97ffff0e 	bl	ffff000000080184 <out_word>
ffff000000080550:	d2800080 	mov	x0, #0x4                   	// #4
ffff000000080554:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff000000080558:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff00000008055c:	97ffff0c 	bl	ffff00000008018c <in_word>
ffff000000080560:	b9001fe0 	str	w0, [sp, #28]
ffff000000080564:	b9401fe0 	ldr	w0, [sp, #28]
ffff000000080568:	120e6400 	and	w0, w0, #0xfffc0fff
ffff00000008056c:	b9001fe0 	str	w0, [sp, #28]
ffff000000080570:	b9401fe1 	ldr	w1, [sp, #28]
ffff000000080574:	52880000 	mov	w0, #0x4000                	// #16384
ffff000000080578:	72a00040 	movk	w0, #0x2, lsl #16
ffff00000008057c:	2a000020 	orr	w0, w1, w0
ffff000000080580:	b9001fe0 	str	w0, [sp, #28]
ffff000000080584:	b9401fe1 	ldr	w1, [sp, #28]
ffff000000080588:	d2800080 	mov	x0, #0x4                   	// #4
ffff00000008058c:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff000000080590:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000080594:	97fffefc 	bl	ffff000000080184 <out_word>
ffff000000080598:	52800001 	mov	w1, #0x0                   	// #0
ffff00000008059c:	d2801280 	mov	x0, #0x94                  	// #148
ffff0000000805a0:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff0000000805a4:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff0000000805a8:	97fffef7 	bl	ffff000000080184 <out_word>
ffff0000000805ac:	d28012c0 	mov	x0, #0x96                  	// #150
ffff0000000805b0:	97fffef2 	bl	ffff000000080178 <delay>
ffff0000000805b4:	52980001 	mov	w1, #0xc000                	// #49152
ffff0000000805b8:	d2801300 	mov	x0, #0x98                  	// #152
ffff0000000805bc:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff0000000805c0:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff0000000805c4:	97fffef0 	bl	ffff000000080184 <out_word>
ffff0000000805c8:	d28012c0 	mov	x0, #0x96                  	// #150
ffff0000000805cc:	97fffeeb 	bl	ffff000000080178 <delay>
ffff0000000805d0:	52800001 	mov	w1, #0x0                   	// #0
ffff0000000805d4:	d2801300 	mov	x0, #0x98                  	// #152
ffff0000000805d8:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff0000000805dc:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff0000000805e0:	97fffee9 	bl	ffff000000080184 <out_word>
ffff0000000805e4:	5280ffe1 	mov	w1, #0x7ff                 	// #2047
ffff0000000805e8:	d2820880 	mov	x0, #0x1044                	// #4164
ffff0000000805ec:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff0000000805f0:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff0000000805f4:	97fffee4 	bl	ffff000000080184 <out_word>
ffff0000000805f8:	52800341 	mov	w1, #0x1a                  	// #26
ffff0000000805fc:	d2820480 	mov	x0, #0x1024                	// #4132
ffff000000080600:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff000000080604:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000080608:	97fffedf 	bl	ffff000000080184 <out_word>
ffff00000008060c:	52800061 	mov	w1, #0x3                   	// #3
ffff000000080610:	d2820500 	mov	x0, #0x1028                	// #4136
ffff000000080614:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff000000080618:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff00000008061c:	97fffeda 	bl	ffff000000080184 <out_word>
ffff000000080620:	52800c01 	mov	w1, #0x60                  	// #96
ffff000000080624:	d2820580 	mov	x0, #0x102c                	// #4140
ffff000000080628:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff00000008062c:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000080630:	97fffed5 	bl	ffff000000080184 <out_word>
ffff000000080634:	52800201 	mov	w1, #0x10                  	// #16
ffff000000080638:	d2820700 	mov	x0, #0x1038                	// #4152
ffff00000008063c:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff000000080640:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000080644:	97fffed0 	bl	ffff000000080184 <out_word>
ffff000000080648:	52806021 	mov	w1, #0x301                 	// #769
ffff00000008064c:	d2820600 	mov	x0, #0x1030                	// #4144
ffff000000080650:	f2a7e400 	movk	x0, #0x3f20, lsl #16
ffff000000080654:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000080658:	97fffecb 	bl	ffff000000080184 <out_word>
ffff00000008065c:	d503201f 	nop
ffff000000080660:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff000000080664:	d65f03c0 	ret

ffff000000080668 <read_string>:
ffff000000080668:	d100c3ff 	sub	sp, sp, #0x30
ffff00000008066c:	f9000fe0 	str	x0, [sp, #24]
ffff000000080670:	b90017e1 	str	w1, [sp, #20]
ffff000000080674:	f90007e2 	str	x2, [sp, #8]
ffff000000080678:	b9002fff 	str	wzr, [sp, #44]
ffff00000008067c:	b9002fff 	str	wzr, [sp, #44]
ffff000000080680:	1400000f 	b	ffff0000000806bc <read_string+0x54>
ffff000000080684:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff000000080688:	f94007e1 	ldr	x1, [sp, #8]
ffff00000008068c:	8b000021 	add	x1, x1, x0
ffff000000080690:	b94017e0 	ldr	w0, [sp, #20]
ffff000000080694:	11000402 	add	w2, w0, #0x1
ffff000000080698:	b90017e2 	str	w2, [sp, #20]
ffff00000008069c:	93407c00 	sxtw	x0, w0
ffff0000000806a0:	f9400fe2 	ldr	x2, [sp, #24]
ffff0000000806a4:	8b000040 	add	x0, x2, x0
ffff0000000806a8:	39400021 	ldrb	w1, [x1]
ffff0000000806ac:	39000001 	strb	w1, [x0]
ffff0000000806b0:	b9402fe0 	ldr	w0, [sp, #44]
ffff0000000806b4:	11000400 	add	w0, w0, #0x1
ffff0000000806b8:	b9002fe0 	str	w0, [sp, #44]
ffff0000000806bc:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff0000000806c0:	f94007e1 	ldr	x1, [sp, #8]
ffff0000000806c4:	8b000020 	add	x0, x1, x0
ffff0000000806c8:	39400000 	ldrb	w0, [x0]
ffff0000000806cc:	7100001f 	cmp	w0, #0x0
ffff0000000806d0:	54fffda1 	b.ne	ffff000000080684 <read_string+0x1c>  // b.any
ffff0000000806d4:	b9402fe0 	ldr	w0, [sp, #44]
ffff0000000806d8:	9100c3ff 	add	sp, sp, #0x30
ffff0000000806dc:	d65f03c0 	ret

ffff0000000806e0 <hex_to_string>:
ffff0000000806e0:	d10183ff 	sub	sp, sp, #0x60
ffff0000000806e4:	f9000fe0 	str	x0, [sp, #24]
ffff0000000806e8:	b90017e1 	str	w1, [sp, #20]
ffff0000000806ec:	f90007e2 	str	x2, [sp, #8]
ffff0000000806f0:	90000060 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff0000000806f4:	91026000 	add	x0, x0, #0x98
ffff0000000806f8:	a9400400 	ldp	x0, x1, [x0]
ffff0000000806fc:	a90287e0 	stp	x0, x1, [sp, #40]
ffff000000080700:	b9005fff 	str	wzr, [sp, #92]
ffff000000080704:	f94007e0 	ldr	x0, [sp, #8]
ffff000000080708:	92400c01 	and	x1, x0, #0xf
ffff00000008070c:	b9405fe0 	ldr	w0, [sp, #92]
ffff000000080710:	11000402 	add	w2, w0, #0x1
ffff000000080714:	b9005fe2 	str	w2, [sp, #92]
ffff000000080718:	9100a3e2 	add	x2, sp, #0x28
ffff00000008071c:	38616842 	ldrb	w2, [x2, x1]
ffff000000080720:	93407c00 	sxtw	x0, w0
ffff000000080724:	9100e3e1 	add	x1, sp, #0x38
ffff000000080728:	38206822 	strb	w2, [x1, x0]
ffff00000008072c:	f94007e0 	ldr	x0, [sp, #8]
ffff000000080730:	d344fc00 	lsr	x0, x0, #4
ffff000000080734:	f90007e0 	str	x0, [sp, #8]
ffff000000080738:	f94007e0 	ldr	x0, [sp, #8]
ffff00000008073c:	f100001f 	cmp	x0, #0x0
ffff000000080740:	54fffe21 	b.ne	ffff000000080704 <hex_to_string+0x24>  // b.any
ffff000000080744:	b9405fe0 	ldr	w0, [sp, #92]
ffff000000080748:	51000400 	sub	w0, w0, #0x1
ffff00000008074c:	b9005be0 	str	w0, [sp, #88]
ffff000000080750:	1400000e 	b	ffff000000080788 <hex_to_string+0xa8>
ffff000000080754:	b94017e0 	ldr	w0, [sp, #20]
ffff000000080758:	11000401 	add	w1, w0, #0x1
ffff00000008075c:	b90017e1 	str	w1, [sp, #20]
ffff000000080760:	93407c00 	sxtw	x0, w0
ffff000000080764:	f9400fe1 	ldr	x1, [sp, #24]
ffff000000080768:	8b000020 	add	x0, x1, x0
ffff00000008076c:	b9805be1 	ldrsw	x1, [sp, #88]
ffff000000080770:	9100e3e2 	add	x2, sp, #0x38
ffff000000080774:	38616841 	ldrb	w1, [x2, x1]
ffff000000080778:	39000001 	strb	w1, [x0]
ffff00000008077c:	b9405be0 	ldr	w0, [sp, #88]
ffff000000080780:	51000400 	sub	w0, w0, #0x1
ffff000000080784:	b9005be0 	str	w0, [sp, #88]
ffff000000080788:	b9405be0 	ldr	w0, [sp, #88]
ffff00000008078c:	7100001f 	cmp	w0, #0x0
ffff000000080790:	54fffe2a 	b.ge	ffff000000080754 <hex_to_string+0x74>  // b.tcont
ffff000000080794:	b94017e0 	ldr	w0, [sp, #20]
ffff000000080798:	11000401 	add	w1, w0, #0x1
ffff00000008079c:	b90017e1 	str	w1, [sp, #20]
ffff0000000807a0:	93407c00 	sxtw	x0, w0
ffff0000000807a4:	f9400fe1 	ldr	x1, [sp, #24]
ffff0000000807a8:	8b000020 	add	x0, x1, x0
ffff0000000807ac:	52800901 	mov	w1, #0x48                  	// #72
ffff0000000807b0:	39000001 	strb	w1, [x0]
ffff0000000807b4:	b9405fe0 	ldr	w0, [sp, #92]
ffff0000000807b8:	11000400 	add	w0, w0, #0x1
ffff0000000807bc:	910183ff 	add	sp, sp, #0x60
ffff0000000807c0:	d65f03c0 	ret

ffff0000000807c4 <udecimal_to_string>:
ffff0000000807c4:	d10183ff 	sub	sp, sp, #0x60
ffff0000000807c8:	f9000fe0 	str	x0, [sp, #24]
ffff0000000807cc:	b90017e1 	str	w1, [sp, #20]
ffff0000000807d0:	f90007e2 	str	x2, [sp, #8]
ffff0000000807d4:	90000060 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff0000000807d8:	9102a001 	add	x1, x0, #0xa8
ffff0000000807dc:	910123e0 	add	x0, sp, #0x48
ffff0000000807e0:	f9400022 	ldr	x2, [x1]
ffff0000000807e4:	79401021 	ldrh	w1, [x1, #8]
ffff0000000807e8:	f9000002 	str	x2, [x0]
ffff0000000807ec:	79001001 	strh	w1, [x0, #8]
ffff0000000807f0:	b9005fff 	str	wzr, [sp, #92]
ffff0000000807f4:	f94007e2 	ldr	x2, [sp, #8]
ffff0000000807f8:	b202e7e0 	mov	x0, #0xcccccccccccccccc    	// #-3689348814741910324
ffff0000000807fc:	f29999a0 	movk	x0, #0xcccd
ffff000000080800:	9bc07c40 	umulh	x0, x2, x0
ffff000000080804:	d343fc01 	lsr	x1, x0, #3
ffff000000080808:	aa0103e0 	mov	x0, x1
ffff00000008080c:	d37ef400 	lsl	x0, x0, #2
ffff000000080810:	8b010000 	add	x0, x0, x1
ffff000000080814:	8b000000 	add	x0, x0, x0
ffff000000080818:	cb000041 	sub	x1, x2, x0
ffff00000008081c:	b9405fe0 	ldr	w0, [sp, #92]
ffff000000080820:	11000402 	add	w2, w0, #0x1
ffff000000080824:	b9005fe2 	str	w2, [sp, #92]
ffff000000080828:	910123e2 	add	x2, sp, #0x48
ffff00000008082c:	38616842 	ldrb	w2, [x2, x1]
ffff000000080830:	93407c00 	sxtw	x0, w0
ffff000000080834:	9100a3e1 	add	x1, sp, #0x28
ffff000000080838:	38206822 	strb	w2, [x1, x0]
ffff00000008083c:	f94007e1 	ldr	x1, [sp, #8]
ffff000000080840:	b202e7e0 	mov	x0, #0xcccccccccccccccc    	// #-3689348814741910324
ffff000000080844:	f29999a0 	movk	x0, #0xcccd
ffff000000080848:	9bc07c20 	umulh	x0, x1, x0
ffff00000008084c:	d343fc00 	lsr	x0, x0, #3
ffff000000080850:	f90007e0 	str	x0, [sp, #8]
ffff000000080854:	f94007e0 	ldr	x0, [sp, #8]
ffff000000080858:	f100001f 	cmp	x0, #0x0
ffff00000008085c:	54fffcc1 	b.ne	ffff0000000807f4 <udecimal_to_string+0x30>  // b.any
ffff000000080860:	b9405fe0 	ldr	w0, [sp, #92]
ffff000000080864:	51000400 	sub	w0, w0, #0x1
ffff000000080868:	b9005be0 	str	w0, [sp, #88]
ffff00000008086c:	1400000e 	b	ffff0000000808a4 <udecimal_to_string+0xe0>
ffff000000080870:	b94017e0 	ldr	w0, [sp, #20]
ffff000000080874:	11000401 	add	w1, w0, #0x1
ffff000000080878:	b90017e1 	str	w1, [sp, #20]
ffff00000008087c:	93407c00 	sxtw	x0, w0
ffff000000080880:	f9400fe1 	ldr	x1, [sp, #24]
ffff000000080884:	8b000020 	add	x0, x1, x0
ffff000000080888:	b9805be1 	ldrsw	x1, [sp, #88]
ffff00000008088c:	9100a3e2 	add	x2, sp, #0x28
ffff000000080890:	38616841 	ldrb	w1, [x2, x1]
ffff000000080894:	39000001 	strb	w1, [x0]
ffff000000080898:	b9405be0 	ldr	w0, [sp, #88]
ffff00000008089c:	51000400 	sub	w0, w0, #0x1
ffff0000000808a0:	b9005be0 	str	w0, [sp, #88]
ffff0000000808a4:	b9405be0 	ldr	w0, [sp, #88]
ffff0000000808a8:	7100001f 	cmp	w0, #0x0
ffff0000000808ac:	54fffe2a 	b.ge	ffff000000080870 <udecimal_to_string+0xac>  // b.tcont
ffff0000000808b0:	b9405fe0 	ldr	w0, [sp, #92]
ffff0000000808b4:	910183ff 	add	sp, sp, #0x60
ffff0000000808b8:	d65f03c0 	ret

ffff0000000808bc <decimal_to_string>:
ffff0000000808bc:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff0000000808c0:	910003fd 	mov	x29, sp
ffff0000000808c4:	f90017e0 	str	x0, [sp, #40]
ffff0000000808c8:	b90027e1 	str	w1, [sp, #36]
ffff0000000808cc:	f9000fe2 	str	x2, [sp, #24]
ffff0000000808d0:	b9003fff 	str	wzr, [sp, #60]
ffff0000000808d4:	f9400fe0 	ldr	x0, [sp, #24]
ffff0000000808d8:	f100001f 	cmp	x0, #0x0
ffff0000000808dc:	540001ca 	b.ge	ffff000000080914 <decimal_to_string+0x58>  // b.tcont
ffff0000000808e0:	f9400fe0 	ldr	x0, [sp, #24]
ffff0000000808e4:	cb0003e0 	neg	x0, x0
ffff0000000808e8:	f9000fe0 	str	x0, [sp, #24]
ffff0000000808ec:	b94027e0 	ldr	w0, [sp, #36]
ffff0000000808f0:	11000401 	add	w1, w0, #0x1
ffff0000000808f4:	b90027e1 	str	w1, [sp, #36]
ffff0000000808f8:	93407c00 	sxtw	x0, w0
ffff0000000808fc:	f94017e1 	ldr	x1, [sp, #40]
ffff000000080900:	8b000020 	add	x0, x1, x0
ffff000000080904:	528005a1 	mov	w1, #0x2d                  	// #45
ffff000000080908:	39000001 	strb	w1, [x0]
ffff00000008090c:	52800020 	mov	w0, #0x1                   	// #1
ffff000000080910:	b9003fe0 	str	w0, [sp, #60]
ffff000000080914:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000080918:	aa0003e2 	mov	x2, x0
ffff00000008091c:	b94027e1 	ldr	w1, [sp, #36]
ffff000000080920:	f94017e0 	ldr	x0, [sp, #40]
ffff000000080924:	97ffffa8 	bl	ffff0000000807c4 <udecimal_to_string>
ffff000000080928:	2a0003e1 	mov	w1, w0
ffff00000008092c:	b9403fe0 	ldr	w0, [sp, #60]
ffff000000080930:	0b010000 	add	w0, w0, w1
ffff000000080934:	b9003fe0 	str	w0, [sp, #60]
ffff000000080938:	b9403fe0 	ldr	w0, [sp, #60]
ffff00000008093c:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff000000080940:	d65f03c0 	ret

ffff000000080944 <write_console>:
ffff000000080944:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff000000080948:	910003fd 	mov	x29, sp
ffff00000008094c:	f9000fe0 	str	x0, [sp, #24]
ffff000000080950:	b90017e1 	str	w1, [sp, #20]
ffff000000080954:	b9002fff 	str	wzr, [sp, #44]
ffff000000080958:	14000009 	b	ffff00000008097c <write_console+0x38>
ffff00000008095c:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff000000080960:	f9400fe1 	ldr	x1, [sp, #24]
ffff000000080964:	8b000020 	add	x0, x1, x0
ffff000000080968:	39400000 	ldrb	w0, [x0]
ffff00000008096c:	97fffea0 	bl	ffff0000000803ec <write_char>
ffff000000080970:	b9402fe0 	ldr	w0, [sp, #44]
ffff000000080974:	11000400 	add	w0, w0, #0x1
ffff000000080978:	b9002fe0 	str	w0, [sp, #44]
ffff00000008097c:	b9402fe1 	ldr	w1, [sp, #44]
ffff000000080980:	b94017e0 	ldr	w0, [sp, #20]
ffff000000080984:	6b00003f 	cmp	w1, w0
ffff000000080988:	54fffeab 	b.lt	ffff00000008095c <write_console+0x18>  // b.tstop
ffff00000008098c:	d503201f 	nop
ffff000000080990:	d503201f 	nop
ffff000000080994:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff000000080998:	d65f03c0 	ret

ffff00000008099c <printk>:
ffff00000008099c:	d11283ff 	sub	sp, sp, #0x4a0
ffff0000000809a0:	a9007bfd 	stp	x29, x30, [sp]
ffff0000000809a4:	910003fd 	mov	x29, sp
ffff0000000809a8:	f9000fe0 	str	x0, [sp, #24]
ffff0000000809ac:	f90237e1 	str	x1, [sp, #1128]
ffff0000000809b0:	f9023be2 	str	x2, [sp, #1136]
ffff0000000809b4:	f9023fe3 	str	x3, [sp, #1144]
ffff0000000809b8:	f90243e4 	str	x4, [sp, #1152]
ffff0000000809bc:	f90247e5 	str	x5, [sp, #1160]
ffff0000000809c0:	f9024be6 	str	x6, [sp, #1168]
ffff0000000809c4:	f9024fe7 	str	x7, [sp, #1176]
ffff0000000809c8:	b9045fff 	str	wzr, [sp, #1116]
ffff0000000809cc:	f9022bff 	str	xzr, [sp, #1104]
ffff0000000809d0:	f90227ff 	str	xzr, [sp, #1096]
ffff0000000809d4:	911283e0 	add	x0, sp, #0x4a0
ffff0000000809d8:	f90017e0 	str	x0, [sp, #40]
ffff0000000809dc:	911283e0 	add	x0, sp, #0x4a0
ffff0000000809e0:	f9001be0 	str	x0, [sp, #48]
ffff0000000809e4:	911183e0 	add	x0, sp, #0x460
ffff0000000809e8:	f9001fe0 	str	x0, [sp, #56]
ffff0000000809ec:	128006e0 	mov	w0, #0xffffffc8            	// #-56
ffff0000000809f0:	b90043e0 	str	w0, [sp, #64]
ffff0000000809f4:	b90047ff 	str	wzr, [sp, #68]
ffff0000000809f8:	b9045bff 	str	wzr, [sp, #1112]
ffff0000000809fc:	140000b1 	b	ffff000000080cc0 <printk+0x324>
ffff000000080a00:	b9845be0 	ldrsw	x0, [sp, #1112]
ffff000000080a04:	f9400fe1 	ldr	x1, [sp, #24]
ffff000000080a08:	8b000020 	add	x0, x1, x0
ffff000000080a0c:	39400000 	ldrb	w0, [x0]
ffff000000080a10:	7100941f 	cmp	w0, #0x25
ffff000000080a14:	54000180 	b.eq	ffff000000080a44 <printk+0xa8>  // b.none
ffff000000080a18:	b9845be0 	ldrsw	x0, [sp, #1112]
ffff000000080a1c:	f9400fe1 	ldr	x1, [sp, #24]
ffff000000080a20:	8b000021 	add	x1, x1, x0
ffff000000080a24:	b9445fe0 	ldr	w0, [sp, #1116]
ffff000000080a28:	11000402 	add	w2, w0, #0x1
ffff000000080a2c:	b9045fe2 	str	w2, [sp, #1116]
ffff000000080a30:	39400022 	ldrb	w2, [x1]
ffff000000080a34:	93407c00 	sxtw	x0, w0
ffff000000080a38:	910123e1 	add	x1, sp, #0x48
ffff000000080a3c:	38206822 	strb	w2, [x1, x0]
ffff000000080a40:	1400009d 	b	ffff000000080cb4 <printk+0x318>
ffff000000080a44:	b9445be0 	ldr	w0, [sp, #1112]
ffff000000080a48:	11000400 	add	w0, w0, #0x1
ffff000000080a4c:	b9045be0 	str	w0, [sp, #1112]
ffff000000080a50:	b9845be0 	ldrsw	x0, [sp, #1112]
ffff000000080a54:	f9400fe1 	ldr	x1, [sp, #24]
ffff000000080a58:	8b000020 	add	x0, x1, x0
ffff000000080a5c:	39400000 	ldrb	w0, [x0]
ffff000000080a60:	7101e01f 	cmp	w0, #0x78
ffff000000080a64:	54000180 	b.eq	ffff000000080a94 <printk+0xf8>  // b.none
ffff000000080a68:	7101e01f 	cmp	w0, #0x78
ffff000000080a6c:	5400110c 	b.gt	ffff000000080c8c <printk+0x2f0>
ffff000000080a70:	7101d41f 	cmp	w0, #0x75
ffff000000080a74:	54000500 	b.eq	ffff000000080b14 <printk+0x178>  // b.none
ffff000000080a78:	7101d41f 	cmp	w0, #0x75
ffff000000080a7c:	5400108c 	b.gt	ffff000000080c8c <printk+0x2f0>
ffff000000080a80:	7101901f 	cmp	w0, #0x64
ffff000000080a84:	54000880 	b.eq	ffff000000080b94 <printk+0x1f8>  // b.none
ffff000000080a88:	7101cc1f 	cmp	w0, #0x73
ffff000000080a8c:	54000c20 	b.eq	ffff000000080c10 <printk+0x274>  // b.none
ffff000000080a90:	1400007f 	b	ffff000000080c8c <printk+0x2f0>
ffff000000080a94:	b94043e1 	ldr	w1, [sp, #64]
ffff000000080a98:	f94017e0 	ldr	x0, [sp, #40]
ffff000000080a9c:	7100003f 	cmp	w1, #0x0
ffff000000080aa0:	540000ab 	b.lt	ffff000000080ab4 <printk+0x118>  // b.tstop
ffff000000080aa4:	91003c01 	add	x1, x0, #0xf
ffff000000080aa8:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff000000080aac:	f90017e1 	str	x1, [sp, #40]
ffff000000080ab0:	1400000d 	b	ffff000000080ae4 <printk+0x148>
ffff000000080ab4:	11002022 	add	w2, w1, #0x8
ffff000000080ab8:	b90043e2 	str	w2, [sp, #64]
ffff000000080abc:	b94043e2 	ldr	w2, [sp, #64]
ffff000000080ac0:	7100005f 	cmp	w2, #0x0
ffff000000080ac4:	540000ad 	b.le	ffff000000080ad8 <printk+0x13c>
ffff000000080ac8:	91003c01 	add	x1, x0, #0xf
ffff000000080acc:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff000000080ad0:	f90017e1 	str	x1, [sp, #40]
ffff000000080ad4:	14000004 	b	ffff000000080ae4 <printk+0x148>
ffff000000080ad8:	f9401be2 	ldr	x2, [sp, #48]
ffff000000080adc:	93407c20 	sxtw	x0, w1
ffff000000080ae0:	8b000040 	add	x0, x2, x0
ffff000000080ae4:	f9400000 	ldr	x0, [x0]
ffff000000080ae8:	f9022be0 	str	x0, [sp, #1104]
ffff000000080aec:	f9422be1 	ldr	x1, [sp, #1104]
ffff000000080af0:	910123e0 	add	x0, sp, #0x48
ffff000000080af4:	aa0103e2 	mov	x2, x1
ffff000000080af8:	b9445fe1 	ldr	w1, [sp, #1116]
ffff000000080afc:	97fffef9 	bl	ffff0000000806e0 <hex_to_string>
ffff000000080b00:	2a0003e1 	mov	w1, w0
ffff000000080b04:	b9445fe0 	ldr	w0, [sp, #1116]
ffff000000080b08:	0b010000 	add	w0, w0, w1
ffff000000080b0c:	b9045fe0 	str	w0, [sp, #1116]
ffff000000080b10:	14000069 	b	ffff000000080cb4 <printk+0x318>
ffff000000080b14:	b94043e1 	ldr	w1, [sp, #64]
ffff000000080b18:	f94017e0 	ldr	x0, [sp, #40]
ffff000000080b1c:	7100003f 	cmp	w1, #0x0
ffff000000080b20:	540000ab 	b.lt	ffff000000080b34 <printk+0x198>  // b.tstop
ffff000000080b24:	91003c01 	add	x1, x0, #0xf
ffff000000080b28:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff000000080b2c:	f90017e1 	str	x1, [sp, #40]
ffff000000080b30:	1400000d 	b	ffff000000080b64 <printk+0x1c8>
ffff000000080b34:	11002022 	add	w2, w1, #0x8
ffff000000080b38:	b90043e2 	str	w2, [sp, #64]
ffff000000080b3c:	b94043e2 	ldr	w2, [sp, #64]
ffff000000080b40:	7100005f 	cmp	w2, #0x0
ffff000000080b44:	540000ad 	b.le	ffff000000080b58 <printk+0x1bc>
ffff000000080b48:	91003c01 	add	x1, x0, #0xf
ffff000000080b4c:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff000000080b50:	f90017e1 	str	x1, [sp, #40]
ffff000000080b54:	14000004 	b	ffff000000080b64 <printk+0x1c8>
ffff000000080b58:	f9401be2 	ldr	x2, [sp, #48]
ffff000000080b5c:	93407c20 	sxtw	x0, w1
ffff000000080b60:	8b000040 	add	x0, x2, x0
ffff000000080b64:	f9400000 	ldr	x0, [x0]
ffff000000080b68:	f9022be0 	str	x0, [sp, #1104]
ffff000000080b6c:	f9422be1 	ldr	x1, [sp, #1104]
ffff000000080b70:	910123e0 	add	x0, sp, #0x48
ffff000000080b74:	aa0103e2 	mov	x2, x1
ffff000000080b78:	b9445fe1 	ldr	w1, [sp, #1116]
ffff000000080b7c:	97ffff12 	bl	ffff0000000807c4 <udecimal_to_string>
ffff000000080b80:	2a0003e1 	mov	w1, w0
ffff000000080b84:	b9445fe0 	ldr	w0, [sp, #1116]
ffff000000080b88:	0b010000 	add	w0, w0, w1
ffff000000080b8c:	b9045fe0 	str	w0, [sp, #1116]
ffff000000080b90:	14000049 	b	ffff000000080cb4 <printk+0x318>
ffff000000080b94:	b94043e1 	ldr	w1, [sp, #64]
ffff000000080b98:	f94017e0 	ldr	x0, [sp, #40]
ffff000000080b9c:	7100003f 	cmp	w1, #0x0
ffff000000080ba0:	540000ab 	b.lt	ffff000000080bb4 <printk+0x218>  // b.tstop
ffff000000080ba4:	91003c01 	add	x1, x0, #0xf
ffff000000080ba8:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff000000080bac:	f90017e1 	str	x1, [sp, #40]
ffff000000080bb0:	1400000d 	b	ffff000000080be4 <printk+0x248>
ffff000000080bb4:	11002022 	add	w2, w1, #0x8
ffff000000080bb8:	b90043e2 	str	w2, [sp, #64]
ffff000000080bbc:	b94043e2 	ldr	w2, [sp, #64]
ffff000000080bc0:	7100005f 	cmp	w2, #0x0
ffff000000080bc4:	540000ad 	b.le	ffff000000080bd8 <printk+0x23c>
ffff000000080bc8:	91003c01 	add	x1, x0, #0xf
ffff000000080bcc:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff000000080bd0:	f90017e1 	str	x1, [sp, #40]
ffff000000080bd4:	14000004 	b	ffff000000080be4 <printk+0x248>
ffff000000080bd8:	f9401be2 	ldr	x2, [sp, #48]
ffff000000080bdc:	93407c20 	sxtw	x0, w1
ffff000000080be0:	8b000040 	add	x0, x2, x0
ffff000000080be4:	f9400000 	ldr	x0, [x0]
ffff000000080be8:	f9022be0 	str	x0, [sp, #1104]
ffff000000080bec:	910123e0 	add	x0, sp, #0x48
ffff000000080bf0:	f9422be2 	ldr	x2, [sp, #1104]
ffff000000080bf4:	b9445fe1 	ldr	w1, [sp, #1116]
ffff000000080bf8:	97ffff31 	bl	ffff0000000808bc <decimal_to_string>
ffff000000080bfc:	2a0003e1 	mov	w1, w0
ffff000000080c00:	b9445fe0 	ldr	w0, [sp, #1116]
ffff000000080c04:	0b010000 	add	w0, w0, w1
ffff000000080c08:	b9045fe0 	str	w0, [sp, #1116]
ffff000000080c0c:	1400002a 	b	ffff000000080cb4 <printk+0x318>
ffff000000080c10:	b94043e1 	ldr	w1, [sp, #64]
ffff000000080c14:	f94017e0 	ldr	x0, [sp, #40]
ffff000000080c18:	7100003f 	cmp	w1, #0x0
ffff000000080c1c:	540000ab 	b.lt	ffff000000080c30 <printk+0x294>  // b.tstop
ffff000000080c20:	91003c01 	add	x1, x0, #0xf
ffff000000080c24:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff000000080c28:	f90017e1 	str	x1, [sp, #40]
ffff000000080c2c:	1400000d 	b	ffff000000080c60 <printk+0x2c4>
ffff000000080c30:	11002022 	add	w2, w1, #0x8
ffff000000080c34:	b90043e2 	str	w2, [sp, #64]
ffff000000080c38:	b94043e2 	ldr	w2, [sp, #64]
ffff000000080c3c:	7100005f 	cmp	w2, #0x0
ffff000000080c40:	540000ad 	b.le	ffff000000080c54 <printk+0x2b8>
ffff000000080c44:	91003c01 	add	x1, x0, #0xf
ffff000000080c48:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff000000080c4c:	f90017e1 	str	x1, [sp, #40]
ffff000000080c50:	14000004 	b	ffff000000080c60 <printk+0x2c4>
ffff000000080c54:	f9401be2 	ldr	x2, [sp, #48]
ffff000000080c58:	93407c20 	sxtw	x0, w1
ffff000000080c5c:	8b000040 	add	x0, x2, x0
ffff000000080c60:	f9400000 	ldr	x0, [x0]
ffff000000080c64:	f90227e0 	str	x0, [sp, #1096]
ffff000000080c68:	910123e0 	add	x0, sp, #0x48
ffff000000080c6c:	f94227e2 	ldr	x2, [sp, #1096]
ffff000000080c70:	b9445fe1 	ldr	w1, [sp, #1116]
ffff000000080c74:	97fffe7d 	bl	ffff000000080668 <read_string>
ffff000000080c78:	2a0003e1 	mov	w1, w0
ffff000000080c7c:	b9445fe0 	ldr	w0, [sp, #1116]
ffff000000080c80:	0b010000 	add	w0, w0, w1
ffff000000080c84:	b9045fe0 	str	w0, [sp, #1116]
ffff000000080c88:	1400000b 	b	ffff000000080cb4 <printk+0x318>
ffff000000080c8c:	b9445fe0 	ldr	w0, [sp, #1116]
ffff000000080c90:	11000401 	add	w1, w0, #0x1
ffff000000080c94:	b9045fe1 	str	w1, [sp, #1116]
ffff000000080c98:	93407c00 	sxtw	x0, w0
ffff000000080c9c:	910123e1 	add	x1, sp, #0x48
ffff000000080ca0:	528004a2 	mov	w2, #0x25                  	// #37
ffff000000080ca4:	38206822 	strb	w2, [x1, x0]
ffff000000080ca8:	b9445be0 	ldr	w0, [sp, #1112]
ffff000000080cac:	51000400 	sub	w0, w0, #0x1
ffff000000080cb0:	b9045be0 	str	w0, [sp, #1112]
ffff000000080cb4:	b9445be0 	ldr	w0, [sp, #1112]
ffff000000080cb8:	11000400 	add	w0, w0, #0x1
ffff000000080cbc:	b9045be0 	str	w0, [sp, #1112]
ffff000000080cc0:	b9845be0 	ldrsw	x0, [sp, #1112]
ffff000000080cc4:	f9400fe1 	ldr	x1, [sp, #24]
ffff000000080cc8:	8b000020 	add	x0, x1, x0
ffff000000080ccc:	39400000 	ldrb	w0, [x0]
ffff000000080cd0:	7100001f 	cmp	w0, #0x0
ffff000000080cd4:	54ffe961 	b.ne	ffff000000080a00 <printk+0x64>  // b.any
ffff000000080cd8:	910123e0 	add	x0, sp, #0x48
ffff000000080cdc:	b9445fe1 	ldr	w1, [sp, #1116]
ffff000000080ce0:	97ffff19 	bl	ffff000000080944 <write_console>
ffff000000080ce4:	b9445fe0 	ldr	w0, [sp, #1116]
ffff000000080ce8:	a9407bfd 	ldp	x29, x30, [sp]
ffff000000080cec:	911283ff 	add	sp, sp, #0x4a0
ffff000000080cf0:	d65f03c0 	ret

ffff000000080cf4 <error_check>:
ffff000000080cf4:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff000000080cf8:	910003fd 	mov	x29, sp
ffff000000080cfc:	f9000fe0 	str	x0, [sp, #24]
ffff000000080d00:	f9000be1 	str	x1, [sp, #16]
ffff000000080d04:	90000060 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff000000080d08:	9102e000 	add	x0, x0, #0xb8
ffff000000080d0c:	97ffff24 	bl	ffff00000008099c <printk>
ffff000000080d10:	90000060 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff000000080d14:	91038000 	add	x0, x0, #0xe0
ffff000000080d18:	97ffff21 	bl	ffff00000008099c <printk>
ffff000000080d1c:	90000060 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff000000080d20:	9102e000 	add	x0, x0, #0xb8
ffff000000080d24:	97ffff1e 	bl	ffff00000008099c <printk>
ffff000000080d28:	f9400be2 	ldr	x2, [sp, #16]
ffff000000080d2c:	f9400fe1 	ldr	x1, [sp, #24]
ffff000000080d30:	90000060 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff000000080d34:	91040000 	add	x0, x0, #0x100
ffff000000080d38:	97ffff19 	bl	ffff00000008099c <printk>
ffff000000080d3c:	d503201f 	nop
ffff000000080d40:	17ffffff 	b	ffff000000080d3c <error_check+0x48>
	...

ffff000000081000 <vector_table>:
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
ffff000000081780:	14000055 	b	ffff0000000818d4 <error>

ffff000000081784 <pstart>:
ffff000000081784:	9100001f 	mov	sp, x0

ffff000000081788 <trap_return>:
ffff000000081788:	a95107e0 	ldp	x0, x1, [sp, #272]
ffff00000008178c:	d5184020 	msr	elr_el1, x0
ffff000000081790:	d5184001 	msr	spsr_el1, x1
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
ffff0000000817e0:	9100001f 	mov	sp, x0
ffff0000000817e4:	17ffffe9 	b	ffff000000081788 <trap_return>

ffff0000000817e8 <sync_handler>:
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
ffff000000081830:	d5385200 	mrs	x0, esr_el1
ffff000000081834:	d35afc01 	lsr	x1, x0, #26
ffff000000081838:	f100543f 	cmp	x1, #0x15
ffff00000008183c:	d2800022 	mov	x2, #0x1                   	// #1
ffff000000081840:	d2800063 	mov	x3, #0x3                   	// #3
ffff000000081844:	9a831040 	csel	x0, x2, x3, ne	// ne = any
ffff000000081848:	d5385201 	mrs	x1, esr_el1
ffff00000008184c:	a91007e0 	stp	x0, x1, [sp, #256]
ffff000000081850:	d5384020 	mrs	x0, elr_el1
ffff000000081854:	d5384001 	mrs	x1, spsr_el1
ffff000000081858:	a91107e0 	stp	x0, x1, [sp, #272]
ffff00000008185c:	910003e0 	mov	x0, sp
ffff000000081860:	940000f5 	bl	ffff000000081c34 <handler>
ffff000000081864:	17ffffc9 	b	ffff000000081788 <trap_return>

ffff000000081868 <irq_handler>:
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
ffff0000000818b0:	d2800040 	mov	x0, #0x2                   	// #2
ffff0000000818b4:	d5385201 	mrs	x1, esr_el1
ffff0000000818b8:	a91007e0 	stp	x0, x1, [sp, #256]
ffff0000000818bc:	d5384020 	mrs	x0, elr_el1
ffff0000000818c0:	d5384001 	mrs	x1, spsr_el1
ffff0000000818c4:	a91107e0 	stp	x0, x1, [sp, #272]
ffff0000000818c8:	910003e0 	mov	x0, sp
ffff0000000818cc:	940000da 	bl	ffff000000081c34 <handler>
ffff0000000818d0:	17ffffae 	b	ffff000000081788 <trap_return>

ffff0000000818d4 <error>:
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
ffff00000008191c:	d2800000 	mov	x0, #0x0                   	// #0
ffff000000081920:	d5385201 	mrs	x1, esr_el1
ffff000000081924:	a91007e0 	stp	x0, x1, [sp, #256]
ffff000000081928:	d5384020 	mrs	x0, elr_el1
ffff00000008192c:	d5384001 	mrs	x1, spsr_el1
ffff000000081930:	a91107e0 	stp	x0, x1, [sp, #272]
ffff000000081934:	910003e0 	mov	x0, sp
ffff000000081938:	940000bf 	bl	ffff000000081c34 <handler>
ffff00000008193c:	17ffff93 	b	ffff000000081788 <trap_return>

ffff000000081940 <read_timer_freq>:
ffff000000081940:	d53be000 	mrs	x0, cntfrq_el0
ffff000000081944:	d65f03c0 	ret

ffff000000081948 <set_timer_interval>:
ffff000000081948:	d51be200 	msr	cntp_tval_el0, x0
ffff00000008194c:	d65f03c0 	ret

ffff000000081950 <enable_timer>:
ffff000000081950:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffff000000081954:	97fffffb 	bl	ffff000000081940 <read_timer_freq>
ffff000000081958:	d2800c81 	mov	x1, #0x64                  	// #100
ffff00000008195c:	9ac10800 	udiv	x0, x0, x1
ffff000000081960:	97fffffa 	bl	ffff000000081948 <set_timer_interval>
ffff000000081964:	d2800020 	mov	x0, #0x1                   	// #1
ffff000000081968:	d51be220 	msr	cntp_ctl_el0, x0
ffff00000008196c:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffff000000081970:	d65f03c0 	ret

ffff000000081974 <read_timer_status>:
ffff000000081974:	d53be220 	mrs	x0, cntp_ctl_el0
ffff000000081978:	d65f03c0 	ret

ffff00000008197c <enable_irq>:
ffff00000008197c:	d50342ff 	msr	daifclr, #0x2
ffff000000081980:	d65f03c0 	ret

ffff000000081984 <swap>:
ffff000000081984:	d10183ff 	sub	sp, sp, #0x60
ffff000000081988:	a90053f3 	stp	x19, x20, [sp]
ffff00000008198c:	a9015bf5 	stp	x21, x22, [sp, #16]
ffff000000081990:	a90263f7 	stp	x23, x24, [sp, #32]
ffff000000081994:	a9036bf9 	stp	x25, x26, [sp, #48]
ffff000000081998:	a90473fb 	stp	x27, x28, [sp, #64]
ffff00000008199c:	a9057bfd 	stp	x29, x30, [sp, #80]
ffff0000000819a0:	910003e2 	mov	x2, sp
ffff0000000819a4:	f9000002 	str	x2, [x0]
ffff0000000819a8:	9100003f 	mov	sp, x1
ffff0000000819ac:	a94053f3 	ldp	x19, x20, [sp]
ffff0000000819b0:	a9415bf5 	ldp	x21, x22, [sp, #16]
ffff0000000819b4:	a94263f7 	ldp	x23, x24, [sp, #32]
ffff0000000819b8:	a9436bf9 	ldp	x25, x26, [sp, #48]
ffff0000000819bc:	a94473fb 	ldp	x27, x28, [sp, #64]
ffff0000000819c0:	a9457bfd 	ldp	x29, x30, [sp, #80]
ffff0000000819c4:	910183ff 	add	sp, sp, #0x60
ffff0000000819c8:	d65f03c0 	ret

ffff0000000819cc <swap_new>:
ffff0000000819cc:	a90053f3 	stp	x19, x20, [sp]
ffff0000000819d0:	a9015bf5 	stp	x21, x22, [sp, #16]
ffff0000000819d4:	a90263f7 	stp	x23, x24, [sp, #32]
ffff0000000819d8:	a9036bf9 	stp	x25, x26, [sp, #48]
ffff0000000819dc:	a90473fb 	stp	x27, x28, [sp, #64]
ffff0000000819e0:	a9057bfd 	stp	x29, x30, [sp, #80]
ffff0000000819e4:	910003e2 	mov	x2, sp
ffff0000000819e8:	f9000002 	str	x2, [x0]
ffff0000000819ec:	9100003f 	mov	sp, x1
ffff0000000819f0:	a94053f3 	ldp	x19, x20, [sp]
ffff0000000819f4:	a9415bf5 	ldp	x21, x22, [sp, #16]
ffff0000000819f8:	a94263f7 	ldp	x23, x24, [sp, #32]
ffff0000000819fc:	a9436bf9 	ldp	x25, x26, [sp, #48]
ffff000000081a00:	a94473fb 	ldp	x27, x28, [sp, #64]
ffff000000081a04:	a9457bfd 	ldp	x29, x30, [sp, #80]
ffff000000081a08:	d65f03c0 	ret

ffff000000081a0c <get_ticks>:
ffff000000081a0c:	90000060 	adrp	x0, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff000000081a10:	910b2000 	add	x0, x0, #0x2c8
ffff000000081a14:	f9400000 	ldr	x0, [x0]
ffff000000081a18:	d65f03c0 	ret

ffff000000081a1c <init_interrupt_controller>:
ffff000000081a1c:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffff000000081a20:	910003fd 	mov	x29, sp
ffff000000081a24:	12800001 	mov	w1, #0xffffffff            	// #-1
ffff000000081a28:	d2964480 	mov	x0, #0xb224                	// #45604
ffff000000081a2c:	f2a7e000 	movk	x0, #0x3f00, lsl #16
ffff000000081a30:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000081a34:	97fff9d4 	bl	ffff000000080184 <out_word>
ffff000000081a38:	12800001 	mov	w1, #0xffffffff            	// #-1
ffff000000081a3c:	d2964380 	mov	x0, #0xb21c                	// #45596
ffff000000081a40:	f2a7e000 	movk	x0, #0x3f00, lsl #16
ffff000000081a44:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000081a48:	97fff9cf 	bl	ffff000000080184 <out_word>
ffff000000081a4c:	12800001 	mov	w1, #0xffffffff            	// #-1
ffff000000081a50:	d2964400 	mov	x0, #0xb220                	// #45600
ffff000000081a54:	f2a7e000 	movk	x0, #0x3f00, lsl #16
ffff000000081a58:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000081a5c:	97fff9ca 	bl	ffff000000080184 <out_word>
ffff000000081a60:	52a04001 	mov	w1, #0x2000000             	// #33554432
ffff000000081a64:	d2964280 	mov	x0, #0xb214                	// #45588
ffff000000081a68:	f2a7e000 	movk	x0, #0x3f00, lsl #16
ffff000000081a6c:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000081a70:	97fff9c5 	bl	ffff000000080184 <out_word>
ffff000000081a74:	d503201f 	nop
ffff000000081a78:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffff000000081a7c:	d65f03c0 	ret

ffff000000081a80 <init_timer>:
ffff000000081a80:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffff000000081a84:	910003fd 	mov	x29, sp
ffff000000081a88:	97ffffae 	bl	ffff000000081940 <read_timer_freq>
ffff000000081a8c:	2a0003e1 	mov	w1, w0
ffff000000081a90:	5290a3e0 	mov	w0, #0x851f                	// #34079
ffff000000081a94:	72aa3d60 	movk	w0, #0x51eb, lsl #16
ffff000000081a98:	9ba07c20 	umull	x0, w1, w0
ffff000000081a9c:	d360fc00 	lsr	x0, x0, #32
ffff000000081aa0:	53057c01 	lsr	w1, w0, #5
ffff000000081aa4:	90000060 	adrp	x0, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff000000081aa8:	910b0000 	add	x0, x0, #0x2c0
ffff000000081aac:	b9000001 	str	w1, [x0]
ffff000000081ab0:	97ffffa8 	bl	ffff000000081950 <enable_timer>
ffff000000081ab4:	52800041 	mov	w1, #0x2                   	// #2
ffff000000081ab8:	d2800800 	mov	x0, #0x40                  	// #64
ffff000000081abc:	f2a80000 	movk	x0, #0x4000, lsl #16
ffff000000081ac0:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000081ac4:	97fff9b0 	bl	ffff000000080184 <out_word>
ffff000000081ac8:	d503201f 	nop
ffff000000081acc:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffff000000081ad0:	d65f03c0 	ret

ffff000000081ad4 <check_sleep_list>:
ffff000000081ad4:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff000000081ad8:	910003fd 	mov	x29, sp
ffff000000081adc:	94002586 	bl	ffff00000008b0f4 <get_pc>
ffff000000081ae0:	f90017e0 	str	x0, [sp, #40]
ffff000000081ae4:	f94017e0 	ldr	x0, [sp, #40]
ffff000000081ae8:	f9400c00 	ldr	x0, [x0, #24]
ffff000000081aec:	f9001fe0 	str	x0, [sp, #56]
ffff000000081af0:	f94017e0 	ldr	x0, [sp, #40]
ffff000000081af4:	91006000 	add	x0, x0, #0x18
ffff000000081af8:	f9001be0 	str	x0, [sp, #48]
ffff000000081afc:	14000027 	b	ffff000000081b98 <check_sleep_list+0xc4>
ffff000000081b00:	f9401fe0 	ldr	x0, [sp, #56]
ffff000000081b04:	f90013e0 	str	x0, [sp, #32]
ffff000000081b08:	f94013e0 	ldr	x0, [sp, #32]
ffff000000081b0c:	b9401000 	ldr	w0, [x0, #16]
ffff000000081b10:	51000401 	sub	w1, w0, #0x1
ffff000000081b14:	f94013e0 	ldr	x0, [sp, #32]
ffff000000081b18:	b9001001 	str	w1, [x0, #16]
ffff000000081b1c:	f94013e0 	ldr	x0, [sp, #32]
ffff000000081b20:	b9401000 	ldr	w0, [x0, #16]
ffff000000081b24:	7100001f 	cmp	w0, #0x0
ffff000000081b28:	540002ec 	b.gt	ffff000000081b84 <check_sleep_list+0xb0>
ffff000000081b2c:	f9401fe0 	ldr	x0, [sp, #56]
ffff000000081b30:	f9400000 	ldr	x0, [x0]
ffff000000081b34:	f9000fe0 	str	x0, [sp, #24]
ffff000000081b38:	f9401be0 	ldr	x0, [sp, #48]
ffff000000081b3c:	f9400fe1 	ldr	x1, [sp, #24]
ffff000000081b40:	f9000001 	str	x1, [x0]
ffff000000081b44:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000081b48:	f100001f 	cmp	x0, #0x0
ffff000000081b4c:	54000081 	b.ne	ffff000000081b5c <check_sleep_list+0x88>  // b.any
ffff000000081b50:	f94017e0 	ldr	x0, [sp, #40]
ffff000000081b54:	f9401be1 	ldr	x1, [sp, #48]
ffff000000081b58:	f9001001 	str	x1, [x0, #32]
ffff000000081b5c:	f94013e0 	ldr	x0, [sp, #32]
ffff000000081b60:	52800061 	mov	w1, #0x3                   	// #3
ffff000000081b64:	b9000c01 	str	w1, [x0, #12]
ffff000000081b68:	f94017e0 	ldr	x0, [sp, #40]
ffff000000081b6c:	91002000 	add	x0, x0, #0x8
ffff000000081b70:	f9401fe1 	ldr	x1, [sp, #56]
ffff000000081b74:	97fff9ac 	bl	ffff000000080224 <append_list_tail>
ffff000000081b78:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000081b7c:	f9001fe0 	str	x0, [sp, #56]
ffff000000081b80:	14000006 	b	ffff000000081b98 <check_sleep_list+0xc4>
ffff000000081b84:	f9401fe0 	ldr	x0, [sp, #56]
ffff000000081b88:	f9001be0 	str	x0, [sp, #48]
ffff000000081b8c:	f9401fe0 	ldr	x0, [sp, #56]
ffff000000081b90:	f9400000 	ldr	x0, [x0]
ffff000000081b94:	f9001fe0 	str	x0, [sp, #56]
ffff000000081b98:	f9401fe0 	ldr	x0, [sp, #56]
ffff000000081b9c:	f100001f 	cmp	x0, #0x0
ffff000000081ba0:	54fffb01 	b.ne	ffff000000081b00 <check_sleep_list+0x2c>  // b.any
ffff000000081ba4:	d503201f 	nop
ffff000000081ba8:	d503201f 	nop
ffff000000081bac:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff000000081bb0:	d65f03c0 	ret

ffff000000081bb4 <timer_interrupt_handler>:
ffff000000081bb4:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff000000081bb8:	910003fd 	mov	x29, sp
ffff000000081bbc:	97ffff6e 	bl	ffff000000081974 <read_timer_status>
ffff000000081bc0:	b9001fe0 	str	w0, [sp, #28]
ffff000000081bc4:	b9401fe0 	ldr	w0, [sp, #28]
ffff000000081bc8:	121e0000 	and	w0, w0, #0x4
ffff000000081bcc:	7100001f 	cmp	w0, #0x0
ffff000000081bd0:	540001c0 	b.eq	ffff000000081c08 <timer_interrupt_handler+0x54>  // b.none
ffff000000081bd4:	90000060 	adrp	x0, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff000000081bd8:	910b2000 	add	x0, x0, #0x2c8
ffff000000081bdc:	f9400000 	ldr	x0, [x0]
ffff000000081be0:	91000401 	add	x1, x0, #0x1
ffff000000081be4:	90000060 	adrp	x0, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff000000081be8:	910b2000 	add	x0, x0, #0x2c8
ffff000000081bec:	f9000001 	str	x1, [x0]
ffff000000081bf0:	12800000 	mov	w0, #0xffffffff            	// #-1
ffff000000081bf4:	9400283f 	bl	ffff00000008bcf0 <wake_up>
ffff000000081bf8:	90000060 	adrp	x0, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff000000081bfc:	910b0000 	add	x0, x0, #0x2c0
ffff000000081c00:	b9400000 	ldr	w0, [x0]
ffff000000081c04:	97ffff51 	bl	ffff000000081948 <set_timer_interval>
ffff000000081c08:	d503201f 	nop
ffff000000081c0c:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff000000081c10:	d65f03c0 	ret

ffff000000081c14 <get_irq_number>:
ffff000000081c14:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffff000000081c18:	910003fd 	mov	x29, sp
ffff000000081c1c:	d2964000 	mov	x0, #0xb200                	// #45568
ffff000000081c20:	f2a7e000 	movk	x0, #0x3f00, lsl #16
ffff000000081c24:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000081c28:	97fff959 	bl	ffff00000008018c <in_word>
ffff000000081c2c:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffff000000081c30:	d65f03c0 	ret

ffff000000081c34 <handler>:
ffff000000081c34:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff000000081c38:	910003fd 	mov	x29, sp
ffff000000081c3c:	f9000fe0 	str	x0, [sp, #24]
ffff000000081c40:	b9002fff 	str	wzr, [sp, #44]
ffff000000081c44:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000081c48:	f9408000 	ldr	x0, [x0, #256]
ffff000000081c4c:	f1000c1f 	cmp	x0, #0x3
ffff000000081c50:	54000580 	b.eq	ffff000000081d00 <handler+0xcc>  // b.none
ffff000000081c54:	f1000c1f 	cmp	x0, #0x3
ffff000000081c58:	540005ac 	b.gt	ffff000000081d0c <handler+0xd8>
ffff000000081c5c:	f100041f 	cmp	x0, #0x1
ffff000000081c60:	54000080 	b.eq	ffff000000081c70 <handler+0x3c>  // b.none
ffff000000081c64:	f100081f 	cmp	x0, #0x2
ffff000000081c68:	54000180 	b.eq	ffff000000081c98 <handler+0x64>  // b.none
ffff000000081c6c:	14000028 	b	ffff000000081d0c <handler+0xd8>
ffff000000081c70:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000081c74:	f9408801 	ldr	x1, [x0, #272]
ffff000000081c78:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000081c7c:	f9408400 	ldr	x0, [x0, #264]
ffff000000081c80:	aa0003e2 	mov	x2, x0
ffff000000081c84:	f0000040 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff000000081c88:	91048000 	add	x0, x0, #0x120
ffff000000081c8c:	97fffb44 	bl	ffff00000008099c <printk>
ffff000000081c90:	d503201f 	nop
ffff000000081c94:	17ffffff 	b	ffff000000081c90 <handler+0x5c>
ffff000000081c98:	d2800c00 	mov	x0, #0x60                  	// #96
ffff000000081c9c:	f2a80000 	movk	x0, #0x4000, lsl #16
ffff000000081ca0:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff000000081ca4:	97fff93a 	bl	ffff00000008018c <in_word>
ffff000000081ca8:	b9002be0 	str	w0, [sp, #40]
ffff000000081cac:	b9402be0 	ldr	w0, [sp, #40]
ffff000000081cb0:	121f0000 	and	w0, w0, #0x2
ffff000000081cb4:	7100001f 	cmp	w0, #0x0
ffff000000081cb8:	540000a0 	b.eq	ffff000000081ccc <handler+0x98>  // b.none
ffff000000081cbc:	97ffffbe 	bl	ffff000000081bb4 <timer_interrupt_handler>
ffff000000081cc0:	52800020 	mov	w0, #0x1                   	// #1
ffff000000081cc4:	b9002fe0 	str	w0, [sp, #44]
ffff000000081cc8:	14000016 	b	ffff000000081d20 <handler+0xec>
ffff000000081ccc:	97ffffd2 	bl	ffff000000081c14 <get_irq_number>
ffff000000081cd0:	b9002be0 	str	w0, [sp, #40]
ffff000000081cd4:	b9402be0 	ldr	w0, [sp, #40]
ffff000000081cd8:	120d0000 	and	w0, w0, #0x80000
ffff000000081cdc:	7100001f 	cmp	w0, #0x0
ffff000000081ce0:	54000060 	b.eq	ffff000000081cec <handler+0xb8>  // b.none
ffff000000081ce4:	97fff9f6 	bl	ffff0000000804bc <uart_handler>
ffff000000081ce8:	1400000e 	b	ffff000000081d20 <handler+0xec>
ffff000000081cec:	f0000040 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff000000081cf0:	9104e000 	add	x0, x0, #0x138
ffff000000081cf4:	97fffb2a 	bl	ffff00000008099c <printk>
ffff000000081cf8:	d503201f 	nop
ffff000000081cfc:	17ffffff 	b	ffff000000081cf8 <handler+0xc4>
ffff000000081d00:	f9400fe0 	ldr	x0, [sp, #24]
ffff000000081d04:	9400289d 	bl	ffff00000008bf78 <system_call>
ffff000000081d08:	14000006 	b	ffff000000081d20 <handler+0xec>
ffff000000081d0c:	f0000040 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff000000081d10:	91052000 	add	x0, x0, #0x148
ffff000000081d14:	97fffb22 	bl	ffff00000008099c <printk>
ffff000000081d18:	d503201f 	nop
ffff000000081d1c:	17ffffff 	b	ffff000000081d18 <handler+0xe4>
ffff000000081d20:	b9402fe0 	ldr	w0, [sp, #44]
ffff000000081d24:	7100041f 	cmp	w0, #0x1
ffff000000081d28:	54000041 	b.ne	ffff000000081d30 <handler+0xfc>  // b.any
ffff000000081d2c:	940027bc 	bl	ffff00000008bc1c <yield>
ffff000000081d30:	d503201f 	nop
ffff000000081d34:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff000000081d38:	d65f03c0 	ret
	...

ffff000000082000 <read_pgd>:
ffff000000082000:	d5382000 	mrs	x0, ttbr0_el1
ffff000000082004:	d65f03c0 	ret

ffff000000082008 <load_pgd>:
ffff000000082008:	d5182000 	msr	ttbr0_el1, x0
ffff00000008200c:	d508831f 	tlbi	vmalle1is
ffff000000082010:	d5033b9f 	dsb	ish
ffff000000082014:	d5033fdf 	isb
ffff000000082018:	d65f03c0 	ret

ffff00000008201c <enable_mmu>:
ffff00000008201c:	10007f20 	adr	x0, ffff000000083000 <pgd_ttbr1>
ffff000000082020:	d5182020 	msr	ttbr1_el1, x0
ffff000000082024:	10027ee0 	adr	x0, ffff000000087000 <pgd_ttbr0>
ffff000000082028:	d5182000 	msr	ttbr0_el1, x0
ffff00000008202c:	5803fea0 	ldr	x0, ffff00000008a000 <pmd_ttbr0+0x1000>
ffff000000082030:	d518a200 	msr	mair_el1, x0
ffff000000082034:	5803fea0 	ldr	x0, ffff00000008a008 <pmd_ttbr0+0x1008>
ffff000000082038:	d5182040 	msr	tcr_el1, x0
ffff00000008203c:	d5381000 	mrs	x0, sctlr_el1
ffff000000082040:	b2400000 	orr	x0, x0, #0x1
ffff000000082044:	d5181000 	msr	sctlr_el1, x0
ffff000000082048:	d5033b9f 	dsb	ish
ffff00000008204c:	d5033fdf 	isb
ffff000000082050:	d65f03c0 	ret

ffff000000082054 <setup_vm>:
ffff000000082054:	10007d60 	adr	x0, ffff000000083000 <pgd_ttbr1>
ffff000000082058:	1000fd41 	adr	x1, ffff000000084000 <pud_ttbr1>
ffff00000008205c:	b2400421 	orr	x1, x1, #0x3
ffff000000082060:	f9000001 	str	x1, [x0]
ffff000000082064:	1000fce0 	adr	x0, ffff000000084000 <pud_ttbr1>
ffff000000082068:	10017cc1 	adr	x1, ffff000000085000 <pmd_ttbr1>
ffff00000008206c:	b2400421 	orr	x1, x1, #0x3
ffff000000082070:	f9000001 	str	x1, [x0]
ffff000000082074:	d2a68002 	mov	x2, #0x34000000            	// #872415232
ffff000000082078:	10017c41 	adr	x1, ffff000000085000 <pmd_ttbr1>
ffff00000008207c:	d28080a0 	mov	x0, #0x405                 	// #1029

ffff000000082080 <loop1>:
ffff000000082080:	f8008420 	str	x0, [x1], #8
ffff000000082084:	91480000 	add	x0, x0, #0x200, lsl #12
ffff000000082088:	eb02001f 	cmp	x0, x2
ffff00000008208c:	54ffffa3 	b.cc	ffff000000082080 <loop1>  // b.lo, b.ul, b.last
ffff000000082090:	d2a80002 	mov	x2, #0x40000000            	// #1073741824
ffff000000082094:	d2a7e000 	mov	x0, #0x3f000000            	// #1056964608
ffff000000082098:	10017b43 	adr	x3, ffff000000085000 <pmd_ttbr1>
ffff00000008209c:	d352fc01 	lsr	x1, x0, #18
ffff0000000820a0:	8b030021 	add	x1, x1, x3
ffff0000000820a4:	b2400000 	orr	x0, x0, #0x1
ffff0000000820a8:	b2760000 	orr	x0, x0, #0x400

ffff0000000820ac <loop2>:
ffff0000000820ac:	f8008420 	str	x0, [x1], #8
ffff0000000820b0:	91480000 	add	x0, x0, #0x200, lsl #12
ffff0000000820b4:	eb02001f 	cmp	x0, x2
ffff0000000820b8:	54ffffa3 	b.cc	ffff0000000820ac <loop2>  // b.lo, b.ul, b.last
ffff0000000820bc:	1000fa20 	adr	x0, ffff000000084000 <pud_ttbr1>
ffff0000000820c0:	91002000 	add	x0, x0, #0x8
ffff0000000820c4:	1001f9e1 	adr	x1, ffff000000086000 <pmd2_ttbr1>
ffff0000000820c8:	b2400421 	orr	x1, x1, #0x3
ffff0000000820cc:	f9000001 	str	x1, [x0]
ffff0000000820d0:	d2a82002 	mov	x2, #0x41000000            	// #1090519040
ffff0000000820d4:	d2a80000 	mov	x0, #0x40000000            	// #1073741824
ffff0000000820d8:	1001f941 	adr	x1, ffff000000086000 <pmd2_ttbr1>
ffff0000000820dc:	b2400000 	orr	x0, x0, #0x1
ffff0000000820e0:	b2760000 	orr	x0, x0, #0x400

ffff0000000820e4 <loop3>:
ffff0000000820e4:	f8008420 	str	x0, [x1], #8
ffff0000000820e8:	91480000 	add	x0, x0, #0x200, lsl #12
ffff0000000820ec:	eb02001f 	cmp	x0, x2
ffff0000000820f0:	54ffffa3 	b.cc	ffff0000000820e4 <loop3>  // b.lo, b.ul, b.last

ffff0000000820f4 <setup_uvm>:
ffff0000000820f4:	10027860 	adr	x0, ffff000000087000 <pgd_ttbr0>
ffff0000000820f8:	1002f841 	adr	x1, ffff000000088000 <pud_ttbr0>
ffff0000000820fc:	b2400421 	orr	x1, x1, #0x3
ffff000000082100:	f9000001 	str	x1, [x0]
ffff000000082104:	1002f7e0 	adr	x0, ffff000000088000 <pud_ttbr0>
ffff000000082108:	100377c1 	adr	x1, ffff000000089000 <pmd_ttbr0>
ffff00000008210c:	b2400421 	orr	x1, x1, #0x3
ffff000000082110:	f9000001 	str	x1, [x0]
ffff000000082114:	10037761 	adr	x1, ffff000000089000 <pmd_ttbr0>
ffff000000082118:	d28080a0 	mov	x0, #0x405                 	// #1029
ffff00000008211c:	f9000020 	str	x0, [x1]
ffff000000082120:	d65f03c0 	ret
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
ffff00000008a000:	00004400 	udf	#17408
ffff00000008a004:	00000000 	udf	#0
ffff00000008a008:	80100010 	fmop4s	za0.s, z0.s, {z16.s-z17.s}
ffff00000008a00c:	00000000 	udf	#0

ffff00000008a010 <free_region>:
ffff00000008a010:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008a014:	910003fd 	mov	x29, sp
ffff00000008a018:	f9000fe0 	str	x0, [sp, #24]
ffff00000008a01c:	f9000be1 	str	x1, [sp, #16]
ffff00000008a020:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008a024:	b24053e0 	mov	x0, #0x1fffff              	// #2097151
ffff00000008a028:	8b000020 	add	x0, x1, x0
ffff00000008a02c:	926ba800 	and	x0, x0, #0xffffffffffe00000
ffff00000008a030:	f90017e0 	str	x0, [sp, #40]
ffff00000008a034:	1400000c 	b	ffff00000008a064 <free_region+0x54>
ffff00000008a038:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008a03c:	91480001 	add	x1, x0, #0x200, lsl #12
ffff00000008a040:	d2a60000 	mov	x0, #0x30000000            	// #805306368
ffff00000008a044:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff00000008a048:	eb00003f 	cmp	x1, x0
ffff00000008a04c:	54000068 	b.hi	ffff00000008a058 <free_region+0x48>  // b.pmore
ffff00000008a050:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008a054:	9400000d 	bl	ffff00000008a088 <kfree>
ffff00000008a058:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008a05c:	91480000 	add	x0, x0, #0x200, lsl #12
ffff00000008a060:	f90017e0 	str	x0, [sp, #40]
ffff00000008a064:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008a068:	91480000 	add	x0, x0, #0x200, lsl #12
ffff00000008a06c:	f9400be1 	ldr	x1, [sp, #16]
ffff00000008a070:	eb00003f 	cmp	x1, x0
ffff00000008a074:	54fffe22 	b.cs	ffff00000008a038 <free_region+0x28>  // b.hs, b.nlast
ffff00000008a078:	d503201f 	nop
ffff00000008a07c:	d503201f 	nop
ffff00000008a080:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff00000008a084:	d65f03c0 	ret

ffff00000008a088 <kfree>:
ffff00000008a088:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008a08c:	910003fd 	mov	x29, sp
ffff00000008a090:	f9000fe0 	str	x0, [sp, #24]
ffff00000008a094:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a098:	92405000 	and	x0, x0, #0x1fffff
ffff00000008a09c:	f100001f 	cmp	x0, #0x0
ffff00000008a0a0:	540000a0 	b.eq	ffff00000008a0b4 <kfree+0x2c>  // b.none
ffff00000008a0a4:	d2800421 	mov	x1, #0x21                  	// #33
ffff00000008a0a8:	d0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008a0ac:	91058000 	add	x0, x0, #0x160
ffff00000008a0b0:	97ffdb11 	bl	ffff000000080cf4 <error_check>
ffff00000008a0b4:	f0000000 	adrp	x0, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff00000008a0b8:	91168000 	add	x0, x0, #0x5a0
ffff00000008a0bc:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008a0c0:	eb00003f 	cmp	x1, x0
ffff00000008a0c4:	540000a2 	b.cs	ffff00000008a0d8 <kfree+0x50>  // b.hs, b.nlast
ffff00000008a0c8:	d2800441 	mov	x1, #0x22                  	// #34
ffff00000008a0cc:	d0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008a0d0:	91058000 	add	x0, x0, #0x160
ffff00000008a0d4:	97ffdb08 	bl	ffff000000080cf4 <error_check>
ffff00000008a0d8:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a0dc:	91480001 	add	x1, x0, #0x200, lsl #12
ffff00000008a0e0:	d2a60000 	mov	x0, #0x30000000            	// #805306368
ffff00000008a0e4:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff00000008a0e8:	eb00003f 	cmp	x1, x0
ffff00000008a0ec:	540000a9 	b.ls	ffff00000008a100 <kfree+0x78>  // b.plast
ffff00000008a0f0:	d2800461 	mov	x1, #0x23                  	// #35
ffff00000008a0f4:	d0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008a0f8:	91058000 	add	x0, x0, #0x160
ffff00000008a0fc:	97ffdafe 	bl	ffff000000080cf4 <error_check>
ffff00000008a100:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a104:	f90017e0 	str	x0, [sp, #40]
ffff00000008a108:	f0000000 	adrp	x0, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff00000008a10c:	910b6000 	add	x0, x0, #0x2d8
ffff00000008a110:	f9400001 	ldr	x1, [x0]
ffff00000008a114:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008a118:	f9000001 	str	x1, [x0]
ffff00000008a11c:	f0000000 	adrp	x0, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff00000008a120:	910b6000 	add	x0, x0, #0x2d8
ffff00000008a124:	f94017e1 	ldr	x1, [sp, #40]
ffff00000008a128:	f9000001 	str	x1, [x0]
ffff00000008a12c:	d503201f 	nop
ffff00000008a130:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff00000008a134:	d65f03c0 	ret

ffff00000008a138 <kalloc>:
ffff00000008a138:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008a13c:	910003fd 	mov	x29, sp
ffff00000008a140:	f0000000 	adrp	x0, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff00000008a144:	910b6000 	add	x0, x0, #0x2d8
ffff00000008a148:	f9400000 	ldr	x0, [x0]
ffff00000008a14c:	f9000fe0 	str	x0, [sp, #24]
ffff00000008a150:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a154:	f100001f 	cmp	x0, #0x0
ffff00000008a158:	54000420 	b.eq	ffff00000008a1dc <kalloc+0xa4>  // b.none
ffff00000008a15c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a160:	92405000 	and	x0, x0, #0x1fffff
ffff00000008a164:	f100001f 	cmp	x0, #0x0
ffff00000008a168:	540000a0 	b.eq	ffff00000008a17c <kalloc+0x44>  // b.none
ffff00000008a16c:	d28005e1 	mov	x1, #0x2f                  	// #47
ffff00000008a170:	d0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008a174:	91058000 	add	x0, x0, #0x160
ffff00000008a178:	97ffdadf 	bl	ffff000000080cf4 <error_check>
ffff00000008a17c:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008a180:	f0000000 	adrp	x0, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff00000008a184:	91168000 	add	x0, x0, #0x5a0
ffff00000008a188:	eb00003f 	cmp	x1, x0
ffff00000008a18c:	540000a2 	b.cs	ffff00000008a1a0 <kalloc+0x68>  // b.hs, b.nlast
ffff00000008a190:	d2800601 	mov	x1, #0x30                  	// #48
ffff00000008a194:	d0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008a198:	91058000 	add	x0, x0, #0x160
ffff00000008a19c:	97ffdad6 	bl	ffff000000080cf4 <error_check>
ffff00000008a1a0:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a1a4:	91480001 	add	x1, x0, #0x200, lsl #12
ffff00000008a1a8:	d2a60000 	mov	x0, #0x30000000            	// #805306368
ffff00000008a1ac:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff00000008a1b0:	eb00003f 	cmp	x1, x0
ffff00000008a1b4:	540000a9 	b.ls	ffff00000008a1c8 <kalloc+0x90>  // b.plast
ffff00000008a1b8:	d2800621 	mov	x1, #0x31                  	// #49
ffff00000008a1bc:	d0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008a1c0:	91058000 	add	x0, x0, #0x160
ffff00000008a1c4:	97ffdacc 	bl	ffff000000080cf4 <error_check>
ffff00000008a1c8:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a1cc:	f9400001 	ldr	x1, [x0]
ffff00000008a1d0:	f0000000 	adrp	x0, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff00000008a1d4:	910b6000 	add	x0, x0, #0x2d8
ffff00000008a1d8:	f9000001 	str	x1, [x0]
ffff00000008a1dc:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a1e0:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008a1e4:	d65f03c0 	ret

ffff00000008a1e8 <checkmm>:
ffff00000008a1e8:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008a1ec:	910003fd 	mov	x29, sp
ffff00000008a1f0:	f0000000 	adrp	x0, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff00000008a1f4:	910b6000 	add	x0, x0, #0x2d8
ffff00000008a1f8:	f9400000 	ldr	x0, [x0]
ffff00000008a1fc:	f90017e0 	str	x0, [sp, #40]
ffff00000008a200:	f90013ff 	str	xzr, [sp, #32]
ffff00000008a204:	f9000fff 	str	xzr, [sp, #24]
ffff00000008a208:	1400000f 	b	ffff00000008a244 <checkmm+0x5c>
ffff00000008a20c:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008a210:	91480000 	add	x0, x0, #0x200, lsl #12
ffff00000008a214:	f90013e0 	str	x0, [sp, #32]
ffff00000008a218:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a21c:	91000401 	add	x1, x0, #0x1
ffff00000008a220:	f9000fe1 	str	x1, [sp, #24]
ffff00000008a224:	f94017e2 	ldr	x2, [sp, #40]
ffff00000008a228:	aa0003e1 	mov	x1, x0
ffff00000008a22c:	d0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008a230:	9105c000 	add	x0, x0, #0x170
ffff00000008a234:	97ffd9da 	bl	ffff00000008099c <printk>
ffff00000008a238:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008a23c:	f9400000 	ldr	x0, [x0]
ffff00000008a240:	f90017e0 	str	x0, [sp, #40]
ffff00000008a244:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008a248:	f100001f 	cmp	x0, #0x0
ffff00000008a24c:	54fffe01 	b.ne	ffff00000008a20c <checkmm+0x24>  // b.any
ffff00000008a250:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008a254:	d354fc00 	lsr	x0, x0, #20
ffff00000008a258:	aa0003e1 	mov	x1, x0
ffff00000008a25c:	d0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008a260:	91062000 	add	x0, x0, #0x188
ffff00000008a264:	97ffd9ce 	bl	ffff00000008099c <printk>
ffff00000008a268:	d503201f 	nop
ffff00000008a26c:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff00000008a270:	d65f03c0 	ret

ffff00000008a274 <find_pgd_entry>:
ffff00000008a274:	a9bb7bfd 	stp	x29, x30, [sp, #-80]!
ffff00000008a278:	910003fd 	mov	x29, sp
ffff00000008a27c:	f90017e0 	str	x0, [sp, #40]
ffff00000008a280:	f90013e1 	str	x1, [sp, #32]
ffff00000008a284:	b9001fe2 	str	w2, [sp, #28]
ffff00000008a288:	f9000be3 	str	x3, [sp, #16]
ffff00000008a28c:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008a290:	f90023e0 	str	x0, [sp, #64]
ffff00000008a294:	f90027ff 	str	xzr, [sp, #72]
ffff00000008a298:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008a29c:	d367fc00 	lsr	x0, x0, #39
ffff00000008a2a0:	12002000 	and	w0, w0, #0x1ff
ffff00000008a2a4:	b9003fe0 	str	w0, [sp, #60]
ffff00000008a2a8:	b9403fe0 	ldr	w0, [sp, #60]
ffff00000008a2ac:	d37df000 	lsl	x0, x0, #3
ffff00000008a2b0:	f94023e1 	ldr	x1, [sp, #64]
ffff00000008a2b4:	8b000020 	add	x0, x1, x0
ffff00000008a2b8:	f9400000 	ldr	x0, [x0]
ffff00000008a2bc:	92400000 	and	x0, x0, #0x1
ffff00000008a2c0:	f100001f 	cmp	x0, #0x0
ffff00000008a2c4:	54000160 	b.eq	ffff00000008a2f0 <find_pgd_entry+0x7c>  // b.none
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
ffff00000008a2f0:	b9401fe0 	ldr	w0, [sp, #28]
ffff00000008a2f4:	7100041f 	cmp	w0, #0x1
ffff00000008a2f8:	540002a1 	b.ne	ffff00000008a34c <find_pgd_entry+0xd8>  // b.any
ffff00000008a2fc:	97ffff8f 	bl	ffff00000008a138 <kalloc>
ffff00000008a300:	f90027e0 	str	x0, [sp, #72]
ffff00000008a304:	f94027e0 	ldr	x0, [sp, #72]
ffff00000008a308:	f100001f 	cmp	x0, #0x0
ffff00000008a30c:	54000200 	b.eq	ffff00000008a34c <find_pgd_entry+0xd8>  // b.none
ffff00000008a310:	52a00402 	mov	w2, #0x200000              	// #2097152
ffff00000008a314:	52800001 	mov	w1, #0x0                   	// #0
ffff00000008a318:	f94027e0 	ldr	x0, [sp, #72]
ffff00000008a31c:	97ffd79e 	bl	ffff000000080194 <memset>
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
ffff00000008a34c:	f94027e0 	ldr	x0, [sp, #72]
ffff00000008a350:	a8c57bfd 	ldp	x29, x30, [sp], #80
ffff00000008a354:	d65f03c0 	ret

ffff00000008a358 <find_pud_entry>:
ffff00000008a358:	a9bb7bfd 	stp	x29, x30, [sp, #-80]!
ffff00000008a35c:	910003fd 	mov	x29, sp
ffff00000008a360:	f90017e0 	str	x0, [sp, #40]
ffff00000008a364:	f90013e1 	str	x1, [sp, #32]
ffff00000008a368:	b9001fe2 	str	w2, [sp, #28]
ffff00000008a36c:	f9000be3 	str	x3, [sp, #16]
ffff00000008a370:	f90023ff 	str	xzr, [sp, #64]
ffff00000008a374:	f90027ff 	str	xzr, [sp, #72]
ffff00000008a378:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008a37c:	d35efc00 	lsr	x0, x0, #30
ffff00000008a380:	12002000 	and	w0, w0, #0x1ff
ffff00000008a384:	b9003fe0 	str	w0, [sp, #60]
ffff00000008a388:	f9400be3 	ldr	x3, [sp, #16]
ffff00000008a38c:	b9401fe2 	ldr	w2, [sp, #28]
ffff00000008a390:	f94013e1 	ldr	x1, [sp, #32]
ffff00000008a394:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008a398:	97ffffb7 	bl	ffff00000008a274 <find_pgd_entry>
ffff00000008a39c:	f90023e0 	str	x0, [sp, #64]
ffff00000008a3a0:	f94023e0 	ldr	x0, [sp, #64]
ffff00000008a3a4:	f100001f 	cmp	x0, #0x0
ffff00000008a3a8:	54000061 	b.ne	ffff00000008a3b4 <find_pud_entry+0x5c>  // b.any
ffff00000008a3ac:	d2800000 	mov	x0, #0x0                   	// #0
ffff00000008a3b0:	1400002b 	b	ffff00000008a45c <find_pud_entry+0x104>
ffff00000008a3b4:	b9403fe0 	ldr	w0, [sp, #60]
ffff00000008a3b8:	d37df000 	lsl	x0, x0, #3
ffff00000008a3bc:	f94023e1 	ldr	x1, [sp, #64]
ffff00000008a3c0:	8b000020 	add	x0, x1, x0
ffff00000008a3c4:	f9400000 	ldr	x0, [x0]
ffff00000008a3c8:	92400000 	and	x0, x0, #0x1
ffff00000008a3cc:	f100001f 	cmp	x0, #0x0
ffff00000008a3d0:	54000160 	b.eq	ffff00000008a3fc <find_pud_entry+0xa4>  // b.none
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
ffff00000008a3fc:	b9401fe0 	ldr	w0, [sp, #28]
ffff00000008a400:	7100041f 	cmp	w0, #0x1
ffff00000008a404:	540002a1 	b.ne	ffff00000008a458 <find_pud_entry+0x100>  // b.any
ffff00000008a408:	97ffff4c 	bl	ffff00000008a138 <kalloc>
ffff00000008a40c:	f90027e0 	str	x0, [sp, #72]
ffff00000008a410:	f94027e0 	ldr	x0, [sp, #72]
ffff00000008a414:	f100001f 	cmp	x0, #0x0
ffff00000008a418:	54000200 	b.eq	ffff00000008a458 <find_pud_entry+0x100>  // b.none
ffff00000008a41c:	52a00402 	mov	w2, #0x200000              	// #2097152
ffff00000008a420:	52800001 	mov	w1, #0x0                   	// #0
ffff00000008a424:	f94027e0 	ldr	x0, [sp, #72]
ffff00000008a428:	97ffd75b 	bl	ffff000000080194 <memset>
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
ffff00000008a458:	f94027e0 	ldr	x0, [sp, #72]
ffff00000008a45c:	a8c57bfd 	ldp	x29, x30, [sp], #80
ffff00000008a460:	d65f03c0 	ret

ffff00000008a464 <map_page>:
ffff00000008a464:	a9bb7bfd 	stp	x29, x30, [sp, #-80]!
ffff00000008a468:	910003fd 	mov	x29, sp
ffff00000008a46c:	f90017e0 	str	x0, [sp, #40]
ffff00000008a470:	f90013e1 	str	x1, [sp, #32]
ffff00000008a474:	f9000fe2 	str	x2, [sp, #24]
ffff00000008a478:	f9000be3 	str	x3, [sp, #16]
ffff00000008a47c:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008a480:	926ba800 	and	x0, x0, #0xffffffffffe00000
ffff00000008a484:	f90027e0 	str	x0, [sp, #72]
ffff00000008a488:	f90023ff 	str	xzr, [sp, #64]
ffff00000008a48c:	f94027e0 	ldr	x0, [sp, #72]
ffff00000008a490:	91480001 	add	x1, x0, #0x200, lsl #12
ffff00000008a494:	92ba0000 	mov	x0, #0xffffffff2fffffff    	// #-3489660929
ffff00000008a498:	f2c00000 	movk	x0, #0x0, lsl #32
ffff00000008a49c:	eb00003f 	cmp	x1, x0
ffff00000008a4a0:	540000a9 	b.ls	ffff00000008a4b4 <map_page+0x50>  // b.plast
ffff00000008a4a4:	d2800f41 	mov	x1, #0x7a                  	// #122
ffff00000008a4a8:	d0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008a4ac:	91058000 	add	x0, x0, #0x160
ffff00000008a4b0:	97ffda11 	bl	ffff000000080cf4 <error_check>
ffff00000008a4b4:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a4b8:	92405000 	and	x0, x0, #0x1fffff
ffff00000008a4bc:	f100001f 	cmp	x0, #0x0
ffff00000008a4c0:	540000a0 	b.eq	ffff00000008a4d4 <map_page+0x70>  // b.none
ffff00000008a4c4:	d2800f61 	mov	x1, #0x7b                  	// #123
ffff00000008a4c8:	d0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008a4cc:	91058000 	add	x0, x0, #0x160
ffff00000008a4d0:	97ffda09 	bl	ffff000000080cf4 <error_check>
ffff00000008a4d4:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a4d8:	91480001 	add	x1, x0, #0x200, lsl #12
ffff00000008a4dc:	d2a60000 	mov	x0, #0x30000000            	// #805306368
ffff00000008a4e0:	eb00003f 	cmp	x1, x0
ffff00000008a4e4:	540000a9 	b.ls	ffff00000008a4f8 <map_page+0x94>  // b.plast
ffff00000008a4e8:	d2800f81 	mov	x1, #0x7c                  	// #124
ffff00000008a4ec:	d0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008a4f0:	91058000 	add	x0, x0, #0x160
ffff00000008a4f4:	97ffda00 	bl	ffff000000080cf4 <error_check>
ffff00000008a4f8:	f9400be3 	ldr	x3, [sp, #16]
ffff00000008a4fc:	52800022 	mov	w2, #0x1                   	// #1
ffff00000008a500:	f94027e1 	ldr	x1, [sp, #72]
ffff00000008a504:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008a508:	97ffff94 	bl	ffff00000008a358 <find_pud_entry>
ffff00000008a50c:	f90023e0 	str	x0, [sp, #64]
ffff00000008a510:	f94023e0 	ldr	x0, [sp, #64]
ffff00000008a514:	f100001f 	cmp	x0, #0x0
ffff00000008a518:	54000061 	b.ne	ffff00000008a524 <map_page+0xc0>  // b.any
ffff00000008a51c:	52800000 	mov	w0, #0x0                   	// #0
ffff00000008a520:	1400001a 	b	ffff00000008a588 <map_page+0x124>
ffff00000008a524:	f94027e0 	ldr	x0, [sp, #72]
ffff00000008a528:	d355fc00 	lsr	x0, x0, #21
ffff00000008a52c:	12002000 	and	w0, w0, #0x1ff
ffff00000008a530:	b9003fe0 	str	w0, [sp, #60]
ffff00000008a534:	b9403fe0 	ldr	w0, [sp, #60]
ffff00000008a538:	d37df000 	lsl	x0, x0, #3
ffff00000008a53c:	f94023e1 	ldr	x1, [sp, #64]
ffff00000008a540:	8b000020 	add	x0, x1, x0
ffff00000008a544:	f9400000 	ldr	x0, [x0]
ffff00000008a548:	92400000 	and	x0, x0, #0x1
ffff00000008a54c:	f100001f 	cmp	x0, #0x0
ffff00000008a550:	540000a0 	b.eq	ffff00000008a564 <map_page+0x100>  // b.none
ffff00000008a554:	d2801081 	mov	x1, #0x84                  	// #132
ffff00000008a558:	d0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008a55c:	91058000 	add	x0, x0, #0x160
ffff00000008a560:	97ffd9e5 	bl	ffff000000080cf4 <error_check>
ffff00000008a564:	b9403fe0 	ldr	w0, [sp, #60]
ffff00000008a568:	d37df000 	lsl	x0, x0, #3
ffff00000008a56c:	f94023e1 	ldr	x1, [sp, #64]
ffff00000008a570:	8b000020 	add	x0, x1, x0
ffff00000008a574:	f9400fe2 	ldr	x2, [sp, #24]
ffff00000008a578:	f9400be1 	ldr	x1, [sp, #16]
ffff00000008a57c:	aa010041 	orr	x1, x2, x1
ffff00000008a580:	f9000001 	str	x1, [x0]
ffff00000008a584:	52800020 	mov	w0, #0x1                   	// #1
ffff00000008a588:	a8c57bfd 	ldp	x29, x30, [sp], #80
ffff00000008a58c:	d65f03c0 	ret

ffff00000008a590 <free_page>:
ffff00000008a590:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008a594:	910003fd 	mov	x29, sp
ffff00000008a598:	f9000fe0 	str	x0, [sp, #24]
ffff00000008a59c:	f9000be1 	str	x1, [sp, #16]
ffff00000008a5a0:	f90017ff 	str	xzr, [sp, #40]
ffff00000008a5a4:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008a5a8:	92405000 	and	x0, x0, #0x1fffff
ffff00000008a5ac:	f100001f 	cmp	x0, #0x0
ffff00000008a5b0:	540000a0 	b.eq	ffff00000008a5c4 <free_page+0x34>  // b.none
ffff00000008a5b4:	d2801201 	mov	x1, #0x90                  	// #144
ffff00000008a5b8:	d0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008a5bc:	91058000 	add	x0, x0, #0x160
ffff00000008a5c0:	97ffd9cd 	bl	ffff000000080cf4 <error_check>
ffff00000008a5c4:	d2800003 	mov	x3, #0x0                   	// #0
ffff00000008a5c8:	52800002 	mov	w2, #0x0                   	// #0
ffff00000008a5cc:	f9400be1 	ldr	x1, [sp, #16]
ffff00000008a5d0:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a5d4:	97ffff61 	bl	ffff00000008a358 <find_pud_entry>
ffff00000008a5d8:	f90017e0 	str	x0, [sp, #40]
ffff00000008a5dc:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008a5e0:	f100001f 	cmp	x0, #0x0
ffff00000008a5e4:	54000360 	b.eq	ffff00000008a650 <free_page+0xc0>  // b.none
ffff00000008a5e8:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008a5ec:	d355fc00 	lsr	x0, x0, #21
ffff00000008a5f0:	12002000 	and	w0, w0, #0x1ff
ffff00000008a5f4:	b90027e0 	str	w0, [sp, #36]
ffff00000008a5f8:	b94027e0 	ldr	w0, [sp, #36]
ffff00000008a5fc:	d37df000 	lsl	x0, x0, #3
ffff00000008a600:	f94017e1 	ldr	x1, [sp, #40]
ffff00000008a604:	8b000020 	add	x0, x1, x0
ffff00000008a608:	f9400000 	ldr	x0, [x0]
ffff00000008a60c:	92400000 	and	x0, x0, #0x1
ffff00000008a610:	f100001f 	cmp	x0, #0x0
ffff00000008a614:	540001e0 	b.eq	ffff00000008a650 <free_page+0xc0>  // b.none
ffff00000008a618:	b94027e0 	ldr	w0, [sp, #36]
ffff00000008a61c:	d37df000 	lsl	x0, x0, #3
ffff00000008a620:	f94017e1 	ldr	x1, [sp, #40]
ffff00000008a624:	8b000020 	add	x0, x1, x0
ffff00000008a628:	f9400000 	ldr	x0, [x0]
ffff00000008a62c:	926b6801 	and	x1, x0, #0xffffffe00000
ffff00000008a630:	d2ffffe0 	mov	x0, #0xffff000000000000    	// #-281474976710656
ffff00000008a634:	8b000020 	add	x0, x1, x0
ffff00000008a638:	97fffe94 	bl	ffff00000008a088 <kfree>
ffff00000008a63c:	b94027e0 	ldr	w0, [sp, #36]
ffff00000008a640:	d37df000 	lsl	x0, x0, #3
ffff00000008a644:	f94017e1 	ldr	x1, [sp, #40]
ffff00000008a648:	8b000020 	add	x0, x1, x0
ffff00000008a64c:	f900001f 	str	xzr, [x0]
ffff00000008a650:	d503201f 	nop
ffff00000008a654:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff00000008a658:	d65f03c0 	ret

ffff00000008a65c <free_pmd>:
ffff00000008a65c:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff00000008a660:	910003fd 	mov	x29, sp
ffff00000008a664:	f9000fe0 	str	x0, [sp, #24]
ffff00000008a668:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a66c:	f9001be0 	str	x0, [sp, #48]
ffff00000008a670:	f90017ff 	str	xzr, [sp, #40]
ffff00000008a674:	b9003fff 	str	wzr, [sp, #60]
ffff00000008a678:	14000033 	b	ffff00000008a744 <free_pmd+0xe8>
ffff00000008a67c:	b9803fe0 	ldrsw	x0, [sp, #60]
ffff00000008a680:	d37df000 	lsl	x0, x0, #3
ffff00000008a684:	f9401be1 	ldr	x1, [sp, #48]
ffff00000008a688:	8b000020 	add	x0, x1, x0
ffff00000008a68c:	f9400000 	ldr	x0, [x0]
ffff00000008a690:	92400000 	and	x0, x0, #0x1
ffff00000008a694:	f100001f 	cmp	x0, #0x0
ffff00000008a698:	54000500 	b.eq	ffff00000008a738 <free_pmd+0xdc>  // b.none
ffff00000008a69c:	b9803fe0 	ldrsw	x0, [sp, #60]
ffff00000008a6a0:	d37df000 	lsl	x0, x0, #3
ffff00000008a6a4:	f9401be1 	ldr	x1, [sp, #48]
ffff00000008a6a8:	8b000020 	add	x0, x1, x0
ffff00000008a6ac:	f9400000 	ldr	x0, [x0]
ffff00000008a6b0:	92748c01 	and	x1, x0, #0xfffffffff000
ffff00000008a6b4:	d2ffffe0 	mov	x0, #0xffff000000000000    	// #-281474976710656
ffff00000008a6b8:	8b000020 	add	x0, x1, x0
ffff00000008a6bc:	f90017e0 	str	x0, [sp, #40]
ffff00000008a6c0:	b9003bff 	str	wzr, [sp, #56]
ffff00000008a6c4:	1400001a 	b	ffff00000008a72c <free_pmd+0xd0>
ffff00000008a6c8:	b9803be0 	ldrsw	x0, [sp, #56]
ffff00000008a6cc:	d37df000 	lsl	x0, x0, #3
ffff00000008a6d0:	f94017e1 	ldr	x1, [sp, #40]
ffff00000008a6d4:	8b000020 	add	x0, x1, x0
ffff00000008a6d8:	f9400000 	ldr	x0, [x0]
ffff00000008a6dc:	92400000 	and	x0, x0, #0x1
ffff00000008a6e0:	f100001f 	cmp	x0, #0x0
ffff00000008a6e4:	540001e0 	b.eq	ffff00000008a720 <free_pmd+0xc4>  // b.none
ffff00000008a6e8:	b9803be0 	ldrsw	x0, [sp, #56]
ffff00000008a6ec:	d37df000 	lsl	x0, x0, #3
ffff00000008a6f0:	f94017e1 	ldr	x1, [sp, #40]
ffff00000008a6f4:	8b000020 	add	x0, x1, x0
ffff00000008a6f8:	f9400000 	ldr	x0, [x0]
ffff00000008a6fc:	92748c01 	and	x1, x0, #0xfffffffff000
ffff00000008a700:	d2ffffe0 	mov	x0, #0xffff000000000000    	// #-281474976710656
ffff00000008a704:	8b000020 	add	x0, x1, x0
ffff00000008a708:	97fffe60 	bl	ffff00000008a088 <kfree>
ffff00000008a70c:	b9803be0 	ldrsw	x0, [sp, #56]
ffff00000008a710:	d37df000 	lsl	x0, x0, #3
ffff00000008a714:	f94017e1 	ldr	x1, [sp, #40]
ffff00000008a718:	8b000020 	add	x0, x1, x0
ffff00000008a71c:	f900001f 	str	xzr, [x0]
ffff00000008a720:	b9403be0 	ldr	w0, [sp, #56]
ffff00000008a724:	11000400 	add	w0, w0, #0x1
ffff00000008a728:	b9003be0 	str	w0, [sp, #56]
ffff00000008a72c:	b9403be0 	ldr	w0, [sp, #56]
ffff00000008a730:	7107fc1f 	cmp	w0, #0x1ff
ffff00000008a734:	54fffcad 	b.le	ffff00000008a6c8 <free_pmd+0x6c>
ffff00000008a738:	b9403fe0 	ldr	w0, [sp, #60]
ffff00000008a73c:	11000400 	add	w0, w0, #0x1
ffff00000008a740:	b9003fe0 	str	w0, [sp, #60]
ffff00000008a744:	b9403fe0 	ldr	w0, [sp, #60]
ffff00000008a748:	7107fc1f 	cmp	w0, #0x1ff
ffff00000008a74c:	54fff98d 	b.le	ffff00000008a67c <free_pmd+0x20>
ffff00000008a750:	d503201f 	nop
ffff00000008a754:	d503201f 	nop
ffff00000008a758:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff00000008a75c:	d65f03c0 	ret

ffff00000008a760 <free_pud>:
ffff00000008a760:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008a764:	910003fd 	mov	x29, sp
ffff00000008a768:	f9000fe0 	str	x0, [sp, #24]
ffff00000008a76c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a770:	f90013e0 	str	x0, [sp, #32]
ffff00000008a774:	b9002fff 	str	wzr, [sp, #44]
ffff00000008a778:	1400001a 	b	ffff00000008a7e0 <free_pud+0x80>
ffff00000008a77c:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff00000008a780:	d37df000 	lsl	x0, x0, #3
ffff00000008a784:	f94013e1 	ldr	x1, [sp, #32]
ffff00000008a788:	8b000020 	add	x0, x1, x0
ffff00000008a78c:	f9400000 	ldr	x0, [x0]
ffff00000008a790:	92400000 	and	x0, x0, #0x1
ffff00000008a794:	f100001f 	cmp	x0, #0x0
ffff00000008a798:	540001e0 	b.eq	ffff00000008a7d4 <free_pud+0x74>  // b.none
ffff00000008a79c:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff00000008a7a0:	d37df000 	lsl	x0, x0, #3
ffff00000008a7a4:	f94013e1 	ldr	x1, [sp, #32]
ffff00000008a7a8:	8b000020 	add	x0, x1, x0
ffff00000008a7ac:	f9400000 	ldr	x0, [x0]
ffff00000008a7b0:	92748c01 	and	x1, x0, #0xfffffffff000
ffff00000008a7b4:	d2ffffe0 	mov	x0, #0xffff000000000000    	// #-281474976710656
ffff00000008a7b8:	8b000020 	add	x0, x1, x0
ffff00000008a7bc:	97fffe33 	bl	ffff00000008a088 <kfree>
ffff00000008a7c0:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff00000008a7c4:	d37df000 	lsl	x0, x0, #3
ffff00000008a7c8:	f94013e1 	ldr	x1, [sp, #32]
ffff00000008a7cc:	8b000020 	add	x0, x1, x0
ffff00000008a7d0:	f900001f 	str	xzr, [x0]
ffff00000008a7d4:	b9402fe0 	ldr	w0, [sp, #44]
ffff00000008a7d8:	11000400 	add	w0, w0, #0x1
ffff00000008a7dc:	b9002fe0 	str	w0, [sp, #44]
ffff00000008a7e0:	b9402fe0 	ldr	w0, [sp, #44]
ffff00000008a7e4:	7107fc1f 	cmp	w0, #0x1ff
ffff00000008a7e8:	54fffcad 	b.le	ffff00000008a77c <free_pud+0x1c>
ffff00000008a7ec:	d503201f 	nop
ffff00000008a7f0:	d503201f 	nop
ffff00000008a7f4:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff00000008a7f8:	d65f03c0 	ret

ffff00000008a7fc <free_pgd>:
ffff00000008a7fc:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008a800:	910003fd 	mov	x29, sp
ffff00000008a804:	f9000fe0 	str	x0, [sp, #24]
ffff00000008a808:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a80c:	97fffe1f 	bl	ffff00000008a088 <kfree>
ffff00000008a810:	d503201f 	nop
ffff00000008a814:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008a818:	d65f03c0 	ret

ffff00000008a81c <free_vm>:
ffff00000008a81c:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008a820:	910003fd 	mov	x29, sp
ffff00000008a824:	f9000fe0 	str	x0, [sp, #24]
ffff00000008a828:	d2a00801 	mov	x1, #0x400000              	// #4194304
ffff00000008a82c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a830:	97ffff58 	bl	ffff00000008a590 <free_page>
ffff00000008a834:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a838:	97ffff89 	bl	ffff00000008a65c <free_pmd>
ffff00000008a83c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a840:	97ffffc8 	bl	ffff00000008a760 <free_pud>
ffff00000008a844:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a848:	97ffffed 	bl	ffff00000008a7fc <free_pgd>
ffff00000008a84c:	d503201f 	nop
ffff00000008a850:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008a854:	d65f03c0 	ret

ffff00000008a858 <load_user_embedded>:
ffff00000008a858:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008a85c:	910003fd 	mov	x29, sp
ffff00000008a860:	f9000fe0 	str	x0, [sp, #24]
ffff00000008a864:	f0000000 	adrp	x0, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff00000008a868:	910ae001 	add	x1, x0, #0x2b8
ffff00000008a86c:	d0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008a870:	912dc000 	add	x0, x0, #0xb70
ffff00000008a874:	cb000020 	sub	x0, x1, x0
ffff00000008a878:	f90017e0 	str	x0, [sp, #40]
ffff00000008a87c:	f9400fe3 	ldr	x3, [sp, #24]
ffff00000008a880:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008a884:	2a0003e2 	mov	w2, w0
ffff00000008a888:	d0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008a88c:	912dc001 	add	x1, x0, #0xb70
ffff00000008a890:	aa0303e0 	mov	x0, x3
ffff00000008a894:	97ffd651 	bl	ffff0000000801d8 <memcpy>
ffff00000008a898:	d503201f 	nop
ffff00000008a89c:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff00000008a8a0:	d65f03c0 	ret

ffff00000008a8a4 <setup_uvm>:
ffff00000008a8a4:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008a8a8:	910003fd 	mov	x29, sp
ffff00000008a8ac:	f9000fe0 	str	x0, [sp, #24]
ffff00000008a8b0:	f9000be1 	str	x1, [sp, #16]
ffff00000008a8b4:	3900bfff 	strb	wzr, [sp, #47]
ffff00000008a8b8:	97fffe20 	bl	ffff00000008a138 <kalloc>
ffff00000008a8bc:	f90013e0 	str	x0, [sp, #32]
ffff00000008a8c0:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008a8c4:	f100001f 	cmp	x0, #0x0
ffff00000008a8c8:	54000400 	b.eq	ffff00000008a948 <setup_uvm+0xa4>  // b.none
ffff00000008a8cc:	52a00402 	mov	w2, #0x200000              	// #2097152
ffff00000008a8d0:	52800001 	mov	w1, #0x0                   	// #0
ffff00000008a8d4:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008a8d8:	97ffd62f 	bl	ffff000000080194 <memset>
ffff00000008a8dc:	f94013e1 	ldr	x1, [sp, #32]
ffff00000008a8e0:	d2e00020 	mov	x0, #0x1000000000000       	// #281474976710656
ffff00000008a8e4:	8b000020 	add	x0, x1, x0
ffff00000008a8e8:	d28088a3 	mov	x3, #0x445                 	// #1093
ffff00000008a8ec:	aa0003e2 	mov	x2, x0
ffff00000008a8f0:	d2a00801 	mov	x1, #0x400000              	// #4194304
ffff00000008a8f4:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a8f8:	97fffedb 	bl	ffff00000008a464 <map_page>
ffff00000008a8fc:	3900bfe0 	strb	w0, [sp, #47]
ffff00000008a900:	3940bfe0 	ldrb	w0, [sp, #47]
ffff00000008a904:	12000000 	and	w0, w0, #0x1
ffff00000008a908:	7100001f 	cmp	w0, #0x0
ffff00000008a90c:	54000160 	b.eq	ffff00000008a938 <setup_uvm+0x94>  // b.none
ffff00000008a910:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008a914:	aa0003e1 	mov	x1, x0
ffff00000008a918:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008a91c:	940001b7 	bl	ffff00000008aff8 <load_file>
ffff00000008a920:	3100041f 	cmn	w0, #0x1
ffff00000008a924:	54000121 	b.ne	ffff00000008a948 <setup_uvm+0xa4>  // b.any
ffff00000008a928:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a92c:	97ffffbc 	bl	ffff00000008a81c <free_vm>
ffff00000008a930:	52800000 	mov	w0, #0x0                   	// #0
ffff00000008a934:	14000006 	b	ffff00000008a94c <setup_uvm+0xa8>
ffff00000008a938:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008a93c:	97fffdd3 	bl	ffff00000008a088 <kfree>
ffff00000008a940:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008a944:	97ffffb6 	bl	ffff00000008a81c <free_vm>
ffff00000008a948:	3940bfe0 	ldrb	w0, [sp, #47]
ffff00000008a94c:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff00000008a950:	d65f03c0 	ret

ffff00000008a954 <switch_vm>:
ffff00000008a954:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008a958:	910003fd 	mov	x29, sp
ffff00000008a95c:	f9000fe0 	str	x0, [sp, #24]
ffff00000008a960:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008a964:	d2e00020 	mov	x0, #0x1000000000000       	// #281474976710656
ffff00000008a968:	8b000020 	add	x0, x1, x0
ffff00000008a96c:	97ffdda7 	bl	ffff000000082008 <load_pgd>
ffff00000008a970:	d503201f 	nop
ffff00000008a974:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008a978:	d65f03c0 	ret

ffff00000008a97c <init_memory>:
ffff00000008a97c:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffff00000008a980:	910003fd 	mov	x29, sp
ffff00000008a984:	f0000000 	adrp	x0, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff00000008a988:	91168000 	add	x0, x0, #0x5a0
ffff00000008a98c:	d2a60001 	mov	x1, #0x30000000            	// #805306368
ffff00000008a990:	f2ffffe1 	movk	x1, #0xffff, lsl #48
ffff00000008a994:	97fffd9f 	bl	ffff00000008a010 <free_region>
ffff00000008a998:	b0ffffc0 	adrp	x0, ffff000000083000 <pgd_ttbr1>
ffff00000008a99c:	91000001 	add	x1, x0, #0x0
ffff00000008a9a0:	f0000000 	adrp	x0, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff00000008a9a4:	910b4000 	add	x0, x0, #0x2d0
ffff00000008a9a8:	f9000001 	str	x1, [x0]
ffff00000008a9ac:	d503201f 	nop
ffff00000008a9b0:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffff00000008a9b4:	d65f03c0 	ret

ffff00000008a9b8 <get_fs_bpb>:
ffff00000008a9b8:	d10043ff 	sub	sp, sp, #0x10
ffff00000008a9bc:	d28038c0 	mov	x0, #0x1c6                 	// #454
ffff00000008a9c0:	f2a60000 	movk	x0, #0x3000, lsl #16
ffff00000008a9c4:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff00000008a9c8:	b9400000 	ldr	w0, [x0]
ffff00000008a9cc:	b9000fe0 	str	w0, [sp, #12]
ffff00000008a9d0:	b9400fe0 	ldr	w0, [sp, #12]
ffff00000008a9d4:	53175800 	lsl	w0, w0, #9
ffff00000008a9d8:	2a0003e1 	mov	w1, w0
ffff00000008a9dc:	d2a60000 	mov	x0, #0x30000000            	// #805306368
ffff00000008a9e0:	f2ffffe0 	movk	x0, #0xffff, lsl #48
ffff00000008a9e4:	8b000020 	add	x0, x1, x0
ffff00000008a9e8:	910043ff 	add	sp, sp, #0x10
ffff00000008a9ec:	d65f03c0 	ret

ffff00000008a9f0 <get_fat_table>:
ffff00000008a9f0:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008a9f4:	910003fd 	mov	x29, sp
ffff00000008a9f8:	97fffff0 	bl	ffff00000008a9b8 <get_fs_bpb>
ffff00000008a9fc:	f9000fe0 	str	x0, [sp, #24]
ffff00000008aa00:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008aa04:	79401c00 	ldrh	w0, [x0, #14]
ffff00000008aa08:	2a0003e1 	mov	w1, w0
ffff00000008aa0c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008aa10:	7840b000 	ldurh	w0, [x0, #11]
ffff00000008aa14:	1b007c20 	mul	w0, w1, w0
ffff00000008aa18:	b90017e0 	str	w0, [sp, #20]
ffff00000008aa1c:	b94017e0 	ldr	w0, [sp, #20]
ffff00000008aa20:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008aa24:	8b000020 	add	x0, x1, x0
ffff00000008aa28:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008aa2c:	d65f03c0 	ret

ffff00000008aa30 <get_cluster_value>:
ffff00000008aa30:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008aa34:	910003fd 	mov	x29, sp
ffff00000008aa38:	b9001fe0 	str	w0, [sp, #28]
ffff00000008aa3c:	97ffffed 	bl	ffff00000008a9f0 <get_fat_table>
ffff00000008aa40:	f90017e0 	str	x0, [sp, #40]
ffff00000008aa44:	b9401fe0 	ldr	w0, [sp, #28]
ffff00000008aa48:	8b000000 	add	x0, x0, x0
ffff00000008aa4c:	aa0003e1 	mov	x1, x0
ffff00000008aa50:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008aa54:	8b010000 	add	x0, x0, x1
ffff00000008aa58:	79400000 	ldrh	w0, [x0]
ffff00000008aa5c:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff00000008aa60:	d65f03c0 	ret

ffff00000008aa64 <get_cluster_offset>:
ffff00000008aa64:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff00000008aa68:	910003fd 	mov	x29, sp
ffff00000008aa6c:	b9001fe0 	str	w0, [sp, #28]
ffff00000008aa70:	b9401fe0 	ldr	w0, [sp, #28]
ffff00000008aa74:	7100041f 	cmp	w0, #0x1
ffff00000008aa78:	540000a8 	b.hi	ffff00000008aa8c <get_cluster_offset+0x28>  // b.pmore
ffff00000008aa7c:	d2800481 	mov	x1, #0x24                  	// #36
ffff00000008aa80:	d0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008aa84:	91068000 	add	x0, x0, #0x1a0
ffff00000008aa88:	97ffd89b 	bl	ffff000000080cf4 <error_check>
ffff00000008aa8c:	97ffffcb 	bl	ffff00000008a9b8 <get_fs_bpb>
ffff00000008aa90:	f9001fe0 	str	x0, [sp, #56]
ffff00000008aa94:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008aa98:	79401c00 	ldrh	w0, [x0, #14]
ffff00000008aa9c:	2a0003e1 	mov	w1, w0
ffff00000008aaa0:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008aaa4:	7840b000 	ldurh	w0, [x0, #11]
ffff00000008aaa8:	1b007c20 	mul	w0, w1, w0
ffff00000008aaac:	b90037e0 	str	w0, [sp, #52]
ffff00000008aab0:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008aab4:	39404000 	ldrb	w0, [x0, #16]
ffff00000008aab8:	2a0003e1 	mov	w1, w0
ffff00000008aabc:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008aac0:	79402c00 	ldrh	w0, [x0, #22]
ffff00000008aac4:	1b007c20 	mul	w0, w1, w0
ffff00000008aac8:	f9401fe1 	ldr	x1, [sp, #56]
ffff00000008aacc:	7840b021 	ldurh	w1, [x1, #11]
ffff00000008aad0:	1b017c00 	mul	w0, w0, w1
ffff00000008aad4:	b90033e0 	str	w0, [sp, #48]
ffff00000008aad8:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008aadc:	78411000 	ldurh	w0, [x0, #17]
ffff00000008aae0:	531b6800 	lsl	w0, w0, #5
ffff00000008aae4:	b9002fe0 	str	w0, [sp, #44]
ffff00000008aae8:	b94037e1 	ldr	w1, [sp, #52]
ffff00000008aaec:	b94033e0 	ldr	w0, [sp, #48]
ffff00000008aaf0:	0b000021 	add	w1, w1, w0
ffff00000008aaf4:	b9402fe0 	ldr	w0, [sp, #44]
ffff00000008aaf8:	0b000021 	add	w1, w1, w0
ffff00000008aafc:	b9401fe0 	ldr	w0, [sp, #28]
ffff00000008ab00:	51000802 	sub	w2, w0, #0x2
ffff00000008ab04:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008ab08:	39403400 	ldrb	w0, [x0, #13]
ffff00000008ab0c:	2a0003e3 	mov	w3, w0
ffff00000008ab10:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008ab14:	7840b000 	ldurh	w0, [x0, #11]
ffff00000008ab18:	1b007c60 	mul	w0, w3, w0
ffff00000008ab1c:	1b007c40 	mul	w0, w2, w0
ffff00000008ab20:	0b000020 	add	w0, w1, w0
ffff00000008ab24:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff00000008ab28:	d65f03c0 	ret

ffff00000008ab2c <get_cluster_size>:
ffff00000008ab2c:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008ab30:	910003fd 	mov	x29, sp
ffff00000008ab34:	97ffffa1 	bl	ffff00000008a9b8 <get_fs_bpb>
ffff00000008ab38:	f9000fe0 	str	x0, [sp, #24]
ffff00000008ab3c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008ab40:	7840b000 	ldurh	w0, [x0, #11]
ffff00000008ab44:	2a0003e1 	mov	w1, w0
ffff00000008ab48:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008ab4c:	39403400 	ldrb	w0, [x0, #13]
ffff00000008ab50:	1b007c20 	mul	w0, w1, w0
ffff00000008ab54:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008ab58:	d65f03c0 	ret

ffff00000008ab5c <get_root_directory_count>:
ffff00000008ab5c:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008ab60:	910003fd 	mov	x29, sp
ffff00000008ab64:	97ffff95 	bl	ffff00000008a9b8 <get_fs_bpb>
ffff00000008ab68:	f9000fe0 	str	x0, [sp, #24]
ffff00000008ab6c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008ab70:	78411000 	ldurh	w0, [x0, #17]
ffff00000008ab74:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008ab78:	d65f03c0 	ret

ffff00000008ab7c <get_root_directory>:
ffff00000008ab7c:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008ab80:	910003fd 	mov	x29, sp
ffff00000008ab84:	97ffff8d 	bl	ffff00000008a9b8 <get_fs_bpb>
ffff00000008ab88:	f9000fe0 	str	x0, [sp, #24]
ffff00000008ab8c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008ab90:	79401c00 	ldrh	w0, [x0, #14]
ffff00000008ab94:	2a0003e1 	mov	w1, w0
ffff00000008ab98:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008ab9c:	39404000 	ldrb	w0, [x0, #16]
ffff00000008aba0:	2a0003e2 	mov	w2, w0
ffff00000008aba4:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008aba8:	79402c00 	ldrh	w0, [x0, #22]
ffff00000008abac:	1b007c40 	mul	w0, w2, w0
ffff00000008abb0:	0b000020 	add	w0, w1, w0
ffff00000008abb4:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008abb8:	7840b021 	ldurh	w1, [x1, #11]
ffff00000008abbc:	1b017c00 	mul	w0, w0, w1
ffff00000008abc0:	b90017e0 	str	w0, [sp, #20]
ffff00000008abc4:	b94017e0 	ldr	w0, [sp, #20]
ffff00000008abc8:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008abcc:	8b000020 	add	x0, x1, x0
ffff00000008abd0:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008abd4:	d65f03c0 	ret

ffff00000008abd8 <is_file_name_equal>:
ffff00000008abd8:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff00000008abdc:	910003fd 	mov	x29, sp
ffff00000008abe0:	f90017e0 	str	x0, [sp, #40]
ffff00000008abe4:	f90013e1 	str	x1, [sp, #32]
ffff00000008abe8:	f9000fe2 	str	x2, [sp, #24]
ffff00000008abec:	3900ffff 	strb	wzr, [sp, #63]
ffff00000008abf0:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008abf4:	52800102 	mov	w2, #0x8                   	// #8
ffff00000008abf8:	f94013e1 	ldr	x1, [sp, #32]
ffff00000008abfc:	97ffd56c 	bl	ffff0000000801ac <memcmp>
ffff00000008ac00:	7100001f 	cmp	w0, #0x0
ffff00000008ac04:	54000141 	b.ne	ffff00000008ac2c <is_file_name_equal+0x54>  // b.any
ffff00000008ac08:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008ac0c:	91002000 	add	x0, x0, #0x8
ffff00000008ac10:	52800062 	mov	w2, #0x3                   	// #3
ffff00000008ac14:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008ac18:	97ffd565 	bl	ffff0000000801ac <memcmp>
ffff00000008ac1c:	7100001f 	cmp	w0, #0x0
ffff00000008ac20:	54000061 	b.ne	ffff00000008ac2c <is_file_name_equal+0x54>  // b.any
ffff00000008ac24:	52800020 	mov	w0, #0x1                   	// #1
ffff00000008ac28:	3900ffe0 	strb	w0, [sp, #63]
ffff00000008ac2c:	3940ffe0 	ldrb	w0, [sp, #63]
ffff00000008ac30:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff00000008ac34:	d65f03c0 	ret

ffff00000008ac38 <split_path>:
ffff00000008ac38:	d100c3ff 	sub	sp, sp, #0x30
ffff00000008ac3c:	f9000fe0 	str	x0, [sp, #24]
ffff00000008ac40:	f9000be1 	str	x1, [sp, #16]
ffff00000008ac44:	f90007e2 	str	x2, [sp, #8]
ffff00000008ac48:	b9002fff 	str	wzr, [sp, #44]
ffff00000008ac4c:	14000014 	b	ffff00000008ac9c <split_path+0x64>
ffff00000008ac50:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff00000008ac54:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008ac58:	8b000020 	add	x0, x1, x0
ffff00000008ac5c:	39400000 	ldrb	w0, [x0]
ffff00000008ac60:	7100bc1f 	cmp	w0, #0x2f
ffff00000008ac64:	54000061 	b.ne	ffff00000008ac70 <split_path+0x38>  // b.any
ffff00000008ac68:	52800000 	mov	w0, #0x0                   	// #0
ffff00000008ac6c:	1400004e 	b	ffff00000008ada4 <split_path+0x16c>
ffff00000008ac70:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff00000008ac74:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008ac78:	8b000021 	add	x1, x1, x0
ffff00000008ac7c:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff00000008ac80:	f9400be2 	ldr	x2, [sp, #16]
ffff00000008ac84:	8b000040 	add	x0, x2, x0
ffff00000008ac88:	39400021 	ldrb	w1, [x1]
ffff00000008ac8c:	39000001 	strb	w1, [x0]
ffff00000008ac90:	b9402fe0 	ldr	w0, [sp, #44]
ffff00000008ac94:	11000400 	add	w0, w0, #0x1
ffff00000008ac98:	b9002fe0 	str	w0, [sp, #44]
ffff00000008ac9c:	b9402fe0 	ldr	w0, [sp, #44]
ffff00000008aca0:	71001c1f 	cmp	w0, #0x7
ffff00000008aca4:	540001ac 	b.gt	ffff00000008acd8 <split_path+0xa0>
ffff00000008aca8:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff00000008acac:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008acb0:	8b000020 	add	x0, x1, x0
ffff00000008acb4:	39400000 	ldrb	w0, [x0]
ffff00000008acb8:	7100b81f 	cmp	w0, #0x2e
ffff00000008acbc:	540000e0 	b.eq	ffff00000008acd8 <split_path+0xa0>  // b.none
ffff00000008acc0:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff00000008acc4:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008acc8:	8b000020 	add	x0, x1, x0
ffff00000008accc:	39400000 	ldrb	w0, [x0]
ffff00000008acd0:	7100001f 	cmp	w0, #0x0
ffff00000008acd4:	54fffbe1 	b.ne	ffff00000008ac50 <split_path+0x18>  // b.any
ffff00000008acd8:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff00000008acdc:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008ace0:	8b000020 	add	x0, x1, x0
ffff00000008ace4:	39400000 	ldrb	w0, [x0]
ffff00000008ace8:	7100b81f 	cmp	w0, #0x2e
ffff00000008acec:	540004a1 	b.ne	ffff00000008ad80 <split_path+0x148>  // b.any
ffff00000008acf0:	b9402fe0 	ldr	w0, [sp, #44]
ffff00000008acf4:	11000400 	add	w0, w0, #0x1
ffff00000008acf8:	b9002fe0 	str	w0, [sp, #44]
ffff00000008acfc:	b9002bff 	str	wzr, [sp, #40]
ffff00000008ad00:	14000017 	b	ffff00000008ad5c <split_path+0x124>
ffff00000008ad04:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff00000008ad08:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008ad0c:	8b000020 	add	x0, x1, x0
ffff00000008ad10:	39400000 	ldrb	w0, [x0]
ffff00000008ad14:	7100bc1f 	cmp	w0, #0x2f
ffff00000008ad18:	54000061 	b.ne	ffff00000008ad24 <split_path+0xec>  // b.any
ffff00000008ad1c:	52800000 	mov	w0, #0x0                   	// #0
ffff00000008ad20:	14000021 	b	ffff00000008ada4 <split_path+0x16c>
ffff00000008ad24:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff00000008ad28:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008ad2c:	8b000021 	add	x1, x1, x0
ffff00000008ad30:	b9802be0 	ldrsw	x0, [sp, #40]
ffff00000008ad34:	f94007e2 	ldr	x2, [sp, #8]
ffff00000008ad38:	8b000040 	add	x0, x2, x0
ffff00000008ad3c:	39400021 	ldrb	w1, [x1]
ffff00000008ad40:	39000001 	strb	w1, [x0]
ffff00000008ad44:	b9402fe0 	ldr	w0, [sp, #44]
ffff00000008ad48:	11000400 	add	w0, w0, #0x1
ffff00000008ad4c:	b9002fe0 	str	w0, [sp, #44]
ffff00000008ad50:	b9402be0 	ldr	w0, [sp, #40]
ffff00000008ad54:	11000400 	add	w0, w0, #0x1
ffff00000008ad58:	b9002be0 	str	w0, [sp, #40]
ffff00000008ad5c:	b9402be0 	ldr	w0, [sp, #40]
ffff00000008ad60:	7100081f 	cmp	w0, #0x2
ffff00000008ad64:	540000ec 	b.gt	ffff00000008ad80 <split_path+0x148>
ffff00000008ad68:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff00000008ad6c:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008ad70:	8b000020 	add	x0, x1, x0
ffff00000008ad74:	39400000 	ldrb	w0, [x0]
ffff00000008ad78:	7100001f 	cmp	w0, #0x0
ffff00000008ad7c:	54fffc41 	b.ne	ffff00000008ad04 <split_path+0xcc>  // b.any
ffff00000008ad80:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff00000008ad84:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008ad88:	8b000020 	add	x0, x1, x0
ffff00000008ad8c:	39400000 	ldrb	w0, [x0]
ffff00000008ad90:	7100001f 	cmp	w0, #0x0
ffff00000008ad94:	54000060 	b.eq	ffff00000008ada0 <split_path+0x168>  // b.none
ffff00000008ad98:	52800000 	mov	w0, #0x0                   	// #0
ffff00000008ad9c:	14000002 	b	ffff00000008ada4 <split_path+0x16c>
ffff00000008ada0:	52800020 	mov	w0, #0x1                   	// #1
ffff00000008ada4:	9100c3ff 	add	sp, sp, #0x30
ffff00000008ada8:	d65f03c0 	ret

ffff00000008adac <search_file>:
ffff00000008adac:	a9bb7bfd 	stp	x29, x30, [sp, #-80]!
ffff00000008adb0:	910003fd 	mov	x29, sp
ffff00000008adb4:	f9000fe0 	str	x0, [sp, #24]
ffff00000008adb8:	b203c3e0 	mov	x0, #0x2020202020202020    	// #2314885530818453536
ffff00000008adbc:	f9001be0 	str	x0, [sp, #48]
ffff00000008adc0:	d0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008adc4:	9106a001 	add	x1, x0, #0x1a8
ffff00000008adc8:	9100a3e0 	add	x0, sp, #0x28
ffff00000008adcc:	79400022 	ldrh	w2, [x1]
ffff00000008add0:	39400821 	ldrb	w1, [x1, #2]
ffff00000008add4:	79000002 	strh	w2, [x0]
ffff00000008add8:	39000801 	strb	w1, [x0, #2]
ffff00000008addc:	9100a3e1 	add	x1, sp, #0x28
ffff00000008ade0:	9100c3e0 	add	x0, sp, #0x30
ffff00000008ade4:	aa0103e2 	mov	x2, x1
ffff00000008ade8:	aa0003e1 	mov	x1, x0
ffff00000008adec:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008adf0:	97ffff92 	bl	ffff00000008ac38 <split_path>
ffff00000008adf4:	39012fe0 	strb	w0, [sp, #75]
ffff00000008adf8:	39412fe0 	ldrb	w0, [sp, #75]
ffff00000008adfc:	12000000 	and	w0, w0, #0x1
ffff00000008ae00:	7100001f 	cmp	w0, #0x0
ffff00000008ae04:	54000660 	b.eq	ffff00000008aed0 <search_file+0x124>  // b.none
ffff00000008ae08:	97ffff55 	bl	ffff00000008ab5c <get_root_directory_count>
ffff00000008ae0c:	b90047e0 	str	w0, [sp, #68]
ffff00000008ae10:	97ffff5b 	bl	ffff00000008ab7c <get_root_directory>
ffff00000008ae14:	f9001fe0 	str	x0, [sp, #56]
ffff00000008ae18:	b9004fff 	str	wzr, [sp, #76]
ffff00000008ae1c:	14000029 	b	ffff00000008aec0 <search_file+0x114>
ffff00000008ae20:	b9404fe0 	ldr	w0, [sp, #76]
ffff00000008ae24:	d37be800 	lsl	x0, x0, #5
ffff00000008ae28:	f9401fe1 	ldr	x1, [sp, #56]
ffff00000008ae2c:	8b000020 	add	x0, x1, x0
ffff00000008ae30:	39400000 	ldrb	w0, [x0]
ffff00000008ae34:	7100001f 	cmp	w0, #0x0
ffff00000008ae38:	54000380 	b.eq	ffff00000008aea8 <search_file+0xfc>  // b.none
ffff00000008ae3c:	b9404fe0 	ldr	w0, [sp, #76]
ffff00000008ae40:	d37be800 	lsl	x0, x0, #5
ffff00000008ae44:	f9401fe1 	ldr	x1, [sp, #56]
ffff00000008ae48:	8b000020 	add	x0, x1, x0
ffff00000008ae4c:	39400000 	ldrb	w0, [x0]
ffff00000008ae50:	7103941f 	cmp	w0, #0xe5
ffff00000008ae54:	540002a0 	b.eq	ffff00000008aea8 <search_file+0xfc>  // b.none
ffff00000008ae58:	b9404fe0 	ldr	w0, [sp, #76]
ffff00000008ae5c:	d37be800 	lsl	x0, x0, #5
ffff00000008ae60:	f9401fe1 	ldr	x1, [sp, #56]
ffff00000008ae64:	8b000020 	add	x0, x1, x0
ffff00000008ae68:	39402c00 	ldrb	w0, [x0, #11]
ffff00000008ae6c:	71003c1f 	cmp	w0, #0xf
ffff00000008ae70:	54000200 	b.eq	ffff00000008aeb0 <search_file+0x104>  // b.none
ffff00000008ae74:	b9404fe0 	ldr	w0, [sp, #76]
ffff00000008ae78:	d37be800 	lsl	x0, x0, #5
ffff00000008ae7c:	f9401fe1 	ldr	x1, [sp, #56]
ffff00000008ae80:	8b000020 	add	x0, x1, x0
ffff00000008ae84:	9100a3e2 	add	x2, sp, #0x28
ffff00000008ae88:	9100c3e1 	add	x1, sp, #0x30
ffff00000008ae8c:	97ffff53 	bl	ffff00000008abd8 <is_file_name_equal>
ffff00000008ae90:	12001c00 	and	w0, w0, #0xff
ffff00000008ae94:	12000000 	and	w0, w0, #0x1
ffff00000008ae98:	7100001f 	cmp	w0, #0x0
ffff00000008ae9c:	540000c0 	b.eq	ffff00000008aeb4 <search_file+0x108>  // b.none
ffff00000008aea0:	b9404fe0 	ldr	w0, [sp, #76]
ffff00000008aea4:	1400000c 	b	ffff00000008aed4 <search_file+0x128>
ffff00000008aea8:	d503201f 	nop
ffff00000008aeac:	14000002 	b	ffff00000008aeb4 <search_file+0x108>
ffff00000008aeb0:	d503201f 	nop
ffff00000008aeb4:	b9404fe0 	ldr	w0, [sp, #76]
ffff00000008aeb8:	11000400 	add	w0, w0, #0x1
ffff00000008aebc:	b9004fe0 	str	w0, [sp, #76]
ffff00000008aec0:	b9404fe1 	ldr	w1, [sp, #76]
ffff00000008aec4:	b94047e0 	ldr	w0, [sp, #68]
ffff00000008aec8:	6b00003f 	cmp	w1, w0
ffff00000008aecc:	54fffaa3 	b.cc	ffff00000008ae20 <search_file+0x74>  // b.lo, b.ul, b.last
ffff00000008aed0:	12800000 	mov	w0, #0xffffffff            	// #-1
ffff00000008aed4:	a8c57bfd 	ldp	x29, x30, [sp], #80
ffff00000008aed8:	d65f03c0 	ret

ffff00000008aedc <read_raw_data>:
ffff00000008aedc:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff00000008aee0:	910003fd 	mov	x29, sp
ffff00000008aee4:	b9001fe0 	str	w0, [sp, #28]
ffff00000008aee8:	f9000be1 	str	x1, [sp, #16]
ffff00000008aeec:	b9001be2 	str	w2, [sp, #24]
ffff00000008aef0:	b9003fff 	str	wzr, [sp, #60]
ffff00000008aef4:	97fffeb1 	bl	ffff00000008a9b8 <get_fs_bpb>
ffff00000008aef8:	f9001be0 	str	x0, [sp, #48]
ffff00000008aefc:	97ffff0c 	bl	ffff00000008ab2c <get_cluster_size>
ffff00000008af00:	b9002fe0 	str	w0, [sp, #44]
ffff00000008af04:	b9401fe0 	ldr	w0, [sp, #28]
ffff00000008af08:	b9003be0 	str	w0, [sp, #56]
ffff00000008af0c:	b9403be0 	ldr	w0, [sp, #56]
ffff00000008af10:	7100041f 	cmp	w0, #0x1
ffff00000008af14:	540004e8 	b.hi	ffff00000008afb0 <read_raw_data+0xd4>  // b.pmore
ffff00000008af18:	12800000 	mov	w0, #0xffffffff            	// #-1
ffff00000008af1c:	1400002a 	b	ffff00000008afc4 <read_raw_data+0xe8>
ffff00000008af20:	b9403be0 	ldr	w0, [sp, #56]
ffff00000008af24:	97fffed0 	bl	ffff00000008aa64 <get_cluster_offset>
ffff00000008af28:	2a0003e1 	mov	w1, w0
ffff00000008af2c:	f9401be0 	ldr	x0, [sp, #48]
ffff00000008af30:	8b000020 	add	x0, x1, x0
ffff00000008af34:	f90013e0 	str	x0, [sp, #32]
ffff00000008af38:	b9403be0 	ldr	w0, [sp, #56]
ffff00000008af3c:	97fffebd 	bl	ffff00000008aa30 <get_cluster_value>
ffff00000008af40:	12003c00 	and	w0, w0, #0xffff
ffff00000008af44:	b9003be0 	str	w0, [sp, #56]
ffff00000008af48:	b9403be1 	ldr	w1, [sp, #56]
ffff00000008af4c:	529ffec0 	mov	w0, #0xfff6                	// #65526
ffff00000008af50:	6b00003f 	cmp	w1, w0
ffff00000008af54:	54000169 	b.ls	ffff00000008af80 <read_raw_data+0xa4>  // b.plast
ffff00000008af58:	b9401be1 	ldr	w1, [sp, #24]
ffff00000008af5c:	b9403fe0 	ldr	w0, [sp, #60]
ffff00000008af60:	4b000020 	sub	w0, w1, w0
ffff00000008af64:	2a0003e2 	mov	w2, w0
ffff00000008af68:	f94013e1 	ldr	x1, [sp, #32]
ffff00000008af6c:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008af70:	97ffd49a 	bl	ffff0000000801d8 <memcpy>
ffff00000008af74:	b9401be0 	ldr	w0, [sp, #24]
ffff00000008af78:	b9003fe0 	str	w0, [sp, #60]
ffff00000008af7c:	14000011 	b	ffff00000008afc0 <read_raw_data+0xe4>
ffff00000008af80:	b9402fe2 	ldr	w2, [sp, #44]
ffff00000008af84:	f94013e1 	ldr	x1, [sp, #32]
ffff00000008af88:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008af8c:	97ffd493 	bl	ffff0000000801d8 <memcpy>
ffff00000008af90:	b9402fe0 	ldr	w0, [sp, #44]
ffff00000008af94:	f9400be1 	ldr	x1, [sp, #16]
ffff00000008af98:	8b000020 	add	x0, x1, x0
ffff00000008af9c:	f9000be0 	str	x0, [sp, #16]
ffff00000008afa0:	b9403fe1 	ldr	w1, [sp, #60]
ffff00000008afa4:	b9402fe0 	ldr	w0, [sp, #44]
ffff00000008afa8:	0b000020 	add	w0, w1, w0
ffff00000008afac:	b9003fe0 	str	w0, [sp, #60]
ffff00000008afb0:	b9403fe1 	ldr	w1, [sp, #60]
ffff00000008afb4:	b9401be0 	ldr	w0, [sp, #24]
ffff00000008afb8:	6b00003f 	cmp	w1, w0
ffff00000008afbc:	54fffb23 	b.cc	ffff00000008af20 <read_raw_data+0x44>  // b.lo, b.ul, b.last
ffff00000008afc0:	b9403fe0 	ldr	w0, [sp, #60]
ffff00000008afc4:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff00000008afc8:	d65f03c0 	ret

ffff00000008afcc <read_file>:
ffff00000008afcc:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008afd0:	910003fd 	mov	x29, sp
ffff00000008afd4:	b9001fe0 	str	w0, [sp, #28]
ffff00000008afd8:	f9000be1 	str	x1, [sp, #16]
ffff00000008afdc:	b9001be2 	str	w2, [sp, #24]
ffff00000008afe0:	b9401be2 	ldr	w2, [sp, #24]
ffff00000008afe4:	f9400be1 	ldr	x1, [sp, #16]
ffff00000008afe8:	b9401fe0 	ldr	w0, [sp, #28]
ffff00000008afec:	97ffffbc 	bl	ffff00000008aedc <read_raw_data>
ffff00000008aff0:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008aff4:	d65f03c0 	ret

ffff00000008aff8 <load_file>:
ffff00000008aff8:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff00000008affc:	910003fd 	mov	x29, sp
ffff00000008b000:	f9000fe0 	str	x0, [sp, #24]
ffff00000008b004:	f9000be1 	str	x1, [sp, #16]
ffff00000008b008:	12800000 	mov	w0, #0xffffffff            	// #-1
ffff00000008b00c:	b9003fe0 	str	w0, [sp, #60]
ffff00000008b010:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b014:	97ffff66 	bl	ffff00000008adac <search_file>
ffff00000008b018:	b9003be0 	str	w0, [sp, #56]
ffff00000008b01c:	b9403be0 	ldr	w0, [sp, #56]
ffff00000008b020:	3100041f 	cmn	w0, #0x1
ffff00000008b024:	54000320 	b.eq	ffff00000008b088 <load_file+0x90>  // b.none
ffff00000008b028:	97fffed5 	bl	ffff00000008ab7c <get_root_directory>
ffff00000008b02c:	f9001be0 	str	x0, [sp, #48]
ffff00000008b030:	b9403be0 	ldr	w0, [sp, #56]
ffff00000008b034:	d37be800 	lsl	x0, x0, #5
ffff00000008b038:	f9401be1 	ldr	x1, [sp, #48]
ffff00000008b03c:	8b000020 	add	x0, x1, x0
ffff00000008b040:	b9401c00 	ldr	w0, [x0, #28]
ffff00000008b044:	b9002fe0 	str	w0, [sp, #44]
ffff00000008b048:	b9403be0 	ldr	w0, [sp, #56]
ffff00000008b04c:	d37be800 	lsl	x0, x0, #5
ffff00000008b050:	f9401be1 	ldr	x1, [sp, #48]
ffff00000008b054:	8b000020 	add	x0, x1, x0
ffff00000008b058:	79403400 	ldrh	w0, [x0, #26]
ffff00000008b05c:	b9002be0 	str	w0, [sp, #40]
ffff00000008b060:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008b064:	b9402fe2 	ldr	w2, [sp, #44]
ffff00000008b068:	aa0003e1 	mov	x1, x0
ffff00000008b06c:	b9402be0 	ldr	w0, [sp, #40]
ffff00000008b070:	97ffffd7 	bl	ffff00000008afcc <read_file>
ffff00000008b074:	2a0003e1 	mov	w1, w0
ffff00000008b078:	b9402fe0 	ldr	w0, [sp, #44]
ffff00000008b07c:	6b01001f 	cmp	w0, w1
ffff00000008b080:	54000041 	b.ne	ffff00000008b088 <load_file+0x90>  // b.any
ffff00000008b084:	b9003fff 	str	wzr, [sp, #60]
ffff00000008b088:	b9403fe0 	ldr	w0, [sp, #60]
ffff00000008b08c:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff00000008b090:	d65f03c0 	ret

ffff00000008b094 <init_fs>:
ffff00000008b094:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008b098:	910003fd 	mov	x29, sp
ffff00000008b09c:	97fffe47 	bl	ffff00000008a9b8 <get_fs_bpb>
ffff00000008b0a0:	f9000fe0 	str	x0, [sp, #24]
ffff00000008b0a4:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b0a8:	9107f800 	add	x0, x0, #0x1fe
ffff00000008b0ac:	39400000 	ldrb	w0, [x0]
ffff00000008b0b0:	7101541f 	cmp	w0, #0x55
ffff00000008b0b4:	540000c1 	b.ne	ffff00000008b0cc <init_fs+0x38>  // b.any
ffff00000008b0b8:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b0bc:	9107fc00 	add	x0, x0, #0x1ff
ffff00000008b0c0:	39400000 	ldrb	w0, [x0]
ffff00000008b0c4:	7102a81f 	cmp	w0, #0xaa
ffff00000008b0c8:	54000100 	b.eq	ffff00000008b0e8 <init_fs+0x54>  // b.none
ffff00000008b0cc:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b0d0:	9106c000 	add	x0, x0, #0x1b0
ffff00000008b0d4:	97ffd632 	bl	ffff00000008099c <printk>
ffff00000008b0d8:	d2801b01 	mov	x1, #0xd8                  	// #216
ffff00000008b0dc:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b0e0:	91068000 	add	x0, x0, #0x1a0
ffff00000008b0e4:	97ffd704 	bl	ffff000000080cf4 <error_check>
ffff00000008b0e8:	d503201f 	nop
ffff00000008b0ec:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008b0f0:	d65f03c0 	ret

ffff00000008b0f4 <get_pc>:
ffff00000008b0f4:	d0000000 	adrp	x0, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff00000008b0f8:	91146000 	add	x0, x0, #0x518
ffff00000008b0fc:	d65f03c0 	ret

ffff00000008b100 <find_unused_process>:
ffff00000008b100:	d10043ff 	sub	sp, sp, #0x10
ffff00000008b104:	f90007ff 	str	xzr, [sp, #8]
ffff00000008b108:	b90007ff 	str	wzr, [sp, #4]
ffff00000008b10c:	14000015 	b	ffff00000008b160 <find_unused_process+0x60>
ffff00000008b110:	d0000000 	adrp	x0, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff00000008b114:	910ba001 	add	x1, x0, #0x2e8
ffff00000008b118:	b98007e2 	ldrsw	x2, [sp, #4]
ffff00000008b11c:	d2800700 	mov	x0, #0x38                  	// #56
ffff00000008b120:	9b007c40 	mul	x0, x2, x0
ffff00000008b124:	8b000020 	add	x0, x1, x0
ffff00000008b128:	b9400c00 	ldr	w0, [x0, #12]
ffff00000008b12c:	7100001f 	cmp	w0, #0x0
ffff00000008b130:	54000121 	b.ne	ffff00000008b154 <find_unused_process+0x54>  // b.any
ffff00000008b134:	b98007e1 	ldrsw	x1, [sp, #4]
ffff00000008b138:	d2800700 	mov	x0, #0x38                  	// #56
ffff00000008b13c:	9b007c21 	mul	x1, x1, x0
ffff00000008b140:	d0000000 	adrp	x0, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff00000008b144:	910ba000 	add	x0, x0, #0x2e8
ffff00000008b148:	8b000020 	add	x0, x1, x0
ffff00000008b14c:	f90007e0 	str	x0, [sp, #8]
ffff00000008b150:	14000007 	b	ffff00000008b16c <find_unused_process+0x6c>
ffff00000008b154:	b94007e0 	ldr	w0, [sp, #4]
ffff00000008b158:	11000400 	add	w0, w0, #0x1
ffff00000008b15c:	b90007e0 	str	w0, [sp, #4]
ffff00000008b160:	b94007e0 	ldr	w0, [sp, #4]
ffff00000008b164:	7100241f 	cmp	w0, #0x9
ffff00000008b168:	54fffd4d 	b.le	ffff00000008b110 <find_unused_process+0x10>
ffff00000008b16c:	f94007e0 	ldr	x0, [sp, #8]
ffff00000008b170:	910043ff 	add	sp, sp, #0x10
ffff00000008b174:	d65f03c0 	ret

ffff00000008b178 <idle_thread>:
ffff00000008b178:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffff00000008b17c:	910003fd 	mov	x29, sp
ffff00000008b180:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b184:	91072000 	add	x0, x0, #0x1c8
ffff00000008b188:	97ffd605 	bl	ffff00000008099c <printk>
ffff00000008b18c:	94000279 	bl	ffff00000008bb70 <schedule>
ffff00000008b190:	d503201f 	nop
ffff00000008b194:	17fffffb 	b	ffff00000008b180 <idle_thread+0x8>

ffff00000008b198 <init_idle_process>:
ffff00000008b198:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008b19c:	910003fd 	mov	x29, sp
ffff00000008b1a0:	97ffffd8 	bl	ffff00000008b100 <find_unused_process>
ffff00000008b1a4:	f9000fe0 	str	x0, [sp, #24]
ffff00000008b1a8:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008b1ac:	d0000000 	adrp	x0, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff00000008b1b0:	910ba000 	add	x0, x0, #0x2e8
ffff00000008b1b4:	eb00003f 	cmp	x1, x0
ffff00000008b1b8:	540000a0 	b.eq	ffff00000008b1cc <init_idle_process+0x34>  // b.none
ffff00000008b1bc:	d28006c1 	mov	x1, #0x36                  	// #54
ffff00000008b1c0:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b1c4:	91076000 	add	x0, x0, #0x1d8
ffff00000008b1c8:	97ffd6cb 	bl	ffff000000080cf4 <error_check>
ffff00000008b1cc:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b1d0:	52800041 	mov	w1, #0x2                   	// #2
ffff00000008b1d4:	b9000c01 	str	w1, [x0, #12]
ffff00000008b1d8:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b1dc:	b900081f 	str	wzr, [x0, #8]
ffff00000008b1e0:	97fffbd6 	bl	ffff00000008a138 <kalloc>
ffff00000008b1e4:	aa0003e1 	mov	x1, x0
ffff00000008b1e8:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b1ec:	f9001401 	str	x1, [x0, #40]
ffff00000008b1f0:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b1f4:	f9401400 	ldr	x0, [x0, #40]
ffff00000008b1f8:	f100001f 	cmp	x0, #0x0
ffff00000008b1fc:	540000a1 	b.ne	ffff00000008b210 <init_idle_process+0x78>  // b.any
ffff00000008b200:	d28007c1 	mov	x1, #0x3e                  	// #62
ffff00000008b204:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b208:	91076000 	add	x0, x0, #0x1d8
ffff00000008b20c:	97ffd6ba 	bl	ffff000000080cf4 <error_check>
ffff00000008b210:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b214:	f9401400 	ldr	x0, [x0, #40]
ffff00000008b218:	52a00402 	mov	w2, #0x200000              	// #2097152
ffff00000008b21c:	52800001 	mov	w1, #0x0                   	// #0
ffff00000008b220:	97ffd3dd 	bl	ffff000000080194 <memset>
ffff00000008b224:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b228:	f9401401 	ldr	x1, [x0, #40]
ffff00000008b22c:	d29fd000 	mov	x0, #0xfe80                	// #65152
ffff00000008b230:	f2a003e0 	movk	x0, #0x1f, lsl #16
ffff00000008b234:	8b000021 	add	x1, x1, x0
ffff00000008b238:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b23c:	f9000c01 	str	x1, [x0, #24]
ffff00000008b240:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b244:	f9400c00 	ldr	x0, [x0, #24]
ffff00000008b248:	91016000 	add	x0, x0, #0x58
ffff00000008b24c:	aa0003e1 	mov	x1, x0
ffff00000008b250:	90000000 	adrp	x0, ffff00000008b000 <load_file+0x8>
ffff00000008b254:	9105e000 	add	x0, x0, #0x178
ffff00000008b258:	f9000020 	str	x0, [x1]
ffff00000008b25c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b260:	f9401401 	ldr	x1, [x0, #40]
ffff00000008b264:	d29fdc00 	mov	x0, #0xfee0                	// #65248
ffff00000008b268:	f2a003e0 	movk	x0, #0x1f, lsl #16
ffff00000008b26c:	8b000020 	add	x0, x1, x0
ffff00000008b270:	aa0003e1 	mov	x1, x0
ffff00000008b274:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b278:	f9001801 	str	x1, [x0, #48]
ffff00000008b27c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b280:	f9401800 	ldr	x0, [x0, #48]
ffff00000008b284:	52802402 	mov	w2, #0x120                 	// #288
ffff00000008b288:	52800001 	mov	w1, #0x0                   	// #0
ffff00000008b28c:	97ffd3c2 	bl	ffff000000080194 <memset>
ffff00000008b290:	d0000000 	adrp	x0, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff00000008b294:	910b4000 	add	x0, x0, #0x2d0
ffff00000008b298:	f9400001 	ldr	x1, [x0]
ffff00000008b29c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b2a0:	f9001001 	str	x1, [x0, #32]
ffff00000008b2a4:	97ffff94 	bl	ffff00000008b0f4 <get_pc>
ffff00000008b2a8:	f9000be0 	str	x0, [sp, #16]
ffff00000008b2ac:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008b2b0:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008b2b4:	f9000001 	str	x1, [x0]
ffff00000008b2b8:	d503201f 	nop
ffff00000008b2bc:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008b2c0:	d65f03c0 	ret

ffff00000008b2c4 <alloc_new_process>:
ffff00000008b2c4:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008b2c8:	910003fd 	mov	x29, sp
ffff00000008b2cc:	97ffff8d 	bl	ffff00000008b100 <find_unused_process>
ffff00000008b2d0:	f9000fe0 	str	x0, [sp, #24]
ffff00000008b2d4:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008b2d8:	d0000000 	adrp	x0, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff00000008b2dc:	910c8000 	add	x0, x0, #0x320
ffff00000008b2e0:	eb00003f 	cmp	x1, x0
ffff00000008b2e4:	540000a0 	b.eq	ffff00000008b2f8 <alloc_new_process+0x34>  // b.none
ffff00000008b2e8:	d2800bc1 	mov	x1, #0x5e                  	// #94
ffff00000008b2ec:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b2f0:	91076000 	add	x0, x0, #0x1d8
ffff00000008b2f4:	97ffd680 	bl	ffff000000080cf4 <error_check>
ffff00000008b2f8:	97fffb90 	bl	ffff00000008a138 <kalloc>
ffff00000008b2fc:	aa0003e1 	mov	x1, x0
ffff00000008b300:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b304:	f9001401 	str	x1, [x0, #40]
ffff00000008b308:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b30c:	f9401400 	ldr	x0, [x0, #40]
ffff00000008b310:	f100001f 	cmp	x0, #0x0
ffff00000008b314:	540000a1 	b.ne	ffff00000008b328 <alloc_new_process+0x64>  // b.any
ffff00000008b318:	d2800c21 	mov	x1, #0x61                  	// #97
ffff00000008b31c:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b320:	91076000 	add	x0, x0, #0x1d8
ffff00000008b324:	97ffd674 	bl	ffff000000080cf4 <error_check>
ffff00000008b328:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b32c:	f9401400 	ldr	x0, [x0, #40]
ffff00000008b330:	52a00402 	mov	w2, #0x200000              	// #2097152
ffff00000008b334:	52800001 	mov	w1, #0x0                   	// #0
ffff00000008b338:	97ffd397 	bl	ffff000000080194 <memset>
ffff00000008b33c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b340:	52800021 	mov	w1, #0x1                   	// #1
ffff00000008b344:	b9000c01 	str	w1, [x0, #12]
ffff00000008b348:	d0000000 	adrp	x0, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff00000008b34c:	910ae000 	add	x0, x0, #0x2b8
ffff00000008b350:	b9400000 	ldr	w0, [x0]
ffff00000008b354:	11000402 	add	w2, w0, #0x1
ffff00000008b358:	d0000001 	adrp	x1, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff00000008b35c:	910ae021 	add	x1, x1, #0x2b8
ffff00000008b360:	b9000022 	str	w2, [x1]
ffff00000008b364:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008b368:	b9000820 	str	w0, [x1, #8]
ffff00000008b36c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b370:	f9401401 	ldr	x1, [x0, #40]
ffff00000008b374:	d29fd000 	mov	x0, #0xfe80                	// #65152
ffff00000008b378:	f2a003e0 	movk	x0, #0x1f, lsl #16
ffff00000008b37c:	8b000021 	add	x1, x1, x0
ffff00000008b380:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b384:	f9000c01 	str	x1, [x0, #24]
ffff00000008b388:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b38c:	f9400c00 	ldr	x0, [x0, #24]
ffff00000008b390:	91016000 	add	x0, x0, #0x58
ffff00000008b394:	aa0003e1 	mov	x1, x0
ffff00000008b398:	d0ffffa0 	adrp	x0, ffff000000081000 <vector_table>
ffff00000008b39c:	911e2000 	add	x0, x0, #0x788
ffff00000008b3a0:	f9000020 	str	x0, [x1]
ffff00000008b3a4:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b3a8:	f9401401 	ldr	x1, [x0, #40]
ffff00000008b3ac:	d29fdc00 	mov	x0, #0xfee0                	// #65248
ffff00000008b3b0:	f2a003e0 	movk	x0, #0x1f, lsl #16
ffff00000008b3b4:	8b000020 	add	x0, x1, x0
ffff00000008b3b8:	aa0003e1 	mov	x1, x0
ffff00000008b3bc:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b3c0:	f9001801 	str	x1, [x0, #48]
ffff00000008b3c4:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b3c8:	f9401800 	ldr	x0, [x0, #48]
ffff00000008b3cc:	d2a00801 	mov	x1, #0x400000              	// #4194304
ffff00000008b3d0:	f9008801 	str	x1, [x0, #272]
ffff00000008b3d4:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b3d8:	f9401800 	ldr	x0, [x0, #48]
ffff00000008b3dc:	d2a00c01 	mov	x1, #0x600000              	// #6291456
ffff00000008b3e0:	f9007c01 	str	x1, [x0, #248]
ffff00000008b3e4:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b3e8:	f9401800 	ldr	x0, [x0, #48]
ffff00000008b3ec:	f9008c1f 	str	xzr, [x0, #280]
ffff00000008b3f0:	97fffb52 	bl	ffff00000008a138 <kalloc>
ffff00000008b3f4:	aa0003e1 	mov	x1, x0
ffff00000008b3f8:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b3fc:	f9001001 	str	x1, [x0, #32]
ffff00000008b400:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b404:	f9401000 	ldr	x0, [x0, #32]
ffff00000008b408:	f100001f 	cmp	x0, #0x0
ffff00000008b40c:	540000a1 	b.ne	ffff00000008b420 <alloc_new_process+0x15c>  // b.any
ffff00000008b410:	d2800e21 	mov	x1, #0x71                  	// #113
ffff00000008b414:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b418:	91076000 	add	x0, x0, #0x1d8
ffff00000008b41c:	97ffd636 	bl	ffff000000080cf4 <error_check>
ffff00000008b420:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b424:	f9401000 	ldr	x0, [x0, #32]
ffff00000008b428:	52a00402 	mov	w2, #0x200000              	// #2097152
ffff00000008b42c:	52800001 	mov	w1, #0x0                   	// #0
ffff00000008b430:	97ffd359 	bl	ffff000000080194 <memset>
ffff00000008b434:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b438:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008b43c:	d65f03c0 	ret

ffff00000008b440 <init_user_process>:
ffff00000008b440:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008b444:	910003fd 	mov	x29, sp
ffff00000008b448:	97ffff9f 	bl	ffff00000008b2c4 <alloc_new_process>
ffff00000008b44c:	f90017e0 	str	x0, [sp, #40]
ffff00000008b450:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b454:	f100001f 	cmp	x0, #0x0
ffff00000008b458:	540000a1 	b.ne	ffff00000008b46c <init_user_process+0x2c>  // b.any
ffff00000008b45c:	d2800fc1 	mov	x1, #0x7e                  	// #126
ffff00000008b460:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b464:	91076000 	add	x0, x0, #0x1d8
ffff00000008b468:	97ffd623 	bl	ffff000000080cf4 <error_check>
ffff00000008b46c:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b470:	f9401002 	ldr	x2, [x0, #32]
ffff00000008b474:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b478:	9107a001 	add	x1, x0, #0x1e8
ffff00000008b47c:	aa0203e0 	mov	x0, x2
ffff00000008b480:	97fffd09 	bl	ffff00000008a8a4 <setup_uvm>
ffff00000008b484:	12001c00 	and	w0, w0, #0xff
ffff00000008b488:	52000000 	eor	w0, w0, #0x1
ffff00000008b48c:	12001c00 	and	w0, w0, #0xff
ffff00000008b490:	12000000 	and	w0, w0, #0x1
ffff00000008b494:	7100001f 	cmp	w0, #0x0
ffff00000008b498:	540000a0 	b.eq	ffff00000008b4ac <init_user_process+0x6c>  // b.none
ffff00000008b49c:	d2801001 	mov	x1, #0x80                  	// #128
ffff00000008b4a0:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b4a4:	91076000 	add	x0, x0, #0x1d8
ffff00000008b4a8:	97ffd613 	bl	ffff000000080cf4 <error_check>
ffff00000008b4ac:	97ffff12 	bl	ffff00000008b0f4 <get_pc>
ffff00000008b4b0:	f90013e0 	str	x0, [sp, #32]
ffff00000008b4b4:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008b4b8:	91002000 	add	x0, x0, #0x8
ffff00000008b4bc:	f9000fe0 	str	x0, [sp, #24]
ffff00000008b4c0:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b4c4:	52800061 	mov	w1, #0x3                   	// #3
ffff00000008b4c8:	b9000c01 	str	w1, [x0, #12]
ffff00000008b4cc:	f94017e1 	ldr	x1, [sp, #40]
ffff00000008b4d0:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b4d4:	97ffd354 	bl	ffff000000080224 <append_list_tail>
ffff00000008b4d8:	d503201f 	nop
ffff00000008b4dc:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff00000008b4e0:	d65f03c0 	ret

ffff00000008b4e4 <alloc_new_process2>:
ffff00000008b4e4:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008b4e8:	910003fd 	mov	x29, sp
ffff00000008b4ec:	f9000fe0 	str	x0, [sp, #24]
ffff00000008b4f0:	97ffff04 	bl	ffff00000008b100 <find_unused_process>
ffff00000008b4f4:	f90017e0 	str	x0, [sp, #40]
ffff00000008b4f8:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b4fc:	f100001f 	cmp	x0, #0x0
ffff00000008b500:	540000a1 	b.ne	ffff00000008b514 <alloc_new_process2+0x30>  // b.any
ffff00000008b504:	d28011c1 	mov	x1, #0x8e                  	// #142
ffff00000008b508:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b50c:	91076000 	add	x0, x0, #0x1d8
ffff00000008b510:	97ffd5f9 	bl	ffff000000080cf4 <error_check>
ffff00000008b514:	97fffb09 	bl	ffff00000008a138 <kalloc>
ffff00000008b518:	aa0003e1 	mov	x1, x0
ffff00000008b51c:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b520:	f9001401 	str	x1, [x0, #40]
ffff00000008b524:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b528:	f9401400 	ldr	x0, [x0, #40]
ffff00000008b52c:	f100001f 	cmp	x0, #0x0
ffff00000008b530:	540000a1 	b.ne	ffff00000008b544 <alloc_new_process2+0x60>  // b.any
ffff00000008b534:	d2801241 	mov	x1, #0x92                  	// #146
ffff00000008b538:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b53c:	91076000 	add	x0, x0, #0x1d8
ffff00000008b540:	97ffd5ed 	bl	ffff000000080cf4 <error_check>
ffff00000008b544:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b548:	f9401400 	ldr	x0, [x0, #40]
ffff00000008b54c:	52a00402 	mov	w2, #0x200000              	// #2097152
ffff00000008b550:	52800001 	mov	w1, #0x0                   	// #0
ffff00000008b554:	97ffd310 	bl	ffff000000080194 <memset>
ffff00000008b558:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b55c:	52800021 	mov	w1, #0x1                   	// #1
ffff00000008b560:	b9000c01 	str	w1, [x0, #12]
ffff00000008b564:	d0000000 	adrp	x0, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff00000008b568:	910ae000 	add	x0, x0, #0x2b8
ffff00000008b56c:	b9400000 	ldr	w0, [x0]
ffff00000008b570:	11000402 	add	w2, w0, #0x1
ffff00000008b574:	d0000001 	adrp	x1, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff00000008b578:	910ae021 	add	x1, x1, #0x2b8
ffff00000008b57c:	b9000022 	str	w2, [x1]
ffff00000008b580:	f94017e1 	ldr	x1, [sp, #40]
ffff00000008b584:	b9000820 	str	w0, [x1, #8]
ffff00000008b588:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b58c:	f9401401 	ldr	x1, [x0, #40]
ffff00000008b590:	d29fd000 	mov	x0, #0xfe80                	// #65152
ffff00000008b594:	f2a003e0 	movk	x0, #0x1f, lsl #16
ffff00000008b598:	8b000021 	add	x1, x1, x0
ffff00000008b59c:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b5a0:	f9000c01 	str	x1, [x0, #24]
ffff00000008b5a4:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b5a8:	f9400c00 	ldr	x0, [x0, #24]
ffff00000008b5ac:	91016000 	add	x0, x0, #0x58
ffff00000008b5b0:	aa0003e1 	mov	x1, x0
ffff00000008b5b4:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b5b8:	f9000020 	str	x0, [x1]
ffff00000008b5bc:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b5c0:	f9401401 	ldr	x1, [x0, #40]
ffff00000008b5c4:	d29fdc00 	mov	x0, #0xfee0                	// #65248
ffff00000008b5c8:	f2a003e0 	movk	x0, #0x1f, lsl #16
ffff00000008b5cc:	8b000020 	add	x0, x1, x0
ffff00000008b5d0:	aa0003e1 	mov	x1, x0
ffff00000008b5d4:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b5d8:	f9001801 	str	x1, [x0, #48]
ffff00000008b5dc:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b5e0:	f9401800 	ldr	x0, [x0, #48]
ffff00000008b5e4:	52802402 	mov	w2, #0x120                 	// #288
ffff00000008b5e8:	52800001 	mov	w1, #0x0                   	// #0
ffff00000008b5ec:	97ffd2ea 	bl	ffff000000080194 <memset>
ffff00000008b5f0:	d0000000 	adrp	x0, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff00000008b5f4:	910b4000 	add	x0, x0, #0x2d0
ffff00000008b5f8:	f9400001 	ldr	x1, [x0]
ffff00000008b5fc:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b600:	f9001001 	str	x1, [x0, #32]
ffff00000008b604:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b608:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff00000008b60c:	d65f03c0 	ret

ffff00000008b610 <create_kernel_process>:
ffff00000008b610:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff00000008b614:	910003fd 	mov	x29, sp
ffff00000008b618:	f9000fe0 	str	x0, [sp, #24]
ffff00000008b61c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b620:	97ffffb1 	bl	ffff00000008b4e4 <alloc_new_process2>
ffff00000008b624:	f9001fe0 	str	x0, [sp, #56]
ffff00000008b628:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008b62c:	f100001f 	cmp	x0, #0x0
ffff00000008b630:	540000a1 	b.ne	ffff00000008b644 <create_kernel_process+0x34>  // b.any
ffff00000008b634:	d2801721 	mov	x1, #0xb9                  	// #185
ffff00000008b638:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b63c:	91076000 	add	x0, x0, #0x1d8
ffff00000008b640:	97ffd5ad 	bl	ffff000000080cf4 <error_check>
ffff00000008b644:	97fffeac 	bl	ffff00000008b0f4 <get_pc>
ffff00000008b648:	f9001be0 	str	x0, [sp, #48]
ffff00000008b64c:	f9401be0 	ldr	x0, [sp, #48]
ffff00000008b650:	91002000 	add	x0, x0, #0x8
ffff00000008b654:	f90017e0 	str	x0, [sp, #40]
ffff00000008b658:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008b65c:	52800061 	mov	w1, #0x3                   	// #3
ffff00000008b660:	b9000c01 	str	w1, [x0, #12]
ffff00000008b664:	f9401fe1 	ldr	x1, [sp, #56]
ffff00000008b668:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b66c:	97ffd2ee 	bl	ffff000000080224 <append_list_tail>
ffff00000008b670:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008b674:	f9401401 	ldr	x1, [x0, #40]
ffff00000008b678:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008b67c:	f9401800 	ldr	x0, [x0, #48]
ffff00000008b680:	aa0003e5 	mov	x5, x0
ffff00000008b684:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008b688:	f9400c02 	ldr	x2, [x0, #24]
ffff00000008b68c:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008b690:	f9401000 	ldr	x0, [x0, #32]
ffff00000008b694:	aa0003e4 	mov	x4, x0
ffff00000008b698:	aa0203e3 	mov	x3, x2
ffff00000008b69c:	aa0503e2 	mov	x2, x5
ffff00000008b6a0:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b6a4:	9107e000 	add	x0, x0, #0x1f8
ffff00000008b6a8:	97ffd4bd 	bl	ffff00000008099c <printk>
ffff00000008b6ac:	d503201f 	nop
ffff00000008b6b0:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff00000008b6b4:	d65f03c0 	ret

ffff00000008b6b8 <set_ttbr0>:
ffff00000008b6b8:	d10083ff 	sub	sp, sp, #0x20
ffff00000008b6bc:	f90007e0 	str	x0, [sp, #8]
ffff00000008b6c0:	f94007e1 	ldr	x1, [sp, #8]
ffff00000008b6c4:	d2e00020 	mov	x0, #0x1000000000000       	// #281474976710656
ffff00000008b6c8:	8b000020 	add	x0, x1, x0
ffff00000008b6cc:	f9000fe0 	str	x0, [sp, #24]
ffff00000008b6d0:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b6d4:	d5033b9f 	dsb	ish
ffff00000008b6d8:	d5182000 	msr	ttbr0_el1, x0
ffff00000008b6dc:	d508831f 	tlbi	vmalle1is
ffff00000008b6e0:	d5033b9f 	dsb	ish
ffff00000008b6e4:	d5033fdf 	isb
ffff00000008b6e8:	d503201f 	nop
ffff00000008b6ec:	910083ff 	add	sp, sp, #0x20
ffff00000008b6f0:	d65f03c0 	ret

ffff00000008b6f4 <move_to_user_mode>:
ffff00000008b6f4:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008b6f8:	910003fd 	mov	x29, sp
ffff00000008b6fc:	f9000fe0 	str	x0, [sp, #24]
ffff00000008b700:	97fffa8e 	bl	ffff00000008a138 <kalloc>
ffff00000008b704:	aa0003e1 	mov	x1, x0
ffff00000008b708:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b70c:	f9001001 	str	x1, [x0, #32]
ffff00000008b710:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b714:	f9401000 	ldr	x0, [x0, #32]
ffff00000008b718:	52a00402 	mov	w2, #0x200000              	// #2097152
ffff00000008b71c:	52800001 	mov	w1, #0x0                   	// #0
ffff00000008b720:	97ffd29d 	bl	ffff000000080194 <memset>
ffff00000008b724:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b728:	f9401400 	ldr	x0, [x0, #40]
ffff00000008b72c:	91480000 	add	x0, x0, #0x200, lsl #12
ffff00000008b730:	f90017e0 	str	x0, [sp, #40]
ffff00000008b734:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b738:	d1048000 	sub	x0, x0, #0x120
ffff00000008b73c:	aa0003e1 	mov	x1, x0
ffff00000008b740:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b744:	f9001801 	str	x1, [x0, #48]
ffff00000008b748:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b74c:	f9401800 	ldr	x0, [x0, #48]
ffff00000008b750:	52802402 	mov	w2, #0x120                 	// #288
ffff00000008b754:	52800001 	mov	w1, #0x0                   	// #0
ffff00000008b758:	97ffd28f 	bl	ffff000000080194 <memset>
ffff00000008b75c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b760:	f9401800 	ldr	x0, [x0, #48]
ffff00000008b764:	d2a00801 	mov	x1, #0x400000              	// #4194304
ffff00000008b768:	f9008801 	str	x1, [x0, #272]
ffff00000008b76c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b770:	f9401800 	ldr	x0, [x0, #48]
ffff00000008b774:	d2a00c01 	mov	x1, #0x600000              	// #6291456
ffff00000008b778:	f9007c01 	str	x1, [x0, #248]
ffff00000008b77c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b780:	f9401800 	ldr	x0, [x0, #48]
ffff00000008b784:	f9008c1f 	str	xzr, [x0, #280]
ffff00000008b788:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b78c:	f9401002 	ldr	x2, [x0, #32]
ffff00000008b790:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b794:	91088001 	add	x1, x0, #0x220
ffff00000008b798:	aa0203e0 	mov	x0, x2
ffff00000008b79c:	97fffc42 	bl	ffff00000008a8a4 <setup_uvm>
ffff00000008b7a0:	12001c00 	and	w0, w0, #0xff
ffff00000008b7a4:	52000000 	eor	w0, w0, #0x1
ffff00000008b7a8:	12001c00 	and	w0, w0, #0xff
ffff00000008b7ac:	12000000 	and	w0, w0, #0x1
ffff00000008b7b0:	7100001f 	cmp	w0, #0x0
ffff00000008b7b4:	540000a0 	b.eq	ffff00000008b7c8 <move_to_user_mode+0xd4>  // b.none
ffff00000008b7b8:	d2801d21 	mov	x1, #0xe9                  	// #233
ffff00000008b7bc:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b7c0:	91076000 	add	x0, x0, #0x1d8
ffff00000008b7c4:	97ffd54c 	bl	ffff000000080cf4 <error_check>
ffff00000008b7c8:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b7cc:	f9401000 	ldr	x0, [x0, #32]
ffff00000008b7d0:	97ffffba 	bl	ffff00000008b6b8 <set_ttbr0>
ffff00000008b7d4:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b7d8:	f9401800 	ldr	x0, [x0, #48]
ffff00000008b7dc:	97ffd801 	bl	ffff0000000817e0 <enter_user>

ffff00000008b7e0 <kthread1>:
ffff00000008b7e0:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffff00000008b7e4:	910003fd 	mov	x29, sp
ffff00000008b7e8:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b7ec:	9108c000 	add	x0, x0, #0x230
ffff00000008b7f0:	97ffd46b 	bl	ffff00000008099c <printk>
ffff00000008b7f4:	97fffe40 	bl	ffff00000008b0f4 <get_pc>
ffff00000008b7f8:	f9400000 	ldr	x0, [x0]
ffff00000008b7fc:	97ffffbe 	bl	ffff00000008b6f4 <move_to_user_mode>
ffff00000008b800:	d503201f 	nop
ffff00000008b804:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffff00000008b808:	d65f03c0 	ret

ffff00000008b80c <init_process>:
ffff00000008b80c:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffff00000008b810:	910003fd 	mov	x29, sp
ffff00000008b814:	97fffe61 	bl	ffff00000008b198 <init_idle_process>
ffff00000008b818:	97ffff0a 	bl	ffff00000008b440 <init_user_process>
ffff00000008b81c:	90000000 	adrp	x0, ffff00000008b000 <load_file+0x8>
ffff00000008b820:	911f8000 	add	x0, x0, #0x7e0
ffff00000008b824:	97ffff7b 	bl	ffff00000008b610 <create_kernel_process>
ffff00000008b828:	d503201f 	nop
ffff00000008b82c:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffff00000008b830:	d65f03c0 	ret

ffff00000008b834 <switch_process>:
ffff00000008b834:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008b838:	910003fd 	mov	x29, sp
ffff00000008b83c:	f9000fe0 	str	x0, [sp, #24]
ffff00000008b840:	f9000be1 	str	x1, [sp, #16]
ffff00000008b844:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008b848:	f9401000 	ldr	x0, [x0, #32]
ffff00000008b84c:	97fffc42 	bl	ffff00000008a954 <switch_vm>
ffff00000008b850:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008b854:	91006002 	add	x2, x0, #0x18
ffff00000008b858:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008b85c:	f9400c00 	ldr	x0, [x0, #24]
ffff00000008b860:	aa0003e1 	mov	x1, x0
ffff00000008b864:	aa0203e0 	mov	x0, x2
ffff00000008b868:	97ffd847 	bl	ffff000000081984 <swap>
ffff00000008b86c:	d503201f 	nop
ffff00000008b870:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008b874:	d65f03c0 	ret

ffff00000008b878 <dump_context>:
ffff00000008b878:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008b87c:	910003fd 	mov	x29, sp
ffff00000008b880:	f9000fe0 	str	x0, [sp, #24]
ffff00000008b884:	f9000be1 	str	x1, [sp, #16]
ffff00000008b888:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008b88c:	f100001f 	cmp	x0, #0x0
ffff00000008b890:	540000c1 	b.ne	ffff00000008b8a8 <dump_context+0x30>  // b.any
ffff00000008b894:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008b898:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b89c:	91094000 	add	x0, x0, #0x250
ffff00000008b8a0:	97ffd43f 	bl	ffff00000008099c <printk>
ffff00000008b8a4:	1400007c 	b	ffff00000008ba94 <dump_context+0x21c>
ffff00000008b8a8:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008b8ac:	f9400c00 	ldr	x0, [x0, #24]
ffff00000008b8b0:	f90017e0 	str	x0, [sp, #40]
ffff00000008b8b4:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008b8b8:	b9400800 	ldr	w0, [x0, #8]
ffff00000008b8bc:	f9400be3 	ldr	x3, [sp, #16]
ffff00000008b8c0:	2a0003e2 	mov	w2, w0
ffff00000008b8c4:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008b8c8:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b8cc:	9109a000 	add	x0, x0, #0x268
ffff00000008b8d0:	97ffd433 	bl	ffff00000008099c <printk>
ffff00000008b8d4:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008b8d8:	f9400c00 	ldr	x0, [x0, #24]
ffff00000008b8dc:	aa0003e1 	mov	x1, x0
ffff00000008b8e0:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b8e4:	910a0000 	add	x0, x0, #0x280
ffff00000008b8e8:	97ffd42d 	bl	ffff00000008099c <printk>
ffff00000008b8ec:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008b8f0:	f9401400 	ldr	x0, [x0, #40]
ffff00000008b8f4:	aa0003e1 	mov	x1, x0
ffff00000008b8f8:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b8fc:	910a6000 	add	x0, x0, #0x298
ffff00000008b900:	97ffd427 	bl	ffff00000008099c <printk>
ffff00000008b904:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008b908:	f9401400 	ldr	x0, [x0, #40]
ffff00000008b90c:	91480000 	add	x0, x0, #0x200, lsl #12
ffff00000008b910:	aa0003e1 	mov	x1, x0
ffff00000008b914:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b918:	910ac000 	add	x0, x0, #0x2b0
ffff00000008b91c:	97ffd420 	bl	ffff00000008099c <printk>
ffff00000008b920:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008b924:	f9400c00 	ldr	x0, [x0, #24]
ffff00000008b928:	d2800c02 	mov	x2, #0x60                  	// #96
ffff00000008b92c:	aa0003e1 	mov	x1, x0
ffff00000008b930:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b934:	910b2000 	add	x0, x0, #0x2c8
ffff00000008b938:	97ffd419 	bl	ffff00000008099c <printk>
ffff00000008b93c:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008b940:	f9401800 	ldr	x0, [x0, #48]
ffff00000008b944:	d2802402 	mov	x2, #0x120                 	// #288
ffff00000008b948:	aa0003e1 	mov	x1, x0
ffff00000008b94c:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b950:	910ba000 	add	x0, x0, #0x2e8
ffff00000008b954:	97ffd412 	bl	ffff00000008099c <printk>
ffff00000008b958:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b95c:	f100001f 	cmp	x0, #0x0
ffff00000008b960:	540000a1 	b.ne	ffff00000008b974 <dump_context+0xfc>  // b.any
ffff00000008b964:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b968:	910c2000 	add	x0, x0, #0x308
ffff00000008b96c:	97ffd40c 	bl	ffff00000008099c <printk>
ffff00000008b970:	14000049 	b	ffff00000008ba94 <dump_context+0x21c>
ffff00000008b974:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b978:	f9400000 	ldr	x0, [x0]
ffff00000008b97c:	aa0003e1 	mov	x1, x0
ffff00000008b980:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b984:	910c8000 	add	x0, x0, #0x320
ffff00000008b988:	97ffd405 	bl	ffff00000008099c <printk>
ffff00000008b98c:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b990:	f9400400 	ldr	x0, [x0, #8]
ffff00000008b994:	aa0003e1 	mov	x1, x0
ffff00000008b998:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b99c:	910cc000 	add	x0, x0, #0x330
ffff00000008b9a0:	97ffd3ff 	bl	ffff00000008099c <printk>
ffff00000008b9a4:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b9a8:	f9400800 	ldr	x0, [x0, #16]
ffff00000008b9ac:	aa0003e1 	mov	x1, x0
ffff00000008b9b0:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b9b4:	910d0000 	add	x0, x0, #0x340
ffff00000008b9b8:	97ffd3f9 	bl	ffff00000008099c <printk>
ffff00000008b9bc:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b9c0:	f9400c00 	ldr	x0, [x0, #24]
ffff00000008b9c4:	aa0003e1 	mov	x1, x0
ffff00000008b9c8:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b9cc:	910d4000 	add	x0, x0, #0x350
ffff00000008b9d0:	97ffd3f3 	bl	ffff00000008099c <printk>
ffff00000008b9d4:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b9d8:	f9401000 	ldr	x0, [x0, #32]
ffff00000008b9dc:	aa0003e1 	mov	x1, x0
ffff00000008b9e0:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b9e4:	910d8000 	add	x0, x0, #0x360
ffff00000008b9e8:	97ffd3ed 	bl	ffff00000008099c <printk>
ffff00000008b9ec:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008b9f0:	f9401400 	ldr	x0, [x0, #40]
ffff00000008b9f4:	aa0003e1 	mov	x1, x0
ffff00000008b9f8:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008b9fc:	910dc000 	add	x0, x0, #0x370
ffff00000008ba00:	97ffd3e7 	bl	ffff00000008099c <printk>
ffff00000008ba04:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008ba08:	f9401800 	ldr	x0, [x0, #48]
ffff00000008ba0c:	aa0003e1 	mov	x1, x0
ffff00000008ba10:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008ba14:	910e0000 	add	x0, x0, #0x380
ffff00000008ba18:	97ffd3e1 	bl	ffff00000008099c <printk>
ffff00000008ba1c:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008ba20:	f9401c00 	ldr	x0, [x0, #56]
ffff00000008ba24:	aa0003e1 	mov	x1, x0
ffff00000008ba28:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008ba2c:	910e4000 	add	x0, x0, #0x390
ffff00000008ba30:	97ffd3db 	bl	ffff00000008099c <printk>
ffff00000008ba34:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008ba38:	f9402000 	ldr	x0, [x0, #64]
ffff00000008ba3c:	aa0003e1 	mov	x1, x0
ffff00000008ba40:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008ba44:	910e8000 	add	x0, x0, #0x3a0
ffff00000008ba48:	97ffd3d5 	bl	ffff00000008099c <printk>
ffff00000008ba4c:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008ba50:	f9402400 	ldr	x0, [x0, #72]
ffff00000008ba54:	aa0003e1 	mov	x1, x0
ffff00000008ba58:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008ba5c:	910ec000 	add	x0, x0, #0x3b0
ffff00000008ba60:	97ffd3cf 	bl	ffff00000008099c <printk>
ffff00000008ba64:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008ba68:	f9402800 	ldr	x0, [x0, #80]
ffff00000008ba6c:	aa0003e1 	mov	x1, x0
ffff00000008ba70:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008ba74:	910f0000 	add	x0, x0, #0x3c0
ffff00000008ba78:	97ffd3c9 	bl	ffff00000008099c <printk>
ffff00000008ba7c:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008ba80:	f9402c00 	ldr	x0, [x0, #88]
ffff00000008ba84:	aa0003e1 	mov	x1, x0
ffff00000008ba88:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008ba8c:	910f4000 	add	x0, x0, #0x3d0
ffff00000008ba90:	97ffd3c3 	bl	ffff00000008099c <printk>
ffff00000008ba94:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff00000008ba98:	d65f03c0 	ret

ffff00000008ba9c <dump_backtrace>:
ffff00000008ba9c:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff00000008baa0:	910003fd 	mov	x29, sp
ffff00000008baa4:	b90037ff 	str	wzr, [sp, #52]
ffff00000008baa8:	aa1d03e0 	mov	x0, x29
ffff00000008baac:	f9001fe0 	str	x0, [sp, #56]
ffff00000008bab0:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008bab4:	910f8000 	add	x0, x0, #0x3e0
ffff00000008bab8:	97ffd3b9 	bl	ffff00000008099c <printk>
ffff00000008babc:	14000018 	b	ffff00000008bb1c <dump_backtrace+0x80>
ffff00000008bac0:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008bac4:	f90017e0 	str	x0, [sp, #40]
ffff00000008bac8:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008bacc:	f9400000 	ldr	x0, [x0]
ffff00000008bad0:	f90013e0 	str	x0, [sp, #32]
ffff00000008bad4:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008bad8:	f9400400 	ldr	x0, [x0, #8]
ffff00000008badc:	f9000fe0 	str	x0, [sp, #24]
ffff00000008bae0:	f9400fe3 	ldr	x3, [sp, #24]
ffff00000008bae4:	f9401fe2 	ldr	x2, [sp, #56]
ffff00000008bae8:	b94037e1 	ldr	w1, [sp, #52]
ffff00000008baec:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008baf0:	91100000 	add	x0, x0, #0x400
ffff00000008baf4:	97ffd3aa 	bl	ffff00000008099c <printk>
ffff00000008baf8:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008bafc:	94000013 	bl	ffff00000008bb48 <is_kernel_address>
ffff00000008bb00:	7100001f 	cmp	w0, #0x0
ffff00000008bb04:	540001a0 	b.eq	ffff00000008bb38 <dump_backtrace+0x9c>  // b.none
ffff00000008bb08:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008bb0c:	f9001fe0 	str	x0, [sp, #56]
ffff00000008bb10:	b94037e0 	ldr	w0, [sp, #52]
ffff00000008bb14:	11000400 	add	w0, w0, #0x1
ffff00000008bb18:	b90037e0 	str	w0, [sp, #52]
ffff00000008bb1c:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008bb20:	f100001f 	cmp	x0, #0x0
ffff00000008bb24:	540000c0 	b.eq	ffff00000008bb3c <dump_backtrace+0xa0>  // b.none
ffff00000008bb28:	b94037e0 	ldr	w0, [sp, #52]
ffff00000008bb2c:	71003c1f 	cmp	w0, #0xf
ffff00000008bb30:	54fffc8d 	b.le	ffff00000008bac0 <dump_backtrace+0x24>
ffff00000008bb34:	14000002 	b	ffff00000008bb3c <dump_backtrace+0xa0>
ffff00000008bb38:	d503201f 	nop
ffff00000008bb3c:	d503201f 	nop
ffff00000008bb40:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff00000008bb44:	d65f03c0 	ret

ffff00000008bb48 <is_kernel_address>:
ffff00000008bb48:	d10043ff 	sub	sp, sp, #0x10
ffff00000008bb4c:	f90007e0 	str	x0, [sp, #8]
ffff00000008bb50:	f94007e0 	ldr	x0, [sp, #8]
ffff00000008bb54:	92503c01 	and	x1, x0, #0xffff000000000000
ffff00000008bb58:	d2ffffe0 	mov	x0, #0xffff000000000000    	// #-281474976710656
ffff00000008bb5c:	eb00003f 	cmp	x1, x0
ffff00000008bb60:	1a9f17e0 	cset	w0, eq	// eq = none
ffff00000008bb64:	12001c00 	and	w0, w0, #0xff
ffff00000008bb68:	910043ff 	add	sp, sp, #0x10
ffff00000008bb6c:	d65f03c0 	ret

ffff00000008bb70 <schedule>:
ffff00000008bb70:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008bb74:	910003fd 	mov	x29, sp
ffff00000008bb78:	97fffd5f 	bl	ffff00000008b0f4 <get_pc>
ffff00000008bb7c:	f90013e0 	str	x0, [sp, #32]
ffff00000008bb80:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008bb84:	91002000 	add	x0, x0, #0x8
ffff00000008bb88:	f9000fe0 	str	x0, [sp, #24]
ffff00000008bb8c:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008bb90:	f9400000 	ldr	x0, [x0]
ffff00000008bb94:	f9000be0 	str	x0, [sp, #16]
ffff00000008bb98:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008bb9c:	97ffd1da 	bl	ffff000000080304 <is_list_empty>
ffff00000008bba0:	12001c00 	and	w0, w0, #0xff
ffff00000008bba4:	12000000 	and	w0, w0, #0x1
ffff00000008bba8:	7100001f 	cmp	w0, #0x0
ffff00000008bbac:	540000a0 	b.eq	ffff00000008bbc0 <schedule+0x50>  // b.none
ffff00000008bbb0:	d0000000 	adrp	x0, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff00000008bbb4:	910ba000 	add	x0, x0, #0x2e8
ffff00000008bbb8:	f90017e0 	str	x0, [sp, #40]
ffff00000008bbbc:	14000004 	b	ffff00000008bbcc <schedule+0x5c>
ffff00000008bbc0:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008bbc4:	97ffd1b5 	bl	ffff000000080298 <remove_list_head>
ffff00000008bbc8:	f90017e0 	str	x0, [sp, #40]
ffff00000008bbcc:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008bbd0:	52800041 	mov	w1, #0x2                   	// #2
ffff00000008bbd4:	b9000c01 	str	w1, [x0, #12]
ffff00000008bbd8:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008bbdc:	f94017e1 	ldr	x1, [sp, #40]
ffff00000008bbe0:	f9000001 	str	x1, [x0]
ffff00000008bbe4:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008bbe8:	91106000 	add	x0, x0, #0x418
ffff00000008bbec:	97ffd36c 	bl	ffff00000008099c <printk>
ffff00000008bbf0:	f9400be1 	ldr	x1, [sp, #16]
ffff00000008bbf4:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008bbf8:	9110c000 	add	x0, x0, #0x430
ffff00000008bbfc:	97ffff1f 	bl	ffff00000008b878 <dump_context>
ffff00000008bc00:	97ffffa7 	bl	ffff00000008ba9c <dump_backtrace>
ffff00000008bc04:	f94017e1 	ldr	x1, [sp, #40]
ffff00000008bc08:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008bc0c:	97ffff0a 	bl	ffff00000008b834 <switch_process>
ffff00000008bc10:	d503201f 	nop
ffff00000008bc14:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff00000008bc18:	d65f03c0 	ret

ffff00000008bc1c <yield>:
ffff00000008bc1c:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008bc20:	910003fd 	mov	x29, sp
ffff00000008bc24:	97fffd34 	bl	ffff00000008b0f4 <get_pc>
ffff00000008bc28:	f90017e0 	str	x0, [sp, #40]
ffff00000008bc2c:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008bc30:	91002000 	add	x0, x0, #0x8
ffff00000008bc34:	f90013e0 	str	x0, [sp, #32]
ffff00000008bc38:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008bc3c:	97ffd1b2 	bl	ffff000000080304 <is_list_empty>
ffff00000008bc40:	12001c00 	and	w0, w0, #0xff
ffff00000008bc44:	12000000 	and	w0, w0, #0x1
ffff00000008bc48:	7100001f 	cmp	w0, #0x0
ffff00000008bc4c:	54000201 	b.ne	ffff00000008bc8c <yield+0x70>  // b.any
ffff00000008bc50:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008bc54:	f9400000 	ldr	x0, [x0]
ffff00000008bc58:	f9000fe0 	str	x0, [sp, #24]
ffff00000008bc5c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008bc60:	52800061 	mov	w1, #0x3                   	// #3
ffff00000008bc64:	b9000c01 	str	w1, [x0, #12]
ffff00000008bc68:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008bc6c:	b9400800 	ldr	w0, [x0, #8]
ffff00000008bc70:	7100001f 	cmp	w0, #0x0
ffff00000008bc74:	54000080 	b.eq	ffff00000008bc84 <yield+0x68>  // b.none
ffff00000008bc78:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008bc7c:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008bc80:	97ffd169 	bl	ffff000000080224 <append_list_tail>
ffff00000008bc84:	97ffffbb 	bl	ffff00000008bb70 <schedule>
ffff00000008bc88:	14000002 	b	ffff00000008bc90 <yield+0x74>
ffff00000008bc8c:	d503201f 	nop
ffff00000008bc90:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff00000008bc94:	d65f03c0 	ret

ffff00000008bc98 <sleep>:
ffff00000008bc98:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffff00000008bc9c:	910003fd 	mov	x29, sp
ffff00000008bca0:	b9001fe0 	str	w0, [sp, #28]
ffff00000008bca4:	97fffd14 	bl	ffff00000008b0f4 <get_pc>
ffff00000008bca8:	f90017e0 	str	x0, [sp, #40]
ffff00000008bcac:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008bcb0:	f9400000 	ldr	x0, [x0]
ffff00000008bcb4:	f90013e0 	str	x0, [sp, #32]
ffff00000008bcb8:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008bcbc:	52800081 	mov	w1, #0x4                   	// #4
ffff00000008bcc0:	b9000c01 	str	w1, [x0, #12]
ffff00000008bcc4:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008bcc8:	b9401fe1 	ldr	w1, [sp, #28]
ffff00000008bccc:	b9001001 	str	w1, [x0, #16]
ffff00000008bcd0:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008bcd4:	91006000 	add	x0, x0, #0x18
ffff00000008bcd8:	f94013e1 	ldr	x1, [sp, #32]
ffff00000008bcdc:	97ffd152 	bl	ffff000000080224 <append_list_tail>
ffff00000008bce0:	97ffffa4 	bl	ffff00000008bb70 <schedule>
ffff00000008bce4:	d503201f 	nop
ffff00000008bce8:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffff00000008bcec:	d65f03c0 	ret

ffff00000008bcf0 <wake_up>:
ffff00000008bcf0:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff00000008bcf4:	910003fd 	mov	x29, sp
ffff00000008bcf8:	b9001fe0 	str	w0, [sp, #28]
ffff00000008bcfc:	97fffcfe 	bl	ffff00000008b0f4 <get_pc>
ffff00000008bd00:	f9001be0 	str	x0, [sp, #48]
ffff00000008bd04:	f9401be0 	ldr	x0, [sp, #48]
ffff00000008bd08:	91002000 	add	x0, x0, #0x8
ffff00000008bd0c:	f90017e0 	str	x0, [sp, #40]
ffff00000008bd10:	f9401be0 	ldr	x0, [sp, #48]
ffff00000008bd14:	91006000 	add	x0, x0, #0x18
ffff00000008bd18:	f90013e0 	str	x0, [sp, #32]
ffff00000008bd1c:	b9401fe1 	ldr	w1, [sp, #28]
ffff00000008bd20:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008bd24:	97ffd181 	bl	ffff000000080328 <remove_list>
ffff00000008bd28:	f9001fe0 	str	x0, [sp, #56]
ffff00000008bd2c:	1400000b 	b	ffff00000008bd58 <wake_up+0x68>
ffff00000008bd30:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008bd34:	52800061 	mov	w1, #0x3                   	// #3
ffff00000008bd38:	b9000c01 	str	w1, [x0, #12]
ffff00000008bd3c:	f9401fe1 	ldr	x1, [sp, #56]
ffff00000008bd40:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008bd44:	97ffd138 	bl	ffff000000080224 <append_list_tail>
ffff00000008bd48:	b9401fe1 	ldr	w1, [sp, #28]
ffff00000008bd4c:	f94013e0 	ldr	x0, [sp, #32]
ffff00000008bd50:	97ffd176 	bl	ffff000000080328 <remove_list>
ffff00000008bd54:	f9001fe0 	str	x0, [sp, #56]
ffff00000008bd58:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008bd5c:	f100001f 	cmp	x0, #0x0
ffff00000008bd60:	54fffe81 	b.ne	ffff00000008bd30 <wake_up+0x40>  // b.any
ffff00000008bd64:	d503201f 	nop
ffff00000008bd68:	d503201f 	nop
ffff00000008bd6c:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff00000008bd70:	d65f03c0 	ret

ffff00000008bd74 <exit>:
ffff00000008bd74:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008bd78:	910003fd 	mov	x29, sp
ffff00000008bd7c:	97fffcde 	bl	ffff00000008b0f4 <get_pc>
ffff00000008bd80:	f9000fe0 	str	x0, [sp, #24]
ffff00000008bd84:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008bd88:	f9400000 	ldr	x0, [x0]
ffff00000008bd8c:	f9000be0 	str	x0, [sp, #16]
ffff00000008bd90:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008bd94:	528000a1 	mov	w1, #0x5                   	// #5
ffff00000008bd98:	b9000c01 	str	w1, [x0, #12]
ffff00000008bd9c:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008bda0:	b9400801 	ldr	w1, [x0, #8]
ffff00000008bda4:	f9400be0 	ldr	x0, [sp, #16]
ffff00000008bda8:	b9001001 	str	w1, [x0, #16]
ffff00000008bdac:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008bdb0:	9100a000 	add	x0, x0, #0x28
ffff00000008bdb4:	f9400be1 	ldr	x1, [sp, #16]
ffff00000008bdb8:	97ffd11b 	bl	ffff000000080224 <append_list_tail>
ffff00000008bdbc:	12800040 	mov	w0, #0xfffffffd            	// #-3
ffff00000008bdc0:	97ffffcc 	bl	ffff00000008bcf0 <wake_up>
ffff00000008bdc4:	97ffff6b 	bl	ffff00000008bb70 <schedule>
ffff00000008bdc8:	d503201f 	nop
ffff00000008bdcc:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008bdd0:	d65f03c0 	ret

ffff00000008bdd4 <wait>:
ffff00000008bdd4:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff00000008bdd8:	910003fd 	mov	x29, sp
ffff00000008bddc:	b9001fe0 	str	w0, [sp, #28]
ffff00000008bde0:	97fffcc5 	bl	ffff00000008b0f4 <get_pc>
ffff00000008bde4:	f9001fe0 	str	x0, [sp, #56]
ffff00000008bde8:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008bdec:	9100a000 	add	x0, x0, #0x28
ffff00000008bdf0:	f9001be0 	str	x0, [sp, #48]
ffff00000008bdf4:	f9401be0 	ldr	x0, [sp, #48]
ffff00000008bdf8:	97ffd143 	bl	ffff000000080304 <is_list_empty>
ffff00000008bdfc:	12001c00 	and	w0, w0, #0xff
ffff00000008be00:	52000000 	eor	w0, w0, #0x1
ffff00000008be04:	12001c00 	and	w0, w0, #0xff
ffff00000008be08:	12000000 	and	w0, w0, #0x1
ffff00000008be0c:	7100001f 	cmp	w0, #0x0
ffff00000008be10:	54000360 	b.eq	ffff00000008be7c <wait+0xa8>  // b.none
ffff00000008be14:	b9401fe1 	ldr	w1, [sp, #28]
ffff00000008be18:	f9401be0 	ldr	x0, [sp, #48]
ffff00000008be1c:	97ffd143 	bl	ffff000000080328 <remove_list>
ffff00000008be20:	f90017e0 	str	x0, [sp, #40]
ffff00000008be24:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008be28:	f100001f 	cmp	x0, #0x0
ffff00000008be2c:	54000280 	b.eq	ffff00000008be7c <wait+0xa8>  // b.none
ffff00000008be30:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008be34:	b9400c00 	ldr	w0, [x0, #12]
ffff00000008be38:	7100141f 	cmp	w0, #0x5
ffff00000008be3c:	540000a0 	b.eq	ffff00000008be50 <wait+0x7c>  // b.none
ffff00000008be40:	d2803c81 	mov	x1, #0x1e4                 	// #484
ffff00000008be44:	b0000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008be48:	91076000 	add	x0, x0, #0x1d8
ffff00000008be4c:	97ffd3aa 	bl	ffff000000080cf4 <error_check>
ffff00000008be50:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008be54:	f9401400 	ldr	x0, [x0, #40]
ffff00000008be58:	97fff88c 	bl	ffff00000008a088 <kfree>
ffff00000008be5c:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008be60:	f9401000 	ldr	x0, [x0, #32]
ffff00000008be64:	97fffa6e 	bl	ffff00000008a81c <free_vm>
ffff00000008be68:	52800702 	mov	w2, #0x38                  	// #56
ffff00000008be6c:	52800001 	mov	w1, #0x0                   	// #0
ffff00000008be70:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008be74:	97ffd0c8 	bl	ffff000000080194 <memset>
ffff00000008be78:	14000004 	b	ffff00000008be88 <wait+0xb4>
ffff00000008be7c:	12800040 	mov	w0, #0xfffffffd            	// #-3
ffff00000008be80:	97ffff86 	bl	ffff00000008bc98 <sleep>
ffff00000008be84:	17ffffdc 	b	ffff00000008bdf4 <wait+0x20>
ffff00000008be88:	d503201f 	nop
ffff00000008be8c:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff00000008be90:	d65f03c0 	ret

ffff00000008be94 <sys_write>:
ffff00000008be94:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008be98:	910003fd 	mov	x29, sp
ffff00000008be9c:	f9000fe0 	str	x0, [sp, #24]
ffff00000008bea0:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008bea4:	f9400000 	ldr	x0, [x0]
ffff00000008bea8:	aa0003e2 	mov	x2, x0
ffff00000008beac:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008beb0:	91002000 	add	x0, x0, #0x8
ffff00000008beb4:	f9400000 	ldr	x0, [x0]
ffff00000008beb8:	2a0003e1 	mov	w1, w0
ffff00000008bebc:	aa0203e0 	mov	x0, x2
ffff00000008bec0:	97ffd2a1 	bl	ffff000000080944 <write_console>
ffff00000008bec4:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008bec8:	91002000 	add	x0, x0, #0x8
ffff00000008becc:	f9400000 	ldr	x0, [x0]
ffff00000008bed0:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008bed4:	d65f03c0 	ret

ffff00000008bed8 <sys_sleep>:
ffff00000008bed8:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff00000008bedc:	910003fd 	mov	x29, sp
ffff00000008bee0:	f9000fe0 	str	x0, [sp, #24]
ffff00000008bee4:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008bee8:	f9400000 	ldr	x0, [x0]
ffff00000008beec:	f9001be0 	str	x0, [sp, #48]
ffff00000008bef0:	97ffd6c7 	bl	ffff000000081a0c <get_ticks>
ffff00000008bef4:	f9001fe0 	str	x0, [sp, #56]
ffff00000008bef8:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008befc:	f90017e0 	str	x0, [sp, #40]
ffff00000008bf00:	14000005 	b	ffff00000008bf14 <sys_sleep+0x3c>
ffff00000008bf04:	12800000 	mov	w0, #0xffffffff            	// #-1
ffff00000008bf08:	97ffff64 	bl	ffff00000008bc98 <sleep>
ffff00000008bf0c:	97ffd6c0 	bl	ffff000000081a0c <get_ticks>
ffff00000008bf10:	f9001fe0 	str	x0, [sp, #56]
ffff00000008bf14:	f9401fe1 	ldr	x1, [sp, #56]
ffff00000008bf18:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008bf1c:	cb000020 	sub	x0, x1, x0
ffff00000008bf20:	f9401be1 	ldr	x1, [sp, #48]
ffff00000008bf24:	eb00003f 	cmp	x1, x0
ffff00000008bf28:	54fffee8 	b.hi	ffff00000008bf04 <sys_sleep+0x2c>  // b.pmore
ffff00000008bf2c:	52800000 	mov	w0, #0x0                   	// #0
ffff00000008bf30:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff00000008bf34:	d65f03c0 	ret

ffff00000008bf38 <sys_exit>:
ffff00000008bf38:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008bf3c:	910003fd 	mov	x29, sp
ffff00000008bf40:	f9000fe0 	str	x0, [sp, #24]
ffff00000008bf44:	97ffff8c 	bl	ffff00000008bd74 <exit>
ffff00000008bf48:	52800000 	mov	w0, #0x0                   	// #0
ffff00000008bf4c:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008bf50:	d65f03c0 	ret

ffff00000008bf54 <sys_wait>:
ffff00000008bf54:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008bf58:	910003fd 	mov	x29, sp
ffff00000008bf5c:	f9000fe0 	str	x0, [sp, #24]
ffff00000008bf60:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008bf64:	f9400000 	ldr	x0, [x0]
ffff00000008bf68:	97ffff9b 	bl	ffff00000008bdd4 <wait>
ffff00000008bf6c:	52800000 	mov	w0, #0x0                   	// #0
ffff00000008bf70:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffff00000008bf74:	d65f03c0 	ret

ffff00000008bf78 <system_call>:
ffff00000008bf78:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff00000008bf7c:	910003fd 	mov	x29, sp
ffff00000008bf80:	f9000fe0 	str	x0, [sp, #24]
ffff00000008bf84:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008bf88:	f9402000 	ldr	x0, [x0, #64]
ffff00000008bf8c:	f9001fe0 	str	x0, [sp, #56]
ffff00000008bf90:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008bf94:	f9400000 	ldr	x0, [x0]
ffff00000008bf98:	f9001be0 	str	x0, [sp, #48]
ffff00000008bf9c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008bfa0:	f9400400 	ldr	x0, [x0, #8]
ffff00000008bfa4:	f90017e0 	str	x0, [sp, #40]
ffff00000008bfa8:	f9401be0 	ldr	x0, [sp, #48]
ffff00000008bfac:	f100001f 	cmp	x0, #0x0
ffff00000008bfb0:	540000eb 	b.lt	ffff00000008bfcc <system_call+0x54>  // b.tstop
ffff00000008bfb4:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008bfb8:	f100001f 	cmp	x0, #0x0
ffff00000008bfbc:	5400008b 	b.lt	ffff00000008bfcc <system_call+0x54>  // b.tstop
ffff00000008bfc0:	f9401fe0 	ldr	x0, [sp, #56]
ffff00000008bfc4:	f1000c1f 	cmp	x0, #0x3
ffff00000008bfc8:	540000ad 	b.le	ffff00000008bfdc <system_call+0x64>
ffff00000008bfcc:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008bfd0:	92800001 	mov	x1, #0xffffffffffffffff    	// #-1
ffff00000008bfd4:	f9000001 	str	x1, [x0]
ffff00000008bfd8:	1400000a 	b	ffff00000008c000 <system_call+0x88>
ffff00000008bfdc:	d0000000 	adrp	x0, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff00000008bfe0:	91154000 	add	x0, x0, #0x550
ffff00000008bfe4:	f9401fe1 	ldr	x1, [sp, #56]
ffff00000008bfe8:	f8617801 	ldr	x1, [x0, x1, lsl #3]
ffff00000008bfec:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008bff0:	d63f0020 	blr	x1
ffff00000008bff4:	93407c01 	sxtw	x1, w0
ffff00000008bff8:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008bffc:	f9000001 	str	x1, [x0]
ffff00000008c000:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff00000008c004:	d65f03c0 	ret

ffff00000008c008 <init_system_call>:
ffff00000008c008:	b0000000 	adrp	x0, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff00000008c00c:	91154000 	add	x0, x0, #0x550
ffff00000008c010:	f0ffffe1 	adrp	x1, ffff00000008b000 <load_file+0x8>
ffff00000008c014:	913a5021 	add	x1, x1, #0xe94
ffff00000008c018:	f9000001 	str	x1, [x0]
ffff00000008c01c:	b0000000 	adrp	x0, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff00000008c020:	91154000 	add	x0, x0, #0x550
ffff00000008c024:	f0ffffe1 	adrp	x1, ffff00000008b000 <load_file+0x8>
ffff00000008c028:	913b6021 	add	x1, x1, #0xed8
ffff00000008c02c:	f9000401 	str	x1, [x0, #8]
ffff00000008c030:	b0000000 	adrp	x0, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff00000008c034:	91154000 	add	x0, x0, #0x550
ffff00000008c038:	f0ffffe1 	adrp	x1, ffff00000008b000 <load_file+0x8>
ffff00000008c03c:	913ce021 	add	x1, x1, #0xf38
ffff00000008c040:	f9000801 	str	x1, [x0, #16]
ffff00000008c044:	b0000000 	adrp	x0, ffff00000008d000 <_binary_init_bin_start+0x490>
ffff00000008c048:	91154000 	add	x0, x0, #0x550
ffff00000008c04c:	f0ffffe1 	adrp	x1, ffff00000008b000 <load_file+0x8>
ffff00000008c050:	913d5021 	add	x1, x1, #0xf54
ffff00000008c054:	f9000c01 	str	x1, [x0, #24]
ffff00000008c058:	d503201f 	nop
ffff00000008c05c:	d65f03c0 	ret

Disassembly of section .rodata:

ffff00000008c060 <.rodata>:
ffff00000008c060:	6c6c6548 	ldnp	d8, d25, [x10, #-320]
ffff00000008c064:	52202c6f 	eor	w15, w3, #0xfff
ffff00000008c068:	62707361 	.inst	0x62707361 ; undefined
ffff00000008c06c:	79727265 	ldrh	w5, [x19, #6456]
ffff00000008c070:	0d697020 	.inst	0x0d697020 ; undefined
ffff00000008c074:	0000000a 	udf	#10
ffff00000008c078:	61206557 	.inst	0x61206557 ; undefined
ffff00000008c07c:	61206572 	.inst	0x61206572 ; undefined
ffff00000008c080:	4c452074 	.inst	0x4c452074 ; undefined
ffff00000008c084:	0d752520 	.inst	0x0d752520 ; undefined
ffff00000008c088:	0000000a 	udf	#10
ffff00000008c08c:	00000000 	udf	#0
ffff00000008c090:	00000a0d 	udf	#2573
ffff00000008c094:	00000000 	udf	#0
ffff00000008c098:	33323130 	.inst	0x33323130 ; undefined
ffff00000008c09c:	37363534 	tbnz	w20, #6, ffff000000088740 <pud_ttbr0+0x740>
ffff00000008c0a0:	42413938 	.inst	0x42413938 ; undefined
ffff00000008c0a4:	46454443 	.inst	0x46454443 ; undefined
ffff00000008c0a8:	33323130 	.inst	0x33323130 ; undefined
ffff00000008c0ac:	37363534 	tbnz	w20, #6, ffff000000088750 <pud_ttbr0+0x750>
ffff00000008c0b0:	00003938 	udf	#14648
ffff00000008c0b4:	00000000 	udf	#0
ffff00000008c0b8:	2d2d0a0d 	stp	s13, s2, [x16, #-152]
ffff00000008c0bc:	2d2d2d2d 	stp	s13, s11, [x9, #-152]
ffff00000008c0c0:	2d2d2d2d 	stp	s13, s11, [x9, #-152]
ffff00000008c0c4:	2d2d2d2d 	stp	s13, s11, [x9, #-152]
ffff00000008c0c8:	2d2d2d2d 	stp	s13, s11, [x9, #-152]
ffff00000008c0cc:	2d2d2d2d 	stp	s13, s11, [x9, #-152]
ffff00000008c0d0:	2d2d2d2d 	stp	s13, s11, [x9, #-152]
ffff00000008c0d4:	2d2d2d2d 	stp	s13, s11, [x9, #-152]
ffff00000008c0d8:	2d2d2d2d 	stp	s13, s11, [x9, #-152]
ffff00000008c0dc:	000a0d2d 	.inst	0x000a0d2d ; undefined
ffff00000008c0e0:	20202020 	.inst	0x20202020 ; undefined
ffff00000008c0e4:	20202020 	.inst	0x20202020 ; undefined
ffff00000008c0e8:	20202020 	.inst	0x20202020 ; undefined
ffff00000008c0ec:	20202020 	.inst	0x20202020 ; undefined
ffff00000008c0f0:	20202020 	.inst	0x20202020 ; undefined
ffff00000008c0f4:	4f525245 	.inst	0x4f525245 ; undefined
ffff00000008c0f8:	48432052 	ldxrh	w18, [x2]
ffff00000008c0fc:	004b4345 	.inst	0x004b4345 ; undefined
ffff00000008c100:	65737341 	fnmls	z1.h, p4/m, z26.h, z19.h
ffff00000008c104:	6f697472 	uqshl	v18.2d, v3.2d, #41
ffff00000008c108:	6146206e 	.inst	0x6146206e ; undefined
ffff00000008c10c:	64656c69 	.inst	0x64656c69 ; undefined
ffff00000008c110:	73255b20 	.inst	0x73255b20 ; undefined
ffff00000008c114:	7525203a 	cblt	w26, #10, ffff00000008bd18 <wake_up+0x28>
ffff00000008c118:	000a0d5d 	.inst	0x000a0d5d ; undefined
ffff00000008c11c:	00000000 	udf	#0
ffff00000008c120:	636e7973 	.inst	0x636e7973 ; undefined
ffff00000008c124:	72726520 	.inst	0x72726520 ; undefined
ffff00000008c128:	6120726f 	.inst	0x6120726f ; undefined
ffff00000008c12c:	78252074 	ldeorh	w5, w20, [x3]
ffff00000008c130:	7825203a 	ldeorh	w5, w26, [x1]
ffff00000008c134:	00000a0d 	udf	#2573
ffff00000008c138:	6e6b6e75 	umin	v21.8h, v19.8h, v11.8h
ffff00000008c13c:	206e776f 	.inst	0x206e776f ; undefined
ffff00000008c140:	0d717269 	.inst	0x0d717269 ; undefined
ffff00000008c144:	0000000a 	udf	#10
ffff00000008c148:	6e6b6e75 	umin	v21.8h, v19.8h, v11.8h
ffff00000008c14c:	206e776f 	.inst	0x206e776f ; undefined
ffff00000008c150:	65637865 	fnmls	z5.h, p6/m, z3.h, z3.h
ffff00000008c154:	6f697470 	uqshl	v16.2d, v3.2d, #41
ffff00000008c158:	000a0d6e 	.inst	0x000a0d6e ; undefined
ffff00000008c15c:	00000000 	udf	#0
ffff00000008c160:	6f6d656d 	sqshlu	v13.2d, v11.2d, #45
ffff00000008c164:	632e7972 	.inst	0x632e7972 ; undefined
	...
ffff00000008c170:	62206425 	.inst	0x62206425 ; undefined
ffff00000008c174:	20657361 	.inst	0x20657361 ; undefined
ffff00000008c178:	25207369 	.inst	0x25207369 ; undefined
ffff00000008c17c:	0a0d2078 	and	w24, w3, w13, lsl #8
	...
ffff00000008c188:	6f6d656d 	sqshlu	v13.2d, v11.2d, #45
ffff00000008c18c:	73207972 	.inst	0x73207972 ; undefined
ffff00000008c190:	20657a69 	.inst	0x20657a69 ; undefined
ffff00000008c194:	25207369 	.inst	0x25207369 ; undefined
ffff00000008c198:	0a0d2075 	and	w21, w3, w13, lsl #8
ffff00000008c19c:	00000000 	udf	#0
ffff00000008c1a0:	656c6966 	fnmls	z6.h, p2/m, z11.h, z12.h
ffff00000008c1a4:	0000632e 	udf	#25390
ffff00000008c1a8:	00202020 	.inst	0x00202020 ; undefined
ffff00000008c1ac:	00000000 	udf	#0
ffff00000008c1b0:	61766e69 	.inst	0x61766e69 ; undefined
ffff00000008c1b4:	2064696c 	.inst	0x2064696c ; undefined
ffff00000008c1b8:	6e676973 	.inst	0x6e676973 ; undefined
ffff00000008c1bc:	72757461 	.inst	0x72757461 ; undefined
ffff00000008c1c0:	00000a65 	udf	#2661
ffff00000008c1c4:	00000000 	udf	#0
ffff00000008c1c8:	656c6469 	fnmls	z9.h, p1/m, z3.h, z12.h
ffff00000008c1cc:	7268745f 	.inst	0x7268745f ; undefined
ffff00000008c1d0:	0d646165 	.inst	0x0d646165 ; undefined
ffff00000008c1d4:	0000000a 	udf	#10
ffff00000008c1d8:	636f7270 	.inst	0x636f7270 ; undefined
ffff00000008c1dc:	2e737365 	uabdl	v5.4s, v27.4h, v19.4h
ffff00000008c1e0:	00000063 	udf	#99
ffff00000008c1e4:	00000000 	udf	#0
ffff00000008c1e8:	54494e49 	b.ls	ffff00000011ebb0 <bss_end+0x91610>  // b.plast
ffff00000008c1ec:	4e49422e 	.inst	0x4e49422e ; undefined
	...
ffff00000008c1f8:	72657375 	.inst	0x72657375 ; undefined
ffff00000008c1fc:	73203a31 	.inst	0x73203a31 ; undefined
ffff00000008c200:	6b636174 	.inst	0x6b636174 ; undefined
ffff00000008c204:	2078253d 	.inst	0x2078253d ; undefined
ffff00000008c208:	253d6674 	whilelt	pn12.b, x19, x29, vlx4
ffff00000008c20c:	74632078 	cbhs	w24, w3, ffff00000008be18 <wait+0x44>
ffff00000008c210:	78253d78 	.inst	0x78253d78 ; undefined
ffff00000008c214:	64677020 	.inst	0x64677020 ; undefined
ffff00000008c218:	0a78253d 	bic	w29, w9, w24, lsr #9
ffff00000008c21c:	00000000 	udf	#0
ffff00000008c220:	52455355 	.inst	0x52455355 ; undefined
ffff00000008c224:	4e49422e 	.inst	0x4e49422e ; undefined
	...
ffff00000008c230:	72657375 	.inst	0x72657375 ; undefined
ffff00000008c234:	73202032 	.inst	0x73202032 ; undefined
ffff00000008c238:	74726174 	.inst	0x74726174 ; undefined
ffff00000008c23c:	206e6920 	.inst	0x206e6920 ; undefined
ffff00000008c240:	6e72656b 	umax	v11.8h, v11.8h, v18.8h
ffff00000008c244:	6d206c65 	stp	d5, d27, [x3, #-512]
ffff00000008c248:	0a65646f 	bic	w15, w3, w5, lsr #25
ffff00000008c24c:	00000000 	udf	#0
ffff00000008c250:	5d73255b 	.inst	0x5d73255b ; undefined
ffff00000008c254:	6f727020 	fcmla	v0.8h, v1.8h, v18.h[1], #270
ffff00000008c258:	73736563 	.inst	0x73736563 ; undefined
ffff00000008c25c:	4e203d20 	cmge	v0.16b, v9.16b, v0.16b
ffff00000008c260:	0a4c4c55 	and	w21, w2, w12, lsr #19
ffff00000008c264:	00000000 	udf	#0
ffff00000008c268:	5d73255b 	.inst	0x5d73255b ; undefined
ffff00000008c26c:	64697020 	.inst	0x64697020 ; undefined
ffff00000008c270:	2064253d 	.inst	0x2064253d ; undefined
ffff00000008c274:	636f7270 	.inst	0x636f7270 ; undefined
ffff00000008c278:	0a78253d 	bic	w29, w9, w24, lsr #9
ffff00000008c27c:	00000000 	udf	#0
ffff00000008c280:	6e6f6320 	rsubhn2	v0.8h, v25.4s, v15.4s
ffff00000008c284:	74786574 	.inst	0x74786574 ; undefined
ffff00000008c288:	64646120 	.inst	0x64646120 ; undefined
ffff00000008c28c:	203d2072 	.inst	0x203d2072 ; undefined
ffff00000008c290:	78257830 	strh	w16, [x1, x5, lsl #1]
ffff00000008c294:	0000000a 	udf	#10
ffff00000008c298:	61747320 	.inst	0x61747320 ; undefined
ffff00000008c29c:	62206b63 	.inst	0x62206b63 ; undefined
ffff00000008c2a0:	20657361 	.inst	0x20657361 ; undefined
ffff00000008c2a4:	7825203d 	ldeorh	w5, w29, [x1]
ffff00000008c2a8:	0000000a 	udf	#10
ffff00000008c2ac:	00000000 	udf	#0
ffff00000008c2b0:	61747320 	.inst	0x61747320 ; undefined
ffff00000008c2b4:	74206b63 	.inst	0x74206b63 ; undefined
ffff00000008c2b8:	2020706f 	.inst	0x2020706f ; undefined
ffff00000008c2bc:	7825203d 	ldeorh	w5, w29, [x1]
ffff00000008c2c0:	0000000a 	udf	#10
ffff00000008c2c4:	00000000 	udf	#0
ffff00000008c2c8:	6e6f6320 	rsubhn2	v0.8h, v25.4s, v15.4s
ffff00000008c2cc:	74786574 	.inst	0x74786574 ; undefined
ffff00000008c2d0:	20202020 	.inst	0x20202020 ; undefined
ffff00000008c2d4:	7825203d 	ldeorh	w5, w29, [x1]
ffff00000008c2d8:	69732820 	ldpsw	x0, x10, [x1, #-104]
ffff00000008c2dc:	253d657a 	whilele	pn10.b, x11, x29, vlx4
ffff00000008c2e0:	000a2964 	.inst	0x000a2964 ; undefined
ffff00000008c2e4:	00000000 	udf	#0
ffff00000008c2e8:	61727420 	.inst	0x61727420 ; undefined
ffff00000008c2ec:	61726670 	.inst	0x61726670 ; undefined
ffff00000008c2f0:	2020656d 	.inst	0x2020656d ; undefined
ffff00000008c2f4:	7825203d 	ldeorh	w5, w29, [x1]
ffff00000008c2f8:	69732820 	ldpsw	x0, x10, [x1, #-104]
ffff00000008c2fc:	253d657a 	whilele	pn10.b, x11, x29, vlx4
ffff00000008c300:	000a2964 	.inst	0x000a2964 ; undefined
ffff00000008c304:	00000000 	udf	#0
ffff00000008c308:	6f632020 	umlal2	v0.4s, v1.8h, v3.h[2]
ffff00000008c30c:	7865746e 	.inst	0x7865746e ; undefined
ffff00000008c310:	73692074 	.inst	0x73692074 ; undefined
ffff00000008c314:	4c554e20 	.inst	0x4c554e20 ; undefined
ffff00000008c318:	00000a4c 	udf	#2636
ffff00000008c31c:	00000000 	udf	#0
ffff00000008c320:	31782020 	adds	w0, w1, #0xe08, lsl #12
ffff00000008c324:	203d2039 	.inst	0x203d2039 ; undefined
ffff00000008c328:	78257830 	strh	w16, [x1, x5, lsl #1]
ffff00000008c32c:	0000000a 	udf	#10
ffff00000008c330:	32782020 	.inst	0x32782020 ; undefined
ffff00000008c334:	203d2030 	.inst	0x203d2030 ; undefined
ffff00000008c338:	78257830 	strh	w16, [x1, x5, lsl #1]
ffff00000008c33c:	0000000a 	udf	#10
ffff00000008c340:	32782020 	.inst	0x32782020 ; undefined
ffff00000008c344:	203d2031 	.inst	0x203d2031 ; undefined
ffff00000008c348:	78257830 	strh	w16, [x1, x5, lsl #1]
ffff00000008c34c:	0000000a 	udf	#10
ffff00000008c350:	32782020 	.inst	0x32782020 ; undefined
ffff00000008c354:	203d2032 	.inst	0x203d2032 ; undefined
ffff00000008c358:	78257830 	strh	w16, [x1, x5, lsl #1]
ffff00000008c35c:	0000000a 	udf	#10
ffff00000008c360:	32782020 	.inst	0x32782020 ; undefined
ffff00000008c364:	203d2033 	.inst	0x203d2033 ; undefined
ffff00000008c368:	78257830 	strh	w16, [x1, x5, lsl #1]
ffff00000008c36c:	0000000a 	udf	#10
ffff00000008c370:	32782020 	.inst	0x32782020 ; undefined
ffff00000008c374:	203d2034 	.inst	0x203d2034 ; undefined
ffff00000008c378:	0a257830 	bic	w16, w1, w5, lsl #30
ffff00000008c37c:	00000000 	udf	#0
ffff00000008c380:	32782020 	.inst	0x32782020 ; undefined
ffff00000008c384:	203d2035 	.inst	0x203d2035 ; undefined
ffff00000008c388:	78257830 	strh	w16, [x1, x5, lsl #1]
ffff00000008c38c:	0000000a 	udf	#10
ffff00000008c390:	32782020 	.inst	0x32782020 ; undefined
ffff00000008c394:	203d2036 	.inst	0x203d2036 ; undefined
ffff00000008c398:	78257830 	strh	w16, [x1, x5, lsl #1]
ffff00000008c39c:	0000000a 	udf	#10
ffff00000008c3a0:	32782020 	.inst	0x32782020 ; undefined
ffff00000008c3a4:	203d2037 	.inst	0x203d2037 ; undefined
ffff00000008c3a8:	78257830 	strh	w16, [x1, x5, lsl #1]
ffff00000008c3ac:	0000000a 	udf	#10
ffff00000008c3b0:	32782020 	.inst	0x32782020 ; undefined
ffff00000008c3b4:	203d2038 	.inst	0x203d2038 ; undefined
ffff00000008c3b8:	78257830 	strh	w16, [x1, x5, lsl #1]
ffff00000008c3bc:	0000000a 	udf	#10
ffff00000008c3c0:	70662020 	adr	x0, ffff0000001587c7 <bss_end+0xcb227>
ffff00000008c3c4:	203d2020 	.inst	0x203d2020 ; undefined
ffff00000008c3c8:	78257830 	strh	w16, [x1, x5, lsl #1]
ffff00000008c3cc:	0000000a 	udf	#10
ffff00000008c3d0:	726c2020 	.inst	0x726c2020 ; undefined
ffff00000008c3d4:	203d2020 	.inst	0x203d2020 ; undefined
ffff00000008c3d8:	78257830 	strh	w16, [x1, x5, lsl #1]
ffff00000008c3dc:	0000000a 	udf	#10
ffff00000008c3e0:	203d3d3d 	.inst	0x203d3d3d ; undefined
ffff00000008c3e4:	6e72656b 	umax	v11.8h, v11.8h, v18.8h
ffff00000008c3e8:	62206c65 	.inst	0x62206c65 ; undefined
ffff00000008c3ec:	746b6361 	.inst	0x746b6361 ; undefined
ffff00000008c3f0:	65636172 	fnmls	z18.h, p0/m, z11.h, z3.h
ffff00000008c3f4:	3d3d3d20 	str	b0, [x9, #3919]
ffff00000008c3f8:	0000000a 	udf	#10
ffff00000008c3fc:	00000000 	udf	#0
ffff00000008c400:	64252320 	fmul	z0.h, z25.h, z5.h[0]
ffff00000008c404:	7066203a 	adr	x26, ffff00000015880b <bss_end+0xcb26b>
ffff00000008c408:	2078253d 	.inst	0x2078253d ; undefined
ffff00000008c40c:	3d726c20 	ldr	b0, [x1, #3227]
ffff00000008c410:	000a7825 	.inst	0x000a7825 ; undefined
ffff00000008c414:	00000000 	udf	#0
ffff00000008c418:	3d3d3d3d 	str	b29, [x9, #3919]
ffff00000008c41c:	6373203d 	.inst	0x6373203d ; undefined
ffff00000008c420:	75646568 	.inst	0x75646568 ; undefined
ffff00000008c424:	3d20656c 	str	b12, [x11, #2073]
ffff00000008c428:	3d3d3d3d 	str	b29, [x9, #3919]
ffff00000008c42c:	0000000a 	udf	#10
ffff00000008c430:	72727563 	.inst	0x72727563 ; undefined
ffff00000008c434:	20746e65 	.inst	0x20746e65 ; undefined
ffff00000008c438:	636f7270 	.inst	0x636f7270 ; undefined
ffff00000008c43c:	20737365 	.inst	0x20737365 ; undefined
	...

Disassembly of section .data:

ffff00000008c450 <_binary_user_bin_start>:
ffff00000008c450:	94000002 	bl	ffff00000008c458 <_binary_user_bin_start+0x8>
ffff00000008c454:	14000000 	b	ffff00000008c454 <_binary_user_bin_start+0x4>
ffff00000008c458:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008c45c:	910003fd 	mov	x29, sp
ffff00000008c460:	f9000fff 	str	xzr, [sp, #24]
ffff00000008c464:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008c468:	90000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008c46c:	911ba000 	add	x0, x0, #0x6e8
ffff00000008c470:	940000bf 	bl	ffff00000008c76c <_binary_user_bin_start+0x31c>
ffff00000008c474:	d28000a0 	mov	x0, #0x5                   	// #5
ffff00000008c478:	9400019c 	bl	ffff00000008cae8 <_binary_user_bin_start+0x698>
ffff00000008c47c:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008c480:	91000400 	add	x0, x0, #0x1
ffff00000008c484:	f9000fe0 	str	x0, [sp, #24]
ffff00000008c488:	d503201f 	nop
ffff00000008c48c:	17fffff6 	b	ffff00000008c464 <_binary_user_bin_start+0x14>
ffff00000008c490:	d10183ff 	sub	sp, sp, #0x60
ffff00000008c494:	f9000fe0 	str	x0, [sp, #24]
ffff00000008c498:	b90017e1 	str	w1, [sp, #20]
ffff00000008c49c:	f90007e2 	str	x2, [sp, #8]
ffff00000008c4a0:	90000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008c4a4:	911c0001 	add	x1, x0, #0x700
ffff00000008c4a8:	910123e0 	add	x0, sp, #0x48
ffff00000008c4ac:	f9400022 	ldr	x2, [x1]
ffff00000008c4b0:	79401021 	ldrh	w1, [x1, #8]
ffff00000008c4b4:	f9000002 	str	x2, [x0]
ffff00000008c4b8:	79001001 	strh	w1, [x0, #8]
ffff00000008c4bc:	b9005fff 	str	wzr, [sp, #92]
ffff00000008c4c0:	f94007e2 	ldr	x2, [sp, #8]
ffff00000008c4c4:	b202e7e0 	mov	x0, #0xcccccccccccccccc    	// #-3689348814741910324
ffff00000008c4c8:	f29999a0 	movk	x0, #0xcccd
ffff00000008c4cc:	9bc07c40 	umulh	x0, x2, x0
ffff00000008c4d0:	d343fc01 	lsr	x1, x0, #3
ffff00000008c4d4:	aa0103e0 	mov	x0, x1
ffff00000008c4d8:	d37ef400 	lsl	x0, x0, #2
ffff00000008c4dc:	8b010000 	add	x0, x0, x1
ffff00000008c4e0:	8b000000 	add	x0, x0, x0
ffff00000008c4e4:	cb000041 	sub	x1, x2, x0
ffff00000008c4e8:	b9405fe0 	ldr	w0, [sp, #92]
ffff00000008c4ec:	11000402 	add	w2, w0, #0x1
ffff00000008c4f0:	b9005fe2 	str	w2, [sp, #92]
ffff00000008c4f4:	910123e2 	add	x2, sp, #0x48
ffff00000008c4f8:	38616842 	ldrb	w2, [x2, x1]
ffff00000008c4fc:	93407c00 	sxtw	x0, w0
ffff00000008c500:	9100a3e1 	add	x1, sp, #0x28
ffff00000008c504:	38206822 	strb	w2, [x1, x0]
ffff00000008c508:	f94007e1 	ldr	x1, [sp, #8]
ffff00000008c50c:	b202e7e0 	mov	x0, #0xcccccccccccccccc    	// #-3689348814741910324
ffff00000008c510:	f29999a0 	movk	x0, #0xcccd
ffff00000008c514:	9bc07c20 	umulh	x0, x1, x0
ffff00000008c518:	d343fc00 	lsr	x0, x0, #3
ffff00000008c51c:	f90007e0 	str	x0, [sp, #8]
ffff00000008c520:	f94007e0 	ldr	x0, [sp, #8]
ffff00000008c524:	f100001f 	cmp	x0, #0x0
ffff00000008c528:	54fffcc1 	b.ne	ffff00000008c4c0 <_binary_user_bin_start+0x70>  // b.any
ffff00000008c52c:	b9405fe0 	ldr	w0, [sp, #92]
ffff00000008c530:	51000400 	sub	w0, w0, #0x1
ffff00000008c534:	b9005be0 	str	w0, [sp, #88]
ffff00000008c538:	1400000e 	b	ffff00000008c570 <_binary_user_bin_start+0x120>
ffff00000008c53c:	b94017e0 	ldr	w0, [sp, #20]
ffff00000008c540:	11000401 	add	w1, w0, #0x1
ffff00000008c544:	b90017e1 	str	w1, [sp, #20]
ffff00000008c548:	93407c00 	sxtw	x0, w0
ffff00000008c54c:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008c550:	8b000020 	add	x0, x1, x0
ffff00000008c554:	b9805be1 	ldrsw	x1, [sp, #88]
ffff00000008c558:	9100a3e2 	add	x2, sp, #0x28
ffff00000008c55c:	38616841 	ldrb	w1, [x2, x1]
ffff00000008c560:	39000001 	strb	w1, [x0]
ffff00000008c564:	b9405be0 	ldr	w0, [sp, #88]
ffff00000008c568:	51000400 	sub	w0, w0, #0x1
ffff00000008c56c:	b9005be0 	str	w0, [sp, #88]
ffff00000008c570:	b9405be0 	ldr	w0, [sp, #88]
ffff00000008c574:	7100001f 	cmp	w0, #0x0
ffff00000008c578:	54fffe2a 	b.ge	ffff00000008c53c <_binary_user_bin_start+0xec>  // b.tcont
ffff00000008c57c:	b9405fe0 	ldr	w0, [sp, #92]
ffff00000008c580:	910183ff 	add	sp, sp, #0x60
ffff00000008c584:	d65f03c0 	ret
ffff00000008c588:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff00000008c58c:	910003fd 	mov	x29, sp
ffff00000008c590:	f90017e0 	str	x0, [sp, #40]
ffff00000008c594:	b90027e1 	str	w1, [sp, #36]
ffff00000008c598:	f9000fe2 	str	x2, [sp, #24]
ffff00000008c59c:	b9003fff 	str	wzr, [sp, #60]
ffff00000008c5a0:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008c5a4:	f100001f 	cmp	x0, #0x0
ffff00000008c5a8:	540001ca 	b.ge	ffff00000008c5e0 <_binary_user_bin_start+0x190>  // b.tcont
ffff00000008c5ac:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008c5b0:	cb0003e0 	neg	x0, x0
ffff00000008c5b4:	f9000fe0 	str	x0, [sp, #24]
ffff00000008c5b8:	b94027e0 	ldr	w0, [sp, #36]
ffff00000008c5bc:	11000401 	add	w1, w0, #0x1
ffff00000008c5c0:	b90027e1 	str	w1, [sp, #36]
ffff00000008c5c4:	93407c00 	sxtw	x0, w0
ffff00000008c5c8:	f94017e1 	ldr	x1, [sp, #40]
ffff00000008c5cc:	8b000020 	add	x0, x1, x0
ffff00000008c5d0:	528005a1 	mov	w1, #0x2d                  	// #45
ffff00000008c5d4:	39000001 	strb	w1, [x0]
ffff00000008c5d8:	52800020 	mov	w0, #0x1                   	// #1
ffff00000008c5dc:	b9003fe0 	str	w0, [sp, #60]
ffff00000008c5e0:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008c5e4:	aa0003e2 	mov	x2, x0
ffff00000008c5e8:	b94027e1 	ldr	w1, [sp, #36]
ffff00000008c5ec:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008c5f0:	97ffffa8 	bl	ffff00000008c490 <_binary_user_bin_start+0x40>
ffff00000008c5f4:	2a0003e1 	mov	w1, w0
ffff00000008c5f8:	b9403fe0 	ldr	w0, [sp, #60]
ffff00000008c5fc:	0b010000 	add	w0, w0, w1
ffff00000008c600:	b9003fe0 	str	w0, [sp, #60]
ffff00000008c604:	b9403fe0 	ldr	w0, [sp, #60]
ffff00000008c608:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff00000008c60c:	d65f03c0 	ret
ffff00000008c610:	d10183ff 	sub	sp, sp, #0x60
ffff00000008c614:	f9000fe0 	str	x0, [sp, #24]
ffff00000008c618:	b90017e1 	str	w1, [sp, #20]
ffff00000008c61c:	f90007e2 	str	x2, [sp, #8]
ffff00000008c620:	90000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008c624:	911c4000 	add	x0, x0, #0x710
ffff00000008c628:	a9400400 	ldp	x0, x1, [x0]
ffff00000008c62c:	a90287e0 	stp	x0, x1, [sp, #40]
ffff00000008c630:	b9005fff 	str	wzr, [sp, #92]
ffff00000008c634:	f94007e0 	ldr	x0, [sp, #8]
ffff00000008c638:	92400c01 	and	x1, x0, #0xf
ffff00000008c63c:	b9405fe0 	ldr	w0, [sp, #92]
ffff00000008c640:	11000402 	add	w2, w0, #0x1
ffff00000008c644:	b9005fe2 	str	w2, [sp, #92]
ffff00000008c648:	9100a3e2 	add	x2, sp, #0x28
ffff00000008c64c:	38616842 	ldrb	w2, [x2, x1]
ffff00000008c650:	93407c00 	sxtw	x0, w0
ffff00000008c654:	9100e3e1 	add	x1, sp, #0x38
ffff00000008c658:	38206822 	strb	w2, [x1, x0]
ffff00000008c65c:	f94007e0 	ldr	x0, [sp, #8]
ffff00000008c660:	d344fc00 	lsr	x0, x0, #4
ffff00000008c664:	f90007e0 	str	x0, [sp, #8]
ffff00000008c668:	f94007e0 	ldr	x0, [sp, #8]
ffff00000008c66c:	f100001f 	cmp	x0, #0x0
ffff00000008c670:	54fffe21 	b.ne	ffff00000008c634 <_binary_user_bin_start+0x1e4>  // b.any
ffff00000008c674:	b9405fe0 	ldr	w0, [sp, #92]
ffff00000008c678:	51000400 	sub	w0, w0, #0x1
ffff00000008c67c:	b9005be0 	str	w0, [sp, #88]
ffff00000008c680:	1400000e 	b	ffff00000008c6b8 <_binary_user_bin_start+0x268>
ffff00000008c684:	b94017e0 	ldr	w0, [sp, #20]
ffff00000008c688:	11000401 	add	w1, w0, #0x1
ffff00000008c68c:	b90017e1 	str	w1, [sp, #20]
ffff00000008c690:	93407c00 	sxtw	x0, w0
ffff00000008c694:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008c698:	8b000020 	add	x0, x1, x0
ffff00000008c69c:	b9805be1 	ldrsw	x1, [sp, #88]
ffff00000008c6a0:	9100e3e2 	add	x2, sp, #0x38
ffff00000008c6a4:	38616841 	ldrb	w1, [x2, x1]
ffff00000008c6a8:	39000001 	strb	w1, [x0]
ffff00000008c6ac:	b9405be0 	ldr	w0, [sp, #88]
ffff00000008c6b0:	51000400 	sub	w0, w0, #0x1
ffff00000008c6b4:	b9005be0 	str	w0, [sp, #88]
ffff00000008c6b8:	b9405be0 	ldr	w0, [sp, #88]
ffff00000008c6bc:	7100001f 	cmp	w0, #0x0
ffff00000008c6c0:	54fffe2a 	b.ge	ffff00000008c684 <_binary_user_bin_start+0x234>  // b.tcont
ffff00000008c6c4:	b94017e0 	ldr	w0, [sp, #20]
ffff00000008c6c8:	11000401 	add	w1, w0, #0x1
ffff00000008c6cc:	b90017e1 	str	w1, [sp, #20]
ffff00000008c6d0:	93407c00 	sxtw	x0, w0
ffff00000008c6d4:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008c6d8:	8b000020 	add	x0, x1, x0
ffff00000008c6dc:	52800901 	mov	w1, #0x48                  	// #72
ffff00000008c6e0:	39000001 	strb	w1, [x0]
ffff00000008c6e4:	b9405fe0 	ldr	w0, [sp, #92]
ffff00000008c6e8:	11000400 	add	w0, w0, #0x1
ffff00000008c6ec:	910183ff 	add	sp, sp, #0x60
ffff00000008c6f0:	d65f03c0 	ret
ffff00000008c6f4:	d100c3ff 	sub	sp, sp, #0x30
ffff00000008c6f8:	f9000fe0 	str	x0, [sp, #24]
ffff00000008c6fc:	b90017e1 	str	w1, [sp, #20]
ffff00000008c700:	f90007e2 	str	x2, [sp, #8]
ffff00000008c704:	b9002fff 	str	wzr, [sp, #44]
ffff00000008c708:	b9002fff 	str	wzr, [sp, #44]
ffff00000008c70c:	1400000f 	b	ffff00000008c748 <_binary_user_bin_start+0x2f8>
ffff00000008c710:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff00000008c714:	f94007e1 	ldr	x1, [sp, #8]
ffff00000008c718:	8b000021 	add	x1, x1, x0
ffff00000008c71c:	b94017e0 	ldr	w0, [sp, #20]
ffff00000008c720:	11000402 	add	w2, w0, #0x1
ffff00000008c724:	b90017e2 	str	w2, [sp, #20]
ffff00000008c728:	93407c00 	sxtw	x0, w0
ffff00000008c72c:	f9400fe2 	ldr	x2, [sp, #24]
ffff00000008c730:	8b000040 	add	x0, x2, x0
ffff00000008c734:	39400021 	ldrb	w1, [x1]
ffff00000008c738:	39000001 	strb	w1, [x0]
ffff00000008c73c:	b9402fe0 	ldr	w0, [sp, #44]
ffff00000008c740:	11000400 	add	w0, w0, #0x1
ffff00000008c744:	b9002fe0 	str	w0, [sp, #44]
ffff00000008c748:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff00000008c74c:	f94007e1 	ldr	x1, [sp, #8]
ffff00000008c750:	8b000020 	add	x0, x1, x0
ffff00000008c754:	39400000 	ldrb	w0, [x0]
ffff00000008c758:	7100001f 	cmp	w0, #0x0
ffff00000008c75c:	54fffda1 	b.ne	ffff00000008c710 <_binary_user_bin_start+0x2c0>  // b.any
ffff00000008c760:	b9402fe0 	ldr	w0, [sp, #44]
ffff00000008c764:	9100c3ff 	add	sp, sp, #0x30
ffff00000008c768:	d65f03c0 	ret
ffff00000008c76c:	d11283ff 	sub	sp, sp, #0x4a0
ffff00000008c770:	a9007bfd 	stp	x29, x30, [sp]
ffff00000008c774:	910003fd 	mov	x29, sp
ffff00000008c778:	f9000fe0 	str	x0, [sp, #24]
ffff00000008c77c:	f90237e1 	str	x1, [sp, #1128]
ffff00000008c780:	f9023be2 	str	x2, [sp, #1136]
ffff00000008c784:	f9023fe3 	str	x3, [sp, #1144]
ffff00000008c788:	f90243e4 	str	x4, [sp, #1152]
ffff00000008c78c:	f90247e5 	str	x5, [sp, #1160]
ffff00000008c790:	f9024be6 	str	x6, [sp, #1168]
ffff00000008c794:	f9024fe7 	str	x7, [sp, #1176]
ffff00000008c798:	b9045fff 	str	wzr, [sp, #1116]
ffff00000008c79c:	f9022bff 	str	xzr, [sp, #1104]
ffff00000008c7a0:	f90227ff 	str	xzr, [sp, #1096]
ffff00000008c7a4:	911283e0 	add	x0, sp, #0x4a0
ffff00000008c7a8:	f90017e0 	str	x0, [sp, #40]
ffff00000008c7ac:	911283e0 	add	x0, sp, #0x4a0
ffff00000008c7b0:	f9001be0 	str	x0, [sp, #48]
ffff00000008c7b4:	911183e0 	add	x0, sp, #0x460
ffff00000008c7b8:	f9001fe0 	str	x0, [sp, #56]
ffff00000008c7bc:	128006e0 	mov	w0, #0xffffffc8            	// #-56
ffff00000008c7c0:	b90043e0 	str	w0, [sp, #64]
ffff00000008c7c4:	b90047ff 	str	wzr, [sp, #68]
ffff00000008c7c8:	b9045bff 	str	wzr, [sp, #1112]
ffff00000008c7cc:	140000b1 	b	ffff00000008ca90 <_binary_user_bin_start+0x640>
ffff00000008c7d0:	b9845be0 	ldrsw	x0, [sp, #1112]
ffff00000008c7d4:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008c7d8:	8b000020 	add	x0, x1, x0
ffff00000008c7dc:	39400000 	ldrb	w0, [x0]
ffff00000008c7e0:	7100941f 	cmp	w0, #0x25
ffff00000008c7e4:	54000180 	b.eq	ffff00000008c814 <_binary_user_bin_start+0x3c4>  // b.none
ffff00000008c7e8:	b9845be0 	ldrsw	x0, [sp, #1112]
ffff00000008c7ec:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008c7f0:	8b000021 	add	x1, x1, x0
ffff00000008c7f4:	b9445fe0 	ldr	w0, [sp, #1116]
ffff00000008c7f8:	11000402 	add	w2, w0, #0x1
ffff00000008c7fc:	b9045fe2 	str	w2, [sp, #1116]
ffff00000008c800:	39400022 	ldrb	w2, [x1]
ffff00000008c804:	93407c00 	sxtw	x0, w0
ffff00000008c808:	910123e1 	add	x1, sp, #0x48
ffff00000008c80c:	38206822 	strb	w2, [x1, x0]
ffff00000008c810:	1400009d 	b	ffff00000008ca84 <_binary_user_bin_start+0x634>
ffff00000008c814:	b9445be0 	ldr	w0, [sp, #1112]
ffff00000008c818:	11000400 	add	w0, w0, #0x1
ffff00000008c81c:	b9045be0 	str	w0, [sp, #1112]
ffff00000008c820:	b9845be0 	ldrsw	x0, [sp, #1112]
ffff00000008c824:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008c828:	8b000020 	add	x0, x1, x0
ffff00000008c82c:	39400000 	ldrb	w0, [x0]
ffff00000008c830:	7101e01f 	cmp	w0, #0x78
ffff00000008c834:	54000180 	b.eq	ffff00000008c864 <_binary_user_bin_start+0x414>  // b.none
ffff00000008c838:	7101e01f 	cmp	w0, #0x78
ffff00000008c83c:	5400110c 	b.gt	ffff00000008ca5c <_binary_user_bin_start+0x60c>
ffff00000008c840:	7101d41f 	cmp	w0, #0x75
ffff00000008c844:	54000500 	b.eq	ffff00000008c8e4 <_binary_user_bin_start+0x494>  // b.none
ffff00000008c848:	7101d41f 	cmp	w0, #0x75
ffff00000008c84c:	5400108c 	b.gt	ffff00000008ca5c <_binary_user_bin_start+0x60c>
ffff00000008c850:	7101901f 	cmp	w0, #0x64
ffff00000008c854:	54000880 	b.eq	ffff00000008c964 <_binary_user_bin_start+0x514>  // b.none
ffff00000008c858:	7101cc1f 	cmp	w0, #0x73
ffff00000008c85c:	54000c20 	b.eq	ffff00000008c9e0 <_binary_user_bin_start+0x590>  // b.none
ffff00000008c860:	1400007f 	b	ffff00000008ca5c <_binary_user_bin_start+0x60c>
ffff00000008c864:	b94043e1 	ldr	w1, [sp, #64]
ffff00000008c868:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008c86c:	7100003f 	cmp	w1, #0x0
ffff00000008c870:	540000ab 	b.lt	ffff00000008c884 <_binary_user_bin_start+0x434>  // b.tstop
ffff00000008c874:	91003c01 	add	x1, x0, #0xf
ffff00000008c878:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff00000008c87c:	f90017e1 	str	x1, [sp, #40]
ffff00000008c880:	1400000d 	b	ffff00000008c8b4 <_binary_user_bin_start+0x464>
ffff00000008c884:	11002022 	add	w2, w1, #0x8
ffff00000008c888:	b90043e2 	str	w2, [sp, #64]
ffff00000008c88c:	b94043e2 	ldr	w2, [sp, #64]
ffff00000008c890:	7100005f 	cmp	w2, #0x0
ffff00000008c894:	540000ad 	b.le	ffff00000008c8a8 <_binary_user_bin_start+0x458>
ffff00000008c898:	91003c01 	add	x1, x0, #0xf
ffff00000008c89c:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff00000008c8a0:	f90017e1 	str	x1, [sp, #40]
ffff00000008c8a4:	14000004 	b	ffff00000008c8b4 <_binary_user_bin_start+0x464>
ffff00000008c8a8:	f9401be2 	ldr	x2, [sp, #48]
ffff00000008c8ac:	93407c20 	sxtw	x0, w1
ffff00000008c8b0:	8b000040 	add	x0, x2, x0
ffff00000008c8b4:	f9400000 	ldr	x0, [x0]
ffff00000008c8b8:	f9022be0 	str	x0, [sp, #1104]
ffff00000008c8bc:	f9422be1 	ldr	x1, [sp, #1104]
ffff00000008c8c0:	910123e0 	add	x0, sp, #0x48
ffff00000008c8c4:	aa0103e2 	mov	x2, x1
ffff00000008c8c8:	b9445fe1 	ldr	w1, [sp, #1116]
ffff00000008c8cc:	97ffff51 	bl	ffff00000008c610 <_binary_user_bin_start+0x1c0>
ffff00000008c8d0:	2a0003e1 	mov	w1, w0
ffff00000008c8d4:	b9445fe0 	ldr	w0, [sp, #1116]
ffff00000008c8d8:	0b010000 	add	w0, w0, w1
ffff00000008c8dc:	b9045fe0 	str	w0, [sp, #1116]
ffff00000008c8e0:	14000069 	b	ffff00000008ca84 <_binary_user_bin_start+0x634>
ffff00000008c8e4:	b94043e1 	ldr	w1, [sp, #64]
ffff00000008c8e8:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008c8ec:	7100003f 	cmp	w1, #0x0
ffff00000008c8f0:	540000ab 	b.lt	ffff00000008c904 <_binary_user_bin_start+0x4b4>  // b.tstop
ffff00000008c8f4:	91003c01 	add	x1, x0, #0xf
ffff00000008c8f8:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff00000008c8fc:	f90017e1 	str	x1, [sp, #40]
ffff00000008c900:	1400000d 	b	ffff00000008c934 <_binary_user_bin_start+0x4e4>
ffff00000008c904:	11002022 	add	w2, w1, #0x8
ffff00000008c908:	b90043e2 	str	w2, [sp, #64]
ffff00000008c90c:	b94043e2 	ldr	w2, [sp, #64]
ffff00000008c910:	7100005f 	cmp	w2, #0x0
ffff00000008c914:	540000ad 	b.le	ffff00000008c928 <_binary_user_bin_start+0x4d8>
ffff00000008c918:	91003c01 	add	x1, x0, #0xf
ffff00000008c91c:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff00000008c920:	f90017e1 	str	x1, [sp, #40]
ffff00000008c924:	14000004 	b	ffff00000008c934 <_binary_user_bin_start+0x4e4>
ffff00000008c928:	f9401be2 	ldr	x2, [sp, #48]
ffff00000008c92c:	93407c20 	sxtw	x0, w1
ffff00000008c930:	8b000040 	add	x0, x2, x0
ffff00000008c934:	f9400000 	ldr	x0, [x0]
ffff00000008c938:	f9022be0 	str	x0, [sp, #1104]
ffff00000008c93c:	f9422be1 	ldr	x1, [sp, #1104]
ffff00000008c940:	910123e0 	add	x0, sp, #0x48
ffff00000008c944:	aa0103e2 	mov	x2, x1
ffff00000008c948:	b9445fe1 	ldr	w1, [sp, #1116]
ffff00000008c94c:	97fffed1 	bl	ffff00000008c490 <_binary_user_bin_start+0x40>
ffff00000008c950:	2a0003e1 	mov	w1, w0
ffff00000008c954:	b9445fe0 	ldr	w0, [sp, #1116]
ffff00000008c958:	0b010000 	add	w0, w0, w1
ffff00000008c95c:	b9045fe0 	str	w0, [sp, #1116]
ffff00000008c960:	14000049 	b	ffff00000008ca84 <_binary_user_bin_start+0x634>
ffff00000008c964:	b94043e1 	ldr	w1, [sp, #64]
ffff00000008c968:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008c96c:	7100003f 	cmp	w1, #0x0
ffff00000008c970:	540000ab 	b.lt	ffff00000008c984 <_binary_user_bin_start+0x534>  // b.tstop
ffff00000008c974:	91003c01 	add	x1, x0, #0xf
ffff00000008c978:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff00000008c97c:	f90017e1 	str	x1, [sp, #40]
ffff00000008c980:	1400000d 	b	ffff00000008c9b4 <_binary_user_bin_start+0x564>
ffff00000008c984:	11002022 	add	w2, w1, #0x8
ffff00000008c988:	b90043e2 	str	w2, [sp, #64]
ffff00000008c98c:	b94043e2 	ldr	w2, [sp, #64]
ffff00000008c990:	7100005f 	cmp	w2, #0x0
ffff00000008c994:	540000ad 	b.le	ffff00000008c9a8 <_binary_user_bin_start+0x558>
ffff00000008c998:	91003c01 	add	x1, x0, #0xf
ffff00000008c99c:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff00000008c9a0:	f90017e1 	str	x1, [sp, #40]
ffff00000008c9a4:	14000004 	b	ffff00000008c9b4 <_binary_user_bin_start+0x564>
ffff00000008c9a8:	f9401be2 	ldr	x2, [sp, #48]
ffff00000008c9ac:	93407c20 	sxtw	x0, w1
ffff00000008c9b0:	8b000040 	add	x0, x2, x0
ffff00000008c9b4:	f9400000 	ldr	x0, [x0]
ffff00000008c9b8:	f9022be0 	str	x0, [sp, #1104]
ffff00000008c9bc:	910123e0 	add	x0, sp, #0x48
ffff00000008c9c0:	f9422be2 	ldr	x2, [sp, #1104]
ffff00000008c9c4:	b9445fe1 	ldr	w1, [sp, #1116]
ffff00000008c9c8:	97fffef0 	bl	ffff00000008c588 <_binary_user_bin_start+0x138>
ffff00000008c9cc:	2a0003e1 	mov	w1, w0
ffff00000008c9d0:	b9445fe0 	ldr	w0, [sp, #1116]
ffff00000008c9d4:	0b010000 	add	w0, w0, w1
ffff00000008c9d8:	b9045fe0 	str	w0, [sp, #1116]
ffff00000008c9dc:	1400002a 	b	ffff00000008ca84 <_binary_user_bin_start+0x634>
ffff00000008c9e0:	b94043e1 	ldr	w1, [sp, #64]
ffff00000008c9e4:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008c9e8:	7100003f 	cmp	w1, #0x0
ffff00000008c9ec:	540000ab 	b.lt	ffff00000008ca00 <_binary_user_bin_start+0x5b0>  // b.tstop
ffff00000008c9f0:	91003c01 	add	x1, x0, #0xf
ffff00000008c9f4:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff00000008c9f8:	f90017e1 	str	x1, [sp, #40]
ffff00000008c9fc:	1400000d 	b	ffff00000008ca30 <_binary_user_bin_start+0x5e0>
ffff00000008ca00:	11002022 	add	w2, w1, #0x8
ffff00000008ca04:	b90043e2 	str	w2, [sp, #64]
ffff00000008ca08:	b94043e2 	ldr	w2, [sp, #64]
ffff00000008ca0c:	7100005f 	cmp	w2, #0x0
ffff00000008ca10:	540000ad 	b.le	ffff00000008ca24 <_binary_user_bin_start+0x5d4>
ffff00000008ca14:	91003c01 	add	x1, x0, #0xf
ffff00000008ca18:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff00000008ca1c:	f90017e1 	str	x1, [sp, #40]
ffff00000008ca20:	14000004 	b	ffff00000008ca30 <_binary_user_bin_start+0x5e0>
ffff00000008ca24:	f9401be2 	ldr	x2, [sp, #48]
ffff00000008ca28:	93407c20 	sxtw	x0, w1
ffff00000008ca2c:	8b000040 	add	x0, x2, x0
ffff00000008ca30:	f9400000 	ldr	x0, [x0]
ffff00000008ca34:	f90227e0 	str	x0, [sp, #1096]
ffff00000008ca38:	910123e0 	add	x0, sp, #0x48
ffff00000008ca3c:	f94227e2 	ldr	x2, [sp, #1096]
ffff00000008ca40:	b9445fe1 	ldr	w1, [sp, #1116]
ffff00000008ca44:	97ffff2c 	bl	ffff00000008c6f4 <_binary_user_bin_start+0x2a4>
ffff00000008ca48:	2a0003e1 	mov	w1, w0
ffff00000008ca4c:	b9445fe0 	ldr	w0, [sp, #1116]
ffff00000008ca50:	0b010000 	add	w0, w0, w1
ffff00000008ca54:	b9045fe0 	str	w0, [sp, #1116]
ffff00000008ca58:	1400000b 	b	ffff00000008ca84 <_binary_user_bin_start+0x634>
ffff00000008ca5c:	b9445fe0 	ldr	w0, [sp, #1116]
ffff00000008ca60:	11000401 	add	w1, w0, #0x1
ffff00000008ca64:	b9045fe1 	str	w1, [sp, #1116]
ffff00000008ca68:	93407c00 	sxtw	x0, w0
ffff00000008ca6c:	910123e1 	add	x1, sp, #0x48
ffff00000008ca70:	528004a2 	mov	w2, #0x25                  	// #37
ffff00000008ca74:	38206822 	strb	w2, [x1, x0]
ffff00000008ca78:	b9445be0 	ldr	w0, [sp, #1112]
ffff00000008ca7c:	51000400 	sub	w0, w0, #0x1
ffff00000008ca80:	b9045be0 	str	w0, [sp, #1112]
ffff00000008ca84:	b9445be0 	ldr	w0, [sp, #1112]
ffff00000008ca88:	11000400 	add	w0, w0, #0x1
ffff00000008ca8c:	b9045be0 	str	w0, [sp, #1112]
ffff00000008ca90:	b9845be0 	ldrsw	x0, [sp, #1112]
ffff00000008ca94:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008ca98:	8b000020 	add	x0, x1, x0
ffff00000008ca9c:	39400000 	ldrb	w0, [x0]
ffff00000008caa0:	7100001f 	cmp	w0, #0x0
ffff00000008caa4:	54ffe961 	b.ne	ffff00000008c7d0 <_binary_user_bin_start+0x380>  // b.any
ffff00000008caa8:	910123e0 	add	x0, sp, #0x48
ffff00000008caac:	b9445fe1 	ldr	w1, [sp, #1116]
ffff00000008cab0:	94000006 	bl	ffff00000008cac8 <_binary_user_bin_start+0x678>
ffff00000008cab4:	b9045fe0 	str	w0, [sp, #1116]
ffff00000008cab8:	b9445fe0 	ldr	w0, [sp, #1116]
ffff00000008cabc:	a9407bfd 	ldp	x29, x30, [sp]
ffff00000008cac0:	911283ff 	add	sp, sp, #0x4a0
ffff00000008cac4:	d65f03c0 	ret
ffff00000008cac8:	d10043ff 	sub	sp, sp, #0x10
ffff00000008cacc:	d2800008 	mov	x8, #0x0                   	// #0
ffff00000008cad0:	a90007e0 	stp	x0, x1, [sp]
ffff00000008cad4:	d2800040 	mov	x0, #0x2                   	// #2
ffff00000008cad8:	910003e1 	mov	x1, sp
ffff00000008cadc:	d4009a41 	svc	#0x4d2
ffff00000008cae0:	910043ff 	add	sp, sp, #0x10
ffff00000008cae4:	d65f03c0 	ret
ffff00000008cae8:	d10023ff 	sub	sp, sp, #0x8
ffff00000008caec:	d2800028 	mov	x8, #0x1                   	// #1
ffff00000008caf0:	f90003e0 	str	x0, [sp]
ffff00000008caf4:	d2800020 	mov	x0, #0x1                   	// #1
ffff00000008caf8:	910003e1 	mov	x1, sp
ffff00000008cafc:	d4009a41 	svc	#0x4d2
ffff00000008cb00:	910023ff 	add	sp, sp, #0x8
ffff00000008cb04:	d65f03c0 	ret
ffff00000008cb08:	d2800048 	mov	x8, #0x2                   	// #2
ffff00000008cb0c:	d2800000 	mov	x0, #0x0                   	// #0
ffff00000008cb10:	d4009a41 	svc	#0x4d2
ffff00000008cb14:	d65f03c0 	ret
ffff00000008cb18:	d10023ff 	sub	sp, sp, #0x8
ffff00000008cb1c:	d2800068 	mov	x8, #0x3                   	// #3
ffff00000008cb20:	f90003e0 	str	x0, [sp]
ffff00000008cb24:	d2800020 	mov	x0, #0x1                   	// #1
ffff00000008cb28:	910003e1 	mov	x1, sp
ffff00000008cb2c:	d4009a41 	svc	#0x4d2
ffff00000008cb30:	910023ff 	add	sp, sp, #0x8
ffff00000008cb34:	d65f03c0 	ret
ffff00000008cb38:	72657355 	.inst	0x72657355 ; undefined
ffff00000008cb3c:	72702032 	.inst	0x72702032 ; undefined
ffff00000008cb40:	7365636f 	.inst	0x7365636f ; undefined
ffff00000008cb44:	75252073 	cblt	w19, #10, ffff00000008c750 <_binary_user_bin_start+0x300>
ffff00000008cb48:	00000a0d 	udf	#2573
ffff00000008cb4c:	00000000 	udf	#0
ffff00000008cb50:	33323130 	.inst	0x33323130 ; undefined
ffff00000008cb54:	37363534 	tbnz	w20, #6, ffff0000000891f8 <pmd_ttbr0+0x1f8>
ffff00000008cb58:	00003938 	udf	#14648
ffff00000008cb5c:	00000000 	udf	#0
ffff00000008cb60:	33323130 	.inst	0x33323130 ; undefined
ffff00000008cb64:	37363534 	tbnz	w20, #6, ffff000000089208 <pmd_ttbr0+0x208>
ffff00000008cb68:	42413938 	.inst	0x42413938 ; undefined
ffff00000008cb6c:	46454443 	.inst	0x46454443 ; undefined

ffff00000008cb70 <_binary_init_bin_start>:
ffff00000008cb70:	94000002 	bl	ffff00000008cb78 <_binary_init_bin_start+0x8>
ffff00000008cb74:	14000000 	b	ffff00000008cb74 <_binary_init_bin_start+0x4>
ffff00000008cb78:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffff00000008cb7c:	910003fd 	mov	x29, sp
ffff00000008cb80:	f9000fff 	str	xzr, [sp, #24]
ffff00000008cb84:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008cb88:	d28857a0 	mov	x0, #0x42bd                	// #17085
ffff00000008cb8c:	f2bcaf40 	movk	x0, #0xe57a, lsl #16
ffff00000008cb90:	f2d29aa0 	movk	x0, #0x94d5, lsl #32
ffff00000008cb94:	f2fad7e0 	movk	x0, #0xd6bf, lsl #48
ffff00000008cb98:	9bc07c20 	umulh	x0, x1, x0
ffff00000008cb9c:	d357fc00 	lsr	x0, x0, #23
ffff00000008cba0:	d292d002 	mov	x2, #0x9680                	// #38528
ffff00000008cba4:	f2a01302 	movk	x2, #0x98, lsl #16
ffff00000008cba8:	9b027c00 	mul	x0, x0, x2
ffff00000008cbac:	cb000020 	sub	x0, x1, x0
ffff00000008cbb0:	f100001f 	cmp	x0, #0x0
ffff00000008cbb4:	540000a1 	b.ne	ffff00000008cbc8 <_binary_init_bin_start+0x58>  // b.any
ffff00000008cbb8:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008cbbc:	90000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008cbc0:	911c4000 	add	x0, x0, #0x710
ffff00000008cbc4:	940000bc 	bl	ffff00000008ceb4 <_binary_init_bin_start+0x344>
ffff00000008cbc8:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008cbcc:	91000400 	add	x0, x0, #0x1
ffff00000008cbd0:	f9000fe0 	str	x0, [sp, #24]
ffff00000008cbd4:	17ffffec 	b	ffff00000008cb84 <_binary_init_bin_start+0x14>
ffff00000008cbd8:	d10183ff 	sub	sp, sp, #0x60
ffff00000008cbdc:	f9000fe0 	str	x0, [sp, #24]
ffff00000008cbe0:	b90017e1 	str	w1, [sp, #20]
ffff00000008cbe4:	f90007e2 	str	x2, [sp, #8]
ffff00000008cbe8:	90000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008cbec:	911ca001 	add	x1, x0, #0x728
ffff00000008cbf0:	910123e0 	add	x0, sp, #0x48
ffff00000008cbf4:	f9400022 	ldr	x2, [x1]
ffff00000008cbf8:	79401021 	ldrh	w1, [x1, #8]
ffff00000008cbfc:	f9000002 	str	x2, [x0]
ffff00000008cc00:	79001001 	strh	w1, [x0, #8]
ffff00000008cc04:	b9005fff 	str	wzr, [sp, #92]
ffff00000008cc08:	f94007e2 	ldr	x2, [sp, #8]
ffff00000008cc0c:	b202e7e0 	mov	x0, #0xcccccccccccccccc    	// #-3689348814741910324
ffff00000008cc10:	f29999a0 	movk	x0, #0xcccd
ffff00000008cc14:	9bc07c40 	umulh	x0, x2, x0
ffff00000008cc18:	d343fc01 	lsr	x1, x0, #3
ffff00000008cc1c:	aa0103e0 	mov	x0, x1
ffff00000008cc20:	d37ef400 	lsl	x0, x0, #2
ffff00000008cc24:	8b010000 	add	x0, x0, x1
ffff00000008cc28:	8b000000 	add	x0, x0, x0
ffff00000008cc2c:	cb000041 	sub	x1, x2, x0
ffff00000008cc30:	b9405fe0 	ldr	w0, [sp, #92]
ffff00000008cc34:	11000402 	add	w2, w0, #0x1
ffff00000008cc38:	b9005fe2 	str	w2, [sp, #92]
ffff00000008cc3c:	910123e2 	add	x2, sp, #0x48
ffff00000008cc40:	38616842 	ldrb	w2, [x2, x1]
ffff00000008cc44:	93407c00 	sxtw	x0, w0
ffff00000008cc48:	9100a3e1 	add	x1, sp, #0x28
ffff00000008cc4c:	38206822 	strb	w2, [x1, x0]
ffff00000008cc50:	f94007e1 	ldr	x1, [sp, #8]
ffff00000008cc54:	b202e7e0 	mov	x0, #0xcccccccccccccccc    	// #-3689348814741910324
ffff00000008cc58:	f29999a0 	movk	x0, #0xcccd
ffff00000008cc5c:	9bc07c20 	umulh	x0, x1, x0
ffff00000008cc60:	d343fc00 	lsr	x0, x0, #3
ffff00000008cc64:	f90007e0 	str	x0, [sp, #8]
ffff00000008cc68:	f94007e0 	ldr	x0, [sp, #8]
ffff00000008cc6c:	f100001f 	cmp	x0, #0x0
ffff00000008cc70:	54fffcc1 	b.ne	ffff00000008cc08 <_binary_init_bin_start+0x98>  // b.any
ffff00000008cc74:	b9405fe0 	ldr	w0, [sp, #92]
ffff00000008cc78:	51000400 	sub	w0, w0, #0x1
ffff00000008cc7c:	b9005be0 	str	w0, [sp, #88]
ffff00000008cc80:	1400000e 	b	ffff00000008ccb8 <_binary_init_bin_start+0x148>
ffff00000008cc84:	b94017e0 	ldr	w0, [sp, #20]
ffff00000008cc88:	11000401 	add	w1, w0, #0x1
ffff00000008cc8c:	b90017e1 	str	w1, [sp, #20]
ffff00000008cc90:	93407c00 	sxtw	x0, w0
ffff00000008cc94:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008cc98:	8b000020 	add	x0, x1, x0
ffff00000008cc9c:	b9805be1 	ldrsw	x1, [sp, #88]
ffff00000008cca0:	9100a3e2 	add	x2, sp, #0x28
ffff00000008cca4:	38616841 	ldrb	w1, [x2, x1]
ffff00000008cca8:	39000001 	strb	w1, [x0]
ffff00000008ccac:	b9405be0 	ldr	w0, [sp, #88]
ffff00000008ccb0:	51000400 	sub	w0, w0, #0x1
ffff00000008ccb4:	b9005be0 	str	w0, [sp, #88]
ffff00000008ccb8:	b9405be0 	ldr	w0, [sp, #88]
ffff00000008ccbc:	7100001f 	cmp	w0, #0x0
ffff00000008ccc0:	54fffe2a 	b.ge	ffff00000008cc84 <_binary_init_bin_start+0x114>  // b.tcont
ffff00000008ccc4:	b9405fe0 	ldr	w0, [sp, #92]
ffff00000008ccc8:	910183ff 	add	sp, sp, #0x60
ffff00000008cccc:	d65f03c0 	ret
ffff00000008ccd0:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffff00000008ccd4:	910003fd 	mov	x29, sp
ffff00000008ccd8:	f90017e0 	str	x0, [sp, #40]
ffff00000008ccdc:	b90027e1 	str	w1, [sp, #36]
ffff00000008cce0:	f9000fe2 	str	x2, [sp, #24]
ffff00000008cce4:	b9003fff 	str	wzr, [sp, #60]
ffff00000008cce8:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008ccec:	f100001f 	cmp	x0, #0x0
ffff00000008ccf0:	540001ca 	b.ge	ffff00000008cd28 <_binary_init_bin_start+0x1b8>  // b.tcont
ffff00000008ccf4:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008ccf8:	cb0003e0 	neg	x0, x0
ffff00000008ccfc:	f9000fe0 	str	x0, [sp, #24]
ffff00000008cd00:	b94027e0 	ldr	w0, [sp, #36]
ffff00000008cd04:	11000401 	add	w1, w0, #0x1
ffff00000008cd08:	b90027e1 	str	w1, [sp, #36]
ffff00000008cd0c:	93407c00 	sxtw	x0, w0
ffff00000008cd10:	f94017e1 	ldr	x1, [sp, #40]
ffff00000008cd14:	8b000020 	add	x0, x1, x0
ffff00000008cd18:	528005a1 	mov	w1, #0x2d                  	// #45
ffff00000008cd1c:	39000001 	strb	w1, [x0]
ffff00000008cd20:	52800020 	mov	w0, #0x1                   	// #1
ffff00000008cd24:	b9003fe0 	str	w0, [sp, #60]
ffff00000008cd28:	f9400fe0 	ldr	x0, [sp, #24]
ffff00000008cd2c:	aa0003e2 	mov	x2, x0
ffff00000008cd30:	b94027e1 	ldr	w1, [sp, #36]
ffff00000008cd34:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008cd38:	97ffffa8 	bl	ffff00000008cbd8 <_binary_init_bin_start+0x68>
ffff00000008cd3c:	2a0003e1 	mov	w1, w0
ffff00000008cd40:	b9403fe0 	ldr	w0, [sp, #60]
ffff00000008cd44:	0b010000 	add	w0, w0, w1
ffff00000008cd48:	b9003fe0 	str	w0, [sp, #60]
ffff00000008cd4c:	b9403fe0 	ldr	w0, [sp, #60]
ffff00000008cd50:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffff00000008cd54:	d65f03c0 	ret
ffff00000008cd58:	d10183ff 	sub	sp, sp, #0x60
ffff00000008cd5c:	f9000fe0 	str	x0, [sp, #24]
ffff00000008cd60:	b90017e1 	str	w1, [sp, #20]
ffff00000008cd64:	f90007e2 	str	x2, [sp, #8]
ffff00000008cd68:	90000000 	adrp	x0, ffff00000008c000 <system_call+0x88>
ffff00000008cd6c:	911ce000 	add	x0, x0, #0x738
ffff00000008cd70:	a9400400 	ldp	x0, x1, [x0]
ffff00000008cd74:	a90287e0 	stp	x0, x1, [sp, #40]
ffff00000008cd78:	b9005fff 	str	wzr, [sp, #92]
ffff00000008cd7c:	f94007e0 	ldr	x0, [sp, #8]
ffff00000008cd80:	92400c01 	and	x1, x0, #0xf
ffff00000008cd84:	b9405fe0 	ldr	w0, [sp, #92]
ffff00000008cd88:	11000402 	add	w2, w0, #0x1
ffff00000008cd8c:	b9005fe2 	str	w2, [sp, #92]
ffff00000008cd90:	9100a3e2 	add	x2, sp, #0x28
ffff00000008cd94:	38616842 	ldrb	w2, [x2, x1]
ffff00000008cd98:	93407c00 	sxtw	x0, w0
ffff00000008cd9c:	9100e3e1 	add	x1, sp, #0x38
ffff00000008cda0:	38206822 	strb	w2, [x1, x0]
ffff00000008cda4:	f94007e0 	ldr	x0, [sp, #8]
ffff00000008cda8:	d344fc00 	lsr	x0, x0, #4
ffff00000008cdac:	f90007e0 	str	x0, [sp, #8]
ffff00000008cdb0:	f94007e0 	ldr	x0, [sp, #8]
ffff00000008cdb4:	f100001f 	cmp	x0, #0x0
ffff00000008cdb8:	54fffe21 	b.ne	ffff00000008cd7c <_binary_init_bin_start+0x20c>  // b.any
ffff00000008cdbc:	b9405fe0 	ldr	w0, [sp, #92]
ffff00000008cdc0:	51000400 	sub	w0, w0, #0x1
ffff00000008cdc4:	b9005be0 	str	w0, [sp, #88]
ffff00000008cdc8:	1400000e 	b	ffff00000008ce00 <_binary_init_bin_start+0x290>
ffff00000008cdcc:	b94017e0 	ldr	w0, [sp, #20]
ffff00000008cdd0:	11000401 	add	w1, w0, #0x1
ffff00000008cdd4:	b90017e1 	str	w1, [sp, #20]
ffff00000008cdd8:	93407c00 	sxtw	x0, w0
ffff00000008cddc:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008cde0:	8b000020 	add	x0, x1, x0
ffff00000008cde4:	b9805be1 	ldrsw	x1, [sp, #88]
ffff00000008cde8:	9100e3e2 	add	x2, sp, #0x38
ffff00000008cdec:	38616841 	ldrb	w1, [x2, x1]
ffff00000008cdf0:	39000001 	strb	w1, [x0]
ffff00000008cdf4:	b9405be0 	ldr	w0, [sp, #88]
ffff00000008cdf8:	51000400 	sub	w0, w0, #0x1
ffff00000008cdfc:	b9005be0 	str	w0, [sp, #88]
ffff00000008ce00:	b9405be0 	ldr	w0, [sp, #88]
ffff00000008ce04:	7100001f 	cmp	w0, #0x0
ffff00000008ce08:	54fffe2a 	b.ge	ffff00000008cdcc <_binary_init_bin_start+0x25c>  // b.tcont
ffff00000008ce0c:	b94017e0 	ldr	w0, [sp, #20]
ffff00000008ce10:	11000401 	add	w1, w0, #0x1
ffff00000008ce14:	b90017e1 	str	w1, [sp, #20]
ffff00000008ce18:	93407c00 	sxtw	x0, w0
ffff00000008ce1c:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008ce20:	8b000020 	add	x0, x1, x0
ffff00000008ce24:	52800901 	mov	w1, #0x48                  	// #72
ffff00000008ce28:	39000001 	strb	w1, [x0]
ffff00000008ce2c:	b9405fe0 	ldr	w0, [sp, #92]
ffff00000008ce30:	11000400 	add	w0, w0, #0x1
ffff00000008ce34:	910183ff 	add	sp, sp, #0x60
ffff00000008ce38:	d65f03c0 	ret
ffff00000008ce3c:	d100c3ff 	sub	sp, sp, #0x30
ffff00000008ce40:	f9000fe0 	str	x0, [sp, #24]
ffff00000008ce44:	b90017e1 	str	w1, [sp, #20]
ffff00000008ce48:	f90007e2 	str	x2, [sp, #8]
ffff00000008ce4c:	b9002fff 	str	wzr, [sp, #44]
ffff00000008ce50:	b9002fff 	str	wzr, [sp, #44]
ffff00000008ce54:	1400000f 	b	ffff00000008ce90 <_binary_init_bin_start+0x320>
ffff00000008ce58:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff00000008ce5c:	f94007e1 	ldr	x1, [sp, #8]
ffff00000008ce60:	8b000021 	add	x1, x1, x0
ffff00000008ce64:	b94017e0 	ldr	w0, [sp, #20]
ffff00000008ce68:	11000402 	add	w2, w0, #0x1
ffff00000008ce6c:	b90017e2 	str	w2, [sp, #20]
ffff00000008ce70:	93407c00 	sxtw	x0, w0
ffff00000008ce74:	f9400fe2 	ldr	x2, [sp, #24]
ffff00000008ce78:	8b000040 	add	x0, x2, x0
ffff00000008ce7c:	39400021 	ldrb	w1, [x1]
ffff00000008ce80:	39000001 	strb	w1, [x0]
ffff00000008ce84:	b9402fe0 	ldr	w0, [sp, #44]
ffff00000008ce88:	11000400 	add	w0, w0, #0x1
ffff00000008ce8c:	b9002fe0 	str	w0, [sp, #44]
ffff00000008ce90:	b9802fe0 	ldrsw	x0, [sp, #44]
ffff00000008ce94:	f94007e1 	ldr	x1, [sp, #8]
ffff00000008ce98:	8b000020 	add	x0, x1, x0
ffff00000008ce9c:	39400000 	ldrb	w0, [x0]
ffff00000008cea0:	7100001f 	cmp	w0, #0x0
ffff00000008cea4:	54fffda1 	b.ne	ffff00000008ce58 <_binary_init_bin_start+0x2e8>  // b.any
ffff00000008cea8:	b9402fe0 	ldr	w0, [sp, #44]
ffff00000008ceac:	9100c3ff 	add	sp, sp, #0x30
ffff00000008ceb0:	d65f03c0 	ret
ffff00000008ceb4:	d11283ff 	sub	sp, sp, #0x4a0
ffff00000008ceb8:	a9007bfd 	stp	x29, x30, [sp]
ffff00000008cebc:	910003fd 	mov	x29, sp
ffff00000008cec0:	f9000fe0 	str	x0, [sp, #24]
ffff00000008cec4:	f90237e1 	str	x1, [sp, #1128]
ffff00000008cec8:	f9023be2 	str	x2, [sp, #1136]
ffff00000008cecc:	f9023fe3 	str	x3, [sp, #1144]
ffff00000008ced0:	f90243e4 	str	x4, [sp, #1152]
ffff00000008ced4:	f90247e5 	str	x5, [sp, #1160]
ffff00000008ced8:	f9024be6 	str	x6, [sp, #1168]
ffff00000008cedc:	f9024fe7 	str	x7, [sp, #1176]
ffff00000008cee0:	b9045fff 	str	wzr, [sp, #1116]
ffff00000008cee4:	f9022bff 	str	xzr, [sp, #1104]
ffff00000008cee8:	f90227ff 	str	xzr, [sp, #1096]
ffff00000008ceec:	911283e0 	add	x0, sp, #0x4a0
ffff00000008cef0:	f90017e0 	str	x0, [sp, #40]
ffff00000008cef4:	911283e0 	add	x0, sp, #0x4a0
ffff00000008cef8:	f9001be0 	str	x0, [sp, #48]
ffff00000008cefc:	911183e0 	add	x0, sp, #0x460
ffff00000008cf00:	f9001fe0 	str	x0, [sp, #56]
ffff00000008cf04:	128006e0 	mov	w0, #0xffffffc8            	// #-56
ffff00000008cf08:	b90043e0 	str	w0, [sp, #64]
ffff00000008cf0c:	b90047ff 	str	wzr, [sp, #68]
ffff00000008cf10:	b9045bff 	str	wzr, [sp, #1112]
ffff00000008cf14:	140000b1 	b	ffff00000008d1d8 <_binary_init_bin_start+0x668>
ffff00000008cf18:	b9845be0 	ldrsw	x0, [sp, #1112]
ffff00000008cf1c:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008cf20:	8b000020 	add	x0, x1, x0
ffff00000008cf24:	39400000 	ldrb	w0, [x0]
ffff00000008cf28:	7100941f 	cmp	w0, #0x25
ffff00000008cf2c:	54000180 	b.eq	ffff00000008cf5c <_binary_init_bin_start+0x3ec>  // b.none
ffff00000008cf30:	b9845be0 	ldrsw	x0, [sp, #1112]
ffff00000008cf34:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008cf38:	8b000021 	add	x1, x1, x0
ffff00000008cf3c:	b9445fe0 	ldr	w0, [sp, #1116]
ffff00000008cf40:	11000402 	add	w2, w0, #0x1
ffff00000008cf44:	b9045fe2 	str	w2, [sp, #1116]
ffff00000008cf48:	39400022 	ldrb	w2, [x1]
ffff00000008cf4c:	93407c00 	sxtw	x0, w0
ffff00000008cf50:	910123e1 	add	x1, sp, #0x48
ffff00000008cf54:	38206822 	strb	w2, [x1, x0]
ffff00000008cf58:	1400009d 	b	ffff00000008d1cc <_binary_init_bin_start+0x65c>
ffff00000008cf5c:	b9445be0 	ldr	w0, [sp, #1112]
ffff00000008cf60:	11000400 	add	w0, w0, #0x1
ffff00000008cf64:	b9045be0 	str	w0, [sp, #1112]
ffff00000008cf68:	b9845be0 	ldrsw	x0, [sp, #1112]
ffff00000008cf6c:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008cf70:	8b000020 	add	x0, x1, x0
ffff00000008cf74:	39400000 	ldrb	w0, [x0]
ffff00000008cf78:	7101e01f 	cmp	w0, #0x78
ffff00000008cf7c:	54000180 	b.eq	ffff00000008cfac <_binary_init_bin_start+0x43c>  // b.none
ffff00000008cf80:	7101e01f 	cmp	w0, #0x78
ffff00000008cf84:	5400110c 	b.gt	ffff00000008d1a4 <_binary_init_bin_start+0x634>
ffff00000008cf88:	7101d41f 	cmp	w0, #0x75
ffff00000008cf8c:	54000500 	b.eq	ffff00000008d02c <_binary_init_bin_start+0x4bc>  // b.none
ffff00000008cf90:	7101d41f 	cmp	w0, #0x75
ffff00000008cf94:	5400108c 	b.gt	ffff00000008d1a4 <_binary_init_bin_start+0x634>
ffff00000008cf98:	7101901f 	cmp	w0, #0x64
ffff00000008cf9c:	54000880 	b.eq	ffff00000008d0ac <_binary_init_bin_start+0x53c>  // b.none
ffff00000008cfa0:	7101cc1f 	cmp	w0, #0x73
ffff00000008cfa4:	54000c20 	b.eq	ffff00000008d128 <_binary_init_bin_start+0x5b8>  // b.none
ffff00000008cfa8:	1400007f 	b	ffff00000008d1a4 <_binary_init_bin_start+0x634>
ffff00000008cfac:	b94043e1 	ldr	w1, [sp, #64]
ffff00000008cfb0:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008cfb4:	7100003f 	cmp	w1, #0x0
ffff00000008cfb8:	540000ab 	b.lt	ffff00000008cfcc <_binary_init_bin_start+0x45c>  // b.tstop
ffff00000008cfbc:	91003c01 	add	x1, x0, #0xf
ffff00000008cfc0:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff00000008cfc4:	f90017e1 	str	x1, [sp, #40]
ffff00000008cfc8:	1400000d 	b	ffff00000008cffc <_binary_init_bin_start+0x48c>
ffff00000008cfcc:	11002022 	add	w2, w1, #0x8
ffff00000008cfd0:	b90043e2 	str	w2, [sp, #64]
ffff00000008cfd4:	b94043e2 	ldr	w2, [sp, #64]
ffff00000008cfd8:	7100005f 	cmp	w2, #0x0
ffff00000008cfdc:	540000ad 	b.le	ffff00000008cff0 <_binary_init_bin_start+0x480>
ffff00000008cfe0:	91003c01 	add	x1, x0, #0xf
ffff00000008cfe4:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff00000008cfe8:	f90017e1 	str	x1, [sp, #40]
ffff00000008cfec:	14000004 	b	ffff00000008cffc <_binary_init_bin_start+0x48c>
ffff00000008cff0:	f9401be2 	ldr	x2, [sp, #48]
ffff00000008cff4:	93407c20 	sxtw	x0, w1
ffff00000008cff8:	8b000040 	add	x0, x2, x0
ffff00000008cffc:	f9400000 	ldr	x0, [x0]
ffff00000008d000:	f9022be0 	str	x0, [sp, #1104]
ffff00000008d004:	f9422be1 	ldr	x1, [sp, #1104]
ffff00000008d008:	910123e0 	add	x0, sp, #0x48
ffff00000008d00c:	aa0103e2 	mov	x2, x1
ffff00000008d010:	b9445fe1 	ldr	w1, [sp, #1116]
ffff00000008d014:	97ffff51 	bl	ffff00000008cd58 <_binary_init_bin_start+0x1e8>
ffff00000008d018:	2a0003e1 	mov	w1, w0
ffff00000008d01c:	b9445fe0 	ldr	w0, [sp, #1116]
ffff00000008d020:	0b010000 	add	w0, w0, w1
ffff00000008d024:	b9045fe0 	str	w0, [sp, #1116]
ffff00000008d028:	14000069 	b	ffff00000008d1cc <_binary_init_bin_start+0x65c>
ffff00000008d02c:	b94043e1 	ldr	w1, [sp, #64]
ffff00000008d030:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008d034:	7100003f 	cmp	w1, #0x0
ffff00000008d038:	540000ab 	b.lt	ffff00000008d04c <_binary_init_bin_start+0x4dc>  // b.tstop
ffff00000008d03c:	91003c01 	add	x1, x0, #0xf
ffff00000008d040:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff00000008d044:	f90017e1 	str	x1, [sp, #40]
ffff00000008d048:	1400000d 	b	ffff00000008d07c <_binary_init_bin_start+0x50c>
ffff00000008d04c:	11002022 	add	w2, w1, #0x8
ffff00000008d050:	b90043e2 	str	w2, [sp, #64]
ffff00000008d054:	b94043e2 	ldr	w2, [sp, #64]
ffff00000008d058:	7100005f 	cmp	w2, #0x0
ffff00000008d05c:	540000ad 	b.le	ffff00000008d070 <_binary_init_bin_start+0x500>
ffff00000008d060:	91003c01 	add	x1, x0, #0xf
ffff00000008d064:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff00000008d068:	f90017e1 	str	x1, [sp, #40]
ffff00000008d06c:	14000004 	b	ffff00000008d07c <_binary_init_bin_start+0x50c>
ffff00000008d070:	f9401be2 	ldr	x2, [sp, #48]
ffff00000008d074:	93407c20 	sxtw	x0, w1
ffff00000008d078:	8b000040 	add	x0, x2, x0
ffff00000008d07c:	f9400000 	ldr	x0, [x0]
ffff00000008d080:	f9022be0 	str	x0, [sp, #1104]
ffff00000008d084:	f9422be1 	ldr	x1, [sp, #1104]
ffff00000008d088:	910123e0 	add	x0, sp, #0x48
ffff00000008d08c:	aa0103e2 	mov	x2, x1
ffff00000008d090:	b9445fe1 	ldr	w1, [sp, #1116]
ffff00000008d094:	97fffed1 	bl	ffff00000008cbd8 <_binary_init_bin_start+0x68>
ffff00000008d098:	2a0003e1 	mov	w1, w0
ffff00000008d09c:	b9445fe0 	ldr	w0, [sp, #1116]
ffff00000008d0a0:	0b010000 	add	w0, w0, w1
ffff00000008d0a4:	b9045fe0 	str	w0, [sp, #1116]
ffff00000008d0a8:	14000049 	b	ffff00000008d1cc <_binary_init_bin_start+0x65c>
ffff00000008d0ac:	b94043e1 	ldr	w1, [sp, #64]
ffff00000008d0b0:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008d0b4:	7100003f 	cmp	w1, #0x0
ffff00000008d0b8:	540000ab 	b.lt	ffff00000008d0cc <_binary_init_bin_start+0x55c>  // b.tstop
ffff00000008d0bc:	91003c01 	add	x1, x0, #0xf
ffff00000008d0c0:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff00000008d0c4:	f90017e1 	str	x1, [sp, #40]
ffff00000008d0c8:	1400000d 	b	ffff00000008d0fc <_binary_init_bin_start+0x58c>
ffff00000008d0cc:	11002022 	add	w2, w1, #0x8
ffff00000008d0d0:	b90043e2 	str	w2, [sp, #64]
ffff00000008d0d4:	b94043e2 	ldr	w2, [sp, #64]
ffff00000008d0d8:	7100005f 	cmp	w2, #0x0
ffff00000008d0dc:	540000ad 	b.le	ffff00000008d0f0 <_binary_init_bin_start+0x580>
ffff00000008d0e0:	91003c01 	add	x1, x0, #0xf
ffff00000008d0e4:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff00000008d0e8:	f90017e1 	str	x1, [sp, #40]
ffff00000008d0ec:	14000004 	b	ffff00000008d0fc <_binary_init_bin_start+0x58c>
ffff00000008d0f0:	f9401be2 	ldr	x2, [sp, #48]
ffff00000008d0f4:	93407c20 	sxtw	x0, w1
ffff00000008d0f8:	8b000040 	add	x0, x2, x0
ffff00000008d0fc:	f9400000 	ldr	x0, [x0]
ffff00000008d100:	f9022be0 	str	x0, [sp, #1104]
ffff00000008d104:	910123e0 	add	x0, sp, #0x48
ffff00000008d108:	f9422be2 	ldr	x2, [sp, #1104]
ffff00000008d10c:	b9445fe1 	ldr	w1, [sp, #1116]
ffff00000008d110:	97fffef0 	bl	ffff00000008ccd0 <_binary_init_bin_start+0x160>
ffff00000008d114:	2a0003e1 	mov	w1, w0
ffff00000008d118:	b9445fe0 	ldr	w0, [sp, #1116]
ffff00000008d11c:	0b010000 	add	w0, w0, w1
ffff00000008d120:	b9045fe0 	str	w0, [sp, #1116]
ffff00000008d124:	1400002a 	b	ffff00000008d1cc <_binary_init_bin_start+0x65c>
ffff00000008d128:	b94043e1 	ldr	w1, [sp, #64]
ffff00000008d12c:	f94017e0 	ldr	x0, [sp, #40]
ffff00000008d130:	7100003f 	cmp	w1, #0x0
ffff00000008d134:	540000ab 	b.lt	ffff00000008d148 <_binary_init_bin_start+0x5d8>  // b.tstop
ffff00000008d138:	91003c01 	add	x1, x0, #0xf
ffff00000008d13c:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff00000008d140:	f90017e1 	str	x1, [sp, #40]
ffff00000008d144:	1400000d 	b	ffff00000008d178 <_binary_init_bin_start+0x608>
ffff00000008d148:	11002022 	add	w2, w1, #0x8
ffff00000008d14c:	b90043e2 	str	w2, [sp, #64]
ffff00000008d150:	b94043e2 	ldr	w2, [sp, #64]
ffff00000008d154:	7100005f 	cmp	w2, #0x0
ffff00000008d158:	540000ad 	b.le	ffff00000008d16c <_binary_init_bin_start+0x5fc>
ffff00000008d15c:	91003c01 	add	x1, x0, #0xf
ffff00000008d160:	927df021 	and	x1, x1, #0xfffffffffffffff8
ffff00000008d164:	f90017e1 	str	x1, [sp, #40]
ffff00000008d168:	14000004 	b	ffff00000008d178 <_binary_init_bin_start+0x608>
ffff00000008d16c:	f9401be2 	ldr	x2, [sp, #48]
ffff00000008d170:	93407c20 	sxtw	x0, w1
ffff00000008d174:	8b000040 	add	x0, x2, x0
ffff00000008d178:	f9400000 	ldr	x0, [x0]
ffff00000008d17c:	f90227e0 	str	x0, [sp, #1096]
ffff00000008d180:	910123e0 	add	x0, sp, #0x48
ffff00000008d184:	f94227e2 	ldr	x2, [sp, #1096]
ffff00000008d188:	b9445fe1 	ldr	w1, [sp, #1116]
ffff00000008d18c:	97ffff2c 	bl	ffff00000008ce3c <_binary_init_bin_start+0x2cc>
ffff00000008d190:	2a0003e1 	mov	w1, w0
ffff00000008d194:	b9445fe0 	ldr	w0, [sp, #1116]
ffff00000008d198:	0b010000 	add	w0, w0, w1
ffff00000008d19c:	b9045fe0 	str	w0, [sp, #1116]
ffff00000008d1a0:	1400000b 	b	ffff00000008d1cc <_binary_init_bin_start+0x65c>
ffff00000008d1a4:	b9445fe0 	ldr	w0, [sp, #1116]
ffff00000008d1a8:	11000401 	add	w1, w0, #0x1
ffff00000008d1ac:	b9045fe1 	str	w1, [sp, #1116]
ffff00000008d1b0:	93407c00 	sxtw	x0, w0
ffff00000008d1b4:	910123e1 	add	x1, sp, #0x48
ffff00000008d1b8:	528004a2 	mov	w2, #0x25                  	// #37
ffff00000008d1bc:	38206822 	strb	w2, [x1, x0]
ffff00000008d1c0:	b9445be0 	ldr	w0, [sp, #1112]
ffff00000008d1c4:	51000400 	sub	w0, w0, #0x1
ffff00000008d1c8:	b9045be0 	str	w0, [sp, #1112]
ffff00000008d1cc:	b9445be0 	ldr	w0, [sp, #1112]
ffff00000008d1d0:	11000400 	add	w0, w0, #0x1
ffff00000008d1d4:	b9045be0 	str	w0, [sp, #1112]
ffff00000008d1d8:	b9845be0 	ldrsw	x0, [sp, #1112]
ffff00000008d1dc:	f9400fe1 	ldr	x1, [sp, #24]
ffff00000008d1e0:	8b000020 	add	x0, x1, x0
ffff00000008d1e4:	39400000 	ldrb	w0, [x0]
ffff00000008d1e8:	7100001f 	cmp	w0, #0x0
ffff00000008d1ec:	54ffe961 	b.ne	ffff00000008cf18 <_binary_init_bin_start+0x3a8>  // b.any
ffff00000008d1f0:	910123e0 	add	x0, sp, #0x48
ffff00000008d1f4:	b9445fe1 	ldr	w1, [sp, #1116]
ffff00000008d1f8:	94000006 	bl	ffff00000008d210 <_binary_init_bin_start+0x6a0>
ffff00000008d1fc:	b9045fe0 	str	w0, [sp, #1116]
ffff00000008d200:	b9445fe0 	ldr	w0, [sp, #1116]
ffff00000008d204:	a9407bfd 	ldp	x29, x30, [sp]
ffff00000008d208:	911283ff 	add	sp, sp, #0x4a0
ffff00000008d20c:	d65f03c0 	ret
ffff00000008d210:	d10043ff 	sub	sp, sp, #0x10
ffff00000008d214:	d2800008 	mov	x8, #0x0                   	// #0
ffff00000008d218:	a90007e0 	stp	x0, x1, [sp]
ffff00000008d21c:	d2800040 	mov	x0, #0x2                   	// #2
ffff00000008d220:	910003e1 	mov	x1, sp
ffff00000008d224:	d4009a41 	svc	#0x4d2
ffff00000008d228:	910043ff 	add	sp, sp, #0x10
ffff00000008d22c:	d65f03c0 	ret
ffff00000008d230:	d10023ff 	sub	sp, sp, #0x8
ffff00000008d234:	d2800028 	mov	x8, #0x1                   	// #1
ffff00000008d238:	f90003e0 	str	x0, [sp]
ffff00000008d23c:	d2800020 	mov	x0, #0x1                   	// #1
ffff00000008d240:	910003e1 	mov	x1, sp
ffff00000008d244:	d4009a41 	svc	#0x4d2
ffff00000008d248:	910023ff 	add	sp, sp, #0x8
ffff00000008d24c:	d65f03c0 	ret
ffff00000008d250:	d2800048 	mov	x8, #0x2                   	// #2
ffff00000008d254:	d2800000 	mov	x0, #0x0                   	// #0
ffff00000008d258:	d4009a41 	svc	#0x4d2
ffff00000008d25c:	d65f03c0 	ret
ffff00000008d260:	d10023ff 	sub	sp, sp, #0x8
ffff00000008d264:	d2800068 	mov	x8, #0x3                   	// #3
ffff00000008d268:	f90003e0 	str	x0, [sp]
ffff00000008d26c:	d2800020 	mov	x0, #0x1                   	// #1
ffff00000008d270:	910003e1 	mov	x1, sp
ffff00000008d274:	d4009a41 	svc	#0x4d2
ffff00000008d278:	910023ff 	add	sp, sp, #0x8
ffff00000008d27c:	d65f03c0 	ret
ffff00000008d280:	72657355 	.inst	0x72657355 ; undefined
ffff00000008d284:	6f727020 	fcmla	v0.8h, v1.8h, v18.h[1], #270
ffff00000008d288:	73736563 	.inst	0x73736563 ; undefined
ffff00000008d28c:	0d752520 	.inst	0x0d752520 ; undefined
ffff00000008d290:	0000000a 	udf	#10
ffff00000008d294:	00000000 	udf	#0
ffff00000008d298:	33323130 	.inst	0x33323130 ; undefined
ffff00000008d29c:	37363534 	tbnz	w20, #6, ffff000000089940 <pmd_ttbr0+0x940>
ffff00000008d2a0:	00003938 	udf	#14648
ffff00000008d2a4:	00000000 	udf	#0
ffff00000008d2a8:	33323130 	.inst	0x33323130 ; undefined
ffff00000008d2ac:	37363534 	tbnz	w20, #6, ffff000000089950 <pmd_ttbr0+0x950>
ffff00000008d2b0:	42413938 	.inst	0x42413938 ; undefined
ffff00000008d2b4:	46454443 	.inst	0x46454443 ; undefined

ffff00000008d2b8 <pid_num>:
ffff00000008d2b8:	00000001 	udf	#1

Disassembly of section .debug_line:

0000000000000000 <.debug_line>:
       0:	00000077 	udf	#119
       4:	00080005 	.inst	0x00080005 ; undefined
       8:	0000002a 	udf	#42
       c:	fb010104 	.inst	0xfb010104 ; undefined
      10:	01000d0e 	.inst	0x01000d0e ; undefined
      14:	00010101 	.inst	0x00010101 ; undefined
      18:	00010000 	.inst	0x00010000 ; undefined
      1c:	01010100 	.inst	0x01010100 ; undefined
      20:	0000011f 	udf	#287
      24:	01020000 	.inst	0x01020000 ; undefined
      28:	020f021f 	.inst	0x020f021f ; undefined
      2c:	0000001d 	udf	#29
      30:	00001d00 	udf	#7424
      34:	09000000 	.inst	0x09000000 ; undefined
      38:	08000002 	stxrb	w0, w2, [x0]
      3c:	ff000000 	.inst	0xff000000 ; undefined
      40:	212119ff 	.inst	0x212119ff ; undefined
      44:	21232321 	.inst	0x21232321 ; undefined
      48:	21212121 	.inst	0x21212121 ; undefined
      4c:	24212121 	cmplo	p1.b, p0/z, z9.b, #4
      50:	23212121 	.inst	0x23212121 ; undefined
      54:	21212121 	.inst	0x21212121 ; undefined
      58:	22212123 	.inst	0x22212123 ; undefined
      5c:	22212221 	.inst	0x22212221 ; undefined
      60:	22212223 	.inst	0x22212223 ; undefined
      64:	22212121 	.inst	0x22212121 ; undefined
      68:	21212121 	.inst	0x21212121 ; undefined
      6c:	21222122 	.inst	0x21222122 ; undefined
      70:	21232122 	.inst	0x21232122 ; undefined
      74:	10022124 	adr	x4, 4498 <MAIR_ATTR+0x98>
      78:	90010100 	adrp	x0, 2020000 <PAGE_SIZE+0x1e20000>
      7c:	05000000 	orr	z0.s, z0.s, #0x1
      80:	5b000800 	.inst	0x5b000800 ; undefined
      84:	04000000 	add	z0.b, p0/m, z0.b, z0.b
      88:	0efb0101 	.inst	0x0efb0101 ; undefined
      8c:	0101000d 	.inst	0x0101000d ; undefined
      90:	00000101 	udf	#257
      94:	00000100 	udf	#256
      98:	1f010101 	fmadd	s1, s8, s1, s0
      9c:	00000002 	udf	#2
      a0:	00002b00 	udf	#11008
      a4:	1f010200 	fmadd	s0, s16, s1, s0
      a8:	240b0f02 	cmphs	p2.b, p3/z, z24.b, z11.b
      ac:	00000000 	udf	#0
      b0:	00000024 	udf	#36
      b4:	00007a00 	udf	#31232
      b8:	00840000 	.inst	0x00840000 ; undefined
      bc:	8e000000 	.inst	0x8e000000 ; undefined
      c0:	00000000 	udf	#0
      c4:	00000098 	udf	#152
      c8:	00009f00 	udf	#40704
      cc:	00a80000 	.inst	0x00a80000 ; undefined
      d0:	af000000 	.inst	0xaf000000 ; undefined
      d4:	01000000 	.inst	0x01000000 ; undefined
      d8:	000000bc 	udf	#188
      dc:	0000c200 	udf	#49664
      e0:	01050000 	.inst	0x01050000 ; undefined
      e4:	10020900 	adr	x0, 4204 <_binary_init_bin_size+0x3abc>
      e8:	00000801 	udf	#2049
      ec:	03ffff00 	.inst	0x03ffff00 ; undefined
      f0:	0505010c 	.inst	0x0505010c ; undefined
      f4:	2d05212f 	stp	s15, s8, [x9, #40]
      f8:	0005053d 	.inst	0x0005053d ; undefined
      fc:	2e010402 	.inst	0x2e010402 ; undefined
     100:	2121215a 	.inst	0x2121215a ; undefined
     104:	05212121 	mov	z1.b, b9
     108:	03022101 	.inst	0x03022101 ; undefined
     10c:	72010100 	ands	w0, w8, #0x80000000
     110:	05000000 	orr	z0.s, z0.s, #0x1
     114:	2a000800 	orr	w0, w0, w0, lsl #2
     118:	04000000 	add	z0.b, p0/m, z0.b, z0.b
     11c:	0efb0101 	.inst	0x0efb0101 ; undefined
     120:	0101000d 	.inst	0x0101000d ; undefined
     124:	00000101 	udf	#257
     128:	00000100 	udf	#256
     12c:	1f010101 	fmadd	s1, s8, s1, s0
     130:	00000001 	udf	#1
     134:	1f010200 	fmadd	s0, s16, s1, s0
     138:	ca020f02 	eor	x2, x24, x2, lsl #3
     13c:	00000000 	udf	#0
     140:	000000ca 	udf	#202
     144:	02090000 	.inst	0x02090000 ; undefined
     148:	0008016c 	.inst	0x0008016c ; undefined
     14c:	ffff0000 	.inst	0xffff0000 ; undefined
     150:	21010a03 	.inst	0x21010a03 ; undefined
     154:	21212321 	.inst	0x21212321 ; undefined
     158:	21232123 	.inst	0x21232123 ; undefined
     15c:	21232123 	.inst	0x21232123 ; undefined
     160:	21232321 	.inst	0x21232321 ; undefined
     164:	21222123 	.inst	0x21222123 ; undefined
     168:	22212121 	.inst	0x22212121 ; undefined
     16c:	22212423 	.inst	0x22212423 ; undefined
     170:	21212122 	.inst	0x21212122 ; undefined
     174:	21212321 	.inst	0x21212321 ; undefined
     178:	21212321 	.inst	0x21212321 ; undefined
     17c:	23212221 	.inst	0x23212221 ; undefined
     180:	01000102 	.inst	0x01000102 ; undefined
     184:	0000f701 	udf	#63233
     188:	08000500 	stxrb	w0, w0, [x8]
     18c:	00004200 	udf	#16896
     190:	01010400 	.inst	0x01010400 ; undefined
     194:	000d0efb 	.inst	0x000d0efb ; undefined
     198:	01010101 	.inst	0x01010101 ; undefined
     19c:	01000000 	.inst	0x01000000 ; undefined
     1a0:	01010000 	.inst	0x01010000 ; undefined
     1a4:	00021f01 	.inst	0x00021f01 ; undefined
     1a8:	2b000000 	adds	w0, w0, w0
     1ac:	02000000 	.inst	0x02000000 ; undefined
     1b0:	0f021f01 	.inst	0x0f021f01 ; undefined
     1b4:	0000d006 	udf	#53254
     1b8:	00d00000 	.inst	0x00d00000 ; undefined
     1bc:	af000000 	.inst	0xaf000000 ; undefined
     1c0:	01000000 	.inst	0x01000000 ; undefined
     1c4:	000000bc 	udf	#188
     1c8:	00007a00 	udf	#31232
     1cc:	00840000 	.inst	0x00840000 ; undefined
     1d0:	05000000 	orr	z0.s, z0.s, #0x1
     1d4:	02090001 	.inst	0x02090001 ; undefined
     1d8:	00080224 	.inst	0x00080224 ; undefined
     1dc:	ffff0000 	.inst	0xffff0000 ; undefined
     1e0:	4b100518 	sub	w24, w8, w16, lsl #1
     1e4:	05300905 	ext	z5.b, z5.b, z8.b, #130
     1e8:	04020008 	.inst	0x04020008 ; undefined
     1ec:	14053c01 	b	14f1f0 <TCR_T1SZ+0x4f1f0>
     1f0:	01053d3d 	.inst	0x01053d3d ; undefined
     1f4:	1d0d0542 	cpyp	[x2]!, [x13]!, x10!
     1f8:	052e1a05 	ext	z5.b, z5.b, z16.b, #118  // note: expected `cpym' after previous `cpyp'
     1fc:	01052f14 	.inst	0x01052f14 ; undefined
     200:	09053f3e 	.inst	0x09053f3e ; undefined
     204:	0008053f 	.inst	0x0008053f ; undefined
     208:	3c010402 	str	b2, [x0], #16
     20c:	053d1005 	ext	z5.b, z5.b, z0.b, #236
     210:	1605310a 	b	fffffffff814c638 <FS_BASE+0xffffc814c638>
     214:	2e10053d 	.inst	0x2e10053d ; undefined
     218:	05300d05 	ext	z5.b, z5.b, z8.b, #131
     21c:	14052e08 	b	14ba3c <TCR_T1SZ+0x4ba3c>
     220:	310c052f 	adds	w15, w9, #0x301
     224:	31210105 	adds	w5, w8, #0x840
     228:	052f1105 	ext	z5.b, z5.b, z8.b, #124
     22c:	01052e18 	.inst	0x01052e18 ; undefined
     230:	1205313d 	and	w29, w9, #0xf80000ff
     234:	052f3d3d 	.inst	0x052f3d3d ; undefined
     238:	2705220b 	.inst	0x2705220b ; undefined
     23c:	2e0c0521 	.inst	0x2e0c0521 ; undefined
     240:	053d2105 	mov	z5.b, z8.b[14]
     244:	12052e18 	and	w24, w16, #0xf800007f
     248:	3015052f 	adr	x15, 2a2ed <MAIR_ATTR+0x25eed>
     24c:	052e1005 	ext	z5.b, z5.b, z0.b, #116
     250:	0d052f1c 	.inst	0x0d052f1c ; undefined
     254:	1c1d0534 	ldr	s20, 3a2f8 <MAIR_ATTR+0x35ef8>
     258:	052e1505 	ext	z5.b, z5.b, z8.b, #117
     25c:	0d052f1c 	.inst	0x0d052f1c ; undefined
     260:	230e053f 	.inst	0x230e053f ; undefined
     264:	052f1105 	ext	z5.b, z5.b, z8.b, #124
     268:	04020014 	.inst	0x04020014 ; undefined
     26c:	3c700301 	ldbfaddl	h16, h1, [x24]
     270:	0c030d05 	.inst	0x0c030d05 ; undefined
     274:	270c054a 	.inst	0x270c054a ; undefined
     278:	02210105 	.inst	0x02210105 ; undefined
     27c:	01010002 	.inst	0x01010002 ; undefined
     280:	000000da 	udf	#218
     284:	00080005 	.inst	0x00080005 ; undefined
     288:	00000038 	udf	#56
     28c:	fb010104 	.inst	0xfb010104 ; undefined
     290:	01000d0e 	.inst	0x01000d0e ; undefined
     294:	00010101 	.inst	0x00010101 ; undefined
     298:	00010000 	.inst	0x00010000 ; undefined
     29c:	01010100 	.inst	0x01010100 ; undefined
     2a0:	0000021f 	udf	#543
     2a4:	002b0000 	.inst	0x002b0000 ; undefined
     2a8:	01020000 	.inst	0x01020000 ; undefined
     2ac:	040f021f 	.inst	0x040f021f ; undefined
     2b0:	000000d6 	udf	#214
     2b4:	0000d600 	udf	#54784
     2b8:	00af0000 	.inst	0x00af0000 ; undefined
     2bc:	bc010000 	stur	s0, [x0, #16]
     2c0:	00000000 	udf	#0
     2c4:	09000105 	.inst	0x09000105 ; undefined
     2c8:	0803ec02 	stlxrb	w3, w2, [x0]
     2cc:	ff000000 	.inst	0xff000000 ; undefined
     2d0:	0b0516ff 	add	wzr, w23, w5, lsl #5
     2d4:	000c053d 	.inst	0x000c053d ; undefined
     2d8:	20010402 	.inst	0x20010402 ; undefined
     2dc:	02001e05 	.inst	0x02001e05 ; undefined
     2e0:	054a0204 	.inst	0x054a0204 ; undefined
     2e4:	0402000c 	.inst	0x0402000c ; undefined
     2e8:	05052002 	.inst	0x05052002 ; undefined
     2ec:	6701052f 	.inst	0x6701052f ; undefined
     2f0:	2f0c053f 	ushr	v31.8b, v9.8b, #4
     2f4:	01040200 	.inst	0x01040200 ; undefined
     2f8:	01054a06 	.inst	0x01054a06 ; undefined
     2fc:	05312106 	mov	z6.b, z8.b[8]
     300:	05053d0e 	.inst	0x05053d0e ; undefined
     304:	211a0520 	.inst	0x211a0520 ; undefined
     308:	053c0905 	ext	z5.b, z5.b, z8.b, #226
     30c:	04020029 	.inst	0x04020029 ; undefined
     310:	1b052d01 	madd	w1, w8, w5, w11
     314:	02040200 	.inst	0x02040200 ; undefined
     318:	001f053c 	.inst	0x001f053c ; undefined
     31c:	4a020402 	eor	w2, w0, w2, lsl #1
     320:	4d310105 	.inst	0x4d310105 ; undefined
     324:	052f1705 	ext	z5.b, z5.b, z24.b, #125
     328:	08055a10 	stxrb	w5, w16, [x16]
     32c:	2f13052e 	ushr	v14.4h, v9.4h, #13
     330:	05300c05 	ext	z5.b, z5.b, z0.b, #131
     334:	054d3d0d 	.inst	0x054d3d0d ; undefined
     338:	01053109 	.inst	0x01053109 ; undefined
     33c:	0505405a 	.inst	0x0505405a ; undefined
     340:	5b100531 	.inst	0x5b100531 ; undefined
     344:	3d590e05 	ldr	b5, [x16, #1603]
     348:	5b590505 	.inst	0x5b590505 ; undefined
     34c:	2f592f59 	.inst	0x2f592f59 ; undefined
     350:	5959595a 	.inst	0x5959595a ; undefined
     354:	01055959 	.inst	0x01055959 ; undefined
     358:	00030259 	.inst	0x00030259 ; undefined
     35c:	01fb0101 	.inst	0x01fb0101 ; undefined
     360:	00050000 	.inst	0x00050000 ; undefined
     364:	00420008 	.inst	0x00420008 ; undefined
     368:	01040000 	.inst	0x01040000 ; undefined
     36c:	0d0efb01 	.inst	0x0d0efb01 ; undefined
     370:	01010100 	.inst	0x01010100 ; undefined
     374:	00000001 	udf	#1
     378:	01000001 	.inst	0x01000001 ; undefined
     37c:	021f0101 	.inst	0x021f0101 ; undefined
     380:	00000000 	udf	#0
     384:	0000002b 	udf	#43
     388:	021f0102 	.inst	0x021f0102 ; undefined
     38c:	00dd060f 	.inst	0x00dd060f ; undefined
     390:	dd000000 	.inst	0xdd000000 ; undefined
     394:	00000000 	udf	#0
     398:	000000af 	udf	#175
     39c:	0000e501 	udf	#58625
     3a0:	00ee0100 	.inst	0x00ee0100 ; undefined
     3a4:	a8000000 	stnp	x0, x0, [x0]
     3a8:	00000000 	udf	#0
     3ac:	09000105 	.inst	0x09000105 ; undefined
     3b0:	08066802 	stxrb	w6, w2, [x0]
     3b4:	ff000000 	.inst	0xff000000 ; undefined
     3b8:	090517ff 	.inst	0x090517ff ; undefined
     3bc:	2210054b 	.inst	0x2210054b ; undefined
     3c0:	05200505 	ext	z5.b, z5.b, z8.b, #1
     3c4:	18052124 	ldr	w4, a7e8 <MAIR_ATTR+0x63e8>
     3c8:	4a0f053c 	eor	w28, w9, w15, lsl #1
     3cc:	052e2405 	dupq	z5.h, z0.h[3]
     3d0:	3105201c 	adds	w28, w0, #0x148
     3d4:	01040200 	.inst	0x01040200 ; undefined
     3d8:	001b051f 	.inst	0x001b051f ; undefined
     3dc:	3c020402 	str	b2, [x0], #32
     3e0:	02002305 	.inst	0x02002305 ; undefined
     3e4:	054a0204 	.inst	0x054a0204 ; undefined
     3e8:	0105320c 	.inst	0x0105320c ; undefined
     3ec:	0a053121 	and	w1, w9, w5, lsl #12
     3f0:	4b09054c 	sub	w12, w10, w9, lsl #1
     3f4:	05233305 	tbl	z5.b, {z24.b}, z3.b
     3f8:	2b052e1b 	adds	w27, w16, w5, lsl #11
     3fc:	2e1f053c 	.inst	0x2e1f053c ; undefined
     400:	053d1005 	ext	z5.b, z5.b, z0.b, #236
     404:	0e053d15 	umov	w21, v8.b[2]
     408:	3c05053e 	str	b30, [x9], #80
     40c:	05211805 	ext	z5.b, z5.b, z0.b, #14
     410:	2b054a0f 	adds	w15, w16, w5, lsl #18
     414:	3c1c052e 	str	b14, [x9], #-64
     418:	02002305 	.inst	0x02002305 ; undefined
     41c:	051f0104 	mov	z4.b, p15/z, #8
     420:	0402001c 	.inst	0x0402001c ; undefined
     424:	14053c02 	b	14f42c <TCR_T1SZ+0x4f42c>
     428:	4a0b0540 	eor	w0, w10, w11, lsl #1
     42c:	052e1805 	ext	z5.b, z5.b, z0.b, #118
     430:	01053011 	.inst	0x01053011 ; undefined
     434:	0a05312f 	and	w15, w9, w5, lsl #12
     438:	7609054b 	.inst	0x7609054b ; undefined
     43c:	05233305 	tbl	z5.b, {z24.b}, z3.b
     440:	2b059e1b 	.inst	0x2b059e1b ; undefined
     444:	2e1f053c 	.inst	0x2e1f053c ; undefined
     448:	053d1005 	ext	z5.b, z5.b, z0.b, #236
     44c:	0e056715 	.inst	0x0e056715 ; undefined
     450:	3c05053e 	str	b30, [x9], #80
     454:	05211805 	ext	z5.b, z5.b, z0.b, #14
     458:	2b054a0f 	adds	w15, w16, w5, lsl #18
     45c:	3c1c052e 	str	b14, [x9], #-64
     460:	02002305 	.inst	0x02002305 ; undefined
     464:	051f0104 	mov	z4.b, p15/z, #8
     468:	0402001c 	.inst	0x0402001c ; undefined
     46c:	0c053c02 	.inst	0x0c053c02 ; undefined
     470:	21010540 	.inst	0x21010540 ; undefined
     474:	59090531 	.inst	0x59090531 ; undefined
     478:	05220805 	ext	z5.b, z5.b, z0.b, #18
     47c:	18053d10 	ldr	w16, ac1c <MAIR_ATTR+0x681c>
     480:	4a0f053d 	eor	w29, w9, w15, lsl #1
     484:	052e1c05 	ext	z5.b, z5.b, z0.b, #119
     488:	0d052f0e 	.inst	0x0d052f0e ; undefined
     48c:	000a0531 	.inst	0x000a0531 ; undefined
     490:	66010402 	.inst	0x66010402 ; undefined
     494:	053d0c05 	ext	z5.b, z5.b, z0.b, #235
     498:	05312101 	mov	z1.b, z8.b[8]
     49c:	05054b0e 	.inst	0x05054b0e ; undefined
     4a0:	211a0520 	.inst	0x211a0520 ; undefined
     4a4:	053c0905 	ext	z5.b, z5.b, z8.b, #226
     4a8:	04020020 	.inst	0x04020020 ; undefined
     4ac:	17052d01 	b	fffffffffc14b8b0 <FS_BASE+0xffffcc14b8b0>
     4b0:	02040200 	.inst	0x02040200 ; undefined
     4b4:	4d01053c 	.inst	0x4d01053c ; undefined
     4b8:	ae09054d 	.inst	0xae09054d ; undefined
     4bc:	05210d05 	ext	z5.b, z5.b, z8.b, #11
     4c0:	0505210b 	.inst	0x0505210b ; undefined
     4c4:	920e0523 	and	x3, x9, #0xc0000000c0000
     4c8:	05200505 	ext	z5.b, z5.b, z8.b, #1
     4cc:	0c052113 	.inst	0x0c052113 ; undefined
     4d0:	2f2b054a 	ushr	v10.2s, v10.2s, #21
     4d4:	053c1f05 	ext	z5.b, z5.b, z24.b, #231
     4d8:	23053c2b 	.inst	0x23053c2b ; undefined
     4dc:	4d0d0520 	.inst	0x4d0d0520 ; undefined
     4e0:	053c1c05 	ext	z5.b, z5.b, z0.b, #231
     4e4:	0d05201b 	.inst	0x0d05201b ; undefined
     4e8:	ca1d053c 	eor	x28, x9, x29, lsl #1
     4ec:	59082405 	.inst	0x59082405 ; undefined
     4f0:	02002105 	.inst	0x02002105 ; undefined
     4f4:	05660104 	ext	z4.b, {z8.b-z9.b}, #48
     4f8:	1d053d15 	.inst	0x1d053d15 ; undefined
     4fc:	08240523 	.inst	0x08240523 ; undefined
     500:	00210559 	.inst	0x00210559 ; undefined
     504:	66010402 	.inst	0x66010402 ; undefined
     508:	053d1505 	ext	z5.b, z5.b, z8.b, #237
     50c:	2405231d 	cmpne	p13.b, p0/z, z24.b, z5.d
     510:	21055908 	.inst	0x21055908 ; undefined
     514:	01040200 	.inst	0x01040200 ; undefined
     518:	3d150558 	str	b24, [x10, #1345]
     51c:	05231c05 	ext	z5.b, z5.b, z0.b, #31
     520:	05590824 	mov	z4.h, p9/z, #65
     524:	04020021 	.inst	0x04020021 ; undefined
     528:	15055801 	b	415652c <FS_SIZE+0xfa052c>
     52c:	2327053d 	.inst	0x2327053d ; undefined
     530:	053c2b05 	tbl	z5.b, {z24.b-z25.b}, z28.b
     534:	29054b16 	stp	w22, w18, [x24, #40]
     538:	01040200 	.inst	0x01040200 ; undefined
     53c:	053c6403 	zip2	z3.b, z0.b, z28.b
     540:	0402001b 	.inst	0x0402001b ; undefined
     544:	1f053c02 	fmadd	s2, s0, s5, s15
     548:	02040200 	.inst	0x02040200 ; undefined
     54c:	0305054a 	.inst	0x0305054a ; undefined
     550:	0c052e21 	.inst	0x0c052e21 ; undefined
     554:	2101053f 	.inst	0x2101053f ; undefined
     558:	01000302 	.inst	0x01000302 ; undefined
     55c:	00005c01 	udf	#23553
     560:	08000500 	stxrb	w0, w0, [x8]
     564:	00003800 	udf	#14336
     568:	01010400 	.inst	0x01010400 ; undefined
     56c:	000d0efb 	.inst	0x000d0efb ; undefined
     570:	01010101 	.inst	0x01010101 ; undefined
     574:	01000000 	.inst	0x01000000 ; undefined
     578:	01010000 	.inst	0x01010000 ; undefined
     57c:	00021f01 	.inst	0x00021f01 ; undefined
     580:	2b000000 	adds	w0, w0, w0
     584:	02000000 	.inst	0x02000000 ; undefined
     588:	0f021f01 	.inst	0x0f021f01 ; undefined
     58c:	0000f904 	udf	#63748
     590:	00f90000 	.inst	0x00f90000 ; undefined
     594:	af000000 	.inst	0xaf000000 ; undefined
     598:	01000000 	.inst	0x01000000 ; undefined
     59c:	000000c2 	udf	#194
     5a0:	00010500 	.inst	0x00010500 ; undefined
     5a4:	0cf40209 	.inst	0x0cf40209 ; undefined
     5a8:	00000008 	udf	#8
     5ac:	0516ffff 	.inst	0x0516ffff ; undefined
     5b0:	3d3d4b05 	str	b5, [x24, #3922]
     5b4:	5a0b053d 	.inst	0x5a0b053d ; undefined
     5b8:	01000202 	.inst	0x01000202 ; undefined
     5bc:	0000b001 	udf	#45057
     5c0:	08000500 	stxrb	w0, w0, [x8]
     5c4:	00002a00 	udf	#10752
     5c8:	01010400 	.inst	0x01010400 ; undefined
     5cc:	000d0efb 	.inst	0x000d0efb ; undefined
     5d0:	01010101 	.inst	0x01010101 ; undefined
     5d4:	01000000 	.inst	0x01000000 ; undefined
     5d8:	01010000 	.inst	0x01010000 ; undefined
     5dc:	00011f01 	.inst	0x00011f01 ; undefined
     5e0:	02000000 	.inst	0x02000000 ; undefined
     5e4:	0f021f01 	.inst	0x0f021f01 ; undefined
     5e8:	00010102 	.inst	0x00010102 ; undefined
     5ec:	01010000 	.inst	0x01010000 ; undefined
     5f0:	00000000 	udf	#0
     5f4:	10000209 	adr	x9, 634 <TCR_T0SZ+0x624>
     5f8:	00000008 	udf	#8
     5fc:	c803ffff 	stlxr	w3, xzr, [sp]
     600:	e8080100 	sttnp	x0, x0, [x8, #128]
     604:	e808e808 	sttnp	x8, x26, [x0, #136]
     608:	e808e808 	sttnp	x8, x26, [x0, #136]
     60c:	e808e808 	sttnp	x8, x26, [x0, #136]
     610:	e808e808 	sttnp	x8, x26, [x0, #136]
     614:	e808e808 	sttnp	x8, x26, [x0, #136]
     618:	e808e808 	sttnp	x8, x26, [x0, #136]
     61c:	e808e808 	sttnp	x8, x26, [x0, #136]
     620:	21212423 	.inst	0x21212423 ; undefined
     624:	21330821 	.inst	0x21330821 ; undefined
     628:	21210822 	.inst	0x21210822 ; undefined
     62c:	21212121 	.inst	0x21212121 ; undefined
     630:	21088521 	.inst	0x21088521 ; undefined
     634:	21088521 	.inst	0x21088521 ; undefined
     638:	23218521 	.inst	0x23218521 ; undefined
     63c:	21222321 	.inst	0x21222321 ; undefined
     640:	21222121 	.inst	0x21222121 ; undefined
     644:	21232122 	.inst	0x21232122 ; undefined
     648:	21232123 	.inst	0x21232123 ; undefined
     64c:	21212121 	.inst	0x21212121 ; undefined
     650:	21212221 	.inst	0x21212221 ; undefined
     654:	21212122 	.inst	0x21212122 ; undefined
     658:	22212121 	.inst	0x22212121 ; undefined
     65c:	21212123 	.inst	0x21212123 ; undefined
     660:	21232121 	.inst	0x21232121 ; undefined
     664:	21212223 	.inst	0x21212223 ; undefined
     668:	22212121 	.inst	0x22212121 ; undefined
     66c:	01000102 	.inst	0x01000102 ; undefined
     670:	00014601 	.inst	0x00014601 ; undefined
     674:	08000500 	stxrb	w0, w0, [x8]
     678:	00005100 	udf	#20736
     67c:	01010400 	.inst	0x01010400 ; undefined
     680:	000d0efb 	.inst	0x000d0efb ; undefined
     684:	01010101 	.inst	0x01010101 ; undefined
     688:	01000000 	.inst	0x01000000 ; undefined
     68c:	01010000 	.inst	0x01010000 ; undefined
     690:	00021f01 	.inst	0x00021f01 ; undefined
     694:	2b000000 	adds	w0, w0, w0
     698:	02000000 	.inst	0x02000000 ; undefined
     69c:	0f021f01 	.inst	0x0f021f01 ; undefined
     6a0:	00010b09 	.inst	0x00010b09 ; undefined
     6a4:	010b0000 	.inst	0x010b0000 ; undefined
     6a8:	af000000 	.inst	0xaf000000 ; undefined
     6ac:	01000000 	.inst	0x01000000 ; undefined
     6b0:	000000bc 	udf	#188
     6b4:	00007a00 	udf	#31232
     6b8:	00840000 	.inst	0x00840000 ; undefined
     6bc:	a8000000 	stnp	x0, x0, [x0]
     6c0:	00000000 	udf	#0
     6c4:	000000c2 	udf	#194
     6c8:	00008e00 	udf	#36352
     6cc:	01050000 	.inst	0x01050000 ; undefined
     6d0:	0c020900 	.inst	0x0c020900 ; undefined
     6d4:	0000081a 	udf	#2074
     6d8:	03ffff00 	.inst	0x03ffff00 ; undefined
     6dc:	0c050112 	.inst	0x0c050112 ; undefined
     6e0:	3d010513 	str	b19, [x8, #65]
     6e4:	2f050523 	mvni	v3.2s, #0xa9
     6e8:	055a5959 	mov	z25.h, p10/m, #-54
     6ec:	053f5901 	.inst	0x053f5901 ; undefined
     6f0:	28052f16 	stnp	w22, w11, [x24, #40]
     6f4:	01040200 	.inst	0x01040200 ; undefined
     6f8:	0014052e 	.inst	0x0014052e ; undefined
     6fc:	58010402 	ldr	x2, 277c <_binary_init_bin_size+0x2034>
     700:	213d0505 	.inst	0x213d0505 ; undefined
     704:	3f590105 	.inst	0x3f590105 ; undefined
     708:	052f2105 	mov	z5.b, z8.b[7]
     70c:	053d2f12 	tbx	z18.b, z24.b, z29.b
     710:	19053e0b 	.inst	0x19053e0b ; undefined
     714:	300a0522 	adr	x2, 147b9 <MAIR_ATTR+0x103b9>
     718:	052e1005 	ext	z5.b, z5.b, z0.b, #116
     71c:	0c053e0e 	.inst	0x0c053e0e ; undefined
     720:	301a052e 	adr	x14, 347c5 <MAIR_ATTR+0x303c5>
     724:	053e1805 	ext	z5.b, z5.b, z0.b, #246
     728:	24053d10 	cmpne	p0.b, p7/z, z8.b, z5.d
     72c:	3e16053d 	.inst	0x3e16053d ; undefined
     730:	053d0d05 	ext	z5.b, z5.b, z8.b, #235
     734:	0d054c11 	.inst	0x0d054c11 ; undefined
     738:	230e052f 	.inst	0x230e052f ; undefined
     73c:	052f0d05 	ext	z5.b, z5.b, z8.b, #123
     740:	04020010 	.inst	0x04020010 ; undefined
     744:	3c6a0301 	ldbfaddl	h10, h1, [x24]
     748:	18030105 	ldr	w5, 6768 <MAIR_ATTR+0x2368>
     74c:	17054d3c 	b	fffffffffc153c3c <FS_BASE+0xffffcc153c3c>
     750:	2f10052f 	ushr	v15.4h, v9.4h, #16
     754:	052e0805 	ext	z5.b, z5.b, z0.b, #114
     758:	0a052f0e 	and	w14, w24, w5, lsl #11
     75c:	34090575 	cbz	w21, 12808 <MAIR_ATTR+0xe408>
     760:	3f4c0105 	.inst	0x3f4c0105 ; undefined
     764:	052f0c05 	ext	z5.b, z5.b, z0.b, #123
     768:	05314b01 	.inst	0x05314b01 ; undefined
     76c:	0f053e09 	.inst	0x0f053e09 ; undefined
     770:	2e050522 	.inst	0x2e050522 ; undefined
     774:	05920d05 	mov	z5.s, p2/z, #104
     778:	05328313 	.inst	0x05328313 ; undefined
     77c:	10055915 	adr	x21, b29c <MAIR_ATTR+0x6e9c>
     780:	2f11052e 	ushr	v14.4h, v9.4h, #15
     784:	05211a05 	ext	z5.b, z5.b, z16.b, #14
     788:	2e0c030d 	ext	v13.8b, v24.8b, v12.8b, #0
     78c:	77031705 	.inst	0x77031705 ; undefined
     790:	2f190520 	ushr	v0.4h, v9.4h, #7
     794:	052e1405 	ext	z5.b, z5.b, z0.b, #117
     798:	0d052f15 	.inst	0x0d052f15 ; undefined
     79c:	1c150527 	ldr	s7, 2a840 <MAIR_ATTR+0x26440>
     7a0:	053d1b05 	ext	z5.b, z5.b, z24.b, #238
     7a4:	0a03340d 	and	w13, w0, w3, lsl #13
     7a8:	1305232e 	sbfx	w14, w25, #5, #4
     7ac:	3108053d 	adds	w29, w9, #0x201
     7b0:	053d0905 	ext	z5.b, z5.b, z8.b, #234
     7b4:	03022201 	.inst	0x03022201 ; undefined
     7b8:	8e010100 	.inst	0x8e010100 ; undefined
     7bc:	05000000 	orr	z0.s, z0.s, #0x1
     7c0:	2a000800 	orr	w0, w0, w0, lsl #2
     7c4:	04000000 	add	z0.b, p0/m, z0.b, z0.b
     7c8:	0efb0101 	.inst	0x0efb0101 ; undefined
     7cc:	0101000d 	.inst	0x0101000d ; undefined
     7d0:	00000101 	udf	#257
     7d4:	00000100 	udf	#256
     7d8:	1f010101 	fmadd	s1, s8, s1, s0
     7dc:	00000001 	udf	#1
     7e0:	1f010200 	fmadd	s0, s16, s1, s0
     7e4:	15020f02 	b	40843ec <FS_SIZE+0xece3ec>
     7e8:	00000001 	udf	#1
     7ec:	00000115 	udf	#277
     7f0:	02090000 	.inst	0x02090000 ; undefined
     7f4:	00082000 	.inst	0x00082000 ; undefined
     7f8:	ffff0000 	.inst	0xffff0000 ; undefined
     7fc:	21010f03 	.inst	0x21010f03 ; undefined
     800:	21212123 	.inst	0x21212123 ; undefined
     804:	22212322 	.inst	0x22212322 ; undefined
     808:	22212221 	.inst	0x22212221 ; undefined
     80c:	21212221 	.inst	0x21212221 ; undefined
     810:	25222121 	.inst	0x25222121 ; undefined
     814:	22222121 	.inst	0x22222121 ; undefined
     818:	22212121 	.inst	0x22212121 ; undefined
     81c:	21232121 	.inst	0x21232121 ; undefined
     820:	21222121 	.inst	0x21222121 ; undefined
     824:	22212122 	.inst	0x22212122 ; undefined
     828:	21212321 	.inst	0x21212321 ; undefined
     82c:	21212221 	.inst	0x21212221 ; undefined
     830:	21222121 	.inst	0x21222121 ; undefined
     834:	23212122 	.inst	0x23212122 ; undefined
     838:	24212121 	cmplo	p1.b, p0/z, z9.b, #4
     83c:	22212121 	.inst	0x22212121 ; undefined
     840:	22212121 	.inst	0x22212121 ; undefined
     844:	02222121 	.inst	0x02222121 ; undefined
     848:	01003fbc 	.inst	0x01003fbc ; undefined
     84c:	0002f201 	.inst	0x0002f201 ; undefined
     850:	08000500 	stxrb	w0, w0, [x8]
     854:	00004c00 	udf	#19456
     858:	01010400 	.inst	0x01010400 ; undefined
     85c:	000d0efb 	.inst	0x000d0efb ; undefined
     860:	01010101 	.inst	0x01010101 ; undefined
     864:	01000000 	.inst	0x01000000 ; undefined
     868:	01010000 	.inst	0x01010000 ; undefined
     86c:	00021f01 	.inst	0x00021f01 ; undefined
     870:	2b000000 	adds	w0, w0, w0
     874:	02000000 	.inst	0x02000000 ; undefined
     878:	0f021f01 	.inst	0x0f021f01 ; undefined
     87c:	00011b08 	.inst	0x00011b08 ; undefined
     880:	011b0000 	.inst	0x011b0000 ; undefined
     884:	bc000000 	stur	s0, [x0]
     888:	00000000 	udf	#0
     88c:	00000098 	udf	#152
     890:	0000c200 	udf	#49664
     894:	01240000 	.inst	0x01240000 ; undefined
     898:	af000000 	.inst	0xaf000000 ; undefined
     89c:	01000000 	.inst	0x01000000 ; undefined
     8a0:	0000009f 	udf	#159
     8a4:	00010500 	.inst	0x00010500 ; undefined
     8a8:	a0100209 	ldnt1b	{z8.b-z9.b}, pn8/z, [x16, x16]
     8ac:	00000008 	udf	#8
     8b0:	1603ffff 	b	fffffffff81008ac <FS_BASE+0xffffc81008ac>
     8b4:	4b1b0501 	sub	w1, w8, w27, lsl #1
     8b8:	053c1305 	ext	z5.b, z5.b, z24.b, #228
     8bc:	13052e05 	sbfx	w5, w16, #5, #7
     8c0:	2e0c0521 	.inst	0x2e0c0521 ; undefined
     8c4:	054b0d05 	.inst	0x054b0d05 ; undefined
     8c8:	04020043 	.inst	0x04020043 ; undefined
     8cc:	2b052c01 	adds	w1, w0, w5, lsl #11
     8d0:	02040200 	.inst	0x02040200 ; undefined
     8d4:	0037053c 	.inst	0x0037053c ; undefined
     8d8:	2e020402 	.inst	0x2e020402 ; undefined
     8dc:	4d410105 	.inst	0x4d410105 ; undefined
     8e0:	003d0505 	.inst	0x003d0505 ; undefined
     8e4:	06010402 	.inst	0x06010402 ; undefined
     8e8:	004b064a 	.inst	0x004b064a ; undefined
     8ec:	06010402 	.inst	0x06010402 ; undefined
     8f0:	004b0658 	.inst	0x004b0658 ; undefined
     8f4:	06010402 	.inst	0x06010402 ; undefined
     8f8:	06120566 	.inst	0x06120566 ; undefined
     8fc:	2f25054c 	ushr	v12.2s, v10.2s, #27
     900:	053c1805 	ext	z5.b, z5.b, z0.b, #230
     904:	01052f16 	.inst	0x01052f16 ; undefined
     908:	12053f4b 	and	w11, w26, #0xf80007ff
     90c:	4c08052f 	.inst	0x4c08052f ; undefined
     910:	003d0905 	.inst	0x003d0905 ; undefined
     914:	06010402 	.inst	0x06010402 ; undefined
     918:	004b064a 	.inst	0x004b064a ; undefined
     91c:	06010402 	.inst	0x06010402 ; undefined
     920:	004b0658 	.inst	0x004b0658 ; undefined
     924:	06010402 	.inst	0x06010402 ; undefined
     928:	06280566 	.inst	0x06280566 ; undefined
     92c:	2e1a054c 	.inst	0x2e1a054c ; undefined
     930:	053f0c05 	ext	z5.b, z5.b, z0.b, #251
     934:	05312101 	mov	z1.b, z8.b[8]
     938:	0e052f12 	smov	w18, v24.b[2]
     93c:	0b05214b 	add	w11, w10, w5, lsl #8
     940:	210e0522 	.inst	0x210e0522 ; undefined
     944:	053d0905 	ext	z5.b, z5.b, z8.b, #234
     948:	0e05830b 	.inst	0x0e05830b ; undefined
     94c:	01040200 	.inst	0x01040200 ; undefined
     950:	42050539 	.inst	0x42050539 ; undefined
     954:	3f670105 	.inst	0x3f670105 ; undefined
     958:	05670f05 	ext	z5.b, {z24.b-z25.b}, #59
     95c:	1d052f0b 	.inst	0x1d052f0b ; undefined
     960:	2e120521 	.inst	0x2e120521 ; undefined
     964:	05300c05 	ext	z5.b, z5.b, z0.b, #131
     968:	08055814 	stxrb	w5, w20, [x0]
     96c:	2f170520 	ushr	v0.4h, v9.4h, #9
     970:	05820e05 	and	z5.d, z5.d, #0x8000ffffffffffff
     974:	1005300d 	adr	x13, af74 <MAIR_ATTR+0x6b74>
     978:	2f0c053d 	ushr	v29.8b, v9.8b, #4
     97c:	053d0d05 	ext	z5.b, z5.b, z8.b, #235
     980:	25054b1b 	sel	p11.b, p2, p8.b, p5.b
     984:	2e10053c 	.inst	0x2e10053c ; undefined
     988:	054a3105 	.inst	0x054a3105 ; undefined
     98c:	0c052018 	.inst	0x0c052018 ; undefined
     990:	21010524 	.inst	0x21010524 ; undefined
     994:	670f0531 	.inst	0x670f0531 ; undefined
     998:	05210b05 	ext	z5.b, z5.b, z24.b, #10
     99c:	1205211d 	and	w29, w8, #0xf800000f
     9a0:	300b052e 	adr	x14, 16a45 <MAIR_ATTR+0x12645>
     9a4:	05670805 	ext	z5.b, {z0.b-z1.b}, #58
     9a8:	0c053d10 	.inst	0x0c053d10 ; undefined
     9ac:	58140531 	ldr	x17, 28a50 <MAIR_ATTR+0x24650>
     9b0:	05200805 	ext	z5.b, z5.b, z0.b, #2
     9b4:	0e052f17 	smov	w23, v24.b[2]
     9b8:	300d0582 	adr	x2, 1aa69 <MAIR_ATTR+0x16669>
     9bc:	053d1005 	ext	z5.b, z5.b, z0.b, #236
     9c0:	0d052f0c 	.inst	0x0d052f0c ; undefined
     9c4:	4b1b053d 	sub	w29, w9, w27, lsl #1
     9c8:	053c2505 	dupq	z5.s, z8.s[3]
     9cc:	31052e10 	adds	w16, w16, #0x14b
     9d0:	2018054a 	.inst	0x2018054a ; undefined
     9d4:	05240c05 	ext	z5.b, z5.b, z0.b, #35
     9d8:	05312101 	mov	z1.b, z8.b[8]
     9dc:	0f05670e 	movi	v14.2s, #0xb8, lsl #24
     9e0:	2205053d 	.inst	0x2205053d ; undefined
     9e4:	01040200 	.inst	0x01040200 ; undefined
     9e8:	4b066606 	sub	w6, w16, w6, lsl #25
     9ec:	01040200 	.inst	0x01040200 ; undefined
     9f0:	4b064a06 	sub	w6, w16, w6, lsl #18
     9f4:	01040200 	.inst	0x01040200 ; undefined
     9f8:	0b055806 	add	w6, w0, w5, lsl #22
     9fc:	08054c06 	stxrb	w5, w6, [x0]
     a00:	3d100567 	str	b7, [x11, #1025]
     a04:	05312205 	mov	z5.b, z16.b[8]
     a08:	05052e12 	.inst	0x05052e12 ; undefined
     a0c:	0402002f 	.inst	0x0402002f ; undefined
     a10:	05820601 	and	z1.d, z1.d, #0x1ffffffffffff
     a14:	054c0608 	.inst	0x054c0608 ; undefined
     a18:	10054a22 	adr	x2, b35c <MAIR_ATTR+0x6f5c>
     a1c:	220c053c 	.inst	0x220c053c ; undefined
     a20:	31210105 	adds	w5, w8, #0x840
     a24:	054c0f05 	.inst	0x054c0f05 ; undefined
     a28:	02002205 	.inst	0x02002205 ; undefined
     a2c:	4a060104 	eor	w4, w8, w6
     a30:	4c060b05 	.inst	0x4c060b05 ; undefined
     a34:	05680805 	ext	z5.b, {z0.b-z1.b}, #66
     a38:	0f053d19 	.inst	0x0f053d19 ; undefined
     a3c:	3010052e 	adr	x14, 20ae1 <MAIR_ATTR+0x1c6e1>
     a40:	05581805 	mov	z5.h, p8/z, #-64
     a44:	1305200c 	sbfx	w12, w0, #5, #4
     a48:	820d052f 	.inst	0x820d052f ; undefined
     a4c:	05211005 	ext	z5.b, z5.b, z0.b, #12
     a50:	01054a18 	.inst	0x01054a18 ; undefined
     a54:	0f053f23 	.inst	0x0f053f23 ; undefined
     a58:	0e052f3d 	smov	w29, v25.b[2]
     a5c:	20050522 	.inst	0x20050522 ; undefined
     a60:	05211005 	ext	z5.b, z5.b, z0.b, #12
     a64:	0c055814 	.inst	0x0c055814 ; undefined
     a68:	2f1e0520 	ushr	v0.4h, v9.4h, #2
     a6c:	05821105 	and	z5.d, z5.d, #0xc00000000000007f
     a70:	0d052216 	.inst	0x0d052216 ; undefined
     a74:	21180520 	.inst	0x21180520 ; undefined
     a78:	05581c05 	mov	z5.h, p8/z, #-32
     a7c:	1b052014 	madd	w20, w0, w5, w8
     a80:	8215052f 	.inst	0x8215052f ; undefined
     a84:	05211805 	ext	z5.b, z5.b, z0.b, #14
     a88:	27054a1c 	.inst	0x27054a1c ; undefined
     a8c:	01040200 	.inst	0x01040200 ; undefined
     a90:	001f051d 	.inst	0x001f051d ; undefined
     a94:	3c020402 	str	b2, [x0], #32
     a98:	01040200 	.inst	0x01040200 ; undefined
     a9c:	00170538 	.inst	0x00170538 ; undefined
     aa0:	3c020402 	str	b2, [x0], #32
     aa4:	0c030105 	.inst	0x0c030105 ; undefined
     aa8:	0f054d3c 	.inst	0x0f054d3c ; undefined
     aac:	300e053d 	adr	x29, 1cb51 <MAIR_ATTR+0x18751>
     ab0:	05200505 	ext	z5.b, z5.b, z8.b, #1
     ab4:	14052110 	b	148ef4 <TCR_T1SZ+0x48ef4>
     ab8:	200c0558 	.inst	0x200c0558 ; undefined
     abc:	052f1305 	ext	z5.b, z5.b, z24.b, #124
     ac0:	1005820d 	adr	x13, bb00 <MAIR_ATTR+0x7700>
     ac4:	4a140521 	eor	w1, w9, w20, lsl #1
     ac8:	02001f05 	.inst	0x02001f05 ; undefined
     acc:	051d0104 	mov	z4.b, p13/z, #8
     ad0:	04020017 	.inst	0x04020017 ; undefined
     ad4:	01053c02 	.inst	0x01053c02 ; undefined
     ad8:	05054d42 	.inst	0x05054d42 ; undefined
     adc:	2f01053d 	mvni	v29.2s, #0x29
     ae0:	3d05053f 	str	b31, [x9, #321]
     ae4:	052f2f3d 	tbx	z29.b, z25.b, z15.b
     ae8:	05412f01 	eor	z1.b, z1.b, #0x88
     aec:	0e053e1e 	umov	w30, v16.b[2]
     af0:	23050557 	.inst	0x23050557 ; undefined
     af4:	40750105 	.inst	0x40750105 ; undefined
     af8:	054b0a05 	.inst	0x054b0a05 ; undefined
     afc:	08052112 	stxrb	w5, w18, [x8]
     b00:	3d090530 	str	b16, [x9, #577]
     b04:	054b2a05 	.inst	0x054b2a05 ; undefined
     b08:	0c053c12 	.inst	0x0c053c12 ; undefined
     b0c:	4b110568 	sub	w8, w11, w17, lsl #1
     b10:	02001005 	.inst	0x02001005 ; undefined
     b14:	054a0104 	.inst	0x054a0104 ; undefined
     b18:	18052f11 	ldr	w17, b0f8 <MAIR_ATTR+0x6cf8>
     b1c:	340d052f 	cbz	w15, 1abc0 <MAIR_ATTR+0x167c0>
     b20:	320c052f 	orr	w15, w9, #0x300000
     b24:	31210105 	adds	w5, w8, #0x840
     b28:	053d0e05 	ext	z5.b, z5.b, z16.b, #235
     b2c:	01053c05 	.inst	0x01053c05 ; undefined
     b30:	05053f21 	.inst	0x05053f21 ; undefined
     b34:	5913052f 	.inst	0x5913052f ; undefined
     b38:	052e1105 	ext	z5.b, z5.b, z8.b, #116
     b3c:	03023e01 	.inst	0x03023e01 ; undefined
     b40:	0b010100 	add	w0, w8, w1
     b44:	05000003 	orr	z3.s, z3.s, #0x1
     b48:	47000800 	.inst	0x47000800 ; undefined
     b4c:	04000000 	add	z0.b, p0/m, z0.b, z0.b
     b50:	0efb0101 	.inst	0x0efb0101 ; undefined
     b54:	0101000d 	.inst	0x0101000d ; undefined
     b58:	00000101 	udf	#257
     b5c:	00000100 	udf	#256
     b60:	1f010101 	fmadd	s1, s8, s1, s0
     b64:	00000002 	udf	#2
     b68:	00002b00 	udf	#11008
     b6c:	1f010200 	fmadd	s0, s16, s1, s0
     b70:	2c070f02 	stnp	s2, s3, [x24, #56]
     b74:	00000001 	udf	#1
     b78:	0000012c 	udf	#300
     b7c:	0000af00 	udf	#44800
     b80:	00980100 	.inst	0x00980100 ; undefined
     b84:	c2000000 	.inst	0xc2000000 ; undefined
     b88:	00000000 	udf	#0
     b8c:	000000bc 	udf	#188
     b90:	00012400 	.inst	0x00012400 ; undefined
     b94:	01050000 	.inst	0x01050000 ; undefined
     b98:	b8020900 	sttr	w0, [x8, #32]
     b9c:	000008a9 	udf	#2217
     ba0:	1affff00 	.inst	0x1affff00 ; undefined
     ba4:	05211405 	ext	z5.b, z5.b, z0.b, #13
     ba8:	28053c0e 	stnp	w14, w15, [x0, #40]
     bac:	3c220530 	.inst	0x3c220530 ; undefined
     bb0:	313d0105 	adds	w5, w8, #0xf40
     bb4:	052f1505 	ext	z5.b, z5.b, z8.b, #125
     bb8:	17052f22 	b	fffffffffc14c840 <FS_BASE+0xffffcc14c840>
     bbc:	203d052e 	.inst	0x203d052e ; undefined
     bc0:	052e0e05 	ext	z5.b, z5.b, z16.b, #115
     bc4:	0105300c 	.inst	0x0105300c ; undefined
     bc8:	1b05313d 	madd	w29, w9, w5, w12
     bcc:	3015053d 	adr	x29, 2ac71 <MAIR_ATTR+0x26871>
     bd0:	31670105 	adds	w5, w8, #0x9c0, lsl #12
     bd4:	00410505 	.inst	0x00410505 ; undefined
     bd8:	06010402 	.inst	0x06010402 ; undefined
     bdc:	0615053c 	.inst	0x0615053c ; undefined
     be0:	301b054c 	adr	x12, 36c89 <MAIR_ATTR+0x32889>
     be4:	052e1005 	ext	z5.b, z5.b, z0.b, #116
     be8:	0e052036 	tbl	v22.8b, {v1.16b-v2.16b}, v5.8b
     bec:	2f1b052e 	ushr	v14.4h, v9.4h, #5
     bf0:	052e1005 	ext	z5.b, z5.b, z0.b, #116
     bf4:	2705202a 	.inst	0x2705202a ; undefined
     bf8:	203f052e 	.inst	0x203f052e ; undefined
     bfc:	052e0e05 	ext	z5.b, z5.b, z16.b, #115
     c00:	0e052f1b 	smov	w27, v24.b[2]
     c04:	3015052e 	adr	x14, 2aca9 <MAIR_ATTR+0x268a9>
     c08:	053c2005 	mov	z5.s, z0.s[3]
     c0c:	23052f10 	.inst	0x23052f10 ; undefined
     c10:	2e18052e 	.inst	0x2e18052e ; undefined
     c14:	05203c05 	.inst	0x05203c05 ; undefined
     c18:	15052e39 	b	414c4fc <FS_SIZE+0xf964fc>
     c1c:	1f2b0520 	fnmadd	s0, s9, s11, s1
     c20:	31220105 	adds	w5, w8, #0x880
     c24:	052f1705 	ext	z5.b, z5.b, z24.b, #125
     c28:	0c053019 	.inst	0x0c053019 ; undefined
     c2c:	2031052e 	.inst	0x2031052e ; undefined
     c30:	052e2c05 	tbx	z5.b, z0.b, z14.b
     c34:	05312101 	mov	z1.b, z8.b[8]
     c38:	0f052f17 	.inst	0x0f052f17 ; undefined
     c3c:	2f010530 	mvni	v16.2s, #0x29
     c40:	32090531 	orr	w17, w9, #0x1800000
     c44:	052f1005 	ext	z5.b, z5.b, z0.b, #124
     c48:	2a053c35 	orr	w21, w1, w5, lsl #15
     c4c:	2044052e 	.inst	0x2044052e ; undefined
     c50:	052e4105 	zip1	p5.b, p8.b, p14.b
     c54:	5a052028 	.inst	0x5a052028 ; undefined
     c58:	2e0c0520 	.inst	0x2e0c0520 ; undefined
     c5c:	3d010530 	str	b16, [x9, #65]
     c60:	590a0531 	.inst	0x590a0531 ; undefined
     c64:	05221905 	ext	z5.b, z5.b, z8.b, #22
     c68:	08052009 	stxrb	w5, w9, [x0]
     c6c:	01040200 	.inst	0x01040200 ; undefined
     c70:	2f19053c 	ushr	v28.4h, v9.4h, #7
     c74:	052e0905 	ext	z5.b, z5.b, z8.b, #114
     c78:	0402002f 	.inst	0x0402002f ; undefined
     c7c:	10053b02 	adr	x2, b3dc <MAIR_ATTR+0x6fdc>
     c80:	310c0530 	adds	w16, w9, #0x301
     c84:	31210105 	adds	w5, w8, #0x840
     c88:	054d0c05 	.inst	0x054d0c05 ; undefined
     c8c:	11052005 	add	w5, w0, #0x148
     c90:	4a0c0521 	eor	w1, w9, w12, lsl #1
     c94:	052f1405 	ext	z5.b, z5.b, z0.b, #125
     c98:	0d053117 	.inst	0x0d053117 ; undefined
     c9c:	3c17053c 	str	b28, [x9], #-144
     ca0:	05201105 	ext	z5.b, z5.b, z8.b, #4
     ca4:	0402003e 	.inst	0x0402003e ; undefined
     ca8:	29051b01 	stp	w1, w6, [x24, #40]
     cac:	02040200 	.inst	0x02040200 ; undefined
     cb0:	001e053c 	.inst	0x001e053c ; undefined
     cb4:	3c030402 	str	b2, [x0], #48
     cb8:	02001705 	.inst	0x02001705 ; undefined
     cbc:	054a0304 	.inst	0x054a0304 ; undefined
     cc0:	04020030 	.inst	0x04020030 ; undefined
     cc4:	29052e04 	stp	w4, w11, [x16, #40]
     cc8:	04040200 	.inst	0x04040200 ; undefined
     ccc:	360d054a 	tbz	w10, #1, ffffffffffffad74 <FS_BASE+0xffffcfffad74>
     cd0:	054a0805 	.inst	0x054a0805 ; undefined
     cd4:	12052f0a 	and	w10, w24, #0xf800007f
     cd8:	2009053e 	.inst	0x2009053e ; undefined
     cdc:	05211505 	ext	z5.b, z5.b, z8.b, #13
     ce0:	18054a10 	ldr	w16, b620 <MAIR_ATTR+0x7220>
     ce4:	311a052f 	adds	w15, w9, #0x681
     ce8:	053c1005 	ext	z5.b, z5.b, z0.b, #228
     cec:	14053c1a 	b	14fd54 <TCR_T1SZ+0x4fd54>
     cf0:	00340520 	.inst	0x00340520 ; undefined
     cf4:	1b010402 	madd	w2, w0, w1, w1
     cf8:	02003905 	.inst	0x02003905 ; undefined
     cfc:	053c0104 	ext	z4.b, z4.b, z8.b, #224
     d00:	0402001f 	.inst	0x0402001f ; undefined
     d04:	26053c02 	.inst	0x26053c02 ; undefined
     d08:	03040200 	.inst	0x03040200 ; undefined
     d0c:	001f053c 	.inst	0x001f053c ; undefined
     d10:	4a030402 	eor	w2, w0, w3, lsl #1
     d14:	09030d05 	.inst	0x09030d05 ; undefined
     d18:	4a08052e 	eor	w14, w9, w8, lsl #1
     d1c:	052f1005 	ext	z5.b, z5.b, z0.b, #124
     d20:	0105310c 	.inst	0x0105310c ; undefined
     d24:	0a053121 	and	w1, w9, w5, lsl #12
     d28:	13052f3d 	sbfx	w29, w25, #5, #7
     d2c:	76080578 	.inst	0x76080578 ; undefined
     d30:	054b1c05 	.inst	0x054b1c05 ; undefined
     d34:	17052f15 	b	fffffffffc14c988 <FS_BASE+0xffffcc14c988>
     d38:	20090530 	.inst	0x20090530 ; undefined
     d3c:	05211a05 	ext	z5.b, z5.b, z16.b, #14
     d40:	10054a22 	adr	x2, b684 <MAIR_ATTR+0x7284>
     d44:	00410520 	.inst	0x00410520 ; undefined
     d48:	2e010402 	.inst	0x2e010402 ; undefined
     d4c:	02004905 	.inst	0x02004905 ; undefined
     d50:	054a0104 	.inst	0x054a0104 ; undefined
     d54:	04020035 	.inst	0x04020035 ; undefined
     d58:	1a052001 	.inst	0x1a052001 ; undefined
     d5c:	4a1d0531 	eor	w17, w9, w29, lsl #1
     d60:	05201005 	ext	z5.b, z5.b, z0.b, #4
     d64:	1105322e 	add	w14, w17, #0x14c
     d68:	0010052e 	.inst	0x0010052e ; undefined
     d6c:	66010402 	.inst	0x66010402 ; undefined
     d70:	053d1805 	ext	z5.b, z5.b, z0.b, #238
     d74:	2e790311 	uaddl	v17.4s, v24.4h, v25.4h
     d78:	00350531 	.inst	0x00350531 ; undefined
     d7c:	1b010402 	madd	w2, w0, w1, w1
     d80:	02002005 	.inst	0x02002005 ; undefined
     d84:	053c0204 	ext	z4.b, z4.b, z16.b, #224
     d88:	4a0e030c 	eor	w12, w24, w14
     d8c:	31210105 	adds	w5, w8, #0x840
     d90:	055b0e05 	mov	z5.h, p11/z, #112
     d94:	1405240b 	b	149dc0 <TCR_T1SZ+0x49dc0>
     d98:	2f0b052f 	ushr	v15.8b, v9.8b, #5
     d9c:	05300805 	ext	z5.b, z5.b, z0.b, #130
     da0:	2a053d10 	orr	w16, w8, w5, lsl #15
     da4:	04020032 	.inst	0x04020032 ; undefined
     da8:	052e0601 	ext	z1.b, z1.b, z16.b, #113
     dac:	0402001a 	.inst	0x0402001a ; undefined
     db0:	05200601 	ext	z1.b, z1.b, z16.b, #1
     db4:	04020028 	.inst	0x04020028 ; undefined
     db8:	0f052001 	.inst	0x0f052001 ; undefined
     dbc:	01040200 	.inst	0x01040200 ; undefined
     dc0:	21110520 	.inst	0x21110520 ; undefined
     dc4:	02000f05 	.inst	0x02000f05 ; undefined
     dc8:	053c0104 	ext	z4.b, z4.b, z8.b, #224
     dcc:	2705220c 	.inst	0x2705220c ; undefined
     dd0:	3c0d054b 	str	b11, [x10], #208
     dd4:	054b1705 	.inst	0x054b1705 ; undefined
     dd8:	09052f0d 	.inst	0x09052f0d ; undefined
     ddc:	4c100523 	.inst	0x4c100523 ; undefined
     de0:	054b1305 	.inst	0x054b1305 ; undefined
     de4:	04020016 	.inst	0x04020016 ; undefined
     de8:	4a730301 	eon	w1, w24, w19, lsr #0
     dec:	10030c05 	adr	x5, 6f6c <MAIR_ATTR+0x2b6c>
     df0:	2101054a 	.inst	0x2101054a ; undefined
     df4:	590c0531 	.inst	0x590c0531 ; undefined
     df8:	314b0105 	adds	w5, w8, #0x2c0, lsl #12
     dfc:	054f0905 	.inst	0x054f0905 ; undefined
     e00:	0805300d 	stxrb	w5, w13, [x0]
     e04:	3e15053e 	.inst	0x3e15053e ; undefined
     e08:	052f1e05 	ext	z5.b, z5.b, z16.b, #127
     e0c:	22054a13 	.inst	0x22054a13 ; undefined
     e10:	4a29052f 	eon	w15, w9, w9, lsl #1
     e14:	05201705 	ext	z5.b, z5.b, z24.b, #5
     e18:	0c05220d 	.inst	0x0c05220d ; undefined
     e1c:	01040200 	.inst	0x01040200 ; undefined
     e20:	3d110566 	str	b6, [x11, #1089]
     e24:	05240c05 	ext	z5.b, z5.b, z0.b, #35
     e28:	05312101 	mov	z1.b, z8.b[8]
     e2c:	0a052f1c 	and	w28, w24, w5, lsl #11
     e30:	3c080530 	str	b16, [x9], #128
     e34:	02001e05 	.inst	0x02001e05 ; undefined
     e38:	052e0104 	ext	z4.b, z4.b, z8.b, #112
     e3c:	0402001a 	.inst	0x0402001a ; undefined
     e40:	09053c01 	.inst	0x09053c01 ; undefined
     e44:	0402002f 	.inst	0x0402002f ; undefined
     e48:	01053d01 	.inst	0x01053d01 ; undefined
     e4c:	0003024c 	.inst	0x0003024c ; undefined
     e50:	044e0101 	.inst	0x044e0101 ; undefined
     e54:	00050000 	.inst	0x00050000 ; undefined
     e58:	00510008 	.inst	0x00510008 ; undefined
     e5c:	01040000 	.inst	0x01040000 ; undefined
     e60:	0d0efb01 	.inst	0x0d0efb01 ; undefined
     e64:	01010100 	.inst	0x01010100 ; undefined
     e68:	00000001 	udf	#1
     e6c:	01000001 	.inst	0x01000001 ; undefined
     e70:	021f0101 	.inst	0x021f0101 ; undefined
     e74:	00000000 	udf	#0
     e78:	0000002b 	udf	#43
     e7c:	021f0102 	.inst	0x021f0102 ; undefined
     e80:	0133090f 	.inst	0x0133090f ; undefined
     e84:	33000000 	bfxil	w0, w0, #0, #1
     e88:	00000001 	udf	#1
     e8c:	000000af 	udf	#175
     e90:	00007a01 	udf	#31233
     e94:	00bc0000 	.inst	0x00bc0000 ; undefined
     e98:	84000000 	ld1sb	{z0.s}, p0/z, [x0, z0.s, uxtw]
     e9c:	00000000 	udf	#0
     ea0:	0000009f 	udf	#159
     ea4:	00012400 	.inst	0x00012400 ; undefined
     ea8:	00c20000 	.inst	0x00c20000 ; undefined
     eac:	05000000 	orr	z0.s, z0.s, #0x1
     eb0:	02090001 	.inst	0x02090001 ; undefined
     eb4:	0008b0f4 	.inst	0x0008b0f4 ; undefined
     eb8:	ffff0000 	.inst	0xffff0000 ; undefined
     ebc:	05011403 	orr	z3.h, z3.h, #0x4000
     ec0:	0105130c 	.inst	0x0105130c ; undefined
     ec4:	1505232f 	b	4149b80 <FS_SIZE+0xf93b80>
     ec8:	220e0521 	.inst	0x220e0521 ; undefined
     ecc:	05200505 	ext	z5.b, z5.b, z8.b, #1
     ed0:	0c05211d 	.inst	0x0c05211d ; undefined
     ed4:	2f150574 	ushr	v20.4h, v11.4h, #11
     ed8:	05750d05 	ext	z5.b, {z8.b-z9.b}, #171
     edc:	04020024 	.inst	0x04020024 ; undefined
     ee0:	17051d01 	b	fffffffffc1482e4 <FS_BASE+0xffffcc1482e4>
     ee4:	02040200 	.inst	0x02040200 ; undefined
     ee8:	430c053c 	.inst	0x430c053c ; undefined
     eec:	30210105 	adr	x5, 42f0d <MAIR_ATTR+0x3eb0d>
     ef0:	05310905 	ext	z5.b, z5.b, z8.b, #138
     ef4:	09053d08 	.inst	0x09053d08 ; undefined
     ef8:	01040200 	.inst	0x01040200 ; undefined
     efc:	3401051f 	cbz	wzr, 2f9c <_binary_init_bin_size+0x2854>
     f00:	05330f05 	ext	z5.b, z5.b, z24.b, #155
     f04:	02002f05 	.inst	0x02002f05 ; undefined
     f08:	58060104 	ldr	x4, cf28 <MAIR_ATTR+0x8b28>
     f0c:	4c061405 	.inst	0x4c061405 ; undefined
     f10:	053d1205 	ext	z5.b, z5.b, z16.b, #236
     f14:	16053220 	b	fffffffff814d794 <FS_BASE+0xffffc814d794>
     f18:	01040200 	.inst	0x01040200 ; undefined
     f1c:	00140520 	.inst	0x00140520 ; undefined
     f20:	20010402 	.inst	0x20010402 ; undefined
     f24:	002f0505 	.inst	0x002f0505 ; undefined
     f28:	06010402 	.inst	0x06010402 ; undefined
     f2c:	061a054a 	.inst	0x061a054a ; undefined
     f30:	2e05054b 	.inst	0x2e05054b ; undefined
     f34:	053f1e05 	ext	z5.b, z5.b, z16.b, #255
     f38:	16052e4d 	b	fffffffff814c86c <FS_BASE+0xffffc814c86c>
     f3c:	3219053c 	orr	w28, w9, #0x180
     f40:	052e2305 	mov	z5.h, z24.h[3]
     f44:	2d052006 	stp	s6, s8, [x0, #40]
     f48:	2e2b0520 	uhadd	v0.8b, v9.8b, v11.8b
     f4c:	05232e05 	tbx	z5.b, z16.b, z3.b
     f50:	13052e42 	sbfx	w2, w18, #5, #7
     f54:	2011053c 	.inst	0x2011053c ; undefined
     f58:	052f1205 	ext	z5.b, z5.b, z16.b, #124
     f5c:	17052e04 	b	fffffffffc14c76c <FS_BASE+0xffffcc14c76c>
     f60:	26055c3f 	.inst	0x26055c3f ; undefined
     f64:	4101052f 	.inst	0x4101052f ; undefined
     f68:	310f053f 	cmn	w9, #0x3c1
     f6c:	002f0505 	.inst	0x002f0505 ; undefined
     f70:	06010402 	.inst	0x06010402 ; undefined
     f74:	06200558 	.inst	0x06200558 ; undefined
     f78:	0016054c 	.inst	0x0016054c ; undefined
     f7c:	20010402 	.inst	0x20010402 ; undefined
     f80:	02001405 	.inst	0x02001405 ; undefined
     f84:	05200104 	ext	z4.b, z4.b, z8.b, #0
     f88:	02002f05 	.inst	0x02002f05 ; undefined
     f8c:	4a060104 	eor	w4, w8, w6
     f90:	4b061a05 	sub	w5, w16, w6, lsl #6
     f94:	052e0505 	ext	z5.b, z5.b, z8.b, #113
     f98:	1b053e14 	madd	w20, w16, w5, w15
     f9c:	7412053d 	cbgt	w29, w18, 1040 <_binary_init_bin_size+0x8f8>
     fa0:	05321f05 	ext	z5.b, z5.b, z24.b, #151
     fa4:	16052e4e 	b	fffffffff814c8dc <FS_BASE+0xffffc814c8dc>
     fa8:	2f19053c 	ushr	v28.4h, v9.4h, #7
     fac:	052e2305 	mov	z5.h, z24.h[3]
     fb0:	2d052006 	stp	s6, s8, [x0, #40]
     fb4:	2e2b0520 	uhadd	v0.8b, v9.8b, v11.8b
     fb8:	05212e05 	tbx	z5.b, z16.b, z1.b
     fbc:	13052e42 	sbfx	w2, w18, #5, #7
     fc0:	2011053c 	.inst	0x2011053c ; undefined
     fc4:	052f0c05 	ext	z5.b, z5.b, z0.b, #123
     fc8:	0c052e16 	.inst	0x0c052e16 ; undefined
     fcc:	2e16052f 	.inst	0x2e16052f ; undefined
     fd0:	052f0c05 	ext	z5.b, z5.b, z0.b, #123
     fd4:	23052e17 	.inst	0x23052e17 ; undefined
     fd8:	00190522 	.inst	0x00190522 ; undefined
     fdc:	20010402 	.inst	0x20010402 ; undefined
     fe0:	02001705 	.inst	0x02001705 ; undefined
     fe4:	05200104 	ext	z4.b, z4.b, z8.b, #0
     fe8:	02002f05 	.inst	0x02002f05 ; undefined
     fec:	4a060104 	eor	w4, w8, w6
     ff0:	4b061a05 	sub	w5, w16, w6, lsl #6
     ff4:	052e0505 	ext	z5.b, z5.b, z8.b, #113
     ff8:	01053e0c 	.inst	0x01053e0c ; undefined
     ffc:	0f053121 	.inst	0x0f053121 ; undefined
    1000:	2f050533 	mvni	v19.2s, #0xa9
    1004:	01040200 	.inst	0x01040200 ; undefined
    1008:	4c063c06 	.inst	0x4c063c06 ; undefined
    100c:	01040200 	.inst	0x01040200 ; undefined
    1010:	02007406 	.inst	0x02007406 ; undefined
    1014:	05580204 	mov	z4.h, p8/z, #16
    1018:	054c0617 	.inst	0x054c0617 ; undefined
    101c:	14052f0a 	b	14cc44 <TCR_T1SZ+0x4cc44>
    1020:	3d05053e 	str	b30, [x9, #321]
    1024:	3f3d0105 	.inst	0x3f3d0105 ; undefined
    1028:	053f0f05 	ext	z5.b, z5.b, z24.b, #251
    102c:	02002f05 	.inst	0x02002f05 ; undefined
    1030:	3c060104 	stur	b4, [x8, #96]
    1034:	4d062005 	.inst	0x4d062005 ; undefined
    1038:	02001605 	.inst	0x02001605 ; undefined
    103c:	05200104 	ext	z4.b, z4.b, z8.b, #0
    1040:	04020014 	.inst	0x04020014 ; undefined
    1044:	05052001 	.inst	0x05052001 ; undefined
    1048:	0402002f 	.inst	0x0402002f ; undefined
    104c:	054a0601 	.inst	0x054a0601 ; undefined
    1050:	054b061a 	.inst	0x054b061a ; undefined
    1054:	14052e05 	b	14c868 <TCR_T1SZ+0x4c868>
    1058:	3d1b053e 	str	b30, [x9, #1729]
    105c:	05741205 	ext	z5.b, {z16.b-z17.b}, #164
    1060:	4d05341e 	.inst	0x4d05341e ; undefined
    1064:	3c16052e 	str	b14, [x9], #-160
    1068:	05311905 	ext	z5.b, z5.b, z8.b, #142
    106c:	06052e23 	.inst	0x06052e23 ; undefined
    1070:	202d0520 	.inst	0x202d0520 ; undefined
    1074:	05202b05 	tbl	z5.b, {z24.b-z25.b}, z0.b
    1078:	4105232d 	.inst	0x4105232d ; undefined
    107c:	3c12052e 	str	b14, [x9], #-224
    1080:	05201105 	ext	z5.b, z5.b, z8.b, #4
    1084:	05053013 	.inst	0x05053013 ; undefined
    1088:	0317052e 	.inst	0x0317052e ; undefined
    108c:	0c053c0a 	.inst	0x0c053c0a ; undefined
    1090:	2101055a 	.inst	0x2101055a ; undefined
    1094:	410f0530 	.inst	0x410f0530 ; undefined
    1098:	003d0505 	.inst	0x003d0505 ; undefined
    109c:	06010402 	.inst	0x06010402 ; undefined
    10a0:	0617053c 	.inst	0x0617053c ; undefined
    10a4:	2f0a054e 	ushr	v14.8b, v10.8b, #6
    10a8:	053e1405 	ext	z5.b, z5.b, z0.b, #245
    10ac:	053d3d05 	.inst	0x053d3d05 ; undefined
    10b0:	05052f26 	.inst	0x05052f26 ; undefined
    10b4:	ae01052d 	.inst	0xae01052d ; undefined
    10b8:	2f0e0540 	ushr	v0.8b, v10.8b, #2
    10bc:	054b0505 	.inst	0x054b0505 ; undefined
    10c0:	660a0301 	.inst	0x660a0301 ; undefined
    10c4:	401d0540 	.inst	0x401d0540 ; undefined
    10c8:	02001305 	.inst	0x02001305 ; undefined
    10cc:	05200104 	ext	z4.b, z4.b, z8.b, #0
    10d0:	04020011 	.inst	0x04020011 ; undefined
    10d4:	14052001 	b	1490d8 <TCR_T1SZ+0x490d8>
    10d8:	2e05052f 	.inst	0x2e05052f ; undefined
    10dc:	053e1b05 	ext	z5.b, z5.b, z24.b, #246
    10e0:	2c052e0e 	stnp	s14, s11, [x16, #40]
    10e4:	2e0d052f 	.inst	0x2e0d052f ; undefined
    10e8:	05200b05 	ext	z5.b, z5.b, z24.b, #2
    10ec:	05052f0d 	.inst	0x05052f0d ; undefined
    10f0:	3d06052e 	str	b14, [x9, #385]
    10f4:	052e1105 	ext	z5.b, z5.b, z8.b, #116
    10f8:	11052f06 	add	w6, w24, #0x14b
    10fc:	2f06052e 	mvni	v14.2s, #0xc9
    1100:	052e1105 	ext	z5.b, z5.b, z8.b, #116
    1104:	02002505 	.inst	0x02002505 ; undefined
    1108:	74060104 	cbgt	w4, w6, 1128 <_binary_init_bin_size+0x9e0>
    110c:	02040200 	.inst	0x02040200 ; undefined
    1110:	3d4b0658 	ldr	b24, [x18, #705]
    1114:	18030105 	ldr	w5, 7134 <MAIR_ATTR+0x2d34>
    1118:	2f05053c 	mvni	v28.2s, #0xa9
    111c:	053e1705 	ext	z5.b, z5.b, z24.b, #245
    1120:	04020005 	.inst	0x04020005 ; undefined
    1124:	01052001 	.inst	0x01052001 ; undefined
    1128:	05053e35 	.inst	0x05053e35 ; undefined
    112c:	0522212f 	mov	z15.h, h9
    1130:	053f3e01 	.inst	0x053f3e01 ; undefined
    1134:	053e4d05 	.inst	0x053e4d05 ; undefined
    1138:	053f7601 	trn2	z1.b, z16.b, z31.b
    113c:	09054d08 	.inst	0x09054d08 ; undefined
    1140:	22054b3d 	.inst	0x22054b3d ; undefined
    1144:	2e090523 	.inst	0x2e090523 ; undefined
    1148:	83220505 	.inst	0x83220505 ; undefined
    114c:	67230567 	.inst	0x67230567 ; undefined
    1150:	592e0505 	ldtadd	x14, x5, [x8]
    1154:	76080575 	.inst	0x76080575 ; undefined
    1158:	3d3d0905 	str	b5, [x8, #3906]
    115c:	67230505 	.inst	0x67230505 ; undefined
    1160:	67676767 	.inst	0x67676767 ; undefined
    1164:	67676767 	.inst	0x67676767 ; undefined
    1168:	01056767 	.inst	0x01056767 ; undefined
    116c:	09053167 	.inst	0x09053167 ; undefined
    1170:	22050530 	.inst	0x22050530 ; undefined
    1174:	3e0b0530 	.inst	0x3e0b0530 ; undefined
    1178:	05211305 	ext	z5.b, z5.b, z24.b, #12
    117c:	053d3012 	tbl	z18.b, {z0.b}, z29.b
    1180:	0e053e09 	umov	w9, v16.b[2]
    1184:	000c0569 	.inst	0x000c0569 ; undefined
    1188:	2e010402 	.inst	0x2e010402 ; undefined
    118c:	2f0e0531 	ushr	v17.8b, v9.8b, #2
    1190:	02000f05 	.inst	0x02000f05 ; undefined
    1194:	73030104 	.inst	0x73030104 ; undefined
    1198:	0402003c 	.inst	0x0402003c ; undefined
    119c:	053c0602 	ext	z2.b, z2.b, z16.b, #225
    11a0:	0f030601 	movi	v1.2s, #0x70
    11a4:	1b0d053c 	madd	w28, w9, w13, w1
    11a8:	3e250105 	.inst	0x3e250105 ; undefined
    11ac:	052f1205 	ext	z5.b, z5.b, z16.b, #124
    11b0:	01052e2a 	.inst	0x01052e2a ; undefined
    11b4:	1705324b 	b	fffffffffc14dae0 <FS_BASE+0xffffcc14dae0>
    11b8:	2f0a0534 	ushr	v20.8b, v9.8b, #6
    11bc:	053d0f05 	ext	z5.b, z5.b, z24.b, #235
    11c0:	08053e09 	stxrb	w5, w9, [x16]
    11c4:	01040200 	.inst	0x01040200 ; undefined
    11c8:	3d16053c 	str	b28, [x9, #1409]
    11cc:	054d2905 	.inst	0x054d2905 ; undefined
    11d0:	26053f19 	.inst	0x26053f19 ; undefined
    11d4:	3e03053d 	.inst	0x3e03053d ; undefined
    11d8:	053e0105 	ext	z5.b, z5.b, z8.b, #240
    11dc:	05054c04 	.inst	0x05054c04 ; undefined
    11e0:	3d010523 	str	b3, [x9, #65]
    11e4:	053c0e03 	ext	z3.b, z3.b, z16.b, #227
    11e8:	0a053317 	and	w23, w24, w5, lsl #12
    11ec:	3e09052f 	.inst	0x3e09052f ; undefined
    11f0:	02000805 	.inst	0x02000805 ; undefined
    11f4:	053c0104 	ext	z4.b, z4.b, z8.b, #224
    11f8:	1405400d 	b	15122c <TCR_T1SZ+0x5122c>
    11fc:	3e10053d 	.inst	0x3e10053d ; undefined
    1200:	052e0805 	ext	z5.b, z5.b, z0.b, #114
    1204:	05052f09 	.inst	0x05052f09 ; undefined
    1208:	0309053f 	.inst	0x0309053f ; undefined
    120c:	01052e76 	.inst	0x01052e76 ; undefined
    1210:	30200b03 	adr	x3, 41371 <MAIR_ATTR+0x3cf71>
    1214:	05401705 	eor	z5.b, z5.b, #0x44
    1218:	14052f0d 	b	14ce4c <TCR_T1SZ+0x4ce4c>
    121c:	3d13053d 	str	b29, [x9, #1217]
    1220:	4b3e0505 	sub	w5, w8, w30, uxtb #1
    1224:	3f210105 	.inst	0x3f210105 ; undefined
    1228:	05421705 	eor	z5.d, z5.d, #0xc07fffffffffffff
    122c:	0f052f10 	.inst	0x0f052f10 ; undefined
    1230:	3e20053d 	.inst	0x3e20053d ; undefined
    1234:	054c0b05 	.inst	0x054c0b05 ; undefined
    1238:	09052118 	.inst	0x09052118 ; undefined
    123c:	3d24053d 	str	b29, [x9, #2305]
    1240:	02001405 	.inst	0x02001405 ; undefined
    1244:	05470104 	.inst	0x05470104 ; undefined
    1248:	054d4101 	.inst	0x054d4101 ; undefined
    124c:	0d053217 	.inst	0x0d053217 ; undefined
    1250:	3d14052f 	str	b15, [x9, #1281]
    1254:	053d1c05 	ext	z5.b, z5.b, z0.b, #239
    1258:	05052e13 	.inst	0x05052e13 ; undefined
    125c:	052f4c30 	.inst	0x052f4c30 ; undefined
    1260:	053f2101 	mov	z1.b, z8.b[15]
    1264:	0a054117 	and	w23, w8, w5, lsl #16
    1268:	3f0e052f 	.inst	0x3f0e052f ; undefined
    126c:	02000d05 	.inst	0x02000d05 ; undefined
    1270:	053c0104 	ext	z4.b, z4.b, z8.b, #224
    1274:	0402000c 	.inst	0x0402000c ; undefined
    1278:	28052e01 	stnp	w1, w11, [x16, #40]
    127c:	4b10053d 	sub	w29, w9, w16, lsl #1
    1280:	003d1105 	.inst	0x003d1105 ; undefined
    1284:	06010402 	.inst	0x06010402 ; undefined
    1288:	3d4b064a 	ldr	b10, [x18, #705]
    128c:	09054b3d 	.inst	0x09054b3d ; undefined
    1290:	000c0524 	.inst	0x000c0524 ; undefined
    1294:	03020402 	.inst	0x03020402 ; undefined
    1298:	01052e75 	.inst	0x01052e75 ; undefined
    129c:	02200d03 	.inst	0x02200d03 ; undefined
    12a0:	01010003 	.inst	0x01010003 ; undefined
    12a4:	000000fa 	udf	#250
    12a8:	00080005 	.inst	0x00080005 ; undefined
    12ac:	00000047 	udf	#71
    12b0:	fb010104 	.inst	0xfb010104 ; undefined
    12b4:	01000d0e 	.inst	0x01000d0e ; undefined
    12b8:	00010101 	.inst	0x00010101 ; undefined
    12bc:	00010000 	.inst	0x00010000 ; undefined
    12c0:	01010100 	.inst	0x01010100 ; undefined
    12c4:	0000021f 	udf	#543
    12c8:	002b0000 	.inst	0x002b0000 ; undefined
    12cc:	01020000 	.inst	0x01020000 ; undefined
    12d0:	070f021f 	.inst	0x070f021f ; undefined
    12d4:	0000013d 	udf	#317
    12d8:	00013d00 	.inst	0x00013d00 ; undefined
    12dc:	00af0000 	.inst	0x00af0000 ; undefined
    12e0:	7a010000 	sbcs	w0, w0, w1
    12e4:	00000000 	udf	#0
    12e8:	0000008e 	udf	#142
    12ec:	00008400 	udf	#33792
    12f0:	00c20000 	.inst	0x00c20000 ; undefined
    12f4:	05000000 	orr	z0.s, z0.s, #0x1
    12f8:	02090001 	.inst	0x02090001 ; undefined
    12fc:	0008be94 	.inst	0x0008be94 ; undefined
    1300:	ffff0000 	.inst	0xffff0000 ; undefined
    1304:	05010a03 	orr	z3.s, z3.s, #0x8000ffff
    1308:	05053d20 	.inst	0x05053d20 ; undefined
    130c:	2030052e 	.inst	0x2030052e ; undefined
    1310:	053c0505 	ext	z5.b, z5.b, z8.b, #225
    1314:	01053d17 	.inst	0x01053d17 ; undefined
    1318:	2205313d 	.inst	0x2205313d ; undefined
    131c:	2e0e053f 	.inst	0x2e0e053f ; undefined
    1320:	05220d05 	ext	z5.b, z5.b, z8.b, #19
    1324:	0b052f0f 	add	w15, w24, w5, lsl #11
    1328:	21090530 	.inst	0x21090530 ; undefined
    132c:	052f1105 	ext	z5.b, z5.b, z8.b, #124
    1330:	04020012 	.inst	0x04020012 ; undefined
    1334:	1e052c01 	.inst	0x1e052c01 ; undefined
    1338:	01040200 	.inst	0x01040200 ; undefined
    133c:	410c053c 	.inst	0x410c053c ; undefined
    1340:	31210105 	adds	w5, w8, #0x840
    1344:	053d0505 	ext	z5.b, z5.b, z8.b, #233
    1348:	0105210c 	.inst	0x0105210c ; undefined
    134c:	10053121 	adr	x1, b970 <MAIR_ATTR+0x7570>
    1350:	2e05053d 	.inst	0x2e05053d ; undefined
    1354:	05210c05 	ext	z5.b, z5.b, z0.b, #11
    1358:	05312101 	mov	z1.b, z8.b[8]
    135c:	053d3d0d 	.inst	0x053d3d0d ; undefined
    1360:	0e053d23 	umov	w3, v9.b[2]
    1364:	2208052e 	.inst	0x2208052e ; undefined
    1368:	02001905 	.inst	0x02001905 ; undefined
    136c:	053c0104 	ext	z4.b, z4.b, z8.b, #224
    1370:	04020022 	.inst	0x04020022 ; undefined
    1374:	10053c02 	adr	x2, baf4 <MAIR_ATTR+0x76f4>
    1378:	3d09053d 	str	b29, [x9, #577]
    137c:	05231a05 	ext	z5.b, z5.b, z16.b, #30
    1380:	02004a0e 	.inst	0x02004a0e ; undefined
    1384:	2e060104 	ext	v4.8b, v8.8b, v6.8b, #0
    1388:	02000c05 	.inst	0x02000c05 ; undefined
    138c:	20060104 	.inst	0x20060104 ; undefined
    1390:	312f0105 	adds	w5, w8, #0xbc0
    1394:	59131505 	.inst	0x59131505 ; undefined
    1398:	01055959 	.inst	0x01055959 ; undefined
    139c:	00020259 	.inst	0x00020259 ; undefined
    13a0:	Address 0x13a0 is out of bounds.


Disassembly of section .debug_line_str:

0000000000000000 <.debug_line_str>:
   0:	6573552f 	fnmla	z15.h, p5/m, z9.h, z19.h
   4:	6a2f7372 	bics	w18, w27, w15, lsl #28
   8:	6e696d69 	umin	v9.8h, v11.8h, v9.8h
   c:	6e616b67 	fcvtxn2	v7.4s, v27.2d
  10:	4c4c2f67 	.inst	0x4c4c2f67 ; undefined
  14:	70722f44 	adr	x4, e45ff <MAIR_ATTR+0xe01ff>
  18:	6d625f69 	ldp	d9, d23, [x27, #-480]
  1c:	6f6f6200 	umlsl2	v0.4s, v16.8h, v15.h[2]
  20:	00732e74 	.inst	0x00732e74 ; undefined
  24:	6e69616d 	rsubhn2	v13.8h, v11.4s, v9.4s
  28:	2f00632e 	.inst	0x2f00632e ; undefined
  2c:	2f74706f 	fcmla	v15.4h, v3.4h, v20.h[1], #270
  30:	656d6f68 	fnmls	z8.h, p3/m, z27.h, z13.h
  34:	77657262 	.inst	0x77657262 ; undefined
  38:	6c65432f 	ldnp	d15, d16, [x25, #-432]
  3c:	2f72616c 	umlsl	v12.4s, v11.4h, v2.h[3]
  40:	63726161 	.inst	0x63726161 ; undefined
  44:	2d343668 	stp	s8, s13, [x19, #-96]
  48:	2d666c65 	ldp	s5, s27, [x3, #-208]
  4c:	2f636367 	umlsl	v7.4s, v27.4h, v3.h[2]
  50:	312e3631 	adds	w17, w17, #0xb8d
  54:	6c2f302e 	stnp	d14, d12, [x1, #-272]
  58:	672f6269 	.inst	0x672f6269 ; undefined
  5c:	612f6363 	.inst	0x612f6363 ; undefined
  60:	68637261 	.inst	0x68637261 ; undefined
  64:	652d3436 	bfmls	z22.h, p5/m, z1.h, z13.h
  68:	312f666c 	adds	w12, w19, #0xbd9
  6c:	2e312e36 	uqsub	v22.8b, v17.8b, v17.8b
  70:	6e692f30 	uqsub	v16.8h, v25.8h, v9.8h
  74:	64756c63 	.inst	0x64756c63 ; undefined
  78:	61680065 	.inst	0x61680065 ; undefined
  7c:	656c646e 	fnmls	z14.h, p1/m, z3.h, z12.h
  80:	00682e72 	.inst	0x00682e72 ; undefined
  84:	636f7270 	.inst	0x636f7270 ; undefined
  88:	2e737365 	uabdl	v5.4s, v27.4h, v19.4h
  8c:	79730068 	ldrh	w8, [x3, #6528]
  90:	6c616373 	ldnp	d19, d24, [x27, #-496]
  94:	00682e6c 	.inst	0x00682e6c ; undefined
  98:	656c6966 	fnmls	z6.h, p2/m, z11.h, z12.h
  9c:	6d00682e 	stp	d14, d26, [x1]
  a0:	726f6d65 	.inst	0x726f6d65 ; undefined
  a4:	00682e79 	.inst	0x00682e79 ; undefined
  a8:	74726175 	.inst	0x74726175 ; undefined
  ac:	7300682e 	.inst	0x7300682e ; undefined
  b0:	6e696474 	umax	v20.8h, v3.8h, v9.8h
  b4:	63672d74 	.inst	0x63672d74 ; undefined
  b8:	00682e63 	.inst	0x00682e63 ; undefined
  bc:	2e62696c 	.inst	0x2e62696c ; undefined
  c0:	72700068 	.inst	0x72700068 ; undefined
  c4:	2e746e69 	umin	v9.4h, v19.4h, v20.4h
  c8:	696c0068 	ldpsw	x8, x0, [x3, #-160]
  cc:	00732e62 	.inst	0x00732e62 ; undefined
  d0:	2e62696c 	.inst	0x2e62696c ; undefined
  d4:	61750063 	.inst	0x61750063 ; undefined
  d8:	632e7472 	.inst	0x632e7472 ; undefined
  dc:	69727000 	ldpsw	x0, x28, [x0, #-112]
  e0:	632e746e 	.inst	0x632e746e ; undefined
  e4:	64747300 	.inst	0x64747300 ; undefined
  e8:	2e677261 	uabdl	v1.4s, v19.4h, v7.4h
  ec:	623c0068 	.inst	0x623c0068 ; undefined
  f0:	746c6975 	.inst	0x746c6975 ; undefined
  f4:	3e6e692d 	.inst	0x3e6e692d ; undefined
  f8:	62656400 	.inst	0x62656400 ; undefined
  fc:	632e6775 	.inst	0x632e6775 ; undefined
 100:	6e616800 	fcvtxn2	v0.4s, v0.2d
 104:	72656c64 	.inst	0x72656c64 ; undefined
 108:	6800732e 	.inst	0x6800732e ; undefined
 10c:	6c646e61 	ldnp	d1, d27, [x19, #-448]
 110:	632e7265 	.inst	0x632e7265 ; undefined
 114:	756d6d00 	.inst	0x756d6d00 ; undefined
 118:	6d00732e 	stp	d14, d28, [x25]
 11c:	726f6d65 	.inst	0x726f6d65 ; undefined
 120:	00632e79 	.inst	0x00632e79 ; undefined
 124:	75626564 	.inst	0x75626564 ; undefined
 128:	00682e67 	.inst	0x00682e67 ; undefined
 12c:	656c6966 	fnmls	z6.h, p2/m, z11.h, z12.h
 130:	7000632e 	adr	x14, d97 <_binary_init_bin_size+0x64f>
 134:	65636f72 	fnmls	z18.h, p3/m, z27.h, z3.h
 138:	632e7373 	.inst	0x632e7373 ; undefined
 13c:	73797300 	.inst	0x73797300 ; undefined
 140:	6c6c6163 	ldnp	d3, d24, [x11, #-320]
 144:	Address 0x144 is out of bounds.


Disassembly of section .debug_info:

0000000000000000 <.debug_info>:
       0:	00000025 	udf	#37
       4:	08010005 	stxrb	w1, w5, [x0]
       8:	00000000 	udf	#0
       c:	00000001 	udf	#1
      10:	08000000 	stxrb	w0, w0, [x0]
      14:	ff000000 	.inst	0xff000000 ; undefined
      18:	000290ff 	.inst	0x000290ff ; undefined
      1c:	07000000 	.inst	0x07000000 ; undefined
      20:	24000000 	cmphs	p0.b, p0/z, z0.b, z0.b
      24:	01000000 	.inst	0x01000000 ; undefined
      28:	0000f680 	udf	#63104
      2c:	01000500 	.inst	0x01000500 ; undefined
      30:	00001408 	udf	#5128
      34:	00630300 	.inst	0x00630300 ; undefined
      38:	240c0000 	cmphs	p0.b, p0/z, z0.b, z12.b
      3c:	00000000 	udf	#0
      40:	10000000 	adr	x0, 40 <TCR_T0SZ+0x30>
      44:	00000801 	udf	#2049
      48:	5cffff00 	ldr	d0, 28 <TCR_T0SZ+0x18>
      4c:	00000000 	udf	#0
      50:	7b000000 	.inst	0x7b000000 ; undefined
      54:	01000000 	.inst	0x01000000 ; undefined
      58:	01330601 	.inst	0x01330601 ; undefined
      5c:	02010000 	.inst	0x02010000 ; undefined
      60:	0001a305 	.inst	0x0001a305 ; undefined
      64:	05040400 	.inst	0x05040400 ; undefined
      68:	00746e69 	.inst	0x00746e69 ; undefined
      6c:	3f050801 	.inst	0x3f050801 ; undefined
      70:	01000001 	.inst	0x01000001 ; undefined
      74:	01310801 	.inst	0x01310801 ; undefined
      78:	02010000 	.inst	0x02010000 ; undefined
      7c:	00017c07 	.inst	0x00017c07 ; undefined
      80:	07040100 	.inst	0x07040100 ; undefined
      84:	00000155 	udf	#341
      88:	00010f05 	.inst	0x00010f05 ; undefined
      8c:	19370800 	rcwcas	x23, x0, [x0]
      90:	0000006b 	udf	#107
      94:	50070801 	adr	x1, e196 <MAIR_ATTR+0x9d96>
      98:	02000001 	.inst	0x02000001 ; undefined
      9c:	00000032 	udf	#50
      a0:	24023d02 	cmpeq	p2.b, p7/z, z8.b, z2.d
      a4:	03000001 	.inst	0x03000001 ; undefined
      a8:	01620224 	.inst	0x01620224 ; undefined
      ac:	3b020000 	.inst	0x3b020000 ; undefined
      b0:	00003d02 	udf	#15618
      b4:	023c0200 	.inst	0x023c0200 ; undefined
      b8:	00000052 	udf	#82
      bc:	48020704 	stxrh	w2, w4, [x24]
      c0:	05000001 	orr	z1.s, z1.s, #0x1
      c4:	01180231 	.inst	0x01180231 ; undefined
      c8:	22060000 	.inst	0x22060000 ; undefined
      cc:	00018f06 	.inst	0x00018f06 ; undefined
      d0:	0f180900 	fdot	v0.2s, v8.8b, v24.4b[2]
      d4:	0000004a 	udf	#74
      d8:	00019607 	.inst	0x00019607 ; undefined
      dc:	05060a00 	.inst	0x05060a00 ; undefined
      e0:	0000003c 	udf	#60
      e4:	000000c6 	udf	#198
      e8:	0000c608 	udf	#50696
      ec:	0a000900 	and	w0, w8, w0, lsl #2
      f0:	0000d308 	udf	#54024
      f4:	08010100 	stxrb	w1, w0, [x8]
      f8:	0000013a 	udf	#314
      fc:	0000cc0b 	udf	#52235
     100:	00480200 	.inst	0x00480200 ; undefined
     104:	19070000 	stlurb	w0, [x0, #112]
     108:	00019d0c 	.inst	0x00019d0c ; undefined
     10c:	060c0100 	.inst	0x060c0100 ; undefined
     110:	00080110 	.inst	0x00080110 ; undefined
     114:	ffff0000 	.inst	0xffff0000 ; undefined
     118:	0000005c 	udf	#92
     11c:	00000000 	udf	#0
     120:	25009c01 	cmpeq	p1.b, p7/z, z0.b, #0
     124:	05000000 	orr	z0.s, z0.s, #0x1
     128:	c2080100 	.inst	0xc2080100 ; undefined
     12c:	01000000 	.inst	0x01000000 ; undefined
     130:	0000010f 	udf	#271
     134:	0008016c 	.inst	0x0008016c ; undefined
     138:	ffff0000 	.inst	0xffff0000 ; undefined
     13c:	01ad01b8 	.inst	0x01ad01b8 ; undefined
     140:	00070000 	.inst	0x00070000 ; undefined
     144:	00240000 	.inst	0x00240000 ; undefined
     148:	80010000 	.inst	0x80010000 ; undefined
     14c:	00000423 	udf	#1059
     150:	08010005 	stxrb	w1, w5, [x0]
     154:	000000d6 	udf	#214
     158:	0000630c 	udf	#25356
     15c:	00d00c00 	.inst	0x00d00c00 ; undefined
     160:	00000000 	udf	#0
     164:	02240000 	.inst	0x02240000 ; undefined
     168:	00000008 	udf	#8
     16c:	01c8ffff 	.inst	0x01c8ffff ; undefined
     170:	00000000 	udf	#0
     174:	01850000 	.inst	0x01850000 ; undefined
     178:	01030000 	.inst	0x01030000 ; undefined
     17c:	00013306 	.inst	0x00013306 ; undefined
     180:	05020300 	orr	z0.d, z0.d, #0x1ffffff
     184:	000001a3 	udf	#419
     188:	6905040d 	stgp	x13, x1, [x0, #160]
     18c:	0800746e 	stxrb	w0, w14, [x3]
     190:	00000110 	udf	#272
     194:	004e182b 	.inst	0x004e182b ; undefined
     198:	08030000 	stxrb	w3, w0, [x0]
     19c:	00013f05 	.inst	0x00013f05 ; undefined
     1a0:	08010300 	stxrb	w1, w0, [x24]
     1a4:	00000131 	udf	#305
     1a8:	7c070203 	stur	h3, [x16, #112]
     1ac:	03000001 	.inst	0x03000001 ; undefined
     1b0:	01550704 	.inst	0x01550704 ; undefined
     1b4:	0f080000 	fdot	v0.2s, v0.8b, v8.4b[0]
     1b8:	37000001 	tbnz	w1, #0, 1b8 <TCR_T0SZ+0x1a8>
     1bc:	00007519 	udf	#29977
     1c0:	07080300 	.inst	0x07080300 ; undefined
     1c4:	00000150 	udf	#336
     1c8:	0001d906 	.inst	0x0001d906 ; undefined
     1cc:	07030800 	.inst	0x07030800 ; undefined
     1d0:	00000096 	udf	#150
     1d4:	00023602 	.inst	0x00023602 ; undefined
     1d8:	0f080300 	fdot	v0.2s, v24.8b, v8.4b[0]
     1dc:	00000096 	udf	#150
     1e0:	7c070000 	stur	h0, [x0, #112]
     1e4:	06000000 	.inst	0x06000000 ; undefined
     1e8:	000001d5 	udf	#469
     1ec:	c20b0310 	.inst	0xc20b0310 ; undefined
     1f0:	02000000 	.inst	0x02000000 ; undefined
     1f4:	00000236 	udf	#566
     1f8:	960f0c03 	bl	fffffffff83c3204 <FS_BASE+0xffffc83c3204>
     1fc:	00000000 	udf	#0
     200:	00023102 	.inst	0x00023102 ; undefined
     204:	0f0d0300 	fdot	v0.2s, v24.8b, v13.4b[0]
     208:	00000096 	udf	#150
     20c:	b30e0008 	.inst	0xb30e0008 ; undefined
     210:	20000001 	.inst	0x20000001 ; undefined
     214:	08140401 	stxrb	w20, w1, [x0]
     218:	00000297 	udf	#663
     21c:	00307801 	.inst	0x00307801 ; undefined
     220:	430d1504 	.inst	0x430d1504 ; undefined
     224:	00000000 	udf	#0
     228:	00317801 	.inst	0x00317801 ; undefined
     22c:	430d1604 	.inst	0x430d1604 ; undefined
     230:	08000000 	stxrb	w0, w0, [x0]
     234:	00327801 	.inst	0x00327801 ; undefined
     238:	430d1704 	.inst	0x430d1704 ; undefined
     23c:	10000000 	adr	x0, 23c <TCR_T0SZ+0x22c>
     240:	00337801 	.inst	0x00337801 ; undefined
     244:	430d1804 	.inst	0x430d1804 ; undefined
     248:	18000000 	ldr	w0, 248 <TCR_T0SZ+0x238>
     24c:	00347801 	.inst	0x00347801 ; undefined
     250:	430d1904 	.inst	0x430d1904 ; undefined
     254:	20000000 	.inst	0x20000000 ; undefined
     258:	00357801 	.inst	0x00357801 ; undefined
     25c:	430d1a04 	.inst	0x430d1a04 ; undefined
     260:	28000000 	stnp	w0, w0, [x0]
     264:	00367801 	.inst	0x00367801 ; undefined
     268:	430d1b04 	.inst	0x430d1b04 ; undefined
     26c:	30000000 	adr	x0, 26d <TCR_T0SZ+0x25d>
     270:	00377801 	.inst	0x00377801 ; undefined
     274:	430d1c04 	.inst	0x430d1c04 ; undefined
     278:	38000000 	sturb	w0, [x0]
     27c:	00387801 	.inst	0x00387801 ; undefined
     280:	430d1d04 	.inst	0x430d1d04 ; undefined
     284:	40000000 	.inst	0x40000000 ; undefined
     288:	00397801 	.inst	0x00397801 ; undefined
     28c:	430d1e04 	.inst	0x430d1e04 ; undefined
     290:	48000000 	stxrh	w0, w0, [x0]
     294:	30317801 	adr	x1, 63195 <MAIR_ATTR+0x5ed95>
     298:	0d1f0400 	.inst	0x0d1f0400 ; undefined
     29c:	00000043 	udf	#67
     2a0:	31780150 	adds	w16, w10, #0xe00, lsl #12
     2a4:	20040031 	.inst	0x20040031 ; undefined
     2a8:	0000430d 	udf	#17165
     2ac:	78015800 	sttrh	w0, [x0, #21]
     2b0:	04003231 	saddv	d17, p4, z17.b
     2b4:	00430d21 	.inst	0x00430d21 ; undefined
     2b8:	01600000 	.inst	0x01600000 ; undefined
     2bc:	00333178 	.inst	0x00333178 ; undefined
     2c0:	430d2204 	.inst	0x430d2204 ; undefined
     2c4:	68000000 	.inst	0x68000000 ; undefined
     2c8:	34317801 	cbz	w1, 631c8 <MAIR_ATTR+0x5edc8>
     2cc:	0d230400 	.inst	0x0d230400 ; undefined
     2d0:	00000043 	udf	#67
     2d4:	31780170 	adds	w16, w11, #0xe00, lsl #12
     2d8:	24040035 	cmphi	p5.b, p0/z, z1.b, z4.b
     2dc:	0000430d 	udf	#17165
     2e0:	78017800 	sttrh	w0, [x0, #23]
     2e4:	04003631 	saddv	d17, p5, z17.b
     2e8:	00430d25 	.inst	0x00430d25 ; undefined
     2ec:	01800000 	.inst	0x01800000 ; undefined
     2f0:	00373178 	.inst	0x00373178 ; undefined
     2f4:	430d2604 	.inst	0x430d2604 ; undefined
     2f8:	88000000 	stxr	w0, w0, [x0]
     2fc:	38317801 	strb	w1, [x0, x17, lsl #0]
     300:	0d270400 	.inst	0x0d270400 ; undefined
     304:	00000043 	udf	#67
     308:	31780190 	adds	w16, w12, #0xe00, lsl #12
     30c:	28040039 	stnp	w25, w0, [x1, #32]
     310:	0000430d 	udf	#17165
     314:	78019800 	sttrh	w0, [x0, #25]
     318:	04003032 	saddv	d18, p4, z1.b
     31c:	00430d29 	.inst	0x00430d29 ; undefined
     320:	01a00000 	.inst	0x01a00000 ; undefined
     324:	00313278 	.inst	0x00313278 ; undefined
     328:	430d2a04 	.inst	0x430d2a04 ; undefined
     32c:	a8000000 	stnp	x0, x0, [x0]
     330:	32327801 	orr	w1, w0, #0xffffdfff
     334:	0d2b0400 	.inst	0x0d2b0400 ; undefined
     338:	00000043 	udf	#67
     33c:	327801b0 	.inst	0x327801b0 ; undefined
     340:	2c040033 	stnp	s19, s0, [x1, #32]
     344:	0000430d 	udf	#17165
     348:	7801b800 	sttrh	w0, [x0, #27]
     34c:	04003432 	saddv	d18, p5, z1.b
     350:	00430d2d 	.inst	0x00430d2d ; undefined
     354:	01c00000 	.inst	0x01c00000 ; undefined
     358:	00353278 	.inst	0x00353278 ; undefined
     35c:	430d2e04 	.inst	0x430d2e04 ; undefined
     360:	c8000000 	stxr	w0, x0, [x0]
     364:	36327801 	tbz	w1, #6, 5264 <MAIR_ATTR+0xe64>
     368:	0d2f0400 	.inst	0x0d2f0400 ; undefined
     36c:	00000043 	udf	#67
     370:	327801d0 	.inst	0x327801d0 ; undefined
     374:	30040037 	adr	x23, 8379 <MAIR_ATTR+0x3f79>
     378:	0000430d 	udf	#17165
     37c:	7801d800 	sttrh	w0, [x0, #29]
     380:	04003832 	saddv	d18, p6, z1.b
     384:	00430d31 	.inst	0x00430d31 ; undefined
     388:	01e00000 	.inst	0x01e00000 ; undefined
     38c:	00393278 	.inst	0x00393278 ; undefined
     390:	430d3204 	.inst	0x430d3204 ; undefined
     394:	e8000000 	sttnp	x0, x0, [x0]
     398:	30337801 	adr	x1, 67299 <MAIR_ATTR+0x62e99>
     39c:	0d330400 	.inst	0x0d330400 ; undefined
     3a0:	00000043 	udf	#67
     3a4:	707301f0 	adr	x16, e63e3 <MAIR_ATTR+0xe1fe3>
     3a8:	34040030 	cbz	w16, 83ac <MAIR_ATTR+0x3fac>
     3ac:	0000430d 	udf	#17165
     3b0:	3b09f800 	.inst	0x3b09f800 ; undefined
     3b4:	35000002 	cbnz	w2, 3b4 <TCR_T0SZ+0x3a4>
     3b8:	00000043 	udf	#67
     3bc:	650a0100 	bfadd	z0.h, z8.h, z10.h
     3c0:	36007273 	tbz	w19, #0, 120c <_binary_init_bin_size+0xac4>
     3c4:	00000043 	udf	#67
     3c8:	650a0108 	bfadd	z8.h, z8.h, z10.h
     3cc:	3700726c 	tbnz	w12, #0, 1218 <_binary_init_bin_size+0xad0>
     3d0:	00000043 	udf	#67
     3d4:	c3090110 	.inst	0xc3090110 ; undefined
     3d8:	38000001 	sturb	w1, [x0]
     3dc:	00000043 	udf	#67
     3e0:	06000118 	.inst	0x06000118 ; undefined
     3e4:	000001c8 	udf	#456
     3e8:	0b080538 	add	w24, w9, w8, lsl #1
     3ec:	02000003 	.inst	0x02000003 ; undefined
     3f0:	00000236 	udf	#566
     3f4:	960f0905 	bl	fffffffff83c2808 <FS_BASE+0xffffc83c2808>
     3f8:	00000000 	udf	#0
     3fc:	64697001 	.inst	0x64697001 ; undefined
     400:	090a0500 	.inst	0x090a0500 ; undefined
     404:	0000003c 	udf	#60
     408:	01bd0208 	.inst	0x01bd0208 ; undefined
     40c:	0b050000 	add	w0, w0, w5
     410:	00003c06 	udf	#15366
     414:	cc020c00 	.inst	0xcc020c00 ; undefined
     418:	05000009 	orr	z9.s, z9.s, #0x1
     41c:	003c070c 	.inst	0x003c070c ; undefined
     420:	02100000 	.inst	0x02100000 ; undefined
     424:	00000910 	udf	#2320
     428:	6a0b0d05 	ands	w5, w8, w11, lsl #3
     42c:	18000000 	ldr	w0, 42c <TCR_T0SZ+0x41c>
     430:	00021702 	.inst	0x00021702 ; undefined
     434:	0b0e0500 	add	w0, w8, w14, lsl #1
     438:	0000006a 	udf	#106
     43c:	035f0220 	.inst	0x035f0220 ; undefined
     440:	0f050000 	fdot	v0.2s, v0.8b, v5.4b[0]
     444:	00006a0b 	udf	#27147
     448:	74012800 	cbgt	w0, w1, 148 <TCR_T0SZ+0x138>
     44c:	10050066 	adr	x6, a458 <MAIR_ATTR+0x6058>
     450:	00030b14 	.inst	0x00030b14 ; undefined
     454:	07003000 	.inst	0x07003000 ; undefined
     458:	000000c2 	udf	#194
     45c:	0001de0b 	.inst	0x0001de0b ; undefined
     460:	960e2b00 	bl	fffffffff838b060 <FS_BASE+0xffffc838b060>
     464:	28000000 	stnp	w0, w0, [x0]
     468:	00000803 	udf	#2051
     46c:	c4ffff00 	ldff1h	{z0.d}, p7/z, [x24, z31.d, lsl #1]
     470:	00000000 	udf	#0
     474:	01000000 	.inst	0x01000000 ; undefined
     478:	0003759c 	.inst	0x0003759c ; undefined
     47c:	03230400 	.inst	0x03230400 ; undefined
     480:	2b2b0000 	adds	w0, w0, w11, uxtb
     484:	00000375 	udf	#885
     488:	04589102 	asr	z2.h, p4/m, z2.h, z8.d
     48c:	000009cc 	udf	#2508
     490:	003c352b 	.inst	0x003c352b ; undefined
     494:	91020000 	add	x0, x0, #0x80
     498:	01f80554 	.inst	0x01f80554 ; undefined
     49c:	962d0000 	bl	fffffffff8b4049c <FS_BASE+0xffffc8b4049c>
     4a0:	02000000 	.inst	0x02000000 ; undefined
     4a4:	20057891 	.inst	0x20057891 ; undefined
     4a8:	2e000002 	ext	v2.8b, v0.8b, v0.8b, #0
     4ac:	00000096 	udf	#150
     4b0:	05709102 	.inst	0x05709102 ; undefined
     4b4:	000001d0 	udf	#464
     4b8:	0000962f 	udf	#38447
     4bc:	68910200 	stgp	x0, x0, [x16], #544
     4c0:	009b0700 	.inst	0x009b0700 ; undefined
     4c4:	ea0b0000 	ands	x0, x0, x11
     4c8:	26000001 	.inst	0x26000001 ; undefined
     4cc:	0003aa06 	.inst	0x0003aa06 ; undefined
     4d0:	08030400 	stxrb	w3, w0, [x0]
     4d4:	ff000000 	.inst	0xff000000 ; undefined
     4d8:	000024ff 	udf	#9471
     4dc:	00000000 	udf	#0
     4e0:	aa9c0100 	orr	x0, x8, x28, asr #0
     4e4:	04000003 	add	z3.b, p0/m, z3.b, z0.b
     4e8:	00000323 	udf	#803
     4ec:	03752526 	.inst	0x03752526 ; undefined
     4f0:	91020000 	add	x0, x0, #0x80
     4f4:	01030078 	.inst	0x01030078 ; undefined
     4f8:	00020002 	.inst	0x00020002 ; undefined
     4fc:	02060f00 	.inst	0x02060f00 ; undefined
     500:	14010000 	b	40500 <MAIR_ATTR+0x3c100>
     504:	0000960e 	udf	#38414
     508:	08029800 	stlxrb	w2, w0, [x0]
     50c:	ff000000 	.inst	0xff000000 ; undefined
     510:	00006cff 	udf	#27903
     514:	00000000 	udf	#0
     518:	ef9c0100 	.inst	0xef9c0100 ; undefined
     51c:	04000003 	add	z3.b, p0/m, z3.b, z0.b
     520:	00000323 	udf	#803
     524:	03753014 	.inst	0x03753014 ; undefined
     528:	91020000 	add	x0, x0, #0x80
     52c:	01d00568 	.inst	0x01d00568 ; undefined
     530:	96160000 	bl	fffffffff8580530 <FS_BASE+0xffffc8580530>
     534:	02000000 	.inst	0x02000000 ; undefined
     538:	10007891 	adr	x17, 1448 <_binary_init_bin_size+0xd00>
     53c:	00000225 	udf	#549
     540:	24060601 	cmphs	p1.b, p1/z, z16.b, z6.b
     544:	00000802 	udf	#2050
     548:	74ffff00 	cbhne	w0, wzr, 528 <TCR_T0SZ+0x518>
     54c:	00000000 	udf	#0
     550:	01000000 	.inst	0x01000000 ; undefined
     554:	0323049c 	.inst	0x0323049c ; undefined
     558:	28060000 	stnp	w0, w0, [x0, #48]
     55c:	00000375 	udf	#885
     560:	04789102 	asr	z2.s, z8.s, #8
     564:	000001d0 	udf	#464
     568:	00963b06 	.inst	0x00963b06 ; undefined
     56c:	91020000 	add	x0, x0, #0x80
     570:	c5000070 	ld1sw	{z16.d}, p0/z, [x3, z0.d, uxtw]
     574:	05000001 	orr	z1.s, z1.s, #0x1
     578:	fe080100 	.inst	0xfe080100 ; undefined
     57c:	09000001 	.inst	0x09000001 ; undefined
     580:	00000063 	udf	#99
     584:	0000d60c 	udf	#54796
     588:	00000000 	udf	#0
     58c:	0803ec00 	stlxrb	w3, w0, [x0]
     590:	ff000000 	.inst	0xff000000 ; undefined
     594:	00027cff 	.inst	0x00027cff ; undefined
     598:	00000000 	udf	#0
     59c:	00028000 	.inst	0x00028000 ; undefined
     5a0:	06010100 	.inst	0x06010100 ; undefined
     5a4:	00000133 	udf	#307
     5a8:	a3050201 	.inst	0xa3050201 ; undefined
     5ac:	0a000001 	and	w1, w0, w0
     5b0:	6e690504 	uhadd	v4.8h, v8.8h, v9.8h
     5b4:	08010074 	stxrb	w1, w20, [x3]
     5b8:	00013f05 	.inst	0x00013f05 ; undefined
     5bc:	08010100 	stxrb	w1, w0, [x8]
     5c0:	00000131 	udf	#305
     5c4:	7c070201 	stur	h1, [x16, #112]
     5c8:	04000001 	add	z1.b, p0/m, z1.b, z0.b
     5cc:	00000291 	udf	#657
     5d0:	00006234 	udf	#25140
     5d4:	07040100 	.inst	0x07040100 ; undefined
     5d8:	00000155 	udf	#341
     5dc:	00010f04 	.inst	0x00010f04 ; undefined
     5e0:	00733700 	.inst	0x00733700 ; undefined
     5e4:	08010000 	stxrb	w1, w0, [x0]
     5e8:	00015007 	.inst	0x00015007 ; undefined
     5ec:	02600500 	.inst	0x02600500 ; undefined
     5f0:	8a100000 	and	x0, x0, x16
     5f4:	02000000 	.inst	0x02000000 ; undefined
     5f8:	00000069 	udf	#105
     5fc:	02660500 	.inst	0x02660500 ; undefined
     600:	9f110000 	.inst	0x9f110000 ; undefined
     604:	02000000 	.inst	0x02000000 ; undefined
     608:	00000069 	udf	#105
     60c:	00005802 	udf	#22530
     610:	420b0000 	.inst	0x420b0000 ; undefined
     614:	03000002 	.inst	0x03000002 ; undefined
     618:	00580a12 	.inst	0x00580a12 ; undefined
     61c:	00b50000 	.inst	0x00b50000 ; undefined
     620:	69020000 	stgp	x0, x0, [x0, #64]
     624:	00000000 	udf	#0
     628:	00004803 	udf	#18435
     62c:	05342900 	tbl	z0.b, {z8.b-z9.b}, z20.b
     630:	00000008 	udf	#8
     634:	0134ffff 	.inst	0x0134ffff ; undefined
     638:	00000000 	udf	#0
     63c:	9c010000 	ldr	q0, 263c <_binary_init_bin_size+0x1ef4>
     640:	000000df 	udf	#223
     644:	00024a06 	.inst	0x00024a06 ; undefined
     648:	00582b00 	.inst	0x00582b00 ; undefined
     64c:	91020000 	add	x0, x0, #0x80
     650:	8403007c 	ld1sb	{z28.s}, p0/z, [x3, z3.s, uxtw]
     654:	16000002 	b	fffffffff800065c <FS_BASE+0xffffc800065c>
     658:	000804bc 	.inst	0x000804bc ; undefined
     65c:	ffff0000 	.inst	0xffff0000 ; undefined
     660:	00000078 	udf	#120
     664:	00000000 	udf	#0
     668:	01279c01 	.inst	0x01279c01 ; undefined
     66c:	8b060000 	add	x0, x0, x6
     670:	18000003 	ldr	w3, 670 <TCR_T0SZ+0x660>
     674:	00000058 	udf	#88
     678:	077c9102 	.inst	0x077c9102 ; undefined
     67c:	000804e8 	.inst	0x000804e8 ; undefined
     680:	ffff0000 	.inst	0xffff0000 ; undefined
     684:	00000040 	udf	#64
     688:	00000000 	udf	#0
     68c:	00686308 	.inst	0x00686308 ; undefined
     690:	0001271b 	.inst	0x0001271b ; undefined
     694:	7b910200 	.inst	0x7b910200 ; undefined
     698:	01010000 	.inst	0x01010000 ; undefined
     69c:	00013a08 	.inst	0x00013a08 ; undefined
     6a0:	01270c00 	.inst	0x01270c00 ; undefined
     6a4:	53030000 	ubfiz	w0, w0, #29, #1
     6a8:	0f000002 	fdot	v2.2s, v0.8b, v0.4b[0]
     6ac:	00080460 	.inst	0x00080460 ; undefined
     6b0:	ffff0000 	.inst	0xffff0000 ; undefined
     6b4:	0000005c 	udf	#92
     6b8:	00000000 	udf	#0
     6bc:	017c9c01 	.inst	0x017c9c01 ; undefined
     6c0:	ec0d0000 	sttnp	q0, q0, [x0, #416]
     6c4:	01000002 	.inst	0x01000002 ; undefined
     6c8:	017c1f0f 	.inst	0x017c1f0f ; undefined
     6cc:	91020000 	add	x0, x0, #0x80
     6d0:	046c0768 	sub	z8.h, z27.h, z12.h
     6d4:	00000008 	udf	#8
     6d8:	0040ffff 	.inst	0x0040ffff ; undefined
     6dc:	00000000 	udf	#0
     6e0:	69080000 	stgp	x0, x0, [x0, #256]
     6e4:	003c1100 	.inst	0x003c1100 ; undefined
     6e8:	91020000 	add	x0, x0, #0x80
     6ec:	0e00007c 	tbl	v28.8b, {v3.16b}, v0.8b
     6f0:	00012e08 	.inst	0x00012e08 ; undefined
     6f4:	026f0f00 	.inst	0x026f0f00 ; undefined
     6f8:	0a010000 	and	w0, w0, w1
     6fc:	00004a0f 	udf	#18959
     700:	08043c00 	stxrb	w4, w0, [x0]
     704:	ff000000 	.inst	0xff000000 ; undefined
     708:	000024ff 	udf	#9471
     70c:	00000000 	udf	#0
     710:	109c0100 	adr	x0, fffffffffff38730 <FS_BASE+0xffffcff38730>
     714:	00000279 	udf	#633
     718:	ec060401 	sttnp	q1, q1, [x0, #192]
     71c:	00000803 	udf	#2051
     720:	50ffff00 	adr	x0, 702 <TCR_T0SZ+0x6f2>
     724:	00000000 	udf	#0
     728:	01000000 	.inst	0x01000000 ; undefined
     72c:	0063119c 	.inst	0x0063119c ; undefined
     730:	4a1f0401 	eor	w1, w0, wzr, lsl #1
     734:	02000000 	.inst	0x02000000 ; undefined
     738:	00007f91 	udf	#32657
     73c:	0000040d 	udf	#1037
     740:	08010005 	stxrb	w1, w5, [x0]
     744:	00000320 	udf	#800
     748:	0000630c 	udf	#25356
     74c:	00dd0c00 	.inst	0x00dd0c00 ; undefined
     750:	00000000 	udf	#0
     754:	06680000 	.inst	0x06680000 ; undefined
     758:	00000008 	udf	#8
     75c:	068cffff 	.inst	0x068cffff ; undefined
     760:	00000000 	udf	#0
     764:	035e0000 	.inst	0x035e0000 ; undefined
     768:	01030000 	.inst	0x01030000 ; undefined
     76c:	00013306 	.inst	0x00013306 ; undefined
     770:	05020300 	orr	z0.d, z0.d, #0x1ffffff
     774:	000001a3 	udf	#419
     778:	6905040d 	stgp	x13, x1, [x0, #160]
     77c:	0500746e 	orr	z14.h, z14.h, #0x3c
     780:	00000110 	udf	#272
     784:	4f182b02 	.inst	0x4f182b02 ; undefined
     788:	03000000 	.inst	0x03000000 ; undefined
     78c:	013f0508 	.inst	0x013f0508 ; undefined
     790:	01030000 	.inst	0x01030000 ; undefined
     794:	00013108 	.inst	0x00013108 ; undefined
     798:	07020300 	.inst	0x07020300 ; undefined
     79c:	0000017c 	udf	#380
     7a0:	55070403 	.inst	0x55070403 ; undefined
     7a4:	05000001 	orr	z1.s, z1.s, #0x1
     7a8:	0000010f 	udf	#271
     7ac:	77193702 	.inst	0x77193702 ; undefined
     7b0:	03000000 	.inst	0x03000000 ; undefined
     7b4:	01500708 	.inst	0x01500708 ; undefined
     7b8:	fe050000 	.inst	0xfe050000 ; undefined
     7bc:	03000002 	.inst	0x03000002 ; undefined
     7c0:	008a1b28 	.inst	0x008a1b28 ; undefined
     7c4:	1e0e0000 	.inst	0x1e0e0000 ; undefined
     7c8:	20000003 	.inst	0x20000003 ; undefined
     7cc:	00c90004 	.inst	0x00c90004 ; undefined
     7d0:	5d040000 	.inst	0x5d040000 ; undefined
     7d4:	c9000003 	.inst	0xc9000003 ; undefined
     7d8:	00000000 	udf	#0
     7dc:	0002de04 	.inst	0x0002de04 ; undefined
     7e0:	0000c900 	udf	#51456
     7e4:	41040800 	.inst	0x41040800 ; undefined
     7e8:	c9000003 	.inst	0xc9000003 ; undefined
     7ec:	10000000 	adr	x0, 7ec <_binary_init_bin_size+0xa4>
     7f0:	00031404 	.inst	0x00031404 ; undefined
     7f4:	00003c00 	udf	#15360
     7f8:	28041800 	stnp	w0, w6, [x0, #32]
     7fc:	3c000003 	stur	b3, [x0]
     800:	1c000000 	ldr	s0, 800 <_binary_init_bin_size+0xb8>
     804:	05080f00 	.inst	0x05080f00 ; undefined
     808:	00000320 	udf	#800
     80c:	7e186803 	.inst	0x7e186803 ; undefined
     810:	10000000 	adr	x0, 810 <_binary_init_bin_size+0xc8>
     814:	00000279 	udf	#633
     818:	e9061705 	sttp	x5, x5, [x24, #96]
     81c:	11000000 	add	w0, w0, #0x0
     820:	00000056 	udf	#86
     824:	01961200 	.inst	0x01961200 ; undefined
     828:	4b010000 	sub	w0, w0, w1
     82c:	00003c05 	udf	#15365
     830:	08099c00 	stlxrb	w9, w0, [x0]
     834:	ff000000 	.inst	0xff000000 ; undefined
     838:	000358ff 	.inst	0x000358ff ; undefined
     83c:	00000000 	udf	#0
     840:	859c0100 	ldr	p0, [x8, #224, mul vl]
     844:	01000001 	.inst	0x01000001 ; undefined
     848:	0000030d 	udf	#781
     84c:	0185184b 	.inst	0x0185184b ; undefined
     850:	91030000 	add	x0, x0, #0xc0
     854:	021376f8 	.inst	0x021376f8 ; undefined
     858:	000002af 	udf	#687
     85c:	01960a4d 	.inst	0x01960a4d ; undefined
     860:	91030000 	add	x0, x0, #0xc0
     864:	bb0277a8 	.inst	0xbb0277a8 ; undefined
     868:	4e000002 	tbl	v2.16b, {v0.16b}, v0.16b
     86c:	00003c09 	udf	#15369
     870:	bc910300 	.inst	0xbc910300 ; undefined
     874:	0339027f 	.inst	0x0339027f ; undefined
     878:	0d4f0000 	.inst	0x0d4f0000 ; undefined
     87c:	00000043 	udf	#67
     880:	7fb09103 	fmulx	s3, s8, v16.s[1]
     884:	0002ec02 	.inst	0x0002ec02 ; undefined
     888:	a70b5000 	.inst	0xa70b5000 ; undefined
     88c:	03000001 	.inst	0x03000001 ; undefined
     890:	027fa891 	.inst	0x027fa891 ; undefined
     894:	000002b6 	udf	#694
     898:	00cb0d51 	.inst	0x00cb0d51 ; undefined
     89c:	91030000 	add	x0, x0, #0xc0
     8a0:	f8067788 	str	x8, [x28], #103
     8a4:	00000809 	udf	#2057
     8a8:	e0ffff00 	st1d	{za0v.d[w15, 0]}, p7, [x24, xzr, lsl #3]
     8ac:	00000002 	udf	#2
     8b0:	07000000 	.inst	0x07000000 ; undefined
     8b4:	3c550069 	ldur	b9, [x3, #-176]
     8b8:	03000000 	.inst	0x03000000 ; undefined
     8bc:	007fb891 	.inst	0x007fb891 ; undefined
     8c0:	01910a00 	.inst	0x01910a00 ; undefined
     8c4:	01030000 	.inst	0x01030000 ; undefined
     8c8:	00013a08 	.inst	0x00013a08 ; undefined
     8cc:	018a1400 	.inst	0x018a1400 ; undefined
     8d0:	8a080000 	and	x0, x0, x8
     8d4:	a7000001 	.inst	0xa7000001 ; undefined
     8d8:	15000001 	b	40008dc <FS_SIZE+0xe4a8dc>
     8dc:	00000077 	udf	#119
     8e0:	0a0003ff 	and	wzr, wzr, w0
     8e4:	0000018a 	udf	#394
     8e8:	00029a16 	.inst	0x00029a16 ; undefined
     8ec:	06440100 	.inst	0x06440100 ; undefined
     8f0:	00080944 	.inst	0x00080944 ; undefined
     8f4:	ffff0000 	.inst	0xffff0000 ; undefined
     8f8:	00000058 	udf	#88
     8fc:	00000000 	udf	#0
     900:	02049c01 	.inst	0x02049c01 ; undefined
     904:	af010000 	.inst	0xaf010000 ; undefined
     908:	44000002 	.inst	0x44000002 ; undefined
     90c:	00018520 	.inst	0x00018520 ; undefined
     910:	68910200 	stgp	x0, x0, [x16], #544
     914:	00079c01 	.inst	0x00079c01 ; undefined
     918:	3c2c4400 	.inst	0x3c2c4400 ; undefined
     91c:	02000000 	.inst	0x02000000 ; undefined
     920:	54066491 	bc.ne	d5b0 <MAIR_ATTR+0x91b0>  // bc.any
     924:	00000809 	udf	#2057
     928:	38ffff00 	.inst	0x38ffff00 ; undefined
     92c:	00000000 	udf	#0
     930:	07000000 	.inst	0x07000000 ; undefined
     934:	3c460069 	ldur	b9, [x3, #96]
     938:	02000000 	.inst	0x02000000 ; undefined
     93c:	00007c91 	udf	#31889
     940:	00034b17 	.inst	0x00034b17 ; undefined
     944:	0c360100 	.inst	0x0c360100 ; undefined
     948:	0000003c 	udf	#60
     94c:	000808bc 	.inst	0x000808bc ; undefined
     950:	ffff0000 	.inst	0xffff0000 ; undefined
     954:	00000088 	udf	#136
     958:	00000000 	udf	#0
     95c:	025f9c01 	.inst	0x025f9c01 ; undefined
     960:	af010000 	.inst	0xaf010000 ; undefined
     964:	36000002 	tbz	w2, #0, 964 <_binary_init_bin_size+0x21c>
     968:	0001a724 	.inst	0x0001a724 ; undefined
     96c:	68910200 	stgp	x0, x0, [x16], #544
     970:	0002d501 	.inst	0x0002d501 ; undefined
     974:	3c303600 	.inst	0x3c303600 ; undefined
     978:	02000000 	.inst	0x02000000 ; undefined
     97c:	32016491 	orr	w17, w4, #0x81ffffff
     980:	36000003 	tbz	w3, #0, 980 <_binary_init_bin_size+0x238>
     984:	00004342 	udf	#17218
     988:	58910200 	ldr	x0, fffffffffff229c8 <FS_BASE+0xffffcff229c8>
     98c:	00079c02 	.inst	0x00079c02 ; undefined
     990:	3c093800 	.inst	0x3c093800 ; undefined
     994:	02000000 	.inst	0x02000000 ; undefined
     998:	0b007c91 	add	w17, w4, w0, lsl #31
     99c:	0000034a 	udf	#842
     9a0:	00003c24 	udf	#15396
     9a4:	0807c400 	stlxrb	w7, w0, [x0]
     9a8:	ff000000 	.inst	0xff000000 ; undefined
     9ac:	0000f8ff 	udf	#63743
     9b0:	00000000 	udf	#0
     9b4:	f49c0100 	.inst	0xf49c0100 ; undefined
     9b8:	01000002 	.inst	0x01000002 ; undefined
     9bc:	000002af 	udf	#687
     9c0:	01a72524 	.inst	0x01a72524 ; undefined
     9c4:	91030000 	add	x0, x0, #0xc0
     9c8:	d5017fb8 	msr	s0_1_c7_c15_5, x24
     9cc:	24000002 	cmphs	p2.b, p0/z, z0.b, z0.b
     9d0:	00003c31 	udf	#15409
     9d4:	b4910300 	cbz	x0, fffffffffff22a34 <FS_BASE+0xffffcff22a34>
     9d8:	0332017f 	.inst	0x0332017f ; undefined
     9dc:	44240000 	sdot	z0.h, z0.b, z4.b[0]
     9e0:	0000006b 	udf	#107
     9e4:	7fa89103 	fmulx	s3, s8, v8.s[1]
     9e8:	0002f302 	.inst	0x0002f302 ; undefined
     9ec:	f40a2600 	cbgt	x0, x10, 6ac <TCR_T0SZ+0x69c>
     9f0:	02000002 	.inst	0x02000002 ; undefined
     9f4:	a8026891 	stnp	x17, x26, [x4, #32]
     9f8:	27000002 	.inst	0x27000002 ; undefined
     9fc:	0003040a 	.inst	0x0003040a ; undefined
     a00:	48910200 	stllrh	w0, [x16]
     a04:	00079c02 	.inst	0x00079c02 ; undefined
     a08:	3c092800 	.inst	0x3c092800 ; undefined
     a0c:	02000000 	.inst	0x02000000 ; undefined
     a10:	60067c91 	.inst	0x60067c91 ; undefined
     a14:	00000808 	udf	#2056
     a18:	50ffff00 	adr	x0, 9fa <_binary_init_bin_size+0x2b2>
     a1c:	00000000 	udf	#0
     a20:	07000000 	.inst	0x07000000 ; undefined
     a24:	3c2f0069 	ldbfadd	h15, h9, [x3]
     a28:	02000000 	.inst	0x02000000 ; undefined
     a2c:	00007891 	udf	#30865
     a30:	00018a08 	.inst	0x00018a08 ; undefined
     a34:	00030400 	.inst	0x00030400 ; undefined
     a38:	00770900 	.inst	0x00770900 ; undefined
     a3c:	00090000 	.inst	0x00090000 ; undefined
     a40:	00018a08 	.inst	0x00018a08 ; undefined
     a44:	00031400 	.inst	0x00031400 ; undefined
     a48:	00770900 	.inst	0x00770900 ; undefined
     a4c:	00180000 	.inst	0x00180000 ; undefined
     a50:	0002c70b 	.inst	0x0002c70b ; undefined
     a54:	003c1000 	.inst	0x003c1000 ; undefined
     a58:	06e00000 	.inst	0x06e00000 ; undefined
     a5c:	00000008 	udf	#8
     a60:	00e4ffff 	.inst	0x00e4ffff ; undefined
     a64:	00000000 	udf	#0
     a68:	9c010000 	ldr	q0, 2a68 <_binary_init_bin_size+0x2320>
     a6c:	000003a9 	udf	#937
     a70:	0002af01 	.inst	0x0002af01 ; undefined
     a74:	a7201000 	.inst	0xa7201000 ; undefined
     a78:	03000001 	.inst	0x03000001 ; undefined
     a7c:	017fb891 	.inst	0x017fb891 ; undefined
     a80:	000002d5 	udf	#725
     a84:	003c2c10 	.inst	0x003c2c10 ; undefined
     a88:	91030000 	add	x0, x0, #0xc0
     a8c:	32017fb4 	.inst	0x32017fb4 ; undefined
     a90:	10000003 	adr	x3, a90 <_binary_init_bin_size+0x348>
     a94:	00006b3f 	udf	#27455
     a98:	a8910300 	stp	x0, x0, [x24], #272
     a9c:	02a8027f 	.inst	0x02a8027f ; undefined
     aa0:	0a120000 	and	w0, w0, w18
     aa4:	00000304 	udf	#772
     aa8:	02589102 	.inst	0x02589102 ; undefined
     aac:	000002f3 	udf	#755
     ab0:	03a90a13 	.inst	0x03a90a13 ; undefined
     ab4:	91020000 	add	x0, x0, #0x80
     ab8:	079c0248 	.inst	0x079c0248 ; undefined
     abc:	09140000 	.inst	0x09140000 ; undefined
     ac0:	0000003c 	udf	#60
     ac4:	067c9102 	.inst	0x067c9102 ; undefined
     ac8:	00080744 	.inst	0x00080744 ; undefined
     acc:	ffff0000 	.inst	0xffff0000 ; undefined
     ad0:	00000050 	udf	#80
     ad4:	00000000 	udf	#0
     ad8:	1b006907 	madd	w7, w8, w0, w26
     adc:	0000003c 	udf	#60
     ae0:	00789102 	.inst	0x00789102 ; undefined
     ae4:	018a0800 	.inst	0x018a0800 ; undefined
     ae8:	03b90000 	.inst	0x03b90000 ; undefined
     aec:	77090000 	.inst	0x77090000 ; undefined
     af0:	0f000000 	fdot	v0.2s, v0.8b, v0.4b[0]
     af4:	02e71800 	.inst	0x02e71800 ; undefined
     af8:	05010000 	orr	z0.s, z0.s, #0x1
     afc:	00003c0c 	udf	#15372
     b00:	08066800 	stxrb	w6, w0, [x0]
     b04:	ff000000 	.inst	0xff000000 ; undefined
     b08:	000078ff 	udf	#30975
     b0c:	00000000 	udf	#0
     b10:	019c0100 	.inst	0x019c0100 ; undefined
     b14:	000002af 	udf	#687
     b18:	01a71e05 	.inst	0x01a71e05 ; undefined
     b1c:	91020000 	add	x0, x0, #0x80
     b20:	02d50168 	.inst	0x02d50168 ; undefined
     b24:	2a050000 	orr	w0, w0, w5
     b28:	0000003c 	udf	#60
     b2c:	01649102 	.inst	0x01649102 ; undefined
     b30:	000002ec 	udf	#748
     b34:	01854005 	.inst	0x01854005 ; undefined
     b38:	91020000 	add	x0, x0, #0x80
     b3c:	07e80258 	.inst	0x07e80258 ; undefined
     b40:	09070000 	.inst	0x09070000 ; undefined
     b44:	0000003c 	udf	#60
     b48:	007c9102 	.inst	0x007c9102 ; undefined
     b4c:	0000d500 	udf	#54528
     b50:	01000500 	.inst	0x01000500 ; undefined
     b54:	00049208 	.inst	0x00049208 ; undefined
     b58:	00630400 	.inst	0x00630400 ; undefined
     b5c:	f90c0000 	str	x0, [x0, #6144]
     b60:	00000000 	udf	#0
     b64:	f4000000 	cbgt	x0, x0, b64 <_binary_init_bin_size+0x41c>
     b68:	0000080c 	udf	#2060
     b6c:	50ffff00 	adr	x0, b4e <_binary_init_bin_size+0x406>
     b70:	00000000 	udf	#0
     b74:	5d000000 	.inst	0x5d000000 ; undefined
     b78:	01000005 	.inst	0x01000005 ; undefined
     b7c:	01330601 	.inst	0x01330601 ; undefined
     b80:	02010000 	.inst	0x02010000 ; undefined
     b84:	0001a305 	.inst	0x0001a305 ; undefined
     b88:	05040500 	.inst	0x05040500 ; undefined
     b8c:	00746e69 	.inst	0x00746e69 ; undefined
     b90:	3f050801 	.inst	0x3f050801 ; undefined
     b94:	01000001 	.inst	0x01000001 ; undefined
     b98:	01310801 	.inst	0x01310801 ; undefined
     b9c:	02010000 	.inst	0x02010000 ; undefined
     ba0:	00017c07 	.inst	0x00017c07 ; undefined
     ba4:	07040100 	.inst	0x07040100 ; undefined
     ba8:	00000155 	udf	#341
     bac:	00010f06 	.inst	0x00010f06 ; undefined
     bb0:	19370200 	.inst	0x19370200 ; undefined
     bb4:	0000006b 	udf	#107
     bb8:	50070801 	adr	x1, ecba <MAIR_ATTR+0xa8ba>
     bbc:	07000001 	.inst	0x07000001 ; undefined
     bc0:	00000196 	udf	#406
     bc4:	3c050603 	str	b3, [x16], #80
     bc8:	89000000 	.inst	0x89000000 ; undefined
     bcc:	08000000 	stxrb	w0, w0, [x0]
     bd0:	00000089 	udf	#137
     bd4:	95020009 	bl	4080bf8 <FS_SIZE+0xecabf8>
     bd8:	01000000 	.inst	0x01000000 ; undefined
     bdc:	013a0801 	.inst	0x013a0801 ; undefined
     be0:	8e0a0000 	.inst	0x8e0a0000 ; undefined
     be4:	0b000000 	add	w0, w0, w0
     be8:	0000036a 	udf	#874
     bec:	f4060401 	cbgt	x1, x6, c6c <_binary_init_bin_size+0x524>
     bf0:	0000080c 	udf	#2060
     bf4:	50ffff00 	adr	x0, bd6 <_binary_init_bin_size+0x48e>
     bf8:	00000000 	udf	#0
     bfc:	01000000 	.inst	0x01000000 ; undefined
     c00:	0000d39c 	udf	#54172
     c04:	07120300 	.inst	0x07120300 ; undefined
     c08:	d3180000 	.inst	0xd3180000 ; undefined
     c0c:	02000000 	.inst	0x02000000 ; undefined
     c10:	65037891 	.inst	0x65037891 ; undefined
     c14:	27000003 	.inst	0x27000003 ; undefined
     c18:	0000005f 	udf	#95
     c1c:	00709102 	.inst	0x00709102 ; undefined
     c20:	00008e02 	udf	#36354
     c24:	00250000 	.inst	0x00250000 ; undefined
     c28:	00050000 	.inst	0x00050000 ; undefined
     c2c:	052d0801 	ext	z1.b, z1.b, z0.b, #106
     c30:	bd010000 	str	s0, [x0, #256]
     c34:	00000005 	udf	#5
     c38:	00000810 	udf	#2064
     c3c:	8cffff00 	.inst	0x8cffff00 ; undefined
     c40:	00037614 	.inst	0x00037614 ; undefined
     c44:	00000700 	udf	#1792
     c48:	00002400 	udf	#9216
     c4c:	cc800100 	.inst	0xcc800100 ; undefined
     c50:	05000005 	orr	z5.s, z5.s, #0x1
     c54:	41080100 	.inst	0x41080100 ; undefined
     c58:	13000005 	sbfx	w5, w0, #0, #1
     c5c:	00000063 	udf	#99
     c60:	00010b0c 	.inst	0x00010b0c ; undefined
     c64:	00000000 	udf	#0
     c68:	081a0c00 	stxrb	w26, w0, [x0]
     c6c:	ff000000 	.inst	0xff000000 ; undefined
     c70:	000330ff 	.inst	0x000330ff ; undefined
     c74:	00000000 	udf	#0
     c78:	00067100 	.inst	0x00067100 ; undefined
     c7c:	06010400 	.inst	0x06010400 ; undefined
     c80:	00000133 	udf	#307
     c84:	a3050204 	.inst	0xa3050204 ; undefined
     c88:	14000001 	b	c8c <_binary_init_bin_size+0x544>
     c8c:	6e690504 	uhadd	v4.8h, v8.8h, v9.8h
     c90:	100a0074 	adr	x20, 14c9c <MAIR_ATTR+0x1089c>
     c94:	2b000001 	adds	w1, w0, w0
     c98:	00004e18 	udf	#19992
     c9c:	05080400 	.inst	0x05080400 ; undefined
     ca0:	0000013f 	udf	#319
     ca4:	31080104 	adds	w4, w8, #0x200
     ca8:	04000001 	add	z1.b, p0/m, z1.b, z0.b
     cac:	017c0702 	.inst	0x017c0702 ; undefined
     cb0:	910a0000 	add	x0, x0, #0x280
     cb4:	34000002 	cbz	w2, cb4 <_binary_init_bin_size+0x56c>
     cb8:	00006e19 	udf	#28185
     cbc:	07040400 	.inst	0x07040400 ; undefined
     cc0:	00000155 	udf	#341
     cc4:	00010f0a 	.inst	0x00010f0a ; undefined
     cc8:	80193700 	.inst	0x80193700 ; undefined
     ccc:	04000000 	add	z0.b, p0/m, z0.b, z0.b
     cd0:	01500708 	.inst	0x01500708 ; undefined
     cd4:	d9080000 	stlur	x0, [x0, #128]
     cd8:	08000001 	stxrb	w0, w1, [x0]
     cdc:	00a10703 	.inst	0x00a10703 ; undefined
     ce0:	36020000 	tbz	w0, #0, 4ce0 <MAIR_ATTR+0x8e0>
     ce4:	03000002 	.inst	0x03000002 ; undefined
     ce8:	00a10f08 	.inst	0x00a10f08 ; undefined
     cec:	00000000 	udf	#0
     cf0:	00008705 	udf	#34565
     cf4:	01d50800 	.inst	0x01d50800 ; undefined
     cf8:	03100000 	.inst	0x03100000 ; undefined
     cfc:	0000cd0b 	udf	#52491
     d00:	02360200 	.inst	0x02360200 ; undefined
     d04:	0c030000 	.inst	0x0c030000 ; undefined
     d08:	0000a10f 	udf	#41231
     d0c:	31020000 	adds	w0, w0, #0x80
     d10:	03000002 	.inst	0x03000002 ; undefined
     d14:	00a10f0d 	.inst	0x00a10f0d ; undefined
     d18:	00080000 	.inst	0x00080000 ; undefined
     d1c:	0001b315 	.inst	0x0001b315 ; undefined
     d20:	04012000 	uaddv	d0, p0, z0.b
     d24:	02a20814 	.inst	0x02a20814 ; undefined
     d28:	78010000 	sturh	w0, [x0, #16]
     d2c:	15040030 	b	4100dec <FS_SIZE+0xf4adec>
     d30:	0000430d 	udf	#17165
     d34:	78010000 	sturh	w0, [x0, #16]
     d38:	16040031 	b	fffffffff8100dfc <FS_BASE+0xffffc8100dfc>
     d3c:	0000430d 	udf	#17165
     d40:	78010800 	sttrh	w0, [x0, #16]
     d44:	17040032 	b	fffffffffc100e0c <FS_BASE+0xffffcc100e0c>
     d48:	0000430d 	udf	#17165
     d4c:	78011000 	sturh	w0, [x0, #17]
     d50:	18040033 	ldr	w19, 8d54 <MAIR_ATTR+0x4954>
     d54:	0000430d 	udf	#17165
     d58:	78011800 	sttrh	w0, [x0, #17]
     d5c:	19040034 	stlurb	w20, [x1, #64]
     d60:	0000430d 	udf	#17165
     d64:	78012000 	sturh	w0, [x0, #18]
     d68:	1a040035 	adc	w21, w1, w4
     d6c:	0000430d 	udf	#17165
     d70:	78012800 	sttrh	w0, [x0, #18]
     d74:	1b040036 	madd	w22, w1, w4, w0
     d78:	0000430d 	udf	#17165
     d7c:	78013000 	sturh	w0, [x0, #19]
     d80:	1c040037 	ldr	s23, 8d84 <MAIR_ATTR+0x4984>
     d84:	0000430d 	udf	#17165
     d88:	78013800 	sttrh	w0, [x0, #19]
     d8c:	1d040038 	.inst	0x1d040038 ; undefined
     d90:	0000430d 	udf	#17165
     d94:	78014000 	sturh	w0, [x0, #20]
     d98:	1e040039 	.inst	0x1e040039 ; undefined
     d9c:	0000430d 	udf	#17165
     da0:	78014800 	sttrh	w0, [x0, #20]
     da4:	04003031 	saddv	d17, p4, z1.b
     da8:	00430d1f 	.inst	0x00430d1f ; undefined
     dac:	01500000 	.inst	0x01500000 ; undefined
     db0:	00313178 	.inst	0x00313178 ; undefined
     db4:	430d2004 	.inst	0x430d2004 ; undefined
     db8:	58000000 	ldr	x0, db8 <_binary_init_bin_size+0x670>
     dbc:	32317801 	orr	w1, w0, #0xffffbfff
     dc0:	0d210400 	.inst	0x0d210400 ; undefined
     dc4:	00000043 	udf	#67
     dc8:	31780160 	adds	w0, w11, #0xe00, lsl #12
     dcc:	22040033 	.inst	0x22040033 ; undefined
     dd0:	0000430d 	udf	#17165
     dd4:	78016800 	sttrh	w0, [x0, #22]
     dd8:	04003431 	saddv	d17, p5, z1.b
     ddc:	00430d23 	.inst	0x00430d23 ; undefined
     de0:	01700000 	.inst	0x01700000 ; undefined
     de4:	00353178 	.inst	0x00353178 ; undefined
     de8:	430d2404 	.inst	0x430d2404 ; undefined
     dec:	78000000 	sturh	w0, [x0]
     df0:	36317801 	tbz	w1, #6, 3cf0 <_binary_init_bin_size+0x35a8>
     df4:	0d250400 	.inst	0x0d250400 ; undefined
     df8:	00000043 	udf	#67
     dfc:	31780180 	adds	w0, w12, #0xe00, lsl #12
     e00:	26040037 	.inst	0x26040037 ; undefined
     e04:	0000430d 	udf	#17165
     e08:	78018800 	sttrh	w0, [x0, #24]
     e0c:	04003831 	saddv	d17, p6, z1.b
     e10:	00430d27 	.inst	0x00430d27 ; undefined
     e14:	01900000 	.inst	0x01900000 ; undefined
     e18:	00393178 	.inst	0x00393178 ; undefined
     e1c:	430d2804 	.inst	0x430d2804 ; undefined
     e20:	98000000 	ldrsw	x0, e20 <_binary_init_bin_size+0x6d8>
     e24:	30327801 	adr	x1, 65d25 <MAIR_ATTR+0x61925>
     e28:	0d290400 	.inst	0x0d290400 ; undefined
     e2c:	00000043 	udf	#67
     e30:	327801a0 	.inst	0x327801a0 ; undefined
     e34:	2a040031 	orr	w17, w1, w4
     e38:	0000430d 	udf	#17165
     e3c:	7801a800 	sttrh	w0, [x0, #26]
     e40:	04003232 	saddv	d18, p4, z17.b
     e44:	00430d2b 	.inst	0x00430d2b ; undefined
     e48:	01b00000 	.inst	0x01b00000 ; undefined
     e4c:	00333278 	.inst	0x00333278 ; undefined
     e50:	430d2c04 	.inst	0x430d2c04 ; undefined
     e54:	b8000000 	stur	w0, [x0]
     e58:	34327801 	cbz	w1, 65d58 <MAIR_ATTR+0x61958>
     e5c:	0d2d0400 	.inst	0x0d2d0400 ; undefined
     e60:	00000043 	udf	#67
     e64:	327801c0 	.inst	0x327801c0 ; undefined
     e68:	2e040035 	ext	v21.8b, v1.8b, v4.8b, #0
     e6c:	0000430d 	udf	#17165
     e70:	7801c800 	sttrh	w0, [x0, #28]
     e74:	04003632 	saddv	d18, p5, z17.b
     e78:	00430d2f 	.inst	0x00430d2f ; undefined
     e7c:	01d00000 	.inst	0x01d00000 ; undefined
     e80:	00373278 	.inst	0x00373278 ; undefined
     e84:	430d3004 	.inst	0x430d3004 ; undefined
     e88:	d8000000 	prfm	pldl1keep, e88 <_binary_init_bin_size+0x740>
     e8c:	38327801 	strb	w1, [x0, x18, lsl #0]
     e90:	0d310400 	.inst	0x0d310400 ; undefined
     e94:	00000043 	udf	#67
     e98:	327801e0 	.inst	0x327801e0 ; undefined
     e9c:	32040039 	orr	w25, w1, #0x10000000
     ea0:	0000430d 	udf	#17165
     ea4:	7801e800 	sttrh	w0, [x0, #30]
     ea8:	04003033 	saddv	d19, p4, z1.b
     eac:	00430d33 	.inst	0x00430d33 ; undefined
     eb0:	01f00000 	.inst	0x01f00000 ; undefined
     eb4:	00307073 	.inst	0x00307073 ; undefined
     eb8:	430d3404 	.inst	0x430d3404 ; undefined
     ebc:	f8000000 	stur	x0, [x0]
     ec0:	00023b0d 	.inst	0x00023b0d ; undefined
     ec4:	00433500 	.inst	0x00433500 ; undefined
     ec8:	01000000 	.inst	0x01000000 ; undefined
     ecc:	7273650e 	.inst	0x7273650e ; undefined
     ed0:	00433600 	.inst	0x00433600 ; undefined
     ed4:	01080000 	.inst	0x01080000 ; undefined
     ed8:	726c650e 	.inst	0x726c650e ; undefined
     edc:	00433700 	.inst	0x00433700 ; undefined
     ee0:	01100000 	.inst	0x01100000 ; undefined
     ee4:	0001c30d 	.inst	0x0001c30d ; undefined
     ee8:	00433800 	.inst	0x00433800 ; undefined
     eec:	01180000 	.inst	0x01180000 ; undefined
     ef0:	01c80800 	.inst	0x01c80800 ; undefined
     ef4:	05380000 	ext	z0.b, z0.b, z0.b, #192
     ef8:	00031608 	.inst	0x00031608 ; undefined
     efc:	02360200 	.inst	0x02360200 ; undefined
     f00:	09050000 	.inst	0x09050000 ; undefined
     f04:	0000a10f 	udf	#41231
     f08:	70010000 	adr	x0, 2f0b <_binary_init_bin_size+0x27c3>
     f0c:	05006469 	orr	z9.h, z9.h, #0xf0
     f10:	003c090a 	.inst	0x003c090a ; undefined
     f14:	02080000 	.inst	0x02080000 ; undefined
     f18:	000001bd 	udf	#445
     f1c:	3c060b05 	.inst	0x3c060b05 ; undefined
     f20:	0c000000 	st4	{v0.8b-v3.8b}, [x0]
     f24:	0009cc02 	.inst	0x0009cc02 ; undefined
     f28:	070c0500 	.inst	0x070c0500 ; undefined
     f2c:	0000003c 	udf	#60
     f30:	09100210 	.inst	0x09100210 ; undefined
     f34:	0d050000 	.inst	0x0d050000 ; undefined
     f38:	0000750b 	udf	#29963
     f3c:	17021800 	b	fffffffffc086f3c <FS_BASE+0xffffcc086f3c>
     f40:	05000002 	orr	z2.s, z2.s, #0x1
     f44:	00750b0e 	.inst	0x00750b0e ; undefined
     f48:	02200000 	.inst	0x02200000 ; undefined
     f4c:	0000035f 	udf	#863
     f50:	750b0f05 	cbgt	w5, #22, 1130 <_binary_init_bin_size+0x9e8>
     f54:	28000000 	stnp	w0, w0, [x0]
     f58:	00667401 	.inst	0x00667401 ; undefined
     f5c:	16141005 	b	fffffffff8504f70 <FS_BASE+0xffffc8504f70>
     f60:	30000003 	adr	x3, f61 <_binary_init_bin_size+0x819>
     f64:	00cd0500 	.inst	0x00cd0500 ; undefined
     f68:	d7080000 	.inst	0xd7080000 ; undefined
     f6c:	38000003 	sturb	w3, [x0]
     f70:	035c1305 	.inst	0x035c1305 ; undefined
     f74:	e6020000 	.inst	0xe6020000 ; undefined
     f78:	05000003 	orr	z3.s, z3.s, #0x1
     f7c:	035c1214 	.inst	0x035c1214 ; undefined
     f80:	02000000 	.inst	0x02000000 ; undefined
     f84:	0000043e 	udf	#1086
     f88:	a6121505 	.inst	0xa6121505 ; undefined
     f8c:	08000000 	stxrb	w0, w0, [x0]
     f90:	00042702 	.inst	0x00042702 ; undefined
     f94:	12170500 	and	w0, w8, #0x600
     f98:	000000a6 	udf	#166
     f9c:	03b50218 	.inst	0x03b50218 ; undefined
     fa0:	18050000 	ldr	w0, afa0 <MAIR_ATTR+0x6ba0>
     fa4:	0000a612 	udf	#42514
     fa8:	05002800 	orr	z0.s, z0.s, #0x8000000
     fac:	000002a2 	udf	#674
     fb0:	00039606 	.inst	0x00039606 ; undefined
     fb4:	63110f00 	.inst	0x63110f00 ; undefined
     fb8:	09000000 	.inst	0x09000000 ; undefined
     fbc:	08d2c003 	.inst	0x08d2c003 ; undefined
     fc0:	ff000000 	.inst	0xff000000 ; undefined
     fc4:	09b606ff 	.inst	0x09b606ff ; undefined
     fc8:	11100000 	add	w0, w0, #0x400
     fcc:	00000075 	udf	#117
     fd0:	d2c80309 	mov	x9, #0x401800000000        	// #70471823392768
     fd4:	00000008 	udf	#8
     fd8:	490bffff 	.inst	0x490bffff ; undefined
     fdc:	05000004 	orr	z4.s, z4.s, #0x1
     fe0:	00570726 	.inst	0x00570726 ; undefined
     fe4:	08080000 	stxrb	w8, w0, [x0]
     fe8:	000003a3 	udf	#931
     fec:	00031603 	.inst	0x00031603 ; undefined
     ff0:	840b0000 	ld1sb	{z0.s}, p0/z, [x0, z11.s, uxtw]
     ff4:	06000002 	.inst	0x06000002 ; undefined
     ff8:	01960f1a 	.inst	0x01960f1a ; undefined
     ffc:	06070000 	.inst	0x06070000 ; undefined
    1000:	00003c05 	udf	#15365
    1004:	0003c100 	.inst	0x0003c100 ; undefined
    1008:	03c10300 	.inst	0x03c10300 ; undefined
    100c:	00160000 	.inst	0x00160000 ; undefined
    1010:	0003cd05 	.inst	0x0003cd05 ; undefined
    1014:	08010400 	stxrb	w1, w0, [x0]
    1018:	0000013a 	udf	#314
    101c:	0003c617 	.inst	0x0003c617 ; undefined
    1020:	02420f00 	.inst	0x02420f00 ; undefined
    1024:	12030000 	and	w0, w0, #0x20000000
    1028:	0000630a 	udf	#25354
    102c:	0003e800 	.inst	0x0003e800 ; undefined
    1030:	00750300 	.inst	0x00750300 ; undefined
    1034:	07000000 	.inst	0x07000000 ; undefined
    1038:	00000392 	udf	#914
    103c:	03f90c01 	.inst	0x03f90c01 ; undefined
    1040:	63030000 	.inst	0x63030000 ; undefined
    1044:	00000000 	udf	#0
    1048:	00044f07 	.inst	0x00044f07 ; undefined
    104c:	0a2a0500 	bic	w0, w8, w10, lsl #1
    1050:	03000004 	.inst	0x03000004 ; undefined
    1054:	0000003c 	udf	#60
    1058:	03800c00 	.inst	0x03800c00 ; undefined
    105c:	0b010000 	add	w0, w0, w1
    1060:	0000630a 	udf	#25354
    1064:	02250700 	.inst	0x02250700 ; undefined
    1068:	1a030000 	adc	w0, w0, w3
    106c:	0000042c 	udf	#1068
    1070:	00042c03 	.inst	0x00042c03 ; undefined
    1074:	00a10300 	.inst	0x00a10300 ; undefined
    1078:	05000000 	orr	z0.s, z0.s, #0x1
    107c:	000000a6 	udf	#166
    1080:	0003d00c 	.inst	0x0003d00c ; undefined
    1084:	18250500 	ldr	w0, 4b124 <MAIR_ATTR+0x46d24>
    1088:	0000043d 	udf	#1085
    108c:	00031b05 	.inst	0x00031b05 ; undefined
    1090:	04310b00 	.inst	0x04310b00 ; undefined
    1094:	0a010000 	and	w0, w0, w1
    1098:	0003a50c 	.inst	0x0003a50c ; undefined
    109c:	0a0d0100 	and	w0, w8, w13
    10a0:	00000063 	udf	#99
    10a4:	00026607 	.inst	0x00026607 ; undefined
    10a8:	6b110300 	subs	w0, w24, w17
    10ac:	03000004 	.inst	0x03000004 ; undefined
    10b0:	00000075 	udf	#117
    10b4:	00006303 	udf	#25347
    10b8:	1f100000 	fmadd	s0, s0, s16, s0
    10bc:	5b000004 	.inst	0x5b000004 ; undefined
    10c0:	00081c34 	.inst	0x00081c34 ; undefined
    10c4:	ffff0000 	.inst	0xffff0000 ; undefined
    10c8:	00000108 	udf	#264
    10cc:	00000000 	udf	#0
    10d0:	04b29c01 	lsl	z1.d, z0.d, #18
    10d4:	74180000 	cbgt	w0, w24, 10d4 <_binary_init_bin_size+0x98c>
    10d8:	5b010066 	.inst	0x5b010066 ; undefined
    10dc:	00031620 	.inst	0x00031620 ; undefined
    10e0:	68910200 	stgp	x0, x0, [x16], #544
    10e4:	71726909 	subs	w9, w8, #0xc9a, lsl #12
    10e8:	630e5d00 	.inst	0x630e5d00 ; undefined
    10ec:	02000000 	.inst	0x02000000 ; undefined
    10f0:	57067891 	.inst	0x57067891 ; undefined
    10f4:	5e000004 	sha1c	q4, s0, v0.4s
    10f8:	00003c09 	udf	#15369
    10fc:	7c910200 	.inst	0x7c910200 ; undefined
    1100:	03f61900 	.inst	0x03f61900 ; undefined
    1104:	56010000 	.inst	0x56010000 ; undefined
    1108:	00006311 	udf	#25361
    110c:	081c1400 	stxrb	w28, w0, [x0]
    1110:	ff000000 	.inst	0xff000000 ; undefined
    1114:	000020ff 	udf	#8447
    1118:	00000000 	udf	#0
    111c:	1a9c0100 	csel	w0, w8, w28, eq	// eq = none
    1120:	0000040f 	udf	#1039
    1124:	b40d4701 	cbz	x1, 1ba04 <MAIR_ATTR+0x17604>
    1128:	0000081b 	udf	#2075
    112c:	60ffff00 	.inst	0x60ffff00 ; undefined
    1130:	00000000 	udf	#0
    1134:	01000000 	.inst	0x01000000 ; undefined
    1138:	0004fd9c 	.inst	0x0004fd9c ; undefined
    113c:	038b0600 	.inst	0x038b0600 ; undefined
    1140:	0e490000 	.inst	0x0e490000 ; undefined
    1144:	00000063 	udf	#99
    1148:	007c9102 	.inst	0x007c9102 ; undefined
    114c:	0003bf10 	.inst	0x0003bf10 ; undefined
    1150:	1ad42700 	lsr	w0, w24, w20
    1154:	00000008 	udf	#8
    1158:	00e0ffff 	.inst	0x00e0ffff ; undefined
    115c:	00000000 	udf	#0
    1160:	9c010000 	ldr	q0, 3160 <_binary_init_bin_size+0x2a18>
    1164:	00000581 	udf	#1409
    1168:	00637009 	.inst	0x00637009 ; undefined
    116c:	043d1c29 	uqsub	z9.b, z1.b, z29.b
    1170:	91020000 	add	x0, x0, #0x80
    1174:	75630968 	cblo	w8, #6, 12a0 <_binary_init_bin_size+0xb58>
    1178:	122a0072 	and	w18, w3, #0x400000
    117c:	000000a1 	udf	#161
    1180:	06789102 	.inst	0x06789102 ; undefined
    1184:	00000220 	udf	#544
    1188:	00a1122b 	.inst	0x00a1122b ; undefined
    118c:	91020000 	add	x0, x0, #0x80
    1190:	1b001170 	madd	w16, w11, w0, w4
    1194:	00000008 	udf	#8
    1198:	0098ffff 	.inst	0x0098ffff ; undefined
    119c:	00000000 	udf	#0
    11a0:	70090000 	adr	x0, 131a3 <MAIR_ATTR+0xeda3>
    11a4:	5c192f00 	ldr	d0, 33784 <MAIR_ATTR+0x2f384>
    11a8:	02000003 	.inst	0x02000003 ; undefined
    11ac:	2c116091 	stnp	s17, s24, [x4, #136]
    11b0:	0000081b 	udf	#2075
    11b4:	58ffff00 	ldr	x0, 1194 <_binary_init_bin_size+0xa4c>
    11b8:	00000000 	udf	#0
    11bc:	06000000 	.inst	0x06000000 ; undefined
    11c0:	00000236 	udf	#566
    11c4:	00a11a35 	.inst	0x00a11a35 ; undefined
    11c8:	91020000 	add	x0, x0, #0x80
    11cc:	00000058 	udf	#88
    11d0:	00003d12 	udf	#15634
    11d4:	1a802000 	csel	w0, w0, w0, cs	// cs = hs, nlast
    11d8:	00000008 	udf	#8
    11dc:	0054ffff 	.inst	0x0054ffff ; undefined
    11e0:	00000000 	udf	#0
    11e4:	9c010000 	ldr	q0, 31e4 <_binary_init_bin_size+0x2a9c>
    11e8:	00016212 	.inst	0x00016212 ; undefined
    11ec:	1a1c1700 	.inst	0x1a1c1700 ; undefined
    11f0:	00000008 	udf	#8
    11f4:	0064ffff 	.inst	0x0064ffff ; undefined
    11f8:	00000000 	udf	#0
    11fc:	9c010000 	ldr	q0, 31fc <_binary_init_bin_size+0x2ab4>
    1200:	0004051b 	.inst	0x0004051b ; undefined
    1204:	0a120100 	and	w0, w8, w18
    1208:	00000075 	udf	#117
    120c:	00081a0c 	.inst	0x00081a0c ; undefined
    1210:	ffff0000 	.inst	0xffff0000 ; undefined
    1214:	00000010 	udf	#16
    1218:	00000000 	udf	#0
    121c:	26009c01 	.inst	0x26009c01 ; undefined
    1220:	05000000 	orr	z0.s, z0.s, #0x1
    1224:	1c080100 	ldr	s0, 11244 <MAIR_ATTR+0xce44>
    1228:	01000007 	.inst	0x01000007 ; undefined
    122c:	000007bb 	udf	#1979
    1230:	00082000 	.inst	0x00082000 ; undefined
    1234:	ffff0000 	.inst	0xffff0000 ; undefined
    1238:	60028090 	.inst	0x60028090 ; undefined
    123c:	07000004 	.inst	0x07000004 ; undefined
    1240:	24000000 	cmphs	p0.b, p0/z, z0.b, z0.b
    1244:	01000000 	.inst	0x01000000 ; undefined
    1248:	00067d80 	.inst	0x00067d80 ; undefined
    124c:	01000500 	.inst	0x01000500 ; undefined
    1250:	00073008 	.inst	0x00073008 ; undefined
    1254:	00631000 	.inst	0x00631000 ; undefined
    1258:	1b0c0000 	madd	w0, w0, w12, w0
    125c:	00000001 	udf	#1
    1260:	10000000 	adr	x0, 1260 <_binary_init_bin_size+0xb18>
    1264:	000008a0 	udf	#2208
    1268:	a8ffff00 	ldp	x0, xzr, [x24], #-8
    126c:	00000009 	udf	#9
    1270:	4d000000 	st1	{v0.b}[8], [x0]
    1274:	05000008 	orr	z8.s, z8.s, #0x1
    1278:	01330601 	.inst	0x01330601 ; undefined
    127c:	02050000 	.inst	0x02050000 ; undefined
    1280:	0001a305 	.inst	0x0001a305 ; undefined
    1284:	05041100 	.inst	0x05041100 ; undefined
    1288:	00746e69 	.inst	0x00746e69 ; undefined
    128c:	3f050805 	.inst	0x3f050805 ; undefined
    1290:	05000001 	orr	z1.s, z1.s, #0x1
    1294:	01310801 	.inst	0x01310801 ; undefined
    1298:	02050000 	.inst	0x02050000 ; undefined
    129c:	00017c07 	.inst	0x00017c07 ; undefined
    12a0:	07040500 	.inst	0x07040500 ; undefined
    12a4:	00000155 	udf	#341
    12a8:	00010f12 	.inst	0x00010f12 ; undefined
    12ac:	19370600 	ldtadd	w23, w0, [x16]
    12b0:	0000006b 	udf	#107
    12b4:	50070805 	adr	x5, f3b6 <MAIR_ATTR+0xafb6>
    12b8:	13000001 	sbfx	w1, w0, #0, #1
    12bc:	0000046f 	udf	#1135
    12c0:	08070708 	stxrb	w7, w8, [x24]
    12c4:	0000008d 	udf	#141
    12c8:	00023614 	.inst	0x00023614 ; undefined
    12cc:	12080700 	and	w0, w24, #0x3000000
    12d0:	0000008d 	udf	#141
    12d4:	72080000 	ands	w0, w0, #0x1000000
    12d8:	15000000 	b	40012d8 <FS_SIZE+0xe4b2d8>
    12dc:	0000009d 	udf	#157
    12e0:	0000009d 	udf	#157
    12e4:	01050016 	.inst	0x01050016 ; undefined
    12e8:	00013a08 	.inst	0x00013a08 ; undefined
    12ec:	009d1700 	.inst	0x009d1700 ; undefined
    12f0:	8a0b0000 	and	x0, x0, x11
    12f4:	0b000004 	add	w4, w0, w0
    12f8:	00000092 	udf	#146
    12fc:	00058918 	.inst	0x00058918 ; undefined
    1300:	0a0e0100 	and	w0, w8, w14
    1304:	0000005f 	udf	#95
    1308:	d2d00309 	mov	x9, #0x801800000000        	// #140840567570432
    130c:	00000008 	udf	#8
    1310:	0902ffff 	.inst	0x0902ffff ; undefined
    1314:	11000005 	add	w5, w0, #0x0
    1318:	00007214 	udf	#29204
    131c:	d8030900 	prfm	pldl1keep, 743c <MAIR_ATTR+0x303c>
    1320:	000008d2 	udf	#2258
    1324:	19ffff00 	.inst	0x19ffff00 ; undefined
    1328:	00646e65 	.inst	0x00646e65 ; undefined
    132c:	9d0d1201 	.inst	0x9d0d1201 ; undefined
    1330:	0b000000 	add	w0, w0, w0
    1334:	00000563 	udf	#1379
    1338:	000092c9 	udf	#37577
    133c:	04b90b00 	.inst	0x04b90b00 ; undefined
    1340:	92ca0000 	mov	x0, #0xffffafffffffffff    	// #-87960930222081
    1344:	09000000 	.inst	0x09000000 ; undefined
    1348:	0000051e 	udf	#1310
    134c:	010f1301 	.inst	0x010f1301 ; undefined
    1350:	5f030000 	.inst	0x5f030000 ; undefined
    1354:	00000000 	udf	#0
    1358:	0004ff0e 	.inst	0x0004ff0e ; undefined
    135c:	3c320300 	ldbfadd	h18, h0, [x24]
    1360:	29000000 	stp	w0, w0, [x0]
    1364:	03000001 	.inst	0x03000001 ; undefined
    1368:	00000129 	udf	#297
    136c:	00005f03 	udf	#24323
    1370:	9d080000 	.inst	0x9d080000 ; undefined
    1374:	09000000 	.inst	0x09000000 ; undefined
    1378:	00000483 	udf	#1155
    137c:	01491502 	.inst	0x01491502 ; undefined
    1380:	49030000 	.inst	0x49030000 ; undefined
    1384:	03000001 	.inst	0x03000001 ; undefined
    1388:	00000149 	udf	#329
    138c:	00005803 	udf	#22531
    1390:	081a0000 	stxrb	w26, w0, [x0]
    1394:	0004d809 	.inst	0x0004d809 ; undefined
    1398:	66140200 	.inst	0x66140200 ; undefined
    139c:	03000001 	.inst	0x03000001 ; undefined
    13a0:	00000149 	udf	#329
    13a4:	00003c03 	udf	#15363
    13a8:	00580300 	.inst	0x00580300 ; undefined
    13ac:	0e000000 	tbl	v0.8b, {v0.16b}, v0.8b
    13b0:	00000196 	udf	#406
    13b4:	003c0604 	.inst	0x003c0604 ; undefined
    13b8:	017c0000 	.inst	0x017c0000 ; undefined
    13bc:	7c030000 	stur	h0, [x0, #48]
    13c0:	1b000001 	madd	w1, w0, w0, w0
    13c4:	00a40800 	.inst	0x00a40800 ; undefined
    13c8:	6a090000 	ands	w0, w0, w9
    13cc:	05000003 	orr	z3.s, z3.s, #0x1
    13d0:	0001970b 	.inst	0x0001970b ; undefined
    13d4:	01290300 	.inst	0x01290300 ; undefined
    13d8:	5f030000 	.inst	0x5f030000 ; undefined
    13dc:	00000000 	udf	#0
    13e0:	0001181c 	.inst	0x0001181c ; undefined
    13e4:	06f40100 	.inst	0x06f40100 ; undefined
    13e8:	0008a97c 	.inst	0x0008a97c ; undefined
    13ec:	ffff0000 	.inst	0xffff0000 ; undefined
    13f0:	0000003c 	udf	#60
    13f4:	00000000 	udf	#0
    13f8:	ce079c01 	.inst	0xce079c01 ; undefined
    13fc:	ef000004 	.inst	0xef000004 ; undefined
    1400:	0008a954 	.inst	0x0008a954 ; undefined
    1404:	ffff0000 	.inst	0xffff0000 ; undefined
    1408:	00000028 	udf	#40
    140c:	00000000 	udf	#0
    1410:	01dc9c01 	.inst	0x01dc9c01 ; undefined
    1414:	6d010000 	stp	d0, d0, [x0, #16]
    1418:	ef007061 	.inst	0xef007061 ; undefined
    141c:	00005f19 	udf	#24345
    1420:	78910200 	ldursh	x0, [x16, #-240]
    1424:	04e80c00 	subpt	z0.d, z0.d, z8.d
    1428:	06d50000 	.inst	0x06d50000 ; undefined
    142c:	00000236 	udf	#566
    1430:	0008a8a4 	.inst	0x0008a8a4 ; undefined
    1434:	ffff0000 	.inst	0xffff0000 ; undefined
    1438:	000000b0 	udf	#176
    143c:	00000000 	udf	#0
    1440:	02369c01 	.inst	0x02369c01 ; undefined
    1444:	6d010000 	stp	d0, d0, [x0, #16]
    1448:	d5007061 	msr	s0_0_c7_c0_3, x1
    144c:	00005f19 	udf	#24345
    1450:	68910200 	stgp	x0, x0, [x16], #544
    1454:	00055906 	.inst	0x00055906 ; undefined
    1458:	2924d500 	stp	w0, w21, [x8, #-220]
    145c:	02000001 	.inst	0x02000001 ; undefined
    1460:	8b026091 	add	x17, x4, x2, lsl #24
    1464:	d7000003 	.inst	0xd7000003 ; undefined
    1468:	0002360a 	.inst	0x0002360a ; undefined
    146c:	7f910200 	.inst	0x7f910200 ; undefined
    1470:	00054602 	.inst	0x00054602 ; undefined
    1474:	490bd800 	.inst	0x490bd800 ; undefined
    1478:	02000001 	.inst	0x02000001 ; undefined
    147c:	05007091 	orr	z17.s, z17.s, #0x7c0000
    1480:	02000201 	.inst	0x02000201 ; undefined
    1484:	27070000 	.inst	0x27070000 ; undefined
    1488:	cc000005 	.inst	0xcc000005 ; undefined
    148c:	0008a858 	.inst	0x0008a858 ; undefined
    1490:	ffff0000 	.inst	0xffff0000 ; undefined
    1494:	0000004c 	udf	#76
    1498:	00000000 	udf	#0
    149c:	02769c01 	.inst	0x02769c01 ; undefined
    14a0:	8d060000 	.inst	0x8d060000 ; undefined
    14a4:	cc000009 	.inst	0xcc000009 ; undefined
    14a8:	00005f22 	udf	#24354
    14ac:	68910200 	stgp	x0, x0, [x16], #544
    14b0:	00079c02 	.inst	0x00079c02 ; undefined
    14b4:	5f0ece00 	.inst	0x5f0ece00 ; undefined
    14b8:	02000000 	.inst	0x02000000 ; undefined
    14bc:	07007891 	.inst	0x07007891 ; undefined
    14c0:	00000474 	udf	#1140
    14c4:	08a81cc2 	.inst	0x08a81cc2 ; undefined
    14c8:	ff000000 	.inst	0xff000000 ; undefined
    14cc:	00003cff 	udf	#15615
    14d0:	00000000 	udf	#0
    14d4:	a19c0100 	usmopa	za0.s, p0/m, p0/m, z8.b, z28.b
    14d8:	01000002 	.inst	0x01000002 ; undefined
    14dc:	0070616d 	.inst	0x0070616d ; undefined
    14e0:	005f17c2 	.inst	0x005f17c2 ; undefined
    14e4:	91020000 	add	x0, x0, #0x80
    14e8:	df0d0078 	.inst	0xdf0d0078 ; undefined
    14ec:	bd000004 	str	s4, [x0]
    14f0:	0008a7fc 	.inst	0x0008a7fc ; undefined
    14f4:	ffff0000 	.inst	0xffff0000 ; undefined
    14f8:	00000020 	udf	#32
    14fc:	00000000 	udf	#0
    1500:	02cc9c01 	.inst	0x02cc9c01 ; undefined
    1504:	6d010000 	stp	d0, d0, [x0, #16]
    1508:	bd007061 	str	s1, [x3, #112]
    150c:	00005f1f 	udf	#24351
    1510:	78910200 	ldursh	x0, [x16, #-240]
    1514:	05150d00 	mov	z0.b, p5/z, #104
    1518:	60b10000 	.inst	0x60b10000 ; undefined
    151c:	000008a7 	udf	#2215
    1520:	9cffff00 	ldr	q0, 1500 <_binary_init_bin_size+0xdb8>
    1524:	00000000 	udf	#0
    1528:	01000000 	.inst	0x01000000 ; undefined
    152c:	0003239c 	.inst	0x0003239c ; undefined
    1530:	616d0100 	.inst	0x616d0100 ; undefined
    1534:	1fb10070 	.inst	0x1fb10070 ; undefined
    1538:	0000005f 	udf	#95
    153c:	04689102 	asr	z2.s, z8.s, #24
    1540:	00727470 	.inst	0x00727470 ; undefined
    1544:	03230fb3 	.inst	0x03230fb3 ; undefined
    1548:	91020000 	add	x0, x0, #0x80
    154c:	a7740a70 	.inst	0xa7740a70 ; undefined
    1550:	00000008 	udf	#8
    1554:	0078ffff 	.inst	0x0078ffff ; undefined
    1558:	00000000 	udf	#0
    155c:	69040000 	stgp	x0, x0, [x0, #128]
    1560:	3c0eb500 	str	b0, [x8], #235
    1564:	02000000 	.inst	0x02000000 ; undefined
    1568:	00007c91 	udf	#31889
    156c:	00005f08 	udf	#24328
    1570:	05940d00 	mov	z0.s, p4/z, #104
    1574:	5c9e0000 	ldr	d0, fffffffffff3d574 <FS_BASE+0xffffcff3d574>
    1578:	000008a6 	udf	#2214
    157c:	04ffff00 	uqdecd	x0, #24, mul #16
    1580:	00000001 	udf	#1
    1584:	01000000 	.inst	0x01000000 ; undefined
    1588:	0003ab9c 	.inst	0x0003ab9c ; undefined
    158c:	616d0100 	.inst	0x616d0100 ; undefined
    1590:	1f9e0070 	.inst	0x1f9e0070 ; undefined
    1594:	0000005f 	udf	#95
    1598:	04589102 	asr	z2.h, p4/m, z2.h, z8.d
    159c:	00646770 	.inst	0x00646770 ; undefined
    15a0:	03230fa0 	.inst	0x03230fa0 ; undefined
    15a4:	91020000 	add	x0, x0, #0x80
    15a8:	75700470 	cblo	w16, #32, 1634 <_binary_init_bin_size+0xeec>
    15ac:	0fa10064 	fmlal	v4.2s, v3.2h, v1.h[2]
    15b0:	00000323 	udf	#803
    15b4:	0a689102 	.inst	0x0a689102 ; undefined
    15b8:	0008a674 	.inst	0x0008a674 ; undefined
    15bc:	ffff0000 	.inst	0xffff0000 ; undefined
    15c0:	000000dc 	udf	#220
    15c4:	00000000 	udf	#0
    15c8:	a3006904 	.inst	0xa3006904 ; undefined
    15cc:	00003c0e 	udf	#15374
    15d0:	7c910200 	.inst	0x7c910200 ; undefined
    15d4:	08a6c00a 	.inst	0x08a6c00a ; undefined
    15d8:	ff000000 	.inst	0xff000000 ; undefined
    15dc:	000078ff 	udf	#30975
    15e0:	00000000 	udf	#0
    15e4:	006a0400 	.inst	0x006a0400 ; undefined
    15e8:	003c16a7 	.inst	0x003c16a7 ; undefined
    15ec:	91020000 	add	x0, x0, #0x80
    15f0:	00000078 	udf	#120
    15f4:	00054107 	.inst	0x00054107 ; undefined
    15f8:	a5908b00 	ld1d	{z0.q}, p2/z, [x24, x16, lsl #3]
    15fc:	00000008 	udf	#8
    1600:	00ccffff 	.inst	0x00ccffff ; undefined
    1604:	00000000 	udf	#0
    1608:	9c010000 	ldr	q0, 3608 <_binary_init_bin_size+0x2ec0>
    160c:	00000400 	udf	#1024
    1610:	70616d01 	adr	x1, c43b3 <MAIR_ATTR+0xbffb3>
    1614:	5f198b00 	.inst	0x5f198b00 ; undefined
    1618:	02000000 	.inst	0x02000000 ; undefined
    161c:	3a066891 	.inst	0x3a066891 ; undefined
    1620:	8b000005 	add	x5, x0, x0
    1624:	00005f27 	udf	#24359
    1628:	60910200 	.inst	0x60910200 ; undefined
    162c:	0007e802 	.inst	0x0007e802 ; undefined
    1630:	58128d00 	ldr	x0, 267d0 <MAIR_ATTR+0x223d0>
    1634:	02000000 	.inst	0x02000000 ; undefined
    1638:	70047491 	adr	x17, a4cb <MAIR_ATTR+0x60cb>
    163c:	8e007274 	.inst	0x8e007274 ; undefined
    1640:	0003230f 	.inst	0x0003230f ; undefined
    1644:	78910200 	ldursh	x0, [x16, #-240]
    1648:	04660c00 	.inst	0x04660c00 ; undefined
    164c:	06750000 	.inst	0x06750000 ; undefined
    1650:	00000236 	udf	#566
    1654:	0008a464 	.inst	0x0008a464 ; undefined
    1658:	ffff0000 	.inst	0xffff0000 ; undefined
    165c:	0000012c 	udf	#300
    1660:	00000000 	udf	#0
    1664:	04819c01 	lsr	z1.d, p7/m, z1.d, #64
    1668:	6d010000 	stp	d0, d0, [x0, #16]
    166c:	75007061 	.inst	0x75007061 ; undefined
    1670:	00005f18 	udf	#24344
    1674:	58910200 	ldr	x0, fffffffffff236b4 <FS_BASE+0xffffcff236b4>
    1678:	75007601 	.inst	0x75007601 ; undefined
    167c:	00005f26 	udf	#24358
    1680:	50910200 	adr	x0, fffffffffff236c2 <FS_BASE+0xffffcff236c2>
    1684:	00617001 	.inst	0x00617001 ; undefined
    1688:	005f3275 	.inst	0x005f3275 ; undefined
    168c:	91020000 	add	x0, x0, #0x80
    1690:	04940648 	sdiv	z8.s, p1/m, z8.s, z18.s
    1694:	3f750000 	.inst	0x3f750000 ; undefined
    1698:	0000005f 	udf	#95
    169c:	02409102 	.inst	0x02409102 ; undefined
    16a0:	0000053a 	udf	#1338
    16a4:	005f0e77 	.inst	0x005f0e77 ; undefined
    16a8:	91020000 	add	x0, x0, #0x80
    16ac:	74700478 	cbhs	w24, w16, 1738 <_binary_init_bin_size+0xff0>
    16b0:	0f780072 	fdot	v18.4h, v3.8b, v8.2b[3]
    16b4:	00000323 	udf	#803
    16b8:	02709102 	.inst	0x02709102 ; undefined
    16bc:	000007e8 	udf	#2024
    16c0:	00581283 	.inst	0x00581283 ; undefined
    16c4:	91020000 	add	x0, x0, #0x80
    16c8:	aa0f006c 	orr	x12, x3, x15
    16cc:	5c000004 	ldr	d4, 16cc <_binary_init_bin_size+0xf84>
    16d0:	00000323 	udf	#803
    16d4:	0008a358 	.inst	0x0008a358 ; undefined
    16d8:	ffff0000 	.inst	0xffff0000 ; undefined
    16dc:	0000010c 	udf	#268
    16e0:	00000000 	udf	#0
    16e4:	05029c01 	orr	z1.d, z1.d, #0xffffe00000003fff
    16e8:	6d010000 	stp	d0, d0, [x0, #16]
    16ec:	5c007061 	ldr	d1, 24f8 <_binary_init_bin_size+0x1db0>
    16f0:	00005f2a 	udf	#24362
    16f4:	58910200 	ldr	x0, fffffffffff23734 <FS_BASE+0xffffcff23734>
    16f8:	5c007601 	ldr	d1, 25b8 <_binary_init_bin_size+0x1e70>
    16fc:	00005f38 	udf	#24376
    1700:	50910200 	adr	x0, fffffffffff23742 <FS_BASE+0xffffcff23742>
    1704:	00047d06 	.inst	0x00047d06 ; undefined
    1708:	3c3f5c00 	.inst	0x3c3f5c00 ; undefined
    170c:	02000000 	.inst	0x02000000 ; undefined
    1710:	94064c91 	bl	194954 <TCR_T1SZ+0x94954>
    1714:	5c000004 	ldr	d4, 1714 <_binary_init_bin_size+0xfcc>
    1718:	00005f4f 	udf	#24399
    171c:	40910200 	.inst	0x40910200 ; undefined
    1720:	72747004 	.inst	0x72747004 ; undefined
    1724:	230f5e00 	.inst	0x230f5e00 ; undefined
    1728:	02000003 	.inst	0x02000003 ; undefined
    172c:	8d027091 	.inst	0x8d027091 ; undefined
    1730:	5f000009 	.inst	0x5f000009 ; undefined
    1734:	0001490b 	.inst	0x0001490b ; undefined
    1738:	78910200 	ldursh	x0, [x16, #-240]
    173c:	0007e802 	.inst	0x0007e802 ; undefined
    1740:	58126000 	ldr	x0, 26340 <MAIR_ATTR+0x21f40>
    1744:	02000000 	.inst	0x02000000 ; undefined
    1748:	0f006c91 	.inst	0x0f006c91 ; undefined
    174c:	0000057a 	udf	#1402
    1750:	00032348 	.inst	0x00032348 ; undefined
    1754:	08a27400 	.inst	0x08a27400 ; undefined
    1758:	ff000000 	.inst	0xff000000 ; undefined
    175c:	0000e4ff 	udf	#58623
    1760:	00000000 	udf	#0
    1764:	839c0100 	.inst	0x839c0100 ; undefined
    1768:	01000005 	.inst	0x01000005 ; undefined
    176c:	0070616d 	.inst	0x0070616d ; undefined
    1770:	005f2a48 	.inst	0x005f2a48 ; undefined
    1774:	91020000 	add	x0, x0, #0x80
    1778:	00760158 	.inst	0x00760158 ; undefined
    177c:	005f3848 	.inst	0x005f3848 ; undefined
    1780:	91020000 	add	x0, x0, #0x80
    1784:	047d0650 	sub	z16.h, z18.h, z29.h
    1788:	3f480000 	.inst	0x3f480000 ; undefined
    178c:	0000003c 	udf	#60
    1790:	064c9102 	.inst	0x064c9102 ; undefined
    1794:	00000494 	udf	#1172
    1798:	005f4f48 	.inst	0x005f4f48 ; undefined
    179c:	91020000 	add	x0, x0, #0x80
    17a0:	74700440 	cbhs	w0, w16, 1828 <_binary_init_bin_size+0x10e0>
    17a4:	0f4a0072 	fdot	v18.4h, v3.8b, v10.2b[0]
    17a8:	00000323 	udf	#803
    17ac:	02709102 	.inst	0x02709102 ; undefined
    17b0:	0000098d 	udf	#2445
    17b4:	01490b4b 	.inst	0x01490b4b ; undefined
    17b8:	91020000 	add	x0, x0, #0x80
    17bc:	07e80278 	.inst	0x07e80278 ; undefined
    17c0:	124c0000 	.inst	0x124c0000 ; undefined
    17c4:	00000058 	udf	#88
    17c8:	006c9102 	.inst	0x006c9102 ; undefined
    17cc:	00055107 	.inst	0x00055107 ; undefined
    17d0:	a1e83900 	umopa	za0.d, p6/m, p1/m, z8.h, z8.h
    17d4:	00000008 	udf	#8
    17d8:	008cffff 	.inst	0x008cffff ; undefined
    17dc:	00000000 	udf	#0
    17e0:	9c010000 	ldr	q0, 37e0 <_binary_init_bin_size+0x3098>
    17e4:	000005c6 	udf	#1478
    17e8:	3b007604 	.inst	0x3b007604 ; undefined
    17ec:	00008d12 	udf	#36114
    17f0:	78910200 	ldursh	x0, [x16, #-240]
    17f4:	00079c02 	.inst	0x00079c02 ; undefined
    17f8:	5f0e3c00 	.inst	0x5f0e3c00 ; undefined
    17fc:	02000000 	.inst	0x02000000 ; undefined
    1800:	69047091 	stgp	x17, x28, [x4, #128]
    1804:	5f0e3d00 	.inst	0x5f0e3d00 ; undefined
    1808:	02000000 	.inst	0x02000000 ; undefined
    180c:	0c006891 	st1	{v17.2s-v19.2s}, [x4]
    1810:	0000047c 	udf	#1148
    1814:	0149072a 	.inst	0x0149072a ; undefined
    1818:	a1380000 	st1b	{z0.b, z8.b}, pn8, [x0, x24]
    181c:	00000008 	udf	#8
    1820:	00b0ffff 	.inst	0x00b0ffff ; undefined
    1824:	00000000 	udf	#0
    1828:	9c010000 	ldr	q0, 3828 <_binary_init_bin_size+0x30e0>
    182c:	000005f6 	udf	#1526
    1830:	0004f202 	.inst	0x0004f202 ; undefined
    1834:	8d122c00 	.inst	0x8d122c00 ; undefined
    1838:	02000000 	.inst	0x02000000 ; undefined
    183c:	07007891 	.inst	0x07007891 ; undefined
    1840:	0000054b 	udf	#1355
    1844:	08a0881f 	.inst	0x08a0881f ; undefined
    1848:	ff000000 	.inst	0xff000000 ; undefined
    184c:	0000b0ff 	udf	#45311
    1850:	00000000 	udf	#0
    1854:	2d9c0100 	stp	s0, s0, [x8, #224]!
    1858:	01000006 	.inst	0x01000006 ; undefined
    185c:	151f0076 	b	47c1a34 <FS_SIZE+0x160ba34>
    1860:	0000005f 	udf	#95
    1864:	02689102 	.inst	0x02689102 ; undefined
    1868:	000004f2 	udf	#1266
    186c:	008d1225 	.inst	0x008d1225 ; undefined
    1870:	91020000 	add	x0, x0, #0x80
    1874:	9e1d0078 	.inst	0x9e1d0078 ; undefined
    1878:	01000004 	.inst	0x01000004 ; undefined
    187c:	a0100d16 	ld1b	{z22.b-z23.b}, pn11/z, [x8, x16]
    1880:	00000008 	udf	#8
    1884:	0078ffff 	.inst	0x0078ffff ; undefined
    1888:	00000000 	udf	#0
    188c:	9c010000 	ldr	q0, 388c <_binary_init_bin_size+0x3144>
    1890:	16007601 	b	fffffffff801f094 <FS_BASE+0xffffc801f094>
    1894:	00005f22 	udf	#24354
    1898:	68910200 	stgp	x0, x0, [x16], #544
    189c:	16006501 	b	fffffffff801aca0 <FS_BASE+0xffffc801aca0>
    18a0:	00005f2e 	udf	#24366
    18a4:	60910200 	.inst	0x60910200 ; undefined
    18a8:	08a0200a 	.inst	0x08a0200a ; undefined
    18ac:	ff000000 	.inst	0xff000000 ; undefined
    18b0:	000058ff 	udf	#22783
    18b4:	00000000 	udf	#0
    18b8:	05740200 	ext	z0.b, {z16.b-z17.b}, #160
    18bc:	13180000 	sbfiz	w0, w0, #8, #1
    18c0:	0000005f 	udf	#95
    18c4:	00789102 	.inst	0x00789102 ; undefined
    18c8:	07ba0000 	.inst	0x07ba0000 ; undefined
    18cc:	00050000 	.inst	0x00050000 ; undefined
    18d0:	091a0801 	.inst	0x091a0801 ; undefined
    18d4:	63110000 	.inst	0x63110000 ; undefined
    18d8:	0c000000 	st4	{v0.8b-v3.8b}, [x0]
    18dc:	0000012c 	udf	#300
    18e0:	00000000 	udf	#0
    18e4:	0008a9b8 	.inst	0x0008a9b8 ; undefined
    18e8:	ffff0000 	.inst	0xffff0000 ; undefined
    18ec:	0000073c 	udf	#1852
    18f0:	00000000 	udf	#0
    18f4:	00000b43 	udf	#2883
    18f8:	33060106 	bfi	w6, w8, #26, #1
    18fc:	06000001 	.inst	0x06000001 ; undefined
    1900:	01a30502 	.inst	0x01a30502 ; undefined
    1904:	04120000 	smulh	z0.b, p0/m, z0.b, z0.b
    1908:	746e6905 	.inst	0x746e6905 ; undefined
    190c:	05080600 	.inst	0x05080600 ; undefined
    1910:	0000013f 	udf	#319
    1914:	00064f0b 	.inst	0x00064f0b ; undefined
    1918:	55182e00 	.inst	0x55182e00 ; undefined
    191c:	06000000 	.inst	0x06000000 ; undefined
    1920:	01310801 	.inst	0x01310801 ; undefined
    1924:	f60b0000 	.inst	0xf60b0000 ; undefined
    1928:	31000006 	adds	w6, w0, #0x0
    192c:	00006719 	udf	#26393
    1930:	07020600 	.inst	0x07020600 ; undefined
    1934:	0000017c 	udf	#380
    1938:	0002910b 	.inst	0x0002910b ; undefined
    193c:	79193400 	strh	w0, [x0, #3226]
    1940:	06000000 	.inst	0x06000000 ; undefined
    1944:	01550704 	.inst	0x01550704 ; undefined
    1948:	0f0b0000 	fdot	v0.2s, v0.8b, v11.4b[0]
    194c:	37000001 	tbnz	w1, #0, 194c <_binary_init_bin_size+0x1204>
    1950:	00008b19 	udf	#35609
    1954:	07080600 	.inst	0x07080600 ; undefined
    1958:	00000150 	udf	#336
    195c:	42504213 	.inst	0x42504213 ; undefined
    1960:	06033e00 	.inst	0x06033e00 ; undefined
    1964:	00018f08 	.inst	0x00018f08 ; undefined
    1968:	061a0100 	.inst	0x061a0100 ; undefined
    196c:	0d070000 	.inst	0x0d070000 ; undefined
    1970:	0000018f 	udf	#399
    1974:	656f0c00 	fmla	z0.h, p3/m, z0.h, z15.h
    1978:	9f08006d 	.inst	0x9f08006d ; undefined
    197c:	03000001 	.inst	0x03000001 ; undefined
    1980:	0007cf01 	.inst	0x0007cf01 ; undefined
    1984:	5c0e0900 	ldr	d0, 1daa4 <MAIR_ATTR+0x196a4>
    1988:	0b000000 	add	w0, w0, w0
    198c:	00063201 	.inst	0x00063201 ; undefined
    1990:	4a0d0a00 	eor	w0, w16, w13, lsl #2
    1994:	0d000000 	st1	{v0.b}[0], [x0]
    1998:	00073f01 	.inst	0x00073f01 ; undefined
    199c:	5c0e0b00 	ldr	d0, 1dafc <MAIR_ATTR+0x196fc>
    19a0:	0e000000 	tbl	v0.8b, {v0.16b}, v0.8b
    19a4:	00062801 	.inst	0x00062801 ; undefined
    19a8:	4a0d0c00 	eor	w0, w0, w13, lsl #3
    19ac:	10000000 	adr	x0, 19ac <_binary_init_bin_size+0x1264>
    19b0:	00076701 	.inst	0x00076701 ; undefined
    19b4:	5c0e0d00 	ldr	d0, 1db54 <MAIR_ATTR+0x19754>
    19b8:	11000000 	add	w0, w0, #0x0
    19bc:	00074801 	.inst	0x00074801 ; undefined
    19c0:	5c0e0e00 	ldr	d0, 1db80 <MAIR_ATTR+0x19780>
    19c4:	13000000 	sbfx	w0, w0, #0, #1
    19c8:	00080c01 	.inst	0x00080c01 ; undefined
    19cc:	4a0d0f00 	eor	w0, w24, w13, lsl #3
    19d0:	15000000 	b	40019d0 <FS_SIZE+0xe4b9d0>
    19d4:	00067901 	.inst	0x00067901 ; undefined
    19d8:	5c0e1000 	ldr	d0, 1dbd8 <MAIR_ATTR+0x197d8>
    19dc:	16000000 	b	fffffffff80019dc <FS_BASE+0xffffc80019dc>
    19e0:	0006b301 	.inst	0x0006b301 ; undefined
    19e4:	5c0e1100 	ldr	d0, 1dc04 <MAIR_ATTR+0x19804>
    19e8:	18000000 	ldr	w0, 19e8 <_binary_init_bin_size+0x12a0>
    19ec:	0007c401 	.inst	0x0007c401 ; undefined
    19f0:	5c0e1200 	ldr	d0, 1dc30 <MAIR_ATTR+0x19830>
    19f4:	1a000000 	adc	w0, w0, w0
    19f8:	00065701 	.inst	0x00065701 ; undefined
    19fc:	6e0e1300 	ext	v0.16b, v24.16b, v14.16b, #2
    1a00:	1c000000 	ldr	s0, 1a00 <_binary_init_bin_size+0x12b8>
    1a04:	0005e601 	.inst	0x0005e601 ; undefined
    1a08:	6e0e1400 	mov	v0.h[3], v0.h[1]
    1a0c:	20000000 	.inst	0x20000000 ; undefined
    1a10:	0007ff01 	.inst	0x0007ff01 ; undefined
    1a14:	4a0d1500 	eor	w0, w8, w13, lsl #5
    1a18:	24000000 	cmphs	p0.b, p0/z, z0.b, z0.b
    1a1c:	0006ce01 	.inst	0x0006ce01 ; undefined
    1a20:	4a0d1600 	eor	w0, w16, w13, lsl #5
    1a24:	25000000 	cmpge	p0.b, p0/z, z0.b, #0
    1a28:	0007ad01 	.inst	0x0007ad01 ; undefined
    1a2c:	4a0d1700 	eor	w0, w24, w13, lsl #5
    1a30:	26000000 	.inst	0x26000000 ; undefined
    1a34:	00061001 	.inst	0x00061001 ; undefined
    1a38:	6e0e1800 	ext	v0.16b, v0.16b, v14.16b, #3
    1a3c:	27000000 	.inst	0x27000000 ; undefined
    1a40:	0007b701 	.inst	0x0007b701 ; undefined
    1a44:	af0d1900 	.inst	0xaf0d1900 ; undefined
    1a48:	2b000001 	adds	w1, w0, w0
    1a4c:	0005ab01 	.inst	0x0005ab01 ; undefined
    1a50:	9f0d1a00 	.inst	0x9f0d1a00 ; undefined
    1a54:	36000001 	tbz	w1, #0, 1a54 <_binary_init_bin_size+0x130c>
    1a58:	004a0900 	.inst	0x004a0900 ; undefined
    1a5c:	019f0000 	.inst	0x019f0000 ; undefined
    1a60:	8b0a0000 	add	x0, x0, x10
    1a64:	02000000 	.inst	0x02000000 ; undefined
    1a68:	004a0900 	.inst	0x004a0900 ; undefined
    1a6c:	01af0000 	.inst	0x01af0000 ; undefined
    1a70:	8b0a0000 	add	x0, x0, x10
    1a74:	07000000 	.inst	0x07000000 ; undefined
    1a78:	004a0900 	.inst	0x004a0900 ; undefined
    1a7c:	01bf0000 	.inst	0x01bf0000 ; undefined
    1a80:	8b0a0000 	add	x0, x0, x10
    1a84:	0a000000 	and	w0, w0, w0
    1a88:	069e1400 	.inst	0x069e1400 ; undefined
    1a8c:	03200000 	.inst	0x03200000 ; undefined
    1a90:	0268081d 	.inst	0x0268081d ; undefined
    1a94:	5e010000 	sha1c	q0, s0, v1.4s
    1a98:	1e000005 	.inst	0x1e000005 ; undefined
    1a9c:	00019f0d 	.inst	0x00019f0d ; undefined
    1aa0:	650c0000 	bfadd	z0.h, z0.h, z12.h
    1aa4:	1f007478 	fmadd	s24, s3, s0, s29
    1aa8:	0000018f 	udf	#399
    1aac:	05db0108 	mov	z8.d, p11/z, #8
    1ab0:	0d200000 	st2	{v0.b-v1.b}[0], [x0]
    1ab4:	0000004a 	udf	#74
    1ab8:	06d4010b 	.inst	0x06d4010b ; undefined
    1abc:	0d210000 	.inst	0x0d210000 ; undefined
    1ac0:	0000004a 	udf	#74
    1ac4:	0694010c 	.inst	0x0694010c ; undefined
    1ac8:	0d220000 	.inst	0x0d220000 ; undefined
    1acc:	0000004a 	udf	#74
    1ad0:	07a1010d 	.inst	0x07a1010d ; undefined
    1ad4:	0e230000 	saddl	v0.8h, v0.8b, v3.8b
    1ad8:	0000005c 	udf	#92
    1adc:	06a7010e 	.inst	0x06a7010e ; undefined
    1ae0:	0e240000 	saddl	v0.8h, v0.8b, v4.8b
    1ae4:	0000005c 	udf	#92
    1ae8:	078b0110 	.inst	0x078b0110 ; undefined
    1aec:	0e250000 	saddl	v0.8h, v0.8b, v5.8b
    1af0:	0000005c 	udf	#92
    1af4:	06050112 	.inst	0x06050112 ; undefined
    1af8:	0e260000 	saddl	v0.8h, v0.8b, v6.8b
    1afc:	0000005c 	udf	#92
    1b00:	066b0114 	.inst	0x066b0114 ; undefined
    1b04:	0e270000 	saddl	v0.8h, v0.8b, v7.8b
    1b08:	0000005c 	udf	#92
    1b0c:	07f80116 	.inst	0x07f80116 ; undefined
    1b10:	0e280000 	saddl	v0.8h, v0.8b, v8.8b
    1b14:	0000005c 	udf	#92
    1b18:	07e00118 	.inst	0x07e00118 ; undefined
    1b1c:	0e290000 	saddl	v0.8h, v0.8b, v9.8b
    1b20:	0000005c 	udf	#92
    1b24:	0717011a 	.inst	0x0717011a ; undefined
    1b28:	0e2a0000 	saddl	v0.8h, v0.8b, v10.8b
    1b2c:	0000006e 	udf	#110
    1b30:	960d001c 	bl	fffffffff8341ba0 <FS_BASE+0xffffc8341ba0>
    1b34:	04000001 	add	z1.b, p0/m, z1.b, z0.b
    1b38:	00003c06 	udf	#15366
    1b3c:	00027e00 	.inst	0x00027e00 ; undefined
    1b40:	027e0700 	.inst	0x027e0700 ; undefined
    1b44:	00150000 	.inst	0x00150000 ; undefined
    1b48:	00028a08 	.inst	0x00028a08 ; undefined
    1b4c:	08010600 	stxrb	w1, w0, [x16]
    1b50:	0000013a 	udf	#314
    1b54:	00028316 	.inst	0x00028316 ; undefined
    1b58:	04830e00 	subr	z0.s, p3/m, z0.s, z16.s
    1b5c:	15050000 	b	4141b5c <FS_SIZE+0xf8bb5c>
    1b60:	000002aa 	udf	#682
    1b64:	0002aa07 	.inst	0x0002aa07 ; undefined
    1b68:	02aa0700 	.inst	0x02aa0700 ; undefined
    1b6c:	79070000 	strh	w0, [x0, #896]
    1b70:	00000000 	udf	#0
    1b74:	720d0817 	ands	w23, w0, #0x380000
    1b78:	05000006 	orr	z6.s, z6.s, #0x1
    1b7c:	00003c17 	udf	#15383
    1b80:	0002cb00 	.inst	0x0002cb00 ; undefined
    1b84:	02aa0700 	.inst	0x02aa0700 ; undefined
    1b88:	aa070000 	orr	x0, x0, x7
    1b8c:	07000002 	.inst	0x07000002 ; undefined
    1b90:	00000079 	udf	#121
    1b94:	036a0e00 	.inst	0x036a0e00 ; undefined
    1b98:	0b060000 	add	w0, w0, w6
    1b9c:	000002e1 	udf	#737
    1ba0:	0002e107 	.inst	0x0002e107 ; undefined
    1ba4:	00800700 	.inst	0x00800700 ; undefined
    1ba8:	08000000 	stxrb	w0, w0, [x0]
    1bac:	00000283 	udf	#643
    1bb0:	00014818 	.inst	0x00014818 ; undefined
    1bb4:	06d20100 	.inst	0x06d20100 ; undefined
    1bb8:	0008b094 	.inst	0x0008b094 ; undefined
    1bbc:	ffff0000 	.inst	0xffff0000 ; undefined
    1bc0:	00000060 	udf	#96
    1bc4:	00000000 	udf	#0
    1bc8:	03119c01 	.inst	0x03119c01 ; undefined
    1bcc:	70040000 	adr	x0, 9bcf <MAIR_ATTR+0x57cf>
    1bd0:	110ed400 	add	w0, w0, #0x3b5
    1bd4:	02000003 	.inst	0x02000003 ; undefined
    1bd8:	08007891 	stxrb	w0, w17, [x4]
    1bdc:	0000004a 	udf	#74
    1be0:	0004ff19 	.inst	0x0004ff19 ; undefined
    1be4:	05ba0100 	zip1	z0.q, z8.q, z26.q
    1be8:	0000003c 	udf	#60
    1bec:	0008aff8 	.inst	0x0008aff8 ; undefined
    1bf0:	ffff0000 	.inst	0xffff0000 ; undefined
    1bf4:	0000009c 	udf	#156
    1bf8:	00000000 	udf	#0
    1bfc:	039b9c01 	.inst	0x039b9c01 ; undefined
    1c00:	27030000 	.inst	0x27030000 ; undefined
    1c04:	ba000007 	adcs	x7, x0, x0
    1c08:	0002e115 	.inst	0x0002e115 ; undefined
    1c0c:	58910200 	ldr	x0, fffffffffff23c4c <FS_BASE+0xffffcff23c4c>
    1c10:	00098d03 	.inst	0x00098d03 ; undefined
    1c14:	8024ba00 	.inst	0x8024ba00 ; undefined
    1c18:	02000000 	.inst	0x02000000 ; undefined
    1c1c:	e8025091 	sttnp	x17, x20, [x4, #32]
    1c20:	bc000007 	stur	s7, [x0]
    1c24:	00006e0e 	udf	#28174
    1c28:	78910200 	ldursh	x0, [x16, #-240]
    1c2c:	00071702 	.inst	0x00071702 ; undefined
    1c30:	6e0ebd00 	.inst	0x6e0ebd00 ; undefined
    1c34:	02000000 	.inst	0x02000000 ; undefined
    1c38:	e0026c91 	.inst	0xe0026c91 ; undefined
    1c3c:	be000007 	.inst	0xbe000007 ; undefined
    1c40:	00006e0e 	udf	#28174
    1c44:	68910200 	stgp	x0, x0, [x16], #544
    1c48:	0007ee02 	.inst	0x0007ee02 ; undefined
    1c4c:	9b16bf00 	msub	x0, x24, x22, x15
    1c50:	02000003 	.inst	0x02000003 ; undefined
    1c54:	72047091 	ands	w17, w4, #0xf1ffffff
    1c58:	c0007465 	mov	za0h.b[w15, 5], p5/m, z3.b
    1c5c:	00003c09 	udf	#15369
    1c60:	7c910200 	.inst	0x7c910200 ; undefined
    1c64:	01bf0800 	.inst	0x01bf0800 ; undefined
    1c68:	0d050000 	.inst	0x0d050000 ; undefined
    1c6c:	b5000007 	cbnz	x7, 1c6c <_binary_init_bin_size+0x1524>
    1c70:	00006e11 	udf	#28177
    1c74:	08afcc00 	.inst	0x08afcc00 ; undefined
    1c78:	ff000000 	.inst	0xff000000 ; undefined
    1c7c:	00002cff 	udf	#11519
    1c80:	00000000 	udf	#0
    1c84:	ec9c0100 	sttp	q0, q0, [x8], #896
    1c88:	03000003 	.inst	0x03000003 ; undefined
    1c8c:	000007e0 	udf	#2016
    1c90:	006e24b5 	.inst	0x006e24b5 ; undefined
    1c94:	91020000 	add	x0, x0, #0x80
    1c98:	02af037c 	.inst	0x02af037c ; undefined
    1c9c:	39b50000 	ldrsb	x0, [x0, #3392]
    1ca0:	000002aa 	udf	#682
    1ca4:	03709102 	.inst	0x03709102 ; undefined
    1ca8:	0000079c 	udf	#1948
    1cac:	006e4ab5 	.inst	0x006e4ab5 ; undefined
    1cb0:	91020000 	add	x0, x0, #0x80
    1cb4:	ff050078 	.inst	0xff050078 ; undefined
    1cb8:	92000006 	and	x6, x0, #0x100000001
    1cbc:	00006e11 	udf	#28177
    1cc0:	08aedc00 	.inst	0x08aedc00 ; undefined
    1cc4:	ff000000 	.inst	0xff000000 ; undefined
    1cc8:	0000f0ff 	udf	#61695
    1ccc:	00000000 	udf	#0
    1cd0:	7e9c0100 	.inst	0x7e9c0100 ; undefined
    1cd4:	03000004 	.inst	0x03000004 ; undefined
    1cd8:	000007e0 	udf	#2016
    1cdc:	006e2892 	.inst	0x006e2892 ; undefined
    1ce0:	91020000 	add	x0, x0, #0x80
    1ce4:	02af035c 	.inst	0x02af035c ; undefined
    1ce8:	3d920000 	str	q0, [x0, #18432]
    1cec:	000002e1 	udf	#737
    1cf0:	03509102 	.inst	0x03509102 ; undefined
    1cf4:	0000079c 	udf	#1948
    1cf8:	006e4e92 	.inst	0x006e4e92 ; undefined
    1cfc:	91020000 	add	x0, x0, #0x80
    1d00:	70620458 	adr	x24, c5d8b <MAIR_ATTR+0xc198b>
    1d04:	11940062 	.inst	0x11940062 ; undefined
    1d08:	0000047e 	udf	#1150
    1d0c:	02709102 	.inst	0x02709102 ; undefined
    1d10:	00000708 	udf	#1800
    1d14:	02e10b95 	.inst	0x02e10b95 ; undefined
    1d18:	91020000 	add	x0, x0, #0x80
    1d1c:	07970260 	.inst	0x07970260 ; undefined
    1d20:	0e960000 	.inst	0x0e960000 ; undefined
    1d24:	0000006e 	udf	#110
    1d28:	027c9102 	.inst	0x027c9102 ; undefined
    1d2c:	000005bb 	udf	#1467
    1d30:	006e0e97 	.inst	0x006e0e97 ; undefined
    1d34:	91020000 	add	x0, x0, #0x80
    1d38:	07e8026c 	.inst	0x07e8026c ; undefined
    1d3c:	0e980000 	.inst	0x0e980000 ; undefined
    1d40:	0000006e 	udf	#110
    1d44:	00789102 	.inst	0x00789102 ; undefined
    1d48:	00009208 	udf	#37384
    1d4c:	05f90500 	.inst	0x05f90500 ; undefined
    1d50:	11740000 	add	w0, w0, #0xd00, lsl #12
    1d54:	0000006e 	udf	#110
    1d58:	0008adac 	.inst	0x0008adac ; undefined
    1d5c:	ffff0000 	.inst	0xffff0000 ; undefined
    1d60:	00000130 	udf	#304
    1d64:	00000000 	udf	#0
    1d68:	05179c01 	.inst	0x05179c01 ; undefined
    1d6c:	27030000 	.inst	0x27030000 ; undefined
    1d70:	74000007 	cbgt	w7, w0, 1d70 <_binary_init_bin_size+0x1628>
    1d74:	0002e123 	.inst	0x0002e123 ; undefined
    1d78:	48910200 	stllrh	w0, [x16]
    1d7c:	00055e02 	.inst	0x00055e02 ; undefined
    1d80:	170a7600 	b	fffffffffc29f580 <FS_BASE+0xffffcc29f580>
    1d84:	02000005 	.inst	0x02000005 ; undefined
    1d88:	65046091 	.inst	0x65046091 ; undefined
    1d8c:	77007478 	.inst	0x77007478 ; undefined
    1d90:	0005270a 	.inst	0x0005270a ; undefined
    1d94:	58910200 	ldr	x0, fffffffffff23dd4 <FS_BASE+0xffffcff23dd4>
    1d98:	00076702 	.inst	0x00076702 ; undefined
    1d9c:	6e0e7800 	ext	v0.16b, v0.16b, v14.16b, #15
    1da0:	02000000 	.inst	0x02000000 ; undefined
    1da4:	ee027491 	.inst	0xee027491 ; undefined
    1da8:	79000007 	strh	w7, [x0]
    1dac:	00039b16 	.inst	0x00039b16 ; undefined
    1db0:	68910200 	stgp	x0, x0, [x16], #544
    1db4:	00038b02 	.inst	0x00038b02 ; undefined
    1db8:	370a7b00 	tbnz	w0, #1, 6d18 <MAIR_ATTR+0x2918>
    1dbc:	02000005 	.inst	0x02000005 ; undefined
    1dc0:	180f7b91 	ldr	w17, 20d30 <MAIR_ATTR+0x1c930>
    1dc4:	000008ae 	udf	#2222
    1dc8:	b8ffff00 	.inst	0xb8ffff00 ; undefined
    1dcc:	00000000 	udf	#0
    1dd0:	04000000 	add	z0.b, p0/m, z0.b, z0.b
    1dd4:	17810069 	b	fffffffffe041f78 <FS_BASE+0xffffce041f78>
    1dd8:	0000006e 	udf	#110
    1ddc:	007c9102 	.inst	0x007c9102 ; undefined
    1de0:	02830900 	.inst	0x02830900 ; undefined
    1de4:	05270000 	ext	z0.b, z0.b, z0.b, #56
    1de8:	8b0a0000 	add	x0, x0, x10
    1dec:	07000000 	.inst	0x07000000 ; undefined
    1df0:	02830900 	.inst	0x02830900 ; undefined
    1df4:	05370000 	ext	z0.b, z0.b, z0.b, #184
    1df8:	8b0a0000 	add	x0, x0, x10
    1dfc:	02000000 	.inst	0x02000000 ; undefined
    1e00:	02010600 	.inst	0x02010600 ; undefined
    1e04:	00000200 	udf	#512
    1e08:	0007211a 	.inst	0x0007211a ; undefined
    1e0c:	0d550100 	.inst	0x0d550100 ; undefined
    1e10:	00000537 	udf	#1335
    1e14:	0008ac38 	.inst	0x0008ac38 ; undefined
    1e18:	ffff0000 	.inst	0xffff0000 ; undefined
    1e1c:	00000174 	udf	#372
    1e20:	00000000 	udf	#0
    1e24:	05b59c01 	.inst	0x05b59c01 ; undefined
    1e28:	27030000 	.inst	0x27030000 ; undefined
    1e2c:	55000007 	.inst	0x55000007 ; undefined
    1e30:	0002e11e 	.inst	0x0002e11e ; undefined
    1e34:	68910200 	stgp	x0, x0, [x16], #544
    1e38:	00055e03 	.inst	0x00055e03 ; undefined
    1e3c:	e12a5500 	.inst	0xe12a5500 ; undefined
    1e40:	02000002 	.inst	0x02000002 ; undefined
    1e44:	65106091 	.inst	0x65106091 ; undefined
    1e48:	55007478 	.inst	0x55007478 ; undefined
    1e4c:	0002e136 	.inst	0x0002e136 ; undefined
    1e50:	58910200 	ldr	x0, fffffffffff23e90 <FS_BASE+0xffffcff23e90>
    1e54:	57006904 	.inst	0x57006904 ; undefined
    1e58:	00003c09 	udf	#15369
    1e5c:	7c910200 	.inst	0x7c910200 ; undefined
    1e60:	08acfc0f 	caslb	w12, w15, [x0]
    1e64:	ff000000 	.inst	0xff000000 ; undefined
    1e68:	000084ff 	udf	#34047
    1e6c:	00000000 	udf	#0
    1e70:	006a0400 	.inst	0x006a0400 ; undefined
    1e74:	003c1264 	.inst	0x003c1264 ; undefined
    1e78:	91020000 	add	x0, x0, #0x80
    1e7c:	05000078 	orr	z24.s, z24.s, #0xf
    1e80:	0000072c 	udf	#1836
    1e84:	05370d49 	ext	z9.b, z9.b, z10.b, #187
    1e88:	abd80000 	.inst	0xabd80000 ; undefined
    1e8c:	00000008 	udf	#8
    1e90:	0060ffff 	.inst	0x0060ffff ; undefined
    1e94:	00000000 	udf	#0
    1e98:	9c010000 	ldr	q0, 3e98 <_binary_init_bin_size+0x3750>
    1e9c:	0000060f 	udf	#1551
    1ea0:	0007ee03 	.inst	0x0007ee03 ; undefined
    1ea4:	9b314900 	smaddl	x0, w8, w17, x18
    1ea8:	02000003 	.inst	0x02000003 ; undefined
    1eac:	5e036891 	.inst	0x5e036891 ; undefined
    1eb0:	49000005 	.inst	0x49000005 ; undefined
    1eb4:	0002e142 	.inst	0x0002e142 ; undefined
    1eb8:	60910200 	.inst	0x60910200 ; undefined
    1ebc:	74786510 	.inst	0x74786510 ; undefined
    1ec0:	e14e4900 	.inst	0xe14e4900 ; undefined
    1ec4:	02000002 	.inst	0x02000002 ; undefined
    1ec8:	8b025891 	add	x17, x4, x2, lsl #22
    1ecc:	4b000003 	sub	w3, w0, w0
    1ed0:	0005370a 	.inst	0x0005370a ; undefined
    1ed4:	7f910200 	.inst	0x7f910200 ; undefined
    1ed8:	07780500 	.inst	0x07780500 ; undefined
    1edc:	193e0000 	.inst	0x193e0000 ; undefined
    1ee0:	0000039b 	udf	#923
    1ee4:	0008ab7c 	.inst	0x0008ab7c ; undefined
    1ee8:	ffff0000 	.inst	0xffff0000 ; undefined
    1eec:	0000005c 	udf	#92
    1ef0:	00000000 	udf	#0
    1ef4:	064b9c01 	.inst	0x064b9c01 ; undefined
    1ef8:	70040000 	adr	x0, 9efb <MAIR_ATTR+0x5afb>
    1efc:	7e114000 	.inst	0x7e114000 ; undefined
    1f00:	02000004 	.inst	0x02000004 ; undefined
    1f04:	d4027891 	.inst	0xd4027891 ; undefined
    1f08:	41000005 	.inst	0x41000005 ; undefined
    1f0c:	00006e0e 	udf	#28174
    1f10:	74910200 	.inst	0x74910200 ; undefined
    1f14:	06dd0500 	.inst	0x06dd0500 ; undefined
    1f18:	11370000 	add	w0, w0, #0xdc0
    1f1c:	0000006e 	udf	#110
    1f20:	0008ab5c 	.inst	0x0008ab5c ; undefined
    1f24:	ffff0000 	.inst	0xffff0000 ; undefined
    1f28:	00000020 	udf	#32
    1f2c:	00000000 	udf	#0
    1f30:	067b9c01 	.inst	0x067b9c01 ; undefined
    1f34:	62040000 	.inst	0x62040000 ; undefined
    1f38:	39006270 	strb	w16, [x19, #24]
    1f3c:	00047e11 	.inst	0x00047e11 ; undefined
    1f40:	78910200 	ldursh	x0, [x16, #-240]
    1f44:	05b70500 	zip2	z0.q, z8.q, z23.q
    1f48:	11300000 	add	w0, w0, #0xc00
    1f4c:	0000006e 	udf	#110
    1f50:	0008ab2c 	.inst	0x0008ab2c ; undefined
    1f54:	ffff0000 	.inst	0xffff0000 ; undefined
    1f58:	00000030 	udf	#48
    1f5c:	00000000 	udf	#0
    1f60:	06ab9c01 	.inst	0x06ab9c01 ; undefined
    1f64:	62040000 	.inst	0x62040000 ; undefined
    1f68:	32006270 	orr	w16, w19, #0x1ffffff
    1f6c:	00047e11 	.inst	0x00047e11 ; undefined
    1f70:	78910200 	ldursh	x0, [x16, #-240]
    1f74:	05c80500 	.inst	0x05c80500 ; undefined
    1f78:	111e0000 	add	w0, w0, #0x780
    1f7c:	0000006e 	udf	#110
    1f80:	0008aa64 	.inst	0x0008aa64 ; undefined
    1f84:	ffff0000 	.inst	0xffff0000 ; undefined
    1f88:	000000c8 	udf	#200
    1f8c:	00000000 	udf	#0
    1f90:	07119c01 	.inst	0x07119c01 ; undefined
    1f94:	e8030000 	sttnp	x0, x0, [x0, #48]
    1f98:	1e000007 	.inst	0x1e000007 ; undefined
    1f9c:	00006e2d 	udf	#28205
    1fa0:	5c910200 	ldr	d0, fffffffffff23fe0 <FS_BASE+0xffffcff23fe0>
    1fa4:	00064602 	.inst	0x00064602 ; undefined
    1fa8:	6e0e2000 	ext	v0.16b, v0.16b, v14.16b, #4
    1fac:	02000000 	.inst	0x02000000 ; undefined
    1fb0:	c5027491 	ldff1w	{z17.d}, p5/z, [x4, z2.d, uxtw]
    1fb4:	21000006 	.inst	0x21000006 ; undefined
    1fb8:	00006e0e 	udf	#28174
    1fbc:	70910200 	adr	x0, fffffffffff23fff <FS_BASE+0xffffcff23fff>
    1fc0:	00061f02 	.inst	0x00061f02 ; undefined
    1fc4:	6e0e2200 	ext	v0.16b, v16.16b, v14.16b, #4
    1fc8:	02000000 	.inst	0x02000000 ; undefined
    1fcc:	70046c91 	adr	x17, ad5f <MAIR_ATTR+0x695f>
    1fd0:	7e112600 	.inst	0x7e112600 ; undefined
    1fd4:	02000004 	.inst	0x02000004 ; undefined
    1fd8:	05007891 	orr	z17.s, z17.s, #0x3e0000
    1fdc:	00000755 	udf	#1877
    1fe0:	005c1117 	.inst	0x005c1117 ; undefined
    1fe4:	aa300000 	orn	x0, x0, x16
    1fe8:	00000008 	udf	#8
    1fec:	0034ffff 	.inst	0x0034ffff ; undefined
    1ff0:	00000000 	udf	#0
    1ff4:	9c010000 	ldr	q0, 3ff4 <_binary_init_bin_size+0x38ac>
    1ff8:	0000074f 	udf	#1871
    1ffc:	0007e003 	.inst	0x0007e003 ; undefined
    2000:	6e2c1700 	urhadd	v0.16b, v24.16b, v12.16b
    2004:	02000000 	.inst	0x02000000 ; undefined
    2008:	a1026c91 	ld1d	{z17.d, z25.d}, pn11/z, [x4, x2, lsl #3]
    200c:	19000005 	stlurb	w5, [x0]
    2010:	00074f0f 	.inst	0x00074f0f ; undefined
    2014:	78910200 	ldursh	x0, [x16, #-240]
    2018:	005c0800 	.inst	0x005c0800 ; undefined
    201c:	9d050000 	.inst	0x9d050000 ; undefined
    2020:	0f000005 	fdot	v5.2s, v0.8b, v0.4b[0]
    2024:	00074f12 	.inst	0x00074f12 ; undefined
    2028:	08a9f000 	.inst	0x08a9f000 ; undefined
    202c:	ff000000 	.inst	0xff000000 ; undefined
    2030:	000040ff 	udf	#16639
    2034:	00000000 	udf	#0
    2038:	909c0100 	adrp	x0, ffffffff38022000 <FS_BASE+0xffff08022000>
    203c:	04000007 	add	z7.b, p0/m, z7.b, z0.b
    2040:	11110070 	add	w16, w3, #0x440
    2044:	0000047e 	udf	#1150
    2048:	02789102 	.inst	0x02789102 ; undefined
    204c:	000005d4 	udf	#1492
    2050:	006e0e12 	.inst	0x006e0e12 ; undefined
    2054:	91020000 	add	x0, x0, #0x80
    2058:	891b0074 	.inst	0x891b0074 ; undefined
    205c:	01000006 	.inst	0x01000006 ; undefined
    2060:	047e1408 	uqadd	z8.h, z0.h, z30.h
    2064:	a9b80000 	stp	x0, x0, [x0, #-128]!
    2068:	00000008 	udf	#8
    206c:	0038ffff 	.inst	0x0038ffff ; undefined
    2070:	00000000 	udf	#0
    2074:	9c010000 	ldr	q0, 4074 <_binary_init_bin_size+0x392c>
    2078:	61626c04 	.inst	0x61626c04 ; undefined
    207c:	6e0e0a00 	ext	v0.16b, v16.16b, v14.16b, #1
    2080:	02000000 	.inst	0x02000000 ; undefined
    2084:	00007c91 	udf	#31889
    2088:	00000b9d 	udf	#2973
    208c:	08010005 	stxrb	w1, w5, [x0]
    2090:	00000ad8 	udf	#2776
    2094:	0000631a 	udf	#25370
    2098:	01330c00 	.inst	0x01330c00 ; undefined
    209c:	00000000 	udf	#0
    20a0:	b0f40000 	adrp	x0, ffffffffe8003000 <FS_BASE+0xffffb8003000>
    20a4:	00000008 	udf	#8
    20a8:	0da0ffff 	.inst	0x0da0ffff ; undefined
    20ac:	00000000 	udf	#0
    20b0:	0e520000 	.inst	0x0e520000 ; undefined
    20b4:	01070000 	.inst	0x01070000 ; undefined
    20b8:	00013306 	.inst	0x00013306 ; undefined
    20bc:	05020700 	orr	z0.d, z0.d, #0x1ffffffffffffff
    20c0:	000001a3 	udf	#419
    20c4:	6905041b 	stgp	x27, x1, [x0, #160]
    20c8:	1000746e 	adr	x14, 2f54 <_binary_init_bin_size+0x280c>
    20cc:	00000110 	udf	#272
    20d0:	004e182b 	.inst	0x004e182b ; undefined
    20d4:	08070000 	stxrb	w7, w0, [x0]
    20d8:	00013f05 	.inst	0x00013f05 ; undefined
    20dc:	08010700 	stxrb	w1, w0, [x24]
    20e0:	00000131 	udf	#305
    20e4:	7c070207 	stur	h7, [x16, #112]
    20e8:	07000001 	.inst	0x07000001 ; undefined
    20ec:	01550704 	.inst	0x01550704 ; undefined
    20f0:	0f100000 	fdot	v0.2s, v0.8b, v16.4b[0]
    20f4:	37000001 	tbnz	w1, #0, 20f4 <_binary_init_bin_size+0x19ac>
    20f8:	00007519 	udf	#29977
    20fc:	07080700 	.inst	0x07080700 ; undefined
    2100:	00000150 	udf	#336
    2104:	00092d0a 	.inst	0x00092d0a ; undefined
    2108:	05036000 	orr	z0.d, z0.d, #0x100000
    210c:	00000123 	udf	#291
    2110:	39317801 	strb	w1, [x0, #3166]
    2114:	0d070300 	.inst	0x0d070300 ; undefined
    2118:	00000043 	udf	#67
    211c:	32780100 	.inst	0x32780100 ; undefined
    2120:	08030030 	stxrb	w3, w16, [x1]
    2124:	0000430d 	udf	#17165
    2128:	78010800 	sttrh	w0, [x0, #16]
    212c:	03003132 	.inst	0x03003132 ; undefined
    2130:	00430d09 	.inst	0x00430d09 ; undefined
    2134:	01100000 	.inst	0x01100000 ; undefined
    2138:	00323278 	.inst	0x00323278 ; undefined
    213c:	430d0a03 	.inst	0x430d0a03 ; undefined
    2140:	18000000 	ldr	w0, 2140 <_binary_init_bin_size+0x19f8>
    2144:	33327801 	.inst	0x33327801 ; undefined
    2148:	0d0b0300 	.inst	0x0d0b0300 ; undefined
    214c:	00000043 	udf	#67
    2150:	32780120 	.inst	0x32780120 ; undefined
    2154:	0c030034 	.inst	0x0c030034 ; undefined
    2158:	0000430d 	udf	#17165
    215c:	78012800 	sttrh	w0, [x0, #18]
    2160:	03003532 	.inst	0x03003532 ; undefined
    2164:	00430d0d 	.inst	0x00430d0d ; undefined
    2168:	01300000 	.inst	0x01300000 ; undefined
    216c:	00363278 	.inst	0x00363278 ; undefined
    2170:	430d0e03 	.inst	0x430d0e03 ; undefined
    2174:	38000000 	sturb	w0, [x0]
    2178:	37327801 	tbnz	w1, #6, 7078 <MAIR_ATTR+0x2c78>
    217c:	0d0f0300 	.inst	0x0d0f0300 ; undefined
    2180:	00000043 	udf	#67
    2184:	32780140 	.inst	0x32780140 ; undefined
    2188:	10030038 	adr	x24, 818c <MAIR_ATTR+0x3d8c>
    218c:	0000430d 	udf	#17165
    2190:	66014800 	.inst	0x66014800 ; undefined
    2194:	11030070 	add	w16, w3, #0xc0
    2198:	0000430d 	udf	#17165
    219c:	6c015000 	stnp	d0, d20, [x0, #16]
    21a0:	12030072 	and	w18, w3, #0x20000000
    21a4:	0000430d 	udf	#17165
    21a8:	1c005800 	ldr	s0, 2ca8 <_binary_init_bin_size+0x2560>
    21ac:	000001b3 	udf	#435
    21b0:	14030120 	b	c2630 <MAIR_ATTR+0xbe230>
    21b4:	0002f808 	.inst	0x0002f808 ; undefined
    21b8:	30780100 	adr	x0, f21d9 <MAIR_ATTR+0xeddd9>
    21bc:	0d150300 	.inst	0x0d150300 ; undefined
    21c0:	00000043 	udf	#67
    21c4:	31780100 	adds	w0, w8, #0xe00, lsl #12
    21c8:	0d160300 	.inst	0x0d160300 ; undefined
    21cc:	00000043 	udf	#67
    21d0:	32780108 	.inst	0x32780108 ; undefined
    21d4:	0d170300 	.inst	0x0d170300 ; undefined
    21d8:	00000043 	udf	#67
    21dc:	33780110 	.inst	0x33780110 ; undefined
    21e0:	0d180300 	.inst	0x0d180300 ; undefined
    21e4:	00000043 	udf	#67
    21e8:	34780118 	cbz	w24, f2208 <MAIR_ATTR+0xede08>
    21ec:	0d190300 	.inst	0x0d190300 ; undefined
    21f0:	00000043 	udf	#67
    21f4:	35780120 	cbnz	w0, f2218 <MAIR_ATTR+0xede18>
    21f8:	0d1a0300 	.inst	0x0d1a0300 ; undefined
    21fc:	00000043 	udf	#67
    2200:	36780128 	tbz	w8, #15, 2224 <_binary_init_bin_size+0x1adc>
    2204:	0d1b0300 	.inst	0x0d1b0300 ; undefined
    2208:	00000043 	udf	#67
    220c:	37780130 	tbnz	w16, #15, 2230 <_binary_init_bin_size+0x1ae8>
    2210:	0d1c0300 	.inst	0x0d1c0300 ; undefined
    2214:	00000043 	udf	#67
    2218:	38780138 	ldaddlb	w24, w24, [x9]
    221c:	0d1d0300 	.inst	0x0d1d0300 ; undefined
    2220:	00000043 	udf	#67
    2224:	39780140 	ldrb	w0, [x10, #3584]
    2228:	0d1e0300 	.inst	0x0d1e0300 ; undefined
    222c:	00000043 	udf	#67
    2230:	31780148 	adds	w8, w10, #0xe00, lsl #12
    2234:	1f030030 	fmadd	s16, s1, s3, s0
    2238:	0000430d 	udf	#17165
    223c:	78015000 	sturh	w0, [x0, #21]
    2240:	03003131 	.inst	0x03003131 ; undefined
    2244:	00430d20 	.inst	0x00430d20 ; undefined
    2248:	01580000 	.inst	0x01580000 ; undefined
    224c:	00323178 	.inst	0x00323178 ; undefined
    2250:	430d2103 	.inst	0x430d2103 ; undefined
    2254:	60000000 	.inst	0x60000000 ; undefined
    2258:	33317801 	.inst	0x33317801 ; undefined
    225c:	0d220300 	.inst	0x0d220300 ; undefined
    2260:	00000043 	udf	#67
    2264:	31780168 	adds	w8, w11, #0xe00, lsl #12
    2268:	23030034 	.inst	0x23030034 ; undefined
    226c:	0000430d 	udf	#17165
    2270:	78017000 	sturh	w0, [x0, #23]
    2274:	03003531 	.inst	0x03003531 ; undefined
    2278:	00430d24 	.inst	0x00430d24 ; undefined
    227c:	01780000 	.inst	0x01780000 ; undefined
    2280:	00363178 	.inst	0x00363178 ; undefined
    2284:	430d2503 	.inst	0x430d2503 ; undefined
    2288:	80000000 	fmop4a	za0.s, z0.s, z16.s
    228c:	37317801 	tbnz	w1, #6, 518c <MAIR_ATTR+0xd8c>
    2290:	0d260300 	.inst	0x0d260300 ; undefined
    2294:	00000043 	udf	#67
    2298:	31780188 	adds	w8, w12, #0xe00, lsl #12
    229c:	27030038 	.inst	0x27030038 ; undefined
    22a0:	0000430d 	udf	#17165
    22a4:	78019000 	sturh	w0, [x0, #25]
    22a8:	03003931 	.inst	0x03003931 ; undefined
    22ac:	00430d28 	.inst	0x00430d28 ; undefined
    22b0:	01980000 	.inst	0x01980000 ; undefined
    22b4:	00303278 	.inst	0x00303278 ; undefined
    22b8:	430d2903 	.inst	0x430d2903 ; undefined
    22bc:	a0000000 	ld1b	{z0.b-z1.b}, pn8/z, [x0, x0]
    22c0:	31327801 	adds	w1, w0, #0xc9e
    22c4:	0d2a0300 	.inst	0x0d2a0300 ; undefined
    22c8:	00000043 	udf	#67
    22cc:	327801a8 	.inst	0x327801a8 ; undefined
    22d0:	2b030032 	adds	w18, w1, w3
    22d4:	0000430d 	udf	#17165
    22d8:	7801b000 	sturh	w0, [x0, #27]
    22dc:	03003332 	.inst	0x03003332 ; undefined
    22e0:	00430d2c 	.inst	0x00430d2c ; undefined
    22e4:	01b80000 	.inst	0x01b80000 ; undefined
    22e8:	00343278 	.inst	0x00343278 ; undefined
    22ec:	430d2d03 	.inst	0x430d2d03 ; undefined
    22f0:	c0000000 	mov	za0h.b[w12, 0], p0/m, z0.b
    22f4:	35327801 	cbnz	w1, 671f4 <MAIR_ATTR+0x62df4>
    22f8:	0d2e0300 	.inst	0x0d2e0300 ; undefined
    22fc:	00000043 	udf	#67
    2300:	327801c8 	.inst	0x327801c8 ; undefined
    2304:	2f030036 	.inst	0x2f030036 ; undefined
    2308:	0000430d 	udf	#17165
    230c:	7801d000 	sturh	w0, [x0, #29]
    2310:	03003732 	.inst	0x03003732 ; undefined
    2314:	00430d30 	.inst	0x00430d30 ; undefined
    2318:	01d80000 	.inst	0x01d80000 ; undefined
    231c:	00383278 	.inst	0x00383278 ; undefined
    2320:	430d3103 	.inst	0x430d3103 ; undefined
    2324:	e0000000 	ld1b	{za0h.b[w12, 0]}, p0/z, [x0, x0]
    2328:	39327801 	strb	w1, [x0, #3230]
    232c:	0d320300 	.inst	0x0d320300 ; undefined
    2330:	00000043 	udf	#67
    2334:	337801e8 	.inst	0x337801e8 ; undefined
    2338:	33030030 	bfi	w16, w1, #29, #1
    233c:	0000430d 	udf	#17165
    2340:	7301f000 	.inst	0x7301f000 ; undefined
    2344:	03003070 	.inst	0x03003070 ; undefined
    2348:	00430d34 	.inst	0x00430d34 ; undefined
    234c:	11f80000 	.inst	0x11f80000 ; undefined
    2350:	0000023b 	udf	#571
    2354:	00004335 	udf	#17205
    2358:	12010000 	and	w0, w0, #0x80000000
    235c:	00727365 	.inst	0x00727365 ; undefined
    2360:	00004336 	udf	#17206
    2364:	12010800 	and	w0, w0, #0x80000003
    2368:	00726c65 	.inst	0x00726c65 ; undefined
    236c:	00004337 	udf	#17207
    2370:	11011000 	add	w0, w0, #0x44
    2374:	000001c3 	udf	#451
    2378:	00004338 	udf	#17208
    237c:	00011800 	.inst	0x00011800 ; undefined
    2380:	0001d90a 	.inst	0x0001d90a ; undefined
    2384:	07040800 	.inst	0x07040800 ; undefined
    2388:	00000312 	udf	#786
    238c:	00023605 	.inst	0x00023605 ; undefined
    2390:	0f080400 	sshr	v0.8b, v0.8b, #8
    2394:	00000312 	udf	#786
    2398:	f8060000 	stur	x0, [x0, #96]
    239c:	0a000002 	and	w2, w0, w0
    23a0:	000001d5 	udf	#469
    23a4:	3e0b0410 	.inst	0x3e0b0410 ; undefined
    23a8:	05000003 	orr	z3.s, z3.s, #0x1
    23ac:	00000236 	udf	#566
    23b0:	120f0c04 	and	w4, w0, #0x1e0000
    23b4:	00000003 	udf	#3
    23b8:	00023105 	.inst	0x00023105 ; undefined
    23bc:	0f0d0400 	sshr	v0.8b, v0.8b, #3
    23c0:	00000312 	udf	#786
    23c4:	c80a0008 	stxr	w10, x8, [x0]
    23c8:	38000001 	sturb	w1, [x0]
    23cc:	03b20805 	.inst	0x03b20805 ; undefined
    23d0:	36050000 	tbz	w0, #0, ffffffffffffc3d0 <FS_BASE+0xffffcfffc3d0>
    23d4:	05000002 	orr	z2.s, z2.s, #0x1
    23d8:	03120f09 	.inst	0x03120f09 ; undefined
    23dc:	01000000 	.inst	0x01000000 ; undefined
    23e0:	00646970 	.inst	0x00646970 ; undefined
    23e4:	3c090a05 	.inst	0x3c090a05 ; undefined
    23e8:	08000000 	stxrb	w0, w0, [x0]
    23ec:	0001bd05 	.inst	0x0001bd05 ; undefined
    23f0:	060b0500 	.inst	0x060b0500 ; undefined
    23f4:	0000003c 	udf	#60
    23f8:	09cc050c 	.inst	0x09cc050c ; undefined
    23fc:	0c050000 	.inst	0x0c050000 ; undefined
    2400:	00003c07 	udf	#15367
    2404:	10051000 	adr	x0, c604 <MAIR_ATTR+0x8204>
    2408:	05000009 	orr	z9.s, z9.s, #0x1
    240c:	006a0b0d 	.inst	0x006a0b0d ; undefined
    2410:	05180000 	mov	z0.b, p8/z, #0
    2414:	00000217 	udf	#535
    2418:	6a0b0e05 	ands	w5, w16, w11, lsl #3
    241c:	20000000 	.inst	0x20000000 ; undefined
    2420:	00035f05 	.inst	0x00035f05 ; undefined
    2424:	0b0f0500 	add	w0, w8, w15, lsl #1
    2428:	0000006a 	udf	#106
    242c:	66740128 	.inst	0x66740128 ; undefined
    2430:	14100500 	b	403830 <PAGE_SIZE+0x203830>
    2434:	000003b2 	udf	#946
    2438:	23060030 	.inst	0x23060030 ; undefined
    243c:	0a000001 	and	w1, w0, w0
    2440:	000003d7 	udf	#983
    2444:	f8130538 	str	x24, [x9], #-208
    2448:	05000003 	orr	z3.s, z3.s, #0x1
    244c:	000003e6 	udf	#998
    2450:	f8121405 	str	x5, [x0], #-223
    2454:	00000003 	udf	#3
    2458:	00043e05 	.inst	0x00043e05 ; undefined
    245c:	12150500 	and	w0, w8, #0x1800
    2460:	00000317 	udf	#791
    2464:	04270508 	sub	z8.b, z8.b, z7.b
    2468:	17050000 	b	fffffffffc142468 <FS_BASE+0xffffcc142468>
    246c:	00031712 	.inst	0x00031712 ; undefined
    2470:	b5051800 	cbnz	x0, c770 <MAIR_ATTR+0x8370>
    2474:	05000003 	orr	z3.s, z3.s, #0x1
    2478:	03171218 	.inst	0x03171218 ; undefined
    247c:	00280000 	.inst	0x00280000 ; undefined
    2480:	00033e06 	.inst	0x00033e06 ; undefined
    2484:	01f81300 	.inst	0x01f81300 ; undefined
    2488:	2e050000 	ext	v0.8b, v0.8b, v5.8b, #0
    248c:	0003f818 	.inst	0x0003f818 ; undefined
    2490:	03fd1d00 	.inst	0x03fd1d00 ; undefined
    2494:	0b010000 	add	w0, w0, w1
    2498:	e0030911 	.inst	0xe0030911 ; undefined
    249c:	000008d2 	udf	#2258
    24a0:	13ffff00 	.inst	0x13ffff00 ; undefined
    24a4:	00000589 	udf	#1417
    24a8:	6a110d01 	ands	w1, w8, w17, lsl #3
    24ac:	1e000000 	.inst	0x1e000000 ; undefined
    24b0:	0000033e 	udf	#830
    24b4:	00000437 	udf	#1079
    24b8:	0000751f 	udf	#29983
    24bc:	04000900 	add	z0.b, p2/m, z0.b, z8.b
    24c0:	000008ac 	udf	#2220
    24c4:	0427170f 	uqadd	z15.b, z24.b, z7.b
    24c8:	03090000 	.inst	0x03090000 ; undefined
    24cc:	0008d2e8 	.inst	0x0008d2e8 ; undefined
    24d0:	ffff0000 	.inst	0xffff0000 ; undefined
    24d4:	0008cc04 	.inst	0x0008cc04 ; undefined
    24d8:	3c0c1000 	stur	b0, [x0, #193]
    24dc:	09000000 	.inst	0x09000000 ; undefined
    24e0:	08d2b803 	.inst	0x08d2b803 ; undefined
    24e4:	ff000000 	.inst	0xff000000 ; undefined
    24e8:	637014ff 	.inst	0x637014ff ; undefined
    24ec:	b71e1100 	tbnz	x0, #35, ffffffffffffe70c <FS_BASE+0xffffcfffe70c>
    24f0:	09000003 	.inst	0x09000003 ; undefined
    24f4:	08d51803 	ldlarb	w3, [x0]
    24f8:	ff000000 	.inst	0xff000000 ; undefined
    24fc:	047409ff 	.inst	0x047409ff ; undefined
    2500:	27060000 	.inst	0x27060000 ; undefined
    2504:	00000486 	udf	#1158
    2508:	00006a03 	udf	#27139
    250c:	4b090000 	sub	w0, w0, w9
    2510:	06000005 	.inst	0x06000005 ; undefined
    2514:	00049721 	.inst	0x00049721 ; undefined
    2518:	006a0300 	.inst	0x006a0300 ; undefined
    251c:	0b000000 	add	w0, w0, w0
    2520:	000001de 	udf	#478
    2524:	120e1e04 	and	w4, w16, #0x3fc0000
    2528:	b2000003 	orr	x3, x0, #0x100000001
    252c:	03000004 	.inst	0x03000004 ; undefined
    2530:	000004b2 	udf	#1202
    2534:	00003c03 	udf	#15363
    2538:	17060000 	b	fffffffffc182538 <FS_BASE+0xffffcc182538>
    253c:	0b000003 	add	w3, w0, w0
    2540:	00000206 	udf	#518
    2544:	120e1b04 	and	w4, w24, #0x1fc0000
    2548:	cd000003 	.inst	0xcd000003 ; undefined
    254c:	03000004 	.inst	0x03000004 ; undefined
    2550:	000004b2 	udf	#1202
    2554:	01ea0b00 	.inst	0x01ea0b00 ; undefined
    2558:	1c040000 	ldr	s0, a558 <MAIR_ATTR+0x6158>
    255c:	0004e306 	.inst	0x0004e306 ; undefined
    2560:	0004e300 	.inst	0x0004e300 ; undefined
    2564:	04b20300 	add	z0.s, z24.s, z18.s
    2568:	07000000 	.inst	0x07000000 ; undefined
    256c:	02000201 	.inst	0x02000201 ; undefined
    2570:	e9090000 	sttp	x0, x0, [x0, #144]
    2574:	05000008 	orr	z8.s, z8.s, #0x1
    2578:	00050027 	.inst	0x00050027 ; undefined
    257c:	05000300 	orr	z0.s, z0.s, #0x1ffffff
    2580:	6a030000 	ands	w0, w0, w3
    2584:	00000000 	udf	#0
    2588:	00006a06 	udf	#27142
    258c:	04ce0900 	.inst	0x04ce0900 ; undefined
    2590:	24060000 	cmphs	p0.b, p0/z, z0.b, z6.b
    2594:	00000516 	udf	#1302
    2598:	00006a03 	udf	#27139
    259c:	39200000 	strb	w0, [x0, #2048]
    25a0:	05000009 	orr	z9.s, z9.s, #0x1
    25a4:	05280d30 	ext	z16.b, z16.b, z9.b, #67
    25a8:	b2030000 	orr	x0, x0, #0x2000000020000000
    25ac:	00000003 	udf	#3
    25b0:	00022509 	.inst	0x00022509 ; undefined
    25b4:	3e1a0400 	.inst	0x3e1a0400 ; undefined
    25b8:	03000005 	.inst	0x03000005 ; undefined
    25bc:	000004b2 	udf	#1202
    25c0:	00031203 	.inst	0x00031203 ; undefined
    25c4:	e80b0000 	sttnp	x0, x0, [x0, #176]
    25c8:	06000004 	.inst	0x06000004 ; undefined
    25cc:	04e30625 	sub	z5.d, z17.d, z3.d
    25d0:	05590000 	mov	z0.h, p9/z, #0
    25d4:	6a030000 	ands	w0, w0, w3
    25d8:	03000000 	.inst	0x03000000 ; undefined
    25dc:	00000559 	udf	#1369
    25e0:	055e0600 	mov	z0.h, p14/z, #48
    25e4:	01070000 	.inst	0x01070000 ; undefined
    25e8:	00013a08 	.inst	0x00013a08 ; undefined
    25ec:	055e2100 	mov	z0.h, p14/z, #2048
    25f0:	78220000 	ldaddh	w2, w0, [x0]
    25f4:	05000008 	orr	z8.s, z8.s, #0x1
    25f8:	d8090628 	prfm	plil1keep, 146bc <MAIR_ATTR+0x102bc>
    25fc:	04000004 	add	z4.b, p0/m, z4.b, z0.b
    2600:	00058d14 	.inst	0x00058d14 ; undefined
    2604:	058d0300 	.inst	0x058d0300 ; undefined
    2608:	3c030000 	stur	b0, [x0, #48]
    260c:	03000000 	.inst	0x03000000 ; undefined
    2610:	00000063 	udf	#99
    2614:	24082300 	cmpeq	p0.b, p0/z, z24.b, z8.d
    2618:	0000047c 	udf	#1148
    261c:	8d072006 	.inst	0x8d072006 ; undefined
    2620:	09000005 	.inst	0x09000005 ; undefined
    2624:	0000036a 	udf	#874
    2628:	05b10b07 	uzp1	z7.q, z24.q, z17.q
    262c:	59030000 	stlurh	w0, [x0, #48]
    2630:	03000005 	.inst	0x03000005 ; undefined
    2634:	0000006a 	udf	#106
    2638:	01960b00 	.inst	0x01960b00 ; undefined
    263c:	06080000 	.inst	0x06080000 ; undefined
    2640:	00003c05 	udf	#15365
    2644:	0005c800 	.inst	0x0005c800 ; undefined
    2648:	05c80300 	.inst	0x05c80300 ; undefined
    264c:	00250000 	.inst	0x00250000 ; undefined
    2650:	00056506 	.inst	0x00056506 ; undefined
    2654:	09cc0800 	.inst	0x09cc0800 ; undefined
    2658:	01d70000 	.inst	0x01d70000 ; undefined
    265c:	08bdd406 	.inst	0x08bdd406 ; undefined
    2660:	ff000000 	.inst	0xff000000 ; undefined
    2664:	0000c0ff 	udf	#49407
    2668:	00000000 	udf	#0
    266c:	289c0100 	stp	w0, w0, [x8], #224
    2670:	0e000006 	tbl	v6.8b, {v0.16b}, v0.8b
    2674:	00646970 	.inst	0x00646970 ; undefined
    2678:	3c0f01d7 	stur	b23, [x14, #240]
    267c:	02000000 	.inst	0x02000000 ; undefined
    2680:	81025c91 	.inst	0x81025c91 ; undefined
    2684:	d9000009 	stlur	x9, [x0]
    2688:	03f81501 	.inst	0x03f81501 ; undefined
    268c:	91020000 	add	x0, x0, #0x80
    2690:	09560268 	.inst	0x09560268 ; undefined
    2694:	01da0000 	.inst	0x01da0000 ; undefined
    2698:	0006281c 	.inst	0x0006281c ; undefined
    269c:	78910200 	ldursh	x0, [x16, #-240]
    26a0:	00032302 	.inst	0x00032302 ; undefined
    26a4:	1601db00 	b	fffffffff80792a4 <FS_BASE+0xffffc80792a4>
    26a8:	000004b2 	udf	#1202
    26ac:	00709102 	.inst	0x00709102 ; undefined
    26b0:	0003b706 	.inst	0x0003b706 ; undefined
    26b4:	09a00800 	.inst	0x09a00800 ; undefined
    26b8:	01c70000 	.inst	0x01c70000 ; undefined
    26bc:	08bd7406 	.inst	0x08bd7406 ; undefined
    26c0:	ff000000 	.inst	0xff000000 ; undefined
    26c4:	000060ff 	udf	#24831
    26c8:	00000000 	udf	#0
    26cc:	6a9c0100 	ands	w0, w8, w28, asr #0
    26d0:	02000006 	.inst	0x02000006 ; undefined
    26d4:	00000981 	udf	#2433
    26d8:	f81501c9 	stur	x9, [x14, #-176]
    26dc:	02000003 	.inst	0x02000003 ; undefined
    26e0:	56027091 	.inst	0x56027091 ; undefined
    26e4:	ca000009 	eor	x9, x0, x0
    26e8:	06281c01 	.inst	0x06281c01 ; undefined
    26ec:	91020000 	add	x0, x0, #0x80
    26f0:	4f080078 	fdot	v24.4s, v3.16b, v8.4b[0]
    26f4:	b3000004 	.inst	0xb3000004 ; undefined
    26f8:	bcf00601 	.inst	0xbcf00601 ; undefined
    26fc:	00000008 	udf	#8
    2700:	0084ffff 	.inst	0x0084ffff ; undefined
    2704:	00000000 	udf	#0
    2708:	9c010000 	ldr	q0, 4708 <MAIR_ATTR+0x308>
    270c:	000006d4 	udf	#1748
    2710:	0009cc0c 	.inst	0x0009cc0c ; undefined
    2714:	1201b300 	and	w0, w24, #0x8fff8fff
    2718:	0000003c 	udf	#60
    271c:	025c9102 	.inst	0x025c9102 ; undefined
    2720:	00000981 	udf	#2433
    2724:	f81501b5 	stur	x21, [x13, #-176]
    2728:	02000003 	.inst	0x02000003 ; undefined
    272c:	56027891 	.inst	0x56027891 ; undefined
    2730:	b6000009 	tbz	x9, #32, 2730 <_binary_init_bin_size+0x1fe8>
    2734:	06281c01 	.inst	0x06281c01 ; undefined
    2738:	91020000 	add	x0, x0, #0x80
    273c:	043e0270 	add	z16.b, z19.b, z30.b
    2740:	01b70000 	.inst	0x01b70000 ; undefined
    2744:	0004b216 	.inst	0x0004b216 ; undefined
    2748:	68910200 	stgp	x0, x0, [x16], #544
    274c:	00042702 	.inst	0x00042702 ; undefined
    2750:	1601b800 	b	fffffffff8070750 <FS_BASE+0xffffc8070750>
    2754:	000004b2 	udf	#1202
    2758:	00609102 	.inst	0x00609102 ; undefined
    275c:	00099608 	.inst	0x00099608 ; undefined
    2760:	0601a500 	.inst	0x0601a500 ; undefined
    2764:	0008bc98 	.inst	0x0008bc98 ; undefined
    2768:	ffff0000 	.inst	0xffff0000 ; undefined
    276c:	00000058 	udf	#88
    2770:	00000000 	udf	#0
    2774:	07209c01 	.inst	0x07209c01 ; undefined
    2778:	cc0c0000 	.inst	0xcc0c0000 ; undefined
    277c:	a5000009 	ld1rqw	{z9.s}, p0/z, [x0, x0, lsl #2]
    2780:	003c1001 	.inst	0x003c1001 ; undefined
    2784:	91020000 	add	x0, x0, #0x80
    2788:	0981026c 	.inst	0x0981026c ; undefined
    278c:	01a70000 	.inst	0x01a70000 ; undefined
    2790:	0003f815 	.inst	0x0003f815 ; undefined
    2794:	70910200 	adr	x0, fffffffffff247d7 <FS_BASE+0xffffcff247d7>
    2798:	00095602 	.inst	0x00095602 ; undefined
    279c:	1c01a800 	ldr	s0, 5c9c <MAIR_ATTR+0x189c>
    27a0:	00000628 	udf	#1576
    27a4:	00789102 	.inst	0x00789102 ; undefined
    27a8:	00044908 	.inst	0x00044908 ; undefined
    27ac:	06018f00 	.inst	0x06018f00 ; undefined
    27b0:	0008bc1c 	.inst	0x0008bc1c ; undefined
    27b4:	ffff0000 	.inst	0xffff0000 ; undefined
    27b8:	0000007c 	udf	#124
    27bc:	00000000 	udf	#0
    27c0:	076c9c01 	.inst	0x076c9c01 ; undefined
    27c4:	81020000 	bfmop4a	za0.s, z0.h, z18.h
    27c8:	91000009 	add	x9, x0, #0x0
    27cc:	03f81501 	.inst	0x03f81501 ; undefined
    27d0:	91020000 	add	x0, x0, #0x80
    27d4:	09560268 	.inst	0x09560268 ; undefined
    27d8:	01920000 	.inst	0x01920000 ; undefined
    27dc:	0006281c 	.inst	0x0006281c ; undefined
    27e0:	78910200 	ldursh	x0, [x16, #-240]
    27e4:	00032302 	.inst	0x00032302 ; undefined
    27e8:	16019300 	b	fffffffff80673e8 <FS_BASE+0xffffc80673e8>
    27ec:	000004b2 	udf	#1202
    27f0:	00709102 	.inst	0x00709102 ; undefined
    27f4:	00045708 	.inst	0x00045708 ; undefined
    27f8:	07016500 	.inst	0x07016500 ; undefined
    27fc:	0008bb70 	.inst	0x0008bb70 ; undefined
    2800:	ffff0000 	.inst	0xffff0000 ; undefined
    2804:	000000ac 	udf	#172
    2808:	00000000 	udf	#0
    280c:	07c79c01 	.inst	0x07c79c01 ; undefined
    2810:	65020000 	bfadd	z0.h, z0.h, z2.h
    2814:	67000008 	.inst	0x67000008 ; undefined
    2818:	03f81501 	.inst	0x03f81501 ; undefined
    281c:	91020000 	add	x0, x0, #0x80
    2820:	08d40260 	ldlarb	w0, [x19]
    2824:	01680000 	.inst	0x01680000 ; undefined
    2828:	0003f815 	.inst	0x0003f815 ; undefined
    282c:	78910200 	ldursh	x0, [x16, #-240]
    2830:	00095602 	.inst	0x00095602 ; undefined
    2834:	1c016900 	ldr	s0, 5554 <MAIR_ATTR+0x1154>
    2838:	00000628 	udf	#1576
    283c:	02709102 	.inst	0x02709102 ; undefined
    2840:	00000323 	udf	#803
    2844:	b216016a 	orr	x10, x11, #0x40000000400
    2848:	02000004 	.inst	0x02000004 ; undefined
    284c:	26006891 	.inst	0x26006891 ; undefined
    2850:	00000884 	udf	#2180
    2854:	05015f01 	orr	z1.b, z1.b, #0x22
    2858:	0000003c 	udf	#60
    285c:	0008bb48 	.inst	0x0008bb48 ; undefined
    2860:	ffff0000 	.inst	0xffff0000 ; undefined
    2864:	00000028 	udf	#40
    2868:	00000000 	udf	#0
    286c:	07fa9c01 	.inst	0x07fa9c01 ; undefined
    2870:	8d0c0000 	.inst	0x8d0c0000 ; undefined
    2874:	5f000009 	.inst	0x5f000009 ; undefined
    2878:	006a2001 	.inst	0x006a2001 ; undefined
    287c:	91020000 	add	x0, x0, #0x80
    2880:	1e080078 	.inst	0x1e080078 ; undefined
    2884:	46000009 	.inst	0x46000009 ; undefined
    2888:	ba9c0601 	.inst	0xba9c0601 ; undefined
    288c:	00000008 	udf	#8
    2890:	00acffff 	.inst	0x00acffff ; undefined
    2894:	00000000 	udf	#0
    2898:	9c010000 	ldr	q0, 4898 <MAIR_ATTR+0x498>
    289c:	00000875 	udf	#2165
    28a0:	00706615 	.inst	0x00706615 ; undefined
    28a4:	6a0e0148 	ands	w8, w10, w14
    28a8:	02000000 	.inst	0x02000000 ; undefined
    28ac:	6c277891 	stnp	d17, d30, [x4, #-400]
    28b0:	48010072 	stxrh	w1, w18, [x3]
    28b4:	006a1201 	.inst	0x006a1201 ; undefined
    28b8:	18020000 	ldr	w0, 68b8 <MAIR_ATTR+0x24b8>
    28bc:	49000009 	.inst	0x49000009 ; undefined
    28c0:	003c0901 	.inst	0x003c0901 ; undefined
    28c4:	91020000 	add	x0, x0, #0x80
    28c8:	000c2874 	.inst	0x000c2874 ; undefined
    28cc:	17020000 	b	fffffffffc0828cc <FS_BASE+0xffffcc0828cc>
    28d0:	50000008 	adr	x8, 28d2 <_binary_init_bin_size+0x218a>
    28d4:	05001301 	orr	z1.s, z1.s, #0xc07fffff
    28d8:	91020000 	add	x0, x0, #0x80
    28dc:	08e10268 	.inst	0x08e10268 ; undefined
    28e0:	01520000 	.inst	0x01520000 ; undefined
    28e4:	00006a12 	udf	#27154
    28e8:	60910200 	.inst	0x60910200 ; undefined
    28ec:	00098902 	.inst	0x00098902 ; undefined
    28f0:	12015300 	and	w0, w24, #0x800fffff
    28f4:	0000006a 	udf	#106
    28f8:	00589102 	.inst	0x00589102 ; undefined
    28fc:	090b0800 	.inst	0x090b0800 ; undefined
    2900:	01210000 	.inst	0x01210000 ; undefined
    2904:	08b87809 	.inst	0x08b87809 ; undefined
    2908:	ff000000 	.inst	0xff000000 ; undefined
    290c:	000224ff 	.inst	0x000224ff ; undefined
    2910:	00000000 	udf	#0
    2914:	bf9c0100 	.inst	0xbf9c0100 ; undefined
    2918:	0e000008 	tbl	v8.8b, {v0.16b}, v0.8b
    291c:	00676174 	.inst	0x00676174 ; undefined
    2920:	c8220121 	stxp	w2, x1, x0, [x9]
    2924:	02000005 	.inst	0x02000005 ; undefined
    2928:	700e6891 	adr	x17, 1f63b <MAIR_ATTR+0x1b23b>
    292c:	37012100 	tbnz	w0, #0, 4d4c <MAIR_ATTR+0x94c>
    2930:	000003f8 	udf	#1016
    2934:	15609102 	b	5826d3c <FS_SIZE+0x2670d3c>
    2938:	00787463 	.inst	0x00787463 ; undefined
    293c:	bf190123 	.inst	0xbf190123 ; undefined
    2940:	02000008 	.inst	0x02000008 ; undefined
    2944:	06007891 	.inst	0x06007891 ; undefined
    2948:	0000007c 	udf	#124
    294c:	00096608 	.inst	0x00096608 ; undefined
    2950:	07011700 	.inst	0x07011700 ; undefined
    2954:	0008b834 	.inst	0x0008b834 ; undefined
    2958:	ffff0000 	.inst	0xffff0000 ; undefined
    295c:	00000044 	udf	#68
    2960:	00000000 	udf	#0
    2964:	09019c01 	.inst	0x09019c01 ; undefined
    2968:	200c0000 	.inst	0x200c0000 ; undefined
    296c:	17000002 	b	fffffffffc002974 <FS_BASE+0xffffcc002974>
    2970:	03f82601 	.inst	0x03f82601 ; undefined
    2974:	91020000 	add	x0, x0, #0x80
    2978:	01f80c78 	.inst	0x01f80c78 ; undefined
    297c:	01170000 	.inst	0x01170000 ; undefined
    2980:	0003f83c 	.inst	0x0003f83c ; undefined
    2984:	70910200 	adr	x0, fffffffffff249c7 <FS_BASE+0xffffcff249c7>
    2988:	01241600 	.inst	0x01241600 ; undefined
    298c:	010e0000 	.inst	0x010e0000 ; undefined
    2990:	0008b80c 	.inst	0x0008b80c ; undefined
    2994:	ffff0000 	.inst	0xffff0000 ; undefined
    2998:	00000028 	udf	#40
    299c:	00000000 	udf	#0
    29a0:	6f169c01 	uqrshrn2	v1.8h, v0.4s, #10
    29a4:	02000008 	.inst	0x02000008 ; undefined
    29a8:	08b7e001 	.inst	0x08b7e001 ; undefined
    29ac:	ff000000 	.inst	0xff000000 ; undefined
    29b0:	00002cff 	udf	#11519
    29b4:	00000000 	udf	#0
    29b8:	179c0100 	b	fffffffffe702db8 <FS_BASE+0xffffce702db8>
    29bc:	00000853 	udf	#2131
    29c0:	b6f406d7 	tbz	x23, #62, ffffffffffffaa98 <FS_BASE+0xffffcfffaa98>
    29c4:	00000008 	udf	#8
    29c8:	00ecffff 	.inst	0x00ecffff ; undefined
    29cc:	00000000 	udf	#0
    29d0:	9c010000 	ldr	q0, 49d0 <MAIR_ATTR+0x5d0>
    29d4:	0000098c 	udf	#2444
    29d8:	d700700f 	.inst	0xd700700f ; undefined
    29dc:	0003f828 	.inst	0x0003f828 ; undefined
    29e0:	68910200 	stgp	x0, x0, [x16], #544
    29e4:	0009810d 	.inst	0x0009810d ; undefined
    29e8:	f817d900 	sttr	x0, [x8, #-131]
    29ec:	0d000003 	st1	{v3.b}[0], [x0]
    29f0:	00000956 	udf	#2390
    29f4:	06281cda 	.inst	0x06281cda ; undefined
    29f8:	230d0000 	.inst	0x230d0000 ; undefined
    29fc:	db000003 	.inst	0xdb000003 ; undefined
    2a00:	0004b216 	.inst	0x0004b216 ; undefined
    2a04:	081d0400 	stxrb	w29, w0, [x0]
    2a08:	0edf0000 	.inst	0x0edf0000 ; undefined
    2a0c:	0000006a 	udf	#106
    2a10:	00789102 	.inst	0x00789102 ; undefined
    2a14:	0008a229 	.inst	0x0008a229 ; undefined
    2a18:	14c70100 	b	31c2e18 <FS_SIZE+0xce18>
    2a1c:	0008b6b8 	.inst	0x0008b6b8 ; undefined
    2a20:	ffff0000 	.inst	0xffff0000 ; undefined
    2a24:	0000003c 	udf	#60
    2a28:	00000000 	udf	#0
    2a2c:	09c89c01 	.inst	0x09c89c01 ; undefined
    2a30:	392a0000 	strb	w0, [x0, #2688]
    2a34:	01000008 	.inst	0x01000008 ; undefined
    2a38:	006a27c7 	.inst	0x006a27c7 ; undefined
    2a3c:	91020000 	add	x0, x0, #0x80
    2a40:	08ee0468 	.inst	0x08ee0468 ; undefined
    2a44:	0ec90000 	.inst	0x0ec90000 ; undefined
    2a48:	0000006a 	udf	#106
    2a4c:	00789102 	.inst	0x00789102 ; undefined
    2a50:	0008f518 	.inst	0x0008f518 ; undefined
    2a54:	b610b200 	tbz	x0, #34, 4094 <_binary_init_bin_size+0x394c>
    2a58:	00000008 	udf	#8
    2a5c:	00a8ffff 	.inst	0x00a8ffff ; undefined
    2a60:	00000000 	udf	#0
    2a64:	9c010000 	ldr	q0, 4a64 <MAIR_ATTR+0x664>
    2a68:	00000a1c 	udf	#2588
    2a6c:	006e660f 	.inst	0x006e660f ; undefined
    2a70:	0a1d2ab2 	and	w18, w21, w29, lsl #10
    2a74:	91020000 	add	x0, x0, #0x80
    2a78:	09810458 	.inst	0x09810458 ; undefined
    2a7c:	15b40000 	b	6d02a7c <FS_SIZE+0x3b4ca7c>
    2a80:	000003f8 	udf	#1016
    2a84:	04789102 	asr	z2.s, z8.s, #8
    2a88:	00000956 	udf	#2390
    2a8c:	06281cb5 	.inst	0x06281cb5 ; undefined
    2a90:	91020000 	add	x0, x0, #0x80
    2a94:	03230470 	.inst	0x03230470 ; undefined
    2a98:	16b60000 	b	fffffffffad82a98 <FS_BASE+0xffffcad82a98>
    2a9c:	000004b2 	udf	#1202
    2aa0:	00689102 	.inst	0x00689102 ; undefined
    2aa4:	0a1c062b 	and	w11, w17, w28, lsl #1
    2aa8:	40190000 	.inst	0x40190000 ; undefined
    2aac:	89000008 	.inst	0x89000008 ; undefined
    2ab0:	000003f8 	udf	#1016
    2ab4:	0008b4e4 	.inst	0x0008b4e4 ; undefined
    2ab8:	ffff0000 	.inst	0xffff0000 ; undefined
    2abc:	0000012c 	udf	#300
    2ac0:	00000000 	udf	#0
    2ac4:	0a5e9c01 	.inst	0x0a5e9c01 ; undefined
    2ac8:	660f0000 	.inst	0x660f0000 ; undefined
    2acc:	3289006e 	.inst	0x3289006e ; undefined
    2ad0:	00000a1d 	udf	#2589
    2ad4:	04689102 	asr	z2.s, z8.s, #24
    2ad8:	00000981 	udf	#2433
    2adc:	03f8158b 	.inst	0x03f8158b ; undefined
    2ae0:	91020000 	add	x0, x0, #0x80
    2ae4:	27180078 	.inst	0x27180078 ; undefined
    2ae8:	77000008 	.inst	0x77000008 ; undefined
    2aec:	0008b440 	.inst	0x0008b440 ; undefined
    2af0:	ffff0000 	.inst	0xffff0000 ; undefined
    2af4:	000000a4 	udf	#164
    2af8:	00000000 	udf	#0
    2afc:	0aa59c01 	.inst	0x0aa59c01 ; undefined
    2b00:	81040000 	bfmop4a	za0.s, z0.h, z20.h
    2b04:	79000009 	strh	w9, [x0]
    2b08:	0003f815 	.inst	0x0003f815 ; undefined
    2b0c:	78910200 	ldursh	x0, [x16, #-240]
    2b10:	00095604 	.inst	0x00095604 ; undefined
    2b14:	281c7a00 	stnp	w0, w30, [x16, #224]
    2b18:	02000006 	.inst	0x02000006 ; undefined
    2b1c:	23047091 	.inst	0x23047091 ; undefined
    2b20:	7b000003 	.inst	0x7b000003 ; undefined
    2b24:	0004b216 	.inst	0x0004b216 ; undefined
    2b28:	68910200 	stgp	x0, x0, [x16], #544
    2b2c:	09441900 	.inst	0x09441900 ; undefined
    2b30:	f8590000 	ldur	x0, [x0, #-112]
    2b34:	c4000003 	ld1sb	{z3.d}, p0/z, [x0, z0.d, uxtw]
    2b38:	000008b2 	udf	#2226
    2b3c:	7cffff00 	.inst	0x7cffff00 ; undefined
    2b40:	00000001 	udf	#1
    2b44:	01000000 	.inst	0x01000000 ; undefined
    2b48:	000ad49c 	.inst	0x000ad49c ; undefined
    2b4c:	09810400 	.inst	0x09810400 ; undefined
    2b50:	155b0000 	b	56c2b50 <FS_SIZE+0x250cb50>
    2b54:	000003f8 	udf	#1016
    2b58:	00789102 	.inst	0x00789102 ; undefined
    2b5c:	0008ba17 	.inst	0x0008ba17 ; undefined
    2b60:	98072f00 	ldrsw	x0, 11140 <MAIR_ATTR+0xcd40>
    2b64:	000008b1 	udf	#2225
    2b68:	2cffff00 	ldp	s0, s31, [x24], #-4
    2b6c:	00000001 	udf	#1
    2b70:	01000000 	.inst	0x01000000 ; undefined
    2b74:	000b199c 	.inst	0x000b199c ; undefined
    2b78:	09810400 	.inst	0x09810400 ; undefined
    2b7c:	15310000 	b	4c42b7c <FS_SIZE+0x1a8cb7c>
    2b80:	000003f8 	udf	#1016
    2b84:	04789102 	asr	z2.s, z8.s, #8
    2b88:	00000956 	udf	#2390
    2b8c:	06281c32 	.inst	0x06281c32 ; undefined
    2b90:	91020000 	add	x0, x0, #0x80
    2b94:	03230d70 	.inst	0x03230d70 ; undefined
    2b98:	16330000 	b	fffffffff8cc2b98 <FS_BASE+0xffffc8cc2b98>
    2b9c:	000004b2 	udf	#1202
    2ba0:	08962c00 	stllrb	w0, [x0]
    2ba4:	26010000 	.inst	0x26010000 ; undefined
    2ba8:	08b17807 	.inst	0x08b17807 ; undefined
    2bac:	ff000000 	.inst	0xff000000 ; undefined
    2bb0:	000020ff 	udf	#8447
    2bb4:	00000000 	udf	#0
    2bb8:	2d9c0100 	stp	s0, s0, [x8, #224]!
    2bbc:	00000975 	udf	#2421
    2bc0:	f8181901 	sttr	x1, [x8, #-127]
    2bc4:	00000003 	udf	#3
    2bc8:	000008b1 	udf	#2225
    2bcc:	78ffff00 	.inst	0x78ffff00 ; undefined
    2bd0:	00000000 	udf	#0
    2bd4:	01000000 	.inst	0x01000000 ; undefined
    2bd8:	000b829c 	.inst	0x000b829c ; undefined
    2bdc:	09810400 	.inst	0x09810400 ; undefined
    2be0:	151b0000 	b	46c2be0 <FS_SIZE+0x150cbe0>
    2be4:	000003f8 	udf	#1016
    2be8:	2e789102 	.inst	0x2e789102 ; undefined
    2bec:	0008b108 	.inst	0x0008b108 ; undefined
    2bf0:	ffff0000 	.inst	0xffff0000 ; undefined
    2bf4:	00000064 	udf	#100
    2bf8:	00000000 	udf	#0
    2bfc:	1d006914 	stlur	b20, [x8, #6]
    2c00:	00003c0e 	udf	#15374
    2c04:	74910200 	.inst	0x74910200 ; undefined
    2c08:	d02f0000 	adrp	x0, 5e004000 <FS_SIZE+0x5ae4e000>
    2c0c:	01000003 	.inst	0x01000003 ; undefined
    2c10:	06281814 	.inst	0x06281814 ; undefined
    2c14:	b0f40000 	adrp	x0, ffffffffe8003000 <FS_BASE+0xffffb8003000>
    2c18:	00000008 	udf	#8
    2c1c:	000cffff 	.inst	0x000cffff ; undefined
    2c20:	00000000 	udf	#0
    2c24:	9c010000 	ldr	q0, 4c24 <MAIR_ATTR+0x824>
    2c28:	00041000 	.inst	0x00041000 ; undefined
    2c2c:	01000500 	.inst	0x01000500 ; undefined
    2c30:	000e1708 	.inst	0x000e1708 ; undefined
    2c34:	00630c00 	.inst	0x00630c00 ; undefined
    2c38:	3d0c0000 	str	b0, [x0, #768]
    2c3c:	00000001 	udf	#1
    2c40:	94000000 	bl	2c40 <_binary_init_bin_size+0x24f8>
    2c44:	000008be 	udf	#2238
    2c48:	ccffff00 	.inst	0xccffff00 ; undefined
    2c4c:	00000001 	udf	#1
    2c50:	a4000000 	ld1rqb	{z0.b}, p0/z, [x0, x0]
    2c54:	02000012 	.inst	0x02000012 ; undefined
    2c58:	01330601 	.inst	0x01330601 ; undefined
    2c5c:	02020000 	.inst	0x02020000 ; undefined
    2c60:	0001a305 	.inst	0x0001a305 ; undefined
    2c64:	05040d00 	.inst	0x05040d00 ; undefined
    2c68:	00746e69 	.inst	0x00746e69 ; undefined
    2c6c:	00011007 	.inst	0x00011007 ; undefined
    2c70:	182b0200 	ldr	w0, 58cb0 <MAIR_ATTR+0x548b0>
    2c74:	0000004f 	udf	#79
    2c78:	3f050802 	.inst	0x3f050802 ; undefined
    2c7c:	02000001 	.inst	0x02000001 ; undefined
    2c80:	01310801 	.inst	0x01310801 ; undefined
    2c84:	02020000 	.inst	0x02020000 ; undefined
    2c88:	00017c07 	.inst	0x00017c07 ; undefined
    2c8c:	07040200 	.inst	0x07040200 ; undefined
    2c90:	00000155 	udf	#341
    2c94:	00010f07 	.inst	0x00010f07 ; undefined
    2c98:	19370200 	.inst	0x19370200 ; undefined
    2c9c:	00000077 	udf	#119
    2ca0:	50070802 	adr	x2, 10da2 <MAIR_ATTR+0xc9a2>
    2ca4:	0e000001 	tbl	v1.8b, {v0.16b}, v0.8b
    2ca8:	000001b3 	udf	#435
    2cac:	14030120 	b	c312c <MAIR_ATTR+0xbed2c>
    2cb0:	00021308 	.inst	0x00021308 ; undefined
    2cb4:	30780100 	adr	x0, f2cd5 <MAIR_ATTR+0xee8d5>
    2cb8:	00431500 	.inst	0x00431500 ; undefined
    2cbc:	01000000 	.inst	0x01000000 ; undefined
    2cc0:	16003178 	b	fffffffff800f2a0 <FS_BASE+0xffffc800f2a0>
    2cc4:	00000043 	udf	#67
    2cc8:	32780108 	.inst	0x32780108 ; undefined
    2ccc:	00431700 	.inst	0x00431700 ; undefined
    2cd0:	01100000 	.inst	0x01100000 ; undefined
    2cd4:	18003378 	ldr	w24, 3340 <_binary_init_bin_size+0x2bf8>
    2cd8:	00000043 	udf	#67
    2cdc:	34780118 	cbz	w24, f2cfc <MAIR_ATTR+0xee8fc>
    2ce0:	00431900 	.inst	0x00431900 ; undefined
    2ce4:	01200000 	.inst	0x01200000 ; undefined
    2ce8:	1a003578 	.inst	0x1a003578 ; undefined
    2cec:	00000043 	udf	#67
    2cf0:	36780128 	tbz	w8, #15, 2d14 <_binary_init_bin_size+0x25cc>
    2cf4:	00431b00 	.inst	0x00431b00 ; undefined
    2cf8:	01300000 	.inst	0x01300000 ; undefined
    2cfc:	1c003778 	ldr	s24, 33e8 <_binary_init_bin_size+0x2ca0>
    2d00:	00000043 	udf	#67
    2d04:	38780138 	ldaddlb	w24, w24, [x9]
    2d08:	00431d00 	.inst	0x00431d00 ; undefined
    2d0c:	01400000 	.inst	0x01400000 ; undefined
    2d10:	1e003978 	.inst	0x1e003978 ; undefined
    2d14:	00000043 	udf	#67
    2d18:	31780148 	adds	w8, w10, #0xe00, lsl #12
    2d1c:	431f0030 	.inst	0x431f0030 ; undefined
    2d20:	50000000 	adr	x0, 2d22 <_binary_init_bin_size+0x25da>
    2d24:	31317801 	adds	w1, w0, #0xc5e
    2d28:	00432000 	.inst	0x00432000 ; undefined
    2d2c:	01580000 	.inst	0x01580000 ; undefined
    2d30:	00323178 	.inst	0x00323178 ; undefined
    2d34:	00004321 	udf	#17185
    2d38:	78016000 	sturh	w0, [x0, #22]
    2d3c:	22003331 	.inst	0x22003331 ; undefined
    2d40:	00000043 	udf	#67
    2d44:	31780168 	adds	w8, w11, #0xe00, lsl #12
    2d48:	43230034 	.inst	0x43230034 ; undefined
    2d4c:	70000000 	adr	x0, 2d4f <_binary_init_bin_size+0x2607>
    2d50:	35317801 	cbnz	w1, 65c50 <MAIR_ATTR+0x61850>
    2d54:	00432400 	.inst	0x00432400 ; undefined
    2d58:	01780000 	.inst	0x01780000 ; undefined
    2d5c:	00363178 	.inst	0x00363178 ; undefined
    2d60:	00004325 	udf	#17189
    2d64:	78018000 	sturh	w0, [x0, #24]
    2d68:	26003731 	.inst	0x26003731 ; undefined
    2d6c:	00000043 	udf	#67
    2d70:	31780188 	adds	w8, w12, #0xe00, lsl #12
    2d74:	43270038 	.inst	0x43270038 ; undefined
    2d78:	90000000 	adrp	x0, 2000 <_binary_init_bin_size+0x18b8>
    2d7c:	39317801 	strb	w1, [x0, #3166]
    2d80:	00432800 	.inst	0x00432800 ; undefined
    2d84:	01980000 	.inst	0x01980000 ; undefined
    2d88:	00303278 	.inst	0x00303278 ; undefined
    2d8c:	00004329 	udf	#17193
    2d90:	7801a000 	sturh	w0, [x0, #26]
    2d94:	2a003132 	orr	w18, w9, w0, lsl #12
    2d98:	00000043 	udf	#67
    2d9c:	327801a8 	.inst	0x327801a8 ; undefined
    2da0:	432b0032 	.inst	0x432b0032 ; undefined
    2da4:	b0000000 	adrp	x0, 3000 <_binary_init_bin_size+0x28b8>
    2da8:	33327801 	.inst	0x33327801 ; undefined
    2dac:	00432c00 	.inst	0x00432c00 ; undefined
    2db0:	01b80000 	.inst	0x01b80000 ; undefined
    2db4:	00343278 	.inst	0x00343278 ; undefined
    2db8:	0000432d 	udf	#17197
    2dbc:	7801c000 	sturh	w0, [x0, #28]
    2dc0:	2e003532 	.inst	0x2e003532 ; undefined
    2dc4:	00000043 	udf	#67
    2dc8:	327801c8 	.inst	0x327801c8 ; undefined
    2dcc:	432f0036 	.inst	0x432f0036 ; undefined
    2dd0:	d0000000 	adrp	x0, 4000 <_binary_init_bin_size+0x38b8>
    2dd4:	37327801 	tbnz	w1, #6, 7cd4 <MAIR_ATTR+0x38d4>
    2dd8:	00433000 	.inst	0x00433000 ; undefined
    2ddc:	01d80000 	.inst	0x01d80000 ; undefined
    2de0:	00383278 	.inst	0x00383278 ; undefined
    2de4:	00004331 	udf	#17201
    2de8:	7801e000 	sturh	w0, [x0, #30]
    2dec:	32003932 	orr	w18, w9, #0x7fff
    2df0:	00000043 	udf	#67
    2df4:	337801e8 	.inst	0x337801e8 ; undefined
    2df8:	43330030 	.inst	0x43330030 ; undefined
    2dfc:	f0000000 	adrp	x0, 5000 <MAIR_ATTR+0xc00>
    2e00:	30707301 	adr	x1, e3c61 <MAIR_ATTR+0xdf861>
    2e04:	00433400 	.inst	0x00433400 ; undefined
    2e08:	0af80000 	bic	w0, w0, w24, ror #0
    2e0c:	0000023b 	udf	#571
    2e10:	00004335 	udf	#17205
    2e14:	0b010000 	add	w0, w0, w1
    2e18:	00727365 	.inst	0x00727365 ; undefined
    2e1c:	00004336 	udf	#17206
    2e20:	0b010800 	add	w0, w0, w1, lsl #2
    2e24:	00726c65 	.inst	0x00726c65 ; undefined
    2e28:	00004337 	udf	#17207
    2e2c:	0a011000 	and	w0, w0, w1, lsl #4
    2e30:	000001c3 	udf	#451
    2e34:	00004338 	udf	#17208
    2e38:	00011800 	.inst	0x00011800 ; undefined
    2e3c:	0009e207 	.inst	0x0009e207 ; undefined
    2e40:	0f060400 	movi	v0.2s, #0xc0
    2e44:	0000021f 	udf	#543
    2e48:	00022405 	.inst	0x00022405 ; undefined
    2e4c:	003c0f00 	.inst	0x003c0f00 ; undefined
    2e50:	02330000 	.inst	0x02330000 ; undefined
    2e54:	33040000 	bfi	w0, w0, #28, #1
    2e58:	00000002 	udf	#2
    2e5c:	00004305 	udf	#17157
    2e60:	007e0500 	.inst	0x007e0500 ; undefined
    2e64:	13100000 	sbfiz	w0, w0, #16, #1
    2e68:	4d000002 	st1	{v2.b}[8], [x0]
    2e6c:	11000002 	add	w2, w0, #0x0
    2e70:	00000077 	udf	#119
    2e74:	a5030009 	ld1rqw	{z9.s}, p0/z, [x0, x3, lsl #2]
    2e78:	08000009 	stxrb	w0, w9, [x0]
    2e7c:	00023d13 	.inst	0x00023d13 ; undefined
    2e80:	50030900 	adr	x0, 8fa2 <MAIR_ATTR+0x4ba2>
    2e84:	000008d5 	udf	#2261
    2e88:	08ffff00 	casalb	wzr, w0, [x24]
    2e8c:	000009cc 	udf	#2508
    2e90:	02732c05 	.inst	0x02732c05 ; undefined
    2e94:	3c040000 	stur	b0, [x0, #64]
    2e98:	00000000 	udf	#0
    2e9c:	0009a012 	.inst	0x0009a012 ; undefined
    2ea0:	062b0500 	.inst	0x062b0500 ; undefined
    2ea4:	00099608 	.inst	0x00099608 ; undefined
    2ea8:	8c290500 	.inst	0x8c290500 ; undefined
    2eac:	04000002 	add	z2.b, p0/m, z2.b, z0.b
    2eb0:	0000003c 	udf	#60
    2eb4:	04051300 	.inst	0x04051300 ; undefined
    2eb8:	3e030000 	.inst	0x3e030000 ; undefined
    2ebc:	00006b0a 	udf	#27402
    2ec0:	029a0800 	.inst	0x029a0800 ; undefined
    2ec4:	07060000 	.inst	0x07060000 ; undefined
    2ec8:	000002ae 	udf	#686
    2ecc:	0002ae04 	.inst	0x0002ae04 ; undefined
    2ed0:	003c0400 	.inst	0x003c0400 ; undefined
    2ed4:	05000000 	orr	z0.s, z0.s, #0x1
    2ed8:	000002ba 	udf	#698
    2edc:	3a080102 	adcs	w2, w8, w8
    2ee0:	14000001 	b	2ee4 <_binary_init_bin_size+0x279c>
    2ee4:	000002b3 	udf	#691
    2ee8:	00005215 	udf	#21013
    2eec:	063b0100 	.inst	0x063b0100 ; undefined
    2ef0:	0008c008 	.inst	0x0008c008 ; undefined
    2ef4:	ffff0000 	.inst	0xffff0000 ; undefined
    2ef8:	00000058 	udf	#88
    2efc:	00000000 	udf	#0
    2f00:	57169c01 	.inst	0x57169c01 ; undefined
    2f04:	01000000 	.inst	0x01000000 ; undefined
    2f08:	bf78062d 	.inst	0xbf78062d ; undefined
    2f0c:	00000008 	udf	#8
    2f10:	0090ffff 	.inst	0x0090ffff ; undefined
    2f14:	00000000 	udf	#0
    2f18:	9c010000 	ldr	q0, 4f18 <MAIR_ATTR+0xb18>
    2f1c:	0000032f 	udf	#815
    2f20:	00667417 	.inst	0x00667417 ; undefined
    2f24:	38242d01 	.inst	0x38242d01 ; undefined
    2f28:	02000002 	.inst	0x02000002 ; undefined
    2f2c:	69185891 	stgp	x17, x22, [x4, #768]
    2f30:	0d2f0100 	.inst	0x0d2f0100 ; undefined
    2f34:	00000043 	udf	#67
    2f38:	03789102 	.inst	0x03789102 ; undefined
    2f3c:	000009ed 	udf	#2541
    2f40:	00430d30 	.inst	0x00430d30 ; undefined
    2f44:	91020000 	add	x0, x0, #0x80
    2f48:	09db0370 	.inst	0x09db0370 ; undefined
    2f4c:	0e310000 	saddl	v0.8h, v0.8b, v17.8b
    2f50:	00000233 	udf	#563
    2f54:	00689102 	.inst	0x00689102 ; undefined
    2f58:	0009c809 	.inst	0x0009c809 ; undefined
    2f5c:	003c2700 	.inst	0x003c2700 ; undefined
    2f60:	bf540000 	.inst	0xbf540000 ; undefined
    2f64:	00000008 	udf	#8
    2f68:	0024ffff 	.inst	0x0024ffff ; undefined
    2f6c:	00000000 	udf	#0
    2f70:	9c010000 	ldr	q0, 4f70 <MAIR_ATTR+0xb70>
    2f74:	0000035e 	udf	#862
    2f78:	0009db06 	.inst	0x0009db06 ; undefined
    2f7c:	331e2700 	bfi	w0, w24, #2, #10
    2f80:	02000002 	.inst	0x02000002 ; undefined
    2f84:	09007891 	.inst	0x09007891 ; undefined
    2f88:	0000099c 	udf	#2460
    2f8c:	00003c21 	udf	#15393
    2f90:	08bf3800 	.inst	0x08bf3800 ; undefined
    2f94:	ff000000 	.inst	0xff000000 ; undefined
    2f98:	00001cff 	udf	#7423
    2f9c:	00000000 	udf	#0
    2fa0:	8d9c0100 	.inst	0x8d9c0100 ; undefined
    2fa4:	06000003 	.inst	0x06000003 ; undefined
    2fa8:	000009db 	udf	#2523
    2fac:	02331e21 	.inst	0x02331e21 ; undefined
    2fb0:	91020000 	add	x0, x0, #0x80
    2fb4:	92090078 	and	x24, x3, #0x80000000800000
    2fb8:	10000009 	adr	x9, 2fb8 <_binary_init_bin_size+0x2870>
    2fbc:	0000003c 	udf	#60
    2fc0:	0008bed8 	.inst	0x0008bed8 ; undefined
    2fc4:	ffff0000 	.inst	0xffff0000 ; undefined
    2fc8:	00000060 	udf	#96
    2fcc:	00000000 	udf	#0
    2fd0:	03e69c01 	.inst	0x03e69c01 ; undefined
    2fd4:	db060000 	.inst	0xdb060000 ; undefined
    2fd8:	10000009 	adr	x9, 2fd8 <_binary_init_bin_size+0x2890>
    2fdc:	0002331f 	.inst	0x0002331f ; undefined
    2fe0:	58910200 	ldr	x0, fffffffffff25020 <FS_BASE+0xffffcff25020>
    2fe4:	0009b603 	.inst	0x0009b603 ; undefined
    2fe8:	6b0e1200 	subs	w0, w16, w14, lsl #4
    2fec:	02000000 	.inst	0x02000000 ; undefined
    2ff0:	b2037891 	orr	x17, x4, #0xefffffffefffffff
    2ff4:	13000009 	sbfx	w9, w0, #0, #1
    2ff8:	00006b0e 	udf	#27406
    2ffc:	68910200 	stgp	x0, x0, [x16], #544
    3000:	0009bc03 	.inst	0x0009bc03 ; undefined
    3004:	6b0e1400 	subs	w0, w0, w14, lsl #5
    3008:	02000000 	.inst	0x02000000 ; undefined
    300c:	19007091 	stlurb	w17, [x4, #7]
    3010:	000009d1 	udf	#2513
    3014:	3c0c0a01 	.inst	0x3c0c0a01 ; undefined
    3018:	94000000 	bl	3018 <_binary_init_bin_size+0x28d0>
    301c:	000008be 	udf	#2238
    3020:	44ffff00 	.inst	0x44ffff00 ; undefined
    3024:	00000000 	udf	#0
    3028:	01000000 	.inst	0x01000000 ; undefined
    302c:	09db069c 	.inst	0x09db069c ; undefined
    3030:	1f0a0000 	fmadd	s0, s0, s10, s0
    3034:	00000233 	udf	#563
    3038:	00789102 	.inst	0x00789102 ; undefined
	...

Disassembly of section .debug_abbrev:

0000000000000000 <.debug_abbrev>:
   0:	10001101 	adr	x1, 220 <TCR_T0SZ+0x210>
   4:	12011117 	and	w23, w8, #0x8000000f
   8:	1b0e030f 	madd	w15, w24, w14, w0
   c:	130e250e 	sbfiz	w14, w8, #18, #10
  10:	00000005 	udf	#5
  14:	0b002401 	add	w1, w0, w0, lsl #9
  18:	030b3e0b 	.inst	0x030b3e0b ; undefined
  1c:	0200000e 	.inst	0x0200000e ; undefined
  20:	193f002e 	.inst	0x193f002e ; undefined
  24:	0b3a0e03 	add	w3, w16, w26, uxtb #3
  28:	21390b3b 	.inst	0x21390b3b ; undefined
  2c:	3c192706 	str	b6, [x24], #-110
  30:	03000019 	.inst	0x03000019 ; undefined
  34:	0e250111 	saddl	v17.8h, v8.8b, v5.8b
  38:	1f030b13 	fmadd	s19, s24, s3, s2
  3c:	01111f1b 	.inst	0x01111f1b ; undefined
  40:	17100712 	b	fffffffffc401c88 <FS_BASE+0xffffcc401c88>
  44:	24040000 	cmphs	p0.b, p0/z, z0.b, z4.b
  48:	3e0b0b00 	.inst	0x3e0b0b00 ; undefined
  4c:	0008030b 	.inst	0x0008030b ; undefined
  50:	00160500 	.inst	0x00160500 ; undefined
  54:	0b3a0e03 	add	w3, w16, w26, uxtb #3
  58:	0b390b3b 	add	w27, w25, w25, uxtb #2
  5c:	00001349 	udf	#4937
  60:	3f002e06 	.inst	0x3f002e06 ; undefined
  64:	3a0e0319 	adcs	w25, w24, w14
  68:	390b3b0b 	strb	w11, [x24, #718]
  6c:	4919270b 	.inst	0x4919270b ; undefined
  70:	00193c13 	.inst	0x00193c13 ; undefined
  74:	012e0700 	.inst	0x012e0700 ; undefined
  78:	0e03193f 	uzp1	v31.8b, v9.8b, v3.8b
  7c:	0b3b0b3a 	add	w26, w25, w27, uxtb #2
  80:	19270b39 	rcwcas	x7, x25, [x25]
  84:	193c1349 	ldclrp	x9, x28, [x26]
  88:	00001301 	udf	#4865
  8c:	49000508 	.inst	0x49000508 ; undefined
  90:	09000013 	.inst	0x09000013 ; undefined
  94:	00000018 	udf	#24
  98:	0b000f0a 	add	w10, w24, w0, lsl #3
  9c:	0013490b 	.inst	0x0013490b ; undefined
  a0:	00260b00 	.inst	0x00260b00 ; undefined
  a4:	00001349 	udf	#4937
  a8:	3f002e0c 	.inst	0x3f002e0c ; undefined
  ac:	3a0e0319 	adcs	w25, w24, w14
  b0:	390b3b0b 	strb	w11, [x24, #718]
  b4:	1119270b 	add	w11, w24, #0x649
  b8:	40071201 	.inst	0x40071201 ; undefined
  bc:	00197c18 	.inst	0x00197c18 ; undefined
  c0:	11010000 	add	w0, w0, #0x40
  c4:	11171000 	add	w0, w0, #0x5c4
  c8:	030f1201 	.inst	0x030f1201 ; undefined
  cc:	250e1b0e 	cmpge	p14.b, p6/z, z24.b, #14
  d0:	0005130e 	.inst	0x0005130e ; undefined
  d4:	0d010000 	.inst	0x0d010000 ; undefined
  d8:	3a080300 	adcs	w0, w24, w8
  dc:	390b3b0b 	strb	w11, [x24, #718]
  e0:	3813490b 	sttrb	w11, [x8, #-204]
  e4:	0200000b 	.inst	0x0200000b ; undefined
  e8:	0e03000d 	tbl	v13.8b, {v0.16b}, v3.8b
  ec:	0b3b0b3a 	add	w26, w25, w27, uxtb #2
  f0:	13490b39 	.inst	0x13490b39 ; undefined
  f4:	00000b38 	udf	#2872
  f8:	0b002403 	add	w3, w0, w0, lsl #9
  fc:	030b3e0b 	.inst	0x030b3e0b ; undefined
 100:	0400000e 	add	z14.b, p0/m, z14.b, z0.b
 104:	0e030005 	tbl	v5.8b, {v0.16b}, v3.8b
 108:	3b01213a 	.inst	0x3b01213a ; undefined
 10c:	490b390b 	.inst	0x490b390b ; undefined
 110:	00180213 	.inst	0x00180213 ; undefined
 114:	00340500 	.inst	0x00340500 ; undefined
 118:	213a0e03 	.inst	0x213a0e03 ; undefined
 11c:	390b3b01 	strb	w1, [x24, #718]
 120:	13491221 	.inst	0x13491221 ; undefined
 124:	00001802 	udf	#6146
 128:	03011306 	.inst	0x03011306 ; undefined
 12c:	3a0b0b0e 	.inst	0x3a0b0b0e ; undefined
 130:	390b3b0b 	strb	w11, [x24, #718]
 134:	13010821 	sbfx	w1, w1, #1, #2
 138:	0f070000 	fdot	v0.2s, v0.8b, v7.4b[0]
 13c:	08210b00 	.inst	0x08210b00 ; undefined
 140:	00001349 	udf	#4937
 144:	03001608 	.inst	0x03001608 ; undefined
 148:	02213a0e 	.inst	0x02213a0e ; undefined
 14c:	0b390b3b 	add	w27, w25, w25, uxtb #2
 150:	00001349 	udf	#4937
 154:	03000d09 	.inst	0x03000d09 ; undefined
 158:	04213a0e 	eor3	z14.d, z14.d, z1.d, z16.d
 15c:	21390b3b 	.inst	0x21390b3b ; undefined
 160:	3813490d 	sttrb	w13, [x8, #-204]
 164:	0a000005 	and	w5, w0, w0
 168:	0803000d 	stxrb	w3, w13, [x0]
 16c:	3b04213a 	.inst	0x3b04213a ; undefined
 170:	0d21390b 	.inst	0x0d21390b ; undefined
 174:	05381349 	ext	z9.b, z9.b, z26.b, #196
 178:	2e0b0000 	ext	v0.8b, v0.8b, v11.8b, #0
 17c:	03193f01 	.inst	0x03193f01 ; undefined
 180:	01213a0e 	.inst	0x01213a0e ; undefined
 184:	0b390b3b 	add	w27, w25, w25, uxtb #2
 188:	13491927 	.inst	0x13491927 ; undefined
 18c:	07120111 	.inst	0x07120111 ; undefined
 190:	197a1840 	.inst	0x197a1840 ; undefined
 194:	00001301 	udf	#4865
 198:	2501110c 	cmpge	p12.b, p4/z, z8.b, #1
 19c:	030b130e 	.inst	0x030b130e ; undefined
 1a0:	111f1b1f 	add	wsp, w24, #0x7c6
 1a4:	10071201 	adr	x1, e3e4 <MAIR_ATTR+0x9fe4>
 1a8:	0d000017 	st1	{v23.b}[0], [x0]
 1ac:	0b0b0024 	add	w4, w1, w11
 1b0:	08030b3e 	stxrb	w3, w30, [x25]
 1b4:	130e0000 	sbfiz	w0, w0, #18, #1
 1b8:	0b0e0301 	add	w1, w24, w14
 1bc:	3b0b3a05 	.inst	0x3b0b3a05 ; undefined
 1c0:	010b390b 	.inst	0x010b390b ; undefined
 1c4:	0f000013 	fdot	v19.2s, v0.8b, v0.4b[0]
 1c8:	193f012e 	.inst	0x193f012e ; undefined
 1cc:	0b3a0e03 	add	w3, w16, w26, uxtb #3
 1d0:	0b390b3b 	add	w27, w25, w25, uxtb #2
 1d4:	13491927 	.inst	0x13491927 ; undefined
 1d8:	07120111 	.inst	0x07120111 ; undefined
 1dc:	197c1840 	.inst	0x197c1840 ; undefined
 1e0:	00001301 	udf	#4865
 1e4:	3f012e10 	.inst	0x3f012e10 ; undefined
 1e8:	3a0e0319 	adcs	w25, w24, w14
 1ec:	390b3b0b 	strb	w11, [x24, #718]
 1f0:	1119270b 	add	w11, w24, #0x649
 1f4:	40071201 	.inst	0x40071201 ; undefined
 1f8:	00197c18 	.inst	0x00197c18 ; undefined
 1fc:	24010000 	cmphs	p0.b, p0/z, z0.b, z1.b
 200:	3e0b0b00 	.inst	0x3e0b0b00 ; undefined
 204:	000e030b 	.inst	0x000e030b ; undefined
 208:	00050200 	.inst	0x00050200 ; undefined
 20c:	00001349 	udf	#4937
 210:	3f012e03 	.inst	0x3f012e03 ; undefined
 214:	3a0e0319 	adcs	w25, w24, w14
 218:	0b3b0121 	add	w1, w9, w27, uxtb
 21c:	27062139 	.inst	0x27062139 ; undefined
 220:	12011119 	and	w25, w8, #0x8000000f
 224:	7c184007 	stur	h7, [x0, #-124]
 228:	00130119 	.inst	0x00130119 ; undefined
 22c:	00160400 	.inst	0x00160400 ; undefined
 230:	213a0e03 	.inst	0x213a0e03 ; undefined
 234:	390b3b02 	strb	w2, [x24, #718]
 238:	13491921 	.inst	0x13491921 ; undefined
 23c:	2e050000 	ext	v0.8b, v0.8b, v5.8b, #0
 240:	03193f01 	.inst	0x03193f01 ; undefined
 244:	03213a0e 	.inst	0x03213a0e ; undefined
 248:	21390b3b 	.inst	0x21390b3b ; undefined
 24c:	3c192706 	str	b6, [x24], #-110
 250:	00130119 	.inst	0x00130119 ; undefined
 254:	00340600 	.inst	0x00340600 ; undefined
 258:	213a0e03 	.inst	0x213a0e03 ; undefined
 25c:	390b3b01 	strb	w1, [x24, #718]
 260:	13490e21 	.inst	0x13490e21 ; undefined
 264:	00001802 	udf	#6146
 268:	11010b07 	add	w7, w24, #0x42
 26c:	00071201 	.inst	0x00071201 ; undefined
 270:	00340800 	.inst	0x00340800 ; undefined
 274:	213a0803 	.inst	0x213a0803 ; undefined
 278:	390b3b01 	strb	w1, [x24, #718]
 27c:	13490e21 	.inst	0x13490e21 ; undefined
 280:	00001802 	udf	#6146
 284:	25011109 	cmpge	p9.b, p4/z, z8.b, #1
 288:	030b130e 	.inst	0x030b130e ; undefined
 28c:	111f1b1f 	add	wsp, w24, #0x7c6
 290:	10071201 	adr	x1, e4d0 <MAIR_ATTR+0xa0d0>
 294:	0a000017 	and	w23, w0, w0
 298:	0b0b0024 	add	w4, w1, w11
 29c:	08030b3e 	stxrb	w3, w30, [x25]
 2a0:	2e0b0000 	ext	v0.8b, v0.8b, v11.8b, #0
 2a4:	03193f01 	.inst	0x03193f01 ; undefined
 2a8:	3b0b3a0e 	.inst	0x3b0b3a0e ; undefined
 2ac:	270b390b 	.inst	0x270b390b ; undefined
 2b0:	3c134919 	.inst	0x3c134919 ; undefined
 2b4:	00130119 	.inst	0x00130119 ; undefined
 2b8:	00260c00 	.inst	0x00260c00 ; undefined
 2bc:	00001349 	udf	#4937
 2c0:	0300050d 	.inst	0x0300050d ; undefined
 2c4:	3b0b3a0e 	.inst	0x3b0b3a0e ; undefined
 2c8:	490b390b 	.inst	0x490b390b ; undefined
 2cc:	00180213 	.inst	0x00180213 ; undefined
 2d0:	000f0e00 	.inst	0x000f0e00 ; undefined
 2d4:	13490b0b 	.inst	0x13490b0b ; undefined
 2d8:	2e0f0000 	ext	v0.8b, v0.8b, v15.8b, #0
 2dc:	03193f00 	.inst	0x03193f00 ; undefined
 2e0:	3b0b3a0e 	.inst	0x3b0b3a0e ; undefined
 2e4:	270b390b 	.inst	0x270b390b ; undefined
 2e8:	11134919 	add	w25, w8, #0x4d2
 2ec:	40071201 	.inst	0x40071201 ; undefined
 2f0:	00197c18 	.inst	0x00197c18 ; undefined
 2f4:	012e1000 	.inst	0x012e1000 ; undefined
 2f8:	0e03193f 	uzp1	v31.8b, v9.8b, v3.8b
 2fc:	0b3b0b3a 	add	w26, w25, w27, uxtb #2
 300:	19270b39 	rcwcas	x7, x25, [x25]
 304:	07120111 	.inst	0x07120111 ; undefined
 308:	197c1840 	.inst	0x197c1840 ; undefined
 30c:	05110000 	mov	z0.b, p1/z, #0
 310:	3a080300 	adcs	w0, w24, w8
 314:	390b3b0b 	strb	w11, [x24, #718]
 318:	0213490b 	.inst	0x0213490b ; undefined
 31c:	00000018 	udf	#24
 320:	03000501 	.inst	0x03000501 ; undefined
 324:	01213a0e 	.inst	0x01213a0e ; undefined
 328:	0b390b3b 	add	w27, w25, w25, uxtb #2
 32c:	18021349 	ldr	w9, 4594 <MAIR_ATTR+0x194>
 330:	34020000 	cbz	w0, 4330 <_binary_init_bin_size+0x3be8>
 334:	3a0e0300 	adcs	w0, w24, w14
 338:	0b3b0121 	add	w1, w9, w27, uxtb
 33c:	13490b39 	.inst	0x13490b39 ; undefined
 340:	00001802 	udf	#6146
 344:	0b002403 	add	w3, w0, w0, lsl #9
 348:	030b3e0b 	.inst	0x030b3e0b ; undefined
 34c:	0400000e 	add	z14.b, p0/m, z14.b, z0.b
 350:	0e03000d 	tbl	v13.8b, {v0.16b}, v3.8b
 354:	0b381349 	add	w9, w26, w24, uxtb #4
 358:	00001934 	udf	#6452
 35c:	03001605 	.inst	0x03001605 ; undefined
 360:	3b0b3a0e 	.inst	0x3b0b3a0e ; undefined
 364:	490b390b 	.inst	0x490b390b ; undefined
 368:	06000013 	.inst	0x06000013 ; undefined
 36c:	0111010b 	.inst	0x0111010b ; undefined
 370:	00000712 	udf	#1810
 374:	03003407 	.inst	0x03003407 ; undefined
 378:	01213a08 	.inst	0x01213a08 ; undefined
 37c:	21390b3b 	.inst	0x21390b3b ; undefined
 380:	0213490e 	.inst	0x0213490e ; undefined
 384:	08000018 	stxrb	w0, w24, [x0]
 388:	13490101 	.inst	0x13490101 ; undefined
 38c:	00001301 	udf	#4865
 390:	49002109 	.inst	0x49002109 ; undefined
 394:	000b2f13 	.inst	0x000b2f13 ; undefined
 398:	000f0a00 	.inst	0x000f0a00 ; undefined
 39c:	4908210b 	.inst	0x4908210b ; undefined
 3a0:	0b000013 	add	w19, w0, w0
 3a4:	0e03012e 	tbl	v14.8b, {v9.16b}, v3.8b
 3a8:	3b01213a 	.inst	0x3b01213a ; undefined
 3ac:	0c21390b 	.inst	0x0c21390b ; undefined
 3b0:	13491927 	.inst	0x13491927 ; undefined
 3b4:	07120111 	.inst	0x07120111 ; undefined
 3b8:	197a1840 	.inst	0x197a1840 ; undefined
 3bc:	00001301 	udf	#4865
 3c0:	2501110c 	cmpge	p12.b, p4/z, z8.b, #1
 3c4:	030b130e 	.inst	0x030b130e ; undefined
 3c8:	111f1b1f 	add	wsp, w24, #0x7c6
 3cc:	10071201 	adr	x1, e60c <MAIR_ATTR+0xa20c>
 3d0:	0d000017 	st1	{v23.b}[0], [x0]
 3d4:	0b0b0024 	add	w4, w1, w11
 3d8:	08030b3e 	stxrb	w3, w30, [x25]
 3dc:	130e0000 	sbfiz	w0, w0, #18, #1
 3e0:	0b0e0301 	add	w1, w24, w14
 3e4:	3b0b3a0b 	.inst	0x3b0b3a0b ; undefined
 3e8:	0013010b 	.inst	0x0013010b ; undefined
 3ec:	000f0f00 	.inst	0x000f0f00 ; undefined
 3f0:	00000b0b 	udf	#2827
 3f4:	3f012e10 	.inst	0x3f012e10 ; undefined
 3f8:	3a0e0319 	adcs	w25, w24, w14
 3fc:	390b3b0b 	strb	w11, [x24, #718]
 400:	3c19270b 	str	b11, [x24], #-110
 404:	00130119 	.inst	0x00130119 ; undefined
 408:	00051100 	.inst	0x00051100 ; undefined
 40c:	00001349 	udf	#4937
 410:	3f012e12 	.inst	0x3f012e12 ; undefined
 414:	3a0e0319 	adcs	w25, w24, w14
 418:	390b3b0b 	strb	w11, [x24, #718]
 41c:	4919270b 	.inst	0x4919270b ; undefined
 420:	12011113 	and	w19, w8, #0x8000000f
 424:	7c184007 	stur	h7, [x0, #-124]
 428:	00130119 	.inst	0x00130119 ; undefined
 42c:	00181300 	.inst	0x00181300 ; undefined
 430:	26140000 	.inst	0x26140000 ; undefined
 434:	00134900 	.inst	0x00134900 ; undefined
 438:	00211500 	.inst	0x00211500 ; undefined
 43c:	052f1349 	ext	z9.b, z9.b, z26.b, #124
 440:	2e160000 	ext	v0.8b, v0.8b, v22.8b, #0
 444:	03193f01 	.inst	0x03193f01 ; undefined
 448:	3b0b3a0e 	.inst	0x3b0b3a0e ; undefined
 44c:	270b390b 	.inst	0x270b390b ; undefined
 450:	12011119 	and	w25, w8, #0x8000000f
 454:	7c184007 	stur	h7, [x0, #-124]
 458:	00130119 	.inst	0x00130119 ; undefined
 45c:	012e1700 	.inst	0x012e1700 ; undefined
 460:	0b3a0e03 	add	w3, w16, w26, uxtb #3
 464:	0b390b3b 	add	w27, w25, w25, uxtb #2
 468:	13491927 	.inst	0x13491927 ; undefined
 46c:	07120111 	.inst	0x07120111 ; undefined
 470:	197c1840 	.inst	0x197c1840 ; undefined
 474:	00001301 	udf	#4865
 478:	03012e18 	.inst	0x03012e18 ; undefined
 47c:	3b0b3a0e 	.inst	0x3b0b3a0e ; undefined
 480:	270b390b 	.inst	0x270b390b ; undefined
 484:	11134919 	add	w25, w8, #0x4d2
 488:	40071201 	.inst	0x40071201 ; undefined
 48c:	00197a18 	.inst	0x00197a18 ; undefined
 490:	24010000 	cmphs	p0.b, p0/z, z0.b, z1.b
 494:	3e0b0b00 	.inst	0x3e0b0b00 ; undefined
 498:	000e030b 	.inst	0x000e030b ; undefined
 49c:	000f0200 	.inst	0x000f0200 ; undefined
 4a0:	4908210b 	.inst	0x4908210b ; undefined
 4a4:	03000013 	.inst	0x03000013 ; undefined
 4a8:	0e030005 	tbl	v5.8b, {v0.16b}, v3.8b
 4ac:	3b01213a 	.inst	0x3b01213a ; undefined
 4b0:	0b390421 	add	w1, w1, w25, uxtb #1
 4b4:	18021349 	ldr	w9, 471c <MAIR_ATTR+0x31c>
 4b8:	11040000 	add	w0, w0, #0x100
 4bc:	130e2501 	sbfiz	w1, w8, #18, #10
 4c0:	1b1f030b 	madd	w11, w24, wzr, w0
 4c4:	1201111f 	and	wsp, w8, #0x8000000f
 4c8:	00171007 	.inst	0x00171007 ; undefined
 4cc:	00240500 	.inst	0x00240500 ; undefined
 4d0:	0b3e0b0b 	add	w11, w24, w30, uxtb #2
 4d4:	00000803 	udf	#2051
 4d8:	03001606 	.inst	0x03001606 ; undefined
 4dc:	3b0b3a0e 	.inst	0x3b0b3a0e ; undefined
 4e0:	490b390b 	.inst	0x490b390b ; undefined
 4e4:	07000013 	.inst	0x07000013 ; undefined
 4e8:	193f012e 	.inst	0x193f012e ; undefined
 4ec:	0b3a0e03 	add	w3, w16, w26, uxtb #3
 4f0:	0b390b3b 	add	w27, w25, w25, uxtb #2
 4f4:	13491927 	.inst	0x13491927 ; undefined
 4f8:	1301193c 	sbfx	w28, w9, #1, #6
 4fc:	05080000 	.inst	0x05080000 ; undefined
 500:	00134900 	.inst	0x00134900 ; undefined
 504:	00180900 	.inst	0x00180900 ; undefined
 508:	260a0000 	.inst	0x260a0000 ; undefined
 50c:	00134900 	.inst	0x00134900 ; undefined
 510:	012e0b00 	.inst	0x012e0b00 ; undefined
 514:	0e03193f 	uzp1	v31.8b, v9.8b, v3.8b
 518:	0b3b0b3a 	add	w26, w25, w27, uxtb #2
 51c:	19270b39 	rcwcas	x7, x25, [x25]
 520:	07120111 	.inst	0x07120111 ; undefined
 524:	197c1840 	.inst	0x197c1840 ; undefined
 528:	00001301 	udf	#4865
 52c:	00110100 	.inst	0x00110100 ; undefined
 530:	01111710 	.inst	0x01111710 ; undefined
 534:	0e030f12 	dup	v18.8b, w24
 538:	0e250e1b 	sqadd	v27.8b, v16.8b, v5.8b
 53c:	00000513 	udf	#1299
 540:	000d0100 	.inst	0x000d0100 ; undefined
 544:	0b3a0803 	add	w3, w0, w26, uxtb #2
 548:	0b390b3b 	add	w27, w25, w25, uxtb #2
 54c:	0b381349 	add	w9, w26, w24, uxtb #4
 550:	0d020000 	.inst	0x0d020000 ; undefined
 554:	3a0e0300 	adcs	w0, w24, w14
 558:	390b3b0b 	strb	w11, [x24, #718]
 55c:	3813490b 	sttrb	w11, [x8, #-204]
 560:	0300000b 	.inst	0x0300000b ; undefined
 564:	13490005 	.inst	0x13490005 ; undefined
 568:	24040000 	cmphs	p0.b, p0/z, z0.b, z4.b
 56c:	3e0b0b00 	.inst	0x3e0b0b00 ; undefined
 570:	000e030b 	.inst	0x000e030b ; undefined
 574:	000f0500 	.inst	0x000f0500 ; undefined
 578:	4908210b 	.inst	0x4908210b ; undefined
 57c:	06000013 	.inst	0x06000013 ; undefined
 580:	0e030034 	tbl	v20.8b, {v1.16b}, v3.8b
 584:	3b01213a 	.inst	0x3b01213a ; undefined
 588:	490b390b 	.inst	0x490b390b ; undefined
 58c:	00180213 	.inst	0x00180213 ; undefined
 590:	012e0700 	.inst	0x012e0700 ; undefined
 594:	0e03193f 	uzp1	v31.8b, v9.8b, v3.8b
 598:	0b3b0b3a 	add	w26, w25, w27, uxtb #2
 59c:	27062139 	.inst	0x27062139 ; undefined
 5a0:	01193c19 	.inst	0x01193c19 ; undefined
 5a4:	08000013 	stxrb	w0, w19, [x0]
 5a8:	0e030113 	tbl	v19.8b, {v8.16b}, v3.8b
 5ac:	0b3a0b0b 	add	w11, w24, w26, uxtb #2
 5b0:	21390b3b 	.inst	0x21390b3b ; undefined
 5b4:	00130108 	.inst	0x00130108 ; undefined
 5b8:	00340900 	.inst	0x00340900 ; undefined
 5bc:	213a0803 	.inst	0x213a0803 ; undefined
 5c0:	390b3b01 	strb	w1, [x24, #718]
 5c4:	0213490b 	.inst	0x0213490b ; undefined
 5c8:	0a000018 	and	w24, w0, w0
 5cc:	0e030016 	tbl	v22.8b, {v0.16b}, v3.8b
 5d0:	3b02213a 	.inst	0x3b02213a ; undefined
 5d4:	490b390b 	.inst	0x490b390b ; undefined
 5d8:	0b000013 	add	w19, w0, w0
 5dc:	193f002e 	.inst	0x193f002e ; undefined
 5e0:	0b3a0e03 	add	w3, w16, w26, uxtb #3
 5e4:	21390b3b 	.inst	0x21390b3b ; undefined
 5e8:	3c192706 	str	b6, [x24], #-110
 5ec:	0c000019 	st4	{v25.8b-v28.8b}, [x0]
 5f0:	193f002e 	.inst	0x193f002e ; undefined
 5f4:	0b3a0e03 	add	w3, w16, w26, uxtb #3
 5f8:	0b390b3b 	add	w27, w25, w25, uxtb #2
 5fc:	13491927 	.inst	0x13491927 ; undefined
 600:	0000193c 	udf	#6460
 604:	03000d0d 	.inst	0x03000d0d ; undefined
 608:	04213a0e 	eor3	z14.d, z14.d, z1.d, z16.d
 60c:	21390b3b 	.inst	0x21390b3b ; undefined
 610:	3813490d 	sttrb	w13, [x8, #-204]
 614:	0e000005 	tbl	v5.8b, {v0.16b}, v0.8b
 618:	0803000d 	stxrb	w3, w13, [x0]
 61c:	3b04213a 	.inst	0x3b04213a ; undefined
 620:	0d21390b 	.inst	0x0d21390b ; undefined
 624:	05381349 	ext	z9.b, z9.b, z26.b, #196
 628:	2e0f0000 	ext	v0.8b, v0.8b, v15.8b, #0
 62c:	03193f01 	.inst	0x03193f01 ; undefined
 630:	3b0b3a0e 	.inst	0x3b0b3a0e ; undefined
 634:	270b390b 	.inst	0x270b390b ; undefined
 638:	3c134919 	.inst	0x3c134919 ; undefined
 63c:	00130119 	.inst	0x00130119 ; undefined
 640:	012e1000 	.inst	0x012e1000 ; undefined
 644:	0e03193f 	uzp1	v31.8b, v9.8b, v3.8b
 648:	3b01213a 	.inst	0x3b01213a ; undefined
 64c:	0621390b 	.inst	0x0621390b ; undefined
 650:	01111927 	.inst	0x01111927 ; undefined
 654:	18400712 	ldr	w18, 80734 <MAIR_ATTR+0x7c334>
 658:	1301197c 	sbfx	w28, w11, #1, #6
 65c:	0b110000 	add	w0, w0, w17
 660:	12011101 	and	w1, w8, #0x8000000f
 664:	12000007 	and	w7, w0, #0x1
 668:	193f002e 	.inst	0x193f002e ; undefined
 66c:	213a0e03 	.inst	0x213a0e03 ; undefined
 670:	390b3b01 	strb	w1, [x24, #718]
 674:	19270621 	ldtadd	w7, w1, [x17]
 678:	07120111 	.inst	0x07120111 ; undefined
 67c:	197c1840 	.inst	0x197c1840 ; undefined
 680:	11130000 	add	w0, w0, #0x4c0
 684:	130e2501 	sbfiz	w1, w8, #18, #10
 688:	1b1f030b 	madd	w11, w24, wzr, w0
 68c:	1201111f 	and	wsp, w8, #0x8000000f
 690:	00171007 	.inst	0x00171007 ; undefined
 694:	00241400 	.inst	0x00241400 ; undefined
 698:	0b3e0b0b 	add	w11, w24, w30, uxtb #2
 69c:	00000803 	udf	#2051
 6a0:	03011315 	.inst	0x03011315 ; undefined
 6a4:	3a050b0e 	.inst	0x3a050b0e ; undefined
 6a8:	390b3b0b 	strb	w11, [x24, #718]
 6ac:	0013010b 	.inst	0x0013010b ; undefined
 6b0:	00181600 	.inst	0x00181600 ; undefined
 6b4:	26170000 	.inst	0x26170000 ; undefined
 6b8:	00134900 	.inst	0x00134900 ; undefined
 6bc:	00051800 	.inst	0x00051800 ; undefined
 6c0:	0b3a0803 	add	w3, w0, w26, uxtb #2
 6c4:	0b390b3b 	add	w27, w25, w25, uxtb #2
 6c8:	18021349 	ldr	w9, 4930 <MAIR_ATTR+0x530>
 6cc:	2e190000 	ext	v0.8b, v0.8b, v25.8b, #0
 6d0:	3a0e0300 	adcs	w0, w24, w14
 6d4:	390b3b0b 	strb	w11, [x24, #718]
 6d8:	4919270b 	.inst	0x4919270b ; undefined
 6dc:	12011113 	and	w19, w8, #0x8000000f
 6e0:	7c184007 	stur	h7, [x0, #-124]
 6e4:	1a000019 	adc	w25, w0, w0
 6e8:	0e03012e 	tbl	v14.8b, {v9.16b}, v3.8b
 6ec:	0b3b0b3a 	add	w26, w25, w27, uxtb #2
 6f0:	19270b39 	rcwcas	x7, x25, [x25]
 6f4:	07120111 	.inst	0x07120111 ; undefined
 6f8:	197c1840 	.inst	0x197c1840 ; undefined
 6fc:	00001301 	udf	#4865
 700:	3f002e1b 	.inst	0x3f002e1b ; undefined
 704:	3a0e0319 	adcs	w25, w24, w14
 708:	390b3b0b 	strb	w11, [x24, #718]
 70c:	4919270b 	.inst	0x4919270b ; undefined
 710:	12011113 	and	w19, w8, #0x8000000f
 714:	7a184007 	.inst	0x7a184007 ; undefined
 718:	00000019 	udf	#25
 71c:	10001101 	adr	x1, 93c <_binary_init_bin_size+0x1f4>
 720:	12011117 	and	w23, w8, #0x8000000f
 724:	1b0e030f 	madd	w15, w24, w14, w0
 728:	130e250e 	sbfiz	w14, w8, #18, #10
 72c:	00000005 	udf	#5
 730:	03000501 	.inst	0x03000501 ; undefined
 734:	01213a08 	.inst	0x01213a08 ; undefined
 738:	0b390b3b 	add	w27, w25, w25, uxtb #2
 73c:	18021349 	ldr	w9, 49a4 <MAIR_ATTR+0x5a4>
 740:	34020000 	cbz	w0, 4740 <MAIR_ATTR+0x340>
 744:	3a0e0300 	adcs	w0, w24, w14
 748:	0b3b0121 	add	w1, w9, w27, uxtb
 74c:	13490b39 	.inst	0x13490b39 ; undefined
 750:	00001802 	udf	#6146
 754:	49000503 	.inst	0x49000503 ; undefined
 758:	04000013 	add	z19.b, p0/m, z19.b, z0.b
 75c:	08030034 	stxrb	w3, w20, [x1]
 760:	3b01213a 	.inst	0x3b01213a ; undefined
 764:	490b390b 	.inst	0x490b390b ; undefined
 768:	00180213 	.inst	0x00180213 ; undefined
 76c:	00240500 	.inst	0x00240500 ; undefined
 770:	0b3e0b0b 	add	w11, w24, w30, uxtb #2
 774:	00000e03 	udf	#3587
 778:	03000506 	.inst	0x03000506 ; undefined
 77c:	01213a0e 	.inst	0x01213a0e ; undefined
 780:	0b390b3b 	add	w27, w25, w25, uxtb #2
 784:	18021349 	ldr	w9, 49ec <MAIR_ATTR+0x5ec>
 788:	2e070000 	ext	v0.8b, v0.8b, v7.8b, #0
 78c:	03193f01 	.inst	0x03193f01 ; undefined
 790:	01213a0e 	.inst	0x01213a0e ; undefined
 794:	21390b3b 	.inst	0x21390b3b ; undefined
 798:	11192706 	add	w6, w24, #0x649
 79c:	40071201 	.inst	0x40071201 ; undefined
 7a0:	01197c18 	.inst	0x01197c18 ; undefined
 7a4:	08000013 	stxrb	w0, w19, [x0]
 7a8:	210b000f 	.inst	0x210b000f ; undefined
 7ac:	00134908 	.inst	0x00134908 ; undefined
 7b0:	012e0900 	.inst	0x012e0900 ; undefined
 7b4:	0e03193f 	uzp1	v31.8b, v9.8b, v3.8b
 7b8:	0b3b0b3a 	add	w26, w25, w27, uxtb #2
 7bc:	27062139 	.inst	0x27062139 ; undefined
 7c0:	01193c19 	.inst	0x01193c19 ; undefined
 7c4:	0a000013 	and	w19, w0, w0
 7c8:	0111010b 	.inst	0x0111010b ; undefined
 7cc:	00000712 	udf	#1810
 7d0:	0300340b 	.inst	0x0300340b ; undefined
 7d4:	01213a0e 	.inst	0x01213a0e ; undefined
 7d8:	21390b3b 	.inst	0x21390b3b ; undefined
 7dc:	3f13490d 	.inst	0x3f13490d ; undefined
 7e0:	00193c19 	.inst	0x00193c19 ; undefined
 7e4:	012e0c00 	.inst	0x012e0c00 ; undefined
 7e8:	0e03193f 	uzp1	v31.8b, v9.8b, v3.8b
 7ec:	3b01213a 	.inst	0x3b01213a ; undefined
 7f0:	270b390b 	.inst	0x270b390b ; undefined
 7f4:	11134919 	add	w25, w8, #0x4d2
 7f8:	40071201 	.inst	0x40071201 ; undefined
 7fc:	01197c18 	.inst	0x01197c18 ; undefined
 800:	0d000013 	st1	{v19.b}[0], [x0]
 804:	0e03012e 	tbl	v14.8b, {v9.16b}, v3.8b
 808:	3b01213a 	.inst	0x3b01213a ; undefined
 80c:	0d21390b 	.inst	0x0d21390b ; undefined
 810:	01111927 	.inst	0x01111927 ; undefined
 814:	18400712 	ldr	w18, 808f4 <MAIR_ATTR+0x7c4f4>
 818:	1301197c 	sbfx	w28, w11, #1, #6
 81c:	2e0e0000 	ext	v0.8b, v0.8b, v14.8b, #0
 820:	03193f01 	.inst	0x03193f01 ; undefined
 824:	3b0b3a0e 	.inst	0x3b0b3a0e ; undefined
 828:	0521390b 	.inst	0x0521390b ; undefined
 82c:	13491927 	.inst	0x13491927 ; undefined
 830:	1301193c 	sbfx	w28, w9, #1, #6
 834:	2e0f0000 	ext	v0.8b, v0.8b, v15.8b, #0
 838:	3a0e0301 	adcs	w1, w24, w14
 83c:	0b3b0121 	add	w1, w9, w27, uxtb
 840:	27122139 	.inst	0x27122139 ; undefined
 844:	11134919 	add	w25, w8, #0x4d2
 848:	40071201 	.inst	0x40071201 ; undefined
 84c:	01197c18 	.inst	0x01197c18 ; undefined
 850:	10000013 	adr	x19, 850 <_binary_init_bin_size+0x108>
 854:	0e250111 	saddl	v17.8h, v8.8b, v5.8b
 858:	1f030b13 	fmadd	s19, s24, s3, s2
 85c:	01111f1b 	.inst	0x01111f1b ; undefined
 860:	17100712 	b	fffffffffc4024a8 <FS_BASE+0xffffcc4024a8>
 864:	24110000 	cmphs	p0.b, p0/z, z0.b, z17.b
 868:	3e0b0b00 	.inst	0x3e0b0b00 ; undefined
 86c:	0008030b 	.inst	0x0008030b ; undefined
 870:	00161200 	.inst	0x00161200 ; undefined
 874:	0b3a0e03 	add	w3, w16, w26, uxtb #3
 878:	0b390b3b 	add	w27, w25, w25, uxtb #2
 87c:	00001349 	udf	#4937
 880:	03011313 	.inst	0x03011313 ; undefined
 884:	3a0b0b0e 	.inst	0x3a0b0b0e ; undefined
 888:	390b3b0b 	strb	w11, [x24, #718]
 88c:	0013010b 	.inst	0x0013010b ; undefined
 890:	000d1400 	.inst	0x000d1400 ; undefined
 894:	0b3a0e03 	add	w3, w16, w26, uxtb #3
 898:	0b390b3b 	add	w27, w25, w25, uxtb #2
 89c:	0b381349 	add	w9, w26, w24, uxtb #4
 8a0:	01150000 	.inst	0x01150000 ; undefined
 8a4:	01134901 	.inst	0x01134901 ; undefined
 8a8:	16000013 	b	fffffffff80008f4 <FS_BASE+0xffffc80008f4>
 8ac:	00000021 	udf	#33
 8b0:	49002617 	.inst	0x49002617 ; undefined
 8b4:	18000013 	ldr	w19, 8b4 <_binary_init_bin_size+0x16c>
 8b8:	0e030034 	tbl	v20.8b, {v1.16b}, v3.8b
 8bc:	0b3b0b3a 	add	w26, w25, w27, uxtb #2
 8c0:	13490b39 	.inst	0x13490b39 ; undefined
 8c4:	1802193f 	ldr	wzr, 4be8 <MAIR_ATTR+0x7e8>
 8c8:	34190000 	cbz	w0, 328c8 <MAIR_ATTR+0x2e4c8>
 8cc:	3a080300 	adcs	w0, w24, w8
 8d0:	390b3b0b 	strb	w11, [x24, #718]
 8d4:	3f13490b 	.inst	0x3f13490b ; undefined
 8d8:	00193c19 	.inst	0x00193c19 ; undefined
 8dc:	000f1a00 	.inst	0x000f1a00 ; undefined
 8e0:	00000b0b 	udf	#2827
 8e4:	0000181b 	udf	#6171
 8e8:	002e1c00 	.inst	0x002e1c00 ; undefined
 8ec:	0e03193f 	uzp1	v31.8b, v9.8b, v3.8b
 8f0:	0b3b0b3a 	add	w26, w25, w27, uxtb #2
 8f4:	19270b39 	rcwcas	x7, x25, [x25]
 8f8:	07120111 	.inst	0x07120111 ; undefined
 8fc:	197c1840 	.inst	0x197c1840 ; undefined
 900:	2e1d0000 	ext	v0.8b, v0.8b, v29.8b, #0
 904:	3a0e0301 	adcs	w1, w24, w14
 908:	390b3b0b 	strb	w11, [x24, #718]
 90c:	1119270b 	add	w11, w24, #0x649
 910:	40071201 	.inst	0x40071201 ; undefined
 914:	00197c18 	.inst	0x00197c18 ; undefined
 918:	0d010000 	.inst	0x0d010000 ; undefined
 91c:	3a0e0300 	adcs	w0, w24, w14
 920:	0b3b0321 	add	w1, w25, w27, uxtb
 924:	13490b39 	.inst	0x13490b39 ; undefined
 928:	00000b38 	udf	#2872
 92c:	03003402 	.inst	0x03003402 ; undefined
 930:	01213a0e 	.inst	0x01213a0e ; undefined
 934:	0b390b3b 	add	w27, w25, w25, uxtb #2
 938:	18021349 	ldr	w9, 4ba0 <MAIR_ATTR+0x7a0>
 93c:	05030000 	orr	z0.d, z0.d, #0x100000000
 940:	3a0e0300 	adcs	w0, w24, w14
 944:	0b3b0121 	add	w1, w9, w27, uxtb
 948:	13490b39 	.inst	0x13490b39 ; undefined
 94c:	00001802 	udf	#6146
 950:	03003404 	.inst	0x03003404 ; undefined
 954:	01213a08 	.inst	0x01213a08 ; undefined
 958:	0b390b3b 	add	w27, w25, w25, uxtb #2
 95c:	18021349 	ldr	w9, 4bc4 <MAIR_ATTR+0x7c4>
 960:	2e050000 	ext	v0.8b, v0.8b, v5.8b, #0
 964:	3a0e0301 	adcs	w1, w24, w14
 968:	0b3b0121 	add	w1, w9, w27, uxtb
 96c:	19270b39 	rcwcas	x7, x25, [x25]
 970:	01111349 	.inst	0x01111349 ; undefined
 974:	18400712 	ldr	w18, 80a54 <MAIR_ATTR+0x7c654>
 978:	1301197c 	sbfx	w28, w11, #1, #6
 97c:	24060000 	cmphs	p0.b, p0/z, z0.b, z6.b
 980:	3e0b0b00 	.inst	0x3e0b0b00 ; undefined
 984:	000e030b 	.inst	0x000e030b ; undefined
 988:	00050700 	.inst	0x00050700 ; undefined
 98c:	00001349 	udf	#4937
 990:	0b000f08 	add	w8, w24, w0, lsl #3
 994:	13490821 	.inst	0x13490821 ; undefined
 998:	01090000 	.inst	0x01090000 ; undefined
 99c:	01134901 	.inst	0x01134901 ; undefined
 9a0:	0a000013 	and	w19, w0, w0
 9a4:	13490021 	.inst	0x13490021 ; undefined
 9a8:	00000b2f 	udf	#2863
 9ac:	0300160b 	.inst	0x0300160b ; undefined
 9b0:	02213a0e 	.inst	0x02213a0e ; undefined
 9b4:	0b390b3b 	add	w27, w25, w25, uxtb #2
 9b8:	00001349 	udf	#4937
 9bc:	03000d0c 	.inst	0x03000d0c ; undefined
 9c0:	03213a08 	.inst	0x03213a08 ; undefined
 9c4:	21390b3b 	.inst	0x21390b3b ; undefined
 9c8:	3813490d 	sttrb	w13, [x8, #-204]
 9cc:	0d00000b 	st1	{v11.b}[0], [x0]
 9d0:	193f012e 	.inst	0x193f012e ; undefined
 9d4:	0b3a0e03 	add	w3, w16, w26, uxtb #3
 9d8:	21390b3b 	.inst	0x21390b3b ; undefined
 9dc:	49192705 	.inst	0x49192705 ; undefined
 9e0:	01193c13 	.inst	0x01193c13 ; undefined
 9e4:	0e000013 	tbl	v19.8b, {v0.16b}, v0.8b
 9e8:	193f012e 	.inst	0x193f012e ; undefined
 9ec:	0b3a0e03 	add	w3, w16, w26, uxtb #3
 9f0:	21390b3b 	.inst	0x21390b3b ; undefined
 9f4:	3c192706 	str	b6, [x24], #-110
 9f8:	00130119 	.inst	0x00130119 ; undefined
 9fc:	010b0f00 	.inst	0x010b0f00 ; undefined
 a00:	07120111 	.inst	0x07120111 ; undefined
 a04:	05100000 	mov	z0.b, p0/z, #0
 a08:	3a080300 	adcs	w0, w24, w8
 a0c:	0b3b0121 	add	w1, w9, w27, uxtb
 a10:	13490b39 	.inst	0x13490b39 ; undefined
 a14:	00001802 	udf	#6146
 a18:	25011111 	cmpgt	p1.b, p4/z, z8.b, #1
 a1c:	030b130e 	.inst	0x030b130e ; undefined
 a20:	111f1b1f 	add	wsp, w24, #0x7c6
 a24:	10071201 	adr	x1, ec64 <MAIR_ATTR+0xa864>
 a28:	12000017 	and	w23, w0, #0x1
 a2c:	0b0b0024 	add	w4, w1, w11
 a30:	08030b3e 	stxrb	w3, w30, [x25]
 a34:	13130000 	sbfiz	w0, w0, #13, #1
 a38:	0b080301 	add	w1, w24, w8
 a3c:	3b0b3a0b 	.inst	0x3b0b3a0b ; undefined
 a40:	010b390b 	.inst	0x010b390b ; undefined
 a44:	14000013 	b	a90 <_binary_init_bin_size+0x348>
 a48:	0e030113 	tbl	v19.8b, {v8.16b}, v3.8b
 a4c:	0b3a0b0b 	add	w11, w24, w26, uxtb #2
 a50:	0b390b3b 	add	w27, w25, w25, uxtb #2
 a54:	00001301 	udf	#4865
 a58:	00001815 	udf	#6165
 a5c:	00261600 	.inst	0x00261600 ; undefined
 a60:	00001349 	udf	#4937
 a64:	0b000f17 	add	w23, w24, w0, lsl #3
 a68:	1800000b 	ldr	w11, a68 <_binary_init_bin_size+0x320>
 a6c:	193f012e 	.inst	0x193f012e ; undefined
 a70:	0b3a0e03 	add	w3, w16, w26, uxtb #3
 a74:	0b390b3b 	add	w27, w25, w25, uxtb #2
 a78:	01111927 	.inst	0x01111927 ; undefined
 a7c:	18400712 	ldr	w18, 80b5c <MAIR_ATTR+0x7c75c>
 a80:	1301197c 	sbfx	w28, w11, #1, #6
 a84:	2e190000 	ext	v0.8b, v0.8b, v25.8b, #0
 a88:	03193f01 	.inst	0x03193f01 ; undefined
 a8c:	3b0b3a0e 	.inst	0x3b0b3a0e ; undefined
 a90:	270b390b 	.inst	0x270b390b ; undefined
 a94:	11134919 	add	w25, w8, #0x4d2
 a98:	40071201 	.inst	0x40071201 ; undefined
 a9c:	01197c18 	.inst	0x01197c18 ; undefined
 aa0:	1a000013 	adc	w19, w0, w0
 aa4:	0e03012e 	tbl	v14.8b, {v9.16b}, v3.8b
 aa8:	0b3b0b3a 	add	w26, w25, w27, uxtb #2
 aac:	19270b39 	rcwcas	x7, x25, [x25]
 ab0:	01111349 	.inst	0x01111349 ; undefined
 ab4:	18400712 	ldr	w18, 80b94 <MAIR_ATTR+0x7c794>
 ab8:	1301197a 	sbfx	w26, w11, #1, #6
 abc:	2e1b0000 	ext	v0.8b, v0.8b, v27.8b, #0
 ac0:	3a0e0301 	adcs	w1, w24, w14
 ac4:	390b3b0b 	strb	w11, [x24, #718]
 ac8:	4919270b 	.inst	0x4919270b ; undefined
 acc:	12011113 	and	w19, w8, #0x8000000f
 ad0:	7a184007 	.inst	0x7a184007 ; undefined
 ad4:	00000019 	udf	#25
 ad8:	03000d01 	.inst	0x03000d01 ; undefined
 adc:	3b0b3a08 	.inst	0x3b0b3a08 ; undefined
 ae0:	490b390b 	.inst	0x490b390b ; undefined
 ae4:	000b3813 	.inst	0x000b3813 ; undefined
 ae8:	00340200 	.inst	0x00340200 ; undefined
 aec:	213a0e03 	.inst	0x213a0e03 ; undefined
 af0:	39053b01 	strb	w1, [x24, #334]
 af4:	0213490b 	.inst	0x0213490b ; undefined
 af8:	03000018 	.inst	0x03000018 ; undefined
 afc:	13490005 	.inst	0x13490005 ; undefined
 b00:	34040000 	cbz	w0, 8b00 <MAIR_ATTR+0x4700>
 b04:	3a0e0300 	adcs	w0, w24, w14
 b08:	0b3b0121 	add	w1, w9, w27, uxtb
 b0c:	13490b39 	.inst	0x13490b39 ; undefined
 b10:	00001802 	udf	#6146
 b14:	03000d05 	.inst	0x03000d05 ; undefined
 b18:	3b0b3a0e 	.inst	0x3b0b3a0e ; undefined
 b1c:	490b390b 	.inst	0x490b390b ; undefined
 b20:	000b3813 	.inst	0x000b3813 ; undefined
 b24:	000f0600 	.inst	0x000f0600 ; undefined
 b28:	4908210b 	.inst	0x4908210b ; undefined
 b2c:	07000013 	.inst	0x07000013 ; undefined
 b30:	0b0b0024 	add	w4, w1, w11
 b34:	0e030b3e 	.inst	0x0e030b3e ; undefined
 b38:	2e080000 	ext	v0.8b, v0.8b, v8.8b, #0
 b3c:	03193f01 	.inst	0x03193f01 ; undefined
 b40:	01213a0e 	.inst	0x01213a0e ; undefined
 b44:	0b39053b 	add	w27, w9, w25, uxtb #1
 b48:	01111927 	.inst	0x01111927 ; undefined
 b4c:	18400712 	ldr	w18, 80c2c <MAIR_ATTR+0x7c82c>
 b50:	1301197c 	sbfx	w28, w11, #1, #6
 b54:	2e090000 	ext	v0.8b, v0.8b, v9.8b, #0
 b58:	03193f01 	.inst	0x03193f01 ; undefined
 b5c:	3b0b3a0e 	.inst	0x3b0b3a0e ; undefined
 b60:	0621390b 	.inst	0x0621390b ; undefined
 b64:	193c1927 	.inst	0x193c1927 ; undefined
 b68:	00001301 	udf	#4865
 b6c:	0301130a 	.inst	0x0301130a ; undefined
 b70:	3a0b0b0e 	.inst	0x3a0b0b0e ; undefined
 b74:	390b3b0b 	strb	w11, [x24, #718]
 b78:	13010821 	sbfx	w1, w1, #1, #2
 b7c:	2e0b0000 	ext	v0.8b, v0.8b, v11.8b, #0
 b80:	03193f01 	.inst	0x03193f01 ; undefined
 b84:	3b0b3a0e 	.inst	0x3b0b3a0e ; undefined
 b88:	270b390b 	.inst	0x270b390b ; undefined
 b8c:	3c134919 	.inst	0x3c134919 ; undefined
 b90:	00130119 	.inst	0x00130119 ; undefined
 b94:	00050c00 	.inst	0x00050c00 ; undefined
 b98:	213a0e03 	.inst	0x213a0e03 ; undefined
 b9c:	39053b01 	strb	w1, [x24, #334]
 ba0:	0213490b 	.inst	0x0213490b ; undefined
 ba4:	0d000018 	st1	{v24.b}[0], [x0]
 ba8:	0e030034 	tbl	v20.8b, {v1.16b}, v3.8b
 bac:	3b01213a 	.inst	0x3b01213a ; undefined
 bb0:	490b390b 	.inst	0x490b390b ; undefined
 bb4:	0e000013 	tbl	v19.8b, {v0.16b}, v0.8b
 bb8:	08030005 	stxrb	w3, w5, [x0]
 bbc:	3b01213a 	.inst	0x3b01213a ; undefined
 bc0:	490b3905 	.inst	0x490b3905 ; undefined
 bc4:	00180213 	.inst	0x00180213 ; undefined
 bc8:	00050f00 	.inst	0x00050f00 ; undefined
 bcc:	213a0803 	.inst	0x213a0803 ; undefined
 bd0:	390b3b01 	strb	w1, [x24, #718]
 bd4:	0213490b 	.inst	0x0213490b ; undefined
 bd8:	10000018 	adr	x24, bd8 <_binary_init_bin_size+0x490>
 bdc:	0e030016 	tbl	v22.8b, {v0.16b}, v3.8b
 be0:	3b02213a 	.inst	0x3b02213a ; undefined
 be4:	490b390b 	.inst	0x490b390b ; undefined
 be8:	11000013 	add	w19, w0, #0x0
 bec:	0e03000d 	tbl	v13.8b, {v0.16b}, v3.8b
 bf0:	3b03213a 	.inst	0x3b03213a ; undefined
 bf4:	0d21390b 	.inst	0x0d21390b ; undefined
 bf8:	05381349 	ext	z9.b, z9.b, z26.b, #196
 bfc:	0d120000 	.inst	0x0d120000 ; undefined
 c00:	3a080300 	adcs	w0, w24, w8
 c04:	0b3b0321 	add	w1, w25, w27, uxtb
 c08:	490d2139 	.inst	0x490d2139 ; undefined
 c0c:	00053813 	.inst	0x00053813 ; undefined
 c10:	00341300 	.inst	0x00341300 ; undefined
 c14:	0b3a0e03 	add	w3, w16, w26, uxtb #3
 c18:	0b390b3b 	add	w27, w25, w25, uxtb #2
 c1c:	193f1349 	ldclrp	x9, xzr, [x26]
 c20:	0000193c 	udf	#6460
 c24:	03003414 	.inst	0x03003414 ; undefined
 c28:	01213a08 	.inst	0x01213a08 ; undefined
 c2c:	0b390b3b 	add	w27, w25, w25, uxtb #2
 c30:	18021349 	ldr	w9, 4e98 <MAIR_ATTR+0xa98>
 c34:	34150000 	cbz	w0, 2ac34 <MAIR_ATTR+0x26834>
 c38:	3a080300 	adcs	w0, w24, w8
 c3c:	053b0121 	ext	z1.b, z1.b, z9.b, #216
 c40:	13490b39 	.inst	0x13490b39 ; undefined
 c44:	00001802 	udf	#6146
 c48:	3f002e16 	.inst	0x3f002e16 ; undefined
 c4c:	3a0e0319 	adcs	w25, w24, w14
 c50:	053b0121 	ext	z1.b, z1.b, z9.b, #216
 c54:	27062139 	.inst	0x27062139 ; undefined
 c58:	12011119 	and	w25, w8, #0x8000000f
 c5c:	7c184007 	stur	h7, [x0, #-124]
 c60:	17000019 	b	fffffffffc000cc4 <FS_BASE+0xffffcc000cc4>
 c64:	193f012e 	.inst	0x193f012e ; undefined
 c68:	213a0e03 	.inst	0x213a0e03 ; undefined
 c6c:	390b3b01 	strb	w1, [x24, #718]
 c70:	1119270b 	add	w11, w24, #0x649
 c74:	40071201 	.inst	0x40071201 ; undefined
 c78:	01197c18 	.inst	0x01197c18 ; undefined
 c7c:	18000013 	ldr	w19, c7c <_binary_init_bin_size+0x534>
 c80:	0e03012e 	tbl	v14.8b, {v9.16b}, v3.8b
 c84:	3b01213a 	.inst	0x3b01213a ; undefined
 c88:	0d21390b 	.inst	0x0d21390b ; undefined
 c8c:	01111927 	.inst	0x01111927 ; undefined
 c90:	18400712 	ldr	w18, 80d70 <MAIR_ATTR+0x7c970>
 c94:	1301197c 	sbfx	w28, w11, #1, #6
 c98:	2e190000 	ext	v0.8b, v0.8b, v25.8b, #0
 c9c:	3a0e0301 	adcs	w1, w24, w14
 ca0:	0b3b0121 	add	w1, w9, w27, uxtb
 ca4:	27182139 	.inst	0x27182139 ; undefined
 ca8:	11134919 	add	w25, w8, #0x4d2
 cac:	40071201 	.inst	0x40071201 ; undefined
 cb0:	01197c18 	.inst	0x01197c18 ; undefined
 cb4:	1a000013 	adc	w19, w0, w0
 cb8:	0e250111 	saddl	v17.8h, v8.8b, v5.8b
 cbc:	1f030b13 	fmadd	s19, s24, s3, s2
 cc0:	01111f1b 	.inst	0x01111f1b ; undefined
 cc4:	17100712 	b	fffffffffc40290c <FS_BASE+0xffffcc40290c>
 cc8:	241b0000 	cmphs	p0.b, p0/z, z0.b, z27.b
 ccc:	3e0b0b00 	.inst	0x3e0b0b00 ; undefined
 cd0:	0008030b 	.inst	0x0008030b ; undefined
 cd4:	01131c00 	.inst	0x01131c00 ; undefined
 cd8:	050b0e03 	.inst	0x050b0e03 ; undefined
 cdc:	0b3b0b3a 	add	w26, w25, w27, uxtb #2
 ce0:	13010b39 	sbfx	w25, w25, #1, #2
 ce4:	341d0000 	cbz	w0, 3ace4 <MAIR_ATTR+0x368e4>
 ce8:	3a134700 	.inst	0x3a134700 ; undefined
 cec:	390b3b0b 	strb	w11, [x24, #718]
 cf0:	0018020b 	.inst	0x0018020b ; undefined
 cf4:	01011e00 	.inst	0x01011e00 ; undefined
 cf8:	13011349 	sbfx	w9, w26, #1, #4
 cfc:	211f0000 	.inst	0x211f0000 ; undefined
 d00:	2f134900 	.inst	0x2f134900 ; undefined
 d04:	2000000b 	.inst	0x2000000b ; undefined
 d08:	193f012e 	.inst	0x193f012e ; undefined
 d0c:	0b3a0e03 	add	w3, w16, w26, uxtb #3
 d10:	0b390b3b 	add	w27, w25, w25, uxtb #2
 d14:	01871927 	.inst	0x01871927 ; undefined
 d18:	01193c19 	.inst	0x01193c19 ; undefined
 d1c:	21000013 	.inst	0x21000013 ; undefined
 d20:	13490026 	.inst	0x13490026 ; undefined
 d24:	2e220000 	uaddl	v0.8h, v0.8b, v2.8b
 d28:	03193f00 	.inst	0x03193f00 ; undefined
 d2c:	3b0b3a0e 	.inst	0x3b0b3a0e ; undefined
 d30:	270b390b 	.inst	0x270b390b ; undefined
 d34:	00193c19 	.inst	0x00193c19 ; undefined
 d38:	000f2300 	.inst	0x000f2300 ; undefined
 d3c:	00000b0b 	udf	#2827
 d40:	3f002e24 	.inst	0x3f002e24 ; undefined
 d44:	3a0e0319 	adcs	w25, w24, w14
 d48:	390b3b0b 	strb	w11, [x24, #718]
 d4c:	4919270b 	.inst	0x4919270b ; undefined
 d50:	00193c13 	.inst	0x00193c13 ; undefined
 d54:	00182500 	.inst	0x00182500 ; undefined
 d58:	2e260000 	uaddl	v0.8h, v0.8b, v6.8b
 d5c:	03193f01 	.inst	0x03193f01 ; undefined
 d60:	3b0b3a0e 	.inst	0x3b0b3a0e ; undefined
 d64:	270b3905 	.inst	0x270b3905 ; undefined
 d68:	11134919 	add	w25, w8, #0x4d2
 d6c:	40071201 	.inst	0x40071201 ; undefined
 d70:	01197a18 	.inst	0x01197a18 ; undefined
 d74:	27000013 	.inst	0x27000013 ; undefined
 d78:	08030034 	stxrb	w3, w20, [x1]
 d7c:	053b0b3a 	ext	z26.b, z26.b, z25.b, #218
 d80:	13490b39 	.inst	0x13490b39 ; undefined
 d84:	0b280000 	add	w0, w0, w8, uxtb
 d88:	00175501 	.inst	0x00175501 ; undefined
 d8c:	012e2900 	.inst	0x012e2900 ; undefined
 d90:	0b3a0e03 	add	w3, w16, w26, uxtb #3
 d94:	0b390b3b 	add	w27, w25, w25, uxtb #2
 d98:	01111927 	.inst	0x01111927 ; undefined
 d9c:	18400712 	ldr	w18, 80e7c <MAIR_ATTR+0x7ca7c>
 da0:	1301197a 	sbfx	w26, w11, #1, #6
 da4:	052a0000 	ext	z0.b, z0.b, z0.b, #80
 da8:	3a0e0300 	adcs	w0, w24, w14
 dac:	390b3b0b 	strb	w11, [x24, #718]
 db0:	0213490b 	.inst	0x0213490b ; undefined
 db4:	2b000018 	adds	w24, w0, w0
 db8:	19270015 	.inst	0x19270015 ; undefined
 dbc:	2e2c0000 	uaddl	v0.8h, v0.8b, v12.8b
 dc0:	03193f00 	.inst	0x03193f00 ; undefined
 dc4:	3b0b3a0e 	.inst	0x3b0b3a0e ; undefined
 dc8:	270b390b 	.inst	0x270b390b ; undefined
 dcc:	12011119 	and	w25, w8, #0x8000000f
 dd0:	7c184007 	stur	h7, [x0, #-124]
 dd4:	2d000019 	stp	s25, s0, [x0]
 dd8:	0e03012e 	tbl	v14.8b, {v9.16b}, v3.8b
 ddc:	0b3b0b3a 	add	w26, w25, w27, uxtb #2
 de0:	19270b39 	rcwcas	x7, x25, [x25]
 de4:	01111349 	.inst	0x01111349 ; undefined
 de8:	18400712 	ldr	w18, 80ec8 <MAIR_ATTR+0x7cac8>
 dec:	1301197a 	sbfx	w26, w11, #1, #6
 df0:	0b2e0000 	add	w0, w0, w14, uxtb
 df4:	12011101 	and	w1, w8, #0x8000000f
 df8:	2f000007 	.inst	0x2f000007 ; undefined
 dfc:	193f002e 	.inst	0x193f002e ; undefined
 e00:	0b3a0e03 	add	w3, w16, w26, uxtb #3
 e04:	0b390b3b 	add	w27, w25, w25, uxtb #2
 e08:	13491927 	.inst	0x13491927 ; undefined
 e0c:	07120111 	.inst	0x07120111 ; undefined
 e10:	197a1840 	.inst	0x197a1840 ; undefined
 e14:	01000000 	.inst	0x01000000 ; undefined
 e18:	0803000d 	stxrb	w3, w13, [x0]
 e1c:	3b03213a 	.inst	0x3b03213a ; undefined
 e20:	0d21390b 	.inst	0x0d21390b ; undefined
 e24:	0b381349 	add	w9, w26, w24, uxtb #4
 e28:	24020000 	cmphs	p0.b, p0/z, z0.b, z2.b
 e2c:	3e0b0b00 	.inst	0x3e0b0b00 ; undefined
 e30:	000e030b 	.inst	0x000e030b ; undefined
 e34:	00340300 	.inst	0x00340300 ; undefined
 e38:	213a0e03 	.inst	0x213a0e03 ; undefined
 e3c:	390b3b01 	strb	w1, [x24, #718]
 e40:	0213490b 	.inst	0x0213490b ; undefined
 e44:	04000018 	add	z24.b, p0/m, z24.b, z0.b
 e48:	13490005 	.inst	0x13490005 ; undefined
 e4c:	0f050000 	fdot	v0.2s, v0.8b, v5.4b[0]
 e50:	08210b00 	.inst	0x08210b00 ; undefined
 e54:	00001349 	udf	#4937
 e58:	03000506 	.inst	0x03000506 ; undefined
 e5c:	01213a0e 	.inst	0x01213a0e ; undefined
 e60:	0b390b3b 	add	w27, w25, w25, uxtb #2
 e64:	18021349 	ldr	w9, 50cc <MAIR_ATTR+0xccc>
 e68:	16070000 	b	fffffffff81c0e68 <FS_BASE+0xffffc81c0e68>
 e6c:	3a0e0300 	adcs	w0, w24, w14
 e70:	390b3b0b 	strb	w11, [x24, #718]
 e74:	0013490b 	.inst	0x0013490b ; undefined
 e78:	012e0800 	.inst	0x012e0800 ; undefined
 e7c:	0e03193f 	uzp1	v31.8b, v9.8b, v3.8b
 e80:	0b3b0b3a 	add	w26, w25, w27, uxtb #2
 e84:	27062139 	.inst	0x27062139 ; undefined
 e88:	01193c19 	.inst	0x01193c19 ; undefined
 e8c:	09000013 	.inst	0x09000013 ; undefined
 e90:	0e03012e 	tbl	v14.8b, {v9.16b}, v3.8b
 e94:	3b01213a 	.inst	0x3b01213a ; undefined
 e98:	0c21390b 	.inst	0x0c21390b ; undefined
 e9c:	13491927 	.inst	0x13491927 ; undefined
 ea0:	07120111 	.inst	0x07120111 ; undefined
 ea4:	197c1840 	.inst	0x197c1840 ; undefined
 ea8:	00001301 	udf	#4865
 eac:	03000d0a 	.inst	0x03000d0a ; undefined
 eb0:	03213a0e 	.inst	0x03213a0e ; undefined
 eb4:	21390b3b 	.inst	0x21390b3b ; undefined
 eb8:	3813490d 	sttrb	w13, [x8, #-204]
 ebc:	0b000005 	add	w5, w0, w0
 ec0:	0803000d 	stxrb	w3, w13, [x0]
 ec4:	3b03213a 	.inst	0x3b03213a ; undefined
 ec8:	0d21390b 	.inst	0x0d21390b ; undefined
 ecc:	05381349 	ext	z9.b, z9.b, z26.b, #196
 ed0:	110c0000 	add	w0, w0, #0x300
 ed4:	130e2501 	sbfiz	w1, w8, #18, #10
 ed8:	1b1f030b 	madd	w11, w24, wzr, w0
 edc:	1201111f 	and	wsp, w8, #0x8000000f
 ee0:	00171007 	.inst	0x00171007 ; undefined
 ee4:	00240d00 	.inst	0x00240d00 ; undefined
 ee8:	0b3e0b0b 	add	w11, w24, w30, uxtb #2
 eec:	00000803 	udf	#2051
 ef0:	0301130e 	.inst	0x0301130e ; undefined
 ef4:	3a050b0e 	.inst	0x3a050b0e ; undefined
 ef8:	390b3b0b 	strb	w11, [x24, #718]
 efc:	0013010b 	.inst	0x0013010b ; undefined
 f00:	01150f00 	.inst	0x01150f00 ; undefined
 f04:	13491927 	.inst	0x13491927 ; undefined
 f08:	00001301 	udf	#4865
 f0c:	49010110 	.inst	0x49010110 ; undefined
 f10:	00130113 	.inst	0x00130113 ; undefined
 f14:	00211100 	.inst	0x00211100 ; undefined
 f18:	0b2f1349 	add	w9, w26, w15, uxtb #4
 f1c:	2e120000 	ext	v0.8b, v0.8b, v18.8b, #0
 f20:	03193f00 	.inst	0x03193f00 ; undefined
 f24:	3b0b3a0e 	.inst	0x3b0b3a0e ; undefined
 f28:	270b390b 	.inst	0x270b390b ; undefined
 f2c:	00193c19 	.inst	0x00193c19 ; undefined
 f30:	002e1300 	.inst	0x002e1300 ; undefined
 f34:	0e03193f 	uzp1	v31.8b, v9.8b, v3.8b
 f38:	0b3b0b3a 	add	w26, w25, w27, uxtb #2
 f3c:	19270b39 	rcwcas	x7, x25, [x25]
 f40:	193c1349 	ldclrp	x9, x28, [x26]
 f44:	26140000 	.inst	0x26140000 ; undefined
 f48:	00134900 	.inst	0x00134900 ; undefined
 f4c:	002e1500 	.inst	0x002e1500 ; undefined
 f50:	0e03193f 	uzp1	v31.8b, v9.8b, v3.8b
 f54:	0b3b0b3a 	add	w26, w25, w27, uxtb #2
 f58:	19270b39 	rcwcas	x7, x25, [x25]
 f5c:	07120111 	.inst	0x07120111 ; undefined
 f60:	197a1840 	.inst	0x197a1840 ; undefined
 f64:	2e160000 	ext	v0.8b, v0.8b, v22.8b, #0
 f68:	03193f01 	.inst	0x03193f01 ; undefined
 f6c:	3b0b3a0e 	.inst	0x3b0b3a0e ; undefined
 f70:	270b390b 	.inst	0x270b390b ; undefined
 f74:	12011119 	and	w25, w8, #0x8000000f
 f78:	7c184007 	stur	h7, [x0, #-124]
 f7c:	00130119 	.inst	0x00130119 ; undefined
 f80:	00051700 	.inst	0x00051700 ; undefined
 f84:	0b3a0803 	add	w3, w0, w26, uxtb #2
 f88:	0b390b3b 	add	w27, w25, w25, uxtb #2
 f8c:	18021349 	ldr	w9, 51f4 <MAIR_ATTR+0xdf4>
 f90:	34180000 	cbz	w0, 30f90 <MAIR_ATTR+0x2cb90>
 f94:	3a080300 	adcs	w0, w24, w8
 f98:	390b3b0b 	strb	w11, [x24, #718]
 f9c:	0213490b 	.inst	0x0213490b ; undefined
 fa0:	19000018 	stlurb	w24, [x0]
 fa4:	0e03012e 	tbl	v14.8b, {v9.16b}, v3.8b
 fa8:	0b3b0b3a 	add	w26, w25, w27, uxtb #2
 fac:	19270b39 	rcwcas	x7, x25, [x25]
 fb0:	01111349 	.inst	0x01111349 ; undefined
 fb4:	18400712 	ldr	w18, 81094 <MAIR_ATTR+0x7cc94>
 fb8:	0000197c 	udf	#6524
	...

Disassembly of section .debug_aranges:

0000000000000000 <.debug_aranges>:
   0:	0000002c 	udf	#44
   4:	00000002 	udf	#2
   8:	00080000 	.inst	0x00080000 ; undefined
   c:	00000000 	udf	#0
  10:	00080000 	.inst	0x00080000 ; undefined
  14:	ffff0000 	.inst	0xffff0000 ; undefined
  18:	00000110 	udf	#272
	...
  30:	0000002c 	udf	#44
  34:	00290002 	.inst	0x00290002 ; undefined
  38:	00080000 	.inst	0x00080000 ; undefined
  3c:	00000000 	udf	#0
  40:	00080110 	.inst	0x00080110 ; undefined
  44:	ffff0000 	.inst	0xffff0000 ; undefined
  48:	0000005c 	udf	#92
	...
  60:	0000002c 	udf	#44
  64:	01230002 	.inst	0x01230002 ; undefined
  68:	00080000 	.inst	0x00080000 ; undefined
  6c:	00000000 	udf	#0
  70:	0008016c 	.inst	0x0008016c ; undefined
  74:	ffff0000 	.inst	0xffff0000 ; undefined
  78:	000000b8 	udf	#184
	...
  90:	0000002c 	udf	#44
  94:	014c0002 	.inst	0x014c0002 ; undefined
  98:	00080000 	.inst	0x00080000 ; undefined
  9c:	00000000 	udf	#0
  a0:	00080224 	.inst	0x00080224 ; undefined
  a4:	ffff0000 	.inst	0xffff0000 ; undefined
  a8:	000001c8 	udf	#456
	...
  c0:	0000002c 	udf	#44
  c4:	05730002 	ext	z2.b, {z0.b-z1.b}, #152
  c8:	00080000 	.inst	0x00080000 ; undefined
  cc:	00000000 	udf	#0
  d0:	000803ec 	.inst	0x000803ec ; undefined
  d4:	ffff0000 	.inst	0xffff0000 ; undefined
  d8:	0000027c 	udf	#636
	...
  f0:	0000002c 	udf	#44
  f4:	073c0002 	.inst	0x073c0002 ; undefined
  f8:	00080000 	.inst	0x00080000 ; undefined
  fc:	00000000 	udf	#0
 100:	00080668 	.inst	0x00080668 ; undefined
 104:	ffff0000 	.inst	0xffff0000 ; undefined
 108:	0000068c 	udf	#1676
	...
 120:	0000002c 	udf	#44
 124:	0b4d0002 	add	w2, w0, w13, lsr #0
 128:	00080000 	.inst	0x00080000 ; undefined
 12c:	00000000 	udf	#0
 130:	00080cf4 	.inst	0x00080cf4 ; undefined
 134:	ffff0000 	.inst	0xffff0000 ; undefined
 138:	00000050 	udf	#80
	...
 150:	0000002c 	udf	#44
 154:	0c260002 	.inst	0x0c260002 ; undefined
 158:	00080000 	.inst	0x00080000 ; undefined
 15c:	00000000 	udf	#0
 160:	00081000 	.inst	0x00081000 ; undefined
 164:	ffff0000 	.inst	0xffff0000 ; undefined
 168:	00000a0c 	udf	#2572
	...
 180:	0000002c 	udf	#44
 184:	0c4f0002 	.inst	0x0c4f0002 ; undefined
 188:	00080000 	.inst	0x00080000 ; undefined
 18c:	00000000 	udf	#0
 190:	00081a0c 	.inst	0x00081a0c ; undefined
 194:	ffff0000 	.inst	0xffff0000 ; undefined
 198:	00000330 	udf	#816
	...
 1b0:	0000002c 	udf	#44
 1b4:	121f0002 	and	w2, w0, #0x2
 1b8:	00080000 	.inst	0x00080000 ; undefined
 1bc:	00000000 	udf	#0
 1c0:	00082000 	.inst	0x00082000 ; undefined
 1c4:	ffff0000 	.inst	0xffff0000 ; undefined
 1c8:	00008010 	udf	#32784
	...
 1e0:	0000002c 	udf	#44
 1e4:	12490002 	.inst	0x12490002 ; undefined
 1e8:	00080000 	.inst	0x00080000 ; undefined
 1ec:	00000000 	udf	#0
 1f0:	0008a010 	.inst	0x0008a010 ; undefined
 1f4:	ffff0000 	.inst	0xffff0000 ; undefined
 1f8:	000009a8 	udf	#2472
	...
 210:	0000002c 	udf	#44
 214:	18ca0002 	ldr	w2, fffffffffff94214 <FS_BASE+0xffffcff94214>
 218:	00080000 	.inst	0x00080000 ; undefined
 21c:	00000000 	udf	#0
 220:	0008a9b8 	.inst	0x0008a9b8 ; undefined
 224:	ffff0000 	.inst	0xffff0000 ; undefined
 228:	0000073c 	udf	#1852
	...
 240:	0000002c 	udf	#44
 244:	20880002 	.inst	0x20880002 ; undefined
 248:	00080000 	.inst	0x00080000 ; undefined
 24c:	00000000 	udf	#0
 250:	0008b0f4 	.inst	0x0008b0f4 ; undefined
 254:	ffff0000 	.inst	0xffff0000 ; undefined
 258:	00000da0 	udf	#3488
	...
 270:	0000002c 	udf	#44
 274:	2c290002 	stnp	s2, s0, [x0, #-184]
 278:	00080000 	.inst	0x00080000 ; undefined
 27c:	00000000 	udf	#0
 280:	0008be94 	.inst	0x0008be94 ; undefined
 284:	ffff0000 	.inst	0xffff0000 ; undefined
 288:	000001cc 	udf	#460
	...

Disassembly of section .debug_str:

0000000000000000 <.debug_str>:
   0:	746f6f62 	.inst	0x746f6f62 ; undefined
   4:	2f00732e 	.inst	0x2f00732e ; undefined
   8:	72657355 	.inst	0x72657355 ; undefined
   c:	696a2f73 	ldpsw	x19, x11, [x27, #-176]
  10:	676e696d 	.inst	0x676e696d ; undefined
  14:	676e616b 	.inst	0x676e616b ; undefined
  18:	444c4c2f 	umlalt	z15.h, z1.b, z12.b
  1c:	6970722f 	ldpsw	x15, x28, [x17, #-128]
  20:	006d625f 	.inst	0x006d625f ; undefined
  24:	20554e47 	.inst	0x20554e47 ; undefined
  28:	32205341 	orr	w1, w26, #0x1fffff
  2c:	2e36342e 	cmhi	v14.8b, v1.8b, v22.8b
  30:	6e650030 	uaddl2	v16.4s, v1.8h, v5.8h
  34:	656c6261 	fnmls	z1.h, p0/m, z19.h, z12.h
  38:	7172695f 	cmp	w10, #0xc9a, lsl #12
  3c:	696e6900 	ldpsw	x0, x26, [x8, #-144]
  40:	69745f74 	ldpsw	x20, x23, [x27, #-96]
  44:	0072656d 	.inst	0x0072656d ; undefined
  48:	74696e69 	.inst	0x74696e69 ; undefined
  4c:	7261755f 	.inst	0x7261755f ; undefined
  50:	6e690074 	uaddl2	v20.4s, v3.8h, v9.8h
  54:	735f7469 	.inst	0x735f7469 ; undefined
  58:	65747379 	fnmls	z25.h, p4/m, z27.h, z20.h
  5c:	61635f6d 	.inst	0x61635f6d ; undefined
  60:	47006c6c 	.inst	0x47006c6c ; undefined
  64:	4320554e 	.inst	0x4320554e ; undefined
  68:	31203939 	adds	w25, w9, #0x80e
  6c:	2e312e36 	uqsub	v22.8b, v17.8b, v17.8b
  70:	6d2d2030 	stp	d16, d8, [x1, #-304]
  74:	3d757063 	ldr	b3, [x3, #3420]
  78:	74726f63 	.inst	0x74726f63 ; undefined
  7c:	612d7865 	.inst	0x612d7865 ; undefined
  80:	6e2b3335 	usubw2	v21.8h, v25.8h, v11.16b
  84:	2070666f 	.inst	0x2070666f ; undefined
  88:	65676d2d 	fnmls	z13.h, p3/m, z9.h, z7.h
  8c:	6172656e 	.inst	0x6172656e ; undefined
  90:	65722d6c 	fmls	z12.h, p3/m, z11.h, z18.h
  94:	6f2d7367 	.inst	0x6f2d7367 ; undefined
  98:	20796c6e 	.inst	0x20796c6e ; undefined
  9c:	696c6d2d 	ldpsw	x13, x27, [x9, #-160]
  a0:	656c7474 	fnmls	z20.h, p5/m, z3.h, z12.h
  a4:	646e652d 	.inst	0x646e652d ; undefined
  a8:	206e6169 	.inst	0x206e6169 ; undefined
  ac:	62616d2d 	.inst	0x62616d2d ; undefined
  b0:	706c3d69 	adr	x9, d885f <MAIR_ATTR+0xd445f>
  b4:	2d203436 	stp	s22, s13, [x1, #-256]
  b8:	4f2d2067 	.inst	0x4f2d2067 ; undefined
  bc:	732d2030 	.inst	0x732d2030 ; undefined
  c0:	633d6474 	.inst	0x633d6474 ; undefined
  c4:	2d203939 	stp	s25, s14, [x9, #-256]
  c8:	2d6f6e66 	ldp	s6, s27, [x19, #-136]
  cc:	74696d6f 	.inst	0x74696d6f ; undefined
  d0:	6172662d 	.inst	0x6172662d ; undefined
  d4:	702d656d 	adr	x13, 5ad83 <MAIR_ATTR+0x56983>
  d8:	746e696f 	.inst	0x746e696f ; undefined
  dc:	2d207265 	stp	s5, s28, [x19, #-256]
  e0:	65726666 	fnmls	z6.h, p1/m, z19.h, z18.h
  e4:	61747365 	.inst	0x61747365 ; undefined
  e8:	6e69646e 	umax	v14.8h, v3.8h, v9.8h
  ec:	662d2067 	.inst	0x662d2067 ; undefined
  f0:	632d6f6e 	.inst	0x632d6f6e ; undefined
  f4:	6f6d6d6f 	.inst	0x6f6d6d6f ; undefined
  f8:	662d206e 	.inst	0x662d206e ; undefined
  fc:	732d6f6e 	.inst	0x732d6f6e ; undefined
 100:	6b636174 	.inst	0x6b636174 ; undefined
 104:	6f72702d 	fcmla	v13.8h, v1.8h, v18.h[1], #270
 108:	74636574 	.inst	0x74636574 ; undefined
 10c:	7500726f 	.inst	0x7500726f ; undefined
 110:	36746e69 	tbz	w9, #14, ffffffffffff8edc <FS_BASE+0xffffcfff8edc>
 114:	00745f34 	.inst	0x00745f34 ; undefined
 118:	74696e69 	.inst	0x74696e69 ; undefined
 11c:	6d656d5f 	ldp	d31, d27, [x10, #-432]
 120:	0079726f 	.inst	0x0079726f ; undefined
 124:	74696e69 	.inst	0x74696e69 ; undefined
 128:	6f72705f 	fcmla	v31.8h, v2.8h, v18.h[1], #270
 12c:	73736563 	.inst	0x73736563 ; undefined
 130:	736e7500 	.inst	0x736e7500 ; undefined
 134:	656e6769 	fnmls	z9.h, p1/m, z27.h, z14.h
 138:	68632064 	.inst	0x68632064 ; undefined
 13c:	6c007261 	stnp	d1, d28, [x19]
 140:	20676e6f 	.inst	0x20676e6f ; undefined
 144:	00746e69 	.inst	0x00746e69 ; undefined
 148:	74696e69 	.inst	0x74696e69 ; undefined
 14c:	0073665f 	.inst	0x0073665f ; undefined
 150:	676e6f6c 	.inst	0x676e6f6c ; undefined
 154:	736e7520 	.inst	0x736e7520 ; undefined
 158:	656e6769 	fnmls	z9.h, p1/m, z27.h, z14.h
 15c:	6e692064 	usubl2	v4.4s, v3.8h, v9.8h
 160:	6e690074 	uaddl2	v20.4s, v3.8h, v9.8h
 164:	695f7469 	ldpsw	x9, x29, [x3, #248]
 168:	7265746e 	.inst	0x7265746e ; undefined
 16c:	74707572 	.inst	0x74707572 ; undefined
 170:	6e6f635f 	rsubhn2	v31.8h, v26.4s, v15.4s
 174:	6c6f7274 	ldnp	d20, d28, [x19, #-272]
 178:	0072656c 	.inst	0x0072656c ; undefined
 17c:	726f6873 	.inst	0x726f6873 ; undefined
 180:	6e752074 	usubl2	v20.4s, v3.8h, v21.8h
 184:	6e676973 	.inst	0x6e676973 ; undefined
 188:	69206465 	stgp	x5, x25, [x3, #-1024]
 18c:	6700746e 	.inst	0x6700746e ; undefined
 190:	655f7465 	fcmeq	p5.h, p5/z, z3.h, z31.h
 194:	7270006c 	.inst	0x7270006c ; undefined
 198:	6b746e69 	.inst	0x6b746e69 ; undefined
 19c:	614d4b00 	.inst	0x614d4b00 ; undefined
 1a0:	73006e69 	.inst	0x73006e69 ; undefined
 1a4:	74726f68 	.inst	0x74726f68 ; undefined
 1a8:	746e6920 	.inst	0x746e6920 ; undefined
 1ac:	62696c00 	.inst	0x62696c00 ; undefined
 1b0:	5400732e 	b.al	1014 <_binary_init_bin_size+0x8cc>
 1b4:	46706172 	.inst	0x46706172 ; undefined
 1b8:	656d6172 	fnmls	z18.h, p0/m, z11.h, z13.h
 1bc:	61747300 	.inst	0x61747300 ; undefined
 1c0:	73006574 	.inst	0x73006574 ; undefined
 1c4:	00727370 	.inst	0x00727370 ; undefined
 1c8:	636f7250 	.inst	0x636f7250 ; undefined
 1cc:	00737365 	.inst	0x00737365 ; undefined
 1d0:	6d657469 	ldp	d9, d29, [x3, #-432]
 1d4:	61654800 	.inst	0x61654800 ; undefined
 1d8:	73694c64 	.inst	0x73694c64 ; undefined
 1dc:	65720074 	fmla	z20.h, p0/m, z3.h, z18.h
 1e0:	65766f6d 	fnmls	z13.h, p3/m, z27.h, z22.h
 1e4:	73696c5f 	.inst	0x73696c5f ; undefined
 1e8:	73690074 	.inst	0x73690074 ; undefined
 1ec:	73696c5f 	.inst	0x73696c5f ; undefined
 1f0:	6d655f74 	ldp	d20, d23, [x27, #-432]
 1f4:	00797470 	.inst	0x00797470 ; undefined
 1f8:	72727563 	.inst	0x72727563 ; undefined
 1fc:	00746e65 	.inst	0x00746e65 ; undefined
 200:	6f6f425f 	mls	v31.8h, v18.8h, v15.h[2]
 204:	6572006c 	fmla	z12.h, p0/m, z3.h, z18.h
 208:	65766f6d 	fnmls	z13.h, p3/m, z27.h, z22.h
 20c:	73696c5f 	.inst	0x73696c5f ; undefined
 210:	65685f74 	fnmla	z20.h, p7/m, z27.h, z8.h
 214:	70006461 	adr	x1, ea3 <_binary_init_bin_size+0x75b>
 218:	5f656761 	.inst	0x5f656761 ; undefined
 21c:	0070616d 	.inst	0x0070616d ; undefined
 220:	76657270 	.inst	0x76657270 ; undefined
 224:	70706100 	adr	x0, e0e47 <MAIR_ATTR+0xdca47>
 228:	5f646e65 	.inst	0x5f646e65 ; undefined
 22c:	7473696c 	.inst	0x7473696c ; undefined
 230:	6961745f 	ldpsw	xzr, x29, [x2, #-248]
 234:	656e006c 	fmla	z12.h, p0/m, z3.h, z14.h
 238:	74007478 	.inst	0x74007478 ; undefined
 23c:	6e706172 	rsubhn2	v18.8h, v11.4s, v16.4s
 240:	6e69006f 	uaddl2	v15.4s, v3.8h, v9.8h
 244:	726f775f 	.inst	0x726f775f ; undefined
 248:	65730064 	fmla	z4.h, p0/m, z3.h, z19.h
 24c:	7463656c 	.inst	0x7463656c ; undefined
 250:	7700726f 	.inst	0x7700726f ; undefined
 254:	65746972 	fnmls	z18.h, p2/m, z11.h, z20.h
 258:	7274735f 	.inst	0x7274735f ; undefined
 25c:	00676e69 	.inst	0x00676e69 ; undefined
 260:	616c6564 	.inst	0x616c6564 ; undefined
 264:	756f0079 	cblo	w25, #30, 270 <TCR_T0SZ+0x260>
 268:	6f775f74 	.inst	0x6f775f74 ; undefined
 26c:	72006472 	ands	w18, w3, #0x3ffffff
 270:	5f646165 	.inst	0x5f646165 ; undefined
 274:	72616863 	.inst	0x72616863 ; undefined
 278:	69727700 	ldpsw	x0, x29, [x24, #-112]
 27c:	635f6574 	.inst	0x635f6574 ; undefined
 280:	00726168 	.inst	0x00726168 ; undefined
 284:	74726175 	.inst	0x74726175 ; undefined
 288:	6e61685f 	fcvtxn2	v31.4s, v2.2d
 28c:	72656c64 	.inst	0x72656c64 ; undefined
 290:	6e697500 	uabd	v0.8h, v8.8h, v9.8h
 294:	5f323374 	.inst	0x5f323374 ; undefined
 298:	72770074 	.inst	0x72770074 ; undefined
 29c:	5f657469 	sqshl	d9, d3, #37
 2a0:	736e6f63 	.inst	0x736e6f63 ; undefined
 2a4:	00656c6f 	.inst	0x00656c6f ; undefined
 2a8:	69676964 	ldpsw	x4, x26, [x11, #-200]
 2ac:	625f7374 	.inst	0x625f7374 ; undefined
 2b0:	65666675 	fnmls	z21.h, p1/m, z19.h, z6.h
 2b4:	72610072 	.inst	0x72610072 ; undefined
 2b8:	62007367 	.inst	0x62007367 ; undefined
 2bc:	65666675 	fnmls	z21.h, p1/m, z19.h, z6.h
 2c0:	69735f72 	ldpsw	x18, x23, [x27, #-104]
 2c4:	6800657a 	.inst	0x6800657a ; undefined
 2c8:	745f7865 	.inst	0x745f7865 ; undefined
 2cc:	74735f6f 	.inst	0x74735f6f ; undefined
 2d0:	676e6972 	.inst	0x676e6972 ; undefined
 2d4:	736f7000 	.inst	0x736f7000 ; undefined
 2d8:	6f697469 	uqshl	v9.2d, v3.2d, #41
 2dc:	5f5f006e 	.inst	0x5f5f006e ; undefined
 2e0:	745f7267 	.inst	0x745f7267 ; undefined
 2e4:	7200706f 	ands	w15, w3, #0x1fffffff
 2e8:	5f646165 	.inst	0x5f646165 ; undefined
 2ec:	69727473 	ldpsw	x19, x29, [x3, #-112]
 2f0:	6400676e 	.inst	0x6400676e ; undefined
 2f4:	74696769 	.inst	0x74696769 ; undefined
 2f8:	616d5f73 	.inst	0x616d5f73 ; undefined
 2fc:	5f5f0070 	.inst	0x5f5f0070 ; undefined
 300:	63756e67 	.inst	0x63756e67 ; undefined
 304:	5f61765f 	sqshl	d31, d18, #33
 308:	7473696c 	.inst	0x7473696c ; undefined
 30c:	726f6600 	.inst	0x726f6600 ; undefined
 310:	0074616d 	.inst	0x0074616d ; undefined
 314:	72675f5f 	.inst	0x72675f5f ; undefined
 318:	66666f5f 	.inst	0x66666f5f ; undefined
 31c:	5f5f0073 	.inst	0x5f5f0073 ; undefined
 320:	6c5f6176 	ldnp	d22, d24, [x11, #496]
 324:	00747369 	.inst	0x00747369 ; undefined
 328:	72765f5f 	.inst	0x72765f5f ; undefined
 32c:	66666f5f 	.inst	0x66666f5f ; undefined
 330:	69640073 	ldpsw	x19, x0, [x3, #-224]
 334:	73746967 	.inst	0x73746967 ; undefined
 338:	746e6900 	.inst	0x746e6900 ; undefined
 33c:	72656765 	.inst	0x72656765 ; undefined
 340:	765f5f00 	.inst	0x765f5f00 ; undefined
 344:	6f745f72 	.inst	0x6f745f72 ; undefined
 348:	64750070 	fmla	z16.h, z3.h, z5.h[6]
 34c:	6d696365 	ldp	d5, d24, [x27, #-368]
 350:	745f6c61 	.inst	0x745f6c61 ; undefined
 354:	74735f6f 	.inst	0x74735f6f ; undefined
 358:	676e6972 	.inst	0x676e6972 ; undefined
 35c:	735f5f00 	.inst	0x735f5f00 ; undefined
 360:	6b636174 	.inst	0x6b636174 ; undefined
 364:	6e696c00 	umin	v0.8h, v0.8h, v9.8h
 368:	72650065 	.inst	0x72650065 ; undefined
 36c:	5f726f72 	.inst	0x5f726f72 ; undefined
 370:	63656863 	.inst	0x63656863 ; undefined
 374:	6168006b 	.inst	0x6168006b ; undefined
 378:	656c646e 	fnmls	z14.h, p1/m, z3.h, z12.h
 37c:	00732e72 	.inst	0x00732e72 ; undefined
 380:	64616572 	.inst	0x64616572 ; undefined
 384:	6d69745f 	ldp	d31, d29, [x2, #-368]
 388:	735f7265 	.inst	0x735f7265 ; undefined
 38c:	75746174 	.inst	0x75746174 ; undefined
 390:	65730073 	fmla	z19.h, p0/m, z3.h, z19.h
 394:	69745f74 	ldpsw	x20, x23, [x27, #-96]
 398:	5f72656d 	.inst	0x5f72656d ; undefined
 39c:	65746e69 	fnmls	z9.h, p3/m, z19.h, z20.h
 3a0:	6c617672 	ldnp	d18, d29, [x19, #-496]
 3a4:	61657200 	.inst	0x61657200 ; undefined
 3a8:	69745f64 	ldpsw	x4, x23, [x27, #-96]
 3ac:	5f72656d 	.inst	0x5f72656d ; undefined
 3b0:	71657266 	subs	w6, w19, #0x95c, lsl #12
 3b4:	6c696b00 	ldnp	d0, d26, [x24, #-368]
 3b8:	696c5f6c 	ldpsw	x12, x23, [x27, #-160]
 3bc:	63007473 	.inst	0x63007473 ; undefined
 3c0:	6b636568 	.inst	0x6b636568 ; undefined
 3c4:	656c735f 	fnmls	z31.h, p4/m, z26.h, z12.h
 3c8:	6c5f7065 	ldnp	d5, d28, [x3, #496]
 3cc:	00747369 	.inst	0x00747369 ; undefined
 3d0:	5f746567 	.inst	0x5f746567 ; undefined
 3d4:	50006370 	adr	x16, 1042 <_binary_init_bin_size+0x8fa>
 3d8:	65636f72 	fnmls	z18.h, p3/m, z27.h, z3.h
 3dc:	6f437373 	fcmla	v19.8h, v27.8h, v3.h[0], #270
 3e0:	6f72746e 	uqshl	v14.2d, v3.2d, #50
 3e4:	7563006c 	cblo	w12, #6, 3f0 <TCR_T0SZ+0x3e0>
 3e8:	6e657272 	uabdl2	v18.4s, v19.8h, v5.8h
 3ec:	72705f74 	.inst	0x72705f74 ; undefined
 3f0:	7365636f 	.inst	0x7365636f ; undefined
 3f4:	65670073 	fmla	z19.h, p0/m, z3.h, z7.h
 3f8:	72695f74 	.inst	0x72695f74 ; undefined
 3fc:	756e5f71 	.inst	0x756e5f71 ; undefined
 400:	7265626d 	.inst	0x7265626d ; undefined
 404:	74656700 	.inst	0x74656700 ; undefined
 408:	6369745f 	.inst	0x6369745f ; undefined
 40c:	7400736b 	.inst	0x7400736b ; undefined
 410:	72656d69 	.inst	0x72656d69 ; undefined
 414:	746e695f 	.inst	0x746e695f ; undefined
 418:	75727265 	.inst	0x75727265 ; undefined
 41c:	685f7470 	.inst	0x685f7470 ; undefined
 420:	6c646e61 	ldnp	d1, d27, [x19, #-448]
 424:	77007265 	.inst	0x77007265 ; undefined
 428:	5f746961 	.inst	0x5f746961 ; undefined
 42c:	7473696c 	.inst	0x7473696c ; undefined
 430:	616e6500 	.inst	0x616e6500 ; undefined
 434:	5f656c62 	.inst	0x5f656c62 ; undefined
 438:	656d6974 	fnmls	z20.h, p2/m, z11.h, z13.h
 43c:	65720072 	fmla	z18.h, p0/m, z3.h, z18.h
 440:	5f796461 	.inst	0x5f796461 ; undefined
 444:	7473696c 	.inst	0x7473696c ; undefined
 448:	65697900 	fnmls	z0.h, p6/m, z8.h, z9.h
 44c:	7700646c 	.inst	0x7700646c ; undefined
 450:	5f656b61 	.inst	0x5f656b61 ; undefined
 454:	73007075 	.inst	0x73007075 ; undefined
 458:	64656863 	.inst	0x64656863 ; undefined
 45c:	00656c75 	.inst	0x00656c75 ; undefined
 460:	2e756d6d 	umin	v13.4h, v11.4h, v21.4h
 464:	616d0073 	.inst	0x616d0073 ; undefined
 468:	61705f70 	.inst	0x61705f70 ; undefined
 46c:	50006567 	adr	x7, 111a <_binary_init_bin_size+0x9d2>
 470:	00656761 	.inst	0x00656761 ; undefined
 474:	65657266 	fnmls	z6.h, p4/m, z19.h, z5.h
 478:	006d765f 	.inst	0x006d765f ; undefined
 47c:	6c6c616b 	ldnp	d11, d24, [x11, #-320]
 480:	6d00636f 	stp	d15, d24, [x27]
 484:	70636d65 	adr	x5, c7233 <MAIR_ATTR+0xc2e33>
 488:	67700079 	.inst	0x67700079 ; undefined
 48c:	74745f64 	.inst	0x74745f64 ; undefined
 490:	00317262 	.inst	0x00317262 ; undefined
 494:	72747461 	.inst	0x72747461 ; undefined
 498:	74756269 	.inst	0x74756269 ; undefined
 49c:	72660065 	.inst	0x72660065 ; undefined
 4a0:	725f6565 	.inst	0x725f6565 ; undefined
 4a4:	6f696765 	sqshlu	v5.2d, v27.2d, #41
 4a8:	6966006e 	ldpsw	x14, x0, [x3, #-208]
 4ac:	705f646e 	adr	x14, bf13b <MAIR_ATTR+0xbad3b>
 4b0:	655f6475 	fcmne	p5.h, p1/z, z3.h, z31.h
 4b4:	7972746e 	ldrh	w14, [x3, #6458]
 4b8:	69625f00 	ldpsw	x0, x23, [x24, #-240]
 4bc:	7972616e 	ldrh	w14, [x11, #6448]
 4c0:	696e695f 	ldpsw	xzr, x26, [x10, #-144]
 4c4:	69625f74 	ldpsw	x20, x23, [x27, #-240]
 4c8:	6e655f6e 	uqrshl	v14.8h, v27.8h, v5.8h
 4cc:	77730064 	.inst	0x77730064 ; undefined
 4d0:	68637469 	.inst	0x68637469 ; undefined
 4d4:	006d765f 	.inst	0x006d765f ; undefined
 4d8:	736d656d 	.inst	0x736d656d ; undefined
 4dc:	66007465 	.inst	0x66007465 ; undefined
 4e0:	5f656572 	.inst	0x5f656572 ; undefined
 4e4:	00646770 	.inst	0x00646770 ; undefined
 4e8:	75746573 	.inst	0x75746573 ; undefined
 4ec:	76755f70 	.inst	0x76755f70 ; undefined
 4f0:	6170006d 	.inst	0x6170006d ; undefined
 4f4:	615f6567 	.inst	0x615f6567 ; undefined
 4f8:	65726464 	fnmls	z4.h, p1/m, z3.h, z18.h
 4fc:	6c007373 	stnp	d19, d28, [x27]
 500:	5f64616f 	.inst	0x5f64616f ; undefined
 504:	656c6966 	fnmls	z6.h, p2/m, z11.h, z12.h
 508:	65726600 	fnmls	z0.h, p1/m, z16.h, z18.h
 50c:	656d5f65 	fnmla	z5.h, p7/m, z27.h, z13.h
 510:	79726f6d 	ldrh	w13, [x27, #6454]
 514:	65726600 	fnmls	z0.h, p1/m, z16.h, z18.h
 518:	75705f65 	.inst	0x75705f65 ; undefined
 51c:	6f6c0064 	mla	v4.8h, v3.8h, v12.h[2]
 520:	705f6461 	adr	x1, bf1af <MAIR_ATTR+0xbadaf>
 524:	6c006467 	stnp	d7, d25, [x3]
 528:	5f64616f 	.inst	0x5f64616f ; undefined
 52c:	72657375 	.inst	0x72657375 ; undefined
 530:	626d655f 	.inst	0x626d655f ; undefined
 534:	65646465 	fnmls	z5.h, p1/m, z3.h, z4.h
 538:	73760064 	.inst	0x73760064 ; undefined
 53c:	74726174 	.inst	0x74726174 ; undefined
 540:	65726600 	fnmls	z0.h, p1/m, z16.h, z18.h
 544:	61705f65 	.inst	0x61705f65 ; undefined
 548:	6b006567 	subs	w7, w11, w0, lsl #25
 54c:	65657266 	fnmls	z6.h, p4/m, z19.h, z5.h
 550:	65686300 	fnmls	z0.h, p0/m, z24.h, z8.h
 554:	6d6d6b63 	ldp	d3, d26, [x27, #-304]
 558:	6c696600 	ldnp	d0, d25, [x16, #-368]
 55c:	616e5f65 	.inst	0x616e5f65 ; undefined
 560:	5f00656d 	.inst	0x5f00656d ; undefined
 564:	616e6962 	.inst	0x616e6962 ; undefined
 568:	695f7972 	ldpsw	x18, x30, [x11, #248]
 56c:	5f74696e 	.inst	0x5f74696e ; undefined
 570:	5f6e6962 	.inst	0x5f6e6962 ; undefined
 574:	72617473 	.inst	0x72617473 ; undefined
 578:	69660074 	ldpsw	x20, x0, [x3, #-208]
 57c:	705f646e 	adr	x14, bf20b <MAIR_ATTR+0xbae0b>
 580:	655f6467 	fcmeq	p7.h, p1/z, z3.h, z31.h
 584:	7972746e 	ldrh	w14, [x3, #6458]
 588:	72656b00 	.inst	0x72656b00 ; undefined
 58c:	5f6c656e 	.inst	0x5f6c656e ; undefined
 590:	00646770 	.inst	0x00646770 ; undefined
 594:	65657266 	fnmls	z6.h, p4/m, z19.h, z5.h
 598:	646d705f 	.inst	0x646d705f ; undefined
 59c:	74656700 	.inst	0x74656700 ; undefined
 5a0:	7461665f 	.inst	0x7461665f ; undefined
 5a4:	6261745f 	.inst	0x6261745f ; undefined
 5a8:	6600656c 	.inst	0x6600656c ; undefined
 5ac:	5f656c69 	.inst	0x5f656c69 ; undefined
 5b0:	74737973 	.inst	0x74737973 ; undefined
 5b4:	67006d65 	.inst	0x67006d65 ; undefined
 5b8:	635f7465 	.inst	0x635f7465 ; undefined
 5bc:	7473756c 	.inst	0x7473756c ; undefined
 5c0:	735f7265 	.inst	0x735f7265 ; undefined
 5c4:	00657a69 	.inst	0x00657a69 ; undefined
 5c8:	5f746567 	.inst	0x5f746567 ; undefined
 5cc:	73756c63 	.inst	0x73756c63 ; undefined
 5d0:	5f726574 	.inst	0x5f726574 ; undefined
 5d4:	7366666f 	.inst	0x7366666f ; undefined
 5d8:	61007465 	.inst	0x61007465 ; undefined
 5dc:	69727474 	ldpsw	x20, x29, [x3, #-112]
 5e0:	65747562 	fnmls	z2.h, p5/m, z11.h, z20.h
 5e4:	616c0073 	.inst	0x616c0073 ; undefined
 5e8:	5f656772 	.inst	0x5f656772 ; undefined
 5ec:	74636573 	.inst	0x74636573 ; undefined
 5f0:	635f726f 	.inst	0x635f726f ; undefined
 5f4:	746e756f 	.inst	0x746e756f ; undefined
 5f8:	61657300 	.inst	0x61657300 ; undefined
 5fc:	5f686372 	.inst	0x5f686372 ; undefined
 600:	656c6966 	fnmls	z6.h, p2/m, z11.h, z12.h
 604:	74746100 	.inst	0x74746100 ; undefined
 608:	6e695f72 	uqrshl	v18.8h, v27.8h, v9.8h
 60c:	00786564 	.inst	0x00786564 ; undefined
 610:	756c6f76 	.inst	0x756c6f76 ; undefined
 614:	695f656d 	ldpsw	x13, x25, [x11, #248]
 618:	756a0064 	cblo	w4, #20, 624 <TCR_T0SZ+0x614>
 61c:	6400706d 	.inst	0x6400706d ; undefined
 620:	735f7269 	.inst	0x735f7269 ; undefined
 624:	00657a69 	.inst	0x00657a69 ; undefined
 628:	5f746166 	.inst	0x5f746166 ; undefined
 62c:	6e756f63 	umin	v3.8h, v27.8h, v21.8h
 630:	65730074 	fmla	z20.h, p0/m, z3.h, z19.h
 634:	726f7463 	.inst	0x726f7463 ; undefined
 638:	65705f73 	fnmla	z19.h, p7/m, z27.h, z16.h
 63c:	6c635f72 	ldnp	d18, d23, [x27, #-464]
 640:	65747375 	fnmls	z21.h, p4/m, z27.h, z20.h
 644:	65720072 	fmla	z18.h, p0/m, z3.h, z18.h
 648:	69735f73 	ldpsw	x19, x23, [x27, #-104]
 64c:	7500657a 	.inst	0x7500657a ; undefined
 650:	38746e69 	.inst	0x38746e69 ; undefined
 654:	6800745f 	.inst	0x6800745f ; undefined
 658:	65646469 	fnmls	z9.h, p1/m, z3.h, z4.h
 65c:	65735f6e 	fnmla	z14.h, p7/m, z27.h, z19.h
 660:	726f7463 	.inst	0x726f7463 ; undefined
 664:	756f635f 	.inst	0x756f635f ; undefined
 668:	6d00746e 	stp	d14, d29, [x3]
 66c:	6d69745f 	ldp	d31, d29, [x2, #-368]
 670:	656d0065 	fmla	z5.h, p0/m, z3.h, z13.h
 674:	706d636d 	adr	x13, db2e3 <MAIR_ATTR+0xd6ee3>
 678:	63657300 	.inst	0x63657300 ; undefined
 67c:	73726f74 	.inst	0x73726f74 ; undefined
 680:	7265705f 	.inst	0x7265705f ; undefined
 684:	7461665f 	.inst	0x7461665f ; undefined
 688:	74656700 	.inst	0x74656700 ; undefined
 68c:	5f73665f 	.inst	0x5f73665f ; undefined
 690:	00627062 	.inst	0x00627062 ; undefined
 694:	61657263 	.inst	0x61657263 ; undefined
 698:	6d5f6574 	ldp	d20, d25, [x11, #496]
 69c:	69440073 	ldpsw	x19, x0, [x3, #32]
 6a0:	746e4572 	.inst	0x746e4572 ; undefined
 6a4:	63007972 	.inst	0x63007972 ; undefined
 6a8:	74616572 	.inst	0x74616572 ; undefined
 6ac:	61645f65 	.inst	0x61645f65 ; undefined
 6b0:	73006574 	.inst	0x73006574 ; undefined
 6b4:	6f746365 	umlsl2	v5.4s, v27.8h, v4.h[3]
 6b8:	705f7372 	adr	x18, bf527 <MAIR_ATTR+0xbb127>
 6bc:	745f7265 	.inst	0x745f7265 ; undefined
 6c0:	6b636172 	.inst	0x6b636172 ; undefined
 6c4:	74616600 	.inst	0x74616600 ; undefined
 6c8:	7a69735f 	.inst	0x7a69735f ; undefined
 6cc:	6c660065 	ldnp	d5, d0, [x3, #-416]
 6d0:	00736761 	.inst	0x00736761 ; undefined
 6d4:	65736572 	fnmls	z18.h, p1/m, z11.h, z19.h
 6d8:	64657672 	.inst	0x64657672 ; undefined
 6dc:	74656700 	.inst	0x74656700 ; undefined
 6e0:	6f6f725f 	fcmla	v31.8h, v18.8h, v15.h[1], #270
 6e4:	69645f74 	ldpsw	x20, x23, [x27, #-224]
 6e8:	74636572 	.inst	0x74636572 ; undefined
 6ec:	5f79726f 	sqdmlsl	s15, h19, v9.h[3]
 6f0:	6e756f63 	umin	v3.8h, v27.8h, v21.8h
 6f4:	69750074 	ldpsw	x20, x0, [x3, #-88]
 6f8:	3631746e 	tbz	w14, #6, 3584 <_binary_init_bin_size+0x2e3c>
 6fc:	7200745f 	tst	w2, #0x3fffffff
 700:	5f646165 	.inst	0x5f646165 ; undefined
 704:	5f776172 	.inst	0x5f776172 ; undefined
 708:	61746164 	.inst	0x61746164 ; undefined
 70c:	61657200 	.inst	0x61657200 ; undefined
 710:	69665f64 	ldpsw	x4, x23, [x27, #-208]
 714:	6600656c 	.inst	0x6600656c ; undefined
 718:	5f656c69 	.inst	0x5f656c69 ; undefined
 71c:	657a6973 	fnmls	z19.h, p2/m, z11.h, z26.h
 720:	6c707300 	ldnp	d0, d28, [x24, #-256]
 724:	705f7469 	adr	x9, bf5b3 <MAIR_ATTR+0xbb1b3>
 728:	00687461 	.inst	0x00687461 ; undefined
 72c:	665f7369 	.inst	0x665f7369 ; undefined
 730:	5f656c69 	.inst	0x5f656c69 ; undefined
 734:	656d616e 	fnmls	z14.h, p0/m, z11.h, z13.h
 738:	7571655f 	.inst	0x7571655f ; undefined
 73c:	72006c61 	ands	w1, w3, #0xfffffff
 740:	72657365 	.inst	0x72657365 ; undefined
 744:	5f646576 	.inst	0x5f646576 ; undefined
 748:	74636573 	.inst	0x74636573 ; undefined
 74c:	635f726f 	.inst	0x635f726f ; undefined
 750:	746e756f 	.inst	0x746e756f ; undefined
 754:	74656700 	.inst	0x74656700 ; undefined
 758:	756c635f 	.inst	0x756c635f ; undefined
 75c:	72657473 	.inst	0x72657473 ; undefined
 760:	6c61765f 	ldnp	d31, d29, [x18, #-496]
 764:	72006575 	ands	w21, w11, #0x3ffffff
 768:	5f746f6f 	.inst	0x5f746f6f ; undefined
 76c:	72746e65 	.inst	0x72746e65 ; undefined
 770:	6f635f79 	.inst	0x6f635f79 ; undefined
 774:	00746e75 	.inst	0x00746e75 ; undefined
 778:	5f746567 	.inst	0x5f746567 ; undefined
 77c:	746f6f72 	.inst	0x746f6f72 ; undefined
 780:	7269645f 	.inst	0x7269645f ; undefined
 784:	6f746365 	umlsl2	v5.4s, v27.8h, v4.h[3]
 788:	61007972 	.inst	0x61007972 ; undefined
 78c:	73656363 	.inst	0x73656363 ; undefined
 790:	61645f73 	.inst	0x61645f73 ; undefined
 794:	72006574 	ands	w20, w11, #0x3ffffff
 798:	5f646165 	.inst	0x5f646165 ; undefined
 79c:	657a6973 	fnmls	z19.h, p2/m, z11.h, z26.h
 7a0:	65726300 	fnmls	z0.h, p0/m, z24.h, z18.h
 7a4:	5f657461 	sqshl	d1, d3, #37
 7a8:	656d6974 	fnmls	z20.h, p2/m, z11.h, z13.h
 7ac:	67697300 	.inst	0x67697300 ; undefined
 7b0:	7574616e 	.inst	0x7574616e ; undefined
 7b4:	76006572 	.inst	0x76006572 ; undefined
 7b8:	6d756c6f 	ldp	d15, d27, [x3, #-176]
 7bc:	616c5f65 	.inst	0x616c5f65 ; undefined
 7c0:	006c6562 	.inst	0x006c6562 ; undefined
 7c4:	64616568 	.inst	0x64616568 ; undefined
 7c8:	756f635f 	.inst	0x756f635f ; undefined
 7cc:	6200746e 	.inst	0x6200746e ; undefined
 7d0:	73657479 	.inst	0x73657479 ; undefined
 7d4:	7265705f 	.inst	0x7265705f ; undefined
 7d8:	6365735f 	.inst	0x6365735f ; undefined
 7dc:	00726f74 	.inst	0x00726f74 ; undefined
 7e0:	73756c63 	.inst	0x73756c63 ; undefined
 7e4:	5f726574 	.inst	0x5f726574 ; undefined
 7e8:	65646e69 	fnmls	z9.h, p3/m, z19.h, z4.h
 7ec:	69640078 	ldpsw	x24, x0, [x3, #-224]
 7f0:	6e655f72 	uqrshl	v18.8h, v27.8h, v5.8h
 7f4:	00797274 	.inst	0x00797274 ; undefined
 7f8:	61645f6d 	.inst	0x61645f6d ; undefined
 7fc:	64006574 	.inst	0x64006574 ; undefined
 800:	65766972 	fnmls	z18.h, p2/m, z11.h, z22.h
 804:	6d756e5f 	ldp	d31, d27, [x18, #-176]
 808:	00726562 	.inst	0x00726562 ; undefined
 80c:	6964656d 	ldpsw	x13, x25, [x11, #-224]
 810:	79745f61 	ldrh	w1, [x27, #6702]
 814:	66006570 	.inst	0x66006570 ; undefined
 818:	656d6172 	fnmls	z18.h, p0/m, z11.h, z13.h
 81c:	61747300 	.inst	0x61747300 ; undefined
 820:	745f6b63 	.inst	0x745f6b63 ; undefined
 824:	6900706f 	stgp	x15, x28, [x3]
 828:	5f74696e 	.inst	0x5f74696e ; undefined
 82c:	72657375 	.inst	0x72657375 ; undefined
 830:	6f72705f 	fcmla	v31.8h, v2.8h, v18.h[1], #270
 834:	73736563 	.inst	0x73736563 ; undefined
 838:	64677000 	.inst	0x64677000 ; undefined
 83c:	0061765f 	.inst	0x0061765f ; undefined
 840:	6f6c6c61 	.inst	0x6f6c6c61 ; undefined
 844:	656e5f63 	fnmla	z3.h, p7/m, z27.h, z14.h
 848:	72705f77 	.inst	0x72705f77 ; undefined
 84c:	7365636f 	.inst	0x7365636f ; undefined
 850:	6d003273 	stp	d19, d12, [x19]
 854:	5f65766f 	sqshl	d15, d19, #37
 858:	755f6f74 	.inst	0x755f6f74 ; undefined
 85c:	5f726573 	.inst	0x5f726573 ; undefined
 860:	65646f6d 	fnmls	z13.h, p3/m, z27.h, z4.h
 864:	65727000 	fnmls	z0.h, p4/m, z0.h, z18.h
 868:	72705f76 	.inst	0x72705f76 ; undefined
 86c:	6b00636f 	subs	w15, w27, w0, lsl #24
 870:	65726874 	fnmls	z20.h, p2/m, z3.h, z18.h
 874:	00316461 	.inst	0x00316461 ; undefined
 878:	70617274 	adr	x20, c36c7 <MAIR_ATTR+0xbf2c7>
 87c:	7465725f 	.inst	0x7465725f ; undefined
 880:	006e7275 	.inst	0x006e7275 ; undefined
 884:	6b5f7369 	subs	w9, w27, wzr, lsr #28
 888:	656e7265 	fnmls	z5.h, p4/m, z19.h, z14.h
 88c:	64615f6c 	.inst	0x64615f6c ; undefined
 890:	73657264 	.inst	0x73657264 ; undefined
 894:	64690073 	fmla	z19.h, z3.h, z1.h[5]
 898:	745f656c 	.inst	0x745f656c ; undefined
 89c:	61657268 	.inst	0x61657268 ; undefined
 8a0:	65730064 	fmla	z4.h, p0/m, z3.h, z19.h
 8a4:	74745f74 	.inst	0x74745f74 ; undefined
 8a8:	00307262 	.inst	0x00307262 ; undefined
 8ac:	636f7270 	.inst	0x636f7270 ; undefined
 8b0:	5f737365 	sqdmlsl	s5, h27, v3.h[3]
 8b4:	6c626174 	ldnp	d20, d24, [x11, #-480]
 8b8:	6e690065 	uaddl2	v5.4s, v3.8h, v9.8h
 8bc:	695f7469 	ldpsw	x9, x29, [x3, #248]
 8c0:	5f656c64 	.inst	0x5f656c64 ; undefined
 8c4:	636f7270 	.inst	0x636f7270 ; undefined
 8c8:	00737365 	.inst	0x00737365 ; undefined
 8cc:	5f646970 	.inst	0x5f646970 ; undefined
 8d0:	006d756e 	.inst	0x006d756e ; undefined
 8d4:	72727563 	.inst	0x72727563 ; undefined
 8d8:	5f746e65 	.inst	0x5f746e65 ; undefined
 8dc:	636f7270 	.inst	0x636f7270 ; undefined
 8e0:	65727000 	fnmls	z0.h, p4/m, z0.h, z18.h
 8e4:	70665f76 	adr	x22, cd4d3 <MAIR_ATTR+0xc90d3>
 8e8:	61777300 	.inst	0x61777300 ; undefined
 8ec:	67700070 	.inst	0x67700070 ; undefined
 8f0:	61705f64 	.inst	0x61705f64 ; undefined
 8f4:	65726300 	fnmls	z0.h, p0/m, z24.h, z18.h
 8f8:	5f657461 	sqshl	d1, d3, #37
 8fc:	6e72656b 	umax	v11.8h, v11.8h, v18.8h
 900:	705f6c65 	adr	x5, bf68f <MAIR_ATTR+0xbb28f>
 904:	65636f72 	fnmls	z18.h, p3/m, z27.h, z3.h
 908:	64007373 	.inst	0x64007373 ; undefined
 90c:	5f706d75 	.inst	0x5f706d75 ; undefined
 910:	746e6f63 	.inst	0x746e6f63 ; undefined
 914:	00747865 	.inst	0x00747865 ; undefined
 918:	74706564 	.inst	0x74706564 ; undefined
 91c:	75640068 	cblo	w8, #8, 928 <_binary_init_bin_size+0x1e0>
 920:	625f706d 	.inst	0x625f706d ; undefined
 924:	746b6361 	.inst	0x746b6361 ; undefined
 928:	65636172 	fnmls	z18.h, p0/m, z11.h, z3.h
 92c:	75706300 	.inst	0x75706300 ; undefined
 930:	6e6f635f 	rsubhn2	v31.8h, v26.4s, v15.4s
 934:	74786574 	.inst	0x74786574 ; undefined
 938:	746e6500 	.inst	0x746e6500 ; undefined
 93c:	755f7265 	.inst	0x755f7265 ; undefined
 940:	00726573 	.inst	0x00726573 ; undefined
 944:	6f6c6c61 	.inst	0x6f6c6c61 ; undefined
 948:	656e5f63 	fnmla	z3.h, p7/m, z27.h, z14.h
 94c:	72705f77 	.inst	0x72705f77 ; undefined
 950:	7365636f 	.inst	0x7365636f ; undefined
 954:	72700073 	.inst	0x72700073 ; undefined
 958:	7365636f 	.inst	0x7365636f ; undefined
 95c:	6f635f73 	.inst	0x6f635f73 ; undefined
 960:	6f72746e 	uqshl	v14.2d, v3.2d, #50
 964:	7773006c 	.inst	0x7773006c ; undefined
 968:	68637469 	.inst	0x68637469 ; undefined
 96c:	6f72705f 	fcmla	v31.8h, v2.8h, v18.h[1], #270
 970:	73736563 	.inst	0x73736563 ; undefined
 974:	6e696600 	umax	v0.8h, v16.8h, v9.8h
 978:	6e755f64 	uqrshl	v4.8h, v27.8h, v21.8h
 97c:	64657375 	.inst	0x64657375 ; undefined
 980:	6f72705f 	fcmla	v31.8h, v2.8h, v18.h[1], #270
 984:	73736563 	.inst	0x73736563 ; undefined
 988:	74657200 	.inst	0x74657200 ; undefined
 98c:	6464615f 	.inst	0x6464615f ; undefined
 990:	79730072 	ldrh	w18, [x3, #6528]
 994:	6c735f73 	ldnp	d19, d23, [x27, #-208]
 998:	00706565 	.inst	0x00706565 ; undefined
 99c:	5f737973 	sqdmlsl	s19, h11, v3.h[7]
 9a0:	74697865 	.inst	0x74697865 ; undefined
 9a4:	73797300 	.inst	0x73797300 ; undefined
 9a8:	5f6d6574 	.inst	0x5f6d6574 ; undefined
 9ac:	6c6c6163 	ldnp	d3, d24, [x11, #-320]
 9b0:	6c6f0073 	ldnp	d19, d0, [x3, #-272]
 9b4:	69745f64 	ldpsw	x4, x23, [x27, #-96]
 9b8:	00736b63 	.inst	0x00736b63 ; undefined
 9bc:	65656c73 	fnmls	z19.h, p3/m, z3.h, z5.h
 9c0:	69745f70 	ldpsw	x16, x23, [x27, #-96]
 9c4:	00736b63 	.inst	0x00736b63 ; undefined
 9c8:	5f737973 	sqdmlsl	s19, h11, v3.h[7]
 9cc:	74696177 	.inst	0x74696177 ; undefined
 9d0:	73797300 	.inst	0x73797300 ; undefined
 9d4:	6972775f 	ldpsw	xzr, x29, [x26, #-112]
 9d8:	61006574 	.inst	0x61006574 ; undefined
 9dc:	74706772 	.inst	0x74706772 ; undefined
 9e0:	59530072 	ldapurh	w18, [x3, #-208]
 9e4:	4d455453 	.inst	0x4d455453 ; undefined
 9e8:	4c4c4143 	.inst	0x4c4c4143 ; undefined
 9ec:	72617000 	.inst	0x72617000 ; undefined
 9f0:	635f6d61 	.inst	0x635f6d61 ; undefined
 9f4:	746e756f 	.inst	0x746e756f ; undefined
	...

Disassembly of section .comment:

0000000000000000 <.comment>:
   0:	3a434347 	ccmn	w26, w3, #0x7, mi	// mi = first
   4:	4e472820 	trn1	v0.8h, v1.8h, v7.8h
   8:	31202955 	adds	w21, w10, #0x80a
   c:	2e312e36 	uqsub	v22.8b, v17.8b, v17.8b
  10:	Address 0x10 is out of bounds.


Disassembly of section .debug_frame:

0000000000000000 <.debug_frame>:
   0:	0000000c 	udf	#12
   4:	ffffffff 	.inst	0xffffffff ; undefined
   8:	78040001 	sturh	w1, [x0, #64]
   c:	001f0c1e 	.inst	0x001f0c1e ; undefined
  10:	00000024 	udf	#36
  14:	00000000 	udf	#0
  18:	00080110 	.inst	0x00080110 ; undefined
  1c:	ffff0000 	.inst	0xffff0000 ; undefined
  20:	0000005c 	udf	#92
  24:	00000000 	udf	#0
  28:	9d100e41 	.inst	0x9d100e41 ; undefined
  2c:	55019e02 	.inst	0x55019e02 ; undefined
  30:	000eddde 	.inst	0x000eddde ; undefined
  34:	00000000 	udf	#0
  38:	0000000c 	udf	#12
  3c:	ffffffff 	.inst	0xffffffff ; undefined
  40:	78040001 	sturh	w1, [x0, #64]
  44:	001f0c1e 	.inst	0x001f0c1e ; undefined
  48:	00000024 	udf	#36
  4c:	00000038 	udf	#56
  50:	00080224 	.inst	0x00080224 ; undefined
  54:	ffff0000 	.inst	0xffff0000 ; undefined
  58:	00000074 	udf	#116
  5c:	00000000 	udf	#0
  60:	9d200e41 	.inst	0x9d200e41 ; undefined
  64:	5b039e04 	.inst	0x5b039e04 ; undefined
  68:	000eddde 	.inst	0x000eddde ; undefined
  6c:	00000000 	udf	#0
  70:	00000024 	udf	#36
  74:	00000038 	udf	#56
  78:	00080298 	.inst	0x00080298 ; undefined
  7c:	ffff0000 	.inst	0xffff0000 ; undefined
  80:	0000006c 	udf	#108
  84:	00000000 	udf	#0
  88:	9d300e41 	.inst	0x9d300e41 ; undefined
  8c:	59059e06 	.inst	0x59059e06 ; undefined
  90:	000eddde 	.inst	0x000eddde ; undefined
  94:	00000000 	udf	#0
  98:	0000001c 	udf	#28
  9c:	00000038 	udf	#56
  a0:	00080304 	.inst	0x00080304 ; undefined
  a4:	ffff0000 	.inst	0xffff0000 ; undefined
  a8:	00000024 	udf	#36
  ac:	00000000 	udf	#0
  b0:	47100e41 	.inst	0x47100e41 ; undefined
  b4:	0000000e 	udf	#14
  b8:	0000001c 	udf	#28
  bc:	00000038 	udf	#56
  c0:	00080328 	.inst	0x00080328 ; undefined
  c4:	ffff0000 	.inst	0xffff0000 ; undefined
  c8:	000000c4 	udf	#196
  cc:	00000000 	udf	#0
  d0:	6f300e41 	.inst	0x6f300e41 ; undefined
  d4:	0000000e 	udf	#14
  d8:	0000000c 	udf	#12
  dc:	ffffffff 	.inst	0xffffffff ; undefined
  e0:	78040001 	sturh	w1, [x0, #64]
  e4:	001f0c1e 	.inst	0x001f0c1e ; undefined
  e8:	00000024 	udf	#36
  ec:	000000d8 	udf	#216
  f0:	000803ec 	.inst	0x000803ec ; undefined
  f4:	ffff0000 	.inst	0xffff0000 ; undefined
  f8:	00000050 	udf	#80
  fc:	00000000 	udf	#0
 100:	9d200e41 	.inst	0x9d200e41 ; undefined
 104:	52039e04 	eor	w4, w16, #0xe01fe01f
 108:	000eddde 	.inst	0x000eddde ; undefined
 10c:	00000000 	udf	#0
 110:	00000024 	udf	#36
 114:	000000d8 	udf	#216
 118:	0008043c 	.inst	0x0008043c ; undefined
 11c:	ffff0000 	.inst	0xffff0000 ; undefined
 120:	00000024 	udf	#36
 124:	00000000 	udf	#0
 128:	9d100e41 	.inst	0x9d100e41 ; undefined
 12c:	47019e02 	.inst	0x47019e02 ; undefined
 130:	000eddde 	.inst	0x000eddde ; undefined
 134:	00000000 	udf	#0
 138:	00000024 	udf	#36
 13c:	000000d8 	udf	#216
 140:	00080460 	.inst	0x00080460 ; undefined
 144:	ffff0000 	.inst	0xffff0000 ; undefined
 148:	0000005c 	udf	#92
 14c:	00000000 	udf	#0
 150:	9d300e41 	.inst	0x9d300e41 ; undefined
 154:	55059e06 	.inst	0x55059e06 ; undefined
 158:	000eddde 	.inst	0x000eddde ; undefined
 15c:	00000000 	udf	#0
 160:	00000024 	udf	#36
 164:	000000d8 	udf	#216
 168:	000804bc 	.inst	0x000804bc ; undefined
 16c:	ffff0000 	.inst	0xffff0000 ; undefined
 170:	00000078 	udf	#120
 174:	00000000 	udf	#0
 178:	9d200e41 	.inst	0x9d200e41 ; undefined
 17c:	5c039e04 	ldr	d4, 753c <MAIR_ATTR+0x313c>
 180:	000eddde 	.inst	0x000eddde ; undefined
 184:	00000000 	udf	#0
 188:	00000024 	udf	#36
 18c:	000000d8 	udf	#216
 190:	00080534 	.inst	0x00080534 ; undefined
 194:	ffff0000 	.inst	0xffff0000 ; undefined
 198:	00000134 	udf	#308
 19c:	00000000 	udf	#0
 1a0:	9d200e41 	.inst	0x9d200e41 ; undefined
 1a4:	02039e04 	.inst	0x02039e04 ; undefined
 1a8:	0eddde4b 	.inst	0x0eddde4b ; undefined
 1ac:	00000000 	udf	#0
 1b0:	0000000c 	udf	#12
 1b4:	ffffffff 	.inst	0xffffffff ; undefined
 1b8:	78040001 	sturh	w1, [x0, #64]
 1bc:	001f0c1e 	.inst	0x001f0c1e ; undefined
 1c0:	0000001c 	udf	#28
 1c4:	000001b0 	udf	#432
 1c8:	00080668 	.inst	0x00080668 ; undefined
 1cc:	ffff0000 	.inst	0xffff0000 ; undefined
 1d0:	00000078 	udf	#120
 1d4:	00000000 	udf	#0
 1d8:	5c300e41 	ldr	d1, 603a0 <MAIR_ATTR+0x5bfa0>
 1dc:	0000000e 	udf	#14
 1e0:	0000001c 	udf	#28
 1e4:	000001b0 	udf	#432
 1e8:	000806e0 	.inst	0x000806e0 ; undefined
 1ec:	ffff0000 	.inst	0xffff0000 ; undefined
 1f0:	000000e4 	udf	#228
 1f4:	00000000 	udf	#0
 1f8:	77600e41 	.inst	0x77600e41 ; undefined
 1fc:	0000000e 	udf	#14
 200:	0000001c 	udf	#28
 204:	000001b0 	udf	#432
 208:	000807c4 	.inst	0x000807c4 ; undefined
 20c:	ffff0000 	.inst	0xffff0000 ; undefined
 210:	000000f8 	udf	#248
 214:	00000000 	udf	#0
 218:	7c600e41 	.inst	0x7c600e41 ; undefined
 21c:	0000000e 	udf	#14
 220:	00000024 	udf	#36
 224:	000001b0 	udf	#432
 228:	000808bc 	.inst	0x000808bc ; undefined
 22c:	ffff0000 	.inst	0xffff0000 ; undefined
 230:	00000088 	udf	#136
 234:	00000000 	udf	#0
 238:	9d400e41 	.inst	0x9d400e41 ; undefined
 23c:	60079e08 	.inst	0x60079e08 ; undefined
 240:	000eddde 	.inst	0x000eddde ; undefined
 244:	00000000 	udf	#0
 248:	00000024 	udf	#36
 24c:	000001b0 	udf	#432
 250:	00080944 	.inst	0x00080944 ; undefined
 254:	ffff0000 	.inst	0xffff0000 ; undefined
 258:	00000058 	udf	#88
 25c:	00000000 	udf	#0
 260:	9d300e41 	.inst	0x9d300e41 ; undefined
 264:	54059e06 	b.vs	b624 <MAIR_ATTR+0x7224>
 268:	000eddde 	.inst	0x000eddde ; undefined
 26c:	00000000 	udf	#0
 270:	0000002c 	udf	#44
 274:	000001b0 	udf	#432
 278:	0008099c 	.inst	0x0008099c ; undefined
 27c:	ffff0000 	.inst	0xffff0000 ; undefined
 280:	00000358 	udf	#856
 284:	00000000 	udf	#0
 288:	09a00e41 	.inst	0x09a00e41 ; undefined
 28c:	01949d41 	.inst	0x01949d41 ; undefined
 290:	0201939e 	.inst	0x0201939e ; undefined
 294:	0ededdd3 	.inst	0x0ededdd3 ; undefined
	...
 2a0:	0000000c 	udf	#12
 2a4:	ffffffff 	.inst	0xffffffff ; undefined
 2a8:	78040001 	sturh	w1, [x0, #64]
 2ac:	001f0c1e 	.inst	0x001f0c1e ; undefined
 2b0:	0000001c 	udf	#28
 2b4:	000002a0 	udf	#672
 2b8:	00080cf4 	.inst	0x00080cf4 ; undefined
 2bc:	ffff0000 	.inst	0xffff0000 ; undefined
 2c0:	00000050 	udf	#80
 2c4:	00000000 	udf	#0
 2c8:	9d200e41 	.inst	0x9d200e41 ; undefined
 2cc:	00039e04 	.inst	0x00039e04 ; undefined
 2d0:	0000000c 	udf	#12
 2d4:	ffffffff 	.inst	0xffffffff ; undefined
 2d8:	78040001 	sturh	w1, [x0, #64]
 2dc:	001f0c1e 	.inst	0x001f0c1e ; undefined
 2e0:	00000014 	udf	#20
 2e4:	000002d0 	udf	#720
 2e8:	00081a0c 	.inst	0x00081a0c ; undefined
 2ec:	ffff0000 	.inst	0xffff0000 ; undefined
 2f0:	00000010 	udf	#16
 2f4:	00000000 	udf	#0
 2f8:	00000024 	udf	#36
 2fc:	000002d0 	udf	#720
 300:	00081a1c 	.inst	0x00081a1c ; undefined
 304:	ffff0000 	.inst	0xffff0000 ; undefined
 308:	00000064 	udf	#100
 30c:	00000000 	udf	#0
 310:	9d100e41 	.inst	0x9d100e41 ; undefined
 314:	57019e02 	.inst	0x57019e02 ; undefined
 318:	000eddde 	.inst	0x000eddde ; undefined
 31c:	00000000 	udf	#0
 320:	00000024 	udf	#36
 324:	000002d0 	udf	#720
 328:	00081a80 	.inst	0x00081a80 ; undefined
 32c:	ffff0000 	.inst	0xffff0000 ; undefined
 330:	00000054 	udf	#84
 334:	00000000 	udf	#0
 338:	9d100e41 	.inst	0x9d100e41 ; undefined
 33c:	53019e02 	.inst	0x53019e02 ; undefined
 340:	000eddde 	.inst	0x000eddde ; undefined
 344:	00000000 	udf	#0
 348:	00000024 	udf	#36
 34c:	000002d0 	udf	#720
 350:	00081ad4 	.inst	0x00081ad4 ; undefined
 354:	ffff0000 	.inst	0xffff0000 ; undefined
 358:	000000e0 	udf	#224
 35c:	00000000 	udf	#0
 360:	9d400e41 	.inst	0x9d400e41 ; undefined
 364:	76079e08 	.inst	0x76079e08 ; undefined
 368:	000eddde 	.inst	0x000eddde ; undefined
 36c:	00000000 	udf	#0
 370:	00000024 	udf	#36
 374:	000002d0 	udf	#720
 378:	00081bb4 	.inst	0x00081bb4 ; undefined
 37c:	ffff0000 	.inst	0xffff0000 ; undefined
 380:	00000060 	udf	#96
 384:	00000000 	udf	#0
 388:	9d200e41 	.inst	0x9d200e41 ; undefined
 38c:	56039e04 	.inst	0x56039e04 ; undefined
 390:	000eddde 	.inst	0x000eddde ; undefined
 394:	00000000 	udf	#0
 398:	00000024 	udf	#36
 39c:	000002d0 	udf	#720
 3a0:	00081c14 	.inst	0x00081c14 ; undefined
 3a4:	ffff0000 	.inst	0xffff0000 ; undefined
 3a8:	00000020 	udf	#32
 3ac:	00000000 	udf	#0
 3b0:	9d100e41 	.inst	0x9d100e41 ; undefined
 3b4:	46019e02 	.inst	0x46019e02 ; undefined
 3b8:	000eddde 	.inst	0x000eddde ; undefined
 3bc:	00000000 	udf	#0
 3c0:	00000024 	udf	#36
 3c4:	000002d0 	udf	#720
 3c8:	00081c34 	.inst	0x00081c34 ; undefined
 3cc:	ffff0000 	.inst	0xffff0000 ; undefined
 3d0:	00000108 	udf	#264
 3d4:	00000000 	udf	#0
 3d8:	9d300e41 	.inst	0x9d300e41 ; undefined
 3dc:	02059e06 	.inst	0x02059e06 ; undefined
 3e0:	0eddde40 	.inst	0x0eddde40 ; undefined
 3e4:	00000000 	udf	#0
 3e8:	0000000c 	udf	#12
 3ec:	ffffffff 	.inst	0xffffffff ; undefined
 3f0:	78040001 	sturh	w1, [x0, #64]
 3f4:	001f0c1e 	.inst	0x001f0c1e ; undefined
 3f8:	00000024 	udf	#36
 3fc:	000003e8 	udf	#1000
 400:	0008a010 	.inst	0x0008a010 ; undefined
 404:	ffff0000 	.inst	0xffff0000 ; undefined
 408:	00000078 	udf	#120
 40c:	00000000 	udf	#0
 410:	9d300e41 	.inst	0x9d300e41 ; undefined
 414:	5c059e06 	ldr	d6, b7d4 <MAIR_ATTR+0x73d4>
 418:	000eddde 	.inst	0x000eddde ; undefined
 41c:	00000000 	udf	#0
 420:	00000024 	udf	#36
 424:	000003e8 	udf	#1000
 428:	0008a088 	.inst	0x0008a088 ; undefined
 42c:	ffff0000 	.inst	0xffff0000 ; undefined
 430:	000000b0 	udf	#176
 434:	00000000 	udf	#0
 438:	9d300e41 	.inst	0x9d300e41 ; undefined
 43c:	6a059e06 	.inst	0x6a059e06 ; undefined
 440:	000eddde 	.inst	0x000eddde ; undefined
 444:	00000000 	udf	#0
 448:	00000024 	udf	#36
 44c:	000003e8 	udf	#1000
 450:	0008a138 	.inst	0x0008a138 ; undefined
 454:	ffff0000 	.inst	0xffff0000 ; undefined
 458:	000000b0 	udf	#176
 45c:	00000000 	udf	#0
 460:	9d200e41 	.inst	0x9d200e41 ; undefined
 464:	6a039e04 	.inst	0x6a039e04 ; undefined
 468:	000eddde 	.inst	0x000eddde ; undefined
 46c:	00000000 	udf	#0
 470:	00000024 	udf	#36
 474:	000003e8 	udf	#1000
 478:	0008a1e8 	.inst	0x0008a1e8 ; undefined
 47c:	ffff0000 	.inst	0xffff0000 ; undefined
 480:	0000008c 	udf	#140
 484:	00000000 	udf	#0
 488:	9d300e41 	.inst	0x9d300e41 ; undefined
 48c:	61059e06 	.inst	0x61059e06 ; undefined
 490:	000eddde 	.inst	0x000eddde ; undefined
 494:	00000000 	udf	#0
 498:	00000024 	udf	#36
 49c:	000003e8 	udf	#1000
 4a0:	0008a274 	.inst	0x0008a274 ; undefined
 4a4:	ffff0000 	.inst	0xffff0000 ; undefined
 4a8:	000000e4 	udf	#228
 4ac:	00000000 	udf	#0
 4b0:	9d500e41 	.inst	0x9d500e41 ; undefined
 4b4:	77099e0a 	.inst	0x77099e0a ; undefined
 4b8:	000eddde 	.inst	0x000eddde ; undefined
 4bc:	00000000 	udf	#0
 4c0:	00000024 	udf	#36
 4c4:	000003e8 	udf	#1000
 4c8:	0008a358 	.inst	0x0008a358 ; undefined
 4cc:	ffff0000 	.inst	0xffff0000 ; undefined
 4d0:	0000010c 	udf	#268
 4d4:	00000000 	udf	#0
 4d8:	9d500e41 	.inst	0x9d500e41 ; undefined
 4dc:	02099e0a 	.inst	0x02099e0a ; undefined
 4e0:	0eddde41 	.inst	0x0eddde41 ; undefined
 4e4:	00000000 	udf	#0
 4e8:	00000024 	udf	#36
 4ec:	000003e8 	udf	#1000
 4f0:	0008a464 	.inst	0x0008a464 ; undefined
 4f4:	ffff0000 	.inst	0xffff0000 ; undefined
 4f8:	0000012c 	udf	#300
 4fc:	00000000 	udf	#0
 500:	9d500e41 	.inst	0x9d500e41 ; undefined
 504:	02099e0a 	.inst	0x02099e0a ; undefined
 508:	0eddde49 	.inst	0x0eddde49 ; undefined
 50c:	00000000 	udf	#0
 510:	00000024 	udf	#36
 514:	000003e8 	udf	#1000
 518:	0008a590 	.inst	0x0008a590 ; undefined
 51c:	ffff0000 	.inst	0xffff0000 ; undefined
 520:	000000cc 	udf	#204
 524:	00000000 	udf	#0
 528:	9d300e41 	.inst	0x9d300e41 ; undefined
 52c:	71059e06 	subs	w6, w16, #0x167
 530:	000eddde 	.inst	0x000eddde ; undefined
 534:	00000000 	udf	#0
 538:	00000024 	udf	#36
 53c:	000003e8 	udf	#1000
 540:	0008a65c 	.inst	0x0008a65c ; undefined
 544:	ffff0000 	.inst	0xffff0000 ; undefined
 548:	00000104 	udf	#260
 54c:	00000000 	udf	#0
 550:	9d400e41 	.inst	0x9d400e41 ; undefined
 554:	7f079e08 	.inst	0x7f079e08 ; undefined
 558:	000eddde 	.inst	0x000eddde ; undefined
 55c:	00000000 	udf	#0
 560:	00000024 	udf	#36
 564:	000003e8 	udf	#1000
 568:	0008a760 	.inst	0x0008a760 ; undefined
 56c:	ffff0000 	.inst	0xffff0000 ; undefined
 570:	0000009c 	udf	#156
 574:	00000000 	udf	#0
 578:	9d300e41 	.inst	0x9d300e41 ; undefined
 57c:	65059e06 	bfminnm	z6.h, p7/m, z6.h, z16.h
 580:	000eddde 	.inst	0x000eddde ; undefined
 584:	00000000 	udf	#0
 588:	00000024 	udf	#36
 58c:	000003e8 	udf	#1000
 590:	0008a7fc 	.inst	0x0008a7fc ; undefined
 594:	ffff0000 	.inst	0xffff0000 ; undefined
 598:	00000020 	udf	#32
 59c:	00000000 	udf	#0
 5a0:	9d200e41 	.inst	0x9d200e41 ; undefined
 5a4:	46039e04 	.inst	0x46039e04 ; undefined
 5a8:	000eddde 	.inst	0x000eddde ; undefined
 5ac:	00000000 	udf	#0
 5b0:	00000024 	udf	#36
 5b4:	000003e8 	udf	#1000
 5b8:	0008a81c 	.inst	0x0008a81c ; undefined
 5bc:	ffff0000 	.inst	0xffff0000 ; undefined
 5c0:	0000003c 	udf	#60
 5c4:	00000000 	udf	#0
 5c8:	9d200e41 	.inst	0x9d200e41 ; undefined
 5cc:	4d039e04 	.inst	0x4d039e04 ; undefined
 5d0:	000eddde 	.inst	0x000eddde ; undefined
 5d4:	00000000 	udf	#0
 5d8:	00000024 	udf	#36
 5dc:	000003e8 	udf	#1000
 5e0:	0008a858 	.inst	0x0008a858 ; undefined
 5e4:	ffff0000 	.inst	0xffff0000 ; undefined
 5e8:	0000004c 	udf	#76
 5ec:	00000000 	udf	#0
 5f0:	9d300e41 	.inst	0x9d300e41 ; undefined
 5f4:	51059e06 	sub	w6, w16, #0x167
 5f8:	000eddde 	.inst	0x000eddde ; undefined
 5fc:	00000000 	udf	#0
 600:	00000024 	udf	#36
 604:	000003e8 	udf	#1000
 608:	0008a8a4 	.inst	0x0008a8a4 ; undefined
 60c:	ffff0000 	.inst	0xffff0000 ; undefined
 610:	000000b0 	udf	#176
 614:	00000000 	udf	#0
 618:	9d300e41 	.inst	0x9d300e41 ; undefined
 61c:	6a059e06 	.inst	0x6a059e06 ; undefined
 620:	000eddde 	.inst	0x000eddde ; undefined
 624:	00000000 	udf	#0
 628:	00000024 	udf	#36
 62c:	000003e8 	udf	#1000
 630:	0008a954 	.inst	0x0008a954 ; undefined
 634:	ffff0000 	.inst	0xffff0000 ; undefined
 638:	00000028 	udf	#40
 63c:	00000000 	udf	#0
 640:	9d200e41 	.inst	0x9d200e41 ; undefined
 644:	48039e04 	stlxrh	w3, w4, [x16]
 648:	000eddde 	.inst	0x000eddde ; undefined
 64c:	00000000 	udf	#0
 650:	00000024 	udf	#36
 654:	000003e8 	udf	#1000
 658:	0008a97c 	.inst	0x0008a97c ; undefined
 65c:	ffff0000 	.inst	0xffff0000 ; undefined
 660:	0000003c 	udf	#60
 664:	00000000 	udf	#0
 668:	9d100e41 	.inst	0x9d100e41 ; undefined
 66c:	4d019e02 	.inst	0x4d019e02 ; undefined
 670:	000eddde 	.inst	0x000eddde ; undefined
 674:	00000000 	udf	#0
 678:	0000000c 	udf	#12
 67c:	ffffffff 	.inst	0xffffffff ; undefined
 680:	78040001 	sturh	w1, [x0, #64]
 684:	001f0c1e 	.inst	0x001f0c1e ; undefined
 688:	0000001c 	udf	#28
 68c:	00000678 	udf	#1656
 690:	0008a9b8 	.inst	0x0008a9b8 ; undefined
 694:	ffff0000 	.inst	0xffff0000 ; undefined
 698:	00000038 	udf	#56
 69c:	00000000 	udf	#0
 6a0:	4c100e41 	.inst	0x4c100e41 ; undefined
 6a4:	0000000e 	udf	#14
 6a8:	00000024 	udf	#36
 6ac:	00000678 	udf	#1656
 6b0:	0008a9f0 	.inst	0x0008a9f0 ; undefined
 6b4:	ffff0000 	.inst	0xffff0000 ; undefined
 6b8:	00000040 	udf	#64
 6bc:	00000000 	udf	#0
 6c0:	9d200e41 	.inst	0x9d200e41 ; undefined
 6c4:	4e039e04 	.inst	0x4e039e04 ; undefined
 6c8:	000eddde 	.inst	0x000eddde ; undefined
 6cc:	00000000 	udf	#0
 6d0:	00000024 	udf	#36
 6d4:	00000678 	udf	#1656
 6d8:	0008aa30 	.inst	0x0008aa30 ; undefined
 6dc:	ffff0000 	.inst	0xffff0000 ; undefined
 6e0:	00000034 	udf	#52
 6e4:	00000000 	udf	#0
 6e8:	9d300e41 	.inst	0x9d300e41 ; undefined
 6ec:	4b059e06 	.inst	0x4b059e06 ; undefined
 6f0:	000eddde 	.inst	0x000eddde ; undefined
 6f4:	00000000 	udf	#0
 6f8:	00000024 	udf	#36
 6fc:	00000678 	udf	#1656
 700:	0008aa64 	.inst	0x0008aa64 ; undefined
 704:	ffff0000 	.inst	0xffff0000 ; undefined
 708:	000000c8 	udf	#200
 70c:	00000000 	udf	#0
 710:	9d400e41 	.inst	0x9d400e41 ; undefined
 714:	70079e08 	adr	x8, fad7 <MAIR_ATTR+0xb6d7>
 718:	000eddde 	.inst	0x000eddde ; undefined
 71c:	00000000 	udf	#0
 720:	00000024 	udf	#36
 724:	00000678 	udf	#1656
 728:	0008ab2c 	.inst	0x0008ab2c ; undefined
 72c:	ffff0000 	.inst	0xffff0000 ; undefined
 730:	00000030 	udf	#48
 734:	00000000 	udf	#0
 738:	9d200e41 	.inst	0x9d200e41 ; undefined
 73c:	4a039e04 	.inst	0x4a039e04 ; undefined
 740:	000eddde 	.inst	0x000eddde ; undefined
 744:	00000000 	udf	#0
 748:	00000024 	udf	#36
 74c:	00000678 	udf	#1656
 750:	0008ab5c 	.inst	0x0008ab5c ; undefined
 754:	ffff0000 	.inst	0xffff0000 ; undefined
 758:	00000020 	udf	#32
 75c:	00000000 	udf	#0
 760:	9d200e41 	.inst	0x9d200e41 ; undefined
 764:	46039e04 	.inst	0x46039e04 ; undefined
 768:	000eddde 	.inst	0x000eddde ; undefined
 76c:	00000000 	udf	#0
 770:	00000024 	udf	#36
 774:	00000678 	udf	#1656
 778:	0008ab7c 	.inst	0x0008ab7c ; undefined
 77c:	ffff0000 	.inst	0xffff0000 ; undefined
 780:	0000005c 	udf	#92
 784:	00000000 	udf	#0
 788:	9d200e41 	.inst	0x9d200e41 ; undefined
 78c:	55039e04 	.inst	0x55039e04 ; undefined
 790:	000eddde 	.inst	0x000eddde ; undefined
 794:	00000000 	udf	#0
 798:	00000024 	udf	#36
 79c:	00000678 	udf	#1656
 7a0:	0008abd8 	.inst	0x0008abd8 ; undefined
 7a4:	ffff0000 	.inst	0xffff0000 ; undefined
 7a8:	00000060 	udf	#96
 7ac:	00000000 	udf	#0
 7b0:	9d400e41 	.inst	0x9d400e41 ; undefined
 7b4:	56079e08 	.inst	0x56079e08 ; undefined
 7b8:	000eddde 	.inst	0x000eddde ; undefined
 7bc:	00000000 	udf	#0
 7c0:	0000001c 	udf	#28
 7c4:	00000678 	udf	#1656
 7c8:	0008ac38 	.inst	0x0008ac38 ; undefined
 7cc:	ffff0000 	.inst	0xffff0000 ; undefined
 7d0:	00000174 	udf	#372
 7d4:	00000000 	udf	#0
 7d8:	02300e41 	.inst	0x02300e41 ; undefined
 7dc:	00000e5b 	udf	#3675
 7e0:	00000024 	udf	#36
 7e4:	00000678 	udf	#1656
 7e8:	0008adac 	.inst	0x0008adac ; undefined
 7ec:	ffff0000 	.inst	0xffff0000 ; undefined
 7f0:	00000130 	udf	#304
 7f4:	00000000 	udf	#0
 7f8:	9d500e41 	.inst	0x9d500e41 ; undefined
 7fc:	02099e0a 	.inst	0x02099e0a ; undefined
 800:	0eddde4a 	.inst	0x0eddde4a ; undefined
 804:	00000000 	udf	#0
 808:	00000024 	udf	#36
 80c:	00000678 	udf	#1656
 810:	0008aedc 	.inst	0x0008aedc ; undefined
 814:	ffff0000 	.inst	0xffff0000 ; undefined
 818:	000000f0 	udf	#240
 81c:	00000000 	udf	#0
 820:	9d400e41 	.inst	0x9d400e41 ; undefined
 824:	7a079e08 	.inst	0x7a079e08 ; undefined
 828:	000eddde 	.inst	0x000eddde ; undefined
 82c:	00000000 	udf	#0
 830:	00000024 	udf	#36
 834:	00000678 	udf	#1656
 838:	0008afcc 	.inst	0x0008afcc ; undefined
 83c:	ffff0000 	.inst	0xffff0000 ; undefined
 840:	0000002c 	udf	#44
 844:	00000000 	udf	#0
 848:	9d200e41 	.inst	0x9d200e41 ; undefined
 84c:	49039e04 	.inst	0x49039e04 ; undefined
 850:	000eddde 	.inst	0x000eddde ; undefined
 854:	00000000 	udf	#0
 858:	00000024 	udf	#36
 85c:	00000678 	udf	#1656
 860:	0008aff8 	.inst	0x0008aff8 ; undefined
 864:	ffff0000 	.inst	0xffff0000 ; undefined
 868:	0000009c 	udf	#156
 86c:	00000000 	udf	#0
 870:	9d400e41 	.inst	0x9d400e41 ; undefined
 874:	65079e08 	bfmin	z8.h, p7/m, z8.h, z16.h
 878:	000eddde 	.inst	0x000eddde ; undefined
 87c:	00000000 	udf	#0
 880:	00000024 	udf	#36
 884:	00000678 	udf	#1656
 888:	0008b094 	.inst	0x0008b094 ; undefined
 88c:	ffff0000 	.inst	0xffff0000 ; undefined
 890:	00000060 	udf	#96
 894:	00000000 	udf	#0
 898:	9d200e41 	.inst	0x9d200e41 ; undefined
 89c:	56039e04 	.inst	0x56039e04 ; undefined
 8a0:	000eddde 	.inst	0x000eddde ; undefined
 8a4:	00000000 	udf	#0
 8a8:	0000000c 	udf	#12
 8ac:	ffffffff 	.inst	0xffffffff ; undefined
 8b0:	78040001 	sturh	w1, [x0, #64]
 8b4:	001f0c1e 	.inst	0x001f0c1e ; undefined
 8b8:	00000014 	udf	#20
 8bc:	000008a8 	udf	#2216
 8c0:	0008b0f4 	.inst	0x0008b0f4 ; undefined
 8c4:	ffff0000 	.inst	0xffff0000 ; undefined
 8c8:	0000000c 	udf	#12
 8cc:	00000000 	udf	#0
 8d0:	0000001c 	udf	#28
 8d4:	000008a8 	udf	#2216
 8d8:	0008b100 	.inst	0x0008b100 ; undefined
 8dc:	ffff0000 	.inst	0xffff0000 ; undefined
 8e0:	00000078 	udf	#120
 8e4:	00000000 	udf	#0
 8e8:	5c100e41 	ldr	d1, 20ab0 <MAIR_ATTR+0x1c6b0>
 8ec:	0000000e 	udf	#14
 8f0:	0000001c 	udf	#28
 8f4:	000008a8 	udf	#2216
 8f8:	0008b178 	.inst	0x0008b178 ; undefined
 8fc:	ffff0000 	.inst	0xffff0000 ; undefined
 900:	00000020 	udf	#32
 904:	00000000 	udf	#0
 908:	9d100e41 	.inst	0x9d100e41 ; undefined
 90c:	00019e02 	.inst	0x00019e02 ; undefined
 910:	00000024 	udf	#36
 914:	000008a8 	udf	#2216
 918:	0008b198 	.inst	0x0008b198 ; undefined
 91c:	ffff0000 	.inst	0xffff0000 ; undefined
 920:	0000012c 	udf	#300
 924:	00000000 	udf	#0
 928:	9d200e41 	.inst	0x9d200e41 ; undefined
 92c:	02039e04 	.inst	0x02039e04 ; undefined
 930:	0eddde49 	.inst	0x0eddde49 ; undefined
 934:	00000000 	udf	#0
 938:	00000024 	udf	#36
 93c:	000008a8 	udf	#2216
 940:	0008b2c4 	.inst	0x0008b2c4 ; undefined
 944:	ffff0000 	.inst	0xffff0000 ; undefined
 948:	0000017c 	udf	#380
 94c:	00000000 	udf	#0
 950:	9d200e41 	.inst	0x9d200e41 ; undefined
 954:	02039e04 	.inst	0x02039e04 ; undefined
 958:	0eddde5d 	.inst	0x0eddde5d ; undefined
 95c:	00000000 	udf	#0
 960:	00000024 	udf	#36
 964:	000008a8 	udf	#2216
 968:	0008b440 	.inst	0x0008b440 ; undefined
 96c:	ffff0000 	.inst	0xffff0000 ; undefined
 970:	000000a4 	udf	#164
 974:	00000000 	udf	#0
 978:	9d300e41 	.inst	0x9d300e41 ; undefined
 97c:	67059e06 	.inst	0x67059e06 ; undefined
 980:	000eddde 	.inst	0x000eddde ; undefined
 984:	00000000 	udf	#0
 988:	00000024 	udf	#36
 98c:	000008a8 	udf	#2216
 990:	0008b4e4 	.inst	0x0008b4e4 ; undefined
 994:	ffff0000 	.inst	0xffff0000 ; undefined
 998:	0000012c 	udf	#300
 99c:	00000000 	udf	#0
 9a0:	9d300e41 	.inst	0x9d300e41 ; undefined
 9a4:	02059e06 	.inst	0x02059e06 ; undefined
 9a8:	0eddde49 	.inst	0x0eddde49 ; undefined
 9ac:	00000000 	udf	#0
 9b0:	00000024 	udf	#36
 9b4:	000008a8 	udf	#2216
 9b8:	0008b610 	.inst	0x0008b610 ; undefined
 9bc:	ffff0000 	.inst	0xffff0000 ; undefined
 9c0:	000000a8 	udf	#168
 9c4:	00000000 	udf	#0
 9c8:	9d400e41 	.inst	0x9d400e41 ; undefined
 9cc:	68079e08 	.inst	0x68079e08 ; undefined
 9d0:	000eddde 	.inst	0x000eddde ; undefined
 9d4:	00000000 	udf	#0
 9d8:	0000001c 	udf	#28
 9dc:	000008a8 	udf	#2216
 9e0:	0008b6b8 	.inst	0x0008b6b8 ; undefined
 9e4:	ffff0000 	.inst	0xffff0000 ; undefined
 9e8:	0000003c 	udf	#60
 9ec:	00000000 	udf	#0
 9f0:	4d200e41 	st2	{v1.b-v2.b}[11], [x18]
 9f4:	0000000e 	udf	#14
 9f8:	0000001c 	udf	#28
 9fc:	000008a8 	udf	#2216
 a00:	0008b6f4 	.inst	0x0008b6f4 ; undefined
 a04:	ffff0000 	.inst	0xffff0000 ; undefined
 a08:	000000ec 	udf	#236
 a0c:	00000000 	udf	#0
 a10:	9d300e41 	.inst	0x9d300e41 ; undefined
 a14:	00059e06 	.inst	0x00059e06 ; undefined
 a18:	00000024 	udf	#36
 a1c:	000008a8 	udf	#2216
 a20:	0008b7e0 	.inst	0x0008b7e0 ; undefined
 a24:	ffff0000 	.inst	0xffff0000 ; undefined
 a28:	0000002c 	udf	#44
 a2c:	00000000 	udf	#0
 a30:	9d100e41 	.inst	0x9d100e41 ; undefined
 a34:	49019e02 	.inst	0x49019e02 ; undefined
 a38:	000eddde 	.inst	0x000eddde ; undefined
 a3c:	00000000 	udf	#0
 a40:	00000024 	udf	#36
 a44:	000008a8 	udf	#2216
 a48:	0008b80c 	.inst	0x0008b80c ; undefined
 a4c:	ffff0000 	.inst	0xffff0000 ; undefined
 a50:	00000028 	udf	#40
 a54:	00000000 	udf	#0
 a58:	9d100e41 	.inst	0x9d100e41 ; undefined
 a5c:	48019e02 	stlxrh	w1, w2, [x16]
 a60:	000eddde 	.inst	0x000eddde ; undefined
 a64:	00000000 	udf	#0
 a68:	00000024 	udf	#36
 a6c:	000008a8 	udf	#2216
 a70:	0008b834 	.inst	0x0008b834 ; undefined
 a74:	ffff0000 	.inst	0xffff0000 ; undefined
 a78:	00000044 	udf	#68
 a7c:	00000000 	udf	#0
 a80:	9d200e41 	.inst	0x9d200e41 ; undefined
 a84:	4f039e04 	.inst	0x4f039e04 ; undefined
 a88:	000eddde 	.inst	0x000eddde ; undefined
 a8c:	00000000 	udf	#0
 a90:	00000024 	udf	#36
 a94:	000008a8 	udf	#2216
 a98:	0008b878 	.inst	0x0008b878 ; undefined
 a9c:	ffff0000 	.inst	0xffff0000 ; undefined
 aa0:	00000224 	udf	#548
 aa4:	00000000 	udf	#0
 aa8:	9d300e41 	.inst	0x9d300e41 ; undefined
 aac:	02059e06 	.inst	0x02059e06 ; undefined
 ab0:	0eddde87 	.inst	0x0eddde87 ; undefined
 ab4:	00000000 	udf	#0
 ab8:	00000024 	udf	#36
 abc:	000008a8 	udf	#2216
 ac0:	0008ba9c 	.inst	0x0008ba9c ; undefined
 ac4:	ffff0000 	.inst	0xffff0000 ; undefined
 ac8:	000000ac 	udf	#172
 acc:	00000000 	udf	#0
 ad0:	9d400e41 	.inst	0x9d400e41 ; undefined
 ad4:	69079e08 	stgp	x8, x7, [x16, #240]
 ad8:	000eddde 	.inst	0x000eddde ; undefined
 adc:	00000000 	udf	#0
 ae0:	0000001c 	udf	#28
 ae4:	000008a8 	udf	#2216
 ae8:	0008bb48 	.inst	0x0008bb48 ; undefined
 aec:	ffff0000 	.inst	0xffff0000 ; undefined
 af0:	00000028 	udf	#40
 af4:	00000000 	udf	#0
 af8:	48100e41 	stxrh	w16, w1, [x18]
 afc:	0000000e 	udf	#14
 b00:	00000024 	udf	#36
 b04:	000008a8 	udf	#2216
 b08:	0008bb70 	.inst	0x0008bb70 ; undefined
 b0c:	ffff0000 	.inst	0xffff0000 ; undefined
 b10:	000000ac 	udf	#172
 b14:	00000000 	udf	#0
 b18:	9d300e41 	.inst	0x9d300e41 ; undefined
 b1c:	69059e06 	stgp	x6, x7, [x16, #176]
 b20:	000eddde 	.inst	0x000eddde ; undefined
 b24:	00000000 	udf	#0
 b28:	00000024 	udf	#36
 b2c:	000008a8 	udf	#2216
 b30:	0008bc1c 	.inst	0x0008bc1c ; undefined
 b34:	ffff0000 	.inst	0xffff0000 ; undefined
 b38:	0000007c 	udf	#124
 b3c:	00000000 	udf	#0
 b40:	9d300e41 	.inst	0x9d300e41 ; undefined
 b44:	5d059e06 	.inst	0x5d059e06 ; undefined
 b48:	000eddde 	.inst	0x000eddde ; undefined
 b4c:	00000000 	udf	#0
 b50:	00000024 	udf	#36
 b54:	000008a8 	udf	#2216
 b58:	0008bc98 	.inst	0x0008bc98 ; undefined
 b5c:	ffff0000 	.inst	0xffff0000 ; undefined
 b60:	00000058 	udf	#88
 b64:	00000000 	udf	#0
 b68:	9d300e41 	.inst	0x9d300e41 ; undefined
 b6c:	54059e06 	b.vs	bf2c <MAIR_ATTR+0x7b2c>
 b70:	000eddde 	.inst	0x000eddde ; undefined
 b74:	00000000 	udf	#0
 b78:	00000024 	udf	#36
 b7c:	000008a8 	udf	#2216
 b80:	0008bcf0 	.inst	0x0008bcf0 ; undefined
 b84:	ffff0000 	.inst	0xffff0000 ; undefined
 b88:	00000084 	udf	#132
 b8c:	00000000 	udf	#0
 b90:	9d400e41 	.inst	0x9d400e41 ; undefined
 b94:	5f079e08 	.inst	0x5f079e08 ; undefined
 b98:	000eddde 	.inst	0x000eddde ; undefined
 b9c:	00000000 	udf	#0
 ba0:	00000024 	udf	#36
 ba4:	000008a8 	udf	#2216
 ba8:	0008bd74 	.inst	0x0008bd74 ; undefined
 bac:	ffff0000 	.inst	0xffff0000 ; undefined
 bb0:	00000060 	udf	#96
 bb4:	00000000 	udf	#0
 bb8:	9d200e41 	.inst	0x9d200e41 ; undefined
 bbc:	56039e04 	.inst	0x56039e04 ; undefined
 bc0:	000eddde 	.inst	0x000eddde ; undefined
 bc4:	00000000 	udf	#0
 bc8:	00000024 	udf	#36
 bcc:	000008a8 	udf	#2216
 bd0:	0008bdd4 	.inst	0x0008bdd4 ; undefined
 bd4:	ffff0000 	.inst	0xffff0000 ; undefined
 bd8:	000000c0 	udf	#192
 bdc:	00000000 	udf	#0
 be0:	9d400e41 	.inst	0x9d400e41 ; undefined
 be4:	6e079e08 	.inst	0x6e079e08 ; undefined
 be8:	000eddde 	.inst	0x000eddde ; undefined
 bec:	00000000 	udf	#0
 bf0:	0000000c 	udf	#12
 bf4:	ffffffff 	.inst	0xffffffff ; undefined
 bf8:	78040001 	sturh	w1, [x0, #64]
 bfc:	001f0c1e 	.inst	0x001f0c1e ; undefined
 c00:	00000024 	udf	#36
 c04:	00000bf0 	udf	#3056
 c08:	0008be94 	.inst	0x0008be94 ; undefined
 c0c:	ffff0000 	.inst	0xffff0000 ; undefined
 c10:	00000044 	udf	#68
 c14:	00000000 	udf	#0
 c18:	9d200e41 	.inst	0x9d200e41 ; undefined
 c1c:	4f039e04 	.inst	0x4f039e04 ; undefined
 c20:	000eddde 	.inst	0x000eddde ; undefined
 c24:	00000000 	udf	#0
 c28:	00000024 	udf	#36
 c2c:	00000bf0 	udf	#3056
 c30:	0008bed8 	.inst	0x0008bed8 ; undefined
 c34:	ffff0000 	.inst	0xffff0000 ; undefined
 c38:	00000060 	udf	#96
 c3c:	00000000 	udf	#0
 c40:	9d400e41 	.inst	0x9d400e41 ; undefined
 c44:	56079e08 	.inst	0x56079e08 ; undefined
 c48:	000eddde 	.inst	0x000eddde ; undefined
 c4c:	00000000 	udf	#0
 c50:	00000024 	udf	#36
 c54:	00000bf0 	udf	#3056
 c58:	0008bf38 	.inst	0x0008bf38 ; undefined
 c5c:	ffff0000 	.inst	0xffff0000 ; undefined
 c60:	0000001c 	udf	#28
 c64:	00000000 	udf	#0
 c68:	9d200e41 	.inst	0x9d200e41 ; undefined
 c6c:	45039e04 	.inst	0x45039e04 ; undefined
 c70:	000eddde 	.inst	0x000eddde ; undefined
 c74:	00000000 	udf	#0
 c78:	00000024 	udf	#36
 c7c:	00000bf0 	udf	#3056
 c80:	0008bf54 	.inst	0x0008bf54 ; undefined
 c84:	ffff0000 	.inst	0xffff0000 ; undefined
 c88:	00000024 	udf	#36
 c8c:	00000000 	udf	#0
 c90:	9d200e41 	.inst	0x9d200e41 ; undefined
 c94:	47039e04 	.inst	0x47039e04 ; undefined
 c98:	000eddde 	.inst	0x000eddde ; undefined
 c9c:	00000000 	udf	#0
 ca0:	00000024 	udf	#36
 ca4:	00000bf0 	udf	#3056
 ca8:	0008bf78 	.inst	0x0008bf78 ; undefined
 cac:	ffff0000 	.inst	0xffff0000 ; undefined
 cb0:	00000090 	udf	#144
 cb4:	00000000 	udf	#0
 cb8:	9d400e41 	.inst	0x9d400e41 ; undefined
 cbc:	62079e08 	.inst	0x62079e08 ; undefined
 cc0:	000eddde 	.inst	0x000eddde ; undefined
 cc4:	00000000 	udf	#0
 cc8:	00000014 	udf	#20
 ccc:	00000bf0 	udf	#3056
 cd0:	0008c008 	.inst	0x0008c008 ; undefined
 cd4:	ffff0000 	.inst	0xffff0000 ; undefined
 cd8:	00000058 	udf	#88
 cdc:	00000000 	udf	#0

Disassembly of section .debug_rnglists:

0000000000000000 <.debug_rnglists>:
   0:	00000013 	udf	#19
   4:	00080005 	.inst	0x00080005 ; undefined
   8:	00000000 	udf	#0
   c:	a813cc04 	stnp	x4, x19, [x0, #312]
  10:	14c40414 	b	3101060 <PAGE_SIZE+0x2f01060>
  14:	Address 0x14 is out of bounds.

