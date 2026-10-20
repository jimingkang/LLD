# Top section of the T113 figure, written for AArch32 (ARMv7-A, Cortex-A7):
# processor modes + exception vectors, CP15 registers, short-descriptor
# formats, and two real translations taken from the _init disassembly.
# exec()'d by gen_t113.py with its helpers (text/rect/arrow/panel) in scope.

DY = DY_TOP


def bitbar(x, y, title, fields, example, col, scale=40):
    """fields: list of (hi, lo, label, value) from bit 31 down to bit 0."""
    text(x, y, title, 14.5, col, 700)
    cx = x
    for hi, lo, lab, val in fields:
        wd = (hi - lo + 1) * scale
        rect(cx, y + 34, wd, 58, '#ffffff', col, 1.3)
        rng = f'{hi}' if hi == lo else f'{hi}:{lo}'
        text(cx + wd / 2, y + 22, rng, 11, '#777', 400, 'middle', True)
        text(cx + wd / 2, y + 52, lab, 12 if wd > 60 else 10.5, '#222', 700, 'middle')
        text(cx + wd / 2, y + 76, val, 11.5 if wd > 60 else 10.5, col, 700, 'middle', True)
        cx += wd
    text(cx + 18, y + 52, example[0], 13, '#222', 700, mono=True)
    text(cx + 18, y + 76, example[1], 12, '#555')


# ------------------------------------------------------------ ① modes + vectors
panel(30, 120, 2340, 520)
text(50, 150, '① 处理器模式与异常向量（ARMv7-A AArch32）  ·  VBAR = kernel_vectors，8 个字，每项一条 b 指令',
     17, RED, 700)
vx = [50, 116, 262, 392, 640, 900]
rect(50, 168, 1450, 32, '#7a3328', '#7a3328', 0)
for x, h in zip(vx, ['偏移', '异常', '进入模式 M[4:0]', '该模式的分组寄存器', 'LR 修正 / 返回方式', 'miniOS 入口与处理']):
    text(x + 10, 184, h, 13, '#fff', 700)
vrows = [
    ('0x00', 'Reset', 'SVC  10011', '—', '不返回', 'kernel_reset：给 IRQ/ABT/UND/FIQ/SVC 设栈，写 VBAR，清 BSS'),
    ('0x04', 'Undefined', 'UND  11011', 'SP_und LR_und SPSR_und', 'LR−4（ARM 态）', 'kernel_undefined_entry → t113_exception_report，停机'),
    ('0x08', 'SVC', 'SVC  10011', 'SP_svc LR_svc SPSR_svc', 'LR = svc 下一条；movs pc, lr', 'kernel_svc_entry：压 68 B trapframe → t113_syscall_dispatch'),
    ('0x0C', 'Prefetch Abort', 'ABT  10111', 'SP_abt LR_abt SPSR_abt', 'LR−4；读 IFSR / IFAR', 'kernel_prefetch_abort_entry → 报告 IFSR/IFAR，停机'),
    ('0x10', 'Data Abort', 'ABT  10111', '同上', 'LR−8；读 DFSR / DFAR', 'kernel_data_abort_entry → 报告 DFSR/DFAR，停机'),
    ('0x14', '未用', '—', '—', '—', 'kernel_exception_hang：wfi 死循环（Hyp 模式的向量表才用此项）'),
    ('0x18', 'IRQ', 'IRQ  10010', 'SP_irq LR_irq SPSR_irq', 'LR−4；srsdb … rfeia', 'kernel_irq_entry：srsdb sp!, #0x13 把 LR/SPSR 存到 SVC 栈 → cps #0x13 → t113_irq_handler'),
    ('0x1C', 'FIQ', 'FIQ  10001', 'r8–r12 SP LR SPSR', 'LR−4', 'kernel_fiq_entry → 报告，停机'),
]
y = 216
for i, r in enumerate(vrows):
    if i % 2:
        rect(50, y - 14, 1450, 28, '#f8ecea', 'none', 0)
    hl = r[0] in ('0x08', '0x10', '0x18')
    for x, c in zip(vx, r):
        text(x + 10, y, c, 12.5, RED if hl and x == 50 else '#222',
             700 if x in (50,) else 400, mono=(x in (50, 262)))
    y += 28
