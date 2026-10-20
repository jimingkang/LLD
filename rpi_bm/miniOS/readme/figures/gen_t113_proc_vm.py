#!/usr/bin/env python3
"""Generate the T113 counterpart of bare-proc-vm-pid1_11.svg (same visual style)."""
import sys

SANS = "'Noto Sans CJK SC','PingFang SC',sans-serif"
MONO = "'DejaVu Sans Mono','Menlo','Noto Sans CJK SC',monospace"
BLUE, ORANGE, TEAL, PURPLE, BROWN, GREEN, RED, GRAY = (
    '#1f4e8c', '#c0662b', '#18897a', '#6a4bb5', '#8a5a00', '#2b8a3e', '#b0564a', '#888888')

DY_TOP = 1500   # height of the AArch32 section from top_mmu.py
W, H = 2400, 2120 + DY_TOP
out = []


def esc(s):
    return s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')


def text(x, y, s, size=14.5, fill='#222', weight=400, anchor='start', mono=False):
    out.append(f'<text x="{x}" y="{y}" font-family="{MONO if mono else SANS}" font-size="{size}" '
               f'fill="{fill}" font-weight="{weight}" text-anchor="{anchor}" '
               f'dominant-baseline="central" xml:space="preserve">{esc(s)}</text>')


def rect(x, y, w, h, fill, stroke, sw=2, rx=0, dash=None):
    d = f' stroke-dasharray="{dash}"' if dash else ''
    out.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}" '
               f'stroke="{stroke}" stroke-width="{sw}"{d}/>')


def arrow(points, color, sw=2, label=None, lx=None, ly=None, anchor='middle'):
    d = 'M' + ' L'.join(f'{x},{y}' for x, y in points)
    out.append(f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{sw}" '
               f'marker-end="url(#m{color[1:]})"/>')
    if label:
        text(lx, ly, label, 13, color, 700, anchor, mono=True)


def panel(x, y, w, h):
    rect(x, y, w, h, '#fbfaf7', '#e2ded4', 1.5, 14)


def row(x, y, k, v, note, vcolor='#222', kx=18, vx=160, nx=330):
    text(x + kx, y, k, 14.5, '#222', 700, mono=True)
    text(x + vx, y, v, 14.5, vcolor, 700, mono=True)
    if note:
        text(x + nx, y, note, 13.5, '#555')


