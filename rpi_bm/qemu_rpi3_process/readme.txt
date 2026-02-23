ref:
https://github.com/rockytriton/LLD
https://github.com/s-matyukevich/raspberry-pi-os/
https://www.youtube.com/watch?v=pd9AVmcRc6U&list=PLVxiWMqQvhg9FCteL7I0aohj1_YiUx1x8
https://www.udemy.com/course/raspberry-pi-write-your-own-operating-system-step-by-step




launch.json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "rpi3_kernel.elf",
      "type": "cppdbg",
      "request": "launch",
      "program": "/home/rlk/Downloads/LLD/rpi_bm/qemu_rpi3_process/qemu/kernel.elf",
      "args": [],
      "stopAtEntry": true,
      "cwd": "${workspaceRoot}",
      "environment": [],
      "externalConsole": true,
      "MIMode": "gdb",
      "logging": {
        "moduleLoad": false,
        "engineLogging": false,
        "trace": false
      },
      "setupCommands": [
        {
          "description": "Enable pretty-printing for gdb",
          "text": "-enable-pretty-printing",
          "ignoreFailures": true
        },
        {
          "description": "set architecture aarch64",
          "text": "set architecture aarch64",
          "ignoreFailures": true
        },
        {
          "description": "Load user init symbols",
          "text": "add-symbol-file ${workspaceFolder}/init/init 0x400000"
        }
      ],
      "miDebuggerPath": "gdb-multiarch",
      "miDebuggerServerAddress": "localhost:1234"
    },
    {
      "name": "C/C++ Runner: Debug Session",
      "type": "cppdbg",
      "request": "launch",
      "args": [],
      "stopAtEntry": false,
      "externalConsole": false,
      "cwd": "/home/rlk/Downloads/LLD/qemu_rpi_process",
      "program": "/home/rlk/Downloads/LLD/rpi_bm/qemu_rpi_process/build/Debug/outDebug",
      "MIMode": "gdb",
      "miDebuggerPath": "gdb",
      "setupCommands": [
        {
          "description": "Enable pretty-printing for gdb",
          "text": "-enable-pretty-printing",
          "ignoreFailures": true
        }
      ]
    }
  ]
}




/*??????(?? .bss / .data)

process_table[]:
+------------------------+
¦ struct Process (pid=0) ¦
+------------------------¦
¦ struct Process (pid=1) ¦
+------------------------¦
¦ struct Process (pid=2) ¦ ? ????
¦   - pid                ¦
¦   - state              ¦
¦   - wait               ¦
¦   - context = 0x2F3FFD50 ?------+
¦   - page_map            ¦       ¦
¦   - stack               ¦       ¦
¦   - tf                  ¦       ¦
+------------------------+       ¦
                                 ¦
                                 ?
								 
*/

/*pid=2 ? kernel stack(2MB)

0xFFFF00002F400000  ? stack top
+--------------------------+
¦ TrapFrame                ¦
+--------------------------¦
¦ sys / handler / sleep    ¦
+--------------------------¦
¦ schedule
+--------------------------¦
¦ Context  (size 0x60) ?---+
+--------------------------¦
¦ ???(sp ????)     ¦
+--------------------------+
0xFFFF00002F200000  ? stack base*/