text(60, y + 4, 'USR 10000 和 SYS 11111 共用 SP/LR；r0–r7、PC 所有模式共用。用户 SP/LR 只能用 ldm/stm 的 ^ 形式在特权模式下读写（kernel_svc_entry、arm32_return_to_user）。',
     12.5, '#555')
text(60, y + 28, '模式栈：SVC 8 KiB，IRQ/ABT/UND/FIQ 各 1 KiB（链接脚本 .kernel_stack）；进程进内核后用自己的 4 KiB 内核栈作 SP_svc。',
     12.5, '#555')

# CPSR bar
text(1540, 150, 'CPSR / SPSR（用户进程初值 0x00000010）', 15, RED, 700)
cps = [(31, 31, 'N', '0'), (30, 30, 'Z', '0'), (29, 29, 'C', '0'), (28, 28, 'V', '0'), (27, 27, 'Q', '0'),
       (26, 25, 'IT', '0'), (24, 24, 'J', '0'), (23, 20, '保留', '0'), (19, 16, 'GE', '0'),
       (15, 10, 'IT', '0'), (9, 9, 'E', '0'), (8, 8, 'A', '0'), (7, 7, 'I', '0'), (6, 6, 'F', '0'),
       (5, 5, 'T', '0'), (4, 0, 'M[4:0]', '10000')]
cx = 1540
for hi, lo, lab, val in cps:
    wd = (hi - lo + 1) * 24
    hot = lab in ('I', 'F', 'T', 'M[4:0]')
    rect(cx, 186, wd, 52, '#fde8e4' if hot else '#ffffff', RED, 1.2)
    text(cx + wd / 2, 175, f'{hi}' if hi == lo else f'{hi}:{lo}', 9.5, '#777', 400, 'middle', True)
    text(cx + wd / 2, 202, lab, 10.5, '#222', 700, 'middle')
    text(cx + wd / 2, 224, val, 10.5, RED, 700, 'middle', True)
    cx += wd
text(1540, 262, 'M = 10000 USR；T = 0 ARM 态；I = F = 0 允许 IRQ/FIQ；A = 0。', 12.5, '#555')
text(1540, 286, 'movs pc, lr / rfeia 把 SPSR 拷回 CPSR，完成模式切换。', 12.5, '#555')
text(1540, 318, '与 AArch64 的根本区别（对照图 1.2）', 13.5, BROWN, 700)
text(1540, 342, '· 用 PL0/PL1 + 模式（miniOS 用 7 种），异常模式各有 SP/LR/SPSR', 12.5, BROWN)
text(1540, 366, '· 向量表 8 项 × 4 B（一条指令），不是 16 项 × 0x80 B', 12.5, BROWN)
text(1540, 390, '· 系统寄存器在 CP15 里，用 MCR/MRC 访问，不是 MSR/MRS', 12.5, BROWN)
text(1540, 414, '· 返回靠 movs pc / subs pc / rfe，不是 eret + ELR', 12.5, BROWN)

# CP15 table
text(1540, 452, 'miniOS 用到的 CP15 寄存器（MCR/MRC p15, op1, Rt, CRn, CRm, op2）', 14, PURPLE, 700)
cp = [
    ('SCTLR', 'c1,c0,0', 'M=1 I=1 XP=1 · C=0 TRE=0 AFE=0', 'mmu.c'),
    ('TTBR0 / TTBCR', 'c2,c0,0 / c2,c0,2', '内核 L1 或 mm->l1 / N = 0', 'mmu.c, user_vm.c'),
    ('DACR', 'c3,c0,0', '0x1：domain 0 = client', 'mmu.c'),
    ('DFSR/IFSR · DFAR/IFAR', 'c5,c0,0/1 · c6,c0,0/2', '故障状态与故障地址', 'exception.c'),
    ('ATS1C{P,U}{R,W} → PAR', 'c7,c8,0..3 → c7,c4,0', '硬件代查一次翻译，不触发异常', 'exception.c, syscall.c'),
    ('TLBIALL · ICIALLU · DCCIMVAC', 'c8,c7,0 · c7,c5,0 · c7,c14,1', '换 TTBR0 全刷 TLB；装代码后同步 I/D', 'user_vm.c'),
    ('VBAR', 'c12,c0,0', 'kernel_vectors', 'kernel_entry.S'),
]
y = 480
for k, enc, v, where in cp:
    text(1548, y, k, 11.5, '#222', 700, mono=True)
    text(1800, y, enc, 11, PURPLE, 700, mono=True)
    text(1990, y, v, 11.5, '#555')
    y += 21