out.append(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><defs>')
for c in (BLUE, ORANGE, TEAL, PURPLE, BROWN, GREEN, RED, GRAY):
    out.append(f'<marker id="m{c[1:]}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" '
               f'markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{c}"/></marker>')
out.append('</defs>')
rect(0, 0, W, H, '#ffffff', 'none', 0)

text(1200, 40, 'T113 init 进程（pid 1）：异常向量、MMU 与地址翻译，t113_task、arm32_trapframe、内核栈、用户地址空间与 L1→L2 页表',
     30, '#222', 700, 'middle')
text(1200, 80, 't113_create_init_user_process() 之后、第一次 ret_from_fork 之前的状态；'
     '物理地址由页分配器动态给出，图里用 PA(…) 表示，数值来自源码常量', 18, '#777', 400, 'middle')

exec(open(__file__.replace('gen_t113.py', 'top_mmu.py').replace('gen_t113_proc_vm.py', 'top_mmu.py'), encoding='utf-8').read())
out.append(f'<g transform="translate(0,{DY})">')
# ------------------------------------------------------------------ top panel
panel(30, 120, 2340, 500)

# t113_task page
text(50, 158, 't113_task  ·  PA(task)，独占一页（4 KiB）', 17, BLUE, 700)
rect(50, 180, 740, 420, '#e3edf9', BLUE)
rect(50, 180, 740, 250, '#f5f9ff', BLUE)
text(64, 200, 'cpu_context（第一个字段，偏移 0：switch.S 把 task 指针当作 context 指针）', 14.5, BLUE, 700)
text(780, 200, '+0', 13.5, '#555', 700, 'end', True)
row(50, 232, 'r4', 'PA(task)', 'ret_from_fork 里 mov r0, r4 → t113_finish_fork(task)')
row(50, 262, 'r5 / r6', '0 / 0', '内核线程才用：fn / arg（用户进程为 0）')
row(50, 292, 'r7..r11', '0', '其余被调用者保存寄存器')
row(50, 322, 'sp', 'PA(stack)+0xfbc', '指向内核栈顶的 trapframe ──→', ORANGE)
out[-1] = out[-1].replace('fill="#555"', f'fill="{ORANGE}"')
row(50, 352, 'lr', 'ret_from_fork', 'cpu_switch_to 末尾 bx lr 跳过去')
text(64, 392, '共 10 个字（40 B）：ldmia r1, {r4-r11, sp, lr} 一条指令装回', 13.5, '#555')
row(50, 455, 'pid/state', '1 / RUNNING', 'flags = PF_USER，name = "init-user"')
row(50, 485, 'kernel_stack', 'PA(stack)', '另一页；与 task 页不一定相邻')
row(50, 515, 'trapframe', 'PA(stack)+0xfbc', '= kernel_stack + 4096 − 68')
row(50, 545, 'mm', 'PA(vm)', 'struct t113_user_vm：l1、l2[8]、pages[32]、brk')
row(50, 575, 'files[4]', '…', '就绪环、任务链表、parent、vfork_parent 等')

# kernel stack page
text(1030, 158, '内核栈页 [PA(stack), PA(stack)+0x1000)  ·  SVC 模式的 sp', 17, ORANGE, 700)
rect(1030, 180, 620, 220, '#fde8d8', ORANGE)
text(1044, 200, 'struct arm32_trapframe（68 B = 0x44）', 14.5, ORANGE, 700)
row(1030, 232, 'r[0..12]', '52 B', '+0..+48   全 0', kx=18, vx=150, nx=280)
row(1030, 262, 'user_sp', '+52', '0x00900000 → SP_usr', kx=18, vx=150, nx=280)
row(1030, 292, 'user_lr', '+56', '0 → LR_usr', kx=18, vx=150, nx=280)
row(1030, 322, 'pc', '+60', 'ELF e_entry → LR_svc → PC', kx=18, vx=150, nx=280)
row(1030, 352, 'cpsr', '+64', '0x10 → SPSR_svc → CPSR', kx=18, vx=150, nx=280)
text(1044, 382, 'TF_USER_SP/TF_PC/TF_CPSR 由 _Static_assert 和 fork_entry.S 钉死', 13, '#555')
rect(1030, 400, 620, 200, '#fff7f0', ORANGE)
text(1044, 425, '↓ 空闲内核栈（向低地址增长，约 4 KiB − 68 B）', 14.5, '#222', 700)
text(1044, 457, '之后每次 svc：kernel_svc_entry 在当前 sp 下方再压一个 68 B 帧，', 13.5, '#555')
text(1044, 482, '返回时弹掉，所以 fork 复制的是 parent_tf，不是 task->trapframe；', 13.5, '#555')
text(1044, 539, '被切走：cpu_context.sp 存成比 +0xfbc 更低的值。', 13.5, '#555')
text(1020, 190, 'PA(stack)+0x1000 栈顶', 13.5, '#333', 700, 'end', True)
text(1020, 400, 'PA(stack)+0xfbc', 13.5, ORANGE, 700, 'end', True)
text(1020, 422, '= 栈顶 − 0x44', 12.5, ORANGE, 400, 'end')
text(1020, 590, 'PA(stack) 栈底', 13.5, '#333', 700, 'end', True)
arrow([(790, 322), (850, 322), (850, 400), (1028, 400)], ORANGE)

# system registers
text(1720, 158, 'movs pc, lr 时的寄存器（arm32_return_to_user）', 17, BLUE, 700)
rect(1720, 180, 630, 420, '#f5f9ff', BLUE)
row(1720, 210, 'TTBR0', 'PA(l1)', '用户 L1 表（16 KiB，每进程一份）', BLUE, vx=150, nx=290)
row(1720, 240, 'TTBR1', '不用', 'TTBCR.N = 0：TTBR0 管整个 4 GiB', '#999', vx=150, nx=290)
row(1720, 270, 'DACR', '0x1', 'domain 0 = client，按 AP 位检查', '#222', vx=150, nx=290)
row(1720, 300, 'SP_usr', '0x00900000', 'ldmia r1, {sp, lr}^', BLUE, vx=150, nx=290)
row(1720, 330, 'LR_usr', '0x0', '同一条指令写入', BLUE, vx=150, nx=290)
row(1720, 360, 'LR_svc', 'e_entry', 'ldr lr, [r3, #TF_PC]', BLUE, vx=150, nx=290)
row(1720, 390, 'SPSR_svc', '0x10', 'msr spsr_cxsf；USR 模式，I/F 打开', BLUE, vx=150, nx=290)
text(1738, 432, 'movs pc, lr：PC ← LR_svc，CPSR ← SPSR_svc，进入用户态', 14, '#222', 700)
text(1738, 470, '和 AArch64 版对照：', 14.5, BROWN, 700)
text(1738, 500, 'eret ← ELR_EL1 / SPSR_EL1，SP_EL0 ← pt_regs.sp', 13.5, BROWN, mono=True)
text(1738, 525, 'ARMv7 没有 ELR，用 SVC 模式的 LR 和 SPSR；', 13.5, BROWN)
text(1738, 550, '用户 SP/LR 是分组寄存器，只能用 ^ 形式的 ldm/stm 访问。', 13.5, BROWN)
text(1738, 575, '0x10 = USR，I=0、F=0：用户态可以被定时器打断。', 13.5, BROWN)

# ------------------------------------------------------------------ physical pages
panel(30, 640, 2340, 300)
boxes = [
    (50, 'PA(task)', 't113_task', '含 cpu_context', '#e3edf9', BLUE),
    (300, 'PA(stack)', '内核栈', '顶部 68 B 是 trapframe', '#fde8d8', ORANGE),
    (550, 'PA(vm)', 't113_user_vm', 'task->mm，一页', '#eaf4ea', GREEN),
]
for x, pa, name, sub, fill, col in boxes:
    rect(x, 670, 220, 120, fill, col)
    text(x + 110, 692, pa, 14, '#222', 700, 'middle', True)
    text(x + 110, 730, name, 15.5, col, 700, 'middle')
    text(x + 110, 762, sub, 12.5, '#555', 400, 'middle')

rect(830, 670, 420, 240, '#efe9fb', PURPLE)
text(1040, 690, 'PA(l1)  ·  用户 L1 表（16 KiB，4096 项 × 1 MiB）', 14, '#222', 700, 'middle', True)
text(846, 722, '先整份复制 __kernel_l1_table，再改两项：', 13, '#555')
rect(846, 740, 388, 30, '#ffffff', PURPLE, 1.5)
text(858, 755, '[1] = PA(l2a) | 0x1   coarse → L2 表 A', 13, PURPLE, 700, mono=True)
rect(846, 778, 388, 30, '#ffffff', PURPLE, 1.5)
text(858, 793, '[8] = PA(l2b) | 0x1   coarse → L2 表 B', 13, PURPLE, 700, mono=True)
text(858, 830, '[0,2..7,9..15]  SRAM 段，仅特权 RW', 12.5, '#555', mono=True)
text(858, 852, '[0x010..0x3ff]  外设段，Device，XN', 12.5, '#555', mono=True)
text(858, 874, '[0x400..0xbff]  DRAM 段，1:1，仅特权 RW', 12.5, '#555', mono=True)
text(858, 896, '其余为 0（访问即 abort）', 12.5, '#555')

rect(1330, 670, 360, 110, '#efe9fb', PURPLE)
text(1510, 690, 'PA(l2a) · L2 表 A（VA 0x001xxxxx）', 13.5, '#222', 700, 'middle', True)
rect(1346, 710, 328, 30, '#ffffff', TEAL, 1.5)
text(1358, 725, '[0] = PA(code) | 0xc6e', 13, TEAL, 700, mono=True)
text(1358, 760, '[1..] 代码/数据段的后续页', 12.5, '#555')

rect(1330, 800, 360, 110, '#efe9fb', PURPLE)
text(1510, 820, 'PA(l2b) · L2 表 B（VA 0x008xxxxx）', 13.5, '#222', 700, 'middle', True)
rect(1346, 840, 328, 30, '#ffffff', BROWN, 1.5)
text(1358, 855, '[255] = PA(ustack) | 0xc7f', 13, BROWN, 700, mono=True)
text(1358, 890, 'L2 表 256 项 × 4 B = 1 KiB，占一整页', 12.5, '#555')

rect(1780, 680, 250, 100, '#e3f4f1', TEAL)
text(1905, 702, 'PA(code)', 14, '#222', 700, 'middle', True)
text(1905, 735, '物理页：用户代码', 15, TEAL, 700, 'middle')
text(1905, 762, '用户只读、可执行', 12.5, '#555', 400, 'middle')
rect(1780, 810, 250, 100, '#fdf3dc', BROWN)
text(1905, 832, 'PA(ustack)', 14, '#222', 700, 'middle', True)
text(1905, 865, '物理页：用户栈', 15, BROWN, 700, 'middle')
text(1905, 892, '用户读写、XN', 12.5, '#555', 400, 'middle')
rect(2090, 680, 250, 230, '#ffffff', GRAY, 1.5, 0, '6,4')
text(2215, 720, '其它页', 14, '#888', 700, 'middle')
text(2215, 750, '堆（sbrk 按页映射）', 12.5, '#888', 400, 'middle')
text(2215, 775, 'ELF 的其余段', 12.5, '#888', 400, 'middle')
text(2215, 800, '每进程最多 32 页、8 张 L2', 12.5, '#888', 400, 'middle')

arrow([(1234, 755), (1328, 725)], PURPLE)
arrow([(1234, 793), (1328, 855)], PURPLE)
arrow([(1674, 725), (1778, 730)], TEAL)
arrow([(1674, 855), (1778, 860)], BROWN)
text(50, 820, '物理页（地址从左到右没有顺序）：箭头就是 MMU 的遍历，只有两级——L1 项给出 L2 表，L2 项给出 4 KiB 页', 13.5, '#333', 700)
text(50, 848, 'L1 表要 16 KiB 对齐，所以用 t113_alloc_pages(4, 4) 分配；L2 表只有 1 KiB，却各占一页', 13.5, '#333')
text(50, 876, 'AArch64 版是 4 级（L0→L3），每级一页 512 项；ARMv7 短描述符只有 2 级', 13.5, BROWN)
# TTBR0 arrow from sys regs to L1
arrow([(1870, 600), (1870, 630), (1040, 630), (1040, 668)], BLUE, 2,
      'TTBR0 = mm->l1 = PA(l1)（遍历起点）', 1455, 620)
arrow([(660, 600), (660, 668)], GREEN)

# ------------------------------------------------------------------ user VA space
panel(30, 960, 2340, 640)
text(50, 990, '用户虚拟地址空间（TTBR0 = PA(l1)；只有用户页不是 1:1 映射）', 18, '#222', 700)
VX = 330
# stack
text(310, 1040, '0x00900000 ← SP_usr', 13.5, BROWN, 700, 'end', True)
rect(VX, 1030, 560, 110, '#fdf3dc', BROWN)
text(VX + 16, 1055, 'VA [0x008ff000, 0x00900000)', 14, '#333', 700, mono=True)
text(VX + 16, 1085, 'USER_STACK_VA，一页，读写、XN', 13.5, '#555')
text(VX + 16, 1115, 'L1[8] → L2B[255] → PA(ustack)', 13.5, BROWN, 700, mono=True)
text(310, 1140, '0x008ff000', 13.5, '#333', 700, 'end', True)
text(220, 1085, '用户栈（RW）', 14, BROWN, 700, 'middle')
arrow([(VX + 560, 1085), (1170, 1085)], BROWN, 2, '映射到', 1030, 1070)
rect(1172, 1035, 300, 100, '#fdf3dc', BROWN)
text(1322, 1058, 'PA(ustack)', 14, '#222', 700, 'middle', True)
text(1322, 1088, '物理页：用户栈', 14, BROWN, 700, 'middle')
text(1322, 1115, 'L2 描述符低 12 位 0xc7f', 12.5, '#555', 400, 'middle')

rect(VX, 1140, 560, 150, '#ffffff', '#cfcfcf', 1.5, 0, '6,4')
text(VX + 280, 1180, '堆：从 heap_base（ELF 末尾向上取整）开始，sbrk 按页映射', 13, '#888', 400, 'middle')
text(VX + 280, 1210, '其余未映射：L1 项是内核 SRAM 段（仅特权）或 0', 13, '#888', 400, 'middle')
text(VX + 280, 1240, '用户访问 → Permission / Translation fault', 13, '#888', 400, 'middle')
text(220, 1215, '未映射 / 堆', 13, '#999', 400, 'middle')

text(310, 1300, '0x001xxxxx', 13.5, '#333', 700, 'end', True)
rect(VX, 1290, 560, 120, '#e3f4f1', TEAL)
text(VX + 16, 1315, 'VA [0x00100000, …)  USER_CODE_VA', 14, '#333', 700, mono=True)
text(VX + 16, 1345, 'ELF PT_LOAD 段，按 p_flags 决定 RW / X；e_entry 在这里', 13.5, '#555')
text(VX + 16, 1375, 'L1[1] → L2A[0] → PA(code)', 13.5, TEAL, 700, mono=True)
text(220, 1350, '用户映像（代码）', 14, TEAL, 700, 'middle')
text(310, 1410, '0x00100000', 13.5, TEAL, 700, 'end', True)
arrow([(VX + 560, 1350), (1170, 1350)], TEAL, 2, '映射到', 1030, 1335)
rect(1172, 1300, 300, 100, '#e3f4f1', TEAL)
text(1322, 1323, 'PA(code)', 14, '#222', 700, 'middle', True)
text(1322, 1353, '物理页：用户代码', 14, TEAL, 700, 'middle')
text(1322, 1380, 'L2 描述符低 12 位 0xc6e', 12.5, '#555', 400, 'middle')
rect(VX, 1410, 560, 50, '#ffffff', '#cfcfcf', 1.5, 0, '6,4')
text(VX + 280, 1435, '[0, 0x00100000)：L1[0] 是内核 SRAM 段，用户无权访问', 13, '#888', 400, 'middle')
text(310, 1460, '0x0', 13.5, '#333', 700, 'end', True)

# VA split
def split(x, y, title, parts, col):
    text(x, y, title, 14, col, 700, mono=True)
    widths = [260, 200, 200]
    labels = ['31:20', '19:12', '11:0']
    names = ['L1 索引', 'L2 索引', '页内偏移']
    cx = x
    for wd, lab, nm, val in zip(widths, labels, names, parts):
        text(cx + wd / 2, y + 28, lab, 12, '#777', 400, 'middle', True)
        rect(cx, y + 42, wd, 56, '#ffffff', col, 1.5)
        text(cx + wd / 2, y + 62, val, 15, '#222', 700, 'middle')
        text(cx + wd / 2, y + 85, nm, 11.5, '#777', 400, 'middle')
        cx += wd


split(1560, 1030, '用户栈 VA = 0x008ff000', ['L1 = 8', 'L2 = 255', '偏移 = 0'], BROWN)
split(1560, 1180, '代码 VA = 0x00100000', ['L1 = 1', 'L2 = 0', '偏移 = 0'], TEAL)
text(1560, 1320, '这些下标就是上面页表框里的 [8] [255] 和 [1] [0]。', 13, '#555')
text(1560, 1348, 'AArch64 版把 48 位 VA 切成 9+9+9+9+12；ARMv7 的 32 位 VA 只切 12+8+12。', 13, BROWN)
text(1560, 1376, '每进程 L1 都是内核 L1 的完整副本，所以内核代码在用户页表下照样可用，', 13, '#555')
text(1560, 1400, '代价是 fork/exec 都要复制 16 KiB，切换时 TLBIALL 全刷。', 13, '#555')

# ------------------------------------------------------------------ bottom
panel(30, 1620, 1140, 480)
text(50, 1650, 'L2 小页描述符解码（SCTLR.XP = 1，TRE = 0，AFE = 0）', 18, PURPLE, 700)
cols = [50, 220, 320, 640, 920]
rect(50, 1670, 1100, 34, '#3b2a74', '#3b2a74', 0)
for x, h in zip(cols, ['字段', '位', '代码页 0xc6e', '栈页 0xc7f', '含义']):
    text(x + 14, 1687, h, 14, '#fff', 700)
rows = [
    ('XN', '0', '0  可执行', '1  不可执行', '数据页一律 XN'),
    ('类型', '1', '1  小页', '1  小页', '4 KiB'),
    ('B / C', '2 / 3', '1 / 1', '1 / 1', '写回、写分配'),
    ('AP[1:0]', '5:4', '10  用户只读', '11  用户读写', '特权总是可读写'),
    ('TEX', '8:6', '001', '001', 'Normal 内存'),
    ('AP[2]', '9', '0', '0', '不加只读限制'),
    ('S', '10', '1', '1', '可共享'),
    ('nG', '11', '1', '1', '非全局；未用 ASID，整表刷'),
]
y = 1722
for i, r in enumerate(rows):
    if i % 2:
        rect(50, y - 15, 1100, 30, '#ece8f7', 'none', 0)
    for x, c in zip(cols, r):
        text(x + 14, y, c, 13.5, '#222', 700 if x == 50 else 400, mono=(x != 920))
    y += 30
text(64, y + 14, '· L1 coarse 描述符：PA(l2) & 0xfffffc00 | 0x1（domain 0）。内核 1 MiB 段：AP = 01，仅特权读写。', 13, PURPLE)
text(64, y + 42, '· 代码页对内核仍可写：exec 复制段内容后，sync_executable_pages() 用 DCCIMVAC + ICIALLU 同步。', 13, PURPLE)

panel(1190, 1620, 1180, 480)
text(1210, 1650, '这几样东西的关系（和 AArch64 版逐条对应）', 18, ORANGE, 700)
items = [
    ('① alloc_process_common()：分配 task 页和内核栈页，trapframe 放在栈顶下 68 B；',
     '   cpu_context.r4 = task，sp = trapframe，lr = ret_from_fork（AArch64：x19 = fn，pc = ret_from_fork）。'),
    ('② t113_user_vm_create_elf()：复制内核 L1，按 PT_LOAD 建 L2 和页，再映射用户栈页；',
     '   trapframe.pc = e_entry，user_sp = 0x00900000，cpsr = 0x10。'),
    ('③ 第一次调度：t113_cpu_switch_to 装回 r4-r11、sp、lr，bx lr → ret_from_fork；',
     '   t113_finish_fork(task) 写 TTBR0 = mm->l1（AArch64 在 move_to_user_mode 里写 TTBR0_EL1）。'),
    ('④ arm32_return_to_user：{sp, lr}^ 写用户分组寄存器，SPSR_svc = cpsr，',
     '   ldmia r0-r12，movs pc, lr 进入 USR 模式（AArch64：kernel_exit + eret）。'),
    ('⑤ 之后每次 svc：kernel_svc_entry 在 SVC 栈上新压一个 68 B 帧，不复用 task->trapframe；',
     '   AArch64 版的 pt_regs（272 B）则总在栈顶同一位置。'),
    ('⑥ 内核地址：T113 内核在 DRAM 1:1 映射，用户 L1 里也有这些段（仅特权）；',
     '   AArch64 版内核走 TTBR1（高地址），用户页表里没有内核映射。'),
]
y = 1690
for a, b in items:
    text(1210, y, a, 13.5, '#222', 700)
    text(1210, y + 26, b, 13, '#555')
    y += 64

out.append('</g>')
out.append('</svg>')
open(sys.argv[1], 'w', encoding='utf-8').write('\n'.join(out))