/*??????,?? sleepu() ?????,?? sync_handler->handler->sys_call->sys_sleep() -> sleep() -> schedule() -> swap() -> idle_thread() -> schedule() -> swap() -> trap_return() -> eret ?????
??:
#0  schedule      fp=0xFFFF00002F3FFD90  lr=0xFFFF00000008BBF4
#1  sleep         fp=0xFFFF00002F3FFDD0  lr=0xFFFF00000008BCD0
#2  sys_sleep     fp=0xFFFF00002F3FFE00  lr=0xFFFF00000008BEF4
#3  sys_call      fp=0xFFFF00002F3FFE30  lr=0xFFFF00000008BFD C
#4  handler (C)   fp=0xFFFF00002F3FFE70  lr=0xFFFF000000081D44
#5  sync_handler  fp=0xFFFF00002F3FFEB0  lr=0xFFFF000000081864
#6  user          fp=0x00000000005FFFE0  lr=0x0000000000400004




???
0xFFFF00002F400000
¦
¦  +----------------------------------------------+
¦  ¦ TrapFrame (size = 0x120)                      ¦
¦  ¦ tf = 0xFFFF00002F3FFEE0                       ¦
¦  ¦  - elr = 0x400004 (user pc)                   ¦
¦  ¦  - spsr / esr / sp0 / regs...                 ¦
¦  +----------------------------------------------+
¦  +----------------------------------------------+
¦  ¦ sync_handler() (??????)              ¦
¦  ¦ fp = 0xFFFF00002F3FFEB0                      ¦
¦  ¦ lr = 0xFFFF000000081864                      ¦
¦  +----------------------------------------------+
¦  +----------------------------------------------+
¦  ¦ handler()   (C ????)                   ¦
¦  ¦ fp = 0xFFFF00002F3FFE70                      ¦
¦  ¦ lr = 0xFFFF000000081D44                      ¦
¦  +----------------------------------------------+
¦
¦  +----------------------------------------------+
¦  ¦ sys_call()                                   ¦
¦  ¦ fp = 0xFFFF00002F3FFE30                      ¦
¦  ¦ lr = 0xFFFF00000008BFDC                      ¦
¦  +----------------------------------------------+
¦  +----------------------------------------------+
¦  ¦ sys_sleep()                                  ¦
¦  ¦ fp = 0xFFFF00002F3FFE00                      ¦
¦  ¦ lr = 0xFFFF00000008BEF4                      ¦
¦  +----------------------------------------------+

¦
¦  +----------------------------------------------+
¦  ¦ sleep()                                      ¦
¦  ¦ fp = 0xFFFF00002F3FFDD0                      ¦
¦  ¦ lr = 0xFFFF00000008BCD0                      ¦
¦  +----------------------------------------------+
¦
¦  +----------------------------------------------+
¦  ¦ schedule()                                   ¦
¦  ¦ fp = 0xFFFF00002F3FFD90                      ¦
¦  ¦ lr = 0xFFFF00000008BBF4                      ¦
¦  +----------------------------------------------+
¦
¦  +----------------------------------------------+
¦  ¦ Context (size = 0x60)                        ¦
¦  ¦ context = 0xFFFF00002F3FFD50                 ¦
¦  ¦  - x19 ~ x28                                 ¦
¦  ¦  - saved fp (x29)                            ¦
¦  ¦  - saved lr (x30)                            ¦
¦  +----------------------------------------------+
¦...
???
0xFFFF00002F200000
*/

/* pid=0?idle_thread ????(2MB)
???
0xFFFF000030000000  ? stack top
¦
¦ +------------------------------------------+
¦ ¦ TrapFrame  (0x120 = 288B)                 ¦
¦ ¦ addr: 0xFFFF00002FFFFEE0                  ¦
¦ ¦  elr / spsr / esr / regs …                ¦
¦ +------------------------------------------+
¦
¦ +------------------------------------------+
¦ ¦ Context  (0x60 = 96B)                     ¦
¦ ¦ addr: 0xFFFF00002FFFFE80                  ¦
¦ ¦  x19–x28                                  ¦
¦ ¦  saved fp = 0x0                           ¦
¦ ¦  saved lr = 0xFFFF00000008B178            ¦
¦ +------------------------------------------+
¦
¦ ------------------------------------------
¦   ? ??:?????????????
¦   sp ????? stack ?????
¦ ------------------------------------------
¦
¦
¦   (??? 2MB ????????????)
¦
¦
???
0xFFFF00002FE00000  ? stack base

boot??
 #0: fp=FFFF00000007FE00H  lr=FFFF00000008BBF4H(yield)
 #1: fp=FFFF00000007FE40H  lr=FFFF00000008BC74H(sleep)
 #2: fp=FFFF00000007FE70H  lr=FFFF000000081D68H(handler)
 #3: fp=FFFF00000007FEA0H  lr=FFFF0000000818D0H(irq_handler)

*/

