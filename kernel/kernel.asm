
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	97013103          	ld	sp,-1680(sp) # 80008970 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
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
    80000056:	97e70713          	addi	a4,a4,-1666 # 800089d0 <timer_scratch>
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
    80000068:	4fc78793          	addi	a5,a5,1276 # 80006560 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd03bf>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dca78793          	addi	a5,a5,-566 # 80000e78 <main>
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
    80000130:	57c080e7          	jalr	1404(ra) # 800026a8 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	780080e7          	jalr	1920(ra) # 800008bc <uartputc>
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
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	98650513          	addi	a0,a0,-1658 # 80010b10 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	97648493          	addi	s1,s1,-1674 # 80010b10 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	a0690913          	addi	s2,s2,-1530 # 80010ba8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	938080e7          	jalr	-1736(ra) # 80001af8 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	32a080e7          	jalr	810(ra) # 800024f2 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	05e080e7          	jalr	94(ra) # 80002234 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	440080e7          	jalr	1088(ra) # 80002652 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	8ea50513          	addi	a0,a0,-1814 # 80010b10 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	8d450513          	addi	a0,a0,-1836 # 80010b10 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	92f72b23          	sw	a5,-1738(a4) # 80010ba8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

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
    80000290:	55e080e7          	jalr	1374(ra) # 800007ea <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54c080e7          	jalr	1356(ra) # 800007ea <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	540080e7          	jalr	1344(ra) # 800007ea <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	536080e7          	jalr	1334(ra) # 800007ea <uartputc_sync>
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
    800002d0:	84450513          	addi	a0,a0,-1980 # 80010b10 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

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
    800002f6:	40c080e7          	jalr	1036(ra) # 800026fe <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	81650513          	addi	a0,a0,-2026 # 80010b10 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
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
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	7f270713          	addi	a4,a4,2034 # 80010b10 <cons>
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
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	7c878793          	addi	a5,a5,1992 # 80010b10 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	8327a783          	lw	a5,-1998(a5) # 80010ba8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	78670713          	addi	a4,a4,1926 # 80010b10 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	77648493          	addi	s1,s1,1910 # 80010b10 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
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
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	73a70713          	addi	a4,a4,1850 # 80010b10 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	7cf72223          	sw	a5,1988(a4) # 80010bb0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	6fe78793          	addi	a5,a5,1790 # 80010b10 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	76c7ab23          	sw	a2,1910(a5) # 80010bac <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	76a50513          	addi	a0,a0,1898 # 80010ba8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	e52080e7          	jalr	-430(ra) # 80002298 <wakeup>
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
    80000460:	00010517          	auipc	a0,0x10
    80000464:	6b050513          	addi	a0,a0,1712 # 80010b10 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	0002d797          	auipc	a5,0x2d
    8000047c:	e3078793          	addi	a5,a5,-464 # 8002d2a8 <devsw>
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
    8000054a:	00010797          	auipc	a5,0x10
    8000054e:	6807a323          	sw	zero,1670(a5) # 80010bd0 <pr+0x18>
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
    80000570:	e2450513          	addi	a0,a0,-476 # 80008390 <states.0+0xa0>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00008717          	auipc	a4,0x8
    80000582:	40f72923          	sw	a5,1042(a4) # 80008990 <panicked>
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
    800005ba:	00010d97          	auipc	s11,0x10
    800005be:	616dad83          	lw	s11,1558(s11) # 80010bd0 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	14050f63          	beqz	a0,80000734 <printf+0x1ac>
    800005da:	4981                	li	s3,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b93          	li	s7,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b17          	auipc	s6,0x8
    800005ea:	a5ab0b13          	addi	s6,s6,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00010517          	auipc	a0,0x10
    800005fc:	5c050513          	addi	a0,a0,1472 # 80010bb8 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5d6080e7          	jalr	1494(ra) # 80000bd6 <acquire>
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
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050463          	beqz	a0,80000734 <printf+0x1ac>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2985                	addiw	s3,s3,1
    80000636:	013a07b3          	add	a5,s4,s3
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000642:	cbed                	beqz	a5,80000734 <printf+0x1ac>
    switch(c){
    80000644:	05778a63          	beq	a5,s7,80000698 <printf+0x110>
    80000648:	02fbf663          	bgeu	s7,a5,80000674 <printf+0xec>
    8000064c:	09978863          	beq	a5,s9,800006dc <printf+0x154>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79563          	bne	a5,a4,8000071e <printf+0x196>
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
    80000674:	09578f63          	beq	a5,s5,80000712 <printf+0x18a>
    80000678:	0b879363          	bne	a5,s8,8000071e <printf+0x196>
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
    800006a4:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c95793          	srli	a5,s2,0x3c
    800006c6:	97da                	add	a5,a5,s6
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0912                	slli	s2,s2,0x4
    800006d6:	34fd                	addiw	s1,s1,-1
    800006d8:	f4ed                	bnez	s1,800006c2 <printf+0x13a>
    800006da:	b7a1                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	6384                	ld	s1,0(a5)
    800006ea:	cc89                	beqz	s1,80000704 <printf+0x17c>
      for(; *s; s++)
    800006ec:	0004c503          	lbu	a0,0(s1)
    800006f0:	d90d                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b8a080e7          	jalr	-1142(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fa:	0485                	addi	s1,s1,1
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	f96d                	bnez	a0,800006f2 <printf+0x16a>
    80000702:	b705                	j	80000622 <printf+0x9a>
        s = "(null)";
    80000704:	00008497          	auipc	s1,0x8
    80000708:	91c48493          	addi	s1,s1,-1764 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070c:	02800513          	li	a0,40
    80000710:	b7cd                	j	800006f2 <printf+0x16a>
      consputc('%');
    80000712:	8556                	mv	a0,s5
    80000714:	00000097          	auipc	ra,0x0
    80000718:	b68080e7          	jalr	-1176(ra) # 8000027c <consputc>
      break;
    8000071c:	b719                	j	80000622 <printf+0x9a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
      consputc(c);
    80000728:	8526                	mv	a0,s1
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b52080e7          	jalr	-1198(ra) # 8000027c <consputc>
      break;
    80000732:	bdc5                	j	80000622 <printf+0x9a>
  if(locking)
    80000734:	020d9163          	bnez	s11,80000756 <printf+0x1ce>
}
    80000738:	70e6                	ld	ra,120(sp)
    8000073a:	7446                	ld	s0,112(sp)
    8000073c:	74a6                	ld	s1,104(sp)
    8000073e:	7906                	ld	s2,96(sp)
    80000740:	69e6                	ld	s3,88(sp)
    80000742:	6a46                	ld	s4,80(sp)
    80000744:	6aa6                	ld	s5,72(sp)
    80000746:	6b06                	ld	s6,64(sp)
    80000748:	7be2                	ld	s7,56(sp)
    8000074a:	7c42                	ld	s8,48(sp)
    8000074c:	7ca2                	ld	s9,40(sp)
    8000074e:	7d02                	ld	s10,32(sp)
    80000750:	6de2                	ld	s11,24(sp)
    80000752:	6129                	addi	sp,sp,192
    80000754:	8082                	ret
    release(&pr.lock);
    80000756:	00010517          	auipc	a0,0x10
    8000075a:	46250513          	addi	a0,a0,1122 # 80010bb8 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	52c080e7          	jalr	1324(ra) # 80000c8a <release>
}
    80000766:	bfc9                	j	80000738 <printf+0x1b0>

0000000080000768 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000768:	1101                	addi	sp,sp,-32
    8000076a:	ec06                	sd	ra,24(sp)
    8000076c:	e822                	sd	s0,16(sp)
    8000076e:	e426                	sd	s1,8(sp)
    80000770:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000772:	00010497          	auipc	s1,0x10
    80000776:	44648493          	addi	s1,s1,1094 # 80010bb8 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	3c2080e7          	jalr	962(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078c:	4785                	li	a5,1
    8000078e:	cc9c                	sw	a5,24(s1)
}
    80000790:	60e2                	ld	ra,24(sp)
    80000792:	6442                	ld	s0,16(sp)
    80000794:	64a2                	ld	s1,8(sp)
    80000796:	6105                	addi	sp,sp,32
    80000798:	8082                	ret

000000008000079a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079a:	1141                	addi	sp,sp,-16
    8000079c:	e406                	sd	ra,8(sp)
    8000079e:	e022                	sd	s0,0(sp)
    800007a0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a2:	100007b7          	lui	a5,0x10000
    800007a6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007aa:	f8000713          	li	a4,-128
    800007ae:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b2:	470d                	li	a4,3
    800007b4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007bc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c0:	469d                	li	a3,7
    800007c2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ca:	00008597          	auipc	a1,0x8
    800007ce:	88e58593          	addi	a1,a1,-1906 # 80008058 <digits+0x18>
    800007d2:	00010517          	auipc	a0,0x10
    800007d6:	40650513          	addi	a0,a0,1030 # 80010bd8 <uart_tx_lock>
    800007da:	00000097          	auipc	ra,0x0
    800007de:	36c080e7          	jalr	876(ra) # 80000b46 <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ea:	1101                	addi	sp,sp,-32
    800007ec:	ec06                	sd	ra,24(sp)
    800007ee:	e822                	sd	s0,16(sp)
    800007f0:	e426                	sd	s1,8(sp)
    800007f2:	1000                	addi	s0,sp,32
    800007f4:	84aa                	mv	s1,a0
  push_off();
    800007f6:	00000097          	auipc	ra,0x0
    800007fa:	394080e7          	jalr	916(ra) # 80000b8a <push_off>

  if(panicked){
    800007fe:	00008797          	auipc	a5,0x8
    80000802:	1927a783          	lw	a5,402(a5) # 80008990 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080a:	c391                	beqz	a5,8000080e <uartputc_sync+0x24>
    for(;;)
    8000080c:	a001                	j	8000080c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000812:	0207f793          	andi	a5,a5,32
    80000816:	dfe5                	beqz	a5,8000080e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000818:	0ff4f513          	andi	a0,s1,255
    8000081c:	100007b7          	lui	a5,0x10000
    80000820:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000824:	00000097          	auipc	ra,0x0
    80000828:	406080e7          	jalr	1030(ra) # 80000c2a <pop_off>
}
    8000082c:	60e2                	ld	ra,24(sp)
    8000082e:	6442                	ld	s0,16(sp)
    80000830:	64a2                	ld	s1,8(sp)
    80000832:	6105                	addi	sp,sp,32
    80000834:	8082                	ret

0000000080000836 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000836:	00008797          	auipc	a5,0x8
    8000083a:	1627b783          	ld	a5,354(a5) # 80008998 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	16273703          	ld	a4,354(a4) # 800089a0 <uart_tx_w>
    80000846:	06f70a63          	beq	a4,a5,800008ba <uartstart+0x84>
{
    8000084a:	7139                	addi	sp,sp,-64
    8000084c:	fc06                	sd	ra,56(sp)
    8000084e:	f822                	sd	s0,48(sp)
    80000850:	f426                	sd	s1,40(sp)
    80000852:	f04a                	sd	s2,32(sp)
    80000854:	ec4e                	sd	s3,24(sp)
    80000856:	e852                	sd	s4,16(sp)
    80000858:	e456                	sd	s5,8(sp)
    8000085a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000860:	00010a17          	auipc	s4,0x10
    80000864:	378a0a13          	addi	s4,s4,888 # 80010bd8 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	13048493          	addi	s1,s1,304 # 80008998 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	13098993          	addi	s3,s3,304 # 800089a0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087c:	02077713          	andi	a4,a4,32
    80000880:	c705                	beqz	a4,800008a8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f7f713          	andi	a4,a5,31
    80000886:	9752                	add	a4,a4,s4
    80000888:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088c:	0785                	addi	a5,a5,1
    8000088e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	a06080e7          	jalr	-1530(ra) # 80002298 <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	609c                	ld	a5,0(s1)
    800008a0:	0009b703          	ld	a4,0(s3)
    800008a4:	fcf71ae3          	bne	a4,a5,80000878 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ce:	00010517          	auipc	a0,0x10
    800008d2:	30a50513          	addi	a0,a0,778 # 80010bd8 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	0b27a783          	lw	a5,178(a5) # 80008990 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	0b873703          	ld	a4,184(a4) # 800089a0 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	0a87b783          	ld	a5,168(a5) # 80008998 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	2dc98993          	addi	s3,s3,732 # 80010bd8 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	09448493          	addi	s1,s1,148 # 80008998 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	09490913          	addi	s2,s2,148 # 800089a0 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00002097          	auipc	ra,0x2
    80000920:	918080e7          	jalr	-1768(ra) # 80002234 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	2a648493          	addi	s1,s1,678 # 80010bd8 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	04e7bd23          	sd	a4,90(a5) # 800089a0 <uart_tx_w>
  uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee8080e7          	jalr	-280(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	332080e7          	jalr	818(ra) # 80000c8a <release>
}
    80000960:	70a2                	ld	ra,40(sp)
    80000962:	7402                	ld	s0,32(sp)
    80000964:	64e2                	ld	s1,24(sp)
    80000966:	6942                	ld	s2,16(sp)
    80000968:	69a2                	ld	s3,8(sp)
    8000096a:	6a02                	ld	s4,0(sp)
    8000096c:	6145                	addi	sp,sp,48
    8000096e:	8082                	ret
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0xb4>

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    800009a6:	a029                	j	800009b0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	916080e7          	jalr	-1770(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	fc2080e7          	jalr	-62(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009b8:	fe9518e3          	bne	a0,s1,800009a8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00010497          	auipc	s1,0x10
    800009c0:	21c48493          	addi	s1,s1,540 # 80010bd8 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e68080e7          	jalr	-408(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	0002e797          	auipc	a5,0x2e
    80000a02:	a4278793          	addi	a5,a5,-1470 # 8002e440 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	2bc080e7          	jalr	700(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00010917          	auipc	s2,0x10
    80000a22:	1f290913          	addi	s2,s2,498 # 80010c10 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ae6080e7          	jalr	-1306(ra) # 8000053e <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	15650513          	addi	a0,a0,342 # 80010c10 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	0002e517          	auipc	a0,0x2e
    80000ad2:	97250513          	addi	a0,a0,-1678 # 8002e440 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	12048493          	addi	s1,s1,288 # 80010c10 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	10850513          	addi	a0,a0,264 # 80010c10 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	0dc50513          	addi	a0,a0,220 # 80010c10 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	f6c080e7          	jalr	-148(ra) # 80001adc <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	f3a080e7          	jalr	-198(ra) # 80001adc <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	f2e080e7          	jalr	-210(ra) # 80001adc <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	f16080e7          	jalr	-234(ra) # 80001adc <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	ed6080e7          	jalr	-298(ra) # 80001adc <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91c080e7          	jalr	-1764(ra) # 8000053e <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	eaa080e7          	jalr	-342(ra) # 80001adc <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8cc080e7          	jalr	-1844(ra) # 8000053e <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8bc080e7          	jalr	-1860(ra) # 8000053e <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	874080e7          	jalr	-1932(ra) # 8000053e <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	fff6c793          	not	a5,a3
    80000e0c:	9fb9                	addw	a5,a5,a4
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	c4c080e7          	jalr	-948(ra) # 80001acc <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	b2070713          	addi	a4,a4,-1248 # 800089a8 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	c30080e7          	jalr	-976(ra) # 80001acc <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6da080e7          	jalr	1754(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	188080e7          	jalr	392(ra) # 8000103e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	a74080e7          	jalr	-1420(ra) # 80002932 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	6da080e7          	jalr	1754(ra) # 800065a0 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	1b4080e7          	jalr	436(ra) # 80002082 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88a080e7          	jalr	-1910(ra) # 80000768 <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	4aa50513          	addi	a0,a0,1194 # 80008390 <states.0+0xa0>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69a080e7          	jalr	1690(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68a080e7          	jalr	1674(ra) # 80000588 <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	48a50513          	addi	a0,a0,1162 # 80008390 <states.0+0xa0>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67a080e7          	jalr	1658(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	3d6080e7          	jalr	982(ra) # 800012f4 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	118080e7          	jalr	280(ra) # 8000103e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	aea080e7          	jalr	-1302(ra) # 80001a18 <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	9d4080e7          	jalr	-1580(ra) # 8000290a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	9f4080e7          	jalr	-1548(ra) # 80002932 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	644080e7          	jalr	1604(ra) # 8000658a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	652080e7          	jalr	1618(ra) # 800065a0 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	27e080e7          	jalr	638(ra) # 800031d4 <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	922080e7          	jalr	-1758(ra) # 80003880 <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	bd2080e7          	jalr	-1070(ra) # 80004b38 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	73a080e7          	jalr	1850(ra) # 800066a8 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	e62080e7          	jalr	-414(ra) # 80001dd8 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	a2f72223          	sw	a5,-1500(a4) # 800089a8 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <helperUnmap>:
pagetable_t kernel_pagetable;
extern char etext[];  // kernel.ld sets this to end of kernel code.

extern char trampoline[]; // trampoline.S
//ADDED
void helperUnmap(uint64 a , pte_t *pte, int do_free, pagetable_t pagetable){
    80000f8e:	7179                	addi	sp,sp,-48
    80000f90:	f406                	sd	ra,40(sp)
    80000f92:	f022                	sd	s0,32(sp)
    80000f94:	ec26                	sd	s1,24(sp)
    80000f96:	e84a                	sd	s2,16(sp)
    80000f98:	e44e                	sd	s3,8(sp)
    80000f9a:	e052                	sd	s4,0(sp)
    80000f9c:	1800                	addi	s0,sp,48
    80000f9e:	8a2a                	mv	s4,a0
    80000fa0:	89ae                	mv	s3,a1
    80000fa2:	84b2                	mv	s1,a2
    80000fa4:	8936                	mv	s2,a3
  struct proc *proc= myproc();
    80000fa6:	00001097          	auipc	ra,0x1
    80000faa:	b52080e7          	jalr	-1198(ra) # 80001af8 <myproc>
  struct metaData *page=proc->pagesInPysical;
  if(do_free&& proc->pid>2 &&pagetable==proc->pagetable &&(*pte & PTE_V)){
    80000fae:	c8a1                	beqz	s1,80000ffe <helperUnmap+0x70>
    80000fb0:	5918                	lw	a4,48(a0)
    80000fb2:	4789                	li	a5,2
    80000fb4:	00e7d563          	bge	a5,a4,80000fbe <helperUnmap+0x30>
    80000fb8:	693c                	ld	a5,80(a0)
    80000fba:	01278a63          	beq	a5,s2,80000fce <helperUnmap+0x40>
        break;
      }
      page++;
    }
  }
}
    80000fbe:	70a2                	ld	ra,40(sp)
    80000fc0:	7402                	ld	s0,32(sp)
    80000fc2:	64e2                	ld	s1,24(sp)
    80000fc4:	6942                	ld	s2,16(sp)
    80000fc6:	69a2                	ld	s3,8(sp)
    80000fc8:	6a02                	ld	s4,0(sp)
    80000fca:	6145                	addi	sp,sp,48
    80000fcc:	8082                	ret
  if(do_free&& proc->pid>2 &&pagetable==proc->pagetable &&(*pte & PTE_V)){
    80000fce:	0009b783          	ld	a5,0(s3) # 1000 <_entry-0x7ffff000>
    80000fd2:	8b85                	andi	a5,a5,1
    80000fd4:	cf85                	beqz	a5,8000100c <helperUnmap+0x7e>
  struct metaData *page=proc->pagesInPysical;
    80000fd6:	28050793          	addi	a5,a0,640
    while(page< & proc->pagesInPysical[MAX_PSYC_PAGES]){
    80000fda:	38050693          	addi	a3,a0,896
      if(page->va==a){
    80000fde:	6398                	ld	a4,0(a5)
    80000fe0:	01470663          	beq	a4,s4,80000fec <helperUnmap+0x5e>
      page++;
    80000fe4:	07c1                	addi	a5,a5,16
    while(page< & proc->pagesInPysical[MAX_PSYC_PAGES]){
    80000fe6:	fed79ce3          	bne	a5,a3,80000fde <helperUnmap+0x50>
    80000fea:	a00d                	j	8000100c <helperUnmap+0x7e>
        page->idxIsHere=0;
    80000fec:	0007b423          	sd	zero,8(a5)
        page->va=0;
    80000ff0:	0007b023          	sd	zero,0(a5)
        proc->physicalPagesCount--;
    80000ff4:	27053783          	ld	a5,624(a0)
    80000ff8:	17fd                	addi	a5,a5,-1
    80000ffa:	26f53823          	sd	a5,624(a0)
  if(proc->pid>2 &&pagetable==proc->pagetable &&(*pte & PTE_V)){
    80000ffe:	5918                	lw	a4,48(a0)
    80001000:	4789                	li	a5,2
    80001002:	fae7dee3          	bge	a5,a4,80000fbe <helperUnmap+0x30>
    80001006:	693c                	ld	a5,80(a0)
    80001008:	fb279be3          	bne	a5,s2,80000fbe <helperUnmap+0x30>
    8000100c:	0009b783          	ld	a5,0(s3)
    80001010:	8b85                	andi	a5,a5,1
    80001012:	d7d5                	beqz	a5,80000fbe <helperUnmap+0x30>
    page=proc->pagesInSwap;
    80001014:	38050793          	addi	a5,a0,896
    while(page< & proc->pagesInSwap[MAX_PSYC_PAGES]){
    80001018:	48050693          	addi	a3,a0,1152
      if(page->va==a){
    8000101c:	6398                	ld	a4,0(a5)
    8000101e:	01470663          	beq	a4,s4,8000102a <helperUnmap+0x9c>
      page++;
    80001022:	07c1                	addi	a5,a5,16
    while(page< & proc->pagesInSwap[MAX_PSYC_PAGES]){
    80001024:	fef69ce3          	bne	a3,a5,8000101c <helperUnmap+0x8e>
    80001028:	bf59                	j	80000fbe <helperUnmap+0x30>
        page->idxIsHere=0;
    8000102a:	0007b423          	sd	zero,8(a5)
        page->va=0;
    8000102e:	0007b023          	sd	zero,0(a5)
        proc->swapPagesCount--;
    80001032:	27853783          	ld	a5,632(a0)
    80001036:	17fd                	addi	a5,a5,-1
    80001038:	26f53c23          	sd	a5,632(a0)
        break;
    8000103c:	b749                	j	80000fbe <helperUnmap+0x30>

000000008000103e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000103e:	1141                	addi	sp,sp,-16
    80001040:	e422                	sd	s0,8(sp)
    80001042:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001044:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80001048:	00008797          	auipc	a5,0x8
    8000104c:	9687b783          	ld	a5,-1688(a5) # 800089b0 <kernel_pagetable>
    80001050:	83b1                	srli	a5,a5,0xc
    80001052:	577d                	li	a4,-1
    80001054:	177e                	slli	a4,a4,0x3f
    80001056:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001058:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    8000105c:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001060:	6422                	ld	s0,8(sp)
    80001062:	0141                	addi	sp,sp,16
    80001064:	8082                	ret

0000000080001066 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001066:	7139                	addi	sp,sp,-64
    80001068:	fc06                	sd	ra,56(sp)
    8000106a:	f822                	sd	s0,48(sp)
    8000106c:	f426                	sd	s1,40(sp)
    8000106e:	f04a                	sd	s2,32(sp)
    80001070:	ec4e                	sd	s3,24(sp)
    80001072:	e852                	sd	s4,16(sp)
    80001074:	e456                	sd	s5,8(sp)
    80001076:	e05a                	sd	s6,0(sp)
    80001078:	0080                	addi	s0,sp,64
    8000107a:	84aa                	mv	s1,a0
    8000107c:	89ae                	mv	s3,a1
    8000107e:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001080:	57fd                	li	a5,-1
    80001082:	83e9                	srli	a5,a5,0x1a
    80001084:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001086:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001088:	04b7f263          	bgeu	a5,a1,800010cc <walk+0x66>
    panic("walk");
    8000108c:	00007517          	auipc	a0,0x7
    80001090:	04450513          	addi	a0,a0,68 # 800080d0 <digits+0x90>
    80001094:	fffff097          	auipc	ra,0xfffff
    80001098:	4aa080e7          	jalr	1194(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000109c:	060a8663          	beqz	s5,80001108 <walk+0xa2>
    800010a0:	00000097          	auipc	ra,0x0
    800010a4:	a46080e7          	jalr	-1466(ra) # 80000ae6 <kalloc>
    800010a8:	84aa                	mv	s1,a0
    800010aa:	c529                	beqz	a0,800010f4 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800010ac:	6605                	lui	a2,0x1
    800010ae:	4581                	li	a1,0
    800010b0:	00000097          	auipc	ra,0x0
    800010b4:	c22080e7          	jalr	-990(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800010b8:	00c4d793          	srli	a5,s1,0xc
    800010bc:	07aa                	slli	a5,a5,0xa
    800010be:	0017e793          	ori	a5,a5,1
    800010c2:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010c6:	3a5d                	addiw	s4,s4,-9
    800010c8:	036a0063          	beq	s4,s6,800010e8 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010cc:	0149d933          	srl	s2,s3,s4
    800010d0:	1ff97913          	andi	s2,s2,511
    800010d4:	090e                	slli	s2,s2,0x3
    800010d6:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010d8:	00093483          	ld	s1,0(s2)
    800010dc:	0014f793          	andi	a5,s1,1
    800010e0:	dfd5                	beqz	a5,8000109c <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010e2:	80a9                	srli	s1,s1,0xa
    800010e4:	04b2                	slli	s1,s1,0xc
    800010e6:	b7c5                	j	800010c6 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010e8:	00c9d513          	srli	a0,s3,0xc
    800010ec:	1ff57513          	andi	a0,a0,511
    800010f0:	050e                	slli	a0,a0,0x3
    800010f2:	9526                	add	a0,a0,s1
}
    800010f4:	70e2                	ld	ra,56(sp)
    800010f6:	7442                	ld	s0,48(sp)
    800010f8:	74a2                	ld	s1,40(sp)
    800010fa:	7902                	ld	s2,32(sp)
    800010fc:	69e2                	ld	s3,24(sp)
    800010fe:	6a42                	ld	s4,16(sp)
    80001100:	6aa2                	ld	s5,8(sp)
    80001102:	6b02                	ld	s6,0(sp)
    80001104:	6121                	addi	sp,sp,64
    80001106:	8082                	ret
        return 0;
    80001108:	4501                	li	a0,0
    8000110a:	b7ed                	j	800010f4 <walk+0x8e>

000000008000110c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000110c:	57fd                	li	a5,-1
    8000110e:	83e9                	srli	a5,a5,0x1a
    80001110:	00b7f463          	bgeu	a5,a1,80001118 <walkaddr+0xc>
    return 0;
    80001114:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001116:	8082                	ret
{
    80001118:	1141                	addi	sp,sp,-16
    8000111a:	e406                	sd	ra,8(sp)
    8000111c:	e022                	sd	s0,0(sp)
    8000111e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001120:	4601                	li	a2,0
    80001122:	00000097          	auipc	ra,0x0
    80001126:	f44080e7          	jalr	-188(ra) # 80001066 <walk>
  if(pte == 0)
    8000112a:	c105                	beqz	a0,8000114a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000112c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000112e:	0117f693          	andi	a3,a5,17
    80001132:	4745                	li	a4,17
    return 0;
    80001134:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001136:	00e68663          	beq	a3,a4,80001142 <walkaddr+0x36>
}
    8000113a:	60a2                	ld	ra,8(sp)
    8000113c:	6402                	ld	s0,0(sp)
    8000113e:	0141                	addi	sp,sp,16
    80001140:	8082                	ret
  pa = PTE2PA(*pte);
    80001142:	00a7d513          	srli	a0,a5,0xa
    80001146:	0532                	slli	a0,a0,0xc
  return pa;
    80001148:	bfcd                	j	8000113a <walkaddr+0x2e>
    return 0;
    8000114a:	4501                	li	a0,0
    8000114c:	b7fd                	j	8000113a <walkaddr+0x2e>

000000008000114e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000114e:	715d                	addi	sp,sp,-80
    80001150:	e486                	sd	ra,72(sp)
    80001152:	e0a2                	sd	s0,64(sp)
    80001154:	fc26                	sd	s1,56(sp)
    80001156:	f84a                	sd	s2,48(sp)
    80001158:	f44e                	sd	s3,40(sp)
    8000115a:	f052                	sd	s4,32(sp)
    8000115c:	ec56                	sd	s5,24(sp)
    8000115e:	e85a                	sd	s6,16(sp)
    80001160:	e45e                	sd	s7,8(sp)
    80001162:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    80001164:	c639                	beqz	a2,800011b2 <mappages+0x64>
    80001166:	8aaa                	mv	s5,a0
    80001168:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    8000116a:	77fd                	lui	a5,0xfffff
    8000116c:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    80001170:	15fd                	addi	a1,a1,-1
    80001172:	00c589b3          	add	s3,a1,a2
    80001176:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    8000117a:	8952                	mv	s2,s4
    8000117c:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001180:	6b85                	lui	s7,0x1
    80001182:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001186:	4605                	li	a2,1
    80001188:	85ca                	mv	a1,s2
    8000118a:	8556                	mv	a0,s5
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	eda080e7          	jalr	-294(ra) # 80001066 <walk>
    80001194:	cd1d                	beqz	a0,800011d2 <mappages+0x84>
    if(*pte & PTE_V)
    80001196:	611c                	ld	a5,0(a0)
    80001198:	8b85                	andi	a5,a5,1
    8000119a:	e785                	bnez	a5,800011c2 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000119c:	80b1                	srli	s1,s1,0xc
    8000119e:	04aa                	slli	s1,s1,0xa
    800011a0:	0164e4b3          	or	s1,s1,s6
    800011a4:	0014e493          	ori	s1,s1,1
    800011a8:	e104                	sd	s1,0(a0)
    if(a == last)
    800011aa:	05390063          	beq	s2,s3,800011ea <mappages+0x9c>
    a += PGSIZE;
    800011ae:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011b0:	bfc9                	j	80001182 <mappages+0x34>
    panic("mappages: size");
    800011b2:	00007517          	auipc	a0,0x7
    800011b6:	f2650513          	addi	a0,a0,-218 # 800080d8 <digits+0x98>
    800011ba:	fffff097          	auipc	ra,0xfffff
    800011be:	384080e7          	jalr	900(ra) # 8000053e <panic>
      panic("mappages: remap");
    800011c2:	00007517          	auipc	a0,0x7
    800011c6:	f2650513          	addi	a0,a0,-218 # 800080e8 <digits+0xa8>
    800011ca:	fffff097          	auipc	ra,0xfffff
    800011ce:	374080e7          	jalr	884(ra) # 8000053e <panic>
      return -1;
    800011d2:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011d4:	60a6                	ld	ra,72(sp)
    800011d6:	6406                	ld	s0,64(sp)
    800011d8:	74e2                	ld	s1,56(sp)
    800011da:	7942                	ld	s2,48(sp)
    800011dc:	79a2                	ld	s3,40(sp)
    800011de:	7a02                	ld	s4,32(sp)
    800011e0:	6ae2                	ld	s5,24(sp)
    800011e2:	6b42                	ld	s6,16(sp)
    800011e4:	6ba2                	ld	s7,8(sp)
    800011e6:	6161                	addi	sp,sp,80
    800011e8:	8082                	ret
  return 0;
    800011ea:	4501                	li	a0,0
    800011ec:	b7e5                	j	800011d4 <mappages+0x86>

00000000800011ee <kvmmap>:
{
    800011ee:	1141                	addi	sp,sp,-16
    800011f0:	e406                	sd	ra,8(sp)
    800011f2:	e022                	sd	s0,0(sp)
    800011f4:	0800                	addi	s0,sp,16
    800011f6:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800011f8:	86b2                	mv	a3,a2
    800011fa:	863e                	mv	a2,a5
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	f52080e7          	jalr	-174(ra) # 8000114e <mappages>
    80001204:	e509                	bnez	a0,8000120e <kvmmap+0x20>
}
    80001206:	60a2                	ld	ra,8(sp)
    80001208:	6402                	ld	s0,0(sp)
    8000120a:	0141                	addi	sp,sp,16
    8000120c:	8082                	ret
    panic("kvmmap");
    8000120e:	00007517          	auipc	a0,0x7
    80001212:	eea50513          	addi	a0,a0,-278 # 800080f8 <digits+0xb8>
    80001216:	fffff097          	auipc	ra,0xfffff
    8000121a:	328080e7          	jalr	808(ra) # 8000053e <panic>

000000008000121e <kvmmake>:
{
    8000121e:	1101                	addi	sp,sp,-32
    80001220:	ec06                	sd	ra,24(sp)
    80001222:	e822                	sd	s0,16(sp)
    80001224:	e426                	sd	s1,8(sp)
    80001226:	e04a                	sd	s2,0(sp)
    80001228:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000122a:	00000097          	auipc	ra,0x0
    8000122e:	8bc080e7          	jalr	-1860(ra) # 80000ae6 <kalloc>
    80001232:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001234:	6605                	lui	a2,0x1
    80001236:	4581                	li	a1,0
    80001238:	00000097          	auipc	ra,0x0
    8000123c:	a9a080e7          	jalr	-1382(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001240:	4719                	li	a4,6
    80001242:	6685                	lui	a3,0x1
    80001244:	10000637          	lui	a2,0x10000
    80001248:	100005b7          	lui	a1,0x10000
    8000124c:	8526                	mv	a0,s1
    8000124e:	00000097          	auipc	ra,0x0
    80001252:	fa0080e7          	jalr	-96(ra) # 800011ee <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001256:	4719                	li	a4,6
    80001258:	6685                	lui	a3,0x1
    8000125a:	10001637          	lui	a2,0x10001
    8000125e:	100015b7          	lui	a1,0x10001
    80001262:	8526                	mv	a0,s1
    80001264:	00000097          	auipc	ra,0x0
    80001268:	f8a080e7          	jalr	-118(ra) # 800011ee <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000126c:	4719                	li	a4,6
    8000126e:	004006b7          	lui	a3,0x400
    80001272:	0c000637          	lui	a2,0xc000
    80001276:	0c0005b7          	lui	a1,0xc000
    8000127a:	8526                	mv	a0,s1
    8000127c:	00000097          	auipc	ra,0x0
    80001280:	f72080e7          	jalr	-142(ra) # 800011ee <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001284:	00007917          	auipc	s2,0x7
    80001288:	d7c90913          	addi	s2,s2,-644 # 80008000 <etext>
    8000128c:	4729                	li	a4,10
    8000128e:	80007697          	auipc	a3,0x80007
    80001292:	d7268693          	addi	a3,a3,-654 # 8000 <_entry-0x7fff8000>
    80001296:	4605                	li	a2,1
    80001298:	067e                	slli	a2,a2,0x1f
    8000129a:	85b2                	mv	a1,a2
    8000129c:	8526                	mv	a0,s1
    8000129e:	00000097          	auipc	ra,0x0
    800012a2:	f50080e7          	jalr	-176(ra) # 800011ee <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012a6:	4719                	li	a4,6
    800012a8:	46c5                	li	a3,17
    800012aa:	06ee                	slli	a3,a3,0x1b
    800012ac:	412686b3          	sub	a3,a3,s2
    800012b0:	864a                	mv	a2,s2
    800012b2:	85ca                	mv	a1,s2
    800012b4:	8526                	mv	a0,s1
    800012b6:	00000097          	auipc	ra,0x0
    800012ba:	f38080e7          	jalr	-200(ra) # 800011ee <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012be:	4729                	li	a4,10
    800012c0:	6685                	lui	a3,0x1
    800012c2:	00006617          	auipc	a2,0x6
    800012c6:	d3e60613          	addi	a2,a2,-706 # 80007000 <_trampoline>
    800012ca:	040005b7          	lui	a1,0x4000
    800012ce:	15fd                	addi	a1,a1,-1
    800012d0:	05b2                	slli	a1,a1,0xc
    800012d2:	8526                	mv	a0,s1
    800012d4:	00000097          	auipc	ra,0x0
    800012d8:	f1a080e7          	jalr	-230(ra) # 800011ee <kvmmap>
  proc_mapstacks(kpgtbl);
    800012dc:	8526                	mv	a0,s1
    800012de:	00000097          	auipc	ra,0x0
    800012e2:	6a4080e7          	jalr	1700(ra) # 80001982 <proc_mapstacks>
}
    800012e6:	8526                	mv	a0,s1
    800012e8:	60e2                	ld	ra,24(sp)
    800012ea:	6442                	ld	s0,16(sp)
    800012ec:	64a2                	ld	s1,8(sp)
    800012ee:	6902                	ld	s2,0(sp)
    800012f0:	6105                	addi	sp,sp,32
    800012f2:	8082                	ret

00000000800012f4 <kvminit>:
{
    800012f4:	1141                	addi	sp,sp,-16
    800012f6:	e406                	sd	ra,8(sp)
    800012f8:	e022                	sd	s0,0(sp)
    800012fa:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800012fc:	00000097          	auipc	ra,0x0
    80001300:	f22080e7          	jalr	-222(ra) # 8000121e <kvmmake>
    80001304:	00007797          	auipc	a5,0x7
    80001308:	6aa7b623          	sd	a0,1708(a5) # 800089b0 <kernel_pagetable>
}
    8000130c:	60a2                	ld	ra,8(sp)
    8000130e:	6402                	ld	s0,0(sp)
    80001310:	0141                	addi	sp,sp,16
    80001312:	8082                	ret

0000000080001314 <uvmunmap>:
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
//The uvmunmap() function is called by the user-space library when a process requests that a virtual memory region be unmapped. The function is also called by the kernel when a process terminates.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001314:	715d                	addi	sp,sp,-80
    80001316:	e486                	sd	ra,72(sp)
    80001318:	e0a2                	sd	s0,64(sp)
    8000131a:	fc26                	sd	s1,56(sp)
    8000131c:	f84a                	sd	s2,48(sp)
    8000131e:	f44e                	sd	s3,40(sp)
    80001320:	f052                	sd	s4,32(sp)
    80001322:	ec56                	sd	s5,24(sp)
    80001324:	e85a                	sd	s6,16(sp)
    80001326:	e45e                	sd	s7,8(sp)
    80001328:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000132a:	03459793          	slli	a5,a1,0x34
    8000132e:	e795                	bnez	a5,8000135a <uvmunmap+0x46>
    80001330:	89aa                	mv	s3,a0
    80001332:	892e                	mv	s2,a1
    80001334:	8a36                	mv	s4,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001336:	0632                	slli	a2,a2,0xc
    80001338:	00b60ab3          	add	s5,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000133c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000133e:	6b05                	lui	s6,0x1
    80001340:	0755ea63          	bltu	a1,s5,800013b4 <uvmunmap+0xa0>
      kfree((void*)pa);
    }
    helperUnmap( a , pte, do_free, pagetable);
    *pte = 0;
  }
}
    80001344:	60a6                	ld	ra,72(sp)
    80001346:	6406                	ld	s0,64(sp)
    80001348:	74e2                	ld	s1,56(sp)
    8000134a:	7942                	ld	s2,48(sp)
    8000134c:	79a2                	ld	s3,40(sp)
    8000134e:	7a02                	ld	s4,32(sp)
    80001350:	6ae2                	ld	s5,24(sp)
    80001352:	6b42                	ld	s6,16(sp)
    80001354:	6ba2                	ld	s7,8(sp)
    80001356:	6161                	addi	sp,sp,80
    80001358:	8082                	ret
    panic("uvmunmap: not aligned");
    8000135a:	00007517          	auipc	a0,0x7
    8000135e:	da650513          	addi	a0,a0,-602 # 80008100 <digits+0xc0>
    80001362:	fffff097          	auipc	ra,0xfffff
    80001366:	1dc080e7          	jalr	476(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    8000136a:	00007517          	auipc	a0,0x7
    8000136e:	dae50513          	addi	a0,a0,-594 # 80008118 <digits+0xd8>
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	1cc080e7          	jalr	460(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    8000137a:	00007517          	auipc	a0,0x7
    8000137e:	dae50513          	addi	a0,a0,-594 # 80008128 <digits+0xe8>
    80001382:	fffff097          	auipc	ra,0xfffff
    80001386:	1bc080e7          	jalr	444(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    8000138a:	00007517          	auipc	a0,0x7
    8000138e:	db650513          	addi	a0,a0,-586 # 80008140 <digits+0x100>
    80001392:	fffff097          	auipc	ra,0xfffff
    80001396:	1ac080e7          	jalr	428(ra) # 8000053e <panic>
    helperUnmap( a , pte, do_free, pagetable);
    8000139a:	86ce                	mv	a3,s3
    8000139c:	8652                	mv	a2,s4
    8000139e:	85a6                	mv	a1,s1
    800013a0:	854a                	mv	a0,s2
    800013a2:	00000097          	auipc	ra,0x0
    800013a6:	bec080e7          	jalr	-1044(ra) # 80000f8e <helperUnmap>
    *pte = 0;
    800013aa:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013ae:	995a                	add	s2,s2,s6
    800013b0:	f9597ae3          	bgeu	s2,s5,80001344 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013b4:	4601                	li	a2,0
    800013b6:	85ca                	mv	a1,s2
    800013b8:	854e                	mv	a0,s3
    800013ba:	00000097          	auipc	ra,0x0
    800013be:	cac080e7          	jalr	-852(ra) # 80001066 <walk>
    800013c2:	84aa                	mv	s1,a0
    800013c4:	d15d                	beqz	a0,8000136a <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013c6:	6108                	ld	a0,0(a0)
    800013c8:	00157793          	andi	a5,a0,1
    800013cc:	d7dd                	beqz	a5,8000137a <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013ce:	3ff57793          	andi	a5,a0,1023
    800013d2:	fb778ce3          	beq	a5,s7,8000138a <uvmunmap+0x76>
    if(do_free){
    800013d6:	fc0a02e3          	beqz	s4,8000139a <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800013da:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013dc:	0532                	slli	a0,a0,0xc
    800013de:	fffff097          	auipc	ra,0xfffff
    800013e2:	60c080e7          	jalr	1548(ra) # 800009ea <kfree>
    800013e6:	bf55                	j	8000139a <uvmunmap+0x86>

00000000800013e8 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013e8:	1101                	addi	sp,sp,-32
    800013ea:	ec06                	sd	ra,24(sp)
    800013ec:	e822                	sd	s0,16(sp)
    800013ee:	e426                	sd	s1,8(sp)
    800013f0:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013f2:	fffff097          	auipc	ra,0xfffff
    800013f6:	6f4080e7          	jalr	1780(ra) # 80000ae6 <kalloc>
    800013fa:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013fc:	c519                	beqz	a0,8000140a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013fe:	6605                	lui	a2,0x1
    80001400:	4581                	li	a1,0
    80001402:	00000097          	auipc	ra,0x0
    80001406:	8d0080e7          	jalr	-1840(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000140a:	8526                	mv	a0,s1
    8000140c:	60e2                	ld	ra,24(sp)
    8000140e:	6442                	ld	s0,16(sp)
    80001410:	64a2                	ld	s1,8(sp)
    80001412:	6105                	addi	sp,sp,32
    80001414:	8082                	ret

0000000080001416 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001416:	7179                	addi	sp,sp,-48
    80001418:	f406                	sd	ra,40(sp)
    8000141a:	f022                	sd	s0,32(sp)
    8000141c:	ec26                	sd	s1,24(sp)
    8000141e:	e84a                	sd	s2,16(sp)
    80001420:	e44e                	sd	s3,8(sp)
    80001422:	e052                	sd	s4,0(sp)
    80001424:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001426:	6785                	lui	a5,0x1
    80001428:	04f67863          	bgeu	a2,a5,80001478 <uvmfirst+0x62>
    8000142c:	8a2a                	mv	s4,a0
    8000142e:	89ae                	mv	s3,a1
    80001430:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001432:	fffff097          	auipc	ra,0xfffff
    80001436:	6b4080e7          	jalr	1716(ra) # 80000ae6 <kalloc>
    8000143a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000143c:	6605                	lui	a2,0x1
    8000143e:	4581                	li	a1,0
    80001440:	00000097          	auipc	ra,0x0
    80001444:	892080e7          	jalr	-1902(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001448:	4779                	li	a4,30
    8000144a:	86ca                	mv	a3,s2
    8000144c:	6605                	lui	a2,0x1
    8000144e:	4581                	li	a1,0
    80001450:	8552                	mv	a0,s4
    80001452:	00000097          	auipc	ra,0x0
    80001456:	cfc080e7          	jalr	-772(ra) # 8000114e <mappages>
  memmove(mem, src, sz);
    8000145a:	8626                	mv	a2,s1
    8000145c:	85ce                	mv	a1,s3
    8000145e:	854a                	mv	a0,s2
    80001460:	00000097          	auipc	ra,0x0
    80001464:	8ce080e7          	jalr	-1842(ra) # 80000d2e <memmove>
}
    80001468:	70a2                	ld	ra,40(sp)
    8000146a:	7402                	ld	s0,32(sp)
    8000146c:	64e2                	ld	s1,24(sp)
    8000146e:	6942                	ld	s2,16(sp)
    80001470:	69a2                	ld	s3,8(sp)
    80001472:	6a02                	ld	s4,0(sp)
    80001474:	6145                	addi	sp,sp,48
    80001476:	8082                	ret
    panic("uvmfirst: more than a page");
    80001478:	00007517          	auipc	a0,0x7
    8000147c:	ce050513          	addi	a0,a0,-800 # 80008158 <digits+0x118>
    80001480:	fffff097          	auipc	ra,0xfffff
    80001484:	0be080e7          	jalr	190(ra) # 8000053e <panic>

0000000080001488 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001488:	1101                	addi	sp,sp,-32
    8000148a:	ec06                	sd	ra,24(sp)
    8000148c:	e822                	sd	s0,16(sp)
    8000148e:	e426                	sd	s1,8(sp)
    80001490:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001492:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001494:	00b67d63          	bgeu	a2,a1,800014ae <uvmdealloc+0x26>
    80001498:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000149a:	6785                	lui	a5,0x1
    8000149c:	17fd                	addi	a5,a5,-1
    8000149e:	00f60733          	add	a4,a2,a5
    800014a2:	767d                	lui	a2,0xfffff
    800014a4:	8f71                	and	a4,a4,a2
    800014a6:	97ae                	add	a5,a5,a1
    800014a8:	8ff1                	and	a5,a5,a2
    800014aa:	00f76863          	bltu	a4,a5,800014ba <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014ae:	8526                	mv	a0,s1
    800014b0:	60e2                	ld	ra,24(sp)
    800014b2:	6442                	ld	s0,16(sp)
    800014b4:	64a2                	ld	s1,8(sp)
    800014b6:	6105                	addi	sp,sp,32
    800014b8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014ba:	8f99                	sub	a5,a5,a4
    800014bc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014be:	4685                	li	a3,1
    800014c0:	0007861b          	sext.w	a2,a5
    800014c4:	85ba                	mv	a1,a4
    800014c6:	00000097          	auipc	ra,0x0
    800014ca:	e4e080e7          	jalr	-434(ra) # 80001314 <uvmunmap>
    800014ce:	b7c5                	j	800014ae <uvmdealloc+0x26>

00000000800014d0 <uvmalloc>:
  if(newsz < oldsz)
    800014d0:	12b66b63          	bltu	a2,a1,80001606 <uvmalloc+0x136>
{
    800014d4:	7159                	addi	sp,sp,-112
    800014d6:	f486                	sd	ra,104(sp)
    800014d8:	f0a2                	sd	s0,96(sp)
    800014da:	eca6                	sd	s1,88(sp)
    800014dc:	e8ca                	sd	s2,80(sp)
    800014de:	e4ce                	sd	s3,72(sp)
    800014e0:	e0d2                	sd	s4,64(sp)
    800014e2:	fc56                	sd	s5,56(sp)
    800014e4:	f85a                	sd	s6,48(sp)
    800014e6:	f45e                	sd	s7,40(sp)
    800014e8:	f062                	sd	s8,32(sp)
    800014ea:	ec66                	sd	s9,24(sp)
    800014ec:	e86a                	sd	s10,16(sp)
    800014ee:	e46e                	sd	s11,8(sp)
    800014f0:	1880                	addi	s0,sp,112
    800014f2:	8a2a                	mv	s4,a0
    800014f4:	8b32                	mv	s6,a2
  oldsz = PGROUNDUP(oldsz);
    800014f6:	6a85                	lui	s5,0x1
    800014f8:	1afd                	addi	s5,s5,-1
    800014fa:	95d6                	add	a1,a1,s5
    800014fc:	7afd                	lui	s5,0xfffff
    800014fe:	0155fab3          	and	s5,a1,s5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001502:	10caf463          	bgeu	s5,a2,8000160a <uvmalloc+0x13a>
    80001506:	89d6                	mv	s3,s5
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001508:	0126eb93          	ori	s7,a3,18
    if(p->pid>2){
    8000150c:	4c09                	li	s8,2
      if(p->physicalPagesCount==MAX_PSYC_PAGES){
    8000150e:	4dc1                	li	s11,16
    page->idxIsHere=1;
    80001510:	4d05                	li	s10,1
    *entry = ~PTE_V | *entry;
    80001512:	5cf9                	li	s9,-2
    80001514:	a849                	j	800015a6 <uvmalloc+0xd6>
      uvmdealloc(pagetable, a, oldsz);
    80001516:	8656                	mv	a2,s5
    80001518:	85ce                	mv	a1,s3
    8000151a:	8552                	mv	a0,s4
    8000151c:	00000097          	auipc	ra,0x0
    80001520:	f6c080e7          	jalr	-148(ra) # 80001488 <uvmdealloc>
      return 0;
    80001524:	4501                	li	a0,0
}
    80001526:	70a6                	ld	ra,104(sp)
    80001528:	7406                	ld	s0,96(sp)
    8000152a:	64e6                	ld	s1,88(sp)
    8000152c:	6946                	ld	s2,80(sp)
    8000152e:	69a6                	ld	s3,72(sp)
    80001530:	6a06                	ld	s4,64(sp)
    80001532:	7ae2                	ld	s5,56(sp)
    80001534:	7b42                	ld	s6,48(sp)
    80001536:	7ba2                	ld	s7,40(sp)
    80001538:	7c02                	ld	s8,32(sp)
    8000153a:	6ce2                	ld	s9,24(sp)
    8000153c:	6d42                	ld	s10,16(sp)
    8000153e:	6da2                	ld	s11,8(sp)
    80001540:	6165                	addi	sp,sp,112
    80001542:	8082                	ret
      kfree(mem);
    80001544:	854a                	mv	a0,s2
    80001546:	fffff097          	auipc	ra,0xfffff
    8000154a:	4a4080e7          	jalr	1188(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000154e:	8656                	mv	a2,s5
    80001550:	85ce                	mv	a1,s3
    80001552:	8552                	mv	a0,s4
    80001554:	00000097          	auipc	ra,0x0
    80001558:	f34080e7          	jalr	-204(ra) # 80001488 <uvmdealloc>
      return 0;
    8000155c:	4501                	li	a0,0
    8000155e:	b7e1                	j	80001526 <uvmalloc+0x56>
        swapOutFromPysc(pagetable,p);
    80001560:	85aa                	mv	a1,a0
    80001562:	8552                	mv	a0,s4
    80001564:	00001097          	auipc	ra,0x1
    80001568:	248080e7          	jalr	584(ra) # 800027ac <swapOutFromPysc>
    8000156c:	a041                	j	800015ec <uvmalloc+0x11c>
        freeIdx=(int)(page-(p->pagesInPysical));
    8000156e:	40c784b3          	sub	s1,a5,a2
    80001572:	8491                	srai	s1,s1,0x4
    80001574:	2481                	sext.w	s1,s1
    page->idxIsHere=1;
    80001576:	0492                	slli	s1,s1,0x4
    80001578:	94ca                	add	s1,s1,s2
    8000157a:	29a4b423          	sd	s10,648(s1)
    page->va=a;
    8000157e:	2934b023          	sd	s3,640(s1)
    p->physicalPagesCount++;
    80001582:	27093783          	ld	a5,624(s2)
    80001586:	0785                	addi	a5,a5,1
    80001588:	26f93823          	sd	a5,624(s2)
    pte_t* entry = walk(pagetable, page->va, 0);
    8000158c:	4601                	li	a2,0
    8000158e:	85ce                	mv	a1,s3
    80001590:	8552                	mv	a0,s4
    80001592:	00000097          	auipc	ra,0x0
    80001596:	ad4080e7          	jalr	-1324(ra) # 80001066 <walk>
    *entry = ~PTE_V | *entry;
    8000159a:	01953023          	sd	s9,0(a0)
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000159e:	6785                	lui	a5,0x1
    800015a0:	99be                	add	s3,s3,a5
    800015a2:	0769f063          	bgeu	s3,s6,80001602 <uvmalloc+0x132>
    mem = kalloc();
    800015a6:	fffff097          	auipc	ra,0xfffff
    800015aa:	540080e7          	jalr	1344(ra) # 80000ae6 <kalloc>
    800015ae:	892a                	mv	s2,a0
    if(mem == 0){
    800015b0:	d13d                	beqz	a0,80001516 <uvmalloc+0x46>
    memset(mem, 0, PGSIZE);
    800015b2:	6605                	lui	a2,0x1
    800015b4:	4581                	li	a1,0
    800015b6:	fffff097          	auipc	ra,0xfffff
    800015ba:	71c080e7          	jalr	1820(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800015be:	875e                	mv	a4,s7
    800015c0:	86ca                	mv	a3,s2
    800015c2:	6605                	lui	a2,0x1
    800015c4:	85ce                	mv	a1,s3
    800015c6:	8552                	mv	a0,s4
    800015c8:	00000097          	auipc	ra,0x0
    800015cc:	b86080e7          	jalr	-1146(ra) # 8000114e <mappages>
    800015d0:	84aa                	mv	s1,a0
    800015d2:	f92d                	bnez	a0,80001544 <uvmalloc+0x74>
    struct proc *p=myproc();
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	524080e7          	jalr	1316(ra) # 80001af8 <myproc>
    800015dc:	892a                	mv	s2,a0
    if(p->pid>2){
    800015de:	591c                	lw	a5,48(a0)
    800015e0:	fafc5fe3          	bge	s8,a5,8000159e <uvmalloc+0xce>
      if(p->physicalPagesCount==MAX_PSYC_PAGES){
    800015e4:	27053783          	ld	a5,624(a0)
    800015e8:	f7b78ce3          	beq	a5,s11,80001560 <uvmalloc+0x90>
    for(page = p->pagesInPysical; page < &p->pagesInPysical[MAX_PSYC_PAGES]; page++ ){
    800015ec:	28090613          	addi	a2,s2,640
    800015f0:	38090693          	addi	a3,s2,896
    800015f4:	87b2                	mv	a5,a2
      if(page->idxIsHere==0){
    800015f6:	6798                	ld	a4,8(a5)
    800015f8:	db3d                	beqz	a4,8000156e <uvmalloc+0x9e>
    for(page = p->pagesInPysical; page < &p->pagesInPysical[MAX_PSYC_PAGES]; page++ ){
    800015fa:	07c1                	addi	a5,a5,16
    800015fc:	fef69de3          	bne	a3,a5,800015f6 <uvmalloc+0x126>
    80001600:	bf9d                	j	80001576 <uvmalloc+0xa6>
  return newsz;
    80001602:	855a                	mv	a0,s6
    80001604:	b70d                	j	80001526 <uvmalloc+0x56>
    return oldsz;
    80001606:	852e                	mv	a0,a1
}
    80001608:	8082                	ret
  return newsz;
    8000160a:	8532                	mv	a0,a2
    8000160c:	bf29                	j	80001526 <uvmalloc+0x56>

000000008000160e <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000160e:	7179                	addi	sp,sp,-48
    80001610:	f406                	sd	ra,40(sp)
    80001612:	f022                	sd	s0,32(sp)
    80001614:	ec26                	sd	s1,24(sp)
    80001616:	e84a                	sd	s2,16(sp)
    80001618:	e44e                	sd	s3,8(sp)
    8000161a:	e052                	sd	s4,0(sp)
    8000161c:	1800                	addi	s0,sp,48
    8000161e:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001620:	84aa                	mv	s1,a0
    80001622:	6905                	lui	s2,0x1
    80001624:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001626:	4985                	li	s3,1
    80001628:	a821                	j	80001640 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000162a:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000162c:	0532                	slli	a0,a0,0xc
    8000162e:	00000097          	auipc	ra,0x0
    80001632:	fe0080e7          	jalr	-32(ra) # 8000160e <freewalk>
      pagetable[i] = 0;
    80001636:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000163a:	04a1                	addi	s1,s1,8
    8000163c:	03248163          	beq	s1,s2,8000165e <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001640:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001642:	00f57793          	andi	a5,a0,15
    80001646:	ff3782e3          	beq	a5,s3,8000162a <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000164a:	8905                	andi	a0,a0,1
    8000164c:	d57d                	beqz	a0,8000163a <freewalk+0x2c>
      panic("freewalk: leaf");
    8000164e:	00007517          	auipc	a0,0x7
    80001652:	b2a50513          	addi	a0,a0,-1238 # 80008178 <digits+0x138>
    80001656:	fffff097          	auipc	ra,0xfffff
    8000165a:	ee8080e7          	jalr	-280(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000165e:	8552                	mv	a0,s4
    80001660:	fffff097          	auipc	ra,0xfffff
    80001664:	38a080e7          	jalr	906(ra) # 800009ea <kfree>
}
    80001668:	70a2                	ld	ra,40(sp)
    8000166a:	7402                	ld	s0,32(sp)
    8000166c:	64e2                	ld	s1,24(sp)
    8000166e:	6942                	ld	s2,16(sp)
    80001670:	69a2                	ld	s3,8(sp)
    80001672:	6a02                	ld	s4,0(sp)
    80001674:	6145                	addi	sp,sp,48
    80001676:	8082                	ret

0000000080001678 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001678:	1101                	addi	sp,sp,-32
    8000167a:	ec06                	sd	ra,24(sp)
    8000167c:	e822                	sd	s0,16(sp)
    8000167e:	e426                	sd	s1,8(sp)
    80001680:	1000                	addi	s0,sp,32
    80001682:	84aa                	mv	s1,a0
  if(sz > 0)
    80001684:	e999                	bnez	a1,8000169a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001686:	8526                	mv	a0,s1
    80001688:	00000097          	auipc	ra,0x0
    8000168c:	f86080e7          	jalr	-122(ra) # 8000160e <freewalk>
}
    80001690:	60e2                	ld	ra,24(sp)
    80001692:	6442                	ld	s0,16(sp)
    80001694:	64a2                	ld	s1,8(sp)
    80001696:	6105                	addi	sp,sp,32
    80001698:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000169a:	6605                	lui	a2,0x1
    8000169c:	167d                	addi	a2,a2,-1
    8000169e:	962e                	add	a2,a2,a1
    800016a0:	4685                	li	a3,1
    800016a2:	8231                	srli	a2,a2,0xc
    800016a4:	4581                	li	a1,0
    800016a6:	00000097          	auipc	ra,0x0
    800016aa:	c6e080e7          	jalr	-914(ra) # 80001314 <uvmunmap>
    800016ae:	bfe1                	j	80001686 <uvmfree+0xe>

00000000800016b0 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800016b0:	c679                	beqz	a2,8000177e <uvmcopy+0xce>
{
    800016b2:	715d                	addi	sp,sp,-80
    800016b4:	e486                	sd	ra,72(sp)
    800016b6:	e0a2                	sd	s0,64(sp)
    800016b8:	fc26                	sd	s1,56(sp)
    800016ba:	f84a                	sd	s2,48(sp)
    800016bc:	f44e                	sd	s3,40(sp)
    800016be:	f052                	sd	s4,32(sp)
    800016c0:	ec56                	sd	s5,24(sp)
    800016c2:	e85a                	sd	s6,16(sp)
    800016c4:	e45e                	sd	s7,8(sp)
    800016c6:	0880                	addi	s0,sp,80
    800016c8:	8b2a                	mv	s6,a0
    800016ca:	8aae                	mv	s5,a1
    800016cc:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800016ce:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800016d0:	4601                	li	a2,0
    800016d2:	85ce                	mv	a1,s3
    800016d4:	855a                	mv	a0,s6
    800016d6:	00000097          	auipc	ra,0x0
    800016da:	990080e7          	jalr	-1648(ra) # 80001066 <walk>
    800016de:	c531                	beqz	a0,8000172a <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800016e0:	6118                	ld	a4,0(a0)
    800016e2:	00177793          	andi	a5,a4,1
    800016e6:	cbb1                	beqz	a5,8000173a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800016e8:	00a75593          	srli	a1,a4,0xa
    800016ec:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800016f0:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800016f4:	fffff097          	auipc	ra,0xfffff
    800016f8:	3f2080e7          	jalr	1010(ra) # 80000ae6 <kalloc>
    800016fc:	892a                	mv	s2,a0
    800016fe:	c939                	beqz	a0,80001754 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001700:	6605                	lui	a2,0x1
    80001702:	85de                	mv	a1,s7
    80001704:	fffff097          	auipc	ra,0xfffff
    80001708:	62a080e7          	jalr	1578(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000170c:	8726                	mv	a4,s1
    8000170e:	86ca                	mv	a3,s2
    80001710:	6605                	lui	a2,0x1
    80001712:	85ce                	mv	a1,s3
    80001714:	8556                	mv	a0,s5
    80001716:	00000097          	auipc	ra,0x0
    8000171a:	a38080e7          	jalr	-1480(ra) # 8000114e <mappages>
    8000171e:	e515                	bnez	a0,8000174a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001720:	6785                	lui	a5,0x1
    80001722:	99be                	add	s3,s3,a5
    80001724:	fb49e6e3          	bltu	s3,s4,800016d0 <uvmcopy+0x20>
    80001728:	a081                	j	80001768 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000172a:	00007517          	auipc	a0,0x7
    8000172e:	a5e50513          	addi	a0,a0,-1442 # 80008188 <digits+0x148>
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	e0c080e7          	jalr	-500(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    8000173a:	00007517          	auipc	a0,0x7
    8000173e:	a6e50513          	addi	a0,a0,-1426 # 800081a8 <digits+0x168>
    80001742:	fffff097          	auipc	ra,0xfffff
    80001746:	dfc080e7          	jalr	-516(ra) # 8000053e <panic>
      kfree(mem);
    8000174a:	854a                	mv	a0,s2
    8000174c:	fffff097          	auipc	ra,0xfffff
    80001750:	29e080e7          	jalr	670(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001754:	4685                	li	a3,1
    80001756:	00c9d613          	srli	a2,s3,0xc
    8000175a:	4581                	li	a1,0
    8000175c:	8556                	mv	a0,s5
    8000175e:	00000097          	auipc	ra,0x0
    80001762:	bb6080e7          	jalr	-1098(ra) # 80001314 <uvmunmap>
  return -1;
    80001766:	557d                	li	a0,-1
}
    80001768:	60a6                	ld	ra,72(sp)
    8000176a:	6406                	ld	s0,64(sp)
    8000176c:	74e2                	ld	s1,56(sp)
    8000176e:	7942                	ld	s2,48(sp)
    80001770:	79a2                	ld	s3,40(sp)
    80001772:	7a02                	ld	s4,32(sp)
    80001774:	6ae2                	ld	s5,24(sp)
    80001776:	6b42                	ld	s6,16(sp)
    80001778:	6ba2                	ld	s7,8(sp)
    8000177a:	6161                	addi	sp,sp,80
    8000177c:	8082                	ret
  return 0;
    8000177e:	4501                	li	a0,0
}
    80001780:	8082                	ret

0000000080001782 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001782:	1141                	addi	sp,sp,-16
    80001784:	e406                	sd	ra,8(sp)
    80001786:	e022                	sd	s0,0(sp)
    80001788:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000178a:	4601                	li	a2,0
    8000178c:	00000097          	auipc	ra,0x0
    80001790:	8da080e7          	jalr	-1830(ra) # 80001066 <walk>
  if(pte == 0)
    80001794:	c901                	beqz	a0,800017a4 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001796:	611c                	ld	a5,0(a0)
    80001798:	9bbd                	andi	a5,a5,-17
    8000179a:	e11c                	sd	a5,0(a0)
}
    8000179c:	60a2                	ld	ra,8(sp)
    8000179e:	6402                	ld	s0,0(sp)
    800017a0:	0141                	addi	sp,sp,16
    800017a2:	8082                	ret
    panic("uvmclear");
    800017a4:	00007517          	auipc	a0,0x7
    800017a8:	a2450513          	addi	a0,a0,-1500 # 800081c8 <digits+0x188>
    800017ac:	fffff097          	auipc	ra,0xfffff
    800017b0:	d92080e7          	jalr	-622(ra) # 8000053e <panic>

00000000800017b4 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017b4:	c6bd                	beqz	a3,80001822 <copyout+0x6e>
{
    800017b6:	715d                	addi	sp,sp,-80
    800017b8:	e486                	sd	ra,72(sp)
    800017ba:	e0a2                	sd	s0,64(sp)
    800017bc:	fc26                	sd	s1,56(sp)
    800017be:	f84a                	sd	s2,48(sp)
    800017c0:	f44e                	sd	s3,40(sp)
    800017c2:	f052                	sd	s4,32(sp)
    800017c4:	ec56                	sd	s5,24(sp)
    800017c6:	e85a                	sd	s6,16(sp)
    800017c8:	e45e                	sd	s7,8(sp)
    800017ca:	e062                	sd	s8,0(sp)
    800017cc:	0880                	addi	s0,sp,80
    800017ce:	8b2a                	mv	s6,a0
    800017d0:	8c2e                	mv	s8,a1
    800017d2:	8a32                	mv	s4,a2
    800017d4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800017d6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800017d8:	6a85                	lui	s5,0x1
    800017da:	a015                	j	800017fe <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800017dc:	9562                	add	a0,a0,s8
    800017de:	0004861b          	sext.w	a2,s1
    800017e2:	85d2                	mv	a1,s4
    800017e4:	41250533          	sub	a0,a0,s2
    800017e8:	fffff097          	auipc	ra,0xfffff
    800017ec:	546080e7          	jalr	1350(ra) # 80000d2e <memmove>

    len -= n;
    800017f0:	409989b3          	sub	s3,s3,s1
    src += n;
    800017f4:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800017f6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017fa:	02098263          	beqz	s3,8000181e <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800017fe:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001802:	85ca                	mv	a1,s2
    80001804:	855a                	mv	a0,s6
    80001806:	00000097          	auipc	ra,0x0
    8000180a:	906080e7          	jalr	-1786(ra) # 8000110c <walkaddr>
    if(pa0 == 0)
    8000180e:	cd01                	beqz	a0,80001826 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001810:	418904b3          	sub	s1,s2,s8
    80001814:	94d6                	add	s1,s1,s5
    if(n > len)
    80001816:	fc99f3e3          	bgeu	s3,s1,800017dc <copyout+0x28>
    8000181a:	84ce                	mv	s1,s3
    8000181c:	b7c1                	j	800017dc <copyout+0x28>
  }
  return 0;
    8000181e:	4501                	li	a0,0
    80001820:	a021                	j	80001828 <copyout+0x74>
    80001822:	4501                	li	a0,0
}
    80001824:	8082                	ret
      return -1;
    80001826:	557d                	li	a0,-1
}
    80001828:	60a6                	ld	ra,72(sp)
    8000182a:	6406                	ld	s0,64(sp)
    8000182c:	74e2                	ld	s1,56(sp)
    8000182e:	7942                	ld	s2,48(sp)
    80001830:	79a2                	ld	s3,40(sp)
    80001832:	7a02                	ld	s4,32(sp)
    80001834:	6ae2                	ld	s5,24(sp)
    80001836:	6b42                	ld	s6,16(sp)
    80001838:	6ba2                	ld	s7,8(sp)
    8000183a:	6c02                	ld	s8,0(sp)
    8000183c:	6161                	addi	sp,sp,80
    8000183e:	8082                	ret

0000000080001840 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001840:	caa5                	beqz	a3,800018b0 <copyin+0x70>
{
    80001842:	715d                	addi	sp,sp,-80
    80001844:	e486                	sd	ra,72(sp)
    80001846:	e0a2                	sd	s0,64(sp)
    80001848:	fc26                	sd	s1,56(sp)
    8000184a:	f84a                	sd	s2,48(sp)
    8000184c:	f44e                	sd	s3,40(sp)
    8000184e:	f052                	sd	s4,32(sp)
    80001850:	ec56                	sd	s5,24(sp)
    80001852:	e85a                	sd	s6,16(sp)
    80001854:	e45e                	sd	s7,8(sp)
    80001856:	e062                	sd	s8,0(sp)
    80001858:	0880                	addi	s0,sp,80
    8000185a:	8b2a                	mv	s6,a0
    8000185c:	8a2e                	mv	s4,a1
    8000185e:	8c32                	mv	s8,a2
    80001860:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001862:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001864:	6a85                	lui	s5,0x1
    80001866:	a01d                	j	8000188c <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001868:	018505b3          	add	a1,a0,s8
    8000186c:	0004861b          	sext.w	a2,s1
    80001870:	412585b3          	sub	a1,a1,s2
    80001874:	8552                	mv	a0,s4
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	4b8080e7          	jalr	1208(ra) # 80000d2e <memmove>

    len -= n;
    8000187e:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001882:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001884:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001888:	02098263          	beqz	s3,800018ac <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000188c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001890:	85ca                	mv	a1,s2
    80001892:	855a                	mv	a0,s6
    80001894:	00000097          	auipc	ra,0x0
    80001898:	878080e7          	jalr	-1928(ra) # 8000110c <walkaddr>
    if(pa0 == 0)
    8000189c:	cd01                	beqz	a0,800018b4 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000189e:	418904b3          	sub	s1,s2,s8
    800018a2:	94d6                	add	s1,s1,s5
    if(n > len)
    800018a4:	fc99f2e3          	bgeu	s3,s1,80001868 <copyin+0x28>
    800018a8:	84ce                	mv	s1,s3
    800018aa:	bf7d                	j	80001868 <copyin+0x28>
  }
  return 0;
    800018ac:	4501                	li	a0,0
    800018ae:	a021                	j	800018b6 <copyin+0x76>
    800018b0:	4501                	li	a0,0
}
    800018b2:	8082                	ret
      return -1;
    800018b4:	557d                	li	a0,-1
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
    800018c8:	6c02                	ld	s8,0(sp)
    800018ca:	6161                	addi	sp,sp,80
    800018cc:	8082                	ret

00000000800018ce <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800018ce:	c6c5                	beqz	a3,80001976 <copyinstr+0xa8>
{
    800018d0:	715d                	addi	sp,sp,-80
    800018d2:	e486                	sd	ra,72(sp)
    800018d4:	e0a2                	sd	s0,64(sp)
    800018d6:	fc26                	sd	s1,56(sp)
    800018d8:	f84a                	sd	s2,48(sp)
    800018da:	f44e                	sd	s3,40(sp)
    800018dc:	f052                	sd	s4,32(sp)
    800018de:	ec56                	sd	s5,24(sp)
    800018e0:	e85a                	sd	s6,16(sp)
    800018e2:	e45e                	sd	s7,8(sp)
    800018e4:	0880                	addi	s0,sp,80
    800018e6:	8a2a                	mv	s4,a0
    800018e8:	8b2e                	mv	s6,a1
    800018ea:	8bb2                	mv	s7,a2
    800018ec:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800018ee:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018f0:	6985                	lui	s3,0x1
    800018f2:	a035                	j	8000191e <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800018f4:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800018f8:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800018fa:	0017b793          	seqz	a5,a5
    800018fe:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001902:	60a6                	ld	ra,72(sp)
    80001904:	6406                	ld	s0,64(sp)
    80001906:	74e2                	ld	s1,56(sp)
    80001908:	7942                	ld	s2,48(sp)
    8000190a:	79a2                	ld	s3,40(sp)
    8000190c:	7a02                	ld	s4,32(sp)
    8000190e:	6ae2                	ld	s5,24(sp)
    80001910:	6b42                	ld	s6,16(sp)
    80001912:	6ba2                	ld	s7,8(sp)
    80001914:	6161                	addi	sp,sp,80
    80001916:	8082                	ret
    srcva = va0 + PGSIZE;
    80001918:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000191c:	c8a9                	beqz	s1,8000196e <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000191e:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001922:	85ca                	mv	a1,s2
    80001924:	8552                	mv	a0,s4
    80001926:	fffff097          	auipc	ra,0xfffff
    8000192a:	7e6080e7          	jalr	2022(ra) # 8000110c <walkaddr>
    if(pa0 == 0)
    8000192e:	c131                	beqz	a0,80001972 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001930:	41790833          	sub	a6,s2,s7
    80001934:	984e                	add	a6,a6,s3
    if(n > max)
    80001936:	0104f363          	bgeu	s1,a6,8000193c <copyinstr+0x6e>
    8000193a:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000193c:	955e                	add	a0,a0,s7
    8000193e:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001942:	fc080be3          	beqz	a6,80001918 <copyinstr+0x4a>
    80001946:	985a                	add	a6,a6,s6
    80001948:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000194a:	41650633          	sub	a2,a0,s6
    8000194e:	14fd                	addi	s1,s1,-1
    80001950:	9b26                	add	s6,s6,s1
    80001952:	00f60733          	add	a4,a2,a5
    80001956:	00074703          	lbu	a4,0(a4)
    8000195a:	df49                	beqz	a4,800018f4 <copyinstr+0x26>
        *dst = *p;
    8000195c:	00e78023          	sb	a4,0(a5)
      --max;
    80001960:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001964:	0785                	addi	a5,a5,1
    while(n > 0){
    80001966:	ff0796e3          	bne	a5,a6,80001952 <copyinstr+0x84>
      dst++;
    8000196a:	8b42                	mv	s6,a6
    8000196c:	b775                	j	80001918 <copyinstr+0x4a>
    8000196e:	4781                	li	a5,0
    80001970:	b769                	j	800018fa <copyinstr+0x2c>
      return -1;
    80001972:	557d                	li	a0,-1
    80001974:	b779                	j	80001902 <copyinstr+0x34>
  int got_null = 0;
    80001976:	4781                	li	a5,0
  if(got_null){
    80001978:	0017b793          	seqz	a5,a5
    8000197c:	40f00533          	neg	a0,a5
}
    80001980:	8082                	ret

0000000080001982 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001982:	7139                	addi	sp,sp,-64
    80001984:	fc06                	sd	ra,56(sp)
    80001986:	f822                	sd	s0,48(sp)
    80001988:	f426                	sd	s1,40(sp)
    8000198a:	f04a                	sd	s2,32(sp)
    8000198c:	ec4e                	sd	s3,24(sp)
    8000198e:	e852                	sd	s4,16(sp)
    80001990:	e456                	sd	s5,8(sp)
    80001992:	e05a                	sd	s6,0(sp)
    80001994:	0080                	addi	s0,sp,64
    80001996:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001998:	0000f497          	auipc	s1,0xf
    8000199c:	6c848493          	addi	s1,s1,1736 # 80011060 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800019a0:	8b26                	mv	s6,s1
    800019a2:	00006a97          	auipc	s5,0x6
    800019a6:	65ea8a93          	addi	s5,s5,1630 # 80008000 <etext>
    800019aa:	04000937          	lui	s2,0x4000
    800019ae:	197d                	addi	s2,s2,-1
    800019b0:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019b2:	00021a17          	auipc	s4,0x21
    800019b6:	6aea0a13          	addi	s4,s4,1710 # 80023060 <tickslock>
    char *pa = kalloc();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	12c080e7          	jalr	300(ra) # 80000ae6 <kalloc>
    800019c2:	862a                	mv	a2,a0
    if(pa == 0)
    800019c4:	c131                	beqz	a0,80001a08 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800019c6:	416485b3          	sub	a1,s1,s6
    800019ca:	859d                	srai	a1,a1,0x7
    800019cc:	000ab783          	ld	a5,0(s5)
    800019d0:	02f585b3          	mul	a1,a1,a5
    800019d4:	2585                	addiw	a1,a1,1
    800019d6:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019da:	4719                	li	a4,6
    800019dc:	6685                	lui	a3,0x1
    800019de:	40b905b3          	sub	a1,s2,a1
    800019e2:	854e                	mv	a0,s3
    800019e4:	00000097          	auipc	ra,0x0
    800019e8:	80a080e7          	jalr	-2038(ra) # 800011ee <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ec:	48048493          	addi	s1,s1,1152
    800019f0:	fd4495e3          	bne	s1,s4,800019ba <proc_mapstacks+0x38>
  }
}
    800019f4:	70e2                	ld	ra,56(sp)
    800019f6:	7442                	ld	s0,48(sp)
    800019f8:	74a2                	ld	s1,40(sp)
    800019fa:	7902                	ld	s2,32(sp)
    800019fc:	69e2                	ld	s3,24(sp)
    800019fe:	6a42                	ld	s4,16(sp)
    80001a00:	6aa2                	ld	s5,8(sp)
    80001a02:	6b02                	ld	s6,0(sp)
    80001a04:	6121                	addi	sp,sp,64
    80001a06:	8082                	ret
      panic("kalloc");
    80001a08:	00006517          	auipc	a0,0x6
    80001a0c:	7d050513          	addi	a0,a0,2000 # 800081d8 <digits+0x198>
    80001a10:	fffff097          	auipc	ra,0xfffff
    80001a14:	b2e080e7          	jalr	-1234(ra) # 8000053e <panic>

0000000080001a18 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001a18:	7139                	addi	sp,sp,-64
    80001a1a:	fc06                	sd	ra,56(sp)
    80001a1c:	f822                	sd	s0,48(sp)
    80001a1e:	f426                	sd	s1,40(sp)
    80001a20:	f04a                	sd	s2,32(sp)
    80001a22:	ec4e                	sd	s3,24(sp)
    80001a24:	e852                	sd	s4,16(sp)
    80001a26:	e456                	sd	s5,8(sp)
    80001a28:	e05a                	sd	s6,0(sp)
    80001a2a:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001a2c:	00006597          	auipc	a1,0x6
    80001a30:	7b458593          	addi	a1,a1,1972 # 800081e0 <digits+0x1a0>
    80001a34:	0000f517          	auipc	a0,0xf
    80001a38:	1fc50513          	addi	a0,a0,508 # 80010c30 <pid_lock>
    80001a3c:	fffff097          	auipc	ra,0xfffff
    80001a40:	10a080e7          	jalr	266(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a44:	00006597          	auipc	a1,0x6
    80001a48:	7a458593          	addi	a1,a1,1956 # 800081e8 <digits+0x1a8>
    80001a4c:	0000f517          	auipc	a0,0xf
    80001a50:	1fc50513          	addi	a0,a0,508 # 80010c48 <wait_lock>
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	0f2080e7          	jalr	242(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a5c:	0000f497          	auipc	s1,0xf
    80001a60:	60448493          	addi	s1,s1,1540 # 80011060 <proc>
      initlock(&p->lock, "proc");
    80001a64:	00006b17          	auipc	s6,0x6
    80001a68:	794b0b13          	addi	s6,s6,1940 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001a6c:	8aa6                	mv	s5,s1
    80001a6e:	00006a17          	auipc	s4,0x6
    80001a72:	592a0a13          	addi	s4,s4,1426 # 80008000 <etext>
    80001a76:	04000937          	lui	s2,0x4000
    80001a7a:	197d                	addi	s2,s2,-1
    80001a7c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a7e:	00021997          	auipc	s3,0x21
    80001a82:	5e298993          	addi	s3,s3,1506 # 80023060 <tickslock>
      initlock(&p->lock, "proc");
    80001a86:	85da                	mv	a1,s6
    80001a88:	8526                	mv	a0,s1
    80001a8a:	fffff097          	auipc	ra,0xfffff
    80001a8e:	0bc080e7          	jalr	188(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    80001a92:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001a96:	415487b3          	sub	a5,s1,s5
    80001a9a:	879d                	srai	a5,a5,0x7
    80001a9c:	000a3703          	ld	a4,0(s4)
    80001aa0:	02e787b3          	mul	a5,a5,a4
    80001aa4:	2785                	addiw	a5,a5,1
    80001aa6:	00d7979b          	slliw	a5,a5,0xd
    80001aaa:	40f907b3          	sub	a5,s2,a5
    80001aae:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ab0:	48048493          	addi	s1,s1,1152
    80001ab4:	fd3499e3          	bne	s1,s3,80001a86 <procinit+0x6e>
  }
}
    80001ab8:	70e2                	ld	ra,56(sp)
    80001aba:	7442                	ld	s0,48(sp)
    80001abc:	74a2                	ld	s1,40(sp)
    80001abe:	7902                	ld	s2,32(sp)
    80001ac0:	69e2                	ld	s3,24(sp)
    80001ac2:	6a42                	ld	s4,16(sp)
    80001ac4:	6aa2                	ld	s5,8(sp)
    80001ac6:	6b02                	ld	s6,0(sp)
    80001ac8:	6121                	addi	sp,sp,64
    80001aca:	8082                	ret

0000000080001acc <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001acc:	1141                	addi	sp,sp,-16
    80001ace:	e422                	sd	s0,8(sp)
    80001ad0:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ad2:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001ad4:	2501                	sext.w	a0,a0
    80001ad6:	6422                	ld	s0,8(sp)
    80001ad8:	0141                	addi	sp,sp,16
    80001ada:	8082                	ret

0000000080001adc <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001adc:	1141                	addi	sp,sp,-16
    80001ade:	e422                	sd	s0,8(sp)
    80001ae0:	0800                	addi	s0,sp,16
    80001ae2:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001ae4:	2781                	sext.w	a5,a5
    80001ae6:	079e                	slli	a5,a5,0x7
  return c;
}
    80001ae8:	0000f517          	auipc	a0,0xf
    80001aec:	17850513          	addi	a0,a0,376 # 80010c60 <cpus>
    80001af0:	953e                	add	a0,a0,a5
    80001af2:	6422                	ld	s0,8(sp)
    80001af4:	0141                	addi	sp,sp,16
    80001af6:	8082                	ret

0000000080001af8 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001af8:	1101                	addi	sp,sp,-32
    80001afa:	ec06                	sd	ra,24(sp)
    80001afc:	e822                	sd	s0,16(sp)
    80001afe:	e426                	sd	s1,8(sp)
    80001b00:	1000                	addi	s0,sp,32
  push_off();
    80001b02:	fffff097          	auipc	ra,0xfffff
    80001b06:	088080e7          	jalr	136(ra) # 80000b8a <push_off>
    80001b0a:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b0c:	2781                	sext.w	a5,a5
    80001b0e:	079e                	slli	a5,a5,0x7
    80001b10:	0000f717          	auipc	a4,0xf
    80001b14:	12070713          	addi	a4,a4,288 # 80010c30 <pid_lock>
    80001b18:	97ba                	add	a5,a5,a4
    80001b1a:	7b84                	ld	s1,48(a5)
  pop_off();
    80001b1c:	fffff097          	auipc	ra,0xfffff
    80001b20:	10e080e7          	jalr	270(ra) # 80000c2a <pop_off>
  return p;
}
    80001b24:	8526                	mv	a0,s1
    80001b26:	60e2                	ld	ra,24(sp)
    80001b28:	6442                	ld	s0,16(sp)
    80001b2a:	64a2                	ld	s1,8(sp)
    80001b2c:	6105                	addi	sp,sp,32
    80001b2e:	8082                	ret

0000000080001b30 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001b30:	1141                	addi	sp,sp,-16
    80001b32:	e406                	sd	ra,8(sp)
    80001b34:	e022                	sd	s0,0(sp)
    80001b36:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001b38:	00000097          	auipc	ra,0x0
    80001b3c:	fc0080e7          	jalr	-64(ra) # 80001af8 <myproc>
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	14a080e7          	jalr	330(ra) # 80000c8a <release>

  if (first) {
    80001b48:	00007797          	auipc	a5,0x7
    80001b4c:	dd87a783          	lw	a5,-552(a5) # 80008920 <first.1>
    80001b50:	eb89                	bnez	a5,80001b62 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b52:	00001097          	auipc	ra,0x1
    80001b56:	df8080e7          	jalr	-520(ra) # 8000294a <usertrapret>
}
    80001b5a:	60a2                	ld	ra,8(sp)
    80001b5c:	6402                	ld	s0,0(sp)
    80001b5e:	0141                	addi	sp,sp,16
    80001b60:	8082                	ret
    first = 0;
    80001b62:	00007797          	auipc	a5,0x7
    80001b66:	da07af23          	sw	zero,-578(a5) # 80008920 <first.1>
    fsinit(ROOTDEV);
    80001b6a:	4505                	li	a0,1
    80001b6c:	00002097          	auipc	ra,0x2
    80001b70:	c94080e7          	jalr	-876(ra) # 80003800 <fsinit>
    80001b74:	bff9                	j	80001b52 <forkret+0x22>

0000000080001b76 <allocpid>:
{
    80001b76:	1101                	addi	sp,sp,-32
    80001b78:	ec06                	sd	ra,24(sp)
    80001b7a:	e822                	sd	s0,16(sp)
    80001b7c:	e426                	sd	s1,8(sp)
    80001b7e:	e04a                	sd	s2,0(sp)
    80001b80:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b82:	0000f917          	auipc	s2,0xf
    80001b86:	0ae90913          	addi	s2,s2,174 # 80010c30 <pid_lock>
    80001b8a:	854a                	mv	a0,s2
    80001b8c:	fffff097          	auipc	ra,0xfffff
    80001b90:	04a080e7          	jalr	74(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001b94:	00007797          	auipc	a5,0x7
    80001b98:	d9078793          	addi	a5,a5,-624 # 80008924 <nextpid>
    80001b9c:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b9e:	0014871b          	addiw	a4,s1,1
    80001ba2:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ba4:	854a                	mv	a0,s2
    80001ba6:	fffff097          	auipc	ra,0xfffff
    80001baa:	0e4080e7          	jalr	228(ra) # 80000c8a <release>
}
    80001bae:	8526                	mv	a0,s1
    80001bb0:	60e2                	ld	ra,24(sp)
    80001bb2:	6442                	ld	s0,16(sp)
    80001bb4:	64a2                	ld	s1,8(sp)
    80001bb6:	6902                	ld	s2,0(sp)
    80001bb8:	6105                	addi	sp,sp,32
    80001bba:	8082                	ret

0000000080001bbc <proc_pagetable>:
{
    80001bbc:	1101                	addi	sp,sp,-32
    80001bbe:	ec06                	sd	ra,24(sp)
    80001bc0:	e822                	sd	s0,16(sp)
    80001bc2:	e426                	sd	s1,8(sp)
    80001bc4:	e04a                	sd	s2,0(sp)
    80001bc6:	1000                	addi	s0,sp,32
    80001bc8:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001bca:	00000097          	auipc	ra,0x0
    80001bce:	81e080e7          	jalr	-2018(ra) # 800013e8 <uvmcreate>
    80001bd2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001bd4:	c121                	beqz	a0,80001c14 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bd6:	4729                	li	a4,10
    80001bd8:	00005697          	auipc	a3,0x5
    80001bdc:	42868693          	addi	a3,a3,1064 # 80007000 <_trampoline>
    80001be0:	6605                	lui	a2,0x1
    80001be2:	040005b7          	lui	a1,0x4000
    80001be6:	15fd                	addi	a1,a1,-1
    80001be8:	05b2                	slli	a1,a1,0xc
    80001bea:	fffff097          	auipc	ra,0xfffff
    80001bee:	564080e7          	jalr	1380(ra) # 8000114e <mappages>
    80001bf2:	02054863          	bltz	a0,80001c22 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bf6:	4719                	li	a4,6
    80001bf8:	05893683          	ld	a3,88(s2)
    80001bfc:	6605                	lui	a2,0x1
    80001bfe:	020005b7          	lui	a1,0x2000
    80001c02:	15fd                	addi	a1,a1,-1
    80001c04:	05b6                	slli	a1,a1,0xd
    80001c06:	8526                	mv	a0,s1
    80001c08:	fffff097          	auipc	ra,0xfffff
    80001c0c:	546080e7          	jalr	1350(ra) # 8000114e <mappages>
    80001c10:	02054163          	bltz	a0,80001c32 <proc_pagetable+0x76>
}
    80001c14:	8526                	mv	a0,s1
    80001c16:	60e2                	ld	ra,24(sp)
    80001c18:	6442                	ld	s0,16(sp)
    80001c1a:	64a2                	ld	s1,8(sp)
    80001c1c:	6902                	ld	s2,0(sp)
    80001c1e:	6105                	addi	sp,sp,32
    80001c20:	8082                	ret
    uvmfree(pagetable, 0);
    80001c22:	4581                	li	a1,0
    80001c24:	8526                	mv	a0,s1
    80001c26:	00000097          	auipc	ra,0x0
    80001c2a:	a52080e7          	jalr	-1454(ra) # 80001678 <uvmfree>
    return 0;
    80001c2e:	4481                	li	s1,0
    80001c30:	b7d5                	j	80001c14 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c32:	4681                	li	a3,0
    80001c34:	4605                	li	a2,1
    80001c36:	040005b7          	lui	a1,0x4000
    80001c3a:	15fd                	addi	a1,a1,-1
    80001c3c:	05b2                	slli	a1,a1,0xc
    80001c3e:	8526                	mv	a0,s1
    80001c40:	fffff097          	auipc	ra,0xfffff
    80001c44:	6d4080e7          	jalr	1748(ra) # 80001314 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c48:	4581                	li	a1,0
    80001c4a:	8526                	mv	a0,s1
    80001c4c:	00000097          	auipc	ra,0x0
    80001c50:	a2c080e7          	jalr	-1492(ra) # 80001678 <uvmfree>
    return 0;
    80001c54:	4481                	li	s1,0
    80001c56:	bf7d                	j	80001c14 <proc_pagetable+0x58>

0000000080001c58 <proc_freepagetable>:
{
    80001c58:	1101                	addi	sp,sp,-32
    80001c5a:	ec06                	sd	ra,24(sp)
    80001c5c:	e822                	sd	s0,16(sp)
    80001c5e:	e426                	sd	s1,8(sp)
    80001c60:	e04a                	sd	s2,0(sp)
    80001c62:	1000                	addi	s0,sp,32
    80001c64:	84aa                	mv	s1,a0
    80001c66:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c68:	4681                	li	a3,0
    80001c6a:	4605                	li	a2,1
    80001c6c:	040005b7          	lui	a1,0x4000
    80001c70:	15fd                	addi	a1,a1,-1
    80001c72:	05b2                	slli	a1,a1,0xc
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	6a0080e7          	jalr	1696(ra) # 80001314 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c7c:	4681                	li	a3,0
    80001c7e:	4605                	li	a2,1
    80001c80:	020005b7          	lui	a1,0x2000
    80001c84:	15fd                	addi	a1,a1,-1
    80001c86:	05b6                	slli	a1,a1,0xd
    80001c88:	8526                	mv	a0,s1
    80001c8a:	fffff097          	auipc	ra,0xfffff
    80001c8e:	68a080e7          	jalr	1674(ra) # 80001314 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c92:	85ca                	mv	a1,s2
    80001c94:	8526                	mv	a0,s1
    80001c96:	00000097          	auipc	ra,0x0
    80001c9a:	9e2080e7          	jalr	-1566(ra) # 80001678 <uvmfree>
}
    80001c9e:	60e2                	ld	ra,24(sp)
    80001ca0:	6442                	ld	s0,16(sp)
    80001ca2:	64a2                	ld	s1,8(sp)
    80001ca4:	6902                	ld	s2,0(sp)
    80001ca6:	6105                	addi	sp,sp,32
    80001ca8:	8082                	ret

0000000080001caa <freeproc>:
{
    80001caa:	1101                	addi	sp,sp,-32
    80001cac:	ec06                	sd	ra,24(sp)
    80001cae:	e822                	sd	s0,16(sp)
    80001cb0:	e426                	sd	s1,8(sp)
    80001cb2:	1000                	addi	s0,sp,32
    80001cb4:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001cb6:	6d28                	ld	a0,88(a0)
    80001cb8:	c509                	beqz	a0,80001cc2 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001cba:	fffff097          	auipc	ra,0xfffff
    80001cbe:	d30080e7          	jalr	-720(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001cc2:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001cc6:	68a8                	ld	a0,80(s1)
    80001cc8:	c511                	beqz	a0,80001cd4 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001cca:	64ac                	ld	a1,72(s1)
    80001ccc:	00000097          	auipc	ra,0x0
    80001cd0:	f8c080e7          	jalr	-116(ra) # 80001c58 <proc_freepagetable>
  p->pagetable = 0;
    80001cd4:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001cd8:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001cdc:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001ce0:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001ce4:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ce8:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001cec:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001cf0:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001cf4:	0004ac23          	sw	zero,24(s1)
  p->swapPagesCount=0;
    80001cf8:	2604bc23          	sd	zero,632(s1)
  p->physicalPagesCount=0;
    80001cfc:	2604b823          	sd	zero,624(s1)
}
    80001d00:	60e2                	ld	ra,24(sp)
    80001d02:	6442                	ld	s0,16(sp)
    80001d04:	64a2                	ld	s1,8(sp)
    80001d06:	6105                	addi	sp,sp,32
    80001d08:	8082                	ret

0000000080001d0a <allocproc>:
{
    80001d0a:	1101                	addi	sp,sp,-32
    80001d0c:	ec06                	sd	ra,24(sp)
    80001d0e:	e822                	sd	s0,16(sp)
    80001d10:	e426                	sd	s1,8(sp)
    80001d12:	e04a                	sd	s2,0(sp)
    80001d14:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d16:	0000f497          	auipc	s1,0xf
    80001d1a:	34a48493          	addi	s1,s1,842 # 80011060 <proc>
    80001d1e:	00021917          	auipc	s2,0x21
    80001d22:	34290913          	addi	s2,s2,834 # 80023060 <tickslock>
    acquire(&p->lock);
    80001d26:	8526                	mv	a0,s1
    80001d28:	fffff097          	auipc	ra,0xfffff
    80001d2c:	eae080e7          	jalr	-338(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001d30:	4c9c                	lw	a5,24(s1)
    80001d32:	cf81                	beqz	a5,80001d4a <allocproc+0x40>
      release(&p->lock);
    80001d34:	8526                	mv	a0,s1
    80001d36:	fffff097          	auipc	ra,0xfffff
    80001d3a:	f54080e7          	jalr	-172(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d3e:	48048493          	addi	s1,s1,1152
    80001d42:	ff2492e3          	bne	s1,s2,80001d26 <allocproc+0x1c>
  return 0;
    80001d46:	4481                	li	s1,0
    80001d48:	a889                	j	80001d9a <allocproc+0x90>
  p->pid = allocpid();
    80001d4a:	00000097          	auipc	ra,0x0
    80001d4e:	e2c080e7          	jalr	-468(ra) # 80001b76 <allocpid>
    80001d52:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d54:	4785                	li	a5,1
    80001d56:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d58:	fffff097          	auipc	ra,0xfffff
    80001d5c:	d8e080e7          	jalr	-626(ra) # 80000ae6 <kalloc>
    80001d60:	892a                	mv	s2,a0
    80001d62:	eca8                	sd	a0,88(s1)
    80001d64:	c131                	beqz	a0,80001da8 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001d66:	8526                	mv	a0,s1
    80001d68:	00000097          	auipc	ra,0x0
    80001d6c:	e54080e7          	jalr	-428(ra) # 80001bbc <proc_pagetable>
    80001d70:	892a                	mv	s2,a0
    80001d72:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d74:	c531                	beqz	a0,80001dc0 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001d76:	07000613          	li	a2,112
    80001d7a:	4581                	li	a1,0
    80001d7c:	06048513          	addi	a0,s1,96
    80001d80:	fffff097          	auipc	ra,0xfffff
    80001d84:	f52080e7          	jalr	-174(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001d88:	00000797          	auipc	a5,0x0
    80001d8c:	da878793          	addi	a5,a5,-600 # 80001b30 <forkret>
    80001d90:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d92:	60bc                	ld	a5,64(s1)
    80001d94:	6705                	lui	a4,0x1
    80001d96:	97ba                	add	a5,a5,a4
    80001d98:	f4bc                	sd	a5,104(s1)
}
    80001d9a:	8526                	mv	a0,s1
    80001d9c:	60e2                	ld	ra,24(sp)
    80001d9e:	6442                	ld	s0,16(sp)
    80001da0:	64a2                	ld	s1,8(sp)
    80001da2:	6902                	ld	s2,0(sp)
    80001da4:	6105                	addi	sp,sp,32
    80001da6:	8082                	ret
    freeproc(p);
    80001da8:	8526                	mv	a0,s1
    80001daa:	00000097          	auipc	ra,0x0
    80001dae:	f00080e7          	jalr	-256(ra) # 80001caa <freeproc>
    release(&p->lock);
    80001db2:	8526                	mv	a0,s1
    80001db4:	fffff097          	auipc	ra,0xfffff
    80001db8:	ed6080e7          	jalr	-298(ra) # 80000c8a <release>
    return 0;
    80001dbc:	84ca                	mv	s1,s2
    80001dbe:	bff1                	j	80001d9a <allocproc+0x90>
    freeproc(p);
    80001dc0:	8526                	mv	a0,s1
    80001dc2:	00000097          	auipc	ra,0x0
    80001dc6:	ee8080e7          	jalr	-280(ra) # 80001caa <freeproc>
    release(&p->lock);
    80001dca:	8526                	mv	a0,s1
    80001dcc:	fffff097          	auipc	ra,0xfffff
    80001dd0:	ebe080e7          	jalr	-322(ra) # 80000c8a <release>
    return 0;
    80001dd4:	84ca                	mv	s1,s2
    80001dd6:	b7d1                	j	80001d9a <allocproc+0x90>

0000000080001dd8 <userinit>:
{
    80001dd8:	1101                	addi	sp,sp,-32
    80001dda:	ec06                	sd	ra,24(sp)
    80001ddc:	e822                	sd	s0,16(sp)
    80001dde:	e426                	sd	s1,8(sp)
    80001de0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001de2:	00000097          	auipc	ra,0x0
    80001de6:	f28080e7          	jalr	-216(ra) # 80001d0a <allocproc>
    80001dea:	84aa                	mv	s1,a0
  initproc = p;
    80001dec:	00007797          	auipc	a5,0x7
    80001df0:	bca7b623          	sd	a0,-1076(a5) # 800089b8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001df4:	03400613          	li	a2,52
    80001df8:	00007597          	auipc	a1,0x7
    80001dfc:	b3858593          	addi	a1,a1,-1224 # 80008930 <initcode>
    80001e00:	6928                	ld	a0,80(a0)
    80001e02:	fffff097          	auipc	ra,0xfffff
    80001e06:	614080e7          	jalr	1556(ra) # 80001416 <uvmfirst>
  p->sz = PGSIZE;
    80001e0a:	6785                	lui	a5,0x1
    80001e0c:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001e0e:	6cb8                	ld	a4,88(s1)
    80001e10:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001e14:	6cb8                	ld	a4,88(s1)
    80001e16:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e18:	4641                	li	a2,16
    80001e1a:	00006597          	auipc	a1,0x6
    80001e1e:	3e658593          	addi	a1,a1,998 # 80008200 <digits+0x1c0>
    80001e22:	15848513          	addi	a0,s1,344
    80001e26:	fffff097          	auipc	ra,0xfffff
    80001e2a:	ff6080e7          	jalr	-10(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001e2e:	00006517          	auipc	a0,0x6
    80001e32:	3e250513          	addi	a0,a0,994 # 80008210 <digits+0x1d0>
    80001e36:	00002097          	auipc	ra,0x2
    80001e3a:	3ec080e7          	jalr	1004(ra) # 80004222 <namei>
    80001e3e:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e42:	478d                	li	a5,3
    80001e44:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e46:	8526                	mv	a0,s1
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	e42080e7          	jalr	-446(ra) # 80000c8a <release>
}
    80001e50:	60e2                	ld	ra,24(sp)
    80001e52:	6442                	ld	s0,16(sp)
    80001e54:	64a2                	ld	s1,8(sp)
    80001e56:	6105                	addi	sp,sp,32
    80001e58:	8082                	ret

0000000080001e5a <growproc>:
{
    80001e5a:	1101                	addi	sp,sp,-32
    80001e5c:	ec06                	sd	ra,24(sp)
    80001e5e:	e822                	sd	s0,16(sp)
    80001e60:	e426                	sd	s1,8(sp)
    80001e62:	e04a                	sd	s2,0(sp)
    80001e64:	1000                	addi	s0,sp,32
    80001e66:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001e68:	00000097          	auipc	ra,0x0
    80001e6c:	c90080e7          	jalr	-880(ra) # 80001af8 <myproc>
    80001e70:	84aa                	mv	s1,a0
  sz = p->sz;
    80001e72:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001e74:	01204c63          	bgtz	s2,80001e8c <growproc+0x32>
  } else if(n < 0){
    80001e78:	02094663          	bltz	s2,80001ea4 <growproc+0x4a>
  p->sz = sz;
    80001e7c:	e4ac                	sd	a1,72(s1)
  return 0;
    80001e7e:	4501                	li	a0,0
}
    80001e80:	60e2                	ld	ra,24(sp)
    80001e82:	6442                	ld	s0,16(sp)
    80001e84:	64a2                	ld	s1,8(sp)
    80001e86:	6902                	ld	s2,0(sp)
    80001e88:	6105                	addi	sp,sp,32
    80001e8a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001e8c:	4691                	li	a3,4
    80001e8e:	00b90633          	add	a2,s2,a1
    80001e92:	6928                	ld	a0,80(a0)
    80001e94:	fffff097          	auipc	ra,0xfffff
    80001e98:	63c080e7          	jalr	1596(ra) # 800014d0 <uvmalloc>
    80001e9c:	85aa                	mv	a1,a0
    80001e9e:	fd79                	bnez	a0,80001e7c <growproc+0x22>
      return -1;
    80001ea0:	557d                	li	a0,-1
    80001ea2:	bff9                	j	80001e80 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001ea4:	00b90633          	add	a2,s2,a1
    80001ea8:	6928                	ld	a0,80(a0)
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	5de080e7          	jalr	1502(ra) # 80001488 <uvmdealloc>
    80001eb2:	85aa                	mv	a1,a0
    80001eb4:	b7e1                	j	80001e7c <growproc+0x22>

0000000080001eb6 <fork>:
{
    80001eb6:	7139                	addi	sp,sp,-64
    80001eb8:	fc06                	sd	ra,56(sp)
    80001eba:	f822                	sd	s0,48(sp)
    80001ebc:	f426                	sd	s1,40(sp)
    80001ebe:	f04a                	sd	s2,32(sp)
    80001ec0:	ec4e                	sd	s3,24(sp)
    80001ec2:	e852                	sd	s4,16(sp)
    80001ec4:	e456                	sd	s5,8(sp)
    80001ec6:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001ec8:	00000097          	auipc	ra,0x0
    80001ecc:	c30080e7          	jalr	-976(ra) # 80001af8 <myproc>
    80001ed0:	8a2a                	mv	s4,a0
  if((np = allocproc()) == 0){
    80001ed2:	00000097          	auipc	ra,0x0
    80001ed6:	e38080e7          	jalr	-456(ra) # 80001d0a <allocproc>
    80001eda:	1a050263          	beqz	a0,8000207e <fork+0x1c8>
    80001ede:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001ee0:	048a3603          	ld	a2,72(s4)
    80001ee4:	692c                	ld	a1,80(a0)
    80001ee6:	050a3503          	ld	a0,80(s4)
    80001eea:	fffff097          	auipc	ra,0xfffff
    80001eee:	7c6080e7          	jalr	1990(ra) # 800016b0 <uvmcopy>
    80001ef2:	04054863          	bltz	a0,80001f42 <fork+0x8c>
  np->sz = p->sz;
    80001ef6:	048a3783          	ld	a5,72(s4)
    80001efa:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001efe:	058a3683          	ld	a3,88(s4)
    80001f02:	87b6                	mv	a5,a3
    80001f04:	0589b703          	ld	a4,88(s3)
    80001f08:	12068693          	addi	a3,a3,288
    80001f0c:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f10:	6788                	ld	a0,8(a5)
    80001f12:	6b8c                	ld	a1,16(a5)
    80001f14:	6f90                	ld	a2,24(a5)
    80001f16:	01073023          	sd	a6,0(a4)
    80001f1a:	e708                	sd	a0,8(a4)
    80001f1c:	eb0c                	sd	a1,16(a4)
    80001f1e:	ef10                	sd	a2,24(a4)
    80001f20:	02078793          	addi	a5,a5,32
    80001f24:	02070713          	addi	a4,a4,32
    80001f28:	fed792e3          	bne	a5,a3,80001f0c <fork+0x56>
  np->trapframe->a0 = 0;
    80001f2c:	0589b783          	ld	a5,88(s3)
    80001f30:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001f34:	0d0a0493          	addi	s1,s4,208
    80001f38:	0d098913          	addi	s2,s3,208
    80001f3c:	150a0a93          	addi	s5,s4,336
    80001f40:	a00d                	j	80001f62 <fork+0xac>
    freeproc(np);
    80001f42:	854e                	mv	a0,s3
    80001f44:	00000097          	auipc	ra,0x0
    80001f48:	d66080e7          	jalr	-666(ra) # 80001caa <freeproc>
    release(&np->lock);
    80001f4c:	854e                	mv	a0,s3
    80001f4e:	fffff097          	auipc	ra,0xfffff
    80001f52:	d3c080e7          	jalr	-708(ra) # 80000c8a <release>
    return -1;
    80001f56:	5afd                	li	s5,-1
    80001f58:	a841                	j	80001fe8 <fork+0x132>
  for(i = 0; i < NOFILE; i++)
    80001f5a:	04a1                	addi	s1,s1,8
    80001f5c:	0921                	addi	s2,s2,8
    80001f5e:	01548b63          	beq	s1,s5,80001f74 <fork+0xbe>
    if(p->ofile[i])
    80001f62:	6088                	ld	a0,0(s1)
    80001f64:	d97d                	beqz	a0,80001f5a <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f66:	00003097          	auipc	ra,0x3
    80001f6a:	c64080e7          	jalr	-924(ra) # 80004bca <filedup>
    80001f6e:	00a93023          	sd	a0,0(s2)
    80001f72:	b7e5                	j	80001f5a <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001f74:	150a3503          	ld	a0,336(s4)
    80001f78:	00002097          	auipc	ra,0x2
    80001f7c:	ac6080e7          	jalr	-1338(ra) # 80003a3e <idup>
    80001f80:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f84:	4641                	li	a2,16
    80001f86:	158a0593          	addi	a1,s4,344
    80001f8a:	15898513          	addi	a0,s3,344
    80001f8e:	fffff097          	auipc	ra,0xfffff
    80001f92:	e8e080e7          	jalr	-370(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001f96:	0309aa83          	lw	s5,48(s3)
  release(&np->lock);
    80001f9a:	854e                	mv	a0,s3
    80001f9c:	fffff097          	auipc	ra,0xfffff
    80001fa0:	cee080e7          	jalr	-786(ra) # 80000c8a <release>
   if(p->pid >2){//dont copy init &shell 
    80001fa4:	030a2703          	lw	a4,48(s4)
    80001fa8:	4789                	li	a5,2
    80001faa:	04e7c963          	blt	a5,a4,80001ffc <fork+0x146>
  acquire(&wait_lock);
    80001fae:	0000f497          	auipc	s1,0xf
    80001fb2:	c9a48493          	addi	s1,s1,-870 # 80010c48 <wait_lock>
    80001fb6:	8526                	mv	a0,s1
    80001fb8:	fffff097          	auipc	ra,0xfffff
    80001fbc:	c1e080e7          	jalr	-994(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001fc0:	0349bc23          	sd	s4,56(s3)
  release(&wait_lock);
    80001fc4:	8526                	mv	a0,s1
    80001fc6:	fffff097          	auipc	ra,0xfffff
    80001fca:	cc4080e7          	jalr	-828(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001fce:	854e                	mv	a0,s3
    80001fd0:	fffff097          	auipc	ra,0xfffff
    80001fd4:	c06080e7          	jalr	-1018(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001fd8:	478d                	li	a5,3
    80001fda:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001fde:	854e                	mv	a0,s3
    80001fe0:	fffff097          	auipc	ra,0xfffff
    80001fe4:	caa080e7          	jalr	-854(ra) # 80000c8a <release>
}
    80001fe8:	8556                	mv	a0,s5
    80001fea:	70e2                	ld	ra,56(sp)
    80001fec:	7442                	ld	s0,48(sp)
    80001fee:	74a2                	ld	s1,40(sp)
    80001ff0:	7902                	ld	s2,32(sp)
    80001ff2:	69e2                	ld	s3,24(sp)
    80001ff4:	6a42                	ld	s4,16(sp)
    80001ff6:	6aa2                	ld	s5,8(sp)
    80001ff8:	6121                	addi	sp,sp,64
    80001ffa:	8082                	ret
    createSwapFile(np);
    80001ffc:	854e                	mv	a0,s3
    80001ffe:	00002097          	auipc	ra,0x2
    80002002:	478080e7          	jalr	1144(ra) # 80004476 <createSwapFile>
    while(idx<MAX_PSYC_PAGES){
    80002006:	280a0793          	addi	a5,s4,640
    8000200a:	28098713          	addi	a4,s3,640
    8000200e:	380a0613          	addi	a2,s4,896
      np->pagesInPysical[idx].va=p->pagesInPysical[idx].va;
    80002012:	6394                	ld	a3,0(a5)
    80002014:	e314                	sd	a3,0(a4)
      np->pagesInPysical[idx].idxIsHere=p->pagesInPysical[idx].idxIsHere;
    80002016:	6794                	ld	a3,8(a5)
    80002018:	e714                	sd	a3,8(a4)
      np->pagesInSwap[idx].va=p->pagesInSwap[idx].va;
    8000201a:	1007b683          	ld	a3,256(a5)
    8000201e:	10d73023          	sd	a3,256(a4)
      np->pagesInSwap[idx].idxIsHere=p->pagesInSwap[idx].idxIsHere;
    80002022:	1087b683          	ld	a3,264(a5)
    80002026:	10d73423          	sd	a3,264(a4)
    while(idx<MAX_PSYC_PAGES){
    8000202a:	07c1                	addi	a5,a5,16
    8000202c:	0741                	addi	a4,a4,16
    8000202e:	fec792e3          	bne	a5,a2,80002012 <fork+0x15c>
    np->physicalPagesCount=p->physicalPagesCount;
    80002032:	270a3783          	ld	a5,624(s4)
    80002036:	26f9b823          	sd	a5,624(s3)
    np->swapPagesCount=p->swapPagesCount;
    8000203a:	278a3783          	ld	a5,632(s4)
    8000203e:	26f9bc23          	sd	a5,632(s3)
    char *space =kalloc();
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	aa4080e7          	jalr	-1372(ra) # 80000ae6 <kalloc>
    8000204a:	892a                	mv	s2,a0
    8000204c:	44c1                	li	s1,16
      readFromSwapFile(p,space,i*PGSIZE,PGSIZE);
    8000204e:	6685                	lui	a3,0x1
    80002050:	6641                	lui	a2,0x10
    80002052:	85ca                	mv	a1,s2
    80002054:	8552                	mv	a0,s4
    80002056:	00002097          	auipc	ra,0x2
    8000205a:	4f4080e7          	jalr	1268(ra) # 8000454a <readFromSwapFile>
      writeToSwapFile(np,space,i*PGSIZE,PGSIZE);
    8000205e:	6685                	lui	a3,0x1
    80002060:	6641                	lui	a2,0x10
    80002062:	85ca                	mv	a1,s2
    80002064:	854e                	mv	a0,s3
    80002066:	00002097          	auipc	ra,0x2
    8000206a:	4c0080e7          	jalr	1216(ra) # 80004526 <writeToSwapFile>
    while(idx<MAX_PSYC_PAGES){
    8000206e:	34fd                	addiw	s1,s1,-1
    80002070:	fcf9                	bnez	s1,8000204e <fork+0x198>
    kfree(space);
    80002072:	854a                	mv	a0,s2
    80002074:	fffff097          	auipc	ra,0xfffff
    80002078:	976080e7          	jalr	-1674(ra) # 800009ea <kfree>
    8000207c:	bf0d                	j	80001fae <fork+0xf8>
    return -1;
    8000207e:	5afd                	li	s5,-1
    80002080:	b7a5                	j	80001fe8 <fork+0x132>

0000000080002082 <scheduler>:
{
    80002082:	7139                	addi	sp,sp,-64
    80002084:	fc06                	sd	ra,56(sp)
    80002086:	f822                	sd	s0,48(sp)
    80002088:	f426                	sd	s1,40(sp)
    8000208a:	f04a                	sd	s2,32(sp)
    8000208c:	ec4e                	sd	s3,24(sp)
    8000208e:	e852                	sd	s4,16(sp)
    80002090:	e456                	sd	s5,8(sp)
    80002092:	e05a                	sd	s6,0(sp)
    80002094:	0080                	addi	s0,sp,64
    80002096:	8792                	mv	a5,tp
  int id = r_tp();
    80002098:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000209a:	00779a93          	slli	s5,a5,0x7
    8000209e:	0000f717          	auipc	a4,0xf
    800020a2:	b9270713          	addi	a4,a4,-1134 # 80010c30 <pid_lock>
    800020a6:	9756                	add	a4,a4,s5
    800020a8:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    800020ac:	0000f717          	auipc	a4,0xf
    800020b0:	bbc70713          	addi	a4,a4,-1092 # 80010c68 <cpus+0x8>
    800020b4:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    800020b6:	498d                	li	s3,3
        p->state = RUNNING;
    800020b8:	4b11                	li	s6,4
        c->proc = p;
    800020ba:	079e                	slli	a5,a5,0x7
    800020bc:	0000fa17          	auipc	s4,0xf
    800020c0:	b74a0a13          	addi	s4,s4,-1164 # 80010c30 <pid_lock>
    800020c4:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800020c6:	00021917          	auipc	s2,0x21
    800020ca:	f9a90913          	addi	s2,s2,-102 # 80023060 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020ce:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020d2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020d6:	10079073          	csrw	sstatus,a5
    800020da:	0000f497          	auipc	s1,0xf
    800020de:	f8648493          	addi	s1,s1,-122 # 80011060 <proc>
    800020e2:	a811                	j	800020f6 <scheduler+0x74>
      release(&p->lock);
    800020e4:	8526                	mv	a0,s1
    800020e6:	fffff097          	auipc	ra,0xfffff
    800020ea:	ba4080e7          	jalr	-1116(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800020ee:	48048493          	addi	s1,s1,1152
    800020f2:	fd248ee3          	beq	s1,s2,800020ce <scheduler+0x4c>
      acquire(&p->lock);
    800020f6:	8526                	mv	a0,s1
    800020f8:	fffff097          	auipc	ra,0xfffff
    800020fc:	ade080e7          	jalr	-1314(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    80002100:	4c9c                	lw	a5,24(s1)
    80002102:	ff3791e3          	bne	a5,s3,800020e4 <scheduler+0x62>
        p->state = RUNNING;
    80002106:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    8000210a:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    8000210e:	06048593          	addi	a1,s1,96
    80002112:	8556                	mv	a0,s5
    80002114:	00000097          	auipc	ra,0x0
    80002118:	78c080e7          	jalr	1932(ra) # 800028a0 <swtch>
        c->proc = 0;
    8000211c:	020a3823          	sd	zero,48(s4)
    80002120:	b7d1                	j	800020e4 <scheduler+0x62>

0000000080002122 <sched>:
{
    80002122:	7179                	addi	sp,sp,-48
    80002124:	f406                	sd	ra,40(sp)
    80002126:	f022                	sd	s0,32(sp)
    80002128:	ec26                	sd	s1,24(sp)
    8000212a:	e84a                	sd	s2,16(sp)
    8000212c:	e44e                	sd	s3,8(sp)
    8000212e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002130:	00000097          	auipc	ra,0x0
    80002134:	9c8080e7          	jalr	-1592(ra) # 80001af8 <myproc>
    80002138:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000213a:	fffff097          	auipc	ra,0xfffff
    8000213e:	a22080e7          	jalr	-1502(ra) # 80000b5c <holding>
    80002142:	c93d                	beqz	a0,800021b8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002144:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002146:	2781                	sext.w	a5,a5
    80002148:	079e                	slli	a5,a5,0x7
    8000214a:	0000f717          	auipc	a4,0xf
    8000214e:	ae670713          	addi	a4,a4,-1306 # 80010c30 <pid_lock>
    80002152:	97ba                	add	a5,a5,a4
    80002154:	0a87a703          	lw	a4,168(a5)
    80002158:	4785                	li	a5,1
    8000215a:	06f71763          	bne	a4,a5,800021c8 <sched+0xa6>
  if(p->state == RUNNING)
    8000215e:	4c98                	lw	a4,24(s1)
    80002160:	4791                	li	a5,4
    80002162:	06f70b63          	beq	a4,a5,800021d8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002166:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000216a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000216c:	efb5                	bnez	a5,800021e8 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000216e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002170:	0000f917          	auipc	s2,0xf
    80002174:	ac090913          	addi	s2,s2,-1344 # 80010c30 <pid_lock>
    80002178:	2781                	sext.w	a5,a5
    8000217a:	079e                	slli	a5,a5,0x7
    8000217c:	97ca                	add	a5,a5,s2
    8000217e:	0ac7a983          	lw	s3,172(a5)
    80002182:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002184:	2781                	sext.w	a5,a5
    80002186:	079e                	slli	a5,a5,0x7
    80002188:	0000f597          	auipc	a1,0xf
    8000218c:	ae058593          	addi	a1,a1,-1312 # 80010c68 <cpus+0x8>
    80002190:	95be                	add	a1,a1,a5
    80002192:	06048513          	addi	a0,s1,96
    80002196:	00000097          	auipc	ra,0x0
    8000219a:	70a080e7          	jalr	1802(ra) # 800028a0 <swtch>
    8000219e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021a0:	2781                	sext.w	a5,a5
    800021a2:	079e                	slli	a5,a5,0x7
    800021a4:	97ca                	add	a5,a5,s2
    800021a6:	0b37a623          	sw	s3,172(a5)
}
    800021aa:	70a2                	ld	ra,40(sp)
    800021ac:	7402                	ld	s0,32(sp)
    800021ae:	64e2                	ld	s1,24(sp)
    800021b0:	6942                	ld	s2,16(sp)
    800021b2:	69a2                	ld	s3,8(sp)
    800021b4:	6145                	addi	sp,sp,48
    800021b6:	8082                	ret
    panic("sched p->lock");
    800021b8:	00006517          	auipc	a0,0x6
    800021bc:	06050513          	addi	a0,a0,96 # 80008218 <digits+0x1d8>
    800021c0:	ffffe097          	auipc	ra,0xffffe
    800021c4:	37e080e7          	jalr	894(ra) # 8000053e <panic>
    panic("sched locks");
    800021c8:	00006517          	auipc	a0,0x6
    800021cc:	06050513          	addi	a0,a0,96 # 80008228 <digits+0x1e8>
    800021d0:	ffffe097          	auipc	ra,0xffffe
    800021d4:	36e080e7          	jalr	878(ra) # 8000053e <panic>
    panic("sched running");
    800021d8:	00006517          	auipc	a0,0x6
    800021dc:	06050513          	addi	a0,a0,96 # 80008238 <digits+0x1f8>
    800021e0:	ffffe097          	auipc	ra,0xffffe
    800021e4:	35e080e7          	jalr	862(ra) # 8000053e <panic>
    panic("sched interruptible");
    800021e8:	00006517          	auipc	a0,0x6
    800021ec:	06050513          	addi	a0,a0,96 # 80008248 <digits+0x208>
    800021f0:	ffffe097          	auipc	ra,0xffffe
    800021f4:	34e080e7          	jalr	846(ra) # 8000053e <panic>

00000000800021f8 <yield>:
{
    800021f8:	1101                	addi	sp,sp,-32
    800021fa:	ec06                	sd	ra,24(sp)
    800021fc:	e822                	sd	s0,16(sp)
    800021fe:	e426                	sd	s1,8(sp)
    80002200:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002202:	00000097          	auipc	ra,0x0
    80002206:	8f6080e7          	jalr	-1802(ra) # 80001af8 <myproc>
    8000220a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000220c:	fffff097          	auipc	ra,0xfffff
    80002210:	9ca080e7          	jalr	-1590(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002214:	478d                	li	a5,3
    80002216:	cc9c                	sw	a5,24(s1)
  sched();
    80002218:	00000097          	auipc	ra,0x0
    8000221c:	f0a080e7          	jalr	-246(ra) # 80002122 <sched>
  release(&p->lock);
    80002220:	8526                	mv	a0,s1
    80002222:	fffff097          	auipc	ra,0xfffff
    80002226:	a68080e7          	jalr	-1432(ra) # 80000c8a <release>
}
    8000222a:	60e2                	ld	ra,24(sp)
    8000222c:	6442                	ld	s0,16(sp)
    8000222e:	64a2                	ld	s1,8(sp)
    80002230:	6105                	addi	sp,sp,32
    80002232:	8082                	ret

0000000080002234 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002234:	7179                	addi	sp,sp,-48
    80002236:	f406                	sd	ra,40(sp)
    80002238:	f022                	sd	s0,32(sp)
    8000223a:	ec26                	sd	s1,24(sp)
    8000223c:	e84a                	sd	s2,16(sp)
    8000223e:	e44e                	sd	s3,8(sp)
    80002240:	1800                	addi	s0,sp,48
    80002242:	89aa                	mv	s3,a0
    80002244:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002246:	00000097          	auipc	ra,0x0
    8000224a:	8b2080e7          	jalr	-1870(ra) # 80001af8 <myproc>
    8000224e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002250:	fffff097          	auipc	ra,0xfffff
    80002254:	986080e7          	jalr	-1658(ra) # 80000bd6 <acquire>
  release(lk);
    80002258:	854a                	mv	a0,s2
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	a30080e7          	jalr	-1488(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002262:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002266:	4789                	li	a5,2
    80002268:	cc9c                	sw	a5,24(s1)

  sched();
    8000226a:	00000097          	auipc	ra,0x0
    8000226e:	eb8080e7          	jalr	-328(ra) # 80002122 <sched>

  // Tidy up.
  p->chan = 0;
    80002272:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002276:	8526                	mv	a0,s1
    80002278:	fffff097          	auipc	ra,0xfffff
    8000227c:	a12080e7          	jalr	-1518(ra) # 80000c8a <release>
  acquire(lk);
    80002280:	854a                	mv	a0,s2
    80002282:	fffff097          	auipc	ra,0xfffff
    80002286:	954080e7          	jalr	-1708(ra) # 80000bd6 <acquire>
}
    8000228a:	70a2                	ld	ra,40(sp)
    8000228c:	7402                	ld	s0,32(sp)
    8000228e:	64e2                	ld	s1,24(sp)
    80002290:	6942                	ld	s2,16(sp)
    80002292:	69a2                	ld	s3,8(sp)
    80002294:	6145                	addi	sp,sp,48
    80002296:	8082                	ret

0000000080002298 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002298:	7139                	addi	sp,sp,-64
    8000229a:	fc06                	sd	ra,56(sp)
    8000229c:	f822                	sd	s0,48(sp)
    8000229e:	f426                	sd	s1,40(sp)
    800022a0:	f04a                	sd	s2,32(sp)
    800022a2:	ec4e                	sd	s3,24(sp)
    800022a4:	e852                	sd	s4,16(sp)
    800022a6:	e456                	sd	s5,8(sp)
    800022a8:	0080                	addi	s0,sp,64
    800022aa:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800022ac:	0000f497          	auipc	s1,0xf
    800022b0:	db448493          	addi	s1,s1,-588 # 80011060 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800022b4:	4989                	li	s3,2
        p->state = RUNNABLE;
    800022b6:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800022b8:	00021917          	auipc	s2,0x21
    800022bc:	da890913          	addi	s2,s2,-600 # 80023060 <tickslock>
    800022c0:	a811                	j	800022d4 <wakeup+0x3c>
      }
      release(&p->lock);
    800022c2:	8526                	mv	a0,s1
    800022c4:	fffff097          	auipc	ra,0xfffff
    800022c8:	9c6080e7          	jalr	-1594(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800022cc:	48048493          	addi	s1,s1,1152
    800022d0:	03248663          	beq	s1,s2,800022fc <wakeup+0x64>
    if(p != myproc()){
    800022d4:	00000097          	auipc	ra,0x0
    800022d8:	824080e7          	jalr	-2012(ra) # 80001af8 <myproc>
    800022dc:	fea488e3          	beq	s1,a0,800022cc <wakeup+0x34>
      acquire(&p->lock);
    800022e0:	8526                	mv	a0,s1
    800022e2:	fffff097          	auipc	ra,0xfffff
    800022e6:	8f4080e7          	jalr	-1804(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800022ea:	4c9c                	lw	a5,24(s1)
    800022ec:	fd379be3          	bne	a5,s3,800022c2 <wakeup+0x2a>
    800022f0:	709c                	ld	a5,32(s1)
    800022f2:	fd4798e3          	bne	a5,s4,800022c2 <wakeup+0x2a>
        p->state = RUNNABLE;
    800022f6:	0154ac23          	sw	s5,24(s1)
    800022fa:	b7e1                	j	800022c2 <wakeup+0x2a>
    }
  }
}
    800022fc:	70e2                	ld	ra,56(sp)
    800022fe:	7442                	ld	s0,48(sp)
    80002300:	74a2                	ld	s1,40(sp)
    80002302:	7902                	ld	s2,32(sp)
    80002304:	69e2                	ld	s3,24(sp)
    80002306:	6a42                	ld	s4,16(sp)
    80002308:	6aa2                	ld	s5,8(sp)
    8000230a:	6121                	addi	sp,sp,64
    8000230c:	8082                	ret

000000008000230e <reparent>:
{
    8000230e:	7179                	addi	sp,sp,-48
    80002310:	f406                	sd	ra,40(sp)
    80002312:	f022                	sd	s0,32(sp)
    80002314:	ec26                	sd	s1,24(sp)
    80002316:	e84a                	sd	s2,16(sp)
    80002318:	e44e                	sd	s3,8(sp)
    8000231a:	e052                	sd	s4,0(sp)
    8000231c:	1800                	addi	s0,sp,48
    8000231e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002320:	0000f497          	auipc	s1,0xf
    80002324:	d4048493          	addi	s1,s1,-704 # 80011060 <proc>
      pp->parent = initproc;
    80002328:	00006a17          	auipc	s4,0x6
    8000232c:	690a0a13          	addi	s4,s4,1680 # 800089b8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002330:	00021997          	auipc	s3,0x21
    80002334:	d3098993          	addi	s3,s3,-720 # 80023060 <tickslock>
    80002338:	a029                	j	80002342 <reparent+0x34>
    8000233a:	48048493          	addi	s1,s1,1152
    8000233e:	01348d63          	beq	s1,s3,80002358 <reparent+0x4a>
    if(pp->parent == p){
    80002342:	7c9c                	ld	a5,56(s1)
    80002344:	ff279be3          	bne	a5,s2,8000233a <reparent+0x2c>
      pp->parent = initproc;
    80002348:	000a3503          	ld	a0,0(s4)
    8000234c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000234e:	00000097          	auipc	ra,0x0
    80002352:	f4a080e7          	jalr	-182(ra) # 80002298 <wakeup>
    80002356:	b7d5                	j	8000233a <reparent+0x2c>
}
    80002358:	70a2                	ld	ra,40(sp)
    8000235a:	7402                	ld	s0,32(sp)
    8000235c:	64e2                	ld	s1,24(sp)
    8000235e:	6942                	ld	s2,16(sp)
    80002360:	69a2                	ld	s3,8(sp)
    80002362:	6a02                	ld	s4,0(sp)
    80002364:	6145                	addi	sp,sp,48
    80002366:	8082                	ret

0000000080002368 <exit>:
{
    80002368:	7179                	addi	sp,sp,-48
    8000236a:	f406                	sd	ra,40(sp)
    8000236c:	f022                	sd	s0,32(sp)
    8000236e:	ec26                	sd	s1,24(sp)
    80002370:	e84a                	sd	s2,16(sp)
    80002372:	e44e                	sd	s3,8(sp)
    80002374:	e052                	sd	s4,0(sp)
    80002376:	1800                	addi	s0,sp,48
    80002378:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	77e080e7          	jalr	1918(ra) # 80001af8 <myproc>
    80002382:	89aa                	mv	s3,a0
  if(p == initproc)
    80002384:	00006797          	auipc	a5,0x6
    80002388:	6347b783          	ld	a5,1588(a5) # 800089b8 <initproc>
    8000238c:	0d050493          	addi	s1,a0,208
    80002390:	15050913          	addi	s2,a0,336
    80002394:	02a79363          	bne	a5,a0,800023ba <exit+0x52>
    panic("init exiting");
    80002398:	00006517          	auipc	a0,0x6
    8000239c:	ec850513          	addi	a0,a0,-312 # 80008260 <digits+0x220>
    800023a0:	ffffe097          	auipc	ra,0xffffe
    800023a4:	19e080e7          	jalr	414(ra) # 8000053e <panic>
      fileclose(f);
    800023a8:	00003097          	auipc	ra,0x3
    800023ac:	874080e7          	jalr	-1932(ra) # 80004c1c <fileclose>
      p->ofile[fd] = 0;
    800023b0:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800023b4:	04a1                	addi	s1,s1,8
    800023b6:	01248563          	beq	s1,s2,800023c0 <exit+0x58>
    if(p->ofile[fd]){
    800023ba:	6088                	ld	a0,0(s1)
    800023bc:	f575                	bnez	a0,800023a8 <exit+0x40>
    800023be:	bfdd                	j	800023b4 <exit+0x4c>
  if(p->pid>2){
    800023c0:	0309a703          	lw	a4,48(s3)
    800023c4:	4789                	li	a5,2
    800023c6:	08e7c163          	blt	a5,a4,80002448 <exit+0xe0>
  begin_op();
    800023ca:	00002097          	auipc	ra,0x2
    800023ce:	386080e7          	jalr	902(ra) # 80004750 <begin_op>
  iput(p->cwd);
    800023d2:	1509b503          	ld	a0,336(s3)
    800023d6:	00002097          	auipc	ra,0x2
    800023da:	860080e7          	jalr	-1952(ra) # 80003c36 <iput>
  end_op();
    800023de:	00002097          	auipc	ra,0x2
    800023e2:	3f2080e7          	jalr	1010(ra) # 800047d0 <end_op>
  p->cwd = 0;
    800023e6:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800023ea:	0000f497          	auipc	s1,0xf
    800023ee:	85e48493          	addi	s1,s1,-1954 # 80010c48 <wait_lock>
    800023f2:	8526                	mv	a0,s1
    800023f4:	ffffe097          	auipc	ra,0xffffe
    800023f8:	7e2080e7          	jalr	2018(ra) # 80000bd6 <acquire>
  reparent(p);
    800023fc:	854e                	mv	a0,s3
    800023fe:	00000097          	auipc	ra,0x0
    80002402:	f10080e7          	jalr	-240(ra) # 8000230e <reparent>
  wakeup(p->parent);
    80002406:	0389b503          	ld	a0,56(s3)
    8000240a:	00000097          	auipc	ra,0x0
    8000240e:	e8e080e7          	jalr	-370(ra) # 80002298 <wakeup>
  acquire(&p->lock);
    80002412:	854e                	mv	a0,s3
    80002414:	ffffe097          	auipc	ra,0xffffe
    80002418:	7c2080e7          	jalr	1986(ra) # 80000bd6 <acquire>
  p->xstate = status;
    8000241c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002420:	4795                	li	a5,5
    80002422:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002426:	8526                	mv	a0,s1
    80002428:	fffff097          	auipc	ra,0xfffff
    8000242c:	862080e7          	jalr	-1950(ra) # 80000c8a <release>
  sched();
    80002430:	00000097          	auipc	ra,0x0
    80002434:	cf2080e7          	jalr	-782(ra) # 80002122 <sched>
  panic("zombie exit");
    80002438:	00006517          	auipc	a0,0x6
    8000243c:	e3850513          	addi	a0,a0,-456 # 80008270 <digits+0x230>
    80002440:	ffffe097          	auipc	ra,0xffffe
    80002444:	0fe080e7          	jalr	254(ra) # 8000053e <panic>
    removeSwapFile(p);
    80002448:	854e                	mv	a0,s3
    8000244a:	00002097          	auipc	ra,0x2
    8000244e:	e84080e7          	jalr	-380(ra) # 800042ce <removeSwapFile>
    80002452:	bfa5                	j	800023ca <exit+0x62>

0000000080002454 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002454:	7179                	addi	sp,sp,-48
    80002456:	f406                	sd	ra,40(sp)
    80002458:	f022                	sd	s0,32(sp)
    8000245a:	ec26                	sd	s1,24(sp)
    8000245c:	e84a                	sd	s2,16(sp)
    8000245e:	e44e                	sd	s3,8(sp)
    80002460:	1800                	addi	s0,sp,48
    80002462:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002464:	0000f497          	auipc	s1,0xf
    80002468:	bfc48493          	addi	s1,s1,-1028 # 80011060 <proc>
    8000246c:	00021997          	auipc	s3,0x21
    80002470:	bf498993          	addi	s3,s3,-1036 # 80023060 <tickslock>
    acquire(&p->lock);
    80002474:	8526                	mv	a0,s1
    80002476:	ffffe097          	auipc	ra,0xffffe
    8000247a:	760080e7          	jalr	1888(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    8000247e:	589c                	lw	a5,48(s1)
    80002480:	01278d63          	beq	a5,s2,8000249a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002484:	8526                	mv	a0,s1
    80002486:	fffff097          	auipc	ra,0xfffff
    8000248a:	804080e7          	jalr	-2044(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000248e:	48048493          	addi	s1,s1,1152
    80002492:	ff3491e3          	bne	s1,s3,80002474 <kill+0x20>
  }
  return -1;
    80002496:	557d                	li	a0,-1
    80002498:	a829                	j	800024b2 <kill+0x5e>
      p->killed = 1;
    8000249a:	4785                	li	a5,1
    8000249c:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000249e:	4c98                	lw	a4,24(s1)
    800024a0:	4789                	li	a5,2
    800024a2:	00f70f63          	beq	a4,a5,800024c0 <kill+0x6c>
      release(&p->lock);
    800024a6:	8526                	mv	a0,s1
    800024a8:	ffffe097          	auipc	ra,0xffffe
    800024ac:	7e2080e7          	jalr	2018(ra) # 80000c8a <release>
      return 0;
    800024b0:	4501                	li	a0,0
}
    800024b2:	70a2                	ld	ra,40(sp)
    800024b4:	7402                	ld	s0,32(sp)
    800024b6:	64e2                	ld	s1,24(sp)
    800024b8:	6942                	ld	s2,16(sp)
    800024ba:	69a2                	ld	s3,8(sp)
    800024bc:	6145                	addi	sp,sp,48
    800024be:	8082                	ret
        p->state = RUNNABLE;
    800024c0:	478d                	li	a5,3
    800024c2:	cc9c                	sw	a5,24(s1)
    800024c4:	b7cd                	j	800024a6 <kill+0x52>

00000000800024c6 <setkilled>:

void
setkilled(struct proc *p)
{
    800024c6:	1101                	addi	sp,sp,-32
    800024c8:	ec06                	sd	ra,24(sp)
    800024ca:	e822                	sd	s0,16(sp)
    800024cc:	e426                	sd	s1,8(sp)
    800024ce:	1000                	addi	s0,sp,32
    800024d0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800024d2:	ffffe097          	auipc	ra,0xffffe
    800024d6:	704080e7          	jalr	1796(ra) # 80000bd6 <acquire>
  p->killed = 1;
    800024da:	4785                	li	a5,1
    800024dc:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800024de:	8526                	mv	a0,s1
    800024e0:	ffffe097          	auipc	ra,0xffffe
    800024e4:	7aa080e7          	jalr	1962(ra) # 80000c8a <release>
}
    800024e8:	60e2                	ld	ra,24(sp)
    800024ea:	6442                	ld	s0,16(sp)
    800024ec:	64a2                	ld	s1,8(sp)
    800024ee:	6105                	addi	sp,sp,32
    800024f0:	8082                	ret

00000000800024f2 <killed>:

int
killed(struct proc *p)
{
    800024f2:	1101                	addi	sp,sp,-32
    800024f4:	ec06                	sd	ra,24(sp)
    800024f6:	e822                	sd	s0,16(sp)
    800024f8:	e426                	sd	s1,8(sp)
    800024fa:	e04a                	sd	s2,0(sp)
    800024fc:	1000                	addi	s0,sp,32
    800024fe:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002500:	ffffe097          	auipc	ra,0xffffe
    80002504:	6d6080e7          	jalr	1750(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002508:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000250c:	8526                	mv	a0,s1
    8000250e:	ffffe097          	auipc	ra,0xffffe
    80002512:	77c080e7          	jalr	1916(ra) # 80000c8a <release>
  return k;
}
    80002516:	854a                	mv	a0,s2
    80002518:	60e2                	ld	ra,24(sp)
    8000251a:	6442                	ld	s0,16(sp)
    8000251c:	64a2                	ld	s1,8(sp)
    8000251e:	6902                	ld	s2,0(sp)
    80002520:	6105                	addi	sp,sp,32
    80002522:	8082                	ret

0000000080002524 <wait>:
{
    80002524:	715d                	addi	sp,sp,-80
    80002526:	e486                	sd	ra,72(sp)
    80002528:	e0a2                	sd	s0,64(sp)
    8000252a:	fc26                	sd	s1,56(sp)
    8000252c:	f84a                	sd	s2,48(sp)
    8000252e:	f44e                	sd	s3,40(sp)
    80002530:	f052                	sd	s4,32(sp)
    80002532:	ec56                	sd	s5,24(sp)
    80002534:	e85a                	sd	s6,16(sp)
    80002536:	e45e                	sd	s7,8(sp)
    80002538:	e062                	sd	s8,0(sp)
    8000253a:	0880                	addi	s0,sp,80
    8000253c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000253e:	fffff097          	auipc	ra,0xfffff
    80002542:	5ba080e7          	jalr	1466(ra) # 80001af8 <myproc>
    80002546:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002548:	0000e517          	auipc	a0,0xe
    8000254c:	70050513          	addi	a0,a0,1792 # 80010c48 <wait_lock>
    80002550:	ffffe097          	auipc	ra,0xffffe
    80002554:	686080e7          	jalr	1670(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002558:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000255a:	4a15                	li	s4,5
        havekids = 1;
    8000255c:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000255e:	00021997          	auipc	s3,0x21
    80002562:	b0298993          	addi	s3,s3,-1278 # 80023060 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002566:	0000ec17          	auipc	s8,0xe
    8000256a:	6e2c0c13          	addi	s8,s8,1762 # 80010c48 <wait_lock>
    havekids = 0;
    8000256e:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002570:	0000f497          	auipc	s1,0xf
    80002574:	af048493          	addi	s1,s1,-1296 # 80011060 <proc>
    80002578:	a0bd                	j	800025e6 <wait+0xc2>
          pid = pp->pid;
    8000257a:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000257e:	000b0e63          	beqz	s6,8000259a <wait+0x76>
    80002582:	4691                	li	a3,4
    80002584:	02c48613          	addi	a2,s1,44
    80002588:	85da                	mv	a1,s6
    8000258a:	05093503          	ld	a0,80(s2)
    8000258e:	fffff097          	auipc	ra,0xfffff
    80002592:	226080e7          	jalr	550(ra) # 800017b4 <copyout>
    80002596:	02054563          	bltz	a0,800025c0 <wait+0x9c>
          freeproc(pp);
    8000259a:	8526                	mv	a0,s1
    8000259c:	fffff097          	auipc	ra,0xfffff
    800025a0:	70e080e7          	jalr	1806(ra) # 80001caa <freeproc>
          release(&pp->lock);
    800025a4:	8526                	mv	a0,s1
    800025a6:	ffffe097          	auipc	ra,0xffffe
    800025aa:	6e4080e7          	jalr	1764(ra) # 80000c8a <release>
          release(&wait_lock);
    800025ae:	0000e517          	auipc	a0,0xe
    800025b2:	69a50513          	addi	a0,a0,1690 # 80010c48 <wait_lock>
    800025b6:	ffffe097          	auipc	ra,0xffffe
    800025ba:	6d4080e7          	jalr	1748(ra) # 80000c8a <release>
          return pid;
    800025be:	a0b5                	j	8000262a <wait+0x106>
            release(&pp->lock);
    800025c0:	8526                	mv	a0,s1
    800025c2:	ffffe097          	auipc	ra,0xffffe
    800025c6:	6c8080e7          	jalr	1736(ra) # 80000c8a <release>
            release(&wait_lock);
    800025ca:	0000e517          	auipc	a0,0xe
    800025ce:	67e50513          	addi	a0,a0,1662 # 80010c48 <wait_lock>
    800025d2:	ffffe097          	auipc	ra,0xffffe
    800025d6:	6b8080e7          	jalr	1720(ra) # 80000c8a <release>
            return -1;
    800025da:	59fd                	li	s3,-1
    800025dc:	a0b9                	j	8000262a <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800025de:	48048493          	addi	s1,s1,1152
    800025e2:	03348463          	beq	s1,s3,8000260a <wait+0xe6>
      if(pp->parent == p){
    800025e6:	7c9c                	ld	a5,56(s1)
    800025e8:	ff279be3          	bne	a5,s2,800025de <wait+0xba>
        acquire(&pp->lock);
    800025ec:	8526                	mv	a0,s1
    800025ee:	ffffe097          	auipc	ra,0xffffe
    800025f2:	5e8080e7          	jalr	1512(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    800025f6:	4c9c                	lw	a5,24(s1)
    800025f8:	f94781e3          	beq	a5,s4,8000257a <wait+0x56>
        release(&pp->lock);
    800025fc:	8526                	mv	a0,s1
    800025fe:	ffffe097          	auipc	ra,0xffffe
    80002602:	68c080e7          	jalr	1676(ra) # 80000c8a <release>
        havekids = 1;
    80002606:	8756                	mv	a4,s5
    80002608:	bfd9                	j	800025de <wait+0xba>
    if(!havekids || killed(p)){
    8000260a:	c719                	beqz	a4,80002618 <wait+0xf4>
    8000260c:	854a                	mv	a0,s2
    8000260e:	00000097          	auipc	ra,0x0
    80002612:	ee4080e7          	jalr	-284(ra) # 800024f2 <killed>
    80002616:	c51d                	beqz	a0,80002644 <wait+0x120>
      release(&wait_lock);
    80002618:	0000e517          	auipc	a0,0xe
    8000261c:	63050513          	addi	a0,a0,1584 # 80010c48 <wait_lock>
    80002620:	ffffe097          	auipc	ra,0xffffe
    80002624:	66a080e7          	jalr	1642(ra) # 80000c8a <release>
      return -1;
    80002628:	59fd                	li	s3,-1
}
    8000262a:	854e                	mv	a0,s3
    8000262c:	60a6                	ld	ra,72(sp)
    8000262e:	6406                	ld	s0,64(sp)
    80002630:	74e2                	ld	s1,56(sp)
    80002632:	7942                	ld	s2,48(sp)
    80002634:	79a2                	ld	s3,40(sp)
    80002636:	7a02                	ld	s4,32(sp)
    80002638:	6ae2                	ld	s5,24(sp)
    8000263a:	6b42                	ld	s6,16(sp)
    8000263c:	6ba2                	ld	s7,8(sp)
    8000263e:	6c02                	ld	s8,0(sp)
    80002640:	6161                	addi	sp,sp,80
    80002642:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002644:	85e2                	mv	a1,s8
    80002646:	854a                	mv	a0,s2
    80002648:	00000097          	auipc	ra,0x0
    8000264c:	bec080e7          	jalr	-1044(ra) # 80002234 <sleep>
    havekids = 0;
    80002650:	bf39                	j	8000256e <wait+0x4a>

0000000080002652 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002652:	7179                	addi	sp,sp,-48
    80002654:	f406                	sd	ra,40(sp)
    80002656:	f022                	sd	s0,32(sp)
    80002658:	ec26                	sd	s1,24(sp)
    8000265a:	e84a                	sd	s2,16(sp)
    8000265c:	e44e                	sd	s3,8(sp)
    8000265e:	e052                	sd	s4,0(sp)
    80002660:	1800                	addi	s0,sp,48
    80002662:	84aa                	mv	s1,a0
    80002664:	892e                	mv	s2,a1
    80002666:	89b2                	mv	s3,a2
    80002668:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000266a:	fffff097          	auipc	ra,0xfffff
    8000266e:	48e080e7          	jalr	1166(ra) # 80001af8 <myproc>
  if(user_dst){
    80002672:	c08d                	beqz	s1,80002694 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002674:	86d2                	mv	a3,s4
    80002676:	864e                	mv	a2,s3
    80002678:	85ca                	mv	a1,s2
    8000267a:	6928                	ld	a0,80(a0)
    8000267c:	fffff097          	auipc	ra,0xfffff
    80002680:	138080e7          	jalr	312(ra) # 800017b4 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002684:	70a2                	ld	ra,40(sp)
    80002686:	7402                	ld	s0,32(sp)
    80002688:	64e2                	ld	s1,24(sp)
    8000268a:	6942                	ld	s2,16(sp)
    8000268c:	69a2                	ld	s3,8(sp)
    8000268e:	6a02                	ld	s4,0(sp)
    80002690:	6145                	addi	sp,sp,48
    80002692:	8082                	ret
    memmove((char *)dst, src, len);
    80002694:	000a061b          	sext.w	a2,s4
    80002698:	85ce                	mv	a1,s3
    8000269a:	854a                	mv	a0,s2
    8000269c:	ffffe097          	auipc	ra,0xffffe
    800026a0:	692080e7          	jalr	1682(ra) # 80000d2e <memmove>
    return 0;
    800026a4:	8526                	mv	a0,s1
    800026a6:	bff9                	j	80002684 <either_copyout+0x32>

00000000800026a8 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026a8:	7179                	addi	sp,sp,-48
    800026aa:	f406                	sd	ra,40(sp)
    800026ac:	f022                	sd	s0,32(sp)
    800026ae:	ec26                	sd	s1,24(sp)
    800026b0:	e84a                	sd	s2,16(sp)
    800026b2:	e44e                	sd	s3,8(sp)
    800026b4:	e052                	sd	s4,0(sp)
    800026b6:	1800                	addi	s0,sp,48
    800026b8:	892a                	mv	s2,a0
    800026ba:	84ae                	mv	s1,a1
    800026bc:	89b2                	mv	s3,a2
    800026be:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026c0:	fffff097          	auipc	ra,0xfffff
    800026c4:	438080e7          	jalr	1080(ra) # 80001af8 <myproc>
  if(user_src){
    800026c8:	c08d                	beqz	s1,800026ea <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800026ca:	86d2                	mv	a3,s4
    800026cc:	864e                	mv	a2,s3
    800026ce:	85ca                	mv	a1,s2
    800026d0:	6928                	ld	a0,80(a0)
    800026d2:	fffff097          	auipc	ra,0xfffff
    800026d6:	16e080e7          	jalr	366(ra) # 80001840 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800026da:	70a2                	ld	ra,40(sp)
    800026dc:	7402                	ld	s0,32(sp)
    800026de:	64e2                	ld	s1,24(sp)
    800026e0:	6942                	ld	s2,16(sp)
    800026e2:	69a2                	ld	s3,8(sp)
    800026e4:	6a02                	ld	s4,0(sp)
    800026e6:	6145                	addi	sp,sp,48
    800026e8:	8082                	ret
    memmove(dst, (char*)src, len);
    800026ea:	000a061b          	sext.w	a2,s4
    800026ee:	85ce                	mv	a1,s3
    800026f0:	854a                	mv	a0,s2
    800026f2:	ffffe097          	auipc	ra,0xffffe
    800026f6:	63c080e7          	jalr	1596(ra) # 80000d2e <memmove>
    return 0;
    800026fa:	8526                	mv	a0,s1
    800026fc:	bff9                	j	800026da <either_copyin+0x32>

00000000800026fe <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800026fe:	715d                	addi	sp,sp,-80
    80002700:	e486                	sd	ra,72(sp)
    80002702:	e0a2                	sd	s0,64(sp)
    80002704:	fc26                	sd	s1,56(sp)
    80002706:	f84a                	sd	s2,48(sp)
    80002708:	f44e                	sd	s3,40(sp)
    8000270a:	f052                	sd	s4,32(sp)
    8000270c:	ec56                	sd	s5,24(sp)
    8000270e:	e85a                	sd	s6,16(sp)
    80002710:	e45e                	sd	s7,8(sp)
    80002712:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002714:	00006517          	auipc	a0,0x6
    80002718:	c7c50513          	addi	a0,a0,-900 # 80008390 <states.0+0xa0>
    8000271c:	ffffe097          	auipc	ra,0xffffe
    80002720:	e6c080e7          	jalr	-404(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002724:	0000f497          	auipc	s1,0xf
    80002728:	a9448493          	addi	s1,s1,-1388 # 800111b8 <proc+0x158>
    8000272c:	00021917          	auipc	s2,0x21
    80002730:	a8c90913          	addi	s2,s2,-1396 # 800231b8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002734:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002736:	00006997          	auipc	s3,0x6
    8000273a:	b4a98993          	addi	s3,s3,-1206 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    8000273e:	00006a97          	auipc	s5,0x6
    80002742:	b4aa8a93          	addi	s5,s5,-1206 # 80008288 <digits+0x248>
    printf("\n");
    80002746:	00006a17          	auipc	s4,0x6
    8000274a:	c4aa0a13          	addi	s4,s4,-950 # 80008390 <states.0+0xa0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000274e:	00006b97          	auipc	s7,0x6
    80002752:	ba2b8b93          	addi	s7,s7,-1118 # 800082f0 <states.0>
    80002756:	a00d                	j	80002778 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002758:	ed86a583          	lw	a1,-296(a3) # ed8 <_entry-0x7ffff128>
    8000275c:	8556                	mv	a0,s5
    8000275e:	ffffe097          	auipc	ra,0xffffe
    80002762:	e2a080e7          	jalr	-470(ra) # 80000588 <printf>
    printf("\n");
    80002766:	8552                	mv	a0,s4
    80002768:	ffffe097          	auipc	ra,0xffffe
    8000276c:	e20080e7          	jalr	-480(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002770:	48048493          	addi	s1,s1,1152
    80002774:	03248163          	beq	s1,s2,80002796 <procdump+0x98>
    if(p->state == UNUSED)
    80002778:	86a6                	mv	a3,s1
    8000277a:	ec04a783          	lw	a5,-320(s1)
    8000277e:	dbed                	beqz	a5,80002770 <procdump+0x72>
      state = "???";
    80002780:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002782:	fcfb6be3          	bltu	s6,a5,80002758 <procdump+0x5a>
    80002786:	1782                	slli	a5,a5,0x20
    80002788:	9381                	srli	a5,a5,0x20
    8000278a:	078e                	slli	a5,a5,0x3
    8000278c:	97de                	add	a5,a5,s7
    8000278e:	6390                	ld	a2,0(a5)
    80002790:	f661                	bnez	a2,80002758 <procdump+0x5a>
      state = "???";
    80002792:	864e                	mv	a2,s3
    80002794:	b7d1                	j	80002758 <procdump+0x5a>
  }
}
    80002796:	60a6                	ld	ra,72(sp)
    80002798:	6406                	ld	s0,64(sp)
    8000279a:	74e2                	ld	s1,56(sp)
    8000279c:	7942                	ld	s2,48(sp)
    8000279e:	79a2                	ld	s3,40(sp)
    800027a0:	7a02                	ld	s4,32(sp)
    800027a2:	6ae2                	ld	s5,24(sp)
    800027a4:	6b42                	ld	s6,16(sp)
    800027a6:	6ba2                	ld	s7,8(sp)
    800027a8:	6161                	addi	sp,sp,80
    800027aa:	8082                	ret

00000000800027ac <swapOutFromPysc>:


//ADDED 4.2
//swap out from pysc == swap in swap file
int 
swapOutFromPysc(pagetable_t pagetable,struct proc *p){
    800027ac:	7139                	addi	sp,sp,-64
    800027ae:	fc06                	sd	ra,56(sp)
    800027b0:	f822                	sd	s0,48(sp)
    800027b2:	f426                	sd	s1,40(sp)
    800027b4:	f04a                	sd	s2,32(sp)
    800027b6:	ec4e                	sd	s3,24(sp)
    800027b8:	e852                	sd	s4,16(sp)
    800027ba:	e456                	sd	s5,8(sp)
    800027bc:	0080                	addi	s0,sp,64
       if(p->physicalPagesCount+p->swapPagesCount==MAX_TOTAL_PAGES){
    800027be:	2705b783          	ld	a5,624(a1)
    800027c2:	2785b703          	ld	a4,632(a1)
    800027c6:	97ba                	add	a5,a5,a4
    800027c8:	02000713          	li	a4,32
    800027cc:	02e78863          	beq	a5,a4,800027fc <swapOutFromPysc+0x50>
    800027d0:	89aa                	mv	s3,a0
    800027d2:	892e                	mv	s2,a1
      }
      //idx of page to removed from pysical memory 
      int idx = pageSwapPolicy(); //TODO
      struct metaData *removedPageFromPsyc = &p->pagesInPysical[idx];
      //looking for free struct into pagesInSwap to put the removed page
      for(struct metaData *page = p->pagesInSwap; page < &p->pagesInSwap[MAX_PSYC_PAGES]; page++){
    800027d4:	38058a13          	addi	s4,a1,896
    800027d8:	48058713          	addi	a4,a1,1152
    800027dc:	84d2                	mv	s1,s4
        //empty space in the swapArr is found
        if(page->idxIsHere==0){
    800027de:	649c                	ld	a5,8(s1)
    800027e0:	cb85                	beqz	a5,80002810 <swapOutFromPysc+0x64>
      for(struct metaData *page = p->pagesInSwap; page < &p->pagesInSwap[MAX_PSYC_PAGES]; page++){
    800027e2:	04c1                	addi	s1,s1,16
    800027e4:	fee49de3          	bne	s1,a4,800027de <swapOutFromPysc+0x32>
          p->physicalPagesCount--;
          sfence_vma(); // flush to TLB
          break;
      }
    }
    return 0;
    800027e8:	4501                	li	a0,0
  }
    800027ea:	70e2                	ld	ra,56(sp)
    800027ec:	7442                	ld	s0,48(sp)
    800027ee:	74a2                	ld	s1,40(sp)
    800027f0:	7902                	ld	s2,32(sp)
    800027f2:	69e2                	ld	s3,24(sp)
    800027f4:	6a42                	ld	s4,16(sp)
    800027f6:	6aa2                	ld	s5,8(sp)
    800027f8:	6121                	addi	sp,sp,64
    800027fa:	8082                	ret
        printf("exceeded number of possible pages\n");
    800027fc:	00006517          	auipc	a0,0x6
    80002800:	a9c50513          	addi	a0,a0,-1380 # 80008298 <digits+0x258>
    80002804:	ffffe097          	auipc	ra,0xffffe
    80002808:	d84080e7          	jalr	-636(ra) # 80000588 <printf>
        return -1;
    8000280c:	557d                	li	a0,-1
    8000280e:	bff1                	j	800027ea <swapOutFromPysc+0x3e>
          page->idxIsHere = 1;
    80002810:	4785                	li	a5,1
    80002812:	e49c                	sd	a5,8(s1)
          page->va=removedPageFromPsyc->va;
    80002814:	28093583          	ld	a1,640(s2)
    80002818:	e08c                	sd	a1,0(s1)
          uint64 pa = walkaddr(pagetable, page->va);
    8000281a:	854e                	mv	a0,s3
    8000281c:	fffff097          	auipc	ra,0xfffff
    80002820:	8f0080e7          	jalr	-1808(ra) # 8000110c <walkaddr>
    80002824:	8aaa                	mv	s5,a0
          pte_t* entry = walk(pagetable, page->va, 0);
    80002826:	4601                	li	a2,0
    80002828:	608c                	ld	a1,0(s1)
    8000282a:	854e                	mv	a0,s3
    8000282c:	fffff097          	auipc	ra,0xfffff
    80002830:	83a080e7          	jalr	-1990(ra) # 80001066 <walk>
    80002834:	89aa                	mv	s3,a0
          if(writeToSwapFile(p,(char *)pa, (page-(p->pagesInSwap)) * PGSIZE, PGSIZE)< PGSIZE){
    80002836:	41448633          	sub	a2,s1,s4
    8000283a:	6685                	lui	a3,0x1
    8000283c:	0086161b          	slliw	a2,a2,0x8
    80002840:	85d6                	mv	a1,s5
    80002842:	854a                	mv	a0,s2
    80002844:	00002097          	auipc	ra,0x2
    80002848:	ce2080e7          	jalr	-798(ra) # 80004526 <writeToSwapFile>
    8000284c:	6785                	lui	a5,0x1
    8000284e:	04f54063          	blt	a0,a5,8000288e <swapOutFromPysc+0xe2>
          p->swapPagesCount++;
    80002852:	27893783          	ld	a5,632(s2)
    80002856:	0785                	addi	a5,a5,1
    80002858:	26f93c23          	sd	a5,632(s2)
          kfree((void *)pa);
    8000285c:	8556                	mv	a0,s5
    8000285e:	ffffe097          	auipc	ra,0xffffe
    80002862:	18c080e7          	jalr	396(ra) # 800009ea <kfree>
          *entry = ~PTE_V & *entry;//not present in pte anymore 
    80002866:	0009b783          	ld	a5,0(s3)
    8000286a:	9bf9                	andi	a5,a5,-2
    8000286c:	2007e793          	ori	a5,a5,512
    80002870:	00f9b023          	sd	a5,0(s3)
          removedPageFromPsyc->idxIsHere=0;
    80002874:	28093423          	sd	zero,648(s2)
          removedPageFromPsyc->va=0;
    80002878:	28093023          	sd	zero,640(s2)
          p->physicalPagesCount--;
    8000287c:	27093783          	ld	a5,624(s2)
    80002880:	17fd                	addi	a5,a5,-1
    80002882:	26f93823          	sd	a5,624(s2)
  asm volatile("sfence.vma zero, zero");
    80002886:	12000073          	sfence.vma
    return 0;
    8000288a:	4501                	li	a0,0
}
    8000288c:	bfb9                	j	800027ea <swapOutFromPysc+0x3e>
            return -1;
    8000288e:	557d                	li	a0,-1
    80002890:	bfa9                	j	800027ea <swapOutFromPysc+0x3e>

0000000080002892 <pageSwapPolicy>:

  int pageSwapPolicy(){
    80002892:	1141                	addi	sp,sp,-16
    80002894:	e422                	sd	s0,8(sp)
    80002896:	0800                	addi	s0,sp,16
    return 0;
    80002898:	4501                	li	a0,0
    8000289a:	6422                	ld	s0,8(sp)
    8000289c:	0141                	addi	sp,sp,16
    8000289e:	8082                	ret

00000000800028a0 <swtch>:
    800028a0:	00153023          	sd	ra,0(a0)
    800028a4:	00253423          	sd	sp,8(a0)
    800028a8:	e900                	sd	s0,16(a0)
    800028aa:	ed04                	sd	s1,24(a0)
    800028ac:	03253023          	sd	s2,32(a0)
    800028b0:	03353423          	sd	s3,40(a0)
    800028b4:	03453823          	sd	s4,48(a0)
    800028b8:	03553c23          	sd	s5,56(a0)
    800028bc:	05653023          	sd	s6,64(a0)
    800028c0:	05753423          	sd	s7,72(a0)
    800028c4:	05853823          	sd	s8,80(a0)
    800028c8:	05953c23          	sd	s9,88(a0)
    800028cc:	07a53023          	sd	s10,96(a0)
    800028d0:	07b53423          	sd	s11,104(a0)
    800028d4:	0005b083          	ld	ra,0(a1)
    800028d8:	0085b103          	ld	sp,8(a1)
    800028dc:	6980                	ld	s0,16(a1)
    800028de:	6d84                	ld	s1,24(a1)
    800028e0:	0205b903          	ld	s2,32(a1)
    800028e4:	0285b983          	ld	s3,40(a1)
    800028e8:	0305ba03          	ld	s4,48(a1)
    800028ec:	0385ba83          	ld	s5,56(a1)
    800028f0:	0405bb03          	ld	s6,64(a1)
    800028f4:	0485bb83          	ld	s7,72(a1)
    800028f8:	0505bc03          	ld	s8,80(a1)
    800028fc:	0585bc83          	ld	s9,88(a1)
    80002900:	0605bd03          	ld	s10,96(a1)
    80002904:	0685bd83          	ld	s11,104(a1)
    80002908:	8082                	ret

000000008000290a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000290a:	1141                	addi	sp,sp,-16
    8000290c:	e406                	sd	ra,8(sp)
    8000290e:	e022                	sd	s0,0(sp)
    80002910:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002912:	00006597          	auipc	a1,0x6
    80002916:	a0e58593          	addi	a1,a1,-1522 # 80008320 <states.0+0x30>
    8000291a:	00020517          	auipc	a0,0x20
    8000291e:	74650513          	addi	a0,a0,1862 # 80023060 <tickslock>
    80002922:	ffffe097          	auipc	ra,0xffffe
    80002926:	224080e7          	jalr	548(ra) # 80000b46 <initlock>
}
    8000292a:	60a2                	ld	ra,8(sp)
    8000292c:	6402                	ld	s0,0(sp)
    8000292e:	0141                	addi	sp,sp,16
    80002930:	8082                	ret

0000000080002932 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002932:	1141                	addi	sp,sp,-16
    80002934:	e422                	sd	s0,8(sp)
    80002936:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002938:	00004797          	auipc	a5,0x4
    8000293c:	b9878793          	addi	a5,a5,-1128 # 800064d0 <kernelvec>
    80002940:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002944:	6422                	ld	s0,8(sp)
    80002946:	0141                	addi	sp,sp,16
    80002948:	8082                	ret

000000008000294a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000294a:	1141                	addi	sp,sp,-16
    8000294c:	e406                	sd	ra,8(sp)
    8000294e:	e022                	sd	s0,0(sp)
    80002950:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002952:	fffff097          	auipc	ra,0xfffff
    80002956:	1a6080e7          	jalr	422(ra) # 80001af8 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000295a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000295e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002960:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002964:	00004617          	auipc	a2,0x4
    80002968:	69c60613          	addi	a2,a2,1692 # 80007000 <_trampoline>
    8000296c:	00004697          	auipc	a3,0x4
    80002970:	69468693          	addi	a3,a3,1684 # 80007000 <_trampoline>
    80002974:	8e91                	sub	a3,a3,a2
    80002976:	040007b7          	lui	a5,0x4000
    8000297a:	17fd                	addi	a5,a5,-1
    8000297c:	07b2                	slli	a5,a5,0xc
    8000297e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002980:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002984:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002986:	180026f3          	csrr	a3,satp
    8000298a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000298c:	6d38                	ld	a4,88(a0)
    8000298e:	6134                	ld	a3,64(a0)
    80002990:	6585                	lui	a1,0x1
    80002992:	96ae                	add	a3,a3,a1
    80002994:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002996:	6d38                	ld	a4,88(a0)
    80002998:	00000697          	auipc	a3,0x0
    8000299c:	13068693          	addi	a3,a3,304 # 80002ac8 <usertrap>
    800029a0:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029a2:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029a4:	8692                	mv	a3,tp
    800029a6:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029a8:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029ac:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029b0:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029b4:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029b8:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029ba:	6f18                	ld	a4,24(a4)
    800029bc:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029c0:	6928                	ld	a0,80(a0)
    800029c2:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800029c4:	00004717          	auipc	a4,0x4
    800029c8:	6d870713          	addi	a4,a4,1752 # 8000709c <userret>
    800029cc:	8f11                	sub	a4,a4,a2
    800029ce:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800029d0:	577d                	li	a4,-1
    800029d2:	177e                	slli	a4,a4,0x3f
    800029d4:	8d59                	or	a0,a0,a4
    800029d6:	9782                	jalr	a5
}
    800029d8:	60a2                	ld	ra,8(sp)
    800029da:	6402                	ld	s0,0(sp)
    800029dc:	0141                	addi	sp,sp,16
    800029de:	8082                	ret

00000000800029e0 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800029e0:	1101                	addi	sp,sp,-32
    800029e2:	ec06                	sd	ra,24(sp)
    800029e4:	e822                	sd	s0,16(sp)
    800029e6:	e426                	sd	s1,8(sp)
    800029e8:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800029ea:	00020497          	auipc	s1,0x20
    800029ee:	67648493          	addi	s1,s1,1654 # 80023060 <tickslock>
    800029f2:	8526                	mv	a0,s1
    800029f4:	ffffe097          	auipc	ra,0xffffe
    800029f8:	1e2080e7          	jalr	482(ra) # 80000bd6 <acquire>
  ticks++;
    800029fc:	00006517          	auipc	a0,0x6
    80002a00:	fc450513          	addi	a0,a0,-60 # 800089c0 <ticks>
    80002a04:	411c                	lw	a5,0(a0)
    80002a06:	2785                	addiw	a5,a5,1
    80002a08:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a0a:	00000097          	auipc	ra,0x0
    80002a0e:	88e080e7          	jalr	-1906(ra) # 80002298 <wakeup>
  release(&tickslock);
    80002a12:	8526                	mv	a0,s1
    80002a14:	ffffe097          	auipc	ra,0xffffe
    80002a18:	276080e7          	jalr	630(ra) # 80000c8a <release>
}
    80002a1c:	60e2                	ld	ra,24(sp)
    80002a1e:	6442                	ld	s0,16(sp)
    80002a20:	64a2                	ld	s1,8(sp)
    80002a22:	6105                	addi	sp,sp,32
    80002a24:	8082                	ret

0000000080002a26 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a26:	1101                	addi	sp,sp,-32
    80002a28:	ec06                	sd	ra,24(sp)
    80002a2a:	e822                	sd	s0,16(sp)
    80002a2c:	e426                	sd	s1,8(sp)
    80002a2e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a30:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a34:	00074d63          	bltz	a4,80002a4e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a38:	57fd                	li	a5,-1
    80002a3a:	17fe                	slli	a5,a5,0x3f
    80002a3c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a3e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a40:	06f70363          	beq	a4,a5,80002aa6 <devintr+0x80>
  }
}
    80002a44:	60e2                	ld	ra,24(sp)
    80002a46:	6442                	ld	s0,16(sp)
    80002a48:	64a2                	ld	s1,8(sp)
    80002a4a:	6105                	addi	sp,sp,32
    80002a4c:	8082                	ret
     (scause & 0xff) == 9){
    80002a4e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a52:	46a5                	li	a3,9
    80002a54:	fed792e3          	bne	a5,a3,80002a38 <devintr+0x12>
    int irq = plic_claim();
    80002a58:	00004097          	auipc	ra,0x4
    80002a5c:	b80080e7          	jalr	-1152(ra) # 800065d8 <plic_claim>
    80002a60:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a62:	47a9                	li	a5,10
    80002a64:	02f50763          	beq	a0,a5,80002a92 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a68:	4785                	li	a5,1
    80002a6a:	02f50963          	beq	a0,a5,80002a9c <devintr+0x76>
    return 1;
    80002a6e:	4505                	li	a0,1
    } else if(irq){
    80002a70:	d8f1                	beqz	s1,80002a44 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a72:	85a6                	mv	a1,s1
    80002a74:	00006517          	auipc	a0,0x6
    80002a78:	8b450513          	addi	a0,a0,-1868 # 80008328 <states.0+0x38>
    80002a7c:	ffffe097          	auipc	ra,0xffffe
    80002a80:	b0c080e7          	jalr	-1268(ra) # 80000588 <printf>
      plic_complete(irq);
    80002a84:	8526                	mv	a0,s1
    80002a86:	00004097          	auipc	ra,0x4
    80002a8a:	b76080e7          	jalr	-1162(ra) # 800065fc <plic_complete>
    return 1;
    80002a8e:	4505                	li	a0,1
    80002a90:	bf55                	j	80002a44 <devintr+0x1e>
      uartintr();
    80002a92:	ffffe097          	auipc	ra,0xffffe
    80002a96:	f08080e7          	jalr	-248(ra) # 8000099a <uartintr>
    80002a9a:	b7ed                	j	80002a84 <devintr+0x5e>
      virtio_disk_intr();
    80002a9c:	00004097          	auipc	ra,0x4
    80002aa0:	02c080e7          	jalr	44(ra) # 80006ac8 <virtio_disk_intr>
    80002aa4:	b7c5                	j	80002a84 <devintr+0x5e>
    if(cpuid() == 0){
    80002aa6:	fffff097          	auipc	ra,0xfffff
    80002aaa:	026080e7          	jalr	38(ra) # 80001acc <cpuid>
    80002aae:	c901                	beqz	a0,80002abe <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002ab0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002ab4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002ab6:	14479073          	csrw	sip,a5
    return 2;
    80002aba:	4509                	li	a0,2
    80002abc:	b761                	j	80002a44 <devintr+0x1e>
      clockintr();
    80002abe:	00000097          	auipc	ra,0x0
    80002ac2:	f22080e7          	jalr	-222(ra) # 800029e0 <clockintr>
    80002ac6:	b7ed                	j	80002ab0 <devintr+0x8a>

0000000080002ac8 <usertrap>:
{
    80002ac8:	7139                	addi	sp,sp,-64
    80002aca:	fc06                	sd	ra,56(sp)
    80002acc:	f822                	sd	s0,48(sp)
    80002ace:	f426                	sd	s1,40(sp)
    80002ad0:	f04a                	sd	s2,32(sp)
    80002ad2:	ec4e                	sd	s3,24(sp)
    80002ad4:	e852                	sd	s4,16(sp)
    80002ad6:	e456                	sd	s5,8(sp)
    80002ad8:	0080                	addi	s0,sp,64
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ada:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002ade:	1007f793          	andi	a5,a5,256
    80002ae2:	ebd5                	bnez	a5,80002b96 <usertrap+0xce>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ae4:	00004797          	auipc	a5,0x4
    80002ae8:	9ec78793          	addi	a5,a5,-1556 # 800064d0 <kernelvec>
    80002aec:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002af0:	fffff097          	auipc	ra,0xfffff
    80002af4:	008080e7          	jalr	8(ra) # 80001af8 <myproc>
    80002af8:	892a                	mv	s2,a0
  p->trapframe->epc = r_sepc();
    80002afa:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002afc:	14102773          	csrr	a4,sepc
    80002b00:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b02:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b06:	47a1                	li	a5,8
    80002b08:	08f70f63          	beq	a4,a5,80002ba6 <usertrap+0xde>
    80002b0c:	14202773          	csrr	a4,scause
   } else if(r_scause() == 13 || r_scause() == 15){
    80002b10:	47b5                	li	a5,13
    80002b12:	00f70763          	beq	a4,a5,80002b20 <usertrap+0x58>
    80002b16:	14202773          	csrr	a4,scause
    80002b1a:	47bd                	li	a5,15
    80002b1c:	1af71863          	bne	a4,a5,80002ccc <usertrap+0x204>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b20:	143024f3          	csrr	s1,stval
    if ((*(walk(p->pagetable, va, 0)) & PTE_PG) == 0){
    80002b24:	4601                	li	a2,0
    80002b26:	85a6                	mv	a1,s1
    80002b28:	05093503          	ld	a0,80(s2)
    80002b2c:	ffffe097          	auipc	ra,0xffffe
    80002b30:	53a080e7          	jalr	1338(ra) # 80001066 <walk>
    80002b34:	611c                	ld	a5,0(a0)
    80002b36:	2007f793          	andi	a5,a5,512
    80002b3a:	c3cd                	beqz	a5,80002bdc <usertrap+0x114>
      if(p->physicalPagesCount ==MAX_PSYC_PAGES){
    80002b3c:	27093703          	ld	a4,624(s2)
    80002b40:	47c1                	li	a5,16
    80002b42:	0cf70b63          	beq	a4,a5,80002c18 <usertrap+0x150>
      char *space= kalloc();
    80002b46:	ffffe097          	auipc	ra,0xffffe
    80002b4a:	fa0080e7          	jalr	-96(ra) # 80000ae6 <kalloc>
    80002b4e:	89aa                	mv	s3,a0
      uint64 newVa = PGROUNDDOWN(va);
    80002b50:	75fd                	lui	a1,0xfffff
    80002b52:	8de5                	and	a1,a1,s1
      for(struct metaData *page=p->pagesInSwap;page<&p->pagesInSwap[MAX_PSYC_PAGES];page++){
    80002b54:	38090a93          	addi	s5,s2,896
    80002b58:	48090713          	addi	a4,s2,1152
    80002b5c:	84d6                	mv	s1,s5
        if(page->va==newVa){
    80002b5e:	609c                	ld	a5,0(s1)
    80002b60:	0cb78463          	beq	a5,a1,80002c28 <usertrap+0x160>
      for(struct metaData *page=p->pagesInSwap;page<&p->pagesInSwap[MAX_PSYC_PAGES];page++){
    80002b64:	04c1                	addi	s1,s1,16
    80002b66:	fee49ce3          	bne	s1,a4,80002b5e <usertrap+0x96>
  asm volatile("sfence.vma zero, zero");
    80002b6a:	12000073          	sfence.vma
  if(killed(p))
    80002b6e:	854a                	mv	a0,s2
    80002b70:	00000097          	auipc	ra,0x0
    80002b74:	982080e7          	jalr	-1662(ra) # 800024f2 <killed>
    80002b78:	1a051563          	bnez	a0,80002d22 <usertrap+0x25a>
  usertrapret();
    80002b7c:	00000097          	auipc	ra,0x0
    80002b80:	dce080e7          	jalr	-562(ra) # 8000294a <usertrapret>
}
    80002b84:	70e2                	ld	ra,56(sp)
    80002b86:	7442                	ld	s0,48(sp)
    80002b88:	74a2                	ld	s1,40(sp)
    80002b8a:	7902                	ld	s2,32(sp)
    80002b8c:	69e2                	ld	s3,24(sp)
    80002b8e:	6a42                	ld	s4,16(sp)
    80002b90:	6aa2                	ld	s5,8(sp)
    80002b92:	6121                	addi	sp,sp,64
    80002b94:	8082                	ret
    panic("usertrap: not from user mode");
    80002b96:	00005517          	auipc	a0,0x5
    80002b9a:	7b250513          	addi	a0,a0,1970 # 80008348 <states.0+0x58>
    80002b9e:	ffffe097          	auipc	ra,0xffffe
    80002ba2:	9a0080e7          	jalr	-1632(ra) # 8000053e <panic>
    if(killed(p))
    80002ba6:	00000097          	auipc	ra,0x0
    80002baa:	94c080e7          	jalr	-1716(ra) # 800024f2 <killed>
    80002bae:	e10d                	bnez	a0,80002bd0 <usertrap+0x108>
    p->trapframe->epc += 4;
    80002bb0:	05893703          	ld	a4,88(s2)
    80002bb4:	6f1c                	ld	a5,24(a4)
    80002bb6:	0791                	addi	a5,a5,4
    80002bb8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bba:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002bbe:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bc2:	10079073          	csrw	sstatus,a5
    syscall();
    80002bc6:	00000097          	auipc	ra,0x0
    80002bca:	3c2080e7          	jalr	962(ra) # 80002f88 <syscall>
    80002bce:	b745                	j	80002b6e <usertrap+0xa6>
      exit(-1);
    80002bd0:	557d                	li	a0,-1
    80002bd2:	fffff097          	auipc	ra,0xfffff
    80002bd6:	796080e7          	jalr	1942(ra) # 80002368 <exit>
    80002bda:	bfd9                	j	80002bb0 <usertrap+0xe8>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bdc:	142025f3          	csrr	a1,scause
      printf("usertrap(): segmentation fault %p pid=%d\n", r_scause(), p->pid);
    80002be0:	03092603          	lw	a2,48(s2)
    80002be4:	00005517          	auipc	a0,0x5
    80002be8:	78450513          	addi	a0,a0,1924 # 80008368 <states.0+0x78>
    80002bec:	ffffe097          	auipc	ra,0xffffe
    80002bf0:	99c080e7          	jalr	-1636(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bf4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bf8:	14302673          	csrr	a2,stval
      printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bfc:	00005517          	auipc	a0,0x5
    80002c00:	79c50513          	addi	a0,a0,1948 # 80008398 <states.0+0xa8>
    80002c04:	ffffe097          	auipc	ra,0xffffe
    80002c08:	984080e7          	jalr	-1660(ra) # 80000588 <printf>
      setkilled(p);
    80002c0c:	854a                	mv	a0,s2
    80002c0e:	00000097          	auipc	ra,0x0
    80002c12:	8b8080e7          	jalr	-1864(ra) # 800024c6 <setkilled>
    80002c16:	bfa1                	j	80002b6e <usertrap+0xa6>
        swapOutFromPysc(p->pagetable,p);
    80002c18:	85ca                	mv	a1,s2
    80002c1a:	05093503          	ld	a0,80(s2)
    80002c1e:	00000097          	auipc	ra,0x0
    80002c22:	b8e080e7          	jalr	-1138(ra) # 800027ac <swapOutFromPysc>
    80002c26:	b705                	j	80002b46 <usertrap+0x7e>
          pte_t *entry = walk(p->pagetable, newVa, 0);
    80002c28:	4601                	li	a2,0
    80002c2a:	05093503          	ld	a0,80(s2)
    80002c2e:	ffffe097          	auipc	ra,0xffffe
    80002c32:	438080e7          	jalr	1080(ra) # 80001066 <walk>
    80002c36:	8a2a                	mv	s4,a0
             if (readFromSwapFile(p, space,(page-p->pagesInSwap)*PGSIZE, PGSIZE) < PGSIZE){
    80002c38:	41548633          	sub	a2,s1,s5
    80002c3c:	6685                	lui	a3,0x1
    80002c3e:	0086161b          	slliw	a2,a2,0x8
    80002c42:	85ce                	mv	a1,s3
    80002c44:	854a                	mv	a0,s2
    80002c46:	00002097          	auipc	ra,0x2
    80002c4a:	904080e7          	jalr	-1788(ra) # 8000454a <readFromSwapFile>
    80002c4e:	6785                	lui	a5,0x1
    80002c50:	06f54163          	blt	a0,a5,80002cb2 <usertrap+0x1ea>
        for(freeP = p->pagesInPysical; freeP < &p->pagesInPysical[MAX_PSYC_PAGES]; freeP++ ){
    80002c54:	28090613          	addi	a2,s2,640
    80002c58:	38090693          	addi	a3,s2,896
    80002c5c:	87b2                	mv	a5,a2
          if(freeP->idxIsHere==0){
    80002c5e:	6798                	ld	a4,8(a5)
    80002c60:	c335                	beqz	a4,80002cc4 <usertrap+0x1fc>
        for(freeP = p->pagesInPysical; freeP < &p->pagesInPysical[MAX_PSYC_PAGES]; freeP++ ){
    80002c62:	07c1                	addi	a5,a5,16
    80002c64:	fed79de3          	bne	a5,a3,80002c5e <usertrap+0x196>
        int freeIdx=0; 
    80002c68:	4781                	li	a5,0
        freeP->idxIsHere=1;
    80002c6a:	0792                	slli	a5,a5,0x4
    80002c6c:	97ca                	add	a5,a5,s2
    80002c6e:	4705                	li	a4,1
    80002c70:	28e7b423          	sd	a4,648(a5) # 1288 <_entry-0x7fffed78>
        freeP->va=page->va;
    80002c74:	6098                	ld	a4,0(s1)
    80002c76:	28e7b023          	sd	a4,640(a5)
        p->physicalPagesCount++;//we update our counter as well 
    80002c7a:	27093783          	ld	a5,624(s2)
    80002c7e:	0785                	addi	a5,a5,1
    80002c80:	26f93823          	sd	a5,624(s2)
        p->swapPagesCount--;
    80002c84:	27893783          	ld	a5,632(s2)
    80002c88:	17fd                	addi	a5,a5,-1
    80002c8a:	26f93c23          	sd	a5,632(s2)
        page->idxIsHere=0;
    80002c8e:	0004b423          	sd	zero,8(s1)
        page->va=0;
    80002c92:	0004b023          	sd	zero,0(s1)
        *entry= PA2PTE((uint64)space)|PTE_FLAGS(*entry);
    80002c96:	00c9d993          	srli	s3,s3,0xc
    80002c9a:	09aa                	slli	s3,s3,0xa
    80002c9c:	000a3783          	ld	a5,0(s4)
    80002ca0:	1ff7f793          	andi	a5,a5,511
        *entry=*entry & ~PTE_PG;
    80002ca4:	0137e9b3          	or	s3,a5,s3
        *entry=*entry | PTE_V;
    80002ca8:	0019e993          	ori	s3,s3,1
    80002cac:	013a3023          	sd	s3,0(s4)
        break;
    80002cb0:	bd6d                	j	80002b6a <usertrap+0xa2>
              printf("error: readFromSwapFile less than PGSIZE chars in usertrap\
    80002cb2:	00005517          	auipc	a0,0x5
    80002cb6:	70650513          	addi	a0,a0,1798 # 800083b8 <states.0+0xc8>
    80002cba:	ffffe097          	auipc	ra,0xffffe
    80002cbe:	8ce080e7          	jalr	-1842(ra) # 80000588 <printf>
    80002cc2:	bf49                	j	80002c54 <usertrap+0x18c>
            freeIdx=(int)(freeP-(p->pagesInPysical));
    80002cc4:	8f91                	sub	a5,a5,a2
    80002cc6:	8791                	srai	a5,a5,0x4
    80002cc8:	2781                	sext.w	a5,a5
            break;
    80002cca:	b745                	j	80002c6a <usertrap+0x1a2>
  else if((which_dev = devintr()) != 0){
    80002ccc:	00000097          	auipc	ra,0x0
    80002cd0:	d5a080e7          	jalr	-678(ra) # 80002a26 <devintr>
    80002cd4:	84aa                	mv	s1,a0
    80002cd6:	c901                	beqz	a0,80002ce6 <usertrap+0x21e>
  if(killed(p))
    80002cd8:	854a                	mv	a0,s2
    80002cda:	00000097          	auipc	ra,0x0
    80002cde:	818080e7          	jalr	-2024(ra) # 800024f2 <killed>
    80002ce2:	c531                	beqz	a0,80002d2e <usertrap+0x266>
    80002ce4:	a081                	j	80002d24 <usertrap+0x25c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ce6:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002cea:	03092603          	lw	a2,48(s2)
    80002cee:	00005517          	auipc	a0,0x5
    80002cf2:	71a50513          	addi	a0,a0,1818 # 80008408 <states.0+0x118>
    80002cf6:	ffffe097          	auipc	ra,0xffffe
    80002cfa:	892080e7          	jalr	-1902(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cfe:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d02:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d06:	00005517          	auipc	a0,0x5
    80002d0a:	69250513          	addi	a0,a0,1682 # 80008398 <states.0+0xa8>
    80002d0e:	ffffe097          	auipc	ra,0xffffe
    80002d12:	87a080e7          	jalr	-1926(ra) # 80000588 <printf>
    setkilled(p);
    80002d16:	854a                	mv	a0,s2
    80002d18:	fffff097          	auipc	ra,0xfffff
    80002d1c:	7ae080e7          	jalr	1966(ra) # 800024c6 <setkilled>
    80002d20:	b5b9                	j	80002b6e <usertrap+0xa6>
  if(killed(p))
    80002d22:	4481                	li	s1,0
    exit(-1);
    80002d24:	557d                	li	a0,-1
    80002d26:	fffff097          	auipc	ra,0xfffff
    80002d2a:	642080e7          	jalr	1602(ra) # 80002368 <exit>
  if(which_dev == 2)
    80002d2e:	4789                	li	a5,2
    80002d30:	e4f496e3          	bne	s1,a5,80002b7c <usertrap+0xb4>
    yield();
    80002d34:	fffff097          	auipc	ra,0xfffff
    80002d38:	4c4080e7          	jalr	1220(ra) # 800021f8 <yield>
    80002d3c:	b581                	j	80002b7c <usertrap+0xb4>

0000000080002d3e <kerneltrap>:
{
    80002d3e:	7179                	addi	sp,sp,-48
    80002d40:	f406                	sd	ra,40(sp)
    80002d42:	f022                	sd	s0,32(sp)
    80002d44:	ec26                	sd	s1,24(sp)
    80002d46:	e84a                	sd	s2,16(sp)
    80002d48:	e44e                	sd	s3,8(sp)
    80002d4a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d4c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d50:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d54:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002d58:	1004f793          	andi	a5,s1,256
    80002d5c:	cb85                	beqz	a5,80002d8c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d5e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002d62:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002d64:	ef85                	bnez	a5,80002d9c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002d66:	00000097          	auipc	ra,0x0
    80002d6a:	cc0080e7          	jalr	-832(ra) # 80002a26 <devintr>
    80002d6e:	cd1d                	beqz	a0,80002dac <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d70:	4789                	li	a5,2
    80002d72:	06f50a63          	beq	a0,a5,80002de6 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d76:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d7a:	10049073          	csrw	sstatus,s1
}
    80002d7e:	70a2                	ld	ra,40(sp)
    80002d80:	7402                	ld	s0,32(sp)
    80002d82:	64e2                	ld	s1,24(sp)
    80002d84:	6942                	ld	s2,16(sp)
    80002d86:	69a2                	ld	s3,8(sp)
    80002d88:	6145                	addi	sp,sp,48
    80002d8a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002d8c:	00005517          	auipc	a0,0x5
    80002d90:	6ac50513          	addi	a0,a0,1708 # 80008438 <states.0+0x148>
    80002d94:	ffffd097          	auipc	ra,0xffffd
    80002d98:	7aa080e7          	jalr	1962(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002d9c:	00005517          	auipc	a0,0x5
    80002da0:	6c450513          	addi	a0,a0,1732 # 80008460 <states.0+0x170>
    80002da4:	ffffd097          	auipc	ra,0xffffd
    80002da8:	79a080e7          	jalr	1946(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002dac:	85ce                	mv	a1,s3
    80002dae:	00005517          	auipc	a0,0x5
    80002db2:	6d250513          	addi	a0,a0,1746 # 80008480 <states.0+0x190>
    80002db6:	ffffd097          	auipc	ra,0xffffd
    80002dba:	7d2080e7          	jalr	2002(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dbe:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002dc2:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002dc6:	00005517          	auipc	a0,0x5
    80002dca:	6ca50513          	addi	a0,a0,1738 # 80008490 <states.0+0x1a0>
    80002dce:	ffffd097          	auipc	ra,0xffffd
    80002dd2:	7ba080e7          	jalr	1978(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002dd6:	00005517          	auipc	a0,0x5
    80002dda:	6d250513          	addi	a0,a0,1746 # 800084a8 <states.0+0x1b8>
    80002dde:	ffffd097          	auipc	ra,0xffffd
    80002de2:	760080e7          	jalr	1888(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002de6:	fffff097          	auipc	ra,0xfffff
    80002dea:	d12080e7          	jalr	-750(ra) # 80001af8 <myproc>
    80002dee:	d541                	beqz	a0,80002d76 <kerneltrap+0x38>
    80002df0:	fffff097          	auipc	ra,0xfffff
    80002df4:	d08080e7          	jalr	-760(ra) # 80001af8 <myproc>
    80002df8:	4d18                	lw	a4,24(a0)
    80002dfa:	4791                	li	a5,4
    80002dfc:	f6f71de3          	bne	a4,a5,80002d76 <kerneltrap+0x38>
    yield();
    80002e00:	fffff097          	auipc	ra,0xfffff
    80002e04:	3f8080e7          	jalr	1016(ra) # 800021f8 <yield>
    80002e08:	b7bd                	j	80002d76 <kerneltrap+0x38>

0000000080002e0a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002e0a:	1101                	addi	sp,sp,-32
    80002e0c:	ec06                	sd	ra,24(sp)
    80002e0e:	e822                	sd	s0,16(sp)
    80002e10:	e426                	sd	s1,8(sp)
    80002e12:	1000                	addi	s0,sp,32
    80002e14:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002e16:	fffff097          	auipc	ra,0xfffff
    80002e1a:	ce2080e7          	jalr	-798(ra) # 80001af8 <myproc>
  switch (n) {
    80002e1e:	4795                	li	a5,5
    80002e20:	0497e163          	bltu	a5,s1,80002e62 <argraw+0x58>
    80002e24:	048a                	slli	s1,s1,0x2
    80002e26:	00005717          	auipc	a4,0x5
    80002e2a:	6ba70713          	addi	a4,a4,1722 # 800084e0 <states.0+0x1f0>
    80002e2e:	94ba                	add	s1,s1,a4
    80002e30:	409c                	lw	a5,0(s1)
    80002e32:	97ba                	add	a5,a5,a4
    80002e34:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002e36:	6d3c                	ld	a5,88(a0)
    80002e38:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002e3a:	60e2                	ld	ra,24(sp)
    80002e3c:	6442                	ld	s0,16(sp)
    80002e3e:	64a2                	ld	s1,8(sp)
    80002e40:	6105                	addi	sp,sp,32
    80002e42:	8082                	ret
    return p->trapframe->a1;
    80002e44:	6d3c                	ld	a5,88(a0)
    80002e46:	7fa8                	ld	a0,120(a5)
    80002e48:	bfcd                	j	80002e3a <argraw+0x30>
    return p->trapframe->a2;
    80002e4a:	6d3c                	ld	a5,88(a0)
    80002e4c:	63c8                	ld	a0,128(a5)
    80002e4e:	b7f5                	j	80002e3a <argraw+0x30>
    return p->trapframe->a3;
    80002e50:	6d3c                	ld	a5,88(a0)
    80002e52:	67c8                	ld	a0,136(a5)
    80002e54:	b7dd                	j	80002e3a <argraw+0x30>
    return p->trapframe->a4;
    80002e56:	6d3c                	ld	a5,88(a0)
    80002e58:	6bc8                	ld	a0,144(a5)
    80002e5a:	b7c5                	j	80002e3a <argraw+0x30>
    return p->trapframe->a5;
    80002e5c:	6d3c                	ld	a5,88(a0)
    80002e5e:	6fc8                	ld	a0,152(a5)
    80002e60:	bfe9                	j	80002e3a <argraw+0x30>
  panic("argraw");
    80002e62:	00005517          	auipc	a0,0x5
    80002e66:	65650513          	addi	a0,a0,1622 # 800084b8 <states.0+0x1c8>
    80002e6a:	ffffd097          	auipc	ra,0xffffd
    80002e6e:	6d4080e7          	jalr	1748(ra) # 8000053e <panic>

0000000080002e72 <fetchaddr>:
{
    80002e72:	1101                	addi	sp,sp,-32
    80002e74:	ec06                	sd	ra,24(sp)
    80002e76:	e822                	sd	s0,16(sp)
    80002e78:	e426                	sd	s1,8(sp)
    80002e7a:	e04a                	sd	s2,0(sp)
    80002e7c:	1000                	addi	s0,sp,32
    80002e7e:	84aa                	mv	s1,a0
    80002e80:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002e82:	fffff097          	auipc	ra,0xfffff
    80002e86:	c76080e7          	jalr	-906(ra) # 80001af8 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002e8a:	653c                	ld	a5,72(a0)
    80002e8c:	02f4f863          	bgeu	s1,a5,80002ebc <fetchaddr+0x4a>
    80002e90:	00848713          	addi	a4,s1,8
    80002e94:	02e7e663          	bltu	a5,a4,80002ec0 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002e98:	46a1                	li	a3,8
    80002e9a:	8626                	mv	a2,s1
    80002e9c:	85ca                	mv	a1,s2
    80002e9e:	6928                	ld	a0,80(a0)
    80002ea0:	fffff097          	auipc	ra,0xfffff
    80002ea4:	9a0080e7          	jalr	-1632(ra) # 80001840 <copyin>
    80002ea8:	00a03533          	snez	a0,a0
    80002eac:	40a00533          	neg	a0,a0
}
    80002eb0:	60e2                	ld	ra,24(sp)
    80002eb2:	6442                	ld	s0,16(sp)
    80002eb4:	64a2                	ld	s1,8(sp)
    80002eb6:	6902                	ld	s2,0(sp)
    80002eb8:	6105                	addi	sp,sp,32
    80002eba:	8082                	ret
    return -1;
    80002ebc:	557d                	li	a0,-1
    80002ebe:	bfcd                	j	80002eb0 <fetchaddr+0x3e>
    80002ec0:	557d                	li	a0,-1
    80002ec2:	b7fd                	j	80002eb0 <fetchaddr+0x3e>

0000000080002ec4 <fetchstr>:
{
    80002ec4:	7179                	addi	sp,sp,-48
    80002ec6:	f406                	sd	ra,40(sp)
    80002ec8:	f022                	sd	s0,32(sp)
    80002eca:	ec26                	sd	s1,24(sp)
    80002ecc:	e84a                	sd	s2,16(sp)
    80002ece:	e44e                	sd	s3,8(sp)
    80002ed0:	1800                	addi	s0,sp,48
    80002ed2:	892a                	mv	s2,a0
    80002ed4:	84ae                	mv	s1,a1
    80002ed6:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ed8:	fffff097          	auipc	ra,0xfffff
    80002edc:	c20080e7          	jalr	-992(ra) # 80001af8 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002ee0:	86ce                	mv	a3,s3
    80002ee2:	864a                	mv	a2,s2
    80002ee4:	85a6                	mv	a1,s1
    80002ee6:	6928                	ld	a0,80(a0)
    80002ee8:	fffff097          	auipc	ra,0xfffff
    80002eec:	9e6080e7          	jalr	-1562(ra) # 800018ce <copyinstr>
    80002ef0:	00054e63          	bltz	a0,80002f0c <fetchstr+0x48>
  return strlen(buf);
    80002ef4:	8526                	mv	a0,s1
    80002ef6:	ffffe097          	auipc	ra,0xffffe
    80002efa:	f58080e7          	jalr	-168(ra) # 80000e4e <strlen>
}
    80002efe:	70a2                	ld	ra,40(sp)
    80002f00:	7402                	ld	s0,32(sp)
    80002f02:	64e2                	ld	s1,24(sp)
    80002f04:	6942                	ld	s2,16(sp)
    80002f06:	69a2                	ld	s3,8(sp)
    80002f08:	6145                	addi	sp,sp,48
    80002f0a:	8082                	ret
    return -1;
    80002f0c:	557d                	li	a0,-1
    80002f0e:	bfc5                	j	80002efe <fetchstr+0x3a>

0000000080002f10 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002f10:	1101                	addi	sp,sp,-32
    80002f12:	ec06                	sd	ra,24(sp)
    80002f14:	e822                	sd	s0,16(sp)
    80002f16:	e426                	sd	s1,8(sp)
    80002f18:	1000                	addi	s0,sp,32
    80002f1a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f1c:	00000097          	auipc	ra,0x0
    80002f20:	eee080e7          	jalr	-274(ra) # 80002e0a <argraw>
    80002f24:	c088                	sw	a0,0(s1)
}
    80002f26:	60e2                	ld	ra,24(sp)
    80002f28:	6442                	ld	s0,16(sp)
    80002f2a:	64a2                	ld	s1,8(sp)
    80002f2c:	6105                	addi	sp,sp,32
    80002f2e:	8082                	ret

0000000080002f30 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002f30:	1101                	addi	sp,sp,-32
    80002f32:	ec06                	sd	ra,24(sp)
    80002f34:	e822                	sd	s0,16(sp)
    80002f36:	e426                	sd	s1,8(sp)
    80002f38:	1000                	addi	s0,sp,32
    80002f3a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f3c:	00000097          	auipc	ra,0x0
    80002f40:	ece080e7          	jalr	-306(ra) # 80002e0a <argraw>
    80002f44:	e088                	sd	a0,0(s1)
}
    80002f46:	60e2                	ld	ra,24(sp)
    80002f48:	6442                	ld	s0,16(sp)
    80002f4a:	64a2                	ld	s1,8(sp)
    80002f4c:	6105                	addi	sp,sp,32
    80002f4e:	8082                	ret

0000000080002f50 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002f50:	7179                	addi	sp,sp,-48
    80002f52:	f406                	sd	ra,40(sp)
    80002f54:	f022                	sd	s0,32(sp)
    80002f56:	ec26                	sd	s1,24(sp)
    80002f58:	e84a                	sd	s2,16(sp)
    80002f5a:	1800                	addi	s0,sp,48
    80002f5c:	84ae                	mv	s1,a1
    80002f5e:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002f60:	fd840593          	addi	a1,s0,-40
    80002f64:	00000097          	auipc	ra,0x0
    80002f68:	fcc080e7          	jalr	-52(ra) # 80002f30 <argaddr>
  return fetchstr(addr, buf, max);
    80002f6c:	864a                	mv	a2,s2
    80002f6e:	85a6                	mv	a1,s1
    80002f70:	fd843503          	ld	a0,-40(s0)
    80002f74:	00000097          	auipc	ra,0x0
    80002f78:	f50080e7          	jalr	-176(ra) # 80002ec4 <fetchstr>
}
    80002f7c:	70a2                	ld	ra,40(sp)
    80002f7e:	7402                	ld	s0,32(sp)
    80002f80:	64e2                	ld	s1,24(sp)
    80002f82:	6942                	ld	s2,16(sp)
    80002f84:	6145                	addi	sp,sp,48
    80002f86:	8082                	ret

0000000080002f88 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002f88:	1101                	addi	sp,sp,-32
    80002f8a:	ec06                	sd	ra,24(sp)
    80002f8c:	e822                	sd	s0,16(sp)
    80002f8e:	e426                	sd	s1,8(sp)
    80002f90:	e04a                	sd	s2,0(sp)
    80002f92:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002f94:	fffff097          	auipc	ra,0xfffff
    80002f98:	b64080e7          	jalr	-1180(ra) # 80001af8 <myproc>
    80002f9c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002f9e:	05853903          	ld	s2,88(a0)
    80002fa2:	0a893783          	ld	a5,168(s2)
    80002fa6:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002faa:	37fd                	addiw	a5,a5,-1
    80002fac:	4751                	li	a4,20
    80002fae:	00f76f63          	bltu	a4,a5,80002fcc <syscall+0x44>
    80002fb2:	00369713          	slli	a4,a3,0x3
    80002fb6:	00005797          	auipc	a5,0x5
    80002fba:	54278793          	addi	a5,a5,1346 # 800084f8 <syscalls>
    80002fbe:	97ba                	add	a5,a5,a4
    80002fc0:	639c                	ld	a5,0(a5)
    80002fc2:	c789                	beqz	a5,80002fcc <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002fc4:	9782                	jalr	a5
    80002fc6:	06a93823          	sd	a0,112(s2)
    80002fca:	a839                	j	80002fe8 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002fcc:	15848613          	addi	a2,s1,344
    80002fd0:	588c                	lw	a1,48(s1)
    80002fd2:	00005517          	auipc	a0,0x5
    80002fd6:	4ee50513          	addi	a0,a0,1262 # 800084c0 <states.0+0x1d0>
    80002fda:	ffffd097          	auipc	ra,0xffffd
    80002fde:	5ae080e7          	jalr	1454(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002fe2:	6cbc                	ld	a5,88(s1)
    80002fe4:	577d                	li	a4,-1
    80002fe6:	fbb8                	sd	a4,112(a5)
  }
}
    80002fe8:	60e2                	ld	ra,24(sp)
    80002fea:	6442                	ld	s0,16(sp)
    80002fec:	64a2                	ld	s1,8(sp)
    80002fee:	6902                	ld	s2,0(sp)
    80002ff0:	6105                	addi	sp,sp,32
    80002ff2:	8082                	ret

0000000080002ff4 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ff4:	1101                	addi	sp,sp,-32
    80002ff6:	ec06                	sd	ra,24(sp)
    80002ff8:	e822                	sd	s0,16(sp)
    80002ffa:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002ffc:	fec40593          	addi	a1,s0,-20
    80003000:	4501                	li	a0,0
    80003002:	00000097          	auipc	ra,0x0
    80003006:	f0e080e7          	jalr	-242(ra) # 80002f10 <argint>
  exit(n);
    8000300a:	fec42503          	lw	a0,-20(s0)
    8000300e:	fffff097          	auipc	ra,0xfffff
    80003012:	35a080e7          	jalr	858(ra) # 80002368 <exit>
  return 0;  // not reached
}
    80003016:	4501                	li	a0,0
    80003018:	60e2                	ld	ra,24(sp)
    8000301a:	6442                	ld	s0,16(sp)
    8000301c:	6105                	addi	sp,sp,32
    8000301e:	8082                	ret

0000000080003020 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003020:	1141                	addi	sp,sp,-16
    80003022:	e406                	sd	ra,8(sp)
    80003024:	e022                	sd	s0,0(sp)
    80003026:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003028:	fffff097          	auipc	ra,0xfffff
    8000302c:	ad0080e7          	jalr	-1328(ra) # 80001af8 <myproc>
}
    80003030:	5908                	lw	a0,48(a0)
    80003032:	60a2                	ld	ra,8(sp)
    80003034:	6402                	ld	s0,0(sp)
    80003036:	0141                	addi	sp,sp,16
    80003038:	8082                	ret

000000008000303a <sys_fork>:

uint64
sys_fork(void)
{
    8000303a:	1141                	addi	sp,sp,-16
    8000303c:	e406                	sd	ra,8(sp)
    8000303e:	e022                	sd	s0,0(sp)
    80003040:	0800                	addi	s0,sp,16
  return fork();
    80003042:	fffff097          	auipc	ra,0xfffff
    80003046:	e74080e7          	jalr	-396(ra) # 80001eb6 <fork>
}
    8000304a:	60a2                	ld	ra,8(sp)
    8000304c:	6402                	ld	s0,0(sp)
    8000304e:	0141                	addi	sp,sp,16
    80003050:	8082                	ret

0000000080003052 <sys_wait>:

uint64
sys_wait(void)
{
    80003052:	1101                	addi	sp,sp,-32
    80003054:	ec06                	sd	ra,24(sp)
    80003056:	e822                	sd	s0,16(sp)
    80003058:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    8000305a:	fe840593          	addi	a1,s0,-24
    8000305e:	4501                	li	a0,0
    80003060:	00000097          	auipc	ra,0x0
    80003064:	ed0080e7          	jalr	-304(ra) # 80002f30 <argaddr>
  return wait(p);
    80003068:	fe843503          	ld	a0,-24(s0)
    8000306c:	fffff097          	auipc	ra,0xfffff
    80003070:	4b8080e7          	jalr	1208(ra) # 80002524 <wait>
}
    80003074:	60e2                	ld	ra,24(sp)
    80003076:	6442                	ld	s0,16(sp)
    80003078:	6105                	addi	sp,sp,32
    8000307a:	8082                	ret

000000008000307c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000307c:	7179                	addi	sp,sp,-48
    8000307e:	f406                	sd	ra,40(sp)
    80003080:	f022                	sd	s0,32(sp)
    80003082:	ec26                	sd	s1,24(sp)
    80003084:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003086:	fdc40593          	addi	a1,s0,-36
    8000308a:	4501                	li	a0,0
    8000308c:	00000097          	auipc	ra,0x0
    80003090:	e84080e7          	jalr	-380(ra) # 80002f10 <argint>
  addr = myproc()->sz;
    80003094:	fffff097          	auipc	ra,0xfffff
    80003098:	a64080e7          	jalr	-1436(ra) # 80001af8 <myproc>
    8000309c:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    8000309e:	fdc42503          	lw	a0,-36(s0)
    800030a2:	fffff097          	auipc	ra,0xfffff
    800030a6:	db8080e7          	jalr	-584(ra) # 80001e5a <growproc>
    800030aa:	00054863          	bltz	a0,800030ba <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800030ae:	8526                	mv	a0,s1
    800030b0:	70a2                	ld	ra,40(sp)
    800030b2:	7402                	ld	s0,32(sp)
    800030b4:	64e2                	ld	s1,24(sp)
    800030b6:	6145                	addi	sp,sp,48
    800030b8:	8082                	ret
    return -1;
    800030ba:	54fd                	li	s1,-1
    800030bc:	bfcd                	j	800030ae <sys_sbrk+0x32>

00000000800030be <sys_sleep>:

uint64
sys_sleep(void)
{
    800030be:	7139                	addi	sp,sp,-64
    800030c0:	fc06                	sd	ra,56(sp)
    800030c2:	f822                	sd	s0,48(sp)
    800030c4:	f426                	sd	s1,40(sp)
    800030c6:	f04a                	sd	s2,32(sp)
    800030c8:	ec4e                	sd	s3,24(sp)
    800030ca:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800030cc:	fcc40593          	addi	a1,s0,-52
    800030d0:	4501                	li	a0,0
    800030d2:	00000097          	auipc	ra,0x0
    800030d6:	e3e080e7          	jalr	-450(ra) # 80002f10 <argint>
  acquire(&tickslock);
    800030da:	00020517          	auipc	a0,0x20
    800030de:	f8650513          	addi	a0,a0,-122 # 80023060 <tickslock>
    800030e2:	ffffe097          	auipc	ra,0xffffe
    800030e6:	af4080e7          	jalr	-1292(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    800030ea:	00006917          	auipc	s2,0x6
    800030ee:	8d692903          	lw	s2,-1834(s2) # 800089c0 <ticks>
  while(ticks - ticks0 < n){
    800030f2:	fcc42783          	lw	a5,-52(s0)
    800030f6:	cf9d                	beqz	a5,80003134 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800030f8:	00020997          	auipc	s3,0x20
    800030fc:	f6898993          	addi	s3,s3,-152 # 80023060 <tickslock>
    80003100:	00006497          	auipc	s1,0x6
    80003104:	8c048493          	addi	s1,s1,-1856 # 800089c0 <ticks>
    if(killed(myproc())){
    80003108:	fffff097          	auipc	ra,0xfffff
    8000310c:	9f0080e7          	jalr	-1552(ra) # 80001af8 <myproc>
    80003110:	fffff097          	auipc	ra,0xfffff
    80003114:	3e2080e7          	jalr	994(ra) # 800024f2 <killed>
    80003118:	ed15                	bnez	a0,80003154 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    8000311a:	85ce                	mv	a1,s3
    8000311c:	8526                	mv	a0,s1
    8000311e:	fffff097          	auipc	ra,0xfffff
    80003122:	116080e7          	jalr	278(ra) # 80002234 <sleep>
  while(ticks - ticks0 < n){
    80003126:	409c                	lw	a5,0(s1)
    80003128:	412787bb          	subw	a5,a5,s2
    8000312c:	fcc42703          	lw	a4,-52(s0)
    80003130:	fce7ece3          	bltu	a5,a4,80003108 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003134:	00020517          	auipc	a0,0x20
    80003138:	f2c50513          	addi	a0,a0,-212 # 80023060 <tickslock>
    8000313c:	ffffe097          	auipc	ra,0xffffe
    80003140:	b4e080e7          	jalr	-1202(ra) # 80000c8a <release>
  return 0;
    80003144:	4501                	li	a0,0
}
    80003146:	70e2                	ld	ra,56(sp)
    80003148:	7442                	ld	s0,48(sp)
    8000314a:	74a2                	ld	s1,40(sp)
    8000314c:	7902                	ld	s2,32(sp)
    8000314e:	69e2                	ld	s3,24(sp)
    80003150:	6121                	addi	sp,sp,64
    80003152:	8082                	ret
      release(&tickslock);
    80003154:	00020517          	auipc	a0,0x20
    80003158:	f0c50513          	addi	a0,a0,-244 # 80023060 <tickslock>
    8000315c:	ffffe097          	auipc	ra,0xffffe
    80003160:	b2e080e7          	jalr	-1234(ra) # 80000c8a <release>
      return -1;
    80003164:	557d                	li	a0,-1
    80003166:	b7c5                	j	80003146 <sys_sleep+0x88>

0000000080003168 <sys_kill>:

uint64
sys_kill(void)
{
    80003168:	1101                	addi	sp,sp,-32
    8000316a:	ec06                	sd	ra,24(sp)
    8000316c:	e822                	sd	s0,16(sp)
    8000316e:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003170:	fec40593          	addi	a1,s0,-20
    80003174:	4501                	li	a0,0
    80003176:	00000097          	auipc	ra,0x0
    8000317a:	d9a080e7          	jalr	-614(ra) # 80002f10 <argint>
  return kill(pid);
    8000317e:	fec42503          	lw	a0,-20(s0)
    80003182:	fffff097          	auipc	ra,0xfffff
    80003186:	2d2080e7          	jalr	722(ra) # 80002454 <kill>
}
    8000318a:	60e2                	ld	ra,24(sp)
    8000318c:	6442                	ld	s0,16(sp)
    8000318e:	6105                	addi	sp,sp,32
    80003190:	8082                	ret

0000000080003192 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003192:	1101                	addi	sp,sp,-32
    80003194:	ec06                	sd	ra,24(sp)
    80003196:	e822                	sd	s0,16(sp)
    80003198:	e426                	sd	s1,8(sp)
    8000319a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000319c:	00020517          	auipc	a0,0x20
    800031a0:	ec450513          	addi	a0,a0,-316 # 80023060 <tickslock>
    800031a4:	ffffe097          	auipc	ra,0xffffe
    800031a8:	a32080e7          	jalr	-1486(ra) # 80000bd6 <acquire>
  xticks = ticks;
    800031ac:	00006497          	auipc	s1,0x6
    800031b0:	8144a483          	lw	s1,-2028(s1) # 800089c0 <ticks>
  release(&tickslock);
    800031b4:	00020517          	auipc	a0,0x20
    800031b8:	eac50513          	addi	a0,a0,-340 # 80023060 <tickslock>
    800031bc:	ffffe097          	auipc	ra,0xffffe
    800031c0:	ace080e7          	jalr	-1330(ra) # 80000c8a <release>
  return xticks;
}
    800031c4:	02049513          	slli	a0,s1,0x20
    800031c8:	9101                	srli	a0,a0,0x20
    800031ca:	60e2                	ld	ra,24(sp)
    800031cc:	6442                	ld	s0,16(sp)
    800031ce:	64a2                	ld	s1,8(sp)
    800031d0:	6105                	addi	sp,sp,32
    800031d2:	8082                	ret

00000000800031d4 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800031d4:	7179                	addi	sp,sp,-48
    800031d6:	f406                	sd	ra,40(sp)
    800031d8:	f022                	sd	s0,32(sp)
    800031da:	ec26                	sd	s1,24(sp)
    800031dc:	e84a                	sd	s2,16(sp)
    800031de:	e44e                	sd	s3,8(sp)
    800031e0:	e052                	sd	s4,0(sp)
    800031e2:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800031e4:	00005597          	auipc	a1,0x5
    800031e8:	3c458593          	addi	a1,a1,964 # 800085a8 <syscalls+0xb0>
    800031ec:	00020517          	auipc	a0,0x20
    800031f0:	e8c50513          	addi	a0,a0,-372 # 80023078 <bcache>
    800031f4:	ffffe097          	auipc	ra,0xffffe
    800031f8:	952080e7          	jalr	-1710(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800031fc:	00028797          	auipc	a5,0x28
    80003200:	e7c78793          	addi	a5,a5,-388 # 8002b078 <bcache+0x8000>
    80003204:	00028717          	auipc	a4,0x28
    80003208:	0dc70713          	addi	a4,a4,220 # 8002b2e0 <bcache+0x8268>
    8000320c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003210:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003214:	00020497          	auipc	s1,0x20
    80003218:	e7c48493          	addi	s1,s1,-388 # 80023090 <bcache+0x18>
    b->next = bcache.head.next;
    8000321c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000321e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003220:	00005a17          	auipc	s4,0x5
    80003224:	390a0a13          	addi	s4,s4,912 # 800085b0 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003228:	2b893783          	ld	a5,696(s2)
    8000322c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000322e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003232:	85d2                	mv	a1,s4
    80003234:	01048513          	addi	a0,s1,16
    80003238:	00001097          	auipc	ra,0x1
    8000323c:	7d6080e7          	jalr	2006(ra) # 80004a0e <initsleeplock>
    bcache.head.next->prev = b;
    80003240:	2b893783          	ld	a5,696(s2)
    80003244:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003246:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000324a:	45848493          	addi	s1,s1,1112
    8000324e:	fd349de3          	bne	s1,s3,80003228 <binit+0x54>
  }
}
    80003252:	70a2                	ld	ra,40(sp)
    80003254:	7402                	ld	s0,32(sp)
    80003256:	64e2                	ld	s1,24(sp)
    80003258:	6942                	ld	s2,16(sp)
    8000325a:	69a2                	ld	s3,8(sp)
    8000325c:	6a02                	ld	s4,0(sp)
    8000325e:	6145                	addi	sp,sp,48
    80003260:	8082                	ret

0000000080003262 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003262:	7179                	addi	sp,sp,-48
    80003264:	f406                	sd	ra,40(sp)
    80003266:	f022                	sd	s0,32(sp)
    80003268:	ec26                	sd	s1,24(sp)
    8000326a:	e84a                	sd	s2,16(sp)
    8000326c:	e44e                	sd	s3,8(sp)
    8000326e:	1800                	addi	s0,sp,48
    80003270:	892a                	mv	s2,a0
    80003272:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003274:	00020517          	auipc	a0,0x20
    80003278:	e0450513          	addi	a0,a0,-508 # 80023078 <bcache>
    8000327c:	ffffe097          	auipc	ra,0xffffe
    80003280:	95a080e7          	jalr	-1702(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003284:	00028497          	auipc	s1,0x28
    80003288:	0ac4b483          	ld	s1,172(s1) # 8002b330 <bcache+0x82b8>
    8000328c:	00028797          	auipc	a5,0x28
    80003290:	05478793          	addi	a5,a5,84 # 8002b2e0 <bcache+0x8268>
    80003294:	02f48f63          	beq	s1,a5,800032d2 <bread+0x70>
    80003298:	873e                	mv	a4,a5
    8000329a:	a021                	j	800032a2 <bread+0x40>
    8000329c:	68a4                	ld	s1,80(s1)
    8000329e:	02e48a63          	beq	s1,a4,800032d2 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800032a2:	449c                	lw	a5,8(s1)
    800032a4:	ff279ce3          	bne	a5,s2,8000329c <bread+0x3a>
    800032a8:	44dc                	lw	a5,12(s1)
    800032aa:	ff3799e3          	bne	a5,s3,8000329c <bread+0x3a>
      b->refcnt++;
    800032ae:	40bc                	lw	a5,64(s1)
    800032b0:	2785                	addiw	a5,a5,1
    800032b2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800032b4:	00020517          	auipc	a0,0x20
    800032b8:	dc450513          	addi	a0,a0,-572 # 80023078 <bcache>
    800032bc:	ffffe097          	auipc	ra,0xffffe
    800032c0:	9ce080e7          	jalr	-1586(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800032c4:	01048513          	addi	a0,s1,16
    800032c8:	00001097          	auipc	ra,0x1
    800032cc:	780080e7          	jalr	1920(ra) # 80004a48 <acquiresleep>
      return b;
    800032d0:	a8b9                	j	8000332e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032d2:	00028497          	auipc	s1,0x28
    800032d6:	0564b483          	ld	s1,86(s1) # 8002b328 <bcache+0x82b0>
    800032da:	00028797          	auipc	a5,0x28
    800032de:	00678793          	addi	a5,a5,6 # 8002b2e0 <bcache+0x8268>
    800032e2:	00f48863          	beq	s1,a5,800032f2 <bread+0x90>
    800032e6:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800032e8:	40bc                	lw	a5,64(s1)
    800032ea:	cf81                	beqz	a5,80003302 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032ec:	64a4                	ld	s1,72(s1)
    800032ee:	fee49de3          	bne	s1,a4,800032e8 <bread+0x86>
  panic("bget: no buffers");
    800032f2:	00005517          	auipc	a0,0x5
    800032f6:	2c650513          	addi	a0,a0,710 # 800085b8 <syscalls+0xc0>
    800032fa:	ffffd097          	auipc	ra,0xffffd
    800032fe:	244080e7          	jalr	580(ra) # 8000053e <panic>
      b->dev = dev;
    80003302:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003306:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000330a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000330e:	4785                	li	a5,1
    80003310:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003312:	00020517          	auipc	a0,0x20
    80003316:	d6650513          	addi	a0,a0,-666 # 80023078 <bcache>
    8000331a:	ffffe097          	auipc	ra,0xffffe
    8000331e:	970080e7          	jalr	-1680(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003322:	01048513          	addi	a0,s1,16
    80003326:	00001097          	auipc	ra,0x1
    8000332a:	722080e7          	jalr	1826(ra) # 80004a48 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000332e:	409c                	lw	a5,0(s1)
    80003330:	cb89                	beqz	a5,80003342 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003332:	8526                	mv	a0,s1
    80003334:	70a2                	ld	ra,40(sp)
    80003336:	7402                	ld	s0,32(sp)
    80003338:	64e2                	ld	s1,24(sp)
    8000333a:	6942                	ld	s2,16(sp)
    8000333c:	69a2                	ld	s3,8(sp)
    8000333e:	6145                	addi	sp,sp,48
    80003340:	8082                	ret
    virtio_disk_rw(b, 0);
    80003342:	4581                	li	a1,0
    80003344:	8526                	mv	a0,s1
    80003346:	00003097          	auipc	ra,0x3
    8000334a:	54e080e7          	jalr	1358(ra) # 80006894 <virtio_disk_rw>
    b->valid = 1;
    8000334e:	4785                	li	a5,1
    80003350:	c09c                	sw	a5,0(s1)
  return b;
    80003352:	b7c5                	j	80003332 <bread+0xd0>

0000000080003354 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003354:	1101                	addi	sp,sp,-32
    80003356:	ec06                	sd	ra,24(sp)
    80003358:	e822                	sd	s0,16(sp)
    8000335a:	e426                	sd	s1,8(sp)
    8000335c:	1000                	addi	s0,sp,32
    8000335e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003360:	0541                	addi	a0,a0,16
    80003362:	00001097          	auipc	ra,0x1
    80003366:	780080e7          	jalr	1920(ra) # 80004ae2 <holdingsleep>
    8000336a:	cd01                	beqz	a0,80003382 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000336c:	4585                	li	a1,1
    8000336e:	8526                	mv	a0,s1
    80003370:	00003097          	auipc	ra,0x3
    80003374:	524080e7          	jalr	1316(ra) # 80006894 <virtio_disk_rw>
}
    80003378:	60e2                	ld	ra,24(sp)
    8000337a:	6442                	ld	s0,16(sp)
    8000337c:	64a2                	ld	s1,8(sp)
    8000337e:	6105                	addi	sp,sp,32
    80003380:	8082                	ret
    panic("bwrite");
    80003382:	00005517          	auipc	a0,0x5
    80003386:	24e50513          	addi	a0,a0,590 # 800085d0 <syscalls+0xd8>
    8000338a:	ffffd097          	auipc	ra,0xffffd
    8000338e:	1b4080e7          	jalr	436(ra) # 8000053e <panic>

0000000080003392 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003392:	1101                	addi	sp,sp,-32
    80003394:	ec06                	sd	ra,24(sp)
    80003396:	e822                	sd	s0,16(sp)
    80003398:	e426                	sd	s1,8(sp)
    8000339a:	e04a                	sd	s2,0(sp)
    8000339c:	1000                	addi	s0,sp,32
    8000339e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800033a0:	01050913          	addi	s2,a0,16
    800033a4:	854a                	mv	a0,s2
    800033a6:	00001097          	auipc	ra,0x1
    800033aa:	73c080e7          	jalr	1852(ra) # 80004ae2 <holdingsleep>
    800033ae:	c92d                	beqz	a0,80003420 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800033b0:	854a                	mv	a0,s2
    800033b2:	00001097          	auipc	ra,0x1
    800033b6:	6ec080e7          	jalr	1772(ra) # 80004a9e <releasesleep>

  acquire(&bcache.lock);
    800033ba:	00020517          	auipc	a0,0x20
    800033be:	cbe50513          	addi	a0,a0,-834 # 80023078 <bcache>
    800033c2:	ffffe097          	auipc	ra,0xffffe
    800033c6:	814080e7          	jalr	-2028(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800033ca:	40bc                	lw	a5,64(s1)
    800033cc:	37fd                	addiw	a5,a5,-1
    800033ce:	0007871b          	sext.w	a4,a5
    800033d2:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800033d4:	eb05                	bnez	a4,80003404 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800033d6:	68bc                	ld	a5,80(s1)
    800033d8:	64b8                	ld	a4,72(s1)
    800033da:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800033dc:	64bc                	ld	a5,72(s1)
    800033de:	68b8                	ld	a4,80(s1)
    800033e0:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800033e2:	00028797          	auipc	a5,0x28
    800033e6:	c9678793          	addi	a5,a5,-874 # 8002b078 <bcache+0x8000>
    800033ea:	2b87b703          	ld	a4,696(a5)
    800033ee:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800033f0:	00028717          	auipc	a4,0x28
    800033f4:	ef070713          	addi	a4,a4,-272 # 8002b2e0 <bcache+0x8268>
    800033f8:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800033fa:	2b87b703          	ld	a4,696(a5)
    800033fe:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003400:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003404:	00020517          	auipc	a0,0x20
    80003408:	c7450513          	addi	a0,a0,-908 # 80023078 <bcache>
    8000340c:	ffffe097          	auipc	ra,0xffffe
    80003410:	87e080e7          	jalr	-1922(ra) # 80000c8a <release>
}
    80003414:	60e2                	ld	ra,24(sp)
    80003416:	6442                	ld	s0,16(sp)
    80003418:	64a2                	ld	s1,8(sp)
    8000341a:	6902                	ld	s2,0(sp)
    8000341c:	6105                	addi	sp,sp,32
    8000341e:	8082                	ret
    panic("brelse");
    80003420:	00005517          	auipc	a0,0x5
    80003424:	1b850513          	addi	a0,a0,440 # 800085d8 <syscalls+0xe0>
    80003428:	ffffd097          	auipc	ra,0xffffd
    8000342c:	116080e7          	jalr	278(ra) # 8000053e <panic>

0000000080003430 <bpin>:

void
bpin(struct buf *b) {
    80003430:	1101                	addi	sp,sp,-32
    80003432:	ec06                	sd	ra,24(sp)
    80003434:	e822                	sd	s0,16(sp)
    80003436:	e426                	sd	s1,8(sp)
    80003438:	1000                	addi	s0,sp,32
    8000343a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000343c:	00020517          	auipc	a0,0x20
    80003440:	c3c50513          	addi	a0,a0,-964 # 80023078 <bcache>
    80003444:	ffffd097          	auipc	ra,0xffffd
    80003448:	792080e7          	jalr	1938(ra) # 80000bd6 <acquire>
  b->refcnt++;
    8000344c:	40bc                	lw	a5,64(s1)
    8000344e:	2785                	addiw	a5,a5,1
    80003450:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003452:	00020517          	auipc	a0,0x20
    80003456:	c2650513          	addi	a0,a0,-986 # 80023078 <bcache>
    8000345a:	ffffe097          	auipc	ra,0xffffe
    8000345e:	830080e7          	jalr	-2000(ra) # 80000c8a <release>
}
    80003462:	60e2                	ld	ra,24(sp)
    80003464:	6442                	ld	s0,16(sp)
    80003466:	64a2                	ld	s1,8(sp)
    80003468:	6105                	addi	sp,sp,32
    8000346a:	8082                	ret

000000008000346c <bunpin>:

void
bunpin(struct buf *b) {
    8000346c:	1101                	addi	sp,sp,-32
    8000346e:	ec06                	sd	ra,24(sp)
    80003470:	e822                	sd	s0,16(sp)
    80003472:	e426                	sd	s1,8(sp)
    80003474:	1000                	addi	s0,sp,32
    80003476:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003478:	00020517          	auipc	a0,0x20
    8000347c:	c0050513          	addi	a0,a0,-1024 # 80023078 <bcache>
    80003480:	ffffd097          	auipc	ra,0xffffd
    80003484:	756080e7          	jalr	1878(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003488:	40bc                	lw	a5,64(s1)
    8000348a:	37fd                	addiw	a5,a5,-1
    8000348c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000348e:	00020517          	auipc	a0,0x20
    80003492:	bea50513          	addi	a0,a0,-1046 # 80023078 <bcache>
    80003496:	ffffd097          	auipc	ra,0xffffd
    8000349a:	7f4080e7          	jalr	2036(ra) # 80000c8a <release>
}
    8000349e:	60e2                	ld	ra,24(sp)
    800034a0:	6442                	ld	s0,16(sp)
    800034a2:	64a2                	ld	s1,8(sp)
    800034a4:	6105                	addi	sp,sp,32
    800034a6:	8082                	ret

00000000800034a8 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800034a8:	1101                	addi	sp,sp,-32
    800034aa:	ec06                	sd	ra,24(sp)
    800034ac:	e822                	sd	s0,16(sp)
    800034ae:	e426                	sd	s1,8(sp)
    800034b0:	e04a                	sd	s2,0(sp)
    800034b2:	1000                	addi	s0,sp,32
    800034b4:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800034b6:	00d5d59b          	srliw	a1,a1,0xd
    800034ba:	00028797          	auipc	a5,0x28
    800034be:	29a7a783          	lw	a5,666(a5) # 8002b754 <sb+0x1c>
    800034c2:	9dbd                	addw	a1,a1,a5
    800034c4:	00000097          	auipc	ra,0x0
    800034c8:	d9e080e7          	jalr	-610(ra) # 80003262 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800034cc:	0074f713          	andi	a4,s1,7
    800034d0:	4785                	li	a5,1
    800034d2:	00e797bb          	sllw	a5,a5,a4
  if ((bp->data[bi / 8] & m) == 0)
    800034d6:	14ce                	slli	s1,s1,0x33
    800034d8:	90d9                	srli	s1,s1,0x36
    800034da:	00950733          	add	a4,a0,s1
    800034de:	05874703          	lbu	a4,88(a4)
    800034e2:	00e7f6b3          	and	a3,a5,a4
    800034e6:	c69d                	beqz	a3,80003514 <bfree+0x6c>
    800034e8:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi / 8] &= ~m;
    800034ea:	94aa                	add	s1,s1,a0
    800034ec:	fff7c793          	not	a5,a5
    800034f0:	8ff9                	and	a5,a5,a4
    800034f2:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800034f6:	00001097          	auipc	ra,0x1
    800034fa:	432080e7          	jalr	1074(ra) # 80004928 <log_write>
  brelse(bp);
    800034fe:	854a                	mv	a0,s2
    80003500:	00000097          	auipc	ra,0x0
    80003504:	e92080e7          	jalr	-366(ra) # 80003392 <brelse>
}
    80003508:	60e2                	ld	ra,24(sp)
    8000350a:	6442                	ld	s0,16(sp)
    8000350c:	64a2                	ld	s1,8(sp)
    8000350e:	6902                	ld	s2,0(sp)
    80003510:	6105                	addi	sp,sp,32
    80003512:	8082                	ret
    panic("freeing free block");
    80003514:	00005517          	auipc	a0,0x5
    80003518:	0cc50513          	addi	a0,a0,204 # 800085e0 <syscalls+0xe8>
    8000351c:	ffffd097          	auipc	ra,0xffffd
    80003520:	022080e7          	jalr	34(ra) # 8000053e <panic>

0000000080003524 <balloc>:
{
    80003524:	711d                	addi	sp,sp,-96
    80003526:	ec86                	sd	ra,88(sp)
    80003528:	e8a2                	sd	s0,80(sp)
    8000352a:	e4a6                	sd	s1,72(sp)
    8000352c:	e0ca                	sd	s2,64(sp)
    8000352e:	fc4e                	sd	s3,56(sp)
    80003530:	f852                	sd	s4,48(sp)
    80003532:	f456                	sd	s5,40(sp)
    80003534:	f05a                	sd	s6,32(sp)
    80003536:	ec5e                	sd	s7,24(sp)
    80003538:	e862                	sd	s8,16(sp)
    8000353a:	e466                	sd	s9,8(sp)
    8000353c:	1080                	addi	s0,sp,96
  for (b = 0; b < sb.size; b += BPB)
    8000353e:	00028797          	auipc	a5,0x28
    80003542:	1fe7a783          	lw	a5,510(a5) # 8002b73c <sb+0x4>
    80003546:	10078163          	beqz	a5,80003648 <balloc+0x124>
    8000354a:	8baa                	mv	s7,a0
    8000354c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000354e:	00028b17          	auipc	s6,0x28
    80003552:	1eab0b13          	addi	s6,s6,490 # 8002b738 <sb>
    for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    80003556:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003558:	4985                	li	s3,1
    for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    8000355a:	6a09                	lui	s4,0x2
  for (b = 0; b < sb.size; b += BPB)
    8000355c:	6c89                	lui	s9,0x2
    8000355e:	a061                	j	800035e6 <balloc+0xc2>
        bp->data[bi / 8] |= m; // Mark block in use.
    80003560:	974a                	add	a4,a4,s2
    80003562:	8fd5                	or	a5,a5,a3
    80003564:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003568:	854a                	mv	a0,s2
    8000356a:	00001097          	auipc	ra,0x1
    8000356e:	3be080e7          	jalr	958(ra) # 80004928 <log_write>
        brelse(bp);
    80003572:	854a                	mv	a0,s2
    80003574:	00000097          	auipc	ra,0x0
    80003578:	e1e080e7          	jalr	-482(ra) # 80003392 <brelse>
  bp = bread(dev, bno);
    8000357c:	85a6                	mv	a1,s1
    8000357e:	855e                	mv	a0,s7
    80003580:	00000097          	auipc	ra,0x0
    80003584:	ce2080e7          	jalr	-798(ra) # 80003262 <bread>
    80003588:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000358a:	40000613          	li	a2,1024
    8000358e:	4581                	li	a1,0
    80003590:	05850513          	addi	a0,a0,88
    80003594:	ffffd097          	auipc	ra,0xffffd
    80003598:	73e080e7          	jalr	1854(ra) # 80000cd2 <memset>
  log_write(bp);
    8000359c:	854a                	mv	a0,s2
    8000359e:	00001097          	auipc	ra,0x1
    800035a2:	38a080e7          	jalr	906(ra) # 80004928 <log_write>
  brelse(bp);
    800035a6:	854a                	mv	a0,s2
    800035a8:	00000097          	auipc	ra,0x0
    800035ac:	dea080e7          	jalr	-534(ra) # 80003392 <brelse>
}
    800035b0:	8526                	mv	a0,s1
    800035b2:	60e6                	ld	ra,88(sp)
    800035b4:	6446                	ld	s0,80(sp)
    800035b6:	64a6                	ld	s1,72(sp)
    800035b8:	6906                	ld	s2,64(sp)
    800035ba:	79e2                	ld	s3,56(sp)
    800035bc:	7a42                	ld	s4,48(sp)
    800035be:	7aa2                	ld	s5,40(sp)
    800035c0:	7b02                	ld	s6,32(sp)
    800035c2:	6be2                	ld	s7,24(sp)
    800035c4:	6c42                	ld	s8,16(sp)
    800035c6:	6ca2                	ld	s9,8(sp)
    800035c8:	6125                	addi	sp,sp,96
    800035ca:	8082                	ret
    brelse(bp);
    800035cc:	854a                	mv	a0,s2
    800035ce:	00000097          	auipc	ra,0x0
    800035d2:	dc4080e7          	jalr	-572(ra) # 80003392 <brelse>
  for (b = 0; b < sb.size; b += BPB)
    800035d6:	015c87bb          	addw	a5,s9,s5
    800035da:	00078a9b          	sext.w	s5,a5
    800035de:	004b2703          	lw	a4,4(s6)
    800035e2:	06eaf363          	bgeu	s5,a4,80003648 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800035e6:	41fad79b          	sraiw	a5,s5,0x1f
    800035ea:	0137d79b          	srliw	a5,a5,0x13
    800035ee:	015787bb          	addw	a5,a5,s5
    800035f2:	40d7d79b          	sraiw	a5,a5,0xd
    800035f6:	01cb2583          	lw	a1,28(s6)
    800035fa:	9dbd                	addw	a1,a1,a5
    800035fc:	855e                	mv	a0,s7
    800035fe:	00000097          	auipc	ra,0x0
    80003602:	c64080e7          	jalr	-924(ra) # 80003262 <bread>
    80003606:	892a                	mv	s2,a0
    for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    80003608:	004b2503          	lw	a0,4(s6)
    8000360c:	000a849b          	sext.w	s1,s5
    80003610:	8662                	mv	a2,s8
    80003612:	faa4fde3          	bgeu	s1,a0,800035cc <balloc+0xa8>
      m = 1 << (bi % 8);
    80003616:	41f6579b          	sraiw	a5,a2,0x1f
    8000361a:	01d7d69b          	srliw	a3,a5,0x1d
    8000361e:	00c6873b          	addw	a4,a3,a2
    80003622:	00777793          	andi	a5,a4,7
    80003626:	9f95                	subw	a5,a5,a3
    80003628:	00f997bb          	sllw	a5,s3,a5
      if ((bp->data[bi / 8] & m) == 0)
    8000362c:	4037571b          	sraiw	a4,a4,0x3
    80003630:	00e906b3          	add	a3,s2,a4
    80003634:	0586c683          	lbu	a3,88(a3) # 1058 <_entry-0x7fffefa8>
    80003638:	00d7f5b3          	and	a1,a5,a3
    8000363c:	d195                	beqz	a1,80003560 <balloc+0x3c>
    for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    8000363e:	2605                	addiw	a2,a2,1
    80003640:	2485                	addiw	s1,s1,1
    80003642:	fd4618e3          	bne	a2,s4,80003612 <balloc+0xee>
    80003646:	b759                	j	800035cc <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003648:	00005517          	auipc	a0,0x5
    8000364c:	fb050513          	addi	a0,a0,-80 # 800085f8 <syscalls+0x100>
    80003650:	ffffd097          	auipc	ra,0xffffd
    80003654:	f38080e7          	jalr	-200(ra) # 80000588 <printf>
  return 0;
    80003658:	4481                	li	s1,0
    8000365a:	bf99                	j	800035b0 <balloc+0x8c>

000000008000365c <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000365c:	7179                	addi	sp,sp,-48
    8000365e:	f406                	sd	ra,40(sp)
    80003660:	f022                	sd	s0,32(sp)
    80003662:	ec26                	sd	s1,24(sp)
    80003664:	e84a                	sd	s2,16(sp)
    80003666:	e44e                	sd	s3,8(sp)
    80003668:	e052                	sd	s4,0(sp)
    8000366a:	1800                	addi	s0,sp,48
    8000366c:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if (bn < NDIRECT)
    8000366e:	47ad                	li	a5,11
    80003670:	02b7e763          	bltu	a5,a1,8000369e <bmap+0x42>
  {
    if ((addr = ip->addrs[bn]) == 0)
    80003674:	02059493          	slli	s1,a1,0x20
    80003678:	9081                	srli	s1,s1,0x20
    8000367a:	048a                	slli	s1,s1,0x2
    8000367c:	94aa                	add	s1,s1,a0
    8000367e:	0504a903          	lw	s2,80(s1)
    80003682:	06091e63          	bnez	s2,800036fe <bmap+0xa2>
    {
      addr = balloc(ip->dev);
    80003686:	4108                	lw	a0,0(a0)
    80003688:	00000097          	auipc	ra,0x0
    8000368c:	e9c080e7          	jalr	-356(ra) # 80003524 <balloc>
    80003690:	0005091b          	sext.w	s2,a0
      if (addr == 0)
    80003694:	06090563          	beqz	s2,800036fe <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003698:	0524a823          	sw	s2,80(s1)
    8000369c:	a08d                	j	800036fe <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000369e:	ff45849b          	addiw	s1,a1,-12
    800036a2:	0004871b          	sext.w	a4,s1

  if (bn < NINDIRECT)
    800036a6:	0ff00793          	li	a5,255
    800036aa:	08e7e563          	bltu	a5,a4,80003734 <bmap+0xd8>
  {
    // Load indirect block, allocating if necessary.
    if ((addr = ip->addrs[NDIRECT]) == 0)
    800036ae:	08052903          	lw	s2,128(a0)
    800036b2:	00091d63          	bnez	s2,800036cc <bmap+0x70>
    {
      addr = balloc(ip->dev);
    800036b6:	4108                	lw	a0,0(a0)
    800036b8:	00000097          	auipc	ra,0x0
    800036bc:	e6c080e7          	jalr	-404(ra) # 80003524 <balloc>
    800036c0:	0005091b          	sext.w	s2,a0
      if (addr == 0)
    800036c4:	02090d63          	beqz	s2,800036fe <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800036c8:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800036cc:	85ca                	mv	a1,s2
    800036ce:	0009a503          	lw	a0,0(s3)
    800036d2:	00000097          	auipc	ra,0x0
    800036d6:	b90080e7          	jalr	-1136(ra) # 80003262 <bread>
    800036da:	8a2a                	mv	s4,a0
    a = (uint *)bp->data;
    800036dc:	05850793          	addi	a5,a0,88
    if ((addr = a[bn]) == 0)
    800036e0:	02049593          	slli	a1,s1,0x20
    800036e4:	9181                	srli	a1,a1,0x20
    800036e6:	058a                	slli	a1,a1,0x2
    800036e8:	00b784b3          	add	s1,a5,a1
    800036ec:	0004a903          	lw	s2,0(s1)
    800036f0:	02090063          	beqz	s2,80003710 <bmap+0xb4>
      {
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800036f4:	8552                	mv	a0,s4
    800036f6:	00000097          	auipc	ra,0x0
    800036fa:	c9c080e7          	jalr	-868(ra) # 80003392 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800036fe:	854a                	mv	a0,s2
    80003700:	70a2                	ld	ra,40(sp)
    80003702:	7402                	ld	s0,32(sp)
    80003704:	64e2                	ld	s1,24(sp)
    80003706:	6942                	ld	s2,16(sp)
    80003708:	69a2                	ld	s3,8(sp)
    8000370a:	6a02                	ld	s4,0(sp)
    8000370c:	6145                	addi	sp,sp,48
    8000370e:	8082                	ret
      addr = balloc(ip->dev);
    80003710:	0009a503          	lw	a0,0(s3)
    80003714:	00000097          	auipc	ra,0x0
    80003718:	e10080e7          	jalr	-496(ra) # 80003524 <balloc>
    8000371c:	0005091b          	sext.w	s2,a0
      if (addr)
    80003720:	fc090ae3          	beqz	s2,800036f4 <bmap+0x98>
        a[bn] = addr;
    80003724:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003728:	8552                	mv	a0,s4
    8000372a:	00001097          	auipc	ra,0x1
    8000372e:	1fe080e7          	jalr	510(ra) # 80004928 <log_write>
    80003732:	b7c9                	j	800036f4 <bmap+0x98>
  panic("bmap: out of range");
    80003734:	00005517          	auipc	a0,0x5
    80003738:	edc50513          	addi	a0,a0,-292 # 80008610 <syscalls+0x118>
    8000373c:	ffffd097          	auipc	ra,0xffffd
    80003740:	e02080e7          	jalr	-510(ra) # 8000053e <panic>

0000000080003744 <iget>:
{
    80003744:	7179                	addi	sp,sp,-48
    80003746:	f406                	sd	ra,40(sp)
    80003748:	f022                	sd	s0,32(sp)
    8000374a:	ec26                	sd	s1,24(sp)
    8000374c:	e84a                	sd	s2,16(sp)
    8000374e:	e44e                	sd	s3,8(sp)
    80003750:	e052                	sd	s4,0(sp)
    80003752:	1800                	addi	s0,sp,48
    80003754:	89aa                	mv	s3,a0
    80003756:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003758:	00028517          	auipc	a0,0x28
    8000375c:	00050513          	mv	a0,a0
    80003760:	ffffd097          	auipc	ra,0xffffd
    80003764:	476080e7          	jalr	1142(ra) # 80000bd6 <acquire>
  empty = 0;
    80003768:	4901                	li	s2,0
  for (ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++)
    8000376a:	00028497          	auipc	s1,0x28
    8000376e:	00648493          	addi	s1,s1,6 # 8002b770 <itable+0x18>
    80003772:	0002a697          	auipc	a3,0x2a
    80003776:	a8e68693          	addi	a3,a3,-1394 # 8002d200 <log>
    8000377a:	a039                	j	80003788 <iget+0x44>
    if (empty == 0 && ip->ref == 0) // Remember empty slot.
    8000377c:	02090b63          	beqz	s2,800037b2 <iget+0x6e>
  for (ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++)
    80003780:	08848493          	addi	s1,s1,136
    80003784:	02d48a63          	beq	s1,a3,800037b8 <iget+0x74>
    if (ip->ref > 0 && ip->dev == dev && ip->inum == inum)
    80003788:	449c                	lw	a5,8(s1)
    8000378a:	fef059e3          	blez	a5,8000377c <iget+0x38>
    8000378e:	4098                	lw	a4,0(s1)
    80003790:	ff3716e3          	bne	a4,s3,8000377c <iget+0x38>
    80003794:	40d8                	lw	a4,4(s1)
    80003796:	ff4713e3          	bne	a4,s4,8000377c <iget+0x38>
      ip->ref++;
    8000379a:	2785                	addiw	a5,a5,1
    8000379c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000379e:	00028517          	auipc	a0,0x28
    800037a2:	fba50513          	addi	a0,a0,-70 # 8002b758 <itable>
    800037a6:	ffffd097          	auipc	ra,0xffffd
    800037aa:	4e4080e7          	jalr	1252(ra) # 80000c8a <release>
      return ip;
    800037ae:	8926                	mv	s2,s1
    800037b0:	a03d                	j	800037de <iget+0x9a>
    if (empty == 0 && ip->ref == 0) // Remember empty slot.
    800037b2:	f7f9                	bnez	a5,80003780 <iget+0x3c>
    800037b4:	8926                	mv	s2,s1
    800037b6:	b7e9                	j	80003780 <iget+0x3c>
  if (empty == 0)
    800037b8:	02090c63          	beqz	s2,800037f0 <iget+0xac>
  ip->dev = dev;
    800037bc:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800037c0:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800037c4:	4785                	li	a5,1
    800037c6:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800037ca:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800037ce:	00028517          	auipc	a0,0x28
    800037d2:	f8a50513          	addi	a0,a0,-118 # 8002b758 <itable>
    800037d6:	ffffd097          	auipc	ra,0xffffd
    800037da:	4b4080e7          	jalr	1204(ra) # 80000c8a <release>
}
    800037de:	854a                	mv	a0,s2
    800037e0:	70a2                	ld	ra,40(sp)
    800037e2:	7402                	ld	s0,32(sp)
    800037e4:	64e2                	ld	s1,24(sp)
    800037e6:	6942                	ld	s2,16(sp)
    800037e8:	69a2                	ld	s3,8(sp)
    800037ea:	6a02                	ld	s4,0(sp)
    800037ec:	6145                	addi	sp,sp,48
    800037ee:	8082                	ret
    panic("iget: no inodes");
    800037f0:	00005517          	auipc	a0,0x5
    800037f4:	e3850513          	addi	a0,a0,-456 # 80008628 <syscalls+0x130>
    800037f8:	ffffd097          	auipc	ra,0xffffd
    800037fc:	d46080e7          	jalr	-698(ra) # 8000053e <panic>

0000000080003800 <fsinit>:
{
    80003800:	7179                	addi	sp,sp,-48
    80003802:	f406                	sd	ra,40(sp)
    80003804:	f022                	sd	s0,32(sp)
    80003806:	ec26                	sd	s1,24(sp)
    80003808:	e84a                	sd	s2,16(sp)
    8000380a:	e44e                	sd	s3,8(sp)
    8000380c:	1800                	addi	s0,sp,48
    8000380e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003810:	4585                	li	a1,1
    80003812:	00000097          	auipc	ra,0x0
    80003816:	a50080e7          	jalr	-1456(ra) # 80003262 <bread>
    8000381a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000381c:	00028997          	auipc	s3,0x28
    80003820:	f1c98993          	addi	s3,s3,-228 # 8002b738 <sb>
    80003824:	02000613          	li	a2,32
    80003828:	05850593          	addi	a1,a0,88
    8000382c:	854e                	mv	a0,s3
    8000382e:	ffffd097          	auipc	ra,0xffffd
    80003832:	500080e7          	jalr	1280(ra) # 80000d2e <memmove>
  brelse(bp);
    80003836:	8526                	mv	a0,s1
    80003838:	00000097          	auipc	ra,0x0
    8000383c:	b5a080e7          	jalr	-1190(ra) # 80003392 <brelse>
  if (sb.magic != FSMAGIC)
    80003840:	0009a703          	lw	a4,0(s3)
    80003844:	102037b7          	lui	a5,0x10203
    80003848:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000384c:	02f71263          	bne	a4,a5,80003870 <fsinit+0x70>
  initlog(dev, &sb);
    80003850:	00028597          	auipc	a1,0x28
    80003854:	ee858593          	addi	a1,a1,-280 # 8002b738 <sb>
    80003858:	854a                	mv	a0,s2
    8000385a:	00001097          	auipc	ra,0x1
    8000385e:	e52080e7          	jalr	-430(ra) # 800046ac <initlog>
}
    80003862:	70a2                	ld	ra,40(sp)
    80003864:	7402                	ld	s0,32(sp)
    80003866:	64e2                	ld	s1,24(sp)
    80003868:	6942                	ld	s2,16(sp)
    8000386a:	69a2                	ld	s3,8(sp)
    8000386c:	6145                	addi	sp,sp,48
    8000386e:	8082                	ret
    panic("invalid file system");
    80003870:	00005517          	auipc	a0,0x5
    80003874:	dc850513          	addi	a0,a0,-568 # 80008638 <syscalls+0x140>
    80003878:	ffffd097          	auipc	ra,0xffffd
    8000387c:	cc6080e7          	jalr	-826(ra) # 8000053e <panic>

0000000080003880 <iinit>:
{
    80003880:	7179                	addi	sp,sp,-48
    80003882:	f406                	sd	ra,40(sp)
    80003884:	f022                	sd	s0,32(sp)
    80003886:	ec26                	sd	s1,24(sp)
    80003888:	e84a                	sd	s2,16(sp)
    8000388a:	e44e                	sd	s3,8(sp)
    8000388c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000388e:	00005597          	auipc	a1,0x5
    80003892:	dc258593          	addi	a1,a1,-574 # 80008650 <syscalls+0x158>
    80003896:	00028517          	auipc	a0,0x28
    8000389a:	ec250513          	addi	a0,a0,-318 # 8002b758 <itable>
    8000389e:	ffffd097          	auipc	ra,0xffffd
    800038a2:	2a8080e7          	jalr	680(ra) # 80000b46 <initlock>
  for (i = 0; i < NINODE; i++)
    800038a6:	00028497          	auipc	s1,0x28
    800038aa:	eda48493          	addi	s1,s1,-294 # 8002b780 <itable+0x28>
    800038ae:	0002a997          	auipc	s3,0x2a
    800038b2:	96298993          	addi	s3,s3,-1694 # 8002d210 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800038b6:	00005917          	auipc	s2,0x5
    800038ba:	da290913          	addi	s2,s2,-606 # 80008658 <syscalls+0x160>
    800038be:	85ca                	mv	a1,s2
    800038c0:	8526                	mv	a0,s1
    800038c2:	00001097          	auipc	ra,0x1
    800038c6:	14c080e7          	jalr	332(ra) # 80004a0e <initsleeplock>
  for (i = 0; i < NINODE; i++)
    800038ca:	08848493          	addi	s1,s1,136
    800038ce:	ff3498e3          	bne	s1,s3,800038be <iinit+0x3e>
}
    800038d2:	70a2                	ld	ra,40(sp)
    800038d4:	7402                	ld	s0,32(sp)
    800038d6:	64e2                	ld	s1,24(sp)
    800038d8:	6942                	ld	s2,16(sp)
    800038da:	69a2                	ld	s3,8(sp)
    800038dc:	6145                	addi	sp,sp,48
    800038de:	8082                	ret

00000000800038e0 <ialloc>:
{
    800038e0:	715d                	addi	sp,sp,-80
    800038e2:	e486                	sd	ra,72(sp)
    800038e4:	e0a2                	sd	s0,64(sp)
    800038e6:	fc26                	sd	s1,56(sp)
    800038e8:	f84a                	sd	s2,48(sp)
    800038ea:	f44e                	sd	s3,40(sp)
    800038ec:	f052                	sd	s4,32(sp)
    800038ee:	ec56                	sd	s5,24(sp)
    800038f0:	e85a                	sd	s6,16(sp)
    800038f2:	e45e                	sd	s7,8(sp)
    800038f4:	0880                	addi	s0,sp,80
  for (inum = 1; inum < sb.ninodes; inum++)
    800038f6:	00028717          	auipc	a4,0x28
    800038fa:	e4e72703          	lw	a4,-434(a4) # 8002b744 <sb+0xc>
    800038fe:	4785                	li	a5,1
    80003900:	04e7fa63          	bgeu	a5,a4,80003954 <ialloc+0x74>
    80003904:	8aaa                	mv	s5,a0
    80003906:	8bae                	mv	s7,a1
    80003908:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000390a:	00028a17          	auipc	s4,0x28
    8000390e:	e2ea0a13          	addi	s4,s4,-466 # 8002b738 <sb>
    80003912:	00048b1b          	sext.w	s6,s1
    80003916:	0044d793          	srli	a5,s1,0x4
    8000391a:	018a2583          	lw	a1,24(s4)
    8000391e:	9dbd                	addw	a1,a1,a5
    80003920:	8556                	mv	a0,s5
    80003922:	00000097          	auipc	ra,0x0
    80003926:	940080e7          	jalr	-1728(ra) # 80003262 <bread>
    8000392a:	892a                	mv	s2,a0
    dip = (struct dinode *)bp->data + inum % IPB;
    8000392c:	05850993          	addi	s3,a0,88
    80003930:	00f4f793          	andi	a5,s1,15
    80003934:	079a                	slli	a5,a5,0x6
    80003936:	99be                	add	s3,s3,a5
    if (dip->type == 0)
    80003938:	00099783          	lh	a5,0(s3)
    8000393c:	c3a1                	beqz	a5,8000397c <ialloc+0x9c>
    brelse(bp);
    8000393e:	00000097          	auipc	ra,0x0
    80003942:	a54080e7          	jalr	-1452(ra) # 80003392 <brelse>
  for (inum = 1; inum < sb.ninodes; inum++)
    80003946:	0485                	addi	s1,s1,1
    80003948:	00ca2703          	lw	a4,12(s4)
    8000394c:	0004879b          	sext.w	a5,s1
    80003950:	fce7e1e3          	bltu	a5,a4,80003912 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003954:	00005517          	auipc	a0,0x5
    80003958:	d0c50513          	addi	a0,a0,-756 # 80008660 <syscalls+0x168>
    8000395c:	ffffd097          	auipc	ra,0xffffd
    80003960:	c2c080e7          	jalr	-980(ra) # 80000588 <printf>
  return 0;
    80003964:	4501                	li	a0,0
}
    80003966:	60a6                	ld	ra,72(sp)
    80003968:	6406                	ld	s0,64(sp)
    8000396a:	74e2                	ld	s1,56(sp)
    8000396c:	7942                	ld	s2,48(sp)
    8000396e:	79a2                	ld	s3,40(sp)
    80003970:	7a02                	ld	s4,32(sp)
    80003972:	6ae2                	ld	s5,24(sp)
    80003974:	6b42                	ld	s6,16(sp)
    80003976:	6ba2                	ld	s7,8(sp)
    80003978:	6161                	addi	sp,sp,80
    8000397a:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000397c:	04000613          	li	a2,64
    80003980:	4581                	li	a1,0
    80003982:	854e                	mv	a0,s3
    80003984:	ffffd097          	auipc	ra,0xffffd
    80003988:	34e080e7          	jalr	846(ra) # 80000cd2 <memset>
      dip->type = type;
    8000398c:	01799023          	sh	s7,0(s3)
      log_write(bp); // mark it allocated on the disk
    80003990:	854a                	mv	a0,s2
    80003992:	00001097          	auipc	ra,0x1
    80003996:	f96080e7          	jalr	-106(ra) # 80004928 <log_write>
      brelse(bp);
    8000399a:	854a                	mv	a0,s2
    8000399c:	00000097          	auipc	ra,0x0
    800039a0:	9f6080e7          	jalr	-1546(ra) # 80003392 <brelse>
      return iget(dev, inum);
    800039a4:	85da                	mv	a1,s6
    800039a6:	8556                	mv	a0,s5
    800039a8:	00000097          	auipc	ra,0x0
    800039ac:	d9c080e7          	jalr	-612(ra) # 80003744 <iget>
    800039b0:	bf5d                	j	80003966 <ialloc+0x86>

00000000800039b2 <iupdate>:
{
    800039b2:	1101                	addi	sp,sp,-32
    800039b4:	ec06                	sd	ra,24(sp)
    800039b6:	e822                	sd	s0,16(sp)
    800039b8:	e426                	sd	s1,8(sp)
    800039ba:	e04a                	sd	s2,0(sp)
    800039bc:	1000                	addi	s0,sp,32
    800039be:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039c0:	415c                	lw	a5,4(a0)
    800039c2:	0047d79b          	srliw	a5,a5,0x4
    800039c6:	00028597          	auipc	a1,0x28
    800039ca:	d8a5a583          	lw	a1,-630(a1) # 8002b750 <sb+0x18>
    800039ce:	9dbd                	addw	a1,a1,a5
    800039d0:	4108                	lw	a0,0(a0)
    800039d2:	00000097          	auipc	ra,0x0
    800039d6:	890080e7          	jalr	-1904(ra) # 80003262 <bread>
    800039da:	892a                	mv	s2,a0
  dip = (struct dinode *)bp->data + ip->inum % IPB;
    800039dc:	05850793          	addi	a5,a0,88
    800039e0:	40c8                	lw	a0,4(s1)
    800039e2:	893d                	andi	a0,a0,15
    800039e4:	051a                	slli	a0,a0,0x6
    800039e6:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800039e8:	04449703          	lh	a4,68(s1)
    800039ec:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800039f0:	04649703          	lh	a4,70(s1)
    800039f4:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800039f8:	04849703          	lh	a4,72(s1)
    800039fc:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003a00:	04a49703          	lh	a4,74(s1)
    80003a04:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003a08:	44f8                	lw	a4,76(s1)
    80003a0a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003a0c:	03400613          	li	a2,52
    80003a10:	05048593          	addi	a1,s1,80
    80003a14:	0531                	addi	a0,a0,12
    80003a16:	ffffd097          	auipc	ra,0xffffd
    80003a1a:	318080e7          	jalr	792(ra) # 80000d2e <memmove>
  log_write(bp);
    80003a1e:	854a                	mv	a0,s2
    80003a20:	00001097          	auipc	ra,0x1
    80003a24:	f08080e7          	jalr	-248(ra) # 80004928 <log_write>
  brelse(bp);
    80003a28:	854a                	mv	a0,s2
    80003a2a:	00000097          	auipc	ra,0x0
    80003a2e:	968080e7          	jalr	-1688(ra) # 80003392 <brelse>
}
    80003a32:	60e2                	ld	ra,24(sp)
    80003a34:	6442                	ld	s0,16(sp)
    80003a36:	64a2                	ld	s1,8(sp)
    80003a38:	6902                	ld	s2,0(sp)
    80003a3a:	6105                	addi	sp,sp,32
    80003a3c:	8082                	ret

0000000080003a3e <idup>:
{
    80003a3e:	1101                	addi	sp,sp,-32
    80003a40:	ec06                	sd	ra,24(sp)
    80003a42:	e822                	sd	s0,16(sp)
    80003a44:	e426                	sd	s1,8(sp)
    80003a46:	1000                	addi	s0,sp,32
    80003a48:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a4a:	00028517          	auipc	a0,0x28
    80003a4e:	d0e50513          	addi	a0,a0,-754 # 8002b758 <itable>
    80003a52:	ffffd097          	auipc	ra,0xffffd
    80003a56:	184080e7          	jalr	388(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003a5a:	449c                	lw	a5,8(s1)
    80003a5c:	2785                	addiw	a5,a5,1
    80003a5e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a60:	00028517          	auipc	a0,0x28
    80003a64:	cf850513          	addi	a0,a0,-776 # 8002b758 <itable>
    80003a68:	ffffd097          	auipc	ra,0xffffd
    80003a6c:	222080e7          	jalr	546(ra) # 80000c8a <release>
}
    80003a70:	8526                	mv	a0,s1
    80003a72:	60e2                	ld	ra,24(sp)
    80003a74:	6442                	ld	s0,16(sp)
    80003a76:	64a2                	ld	s1,8(sp)
    80003a78:	6105                	addi	sp,sp,32
    80003a7a:	8082                	ret

0000000080003a7c <ilock>:
{
    80003a7c:	1101                	addi	sp,sp,-32
    80003a7e:	ec06                	sd	ra,24(sp)
    80003a80:	e822                	sd	s0,16(sp)
    80003a82:	e426                	sd	s1,8(sp)
    80003a84:	e04a                	sd	s2,0(sp)
    80003a86:	1000                	addi	s0,sp,32
  if (ip == 0 || ip->ref < 1)
    80003a88:	c115                	beqz	a0,80003aac <ilock+0x30>
    80003a8a:	84aa                	mv	s1,a0
    80003a8c:	451c                	lw	a5,8(a0)
    80003a8e:	00f05f63          	blez	a5,80003aac <ilock+0x30>
  acquiresleep(&ip->lock);
    80003a92:	0541                	addi	a0,a0,16
    80003a94:	00001097          	auipc	ra,0x1
    80003a98:	fb4080e7          	jalr	-76(ra) # 80004a48 <acquiresleep>
  if (ip->valid == 0)
    80003a9c:	40bc                	lw	a5,64(s1)
    80003a9e:	cf99                	beqz	a5,80003abc <ilock+0x40>
}
    80003aa0:	60e2                	ld	ra,24(sp)
    80003aa2:	6442                	ld	s0,16(sp)
    80003aa4:	64a2                	ld	s1,8(sp)
    80003aa6:	6902                	ld	s2,0(sp)
    80003aa8:	6105                	addi	sp,sp,32
    80003aaa:	8082                	ret
    panic("ilock");
    80003aac:	00005517          	auipc	a0,0x5
    80003ab0:	bcc50513          	addi	a0,a0,-1076 # 80008678 <syscalls+0x180>
    80003ab4:	ffffd097          	auipc	ra,0xffffd
    80003ab8:	a8a080e7          	jalr	-1398(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003abc:	40dc                	lw	a5,4(s1)
    80003abe:	0047d79b          	srliw	a5,a5,0x4
    80003ac2:	00028597          	auipc	a1,0x28
    80003ac6:	c8e5a583          	lw	a1,-882(a1) # 8002b750 <sb+0x18>
    80003aca:	9dbd                	addw	a1,a1,a5
    80003acc:	4088                	lw	a0,0(s1)
    80003ace:	fffff097          	auipc	ra,0xfffff
    80003ad2:	794080e7          	jalr	1940(ra) # 80003262 <bread>
    80003ad6:	892a                	mv	s2,a0
    dip = (struct dinode *)bp->data + ip->inum % IPB;
    80003ad8:	05850593          	addi	a1,a0,88
    80003adc:	40dc                	lw	a5,4(s1)
    80003ade:	8bbd                	andi	a5,a5,15
    80003ae0:	079a                	slli	a5,a5,0x6
    80003ae2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003ae4:	00059783          	lh	a5,0(a1)
    80003ae8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003aec:	00259783          	lh	a5,2(a1)
    80003af0:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003af4:	00459783          	lh	a5,4(a1)
    80003af8:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003afc:	00659783          	lh	a5,6(a1)
    80003b00:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003b04:	459c                	lw	a5,8(a1)
    80003b06:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003b08:	03400613          	li	a2,52
    80003b0c:	05b1                	addi	a1,a1,12
    80003b0e:	05048513          	addi	a0,s1,80
    80003b12:	ffffd097          	auipc	ra,0xffffd
    80003b16:	21c080e7          	jalr	540(ra) # 80000d2e <memmove>
    brelse(bp);
    80003b1a:	854a                	mv	a0,s2
    80003b1c:	00000097          	auipc	ra,0x0
    80003b20:	876080e7          	jalr	-1930(ra) # 80003392 <brelse>
    ip->valid = 1;
    80003b24:	4785                	li	a5,1
    80003b26:	c0bc                	sw	a5,64(s1)
    if (ip->type == 0)
    80003b28:	04449783          	lh	a5,68(s1)
    80003b2c:	fbb5                	bnez	a5,80003aa0 <ilock+0x24>
      panic("ilock: no type");
    80003b2e:	00005517          	auipc	a0,0x5
    80003b32:	b5250513          	addi	a0,a0,-1198 # 80008680 <syscalls+0x188>
    80003b36:	ffffd097          	auipc	ra,0xffffd
    80003b3a:	a08080e7          	jalr	-1528(ra) # 8000053e <panic>

0000000080003b3e <iunlock>:
{
    80003b3e:	1101                	addi	sp,sp,-32
    80003b40:	ec06                	sd	ra,24(sp)
    80003b42:	e822                	sd	s0,16(sp)
    80003b44:	e426                	sd	s1,8(sp)
    80003b46:	e04a                	sd	s2,0(sp)
    80003b48:	1000                	addi	s0,sp,32
  if (ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003b4a:	c905                	beqz	a0,80003b7a <iunlock+0x3c>
    80003b4c:	84aa                	mv	s1,a0
    80003b4e:	01050913          	addi	s2,a0,16
    80003b52:	854a                	mv	a0,s2
    80003b54:	00001097          	auipc	ra,0x1
    80003b58:	f8e080e7          	jalr	-114(ra) # 80004ae2 <holdingsleep>
    80003b5c:	cd19                	beqz	a0,80003b7a <iunlock+0x3c>
    80003b5e:	449c                	lw	a5,8(s1)
    80003b60:	00f05d63          	blez	a5,80003b7a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003b64:	854a                	mv	a0,s2
    80003b66:	00001097          	auipc	ra,0x1
    80003b6a:	f38080e7          	jalr	-200(ra) # 80004a9e <releasesleep>
}
    80003b6e:	60e2                	ld	ra,24(sp)
    80003b70:	6442                	ld	s0,16(sp)
    80003b72:	64a2                	ld	s1,8(sp)
    80003b74:	6902                	ld	s2,0(sp)
    80003b76:	6105                	addi	sp,sp,32
    80003b78:	8082                	ret
    panic("iunlock");
    80003b7a:	00005517          	auipc	a0,0x5
    80003b7e:	b1650513          	addi	a0,a0,-1258 # 80008690 <syscalls+0x198>
    80003b82:	ffffd097          	auipc	ra,0xffffd
    80003b86:	9bc080e7          	jalr	-1604(ra) # 8000053e <panic>

0000000080003b8a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void itrunc(struct inode *ip)
{
    80003b8a:	7179                	addi	sp,sp,-48
    80003b8c:	f406                	sd	ra,40(sp)
    80003b8e:	f022                	sd	s0,32(sp)
    80003b90:	ec26                	sd	s1,24(sp)
    80003b92:	e84a                	sd	s2,16(sp)
    80003b94:	e44e                	sd	s3,8(sp)
    80003b96:	e052                	sd	s4,0(sp)
    80003b98:	1800                	addi	s0,sp,48
    80003b9a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for (i = 0; i < NDIRECT; i++)
    80003b9c:	05050493          	addi	s1,a0,80
    80003ba0:	08050913          	addi	s2,a0,128
    80003ba4:	a021                	j	80003bac <itrunc+0x22>
    80003ba6:	0491                	addi	s1,s1,4
    80003ba8:	01248d63          	beq	s1,s2,80003bc2 <itrunc+0x38>
  {
    if (ip->addrs[i])
    80003bac:	408c                	lw	a1,0(s1)
    80003bae:	dde5                	beqz	a1,80003ba6 <itrunc+0x1c>
    {
      bfree(ip->dev, ip->addrs[i]);
    80003bb0:	0009a503          	lw	a0,0(s3)
    80003bb4:	00000097          	auipc	ra,0x0
    80003bb8:	8f4080e7          	jalr	-1804(ra) # 800034a8 <bfree>
      ip->addrs[i] = 0;
    80003bbc:	0004a023          	sw	zero,0(s1)
    80003bc0:	b7dd                	j	80003ba6 <itrunc+0x1c>
    }
  }

  if (ip->addrs[NDIRECT])
    80003bc2:	0809a583          	lw	a1,128(s3)
    80003bc6:	e185                	bnez	a1,80003be6 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003bc8:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003bcc:	854e                	mv	a0,s3
    80003bce:	00000097          	auipc	ra,0x0
    80003bd2:	de4080e7          	jalr	-540(ra) # 800039b2 <iupdate>
}
    80003bd6:	70a2                	ld	ra,40(sp)
    80003bd8:	7402                	ld	s0,32(sp)
    80003bda:	64e2                	ld	s1,24(sp)
    80003bdc:	6942                	ld	s2,16(sp)
    80003bde:	69a2                	ld	s3,8(sp)
    80003be0:	6a02                	ld	s4,0(sp)
    80003be2:	6145                	addi	sp,sp,48
    80003be4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003be6:	0009a503          	lw	a0,0(s3)
    80003bea:	fffff097          	auipc	ra,0xfffff
    80003bee:	678080e7          	jalr	1656(ra) # 80003262 <bread>
    80003bf2:	8a2a                	mv	s4,a0
    for (j = 0; j < NINDIRECT; j++)
    80003bf4:	05850493          	addi	s1,a0,88
    80003bf8:	45850913          	addi	s2,a0,1112
    80003bfc:	a021                	j	80003c04 <itrunc+0x7a>
    80003bfe:	0491                	addi	s1,s1,4
    80003c00:	01248b63          	beq	s1,s2,80003c16 <itrunc+0x8c>
      if (a[j])
    80003c04:	408c                	lw	a1,0(s1)
    80003c06:	dde5                	beqz	a1,80003bfe <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003c08:	0009a503          	lw	a0,0(s3)
    80003c0c:	00000097          	auipc	ra,0x0
    80003c10:	89c080e7          	jalr	-1892(ra) # 800034a8 <bfree>
    80003c14:	b7ed                	j	80003bfe <itrunc+0x74>
    brelse(bp);
    80003c16:	8552                	mv	a0,s4
    80003c18:	fffff097          	auipc	ra,0xfffff
    80003c1c:	77a080e7          	jalr	1914(ra) # 80003392 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003c20:	0809a583          	lw	a1,128(s3)
    80003c24:	0009a503          	lw	a0,0(s3)
    80003c28:	00000097          	auipc	ra,0x0
    80003c2c:	880080e7          	jalr	-1920(ra) # 800034a8 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003c30:	0809a023          	sw	zero,128(s3)
    80003c34:	bf51                	j	80003bc8 <itrunc+0x3e>

0000000080003c36 <iput>:
{
    80003c36:	1101                	addi	sp,sp,-32
    80003c38:	ec06                	sd	ra,24(sp)
    80003c3a:	e822                	sd	s0,16(sp)
    80003c3c:	e426                	sd	s1,8(sp)
    80003c3e:	e04a                	sd	s2,0(sp)
    80003c40:	1000                	addi	s0,sp,32
    80003c42:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c44:	00028517          	auipc	a0,0x28
    80003c48:	b1450513          	addi	a0,a0,-1260 # 8002b758 <itable>
    80003c4c:	ffffd097          	auipc	ra,0xffffd
    80003c50:	f8a080e7          	jalr	-118(ra) # 80000bd6 <acquire>
  if (ip->ref == 1 && ip->valid && ip->nlink == 0)
    80003c54:	4498                	lw	a4,8(s1)
    80003c56:	4785                	li	a5,1
    80003c58:	02f70363          	beq	a4,a5,80003c7e <iput+0x48>
  ip->ref--;
    80003c5c:	449c                	lw	a5,8(s1)
    80003c5e:	37fd                	addiw	a5,a5,-1
    80003c60:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c62:	00028517          	auipc	a0,0x28
    80003c66:	af650513          	addi	a0,a0,-1290 # 8002b758 <itable>
    80003c6a:	ffffd097          	auipc	ra,0xffffd
    80003c6e:	020080e7          	jalr	32(ra) # 80000c8a <release>
}
    80003c72:	60e2                	ld	ra,24(sp)
    80003c74:	6442                	ld	s0,16(sp)
    80003c76:	64a2                	ld	s1,8(sp)
    80003c78:	6902                	ld	s2,0(sp)
    80003c7a:	6105                	addi	sp,sp,32
    80003c7c:	8082                	ret
  if (ip->ref == 1 && ip->valid && ip->nlink == 0)
    80003c7e:	40bc                	lw	a5,64(s1)
    80003c80:	dff1                	beqz	a5,80003c5c <iput+0x26>
    80003c82:	04a49783          	lh	a5,74(s1)
    80003c86:	fbf9                	bnez	a5,80003c5c <iput+0x26>
    acquiresleep(&ip->lock);
    80003c88:	01048913          	addi	s2,s1,16
    80003c8c:	854a                	mv	a0,s2
    80003c8e:	00001097          	auipc	ra,0x1
    80003c92:	dba080e7          	jalr	-582(ra) # 80004a48 <acquiresleep>
    release(&itable.lock);
    80003c96:	00028517          	auipc	a0,0x28
    80003c9a:	ac250513          	addi	a0,a0,-1342 # 8002b758 <itable>
    80003c9e:	ffffd097          	auipc	ra,0xffffd
    80003ca2:	fec080e7          	jalr	-20(ra) # 80000c8a <release>
    itrunc(ip);
    80003ca6:	8526                	mv	a0,s1
    80003ca8:	00000097          	auipc	ra,0x0
    80003cac:	ee2080e7          	jalr	-286(ra) # 80003b8a <itrunc>
    ip->type = 0;
    80003cb0:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003cb4:	8526                	mv	a0,s1
    80003cb6:	00000097          	auipc	ra,0x0
    80003cba:	cfc080e7          	jalr	-772(ra) # 800039b2 <iupdate>
    ip->valid = 0;
    80003cbe:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003cc2:	854a                	mv	a0,s2
    80003cc4:	00001097          	auipc	ra,0x1
    80003cc8:	dda080e7          	jalr	-550(ra) # 80004a9e <releasesleep>
    acquire(&itable.lock);
    80003ccc:	00028517          	auipc	a0,0x28
    80003cd0:	a8c50513          	addi	a0,a0,-1396 # 8002b758 <itable>
    80003cd4:	ffffd097          	auipc	ra,0xffffd
    80003cd8:	f02080e7          	jalr	-254(ra) # 80000bd6 <acquire>
    80003cdc:	b741                	j	80003c5c <iput+0x26>

0000000080003cde <iunlockput>:
{
    80003cde:	1101                	addi	sp,sp,-32
    80003ce0:	ec06                	sd	ra,24(sp)
    80003ce2:	e822                	sd	s0,16(sp)
    80003ce4:	e426                	sd	s1,8(sp)
    80003ce6:	1000                	addi	s0,sp,32
    80003ce8:	84aa                	mv	s1,a0
  iunlock(ip);
    80003cea:	00000097          	auipc	ra,0x0
    80003cee:	e54080e7          	jalr	-428(ra) # 80003b3e <iunlock>
  iput(ip);
    80003cf2:	8526                	mv	a0,s1
    80003cf4:	00000097          	auipc	ra,0x0
    80003cf8:	f42080e7          	jalr	-190(ra) # 80003c36 <iput>
}
    80003cfc:	60e2                	ld	ra,24(sp)
    80003cfe:	6442                	ld	s0,16(sp)
    80003d00:	64a2                	ld	s1,8(sp)
    80003d02:	6105                	addi	sp,sp,32
    80003d04:	8082                	ret

0000000080003d06 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void stati(struct inode *ip, struct stat *st)
{
    80003d06:	1141                	addi	sp,sp,-16
    80003d08:	e422                	sd	s0,8(sp)
    80003d0a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003d0c:	411c                	lw	a5,0(a0)
    80003d0e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003d10:	415c                	lw	a5,4(a0)
    80003d12:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003d14:	04451783          	lh	a5,68(a0)
    80003d18:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003d1c:	04a51783          	lh	a5,74(a0)
    80003d20:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003d24:	04c56783          	lwu	a5,76(a0)
    80003d28:	e99c                	sd	a5,16(a1)
}
    80003d2a:	6422                	ld	s0,8(sp)
    80003d2c:	0141                	addi	sp,sp,16
    80003d2e:	8082                	ret

0000000080003d30 <readi>:
int readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if (off > ip->size || off + n < off)
    80003d30:	457c                	lw	a5,76(a0)
    80003d32:	0ed7e963          	bltu	a5,a3,80003e24 <readi+0xf4>
{
    80003d36:	7159                	addi	sp,sp,-112
    80003d38:	f486                	sd	ra,104(sp)
    80003d3a:	f0a2                	sd	s0,96(sp)
    80003d3c:	eca6                	sd	s1,88(sp)
    80003d3e:	e8ca                	sd	s2,80(sp)
    80003d40:	e4ce                	sd	s3,72(sp)
    80003d42:	e0d2                	sd	s4,64(sp)
    80003d44:	fc56                	sd	s5,56(sp)
    80003d46:	f85a                	sd	s6,48(sp)
    80003d48:	f45e                	sd	s7,40(sp)
    80003d4a:	f062                	sd	s8,32(sp)
    80003d4c:	ec66                	sd	s9,24(sp)
    80003d4e:	e86a                	sd	s10,16(sp)
    80003d50:	e46e                	sd	s11,8(sp)
    80003d52:	1880                	addi	s0,sp,112
    80003d54:	8b2a                	mv	s6,a0
    80003d56:	8bae                	mv	s7,a1
    80003d58:	8a32                	mv	s4,a2
    80003d5a:	84b6                	mv	s1,a3
    80003d5c:	8aba                	mv	s5,a4
  if (off > ip->size || off + n < off)
    80003d5e:	9f35                	addw	a4,a4,a3
    return 0;
    80003d60:	4501                	li	a0,0
  if (off > ip->size || off + n < off)
    80003d62:	0ad76063          	bltu	a4,a3,80003e02 <readi+0xd2>
  if (off + n > ip->size)
    80003d66:	00e7f463          	bgeu	a5,a4,80003d6e <readi+0x3e>
    n = ip->size - off;
    80003d6a:	40d78abb          	subw	s5,a5,a3

  for (tot = 0; tot < n; tot += m, off += m, dst += m)
    80003d6e:	0a0a8963          	beqz	s5,80003e20 <readi+0xf0>
    80003d72:	4981                	li	s3,0
  {
    uint addr = bmap(ip, off / BSIZE);
    if (addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off % BSIZE);
    80003d74:	40000c93          	li	s9,1024
    if (either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1)
    80003d78:	5c7d                	li	s8,-1
    80003d7a:	a82d                	j	80003db4 <readi+0x84>
    80003d7c:	020d1d93          	slli	s11,s10,0x20
    80003d80:	020ddd93          	srli	s11,s11,0x20
    80003d84:	05890793          	addi	a5,s2,88
    80003d88:	86ee                	mv	a3,s11
    80003d8a:	963e                	add	a2,a2,a5
    80003d8c:	85d2                	mv	a1,s4
    80003d8e:	855e                	mv	a0,s7
    80003d90:	fffff097          	auipc	ra,0xfffff
    80003d94:	8c2080e7          	jalr	-1854(ra) # 80002652 <either_copyout>
    80003d98:	05850d63          	beq	a0,s8,80003df2 <readi+0xc2>
    {
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003d9c:	854a                	mv	a0,s2
    80003d9e:	fffff097          	auipc	ra,0xfffff
    80003da2:	5f4080e7          	jalr	1524(ra) # 80003392 <brelse>
  for (tot = 0; tot < n; tot += m, off += m, dst += m)
    80003da6:	013d09bb          	addw	s3,s10,s3
    80003daa:	009d04bb          	addw	s1,s10,s1
    80003dae:	9a6e                	add	s4,s4,s11
    80003db0:	0559f763          	bgeu	s3,s5,80003dfe <readi+0xce>
    uint addr = bmap(ip, off / BSIZE);
    80003db4:	00a4d59b          	srliw	a1,s1,0xa
    80003db8:	855a                	mv	a0,s6
    80003dba:	00000097          	auipc	ra,0x0
    80003dbe:	8a2080e7          	jalr	-1886(ra) # 8000365c <bmap>
    80003dc2:	0005059b          	sext.w	a1,a0
    if (addr == 0)
    80003dc6:	cd85                	beqz	a1,80003dfe <readi+0xce>
    bp = bread(ip->dev, addr);
    80003dc8:	000b2503          	lw	a0,0(s6)
    80003dcc:	fffff097          	auipc	ra,0xfffff
    80003dd0:	496080e7          	jalr	1174(ra) # 80003262 <bread>
    80003dd4:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off % BSIZE);
    80003dd6:	3ff4f613          	andi	a2,s1,1023
    80003dda:	40cc87bb          	subw	a5,s9,a2
    80003dde:	413a873b          	subw	a4,s5,s3
    80003de2:	8d3e                	mv	s10,a5
    80003de4:	2781                	sext.w	a5,a5
    80003de6:	0007069b          	sext.w	a3,a4
    80003dea:	f8f6f9e3          	bgeu	a3,a5,80003d7c <readi+0x4c>
    80003dee:	8d3a                	mv	s10,a4
    80003df0:	b771                	j	80003d7c <readi+0x4c>
      brelse(bp);
    80003df2:	854a                	mv	a0,s2
    80003df4:	fffff097          	auipc	ra,0xfffff
    80003df8:	59e080e7          	jalr	1438(ra) # 80003392 <brelse>
      tot = -1;
    80003dfc:	59fd                	li	s3,-1
  }
  return tot;
    80003dfe:	0009851b          	sext.w	a0,s3
}
    80003e02:	70a6                	ld	ra,104(sp)
    80003e04:	7406                	ld	s0,96(sp)
    80003e06:	64e6                	ld	s1,88(sp)
    80003e08:	6946                	ld	s2,80(sp)
    80003e0a:	69a6                	ld	s3,72(sp)
    80003e0c:	6a06                	ld	s4,64(sp)
    80003e0e:	7ae2                	ld	s5,56(sp)
    80003e10:	7b42                	ld	s6,48(sp)
    80003e12:	7ba2                	ld	s7,40(sp)
    80003e14:	7c02                	ld	s8,32(sp)
    80003e16:	6ce2                	ld	s9,24(sp)
    80003e18:	6d42                	ld	s10,16(sp)
    80003e1a:	6da2                	ld	s11,8(sp)
    80003e1c:	6165                	addi	sp,sp,112
    80003e1e:	8082                	ret
  for (tot = 0; tot < n; tot += m, off += m, dst += m)
    80003e20:	89d6                	mv	s3,s5
    80003e22:	bff1                	j	80003dfe <readi+0xce>
    return 0;
    80003e24:	4501                	li	a0,0
}
    80003e26:	8082                	ret

0000000080003e28 <writei>:
int writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if (off > ip->size || off + n < off)
    80003e28:	457c                	lw	a5,76(a0)
    80003e2a:	10d7e863          	bltu	a5,a3,80003f3a <writei+0x112>
{
    80003e2e:	7159                	addi	sp,sp,-112
    80003e30:	f486                	sd	ra,104(sp)
    80003e32:	f0a2                	sd	s0,96(sp)
    80003e34:	eca6                	sd	s1,88(sp)
    80003e36:	e8ca                	sd	s2,80(sp)
    80003e38:	e4ce                	sd	s3,72(sp)
    80003e3a:	e0d2                	sd	s4,64(sp)
    80003e3c:	fc56                	sd	s5,56(sp)
    80003e3e:	f85a                	sd	s6,48(sp)
    80003e40:	f45e                	sd	s7,40(sp)
    80003e42:	f062                	sd	s8,32(sp)
    80003e44:	ec66                	sd	s9,24(sp)
    80003e46:	e86a                	sd	s10,16(sp)
    80003e48:	e46e                	sd	s11,8(sp)
    80003e4a:	1880                	addi	s0,sp,112
    80003e4c:	8aaa                	mv	s5,a0
    80003e4e:	8bae                	mv	s7,a1
    80003e50:	8a32                	mv	s4,a2
    80003e52:	8936                	mv	s2,a3
    80003e54:	8b3a                	mv	s6,a4
  if (off > ip->size || off + n < off)
    80003e56:	00e687bb          	addw	a5,a3,a4
    80003e5a:	0ed7e263          	bltu	a5,a3,80003f3e <writei+0x116>
    return -1;
  if (off + n > MAXFILE * BSIZE)
    80003e5e:	00043737          	lui	a4,0x43
    80003e62:	0ef76063          	bltu	a4,a5,80003f42 <writei+0x11a>
    return -1;

  for (tot = 0; tot < n; tot += m, off += m, src += m)
    80003e66:	0c0b0863          	beqz	s6,80003f36 <writei+0x10e>
    80003e6a:	4981                	li	s3,0
  {
    uint addr = bmap(ip, off / BSIZE);
    if (addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off % BSIZE);
    80003e6c:	40000c93          	li	s9,1024
    if (either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1)
    80003e70:	5c7d                	li	s8,-1
    80003e72:	a091                	j	80003eb6 <writei+0x8e>
    80003e74:	020d1d93          	slli	s11,s10,0x20
    80003e78:	020ddd93          	srli	s11,s11,0x20
    80003e7c:	05848793          	addi	a5,s1,88
    80003e80:	86ee                	mv	a3,s11
    80003e82:	8652                	mv	a2,s4
    80003e84:	85de                	mv	a1,s7
    80003e86:	953e                	add	a0,a0,a5
    80003e88:	fffff097          	auipc	ra,0xfffff
    80003e8c:	820080e7          	jalr	-2016(ra) # 800026a8 <either_copyin>
    80003e90:	07850263          	beq	a0,s8,80003ef4 <writei+0xcc>
    {
      brelse(bp);
      break;
    }
    log_write(bp);
    80003e94:	8526                	mv	a0,s1
    80003e96:	00001097          	auipc	ra,0x1
    80003e9a:	a92080e7          	jalr	-1390(ra) # 80004928 <log_write>
    brelse(bp);
    80003e9e:	8526                	mv	a0,s1
    80003ea0:	fffff097          	auipc	ra,0xfffff
    80003ea4:	4f2080e7          	jalr	1266(ra) # 80003392 <brelse>
  for (tot = 0; tot < n; tot += m, off += m, src += m)
    80003ea8:	013d09bb          	addw	s3,s10,s3
    80003eac:	012d093b          	addw	s2,s10,s2
    80003eb0:	9a6e                	add	s4,s4,s11
    80003eb2:	0569f663          	bgeu	s3,s6,80003efe <writei+0xd6>
    uint addr = bmap(ip, off / BSIZE);
    80003eb6:	00a9559b          	srliw	a1,s2,0xa
    80003eba:	8556                	mv	a0,s5
    80003ebc:	fffff097          	auipc	ra,0xfffff
    80003ec0:	7a0080e7          	jalr	1952(ra) # 8000365c <bmap>
    80003ec4:	0005059b          	sext.w	a1,a0
    if (addr == 0)
    80003ec8:	c99d                	beqz	a1,80003efe <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003eca:	000aa503          	lw	a0,0(s5)
    80003ece:	fffff097          	auipc	ra,0xfffff
    80003ed2:	394080e7          	jalr	916(ra) # 80003262 <bread>
    80003ed6:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off % BSIZE);
    80003ed8:	3ff97513          	andi	a0,s2,1023
    80003edc:	40ac87bb          	subw	a5,s9,a0
    80003ee0:	413b073b          	subw	a4,s6,s3
    80003ee4:	8d3e                	mv	s10,a5
    80003ee6:	2781                	sext.w	a5,a5
    80003ee8:	0007069b          	sext.w	a3,a4
    80003eec:	f8f6f4e3          	bgeu	a3,a5,80003e74 <writei+0x4c>
    80003ef0:	8d3a                	mv	s10,a4
    80003ef2:	b749                	j	80003e74 <writei+0x4c>
      brelse(bp);
    80003ef4:	8526                	mv	a0,s1
    80003ef6:	fffff097          	auipc	ra,0xfffff
    80003efa:	49c080e7          	jalr	1180(ra) # 80003392 <brelse>
  }

  if (off > ip->size)
    80003efe:	04caa783          	lw	a5,76(s5)
    80003f02:	0127f463          	bgeu	a5,s2,80003f0a <writei+0xe2>
    ip->size = off;
    80003f06:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003f0a:	8556                	mv	a0,s5
    80003f0c:	00000097          	auipc	ra,0x0
    80003f10:	aa6080e7          	jalr	-1370(ra) # 800039b2 <iupdate>

  return tot;
    80003f14:	0009851b          	sext.w	a0,s3
}
    80003f18:	70a6                	ld	ra,104(sp)
    80003f1a:	7406                	ld	s0,96(sp)
    80003f1c:	64e6                	ld	s1,88(sp)
    80003f1e:	6946                	ld	s2,80(sp)
    80003f20:	69a6                	ld	s3,72(sp)
    80003f22:	6a06                	ld	s4,64(sp)
    80003f24:	7ae2                	ld	s5,56(sp)
    80003f26:	7b42                	ld	s6,48(sp)
    80003f28:	7ba2                	ld	s7,40(sp)
    80003f2a:	7c02                	ld	s8,32(sp)
    80003f2c:	6ce2                	ld	s9,24(sp)
    80003f2e:	6d42                	ld	s10,16(sp)
    80003f30:	6da2                	ld	s11,8(sp)
    80003f32:	6165                	addi	sp,sp,112
    80003f34:	8082                	ret
  for (tot = 0; tot < n; tot += m, off += m, src += m)
    80003f36:	89da                	mv	s3,s6
    80003f38:	bfc9                	j	80003f0a <writei+0xe2>
    return -1;
    80003f3a:	557d                	li	a0,-1
}
    80003f3c:	8082                	ret
    return -1;
    80003f3e:	557d                	li	a0,-1
    80003f40:	bfe1                	j	80003f18 <writei+0xf0>
    return -1;
    80003f42:	557d                	li	a0,-1
    80003f44:	bfd1                	j	80003f18 <writei+0xf0>

0000000080003f46 <namecmp>:

// Directories

int namecmp(const char *s, const char *t)
{
    80003f46:	1141                	addi	sp,sp,-16
    80003f48:	e406                	sd	ra,8(sp)
    80003f4a:	e022                	sd	s0,0(sp)
    80003f4c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003f4e:	4639                	li	a2,14
    80003f50:	ffffd097          	auipc	ra,0xffffd
    80003f54:	e52080e7          	jalr	-430(ra) # 80000da2 <strncmp>
}
    80003f58:	60a2                	ld	ra,8(sp)
    80003f5a:	6402                	ld	s0,0(sp)
    80003f5c:	0141                	addi	sp,sp,16
    80003f5e:	8082                	ret

0000000080003f60 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode *
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003f60:	7139                	addi	sp,sp,-64
    80003f62:	fc06                	sd	ra,56(sp)
    80003f64:	f822                	sd	s0,48(sp)
    80003f66:	f426                	sd	s1,40(sp)
    80003f68:	f04a                	sd	s2,32(sp)
    80003f6a:	ec4e                	sd	s3,24(sp)
    80003f6c:	e852                	sd	s4,16(sp)
    80003f6e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if (dp->type != T_DIR)
    80003f70:	04451703          	lh	a4,68(a0)
    80003f74:	4785                	li	a5,1
    80003f76:	00f71a63          	bne	a4,a5,80003f8a <dirlookup+0x2a>
    80003f7a:	892a                	mv	s2,a0
    80003f7c:	89ae                	mv	s3,a1
    80003f7e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for (off = 0; off < dp->size; off += sizeof(de))
    80003f80:	457c                	lw	a5,76(a0)
    80003f82:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003f84:	4501                	li	a0,0
  for (off = 0; off < dp->size; off += sizeof(de))
    80003f86:	e79d                	bnez	a5,80003fb4 <dirlookup+0x54>
    80003f88:	a8a5                	j	80004000 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003f8a:	00004517          	auipc	a0,0x4
    80003f8e:	70e50513          	addi	a0,a0,1806 # 80008698 <syscalls+0x1a0>
    80003f92:	ffffc097          	auipc	ra,0xffffc
    80003f96:	5ac080e7          	jalr	1452(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003f9a:	00004517          	auipc	a0,0x4
    80003f9e:	71650513          	addi	a0,a0,1814 # 800086b0 <syscalls+0x1b8>
    80003fa2:	ffffc097          	auipc	ra,0xffffc
    80003fa6:	59c080e7          	jalr	1436(ra) # 8000053e <panic>
  for (off = 0; off < dp->size; off += sizeof(de))
    80003faa:	24c1                	addiw	s1,s1,16
    80003fac:	04c92783          	lw	a5,76(s2)
    80003fb0:	04f4f763          	bgeu	s1,a5,80003ffe <dirlookup+0x9e>
    if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fb4:	4741                	li	a4,16
    80003fb6:	86a6                	mv	a3,s1
    80003fb8:	fc040613          	addi	a2,s0,-64
    80003fbc:	4581                	li	a1,0
    80003fbe:	854a                	mv	a0,s2
    80003fc0:	00000097          	auipc	ra,0x0
    80003fc4:	d70080e7          	jalr	-656(ra) # 80003d30 <readi>
    80003fc8:	47c1                	li	a5,16
    80003fca:	fcf518e3          	bne	a0,a5,80003f9a <dirlookup+0x3a>
    if (de.inum == 0)
    80003fce:	fc045783          	lhu	a5,-64(s0)
    80003fd2:	dfe1                	beqz	a5,80003faa <dirlookup+0x4a>
    if (namecmp(name, de.name) == 0)
    80003fd4:	fc240593          	addi	a1,s0,-62
    80003fd8:	854e                	mv	a0,s3
    80003fda:	00000097          	auipc	ra,0x0
    80003fde:	f6c080e7          	jalr	-148(ra) # 80003f46 <namecmp>
    80003fe2:	f561                	bnez	a0,80003faa <dirlookup+0x4a>
      if (poff)
    80003fe4:	000a0463          	beqz	s4,80003fec <dirlookup+0x8c>
        *poff = off;
    80003fe8:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003fec:	fc045583          	lhu	a1,-64(s0)
    80003ff0:	00092503          	lw	a0,0(s2)
    80003ff4:	fffff097          	auipc	ra,0xfffff
    80003ff8:	750080e7          	jalr	1872(ra) # 80003744 <iget>
    80003ffc:	a011                	j	80004000 <dirlookup+0xa0>
  return 0;
    80003ffe:	4501                	li	a0,0
}
    80004000:	70e2                	ld	ra,56(sp)
    80004002:	7442                	ld	s0,48(sp)
    80004004:	74a2                	ld	s1,40(sp)
    80004006:	7902                	ld	s2,32(sp)
    80004008:	69e2                	ld	s3,24(sp)
    8000400a:	6a42                	ld	s4,16(sp)
    8000400c:	6121                	addi	sp,sp,64
    8000400e:	8082                	ret

0000000080004010 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode *
namex(char *path, int nameiparent, char *name)
{
    80004010:	711d                	addi	sp,sp,-96
    80004012:	ec86                	sd	ra,88(sp)
    80004014:	e8a2                	sd	s0,80(sp)
    80004016:	e4a6                	sd	s1,72(sp)
    80004018:	e0ca                	sd	s2,64(sp)
    8000401a:	fc4e                	sd	s3,56(sp)
    8000401c:	f852                	sd	s4,48(sp)
    8000401e:	f456                	sd	s5,40(sp)
    80004020:	f05a                	sd	s6,32(sp)
    80004022:	ec5e                	sd	s7,24(sp)
    80004024:	e862                	sd	s8,16(sp)
    80004026:	e466                	sd	s9,8(sp)
    80004028:	1080                	addi	s0,sp,96
    8000402a:	84aa                	mv	s1,a0
    8000402c:	8aae                	mv	s5,a1
    8000402e:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if (*path == '/')
    80004030:	00054703          	lbu	a4,0(a0)
    80004034:	02f00793          	li	a5,47
    80004038:	02f70363          	beq	a4,a5,8000405e <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000403c:	ffffe097          	auipc	ra,0xffffe
    80004040:	abc080e7          	jalr	-1348(ra) # 80001af8 <myproc>
    80004044:	15053503          	ld	a0,336(a0)
    80004048:	00000097          	auipc	ra,0x0
    8000404c:	9f6080e7          	jalr	-1546(ra) # 80003a3e <idup>
    80004050:	89aa                	mv	s3,a0
  while (*path == '/')
    80004052:	02f00913          	li	s2,47
  len = path - s;
    80004056:	4b01                	li	s6,0
  if (len >= DIRSIZ)
    80004058:	4c35                	li	s8,13

  while ((path = skipelem(path, name)) != 0)
  {
    ilock(ip);
    if (ip->type != T_DIR)
    8000405a:	4b85                	li	s7,1
    8000405c:	a865                	j	80004114 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000405e:	4585                	li	a1,1
    80004060:	4505                	li	a0,1
    80004062:	fffff097          	auipc	ra,0xfffff
    80004066:	6e2080e7          	jalr	1762(ra) # 80003744 <iget>
    8000406a:	89aa                	mv	s3,a0
    8000406c:	b7dd                	j	80004052 <namex+0x42>
    {
      iunlockput(ip);
    8000406e:	854e                	mv	a0,s3
    80004070:	00000097          	auipc	ra,0x0
    80004074:	c6e080e7          	jalr	-914(ra) # 80003cde <iunlockput>
      return 0;
    80004078:	4981                	li	s3,0
  {
    iput(ip);
    return 0;
  }
  return ip;
}
    8000407a:	854e                	mv	a0,s3
    8000407c:	60e6                	ld	ra,88(sp)
    8000407e:	6446                	ld	s0,80(sp)
    80004080:	64a6                	ld	s1,72(sp)
    80004082:	6906                	ld	s2,64(sp)
    80004084:	79e2                	ld	s3,56(sp)
    80004086:	7a42                	ld	s4,48(sp)
    80004088:	7aa2                	ld	s5,40(sp)
    8000408a:	7b02                	ld	s6,32(sp)
    8000408c:	6be2                	ld	s7,24(sp)
    8000408e:	6c42                	ld	s8,16(sp)
    80004090:	6ca2                	ld	s9,8(sp)
    80004092:	6125                	addi	sp,sp,96
    80004094:	8082                	ret
      iunlock(ip);
    80004096:	854e                	mv	a0,s3
    80004098:	00000097          	auipc	ra,0x0
    8000409c:	aa6080e7          	jalr	-1370(ra) # 80003b3e <iunlock>
      return ip;
    800040a0:	bfe9                	j	8000407a <namex+0x6a>
      iunlockput(ip);
    800040a2:	854e                	mv	a0,s3
    800040a4:	00000097          	auipc	ra,0x0
    800040a8:	c3a080e7          	jalr	-966(ra) # 80003cde <iunlockput>
      return 0;
    800040ac:	89e6                	mv	s3,s9
    800040ae:	b7f1                	j	8000407a <namex+0x6a>
  len = path - s;
    800040b0:	40b48633          	sub	a2,s1,a1
    800040b4:	00060c9b          	sext.w	s9,a2
  if (len >= DIRSIZ)
    800040b8:	099c5463          	bge	s8,s9,80004140 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800040bc:	4639                	li	a2,14
    800040be:	8552                	mv	a0,s4
    800040c0:	ffffd097          	auipc	ra,0xffffd
    800040c4:	c6e080e7          	jalr	-914(ra) # 80000d2e <memmove>
  while (*path == '/')
    800040c8:	0004c783          	lbu	a5,0(s1)
    800040cc:	01279763          	bne	a5,s2,800040da <namex+0xca>
    path++;
    800040d0:	0485                	addi	s1,s1,1
  while (*path == '/')
    800040d2:	0004c783          	lbu	a5,0(s1)
    800040d6:	ff278de3          	beq	a5,s2,800040d0 <namex+0xc0>
    ilock(ip);
    800040da:	854e                	mv	a0,s3
    800040dc:	00000097          	auipc	ra,0x0
    800040e0:	9a0080e7          	jalr	-1632(ra) # 80003a7c <ilock>
    if (ip->type != T_DIR)
    800040e4:	04499783          	lh	a5,68(s3)
    800040e8:	f97793e3          	bne	a5,s7,8000406e <namex+0x5e>
    if (nameiparent && *path == '\0')
    800040ec:	000a8563          	beqz	s5,800040f6 <namex+0xe6>
    800040f0:	0004c783          	lbu	a5,0(s1)
    800040f4:	d3cd                	beqz	a5,80004096 <namex+0x86>
    if ((next = dirlookup(ip, name, 0)) == 0)
    800040f6:	865a                	mv	a2,s6
    800040f8:	85d2                	mv	a1,s4
    800040fa:	854e                	mv	a0,s3
    800040fc:	00000097          	auipc	ra,0x0
    80004100:	e64080e7          	jalr	-412(ra) # 80003f60 <dirlookup>
    80004104:	8caa                	mv	s9,a0
    80004106:	dd51                	beqz	a0,800040a2 <namex+0x92>
    iunlockput(ip);
    80004108:	854e                	mv	a0,s3
    8000410a:	00000097          	auipc	ra,0x0
    8000410e:	bd4080e7          	jalr	-1068(ra) # 80003cde <iunlockput>
    ip = next;
    80004112:	89e6                	mv	s3,s9
  while (*path == '/')
    80004114:	0004c783          	lbu	a5,0(s1)
    80004118:	05279763          	bne	a5,s2,80004166 <namex+0x156>
    path++;
    8000411c:	0485                	addi	s1,s1,1
  while (*path == '/')
    8000411e:	0004c783          	lbu	a5,0(s1)
    80004122:	ff278de3          	beq	a5,s2,8000411c <namex+0x10c>
  if (*path == 0)
    80004126:	c79d                	beqz	a5,80004154 <namex+0x144>
    path++;
    80004128:	85a6                	mv	a1,s1
  len = path - s;
    8000412a:	8cda                	mv	s9,s6
    8000412c:	865a                	mv	a2,s6
  while (*path != '/' && *path != 0)
    8000412e:	01278963          	beq	a5,s2,80004140 <namex+0x130>
    80004132:	dfbd                	beqz	a5,800040b0 <namex+0xa0>
    path++;
    80004134:	0485                	addi	s1,s1,1
  while (*path != '/' && *path != 0)
    80004136:	0004c783          	lbu	a5,0(s1)
    8000413a:	ff279ce3          	bne	a5,s2,80004132 <namex+0x122>
    8000413e:	bf8d                	j	800040b0 <namex+0xa0>
    memmove(name, s, len);
    80004140:	2601                	sext.w	a2,a2
    80004142:	8552                	mv	a0,s4
    80004144:	ffffd097          	auipc	ra,0xffffd
    80004148:	bea080e7          	jalr	-1046(ra) # 80000d2e <memmove>
    name[len] = 0;
    8000414c:	9cd2                	add	s9,s9,s4
    8000414e:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004152:	bf9d                	j	800040c8 <namex+0xb8>
  if (nameiparent)
    80004154:	f20a83e3          	beqz	s5,8000407a <namex+0x6a>
    iput(ip);
    80004158:	854e                	mv	a0,s3
    8000415a:	00000097          	auipc	ra,0x0
    8000415e:	adc080e7          	jalr	-1316(ra) # 80003c36 <iput>
    return 0;
    80004162:	4981                	li	s3,0
    80004164:	bf19                	j	8000407a <namex+0x6a>
  if (*path == 0)
    80004166:	d7fd                	beqz	a5,80004154 <namex+0x144>
  while (*path != '/' && *path != 0)
    80004168:	0004c783          	lbu	a5,0(s1)
    8000416c:	85a6                	mv	a1,s1
    8000416e:	b7d1                	j	80004132 <namex+0x122>

0000000080004170 <dirlink>:
{
    80004170:	7139                	addi	sp,sp,-64
    80004172:	fc06                	sd	ra,56(sp)
    80004174:	f822                	sd	s0,48(sp)
    80004176:	f426                	sd	s1,40(sp)
    80004178:	f04a                	sd	s2,32(sp)
    8000417a:	ec4e                	sd	s3,24(sp)
    8000417c:	e852                	sd	s4,16(sp)
    8000417e:	0080                	addi	s0,sp,64
    80004180:	892a                	mv	s2,a0
    80004182:	8a2e                	mv	s4,a1
    80004184:	89b2                	mv	s3,a2
  if ((ip = dirlookup(dp, name, 0)) != 0)
    80004186:	4601                	li	a2,0
    80004188:	00000097          	auipc	ra,0x0
    8000418c:	dd8080e7          	jalr	-552(ra) # 80003f60 <dirlookup>
    80004190:	e93d                	bnez	a0,80004206 <dirlink+0x96>
  for (off = 0; off < dp->size; off += sizeof(de))
    80004192:	04c92483          	lw	s1,76(s2)
    80004196:	c49d                	beqz	s1,800041c4 <dirlink+0x54>
    80004198:	4481                	li	s1,0
    if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000419a:	4741                	li	a4,16
    8000419c:	86a6                	mv	a3,s1
    8000419e:	fc040613          	addi	a2,s0,-64
    800041a2:	4581                	li	a1,0
    800041a4:	854a                	mv	a0,s2
    800041a6:	00000097          	auipc	ra,0x0
    800041aa:	b8a080e7          	jalr	-1142(ra) # 80003d30 <readi>
    800041ae:	47c1                	li	a5,16
    800041b0:	06f51163          	bne	a0,a5,80004212 <dirlink+0xa2>
    if (de.inum == 0)
    800041b4:	fc045783          	lhu	a5,-64(s0)
    800041b8:	c791                	beqz	a5,800041c4 <dirlink+0x54>
  for (off = 0; off < dp->size; off += sizeof(de))
    800041ba:	24c1                	addiw	s1,s1,16
    800041bc:	04c92783          	lw	a5,76(s2)
    800041c0:	fcf4ede3          	bltu	s1,a5,8000419a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800041c4:	4639                	li	a2,14
    800041c6:	85d2                	mv	a1,s4
    800041c8:	fc240513          	addi	a0,s0,-62
    800041cc:	ffffd097          	auipc	ra,0xffffd
    800041d0:	c12080e7          	jalr	-1006(ra) # 80000dde <strncpy>
  de.inum = inum;
    800041d4:	fd341023          	sh	s3,-64(s0)
  if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041d8:	4741                	li	a4,16
    800041da:	86a6                	mv	a3,s1
    800041dc:	fc040613          	addi	a2,s0,-64
    800041e0:	4581                	li	a1,0
    800041e2:	854a                	mv	a0,s2
    800041e4:	00000097          	auipc	ra,0x0
    800041e8:	c44080e7          	jalr	-956(ra) # 80003e28 <writei>
    800041ec:	1541                	addi	a0,a0,-16
    800041ee:	00a03533          	snez	a0,a0
    800041f2:	40a00533          	neg	a0,a0
}
    800041f6:	70e2                	ld	ra,56(sp)
    800041f8:	7442                	ld	s0,48(sp)
    800041fa:	74a2                	ld	s1,40(sp)
    800041fc:	7902                	ld	s2,32(sp)
    800041fe:	69e2                	ld	s3,24(sp)
    80004200:	6a42                	ld	s4,16(sp)
    80004202:	6121                	addi	sp,sp,64
    80004204:	8082                	ret
    iput(ip);
    80004206:	00000097          	auipc	ra,0x0
    8000420a:	a30080e7          	jalr	-1488(ra) # 80003c36 <iput>
    return -1;
    8000420e:	557d                	li	a0,-1
    80004210:	b7dd                	j	800041f6 <dirlink+0x86>
      panic("dirlink read");
    80004212:	00004517          	auipc	a0,0x4
    80004216:	4ae50513          	addi	a0,a0,1198 # 800086c0 <syscalls+0x1c8>
    8000421a:	ffffc097          	auipc	ra,0xffffc
    8000421e:	324080e7          	jalr	804(ra) # 8000053e <panic>

0000000080004222 <namei>:

struct inode *
namei(char *path)
{
    80004222:	1101                	addi	sp,sp,-32
    80004224:	ec06                	sd	ra,24(sp)
    80004226:	e822                	sd	s0,16(sp)
    80004228:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000422a:	fe040613          	addi	a2,s0,-32
    8000422e:	4581                	li	a1,0
    80004230:	00000097          	auipc	ra,0x0
    80004234:	de0080e7          	jalr	-544(ra) # 80004010 <namex>
}
    80004238:	60e2                	ld	ra,24(sp)
    8000423a:	6442                	ld	s0,16(sp)
    8000423c:	6105                	addi	sp,sp,32
    8000423e:	8082                	ret

0000000080004240 <nameiparent>:

struct inode *
nameiparent(char *path, char *name)
{
    80004240:	1141                	addi	sp,sp,-16
    80004242:	e406                	sd	ra,8(sp)
    80004244:	e022                	sd	s0,0(sp)
    80004246:	0800                	addi	s0,sp,16
    80004248:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000424a:	4585                	li	a1,1
    8000424c:	00000097          	auipc	ra,0x0
    80004250:	dc4080e7          	jalr	-572(ra) # 80004010 <namex>
}
    80004254:	60a2                	ld	ra,8(sp)
    80004256:	6402                	ld	s0,0(sp)
    80004258:	0141                	addi	sp,sp,16
    8000425a:	8082                	ret

000000008000425c <itoa>:

#include "fcntl.h"
#define DIGITS 14

char *itoa(int i, char b[])
{
    8000425c:	1101                	addi	sp,sp,-32
    8000425e:	ec22                	sd	s0,24(sp)
    80004260:	1000                	addi	s0,sp,32
    80004262:	872a                	mv	a4,a0
    80004264:	852e                	mv	a0,a1
  char const digit[] = "0123456789";
    80004266:	00004797          	auipc	a5,0x4
    8000426a:	46a78793          	addi	a5,a5,1130 # 800086d0 <syscalls+0x1d8>
    8000426e:	6394                	ld	a3,0(a5)
    80004270:	fed43023          	sd	a3,-32(s0)
    80004274:	0087d683          	lhu	a3,8(a5)
    80004278:	fed41423          	sh	a3,-24(s0)
    8000427c:	00a7c783          	lbu	a5,10(a5)
    80004280:	fef40523          	sb	a5,-22(s0)
  char *p = b;
    80004284:	87ae                	mv	a5,a1
  if (i < 0)
    80004286:	02074b63          	bltz	a4,800042bc <itoa+0x60>
  {
    *p++ = '-';
    i *= -1;
  }
  int shifter = i;
    8000428a:	86ba                	mv	a3,a4
  do
  { // Move to where representation ends
    ++p;
    shifter = shifter / 10;
    8000428c:	4629                	li	a2,10
    ++p;
    8000428e:	0785                	addi	a5,a5,1
    shifter = shifter / 10;
    80004290:	02c6c6bb          	divw	a3,a3,a2
  } while (shifter);
    80004294:	feed                	bnez	a3,8000428e <itoa+0x32>
  *p = '\0';
    80004296:	00078023          	sb	zero,0(a5)
  do
  { // Move back, inserting digits as u go
    *--p = digit[i % 10];
    8000429a:	4629                	li	a2,10
    8000429c:	17fd                	addi	a5,a5,-1
    8000429e:	02c766bb          	remw	a3,a4,a2
    800042a2:	ff040593          	addi	a1,s0,-16
    800042a6:	96ae                	add	a3,a3,a1
    800042a8:	ff06c683          	lbu	a3,-16(a3)
    800042ac:	00d78023          	sb	a3,0(a5)
    i = i / 10;
    800042b0:	02c7473b          	divw	a4,a4,a2
  } while (i);
    800042b4:	f765                	bnez	a4,8000429c <itoa+0x40>
  return b;
}
    800042b6:	6462                	ld	s0,24(sp)
    800042b8:	6105                	addi	sp,sp,32
    800042ba:	8082                	ret
    *p++ = '-';
    800042bc:	00158793          	addi	a5,a1,1
    800042c0:	02d00693          	li	a3,45
    800042c4:	00d58023          	sb	a3,0(a1)
    i *= -1;
    800042c8:	40e0073b          	negw	a4,a4
    800042cc:	bf7d                	j	8000428a <itoa+0x2e>

00000000800042ce <removeSwapFile>:
// remove swap file of proc p;
int removeSwapFile(struct proc *p)
{
    800042ce:	711d                	addi	sp,sp,-96
    800042d0:	ec86                	sd	ra,88(sp)
    800042d2:	e8a2                	sd	s0,80(sp)
    800042d4:	e4a6                	sd	s1,72(sp)
    800042d6:	e0ca                	sd	s2,64(sp)
    800042d8:	1080                	addi	s0,sp,96
    800042da:	84aa                	mv	s1,a0
  // path of proccess
  char path[DIGITS];
  memmove(path, "/.swap", 6);
    800042dc:	4619                	li	a2,6
    800042de:	00004597          	auipc	a1,0x4
    800042e2:	40258593          	addi	a1,a1,1026 # 800086e0 <syscalls+0x1e8>
    800042e6:	fd040513          	addi	a0,s0,-48
    800042ea:	ffffd097          	auipc	ra,0xffffd
    800042ee:	a44080e7          	jalr	-1468(ra) # 80000d2e <memmove>
  itoa(p->pid, path + 6);
    800042f2:	fd640593          	addi	a1,s0,-42
    800042f6:	5888                	lw	a0,48(s1)
    800042f8:	00000097          	auipc	ra,0x0
    800042fc:	f64080e7          	jalr	-156(ra) # 8000425c <itoa>
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ];
  uint off;

  if (0 == p->swapFile)
    80004300:	1684b503          	ld	a0,360(s1)
    80004304:	16050763          	beqz	a0,80004472 <removeSwapFile+0x1a4>
  {
    return -1;
  }
  fileclose(p->swapFile);
    80004308:	00001097          	auipc	ra,0x1
    8000430c:	914080e7          	jalr	-1772(ra) # 80004c1c <fileclose>

  begin_op();
    80004310:	00000097          	auipc	ra,0x0
    80004314:	440080e7          	jalr	1088(ra) # 80004750 <begin_op>
  if ((dp = nameiparent(path, name)) == 0)
    80004318:	fb040593          	addi	a1,s0,-80
    8000431c:	fd040513          	addi	a0,s0,-48
    80004320:	00000097          	auipc	ra,0x0
    80004324:	f20080e7          	jalr	-224(ra) # 80004240 <nameiparent>
    80004328:	892a                	mv	s2,a0
    8000432a:	cd69                	beqz	a0,80004404 <removeSwapFile+0x136>
  {
    end_op();
    return -1;
  }

  ilock(dp);
    8000432c:	fffff097          	auipc	ra,0xfffff
    80004330:	750080e7          	jalr	1872(ra) # 80003a7c <ilock>

  // Cannot unlink "." or "..".
  if (namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80004334:	00004597          	auipc	a1,0x4
    80004338:	3b458593          	addi	a1,a1,948 # 800086e8 <syscalls+0x1f0>
    8000433c:	fb040513          	addi	a0,s0,-80
    80004340:	00000097          	auipc	ra,0x0
    80004344:	c06080e7          	jalr	-1018(ra) # 80003f46 <namecmp>
    80004348:	c57d                	beqz	a0,80004436 <removeSwapFile+0x168>
    8000434a:	00004597          	auipc	a1,0x4
    8000434e:	3a658593          	addi	a1,a1,934 # 800086f0 <syscalls+0x1f8>
    80004352:	fb040513          	addi	a0,s0,-80
    80004356:	00000097          	auipc	ra,0x0
    8000435a:	bf0080e7          	jalr	-1040(ra) # 80003f46 <namecmp>
    8000435e:	cd61                	beqz	a0,80004436 <removeSwapFile+0x168>
    goto bad;

  if ((ip = dirlookup(dp, name, &off)) == 0)
    80004360:	fac40613          	addi	a2,s0,-84
    80004364:	fb040593          	addi	a1,s0,-80
    80004368:	854a                	mv	a0,s2
    8000436a:	00000097          	auipc	ra,0x0
    8000436e:	bf6080e7          	jalr	-1034(ra) # 80003f60 <dirlookup>
    80004372:	84aa                	mv	s1,a0
    80004374:	c169                	beqz	a0,80004436 <removeSwapFile+0x168>
    goto bad;
  ilock(ip);
    80004376:	fffff097          	auipc	ra,0xfffff
    8000437a:	706080e7          	jalr	1798(ra) # 80003a7c <ilock>

  if (ip->nlink < 1)
    8000437e:	04a49783          	lh	a5,74(s1)
    80004382:	08f05763          	blez	a5,80004410 <removeSwapFile+0x142>
    panic("unlink: nlink < 1");
  if (ip->type == T_DIR && !isdirempty(ip))
    80004386:	04449703          	lh	a4,68(s1)
    8000438a:	4785                	li	a5,1
    8000438c:	08f70a63          	beq	a4,a5,80004420 <removeSwapFile+0x152>
  {
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    80004390:	4641                	li	a2,16
    80004392:	4581                	li	a1,0
    80004394:	fc040513          	addi	a0,s0,-64
    80004398:	ffffd097          	auipc	ra,0xffffd
    8000439c:	93a080e7          	jalr	-1734(ra) # 80000cd2 <memset>
  if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043a0:	4741                	li	a4,16
    800043a2:	fac42683          	lw	a3,-84(s0)
    800043a6:	fc040613          	addi	a2,s0,-64
    800043aa:	4581                	li	a1,0
    800043ac:	854a                	mv	a0,s2
    800043ae:	00000097          	auipc	ra,0x0
    800043b2:	a7a080e7          	jalr	-1414(ra) # 80003e28 <writei>
    800043b6:	47c1                	li	a5,16
    800043b8:	08f51a63          	bne	a0,a5,8000444c <removeSwapFile+0x17e>
    panic("unlink: writei");
  if (ip->type == T_DIR)
    800043bc:	04449703          	lh	a4,68(s1)
    800043c0:	4785                	li	a5,1
    800043c2:	08f70d63          	beq	a4,a5,8000445c <removeSwapFile+0x18e>
  {
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    800043c6:	854a                	mv	a0,s2
    800043c8:	00000097          	auipc	ra,0x0
    800043cc:	916080e7          	jalr	-1770(ra) # 80003cde <iunlockput>

  ip->nlink--;
    800043d0:	04a4d783          	lhu	a5,74(s1)
    800043d4:	37fd                	addiw	a5,a5,-1
    800043d6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800043da:	8526                	mv	a0,s1
    800043dc:	fffff097          	auipc	ra,0xfffff
    800043e0:	5d6080e7          	jalr	1494(ra) # 800039b2 <iupdate>
  iunlockput(ip);
    800043e4:	8526                	mv	a0,s1
    800043e6:	00000097          	auipc	ra,0x0
    800043ea:	8f8080e7          	jalr	-1800(ra) # 80003cde <iunlockput>

  end_op();
    800043ee:	00000097          	auipc	ra,0x0
    800043f2:	3e2080e7          	jalr	994(ra) # 800047d0 <end_op>

  return 0;
    800043f6:	4501                	li	a0,0

bad:
  iunlockput(dp);
  end_op();
  return -1;
}
    800043f8:	60e6                	ld	ra,88(sp)
    800043fa:	6446                	ld	s0,80(sp)
    800043fc:	64a6                	ld	s1,72(sp)
    800043fe:	6906                	ld	s2,64(sp)
    80004400:	6125                	addi	sp,sp,96
    80004402:	8082                	ret
    end_op();
    80004404:	00000097          	auipc	ra,0x0
    80004408:	3cc080e7          	jalr	972(ra) # 800047d0 <end_op>
    return -1;
    8000440c:	557d                	li	a0,-1
    8000440e:	b7ed                	j	800043f8 <removeSwapFile+0x12a>
    panic("unlink: nlink < 1");
    80004410:	00004517          	auipc	a0,0x4
    80004414:	2e850513          	addi	a0,a0,744 # 800086f8 <syscalls+0x200>
    80004418:	ffffc097          	auipc	ra,0xffffc
    8000441c:	126080e7          	jalr	294(ra) # 8000053e <panic>
  if (ip->type == T_DIR && !isdirempty(ip))
    80004420:	8526                	mv	a0,s1
    80004422:	00001097          	auipc	ra,0x1
    80004426:	7f6080e7          	jalr	2038(ra) # 80005c18 <isdirempty>
    8000442a:	f13d                	bnez	a0,80004390 <removeSwapFile+0xc2>
    iunlockput(ip);
    8000442c:	8526                	mv	a0,s1
    8000442e:	00000097          	auipc	ra,0x0
    80004432:	8b0080e7          	jalr	-1872(ra) # 80003cde <iunlockput>
  iunlockput(dp);
    80004436:	854a                	mv	a0,s2
    80004438:	00000097          	auipc	ra,0x0
    8000443c:	8a6080e7          	jalr	-1882(ra) # 80003cde <iunlockput>
  end_op();
    80004440:	00000097          	auipc	ra,0x0
    80004444:	390080e7          	jalr	912(ra) # 800047d0 <end_op>
  return -1;
    80004448:	557d                	li	a0,-1
    8000444a:	b77d                	j	800043f8 <removeSwapFile+0x12a>
    panic("unlink: writei");
    8000444c:	00004517          	auipc	a0,0x4
    80004450:	2c450513          	addi	a0,a0,708 # 80008710 <syscalls+0x218>
    80004454:	ffffc097          	auipc	ra,0xffffc
    80004458:	0ea080e7          	jalr	234(ra) # 8000053e <panic>
    dp->nlink--;
    8000445c:	04a95783          	lhu	a5,74(s2)
    80004460:	37fd                	addiw	a5,a5,-1
    80004462:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80004466:	854a                	mv	a0,s2
    80004468:	fffff097          	auipc	ra,0xfffff
    8000446c:	54a080e7          	jalr	1354(ra) # 800039b2 <iupdate>
    80004470:	bf99                	j	800043c6 <removeSwapFile+0xf8>
    return -1;
    80004472:	557d                	li	a0,-1
    80004474:	b751                	j	800043f8 <removeSwapFile+0x12a>

0000000080004476 <createSwapFile>:

// return 0 on success
int createSwapFile(struct proc *p)
{
    80004476:	7179                	addi	sp,sp,-48
    80004478:	f406                	sd	ra,40(sp)
    8000447a:	f022                	sd	s0,32(sp)
    8000447c:	ec26                	sd	s1,24(sp)
    8000447e:	e84a                	sd	s2,16(sp)
    80004480:	1800                	addi	s0,sp,48
    80004482:	84aa                	mv	s1,a0

  char path[DIGITS];
  memmove(path, "/.swap", 6);
    80004484:	4619                	li	a2,6
    80004486:	00004597          	auipc	a1,0x4
    8000448a:	25a58593          	addi	a1,a1,602 # 800086e0 <syscalls+0x1e8>
    8000448e:	fd040513          	addi	a0,s0,-48
    80004492:	ffffd097          	auipc	ra,0xffffd
    80004496:	89c080e7          	jalr	-1892(ra) # 80000d2e <memmove>
  itoa(p->pid, path + 6);
    8000449a:	fd640593          	addi	a1,s0,-42
    8000449e:	5888                	lw	a0,48(s1)
    800044a0:	00000097          	auipc	ra,0x0
    800044a4:	dbc080e7          	jalr	-580(ra) # 8000425c <itoa>

  begin_op();
    800044a8:	00000097          	auipc	ra,0x0
    800044ac:	2a8080e7          	jalr	680(ra) # 80004750 <begin_op>

  struct inode *in = create(path, T_FILE, 0, 0);
    800044b0:	4681                	li	a3,0
    800044b2:	4601                	li	a2,0
    800044b4:	4589                	li	a1,2
    800044b6:	fd040513          	addi	a0,s0,-48
    800044ba:	00002097          	auipc	ra,0x2
    800044be:	952080e7          	jalr	-1710(ra) # 80005e0c <create>
    800044c2:	892a                	mv	s2,a0
  iunlock(in);
    800044c4:	fffff097          	auipc	ra,0xfffff
    800044c8:	67a080e7          	jalr	1658(ra) # 80003b3e <iunlock>
  p->swapFile = filealloc();
    800044cc:	00000097          	auipc	ra,0x0
    800044d0:	694080e7          	jalr	1684(ra) # 80004b60 <filealloc>
    800044d4:	16a4b423          	sd	a0,360(s1)
  if (p->swapFile == 0)
    800044d8:	cd1d                	beqz	a0,80004516 <createSwapFile+0xa0>
    panic("no slot for files on /store");

  p->swapFile->ip = in;
    800044da:	01253c23          	sd	s2,24(a0)
  p->swapFile->type = FD_INODE;
    800044de:	1684b703          	ld	a4,360(s1)
    800044e2:	4789                	li	a5,2
    800044e4:	c31c                	sw	a5,0(a4)
  p->swapFile->off = 0;
    800044e6:	1684b703          	ld	a4,360(s1)
    800044ea:	02072023          	sw	zero,32(a4) # 43020 <_entry-0x7ffbcfe0>
  p->swapFile->readable = O_WRONLY;
    800044ee:	1684b703          	ld	a4,360(s1)
    800044f2:	4685                	li	a3,1
    800044f4:	00d70423          	sb	a3,8(a4)
  p->swapFile->writable = O_RDWR;
    800044f8:	1684b703          	ld	a4,360(s1)
    800044fc:	00f704a3          	sb	a5,9(a4)
  end_op();
    80004500:	00000097          	auipc	ra,0x0
    80004504:	2d0080e7          	jalr	720(ra) # 800047d0 <end_op>

  return 0;
}
    80004508:	4501                	li	a0,0
    8000450a:	70a2                	ld	ra,40(sp)
    8000450c:	7402                	ld	s0,32(sp)
    8000450e:	64e2                	ld	s1,24(sp)
    80004510:	6942                	ld	s2,16(sp)
    80004512:	6145                	addi	sp,sp,48
    80004514:	8082                	ret
    panic("no slot for files on /store");
    80004516:	00004517          	auipc	a0,0x4
    8000451a:	20a50513          	addi	a0,a0,522 # 80008720 <syscalls+0x228>
    8000451e:	ffffc097          	auipc	ra,0xffffc
    80004522:	020080e7          	jalr	32(ra) # 8000053e <panic>

0000000080004526 <writeToSwapFile>:

// return as sys_write (-1 when error)
int writeToSwapFile(struct proc *p, char *buffer, uint placeOnFile, uint size)
{
    80004526:	1141                	addi	sp,sp,-16
    80004528:	e406                	sd	ra,8(sp)
    8000452a:	e022                	sd	s0,0(sp)
    8000452c:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    8000452e:	16853783          	ld	a5,360(a0)
    80004532:	d390                	sw	a2,32(a5)
  return kfilewrite(p->swapFile, (uint64)buffer, size);
    80004534:	8636                	mv	a2,a3
    80004536:	16853503          	ld	a0,360(a0)
    8000453a:	00001097          	auipc	ra,0x1
    8000453e:	ad4080e7          	jalr	-1324(ra) # 8000500e <kfilewrite>
}
    80004542:	60a2                	ld	ra,8(sp)
    80004544:	6402                	ld	s0,0(sp)
    80004546:	0141                	addi	sp,sp,16
    80004548:	8082                	ret

000000008000454a <readFromSwapFile>:

// return as sys_read (-1 when error)
int readFromSwapFile(struct proc *p, char *buffer, uint placeOnFile, uint size)
{
    8000454a:	1141                	addi	sp,sp,-16
    8000454c:	e406                	sd	ra,8(sp)
    8000454e:	e022                	sd	s0,0(sp)
    80004550:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    80004552:	16853783          	ld	a5,360(a0)
    80004556:	d390                	sw	a2,32(a5)
  return kfileread(p->swapFile, (uint64)buffer, size);
    80004558:	8636                	mv	a2,a3
    8000455a:	16853503          	ld	a0,360(a0)
    8000455e:	00001097          	auipc	ra,0x1
    80004562:	9ee080e7          	jalr	-1554(ra) # 80004f4c <kfileread>
    80004566:	60a2                	ld	ra,8(sp)
    80004568:	6402                	ld	s0,0(sp)
    8000456a:	0141                	addi	sp,sp,16
    8000456c:	8082                	ret

000000008000456e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000456e:	1101                	addi	sp,sp,-32
    80004570:	ec06                	sd	ra,24(sp)
    80004572:	e822                	sd	s0,16(sp)
    80004574:	e426                	sd	s1,8(sp)
    80004576:	e04a                	sd	s2,0(sp)
    80004578:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000457a:	00029917          	auipc	s2,0x29
    8000457e:	c8690913          	addi	s2,s2,-890 # 8002d200 <log>
    80004582:	01892583          	lw	a1,24(s2)
    80004586:	02892503          	lw	a0,40(s2)
    8000458a:	fffff097          	auipc	ra,0xfffff
    8000458e:	cd8080e7          	jalr	-808(ra) # 80003262 <bread>
    80004592:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004594:	02c92683          	lw	a3,44(s2)
    80004598:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000459a:	02d05763          	blez	a3,800045c8 <write_head+0x5a>
    8000459e:	00029797          	auipc	a5,0x29
    800045a2:	c9278793          	addi	a5,a5,-878 # 8002d230 <log+0x30>
    800045a6:	05c50713          	addi	a4,a0,92
    800045aa:	36fd                	addiw	a3,a3,-1
    800045ac:	1682                	slli	a3,a3,0x20
    800045ae:	9281                	srli	a3,a3,0x20
    800045b0:	068a                	slli	a3,a3,0x2
    800045b2:	00029617          	auipc	a2,0x29
    800045b6:	c8260613          	addi	a2,a2,-894 # 8002d234 <log+0x34>
    800045ba:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800045bc:	4390                	lw	a2,0(a5)
    800045be:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800045c0:	0791                	addi	a5,a5,4
    800045c2:	0711                	addi	a4,a4,4
    800045c4:	fed79ce3          	bne	a5,a3,800045bc <write_head+0x4e>
  }
  bwrite(buf);
    800045c8:	8526                	mv	a0,s1
    800045ca:	fffff097          	auipc	ra,0xfffff
    800045ce:	d8a080e7          	jalr	-630(ra) # 80003354 <bwrite>
  brelse(buf);
    800045d2:	8526                	mv	a0,s1
    800045d4:	fffff097          	auipc	ra,0xfffff
    800045d8:	dbe080e7          	jalr	-578(ra) # 80003392 <brelse>
}
    800045dc:	60e2                	ld	ra,24(sp)
    800045de:	6442                	ld	s0,16(sp)
    800045e0:	64a2                	ld	s1,8(sp)
    800045e2:	6902                	ld	s2,0(sp)
    800045e4:	6105                	addi	sp,sp,32
    800045e6:	8082                	ret

00000000800045e8 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800045e8:	00029797          	auipc	a5,0x29
    800045ec:	c447a783          	lw	a5,-956(a5) # 8002d22c <log+0x2c>
    800045f0:	0af05d63          	blez	a5,800046aa <install_trans+0xc2>
{
    800045f4:	7139                	addi	sp,sp,-64
    800045f6:	fc06                	sd	ra,56(sp)
    800045f8:	f822                	sd	s0,48(sp)
    800045fa:	f426                	sd	s1,40(sp)
    800045fc:	f04a                	sd	s2,32(sp)
    800045fe:	ec4e                	sd	s3,24(sp)
    80004600:	e852                	sd	s4,16(sp)
    80004602:	e456                	sd	s5,8(sp)
    80004604:	e05a                	sd	s6,0(sp)
    80004606:	0080                	addi	s0,sp,64
    80004608:	8b2a                	mv	s6,a0
    8000460a:	00029a97          	auipc	s5,0x29
    8000460e:	c26a8a93          	addi	s5,s5,-986 # 8002d230 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004612:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004614:	00029997          	auipc	s3,0x29
    80004618:	bec98993          	addi	s3,s3,-1044 # 8002d200 <log>
    8000461c:	a00d                	j	8000463e <install_trans+0x56>
    brelse(lbuf);
    8000461e:	854a                	mv	a0,s2
    80004620:	fffff097          	auipc	ra,0xfffff
    80004624:	d72080e7          	jalr	-654(ra) # 80003392 <brelse>
    brelse(dbuf);
    80004628:	8526                	mv	a0,s1
    8000462a:	fffff097          	auipc	ra,0xfffff
    8000462e:	d68080e7          	jalr	-664(ra) # 80003392 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004632:	2a05                	addiw	s4,s4,1
    80004634:	0a91                	addi	s5,s5,4
    80004636:	02c9a783          	lw	a5,44(s3)
    8000463a:	04fa5e63          	bge	s4,a5,80004696 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000463e:	0189a583          	lw	a1,24(s3)
    80004642:	014585bb          	addw	a1,a1,s4
    80004646:	2585                	addiw	a1,a1,1
    80004648:	0289a503          	lw	a0,40(s3)
    8000464c:	fffff097          	auipc	ra,0xfffff
    80004650:	c16080e7          	jalr	-1002(ra) # 80003262 <bread>
    80004654:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004656:	000aa583          	lw	a1,0(s5)
    8000465a:	0289a503          	lw	a0,40(s3)
    8000465e:	fffff097          	auipc	ra,0xfffff
    80004662:	c04080e7          	jalr	-1020(ra) # 80003262 <bread>
    80004666:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004668:	40000613          	li	a2,1024
    8000466c:	05890593          	addi	a1,s2,88
    80004670:	05850513          	addi	a0,a0,88
    80004674:	ffffc097          	auipc	ra,0xffffc
    80004678:	6ba080e7          	jalr	1722(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    8000467c:	8526                	mv	a0,s1
    8000467e:	fffff097          	auipc	ra,0xfffff
    80004682:	cd6080e7          	jalr	-810(ra) # 80003354 <bwrite>
    if(recovering == 0)
    80004686:	f80b1ce3          	bnez	s6,8000461e <install_trans+0x36>
      bunpin(dbuf);
    8000468a:	8526                	mv	a0,s1
    8000468c:	fffff097          	auipc	ra,0xfffff
    80004690:	de0080e7          	jalr	-544(ra) # 8000346c <bunpin>
    80004694:	b769                	j	8000461e <install_trans+0x36>
}
    80004696:	70e2                	ld	ra,56(sp)
    80004698:	7442                	ld	s0,48(sp)
    8000469a:	74a2                	ld	s1,40(sp)
    8000469c:	7902                	ld	s2,32(sp)
    8000469e:	69e2                	ld	s3,24(sp)
    800046a0:	6a42                	ld	s4,16(sp)
    800046a2:	6aa2                	ld	s5,8(sp)
    800046a4:	6b02                	ld	s6,0(sp)
    800046a6:	6121                	addi	sp,sp,64
    800046a8:	8082                	ret
    800046aa:	8082                	ret

00000000800046ac <initlog>:
{
    800046ac:	7179                	addi	sp,sp,-48
    800046ae:	f406                	sd	ra,40(sp)
    800046b0:	f022                	sd	s0,32(sp)
    800046b2:	ec26                	sd	s1,24(sp)
    800046b4:	e84a                	sd	s2,16(sp)
    800046b6:	e44e                	sd	s3,8(sp)
    800046b8:	1800                	addi	s0,sp,48
    800046ba:	892a                	mv	s2,a0
    800046bc:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800046be:	00029497          	auipc	s1,0x29
    800046c2:	b4248493          	addi	s1,s1,-1214 # 8002d200 <log>
    800046c6:	00004597          	auipc	a1,0x4
    800046ca:	07a58593          	addi	a1,a1,122 # 80008740 <syscalls+0x248>
    800046ce:	8526                	mv	a0,s1
    800046d0:	ffffc097          	auipc	ra,0xffffc
    800046d4:	476080e7          	jalr	1142(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    800046d8:	0149a583          	lw	a1,20(s3)
    800046dc:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800046de:	0109a783          	lw	a5,16(s3)
    800046e2:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800046e4:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800046e8:	854a                	mv	a0,s2
    800046ea:	fffff097          	auipc	ra,0xfffff
    800046ee:	b78080e7          	jalr	-1160(ra) # 80003262 <bread>
  log.lh.n = lh->n;
    800046f2:	4d34                	lw	a3,88(a0)
    800046f4:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800046f6:	02d05563          	blez	a3,80004720 <initlog+0x74>
    800046fa:	05c50793          	addi	a5,a0,92
    800046fe:	00029717          	auipc	a4,0x29
    80004702:	b3270713          	addi	a4,a4,-1230 # 8002d230 <log+0x30>
    80004706:	36fd                	addiw	a3,a3,-1
    80004708:	1682                	slli	a3,a3,0x20
    8000470a:	9281                	srli	a3,a3,0x20
    8000470c:	068a                	slli	a3,a3,0x2
    8000470e:	06050613          	addi	a2,a0,96
    80004712:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004714:	4390                	lw	a2,0(a5)
    80004716:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004718:	0791                	addi	a5,a5,4
    8000471a:	0711                	addi	a4,a4,4
    8000471c:	fed79ce3          	bne	a5,a3,80004714 <initlog+0x68>
  brelse(buf);
    80004720:	fffff097          	auipc	ra,0xfffff
    80004724:	c72080e7          	jalr	-910(ra) # 80003392 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004728:	4505                	li	a0,1
    8000472a:	00000097          	auipc	ra,0x0
    8000472e:	ebe080e7          	jalr	-322(ra) # 800045e8 <install_trans>
  log.lh.n = 0;
    80004732:	00029797          	auipc	a5,0x29
    80004736:	ae07ad23          	sw	zero,-1286(a5) # 8002d22c <log+0x2c>
  write_head(); // clear the log
    8000473a:	00000097          	auipc	ra,0x0
    8000473e:	e34080e7          	jalr	-460(ra) # 8000456e <write_head>
}
    80004742:	70a2                	ld	ra,40(sp)
    80004744:	7402                	ld	s0,32(sp)
    80004746:	64e2                	ld	s1,24(sp)
    80004748:	6942                	ld	s2,16(sp)
    8000474a:	69a2                	ld	s3,8(sp)
    8000474c:	6145                	addi	sp,sp,48
    8000474e:	8082                	ret

0000000080004750 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004750:	1101                	addi	sp,sp,-32
    80004752:	ec06                	sd	ra,24(sp)
    80004754:	e822                	sd	s0,16(sp)
    80004756:	e426                	sd	s1,8(sp)
    80004758:	e04a                	sd	s2,0(sp)
    8000475a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000475c:	00029517          	auipc	a0,0x29
    80004760:	aa450513          	addi	a0,a0,-1372 # 8002d200 <log>
    80004764:	ffffc097          	auipc	ra,0xffffc
    80004768:	472080e7          	jalr	1138(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    8000476c:	00029497          	auipc	s1,0x29
    80004770:	a9448493          	addi	s1,s1,-1388 # 8002d200 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004774:	4979                	li	s2,30
    80004776:	a039                	j	80004784 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004778:	85a6                	mv	a1,s1
    8000477a:	8526                	mv	a0,s1
    8000477c:	ffffe097          	auipc	ra,0xffffe
    80004780:	ab8080e7          	jalr	-1352(ra) # 80002234 <sleep>
    if(log.committing){
    80004784:	50dc                	lw	a5,36(s1)
    80004786:	fbed                	bnez	a5,80004778 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004788:	509c                	lw	a5,32(s1)
    8000478a:	0017871b          	addiw	a4,a5,1
    8000478e:	0007069b          	sext.w	a3,a4
    80004792:	0027179b          	slliw	a5,a4,0x2
    80004796:	9fb9                	addw	a5,a5,a4
    80004798:	0017979b          	slliw	a5,a5,0x1
    8000479c:	54d8                	lw	a4,44(s1)
    8000479e:	9fb9                	addw	a5,a5,a4
    800047a0:	00f95963          	bge	s2,a5,800047b2 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800047a4:	85a6                	mv	a1,s1
    800047a6:	8526                	mv	a0,s1
    800047a8:	ffffe097          	auipc	ra,0xffffe
    800047ac:	a8c080e7          	jalr	-1396(ra) # 80002234 <sleep>
    800047b0:	bfd1                	j	80004784 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800047b2:	00029517          	auipc	a0,0x29
    800047b6:	a4e50513          	addi	a0,a0,-1458 # 8002d200 <log>
    800047ba:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800047bc:	ffffc097          	auipc	ra,0xffffc
    800047c0:	4ce080e7          	jalr	1230(ra) # 80000c8a <release>
      break;
    }
  }
}
    800047c4:	60e2                	ld	ra,24(sp)
    800047c6:	6442                	ld	s0,16(sp)
    800047c8:	64a2                	ld	s1,8(sp)
    800047ca:	6902                	ld	s2,0(sp)
    800047cc:	6105                	addi	sp,sp,32
    800047ce:	8082                	ret

00000000800047d0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800047d0:	7139                	addi	sp,sp,-64
    800047d2:	fc06                	sd	ra,56(sp)
    800047d4:	f822                	sd	s0,48(sp)
    800047d6:	f426                	sd	s1,40(sp)
    800047d8:	f04a                	sd	s2,32(sp)
    800047da:	ec4e                	sd	s3,24(sp)
    800047dc:	e852                	sd	s4,16(sp)
    800047de:	e456                	sd	s5,8(sp)
    800047e0:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800047e2:	00029497          	auipc	s1,0x29
    800047e6:	a1e48493          	addi	s1,s1,-1506 # 8002d200 <log>
    800047ea:	8526                	mv	a0,s1
    800047ec:	ffffc097          	auipc	ra,0xffffc
    800047f0:	3ea080e7          	jalr	1002(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800047f4:	509c                	lw	a5,32(s1)
    800047f6:	37fd                	addiw	a5,a5,-1
    800047f8:	0007891b          	sext.w	s2,a5
    800047fc:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800047fe:	50dc                	lw	a5,36(s1)
    80004800:	e7b9                	bnez	a5,8000484e <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004802:	04091e63          	bnez	s2,8000485e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004806:	00029497          	auipc	s1,0x29
    8000480a:	9fa48493          	addi	s1,s1,-1542 # 8002d200 <log>
    8000480e:	4785                	li	a5,1
    80004810:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004812:	8526                	mv	a0,s1
    80004814:	ffffc097          	auipc	ra,0xffffc
    80004818:	476080e7          	jalr	1142(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000481c:	54dc                	lw	a5,44(s1)
    8000481e:	06f04763          	bgtz	a5,8000488c <end_op+0xbc>
    acquire(&log.lock);
    80004822:	00029497          	auipc	s1,0x29
    80004826:	9de48493          	addi	s1,s1,-1570 # 8002d200 <log>
    8000482a:	8526                	mv	a0,s1
    8000482c:	ffffc097          	auipc	ra,0xffffc
    80004830:	3aa080e7          	jalr	938(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004834:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004838:	8526                	mv	a0,s1
    8000483a:	ffffe097          	auipc	ra,0xffffe
    8000483e:	a5e080e7          	jalr	-1442(ra) # 80002298 <wakeup>
    release(&log.lock);
    80004842:	8526                	mv	a0,s1
    80004844:	ffffc097          	auipc	ra,0xffffc
    80004848:	446080e7          	jalr	1094(ra) # 80000c8a <release>
}
    8000484c:	a03d                	j	8000487a <end_op+0xaa>
    panic("log.committing");
    8000484e:	00004517          	auipc	a0,0x4
    80004852:	efa50513          	addi	a0,a0,-262 # 80008748 <syscalls+0x250>
    80004856:	ffffc097          	auipc	ra,0xffffc
    8000485a:	ce8080e7          	jalr	-792(ra) # 8000053e <panic>
    wakeup(&log);
    8000485e:	00029497          	auipc	s1,0x29
    80004862:	9a248493          	addi	s1,s1,-1630 # 8002d200 <log>
    80004866:	8526                	mv	a0,s1
    80004868:	ffffe097          	auipc	ra,0xffffe
    8000486c:	a30080e7          	jalr	-1488(ra) # 80002298 <wakeup>
  release(&log.lock);
    80004870:	8526                	mv	a0,s1
    80004872:	ffffc097          	auipc	ra,0xffffc
    80004876:	418080e7          	jalr	1048(ra) # 80000c8a <release>
}
    8000487a:	70e2                	ld	ra,56(sp)
    8000487c:	7442                	ld	s0,48(sp)
    8000487e:	74a2                	ld	s1,40(sp)
    80004880:	7902                	ld	s2,32(sp)
    80004882:	69e2                	ld	s3,24(sp)
    80004884:	6a42                	ld	s4,16(sp)
    80004886:	6aa2                	ld	s5,8(sp)
    80004888:	6121                	addi	sp,sp,64
    8000488a:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000488c:	00029a97          	auipc	s5,0x29
    80004890:	9a4a8a93          	addi	s5,s5,-1628 # 8002d230 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004894:	00029a17          	auipc	s4,0x29
    80004898:	96ca0a13          	addi	s4,s4,-1684 # 8002d200 <log>
    8000489c:	018a2583          	lw	a1,24(s4)
    800048a0:	012585bb          	addw	a1,a1,s2
    800048a4:	2585                	addiw	a1,a1,1
    800048a6:	028a2503          	lw	a0,40(s4)
    800048aa:	fffff097          	auipc	ra,0xfffff
    800048ae:	9b8080e7          	jalr	-1608(ra) # 80003262 <bread>
    800048b2:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800048b4:	000aa583          	lw	a1,0(s5)
    800048b8:	028a2503          	lw	a0,40(s4)
    800048bc:	fffff097          	auipc	ra,0xfffff
    800048c0:	9a6080e7          	jalr	-1626(ra) # 80003262 <bread>
    800048c4:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800048c6:	40000613          	li	a2,1024
    800048ca:	05850593          	addi	a1,a0,88
    800048ce:	05848513          	addi	a0,s1,88
    800048d2:	ffffc097          	auipc	ra,0xffffc
    800048d6:	45c080e7          	jalr	1116(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    800048da:	8526                	mv	a0,s1
    800048dc:	fffff097          	auipc	ra,0xfffff
    800048e0:	a78080e7          	jalr	-1416(ra) # 80003354 <bwrite>
    brelse(from);
    800048e4:	854e                	mv	a0,s3
    800048e6:	fffff097          	auipc	ra,0xfffff
    800048ea:	aac080e7          	jalr	-1364(ra) # 80003392 <brelse>
    brelse(to);
    800048ee:	8526                	mv	a0,s1
    800048f0:	fffff097          	auipc	ra,0xfffff
    800048f4:	aa2080e7          	jalr	-1374(ra) # 80003392 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048f8:	2905                	addiw	s2,s2,1
    800048fa:	0a91                	addi	s5,s5,4
    800048fc:	02ca2783          	lw	a5,44(s4)
    80004900:	f8f94ee3          	blt	s2,a5,8000489c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004904:	00000097          	auipc	ra,0x0
    80004908:	c6a080e7          	jalr	-918(ra) # 8000456e <write_head>
    install_trans(0); // Now install writes to home locations
    8000490c:	4501                	li	a0,0
    8000490e:	00000097          	auipc	ra,0x0
    80004912:	cda080e7          	jalr	-806(ra) # 800045e8 <install_trans>
    log.lh.n = 0;
    80004916:	00029797          	auipc	a5,0x29
    8000491a:	9007ab23          	sw	zero,-1770(a5) # 8002d22c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000491e:	00000097          	auipc	ra,0x0
    80004922:	c50080e7          	jalr	-944(ra) # 8000456e <write_head>
    80004926:	bdf5                	j	80004822 <end_op+0x52>

0000000080004928 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004928:	1101                	addi	sp,sp,-32
    8000492a:	ec06                	sd	ra,24(sp)
    8000492c:	e822                	sd	s0,16(sp)
    8000492e:	e426                	sd	s1,8(sp)
    80004930:	e04a                	sd	s2,0(sp)
    80004932:	1000                	addi	s0,sp,32
    80004934:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004936:	00029917          	auipc	s2,0x29
    8000493a:	8ca90913          	addi	s2,s2,-1846 # 8002d200 <log>
    8000493e:	854a                	mv	a0,s2
    80004940:	ffffc097          	auipc	ra,0xffffc
    80004944:	296080e7          	jalr	662(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004948:	02c92603          	lw	a2,44(s2)
    8000494c:	47f5                	li	a5,29
    8000494e:	06c7c563          	blt	a5,a2,800049b8 <log_write+0x90>
    80004952:	00029797          	auipc	a5,0x29
    80004956:	8ca7a783          	lw	a5,-1846(a5) # 8002d21c <log+0x1c>
    8000495a:	37fd                	addiw	a5,a5,-1
    8000495c:	04f65e63          	bge	a2,a5,800049b8 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004960:	00029797          	auipc	a5,0x29
    80004964:	8c07a783          	lw	a5,-1856(a5) # 8002d220 <log+0x20>
    80004968:	06f05063          	blez	a5,800049c8 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000496c:	4781                	li	a5,0
    8000496e:	06c05563          	blez	a2,800049d8 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004972:	44cc                	lw	a1,12(s1)
    80004974:	00029717          	auipc	a4,0x29
    80004978:	8bc70713          	addi	a4,a4,-1860 # 8002d230 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000497c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000497e:	4314                	lw	a3,0(a4)
    80004980:	04b68c63          	beq	a3,a1,800049d8 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004984:	2785                	addiw	a5,a5,1
    80004986:	0711                	addi	a4,a4,4
    80004988:	fef61be3          	bne	a2,a5,8000497e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000498c:	0621                	addi	a2,a2,8
    8000498e:	060a                	slli	a2,a2,0x2
    80004990:	00029797          	auipc	a5,0x29
    80004994:	87078793          	addi	a5,a5,-1936 # 8002d200 <log>
    80004998:	963e                	add	a2,a2,a5
    8000499a:	44dc                	lw	a5,12(s1)
    8000499c:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000499e:	8526                	mv	a0,s1
    800049a0:	fffff097          	auipc	ra,0xfffff
    800049a4:	a90080e7          	jalr	-1392(ra) # 80003430 <bpin>
    log.lh.n++;
    800049a8:	00029717          	auipc	a4,0x29
    800049ac:	85870713          	addi	a4,a4,-1960 # 8002d200 <log>
    800049b0:	575c                	lw	a5,44(a4)
    800049b2:	2785                	addiw	a5,a5,1
    800049b4:	d75c                	sw	a5,44(a4)
    800049b6:	a835                	j	800049f2 <log_write+0xca>
    panic("too big a transaction");
    800049b8:	00004517          	auipc	a0,0x4
    800049bc:	da050513          	addi	a0,a0,-608 # 80008758 <syscalls+0x260>
    800049c0:	ffffc097          	auipc	ra,0xffffc
    800049c4:	b7e080e7          	jalr	-1154(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800049c8:	00004517          	auipc	a0,0x4
    800049cc:	da850513          	addi	a0,a0,-600 # 80008770 <syscalls+0x278>
    800049d0:	ffffc097          	auipc	ra,0xffffc
    800049d4:	b6e080e7          	jalr	-1170(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800049d8:	00878713          	addi	a4,a5,8
    800049dc:	00271693          	slli	a3,a4,0x2
    800049e0:	00029717          	auipc	a4,0x29
    800049e4:	82070713          	addi	a4,a4,-2016 # 8002d200 <log>
    800049e8:	9736                	add	a4,a4,a3
    800049ea:	44d4                	lw	a3,12(s1)
    800049ec:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800049ee:	faf608e3          	beq	a2,a5,8000499e <log_write+0x76>
  }
  release(&log.lock);
    800049f2:	00029517          	auipc	a0,0x29
    800049f6:	80e50513          	addi	a0,a0,-2034 # 8002d200 <log>
    800049fa:	ffffc097          	auipc	ra,0xffffc
    800049fe:	290080e7          	jalr	656(ra) # 80000c8a <release>
}
    80004a02:	60e2                	ld	ra,24(sp)
    80004a04:	6442                	ld	s0,16(sp)
    80004a06:	64a2                	ld	s1,8(sp)
    80004a08:	6902                	ld	s2,0(sp)
    80004a0a:	6105                	addi	sp,sp,32
    80004a0c:	8082                	ret

0000000080004a0e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004a0e:	1101                	addi	sp,sp,-32
    80004a10:	ec06                	sd	ra,24(sp)
    80004a12:	e822                	sd	s0,16(sp)
    80004a14:	e426                	sd	s1,8(sp)
    80004a16:	e04a                	sd	s2,0(sp)
    80004a18:	1000                	addi	s0,sp,32
    80004a1a:	84aa                	mv	s1,a0
    80004a1c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004a1e:	00004597          	auipc	a1,0x4
    80004a22:	d7258593          	addi	a1,a1,-654 # 80008790 <syscalls+0x298>
    80004a26:	0521                	addi	a0,a0,8
    80004a28:	ffffc097          	auipc	ra,0xffffc
    80004a2c:	11e080e7          	jalr	286(ra) # 80000b46 <initlock>
  lk->name = name;
    80004a30:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004a34:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a38:	0204a423          	sw	zero,40(s1)
}
    80004a3c:	60e2                	ld	ra,24(sp)
    80004a3e:	6442                	ld	s0,16(sp)
    80004a40:	64a2                	ld	s1,8(sp)
    80004a42:	6902                	ld	s2,0(sp)
    80004a44:	6105                	addi	sp,sp,32
    80004a46:	8082                	ret

0000000080004a48 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004a48:	1101                	addi	sp,sp,-32
    80004a4a:	ec06                	sd	ra,24(sp)
    80004a4c:	e822                	sd	s0,16(sp)
    80004a4e:	e426                	sd	s1,8(sp)
    80004a50:	e04a                	sd	s2,0(sp)
    80004a52:	1000                	addi	s0,sp,32
    80004a54:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a56:	00850913          	addi	s2,a0,8
    80004a5a:	854a                	mv	a0,s2
    80004a5c:	ffffc097          	auipc	ra,0xffffc
    80004a60:	17a080e7          	jalr	378(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004a64:	409c                	lw	a5,0(s1)
    80004a66:	cb89                	beqz	a5,80004a78 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004a68:	85ca                	mv	a1,s2
    80004a6a:	8526                	mv	a0,s1
    80004a6c:	ffffd097          	auipc	ra,0xffffd
    80004a70:	7c8080e7          	jalr	1992(ra) # 80002234 <sleep>
  while (lk->locked) {
    80004a74:	409c                	lw	a5,0(s1)
    80004a76:	fbed                	bnez	a5,80004a68 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004a78:	4785                	li	a5,1
    80004a7a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004a7c:	ffffd097          	auipc	ra,0xffffd
    80004a80:	07c080e7          	jalr	124(ra) # 80001af8 <myproc>
    80004a84:	591c                	lw	a5,48(a0)
    80004a86:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004a88:	854a                	mv	a0,s2
    80004a8a:	ffffc097          	auipc	ra,0xffffc
    80004a8e:	200080e7          	jalr	512(ra) # 80000c8a <release>
}
    80004a92:	60e2                	ld	ra,24(sp)
    80004a94:	6442                	ld	s0,16(sp)
    80004a96:	64a2                	ld	s1,8(sp)
    80004a98:	6902                	ld	s2,0(sp)
    80004a9a:	6105                	addi	sp,sp,32
    80004a9c:	8082                	ret

0000000080004a9e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004a9e:	1101                	addi	sp,sp,-32
    80004aa0:	ec06                	sd	ra,24(sp)
    80004aa2:	e822                	sd	s0,16(sp)
    80004aa4:	e426                	sd	s1,8(sp)
    80004aa6:	e04a                	sd	s2,0(sp)
    80004aa8:	1000                	addi	s0,sp,32
    80004aaa:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004aac:	00850913          	addi	s2,a0,8
    80004ab0:	854a                	mv	a0,s2
    80004ab2:	ffffc097          	auipc	ra,0xffffc
    80004ab6:	124080e7          	jalr	292(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004aba:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004abe:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004ac2:	8526                	mv	a0,s1
    80004ac4:	ffffd097          	auipc	ra,0xffffd
    80004ac8:	7d4080e7          	jalr	2004(ra) # 80002298 <wakeup>
  release(&lk->lk);
    80004acc:	854a                	mv	a0,s2
    80004ace:	ffffc097          	auipc	ra,0xffffc
    80004ad2:	1bc080e7          	jalr	444(ra) # 80000c8a <release>
}
    80004ad6:	60e2                	ld	ra,24(sp)
    80004ad8:	6442                	ld	s0,16(sp)
    80004ada:	64a2                	ld	s1,8(sp)
    80004adc:	6902                	ld	s2,0(sp)
    80004ade:	6105                	addi	sp,sp,32
    80004ae0:	8082                	ret

0000000080004ae2 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004ae2:	7179                	addi	sp,sp,-48
    80004ae4:	f406                	sd	ra,40(sp)
    80004ae6:	f022                	sd	s0,32(sp)
    80004ae8:	ec26                	sd	s1,24(sp)
    80004aea:	e84a                	sd	s2,16(sp)
    80004aec:	e44e                	sd	s3,8(sp)
    80004aee:	1800                	addi	s0,sp,48
    80004af0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004af2:	00850913          	addi	s2,a0,8
    80004af6:	854a                	mv	a0,s2
    80004af8:	ffffc097          	auipc	ra,0xffffc
    80004afc:	0de080e7          	jalr	222(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b00:	409c                	lw	a5,0(s1)
    80004b02:	ef99                	bnez	a5,80004b20 <holdingsleep+0x3e>
    80004b04:	4481                	li	s1,0
  release(&lk->lk);
    80004b06:	854a                	mv	a0,s2
    80004b08:	ffffc097          	auipc	ra,0xffffc
    80004b0c:	182080e7          	jalr	386(ra) # 80000c8a <release>
  return r;
}
    80004b10:	8526                	mv	a0,s1
    80004b12:	70a2                	ld	ra,40(sp)
    80004b14:	7402                	ld	s0,32(sp)
    80004b16:	64e2                	ld	s1,24(sp)
    80004b18:	6942                	ld	s2,16(sp)
    80004b1a:	69a2                	ld	s3,8(sp)
    80004b1c:	6145                	addi	sp,sp,48
    80004b1e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b20:	0284a983          	lw	s3,40(s1)
    80004b24:	ffffd097          	auipc	ra,0xffffd
    80004b28:	fd4080e7          	jalr	-44(ra) # 80001af8 <myproc>
    80004b2c:	5904                	lw	s1,48(a0)
    80004b2e:	413484b3          	sub	s1,s1,s3
    80004b32:	0014b493          	seqz	s1,s1
    80004b36:	bfc1                	j	80004b06 <holdingsleep+0x24>

0000000080004b38 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004b38:	1141                	addi	sp,sp,-16
    80004b3a:	e406                	sd	ra,8(sp)
    80004b3c:	e022                	sd	s0,0(sp)
    80004b3e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004b40:	00004597          	auipc	a1,0x4
    80004b44:	c6058593          	addi	a1,a1,-928 # 800087a0 <syscalls+0x2a8>
    80004b48:	00029517          	auipc	a0,0x29
    80004b4c:	80050513          	addi	a0,a0,-2048 # 8002d348 <ftable>
    80004b50:	ffffc097          	auipc	ra,0xffffc
    80004b54:	ff6080e7          	jalr	-10(ra) # 80000b46 <initlock>
}
    80004b58:	60a2                	ld	ra,8(sp)
    80004b5a:	6402                	ld	s0,0(sp)
    80004b5c:	0141                	addi	sp,sp,16
    80004b5e:	8082                	ret

0000000080004b60 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004b60:	1101                	addi	sp,sp,-32
    80004b62:	ec06                	sd	ra,24(sp)
    80004b64:	e822                	sd	s0,16(sp)
    80004b66:	e426                	sd	s1,8(sp)
    80004b68:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004b6a:	00028517          	auipc	a0,0x28
    80004b6e:	7de50513          	addi	a0,a0,2014 # 8002d348 <ftable>
    80004b72:	ffffc097          	auipc	ra,0xffffc
    80004b76:	064080e7          	jalr	100(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b7a:	00028497          	auipc	s1,0x28
    80004b7e:	7e648493          	addi	s1,s1,2022 # 8002d360 <ftable+0x18>
    80004b82:	00029717          	auipc	a4,0x29
    80004b86:	77e70713          	addi	a4,a4,1918 # 8002e300 <disk>
    if(f->ref == 0){
    80004b8a:	40dc                	lw	a5,4(s1)
    80004b8c:	cf99                	beqz	a5,80004baa <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b8e:	02848493          	addi	s1,s1,40
    80004b92:	fee49ce3          	bne	s1,a4,80004b8a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004b96:	00028517          	auipc	a0,0x28
    80004b9a:	7b250513          	addi	a0,a0,1970 # 8002d348 <ftable>
    80004b9e:	ffffc097          	auipc	ra,0xffffc
    80004ba2:	0ec080e7          	jalr	236(ra) # 80000c8a <release>
  return 0;
    80004ba6:	4481                	li	s1,0
    80004ba8:	a819                	j	80004bbe <filealloc+0x5e>
      f->ref = 1;
    80004baa:	4785                	li	a5,1
    80004bac:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004bae:	00028517          	auipc	a0,0x28
    80004bb2:	79a50513          	addi	a0,a0,1946 # 8002d348 <ftable>
    80004bb6:	ffffc097          	auipc	ra,0xffffc
    80004bba:	0d4080e7          	jalr	212(ra) # 80000c8a <release>
}
    80004bbe:	8526                	mv	a0,s1
    80004bc0:	60e2                	ld	ra,24(sp)
    80004bc2:	6442                	ld	s0,16(sp)
    80004bc4:	64a2                	ld	s1,8(sp)
    80004bc6:	6105                	addi	sp,sp,32
    80004bc8:	8082                	ret

0000000080004bca <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004bca:	1101                	addi	sp,sp,-32
    80004bcc:	ec06                	sd	ra,24(sp)
    80004bce:	e822                	sd	s0,16(sp)
    80004bd0:	e426                	sd	s1,8(sp)
    80004bd2:	1000                	addi	s0,sp,32
    80004bd4:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004bd6:	00028517          	auipc	a0,0x28
    80004bda:	77250513          	addi	a0,a0,1906 # 8002d348 <ftable>
    80004bde:	ffffc097          	auipc	ra,0xffffc
    80004be2:	ff8080e7          	jalr	-8(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004be6:	40dc                	lw	a5,4(s1)
    80004be8:	02f05263          	blez	a5,80004c0c <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004bec:	2785                	addiw	a5,a5,1
    80004bee:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004bf0:	00028517          	auipc	a0,0x28
    80004bf4:	75850513          	addi	a0,a0,1880 # 8002d348 <ftable>
    80004bf8:	ffffc097          	auipc	ra,0xffffc
    80004bfc:	092080e7          	jalr	146(ra) # 80000c8a <release>
  return f;
}
    80004c00:	8526                	mv	a0,s1
    80004c02:	60e2                	ld	ra,24(sp)
    80004c04:	6442                	ld	s0,16(sp)
    80004c06:	64a2                	ld	s1,8(sp)
    80004c08:	6105                	addi	sp,sp,32
    80004c0a:	8082                	ret
    panic("filedup");
    80004c0c:	00004517          	auipc	a0,0x4
    80004c10:	b9c50513          	addi	a0,a0,-1124 # 800087a8 <syscalls+0x2b0>
    80004c14:	ffffc097          	auipc	ra,0xffffc
    80004c18:	92a080e7          	jalr	-1750(ra) # 8000053e <panic>

0000000080004c1c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004c1c:	7139                	addi	sp,sp,-64
    80004c1e:	fc06                	sd	ra,56(sp)
    80004c20:	f822                	sd	s0,48(sp)
    80004c22:	f426                	sd	s1,40(sp)
    80004c24:	f04a                	sd	s2,32(sp)
    80004c26:	ec4e                	sd	s3,24(sp)
    80004c28:	e852                	sd	s4,16(sp)
    80004c2a:	e456                	sd	s5,8(sp)
    80004c2c:	0080                	addi	s0,sp,64
    80004c2e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004c30:	00028517          	auipc	a0,0x28
    80004c34:	71850513          	addi	a0,a0,1816 # 8002d348 <ftable>
    80004c38:	ffffc097          	auipc	ra,0xffffc
    80004c3c:	f9e080e7          	jalr	-98(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004c40:	40dc                	lw	a5,4(s1)
    80004c42:	06f05163          	blez	a5,80004ca4 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004c46:	37fd                	addiw	a5,a5,-1
    80004c48:	0007871b          	sext.w	a4,a5
    80004c4c:	c0dc                	sw	a5,4(s1)
    80004c4e:	06e04363          	bgtz	a4,80004cb4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004c52:	0004a903          	lw	s2,0(s1)
    80004c56:	0094ca83          	lbu	s5,9(s1)
    80004c5a:	0104ba03          	ld	s4,16(s1)
    80004c5e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004c62:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004c66:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004c6a:	00028517          	auipc	a0,0x28
    80004c6e:	6de50513          	addi	a0,a0,1758 # 8002d348 <ftable>
    80004c72:	ffffc097          	auipc	ra,0xffffc
    80004c76:	018080e7          	jalr	24(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004c7a:	4785                	li	a5,1
    80004c7c:	04f90d63          	beq	s2,a5,80004cd6 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004c80:	3979                	addiw	s2,s2,-2
    80004c82:	4785                	li	a5,1
    80004c84:	0527e063          	bltu	a5,s2,80004cc4 <fileclose+0xa8>
    begin_op();
    80004c88:	00000097          	auipc	ra,0x0
    80004c8c:	ac8080e7          	jalr	-1336(ra) # 80004750 <begin_op>
    iput(ff.ip);
    80004c90:	854e                	mv	a0,s3
    80004c92:	fffff097          	auipc	ra,0xfffff
    80004c96:	fa4080e7          	jalr	-92(ra) # 80003c36 <iput>
    end_op();
    80004c9a:	00000097          	auipc	ra,0x0
    80004c9e:	b36080e7          	jalr	-1226(ra) # 800047d0 <end_op>
    80004ca2:	a00d                	j	80004cc4 <fileclose+0xa8>
    panic("fileclose");
    80004ca4:	00004517          	auipc	a0,0x4
    80004ca8:	b0c50513          	addi	a0,a0,-1268 # 800087b0 <syscalls+0x2b8>
    80004cac:	ffffc097          	auipc	ra,0xffffc
    80004cb0:	892080e7          	jalr	-1902(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004cb4:	00028517          	auipc	a0,0x28
    80004cb8:	69450513          	addi	a0,a0,1684 # 8002d348 <ftable>
    80004cbc:	ffffc097          	auipc	ra,0xffffc
    80004cc0:	fce080e7          	jalr	-50(ra) # 80000c8a <release>
  }
}
    80004cc4:	70e2                	ld	ra,56(sp)
    80004cc6:	7442                	ld	s0,48(sp)
    80004cc8:	74a2                	ld	s1,40(sp)
    80004cca:	7902                	ld	s2,32(sp)
    80004ccc:	69e2                	ld	s3,24(sp)
    80004cce:	6a42                	ld	s4,16(sp)
    80004cd0:	6aa2                	ld	s5,8(sp)
    80004cd2:	6121                	addi	sp,sp,64
    80004cd4:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004cd6:	85d6                	mv	a1,s5
    80004cd8:	8552                	mv	a0,s4
    80004cda:	00000097          	auipc	ra,0x0
    80004cde:	542080e7          	jalr	1346(ra) # 8000521c <pipeclose>
    80004ce2:	b7cd                	j	80004cc4 <fileclose+0xa8>

0000000080004ce4 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004ce4:	715d                	addi	sp,sp,-80
    80004ce6:	e486                	sd	ra,72(sp)
    80004ce8:	e0a2                	sd	s0,64(sp)
    80004cea:	fc26                	sd	s1,56(sp)
    80004cec:	f84a                	sd	s2,48(sp)
    80004cee:	f44e                	sd	s3,40(sp)
    80004cf0:	0880                	addi	s0,sp,80
    80004cf2:	84aa                	mv	s1,a0
    80004cf4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004cf6:	ffffd097          	auipc	ra,0xffffd
    80004cfa:	e02080e7          	jalr	-510(ra) # 80001af8 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004cfe:	409c                	lw	a5,0(s1)
    80004d00:	37f9                	addiw	a5,a5,-2
    80004d02:	4705                	li	a4,1
    80004d04:	04f76763          	bltu	a4,a5,80004d52 <filestat+0x6e>
    80004d08:	892a                	mv	s2,a0
    ilock(f->ip);
    80004d0a:	6c88                	ld	a0,24(s1)
    80004d0c:	fffff097          	auipc	ra,0xfffff
    80004d10:	d70080e7          	jalr	-656(ra) # 80003a7c <ilock>
    stati(f->ip, &st);
    80004d14:	fb840593          	addi	a1,s0,-72
    80004d18:	6c88                	ld	a0,24(s1)
    80004d1a:	fffff097          	auipc	ra,0xfffff
    80004d1e:	fec080e7          	jalr	-20(ra) # 80003d06 <stati>
    iunlock(f->ip);
    80004d22:	6c88                	ld	a0,24(s1)
    80004d24:	fffff097          	auipc	ra,0xfffff
    80004d28:	e1a080e7          	jalr	-486(ra) # 80003b3e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004d2c:	46e1                	li	a3,24
    80004d2e:	fb840613          	addi	a2,s0,-72
    80004d32:	85ce                	mv	a1,s3
    80004d34:	05093503          	ld	a0,80(s2)
    80004d38:	ffffd097          	auipc	ra,0xffffd
    80004d3c:	a7c080e7          	jalr	-1412(ra) # 800017b4 <copyout>
    80004d40:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004d44:	60a6                	ld	ra,72(sp)
    80004d46:	6406                	ld	s0,64(sp)
    80004d48:	74e2                	ld	s1,56(sp)
    80004d4a:	7942                	ld	s2,48(sp)
    80004d4c:	79a2                	ld	s3,40(sp)
    80004d4e:	6161                	addi	sp,sp,80
    80004d50:	8082                	ret
  return -1;
    80004d52:	557d                	li	a0,-1
    80004d54:	bfc5                	j	80004d44 <filestat+0x60>

0000000080004d56 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004d56:	7179                	addi	sp,sp,-48
    80004d58:	f406                	sd	ra,40(sp)
    80004d5a:	f022                	sd	s0,32(sp)
    80004d5c:	ec26                	sd	s1,24(sp)
    80004d5e:	e84a                	sd	s2,16(sp)
    80004d60:	e44e                	sd	s3,8(sp)
    80004d62:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004d64:	00854783          	lbu	a5,8(a0)
    80004d68:	c3d5                	beqz	a5,80004e0c <fileread+0xb6>
    80004d6a:	84aa                	mv	s1,a0
    80004d6c:	89ae                	mv	s3,a1
    80004d6e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d70:	411c                	lw	a5,0(a0)
    80004d72:	4705                	li	a4,1
    80004d74:	04e78963          	beq	a5,a4,80004dc6 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d78:	470d                	li	a4,3
    80004d7a:	04e78d63          	beq	a5,a4,80004dd4 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d7e:	4709                	li	a4,2
    80004d80:	06e79e63          	bne	a5,a4,80004dfc <fileread+0xa6>
    ilock(f->ip);
    80004d84:	6d08                	ld	a0,24(a0)
    80004d86:	fffff097          	auipc	ra,0xfffff
    80004d8a:	cf6080e7          	jalr	-778(ra) # 80003a7c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004d8e:	874a                	mv	a4,s2
    80004d90:	5094                	lw	a3,32(s1)
    80004d92:	864e                	mv	a2,s3
    80004d94:	4585                	li	a1,1
    80004d96:	6c88                	ld	a0,24(s1)
    80004d98:	fffff097          	auipc	ra,0xfffff
    80004d9c:	f98080e7          	jalr	-104(ra) # 80003d30 <readi>
    80004da0:	892a                	mv	s2,a0
    80004da2:	00a05563          	blez	a0,80004dac <fileread+0x56>
      f->off += r;
    80004da6:	509c                	lw	a5,32(s1)
    80004da8:	9fa9                	addw	a5,a5,a0
    80004daa:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004dac:	6c88                	ld	a0,24(s1)
    80004dae:	fffff097          	auipc	ra,0xfffff
    80004db2:	d90080e7          	jalr	-624(ra) # 80003b3e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004db6:	854a                	mv	a0,s2
    80004db8:	70a2                	ld	ra,40(sp)
    80004dba:	7402                	ld	s0,32(sp)
    80004dbc:	64e2                	ld	s1,24(sp)
    80004dbe:	6942                	ld	s2,16(sp)
    80004dc0:	69a2                	ld	s3,8(sp)
    80004dc2:	6145                	addi	sp,sp,48
    80004dc4:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004dc6:	6908                	ld	a0,16(a0)
    80004dc8:	00000097          	auipc	ra,0x0
    80004dcc:	5bc080e7          	jalr	1468(ra) # 80005384 <piperead>
    80004dd0:	892a                	mv	s2,a0
    80004dd2:	b7d5                	j	80004db6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004dd4:	02451783          	lh	a5,36(a0)
    80004dd8:	03079693          	slli	a3,a5,0x30
    80004ddc:	92c1                	srli	a3,a3,0x30
    80004dde:	4725                	li	a4,9
    80004de0:	02d76863          	bltu	a4,a3,80004e10 <fileread+0xba>
    80004de4:	0792                	slli	a5,a5,0x4
    80004de6:	00028717          	auipc	a4,0x28
    80004dea:	4c270713          	addi	a4,a4,1218 # 8002d2a8 <devsw>
    80004dee:	97ba                	add	a5,a5,a4
    80004df0:	639c                	ld	a5,0(a5)
    80004df2:	c38d                	beqz	a5,80004e14 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004df4:	4505                	li	a0,1
    80004df6:	9782                	jalr	a5
    80004df8:	892a                	mv	s2,a0
    80004dfa:	bf75                	j	80004db6 <fileread+0x60>
    panic("fileread");
    80004dfc:	00004517          	auipc	a0,0x4
    80004e00:	9c450513          	addi	a0,a0,-1596 # 800087c0 <syscalls+0x2c8>
    80004e04:	ffffb097          	auipc	ra,0xffffb
    80004e08:	73a080e7          	jalr	1850(ra) # 8000053e <panic>
    return -1;
    80004e0c:	597d                	li	s2,-1
    80004e0e:	b765                	j	80004db6 <fileread+0x60>
      return -1;
    80004e10:	597d                	li	s2,-1
    80004e12:	b755                	j	80004db6 <fileread+0x60>
    80004e14:	597d                	li	s2,-1
    80004e16:	b745                	j	80004db6 <fileread+0x60>

0000000080004e18 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004e18:	715d                	addi	sp,sp,-80
    80004e1a:	e486                	sd	ra,72(sp)
    80004e1c:	e0a2                	sd	s0,64(sp)
    80004e1e:	fc26                	sd	s1,56(sp)
    80004e20:	f84a                	sd	s2,48(sp)
    80004e22:	f44e                	sd	s3,40(sp)
    80004e24:	f052                	sd	s4,32(sp)
    80004e26:	ec56                	sd	s5,24(sp)
    80004e28:	e85a                	sd	s6,16(sp)
    80004e2a:	e45e                	sd	s7,8(sp)
    80004e2c:	e062                	sd	s8,0(sp)
    80004e2e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004e30:	00954783          	lbu	a5,9(a0)
    80004e34:	10078663          	beqz	a5,80004f40 <filewrite+0x128>
    80004e38:	892a                	mv	s2,a0
    80004e3a:	8aae                	mv	s5,a1
    80004e3c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e3e:	411c                	lw	a5,0(a0)
    80004e40:	4705                	li	a4,1
    80004e42:	02e78263          	beq	a5,a4,80004e66 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e46:	470d                	li	a4,3
    80004e48:	02e78663          	beq	a5,a4,80004e74 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e4c:	4709                	li	a4,2
    80004e4e:	0ee79163          	bne	a5,a4,80004f30 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004e52:	0ac05d63          	blez	a2,80004f0c <filewrite+0xf4>
    int i = 0;
    80004e56:	4981                	li	s3,0
    80004e58:	6b05                	lui	s6,0x1
    80004e5a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004e5e:	6b85                	lui	s7,0x1
    80004e60:	c00b8b9b          	addiw	s7,s7,-1024
    80004e64:	a861                	j	80004efc <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004e66:	6908                	ld	a0,16(a0)
    80004e68:	00000097          	auipc	ra,0x0
    80004e6c:	424080e7          	jalr	1060(ra) # 8000528c <pipewrite>
    80004e70:	8a2a                	mv	s4,a0
    80004e72:	a045                	j	80004f12 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004e74:	02451783          	lh	a5,36(a0)
    80004e78:	03079693          	slli	a3,a5,0x30
    80004e7c:	92c1                	srli	a3,a3,0x30
    80004e7e:	4725                	li	a4,9
    80004e80:	0cd76263          	bltu	a4,a3,80004f44 <filewrite+0x12c>
    80004e84:	0792                	slli	a5,a5,0x4
    80004e86:	00028717          	auipc	a4,0x28
    80004e8a:	42270713          	addi	a4,a4,1058 # 8002d2a8 <devsw>
    80004e8e:	97ba                	add	a5,a5,a4
    80004e90:	679c                	ld	a5,8(a5)
    80004e92:	cbdd                	beqz	a5,80004f48 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004e94:	4505                	li	a0,1
    80004e96:	9782                	jalr	a5
    80004e98:	8a2a                	mv	s4,a0
    80004e9a:	a8a5                	j	80004f12 <filewrite+0xfa>
    80004e9c:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004ea0:	00000097          	auipc	ra,0x0
    80004ea4:	8b0080e7          	jalr	-1872(ra) # 80004750 <begin_op>
      ilock(f->ip);
    80004ea8:	01893503          	ld	a0,24(s2)
    80004eac:	fffff097          	auipc	ra,0xfffff
    80004eb0:	bd0080e7          	jalr	-1072(ra) # 80003a7c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004eb4:	8762                	mv	a4,s8
    80004eb6:	02092683          	lw	a3,32(s2)
    80004eba:	01598633          	add	a2,s3,s5
    80004ebe:	4585                	li	a1,1
    80004ec0:	01893503          	ld	a0,24(s2)
    80004ec4:	fffff097          	auipc	ra,0xfffff
    80004ec8:	f64080e7          	jalr	-156(ra) # 80003e28 <writei>
    80004ecc:	84aa                	mv	s1,a0
    80004ece:	00a05763          	blez	a0,80004edc <filewrite+0xc4>
        f->off += r;
    80004ed2:	02092783          	lw	a5,32(s2)
    80004ed6:	9fa9                	addw	a5,a5,a0
    80004ed8:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004edc:	01893503          	ld	a0,24(s2)
    80004ee0:	fffff097          	auipc	ra,0xfffff
    80004ee4:	c5e080e7          	jalr	-930(ra) # 80003b3e <iunlock>
      end_op();
    80004ee8:	00000097          	auipc	ra,0x0
    80004eec:	8e8080e7          	jalr	-1816(ra) # 800047d0 <end_op>

      if(r != n1){
    80004ef0:	009c1f63          	bne	s8,s1,80004f0e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004ef4:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ef8:	0149db63          	bge	s3,s4,80004f0e <filewrite+0xf6>
      int n1 = n - i;
    80004efc:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004f00:	84be                	mv	s1,a5
    80004f02:	2781                	sext.w	a5,a5
    80004f04:	f8fb5ce3          	bge	s6,a5,80004e9c <filewrite+0x84>
    80004f08:	84de                	mv	s1,s7
    80004f0a:	bf49                	j	80004e9c <filewrite+0x84>
    int i = 0;
    80004f0c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004f0e:	013a1f63          	bne	s4,s3,80004f2c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004f12:	8552                	mv	a0,s4
    80004f14:	60a6                	ld	ra,72(sp)
    80004f16:	6406                	ld	s0,64(sp)
    80004f18:	74e2                	ld	s1,56(sp)
    80004f1a:	7942                	ld	s2,48(sp)
    80004f1c:	79a2                	ld	s3,40(sp)
    80004f1e:	7a02                	ld	s4,32(sp)
    80004f20:	6ae2                	ld	s5,24(sp)
    80004f22:	6b42                	ld	s6,16(sp)
    80004f24:	6ba2                	ld	s7,8(sp)
    80004f26:	6c02                	ld	s8,0(sp)
    80004f28:	6161                	addi	sp,sp,80
    80004f2a:	8082                	ret
    ret = (i == n ? n : -1);
    80004f2c:	5a7d                	li	s4,-1
    80004f2e:	b7d5                	j	80004f12 <filewrite+0xfa>
    panic("filewrite");
    80004f30:	00004517          	auipc	a0,0x4
    80004f34:	8a050513          	addi	a0,a0,-1888 # 800087d0 <syscalls+0x2d8>
    80004f38:	ffffb097          	auipc	ra,0xffffb
    80004f3c:	606080e7          	jalr	1542(ra) # 8000053e <panic>
    return -1;
    80004f40:	5a7d                	li	s4,-1
    80004f42:	bfc1                	j	80004f12 <filewrite+0xfa>
      return -1;
    80004f44:	5a7d                	li	s4,-1
    80004f46:	b7f1                	j	80004f12 <filewrite+0xfa>
    80004f48:	5a7d                	li	s4,-1
    80004f4a:	b7e1                	j	80004f12 <filewrite+0xfa>

0000000080004f4c <kfileread>:

// Read from file f.
// addr is a kernel virtual address.
int
kfileread(struct file *f, uint64 addr, int n)
{
    80004f4c:	7179                	addi	sp,sp,-48
    80004f4e:	f406                	sd	ra,40(sp)
    80004f50:	f022                	sd	s0,32(sp)
    80004f52:	ec26                	sd	s1,24(sp)
    80004f54:	e84a                	sd	s2,16(sp)
    80004f56:	e44e                	sd	s3,8(sp)
    80004f58:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004f5a:	00854783          	lbu	a5,8(a0)
    80004f5e:	c3d5                	beqz	a5,80005002 <kfileread+0xb6>
    80004f60:	84aa                	mv	s1,a0
    80004f62:	89ae                	mv	s3,a1
    80004f64:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004f66:	411c                	lw	a5,0(a0)
    80004f68:	4705                	li	a4,1
    80004f6a:	04e78963          	beq	a5,a4,80004fbc <kfileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004f6e:	470d                	li	a4,3
    80004f70:	04e78d63          	beq	a5,a4,80004fca <kfileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f74:	4709                	li	a4,2
    80004f76:	06e79e63          	bne	a5,a4,80004ff2 <kfileread+0xa6>
    ilock(f->ip);
    80004f7a:	6d08                	ld	a0,24(a0)
    80004f7c:	fffff097          	auipc	ra,0xfffff
    80004f80:	b00080e7          	jalr	-1280(ra) # 80003a7c <ilock>
    if((r = readi(f->ip, 0, addr, f->off, n)) > 0)
    80004f84:	874a                	mv	a4,s2
    80004f86:	5094                	lw	a3,32(s1)
    80004f88:	864e                	mv	a2,s3
    80004f8a:	4581                	li	a1,0
    80004f8c:	6c88                	ld	a0,24(s1)
    80004f8e:	fffff097          	auipc	ra,0xfffff
    80004f92:	da2080e7          	jalr	-606(ra) # 80003d30 <readi>
    80004f96:	892a                	mv	s2,a0
    80004f98:	00a05563          	blez	a0,80004fa2 <kfileread+0x56>
      f->off += r;
    80004f9c:	509c                	lw	a5,32(s1)
    80004f9e:	9fa9                	addw	a5,a5,a0
    80004fa0:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004fa2:	6c88                	ld	a0,24(s1)
    80004fa4:	fffff097          	auipc	ra,0xfffff
    80004fa8:	b9a080e7          	jalr	-1126(ra) # 80003b3e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004fac:	854a                	mv	a0,s2
    80004fae:	70a2                	ld	ra,40(sp)
    80004fb0:	7402                	ld	s0,32(sp)
    80004fb2:	64e2                	ld	s1,24(sp)
    80004fb4:	6942                	ld	s2,16(sp)
    80004fb6:	69a2                	ld	s3,8(sp)
    80004fb8:	6145                	addi	sp,sp,48
    80004fba:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004fbc:	6908                	ld	a0,16(a0)
    80004fbe:	00000097          	auipc	ra,0x0
    80004fc2:	3c6080e7          	jalr	966(ra) # 80005384 <piperead>
    80004fc6:	892a                	mv	s2,a0
    80004fc8:	b7d5                	j	80004fac <kfileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004fca:	02451783          	lh	a5,36(a0)
    80004fce:	03079693          	slli	a3,a5,0x30
    80004fd2:	92c1                	srli	a3,a3,0x30
    80004fd4:	4725                	li	a4,9
    80004fd6:	02d76863          	bltu	a4,a3,80005006 <kfileread+0xba>
    80004fda:	0792                	slli	a5,a5,0x4
    80004fdc:	00028717          	auipc	a4,0x28
    80004fe0:	2cc70713          	addi	a4,a4,716 # 8002d2a8 <devsw>
    80004fe4:	97ba                	add	a5,a5,a4
    80004fe6:	639c                	ld	a5,0(a5)
    80004fe8:	c38d                	beqz	a5,8000500a <kfileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004fea:	4505                	li	a0,1
    80004fec:	9782                	jalr	a5
    80004fee:	892a                	mv	s2,a0
    80004ff0:	bf75                	j	80004fac <kfileread+0x60>
    panic("fileread");
    80004ff2:	00003517          	auipc	a0,0x3
    80004ff6:	7ce50513          	addi	a0,a0,1998 # 800087c0 <syscalls+0x2c8>
    80004ffa:	ffffb097          	auipc	ra,0xffffb
    80004ffe:	544080e7          	jalr	1348(ra) # 8000053e <panic>
    return -1;
    80005002:	597d                	li	s2,-1
    80005004:	b765                	j	80004fac <kfileread+0x60>
      return -1;
    80005006:	597d                	li	s2,-1
    80005008:	b755                	j	80004fac <kfileread+0x60>
    8000500a:	597d                	li	s2,-1
    8000500c:	b745                	j	80004fac <kfileread+0x60>

000000008000500e <kfilewrite>:

// Write to file f.
// addr is a kernel virtual address.
int
kfilewrite(struct file *f, uint64 addr, int n)
{
    8000500e:	715d                	addi	sp,sp,-80
    80005010:	e486                	sd	ra,72(sp)
    80005012:	e0a2                	sd	s0,64(sp)
    80005014:	fc26                	sd	s1,56(sp)
    80005016:	f84a                	sd	s2,48(sp)
    80005018:	f44e                	sd	s3,40(sp)
    8000501a:	f052                	sd	s4,32(sp)
    8000501c:	ec56                	sd	s5,24(sp)
    8000501e:	e85a                	sd	s6,16(sp)
    80005020:	e45e                	sd	s7,8(sp)
    80005022:	e062                	sd	s8,0(sp)
    80005024:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005026:	00954783          	lbu	a5,9(a0)
    8000502a:	10078663          	beqz	a5,80005136 <kfilewrite+0x128>
    8000502e:	892a                	mv	s2,a0
    80005030:	8aae                	mv	s5,a1
    80005032:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005034:	411c                	lw	a5,0(a0)
    80005036:	4705                	li	a4,1
    80005038:	02e78263          	beq	a5,a4,8000505c <kfilewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000503c:	470d                	li	a4,3
    8000503e:	02e78663          	beq	a5,a4,8000506a <kfilewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005042:	4709                	li	a4,2
    80005044:	0ee79163          	bne	a5,a4,80005126 <kfilewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005048:	0ac05d63          	blez	a2,80005102 <kfilewrite+0xf4>
    int i = 0;
    8000504c:	4981                	li	s3,0
    8000504e:	6b05                	lui	s6,0x1
    80005050:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005054:	6b85                	lui	s7,0x1
    80005056:	c00b8b9b          	addiw	s7,s7,-1024
    8000505a:	a861                	j	800050f2 <kfilewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000505c:	6908                	ld	a0,16(a0)
    8000505e:	00000097          	auipc	ra,0x0
    80005062:	22e080e7          	jalr	558(ra) # 8000528c <pipewrite>
    80005066:	8a2a                	mv	s4,a0
    80005068:	a045                	j	80005108 <kfilewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000506a:	02451783          	lh	a5,36(a0)
    8000506e:	03079693          	slli	a3,a5,0x30
    80005072:	92c1                	srli	a3,a3,0x30
    80005074:	4725                	li	a4,9
    80005076:	0cd76263          	bltu	a4,a3,8000513a <kfilewrite+0x12c>
    8000507a:	0792                	slli	a5,a5,0x4
    8000507c:	00028717          	auipc	a4,0x28
    80005080:	22c70713          	addi	a4,a4,556 # 8002d2a8 <devsw>
    80005084:	97ba                	add	a5,a5,a4
    80005086:	679c                	ld	a5,8(a5)
    80005088:	cbdd                	beqz	a5,8000513e <kfilewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000508a:	4505                	li	a0,1
    8000508c:	9782                	jalr	a5
    8000508e:	8a2a                	mv	s4,a0
    80005090:	a8a5                	j	80005108 <kfilewrite+0xfa>
    80005092:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005096:	fffff097          	auipc	ra,0xfffff
    8000509a:	6ba080e7          	jalr	1722(ra) # 80004750 <begin_op>
      ilock(f->ip);
    8000509e:	01893503          	ld	a0,24(s2)
    800050a2:	fffff097          	auipc	ra,0xfffff
    800050a6:	9da080e7          	jalr	-1574(ra) # 80003a7c <ilock>
      if ((r = writei(f->ip, 0, addr + i, f->off, n1)) > 0)
    800050aa:	8762                	mv	a4,s8
    800050ac:	02092683          	lw	a3,32(s2)
    800050b0:	01598633          	add	a2,s3,s5
    800050b4:	4581                	li	a1,0
    800050b6:	01893503          	ld	a0,24(s2)
    800050ba:	fffff097          	auipc	ra,0xfffff
    800050be:	d6e080e7          	jalr	-658(ra) # 80003e28 <writei>
    800050c2:	84aa                	mv	s1,a0
    800050c4:	00a05763          	blez	a0,800050d2 <kfilewrite+0xc4>
        f->off += r;
    800050c8:	02092783          	lw	a5,32(s2)
    800050cc:	9fa9                	addw	a5,a5,a0
    800050ce:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800050d2:	01893503          	ld	a0,24(s2)
    800050d6:	fffff097          	auipc	ra,0xfffff
    800050da:	a68080e7          	jalr	-1432(ra) # 80003b3e <iunlock>
      end_op();
    800050de:	fffff097          	auipc	ra,0xfffff
    800050e2:	6f2080e7          	jalr	1778(ra) # 800047d0 <end_op>

      if(r != n1){
    800050e6:	009c1f63          	bne	s8,s1,80005104 <kfilewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800050ea:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800050ee:	0149db63          	bge	s3,s4,80005104 <kfilewrite+0xf6>
      int n1 = n - i;
    800050f2:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800050f6:	84be                	mv	s1,a5
    800050f8:	2781                	sext.w	a5,a5
    800050fa:	f8fb5ce3          	bge	s6,a5,80005092 <kfilewrite+0x84>
    800050fe:	84de                	mv	s1,s7
    80005100:	bf49                	j	80005092 <kfilewrite+0x84>
    int i = 0;
    80005102:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005104:	013a1f63          	bne	s4,s3,80005122 <kfilewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
    80005108:	8552                	mv	a0,s4
    8000510a:	60a6                	ld	ra,72(sp)
    8000510c:	6406                	ld	s0,64(sp)
    8000510e:	74e2                	ld	s1,56(sp)
    80005110:	7942                	ld	s2,48(sp)
    80005112:	79a2                	ld	s3,40(sp)
    80005114:	7a02                	ld	s4,32(sp)
    80005116:	6ae2                	ld	s5,24(sp)
    80005118:	6b42                	ld	s6,16(sp)
    8000511a:	6ba2                	ld	s7,8(sp)
    8000511c:	6c02                	ld	s8,0(sp)
    8000511e:	6161                	addi	sp,sp,80
    80005120:	8082                	ret
    ret = (i == n ? n : -1);
    80005122:	5a7d                	li	s4,-1
    80005124:	b7d5                	j	80005108 <kfilewrite+0xfa>
    panic("filewrite");
    80005126:	00003517          	auipc	a0,0x3
    8000512a:	6aa50513          	addi	a0,a0,1706 # 800087d0 <syscalls+0x2d8>
    8000512e:	ffffb097          	auipc	ra,0xffffb
    80005132:	410080e7          	jalr	1040(ra) # 8000053e <panic>
    return -1;
    80005136:	5a7d                	li	s4,-1
    80005138:	bfc1                	j	80005108 <kfilewrite+0xfa>
      return -1;
    8000513a:	5a7d                	li	s4,-1
    8000513c:	b7f1                	j	80005108 <kfilewrite+0xfa>
    8000513e:	5a7d                	li	s4,-1
    80005140:	b7e1                	j	80005108 <kfilewrite+0xfa>

0000000080005142 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005142:	7179                	addi	sp,sp,-48
    80005144:	f406                	sd	ra,40(sp)
    80005146:	f022                	sd	s0,32(sp)
    80005148:	ec26                	sd	s1,24(sp)
    8000514a:	e84a                	sd	s2,16(sp)
    8000514c:	e44e                	sd	s3,8(sp)
    8000514e:	e052                	sd	s4,0(sp)
    80005150:	1800                	addi	s0,sp,48
    80005152:	84aa                	mv	s1,a0
    80005154:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005156:	0005b023          	sd	zero,0(a1)
    8000515a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000515e:	00000097          	auipc	ra,0x0
    80005162:	a02080e7          	jalr	-1534(ra) # 80004b60 <filealloc>
    80005166:	e088                	sd	a0,0(s1)
    80005168:	c551                	beqz	a0,800051f4 <pipealloc+0xb2>
    8000516a:	00000097          	auipc	ra,0x0
    8000516e:	9f6080e7          	jalr	-1546(ra) # 80004b60 <filealloc>
    80005172:	00aa3023          	sd	a0,0(s4)
    80005176:	c92d                	beqz	a0,800051e8 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005178:	ffffc097          	auipc	ra,0xffffc
    8000517c:	96e080e7          	jalr	-1682(ra) # 80000ae6 <kalloc>
    80005180:	892a                	mv	s2,a0
    80005182:	c125                	beqz	a0,800051e2 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005184:	4985                	li	s3,1
    80005186:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000518a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000518e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005192:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005196:	00003597          	auipc	a1,0x3
    8000519a:	64a58593          	addi	a1,a1,1610 # 800087e0 <syscalls+0x2e8>
    8000519e:	ffffc097          	auipc	ra,0xffffc
    800051a2:	9a8080e7          	jalr	-1624(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    800051a6:	609c                	ld	a5,0(s1)
    800051a8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800051ac:	609c                	ld	a5,0(s1)
    800051ae:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800051b2:	609c                	ld	a5,0(s1)
    800051b4:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800051b8:	609c                	ld	a5,0(s1)
    800051ba:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800051be:	000a3783          	ld	a5,0(s4)
    800051c2:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800051c6:	000a3783          	ld	a5,0(s4)
    800051ca:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800051ce:	000a3783          	ld	a5,0(s4)
    800051d2:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800051d6:	000a3783          	ld	a5,0(s4)
    800051da:	0127b823          	sd	s2,16(a5)
  return 0;
    800051de:	4501                	li	a0,0
    800051e0:	a025                	j	80005208 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800051e2:	6088                	ld	a0,0(s1)
    800051e4:	e501                	bnez	a0,800051ec <pipealloc+0xaa>
    800051e6:	a039                	j	800051f4 <pipealloc+0xb2>
    800051e8:	6088                	ld	a0,0(s1)
    800051ea:	c51d                	beqz	a0,80005218 <pipealloc+0xd6>
    fileclose(*f0);
    800051ec:	00000097          	auipc	ra,0x0
    800051f0:	a30080e7          	jalr	-1488(ra) # 80004c1c <fileclose>
  if(*f1)
    800051f4:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800051f8:	557d                	li	a0,-1
  if(*f1)
    800051fa:	c799                	beqz	a5,80005208 <pipealloc+0xc6>
    fileclose(*f1);
    800051fc:	853e                	mv	a0,a5
    800051fe:	00000097          	auipc	ra,0x0
    80005202:	a1e080e7          	jalr	-1506(ra) # 80004c1c <fileclose>
  return -1;
    80005206:	557d                	li	a0,-1
}
    80005208:	70a2                	ld	ra,40(sp)
    8000520a:	7402                	ld	s0,32(sp)
    8000520c:	64e2                	ld	s1,24(sp)
    8000520e:	6942                	ld	s2,16(sp)
    80005210:	69a2                	ld	s3,8(sp)
    80005212:	6a02                	ld	s4,0(sp)
    80005214:	6145                	addi	sp,sp,48
    80005216:	8082                	ret
  return -1;
    80005218:	557d                	li	a0,-1
    8000521a:	b7fd                	j	80005208 <pipealloc+0xc6>

000000008000521c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000521c:	1101                	addi	sp,sp,-32
    8000521e:	ec06                	sd	ra,24(sp)
    80005220:	e822                	sd	s0,16(sp)
    80005222:	e426                	sd	s1,8(sp)
    80005224:	e04a                	sd	s2,0(sp)
    80005226:	1000                	addi	s0,sp,32
    80005228:	84aa                	mv	s1,a0
    8000522a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000522c:	ffffc097          	auipc	ra,0xffffc
    80005230:	9aa080e7          	jalr	-1622(ra) # 80000bd6 <acquire>
  if(writable){
    80005234:	02090d63          	beqz	s2,8000526e <pipeclose+0x52>
    pi->writeopen = 0;
    80005238:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000523c:	21848513          	addi	a0,s1,536
    80005240:	ffffd097          	auipc	ra,0xffffd
    80005244:	058080e7          	jalr	88(ra) # 80002298 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005248:	2204b783          	ld	a5,544(s1)
    8000524c:	eb95                	bnez	a5,80005280 <pipeclose+0x64>
    release(&pi->lock);
    8000524e:	8526                	mv	a0,s1
    80005250:	ffffc097          	auipc	ra,0xffffc
    80005254:	a3a080e7          	jalr	-1478(ra) # 80000c8a <release>
    kfree((char*)pi);
    80005258:	8526                	mv	a0,s1
    8000525a:	ffffb097          	auipc	ra,0xffffb
    8000525e:	790080e7          	jalr	1936(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80005262:	60e2                	ld	ra,24(sp)
    80005264:	6442                	ld	s0,16(sp)
    80005266:	64a2                	ld	s1,8(sp)
    80005268:	6902                	ld	s2,0(sp)
    8000526a:	6105                	addi	sp,sp,32
    8000526c:	8082                	ret
    pi->readopen = 0;
    8000526e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005272:	21c48513          	addi	a0,s1,540
    80005276:	ffffd097          	auipc	ra,0xffffd
    8000527a:	022080e7          	jalr	34(ra) # 80002298 <wakeup>
    8000527e:	b7e9                	j	80005248 <pipeclose+0x2c>
    release(&pi->lock);
    80005280:	8526                	mv	a0,s1
    80005282:	ffffc097          	auipc	ra,0xffffc
    80005286:	a08080e7          	jalr	-1528(ra) # 80000c8a <release>
}
    8000528a:	bfe1                	j	80005262 <pipeclose+0x46>

000000008000528c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000528c:	711d                	addi	sp,sp,-96
    8000528e:	ec86                	sd	ra,88(sp)
    80005290:	e8a2                	sd	s0,80(sp)
    80005292:	e4a6                	sd	s1,72(sp)
    80005294:	e0ca                	sd	s2,64(sp)
    80005296:	fc4e                	sd	s3,56(sp)
    80005298:	f852                	sd	s4,48(sp)
    8000529a:	f456                	sd	s5,40(sp)
    8000529c:	f05a                	sd	s6,32(sp)
    8000529e:	ec5e                	sd	s7,24(sp)
    800052a0:	e862                	sd	s8,16(sp)
    800052a2:	1080                	addi	s0,sp,96
    800052a4:	84aa                	mv	s1,a0
    800052a6:	8aae                	mv	s5,a1
    800052a8:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800052aa:	ffffd097          	auipc	ra,0xffffd
    800052ae:	84e080e7          	jalr	-1970(ra) # 80001af8 <myproc>
    800052b2:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800052b4:	8526                	mv	a0,s1
    800052b6:	ffffc097          	auipc	ra,0xffffc
    800052ba:	920080e7          	jalr	-1760(ra) # 80000bd6 <acquire>
  while(i < n){
    800052be:	0b405663          	blez	s4,8000536a <pipewrite+0xde>
  int i = 0;
    800052c2:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800052c4:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800052c6:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800052ca:	21c48b93          	addi	s7,s1,540
    800052ce:	a089                	j	80005310 <pipewrite+0x84>
      release(&pi->lock);
    800052d0:	8526                	mv	a0,s1
    800052d2:	ffffc097          	auipc	ra,0xffffc
    800052d6:	9b8080e7          	jalr	-1608(ra) # 80000c8a <release>
      return -1;
    800052da:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800052dc:	854a                	mv	a0,s2
    800052de:	60e6                	ld	ra,88(sp)
    800052e0:	6446                	ld	s0,80(sp)
    800052e2:	64a6                	ld	s1,72(sp)
    800052e4:	6906                	ld	s2,64(sp)
    800052e6:	79e2                	ld	s3,56(sp)
    800052e8:	7a42                	ld	s4,48(sp)
    800052ea:	7aa2                	ld	s5,40(sp)
    800052ec:	7b02                	ld	s6,32(sp)
    800052ee:	6be2                	ld	s7,24(sp)
    800052f0:	6c42                	ld	s8,16(sp)
    800052f2:	6125                	addi	sp,sp,96
    800052f4:	8082                	ret
      wakeup(&pi->nread);
    800052f6:	8562                	mv	a0,s8
    800052f8:	ffffd097          	auipc	ra,0xffffd
    800052fc:	fa0080e7          	jalr	-96(ra) # 80002298 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005300:	85a6                	mv	a1,s1
    80005302:	855e                	mv	a0,s7
    80005304:	ffffd097          	auipc	ra,0xffffd
    80005308:	f30080e7          	jalr	-208(ra) # 80002234 <sleep>
  while(i < n){
    8000530c:	07495063          	bge	s2,s4,8000536c <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80005310:	2204a783          	lw	a5,544(s1)
    80005314:	dfd5                	beqz	a5,800052d0 <pipewrite+0x44>
    80005316:	854e                	mv	a0,s3
    80005318:	ffffd097          	auipc	ra,0xffffd
    8000531c:	1da080e7          	jalr	474(ra) # 800024f2 <killed>
    80005320:	f945                	bnez	a0,800052d0 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005322:	2184a783          	lw	a5,536(s1)
    80005326:	21c4a703          	lw	a4,540(s1)
    8000532a:	2007879b          	addiw	a5,a5,512
    8000532e:	fcf704e3          	beq	a4,a5,800052f6 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005332:	4685                	li	a3,1
    80005334:	01590633          	add	a2,s2,s5
    80005338:	faf40593          	addi	a1,s0,-81
    8000533c:	0509b503          	ld	a0,80(s3)
    80005340:	ffffc097          	auipc	ra,0xffffc
    80005344:	500080e7          	jalr	1280(ra) # 80001840 <copyin>
    80005348:	03650263          	beq	a0,s6,8000536c <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000534c:	21c4a783          	lw	a5,540(s1)
    80005350:	0017871b          	addiw	a4,a5,1
    80005354:	20e4ae23          	sw	a4,540(s1)
    80005358:	1ff7f793          	andi	a5,a5,511
    8000535c:	97a6                	add	a5,a5,s1
    8000535e:	faf44703          	lbu	a4,-81(s0)
    80005362:	00e78c23          	sb	a4,24(a5)
      i++;
    80005366:	2905                	addiw	s2,s2,1
    80005368:	b755                	j	8000530c <pipewrite+0x80>
  int i = 0;
    8000536a:	4901                	li	s2,0
  wakeup(&pi->nread);
    8000536c:	21848513          	addi	a0,s1,536
    80005370:	ffffd097          	auipc	ra,0xffffd
    80005374:	f28080e7          	jalr	-216(ra) # 80002298 <wakeup>
  release(&pi->lock);
    80005378:	8526                	mv	a0,s1
    8000537a:	ffffc097          	auipc	ra,0xffffc
    8000537e:	910080e7          	jalr	-1776(ra) # 80000c8a <release>
  return i;
    80005382:	bfa9                	j	800052dc <pipewrite+0x50>

0000000080005384 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005384:	715d                	addi	sp,sp,-80
    80005386:	e486                	sd	ra,72(sp)
    80005388:	e0a2                	sd	s0,64(sp)
    8000538a:	fc26                	sd	s1,56(sp)
    8000538c:	f84a                	sd	s2,48(sp)
    8000538e:	f44e                	sd	s3,40(sp)
    80005390:	f052                	sd	s4,32(sp)
    80005392:	ec56                	sd	s5,24(sp)
    80005394:	e85a                	sd	s6,16(sp)
    80005396:	0880                	addi	s0,sp,80
    80005398:	84aa                	mv	s1,a0
    8000539a:	892e                	mv	s2,a1
    8000539c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000539e:	ffffc097          	auipc	ra,0xffffc
    800053a2:	75a080e7          	jalr	1882(ra) # 80001af8 <myproc>
    800053a6:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800053a8:	8526                	mv	a0,s1
    800053aa:	ffffc097          	auipc	ra,0xffffc
    800053ae:	82c080e7          	jalr	-2004(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800053b2:	2184a703          	lw	a4,536(s1)
    800053b6:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800053ba:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800053be:	02f71763          	bne	a4,a5,800053ec <piperead+0x68>
    800053c2:	2244a783          	lw	a5,548(s1)
    800053c6:	c39d                	beqz	a5,800053ec <piperead+0x68>
    if(killed(pr)){
    800053c8:	8552                	mv	a0,s4
    800053ca:	ffffd097          	auipc	ra,0xffffd
    800053ce:	128080e7          	jalr	296(ra) # 800024f2 <killed>
    800053d2:	e941                	bnez	a0,80005462 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800053d4:	85a6                	mv	a1,s1
    800053d6:	854e                	mv	a0,s3
    800053d8:	ffffd097          	auipc	ra,0xffffd
    800053dc:	e5c080e7          	jalr	-420(ra) # 80002234 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800053e0:	2184a703          	lw	a4,536(s1)
    800053e4:	21c4a783          	lw	a5,540(s1)
    800053e8:	fcf70de3          	beq	a4,a5,800053c2 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800053ec:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800053ee:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800053f0:	05505363          	blez	s5,80005436 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    800053f4:	2184a783          	lw	a5,536(s1)
    800053f8:	21c4a703          	lw	a4,540(s1)
    800053fc:	02f70d63          	beq	a4,a5,80005436 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005400:	0017871b          	addiw	a4,a5,1
    80005404:	20e4ac23          	sw	a4,536(s1)
    80005408:	1ff7f793          	andi	a5,a5,511
    8000540c:	97a6                	add	a5,a5,s1
    8000540e:	0187c783          	lbu	a5,24(a5)
    80005412:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005416:	4685                	li	a3,1
    80005418:	fbf40613          	addi	a2,s0,-65
    8000541c:	85ca                	mv	a1,s2
    8000541e:	050a3503          	ld	a0,80(s4)
    80005422:	ffffc097          	auipc	ra,0xffffc
    80005426:	392080e7          	jalr	914(ra) # 800017b4 <copyout>
    8000542a:	01650663          	beq	a0,s6,80005436 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000542e:	2985                	addiw	s3,s3,1
    80005430:	0905                	addi	s2,s2,1
    80005432:	fd3a91e3          	bne	s5,s3,800053f4 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005436:	21c48513          	addi	a0,s1,540
    8000543a:	ffffd097          	auipc	ra,0xffffd
    8000543e:	e5e080e7          	jalr	-418(ra) # 80002298 <wakeup>
  release(&pi->lock);
    80005442:	8526                	mv	a0,s1
    80005444:	ffffc097          	auipc	ra,0xffffc
    80005448:	846080e7          	jalr	-1978(ra) # 80000c8a <release>
  return i;
}
    8000544c:	854e                	mv	a0,s3
    8000544e:	60a6                	ld	ra,72(sp)
    80005450:	6406                	ld	s0,64(sp)
    80005452:	74e2                	ld	s1,56(sp)
    80005454:	7942                	ld	s2,48(sp)
    80005456:	79a2                	ld	s3,40(sp)
    80005458:	7a02                	ld	s4,32(sp)
    8000545a:	6ae2                	ld	s5,24(sp)
    8000545c:	6b42                	ld	s6,16(sp)
    8000545e:	6161                	addi	sp,sp,80
    80005460:	8082                	ret
      release(&pi->lock);
    80005462:	8526                	mv	a0,s1
    80005464:	ffffc097          	auipc	ra,0xffffc
    80005468:	826080e7          	jalr	-2010(ra) # 80000c8a <release>
      return -1;
    8000546c:	59fd                	li	s3,-1
    8000546e:	bff9                	j	8000544c <piperead+0xc8>

0000000080005470 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005470:	1141                	addi	sp,sp,-16
    80005472:	e422                	sd	s0,8(sp)
    80005474:	0800                	addi	s0,sp,16
    80005476:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005478:	8905                	andi	a0,a0,1
    8000547a:	c111                	beqz	a0,8000547e <flags2perm+0xe>
      perm = PTE_X;
    8000547c:	4521                	li	a0,8
    if(flags & 0x2)
    8000547e:	8b89                	andi	a5,a5,2
    80005480:	c399                	beqz	a5,80005486 <flags2perm+0x16>
      perm |= PTE_W;
    80005482:	00456513          	ori	a0,a0,4
    return perm;
}
    80005486:	6422                	ld	s0,8(sp)
    80005488:	0141                	addi	sp,sp,16
    8000548a:	8082                	ret

000000008000548c <exec>:

int
exec(char *path, char **argv)
{
    8000548c:	de010113          	addi	sp,sp,-544
    80005490:	20113c23          	sd	ra,536(sp)
    80005494:	20813823          	sd	s0,528(sp)
    80005498:	20913423          	sd	s1,520(sp)
    8000549c:	21213023          	sd	s2,512(sp)
    800054a0:	ffce                	sd	s3,504(sp)
    800054a2:	fbd2                	sd	s4,496(sp)
    800054a4:	f7d6                	sd	s5,488(sp)
    800054a6:	f3da                	sd	s6,480(sp)
    800054a8:	efde                	sd	s7,472(sp)
    800054aa:	ebe2                	sd	s8,464(sp)
    800054ac:	e7e6                	sd	s9,456(sp)
    800054ae:	e3ea                	sd	s10,448(sp)
    800054b0:	ff6e                	sd	s11,440(sp)
    800054b2:	1400                	addi	s0,sp,544
    800054b4:	dea43c23          	sd	a0,-520(s0)
    800054b8:	deb43423          	sd	a1,-536(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800054bc:	ffffc097          	auipc	ra,0xffffc
    800054c0:	63c080e7          	jalr	1596(ra) # 80001af8 <myproc>
    800054c4:	84aa                	mv	s1,a0

   //free the swap file when its not the shell& init proc 
  if(p->pid>2){
    800054c6:	5918                	lw	a4,48(a0)
    800054c8:	4789                	li	a5,2
    800054ca:	04e7d563          	bge	a5,a4,80005514 <exec+0x88>
    struct metaData *page=p->pagesInPysical;
    800054ce:	28050713          	addi	a4,a0,640
    while(page< &p->pagesInPysical[MAX_PSYC_PAGES]){
    800054d2:	38050793          	addi	a5,a0,896
    800054d6:	86be                	mv	a3,a5
      page->idxIsHere=0;
    800054d8:	00073423          	sd	zero,8(a4)
      page->va=0;
    800054dc:	00073023          	sd	zero,0(a4)
      page++;
    800054e0:	0741                	addi	a4,a4,16
    while(page< &p->pagesInPysical[MAX_PSYC_PAGES]){
    800054e2:	fed71be3          	bne	a4,a3,800054d8 <exec+0x4c>
    }
    
    page=p->pagesInSwap;
    while(page< &p->pagesInSwap[MAX_PSYC_PAGES]){
    800054e6:	48048713          	addi	a4,s1,1152
      page->idxIsHere=0;
    800054ea:	0007b423          	sd	zero,8(a5)
      page->va=0;
    800054ee:	0007b023          	sd	zero,0(a5)
      page++;
    800054f2:	07c1                	addi	a5,a5,16
    while(page< &p->pagesInSwap[MAX_PSYC_PAGES]){
    800054f4:	fee79be3          	bne	a5,a4,800054ea <exec+0x5e>
    }
    p->swapPagesCount=0;
    800054f8:	2604bc23          	sd	zero,632(s1)
    p->physicalPagesCount=0;
    800054fc:	2604b823          	sd	zero,624(s1)
    removeSwapFile(p);
    80005500:	8526                	mv	a0,s1
    80005502:	fffff097          	auipc	ra,0xfffff
    80005506:	dcc080e7          	jalr	-564(ra) # 800042ce <removeSwapFile>
    createSwapFile(p);
    8000550a:	8526                	mv	a0,s1
    8000550c:	fffff097          	auipc	ra,0xfffff
    80005510:	f6a080e7          	jalr	-150(ra) # 80004476 <createSwapFile>
  }

  begin_op();
    80005514:	fffff097          	auipc	ra,0xfffff
    80005518:	23c080e7          	jalr	572(ra) # 80004750 <begin_op>

  if((ip = namei(path)) == 0){
    8000551c:	df843503          	ld	a0,-520(s0)
    80005520:	fffff097          	auipc	ra,0xfffff
    80005524:	d02080e7          	jalr	-766(ra) # 80004222 <namei>
    80005528:	8aaa                	mv	s5,a0
    8000552a:	c935                	beqz	a0,8000559e <exec+0x112>
    end_op();
    return -1;
  }
  ilock(ip);
    8000552c:	ffffe097          	auipc	ra,0xffffe
    80005530:	550080e7          	jalr	1360(ra) # 80003a7c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005534:	04000713          	li	a4,64
    80005538:	4681                	li	a3,0
    8000553a:	e5040613          	addi	a2,s0,-432
    8000553e:	4581                	li	a1,0
    80005540:	8556                	mv	a0,s5
    80005542:	ffffe097          	auipc	ra,0xffffe
    80005546:	7ee080e7          	jalr	2030(ra) # 80003d30 <readi>
    8000554a:	04000793          	li	a5,64
    8000554e:	00f51a63          	bne	a0,a5,80005562 <exec+0xd6>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005552:	e5042703          	lw	a4,-432(s0)
    80005556:	464c47b7          	lui	a5,0x464c4
    8000555a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000555e:	04f70663          	beq	a4,a5,800055aa <exec+0x11e>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005562:	8556                	mv	a0,s5
    80005564:	ffffe097          	auipc	ra,0xffffe
    80005568:	77a080e7          	jalr	1914(ra) # 80003cde <iunlockput>
    end_op();
    8000556c:	fffff097          	auipc	ra,0xfffff
    80005570:	264080e7          	jalr	612(ra) # 800047d0 <end_op>
  }
  return -1;
    80005574:	557d                	li	a0,-1
}
    80005576:	21813083          	ld	ra,536(sp)
    8000557a:	21013403          	ld	s0,528(sp)
    8000557e:	20813483          	ld	s1,520(sp)
    80005582:	20013903          	ld	s2,512(sp)
    80005586:	79fe                	ld	s3,504(sp)
    80005588:	7a5e                	ld	s4,496(sp)
    8000558a:	7abe                	ld	s5,488(sp)
    8000558c:	7b1e                	ld	s6,480(sp)
    8000558e:	6bfe                	ld	s7,472(sp)
    80005590:	6c5e                	ld	s8,464(sp)
    80005592:	6cbe                	ld	s9,456(sp)
    80005594:	6d1e                	ld	s10,448(sp)
    80005596:	7dfa                	ld	s11,440(sp)
    80005598:	22010113          	addi	sp,sp,544
    8000559c:	8082                	ret
    end_op();
    8000559e:	fffff097          	auipc	ra,0xfffff
    800055a2:	232080e7          	jalr	562(ra) # 800047d0 <end_op>
    return -1;
    800055a6:	557d                	li	a0,-1
    800055a8:	b7f9                	j	80005576 <exec+0xea>
  if((pagetable = proc_pagetable(p)) == 0)
    800055aa:	8526                	mv	a0,s1
    800055ac:	ffffc097          	auipc	ra,0xffffc
    800055b0:	610080e7          	jalr	1552(ra) # 80001bbc <proc_pagetable>
    800055b4:	8b2a                	mv	s6,a0
    800055b6:	d555                	beqz	a0,80005562 <exec+0xd6>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800055b8:	e7042783          	lw	a5,-400(s0)
    800055bc:	e8845703          	lhu	a4,-376(s0)
    800055c0:	c735                	beqz	a4,8000562c <exec+0x1a0>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800055c2:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800055c4:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800055c8:	6a05                	lui	s4,0x1
    800055ca:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800055ce:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800055d2:	6d85                	lui	s11,0x1
    800055d4:	7d7d                	lui	s10,0xfffff
    800055d6:	a481                	j	80005816 <exec+0x38a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800055d8:	00003517          	auipc	a0,0x3
    800055dc:	21050513          	addi	a0,a0,528 # 800087e8 <syscalls+0x2f0>
    800055e0:	ffffb097          	auipc	ra,0xffffb
    800055e4:	f5e080e7          	jalr	-162(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800055e8:	874a                	mv	a4,s2
    800055ea:	009c86bb          	addw	a3,s9,s1
    800055ee:	4581                	li	a1,0
    800055f0:	8556                	mv	a0,s5
    800055f2:	ffffe097          	auipc	ra,0xffffe
    800055f6:	73e080e7          	jalr	1854(ra) # 80003d30 <readi>
    800055fa:	2501                	sext.w	a0,a0
    800055fc:	1aa91a63          	bne	s2,a0,800057b0 <exec+0x324>
  for(i = 0; i < sz; i += PGSIZE){
    80005600:	009d84bb          	addw	s1,s11,s1
    80005604:	013d09bb          	addw	s3,s10,s3
    80005608:	1f74f763          	bgeu	s1,s7,800057f6 <exec+0x36a>
    pa = walkaddr(pagetable, va + i);
    8000560c:	02049593          	slli	a1,s1,0x20
    80005610:	9181                	srli	a1,a1,0x20
    80005612:	95e2                	add	a1,a1,s8
    80005614:	855a                	mv	a0,s6
    80005616:	ffffc097          	auipc	ra,0xffffc
    8000561a:	af6080e7          	jalr	-1290(ra) # 8000110c <walkaddr>
    8000561e:	862a                	mv	a2,a0
    if(pa == 0)
    80005620:	dd45                	beqz	a0,800055d8 <exec+0x14c>
      n = PGSIZE;
    80005622:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005624:	fd49f2e3          	bgeu	s3,s4,800055e8 <exec+0x15c>
      n = sz - i;
    80005628:	894e                	mv	s2,s3
    8000562a:	bf7d                	j	800055e8 <exec+0x15c>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000562c:	4901                	li	s2,0
  iunlockput(ip);
    8000562e:	8556                	mv	a0,s5
    80005630:	ffffe097          	auipc	ra,0xffffe
    80005634:	6ae080e7          	jalr	1710(ra) # 80003cde <iunlockput>
  end_op();
    80005638:	fffff097          	auipc	ra,0xfffff
    8000563c:	198080e7          	jalr	408(ra) # 800047d0 <end_op>
  p = myproc();
    80005640:	ffffc097          	auipc	ra,0xffffc
    80005644:	4b8080e7          	jalr	1208(ra) # 80001af8 <myproc>
    80005648:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000564a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000564e:	6785                	lui	a5,0x1
    80005650:	17fd                	addi	a5,a5,-1
    80005652:	993e                	add	s2,s2,a5
    80005654:	77fd                	lui	a5,0xfffff
    80005656:	00f977b3          	and	a5,s2,a5
    8000565a:	def43823          	sd	a5,-528(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000565e:	4691                	li	a3,4
    80005660:	6609                	lui	a2,0x2
    80005662:	963e                	add	a2,a2,a5
    80005664:	85be                	mv	a1,a5
    80005666:	855a                	mv	a0,s6
    80005668:	ffffc097          	auipc	ra,0xffffc
    8000566c:	e68080e7          	jalr	-408(ra) # 800014d0 <uvmalloc>
    80005670:	8c2a                	mv	s8,a0
  ip = 0;
    80005672:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005674:	12050e63          	beqz	a0,800057b0 <exec+0x324>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005678:	75f9                	lui	a1,0xffffe
    8000567a:	95aa                	add	a1,a1,a0
    8000567c:	855a                	mv	a0,s6
    8000567e:	ffffc097          	auipc	ra,0xffffc
    80005682:	104080e7          	jalr	260(ra) # 80001782 <uvmclear>
  stackbase = sp - PGSIZE;
    80005686:	7afd                	lui	s5,0xfffff
    80005688:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    8000568a:	de843783          	ld	a5,-536(s0)
    8000568e:	6388                	ld	a0,0(a5)
    80005690:	c925                	beqz	a0,80005700 <exec+0x274>
    80005692:	e9040993          	addi	s3,s0,-368
    80005696:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000569a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000569c:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000569e:	ffffb097          	auipc	ra,0xffffb
    800056a2:	7b0080e7          	jalr	1968(ra) # 80000e4e <strlen>
    800056a6:	0015079b          	addiw	a5,a0,1
    800056aa:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800056ae:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800056b2:	13596663          	bltu	s2,s5,800057de <exec+0x352>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800056b6:	de843d83          	ld	s11,-536(s0)
    800056ba:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800056be:	8552                	mv	a0,s4
    800056c0:	ffffb097          	auipc	ra,0xffffb
    800056c4:	78e080e7          	jalr	1934(ra) # 80000e4e <strlen>
    800056c8:	0015069b          	addiw	a3,a0,1
    800056cc:	8652                	mv	a2,s4
    800056ce:	85ca                	mv	a1,s2
    800056d0:	855a                	mv	a0,s6
    800056d2:	ffffc097          	auipc	ra,0xffffc
    800056d6:	0e2080e7          	jalr	226(ra) # 800017b4 <copyout>
    800056da:	10054663          	bltz	a0,800057e6 <exec+0x35a>
    ustack[argc] = sp;
    800056de:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800056e2:	0485                	addi	s1,s1,1
    800056e4:	008d8793          	addi	a5,s11,8
    800056e8:	def43423          	sd	a5,-536(s0)
    800056ec:	008db503          	ld	a0,8(s11)
    800056f0:	c911                	beqz	a0,80005704 <exec+0x278>
    if(argc >= MAXARG)
    800056f2:	09a1                	addi	s3,s3,8
    800056f4:	fb9995e3          	bne	s3,s9,8000569e <exec+0x212>
  sz = sz1;
    800056f8:	df843823          	sd	s8,-528(s0)
  ip = 0;
    800056fc:	4a81                	li	s5,0
    800056fe:	a84d                	j	800057b0 <exec+0x324>
  sp = sz;
    80005700:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005702:	4481                	li	s1,0
  ustack[argc] = 0;
    80005704:	00349793          	slli	a5,s1,0x3
    80005708:	f9040713          	addi	a4,s0,-112
    8000570c:	97ba                	add	a5,a5,a4
    8000570e:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffd0ac0>
  sp -= (argc+1) * sizeof(uint64);
    80005712:	00148693          	addi	a3,s1,1
    80005716:	068e                	slli	a3,a3,0x3
    80005718:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000571c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005720:	01597663          	bgeu	s2,s5,8000572c <exec+0x2a0>
  sz = sz1;
    80005724:	df843823          	sd	s8,-528(s0)
  ip = 0;
    80005728:	4a81                	li	s5,0
    8000572a:	a059                	j	800057b0 <exec+0x324>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000572c:	e9040613          	addi	a2,s0,-368
    80005730:	85ca                	mv	a1,s2
    80005732:	855a                	mv	a0,s6
    80005734:	ffffc097          	auipc	ra,0xffffc
    80005738:	080080e7          	jalr	128(ra) # 800017b4 <copyout>
    8000573c:	0a054963          	bltz	a0,800057ee <exec+0x362>
  p->trapframe->a1 = sp;
    80005740:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005744:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005748:	df843783          	ld	a5,-520(s0)
    8000574c:	0007c703          	lbu	a4,0(a5)
    80005750:	cf11                	beqz	a4,8000576c <exec+0x2e0>
    80005752:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005754:	02f00693          	li	a3,47
    80005758:	a039                	j	80005766 <exec+0x2da>
      last = s+1;
    8000575a:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000575e:	0785                	addi	a5,a5,1
    80005760:	fff7c703          	lbu	a4,-1(a5)
    80005764:	c701                	beqz	a4,8000576c <exec+0x2e0>
    if(*s == '/')
    80005766:	fed71ce3          	bne	a4,a3,8000575e <exec+0x2d2>
    8000576a:	bfc5                	j	8000575a <exec+0x2ce>
  safestrcpy(p->name, last, sizeof(p->name));
    8000576c:	4641                	li	a2,16
    8000576e:	df843583          	ld	a1,-520(s0)
    80005772:	158b8513          	addi	a0,s7,344
    80005776:	ffffb097          	auipc	ra,0xffffb
    8000577a:	6a6080e7          	jalr	1702(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    8000577e:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005782:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005786:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000578a:	058bb783          	ld	a5,88(s7)
    8000578e:	e6843703          	ld	a4,-408(s0)
    80005792:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005794:	058bb783          	ld	a5,88(s7)
    80005798:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000579c:	85ea                	mv	a1,s10
    8000579e:	ffffc097          	auipc	ra,0xffffc
    800057a2:	4ba080e7          	jalr	1210(ra) # 80001c58 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800057a6:	0004851b          	sext.w	a0,s1
    800057aa:	b3f1                	j	80005576 <exec+0xea>
    800057ac:	df243823          	sd	s2,-528(s0)
    proc_freepagetable(pagetable, sz);
    800057b0:	df043583          	ld	a1,-528(s0)
    800057b4:	855a                	mv	a0,s6
    800057b6:	ffffc097          	auipc	ra,0xffffc
    800057ba:	4a2080e7          	jalr	1186(ra) # 80001c58 <proc_freepagetable>
  if(ip){
    800057be:	da0a92e3          	bnez	s5,80005562 <exec+0xd6>
  return -1;
    800057c2:	557d                	li	a0,-1
    800057c4:	bb4d                	j	80005576 <exec+0xea>
    800057c6:	df243823          	sd	s2,-528(s0)
    800057ca:	b7dd                	j	800057b0 <exec+0x324>
    800057cc:	df243823          	sd	s2,-528(s0)
    800057d0:	b7c5                	j	800057b0 <exec+0x324>
    800057d2:	df243823          	sd	s2,-528(s0)
    800057d6:	bfe9                	j	800057b0 <exec+0x324>
    800057d8:	df243823          	sd	s2,-528(s0)
    800057dc:	bfd1                	j	800057b0 <exec+0x324>
  sz = sz1;
    800057de:	df843823          	sd	s8,-528(s0)
  ip = 0;
    800057e2:	4a81                	li	s5,0
    800057e4:	b7f1                	j	800057b0 <exec+0x324>
  sz = sz1;
    800057e6:	df843823          	sd	s8,-528(s0)
  ip = 0;
    800057ea:	4a81                	li	s5,0
    800057ec:	b7d1                	j	800057b0 <exec+0x324>
  sz = sz1;
    800057ee:	df843823          	sd	s8,-528(s0)
  ip = 0;
    800057f2:	4a81                	li	s5,0
    800057f4:	bf75                	j	800057b0 <exec+0x324>
    sz = sz1;
    800057f6:	df043903          	ld	s2,-528(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800057fa:	e0843783          	ld	a5,-504(s0)
    800057fe:	0017869b          	addiw	a3,a5,1
    80005802:	e0d43423          	sd	a3,-504(s0)
    80005806:	e0043783          	ld	a5,-512(s0)
    8000580a:	0387879b          	addiw	a5,a5,56
    8000580e:	e8845703          	lhu	a4,-376(s0)
    80005812:	e0e6dee3          	bge	a3,a4,8000562e <exec+0x1a2>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005816:	2781                	sext.w	a5,a5
    80005818:	e0f43023          	sd	a5,-512(s0)
    8000581c:	03800713          	li	a4,56
    80005820:	86be                	mv	a3,a5
    80005822:	e1840613          	addi	a2,s0,-488
    80005826:	4581                	li	a1,0
    80005828:	8556                	mv	a0,s5
    8000582a:	ffffe097          	auipc	ra,0xffffe
    8000582e:	506080e7          	jalr	1286(ra) # 80003d30 <readi>
    80005832:	03800793          	li	a5,56
    80005836:	f6f51be3          	bne	a0,a5,800057ac <exec+0x320>
    if(ph.type != ELF_PROG_LOAD)
    8000583a:	e1842783          	lw	a5,-488(s0)
    8000583e:	4705                	li	a4,1
    80005840:	fae79de3          	bne	a5,a4,800057fa <exec+0x36e>
    if(ph.memsz < ph.filesz)
    80005844:	e4043483          	ld	s1,-448(s0)
    80005848:	e3843783          	ld	a5,-456(s0)
    8000584c:	f6f4ede3          	bltu	s1,a5,800057c6 <exec+0x33a>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005850:	e2843783          	ld	a5,-472(s0)
    80005854:	94be                	add	s1,s1,a5
    80005856:	f6f4ebe3          	bltu	s1,a5,800057cc <exec+0x340>
    if(ph.vaddr % PGSIZE != 0)
    8000585a:	de043703          	ld	a4,-544(s0)
    8000585e:	8ff9                	and	a5,a5,a4
    80005860:	fbad                	bnez	a5,800057d2 <exec+0x346>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005862:	e1c42503          	lw	a0,-484(s0)
    80005866:	00000097          	auipc	ra,0x0
    8000586a:	c0a080e7          	jalr	-1014(ra) # 80005470 <flags2perm>
    8000586e:	86aa                	mv	a3,a0
    80005870:	8626                	mv	a2,s1
    80005872:	85ca                	mv	a1,s2
    80005874:	855a                	mv	a0,s6
    80005876:	ffffc097          	auipc	ra,0xffffc
    8000587a:	c5a080e7          	jalr	-934(ra) # 800014d0 <uvmalloc>
    8000587e:	dea43823          	sd	a0,-528(s0)
    80005882:	d939                	beqz	a0,800057d8 <exec+0x34c>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005884:	e2843c03          	ld	s8,-472(s0)
    80005888:	e2042c83          	lw	s9,-480(s0)
    8000588c:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005890:	f60b83e3          	beqz	s7,800057f6 <exec+0x36a>
    80005894:	89de                	mv	s3,s7
    80005896:	4481                	li	s1,0
    80005898:	bb95                	j	8000560c <exec+0x180>

000000008000589a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000589a:	7179                	addi	sp,sp,-48
    8000589c:	f406                	sd	ra,40(sp)
    8000589e:	f022                	sd	s0,32(sp)
    800058a0:	ec26                	sd	s1,24(sp)
    800058a2:	e84a                	sd	s2,16(sp)
    800058a4:	1800                	addi	s0,sp,48
    800058a6:	892e                	mv	s2,a1
    800058a8:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800058aa:	fdc40593          	addi	a1,s0,-36
    800058ae:	ffffd097          	auipc	ra,0xffffd
    800058b2:	662080e7          	jalr	1634(ra) # 80002f10 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800058b6:	fdc42703          	lw	a4,-36(s0)
    800058ba:	47bd                	li	a5,15
    800058bc:	02e7eb63          	bltu	a5,a4,800058f2 <argfd+0x58>
    800058c0:	ffffc097          	auipc	ra,0xffffc
    800058c4:	238080e7          	jalr	568(ra) # 80001af8 <myproc>
    800058c8:	fdc42703          	lw	a4,-36(s0)
    800058cc:	01a70793          	addi	a5,a4,26
    800058d0:	078e                	slli	a5,a5,0x3
    800058d2:	953e                	add	a0,a0,a5
    800058d4:	611c                	ld	a5,0(a0)
    800058d6:	c385                	beqz	a5,800058f6 <argfd+0x5c>
    return -1;
  if(pfd)
    800058d8:	00090463          	beqz	s2,800058e0 <argfd+0x46>
    *pfd = fd;
    800058dc:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800058e0:	4501                	li	a0,0
  if(pf)
    800058e2:	c091                	beqz	s1,800058e6 <argfd+0x4c>
    *pf = f;
    800058e4:	e09c                	sd	a5,0(s1)
}
    800058e6:	70a2                	ld	ra,40(sp)
    800058e8:	7402                	ld	s0,32(sp)
    800058ea:	64e2                	ld	s1,24(sp)
    800058ec:	6942                	ld	s2,16(sp)
    800058ee:	6145                	addi	sp,sp,48
    800058f0:	8082                	ret
    return -1;
    800058f2:	557d                	li	a0,-1
    800058f4:	bfcd                	j	800058e6 <argfd+0x4c>
    800058f6:	557d                	li	a0,-1
    800058f8:	b7fd                	j	800058e6 <argfd+0x4c>

00000000800058fa <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800058fa:	1101                	addi	sp,sp,-32
    800058fc:	ec06                	sd	ra,24(sp)
    800058fe:	e822                	sd	s0,16(sp)
    80005900:	e426                	sd	s1,8(sp)
    80005902:	1000                	addi	s0,sp,32
    80005904:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005906:	ffffc097          	auipc	ra,0xffffc
    8000590a:	1f2080e7          	jalr	498(ra) # 80001af8 <myproc>
    8000590e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005910:	0d050793          	addi	a5,a0,208
    80005914:	4501                	li	a0,0
    80005916:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005918:	6398                	ld	a4,0(a5)
    8000591a:	cb19                	beqz	a4,80005930 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000591c:	2505                	addiw	a0,a0,1
    8000591e:	07a1                	addi	a5,a5,8
    80005920:	fed51ce3          	bne	a0,a3,80005918 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005924:	557d                	li	a0,-1
}
    80005926:	60e2                	ld	ra,24(sp)
    80005928:	6442                	ld	s0,16(sp)
    8000592a:	64a2                	ld	s1,8(sp)
    8000592c:	6105                	addi	sp,sp,32
    8000592e:	8082                	ret
      p->ofile[fd] = f;
    80005930:	01a50793          	addi	a5,a0,26
    80005934:	078e                	slli	a5,a5,0x3
    80005936:	963e                	add	a2,a2,a5
    80005938:	e204                	sd	s1,0(a2)
      return fd;
    8000593a:	b7f5                	j	80005926 <fdalloc+0x2c>

000000008000593c <sys_dup>:

uint64
sys_dup(void)
{
    8000593c:	7179                	addi	sp,sp,-48
    8000593e:	f406                	sd	ra,40(sp)
    80005940:	f022                	sd	s0,32(sp)
    80005942:	ec26                	sd	s1,24(sp)
    80005944:	1800                	addi	s0,sp,48
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)
    80005946:	fd840613          	addi	a2,s0,-40
    8000594a:	4581                	li	a1,0
    8000594c:	4501                	li	a0,0
    8000594e:	00000097          	auipc	ra,0x0
    80005952:	f4c080e7          	jalr	-180(ra) # 8000589a <argfd>
    return -1;
    80005956:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005958:	02054363          	bltz	a0,8000597e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000595c:	fd843503          	ld	a0,-40(s0)
    80005960:	00000097          	auipc	ra,0x0
    80005964:	f9a080e7          	jalr	-102(ra) # 800058fa <fdalloc>
    80005968:	84aa                	mv	s1,a0
    return -1;
    8000596a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000596c:	00054963          	bltz	a0,8000597e <sys_dup+0x42>
  filedup(f);
    80005970:	fd843503          	ld	a0,-40(s0)
    80005974:	fffff097          	auipc	ra,0xfffff
    80005978:	256080e7          	jalr	598(ra) # 80004bca <filedup>
  return fd;
    8000597c:	87a6                	mv	a5,s1
}
    8000597e:	853e                	mv	a0,a5
    80005980:	70a2                	ld	ra,40(sp)
    80005982:	7402                	ld	s0,32(sp)
    80005984:	64e2                	ld	s1,24(sp)
    80005986:	6145                	addi	sp,sp,48
    80005988:	8082                	ret

000000008000598a <sys_read>:

uint64
sys_read(void)
{
    8000598a:	7179                	addi	sp,sp,-48
    8000598c:	f406                	sd	ra,40(sp)
    8000598e:	f022                	sd	s0,32(sp)
    80005990:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  argaddr(1, &p);
    80005992:	fd840593          	addi	a1,s0,-40
    80005996:	4505                	li	a0,1
    80005998:	ffffd097          	auipc	ra,0xffffd
    8000599c:	598080e7          	jalr	1432(ra) # 80002f30 <argaddr>
  argint(2, &n);
    800059a0:	fe440593          	addi	a1,s0,-28
    800059a4:	4509                	li	a0,2
    800059a6:	ffffd097          	auipc	ra,0xffffd
    800059aa:	56a080e7          	jalr	1386(ra) # 80002f10 <argint>
  if(argfd(0, 0, &f) < 0)
    800059ae:	fe840613          	addi	a2,s0,-24
    800059b2:	4581                	li	a1,0
    800059b4:	4501                	li	a0,0
    800059b6:	00000097          	auipc	ra,0x0
    800059ba:	ee4080e7          	jalr	-284(ra) # 8000589a <argfd>
    800059be:	87aa                	mv	a5,a0
    return -1;
    800059c0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800059c2:	0007cc63          	bltz	a5,800059da <sys_read+0x50>
  return fileread(f, p, n);
    800059c6:	fe442603          	lw	a2,-28(s0)
    800059ca:	fd843583          	ld	a1,-40(s0)
    800059ce:	fe843503          	ld	a0,-24(s0)
    800059d2:	fffff097          	auipc	ra,0xfffff
    800059d6:	384080e7          	jalr	900(ra) # 80004d56 <fileread>
}
    800059da:	70a2                	ld	ra,40(sp)
    800059dc:	7402                	ld	s0,32(sp)
    800059de:	6145                	addi	sp,sp,48
    800059e0:	8082                	ret

00000000800059e2 <sys_write>:

uint64
sys_write(void)
{
    800059e2:	7179                	addi	sp,sp,-48
    800059e4:	f406                	sd	ra,40(sp)
    800059e6:	f022                	sd	s0,32(sp)
    800059e8:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;
  
  argaddr(1, &p);
    800059ea:	fd840593          	addi	a1,s0,-40
    800059ee:	4505                	li	a0,1
    800059f0:	ffffd097          	auipc	ra,0xffffd
    800059f4:	540080e7          	jalr	1344(ra) # 80002f30 <argaddr>
  argint(2, &n);
    800059f8:	fe440593          	addi	a1,s0,-28
    800059fc:	4509                	li	a0,2
    800059fe:	ffffd097          	auipc	ra,0xffffd
    80005a02:	512080e7          	jalr	1298(ra) # 80002f10 <argint>
  if(argfd(0, 0, &f) < 0)
    80005a06:	fe840613          	addi	a2,s0,-24
    80005a0a:	4581                	li	a1,0
    80005a0c:	4501                	li	a0,0
    80005a0e:	00000097          	auipc	ra,0x0
    80005a12:	e8c080e7          	jalr	-372(ra) # 8000589a <argfd>
    80005a16:	87aa                	mv	a5,a0
    return -1;
    80005a18:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005a1a:	0007cc63          	bltz	a5,80005a32 <sys_write+0x50>

  return filewrite(f, p, n);
    80005a1e:	fe442603          	lw	a2,-28(s0)
    80005a22:	fd843583          	ld	a1,-40(s0)
    80005a26:	fe843503          	ld	a0,-24(s0)
    80005a2a:	fffff097          	auipc	ra,0xfffff
    80005a2e:	3ee080e7          	jalr	1006(ra) # 80004e18 <filewrite>
}
    80005a32:	70a2                	ld	ra,40(sp)
    80005a34:	7402                	ld	s0,32(sp)
    80005a36:	6145                	addi	sp,sp,48
    80005a38:	8082                	ret

0000000080005a3a <sys_close>:

uint64
sys_close(void)
{
    80005a3a:	1101                	addi	sp,sp,-32
    80005a3c:	ec06                	sd	ra,24(sp)
    80005a3e:	e822                	sd	s0,16(sp)
    80005a40:	1000                	addi	s0,sp,32
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)
    80005a42:	fe040613          	addi	a2,s0,-32
    80005a46:	fec40593          	addi	a1,s0,-20
    80005a4a:	4501                	li	a0,0
    80005a4c:	00000097          	auipc	ra,0x0
    80005a50:	e4e080e7          	jalr	-434(ra) # 8000589a <argfd>
    return -1;
    80005a54:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005a56:	02054463          	bltz	a0,80005a7e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005a5a:	ffffc097          	auipc	ra,0xffffc
    80005a5e:	09e080e7          	jalr	158(ra) # 80001af8 <myproc>
    80005a62:	fec42783          	lw	a5,-20(s0)
    80005a66:	07e9                	addi	a5,a5,26
    80005a68:	078e                	slli	a5,a5,0x3
    80005a6a:	97aa                	add	a5,a5,a0
    80005a6c:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005a70:	fe043503          	ld	a0,-32(s0)
    80005a74:	fffff097          	auipc	ra,0xfffff
    80005a78:	1a8080e7          	jalr	424(ra) # 80004c1c <fileclose>
  return 0;
    80005a7c:	4781                	li	a5,0
}
    80005a7e:	853e                	mv	a0,a5
    80005a80:	60e2                	ld	ra,24(sp)
    80005a82:	6442                	ld	s0,16(sp)
    80005a84:	6105                	addi	sp,sp,32
    80005a86:	8082                	ret

0000000080005a88 <sys_fstat>:

uint64
sys_fstat(void)
{
    80005a88:	1101                	addi	sp,sp,-32
    80005a8a:	ec06                	sd	ra,24(sp)
    80005a8c:	e822                	sd	s0,16(sp)
    80005a8e:	1000                	addi	s0,sp,32
  struct file *f;
  uint64 st; // user pointer to struct stat

  argaddr(1, &st);
    80005a90:	fe040593          	addi	a1,s0,-32
    80005a94:	4505                	li	a0,1
    80005a96:	ffffd097          	auipc	ra,0xffffd
    80005a9a:	49a080e7          	jalr	1178(ra) # 80002f30 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005a9e:	fe840613          	addi	a2,s0,-24
    80005aa2:	4581                	li	a1,0
    80005aa4:	4501                	li	a0,0
    80005aa6:	00000097          	auipc	ra,0x0
    80005aaa:	df4080e7          	jalr	-524(ra) # 8000589a <argfd>
    80005aae:	87aa                	mv	a5,a0
    return -1;
    80005ab0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005ab2:	0007ca63          	bltz	a5,80005ac6 <sys_fstat+0x3e>
  return filestat(f, st);
    80005ab6:	fe043583          	ld	a1,-32(s0)
    80005aba:	fe843503          	ld	a0,-24(s0)
    80005abe:	fffff097          	auipc	ra,0xfffff
    80005ac2:	226080e7          	jalr	550(ra) # 80004ce4 <filestat>
}
    80005ac6:	60e2                	ld	ra,24(sp)
    80005ac8:	6442                	ld	s0,16(sp)
    80005aca:	6105                	addi	sp,sp,32
    80005acc:	8082                	ret

0000000080005ace <sys_link>:

// Create the path new as a link to the same inode as old.
uint64
sys_link(void)
{
    80005ace:	7169                	addi	sp,sp,-304
    80005ad0:	f606                	sd	ra,296(sp)
    80005ad2:	f222                	sd	s0,288(sp)
    80005ad4:	ee26                	sd	s1,280(sp)
    80005ad6:	ea4a                	sd	s2,272(sp)
    80005ad8:	1a00                	addi	s0,sp,304
  char name[DIRSIZ], new[MAXPATH], old[MAXPATH];
  struct inode *dp, *ip;

  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ada:	08000613          	li	a2,128
    80005ade:	ed040593          	addi	a1,s0,-304
    80005ae2:	4501                	li	a0,0
    80005ae4:	ffffd097          	auipc	ra,0xffffd
    80005ae8:	46c080e7          	jalr	1132(ra) # 80002f50 <argstr>
    return -1;
    80005aec:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005aee:	10054e63          	bltz	a0,80005c0a <sys_link+0x13c>
    80005af2:	08000613          	li	a2,128
    80005af6:	f5040593          	addi	a1,s0,-176
    80005afa:	4505                	li	a0,1
    80005afc:	ffffd097          	auipc	ra,0xffffd
    80005b00:	454080e7          	jalr	1108(ra) # 80002f50 <argstr>
    return -1;
    80005b04:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b06:	10054263          	bltz	a0,80005c0a <sys_link+0x13c>

  begin_op();
    80005b0a:	fffff097          	auipc	ra,0xfffff
    80005b0e:	c46080e7          	jalr	-954(ra) # 80004750 <begin_op>
  if((ip = namei(old)) == 0){
    80005b12:	ed040513          	addi	a0,s0,-304
    80005b16:	ffffe097          	auipc	ra,0xffffe
    80005b1a:	70c080e7          	jalr	1804(ra) # 80004222 <namei>
    80005b1e:	84aa                	mv	s1,a0
    80005b20:	c551                	beqz	a0,80005bac <sys_link+0xde>
    end_op();
    return -1;
  }

  ilock(ip);
    80005b22:	ffffe097          	auipc	ra,0xffffe
    80005b26:	f5a080e7          	jalr	-166(ra) # 80003a7c <ilock>
  if(ip->type == T_DIR){
    80005b2a:	04449703          	lh	a4,68(s1)
    80005b2e:	4785                	li	a5,1
    80005b30:	08f70463          	beq	a4,a5,80005bb8 <sys_link+0xea>
    iunlockput(ip);
    end_op();
    return -1;
  }

  ip->nlink++;
    80005b34:	04a4d783          	lhu	a5,74(s1)
    80005b38:	2785                	addiw	a5,a5,1
    80005b3a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b3e:	8526                	mv	a0,s1
    80005b40:	ffffe097          	auipc	ra,0xffffe
    80005b44:	e72080e7          	jalr	-398(ra) # 800039b2 <iupdate>
  iunlock(ip);
    80005b48:	8526                	mv	a0,s1
    80005b4a:	ffffe097          	auipc	ra,0xffffe
    80005b4e:	ff4080e7          	jalr	-12(ra) # 80003b3e <iunlock>

  if((dp = nameiparent(new, name)) == 0)
    80005b52:	fd040593          	addi	a1,s0,-48
    80005b56:	f5040513          	addi	a0,s0,-176
    80005b5a:	ffffe097          	auipc	ra,0xffffe
    80005b5e:	6e6080e7          	jalr	1766(ra) # 80004240 <nameiparent>
    80005b62:	892a                	mv	s2,a0
    80005b64:	c935                	beqz	a0,80005bd8 <sys_link+0x10a>
    goto bad;
  ilock(dp);
    80005b66:	ffffe097          	auipc	ra,0xffffe
    80005b6a:	f16080e7          	jalr	-234(ra) # 80003a7c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005b6e:	00092703          	lw	a4,0(s2)
    80005b72:	409c                	lw	a5,0(s1)
    80005b74:	04f71d63          	bne	a4,a5,80005bce <sys_link+0x100>
    80005b78:	40d0                	lw	a2,4(s1)
    80005b7a:	fd040593          	addi	a1,s0,-48
    80005b7e:	854a                	mv	a0,s2
    80005b80:	ffffe097          	auipc	ra,0xffffe
    80005b84:	5f0080e7          	jalr	1520(ra) # 80004170 <dirlink>
    80005b88:	04054363          	bltz	a0,80005bce <sys_link+0x100>
    iunlockput(dp);
    goto bad;
  }
  iunlockput(dp);
    80005b8c:	854a                	mv	a0,s2
    80005b8e:	ffffe097          	auipc	ra,0xffffe
    80005b92:	150080e7          	jalr	336(ra) # 80003cde <iunlockput>
  iput(ip);
    80005b96:	8526                	mv	a0,s1
    80005b98:	ffffe097          	auipc	ra,0xffffe
    80005b9c:	09e080e7          	jalr	158(ra) # 80003c36 <iput>

  end_op();
    80005ba0:	fffff097          	auipc	ra,0xfffff
    80005ba4:	c30080e7          	jalr	-976(ra) # 800047d0 <end_op>

  return 0;
    80005ba8:	4781                	li	a5,0
    80005baa:	a085                	j	80005c0a <sys_link+0x13c>
    end_op();
    80005bac:	fffff097          	auipc	ra,0xfffff
    80005bb0:	c24080e7          	jalr	-988(ra) # 800047d0 <end_op>
    return -1;
    80005bb4:	57fd                	li	a5,-1
    80005bb6:	a891                	j	80005c0a <sys_link+0x13c>
    iunlockput(ip);
    80005bb8:	8526                	mv	a0,s1
    80005bba:	ffffe097          	auipc	ra,0xffffe
    80005bbe:	124080e7          	jalr	292(ra) # 80003cde <iunlockput>
    end_op();
    80005bc2:	fffff097          	auipc	ra,0xfffff
    80005bc6:	c0e080e7          	jalr	-1010(ra) # 800047d0 <end_op>
    return -1;
    80005bca:	57fd                	li	a5,-1
    80005bcc:	a83d                	j	80005c0a <sys_link+0x13c>
    iunlockput(dp);
    80005bce:	854a                	mv	a0,s2
    80005bd0:	ffffe097          	auipc	ra,0xffffe
    80005bd4:	10e080e7          	jalr	270(ra) # 80003cde <iunlockput>

bad:
  ilock(ip);
    80005bd8:	8526                	mv	a0,s1
    80005bda:	ffffe097          	auipc	ra,0xffffe
    80005bde:	ea2080e7          	jalr	-350(ra) # 80003a7c <ilock>
  ip->nlink--;
    80005be2:	04a4d783          	lhu	a5,74(s1)
    80005be6:	37fd                	addiw	a5,a5,-1
    80005be8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005bec:	8526                	mv	a0,s1
    80005bee:	ffffe097          	auipc	ra,0xffffe
    80005bf2:	dc4080e7          	jalr	-572(ra) # 800039b2 <iupdate>
  iunlockput(ip);
    80005bf6:	8526                	mv	a0,s1
    80005bf8:	ffffe097          	auipc	ra,0xffffe
    80005bfc:	0e6080e7          	jalr	230(ra) # 80003cde <iunlockput>
  end_op();
    80005c00:	fffff097          	auipc	ra,0xfffff
    80005c04:	bd0080e7          	jalr	-1072(ra) # 800047d0 <end_op>
  return -1;
    80005c08:	57fd                	li	a5,-1
}
    80005c0a:	853e                	mv	a0,a5
    80005c0c:	70b2                	ld	ra,296(sp)
    80005c0e:	7412                	ld	s0,288(sp)
    80005c10:	64f2                	ld	s1,280(sp)
    80005c12:	6952                	ld	s2,272(sp)
    80005c14:	6155                	addi	sp,sp,304
    80005c16:	8082                	ret

0000000080005c18 <isdirempty>:
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c18:	4578                	lw	a4,76(a0)
    80005c1a:	02000793          	li	a5,32
    80005c1e:	04e7fa63          	bgeu	a5,a4,80005c72 <isdirempty+0x5a>
{
    80005c22:	7179                	addi	sp,sp,-48
    80005c24:	f406                	sd	ra,40(sp)
    80005c26:	f022                	sd	s0,32(sp)
    80005c28:	ec26                	sd	s1,24(sp)
    80005c2a:	e84a                	sd	s2,16(sp)
    80005c2c:	1800                	addi	s0,sp,48
    80005c2e:	892a                	mv	s2,a0
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c30:	02000493          	li	s1,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c34:	4741                	li	a4,16
    80005c36:	86a6                	mv	a3,s1
    80005c38:	fd040613          	addi	a2,s0,-48
    80005c3c:	4581                	li	a1,0
    80005c3e:	854a                	mv	a0,s2
    80005c40:	ffffe097          	auipc	ra,0xffffe
    80005c44:	0f0080e7          	jalr	240(ra) # 80003d30 <readi>
    80005c48:	47c1                	li	a5,16
    80005c4a:	00f51c63          	bne	a0,a5,80005c62 <isdirempty+0x4a>
      panic("isdirempty: readi");
    if(de.inum != 0)
    80005c4e:	fd045783          	lhu	a5,-48(s0)
    80005c52:	e395                	bnez	a5,80005c76 <isdirempty+0x5e>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c54:	24c1                	addiw	s1,s1,16
    80005c56:	04c92783          	lw	a5,76(s2)
    80005c5a:	fcf4ede3          	bltu	s1,a5,80005c34 <isdirempty+0x1c>
      return 0;
  }
  return 1;
    80005c5e:	4505                	li	a0,1
    80005c60:	a821                	j	80005c78 <isdirempty+0x60>
      panic("isdirempty: readi");
    80005c62:	00003517          	auipc	a0,0x3
    80005c66:	ba650513          	addi	a0,a0,-1114 # 80008808 <syscalls+0x310>
    80005c6a:	ffffb097          	auipc	ra,0xffffb
    80005c6e:	8d4080e7          	jalr	-1836(ra) # 8000053e <panic>
  return 1;
    80005c72:	4505                	li	a0,1
}
    80005c74:	8082                	ret
      return 0;
    80005c76:	4501                	li	a0,0
}
    80005c78:	70a2                	ld	ra,40(sp)
    80005c7a:	7402                	ld	s0,32(sp)
    80005c7c:	64e2                	ld	s1,24(sp)
    80005c7e:	6942                	ld	s2,16(sp)
    80005c80:	6145                	addi	sp,sp,48
    80005c82:	8082                	ret

0000000080005c84 <sys_unlink>:

uint64
sys_unlink(void)
{
    80005c84:	7155                	addi	sp,sp,-208
    80005c86:	e586                	sd	ra,200(sp)
    80005c88:	e1a2                	sd	s0,192(sp)
    80005c8a:	fd26                	sd	s1,184(sp)
    80005c8c:	f94a                	sd	s2,176(sp)
    80005c8e:	0980                	addi	s0,sp,208
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], path[MAXPATH];
  uint off;

  if(argstr(0, path, MAXPATH) < 0)
    80005c90:	08000613          	li	a2,128
    80005c94:	f4040593          	addi	a1,s0,-192
    80005c98:	4501                	li	a0,0
    80005c9a:	ffffd097          	auipc	ra,0xffffd
    80005c9e:	2b6080e7          	jalr	694(ra) # 80002f50 <argstr>
    80005ca2:	16054363          	bltz	a0,80005e08 <sys_unlink+0x184>
    return -1;

  begin_op();
    80005ca6:	fffff097          	auipc	ra,0xfffff
    80005caa:	aaa080e7          	jalr	-1366(ra) # 80004750 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005cae:	fc040593          	addi	a1,s0,-64
    80005cb2:	f4040513          	addi	a0,s0,-192
    80005cb6:	ffffe097          	auipc	ra,0xffffe
    80005cba:	58a080e7          	jalr	1418(ra) # 80004240 <nameiparent>
    80005cbe:	84aa                	mv	s1,a0
    80005cc0:	c961                	beqz	a0,80005d90 <sys_unlink+0x10c>
    end_op();
    return -1;
  }

  ilock(dp);
    80005cc2:	ffffe097          	auipc	ra,0xffffe
    80005cc6:	dba080e7          	jalr	-582(ra) # 80003a7c <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005cca:	00003597          	auipc	a1,0x3
    80005cce:	a1e58593          	addi	a1,a1,-1506 # 800086e8 <syscalls+0x1f0>
    80005cd2:	fc040513          	addi	a0,s0,-64
    80005cd6:	ffffe097          	auipc	ra,0xffffe
    80005cda:	270080e7          	jalr	624(ra) # 80003f46 <namecmp>
    80005cde:	c175                	beqz	a0,80005dc2 <sys_unlink+0x13e>
    80005ce0:	00003597          	auipc	a1,0x3
    80005ce4:	a1058593          	addi	a1,a1,-1520 # 800086f0 <syscalls+0x1f8>
    80005ce8:	fc040513          	addi	a0,s0,-64
    80005cec:	ffffe097          	auipc	ra,0xffffe
    80005cf0:	25a080e7          	jalr	602(ra) # 80003f46 <namecmp>
    80005cf4:	c579                	beqz	a0,80005dc2 <sys_unlink+0x13e>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    80005cf6:	f3c40613          	addi	a2,s0,-196
    80005cfa:	fc040593          	addi	a1,s0,-64
    80005cfe:	8526                	mv	a0,s1
    80005d00:	ffffe097          	auipc	ra,0xffffe
    80005d04:	260080e7          	jalr	608(ra) # 80003f60 <dirlookup>
    80005d08:	892a                	mv	s2,a0
    80005d0a:	cd45                	beqz	a0,80005dc2 <sys_unlink+0x13e>
    goto bad;
  ilock(ip);
    80005d0c:	ffffe097          	auipc	ra,0xffffe
    80005d10:	d70080e7          	jalr	-656(ra) # 80003a7c <ilock>

  if(ip->nlink < 1)
    80005d14:	04a91783          	lh	a5,74(s2)
    80005d18:	08f05263          	blez	a5,80005d9c <sys_unlink+0x118>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005d1c:	04491703          	lh	a4,68(s2)
    80005d20:	4785                	li	a5,1
    80005d22:	08f70563          	beq	a4,a5,80005dac <sys_unlink+0x128>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    80005d26:	4641                	li	a2,16
    80005d28:	4581                	li	a1,0
    80005d2a:	fd040513          	addi	a0,s0,-48
    80005d2e:	ffffb097          	auipc	ra,0xffffb
    80005d32:	fa4080e7          	jalr	-92(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d36:	4741                	li	a4,16
    80005d38:	f3c42683          	lw	a3,-196(s0)
    80005d3c:	fd040613          	addi	a2,s0,-48
    80005d40:	4581                	li	a1,0
    80005d42:	8526                	mv	a0,s1
    80005d44:	ffffe097          	auipc	ra,0xffffe
    80005d48:	0e4080e7          	jalr	228(ra) # 80003e28 <writei>
    80005d4c:	47c1                	li	a5,16
    80005d4e:	08f51a63          	bne	a0,a5,80005de2 <sys_unlink+0x15e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    80005d52:	04491703          	lh	a4,68(s2)
    80005d56:	4785                	li	a5,1
    80005d58:	08f70d63          	beq	a4,a5,80005df2 <sys_unlink+0x16e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    80005d5c:	8526                	mv	a0,s1
    80005d5e:	ffffe097          	auipc	ra,0xffffe
    80005d62:	f80080e7          	jalr	-128(ra) # 80003cde <iunlockput>

  ip->nlink--;
    80005d66:	04a95783          	lhu	a5,74(s2)
    80005d6a:	37fd                	addiw	a5,a5,-1
    80005d6c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005d70:	854a                	mv	a0,s2
    80005d72:	ffffe097          	auipc	ra,0xffffe
    80005d76:	c40080e7          	jalr	-960(ra) # 800039b2 <iupdate>
  iunlockput(ip);
    80005d7a:	854a                	mv	a0,s2
    80005d7c:	ffffe097          	auipc	ra,0xffffe
    80005d80:	f62080e7          	jalr	-158(ra) # 80003cde <iunlockput>

  end_op();
    80005d84:	fffff097          	auipc	ra,0xfffff
    80005d88:	a4c080e7          	jalr	-1460(ra) # 800047d0 <end_op>

  return 0;
    80005d8c:	4501                	li	a0,0
    80005d8e:	a0a1                	j	80005dd6 <sys_unlink+0x152>
    end_op();
    80005d90:	fffff097          	auipc	ra,0xfffff
    80005d94:	a40080e7          	jalr	-1472(ra) # 800047d0 <end_op>
    return -1;
    80005d98:	557d                	li	a0,-1
    80005d9a:	a835                	j	80005dd6 <sys_unlink+0x152>
    panic("unlink: nlink < 1");
    80005d9c:	00003517          	auipc	a0,0x3
    80005da0:	95c50513          	addi	a0,a0,-1700 # 800086f8 <syscalls+0x200>
    80005da4:	ffffa097          	auipc	ra,0xffffa
    80005da8:	79a080e7          	jalr	1946(ra) # 8000053e <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005dac:	854a                	mv	a0,s2
    80005dae:	00000097          	auipc	ra,0x0
    80005db2:	e6a080e7          	jalr	-406(ra) # 80005c18 <isdirempty>
    80005db6:	f925                	bnez	a0,80005d26 <sys_unlink+0xa2>
    iunlockput(ip);
    80005db8:	854a                	mv	a0,s2
    80005dba:	ffffe097          	auipc	ra,0xffffe
    80005dbe:	f24080e7          	jalr	-220(ra) # 80003cde <iunlockput>

bad:
  iunlockput(dp);
    80005dc2:	8526                	mv	a0,s1
    80005dc4:	ffffe097          	auipc	ra,0xffffe
    80005dc8:	f1a080e7          	jalr	-230(ra) # 80003cde <iunlockput>
  end_op();
    80005dcc:	fffff097          	auipc	ra,0xfffff
    80005dd0:	a04080e7          	jalr	-1532(ra) # 800047d0 <end_op>
  return -1;
    80005dd4:	557d                	li	a0,-1
}
    80005dd6:	60ae                	ld	ra,200(sp)
    80005dd8:	640e                	ld	s0,192(sp)
    80005dda:	74ea                	ld	s1,184(sp)
    80005ddc:	794a                	ld	s2,176(sp)
    80005dde:	6169                	addi	sp,sp,208
    80005de0:	8082                	ret
    panic("unlink: writei");
    80005de2:	00003517          	auipc	a0,0x3
    80005de6:	92e50513          	addi	a0,a0,-1746 # 80008710 <syscalls+0x218>
    80005dea:	ffffa097          	auipc	ra,0xffffa
    80005dee:	754080e7          	jalr	1876(ra) # 8000053e <panic>
    dp->nlink--;
    80005df2:	04a4d783          	lhu	a5,74(s1)
    80005df6:	37fd                	addiw	a5,a5,-1
    80005df8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005dfc:	8526                	mv	a0,s1
    80005dfe:	ffffe097          	auipc	ra,0xffffe
    80005e02:	bb4080e7          	jalr	-1100(ra) # 800039b2 <iupdate>
    80005e06:	bf99                	j	80005d5c <sys_unlink+0xd8>
    return -1;
    80005e08:	557d                	li	a0,-1
    80005e0a:	b7f1                	j	80005dd6 <sys_unlink+0x152>

0000000080005e0c <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
    80005e0c:	715d                	addi	sp,sp,-80
    80005e0e:	e486                	sd	ra,72(sp)
    80005e10:	e0a2                	sd	s0,64(sp)
    80005e12:	fc26                	sd	s1,56(sp)
    80005e14:	f84a                	sd	s2,48(sp)
    80005e16:	f44e                	sd	s3,40(sp)
    80005e18:	f052                	sd	s4,32(sp)
    80005e1a:	ec56                	sd	s5,24(sp)
    80005e1c:	e85a                	sd	s6,16(sp)
    80005e1e:	0880                	addi	s0,sp,80
    80005e20:	8b2e                	mv	s6,a1
    80005e22:	89b2                	mv	s3,a2
    80005e24:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005e26:	fb040593          	addi	a1,s0,-80
    80005e2a:	ffffe097          	auipc	ra,0xffffe
    80005e2e:	416080e7          	jalr	1046(ra) # 80004240 <nameiparent>
    80005e32:	84aa                	mv	s1,a0
    80005e34:	14050f63          	beqz	a0,80005f92 <create+0x186>
    return 0;

  ilock(dp);
    80005e38:	ffffe097          	auipc	ra,0xffffe
    80005e3c:	c44080e7          	jalr	-956(ra) # 80003a7c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005e40:	4601                	li	a2,0
    80005e42:	fb040593          	addi	a1,s0,-80
    80005e46:	8526                	mv	a0,s1
    80005e48:	ffffe097          	auipc	ra,0xffffe
    80005e4c:	118080e7          	jalr	280(ra) # 80003f60 <dirlookup>
    80005e50:	8aaa                	mv	s5,a0
    80005e52:	c931                	beqz	a0,80005ea6 <create+0x9a>
    iunlockput(dp);
    80005e54:	8526                	mv	a0,s1
    80005e56:	ffffe097          	auipc	ra,0xffffe
    80005e5a:	e88080e7          	jalr	-376(ra) # 80003cde <iunlockput>
    ilock(ip);
    80005e5e:	8556                	mv	a0,s5
    80005e60:	ffffe097          	auipc	ra,0xffffe
    80005e64:	c1c080e7          	jalr	-996(ra) # 80003a7c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005e68:	000b059b          	sext.w	a1,s6
    80005e6c:	4789                	li	a5,2
    80005e6e:	02f59563          	bne	a1,a5,80005e98 <create+0x8c>
    80005e72:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffd0c04>
    80005e76:	37f9                	addiw	a5,a5,-2
    80005e78:	17c2                	slli	a5,a5,0x30
    80005e7a:	93c1                	srli	a5,a5,0x30
    80005e7c:	4705                	li	a4,1
    80005e7e:	00f76d63          	bltu	a4,a5,80005e98 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005e82:	8556                	mv	a0,s5
    80005e84:	60a6                	ld	ra,72(sp)
    80005e86:	6406                	ld	s0,64(sp)
    80005e88:	74e2                	ld	s1,56(sp)
    80005e8a:	7942                	ld	s2,48(sp)
    80005e8c:	79a2                	ld	s3,40(sp)
    80005e8e:	7a02                	ld	s4,32(sp)
    80005e90:	6ae2                	ld	s5,24(sp)
    80005e92:	6b42                	ld	s6,16(sp)
    80005e94:	6161                	addi	sp,sp,80
    80005e96:	8082                	ret
    iunlockput(ip);
    80005e98:	8556                	mv	a0,s5
    80005e9a:	ffffe097          	auipc	ra,0xffffe
    80005e9e:	e44080e7          	jalr	-444(ra) # 80003cde <iunlockput>
    return 0;
    80005ea2:	4a81                	li	s5,0
    80005ea4:	bff9                	j	80005e82 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005ea6:	85da                	mv	a1,s6
    80005ea8:	4088                	lw	a0,0(s1)
    80005eaa:	ffffe097          	auipc	ra,0xffffe
    80005eae:	a36080e7          	jalr	-1482(ra) # 800038e0 <ialloc>
    80005eb2:	8a2a                	mv	s4,a0
    80005eb4:	c539                	beqz	a0,80005f02 <create+0xf6>
  ilock(ip);
    80005eb6:	ffffe097          	auipc	ra,0xffffe
    80005eba:	bc6080e7          	jalr	-1082(ra) # 80003a7c <ilock>
  ip->major = major;
    80005ebe:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005ec2:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005ec6:	4905                	li	s2,1
    80005ec8:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005ecc:	8552                	mv	a0,s4
    80005ece:	ffffe097          	auipc	ra,0xffffe
    80005ed2:	ae4080e7          	jalr	-1308(ra) # 800039b2 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005ed6:	000b059b          	sext.w	a1,s6
    80005eda:	03258b63          	beq	a1,s2,80005f10 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005ede:	004a2603          	lw	a2,4(s4)
    80005ee2:	fb040593          	addi	a1,s0,-80
    80005ee6:	8526                	mv	a0,s1
    80005ee8:	ffffe097          	auipc	ra,0xffffe
    80005eec:	288080e7          	jalr	648(ra) # 80004170 <dirlink>
    80005ef0:	06054f63          	bltz	a0,80005f6e <create+0x162>
  iunlockput(dp);
    80005ef4:	8526                	mv	a0,s1
    80005ef6:	ffffe097          	auipc	ra,0xffffe
    80005efa:	de8080e7          	jalr	-536(ra) # 80003cde <iunlockput>
  return ip;
    80005efe:	8ad2                	mv	s5,s4
    80005f00:	b749                	j	80005e82 <create+0x76>
    iunlockput(dp);
    80005f02:	8526                	mv	a0,s1
    80005f04:	ffffe097          	auipc	ra,0xffffe
    80005f08:	dda080e7          	jalr	-550(ra) # 80003cde <iunlockput>
    return 0;
    80005f0c:	8ad2                	mv	s5,s4
    80005f0e:	bf95                	j	80005e82 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005f10:	004a2603          	lw	a2,4(s4)
    80005f14:	00002597          	auipc	a1,0x2
    80005f18:	7d458593          	addi	a1,a1,2004 # 800086e8 <syscalls+0x1f0>
    80005f1c:	8552                	mv	a0,s4
    80005f1e:	ffffe097          	auipc	ra,0xffffe
    80005f22:	252080e7          	jalr	594(ra) # 80004170 <dirlink>
    80005f26:	04054463          	bltz	a0,80005f6e <create+0x162>
    80005f2a:	40d0                	lw	a2,4(s1)
    80005f2c:	00002597          	auipc	a1,0x2
    80005f30:	7c458593          	addi	a1,a1,1988 # 800086f0 <syscalls+0x1f8>
    80005f34:	8552                	mv	a0,s4
    80005f36:	ffffe097          	auipc	ra,0xffffe
    80005f3a:	23a080e7          	jalr	570(ra) # 80004170 <dirlink>
    80005f3e:	02054863          	bltz	a0,80005f6e <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005f42:	004a2603          	lw	a2,4(s4)
    80005f46:	fb040593          	addi	a1,s0,-80
    80005f4a:	8526                	mv	a0,s1
    80005f4c:	ffffe097          	auipc	ra,0xffffe
    80005f50:	224080e7          	jalr	548(ra) # 80004170 <dirlink>
    80005f54:	00054d63          	bltz	a0,80005f6e <create+0x162>
    dp->nlink++;  // for ".."
    80005f58:	04a4d783          	lhu	a5,74(s1)
    80005f5c:	2785                	addiw	a5,a5,1
    80005f5e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005f62:	8526                	mv	a0,s1
    80005f64:	ffffe097          	auipc	ra,0xffffe
    80005f68:	a4e080e7          	jalr	-1458(ra) # 800039b2 <iupdate>
    80005f6c:	b761                	j	80005ef4 <create+0xe8>
  ip->nlink = 0;
    80005f6e:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005f72:	8552                	mv	a0,s4
    80005f74:	ffffe097          	auipc	ra,0xffffe
    80005f78:	a3e080e7          	jalr	-1474(ra) # 800039b2 <iupdate>
  iunlockput(ip);
    80005f7c:	8552                	mv	a0,s4
    80005f7e:	ffffe097          	auipc	ra,0xffffe
    80005f82:	d60080e7          	jalr	-672(ra) # 80003cde <iunlockput>
  iunlockput(dp);
    80005f86:	8526                	mv	a0,s1
    80005f88:	ffffe097          	auipc	ra,0xffffe
    80005f8c:	d56080e7          	jalr	-682(ra) # 80003cde <iunlockput>
  return 0;
    80005f90:	bdcd                	j	80005e82 <create+0x76>
    return 0;
    80005f92:	8aaa                	mv	s5,a0
    80005f94:	b5fd                	j	80005e82 <create+0x76>

0000000080005f96 <sys_open>:

uint64
sys_open(void)
{
    80005f96:	7131                	addi	sp,sp,-192
    80005f98:	fd06                	sd	ra,184(sp)
    80005f9a:	f922                	sd	s0,176(sp)
    80005f9c:	f526                	sd	s1,168(sp)
    80005f9e:	f14a                	sd	s2,160(sp)
    80005fa0:	ed4e                	sd	s3,152(sp)
    80005fa2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005fa4:	f4c40593          	addi	a1,s0,-180
    80005fa8:	4505                	li	a0,1
    80005faa:	ffffd097          	auipc	ra,0xffffd
    80005fae:	f66080e7          	jalr	-154(ra) # 80002f10 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005fb2:	08000613          	li	a2,128
    80005fb6:	f5040593          	addi	a1,s0,-176
    80005fba:	4501                	li	a0,0
    80005fbc:	ffffd097          	auipc	ra,0xffffd
    80005fc0:	f94080e7          	jalr	-108(ra) # 80002f50 <argstr>
    80005fc4:	87aa                	mv	a5,a0
    return -1;
    80005fc6:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005fc8:	0a07c963          	bltz	a5,8000607a <sys_open+0xe4>

  begin_op();
    80005fcc:	ffffe097          	auipc	ra,0xffffe
    80005fd0:	784080e7          	jalr	1924(ra) # 80004750 <begin_op>

  if(omode & O_CREATE){
    80005fd4:	f4c42783          	lw	a5,-180(s0)
    80005fd8:	2007f793          	andi	a5,a5,512
    80005fdc:	cfc5                	beqz	a5,80006094 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005fde:	4681                	li	a3,0
    80005fe0:	4601                	li	a2,0
    80005fe2:	4589                	li	a1,2
    80005fe4:	f5040513          	addi	a0,s0,-176
    80005fe8:	00000097          	auipc	ra,0x0
    80005fec:	e24080e7          	jalr	-476(ra) # 80005e0c <create>
    80005ff0:	84aa                	mv	s1,a0
    if(ip == 0){
    80005ff2:	c959                	beqz	a0,80006088 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005ff4:	04449703          	lh	a4,68(s1)
    80005ff8:	478d                	li	a5,3
    80005ffa:	00f71763          	bne	a4,a5,80006008 <sys_open+0x72>
    80005ffe:	0464d703          	lhu	a4,70(s1)
    80006002:	47a5                	li	a5,9
    80006004:	0ce7ed63          	bltu	a5,a4,800060de <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006008:	fffff097          	auipc	ra,0xfffff
    8000600c:	b58080e7          	jalr	-1192(ra) # 80004b60 <filealloc>
    80006010:	89aa                	mv	s3,a0
    80006012:	10050363          	beqz	a0,80006118 <sys_open+0x182>
    80006016:	00000097          	auipc	ra,0x0
    8000601a:	8e4080e7          	jalr	-1820(ra) # 800058fa <fdalloc>
    8000601e:	892a                	mv	s2,a0
    80006020:	0e054763          	bltz	a0,8000610e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006024:	04449703          	lh	a4,68(s1)
    80006028:	478d                	li	a5,3
    8000602a:	0cf70563          	beq	a4,a5,800060f4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000602e:	4789                	li	a5,2
    80006030:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006034:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006038:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000603c:	f4c42783          	lw	a5,-180(s0)
    80006040:	0017c713          	xori	a4,a5,1
    80006044:	8b05                	andi	a4,a4,1
    80006046:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000604a:	0037f713          	andi	a4,a5,3
    8000604e:	00e03733          	snez	a4,a4
    80006052:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006056:	4007f793          	andi	a5,a5,1024
    8000605a:	c791                	beqz	a5,80006066 <sys_open+0xd0>
    8000605c:	04449703          	lh	a4,68(s1)
    80006060:	4789                	li	a5,2
    80006062:	0af70063          	beq	a4,a5,80006102 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006066:	8526                	mv	a0,s1
    80006068:	ffffe097          	auipc	ra,0xffffe
    8000606c:	ad6080e7          	jalr	-1322(ra) # 80003b3e <iunlock>
  end_op();
    80006070:	ffffe097          	auipc	ra,0xffffe
    80006074:	760080e7          	jalr	1888(ra) # 800047d0 <end_op>

  return fd;
    80006078:	854a                	mv	a0,s2
}
    8000607a:	70ea                	ld	ra,184(sp)
    8000607c:	744a                	ld	s0,176(sp)
    8000607e:	74aa                	ld	s1,168(sp)
    80006080:	790a                	ld	s2,160(sp)
    80006082:	69ea                	ld	s3,152(sp)
    80006084:	6129                	addi	sp,sp,192
    80006086:	8082                	ret
      end_op();
    80006088:	ffffe097          	auipc	ra,0xffffe
    8000608c:	748080e7          	jalr	1864(ra) # 800047d0 <end_op>
      return -1;
    80006090:	557d                	li	a0,-1
    80006092:	b7e5                	j	8000607a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006094:	f5040513          	addi	a0,s0,-176
    80006098:	ffffe097          	auipc	ra,0xffffe
    8000609c:	18a080e7          	jalr	394(ra) # 80004222 <namei>
    800060a0:	84aa                	mv	s1,a0
    800060a2:	c905                	beqz	a0,800060d2 <sys_open+0x13c>
    ilock(ip);
    800060a4:	ffffe097          	auipc	ra,0xffffe
    800060a8:	9d8080e7          	jalr	-1576(ra) # 80003a7c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800060ac:	04449703          	lh	a4,68(s1)
    800060b0:	4785                	li	a5,1
    800060b2:	f4f711e3          	bne	a4,a5,80005ff4 <sys_open+0x5e>
    800060b6:	f4c42783          	lw	a5,-180(s0)
    800060ba:	d7b9                	beqz	a5,80006008 <sys_open+0x72>
      iunlockput(ip);
    800060bc:	8526                	mv	a0,s1
    800060be:	ffffe097          	auipc	ra,0xffffe
    800060c2:	c20080e7          	jalr	-992(ra) # 80003cde <iunlockput>
      end_op();
    800060c6:	ffffe097          	auipc	ra,0xffffe
    800060ca:	70a080e7          	jalr	1802(ra) # 800047d0 <end_op>
      return -1;
    800060ce:	557d                	li	a0,-1
    800060d0:	b76d                	j	8000607a <sys_open+0xe4>
      end_op();
    800060d2:	ffffe097          	auipc	ra,0xffffe
    800060d6:	6fe080e7          	jalr	1790(ra) # 800047d0 <end_op>
      return -1;
    800060da:	557d                	li	a0,-1
    800060dc:	bf79                	j	8000607a <sys_open+0xe4>
    iunlockput(ip);
    800060de:	8526                	mv	a0,s1
    800060e0:	ffffe097          	auipc	ra,0xffffe
    800060e4:	bfe080e7          	jalr	-1026(ra) # 80003cde <iunlockput>
    end_op();
    800060e8:	ffffe097          	auipc	ra,0xffffe
    800060ec:	6e8080e7          	jalr	1768(ra) # 800047d0 <end_op>
    return -1;
    800060f0:	557d                	li	a0,-1
    800060f2:	b761                	j	8000607a <sys_open+0xe4>
    f->type = FD_DEVICE;
    800060f4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800060f8:	04649783          	lh	a5,70(s1)
    800060fc:	02f99223          	sh	a5,36(s3)
    80006100:	bf25                	j	80006038 <sys_open+0xa2>
    itrunc(ip);
    80006102:	8526                	mv	a0,s1
    80006104:	ffffe097          	auipc	ra,0xffffe
    80006108:	a86080e7          	jalr	-1402(ra) # 80003b8a <itrunc>
    8000610c:	bfa9                	j	80006066 <sys_open+0xd0>
      fileclose(f);
    8000610e:	854e                	mv	a0,s3
    80006110:	fffff097          	auipc	ra,0xfffff
    80006114:	b0c080e7          	jalr	-1268(ra) # 80004c1c <fileclose>
    iunlockput(ip);
    80006118:	8526                	mv	a0,s1
    8000611a:	ffffe097          	auipc	ra,0xffffe
    8000611e:	bc4080e7          	jalr	-1084(ra) # 80003cde <iunlockput>
    end_op();
    80006122:	ffffe097          	auipc	ra,0xffffe
    80006126:	6ae080e7          	jalr	1710(ra) # 800047d0 <end_op>
    return -1;
    8000612a:	557d                	li	a0,-1
    8000612c:	b7b9                	j	8000607a <sys_open+0xe4>

000000008000612e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000612e:	7175                	addi	sp,sp,-144
    80006130:	e506                	sd	ra,136(sp)
    80006132:	e122                	sd	s0,128(sp)
    80006134:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006136:	ffffe097          	auipc	ra,0xffffe
    8000613a:	61a080e7          	jalr	1562(ra) # 80004750 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000613e:	08000613          	li	a2,128
    80006142:	f7040593          	addi	a1,s0,-144
    80006146:	4501                	li	a0,0
    80006148:	ffffd097          	auipc	ra,0xffffd
    8000614c:	e08080e7          	jalr	-504(ra) # 80002f50 <argstr>
    80006150:	02054963          	bltz	a0,80006182 <sys_mkdir+0x54>
    80006154:	4681                	li	a3,0
    80006156:	4601                	li	a2,0
    80006158:	4585                	li	a1,1
    8000615a:	f7040513          	addi	a0,s0,-144
    8000615e:	00000097          	auipc	ra,0x0
    80006162:	cae080e7          	jalr	-850(ra) # 80005e0c <create>
    80006166:	cd11                	beqz	a0,80006182 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006168:	ffffe097          	auipc	ra,0xffffe
    8000616c:	b76080e7          	jalr	-1162(ra) # 80003cde <iunlockput>
  end_op();
    80006170:	ffffe097          	auipc	ra,0xffffe
    80006174:	660080e7          	jalr	1632(ra) # 800047d0 <end_op>
  return 0;
    80006178:	4501                	li	a0,0
}
    8000617a:	60aa                	ld	ra,136(sp)
    8000617c:	640a                	ld	s0,128(sp)
    8000617e:	6149                	addi	sp,sp,144
    80006180:	8082                	ret
    end_op();
    80006182:	ffffe097          	auipc	ra,0xffffe
    80006186:	64e080e7          	jalr	1614(ra) # 800047d0 <end_op>
    return -1;
    8000618a:	557d                	li	a0,-1
    8000618c:	b7fd                	j	8000617a <sys_mkdir+0x4c>

000000008000618e <sys_mknod>:

uint64
sys_mknod(void)
{
    8000618e:	7135                	addi	sp,sp,-160
    80006190:	ed06                	sd	ra,152(sp)
    80006192:	e922                	sd	s0,144(sp)
    80006194:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006196:	ffffe097          	auipc	ra,0xffffe
    8000619a:	5ba080e7          	jalr	1466(ra) # 80004750 <begin_op>
  argint(1, &major);
    8000619e:	f6c40593          	addi	a1,s0,-148
    800061a2:	4505                	li	a0,1
    800061a4:	ffffd097          	auipc	ra,0xffffd
    800061a8:	d6c080e7          	jalr	-660(ra) # 80002f10 <argint>
  argint(2, &minor);
    800061ac:	f6840593          	addi	a1,s0,-152
    800061b0:	4509                	li	a0,2
    800061b2:	ffffd097          	auipc	ra,0xffffd
    800061b6:	d5e080e7          	jalr	-674(ra) # 80002f10 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800061ba:	08000613          	li	a2,128
    800061be:	f7040593          	addi	a1,s0,-144
    800061c2:	4501                	li	a0,0
    800061c4:	ffffd097          	auipc	ra,0xffffd
    800061c8:	d8c080e7          	jalr	-628(ra) # 80002f50 <argstr>
    800061cc:	02054b63          	bltz	a0,80006202 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800061d0:	f6841683          	lh	a3,-152(s0)
    800061d4:	f6c41603          	lh	a2,-148(s0)
    800061d8:	458d                	li	a1,3
    800061da:	f7040513          	addi	a0,s0,-144
    800061de:	00000097          	auipc	ra,0x0
    800061e2:	c2e080e7          	jalr	-978(ra) # 80005e0c <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800061e6:	cd11                	beqz	a0,80006202 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800061e8:	ffffe097          	auipc	ra,0xffffe
    800061ec:	af6080e7          	jalr	-1290(ra) # 80003cde <iunlockput>
  end_op();
    800061f0:	ffffe097          	auipc	ra,0xffffe
    800061f4:	5e0080e7          	jalr	1504(ra) # 800047d0 <end_op>
  return 0;
    800061f8:	4501                	li	a0,0
}
    800061fa:	60ea                	ld	ra,152(sp)
    800061fc:	644a                	ld	s0,144(sp)
    800061fe:	610d                	addi	sp,sp,160
    80006200:	8082                	ret
    end_op();
    80006202:	ffffe097          	auipc	ra,0xffffe
    80006206:	5ce080e7          	jalr	1486(ra) # 800047d0 <end_op>
    return -1;
    8000620a:	557d                	li	a0,-1
    8000620c:	b7fd                	j	800061fa <sys_mknod+0x6c>

000000008000620e <sys_chdir>:

uint64
sys_chdir(void)
{
    8000620e:	7135                	addi	sp,sp,-160
    80006210:	ed06                	sd	ra,152(sp)
    80006212:	e922                	sd	s0,144(sp)
    80006214:	e526                	sd	s1,136(sp)
    80006216:	e14a                	sd	s2,128(sp)
    80006218:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000621a:	ffffc097          	auipc	ra,0xffffc
    8000621e:	8de080e7          	jalr	-1826(ra) # 80001af8 <myproc>
    80006222:	892a                	mv	s2,a0
  
  begin_op();
    80006224:	ffffe097          	auipc	ra,0xffffe
    80006228:	52c080e7          	jalr	1324(ra) # 80004750 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000622c:	08000613          	li	a2,128
    80006230:	f6040593          	addi	a1,s0,-160
    80006234:	4501                	li	a0,0
    80006236:	ffffd097          	auipc	ra,0xffffd
    8000623a:	d1a080e7          	jalr	-742(ra) # 80002f50 <argstr>
    8000623e:	04054b63          	bltz	a0,80006294 <sys_chdir+0x86>
    80006242:	f6040513          	addi	a0,s0,-160
    80006246:	ffffe097          	auipc	ra,0xffffe
    8000624a:	fdc080e7          	jalr	-36(ra) # 80004222 <namei>
    8000624e:	84aa                	mv	s1,a0
    80006250:	c131                	beqz	a0,80006294 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006252:	ffffe097          	auipc	ra,0xffffe
    80006256:	82a080e7          	jalr	-2006(ra) # 80003a7c <ilock>
  if(ip->type != T_DIR){
    8000625a:	04449703          	lh	a4,68(s1)
    8000625e:	4785                	li	a5,1
    80006260:	04f71063          	bne	a4,a5,800062a0 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006264:	8526                	mv	a0,s1
    80006266:	ffffe097          	auipc	ra,0xffffe
    8000626a:	8d8080e7          	jalr	-1832(ra) # 80003b3e <iunlock>
  iput(p->cwd);
    8000626e:	15093503          	ld	a0,336(s2)
    80006272:	ffffe097          	auipc	ra,0xffffe
    80006276:	9c4080e7          	jalr	-1596(ra) # 80003c36 <iput>
  end_op();
    8000627a:	ffffe097          	auipc	ra,0xffffe
    8000627e:	556080e7          	jalr	1366(ra) # 800047d0 <end_op>
  p->cwd = ip;
    80006282:	14993823          	sd	s1,336(s2)
  return 0;
    80006286:	4501                	li	a0,0
}
    80006288:	60ea                	ld	ra,152(sp)
    8000628a:	644a                	ld	s0,144(sp)
    8000628c:	64aa                	ld	s1,136(sp)
    8000628e:	690a                	ld	s2,128(sp)
    80006290:	610d                	addi	sp,sp,160
    80006292:	8082                	ret
    end_op();
    80006294:	ffffe097          	auipc	ra,0xffffe
    80006298:	53c080e7          	jalr	1340(ra) # 800047d0 <end_op>
    return -1;
    8000629c:	557d                	li	a0,-1
    8000629e:	b7ed                	j	80006288 <sys_chdir+0x7a>
    iunlockput(ip);
    800062a0:	8526                	mv	a0,s1
    800062a2:	ffffe097          	auipc	ra,0xffffe
    800062a6:	a3c080e7          	jalr	-1476(ra) # 80003cde <iunlockput>
    end_op();
    800062aa:	ffffe097          	auipc	ra,0xffffe
    800062ae:	526080e7          	jalr	1318(ra) # 800047d0 <end_op>
    return -1;
    800062b2:	557d                	li	a0,-1
    800062b4:	bfd1                	j	80006288 <sys_chdir+0x7a>

00000000800062b6 <sys_exec>:

uint64
sys_exec(void)
{
    800062b6:	7145                	addi	sp,sp,-464
    800062b8:	e786                	sd	ra,456(sp)
    800062ba:	e3a2                	sd	s0,448(sp)
    800062bc:	ff26                	sd	s1,440(sp)
    800062be:	fb4a                	sd	s2,432(sp)
    800062c0:	f74e                	sd	s3,424(sp)
    800062c2:	f352                	sd	s4,416(sp)
    800062c4:	ef56                	sd	s5,408(sp)
    800062c6:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800062c8:	e3840593          	addi	a1,s0,-456
    800062cc:	4505                	li	a0,1
    800062ce:	ffffd097          	auipc	ra,0xffffd
    800062d2:	c62080e7          	jalr	-926(ra) # 80002f30 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800062d6:	08000613          	li	a2,128
    800062da:	f4040593          	addi	a1,s0,-192
    800062de:	4501                	li	a0,0
    800062e0:	ffffd097          	auipc	ra,0xffffd
    800062e4:	c70080e7          	jalr	-912(ra) # 80002f50 <argstr>
    800062e8:	87aa                	mv	a5,a0
    return -1;
    800062ea:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800062ec:	0c07c263          	bltz	a5,800063b0 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800062f0:	10000613          	li	a2,256
    800062f4:	4581                	li	a1,0
    800062f6:	e4040513          	addi	a0,s0,-448
    800062fa:	ffffb097          	auipc	ra,0xffffb
    800062fe:	9d8080e7          	jalr	-1576(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006302:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006306:	89a6                	mv	s3,s1
    80006308:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000630a:	02000a13          	li	s4,32
    8000630e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006312:	00391793          	slli	a5,s2,0x3
    80006316:	e3040593          	addi	a1,s0,-464
    8000631a:	e3843503          	ld	a0,-456(s0)
    8000631e:	953e                	add	a0,a0,a5
    80006320:	ffffd097          	auipc	ra,0xffffd
    80006324:	b52080e7          	jalr	-1198(ra) # 80002e72 <fetchaddr>
    80006328:	02054a63          	bltz	a0,8000635c <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    8000632c:	e3043783          	ld	a5,-464(s0)
    80006330:	c3b9                	beqz	a5,80006376 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006332:	ffffa097          	auipc	ra,0xffffa
    80006336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000633a:	85aa                	mv	a1,a0
    8000633c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006340:	cd11                	beqz	a0,8000635c <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006342:	6605                	lui	a2,0x1
    80006344:	e3043503          	ld	a0,-464(s0)
    80006348:	ffffd097          	auipc	ra,0xffffd
    8000634c:	b7c080e7          	jalr	-1156(ra) # 80002ec4 <fetchstr>
    80006350:	00054663          	bltz	a0,8000635c <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80006354:	0905                	addi	s2,s2,1
    80006356:	09a1                	addi	s3,s3,8
    80006358:	fb491be3          	bne	s2,s4,8000630e <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000635c:	10048913          	addi	s2,s1,256
    80006360:	6088                	ld	a0,0(s1)
    80006362:	c531                	beqz	a0,800063ae <sys_exec+0xf8>
    kfree(argv[i]);
    80006364:	ffffa097          	auipc	ra,0xffffa
    80006368:	686080e7          	jalr	1670(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000636c:	04a1                	addi	s1,s1,8
    8000636e:	ff2499e3          	bne	s1,s2,80006360 <sys_exec+0xaa>
  return -1;
    80006372:	557d                	li	a0,-1
    80006374:	a835                	j	800063b0 <sys_exec+0xfa>
      argv[i] = 0;
    80006376:	0a8e                	slli	s5,s5,0x3
    80006378:	fc040793          	addi	a5,s0,-64
    8000637c:	9abe                	add	s5,s5,a5
    8000637e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006382:	e4040593          	addi	a1,s0,-448
    80006386:	f4040513          	addi	a0,s0,-192
    8000638a:	fffff097          	auipc	ra,0xfffff
    8000638e:	102080e7          	jalr	258(ra) # 8000548c <exec>
    80006392:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006394:	10048993          	addi	s3,s1,256
    80006398:	6088                	ld	a0,0(s1)
    8000639a:	c901                	beqz	a0,800063aa <sys_exec+0xf4>
    kfree(argv[i]);
    8000639c:	ffffa097          	auipc	ra,0xffffa
    800063a0:	64e080e7          	jalr	1614(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800063a4:	04a1                	addi	s1,s1,8
    800063a6:	ff3499e3          	bne	s1,s3,80006398 <sys_exec+0xe2>
  return ret;
    800063aa:	854a                	mv	a0,s2
    800063ac:	a011                	j	800063b0 <sys_exec+0xfa>
  return -1;
    800063ae:	557d                	li	a0,-1
}
    800063b0:	60be                	ld	ra,456(sp)
    800063b2:	641e                	ld	s0,448(sp)
    800063b4:	74fa                	ld	s1,440(sp)
    800063b6:	795a                	ld	s2,432(sp)
    800063b8:	79ba                	ld	s3,424(sp)
    800063ba:	7a1a                	ld	s4,416(sp)
    800063bc:	6afa                	ld	s5,408(sp)
    800063be:	6179                	addi	sp,sp,464
    800063c0:	8082                	ret

00000000800063c2 <sys_pipe>:

uint64
sys_pipe(void)
{
    800063c2:	7139                	addi	sp,sp,-64
    800063c4:	fc06                	sd	ra,56(sp)
    800063c6:	f822                	sd	s0,48(sp)
    800063c8:	f426                	sd	s1,40(sp)
    800063ca:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800063cc:	ffffb097          	auipc	ra,0xffffb
    800063d0:	72c080e7          	jalr	1836(ra) # 80001af8 <myproc>
    800063d4:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800063d6:	fd840593          	addi	a1,s0,-40
    800063da:	4501                	li	a0,0
    800063dc:	ffffd097          	auipc	ra,0xffffd
    800063e0:	b54080e7          	jalr	-1196(ra) # 80002f30 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800063e4:	fc840593          	addi	a1,s0,-56
    800063e8:	fd040513          	addi	a0,s0,-48
    800063ec:	fffff097          	auipc	ra,0xfffff
    800063f0:	d56080e7          	jalr	-682(ra) # 80005142 <pipealloc>
    return -1;
    800063f4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800063f6:	0c054463          	bltz	a0,800064be <sys_pipe+0xfc>
  fd0 = -1;
    800063fa:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800063fe:	fd043503          	ld	a0,-48(s0)
    80006402:	fffff097          	auipc	ra,0xfffff
    80006406:	4f8080e7          	jalr	1272(ra) # 800058fa <fdalloc>
    8000640a:	fca42223          	sw	a0,-60(s0)
    8000640e:	08054b63          	bltz	a0,800064a4 <sys_pipe+0xe2>
    80006412:	fc843503          	ld	a0,-56(s0)
    80006416:	fffff097          	auipc	ra,0xfffff
    8000641a:	4e4080e7          	jalr	1252(ra) # 800058fa <fdalloc>
    8000641e:	fca42023          	sw	a0,-64(s0)
    80006422:	06054863          	bltz	a0,80006492 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006426:	4691                	li	a3,4
    80006428:	fc440613          	addi	a2,s0,-60
    8000642c:	fd843583          	ld	a1,-40(s0)
    80006430:	68a8                	ld	a0,80(s1)
    80006432:	ffffb097          	auipc	ra,0xffffb
    80006436:	382080e7          	jalr	898(ra) # 800017b4 <copyout>
    8000643a:	02054063          	bltz	a0,8000645a <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000643e:	4691                	li	a3,4
    80006440:	fc040613          	addi	a2,s0,-64
    80006444:	fd843583          	ld	a1,-40(s0)
    80006448:	0591                	addi	a1,a1,4
    8000644a:	68a8                	ld	a0,80(s1)
    8000644c:	ffffb097          	auipc	ra,0xffffb
    80006450:	368080e7          	jalr	872(ra) # 800017b4 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006454:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006456:	06055463          	bgez	a0,800064be <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    8000645a:	fc442783          	lw	a5,-60(s0)
    8000645e:	07e9                	addi	a5,a5,26
    80006460:	078e                	slli	a5,a5,0x3
    80006462:	97a6                	add	a5,a5,s1
    80006464:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006468:	fc042503          	lw	a0,-64(s0)
    8000646c:	0569                	addi	a0,a0,26
    8000646e:	050e                	slli	a0,a0,0x3
    80006470:	94aa                	add	s1,s1,a0
    80006472:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006476:	fd043503          	ld	a0,-48(s0)
    8000647a:	ffffe097          	auipc	ra,0xffffe
    8000647e:	7a2080e7          	jalr	1954(ra) # 80004c1c <fileclose>
    fileclose(wf);
    80006482:	fc843503          	ld	a0,-56(s0)
    80006486:	ffffe097          	auipc	ra,0xffffe
    8000648a:	796080e7          	jalr	1942(ra) # 80004c1c <fileclose>
    return -1;
    8000648e:	57fd                	li	a5,-1
    80006490:	a03d                	j	800064be <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006492:	fc442783          	lw	a5,-60(s0)
    80006496:	0007c763          	bltz	a5,800064a4 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    8000649a:	07e9                	addi	a5,a5,26
    8000649c:	078e                	slli	a5,a5,0x3
    8000649e:	94be                	add	s1,s1,a5
    800064a0:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800064a4:	fd043503          	ld	a0,-48(s0)
    800064a8:	ffffe097          	auipc	ra,0xffffe
    800064ac:	774080e7          	jalr	1908(ra) # 80004c1c <fileclose>
    fileclose(wf);
    800064b0:	fc843503          	ld	a0,-56(s0)
    800064b4:	ffffe097          	auipc	ra,0xffffe
    800064b8:	768080e7          	jalr	1896(ra) # 80004c1c <fileclose>
    return -1;
    800064bc:	57fd                	li	a5,-1
}
    800064be:	853e                	mv	a0,a5
    800064c0:	70e2                	ld	ra,56(sp)
    800064c2:	7442                	ld	s0,48(sp)
    800064c4:	74a2                	ld	s1,40(sp)
    800064c6:	6121                	addi	sp,sp,64
    800064c8:	8082                	ret
    800064ca:	0000                	unimp
    800064cc:	0000                	unimp
	...

00000000800064d0 <kernelvec>:
    800064d0:	7111                	addi	sp,sp,-256
    800064d2:	e006                	sd	ra,0(sp)
    800064d4:	e40a                	sd	sp,8(sp)
    800064d6:	e80e                	sd	gp,16(sp)
    800064d8:	ec12                	sd	tp,24(sp)
    800064da:	f016                	sd	t0,32(sp)
    800064dc:	f41a                	sd	t1,40(sp)
    800064de:	f81e                	sd	t2,48(sp)
    800064e0:	fc22                	sd	s0,56(sp)
    800064e2:	e0a6                	sd	s1,64(sp)
    800064e4:	e4aa                	sd	a0,72(sp)
    800064e6:	e8ae                	sd	a1,80(sp)
    800064e8:	ecb2                	sd	a2,88(sp)
    800064ea:	f0b6                	sd	a3,96(sp)
    800064ec:	f4ba                	sd	a4,104(sp)
    800064ee:	f8be                	sd	a5,112(sp)
    800064f0:	fcc2                	sd	a6,120(sp)
    800064f2:	e146                	sd	a7,128(sp)
    800064f4:	e54a                	sd	s2,136(sp)
    800064f6:	e94e                	sd	s3,144(sp)
    800064f8:	ed52                	sd	s4,152(sp)
    800064fa:	f156                	sd	s5,160(sp)
    800064fc:	f55a                	sd	s6,168(sp)
    800064fe:	f95e                	sd	s7,176(sp)
    80006500:	fd62                	sd	s8,184(sp)
    80006502:	e1e6                	sd	s9,192(sp)
    80006504:	e5ea                	sd	s10,200(sp)
    80006506:	e9ee                	sd	s11,208(sp)
    80006508:	edf2                	sd	t3,216(sp)
    8000650a:	f1f6                	sd	t4,224(sp)
    8000650c:	f5fa                	sd	t5,232(sp)
    8000650e:	f9fe                	sd	t6,240(sp)
    80006510:	82ffc0ef          	jal	ra,80002d3e <kerneltrap>
    80006514:	6082                	ld	ra,0(sp)
    80006516:	6122                	ld	sp,8(sp)
    80006518:	61c2                	ld	gp,16(sp)
    8000651a:	7282                	ld	t0,32(sp)
    8000651c:	7322                	ld	t1,40(sp)
    8000651e:	73c2                	ld	t2,48(sp)
    80006520:	7462                	ld	s0,56(sp)
    80006522:	6486                	ld	s1,64(sp)
    80006524:	6526                	ld	a0,72(sp)
    80006526:	65c6                	ld	a1,80(sp)
    80006528:	6666                	ld	a2,88(sp)
    8000652a:	7686                	ld	a3,96(sp)
    8000652c:	7726                	ld	a4,104(sp)
    8000652e:	77c6                	ld	a5,112(sp)
    80006530:	7866                	ld	a6,120(sp)
    80006532:	688a                	ld	a7,128(sp)
    80006534:	692a                	ld	s2,136(sp)
    80006536:	69ca                	ld	s3,144(sp)
    80006538:	6a6a                	ld	s4,152(sp)
    8000653a:	7a8a                	ld	s5,160(sp)
    8000653c:	7b2a                	ld	s6,168(sp)
    8000653e:	7bca                	ld	s7,176(sp)
    80006540:	7c6a                	ld	s8,184(sp)
    80006542:	6c8e                	ld	s9,192(sp)
    80006544:	6d2e                	ld	s10,200(sp)
    80006546:	6dce                	ld	s11,208(sp)
    80006548:	6e6e                	ld	t3,216(sp)
    8000654a:	7e8e                	ld	t4,224(sp)
    8000654c:	7f2e                	ld	t5,232(sp)
    8000654e:	7fce                	ld	t6,240(sp)
    80006550:	6111                	addi	sp,sp,256
    80006552:	10200073          	sret
    80006556:	00000013          	nop
    8000655a:	00000013          	nop
    8000655e:	0001                	nop

0000000080006560 <timervec>:
    80006560:	34051573          	csrrw	a0,mscratch,a0
    80006564:	e10c                	sd	a1,0(a0)
    80006566:	e510                	sd	a2,8(a0)
    80006568:	e914                	sd	a3,16(a0)
    8000656a:	6d0c                	ld	a1,24(a0)
    8000656c:	7110                	ld	a2,32(a0)
    8000656e:	6194                	ld	a3,0(a1)
    80006570:	96b2                	add	a3,a3,a2
    80006572:	e194                	sd	a3,0(a1)
    80006574:	4589                	li	a1,2
    80006576:	14459073          	csrw	sip,a1
    8000657a:	6914                	ld	a3,16(a0)
    8000657c:	6510                	ld	a2,8(a0)
    8000657e:	610c                	ld	a1,0(a0)
    80006580:	34051573          	csrrw	a0,mscratch,a0
    80006584:	30200073          	mret
	...

000000008000658a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000658a:	1141                	addi	sp,sp,-16
    8000658c:	e422                	sd	s0,8(sp)
    8000658e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006590:	0c0007b7          	lui	a5,0xc000
    80006594:	4705                	li	a4,1
    80006596:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006598:	c3d8                	sw	a4,4(a5)
}
    8000659a:	6422                	ld	s0,8(sp)
    8000659c:	0141                	addi	sp,sp,16
    8000659e:	8082                	ret

00000000800065a0 <plicinithart>:

void
plicinithart(void)
{
    800065a0:	1141                	addi	sp,sp,-16
    800065a2:	e406                	sd	ra,8(sp)
    800065a4:	e022                	sd	s0,0(sp)
    800065a6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800065a8:	ffffb097          	auipc	ra,0xffffb
    800065ac:	524080e7          	jalr	1316(ra) # 80001acc <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800065b0:	0085171b          	slliw	a4,a0,0x8
    800065b4:	0c0027b7          	lui	a5,0xc002
    800065b8:	97ba                	add	a5,a5,a4
    800065ba:	40200713          	li	a4,1026
    800065be:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800065c2:	00d5151b          	slliw	a0,a0,0xd
    800065c6:	0c2017b7          	lui	a5,0xc201
    800065ca:	953e                	add	a0,a0,a5
    800065cc:	00052023          	sw	zero,0(a0)
}
    800065d0:	60a2                	ld	ra,8(sp)
    800065d2:	6402                	ld	s0,0(sp)
    800065d4:	0141                	addi	sp,sp,16
    800065d6:	8082                	ret

00000000800065d8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800065d8:	1141                	addi	sp,sp,-16
    800065da:	e406                	sd	ra,8(sp)
    800065dc:	e022                	sd	s0,0(sp)
    800065de:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800065e0:	ffffb097          	auipc	ra,0xffffb
    800065e4:	4ec080e7          	jalr	1260(ra) # 80001acc <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800065e8:	00d5179b          	slliw	a5,a0,0xd
    800065ec:	0c201537          	lui	a0,0xc201
    800065f0:	953e                	add	a0,a0,a5
  return irq;
}
    800065f2:	4148                	lw	a0,4(a0)
    800065f4:	60a2                	ld	ra,8(sp)
    800065f6:	6402                	ld	s0,0(sp)
    800065f8:	0141                	addi	sp,sp,16
    800065fa:	8082                	ret

00000000800065fc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800065fc:	1101                	addi	sp,sp,-32
    800065fe:	ec06                	sd	ra,24(sp)
    80006600:	e822                	sd	s0,16(sp)
    80006602:	e426                	sd	s1,8(sp)
    80006604:	1000                	addi	s0,sp,32
    80006606:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006608:	ffffb097          	auipc	ra,0xffffb
    8000660c:	4c4080e7          	jalr	1220(ra) # 80001acc <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006610:	00d5151b          	slliw	a0,a0,0xd
    80006614:	0c2017b7          	lui	a5,0xc201
    80006618:	97aa                	add	a5,a5,a0
    8000661a:	c3c4                	sw	s1,4(a5)
}
    8000661c:	60e2                	ld	ra,24(sp)
    8000661e:	6442                	ld	s0,16(sp)
    80006620:	64a2                	ld	s1,8(sp)
    80006622:	6105                	addi	sp,sp,32
    80006624:	8082                	ret

0000000080006626 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006626:	1141                	addi	sp,sp,-16
    80006628:	e406                	sd	ra,8(sp)
    8000662a:	e022                	sd	s0,0(sp)
    8000662c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000662e:	479d                	li	a5,7
    80006630:	04a7cc63          	blt	a5,a0,80006688 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006634:	00028797          	auipc	a5,0x28
    80006638:	ccc78793          	addi	a5,a5,-820 # 8002e300 <disk>
    8000663c:	97aa                	add	a5,a5,a0
    8000663e:	0187c783          	lbu	a5,24(a5)
    80006642:	ebb9                	bnez	a5,80006698 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006644:	00451613          	slli	a2,a0,0x4
    80006648:	00028797          	auipc	a5,0x28
    8000664c:	cb878793          	addi	a5,a5,-840 # 8002e300 <disk>
    80006650:	6394                	ld	a3,0(a5)
    80006652:	96b2                	add	a3,a3,a2
    80006654:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006658:	6398                	ld	a4,0(a5)
    8000665a:	9732                	add	a4,a4,a2
    8000665c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006660:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006664:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006668:	953e                	add	a0,a0,a5
    8000666a:	4785                	li	a5,1
    8000666c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006670:	00028517          	auipc	a0,0x28
    80006674:	ca850513          	addi	a0,a0,-856 # 8002e318 <disk+0x18>
    80006678:	ffffc097          	auipc	ra,0xffffc
    8000667c:	c20080e7          	jalr	-992(ra) # 80002298 <wakeup>
}
    80006680:	60a2                	ld	ra,8(sp)
    80006682:	6402                	ld	s0,0(sp)
    80006684:	0141                	addi	sp,sp,16
    80006686:	8082                	ret
    panic("free_desc 1");
    80006688:	00002517          	auipc	a0,0x2
    8000668c:	19850513          	addi	a0,a0,408 # 80008820 <syscalls+0x328>
    80006690:	ffffa097          	auipc	ra,0xffffa
    80006694:	eae080e7          	jalr	-338(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006698:	00002517          	auipc	a0,0x2
    8000669c:	19850513          	addi	a0,a0,408 # 80008830 <syscalls+0x338>
    800066a0:	ffffa097          	auipc	ra,0xffffa
    800066a4:	e9e080e7          	jalr	-354(ra) # 8000053e <panic>

00000000800066a8 <virtio_disk_init>:
{
    800066a8:	1101                	addi	sp,sp,-32
    800066aa:	ec06                	sd	ra,24(sp)
    800066ac:	e822                	sd	s0,16(sp)
    800066ae:	e426                	sd	s1,8(sp)
    800066b0:	e04a                	sd	s2,0(sp)
    800066b2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800066b4:	00002597          	auipc	a1,0x2
    800066b8:	18c58593          	addi	a1,a1,396 # 80008840 <syscalls+0x348>
    800066bc:	00028517          	auipc	a0,0x28
    800066c0:	d6c50513          	addi	a0,a0,-660 # 8002e428 <disk+0x128>
    800066c4:	ffffa097          	auipc	ra,0xffffa
    800066c8:	482080e7          	jalr	1154(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800066cc:	100017b7          	lui	a5,0x10001
    800066d0:	4398                	lw	a4,0(a5)
    800066d2:	2701                	sext.w	a4,a4
    800066d4:	747277b7          	lui	a5,0x74727
    800066d8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800066dc:	14f71c63          	bne	a4,a5,80006834 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800066e0:	100017b7          	lui	a5,0x10001
    800066e4:	43dc                	lw	a5,4(a5)
    800066e6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800066e8:	4709                	li	a4,2
    800066ea:	14e79563          	bne	a5,a4,80006834 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800066ee:	100017b7          	lui	a5,0x10001
    800066f2:	479c                	lw	a5,8(a5)
    800066f4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800066f6:	12e79f63          	bne	a5,a4,80006834 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800066fa:	100017b7          	lui	a5,0x10001
    800066fe:	47d8                	lw	a4,12(a5)
    80006700:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006702:	554d47b7          	lui	a5,0x554d4
    80006706:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000670a:	12f71563          	bne	a4,a5,80006834 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000670e:	100017b7          	lui	a5,0x10001
    80006712:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006716:	4705                	li	a4,1
    80006718:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000671a:	470d                	li	a4,3
    8000671c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000671e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006720:	c7ffe737          	lui	a4,0xc7ffe
    80006724:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd031f>
    80006728:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000672a:	2701                	sext.w	a4,a4
    8000672c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000672e:	472d                	li	a4,11
    80006730:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006732:	5bbc                	lw	a5,112(a5)
    80006734:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006738:	8ba1                	andi	a5,a5,8
    8000673a:	10078563          	beqz	a5,80006844 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000673e:	100017b7          	lui	a5,0x10001
    80006742:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006746:	43fc                	lw	a5,68(a5)
    80006748:	2781                	sext.w	a5,a5
    8000674a:	10079563          	bnez	a5,80006854 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000674e:	100017b7          	lui	a5,0x10001
    80006752:	5bdc                	lw	a5,52(a5)
    80006754:	2781                	sext.w	a5,a5
  if(max == 0)
    80006756:	10078763          	beqz	a5,80006864 <virtio_disk_init+0x1bc>
  if(max < NUM)
    8000675a:	471d                	li	a4,7
    8000675c:	10f77c63          	bgeu	a4,a5,80006874 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80006760:	ffffa097          	auipc	ra,0xffffa
    80006764:	386080e7          	jalr	902(ra) # 80000ae6 <kalloc>
    80006768:	00028497          	auipc	s1,0x28
    8000676c:	b9848493          	addi	s1,s1,-1128 # 8002e300 <disk>
    80006770:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006772:	ffffa097          	auipc	ra,0xffffa
    80006776:	374080e7          	jalr	884(ra) # 80000ae6 <kalloc>
    8000677a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000677c:	ffffa097          	auipc	ra,0xffffa
    80006780:	36a080e7          	jalr	874(ra) # 80000ae6 <kalloc>
    80006784:	87aa                	mv	a5,a0
    80006786:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006788:	6088                	ld	a0,0(s1)
    8000678a:	cd6d                	beqz	a0,80006884 <virtio_disk_init+0x1dc>
    8000678c:	00028717          	auipc	a4,0x28
    80006790:	b7c73703          	ld	a4,-1156(a4) # 8002e308 <disk+0x8>
    80006794:	cb65                	beqz	a4,80006884 <virtio_disk_init+0x1dc>
    80006796:	c7fd                	beqz	a5,80006884 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80006798:	6605                	lui	a2,0x1
    8000679a:	4581                	li	a1,0
    8000679c:	ffffa097          	auipc	ra,0xffffa
    800067a0:	536080e7          	jalr	1334(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    800067a4:	00028497          	auipc	s1,0x28
    800067a8:	b5c48493          	addi	s1,s1,-1188 # 8002e300 <disk>
    800067ac:	6605                	lui	a2,0x1
    800067ae:	4581                	li	a1,0
    800067b0:	6488                	ld	a0,8(s1)
    800067b2:	ffffa097          	auipc	ra,0xffffa
    800067b6:	520080e7          	jalr	1312(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    800067ba:	6605                	lui	a2,0x1
    800067bc:	4581                	li	a1,0
    800067be:	6888                	ld	a0,16(s1)
    800067c0:	ffffa097          	auipc	ra,0xffffa
    800067c4:	512080e7          	jalr	1298(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800067c8:	100017b7          	lui	a5,0x10001
    800067cc:	4721                	li	a4,8
    800067ce:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800067d0:	4098                	lw	a4,0(s1)
    800067d2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800067d6:	40d8                	lw	a4,4(s1)
    800067d8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800067dc:	6498                	ld	a4,8(s1)
    800067de:	0007069b          	sext.w	a3,a4
    800067e2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800067e6:	9701                	srai	a4,a4,0x20
    800067e8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800067ec:	6898                	ld	a4,16(s1)
    800067ee:	0007069b          	sext.w	a3,a4
    800067f2:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800067f6:	9701                	srai	a4,a4,0x20
    800067f8:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800067fc:	4705                	li	a4,1
    800067fe:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006800:	00e48c23          	sb	a4,24(s1)
    80006804:	00e48ca3          	sb	a4,25(s1)
    80006808:	00e48d23          	sb	a4,26(s1)
    8000680c:	00e48da3          	sb	a4,27(s1)
    80006810:	00e48e23          	sb	a4,28(s1)
    80006814:	00e48ea3          	sb	a4,29(s1)
    80006818:	00e48f23          	sb	a4,30(s1)
    8000681c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006820:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006824:	0727a823          	sw	s2,112(a5)
}
    80006828:	60e2                	ld	ra,24(sp)
    8000682a:	6442                	ld	s0,16(sp)
    8000682c:	64a2                	ld	s1,8(sp)
    8000682e:	6902                	ld	s2,0(sp)
    80006830:	6105                	addi	sp,sp,32
    80006832:	8082                	ret
    panic("could not find virtio disk");
    80006834:	00002517          	auipc	a0,0x2
    80006838:	01c50513          	addi	a0,a0,28 # 80008850 <syscalls+0x358>
    8000683c:	ffffa097          	auipc	ra,0xffffa
    80006840:	d02080e7          	jalr	-766(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006844:	00002517          	auipc	a0,0x2
    80006848:	02c50513          	addi	a0,a0,44 # 80008870 <syscalls+0x378>
    8000684c:	ffffa097          	auipc	ra,0xffffa
    80006850:	cf2080e7          	jalr	-782(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006854:	00002517          	auipc	a0,0x2
    80006858:	03c50513          	addi	a0,a0,60 # 80008890 <syscalls+0x398>
    8000685c:	ffffa097          	auipc	ra,0xffffa
    80006860:	ce2080e7          	jalr	-798(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006864:	00002517          	auipc	a0,0x2
    80006868:	04c50513          	addi	a0,a0,76 # 800088b0 <syscalls+0x3b8>
    8000686c:	ffffa097          	auipc	ra,0xffffa
    80006870:	cd2080e7          	jalr	-814(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006874:	00002517          	auipc	a0,0x2
    80006878:	05c50513          	addi	a0,a0,92 # 800088d0 <syscalls+0x3d8>
    8000687c:	ffffa097          	auipc	ra,0xffffa
    80006880:	cc2080e7          	jalr	-830(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80006884:	00002517          	auipc	a0,0x2
    80006888:	06c50513          	addi	a0,a0,108 # 800088f0 <syscalls+0x3f8>
    8000688c:	ffffa097          	auipc	ra,0xffffa
    80006890:	cb2080e7          	jalr	-846(ra) # 8000053e <panic>

0000000080006894 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006894:	7119                	addi	sp,sp,-128
    80006896:	fc86                	sd	ra,120(sp)
    80006898:	f8a2                	sd	s0,112(sp)
    8000689a:	f4a6                	sd	s1,104(sp)
    8000689c:	f0ca                	sd	s2,96(sp)
    8000689e:	ecce                	sd	s3,88(sp)
    800068a0:	e8d2                	sd	s4,80(sp)
    800068a2:	e4d6                	sd	s5,72(sp)
    800068a4:	e0da                	sd	s6,64(sp)
    800068a6:	fc5e                	sd	s7,56(sp)
    800068a8:	f862                	sd	s8,48(sp)
    800068aa:	f466                	sd	s9,40(sp)
    800068ac:	f06a                	sd	s10,32(sp)
    800068ae:	ec6e                	sd	s11,24(sp)
    800068b0:	0100                	addi	s0,sp,128
    800068b2:	8aaa                	mv	s5,a0
    800068b4:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800068b6:	00c52d03          	lw	s10,12(a0)
    800068ba:	001d1d1b          	slliw	s10,s10,0x1
    800068be:	1d02                	slli	s10,s10,0x20
    800068c0:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800068c4:	00028517          	auipc	a0,0x28
    800068c8:	b6450513          	addi	a0,a0,-1180 # 8002e428 <disk+0x128>
    800068cc:	ffffa097          	auipc	ra,0xffffa
    800068d0:	30a080e7          	jalr	778(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    800068d4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800068d6:	44a1                	li	s1,8
      disk.free[i] = 0;
    800068d8:	00028b97          	auipc	s7,0x28
    800068dc:	a28b8b93          	addi	s7,s7,-1496 # 8002e300 <disk>
  for(int i = 0; i < 3; i++){
    800068e0:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800068e2:	00028c97          	auipc	s9,0x28
    800068e6:	b46c8c93          	addi	s9,s9,-1210 # 8002e428 <disk+0x128>
    800068ea:	a08d                	j	8000694c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800068ec:	00fb8733          	add	a4,s7,a5
    800068f0:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800068f4:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800068f6:	0207c563          	bltz	a5,80006920 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800068fa:	2905                	addiw	s2,s2,1
    800068fc:	0611                	addi	a2,a2,4
    800068fe:	05690c63          	beq	s2,s6,80006956 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006902:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006904:	00028717          	auipc	a4,0x28
    80006908:	9fc70713          	addi	a4,a4,-1540 # 8002e300 <disk>
    8000690c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000690e:	01874683          	lbu	a3,24(a4)
    80006912:	fee9                	bnez	a3,800068ec <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006914:	2785                	addiw	a5,a5,1
    80006916:	0705                	addi	a4,a4,1
    80006918:	fe979be3          	bne	a5,s1,8000690e <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000691c:	57fd                	li	a5,-1
    8000691e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006920:	01205d63          	blez	s2,8000693a <virtio_disk_rw+0xa6>
    80006924:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006926:	000a2503          	lw	a0,0(s4)
    8000692a:	00000097          	auipc	ra,0x0
    8000692e:	cfc080e7          	jalr	-772(ra) # 80006626 <free_desc>
      for(int j = 0; j < i; j++)
    80006932:	2d85                	addiw	s11,s11,1
    80006934:	0a11                	addi	s4,s4,4
    80006936:	ffb918e3          	bne	s2,s11,80006926 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000693a:	85e6                	mv	a1,s9
    8000693c:	00028517          	auipc	a0,0x28
    80006940:	9dc50513          	addi	a0,a0,-1572 # 8002e318 <disk+0x18>
    80006944:	ffffc097          	auipc	ra,0xffffc
    80006948:	8f0080e7          	jalr	-1808(ra) # 80002234 <sleep>
  for(int i = 0; i < 3; i++){
    8000694c:	f8040a13          	addi	s4,s0,-128
{
    80006950:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006952:	894e                	mv	s2,s3
    80006954:	b77d                	j	80006902 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006956:	f8042583          	lw	a1,-128(s0)
    8000695a:	00a58793          	addi	a5,a1,10
    8000695e:	0792                	slli	a5,a5,0x4

  if(write)
    80006960:	00028617          	auipc	a2,0x28
    80006964:	9a060613          	addi	a2,a2,-1632 # 8002e300 <disk>
    80006968:	00f60733          	add	a4,a2,a5
    8000696c:	018036b3          	snez	a3,s8
    80006970:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006972:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006976:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000697a:	f6078693          	addi	a3,a5,-160
    8000697e:	6218                	ld	a4,0(a2)
    80006980:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006982:	00878513          	addi	a0,a5,8
    80006986:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006988:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000698a:	6208                	ld	a0,0(a2)
    8000698c:	96aa                	add	a3,a3,a0
    8000698e:	4741                	li	a4,16
    80006990:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006992:	4705                	li	a4,1
    80006994:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006998:	f8442703          	lw	a4,-124(s0)
    8000699c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800069a0:	0712                	slli	a4,a4,0x4
    800069a2:	953a                	add	a0,a0,a4
    800069a4:	058a8693          	addi	a3,s5,88
    800069a8:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800069aa:	6208                	ld	a0,0(a2)
    800069ac:	972a                	add	a4,a4,a0
    800069ae:	40000693          	li	a3,1024
    800069b2:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800069b4:	001c3c13          	seqz	s8,s8
    800069b8:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800069ba:	001c6c13          	ori	s8,s8,1
    800069be:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    800069c2:	f8842603          	lw	a2,-120(s0)
    800069c6:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800069ca:	00028697          	auipc	a3,0x28
    800069ce:	93668693          	addi	a3,a3,-1738 # 8002e300 <disk>
    800069d2:	00258713          	addi	a4,a1,2
    800069d6:	0712                	slli	a4,a4,0x4
    800069d8:	9736                	add	a4,a4,a3
    800069da:	587d                	li	a6,-1
    800069dc:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800069e0:	0612                	slli	a2,a2,0x4
    800069e2:	9532                	add	a0,a0,a2
    800069e4:	f9078793          	addi	a5,a5,-112
    800069e8:	97b6                	add	a5,a5,a3
    800069ea:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    800069ec:	629c                	ld	a5,0(a3)
    800069ee:	97b2                	add	a5,a5,a2
    800069f0:	4605                	li	a2,1
    800069f2:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800069f4:	4509                	li	a0,2
    800069f6:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    800069fa:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800069fe:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006a02:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006a06:	6698                	ld	a4,8(a3)
    80006a08:	00275783          	lhu	a5,2(a4)
    80006a0c:	8b9d                	andi	a5,a5,7
    80006a0e:	0786                	slli	a5,a5,0x1
    80006a10:	97ba                	add	a5,a5,a4
    80006a12:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006a16:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006a1a:	6698                	ld	a4,8(a3)
    80006a1c:	00275783          	lhu	a5,2(a4)
    80006a20:	2785                	addiw	a5,a5,1
    80006a22:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006a26:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006a2a:	100017b7          	lui	a5,0x10001
    80006a2e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006a32:	004aa783          	lw	a5,4(s5)
    80006a36:	02c79163          	bne	a5,a2,80006a58 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006a3a:	00028917          	auipc	s2,0x28
    80006a3e:	9ee90913          	addi	s2,s2,-1554 # 8002e428 <disk+0x128>
  while(b->disk == 1) {
    80006a42:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006a44:	85ca                	mv	a1,s2
    80006a46:	8556                	mv	a0,s5
    80006a48:	ffffb097          	auipc	ra,0xffffb
    80006a4c:	7ec080e7          	jalr	2028(ra) # 80002234 <sleep>
  while(b->disk == 1) {
    80006a50:	004aa783          	lw	a5,4(s5)
    80006a54:	fe9788e3          	beq	a5,s1,80006a44 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006a58:	f8042903          	lw	s2,-128(s0)
    80006a5c:	00290793          	addi	a5,s2,2
    80006a60:	00479713          	slli	a4,a5,0x4
    80006a64:	00028797          	auipc	a5,0x28
    80006a68:	89c78793          	addi	a5,a5,-1892 # 8002e300 <disk>
    80006a6c:	97ba                	add	a5,a5,a4
    80006a6e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006a72:	00028997          	auipc	s3,0x28
    80006a76:	88e98993          	addi	s3,s3,-1906 # 8002e300 <disk>
    80006a7a:	00491713          	slli	a4,s2,0x4
    80006a7e:	0009b783          	ld	a5,0(s3)
    80006a82:	97ba                	add	a5,a5,a4
    80006a84:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006a88:	854a                	mv	a0,s2
    80006a8a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006a8e:	00000097          	auipc	ra,0x0
    80006a92:	b98080e7          	jalr	-1128(ra) # 80006626 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006a96:	8885                	andi	s1,s1,1
    80006a98:	f0ed                	bnez	s1,80006a7a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006a9a:	00028517          	auipc	a0,0x28
    80006a9e:	98e50513          	addi	a0,a0,-1650 # 8002e428 <disk+0x128>
    80006aa2:	ffffa097          	auipc	ra,0xffffa
    80006aa6:	1e8080e7          	jalr	488(ra) # 80000c8a <release>
}
    80006aaa:	70e6                	ld	ra,120(sp)
    80006aac:	7446                	ld	s0,112(sp)
    80006aae:	74a6                	ld	s1,104(sp)
    80006ab0:	7906                	ld	s2,96(sp)
    80006ab2:	69e6                	ld	s3,88(sp)
    80006ab4:	6a46                	ld	s4,80(sp)
    80006ab6:	6aa6                	ld	s5,72(sp)
    80006ab8:	6b06                	ld	s6,64(sp)
    80006aba:	7be2                	ld	s7,56(sp)
    80006abc:	7c42                	ld	s8,48(sp)
    80006abe:	7ca2                	ld	s9,40(sp)
    80006ac0:	7d02                	ld	s10,32(sp)
    80006ac2:	6de2                	ld	s11,24(sp)
    80006ac4:	6109                	addi	sp,sp,128
    80006ac6:	8082                	ret

0000000080006ac8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006ac8:	1101                	addi	sp,sp,-32
    80006aca:	ec06                	sd	ra,24(sp)
    80006acc:	e822                	sd	s0,16(sp)
    80006ace:	e426                	sd	s1,8(sp)
    80006ad0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006ad2:	00028497          	auipc	s1,0x28
    80006ad6:	82e48493          	addi	s1,s1,-2002 # 8002e300 <disk>
    80006ada:	00028517          	auipc	a0,0x28
    80006ade:	94e50513          	addi	a0,a0,-1714 # 8002e428 <disk+0x128>
    80006ae2:	ffffa097          	auipc	ra,0xffffa
    80006ae6:	0f4080e7          	jalr	244(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006aea:	10001737          	lui	a4,0x10001
    80006aee:	533c                	lw	a5,96(a4)
    80006af0:	8b8d                	andi	a5,a5,3
    80006af2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006af4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006af8:	689c                	ld	a5,16(s1)
    80006afa:	0204d703          	lhu	a4,32(s1)
    80006afe:	0027d783          	lhu	a5,2(a5)
    80006b02:	04f70863          	beq	a4,a5,80006b52 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006b06:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006b0a:	6898                	ld	a4,16(s1)
    80006b0c:	0204d783          	lhu	a5,32(s1)
    80006b10:	8b9d                	andi	a5,a5,7
    80006b12:	078e                	slli	a5,a5,0x3
    80006b14:	97ba                	add	a5,a5,a4
    80006b16:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006b18:	00278713          	addi	a4,a5,2
    80006b1c:	0712                	slli	a4,a4,0x4
    80006b1e:	9726                	add	a4,a4,s1
    80006b20:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006b24:	e721                	bnez	a4,80006b6c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006b26:	0789                	addi	a5,a5,2
    80006b28:	0792                	slli	a5,a5,0x4
    80006b2a:	97a6                	add	a5,a5,s1
    80006b2c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006b2e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006b32:	ffffb097          	auipc	ra,0xffffb
    80006b36:	766080e7          	jalr	1894(ra) # 80002298 <wakeup>

    disk.used_idx += 1;
    80006b3a:	0204d783          	lhu	a5,32(s1)
    80006b3e:	2785                	addiw	a5,a5,1
    80006b40:	17c2                	slli	a5,a5,0x30
    80006b42:	93c1                	srli	a5,a5,0x30
    80006b44:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006b48:	6898                	ld	a4,16(s1)
    80006b4a:	00275703          	lhu	a4,2(a4)
    80006b4e:	faf71ce3          	bne	a4,a5,80006b06 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006b52:	00028517          	auipc	a0,0x28
    80006b56:	8d650513          	addi	a0,a0,-1834 # 8002e428 <disk+0x128>
    80006b5a:	ffffa097          	auipc	ra,0xffffa
    80006b5e:	130080e7          	jalr	304(ra) # 80000c8a <release>
}
    80006b62:	60e2                	ld	ra,24(sp)
    80006b64:	6442                	ld	s0,16(sp)
    80006b66:	64a2                	ld	s1,8(sp)
    80006b68:	6105                	addi	sp,sp,32
    80006b6a:	8082                	ret
      panic("virtio_disk_intr status");
    80006b6c:	00002517          	auipc	a0,0x2
    80006b70:	d9c50513          	addi	a0,a0,-612 # 80008908 <syscalls+0x410>
    80006b74:	ffffa097          	auipc	ra,0xffffa
    80006b78:	9ca080e7          	jalr	-1590(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