# ------------------------------------------------------------ ② descriptors
panel(30, 660, 2340, 400)
text(50, 690, '② ARMv7-A 短描述符格式（TTBCR.EAE = 0）  ·  32 位 VA，两级：L1 4096 项 × 1 MiB，L2 256 项 × 4 KiB',
     17, PURPLE, 700)
bitbar(50, 710, 'L1 段描述符（内核 1:1 映射用）  位[1:0] = 10', [
    (31, 20, '段基址 PA[31:20]', 'VA[31:20]'), (19, 19, 'NS', '0'), (18, 18, '0', '0'), (17, 17, 'nG', '0'),
    (16, 16, 'S', 'D:1'), (15, 15, 'AP2', '0'), (14, 12, 'TEX', 'N:001'), (11, 10, 'AP', '01'),
    (9, 9, '', '0'), (8, 5, 'Domain', '0'), (4, 4, 'XN', 'D:1'), (3, 3, 'C', 'N:1'), (2, 2, 'B', '1'),
    (1, 0, '类型', '10')],
    ('DRAM: 0x4020140e   外设: 0x02510416', 'N = Normal（SRAM/DRAM），D = Device（外设）；AP=01 仅特权读写'), BLUE)
bitbar(50, 820, 'L1 页表描述符（用户 L1[1]、L1[8]）  位[1:0] = 01', [
    (31, 10, 'L2 表基址 PA[31:10]（1 KiB 对齐）', 'PA(l2a) / PA(l2b)'), (9, 9, '', '0'), (8, 5, 'Domain', '0'),
    (4, 4, '0', '0'), (3, 3, 'NS', '0'), (2, 2, 'PXN', '0'), (1, 0, '类型', '01')],
    ('PA(l2b) | 0x01', 'get_l2()：l2 & 0xfffffc00 | L1_COARSE'), PURPLE)
bitbar(50, 930, 'L2 小页描述符（用户页）  位[1] = 1', [
    (31, 12, '页基址 PA[31:12]', 'PA(code) / PA(ustack)'), (11, 11, 'nG', '1'), (10, 10, 'S', '1'),
    (9, 9, 'AP2', '0'), (8, 6, 'TEX', '001'), (5, 4, 'AP', '10/11'), (3, 3, 'C', '1'), (2, 2, 'B', '1'),
    (1, 1, '1', '1'), (0, 0, 'XN', '0/1')],
    ('代码 0xc6e   栈 0xc7f', 'l2_flags()：AP 10 用户只读 / 11 用户读写；数据页 XN=1'), TEAL)
text(1990, 712, '没用到的格式：', 13, '#777', 700)
text(1990, 736, '· 超级段（16 MiB，L1 位18 = 1）', 12, '#777')
text(1990, 758, '· L2 大页（64 KiB，类型 01）', 12, '#777')
text(1990, 780, '· LPAE 长描述符（TTBCR.EAE = 1，三级、64 位项）', 12, '#777')
text(1990, 802, '  Cortex-A7 支持，miniOS 不用', 12, '#777')

# ------------------------------------------------------------ ③ two translations
panel(30, 1080, 2340, 400)
text(50, 1110, '③ 两次真实的翻译：init 的第一次取指和第一次写栈（来自 _init 反汇编，e_entry = 0x00100000）', 17, TEAL, 700)
text(50, 1138, '0x00100000  eb000002  bl main          →  用户态取指 VA 0x00100000', 12.5, '#333', mono=True)
text(50, 1160, '0x00100010  e92d4030  push {r4, r5, lr} →  SP 0x00900000 先减 12，写 0x008ffff4 / f8 / fc（STMDB）', 12.5, '#333', mono=True)


