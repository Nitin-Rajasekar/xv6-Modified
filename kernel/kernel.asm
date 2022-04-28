
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a2013103          	ld	sp,-1504(sp) # 80008a20 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	2ec78793          	addi	a5,a5,748 # 80006350 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ff1c7ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	6ec080e7          	jalr	1772(ra) # 80002818 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	80c080e7          	jalr	-2036(ra) # 800019d0 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	fa0080e7          	jalr	-96(ra) # 80002174 <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	5b2080e7          	jalr	1458(ra) # 800027c2 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	57c080e7          	jalr	1404(ra) # 8000286e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	ffe080e7          	jalr	-2(ra) # 80002444 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	000dd797          	auipc	a5,0xdd
    8000047c:	ea078793          	addi	a5,a5,-352 # 800dd318 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	ba4080e7          	jalr	-1116(ra) # 80002444 <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	848080e7          	jalr	-1976(ra) # 80002174 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	000e1797          	auipc	a5,0xe1
    80000a10:	5f478793          	addi	a5,a5,1524 # 800e2000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	000e1517          	auipc	a0,0xe1
    80000ae0:	52450513          	addi	a0,a0,1316 # 800e2000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	e36080e7          	jalr	-458(ra) # 800019b4 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	e04080e7          	jalr	-508(ra) # 800019b4 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	df8080e7          	jalr	-520(ra) # 800019b4 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	de0080e7          	jalr	-544(ra) # 800019b4 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	da0080e7          	jalr	-608(ra) # 800019b4 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	d74080e7          	jalr	-652(ra) # 800019b4 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	b0e080e7          	jalr	-1266(ra) # 800019a4 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	af2080e7          	jalr	-1294(ra) # 800019a4 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	afe080e7          	jalr	-1282(ra) # 800029d2 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	4b4080e7          	jalr	1204(ra) # 80006390 <plicinithart>
  }
  

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	0cc080e7          	jalr	204(ra) # 80001fb0 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	998080e7          	jalr	-1640(ra) # 800018dc <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	a5e080e7          	jalr	-1442(ra) # 800029aa <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	a7e080e7          	jalr	-1410(ra) # 800029d2 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	41e080e7          	jalr	1054(ra) # 8000637a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	42c080e7          	jalr	1068(ra) # 80006390 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	60c080e7          	jalr	1548(ra) # 80003578 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	c9c080e7          	jalr	-868(ra) # 80003c10 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	c46080e7          	jalr	-954(ra) # 80004bc2 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	52e080e7          	jalr	1326(ra) # 800064b2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	d72080e7          	jalr	-654(ra) # 80001cfe <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	5fe080e7          	jalr	1534(ra) # 8000183e <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    8000183e:	715d                	addi	sp,sp,-80
    80001840:	e486                	sd	ra,72(sp)
    80001842:	e0a2                	sd	s0,64(sp)
    80001844:	fc26                	sd	s1,56(sp)
    80001846:	f84a                	sd	s2,48(sp)
    80001848:	f44e                	sd	s3,40(sp)
    8000184a:	f052                	sd	s4,32(sp)
    8000184c:	ec56                	sd	s5,24(sp)
    8000184e:	e85a                	sd	s6,16(sp)
    80001850:	e45e                	sd	s7,8(sp)
    80001852:	0880                	addi	s0,sp,80
    80001854:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001856:	00010497          	auipc	s1,0x10
    8000185a:	e7a48493          	addi	s1,s1,-390 # 800116d0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    8000185e:	8ba6                	mv	s7,s1
    80001860:	00006b17          	auipc	s6,0x6
    80001864:	7a0b0b13          	addi	s6,s6,1952 # 80008000 <etext>
    80001868:	04000937          	lui	s2,0x4000
    8000186c:	197d                	addi	s2,s2,-1
    8000186e:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001870:	698d                	lui	s3,0x3
    80001872:	06898993          	addi	s3,s3,104 # 3068 <_entry-0x7fffcf98>
    80001876:	000d2a97          	auipc	s5,0xd2
    8000187a:	85aa8a93          	addi	s5,s5,-1958 # 800d30d0 <tickslock>
    char *pa = kalloc();
    8000187e:	fffff097          	auipc	ra,0xfffff
    80001882:	276080e7          	jalr	630(ra) # 80000af4 <kalloc>
    80001886:	862a                	mv	a2,a0
    if (pa == 0)
    80001888:	c131                	beqz	a0,800018cc <proc_mapstacks+0x8e>
    uint64 va = KSTACK((int)(p - proc));
    8000188a:	417485b3          	sub	a1,s1,s7
    8000188e:	858d                	srai	a1,a1,0x3
    80001890:	000b3783          	ld	a5,0(s6)
    80001894:	02f585b3          	mul	a1,a1,a5
    80001898:	2585                	addiw	a1,a1,1
    8000189a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000189e:	4719                	li	a4,6
    800018a0:	6685                	lui	a3,0x1
    800018a2:	40b905b3          	sub	a1,s2,a1
    800018a6:	8552                	mv	a0,s4
    800018a8:	00000097          	auipc	ra,0x0
    800018ac:	8a8080e7          	jalr	-1880(ra) # 80001150 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018b0:	94ce                	add	s1,s1,s3
    800018b2:	fd5496e3          	bne	s1,s5,8000187e <proc_mapstacks+0x40>
  }
}
    800018b6:	60a6                	ld	ra,72(sp)
    800018b8:	6406                	ld	s0,64(sp)
    800018ba:	74e2                	ld	s1,56(sp)
    800018bc:	7942                	ld	s2,48(sp)
    800018be:	79a2                	ld	s3,40(sp)
    800018c0:	7a02                	ld	s4,32(sp)
    800018c2:	6ae2                	ld	s5,24(sp)
    800018c4:	6b42                	ld	s6,16(sp)
    800018c6:	6ba2                	ld	s7,8(sp)
    800018c8:	6161                	addi	sp,sp,80
    800018ca:	8082                	ret
      panic("kalloc");
    800018cc:	00007517          	auipc	a0,0x7
    800018d0:	90c50513          	addi	a0,a0,-1780 # 800081d8 <digits+0x198>
    800018d4:	fffff097          	auipc	ra,0xfffff
    800018d8:	c6a080e7          	jalr	-918(ra) # 8000053e <panic>

00000000800018dc <procinit>:

// initialize the proc table at boot time.
void procinit(void)
{
    800018dc:	715d                	addi	sp,sp,-80
    800018de:	e486                	sd	ra,72(sp)
    800018e0:	e0a2                	sd	s0,64(sp)
    800018e2:	fc26                	sd	s1,56(sp)
    800018e4:	f84a                	sd	s2,48(sp)
    800018e6:	f44e                	sd	s3,40(sp)
    800018e8:	f052                	sd	s4,32(sp)
    800018ea:	ec56                	sd	s5,24(sp)
    800018ec:	e85a                	sd	s6,16(sp)
    800018ee:	e45e                	sd	s7,8(sp)
    800018f0:	0880                	addi	s0,sp,80
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018f2:	00007597          	auipc	a1,0x7
    800018f6:	8ee58593          	addi	a1,a1,-1810 # 800081e0 <digits+0x1a0>
    800018fa:	00010517          	auipc	a0,0x10
    800018fe:	9a650513          	addi	a0,a0,-1626 # 800112a0 <pid_lock>
    80001902:	fffff097          	auipc	ra,0xfffff
    80001906:	252080e7          	jalr	594(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    8000190a:	00007597          	auipc	a1,0x7
    8000190e:	8de58593          	addi	a1,a1,-1826 # 800081e8 <digits+0x1a8>
    80001912:	00010517          	auipc	a0,0x10
    80001916:	9a650513          	addi	a0,a0,-1626 # 800112b8 <wait_lock>
    8000191a:	fffff097          	auipc	ra,0xfffff
    8000191e:	23a080e7          	jalr	570(ra) # 80000b54 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001922:	00010497          	auipc	s1,0x10
    80001926:	dae48493          	addi	s1,s1,-594 # 800116d0 <proc>
  {
    initlock(&p->lock, "proc");
    8000192a:	00007b97          	auipc	s7,0x7
    8000192e:	8ceb8b93          	addi	s7,s7,-1842 # 800081f8 <digits+0x1b8>
    p->kstack = KSTACK((int)(p - proc));
    80001932:	8b26                	mv	s6,s1
    80001934:	00006a97          	auipc	s5,0x6
    80001938:	6cca8a93          	addi	s5,s5,1740 # 80008000 <etext>
    8000193c:	04000937          	lui	s2,0x4000
    80001940:	197d                	addi	s2,s2,-1
    80001942:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001944:	698d                	lui	s3,0x3
    80001946:	06898993          	addi	s3,s3,104 # 3068 <_entry-0x7fffcf98>
    8000194a:	000d1a17          	auipc	s4,0xd1
    8000194e:	786a0a13          	addi	s4,s4,1926 # 800d30d0 <tickslock>
    initlock(&p->lock, "proc");
    80001952:	85de                	mv	a1,s7
    80001954:	8526                	mv	a0,s1
    80001956:	fffff097          	auipc	ra,0xfffff
    8000195a:	1fe080e7          	jalr	510(ra) # 80000b54 <initlock>
    p->kstack = KSTACK((int)(p - proc));
    8000195e:	416487b3          	sub	a5,s1,s6
    80001962:	878d                	srai	a5,a5,0x3
    80001964:	000ab703          	ld	a4,0(s5)
    80001968:	02e787b3          	mul	a5,a5,a4
    8000196c:	2785                	addiw	a5,a5,1
    8000196e:	00d7979b          	slliw	a5,a5,0xd
    80001972:	40f907b3          	sub	a5,s2,a5
    80001976:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001978:	94ce                	add	s1,s1,s3
    8000197a:	fd449ce3          	bne	s1,s4,80001952 <procinit+0x76>
  }
  p->syscall_index = 0;
    8000197e:	000d5797          	auipc	a5,0xd5
    80001982:	d5278793          	addi	a5,a5,-686 # 800d66d0 <bcache+0x35e8>
    80001986:	a407aa23          	sw	zero,-1452(a5)
  p->is_trace = 0;
    8000198a:	a407ae23          	sw	zero,-1444(a5)
}
    8000198e:	60a6                	ld	ra,72(sp)
    80001990:	6406                	ld	s0,64(sp)
    80001992:	74e2                	ld	s1,56(sp)
    80001994:	7942                	ld	s2,48(sp)
    80001996:	79a2                	ld	s3,40(sp)
    80001998:	7a02                	ld	s4,32(sp)
    8000199a:	6ae2                	ld	s5,24(sp)
    8000199c:	6b42                	ld	s6,16(sp)
    8000199e:	6ba2                	ld	s7,8(sp)
    800019a0:	6161                	addi	sp,sp,80
    800019a2:	8082                	ret

00000000800019a4 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    800019a4:	1141                	addi	sp,sp,-16
    800019a6:	e422                	sd	s0,8(sp)
    800019a8:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019aa:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019ac:	2501                	sext.w	a0,a0
    800019ae:	6422                	ld	s0,8(sp)
    800019b0:	0141                	addi	sp,sp,16
    800019b2:	8082                	ret

00000000800019b4 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    800019b4:	1141                	addi	sp,sp,-16
    800019b6:	e422                	sd	s0,8(sp)
    800019b8:	0800                	addi	s0,sp,16
    800019ba:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019bc:	2781                	sext.w	a5,a5
    800019be:	079e                	slli	a5,a5,0x7
  return c;
}
    800019c0:	00010517          	auipc	a0,0x10
    800019c4:	91050513          	addi	a0,a0,-1776 # 800112d0 <cpus>
    800019c8:	953e                	add	a0,a0,a5
    800019ca:	6422                	ld	s0,8(sp)
    800019cc:	0141                	addi	sp,sp,16
    800019ce:	8082                	ret

00000000800019d0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019d0:	1101                	addi	sp,sp,-32
    800019d2:	ec06                	sd	ra,24(sp)
    800019d4:	e822                	sd	s0,16(sp)
    800019d6:	e426                	sd	s1,8(sp)
    800019d8:	1000                	addi	s0,sp,32
  push_off();
    800019da:	fffff097          	auipc	ra,0xfffff
    800019de:	1be080e7          	jalr	446(ra) # 80000b98 <push_off>
    800019e2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019e4:	2781                	sext.w	a5,a5
    800019e6:	079e                	slli	a5,a5,0x7
    800019e8:	00010717          	auipc	a4,0x10
    800019ec:	8b870713          	addi	a4,a4,-1864 # 800112a0 <pid_lock>
    800019f0:	97ba                	add	a5,a5,a4
    800019f2:	7b84                	ld	s1,48(a5)
  pop_off();
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	244080e7          	jalr	580(ra) # 80000c38 <pop_off>
  return p;
}
    800019fc:	8526                	mv	a0,s1
    800019fe:	60e2                	ld	ra,24(sp)
    80001a00:	6442                	ld	s0,16(sp)
    80001a02:	64a2                	ld	s1,8(sp)
    80001a04:	6105                	addi	sp,sp,32
    80001a06:	8082                	ret

0000000080001a08 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001a08:	1141                	addi	sp,sp,-16
    80001a0a:	e406                	sd	ra,8(sp)
    80001a0c:	e022                	sd	s0,0(sp)
    80001a0e:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a10:	00000097          	auipc	ra,0x0
    80001a14:	fc0080e7          	jalr	-64(ra) # 800019d0 <myproc>
    80001a18:	fffff097          	auipc	ra,0xfffff
    80001a1c:	280080e7          	jalr	640(ra) # 80000c98 <release>

  if (first)
    80001a20:	00007797          	auipc	a5,0x7
    80001a24:	fb07a783          	lw	a5,-80(a5) # 800089d0 <first.1732>
    80001a28:	eb89                	bnez	a5,80001a3a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a2a:	00001097          	auipc	ra,0x1
    80001a2e:	fc0080e7          	jalr	-64(ra) # 800029ea <usertrapret>
}
    80001a32:	60a2                	ld	ra,8(sp)
    80001a34:	6402                	ld	s0,0(sp)
    80001a36:	0141                	addi	sp,sp,16
    80001a38:	8082                	ret
    first = 0;
    80001a3a:	00007797          	auipc	a5,0x7
    80001a3e:	f807ab23          	sw	zero,-106(a5) # 800089d0 <first.1732>
    fsinit(ROOTDEV);
    80001a42:	4505                	li	a0,1
    80001a44:	00002097          	auipc	ra,0x2
    80001a48:	14c080e7          	jalr	332(ra) # 80003b90 <fsinit>
    80001a4c:	bff9                	j	80001a2a <forkret+0x22>

0000000080001a4e <allocpid>:
{
    80001a4e:	1101                	addi	sp,sp,-32
    80001a50:	ec06                	sd	ra,24(sp)
    80001a52:	e822                	sd	s0,16(sp)
    80001a54:	e426                	sd	s1,8(sp)
    80001a56:	e04a                	sd	s2,0(sp)
    80001a58:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a5a:	00010917          	auipc	s2,0x10
    80001a5e:	84690913          	addi	s2,s2,-1978 # 800112a0 <pid_lock>
    80001a62:	854a                	mv	a0,s2
    80001a64:	fffff097          	auipc	ra,0xfffff
    80001a68:	180080e7          	jalr	384(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a6c:	00007797          	auipc	a5,0x7
    80001a70:	f6878793          	addi	a5,a5,-152 # 800089d4 <nextpid>
    80001a74:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a76:	0014871b          	addiw	a4,s1,1
    80001a7a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a7c:	854a                	mv	a0,s2
    80001a7e:	fffff097          	auipc	ra,0xfffff
    80001a82:	21a080e7          	jalr	538(ra) # 80000c98 <release>
}
    80001a86:	8526                	mv	a0,s1
    80001a88:	60e2                	ld	ra,24(sp)
    80001a8a:	6442                	ld	s0,16(sp)
    80001a8c:	64a2                	ld	s1,8(sp)
    80001a8e:	6902                	ld	s2,0(sp)
    80001a90:	6105                	addi	sp,sp,32
    80001a92:	8082                	ret

0000000080001a94 <proc_pagetable>:
{
    80001a94:	1101                	addi	sp,sp,-32
    80001a96:	ec06                	sd	ra,24(sp)
    80001a98:	e822                	sd	s0,16(sp)
    80001a9a:	e426                	sd	s1,8(sp)
    80001a9c:	e04a                	sd	s2,0(sp)
    80001a9e:	1000                	addi	s0,sp,32
    80001aa0:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001aa2:	00000097          	auipc	ra,0x0
    80001aa6:	898080e7          	jalr	-1896(ra) # 8000133a <uvmcreate>
    80001aaa:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001aac:	c121                	beqz	a0,80001aec <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aae:	4729                	li	a4,10
    80001ab0:	00005697          	auipc	a3,0x5
    80001ab4:	55068693          	addi	a3,a3,1360 # 80007000 <_trampoline>
    80001ab8:	6605                	lui	a2,0x1
    80001aba:	040005b7          	lui	a1,0x4000
    80001abe:	15fd                	addi	a1,a1,-1
    80001ac0:	05b2                	slli	a1,a1,0xc
    80001ac2:	fffff097          	auipc	ra,0xfffff
    80001ac6:	5ee080e7          	jalr	1518(ra) # 800010b0 <mappages>
    80001aca:	02054863          	bltz	a0,80001afa <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ace:	4719                	li	a4,6
    80001ad0:	05893683          	ld	a3,88(s2)
    80001ad4:	6605                	lui	a2,0x1
    80001ad6:	020005b7          	lui	a1,0x2000
    80001ada:	15fd                	addi	a1,a1,-1
    80001adc:	05b6                	slli	a1,a1,0xd
    80001ade:	8526                	mv	a0,s1
    80001ae0:	fffff097          	auipc	ra,0xfffff
    80001ae4:	5d0080e7          	jalr	1488(ra) # 800010b0 <mappages>
    80001ae8:	02054163          	bltz	a0,80001b0a <proc_pagetable+0x76>
}
    80001aec:	8526                	mv	a0,s1
    80001aee:	60e2                	ld	ra,24(sp)
    80001af0:	6442                	ld	s0,16(sp)
    80001af2:	64a2                	ld	s1,8(sp)
    80001af4:	6902                	ld	s2,0(sp)
    80001af6:	6105                	addi	sp,sp,32
    80001af8:	8082                	ret
    uvmfree(pagetable, 0);
    80001afa:	4581                	li	a1,0
    80001afc:	8526                	mv	a0,s1
    80001afe:	00000097          	auipc	ra,0x0
    80001b02:	a38080e7          	jalr	-1480(ra) # 80001536 <uvmfree>
    return 0;
    80001b06:	4481                	li	s1,0
    80001b08:	b7d5                	j	80001aec <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b0a:	4681                	li	a3,0
    80001b0c:	4605                	li	a2,1
    80001b0e:	040005b7          	lui	a1,0x4000
    80001b12:	15fd                	addi	a1,a1,-1
    80001b14:	05b2                	slli	a1,a1,0xc
    80001b16:	8526                	mv	a0,s1
    80001b18:	fffff097          	auipc	ra,0xfffff
    80001b1c:	75e080e7          	jalr	1886(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b20:	4581                	li	a1,0
    80001b22:	8526                	mv	a0,s1
    80001b24:	00000097          	auipc	ra,0x0
    80001b28:	a12080e7          	jalr	-1518(ra) # 80001536 <uvmfree>
    return 0;
    80001b2c:	4481                	li	s1,0
    80001b2e:	bf7d                	j	80001aec <proc_pagetable+0x58>

0000000080001b30 <proc_freepagetable>:
{
    80001b30:	1101                	addi	sp,sp,-32
    80001b32:	ec06                	sd	ra,24(sp)
    80001b34:	e822                	sd	s0,16(sp)
    80001b36:	e426                	sd	s1,8(sp)
    80001b38:	e04a                	sd	s2,0(sp)
    80001b3a:	1000                	addi	s0,sp,32
    80001b3c:	84aa                	mv	s1,a0
    80001b3e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b40:	4681                	li	a3,0
    80001b42:	4605                	li	a2,1
    80001b44:	040005b7          	lui	a1,0x4000
    80001b48:	15fd                	addi	a1,a1,-1
    80001b4a:	05b2                	slli	a1,a1,0xc
    80001b4c:	fffff097          	auipc	ra,0xfffff
    80001b50:	72a080e7          	jalr	1834(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b54:	4681                	li	a3,0
    80001b56:	4605                	li	a2,1
    80001b58:	020005b7          	lui	a1,0x2000
    80001b5c:	15fd                	addi	a1,a1,-1
    80001b5e:	05b6                	slli	a1,a1,0xd
    80001b60:	8526                	mv	a0,s1
    80001b62:	fffff097          	auipc	ra,0xfffff
    80001b66:	714080e7          	jalr	1812(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b6a:	85ca                	mv	a1,s2
    80001b6c:	8526                	mv	a0,s1
    80001b6e:	00000097          	auipc	ra,0x0
    80001b72:	9c8080e7          	jalr	-1592(ra) # 80001536 <uvmfree>
}
    80001b76:	60e2                	ld	ra,24(sp)
    80001b78:	6442                	ld	s0,16(sp)
    80001b7a:	64a2                	ld	s1,8(sp)
    80001b7c:	6902                	ld	s2,0(sp)
    80001b7e:	6105                	addi	sp,sp,32
    80001b80:	8082                	ret

0000000080001b82 <freeproc>:
{
    80001b82:	1101                	addi	sp,sp,-32
    80001b84:	ec06                	sd	ra,24(sp)
    80001b86:	e822                	sd	s0,16(sp)
    80001b88:	e426                	sd	s1,8(sp)
    80001b8a:	1000                	addi	s0,sp,32
    80001b8c:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b8e:	6d28                	ld	a0,88(a0)
    80001b90:	c509                	beqz	a0,80001b9a <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b92:	fffff097          	auipc	ra,0xfffff
    80001b96:	e66080e7          	jalr	-410(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b9a:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001b9e:	68a8                	ld	a0,80(s1)
    80001ba0:	c511                	beqz	a0,80001bac <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ba2:	64ac                	ld	a1,72(s1)
    80001ba4:	00000097          	auipc	ra,0x0
    80001ba8:	f8c080e7          	jalr	-116(ra) # 80001b30 <proc_freepagetable>
  p->pagetable = 0;
    80001bac:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bb0:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bb4:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bb8:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bbc:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bc0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bc4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bc8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bcc:	0004ac23          	sw	zero,24(s1)
}
    80001bd0:	60e2                	ld	ra,24(sp)
    80001bd2:	6442                	ld	s0,16(sp)
    80001bd4:	64a2                	ld	s1,8(sp)
    80001bd6:	6105                	addi	sp,sp,32
    80001bd8:	8082                	ret

0000000080001bda <allocproc>:
{
    80001bda:	7179                	addi	sp,sp,-48
    80001bdc:	f406                	sd	ra,40(sp)
    80001bde:	f022                	sd	s0,32(sp)
    80001be0:	ec26                	sd	s1,24(sp)
    80001be2:	e84a                	sd	s2,16(sp)
    80001be4:	e44e                	sd	s3,8(sp)
    80001be6:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++)
    80001be8:	00010497          	auipc	s1,0x10
    80001bec:	ae848493          	addi	s1,s1,-1304 # 800116d0 <proc>
    80001bf0:	690d                	lui	s2,0x3
    80001bf2:	06890913          	addi	s2,s2,104 # 3068 <_entry-0x7fffcf98>
    80001bf6:	000d1997          	auipc	s3,0xd1
    80001bfa:	4da98993          	addi	s3,s3,1242 # 800d30d0 <tickslock>
    acquire(&p->lock);
    80001bfe:	8526                	mv	a0,s1
    80001c00:	fffff097          	auipc	ra,0xfffff
    80001c04:	fe4080e7          	jalr	-28(ra) # 80000be4 <acquire>
    if (p->state == UNUSED)
    80001c08:	4c9c                	lw	a5,24(s1)
    80001c0a:	cb99                	beqz	a5,80001c20 <allocproc+0x46>
      release(&p->lock);
    80001c0c:	8526                	mv	a0,s1
    80001c0e:	fffff097          	auipc	ra,0xfffff
    80001c12:	08a080e7          	jalr	138(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001c16:	94ca                	add	s1,s1,s2
    80001c18:	ff3493e3          	bne	s1,s3,80001bfe <allocproc+0x24>
  return 0;
    80001c1c:	4481                	li	s1,0
    80001c1e:	a89d                	j	80001c94 <allocproc+0xba>
  p->pid = allocpid();
    80001c20:	00000097          	auipc	ra,0x0
    80001c24:	e2e080e7          	jalr	-466(ra) # 80001a4e <allocpid>
    80001c28:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c2a:	4785                	li	a5,1
    80001c2c:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c2e:	fffff097          	auipc	ra,0xfffff
    80001c32:	ec6080e7          	jalr	-314(ra) # 80000af4 <kalloc>
    80001c36:	892a                	mv	s2,a0
    80001c38:	eca8                	sd	a0,88(s1)
    80001c3a:	c52d                	beqz	a0,80001ca4 <allocproc+0xca>
  p->pagetable = proc_pagetable(p);
    80001c3c:	8526                	mv	a0,s1
    80001c3e:	00000097          	auipc	ra,0x0
    80001c42:	e56080e7          	jalr	-426(ra) # 80001a94 <proc_pagetable>
    80001c46:	892a                	mv	s2,a0
    80001c48:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c4a:	c92d                	beqz	a0,80001cbc <allocproc+0xe2>
  memset(&p->context, 0, sizeof(p->context));
    80001c4c:	07000613          	li	a2,112
    80001c50:	4581                	li	a1,0
    80001c52:	06048513          	addi	a0,s1,96
    80001c56:	fffff097          	auipc	ra,0xfffff
    80001c5a:	08a080e7          	jalr	138(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c5e:	00000797          	auipc	a5,0x0
    80001c62:	daa78793          	addi	a5,a5,-598 # 80001a08 <forkret>
    80001c66:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c68:	60bc                	ld	a5,64(s1)
    80001c6a:	6705                	lui	a4,0x1
    80001c6c:	97ba                	add	a5,a5,a4
    80001c6e:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001c70:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001c74:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001c78:	00007797          	auipc	a5,0x7
    80001c7c:	3c07a783          	lw	a5,960(a5) # 80009038 <ticks>
    80001c80:	16f4a623          	sw	a5,364(s1)
  p->syscall_index = 0;
    80001c84:	678d                	lui	a5,0x3
    80001c86:	97a6                	add	a5,a5,s1
    80001c88:	0407aa23          	sw	zero,84(a5) # 3054 <_entry-0x7fffcfac>
  p->is_trace = 0;
    80001c8c:	0407ae23          	sw	zero,92(a5)
  p->mask = 0;
    80001c90:	0407ac23          	sw	zero,88(a5)
}
    80001c94:	8526                	mv	a0,s1
    80001c96:	70a2                	ld	ra,40(sp)
    80001c98:	7402                	ld	s0,32(sp)
    80001c9a:	64e2                	ld	s1,24(sp)
    80001c9c:	6942                	ld	s2,16(sp)
    80001c9e:	69a2                	ld	s3,8(sp)
    80001ca0:	6145                	addi	sp,sp,48
    80001ca2:	8082                	ret
    freeproc(p);
    80001ca4:	8526                	mv	a0,s1
    80001ca6:	00000097          	auipc	ra,0x0
    80001caa:	edc080e7          	jalr	-292(ra) # 80001b82 <freeproc>
    release(&p->lock);
    80001cae:	8526                	mv	a0,s1
    80001cb0:	fffff097          	auipc	ra,0xfffff
    80001cb4:	fe8080e7          	jalr	-24(ra) # 80000c98 <release>
    return 0;
    80001cb8:	84ca                	mv	s1,s2
    80001cba:	bfe9                	j	80001c94 <allocproc+0xba>
    freeproc(p);
    80001cbc:	8526                	mv	a0,s1
    80001cbe:	00000097          	auipc	ra,0x0
    80001cc2:	ec4080e7          	jalr	-316(ra) # 80001b82 <freeproc>
    release(&p->lock);
    80001cc6:	8526                	mv	a0,s1
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	fd0080e7          	jalr	-48(ra) # 80000c98 <release>
    return 0;
    80001cd0:	84ca                	mv	s1,s2
    80001cd2:	b7c9                	j	80001c94 <allocproc+0xba>

0000000080001cd4 <trace>:
{
    80001cd4:	1101                	addi	sp,sp,-32
    80001cd6:	ec06                	sd	ra,24(sp)
    80001cd8:	e822                	sd	s0,16(sp)
    80001cda:	e426                	sd	s1,8(sp)
    80001cdc:	1000                	addi	s0,sp,32
    80001cde:	84aa                	mv	s1,a0
  p = myproc();
    80001ce0:	00000097          	auipc	ra,0x0
    80001ce4:	cf0080e7          	jalr	-784(ra) # 800019d0 <myproc>
  p->is_trace = 1;
    80001ce8:	678d                	lui	a5,0x3
    80001cea:	97aa                	add	a5,a5,a0
    80001cec:	4705                	li	a4,1
    80001cee:	cff8                	sw	a4,92(a5)
  p->mask = mask;
    80001cf0:	cfa4                	sw	s1,88(a5)
}
    80001cf2:	4501                	li	a0,0
    80001cf4:	60e2                	ld	ra,24(sp)
    80001cf6:	6442                	ld	s0,16(sp)
    80001cf8:	64a2                	ld	s1,8(sp)
    80001cfa:	6105                	addi	sp,sp,32
    80001cfc:	8082                	ret

0000000080001cfe <userinit>:
{
    80001cfe:	1101                	addi	sp,sp,-32
    80001d00:	ec06                	sd	ra,24(sp)
    80001d02:	e822                	sd	s0,16(sp)
    80001d04:	e426                	sd	s1,8(sp)
    80001d06:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d08:	00000097          	auipc	ra,0x0
    80001d0c:	ed2080e7          	jalr	-302(ra) # 80001bda <allocproc>
    80001d10:	84aa                	mv	s1,a0
  initproc = p;
    80001d12:	00007797          	auipc	a5,0x7
    80001d16:	30a7bf23          	sd	a0,798(a5) # 80009030 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d1a:	03400613          	li	a2,52
    80001d1e:	00007597          	auipc	a1,0x7
    80001d22:	cc258593          	addi	a1,a1,-830 # 800089e0 <initcode>
    80001d26:	6928                	ld	a0,80(a0)
    80001d28:	fffff097          	auipc	ra,0xfffff
    80001d2c:	640080e7          	jalr	1600(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001d30:	6785                	lui	a5,0x1
    80001d32:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001d34:	6cb8                	ld	a4,88(s1)
    80001d36:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001d3a:	6cb8                	ld	a4,88(s1)
    80001d3c:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d3e:	4641                	li	a2,16
    80001d40:	00006597          	auipc	a1,0x6
    80001d44:	4c058593          	addi	a1,a1,1216 # 80008200 <digits+0x1c0>
    80001d48:	15848513          	addi	a0,s1,344
    80001d4c:	fffff097          	auipc	ra,0xfffff
    80001d50:	0e6080e7          	jalr	230(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d54:	00006517          	auipc	a0,0x6
    80001d58:	4bc50513          	addi	a0,a0,1212 # 80008210 <digits+0x1d0>
    80001d5c:	00003097          	auipc	ra,0x3
    80001d60:	862080e7          	jalr	-1950(ra) # 800045be <namei>
    80001d64:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d68:	478d                	li	a5,3
    80001d6a:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d6c:	8526                	mv	a0,s1
    80001d6e:	fffff097          	auipc	ra,0xfffff
    80001d72:	f2a080e7          	jalr	-214(ra) # 80000c98 <release>
}
    80001d76:	60e2                	ld	ra,24(sp)
    80001d78:	6442                	ld	s0,16(sp)
    80001d7a:	64a2                	ld	s1,8(sp)
    80001d7c:	6105                	addi	sp,sp,32
    80001d7e:	8082                	ret

0000000080001d80 <growproc>:
{
    80001d80:	1101                	addi	sp,sp,-32
    80001d82:	ec06                	sd	ra,24(sp)
    80001d84:	e822                	sd	s0,16(sp)
    80001d86:	e426                	sd	s1,8(sp)
    80001d88:	e04a                	sd	s2,0(sp)
    80001d8a:	1000                	addi	s0,sp,32
    80001d8c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d8e:	00000097          	auipc	ra,0x0
    80001d92:	c42080e7          	jalr	-958(ra) # 800019d0 <myproc>
    80001d96:	892a                	mv	s2,a0
  sz = p->sz;
    80001d98:	652c                	ld	a1,72(a0)
    80001d9a:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001d9e:	00904f63          	bgtz	s1,80001dbc <growproc+0x3c>
  else if (n < 0)
    80001da2:	0204cc63          	bltz	s1,80001dda <growproc+0x5a>
  p->sz = sz;
    80001da6:	1602                	slli	a2,a2,0x20
    80001da8:	9201                	srli	a2,a2,0x20
    80001daa:	04c93423          	sd	a2,72(s2)
  return 0;
    80001dae:	4501                	li	a0,0
}
    80001db0:	60e2                	ld	ra,24(sp)
    80001db2:	6442                	ld	s0,16(sp)
    80001db4:	64a2                	ld	s1,8(sp)
    80001db6:	6902                	ld	s2,0(sp)
    80001db8:	6105                	addi	sp,sp,32
    80001dba:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001dbc:	9e25                	addw	a2,a2,s1
    80001dbe:	1602                	slli	a2,a2,0x20
    80001dc0:	9201                	srli	a2,a2,0x20
    80001dc2:	1582                	slli	a1,a1,0x20
    80001dc4:	9181                	srli	a1,a1,0x20
    80001dc6:	6928                	ld	a0,80(a0)
    80001dc8:	fffff097          	auipc	ra,0xfffff
    80001dcc:	65a080e7          	jalr	1626(ra) # 80001422 <uvmalloc>
    80001dd0:	0005061b          	sext.w	a2,a0
    80001dd4:	fa69                	bnez	a2,80001da6 <growproc+0x26>
      return -1;
    80001dd6:	557d                	li	a0,-1
    80001dd8:	bfe1                	j	80001db0 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dda:	9e25                	addw	a2,a2,s1
    80001ddc:	1602                	slli	a2,a2,0x20
    80001dde:	9201                	srli	a2,a2,0x20
    80001de0:	1582                	slli	a1,a1,0x20
    80001de2:	9181                	srli	a1,a1,0x20
    80001de4:	6928                	ld	a0,80(a0)
    80001de6:	fffff097          	auipc	ra,0xfffff
    80001dea:	5f4080e7          	jalr	1524(ra) # 800013da <uvmdealloc>
    80001dee:	0005061b          	sext.w	a2,a0
    80001df2:	bf55                	j	80001da6 <growproc+0x26>

0000000080001df4 <fork>:
{
    80001df4:	7179                	addi	sp,sp,-48
    80001df6:	f406                	sd	ra,40(sp)
    80001df8:	f022                	sd	s0,32(sp)
    80001dfa:	ec26                	sd	s1,24(sp)
    80001dfc:	e84a                	sd	s2,16(sp)
    80001dfe:	e44e                	sd	s3,8(sp)
    80001e00:	e052                	sd	s4,0(sp)
    80001e02:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e04:	00000097          	auipc	ra,0x0
    80001e08:	bcc080e7          	jalr	-1076(ra) # 800019d0 <myproc>
    80001e0c:	892a                	mv	s2,a0
  if ((np = allocproc()) == 0)
    80001e0e:	00000097          	auipc	ra,0x0
    80001e12:	dcc080e7          	jalr	-564(ra) # 80001bda <allocproc>
    80001e16:	12050863          	beqz	a0,80001f46 <fork+0x152>
    80001e1a:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001e1c:	04893603          	ld	a2,72(s2)
    80001e20:	692c                	ld	a1,80(a0)
    80001e22:	05093503          	ld	a0,80(s2)
    80001e26:	fffff097          	auipc	ra,0xfffff
    80001e2a:	748080e7          	jalr	1864(ra) # 8000156e <uvmcopy>
    80001e2e:	04054663          	bltz	a0,80001e7a <fork+0x86>
  np->sz = p->sz;
    80001e32:	04893783          	ld	a5,72(s2)
    80001e36:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e3a:	05893683          	ld	a3,88(s2)
    80001e3e:	87b6                	mv	a5,a3
    80001e40:	0589b703          	ld	a4,88(s3)
    80001e44:	12068693          	addi	a3,a3,288
    80001e48:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e4c:	6788                	ld	a0,8(a5)
    80001e4e:	6b8c                	ld	a1,16(a5)
    80001e50:	6f90                	ld	a2,24(a5)
    80001e52:	01073023          	sd	a6,0(a4)
    80001e56:	e708                	sd	a0,8(a4)
    80001e58:	eb0c                	sd	a1,16(a4)
    80001e5a:	ef10                	sd	a2,24(a4)
    80001e5c:	02078793          	addi	a5,a5,32
    80001e60:	02070713          	addi	a4,a4,32
    80001e64:	fed792e3          	bne	a5,a3,80001e48 <fork+0x54>
  np->trapframe->a0 = 0;
    80001e68:	0589b783          	ld	a5,88(s3)
    80001e6c:	0607b823          	sd	zero,112(a5)
    80001e70:	0d000493          	li	s1,208
  for (i = 0; i < NOFILE; i++)
    80001e74:	15000a13          	li	s4,336
    80001e78:	a03d                	j	80001ea6 <fork+0xb2>
    freeproc(np);
    80001e7a:	854e                	mv	a0,s3
    80001e7c:	00000097          	auipc	ra,0x0
    80001e80:	d06080e7          	jalr	-762(ra) # 80001b82 <freeproc>
    release(&np->lock);
    80001e84:	854e                	mv	a0,s3
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	e12080e7          	jalr	-494(ra) # 80000c98 <release>
    return -1;
    80001e8e:	5a7d                	li	s4,-1
    80001e90:	a055                	j	80001f34 <fork+0x140>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e92:	00003097          	auipc	ra,0x3
    80001e96:	dc2080e7          	jalr	-574(ra) # 80004c54 <filedup>
    80001e9a:	009987b3          	add	a5,s3,s1
    80001e9e:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    80001ea0:	04a1                	addi	s1,s1,8
    80001ea2:	01448763          	beq	s1,s4,80001eb0 <fork+0xbc>
    if (p->ofile[i])
    80001ea6:	009907b3          	add	a5,s2,s1
    80001eaa:	6388                	ld	a0,0(a5)
    80001eac:	f17d                	bnez	a0,80001e92 <fork+0x9e>
    80001eae:	bfcd                	j	80001ea0 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001eb0:	15093503          	ld	a0,336(s2)
    80001eb4:	00002097          	auipc	ra,0x2
    80001eb8:	f16080e7          	jalr	-234(ra) # 80003dca <idup>
    80001ebc:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ec0:	4641                	li	a2,16
    80001ec2:	15890593          	addi	a1,s2,344
    80001ec6:	15898513          	addi	a0,s3,344
    80001eca:	fffff097          	auipc	ra,0xfffff
    80001ece:	f68080e7          	jalr	-152(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001ed2:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001ed6:	854e                	mv	a0,s3
    80001ed8:	fffff097          	auipc	ra,0xfffff
    80001edc:	dc0080e7          	jalr	-576(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001ee0:	0000f497          	auipc	s1,0xf
    80001ee4:	3d848493          	addi	s1,s1,984 # 800112b8 <wait_lock>
    80001ee8:	8526                	mv	a0,s1
    80001eea:	fffff097          	auipc	ra,0xfffff
    80001eee:	cfa080e7          	jalr	-774(ra) # 80000be4 <acquire>
  np->parent = p;
    80001ef2:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001ef6:	8526                	mv	a0,s1
    80001ef8:	fffff097          	auipc	ra,0xfffff
    80001efc:	da0080e7          	jalr	-608(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001f00:	854e                	mv	a0,s3
    80001f02:	fffff097          	auipc	ra,0xfffff
    80001f06:	ce2080e7          	jalr	-798(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001f0a:	478d                	li	a5,3
    80001f0c:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f10:	854e                	mv	a0,s3
    80001f12:	fffff097          	auipc	ra,0xfffff
    80001f16:	d86080e7          	jalr	-634(ra) # 80000c98 <release>
  np->is_trace = p->is_trace;
    80001f1a:	678d                	lui	a5,0x3
    80001f1c:	993e                	add	s2,s2,a5
    80001f1e:	05c92703          	lw	a4,92(s2)
    80001f22:	99be                	add	s3,s3,a5
    80001f24:	04e9ae23          	sw	a4,92(s3)
  np->mask = p->mask;
    80001f28:	05892783          	lw	a5,88(s2)
    80001f2c:	04f9ac23          	sw	a5,88(s3)
  np->syscall_index = 0;
    80001f30:	0409aa23          	sw	zero,84(s3)
}
    80001f34:	8552                	mv	a0,s4
    80001f36:	70a2                	ld	ra,40(sp)
    80001f38:	7402                	ld	s0,32(sp)
    80001f3a:	64e2                	ld	s1,24(sp)
    80001f3c:	6942                	ld	s2,16(sp)
    80001f3e:	69a2                	ld	s3,8(sp)
    80001f40:	6a02                	ld	s4,0(sp)
    80001f42:	6145                	addi	sp,sp,48
    80001f44:	8082                	ret
    return -1;
    80001f46:	5a7d                	li	s4,-1
    80001f48:	b7f5                	j	80001f34 <fork+0x140>

0000000080001f4a <update_time>:
{
    80001f4a:	7179                	addi	sp,sp,-48
    80001f4c:	f406                	sd	ra,40(sp)
    80001f4e:	f022                	sd	s0,32(sp)
    80001f50:	ec26                	sd	s1,24(sp)
    80001f52:	e84a                	sd	s2,16(sp)
    80001f54:	e44e                	sd	s3,8(sp)
    80001f56:	e052                	sd	s4,0(sp)
    80001f58:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++)
    80001f5a:	0000f497          	auipc	s1,0xf
    80001f5e:	77648493          	addi	s1,s1,1910 # 800116d0 <proc>
    if (p->state == RUNNING)
    80001f62:	4a11                	li	s4,4
  for (p = proc; p < &proc[NPROC]; p++)
    80001f64:	690d                	lui	s2,0x3
    80001f66:	06890913          	addi	s2,s2,104 # 3068 <_entry-0x7fffcf98>
    80001f6a:	000d1997          	auipc	s3,0xd1
    80001f6e:	16698993          	addi	s3,s3,358 # 800d30d0 <tickslock>
    80001f72:	a809                	j	80001f84 <update_time+0x3a>
    release(&p->lock);
    80001f74:	8526                	mv	a0,s1
    80001f76:	fffff097          	auipc	ra,0xfffff
    80001f7a:	d22080e7          	jalr	-734(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001f7e:	94ca                	add	s1,s1,s2
    80001f80:	03348063          	beq	s1,s3,80001fa0 <update_time+0x56>
    acquire(&p->lock);
    80001f84:	8526                	mv	a0,s1
    80001f86:	fffff097          	auipc	ra,0xfffff
    80001f8a:	c5e080e7          	jalr	-930(ra) # 80000be4 <acquire>
    if (p->state == RUNNING)
    80001f8e:	4c9c                	lw	a5,24(s1)
    80001f90:	ff4792e3          	bne	a5,s4,80001f74 <update_time+0x2a>
      p->rtime++;
    80001f94:	1684a783          	lw	a5,360(s1)
    80001f98:	2785                	addiw	a5,a5,1
    80001f9a:	16f4a423          	sw	a5,360(s1)
    80001f9e:	bfd9                	j	80001f74 <update_time+0x2a>
}
    80001fa0:	70a2                	ld	ra,40(sp)
    80001fa2:	7402                	ld	s0,32(sp)
    80001fa4:	64e2                	ld	s1,24(sp)
    80001fa6:	6942                	ld	s2,16(sp)
    80001fa8:	69a2                	ld	s3,8(sp)
    80001faa:	6a02                	ld	s4,0(sp)
    80001fac:	6145                	addi	sp,sp,48
    80001fae:	8082                	ret

0000000080001fb0 <scheduler>:
{
    80001fb0:	715d                	addi	sp,sp,-80
    80001fb2:	e486                	sd	ra,72(sp)
    80001fb4:	e0a2                	sd	s0,64(sp)
    80001fb6:	fc26                	sd	s1,56(sp)
    80001fb8:	f84a                	sd	s2,48(sp)
    80001fba:	f44e                	sd	s3,40(sp)
    80001fbc:	f052                	sd	s4,32(sp)
    80001fbe:	ec56                	sd	s5,24(sp)
    80001fc0:	e85a                	sd	s6,16(sp)
    80001fc2:	e45e                	sd	s7,8(sp)
    80001fc4:	0880                	addi	s0,sp,80
    80001fc6:	8792                	mv	a5,tp
  int id = r_tp();
    80001fc8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fca:	00779b13          	slli	s6,a5,0x7
    80001fce:	0000f717          	auipc	a4,0xf
    80001fd2:	2d270713          	addi	a4,a4,722 # 800112a0 <pid_lock>
    80001fd6:	975a                	add	a4,a4,s6
    80001fd8:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001fdc:	0000f717          	auipc	a4,0xf
    80001fe0:	2fc70713          	addi	a4,a4,764 # 800112d8 <cpus+0x8>
    80001fe4:	9b3a                	add	s6,s6,a4
    80001fe6:	6a0d                	lui	s4,0x3
    80001fe8:	060a0b93          	addi	s7,s4,96 # 3060 <_entry-0x7fffcfa0>
        c->proc = p;
    80001fec:	079e                	slli	a5,a5,0x7
    80001fee:	0000fa97          	auipc	s5,0xf
    80001ff2:	2b2a8a93          	addi	s5,s5,690 # 800112a0 <pid_lock>
    80001ff6:	9abe                	add	s5,s5,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001ff8:	068a0a13          	addi	s4,s4,104
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ffc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002000:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002004:	10079073          	csrw	sstatus,a5
    80002008:	0000f497          	auipc	s1,0xf
    8000200c:	6c848493          	addi	s1,s1,1736 # 800116d0 <proc>
      if (p->state == RUNNABLE)
    80002010:	498d                	li	s3,3
    for (p = proc; p < &proc[NPROC]; p++)
    80002012:	000d1917          	auipc	s2,0xd1
    80002016:	0be90913          	addi	s2,s2,190 # 800d30d0 <tickslock>
    8000201a:	a81d                	j	80002050 <scheduler+0xa0>
        p->state = RUNNING;
    8000201c:	4791                	li	a5,4
    8000201e:	cc9c                	sw	a5,24(s1)
        p->nrun++;
    80002020:	01748733          	add	a4,s1,s7
    80002024:	431c                	lw	a5,0(a4)
    80002026:	2785                	addiw	a5,a5,1
    80002028:	c31c                	sw	a5,0(a4)
        c->proc = p;
    8000202a:	029ab823          	sd	s1,48(s5)
        swtch(&c->context, &p->context);
    8000202e:	06048593          	addi	a1,s1,96
    80002032:	855a                	mv	a0,s6
    80002034:	00001097          	auipc	ra,0x1
    80002038:	90c080e7          	jalr	-1780(ra) # 80002940 <swtch>
        c->proc = 0;
    8000203c:	020ab823          	sd	zero,48(s5)
      release(&p->lock);
    80002040:	8526                	mv	a0,s1
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	c56080e7          	jalr	-938(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000204a:	94d2                	add	s1,s1,s4
    8000204c:	fb2488e3          	beq	s1,s2,80001ffc <scheduler+0x4c>
      acquire(&p->lock);
    80002050:	8526                	mv	a0,s1
    80002052:	fffff097          	auipc	ra,0xfffff
    80002056:	b92080e7          	jalr	-1134(ra) # 80000be4 <acquire>
      if (p->state == RUNNABLE)
    8000205a:	4c9c                	lw	a5,24(s1)
    8000205c:	ff3792e3          	bne	a5,s3,80002040 <scheduler+0x90>
    80002060:	bf75                	j	8000201c <scheduler+0x6c>

0000000080002062 <sched>:
{
    80002062:	7179                	addi	sp,sp,-48
    80002064:	f406                	sd	ra,40(sp)
    80002066:	f022                	sd	s0,32(sp)
    80002068:	ec26                	sd	s1,24(sp)
    8000206a:	e84a                	sd	s2,16(sp)
    8000206c:	e44e                	sd	s3,8(sp)
    8000206e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002070:	00000097          	auipc	ra,0x0
    80002074:	960080e7          	jalr	-1696(ra) # 800019d0 <myproc>
    80002078:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    8000207a:	fffff097          	auipc	ra,0xfffff
    8000207e:	af0080e7          	jalr	-1296(ra) # 80000b6a <holding>
    80002082:	c93d                	beqz	a0,800020f8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002084:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002086:	2781                	sext.w	a5,a5
    80002088:	079e                	slli	a5,a5,0x7
    8000208a:	0000f717          	auipc	a4,0xf
    8000208e:	21670713          	addi	a4,a4,534 # 800112a0 <pid_lock>
    80002092:	97ba                	add	a5,a5,a4
    80002094:	0a87a703          	lw	a4,168(a5) # 30a8 <_entry-0x7fffcf58>
    80002098:	4785                	li	a5,1
    8000209a:	06f71763          	bne	a4,a5,80002108 <sched+0xa6>
  if (p->state == RUNNING)
    8000209e:	4c98                	lw	a4,24(s1)
    800020a0:	4791                	li	a5,4
    800020a2:	06f70b63          	beq	a4,a5,80002118 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020a6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020aa:	8b89                	andi	a5,a5,2
  if (intr_get())
    800020ac:	efb5                	bnez	a5,80002128 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020ae:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020b0:	0000f917          	auipc	s2,0xf
    800020b4:	1f090913          	addi	s2,s2,496 # 800112a0 <pid_lock>
    800020b8:	2781                	sext.w	a5,a5
    800020ba:	079e                	slli	a5,a5,0x7
    800020bc:	97ca                	add	a5,a5,s2
    800020be:	0ac7a983          	lw	s3,172(a5)
    800020c2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020c4:	2781                	sext.w	a5,a5
    800020c6:	079e                	slli	a5,a5,0x7
    800020c8:	0000f597          	auipc	a1,0xf
    800020cc:	21058593          	addi	a1,a1,528 # 800112d8 <cpus+0x8>
    800020d0:	95be                	add	a1,a1,a5
    800020d2:	06048513          	addi	a0,s1,96
    800020d6:	00001097          	auipc	ra,0x1
    800020da:	86a080e7          	jalr	-1942(ra) # 80002940 <swtch>
    800020de:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020e0:	2781                	sext.w	a5,a5
    800020e2:	079e                	slli	a5,a5,0x7
    800020e4:	97ca                	add	a5,a5,s2
    800020e6:	0b37a623          	sw	s3,172(a5)
}
    800020ea:	70a2                	ld	ra,40(sp)
    800020ec:	7402                	ld	s0,32(sp)
    800020ee:	64e2                	ld	s1,24(sp)
    800020f0:	6942                	ld	s2,16(sp)
    800020f2:	69a2                	ld	s3,8(sp)
    800020f4:	6145                	addi	sp,sp,48
    800020f6:	8082                	ret
    panic("sched p->lock");
    800020f8:	00006517          	auipc	a0,0x6
    800020fc:	12050513          	addi	a0,a0,288 # 80008218 <digits+0x1d8>
    80002100:	ffffe097          	auipc	ra,0xffffe
    80002104:	43e080e7          	jalr	1086(ra) # 8000053e <panic>
    panic("sched locks");
    80002108:	00006517          	auipc	a0,0x6
    8000210c:	12050513          	addi	a0,a0,288 # 80008228 <digits+0x1e8>
    80002110:	ffffe097          	auipc	ra,0xffffe
    80002114:	42e080e7          	jalr	1070(ra) # 8000053e <panic>
    panic("sched running");
    80002118:	00006517          	auipc	a0,0x6
    8000211c:	12050513          	addi	a0,a0,288 # 80008238 <digits+0x1f8>
    80002120:	ffffe097          	auipc	ra,0xffffe
    80002124:	41e080e7          	jalr	1054(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002128:	00006517          	auipc	a0,0x6
    8000212c:	12050513          	addi	a0,a0,288 # 80008248 <digits+0x208>
    80002130:	ffffe097          	auipc	ra,0xffffe
    80002134:	40e080e7          	jalr	1038(ra) # 8000053e <panic>

0000000080002138 <yield>:
{
    80002138:	1101                	addi	sp,sp,-32
    8000213a:	ec06                	sd	ra,24(sp)
    8000213c:	e822                	sd	s0,16(sp)
    8000213e:	e426                	sd	s1,8(sp)
    80002140:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002142:	00000097          	auipc	ra,0x0
    80002146:	88e080e7          	jalr	-1906(ra) # 800019d0 <myproc>
    8000214a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000214c:	fffff097          	auipc	ra,0xfffff
    80002150:	a98080e7          	jalr	-1384(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002154:	478d                	li	a5,3
    80002156:	cc9c                	sw	a5,24(s1)
  sched();
    80002158:	00000097          	auipc	ra,0x0
    8000215c:	f0a080e7          	jalr	-246(ra) # 80002062 <sched>
  release(&p->lock);
    80002160:	8526                	mv	a0,s1
    80002162:	fffff097          	auipc	ra,0xfffff
    80002166:	b36080e7          	jalr	-1226(ra) # 80000c98 <release>
}
    8000216a:	60e2                	ld	ra,24(sp)
    8000216c:	6442                	ld	s0,16(sp)
    8000216e:	64a2                	ld	s1,8(sp)
    80002170:	6105                	addi	sp,sp,32
    80002172:	8082                	ret

0000000080002174 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002174:	7179                	addi	sp,sp,-48
    80002176:	f406                	sd	ra,40(sp)
    80002178:	f022                	sd	s0,32(sp)
    8000217a:	ec26                	sd	s1,24(sp)
    8000217c:	e84a                	sd	s2,16(sp)
    8000217e:	e44e                	sd	s3,8(sp)
    80002180:	1800                	addi	s0,sp,48
    80002182:	89aa                	mv	s3,a0
    80002184:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002186:	00000097          	auipc	ra,0x0
    8000218a:	84a080e7          	jalr	-1974(ra) # 800019d0 <myproc>
    8000218e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); //DOC: sleeplock1
    80002190:	fffff097          	auipc	ra,0xfffff
    80002194:	a54080e7          	jalr	-1452(ra) # 80000be4 <acquire>
  release(lk);
    80002198:	854a                	mv	a0,s2
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	afe080e7          	jalr	-1282(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800021a2:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800021a6:	4789                	li	a5,2
    800021a8:	cc9c                	sw	a5,24(s1)

  sched();
    800021aa:	00000097          	auipc	ra,0x0
    800021ae:	eb8080e7          	jalr	-328(ra) # 80002062 <sched>

  // Tidy up.
  p->chan = 0;
    800021b2:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800021b6:	8526                	mv	a0,s1
    800021b8:	fffff097          	auipc	ra,0xfffff
    800021bc:	ae0080e7          	jalr	-1312(ra) # 80000c98 <release>
  acquire(lk);
    800021c0:	854a                	mv	a0,s2
    800021c2:	fffff097          	auipc	ra,0xfffff
    800021c6:	a22080e7          	jalr	-1502(ra) # 80000be4 <acquire>
}
    800021ca:	70a2                	ld	ra,40(sp)
    800021cc:	7402                	ld	s0,32(sp)
    800021ce:	64e2                	ld	s1,24(sp)
    800021d0:	6942                	ld	s2,16(sp)
    800021d2:	69a2                	ld	s3,8(sp)
    800021d4:	6145                	addi	sp,sp,48
    800021d6:	8082                	ret

00000000800021d8 <wait>:
{
    800021d8:	715d                	addi	sp,sp,-80
    800021da:	e486                	sd	ra,72(sp)
    800021dc:	e0a2                	sd	s0,64(sp)
    800021de:	fc26                	sd	s1,56(sp)
    800021e0:	f84a                	sd	s2,48(sp)
    800021e2:	f44e                	sd	s3,40(sp)
    800021e4:	f052                	sd	s4,32(sp)
    800021e6:	ec56                	sd	s5,24(sp)
    800021e8:	e85a                	sd	s6,16(sp)
    800021ea:	e45e                	sd	s7,8(sp)
    800021ec:	0880                	addi	s0,sp,80
    800021ee:	8baa                	mv	s7,a0
  struct proc *p = myproc();
    800021f0:	fffff097          	auipc	ra,0xfffff
    800021f4:	7e0080e7          	jalr	2016(ra) # 800019d0 <myproc>
    800021f8:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800021fa:	0000f517          	auipc	a0,0xf
    800021fe:	0be50513          	addi	a0,a0,190 # 800112b8 <wait_lock>
    80002202:	fffff097          	auipc	ra,0xfffff
    80002206:	9e2080e7          	jalr	-1566(ra) # 80000be4 <acquire>
        if (np->state == ZOMBIE)
    8000220a:	4a95                	li	s5,5
    for (np = proc; np < &proc[NPROC]; np++)
    8000220c:	698d                	lui	s3,0x3
    8000220e:	06898993          	addi	s3,s3,104 # 3068 <_entry-0x7fffcf98>
    80002212:	000d1a17          	auipc	s4,0xd1
    80002216:	ebea0a13          	addi	s4,s4,-322 # 800d30d0 <tickslock>
        havekids = 1;
    8000221a:	4b05                	li	s6,1
    havekids = 0;
    8000221c:	4701                	li	a4,0
    for (np = proc; np < &proc[NPROC]; np++)
    8000221e:	0000f497          	auipc	s1,0xf
    80002222:	4b248493          	addi	s1,s1,1202 # 800116d0 <proc>
    80002226:	a0b5                	j	80002292 <wait+0xba>
          pid = np->pid;
    80002228:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000222c:	000b8e63          	beqz	s7,80002248 <wait+0x70>
    80002230:	4691                	li	a3,4
    80002232:	02c48613          	addi	a2,s1,44
    80002236:	85de                	mv	a1,s7
    80002238:	05093503          	ld	a0,80(s2)
    8000223c:	fffff097          	auipc	ra,0xfffff
    80002240:	436080e7          	jalr	1078(ra) # 80001672 <copyout>
    80002244:	02054563          	bltz	a0,8000226e <wait+0x96>
          freeproc(np);
    80002248:	8526                	mv	a0,s1
    8000224a:	00000097          	auipc	ra,0x0
    8000224e:	938080e7          	jalr	-1736(ra) # 80001b82 <freeproc>
          release(&np->lock);
    80002252:	8526                	mv	a0,s1
    80002254:	fffff097          	auipc	ra,0xfffff
    80002258:	a44080e7          	jalr	-1468(ra) # 80000c98 <release>
          release(&wait_lock);
    8000225c:	0000f517          	auipc	a0,0xf
    80002260:	05c50513          	addi	a0,a0,92 # 800112b8 <wait_lock>
    80002264:	fffff097          	auipc	ra,0xfffff
    80002268:	a34080e7          	jalr	-1484(ra) # 80000c98 <release>
          return pid;
    8000226c:	a095                	j	800022d0 <wait+0xf8>
            release(&np->lock);
    8000226e:	8526                	mv	a0,s1
    80002270:	fffff097          	auipc	ra,0xfffff
    80002274:	a28080e7          	jalr	-1496(ra) # 80000c98 <release>
            release(&wait_lock);
    80002278:	0000f517          	auipc	a0,0xf
    8000227c:	04050513          	addi	a0,a0,64 # 800112b8 <wait_lock>
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	a18080e7          	jalr	-1512(ra) # 80000c98 <release>
            return -1;
    80002288:	59fd                	li	s3,-1
    8000228a:	a099                	j	800022d0 <wait+0xf8>
    for (np = proc; np < &proc[NPROC]; np++)
    8000228c:	94ce                	add	s1,s1,s3
    8000228e:	03448463          	beq	s1,s4,800022b6 <wait+0xde>
      if (np->parent == p)
    80002292:	7c9c                	ld	a5,56(s1)
    80002294:	ff279ce3          	bne	a5,s2,8000228c <wait+0xb4>
        acquire(&np->lock);
    80002298:	8526                	mv	a0,s1
    8000229a:	fffff097          	auipc	ra,0xfffff
    8000229e:	94a080e7          	jalr	-1718(ra) # 80000be4 <acquire>
        if (np->state == ZOMBIE)
    800022a2:	4c9c                	lw	a5,24(s1)
    800022a4:	f95782e3          	beq	a5,s5,80002228 <wait+0x50>
        release(&np->lock);
    800022a8:	8526                	mv	a0,s1
    800022aa:	fffff097          	auipc	ra,0xfffff
    800022ae:	9ee080e7          	jalr	-1554(ra) # 80000c98 <release>
        havekids = 1;
    800022b2:	875a                	mv	a4,s6
    800022b4:	bfe1                	j	8000228c <wait+0xb4>
    if (!havekids || p->killed)
    800022b6:	c701                	beqz	a4,800022be <wait+0xe6>
    800022b8:	02892783          	lw	a5,40(s2)
    800022bc:	c795                	beqz	a5,800022e8 <wait+0x110>
      release(&wait_lock);
    800022be:	0000f517          	auipc	a0,0xf
    800022c2:	ffa50513          	addi	a0,a0,-6 # 800112b8 <wait_lock>
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	9d2080e7          	jalr	-1582(ra) # 80000c98 <release>
      return -1;
    800022ce:	59fd                	li	s3,-1
}
    800022d0:	854e                	mv	a0,s3
    800022d2:	60a6                	ld	ra,72(sp)
    800022d4:	6406                	ld	s0,64(sp)
    800022d6:	74e2                	ld	s1,56(sp)
    800022d8:	7942                	ld	s2,48(sp)
    800022da:	79a2                	ld	s3,40(sp)
    800022dc:	7a02                	ld	s4,32(sp)
    800022de:	6ae2                	ld	s5,24(sp)
    800022e0:	6b42                	ld	s6,16(sp)
    800022e2:	6ba2                	ld	s7,8(sp)
    800022e4:	6161                	addi	sp,sp,80
    800022e6:	8082                	ret
    sleep(p, &wait_lock); //DOC: wait-sleep
    800022e8:	0000f597          	auipc	a1,0xf
    800022ec:	fd058593          	addi	a1,a1,-48 # 800112b8 <wait_lock>
    800022f0:	854a                	mv	a0,s2
    800022f2:	00000097          	auipc	ra,0x0
    800022f6:	e82080e7          	jalr	-382(ra) # 80002174 <sleep>
    havekids = 0;
    800022fa:	b70d                	j	8000221c <wait+0x44>

00000000800022fc <waitx>:
{
    800022fc:	711d                	addi	sp,sp,-96
    800022fe:	ec86                	sd	ra,88(sp)
    80002300:	e8a2                	sd	s0,80(sp)
    80002302:	e4a6                	sd	s1,72(sp)
    80002304:	e0ca                	sd	s2,64(sp)
    80002306:	fc4e                	sd	s3,56(sp)
    80002308:	f852                	sd	s4,48(sp)
    8000230a:	f456                	sd	s5,40(sp)
    8000230c:	f05a                	sd	s6,32(sp)
    8000230e:	ec5e                	sd	s7,24(sp)
    80002310:	e862                	sd	s8,16(sp)
    80002312:	e466                	sd	s9,8(sp)
    80002314:	1080                	addi	s0,sp,96
    80002316:	8baa                	mv	s7,a0
    80002318:	8cae                	mv	s9,a1
    8000231a:	8c32                	mv	s8,a2
  struct proc *p = myproc();
    8000231c:	fffff097          	auipc	ra,0xfffff
    80002320:	6b4080e7          	jalr	1716(ra) # 800019d0 <myproc>
    80002324:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002326:	0000f517          	auipc	a0,0xf
    8000232a:	f9250513          	addi	a0,a0,-110 # 800112b8 <wait_lock>
    8000232e:	fffff097          	auipc	ra,0xfffff
    80002332:	8b6080e7          	jalr	-1866(ra) # 80000be4 <acquire>
        if (np->state == ZOMBIE)
    80002336:	4a95                	li	s5,5
    for (np = proc; np < &proc[NPROC]; np++)
    80002338:	698d                	lui	s3,0x3
    8000233a:	06898993          	addi	s3,s3,104 # 3068 <_entry-0x7fffcf98>
    8000233e:	000d1a17          	auipc	s4,0xd1
    80002342:	d92a0a13          	addi	s4,s4,-622 # 800d30d0 <tickslock>
        havekids = 1;
    80002346:	4b05                	li	s6,1
    havekids = 0;
    80002348:	4701                	li	a4,0
    for (np = proc; np < &proc[NPROC]; np++)
    8000234a:	0000f497          	auipc	s1,0xf
    8000234e:	38648493          	addi	s1,s1,902 # 800116d0 <proc>
    80002352:	a051                	j	800023d6 <waitx+0xda>
          pid = np->pid;
    80002354:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002358:	1684a703          	lw	a4,360(s1)
    8000235c:	00eca023          	sw	a4,0(s9)
          *wtime = np->etime - np->ctime - np->rtime;
    80002360:	16c4a783          	lw	a5,364(s1)
    80002364:	9f3d                	addw	a4,a4,a5
    80002366:	1704a783          	lw	a5,368(s1)
    8000236a:	9f99                	subw	a5,a5,a4
    8000236c:	00fc2023          	sw	a5,0(s8)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002370:	000b8e63          	beqz	s7,8000238c <waitx+0x90>
    80002374:	4691                	li	a3,4
    80002376:	02c48613          	addi	a2,s1,44
    8000237a:	85de                	mv	a1,s7
    8000237c:	05093503          	ld	a0,80(s2)
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	2f2080e7          	jalr	754(ra) # 80001672 <copyout>
    80002388:	02054563          	bltz	a0,800023b2 <waitx+0xb6>
          freeproc(np);
    8000238c:	8526                	mv	a0,s1
    8000238e:	fffff097          	auipc	ra,0xfffff
    80002392:	7f4080e7          	jalr	2036(ra) # 80001b82 <freeproc>
          release(&np->lock);
    80002396:	8526                	mv	a0,s1
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	900080e7          	jalr	-1792(ra) # 80000c98 <release>
          release(&wait_lock);
    800023a0:	0000f517          	auipc	a0,0xf
    800023a4:	f1850513          	addi	a0,a0,-232 # 800112b8 <wait_lock>
    800023a8:	fffff097          	auipc	ra,0xfffff
    800023ac:	8f0080e7          	jalr	-1808(ra) # 80000c98 <release>
          return pid;
    800023b0:	a095                	j	80002414 <waitx+0x118>
            release(&np->lock);
    800023b2:	8526                	mv	a0,s1
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	8e4080e7          	jalr	-1820(ra) # 80000c98 <release>
            release(&wait_lock);
    800023bc:	0000f517          	auipc	a0,0xf
    800023c0:	efc50513          	addi	a0,a0,-260 # 800112b8 <wait_lock>
    800023c4:	fffff097          	auipc	ra,0xfffff
    800023c8:	8d4080e7          	jalr	-1836(ra) # 80000c98 <release>
            return -1;
    800023cc:	59fd                	li	s3,-1
    800023ce:	a099                	j	80002414 <waitx+0x118>
    for (np = proc; np < &proc[NPROC]; np++)
    800023d0:	94ce                	add	s1,s1,s3
    800023d2:	03448463          	beq	s1,s4,800023fa <waitx+0xfe>
      if (np->parent == p)
    800023d6:	7c9c                	ld	a5,56(s1)
    800023d8:	ff279ce3          	bne	a5,s2,800023d0 <waitx+0xd4>
        acquire(&np->lock);
    800023dc:	8526                	mv	a0,s1
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	806080e7          	jalr	-2042(ra) # 80000be4 <acquire>
        if (np->state == ZOMBIE)
    800023e6:	4c9c                	lw	a5,24(s1)
    800023e8:	f75786e3          	beq	a5,s5,80002354 <waitx+0x58>
        release(&np->lock);
    800023ec:	8526                	mv	a0,s1
    800023ee:	fffff097          	auipc	ra,0xfffff
    800023f2:	8aa080e7          	jalr	-1878(ra) # 80000c98 <release>
        havekids = 1;
    800023f6:	875a                	mv	a4,s6
    800023f8:	bfe1                	j	800023d0 <waitx+0xd4>
    if (!havekids || p->killed)
    800023fa:	c701                	beqz	a4,80002402 <waitx+0x106>
    800023fc:	02892783          	lw	a5,40(s2)
    80002400:	cb85                	beqz	a5,80002430 <waitx+0x134>
      release(&wait_lock);
    80002402:	0000f517          	auipc	a0,0xf
    80002406:	eb650513          	addi	a0,a0,-330 # 800112b8 <wait_lock>
    8000240a:	fffff097          	auipc	ra,0xfffff
    8000240e:	88e080e7          	jalr	-1906(ra) # 80000c98 <release>
      return -1;
    80002412:	59fd                	li	s3,-1
}
    80002414:	854e                	mv	a0,s3
    80002416:	60e6                	ld	ra,88(sp)
    80002418:	6446                	ld	s0,80(sp)
    8000241a:	64a6                	ld	s1,72(sp)
    8000241c:	6906                	ld	s2,64(sp)
    8000241e:	79e2                	ld	s3,56(sp)
    80002420:	7a42                	ld	s4,48(sp)
    80002422:	7aa2                	ld	s5,40(sp)
    80002424:	7b02                	ld	s6,32(sp)
    80002426:	6be2                	ld	s7,24(sp)
    80002428:	6c42                	ld	s8,16(sp)
    8000242a:	6ca2                	ld	s9,8(sp)
    8000242c:	6125                	addi	sp,sp,96
    8000242e:	8082                	ret
    sleep(p, &wait_lock); //DOC: wait-sleep
    80002430:	0000f597          	auipc	a1,0xf
    80002434:	e8858593          	addi	a1,a1,-376 # 800112b8 <wait_lock>
    80002438:	854a                	mv	a0,s2
    8000243a:	00000097          	auipc	ra,0x0
    8000243e:	d3a080e7          	jalr	-710(ra) # 80002174 <sleep>
    havekids = 0;
    80002442:	b719                	j	80002348 <waitx+0x4c>

0000000080002444 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002444:	7139                	addi	sp,sp,-64
    80002446:	fc06                	sd	ra,56(sp)
    80002448:	f822                	sd	s0,48(sp)
    8000244a:	f426                	sd	s1,40(sp)
    8000244c:	f04a                	sd	s2,32(sp)
    8000244e:	ec4e                	sd	s3,24(sp)
    80002450:	e852                	sd	s4,16(sp)
    80002452:	e456                	sd	s5,8(sp)
    80002454:	e05a                	sd	s6,0(sp)
    80002456:	0080                	addi	s0,sp,64
    80002458:	8aaa                	mv	s5,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000245a:	0000f497          	auipc	s1,0xf
    8000245e:	27648493          	addi	s1,s1,630 # 800116d0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002462:	4a09                	li	s4,2
      {
        p->state = RUNNABLE;
    80002464:	4b0d                	li	s6,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002466:	690d                	lui	s2,0x3
    80002468:	06890913          	addi	s2,s2,104 # 3068 <_entry-0x7fffcf98>
    8000246c:	000d1997          	auipc	s3,0xd1
    80002470:	c6498993          	addi	s3,s3,-924 # 800d30d0 <tickslock>
    80002474:	a819                	j	8000248a <wakeup+0x46>
        p->state = RUNNABLE;
    80002476:	0164ac23          	sw	s6,24(s1)
      }
      release(&p->lock);
    8000247a:	8526                	mv	a0,s1
    8000247c:	fffff097          	auipc	ra,0xfffff
    80002480:	81c080e7          	jalr	-2020(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002484:	94ca                	add	s1,s1,s2
    80002486:	03348463          	beq	s1,s3,800024ae <wakeup+0x6a>
    if (p != myproc())
    8000248a:	fffff097          	auipc	ra,0xfffff
    8000248e:	546080e7          	jalr	1350(ra) # 800019d0 <myproc>
    80002492:	fea489e3          	beq	s1,a0,80002484 <wakeup+0x40>
      acquire(&p->lock);
    80002496:	8526                	mv	a0,s1
    80002498:	ffffe097          	auipc	ra,0xffffe
    8000249c:	74c080e7          	jalr	1868(ra) # 80000be4 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800024a0:	4c9c                	lw	a5,24(s1)
    800024a2:	fd479ce3          	bne	a5,s4,8000247a <wakeup+0x36>
    800024a6:	709c                	ld	a5,32(s1)
    800024a8:	fd5799e3          	bne	a5,s5,8000247a <wakeup+0x36>
    800024ac:	b7e9                	j	80002476 <wakeup+0x32>
    }
  }
}
    800024ae:	70e2                	ld	ra,56(sp)
    800024b0:	7442                	ld	s0,48(sp)
    800024b2:	74a2                	ld	s1,40(sp)
    800024b4:	7902                	ld	s2,32(sp)
    800024b6:	69e2                	ld	s3,24(sp)
    800024b8:	6a42                	ld	s4,16(sp)
    800024ba:	6aa2                	ld	s5,8(sp)
    800024bc:	6b02                	ld	s6,0(sp)
    800024be:	6121                	addi	sp,sp,64
    800024c0:	8082                	ret

00000000800024c2 <reparent>:
{
    800024c2:	7139                	addi	sp,sp,-64
    800024c4:	fc06                	sd	ra,56(sp)
    800024c6:	f822                	sd	s0,48(sp)
    800024c8:	f426                	sd	s1,40(sp)
    800024ca:	f04a                	sd	s2,32(sp)
    800024cc:	ec4e                	sd	s3,24(sp)
    800024ce:	e852                	sd	s4,16(sp)
    800024d0:	e456                	sd	s5,8(sp)
    800024d2:	0080                	addi	s0,sp,64
    800024d4:	89aa                	mv	s3,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800024d6:	0000f497          	auipc	s1,0xf
    800024da:	1fa48493          	addi	s1,s1,506 # 800116d0 <proc>
      pp->parent = initproc;
    800024de:	00007a97          	auipc	s5,0x7
    800024e2:	b52a8a93          	addi	s5,s5,-1198 # 80009030 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800024e6:	690d                	lui	s2,0x3
    800024e8:	06890913          	addi	s2,s2,104 # 3068 <_entry-0x7fffcf98>
    800024ec:	000d1a17          	auipc	s4,0xd1
    800024f0:	be4a0a13          	addi	s4,s4,-1052 # 800d30d0 <tickslock>
    800024f4:	a021                	j	800024fc <reparent+0x3a>
    800024f6:	94ca                	add	s1,s1,s2
    800024f8:	01448d63          	beq	s1,s4,80002512 <reparent+0x50>
    if (pp->parent == p)
    800024fc:	7c9c                	ld	a5,56(s1)
    800024fe:	ff379ce3          	bne	a5,s3,800024f6 <reparent+0x34>
      pp->parent = initproc;
    80002502:	000ab503          	ld	a0,0(s5)
    80002506:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002508:	00000097          	auipc	ra,0x0
    8000250c:	f3c080e7          	jalr	-196(ra) # 80002444 <wakeup>
    80002510:	b7dd                	j	800024f6 <reparent+0x34>
}
    80002512:	70e2                	ld	ra,56(sp)
    80002514:	7442                	ld	s0,48(sp)
    80002516:	74a2                	ld	s1,40(sp)
    80002518:	7902                	ld	s2,32(sp)
    8000251a:	69e2                	ld	s3,24(sp)
    8000251c:	6a42                	ld	s4,16(sp)
    8000251e:	6aa2                	ld	s5,8(sp)
    80002520:	6121                	addi	sp,sp,64
    80002522:	8082                	ret

0000000080002524 <exit>:
{
    80002524:	7155                	addi	sp,sp,-208
    80002526:	e586                	sd	ra,200(sp)
    80002528:	e1a2                	sd	s0,192(sp)
    8000252a:	fd26                	sd	s1,184(sp)
    8000252c:	f94a                	sd	s2,176(sp)
    8000252e:	f54e                	sd	s3,168(sp)
    80002530:	f152                	sd	s4,160(sp)
    80002532:	ed56                	sd	s5,152(sp)
    80002534:	e95a                	sd	s6,144(sp)
    80002536:	e55e                	sd	s7,136(sp)
    80002538:	e162                	sd	s8,128(sp)
    8000253a:	fce6                	sd	s9,120(sp)
    8000253c:	f8ea                	sd	s10,112(sp)
    8000253e:	f4ee                	sd	s11,104(sp)
    80002540:	0980                	addi	s0,sp,208
    80002542:	f2a43c23          	sd	a0,-200(s0)
  struct proc *p = myproc();
    80002546:	fffff097          	auipc	ra,0xfffff
    8000254a:	48a080e7          	jalr	1162(ra) # 800019d0 <myproc>
    8000254e:	8b2a                	mv	s6,a0
  char string[50] = "";
    80002550:	f4043c23          	sd	zero,-168(s0)
    80002554:	f6043023          	sd	zero,-160(s0)
    80002558:	f6043423          	sd	zero,-152(s0)
    8000255c:	f6043823          	sd	zero,-144(s0)
    80002560:	f6043c23          	sd	zero,-136(s0)
    80002564:	f8043023          	sd	zero,-128(s0)
    80002568:	f8041423          	sh	zero,-120(s0)
  if (p->is_trace == 1)
    8000256c:	678d                	lui	a5,0x3
    8000256e:	97aa                	add	a5,a5,a0
    80002570:	4ff8                	lw	a4,92(a5)
    80002572:	4785                	li	a5,1
    80002574:	02f70463          	beq	a4,a5,8000259c <exit+0x78>
  if (p == initproc)
    80002578:	00007797          	auipc	a5,0x7
    8000257c:	ab87b783          	ld	a5,-1352(a5) # 80009030 <initproc>
    80002580:	0d0b0493          	addi	s1,s6,208
    80002584:	150b0913          	addi	s2,s6,336
    80002588:	13679663          	bne	a5,s6,800026b4 <exit+0x190>
    panic("init exiting");
    8000258c:	00006517          	auipc	a0,0x6
    80002590:	d0c50513          	addi	a0,a0,-756 # 80008298 <digits+0x258>
    80002594:	ffffe097          	auipc	ra,0xffffe
    80002598:	faa080e7          	jalr	-86(ra) # 8000053e <panic>
    for (int i = 0; i < p->syscall_index; i++)
    8000259c:	678d                	lui	a5,0x3
    8000259e:	97aa                	add	a5,a5,a0
    800025a0:	4bfc                	lw	a5,84(a5)
    800025a2:	fcf05be3          	blez	a5,80002578 <exit+0x54>
    800025a6:	17450c13          	addi	s8,a0,372
    800025aa:	6d09                	lui	s10,0x2
    800025ac:	0b4d0d13          	addi	s10,s10,180 # 20b4 <_entry-0x7fffdf4c>
    800025b0:	9d2a                	add	s10,s10,a0
    800025b2:	4d81                	li	s11,0
        printf("%d", p->syscall_args[i][n]);
    800025b4:	00006a97          	auipc	s5,0x6
    800025b8:	cc4a8a93          	addi	s5,s5,-828 # 80008278 <digits+0x238>
          printf(" ");
    800025bc:	00006b97          	auipc	s7,0x6
    800025c0:	cc4b8b93          	addi	s7,s7,-828 # 80008280 <digits+0x240>
      printf(" -> %d", p->syscall_returns[i]);
    800025c4:	6785                	lui	a5,0x1
    800025c6:	fa078793          	addi	a5,a5,-96 # fa0 <_entry-0x7ffff060>
    800025ca:	f4f43423          	sd	a5,-184(s0)
    for (int i = 0; i < p->syscall_index; i++)
    800025ce:	678d                	lui	a5,0x3
    800025d0:	97aa                	add	a5,a5,a0
    800025d2:	f4f43023          	sd	a5,-192(s0)
    800025d6:	a895                	j	8000264a <exit+0x126>
      for (int n = 0; n < j; n++)
    800025d8:	2485                	addiw	s1,s1,1
    800025da:	0911                	addi	s2,s2,4
    800025dc:	02998163          	beq	s3,s1,800025fe <exit+0xda>
        printf("%d", p->syscall_args[i][n]);
    800025e0:	00092583          	lw	a1,0(s2)
    800025e4:	8556                	mv	a0,s5
    800025e6:	ffffe097          	auipc	ra,0xffffe
    800025ea:	fa2080e7          	jalr	-94(ra) # 80000588 <printf>
        if (n != j - 1)
    800025ee:	fe9a05e3          	beq	s4,s1,800025d8 <exit+0xb4>
          printf(" ");
    800025f2:	855e                	mv	a0,s7
    800025f4:	ffffe097          	auipc	ra,0xffffe
    800025f8:	f94080e7          	jalr	-108(ra) # 80000588 <printf>
    800025fc:	bff1                	j	800025d8 <exit+0xb4>
      printf(")");
    800025fe:	00006517          	auipc	a0,0x6
    80002602:	c8a50513          	addi	a0,a0,-886 # 80008288 <digits+0x248>
    80002606:	ffffe097          	auipc	ra,0xffffe
    8000260a:	f82080e7          	jalr	-126(ra) # 80000588 <printf>
      printf(" -> %d", p->syscall_returns[i]);
    8000260e:	f4843783          	ld	a5,-184(s0)
    80002612:	9cbe                	add	s9,s9,a5
    80002614:	000ca583          	lw	a1,0(s9)
    80002618:	00006517          	auipc	a0,0x6
    8000261c:	c7850513          	addi	a0,a0,-904 # 80008290 <digits+0x250>
    80002620:	ffffe097          	auipc	ra,0xffffe
    80002624:	f68080e7          	jalr	-152(ra) # 80000588 <printf>
      printf("\n");
    80002628:	00006517          	auipc	a0,0x6
    8000262c:	aa050513          	addi	a0,a0,-1376 # 800080c8 <digits+0x88>
    80002630:	ffffe097          	auipc	ra,0xffffe
    80002634:	f58080e7          	jalr	-168(ra) # 80000588 <printf>
    for (int i = 0; i < p->syscall_index; i++)
    80002638:	2d85                	addiw	s11,s11,1
    8000263a:	0c11                	addi	s8,s8,4
    8000263c:	028d0d13          	addi	s10,s10,40
    80002640:	f4043783          	ld	a5,-192(s0)
    80002644:	4bfc                	lw	a5,84(a5)
    80002646:	f2fdd9e3          	bge	s11,a5,80002578 <exit+0x54>
      printf("%d: syscall %s", p->pid, num_to_name(p->syscall_ids[i], string));
    8000264a:	030b2483          	lw	s1,48(s6)
    8000264e:	8ce2                	mv	s9,s8
    80002650:	f5840593          	addi	a1,s0,-168
    80002654:	000c2503          	lw	a0,0(s8)
    80002658:	00001097          	auipc	ra,0x1
    8000265c:	878080e7          	jalr	-1928(ra) # 80002ed0 <num_to_name>
    80002660:	862a                	mv	a2,a0
    80002662:	85a6                	mv	a1,s1
    80002664:	00006517          	auipc	a0,0x6
    80002668:	bfc50513          	addi	a0,a0,-1028 # 80008260 <digits+0x220>
    8000266c:	ffffe097          	auipc	ra,0xffffe
    80002670:	f1c080e7          	jalr	-228(ra) # 80000588 <printf>
      printf("(");
    80002674:	00006517          	auipc	a0,0x6
    80002678:	bfc50513          	addi	a0,a0,-1028 # 80008270 <digits+0x230>
    8000267c:	ffffe097          	auipc	ra,0xffffe
    80002680:	f0c080e7          	jalr	-244(ra) # 80000588 <printf>
      j = num_arg(p->syscall_ids[i], j);
    80002684:	4581                	li	a1,0
    80002686:	000c2503          	lw	a0,0(s8)
    8000268a:	00001097          	auipc	ra,0x1
    8000268e:	a40080e7          	jalr	-1472(ra) # 800030ca <num_arg>
    80002692:	89aa                	mv	s3,a0
      for (int n = 0; n < j; n++)
    80002694:	f6a055e3          	blez	a0,800025fe <exit+0xda>
    80002698:	896a                	mv	s2,s10
    8000269a:	4481                	li	s1,0
        if (n != j - 1)
    8000269c:	fff50a1b          	addiw	s4,a0,-1
    800026a0:	b781                	j	800025e0 <exit+0xbc>
      fileclose(f);
    800026a2:	00002097          	auipc	ra,0x2
    800026a6:	604080e7          	jalr	1540(ra) # 80004ca6 <fileclose>
      p->ofile[fd] = 0;
    800026aa:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800026ae:	04a1                	addi	s1,s1,8
    800026b0:	01248563          	beq	s1,s2,800026ba <exit+0x196>
    if (p->ofile[fd])
    800026b4:	6088                	ld	a0,0(s1)
    800026b6:	f575                	bnez	a0,800026a2 <exit+0x17e>
    800026b8:	bfdd                	j	800026ae <exit+0x18a>
  begin_op();
    800026ba:	00002097          	auipc	ra,0x2
    800026be:	120080e7          	jalr	288(ra) # 800047da <begin_op>
  iput(p->cwd);
    800026c2:	150b3503          	ld	a0,336(s6)
    800026c6:	00002097          	auipc	ra,0x2
    800026ca:	8fc080e7          	jalr	-1796(ra) # 80003fc2 <iput>
  end_op();
    800026ce:	00002097          	auipc	ra,0x2
    800026d2:	18c080e7          	jalr	396(ra) # 8000485a <end_op>
  p->cwd = 0;
    800026d6:	140b3823          	sd	zero,336(s6)
  acquire(&wait_lock);
    800026da:	0000f497          	auipc	s1,0xf
    800026de:	bde48493          	addi	s1,s1,-1058 # 800112b8 <wait_lock>
    800026e2:	8526                	mv	a0,s1
    800026e4:	ffffe097          	auipc	ra,0xffffe
    800026e8:	500080e7          	jalr	1280(ra) # 80000be4 <acquire>
  reparent(p);
    800026ec:	855a                	mv	a0,s6
    800026ee:	00000097          	auipc	ra,0x0
    800026f2:	dd4080e7          	jalr	-556(ra) # 800024c2 <reparent>
  wakeup(p->parent);
    800026f6:	038b3503          	ld	a0,56(s6)
    800026fa:	00000097          	auipc	ra,0x0
    800026fe:	d4a080e7          	jalr	-694(ra) # 80002444 <wakeup>
  acquire(&p->lock);
    80002702:	855a                	mv	a0,s6
    80002704:	ffffe097          	auipc	ra,0xffffe
    80002708:	4e0080e7          	jalr	1248(ra) # 80000be4 <acquire>
  p->xstate = status;
    8000270c:	f3843783          	ld	a5,-200(s0)
    80002710:	02fb2623          	sw	a5,44(s6)
  p->state = ZOMBIE;
    80002714:	4795                	li	a5,5
    80002716:	00fb2c23          	sw	a5,24(s6)
  p->etime = ticks;
    8000271a:	00007797          	auipc	a5,0x7
    8000271e:	91e7a783          	lw	a5,-1762(a5) # 80009038 <ticks>
    80002722:	16fb2823          	sw	a5,368(s6)
  release(&wait_lock);
    80002726:	8526                	mv	a0,s1
    80002728:	ffffe097          	auipc	ra,0xffffe
    8000272c:	570080e7          	jalr	1392(ra) # 80000c98 <release>
  sched();
    80002730:	00000097          	auipc	ra,0x0
    80002734:	932080e7          	jalr	-1742(ra) # 80002062 <sched>
  panic("zombie exit");
    80002738:	00006517          	auipc	a0,0x6
    8000273c:	b7050513          	addi	a0,a0,-1168 # 800082a8 <digits+0x268>
    80002740:	ffffe097          	auipc	ra,0xffffe
    80002744:	dfe080e7          	jalr	-514(ra) # 8000053e <panic>

0000000080002748 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002748:	7179                	addi	sp,sp,-48
    8000274a:	f406                	sd	ra,40(sp)
    8000274c:	f022                	sd	s0,32(sp)
    8000274e:	ec26                	sd	s1,24(sp)
    80002750:	e84a                	sd	s2,16(sp)
    80002752:	e44e                	sd	s3,8(sp)
    80002754:	e052                	sd	s4,0(sp)
    80002756:	1800                	addi	s0,sp,48
    80002758:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000275a:	0000f497          	auipc	s1,0xf
    8000275e:	f7648493          	addi	s1,s1,-138 # 800116d0 <proc>
    80002762:	698d                	lui	s3,0x3
    80002764:	06898993          	addi	s3,s3,104 # 3068 <_entry-0x7fffcf98>
    80002768:	000d1a17          	auipc	s4,0xd1
    8000276c:	968a0a13          	addi	s4,s4,-1688 # 800d30d0 <tickslock>
  {
    acquire(&p->lock);
    80002770:	8526                	mv	a0,s1
    80002772:	ffffe097          	auipc	ra,0xffffe
    80002776:	472080e7          	jalr	1138(ra) # 80000be4 <acquire>
    if (p->pid == pid)
    8000277a:	589c                	lw	a5,48(s1)
    8000277c:	01278c63          	beq	a5,s2,80002794 <kill+0x4c>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002780:	8526                	mv	a0,s1
    80002782:	ffffe097          	auipc	ra,0xffffe
    80002786:	516080e7          	jalr	1302(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000278a:	94ce                	add	s1,s1,s3
    8000278c:	ff4492e3          	bne	s1,s4,80002770 <kill+0x28>
  }
  return -1;
    80002790:	557d                	li	a0,-1
    80002792:	a829                	j	800027ac <kill+0x64>
      p->killed = 1;
    80002794:	4785                	li	a5,1
    80002796:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002798:	4c98                	lw	a4,24(s1)
    8000279a:	4789                	li	a5,2
    8000279c:	02f70063          	beq	a4,a5,800027bc <kill+0x74>
      release(&p->lock);
    800027a0:	8526                	mv	a0,s1
    800027a2:	ffffe097          	auipc	ra,0xffffe
    800027a6:	4f6080e7          	jalr	1270(ra) # 80000c98 <release>
      return 0;
    800027aa:	4501                	li	a0,0
}
    800027ac:	70a2                	ld	ra,40(sp)
    800027ae:	7402                	ld	s0,32(sp)
    800027b0:	64e2                	ld	s1,24(sp)
    800027b2:	6942                	ld	s2,16(sp)
    800027b4:	69a2                	ld	s3,8(sp)
    800027b6:	6a02                	ld	s4,0(sp)
    800027b8:	6145                	addi	sp,sp,48
    800027ba:	8082                	ret
        p->state = RUNNABLE;
    800027bc:	478d                	li	a5,3
    800027be:	cc9c                	sw	a5,24(s1)
    800027c0:	b7c5                	j	800027a0 <kill+0x58>

00000000800027c2 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027c2:	7179                	addi	sp,sp,-48
    800027c4:	f406                	sd	ra,40(sp)
    800027c6:	f022                	sd	s0,32(sp)
    800027c8:	ec26                	sd	s1,24(sp)
    800027ca:	e84a                	sd	s2,16(sp)
    800027cc:	e44e                	sd	s3,8(sp)
    800027ce:	e052                	sd	s4,0(sp)
    800027d0:	1800                	addi	s0,sp,48
    800027d2:	84aa                	mv	s1,a0
    800027d4:	892e                	mv	s2,a1
    800027d6:	89b2                	mv	s3,a2
    800027d8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027da:	fffff097          	auipc	ra,0xfffff
    800027de:	1f6080e7          	jalr	502(ra) # 800019d0 <myproc>
  if (user_dst)
    800027e2:	c08d                	beqz	s1,80002804 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800027e4:	86d2                	mv	a3,s4
    800027e6:	864e                	mv	a2,s3
    800027e8:	85ca                	mv	a1,s2
    800027ea:	6928                	ld	a0,80(a0)
    800027ec:	fffff097          	auipc	ra,0xfffff
    800027f0:	e86080e7          	jalr	-378(ra) # 80001672 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027f4:	70a2                	ld	ra,40(sp)
    800027f6:	7402                	ld	s0,32(sp)
    800027f8:	64e2                	ld	s1,24(sp)
    800027fa:	6942                	ld	s2,16(sp)
    800027fc:	69a2                	ld	s3,8(sp)
    800027fe:	6a02                	ld	s4,0(sp)
    80002800:	6145                	addi	sp,sp,48
    80002802:	8082                	ret
    memmove((char *)dst, src, len);
    80002804:	000a061b          	sext.w	a2,s4
    80002808:	85ce                	mv	a1,s3
    8000280a:	854a                	mv	a0,s2
    8000280c:	ffffe097          	auipc	ra,0xffffe
    80002810:	534080e7          	jalr	1332(ra) # 80000d40 <memmove>
    return 0;
    80002814:	8526                	mv	a0,s1
    80002816:	bff9                	j	800027f4 <either_copyout+0x32>

0000000080002818 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002818:	7179                	addi	sp,sp,-48
    8000281a:	f406                	sd	ra,40(sp)
    8000281c:	f022                	sd	s0,32(sp)
    8000281e:	ec26                	sd	s1,24(sp)
    80002820:	e84a                	sd	s2,16(sp)
    80002822:	e44e                	sd	s3,8(sp)
    80002824:	e052                	sd	s4,0(sp)
    80002826:	1800                	addi	s0,sp,48
    80002828:	892a                	mv	s2,a0
    8000282a:	84ae                	mv	s1,a1
    8000282c:	89b2                	mv	s3,a2
    8000282e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002830:	fffff097          	auipc	ra,0xfffff
    80002834:	1a0080e7          	jalr	416(ra) # 800019d0 <myproc>
  if (user_src)
    80002838:	c08d                	beqz	s1,8000285a <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    8000283a:	86d2                	mv	a3,s4
    8000283c:	864e                	mv	a2,s3
    8000283e:	85ca                	mv	a1,s2
    80002840:	6928                	ld	a0,80(a0)
    80002842:	fffff097          	auipc	ra,0xfffff
    80002846:	ebc080e7          	jalr	-324(ra) # 800016fe <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    8000284a:	70a2                	ld	ra,40(sp)
    8000284c:	7402                	ld	s0,32(sp)
    8000284e:	64e2                	ld	s1,24(sp)
    80002850:	6942                	ld	s2,16(sp)
    80002852:	69a2                	ld	s3,8(sp)
    80002854:	6a02                	ld	s4,0(sp)
    80002856:	6145                	addi	sp,sp,48
    80002858:	8082                	ret
    memmove(dst, (char *)src, len);
    8000285a:	000a061b          	sext.w	a2,s4
    8000285e:	85ce                	mv	a1,s3
    80002860:	854a                	mv	a0,s2
    80002862:	ffffe097          	auipc	ra,0xffffe
    80002866:	4de080e7          	jalr	1246(ra) # 80000d40 <memmove>
    return 0;
    8000286a:	8526                	mv	a0,s1
    8000286c:	bff9                	j	8000284a <either_copyin+0x32>

000000008000286e <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000286e:	711d                	addi	sp,sp,-96
    80002870:	ec86                	sd	ra,88(sp)
    80002872:	e8a2                	sd	s0,80(sp)
    80002874:	e4a6                	sd	s1,72(sp)
    80002876:	e0ca                	sd	s2,64(sp)
    80002878:	fc4e                	sd	s3,56(sp)
    8000287a:	f852                	sd	s4,48(sp)
    8000287c:	f456                	sd	s5,40(sp)
    8000287e:	f05a                	sd	s6,32(sp)
    80002880:	ec5e                	sd	s7,24(sp)
    80002882:	e862                	sd	s8,16(sp)
    80002884:	e466                	sd	s9,8(sp)
    80002886:	1080                	addi	s0,sp,96
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002888:	00006517          	auipc	a0,0x6
    8000288c:	84050513          	addi	a0,a0,-1984 # 800080c8 <digits+0x88>
    80002890:	ffffe097          	auipc	ra,0xffffe
    80002894:	cf8080e7          	jalr	-776(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002898:	0000f497          	auipc	s1,0xf
    8000289c:	f9048493          	addi	s1,s1,-112 # 80011828 <proc+0x158>
    800028a0:	000d1997          	auipc	s3,0xd1
    800028a4:	98898993          	addi	s3,s3,-1656 # 800d3228 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028a8:	4c15                	li	s8,5
      state = states[p->state];
    else
      state = "???";
    800028aa:	00006a17          	auipc	s4,0x6
    800028ae:	a0ea0a13          	addi	s4,s4,-1522 # 800082b8 <digits+0x278>
    printf("%d %s %s %d %d %d", p->pid, state, p->name, p->rtime, p->etime-p->ctime-p->rtime,p->nrun);
    800028b2:	690d                	lui	s2,0x3
    800028b4:	f0890b93          	addi	s7,s2,-248 # 2f08 <_entry-0x7fffd0f8>
    800028b8:	00006b17          	auipc	s6,0x6
    800028bc:	a08b0b13          	addi	s6,s6,-1528 # 800082c0 <digits+0x280>
    printf("\n");
    800028c0:	00006a97          	auipc	s5,0x6
    800028c4:	808a8a93          	addi	s5,s5,-2040 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028c8:	00006c97          	auipc	s9,0x6
    800028cc:	a38c8c93          	addi	s9,s9,-1480 # 80008300 <states.1769>
    800028d0:	06890913          	addi	s2,s2,104
    800028d4:	a815                	j	80002908 <procdump+0x9a>
    printf("%d %s %s %d %d %d", p->pid, state, p->name, p->rtime, p->etime-p->ctime-p->rtime,p->nrun);
    800028d6:	4a98                	lw	a4,16(a3)
    800028d8:	01768533          	add	a0,a3,s7
    800028dc:	4adc                	lw	a5,20(a3)
    800028de:	9fb9                	addw	a5,a5,a4
    800028e0:	4e8c                	lw	a1,24(a3)
    800028e2:	00052803          	lw	a6,0(a0)
    800028e6:	40f587bb          	subw	a5,a1,a5
    800028ea:	ed86a583          	lw	a1,-296(a3)
    800028ee:	855a                	mv	a0,s6
    800028f0:	ffffe097          	auipc	ra,0xffffe
    800028f4:	c98080e7          	jalr	-872(ra) # 80000588 <printf>
    printf("\n");
    800028f8:	8556                	mv	a0,s5
    800028fa:	ffffe097          	auipc	ra,0xffffe
    800028fe:	c8e080e7          	jalr	-882(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002902:	94ca                	add	s1,s1,s2
    80002904:	03348163          	beq	s1,s3,80002926 <procdump+0xb8>
    if (p->state == UNUSED)
    80002908:	86a6                	mv	a3,s1
    8000290a:	ec04a783          	lw	a5,-320(s1)
    8000290e:	dbf5                	beqz	a5,80002902 <procdump+0x94>
      state = "???";
    80002910:	8652                	mv	a2,s4
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002912:	fcfc62e3          	bltu	s8,a5,800028d6 <procdump+0x68>
    80002916:	1782                	slli	a5,a5,0x20
    80002918:	9381                	srli	a5,a5,0x20
    8000291a:	078e                	slli	a5,a5,0x3
    8000291c:	97e6                	add	a5,a5,s9
    8000291e:	6390                	ld	a2,0(a5)
    80002920:	fa5d                	bnez	a2,800028d6 <procdump+0x68>
      state = "???";
    80002922:	8652                	mv	a2,s4
    80002924:	bf4d                	j	800028d6 <procdump+0x68>
  }
}
    80002926:	60e6                	ld	ra,88(sp)
    80002928:	6446                	ld	s0,80(sp)
    8000292a:	64a6                	ld	s1,72(sp)
    8000292c:	6906                	ld	s2,64(sp)
    8000292e:	79e2                	ld	s3,56(sp)
    80002930:	7a42                	ld	s4,48(sp)
    80002932:	7aa2                	ld	s5,40(sp)
    80002934:	7b02                	ld	s6,32(sp)
    80002936:	6be2                	ld	s7,24(sp)
    80002938:	6c42                	ld	s8,16(sp)
    8000293a:	6ca2                	ld	s9,8(sp)
    8000293c:	6125                	addi	sp,sp,96
    8000293e:	8082                	ret

0000000080002940 <swtch>:
    80002940:	00153023          	sd	ra,0(a0)
    80002944:	00253423          	sd	sp,8(a0)
    80002948:	e900                	sd	s0,16(a0)
    8000294a:	ed04                	sd	s1,24(a0)
    8000294c:	03253023          	sd	s2,32(a0)
    80002950:	03353423          	sd	s3,40(a0)
    80002954:	03453823          	sd	s4,48(a0)
    80002958:	03553c23          	sd	s5,56(a0)
    8000295c:	05653023          	sd	s6,64(a0)
    80002960:	05753423          	sd	s7,72(a0)
    80002964:	05853823          	sd	s8,80(a0)
    80002968:	05953c23          	sd	s9,88(a0)
    8000296c:	07a53023          	sd	s10,96(a0)
    80002970:	07b53423          	sd	s11,104(a0)
    80002974:	0005b083          	ld	ra,0(a1)
    80002978:	0085b103          	ld	sp,8(a1)
    8000297c:	6980                	ld	s0,16(a1)
    8000297e:	6d84                	ld	s1,24(a1)
    80002980:	0205b903          	ld	s2,32(a1)
    80002984:	0285b983          	ld	s3,40(a1)
    80002988:	0305ba03          	ld	s4,48(a1)
    8000298c:	0385ba83          	ld	s5,56(a1)
    80002990:	0405bb03          	ld	s6,64(a1)
    80002994:	0485bb83          	ld	s7,72(a1)
    80002998:	0505bc03          	ld	s8,80(a1)
    8000299c:	0585bc83          	ld	s9,88(a1)
    800029a0:	0605bd03          	ld	s10,96(a1)
    800029a4:	0685bd83          	ld	s11,104(a1)
    800029a8:	8082                	ret

00000000800029aa <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800029aa:	1141                	addi	sp,sp,-16
    800029ac:	e406                	sd	ra,8(sp)
    800029ae:	e022                	sd	s0,0(sp)
    800029b0:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800029b2:	00006597          	auipc	a1,0x6
    800029b6:	97e58593          	addi	a1,a1,-1666 # 80008330 <states.1769+0x30>
    800029ba:	000d0517          	auipc	a0,0xd0
    800029be:	71650513          	addi	a0,a0,1814 # 800d30d0 <tickslock>
    800029c2:	ffffe097          	auipc	ra,0xffffe
    800029c6:	192080e7          	jalr	402(ra) # 80000b54 <initlock>
}
    800029ca:	60a2                	ld	ra,8(sp)
    800029cc:	6402                	ld	s0,0(sp)
    800029ce:	0141                	addi	sp,sp,16
    800029d0:	8082                	ret

00000000800029d2 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800029d2:	1141                	addi	sp,sp,-16
    800029d4:	e422                	sd	s0,8(sp)
    800029d6:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029d8:	00004797          	auipc	a5,0x4
    800029dc:	8e878793          	addi	a5,a5,-1816 # 800062c0 <kernelvec>
    800029e0:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800029e4:	6422                	ld	s0,8(sp)
    800029e6:	0141                	addi	sp,sp,16
    800029e8:	8082                	ret

00000000800029ea <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800029ea:	1141                	addi	sp,sp,-16
    800029ec:	e406                	sd	ra,8(sp)
    800029ee:	e022                	sd	s0,0(sp)
    800029f0:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029f2:	fffff097          	auipc	ra,0xfffff
    800029f6:	fde080e7          	jalr	-34(ra) # 800019d0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029fa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029fe:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a00:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002a04:	00004617          	auipc	a2,0x4
    80002a08:	5fc60613          	addi	a2,a2,1532 # 80007000 <_trampoline>
    80002a0c:	00004697          	auipc	a3,0x4
    80002a10:	5f468693          	addi	a3,a3,1524 # 80007000 <_trampoline>
    80002a14:	8e91                	sub	a3,a3,a2
    80002a16:	040007b7          	lui	a5,0x4000
    80002a1a:	17fd                	addi	a5,a5,-1
    80002a1c:	07b2                	slli	a5,a5,0xc
    80002a1e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a20:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002a24:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a26:	180026f3          	csrr	a3,satp
    80002a2a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a2c:	6d38                	ld	a4,88(a0)
    80002a2e:	6134                	ld	a3,64(a0)
    80002a30:	6585                	lui	a1,0x1
    80002a32:	96ae                	add	a3,a3,a1
    80002a34:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a36:	6d38                	ld	a4,88(a0)
    80002a38:	00000697          	auipc	a3,0x0
    80002a3c:	14668693          	addi	a3,a3,326 # 80002b7e <usertrap>
    80002a40:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a42:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a44:	8692                	mv	a3,tp
    80002a46:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a48:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a4c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a50:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a54:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a58:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a5a:	6f18                	ld	a4,24(a4)
    80002a5c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a60:	692c                	ld	a1,80(a0)
    80002a62:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a64:	00004717          	auipc	a4,0x4
    80002a68:	62c70713          	addi	a4,a4,1580 # 80007090 <userret>
    80002a6c:	8f11                	sub	a4,a4,a2
    80002a6e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a70:	577d                	li	a4,-1
    80002a72:	177e                	slli	a4,a4,0x3f
    80002a74:	8dd9                	or	a1,a1,a4
    80002a76:	02000537          	lui	a0,0x2000
    80002a7a:	157d                	addi	a0,a0,-1
    80002a7c:	0536                	slli	a0,a0,0xd
    80002a7e:	9782                	jalr	a5
}
    80002a80:	60a2                	ld	ra,8(sp)
    80002a82:	6402                	ld	s0,0(sp)
    80002a84:	0141                	addi	sp,sp,16
    80002a86:	8082                	ret

0000000080002a88 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a88:	1101                	addi	sp,sp,-32
    80002a8a:	ec06                	sd	ra,24(sp)
    80002a8c:	e822                	sd	s0,16(sp)
    80002a8e:	e426                	sd	s1,8(sp)
    80002a90:	e04a                	sd	s2,0(sp)
    80002a92:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a94:	000d0917          	auipc	s2,0xd0
    80002a98:	63c90913          	addi	s2,s2,1596 # 800d30d0 <tickslock>
    80002a9c:	854a                	mv	a0,s2
    80002a9e:	ffffe097          	auipc	ra,0xffffe
    80002aa2:	146080e7          	jalr	326(ra) # 80000be4 <acquire>
  ticks++;
    80002aa6:	00006497          	auipc	s1,0x6
    80002aaa:	59248493          	addi	s1,s1,1426 # 80009038 <ticks>
    80002aae:	409c                	lw	a5,0(s1)
    80002ab0:	2785                	addiw	a5,a5,1
    80002ab2:	c09c                	sw	a5,0(s1)
  update_time();
    80002ab4:	fffff097          	auipc	ra,0xfffff
    80002ab8:	496080e7          	jalr	1174(ra) # 80001f4a <update_time>
  wakeup(&ticks);
    80002abc:	8526                	mv	a0,s1
    80002abe:	00000097          	auipc	ra,0x0
    80002ac2:	986080e7          	jalr	-1658(ra) # 80002444 <wakeup>
  release(&tickslock);
    80002ac6:	854a                	mv	a0,s2
    80002ac8:	ffffe097          	auipc	ra,0xffffe
    80002acc:	1d0080e7          	jalr	464(ra) # 80000c98 <release>
}
    80002ad0:	60e2                	ld	ra,24(sp)
    80002ad2:	6442                	ld	s0,16(sp)
    80002ad4:	64a2                	ld	s1,8(sp)
    80002ad6:	6902                	ld	s2,0(sp)
    80002ad8:	6105                	addi	sp,sp,32
    80002ada:	8082                	ret

0000000080002adc <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002adc:	1101                	addi	sp,sp,-32
    80002ade:	ec06                	sd	ra,24(sp)
    80002ae0:	e822                	sd	s0,16(sp)
    80002ae2:	e426                	sd	s1,8(sp)
    80002ae4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ae6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002aea:	00074d63          	bltz	a4,80002b04 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002aee:	57fd                	li	a5,-1
    80002af0:	17fe                	slli	a5,a5,0x3f
    80002af2:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002af4:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002af6:	06f70363          	beq	a4,a5,80002b5c <devintr+0x80>
  }
}
    80002afa:	60e2                	ld	ra,24(sp)
    80002afc:	6442                	ld	s0,16(sp)
    80002afe:	64a2                	ld	s1,8(sp)
    80002b00:	6105                	addi	sp,sp,32
    80002b02:	8082                	ret
     (scause & 0xff) == 9){
    80002b04:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002b08:	46a5                	li	a3,9
    80002b0a:	fed792e3          	bne	a5,a3,80002aee <devintr+0x12>
    int irq = plic_claim();
    80002b0e:	00004097          	auipc	ra,0x4
    80002b12:	8ba080e7          	jalr	-1862(ra) # 800063c8 <plic_claim>
    80002b16:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002b18:	47a9                	li	a5,10
    80002b1a:	02f50763          	beq	a0,a5,80002b48 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002b1e:	4785                	li	a5,1
    80002b20:	02f50963          	beq	a0,a5,80002b52 <devintr+0x76>
    return 1;
    80002b24:	4505                	li	a0,1
    } else if(irq){
    80002b26:	d8f1                	beqz	s1,80002afa <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002b28:	85a6                	mv	a1,s1
    80002b2a:	00006517          	auipc	a0,0x6
    80002b2e:	80e50513          	addi	a0,a0,-2034 # 80008338 <states.1769+0x38>
    80002b32:	ffffe097          	auipc	ra,0xffffe
    80002b36:	a56080e7          	jalr	-1450(ra) # 80000588 <printf>
      plic_complete(irq);
    80002b3a:	8526                	mv	a0,s1
    80002b3c:	00004097          	auipc	ra,0x4
    80002b40:	8b0080e7          	jalr	-1872(ra) # 800063ec <plic_complete>
    return 1;
    80002b44:	4505                	li	a0,1
    80002b46:	bf55                	j	80002afa <devintr+0x1e>
      uartintr();
    80002b48:	ffffe097          	auipc	ra,0xffffe
    80002b4c:	e60080e7          	jalr	-416(ra) # 800009a8 <uartintr>
    80002b50:	b7ed                	j	80002b3a <devintr+0x5e>
      virtio_disk_intr();
    80002b52:	00004097          	auipc	ra,0x4
    80002b56:	d7a080e7          	jalr	-646(ra) # 800068cc <virtio_disk_intr>
    80002b5a:	b7c5                	j	80002b3a <devintr+0x5e>
    if(cpuid() == 0){
    80002b5c:	fffff097          	auipc	ra,0xfffff
    80002b60:	e48080e7          	jalr	-440(ra) # 800019a4 <cpuid>
    80002b64:	c901                	beqz	a0,80002b74 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b66:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b6a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b6c:	14479073          	csrw	sip,a5
    return 2;
    80002b70:	4509                	li	a0,2
    80002b72:	b761                	j	80002afa <devintr+0x1e>
      clockintr();
    80002b74:	00000097          	auipc	ra,0x0
    80002b78:	f14080e7          	jalr	-236(ra) # 80002a88 <clockintr>
    80002b7c:	b7ed                	j	80002b66 <devintr+0x8a>

0000000080002b7e <usertrap>:
{
    80002b7e:	1101                	addi	sp,sp,-32
    80002b80:	ec06                	sd	ra,24(sp)
    80002b82:	e822                	sd	s0,16(sp)
    80002b84:	e426                	sd	s1,8(sp)
    80002b86:	e04a                	sd	s2,0(sp)
    80002b88:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b8a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b8e:	1007f793          	andi	a5,a5,256
    80002b92:	e3ad                	bnez	a5,80002bf4 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b94:	00003797          	auipc	a5,0x3
    80002b98:	72c78793          	addi	a5,a5,1836 # 800062c0 <kernelvec>
    80002b9c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002ba0:	fffff097          	auipc	ra,0xfffff
    80002ba4:	e30080e7          	jalr	-464(ra) # 800019d0 <myproc>
    80002ba8:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002baa:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bac:	14102773          	csrr	a4,sepc
    80002bb0:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bb2:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002bb6:	47a1                	li	a5,8
    80002bb8:	04f71c63          	bne	a4,a5,80002c10 <usertrap+0x92>
    if(p->killed)
    80002bbc:	551c                	lw	a5,40(a0)
    80002bbe:	e3b9                	bnez	a5,80002c04 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002bc0:	6cb8                	ld	a4,88(s1)
    80002bc2:	6f1c                	ld	a5,24(a4)
    80002bc4:	0791                	addi	a5,a5,4
    80002bc6:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bc8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002bcc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bd0:	10079073          	csrw	sstatus,a5
    syscall();
    80002bd4:	00000097          	auipc	ra,0x0
    80002bd8:	56c080e7          	jalr	1388(ra) # 80003140 <syscall>
  if(p->killed)
    80002bdc:	549c                	lw	a5,40(s1)
    80002bde:	ebc1                	bnez	a5,80002c6e <usertrap+0xf0>
  usertrapret();
    80002be0:	00000097          	auipc	ra,0x0
    80002be4:	e0a080e7          	jalr	-502(ra) # 800029ea <usertrapret>
}
    80002be8:	60e2                	ld	ra,24(sp)
    80002bea:	6442                	ld	s0,16(sp)
    80002bec:	64a2                	ld	s1,8(sp)
    80002bee:	6902                	ld	s2,0(sp)
    80002bf0:	6105                	addi	sp,sp,32
    80002bf2:	8082                	ret
    panic("usertrap: not from user mode");
    80002bf4:	00005517          	auipc	a0,0x5
    80002bf8:	76450513          	addi	a0,a0,1892 # 80008358 <states.1769+0x58>
    80002bfc:	ffffe097          	auipc	ra,0xffffe
    80002c00:	942080e7          	jalr	-1726(ra) # 8000053e <panic>
      exit(-1);
    80002c04:	557d                	li	a0,-1
    80002c06:	00000097          	auipc	ra,0x0
    80002c0a:	91e080e7          	jalr	-1762(ra) # 80002524 <exit>
    80002c0e:	bf4d                	j	80002bc0 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002c10:	00000097          	auipc	ra,0x0
    80002c14:	ecc080e7          	jalr	-308(ra) # 80002adc <devintr>
    80002c18:	892a                	mv	s2,a0
    80002c1a:	c501                	beqz	a0,80002c22 <usertrap+0xa4>
  if(p->killed)
    80002c1c:	549c                	lw	a5,40(s1)
    80002c1e:	c3a1                	beqz	a5,80002c5e <usertrap+0xe0>
    80002c20:	a815                	j	80002c54 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c22:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c26:	5890                	lw	a2,48(s1)
    80002c28:	00005517          	auipc	a0,0x5
    80002c2c:	75050513          	addi	a0,a0,1872 # 80008378 <states.1769+0x78>
    80002c30:	ffffe097          	auipc	ra,0xffffe
    80002c34:	958080e7          	jalr	-1704(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c38:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c3c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c40:	00005517          	auipc	a0,0x5
    80002c44:	76850513          	addi	a0,a0,1896 # 800083a8 <states.1769+0xa8>
    80002c48:	ffffe097          	auipc	ra,0xffffe
    80002c4c:	940080e7          	jalr	-1728(ra) # 80000588 <printf>
    p->killed = 1;
    80002c50:	4785                	li	a5,1
    80002c52:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002c54:	557d                	li	a0,-1
    80002c56:	00000097          	auipc	ra,0x0
    80002c5a:	8ce080e7          	jalr	-1842(ra) # 80002524 <exit>
  if(which_dev == 2)
    80002c5e:	4789                	li	a5,2
    80002c60:	f8f910e3          	bne	s2,a5,80002be0 <usertrap+0x62>
    yield();
    80002c64:	fffff097          	auipc	ra,0xfffff
    80002c68:	4d4080e7          	jalr	1236(ra) # 80002138 <yield>
    80002c6c:	bf95                	j	80002be0 <usertrap+0x62>
  int which_dev = 0;
    80002c6e:	4901                	li	s2,0
    80002c70:	b7d5                	j	80002c54 <usertrap+0xd6>

0000000080002c72 <kerneltrap>:
{
    80002c72:	7179                	addi	sp,sp,-48
    80002c74:	f406                	sd	ra,40(sp)
    80002c76:	f022                	sd	s0,32(sp)
    80002c78:	ec26                	sd	s1,24(sp)
    80002c7a:	e84a                	sd	s2,16(sp)
    80002c7c:	e44e                	sd	s3,8(sp)
    80002c7e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c80:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c84:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c88:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c8c:	1004f793          	andi	a5,s1,256
    80002c90:	cb85                	beqz	a5,80002cc0 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c92:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c96:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c98:	ef85                	bnez	a5,80002cd0 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c9a:	00000097          	auipc	ra,0x0
    80002c9e:	e42080e7          	jalr	-446(ra) # 80002adc <devintr>
    80002ca2:	cd1d                	beqz	a0,80002ce0 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ca4:	4789                	li	a5,2
    80002ca6:	06f50a63          	beq	a0,a5,80002d1a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002caa:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cae:	10049073          	csrw	sstatus,s1
}
    80002cb2:	70a2                	ld	ra,40(sp)
    80002cb4:	7402                	ld	s0,32(sp)
    80002cb6:	64e2                	ld	s1,24(sp)
    80002cb8:	6942                	ld	s2,16(sp)
    80002cba:	69a2                	ld	s3,8(sp)
    80002cbc:	6145                	addi	sp,sp,48
    80002cbe:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002cc0:	00005517          	auipc	a0,0x5
    80002cc4:	70850513          	addi	a0,a0,1800 # 800083c8 <states.1769+0xc8>
    80002cc8:	ffffe097          	auipc	ra,0xffffe
    80002ccc:	876080e7          	jalr	-1930(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002cd0:	00005517          	auipc	a0,0x5
    80002cd4:	72050513          	addi	a0,a0,1824 # 800083f0 <states.1769+0xf0>
    80002cd8:	ffffe097          	auipc	ra,0xffffe
    80002cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002ce0:	85ce                	mv	a1,s3
    80002ce2:	00005517          	auipc	a0,0x5
    80002ce6:	72e50513          	addi	a0,a0,1838 # 80008410 <states.1769+0x110>
    80002cea:	ffffe097          	auipc	ra,0xffffe
    80002cee:	89e080e7          	jalr	-1890(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cf2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cf6:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cfa:	00005517          	auipc	a0,0x5
    80002cfe:	72650513          	addi	a0,a0,1830 # 80008420 <states.1769+0x120>
    80002d02:	ffffe097          	auipc	ra,0xffffe
    80002d06:	886080e7          	jalr	-1914(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002d0a:	00005517          	auipc	a0,0x5
    80002d0e:	72e50513          	addi	a0,a0,1838 # 80008438 <states.1769+0x138>
    80002d12:	ffffe097          	auipc	ra,0xffffe
    80002d16:	82c080e7          	jalr	-2004(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d1a:	fffff097          	auipc	ra,0xfffff
    80002d1e:	cb6080e7          	jalr	-842(ra) # 800019d0 <myproc>
    80002d22:	d541                	beqz	a0,80002caa <kerneltrap+0x38>
    80002d24:	fffff097          	auipc	ra,0xfffff
    80002d28:	cac080e7          	jalr	-852(ra) # 800019d0 <myproc>
    80002d2c:	4d18                	lw	a4,24(a0)
    80002d2e:	4791                	li	a5,4
    80002d30:	f6f71de3          	bne	a4,a5,80002caa <kerneltrap+0x38>
    yield();
    80002d34:	fffff097          	auipc	ra,0xfffff
    80002d38:	404080e7          	jalr	1028(ra) # 80002138 <yield>
    80002d3c:	b7bd                	j	80002caa <kerneltrap+0x38>

0000000080002d3e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d3e:	1101                	addi	sp,sp,-32
    80002d40:	ec06                	sd	ra,24(sp)
    80002d42:	e822                	sd	s0,16(sp)
    80002d44:	e426                	sd	s1,8(sp)
    80002d46:	1000                	addi	s0,sp,32
    80002d48:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d4a:	fffff097          	auipc	ra,0xfffff
    80002d4e:	c86080e7          	jalr	-890(ra) # 800019d0 <myproc>
  switch (n)
    80002d52:	4795                	li	a5,5
    80002d54:	0497e163          	bltu	a5,s1,80002d96 <argraw+0x58>
    80002d58:	048a                	slli	s1,s1,0x2
    80002d5a:	00005717          	auipc	a4,0x5
    80002d5e:	7c670713          	addi	a4,a4,1990 # 80008520 <states.1769+0x220>
    80002d62:	94ba                	add	s1,s1,a4
    80002d64:	409c                	lw	a5,0(s1)
    80002d66:	97ba                	add	a5,a5,a4
    80002d68:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002d6a:	6d3c                	ld	a5,88(a0)
    80002d6c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d6e:	60e2                	ld	ra,24(sp)
    80002d70:	6442                	ld	s0,16(sp)
    80002d72:	64a2                	ld	s1,8(sp)
    80002d74:	6105                	addi	sp,sp,32
    80002d76:	8082                	ret
    return p->trapframe->a1;
    80002d78:	6d3c                	ld	a5,88(a0)
    80002d7a:	7fa8                	ld	a0,120(a5)
    80002d7c:	bfcd                	j	80002d6e <argraw+0x30>
    return p->trapframe->a2;
    80002d7e:	6d3c                	ld	a5,88(a0)
    80002d80:	63c8                	ld	a0,128(a5)
    80002d82:	b7f5                	j	80002d6e <argraw+0x30>
    return p->trapframe->a3;
    80002d84:	6d3c                	ld	a5,88(a0)
    80002d86:	67c8                	ld	a0,136(a5)
    80002d88:	b7dd                	j	80002d6e <argraw+0x30>
    return p->trapframe->a4;
    80002d8a:	6d3c                	ld	a5,88(a0)
    80002d8c:	6bc8                	ld	a0,144(a5)
    80002d8e:	b7c5                	j	80002d6e <argraw+0x30>
    return p->trapframe->a5;
    80002d90:	6d3c                	ld	a5,88(a0)
    80002d92:	6fc8                	ld	a0,152(a5)
    80002d94:	bfe9                	j	80002d6e <argraw+0x30>
  panic("argraw");
    80002d96:	00005517          	auipc	a0,0x5
    80002d9a:	6b250513          	addi	a0,a0,1714 # 80008448 <states.1769+0x148>
    80002d9e:	ffffd097          	auipc	ra,0xffffd
    80002da2:	7a0080e7          	jalr	1952(ra) # 8000053e <panic>

0000000080002da6 <fetchaddr>:
{
    80002da6:	1101                	addi	sp,sp,-32
    80002da8:	ec06                	sd	ra,24(sp)
    80002daa:	e822                	sd	s0,16(sp)
    80002dac:	e426                	sd	s1,8(sp)
    80002dae:	e04a                	sd	s2,0(sp)
    80002db0:	1000                	addi	s0,sp,32
    80002db2:	84aa                	mv	s1,a0
    80002db4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002db6:	fffff097          	auipc	ra,0xfffff
    80002dba:	c1a080e7          	jalr	-998(ra) # 800019d0 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    80002dbe:	653c                	ld	a5,72(a0)
    80002dc0:	02f4f863          	bgeu	s1,a5,80002df0 <fetchaddr+0x4a>
    80002dc4:	00848713          	addi	a4,s1,8
    80002dc8:	02e7e663          	bltu	a5,a4,80002df4 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002dcc:	46a1                	li	a3,8
    80002dce:	8626                	mv	a2,s1
    80002dd0:	85ca                	mv	a1,s2
    80002dd2:	6928                	ld	a0,80(a0)
    80002dd4:	fffff097          	auipc	ra,0xfffff
    80002dd8:	92a080e7          	jalr	-1750(ra) # 800016fe <copyin>
    80002ddc:	00a03533          	snez	a0,a0
    80002de0:	40a00533          	neg	a0,a0
}
    80002de4:	60e2                	ld	ra,24(sp)
    80002de6:	6442                	ld	s0,16(sp)
    80002de8:	64a2                	ld	s1,8(sp)
    80002dea:	6902                	ld	s2,0(sp)
    80002dec:	6105                	addi	sp,sp,32
    80002dee:	8082                	ret
    return -1;
    80002df0:	557d                	li	a0,-1
    80002df2:	bfcd                	j	80002de4 <fetchaddr+0x3e>
    80002df4:	557d                	li	a0,-1
    80002df6:	b7fd                	j	80002de4 <fetchaddr+0x3e>

0000000080002df8 <fetchstr>:
{
    80002df8:	7179                	addi	sp,sp,-48
    80002dfa:	f406                	sd	ra,40(sp)
    80002dfc:	f022                	sd	s0,32(sp)
    80002dfe:	ec26                	sd	s1,24(sp)
    80002e00:	e84a                	sd	s2,16(sp)
    80002e02:	e44e                	sd	s3,8(sp)
    80002e04:	1800                	addi	s0,sp,48
    80002e06:	892a                	mv	s2,a0
    80002e08:	84ae                	mv	s1,a1
    80002e0a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002e0c:	fffff097          	auipc	ra,0xfffff
    80002e10:	bc4080e7          	jalr	-1084(ra) # 800019d0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002e14:	86ce                	mv	a3,s3
    80002e16:	864a                	mv	a2,s2
    80002e18:	85a6                	mv	a1,s1
    80002e1a:	6928                	ld	a0,80(a0)
    80002e1c:	fffff097          	auipc	ra,0xfffff
    80002e20:	96e080e7          	jalr	-1682(ra) # 8000178a <copyinstr>
  if (err < 0)
    80002e24:	00054763          	bltz	a0,80002e32 <fetchstr+0x3a>
  return strlen(buf);
    80002e28:	8526                	mv	a0,s1
    80002e2a:	ffffe097          	auipc	ra,0xffffe
    80002e2e:	03a080e7          	jalr	58(ra) # 80000e64 <strlen>
}
    80002e32:	70a2                	ld	ra,40(sp)
    80002e34:	7402                	ld	s0,32(sp)
    80002e36:	64e2                	ld	s1,24(sp)
    80002e38:	6942                	ld	s2,16(sp)
    80002e3a:	69a2                	ld	s3,8(sp)
    80002e3c:	6145                	addi	sp,sp,48
    80002e3e:	8082                	ret

0000000080002e40 <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    80002e40:	1101                	addi	sp,sp,-32
    80002e42:	ec06                	sd	ra,24(sp)
    80002e44:	e822                	sd	s0,16(sp)
    80002e46:	e426                	sd	s1,8(sp)
    80002e48:	1000                	addi	s0,sp,32
    80002e4a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e4c:	00000097          	auipc	ra,0x0
    80002e50:	ef2080e7          	jalr	-270(ra) # 80002d3e <argraw>
    80002e54:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e56:	4501                	li	a0,0
    80002e58:	60e2                	ld	ra,24(sp)
    80002e5a:	6442                	ld	s0,16(sp)
    80002e5c:	64a2                	ld	s1,8(sp)
    80002e5e:	6105                	addi	sp,sp,32
    80002e60:	8082                	ret

0000000080002e62 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    80002e62:	1101                	addi	sp,sp,-32
    80002e64:	ec06                	sd	ra,24(sp)
    80002e66:	e822                	sd	s0,16(sp)
    80002e68:	e426                	sd	s1,8(sp)
    80002e6a:	1000                	addi	s0,sp,32
    80002e6c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e6e:	00000097          	auipc	ra,0x0
    80002e72:	ed0080e7          	jalr	-304(ra) # 80002d3e <argraw>
    80002e76:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e78:	4501                	li	a0,0
    80002e7a:	60e2                	ld	ra,24(sp)
    80002e7c:	6442                	ld	s0,16(sp)
    80002e7e:	64a2                	ld	s1,8(sp)
    80002e80:	6105                	addi	sp,sp,32
    80002e82:	8082                	ret

0000000080002e84 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002e84:	1101                	addi	sp,sp,-32
    80002e86:	ec06                	sd	ra,24(sp)
    80002e88:	e822                	sd	s0,16(sp)
    80002e8a:	e426                	sd	s1,8(sp)
    80002e8c:	e04a                	sd	s2,0(sp)
    80002e8e:	1000                	addi	s0,sp,32
    80002e90:	84ae                	mv	s1,a1
    80002e92:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e94:	00000097          	auipc	ra,0x0
    80002e98:	eaa080e7          	jalr	-342(ra) # 80002d3e <argraw>
  uint64 addr;
  if (argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e9c:	864a                	mv	a2,s2
    80002e9e:	85a6                	mv	a1,s1
    80002ea0:	00000097          	auipc	ra,0x0
    80002ea4:	f58080e7          	jalr	-168(ra) # 80002df8 <fetchstr>
}
    80002ea8:	60e2                	ld	ra,24(sp)
    80002eaa:	6442                	ld	s0,16(sp)
    80002eac:	64a2                	ld	s1,8(sp)
    80002eae:	6902                	ld	s2,0(sp)
    80002eb0:	6105                	addi	sp,sp,32
    80002eb2:	8082                	ret

0000000080002eb4 <n_strcpy>:
    p->trapframe->a0 = -1;
  }
}

char *n_strcpy(char *dest, char const *src)
{
    80002eb4:	1141                	addi	sp,sp,-16
    80002eb6:	e422                	sd	s0,8(sp)
    80002eb8:	0800                	addi	s0,sp,16

  char *ptr = dest;

  while ((*dest++ = *src++))
    80002eba:	87aa                	mv	a5,a0
    80002ebc:	0585                	addi	a1,a1,1
    80002ebe:	0785                	addi	a5,a5,1
    80002ec0:	fff5c703          	lbu	a4,-1(a1) # fff <_entry-0x7ffff001>
    80002ec4:	fee78fa3          	sb	a4,-1(a5)
    80002ec8:	fb75                	bnez	a4,80002ebc <n_strcpy+0x8>
    ;

  return ptr;
}
    80002eca:	6422                	ld	s0,8(sp)
    80002ecc:	0141                	addi	sp,sp,16
    80002ece:	8082                	ret

0000000080002ed0 <num_to_name>:

char *num_to_name(int num, char *string)
{
    80002ed0:	1101                	addi	sp,sp,-32
    80002ed2:	ec06                	sd	ra,24(sp)
    80002ed4:	e822                	sd	s0,16(sp)
    80002ed6:	e426                	sd	s1,8(sp)
    80002ed8:	1000                	addi	s0,sp,32
    80002eda:	84ae                	mv	s1,a1
  switch (num)
    80002edc:	47dd                	li	a5,23
    80002ede:	02a7e463          	bltu	a5,a0,80002f06 <num_to_name+0x36>
    80002ee2:	050a                	slli	a0,a0,0x2
    80002ee4:	00005717          	auipc	a4,0x5
    80002ee8:	65470713          	addi	a4,a4,1620 # 80008538 <states.1769+0x238>
    80002eec:	953a                	add	a0,a0,a4
    80002eee:	411c                	lw	a5,0(a0)
    80002ef0:	97ba                	add	a5,a5,a4
    80002ef2:	8782                	jr	a5
  {
  case 1:
    n_strcpy(string, "fork");
    80002ef4:	00005597          	auipc	a1,0x5
    80002ef8:	55c58593          	addi	a1,a1,1372 # 80008450 <states.1769+0x150>
    80002efc:	8526                	mv	a0,s1
    80002efe:	00000097          	auipc	ra,0x0
    80002f02:	fb6080e7          	jalr	-74(ra) # 80002eb4 <n_strcpy>
  case 23:
    n_strcpy(string, "trace");
    break;
  }
  return string;
}
    80002f06:	8526                	mv	a0,s1
    80002f08:	60e2                	ld	ra,24(sp)
    80002f0a:	6442                	ld	s0,16(sp)
    80002f0c:	64a2                	ld	s1,8(sp)
    80002f0e:	6105                	addi	sp,sp,32
    80002f10:	8082                	ret
    n_strcpy(string, "exit");
    80002f12:	00005597          	auipc	a1,0x5
    80002f16:	54658593          	addi	a1,a1,1350 # 80008458 <states.1769+0x158>
    80002f1a:	8526                	mv	a0,s1
    80002f1c:	00000097          	auipc	ra,0x0
    80002f20:	f98080e7          	jalr	-104(ra) # 80002eb4 <n_strcpy>
    break;
    80002f24:	b7cd                	j	80002f06 <num_to_name+0x36>
    n_strcpy(string, "wait");
    80002f26:	00005597          	auipc	a1,0x5
    80002f2a:	53a58593          	addi	a1,a1,1338 # 80008460 <states.1769+0x160>
    80002f2e:	8526                	mv	a0,s1
    80002f30:	00000097          	auipc	ra,0x0
    80002f34:	f84080e7          	jalr	-124(ra) # 80002eb4 <n_strcpy>
    break;
    80002f38:	b7f9                	j	80002f06 <num_to_name+0x36>
    n_strcpy(string, "pipe");
    80002f3a:	00005597          	auipc	a1,0x5
    80002f3e:	52e58593          	addi	a1,a1,1326 # 80008468 <states.1769+0x168>
    80002f42:	8526                	mv	a0,s1
    80002f44:	00000097          	auipc	ra,0x0
    80002f48:	f70080e7          	jalr	-144(ra) # 80002eb4 <n_strcpy>
    break;
    80002f4c:	bf6d                	j	80002f06 <num_to_name+0x36>
    n_strcpy(string, "read");
    80002f4e:	00006597          	auipc	a1,0x6
    80002f52:	88a58593          	addi	a1,a1,-1910 # 800087d8 <syscalls+0x1e0>
    80002f56:	8526                	mv	a0,s1
    80002f58:	00000097          	auipc	ra,0x0
    80002f5c:	f5c080e7          	jalr	-164(ra) # 80002eb4 <n_strcpy>
    break;
    80002f60:	b75d                	j	80002f06 <num_to_name+0x36>
    n_strcpy(string, "kill");
    80002f62:	00005597          	auipc	a1,0x5
    80002f66:	50e58593          	addi	a1,a1,1294 # 80008470 <states.1769+0x170>
    80002f6a:	8526                	mv	a0,s1
    80002f6c:	00000097          	auipc	ra,0x0
    80002f70:	f48080e7          	jalr	-184(ra) # 80002eb4 <n_strcpy>
    break;
    80002f74:	bf49                	j	80002f06 <num_to_name+0x36>
    n_strcpy(string, "exec");
    80002f76:	00005597          	auipc	a1,0x5
    80002f7a:	50258593          	addi	a1,a1,1282 # 80008478 <states.1769+0x178>
    80002f7e:	8526                	mv	a0,s1
    80002f80:	00000097          	auipc	ra,0x0
    80002f84:	f34080e7          	jalr	-204(ra) # 80002eb4 <n_strcpy>
    break;
    80002f88:	bfbd                	j	80002f06 <num_to_name+0x36>
    n_strcpy(string, "fstat");
    80002f8a:	00005597          	auipc	a1,0x5
    80002f8e:	4f658593          	addi	a1,a1,1270 # 80008480 <states.1769+0x180>
    80002f92:	8526                	mv	a0,s1
    80002f94:	00000097          	auipc	ra,0x0
    80002f98:	f20080e7          	jalr	-224(ra) # 80002eb4 <n_strcpy>
    break;
    80002f9c:	b7ad                	j	80002f06 <num_to_name+0x36>
    n_strcpy(string, "chdir");
    80002f9e:	00005597          	auipc	a1,0x5
    80002fa2:	4ea58593          	addi	a1,a1,1258 # 80008488 <states.1769+0x188>
    80002fa6:	8526                	mv	a0,s1
    80002fa8:	00000097          	auipc	ra,0x0
    80002fac:	f0c080e7          	jalr	-244(ra) # 80002eb4 <n_strcpy>
    break;
    80002fb0:	bf99                	j	80002f06 <num_to_name+0x36>
    n_strcpy(string, "dup");
    80002fb2:	00005597          	auipc	a1,0x5
    80002fb6:	4de58593          	addi	a1,a1,1246 # 80008490 <states.1769+0x190>
    80002fba:	8526                	mv	a0,s1
    80002fbc:	00000097          	auipc	ra,0x0
    80002fc0:	ef8080e7          	jalr	-264(ra) # 80002eb4 <n_strcpy>
    break;
    80002fc4:	b789                	j	80002f06 <num_to_name+0x36>
    n_strcpy(string, "getpid");
    80002fc6:	00005597          	auipc	a1,0x5
    80002fca:	4d258593          	addi	a1,a1,1234 # 80008498 <states.1769+0x198>
    80002fce:	8526                	mv	a0,s1
    80002fd0:	00000097          	auipc	ra,0x0
    80002fd4:	ee4080e7          	jalr	-284(ra) # 80002eb4 <n_strcpy>
    break;
    80002fd8:	b73d                	j	80002f06 <num_to_name+0x36>
    n_strcpy(string, "sbrk");
    80002fda:	00005597          	auipc	a1,0x5
    80002fde:	4c658593          	addi	a1,a1,1222 # 800084a0 <states.1769+0x1a0>
    80002fe2:	8526                	mv	a0,s1
    80002fe4:	00000097          	auipc	ra,0x0
    80002fe8:	ed0080e7          	jalr	-304(ra) # 80002eb4 <n_strcpy>
    break;
    80002fec:	bf29                	j	80002f06 <num_to_name+0x36>
    n_strcpy(string, "sleep");
    80002fee:	00005597          	auipc	a1,0x5
    80002ff2:	4ba58593          	addi	a1,a1,1210 # 800084a8 <states.1769+0x1a8>
    80002ff6:	8526                	mv	a0,s1
    80002ff8:	00000097          	auipc	ra,0x0
    80002ffc:	ebc080e7          	jalr	-324(ra) # 80002eb4 <n_strcpy>
    break;
    80003000:	b719                	j	80002f06 <num_to_name+0x36>
    n_strcpy(string, "uptime");
    80003002:	00005597          	auipc	a1,0x5
    80003006:	4ae58593          	addi	a1,a1,1198 # 800084b0 <states.1769+0x1b0>
    8000300a:	8526                	mv	a0,s1
    8000300c:	00000097          	auipc	ra,0x0
    80003010:	ea8080e7          	jalr	-344(ra) # 80002eb4 <n_strcpy>
    break;
    80003014:	bdcd                	j	80002f06 <num_to_name+0x36>
    n_strcpy(string, "open");
    80003016:	00005597          	auipc	a1,0x5
    8000301a:	4a258593          	addi	a1,a1,1186 # 800084b8 <states.1769+0x1b8>
    8000301e:	8526                	mv	a0,s1
    80003020:	00000097          	auipc	ra,0x0
    80003024:	e94080e7          	jalr	-364(ra) # 80002eb4 <n_strcpy>
    break;
    80003028:	bdf9                	j	80002f06 <num_to_name+0x36>
    n_strcpy(string, "write");
    8000302a:	00005597          	auipc	a1,0x5
    8000302e:	49658593          	addi	a1,a1,1174 # 800084c0 <states.1769+0x1c0>
    80003032:	8526                	mv	a0,s1
    80003034:	00000097          	auipc	ra,0x0
    80003038:	e80080e7          	jalr	-384(ra) # 80002eb4 <n_strcpy>
    break;
    8000303c:	b5e9                	j	80002f06 <num_to_name+0x36>
    n_strcpy(string, "mknod");
    8000303e:	00005597          	auipc	a1,0x5
    80003042:	48a58593          	addi	a1,a1,1162 # 800084c8 <states.1769+0x1c8>
    80003046:	8526                	mv	a0,s1
    80003048:	00000097          	auipc	ra,0x0
    8000304c:	e6c080e7          	jalr	-404(ra) # 80002eb4 <n_strcpy>
    break;
    80003050:	bd5d                	j	80002f06 <num_to_name+0x36>
    n_strcpy(string, "unlink");
    80003052:	00005597          	auipc	a1,0x5
    80003056:	47e58593          	addi	a1,a1,1150 # 800084d0 <states.1769+0x1d0>
    8000305a:	8526                	mv	a0,s1
    8000305c:	00000097          	auipc	ra,0x0
    80003060:	e58080e7          	jalr	-424(ra) # 80002eb4 <n_strcpy>
    break;
    80003064:	b54d                	j	80002f06 <num_to_name+0x36>
    n_strcpy(string, "link");
    80003066:	00005597          	auipc	a1,0x5
    8000306a:	47258593          	addi	a1,a1,1138 # 800084d8 <states.1769+0x1d8>
    8000306e:	8526                	mv	a0,s1
    80003070:	00000097          	auipc	ra,0x0
    80003074:	e44080e7          	jalr	-444(ra) # 80002eb4 <n_strcpy>
    break;
    80003078:	b579                	j	80002f06 <num_to_name+0x36>
    n_strcpy(string, "mkdir");
    8000307a:	00005597          	auipc	a1,0x5
    8000307e:	46658593          	addi	a1,a1,1126 # 800084e0 <states.1769+0x1e0>
    80003082:	8526                	mv	a0,s1
    80003084:	00000097          	auipc	ra,0x0
    80003088:	e30080e7          	jalr	-464(ra) # 80002eb4 <n_strcpy>
    break;
    8000308c:	bdad                	j	80002f06 <num_to_name+0x36>
    n_strcpy(string, "close");
    8000308e:	00005597          	auipc	a1,0x5
    80003092:	45a58593          	addi	a1,a1,1114 # 800084e8 <states.1769+0x1e8>
    80003096:	8526                	mv	a0,s1
    80003098:	00000097          	auipc	ra,0x0
    8000309c:	e1c080e7          	jalr	-484(ra) # 80002eb4 <n_strcpy>
    break;
    800030a0:	b59d                	j	80002f06 <num_to_name+0x36>
    n_strcpy(string, "waitx");
    800030a2:	00005597          	auipc	a1,0x5
    800030a6:	44e58593          	addi	a1,a1,1102 # 800084f0 <states.1769+0x1f0>
    800030aa:	8526                	mv	a0,s1
    800030ac:	00000097          	auipc	ra,0x0
    800030b0:	e08080e7          	jalr	-504(ra) # 80002eb4 <n_strcpy>
    break;
    800030b4:	bd89                	j	80002f06 <num_to_name+0x36>
    n_strcpy(string, "trace");
    800030b6:	00005597          	auipc	a1,0x5
    800030ba:	44258593          	addi	a1,a1,1090 # 800084f8 <states.1769+0x1f8>
    800030be:	8526                	mv	a0,s1
    800030c0:	00000097          	auipc	ra,0x0
    800030c4:	df4080e7          	jalr	-524(ra) # 80002eb4 <n_strcpy>
    break;
    800030c8:	bd3d                	j	80002f06 <num_to_name+0x36>

00000000800030ca <num_arg>:

int num_arg(int num, int args)
{
    800030ca:	1141                	addi	sp,sp,-16
    800030cc:	e422                	sd	s0,8(sp)
    800030ce:	0800                	addi	s0,sp,16
  switch (num)
    800030d0:	47dd                	li	a5,23
    800030d2:	06a7e563          	bltu	a5,a0,8000313c <num_arg+0x72>
    800030d6:	050a                	slli	a0,a0,0x2
    800030d8:	00005717          	auipc	a4,0x5
    800030dc:	4c070713          	addi	a4,a4,1216 # 80008598 <states.1769+0x298>
    800030e0:	953a                	add	a0,a0,a4
    800030e2:	411c                	lw	a5,0(a0)
    800030e4:	97ba                	add	a5,a5,a4
    800030e6:	8782                	jr	a5
    break;
  case 19:
    args = 2;
    break;
  case 20:
    args = 1;
    800030e8:	4501                	li	a0,0
  case 23:
    args = 1;
    break;
  }
  return args;
}
    800030ea:	6422                	ld	s0,8(sp)
    800030ec:	0141                	addi	sp,sp,16
    800030ee:	8082                	ret
    args = 1;
    800030f0:	4505                	li	a0,1
    break;
    800030f2:	bfe5                	j	800030ea <num_arg+0x20>
    args = 1;
    800030f4:	4505                	li	a0,1
    break;
    800030f6:	bfd5                	j	800030ea <num_arg+0x20>
    args = 3;
    800030f8:	450d                	li	a0,3
    break;
    800030fa:	bfc5                	j	800030ea <num_arg+0x20>
    args = 1;
    800030fc:	4505                	li	a0,1
    break;
    800030fe:	b7f5                	j	800030ea <num_arg+0x20>
    args = 2;
    80003100:	4509                	li	a0,2
    break;
    80003102:	b7e5                	j	800030ea <num_arg+0x20>
    args = 2;
    80003104:	4509                	li	a0,2
    break;
    80003106:	b7d5                	j	800030ea <num_arg+0x20>
    args = 1;
    80003108:	4505                	li	a0,1
    break;
    8000310a:	b7c5                	j	800030ea <num_arg+0x20>
    args = 1;
    8000310c:	4505                	li	a0,1
    break;
    8000310e:	bff1                	j	800030ea <num_arg+0x20>
    args = 1;
    80003110:	4505                	li	a0,1
    break;
    80003112:	bfe1                	j	800030ea <num_arg+0x20>
    args = 1;
    80003114:	4505                	li	a0,1
    break;
    80003116:	bfd1                	j	800030ea <num_arg+0x20>
    args = 2;
    80003118:	4509                	li	a0,2
    break;
    8000311a:	bfc1                	j	800030ea <num_arg+0x20>
    args = 3;
    8000311c:	450d                	li	a0,3
    break;
    8000311e:	b7f1                	j	800030ea <num_arg+0x20>
    args = 3;
    80003120:	450d                	li	a0,3
    break;
    80003122:	b7e1                	j	800030ea <num_arg+0x20>
    args = 1;
    80003124:	4505                	li	a0,1
    break;
    80003126:	b7d1                	j	800030ea <num_arg+0x20>
    args = 2;
    80003128:	4509                	li	a0,2
    break;
    8000312a:	b7c1                	j	800030ea <num_arg+0x20>
    args = 1;
    8000312c:	4505                	li	a0,1
    break;
    8000312e:	bf75                	j	800030ea <num_arg+0x20>
    args = 1;
    80003130:	4505                	li	a0,1
    break;
    80003132:	bf65                	j	800030ea <num_arg+0x20>
    args = 3;
    80003134:	450d                	li	a0,3
    break;
    80003136:	bf55                	j	800030ea <num_arg+0x20>
    args = 1;
    80003138:	4505                	li	a0,1
    break;
    8000313a:	bf45                	j	800030ea <num_arg+0x20>
    args = 1;
    8000313c:	852e                	mv	a0,a1
    8000313e:	b775                	j	800030ea <num_arg+0x20>

0000000080003140 <syscall>:
{
    80003140:	7141                	addi	sp,sp,-496
    80003142:	f786                	sd	ra,488(sp)
    80003144:	f3a2                	sd	s0,480(sp)
    80003146:	efa6                	sd	s1,472(sp)
    80003148:	ebca                	sd	s2,464(sp)
    8000314a:	e7ce                	sd	s3,456(sp)
    8000314c:	e3d2                	sd	s4,448(sp)
    8000314e:	ff56                	sd	s5,440(sp)
    80003150:	fb5a                	sd	s6,432(sp)
    80003152:	f75e                	sd	s7,424(sp)
    80003154:	1b80                	addi	s0,sp,496
  struct proc *p = myproc();
    80003156:	fffff097          	auipc	ra,0xfffff
    8000315a:	87a080e7          	jalr	-1926(ra) # 800019d0 <myproc>
    8000315e:	892a                	mv	s2,a0
  num = p->trapframe->a7;
    80003160:	6d3c                	ld	a5,88(a0)
    80003162:	77dc                	ld	a5,168(a5)
    80003164:	00078b1b          	sext.w	s6,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80003168:	37fd                	addiw	a5,a5,-1
    8000316a:	4759                	li	a4,22
    8000316c:	0ef76963          	bltu	a4,a5,8000325e <syscall+0x11e>
    80003170:	003b1713          	slli	a4,s6,0x3
    80003174:	00005797          	auipc	a5,0x5
    80003178:	48478793          	addi	a5,a5,1156 # 800085f8 <syscalls>
    8000317c:	97ba                	add	a5,a5,a4
    8000317e:	0007bb83          	ld	s7,0(a5)
    80003182:	0c0b8e63          	beqz	s7,8000325e <syscall+0x11e>
    args = num_arg(num, args);
    80003186:	4581                	li	a1,0
    80003188:	855a                	mv	a0,s6
    8000318a:	00000097          	auipc	ra,0x0
    8000318e:	f40080e7          	jalr	-192(ra) # 800030ca <num_arg>
    80003192:	89aa                	mv	s3,a0
    for (int i = 0; i < args; i++)
    80003194:	02a05f63          	blez	a0,800031d2 <syscall+0x92>
    80003198:	4481                	li	s1,0
      p->syscall_args[p->syscall_index][i] = arg_holder;
    8000319a:	6a8d                	lui	s5,0x3
    8000319c:	9aca                	add	s5,s5,s2
    8000319e:	6a05                	lui	s4,0x1
    800031a0:	82ca0a13          	addi	s4,s4,-2004 # 82c <_entry-0x7ffff7d4>
      argint(i, &arg_holder);
    800031a4:	fac40593          	addi	a1,s0,-84
    800031a8:	8526                	mv	a0,s1
    800031aa:	00000097          	auipc	ra,0x0
    800031ae:	c96080e7          	jalr	-874(ra) # 80002e40 <argint>
      p->syscall_args[p->syscall_index][i] = arg_holder;
    800031b2:	054aa703          	lw	a4,84(s5) # 3054 <_entry-0x7fffcfac>
    800031b6:	00271793          	slli	a5,a4,0x2
    800031ba:	97ba                	add	a5,a5,a4
    800031bc:	0786                	slli	a5,a5,0x1
    800031be:	97a6                	add	a5,a5,s1
    800031c0:	97d2                	add	a5,a5,s4
    800031c2:	078a                	slli	a5,a5,0x2
    800031c4:	97ca                	add	a5,a5,s2
    800031c6:	fac42703          	lw	a4,-84(s0)
    800031ca:	c3d8                	sw	a4,4(a5)
    for (int i = 0; i < args; i++)
    800031cc:	2485                	addiw	s1,s1,1
    800031ce:	fc999be3          	bne	s3,s1,800031a4 <syscall+0x64>
    p->trapframe->a0 = syscalls[num]();
    800031d2:	05893483          	ld	s1,88(s2)
    800031d6:	9b82                	jalr	s7
    800031d8:	f8a8                	sd	a0,112(s1)
    for(int k=0;k<100;k++)
    800031da:	e1840693          	addi	a3,s0,-488
    800031de:	fa840713          	addi	a4,s0,-88
    p->trapframe->a0 = syscalls[num]();
    800031e2:	87b6                	mv	a5,a3
      array[k]=0;
    800031e4:	0007a023          	sw	zero,0(a5)
    for(int k=0;k<100;k++)
    800031e8:	0791                	addi	a5,a5,4
    800031ea:	fee79de3          	bne	a5,a4,800031e4 <syscall+0xa4>
    int mask_temp=p->mask;
    800031ee:	678d                	lui	a5,0x3
    800031f0:	97ca                	add	a5,a5,s2
    800031f2:	4fa8                	lw	a0,88(a5)
    for (j = 0; p->mask > 0; j++)
    800031f4:	02a05263          	blez	a0,80003218 <syscall+0xd8>
    800031f8:	87aa                	mv	a5,a0
    800031fa:	4585                	li	a1,1
      array[j] = p->mask % 2;
    800031fc:	01f7d61b          	srliw	a2,a5,0x1f
    80003200:	00f6073b          	addw	a4,a2,a5
    80003204:	8b05                	andi	a4,a4,1
    80003206:	9f11                	subw	a4,a4,a2
    80003208:	c298                	sw	a4,0(a3)
      p->mask = p->mask / 2;
    8000320a:	873e                	mv	a4,a5
    8000320c:	9fb1                	addw	a5,a5,a2
    8000320e:	4017d79b          	sraiw	a5,a5,0x1
    for (j = 0; p->mask > 0; j++)
    80003212:	0691                	addi	a3,a3,4
    80003214:	fee5c4e3          	blt	a1,a4,800031fc <syscall+0xbc>
    p->mask=mask_temp;
    80003218:	678d                	lui	a5,0x3
    8000321a:	97ca                	add	a5,a5,s2
    8000321c:	cfa8                	sw	a0,88(a5)
    if (p->is_trace == 1 && array[num] == 1)
    8000321e:	4ff8                	lw	a4,92(a5)
    80003220:	4785                	li	a5,1
    80003222:	04f71f63          	bne	a4,a5,80003280 <syscall+0x140>
    80003226:	002b1793          	slli	a5,s6,0x2
    8000322a:	fb040713          	addi	a4,s0,-80
    8000322e:	97ba                	add	a5,a5,a4
    80003230:	e687a703          	lw	a4,-408(a5) # 2e68 <_entry-0x7fffd198>
    80003234:	4785                	li	a5,1
    80003236:	04f71563          	bne	a4,a5,80003280 <syscall+0x140>
      p->syscall_ids[p->syscall_index] = num;
    8000323a:	670d                	lui	a4,0x3
    8000323c:	974a                	add	a4,a4,s2
    8000323e:	4b74                	lw	a3,84(a4)
    80003240:	00269793          	slli	a5,a3,0x2
    80003244:	97ca                	add	a5,a5,s2
    80003246:	1767aa23          	sw	s6,372(a5)
      p->syscall_returns[p->syscall_index] = p->trapframe->a0;
    8000324a:	6605                	lui	a2,0x1
    8000324c:	97b2                	add	a5,a5,a2
    8000324e:	05893603          	ld	a2,88(s2)
    80003252:	7a30                	ld	a2,112(a2)
    80003254:	10c7aa23          	sw	a2,276(a5)
      p->syscall_index++;
    80003258:	2685                	addiw	a3,a3,1
    8000325a:	cb74                	sw	a3,84(a4)
  {
    8000325c:	a015                	j	80003280 <syscall+0x140>
    printf("%d %s: unknown sys call %d\n",
    8000325e:	86da                	mv	a3,s6
    80003260:	15890613          	addi	a2,s2,344
    80003264:	03092583          	lw	a1,48(s2)
    80003268:	00005517          	auipc	a0,0x5
    8000326c:	29850513          	addi	a0,a0,664 # 80008500 <states.1769+0x200>
    80003270:	ffffd097          	auipc	ra,0xffffd
    80003274:	318080e7          	jalr	792(ra) # 80000588 <printf>
    p->trapframe->a0 = -1;
    80003278:	05893783          	ld	a5,88(s2)
    8000327c:	577d                	li	a4,-1
    8000327e:	fbb8                	sd	a4,112(a5)
}
    80003280:	70be                	ld	ra,488(sp)
    80003282:	741e                	ld	s0,480(sp)
    80003284:	64fe                	ld	s1,472(sp)
    80003286:	695e                	ld	s2,464(sp)
    80003288:	69be                	ld	s3,456(sp)
    8000328a:	6a1e                	ld	s4,448(sp)
    8000328c:	7afa                	ld	s5,440(sp)
    8000328e:	7b5a                	ld	s6,432(sp)
    80003290:	7bba                	ld	s7,424(sp)
    80003292:	617d                	addi	sp,sp,496
    80003294:	8082                	ret

0000000080003296 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003296:	1101                	addi	sp,sp,-32
    80003298:	ec06                	sd	ra,24(sp)
    8000329a:	e822                	sd	s0,16(sp)
    8000329c:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000329e:	fec40593          	addi	a1,s0,-20
    800032a2:	4501                	li	a0,0
    800032a4:	00000097          	auipc	ra,0x0
    800032a8:	b9c080e7          	jalr	-1124(ra) # 80002e40 <argint>
    return -1;
    800032ac:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800032ae:	00054963          	bltz	a0,800032c0 <sys_exit+0x2a>
  exit(n);
    800032b2:	fec42503          	lw	a0,-20(s0)
    800032b6:	fffff097          	auipc	ra,0xfffff
    800032ba:	26e080e7          	jalr	622(ra) # 80002524 <exit>
  return 0;  // not reached
    800032be:	4781                	li	a5,0
}
    800032c0:	853e                	mv	a0,a5
    800032c2:	60e2                	ld	ra,24(sp)
    800032c4:	6442                	ld	s0,16(sp)
    800032c6:	6105                	addi	sp,sp,32
    800032c8:	8082                	ret

00000000800032ca <sys_getpid>:

uint64
sys_getpid(void)
{
    800032ca:	1141                	addi	sp,sp,-16
    800032cc:	e406                	sd	ra,8(sp)
    800032ce:	e022                	sd	s0,0(sp)
    800032d0:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800032d2:	ffffe097          	auipc	ra,0xffffe
    800032d6:	6fe080e7          	jalr	1790(ra) # 800019d0 <myproc>
}
    800032da:	5908                	lw	a0,48(a0)
    800032dc:	60a2                	ld	ra,8(sp)
    800032de:	6402                	ld	s0,0(sp)
    800032e0:	0141                	addi	sp,sp,16
    800032e2:	8082                	ret

00000000800032e4 <sys_fork>:

uint64
sys_fork(void)
{
    800032e4:	1141                	addi	sp,sp,-16
    800032e6:	e406                	sd	ra,8(sp)
    800032e8:	e022                	sd	s0,0(sp)
    800032ea:	0800                	addi	s0,sp,16
  return fork();
    800032ec:	fffff097          	auipc	ra,0xfffff
    800032f0:	b08080e7          	jalr	-1272(ra) # 80001df4 <fork>
}
    800032f4:	60a2                	ld	ra,8(sp)
    800032f6:	6402                	ld	s0,0(sp)
    800032f8:	0141                	addi	sp,sp,16
    800032fa:	8082                	ret

00000000800032fc <sys_trace>:



int
sys_trace(void)
{
    800032fc:	1101                	addi	sp,sp,-32
    800032fe:	ec06                	sd	ra,24(sp)
    80003300:	e822                	sd	s0,16(sp)
    80003302:	1000                	addi	s0,sp,32

  uint64 mask;
  if(argaddr(0,&mask)<0)
    80003304:	fe840593          	addi	a1,s0,-24
    80003308:	4501                	li	a0,0
    8000330a:	00000097          	auipc	ra,0x0
    8000330e:	b58080e7          	jalr	-1192(ra) # 80002e62 <argaddr>
    80003312:	00054c63          	bltz	a0,8000332a <sys_trace+0x2e>
    return -1;


  return trace(mask);
    80003316:	fe842503          	lw	a0,-24(s0)
    8000331a:	fffff097          	auipc	ra,0xfffff
    8000331e:	9ba080e7          	jalr	-1606(ra) # 80001cd4 <trace>
  
}
    80003322:	60e2                	ld	ra,24(sp)
    80003324:	6442                	ld	s0,16(sp)
    80003326:	6105                	addi	sp,sp,32
    80003328:	8082                	ret
    return -1;
    8000332a:	557d                	li	a0,-1
    8000332c:	bfdd                	j	80003322 <sys_trace+0x26>

000000008000332e <sys_wait>:

uint64
sys_wait(void)
{
    8000332e:	1101                	addi	sp,sp,-32
    80003330:	ec06                	sd	ra,24(sp)
    80003332:	e822                	sd	s0,16(sp)
    80003334:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003336:	fe840593          	addi	a1,s0,-24
    8000333a:	4501                	li	a0,0
    8000333c:	00000097          	auipc	ra,0x0
    80003340:	b26080e7          	jalr	-1242(ra) # 80002e62 <argaddr>
    80003344:	87aa                	mv	a5,a0
    return -1;
    80003346:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003348:	0007c863          	bltz	a5,80003358 <sys_wait+0x2a>
  return wait(p);
    8000334c:	fe843503          	ld	a0,-24(s0)
    80003350:	fffff097          	auipc	ra,0xfffff
    80003354:	e88080e7          	jalr	-376(ra) # 800021d8 <wait>
}
    80003358:	60e2                	ld	ra,24(sp)
    8000335a:	6442                	ld	s0,16(sp)
    8000335c:	6105                	addi	sp,sp,32
    8000335e:	8082                	ret

0000000080003360 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003360:	7139                	addi	sp,sp,-64
    80003362:	fc06                	sd	ra,56(sp)
    80003364:	f822                	sd	s0,48(sp)
    80003366:	f426                	sd	s1,40(sp)
    80003368:	f04a                	sd	s2,32(sp)
    8000336a:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  if(argaddr(0, &addr) < 0)
    8000336c:	fd840593          	addi	a1,s0,-40
    80003370:	4501                	li	a0,0
    80003372:	00000097          	auipc	ra,0x0
    80003376:	af0080e7          	jalr	-1296(ra) # 80002e62 <argaddr>
    return -1;
    8000337a:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0)
    8000337c:	08054063          	bltz	a0,800033fc <sys_waitx+0x9c>
  if(argaddr(1, &addr1) < 0) // user virtual memory
    80003380:	fd040593          	addi	a1,s0,-48
    80003384:	4505                	li	a0,1
    80003386:	00000097          	auipc	ra,0x0
    8000338a:	adc080e7          	jalr	-1316(ra) # 80002e62 <argaddr>
    return -1;
    8000338e:	57fd                	li	a5,-1
  if(argaddr(1, &addr1) < 0) // user virtual memory
    80003390:	06054663          	bltz	a0,800033fc <sys_waitx+0x9c>
  if(argaddr(2, &addr2) < 0)
    80003394:	fc840593          	addi	a1,s0,-56
    80003398:	4509                	li	a0,2
    8000339a:	00000097          	auipc	ra,0x0
    8000339e:	ac8080e7          	jalr	-1336(ra) # 80002e62 <argaddr>
    return -1;
    800033a2:	57fd                	li	a5,-1
  if(argaddr(2, &addr2) < 0)
    800033a4:	04054c63          	bltz	a0,800033fc <sys_waitx+0x9c>
  int ret = waitx(addr, &wtime, &rtime);
    800033a8:	fc040613          	addi	a2,s0,-64
    800033ac:	fc440593          	addi	a1,s0,-60
    800033b0:	fd843503          	ld	a0,-40(s0)
    800033b4:	fffff097          	auipc	ra,0xfffff
    800033b8:	f48080e7          	jalr	-184(ra) # 800022fc <waitx>
    800033bc:	892a                	mv	s2,a0
  struct proc* p = myproc();
    800033be:	ffffe097          	auipc	ra,0xffffe
    800033c2:	612080e7          	jalr	1554(ra) # 800019d0 <myproc>
    800033c6:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    800033c8:	4691                	li	a3,4
    800033ca:	fc440613          	addi	a2,s0,-60
    800033ce:	fd043583          	ld	a1,-48(s0)
    800033d2:	6928                	ld	a0,80(a0)
    800033d4:	ffffe097          	auipc	ra,0xffffe
    800033d8:	29e080e7          	jalr	670(ra) # 80001672 <copyout>
    return -1;
    800033dc:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    800033de:	00054f63          	bltz	a0,800033fc <sys_waitx+0x9c>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    800033e2:	4691                	li	a3,4
    800033e4:	fc040613          	addi	a2,s0,-64
    800033e8:	fc843583          	ld	a1,-56(s0)
    800033ec:	68a8                	ld	a0,80(s1)
    800033ee:	ffffe097          	auipc	ra,0xffffe
    800033f2:	284080e7          	jalr	644(ra) # 80001672 <copyout>
    800033f6:	00054a63          	bltz	a0,8000340a <sys_waitx+0xaa>
    return -1;
  return ret;
    800033fa:	87ca                	mv	a5,s2
}
    800033fc:	853e                	mv	a0,a5
    800033fe:	70e2                	ld	ra,56(sp)
    80003400:	7442                	ld	s0,48(sp)
    80003402:	74a2                	ld	s1,40(sp)
    80003404:	7902                	ld	s2,32(sp)
    80003406:	6121                	addi	sp,sp,64
    80003408:	8082                	ret
    return -1;
    8000340a:	57fd                	li	a5,-1
    8000340c:	bfc5                	j	800033fc <sys_waitx+0x9c>

000000008000340e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000340e:	7179                	addi	sp,sp,-48
    80003410:	f406                	sd	ra,40(sp)
    80003412:	f022                	sd	s0,32(sp)
    80003414:	ec26                	sd	s1,24(sp)
    80003416:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003418:	fdc40593          	addi	a1,s0,-36
    8000341c:	4501                	li	a0,0
    8000341e:	00000097          	auipc	ra,0x0
    80003422:	a22080e7          	jalr	-1502(ra) # 80002e40 <argint>
    80003426:	87aa                	mv	a5,a0
    return -1;
    80003428:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000342a:	0207c063          	bltz	a5,8000344a <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000342e:	ffffe097          	auipc	ra,0xffffe
    80003432:	5a2080e7          	jalr	1442(ra) # 800019d0 <myproc>
    80003436:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80003438:	fdc42503          	lw	a0,-36(s0)
    8000343c:	fffff097          	auipc	ra,0xfffff
    80003440:	944080e7          	jalr	-1724(ra) # 80001d80 <growproc>
    80003444:	00054863          	bltz	a0,80003454 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003448:	8526                	mv	a0,s1
}
    8000344a:	70a2                	ld	ra,40(sp)
    8000344c:	7402                	ld	s0,32(sp)
    8000344e:	64e2                	ld	s1,24(sp)
    80003450:	6145                	addi	sp,sp,48
    80003452:	8082                	ret
    return -1;
    80003454:	557d                	li	a0,-1
    80003456:	bfd5                	j	8000344a <sys_sbrk+0x3c>

0000000080003458 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003458:	7139                	addi	sp,sp,-64
    8000345a:	fc06                	sd	ra,56(sp)
    8000345c:	f822                	sd	s0,48(sp)
    8000345e:	f426                	sd	s1,40(sp)
    80003460:	f04a                	sd	s2,32(sp)
    80003462:	ec4e                	sd	s3,24(sp)
    80003464:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003466:	fcc40593          	addi	a1,s0,-52
    8000346a:	4501                	li	a0,0
    8000346c:	00000097          	auipc	ra,0x0
    80003470:	9d4080e7          	jalr	-1580(ra) # 80002e40 <argint>
    return -1;
    80003474:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003476:	06054563          	bltz	a0,800034e0 <sys_sleep+0x88>
  acquire(&tickslock);
    8000347a:	000d0517          	auipc	a0,0xd0
    8000347e:	c5650513          	addi	a0,a0,-938 # 800d30d0 <tickslock>
    80003482:	ffffd097          	auipc	ra,0xffffd
    80003486:	762080e7          	jalr	1890(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    8000348a:	00006917          	auipc	s2,0x6
    8000348e:	bae92903          	lw	s2,-1106(s2) # 80009038 <ticks>
  while(ticks - ticks0 < n){
    80003492:	fcc42783          	lw	a5,-52(s0)
    80003496:	cf85                	beqz	a5,800034ce <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003498:	000d0997          	auipc	s3,0xd0
    8000349c:	c3898993          	addi	s3,s3,-968 # 800d30d0 <tickslock>
    800034a0:	00006497          	auipc	s1,0x6
    800034a4:	b9848493          	addi	s1,s1,-1128 # 80009038 <ticks>
    if(myproc()->killed){
    800034a8:	ffffe097          	auipc	ra,0xffffe
    800034ac:	528080e7          	jalr	1320(ra) # 800019d0 <myproc>
    800034b0:	551c                	lw	a5,40(a0)
    800034b2:	ef9d                	bnez	a5,800034f0 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800034b4:	85ce                	mv	a1,s3
    800034b6:	8526                	mv	a0,s1
    800034b8:	fffff097          	auipc	ra,0xfffff
    800034bc:	cbc080e7          	jalr	-836(ra) # 80002174 <sleep>
  while(ticks - ticks0 < n){
    800034c0:	409c                	lw	a5,0(s1)
    800034c2:	412787bb          	subw	a5,a5,s2
    800034c6:	fcc42703          	lw	a4,-52(s0)
    800034ca:	fce7efe3          	bltu	a5,a4,800034a8 <sys_sleep+0x50>
  }
  release(&tickslock);
    800034ce:	000d0517          	auipc	a0,0xd0
    800034d2:	c0250513          	addi	a0,a0,-1022 # 800d30d0 <tickslock>
    800034d6:	ffffd097          	auipc	ra,0xffffd
    800034da:	7c2080e7          	jalr	1986(ra) # 80000c98 <release>
  return 0;
    800034de:	4781                	li	a5,0
}
    800034e0:	853e                	mv	a0,a5
    800034e2:	70e2                	ld	ra,56(sp)
    800034e4:	7442                	ld	s0,48(sp)
    800034e6:	74a2                	ld	s1,40(sp)
    800034e8:	7902                	ld	s2,32(sp)
    800034ea:	69e2                	ld	s3,24(sp)
    800034ec:	6121                	addi	sp,sp,64
    800034ee:	8082                	ret
      release(&tickslock);
    800034f0:	000d0517          	auipc	a0,0xd0
    800034f4:	be050513          	addi	a0,a0,-1056 # 800d30d0 <tickslock>
    800034f8:	ffffd097          	auipc	ra,0xffffd
    800034fc:	7a0080e7          	jalr	1952(ra) # 80000c98 <release>
      return -1;
    80003500:	57fd                	li	a5,-1
    80003502:	bff9                	j	800034e0 <sys_sleep+0x88>

0000000080003504 <sys_kill>:

uint64
sys_kill(void)
{
    80003504:	1101                	addi	sp,sp,-32
    80003506:	ec06                	sd	ra,24(sp)
    80003508:	e822                	sd	s0,16(sp)
    8000350a:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000350c:	fec40593          	addi	a1,s0,-20
    80003510:	4501                	li	a0,0
    80003512:	00000097          	auipc	ra,0x0
    80003516:	92e080e7          	jalr	-1746(ra) # 80002e40 <argint>
    8000351a:	87aa                	mv	a5,a0
    return -1;
    8000351c:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000351e:	0007c863          	bltz	a5,8000352e <sys_kill+0x2a>
  return kill(pid);
    80003522:	fec42503          	lw	a0,-20(s0)
    80003526:	fffff097          	auipc	ra,0xfffff
    8000352a:	222080e7          	jalr	546(ra) # 80002748 <kill>
}
    8000352e:	60e2                	ld	ra,24(sp)
    80003530:	6442                	ld	s0,16(sp)
    80003532:	6105                	addi	sp,sp,32
    80003534:	8082                	ret

0000000080003536 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003536:	1101                	addi	sp,sp,-32
    80003538:	ec06                	sd	ra,24(sp)
    8000353a:	e822                	sd	s0,16(sp)
    8000353c:	e426                	sd	s1,8(sp)
    8000353e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003540:	000d0517          	auipc	a0,0xd0
    80003544:	b9050513          	addi	a0,a0,-1136 # 800d30d0 <tickslock>
    80003548:	ffffd097          	auipc	ra,0xffffd
    8000354c:	69c080e7          	jalr	1692(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003550:	00006497          	auipc	s1,0x6
    80003554:	ae84a483          	lw	s1,-1304(s1) # 80009038 <ticks>
  release(&tickslock);
    80003558:	000d0517          	auipc	a0,0xd0
    8000355c:	b7850513          	addi	a0,a0,-1160 # 800d30d0 <tickslock>
    80003560:	ffffd097          	auipc	ra,0xffffd
    80003564:	738080e7          	jalr	1848(ra) # 80000c98 <release>
  return xticks;
}
    80003568:	02049513          	slli	a0,s1,0x20
    8000356c:	9101                	srli	a0,a0,0x20
    8000356e:	60e2                	ld	ra,24(sp)
    80003570:	6442                	ld	s0,16(sp)
    80003572:	64a2                	ld	s1,8(sp)
    80003574:	6105                	addi	sp,sp,32
    80003576:	8082                	ret

0000000080003578 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003578:	7179                	addi	sp,sp,-48
    8000357a:	f406                	sd	ra,40(sp)
    8000357c:	f022                	sd	s0,32(sp)
    8000357e:	ec26                	sd	s1,24(sp)
    80003580:	e84a                	sd	s2,16(sp)
    80003582:	e44e                	sd	s3,8(sp)
    80003584:	e052                	sd	s4,0(sp)
    80003586:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003588:	00005597          	auipc	a1,0x5
    8000358c:	13058593          	addi	a1,a1,304 # 800086b8 <syscalls+0xc0>
    80003590:	000d0517          	auipc	a0,0xd0
    80003594:	b5850513          	addi	a0,a0,-1192 # 800d30e8 <bcache>
    80003598:	ffffd097          	auipc	ra,0xffffd
    8000359c:	5bc080e7          	jalr	1468(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800035a0:	000d8797          	auipc	a5,0xd8
    800035a4:	b4878793          	addi	a5,a5,-1208 # 800db0e8 <bcache+0x8000>
    800035a8:	000d8717          	auipc	a4,0xd8
    800035ac:	da870713          	addi	a4,a4,-600 # 800db350 <bcache+0x8268>
    800035b0:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800035b4:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800035b8:	000d0497          	auipc	s1,0xd0
    800035bc:	b4848493          	addi	s1,s1,-1208 # 800d3100 <bcache+0x18>
    b->next = bcache.head.next;
    800035c0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800035c2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800035c4:	00005a17          	auipc	s4,0x5
    800035c8:	0fca0a13          	addi	s4,s4,252 # 800086c0 <syscalls+0xc8>
    b->next = bcache.head.next;
    800035cc:	2b893783          	ld	a5,696(s2)
    800035d0:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800035d2:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800035d6:	85d2                	mv	a1,s4
    800035d8:	01048513          	addi	a0,s1,16
    800035dc:	00001097          	auipc	ra,0x1
    800035e0:	4bc080e7          	jalr	1212(ra) # 80004a98 <initsleeplock>
    bcache.head.next->prev = b;
    800035e4:	2b893783          	ld	a5,696(s2)
    800035e8:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800035ea:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800035ee:	45848493          	addi	s1,s1,1112
    800035f2:	fd349de3          	bne	s1,s3,800035cc <binit+0x54>
  }
}
    800035f6:	70a2                	ld	ra,40(sp)
    800035f8:	7402                	ld	s0,32(sp)
    800035fa:	64e2                	ld	s1,24(sp)
    800035fc:	6942                	ld	s2,16(sp)
    800035fe:	69a2                	ld	s3,8(sp)
    80003600:	6a02                	ld	s4,0(sp)
    80003602:	6145                	addi	sp,sp,48
    80003604:	8082                	ret

0000000080003606 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003606:	7179                	addi	sp,sp,-48
    80003608:	f406                	sd	ra,40(sp)
    8000360a:	f022                	sd	s0,32(sp)
    8000360c:	ec26                	sd	s1,24(sp)
    8000360e:	e84a                	sd	s2,16(sp)
    80003610:	e44e                	sd	s3,8(sp)
    80003612:	1800                	addi	s0,sp,48
    80003614:	89aa                	mv	s3,a0
    80003616:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003618:	000d0517          	auipc	a0,0xd0
    8000361c:	ad050513          	addi	a0,a0,-1328 # 800d30e8 <bcache>
    80003620:	ffffd097          	auipc	ra,0xffffd
    80003624:	5c4080e7          	jalr	1476(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003628:	000d8497          	auipc	s1,0xd8
    8000362c:	d784b483          	ld	s1,-648(s1) # 800db3a0 <bcache+0x82b8>
    80003630:	000d8797          	auipc	a5,0xd8
    80003634:	d2078793          	addi	a5,a5,-736 # 800db350 <bcache+0x8268>
    80003638:	02f48f63          	beq	s1,a5,80003676 <bread+0x70>
    8000363c:	873e                	mv	a4,a5
    8000363e:	a021                	j	80003646 <bread+0x40>
    80003640:	68a4                	ld	s1,80(s1)
    80003642:	02e48a63          	beq	s1,a4,80003676 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003646:	449c                	lw	a5,8(s1)
    80003648:	ff379ce3          	bne	a5,s3,80003640 <bread+0x3a>
    8000364c:	44dc                	lw	a5,12(s1)
    8000364e:	ff2799e3          	bne	a5,s2,80003640 <bread+0x3a>
      b->refcnt++;
    80003652:	40bc                	lw	a5,64(s1)
    80003654:	2785                	addiw	a5,a5,1
    80003656:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003658:	000d0517          	auipc	a0,0xd0
    8000365c:	a9050513          	addi	a0,a0,-1392 # 800d30e8 <bcache>
    80003660:	ffffd097          	auipc	ra,0xffffd
    80003664:	638080e7          	jalr	1592(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003668:	01048513          	addi	a0,s1,16
    8000366c:	00001097          	auipc	ra,0x1
    80003670:	466080e7          	jalr	1126(ra) # 80004ad2 <acquiresleep>
      return b;
    80003674:	a8b9                	j	800036d2 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003676:	000d8497          	auipc	s1,0xd8
    8000367a:	d224b483          	ld	s1,-734(s1) # 800db398 <bcache+0x82b0>
    8000367e:	000d8797          	auipc	a5,0xd8
    80003682:	cd278793          	addi	a5,a5,-814 # 800db350 <bcache+0x8268>
    80003686:	00f48863          	beq	s1,a5,80003696 <bread+0x90>
    8000368a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000368c:	40bc                	lw	a5,64(s1)
    8000368e:	cf81                	beqz	a5,800036a6 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003690:	64a4                	ld	s1,72(s1)
    80003692:	fee49de3          	bne	s1,a4,8000368c <bread+0x86>
  panic("bget: no buffers");
    80003696:	00005517          	auipc	a0,0x5
    8000369a:	03250513          	addi	a0,a0,50 # 800086c8 <syscalls+0xd0>
    8000369e:	ffffd097          	auipc	ra,0xffffd
    800036a2:	ea0080e7          	jalr	-352(ra) # 8000053e <panic>
      b->dev = dev;
    800036a6:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800036aa:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800036ae:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800036b2:	4785                	li	a5,1
    800036b4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800036b6:	000d0517          	auipc	a0,0xd0
    800036ba:	a3250513          	addi	a0,a0,-1486 # 800d30e8 <bcache>
    800036be:	ffffd097          	auipc	ra,0xffffd
    800036c2:	5da080e7          	jalr	1498(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800036c6:	01048513          	addi	a0,s1,16
    800036ca:	00001097          	auipc	ra,0x1
    800036ce:	408080e7          	jalr	1032(ra) # 80004ad2 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800036d2:	409c                	lw	a5,0(s1)
    800036d4:	cb89                	beqz	a5,800036e6 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800036d6:	8526                	mv	a0,s1
    800036d8:	70a2                	ld	ra,40(sp)
    800036da:	7402                	ld	s0,32(sp)
    800036dc:	64e2                	ld	s1,24(sp)
    800036de:	6942                	ld	s2,16(sp)
    800036e0:	69a2                	ld	s3,8(sp)
    800036e2:	6145                	addi	sp,sp,48
    800036e4:	8082                	ret
    virtio_disk_rw(b, 0);
    800036e6:	4581                	li	a1,0
    800036e8:	8526                	mv	a0,s1
    800036ea:	00003097          	auipc	ra,0x3
    800036ee:	f0c080e7          	jalr	-244(ra) # 800065f6 <virtio_disk_rw>
    b->valid = 1;
    800036f2:	4785                	li	a5,1
    800036f4:	c09c                	sw	a5,0(s1)
  return b;
    800036f6:	b7c5                	j	800036d6 <bread+0xd0>

00000000800036f8 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800036f8:	1101                	addi	sp,sp,-32
    800036fa:	ec06                	sd	ra,24(sp)
    800036fc:	e822                	sd	s0,16(sp)
    800036fe:	e426                	sd	s1,8(sp)
    80003700:	1000                	addi	s0,sp,32
    80003702:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003704:	0541                	addi	a0,a0,16
    80003706:	00001097          	auipc	ra,0x1
    8000370a:	466080e7          	jalr	1126(ra) # 80004b6c <holdingsleep>
    8000370e:	cd01                	beqz	a0,80003726 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003710:	4585                	li	a1,1
    80003712:	8526                	mv	a0,s1
    80003714:	00003097          	auipc	ra,0x3
    80003718:	ee2080e7          	jalr	-286(ra) # 800065f6 <virtio_disk_rw>
}
    8000371c:	60e2                	ld	ra,24(sp)
    8000371e:	6442                	ld	s0,16(sp)
    80003720:	64a2                	ld	s1,8(sp)
    80003722:	6105                	addi	sp,sp,32
    80003724:	8082                	ret
    panic("bwrite");
    80003726:	00005517          	auipc	a0,0x5
    8000372a:	fba50513          	addi	a0,a0,-70 # 800086e0 <syscalls+0xe8>
    8000372e:	ffffd097          	auipc	ra,0xffffd
    80003732:	e10080e7          	jalr	-496(ra) # 8000053e <panic>

0000000080003736 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003736:	1101                	addi	sp,sp,-32
    80003738:	ec06                	sd	ra,24(sp)
    8000373a:	e822                	sd	s0,16(sp)
    8000373c:	e426                	sd	s1,8(sp)
    8000373e:	e04a                	sd	s2,0(sp)
    80003740:	1000                	addi	s0,sp,32
    80003742:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003744:	01050913          	addi	s2,a0,16
    80003748:	854a                	mv	a0,s2
    8000374a:	00001097          	auipc	ra,0x1
    8000374e:	422080e7          	jalr	1058(ra) # 80004b6c <holdingsleep>
    80003752:	c92d                	beqz	a0,800037c4 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003754:	854a                	mv	a0,s2
    80003756:	00001097          	auipc	ra,0x1
    8000375a:	3d2080e7          	jalr	978(ra) # 80004b28 <releasesleep>

  acquire(&bcache.lock);
    8000375e:	000d0517          	auipc	a0,0xd0
    80003762:	98a50513          	addi	a0,a0,-1654 # 800d30e8 <bcache>
    80003766:	ffffd097          	auipc	ra,0xffffd
    8000376a:	47e080e7          	jalr	1150(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000376e:	40bc                	lw	a5,64(s1)
    80003770:	37fd                	addiw	a5,a5,-1
    80003772:	0007871b          	sext.w	a4,a5
    80003776:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003778:	eb05                	bnez	a4,800037a8 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000377a:	68bc                	ld	a5,80(s1)
    8000377c:	64b8                	ld	a4,72(s1)
    8000377e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003780:	64bc                	ld	a5,72(s1)
    80003782:	68b8                	ld	a4,80(s1)
    80003784:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003786:	000d8797          	auipc	a5,0xd8
    8000378a:	96278793          	addi	a5,a5,-1694 # 800db0e8 <bcache+0x8000>
    8000378e:	2b87b703          	ld	a4,696(a5)
    80003792:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003794:	000d8717          	auipc	a4,0xd8
    80003798:	bbc70713          	addi	a4,a4,-1092 # 800db350 <bcache+0x8268>
    8000379c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000379e:	2b87b703          	ld	a4,696(a5)
    800037a2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800037a4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800037a8:	000d0517          	auipc	a0,0xd0
    800037ac:	94050513          	addi	a0,a0,-1728 # 800d30e8 <bcache>
    800037b0:	ffffd097          	auipc	ra,0xffffd
    800037b4:	4e8080e7          	jalr	1256(ra) # 80000c98 <release>
}
    800037b8:	60e2                	ld	ra,24(sp)
    800037ba:	6442                	ld	s0,16(sp)
    800037bc:	64a2                	ld	s1,8(sp)
    800037be:	6902                	ld	s2,0(sp)
    800037c0:	6105                	addi	sp,sp,32
    800037c2:	8082                	ret
    panic("brelse");
    800037c4:	00005517          	auipc	a0,0x5
    800037c8:	f2450513          	addi	a0,a0,-220 # 800086e8 <syscalls+0xf0>
    800037cc:	ffffd097          	auipc	ra,0xffffd
    800037d0:	d72080e7          	jalr	-654(ra) # 8000053e <panic>

00000000800037d4 <bpin>:

void
bpin(struct buf *b) {
    800037d4:	1101                	addi	sp,sp,-32
    800037d6:	ec06                	sd	ra,24(sp)
    800037d8:	e822                	sd	s0,16(sp)
    800037da:	e426                	sd	s1,8(sp)
    800037dc:	1000                	addi	s0,sp,32
    800037de:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037e0:	000d0517          	auipc	a0,0xd0
    800037e4:	90850513          	addi	a0,a0,-1784 # 800d30e8 <bcache>
    800037e8:	ffffd097          	auipc	ra,0xffffd
    800037ec:	3fc080e7          	jalr	1020(ra) # 80000be4 <acquire>
  b->refcnt++;
    800037f0:	40bc                	lw	a5,64(s1)
    800037f2:	2785                	addiw	a5,a5,1
    800037f4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800037f6:	000d0517          	auipc	a0,0xd0
    800037fa:	8f250513          	addi	a0,a0,-1806 # 800d30e8 <bcache>
    800037fe:	ffffd097          	auipc	ra,0xffffd
    80003802:	49a080e7          	jalr	1178(ra) # 80000c98 <release>
}
    80003806:	60e2                	ld	ra,24(sp)
    80003808:	6442                	ld	s0,16(sp)
    8000380a:	64a2                	ld	s1,8(sp)
    8000380c:	6105                	addi	sp,sp,32
    8000380e:	8082                	ret

0000000080003810 <bunpin>:

void
bunpin(struct buf *b) {
    80003810:	1101                	addi	sp,sp,-32
    80003812:	ec06                	sd	ra,24(sp)
    80003814:	e822                	sd	s0,16(sp)
    80003816:	e426                	sd	s1,8(sp)
    80003818:	1000                	addi	s0,sp,32
    8000381a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000381c:	000d0517          	auipc	a0,0xd0
    80003820:	8cc50513          	addi	a0,a0,-1844 # 800d30e8 <bcache>
    80003824:	ffffd097          	auipc	ra,0xffffd
    80003828:	3c0080e7          	jalr	960(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000382c:	40bc                	lw	a5,64(s1)
    8000382e:	37fd                	addiw	a5,a5,-1
    80003830:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003832:	000d0517          	auipc	a0,0xd0
    80003836:	8b650513          	addi	a0,a0,-1866 # 800d30e8 <bcache>
    8000383a:	ffffd097          	auipc	ra,0xffffd
    8000383e:	45e080e7          	jalr	1118(ra) # 80000c98 <release>
}
    80003842:	60e2                	ld	ra,24(sp)
    80003844:	6442                	ld	s0,16(sp)
    80003846:	64a2                	ld	s1,8(sp)
    80003848:	6105                	addi	sp,sp,32
    8000384a:	8082                	ret

000000008000384c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000384c:	1101                	addi	sp,sp,-32
    8000384e:	ec06                	sd	ra,24(sp)
    80003850:	e822                	sd	s0,16(sp)
    80003852:	e426                	sd	s1,8(sp)
    80003854:	e04a                	sd	s2,0(sp)
    80003856:	1000                	addi	s0,sp,32
    80003858:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000385a:	00d5d59b          	srliw	a1,a1,0xd
    8000385e:	000d8797          	auipc	a5,0xd8
    80003862:	f667a783          	lw	a5,-154(a5) # 800db7c4 <sb+0x1c>
    80003866:	9dbd                	addw	a1,a1,a5
    80003868:	00000097          	auipc	ra,0x0
    8000386c:	d9e080e7          	jalr	-610(ra) # 80003606 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003870:	0074f713          	andi	a4,s1,7
    80003874:	4785                	li	a5,1
    80003876:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000387a:	14ce                	slli	s1,s1,0x33
    8000387c:	90d9                	srli	s1,s1,0x36
    8000387e:	00950733          	add	a4,a0,s1
    80003882:	05874703          	lbu	a4,88(a4)
    80003886:	00e7f6b3          	and	a3,a5,a4
    8000388a:	c69d                	beqz	a3,800038b8 <bfree+0x6c>
    8000388c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000388e:	94aa                	add	s1,s1,a0
    80003890:	fff7c793          	not	a5,a5
    80003894:	8ff9                	and	a5,a5,a4
    80003896:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000389a:	00001097          	auipc	ra,0x1
    8000389e:	118080e7          	jalr	280(ra) # 800049b2 <log_write>
  brelse(bp);
    800038a2:	854a                	mv	a0,s2
    800038a4:	00000097          	auipc	ra,0x0
    800038a8:	e92080e7          	jalr	-366(ra) # 80003736 <brelse>
}
    800038ac:	60e2                	ld	ra,24(sp)
    800038ae:	6442                	ld	s0,16(sp)
    800038b0:	64a2                	ld	s1,8(sp)
    800038b2:	6902                	ld	s2,0(sp)
    800038b4:	6105                	addi	sp,sp,32
    800038b6:	8082                	ret
    panic("freeing free block");
    800038b8:	00005517          	auipc	a0,0x5
    800038bc:	e3850513          	addi	a0,a0,-456 # 800086f0 <syscalls+0xf8>
    800038c0:	ffffd097          	auipc	ra,0xffffd
    800038c4:	c7e080e7          	jalr	-898(ra) # 8000053e <panic>

00000000800038c8 <balloc>:
{
    800038c8:	711d                	addi	sp,sp,-96
    800038ca:	ec86                	sd	ra,88(sp)
    800038cc:	e8a2                	sd	s0,80(sp)
    800038ce:	e4a6                	sd	s1,72(sp)
    800038d0:	e0ca                	sd	s2,64(sp)
    800038d2:	fc4e                	sd	s3,56(sp)
    800038d4:	f852                	sd	s4,48(sp)
    800038d6:	f456                	sd	s5,40(sp)
    800038d8:	f05a                	sd	s6,32(sp)
    800038da:	ec5e                	sd	s7,24(sp)
    800038dc:	e862                	sd	s8,16(sp)
    800038de:	e466                	sd	s9,8(sp)
    800038e0:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800038e2:	000d8797          	auipc	a5,0xd8
    800038e6:	eca7a783          	lw	a5,-310(a5) # 800db7ac <sb+0x4>
    800038ea:	cbd1                	beqz	a5,8000397e <balloc+0xb6>
    800038ec:	8baa                	mv	s7,a0
    800038ee:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800038f0:	000d8b17          	auipc	s6,0xd8
    800038f4:	eb8b0b13          	addi	s6,s6,-328 # 800db7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038f8:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800038fa:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038fc:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800038fe:	6c89                	lui	s9,0x2
    80003900:	a831                	j	8000391c <balloc+0x54>
    brelse(bp);
    80003902:	854a                	mv	a0,s2
    80003904:	00000097          	auipc	ra,0x0
    80003908:	e32080e7          	jalr	-462(ra) # 80003736 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000390c:	015c87bb          	addw	a5,s9,s5
    80003910:	00078a9b          	sext.w	s5,a5
    80003914:	004b2703          	lw	a4,4(s6)
    80003918:	06eaf363          	bgeu	s5,a4,8000397e <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000391c:	41fad79b          	sraiw	a5,s5,0x1f
    80003920:	0137d79b          	srliw	a5,a5,0x13
    80003924:	015787bb          	addw	a5,a5,s5
    80003928:	40d7d79b          	sraiw	a5,a5,0xd
    8000392c:	01cb2583          	lw	a1,28(s6)
    80003930:	9dbd                	addw	a1,a1,a5
    80003932:	855e                	mv	a0,s7
    80003934:	00000097          	auipc	ra,0x0
    80003938:	cd2080e7          	jalr	-814(ra) # 80003606 <bread>
    8000393c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000393e:	004b2503          	lw	a0,4(s6)
    80003942:	000a849b          	sext.w	s1,s5
    80003946:	8662                	mv	a2,s8
    80003948:	faa4fde3          	bgeu	s1,a0,80003902 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000394c:	41f6579b          	sraiw	a5,a2,0x1f
    80003950:	01d7d69b          	srliw	a3,a5,0x1d
    80003954:	00c6873b          	addw	a4,a3,a2
    80003958:	00777793          	andi	a5,a4,7
    8000395c:	9f95                	subw	a5,a5,a3
    8000395e:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003962:	4037571b          	sraiw	a4,a4,0x3
    80003966:	00e906b3          	add	a3,s2,a4
    8000396a:	0586c683          	lbu	a3,88(a3)
    8000396e:	00d7f5b3          	and	a1,a5,a3
    80003972:	cd91                	beqz	a1,8000398e <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003974:	2605                	addiw	a2,a2,1
    80003976:	2485                	addiw	s1,s1,1
    80003978:	fd4618e3          	bne	a2,s4,80003948 <balloc+0x80>
    8000397c:	b759                	j	80003902 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000397e:	00005517          	auipc	a0,0x5
    80003982:	d8a50513          	addi	a0,a0,-630 # 80008708 <syscalls+0x110>
    80003986:	ffffd097          	auipc	ra,0xffffd
    8000398a:	bb8080e7          	jalr	-1096(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000398e:	974a                	add	a4,a4,s2
    80003990:	8fd5                	or	a5,a5,a3
    80003992:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003996:	854a                	mv	a0,s2
    80003998:	00001097          	auipc	ra,0x1
    8000399c:	01a080e7          	jalr	26(ra) # 800049b2 <log_write>
        brelse(bp);
    800039a0:	854a                	mv	a0,s2
    800039a2:	00000097          	auipc	ra,0x0
    800039a6:	d94080e7          	jalr	-620(ra) # 80003736 <brelse>
  bp = bread(dev, bno);
    800039aa:	85a6                	mv	a1,s1
    800039ac:	855e                	mv	a0,s7
    800039ae:	00000097          	auipc	ra,0x0
    800039b2:	c58080e7          	jalr	-936(ra) # 80003606 <bread>
    800039b6:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800039b8:	40000613          	li	a2,1024
    800039bc:	4581                	li	a1,0
    800039be:	05850513          	addi	a0,a0,88
    800039c2:	ffffd097          	auipc	ra,0xffffd
    800039c6:	31e080e7          	jalr	798(ra) # 80000ce0 <memset>
  log_write(bp);
    800039ca:	854a                	mv	a0,s2
    800039cc:	00001097          	auipc	ra,0x1
    800039d0:	fe6080e7          	jalr	-26(ra) # 800049b2 <log_write>
  brelse(bp);
    800039d4:	854a                	mv	a0,s2
    800039d6:	00000097          	auipc	ra,0x0
    800039da:	d60080e7          	jalr	-672(ra) # 80003736 <brelse>
}
    800039de:	8526                	mv	a0,s1
    800039e0:	60e6                	ld	ra,88(sp)
    800039e2:	6446                	ld	s0,80(sp)
    800039e4:	64a6                	ld	s1,72(sp)
    800039e6:	6906                	ld	s2,64(sp)
    800039e8:	79e2                	ld	s3,56(sp)
    800039ea:	7a42                	ld	s4,48(sp)
    800039ec:	7aa2                	ld	s5,40(sp)
    800039ee:	7b02                	ld	s6,32(sp)
    800039f0:	6be2                	ld	s7,24(sp)
    800039f2:	6c42                	ld	s8,16(sp)
    800039f4:	6ca2                	ld	s9,8(sp)
    800039f6:	6125                	addi	sp,sp,96
    800039f8:	8082                	ret

00000000800039fa <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800039fa:	7179                	addi	sp,sp,-48
    800039fc:	f406                	sd	ra,40(sp)
    800039fe:	f022                	sd	s0,32(sp)
    80003a00:	ec26                	sd	s1,24(sp)
    80003a02:	e84a                	sd	s2,16(sp)
    80003a04:	e44e                	sd	s3,8(sp)
    80003a06:	e052                	sd	s4,0(sp)
    80003a08:	1800                	addi	s0,sp,48
    80003a0a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003a0c:	47ad                	li	a5,11
    80003a0e:	04b7fe63          	bgeu	a5,a1,80003a6a <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003a12:	ff45849b          	addiw	s1,a1,-12
    80003a16:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003a1a:	0ff00793          	li	a5,255
    80003a1e:	0ae7e363          	bltu	a5,a4,80003ac4 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003a22:	08052583          	lw	a1,128(a0)
    80003a26:	c5ad                	beqz	a1,80003a90 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003a28:	00092503          	lw	a0,0(s2)
    80003a2c:	00000097          	auipc	ra,0x0
    80003a30:	bda080e7          	jalr	-1062(ra) # 80003606 <bread>
    80003a34:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003a36:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003a3a:	02049593          	slli	a1,s1,0x20
    80003a3e:	9181                	srli	a1,a1,0x20
    80003a40:	058a                	slli	a1,a1,0x2
    80003a42:	00b784b3          	add	s1,a5,a1
    80003a46:	0004a983          	lw	s3,0(s1)
    80003a4a:	04098d63          	beqz	s3,80003aa4 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003a4e:	8552                	mv	a0,s4
    80003a50:	00000097          	auipc	ra,0x0
    80003a54:	ce6080e7          	jalr	-794(ra) # 80003736 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003a58:	854e                	mv	a0,s3
    80003a5a:	70a2                	ld	ra,40(sp)
    80003a5c:	7402                	ld	s0,32(sp)
    80003a5e:	64e2                	ld	s1,24(sp)
    80003a60:	6942                	ld	s2,16(sp)
    80003a62:	69a2                	ld	s3,8(sp)
    80003a64:	6a02                	ld	s4,0(sp)
    80003a66:	6145                	addi	sp,sp,48
    80003a68:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003a6a:	02059493          	slli	s1,a1,0x20
    80003a6e:	9081                	srli	s1,s1,0x20
    80003a70:	048a                	slli	s1,s1,0x2
    80003a72:	94aa                	add	s1,s1,a0
    80003a74:	0504a983          	lw	s3,80(s1)
    80003a78:	fe0990e3          	bnez	s3,80003a58 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003a7c:	4108                	lw	a0,0(a0)
    80003a7e:	00000097          	auipc	ra,0x0
    80003a82:	e4a080e7          	jalr	-438(ra) # 800038c8 <balloc>
    80003a86:	0005099b          	sext.w	s3,a0
    80003a8a:	0534a823          	sw	s3,80(s1)
    80003a8e:	b7e9                	j	80003a58 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003a90:	4108                	lw	a0,0(a0)
    80003a92:	00000097          	auipc	ra,0x0
    80003a96:	e36080e7          	jalr	-458(ra) # 800038c8 <balloc>
    80003a9a:	0005059b          	sext.w	a1,a0
    80003a9e:	08b92023          	sw	a1,128(s2)
    80003aa2:	b759                	j	80003a28 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003aa4:	00092503          	lw	a0,0(s2)
    80003aa8:	00000097          	auipc	ra,0x0
    80003aac:	e20080e7          	jalr	-480(ra) # 800038c8 <balloc>
    80003ab0:	0005099b          	sext.w	s3,a0
    80003ab4:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003ab8:	8552                	mv	a0,s4
    80003aba:	00001097          	auipc	ra,0x1
    80003abe:	ef8080e7          	jalr	-264(ra) # 800049b2 <log_write>
    80003ac2:	b771                	j	80003a4e <bmap+0x54>
  panic("bmap: out of range");
    80003ac4:	00005517          	auipc	a0,0x5
    80003ac8:	c5c50513          	addi	a0,a0,-932 # 80008720 <syscalls+0x128>
    80003acc:	ffffd097          	auipc	ra,0xffffd
    80003ad0:	a72080e7          	jalr	-1422(ra) # 8000053e <panic>

0000000080003ad4 <iget>:
{
    80003ad4:	7179                	addi	sp,sp,-48
    80003ad6:	f406                	sd	ra,40(sp)
    80003ad8:	f022                	sd	s0,32(sp)
    80003ada:	ec26                	sd	s1,24(sp)
    80003adc:	e84a                	sd	s2,16(sp)
    80003ade:	e44e                	sd	s3,8(sp)
    80003ae0:	e052                	sd	s4,0(sp)
    80003ae2:	1800                	addi	s0,sp,48
    80003ae4:	89aa                	mv	s3,a0
    80003ae6:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003ae8:	000d8517          	auipc	a0,0xd8
    80003aec:	ce050513          	addi	a0,a0,-800 # 800db7c8 <itable>
    80003af0:	ffffd097          	auipc	ra,0xffffd
    80003af4:	0f4080e7          	jalr	244(ra) # 80000be4 <acquire>
  empty = 0;
    80003af8:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003afa:	000d8497          	auipc	s1,0xd8
    80003afe:	ce648493          	addi	s1,s1,-794 # 800db7e0 <itable+0x18>
    80003b02:	000d9697          	auipc	a3,0xd9
    80003b06:	76e68693          	addi	a3,a3,1902 # 800dd270 <log>
    80003b0a:	a039                	j	80003b18 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b0c:	02090b63          	beqz	s2,80003b42 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b10:	08848493          	addi	s1,s1,136
    80003b14:	02d48a63          	beq	s1,a3,80003b48 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003b18:	449c                	lw	a5,8(s1)
    80003b1a:	fef059e3          	blez	a5,80003b0c <iget+0x38>
    80003b1e:	4098                	lw	a4,0(s1)
    80003b20:	ff3716e3          	bne	a4,s3,80003b0c <iget+0x38>
    80003b24:	40d8                	lw	a4,4(s1)
    80003b26:	ff4713e3          	bne	a4,s4,80003b0c <iget+0x38>
      ip->ref++;
    80003b2a:	2785                	addiw	a5,a5,1
    80003b2c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003b2e:	000d8517          	auipc	a0,0xd8
    80003b32:	c9a50513          	addi	a0,a0,-870 # 800db7c8 <itable>
    80003b36:	ffffd097          	auipc	ra,0xffffd
    80003b3a:	162080e7          	jalr	354(ra) # 80000c98 <release>
      return ip;
    80003b3e:	8926                	mv	s2,s1
    80003b40:	a03d                	j	80003b6e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b42:	f7f9                	bnez	a5,80003b10 <iget+0x3c>
    80003b44:	8926                	mv	s2,s1
    80003b46:	b7e9                	j	80003b10 <iget+0x3c>
  if(empty == 0)
    80003b48:	02090c63          	beqz	s2,80003b80 <iget+0xac>
  ip->dev = dev;
    80003b4c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003b50:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003b54:	4785                	li	a5,1
    80003b56:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003b5a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003b5e:	000d8517          	auipc	a0,0xd8
    80003b62:	c6a50513          	addi	a0,a0,-918 # 800db7c8 <itable>
    80003b66:	ffffd097          	auipc	ra,0xffffd
    80003b6a:	132080e7          	jalr	306(ra) # 80000c98 <release>
}
    80003b6e:	854a                	mv	a0,s2
    80003b70:	70a2                	ld	ra,40(sp)
    80003b72:	7402                	ld	s0,32(sp)
    80003b74:	64e2                	ld	s1,24(sp)
    80003b76:	6942                	ld	s2,16(sp)
    80003b78:	69a2                	ld	s3,8(sp)
    80003b7a:	6a02                	ld	s4,0(sp)
    80003b7c:	6145                	addi	sp,sp,48
    80003b7e:	8082                	ret
    panic("iget: no inodes");
    80003b80:	00005517          	auipc	a0,0x5
    80003b84:	bb850513          	addi	a0,a0,-1096 # 80008738 <syscalls+0x140>
    80003b88:	ffffd097          	auipc	ra,0xffffd
    80003b8c:	9b6080e7          	jalr	-1610(ra) # 8000053e <panic>

0000000080003b90 <fsinit>:
fsinit(int dev) {
    80003b90:	7179                	addi	sp,sp,-48
    80003b92:	f406                	sd	ra,40(sp)
    80003b94:	f022                	sd	s0,32(sp)
    80003b96:	ec26                	sd	s1,24(sp)
    80003b98:	e84a                	sd	s2,16(sp)
    80003b9a:	e44e                	sd	s3,8(sp)
    80003b9c:	1800                	addi	s0,sp,48
    80003b9e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003ba0:	4585                	li	a1,1
    80003ba2:	00000097          	auipc	ra,0x0
    80003ba6:	a64080e7          	jalr	-1436(ra) # 80003606 <bread>
    80003baa:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003bac:	000d8997          	auipc	s3,0xd8
    80003bb0:	bfc98993          	addi	s3,s3,-1028 # 800db7a8 <sb>
    80003bb4:	02000613          	li	a2,32
    80003bb8:	05850593          	addi	a1,a0,88
    80003bbc:	854e                	mv	a0,s3
    80003bbe:	ffffd097          	auipc	ra,0xffffd
    80003bc2:	182080e7          	jalr	386(ra) # 80000d40 <memmove>
  brelse(bp);
    80003bc6:	8526                	mv	a0,s1
    80003bc8:	00000097          	auipc	ra,0x0
    80003bcc:	b6e080e7          	jalr	-1170(ra) # 80003736 <brelse>
  if(sb.magic != FSMAGIC)
    80003bd0:	0009a703          	lw	a4,0(s3)
    80003bd4:	102037b7          	lui	a5,0x10203
    80003bd8:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003bdc:	02f71263          	bne	a4,a5,80003c00 <fsinit+0x70>
  initlog(dev, &sb);
    80003be0:	000d8597          	auipc	a1,0xd8
    80003be4:	bc858593          	addi	a1,a1,-1080 # 800db7a8 <sb>
    80003be8:	854a                	mv	a0,s2
    80003bea:	00001097          	auipc	ra,0x1
    80003bee:	b4c080e7          	jalr	-1204(ra) # 80004736 <initlog>
}
    80003bf2:	70a2                	ld	ra,40(sp)
    80003bf4:	7402                	ld	s0,32(sp)
    80003bf6:	64e2                	ld	s1,24(sp)
    80003bf8:	6942                	ld	s2,16(sp)
    80003bfa:	69a2                	ld	s3,8(sp)
    80003bfc:	6145                	addi	sp,sp,48
    80003bfe:	8082                	ret
    panic("invalid file system");
    80003c00:	00005517          	auipc	a0,0x5
    80003c04:	b4850513          	addi	a0,a0,-1208 # 80008748 <syscalls+0x150>
    80003c08:	ffffd097          	auipc	ra,0xffffd
    80003c0c:	936080e7          	jalr	-1738(ra) # 8000053e <panic>

0000000080003c10 <iinit>:
{
    80003c10:	7179                	addi	sp,sp,-48
    80003c12:	f406                	sd	ra,40(sp)
    80003c14:	f022                	sd	s0,32(sp)
    80003c16:	ec26                	sd	s1,24(sp)
    80003c18:	e84a                	sd	s2,16(sp)
    80003c1a:	e44e                	sd	s3,8(sp)
    80003c1c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003c1e:	00005597          	auipc	a1,0x5
    80003c22:	b4258593          	addi	a1,a1,-1214 # 80008760 <syscalls+0x168>
    80003c26:	000d8517          	auipc	a0,0xd8
    80003c2a:	ba250513          	addi	a0,a0,-1118 # 800db7c8 <itable>
    80003c2e:	ffffd097          	auipc	ra,0xffffd
    80003c32:	f26080e7          	jalr	-218(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003c36:	000d8497          	auipc	s1,0xd8
    80003c3a:	bba48493          	addi	s1,s1,-1094 # 800db7f0 <itable+0x28>
    80003c3e:	000d9997          	auipc	s3,0xd9
    80003c42:	64298993          	addi	s3,s3,1602 # 800dd280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003c46:	00005917          	auipc	s2,0x5
    80003c4a:	b2290913          	addi	s2,s2,-1246 # 80008768 <syscalls+0x170>
    80003c4e:	85ca                	mv	a1,s2
    80003c50:	8526                	mv	a0,s1
    80003c52:	00001097          	auipc	ra,0x1
    80003c56:	e46080e7          	jalr	-442(ra) # 80004a98 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003c5a:	08848493          	addi	s1,s1,136
    80003c5e:	ff3498e3          	bne	s1,s3,80003c4e <iinit+0x3e>
}
    80003c62:	70a2                	ld	ra,40(sp)
    80003c64:	7402                	ld	s0,32(sp)
    80003c66:	64e2                	ld	s1,24(sp)
    80003c68:	6942                	ld	s2,16(sp)
    80003c6a:	69a2                	ld	s3,8(sp)
    80003c6c:	6145                	addi	sp,sp,48
    80003c6e:	8082                	ret

0000000080003c70 <ialloc>:
{
    80003c70:	715d                	addi	sp,sp,-80
    80003c72:	e486                	sd	ra,72(sp)
    80003c74:	e0a2                	sd	s0,64(sp)
    80003c76:	fc26                	sd	s1,56(sp)
    80003c78:	f84a                	sd	s2,48(sp)
    80003c7a:	f44e                	sd	s3,40(sp)
    80003c7c:	f052                	sd	s4,32(sp)
    80003c7e:	ec56                	sd	s5,24(sp)
    80003c80:	e85a                	sd	s6,16(sp)
    80003c82:	e45e                	sd	s7,8(sp)
    80003c84:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c86:	000d8717          	auipc	a4,0xd8
    80003c8a:	b2e72703          	lw	a4,-1234(a4) # 800db7b4 <sb+0xc>
    80003c8e:	4785                	li	a5,1
    80003c90:	04e7fa63          	bgeu	a5,a4,80003ce4 <ialloc+0x74>
    80003c94:	8aaa                	mv	s5,a0
    80003c96:	8bae                	mv	s7,a1
    80003c98:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003c9a:	000d8a17          	auipc	s4,0xd8
    80003c9e:	b0ea0a13          	addi	s4,s4,-1266 # 800db7a8 <sb>
    80003ca2:	00048b1b          	sext.w	s6,s1
    80003ca6:	0044d593          	srli	a1,s1,0x4
    80003caa:	018a2783          	lw	a5,24(s4)
    80003cae:	9dbd                	addw	a1,a1,a5
    80003cb0:	8556                	mv	a0,s5
    80003cb2:	00000097          	auipc	ra,0x0
    80003cb6:	954080e7          	jalr	-1708(ra) # 80003606 <bread>
    80003cba:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003cbc:	05850993          	addi	s3,a0,88
    80003cc0:	00f4f793          	andi	a5,s1,15
    80003cc4:	079a                	slli	a5,a5,0x6
    80003cc6:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003cc8:	00099783          	lh	a5,0(s3)
    80003ccc:	c785                	beqz	a5,80003cf4 <ialloc+0x84>
    brelse(bp);
    80003cce:	00000097          	auipc	ra,0x0
    80003cd2:	a68080e7          	jalr	-1432(ra) # 80003736 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003cd6:	0485                	addi	s1,s1,1
    80003cd8:	00ca2703          	lw	a4,12(s4)
    80003cdc:	0004879b          	sext.w	a5,s1
    80003ce0:	fce7e1e3          	bltu	a5,a4,80003ca2 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003ce4:	00005517          	auipc	a0,0x5
    80003ce8:	a8c50513          	addi	a0,a0,-1396 # 80008770 <syscalls+0x178>
    80003cec:	ffffd097          	auipc	ra,0xffffd
    80003cf0:	852080e7          	jalr	-1966(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003cf4:	04000613          	li	a2,64
    80003cf8:	4581                	li	a1,0
    80003cfa:	854e                	mv	a0,s3
    80003cfc:	ffffd097          	auipc	ra,0xffffd
    80003d00:	fe4080e7          	jalr	-28(ra) # 80000ce0 <memset>
      dip->type = type;
    80003d04:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003d08:	854a                	mv	a0,s2
    80003d0a:	00001097          	auipc	ra,0x1
    80003d0e:	ca8080e7          	jalr	-856(ra) # 800049b2 <log_write>
      brelse(bp);
    80003d12:	854a                	mv	a0,s2
    80003d14:	00000097          	auipc	ra,0x0
    80003d18:	a22080e7          	jalr	-1502(ra) # 80003736 <brelse>
      return iget(dev, inum);
    80003d1c:	85da                	mv	a1,s6
    80003d1e:	8556                	mv	a0,s5
    80003d20:	00000097          	auipc	ra,0x0
    80003d24:	db4080e7          	jalr	-588(ra) # 80003ad4 <iget>
}
    80003d28:	60a6                	ld	ra,72(sp)
    80003d2a:	6406                	ld	s0,64(sp)
    80003d2c:	74e2                	ld	s1,56(sp)
    80003d2e:	7942                	ld	s2,48(sp)
    80003d30:	79a2                	ld	s3,40(sp)
    80003d32:	7a02                	ld	s4,32(sp)
    80003d34:	6ae2                	ld	s5,24(sp)
    80003d36:	6b42                	ld	s6,16(sp)
    80003d38:	6ba2                	ld	s7,8(sp)
    80003d3a:	6161                	addi	sp,sp,80
    80003d3c:	8082                	ret

0000000080003d3e <iupdate>:
{
    80003d3e:	1101                	addi	sp,sp,-32
    80003d40:	ec06                	sd	ra,24(sp)
    80003d42:	e822                	sd	s0,16(sp)
    80003d44:	e426                	sd	s1,8(sp)
    80003d46:	e04a                	sd	s2,0(sp)
    80003d48:	1000                	addi	s0,sp,32
    80003d4a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d4c:	415c                	lw	a5,4(a0)
    80003d4e:	0047d79b          	srliw	a5,a5,0x4
    80003d52:	000d8597          	auipc	a1,0xd8
    80003d56:	a6e5a583          	lw	a1,-1426(a1) # 800db7c0 <sb+0x18>
    80003d5a:	9dbd                	addw	a1,a1,a5
    80003d5c:	4108                	lw	a0,0(a0)
    80003d5e:	00000097          	auipc	ra,0x0
    80003d62:	8a8080e7          	jalr	-1880(ra) # 80003606 <bread>
    80003d66:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d68:	05850793          	addi	a5,a0,88
    80003d6c:	40c8                	lw	a0,4(s1)
    80003d6e:	893d                	andi	a0,a0,15
    80003d70:	051a                	slli	a0,a0,0x6
    80003d72:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003d74:	04449703          	lh	a4,68(s1)
    80003d78:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003d7c:	04649703          	lh	a4,70(s1)
    80003d80:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003d84:	04849703          	lh	a4,72(s1)
    80003d88:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003d8c:	04a49703          	lh	a4,74(s1)
    80003d90:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003d94:	44f8                	lw	a4,76(s1)
    80003d96:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003d98:	03400613          	li	a2,52
    80003d9c:	05048593          	addi	a1,s1,80
    80003da0:	0531                	addi	a0,a0,12
    80003da2:	ffffd097          	auipc	ra,0xffffd
    80003da6:	f9e080e7          	jalr	-98(ra) # 80000d40 <memmove>
  log_write(bp);
    80003daa:	854a                	mv	a0,s2
    80003dac:	00001097          	auipc	ra,0x1
    80003db0:	c06080e7          	jalr	-1018(ra) # 800049b2 <log_write>
  brelse(bp);
    80003db4:	854a                	mv	a0,s2
    80003db6:	00000097          	auipc	ra,0x0
    80003dba:	980080e7          	jalr	-1664(ra) # 80003736 <brelse>
}
    80003dbe:	60e2                	ld	ra,24(sp)
    80003dc0:	6442                	ld	s0,16(sp)
    80003dc2:	64a2                	ld	s1,8(sp)
    80003dc4:	6902                	ld	s2,0(sp)
    80003dc6:	6105                	addi	sp,sp,32
    80003dc8:	8082                	ret

0000000080003dca <idup>:
{
    80003dca:	1101                	addi	sp,sp,-32
    80003dcc:	ec06                	sd	ra,24(sp)
    80003dce:	e822                	sd	s0,16(sp)
    80003dd0:	e426                	sd	s1,8(sp)
    80003dd2:	1000                	addi	s0,sp,32
    80003dd4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003dd6:	000d8517          	auipc	a0,0xd8
    80003dda:	9f250513          	addi	a0,a0,-1550 # 800db7c8 <itable>
    80003dde:	ffffd097          	auipc	ra,0xffffd
    80003de2:	e06080e7          	jalr	-506(ra) # 80000be4 <acquire>
  ip->ref++;
    80003de6:	449c                	lw	a5,8(s1)
    80003de8:	2785                	addiw	a5,a5,1
    80003dea:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003dec:	000d8517          	auipc	a0,0xd8
    80003df0:	9dc50513          	addi	a0,a0,-1572 # 800db7c8 <itable>
    80003df4:	ffffd097          	auipc	ra,0xffffd
    80003df8:	ea4080e7          	jalr	-348(ra) # 80000c98 <release>
}
    80003dfc:	8526                	mv	a0,s1
    80003dfe:	60e2                	ld	ra,24(sp)
    80003e00:	6442                	ld	s0,16(sp)
    80003e02:	64a2                	ld	s1,8(sp)
    80003e04:	6105                	addi	sp,sp,32
    80003e06:	8082                	ret

0000000080003e08 <ilock>:
{
    80003e08:	1101                	addi	sp,sp,-32
    80003e0a:	ec06                	sd	ra,24(sp)
    80003e0c:	e822                	sd	s0,16(sp)
    80003e0e:	e426                	sd	s1,8(sp)
    80003e10:	e04a                	sd	s2,0(sp)
    80003e12:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003e14:	c115                	beqz	a0,80003e38 <ilock+0x30>
    80003e16:	84aa                	mv	s1,a0
    80003e18:	451c                	lw	a5,8(a0)
    80003e1a:	00f05f63          	blez	a5,80003e38 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003e1e:	0541                	addi	a0,a0,16
    80003e20:	00001097          	auipc	ra,0x1
    80003e24:	cb2080e7          	jalr	-846(ra) # 80004ad2 <acquiresleep>
  if(ip->valid == 0){
    80003e28:	40bc                	lw	a5,64(s1)
    80003e2a:	cf99                	beqz	a5,80003e48 <ilock+0x40>
}
    80003e2c:	60e2                	ld	ra,24(sp)
    80003e2e:	6442                	ld	s0,16(sp)
    80003e30:	64a2                	ld	s1,8(sp)
    80003e32:	6902                	ld	s2,0(sp)
    80003e34:	6105                	addi	sp,sp,32
    80003e36:	8082                	ret
    panic("ilock");
    80003e38:	00005517          	auipc	a0,0x5
    80003e3c:	95050513          	addi	a0,a0,-1712 # 80008788 <syscalls+0x190>
    80003e40:	ffffc097          	auipc	ra,0xffffc
    80003e44:	6fe080e7          	jalr	1790(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e48:	40dc                	lw	a5,4(s1)
    80003e4a:	0047d79b          	srliw	a5,a5,0x4
    80003e4e:	000d8597          	auipc	a1,0xd8
    80003e52:	9725a583          	lw	a1,-1678(a1) # 800db7c0 <sb+0x18>
    80003e56:	9dbd                	addw	a1,a1,a5
    80003e58:	4088                	lw	a0,0(s1)
    80003e5a:	fffff097          	auipc	ra,0xfffff
    80003e5e:	7ac080e7          	jalr	1964(ra) # 80003606 <bread>
    80003e62:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e64:	05850593          	addi	a1,a0,88
    80003e68:	40dc                	lw	a5,4(s1)
    80003e6a:	8bbd                	andi	a5,a5,15
    80003e6c:	079a                	slli	a5,a5,0x6
    80003e6e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003e70:	00059783          	lh	a5,0(a1)
    80003e74:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003e78:	00259783          	lh	a5,2(a1)
    80003e7c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003e80:	00459783          	lh	a5,4(a1)
    80003e84:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003e88:	00659783          	lh	a5,6(a1)
    80003e8c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003e90:	459c                	lw	a5,8(a1)
    80003e92:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003e94:	03400613          	li	a2,52
    80003e98:	05b1                	addi	a1,a1,12
    80003e9a:	05048513          	addi	a0,s1,80
    80003e9e:	ffffd097          	auipc	ra,0xffffd
    80003ea2:	ea2080e7          	jalr	-350(ra) # 80000d40 <memmove>
    brelse(bp);
    80003ea6:	854a                	mv	a0,s2
    80003ea8:	00000097          	auipc	ra,0x0
    80003eac:	88e080e7          	jalr	-1906(ra) # 80003736 <brelse>
    ip->valid = 1;
    80003eb0:	4785                	li	a5,1
    80003eb2:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003eb4:	04449783          	lh	a5,68(s1)
    80003eb8:	fbb5                	bnez	a5,80003e2c <ilock+0x24>
      panic("ilock: no type");
    80003eba:	00005517          	auipc	a0,0x5
    80003ebe:	8d650513          	addi	a0,a0,-1834 # 80008790 <syscalls+0x198>
    80003ec2:	ffffc097          	auipc	ra,0xffffc
    80003ec6:	67c080e7          	jalr	1660(ra) # 8000053e <panic>

0000000080003eca <iunlock>:
{
    80003eca:	1101                	addi	sp,sp,-32
    80003ecc:	ec06                	sd	ra,24(sp)
    80003ece:	e822                	sd	s0,16(sp)
    80003ed0:	e426                	sd	s1,8(sp)
    80003ed2:	e04a                	sd	s2,0(sp)
    80003ed4:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003ed6:	c905                	beqz	a0,80003f06 <iunlock+0x3c>
    80003ed8:	84aa                	mv	s1,a0
    80003eda:	01050913          	addi	s2,a0,16
    80003ede:	854a                	mv	a0,s2
    80003ee0:	00001097          	auipc	ra,0x1
    80003ee4:	c8c080e7          	jalr	-884(ra) # 80004b6c <holdingsleep>
    80003ee8:	cd19                	beqz	a0,80003f06 <iunlock+0x3c>
    80003eea:	449c                	lw	a5,8(s1)
    80003eec:	00f05d63          	blez	a5,80003f06 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ef0:	854a                	mv	a0,s2
    80003ef2:	00001097          	auipc	ra,0x1
    80003ef6:	c36080e7          	jalr	-970(ra) # 80004b28 <releasesleep>
}
    80003efa:	60e2                	ld	ra,24(sp)
    80003efc:	6442                	ld	s0,16(sp)
    80003efe:	64a2                	ld	s1,8(sp)
    80003f00:	6902                	ld	s2,0(sp)
    80003f02:	6105                	addi	sp,sp,32
    80003f04:	8082                	ret
    panic("iunlock");
    80003f06:	00005517          	auipc	a0,0x5
    80003f0a:	89a50513          	addi	a0,a0,-1894 # 800087a0 <syscalls+0x1a8>
    80003f0e:	ffffc097          	auipc	ra,0xffffc
    80003f12:	630080e7          	jalr	1584(ra) # 8000053e <panic>

0000000080003f16 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003f16:	7179                	addi	sp,sp,-48
    80003f18:	f406                	sd	ra,40(sp)
    80003f1a:	f022                	sd	s0,32(sp)
    80003f1c:	ec26                	sd	s1,24(sp)
    80003f1e:	e84a                	sd	s2,16(sp)
    80003f20:	e44e                	sd	s3,8(sp)
    80003f22:	e052                	sd	s4,0(sp)
    80003f24:	1800                	addi	s0,sp,48
    80003f26:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003f28:	05050493          	addi	s1,a0,80
    80003f2c:	08050913          	addi	s2,a0,128
    80003f30:	a021                	j	80003f38 <itrunc+0x22>
    80003f32:	0491                	addi	s1,s1,4
    80003f34:	01248d63          	beq	s1,s2,80003f4e <itrunc+0x38>
    if(ip->addrs[i]){
    80003f38:	408c                	lw	a1,0(s1)
    80003f3a:	dde5                	beqz	a1,80003f32 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003f3c:	0009a503          	lw	a0,0(s3)
    80003f40:	00000097          	auipc	ra,0x0
    80003f44:	90c080e7          	jalr	-1780(ra) # 8000384c <bfree>
      ip->addrs[i] = 0;
    80003f48:	0004a023          	sw	zero,0(s1)
    80003f4c:	b7dd                	j	80003f32 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003f4e:	0809a583          	lw	a1,128(s3)
    80003f52:	e185                	bnez	a1,80003f72 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003f54:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003f58:	854e                	mv	a0,s3
    80003f5a:	00000097          	auipc	ra,0x0
    80003f5e:	de4080e7          	jalr	-540(ra) # 80003d3e <iupdate>
}
    80003f62:	70a2                	ld	ra,40(sp)
    80003f64:	7402                	ld	s0,32(sp)
    80003f66:	64e2                	ld	s1,24(sp)
    80003f68:	6942                	ld	s2,16(sp)
    80003f6a:	69a2                	ld	s3,8(sp)
    80003f6c:	6a02                	ld	s4,0(sp)
    80003f6e:	6145                	addi	sp,sp,48
    80003f70:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003f72:	0009a503          	lw	a0,0(s3)
    80003f76:	fffff097          	auipc	ra,0xfffff
    80003f7a:	690080e7          	jalr	1680(ra) # 80003606 <bread>
    80003f7e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003f80:	05850493          	addi	s1,a0,88
    80003f84:	45850913          	addi	s2,a0,1112
    80003f88:	a811                	j	80003f9c <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003f8a:	0009a503          	lw	a0,0(s3)
    80003f8e:	00000097          	auipc	ra,0x0
    80003f92:	8be080e7          	jalr	-1858(ra) # 8000384c <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003f96:	0491                	addi	s1,s1,4
    80003f98:	01248563          	beq	s1,s2,80003fa2 <itrunc+0x8c>
      if(a[j])
    80003f9c:	408c                	lw	a1,0(s1)
    80003f9e:	dde5                	beqz	a1,80003f96 <itrunc+0x80>
    80003fa0:	b7ed                	j	80003f8a <itrunc+0x74>
    brelse(bp);
    80003fa2:	8552                	mv	a0,s4
    80003fa4:	fffff097          	auipc	ra,0xfffff
    80003fa8:	792080e7          	jalr	1938(ra) # 80003736 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003fac:	0809a583          	lw	a1,128(s3)
    80003fb0:	0009a503          	lw	a0,0(s3)
    80003fb4:	00000097          	auipc	ra,0x0
    80003fb8:	898080e7          	jalr	-1896(ra) # 8000384c <bfree>
    ip->addrs[NDIRECT] = 0;
    80003fbc:	0809a023          	sw	zero,128(s3)
    80003fc0:	bf51                	j	80003f54 <itrunc+0x3e>

0000000080003fc2 <iput>:
{
    80003fc2:	1101                	addi	sp,sp,-32
    80003fc4:	ec06                	sd	ra,24(sp)
    80003fc6:	e822                	sd	s0,16(sp)
    80003fc8:	e426                	sd	s1,8(sp)
    80003fca:	e04a                	sd	s2,0(sp)
    80003fcc:	1000                	addi	s0,sp,32
    80003fce:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003fd0:	000d7517          	auipc	a0,0xd7
    80003fd4:	7f850513          	addi	a0,a0,2040 # 800db7c8 <itable>
    80003fd8:	ffffd097          	auipc	ra,0xffffd
    80003fdc:	c0c080e7          	jalr	-1012(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003fe0:	4498                	lw	a4,8(s1)
    80003fe2:	4785                	li	a5,1
    80003fe4:	02f70363          	beq	a4,a5,8000400a <iput+0x48>
  ip->ref--;
    80003fe8:	449c                	lw	a5,8(s1)
    80003fea:	37fd                	addiw	a5,a5,-1
    80003fec:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003fee:	000d7517          	auipc	a0,0xd7
    80003ff2:	7da50513          	addi	a0,a0,2010 # 800db7c8 <itable>
    80003ff6:	ffffd097          	auipc	ra,0xffffd
    80003ffa:	ca2080e7          	jalr	-862(ra) # 80000c98 <release>
}
    80003ffe:	60e2                	ld	ra,24(sp)
    80004000:	6442                	ld	s0,16(sp)
    80004002:	64a2                	ld	s1,8(sp)
    80004004:	6902                	ld	s2,0(sp)
    80004006:	6105                	addi	sp,sp,32
    80004008:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000400a:	40bc                	lw	a5,64(s1)
    8000400c:	dff1                	beqz	a5,80003fe8 <iput+0x26>
    8000400e:	04a49783          	lh	a5,74(s1)
    80004012:	fbf9                	bnez	a5,80003fe8 <iput+0x26>
    acquiresleep(&ip->lock);
    80004014:	01048913          	addi	s2,s1,16
    80004018:	854a                	mv	a0,s2
    8000401a:	00001097          	auipc	ra,0x1
    8000401e:	ab8080e7          	jalr	-1352(ra) # 80004ad2 <acquiresleep>
    release(&itable.lock);
    80004022:	000d7517          	auipc	a0,0xd7
    80004026:	7a650513          	addi	a0,a0,1958 # 800db7c8 <itable>
    8000402a:	ffffd097          	auipc	ra,0xffffd
    8000402e:	c6e080e7          	jalr	-914(ra) # 80000c98 <release>
    itrunc(ip);
    80004032:	8526                	mv	a0,s1
    80004034:	00000097          	auipc	ra,0x0
    80004038:	ee2080e7          	jalr	-286(ra) # 80003f16 <itrunc>
    ip->type = 0;
    8000403c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004040:	8526                	mv	a0,s1
    80004042:	00000097          	auipc	ra,0x0
    80004046:	cfc080e7          	jalr	-772(ra) # 80003d3e <iupdate>
    ip->valid = 0;
    8000404a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000404e:	854a                	mv	a0,s2
    80004050:	00001097          	auipc	ra,0x1
    80004054:	ad8080e7          	jalr	-1320(ra) # 80004b28 <releasesleep>
    acquire(&itable.lock);
    80004058:	000d7517          	auipc	a0,0xd7
    8000405c:	77050513          	addi	a0,a0,1904 # 800db7c8 <itable>
    80004060:	ffffd097          	auipc	ra,0xffffd
    80004064:	b84080e7          	jalr	-1148(ra) # 80000be4 <acquire>
    80004068:	b741                	j	80003fe8 <iput+0x26>

000000008000406a <iunlockput>:
{
    8000406a:	1101                	addi	sp,sp,-32
    8000406c:	ec06                	sd	ra,24(sp)
    8000406e:	e822                	sd	s0,16(sp)
    80004070:	e426                	sd	s1,8(sp)
    80004072:	1000                	addi	s0,sp,32
    80004074:	84aa                	mv	s1,a0
  iunlock(ip);
    80004076:	00000097          	auipc	ra,0x0
    8000407a:	e54080e7          	jalr	-428(ra) # 80003eca <iunlock>
  iput(ip);
    8000407e:	8526                	mv	a0,s1
    80004080:	00000097          	auipc	ra,0x0
    80004084:	f42080e7          	jalr	-190(ra) # 80003fc2 <iput>
}
    80004088:	60e2                	ld	ra,24(sp)
    8000408a:	6442                	ld	s0,16(sp)
    8000408c:	64a2                	ld	s1,8(sp)
    8000408e:	6105                	addi	sp,sp,32
    80004090:	8082                	ret

0000000080004092 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004092:	1141                	addi	sp,sp,-16
    80004094:	e422                	sd	s0,8(sp)
    80004096:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004098:	411c                	lw	a5,0(a0)
    8000409a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000409c:	415c                	lw	a5,4(a0)
    8000409e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800040a0:	04451783          	lh	a5,68(a0)
    800040a4:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800040a8:	04a51783          	lh	a5,74(a0)
    800040ac:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800040b0:	04c56783          	lwu	a5,76(a0)
    800040b4:	e99c                	sd	a5,16(a1)
}
    800040b6:	6422                	ld	s0,8(sp)
    800040b8:	0141                	addi	sp,sp,16
    800040ba:	8082                	ret

00000000800040bc <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040bc:	457c                	lw	a5,76(a0)
    800040be:	0ed7e963          	bltu	a5,a3,800041b0 <readi+0xf4>
{
    800040c2:	7159                	addi	sp,sp,-112
    800040c4:	f486                	sd	ra,104(sp)
    800040c6:	f0a2                	sd	s0,96(sp)
    800040c8:	eca6                	sd	s1,88(sp)
    800040ca:	e8ca                	sd	s2,80(sp)
    800040cc:	e4ce                	sd	s3,72(sp)
    800040ce:	e0d2                	sd	s4,64(sp)
    800040d0:	fc56                	sd	s5,56(sp)
    800040d2:	f85a                	sd	s6,48(sp)
    800040d4:	f45e                	sd	s7,40(sp)
    800040d6:	f062                	sd	s8,32(sp)
    800040d8:	ec66                	sd	s9,24(sp)
    800040da:	e86a                	sd	s10,16(sp)
    800040dc:	e46e                	sd	s11,8(sp)
    800040de:	1880                	addi	s0,sp,112
    800040e0:	8baa                	mv	s7,a0
    800040e2:	8c2e                	mv	s8,a1
    800040e4:	8ab2                	mv	s5,a2
    800040e6:	84b6                	mv	s1,a3
    800040e8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800040ea:	9f35                	addw	a4,a4,a3
    return 0;
    800040ec:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800040ee:	0ad76063          	bltu	a4,a3,8000418e <readi+0xd2>
  if(off + n > ip->size)
    800040f2:	00e7f463          	bgeu	a5,a4,800040fa <readi+0x3e>
    n = ip->size - off;
    800040f6:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040fa:	0a0b0963          	beqz	s6,800041ac <readi+0xf0>
    800040fe:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004100:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004104:	5cfd                	li	s9,-1
    80004106:	a82d                	j	80004140 <readi+0x84>
    80004108:	020a1d93          	slli	s11,s4,0x20
    8000410c:	020ddd93          	srli	s11,s11,0x20
    80004110:	05890613          	addi	a2,s2,88
    80004114:	86ee                	mv	a3,s11
    80004116:	963a                	add	a2,a2,a4
    80004118:	85d6                	mv	a1,s5
    8000411a:	8562                	mv	a0,s8
    8000411c:	ffffe097          	auipc	ra,0xffffe
    80004120:	6a6080e7          	jalr	1702(ra) # 800027c2 <either_copyout>
    80004124:	05950d63          	beq	a0,s9,8000417e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004128:	854a                	mv	a0,s2
    8000412a:	fffff097          	auipc	ra,0xfffff
    8000412e:	60c080e7          	jalr	1548(ra) # 80003736 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004132:	013a09bb          	addw	s3,s4,s3
    80004136:	009a04bb          	addw	s1,s4,s1
    8000413a:	9aee                	add	s5,s5,s11
    8000413c:	0569f763          	bgeu	s3,s6,8000418a <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004140:	000ba903          	lw	s2,0(s7)
    80004144:	00a4d59b          	srliw	a1,s1,0xa
    80004148:	855e                	mv	a0,s7
    8000414a:	00000097          	auipc	ra,0x0
    8000414e:	8b0080e7          	jalr	-1872(ra) # 800039fa <bmap>
    80004152:	0005059b          	sext.w	a1,a0
    80004156:	854a                	mv	a0,s2
    80004158:	fffff097          	auipc	ra,0xfffff
    8000415c:	4ae080e7          	jalr	1198(ra) # 80003606 <bread>
    80004160:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004162:	3ff4f713          	andi	a4,s1,1023
    80004166:	40ed07bb          	subw	a5,s10,a4
    8000416a:	413b06bb          	subw	a3,s6,s3
    8000416e:	8a3e                	mv	s4,a5
    80004170:	2781                	sext.w	a5,a5
    80004172:	0006861b          	sext.w	a2,a3
    80004176:	f8f679e3          	bgeu	a2,a5,80004108 <readi+0x4c>
    8000417a:	8a36                	mv	s4,a3
    8000417c:	b771                	j	80004108 <readi+0x4c>
      brelse(bp);
    8000417e:	854a                	mv	a0,s2
    80004180:	fffff097          	auipc	ra,0xfffff
    80004184:	5b6080e7          	jalr	1462(ra) # 80003736 <brelse>
      tot = -1;
    80004188:	59fd                	li	s3,-1
  }
  return tot;
    8000418a:	0009851b          	sext.w	a0,s3
}
    8000418e:	70a6                	ld	ra,104(sp)
    80004190:	7406                	ld	s0,96(sp)
    80004192:	64e6                	ld	s1,88(sp)
    80004194:	6946                	ld	s2,80(sp)
    80004196:	69a6                	ld	s3,72(sp)
    80004198:	6a06                	ld	s4,64(sp)
    8000419a:	7ae2                	ld	s5,56(sp)
    8000419c:	7b42                	ld	s6,48(sp)
    8000419e:	7ba2                	ld	s7,40(sp)
    800041a0:	7c02                	ld	s8,32(sp)
    800041a2:	6ce2                	ld	s9,24(sp)
    800041a4:	6d42                	ld	s10,16(sp)
    800041a6:	6da2                	ld	s11,8(sp)
    800041a8:	6165                	addi	sp,sp,112
    800041aa:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041ac:	89da                	mv	s3,s6
    800041ae:	bff1                	j	8000418a <readi+0xce>
    return 0;
    800041b0:	4501                	li	a0,0
}
    800041b2:	8082                	ret

00000000800041b4 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800041b4:	457c                	lw	a5,76(a0)
    800041b6:	10d7e863          	bltu	a5,a3,800042c6 <writei+0x112>
{
    800041ba:	7159                	addi	sp,sp,-112
    800041bc:	f486                	sd	ra,104(sp)
    800041be:	f0a2                	sd	s0,96(sp)
    800041c0:	eca6                	sd	s1,88(sp)
    800041c2:	e8ca                	sd	s2,80(sp)
    800041c4:	e4ce                	sd	s3,72(sp)
    800041c6:	e0d2                	sd	s4,64(sp)
    800041c8:	fc56                	sd	s5,56(sp)
    800041ca:	f85a                	sd	s6,48(sp)
    800041cc:	f45e                	sd	s7,40(sp)
    800041ce:	f062                	sd	s8,32(sp)
    800041d0:	ec66                	sd	s9,24(sp)
    800041d2:	e86a                	sd	s10,16(sp)
    800041d4:	e46e                	sd	s11,8(sp)
    800041d6:	1880                	addi	s0,sp,112
    800041d8:	8b2a                	mv	s6,a0
    800041da:	8c2e                	mv	s8,a1
    800041dc:	8ab2                	mv	s5,a2
    800041de:	8936                	mv	s2,a3
    800041e0:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800041e2:	00e687bb          	addw	a5,a3,a4
    800041e6:	0ed7e263          	bltu	a5,a3,800042ca <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800041ea:	00043737          	lui	a4,0x43
    800041ee:	0ef76063          	bltu	a4,a5,800042ce <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041f2:	0c0b8863          	beqz	s7,800042c2 <writei+0x10e>
    800041f6:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800041f8:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800041fc:	5cfd                	li	s9,-1
    800041fe:	a091                	j	80004242 <writei+0x8e>
    80004200:	02099d93          	slli	s11,s3,0x20
    80004204:	020ddd93          	srli	s11,s11,0x20
    80004208:	05848513          	addi	a0,s1,88
    8000420c:	86ee                	mv	a3,s11
    8000420e:	8656                	mv	a2,s5
    80004210:	85e2                	mv	a1,s8
    80004212:	953a                	add	a0,a0,a4
    80004214:	ffffe097          	auipc	ra,0xffffe
    80004218:	604080e7          	jalr	1540(ra) # 80002818 <either_copyin>
    8000421c:	07950263          	beq	a0,s9,80004280 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004220:	8526                	mv	a0,s1
    80004222:	00000097          	auipc	ra,0x0
    80004226:	790080e7          	jalr	1936(ra) # 800049b2 <log_write>
    brelse(bp);
    8000422a:	8526                	mv	a0,s1
    8000422c:	fffff097          	auipc	ra,0xfffff
    80004230:	50a080e7          	jalr	1290(ra) # 80003736 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004234:	01498a3b          	addw	s4,s3,s4
    80004238:	0129893b          	addw	s2,s3,s2
    8000423c:	9aee                	add	s5,s5,s11
    8000423e:	057a7663          	bgeu	s4,s7,8000428a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004242:	000b2483          	lw	s1,0(s6)
    80004246:	00a9559b          	srliw	a1,s2,0xa
    8000424a:	855a                	mv	a0,s6
    8000424c:	fffff097          	auipc	ra,0xfffff
    80004250:	7ae080e7          	jalr	1966(ra) # 800039fa <bmap>
    80004254:	0005059b          	sext.w	a1,a0
    80004258:	8526                	mv	a0,s1
    8000425a:	fffff097          	auipc	ra,0xfffff
    8000425e:	3ac080e7          	jalr	940(ra) # 80003606 <bread>
    80004262:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004264:	3ff97713          	andi	a4,s2,1023
    80004268:	40ed07bb          	subw	a5,s10,a4
    8000426c:	414b86bb          	subw	a3,s7,s4
    80004270:	89be                	mv	s3,a5
    80004272:	2781                	sext.w	a5,a5
    80004274:	0006861b          	sext.w	a2,a3
    80004278:	f8f674e3          	bgeu	a2,a5,80004200 <writei+0x4c>
    8000427c:	89b6                	mv	s3,a3
    8000427e:	b749                	j	80004200 <writei+0x4c>
      brelse(bp);
    80004280:	8526                	mv	a0,s1
    80004282:	fffff097          	auipc	ra,0xfffff
    80004286:	4b4080e7          	jalr	1204(ra) # 80003736 <brelse>
  }

  if(off > ip->size)
    8000428a:	04cb2783          	lw	a5,76(s6)
    8000428e:	0127f463          	bgeu	a5,s2,80004296 <writei+0xe2>
    ip->size = off;
    80004292:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004296:	855a                	mv	a0,s6
    80004298:	00000097          	auipc	ra,0x0
    8000429c:	aa6080e7          	jalr	-1370(ra) # 80003d3e <iupdate>

  return tot;
    800042a0:	000a051b          	sext.w	a0,s4
}
    800042a4:	70a6                	ld	ra,104(sp)
    800042a6:	7406                	ld	s0,96(sp)
    800042a8:	64e6                	ld	s1,88(sp)
    800042aa:	6946                	ld	s2,80(sp)
    800042ac:	69a6                	ld	s3,72(sp)
    800042ae:	6a06                	ld	s4,64(sp)
    800042b0:	7ae2                	ld	s5,56(sp)
    800042b2:	7b42                	ld	s6,48(sp)
    800042b4:	7ba2                	ld	s7,40(sp)
    800042b6:	7c02                	ld	s8,32(sp)
    800042b8:	6ce2                	ld	s9,24(sp)
    800042ba:	6d42                	ld	s10,16(sp)
    800042bc:	6da2                	ld	s11,8(sp)
    800042be:	6165                	addi	sp,sp,112
    800042c0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042c2:	8a5e                	mv	s4,s7
    800042c4:	bfc9                	j	80004296 <writei+0xe2>
    return -1;
    800042c6:	557d                	li	a0,-1
}
    800042c8:	8082                	ret
    return -1;
    800042ca:	557d                	li	a0,-1
    800042cc:	bfe1                	j	800042a4 <writei+0xf0>
    return -1;
    800042ce:	557d                	li	a0,-1
    800042d0:	bfd1                	j	800042a4 <writei+0xf0>

00000000800042d2 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800042d2:	1141                	addi	sp,sp,-16
    800042d4:	e406                	sd	ra,8(sp)
    800042d6:	e022                	sd	s0,0(sp)
    800042d8:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800042da:	4639                	li	a2,14
    800042dc:	ffffd097          	auipc	ra,0xffffd
    800042e0:	adc080e7          	jalr	-1316(ra) # 80000db8 <strncmp>
}
    800042e4:	60a2                	ld	ra,8(sp)
    800042e6:	6402                	ld	s0,0(sp)
    800042e8:	0141                	addi	sp,sp,16
    800042ea:	8082                	ret

00000000800042ec <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800042ec:	7139                	addi	sp,sp,-64
    800042ee:	fc06                	sd	ra,56(sp)
    800042f0:	f822                	sd	s0,48(sp)
    800042f2:	f426                	sd	s1,40(sp)
    800042f4:	f04a                	sd	s2,32(sp)
    800042f6:	ec4e                	sd	s3,24(sp)
    800042f8:	e852                	sd	s4,16(sp)
    800042fa:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800042fc:	04451703          	lh	a4,68(a0)
    80004300:	4785                	li	a5,1
    80004302:	00f71a63          	bne	a4,a5,80004316 <dirlookup+0x2a>
    80004306:	892a                	mv	s2,a0
    80004308:	89ae                	mv	s3,a1
    8000430a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000430c:	457c                	lw	a5,76(a0)
    8000430e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004310:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004312:	e79d                	bnez	a5,80004340 <dirlookup+0x54>
    80004314:	a8a5                	j	8000438c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004316:	00004517          	auipc	a0,0x4
    8000431a:	49250513          	addi	a0,a0,1170 # 800087a8 <syscalls+0x1b0>
    8000431e:	ffffc097          	auipc	ra,0xffffc
    80004322:	220080e7          	jalr	544(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004326:	00004517          	auipc	a0,0x4
    8000432a:	49a50513          	addi	a0,a0,1178 # 800087c0 <syscalls+0x1c8>
    8000432e:	ffffc097          	auipc	ra,0xffffc
    80004332:	210080e7          	jalr	528(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004336:	24c1                	addiw	s1,s1,16
    80004338:	04c92783          	lw	a5,76(s2)
    8000433c:	04f4f763          	bgeu	s1,a5,8000438a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004340:	4741                	li	a4,16
    80004342:	86a6                	mv	a3,s1
    80004344:	fc040613          	addi	a2,s0,-64
    80004348:	4581                	li	a1,0
    8000434a:	854a                	mv	a0,s2
    8000434c:	00000097          	auipc	ra,0x0
    80004350:	d70080e7          	jalr	-656(ra) # 800040bc <readi>
    80004354:	47c1                	li	a5,16
    80004356:	fcf518e3          	bne	a0,a5,80004326 <dirlookup+0x3a>
    if(de.inum == 0)
    8000435a:	fc045783          	lhu	a5,-64(s0)
    8000435e:	dfe1                	beqz	a5,80004336 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004360:	fc240593          	addi	a1,s0,-62
    80004364:	854e                	mv	a0,s3
    80004366:	00000097          	auipc	ra,0x0
    8000436a:	f6c080e7          	jalr	-148(ra) # 800042d2 <namecmp>
    8000436e:	f561                	bnez	a0,80004336 <dirlookup+0x4a>
      if(poff)
    80004370:	000a0463          	beqz	s4,80004378 <dirlookup+0x8c>
        *poff = off;
    80004374:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004378:	fc045583          	lhu	a1,-64(s0)
    8000437c:	00092503          	lw	a0,0(s2)
    80004380:	fffff097          	auipc	ra,0xfffff
    80004384:	754080e7          	jalr	1876(ra) # 80003ad4 <iget>
    80004388:	a011                	j	8000438c <dirlookup+0xa0>
  return 0;
    8000438a:	4501                	li	a0,0
}
    8000438c:	70e2                	ld	ra,56(sp)
    8000438e:	7442                	ld	s0,48(sp)
    80004390:	74a2                	ld	s1,40(sp)
    80004392:	7902                	ld	s2,32(sp)
    80004394:	69e2                	ld	s3,24(sp)
    80004396:	6a42                	ld	s4,16(sp)
    80004398:	6121                	addi	sp,sp,64
    8000439a:	8082                	ret

000000008000439c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000439c:	711d                	addi	sp,sp,-96
    8000439e:	ec86                	sd	ra,88(sp)
    800043a0:	e8a2                	sd	s0,80(sp)
    800043a2:	e4a6                	sd	s1,72(sp)
    800043a4:	e0ca                	sd	s2,64(sp)
    800043a6:	fc4e                	sd	s3,56(sp)
    800043a8:	f852                	sd	s4,48(sp)
    800043aa:	f456                	sd	s5,40(sp)
    800043ac:	f05a                	sd	s6,32(sp)
    800043ae:	ec5e                	sd	s7,24(sp)
    800043b0:	e862                	sd	s8,16(sp)
    800043b2:	e466                	sd	s9,8(sp)
    800043b4:	1080                	addi	s0,sp,96
    800043b6:	84aa                	mv	s1,a0
    800043b8:	8b2e                	mv	s6,a1
    800043ba:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800043bc:	00054703          	lbu	a4,0(a0)
    800043c0:	02f00793          	li	a5,47
    800043c4:	02f70363          	beq	a4,a5,800043ea <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800043c8:	ffffd097          	auipc	ra,0xffffd
    800043cc:	608080e7          	jalr	1544(ra) # 800019d0 <myproc>
    800043d0:	15053503          	ld	a0,336(a0)
    800043d4:	00000097          	auipc	ra,0x0
    800043d8:	9f6080e7          	jalr	-1546(ra) # 80003dca <idup>
    800043dc:	89aa                	mv	s3,a0
  while(*path == '/')
    800043de:	02f00913          	li	s2,47
  len = path - s;
    800043e2:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800043e4:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800043e6:	4c05                	li	s8,1
    800043e8:	a865                	j	800044a0 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800043ea:	4585                	li	a1,1
    800043ec:	4505                	li	a0,1
    800043ee:	fffff097          	auipc	ra,0xfffff
    800043f2:	6e6080e7          	jalr	1766(ra) # 80003ad4 <iget>
    800043f6:	89aa                	mv	s3,a0
    800043f8:	b7dd                	j	800043de <namex+0x42>
      iunlockput(ip);
    800043fa:	854e                	mv	a0,s3
    800043fc:	00000097          	auipc	ra,0x0
    80004400:	c6e080e7          	jalr	-914(ra) # 8000406a <iunlockput>
      return 0;
    80004404:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004406:	854e                	mv	a0,s3
    80004408:	60e6                	ld	ra,88(sp)
    8000440a:	6446                	ld	s0,80(sp)
    8000440c:	64a6                	ld	s1,72(sp)
    8000440e:	6906                	ld	s2,64(sp)
    80004410:	79e2                	ld	s3,56(sp)
    80004412:	7a42                	ld	s4,48(sp)
    80004414:	7aa2                	ld	s5,40(sp)
    80004416:	7b02                	ld	s6,32(sp)
    80004418:	6be2                	ld	s7,24(sp)
    8000441a:	6c42                	ld	s8,16(sp)
    8000441c:	6ca2                	ld	s9,8(sp)
    8000441e:	6125                	addi	sp,sp,96
    80004420:	8082                	ret
      iunlock(ip);
    80004422:	854e                	mv	a0,s3
    80004424:	00000097          	auipc	ra,0x0
    80004428:	aa6080e7          	jalr	-1370(ra) # 80003eca <iunlock>
      return ip;
    8000442c:	bfe9                	j	80004406 <namex+0x6a>
      iunlockput(ip);
    8000442e:	854e                	mv	a0,s3
    80004430:	00000097          	auipc	ra,0x0
    80004434:	c3a080e7          	jalr	-966(ra) # 8000406a <iunlockput>
      return 0;
    80004438:	89d2                	mv	s3,s4
    8000443a:	b7f1                	j	80004406 <namex+0x6a>
  len = path - s;
    8000443c:	40b48633          	sub	a2,s1,a1
    80004440:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004444:	094cd463          	bge	s9,s4,800044cc <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004448:	4639                	li	a2,14
    8000444a:	8556                	mv	a0,s5
    8000444c:	ffffd097          	auipc	ra,0xffffd
    80004450:	8f4080e7          	jalr	-1804(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004454:	0004c783          	lbu	a5,0(s1)
    80004458:	01279763          	bne	a5,s2,80004466 <namex+0xca>
    path++;
    8000445c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000445e:	0004c783          	lbu	a5,0(s1)
    80004462:	ff278de3          	beq	a5,s2,8000445c <namex+0xc0>
    ilock(ip);
    80004466:	854e                	mv	a0,s3
    80004468:	00000097          	auipc	ra,0x0
    8000446c:	9a0080e7          	jalr	-1632(ra) # 80003e08 <ilock>
    if(ip->type != T_DIR){
    80004470:	04499783          	lh	a5,68(s3)
    80004474:	f98793e3          	bne	a5,s8,800043fa <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004478:	000b0563          	beqz	s6,80004482 <namex+0xe6>
    8000447c:	0004c783          	lbu	a5,0(s1)
    80004480:	d3cd                	beqz	a5,80004422 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004482:	865e                	mv	a2,s7
    80004484:	85d6                	mv	a1,s5
    80004486:	854e                	mv	a0,s3
    80004488:	00000097          	auipc	ra,0x0
    8000448c:	e64080e7          	jalr	-412(ra) # 800042ec <dirlookup>
    80004490:	8a2a                	mv	s4,a0
    80004492:	dd51                	beqz	a0,8000442e <namex+0x92>
    iunlockput(ip);
    80004494:	854e                	mv	a0,s3
    80004496:	00000097          	auipc	ra,0x0
    8000449a:	bd4080e7          	jalr	-1068(ra) # 8000406a <iunlockput>
    ip = next;
    8000449e:	89d2                	mv	s3,s4
  while(*path == '/')
    800044a0:	0004c783          	lbu	a5,0(s1)
    800044a4:	05279763          	bne	a5,s2,800044f2 <namex+0x156>
    path++;
    800044a8:	0485                	addi	s1,s1,1
  while(*path == '/')
    800044aa:	0004c783          	lbu	a5,0(s1)
    800044ae:	ff278de3          	beq	a5,s2,800044a8 <namex+0x10c>
  if(*path == 0)
    800044b2:	c79d                	beqz	a5,800044e0 <namex+0x144>
    path++;
    800044b4:	85a6                	mv	a1,s1
  len = path - s;
    800044b6:	8a5e                	mv	s4,s7
    800044b8:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800044ba:	01278963          	beq	a5,s2,800044cc <namex+0x130>
    800044be:	dfbd                	beqz	a5,8000443c <namex+0xa0>
    path++;
    800044c0:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800044c2:	0004c783          	lbu	a5,0(s1)
    800044c6:	ff279ce3          	bne	a5,s2,800044be <namex+0x122>
    800044ca:	bf8d                	j	8000443c <namex+0xa0>
    memmove(name, s, len);
    800044cc:	2601                	sext.w	a2,a2
    800044ce:	8556                	mv	a0,s5
    800044d0:	ffffd097          	auipc	ra,0xffffd
    800044d4:	870080e7          	jalr	-1936(ra) # 80000d40 <memmove>
    name[len] = 0;
    800044d8:	9a56                	add	s4,s4,s5
    800044da:	000a0023          	sb	zero,0(s4)
    800044de:	bf9d                	j	80004454 <namex+0xb8>
  if(nameiparent){
    800044e0:	f20b03e3          	beqz	s6,80004406 <namex+0x6a>
    iput(ip);
    800044e4:	854e                	mv	a0,s3
    800044e6:	00000097          	auipc	ra,0x0
    800044ea:	adc080e7          	jalr	-1316(ra) # 80003fc2 <iput>
    return 0;
    800044ee:	4981                	li	s3,0
    800044f0:	bf19                	j	80004406 <namex+0x6a>
  if(*path == 0)
    800044f2:	d7fd                	beqz	a5,800044e0 <namex+0x144>
  while(*path != '/' && *path != 0)
    800044f4:	0004c783          	lbu	a5,0(s1)
    800044f8:	85a6                	mv	a1,s1
    800044fa:	b7d1                	j	800044be <namex+0x122>

00000000800044fc <dirlink>:
{
    800044fc:	7139                	addi	sp,sp,-64
    800044fe:	fc06                	sd	ra,56(sp)
    80004500:	f822                	sd	s0,48(sp)
    80004502:	f426                	sd	s1,40(sp)
    80004504:	f04a                	sd	s2,32(sp)
    80004506:	ec4e                	sd	s3,24(sp)
    80004508:	e852                	sd	s4,16(sp)
    8000450a:	0080                	addi	s0,sp,64
    8000450c:	892a                	mv	s2,a0
    8000450e:	8a2e                	mv	s4,a1
    80004510:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004512:	4601                	li	a2,0
    80004514:	00000097          	auipc	ra,0x0
    80004518:	dd8080e7          	jalr	-552(ra) # 800042ec <dirlookup>
    8000451c:	e93d                	bnez	a0,80004592 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000451e:	04c92483          	lw	s1,76(s2)
    80004522:	c49d                	beqz	s1,80004550 <dirlink+0x54>
    80004524:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004526:	4741                	li	a4,16
    80004528:	86a6                	mv	a3,s1
    8000452a:	fc040613          	addi	a2,s0,-64
    8000452e:	4581                	li	a1,0
    80004530:	854a                	mv	a0,s2
    80004532:	00000097          	auipc	ra,0x0
    80004536:	b8a080e7          	jalr	-1142(ra) # 800040bc <readi>
    8000453a:	47c1                	li	a5,16
    8000453c:	06f51163          	bne	a0,a5,8000459e <dirlink+0xa2>
    if(de.inum == 0)
    80004540:	fc045783          	lhu	a5,-64(s0)
    80004544:	c791                	beqz	a5,80004550 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004546:	24c1                	addiw	s1,s1,16
    80004548:	04c92783          	lw	a5,76(s2)
    8000454c:	fcf4ede3          	bltu	s1,a5,80004526 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004550:	4639                	li	a2,14
    80004552:	85d2                	mv	a1,s4
    80004554:	fc240513          	addi	a0,s0,-62
    80004558:	ffffd097          	auipc	ra,0xffffd
    8000455c:	89c080e7          	jalr	-1892(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004560:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004564:	4741                	li	a4,16
    80004566:	86a6                	mv	a3,s1
    80004568:	fc040613          	addi	a2,s0,-64
    8000456c:	4581                	li	a1,0
    8000456e:	854a                	mv	a0,s2
    80004570:	00000097          	auipc	ra,0x0
    80004574:	c44080e7          	jalr	-956(ra) # 800041b4 <writei>
    80004578:	872a                	mv	a4,a0
    8000457a:	47c1                	li	a5,16
  return 0;
    8000457c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000457e:	02f71863          	bne	a4,a5,800045ae <dirlink+0xb2>
}
    80004582:	70e2                	ld	ra,56(sp)
    80004584:	7442                	ld	s0,48(sp)
    80004586:	74a2                	ld	s1,40(sp)
    80004588:	7902                	ld	s2,32(sp)
    8000458a:	69e2                	ld	s3,24(sp)
    8000458c:	6a42                	ld	s4,16(sp)
    8000458e:	6121                	addi	sp,sp,64
    80004590:	8082                	ret
    iput(ip);
    80004592:	00000097          	auipc	ra,0x0
    80004596:	a30080e7          	jalr	-1488(ra) # 80003fc2 <iput>
    return -1;
    8000459a:	557d                	li	a0,-1
    8000459c:	b7dd                	j	80004582 <dirlink+0x86>
      panic("dirlink read");
    8000459e:	00004517          	auipc	a0,0x4
    800045a2:	23250513          	addi	a0,a0,562 # 800087d0 <syscalls+0x1d8>
    800045a6:	ffffc097          	auipc	ra,0xffffc
    800045aa:	f98080e7          	jalr	-104(ra) # 8000053e <panic>
    panic("dirlink");
    800045ae:	00004517          	auipc	a0,0x4
    800045b2:	32a50513          	addi	a0,a0,810 # 800088d8 <syscalls+0x2e0>
    800045b6:	ffffc097          	auipc	ra,0xffffc
    800045ba:	f88080e7          	jalr	-120(ra) # 8000053e <panic>

00000000800045be <namei>:

struct inode*
namei(char *path)
{
    800045be:	1101                	addi	sp,sp,-32
    800045c0:	ec06                	sd	ra,24(sp)
    800045c2:	e822                	sd	s0,16(sp)
    800045c4:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800045c6:	fe040613          	addi	a2,s0,-32
    800045ca:	4581                	li	a1,0
    800045cc:	00000097          	auipc	ra,0x0
    800045d0:	dd0080e7          	jalr	-560(ra) # 8000439c <namex>
}
    800045d4:	60e2                	ld	ra,24(sp)
    800045d6:	6442                	ld	s0,16(sp)
    800045d8:	6105                	addi	sp,sp,32
    800045da:	8082                	ret

00000000800045dc <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800045dc:	1141                	addi	sp,sp,-16
    800045de:	e406                	sd	ra,8(sp)
    800045e0:	e022                	sd	s0,0(sp)
    800045e2:	0800                	addi	s0,sp,16
    800045e4:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800045e6:	4585                	li	a1,1
    800045e8:	00000097          	auipc	ra,0x0
    800045ec:	db4080e7          	jalr	-588(ra) # 8000439c <namex>
}
    800045f0:	60a2                	ld	ra,8(sp)
    800045f2:	6402                	ld	s0,0(sp)
    800045f4:	0141                	addi	sp,sp,16
    800045f6:	8082                	ret

00000000800045f8 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800045f8:	1101                	addi	sp,sp,-32
    800045fa:	ec06                	sd	ra,24(sp)
    800045fc:	e822                	sd	s0,16(sp)
    800045fe:	e426                	sd	s1,8(sp)
    80004600:	e04a                	sd	s2,0(sp)
    80004602:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004604:	000d9917          	auipc	s2,0xd9
    80004608:	c6c90913          	addi	s2,s2,-916 # 800dd270 <log>
    8000460c:	01892583          	lw	a1,24(s2)
    80004610:	02892503          	lw	a0,40(s2)
    80004614:	fffff097          	auipc	ra,0xfffff
    80004618:	ff2080e7          	jalr	-14(ra) # 80003606 <bread>
    8000461c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000461e:	02c92683          	lw	a3,44(s2)
    80004622:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004624:	02d05763          	blez	a3,80004652 <write_head+0x5a>
    80004628:	000d9797          	auipc	a5,0xd9
    8000462c:	c7878793          	addi	a5,a5,-904 # 800dd2a0 <log+0x30>
    80004630:	05c50713          	addi	a4,a0,92
    80004634:	36fd                	addiw	a3,a3,-1
    80004636:	1682                	slli	a3,a3,0x20
    80004638:	9281                	srli	a3,a3,0x20
    8000463a:	068a                	slli	a3,a3,0x2
    8000463c:	000d9617          	auipc	a2,0xd9
    80004640:	c6860613          	addi	a2,a2,-920 # 800dd2a4 <log+0x34>
    80004644:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004646:	4390                	lw	a2,0(a5)
    80004648:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000464a:	0791                	addi	a5,a5,4
    8000464c:	0711                	addi	a4,a4,4
    8000464e:	fed79ce3          	bne	a5,a3,80004646 <write_head+0x4e>
  }
  bwrite(buf);
    80004652:	8526                	mv	a0,s1
    80004654:	fffff097          	auipc	ra,0xfffff
    80004658:	0a4080e7          	jalr	164(ra) # 800036f8 <bwrite>
  brelse(buf);
    8000465c:	8526                	mv	a0,s1
    8000465e:	fffff097          	auipc	ra,0xfffff
    80004662:	0d8080e7          	jalr	216(ra) # 80003736 <brelse>
}
    80004666:	60e2                	ld	ra,24(sp)
    80004668:	6442                	ld	s0,16(sp)
    8000466a:	64a2                	ld	s1,8(sp)
    8000466c:	6902                	ld	s2,0(sp)
    8000466e:	6105                	addi	sp,sp,32
    80004670:	8082                	ret

0000000080004672 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004672:	000d9797          	auipc	a5,0xd9
    80004676:	c2a7a783          	lw	a5,-982(a5) # 800dd29c <log+0x2c>
    8000467a:	0af05d63          	blez	a5,80004734 <install_trans+0xc2>
{
    8000467e:	7139                	addi	sp,sp,-64
    80004680:	fc06                	sd	ra,56(sp)
    80004682:	f822                	sd	s0,48(sp)
    80004684:	f426                	sd	s1,40(sp)
    80004686:	f04a                	sd	s2,32(sp)
    80004688:	ec4e                	sd	s3,24(sp)
    8000468a:	e852                	sd	s4,16(sp)
    8000468c:	e456                	sd	s5,8(sp)
    8000468e:	e05a                	sd	s6,0(sp)
    80004690:	0080                	addi	s0,sp,64
    80004692:	8b2a                	mv	s6,a0
    80004694:	000d9a97          	auipc	s5,0xd9
    80004698:	c0ca8a93          	addi	s5,s5,-1012 # 800dd2a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000469c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000469e:	000d9997          	auipc	s3,0xd9
    800046a2:	bd298993          	addi	s3,s3,-1070 # 800dd270 <log>
    800046a6:	a035                	j	800046d2 <install_trans+0x60>
      bunpin(dbuf);
    800046a8:	8526                	mv	a0,s1
    800046aa:	fffff097          	auipc	ra,0xfffff
    800046ae:	166080e7          	jalr	358(ra) # 80003810 <bunpin>
    brelse(lbuf);
    800046b2:	854a                	mv	a0,s2
    800046b4:	fffff097          	auipc	ra,0xfffff
    800046b8:	082080e7          	jalr	130(ra) # 80003736 <brelse>
    brelse(dbuf);
    800046bc:	8526                	mv	a0,s1
    800046be:	fffff097          	auipc	ra,0xfffff
    800046c2:	078080e7          	jalr	120(ra) # 80003736 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046c6:	2a05                	addiw	s4,s4,1
    800046c8:	0a91                	addi	s5,s5,4
    800046ca:	02c9a783          	lw	a5,44(s3)
    800046ce:	04fa5963          	bge	s4,a5,80004720 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800046d2:	0189a583          	lw	a1,24(s3)
    800046d6:	014585bb          	addw	a1,a1,s4
    800046da:	2585                	addiw	a1,a1,1
    800046dc:	0289a503          	lw	a0,40(s3)
    800046e0:	fffff097          	auipc	ra,0xfffff
    800046e4:	f26080e7          	jalr	-218(ra) # 80003606 <bread>
    800046e8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800046ea:	000aa583          	lw	a1,0(s5)
    800046ee:	0289a503          	lw	a0,40(s3)
    800046f2:	fffff097          	auipc	ra,0xfffff
    800046f6:	f14080e7          	jalr	-236(ra) # 80003606 <bread>
    800046fa:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800046fc:	40000613          	li	a2,1024
    80004700:	05890593          	addi	a1,s2,88
    80004704:	05850513          	addi	a0,a0,88
    80004708:	ffffc097          	auipc	ra,0xffffc
    8000470c:	638080e7          	jalr	1592(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004710:	8526                	mv	a0,s1
    80004712:	fffff097          	auipc	ra,0xfffff
    80004716:	fe6080e7          	jalr	-26(ra) # 800036f8 <bwrite>
    if(recovering == 0)
    8000471a:	f80b1ce3          	bnez	s6,800046b2 <install_trans+0x40>
    8000471e:	b769                	j	800046a8 <install_trans+0x36>
}
    80004720:	70e2                	ld	ra,56(sp)
    80004722:	7442                	ld	s0,48(sp)
    80004724:	74a2                	ld	s1,40(sp)
    80004726:	7902                	ld	s2,32(sp)
    80004728:	69e2                	ld	s3,24(sp)
    8000472a:	6a42                	ld	s4,16(sp)
    8000472c:	6aa2                	ld	s5,8(sp)
    8000472e:	6b02                	ld	s6,0(sp)
    80004730:	6121                	addi	sp,sp,64
    80004732:	8082                	ret
    80004734:	8082                	ret

0000000080004736 <initlog>:
{
    80004736:	7179                	addi	sp,sp,-48
    80004738:	f406                	sd	ra,40(sp)
    8000473a:	f022                	sd	s0,32(sp)
    8000473c:	ec26                	sd	s1,24(sp)
    8000473e:	e84a                	sd	s2,16(sp)
    80004740:	e44e                	sd	s3,8(sp)
    80004742:	1800                	addi	s0,sp,48
    80004744:	892a                	mv	s2,a0
    80004746:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004748:	000d9497          	auipc	s1,0xd9
    8000474c:	b2848493          	addi	s1,s1,-1240 # 800dd270 <log>
    80004750:	00004597          	auipc	a1,0x4
    80004754:	09058593          	addi	a1,a1,144 # 800087e0 <syscalls+0x1e8>
    80004758:	8526                	mv	a0,s1
    8000475a:	ffffc097          	auipc	ra,0xffffc
    8000475e:	3fa080e7          	jalr	1018(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004762:	0149a583          	lw	a1,20(s3)
    80004766:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004768:	0109a783          	lw	a5,16(s3)
    8000476c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000476e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004772:	854a                	mv	a0,s2
    80004774:	fffff097          	auipc	ra,0xfffff
    80004778:	e92080e7          	jalr	-366(ra) # 80003606 <bread>
  log.lh.n = lh->n;
    8000477c:	4d3c                	lw	a5,88(a0)
    8000477e:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004780:	02f05563          	blez	a5,800047aa <initlog+0x74>
    80004784:	05c50713          	addi	a4,a0,92
    80004788:	000d9697          	auipc	a3,0xd9
    8000478c:	b1868693          	addi	a3,a3,-1256 # 800dd2a0 <log+0x30>
    80004790:	37fd                	addiw	a5,a5,-1
    80004792:	1782                	slli	a5,a5,0x20
    80004794:	9381                	srli	a5,a5,0x20
    80004796:	078a                	slli	a5,a5,0x2
    80004798:	06050613          	addi	a2,a0,96
    8000479c:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000479e:	4310                	lw	a2,0(a4)
    800047a0:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800047a2:	0711                	addi	a4,a4,4
    800047a4:	0691                	addi	a3,a3,4
    800047a6:	fef71ce3          	bne	a4,a5,8000479e <initlog+0x68>
  brelse(buf);
    800047aa:	fffff097          	auipc	ra,0xfffff
    800047ae:	f8c080e7          	jalr	-116(ra) # 80003736 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800047b2:	4505                	li	a0,1
    800047b4:	00000097          	auipc	ra,0x0
    800047b8:	ebe080e7          	jalr	-322(ra) # 80004672 <install_trans>
  log.lh.n = 0;
    800047bc:	000d9797          	auipc	a5,0xd9
    800047c0:	ae07a023          	sw	zero,-1312(a5) # 800dd29c <log+0x2c>
  write_head(); // clear the log
    800047c4:	00000097          	auipc	ra,0x0
    800047c8:	e34080e7          	jalr	-460(ra) # 800045f8 <write_head>
}
    800047cc:	70a2                	ld	ra,40(sp)
    800047ce:	7402                	ld	s0,32(sp)
    800047d0:	64e2                	ld	s1,24(sp)
    800047d2:	6942                	ld	s2,16(sp)
    800047d4:	69a2                	ld	s3,8(sp)
    800047d6:	6145                	addi	sp,sp,48
    800047d8:	8082                	ret

00000000800047da <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800047da:	1101                	addi	sp,sp,-32
    800047dc:	ec06                	sd	ra,24(sp)
    800047de:	e822                	sd	s0,16(sp)
    800047e0:	e426                	sd	s1,8(sp)
    800047e2:	e04a                	sd	s2,0(sp)
    800047e4:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800047e6:	000d9517          	auipc	a0,0xd9
    800047ea:	a8a50513          	addi	a0,a0,-1398 # 800dd270 <log>
    800047ee:	ffffc097          	auipc	ra,0xffffc
    800047f2:	3f6080e7          	jalr	1014(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800047f6:	000d9497          	auipc	s1,0xd9
    800047fa:	a7a48493          	addi	s1,s1,-1414 # 800dd270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800047fe:	4979                	li	s2,30
    80004800:	a039                	j	8000480e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004802:	85a6                	mv	a1,s1
    80004804:	8526                	mv	a0,s1
    80004806:	ffffe097          	auipc	ra,0xffffe
    8000480a:	96e080e7          	jalr	-1682(ra) # 80002174 <sleep>
    if(log.committing){
    8000480e:	50dc                	lw	a5,36(s1)
    80004810:	fbed                	bnez	a5,80004802 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004812:	509c                	lw	a5,32(s1)
    80004814:	0017871b          	addiw	a4,a5,1
    80004818:	0007069b          	sext.w	a3,a4
    8000481c:	0027179b          	slliw	a5,a4,0x2
    80004820:	9fb9                	addw	a5,a5,a4
    80004822:	0017979b          	slliw	a5,a5,0x1
    80004826:	54d8                	lw	a4,44(s1)
    80004828:	9fb9                	addw	a5,a5,a4
    8000482a:	00f95963          	bge	s2,a5,8000483c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000482e:	85a6                	mv	a1,s1
    80004830:	8526                	mv	a0,s1
    80004832:	ffffe097          	auipc	ra,0xffffe
    80004836:	942080e7          	jalr	-1726(ra) # 80002174 <sleep>
    8000483a:	bfd1                	j	8000480e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000483c:	000d9517          	auipc	a0,0xd9
    80004840:	a3450513          	addi	a0,a0,-1484 # 800dd270 <log>
    80004844:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004846:	ffffc097          	auipc	ra,0xffffc
    8000484a:	452080e7          	jalr	1106(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000484e:	60e2                	ld	ra,24(sp)
    80004850:	6442                	ld	s0,16(sp)
    80004852:	64a2                	ld	s1,8(sp)
    80004854:	6902                	ld	s2,0(sp)
    80004856:	6105                	addi	sp,sp,32
    80004858:	8082                	ret

000000008000485a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000485a:	7139                	addi	sp,sp,-64
    8000485c:	fc06                	sd	ra,56(sp)
    8000485e:	f822                	sd	s0,48(sp)
    80004860:	f426                	sd	s1,40(sp)
    80004862:	f04a                	sd	s2,32(sp)
    80004864:	ec4e                	sd	s3,24(sp)
    80004866:	e852                	sd	s4,16(sp)
    80004868:	e456                	sd	s5,8(sp)
    8000486a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000486c:	000d9497          	auipc	s1,0xd9
    80004870:	a0448493          	addi	s1,s1,-1532 # 800dd270 <log>
    80004874:	8526                	mv	a0,s1
    80004876:	ffffc097          	auipc	ra,0xffffc
    8000487a:	36e080e7          	jalr	878(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000487e:	509c                	lw	a5,32(s1)
    80004880:	37fd                	addiw	a5,a5,-1
    80004882:	0007891b          	sext.w	s2,a5
    80004886:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004888:	50dc                	lw	a5,36(s1)
    8000488a:	efb9                	bnez	a5,800048e8 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000488c:	06091663          	bnez	s2,800048f8 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004890:	000d9497          	auipc	s1,0xd9
    80004894:	9e048493          	addi	s1,s1,-1568 # 800dd270 <log>
    80004898:	4785                	li	a5,1
    8000489a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000489c:	8526                	mv	a0,s1
    8000489e:	ffffc097          	auipc	ra,0xffffc
    800048a2:	3fa080e7          	jalr	1018(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800048a6:	54dc                	lw	a5,44(s1)
    800048a8:	06f04763          	bgtz	a5,80004916 <end_op+0xbc>
    acquire(&log.lock);
    800048ac:	000d9497          	auipc	s1,0xd9
    800048b0:	9c448493          	addi	s1,s1,-1596 # 800dd270 <log>
    800048b4:	8526                	mv	a0,s1
    800048b6:	ffffc097          	auipc	ra,0xffffc
    800048ba:	32e080e7          	jalr	814(ra) # 80000be4 <acquire>
    log.committing = 0;
    800048be:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800048c2:	8526                	mv	a0,s1
    800048c4:	ffffe097          	auipc	ra,0xffffe
    800048c8:	b80080e7          	jalr	-1152(ra) # 80002444 <wakeup>
    release(&log.lock);
    800048cc:	8526                	mv	a0,s1
    800048ce:	ffffc097          	auipc	ra,0xffffc
    800048d2:	3ca080e7          	jalr	970(ra) # 80000c98 <release>
}
    800048d6:	70e2                	ld	ra,56(sp)
    800048d8:	7442                	ld	s0,48(sp)
    800048da:	74a2                	ld	s1,40(sp)
    800048dc:	7902                	ld	s2,32(sp)
    800048de:	69e2                	ld	s3,24(sp)
    800048e0:	6a42                	ld	s4,16(sp)
    800048e2:	6aa2                	ld	s5,8(sp)
    800048e4:	6121                	addi	sp,sp,64
    800048e6:	8082                	ret
    panic("log.committing");
    800048e8:	00004517          	auipc	a0,0x4
    800048ec:	f0050513          	addi	a0,a0,-256 # 800087e8 <syscalls+0x1f0>
    800048f0:	ffffc097          	auipc	ra,0xffffc
    800048f4:	c4e080e7          	jalr	-946(ra) # 8000053e <panic>
    wakeup(&log);
    800048f8:	000d9497          	auipc	s1,0xd9
    800048fc:	97848493          	addi	s1,s1,-1672 # 800dd270 <log>
    80004900:	8526                	mv	a0,s1
    80004902:	ffffe097          	auipc	ra,0xffffe
    80004906:	b42080e7          	jalr	-1214(ra) # 80002444 <wakeup>
  release(&log.lock);
    8000490a:	8526                	mv	a0,s1
    8000490c:	ffffc097          	auipc	ra,0xffffc
    80004910:	38c080e7          	jalr	908(ra) # 80000c98 <release>
  if(do_commit){
    80004914:	b7c9                	j	800048d6 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004916:	000d9a97          	auipc	s5,0xd9
    8000491a:	98aa8a93          	addi	s5,s5,-1654 # 800dd2a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000491e:	000d9a17          	auipc	s4,0xd9
    80004922:	952a0a13          	addi	s4,s4,-1710 # 800dd270 <log>
    80004926:	018a2583          	lw	a1,24(s4)
    8000492a:	012585bb          	addw	a1,a1,s2
    8000492e:	2585                	addiw	a1,a1,1
    80004930:	028a2503          	lw	a0,40(s4)
    80004934:	fffff097          	auipc	ra,0xfffff
    80004938:	cd2080e7          	jalr	-814(ra) # 80003606 <bread>
    8000493c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000493e:	000aa583          	lw	a1,0(s5)
    80004942:	028a2503          	lw	a0,40(s4)
    80004946:	fffff097          	auipc	ra,0xfffff
    8000494a:	cc0080e7          	jalr	-832(ra) # 80003606 <bread>
    8000494e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004950:	40000613          	li	a2,1024
    80004954:	05850593          	addi	a1,a0,88
    80004958:	05848513          	addi	a0,s1,88
    8000495c:	ffffc097          	auipc	ra,0xffffc
    80004960:	3e4080e7          	jalr	996(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004964:	8526                	mv	a0,s1
    80004966:	fffff097          	auipc	ra,0xfffff
    8000496a:	d92080e7          	jalr	-622(ra) # 800036f8 <bwrite>
    brelse(from);
    8000496e:	854e                	mv	a0,s3
    80004970:	fffff097          	auipc	ra,0xfffff
    80004974:	dc6080e7          	jalr	-570(ra) # 80003736 <brelse>
    brelse(to);
    80004978:	8526                	mv	a0,s1
    8000497a:	fffff097          	auipc	ra,0xfffff
    8000497e:	dbc080e7          	jalr	-580(ra) # 80003736 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004982:	2905                	addiw	s2,s2,1
    80004984:	0a91                	addi	s5,s5,4
    80004986:	02ca2783          	lw	a5,44(s4)
    8000498a:	f8f94ee3          	blt	s2,a5,80004926 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000498e:	00000097          	auipc	ra,0x0
    80004992:	c6a080e7          	jalr	-918(ra) # 800045f8 <write_head>
    install_trans(0); // Now install writes to home locations
    80004996:	4501                	li	a0,0
    80004998:	00000097          	auipc	ra,0x0
    8000499c:	cda080e7          	jalr	-806(ra) # 80004672 <install_trans>
    log.lh.n = 0;
    800049a0:	000d9797          	auipc	a5,0xd9
    800049a4:	8e07ae23          	sw	zero,-1796(a5) # 800dd29c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800049a8:	00000097          	auipc	ra,0x0
    800049ac:	c50080e7          	jalr	-944(ra) # 800045f8 <write_head>
    800049b0:	bdf5                	j	800048ac <end_op+0x52>

00000000800049b2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800049b2:	1101                	addi	sp,sp,-32
    800049b4:	ec06                	sd	ra,24(sp)
    800049b6:	e822                	sd	s0,16(sp)
    800049b8:	e426                	sd	s1,8(sp)
    800049ba:	e04a                	sd	s2,0(sp)
    800049bc:	1000                	addi	s0,sp,32
    800049be:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800049c0:	000d9917          	auipc	s2,0xd9
    800049c4:	8b090913          	addi	s2,s2,-1872 # 800dd270 <log>
    800049c8:	854a                	mv	a0,s2
    800049ca:	ffffc097          	auipc	ra,0xffffc
    800049ce:	21a080e7          	jalr	538(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800049d2:	02c92603          	lw	a2,44(s2)
    800049d6:	47f5                	li	a5,29
    800049d8:	06c7c563          	blt	a5,a2,80004a42 <log_write+0x90>
    800049dc:	000d9797          	auipc	a5,0xd9
    800049e0:	8b07a783          	lw	a5,-1872(a5) # 800dd28c <log+0x1c>
    800049e4:	37fd                	addiw	a5,a5,-1
    800049e6:	04f65e63          	bge	a2,a5,80004a42 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800049ea:	000d9797          	auipc	a5,0xd9
    800049ee:	8a67a783          	lw	a5,-1882(a5) # 800dd290 <log+0x20>
    800049f2:	06f05063          	blez	a5,80004a52 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800049f6:	4781                	li	a5,0
    800049f8:	06c05563          	blez	a2,80004a62 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800049fc:	44cc                	lw	a1,12(s1)
    800049fe:	000d9717          	auipc	a4,0xd9
    80004a02:	8a270713          	addi	a4,a4,-1886 # 800dd2a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004a06:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a08:	4314                	lw	a3,0(a4)
    80004a0a:	04b68c63          	beq	a3,a1,80004a62 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004a0e:	2785                	addiw	a5,a5,1
    80004a10:	0711                	addi	a4,a4,4
    80004a12:	fef61be3          	bne	a2,a5,80004a08 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004a16:	0621                	addi	a2,a2,8
    80004a18:	060a                	slli	a2,a2,0x2
    80004a1a:	000d9797          	auipc	a5,0xd9
    80004a1e:	85678793          	addi	a5,a5,-1962 # 800dd270 <log>
    80004a22:	963e                	add	a2,a2,a5
    80004a24:	44dc                	lw	a5,12(s1)
    80004a26:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004a28:	8526                	mv	a0,s1
    80004a2a:	fffff097          	auipc	ra,0xfffff
    80004a2e:	daa080e7          	jalr	-598(ra) # 800037d4 <bpin>
    log.lh.n++;
    80004a32:	000d9717          	auipc	a4,0xd9
    80004a36:	83e70713          	addi	a4,a4,-1986 # 800dd270 <log>
    80004a3a:	575c                	lw	a5,44(a4)
    80004a3c:	2785                	addiw	a5,a5,1
    80004a3e:	d75c                	sw	a5,44(a4)
    80004a40:	a835                	j	80004a7c <log_write+0xca>
    panic("too big a transaction");
    80004a42:	00004517          	auipc	a0,0x4
    80004a46:	db650513          	addi	a0,a0,-586 # 800087f8 <syscalls+0x200>
    80004a4a:	ffffc097          	auipc	ra,0xffffc
    80004a4e:	af4080e7          	jalr	-1292(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004a52:	00004517          	auipc	a0,0x4
    80004a56:	dbe50513          	addi	a0,a0,-578 # 80008810 <syscalls+0x218>
    80004a5a:	ffffc097          	auipc	ra,0xffffc
    80004a5e:	ae4080e7          	jalr	-1308(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004a62:	00878713          	addi	a4,a5,8
    80004a66:	00271693          	slli	a3,a4,0x2
    80004a6a:	000d9717          	auipc	a4,0xd9
    80004a6e:	80670713          	addi	a4,a4,-2042 # 800dd270 <log>
    80004a72:	9736                	add	a4,a4,a3
    80004a74:	44d4                	lw	a3,12(s1)
    80004a76:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004a78:	faf608e3          	beq	a2,a5,80004a28 <log_write+0x76>
  }
  release(&log.lock);
    80004a7c:	000d8517          	auipc	a0,0xd8
    80004a80:	7f450513          	addi	a0,a0,2036 # 800dd270 <log>
    80004a84:	ffffc097          	auipc	ra,0xffffc
    80004a88:	214080e7          	jalr	532(ra) # 80000c98 <release>
}
    80004a8c:	60e2                	ld	ra,24(sp)
    80004a8e:	6442                	ld	s0,16(sp)
    80004a90:	64a2                	ld	s1,8(sp)
    80004a92:	6902                	ld	s2,0(sp)
    80004a94:	6105                	addi	sp,sp,32
    80004a96:	8082                	ret

0000000080004a98 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004a98:	1101                	addi	sp,sp,-32
    80004a9a:	ec06                	sd	ra,24(sp)
    80004a9c:	e822                	sd	s0,16(sp)
    80004a9e:	e426                	sd	s1,8(sp)
    80004aa0:	e04a                	sd	s2,0(sp)
    80004aa2:	1000                	addi	s0,sp,32
    80004aa4:	84aa                	mv	s1,a0
    80004aa6:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004aa8:	00004597          	auipc	a1,0x4
    80004aac:	d8858593          	addi	a1,a1,-632 # 80008830 <syscalls+0x238>
    80004ab0:	0521                	addi	a0,a0,8
    80004ab2:	ffffc097          	auipc	ra,0xffffc
    80004ab6:	0a2080e7          	jalr	162(ra) # 80000b54 <initlock>
  lk->name = name;
    80004aba:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004abe:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004ac2:	0204a423          	sw	zero,40(s1)
}
    80004ac6:	60e2                	ld	ra,24(sp)
    80004ac8:	6442                	ld	s0,16(sp)
    80004aca:	64a2                	ld	s1,8(sp)
    80004acc:	6902                	ld	s2,0(sp)
    80004ace:	6105                	addi	sp,sp,32
    80004ad0:	8082                	ret

0000000080004ad2 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004ad2:	1101                	addi	sp,sp,-32
    80004ad4:	ec06                	sd	ra,24(sp)
    80004ad6:	e822                	sd	s0,16(sp)
    80004ad8:	e426                	sd	s1,8(sp)
    80004ada:	e04a                	sd	s2,0(sp)
    80004adc:	1000                	addi	s0,sp,32
    80004ade:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004ae0:	00850913          	addi	s2,a0,8
    80004ae4:	854a                	mv	a0,s2
    80004ae6:	ffffc097          	auipc	ra,0xffffc
    80004aea:	0fe080e7          	jalr	254(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004aee:	409c                	lw	a5,0(s1)
    80004af0:	cb89                	beqz	a5,80004b02 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004af2:	85ca                	mv	a1,s2
    80004af4:	8526                	mv	a0,s1
    80004af6:	ffffd097          	auipc	ra,0xffffd
    80004afa:	67e080e7          	jalr	1662(ra) # 80002174 <sleep>
  while (lk->locked) {
    80004afe:	409c                	lw	a5,0(s1)
    80004b00:	fbed                	bnez	a5,80004af2 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004b02:	4785                	li	a5,1
    80004b04:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004b06:	ffffd097          	auipc	ra,0xffffd
    80004b0a:	eca080e7          	jalr	-310(ra) # 800019d0 <myproc>
    80004b0e:	591c                	lw	a5,48(a0)
    80004b10:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004b12:	854a                	mv	a0,s2
    80004b14:	ffffc097          	auipc	ra,0xffffc
    80004b18:	184080e7          	jalr	388(ra) # 80000c98 <release>
}
    80004b1c:	60e2                	ld	ra,24(sp)
    80004b1e:	6442                	ld	s0,16(sp)
    80004b20:	64a2                	ld	s1,8(sp)
    80004b22:	6902                	ld	s2,0(sp)
    80004b24:	6105                	addi	sp,sp,32
    80004b26:	8082                	ret

0000000080004b28 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004b28:	1101                	addi	sp,sp,-32
    80004b2a:	ec06                	sd	ra,24(sp)
    80004b2c:	e822                	sd	s0,16(sp)
    80004b2e:	e426                	sd	s1,8(sp)
    80004b30:	e04a                	sd	s2,0(sp)
    80004b32:	1000                	addi	s0,sp,32
    80004b34:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b36:	00850913          	addi	s2,a0,8
    80004b3a:	854a                	mv	a0,s2
    80004b3c:	ffffc097          	auipc	ra,0xffffc
    80004b40:	0a8080e7          	jalr	168(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004b44:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b48:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004b4c:	8526                	mv	a0,s1
    80004b4e:	ffffe097          	auipc	ra,0xffffe
    80004b52:	8f6080e7          	jalr	-1802(ra) # 80002444 <wakeup>
  release(&lk->lk);
    80004b56:	854a                	mv	a0,s2
    80004b58:	ffffc097          	auipc	ra,0xffffc
    80004b5c:	140080e7          	jalr	320(ra) # 80000c98 <release>
}
    80004b60:	60e2                	ld	ra,24(sp)
    80004b62:	6442                	ld	s0,16(sp)
    80004b64:	64a2                	ld	s1,8(sp)
    80004b66:	6902                	ld	s2,0(sp)
    80004b68:	6105                	addi	sp,sp,32
    80004b6a:	8082                	ret

0000000080004b6c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004b6c:	7179                	addi	sp,sp,-48
    80004b6e:	f406                	sd	ra,40(sp)
    80004b70:	f022                	sd	s0,32(sp)
    80004b72:	ec26                	sd	s1,24(sp)
    80004b74:	e84a                	sd	s2,16(sp)
    80004b76:	e44e                	sd	s3,8(sp)
    80004b78:	1800                	addi	s0,sp,48
    80004b7a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004b7c:	00850913          	addi	s2,a0,8
    80004b80:	854a                	mv	a0,s2
    80004b82:	ffffc097          	auipc	ra,0xffffc
    80004b86:	062080e7          	jalr	98(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b8a:	409c                	lw	a5,0(s1)
    80004b8c:	ef99                	bnez	a5,80004baa <holdingsleep+0x3e>
    80004b8e:	4481                	li	s1,0
  release(&lk->lk);
    80004b90:	854a                	mv	a0,s2
    80004b92:	ffffc097          	auipc	ra,0xffffc
    80004b96:	106080e7          	jalr	262(ra) # 80000c98 <release>
  return r;
}
    80004b9a:	8526                	mv	a0,s1
    80004b9c:	70a2                	ld	ra,40(sp)
    80004b9e:	7402                	ld	s0,32(sp)
    80004ba0:	64e2                	ld	s1,24(sp)
    80004ba2:	6942                	ld	s2,16(sp)
    80004ba4:	69a2                	ld	s3,8(sp)
    80004ba6:	6145                	addi	sp,sp,48
    80004ba8:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004baa:	0284a983          	lw	s3,40(s1)
    80004bae:	ffffd097          	auipc	ra,0xffffd
    80004bb2:	e22080e7          	jalr	-478(ra) # 800019d0 <myproc>
    80004bb6:	5904                	lw	s1,48(a0)
    80004bb8:	413484b3          	sub	s1,s1,s3
    80004bbc:	0014b493          	seqz	s1,s1
    80004bc0:	bfc1                	j	80004b90 <holdingsleep+0x24>

0000000080004bc2 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004bc2:	1141                	addi	sp,sp,-16
    80004bc4:	e406                	sd	ra,8(sp)
    80004bc6:	e022                	sd	s0,0(sp)
    80004bc8:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004bca:	00004597          	auipc	a1,0x4
    80004bce:	c7658593          	addi	a1,a1,-906 # 80008840 <syscalls+0x248>
    80004bd2:	000d8517          	auipc	a0,0xd8
    80004bd6:	7e650513          	addi	a0,a0,2022 # 800dd3b8 <ftable>
    80004bda:	ffffc097          	auipc	ra,0xffffc
    80004bde:	f7a080e7          	jalr	-134(ra) # 80000b54 <initlock>
}
    80004be2:	60a2                	ld	ra,8(sp)
    80004be4:	6402                	ld	s0,0(sp)
    80004be6:	0141                	addi	sp,sp,16
    80004be8:	8082                	ret

0000000080004bea <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004bea:	1101                	addi	sp,sp,-32
    80004bec:	ec06                	sd	ra,24(sp)
    80004bee:	e822                	sd	s0,16(sp)
    80004bf0:	e426                	sd	s1,8(sp)
    80004bf2:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004bf4:	000d8517          	auipc	a0,0xd8
    80004bf8:	7c450513          	addi	a0,a0,1988 # 800dd3b8 <ftable>
    80004bfc:	ffffc097          	auipc	ra,0xffffc
    80004c00:	fe8080e7          	jalr	-24(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c04:	000d8497          	auipc	s1,0xd8
    80004c08:	7cc48493          	addi	s1,s1,1996 # 800dd3d0 <ftable+0x18>
    80004c0c:	000d9717          	auipc	a4,0xd9
    80004c10:	76470713          	addi	a4,a4,1892 # 800de370 <ftable+0xfb8>
    if(f->ref == 0){
    80004c14:	40dc                	lw	a5,4(s1)
    80004c16:	cf99                	beqz	a5,80004c34 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c18:	02848493          	addi	s1,s1,40
    80004c1c:	fee49ce3          	bne	s1,a4,80004c14 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004c20:	000d8517          	auipc	a0,0xd8
    80004c24:	79850513          	addi	a0,a0,1944 # 800dd3b8 <ftable>
    80004c28:	ffffc097          	auipc	ra,0xffffc
    80004c2c:	070080e7          	jalr	112(ra) # 80000c98 <release>
  return 0;
    80004c30:	4481                	li	s1,0
    80004c32:	a819                	j	80004c48 <filealloc+0x5e>
      f->ref = 1;
    80004c34:	4785                	li	a5,1
    80004c36:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004c38:	000d8517          	auipc	a0,0xd8
    80004c3c:	78050513          	addi	a0,a0,1920 # 800dd3b8 <ftable>
    80004c40:	ffffc097          	auipc	ra,0xffffc
    80004c44:	058080e7          	jalr	88(ra) # 80000c98 <release>
}
    80004c48:	8526                	mv	a0,s1
    80004c4a:	60e2                	ld	ra,24(sp)
    80004c4c:	6442                	ld	s0,16(sp)
    80004c4e:	64a2                	ld	s1,8(sp)
    80004c50:	6105                	addi	sp,sp,32
    80004c52:	8082                	ret

0000000080004c54 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004c54:	1101                	addi	sp,sp,-32
    80004c56:	ec06                	sd	ra,24(sp)
    80004c58:	e822                	sd	s0,16(sp)
    80004c5a:	e426                	sd	s1,8(sp)
    80004c5c:	1000                	addi	s0,sp,32
    80004c5e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004c60:	000d8517          	auipc	a0,0xd8
    80004c64:	75850513          	addi	a0,a0,1880 # 800dd3b8 <ftable>
    80004c68:	ffffc097          	auipc	ra,0xffffc
    80004c6c:	f7c080e7          	jalr	-132(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004c70:	40dc                	lw	a5,4(s1)
    80004c72:	02f05263          	blez	a5,80004c96 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004c76:	2785                	addiw	a5,a5,1
    80004c78:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004c7a:	000d8517          	auipc	a0,0xd8
    80004c7e:	73e50513          	addi	a0,a0,1854 # 800dd3b8 <ftable>
    80004c82:	ffffc097          	auipc	ra,0xffffc
    80004c86:	016080e7          	jalr	22(ra) # 80000c98 <release>
  return f;
}
    80004c8a:	8526                	mv	a0,s1
    80004c8c:	60e2                	ld	ra,24(sp)
    80004c8e:	6442                	ld	s0,16(sp)
    80004c90:	64a2                	ld	s1,8(sp)
    80004c92:	6105                	addi	sp,sp,32
    80004c94:	8082                	ret
    panic("filedup");
    80004c96:	00004517          	auipc	a0,0x4
    80004c9a:	bb250513          	addi	a0,a0,-1102 # 80008848 <syscalls+0x250>
    80004c9e:	ffffc097          	auipc	ra,0xffffc
    80004ca2:	8a0080e7          	jalr	-1888(ra) # 8000053e <panic>

0000000080004ca6 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004ca6:	7139                	addi	sp,sp,-64
    80004ca8:	fc06                	sd	ra,56(sp)
    80004caa:	f822                	sd	s0,48(sp)
    80004cac:	f426                	sd	s1,40(sp)
    80004cae:	f04a                	sd	s2,32(sp)
    80004cb0:	ec4e                	sd	s3,24(sp)
    80004cb2:	e852                	sd	s4,16(sp)
    80004cb4:	e456                	sd	s5,8(sp)
    80004cb6:	0080                	addi	s0,sp,64
    80004cb8:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004cba:	000d8517          	auipc	a0,0xd8
    80004cbe:	6fe50513          	addi	a0,a0,1790 # 800dd3b8 <ftable>
    80004cc2:	ffffc097          	auipc	ra,0xffffc
    80004cc6:	f22080e7          	jalr	-222(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004cca:	40dc                	lw	a5,4(s1)
    80004ccc:	06f05163          	blez	a5,80004d2e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004cd0:	37fd                	addiw	a5,a5,-1
    80004cd2:	0007871b          	sext.w	a4,a5
    80004cd6:	c0dc                	sw	a5,4(s1)
    80004cd8:	06e04363          	bgtz	a4,80004d3e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004cdc:	0004a903          	lw	s2,0(s1)
    80004ce0:	0094ca83          	lbu	s5,9(s1)
    80004ce4:	0104ba03          	ld	s4,16(s1)
    80004ce8:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004cec:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004cf0:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004cf4:	000d8517          	auipc	a0,0xd8
    80004cf8:	6c450513          	addi	a0,a0,1732 # 800dd3b8 <ftable>
    80004cfc:	ffffc097          	auipc	ra,0xffffc
    80004d00:	f9c080e7          	jalr	-100(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004d04:	4785                	li	a5,1
    80004d06:	04f90d63          	beq	s2,a5,80004d60 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004d0a:	3979                	addiw	s2,s2,-2
    80004d0c:	4785                	li	a5,1
    80004d0e:	0527e063          	bltu	a5,s2,80004d4e <fileclose+0xa8>
    begin_op();
    80004d12:	00000097          	auipc	ra,0x0
    80004d16:	ac8080e7          	jalr	-1336(ra) # 800047da <begin_op>
    iput(ff.ip);
    80004d1a:	854e                	mv	a0,s3
    80004d1c:	fffff097          	auipc	ra,0xfffff
    80004d20:	2a6080e7          	jalr	678(ra) # 80003fc2 <iput>
    end_op();
    80004d24:	00000097          	auipc	ra,0x0
    80004d28:	b36080e7          	jalr	-1226(ra) # 8000485a <end_op>
    80004d2c:	a00d                	j	80004d4e <fileclose+0xa8>
    panic("fileclose");
    80004d2e:	00004517          	auipc	a0,0x4
    80004d32:	b2250513          	addi	a0,a0,-1246 # 80008850 <syscalls+0x258>
    80004d36:	ffffc097          	auipc	ra,0xffffc
    80004d3a:	808080e7          	jalr	-2040(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004d3e:	000d8517          	auipc	a0,0xd8
    80004d42:	67a50513          	addi	a0,a0,1658 # 800dd3b8 <ftable>
    80004d46:	ffffc097          	auipc	ra,0xffffc
    80004d4a:	f52080e7          	jalr	-174(ra) # 80000c98 <release>
  }
}
    80004d4e:	70e2                	ld	ra,56(sp)
    80004d50:	7442                	ld	s0,48(sp)
    80004d52:	74a2                	ld	s1,40(sp)
    80004d54:	7902                	ld	s2,32(sp)
    80004d56:	69e2                	ld	s3,24(sp)
    80004d58:	6a42                	ld	s4,16(sp)
    80004d5a:	6aa2                	ld	s5,8(sp)
    80004d5c:	6121                	addi	sp,sp,64
    80004d5e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004d60:	85d6                	mv	a1,s5
    80004d62:	8552                	mv	a0,s4
    80004d64:	00000097          	auipc	ra,0x0
    80004d68:	34c080e7          	jalr	844(ra) # 800050b0 <pipeclose>
    80004d6c:	b7cd                	j	80004d4e <fileclose+0xa8>

0000000080004d6e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004d6e:	715d                	addi	sp,sp,-80
    80004d70:	e486                	sd	ra,72(sp)
    80004d72:	e0a2                	sd	s0,64(sp)
    80004d74:	fc26                	sd	s1,56(sp)
    80004d76:	f84a                	sd	s2,48(sp)
    80004d78:	f44e                	sd	s3,40(sp)
    80004d7a:	0880                	addi	s0,sp,80
    80004d7c:	84aa                	mv	s1,a0
    80004d7e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004d80:	ffffd097          	auipc	ra,0xffffd
    80004d84:	c50080e7          	jalr	-944(ra) # 800019d0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004d88:	409c                	lw	a5,0(s1)
    80004d8a:	37f9                	addiw	a5,a5,-2
    80004d8c:	4705                	li	a4,1
    80004d8e:	04f76763          	bltu	a4,a5,80004ddc <filestat+0x6e>
    80004d92:	892a                	mv	s2,a0
    ilock(f->ip);
    80004d94:	6c88                	ld	a0,24(s1)
    80004d96:	fffff097          	auipc	ra,0xfffff
    80004d9a:	072080e7          	jalr	114(ra) # 80003e08 <ilock>
    stati(f->ip, &st);
    80004d9e:	fb840593          	addi	a1,s0,-72
    80004da2:	6c88                	ld	a0,24(s1)
    80004da4:	fffff097          	auipc	ra,0xfffff
    80004da8:	2ee080e7          	jalr	750(ra) # 80004092 <stati>
    iunlock(f->ip);
    80004dac:	6c88                	ld	a0,24(s1)
    80004dae:	fffff097          	auipc	ra,0xfffff
    80004db2:	11c080e7          	jalr	284(ra) # 80003eca <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004db6:	46e1                	li	a3,24
    80004db8:	fb840613          	addi	a2,s0,-72
    80004dbc:	85ce                	mv	a1,s3
    80004dbe:	05093503          	ld	a0,80(s2)
    80004dc2:	ffffd097          	auipc	ra,0xffffd
    80004dc6:	8b0080e7          	jalr	-1872(ra) # 80001672 <copyout>
    80004dca:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004dce:	60a6                	ld	ra,72(sp)
    80004dd0:	6406                	ld	s0,64(sp)
    80004dd2:	74e2                	ld	s1,56(sp)
    80004dd4:	7942                	ld	s2,48(sp)
    80004dd6:	79a2                	ld	s3,40(sp)
    80004dd8:	6161                	addi	sp,sp,80
    80004dda:	8082                	ret
  return -1;
    80004ddc:	557d                	li	a0,-1
    80004dde:	bfc5                	j	80004dce <filestat+0x60>

0000000080004de0 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004de0:	7179                	addi	sp,sp,-48
    80004de2:	f406                	sd	ra,40(sp)
    80004de4:	f022                	sd	s0,32(sp)
    80004de6:	ec26                	sd	s1,24(sp)
    80004de8:	e84a                	sd	s2,16(sp)
    80004dea:	e44e                	sd	s3,8(sp)
    80004dec:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004dee:	00854783          	lbu	a5,8(a0)
    80004df2:	c3d5                	beqz	a5,80004e96 <fileread+0xb6>
    80004df4:	84aa                	mv	s1,a0
    80004df6:	89ae                	mv	s3,a1
    80004df8:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004dfa:	411c                	lw	a5,0(a0)
    80004dfc:	4705                	li	a4,1
    80004dfe:	04e78963          	beq	a5,a4,80004e50 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e02:	470d                	li	a4,3
    80004e04:	04e78d63          	beq	a5,a4,80004e5e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e08:	4709                	li	a4,2
    80004e0a:	06e79e63          	bne	a5,a4,80004e86 <fileread+0xa6>
    ilock(f->ip);
    80004e0e:	6d08                	ld	a0,24(a0)
    80004e10:	fffff097          	auipc	ra,0xfffff
    80004e14:	ff8080e7          	jalr	-8(ra) # 80003e08 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004e18:	874a                	mv	a4,s2
    80004e1a:	5094                	lw	a3,32(s1)
    80004e1c:	864e                	mv	a2,s3
    80004e1e:	4585                	li	a1,1
    80004e20:	6c88                	ld	a0,24(s1)
    80004e22:	fffff097          	auipc	ra,0xfffff
    80004e26:	29a080e7          	jalr	666(ra) # 800040bc <readi>
    80004e2a:	892a                	mv	s2,a0
    80004e2c:	00a05563          	blez	a0,80004e36 <fileread+0x56>
      f->off += r;
    80004e30:	509c                	lw	a5,32(s1)
    80004e32:	9fa9                	addw	a5,a5,a0
    80004e34:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004e36:	6c88                	ld	a0,24(s1)
    80004e38:	fffff097          	auipc	ra,0xfffff
    80004e3c:	092080e7          	jalr	146(ra) # 80003eca <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004e40:	854a                	mv	a0,s2
    80004e42:	70a2                	ld	ra,40(sp)
    80004e44:	7402                	ld	s0,32(sp)
    80004e46:	64e2                	ld	s1,24(sp)
    80004e48:	6942                	ld	s2,16(sp)
    80004e4a:	69a2                	ld	s3,8(sp)
    80004e4c:	6145                	addi	sp,sp,48
    80004e4e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004e50:	6908                	ld	a0,16(a0)
    80004e52:	00000097          	auipc	ra,0x0
    80004e56:	3c8080e7          	jalr	968(ra) # 8000521a <piperead>
    80004e5a:	892a                	mv	s2,a0
    80004e5c:	b7d5                	j	80004e40 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004e5e:	02451783          	lh	a5,36(a0)
    80004e62:	03079693          	slli	a3,a5,0x30
    80004e66:	92c1                	srli	a3,a3,0x30
    80004e68:	4725                	li	a4,9
    80004e6a:	02d76863          	bltu	a4,a3,80004e9a <fileread+0xba>
    80004e6e:	0792                	slli	a5,a5,0x4
    80004e70:	000d8717          	auipc	a4,0xd8
    80004e74:	4a870713          	addi	a4,a4,1192 # 800dd318 <devsw>
    80004e78:	97ba                	add	a5,a5,a4
    80004e7a:	639c                	ld	a5,0(a5)
    80004e7c:	c38d                	beqz	a5,80004e9e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004e7e:	4505                	li	a0,1
    80004e80:	9782                	jalr	a5
    80004e82:	892a                	mv	s2,a0
    80004e84:	bf75                	j	80004e40 <fileread+0x60>
    panic("fileread");
    80004e86:	00004517          	auipc	a0,0x4
    80004e8a:	9da50513          	addi	a0,a0,-1574 # 80008860 <syscalls+0x268>
    80004e8e:	ffffb097          	auipc	ra,0xffffb
    80004e92:	6b0080e7          	jalr	1712(ra) # 8000053e <panic>
    return -1;
    80004e96:	597d                	li	s2,-1
    80004e98:	b765                	j	80004e40 <fileread+0x60>
      return -1;
    80004e9a:	597d                	li	s2,-1
    80004e9c:	b755                	j	80004e40 <fileread+0x60>
    80004e9e:	597d                	li	s2,-1
    80004ea0:	b745                	j	80004e40 <fileread+0x60>

0000000080004ea2 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004ea2:	715d                	addi	sp,sp,-80
    80004ea4:	e486                	sd	ra,72(sp)
    80004ea6:	e0a2                	sd	s0,64(sp)
    80004ea8:	fc26                	sd	s1,56(sp)
    80004eaa:	f84a                	sd	s2,48(sp)
    80004eac:	f44e                	sd	s3,40(sp)
    80004eae:	f052                	sd	s4,32(sp)
    80004eb0:	ec56                	sd	s5,24(sp)
    80004eb2:	e85a                	sd	s6,16(sp)
    80004eb4:	e45e                	sd	s7,8(sp)
    80004eb6:	e062                	sd	s8,0(sp)
    80004eb8:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004eba:	00954783          	lbu	a5,9(a0)
    80004ebe:	10078663          	beqz	a5,80004fca <filewrite+0x128>
    80004ec2:	892a                	mv	s2,a0
    80004ec4:	8aae                	mv	s5,a1
    80004ec6:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ec8:	411c                	lw	a5,0(a0)
    80004eca:	4705                	li	a4,1
    80004ecc:	02e78263          	beq	a5,a4,80004ef0 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ed0:	470d                	li	a4,3
    80004ed2:	02e78663          	beq	a5,a4,80004efe <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ed6:	4709                	li	a4,2
    80004ed8:	0ee79163          	bne	a5,a4,80004fba <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004edc:	0ac05d63          	blez	a2,80004f96 <filewrite+0xf4>
    int i = 0;
    80004ee0:	4981                	li	s3,0
    80004ee2:	6b05                	lui	s6,0x1
    80004ee4:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004ee8:	6b85                	lui	s7,0x1
    80004eea:	c00b8b9b          	addiw	s7,s7,-1024
    80004eee:	a861                	j	80004f86 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004ef0:	6908                	ld	a0,16(a0)
    80004ef2:	00000097          	auipc	ra,0x0
    80004ef6:	22e080e7          	jalr	558(ra) # 80005120 <pipewrite>
    80004efa:	8a2a                	mv	s4,a0
    80004efc:	a045                	j	80004f9c <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004efe:	02451783          	lh	a5,36(a0)
    80004f02:	03079693          	slli	a3,a5,0x30
    80004f06:	92c1                	srli	a3,a3,0x30
    80004f08:	4725                	li	a4,9
    80004f0a:	0cd76263          	bltu	a4,a3,80004fce <filewrite+0x12c>
    80004f0e:	0792                	slli	a5,a5,0x4
    80004f10:	000d8717          	auipc	a4,0xd8
    80004f14:	40870713          	addi	a4,a4,1032 # 800dd318 <devsw>
    80004f18:	97ba                	add	a5,a5,a4
    80004f1a:	679c                	ld	a5,8(a5)
    80004f1c:	cbdd                	beqz	a5,80004fd2 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004f1e:	4505                	li	a0,1
    80004f20:	9782                	jalr	a5
    80004f22:	8a2a                	mv	s4,a0
    80004f24:	a8a5                	j	80004f9c <filewrite+0xfa>
    80004f26:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004f2a:	00000097          	auipc	ra,0x0
    80004f2e:	8b0080e7          	jalr	-1872(ra) # 800047da <begin_op>
      ilock(f->ip);
    80004f32:	01893503          	ld	a0,24(s2)
    80004f36:	fffff097          	auipc	ra,0xfffff
    80004f3a:	ed2080e7          	jalr	-302(ra) # 80003e08 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004f3e:	8762                	mv	a4,s8
    80004f40:	02092683          	lw	a3,32(s2)
    80004f44:	01598633          	add	a2,s3,s5
    80004f48:	4585                	li	a1,1
    80004f4a:	01893503          	ld	a0,24(s2)
    80004f4e:	fffff097          	auipc	ra,0xfffff
    80004f52:	266080e7          	jalr	614(ra) # 800041b4 <writei>
    80004f56:	84aa                	mv	s1,a0
    80004f58:	00a05763          	blez	a0,80004f66 <filewrite+0xc4>
        f->off += r;
    80004f5c:	02092783          	lw	a5,32(s2)
    80004f60:	9fa9                	addw	a5,a5,a0
    80004f62:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004f66:	01893503          	ld	a0,24(s2)
    80004f6a:	fffff097          	auipc	ra,0xfffff
    80004f6e:	f60080e7          	jalr	-160(ra) # 80003eca <iunlock>
      end_op();
    80004f72:	00000097          	auipc	ra,0x0
    80004f76:	8e8080e7          	jalr	-1816(ra) # 8000485a <end_op>

      if(r != n1){
    80004f7a:	009c1f63          	bne	s8,s1,80004f98 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004f7e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004f82:	0149db63          	bge	s3,s4,80004f98 <filewrite+0xf6>
      int n1 = n - i;
    80004f86:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004f8a:	84be                	mv	s1,a5
    80004f8c:	2781                	sext.w	a5,a5
    80004f8e:	f8fb5ce3          	bge	s6,a5,80004f26 <filewrite+0x84>
    80004f92:	84de                	mv	s1,s7
    80004f94:	bf49                	j	80004f26 <filewrite+0x84>
    int i = 0;
    80004f96:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004f98:	013a1f63          	bne	s4,s3,80004fb6 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004f9c:	8552                	mv	a0,s4
    80004f9e:	60a6                	ld	ra,72(sp)
    80004fa0:	6406                	ld	s0,64(sp)
    80004fa2:	74e2                	ld	s1,56(sp)
    80004fa4:	7942                	ld	s2,48(sp)
    80004fa6:	79a2                	ld	s3,40(sp)
    80004fa8:	7a02                	ld	s4,32(sp)
    80004faa:	6ae2                	ld	s5,24(sp)
    80004fac:	6b42                	ld	s6,16(sp)
    80004fae:	6ba2                	ld	s7,8(sp)
    80004fb0:	6c02                	ld	s8,0(sp)
    80004fb2:	6161                	addi	sp,sp,80
    80004fb4:	8082                	ret
    ret = (i == n ? n : -1);
    80004fb6:	5a7d                	li	s4,-1
    80004fb8:	b7d5                	j	80004f9c <filewrite+0xfa>
    panic("filewrite");
    80004fba:	00004517          	auipc	a0,0x4
    80004fbe:	8b650513          	addi	a0,a0,-1866 # 80008870 <syscalls+0x278>
    80004fc2:	ffffb097          	auipc	ra,0xffffb
    80004fc6:	57c080e7          	jalr	1404(ra) # 8000053e <panic>
    return -1;
    80004fca:	5a7d                	li	s4,-1
    80004fcc:	bfc1                	j	80004f9c <filewrite+0xfa>
      return -1;
    80004fce:	5a7d                	li	s4,-1
    80004fd0:	b7f1                	j	80004f9c <filewrite+0xfa>
    80004fd2:	5a7d                	li	s4,-1
    80004fd4:	b7e1                	j	80004f9c <filewrite+0xfa>

0000000080004fd6 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004fd6:	7179                	addi	sp,sp,-48
    80004fd8:	f406                	sd	ra,40(sp)
    80004fda:	f022                	sd	s0,32(sp)
    80004fdc:	ec26                	sd	s1,24(sp)
    80004fde:	e84a                	sd	s2,16(sp)
    80004fe0:	e44e                	sd	s3,8(sp)
    80004fe2:	e052                	sd	s4,0(sp)
    80004fe4:	1800                	addi	s0,sp,48
    80004fe6:	84aa                	mv	s1,a0
    80004fe8:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004fea:	0005b023          	sd	zero,0(a1)
    80004fee:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ff2:	00000097          	auipc	ra,0x0
    80004ff6:	bf8080e7          	jalr	-1032(ra) # 80004bea <filealloc>
    80004ffa:	e088                	sd	a0,0(s1)
    80004ffc:	c551                	beqz	a0,80005088 <pipealloc+0xb2>
    80004ffe:	00000097          	auipc	ra,0x0
    80005002:	bec080e7          	jalr	-1044(ra) # 80004bea <filealloc>
    80005006:	00aa3023          	sd	a0,0(s4)
    8000500a:	c92d                	beqz	a0,8000507c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000500c:	ffffc097          	auipc	ra,0xffffc
    80005010:	ae8080e7          	jalr	-1304(ra) # 80000af4 <kalloc>
    80005014:	892a                	mv	s2,a0
    80005016:	c125                	beqz	a0,80005076 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005018:	4985                	li	s3,1
    8000501a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000501e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005022:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005026:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000502a:	00003597          	auipc	a1,0x3
    8000502e:	43e58593          	addi	a1,a1,1086 # 80008468 <states.1769+0x168>
    80005032:	ffffc097          	auipc	ra,0xffffc
    80005036:	b22080e7          	jalr	-1246(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    8000503a:	609c                	ld	a5,0(s1)
    8000503c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005040:	609c                	ld	a5,0(s1)
    80005042:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005046:	609c                	ld	a5,0(s1)
    80005048:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000504c:	609c                	ld	a5,0(s1)
    8000504e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005052:	000a3783          	ld	a5,0(s4)
    80005056:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000505a:	000a3783          	ld	a5,0(s4)
    8000505e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005062:	000a3783          	ld	a5,0(s4)
    80005066:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000506a:	000a3783          	ld	a5,0(s4)
    8000506e:	0127b823          	sd	s2,16(a5)
  return 0;
    80005072:	4501                	li	a0,0
    80005074:	a025                	j	8000509c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005076:	6088                	ld	a0,0(s1)
    80005078:	e501                	bnez	a0,80005080 <pipealloc+0xaa>
    8000507a:	a039                	j	80005088 <pipealloc+0xb2>
    8000507c:	6088                	ld	a0,0(s1)
    8000507e:	c51d                	beqz	a0,800050ac <pipealloc+0xd6>
    fileclose(*f0);
    80005080:	00000097          	auipc	ra,0x0
    80005084:	c26080e7          	jalr	-986(ra) # 80004ca6 <fileclose>
  if(*f1)
    80005088:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000508c:	557d                	li	a0,-1
  if(*f1)
    8000508e:	c799                	beqz	a5,8000509c <pipealloc+0xc6>
    fileclose(*f1);
    80005090:	853e                	mv	a0,a5
    80005092:	00000097          	auipc	ra,0x0
    80005096:	c14080e7          	jalr	-1004(ra) # 80004ca6 <fileclose>
  return -1;
    8000509a:	557d                	li	a0,-1
}
    8000509c:	70a2                	ld	ra,40(sp)
    8000509e:	7402                	ld	s0,32(sp)
    800050a0:	64e2                	ld	s1,24(sp)
    800050a2:	6942                	ld	s2,16(sp)
    800050a4:	69a2                	ld	s3,8(sp)
    800050a6:	6a02                	ld	s4,0(sp)
    800050a8:	6145                	addi	sp,sp,48
    800050aa:	8082                	ret
  return -1;
    800050ac:	557d                	li	a0,-1
    800050ae:	b7fd                	j	8000509c <pipealloc+0xc6>

00000000800050b0 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800050b0:	1101                	addi	sp,sp,-32
    800050b2:	ec06                	sd	ra,24(sp)
    800050b4:	e822                	sd	s0,16(sp)
    800050b6:	e426                	sd	s1,8(sp)
    800050b8:	e04a                	sd	s2,0(sp)
    800050ba:	1000                	addi	s0,sp,32
    800050bc:	84aa                	mv	s1,a0
    800050be:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800050c0:	ffffc097          	auipc	ra,0xffffc
    800050c4:	b24080e7          	jalr	-1244(ra) # 80000be4 <acquire>
  if(writable){
    800050c8:	02090d63          	beqz	s2,80005102 <pipeclose+0x52>
    pi->writeopen = 0;
    800050cc:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800050d0:	21848513          	addi	a0,s1,536
    800050d4:	ffffd097          	auipc	ra,0xffffd
    800050d8:	370080e7          	jalr	880(ra) # 80002444 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800050dc:	2204b783          	ld	a5,544(s1)
    800050e0:	eb95                	bnez	a5,80005114 <pipeclose+0x64>
    release(&pi->lock);
    800050e2:	8526                	mv	a0,s1
    800050e4:	ffffc097          	auipc	ra,0xffffc
    800050e8:	bb4080e7          	jalr	-1100(ra) # 80000c98 <release>
    kfree((char*)pi);
    800050ec:	8526                	mv	a0,s1
    800050ee:	ffffc097          	auipc	ra,0xffffc
    800050f2:	90a080e7          	jalr	-1782(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800050f6:	60e2                	ld	ra,24(sp)
    800050f8:	6442                	ld	s0,16(sp)
    800050fa:	64a2                	ld	s1,8(sp)
    800050fc:	6902                	ld	s2,0(sp)
    800050fe:	6105                	addi	sp,sp,32
    80005100:	8082                	ret
    pi->readopen = 0;
    80005102:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005106:	21c48513          	addi	a0,s1,540
    8000510a:	ffffd097          	auipc	ra,0xffffd
    8000510e:	33a080e7          	jalr	826(ra) # 80002444 <wakeup>
    80005112:	b7e9                	j	800050dc <pipeclose+0x2c>
    release(&pi->lock);
    80005114:	8526                	mv	a0,s1
    80005116:	ffffc097          	auipc	ra,0xffffc
    8000511a:	b82080e7          	jalr	-1150(ra) # 80000c98 <release>
}
    8000511e:	bfe1                	j	800050f6 <pipeclose+0x46>

0000000080005120 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005120:	7159                	addi	sp,sp,-112
    80005122:	f486                	sd	ra,104(sp)
    80005124:	f0a2                	sd	s0,96(sp)
    80005126:	eca6                	sd	s1,88(sp)
    80005128:	e8ca                	sd	s2,80(sp)
    8000512a:	e4ce                	sd	s3,72(sp)
    8000512c:	e0d2                	sd	s4,64(sp)
    8000512e:	fc56                	sd	s5,56(sp)
    80005130:	f85a                	sd	s6,48(sp)
    80005132:	f45e                	sd	s7,40(sp)
    80005134:	f062                	sd	s8,32(sp)
    80005136:	ec66                	sd	s9,24(sp)
    80005138:	1880                	addi	s0,sp,112
    8000513a:	84aa                	mv	s1,a0
    8000513c:	8aae                	mv	s5,a1
    8000513e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005140:	ffffd097          	auipc	ra,0xffffd
    80005144:	890080e7          	jalr	-1904(ra) # 800019d0 <myproc>
    80005148:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000514a:	8526                	mv	a0,s1
    8000514c:	ffffc097          	auipc	ra,0xffffc
    80005150:	a98080e7          	jalr	-1384(ra) # 80000be4 <acquire>
  while(i < n){
    80005154:	0d405163          	blez	s4,80005216 <pipewrite+0xf6>
    80005158:	8ba6                	mv	s7,s1
  int i = 0;
    8000515a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000515c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000515e:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005162:	21c48c13          	addi	s8,s1,540
    80005166:	a08d                	j	800051c8 <pipewrite+0xa8>
      release(&pi->lock);
    80005168:	8526                	mv	a0,s1
    8000516a:	ffffc097          	auipc	ra,0xffffc
    8000516e:	b2e080e7          	jalr	-1234(ra) # 80000c98 <release>
      return -1;
    80005172:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005174:	854a                	mv	a0,s2
    80005176:	70a6                	ld	ra,104(sp)
    80005178:	7406                	ld	s0,96(sp)
    8000517a:	64e6                	ld	s1,88(sp)
    8000517c:	6946                	ld	s2,80(sp)
    8000517e:	69a6                	ld	s3,72(sp)
    80005180:	6a06                	ld	s4,64(sp)
    80005182:	7ae2                	ld	s5,56(sp)
    80005184:	7b42                	ld	s6,48(sp)
    80005186:	7ba2                	ld	s7,40(sp)
    80005188:	7c02                	ld	s8,32(sp)
    8000518a:	6ce2                	ld	s9,24(sp)
    8000518c:	6165                	addi	sp,sp,112
    8000518e:	8082                	ret
      wakeup(&pi->nread);
    80005190:	8566                	mv	a0,s9
    80005192:	ffffd097          	auipc	ra,0xffffd
    80005196:	2b2080e7          	jalr	690(ra) # 80002444 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000519a:	85de                	mv	a1,s7
    8000519c:	8562                	mv	a0,s8
    8000519e:	ffffd097          	auipc	ra,0xffffd
    800051a2:	fd6080e7          	jalr	-42(ra) # 80002174 <sleep>
    800051a6:	a839                	j	800051c4 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800051a8:	21c4a783          	lw	a5,540(s1)
    800051ac:	0017871b          	addiw	a4,a5,1
    800051b0:	20e4ae23          	sw	a4,540(s1)
    800051b4:	1ff7f793          	andi	a5,a5,511
    800051b8:	97a6                	add	a5,a5,s1
    800051ba:	f9f44703          	lbu	a4,-97(s0)
    800051be:	00e78c23          	sb	a4,24(a5)
      i++;
    800051c2:	2905                	addiw	s2,s2,1
  while(i < n){
    800051c4:	03495d63          	bge	s2,s4,800051fe <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800051c8:	2204a783          	lw	a5,544(s1)
    800051cc:	dfd1                	beqz	a5,80005168 <pipewrite+0x48>
    800051ce:	0289a783          	lw	a5,40(s3)
    800051d2:	fbd9                	bnez	a5,80005168 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800051d4:	2184a783          	lw	a5,536(s1)
    800051d8:	21c4a703          	lw	a4,540(s1)
    800051dc:	2007879b          	addiw	a5,a5,512
    800051e0:	faf708e3          	beq	a4,a5,80005190 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800051e4:	4685                	li	a3,1
    800051e6:	01590633          	add	a2,s2,s5
    800051ea:	f9f40593          	addi	a1,s0,-97
    800051ee:	0509b503          	ld	a0,80(s3)
    800051f2:	ffffc097          	auipc	ra,0xffffc
    800051f6:	50c080e7          	jalr	1292(ra) # 800016fe <copyin>
    800051fa:	fb6517e3          	bne	a0,s6,800051a8 <pipewrite+0x88>
  wakeup(&pi->nread);
    800051fe:	21848513          	addi	a0,s1,536
    80005202:	ffffd097          	auipc	ra,0xffffd
    80005206:	242080e7          	jalr	578(ra) # 80002444 <wakeup>
  release(&pi->lock);
    8000520a:	8526                	mv	a0,s1
    8000520c:	ffffc097          	auipc	ra,0xffffc
    80005210:	a8c080e7          	jalr	-1396(ra) # 80000c98 <release>
  return i;
    80005214:	b785                	j	80005174 <pipewrite+0x54>
  int i = 0;
    80005216:	4901                	li	s2,0
    80005218:	b7dd                	j	800051fe <pipewrite+0xde>

000000008000521a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000521a:	715d                	addi	sp,sp,-80
    8000521c:	e486                	sd	ra,72(sp)
    8000521e:	e0a2                	sd	s0,64(sp)
    80005220:	fc26                	sd	s1,56(sp)
    80005222:	f84a                	sd	s2,48(sp)
    80005224:	f44e                	sd	s3,40(sp)
    80005226:	f052                	sd	s4,32(sp)
    80005228:	ec56                	sd	s5,24(sp)
    8000522a:	e85a                	sd	s6,16(sp)
    8000522c:	0880                	addi	s0,sp,80
    8000522e:	84aa                	mv	s1,a0
    80005230:	892e                	mv	s2,a1
    80005232:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005234:	ffffc097          	auipc	ra,0xffffc
    80005238:	79c080e7          	jalr	1948(ra) # 800019d0 <myproc>
    8000523c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000523e:	8b26                	mv	s6,s1
    80005240:	8526                	mv	a0,s1
    80005242:	ffffc097          	auipc	ra,0xffffc
    80005246:	9a2080e7          	jalr	-1630(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000524a:	2184a703          	lw	a4,536(s1)
    8000524e:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005252:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005256:	02f71463          	bne	a4,a5,8000527e <piperead+0x64>
    8000525a:	2244a783          	lw	a5,548(s1)
    8000525e:	c385                	beqz	a5,8000527e <piperead+0x64>
    if(pr->killed){
    80005260:	028a2783          	lw	a5,40(s4)
    80005264:	ebc1                	bnez	a5,800052f4 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005266:	85da                	mv	a1,s6
    80005268:	854e                	mv	a0,s3
    8000526a:	ffffd097          	auipc	ra,0xffffd
    8000526e:	f0a080e7          	jalr	-246(ra) # 80002174 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005272:	2184a703          	lw	a4,536(s1)
    80005276:	21c4a783          	lw	a5,540(s1)
    8000527a:	fef700e3          	beq	a4,a5,8000525a <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000527e:	09505263          	blez	s5,80005302 <piperead+0xe8>
    80005282:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005284:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005286:	2184a783          	lw	a5,536(s1)
    8000528a:	21c4a703          	lw	a4,540(s1)
    8000528e:	02f70d63          	beq	a4,a5,800052c8 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005292:	0017871b          	addiw	a4,a5,1
    80005296:	20e4ac23          	sw	a4,536(s1)
    8000529a:	1ff7f793          	andi	a5,a5,511
    8000529e:	97a6                	add	a5,a5,s1
    800052a0:	0187c783          	lbu	a5,24(a5)
    800052a4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800052a8:	4685                	li	a3,1
    800052aa:	fbf40613          	addi	a2,s0,-65
    800052ae:	85ca                	mv	a1,s2
    800052b0:	050a3503          	ld	a0,80(s4)
    800052b4:	ffffc097          	auipc	ra,0xffffc
    800052b8:	3be080e7          	jalr	958(ra) # 80001672 <copyout>
    800052bc:	01650663          	beq	a0,s6,800052c8 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052c0:	2985                	addiw	s3,s3,1
    800052c2:	0905                	addi	s2,s2,1
    800052c4:	fd3a91e3          	bne	s5,s3,80005286 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800052c8:	21c48513          	addi	a0,s1,540
    800052cc:	ffffd097          	auipc	ra,0xffffd
    800052d0:	178080e7          	jalr	376(ra) # 80002444 <wakeup>
  release(&pi->lock);
    800052d4:	8526                	mv	a0,s1
    800052d6:	ffffc097          	auipc	ra,0xffffc
    800052da:	9c2080e7          	jalr	-1598(ra) # 80000c98 <release>
  return i;
}
    800052de:	854e                	mv	a0,s3
    800052e0:	60a6                	ld	ra,72(sp)
    800052e2:	6406                	ld	s0,64(sp)
    800052e4:	74e2                	ld	s1,56(sp)
    800052e6:	7942                	ld	s2,48(sp)
    800052e8:	79a2                	ld	s3,40(sp)
    800052ea:	7a02                	ld	s4,32(sp)
    800052ec:	6ae2                	ld	s5,24(sp)
    800052ee:	6b42                	ld	s6,16(sp)
    800052f0:	6161                	addi	sp,sp,80
    800052f2:	8082                	ret
      release(&pi->lock);
    800052f4:	8526                	mv	a0,s1
    800052f6:	ffffc097          	auipc	ra,0xffffc
    800052fa:	9a2080e7          	jalr	-1630(ra) # 80000c98 <release>
      return -1;
    800052fe:	59fd                	li	s3,-1
    80005300:	bff9                	j	800052de <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005302:	4981                	li	s3,0
    80005304:	b7d1                	j	800052c8 <piperead+0xae>

0000000080005306 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005306:	df010113          	addi	sp,sp,-528
    8000530a:	20113423          	sd	ra,520(sp)
    8000530e:	20813023          	sd	s0,512(sp)
    80005312:	ffa6                	sd	s1,504(sp)
    80005314:	fbca                	sd	s2,496(sp)
    80005316:	f7ce                	sd	s3,488(sp)
    80005318:	f3d2                	sd	s4,480(sp)
    8000531a:	efd6                	sd	s5,472(sp)
    8000531c:	ebda                	sd	s6,464(sp)
    8000531e:	e7de                	sd	s7,456(sp)
    80005320:	e3e2                	sd	s8,448(sp)
    80005322:	ff66                	sd	s9,440(sp)
    80005324:	fb6a                	sd	s10,432(sp)
    80005326:	f76e                	sd	s11,424(sp)
    80005328:	0c00                	addi	s0,sp,528
    8000532a:	84aa                	mv	s1,a0
    8000532c:	dea43c23          	sd	a0,-520(s0)
    80005330:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005334:	ffffc097          	auipc	ra,0xffffc
    80005338:	69c080e7          	jalr	1692(ra) # 800019d0 <myproc>
    8000533c:	892a                	mv	s2,a0

  begin_op();
    8000533e:	fffff097          	auipc	ra,0xfffff
    80005342:	49c080e7          	jalr	1180(ra) # 800047da <begin_op>

  if((ip = namei(path)) == 0){
    80005346:	8526                	mv	a0,s1
    80005348:	fffff097          	auipc	ra,0xfffff
    8000534c:	276080e7          	jalr	630(ra) # 800045be <namei>
    80005350:	c92d                	beqz	a0,800053c2 <exec+0xbc>
    80005352:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005354:	fffff097          	auipc	ra,0xfffff
    80005358:	ab4080e7          	jalr	-1356(ra) # 80003e08 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000535c:	04000713          	li	a4,64
    80005360:	4681                	li	a3,0
    80005362:	e5040613          	addi	a2,s0,-432
    80005366:	4581                	li	a1,0
    80005368:	8526                	mv	a0,s1
    8000536a:	fffff097          	auipc	ra,0xfffff
    8000536e:	d52080e7          	jalr	-686(ra) # 800040bc <readi>
    80005372:	04000793          	li	a5,64
    80005376:	00f51a63          	bne	a0,a5,8000538a <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000537a:	e5042703          	lw	a4,-432(s0)
    8000537e:	464c47b7          	lui	a5,0x464c4
    80005382:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005386:	04f70463          	beq	a4,a5,800053ce <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000538a:	8526                	mv	a0,s1
    8000538c:	fffff097          	auipc	ra,0xfffff
    80005390:	cde080e7          	jalr	-802(ra) # 8000406a <iunlockput>
    end_op();
    80005394:	fffff097          	auipc	ra,0xfffff
    80005398:	4c6080e7          	jalr	1222(ra) # 8000485a <end_op>
  }
  return -1;
    8000539c:	557d                	li	a0,-1
}
    8000539e:	20813083          	ld	ra,520(sp)
    800053a2:	20013403          	ld	s0,512(sp)
    800053a6:	74fe                	ld	s1,504(sp)
    800053a8:	795e                	ld	s2,496(sp)
    800053aa:	79be                	ld	s3,488(sp)
    800053ac:	7a1e                	ld	s4,480(sp)
    800053ae:	6afe                	ld	s5,472(sp)
    800053b0:	6b5e                	ld	s6,464(sp)
    800053b2:	6bbe                	ld	s7,456(sp)
    800053b4:	6c1e                	ld	s8,448(sp)
    800053b6:	7cfa                	ld	s9,440(sp)
    800053b8:	7d5a                	ld	s10,432(sp)
    800053ba:	7dba                	ld	s11,424(sp)
    800053bc:	21010113          	addi	sp,sp,528
    800053c0:	8082                	ret
    end_op();
    800053c2:	fffff097          	auipc	ra,0xfffff
    800053c6:	498080e7          	jalr	1176(ra) # 8000485a <end_op>
    return -1;
    800053ca:	557d                	li	a0,-1
    800053cc:	bfc9                	j	8000539e <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800053ce:	854a                	mv	a0,s2
    800053d0:	ffffc097          	auipc	ra,0xffffc
    800053d4:	6c4080e7          	jalr	1732(ra) # 80001a94 <proc_pagetable>
    800053d8:	8baa                	mv	s7,a0
    800053da:	d945                	beqz	a0,8000538a <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053dc:	e7042983          	lw	s3,-400(s0)
    800053e0:	e8845783          	lhu	a5,-376(s0)
    800053e4:	c7ad                	beqz	a5,8000544e <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800053e6:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053e8:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800053ea:	6c85                	lui	s9,0x1
    800053ec:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800053f0:	def43823          	sd	a5,-528(s0)
    800053f4:	a42d                	j	8000561e <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800053f6:	00003517          	auipc	a0,0x3
    800053fa:	48a50513          	addi	a0,a0,1162 # 80008880 <syscalls+0x288>
    800053fe:	ffffb097          	auipc	ra,0xffffb
    80005402:	140080e7          	jalr	320(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005406:	8756                	mv	a4,s5
    80005408:	012d86bb          	addw	a3,s11,s2
    8000540c:	4581                	li	a1,0
    8000540e:	8526                	mv	a0,s1
    80005410:	fffff097          	auipc	ra,0xfffff
    80005414:	cac080e7          	jalr	-852(ra) # 800040bc <readi>
    80005418:	2501                	sext.w	a0,a0
    8000541a:	1aaa9963          	bne	s5,a0,800055cc <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    8000541e:	6785                	lui	a5,0x1
    80005420:	0127893b          	addw	s2,a5,s2
    80005424:	77fd                	lui	a5,0xfffff
    80005426:	01478a3b          	addw	s4,a5,s4
    8000542a:	1f897163          	bgeu	s2,s8,8000560c <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000542e:	02091593          	slli	a1,s2,0x20
    80005432:	9181                	srli	a1,a1,0x20
    80005434:	95ea                	add	a1,a1,s10
    80005436:	855e                	mv	a0,s7
    80005438:	ffffc097          	auipc	ra,0xffffc
    8000543c:	c36080e7          	jalr	-970(ra) # 8000106e <walkaddr>
    80005440:	862a                	mv	a2,a0
    if(pa == 0)
    80005442:	d955                	beqz	a0,800053f6 <exec+0xf0>
      n = PGSIZE;
    80005444:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005446:	fd9a70e3          	bgeu	s4,s9,80005406 <exec+0x100>
      n = sz - i;
    8000544a:	8ad2                	mv	s5,s4
    8000544c:	bf6d                	j	80005406 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000544e:	4901                	li	s2,0
  iunlockput(ip);
    80005450:	8526                	mv	a0,s1
    80005452:	fffff097          	auipc	ra,0xfffff
    80005456:	c18080e7          	jalr	-1000(ra) # 8000406a <iunlockput>
  end_op();
    8000545a:	fffff097          	auipc	ra,0xfffff
    8000545e:	400080e7          	jalr	1024(ra) # 8000485a <end_op>
  p = myproc();
    80005462:	ffffc097          	auipc	ra,0xffffc
    80005466:	56e080e7          	jalr	1390(ra) # 800019d0 <myproc>
    8000546a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000546c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005470:	6785                	lui	a5,0x1
    80005472:	17fd                	addi	a5,a5,-1
    80005474:	993e                	add	s2,s2,a5
    80005476:	757d                	lui	a0,0xfffff
    80005478:	00a977b3          	and	a5,s2,a0
    8000547c:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005480:	6609                	lui	a2,0x2
    80005482:	963e                	add	a2,a2,a5
    80005484:	85be                	mv	a1,a5
    80005486:	855e                	mv	a0,s7
    80005488:	ffffc097          	auipc	ra,0xffffc
    8000548c:	f9a080e7          	jalr	-102(ra) # 80001422 <uvmalloc>
    80005490:	8b2a                	mv	s6,a0
  ip = 0;
    80005492:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005494:	12050c63          	beqz	a0,800055cc <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005498:	75f9                	lui	a1,0xffffe
    8000549a:	95aa                	add	a1,a1,a0
    8000549c:	855e                	mv	a0,s7
    8000549e:	ffffc097          	auipc	ra,0xffffc
    800054a2:	1a2080e7          	jalr	418(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    800054a6:	7c7d                	lui	s8,0xfffff
    800054a8:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800054aa:	e0043783          	ld	a5,-512(s0)
    800054ae:	6388                	ld	a0,0(a5)
    800054b0:	c535                	beqz	a0,8000551c <exec+0x216>
    800054b2:	e9040993          	addi	s3,s0,-368
    800054b6:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800054ba:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800054bc:	ffffc097          	auipc	ra,0xffffc
    800054c0:	9a8080e7          	jalr	-1624(ra) # 80000e64 <strlen>
    800054c4:	2505                	addiw	a0,a0,1
    800054c6:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800054ca:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800054ce:	13896363          	bltu	s2,s8,800055f4 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800054d2:	e0043d83          	ld	s11,-512(s0)
    800054d6:	000dba03          	ld	s4,0(s11)
    800054da:	8552                	mv	a0,s4
    800054dc:	ffffc097          	auipc	ra,0xffffc
    800054e0:	988080e7          	jalr	-1656(ra) # 80000e64 <strlen>
    800054e4:	0015069b          	addiw	a3,a0,1
    800054e8:	8652                	mv	a2,s4
    800054ea:	85ca                	mv	a1,s2
    800054ec:	855e                	mv	a0,s7
    800054ee:	ffffc097          	auipc	ra,0xffffc
    800054f2:	184080e7          	jalr	388(ra) # 80001672 <copyout>
    800054f6:	10054363          	bltz	a0,800055fc <exec+0x2f6>
    ustack[argc] = sp;
    800054fa:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800054fe:	0485                	addi	s1,s1,1
    80005500:	008d8793          	addi	a5,s11,8
    80005504:	e0f43023          	sd	a5,-512(s0)
    80005508:	008db503          	ld	a0,8(s11)
    8000550c:	c911                	beqz	a0,80005520 <exec+0x21a>
    if(argc >= MAXARG)
    8000550e:	09a1                	addi	s3,s3,8
    80005510:	fb3c96e3          	bne	s9,s3,800054bc <exec+0x1b6>
  sz = sz1;
    80005514:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005518:	4481                	li	s1,0
    8000551a:	a84d                	j	800055cc <exec+0x2c6>
  sp = sz;
    8000551c:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000551e:	4481                	li	s1,0
  ustack[argc] = 0;
    80005520:	00349793          	slli	a5,s1,0x3
    80005524:	f9040713          	addi	a4,s0,-112
    80005528:	97ba                	add	a5,a5,a4
    8000552a:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000552e:	00148693          	addi	a3,s1,1
    80005532:	068e                	slli	a3,a3,0x3
    80005534:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005538:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000553c:	01897663          	bgeu	s2,s8,80005548 <exec+0x242>
  sz = sz1;
    80005540:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005544:	4481                	li	s1,0
    80005546:	a059                	j	800055cc <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005548:	e9040613          	addi	a2,s0,-368
    8000554c:	85ca                	mv	a1,s2
    8000554e:	855e                	mv	a0,s7
    80005550:	ffffc097          	auipc	ra,0xffffc
    80005554:	122080e7          	jalr	290(ra) # 80001672 <copyout>
    80005558:	0a054663          	bltz	a0,80005604 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000555c:	058ab783          	ld	a5,88(s5)
    80005560:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005564:	df843783          	ld	a5,-520(s0)
    80005568:	0007c703          	lbu	a4,0(a5)
    8000556c:	cf11                	beqz	a4,80005588 <exec+0x282>
    8000556e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005570:	02f00693          	li	a3,47
    80005574:	a039                	j	80005582 <exec+0x27c>
      last = s+1;
    80005576:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000557a:	0785                	addi	a5,a5,1
    8000557c:	fff7c703          	lbu	a4,-1(a5)
    80005580:	c701                	beqz	a4,80005588 <exec+0x282>
    if(*s == '/')
    80005582:	fed71ce3          	bne	a4,a3,8000557a <exec+0x274>
    80005586:	bfc5                	j	80005576 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005588:	4641                	li	a2,16
    8000558a:	df843583          	ld	a1,-520(s0)
    8000558e:	158a8513          	addi	a0,s5,344
    80005592:	ffffc097          	auipc	ra,0xffffc
    80005596:	8a0080e7          	jalr	-1888(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    8000559a:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000559e:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800055a2:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800055a6:	058ab783          	ld	a5,88(s5)
    800055aa:	e6843703          	ld	a4,-408(s0)
    800055ae:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800055b0:	058ab783          	ld	a5,88(s5)
    800055b4:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800055b8:	85ea                	mv	a1,s10
    800055ba:	ffffc097          	auipc	ra,0xffffc
    800055be:	576080e7          	jalr	1398(ra) # 80001b30 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800055c2:	0004851b          	sext.w	a0,s1
    800055c6:	bbe1                	j	8000539e <exec+0x98>
    800055c8:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800055cc:	e0843583          	ld	a1,-504(s0)
    800055d0:	855e                	mv	a0,s7
    800055d2:	ffffc097          	auipc	ra,0xffffc
    800055d6:	55e080e7          	jalr	1374(ra) # 80001b30 <proc_freepagetable>
  if(ip){
    800055da:	da0498e3          	bnez	s1,8000538a <exec+0x84>
  return -1;
    800055de:	557d                	li	a0,-1
    800055e0:	bb7d                	j	8000539e <exec+0x98>
    800055e2:	e1243423          	sd	s2,-504(s0)
    800055e6:	b7dd                	j	800055cc <exec+0x2c6>
    800055e8:	e1243423          	sd	s2,-504(s0)
    800055ec:	b7c5                	j	800055cc <exec+0x2c6>
    800055ee:	e1243423          	sd	s2,-504(s0)
    800055f2:	bfe9                	j	800055cc <exec+0x2c6>
  sz = sz1;
    800055f4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055f8:	4481                	li	s1,0
    800055fa:	bfc9                	j	800055cc <exec+0x2c6>
  sz = sz1;
    800055fc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005600:	4481                	li	s1,0
    80005602:	b7e9                	j	800055cc <exec+0x2c6>
  sz = sz1;
    80005604:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005608:	4481                	li	s1,0
    8000560a:	b7c9                	j	800055cc <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000560c:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005610:	2b05                	addiw	s6,s6,1
    80005612:	0389899b          	addiw	s3,s3,56
    80005616:	e8845783          	lhu	a5,-376(s0)
    8000561a:	e2fb5be3          	bge	s6,a5,80005450 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000561e:	2981                	sext.w	s3,s3
    80005620:	03800713          	li	a4,56
    80005624:	86ce                	mv	a3,s3
    80005626:	e1840613          	addi	a2,s0,-488
    8000562a:	4581                	li	a1,0
    8000562c:	8526                	mv	a0,s1
    8000562e:	fffff097          	auipc	ra,0xfffff
    80005632:	a8e080e7          	jalr	-1394(ra) # 800040bc <readi>
    80005636:	03800793          	li	a5,56
    8000563a:	f8f517e3          	bne	a0,a5,800055c8 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000563e:	e1842783          	lw	a5,-488(s0)
    80005642:	4705                	li	a4,1
    80005644:	fce796e3          	bne	a5,a4,80005610 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005648:	e4043603          	ld	a2,-448(s0)
    8000564c:	e3843783          	ld	a5,-456(s0)
    80005650:	f8f669e3          	bltu	a2,a5,800055e2 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005654:	e2843783          	ld	a5,-472(s0)
    80005658:	963e                	add	a2,a2,a5
    8000565a:	f8f667e3          	bltu	a2,a5,800055e8 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000565e:	85ca                	mv	a1,s2
    80005660:	855e                	mv	a0,s7
    80005662:	ffffc097          	auipc	ra,0xffffc
    80005666:	dc0080e7          	jalr	-576(ra) # 80001422 <uvmalloc>
    8000566a:	e0a43423          	sd	a0,-504(s0)
    8000566e:	d141                	beqz	a0,800055ee <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005670:	e2843d03          	ld	s10,-472(s0)
    80005674:	df043783          	ld	a5,-528(s0)
    80005678:	00fd77b3          	and	a5,s10,a5
    8000567c:	fba1                	bnez	a5,800055cc <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000567e:	e2042d83          	lw	s11,-480(s0)
    80005682:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005686:	f80c03e3          	beqz	s8,8000560c <exec+0x306>
    8000568a:	8a62                	mv	s4,s8
    8000568c:	4901                	li	s2,0
    8000568e:	b345                	j	8000542e <exec+0x128>

0000000080005690 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005690:	7179                	addi	sp,sp,-48
    80005692:	f406                	sd	ra,40(sp)
    80005694:	f022                	sd	s0,32(sp)
    80005696:	ec26                	sd	s1,24(sp)
    80005698:	e84a                	sd	s2,16(sp)
    8000569a:	1800                	addi	s0,sp,48
    8000569c:	892e                	mv	s2,a1
    8000569e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800056a0:	fdc40593          	addi	a1,s0,-36
    800056a4:	ffffd097          	auipc	ra,0xffffd
    800056a8:	79c080e7          	jalr	1948(ra) # 80002e40 <argint>
    800056ac:	04054063          	bltz	a0,800056ec <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800056b0:	fdc42703          	lw	a4,-36(s0)
    800056b4:	47bd                	li	a5,15
    800056b6:	02e7ed63          	bltu	a5,a4,800056f0 <argfd+0x60>
    800056ba:	ffffc097          	auipc	ra,0xffffc
    800056be:	316080e7          	jalr	790(ra) # 800019d0 <myproc>
    800056c2:	fdc42703          	lw	a4,-36(s0)
    800056c6:	01a70793          	addi	a5,a4,26
    800056ca:	078e                	slli	a5,a5,0x3
    800056cc:	953e                	add	a0,a0,a5
    800056ce:	611c                	ld	a5,0(a0)
    800056d0:	c395                	beqz	a5,800056f4 <argfd+0x64>
    return -1;
  if(pfd)
    800056d2:	00090463          	beqz	s2,800056da <argfd+0x4a>
    *pfd = fd;
    800056d6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800056da:	4501                	li	a0,0
  if(pf)
    800056dc:	c091                	beqz	s1,800056e0 <argfd+0x50>
    *pf = f;
    800056de:	e09c                	sd	a5,0(s1)
}
    800056e0:	70a2                	ld	ra,40(sp)
    800056e2:	7402                	ld	s0,32(sp)
    800056e4:	64e2                	ld	s1,24(sp)
    800056e6:	6942                	ld	s2,16(sp)
    800056e8:	6145                	addi	sp,sp,48
    800056ea:	8082                	ret
    return -1;
    800056ec:	557d                	li	a0,-1
    800056ee:	bfcd                	j	800056e0 <argfd+0x50>
    return -1;
    800056f0:	557d                	li	a0,-1
    800056f2:	b7fd                	j	800056e0 <argfd+0x50>
    800056f4:	557d                	li	a0,-1
    800056f6:	b7ed                	j	800056e0 <argfd+0x50>

00000000800056f8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800056f8:	1101                	addi	sp,sp,-32
    800056fa:	ec06                	sd	ra,24(sp)
    800056fc:	e822                	sd	s0,16(sp)
    800056fe:	e426                	sd	s1,8(sp)
    80005700:	1000                	addi	s0,sp,32
    80005702:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005704:	ffffc097          	auipc	ra,0xffffc
    80005708:	2cc080e7          	jalr	716(ra) # 800019d0 <myproc>
    8000570c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000570e:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ff1d0d0>
    80005712:	4501                	li	a0,0
    80005714:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005716:	6398                	ld	a4,0(a5)
    80005718:	cb19                	beqz	a4,8000572e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000571a:	2505                	addiw	a0,a0,1
    8000571c:	07a1                	addi	a5,a5,8
    8000571e:	fed51ce3          	bne	a0,a3,80005716 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005722:	557d                	li	a0,-1
}
    80005724:	60e2                	ld	ra,24(sp)
    80005726:	6442                	ld	s0,16(sp)
    80005728:	64a2                	ld	s1,8(sp)
    8000572a:	6105                	addi	sp,sp,32
    8000572c:	8082                	ret
      p->ofile[fd] = f;
    8000572e:	01a50793          	addi	a5,a0,26
    80005732:	078e                	slli	a5,a5,0x3
    80005734:	963e                	add	a2,a2,a5
    80005736:	e204                	sd	s1,0(a2)
      return fd;
    80005738:	b7f5                	j	80005724 <fdalloc+0x2c>

000000008000573a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000573a:	715d                	addi	sp,sp,-80
    8000573c:	e486                	sd	ra,72(sp)
    8000573e:	e0a2                	sd	s0,64(sp)
    80005740:	fc26                	sd	s1,56(sp)
    80005742:	f84a                	sd	s2,48(sp)
    80005744:	f44e                	sd	s3,40(sp)
    80005746:	f052                	sd	s4,32(sp)
    80005748:	ec56                	sd	s5,24(sp)
    8000574a:	0880                	addi	s0,sp,80
    8000574c:	89ae                	mv	s3,a1
    8000574e:	8ab2                	mv	s5,a2
    80005750:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005752:	fb040593          	addi	a1,s0,-80
    80005756:	fffff097          	auipc	ra,0xfffff
    8000575a:	e86080e7          	jalr	-378(ra) # 800045dc <nameiparent>
    8000575e:	892a                	mv	s2,a0
    80005760:	12050f63          	beqz	a0,8000589e <create+0x164>
    return 0;

  ilock(dp);
    80005764:	ffffe097          	auipc	ra,0xffffe
    80005768:	6a4080e7          	jalr	1700(ra) # 80003e08 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000576c:	4601                	li	a2,0
    8000576e:	fb040593          	addi	a1,s0,-80
    80005772:	854a                	mv	a0,s2
    80005774:	fffff097          	auipc	ra,0xfffff
    80005778:	b78080e7          	jalr	-1160(ra) # 800042ec <dirlookup>
    8000577c:	84aa                	mv	s1,a0
    8000577e:	c921                	beqz	a0,800057ce <create+0x94>
    iunlockput(dp);
    80005780:	854a                	mv	a0,s2
    80005782:	fffff097          	auipc	ra,0xfffff
    80005786:	8e8080e7          	jalr	-1816(ra) # 8000406a <iunlockput>
    ilock(ip);
    8000578a:	8526                	mv	a0,s1
    8000578c:	ffffe097          	auipc	ra,0xffffe
    80005790:	67c080e7          	jalr	1660(ra) # 80003e08 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005794:	2981                	sext.w	s3,s3
    80005796:	4789                	li	a5,2
    80005798:	02f99463          	bne	s3,a5,800057c0 <create+0x86>
    8000579c:	0444d783          	lhu	a5,68(s1)
    800057a0:	37f9                	addiw	a5,a5,-2
    800057a2:	17c2                	slli	a5,a5,0x30
    800057a4:	93c1                	srli	a5,a5,0x30
    800057a6:	4705                	li	a4,1
    800057a8:	00f76c63          	bltu	a4,a5,800057c0 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800057ac:	8526                	mv	a0,s1
    800057ae:	60a6                	ld	ra,72(sp)
    800057b0:	6406                	ld	s0,64(sp)
    800057b2:	74e2                	ld	s1,56(sp)
    800057b4:	7942                	ld	s2,48(sp)
    800057b6:	79a2                	ld	s3,40(sp)
    800057b8:	7a02                	ld	s4,32(sp)
    800057ba:	6ae2                	ld	s5,24(sp)
    800057bc:	6161                	addi	sp,sp,80
    800057be:	8082                	ret
    iunlockput(ip);
    800057c0:	8526                	mv	a0,s1
    800057c2:	fffff097          	auipc	ra,0xfffff
    800057c6:	8a8080e7          	jalr	-1880(ra) # 8000406a <iunlockput>
    return 0;
    800057ca:	4481                	li	s1,0
    800057cc:	b7c5                	j	800057ac <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800057ce:	85ce                	mv	a1,s3
    800057d0:	00092503          	lw	a0,0(s2)
    800057d4:	ffffe097          	auipc	ra,0xffffe
    800057d8:	49c080e7          	jalr	1180(ra) # 80003c70 <ialloc>
    800057dc:	84aa                	mv	s1,a0
    800057de:	c529                	beqz	a0,80005828 <create+0xee>
  ilock(ip);
    800057e0:	ffffe097          	auipc	ra,0xffffe
    800057e4:	628080e7          	jalr	1576(ra) # 80003e08 <ilock>
  ip->major = major;
    800057e8:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800057ec:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800057f0:	4785                	li	a5,1
    800057f2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057f6:	8526                	mv	a0,s1
    800057f8:	ffffe097          	auipc	ra,0xffffe
    800057fc:	546080e7          	jalr	1350(ra) # 80003d3e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005800:	2981                	sext.w	s3,s3
    80005802:	4785                	li	a5,1
    80005804:	02f98a63          	beq	s3,a5,80005838 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005808:	40d0                	lw	a2,4(s1)
    8000580a:	fb040593          	addi	a1,s0,-80
    8000580e:	854a                	mv	a0,s2
    80005810:	fffff097          	auipc	ra,0xfffff
    80005814:	cec080e7          	jalr	-788(ra) # 800044fc <dirlink>
    80005818:	06054b63          	bltz	a0,8000588e <create+0x154>
  iunlockput(dp);
    8000581c:	854a                	mv	a0,s2
    8000581e:	fffff097          	auipc	ra,0xfffff
    80005822:	84c080e7          	jalr	-1972(ra) # 8000406a <iunlockput>
  return ip;
    80005826:	b759                	j	800057ac <create+0x72>
    panic("create: ialloc");
    80005828:	00003517          	auipc	a0,0x3
    8000582c:	07850513          	addi	a0,a0,120 # 800088a0 <syscalls+0x2a8>
    80005830:	ffffb097          	auipc	ra,0xffffb
    80005834:	d0e080e7          	jalr	-754(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005838:	04a95783          	lhu	a5,74(s2)
    8000583c:	2785                	addiw	a5,a5,1
    8000583e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005842:	854a                	mv	a0,s2
    80005844:	ffffe097          	auipc	ra,0xffffe
    80005848:	4fa080e7          	jalr	1274(ra) # 80003d3e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000584c:	40d0                	lw	a2,4(s1)
    8000584e:	00003597          	auipc	a1,0x3
    80005852:	06258593          	addi	a1,a1,98 # 800088b0 <syscalls+0x2b8>
    80005856:	8526                	mv	a0,s1
    80005858:	fffff097          	auipc	ra,0xfffff
    8000585c:	ca4080e7          	jalr	-860(ra) # 800044fc <dirlink>
    80005860:	00054f63          	bltz	a0,8000587e <create+0x144>
    80005864:	00492603          	lw	a2,4(s2)
    80005868:	00003597          	auipc	a1,0x3
    8000586c:	05058593          	addi	a1,a1,80 # 800088b8 <syscalls+0x2c0>
    80005870:	8526                	mv	a0,s1
    80005872:	fffff097          	auipc	ra,0xfffff
    80005876:	c8a080e7          	jalr	-886(ra) # 800044fc <dirlink>
    8000587a:	f80557e3          	bgez	a0,80005808 <create+0xce>
      panic("create dots");
    8000587e:	00003517          	auipc	a0,0x3
    80005882:	04250513          	addi	a0,a0,66 # 800088c0 <syscalls+0x2c8>
    80005886:	ffffb097          	auipc	ra,0xffffb
    8000588a:	cb8080e7          	jalr	-840(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000588e:	00003517          	auipc	a0,0x3
    80005892:	04250513          	addi	a0,a0,66 # 800088d0 <syscalls+0x2d8>
    80005896:	ffffb097          	auipc	ra,0xffffb
    8000589a:	ca8080e7          	jalr	-856(ra) # 8000053e <panic>
    return 0;
    8000589e:	84aa                	mv	s1,a0
    800058a0:	b731                	j	800057ac <create+0x72>

00000000800058a2 <sys_dup>:
{
    800058a2:	7179                	addi	sp,sp,-48
    800058a4:	f406                	sd	ra,40(sp)
    800058a6:	f022                	sd	s0,32(sp)
    800058a8:	ec26                	sd	s1,24(sp)
    800058aa:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800058ac:	fd840613          	addi	a2,s0,-40
    800058b0:	4581                	li	a1,0
    800058b2:	4501                	li	a0,0
    800058b4:	00000097          	auipc	ra,0x0
    800058b8:	ddc080e7          	jalr	-548(ra) # 80005690 <argfd>
    return -1;
    800058bc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800058be:	02054363          	bltz	a0,800058e4 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800058c2:	fd843503          	ld	a0,-40(s0)
    800058c6:	00000097          	auipc	ra,0x0
    800058ca:	e32080e7          	jalr	-462(ra) # 800056f8 <fdalloc>
    800058ce:	84aa                	mv	s1,a0
    return -1;
    800058d0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800058d2:	00054963          	bltz	a0,800058e4 <sys_dup+0x42>
  filedup(f);
    800058d6:	fd843503          	ld	a0,-40(s0)
    800058da:	fffff097          	auipc	ra,0xfffff
    800058de:	37a080e7          	jalr	890(ra) # 80004c54 <filedup>
  return fd;
    800058e2:	87a6                	mv	a5,s1
}
    800058e4:	853e                	mv	a0,a5
    800058e6:	70a2                	ld	ra,40(sp)
    800058e8:	7402                	ld	s0,32(sp)
    800058ea:	64e2                	ld	s1,24(sp)
    800058ec:	6145                	addi	sp,sp,48
    800058ee:	8082                	ret

00000000800058f0 <sys_read>:
{
    800058f0:	7179                	addi	sp,sp,-48
    800058f2:	f406                	sd	ra,40(sp)
    800058f4:	f022                	sd	s0,32(sp)
    800058f6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058f8:	fe840613          	addi	a2,s0,-24
    800058fc:	4581                	li	a1,0
    800058fe:	4501                	li	a0,0
    80005900:	00000097          	auipc	ra,0x0
    80005904:	d90080e7          	jalr	-624(ra) # 80005690 <argfd>
    return -1;
    80005908:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000590a:	04054163          	bltz	a0,8000594c <sys_read+0x5c>
    8000590e:	fe440593          	addi	a1,s0,-28
    80005912:	4509                	li	a0,2
    80005914:	ffffd097          	auipc	ra,0xffffd
    80005918:	52c080e7          	jalr	1324(ra) # 80002e40 <argint>
    return -1;
    8000591c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000591e:	02054763          	bltz	a0,8000594c <sys_read+0x5c>
    80005922:	fd840593          	addi	a1,s0,-40
    80005926:	4505                	li	a0,1
    80005928:	ffffd097          	auipc	ra,0xffffd
    8000592c:	53a080e7          	jalr	1338(ra) # 80002e62 <argaddr>
    return -1;
    80005930:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005932:	00054d63          	bltz	a0,8000594c <sys_read+0x5c>
  return fileread(f, p, n);
    80005936:	fe442603          	lw	a2,-28(s0)
    8000593a:	fd843583          	ld	a1,-40(s0)
    8000593e:	fe843503          	ld	a0,-24(s0)
    80005942:	fffff097          	auipc	ra,0xfffff
    80005946:	49e080e7          	jalr	1182(ra) # 80004de0 <fileread>
    8000594a:	87aa                	mv	a5,a0
}
    8000594c:	853e                	mv	a0,a5
    8000594e:	70a2                	ld	ra,40(sp)
    80005950:	7402                	ld	s0,32(sp)
    80005952:	6145                	addi	sp,sp,48
    80005954:	8082                	ret

0000000080005956 <sys_write>:
{
    80005956:	7179                	addi	sp,sp,-48
    80005958:	f406                	sd	ra,40(sp)
    8000595a:	f022                	sd	s0,32(sp)
    8000595c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000595e:	fe840613          	addi	a2,s0,-24
    80005962:	4581                	li	a1,0
    80005964:	4501                	li	a0,0
    80005966:	00000097          	auipc	ra,0x0
    8000596a:	d2a080e7          	jalr	-726(ra) # 80005690 <argfd>
    return -1;
    8000596e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005970:	04054163          	bltz	a0,800059b2 <sys_write+0x5c>
    80005974:	fe440593          	addi	a1,s0,-28
    80005978:	4509                	li	a0,2
    8000597a:	ffffd097          	auipc	ra,0xffffd
    8000597e:	4c6080e7          	jalr	1222(ra) # 80002e40 <argint>
    return -1;
    80005982:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005984:	02054763          	bltz	a0,800059b2 <sys_write+0x5c>
    80005988:	fd840593          	addi	a1,s0,-40
    8000598c:	4505                	li	a0,1
    8000598e:	ffffd097          	auipc	ra,0xffffd
    80005992:	4d4080e7          	jalr	1236(ra) # 80002e62 <argaddr>
    return -1;
    80005996:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005998:	00054d63          	bltz	a0,800059b2 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000599c:	fe442603          	lw	a2,-28(s0)
    800059a0:	fd843583          	ld	a1,-40(s0)
    800059a4:	fe843503          	ld	a0,-24(s0)
    800059a8:	fffff097          	auipc	ra,0xfffff
    800059ac:	4fa080e7          	jalr	1274(ra) # 80004ea2 <filewrite>
    800059b0:	87aa                	mv	a5,a0
}
    800059b2:	853e                	mv	a0,a5
    800059b4:	70a2                	ld	ra,40(sp)
    800059b6:	7402                	ld	s0,32(sp)
    800059b8:	6145                	addi	sp,sp,48
    800059ba:	8082                	ret

00000000800059bc <sys_close>:
{
    800059bc:	1101                	addi	sp,sp,-32
    800059be:	ec06                	sd	ra,24(sp)
    800059c0:	e822                	sd	s0,16(sp)
    800059c2:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800059c4:	fe040613          	addi	a2,s0,-32
    800059c8:	fec40593          	addi	a1,s0,-20
    800059cc:	4501                	li	a0,0
    800059ce:	00000097          	auipc	ra,0x0
    800059d2:	cc2080e7          	jalr	-830(ra) # 80005690 <argfd>
    return -1;
    800059d6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800059d8:	02054463          	bltz	a0,80005a00 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800059dc:	ffffc097          	auipc	ra,0xffffc
    800059e0:	ff4080e7          	jalr	-12(ra) # 800019d0 <myproc>
    800059e4:	fec42783          	lw	a5,-20(s0)
    800059e8:	07e9                	addi	a5,a5,26
    800059ea:	078e                	slli	a5,a5,0x3
    800059ec:	97aa                	add	a5,a5,a0
    800059ee:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800059f2:	fe043503          	ld	a0,-32(s0)
    800059f6:	fffff097          	auipc	ra,0xfffff
    800059fa:	2b0080e7          	jalr	688(ra) # 80004ca6 <fileclose>
  return 0;
    800059fe:	4781                	li	a5,0
}
    80005a00:	853e                	mv	a0,a5
    80005a02:	60e2                	ld	ra,24(sp)
    80005a04:	6442                	ld	s0,16(sp)
    80005a06:	6105                	addi	sp,sp,32
    80005a08:	8082                	ret

0000000080005a0a <sys_fstat>:
{
    80005a0a:	1101                	addi	sp,sp,-32
    80005a0c:	ec06                	sd	ra,24(sp)
    80005a0e:	e822                	sd	s0,16(sp)
    80005a10:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a12:	fe840613          	addi	a2,s0,-24
    80005a16:	4581                	li	a1,0
    80005a18:	4501                	li	a0,0
    80005a1a:	00000097          	auipc	ra,0x0
    80005a1e:	c76080e7          	jalr	-906(ra) # 80005690 <argfd>
    return -1;
    80005a22:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a24:	02054563          	bltz	a0,80005a4e <sys_fstat+0x44>
    80005a28:	fe040593          	addi	a1,s0,-32
    80005a2c:	4505                	li	a0,1
    80005a2e:	ffffd097          	auipc	ra,0xffffd
    80005a32:	434080e7          	jalr	1076(ra) # 80002e62 <argaddr>
    return -1;
    80005a36:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a38:	00054b63          	bltz	a0,80005a4e <sys_fstat+0x44>
  return filestat(f, st);
    80005a3c:	fe043583          	ld	a1,-32(s0)
    80005a40:	fe843503          	ld	a0,-24(s0)
    80005a44:	fffff097          	auipc	ra,0xfffff
    80005a48:	32a080e7          	jalr	810(ra) # 80004d6e <filestat>
    80005a4c:	87aa                	mv	a5,a0
}
    80005a4e:	853e                	mv	a0,a5
    80005a50:	60e2                	ld	ra,24(sp)
    80005a52:	6442                	ld	s0,16(sp)
    80005a54:	6105                	addi	sp,sp,32
    80005a56:	8082                	ret

0000000080005a58 <sys_link>:
{
    80005a58:	7169                	addi	sp,sp,-304
    80005a5a:	f606                	sd	ra,296(sp)
    80005a5c:	f222                	sd	s0,288(sp)
    80005a5e:	ee26                	sd	s1,280(sp)
    80005a60:	ea4a                	sd	s2,272(sp)
    80005a62:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a64:	08000613          	li	a2,128
    80005a68:	ed040593          	addi	a1,s0,-304
    80005a6c:	4501                	li	a0,0
    80005a6e:	ffffd097          	auipc	ra,0xffffd
    80005a72:	416080e7          	jalr	1046(ra) # 80002e84 <argstr>
    return -1;
    80005a76:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a78:	10054e63          	bltz	a0,80005b94 <sys_link+0x13c>
    80005a7c:	08000613          	li	a2,128
    80005a80:	f5040593          	addi	a1,s0,-176
    80005a84:	4505                	li	a0,1
    80005a86:	ffffd097          	auipc	ra,0xffffd
    80005a8a:	3fe080e7          	jalr	1022(ra) # 80002e84 <argstr>
    return -1;
    80005a8e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a90:	10054263          	bltz	a0,80005b94 <sys_link+0x13c>
  begin_op();
    80005a94:	fffff097          	auipc	ra,0xfffff
    80005a98:	d46080e7          	jalr	-698(ra) # 800047da <begin_op>
  if((ip = namei(old)) == 0){
    80005a9c:	ed040513          	addi	a0,s0,-304
    80005aa0:	fffff097          	auipc	ra,0xfffff
    80005aa4:	b1e080e7          	jalr	-1250(ra) # 800045be <namei>
    80005aa8:	84aa                	mv	s1,a0
    80005aaa:	c551                	beqz	a0,80005b36 <sys_link+0xde>
  ilock(ip);
    80005aac:	ffffe097          	auipc	ra,0xffffe
    80005ab0:	35c080e7          	jalr	860(ra) # 80003e08 <ilock>
  if(ip->type == T_DIR){
    80005ab4:	04449703          	lh	a4,68(s1)
    80005ab8:	4785                	li	a5,1
    80005aba:	08f70463          	beq	a4,a5,80005b42 <sys_link+0xea>
  ip->nlink++;
    80005abe:	04a4d783          	lhu	a5,74(s1)
    80005ac2:	2785                	addiw	a5,a5,1
    80005ac4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005ac8:	8526                	mv	a0,s1
    80005aca:	ffffe097          	auipc	ra,0xffffe
    80005ace:	274080e7          	jalr	628(ra) # 80003d3e <iupdate>
  iunlock(ip);
    80005ad2:	8526                	mv	a0,s1
    80005ad4:	ffffe097          	auipc	ra,0xffffe
    80005ad8:	3f6080e7          	jalr	1014(ra) # 80003eca <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005adc:	fd040593          	addi	a1,s0,-48
    80005ae0:	f5040513          	addi	a0,s0,-176
    80005ae4:	fffff097          	auipc	ra,0xfffff
    80005ae8:	af8080e7          	jalr	-1288(ra) # 800045dc <nameiparent>
    80005aec:	892a                	mv	s2,a0
    80005aee:	c935                	beqz	a0,80005b62 <sys_link+0x10a>
  ilock(dp);
    80005af0:	ffffe097          	auipc	ra,0xffffe
    80005af4:	318080e7          	jalr	792(ra) # 80003e08 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005af8:	00092703          	lw	a4,0(s2)
    80005afc:	409c                	lw	a5,0(s1)
    80005afe:	04f71d63          	bne	a4,a5,80005b58 <sys_link+0x100>
    80005b02:	40d0                	lw	a2,4(s1)
    80005b04:	fd040593          	addi	a1,s0,-48
    80005b08:	854a                	mv	a0,s2
    80005b0a:	fffff097          	auipc	ra,0xfffff
    80005b0e:	9f2080e7          	jalr	-1550(ra) # 800044fc <dirlink>
    80005b12:	04054363          	bltz	a0,80005b58 <sys_link+0x100>
  iunlockput(dp);
    80005b16:	854a                	mv	a0,s2
    80005b18:	ffffe097          	auipc	ra,0xffffe
    80005b1c:	552080e7          	jalr	1362(ra) # 8000406a <iunlockput>
  iput(ip);
    80005b20:	8526                	mv	a0,s1
    80005b22:	ffffe097          	auipc	ra,0xffffe
    80005b26:	4a0080e7          	jalr	1184(ra) # 80003fc2 <iput>
  end_op();
    80005b2a:	fffff097          	auipc	ra,0xfffff
    80005b2e:	d30080e7          	jalr	-720(ra) # 8000485a <end_op>
  return 0;
    80005b32:	4781                	li	a5,0
    80005b34:	a085                	j	80005b94 <sys_link+0x13c>
    end_op();
    80005b36:	fffff097          	auipc	ra,0xfffff
    80005b3a:	d24080e7          	jalr	-732(ra) # 8000485a <end_op>
    return -1;
    80005b3e:	57fd                	li	a5,-1
    80005b40:	a891                	j	80005b94 <sys_link+0x13c>
    iunlockput(ip);
    80005b42:	8526                	mv	a0,s1
    80005b44:	ffffe097          	auipc	ra,0xffffe
    80005b48:	526080e7          	jalr	1318(ra) # 8000406a <iunlockput>
    end_op();
    80005b4c:	fffff097          	auipc	ra,0xfffff
    80005b50:	d0e080e7          	jalr	-754(ra) # 8000485a <end_op>
    return -1;
    80005b54:	57fd                	li	a5,-1
    80005b56:	a83d                	j	80005b94 <sys_link+0x13c>
    iunlockput(dp);
    80005b58:	854a                	mv	a0,s2
    80005b5a:	ffffe097          	auipc	ra,0xffffe
    80005b5e:	510080e7          	jalr	1296(ra) # 8000406a <iunlockput>
  ilock(ip);
    80005b62:	8526                	mv	a0,s1
    80005b64:	ffffe097          	auipc	ra,0xffffe
    80005b68:	2a4080e7          	jalr	676(ra) # 80003e08 <ilock>
  ip->nlink--;
    80005b6c:	04a4d783          	lhu	a5,74(s1)
    80005b70:	37fd                	addiw	a5,a5,-1
    80005b72:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b76:	8526                	mv	a0,s1
    80005b78:	ffffe097          	auipc	ra,0xffffe
    80005b7c:	1c6080e7          	jalr	454(ra) # 80003d3e <iupdate>
  iunlockput(ip);
    80005b80:	8526                	mv	a0,s1
    80005b82:	ffffe097          	auipc	ra,0xffffe
    80005b86:	4e8080e7          	jalr	1256(ra) # 8000406a <iunlockput>
  end_op();
    80005b8a:	fffff097          	auipc	ra,0xfffff
    80005b8e:	cd0080e7          	jalr	-816(ra) # 8000485a <end_op>
  return -1;
    80005b92:	57fd                	li	a5,-1
}
    80005b94:	853e                	mv	a0,a5
    80005b96:	70b2                	ld	ra,296(sp)
    80005b98:	7412                	ld	s0,288(sp)
    80005b9a:	64f2                	ld	s1,280(sp)
    80005b9c:	6952                	ld	s2,272(sp)
    80005b9e:	6155                	addi	sp,sp,304
    80005ba0:	8082                	ret

0000000080005ba2 <sys_unlink>:
{
    80005ba2:	7151                	addi	sp,sp,-240
    80005ba4:	f586                	sd	ra,232(sp)
    80005ba6:	f1a2                	sd	s0,224(sp)
    80005ba8:	eda6                	sd	s1,216(sp)
    80005baa:	e9ca                	sd	s2,208(sp)
    80005bac:	e5ce                	sd	s3,200(sp)
    80005bae:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005bb0:	08000613          	li	a2,128
    80005bb4:	f3040593          	addi	a1,s0,-208
    80005bb8:	4501                	li	a0,0
    80005bba:	ffffd097          	auipc	ra,0xffffd
    80005bbe:	2ca080e7          	jalr	714(ra) # 80002e84 <argstr>
    80005bc2:	18054163          	bltz	a0,80005d44 <sys_unlink+0x1a2>
  begin_op();
    80005bc6:	fffff097          	auipc	ra,0xfffff
    80005bca:	c14080e7          	jalr	-1004(ra) # 800047da <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005bce:	fb040593          	addi	a1,s0,-80
    80005bd2:	f3040513          	addi	a0,s0,-208
    80005bd6:	fffff097          	auipc	ra,0xfffff
    80005bda:	a06080e7          	jalr	-1530(ra) # 800045dc <nameiparent>
    80005bde:	84aa                	mv	s1,a0
    80005be0:	c979                	beqz	a0,80005cb6 <sys_unlink+0x114>
  ilock(dp);
    80005be2:	ffffe097          	auipc	ra,0xffffe
    80005be6:	226080e7          	jalr	550(ra) # 80003e08 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005bea:	00003597          	auipc	a1,0x3
    80005bee:	cc658593          	addi	a1,a1,-826 # 800088b0 <syscalls+0x2b8>
    80005bf2:	fb040513          	addi	a0,s0,-80
    80005bf6:	ffffe097          	auipc	ra,0xffffe
    80005bfa:	6dc080e7          	jalr	1756(ra) # 800042d2 <namecmp>
    80005bfe:	14050a63          	beqz	a0,80005d52 <sys_unlink+0x1b0>
    80005c02:	00003597          	auipc	a1,0x3
    80005c06:	cb658593          	addi	a1,a1,-842 # 800088b8 <syscalls+0x2c0>
    80005c0a:	fb040513          	addi	a0,s0,-80
    80005c0e:	ffffe097          	auipc	ra,0xffffe
    80005c12:	6c4080e7          	jalr	1732(ra) # 800042d2 <namecmp>
    80005c16:	12050e63          	beqz	a0,80005d52 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005c1a:	f2c40613          	addi	a2,s0,-212
    80005c1e:	fb040593          	addi	a1,s0,-80
    80005c22:	8526                	mv	a0,s1
    80005c24:	ffffe097          	auipc	ra,0xffffe
    80005c28:	6c8080e7          	jalr	1736(ra) # 800042ec <dirlookup>
    80005c2c:	892a                	mv	s2,a0
    80005c2e:	12050263          	beqz	a0,80005d52 <sys_unlink+0x1b0>
  ilock(ip);
    80005c32:	ffffe097          	auipc	ra,0xffffe
    80005c36:	1d6080e7          	jalr	470(ra) # 80003e08 <ilock>
  if(ip->nlink < 1)
    80005c3a:	04a91783          	lh	a5,74(s2)
    80005c3e:	08f05263          	blez	a5,80005cc2 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005c42:	04491703          	lh	a4,68(s2)
    80005c46:	4785                	li	a5,1
    80005c48:	08f70563          	beq	a4,a5,80005cd2 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005c4c:	4641                	li	a2,16
    80005c4e:	4581                	li	a1,0
    80005c50:	fc040513          	addi	a0,s0,-64
    80005c54:	ffffb097          	auipc	ra,0xffffb
    80005c58:	08c080e7          	jalr	140(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c5c:	4741                	li	a4,16
    80005c5e:	f2c42683          	lw	a3,-212(s0)
    80005c62:	fc040613          	addi	a2,s0,-64
    80005c66:	4581                	li	a1,0
    80005c68:	8526                	mv	a0,s1
    80005c6a:	ffffe097          	auipc	ra,0xffffe
    80005c6e:	54a080e7          	jalr	1354(ra) # 800041b4 <writei>
    80005c72:	47c1                	li	a5,16
    80005c74:	0af51563          	bne	a0,a5,80005d1e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005c78:	04491703          	lh	a4,68(s2)
    80005c7c:	4785                	li	a5,1
    80005c7e:	0af70863          	beq	a4,a5,80005d2e <sys_unlink+0x18c>
  iunlockput(dp);
    80005c82:	8526                	mv	a0,s1
    80005c84:	ffffe097          	auipc	ra,0xffffe
    80005c88:	3e6080e7          	jalr	998(ra) # 8000406a <iunlockput>
  ip->nlink--;
    80005c8c:	04a95783          	lhu	a5,74(s2)
    80005c90:	37fd                	addiw	a5,a5,-1
    80005c92:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005c96:	854a                	mv	a0,s2
    80005c98:	ffffe097          	auipc	ra,0xffffe
    80005c9c:	0a6080e7          	jalr	166(ra) # 80003d3e <iupdate>
  iunlockput(ip);
    80005ca0:	854a                	mv	a0,s2
    80005ca2:	ffffe097          	auipc	ra,0xffffe
    80005ca6:	3c8080e7          	jalr	968(ra) # 8000406a <iunlockput>
  end_op();
    80005caa:	fffff097          	auipc	ra,0xfffff
    80005cae:	bb0080e7          	jalr	-1104(ra) # 8000485a <end_op>
  return 0;
    80005cb2:	4501                	li	a0,0
    80005cb4:	a84d                	j	80005d66 <sys_unlink+0x1c4>
    end_op();
    80005cb6:	fffff097          	auipc	ra,0xfffff
    80005cba:	ba4080e7          	jalr	-1116(ra) # 8000485a <end_op>
    return -1;
    80005cbe:	557d                	li	a0,-1
    80005cc0:	a05d                	j	80005d66 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005cc2:	00003517          	auipc	a0,0x3
    80005cc6:	c1e50513          	addi	a0,a0,-994 # 800088e0 <syscalls+0x2e8>
    80005cca:	ffffb097          	auipc	ra,0xffffb
    80005cce:	874080e7          	jalr	-1932(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005cd2:	04c92703          	lw	a4,76(s2)
    80005cd6:	02000793          	li	a5,32
    80005cda:	f6e7f9e3          	bgeu	a5,a4,80005c4c <sys_unlink+0xaa>
    80005cde:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ce2:	4741                	li	a4,16
    80005ce4:	86ce                	mv	a3,s3
    80005ce6:	f1840613          	addi	a2,s0,-232
    80005cea:	4581                	li	a1,0
    80005cec:	854a                	mv	a0,s2
    80005cee:	ffffe097          	auipc	ra,0xffffe
    80005cf2:	3ce080e7          	jalr	974(ra) # 800040bc <readi>
    80005cf6:	47c1                	li	a5,16
    80005cf8:	00f51b63          	bne	a0,a5,80005d0e <sys_unlink+0x16c>
    if(de.inum != 0)
    80005cfc:	f1845783          	lhu	a5,-232(s0)
    80005d00:	e7a1                	bnez	a5,80005d48 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d02:	29c1                	addiw	s3,s3,16
    80005d04:	04c92783          	lw	a5,76(s2)
    80005d08:	fcf9ede3          	bltu	s3,a5,80005ce2 <sys_unlink+0x140>
    80005d0c:	b781                	j	80005c4c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005d0e:	00003517          	auipc	a0,0x3
    80005d12:	bea50513          	addi	a0,a0,-1046 # 800088f8 <syscalls+0x300>
    80005d16:	ffffb097          	auipc	ra,0xffffb
    80005d1a:	828080e7          	jalr	-2008(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005d1e:	00003517          	auipc	a0,0x3
    80005d22:	bf250513          	addi	a0,a0,-1038 # 80008910 <syscalls+0x318>
    80005d26:	ffffb097          	auipc	ra,0xffffb
    80005d2a:	818080e7          	jalr	-2024(ra) # 8000053e <panic>
    dp->nlink--;
    80005d2e:	04a4d783          	lhu	a5,74(s1)
    80005d32:	37fd                	addiw	a5,a5,-1
    80005d34:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d38:	8526                	mv	a0,s1
    80005d3a:	ffffe097          	auipc	ra,0xffffe
    80005d3e:	004080e7          	jalr	4(ra) # 80003d3e <iupdate>
    80005d42:	b781                	j	80005c82 <sys_unlink+0xe0>
    return -1;
    80005d44:	557d                	li	a0,-1
    80005d46:	a005                	j	80005d66 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005d48:	854a                	mv	a0,s2
    80005d4a:	ffffe097          	auipc	ra,0xffffe
    80005d4e:	320080e7          	jalr	800(ra) # 8000406a <iunlockput>
  iunlockput(dp);
    80005d52:	8526                	mv	a0,s1
    80005d54:	ffffe097          	auipc	ra,0xffffe
    80005d58:	316080e7          	jalr	790(ra) # 8000406a <iunlockput>
  end_op();
    80005d5c:	fffff097          	auipc	ra,0xfffff
    80005d60:	afe080e7          	jalr	-1282(ra) # 8000485a <end_op>
  return -1;
    80005d64:	557d                	li	a0,-1
}
    80005d66:	70ae                	ld	ra,232(sp)
    80005d68:	740e                	ld	s0,224(sp)
    80005d6a:	64ee                	ld	s1,216(sp)
    80005d6c:	694e                	ld	s2,208(sp)
    80005d6e:	69ae                	ld	s3,200(sp)
    80005d70:	616d                	addi	sp,sp,240
    80005d72:	8082                	ret

0000000080005d74 <sys_open>:

uint64
sys_open(void)
{
    80005d74:	7131                	addi	sp,sp,-192
    80005d76:	fd06                	sd	ra,184(sp)
    80005d78:	f922                	sd	s0,176(sp)
    80005d7a:	f526                	sd	s1,168(sp)
    80005d7c:	f14a                	sd	s2,160(sp)
    80005d7e:	ed4e                	sd	s3,152(sp)
    80005d80:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005d82:	08000613          	li	a2,128
    80005d86:	f5040593          	addi	a1,s0,-176
    80005d8a:	4501                	li	a0,0
    80005d8c:	ffffd097          	auipc	ra,0xffffd
    80005d90:	0f8080e7          	jalr	248(ra) # 80002e84 <argstr>
    return -1;
    80005d94:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005d96:	0c054163          	bltz	a0,80005e58 <sys_open+0xe4>
    80005d9a:	f4c40593          	addi	a1,s0,-180
    80005d9e:	4505                	li	a0,1
    80005da0:	ffffd097          	auipc	ra,0xffffd
    80005da4:	0a0080e7          	jalr	160(ra) # 80002e40 <argint>
    80005da8:	0a054863          	bltz	a0,80005e58 <sys_open+0xe4>

  begin_op();
    80005dac:	fffff097          	auipc	ra,0xfffff
    80005db0:	a2e080e7          	jalr	-1490(ra) # 800047da <begin_op>

  if(omode & O_CREATE){
    80005db4:	f4c42783          	lw	a5,-180(s0)
    80005db8:	2007f793          	andi	a5,a5,512
    80005dbc:	cbdd                	beqz	a5,80005e72 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005dbe:	4681                	li	a3,0
    80005dc0:	4601                	li	a2,0
    80005dc2:	4589                	li	a1,2
    80005dc4:	f5040513          	addi	a0,s0,-176
    80005dc8:	00000097          	auipc	ra,0x0
    80005dcc:	972080e7          	jalr	-1678(ra) # 8000573a <create>
    80005dd0:	892a                	mv	s2,a0
    if(ip == 0){
    80005dd2:	c959                	beqz	a0,80005e68 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005dd4:	04491703          	lh	a4,68(s2)
    80005dd8:	478d                	li	a5,3
    80005dda:	00f71763          	bne	a4,a5,80005de8 <sys_open+0x74>
    80005dde:	04695703          	lhu	a4,70(s2)
    80005de2:	47a5                	li	a5,9
    80005de4:	0ce7ec63          	bltu	a5,a4,80005ebc <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005de8:	fffff097          	auipc	ra,0xfffff
    80005dec:	e02080e7          	jalr	-510(ra) # 80004bea <filealloc>
    80005df0:	89aa                	mv	s3,a0
    80005df2:	10050263          	beqz	a0,80005ef6 <sys_open+0x182>
    80005df6:	00000097          	auipc	ra,0x0
    80005dfa:	902080e7          	jalr	-1790(ra) # 800056f8 <fdalloc>
    80005dfe:	84aa                	mv	s1,a0
    80005e00:	0e054663          	bltz	a0,80005eec <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005e04:	04491703          	lh	a4,68(s2)
    80005e08:	478d                	li	a5,3
    80005e0a:	0cf70463          	beq	a4,a5,80005ed2 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005e0e:	4789                	li	a5,2
    80005e10:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005e14:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005e18:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005e1c:	f4c42783          	lw	a5,-180(s0)
    80005e20:	0017c713          	xori	a4,a5,1
    80005e24:	8b05                	andi	a4,a4,1
    80005e26:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005e2a:	0037f713          	andi	a4,a5,3
    80005e2e:	00e03733          	snez	a4,a4
    80005e32:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005e36:	4007f793          	andi	a5,a5,1024
    80005e3a:	c791                	beqz	a5,80005e46 <sys_open+0xd2>
    80005e3c:	04491703          	lh	a4,68(s2)
    80005e40:	4789                	li	a5,2
    80005e42:	08f70f63          	beq	a4,a5,80005ee0 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005e46:	854a                	mv	a0,s2
    80005e48:	ffffe097          	auipc	ra,0xffffe
    80005e4c:	082080e7          	jalr	130(ra) # 80003eca <iunlock>
  end_op();
    80005e50:	fffff097          	auipc	ra,0xfffff
    80005e54:	a0a080e7          	jalr	-1526(ra) # 8000485a <end_op>

  return fd;
}
    80005e58:	8526                	mv	a0,s1
    80005e5a:	70ea                	ld	ra,184(sp)
    80005e5c:	744a                	ld	s0,176(sp)
    80005e5e:	74aa                	ld	s1,168(sp)
    80005e60:	790a                	ld	s2,160(sp)
    80005e62:	69ea                	ld	s3,152(sp)
    80005e64:	6129                	addi	sp,sp,192
    80005e66:	8082                	ret
      end_op();
    80005e68:	fffff097          	auipc	ra,0xfffff
    80005e6c:	9f2080e7          	jalr	-1550(ra) # 8000485a <end_op>
      return -1;
    80005e70:	b7e5                	j	80005e58 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005e72:	f5040513          	addi	a0,s0,-176
    80005e76:	ffffe097          	auipc	ra,0xffffe
    80005e7a:	748080e7          	jalr	1864(ra) # 800045be <namei>
    80005e7e:	892a                	mv	s2,a0
    80005e80:	c905                	beqz	a0,80005eb0 <sys_open+0x13c>
    ilock(ip);
    80005e82:	ffffe097          	auipc	ra,0xffffe
    80005e86:	f86080e7          	jalr	-122(ra) # 80003e08 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005e8a:	04491703          	lh	a4,68(s2)
    80005e8e:	4785                	li	a5,1
    80005e90:	f4f712e3          	bne	a4,a5,80005dd4 <sys_open+0x60>
    80005e94:	f4c42783          	lw	a5,-180(s0)
    80005e98:	dba1                	beqz	a5,80005de8 <sys_open+0x74>
      iunlockput(ip);
    80005e9a:	854a                	mv	a0,s2
    80005e9c:	ffffe097          	auipc	ra,0xffffe
    80005ea0:	1ce080e7          	jalr	462(ra) # 8000406a <iunlockput>
      end_op();
    80005ea4:	fffff097          	auipc	ra,0xfffff
    80005ea8:	9b6080e7          	jalr	-1610(ra) # 8000485a <end_op>
      return -1;
    80005eac:	54fd                	li	s1,-1
    80005eae:	b76d                	j	80005e58 <sys_open+0xe4>
      end_op();
    80005eb0:	fffff097          	auipc	ra,0xfffff
    80005eb4:	9aa080e7          	jalr	-1622(ra) # 8000485a <end_op>
      return -1;
    80005eb8:	54fd                	li	s1,-1
    80005eba:	bf79                	j	80005e58 <sys_open+0xe4>
    iunlockput(ip);
    80005ebc:	854a                	mv	a0,s2
    80005ebe:	ffffe097          	auipc	ra,0xffffe
    80005ec2:	1ac080e7          	jalr	428(ra) # 8000406a <iunlockput>
    end_op();
    80005ec6:	fffff097          	auipc	ra,0xfffff
    80005eca:	994080e7          	jalr	-1644(ra) # 8000485a <end_op>
    return -1;
    80005ece:	54fd                	li	s1,-1
    80005ed0:	b761                	j	80005e58 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005ed2:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005ed6:	04691783          	lh	a5,70(s2)
    80005eda:	02f99223          	sh	a5,36(s3)
    80005ede:	bf2d                	j	80005e18 <sys_open+0xa4>
    itrunc(ip);
    80005ee0:	854a                	mv	a0,s2
    80005ee2:	ffffe097          	auipc	ra,0xffffe
    80005ee6:	034080e7          	jalr	52(ra) # 80003f16 <itrunc>
    80005eea:	bfb1                	j	80005e46 <sys_open+0xd2>
      fileclose(f);
    80005eec:	854e                	mv	a0,s3
    80005eee:	fffff097          	auipc	ra,0xfffff
    80005ef2:	db8080e7          	jalr	-584(ra) # 80004ca6 <fileclose>
    iunlockput(ip);
    80005ef6:	854a                	mv	a0,s2
    80005ef8:	ffffe097          	auipc	ra,0xffffe
    80005efc:	172080e7          	jalr	370(ra) # 8000406a <iunlockput>
    end_op();
    80005f00:	fffff097          	auipc	ra,0xfffff
    80005f04:	95a080e7          	jalr	-1702(ra) # 8000485a <end_op>
    return -1;
    80005f08:	54fd                	li	s1,-1
    80005f0a:	b7b9                	j	80005e58 <sys_open+0xe4>

0000000080005f0c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005f0c:	7175                	addi	sp,sp,-144
    80005f0e:	e506                	sd	ra,136(sp)
    80005f10:	e122                	sd	s0,128(sp)
    80005f12:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005f14:	fffff097          	auipc	ra,0xfffff
    80005f18:	8c6080e7          	jalr	-1850(ra) # 800047da <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005f1c:	08000613          	li	a2,128
    80005f20:	f7040593          	addi	a1,s0,-144
    80005f24:	4501                	li	a0,0
    80005f26:	ffffd097          	auipc	ra,0xffffd
    80005f2a:	f5e080e7          	jalr	-162(ra) # 80002e84 <argstr>
    80005f2e:	02054963          	bltz	a0,80005f60 <sys_mkdir+0x54>
    80005f32:	4681                	li	a3,0
    80005f34:	4601                	li	a2,0
    80005f36:	4585                	li	a1,1
    80005f38:	f7040513          	addi	a0,s0,-144
    80005f3c:	fffff097          	auipc	ra,0xfffff
    80005f40:	7fe080e7          	jalr	2046(ra) # 8000573a <create>
    80005f44:	cd11                	beqz	a0,80005f60 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f46:	ffffe097          	auipc	ra,0xffffe
    80005f4a:	124080e7          	jalr	292(ra) # 8000406a <iunlockput>
  end_op();
    80005f4e:	fffff097          	auipc	ra,0xfffff
    80005f52:	90c080e7          	jalr	-1780(ra) # 8000485a <end_op>
  return 0;
    80005f56:	4501                	li	a0,0
}
    80005f58:	60aa                	ld	ra,136(sp)
    80005f5a:	640a                	ld	s0,128(sp)
    80005f5c:	6149                	addi	sp,sp,144
    80005f5e:	8082                	ret
    end_op();
    80005f60:	fffff097          	auipc	ra,0xfffff
    80005f64:	8fa080e7          	jalr	-1798(ra) # 8000485a <end_op>
    return -1;
    80005f68:	557d                	li	a0,-1
    80005f6a:	b7fd                	j	80005f58 <sys_mkdir+0x4c>

0000000080005f6c <sys_mknod>:

uint64
sys_mknod(void)
{
    80005f6c:	7135                	addi	sp,sp,-160
    80005f6e:	ed06                	sd	ra,152(sp)
    80005f70:	e922                	sd	s0,144(sp)
    80005f72:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005f74:	fffff097          	auipc	ra,0xfffff
    80005f78:	866080e7          	jalr	-1946(ra) # 800047da <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f7c:	08000613          	li	a2,128
    80005f80:	f7040593          	addi	a1,s0,-144
    80005f84:	4501                	li	a0,0
    80005f86:	ffffd097          	auipc	ra,0xffffd
    80005f8a:	efe080e7          	jalr	-258(ra) # 80002e84 <argstr>
    80005f8e:	04054a63          	bltz	a0,80005fe2 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005f92:	f6c40593          	addi	a1,s0,-148
    80005f96:	4505                	li	a0,1
    80005f98:	ffffd097          	auipc	ra,0xffffd
    80005f9c:	ea8080e7          	jalr	-344(ra) # 80002e40 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005fa0:	04054163          	bltz	a0,80005fe2 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005fa4:	f6840593          	addi	a1,s0,-152
    80005fa8:	4509                	li	a0,2
    80005faa:	ffffd097          	auipc	ra,0xffffd
    80005fae:	e96080e7          	jalr	-362(ra) # 80002e40 <argint>
     argint(1, &major) < 0 ||
    80005fb2:	02054863          	bltz	a0,80005fe2 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005fb6:	f6841683          	lh	a3,-152(s0)
    80005fba:	f6c41603          	lh	a2,-148(s0)
    80005fbe:	458d                	li	a1,3
    80005fc0:	f7040513          	addi	a0,s0,-144
    80005fc4:	fffff097          	auipc	ra,0xfffff
    80005fc8:	776080e7          	jalr	1910(ra) # 8000573a <create>
     argint(2, &minor) < 0 ||
    80005fcc:	c919                	beqz	a0,80005fe2 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005fce:	ffffe097          	auipc	ra,0xffffe
    80005fd2:	09c080e7          	jalr	156(ra) # 8000406a <iunlockput>
  end_op();
    80005fd6:	fffff097          	auipc	ra,0xfffff
    80005fda:	884080e7          	jalr	-1916(ra) # 8000485a <end_op>
  return 0;
    80005fde:	4501                	li	a0,0
    80005fe0:	a031                	j	80005fec <sys_mknod+0x80>
    end_op();
    80005fe2:	fffff097          	auipc	ra,0xfffff
    80005fe6:	878080e7          	jalr	-1928(ra) # 8000485a <end_op>
    return -1;
    80005fea:	557d                	li	a0,-1
}
    80005fec:	60ea                	ld	ra,152(sp)
    80005fee:	644a                	ld	s0,144(sp)
    80005ff0:	610d                	addi	sp,sp,160
    80005ff2:	8082                	ret

0000000080005ff4 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005ff4:	7135                	addi	sp,sp,-160
    80005ff6:	ed06                	sd	ra,152(sp)
    80005ff8:	e922                	sd	s0,144(sp)
    80005ffa:	e526                	sd	s1,136(sp)
    80005ffc:	e14a                	sd	s2,128(sp)
    80005ffe:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006000:	ffffc097          	auipc	ra,0xffffc
    80006004:	9d0080e7          	jalr	-1584(ra) # 800019d0 <myproc>
    80006008:	892a                	mv	s2,a0
  
  begin_op();
    8000600a:	ffffe097          	auipc	ra,0xffffe
    8000600e:	7d0080e7          	jalr	2000(ra) # 800047da <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006012:	08000613          	li	a2,128
    80006016:	f6040593          	addi	a1,s0,-160
    8000601a:	4501                	li	a0,0
    8000601c:	ffffd097          	auipc	ra,0xffffd
    80006020:	e68080e7          	jalr	-408(ra) # 80002e84 <argstr>
    80006024:	04054b63          	bltz	a0,8000607a <sys_chdir+0x86>
    80006028:	f6040513          	addi	a0,s0,-160
    8000602c:	ffffe097          	auipc	ra,0xffffe
    80006030:	592080e7          	jalr	1426(ra) # 800045be <namei>
    80006034:	84aa                	mv	s1,a0
    80006036:	c131                	beqz	a0,8000607a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006038:	ffffe097          	auipc	ra,0xffffe
    8000603c:	dd0080e7          	jalr	-560(ra) # 80003e08 <ilock>
  if(ip->type != T_DIR){
    80006040:	04449703          	lh	a4,68(s1)
    80006044:	4785                	li	a5,1
    80006046:	04f71063          	bne	a4,a5,80006086 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000604a:	8526                	mv	a0,s1
    8000604c:	ffffe097          	auipc	ra,0xffffe
    80006050:	e7e080e7          	jalr	-386(ra) # 80003eca <iunlock>
  iput(p->cwd);
    80006054:	15093503          	ld	a0,336(s2)
    80006058:	ffffe097          	auipc	ra,0xffffe
    8000605c:	f6a080e7          	jalr	-150(ra) # 80003fc2 <iput>
  end_op();
    80006060:	ffffe097          	auipc	ra,0xffffe
    80006064:	7fa080e7          	jalr	2042(ra) # 8000485a <end_op>
  p->cwd = ip;
    80006068:	14993823          	sd	s1,336(s2)
  return 0;
    8000606c:	4501                	li	a0,0
}
    8000606e:	60ea                	ld	ra,152(sp)
    80006070:	644a                	ld	s0,144(sp)
    80006072:	64aa                	ld	s1,136(sp)
    80006074:	690a                	ld	s2,128(sp)
    80006076:	610d                	addi	sp,sp,160
    80006078:	8082                	ret
    end_op();
    8000607a:	ffffe097          	auipc	ra,0xffffe
    8000607e:	7e0080e7          	jalr	2016(ra) # 8000485a <end_op>
    return -1;
    80006082:	557d                	li	a0,-1
    80006084:	b7ed                	j	8000606e <sys_chdir+0x7a>
    iunlockput(ip);
    80006086:	8526                	mv	a0,s1
    80006088:	ffffe097          	auipc	ra,0xffffe
    8000608c:	fe2080e7          	jalr	-30(ra) # 8000406a <iunlockput>
    end_op();
    80006090:	ffffe097          	auipc	ra,0xffffe
    80006094:	7ca080e7          	jalr	1994(ra) # 8000485a <end_op>
    return -1;
    80006098:	557d                	li	a0,-1
    8000609a:	bfd1                	j	8000606e <sys_chdir+0x7a>

000000008000609c <sys_exec>:

uint64
sys_exec(void)
{
    8000609c:	7145                	addi	sp,sp,-464
    8000609e:	e786                	sd	ra,456(sp)
    800060a0:	e3a2                	sd	s0,448(sp)
    800060a2:	ff26                	sd	s1,440(sp)
    800060a4:	fb4a                	sd	s2,432(sp)
    800060a6:	f74e                	sd	s3,424(sp)
    800060a8:	f352                	sd	s4,416(sp)
    800060aa:	ef56                	sd	s5,408(sp)
    800060ac:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800060ae:	08000613          	li	a2,128
    800060b2:	f4040593          	addi	a1,s0,-192
    800060b6:	4501                	li	a0,0
    800060b8:	ffffd097          	auipc	ra,0xffffd
    800060bc:	dcc080e7          	jalr	-564(ra) # 80002e84 <argstr>
    return -1;
    800060c0:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800060c2:	0c054a63          	bltz	a0,80006196 <sys_exec+0xfa>
    800060c6:	e3840593          	addi	a1,s0,-456
    800060ca:	4505                	li	a0,1
    800060cc:	ffffd097          	auipc	ra,0xffffd
    800060d0:	d96080e7          	jalr	-618(ra) # 80002e62 <argaddr>
    800060d4:	0c054163          	bltz	a0,80006196 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800060d8:	10000613          	li	a2,256
    800060dc:	4581                	li	a1,0
    800060de:	e4040513          	addi	a0,s0,-448
    800060e2:	ffffb097          	auipc	ra,0xffffb
    800060e6:	bfe080e7          	jalr	-1026(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800060ea:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800060ee:	89a6                	mv	s3,s1
    800060f0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800060f2:	02000a13          	li	s4,32
    800060f6:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800060fa:	00391513          	slli	a0,s2,0x3
    800060fe:	e3040593          	addi	a1,s0,-464
    80006102:	e3843783          	ld	a5,-456(s0)
    80006106:	953e                	add	a0,a0,a5
    80006108:	ffffd097          	auipc	ra,0xffffd
    8000610c:	c9e080e7          	jalr	-866(ra) # 80002da6 <fetchaddr>
    80006110:	02054a63          	bltz	a0,80006144 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006114:	e3043783          	ld	a5,-464(s0)
    80006118:	c3b9                	beqz	a5,8000615e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000611a:	ffffb097          	auipc	ra,0xffffb
    8000611e:	9da080e7          	jalr	-1574(ra) # 80000af4 <kalloc>
    80006122:	85aa                	mv	a1,a0
    80006124:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006128:	cd11                	beqz	a0,80006144 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000612a:	6605                	lui	a2,0x1
    8000612c:	e3043503          	ld	a0,-464(s0)
    80006130:	ffffd097          	auipc	ra,0xffffd
    80006134:	cc8080e7          	jalr	-824(ra) # 80002df8 <fetchstr>
    80006138:	00054663          	bltz	a0,80006144 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000613c:	0905                	addi	s2,s2,1
    8000613e:	09a1                	addi	s3,s3,8
    80006140:	fb491be3          	bne	s2,s4,800060f6 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006144:	10048913          	addi	s2,s1,256
    80006148:	6088                	ld	a0,0(s1)
    8000614a:	c529                	beqz	a0,80006194 <sys_exec+0xf8>
    kfree(argv[i]);
    8000614c:	ffffb097          	auipc	ra,0xffffb
    80006150:	8ac080e7          	jalr	-1876(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006154:	04a1                	addi	s1,s1,8
    80006156:	ff2499e3          	bne	s1,s2,80006148 <sys_exec+0xac>
  return -1;
    8000615a:	597d                	li	s2,-1
    8000615c:	a82d                	j	80006196 <sys_exec+0xfa>
      argv[i] = 0;
    8000615e:	0a8e                	slli	s5,s5,0x3
    80006160:	fc040793          	addi	a5,s0,-64
    80006164:	9abe                	add	s5,s5,a5
    80006166:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000616a:	e4040593          	addi	a1,s0,-448
    8000616e:	f4040513          	addi	a0,s0,-192
    80006172:	fffff097          	auipc	ra,0xfffff
    80006176:	194080e7          	jalr	404(ra) # 80005306 <exec>
    8000617a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000617c:	10048993          	addi	s3,s1,256
    80006180:	6088                	ld	a0,0(s1)
    80006182:	c911                	beqz	a0,80006196 <sys_exec+0xfa>
    kfree(argv[i]);
    80006184:	ffffb097          	auipc	ra,0xffffb
    80006188:	874080e7          	jalr	-1932(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000618c:	04a1                	addi	s1,s1,8
    8000618e:	ff3499e3          	bne	s1,s3,80006180 <sys_exec+0xe4>
    80006192:	a011                	j	80006196 <sys_exec+0xfa>
  return -1;
    80006194:	597d                	li	s2,-1
}
    80006196:	854a                	mv	a0,s2
    80006198:	60be                	ld	ra,456(sp)
    8000619a:	641e                	ld	s0,448(sp)
    8000619c:	74fa                	ld	s1,440(sp)
    8000619e:	795a                	ld	s2,432(sp)
    800061a0:	79ba                	ld	s3,424(sp)
    800061a2:	7a1a                	ld	s4,416(sp)
    800061a4:	6afa                	ld	s5,408(sp)
    800061a6:	6179                	addi	sp,sp,464
    800061a8:	8082                	ret

00000000800061aa <sys_pipe>:

uint64
sys_pipe(void)
{
    800061aa:	7139                	addi	sp,sp,-64
    800061ac:	fc06                	sd	ra,56(sp)
    800061ae:	f822                	sd	s0,48(sp)
    800061b0:	f426                	sd	s1,40(sp)
    800061b2:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800061b4:	ffffc097          	auipc	ra,0xffffc
    800061b8:	81c080e7          	jalr	-2020(ra) # 800019d0 <myproc>
    800061bc:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800061be:	fd840593          	addi	a1,s0,-40
    800061c2:	4501                	li	a0,0
    800061c4:	ffffd097          	auipc	ra,0xffffd
    800061c8:	c9e080e7          	jalr	-866(ra) # 80002e62 <argaddr>
    return -1;
    800061cc:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800061ce:	0e054063          	bltz	a0,800062ae <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800061d2:	fc840593          	addi	a1,s0,-56
    800061d6:	fd040513          	addi	a0,s0,-48
    800061da:	fffff097          	auipc	ra,0xfffff
    800061de:	dfc080e7          	jalr	-516(ra) # 80004fd6 <pipealloc>
    return -1;
    800061e2:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800061e4:	0c054563          	bltz	a0,800062ae <sys_pipe+0x104>
  fd0 = -1;
    800061e8:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800061ec:	fd043503          	ld	a0,-48(s0)
    800061f0:	fffff097          	auipc	ra,0xfffff
    800061f4:	508080e7          	jalr	1288(ra) # 800056f8 <fdalloc>
    800061f8:	fca42223          	sw	a0,-60(s0)
    800061fc:	08054c63          	bltz	a0,80006294 <sys_pipe+0xea>
    80006200:	fc843503          	ld	a0,-56(s0)
    80006204:	fffff097          	auipc	ra,0xfffff
    80006208:	4f4080e7          	jalr	1268(ra) # 800056f8 <fdalloc>
    8000620c:	fca42023          	sw	a0,-64(s0)
    80006210:	06054863          	bltz	a0,80006280 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006214:	4691                	li	a3,4
    80006216:	fc440613          	addi	a2,s0,-60
    8000621a:	fd843583          	ld	a1,-40(s0)
    8000621e:	68a8                	ld	a0,80(s1)
    80006220:	ffffb097          	auipc	ra,0xffffb
    80006224:	452080e7          	jalr	1106(ra) # 80001672 <copyout>
    80006228:	02054063          	bltz	a0,80006248 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000622c:	4691                	li	a3,4
    8000622e:	fc040613          	addi	a2,s0,-64
    80006232:	fd843583          	ld	a1,-40(s0)
    80006236:	0591                	addi	a1,a1,4
    80006238:	68a8                	ld	a0,80(s1)
    8000623a:	ffffb097          	auipc	ra,0xffffb
    8000623e:	438080e7          	jalr	1080(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006242:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006244:	06055563          	bgez	a0,800062ae <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006248:	fc442783          	lw	a5,-60(s0)
    8000624c:	07e9                	addi	a5,a5,26
    8000624e:	078e                	slli	a5,a5,0x3
    80006250:	97a6                	add	a5,a5,s1
    80006252:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006256:	fc042503          	lw	a0,-64(s0)
    8000625a:	0569                	addi	a0,a0,26
    8000625c:	050e                	slli	a0,a0,0x3
    8000625e:	9526                	add	a0,a0,s1
    80006260:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006264:	fd043503          	ld	a0,-48(s0)
    80006268:	fffff097          	auipc	ra,0xfffff
    8000626c:	a3e080e7          	jalr	-1474(ra) # 80004ca6 <fileclose>
    fileclose(wf);
    80006270:	fc843503          	ld	a0,-56(s0)
    80006274:	fffff097          	auipc	ra,0xfffff
    80006278:	a32080e7          	jalr	-1486(ra) # 80004ca6 <fileclose>
    return -1;
    8000627c:	57fd                	li	a5,-1
    8000627e:	a805                	j	800062ae <sys_pipe+0x104>
    if(fd0 >= 0)
    80006280:	fc442783          	lw	a5,-60(s0)
    80006284:	0007c863          	bltz	a5,80006294 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006288:	01a78513          	addi	a0,a5,26
    8000628c:	050e                	slli	a0,a0,0x3
    8000628e:	9526                	add	a0,a0,s1
    80006290:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006294:	fd043503          	ld	a0,-48(s0)
    80006298:	fffff097          	auipc	ra,0xfffff
    8000629c:	a0e080e7          	jalr	-1522(ra) # 80004ca6 <fileclose>
    fileclose(wf);
    800062a0:	fc843503          	ld	a0,-56(s0)
    800062a4:	fffff097          	auipc	ra,0xfffff
    800062a8:	a02080e7          	jalr	-1534(ra) # 80004ca6 <fileclose>
    return -1;
    800062ac:	57fd                	li	a5,-1
}
    800062ae:	853e                	mv	a0,a5
    800062b0:	70e2                	ld	ra,56(sp)
    800062b2:	7442                	ld	s0,48(sp)
    800062b4:	74a2                	ld	s1,40(sp)
    800062b6:	6121                	addi	sp,sp,64
    800062b8:	8082                	ret
    800062ba:	0000                	unimp
    800062bc:	0000                	unimp
	...

00000000800062c0 <kernelvec>:
    800062c0:	7111                	addi	sp,sp,-256
    800062c2:	e006                	sd	ra,0(sp)
    800062c4:	e40a                	sd	sp,8(sp)
    800062c6:	e80e                	sd	gp,16(sp)
    800062c8:	ec12                	sd	tp,24(sp)
    800062ca:	f016                	sd	t0,32(sp)
    800062cc:	f41a                	sd	t1,40(sp)
    800062ce:	f81e                	sd	t2,48(sp)
    800062d0:	fc22                	sd	s0,56(sp)
    800062d2:	e0a6                	sd	s1,64(sp)
    800062d4:	e4aa                	sd	a0,72(sp)
    800062d6:	e8ae                	sd	a1,80(sp)
    800062d8:	ecb2                	sd	a2,88(sp)
    800062da:	f0b6                	sd	a3,96(sp)
    800062dc:	f4ba                	sd	a4,104(sp)
    800062de:	f8be                	sd	a5,112(sp)
    800062e0:	fcc2                	sd	a6,120(sp)
    800062e2:	e146                	sd	a7,128(sp)
    800062e4:	e54a                	sd	s2,136(sp)
    800062e6:	e94e                	sd	s3,144(sp)
    800062e8:	ed52                	sd	s4,152(sp)
    800062ea:	f156                	sd	s5,160(sp)
    800062ec:	f55a                	sd	s6,168(sp)
    800062ee:	f95e                	sd	s7,176(sp)
    800062f0:	fd62                	sd	s8,184(sp)
    800062f2:	e1e6                	sd	s9,192(sp)
    800062f4:	e5ea                	sd	s10,200(sp)
    800062f6:	e9ee                	sd	s11,208(sp)
    800062f8:	edf2                	sd	t3,216(sp)
    800062fa:	f1f6                	sd	t4,224(sp)
    800062fc:	f5fa                	sd	t5,232(sp)
    800062fe:	f9fe                	sd	t6,240(sp)
    80006300:	973fc0ef          	jal	ra,80002c72 <kerneltrap>
    80006304:	6082                	ld	ra,0(sp)
    80006306:	6122                	ld	sp,8(sp)
    80006308:	61c2                	ld	gp,16(sp)
    8000630a:	7282                	ld	t0,32(sp)
    8000630c:	7322                	ld	t1,40(sp)
    8000630e:	73c2                	ld	t2,48(sp)
    80006310:	7462                	ld	s0,56(sp)
    80006312:	6486                	ld	s1,64(sp)
    80006314:	6526                	ld	a0,72(sp)
    80006316:	65c6                	ld	a1,80(sp)
    80006318:	6666                	ld	a2,88(sp)
    8000631a:	7686                	ld	a3,96(sp)
    8000631c:	7726                	ld	a4,104(sp)
    8000631e:	77c6                	ld	a5,112(sp)
    80006320:	7866                	ld	a6,120(sp)
    80006322:	688a                	ld	a7,128(sp)
    80006324:	692a                	ld	s2,136(sp)
    80006326:	69ca                	ld	s3,144(sp)
    80006328:	6a6a                	ld	s4,152(sp)
    8000632a:	7a8a                	ld	s5,160(sp)
    8000632c:	7b2a                	ld	s6,168(sp)
    8000632e:	7bca                	ld	s7,176(sp)
    80006330:	7c6a                	ld	s8,184(sp)
    80006332:	6c8e                	ld	s9,192(sp)
    80006334:	6d2e                	ld	s10,200(sp)
    80006336:	6dce                	ld	s11,208(sp)
    80006338:	6e6e                	ld	t3,216(sp)
    8000633a:	7e8e                	ld	t4,224(sp)
    8000633c:	7f2e                	ld	t5,232(sp)
    8000633e:	7fce                	ld	t6,240(sp)
    80006340:	6111                	addi	sp,sp,256
    80006342:	10200073          	sret
    80006346:	00000013          	nop
    8000634a:	00000013          	nop
    8000634e:	0001                	nop

0000000080006350 <timervec>:
    80006350:	34051573          	csrrw	a0,mscratch,a0
    80006354:	e10c                	sd	a1,0(a0)
    80006356:	e510                	sd	a2,8(a0)
    80006358:	e914                	sd	a3,16(a0)
    8000635a:	6d0c                	ld	a1,24(a0)
    8000635c:	7110                	ld	a2,32(a0)
    8000635e:	6194                	ld	a3,0(a1)
    80006360:	96b2                	add	a3,a3,a2
    80006362:	e194                	sd	a3,0(a1)
    80006364:	4589                	li	a1,2
    80006366:	14459073          	csrw	sip,a1
    8000636a:	6914                	ld	a3,16(a0)
    8000636c:	6510                	ld	a2,8(a0)
    8000636e:	610c                	ld	a1,0(a0)
    80006370:	34051573          	csrrw	a0,mscratch,a0
    80006374:	30200073          	mret
	...

000000008000637a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000637a:	1141                	addi	sp,sp,-16
    8000637c:	e422                	sd	s0,8(sp)
    8000637e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006380:	0c0007b7          	lui	a5,0xc000
    80006384:	4705                	li	a4,1
    80006386:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006388:	c3d8                	sw	a4,4(a5)
}
    8000638a:	6422                	ld	s0,8(sp)
    8000638c:	0141                	addi	sp,sp,16
    8000638e:	8082                	ret

0000000080006390 <plicinithart>:

void
plicinithart(void)
{
    80006390:	1141                	addi	sp,sp,-16
    80006392:	e406                	sd	ra,8(sp)
    80006394:	e022                	sd	s0,0(sp)
    80006396:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006398:	ffffb097          	auipc	ra,0xffffb
    8000639c:	60c080e7          	jalr	1548(ra) # 800019a4 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800063a0:	0085171b          	slliw	a4,a0,0x8
    800063a4:	0c0027b7          	lui	a5,0xc002
    800063a8:	97ba                	add	a5,a5,a4
    800063aa:	40200713          	li	a4,1026
    800063ae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800063b2:	00d5151b          	slliw	a0,a0,0xd
    800063b6:	0c2017b7          	lui	a5,0xc201
    800063ba:	953e                	add	a0,a0,a5
    800063bc:	00052023          	sw	zero,0(a0)
}
    800063c0:	60a2                	ld	ra,8(sp)
    800063c2:	6402                	ld	s0,0(sp)
    800063c4:	0141                	addi	sp,sp,16
    800063c6:	8082                	ret

00000000800063c8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800063c8:	1141                	addi	sp,sp,-16
    800063ca:	e406                	sd	ra,8(sp)
    800063cc:	e022                	sd	s0,0(sp)
    800063ce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063d0:	ffffb097          	auipc	ra,0xffffb
    800063d4:	5d4080e7          	jalr	1492(ra) # 800019a4 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800063d8:	00d5179b          	slliw	a5,a0,0xd
    800063dc:	0c201537          	lui	a0,0xc201
    800063e0:	953e                	add	a0,a0,a5
  return irq;
}
    800063e2:	4148                	lw	a0,4(a0)
    800063e4:	60a2                	ld	ra,8(sp)
    800063e6:	6402                	ld	s0,0(sp)
    800063e8:	0141                	addi	sp,sp,16
    800063ea:	8082                	ret

00000000800063ec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800063ec:	1101                	addi	sp,sp,-32
    800063ee:	ec06                	sd	ra,24(sp)
    800063f0:	e822                	sd	s0,16(sp)
    800063f2:	e426                	sd	s1,8(sp)
    800063f4:	1000                	addi	s0,sp,32
    800063f6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800063f8:	ffffb097          	auipc	ra,0xffffb
    800063fc:	5ac080e7          	jalr	1452(ra) # 800019a4 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006400:	00d5151b          	slliw	a0,a0,0xd
    80006404:	0c2017b7          	lui	a5,0xc201
    80006408:	97aa                	add	a5,a5,a0
    8000640a:	c3c4                	sw	s1,4(a5)
}
    8000640c:	60e2                	ld	ra,24(sp)
    8000640e:	6442                	ld	s0,16(sp)
    80006410:	64a2                	ld	s1,8(sp)
    80006412:	6105                	addi	sp,sp,32
    80006414:	8082                	ret

0000000080006416 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006416:	1141                	addi	sp,sp,-16
    80006418:	e406                	sd	ra,8(sp)
    8000641a:	e022                	sd	s0,0(sp)
    8000641c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000641e:	479d                	li	a5,7
    80006420:	06a7c963          	blt	a5,a0,80006492 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006424:	000d9797          	auipc	a5,0xd9
    80006428:	bdc78793          	addi	a5,a5,-1060 # 800df000 <disk>
    8000642c:	00a78733          	add	a4,a5,a0
    80006430:	6789                	lui	a5,0x2
    80006432:	97ba                	add	a5,a5,a4
    80006434:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006438:	e7ad                	bnez	a5,800064a2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000643a:	00451793          	slli	a5,a0,0x4
    8000643e:	000db717          	auipc	a4,0xdb
    80006442:	bc270713          	addi	a4,a4,-1086 # 800e1000 <disk+0x2000>
    80006446:	6314                	ld	a3,0(a4)
    80006448:	96be                	add	a3,a3,a5
    8000644a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000644e:	6314                	ld	a3,0(a4)
    80006450:	96be                	add	a3,a3,a5
    80006452:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006456:	6314                	ld	a3,0(a4)
    80006458:	96be                	add	a3,a3,a5
    8000645a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000645e:	6318                	ld	a4,0(a4)
    80006460:	97ba                	add	a5,a5,a4
    80006462:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006466:	000d9797          	auipc	a5,0xd9
    8000646a:	b9a78793          	addi	a5,a5,-1126 # 800df000 <disk>
    8000646e:	97aa                	add	a5,a5,a0
    80006470:	6509                	lui	a0,0x2
    80006472:	953e                	add	a0,a0,a5
    80006474:	4785                	li	a5,1
    80006476:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000647a:	000db517          	auipc	a0,0xdb
    8000647e:	b9e50513          	addi	a0,a0,-1122 # 800e1018 <disk+0x2018>
    80006482:	ffffc097          	auipc	ra,0xffffc
    80006486:	fc2080e7          	jalr	-62(ra) # 80002444 <wakeup>
}
    8000648a:	60a2                	ld	ra,8(sp)
    8000648c:	6402                	ld	s0,0(sp)
    8000648e:	0141                	addi	sp,sp,16
    80006490:	8082                	ret
    panic("free_desc 1");
    80006492:	00002517          	auipc	a0,0x2
    80006496:	48e50513          	addi	a0,a0,1166 # 80008920 <syscalls+0x328>
    8000649a:	ffffa097          	auipc	ra,0xffffa
    8000649e:	0a4080e7          	jalr	164(ra) # 8000053e <panic>
    panic("free_desc 2");
    800064a2:	00002517          	auipc	a0,0x2
    800064a6:	48e50513          	addi	a0,a0,1166 # 80008930 <syscalls+0x338>
    800064aa:	ffffa097          	auipc	ra,0xffffa
    800064ae:	094080e7          	jalr	148(ra) # 8000053e <panic>

00000000800064b2 <virtio_disk_init>:
{
    800064b2:	1101                	addi	sp,sp,-32
    800064b4:	ec06                	sd	ra,24(sp)
    800064b6:	e822                	sd	s0,16(sp)
    800064b8:	e426                	sd	s1,8(sp)
    800064ba:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800064bc:	00002597          	auipc	a1,0x2
    800064c0:	48458593          	addi	a1,a1,1156 # 80008940 <syscalls+0x348>
    800064c4:	000db517          	auipc	a0,0xdb
    800064c8:	c6450513          	addi	a0,a0,-924 # 800e1128 <disk+0x2128>
    800064cc:	ffffa097          	auipc	ra,0xffffa
    800064d0:	688080e7          	jalr	1672(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064d4:	100017b7          	lui	a5,0x10001
    800064d8:	4398                	lw	a4,0(a5)
    800064da:	2701                	sext.w	a4,a4
    800064dc:	747277b7          	lui	a5,0x74727
    800064e0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800064e4:	0ef71163          	bne	a4,a5,800065c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800064e8:	100017b7          	lui	a5,0x10001
    800064ec:	43dc                	lw	a5,4(a5)
    800064ee:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064f0:	4705                	li	a4,1
    800064f2:	0ce79a63          	bne	a5,a4,800065c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064f6:	100017b7          	lui	a5,0x10001
    800064fa:	479c                	lw	a5,8(a5)
    800064fc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800064fe:	4709                	li	a4,2
    80006500:	0ce79363          	bne	a5,a4,800065c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006504:	100017b7          	lui	a5,0x10001
    80006508:	47d8                	lw	a4,12(a5)
    8000650a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000650c:	554d47b7          	lui	a5,0x554d4
    80006510:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006514:	0af71963          	bne	a4,a5,800065c6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006518:	100017b7          	lui	a5,0x10001
    8000651c:	4705                	li	a4,1
    8000651e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006520:	470d                	li	a4,3
    80006522:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006524:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006526:	c7ffe737          	lui	a4,0xc7ffe
    8000652a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47f1c75f>
    8000652e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006530:	2701                	sext.w	a4,a4
    80006532:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006534:	472d                	li	a4,11
    80006536:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006538:	473d                	li	a4,15
    8000653a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000653c:	6705                	lui	a4,0x1
    8000653e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006540:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006544:	5bdc                	lw	a5,52(a5)
    80006546:	2781                	sext.w	a5,a5
  if(max == 0)
    80006548:	c7d9                	beqz	a5,800065d6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000654a:	471d                	li	a4,7
    8000654c:	08f77d63          	bgeu	a4,a5,800065e6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006550:	100014b7          	lui	s1,0x10001
    80006554:	47a1                	li	a5,8
    80006556:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006558:	6609                	lui	a2,0x2
    8000655a:	4581                	li	a1,0
    8000655c:	000d9517          	auipc	a0,0xd9
    80006560:	aa450513          	addi	a0,a0,-1372 # 800df000 <disk>
    80006564:	ffffa097          	auipc	ra,0xffffa
    80006568:	77c080e7          	jalr	1916(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000656c:	000d9717          	auipc	a4,0xd9
    80006570:	a9470713          	addi	a4,a4,-1388 # 800df000 <disk>
    80006574:	00c75793          	srli	a5,a4,0xc
    80006578:	2781                	sext.w	a5,a5
    8000657a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000657c:	000db797          	auipc	a5,0xdb
    80006580:	a8478793          	addi	a5,a5,-1404 # 800e1000 <disk+0x2000>
    80006584:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006586:	000d9717          	auipc	a4,0xd9
    8000658a:	afa70713          	addi	a4,a4,-1286 # 800df080 <disk+0x80>
    8000658e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006590:	000da717          	auipc	a4,0xda
    80006594:	a7070713          	addi	a4,a4,-1424 # 800e0000 <disk+0x1000>
    80006598:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000659a:	4705                	li	a4,1
    8000659c:	00e78c23          	sb	a4,24(a5)
    800065a0:	00e78ca3          	sb	a4,25(a5)
    800065a4:	00e78d23          	sb	a4,26(a5)
    800065a8:	00e78da3          	sb	a4,27(a5)
    800065ac:	00e78e23          	sb	a4,28(a5)
    800065b0:	00e78ea3          	sb	a4,29(a5)
    800065b4:	00e78f23          	sb	a4,30(a5)
    800065b8:	00e78fa3          	sb	a4,31(a5)
}
    800065bc:	60e2                	ld	ra,24(sp)
    800065be:	6442                	ld	s0,16(sp)
    800065c0:	64a2                	ld	s1,8(sp)
    800065c2:	6105                	addi	sp,sp,32
    800065c4:	8082                	ret
    panic("could not find virtio disk");
    800065c6:	00002517          	auipc	a0,0x2
    800065ca:	38a50513          	addi	a0,a0,906 # 80008950 <syscalls+0x358>
    800065ce:	ffffa097          	auipc	ra,0xffffa
    800065d2:	f70080e7          	jalr	-144(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800065d6:	00002517          	auipc	a0,0x2
    800065da:	39a50513          	addi	a0,a0,922 # 80008970 <syscalls+0x378>
    800065de:	ffffa097          	auipc	ra,0xffffa
    800065e2:	f60080e7          	jalr	-160(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800065e6:	00002517          	auipc	a0,0x2
    800065ea:	3aa50513          	addi	a0,a0,938 # 80008990 <syscalls+0x398>
    800065ee:	ffffa097          	auipc	ra,0xffffa
    800065f2:	f50080e7          	jalr	-176(ra) # 8000053e <panic>

00000000800065f6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800065f6:	7159                	addi	sp,sp,-112
    800065f8:	f486                	sd	ra,104(sp)
    800065fa:	f0a2                	sd	s0,96(sp)
    800065fc:	eca6                	sd	s1,88(sp)
    800065fe:	e8ca                	sd	s2,80(sp)
    80006600:	e4ce                	sd	s3,72(sp)
    80006602:	e0d2                	sd	s4,64(sp)
    80006604:	fc56                	sd	s5,56(sp)
    80006606:	f85a                	sd	s6,48(sp)
    80006608:	f45e                	sd	s7,40(sp)
    8000660a:	f062                	sd	s8,32(sp)
    8000660c:	ec66                	sd	s9,24(sp)
    8000660e:	e86a                	sd	s10,16(sp)
    80006610:	1880                	addi	s0,sp,112
    80006612:	892a                	mv	s2,a0
    80006614:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006616:	00c52c83          	lw	s9,12(a0)
    8000661a:	001c9c9b          	slliw	s9,s9,0x1
    8000661e:	1c82                	slli	s9,s9,0x20
    80006620:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006624:	000db517          	auipc	a0,0xdb
    80006628:	b0450513          	addi	a0,a0,-1276 # 800e1128 <disk+0x2128>
    8000662c:	ffffa097          	auipc	ra,0xffffa
    80006630:	5b8080e7          	jalr	1464(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006634:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006636:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006638:	000d9b97          	auipc	s7,0xd9
    8000663c:	9c8b8b93          	addi	s7,s7,-1592 # 800df000 <disk>
    80006640:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006642:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006644:	8a4e                	mv	s4,s3
    80006646:	a051                	j	800066ca <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006648:	00fb86b3          	add	a3,s7,a5
    8000664c:	96da                	add	a3,a3,s6
    8000664e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006652:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006654:	0207c563          	bltz	a5,8000667e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006658:	2485                	addiw	s1,s1,1
    8000665a:	0711                	addi	a4,a4,4
    8000665c:	25548063          	beq	s1,s5,8000689c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006660:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006662:	000db697          	auipc	a3,0xdb
    80006666:	9b668693          	addi	a3,a3,-1610 # 800e1018 <disk+0x2018>
    8000666a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000666c:	0006c583          	lbu	a1,0(a3)
    80006670:	fde1                	bnez	a1,80006648 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006672:	2785                	addiw	a5,a5,1
    80006674:	0685                	addi	a3,a3,1
    80006676:	ff879be3          	bne	a5,s8,8000666c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000667a:	57fd                	li	a5,-1
    8000667c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000667e:	02905a63          	blez	s1,800066b2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006682:	f9042503          	lw	a0,-112(s0)
    80006686:	00000097          	auipc	ra,0x0
    8000668a:	d90080e7          	jalr	-624(ra) # 80006416 <free_desc>
      for(int j = 0; j < i; j++)
    8000668e:	4785                	li	a5,1
    80006690:	0297d163          	bge	a5,s1,800066b2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006694:	f9442503          	lw	a0,-108(s0)
    80006698:	00000097          	auipc	ra,0x0
    8000669c:	d7e080e7          	jalr	-642(ra) # 80006416 <free_desc>
      for(int j = 0; j < i; j++)
    800066a0:	4789                	li	a5,2
    800066a2:	0097d863          	bge	a5,s1,800066b2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800066a6:	f9842503          	lw	a0,-104(s0)
    800066aa:	00000097          	auipc	ra,0x0
    800066ae:	d6c080e7          	jalr	-660(ra) # 80006416 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800066b2:	000db597          	auipc	a1,0xdb
    800066b6:	a7658593          	addi	a1,a1,-1418 # 800e1128 <disk+0x2128>
    800066ba:	000db517          	auipc	a0,0xdb
    800066be:	95e50513          	addi	a0,a0,-1698 # 800e1018 <disk+0x2018>
    800066c2:	ffffc097          	auipc	ra,0xffffc
    800066c6:	ab2080e7          	jalr	-1358(ra) # 80002174 <sleep>
  for(int i = 0; i < 3; i++){
    800066ca:	f9040713          	addi	a4,s0,-112
    800066ce:	84ce                	mv	s1,s3
    800066d0:	bf41                	j	80006660 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800066d2:	20058713          	addi	a4,a1,512
    800066d6:	00471693          	slli	a3,a4,0x4
    800066da:	000d9717          	auipc	a4,0xd9
    800066de:	92670713          	addi	a4,a4,-1754 # 800df000 <disk>
    800066e2:	9736                	add	a4,a4,a3
    800066e4:	4685                	li	a3,1
    800066e6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800066ea:	20058713          	addi	a4,a1,512
    800066ee:	00471693          	slli	a3,a4,0x4
    800066f2:	000d9717          	auipc	a4,0xd9
    800066f6:	90e70713          	addi	a4,a4,-1778 # 800df000 <disk>
    800066fa:	9736                	add	a4,a4,a3
    800066fc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006700:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006704:	7679                	lui	a2,0xffffe
    80006706:	963e                	add	a2,a2,a5
    80006708:	000db697          	auipc	a3,0xdb
    8000670c:	8f868693          	addi	a3,a3,-1800 # 800e1000 <disk+0x2000>
    80006710:	6298                	ld	a4,0(a3)
    80006712:	9732                	add	a4,a4,a2
    80006714:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006716:	6298                	ld	a4,0(a3)
    80006718:	9732                	add	a4,a4,a2
    8000671a:	4541                	li	a0,16
    8000671c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000671e:	6298                	ld	a4,0(a3)
    80006720:	9732                	add	a4,a4,a2
    80006722:	4505                	li	a0,1
    80006724:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006728:	f9442703          	lw	a4,-108(s0)
    8000672c:	6288                	ld	a0,0(a3)
    8000672e:	962a                	add	a2,a2,a0
    80006730:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ff1c00e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006734:	0712                	slli	a4,a4,0x4
    80006736:	6290                	ld	a2,0(a3)
    80006738:	963a                	add	a2,a2,a4
    8000673a:	05890513          	addi	a0,s2,88
    8000673e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006740:	6294                	ld	a3,0(a3)
    80006742:	96ba                	add	a3,a3,a4
    80006744:	40000613          	li	a2,1024
    80006748:	c690                	sw	a2,8(a3)
  if(write)
    8000674a:	140d0063          	beqz	s10,8000688a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000674e:	000db697          	auipc	a3,0xdb
    80006752:	8b26b683          	ld	a3,-1870(a3) # 800e1000 <disk+0x2000>
    80006756:	96ba                	add	a3,a3,a4
    80006758:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000675c:	000d9817          	auipc	a6,0xd9
    80006760:	8a480813          	addi	a6,a6,-1884 # 800df000 <disk>
    80006764:	000db517          	auipc	a0,0xdb
    80006768:	89c50513          	addi	a0,a0,-1892 # 800e1000 <disk+0x2000>
    8000676c:	6114                	ld	a3,0(a0)
    8000676e:	96ba                	add	a3,a3,a4
    80006770:	00c6d603          	lhu	a2,12(a3)
    80006774:	00166613          	ori	a2,a2,1
    80006778:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000677c:	f9842683          	lw	a3,-104(s0)
    80006780:	6110                	ld	a2,0(a0)
    80006782:	9732                	add	a4,a4,a2
    80006784:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006788:	20058613          	addi	a2,a1,512
    8000678c:	0612                	slli	a2,a2,0x4
    8000678e:	9642                	add	a2,a2,a6
    80006790:	577d                	li	a4,-1
    80006792:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006796:	00469713          	slli	a4,a3,0x4
    8000679a:	6114                	ld	a3,0(a0)
    8000679c:	96ba                	add	a3,a3,a4
    8000679e:	03078793          	addi	a5,a5,48
    800067a2:	97c2                	add	a5,a5,a6
    800067a4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800067a6:	611c                	ld	a5,0(a0)
    800067a8:	97ba                	add	a5,a5,a4
    800067aa:	4685                	li	a3,1
    800067ac:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800067ae:	611c                	ld	a5,0(a0)
    800067b0:	97ba                	add	a5,a5,a4
    800067b2:	4809                	li	a6,2
    800067b4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800067b8:	611c                	ld	a5,0(a0)
    800067ba:	973e                	add	a4,a4,a5
    800067bc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800067c0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800067c4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800067c8:	6518                	ld	a4,8(a0)
    800067ca:	00275783          	lhu	a5,2(a4)
    800067ce:	8b9d                	andi	a5,a5,7
    800067d0:	0786                	slli	a5,a5,0x1
    800067d2:	97ba                	add	a5,a5,a4
    800067d4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800067d8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800067dc:	6518                	ld	a4,8(a0)
    800067de:	00275783          	lhu	a5,2(a4)
    800067e2:	2785                	addiw	a5,a5,1
    800067e4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800067e8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800067ec:	100017b7          	lui	a5,0x10001
    800067f0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800067f4:	00492703          	lw	a4,4(s2)
    800067f8:	4785                	li	a5,1
    800067fa:	02f71163          	bne	a4,a5,8000681c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800067fe:	000db997          	auipc	s3,0xdb
    80006802:	92a98993          	addi	s3,s3,-1750 # 800e1128 <disk+0x2128>
  while(b->disk == 1) {
    80006806:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006808:	85ce                	mv	a1,s3
    8000680a:	854a                	mv	a0,s2
    8000680c:	ffffc097          	auipc	ra,0xffffc
    80006810:	968080e7          	jalr	-1688(ra) # 80002174 <sleep>
  while(b->disk == 1) {
    80006814:	00492783          	lw	a5,4(s2)
    80006818:	fe9788e3          	beq	a5,s1,80006808 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000681c:	f9042903          	lw	s2,-112(s0)
    80006820:	20090793          	addi	a5,s2,512
    80006824:	00479713          	slli	a4,a5,0x4
    80006828:	000d8797          	auipc	a5,0xd8
    8000682c:	7d878793          	addi	a5,a5,2008 # 800df000 <disk>
    80006830:	97ba                	add	a5,a5,a4
    80006832:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006836:	000da997          	auipc	s3,0xda
    8000683a:	7ca98993          	addi	s3,s3,1994 # 800e1000 <disk+0x2000>
    8000683e:	00491713          	slli	a4,s2,0x4
    80006842:	0009b783          	ld	a5,0(s3)
    80006846:	97ba                	add	a5,a5,a4
    80006848:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000684c:	854a                	mv	a0,s2
    8000684e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006852:	00000097          	auipc	ra,0x0
    80006856:	bc4080e7          	jalr	-1084(ra) # 80006416 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000685a:	8885                	andi	s1,s1,1
    8000685c:	f0ed                	bnez	s1,8000683e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000685e:	000db517          	auipc	a0,0xdb
    80006862:	8ca50513          	addi	a0,a0,-1846 # 800e1128 <disk+0x2128>
    80006866:	ffffa097          	auipc	ra,0xffffa
    8000686a:	432080e7          	jalr	1074(ra) # 80000c98 <release>
}
    8000686e:	70a6                	ld	ra,104(sp)
    80006870:	7406                	ld	s0,96(sp)
    80006872:	64e6                	ld	s1,88(sp)
    80006874:	6946                	ld	s2,80(sp)
    80006876:	69a6                	ld	s3,72(sp)
    80006878:	6a06                	ld	s4,64(sp)
    8000687a:	7ae2                	ld	s5,56(sp)
    8000687c:	7b42                	ld	s6,48(sp)
    8000687e:	7ba2                	ld	s7,40(sp)
    80006880:	7c02                	ld	s8,32(sp)
    80006882:	6ce2                	ld	s9,24(sp)
    80006884:	6d42                	ld	s10,16(sp)
    80006886:	6165                	addi	sp,sp,112
    80006888:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000688a:	000da697          	auipc	a3,0xda
    8000688e:	7766b683          	ld	a3,1910(a3) # 800e1000 <disk+0x2000>
    80006892:	96ba                	add	a3,a3,a4
    80006894:	4609                	li	a2,2
    80006896:	00c69623          	sh	a2,12(a3)
    8000689a:	b5c9                	j	8000675c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000689c:	f9042583          	lw	a1,-112(s0)
    800068a0:	20058793          	addi	a5,a1,512
    800068a4:	0792                	slli	a5,a5,0x4
    800068a6:	000d9517          	auipc	a0,0xd9
    800068aa:	80250513          	addi	a0,a0,-2046 # 800df0a8 <disk+0xa8>
    800068ae:	953e                	add	a0,a0,a5
  if(write)
    800068b0:	e20d11e3          	bnez	s10,800066d2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800068b4:	20058713          	addi	a4,a1,512
    800068b8:	00471693          	slli	a3,a4,0x4
    800068bc:	000d8717          	auipc	a4,0xd8
    800068c0:	74470713          	addi	a4,a4,1860 # 800df000 <disk>
    800068c4:	9736                	add	a4,a4,a3
    800068c6:	0a072423          	sw	zero,168(a4)
    800068ca:	b505                	j	800066ea <virtio_disk_rw+0xf4>

00000000800068cc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800068cc:	1101                	addi	sp,sp,-32
    800068ce:	ec06                	sd	ra,24(sp)
    800068d0:	e822                	sd	s0,16(sp)
    800068d2:	e426                	sd	s1,8(sp)
    800068d4:	e04a                	sd	s2,0(sp)
    800068d6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800068d8:	000db517          	auipc	a0,0xdb
    800068dc:	85050513          	addi	a0,a0,-1968 # 800e1128 <disk+0x2128>
    800068e0:	ffffa097          	auipc	ra,0xffffa
    800068e4:	304080e7          	jalr	772(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800068e8:	10001737          	lui	a4,0x10001
    800068ec:	533c                	lw	a5,96(a4)
    800068ee:	8b8d                	andi	a5,a5,3
    800068f0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800068f2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800068f6:	000da797          	auipc	a5,0xda
    800068fa:	70a78793          	addi	a5,a5,1802 # 800e1000 <disk+0x2000>
    800068fe:	6b94                	ld	a3,16(a5)
    80006900:	0207d703          	lhu	a4,32(a5)
    80006904:	0026d783          	lhu	a5,2(a3)
    80006908:	06f70163          	beq	a4,a5,8000696a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000690c:	000d8917          	auipc	s2,0xd8
    80006910:	6f490913          	addi	s2,s2,1780 # 800df000 <disk>
    80006914:	000da497          	auipc	s1,0xda
    80006918:	6ec48493          	addi	s1,s1,1772 # 800e1000 <disk+0x2000>
    __sync_synchronize();
    8000691c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006920:	6898                	ld	a4,16(s1)
    80006922:	0204d783          	lhu	a5,32(s1)
    80006926:	8b9d                	andi	a5,a5,7
    80006928:	078e                	slli	a5,a5,0x3
    8000692a:	97ba                	add	a5,a5,a4
    8000692c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000692e:	20078713          	addi	a4,a5,512
    80006932:	0712                	slli	a4,a4,0x4
    80006934:	974a                	add	a4,a4,s2
    80006936:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000693a:	e731                	bnez	a4,80006986 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000693c:	20078793          	addi	a5,a5,512
    80006940:	0792                	slli	a5,a5,0x4
    80006942:	97ca                	add	a5,a5,s2
    80006944:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006946:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000694a:	ffffc097          	auipc	ra,0xffffc
    8000694e:	afa080e7          	jalr	-1286(ra) # 80002444 <wakeup>

    disk.used_idx += 1;
    80006952:	0204d783          	lhu	a5,32(s1)
    80006956:	2785                	addiw	a5,a5,1
    80006958:	17c2                	slli	a5,a5,0x30
    8000695a:	93c1                	srli	a5,a5,0x30
    8000695c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006960:	6898                	ld	a4,16(s1)
    80006962:	00275703          	lhu	a4,2(a4)
    80006966:	faf71be3          	bne	a4,a5,8000691c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000696a:	000da517          	auipc	a0,0xda
    8000696e:	7be50513          	addi	a0,a0,1982 # 800e1128 <disk+0x2128>
    80006972:	ffffa097          	auipc	ra,0xffffa
    80006976:	326080e7          	jalr	806(ra) # 80000c98 <release>
}
    8000697a:	60e2                	ld	ra,24(sp)
    8000697c:	6442                	ld	s0,16(sp)
    8000697e:	64a2                	ld	s1,8(sp)
    80006980:	6902                	ld	s2,0(sp)
    80006982:	6105                	addi	sp,sp,32
    80006984:	8082                	ret
      panic("virtio_disk_intr status");
    80006986:	00002517          	auipc	a0,0x2
    8000698a:	02a50513          	addi	a0,a0,42 # 800089b0 <syscalls+0x3b8>
    8000698e:	ffffa097          	auipc	ra,0xffffa
    80006992:	bb0080e7          	jalr	-1104(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
