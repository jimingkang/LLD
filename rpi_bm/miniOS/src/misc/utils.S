.globl delay
delay:
    subs x0, x0, #1
    bne delay
    ret

.globl put32
put32:
    str w1, [x0]
    ret

.globl get32
get32:
    ldr w0, [x0]
    ret

.globl get_el
get_el:
    mrs x0, CurrentEL
    lsr x0, x0, #2
    ret


.globl set_pgd
set_pgd:
	msr	ttbr0_el1, x0
	tlbi vmalle1is
  	DSB ISH              // ensure completion of TLB invalidation
	isb

	  // 3. 读取 SCTLR_EL1，置位 M(0)，重新写回，再 isb
   // mrs     x1, SCTLR_EL1     // x1 = 原来的 SCTLR_EL1
   // orr     x1, x1, #(1 << 0) // 将 M 位(第 0 位) 设 1，打开 MMU
  //  msr     SCTLR_EL1, x1
 //   isb                       // 保证新 SCTLR 生效
	ret
	

.globl get_pgd
get_pgd:
	mov x1, 0
	ldr x0, [x1]
	mov x0, 0x1000
	msr	ttbr0_el1, x0
	ldr x0, [x1]
	ret