def lane(y, va, l1i, l2i, off, l1d, l2d, pa, verdict, col):
    rect(50, y, 290, 92, '#ffffff', col, 1.5)
    text(195, y + 22, 'VA', 13, '#777', 700, 'middle')
    text(195, y + 50, va, 17, '#222', 700, 'middle', True)
    text(195, y + 76, f'[31:20]={l1i} [19:12]={l2i} [11:0]={off}', 10.5, col, 700, 'middle', True)
    rect(390, y, 470, 92, '#efe9fb', PURPLE, 1.5)
    text(406, y + 22, f'L1 描述符地址 = TTBR0[31:14] : {l1i} : 00', 12.5, '#333', mono=True)
    text(406, y + 50, f'L1[{int(l1i, 16)}] = {l1d}', 14, PURPLE, 700, mono=True)
    text(406, y + 76, '位[1:0] = 01 → 去 L2；Domain 0 client → 查 AP', 12, '#555')
    rect(910, y, 500, 92, '#e3f4f1', TEAL, 1.5)
    text(926, y + 22, f'L2 描述符地址 = L1desc[31:10] : {l2i} : 00', 12.5, '#333', mono=True)
    text(926, y + 50, f'L2[{int(l2i, 16)}] = {l2d}', 14, TEAL, 700, mono=True)
    text(926, y + 76, verdict, 12, '#555')
    rect(1460, y, 380, 92, '#fdf3dc', BROWN, 1.5)
    text(1476, y + 22, 'PA = L2desc[31:12] : VA[11:0]', 12.5, '#333', mono=True)
    text(1476, y + 52, pa, 15, BROWN, 700, mono=True)
    text(1476, y + 76, '结果进 TLB；下次同页不再走表', 12, '#555')
    arrow([(340, y + 46), (388, y + 46)], col)
    arrow([(860, y + 46), (908, y + 46)], PURPLE)
    arrow([(1410, y + 46), (1458, y + 46)], TEAL)


lane(1180, '0x00100000', '0x001', '0x00', '0x000', 'PA(l2a) | 0x01', 'PA(code) | 0xc6e',
     'PA(code) + 0x000', 'AP=10 用户只读，XN=0 → 取指通过', TEAL)
lane(1290, '0x008ffff4', '0x008', '0xff', '0xff4', 'PA(l2b) | 0x01', 'PA(ustack) | 0xc7f',
     'PA(ustack) + 0xff4', 'AP=11 用户读写 → 写通过；XN=1，此页不能取指', BROWN)
text(50, 1410, '内核地址只查一级：VA 0x40200000 → L1[0x402] = 0x4020140e 段 → PA 0x40200000；VA 0x02500c00（UART3）→ L1[0x025] = 0x02510416 → PA 0x02500c00。',
     12.5, '#555')
text(50, 1436, '表遍历本身按 TTBR0 的 RGN = 0（不经 cache）读内存；SCTLR.C = 0 时数据访问也不经 D-cache，描述符里的 C/B 位暂时只是“将来可缓存”的声明。',
     12.5, '#555')

rect(1880, 1180, 470, 250, '#ffffff', RED, 1.5)
text(2115, 1198, '走不通时：FS = DFSR/IFSR {[10], [3:0]}', 13.5, RED, 700, 'middle')
faults = [
    ('0b00101', '段翻译错：L1 项类型 00'),
    ('0b00111', '页翻译错：L2 项为 0'),
    ('0b01101', '段权限错：用户碰内核段'),
    ('0b01111', '页权限错：用户写只读页'),
    ('0b01001/01011', '域错（DACR 为 no access）'),
]
y = 1226
for fs, d in faults:
    text(1896, y, fs, 12, '#222', 700, mono=True)
    text(2040, y, d, 12, '#555')
    y += 24
text(1896, y + 4, '读写 → 0x10 Data Abort（DFAR = VA）', 12, RED, 700)
text(1896, y + 28, '取指 → 0x0C Prefetch Abort（IFAR = VA）', 12, RED, 700)
text(1896, y + 52, 'syscall 检查用户指针：ATS1CUR/CUW 查 PAR.F', 12, '#555')
