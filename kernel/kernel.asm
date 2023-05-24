
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
    80000068:	6ec78793          	addi	a5,a5,1772 # 80006750 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffc81bf>
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
    80000130:	596080e7          	jalr	1430(ra) # 800026c2 <either_copyin>
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
    800001c4:	93e080e7          	jalr	-1730(ra) # 80001afe <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	344080e7          	jalr	836(ra) # 8000250c <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	078080e7          	jalr	120(ra) # 8000224e <sleep>
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
    80000216:	45a080e7          	jalr	1114(ra) # 8000266c <either_copyout>
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
    800002f6:	426080e7          	jalr	1062(ra) # 80002718 <procdump>
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
    8000044a:	e6c080e7          	jalr	-404(ra) # 800022b2 <wakeup>
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
    80000478:	00035797          	auipc	a5,0x35
    8000047c:	03078793          	addi	a5,a5,48 # 800354a8 <devsw>
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
    80000896:	a20080e7          	jalr	-1504(ra) # 800022b2 <wakeup>
    
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
    80000920:	932080e7          	jalr	-1742(ra) # 8000224e <sleep>
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
    800009fe:	00036797          	auipc	a5,0x36
    80000a02:	c4278793          	addi	a5,a5,-958 # 80036640 <end>
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
    80000ace:	00036517          	auipc	a0,0x36
    80000ad2:	b7250513          	addi	a0,a0,-1166 # 80036640 <end>
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
    80000b74:	f72080e7          	jalr	-142(ra) # 80001ae2 <mycpu>
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
    80000ba6:	f40080e7          	jalr	-192(ra) # 80001ae2 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	f34080e7          	jalr	-204(ra) # 80001ae2 <mycpu>
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
    80000bca:	f1c080e7          	jalr	-228(ra) # 80001ae2 <mycpu>
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
    80000c0a:	edc080e7          	jalr	-292(ra) # 80001ae2 <mycpu>
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
    80000c36:	eb0080e7          	jalr	-336(ra) # 80001ae2 <mycpu>
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
    80000e84:	c52080e7          	jalr	-942(ra) # 80001ad2 <cpuid>
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
    80000ea0:	c36080e7          	jalr	-970(ra) # 80001ad2 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6da080e7          	jalr	1754(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	18c080e7          	jalr	396(ra) # 80001042 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	c4e080e7          	jalr	-946(ra) # 80002b0c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00006097          	auipc	ra,0x6
    80000eca:	8ca080e7          	jalr	-1846(ra) # 80006790 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	1ce080e7          	jalr	462(ra) # 8000209c <scheduler>
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
    80000f22:	3da080e7          	jalr	986(ra) # 800012f8 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	11c080e7          	jalr	284(ra) # 80001042 <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	af0080e7          	jalr	-1296(ra) # 80001a1e <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	bae080e7          	jalr	-1106(ra) # 80002ae4 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	bce080e7          	jalr	-1074(ra) # 80002b0c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00006097          	auipc	ra,0x6
    80000f4a:	834080e7          	jalr	-1996(ra) # 8000677a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00006097          	auipc	ra,0x6
    80000f52:	842080e7          	jalr	-1982(ra) # 80006790 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	45c080e7          	jalr	1116(ra) # 800033b2 <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	b00080e7          	jalr	-1280(ra) # 80003a5e <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	db0080e7          	jalr	-592(ra) # 80004d16 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00006097          	auipc	ra,0x6
    80000f72:	92a080e7          	jalr	-1750(ra) # 80006898 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	e70080e7          	jalr	-400(ra) # 80001de6 <userinit>
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
    80000faa:	b58080e7          	jalr	-1192(ra) # 80001afe <myproc>
  struct metaData *page=proc->pagesInPysical;
  if(do_free&& proc->pid>2 &&pagetable==proc->pagetable &&(*pte & PTE_V)){
    80000fae:	c8a9                	beqz	s1,80001000 <helperUnmap+0x72>
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
    80000fd4:	cf8d                	beqz	a5,8000100e <helperUnmap+0x80>
  struct metaData *page=proc->pagesInPysical;
    80000fd6:	28050793          	addi	a5,a0,640
    while(page< & proc->pagesInPysical[MAX_PSYC_PAGES]){
    80000fda:	48050693          	addi	a3,a0,1152
      if(page->va==a){
    80000fde:	6398                	ld	a4,0(a5)
    80000fe0:	01470763          	beq	a4,s4,80000fee <helperUnmap+0x60>
      page++;
    80000fe4:	02078793          	addi	a5,a5,32
    while(page< & proc->pagesInPysical[MAX_PSYC_PAGES]){
    80000fe8:	fed79be3          	bne	a5,a3,80000fde <helperUnmap+0x50>
    80000fec:	a00d                	j	8000100e <helperUnmap+0x80>
        page->idxIsHere=0;
    80000fee:	0007b423          	sd	zero,8(a5)
        page->va=0;
    80000ff2:	0007b023          	sd	zero,0(a5)
        proc->physicalPagesCount--;
    80000ff6:	27053783          	ld	a5,624(a0)
    80000ffa:	17fd                	addi	a5,a5,-1
    80000ffc:	26f53823          	sd	a5,624(a0)
  if(proc->pid>2 &&pagetable==proc->pagetable &&(*pte & PTE_V)){
    80001000:	5918                	lw	a4,48(a0)
    80001002:	4789                	li	a5,2
    80001004:	fae7dde3          	bge	a5,a4,80000fbe <helperUnmap+0x30>
    80001008:	693c                	ld	a5,80(a0)
    8000100a:	fb279ae3          	bne	a5,s2,80000fbe <helperUnmap+0x30>
    8000100e:	0009b783          	ld	a5,0(s3)
    80001012:	8b85                	andi	a5,a5,1
    80001014:	d7cd                	beqz	a5,80000fbe <helperUnmap+0x30>
    page=proc->pagesInSwap;
    80001016:	48050793          	addi	a5,a0,1152
    while(page< & proc->pagesInSwap[MAX_PSYC_PAGES]){
    8000101a:	68050693          	addi	a3,a0,1664
      if(page->va==a){
    8000101e:	6398                	ld	a4,0(a5)
    80001020:	01470763          	beq	a4,s4,8000102e <helperUnmap+0xa0>
      page++;
    80001024:	02078793          	addi	a5,a5,32
    while(page< & proc->pagesInSwap[MAX_PSYC_PAGES]){
    80001028:	fef69be3          	bne	a3,a5,8000101e <helperUnmap+0x90>
    8000102c:	bf49                	j	80000fbe <helperUnmap+0x30>
        page->idxIsHere=0;
    8000102e:	0007b423          	sd	zero,8(a5)
        page->va=0;
    80001032:	0007b023          	sd	zero,0(a5)
        proc->swapPagesCount--;
    80001036:	27853783          	ld	a5,632(a0)
    8000103a:	17fd                	addi	a5,a5,-1
    8000103c:	26f53c23          	sd	a5,632(a0)
        break;
    80001040:	bfbd                	j	80000fbe <helperUnmap+0x30>

0000000080001042 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001042:	1141                	addi	sp,sp,-16
    80001044:	e422                	sd	s0,8(sp)
    80001046:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001048:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    8000104c:	00008797          	auipc	a5,0x8
    80001050:	9647b783          	ld	a5,-1692(a5) # 800089b0 <kernel_pagetable>
    80001054:	83b1                	srli	a5,a5,0xc
    80001056:	577d                	li	a4,-1
    80001058:	177e                	slli	a4,a4,0x3f
    8000105a:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000105c:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001060:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001064:	6422                	ld	s0,8(sp)
    80001066:	0141                	addi	sp,sp,16
    80001068:	8082                	ret

000000008000106a <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000106a:	7139                	addi	sp,sp,-64
    8000106c:	fc06                	sd	ra,56(sp)
    8000106e:	f822                	sd	s0,48(sp)
    80001070:	f426                	sd	s1,40(sp)
    80001072:	f04a                	sd	s2,32(sp)
    80001074:	ec4e                	sd	s3,24(sp)
    80001076:	e852                	sd	s4,16(sp)
    80001078:	e456                	sd	s5,8(sp)
    8000107a:	e05a                	sd	s6,0(sp)
    8000107c:	0080                	addi	s0,sp,64
    8000107e:	84aa                	mv	s1,a0
    80001080:	89ae                	mv	s3,a1
    80001082:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001084:	57fd                	li	a5,-1
    80001086:	83e9                	srli	a5,a5,0x1a
    80001088:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000108a:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000108c:	04b7f263          	bgeu	a5,a1,800010d0 <walk+0x66>
    panic("walk");
    80001090:	00007517          	auipc	a0,0x7
    80001094:	04050513          	addi	a0,a0,64 # 800080d0 <digits+0x90>
    80001098:	fffff097          	auipc	ra,0xfffff
    8000109c:	4a6080e7          	jalr	1190(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800010a0:	060a8663          	beqz	s5,8000110c <walk+0xa2>
    800010a4:	00000097          	auipc	ra,0x0
    800010a8:	a42080e7          	jalr	-1470(ra) # 80000ae6 <kalloc>
    800010ac:	84aa                	mv	s1,a0
    800010ae:	c529                	beqz	a0,800010f8 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800010b0:	6605                	lui	a2,0x1
    800010b2:	4581                	li	a1,0
    800010b4:	00000097          	auipc	ra,0x0
    800010b8:	c1e080e7          	jalr	-994(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800010bc:	00c4d793          	srli	a5,s1,0xc
    800010c0:	07aa                	slli	a5,a5,0xa
    800010c2:	0017e793          	ori	a5,a5,1
    800010c6:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010ca:	3a5d                	addiw	s4,s4,-9
    800010cc:	036a0063          	beq	s4,s6,800010ec <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010d0:	0149d933          	srl	s2,s3,s4
    800010d4:	1ff97913          	andi	s2,s2,511
    800010d8:	090e                	slli	s2,s2,0x3
    800010da:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010dc:	00093483          	ld	s1,0(s2)
    800010e0:	0014f793          	andi	a5,s1,1
    800010e4:	dfd5                	beqz	a5,800010a0 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010e6:	80a9                	srli	s1,s1,0xa
    800010e8:	04b2                	slli	s1,s1,0xc
    800010ea:	b7c5                	j	800010ca <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010ec:	00c9d513          	srli	a0,s3,0xc
    800010f0:	1ff57513          	andi	a0,a0,511
    800010f4:	050e                	slli	a0,a0,0x3
    800010f6:	9526                	add	a0,a0,s1
}
    800010f8:	70e2                	ld	ra,56(sp)
    800010fa:	7442                	ld	s0,48(sp)
    800010fc:	74a2                	ld	s1,40(sp)
    800010fe:	7902                	ld	s2,32(sp)
    80001100:	69e2                	ld	s3,24(sp)
    80001102:	6a42                	ld	s4,16(sp)
    80001104:	6aa2                	ld	s5,8(sp)
    80001106:	6b02                	ld	s6,0(sp)
    80001108:	6121                	addi	sp,sp,64
    8000110a:	8082                	ret
        return 0;
    8000110c:	4501                	li	a0,0
    8000110e:	b7ed                	j	800010f8 <walk+0x8e>

0000000080001110 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001110:	57fd                	li	a5,-1
    80001112:	83e9                	srli	a5,a5,0x1a
    80001114:	00b7f463          	bgeu	a5,a1,8000111c <walkaddr+0xc>
    return 0;
    80001118:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000111a:	8082                	ret
{
    8000111c:	1141                	addi	sp,sp,-16
    8000111e:	e406                	sd	ra,8(sp)
    80001120:	e022                	sd	s0,0(sp)
    80001122:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001124:	4601                	li	a2,0
    80001126:	00000097          	auipc	ra,0x0
    8000112a:	f44080e7          	jalr	-188(ra) # 8000106a <walk>
  if(pte == 0)
    8000112e:	c105                	beqz	a0,8000114e <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001130:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001132:	0117f693          	andi	a3,a5,17
    80001136:	4745                	li	a4,17
    return 0;
    80001138:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000113a:	00e68663          	beq	a3,a4,80001146 <walkaddr+0x36>
}
    8000113e:	60a2                	ld	ra,8(sp)
    80001140:	6402                	ld	s0,0(sp)
    80001142:	0141                	addi	sp,sp,16
    80001144:	8082                	ret
  pa = PTE2PA(*pte);
    80001146:	00a7d513          	srli	a0,a5,0xa
    8000114a:	0532                	slli	a0,a0,0xc
  return pa;
    8000114c:	bfcd                	j	8000113e <walkaddr+0x2e>
    return 0;
    8000114e:	4501                	li	a0,0
    80001150:	b7fd                	j	8000113e <walkaddr+0x2e>

0000000080001152 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001152:	715d                	addi	sp,sp,-80
    80001154:	e486                	sd	ra,72(sp)
    80001156:	e0a2                	sd	s0,64(sp)
    80001158:	fc26                	sd	s1,56(sp)
    8000115a:	f84a                	sd	s2,48(sp)
    8000115c:	f44e                	sd	s3,40(sp)
    8000115e:	f052                	sd	s4,32(sp)
    80001160:	ec56                	sd	s5,24(sp)
    80001162:	e85a                	sd	s6,16(sp)
    80001164:	e45e                	sd	s7,8(sp)
    80001166:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    80001168:	c639                	beqz	a2,800011b6 <mappages+0x64>
    8000116a:	8aaa                	mv	s5,a0
    8000116c:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    8000116e:	77fd                	lui	a5,0xfffff
    80001170:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    80001174:	15fd                	addi	a1,a1,-1
    80001176:	00c589b3          	add	s3,a1,a2
    8000117a:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    8000117e:	8952                	mv	s2,s4
    80001180:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001184:	6b85                	lui	s7,0x1
    80001186:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000118a:	4605                	li	a2,1
    8000118c:	85ca                	mv	a1,s2
    8000118e:	8556                	mv	a0,s5
    80001190:	00000097          	auipc	ra,0x0
    80001194:	eda080e7          	jalr	-294(ra) # 8000106a <walk>
    80001198:	cd1d                	beqz	a0,800011d6 <mappages+0x84>
    if(*pte & PTE_V)
    8000119a:	611c                	ld	a5,0(a0)
    8000119c:	8b85                	andi	a5,a5,1
    8000119e:	e785                	bnez	a5,800011c6 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011a0:	80b1                	srli	s1,s1,0xc
    800011a2:	04aa                	slli	s1,s1,0xa
    800011a4:	0164e4b3          	or	s1,s1,s6
    800011a8:	0014e493          	ori	s1,s1,1
    800011ac:	e104                	sd	s1,0(a0)
    if(a == last)
    800011ae:	05390063          	beq	s2,s3,800011ee <mappages+0x9c>
    a += PGSIZE;
    800011b2:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011b4:	bfc9                	j	80001186 <mappages+0x34>
    panic("mappages: size");
    800011b6:	00007517          	auipc	a0,0x7
    800011ba:	f2250513          	addi	a0,a0,-222 # 800080d8 <digits+0x98>
    800011be:	fffff097          	auipc	ra,0xfffff
    800011c2:	380080e7          	jalr	896(ra) # 8000053e <panic>
      panic("mappages: remap");
    800011c6:	00007517          	auipc	a0,0x7
    800011ca:	f2250513          	addi	a0,a0,-222 # 800080e8 <digits+0xa8>
    800011ce:	fffff097          	auipc	ra,0xfffff
    800011d2:	370080e7          	jalr	880(ra) # 8000053e <panic>
      return -1;
    800011d6:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011d8:	60a6                	ld	ra,72(sp)
    800011da:	6406                	ld	s0,64(sp)
    800011dc:	74e2                	ld	s1,56(sp)
    800011de:	7942                	ld	s2,48(sp)
    800011e0:	79a2                	ld	s3,40(sp)
    800011e2:	7a02                	ld	s4,32(sp)
    800011e4:	6ae2                	ld	s5,24(sp)
    800011e6:	6b42                	ld	s6,16(sp)
    800011e8:	6ba2                	ld	s7,8(sp)
    800011ea:	6161                	addi	sp,sp,80
    800011ec:	8082                	ret
  return 0;
    800011ee:	4501                	li	a0,0
    800011f0:	b7e5                	j	800011d8 <mappages+0x86>

00000000800011f2 <kvmmap>:
{
    800011f2:	1141                	addi	sp,sp,-16
    800011f4:	e406                	sd	ra,8(sp)
    800011f6:	e022                	sd	s0,0(sp)
    800011f8:	0800                	addi	s0,sp,16
    800011fa:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800011fc:	86b2                	mv	a3,a2
    800011fe:	863e                	mv	a2,a5
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f52080e7          	jalr	-174(ra) # 80001152 <mappages>
    80001208:	e509                	bnez	a0,80001212 <kvmmap+0x20>
}
    8000120a:	60a2                	ld	ra,8(sp)
    8000120c:	6402                	ld	s0,0(sp)
    8000120e:	0141                	addi	sp,sp,16
    80001210:	8082                	ret
    panic("kvmmap");
    80001212:	00007517          	auipc	a0,0x7
    80001216:	ee650513          	addi	a0,a0,-282 # 800080f8 <digits+0xb8>
    8000121a:	fffff097          	auipc	ra,0xfffff
    8000121e:	324080e7          	jalr	804(ra) # 8000053e <panic>

0000000080001222 <kvmmake>:
{
    80001222:	1101                	addi	sp,sp,-32
    80001224:	ec06                	sd	ra,24(sp)
    80001226:	e822                	sd	s0,16(sp)
    80001228:	e426                	sd	s1,8(sp)
    8000122a:	e04a                	sd	s2,0(sp)
    8000122c:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	8b8080e7          	jalr	-1864(ra) # 80000ae6 <kalloc>
    80001236:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001238:	6605                	lui	a2,0x1
    8000123a:	4581                	li	a1,0
    8000123c:	00000097          	auipc	ra,0x0
    80001240:	a96080e7          	jalr	-1386(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001244:	4719                	li	a4,6
    80001246:	6685                	lui	a3,0x1
    80001248:	10000637          	lui	a2,0x10000
    8000124c:	100005b7          	lui	a1,0x10000
    80001250:	8526                	mv	a0,s1
    80001252:	00000097          	auipc	ra,0x0
    80001256:	fa0080e7          	jalr	-96(ra) # 800011f2 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000125a:	4719                	li	a4,6
    8000125c:	6685                	lui	a3,0x1
    8000125e:	10001637          	lui	a2,0x10001
    80001262:	100015b7          	lui	a1,0x10001
    80001266:	8526                	mv	a0,s1
    80001268:	00000097          	auipc	ra,0x0
    8000126c:	f8a080e7          	jalr	-118(ra) # 800011f2 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001270:	4719                	li	a4,6
    80001272:	004006b7          	lui	a3,0x400
    80001276:	0c000637          	lui	a2,0xc000
    8000127a:	0c0005b7          	lui	a1,0xc000
    8000127e:	8526                	mv	a0,s1
    80001280:	00000097          	auipc	ra,0x0
    80001284:	f72080e7          	jalr	-142(ra) # 800011f2 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001288:	00007917          	auipc	s2,0x7
    8000128c:	d7890913          	addi	s2,s2,-648 # 80008000 <etext>
    80001290:	4729                	li	a4,10
    80001292:	80007697          	auipc	a3,0x80007
    80001296:	d6e68693          	addi	a3,a3,-658 # 8000 <_entry-0x7fff8000>
    8000129a:	4605                	li	a2,1
    8000129c:	067e                	slli	a2,a2,0x1f
    8000129e:	85b2                	mv	a1,a2
    800012a0:	8526                	mv	a0,s1
    800012a2:	00000097          	auipc	ra,0x0
    800012a6:	f50080e7          	jalr	-176(ra) # 800011f2 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012aa:	4719                	li	a4,6
    800012ac:	46c5                	li	a3,17
    800012ae:	06ee                	slli	a3,a3,0x1b
    800012b0:	412686b3          	sub	a3,a3,s2
    800012b4:	864a                	mv	a2,s2
    800012b6:	85ca                	mv	a1,s2
    800012b8:	8526                	mv	a0,s1
    800012ba:	00000097          	auipc	ra,0x0
    800012be:	f38080e7          	jalr	-200(ra) # 800011f2 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012c2:	4729                	li	a4,10
    800012c4:	6685                	lui	a3,0x1
    800012c6:	00006617          	auipc	a2,0x6
    800012ca:	d3a60613          	addi	a2,a2,-710 # 80007000 <_trampoline>
    800012ce:	040005b7          	lui	a1,0x4000
    800012d2:	15fd                	addi	a1,a1,-1
    800012d4:	05b2                	slli	a1,a1,0xc
    800012d6:	8526                	mv	a0,s1
    800012d8:	00000097          	auipc	ra,0x0
    800012dc:	f1a080e7          	jalr	-230(ra) # 800011f2 <kvmmap>
  proc_mapstacks(kpgtbl);
    800012e0:	8526                	mv	a0,s1
    800012e2:	00000097          	auipc	ra,0x0
    800012e6:	6a6080e7          	jalr	1702(ra) # 80001988 <proc_mapstacks>
}
    800012ea:	8526                	mv	a0,s1
    800012ec:	60e2                	ld	ra,24(sp)
    800012ee:	6442                	ld	s0,16(sp)
    800012f0:	64a2                	ld	s1,8(sp)
    800012f2:	6902                	ld	s2,0(sp)
    800012f4:	6105                	addi	sp,sp,32
    800012f6:	8082                	ret

00000000800012f8 <kvminit>:
{
    800012f8:	1141                	addi	sp,sp,-16
    800012fa:	e406                	sd	ra,8(sp)
    800012fc:	e022                	sd	s0,0(sp)
    800012fe:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001300:	00000097          	auipc	ra,0x0
    80001304:	f22080e7          	jalr	-222(ra) # 80001222 <kvmmake>
    80001308:	00007797          	auipc	a5,0x7
    8000130c:	6aa7b423          	sd	a0,1704(a5) # 800089b0 <kernel_pagetable>
}
    80001310:	60a2                	ld	ra,8(sp)
    80001312:	6402                	ld	s0,0(sp)
    80001314:	0141                	addi	sp,sp,16
    80001316:	8082                	ret

0000000080001318 <uvmunmap>:
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
//The uvmunmap() function is called by the user-space library when a process requests that a virtual memory region be unmapped. The function is also called by the kernel when a process terminates.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001318:	715d                	addi	sp,sp,-80
    8000131a:	e486                	sd	ra,72(sp)
    8000131c:	e0a2                	sd	s0,64(sp)
    8000131e:	fc26                	sd	s1,56(sp)
    80001320:	f84a                	sd	s2,48(sp)
    80001322:	f44e                	sd	s3,40(sp)
    80001324:	f052                	sd	s4,32(sp)
    80001326:	ec56                	sd	s5,24(sp)
    80001328:	e85a                	sd	s6,16(sp)
    8000132a:	e45e                	sd	s7,8(sp)
    8000132c:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000132e:	03459793          	slli	a5,a1,0x34
    80001332:	e795                	bnez	a5,8000135e <uvmunmap+0x46>
    80001334:	89aa                	mv	s3,a0
    80001336:	892e                	mv	s2,a1
    80001338:	8a36                	mv	s4,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000133a:	0632                	slli	a2,a2,0xc
    8000133c:	00b60ab3          	add	s5,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001340:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001342:	6b05                	lui	s6,0x1
    80001344:	0755ea63          	bltu	a1,s5,800013b8 <uvmunmap+0xa0>
      kfree((void*)pa);
    }
    helperUnmap( a , pte, do_free, pagetable);
    *pte = 0;
  }
}
    80001348:	60a6                	ld	ra,72(sp)
    8000134a:	6406                	ld	s0,64(sp)
    8000134c:	74e2                	ld	s1,56(sp)
    8000134e:	7942                	ld	s2,48(sp)
    80001350:	79a2                	ld	s3,40(sp)
    80001352:	7a02                	ld	s4,32(sp)
    80001354:	6ae2                	ld	s5,24(sp)
    80001356:	6b42                	ld	s6,16(sp)
    80001358:	6ba2                	ld	s7,8(sp)
    8000135a:	6161                	addi	sp,sp,80
    8000135c:	8082                	ret
    panic("uvmunmap: not aligned");
    8000135e:	00007517          	auipc	a0,0x7
    80001362:	da250513          	addi	a0,a0,-606 # 80008100 <digits+0xc0>
    80001366:	fffff097          	auipc	ra,0xfffff
    8000136a:	1d8080e7          	jalr	472(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    8000136e:	00007517          	auipc	a0,0x7
    80001372:	daa50513          	addi	a0,a0,-598 # 80008118 <digits+0xd8>
    80001376:	fffff097          	auipc	ra,0xfffff
    8000137a:	1c8080e7          	jalr	456(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    8000137e:	00007517          	auipc	a0,0x7
    80001382:	daa50513          	addi	a0,a0,-598 # 80008128 <digits+0xe8>
    80001386:	fffff097          	auipc	ra,0xfffff
    8000138a:	1b8080e7          	jalr	440(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    8000138e:	00007517          	auipc	a0,0x7
    80001392:	db250513          	addi	a0,a0,-590 # 80008140 <digits+0x100>
    80001396:	fffff097          	auipc	ra,0xfffff
    8000139a:	1a8080e7          	jalr	424(ra) # 8000053e <panic>
    helperUnmap( a , pte, do_free, pagetable);
    8000139e:	86ce                	mv	a3,s3
    800013a0:	8652                	mv	a2,s4
    800013a2:	85a6                	mv	a1,s1
    800013a4:	854a                	mv	a0,s2
    800013a6:	00000097          	auipc	ra,0x0
    800013aa:	be8080e7          	jalr	-1048(ra) # 80000f8e <helperUnmap>
    *pte = 0;
    800013ae:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013b2:	995a                	add	s2,s2,s6
    800013b4:	f9597ae3          	bgeu	s2,s5,80001348 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013b8:	4601                	li	a2,0
    800013ba:	85ca                	mv	a1,s2
    800013bc:	854e                	mv	a0,s3
    800013be:	00000097          	auipc	ra,0x0
    800013c2:	cac080e7          	jalr	-852(ra) # 8000106a <walk>
    800013c6:	84aa                	mv	s1,a0
    800013c8:	d15d                	beqz	a0,8000136e <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013ca:	6108                	ld	a0,0(a0)
    800013cc:	00157793          	andi	a5,a0,1
    800013d0:	d7dd                	beqz	a5,8000137e <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013d2:	3ff57793          	andi	a5,a0,1023
    800013d6:	fb778ce3          	beq	a5,s7,8000138e <uvmunmap+0x76>
    if(do_free){
    800013da:	fc0a02e3          	beqz	s4,8000139e <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800013de:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013e0:	0532                	slli	a0,a0,0xc
    800013e2:	fffff097          	auipc	ra,0xfffff
    800013e6:	608080e7          	jalr	1544(ra) # 800009ea <kfree>
    800013ea:	bf55                	j	8000139e <uvmunmap+0x86>

00000000800013ec <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013ec:	1101                	addi	sp,sp,-32
    800013ee:	ec06                	sd	ra,24(sp)
    800013f0:	e822                	sd	s0,16(sp)
    800013f2:	e426                	sd	s1,8(sp)
    800013f4:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013f6:	fffff097          	auipc	ra,0xfffff
    800013fa:	6f0080e7          	jalr	1776(ra) # 80000ae6 <kalloc>
    800013fe:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001400:	c519                	beqz	a0,8000140e <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001402:	6605                	lui	a2,0x1
    80001404:	4581                	li	a1,0
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	8cc080e7          	jalr	-1844(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000140e:	8526                	mv	a0,s1
    80001410:	60e2                	ld	ra,24(sp)
    80001412:	6442                	ld	s0,16(sp)
    80001414:	64a2                	ld	s1,8(sp)
    80001416:	6105                	addi	sp,sp,32
    80001418:	8082                	ret

000000008000141a <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    8000141a:	7179                	addi	sp,sp,-48
    8000141c:	f406                	sd	ra,40(sp)
    8000141e:	f022                	sd	s0,32(sp)
    80001420:	ec26                	sd	s1,24(sp)
    80001422:	e84a                	sd	s2,16(sp)
    80001424:	e44e                	sd	s3,8(sp)
    80001426:	e052                	sd	s4,0(sp)
    80001428:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000142a:	6785                	lui	a5,0x1
    8000142c:	04f67863          	bgeu	a2,a5,8000147c <uvmfirst+0x62>
    80001430:	8a2a                	mv	s4,a0
    80001432:	89ae                	mv	s3,a1
    80001434:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001436:	fffff097          	auipc	ra,0xfffff
    8000143a:	6b0080e7          	jalr	1712(ra) # 80000ae6 <kalloc>
    8000143e:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001440:	6605                	lui	a2,0x1
    80001442:	4581                	li	a1,0
    80001444:	00000097          	auipc	ra,0x0
    80001448:	88e080e7          	jalr	-1906(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000144c:	4779                	li	a4,30
    8000144e:	86ca                	mv	a3,s2
    80001450:	6605                	lui	a2,0x1
    80001452:	4581                	li	a1,0
    80001454:	8552                	mv	a0,s4
    80001456:	00000097          	auipc	ra,0x0
    8000145a:	cfc080e7          	jalr	-772(ra) # 80001152 <mappages>
  memmove(mem, src, sz);
    8000145e:	8626                	mv	a2,s1
    80001460:	85ce                	mv	a1,s3
    80001462:	854a                	mv	a0,s2
    80001464:	00000097          	auipc	ra,0x0
    80001468:	8ca080e7          	jalr	-1846(ra) # 80000d2e <memmove>
}
    8000146c:	70a2                	ld	ra,40(sp)
    8000146e:	7402                	ld	s0,32(sp)
    80001470:	64e2                	ld	s1,24(sp)
    80001472:	6942                	ld	s2,16(sp)
    80001474:	69a2                	ld	s3,8(sp)
    80001476:	6a02                	ld	s4,0(sp)
    80001478:	6145                	addi	sp,sp,48
    8000147a:	8082                	ret
    panic("uvmfirst: more than a page");
    8000147c:	00007517          	auipc	a0,0x7
    80001480:	cdc50513          	addi	a0,a0,-804 # 80008158 <digits+0x118>
    80001484:	fffff097          	auipc	ra,0xfffff
    80001488:	0ba080e7          	jalr	186(ra) # 8000053e <panic>

000000008000148c <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000148c:	1101                	addi	sp,sp,-32
    8000148e:	ec06                	sd	ra,24(sp)
    80001490:	e822                	sd	s0,16(sp)
    80001492:	e426                	sd	s1,8(sp)
    80001494:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001496:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001498:	00b67d63          	bgeu	a2,a1,800014b2 <uvmdealloc+0x26>
    8000149c:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000149e:	6785                	lui	a5,0x1
    800014a0:	17fd                	addi	a5,a5,-1
    800014a2:	00f60733          	add	a4,a2,a5
    800014a6:	767d                	lui	a2,0xfffff
    800014a8:	8f71                	and	a4,a4,a2
    800014aa:	97ae                	add	a5,a5,a1
    800014ac:	8ff1                	and	a5,a5,a2
    800014ae:	00f76863          	bltu	a4,a5,800014be <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014b2:	8526                	mv	a0,s1
    800014b4:	60e2                	ld	ra,24(sp)
    800014b6:	6442                	ld	s0,16(sp)
    800014b8:	64a2                	ld	s1,8(sp)
    800014ba:	6105                	addi	sp,sp,32
    800014bc:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014be:	8f99                	sub	a5,a5,a4
    800014c0:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014c2:	4685                	li	a3,1
    800014c4:	0007861b          	sext.w	a2,a5
    800014c8:	85ba                	mv	a1,a4
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	e4e080e7          	jalr	-434(ra) # 80001318 <uvmunmap>
    800014d2:	b7c5                	j	800014b2 <uvmdealloc+0x26>

00000000800014d4 <uvmalloc>:
  if(newsz < oldsz)
    800014d4:	12b66c63          	bltu	a2,a1,8000160c <uvmalloc+0x138>
{
    800014d8:	7159                	addi	sp,sp,-112
    800014da:	f486                	sd	ra,104(sp)
    800014dc:	f0a2                	sd	s0,96(sp)
    800014de:	eca6                	sd	s1,88(sp)
    800014e0:	e8ca                	sd	s2,80(sp)
    800014e2:	e4ce                	sd	s3,72(sp)
    800014e4:	e0d2                	sd	s4,64(sp)
    800014e6:	fc56                	sd	s5,56(sp)
    800014e8:	f85a                	sd	s6,48(sp)
    800014ea:	f45e                	sd	s7,40(sp)
    800014ec:	f062                	sd	s8,32(sp)
    800014ee:	ec66                	sd	s9,24(sp)
    800014f0:	e86a                	sd	s10,16(sp)
    800014f2:	e46e                	sd	s11,8(sp)
    800014f4:	1880                	addi	s0,sp,112
    800014f6:	8a2a                	mv	s4,a0
    800014f8:	8b32                	mv	s6,a2
  oldsz = PGROUNDUP(oldsz);
    800014fa:	6a85                	lui	s5,0x1
    800014fc:	1afd                	addi	s5,s5,-1
    800014fe:	95d6                	add	a1,a1,s5
    80001500:	7afd                	lui	s5,0xfffff
    80001502:	0155fab3          	and	s5,a1,s5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001506:	10caf563          	bgeu	s5,a2,80001610 <uvmalloc+0x13c>
    8000150a:	89d6                	mv	s3,s5
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000150c:	0126eb93          	ori	s7,a3,18
    if(p->pid>2){
    80001510:	4c09                	li	s8,2
      if(p->physicalPagesCount==MAX_PSYC_PAGES){
    80001512:	4dc1                	li	s11,16
    page->idxIsHere=1;
    80001514:	4d05                	li	s10,1
    *entry = ~PTE_V | *entry;
    80001516:	5cf9                	li	s9,-2
    80001518:	a849                	j	800015aa <uvmalloc+0xd6>
      uvmdealloc(pagetable, a, oldsz);
    8000151a:	8656                	mv	a2,s5
    8000151c:	85ce                	mv	a1,s3
    8000151e:	8552                	mv	a0,s4
    80001520:	00000097          	auipc	ra,0x0
    80001524:	f6c080e7          	jalr	-148(ra) # 8000148c <uvmdealloc>
      return 0;
    80001528:	4501                	li	a0,0
}
    8000152a:	70a6                	ld	ra,104(sp)
    8000152c:	7406                	ld	s0,96(sp)
    8000152e:	64e6                	ld	s1,88(sp)
    80001530:	6946                	ld	s2,80(sp)
    80001532:	69a6                	ld	s3,72(sp)
    80001534:	6a06                	ld	s4,64(sp)
    80001536:	7ae2                	ld	s5,56(sp)
    80001538:	7b42                	ld	s6,48(sp)
    8000153a:	7ba2                	ld	s7,40(sp)
    8000153c:	7c02                	ld	s8,32(sp)
    8000153e:	6ce2                	ld	s9,24(sp)
    80001540:	6d42                	ld	s10,16(sp)
    80001542:	6da2                	ld	s11,8(sp)
    80001544:	6165                	addi	sp,sp,112
    80001546:	8082                	ret
      kfree(mem);
    80001548:	854a                	mv	a0,s2
    8000154a:	fffff097          	auipc	ra,0xfffff
    8000154e:	4a0080e7          	jalr	1184(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001552:	8656                	mv	a2,s5
    80001554:	85ce                	mv	a1,s3
    80001556:	8552                	mv	a0,s4
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	f34080e7          	jalr	-204(ra) # 8000148c <uvmdealloc>
      return 0;
    80001560:	4501                	li	a0,0
    80001562:	b7e1                	j	8000152a <uvmalloc+0x56>
        swapOutFromPysc(pagetable,p);
    80001564:	85aa                	mv	a1,a0
    80001566:	8552                	mv	a0,s4
    80001568:	00001097          	auipc	ra,0x1
    8000156c:	25e080e7          	jalr	606(ra) # 800027c6 <swapOutFromPysc>
    80001570:	a041                	j	800015f0 <uvmalloc+0x11c>
        freeIdx=(int)(page-(p->pagesInPysical));
    80001572:	40c784b3          	sub	s1,a5,a2
    80001576:	8495                	srai	s1,s1,0x5
    80001578:	2481                	sext.w	s1,s1
    page->idxIsHere=1;
    8000157a:	0496                	slli	s1,s1,0x5
    8000157c:	94ca                	add	s1,s1,s2
    8000157e:	29a4b423          	sd	s10,648(s1)
    page->va=a;
    80001582:	2934b023          	sd	s3,640(s1)
    p->physicalPagesCount++;
    80001586:	27093783          	ld	a5,624(s2)
    8000158a:	0785                	addi	a5,a5,1
    8000158c:	26f93823          	sd	a5,624(s2)
    pte_t* entry = walk(pagetable, page->va, 0);
    80001590:	4601                	li	a2,0
    80001592:	85ce                	mv	a1,s3
    80001594:	8552                	mv	a0,s4
    80001596:	00000097          	auipc	ra,0x0
    8000159a:	ad4080e7          	jalr	-1324(ra) # 8000106a <walk>
    *entry = ~PTE_V | *entry;
    8000159e:	01953023          	sd	s9,0(a0)
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015a2:	6785                	lui	a5,0x1
    800015a4:	99be                	add	s3,s3,a5
    800015a6:	0769f163          	bgeu	s3,s6,80001608 <uvmalloc+0x134>
    mem = kalloc();
    800015aa:	fffff097          	auipc	ra,0xfffff
    800015ae:	53c080e7          	jalr	1340(ra) # 80000ae6 <kalloc>
    800015b2:	892a                	mv	s2,a0
    if(mem == 0){
    800015b4:	d13d                	beqz	a0,8000151a <uvmalloc+0x46>
    memset(mem, 0, PGSIZE);
    800015b6:	6605                	lui	a2,0x1
    800015b8:	4581                	li	a1,0
    800015ba:	fffff097          	auipc	ra,0xfffff
    800015be:	718080e7          	jalr	1816(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800015c2:	875e                	mv	a4,s7
    800015c4:	86ca                	mv	a3,s2
    800015c6:	6605                	lui	a2,0x1
    800015c8:	85ce                	mv	a1,s3
    800015ca:	8552                	mv	a0,s4
    800015cc:	00000097          	auipc	ra,0x0
    800015d0:	b86080e7          	jalr	-1146(ra) # 80001152 <mappages>
    800015d4:	84aa                	mv	s1,a0
    800015d6:	f92d                	bnez	a0,80001548 <uvmalloc+0x74>
    struct proc *p=myproc();
    800015d8:	00000097          	auipc	ra,0x0
    800015dc:	526080e7          	jalr	1318(ra) # 80001afe <myproc>
    800015e0:	892a                	mv	s2,a0
    if(p->pid>2){
    800015e2:	591c                	lw	a5,48(a0)
    800015e4:	fafc5fe3          	bge	s8,a5,800015a2 <uvmalloc+0xce>
      if(p->physicalPagesCount==MAX_PSYC_PAGES){
    800015e8:	27053783          	ld	a5,624(a0)
    800015ec:	f7b78ce3          	beq	a5,s11,80001564 <uvmalloc+0x90>
    for(page = p->pagesInPysical; page < &p->pagesInPysical[MAX_PSYC_PAGES]; page++ ){
    800015f0:	28090613          	addi	a2,s2,640
    800015f4:	48090693          	addi	a3,s2,1152
    800015f8:	87b2                	mv	a5,a2
      if(page->idxIsHere==0){
    800015fa:	6798                	ld	a4,8(a5)
    800015fc:	db3d                	beqz	a4,80001572 <uvmalloc+0x9e>
    for(page = p->pagesInPysical; page < &p->pagesInPysical[MAX_PSYC_PAGES]; page++ ){
    800015fe:	02078793          	addi	a5,a5,32 # 1020 <_entry-0x7fffefe0>
    80001602:	fef69ce3          	bne	a3,a5,800015fa <uvmalloc+0x126>
    80001606:	bf95                	j	8000157a <uvmalloc+0xa6>
  return newsz;
    80001608:	855a                	mv	a0,s6
    8000160a:	b705                	j	8000152a <uvmalloc+0x56>
    return oldsz;
    8000160c:	852e                	mv	a0,a1
}
    8000160e:	8082                	ret
  return newsz;
    80001610:	8532                	mv	a0,a2
    80001612:	bf21                	j	8000152a <uvmalloc+0x56>

0000000080001614 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001614:	7179                	addi	sp,sp,-48
    80001616:	f406                	sd	ra,40(sp)
    80001618:	f022                	sd	s0,32(sp)
    8000161a:	ec26                	sd	s1,24(sp)
    8000161c:	e84a                	sd	s2,16(sp)
    8000161e:	e44e                	sd	s3,8(sp)
    80001620:	e052                	sd	s4,0(sp)
    80001622:	1800                	addi	s0,sp,48
    80001624:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001626:	84aa                	mv	s1,a0
    80001628:	6905                	lui	s2,0x1
    8000162a:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000162c:	4985                	li	s3,1
    8000162e:	a821                	j	80001646 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001630:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001632:	0532                	slli	a0,a0,0xc
    80001634:	00000097          	auipc	ra,0x0
    80001638:	fe0080e7          	jalr	-32(ra) # 80001614 <freewalk>
      pagetable[i] = 0;
    8000163c:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001640:	04a1                	addi	s1,s1,8
    80001642:	03248163          	beq	s1,s2,80001664 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001646:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001648:	00f57793          	andi	a5,a0,15
    8000164c:	ff3782e3          	beq	a5,s3,80001630 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001650:	8905                	andi	a0,a0,1
    80001652:	d57d                	beqz	a0,80001640 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001654:	00007517          	auipc	a0,0x7
    80001658:	b2450513          	addi	a0,a0,-1244 # 80008178 <digits+0x138>
    8000165c:	fffff097          	auipc	ra,0xfffff
    80001660:	ee2080e7          	jalr	-286(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001664:	8552                	mv	a0,s4
    80001666:	fffff097          	auipc	ra,0xfffff
    8000166a:	384080e7          	jalr	900(ra) # 800009ea <kfree>
}
    8000166e:	70a2                	ld	ra,40(sp)
    80001670:	7402                	ld	s0,32(sp)
    80001672:	64e2                	ld	s1,24(sp)
    80001674:	6942                	ld	s2,16(sp)
    80001676:	69a2                	ld	s3,8(sp)
    80001678:	6a02                	ld	s4,0(sp)
    8000167a:	6145                	addi	sp,sp,48
    8000167c:	8082                	ret

000000008000167e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000167e:	1101                	addi	sp,sp,-32
    80001680:	ec06                	sd	ra,24(sp)
    80001682:	e822                	sd	s0,16(sp)
    80001684:	e426                	sd	s1,8(sp)
    80001686:	1000                	addi	s0,sp,32
    80001688:	84aa                	mv	s1,a0
  if(sz > 0)
    8000168a:	e999                	bnez	a1,800016a0 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000168c:	8526                	mv	a0,s1
    8000168e:	00000097          	auipc	ra,0x0
    80001692:	f86080e7          	jalr	-122(ra) # 80001614 <freewalk>
}
    80001696:	60e2                	ld	ra,24(sp)
    80001698:	6442                	ld	s0,16(sp)
    8000169a:	64a2                	ld	s1,8(sp)
    8000169c:	6105                	addi	sp,sp,32
    8000169e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800016a0:	6605                	lui	a2,0x1
    800016a2:	167d                	addi	a2,a2,-1
    800016a4:	962e                	add	a2,a2,a1
    800016a6:	4685                	li	a3,1
    800016a8:	8231                	srli	a2,a2,0xc
    800016aa:	4581                	li	a1,0
    800016ac:	00000097          	auipc	ra,0x0
    800016b0:	c6c080e7          	jalr	-916(ra) # 80001318 <uvmunmap>
    800016b4:	bfe1                	j	8000168c <uvmfree+0xe>

00000000800016b6 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800016b6:	c679                	beqz	a2,80001784 <uvmcopy+0xce>
{
    800016b8:	715d                	addi	sp,sp,-80
    800016ba:	e486                	sd	ra,72(sp)
    800016bc:	e0a2                	sd	s0,64(sp)
    800016be:	fc26                	sd	s1,56(sp)
    800016c0:	f84a                	sd	s2,48(sp)
    800016c2:	f44e                	sd	s3,40(sp)
    800016c4:	f052                	sd	s4,32(sp)
    800016c6:	ec56                	sd	s5,24(sp)
    800016c8:	e85a                	sd	s6,16(sp)
    800016ca:	e45e                	sd	s7,8(sp)
    800016cc:	0880                	addi	s0,sp,80
    800016ce:	8b2a                	mv	s6,a0
    800016d0:	8aae                	mv	s5,a1
    800016d2:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800016d4:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800016d6:	4601                	li	a2,0
    800016d8:	85ce                	mv	a1,s3
    800016da:	855a                	mv	a0,s6
    800016dc:	00000097          	auipc	ra,0x0
    800016e0:	98e080e7          	jalr	-1650(ra) # 8000106a <walk>
    800016e4:	c531                	beqz	a0,80001730 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800016e6:	6118                	ld	a4,0(a0)
    800016e8:	00177793          	andi	a5,a4,1
    800016ec:	cbb1                	beqz	a5,80001740 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800016ee:	00a75593          	srli	a1,a4,0xa
    800016f2:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800016f6:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800016fa:	fffff097          	auipc	ra,0xfffff
    800016fe:	3ec080e7          	jalr	1004(ra) # 80000ae6 <kalloc>
    80001702:	892a                	mv	s2,a0
    80001704:	c939                	beqz	a0,8000175a <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001706:	6605                	lui	a2,0x1
    80001708:	85de                	mv	a1,s7
    8000170a:	fffff097          	auipc	ra,0xfffff
    8000170e:	624080e7          	jalr	1572(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001712:	8726                	mv	a4,s1
    80001714:	86ca                	mv	a3,s2
    80001716:	6605                	lui	a2,0x1
    80001718:	85ce                	mv	a1,s3
    8000171a:	8556                	mv	a0,s5
    8000171c:	00000097          	auipc	ra,0x0
    80001720:	a36080e7          	jalr	-1482(ra) # 80001152 <mappages>
    80001724:	e515                	bnez	a0,80001750 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001726:	6785                	lui	a5,0x1
    80001728:	99be                	add	s3,s3,a5
    8000172a:	fb49e6e3          	bltu	s3,s4,800016d6 <uvmcopy+0x20>
    8000172e:	a081                	j	8000176e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001730:	00007517          	auipc	a0,0x7
    80001734:	a5850513          	addi	a0,a0,-1448 # 80008188 <digits+0x148>
    80001738:	fffff097          	auipc	ra,0xfffff
    8000173c:	e06080e7          	jalr	-506(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    80001740:	00007517          	auipc	a0,0x7
    80001744:	a6850513          	addi	a0,a0,-1432 # 800081a8 <digits+0x168>
    80001748:	fffff097          	auipc	ra,0xfffff
    8000174c:	df6080e7          	jalr	-522(ra) # 8000053e <panic>
      kfree(mem);
    80001750:	854a                	mv	a0,s2
    80001752:	fffff097          	auipc	ra,0xfffff
    80001756:	298080e7          	jalr	664(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000175a:	4685                	li	a3,1
    8000175c:	00c9d613          	srli	a2,s3,0xc
    80001760:	4581                	li	a1,0
    80001762:	8556                	mv	a0,s5
    80001764:	00000097          	auipc	ra,0x0
    80001768:	bb4080e7          	jalr	-1100(ra) # 80001318 <uvmunmap>
  return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6161                	addi	sp,sp,80
    80001782:	8082                	ret
  return 0;
    80001784:	4501                	li	a0,0
}
    80001786:	8082                	ret

0000000080001788 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001788:	1141                	addi	sp,sp,-16
    8000178a:	e406                	sd	ra,8(sp)
    8000178c:	e022                	sd	s0,0(sp)
    8000178e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001790:	4601                	li	a2,0
    80001792:	00000097          	auipc	ra,0x0
    80001796:	8d8080e7          	jalr	-1832(ra) # 8000106a <walk>
  if(pte == 0)
    8000179a:	c901                	beqz	a0,800017aa <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000179c:	611c                	ld	a5,0(a0)
    8000179e:	9bbd                	andi	a5,a5,-17
    800017a0:	e11c                	sd	a5,0(a0)
}
    800017a2:	60a2                	ld	ra,8(sp)
    800017a4:	6402                	ld	s0,0(sp)
    800017a6:	0141                	addi	sp,sp,16
    800017a8:	8082                	ret
    panic("uvmclear");
    800017aa:	00007517          	auipc	a0,0x7
    800017ae:	a1e50513          	addi	a0,a0,-1506 # 800081c8 <digits+0x188>
    800017b2:	fffff097          	auipc	ra,0xfffff
    800017b6:	d8c080e7          	jalr	-628(ra) # 8000053e <panic>

00000000800017ba <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017ba:	c6bd                	beqz	a3,80001828 <copyout+0x6e>
{
    800017bc:	715d                	addi	sp,sp,-80
    800017be:	e486                	sd	ra,72(sp)
    800017c0:	e0a2                	sd	s0,64(sp)
    800017c2:	fc26                	sd	s1,56(sp)
    800017c4:	f84a                	sd	s2,48(sp)
    800017c6:	f44e                	sd	s3,40(sp)
    800017c8:	f052                	sd	s4,32(sp)
    800017ca:	ec56                	sd	s5,24(sp)
    800017cc:	e85a                	sd	s6,16(sp)
    800017ce:	e45e                	sd	s7,8(sp)
    800017d0:	e062                	sd	s8,0(sp)
    800017d2:	0880                	addi	s0,sp,80
    800017d4:	8b2a                	mv	s6,a0
    800017d6:	8c2e                	mv	s8,a1
    800017d8:	8a32                	mv	s4,a2
    800017da:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800017dc:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800017de:	6a85                	lui	s5,0x1
    800017e0:	a015                	j	80001804 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800017e2:	9562                	add	a0,a0,s8
    800017e4:	0004861b          	sext.w	a2,s1
    800017e8:	85d2                	mv	a1,s4
    800017ea:	41250533          	sub	a0,a0,s2
    800017ee:	fffff097          	auipc	ra,0xfffff
    800017f2:	540080e7          	jalr	1344(ra) # 80000d2e <memmove>

    len -= n;
    800017f6:	409989b3          	sub	s3,s3,s1
    src += n;
    800017fa:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800017fc:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001800:	02098263          	beqz	s3,80001824 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001804:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001808:	85ca                	mv	a1,s2
    8000180a:	855a                	mv	a0,s6
    8000180c:	00000097          	auipc	ra,0x0
    80001810:	904080e7          	jalr	-1788(ra) # 80001110 <walkaddr>
    if(pa0 == 0)
    80001814:	cd01                	beqz	a0,8000182c <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001816:	418904b3          	sub	s1,s2,s8
    8000181a:	94d6                	add	s1,s1,s5
    if(n > len)
    8000181c:	fc99f3e3          	bgeu	s3,s1,800017e2 <copyout+0x28>
    80001820:	84ce                	mv	s1,s3
    80001822:	b7c1                	j	800017e2 <copyout+0x28>
  }
  return 0;
    80001824:	4501                	li	a0,0
    80001826:	a021                	j	8000182e <copyout+0x74>
    80001828:	4501                	li	a0,0
}
    8000182a:	8082                	ret
      return -1;
    8000182c:	557d                	li	a0,-1
}
    8000182e:	60a6                	ld	ra,72(sp)
    80001830:	6406                	ld	s0,64(sp)
    80001832:	74e2                	ld	s1,56(sp)
    80001834:	7942                	ld	s2,48(sp)
    80001836:	79a2                	ld	s3,40(sp)
    80001838:	7a02                	ld	s4,32(sp)
    8000183a:	6ae2                	ld	s5,24(sp)
    8000183c:	6b42                	ld	s6,16(sp)
    8000183e:	6ba2                	ld	s7,8(sp)
    80001840:	6c02                	ld	s8,0(sp)
    80001842:	6161                	addi	sp,sp,80
    80001844:	8082                	ret

0000000080001846 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001846:	caa5                	beqz	a3,800018b6 <copyin+0x70>
{
    80001848:	715d                	addi	sp,sp,-80
    8000184a:	e486                	sd	ra,72(sp)
    8000184c:	e0a2                	sd	s0,64(sp)
    8000184e:	fc26                	sd	s1,56(sp)
    80001850:	f84a                	sd	s2,48(sp)
    80001852:	f44e                	sd	s3,40(sp)
    80001854:	f052                	sd	s4,32(sp)
    80001856:	ec56                	sd	s5,24(sp)
    80001858:	e85a                	sd	s6,16(sp)
    8000185a:	e45e                	sd	s7,8(sp)
    8000185c:	e062                	sd	s8,0(sp)
    8000185e:	0880                	addi	s0,sp,80
    80001860:	8b2a                	mv	s6,a0
    80001862:	8a2e                	mv	s4,a1
    80001864:	8c32                	mv	s8,a2
    80001866:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001868:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000186a:	6a85                	lui	s5,0x1
    8000186c:	a01d                	j	80001892 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000186e:	018505b3          	add	a1,a0,s8
    80001872:	0004861b          	sext.w	a2,s1
    80001876:	412585b3          	sub	a1,a1,s2
    8000187a:	8552                	mv	a0,s4
    8000187c:	fffff097          	auipc	ra,0xfffff
    80001880:	4b2080e7          	jalr	1202(ra) # 80000d2e <memmove>

    len -= n;
    80001884:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001888:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000188a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000188e:	02098263          	beqz	s3,800018b2 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001892:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001896:	85ca                	mv	a1,s2
    80001898:	855a                	mv	a0,s6
    8000189a:	00000097          	auipc	ra,0x0
    8000189e:	876080e7          	jalr	-1930(ra) # 80001110 <walkaddr>
    if(pa0 == 0)
    800018a2:	cd01                	beqz	a0,800018ba <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800018a4:	418904b3          	sub	s1,s2,s8
    800018a8:	94d6                	add	s1,s1,s5
    if(n > len)
    800018aa:	fc99f2e3          	bgeu	s3,s1,8000186e <copyin+0x28>
    800018ae:	84ce                	mv	s1,s3
    800018b0:	bf7d                	j	8000186e <copyin+0x28>
  }
  return 0;
    800018b2:	4501                	li	a0,0
    800018b4:	a021                	j	800018bc <copyin+0x76>
    800018b6:	4501                	li	a0,0
}
    800018b8:	8082                	ret
      return -1;
    800018ba:	557d                	li	a0,-1
}
    800018bc:	60a6                	ld	ra,72(sp)
    800018be:	6406                	ld	s0,64(sp)
    800018c0:	74e2                	ld	s1,56(sp)
    800018c2:	7942                	ld	s2,48(sp)
    800018c4:	79a2                	ld	s3,40(sp)
    800018c6:	7a02                	ld	s4,32(sp)
    800018c8:	6ae2                	ld	s5,24(sp)
    800018ca:	6b42                	ld	s6,16(sp)
    800018cc:	6ba2                	ld	s7,8(sp)
    800018ce:	6c02                	ld	s8,0(sp)
    800018d0:	6161                	addi	sp,sp,80
    800018d2:	8082                	ret

00000000800018d4 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800018d4:	c6c5                	beqz	a3,8000197c <copyinstr+0xa8>
{
    800018d6:	715d                	addi	sp,sp,-80
    800018d8:	e486                	sd	ra,72(sp)
    800018da:	e0a2                	sd	s0,64(sp)
    800018dc:	fc26                	sd	s1,56(sp)
    800018de:	f84a                	sd	s2,48(sp)
    800018e0:	f44e                	sd	s3,40(sp)
    800018e2:	f052                	sd	s4,32(sp)
    800018e4:	ec56                	sd	s5,24(sp)
    800018e6:	e85a                	sd	s6,16(sp)
    800018e8:	e45e                	sd	s7,8(sp)
    800018ea:	0880                	addi	s0,sp,80
    800018ec:	8a2a                	mv	s4,a0
    800018ee:	8b2e                	mv	s6,a1
    800018f0:	8bb2                	mv	s7,a2
    800018f2:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800018f4:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018f6:	6985                	lui	s3,0x1
    800018f8:	a035                	j	80001924 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800018fa:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800018fe:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001900:	0017b793          	seqz	a5,a5
    80001904:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001908:	60a6                	ld	ra,72(sp)
    8000190a:	6406                	ld	s0,64(sp)
    8000190c:	74e2                	ld	s1,56(sp)
    8000190e:	7942                	ld	s2,48(sp)
    80001910:	79a2                	ld	s3,40(sp)
    80001912:	7a02                	ld	s4,32(sp)
    80001914:	6ae2                	ld	s5,24(sp)
    80001916:	6b42                	ld	s6,16(sp)
    80001918:	6ba2                	ld	s7,8(sp)
    8000191a:	6161                	addi	sp,sp,80
    8000191c:	8082                	ret
    srcva = va0 + PGSIZE;
    8000191e:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001922:	c8a9                	beqz	s1,80001974 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001924:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001928:	85ca                	mv	a1,s2
    8000192a:	8552                	mv	a0,s4
    8000192c:	fffff097          	auipc	ra,0xfffff
    80001930:	7e4080e7          	jalr	2020(ra) # 80001110 <walkaddr>
    if(pa0 == 0)
    80001934:	c131                	beqz	a0,80001978 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001936:	41790833          	sub	a6,s2,s7
    8000193a:	984e                	add	a6,a6,s3
    if(n > max)
    8000193c:	0104f363          	bgeu	s1,a6,80001942 <copyinstr+0x6e>
    80001940:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001942:	955e                	add	a0,a0,s7
    80001944:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001948:	fc080be3          	beqz	a6,8000191e <copyinstr+0x4a>
    8000194c:	985a                	add	a6,a6,s6
    8000194e:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001950:	41650633          	sub	a2,a0,s6
    80001954:	14fd                	addi	s1,s1,-1
    80001956:	9b26                	add	s6,s6,s1
    80001958:	00f60733          	add	a4,a2,a5
    8000195c:	00074703          	lbu	a4,0(a4)
    80001960:	df49                	beqz	a4,800018fa <copyinstr+0x26>
        *dst = *p;
    80001962:	00e78023          	sb	a4,0(a5)
      --max;
    80001966:	40fb04b3          	sub	s1,s6,a5
      dst++;
    8000196a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000196c:	ff0796e3          	bne	a5,a6,80001958 <copyinstr+0x84>
      dst++;
    80001970:	8b42                	mv	s6,a6
    80001972:	b775                	j	8000191e <copyinstr+0x4a>
    80001974:	4781                	li	a5,0
    80001976:	b769                	j	80001900 <copyinstr+0x2c>
      return -1;
    80001978:	557d                	li	a0,-1
    8000197a:	b779                	j	80001908 <copyinstr+0x34>
  int got_null = 0;
    8000197c:	4781                	li	a5,0
  if(got_null){
    8000197e:	0017b793          	seqz	a5,a5
    80001982:	40f00533          	neg	a0,a5
}
    80001986:	8082                	ret

0000000080001988 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001988:	7139                	addi	sp,sp,-64
    8000198a:	fc06                	sd	ra,56(sp)
    8000198c:	f822                	sd	s0,48(sp)
    8000198e:	f426                	sd	s1,40(sp)
    80001990:	f04a                	sd	s2,32(sp)
    80001992:	ec4e                	sd	s3,24(sp)
    80001994:	e852                	sd	s4,16(sp)
    80001996:	e456                	sd	s5,8(sp)
    80001998:	e05a                	sd	s6,0(sp)
    8000199a:	0080                	addi	s0,sp,64
    8000199c:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000199e:	0000f497          	auipc	s1,0xf
    800019a2:	6c248493          	addi	s1,s1,1730 # 80011060 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800019a6:	8b26                	mv	s6,s1
    800019a8:	00006a97          	auipc	s5,0x6
    800019ac:	658a8a93          	addi	s5,s5,1624 # 80008000 <etext>
    800019b0:	04000937          	lui	s2,0x4000
    800019b4:	197d                	addi	s2,s2,-1
    800019b6:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019b8:	0002aa17          	auipc	s4,0x2a
    800019bc:	8a8a0a13          	addi	s4,s4,-1880 # 8002b260 <tickslock>
    char *pa = kalloc();
    800019c0:	fffff097          	auipc	ra,0xfffff
    800019c4:	126080e7          	jalr	294(ra) # 80000ae6 <kalloc>
    800019c8:	862a                	mv	a2,a0
    if(pa == 0)
    800019ca:	c131                	beqz	a0,80001a0e <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800019cc:	416485b3          	sub	a1,s1,s6
    800019d0:	858d                	srai	a1,a1,0x3
    800019d2:	000ab783          	ld	a5,0(s5)
    800019d6:	02f585b3          	mul	a1,a1,a5
    800019da:	2585                	addiw	a1,a1,1
    800019dc:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019e0:	4719                	li	a4,6
    800019e2:	6685                	lui	a3,0x1
    800019e4:	40b905b3          	sub	a1,s2,a1
    800019e8:	854e                	mv	a0,s3
    800019ea:	00000097          	auipc	ra,0x0
    800019ee:	808080e7          	jalr	-2040(ra) # 800011f2 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019f2:	68848493          	addi	s1,s1,1672
    800019f6:	fd4495e3          	bne	s1,s4,800019c0 <proc_mapstacks+0x38>
  }
}
    800019fa:	70e2                	ld	ra,56(sp)
    800019fc:	7442                	ld	s0,48(sp)
    800019fe:	74a2                	ld	s1,40(sp)
    80001a00:	7902                	ld	s2,32(sp)
    80001a02:	69e2                	ld	s3,24(sp)
    80001a04:	6a42                	ld	s4,16(sp)
    80001a06:	6aa2                	ld	s5,8(sp)
    80001a08:	6b02                	ld	s6,0(sp)
    80001a0a:	6121                	addi	sp,sp,64
    80001a0c:	8082                	ret
      panic("kalloc");
    80001a0e:	00006517          	auipc	a0,0x6
    80001a12:	7ca50513          	addi	a0,a0,1994 # 800081d8 <digits+0x198>
    80001a16:	fffff097          	auipc	ra,0xfffff
    80001a1a:	b28080e7          	jalr	-1240(ra) # 8000053e <panic>

0000000080001a1e <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001a1e:	7139                	addi	sp,sp,-64
    80001a20:	fc06                	sd	ra,56(sp)
    80001a22:	f822                	sd	s0,48(sp)
    80001a24:	f426                	sd	s1,40(sp)
    80001a26:	f04a                	sd	s2,32(sp)
    80001a28:	ec4e                	sd	s3,24(sp)
    80001a2a:	e852                	sd	s4,16(sp)
    80001a2c:	e456                	sd	s5,8(sp)
    80001a2e:	e05a                	sd	s6,0(sp)
    80001a30:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001a32:	00006597          	auipc	a1,0x6
    80001a36:	7ae58593          	addi	a1,a1,1966 # 800081e0 <digits+0x1a0>
    80001a3a:	0000f517          	auipc	a0,0xf
    80001a3e:	1f650513          	addi	a0,a0,502 # 80010c30 <pid_lock>
    80001a42:	fffff097          	auipc	ra,0xfffff
    80001a46:	104080e7          	jalr	260(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a4a:	00006597          	auipc	a1,0x6
    80001a4e:	79e58593          	addi	a1,a1,1950 # 800081e8 <digits+0x1a8>
    80001a52:	0000f517          	auipc	a0,0xf
    80001a56:	1f650513          	addi	a0,a0,502 # 80010c48 <wait_lock>
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	0ec080e7          	jalr	236(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a62:	0000f497          	auipc	s1,0xf
    80001a66:	5fe48493          	addi	s1,s1,1534 # 80011060 <proc>
      initlock(&p->lock, "proc");
    80001a6a:	00006b17          	auipc	s6,0x6
    80001a6e:	78eb0b13          	addi	s6,s6,1934 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001a72:	8aa6                	mv	s5,s1
    80001a74:	00006a17          	auipc	s4,0x6
    80001a78:	58ca0a13          	addi	s4,s4,1420 # 80008000 <etext>
    80001a7c:	04000937          	lui	s2,0x4000
    80001a80:	197d                	addi	s2,s2,-1
    80001a82:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a84:	00029997          	auipc	s3,0x29
    80001a88:	7dc98993          	addi	s3,s3,2012 # 8002b260 <tickslock>
      initlock(&p->lock, "proc");
    80001a8c:	85da                	mv	a1,s6
    80001a8e:	8526                	mv	a0,s1
    80001a90:	fffff097          	auipc	ra,0xfffff
    80001a94:	0b6080e7          	jalr	182(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    80001a98:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001a9c:	415487b3          	sub	a5,s1,s5
    80001aa0:	878d                	srai	a5,a5,0x3
    80001aa2:	000a3703          	ld	a4,0(s4)
    80001aa6:	02e787b3          	mul	a5,a5,a4
    80001aaa:	2785                	addiw	a5,a5,1
    80001aac:	00d7979b          	slliw	a5,a5,0xd
    80001ab0:	40f907b3          	sub	a5,s2,a5
    80001ab4:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ab6:	68848493          	addi	s1,s1,1672
    80001aba:	fd3499e3          	bne	s1,s3,80001a8c <procinit+0x6e>
  }
}
    80001abe:	70e2                	ld	ra,56(sp)
    80001ac0:	7442                	ld	s0,48(sp)
    80001ac2:	74a2                	ld	s1,40(sp)
    80001ac4:	7902                	ld	s2,32(sp)
    80001ac6:	69e2                	ld	s3,24(sp)
    80001ac8:	6a42                	ld	s4,16(sp)
    80001aca:	6aa2                	ld	s5,8(sp)
    80001acc:	6b02                	ld	s6,0(sp)
    80001ace:	6121                	addi	sp,sp,64
    80001ad0:	8082                	ret

0000000080001ad2 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001ad2:	1141                	addi	sp,sp,-16
    80001ad4:	e422                	sd	s0,8(sp)
    80001ad6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ad8:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001ada:	2501                	sext.w	a0,a0
    80001adc:	6422                	ld	s0,8(sp)
    80001ade:	0141                	addi	sp,sp,16
    80001ae0:	8082                	ret

0000000080001ae2 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001ae2:	1141                	addi	sp,sp,-16
    80001ae4:	e422                	sd	s0,8(sp)
    80001ae6:	0800                	addi	s0,sp,16
    80001ae8:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001aea:	2781                	sext.w	a5,a5
    80001aec:	079e                	slli	a5,a5,0x7
  return c;
}
    80001aee:	0000f517          	auipc	a0,0xf
    80001af2:	17250513          	addi	a0,a0,370 # 80010c60 <cpus>
    80001af6:	953e                	add	a0,a0,a5
    80001af8:	6422                	ld	s0,8(sp)
    80001afa:	0141                	addi	sp,sp,16
    80001afc:	8082                	ret

0000000080001afe <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001afe:	1101                	addi	sp,sp,-32
    80001b00:	ec06                	sd	ra,24(sp)
    80001b02:	e822                	sd	s0,16(sp)
    80001b04:	e426                	sd	s1,8(sp)
    80001b06:	1000                	addi	s0,sp,32
  push_off();
    80001b08:	fffff097          	auipc	ra,0xfffff
    80001b0c:	082080e7          	jalr	130(ra) # 80000b8a <push_off>
    80001b10:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b12:	2781                	sext.w	a5,a5
    80001b14:	079e                	slli	a5,a5,0x7
    80001b16:	0000f717          	auipc	a4,0xf
    80001b1a:	11a70713          	addi	a4,a4,282 # 80010c30 <pid_lock>
    80001b1e:	97ba                	add	a5,a5,a4
    80001b20:	7b84                	ld	s1,48(a5)
  pop_off();
    80001b22:	fffff097          	auipc	ra,0xfffff
    80001b26:	108080e7          	jalr	264(ra) # 80000c2a <pop_off>
  return p;
}
    80001b2a:	8526                	mv	a0,s1
    80001b2c:	60e2                	ld	ra,24(sp)
    80001b2e:	6442                	ld	s0,16(sp)
    80001b30:	64a2                	ld	s1,8(sp)
    80001b32:	6105                	addi	sp,sp,32
    80001b34:	8082                	ret

0000000080001b36 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001b36:	1141                	addi	sp,sp,-16
    80001b38:	e406                	sd	ra,8(sp)
    80001b3a:	e022                	sd	s0,0(sp)
    80001b3c:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001b3e:	00000097          	auipc	ra,0x0
    80001b42:	fc0080e7          	jalr	-64(ra) # 80001afe <myproc>
    80001b46:	fffff097          	auipc	ra,0xfffff
    80001b4a:	144080e7          	jalr	324(ra) # 80000c8a <release>

  if (first) {
    80001b4e:	00007797          	auipc	a5,0x7
    80001b52:	dd27a783          	lw	a5,-558(a5) # 80008920 <first.1>
    80001b56:	eb89                	bnez	a5,80001b68 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b58:	00001097          	auipc	ra,0x1
    80001b5c:	fcc080e7          	jalr	-52(ra) # 80002b24 <usertrapret>
}
    80001b60:	60a2                	ld	ra,8(sp)
    80001b62:	6402                	ld	s0,0(sp)
    80001b64:	0141                	addi	sp,sp,16
    80001b66:	8082                	ret
    first = 0;
    80001b68:	00007797          	auipc	a5,0x7
    80001b6c:	da07ac23          	sw	zero,-584(a5) # 80008920 <first.1>
    fsinit(ROOTDEV);
    80001b70:	4505                	li	a0,1
    80001b72:	00002097          	auipc	ra,0x2
    80001b76:	e6c080e7          	jalr	-404(ra) # 800039de <fsinit>
    80001b7a:	bff9                	j	80001b58 <forkret+0x22>

0000000080001b7c <allocpid>:
{
    80001b7c:	1101                	addi	sp,sp,-32
    80001b7e:	ec06                	sd	ra,24(sp)
    80001b80:	e822                	sd	s0,16(sp)
    80001b82:	e426                	sd	s1,8(sp)
    80001b84:	e04a                	sd	s2,0(sp)
    80001b86:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b88:	0000f917          	auipc	s2,0xf
    80001b8c:	0a890913          	addi	s2,s2,168 # 80010c30 <pid_lock>
    80001b90:	854a                	mv	a0,s2
    80001b92:	fffff097          	auipc	ra,0xfffff
    80001b96:	044080e7          	jalr	68(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001b9a:	00007797          	auipc	a5,0x7
    80001b9e:	d8a78793          	addi	a5,a5,-630 # 80008924 <nextpid>
    80001ba2:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ba4:	0014871b          	addiw	a4,s1,1
    80001ba8:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001baa:	854a                	mv	a0,s2
    80001bac:	fffff097          	auipc	ra,0xfffff
    80001bb0:	0de080e7          	jalr	222(ra) # 80000c8a <release>
}
    80001bb4:	8526                	mv	a0,s1
    80001bb6:	60e2                	ld	ra,24(sp)
    80001bb8:	6442                	ld	s0,16(sp)
    80001bba:	64a2                	ld	s1,8(sp)
    80001bbc:	6902                	ld	s2,0(sp)
    80001bbe:	6105                	addi	sp,sp,32
    80001bc0:	8082                	ret

0000000080001bc2 <proc_pagetable>:
{
    80001bc2:	1101                	addi	sp,sp,-32
    80001bc4:	ec06                	sd	ra,24(sp)
    80001bc6:	e822                	sd	s0,16(sp)
    80001bc8:	e426                	sd	s1,8(sp)
    80001bca:	e04a                	sd	s2,0(sp)
    80001bcc:	1000                	addi	s0,sp,32
    80001bce:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001bd0:	00000097          	auipc	ra,0x0
    80001bd4:	81c080e7          	jalr	-2020(ra) # 800013ec <uvmcreate>
    80001bd8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001bda:	c121                	beqz	a0,80001c1a <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bdc:	4729                	li	a4,10
    80001bde:	00005697          	auipc	a3,0x5
    80001be2:	42268693          	addi	a3,a3,1058 # 80007000 <_trampoline>
    80001be6:	6605                	lui	a2,0x1
    80001be8:	040005b7          	lui	a1,0x4000
    80001bec:	15fd                	addi	a1,a1,-1
    80001bee:	05b2                	slli	a1,a1,0xc
    80001bf0:	fffff097          	auipc	ra,0xfffff
    80001bf4:	562080e7          	jalr	1378(ra) # 80001152 <mappages>
    80001bf8:	02054863          	bltz	a0,80001c28 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bfc:	4719                	li	a4,6
    80001bfe:	05893683          	ld	a3,88(s2)
    80001c02:	6605                	lui	a2,0x1
    80001c04:	020005b7          	lui	a1,0x2000
    80001c08:	15fd                	addi	a1,a1,-1
    80001c0a:	05b6                	slli	a1,a1,0xd
    80001c0c:	8526                	mv	a0,s1
    80001c0e:	fffff097          	auipc	ra,0xfffff
    80001c12:	544080e7          	jalr	1348(ra) # 80001152 <mappages>
    80001c16:	02054163          	bltz	a0,80001c38 <proc_pagetable+0x76>
}
    80001c1a:	8526                	mv	a0,s1
    80001c1c:	60e2                	ld	ra,24(sp)
    80001c1e:	6442                	ld	s0,16(sp)
    80001c20:	64a2                	ld	s1,8(sp)
    80001c22:	6902                	ld	s2,0(sp)
    80001c24:	6105                	addi	sp,sp,32
    80001c26:	8082                	ret
    uvmfree(pagetable, 0);
    80001c28:	4581                	li	a1,0
    80001c2a:	8526                	mv	a0,s1
    80001c2c:	00000097          	auipc	ra,0x0
    80001c30:	a52080e7          	jalr	-1454(ra) # 8000167e <uvmfree>
    return 0;
    80001c34:	4481                	li	s1,0
    80001c36:	b7d5                	j	80001c1a <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c38:	4681                	li	a3,0
    80001c3a:	4605                	li	a2,1
    80001c3c:	040005b7          	lui	a1,0x4000
    80001c40:	15fd                	addi	a1,a1,-1
    80001c42:	05b2                	slli	a1,a1,0xc
    80001c44:	8526                	mv	a0,s1
    80001c46:	fffff097          	auipc	ra,0xfffff
    80001c4a:	6d2080e7          	jalr	1746(ra) # 80001318 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c4e:	4581                	li	a1,0
    80001c50:	8526                	mv	a0,s1
    80001c52:	00000097          	auipc	ra,0x0
    80001c56:	a2c080e7          	jalr	-1492(ra) # 8000167e <uvmfree>
    return 0;
    80001c5a:	4481                	li	s1,0
    80001c5c:	bf7d                	j	80001c1a <proc_pagetable+0x58>

0000000080001c5e <proc_freepagetable>:
{
    80001c5e:	1101                	addi	sp,sp,-32
    80001c60:	ec06                	sd	ra,24(sp)
    80001c62:	e822                	sd	s0,16(sp)
    80001c64:	e426                	sd	s1,8(sp)
    80001c66:	e04a                	sd	s2,0(sp)
    80001c68:	1000                	addi	s0,sp,32
    80001c6a:	84aa                	mv	s1,a0
    80001c6c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c6e:	4681                	li	a3,0
    80001c70:	4605                	li	a2,1
    80001c72:	040005b7          	lui	a1,0x4000
    80001c76:	15fd                	addi	a1,a1,-1
    80001c78:	05b2                	slli	a1,a1,0xc
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	69e080e7          	jalr	1694(ra) # 80001318 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c82:	4681                	li	a3,0
    80001c84:	4605                	li	a2,1
    80001c86:	020005b7          	lui	a1,0x2000
    80001c8a:	15fd                	addi	a1,a1,-1
    80001c8c:	05b6                	slli	a1,a1,0xd
    80001c8e:	8526                	mv	a0,s1
    80001c90:	fffff097          	auipc	ra,0xfffff
    80001c94:	688080e7          	jalr	1672(ra) # 80001318 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c98:	85ca                	mv	a1,s2
    80001c9a:	8526                	mv	a0,s1
    80001c9c:	00000097          	auipc	ra,0x0
    80001ca0:	9e2080e7          	jalr	-1566(ra) # 8000167e <uvmfree>
}
    80001ca4:	60e2                	ld	ra,24(sp)
    80001ca6:	6442                	ld	s0,16(sp)
    80001ca8:	64a2                	ld	s1,8(sp)
    80001caa:	6902                	ld	s2,0(sp)
    80001cac:	6105                	addi	sp,sp,32
    80001cae:	8082                	ret

0000000080001cb0 <freeproc>:
{
    80001cb0:	1101                	addi	sp,sp,-32
    80001cb2:	ec06                	sd	ra,24(sp)
    80001cb4:	e822                	sd	s0,16(sp)
    80001cb6:	e426                	sd	s1,8(sp)
    80001cb8:	1000                	addi	s0,sp,32
    80001cba:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001cbc:	6d28                	ld	a0,88(a0)
    80001cbe:	c509                	beqz	a0,80001cc8 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001cc0:	fffff097          	auipc	ra,0xfffff
    80001cc4:	d2a080e7          	jalr	-726(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001cc8:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001ccc:	68a8                	ld	a0,80(s1)
    80001cce:	c511                	beqz	a0,80001cda <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001cd0:	64ac                	ld	a1,72(s1)
    80001cd2:	00000097          	auipc	ra,0x0
    80001cd6:	f8c080e7          	jalr	-116(ra) # 80001c5e <proc_freepagetable>
  p->pagetable = 0;
    80001cda:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001cde:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001ce2:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001ce6:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001cea:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001cee:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001cf2:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001cf6:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001cfa:	0004ac23          	sw	zero,24(s1)
  p->swapPagesCount=0;
    80001cfe:	2604bc23          	sd	zero,632(s1)
  p->physicalPagesCount=0;
    80001d02:	2604b823          	sd	zero,624(s1)
  p->helpPageTimer=0;
    80001d06:	6804b023          	sd	zero,1664(s1)
}
    80001d0a:	60e2                	ld	ra,24(sp)
    80001d0c:	6442                	ld	s0,16(sp)
    80001d0e:	64a2                	ld	s1,8(sp)
    80001d10:	6105                	addi	sp,sp,32
    80001d12:	8082                	ret

0000000080001d14 <allocproc>:
{
    80001d14:	1101                	addi	sp,sp,-32
    80001d16:	ec06                	sd	ra,24(sp)
    80001d18:	e822                	sd	s0,16(sp)
    80001d1a:	e426                	sd	s1,8(sp)
    80001d1c:	e04a                	sd	s2,0(sp)
    80001d1e:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d20:	0000f497          	auipc	s1,0xf
    80001d24:	34048493          	addi	s1,s1,832 # 80011060 <proc>
    80001d28:	00029917          	auipc	s2,0x29
    80001d2c:	53890913          	addi	s2,s2,1336 # 8002b260 <tickslock>
    acquire(&p->lock);
    80001d30:	8526                	mv	a0,s1
    80001d32:	fffff097          	auipc	ra,0xfffff
    80001d36:	ea4080e7          	jalr	-348(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001d3a:	4c9c                	lw	a5,24(s1)
    80001d3c:	cf81                	beqz	a5,80001d54 <allocproc+0x40>
      release(&p->lock);
    80001d3e:	8526                	mv	a0,s1
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	f4a080e7          	jalr	-182(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d48:	68848493          	addi	s1,s1,1672
    80001d4c:	ff2492e3          	bne	s1,s2,80001d30 <allocproc+0x1c>
  return 0;
    80001d50:	4481                	li	s1,0
    80001d52:	a899                	j	80001da8 <allocproc+0x94>
  p->pid = allocpid();
    80001d54:	00000097          	auipc	ra,0x0
    80001d58:	e28080e7          	jalr	-472(ra) # 80001b7c <allocpid>
    80001d5c:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d5e:	4785                	li	a5,1
    80001d60:	cc9c                	sw	a5,24(s1)
  p ->helpPageTimer=0;
    80001d62:	6804b023          	sd	zero,1664(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d66:	fffff097          	auipc	ra,0xfffff
    80001d6a:	d80080e7          	jalr	-640(ra) # 80000ae6 <kalloc>
    80001d6e:	892a                	mv	s2,a0
    80001d70:	eca8                	sd	a0,88(s1)
    80001d72:	c131                	beqz	a0,80001db6 <allocproc+0xa2>
  p->pagetable = proc_pagetable(p);
    80001d74:	8526                	mv	a0,s1
    80001d76:	00000097          	auipc	ra,0x0
    80001d7a:	e4c080e7          	jalr	-436(ra) # 80001bc2 <proc_pagetable>
    80001d7e:	892a                	mv	s2,a0
    80001d80:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d82:	c531                	beqz	a0,80001dce <allocproc+0xba>
  memset(&p->context, 0, sizeof(p->context));
    80001d84:	07000613          	li	a2,112
    80001d88:	4581                	li	a1,0
    80001d8a:	06048513          	addi	a0,s1,96
    80001d8e:	fffff097          	auipc	ra,0xfffff
    80001d92:	f44080e7          	jalr	-188(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001d96:	00000797          	auipc	a5,0x0
    80001d9a:	da078793          	addi	a5,a5,-608 # 80001b36 <forkret>
    80001d9e:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001da0:	60bc                	ld	a5,64(s1)
    80001da2:	6705                	lui	a4,0x1
    80001da4:	97ba                	add	a5,a5,a4
    80001da6:	f4bc                	sd	a5,104(s1)
}
    80001da8:	8526                	mv	a0,s1
    80001daa:	60e2                	ld	ra,24(sp)
    80001dac:	6442                	ld	s0,16(sp)
    80001dae:	64a2                	ld	s1,8(sp)
    80001db0:	6902                	ld	s2,0(sp)
    80001db2:	6105                	addi	sp,sp,32
    80001db4:	8082                	ret
    freeproc(p);
    80001db6:	8526                	mv	a0,s1
    80001db8:	00000097          	auipc	ra,0x0
    80001dbc:	ef8080e7          	jalr	-264(ra) # 80001cb0 <freeproc>
    release(&p->lock);
    80001dc0:	8526                	mv	a0,s1
    80001dc2:	fffff097          	auipc	ra,0xfffff
    80001dc6:	ec8080e7          	jalr	-312(ra) # 80000c8a <release>
    return 0;
    80001dca:	84ca                	mv	s1,s2
    80001dcc:	bff1                	j	80001da8 <allocproc+0x94>
    freeproc(p);
    80001dce:	8526                	mv	a0,s1
    80001dd0:	00000097          	auipc	ra,0x0
    80001dd4:	ee0080e7          	jalr	-288(ra) # 80001cb0 <freeproc>
    release(&p->lock);
    80001dd8:	8526                	mv	a0,s1
    80001dda:	fffff097          	auipc	ra,0xfffff
    80001dde:	eb0080e7          	jalr	-336(ra) # 80000c8a <release>
    return 0;
    80001de2:	84ca                	mv	s1,s2
    80001de4:	b7d1                	j	80001da8 <allocproc+0x94>

0000000080001de6 <userinit>:
{
    80001de6:	1101                	addi	sp,sp,-32
    80001de8:	ec06                	sd	ra,24(sp)
    80001dea:	e822                	sd	s0,16(sp)
    80001dec:	e426                	sd	s1,8(sp)
    80001dee:	1000                	addi	s0,sp,32
  p = allocproc();
    80001df0:	00000097          	auipc	ra,0x0
    80001df4:	f24080e7          	jalr	-220(ra) # 80001d14 <allocproc>
    80001df8:	84aa                	mv	s1,a0
  initproc = p;
    80001dfa:	00007797          	auipc	a5,0x7
    80001dfe:	baa7bf23          	sd	a0,-1090(a5) # 800089b8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001e02:	03400613          	li	a2,52
    80001e06:	00007597          	auipc	a1,0x7
    80001e0a:	b2a58593          	addi	a1,a1,-1238 # 80008930 <initcode>
    80001e0e:	6928                	ld	a0,80(a0)
    80001e10:	fffff097          	auipc	ra,0xfffff
    80001e14:	60a080e7          	jalr	1546(ra) # 8000141a <uvmfirst>
  p->sz = PGSIZE;
    80001e18:	6785                	lui	a5,0x1
    80001e1a:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001e1c:	6cb8                	ld	a4,88(s1)
    80001e1e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001e22:	6cb8                	ld	a4,88(s1)
    80001e24:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e26:	4641                	li	a2,16
    80001e28:	00006597          	auipc	a1,0x6
    80001e2c:	3d858593          	addi	a1,a1,984 # 80008200 <digits+0x1c0>
    80001e30:	15848513          	addi	a0,s1,344
    80001e34:	fffff097          	auipc	ra,0xfffff
    80001e38:	fe8080e7          	jalr	-24(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001e3c:	00006517          	auipc	a0,0x6
    80001e40:	3d450513          	addi	a0,a0,980 # 80008210 <digits+0x1d0>
    80001e44:	00002097          	auipc	ra,0x2
    80001e48:	5bc080e7          	jalr	1468(ra) # 80004400 <namei>
    80001e4c:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e50:	478d                	li	a5,3
    80001e52:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e54:	8526                	mv	a0,s1
    80001e56:	fffff097          	auipc	ra,0xfffff
    80001e5a:	e34080e7          	jalr	-460(ra) # 80000c8a <release>
}
    80001e5e:	60e2                	ld	ra,24(sp)
    80001e60:	6442                	ld	s0,16(sp)
    80001e62:	64a2                	ld	s1,8(sp)
    80001e64:	6105                	addi	sp,sp,32
    80001e66:	8082                	ret

0000000080001e68 <growproc>:
{
    80001e68:	1101                	addi	sp,sp,-32
    80001e6a:	ec06                	sd	ra,24(sp)
    80001e6c:	e822                	sd	s0,16(sp)
    80001e6e:	e426                	sd	s1,8(sp)
    80001e70:	e04a                	sd	s2,0(sp)
    80001e72:	1000                	addi	s0,sp,32
    80001e74:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001e76:	00000097          	auipc	ra,0x0
    80001e7a:	c88080e7          	jalr	-888(ra) # 80001afe <myproc>
    80001e7e:	84aa                	mv	s1,a0
  sz = p->sz;
    80001e80:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001e82:	01204c63          	bgtz	s2,80001e9a <growproc+0x32>
  } else if(n < 0){
    80001e86:	02094663          	bltz	s2,80001eb2 <growproc+0x4a>
  p->sz = sz;
    80001e8a:	e4ac                	sd	a1,72(s1)
  return 0;
    80001e8c:	4501                	li	a0,0
}
    80001e8e:	60e2                	ld	ra,24(sp)
    80001e90:	6442                	ld	s0,16(sp)
    80001e92:	64a2                	ld	s1,8(sp)
    80001e94:	6902                	ld	s2,0(sp)
    80001e96:	6105                	addi	sp,sp,32
    80001e98:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001e9a:	4691                	li	a3,4
    80001e9c:	00b90633          	add	a2,s2,a1
    80001ea0:	6928                	ld	a0,80(a0)
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	632080e7          	jalr	1586(ra) # 800014d4 <uvmalloc>
    80001eaa:	85aa                	mv	a1,a0
    80001eac:	fd79                	bnez	a0,80001e8a <growproc+0x22>
      return -1;
    80001eae:	557d                	li	a0,-1
    80001eb0:	bff9                	j	80001e8e <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001eb2:	00b90633          	add	a2,s2,a1
    80001eb6:	6928                	ld	a0,80(a0)
    80001eb8:	fffff097          	auipc	ra,0xfffff
    80001ebc:	5d4080e7          	jalr	1492(ra) # 8000148c <uvmdealloc>
    80001ec0:	85aa                	mv	a1,a0
    80001ec2:	b7e1                	j	80001e8a <growproc+0x22>

0000000080001ec4 <fork>:
{
    80001ec4:	7139                	addi	sp,sp,-64
    80001ec6:	fc06                	sd	ra,56(sp)
    80001ec8:	f822                	sd	s0,48(sp)
    80001eca:	f426                	sd	s1,40(sp)
    80001ecc:	f04a                	sd	s2,32(sp)
    80001ece:	ec4e                	sd	s3,24(sp)
    80001ed0:	e852                	sd	s4,16(sp)
    80001ed2:	e456                	sd	s5,8(sp)
    80001ed4:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001ed6:	00000097          	auipc	ra,0x0
    80001eda:	c28080e7          	jalr	-984(ra) # 80001afe <myproc>
    80001ede:	8a2a                	mv	s4,a0
  if((np = allocproc()) == 0){
    80001ee0:	00000097          	auipc	ra,0x0
    80001ee4:	e34080e7          	jalr	-460(ra) # 80001d14 <allocproc>
    80001ee8:	1a050863          	beqz	a0,80002098 <fork+0x1d4>
    80001eec:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001eee:	048a3603          	ld	a2,72(s4)
    80001ef2:	692c                	ld	a1,80(a0)
    80001ef4:	050a3503          	ld	a0,80(s4)
    80001ef8:	fffff097          	auipc	ra,0xfffff
    80001efc:	7be080e7          	jalr	1982(ra) # 800016b6 <uvmcopy>
    80001f00:	04054863          	bltz	a0,80001f50 <fork+0x8c>
  np->sz = p->sz;
    80001f04:	048a3783          	ld	a5,72(s4)
    80001f08:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001f0c:	058a3683          	ld	a3,88(s4)
    80001f10:	87b6                	mv	a5,a3
    80001f12:	0589b703          	ld	a4,88(s3)
    80001f16:	12068693          	addi	a3,a3,288
    80001f1a:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f1e:	6788                	ld	a0,8(a5)
    80001f20:	6b8c                	ld	a1,16(a5)
    80001f22:	6f90                	ld	a2,24(a5)
    80001f24:	01073023          	sd	a6,0(a4)
    80001f28:	e708                	sd	a0,8(a4)
    80001f2a:	eb0c                	sd	a1,16(a4)
    80001f2c:	ef10                	sd	a2,24(a4)
    80001f2e:	02078793          	addi	a5,a5,32
    80001f32:	02070713          	addi	a4,a4,32
    80001f36:	fed792e3          	bne	a5,a3,80001f1a <fork+0x56>
  np->trapframe->a0 = 0;
    80001f3a:	0589b783          	ld	a5,88(s3)
    80001f3e:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001f42:	0d0a0493          	addi	s1,s4,208
    80001f46:	0d098913          	addi	s2,s3,208
    80001f4a:	150a0a93          	addi	s5,s4,336
    80001f4e:	a00d                	j	80001f70 <fork+0xac>
    freeproc(np);
    80001f50:	854e                	mv	a0,s3
    80001f52:	00000097          	auipc	ra,0x0
    80001f56:	d5e080e7          	jalr	-674(ra) # 80001cb0 <freeproc>
    release(&np->lock);
    80001f5a:	854e                	mv	a0,s3
    80001f5c:	fffff097          	auipc	ra,0xfffff
    80001f60:	d2e080e7          	jalr	-722(ra) # 80000c8a <release>
    return -1;
    80001f64:	5afd                	li	s5,-1
    80001f66:	a841                	j	80001ff6 <fork+0x132>
  for(i = 0; i < NOFILE; i++)
    80001f68:	04a1                	addi	s1,s1,8
    80001f6a:	0921                	addi	s2,s2,8
    80001f6c:	01548b63          	beq	s1,s5,80001f82 <fork+0xbe>
    if(p->ofile[i])
    80001f70:	6088                	ld	a0,0(s1)
    80001f72:	d97d                	beqz	a0,80001f68 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f74:	00003097          	auipc	ra,0x3
    80001f78:	e34080e7          	jalr	-460(ra) # 80004da8 <filedup>
    80001f7c:	00a93023          	sd	a0,0(s2)
    80001f80:	b7e5                	j	80001f68 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001f82:	150a3503          	ld	a0,336(s4)
    80001f86:	00002097          	auipc	ra,0x2
    80001f8a:	c96080e7          	jalr	-874(ra) # 80003c1c <idup>
    80001f8e:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f92:	4641                	li	a2,16
    80001f94:	158a0593          	addi	a1,s4,344
    80001f98:	15898513          	addi	a0,s3,344
    80001f9c:	fffff097          	auipc	ra,0xfffff
    80001fa0:	e80080e7          	jalr	-384(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001fa4:	0309aa83          	lw	s5,48(s3)
  release(&np->lock);
    80001fa8:	854e                	mv	a0,s3
    80001faa:	fffff097          	auipc	ra,0xfffff
    80001fae:	ce0080e7          	jalr	-800(ra) # 80000c8a <release>
   if(p->pid >2){//dont copy init &shell 
    80001fb2:	030a2703          	lw	a4,48(s4)
    80001fb6:	4789                	li	a5,2
    80001fb8:	04e7c963          	blt	a5,a4,8000200a <fork+0x146>
  acquire(&wait_lock);
    80001fbc:	0000f497          	auipc	s1,0xf
    80001fc0:	c8c48493          	addi	s1,s1,-884 # 80010c48 <wait_lock>
    80001fc4:	8526                	mv	a0,s1
    80001fc6:	fffff097          	auipc	ra,0xfffff
    80001fca:	c10080e7          	jalr	-1008(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001fce:	0349bc23          	sd	s4,56(s3)
  release(&wait_lock);
    80001fd2:	8526                	mv	a0,s1
    80001fd4:	fffff097          	auipc	ra,0xfffff
    80001fd8:	cb6080e7          	jalr	-842(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001fdc:	854e                	mv	a0,s3
    80001fde:	fffff097          	auipc	ra,0xfffff
    80001fe2:	bf8080e7          	jalr	-1032(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001fe6:	478d                	li	a5,3
    80001fe8:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001fec:	854e                	mv	a0,s3
    80001fee:	fffff097          	auipc	ra,0xfffff
    80001ff2:	c9c080e7          	jalr	-868(ra) # 80000c8a <release>
}
    80001ff6:	8556                	mv	a0,s5
    80001ff8:	70e2                	ld	ra,56(sp)
    80001ffa:	7442                	ld	s0,48(sp)
    80001ffc:	74a2                	ld	s1,40(sp)
    80001ffe:	7902                	ld	s2,32(sp)
    80002000:	69e2                	ld	s3,24(sp)
    80002002:	6a42                	ld	s4,16(sp)
    80002004:	6aa2                	ld	s5,8(sp)
    80002006:	6121                	addi	sp,sp,64
    80002008:	8082                	ret
    createSwapFile(np);
    8000200a:	854e                	mv	a0,s3
    8000200c:	00002097          	auipc	ra,0x2
    80002010:	648080e7          	jalr	1608(ra) # 80004654 <createSwapFile>
    while(idx<MAX_PSYC_PAGES){
    80002014:	280a0793          	addi	a5,s4,640
    80002018:	28098713          	addi	a4,s3,640
    8000201c:	480a0613          	addi	a2,s4,1152
      np->pagesInPysical[idx].va=p->pagesInPysical[idx].va;
    80002020:	6394                	ld	a3,0(a5)
    80002022:	e314                	sd	a3,0(a4)
      np->pagesInPysical[idx].idxIsHere=p->pagesInPysical[idx].idxIsHere;
    80002024:	6794                	ld	a3,8(a5)
    80002026:	e714                	sd	a3,8(a4)
      np->pagesInSwap[idx].va=p->pagesInSwap[idx].va;
    80002028:	2007b683          	ld	a3,512(a5)
    8000202c:	20d73023          	sd	a3,512(a4)
      np->pagesInSwap[idx].idxIsHere=p->pagesInSwap[idx].idxIsHere;
    80002030:	2087b683          	ld	a3,520(a5)
    80002034:	20d73423          	sd	a3,520(a4)
    while(idx<MAX_PSYC_PAGES){
    80002038:	02078793          	addi	a5,a5,32
    8000203c:	02070713          	addi	a4,a4,32
    80002040:	fec790e3          	bne	a5,a2,80002020 <fork+0x15c>
    np->physicalPagesCount=p->physicalPagesCount;
    80002044:	270a3783          	ld	a5,624(s4)
    80002048:	26f9b823          	sd	a5,624(s3)
    np->swapPagesCount=p->swapPagesCount;
    8000204c:	278a3783          	ld	a5,632(s4)
    80002050:	26f9bc23          	sd	a5,632(s3)
    np->helpPageTimer=  p->helpPageTimer;
    80002054:	680a3783          	ld	a5,1664(s4)
    80002058:	68f9b023          	sd	a5,1664(s3)
    char *space =kalloc();
    8000205c:	fffff097          	auipc	ra,0xfffff
    80002060:	a8a080e7          	jalr	-1398(ra) # 80000ae6 <kalloc>
    80002064:	892a                	mv	s2,a0
    80002066:	44c1                	li	s1,16
      readFromSwapFile(p,space,i*PGSIZE,PGSIZE);
    80002068:	6685                	lui	a3,0x1
    8000206a:	6641                	lui	a2,0x10
    8000206c:	85ca                	mv	a1,s2
    8000206e:	8552                	mv	a0,s4
    80002070:	00002097          	auipc	ra,0x2
    80002074:	6b8080e7          	jalr	1720(ra) # 80004728 <readFromSwapFile>
      writeToSwapFile(np,space,i*PGSIZE,PGSIZE);
    80002078:	6685                	lui	a3,0x1
    8000207a:	6641                	lui	a2,0x10
    8000207c:	85ca                	mv	a1,s2
    8000207e:	854e                	mv	a0,s3
    80002080:	00002097          	auipc	ra,0x2
    80002084:	684080e7          	jalr	1668(ra) # 80004704 <writeToSwapFile>
    while(idx<MAX_PSYC_PAGES){
    80002088:	34fd                	addiw	s1,s1,-1
    8000208a:	fcf9                	bnez	s1,80002068 <fork+0x1a4>
    kfree(space);
    8000208c:	854a                	mv	a0,s2
    8000208e:	fffff097          	auipc	ra,0xfffff
    80002092:	95c080e7          	jalr	-1700(ra) # 800009ea <kfree>
    80002096:	b71d                	j	80001fbc <fork+0xf8>
    return -1;
    80002098:	5afd                	li	s5,-1
    8000209a:	bfb1                	j	80001ff6 <fork+0x132>

000000008000209c <scheduler>:
{
    8000209c:	7139                	addi	sp,sp,-64
    8000209e:	fc06                	sd	ra,56(sp)
    800020a0:	f822                	sd	s0,48(sp)
    800020a2:	f426                	sd	s1,40(sp)
    800020a4:	f04a                	sd	s2,32(sp)
    800020a6:	ec4e                	sd	s3,24(sp)
    800020a8:	e852                	sd	s4,16(sp)
    800020aa:	e456                	sd	s5,8(sp)
    800020ac:	e05a                	sd	s6,0(sp)
    800020ae:	0080                	addi	s0,sp,64
    800020b0:	8792                	mv	a5,tp
  int id = r_tp();
    800020b2:	2781                	sext.w	a5,a5
  c->proc = 0;
    800020b4:	00779a93          	slli	s5,a5,0x7
    800020b8:	0000f717          	auipc	a4,0xf
    800020bc:	b7870713          	addi	a4,a4,-1160 # 80010c30 <pid_lock>
    800020c0:	9756                	add	a4,a4,s5
    800020c2:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    800020c6:	0000f717          	auipc	a4,0xf
    800020ca:	ba270713          	addi	a4,a4,-1118 # 80010c68 <cpus+0x8>
    800020ce:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    800020d0:	498d                	li	s3,3
        p->state = RUNNING;
    800020d2:	4b11                	li	s6,4
        c->proc = p;
    800020d4:	079e                	slli	a5,a5,0x7
    800020d6:	0000fa17          	auipc	s4,0xf
    800020da:	b5aa0a13          	addi	s4,s4,-1190 # 80010c30 <pid_lock>
    800020de:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800020e0:	00029917          	auipc	s2,0x29
    800020e4:	18090913          	addi	s2,s2,384 # 8002b260 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020e8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020ec:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020f0:	10079073          	csrw	sstatus,a5
    800020f4:	0000f497          	auipc	s1,0xf
    800020f8:	f6c48493          	addi	s1,s1,-148 # 80011060 <proc>
    800020fc:	a811                	j	80002110 <scheduler+0x74>
      release(&p->lock);
    800020fe:	8526                	mv	a0,s1
    80002100:	fffff097          	auipc	ra,0xfffff
    80002104:	b8a080e7          	jalr	-1142(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002108:	68848493          	addi	s1,s1,1672
    8000210c:	fd248ee3          	beq	s1,s2,800020e8 <scheduler+0x4c>
      acquire(&p->lock);
    80002110:	8526                	mv	a0,s1
    80002112:	fffff097          	auipc	ra,0xfffff
    80002116:	ac4080e7          	jalr	-1340(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    8000211a:	4c9c                	lw	a5,24(s1)
    8000211c:	ff3791e3          	bne	a5,s3,800020fe <scheduler+0x62>
        p->state = RUNNING;
    80002120:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002124:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002128:	06048593          	addi	a1,s1,96
    8000212c:	8556                	mv	a0,s5
    8000212e:	00001097          	auipc	ra,0x1
    80002132:	94c080e7          	jalr	-1716(ra) # 80002a7a <swtch>
        c->proc = 0;
    80002136:	020a3823          	sd	zero,48(s4)
    8000213a:	b7d1                	j	800020fe <scheduler+0x62>

000000008000213c <sched>:
{
    8000213c:	7179                	addi	sp,sp,-48
    8000213e:	f406                	sd	ra,40(sp)
    80002140:	f022                	sd	s0,32(sp)
    80002142:	ec26                	sd	s1,24(sp)
    80002144:	e84a                	sd	s2,16(sp)
    80002146:	e44e                	sd	s3,8(sp)
    80002148:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000214a:	00000097          	auipc	ra,0x0
    8000214e:	9b4080e7          	jalr	-1612(ra) # 80001afe <myproc>
    80002152:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002154:	fffff097          	auipc	ra,0xfffff
    80002158:	a08080e7          	jalr	-1528(ra) # 80000b5c <holding>
    8000215c:	c93d                	beqz	a0,800021d2 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000215e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002160:	2781                	sext.w	a5,a5
    80002162:	079e                	slli	a5,a5,0x7
    80002164:	0000f717          	auipc	a4,0xf
    80002168:	acc70713          	addi	a4,a4,-1332 # 80010c30 <pid_lock>
    8000216c:	97ba                	add	a5,a5,a4
    8000216e:	0a87a703          	lw	a4,168(a5)
    80002172:	4785                	li	a5,1
    80002174:	06f71763          	bne	a4,a5,800021e2 <sched+0xa6>
  if(p->state == RUNNING)
    80002178:	4c98                	lw	a4,24(s1)
    8000217a:	4791                	li	a5,4
    8000217c:	06f70b63          	beq	a4,a5,800021f2 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002180:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002184:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002186:	efb5                	bnez	a5,80002202 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002188:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000218a:	0000f917          	auipc	s2,0xf
    8000218e:	aa690913          	addi	s2,s2,-1370 # 80010c30 <pid_lock>
    80002192:	2781                	sext.w	a5,a5
    80002194:	079e                	slli	a5,a5,0x7
    80002196:	97ca                	add	a5,a5,s2
    80002198:	0ac7a983          	lw	s3,172(a5)
    8000219c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000219e:	2781                	sext.w	a5,a5
    800021a0:	079e                	slli	a5,a5,0x7
    800021a2:	0000f597          	auipc	a1,0xf
    800021a6:	ac658593          	addi	a1,a1,-1338 # 80010c68 <cpus+0x8>
    800021aa:	95be                	add	a1,a1,a5
    800021ac:	06048513          	addi	a0,s1,96
    800021b0:	00001097          	auipc	ra,0x1
    800021b4:	8ca080e7          	jalr	-1846(ra) # 80002a7a <swtch>
    800021b8:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021ba:	2781                	sext.w	a5,a5
    800021bc:	079e                	slli	a5,a5,0x7
    800021be:	97ca                	add	a5,a5,s2
    800021c0:	0b37a623          	sw	s3,172(a5)
}
    800021c4:	70a2                	ld	ra,40(sp)
    800021c6:	7402                	ld	s0,32(sp)
    800021c8:	64e2                	ld	s1,24(sp)
    800021ca:	6942                	ld	s2,16(sp)
    800021cc:	69a2                	ld	s3,8(sp)
    800021ce:	6145                	addi	sp,sp,48
    800021d0:	8082                	ret
    panic("sched p->lock");
    800021d2:	00006517          	auipc	a0,0x6
    800021d6:	04650513          	addi	a0,a0,70 # 80008218 <digits+0x1d8>
    800021da:	ffffe097          	auipc	ra,0xffffe
    800021de:	364080e7          	jalr	868(ra) # 8000053e <panic>
    panic("sched locks");
    800021e2:	00006517          	auipc	a0,0x6
    800021e6:	04650513          	addi	a0,a0,70 # 80008228 <digits+0x1e8>
    800021ea:	ffffe097          	auipc	ra,0xffffe
    800021ee:	354080e7          	jalr	852(ra) # 8000053e <panic>
    panic("sched running");
    800021f2:	00006517          	auipc	a0,0x6
    800021f6:	04650513          	addi	a0,a0,70 # 80008238 <digits+0x1f8>
    800021fa:	ffffe097          	auipc	ra,0xffffe
    800021fe:	344080e7          	jalr	836(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002202:	00006517          	auipc	a0,0x6
    80002206:	04650513          	addi	a0,a0,70 # 80008248 <digits+0x208>
    8000220a:	ffffe097          	auipc	ra,0xffffe
    8000220e:	334080e7          	jalr	820(ra) # 8000053e <panic>

0000000080002212 <yield>:
{
    80002212:	1101                	addi	sp,sp,-32
    80002214:	ec06                	sd	ra,24(sp)
    80002216:	e822                	sd	s0,16(sp)
    80002218:	e426                	sd	s1,8(sp)
    8000221a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000221c:	00000097          	auipc	ra,0x0
    80002220:	8e2080e7          	jalr	-1822(ra) # 80001afe <myproc>
    80002224:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002226:	fffff097          	auipc	ra,0xfffff
    8000222a:	9b0080e7          	jalr	-1616(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    8000222e:	478d                	li	a5,3
    80002230:	cc9c                	sw	a5,24(s1)
  sched();
    80002232:	00000097          	auipc	ra,0x0
    80002236:	f0a080e7          	jalr	-246(ra) # 8000213c <sched>
  release(&p->lock);
    8000223a:	8526                	mv	a0,s1
    8000223c:	fffff097          	auipc	ra,0xfffff
    80002240:	a4e080e7          	jalr	-1458(ra) # 80000c8a <release>
}
    80002244:	60e2                	ld	ra,24(sp)
    80002246:	6442                	ld	s0,16(sp)
    80002248:	64a2                	ld	s1,8(sp)
    8000224a:	6105                	addi	sp,sp,32
    8000224c:	8082                	ret

000000008000224e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000224e:	7179                	addi	sp,sp,-48
    80002250:	f406                	sd	ra,40(sp)
    80002252:	f022                	sd	s0,32(sp)
    80002254:	ec26                	sd	s1,24(sp)
    80002256:	e84a                	sd	s2,16(sp)
    80002258:	e44e                	sd	s3,8(sp)
    8000225a:	1800                	addi	s0,sp,48
    8000225c:	89aa                	mv	s3,a0
    8000225e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002260:	00000097          	auipc	ra,0x0
    80002264:	89e080e7          	jalr	-1890(ra) # 80001afe <myproc>
    80002268:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000226a:	fffff097          	auipc	ra,0xfffff
    8000226e:	96c080e7          	jalr	-1684(ra) # 80000bd6 <acquire>
  release(lk);
    80002272:	854a                	mv	a0,s2
    80002274:	fffff097          	auipc	ra,0xfffff
    80002278:	a16080e7          	jalr	-1514(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    8000227c:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002280:	4789                	li	a5,2
    80002282:	cc9c                	sw	a5,24(s1)

  sched();
    80002284:	00000097          	auipc	ra,0x0
    80002288:	eb8080e7          	jalr	-328(ra) # 8000213c <sched>

  // Tidy up.
  p->chan = 0;
    8000228c:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002290:	8526                	mv	a0,s1
    80002292:	fffff097          	auipc	ra,0xfffff
    80002296:	9f8080e7          	jalr	-1544(ra) # 80000c8a <release>
  acquire(lk);
    8000229a:	854a                	mv	a0,s2
    8000229c:	fffff097          	auipc	ra,0xfffff
    800022a0:	93a080e7          	jalr	-1734(ra) # 80000bd6 <acquire>
}
    800022a4:	70a2                	ld	ra,40(sp)
    800022a6:	7402                	ld	s0,32(sp)
    800022a8:	64e2                	ld	s1,24(sp)
    800022aa:	6942                	ld	s2,16(sp)
    800022ac:	69a2                	ld	s3,8(sp)
    800022ae:	6145                	addi	sp,sp,48
    800022b0:	8082                	ret

00000000800022b2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800022b2:	7139                	addi	sp,sp,-64
    800022b4:	fc06                	sd	ra,56(sp)
    800022b6:	f822                	sd	s0,48(sp)
    800022b8:	f426                	sd	s1,40(sp)
    800022ba:	f04a                	sd	s2,32(sp)
    800022bc:	ec4e                	sd	s3,24(sp)
    800022be:	e852                	sd	s4,16(sp)
    800022c0:	e456                	sd	s5,8(sp)
    800022c2:	0080                	addi	s0,sp,64
    800022c4:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800022c6:	0000f497          	auipc	s1,0xf
    800022ca:	d9a48493          	addi	s1,s1,-614 # 80011060 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800022ce:	4989                	li	s3,2
        p->state = RUNNABLE;
    800022d0:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800022d2:	00029917          	auipc	s2,0x29
    800022d6:	f8e90913          	addi	s2,s2,-114 # 8002b260 <tickslock>
    800022da:	a811                	j	800022ee <wakeup+0x3c>
      }
      release(&p->lock);
    800022dc:	8526                	mv	a0,s1
    800022de:	fffff097          	auipc	ra,0xfffff
    800022e2:	9ac080e7          	jalr	-1620(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800022e6:	68848493          	addi	s1,s1,1672
    800022ea:	03248663          	beq	s1,s2,80002316 <wakeup+0x64>
    if(p != myproc()){
    800022ee:	00000097          	auipc	ra,0x0
    800022f2:	810080e7          	jalr	-2032(ra) # 80001afe <myproc>
    800022f6:	fea488e3          	beq	s1,a0,800022e6 <wakeup+0x34>
      acquire(&p->lock);
    800022fa:	8526                	mv	a0,s1
    800022fc:	fffff097          	auipc	ra,0xfffff
    80002300:	8da080e7          	jalr	-1830(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002304:	4c9c                	lw	a5,24(s1)
    80002306:	fd379be3          	bne	a5,s3,800022dc <wakeup+0x2a>
    8000230a:	709c                	ld	a5,32(s1)
    8000230c:	fd4798e3          	bne	a5,s4,800022dc <wakeup+0x2a>
        p->state = RUNNABLE;
    80002310:	0154ac23          	sw	s5,24(s1)
    80002314:	b7e1                	j	800022dc <wakeup+0x2a>
    }
  }
}
    80002316:	70e2                	ld	ra,56(sp)
    80002318:	7442                	ld	s0,48(sp)
    8000231a:	74a2                	ld	s1,40(sp)
    8000231c:	7902                	ld	s2,32(sp)
    8000231e:	69e2                	ld	s3,24(sp)
    80002320:	6a42                	ld	s4,16(sp)
    80002322:	6aa2                	ld	s5,8(sp)
    80002324:	6121                	addi	sp,sp,64
    80002326:	8082                	ret

0000000080002328 <reparent>:
{
    80002328:	7179                	addi	sp,sp,-48
    8000232a:	f406                	sd	ra,40(sp)
    8000232c:	f022                	sd	s0,32(sp)
    8000232e:	ec26                	sd	s1,24(sp)
    80002330:	e84a                	sd	s2,16(sp)
    80002332:	e44e                	sd	s3,8(sp)
    80002334:	e052                	sd	s4,0(sp)
    80002336:	1800                	addi	s0,sp,48
    80002338:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000233a:	0000f497          	auipc	s1,0xf
    8000233e:	d2648493          	addi	s1,s1,-730 # 80011060 <proc>
      pp->parent = initproc;
    80002342:	00006a17          	auipc	s4,0x6
    80002346:	676a0a13          	addi	s4,s4,1654 # 800089b8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000234a:	00029997          	auipc	s3,0x29
    8000234e:	f1698993          	addi	s3,s3,-234 # 8002b260 <tickslock>
    80002352:	a029                	j	8000235c <reparent+0x34>
    80002354:	68848493          	addi	s1,s1,1672
    80002358:	01348d63          	beq	s1,s3,80002372 <reparent+0x4a>
    if(pp->parent == p){
    8000235c:	7c9c                	ld	a5,56(s1)
    8000235e:	ff279be3          	bne	a5,s2,80002354 <reparent+0x2c>
      pp->parent = initproc;
    80002362:	000a3503          	ld	a0,0(s4)
    80002366:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002368:	00000097          	auipc	ra,0x0
    8000236c:	f4a080e7          	jalr	-182(ra) # 800022b2 <wakeup>
    80002370:	b7d5                	j	80002354 <reparent+0x2c>
}
    80002372:	70a2                	ld	ra,40(sp)
    80002374:	7402                	ld	s0,32(sp)
    80002376:	64e2                	ld	s1,24(sp)
    80002378:	6942                	ld	s2,16(sp)
    8000237a:	69a2                	ld	s3,8(sp)
    8000237c:	6a02                	ld	s4,0(sp)
    8000237e:	6145                	addi	sp,sp,48
    80002380:	8082                	ret

0000000080002382 <exit>:
{
    80002382:	7179                	addi	sp,sp,-48
    80002384:	f406                	sd	ra,40(sp)
    80002386:	f022                	sd	s0,32(sp)
    80002388:	ec26                	sd	s1,24(sp)
    8000238a:	e84a                	sd	s2,16(sp)
    8000238c:	e44e                	sd	s3,8(sp)
    8000238e:	e052                	sd	s4,0(sp)
    80002390:	1800                	addi	s0,sp,48
    80002392:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002394:	fffff097          	auipc	ra,0xfffff
    80002398:	76a080e7          	jalr	1898(ra) # 80001afe <myproc>
    8000239c:	89aa                	mv	s3,a0
  if(p == initproc)
    8000239e:	00006797          	auipc	a5,0x6
    800023a2:	61a7b783          	ld	a5,1562(a5) # 800089b8 <initproc>
    800023a6:	0d050493          	addi	s1,a0,208
    800023aa:	15050913          	addi	s2,a0,336
    800023ae:	02a79363          	bne	a5,a0,800023d4 <exit+0x52>
    panic("init exiting");
    800023b2:	00006517          	auipc	a0,0x6
    800023b6:	eae50513          	addi	a0,a0,-338 # 80008260 <digits+0x220>
    800023ba:	ffffe097          	auipc	ra,0xffffe
    800023be:	184080e7          	jalr	388(ra) # 8000053e <panic>
      fileclose(f);
    800023c2:	00003097          	auipc	ra,0x3
    800023c6:	a38080e7          	jalr	-1480(ra) # 80004dfa <fileclose>
      p->ofile[fd] = 0;
    800023ca:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800023ce:	04a1                	addi	s1,s1,8
    800023d0:	01248563          	beq	s1,s2,800023da <exit+0x58>
    if(p->ofile[fd]){
    800023d4:	6088                	ld	a0,0(s1)
    800023d6:	f575                	bnez	a0,800023c2 <exit+0x40>
    800023d8:	bfdd                	j	800023ce <exit+0x4c>
  if(p->pid>2){
    800023da:	0309a703          	lw	a4,48(s3)
    800023de:	4789                	li	a5,2
    800023e0:	08e7c163          	blt	a5,a4,80002462 <exit+0xe0>
  begin_op();
    800023e4:	00002097          	auipc	ra,0x2
    800023e8:	54a080e7          	jalr	1354(ra) # 8000492e <begin_op>
  iput(p->cwd);
    800023ec:	1509b503          	ld	a0,336(s3)
    800023f0:	00002097          	auipc	ra,0x2
    800023f4:	a24080e7          	jalr	-1500(ra) # 80003e14 <iput>
  end_op();
    800023f8:	00002097          	auipc	ra,0x2
    800023fc:	5b6080e7          	jalr	1462(ra) # 800049ae <end_op>
  p->cwd = 0;
    80002400:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002404:	0000f497          	auipc	s1,0xf
    80002408:	84448493          	addi	s1,s1,-1980 # 80010c48 <wait_lock>
    8000240c:	8526                	mv	a0,s1
    8000240e:	ffffe097          	auipc	ra,0xffffe
    80002412:	7c8080e7          	jalr	1992(ra) # 80000bd6 <acquire>
  reparent(p);
    80002416:	854e                	mv	a0,s3
    80002418:	00000097          	auipc	ra,0x0
    8000241c:	f10080e7          	jalr	-240(ra) # 80002328 <reparent>
  wakeup(p->parent);
    80002420:	0389b503          	ld	a0,56(s3)
    80002424:	00000097          	auipc	ra,0x0
    80002428:	e8e080e7          	jalr	-370(ra) # 800022b2 <wakeup>
  acquire(&p->lock);
    8000242c:	854e                	mv	a0,s3
    8000242e:	ffffe097          	auipc	ra,0xffffe
    80002432:	7a8080e7          	jalr	1960(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002436:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000243a:	4795                	li	a5,5
    8000243c:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002440:	8526                	mv	a0,s1
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	848080e7          	jalr	-1976(ra) # 80000c8a <release>
  sched();
    8000244a:	00000097          	auipc	ra,0x0
    8000244e:	cf2080e7          	jalr	-782(ra) # 8000213c <sched>
  panic("zombie exit");
    80002452:	00006517          	auipc	a0,0x6
    80002456:	e1e50513          	addi	a0,a0,-482 # 80008270 <digits+0x230>
    8000245a:	ffffe097          	auipc	ra,0xffffe
    8000245e:	0e4080e7          	jalr	228(ra) # 8000053e <panic>
    removeSwapFile(p);
    80002462:	854e                	mv	a0,s3
    80002464:	00002097          	auipc	ra,0x2
    80002468:	048080e7          	jalr	72(ra) # 800044ac <removeSwapFile>
    8000246c:	bfa5                	j	800023e4 <exit+0x62>

000000008000246e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000246e:	7179                	addi	sp,sp,-48
    80002470:	f406                	sd	ra,40(sp)
    80002472:	f022                	sd	s0,32(sp)
    80002474:	ec26                	sd	s1,24(sp)
    80002476:	e84a                	sd	s2,16(sp)
    80002478:	e44e                	sd	s3,8(sp)
    8000247a:	1800                	addi	s0,sp,48
    8000247c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000247e:	0000f497          	auipc	s1,0xf
    80002482:	be248493          	addi	s1,s1,-1054 # 80011060 <proc>
    80002486:	00029997          	auipc	s3,0x29
    8000248a:	dda98993          	addi	s3,s3,-550 # 8002b260 <tickslock>
    acquire(&p->lock);
    8000248e:	8526                	mv	a0,s1
    80002490:	ffffe097          	auipc	ra,0xffffe
    80002494:	746080e7          	jalr	1862(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    80002498:	589c                	lw	a5,48(s1)
    8000249a:	01278d63          	beq	a5,s2,800024b4 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000249e:	8526                	mv	a0,s1
    800024a0:	ffffe097          	auipc	ra,0xffffe
    800024a4:	7ea080e7          	jalr	2026(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800024a8:	68848493          	addi	s1,s1,1672
    800024ac:	ff3491e3          	bne	s1,s3,8000248e <kill+0x20>
  }
  return -1;
    800024b0:	557d                	li	a0,-1
    800024b2:	a829                	j	800024cc <kill+0x5e>
      p->killed = 1;
    800024b4:	4785                	li	a5,1
    800024b6:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800024b8:	4c98                	lw	a4,24(s1)
    800024ba:	4789                	li	a5,2
    800024bc:	00f70f63          	beq	a4,a5,800024da <kill+0x6c>
      release(&p->lock);
    800024c0:	8526                	mv	a0,s1
    800024c2:	ffffe097          	auipc	ra,0xffffe
    800024c6:	7c8080e7          	jalr	1992(ra) # 80000c8a <release>
      return 0;
    800024ca:	4501                	li	a0,0
}
    800024cc:	70a2                	ld	ra,40(sp)
    800024ce:	7402                	ld	s0,32(sp)
    800024d0:	64e2                	ld	s1,24(sp)
    800024d2:	6942                	ld	s2,16(sp)
    800024d4:	69a2                	ld	s3,8(sp)
    800024d6:	6145                	addi	sp,sp,48
    800024d8:	8082                	ret
        p->state = RUNNABLE;
    800024da:	478d                	li	a5,3
    800024dc:	cc9c                	sw	a5,24(s1)
    800024de:	b7cd                	j	800024c0 <kill+0x52>

00000000800024e0 <setkilled>:

void
setkilled(struct proc *p)
{
    800024e0:	1101                	addi	sp,sp,-32
    800024e2:	ec06                	sd	ra,24(sp)
    800024e4:	e822                	sd	s0,16(sp)
    800024e6:	e426                	sd	s1,8(sp)
    800024e8:	1000                	addi	s0,sp,32
    800024ea:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800024ec:	ffffe097          	auipc	ra,0xffffe
    800024f0:	6ea080e7          	jalr	1770(ra) # 80000bd6 <acquire>
  p->killed = 1;
    800024f4:	4785                	li	a5,1
    800024f6:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800024f8:	8526                	mv	a0,s1
    800024fa:	ffffe097          	auipc	ra,0xffffe
    800024fe:	790080e7          	jalr	1936(ra) # 80000c8a <release>
}
    80002502:	60e2                	ld	ra,24(sp)
    80002504:	6442                	ld	s0,16(sp)
    80002506:	64a2                	ld	s1,8(sp)
    80002508:	6105                	addi	sp,sp,32
    8000250a:	8082                	ret

000000008000250c <killed>:

int
killed(struct proc *p)
{
    8000250c:	1101                	addi	sp,sp,-32
    8000250e:	ec06                	sd	ra,24(sp)
    80002510:	e822                	sd	s0,16(sp)
    80002512:	e426                	sd	s1,8(sp)
    80002514:	e04a                	sd	s2,0(sp)
    80002516:	1000                	addi	s0,sp,32
    80002518:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    8000251a:	ffffe097          	auipc	ra,0xffffe
    8000251e:	6bc080e7          	jalr	1724(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002522:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002526:	8526                	mv	a0,s1
    80002528:	ffffe097          	auipc	ra,0xffffe
    8000252c:	762080e7          	jalr	1890(ra) # 80000c8a <release>
  return k;
}
    80002530:	854a                	mv	a0,s2
    80002532:	60e2                	ld	ra,24(sp)
    80002534:	6442                	ld	s0,16(sp)
    80002536:	64a2                	ld	s1,8(sp)
    80002538:	6902                	ld	s2,0(sp)
    8000253a:	6105                	addi	sp,sp,32
    8000253c:	8082                	ret

000000008000253e <wait>:
{
    8000253e:	715d                	addi	sp,sp,-80
    80002540:	e486                	sd	ra,72(sp)
    80002542:	e0a2                	sd	s0,64(sp)
    80002544:	fc26                	sd	s1,56(sp)
    80002546:	f84a                	sd	s2,48(sp)
    80002548:	f44e                	sd	s3,40(sp)
    8000254a:	f052                	sd	s4,32(sp)
    8000254c:	ec56                	sd	s5,24(sp)
    8000254e:	e85a                	sd	s6,16(sp)
    80002550:	e45e                	sd	s7,8(sp)
    80002552:	e062                	sd	s8,0(sp)
    80002554:	0880                	addi	s0,sp,80
    80002556:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002558:	fffff097          	auipc	ra,0xfffff
    8000255c:	5a6080e7          	jalr	1446(ra) # 80001afe <myproc>
    80002560:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002562:	0000e517          	auipc	a0,0xe
    80002566:	6e650513          	addi	a0,a0,1766 # 80010c48 <wait_lock>
    8000256a:	ffffe097          	auipc	ra,0xffffe
    8000256e:	66c080e7          	jalr	1644(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002572:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002574:	4a15                	li	s4,5
        havekids = 1;
    80002576:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002578:	00029997          	auipc	s3,0x29
    8000257c:	ce898993          	addi	s3,s3,-792 # 8002b260 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002580:	0000ec17          	auipc	s8,0xe
    80002584:	6c8c0c13          	addi	s8,s8,1736 # 80010c48 <wait_lock>
    havekids = 0;
    80002588:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000258a:	0000f497          	auipc	s1,0xf
    8000258e:	ad648493          	addi	s1,s1,-1322 # 80011060 <proc>
    80002592:	a0bd                	j	80002600 <wait+0xc2>
          pid = pp->pid;
    80002594:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002598:	000b0e63          	beqz	s6,800025b4 <wait+0x76>
    8000259c:	4691                	li	a3,4
    8000259e:	02c48613          	addi	a2,s1,44
    800025a2:	85da                	mv	a1,s6
    800025a4:	05093503          	ld	a0,80(s2)
    800025a8:	fffff097          	auipc	ra,0xfffff
    800025ac:	212080e7          	jalr	530(ra) # 800017ba <copyout>
    800025b0:	02054563          	bltz	a0,800025da <wait+0x9c>
          freeproc(pp);
    800025b4:	8526                	mv	a0,s1
    800025b6:	fffff097          	auipc	ra,0xfffff
    800025ba:	6fa080e7          	jalr	1786(ra) # 80001cb0 <freeproc>
          release(&pp->lock);
    800025be:	8526                	mv	a0,s1
    800025c0:	ffffe097          	auipc	ra,0xffffe
    800025c4:	6ca080e7          	jalr	1738(ra) # 80000c8a <release>
          release(&wait_lock);
    800025c8:	0000e517          	auipc	a0,0xe
    800025cc:	68050513          	addi	a0,a0,1664 # 80010c48 <wait_lock>
    800025d0:	ffffe097          	auipc	ra,0xffffe
    800025d4:	6ba080e7          	jalr	1722(ra) # 80000c8a <release>
          return pid;
    800025d8:	a0b5                	j	80002644 <wait+0x106>
            release(&pp->lock);
    800025da:	8526                	mv	a0,s1
    800025dc:	ffffe097          	auipc	ra,0xffffe
    800025e0:	6ae080e7          	jalr	1710(ra) # 80000c8a <release>
            release(&wait_lock);
    800025e4:	0000e517          	auipc	a0,0xe
    800025e8:	66450513          	addi	a0,a0,1636 # 80010c48 <wait_lock>
    800025ec:	ffffe097          	auipc	ra,0xffffe
    800025f0:	69e080e7          	jalr	1694(ra) # 80000c8a <release>
            return -1;
    800025f4:	59fd                	li	s3,-1
    800025f6:	a0b9                	j	80002644 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800025f8:	68848493          	addi	s1,s1,1672
    800025fc:	03348463          	beq	s1,s3,80002624 <wait+0xe6>
      if(pp->parent == p){
    80002600:	7c9c                	ld	a5,56(s1)
    80002602:	ff279be3          	bne	a5,s2,800025f8 <wait+0xba>
        acquire(&pp->lock);
    80002606:	8526                	mv	a0,s1
    80002608:	ffffe097          	auipc	ra,0xffffe
    8000260c:	5ce080e7          	jalr	1486(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    80002610:	4c9c                	lw	a5,24(s1)
    80002612:	f94781e3          	beq	a5,s4,80002594 <wait+0x56>
        release(&pp->lock);
    80002616:	8526                	mv	a0,s1
    80002618:	ffffe097          	auipc	ra,0xffffe
    8000261c:	672080e7          	jalr	1650(ra) # 80000c8a <release>
        havekids = 1;
    80002620:	8756                	mv	a4,s5
    80002622:	bfd9                	j	800025f8 <wait+0xba>
    if(!havekids || killed(p)){
    80002624:	c719                	beqz	a4,80002632 <wait+0xf4>
    80002626:	854a                	mv	a0,s2
    80002628:	00000097          	auipc	ra,0x0
    8000262c:	ee4080e7          	jalr	-284(ra) # 8000250c <killed>
    80002630:	c51d                	beqz	a0,8000265e <wait+0x120>
      release(&wait_lock);
    80002632:	0000e517          	auipc	a0,0xe
    80002636:	61650513          	addi	a0,a0,1558 # 80010c48 <wait_lock>
    8000263a:	ffffe097          	auipc	ra,0xffffe
    8000263e:	650080e7          	jalr	1616(ra) # 80000c8a <release>
      return -1;
    80002642:	59fd                	li	s3,-1
}
    80002644:	854e                	mv	a0,s3
    80002646:	60a6                	ld	ra,72(sp)
    80002648:	6406                	ld	s0,64(sp)
    8000264a:	74e2                	ld	s1,56(sp)
    8000264c:	7942                	ld	s2,48(sp)
    8000264e:	79a2                	ld	s3,40(sp)
    80002650:	7a02                	ld	s4,32(sp)
    80002652:	6ae2                	ld	s5,24(sp)
    80002654:	6b42                	ld	s6,16(sp)
    80002656:	6ba2                	ld	s7,8(sp)
    80002658:	6c02                	ld	s8,0(sp)
    8000265a:	6161                	addi	sp,sp,80
    8000265c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000265e:	85e2                	mv	a1,s8
    80002660:	854a                	mv	a0,s2
    80002662:	00000097          	auipc	ra,0x0
    80002666:	bec080e7          	jalr	-1044(ra) # 8000224e <sleep>
    havekids = 0;
    8000266a:	bf39                	j	80002588 <wait+0x4a>

000000008000266c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000266c:	7179                	addi	sp,sp,-48
    8000266e:	f406                	sd	ra,40(sp)
    80002670:	f022                	sd	s0,32(sp)
    80002672:	ec26                	sd	s1,24(sp)
    80002674:	e84a                	sd	s2,16(sp)
    80002676:	e44e                	sd	s3,8(sp)
    80002678:	e052                	sd	s4,0(sp)
    8000267a:	1800                	addi	s0,sp,48
    8000267c:	84aa                	mv	s1,a0
    8000267e:	892e                	mv	s2,a1
    80002680:	89b2                	mv	s3,a2
    80002682:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002684:	fffff097          	auipc	ra,0xfffff
    80002688:	47a080e7          	jalr	1146(ra) # 80001afe <myproc>
  if(user_dst){
    8000268c:	c08d                	beqz	s1,800026ae <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000268e:	86d2                	mv	a3,s4
    80002690:	864e                	mv	a2,s3
    80002692:	85ca                	mv	a1,s2
    80002694:	6928                	ld	a0,80(a0)
    80002696:	fffff097          	auipc	ra,0xfffff
    8000269a:	124080e7          	jalr	292(ra) # 800017ba <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000269e:	70a2                	ld	ra,40(sp)
    800026a0:	7402                	ld	s0,32(sp)
    800026a2:	64e2                	ld	s1,24(sp)
    800026a4:	6942                	ld	s2,16(sp)
    800026a6:	69a2                	ld	s3,8(sp)
    800026a8:	6a02                	ld	s4,0(sp)
    800026aa:	6145                	addi	sp,sp,48
    800026ac:	8082                	ret
    memmove((char *)dst, src, len);
    800026ae:	000a061b          	sext.w	a2,s4
    800026b2:	85ce                	mv	a1,s3
    800026b4:	854a                	mv	a0,s2
    800026b6:	ffffe097          	auipc	ra,0xffffe
    800026ba:	678080e7          	jalr	1656(ra) # 80000d2e <memmove>
    return 0;
    800026be:	8526                	mv	a0,s1
    800026c0:	bff9                	j	8000269e <either_copyout+0x32>

00000000800026c2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026c2:	7179                	addi	sp,sp,-48
    800026c4:	f406                	sd	ra,40(sp)
    800026c6:	f022                	sd	s0,32(sp)
    800026c8:	ec26                	sd	s1,24(sp)
    800026ca:	e84a                	sd	s2,16(sp)
    800026cc:	e44e                	sd	s3,8(sp)
    800026ce:	e052                	sd	s4,0(sp)
    800026d0:	1800                	addi	s0,sp,48
    800026d2:	892a                	mv	s2,a0
    800026d4:	84ae                	mv	s1,a1
    800026d6:	89b2                	mv	s3,a2
    800026d8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026da:	fffff097          	auipc	ra,0xfffff
    800026de:	424080e7          	jalr	1060(ra) # 80001afe <myproc>
  if(user_src){
    800026e2:	c08d                	beqz	s1,80002704 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800026e4:	86d2                	mv	a3,s4
    800026e6:	864e                	mv	a2,s3
    800026e8:	85ca                	mv	a1,s2
    800026ea:	6928                	ld	a0,80(a0)
    800026ec:	fffff097          	auipc	ra,0xfffff
    800026f0:	15a080e7          	jalr	346(ra) # 80001846 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800026f4:	70a2                	ld	ra,40(sp)
    800026f6:	7402                	ld	s0,32(sp)
    800026f8:	64e2                	ld	s1,24(sp)
    800026fa:	6942                	ld	s2,16(sp)
    800026fc:	69a2                	ld	s3,8(sp)
    800026fe:	6a02                	ld	s4,0(sp)
    80002700:	6145                	addi	sp,sp,48
    80002702:	8082                	ret
    memmove(dst, (char*)src, len);
    80002704:	000a061b          	sext.w	a2,s4
    80002708:	85ce                	mv	a1,s3
    8000270a:	854a                	mv	a0,s2
    8000270c:	ffffe097          	auipc	ra,0xffffe
    80002710:	622080e7          	jalr	1570(ra) # 80000d2e <memmove>
    return 0;
    80002714:	8526                	mv	a0,s1
    80002716:	bff9                	j	800026f4 <either_copyin+0x32>

0000000080002718 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002718:	715d                	addi	sp,sp,-80
    8000271a:	e486                	sd	ra,72(sp)
    8000271c:	e0a2                	sd	s0,64(sp)
    8000271e:	fc26                	sd	s1,56(sp)
    80002720:	f84a                	sd	s2,48(sp)
    80002722:	f44e                	sd	s3,40(sp)
    80002724:	f052                	sd	s4,32(sp)
    80002726:	ec56                	sd	s5,24(sp)
    80002728:	e85a                	sd	s6,16(sp)
    8000272a:	e45e                	sd	s7,8(sp)
    8000272c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000272e:	00006517          	auipc	a0,0x6
    80002732:	c6250513          	addi	a0,a0,-926 # 80008390 <states.0+0xa0>
    80002736:	ffffe097          	auipc	ra,0xffffe
    8000273a:	e52080e7          	jalr	-430(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000273e:	0000f497          	auipc	s1,0xf
    80002742:	a7a48493          	addi	s1,s1,-1414 # 800111b8 <proc+0x158>
    80002746:	00029917          	auipc	s2,0x29
    8000274a:	c7290913          	addi	s2,s2,-910 # 8002b3b8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000274e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002750:	00006997          	auipc	s3,0x6
    80002754:	b3098993          	addi	s3,s3,-1232 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002758:	00006a97          	auipc	s5,0x6
    8000275c:	b30a8a93          	addi	s5,s5,-1232 # 80008288 <digits+0x248>
    printf("\n");
    80002760:	00006a17          	auipc	s4,0x6
    80002764:	c30a0a13          	addi	s4,s4,-976 # 80008390 <states.0+0xa0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002768:	00006b97          	auipc	s7,0x6
    8000276c:	b88b8b93          	addi	s7,s7,-1144 # 800082f0 <states.0>
    80002770:	a00d                	j	80002792 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002772:	ed86a583          	lw	a1,-296(a3) # ed8 <_entry-0x7ffff128>
    80002776:	8556                	mv	a0,s5
    80002778:	ffffe097          	auipc	ra,0xffffe
    8000277c:	e10080e7          	jalr	-496(ra) # 80000588 <printf>
    printf("\n");
    80002780:	8552                	mv	a0,s4
    80002782:	ffffe097          	auipc	ra,0xffffe
    80002786:	e06080e7          	jalr	-506(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000278a:	68848493          	addi	s1,s1,1672
    8000278e:	03248163          	beq	s1,s2,800027b0 <procdump+0x98>
    if(p->state == UNUSED)
    80002792:	86a6                	mv	a3,s1
    80002794:	ec04a783          	lw	a5,-320(s1)
    80002798:	dbed                	beqz	a5,8000278a <procdump+0x72>
      state = "???";
    8000279a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000279c:	fcfb6be3          	bltu	s6,a5,80002772 <procdump+0x5a>
    800027a0:	1782                	slli	a5,a5,0x20
    800027a2:	9381                	srli	a5,a5,0x20
    800027a4:	078e                	slli	a5,a5,0x3
    800027a6:	97de                	add	a5,a5,s7
    800027a8:	6390                	ld	a2,0(a5)
    800027aa:	f661                	bnez	a2,80002772 <procdump+0x5a>
      state = "???";
    800027ac:	864e                	mv	a2,s3
    800027ae:	b7d1                	j	80002772 <procdump+0x5a>
  }
}
    800027b0:	60a6                	ld	ra,72(sp)
    800027b2:	6406                	ld	s0,64(sp)
    800027b4:	74e2                	ld	s1,56(sp)
    800027b6:	7942                	ld	s2,48(sp)
    800027b8:	79a2                	ld	s3,40(sp)
    800027ba:	7a02                	ld	s4,32(sp)
    800027bc:	6ae2                	ld	s5,24(sp)
    800027be:	6b42                	ld	s6,16(sp)
    800027c0:	6ba2                	ld	s7,8(sp)
    800027c2:	6161                	addi	sp,sp,80
    800027c4:	8082                	ret

00000000800027c6 <swapOutFromPysc>:


//ADDED 4.2
//swap out from pysc == swap in swap file
int 
swapOutFromPysc(pagetable_t pagetable,struct proc *p){
    800027c6:	7139                	addi	sp,sp,-64
    800027c8:	fc06                	sd	ra,56(sp)
    800027ca:	f822                	sd	s0,48(sp)
    800027cc:	f426                	sd	s1,40(sp)
    800027ce:	f04a                	sd	s2,32(sp)
    800027d0:	ec4e                	sd	s3,24(sp)
    800027d2:	e852                	sd	s4,16(sp)
    800027d4:	e456                	sd	s5,8(sp)
    800027d6:	0080                	addi	s0,sp,64
       if(p->physicalPagesCount+p->swapPagesCount==MAX_TOTAL_PAGES){
    800027d8:	2705b783          	ld	a5,624(a1)
    800027dc:	2785b703          	ld	a4,632(a1)
    800027e0:	97ba                	add	a5,a5,a4
    800027e2:	02000713          	li	a4,32
    800027e6:	02e78963          	beq	a5,a4,80002818 <swapOutFromPysc+0x52>
    800027ea:	89aa                	mv	s3,a0
    800027ec:	892e                	mv	s2,a1
      }
      //idx of page to removed from pysical memory 
      int idx = pageSwapPolicy(); //TODO
      struct metaData *removedPageFromPsyc = &p->pagesInPysical[idx];
      //looking for free struct into pagesInSwap to put the removed page
      for(struct metaData *page = p->pagesInSwap; page < &p->pagesInSwap[MAX_PSYC_PAGES]; page++){
    800027ee:	48058a13          	addi	s4,a1,1152
    800027f2:	68058713          	addi	a4,a1,1664
    800027f6:	84d2                	mv	s1,s4
        //empty space in the swapArr is found
        if(page->idxIsHere==0){
    800027f8:	649c                	ld	a5,8(s1)
    800027fa:	cb8d                	beqz	a5,8000282c <swapOutFromPysc+0x66>
      for(struct metaData *page = p->pagesInSwap; page < &p->pagesInSwap[MAX_PSYC_PAGES]; page++){
    800027fc:	02048493          	addi	s1,s1,32
    80002800:	fee49ce3          	bne	s1,a4,800027f8 <swapOutFromPysc+0x32>
          p->physicalPagesCount--;
          sfence_vma(); // flush to TLB
          break;
      }
    }
    return 0;
    80002804:	4501                	li	a0,0
  }
    80002806:	70e2                	ld	ra,56(sp)
    80002808:	7442                	ld	s0,48(sp)
    8000280a:	74a2                	ld	s1,40(sp)
    8000280c:	7902                	ld	s2,32(sp)
    8000280e:	69e2                	ld	s3,24(sp)
    80002810:	6a42                	ld	s4,16(sp)
    80002812:	6aa2                	ld	s5,8(sp)
    80002814:	6121                	addi	sp,sp,64
    80002816:	8082                	ret
        printf("exceeded number of possible pages\n");
    80002818:	00006517          	auipc	a0,0x6
    8000281c:	a8050513          	addi	a0,a0,-1408 # 80008298 <digits+0x258>
    80002820:	ffffe097          	auipc	ra,0xffffe
    80002824:	d68080e7          	jalr	-664(ra) # 80000588 <printf>
        return -1;
    80002828:	557d                	li	a0,-1
    8000282a:	bff1                	j	80002806 <swapOutFromPysc+0x40>
          page->idxIsHere = 1;
    8000282c:	4785                	li	a5,1
    8000282e:	e49c                	sd	a5,8(s1)
          page->va=removedPageFromPsyc->va;
    80002830:	2a093583          	ld	a1,672(s2)
    80002834:	e08c                	sd	a1,0(s1)
          uint64 pa = walkaddr(pagetable, page->va);
    80002836:	854e                	mv	a0,s3
    80002838:	fffff097          	auipc	ra,0xfffff
    8000283c:	8d8080e7          	jalr	-1832(ra) # 80001110 <walkaddr>
    80002840:	8aaa                	mv	s5,a0
          pte_t* entry = walk(pagetable, page->va, 0);
    80002842:	4601                	li	a2,0
    80002844:	608c                	ld	a1,0(s1)
    80002846:	854e                	mv	a0,s3
    80002848:	fffff097          	auipc	ra,0xfffff
    8000284c:	822080e7          	jalr	-2014(ra) # 8000106a <walk>
    80002850:	89aa                	mv	s3,a0
          if(writeToSwapFile(p,(char *)pa, (page-(p->pagesInSwap)) * PGSIZE, PGSIZE)< PGSIZE){
    80002852:	41448633          	sub	a2,s1,s4
    80002856:	6685                	lui	a3,0x1
    80002858:	0076161b          	slliw	a2,a2,0x7
    8000285c:	85d6                	mv	a1,s5
    8000285e:	854a                	mv	a0,s2
    80002860:	00002097          	auipc	ra,0x2
    80002864:	ea4080e7          	jalr	-348(ra) # 80004704 <writeToSwapFile>
    80002868:	6785                	lui	a5,0x1
    8000286a:	04f54063          	blt	a0,a5,800028aa <swapOutFromPysc+0xe4>
          p->swapPagesCount++;
    8000286e:	27893783          	ld	a5,632(s2)
    80002872:	0785                	addi	a5,a5,1
    80002874:	26f93c23          	sd	a5,632(s2)
          kfree((void *)pa);
    80002878:	8556                	mv	a0,s5
    8000287a:	ffffe097          	auipc	ra,0xffffe
    8000287e:	170080e7          	jalr	368(ra) # 800009ea <kfree>
          *entry = ~PTE_V & *entry;//not present in pte anymore 
    80002882:	0009b783          	ld	a5,0(s3)
    80002886:	9bf9                	andi	a5,a5,-2
    80002888:	2007e793          	ori	a5,a5,512
    8000288c:	00f9b023          	sd	a5,0(s3)
          removedPageFromPsyc->idxIsHere=0;
    80002890:	2a093423          	sd	zero,680(s2)
          removedPageFromPsyc->va=0;
    80002894:	2a093023          	sd	zero,672(s2)
          p->physicalPagesCount--;
    80002898:	27093783          	ld	a5,624(s2)
    8000289c:	17fd                	addi	a5,a5,-1
    8000289e:	26f93823          	sd	a5,624(s2)
  asm volatile("sfence.vma zero, zero");
    800028a2:	12000073          	sfence.vma
    return 0;
    800028a6:	4501                	li	a0,0
}
    800028a8:	bfb9                	j	80002806 <swapOutFromPysc+0x40>
            return -1;
    800028aa:	557d                	li	a0,-1
    800028ac:	bfa9                	j	80002806 <swapOutFromPysc+0x40>

00000000800028ae <pageSwapPolicy>:

  int 
  pageSwapPolicy(){
    800028ae:	1141                	addi	sp,sp,-16
    800028b0:	e422                	sd	s0,8(sp)
    800028b2:	0800                	addi	s0,sp,16

    #ifdef NONE
    return 1;
    #endif
    return 1;
  }
    800028b4:	4505                	li	a0,1
    800028b6:	6422                	ld	s0,8(sp)
    800028b8:	0141                	addi	sp,sp,16
    800028ba:	8082                	ret

00000000800028bc <nfua>:


int
nfua(){
    800028bc:	1141                	addi	sp,sp,-16
    800028be:	e406                	sd	ra,8(sp)
    800028c0:	e022                	sd	s0,0(sp)
    800028c2:	0800                	addi	s0,sp,16
struct proc *proc = myproc();
    800028c4:	fffff097          	auipc	ra,0xfffff
    800028c8:	23a080e7          	jalr	570(ra) # 80001afe <myproc>
    800028cc:	85aa                	mv	a1,a0
uint64 lowest =  __UINT64_MAX__;
int lowestIdx = 1;
struct metaData *page = proc->pagesInPysical+1;//start from the second idx  
    800028ce:	2a050793          	addi	a5,a0,672
while(page < &proc->pagesInPysical[MAX_PSYC_PAGES]){
    800028d2:	48050693          	addi	a3,a0,1152
int lowestIdx = 1;
    800028d6:	4505                	li	a0,1
uint64 lowest =  __UINT64_MAX__;
    800028d8:	567d                	li	a2,-1
  if(page->idxIsHere && page->aging < lowest){
    lowest = page->aging;
    lowestIdx= (int)(page-(proc->pagesInPysical));
    800028da:	28058593          	addi	a1,a1,640
    800028de:	a029                	j	800028e8 <nfua+0x2c>
  }
  page++;
    800028e0:	02078793          	addi	a5,a5,32 # 1020 <_entry-0x7fffefe0>
while(page < &proc->pagesInPysical[MAX_PSYC_PAGES]){
    800028e4:	00f68d63          	beq	a3,a5,800028fe <nfua+0x42>
  if(page->idxIsHere && page->aging < lowest){
    800028e8:	6798                	ld	a4,8(a5)
    800028ea:	db7d                	beqz	a4,800028e0 <nfua+0x24>
    800028ec:	6f98                	ld	a4,24(a5)
    800028ee:	fec779e3          	bgeu	a4,a2,800028e0 <nfua+0x24>
    lowestIdx= (int)(page-(proc->pagesInPysical));
    800028f2:	40b78533          	sub	a0,a5,a1
    800028f6:	8515                	srai	a0,a0,0x5
    800028f8:	2501                	sext.w	a0,a0
    lowest = page->aging;
    800028fa:	863a                	mv	a2,a4
    800028fc:	b7d5                	j	800028e0 <nfua+0x24>
}
return lowestIdx;
}
    800028fe:	60a2                	ld	ra,8(sp)
    80002900:	6402                	ld	s0,0(sp)
    80002902:	0141                	addi	sp,sp,16
    80002904:	8082                	ret

0000000080002906 <lafa>:

int
lafa(){
    80002906:	1141                	addi	sp,sp,-16
    80002908:	e406                	sd	ra,8(sp)
    8000290a:	e022                	sd	s0,0(sp)
    8000290c:	0800                	addi	s0,sp,16
  struct metaData *pg;
  int minOnes = 64;
  int minIdx = -1;
  struct proc *p=myproc();
    8000290e:	fffff097          	auipc	ra,0xfffff
    80002912:	1f0080e7          	jalr	496(ra) # 80001afe <myproc>

  for (pg = p->pagesInPysical; pg < &p->pagesInPysical[MAX_PSYC_PAGES]; pg++) {
    80002916:	28050e93          	addi	t4,a0,640
    8000291a:	48050893          	addi	a7,a0,1152
    8000291e:	8876                	mv	a6,t4
  int minIdx = -1;
    80002920:	557d                	li	a0,-1
  int minOnes = 64;
    80002922:	04000e13          	li	t3,64
    if (pg->idxIsHere) {
      int ones = 0;
      for (int i = 0; i < 64; i++) {
    80002926:	4301                	li	t1,0
    80002928:	04000593          	li	a1,64
        if ((pg->aging >> i) & 1) {
          ones++;
        }
      }
      if (ones < minOnes || (minIdx == -1 && ones <= minOnes)) {
    8000292c:	5f7d                	li	t5,-1
    8000292e:	a80d                	j	80002960 <lafa+0x5a>
      for (int i = 0; i < 64; i++) {
    80002930:	2785                	addiw	a5,a5,1
    80002932:	00b78863          	beq	a5,a1,80002942 <lafa+0x3c>
        if ((pg->aging >> i) & 1) {
    80002936:	00f65733          	srl	a4,a2,a5
    8000293a:	8b05                	andi	a4,a4,1
    8000293c:	db75                	beqz	a4,80002930 <lafa+0x2a>
          ones++;
    8000293e:	2685                	addiw	a3,a3,1
    80002940:	bfc5                	j	80002930 <lafa+0x2a>
      if (ones < minOnes || (minIdx == -1 && ones <= minOnes)) {
    80002942:	01c6c663          	blt	a3,t3,8000294e <lafa+0x48>
    80002946:	01e51963          	bne	a0,t5,80002958 <lafa+0x52>
    8000294a:	01c69763          	bne	a3,t3,80002958 <lafa+0x52>
        minOnes = ones;
        minIdx = (int)(pg - p->pagesInPysical);
    8000294e:	41d80533          	sub	a0,a6,t4
    80002952:	8515                	srai	a0,a0,0x5
    80002954:	2501                	sext.w	a0,a0
    80002956:	8e36                	mv	t3,a3
  for (pg = p->pagesInPysical; pg < &p->pagesInPysical[MAX_PSYC_PAGES]; pg++) {
    80002958:	02080813          	addi	a6,a6,32
    8000295c:	01180a63          	beq	a6,a7,80002970 <lafa+0x6a>
    if (pg->idxIsHere) {
    80002960:	00883783          	ld	a5,8(a6)
    80002964:	dbf5                	beqz	a5,80002958 <lafa+0x52>
        if ((pg->aging >> i) & 1) {
    80002966:	01883603          	ld	a2,24(a6)
      for (int i = 0; i < 64; i++) {
    8000296a:	879a                	mv	a5,t1
      int ones = 0;
    8000296c:	869a                	mv	a3,t1
    8000296e:	b7e1                	j	80002936 <lafa+0x30>
      }
    }
  }
  return minIdx;
}
    80002970:	60a2                	ld	ra,8(sp)
    80002972:	6402                	ld	s0,0(sp)
    80002974:	0141                	addi	sp,sp,16
    80002976:	8082                	ret

0000000080002978 <scfifo>:

int 
scfifo(){
    80002978:	1101                	addi	sp,sp,-32
    8000297a:	ec06                	sd	ra,24(sp)
    8000297c:	e822                	sd	s0,16(sp)
    8000297e:	e426                	sd	s1,8(sp)
    80002980:	e04a                	sd	s2,0(sp)
    80002982:	1000                	addi	s0,sp,32
    struct proc *p=myproc();
    80002984:	fffff097          	auipc	ra,0xfffff
    80002988:	17a080e7          	jalr	378(ra) # 80001afe <myproc>
    8000298c:	892a                	mv	s2,a0

  struct metaData *page=p->pagesInPysical;
    8000298e:	28050593          	addi	a1,a0,640
  uint64 lowestCreateTime = __UINT64_MAX__;
  int lowestCreateIdx = -1;

  while (page < &p->pagesInPysical[MAX_PSYC_PAGES]) {
    80002992:	48050693          	addi	a3,a0,1152
  struct metaData *page=p->pagesInPysical;
    80002996:	87ae                	mv	a5,a1
  int lowestCreateIdx = -1;
    80002998:	54fd                	li	s1,-1
  uint64 lowestCreateTime = __UINT64_MAX__;
    8000299a:	567d                	li	a2,-1
    8000299c:	a029                	j	800029a6 <scfifo+0x2e>
    if (page->idxIsHere && page->pageCreateTime <= lowestCreateTime) {
      lowestCreateIdx = (int)(page - p->pagesInPysical);
      lowestCreateTime = page->pageCreateTime;
    }
    page++;
    8000299e:	02078793          	addi	a5,a5,32
  while (page < &p->pagesInPysical[MAX_PSYC_PAGES]) {
    800029a2:	00f68e63          	beq	a3,a5,800029be <scfifo+0x46>
    if (page->idxIsHere && page->pageCreateTime <= lowestCreateTime) {
    800029a6:	6798                	ld	a4,8(a5)
    800029a8:	db7d                	beqz	a4,8000299e <scfifo+0x26>
    800029aa:	6b98                	ld	a4,16(a5)
    800029ac:	fee669e3          	bltu	a2,a4,8000299e <scfifo+0x26>
      lowestCreateIdx = (int)(page - p->pagesInPysical);
    800029b0:	40b78633          	sub	a2,a5,a1
    800029b4:	8615                	srai	a2,a2,0x5
    800029b6:	0006049b          	sext.w	s1,a2
      lowestCreateTime = page->pageCreateTime;
    800029ba:	863a                	mv	a2,a4
    800029bc:	b7cd                	j	8000299e <scfifo+0x26>
  }

  pte_t *pte = walk(p->pagetable, p->pagesInPysical[lowestCreateIdx].va, 0);
    800029be:	01448793          	addi	a5,s1,20
    800029c2:	0796                	slli	a5,a5,0x5
    800029c4:	97ca                	add	a5,a5,s2
    800029c6:	4601                	li	a2,0
    800029c8:	638c                	ld	a1,0(a5)
    800029ca:	05093503          	ld	a0,80(s2)
    800029ce:	ffffe097          	auipc	ra,0xffffe
    800029d2:	69c080e7          	jalr	1692(ra) # 8000106a <walk>
  if ((*pte & PTE_A) != 0) {
    800029d6:	611c                	ld	a5,0(a0)
    800029d8:	0407f713          	andi	a4,a5,64
    800029dc:	cf11                	beqz	a4,800029f8 <scfifo+0x80>
    *pte =*pte & ~PTE_A;
    800029de:	fbf7f793          	andi	a5,a5,-65
    800029e2:	e11c                	sd	a5,0(a0)
    p->helpPageTimer++;
    800029e4:	68093783          	ld	a5,1664(s2)
    800029e8:	0785                	addi	a5,a5,1
    800029ea:	68f93023          	sd	a5,1664(s2)
    p->pagesInPysical[lowestCreateIdx].pageCreateTime = p->helpPageTimer;
    800029ee:	00549713          	slli	a4,s1,0x5
    800029f2:	993a                	add	s2,s2,a4
    800029f4:	28f93823          	sd	a5,656(s2)
  }
  return lowestCreateIdx;
}
    800029f8:	8526                	mv	a0,s1
    800029fa:	60e2                	ld	ra,24(sp)
    800029fc:	6442                	ld	s0,16(sp)
    800029fe:	64a2                	ld	s1,8(sp)
    80002a00:	6902                	ld	s2,0(sp)
    80002a02:	6105                	addi	sp,sp,32
    80002a04:	8082                	ret

0000000080002a06 <agePage>:

void agePage() {
    80002a06:	7179                	addi	sp,sp,-48
    80002a08:	f406                	sd	ra,40(sp)
    80002a0a:	f022                	sd	s0,32(sp)
    80002a0c:	ec26                	sd	s1,24(sp)
    80002a0e:	e84a                	sd	s2,16(sp)
    80002a10:	e44e                	sd	s3,8(sp)
    80002a12:	e052                	sd	s4,0(sp)
    80002a14:	1800                	addi	s0,sp,48
  struct metaData *page;
  pte_t *entry;
  struct proc *p=myproc();
    80002a16:	fffff097          	auipc	ra,0xfffff
    80002a1a:	0e8080e7          	jalr	232(ra) # 80001afe <myproc>
    80002a1e:	89aa                	mv	s3,a0
  for (page = p->pagesInPysical; page < &p->pagesInPysical[MAX_PSYC_PAGES]; page++) {
    80002a20:	28050493          	addi	s1,a0,640
    80002a24:	48050913          	addi	s2,a0,1152
    if (page->idxIsHere) {
      entry = walk(p->pagetable, page->va, 0);
      if ((*entry & PTE_A) != 0) {
        page->aging = (page->aging >> 1) | (1ULL << 63);
    80002a28:	5a7d                	li	s4,-1
    80002a2a:	1a7e                	slli	s4,s4,0x3f
    80002a2c:	a821                	j	80002a44 <agePage+0x3e>
      } else {
        page->aging = (page->aging >> 1);
    80002a2e:	6c9c                	ld	a5,24(s1)
    80002a30:	8385                	srli	a5,a5,0x1
    80002a32:	ec9c                	sd	a5,24(s1)
      }
      *entry = *entry & ~PTE_A;
    80002a34:	611c                	ld	a5,0(a0)
    80002a36:	fbf7f793          	andi	a5,a5,-65
    80002a3a:	e11c                	sd	a5,0(a0)
  for (page = p->pagesInPysical; page < &p->pagesInPysical[MAX_PSYC_PAGES]; page++) {
    80002a3c:	02048493          	addi	s1,s1,32
    80002a40:	02990563          	beq	s2,s1,80002a6a <agePage+0x64>
    if (page->idxIsHere) {
    80002a44:	649c                	ld	a5,8(s1)
    80002a46:	dbfd                	beqz	a5,80002a3c <agePage+0x36>
      entry = walk(p->pagetable, page->va, 0);
    80002a48:	4601                	li	a2,0
    80002a4a:	608c                	ld	a1,0(s1)
    80002a4c:	0509b503          	ld	a0,80(s3)
    80002a50:	ffffe097          	auipc	ra,0xffffe
    80002a54:	61a080e7          	jalr	1562(ra) # 8000106a <walk>
      if ((*entry & PTE_A) != 0) {
    80002a58:	611c                	ld	a5,0(a0)
    80002a5a:	0407f793          	andi	a5,a5,64
    80002a5e:	dbe1                	beqz	a5,80002a2e <agePage+0x28>
        page->aging = (page->aging >> 1) | (1ULL << 63);
    80002a60:	6c9c                	ld	a5,24(s1)
    80002a62:	8385                	srli	a5,a5,0x1
    80002a64:	0147e7b3          	or	a5,a5,s4
    80002a68:	b7e9                	j	80002a32 <agePage+0x2c>
    }
  }
}
    80002a6a:	70a2                	ld	ra,40(sp)
    80002a6c:	7402                	ld	s0,32(sp)
    80002a6e:	64e2                	ld	s1,24(sp)
    80002a70:	6942                	ld	s2,16(sp)
    80002a72:	69a2                	ld	s3,8(sp)
    80002a74:	6a02                	ld	s4,0(sp)
    80002a76:	6145                	addi	sp,sp,48
    80002a78:	8082                	ret

0000000080002a7a <swtch>:
    80002a7a:	00153023          	sd	ra,0(a0)
    80002a7e:	00253423          	sd	sp,8(a0)
    80002a82:	e900                	sd	s0,16(a0)
    80002a84:	ed04                	sd	s1,24(a0)
    80002a86:	03253023          	sd	s2,32(a0)
    80002a8a:	03353423          	sd	s3,40(a0)
    80002a8e:	03453823          	sd	s4,48(a0)
    80002a92:	03553c23          	sd	s5,56(a0)
    80002a96:	05653023          	sd	s6,64(a0)
    80002a9a:	05753423          	sd	s7,72(a0)
    80002a9e:	05853823          	sd	s8,80(a0)
    80002aa2:	05953c23          	sd	s9,88(a0)
    80002aa6:	07a53023          	sd	s10,96(a0)
    80002aaa:	07b53423          	sd	s11,104(a0)
    80002aae:	0005b083          	ld	ra,0(a1)
    80002ab2:	0085b103          	ld	sp,8(a1)
    80002ab6:	6980                	ld	s0,16(a1)
    80002ab8:	6d84                	ld	s1,24(a1)
    80002aba:	0205b903          	ld	s2,32(a1)
    80002abe:	0285b983          	ld	s3,40(a1)
    80002ac2:	0305ba03          	ld	s4,48(a1)
    80002ac6:	0385ba83          	ld	s5,56(a1)
    80002aca:	0405bb03          	ld	s6,64(a1)
    80002ace:	0485bb83          	ld	s7,72(a1)
    80002ad2:	0505bc03          	ld	s8,80(a1)
    80002ad6:	0585bc83          	ld	s9,88(a1)
    80002ada:	0605bd03          	ld	s10,96(a1)
    80002ade:	0685bd83          	ld	s11,104(a1)
    80002ae2:	8082                	ret

0000000080002ae4 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002ae4:	1141                	addi	sp,sp,-16
    80002ae6:	e406                	sd	ra,8(sp)
    80002ae8:	e022                	sd	s0,0(sp)
    80002aea:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002aec:	00006597          	auipc	a1,0x6
    80002af0:	83458593          	addi	a1,a1,-1996 # 80008320 <states.0+0x30>
    80002af4:	00028517          	auipc	a0,0x28
    80002af8:	76c50513          	addi	a0,a0,1900 # 8002b260 <tickslock>
    80002afc:	ffffe097          	auipc	ra,0xffffe
    80002b00:	04a080e7          	jalr	74(ra) # 80000b46 <initlock>
}
    80002b04:	60a2                	ld	ra,8(sp)
    80002b06:	6402                	ld	s0,0(sp)
    80002b08:	0141                	addi	sp,sp,16
    80002b0a:	8082                	ret

0000000080002b0c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002b0c:	1141                	addi	sp,sp,-16
    80002b0e:	e422                	sd	s0,8(sp)
    80002b10:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b12:	00004797          	auipc	a5,0x4
    80002b16:	bae78793          	addi	a5,a5,-1106 # 800066c0 <kernelvec>
    80002b1a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002b1e:	6422                	ld	s0,8(sp)
    80002b20:	0141                	addi	sp,sp,16
    80002b22:	8082                	ret

0000000080002b24 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002b24:	1141                	addi	sp,sp,-16
    80002b26:	e406                	sd	ra,8(sp)
    80002b28:	e022                	sd	s0,0(sp)
    80002b2a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002b2c:	fffff097          	auipc	ra,0xfffff
    80002b30:	fd2080e7          	jalr	-46(ra) # 80001afe <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b34:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002b38:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b3a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002b3e:	00004617          	auipc	a2,0x4
    80002b42:	4c260613          	addi	a2,a2,1218 # 80007000 <_trampoline>
    80002b46:	00004697          	auipc	a3,0x4
    80002b4a:	4ba68693          	addi	a3,a3,1210 # 80007000 <_trampoline>
    80002b4e:	8e91                	sub	a3,a3,a2
    80002b50:	040007b7          	lui	a5,0x4000
    80002b54:	17fd                	addi	a5,a5,-1
    80002b56:	07b2                	slli	a5,a5,0xc
    80002b58:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b5a:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002b5e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002b60:	180026f3          	csrr	a3,satp
    80002b64:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002b66:	6d38                	ld	a4,88(a0)
    80002b68:	6134                	ld	a3,64(a0)
    80002b6a:	6585                	lui	a1,0x1
    80002b6c:	96ae                	add	a3,a3,a1
    80002b6e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002b70:	6d38                	ld	a4,88(a0)
    80002b72:	00000697          	auipc	a3,0x0
    80002b76:	13068693          	addi	a3,a3,304 # 80002ca2 <usertrap>
    80002b7a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002b7c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002b7e:	8692                	mv	a3,tp
    80002b80:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b82:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002b86:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002b8a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b8e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002b92:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b94:	6f18                	ld	a4,24(a4)
    80002b96:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002b9a:	6928                	ld	a0,80(a0)
    80002b9c:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002b9e:	00004717          	auipc	a4,0x4
    80002ba2:	4fe70713          	addi	a4,a4,1278 # 8000709c <userret>
    80002ba6:	8f11                	sub	a4,a4,a2
    80002ba8:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002baa:	577d                	li	a4,-1
    80002bac:	177e                	slli	a4,a4,0x3f
    80002bae:	8d59                	or	a0,a0,a4
    80002bb0:	9782                	jalr	a5
}
    80002bb2:	60a2                	ld	ra,8(sp)
    80002bb4:	6402                	ld	s0,0(sp)
    80002bb6:	0141                	addi	sp,sp,16
    80002bb8:	8082                	ret

0000000080002bba <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002bba:	1101                	addi	sp,sp,-32
    80002bbc:	ec06                	sd	ra,24(sp)
    80002bbe:	e822                	sd	s0,16(sp)
    80002bc0:	e426                	sd	s1,8(sp)
    80002bc2:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002bc4:	00028497          	auipc	s1,0x28
    80002bc8:	69c48493          	addi	s1,s1,1692 # 8002b260 <tickslock>
    80002bcc:	8526                	mv	a0,s1
    80002bce:	ffffe097          	auipc	ra,0xffffe
    80002bd2:	008080e7          	jalr	8(ra) # 80000bd6 <acquire>
  ticks++;
    80002bd6:	00006517          	auipc	a0,0x6
    80002bda:	dea50513          	addi	a0,a0,-534 # 800089c0 <ticks>
    80002bde:	411c                	lw	a5,0(a0)
    80002be0:	2785                	addiw	a5,a5,1
    80002be2:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002be4:	fffff097          	auipc	ra,0xfffff
    80002be8:	6ce080e7          	jalr	1742(ra) # 800022b2 <wakeup>
  release(&tickslock);
    80002bec:	8526                	mv	a0,s1
    80002bee:	ffffe097          	auipc	ra,0xffffe
    80002bf2:	09c080e7          	jalr	156(ra) # 80000c8a <release>
}
    80002bf6:	60e2                	ld	ra,24(sp)
    80002bf8:	6442                	ld	s0,16(sp)
    80002bfa:	64a2                	ld	s1,8(sp)
    80002bfc:	6105                	addi	sp,sp,32
    80002bfe:	8082                	ret

0000000080002c00 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002c00:	1101                	addi	sp,sp,-32
    80002c02:	ec06                	sd	ra,24(sp)
    80002c04:	e822                	sd	s0,16(sp)
    80002c06:	e426                	sd	s1,8(sp)
    80002c08:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c0a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002c0e:	00074d63          	bltz	a4,80002c28 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002c12:	57fd                	li	a5,-1
    80002c14:	17fe                	slli	a5,a5,0x3f
    80002c16:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002c18:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002c1a:	06f70363          	beq	a4,a5,80002c80 <devintr+0x80>
  }
}
    80002c1e:	60e2                	ld	ra,24(sp)
    80002c20:	6442                	ld	s0,16(sp)
    80002c22:	64a2                	ld	s1,8(sp)
    80002c24:	6105                	addi	sp,sp,32
    80002c26:	8082                	ret
     (scause & 0xff) == 9){
    80002c28:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002c2c:	46a5                	li	a3,9
    80002c2e:	fed792e3          	bne	a5,a3,80002c12 <devintr+0x12>
    int irq = plic_claim();
    80002c32:	00004097          	auipc	ra,0x4
    80002c36:	b96080e7          	jalr	-1130(ra) # 800067c8 <plic_claim>
    80002c3a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002c3c:	47a9                	li	a5,10
    80002c3e:	02f50763          	beq	a0,a5,80002c6c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002c42:	4785                	li	a5,1
    80002c44:	02f50963          	beq	a0,a5,80002c76 <devintr+0x76>
    return 1;
    80002c48:	4505                	li	a0,1
    } else if(irq){
    80002c4a:	d8f1                	beqz	s1,80002c1e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002c4c:	85a6                	mv	a1,s1
    80002c4e:	00005517          	auipc	a0,0x5
    80002c52:	6da50513          	addi	a0,a0,1754 # 80008328 <states.0+0x38>
    80002c56:	ffffe097          	auipc	ra,0xffffe
    80002c5a:	932080e7          	jalr	-1742(ra) # 80000588 <printf>
      plic_complete(irq);
    80002c5e:	8526                	mv	a0,s1
    80002c60:	00004097          	auipc	ra,0x4
    80002c64:	b8c080e7          	jalr	-1140(ra) # 800067ec <plic_complete>
    return 1;
    80002c68:	4505                	li	a0,1
    80002c6a:	bf55                	j	80002c1e <devintr+0x1e>
      uartintr();
    80002c6c:	ffffe097          	auipc	ra,0xffffe
    80002c70:	d2e080e7          	jalr	-722(ra) # 8000099a <uartintr>
    80002c74:	b7ed                	j	80002c5e <devintr+0x5e>
      virtio_disk_intr();
    80002c76:	00004097          	auipc	ra,0x4
    80002c7a:	042080e7          	jalr	66(ra) # 80006cb8 <virtio_disk_intr>
    80002c7e:	b7c5                	j	80002c5e <devintr+0x5e>
    if(cpuid() == 0){
    80002c80:	fffff097          	auipc	ra,0xfffff
    80002c84:	e52080e7          	jalr	-430(ra) # 80001ad2 <cpuid>
    80002c88:	c901                	beqz	a0,80002c98 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002c8a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002c8e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002c90:	14479073          	csrw	sip,a5
    return 2;
    80002c94:	4509                	li	a0,2
    80002c96:	b761                	j	80002c1e <devintr+0x1e>
      clockintr();
    80002c98:	00000097          	auipc	ra,0x0
    80002c9c:	f22080e7          	jalr	-222(ra) # 80002bba <clockintr>
    80002ca0:	b7ed                	j	80002c8a <devintr+0x8a>

0000000080002ca2 <usertrap>:
{
    80002ca2:	7139                	addi	sp,sp,-64
    80002ca4:	fc06                	sd	ra,56(sp)
    80002ca6:	f822                	sd	s0,48(sp)
    80002ca8:	f426                	sd	s1,40(sp)
    80002caa:	f04a                	sd	s2,32(sp)
    80002cac:	ec4e                	sd	s3,24(sp)
    80002cae:	e852                	sd	s4,16(sp)
    80002cb0:	e456                	sd	s5,8(sp)
    80002cb2:	0080                	addi	s0,sp,64
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cb4:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002cb8:	1007f793          	andi	a5,a5,256
    80002cbc:	ebdd                	bnez	a5,80002d72 <usertrap+0xd0>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cbe:	00004797          	auipc	a5,0x4
    80002cc2:	a0278793          	addi	a5,a5,-1534 # 800066c0 <kernelvec>
    80002cc6:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002cca:	fffff097          	auipc	ra,0xfffff
    80002cce:	e34080e7          	jalr	-460(ra) # 80001afe <myproc>
    80002cd2:	892a                	mv	s2,a0
  p->trapframe->epc = r_sepc();
    80002cd4:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cd6:	14102773          	csrr	a4,sepc
    80002cda:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cdc:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002ce0:	47a1                	li	a5,8
    80002ce2:	0af70063          	beq	a4,a5,80002d82 <usertrap+0xe0>
    80002ce6:	14202773          	csrr	a4,scause
   } else if(r_scause() == 13 || r_scause() == 15){
    80002cea:	47b5                	li	a5,13
    80002cec:	00f70763          	beq	a4,a5,80002cfa <usertrap+0x58>
    80002cf0:	14202773          	csrr	a4,scause
    80002cf4:	47bd                	li	a5,15
    80002cf6:	1af71a63          	bne	a4,a5,80002eaa <usertrap+0x208>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cfa:	143024f3          	csrr	s1,stval
    if ((*(walk(p->pagetable, va, 0)) & PTE_PG) == 0){
    80002cfe:	4601                	li	a2,0
    80002d00:	85a6                	mv	a1,s1
    80002d02:	05093503          	ld	a0,80(s2)
    80002d06:	ffffe097          	auipc	ra,0xffffe
    80002d0a:	364080e7          	jalr	868(ra) # 8000106a <walk>
    80002d0e:	611c                	ld	a5,0(a0)
    80002d10:	2007f793          	andi	a5,a5,512
    80002d14:	c3d5                	beqz	a5,80002db8 <usertrap+0x116>
      if(p->physicalPagesCount ==MAX_PSYC_PAGES){
    80002d16:	27093703          	ld	a4,624(s2)
    80002d1a:	47c1                	li	a5,16
    80002d1c:	0cf70c63          	beq	a4,a5,80002df4 <usertrap+0x152>
      char *space= kalloc();
    80002d20:	ffffe097          	auipc	ra,0xffffe
    80002d24:	dc6080e7          	jalr	-570(ra) # 80000ae6 <kalloc>
    80002d28:	89aa                	mv	s3,a0
      uint64 newVa = PGROUNDDOWN(va);
    80002d2a:	75fd                	lui	a1,0xfffff
    80002d2c:	8de5                	and	a1,a1,s1
      for(struct metaData *page=p->pagesInSwap;page<&p->pagesInSwap[MAX_PSYC_PAGES];page++){
    80002d2e:	48090a93          	addi	s5,s2,1152
    80002d32:	68090713          	addi	a4,s2,1664
    80002d36:	84d6                	mv	s1,s5
        if(page->va==newVa){
    80002d38:	609c                	ld	a5,0(s1)
    80002d3a:	0cb78563          	beq	a5,a1,80002e04 <usertrap+0x162>
      for(struct metaData *page=p->pagesInSwap;page<&p->pagesInSwap[MAX_PSYC_PAGES];page++){
    80002d3e:	02048493          	addi	s1,s1,32
    80002d42:	fee49be3          	bne	s1,a4,80002d38 <usertrap+0x96>
  asm volatile("sfence.vma zero, zero");
    80002d46:	12000073          	sfence.vma
  if(killed(p))
    80002d4a:	854a                	mv	a0,s2
    80002d4c:	fffff097          	auipc	ra,0xfffff
    80002d50:	7c0080e7          	jalr	1984(ra) # 8000250c <killed>
    80002d54:	1a051663          	bnez	a0,80002f00 <usertrap+0x25e>
  usertrapret();
    80002d58:	00000097          	auipc	ra,0x0
    80002d5c:	dcc080e7          	jalr	-564(ra) # 80002b24 <usertrapret>
}
    80002d60:	70e2                	ld	ra,56(sp)
    80002d62:	7442                	ld	s0,48(sp)
    80002d64:	74a2                	ld	s1,40(sp)
    80002d66:	7902                	ld	s2,32(sp)
    80002d68:	69e2                	ld	s3,24(sp)
    80002d6a:	6a42                	ld	s4,16(sp)
    80002d6c:	6aa2                	ld	s5,8(sp)
    80002d6e:	6121                	addi	sp,sp,64
    80002d70:	8082                	ret
    panic("usertrap: not from user mode");
    80002d72:	00005517          	auipc	a0,0x5
    80002d76:	5d650513          	addi	a0,a0,1494 # 80008348 <states.0+0x58>
    80002d7a:	ffffd097          	auipc	ra,0xffffd
    80002d7e:	7c4080e7          	jalr	1988(ra) # 8000053e <panic>
    if(killed(p))
    80002d82:	fffff097          	auipc	ra,0xfffff
    80002d86:	78a080e7          	jalr	1930(ra) # 8000250c <killed>
    80002d8a:	e10d                	bnez	a0,80002dac <usertrap+0x10a>
    p->trapframe->epc += 4;
    80002d8c:	05893703          	ld	a4,88(s2)
    80002d90:	6f1c                	ld	a5,24(a4)
    80002d92:	0791                	addi	a5,a5,4
    80002d94:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d96:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002d9a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d9e:	10079073          	csrw	sstatus,a5
    syscall();
    80002da2:	00000097          	auipc	ra,0x0
    80002da6:	3c4080e7          	jalr	964(ra) # 80003166 <syscall>
    80002daa:	b745                	j	80002d4a <usertrap+0xa8>
      exit(-1);
    80002dac:	557d                	li	a0,-1
    80002dae:	fffff097          	auipc	ra,0xfffff
    80002db2:	5d4080e7          	jalr	1492(ra) # 80002382 <exit>
    80002db6:	bfd9                	j	80002d8c <usertrap+0xea>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002db8:	142025f3          	csrr	a1,scause
      printf("usertrap(): segmentation fault %p pid=%d\n", r_scause(), p->pid);
    80002dbc:	03092603          	lw	a2,48(s2)
    80002dc0:	00005517          	auipc	a0,0x5
    80002dc4:	5a850513          	addi	a0,a0,1448 # 80008368 <states.0+0x78>
    80002dc8:	ffffd097          	auipc	ra,0xffffd
    80002dcc:	7c0080e7          	jalr	1984(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dd0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002dd4:	14302673          	csrr	a2,stval
      printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002dd8:	00005517          	auipc	a0,0x5
    80002ddc:	5c050513          	addi	a0,a0,1472 # 80008398 <states.0+0xa8>
    80002de0:	ffffd097          	auipc	ra,0xffffd
    80002de4:	7a8080e7          	jalr	1960(ra) # 80000588 <printf>
      setkilled(p);
    80002de8:	854a                	mv	a0,s2
    80002dea:	fffff097          	auipc	ra,0xfffff
    80002dee:	6f6080e7          	jalr	1782(ra) # 800024e0 <setkilled>
    80002df2:	bfa1                	j	80002d4a <usertrap+0xa8>
        swapOutFromPysc(p->pagetable,p);
    80002df4:	85ca                	mv	a1,s2
    80002df6:	05093503          	ld	a0,80(s2)
    80002dfa:	00000097          	auipc	ra,0x0
    80002dfe:	9cc080e7          	jalr	-1588(ra) # 800027c6 <swapOutFromPysc>
    80002e02:	bf39                	j	80002d20 <usertrap+0x7e>
          pte_t *entry = walk(p->pagetable, newVa, 0);
    80002e04:	4601                	li	a2,0
    80002e06:	05093503          	ld	a0,80(s2)
    80002e0a:	ffffe097          	auipc	ra,0xffffe
    80002e0e:	260080e7          	jalr	608(ra) # 8000106a <walk>
    80002e12:	8a2a                	mv	s4,a0
             if (readFromSwapFile(p, space,(page-p->pagesInSwap)*PGSIZE, PGSIZE) < PGSIZE){
    80002e14:	41548633          	sub	a2,s1,s5
    80002e18:	6685                	lui	a3,0x1
    80002e1a:	0076161b          	slliw	a2,a2,0x7
    80002e1e:	85ce                	mv	a1,s3
    80002e20:	854a                	mv	a0,s2
    80002e22:	00002097          	auipc	ra,0x2
    80002e26:	906080e7          	jalr	-1786(ra) # 80004728 <readFromSwapFile>
    80002e2a:	6785                	lui	a5,0x1
    80002e2c:	06f54263          	blt	a0,a5,80002e90 <usertrap+0x1ee>
        for(freeP = p->pagesInPysical; freeP < &p->pagesInPysical[MAX_PSYC_PAGES]; freeP++ ){
    80002e30:	28090613          	addi	a2,s2,640
    80002e34:	48090693          	addi	a3,s2,1152
    80002e38:	87b2                	mv	a5,a2
          if(freeP->idxIsHere==0){
    80002e3a:	6798                	ld	a4,8(a5)
    80002e3c:	c33d                	beqz	a4,80002ea2 <usertrap+0x200>
        for(freeP = p->pagesInPysical; freeP < &p->pagesInPysical[MAX_PSYC_PAGES]; freeP++ ){
    80002e3e:	02078793          	addi	a5,a5,32 # 1020 <_entry-0x7fffefe0>
    80002e42:	fed79ce3          	bne	a5,a3,80002e3a <usertrap+0x198>
        int freeIdx=0; 
    80002e46:	4781                	li	a5,0
        freeP->idxIsHere=1;
    80002e48:	0796                	slli	a5,a5,0x5
    80002e4a:	97ca                	add	a5,a5,s2
    80002e4c:	4705                	li	a4,1
    80002e4e:	28e7b423          	sd	a4,648(a5)
        freeP->va=page->va;
    80002e52:	6098                	ld	a4,0(s1)
    80002e54:	28e7b023          	sd	a4,640(a5)
        p->physicalPagesCount++;//we update our counter as well 
    80002e58:	27093783          	ld	a5,624(s2)
    80002e5c:	0785                	addi	a5,a5,1
    80002e5e:	26f93823          	sd	a5,624(s2)
        p->swapPagesCount--;
    80002e62:	27893783          	ld	a5,632(s2)
    80002e66:	17fd                	addi	a5,a5,-1
    80002e68:	26f93c23          	sd	a5,632(s2)
        page->idxIsHere=0;
    80002e6c:	0004b423          	sd	zero,8(s1)
        page->va=0;
    80002e70:	0004b023          	sd	zero,0(s1)
        *entry= PA2PTE((uint64)space)|PTE_FLAGS(*entry);
    80002e74:	00c9d993          	srli	s3,s3,0xc
    80002e78:	09aa                	slli	s3,s3,0xa
    80002e7a:	000a3783          	ld	a5,0(s4)
    80002e7e:	1ff7f793          	andi	a5,a5,511
        *entry=*entry & ~PTE_PG;
    80002e82:	0137e9b3          	or	s3,a5,s3
        *entry=*entry | PTE_V;
    80002e86:	0019e993          	ori	s3,s3,1
    80002e8a:	013a3023          	sd	s3,0(s4)
        break;
    80002e8e:	bd65                	j	80002d46 <usertrap+0xa4>
              printf("error: readFromSwapFile less than PGSIZE chars in usertrap\
    80002e90:	00005517          	auipc	a0,0x5
    80002e94:	52850513          	addi	a0,a0,1320 # 800083b8 <states.0+0xc8>
    80002e98:	ffffd097          	auipc	ra,0xffffd
    80002e9c:	6f0080e7          	jalr	1776(ra) # 80000588 <printf>
    80002ea0:	bf41                	j	80002e30 <usertrap+0x18e>
            freeIdx=(int)(freeP-(p->pagesInPysical));
    80002ea2:	8f91                	sub	a5,a5,a2
    80002ea4:	8795                	srai	a5,a5,0x5
    80002ea6:	2781                	sext.w	a5,a5
            break;
    80002ea8:	b745                	j	80002e48 <usertrap+0x1a6>
  else if((which_dev = devintr()) != 0){
    80002eaa:	00000097          	auipc	ra,0x0
    80002eae:	d56080e7          	jalr	-682(ra) # 80002c00 <devintr>
    80002eb2:	84aa                	mv	s1,a0
    80002eb4:	c901                	beqz	a0,80002ec4 <usertrap+0x222>
  if(killed(p))
    80002eb6:	854a                	mv	a0,s2
    80002eb8:	fffff097          	auipc	ra,0xfffff
    80002ebc:	654080e7          	jalr	1620(ra) # 8000250c <killed>
    80002ec0:	c531                	beqz	a0,80002f0c <usertrap+0x26a>
    80002ec2:	a081                	j	80002f02 <usertrap+0x260>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ec4:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ec8:	03092603          	lw	a2,48(s2)
    80002ecc:	00005517          	auipc	a0,0x5
    80002ed0:	53c50513          	addi	a0,a0,1340 # 80008408 <states.0+0x118>
    80002ed4:	ffffd097          	auipc	ra,0xffffd
    80002ed8:	6b4080e7          	jalr	1716(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002edc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ee0:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ee4:	00005517          	auipc	a0,0x5
    80002ee8:	4b450513          	addi	a0,a0,1204 # 80008398 <states.0+0xa8>
    80002eec:	ffffd097          	auipc	ra,0xffffd
    80002ef0:	69c080e7          	jalr	1692(ra) # 80000588 <printf>
    setkilled(p);
    80002ef4:	854a                	mv	a0,s2
    80002ef6:	fffff097          	auipc	ra,0xfffff
    80002efa:	5ea080e7          	jalr	1514(ra) # 800024e0 <setkilled>
    80002efe:	b5b1                	j	80002d4a <usertrap+0xa8>
  if(killed(p))
    80002f00:	4481                	li	s1,0
    exit(-1);
    80002f02:	557d                	li	a0,-1
    80002f04:	fffff097          	auipc	ra,0xfffff
    80002f08:	47e080e7          	jalr	1150(ra) # 80002382 <exit>
  if(which_dev == 2)
    80002f0c:	4789                	li	a5,2
    80002f0e:	e4f495e3          	bne	s1,a5,80002d58 <usertrap+0xb6>
    yield();
    80002f12:	fffff097          	auipc	ra,0xfffff
    80002f16:	300080e7          	jalr	768(ra) # 80002212 <yield>
    80002f1a:	bd3d                	j	80002d58 <usertrap+0xb6>

0000000080002f1c <kerneltrap>:
{
    80002f1c:	7179                	addi	sp,sp,-48
    80002f1e:	f406                	sd	ra,40(sp)
    80002f20:	f022                	sd	s0,32(sp)
    80002f22:	ec26                	sd	s1,24(sp)
    80002f24:	e84a                	sd	s2,16(sp)
    80002f26:	e44e                	sd	s3,8(sp)
    80002f28:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f2a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f2e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f32:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002f36:	1004f793          	andi	a5,s1,256
    80002f3a:	cb85                	beqz	a5,80002f6a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f3c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002f40:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002f42:	ef85                	bnez	a5,80002f7a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002f44:	00000097          	auipc	ra,0x0
    80002f48:	cbc080e7          	jalr	-836(ra) # 80002c00 <devintr>
    80002f4c:	cd1d                	beqz	a0,80002f8a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f4e:	4789                	li	a5,2
    80002f50:	06f50a63          	beq	a0,a5,80002fc4 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f54:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f58:	10049073          	csrw	sstatus,s1
}
    80002f5c:	70a2                	ld	ra,40(sp)
    80002f5e:	7402                	ld	s0,32(sp)
    80002f60:	64e2                	ld	s1,24(sp)
    80002f62:	6942                	ld	s2,16(sp)
    80002f64:	69a2                	ld	s3,8(sp)
    80002f66:	6145                	addi	sp,sp,48
    80002f68:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002f6a:	00005517          	auipc	a0,0x5
    80002f6e:	4ce50513          	addi	a0,a0,1230 # 80008438 <states.0+0x148>
    80002f72:	ffffd097          	auipc	ra,0xffffd
    80002f76:	5cc080e7          	jalr	1484(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002f7a:	00005517          	auipc	a0,0x5
    80002f7e:	4e650513          	addi	a0,a0,1254 # 80008460 <states.0+0x170>
    80002f82:	ffffd097          	auipc	ra,0xffffd
    80002f86:	5bc080e7          	jalr	1468(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002f8a:	85ce                	mv	a1,s3
    80002f8c:	00005517          	auipc	a0,0x5
    80002f90:	4f450513          	addi	a0,a0,1268 # 80008480 <states.0+0x190>
    80002f94:	ffffd097          	auipc	ra,0xffffd
    80002f98:	5f4080e7          	jalr	1524(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f9c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002fa0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002fa4:	00005517          	auipc	a0,0x5
    80002fa8:	4ec50513          	addi	a0,a0,1260 # 80008490 <states.0+0x1a0>
    80002fac:	ffffd097          	auipc	ra,0xffffd
    80002fb0:	5dc080e7          	jalr	1500(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002fb4:	00005517          	auipc	a0,0x5
    80002fb8:	4f450513          	addi	a0,a0,1268 # 800084a8 <states.0+0x1b8>
    80002fbc:	ffffd097          	auipc	ra,0xffffd
    80002fc0:	582080e7          	jalr	1410(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002fc4:	fffff097          	auipc	ra,0xfffff
    80002fc8:	b3a080e7          	jalr	-1222(ra) # 80001afe <myproc>
    80002fcc:	d541                	beqz	a0,80002f54 <kerneltrap+0x38>
    80002fce:	fffff097          	auipc	ra,0xfffff
    80002fd2:	b30080e7          	jalr	-1232(ra) # 80001afe <myproc>
    80002fd6:	4d18                	lw	a4,24(a0)
    80002fd8:	4791                	li	a5,4
    80002fda:	f6f71de3          	bne	a4,a5,80002f54 <kerneltrap+0x38>
    yield();
    80002fde:	fffff097          	auipc	ra,0xfffff
    80002fe2:	234080e7          	jalr	564(ra) # 80002212 <yield>
    80002fe6:	b7bd                	j	80002f54 <kerneltrap+0x38>

0000000080002fe8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002fe8:	1101                	addi	sp,sp,-32
    80002fea:	ec06                	sd	ra,24(sp)
    80002fec:	e822                	sd	s0,16(sp)
    80002fee:	e426                	sd	s1,8(sp)
    80002ff0:	1000                	addi	s0,sp,32
    80002ff2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ff4:	fffff097          	auipc	ra,0xfffff
    80002ff8:	b0a080e7          	jalr	-1270(ra) # 80001afe <myproc>
  switch (n) {
    80002ffc:	4795                	li	a5,5
    80002ffe:	0497e163          	bltu	a5,s1,80003040 <argraw+0x58>
    80003002:	048a                	slli	s1,s1,0x2
    80003004:	00005717          	auipc	a4,0x5
    80003008:	4dc70713          	addi	a4,a4,1244 # 800084e0 <states.0+0x1f0>
    8000300c:	94ba                	add	s1,s1,a4
    8000300e:	409c                	lw	a5,0(s1)
    80003010:	97ba                	add	a5,a5,a4
    80003012:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003014:	6d3c                	ld	a5,88(a0)
    80003016:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003018:	60e2                	ld	ra,24(sp)
    8000301a:	6442                	ld	s0,16(sp)
    8000301c:	64a2                	ld	s1,8(sp)
    8000301e:	6105                	addi	sp,sp,32
    80003020:	8082                	ret
    return p->trapframe->a1;
    80003022:	6d3c                	ld	a5,88(a0)
    80003024:	7fa8                	ld	a0,120(a5)
    80003026:	bfcd                	j	80003018 <argraw+0x30>
    return p->trapframe->a2;
    80003028:	6d3c                	ld	a5,88(a0)
    8000302a:	63c8                	ld	a0,128(a5)
    8000302c:	b7f5                	j	80003018 <argraw+0x30>
    return p->trapframe->a3;
    8000302e:	6d3c                	ld	a5,88(a0)
    80003030:	67c8                	ld	a0,136(a5)
    80003032:	b7dd                	j	80003018 <argraw+0x30>
    return p->trapframe->a4;
    80003034:	6d3c                	ld	a5,88(a0)
    80003036:	6bc8                	ld	a0,144(a5)
    80003038:	b7c5                	j	80003018 <argraw+0x30>
    return p->trapframe->a5;
    8000303a:	6d3c                	ld	a5,88(a0)
    8000303c:	6fc8                	ld	a0,152(a5)
    8000303e:	bfe9                	j	80003018 <argraw+0x30>
  panic("argraw");
    80003040:	00005517          	auipc	a0,0x5
    80003044:	47850513          	addi	a0,a0,1144 # 800084b8 <states.0+0x1c8>
    80003048:	ffffd097          	auipc	ra,0xffffd
    8000304c:	4f6080e7          	jalr	1270(ra) # 8000053e <panic>

0000000080003050 <fetchaddr>:
{
    80003050:	1101                	addi	sp,sp,-32
    80003052:	ec06                	sd	ra,24(sp)
    80003054:	e822                	sd	s0,16(sp)
    80003056:	e426                	sd	s1,8(sp)
    80003058:	e04a                	sd	s2,0(sp)
    8000305a:	1000                	addi	s0,sp,32
    8000305c:	84aa                	mv	s1,a0
    8000305e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003060:	fffff097          	auipc	ra,0xfffff
    80003064:	a9e080e7          	jalr	-1378(ra) # 80001afe <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80003068:	653c                	ld	a5,72(a0)
    8000306a:	02f4f863          	bgeu	s1,a5,8000309a <fetchaddr+0x4a>
    8000306e:	00848713          	addi	a4,s1,8
    80003072:	02e7e663          	bltu	a5,a4,8000309e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003076:	46a1                	li	a3,8
    80003078:	8626                	mv	a2,s1
    8000307a:	85ca                	mv	a1,s2
    8000307c:	6928                	ld	a0,80(a0)
    8000307e:	ffffe097          	auipc	ra,0xffffe
    80003082:	7c8080e7          	jalr	1992(ra) # 80001846 <copyin>
    80003086:	00a03533          	snez	a0,a0
    8000308a:	40a00533          	neg	a0,a0
}
    8000308e:	60e2                	ld	ra,24(sp)
    80003090:	6442                	ld	s0,16(sp)
    80003092:	64a2                	ld	s1,8(sp)
    80003094:	6902                	ld	s2,0(sp)
    80003096:	6105                	addi	sp,sp,32
    80003098:	8082                	ret
    return -1;
    8000309a:	557d                	li	a0,-1
    8000309c:	bfcd                	j	8000308e <fetchaddr+0x3e>
    8000309e:	557d                	li	a0,-1
    800030a0:	b7fd                	j	8000308e <fetchaddr+0x3e>

00000000800030a2 <fetchstr>:
{
    800030a2:	7179                	addi	sp,sp,-48
    800030a4:	f406                	sd	ra,40(sp)
    800030a6:	f022                	sd	s0,32(sp)
    800030a8:	ec26                	sd	s1,24(sp)
    800030aa:	e84a                	sd	s2,16(sp)
    800030ac:	e44e                	sd	s3,8(sp)
    800030ae:	1800                	addi	s0,sp,48
    800030b0:	892a                	mv	s2,a0
    800030b2:	84ae                	mv	s1,a1
    800030b4:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800030b6:	fffff097          	auipc	ra,0xfffff
    800030ba:	a48080e7          	jalr	-1464(ra) # 80001afe <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    800030be:	86ce                	mv	a3,s3
    800030c0:	864a                	mv	a2,s2
    800030c2:	85a6                	mv	a1,s1
    800030c4:	6928                	ld	a0,80(a0)
    800030c6:	fffff097          	auipc	ra,0xfffff
    800030ca:	80e080e7          	jalr	-2034(ra) # 800018d4 <copyinstr>
    800030ce:	00054e63          	bltz	a0,800030ea <fetchstr+0x48>
  return strlen(buf);
    800030d2:	8526                	mv	a0,s1
    800030d4:	ffffe097          	auipc	ra,0xffffe
    800030d8:	d7a080e7          	jalr	-646(ra) # 80000e4e <strlen>
}
    800030dc:	70a2                	ld	ra,40(sp)
    800030de:	7402                	ld	s0,32(sp)
    800030e0:	64e2                	ld	s1,24(sp)
    800030e2:	6942                	ld	s2,16(sp)
    800030e4:	69a2                	ld	s3,8(sp)
    800030e6:	6145                	addi	sp,sp,48
    800030e8:	8082                	ret
    return -1;
    800030ea:	557d                	li	a0,-1
    800030ec:	bfc5                	j	800030dc <fetchstr+0x3a>

00000000800030ee <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    800030ee:	1101                	addi	sp,sp,-32
    800030f0:	ec06                	sd	ra,24(sp)
    800030f2:	e822                	sd	s0,16(sp)
    800030f4:	e426                	sd	s1,8(sp)
    800030f6:	1000                	addi	s0,sp,32
    800030f8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030fa:	00000097          	auipc	ra,0x0
    800030fe:	eee080e7          	jalr	-274(ra) # 80002fe8 <argraw>
    80003102:	c088                	sw	a0,0(s1)
}
    80003104:	60e2                	ld	ra,24(sp)
    80003106:	6442                	ld	s0,16(sp)
    80003108:	64a2                	ld	s1,8(sp)
    8000310a:	6105                	addi	sp,sp,32
    8000310c:	8082                	ret

000000008000310e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    8000310e:	1101                	addi	sp,sp,-32
    80003110:	ec06                	sd	ra,24(sp)
    80003112:	e822                	sd	s0,16(sp)
    80003114:	e426                	sd	s1,8(sp)
    80003116:	1000                	addi	s0,sp,32
    80003118:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000311a:	00000097          	auipc	ra,0x0
    8000311e:	ece080e7          	jalr	-306(ra) # 80002fe8 <argraw>
    80003122:	e088                	sd	a0,0(s1)
}
    80003124:	60e2                	ld	ra,24(sp)
    80003126:	6442                	ld	s0,16(sp)
    80003128:	64a2                	ld	s1,8(sp)
    8000312a:	6105                	addi	sp,sp,32
    8000312c:	8082                	ret

000000008000312e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000312e:	7179                	addi	sp,sp,-48
    80003130:	f406                	sd	ra,40(sp)
    80003132:	f022                	sd	s0,32(sp)
    80003134:	ec26                	sd	s1,24(sp)
    80003136:	e84a                	sd	s2,16(sp)
    80003138:	1800                	addi	s0,sp,48
    8000313a:	84ae                	mv	s1,a1
    8000313c:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    8000313e:	fd840593          	addi	a1,s0,-40
    80003142:	00000097          	auipc	ra,0x0
    80003146:	fcc080e7          	jalr	-52(ra) # 8000310e <argaddr>
  return fetchstr(addr, buf, max);
    8000314a:	864a                	mv	a2,s2
    8000314c:	85a6                	mv	a1,s1
    8000314e:	fd843503          	ld	a0,-40(s0)
    80003152:	00000097          	auipc	ra,0x0
    80003156:	f50080e7          	jalr	-176(ra) # 800030a2 <fetchstr>
}
    8000315a:	70a2                	ld	ra,40(sp)
    8000315c:	7402                	ld	s0,32(sp)
    8000315e:	64e2                	ld	s1,24(sp)
    80003160:	6942                	ld	s2,16(sp)
    80003162:	6145                	addi	sp,sp,48
    80003164:	8082                	ret

0000000080003166 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80003166:	1101                	addi	sp,sp,-32
    80003168:	ec06                	sd	ra,24(sp)
    8000316a:	e822                	sd	s0,16(sp)
    8000316c:	e426                	sd	s1,8(sp)
    8000316e:	e04a                	sd	s2,0(sp)
    80003170:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003172:	fffff097          	auipc	ra,0xfffff
    80003176:	98c080e7          	jalr	-1652(ra) # 80001afe <myproc>
    8000317a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000317c:	05853903          	ld	s2,88(a0)
    80003180:	0a893783          	ld	a5,168(s2)
    80003184:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003188:	37fd                	addiw	a5,a5,-1
    8000318a:	4751                	li	a4,20
    8000318c:	00f76f63          	bltu	a4,a5,800031aa <syscall+0x44>
    80003190:	00369713          	slli	a4,a3,0x3
    80003194:	00005797          	auipc	a5,0x5
    80003198:	36478793          	addi	a5,a5,868 # 800084f8 <syscalls>
    8000319c:	97ba                	add	a5,a5,a4
    8000319e:	639c                	ld	a5,0(a5)
    800031a0:	c789                	beqz	a5,800031aa <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    800031a2:	9782                	jalr	a5
    800031a4:	06a93823          	sd	a0,112(s2)
    800031a8:	a839                	j	800031c6 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800031aa:	15848613          	addi	a2,s1,344
    800031ae:	588c                	lw	a1,48(s1)
    800031b0:	00005517          	auipc	a0,0x5
    800031b4:	31050513          	addi	a0,a0,784 # 800084c0 <states.0+0x1d0>
    800031b8:	ffffd097          	auipc	ra,0xffffd
    800031bc:	3d0080e7          	jalr	976(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800031c0:	6cbc                	ld	a5,88(s1)
    800031c2:	577d                	li	a4,-1
    800031c4:	fbb8                	sd	a4,112(a5)
  }
}
    800031c6:	60e2                	ld	ra,24(sp)
    800031c8:	6442                	ld	s0,16(sp)
    800031ca:	64a2                	ld	s1,8(sp)
    800031cc:	6902                	ld	s2,0(sp)
    800031ce:	6105                	addi	sp,sp,32
    800031d0:	8082                	ret

00000000800031d2 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800031d2:	1101                	addi	sp,sp,-32
    800031d4:	ec06                	sd	ra,24(sp)
    800031d6:	e822                	sd	s0,16(sp)
    800031d8:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    800031da:	fec40593          	addi	a1,s0,-20
    800031de:	4501                	li	a0,0
    800031e0:	00000097          	auipc	ra,0x0
    800031e4:	f0e080e7          	jalr	-242(ra) # 800030ee <argint>
  exit(n);
    800031e8:	fec42503          	lw	a0,-20(s0)
    800031ec:	fffff097          	auipc	ra,0xfffff
    800031f0:	196080e7          	jalr	406(ra) # 80002382 <exit>
  return 0;  // not reached
}
    800031f4:	4501                	li	a0,0
    800031f6:	60e2                	ld	ra,24(sp)
    800031f8:	6442                	ld	s0,16(sp)
    800031fa:	6105                	addi	sp,sp,32
    800031fc:	8082                	ret

00000000800031fe <sys_getpid>:

uint64
sys_getpid(void)
{
    800031fe:	1141                	addi	sp,sp,-16
    80003200:	e406                	sd	ra,8(sp)
    80003202:	e022                	sd	s0,0(sp)
    80003204:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003206:	fffff097          	auipc	ra,0xfffff
    8000320a:	8f8080e7          	jalr	-1800(ra) # 80001afe <myproc>
}
    8000320e:	5908                	lw	a0,48(a0)
    80003210:	60a2                	ld	ra,8(sp)
    80003212:	6402                	ld	s0,0(sp)
    80003214:	0141                	addi	sp,sp,16
    80003216:	8082                	ret

0000000080003218 <sys_fork>:

uint64
sys_fork(void)
{
    80003218:	1141                	addi	sp,sp,-16
    8000321a:	e406                	sd	ra,8(sp)
    8000321c:	e022                	sd	s0,0(sp)
    8000321e:	0800                	addi	s0,sp,16
  return fork();
    80003220:	fffff097          	auipc	ra,0xfffff
    80003224:	ca4080e7          	jalr	-860(ra) # 80001ec4 <fork>
}
    80003228:	60a2                	ld	ra,8(sp)
    8000322a:	6402                	ld	s0,0(sp)
    8000322c:	0141                	addi	sp,sp,16
    8000322e:	8082                	ret

0000000080003230 <sys_wait>:

uint64
sys_wait(void)
{
    80003230:	1101                	addi	sp,sp,-32
    80003232:	ec06                	sd	ra,24(sp)
    80003234:	e822                	sd	s0,16(sp)
    80003236:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003238:	fe840593          	addi	a1,s0,-24
    8000323c:	4501                	li	a0,0
    8000323e:	00000097          	auipc	ra,0x0
    80003242:	ed0080e7          	jalr	-304(ra) # 8000310e <argaddr>
  return wait(p);
    80003246:	fe843503          	ld	a0,-24(s0)
    8000324a:	fffff097          	auipc	ra,0xfffff
    8000324e:	2f4080e7          	jalr	756(ra) # 8000253e <wait>
}
    80003252:	60e2                	ld	ra,24(sp)
    80003254:	6442                	ld	s0,16(sp)
    80003256:	6105                	addi	sp,sp,32
    80003258:	8082                	ret

000000008000325a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000325a:	7179                	addi	sp,sp,-48
    8000325c:	f406                	sd	ra,40(sp)
    8000325e:	f022                	sd	s0,32(sp)
    80003260:	ec26                	sd	s1,24(sp)
    80003262:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003264:	fdc40593          	addi	a1,s0,-36
    80003268:	4501                	li	a0,0
    8000326a:	00000097          	auipc	ra,0x0
    8000326e:	e84080e7          	jalr	-380(ra) # 800030ee <argint>
  addr = myproc()->sz;
    80003272:	fffff097          	auipc	ra,0xfffff
    80003276:	88c080e7          	jalr	-1908(ra) # 80001afe <myproc>
    8000327a:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    8000327c:	fdc42503          	lw	a0,-36(s0)
    80003280:	fffff097          	auipc	ra,0xfffff
    80003284:	be8080e7          	jalr	-1048(ra) # 80001e68 <growproc>
    80003288:	00054863          	bltz	a0,80003298 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    8000328c:	8526                	mv	a0,s1
    8000328e:	70a2                	ld	ra,40(sp)
    80003290:	7402                	ld	s0,32(sp)
    80003292:	64e2                	ld	s1,24(sp)
    80003294:	6145                	addi	sp,sp,48
    80003296:	8082                	ret
    return -1;
    80003298:	54fd                	li	s1,-1
    8000329a:	bfcd                	j	8000328c <sys_sbrk+0x32>

000000008000329c <sys_sleep>:

uint64
sys_sleep(void)
{
    8000329c:	7139                	addi	sp,sp,-64
    8000329e:	fc06                	sd	ra,56(sp)
    800032a0:	f822                	sd	s0,48(sp)
    800032a2:	f426                	sd	s1,40(sp)
    800032a4:	f04a                	sd	s2,32(sp)
    800032a6:	ec4e                	sd	s3,24(sp)
    800032a8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800032aa:	fcc40593          	addi	a1,s0,-52
    800032ae:	4501                	li	a0,0
    800032b0:	00000097          	auipc	ra,0x0
    800032b4:	e3e080e7          	jalr	-450(ra) # 800030ee <argint>
  acquire(&tickslock);
    800032b8:	00028517          	auipc	a0,0x28
    800032bc:	fa850513          	addi	a0,a0,-88 # 8002b260 <tickslock>
    800032c0:	ffffe097          	auipc	ra,0xffffe
    800032c4:	916080e7          	jalr	-1770(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    800032c8:	00005917          	auipc	s2,0x5
    800032cc:	6f892903          	lw	s2,1784(s2) # 800089c0 <ticks>
  while(ticks - ticks0 < n){
    800032d0:	fcc42783          	lw	a5,-52(s0)
    800032d4:	cf9d                	beqz	a5,80003312 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800032d6:	00028997          	auipc	s3,0x28
    800032da:	f8a98993          	addi	s3,s3,-118 # 8002b260 <tickslock>
    800032de:	00005497          	auipc	s1,0x5
    800032e2:	6e248493          	addi	s1,s1,1762 # 800089c0 <ticks>
    if(killed(myproc())){
    800032e6:	fffff097          	auipc	ra,0xfffff
    800032ea:	818080e7          	jalr	-2024(ra) # 80001afe <myproc>
    800032ee:	fffff097          	auipc	ra,0xfffff
    800032f2:	21e080e7          	jalr	542(ra) # 8000250c <killed>
    800032f6:	ed15                	bnez	a0,80003332 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    800032f8:	85ce                	mv	a1,s3
    800032fa:	8526                	mv	a0,s1
    800032fc:	fffff097          	auipc	ra,0xfffff
    80003300:	f52080e7          	jalr	-174(ra) # 8000224e <sleep>
  while(ticks - ticks0 < n){
    80003304:	409c                	lw	a5,0(s1)
    80003306:	412787bb          	subw	a5,a5,s2
    8000330a:	fcc42703          	lw	a4,-52(s0)
    8000330e:	fce7ece3          	bltu	a5,a4,800032e6 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003312:	00028517          	auipc	a0,0x28
    80003316:	f4e50513          	addi	a0,a0,-178 # 8002b260 <tickslock>
    8000331a:	ffffe097          	auipc	ra,0xffffe
    8000331e:	970080e7          	jalr	-1680(ra) # 80000c8a <release>
  return 0;
    80003322:	4501                	li	a0,0
}
    80003324:	70e2                	ld	ra,56(sp)
    80003326:	7442                	ld	s0,48(sp)
    80003328:	74a2                	ld	s1,40(sp)
    8000332a:	7902                	ld	s2,32(sp)
    8000332c:	69e2                	ld	s3,24(sp)
    8000332e:	6121                	addi	sp,sp,64
    80003330:	8082                	ret
      release(&tickslock);
    80003332:	00028517          	auipc	a0,0x28
    80003336:	f2e50513          	addi	a0,a0,-210 # 8002b260 <tickslock>
    8000333a:	ffffe097          	auipc	ra,0xffffe
    8000333e:	950080e7          	jalr	-1712(ra) # 80000c8a <release>
      return -1;
    80003342:	557d                	li	a0,-1
    80003344:	b7c5                	j	80003324 <sys_sleep+0x88>

0000000080003346 <sys_kill>:

uint64
sys_kill(void)
{
    80003346:	1101                	addi	sp,sp,-32
    80003348:	ec06                	sd	ra,24(sp)
    8000334a:	e822                	sd	s0,16(sp)
    8000334c:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    8000334e:	fec40593          	addi	a1,s0,-20
    80003352:	4501                	li	a0,0
    80003354:	00000097          	auipc	ra,0x0
    80003358:	d9a080e7          	jalr	-614(ra) # 800030ee <argint>
  return kill(pid);
    8000335c:	fec42503          	lw	a0,-20(s0)
    80003360:	fffff097          	auipc	ra,0xfffff
    80003364:	10e080e7          	jalr	270(ra) # 8000246e <kill>
}
    80003368:	60e2                	ld	ra,24(sp)
    8000336a:	6442                	ld	s0,16(sp)
    8000336c:	6105                	addi	sp,sp,32
    8000336e:	8082                	ret

0000000080003370 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003370:	1101                	addi	sp,sp,-32
    80003372:	ec06                	sd	ra,24(sp)
    80003374:	e822                	sd	s0,16(sp)
    80003376:	e426                	sd	s1,8(sp)
    80003378:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000337a:	00028517          	auipc	a0,0x28
    8000337e:	ee650513          	addi	a0,a0,-282 # 8002b260 <tickslock>
    80003382:	ffffe097          	auipc	ra,0xffffe
    80003386:	854080e7          	jalr	-1964(ra) # 80000bd6 <acquire>
  xticks = ticks;
    8000338a:	00005497          	auipc	s1,0x5
    8000338e:	6364a483          	lw	s1,1590(s1) # 800089c0 <ticks>
  release(&tickslock);
    80003392:	00028517          	auipc	a0,0x28
    80003396:	ece50513          	addi	a0,a0,-306 # 8002b260 <tickslock>
    8000339a:	ffffe097          	auipc	ra,0xffffe
    8000339e:	8f0080e7          	jalr	-1808(ra) # 80000c8a <release>
  return xticks;
}
    800033a2:	02049513          	slli	a0,s1,0x20
    800033a6:	9101                	srli	a0,a0,0x20
    800033a8:	60e2                	ld	ra,24(sp)
    800033aa:	6442                	ld	s0,16(sp)
    800033ac:	64a2                	ld	s1,8(sp)
    800033ae:	6105                	addi	sp,sp,32
    800033b0:	8082                	ret

00000000800033b2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800033b2:	7179                	addi	sp,sp,-48
    800033b4:	f406                	sd	ra,40(sp)
    800033b6:	f022                	sd	s0,32(sp)
    800033b8:	ec26                	sd	s1,24(sp)
    800033ba:	e84a                	sd	s2,16(sp)
    800033bc:	e44e                	sd	s3,8(sp)
    800033be:	e052                	sd	s4,0(sp)
    800033c0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800033c2:	00005597          	auipc	a1,0x5
    800033c6:	1e658593          	addi	a1,a1,486 # 800085a8 <syscalls+0xb0>
    800033ca:	00028517          	auipc	a0,0x28
    800033ce:	eae50513          	addi	a0,a0,-338 # 8002b278 <bcache>
    800033d2:	ffffd097          	auipc	ra,0xffffd
    800033d6:	774080e7          	jalr	1908(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800033da:	00030797          	auipc	a5,0x30
    800033de:	e9e78793          	addi	a5,a5,-354 # 80033278 <bcache+0x8000>
    800033e2:	00030717          	auipc	a4,0x30
    800033e6:	0fe70713          	addi	a4,a4,254 # 800334e0 <bcache+0x8268>
    800033ea:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800033ee:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033f2:	00028497          	auipc	s1,0x28
    800033f6:	e9e48493          	addi	s1,s1,-354 # 8002b290 <bcache+0x18>
    b->next = bcache.head.next;
    800033fa:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800033fc:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800033fe:	00005a17          	auipc	s4,0x5
    80003402:	1b2a0a13          	addi	s4,s4,434 # 800085b0 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003406:	2b893783          	ld	a5,696(s2)
    8000340a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000340c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003410:	85d2                	mv	a1,s4
    80003412:	01048513          	addi	a0,s1,16
    80003416:	00001097          	auipc	ra,0x1
    8000341a:	7d6080e7          	jalr	2006(ra) # 80004bec <initsleeplock>
    bcache.head.next->prev = b;
    8000341e:	2b893783          	ld	a5,696(s2)
    80003422:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003424:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003428:	45848493          	addi	s1,s1,1112
    8000342c:	fd349de3          	bne	s1,s3,80003406 <binit+0x54>
  }
}
    80003430:	70a2                	ld	ra,40(sp)
    80003432:	7402                	ld	s0,32(sp)
    80003434:	64e2                	ld	s1,24(sp)
    80003436:	6942                	ld	s2,16(sp)
    80003438:	69a2                	ld	s3,8(sp)
    8000343a:	6a02                	ld	s4,0(sp)
    8000343c:	6145                	addi	sp,sp,48
    8000343e:	8082                	ret

0000000080003440 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003440:	7179                	addi	sp,sp,-48
    80003442:	f406                	sd	ra,40(sp)
    80003444:	f022                	sd	s0,32(sp)
    80003446:	ec26                	sd	s1,24(sp)
    80003448:	e84a                	sd	s2,16(sp)
    8000344a:	e44e                	sd	s3,8(sp)
    8000344c:	1800                	addi	s0,sp,48
    8000344e:	892a                	mv	s2,a0
    80003450:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003452:	00028517          	auipc	a0,0x28
    80003456:	e2650513          	addi	a0,a0,-474 # 8002b278 <bcache>
    8000345a:	ffffd097          	auipc	ra,0xffffd
    8000345e:	77c080e7          	jalr	1916(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003462:	00030497          	auipc	s1,0x30
    80003466:	0ce4b483          	ld	s1,206(s1) # 80033530 <bcache+0x82b8>
    8000346a:	00030797          	auipc	a5,0x30
    8000346e:	07678793          	addi	a5,a5,118 # 800334e0 <bcache+0x8268>
    80003472:	02f48f63          	beq	s1,a5,800034b0 <bread+0x70>
    80003476:	873e                	mv	a4,a5
    80003478:	a021                	j	80003480 <bread+0x40>
    8000347a:	68a4                	ld	s1,80(s1)
    8000347c:	02e48a63          	beq	s1,a4,800034b0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003480:	449c                	lw	a5,8(s1)
    80003482:	ff279ce3          	bne	a5,s2,8000347a <bread+0x3a>
    80003486:	44dc                	lw	a5,12(s1)
    80003488:	ff3799e3          	bne	a5,s3,8000347a <bread+0x3a>
      b->refcnt++;
    8000348c:	40bc                	lw	a5,64(s1)
    8000348e:	2785                	addiw	a5,a5,1
    80003490:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003492:	00028517          	auipc	a0,0x28
    80003496:	de650513          	addi	a0,a0,-538 # 8002b278 <bcache>
    8000349a:	ffffd097          	auipc	ra,0xffffd
    8000349e:	7f0080e7          	jalr	2032(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800034a2:	01048513          	addi	a0,s1,16
    800034a6:	00001097          	auipc	ra,0x1
    800034aa:	780080e7          	jalr	1920(ra) # 80004c26 <acquiresleep>
      return b;
    800034ae:	a8b9                	j	8000350c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034b0:	00030497          	auipc	s1,0x30
    800034b4:	0784b483          	ld	s1,120(s1) # 80033528 <bcache+0x82b0>
    800034b8:	00030797          	auipc	a5,0x30
    800034bc:	02878793          	addi	a5,a5,40 # 800334e0 <bcache+0x8268>
    800034c0:	00f48863          	beq	s1,a5,800034d0 <bread+0x90>
    800034c4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800034c6:	40bc                	lw	a5,64(s1)
    800034c8:	cf81                	beqz	a5,800034e0 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034ca:	64a4                	ld	s1,72(s1)
    800034cc:	fee49de3          	bne	s1,a4,800034c6 <bread+0x86>
  panic("bget: no buffers");
    800034d0:	00005517          	auipc	a0,0x5
    800034d4:	0e850513          	addi	a0,a0,232 # 800085b8 <syscalls+0xc0>
    800034d8:	ffffd097          	auipc	ra,0xffffd
    800034dc:	066080e7          	jalr	102(ra) # 8000053e <panic>
      b->dev = dev;
    800034e0:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800034e4:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800034e8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800034ec:	4785                	li	a5,1
    800034ee:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034f0:	00028517          	auipc	a0,0x28
    800034f4:	d8850513          	addi	a0,a0,-632 # 8002b278 <bcache>
    800034f8:	ffffd097          	auipc	ra,0xffffd
    800034fc:	792080e7          	jalr	1938(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003500:	01048513          	addi	a0,s1,16
    80003504:	00001097          	auipc	ra,0x1
    80003508:	722080e7          	jalr	1826(ra) # 80004c26 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000350c:	409c                	lw	a5,0(s1)
    8000350e:	cb89                	beqz	a5,80003520 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003510:	8526                	mv	a0,s1
    80003512:	70a2                	ld	ra,40(sp)
    80003514:	7402                	ld	s0,32(sp)
    80003516:	64e2                	ld	s1,24(sp)
    80003518:	6942                	ld	s2,16(sp)
    8000351a:	69a2                	ld	s3,8(sp)
    8000351c:	6145                	addi	sp,sp,48
    8000351e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003520:	4581                	li	a1,0
    80003522:	8526                	mv	a0,s1
    80003524:	00003097          	auipc	ra,0x3
    80003528:	560080e7          	jalr	1376(ra) # 80006a84 <virtio_disk_rw>
    b->valid = 1;
    8000352c:	4785                	li	a5,1
    8000352e:	c09c                	sw	a5,0(s1)
  return b;
    80003530:	b7c5                	j	80003510 <bread+0xd0>

0000000080003532 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003532:	1101                	addi	sp,sp,-32
    80003534:	ec06                	sd	ra,24(sp)
    80003536:	e822                	sd	s0,16(sp)
    80003538:	e426                	sd	s1,8(sp)
    8000353a:	1000                	addi	s0,sp,32
    8000353c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000353e:	0541                	addi	a0,a0,16
    80003540:	00001097          	auipc	ra,0x1
    80003544:	780080e7          	jalr	1920(ra) # 80004cc0 <holdingsleep>
    80003548:	cd01                	beqz	a0,80003560 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000354a:	4585                	li	a1,1
    8000354c:	8526                	mv	a0,s1
    8000354e:	00003097          	auipc	ra,0x3
    80003552:	536080e7          	jalr	1334(ra) # 80006a84 <virtio_disk_rw>
}
    80003556:	60e2                	ld	ra,24(sp)
    80003558:	6442                	ld	s0,16(sp)
    8000355a:	64a2                	ld	s1,8(sp)
    8000355c:	6105                	addi	sp,sp,32
    8000355e:	8082                	ret
    panic("bwrite");
    80003560:	00005517          	auipc	a0,0x5
    80003564:	07050513          	addi	a0,a0,112 # 800085d0 <syscalls+0xd8>
    80003568:	ffffd097          	auipc	ra,0xffffd
    8000356c:	fd6080e7          	jalr	-42(ra) # 8000053e <panic>

0000000080003570 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003570:	1101                	addi	sp,sp,-32
    80003572:	ec06                	sd	ra,24(sp)
    80003574:	e822                	sd	s0,16(sp)
    80003576:	e426                	sd	s1,8(sp)
    80003578:	e04a                	sd	s2,0(sp)
    8000357a:	1000                	addi	s0,sp,32
    8000357c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000357e:	01050913          	addi	s2,a0,16
    80003582:	854a                	mv	a0,s2
    80003584:	00001097          	auipc	ra,0x1
    80003588:	73c080e7          	jalr	1852(ra) # 80004cc0 <holdingsleep>
    8000358c:	c92d                	beqz	a0,800035fe <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000358e:	854a                	mv	a0,s2
    80003590:	00001097          	auipc	ra,0x1
    80003594:	6ec080e7          	jalr	1772(ra) # 80004c7c <releasesleep>

  acquire(&bcache.lock);
    80003598:	00028517          	auipc	a0,0x28
    8000359c:	ce050513          	addi	a0,a0,-800 # 8002b278 <bcache>
    800035a0:	ffffd097          	auipc	ra,0xffffd
    800035a4:	636080e7          	jalr	1590(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800035a8:	40bc                	lw	a5,64(s1)
    800035aa:	37fd                	addiw	a5,a5,-1
    800035ac:	0007871b          	sext.w	a4,a5
    800035b0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800035b2:	eb05                	bnez	a4,800035e2 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800035b4:	68bc                	ld	a5,80(s1)
    800035b6:	64b8                	ld	a4,72(s1)
    800035b8:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800035ba:	64bc                	ld	a5,72(s1)
    800035bc:	68b8                	ld	a4,80(s1)
    800035be:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800035c0:	00030797          	auipc	a5,0x30
    800035c4:	cb878793          	addi	a5,a5,-840 # 80033278 <bcache+0x8000>
    800035c8:	2b87b703          	ld	a4,696(a5)
    800035cc:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800035ce:	00030717          	auipc	a4,0x30
    800035d2:	f1270713          	addi	a4,a4,-238 # 800334e0 <bcache+0x8268>
    800035d6:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800035d8:	2b87b703          	ld	a4,696(a5)
    800035dc:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800035de:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800035e2:	00028517          	auipc	a0,0x28
    800035e6:	c9650513          	addi	a0,a0,-874 # 8002b278 <bcache>
    800035ea:	ffffd097          	auipc	ra,0xffffd
    800035ee:	6a0080e7          	jalr	1696(ra) # 80000c8a <release>
}
    800035f2:	60e2                	ld	ra,24(sp)
    800035f4:	6442                	ld	s0,16(sp)
    800035f6:	64a2                	ld	s1,8(sp)
    800035f8:	6902                	ld	s2,0(sp)
    800035fa:	6105                	addi	sp,sp,32
    800035fc:	8082                	ret
    panic("brelse");
    800035fe:	00005517          	auipc	a0,0x5
    80003602:	fda50513          	addi	a0,a0,-38 # 800085d8 <syscalls+0xe0>
    80003606:	ffffd097          	auipc	ra,0xffffd
    8000360a:	f38080e7          	jalr	-200(ra) # 8000053e <panic>

000000008000360e <bpin>:

void
bpin(struct buf *b) {
    8000360e:	1101                	addi	sp,sp,-32
    80003610:	ec06                	sd	ra,24(sp)
    80003612:	e822                	sd	s0,16(sp)
    80003614:	e426                	sd	s1,8(sp)
    80003616:	1000                	addi	s0,sp,32
    80003618:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000361a:	00028517          	auipc	a0,0x28
    8000361e:	c5e50513          	addi	a0,a0,-930 # 8002b278 <bcache>
    80003622:	ffffd097          	auipc	ra,0xffffd
    80003626:	5b4080e7          	jalr	1460(ra) # 80000bd6 <acquire>
  b->refcnt++;
    8000362a:	40bc                	lw	a5,64(s1)
    8000362c:	2785                	addiw	a5,a5,1
    8000362e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003630:	00028517          	auipc	a0,0x28
    80003634:	c4850513          	addi	a0,a0,-952 # 8002b278 <bcache>
    80003638:	ffffd097          	auipc	ra,0xffffd
    8000363c:	652080e7          	jalr	1618(ra) # 80000c8a <release>
}
    80003640:	60e2                	ld	ra,24(sp)
    80003642:	6442                	ld	s0,16(sp)
    80003644:	64a2                	ld	s1,8(sp)
    80003646:	6105                	addi	sp,sp,32
    80003648:	8082                	ret

000000008000364a <bunpin>:

void
bunpin(struct buf *b) {
    8000364a:	1101                	addi	sp,sp,-32
    8000364c:	ec06                	sd	ra,24(sp)
    8000364e:	e822                	sd	s0,16(sp)
    80003650:	e426                	sd	s1,8(sp)
    80003652:	1000                	addi	s0,sp,32
    80003654:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003656:	00028517          	auipc	a0,0x28
    8000365a:	c2250513          	addi	a0,a0,-990 # 8002b278 <bcache>
    8000365e:	ffffd097          	auipc	ra,0xffffd
    80003662:	578080e7          	jalr	1400(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003666:	40bc                	lw	a5,64(s1)
    80003668:	37fd                	addiw	a5,a5,-1
    8000366a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000366c:	00028517          	auipc	a0,0x28
    80003670:	c0c50513          	addi	a0,a0,-1012 # 8002b278 <bcache>
    80003674:	ffffd097          	auipc	ra,0xffffd
    80003678:	616080e7          	jalr	1558(ra) # 80000c8a <release>
}
    8000367c:	60e2                	ld	ra,24(sp)
    8000367e:	6442                	ld	s0,16(sp)
    80003680:	64a2                	ld	s1,8(sp)
    80003682:	6105                	addi	sp,sp,32
    80003684:	8082                	ret

0000000080003686 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003686:	1101                	addi	sp,sp,-32
    80003688:	ec06                	sd	ra,24(sp)
    8000368a:	e822                	sd	s0,16(sp)
    8000368c:	e426                	sd	s1,8(sp)
    8000368e:	e04a                	sd	s2,0(sp)
    80003690:	1000                	addi	s0,sp,32
    80003692:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003694:	00d5d59b          	srliw	a1,a1,0xd
    80003698:	00030797          	auipc	a5,0x30
    8000369c:	2bc7a783          	lw	a5,700(a5) # 80033954 <sb+0x1c>
    800036a0:	9dbd                	addw	a1,a1,a5
    800036a2:	00000097          	auipc	ra,0x0
    800036a6:	d9e080e7          	jalr	-610(ra) # 80003440 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800036aa:	0074f713          	andi	a4,s1,7
    800036ae:	4785                	li	a5,1
    800036b0:	00e797bb          	sllw	a5,a5,a4
  if ((bp->data[bi / 8] & m) == 0)
    800036b4:	14ce                	slli	s1,s1,0x33
    800036b6:	90d9                	srli	s1,s1,0x36
    800036b8:	00950733          	add	a4,a0,s1
    800036bc:	05874703          	lbu	a4,88(a4)
    800036c0:	00e7f6b3          	and	a3,a5,a4
    800036c4:	c69d                	beqz	a3,800036f2 <bfree+0x6c>
    800036c6:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi / 8] &= ~m;
    800036c8:	94aa                	add	s1,s1,a0
    800036ca:	fff7c793          	not	a5,a5
    800036ce:	8ff9                	and	a5,a5,a4
    800036d0:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800036d4:	00001097          	auipc	ra,0x1
    800036d8:	432080e7          	jalr	1074(ra) # 80004b06 <log_write>
  brelse(bp);
    800036dc:	854a                	mv	a0,s2
    800036de:	00000097          	auipc	ra,0x0
    800036e2:	e92080e7          	jalr	-366(ra) # 80003570 <brelse>
}
    800036e6:	60e2                	ld	ra,24(sp)
    800036e8:	6442                	ld	s0,16(sp)
    800036ea:	64a2                	ld	s1,8(sp)
    800036ec:	6902                	ld	s2,0(sp)
    800036ee:	6105                	addi	sp,sp,32
    800036f0:	8082                	ret
    panic("freeing free block");
    800036f2:	00005517          	auipc	a0,0x5
    800036f6:	eee50513          	addi	a0,a0,-274 # 800085e0 <syscalls+0xe8>
    800036fa:	ffffd097          	auipc	ra,0xffffd
    800036fe:	e44080e7          	jalr	-444(ra) # 8000053e <panic>

0000000080003702 <balloc>:
{
    80003702:	711d                	addi	sp,sp,-96
    80003704:	ec86                	sd	ra,88(sp)
    80003706:	e8a2                	sd	s0,80(sp)
    80003708:	e4a6                	sd	s1,72(sp)
    8000370a:	e0ca                	sd	s2,64(sp)
    8000370c:	fc4e                	sd	s3,56(sp)
    8000370e:	f852                	sd	s4,48(sp)
    80003710:	f456                	sd	s5,40(sp)
    80003712:	f05a                	sd	s6,32(sp)
    80003714:	ec5e                	sd	s7,24(sp)
    80003716:	e862                	sd	s8,16(sp)
    80003718:	e466                	sd	s9,8(sp)
    8000371a:	1080                	addi	s0,sp,96
  for (b = 0; b < sb.size; b += BPB)
    8000371c:	00030797          	auipc	a5,0x30
    80003720:	2207a783          	lw	a5,544(a5) # 8003393c <sb+0x4>
    80003724:	10078163          	beqz	a5,80003826 <balloc+0x124>
    80003728:	8baa                	mv	s7,a0
    8000372a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000372c:	00030b17          	auipc	s6,0x30
    80003730:	20cb0b13          	addi	s6,s6,524 # 80033938 <sb>
    for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    80003734:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003736:	4985                	li	s3,1
    for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    80003738:	6a09                	lui	s4,0x2
  for (b = 0; b < sb.size; b += BPB)
    8000373a:	6c89                	lui	s9,0x2
    8000373c:	a061                	j	800037c4 <balloc+0xc2>
        bp->data[bi / 8] |= m; // Mark block in use.
    8000373e:	974a                	add	a4,a4,s2
    80003740:	8fd5                	or	a5,a5,a3
    80003742:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003746:	854a                	mv	a0,s2
    80003748:	00001097          	auipc	ra,0x1
    8000374c:	3be080e7          	jalr	958(ra) # 80004b06 <log_write>
        brelse(bp);
    80003750:	854a                	mv	a0,s2
    80003752:	00000097          	auipc	ra,0x0
    80003756:	e1e080e7          	jalr	-482(ra) # 80003570 <brelse>
  bp = bread(dev, bno);
    8000375a:	85a6                	mv	a1,s1
    8000375c:	855e                	mv	a0,s7
    8000375e:	00000097          	auipc	ra,0x0
    80003762:	ce2080e7          	jalr	-798(ra) # 80003440 <bread>
    80003766:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003768:	40000613          	li	a2,1024
    8000376c:	4581                	li	a1,0
    8000376e:	05850513          	addi	a0,a0,88
    80003772:	ffffd097          	auipc	ra,0xffffd
    80003776:	560080e7          	jalr	1376(ra) # 80000cd2 <memset>
  log_write(bp);
    8000377a:	854a                	mv	a0,s2
    8000377c:	00001097          	auipc	ra,0x1
    80003780:	38a080e7          	jalr	906(ra) # 80004b06 <log_write>
  brelse(bp);
    80003784:	854a                	mv	a0,s2
    80003786:	00000097          	auipc	ra,0x0
    8000378a:	dea080e7          	jalr	-534(ra) # 80003570 <brelse>
}
    8000378e:	8526                	mv	a0,s1
    80003790:	60e6                	ld	ra,88(sp)
    80003792:	6446                	ld	s0,80(sp)
    80003794:	64a6                	ld	s1,72(sp)
    80003796:	6906                	ld	s2,64(sp)
    80003798:	79e2                	ld	s3,56(sp)
    8000379a:	7a42                	ld	s4,48(sp)
    8000379c:	7aa2                	ld	s5,40(sp)
    8000379e:	7b02                	ld	s6,32(sp)
    800037a0:	6be2                	ld	s7,24(sp)
    800037a2:	6c42                	ld	s8,16(sp)
    800037a4:	6ca2                	ld	s9,8(sp)
    800037a6:	6125                	addi	sp,sp,96
    800037a8:	8082                	ret
    brelse(bp);
    800037aa:	854a                	mv	a0,s2
    800037ac:	00000097          	auipc	ra,0x0
    800037b0:	dc4080e7          	jalr	-572(ra) # 80003570 <brelse>
  for (b = 0; b < sb.size; b += BPB)
    800037b4:	015c87bb          	addw	a5,s9,s5
    800037b8:	00078a9b          	sext.w	s5,a5
    800037bc:	004b2703          	lw	a4,4(s6)
    800037c0:	06eaf363          	bgeu	s5,a4,80003826 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800037c4:	41fad79b          	sraiw	a5,s5,0x1f
    800037c8:	0137d79b          	srliw	a5,a5,0x13
    800037cc:	015787bb          	addw	a5,a5,s5
    800037d0:	40d7d79b          	sraiw	a5,a5,0xd
    800037d4:	01cb2583          	lw	a1,28(s6)
    800037d8:	9dbd                	addw	a1,a1,a5
    800037da:	855e                	mv	a0,s7
    800037dc:	00000097          	auipc	ra,0x0
    800037e0:	c64080e7          	jalr	-924(ra) # 80003440 <bread>
    800037e4:	892a                	mv	s2,a0
    for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    800037e6:	004b2503          	lw	a0,4(s6)
    800037ea:	000a849b          	sext.w	s1,s5
    800037ee:	8662                	mv	a2,s8
    800037f0:	faa4fde3          	bgeu	s1,a0,800037aa <balloc+0xa8>
      m = 1 << (bi % 8);
    800037f4:	41f6579b          	sraiw	a5,a2,0x1f
    800037f8:	01d7d69b          	srliw	a3,a5,0x1d
    800037fc:	00c6873b          	addw	a4,a3,a2
    80003800:	00777793          	andi	a5,a4,7
    80003804:	9f95                	subw	a5,a5,a3
    80003806:	00f997bb          	sllw	a5,s3,a5
      if ((bp->data[bi / 8] & m) == 0)
    8000380a:	4037571b          	sraiw	a4,a4,0x3
    8000380e:	00e906b3          	add	a3,s2,a4
    80003812:	0586c683          	lbu	a3,88(a3) # 1058 <_entry-0x7fffefa8>
    80003816:	00d7f5b3          	and	a1,a5,a3
    8000381a:	d195                	beqz	a1,8000373e <balloc+0x3c>
    for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    8000381c:	2605                	addiw	a2,a2,1
    8000381e:	2485                	addiw	s1,s1,1
    80003820:	fd4618e3          	bne	a2,s4,800037f0 <balloc+0xee>
    80003824:	b759                	j	800037aa <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003826:	00005517          	auipc	a0,0x5
    8000382a:	dd250513          	addi	a0,a0,-558 # 800085f8 <syscalls+0x100>
    8000382e:	ffffd097          	auipc	ra,0xffffd
    80003832:	d5a080e7          	jalr	-678(ra) # 80000588 <printf>
  return 0;
    80003836:	4481                	li	s1,0
    80003838:	bf99                	j	8000378e <balloc+0x8c>

000000008000383a <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000383a:	7179                	addi	sp,sp,-48
    8000383c:	f406                	sd	ra,40(sp)
    8000383e:	f022                	sd	s0,32(sp)
    80003840:	ec26                	sd	s1,24(sp)
    80003842:	e84a                	sd	s2,16(sp)
    80003844:	e44e                	sd	s3,8(sp)
    80003846:	e052                	sd	s4,0(sp)
    80003848:	1800                	addi	s0,sp,48
    8000384a:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if (bn < NDIRECT)
    8000384c:	47ad                	li	a5,11
    8000384e:	02b7e763          	bltu	a5,a1,8000387c <bmap+0x42>
  {
    if ((addr = ip->addrs[bn]) == 0)
    80003852:	02059493          	slli	s1,a1,0x20
    80003856:	9081                	srli	s1,s1,0x20
    80003858:	048a                	slli	s1,s1,0x2
    8000385a:	94aa                	add	s1,s1,a0
    8000385c:	0504a903          	lw	s2,80(s1)
    80003860:	06091e63          	bnez	s2,800038dc <bmap+0xa2>
    {
      addr = balloc(ip->dev);
    80003864:	4108                	lw	a0,0(a0)
    80003866:	00000097          	auipc	ra,0x0
    8000386a:	e9c080e7          	jalr	-356(ra) # 80003702 <balloc>
    8000386e:	0005091b          	sext.w	s2,a0
      if (addr == 0)
    80003872:	06090563          	beqz	s2,800038dc <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003876:	0524a823          	sw	s2,80(s1)
    8000387a:	a08d                	j	800038dc <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000387c:	ff45849b          	addiw	s1,a1,-12
    80003880:	0004871b          	sext.w	a4,s1

  if (bn < NINDIRECT)
    80003884:	0ff00793          	li	a5,255
    80003888:	08e7e563          	bltu	a5,a4,80003912 <bmap+0xd8>
  {
    // Load indirect block, allocating if necessary.
    if ((addr = ip->addrs[NDIRECT]) == 0)
    8000388c:	08052903          	lw	s2,128(a0)
    80003890:	00091d63          	bnez	s2,800038aa <bmap+0x70>
    {
      addr = balloc(ip->dev);
    80003894:	4108                	lw	a0,0(a0)
    80003896:	00000097          	auipc	ra,0x0
    8000389a:	e6c080e7          	jalr	-404(ra) # 80003702 <balloc>
    8000389e:	0005091b          	sext.w	s2,a0
      if (addr == 0)
    800038a2:	02090d63          	beqz	s2,800038dc <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800038a6:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800038aa:	85ca                	mv	a1,s2
    800038ac:	0009a503          	lw	a0,0(s3)
    800038b0:	00000097          	auipc	ra,0x0
    800038b4:	b90080e7          	jalr	-1136(ra) # 80003440 <bread>
    800038b8:	8a2a                	mv	s4,a0
    a = (uint *)bp->data;
    800038ba:	05850793          	addi	a5,a0,88
    if ((addr = a[bn]) == 0)
    800038be:	02049593          	slli	a1,s1,0x20
    800038c2:	9181                	srli	a1,a1,0x20
    800038c4:	058a                	slli	a1,a1,0x2
    800038c6:	00b784b3          	add	s1,a5,a1
    800038ca:	0004a903          	lw	s2,0(s1)
    800038ce:	02090063          	beqz	s2,800038ee <bmap+0xb4>
      {
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800038d2:	8552                	mv	a0,s4
    800038d4:	00000097          	auipc	ra,0x0
    800038d8:	c9c080e7          	jalr	-868(ra) # 80003570 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800038dc:	854a                	mv	a0,s2
    800038de:	70a2                	ld	ra,40(sp)
    800038e0:	7402                	ld	s0,32(sp)
    800038e2:	64e2                	ld	s1,24(sp)
    800038e4:	6942                	ld	s2,16(sp)
    800038e6:	69a2                	ld	s3,8(sp)
    800038e8:	6a02                	ld	s4,0(sp)
    800038ea:	6145                	addi	sp,sp,48
    800038ec:	8082                	ret
      addr = balloc(ip->dev);
    800038ee:	0009a503          	lw	a0,0(s3)
    800038f2:	00000097          	auipc	ra,0x0
    800038f6:	e10080e7          	jalr	-496(ra) # 80003702 <balloc>
    800038fa:	0005091b          	sext.w	s2,a0
      if (addr)
    800038fe:	fc090ae3          	beqz	s2,800038d2 <bmap+0x98>
        a[bn] = addr;
    80003902:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003906:	8552                	mv	a0,s4
    80003908:	00001097          	auipc	ra,0x1
    8000390c:	1fe080e7          	jalr	510(ra) # 80004b06 <log_write>
    80003910:	b7c9                	j	800038d2 <bmap+0x98>
  panic("bmap: out of range");
    80003912:	00005517          	auipc	a0,0x5
    80003916:	cfe50513          	addi	a0,a0,-770 # 80008610 <syscalls+0x118>
    8000391a:	ffffd097          	auipc	ra,0xffffd
    8000391e:	c24080e7          	jalr	-988(ra) # 8000053e <panic>

0000000080003922 <iget>:
{
    80003922:	7179                	addi	sp,sp,-48
    80003924:	f406                	sd	ra,40(sp)
    80003926:	f022                	sd	s0,32(sp)
    80003928:	ec26                	sd	s1,24(sp)
    8000392a:	e84a                	sd	s2,16(sp)
    8000392c:	e44e                	sd	s3,8(sp)
    8000392e:	e052                	sd	s4,0(sp)
    80003930:	1800                	addi	s0,sp,48
    80003932:	89aa                	mv	s3,a0
    80003934:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003936:	00030517          	auipc	a0,0x30
    8000393a:	02250513          	addi	a0,a0,34 # 80033958 <itable>
    8000393e:	ffffd097          	auipc	ra,0xffffd
    80003942:	298080e7          	jalr	664(ra) # 80000bd6 <acquire>
  empty = 0;
    80003946:	4901                	li	s2,0
  for (ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++)
    80003948:	00030497          	auipc	s1,0x30
    8000394c:	02848493          	addi	s1,s1,40 # 80033970 <itable+0x18>
    80003950:	00032697          	auipc	a3,0x32
    80003954:	ab068693          	addi	a3,a3,-1360 # 80035400 <log>
    80003958:	a039                	j	80003966 <iget+0x44>
    if (empty == 0 && ip->ref == 0) // Remember empty slot.
    8000395a:	02090b63          	beqz	s2,80003990 <iget+0x6e>
  for (ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++)
    8000395e:	08848493          	addi	s1,s1,136
    80003962:	02d48a63          	beq	s1,a3,80003996 <iget+0x74>
    if (ip->ref > 0 && ip->dev == dev && ip->inum == inum)
    80003966:	449c                	lw	a5,8(s1)
    80003968:	fef059e3          	blez	a5,8000395a <iget+0x38>
    8000396c:	4098                	lw	a4,0(s1)
    8000396e:	ff3716e3          	bne	a4,s3,8000395a <iget+0x38>
    80003972:	40d8                	lw	a4,4(s1)
    80003974:	ff4713e3          	bne	a4,s4,8000395a <iget+0x38>
      ip->ref++;
    80003978:	2785                	addiw	a5,a5,1
    8000397a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000397c:	00030517          	auipc	a0,0x30
    80003980:	fdc50513          	addi	a0,a0,-36 # 80033958 <itable>
    80003984:	ffffd097          	auipc	ra,0xffffd
    80003988:	306080e7          	jalr	774(ra) # 80000c8a <release>
      return ip;
    8000398c:	8926                	mv	s2,s1
    8000398e:	a03d                	j	800039bc <iget+0x9a>
    if (empty == 0 && ip->ref == 0) // Remember empty slot.
    80003990:	f7f9                	bnez	a5,8000395e <iget+0x3c>
    80003992:	8926                	mv	s2,s1
    80003994:	b7e9                	j	8000395e <iget+0x3c>
  if (empty == 0)
    80003996:	02090c63          	beqz	s2,800039ce <iget+0xac>
  ip->dev = dev;
    8000399a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000399e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800039a2:	4785                	li	a5,1
    800039a4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800039a8:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800039ac:	00030517          	auipc	a0,0x30
    800039b0:	fac50513          	addi	a0,a0,-84 # 80033958 <itable>
    800039b4:	ffffd097          	auipc	ra,0xffffd
    800039b8:	2d6080e7          	jalr	726(ra) # 80000c8a <release>
}
    800039bc:	854a                	mv	a0,s2
    800039be:	70a2                	ld	ra,40(sp)
    800039c0:	7402                	ld	s0,32(sp)
    800039c2:	64e2                	ld	s1,24(sp)
    800039c4:	6942                	ld	s2,16(sp)
    800039c6:	69a2                	ld	s3,8(sp)
    800039c8:	6a02                	ld	s4,0(sp)
    800039ca:	6145                	addi	sp,sp,48
    800039cc:	8082                	ret
    panic("iget: no inodes");
    800039ce:	00005517          	auipc	a0,0x5
    800039d2:	c5a50513          	addi	a0,a0,-934 # 80008628 <syscalls+0x130>
    800039d6:	ffffd097          	auipc	ra,0xffffd
    800039da:	b68080e7          	jalr	-1176(ra) # 8000053e <panic>

00000000800039de <fsinit>:
{
    800039de:	7179                	addi	sp,sp,-48
    800039e0:	f406                	sd	ra,40(sp)
    800039e2:	f022                	sd	s0,32(sp)
    800039e4:	ec26                	sd	s1,24(sp)
    800039e6:	e84a                	sd	s2,16(sp)
    800039e8:	e44e                	sd	s3,8(sp)
    800039ea:	1800                	addi	s0,sp,48
    800039ec:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800039ee:	4585                	li	a1,1
    800039f0:	00000097          	auipc	ra,0x0
    800039f4:	a50080e7          	jalr	-1456(ra) # 80003440 <bread>
    800039f8:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800039fa:	00030997          	auipc	s3,0x30
    800039fe:	f3e98993          	addi	s3,s3,-194 # 80033938 <sb>
    80003a02:	02000613          	li	a2,32
    80003a06:	05850593          	addi	a1,a0,88
    80003a0a:	854e                	mv	a0,s3
    80003a0c:	ffffd097          	auipc	ra,0xffffd
    80003a10:	322080e7          	jalr	802(ra) # 80000d2e <memmove>
  brelse(bp);
    80003a14:	8526                	mv	a0,s1
    80003a16:	00000097          	auipc	ra,0x0
    80003a1a:	b5a080e7          	jalr	-1190(ra) # 80003570 <brelse>
  if (sb.magic != FSMAGIC)
    80003a1e:	0009a703          	lw	a4,0(s3)
    80003a22:	102037b7          	lui	a5,0x10203
    80003a26:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003a2a:	02f71263          	bne	a4,a5,80003a4e <fsinit+0x70>
  initlog(dev, &sb);
    80003a2e:	00030597          	auipc	a1,0x30
    80003a32:	f0a58593          	addi	a1,a1,-246 # 80033938 <sb>
    80003a36:	854a                	mv	a0,s2
    80003a38:	00001097          	auipc	ra,0x1
    80003a3c:	e52080e7          	jalr	-430(ra) # 8000488a <initlog>
}
    80003a40:	70a2                	ld	ra,40(sp)
    80003a42:	7402                	ld	s0,32(sp)
    80003a44:	64e2                	ld	s1,24(sp)
    80003a46:	6942                	ld	s2,16(sp)
    80003a48:	69a2                	ld	s3,8(sp)
    80003a4a:	6145                	addi	sp,sp,48
    80003a4c:	8082                	ret
    panic("invalid file system");
    80003a4e:	00005517          	auipc	a0,0x5
    80003a52:	bea50513          	addi	a0,a0,-1046 # 80008638 <syscalls+0x140>
    80003a56:	ffffd097          	auipc	ra,0xffffd
    80003a5a:	ae8080e7          	jalr	-1304(ra) # 8000053e <panic>

0000000080003a5e <iinit>:
{
    80003a5e:	7179                	addi	sp,sp,-48
    80003a60:	f406                	sd	ra,40(sp)
    80003a62:	f022                	sd	s0,32(sp)
    80003a64:	ec26                	sd	s1,24(sp)
    80003a66:	e84a                	sd	s2,16(sp)
    80003a68:	e44e                	sd	s3,8(sp)
    80003a6a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a6c:	00005597          	auipc	a1,0x5
    80003a70:	be458593          	addi	a1,a1,-1052 # 80008650 <syscalls+0x158>
    80003a74:	00030517          	auipc	a0,0x30
    80003a78:	ee450513          	addi	a0,a0,-284 # 80033958 <itable>
    80003a7c:	ffffd097          	auipc	ra,0xffffd
    80003a80:	0ca080e7          	jalr	202(ra) # 80000b46 <initlock>
  for (i = 0; i < NINODE; i++)
    80003a84:	00030497          	auipc	s1,0x30
    80003a88:	efc48493          	addi	s1,s1,-260 # 80033980 <itable+0x28>
    80003a8c:	00032997          	auipc	s3,0x32
    80003a90:	98498993          	addi	s3,s3,-1660 # 80035410 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a94:	00005917          	auipc	s2,0x5
    80003a98:	bc490913          	addi	s2,s2,-1084 # 80008658 <syscalls+0x160>
    80003a9c:	85ca                	mv	a1,s2
    80003a9e:	8526                	mv	a0,s1
    80003aa0:	00001097          	auipc	ra,0x1
    80003aa4:	14c080e7          	jalr	332(ra) # 80004bec <initsleeplock>
  for (i = 0; i < NINODE; i++)
    80003aa8:	08848493          	addi	s1,s1,136
    80003aac:	ff3498e3          	bne	s1,s3,80003a9c <iinit+0x3e>
}
    80003ab0:	70a2                	ld	ra,40(sp)
    80003ab2:	7402                	ld	s0,32(sp)
    80003ab4:	64e2                	ld	s1,24(sp)
    80003ab6:	6942                	ld	s2,16(sp)
    80003ab8:	69a2                	ld	s3,8(sp)
    80003aba:	6145                	addi	sp,sp,48
    80003abc:	8082                	ret

0000000080003abe <ialloc>:
{
    80003abe:	715d                	addi	sp,sp,-80
    80003ac0:	e486                	sd	ra,72(sp)
    80003ac2:	e0a2                	sd	s0,64(sp)
    80003ac4:	fc26                	sd	s1,56(sp)
    80003ac6:	f84a                	sd	s2,48(sp)
    80003ac8:	f44e                	sd	s3,40(sp)
    80003aca:	f052                	sd	s4,32(sp)
    80003acc:	ec56                	sd	s5,24(sp)
    80003ace:	e85a                	sd	s6,16(sp)
    80003ad0:	e45e                	sd	s7,8(sp)
    80003ad2:	0880                	addi	s0,sp,80
  for (inum = 1; inum < sb.ninodes; inum++)
    80003ad4:	00030717          	auipc	a4,0x30
    80003ad8:	e7072703          	lw	a4,-400(a4) # 80033944 <sb+0xc>
    80003adc:	4785                	li	a5,1
    80003ade:	04e7fa63          	bgeu	a5,a4,80003b32 <ialloc+0x74>
    80003ae2:	8aaa                	mv	s5,a0
    80003ae4:	8bae                	mv	s7,a1
    80003ae6:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003ae8:	00030a17          	auipc	s4,0x30
    80003aec:	e50a0a13          	addi	s4,s4,-432 # 80033938 <sb>
    80003af0:	00048b1b          	sext.w	s6,s1
    80003af4:	0044d793          	srli	a5,s1,0x4
    80003af8:	018a2583          	lw	a1,24(s4)
    80003afc:	9dbd                	addw	a1,a1,a5
    80003afe:	8556                	mv	a0,s5
    80003b00:	00000097          	auipc	ra,0x0
    80003b04:	940080e7          	jalr	-1728(ra) # 80003440 <bread>
    80003b08:	892a                	mv	s2,a0
    dip = (struct dinode *)bp->data + inum % IPB;
    80003b0a:	05850993          	addi	s3,a0,88
    80003b0e:	00f4f793          	andi	a5,s1,15
    80003b12:	079a                	slli	a5,a5,0x6
    80003b14:	99be                	add	s3,s3,a5
    if (dip->type == 0)
    80003b16:	00099783          	lh	a5,0(s3)
    80003b1a:	c3a1                	beqz	a5,80003b5a <ialloc+0x9c>
    brelse(bp);
    80003b1c:	00000097          	auipc	ra,0x0
    80003b20:	a54080e7          	jalr	-1452(ra) # 80003570 <brelse>
  for (inum = 1; inum < sb.ninodes; inum++)
    80003b24:	0485                	addi	s1,s1,1
    80003b26:	00ca2703          	lw	a4,12(s4)
    80003b2a:	0004879b          	sext.w	a5,s1
    80003b2e:	fce7e1e3          	bltu	a5,a4,80003af0 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003b32:	00005517          	auipc	a0,0x5
    80003b36:	b2e50513          	addi	a0,a0,-1234 # 80008660 <syscalls+0x168>
    80003b3a:	ffffd097          	auipc	ra,0xffffd
    80003b3e:	a4e080e7          	jalr	-1458(ra) # 80000588 <printf>
  return 0;
    80003b42:	4501                	li	a0,0
}
    80003b44:	60a6                	ld	ra,72(sp)
    80003b46:	6406                	ld	s0,64(sp)
    80003b48:	74e2                	ld	s1,56(sp)
    80003b4a:	7942                	ld	s2,48(sp)
    80003b4c:	79a2                	ld	s3,40(sp)
    80003b4e:	7a02                	ld	s4,32(sp)
    80003b50:	6ae2                	ld	s5,24(sp)
    80003b52:	6b42                	ld	s6,16(sp)
    80003b54:	6ba2                	ld	s7,8(sp)
    80003b56:	6161                	addi	sp,sp,80
    80003b58:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003b5a:	04000613          	li	a2,64
    80003b5e:	4581                	li	a1,0
    80003b60:	854e                	mv	a0,s3
    80003b62:	ffffd097          	auipc	ra,0xffffd
    80003b66:	170080e7          	jalr	368(ra) # 80000cd2 <memset>
      dip->type = type;
    80003b6a:	01799023          	sh	s7,0(s3)
      log_write(bp); // mark it allocated on the disk
    80003b6e:	854a                	mv	a0,s2
    80003b70:	00001097          	auipc	ra,0x1
    80003b74:	f96080e7          	jalr	-106(ra) # 80004b06 <log_write>
      brelse(bp);
    80003b78:	854a                	mv	a0,s2
    80003b7a:	00000097          	auipc	ra,0x0
    80003b7e:	9f6080e7          	jalr	-1546(ra) # 80003570 <brelse>
      return iget(dev, inum);
    80003b82:	85da                	mv	a1,s6
    80003b84:	8556                	mv	a0,s5
    80003b86:	00000097          	auipc	ra,0x0
    80003b8a:	d9c080e7          	jalr	-612(ra) # 80003922 <iget>
    80003b8e:	bf5d                	j	80003b44 <ialloc+0x86>

0000000080003b90 <iupdate>:
{
    80003b90:	1101                	addi	sp,sp,-32
    80003b92:	ec06                	sd	ra,24(sp)
    80003b94:	e822                	sd	s0,16(sp)
    80003b96:	e426                	sd	s1,8(sp)
    80003b98:	e04a                	sd	s2,0(sp)
    80003b9a:	1000                	addi	s0,sp,32
    80003b9c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b9e:	415c                	lw	a5,4(a0)
    80003ba0:	0047d79b          	srliw	a5,a5,0x4
    80003ba4:	00030597          	auipc	a1,0x30
    80003ba8:	dac5a583          	lw	a1,-596(a1) # 80033950 <sb+0x18>
    80003bac:	9dbd                	addw	a1,a1,a5
    80003bae:	4108                	lw	a0,0(a0)
    80003bb0:	00000097          	auipc	ra,0x0
    80003bb4:	890080e7          	jalr	-1904(ra) # 80003440 <bread>
    80003bb8:	892a                	mv	s2,a0
  dip = (struct dinode *)bp->data + ip->inum % IPB;
    80003bba:	05850793          	addi	a5,a0,88
    80003bbe:	40c8                	lw	a0,4(s1)
    80003bc0:	893d                	andi	a0,a0,15
    80003bc2:	051a                	slli	a0,a0,0x6
    80003bc4:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003bc6:	04449703          	lh	a4,68(s1)
    80003bca:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003bce:	04649703          	lh	a4,70(s1)
    80003bd2:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003bd6:	04849703          	lh	a4,72(s1)
    80003bda:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003bde:	04a49703          	lh	a4,74(s1)
    80003be2:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003be6:	44f8                	lw	a4,76(s1)
    80003be8:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003bea:	03400613          	li	a2,52
    80003bee:	05048593          	addi	a1,s1,80
    80003bf2:	0531                	addi	a0,a0,12
    80003bf4:	ffffd097          	auipc	ra,0xffffd
    80003bf8:	13a080e7          	jalr	314(ra) # 80000d2e <memmove>
  log_write(bp);
    80003bfc:	854a                	mv	a0,s2
    80003bfe:	00001097          	auipc	ra,0x1
    80003c02:	f08080e7          	jalr	-248(ra) # 80004b06 <log_write>
  brelse(bp);
    80003c06:	854a                	mv	a0,s2
    80003c08:	00000097          	auipc	ra,0x0
    80003c0c:	968080e7          	jalr	-1688(ra) # 80003570 <brelse>
}
    80003c10:	60e2                	ld	ra,24(sp)
    80003c12:	6442                	ld	s0,16(sp)
    80003c14:	64a2                	ld	s1,8(sp)
    80003c16:	6902                	ld	s2,0(sp)
    80003c18:	6105                	addi	sp,sp,32
    80003c1a:	8082                	ret

0000000080003c1c <idup>:
{
    80003c1c:	1101                	addi	sp,sp,-32
    80003c1e:	ec06                	sd	ra,24(sp)
    80003c20:	e822                	sd	s0,16(sp)
    80003c22:	e426                	sd	s1,8(sp)
    80003c24:	1000                	addi	s0,sp,32
    80003c26:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c28:	00030517          	auipc	a0,0x30
    80003c2c:	d3050513          	addi	a0,a0,-720 # 80033958 <itable>
    80003c30:	ffffd097          	auipc	ra,0xffffd
    80003c34:	fa6080e7          	jalr	-90(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003c38:	449c                	lw	a5,8(s1)
    80003c3a:	2785                	addiw	a5,a5,1
    80003c3c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c3e:	00030517          	auipc	a0,0x30
    80003c42:	d1a50513          	addi	a0,a0,-742 # 80033958 <itable>
    80003c46:	ffffd097          	auipc	ra,0xffffd
    80003c4a:	044080e7          	jalr	68(ra) # 80000c8a <release>
}
    80003c4e:	8526                	mv	a0,s1
    80003c50:	60e2                	ld	ra,24(sp)
    80003c52:	6442                	ld	s0,16(sp)
    80003c54:	64a2                	ld	s1,8(sp)
    80003c56:	6105                	addi	sp,sp,32
    80003c58:	8082                	ret

0000000080003c5a <ilock>:
{
    80003c5a:	1101                	addi	sp,sp,-32
    80003c5c:	ec06                	sd	ra,24(sp)
    80003c5e:	e822                	sd	s0,16(sp)
    80003c60:	e426                	sd	s1,8(sp)
    80003c62:	e04a                	sd	s2,0(sp)
    80003c64:	1000                	addi	s0,sp,32
  if (ip == 0 || ip->ref < 1)
    80003c66:	c115                	beqz	a0,80003c8a <ilock+0x30>
    80003c68:	84aa                	mv	s1,a0
    80003c6a:	451c                	lw	a5,8(a0)
    80003c6c:	00f05f63          	blez	a5,80003c8a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c70:	0541                	addi	a0,a0,16
    80003c72:	00001097          	auipc	ra,0x1
    80003c76:	fb4080e7          	jalr	-76(ra) # 80004c26 <acquiresleep>
  if (ip->valid == 0)
    80003c7a:	40bc                	lw	a5,64(s1)
    80003c7c:	cf99                	beqz	a5,80003c9a <ilock+0x40>
}
    80003c7e:	60e2                	ld	ra,24(sp)
    80003c80:	6442                	ld	s0,16(sp)
    80003c82:	64a2                	ld	s1,8(sp)
    80003c84:	6902                	ld	s2,0(sp)
    80003c86:	6105                	addi	sp,sp,32
    80003c88:	8082                	ret
    panic("ilock");
    80003c8a:	00005517          	auipc	a0,0x5
    80003c8e:	9ee50513          	addi	a0,a0,-1554 # 80008678 <syscalls+0x180>
    80003c92:	ffffd097          	auipc	ra,0xffffd
    80003c96:	8ac080e7          	jalr	-1876(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c9a:	40dc                	lw	a5,4(s1)
    80003c9c:	0047d79b          	srliw	a5,a5,0x4
    80003ca0:	00030597          	auipc	a1,0x30
    80003ca4:	cb05a583          	lw	a1,-848(a1) # 80033950 <sb+0x18>
    80003ca8:	9dbd                	addw	a1,a1,a5
    80003caa:	4088                	lw	a0,0(s1)
    80003cac:	fffff097          	auipc	ra,0xfffff
    80003cb0:	794080e7          	jalr	1940(ra) # 80003440 <bread>
    80003cb4:	892a                	mv	s2,a0
    dip = (struct dinode *)bp->data + ip->inum % IPB;
    80003cb6:	05850593          	addi	a1,a0,88
    80003cba:	40dc                	lw	a5,4(s1)
    80003cbc:	8bbd                	andi	a5,a5,15
    80003cbe:	079a                	slli	a5,a5,0x6
    80003cc0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003cc2:	00059783          	lh	a5,0(a1)
    80003cc6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003cca:	00259783          	lh	a5,2(a1)
    80003cce:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003cd2:	00459783          	lh	a5,4(a1)
    80003cd6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003cda:	00659783          	lh	a5,6(a1)
    80003cde:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003ce2:	459c                	lw	a5,8(a1)
    80003ce4:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003ce6:	03400613          	li	a2,52
    80003cea:	05b1                	addi	a1,a1,12
    80003cec:	05048513          	addi	a0,s1,80
    80003cf0:	ffffd097          	auipc	ra,0xffffd
    80003cf4:	03e080e7          	jalr	62(ra) # 80000d2e <memmove>
    brelse(bp);
    80003cf8:	854a                	mv	a0,s2
    80003cfa:	00000097          	auipc	ra,0x0
    80003cfe:	876080e7          	jalr	-1930(ra) # 80003570 <brelse>
    ip->valid = 1;
    80003d02:	4785                	li	a5,1
    80003d04:	c0bc                	sw	a5,64(s1)
    if (ip->type == 0)
    80003d06:	04449783          	lh	a5,68(s1)
    80003d0a:	fbb5                	bnez	a5,80003c7e <ilock+0x24>
      panic("ilock: no type");
    80003d0c:	00005517          	auipc	a0,0x5
    80003d10:	97450513          	addi	a0,a0,-1676 # 80008680 <syscalls+0x188>
    80003d14:	ffffd097          	auipc	ra,0xffffd
    80003d18:	82a080e7          	jalr	-2006(ra) # 8000053e <panic>

0000000080003d1c <iunlock>:
{
    80003d1c:	1101                	addi	sp,sp,-32
    80003d1e:	ec06                	sd	ra,24(sp)
    80003d20:	e822                	sd	s0,16(sp)
    80003d22:	e426                	sd	s1,8(sp)
    80003d24:	e04a                	sd	s2,0(sp)
    80003d26:	1000                	addi	s0,sp,32
  if (ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003d28:	c905                	beqz	a0,80003d58 <iunlock+0x3c>
    80003d2a:	84aa                	mv	s1,a0
    80003d2c:	01050913          	addi	s2,a0,16
    80003d30:	854a                	mv	a0,s2
    80003d32:	00001097          	auipc	ra,0x1
    80003d36:	f8e080e7          	jalr	-114(ra) # 80004cc0 <holdingsleep>
    80003d3a:	cd19                	beqz	a0,80003d58 <iunlock+0x3c>
    80003d3c:	449c                	lw	a5,8(s1)
    80003d3e:	00f05d63          	blez	a5,80003d58 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d42:	854a                	mv	a0,s2
    80003d44:	00001097          	auipc	ra,0x1
    80003d48:	f38080e7          	jalr	-200(ra) # 80004c7c <releasesleep>
}
    80003d4c:	60e2                	ld	ra,24(sp)
    80003d4e:	6442                	ld	s0,16(sp)
    80003d50:	64a2                	ld	s1,8(sp)
    80003d52:	6902                	ld	s2,0(sp)
    80003d54:	6105                	addi	sp,sp,32
    80003d56:	8082                	ret
    panic("iunlock");
    80003d58:	00005517          	auipc	a0,0x5
    80003d5c:	93850513          	addi	a0,a0,-1736 # 80008690 <syscalls+0x198>
    80003d60:	ffffc097          	auipc	ra,0xffffc
    80003d64:	7de080e7          	jalr	2014(ra) # 8000053e <panic>

0000000080003d68 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void itrunc(struct inode *ip)
{
    80003d68:	7179                	addi	sp,sp,-48
    80003d6a:	f406                	sd	ra,40(sp)
    80003d6c:	f022                	sd	s0,32(sp)
    80003d6e:	ec26                	sd	s1,24(sp)
    80003d70:	e84a                	sd	s2,16(sp)
    80003d72:	e44e                	sd	s3,8(sp)
    80003d74:	e052                	sd	s4,0(sp)
    80003d76:	1800                	addi	s0,sp,48
    80003d78:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for (i = 0; i < NDIRECT; i++)
    80003d7a:	05050493          	addi	s1,a0,80
    80003d7e:	08050913          	addi	s2,a0,128
    80003d82:	a021                	j	80003d8a <itrunc+0x22>
    80003d84:	0491                	addi	s1,s1,4
    80003d86:	01248d63          	beq	s1,s2,80003da0 <itrunc+0x38>
  {
    if (ip->addrs[i])
    80003d8a:	408c                	lw	a1,0(s1)
    80003d8c:	dde5                	beqz	a1,80003d84 <itrunc+0x1c>
    {
      bfree(ip->dev, ip->addrs[i]);
    80003d8e:	0009a503          	lw	a0,0(s3)
    80003d92:	00000097          	auipc	ra,0x0
    80003d96:	8f4080e7          	jalr	-1804(ra) # 80003686 <bfree>
      ip->addrs[i] = 0;
    80003d9a:	0004a023          	sw	zero,0(s1)
    80003d9e:	b7dd                	j	80003d84 <itrunc+0x1c>
    }
  }

  if (ip->addrs[NDIRECT])
    80003da0:	0809a583          	lw	a1,128(s3)
    80003da4:	e185                	bnez	a1,80003dc4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003da6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003daa:	854e                	mv	a0,s3
    80003dac:	00000097          	auipc	ra,0x0
    80003db0:	de4080e7          	jalr	-540(ra) # 80003b90 <iupdate>
}
    80003db4:	70a2                	ld	ra,40(sp)
    80003db6:	7402                	ld	s0,32(sp)
    80003db8:	64e2                	ld	s1,24(sp)
    80003dba:	6942                	ld	s2,16(sp)
    80003dbc:	69a2                	ld	s3,8(sp)
    80003dbe:	6a02                	ld	s4,0(sp)
    80003dc0:	6145                	addi	sp,sp,48
    80003dc2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003dc4:	0009a503          	lw	a0,0(s3)
    80003dc8:	fffff097          	auipc	ra,0xfffff
    80003dcc:	678080e7          	jalr	1656(ra) # 80003440 <bread>
    80003dd0:	8a2a                	mv	s4,a0
    for (j = 0; j < NINDIRECT; j++)
    80003dd2:	05850493          	addi	s1,a0,88
    80003dd6:	45850913          	addi	s2,a0,1112
    80003dda:	a021                	j	80003de2 <itrunc+0x7a>
    80003ddc:	0491                	addi	s1,s1,4
    80003dde:	01248b63          	beq	s1,s2,80003df4 <itrunc+0x8c>
      if (a[j])
    80003de2:	408c                	lw	a1,0(s1)
    80003de4:	dde5                	beqz	a1,80003ddc <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003de6:	0009a503          	lw	a0,0(s3)
    80003dea:	00000097          	auipc	ra,0x0
    80003dee:	89c080e7          	jalr	-1892(ra) # 80003686 <bfree>
    80003df2:	b7ed                	j	80003ddc <itrunc+0x74>
    brelse(bp);
    80003df4:	8552                	mv	a0,s4
    80003df6:	fffff097          	auipc	ra,0xfffff
    80003dfa:	77a080e7          	jalr	1914(ra) # 80003570 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003dfe:	0809a583          	lw	a1,128(s3)
    80003e02:	0009a503          	lw	a0,0(s3)
    80003e06:	00000097          	auipc	ra,0x0
    80003e0a:	880080e7          	jalr	-1920(ra) # 80003686 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003e0e:	0809a023          	sw	zero,128(s3)
    80003e12:	bf51                	j	80003da6 <itrunc+0x3e>

0000000080003e14 <iput>:
{
    80003e14:	1101                	addi	sp,sp,-32
    80003e16:	ec06                	sd	ra,24(sp)
    80003e18:	e822                	sd	s0,16(sp)
    80003e1a:	e426                	sd	s1,8(sp)
    80003e1c:	e04a                	sd	s2,0(sp)
    80003e1e:	1000                	addi	s0,sp,32
    80003e20:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e22:	00030517          	auipc	a0,0x30
    80003e26:	b3650513          	addi	a0,a0,-1226 # 80033958 <itable>
    80003e2a:	ffffd097          	auipc	ra,0xffffd
    80003e2e:	dac080e7          	jalr	-596(ra) # 80000bd6 <acquire>
  if (ip->ref == 1 && ip->valid && ip->nlink == 0)
    80003e32:	4498                	lw	a4,8(s1)
    80003e34:	4785                	li	a5,1
    80003e36:	02f70363          	beq	a4,a5,80003e5c <iput+0x48>
  ip->ref--;
    80003e3a:	449c                	lw	a5,8(s1)
    80003e3c:	37fd                	addiw	a5,a5,-1
    80003e3e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e40:	00030517          	auipc	a0,0x30
    80003e44:	b1850513          	addi	a0,a0,-1256 # 80033958 <itable>
    80003e48:	ffffd097          	auipc	ra,0xffffd
    80003e4c:	e42080e7          	jalr	-446(ra) # 80000c8a <release>
}
    80003e50:	60e2                	ld	ra,24(sp)
    80003e52:	6442                	ld	s0,16(sp)
    80003e54:	64a2                	ld	s1,8(sp)
    80003e56:	6902                	ld	s2,0(sp)
    80003e58:	6105                	addi	sp,sp,32
    80003e5a:	8082                	ret
  if (ip->ref == 1 && ip->valid && ip->nlink == 0)
    80003e5c:	40bc                	lw	a5,64(s1)
    80003e5e:	dff1                	beqz	a5,80003e3a <iput+0x26>
    80003e60:	04a49783          	lh	a5,74(s1)
    80003e64:	fbf9                	bnez	a5,80003e3a <iput+0x26>
    acquiresleep(&ip->lock);
    80003e66:	01048913          	addi	s2,s1,16
    80003e6a:	854a                	mv	a0,s2
    80003e6c:	00001097          	auipc	ra,0x1
    80003e70:	dba080e7          	jalr	-582(ra) # 80004c26 <acquiresleep>
    release(&itable.lock);
    80003e74:	00030517          	auipc	a0,0x30
    80003e78:	ae450513          	addi	a0,a0,-1308 # 80033958 <itable>
    80003e7c:	ffffd097          	auipc	ra,0xffffd
    80003e80:	e0e080e7          	jalr	-498(ra) # 80000c8a <release>
    itrunc(ip);
    80003e84:	8526                	mv	a0,s1
    80003e86:	00000097          	auipc	ra,0x0
    80003e8a:	ee2080e7          	jalr	-286(ra) # 80003d68 <itrunc>
    ip->type = 0;
    80003e8e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e92:	8526                	mv	a0,s1
    80003e94:	00000097          	auipc	ra,0x0
    80003e98:	cfc080e7          	jalr	-772(ra) # 80003b90 <iupdate>
    ip->valid = 0;
    80003e9c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ea0:	854a                	mv	a0,s2
    80003ea2:	00001097          	auipc	ra,0x1
    80003ea6:	dda080e7          	jalr	-550(ra) # 80004c7c <releasesleep>
    acquire(&itable.lock);
    80003eaa:	00030517          	auipc	a0,0x30
    80003eae:	aae50513          	addi	a0,a0,-1362 # 80033958 <itable>
    80003eb2:	ffffd097          	auipc	ra,0xffffd
    80003eb6:	d24080e7          	jalr	-732(ra) # 80000bd6 <acquire>
    80003eba:	b741                	j	80003e3a <iput+0x26>

0000000080003ebc <iunlockput>:
{
    80003ebc:	1101                	addi	sp,sp,-32
    80003ebe:	ec06                	sd	ra,24(sp)
    80003ec0:	e822                	sd	s0,16(sp)
    80003ec2:	e426                	sd	s1,8(sp)
    80003ec4:	1000                	addi	s0,sp,32
    80003ec6:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ec8:	00000097          	auipc	ra,0x0
    80003ecc:	e54080e7          	jalr	-428(ra) # 80003d1c <iunlock>
  iput(ip);
    80003ed0:	8526                	mv	a0,s1
    80003ed2:	00000097          	auipc	ra,0x0
    80003ed6:	f42080e7          	jalr	-190(ra) # 80003e14 <iput>
}
    80003eda:	60e2                	ld	ra,24(sp)
    80003edc:	6442                	ld	s0,16(sp)
    80003ede:	64a2                	ld	s1,8(sp)
    80003ee0:	6105                	addi	sp,sp,32
    80003ee2:	8082                	ret

0000000080003ee4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void stati(struct inode *ip, struct stat *st)
{
    80003ee4:	1141                	addi	sp,sp,-16
    80003ee6:	e422                	sd	s0,8(sp)
    80003ee8:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003eea:	411c                	lw	a5,0(a0)
    80003eec:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003eee:	415c                	lw	a5,4(a0)
    80003ef0:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ef2:	04451783          	lh	a5,68(a0)
    80003ef6:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003efa:	04a51783          	lh	a5,74(a0)
    80003efe:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003f02:	04c56783          	lwu	a5,76(a0)
    80003f06:	e99c                	sd	a5,16(a1)
}
    80003f08:	6422                	ld	s0,8(sp)
    80003f0a:	0141                	addi	sp,sp,16
    80003f0c:	8082                	ret

0000000080003f0e <readi>:
int readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if (off > ip->size || off + n < off)
    80003f0e:	457c                	lw	a5,76(a0)
    80003f10:	0ed7e963          	bltu	a5,a3,80004002 <readi+0xf4>
{
    80003f14:	7159                	addi	sp,sp,-112
    80003f16:	f486                	sd	ra,104(sp)
    80003f18:	f0a2                	sd	s0,96(sp)
    80003f1a:	eca6                	sd	s1,88(sp)
    80003f1c:	e8ca                	sd	s2,80(sp)
    80003f1e:	e4ce                	sd	s3,72(sp)
    80003f20:	e0d2                	sd	s4,64(sp)
    80003f22:	fc56                	sd	s5,56(sp)
    80003f24:	f85a                	sd	s6,48(sp)
    80003f26:	f45e                	sd	s7,40(sp)
    80003f28:	f062                	sd	s8,32(sp)
    80003f2a:	ec66                	sd	s9,24(sp)
    80003f2c:	e86a                	sd	s10,16(sp)
    80003f2e:	e46e                	sd	s11,8(sp)
    80003f30:	1880                	addi	s0,sp,112
    80003f32:	8b2a                	mv	s6,a0
    80003f34:	8bae                	mv	s7,a1
    80003f36:	8a32                	mv	s4,a2
    80003f38:	84b6                	mv	s1,a3
    80003f3a:	8aba                	mv	s5,a4
  if (off > ip->size || off + n < off)
    80003f3c:	9f35                	addw	a4,a4,a3
    return 0;
    80003f3e:	4501                	li	a0,0
  if (off > ip->size || off + n < off)
    80003f40:	0ad76063          	bltu	a4,a3,80003fe0 <readi+0xd2>
  if (off + n > ip->size)
    80003f44:	00e7f463          	bgeu	a5,a4,80003f4c <readi+0x3e>
    n = ip->size - off;
    80003f48:	40d78abb          	subw	s5,a5,a3

  for (tot = 0; tot < n; tot += m, off += m, dst += m)
    80003f4c:	0a0a8963          	beqz	s5,80003ffe <readi+0xf0>
    80003f50:	4981                	li	s3,0
  {
    uint addr = bmap(ip, off / BSIZE);
    if (addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off % BSIZE);
    80003f52:	40000c93          	li	s9,1024
    if (either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1)
    80003f56:	5c7d                	li	s8,-1
    80003f58:	a82d                	j	80003f92 <readi+0x84>
    80003f5a:	020d1d93          	slli	s11,s10,0x20
    80003f5e:	020ddd93          	srli	s11,s11,0x20
    80003f62:	05890793          	addi	a5,s2,88
    80003f66:	86ee                	mv	a3,s11
    80003f68:	963e                	add	a2,a2,a5
    80003f6a:	85d2                	mv	a1,s4
    80003f6c:	855e                	mv	a0,s7
    80003f6e:	ffffe097          	auipc	ra,0xffffe
    80003f72:	6fe080e7          	jalr	1790(ra) # 8000266c <either_copyout>
    80003f76:	05850d63          	beq	a0,s8,80003fd0 <readi+0xc2>
    {
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f7a:	854a                	mv	a0,s2
    80003f7c:	fffff097          	auipc	ra,0xfffff
    80003f80:	5f4080e7          	jalr	1524(ra) # 80003570 <brelse>
  for (tot = 0; tot < n; tot += m, off += m, dst += m)
    80003f84:	013d09bb          	addw	s3,s10,s3
    80003f88:	009d04bb          	addw	s1,s10,s1
    80003f8c:	9a6e                	add	s4,s4,s11
    80003f8e:	0559f763          	bgeu	s3,s5,80003fdc <readi+0xce>
    uint addr = bmap(ip, off / BSIZE);
    80003f92:	00a4d59b          	srliw	a1,s1,0xa
    80003f96:	855a                	mv	a0,s6
    80003f98:	00000097          	auipc	ra,0x0
    80003f9c:	8a2080e7          	jalr	-1886(ra) # 8000383a <bmap>
    80003fa0:	0005059b          	sext.w	a1,a0
    if (addr == 0)
    80003fa4:	cd85                	beqz	a1,80003fdc <readi+0xce>
    bp = bread(ip->dev, addr);
    80003fa6:	000b2503          	lw	a0,0(s6)
    80003faa:	fffff097          	auipc	ra,0xfffff
    80003fae:	496080e7          	jalr	1174(ra) # 80003440 <bread>
    80003fb2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off % BSIZE);
    80003fb4:	3ff4f613          	andi	a2,s1,1023
    80003fb8:	40cc87bb          	subw	a5,s9,a2
    80003fbc:	413a873b          	subw	a4,s5,s3
    80003fc0:	8d3e                	mv	s10,a5
    80003fc2:	2781                	sext.w	a5,a5
    80003fc4:	0007069b          	sext.w	a3,a4
    80003fc8:	f8f6f9e3          	bgeu	a3,a5,80003f5a <readi+0x4c>
    80003fcc:	8d3a                	mv	s10,a4
    80003fce:	b771                	j	80003f5a <readi+0x4c>
      brelse(bp);
    80003fd0:	854a                	mv	a0,s2
    80003fd2:	fffff097          	auipc	ra,0xfffff
    80003fd6:	59e080e7          	jalr	1438(ra) # 80003570 <brelse>
      tot = -1;
    80003fda:	59fd                	li	s3,-1
  }
  return tot;
    80003fdc:	0009851b          	sext.w	a0,s3
}
    80003fe0:	70a6                	ld	ra,104(sp)
    80003fe2:	7406                	ld	s0,96(sp)
    80003fe4:	64e6                	ld	s1,88(sp)
    80003fe6:	6946                	ld	s2,80(sp)
    80003fe8:	69a6                	ld	s3,72(sp)
    80003fea:	6a06                	ld	s4,64(sp)
    80003fec:	7ae2                	ld	s5,56(sp)
    80003fee:	7b42                	ld	s6,48(sp)
    80003ff0:	7ba2                	ld	s7,40(sp)
    80003ff2:	7c02                	ld	s8,32(sp)
    80003ff4:	6ce2                	ld	s9,24(sp)
    80003ff6:	6d42                	ld	s10,16(sp)
    80003ff8:	6da2                	ld	s11,8(sp)
    80003ffa:	6165                	addi	sp,sp,112
    80003ffc:	8082                	ret
  for (tot = 0; tot < n; tot += m, off += m, dst += m)
    80003ffe:	89d6                	mv	s3,s5
    80004000:	bff1                	j	80003fdc <readi+0xce>
    return 0;
    80004002:	4501                	li	a0,0
}
    80004004:	8082                	ret

0000000080004006 <writei>:
int writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if (off > ip->size || off + n < off)
    80004006:	457c                	lw	a5,76(a0)
    80004008:	10d7e863          	bltu	a5,a3,80004118 <writei+0x112>
{
    8000400c:	7159                	addi	sp,sp,-112
    8000400e:	f486                	sd	ra,104(sp)
    80004010:	f0a2                	sd	s0,96(sp)
    80004012:	eca6                	sd	s1,88(sp)
    80004014:	e8ca                	sd	s2,80(sp)
    80004016:	e4ce                	sd	s3,72(sp)
    80004018:	e0d2                	sd	s4,64(sp)
    8000401a:	fc56                	sd	s5,56(sp)
    8000401c:	f85a                	sd	s6,48(sp)
    8000401e:	f45e                	sd	s7,40(sp)
    80004020:	f062                	sd	s8,32(sp)
    80004022:	ec66                	sd	s9,24(sp)
    80004024:	e86a                	sd	s10,16(sp)
    80004026:	e46e                	sd	s11,8(sp)
    80004028:	1880                	addi	s0,sp,112
    8000402a:	8aaa                	mv	s5,a0
    8000402c:	8bae                	mv	s7,a1
    8000402e:	8a32                	mv	s4,a2
    80004030:	8936                	mv	s2,a3
    80004032:	8b3a                	mv	s6,a4
  if (off > ip->size || off + n < off)
    80004034:	00e687bb          	addw	a5,a3,a4
    80004038:	0ed7e263          	bltu	a5,a3,8000411c <writei+0x116>
    return -1;
  if (off + n > MAXFILE * BSIZE)
    8000403c:	00043737          	lui	a4,0x43
    80004040:	0ef76063          	bltu	a4,a5,80004120 <writei+0x11a>
    return -1;

  for (tot = 0; tot < n; tot += m, off += m, src += m)
    80004044:	0c0b0863          	beqz	s6,80004114 <writei+0x10e>
    80004048:	4981                	li	s3,0
  {
    uint addr = bmap(ip, off / BSIZE);
    if (addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off % BSIZE);
    8000404a:	40000c93          	li	s9,1024
    if (either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1)
    8000404e:	5c7d                	li	s8,-1
    80004050:	a091                	j	80004094 <writei+0x8e>
    80004052:	020d1d93          	slli	s11,s10,0x20
    80004056:	020ddd93          	srli	s11,s11,0x20
    8000405a:	05848793          	addi	a5,s1,88
    8000405e:	86ee                	mv	a3,s11
    80004060:	8652                	mv	a2,s4
    80004062:	85de                	mv	a1,s7
    80004064:	953e                	add	a0,a0,a5
    80004066:	ffffe097          	auipc	ra,0xffffe
    8000406a:	65c080e7          	jalr	1628(ra) # 800026c2 <either_copyin>
    8000406e:	07850263          	beq	a0,s8,800040d2 <writei+0xcc>
    {
      brelse(bp);
      break;
    }
    log_write(bp);
    80004072:	8526                	mv	a0,s1
    80004074:	00001097          	auipc	ra,0x1
    80004078:	a92080e7          	jalr	-1390(ra) # 80004b06 <log_write>
    brelse(bp);
    8000407c:	8526                	mv	a0,s1
    8000407e:	fffff097          	auipc	ra,0xfffff
    80004082:	4f2080e7          	jalr	1266(ra) # 80003570 <brelse>
  for (tot = 0; tot < n; tot += m, off += m, src += m)
    80004086:	013d09bb          	addw	s3,s10,s3
    8000408a:	012d093b          	addw	s2,s10,s2
    8000408e:	9a6e                	add	s4,s4,s11
    80004090:	0569f663          	bgeu	s3,s6,800040dc <writei+0xd6>
    uint addr = bmap(ip, off / BSIZE);
    80004094:	00a9559b          	srliw	a1,s2,0xa
    80004098:	8556                	mv	a0,s5
    8000409a:	fffff097          	auipc	ra,0xfffff
    8000409e:	7a0080e7          	jalr	1952(ra) # 8000383a <bmap>
    800040a2:	0005059b          	sext.w	a1,a0
    if (addr == 0)
    800040a6:	c99d                	beqz	a1,800040dc <writei+0xd6>
    bp = bread(ip->dev, addr);
    800040a8:	000aa503          	lw	a0,0(s5)
    800040ac:	fffff097          	auipc	ra,0xfffff
    800040b0:	394080e7          	jalr	916(ra) # 80003440 <bread>
    800040b4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off % BSIZE);
    800040b6:	3ff97513          	andi	a0,s2,1023
    800040ba:	40ac87bb          	subw	a5,s9,a0
    800040be:	413b073b          	subw	a4,s6,s3
    800040c2:	8d3e                	mv	s10,a5
    800040c4:	2781                	sext.w	a5,a5
    800040c6:	0007069b          	sext.w	a3,a4
    800040ca:	f8f6f4e3          	bgeu	a3,a5,80004052 <writei+0x4c>
    800040ce:	8d3a                	mv	s10,a4
    800040d0:	b749                	j	80004052 <writei+0x4c>
      brelse(bp);
    800040d2:	8526                	mv	a0,s1
    800040d4:	fffff097          	auipc	ra,0xfffff
    800040d8:	49c080e7          	jalr	1180(ra) # 80003570 <brelse>
  }

  if (off > ip->size)
    800040dc:	04caa783          	lw	a5,76(s5)
    800040e0:	0127f463          	bgeu	a5,s2,800040e8 <writei+0xe2>
    ip->size = off;
    800040e4:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800040e8:	8556                	mv	a0,s5
    800040ea:	00000097          	auipc	ra,0x0
    800040ee:	aa6080e7          	jalr	-1370(ra) # 80003b90 <iupdate>

  return tot;
    800040f2:	0009851b          	sext.w	a0,s3
}
    800040f6:	70a6                	ld	ra,104(sp)
    800040f8:	7406                	ld	s0,96(sp)
    800040fa:	64e6                	ld	s1,88(sp)
    800040fc:	6946                	ld	s2,80(sp)
    800040fe:	69a6                	ld	s3,72(sp)
    80004100:	6a06                	ld	s4,64(sp)
    80004102:	7ae2                	ld	s5,56(sp)
    80004104:	7b42                	ld	s6,48(sp)
    80004106:	7ba2                	ld	s7,40(sp)
    80004108:	7c02                	ld	s8,32(sp)
    8000410a:	6ce2                	ld	s9,24(sp)
    8000410c:	6d42                	ld	s10,16(sp)
    8000410e:	6da2                	ld	s11,8(sp)
    80004110:	6165                	addi	sp,sp,112
    80004112:	8082                	ret
  for (tot = 0; tot < n; tot += m, off += m, src += m)
    80004114:	89da                	mv	s3,s6
    80004116:	bfc9                	j	800040e8 <writei+0xe2>
    return -1;
    80004118:	557d                	li	a0,-1
}
    8000411a:	8082                	ret
    return -1;
    8000411c:	557d                	li	a0,-1
    8000411e:	bfe1                	j	800040f6 <writei+0xf0>
    return -1;
    80004120:	557d                	li	a0,-1
    80004122:	bfd1                	j	800040f6 <writei+0xf0>

0000000080004124 <namecmp>:

// Directories

int namecmp(const char *s, const char *t)
{
    80004124:	1141                	addi	sp,sp,-16
    80004126:	e406                	sd	ra,8(sp)
    80004128:	e022                	sd	s0,0(sp)
    8000412a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000412c:	4639                	li	a2,14
    8000412e:	ffffd097          	auipc	ra,0xffffd
    80004132:	c74080e7          	jalr	-908(ra) # 80000da2 <strncmp>
}
    80004136:	60a2                	ld	ra,8(sp)
    80004138:	6402                	ld	s0,0(sp)
    8000413a:	0141                	addi	sp,sp,16
    8000413c:	8082                	ret

000000008000413e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode *
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000413e:	7139                	addi	sp,sp,-64
    80004140:	fc06                	sd	ra,56(sp)
    80004142:	f822                	sd	s0,48(sp)
    80004144:	f426                	sd	s1,40(sp)
    80004146:	f04a                	sd	s2,32(sp)
    80004148:	ec4e                	sd	s3,24(sp)
    8000414a:	e852                	sd	s4,16(sp)
    8000414c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if (dp->type != T_DIR)
    8000414e:	04451703          	lh	a4,68(a0)
    80004152:	4785                	li	a5,1
    80004154:	00f71a63          	bne	a4,a5,80004168 <dirlookup+0x2a>
    80004158:	892a                	mv	s2,a0
    8000415a:	89ae                	mv	s3,a1
    8000415c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for (off = 0; off < dp->size; off += sizeof(de))
    8000415e:	457c                	lw	a5,76(a0)
    80004160:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004162:	4501                	li	a0,0
  for (off = 0; off < dp->size; off += sizeof(de))
    80004164:	e79d                	bnez	a5,80004192 <dirlookup+0x54>
    80004166:	a8a5                	j	800041de <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004168:	00004517          	auipc	a0,0x4
    8000416c:	53050513          	addi	a0,a0,1328 # 80008698 <syscalls+0x1a0>
    80004170:	ffffc097          	auipc	ra,0xffffc
    80004174:	3ce080e7          	jalr	974(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004178:	00004517          	auipc	a0,0x4
    8000417c:	53850513          	addi	a0,a0,1336 # 800086b0 <syscalls+0x1b8>
    80004180:	ffffc097          	auipc	ra,0xffffc
    80004184:	3be080e7          	jalr	958(ra) # 8000053e <panic>
  for (off = 0; off < dp->size; off += sizeof(de))
    80004188:	24c1                	addiw	s1,s1,16
    8000418a:	04c92783          	lw	a5,76(s2)
    8000418e:	04f4f763          	bgeu	s1,a5,800041dc <dirlookup+0x9e>
    if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004192:	4741                	li	a4,16
    80004194:	86a6                	mv	a3,s1
    80004196:	fc040613          	addi	a2,s0,-64
    8000419a:	4581                	li	a1,0
    8000419c:	854a                	mv	a0,s2
    8000419e:	00000097          	auipc	ra,0x0
    800041a2:	d70080e7          	jalr	-656(ra) # 80003f0e <readi>
    800041a6:	47c1                	li	a5,16
    800041a8:	fcf518e3          	bne	a0,a5,80004178 <dirlookup+0x3a>
    if (de.inum == 0)
    800041ac:	fc045783          	lhu	a5,-64(s0)
    800041b0:	dfe1                	beqz	a5,80004188 <dirlookup+0x4a>
    if (namecmp(name, de.name) == 0)
    800041b2:	fc240593          	addi	a1,s0,-62
    800041b6:	854e                	mv	a0,s3
    800041b8:	00000097          	auipc	ra,0x0
    800041bc:	f6c080e7          	jalr	-148(ra) # 80004124 <namecmp>
    800041c0:	f561                	bnez	a0,80004188 <dirlookup+0x4a>
      if (poff)
    800041c2:	000a0463          	beqz	s4,800041ca <dirlookup+0x8c>
        *poff = off;
    800041c6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800041ca:	fc045583          	lhu	a1,-64(s0)
    800041ce:	00092503          	lw	a0,0(s2)
    800041d2:	fffff097          	auipc	ra,0xfffff
    800041d6:	750080e7          	jalr	1872(ra) # 80003922 <iget>
    800041da:	a011                	j	800041de <dirlookup+0xa0>
  return 0;
    800041dc:	4501                	li	a0,0
}
    800041de:	70e2                	ld	ra,56(sp)
    800041e0:	7442                	ld	s0,48(sp)
    800041e2:	74a2                	ld	s1,40(sp)
    800041e4:	7902                	ld	s2,32(sp)
    800041e6:	69e2                	ld	s3,24(sp)
    800041e8:	6a42                	ld	s4,16(sp)
    800041ea:	6121                	addi	sp,sp,64
    800041ec:	8082                	ret

00000000800041ee <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode *
namex(char *path, int nameiparent, char *name)
{
    800041ee:	711d                	addi	sp,sp,-96
    800041f0:	ec86                	sd	ra,88(sp)
    800041f2:	e8a2                	sd	s0,80(sp)
    800041f4:	e4a6                	sd	s1,72(sp)
    800041f6:	e0ca                	sd	s2,64(sp)
    800041f8:	fc4e                	sd	s3,56(sp)
    800041fa:	f852                	sd	s4,48(sp)
    800041fc:	f456                	sd	s5,40(sp)
    800041fe:	f05a                	sd	s6,32(sp)
    80004200:	ec5e                	sd	s7,24(sp)
    80004202:	e862                	sd	s8,16(sp)
    80004204:	e466                	sd	s9,8(sp)
    80004206:	1080                	addi	s0,sp,96
    80004208:	84aa                	mv	s1,a0
    8000420a:	8aae                	mv	s5,a1
    8000420c:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if (*path == '/')
    8000420e:	00054703          	lbu	a4,0(a0)
    80004212:	02f00793          	li	a5,47
    80004216:	02f70363          	beq	a4,a5,8000423c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000421a:	ffffe097          	auipc	ra,0xffffe
    8000421e:	8e4080e7          	jalr	-1820(ra) # 80001afe <myproc>
    80004222:	15053503          	ld	a0,336(a0)
    80004226:	00000097          	auipc	ra,0x0
    8000422a:	9f6080e7          	jalr	-1546(ra) # 80003c1c <idup>
    8000422e:	89aa                	mv	s3,a0
  while (*path == '/')
    80004230:	02f00913          	li	s2,47
  len = path - s;
    80004234:	4b01                	li	s6,0
  if (len >= DIRSIZ)
    80004236:	4c35                	li	s8,13

  while ((path = skipelem(path, name)) != 0)
  {
    ilock(ip);
    if (ip->type != T_DIR)
    80004238:	4b85                	li	s7,1
    8000423a:	a865                	j	800042f2 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000423c:	4585                	li	a1,1
    8000423e:	4505                	li	a0,1
    80004240:	fffff097          	auipc	ra,0xfffff
    80004244:	6e2080e7          	jalr	1762(ra) # 80003922 <iget>
    80004248:	89aa                	mv	s3,a0
    8000424a:	b7dd                	j	80004230 <namex+0x42>
    {
      iunlockput(ip);
    8000424c:	854e                	mv	a0,s3
    8000424e:	00000097          	auipc	ra,0x0
    80004252:	c6e080e7          	jalr	-914(ra) # 80003ebc <iunlockput>
      return 0;
    80004256:	4981                	li	s3,0
  {
    iput(ip);
    return 0;
  }
  return ip;
}
    80004258:	854e                	mv	a0,s3
    8000425a:	60e6                	ld	ra,88(sp)
    8000425c:	6446                	ld	s0,80(sp)
    8000425e:	64a6                	ld	s1,72(sp)
    80004260:	6906                	ld	s2,64(sp)
    80004262:	79e2                	ld	s3,56(sp)
    80004264:	7a42                	ld	s4,48(sp)
    80004266:	7aa2                	ld	s5,40(sp)
    80004268:	7b02                	ld	s6,32(sp)
    8000426a:	6be2                	ld	s7,24(sp)
    8000426c:	6c42                	ld	s8,16(sp)
    8000426e:	6ca2                	ld	s9,8(sp)
    80004270:	6125                	addi	sp,sp,96
    80004272:	8082                	ret
      iunlock(ip);
    80004274:	854e                	mv	a0,s3
    80004276:	00000097          	auipc	ra,0x0
    8000427a:	aa6080e7          	jalr	-1370(ra) # 80003d1c <iunlock>
      return ip;
    8000427e:	bfe9                	j	80004258 <namex+0x6a>
      iunlockput(ip);
    80004280:	854e                	mv	a0,s3
    80004282:	00000097          	auipc	ra,0x0
    80004286:	c3a080e7          	jalr	-966(ra) # 80003ebc <iunlockput>
      return 0;
    8000428a:	89e6                	mv	s3,s9
    8000428c:	b7f1                	j	80004258 <namex+0x6a>
  len = path - s;
    8000428e:	40b48633          	sub	a2,s1,a1
    80004292:	00060c9b          	sext.w	s9,a2
  if (len >= DIRSIZ)
    80004296:	099c5463          	bge	s8,s9,8000431e <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000429a:	4639                	li	a2,14
    8000429c:	8552                	mv	a0,s4
    8000429e:	ffffd097          	auipc	ra,0xffffd
    800042a2:	a90080e7          	jalr	-1392(ra) # 80000d2e <memmove>
  while (*path == '/')
    800042a6:	0004c783          	lbu	a5,0(s1)
    800042aa:	01279763          	bne	a5,s2,800042b8 <namex+0xca>
    path++;
    800042ae:	0485                	addi	s1,s1,1
  while (*path == '/')
    800042b0:	0004c783          	lbu	a5,0(s1)
    800042b4:	ff278de3          	beq	a5,s2,800042ae <namex+0xc0>
    ilock(ip);
    800042b8:	854e                	mv	a0,s3
    800042ba:	00000097          	auipc	ra,0x0
    800042be:	9a0080e7          	jalr	-1632(ra) # 80003c5a <ilock>
    if (ip->type != T_DIR)
    800042c2:	04499783          	lh	a5,68(s3)
    800042c6:	f97793e3          	bne	a5,s7,8000424c <namex+0x5e>
    if (nameiparent && *path == '\0')
    800042ca:	000a8563          	beqz	s5,800042d4 <namex+0xe6>
    800042ce:	0004c783          	lbu	a5,0(s1)
    800042d2:	d3cd                	beqz	a5,80004274 <namex+0x86>
    if ((next = dirlookup(ip, name, 0)) == 0)
    800042d4:	865a                	mv	a2,s6
    800042d6:	85d2                	mv	a1,s4
    800042d8:	854e                	mv	a0,s3
    800042da:	00000097          	auipc	ra,0x0
    800042de:	e64080e7          	jalr	-412(ra) # 8000413e <dirlookup>
    800042e2:	8caa                	mv	s9,a0
    800042e4:	dd51                	beqz	a0,80004280 <namex+0x92>
    iunlockput(ip);
    800042e6:	854e                	mv	a0,s3
    800042e8:	00000097          	auipc	ra,0x0
    800042ec:	bd4080e7          	jalr	-1068(ra) # 80003ebc <iunlockput>
    ip = next;
    800042f0:	89e6                	mv	s3,s9
  while (*path == '/')
    800042f2:	0004c783          	lbu	a5,0(s1)
    800042f6:	05279763          	bne	a5,s2,80004344 <namex+0x156>
    path++;
    800042fa:	0485                	addi	s1,s1,1
  while (*path == '/')
    800042fc:	0004c783          	lbu	a5,0(s1)
    80004300:	ff278de3          	beq	a5,s2,800042fa <namex+0x10c>
  if (*path == 0)
    80004304:	c79d                	beqz	a5,80004332 <namex+0x144>
    path++;
    80004306:	85a6                	mv	a1,s1
  len = path - s;
    80004308:	8cda                	mv	s9,s6
    8000430a:	865a                	mv	a2,s6
  while (*path != '/' && *path != 0)
    8000430c:	01278963          	beq	a5,s2,8000431e <namex+0x130>
    80004310:	dfbd                	beqz	a5,8000428e <namex+0xa0>
    path++;
    80004312:	0485                	addi	s1,s1,1
  while (*path != '/' && *path != 0)
    80004314:	0004c783          	lbu	a5,0(s1)
    80004318:	ff279ce3          	bne	a5,s2,80004310 <namex+0x122>
    8000431c:	bf8d                	j	8000428e <namex+0xa0>
    memmove(name, s, len);
    8000431e:	2601                	sext.w	a2,a2
    80004320:	8552                	mv	a0,s4
    80004322:	ffffd097          	auipc	ra,0xffffd
    80004326:	a0c080e7          	jalr	-1524(ra) # 80000d2e <memmove>
    name[len] = 0;
    8000432a:	9cd2                	add	s9,s9,s4
    8000432c:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004330:	bf9d                	j	800042a6 <namex+0xb8>
  if (nameiparent)
    80004332:	f20a83e3          	beqz	s5,80004258 <namex+0x6a>
    iput(ip);
    80004336:	854e                	mv	a0,s3
    80004338:	00000097          	auipc	ra,0x0
    8000433c:	adc080e7          	jalr	-1316(ra) # 80003e14 <iput>
    return 0;
    80004340:	4981                	li	s3,0
    80004342:	bf19                	j	80004258 <namex+0x6a>
  if (*path == 0)
    80004344:	d7fd                	beqz	a5,80004332 <namex+0x144>
  while (*path != '/' && *path != 0)
    80004346:	0004c783          	lbu	a5,0(s1)
    8000434a:	85a6                	mv	a1,s1
    8000434c:	b7d1                	j	80004310 <namex+0x122>

000000008000434e <dirlink>:
{
    8000434e:	7139                	addi	sp,sp,-64
    80004350:	fc06                	sd	ra,56(sp)
    80004352:	f822                	sd	s0,48(sp)
    80004354:	f426                	sd	s1,40(sp)
    80004356:	f04a                	sd	s2,32(sp)
    80004358:	ec4e                	sd	s3,24(sp)
    8000435a:	e852                	sd	s4,16(sp)
    8000435c:	0080                	addi	s0,sp,64
    8000435e:	892a                	mv	s2,a0
    80004360:	8a2e                	mv	s4,a1
    80004362:	89b2                	mv	s3,a2
  if ((ip = dirlookup(dp, name, 0)) != 0)
    80004364:	4601                	li	a2,0
    80004366:	00000097          	auipc	ra,0x0
    8000436a:	dd8080e7          	jalr	-552(ra) # 8000413e <dirlookup>
    8000436e:	e93d                	bnez	a0,800043e4 <dirlink+0x96>
  for (off = 0; off < dp->size; off += sizeof(de))
    80004370:	04c92483          	lw	s1,76(s2)
    80004374:	c49d                	beqz	s1,800043a2 <dirlink+0x54>
    80004376:	4481                	li	s1,0
    if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004378:	4741                	li	a4,16
    8000437a:	86a6                	mv	a3,s1
    8000437c:	fc040613          	addi	a2,s0,-64
    80004380:	4581                	li	a1,0
    80004382:	854a                	mv	a0,s2
    80004384:	00000097          	auipc	ra,0x0
    80004388:	b8a080e7          	jalr	-1142(ra) # 80003f0e <readi>
    8000438c:	47c1                	li	a5,16
    8000438e:	06f51163          	bne	a0,a5,800043f0 <dirlink+0xa2>
    if (de.inum == 0)
    80004392:	fc045783          	lhu	a5,-64(s0)
    80004396:	c791                	beqz	a5,800043a2 <dirlink+0x54>
  for (off = 0; off < dp->size; off += sizeof(de))
    80004398:	24c1                	addiw	s1,s1,16
    8000439a:	04c92783          	lw	a5,76(s2)
    8000439e:	fcf4ede3          	bltu	s1,a5,80004378 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800043a2:	4639                	li	a2,14
    800043a4:	85d2                	mv	a1,s4
    800043a6:	fc240513          	addi	a0,s0,-62
    800043aa:	ffffd097          	auipc	ra,0xffffd
    800043ae:	a34080e7          	jalr	-1484(ra) # 80000dde <strncpy>
  de.inum = inum;
    800043b2:	fd341023          	sh	s3,-64(s0)
  if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043b6:	4741                	li	a4,16
    800043b8:	86a6                	mv	a3,s1
    800043ba:	fc040613          	addi	a2,s0,-64
    800043be:	4581                	li	a1,0
    800043c0:	854a                	mv	a0,s2
    800043c2:	00000097          	auipc	ra,0x0
    800043c6:	c44080e7          	jalr	-956(ra) # 80004006 <writei>
    800043ca:	1541                	addi	a0,a0,-16
    800043cc:	00a03533          	snez	a0,a0
    800043d0:	40a00533          	neg	a0,a0
}
    800043d4:	70e2                	ld	ra,56(sp)
    800043d6:	7442                	ld	s0,48(sp)
    800043d8:	74a2                	ld	s1,40(sp)
    800043da:	7902                	ld	s2,32(sp)
    800043dc:	69e2                	ld	s3,24(sp)
    800043de:	6a42                	ld	s4,16(sp)
    800043e0:	6121                	addi	sp,sp,64
    800043e2:	8082                	ret
    iput(ip);
    800043e4:	00000097          	auipc	ra,0x0
    800043e8:	a30080e7          	jalr	-1488(ra) # 80003e14 <iput>
    return -1;
    800043ec:	557d                	li	a0,-1
    800043ee:	b7dd                	j	800043d4 <dirlink+0x86>
      panic("dirlink read");
    800043f0:	00004517          	auipc	a0,0x4
    800043f4:	2d050513          	addi	a0,a0,720 # 800086c0 <syscalls+0x1c8>
    800043f8:	ffffc097          	auipc	ra,0xffffc
    800043fc:	146080e7          	jalr	326(ra) # 8000053e <panic>

0000000080004400 <namei>:

struct inode *
namei(char *path)
{
    80004400:	1101                	addi	sp,sp,-32
    80004402:	ec06                	sd	ra,24(sp)
    80004404:	e822                	sd	s0,16(sp)
    80004406:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004408:	fe040613          	addi	a2,s0,-32
    8000440c:	4581                	li	a1,0
    8000440e:	00000097          	auipc	ra,0x0
    80004412:	de0080e7          	jalr	-544(ra) # 800041ee <namex>
}
    80004416:	60e2                	ld	ra,24(sp)
    80004418:	6442                	ld	s0,16(sp)
    8000441a:	6105                	addi	sp,sp,32
    8000441c:	8082                	ret

000000008000441e <nameiparent>:

struct inode *
nameiparent(char *path, char *name)
{
    8000441e:	1141                	addi	sp,sp,-16
    80004420:	e406                	sd	ra,8(sp)
    80004422:	e022                	sd	s0,0(sp)
    80004424:	0800                	addi	s0,sp,16
    80004426:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004428:	4585                	li	a1,1
    8000442a:	00000097          	auipc	ra,0x0
    8000442e:	dc4080e7          	jalr	-572(ra) # 800041ee <namex>
}
    80004432:	60a2                	ld	ra,8(sp)
    80004434:	6402                	ld	s0,0(sp)
    80004436:	0141                	addi	sp,sp,16
    80004438:	8082                	ret

000000008000443a <itoa>:

#include "fcntl.h"
#define DIGITS 14

char *itoa(int i, char b[])
{
    8000443a:	1101                	addi	sp,sp,-32
    8000443c:	ec22                	sd	s0,24(sp)
    8000443e:	1000                	addi	s0,sp,32
    80004440:	872a                	mv	a4,a0
    80004442:	852e                	mv	a0,a1
  char const digit[] = "0123456789";
    80004444:	00004797          	auipc	a5,0x4
    80004448:	28c78793          	addi	a5,a5,652 # 800086d0 <syscalls+0x1d8>
    8000444c:	6394                	ld	a3,0(a5)
    8000444e:	fed43023          	sd	a3,-32(s0)
    80004452:	0087d683          	lhu	a3,8(a5)
    80004456:	fed41423          	sh	a3,-24(s0)
    8000445a:	00a7c783          	lbu	a5,10(a5)
    8000445e:	fef40523          	sb	a5,-22(s0)
  char *p = b;
    80004462:	87ae                	mv	a5,a1
  if (i < 0)
    80004464:	02074b63          	bltz	a4,8000449a <itoa+0x60>
  {
    *p++ = '-';
    i *= -1;
  }
  int shifter = i;
    80004468:	86ba                	mv	a3,a4
  do
  { // Move to where representation ends
    ++p;
    shifter = shifter / 10;
    8000446a:	4629                	li	a2,10
    ++p;
    8000446c:	0785                	addi	a5,a5,1
    shifter = shifter / 10;
    8000446e:	02c6c6bb          	divw	a3,a3,a2
  } while (shifter);
    80004472:	feed                	bnez	a3,8000446c <itoa+0x32>
  *p = '\0';
    80004474:	00078023          	sb	zero,0(a5)
  do
  { // Move back, inserting digits as u go
    *--p = digit[i % 10];
    80004478:	4629                	li	a2,10
    8000447a:	17fd                	addi	a5,a5,-1
    8000447c:	02c766bb          	remw	a3,a4,a2
    80004480:	ff040593          	addi	a1,s0,-16
    80004484:	96ae                	add	a3,a3,a1
    80004486:	ff06c683          	lbu	a3,-16(a3)
    8000448a:	00d78023          	sb	a3,0(a5)
    i = i / 10;
    8000448e:	02c7473b          	divw	a4,a4,a2
  } while (i);
    80004492:	f765                	bnez	a4,8000447a <itoa+0x40>
  return b;
}
    80004494:	6462                	ld	s0,24(sp)
    80004496:	6105                	addi	sp,sp,32
    80004498:	8082                	ret
    *p++ = '-';
    8000449a:	00158793          	addi	a5,a1,1
    8000449e:	02d00693          	li	a3,45
    800044a2:	00d58023          	sb	a3,0(a1)
    i *= -1;
    800044a6:	40e0073b          	negw	a4,a4
    800044aa:	bf7d                	j	80004468 <itoa+0x2e>

00000000800044ac <removeSwapFile>:
// remove swap file of proc p;
int removeSwapFile(struct proc *p)
{
    800044ac:	711d                	addi	sp,sp,-96
    800044ae:	ec86                	sd	ra,88(sp)
    800044b0:	e8a2                	sd	s0,80(sp)
    800044b2:	e4a6                	sd	s1,72(sp)
    800044b4:	e0ca                	sd	s2,64(sp)
    800044b6:	1080                	addi	s0,sp,96
    800044b8:	84aa                	mv	s1,a0
  // path of proccess
  char path[DIGITS];
  memmove(path, "/.swap", 6);
    800044ba:	4619                	li	a2,6
    800044bc:	00004597          	auipc	a1,0x4
    800044c0:	22458593          	addi	a1,a1,548 # 800086e0 <syscalls+0x1e8>
    800044c4:	fd040513          	addi	a0,s0,-48
    800044c8:	ffffd097          	auipc	ra,0xffffd
    800044cc:	866080e7          	jalr	-1946(ra) # 80000d2e <memmove>
  itoa(p->pid, path + 6);
    800044d0:	fd640593          	addi	a1,s0,-42
    800044d4:	5888                	lw	a0,48(s1)
    800044d6:	00000097          	auipc	ra,0x0
    800044da:	f64080e7          	jalr	-156(ra) # 8000443a <itoa>
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ];
  uint off;

  if (0 == p->swapFile)
    800044de:	1684b503          	ld	a0,360(s1)
    800044e2:	16050763          	beqz	a0,80004650 <removeSwapFile+0x1a4>
  {
    return -1;
  }
  fileclose(p->swapFile);
    800044e6:	00001097          	auipc	ra,0x1
    800044ea:	914080e7          	jalr	-1772(ra) # 80004dfa <fileclose>

  begin_op();
    800044ee:	00000097          	auipc	ra,0x0
    800044f2:	440080e7          	jalr	1088(ra) # 8000492e <begin_op>
  if ((dp = nameiparent(path, name)) == 0)
    800044f6:	fb040593          	addi	a1,s0,-80
    800044fa:	fd040513          	addi	a0,s0,-48
    800044fe:	00000097          	auipc	ra,0x0
    80004502:	f20080e7          	jalr	-224(ra) # 8000441e <nameiparent>
    80004506:	892a                	mv	s2,a0
    80004508:	cd69                	beqz	a0,800045e2 <removeSwapFile+0x136>
  {
    end_op();
    return -1;
  }

  ilock(dp);
    8000450a:	fffff097          	auipc	ra,0xfffff
    8000450e:	750080e7          	jalr	1872(ra) # 80003c5a <ilock>

  // Cannot unlink "." or "..".
  if (namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80004512:	00004597          	auipc	a1,0x4
    80004516:	1d658593          	addi	a1,a1,470 # 800086e8 <syscalls+0x1f0>
    8000451a:	fb040513          	addi	a0,s0,-80
    8000451e:	00000097          	auipc	ra,0x0
    80004522:	c06080e7          	jalr	-1018(ra) # 80004124 <namecmp>
    80004526:	c57d                	beqz	a0,80004614 <removeSwapFile+0x168>
    80004528:	00004597          	auipc	a1,0x4
    8000452c:	1c858593          	addi	a1,a1,456 # 800086f0 <syscalls+0x1f8>
    80004530:	fb040513          	addi	a0,s0,-80
    80004534:	00000097          	auipc	ra,0x0
    80004538:	bf0080e7          	jalr	-1040(ra) # 80004124 <namecmp>
    8000453c:	cd61                	beqz	a0,80004614 <removeSwapFile+0x168>
    goto bad;

  if ((ip = dirlookup(dp, name, &off)) == 0)
    8000453e:	fac40613          	addi	a2,s0,-84
    80004542:	fb040593          	addi	a1,s0,-80
    80004546:	854a                	mv	a0,s2
    80004548:	00000097          	auipc	ra,0x0
    8000454c:	bf6080e7          	jalr	-1034(ra) # 8000413e <dirlookup>
    80004550:	84aa                	mv	s1,a0
    80004552:	c169                	beqz	a0,80004614 <removeSwapFile+0x168>
    goto bad;
  ilock(ip);
    80004554:	fffff097          	auipc	ra,0xfffff
    80004558:	706080e7          	jalr	1798(ra) # 80003c5a <ilock>

  if (ip->nlink < 1)
    8000455c:	04a49783          	lh	a5,74(s1)
    80004560:	08f05763          	blez	a5,800045ee <removeSwapFile+0x142>
    panic("unlink: nlink < 1");
  if (ip->type == T_DIR && !isdirempty(ip))
    80004564:	04449703          	lh	a4,68(s1)
    80004568:	4785                	li	a5,1
    8000456a:	08f70a63          	beq	a4,a5,800045fe <removeSwapFile+0x152>
  {
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    8000456e:	4641                	li	a2,16
    80004570:	4581                	li	a1,0
    80004572:	fc040513          	addi	a0,s0,-64
    80004576:	ffffc097          	auipc	ra,0xffffc
    8000457a:	75c080e7          	jalr	1884(ra) # 80000cd2 <memset>
  if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000457e:	4741                	li	a4,16
    80004580:	fac42683          	lw	a3,-84(s0)
    80004584:	fc040613          	addi	a2,s0,-64
    80004588:	4581                	li	a1,0
    8000458a:	854a                	mv	a0,s2
    8000458c:	00000097          	auipc	ra,0x0
    80004590:	a7a080e7          	jalr	-1414(ra) # 80004006 <writei>
    80004594:	47c1                	li	a5,16
    80004596:	08f51a63          	bne	a0,a5,8000462a <removeSwapFile+0x17e>
    panic("unlink: writei");
  if (ip->type == T_DIR)
    8000459a:	04449703          	lh	a4,68(s1)
    8000459e:	4785                	li	a5,1
    800045a0:	08f70d63          	beq	a4,a5,8000463a <removeSwapFile+0x18e>
  {
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    800045a4:	854a                	mv	a0,s2
    800045a6:	00000097          	auipc	ra,0x0
    800045aa:	916080e7          	jalr	-1770(ra) # 80003ebc <iunlockput>

  ip->nlink--;
    800045ae:	04a4d783          	lhu	a5,74(s1)
    800045b2:	37fd                	addiw	a5,a5,-1
    800045b4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800045b8:	8526                	mv	a0,s1
    800045ba:	fffff097          	auipc	ra,0xfffff
    800045be:	5d6080e7          	jalr	1494(ra) # 80003b90 <iupdate>
  iunlockput(ip);
    800045c2:	8526                	mv	a0,s1
    800045c4:	00000097          	auipc	ra,0x0
    800045c8:	8f8080e7          	jalr	-1800(ra) # 80003ebc <iunlockput>

  end_op();
    800045cc:	00000097          	auipc	ra,0x0
    800045d0:	3e2080e7          	jalr	994(ra) # 800049ae <end_op>

  return 0;
    800045d4:	4501                	li	a0,0

bad:
  iunlockput(dp);
  end_op();
  return -1;
}
    800045d6:	60e6                	ld	ra,88(sp)
    800045d8:	6446                	ld	s0,80(sp)
    800045da:	64a6                	ld	s1,72(sp)
    800045dc:	6906                	ld	s2,64(sp)
    800045de:	6125                	addi	sp,sp,96
    800045e0:	8082                	ret
    end_op();
    800045e2:	00000097          	auipc	ra,0x0
    800045e6:	3cc080e7          	jalr	972(ra) # 800049ae <end_op>
    return -1;
    800045ea:	557d                	li	a0,-1
    800045ec:	b7ed                	j	800045d6 <removeSwapFile+0x12a>
    panic("unlink: nlink < 1");
    800045ee:	00004517          	auipc	a0,0x4
    800045f2:	10a50513          	addi	a0,a0,266 # 800086f8 <syscalls+0x200>
    800045f6:	ffffc097          	auipc	ra,0xffffc
    800045fa:	f48080e7          	jalr	-184(ra) # 8000053e <panic>
  if (ip->type == T_DIR && !isdirempty(ip))
    800045fe:	8526                	mv	a0,s1
    80004600:	00002097          	auipc	ra,0x2
    80004604:	80a080e7          	jalr	-2038(ra) # 80005e0a <isdirempty>
    80004608:	f13d                	bnez	a0,8000456e <removeSwapFile+0xc2>
    iunlockput(ip);
    8000460a:	8526                	mv	a0,s1
    8000460c:	00000097          	auipc	ra,0x0
    80004610:	8b0080e7          	jalr	-1872(ra) # 80003ebc <iunlockput>
  iunlockput(dp);
    80004614:	854a                	mv	a0,s2
    80004616:	00000097          	auipc	ra,0x0
    8000461a:	8a6080e7          	jalr	-1882(ra) # 80003ebc <iunlockput>
  end_op();
    8000461e:	00000097          	auipc	ra,0x0
    80004622:	390080e7          	jalr	912(ra) # 800049ae <end_op>
  return -1;
    80004626:	557d                	li	a0,-1
    80004628:	b77d                	j	800045d6 <removeSwapFile+0x12a>
    panic("unlink: writei");
    8000462a:	00004517          	auipc	a0,0x4
    8000462e:	0e650513          	addi	a0,a0,230 # 80008710 <syscalls+0x218>
    80004632:	ffffc097          	auipc	ra,0xffffc
    80004636:	f0c080e7          	jalr	-244(ra) # 8000053e <panic>
    dp->nlink--;
    8000463a:	04a95783          	lhu	a5,74(s2)
    8000463e:	37fd                	addiw	a5,a5,-1
    80004640:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80004644:	854a                	mv	a0,s2
    80004646:	fffff097          	auipc	ra,0xfffff
    8000464a:	54a080e7          	jalr	1354(ra) # 80003b90 <iupdate>
    8000464e:	bf99                	j	800045a4 <removeSwapFile+0xf8>
    return -1;
    80004650:	557d                	li	a0,-1
    80004652:	b751                	j	800045d6 <removeSwapFile+0x12a>

0000000080004654 <createSwapFile>:

// return 0 on success
int createSwapFile(struct proc *p)
{
    80004654:	7179                	addi	sp,sp,-48
    80004656:	f406                	sd	ra,40(sp)
    80004658:	f022                	sd	s0,32(sp)
    8000465a:	ec26                	sd	s1,24(sp)
    8000465c:	e84a                	sd	s2,16(sp)
    8000465e:	1800                	addi	s0,sp,48
    80004660:	84aa                	mv	s1,a0

  char path[DIGITS];
  memmove(path, "/.swap", 6);
    80004662:	4619                	li	a2,6
    80004664:	00004597          	auipc	a1,0x4
    80004668:	07c58593          	addi	a1,a1,124 # 800086e0 <syscalls+0x1e8>
    8000466c:	fd040513          	addi	a0,s0,-48
    80004670:	ffffc097          	auipc	ra,0xffffc
    80004674:	6be080e7          	jalr	1726(ra) # 80000d2e <memmove>
  itoa(p->pid, path + 6);
    80004678:	fd640593          	addi	a1,s0,-42
    8000467c:	5888                	lw	a0,48(s1)
    8000467e:	00000097          	auipc	ra,0x0
    80004682:	dbc080e7          	jalr	-580(ra) # 8000443a <itoa>

  begin_op();
    80004686:	00000097          	auipc	ra,0x0
    8000468a:	2a8080e7          	jalr	680(ra) # 8000492e <begin_op>

  struct inode *in = create(path, T_FILE, 0, 0);
    8000468e:	4681                	li	a3,0
    80004690:	4601                	li	a2,0
    80004692:	4589                	li	a1,2
    80004694:	fd040513          	addi	a0,s0,-48
    80004698:	00002097          	auipc	ra,0x2
    8000469c:	966080e7          	jalr	-1690(ra) # 80005ffe <create>
    800046a0:	892a                	mv	s2,a0
  iunlock(in);
    800046a2:	fffff097          	auipc	ra,0xfffff
    800046a6:	67a080e7          	jalr	1658(ra) # 80003d1c <iunlock>
  p->swapFile = filealloc();
    800046aa:	00000097          	auipc	ra,0x0
    800046ae:	694080e7          	jalr	1684(ra) # 80004d3e <filealloc>
    800046b2:	16a4b423          	sd	a0,360(s1)
  if (p->swapFile == 0)
    800046b6:	cd1d                	beqz	a0,800046f4 <createSwapFile+0xa0>
    panic("no slot for files on /store");

  p->swapFile->ip = in;
    800046b8:	01253c23          	sd	s2,24(a0)
  p->swapFile->type = FD_INODE;
    800046bc:	1684b703          	ld	a4,360(s1)
    800046c0:	4789                	li	a5,2
    800046c2:	c31c                	sw	a5,0(a4)
  p->swapFile->off = 0;
    800046c4:	1684b703          	ld	a4,360(s1)
    800046c8:	02072023          	sw	zero,32(a4) # 43020 <_entry-0x7ffbcfe0>
  p->swapFile->readable = O_WRONLY;
    800046cc:	1684b703          	ld	a4,360(s1)
    800046d0:	4685                	li	a3,1
    800046d2:	00d70423          	sb	a3,8(a4)
  p->swapFile->writable = O_RDWR;
    800046d6:	1684b703          	ld	a4,360(s1)
    800046da:	00f704a3          	sb	a5,9(a4)
  end_op();
    800046de:	00000097          	auipc	ra,0x0
    800046e2:	2d0080e7          	jalr	720(ra) # 800049ae <end_op>

  return 0;
}
    800046e6:	4501                	li	a0,0
    800046e8:	70a2                	ld	ra,40(sp)
    800046ea:	7402                	ld	s0,32(sp)
    800046ec:	64e2                	ld	s1,24(sp)
    800046ee:	6942                	ld	s2,16(sp)
    800046f0:	6145                	addi	sp,sp,48
    800046f2:	8082                	ret
    panic("no slot for files on /store");
    800046f4:	00004517          	auipc	a0,0x4
    800046f8:	02c50513          	addi	a0,a0,44 # 80008720 <syscalls+0x228>
    800046fc:	ffffc097          	auipc	ra,0xffffc
    80004700:	e42080e7          	jalr	-446(ra) # 8000053e <panic>

0000000080004704 <writeToSwapFile>:

// return as sys_write (-1 when error)
int writeToSwapFile(struct proc *p, char *buffer, uint placeOnFile, uint size)
{
    80004704:	1141                	addi	sp,sp,-16
    80004706:	e406                	sd	ra,8(sp)
    80004708:	e022                	sd	s0,0(sp)
    8000470a:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    8000470c:	16853783          	ld	a5,360(a0)
    80004710:	d390                	sw	a2,32(a5)
  return kfilewrite(p->swapFile, (uint64)buffer, size);
    80004712:	8636                	mv	a2,a3
    80004714:	16853503          	ld	a0,360(a0)
    80004718:	00001097          	auipc	ra,0x1
    8000471c:	ad4080e7          	jalr	-1324(ra) # 800051ec <kfilewrite>
}
    80004720:	60a2                	ld	ra,8(sp)
    80004722:	6402                	ld	s0,0(sp)
    80004724:	0141                	addi	sp,sp,16
    80004726:	8082                	ret

0000000080004728 <readFromSwapFile>:

// return as sys_read (-1 when error)
int readFromSwapFile(struct proc *p, char *buffer, uint placeOnFile, uint size)
{
    80004728:	1141                	addi	sp,sp,-16
    8000472a:	e406                	sd	ra,8(sp)
    8000472c:	e022                	sd	s0,0(sp)
    8000472e:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    80004730:	16853783          	ld	a5,360(a0)
    80004734:	d390                	sw	a2,32(a5)
  return kfileread(p->swapFile, (uint64)buffer, size);
    80004736:	8636                	mv	a2,a3
    80004738:	16853503          	ld	a0,360(a0)
    8000473c:	00001097          	auipc	ra,0x1
    80004740:	9ee080e7          	jalr	-1554(ra) # 8000512a <kfileread>
    80004744:	60a2                	ld	ra,8(sp)
    80004746:	6402                	ld	s0,0(sp)
    80004748:	0141                	addi	sp,sp,16
    8000474a:	8082                	ret

000000008000474c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000474c:	1101                	addi	sp,sp,-32
    8000474e:	ec06                	sd	ra,24(sp)
    80004750:	e822                	sd	s0,16(sp)
    80004752:	e426                	sd	s1,8(sp)
    80004754:	e04a                	sd	s2,0(sp)
    80004756:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004758:	00031917          	auipc	s2,0x31
    8000475c:	ca890913          	addi	s2,s2,-856 # 80035400 <log>
    80004760:	01892583          	lw	a1,24(s2)
    80004764:	02892503          	lw	a0,40(s2)
    80004768:	fffff097          	auipc	ra,0xfffff
    8000476c:	cd8080e7          	jalr	-808(ra) # 80003440 <bread>
    80004770:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004772:	02c92683          	lw	a3,44(s2)
    80004776:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004778:	02d05763          	blez	a3,800047a6 <write_head+0x5a>
    8000477c:	00031797          	auipc	a5,0x31
    80004780:	cb478793          	addi	a5,a5,-844 # 80035430 <log+0x30>
    80004784:	05c50713          	addi	a4,a0,92
    80004788:	36fd                	addiw	a3,a3,-1
    8000478a:	1682                	slli	a3,a3,0x20
    8000478c:	9281                	srli	a3,a3,0x20
    8000478e:	068a                	slli	a3,a3,0x2
    80004790:	00031617          	auipc	a2,0x31
    80004794:	ca460613          	addi	a2,a2,-860 # 80035434 <log+0x34>
    80004798:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000479a:	4390                	lw	a2,0(a5)
    8000479c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000479e:	0791                	addi	a5,a5,4
    800047a0:	0711                	addi	a4,a4,4
    800047a2:	fed79ce3          	bne	a5,a3,8000479a <write_head+0x4e>
  }
  bwrite(buf);
    800047a6:	8526                	mv	a0,s1
    800047a8:	fffff097          	auipc	ra,0xfffff
    800047ac:	d8a080e7          	jalr	-630(ra) # 80003532 <bwrite>
  brelse(buf);
    800047b0:	8526                	mv	a0,s1
    800047b2:	fffff097          	auipc	ra,0xfffff
    800047b6:	dbe080e7          	jalr	-578(ra) # 80003570 <brelse>
}
    800047ba:	60e2                	ld	ra,24(sp)
    800047bc:	6442                	ld	s0,16(sp)
    800047be:	64a2                	ld	s1,8(sp)
    800047c0:	6902                	ld	s2,0(sp)
    800047c2:	6105                	addi	sp,sp,32
    800047c4:	8082                	ret

00000000800047c6 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800047c6:	00031797          	auipc	a5,0x31
    800047ca:	c667a783          	lw	a5,-922(a5) # 8003542c <log+0x2c>
    800047ce:	0af05d63          	blez	a5,80004888 <install_trans+0xc2>
{
    800047d2:	7139                	addi	sp,sp,-64
    800047d4:	fc06                	sd	ra,56(sp)
    800047d6:	f822                	sd	s0,48(sp)
    800047d8:	f426                	sd	s1,40(sp)
    800047da:	f04a                	sd	s2,32(sp)
    800047dc:	ec4e                	sd	s3,24(sp)
    800047de:	e852                	sd	s4,16(sp)
    800047e0:	e456                	sd	s5,8(sp)
    800047e2:	e05a                	sd	s6,0(sp)
    800047e4:	0080                	addi	s0,sp,64
    800047e6:	8b2a                	mv	s6,a0
    800047e8:	00031a97          	auipc	s5,0x31
    800047ec:	c48a8a93          	addi	s5,s5,-952 # 80035430 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047f0:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800047f2:	00031997          	auipc	s3,0x31
    800047f6:	c0e98993          	addi	s3,s3,-1010 # 80035400 <log>
    800047fa:	a00d                	j	8000481c <install_trans+0x56>
    brelse(lbuf);
    800047fc:	854a                	mv	a0,s2
    800047fe:	fffff097          	auipc	ra,0xfffff
    80004802:	d72080e7          	jalr	-654(ra) # 80003570 <brelse>
    brelse(dbuf);
    80004806:	8526                	mv	a0,s1
    80004808:	fffff097          	auipc	ra,0xfffff
    8000480c:	d68080e7          	jalr	-664(ra) # 80003570 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004810:	2a05                	addiw	s4,s4,1
    80004812:	0a91                	addi	s5,s5,4
    80004814:	02c9a783          	lw	a5,44(s3)
    80004818:	04fa5e63          	bge	s4,a5,80004874 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000481c:	0189a583          	lw	a1,24(s3)
    80004820:	014585bb          	addw	a1,a1,s4
    80004824:	2585                	addiw	a1,a1,1
    80004826:	0289a503          	lw	a0,40(s3)
    8000482a:	fffff097          	auipc	ra,0xfffff
    8000482e:	c16080e7          	jalr	-1002(ra) # 80003440 <bread>
    80004832:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004834:	000aa583          	lw	a1,0(s5)
    80004838:	0289a503          	lw	a0,40(s3)
    8000483c:	fffff097          	auipc	ra,0xfffff
    80004840:	c04080e7          	jalr	-1020(ra) # 80003440 <bread>
    80004844:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004846:	40000613          	li	a2,1024
    8000484a:	05890593          	addi	a1,s2,88
    8000484e:	05850513          	addi	a0,a0,88
    80004852:	ffffc097          	auipc	ra,0xffffc
    80004856:	4dc080e7          	jalr	1244(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    8000485a:	8526                	mv	a0,s1
    8000485c:	fffff097          	auipc	ra,0xfffff
    80004860:	cd6080e7          	jalr	-810(ra) # 80003532 <bwrite>
    if(recovering == 0)
    80004864:	f80b1ce3          	bnez	s6,800047fc <install_trans+0x36>
      bunpin(dbuf);
    80004868:	8526                	mv	a0,s1
    8000486a:	fffff097          	auipc	ra,0xfffff
    8000486e:	de0080e7          	jalr	-544(ra) # 8000364a <bunpin>
    80004872:	b769                	j	800047fc <install_trans+0x36>
}
    80004874:	70e2                	ld	ra,56(sp)
    80004876:	7442                	ld	s0,48(sp)
    80004878:	74a2                	ld	s1,40(sp)
    8000487a:	7902                	ld	s2,32(sp)
    8000487c:	69e2                	ld	s3,24(sp)
    8000487e:	6a42                	ld	s4,16(sp)
    80004880:	6aa2                	ld	s5,8(sp)
    80004882:	6b02                	ld	s6,0(sp)
    80004884:	6121                	addi	sp,sp,64
    80004886:	8082                	ret
    80004888:	8082                	ret

000000008000488a <initlog>:
{
    8000488a:	7179                	addi	sp,sp,-48
    8000488c:	f406                	sd	ra,40(sp)
    8000488e:	f022                	sd	s0,32(sp)
    80004890:	ec26                	sd	s1,24(sp)
    80004892:	e84a                	sd	s2,16(sp)
    80004894:	e44e                	sd	s3,8(sp)
    80004896:	1800                	addi	s0,sp,48
    80004898:	892a                	mv	s2,a0
    8000489a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000489c:	00031497          	auipc	s1,0x31
    800048a0:	b6448493          	addi	s1,s1,-1180 # 80035400 <log>
    800048a4:	00004597          	auipc	a1,0x4
    800048a8:	e9c58593          	addi	a1,a1,-356 # 80008740 <syscalls+0x248>
    800048ac:	8526                	mv	a0,s1
    800048ae:	ffffc097          	auipc	ra,0xffffc
    800048b2:	298080e7          	jalr	664(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    800048b6:	0149a583          	lw	a1,20(s3)
    800048ba:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800048bc:	0109a783          	lw	a5,16(s3)
    800048c0:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800048c2:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800048c6:	854a                	mv	a0,s2
    800048c8:	fffff097          	auipc	ra,0xfffff
    800048cc:	b78080e7          	jalr	-1160(ra) # 80003440 <bread>
  log.lh.n = lh->n;
    800048d0:	4d34                	lw	a3,88(a0)
    800048d2:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800048d4:	02d05563          	blez	a3,800048fe <initlog+0x74>
    800048d8:	05c50793          	addi	a5,a0,92
    800048dc:	00031717          	auipc	a4,0x31
    800048e0:	b5470713          	addi	a4,a4,-1196 # 80035430 <log+0x30>
    800048e4:	36fd                	addiw	a3,a3,-1
    800048e6:	1682                	slli	a3,a3,0x20
    800048e8:	9281                	srli	a3,a3,0x20
    800048ea:	068a                	slli	a3,a3,0x2
    800048ec:	06050613          	addi	a2,a0,96
    800048f0:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800048f2:	4390                	lw	a2,0(a5)
    800048f4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800048f6:	0791                	addi	a5,a5,4
    800048f8:	0711                	addi	a4,a4,4
    800048fa:	fed79ce3          	bne	a5,a3,800048f2 <initlog+0x68>
  brelse(buf);
    800048fe:	fffff097          	auipc	ra,0xfffff
    80004902:	c72080e7          	jalr	-910(ra) # 80003570 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004906:	4505                	li	a0,1
    80004908:	00000097          	auipc	ra,0x0
    8000490c:	ebe080e7          	jalr	-322(ra) # 800047c6 <install_trans>
  log.lh.n = 0;
    80004910:	00031797          	auipc	a5,0x31
    80004914:	b007ae23          	sw	zero,-1252(a5) # 8003542c <log+0x2c>
  write_head(); // clear the log
    80004918:	00000097          	auipc	ra,0x0
    8000491c:	e34080e7          	jalr	-460(ra) # 8000474c <write_head>
}
    80004920:	70a2                	ld	ra,40(sp)
    80004922:	7402                	ld	s0,32(sp)
    80004924:	64e2                	ld	s1,24(sp)
    80004926:	6942                	ld	s2,16(sp)
    80004928:	69a2                	ld	s3,8(sp)
    8000492a:	6145                	addi	sp,sp,48
    8000492c:	8082                	ret

000000008000492e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000492e:	1101                	addi	sp,sp,-32
    80004930:	ec06                	sd	ra,24(sp)
    80004932:	e822                	sd	s0,16(sp)
    80004934:	e426                	sd	s1,8(sp)
    80004936:	e04a                	sd	s2,0(sp)
    80004938:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000493a:	00031517          	auipc	a0,0x31
    8000493e:	ac650513          	addi	a0,a0,-1338 # 80035400 <log>
    80004942:	ffffc097          	auipc	ra,0xffffc
    80004946:	294080e7          	jalr	660(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    8000494a:	00031497          	auipc	s1,0x31
    8000494e:	ab648493          	addi	s1,s1,-1354 # 80035400 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004952:	4979                	li	s2,30
    80004954:	a039                	j	80004962 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004956:	85a6                	mv	a1,s1
    80004958:	8526                	mv	a0,s1
    8000495a:	ffffe097          	auipc	ra,0xffffe
    8000495e:	8f4080e7          	jalr	-1804(ra) # 8000224e <sleep>
    if(log.committing){
    80004962:	50dc                	lw	a5,36(s1)
    80004964:	fbed                	bnez	a5,80004956 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004966:	509c                	lw	a5,32(s1)
    80004968:	0017871b          	addiw	a4,a5,1
    8000496c:	0007069b          	sext.w	a3,a4
    80004970:	0027179b          	slliw	a5,a4,0x2
    80004974:	9fb9                	addw	a5,a5,a4
    80004976:	0017979b          	slliw	a5,a5,0x1
    8000497a:	54d8                	lw	a4,44(s1)
    8000497c:	9fb9                	addw	a5,a5,a4
    8000497e:	00f95963          	bge	s2,a5,80004990 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004982:	85a6                	mv	a1,s1
    80004984:	8526                	mv	a0,s1
    80004986:	ffffe097          	auipc	ra,0xffffe
    8000498a:	8c8080e7          	jalr	-1848(ra) # 8000224e <sleep>
    8000498e:	bfd1                	j	80004962 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004990:	00031517          	auipc	a0,0x31
    80004994:	a7050513          	addi	a0,a0,-1424 # 80035400 <log>
    80004998:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000499a:	ffffc097          	auipc	ra,0xffffc
    8000499e:	2f0080e7          	jalr	752(ra) # 80000c8a <release>
      break;
    }
  }
}
    800049a2:	60e2                	ld	ra,24(sp)
    800049a4:	6442                	ld	s0,16(sp)
    800049a6:	64a2                	ld	s1,8(sp)
    800049a8:	6902                	ld	s2,0(sp)
    800049aa:	6105                	addi	sp,sp,32
    800049ac:	8082                	ret

00000000800049ae <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800049ae:	7139                	addi	sp,sp,-64
    800049b0:	fc06                	sd	ra,56(sp)
    800049b2:	f822                	sd	s0,48(sp)
    800049b4:	f426                	sd	s1,40(sp)
    800049b6:	f04a                	sd	s2,32(sp)
    800049b8:	ec4e                	sd	s3,24(sp)
    800049ba:	e852                	sd	s4,16(sp)
    800049bc:	e456                	sd	s5,8(sp)
    800049be:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800049c0:	00031497          	auipc	s1,0x31
    800049c4:	a4048493          	addi	s1,s1,-1472 # 80035400 <log>
    800049c8:	8526                	mv	a0,s1
    800049ca:	ffffc097          	auipc	ra,0xffffc
    800049ce:	20c080e7          	jalr	524(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800049d2:	509c                	lw	a5,32(s1)
    800049d4:	37fd                	addiw	a5,a5,-1
    800049d6:	0007891b          	sext.w	s2,a5
    800049da:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800049dc:	50dc                	lw	a5,36(s1)
    800049de:	e7b9                	bnez	a5,80004a2c <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800049e0:	04091e63          	bnez	s2,80004a3c <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800049e4:	00031497          	auipc	s1,0x31
    800049e8:	a1c48493          	addi	s1,s1,-1508 # 80035400 <log>
    800049ec:	4785                	li	a5,1
    800049ee:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800049f0:	8526                	mv	a0,s1
    800049f2:	ffffc097          	auipc	ra,0xffffc
    800049f6:	298080e7          	jalr	664(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800049fa:	54dc                	lw	a5,44(s1)
    800049fc:	06f04763          	bgtz	a5,80004a6a <end_op+0xbc>
    acquire(&log.lock);
    80004a00:	00031497          	auipc	s1,0x31
    80004a04:	a0048493          	addi	s1,s1,-1536 # 80035400 <log>
    80004a08:	8526                	mv	a0,s1
    80004a0a:	ffffc097          	auipc	ra,0xffffc
    80004a0e:	1cc080e7          	jalr	460(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004a12:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004a16:	8526                	mv	a0,s1
    80004a18:	ffffe097          	auipc	ra,0xffffe
    80004a1c:	89a080e7          	jalr	-1894(ra) # 800022b2 <wakeup>
    release(&log.lock);
    80004a20:	8526                	mv	a0,s1
    80004a22:	ffffc097          	auipc	ra,0xffffc
    80004a26:	268080e7          	jalr	616(ra) # 80000c8a <release>
}
    80004a2a:	a03d                	j	80004a58 <end_op+0xaa>
    panic("log.committing");
    80004a2c:	00004517          	auipc	a0,0x4
    80004a30:	d1c50513          	addi	a0,a0,-740 # 80008748 <syscalls+0x250>
    80004a34:	ffffc097          	auipc	ra,0xffffc
    80004a38:	b0a080e7          	jalr	-1270(ra) # 8000053e <panic>
    wakeup(&log);
    80004a3c:	00031497          	auipc	s1,0x31
    80004a40:	9c448493          	addi	s1,s1,-1596 # 80035400 <log>
    80004a44:	8526                	mv	a0,s1
    80004a46:	ffffe097          	auipc	ra,0xffffe
    80004a4a:	86c080e7          	jalr	-1940(ra) # 800022b2 <wakeup>
  release(&log.lock);
    80004a4e:	8526                	mv	a0,s1
    80004a50:	ffffc097          	auipc	ra,0xffffc
    80004a54:	23a080e7          	jalr	570(ra) # 80000c8a <release>
}
    80004a58:	70e2                	ld	ra,56(sp)
    80004a5a:	7442                	ld	s0,48(sp)
    80004a5c:	74a2                	ld	s1,40(sp)
    80004a5e:	7902                	ld	s2,32(sp)
    80004a60:	69e2                	ld	s3,24(sp)
    80004a62:	6a42                	ld	s4,16(sp)
    80004a64:	6aa2                	ld	s5,8(sp)
    80004a66:	6121                	addi	sp,sp,64
    80004a68:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a6a:	00031a97          	auipc	s5,0x31
    80004a6e:	9c6a8a93          	addi	s5,s5,-1594 # 80035430 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004a72:	00031a17          	auipc	s4,0x31
    80004a76:	98ea0a13          	addi	s4,s4,-1650 # 80035400 <log>
    80004a7a:	018a2583          	lw	a1,24(s4)
    80004a7e:	012585bb          	addw	a1,a1,s2
    80004a82:	2585                	addiw	a1,a1,1
    80004a84:	028a2503          	lw	a0,40(s4)
    80004a88:	fffff097          	auipc	ra,0xfffff
    80004a8c:	9b8080e7          	jalr	-1608(ra) # 80003440 <bread>
    80004a90:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004a92:	000aa583          	lw	a1,0(s5)
    80004a96:	028a2503          	lw	a0,40(s4)
    80004a9a:	fffff097          	auipc	ra,0xfffff
    80004a9e:	9a6080e7          	jalr	-1626(ra) # 80003440 <bread>
    80004aa2:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004aa4:	40000613          	li	a2,1024
    80004aa8:	05850593          	addi	a1,a0,88
    80004aac:	05848513          	addi	a0,s1,88
    80004ab0:	ffffc097          	auipc	ra,0xffffc
    80004ab4:	27e080e7          	jalr	638(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004ab8:	8526                	mv	a0,s1
    80004aba:	fffff097          	auipc	ra,0xfffff
    80004abe:	a78080e7          	jalr	-1416(ra) # 80003532 <bwrite>
    brelse(from);
    80004ac2:	854e                	mv	a0,s3
    80004ac4:	fffff097          	auipc	ra,0xfffff
    80004ac8:	aac080e7          	jalr	-1364(ra) # 80003570 <brelse>
    brelse(to);
    80004acc:	8526                	mv	a0,s1
    80004ace:	fffff097          	auipc	ra,0xfffff
    80004ad2:	aa2080e7          	jalr	-1374(ra) # 80003570 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ad6:	2905                	addiw	s2,s2,1
    80004ad8:	0a91                	addi	s5,s5,4
    80004ada:	02ca2783          	lw	a5,44(s4)
    80004ade:	f8f94ee3          	blt	s2,a5,80004a7a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004ae2:	00000097          	auipc	ra,0x0
    80004ae6:	c6a080e7          	jalr	-918(ra) # 8000474c <write_head>
    install_trans(0); // Now install writes to home locations
    80004aea:	4501                	li	a0,0
    80004aec:	00000097          	auipc	ra,0x0
    80004af0:	cda080e7          	jalr	-806(ra) # 800047c6 <install_trans>
    log.lh.n = 0;
    80004af4:	00031797          	auipc	a5,0x31
    80004af8:	9207ac23          	sw	zero,-1736(a5) # 8003542c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004afc:	00000097          	auipc	ra,0x0
    80004b00:	c50080e7          	jalr	-944(ra) # 8000474c <write_head>
    80004b04:	bdf5                	j	80004a00 <end_op+0x52>

0000000080004b06 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004b06:	1101                	addi	sp,sp,-32
    80004b08:	ec06                	sd	ra,24(sp)
    80004b0a:	e822                	sd	s0,16(sp)
    80004b0c:	e426                	sd	s1,8(sp)
    80004b0e:	e04a                	sd	s2,0(sp)
    80004b10:	1000                	addi	s0,sp,32
    80004b12:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004b14:	00031917          	auipc	s2,0x31
    80004b18:	8ec90913          	addi	s2,s2,-1812 # 80035400 <log>
    80004b1c:	854a                	mv	a0,s2
    80004b1e:	ffffc097          	auipc	ra,0xffffc
    80004b22:	0b8080e7          	jalr	184(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004b26:	02c92603          	lw	a2,44(s2)
    80004b2a:	47f5                	li	a5,29
    80004b2c:	06c7c563          	blt	a5,a2,80004b96 <log_write+0x90>
    80004b30:	00031797          	auipc	a5,0x31
    80004b34:	8ec7a783          	lw	a5,-1812(a5) # 8003541c <log+0x1c>
    80004b38:	37fd                	addiw	a5,a5,-1
    80004b3a:	04f65e63          	bge	a2,a5,80004b96 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004b3e:	00031797          	auipc	a5,0x31
    80004b42:	8e27a783          	lw	a5,-1822(a5) # 80035420 <log+0x20>
    80004b46:	06f05063          	blez	a5,80004ba6 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004b4a:	4781                	li	a5,0
    80004b4c:	06c05563          	blez	a2,80004bb6 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004b50:	44cc                	lw	a1,12(s1)
    80004b52:	00031717          	auipc	a4,0x31
    80004b56:	8de70713          	addi	a4,a4,-1826 # 80035430 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004b5a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004b5c:	4314                	lw	a3,0(a4)
    80004b5e:	04b68c63          	beq	a3,a1,80004bb6 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004b62:	2785                	addiw	a5,a5,1
    80004b64:	0711                	addi	a4,a4,4
    80004b66:	fef61be3          	bne	a2,a5,80004b5c <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004b6a:	0621                	addi	a2,a2,8
    80004b6c:	060a                	slli	a2,a2,0x2
    80004b6e:	00031797          	auipc	a5,0x31
    80004b72:	89278793          	addi	a5,a5,-1902 # 80035400 <log>
    80004b76:	963e                	add	a2,a2,a5
    80004b78:	44dc                	lw	a5,12(s1)
    80004b7a:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004b7c:	8526                	mv	a0,s1
    80004b7e:	fffff097          	auipc	ra,0xfffff
    80004b82:	a90080e7          	jalr	-1392(ra) # 8000360e <bpin>
    log.lh.n++;
    80004b86:	00031717          	auipc	a4,0x31
    80004b8a:	87a70713          	addi	a4,a4,-1926 # 80035400 <log>
    80004b8e:	575c                	lw	a5,44(a4)
    80004b90:	2785                	addiw	a5,a5,1
    80004b92:	d75c                	sw	a5,44(a4)
    80004b94:	a835                	j	80004bd0 <log_write+0xca>
    panic("too big a transaction");
    80004b96:	00004517          	auipc	a0,0x4
    80004b9a:	bc250513          	addi	a0,a0,-1086 # 80008758 <syscalls+0x260>
    80004b9e:	ffffc097          	auipc	ra,0xffffc
    80004ba2:	9a0080e7          	jalr	-1632(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004ba6:	00004517          	auipc	a0,0x4
    80004baa:	bca50513          	addi	a0,a0,-1078 # 80008770 <syscalls+0x278>
    80004bae:	ffffc097          	auipc	ra,0xffffc
    80004bb2:	990080e7          	jalr	-1648(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004bb6:	00878713          	addi	a4,a5,8
    80004bba:	00271693          	slli	a3,a4,0x2
    80004bbe:	00031717          	auipc	a4,0x31
    80004bc2:	84270713          	addi	a4,a4,-1982 # 80035400 <log>
    80004bc6:	9736                	add	a4,a4,a3
    80004bc8:	44d4                	lw	a3,12(s1)
    80004bca:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004bcc:	faf608e3          	beq	a2,a5,80004b7c <log_write+0x76>
  }
  release(&log.lock);
    80004bd0:	00031517          	auipc	a0,0x31
    80004bd4:	83050513          	addi	a0,a0,-2000 # 80035400 <log>
    80004bd8:	ffffc097          	auipc	ra,0xffffc
    80004bdc:	0b2080e7          	jalr	178(ra) # 80000c8a <release>
}
    80004be0:	60e2                	ld	ra,24(sp)
    80004be2:	6442                	ld	s0,16(sp)
    80004be4:	64a2                	ld	s1,8(sp)
    80004be6:	6902                	ld	s2,0(sp)
    80004be8:	6105                	addi	sp,sp,32
    80004bea:	8082                	ret

0000000080004bec <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004bec:	1101                	addi	sp,sp,-32
    80004bee:	ec06                	sd	ra,24(sp)
    80004bf0:	e822                	sd	s0,16(sp)
    80004bf2:	e426                	sd	s1,8(sp)
    80004bf4:	e04a                	sd	s2,0(sp)
    80004bf6:	1000                	addi	s0,sp,32
    80004bf8:	84aa                	mv	s1,a0
    80004bfa:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004bfc:	00004597          	auipc	a1,0x4
    80004c00:	b9458593          	addi	a1,a1,-1132 # 80008790 <syscalls+0x298>
    80004c04:	0521                	addi	a0,a0,8
    80004c06:	ffffc097          	auipc	ra,0xffffc
    80004c0a:	f40080e7          	jalr	-192(ra) # 80000b46 <initlock>
  lk->name = name;
    80004c0e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004c12:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004c16:	0204a423          	sw	zero,40(s1)
}
    80004c1a:	60e2                	ld	ra,24(sp)
    80004c1c:	6442                	ld	s0,16(sp)
    80004c1e:	64a2                	ld	s1,8(sp)
    80004c20:	6902                	ld	s2,0(sp)
    80004c22:	6105                	addi	sp,sp,32
    80004c24:	8082                	ret

0000000080004c26 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004c26:	1101                	addi	sp,sp,-32
    80004c28:	ec06                	sd	ra,24(sp)
    80004c2a:	e822                	sd	s0,16(sp)
    80004c2c:	e426                	sd	s1,8(sp)
    80004c2e:	e04a                	sd	s2,0(sp)
    80004c30:	1000                	addi	s0,sp,32
    80004c32:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004c34:	00850913          	addi	s2,a0,8
    80004c38:	854a                	mv	a0,s2
    80004c3a:	ffffc097          	auipc	ra,0xffffc
    80004c3e:	f9c080e7          	jalr	-100(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004c42:	409c                	lw	a5,0(s1)
    80004c44:	cb89                	beqz	a5,80004c56 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004c46:	85ca                	mv	a1,s2
    80004c48:	8526                	mv	a0,s1
    80004c4a:	ffffd097          	auipc	ra,0xffffd
    80004c4e:	604080e7          	jalr	1540(ra) # 8000224e <sleep>
  while (lk->locked) {
    80004c52:	409c                	lw	a5,0(s1)
    80004c54:	fbed                	bnez	a5,80004c46 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004c56:	4785                	li	a5,1
    80004c58:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004c5a:	ffffd097          	auipc	ra,0xffffd
    80004c5e:	ea4080e7          	jalr	-348(ra) # 80001afe <myproc>
    80004c62:	591c                	lw	a5,48(a0)
    80004c64:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004c66:	854a                	mv	a0,s2
    80004c68:	ffffc097          	auipc	ra,0xffffc
    80004c6c:	022080e7          	jalr	34(ra) # 80000c8a <release>
}
    80004c70:	60e2                	ld	ra,24(sp)
    80004c72:	6442                	ld	s0,16(sp)
    80004c74:	64a2                	ld	s1,8(sp)
    80004c76:	6902                	ld	s2,0(sp)
    80004c78:	6105                	addi	sp,sp,32
    80004c7a:	8082                	ret

0000000080004c7c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004c7c:	1101                	addi	sp,sp,-32
    80004c7e:	ec06                	sd	ra,24(sp)
    80004c80:	e822                	sd	s0,16(sp)
    80004c82:	e426                	sd	s1,8(sp)
    80004c84:	e04a                	sd	s2,0(sp)
    80004c86:	1000                	addi	s0,sp,32
    80004c88:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004c8a:	00850913          	addi	s2,a0,8
    80004c8e:	854a                	mv	a0,s2
    80004c90:	ffffc097          	auipc	ra,0xffffc
    80004c94:	f46080e7          	jalr	-186(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004c98:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004c9c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004ca0:	8526                	mv	a0,s1
    80004ca2:	ffffd097          	auipc	ra,0xffffd
    80004ca6:	610080e7          	jalr	1552(ra) # 800022b2 <wakeup>
  release(&lk->lk);
    80004caa:	854a                	mv	a0,s2
    80004cac:	ffffc097          	auipc	ra,0xffffc
    80004cb0:	fde080e7          	jalr	-34(ra) # 80000c8a <release>
}
    80004cb4:	60e2                	ld	ra,24(sp)
    80004cb6:	6442                	ld	s0,16(sp)
    80004cb8:	64a2                	ld	s1,8(sp)
    80004cba:	6902                	ld	s2,0(sp)
    80004cbc:	6105                	addi	sp,sp,32
    80004cbe:	8082                	ret

0000000080004cc0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004cc0:	7179                	addi	sp,sp,-48
    80004cc2:	f406                	sd	ra,40(sp)
    80004cc4:	f022                	sd	s0,32(sp)
    80004cc6:	ec26                	sd	s1,24(sp)
    80004cc8:	e84a                	sd	s2,16(sp)
    80004cca:	e44e                	sd	s3,8(sp)
    80004ccc:	1800                	addi	s0,sp,48
    80004cce:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004cd0:	00850913          	addi	s2,a0,8
    80004cd4:	854a                	mv	a0,s2
    80004cd6:	ffffc097          	auipc	ra,0xffffc
    80004cda:	f00080e7          	jalr	-256(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004cde:	409c                	lw	a5,0(s1)
    80004ce0:	ef99                	bnez	a5,80004cfe <holdingsleep+0x3e>
    80004ce2:	4481                	li	s1,0
  release(&lk->lk);
    80004ce4:	854a                	mv	a0,s2
    80004ce6:	ffffc097          	auipc	ra,0xffffc
    80004cea:	fa4080e7          	jalr	-92(ra) # 80000c8a <release>
  return r;
}
    80004cee:	8526                	mv	a0,s1
    80004cf0:	70a2                	ld	ra,40(sp)
    80004cf2:	7402                	ld	s0,32(sp)
    80004cf4:	64e2                	ld	s1,24(sp)
    80004cf6:	6942                	ld	s2,16(sp)
    80004cf8:	69a2                	ld	s3,8(sp)
    80004cfa:	6145                	addi	sp,sp,48
    80004cfc:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004cfe:	0284a983          	lw	s3,40(s1)
    80004d02:	ffffd097          	auipc	ra,0xffffd
    80004d06:	dfc080e7          	jalr	-516(ra) # 80001afe <myproc>
    80004d0a:	5904                	lw	s1,48(a0)
    80004d0c:	413484b3          	sub	s1,s1,s3
    80004d10:	0014b493          	seqz	s1,s1
    80004d14:	bfc1                	j	80004ce4 <holdingsleep+0x24>

0000000080004d16 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004d16:	1141                	addi	sp,sp,-16
    80004d18:	e406                	sd	ra,8(sp)
    80004d1a:	e022                	sd	s0,0(sp)
    80004d1c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004d1e:	00004597          	auipc	a1,0x4
    80004d22:	a8258593          	addi	a1,a1,-1406 # 800087a0 <syscalls+0x2a8>
    80004d26:	00031517          	auipc	a0,0x31
    80004d2a:	82250513          	addi	a0,a0,-2014 # 80035548 <ftable>
    80004d2e:	ffffc097          	auipc	ra,0xffffc
    80004d32:	e18080e7          	jalr	-488(ra) # 80000b46 <initlock>
}
    80004d36:	60a2                	ld	ra,8(sp)
    80004d38:	6402                	ld	s0,0(sp)
    80004d3a:	0141                	addi	sp,sp,16
    80004d3c:	8082                	ret

0000000080004d3e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004d3e:	1101                	addi	sp,sp,-32
    80004d40:	ec06                	sd	ra,24(sp)
    80004d42:	e822                	sd	s0,16(sp)
    80004d44:	e426                	sd	s1,8(sp)
    80004d46:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004d48:	00031517          	auipc	a0,0x31
    80004d4c:	80050513          	addi	a0,a0,-2048 # 80035548 <ftable>
    80004d50:	ffffc097          	auipc	ra,0xffffc
    80004d54:	e86080e7          	jalr	-378(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004d58:	00031497          	auipc	s1,0x31
    80004d5c:	80848493          	addi	s1,s1,-2040 # 80035560 <ftable+0x18>
    80004d60:	00031717          	auipc	a4,0x31
    80004d64:	7a070713          	addi	a4,a4,1952 # 80036500 <disk>
    if(f->ref == 0){
    80004d68:	40dc                	lw	a5,4(s1)
    80004d6a:	cf99                	beqz	a5,80004d88 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004d6c:	02848493          	addi	s1,s1,40
    80004d70:	fee49ce3          	bne	s1,a4,80004d68 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004d74:	00030517          	auipc	a0,0x30
    80004d78:	7d450513          	addi	a0,a0,2004 # 80035548 <ftable>
    80004d7c:	ffffc097          	auipc	ra,0xffffc
    80004d80:	f0e080e7          	jalr	-242(ra) # 80000c8a <release>
  return 0;
    80004d84:	4481                	li	s1,0
    80004d86:	a819                	j	80004d9c <filealloc+0x5e>
      f->ref = 1;
    80004d88:	4785                	li	a5,1
    80004d8a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004d8c:	00030517          	auipc	a0,0x30
    80004d90:	7bc50513          	addi	a0,a0,1980 # 80035548 <ftable>
    80004d94:	ffffc097          	auipc	ra,0xffffc
    80004d98:	ef6080e7          	jalr	-266(ra) # 80000c8a <release>
}
    80004d9c:	8526                	mv	a0,s1
    80004d9e:	60e2                	ld	ra,24(sp)
    80004da0:	6442                	ld	s0,16(sp)
    80004da2:	64a2                	ld	s1,8(sp)
    80004da4:	6105                	addi	sp,sp,32
    80004da6:	8082                	ret

0000000080004da8 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004da8:	1101                	addi	sp,sp,-32
    80004daa:	ec06                	sd	ra,24(sp)
    80004dac:	e822                	sd	s0,16(sp)
    80004dae:	e426                	sd	s1,8(sp)
    80004db0:	1000                	addi	s0,sp,32
    80004db2:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004db4:	00030517          	auipc	a0,0x30
    80004db8:	79450513          	addi	a0,a0,1940 # 80035548 <ftable>
    80004dbc:	ffffc097          	auipc	ra,0xffffc
    80004dc0:	e1a080e7          	jalr	-486(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004dc4:	40dc                	lw	a5,4(s1)
    80004dc6:	02f05263          	blez	a5,80004dea <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004dca:	2785                	addiw	a5,a5,1
    80004dcc:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004dce:	00030517          	auipc	a0,0x30
    80004dd2:	77a50513          	addi	a0,a0,1914 # 80035548 <ftable>
    80004dd6:	ffffc097          	auipc	ra,0xffffc
    80004dda:	eb4080e7          	jalr	-332(ra) # 80000c8a <release>
  return f;
}
    80004dde:	8526                	mv	a0,s1
    80004de0:	60e2                	ld	ra,24(sp)
    80004de2:	6442                	ld	s0,16(sp)
    80004de4:	64a2                	ld	s1,8(sp)
    80004de6:	6105                	addi	sp,sp,32
    80004de8:	8082                	ret
    panic("filedup");
    80004dea:	00004517          	auipc	a0,0x4
    80004dee:	9be50513          	addi	a0,a0,-1602 # 800087a8 <syscalls+0x2b0>
    80004df2:	ffffb097          	auipc	ra,0xffffb
    80004df6:	74c080e7          	jalr	1868(ra) # 8000053e <panic>

0000000080004dfa <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004dfa:	7139                	addi	sp,sp,-64
    80004dfc:	fc06                	sd	ra,56(sp)
    80004dfe:	f822                	sd	s0,48(sp)
    80004e00:	f426                	sd	s1,40(sp)
    80004e02:	f04a                	sd	s2,32(sp)
    80004e04:	ec4e                	sd	s3,24(sp)
    80004e06:	e852                	sd	s4,16(sp)
    80004e08:	e456                	sd	s5,8(sp)
    80004e0a:	0080                	addi	s0,sp,64
    80004e0c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004e0e:	00030517          	auipc	a0,0x30
    80004e12:	73a50513          	addi	a0,a0,1850 # 80035548 <ftable>
    80004e16:	ffffc097          	auipc	ra,0xffffc
    80004e1a:	dc0080e7          	jalr	-576(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004e1e:	40dc                	lw	a5,4(s1)
    80004e20:	06f05163          	blez	a5,80004e82 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004e24:	37fd                	addiw	a5,a5,-1
    80004e26:	0007871b          	sext.w	a4,a5
    80004e2a:	c0dc                	sw	a5,4(s1)
    80004e2c:	06e04363          	bgtz	a4,80004e92 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004e30:	0004a903          	lw	s2,0(s1)
    80004e34:	0094ca83          	lbu	s5,9(s1)
    80004e38:	0104ba03          	ld	s4,16(s1)
    80004e3c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004e40:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004e44:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004e48:	00030517          	auipc	a0,0x30
    80004e4c:	70050513          	addi	a0,a0,1792 # 80035548 <ftable>
    80004e50:	ffffc097          	auipc	ra,0xffffc
    80004e54:	e3a080e7          	jalr	-454(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004e58:	4785                	li	a5,1
    80004e5a:	04f90d63          	beq	s2,a5,80004eb4 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004e5e:	3979                	addiw	s2,s2,-2
    80004e60:	4785                	li	a5,1
    80004e62:	0527e063          	bltu	a5,s2,80004ea2 <fileclose+0xa8>
    begin_op();
    80004e66:	00000097          	auipc	ra,0x0
    80004e6a:	ac8080e7          	jalr	-1336(ra) # 8000492e <begin_op>
    iput(ff.ip);
    80004e6e:	854e                	mv	a0,s3
    80004e70:	fffff097          	auipc	ra,0xfffff
    80004e74:	fa4080e7          	jalr	-92(ra) # 80003e14 <iput>
    end_op();
    80004e78:	00000097          	auipc	ra,0x0
    80004e7c:	b36080e7          	jalr	-1226(ra) # 800049ae <end_op>
    80004e80:	a00d                	j	80004ea2 <fileclose+0xa8>
    panic("fileclose");
    80004e82:	00004517          	auipc	a0,0x4
    80004e86:	92e50513          	addi	a0,a0,-1746 # 800087b0 <syscalls+0x2b8>
    80004e8a:	ffffb097          	auipc	ra,0xffffb
    80004e8e:	6b4080e7          	jalr	1716(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004e92:	00030517          	auipc	a0,0x30
    80004e96:	6b650513          	addi	a0,a0,1718 # 80035548 <ftable>
    80004e9a:	ffffc097          	auipc	ra,0xffffc
    80004e9e:	df0080e7          	jalr	-528(ra) # 80000c8a <release>
  }
}
    80004ea2:	70e2                	ld	ra,56(sp)
    80004ea4:	7442                	ld	s0,48(sp)
    80004ea6:	74a2                	ld	s1,40(sp)
    80004ea8:	7902                	ld	s2,32(sp)
    80004eaa:	69e2                	ld	s3,24(sp)
    80004eac:	6a42                	ld	s4,16(sp)
    80004eae:	6aa2                	ld	s5,8(sp)
    80004eb0:	6121                	addi	sp,sp,64
    80004eb2:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004eb4:	85d6                	mv	a1,s5
    80004eb6:	8552                	mv	a0,s4
    80004eb8:	00000097          	auipc	ra,0x0
    80004ebc:	542080e7          	jalr	1346(ra) # 800053fa <pipeclose>
    80004ec0:	b7cd                	j	80004ea2 <fileclose+0xa8>

0000000080004ec2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004ec2:	715d                	addi	sp,sp,-80
    80004ec4:	e486                	sd	ra,72(sp)
    80004ec6:	e0a2                	sd	s0,64(sp)
    80004ec8:	fc26                	sd	s1,56(sp)
    80004eca:	f84a                	sd	s2,48(sp)
    80004ecc:	f44e                	sd	s3,40(sp)
    80004ece:	0880                	addi	s0,sp,80
    80004ed0:	84aa                	mv	s1,a0
    80004ed2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004ed4:	ffffd097          	auipc	ra,0xffffd
    80004ed8:	c2a080e7          	jalr	-982(ra) # 80001afe <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004edc:	409c                	lw	a5,0(s1)
    80004ede:	37f9                	addiw	a5,a5,-2
    80004ee0:	4705                	li	a4,1
    80004ee2:	04f76763          	bltu	a4,a5,80004f30 <filestat+0x6e>
    80004ee6:	892a                	mv	s2,a0
    ilock(f->ip);
    80004ee8:	6c88                	ld	a0,24(s1)
    80004eea:	fffff097          	auipc	ra,0xfffff
    80004eee:	d70080e7          	jalr	-656(ra) # 80003c5a <ilock>
    stati(f->ip, &st);
    80004ef2:	fb840593          	addi	a1,s0,-72
    80004ef6:	6c88                	ld	a0,24(s1)
    80004ef8:	fffff097          	auipc	ra,0xfffff
    80004efc:	fec080e7          	jalr	-20(ra) # 80003ee4 <stati>
    iunlock(f->ip);
    80004f00:	6c88                	ld	a0,24(s1)
    80004f02:	fffff097          	auipc	ra,0xfffff
    80004f06:	e1a080e7          	jalr	-486(ra) # 80003d1c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004f0a:	46e1                	li	a3,24
    80004f0c:	fb840613          	addi	a2,s0,-72
    80004f10:	85ce                	mv	a1,s3
    80004f12:	05093503          	ld	a0,80(s2)
    80004f16:	ffffd097          	auipc	ra,0xffffd
    80004f1a:	8a4080e7          	jalr	-1884(ra) # 800017ba <copyout>
    80004f1e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004f22:	60a6                	ld	ra,72(sp)
    80004f24:	6406                	ld	s0,64(sp)
    80004f26:	74e2                	ld	s1,56(sp)
    80004f28:	7942                	ld	s2,48(sp)
    80004f2a:	79a2                	ld	s3,40(sp)
    80004f2c:	6161                	addi	sp,sp,80
    80004f2e:	8082                	ret
  return -1;
    80004f30:	557d                	li	a0,-1
    80004f32:	bfc5                	j	80004f22 <filestat+0x60>

0000000080004f34 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004f34:	7179                	addi	sp,sp,-48
    80004f36:	f406                	sd	ra,40(sp)
    80004f38:	f022                	sd	s0,32(sp)
    80004f3a:	ec26                	sd	s1,24(sp)
    80004f3c:	e84a                	sd	s2,16(sp)
    80004f3e:	e44e                	sd	s3,8(sp)
    80004f40:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004f42:	00854783          	lbu	a5,8(a0)
    80004f46:	c3d5                	beqz	a5,80004fea <fileread+0xb6>
    80004f48:	84aa                	mv	s1,a0
    80004f4a:	89ae                	mv	s3,a1
    80004f4c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004f4e:	411c                	lw	a5,0(a0)
    80004f50:	4705                	li	a4,1
    80004f52:	04e78963          	beq	a5,a4,80004fa4 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004f56:	470d                	li	a4,3
    80004f58:	04e78d63          	beq	a5,a4,80004fb2 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f5c:	4709                	li	a4,2
    80004f5e:	06e79e63          	bne	a5,a4,80004fda <fileread+0xa6>
    ilock(f->ip);
    80004f62:	6d08                	ld	a0,24(a0)
    80004f64:	fffff097          	auipc	ra,0xfffff
    80004f68:	cf6080e7          	jalr	-778(ra) # 80003c5a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004f6c:	874a                	mv	a4,s2
    80004f6e:	5094                	lw	a3,32(s1)
    80004f70:	864e                	mv	a2,s3
    80004f72:	4585                	li	a1,1
    80004f74:	6c88                	ld	a0,24(s1)
    80004f76:	fffff097          	auipc	ra,0xfffff
    80004f7a:	f98080e7          	jalr	-104(ra) # 80003f0e <readi>
    80004f7e:	892a                	mv	s2,a0
    80004f80:	00a05563          	blez	a0,80004f8a <fileread+0x56>
      f->off += r;
    80004f84:	509c                	lw	a5,32(s1)
    80004f86:	9fa9                	addw	a5,a5,a0
    80004f88:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004f8a:	6c88                	ld	a0,24(s1)
    80004f8c:	fffff097          	auipc	ra,0xfffff
    80004f90:	d90080e7          	jalr	-624(ra) # 80003d1c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004f94:	854a                	mv	a0,s2
    80004f96:	70a2                	ld	ra,40(sp)
    80004f98:	7402                	ld	s0,32(sp)
    80004f9a:	64e2                	ld	s1,24(sp)
    80004f9c:	6942                	ld	s2,16(sp)
    80004f9e:	69a2                	ld	s3,8(sp)
    80004fa0:	6145                	addi	sp,sp,48
    80004fa2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004fa4:	6908                	ld	a0,16(a0)
    80004fa6:	00000097          	auipc	ra,0x0
    80004faa:	5bc080e7          	jalr	1468(ra) # 80005562 <piperead>
    80004fae:	892a                	mv	s2,a0
    80004fb0:	b7d5                	j	80004f94 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004fb2:	02451783          	lh	a5,36(a0)
    80004fb6:	03079693          	slli	a3,a5,0x30
    80004fba:	92c1                	srli	a3,a3,0x30
    80004fbc:	4725                	li	a4,9
    80004fbe:	02d76863          	bltu	a4,a3,80004fee <fileread+0xba>
    80004fc2:	0792                	slli	a5,a5,0x4
    80004fc4:	00030717          	auipc	a4,0x30
    80004fc8:	4e470713          	addi	a4,a4,1252 # 800354a8 <devsw>
    80004fcc:	97ba                	add	a5,a5,a4
    80004fce:	639c                	ld	a5,0(a5)
    80004fd0:	c38d                	beqz	a5,80004ff2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004fd2:	4505                	li	a0,1
    80004fd4:	9782                	jalr	a5
    80004fd6:	892a                	mv	s2,a0
    80004fd8:	bf75                	j	80004f94 <fileread+0x60>
    panic("fileread");
    80004fda:	00003517          	auipc	a0,0x3
    80004fde:	7e650513          	addi	a0,a0,2022 # 800087c0 <syscalls+0x2c8>
    80004fe2:	ffffb097          	auipc	ra,0xffffb
    80004fe6:	55c080e7          	jalr	1372(ra) # 8000053e <panic>
    return -1;
    80004fea:	597d                	li	s2,-1
    80004fec:	b765                	j	80004f94 <fileread+0x60>
      return -1;
    80004fee:	597d                	li	s2,-1
    80004ff0:	b755                	j	80004f94 <fileread+0x60>
    80004ff2:	597d                	li	s2,-1
    80004ff4:	b745                	j	80004f94 <fileread+0x60>

0000000080004ff6 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004ff6:	715d                	addi	sp,sp,-80
    80004ff8:	e486                	sd	ra,72(sp)
    80004ffa:	e0a2                	sd	s0,64(sp)
    80004ffc:	fc26                	sd	s1,56(sp)
    80004ffe:	f84a                	sd	s2,48(sp)
    80005000:	f44e                	sd	s3,40(sp)
    80005002:	f052                	sd	s4,32(sp)
    80005004:	ec56                	sd	s5,24(sp)
    80005006:	e85a                	sd	s6,16(sp)
    80005008:	e45e                	sd	s7,8(sp)
    8000500a:	e062                	sd	s8,0(sp)
    8000500c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000500e:	00954783          	lbu	a5,9(a0)
    80005012:	10078663          	beqz	a5,8000511e <filewrite+0x128>
    80005016:	892a                	mv	s2,a0
    80005018:	8aae                	mv	s5,a1
    8000501a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000501c:	411c                	lw	a5,0(a0)
    8000501e:	4705                	li	a4,1
    80005020:	02e78263          	beq	a5,a4,80005044 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005024:	470d                	li	a4,3
    80005026:	02e78663          	beq	a5,a4,80005052 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000502a:	4709                	li	a4,2
    8000502c:	0ee79163          	bne	a5,a4,8000510e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005030:	0ac05d63          	blez	a2,800050ea <filewrite+0xf4>
    int i = 0;
    80005034:	4981                	li	s3,0
    80005036:	6b05                	lui	s6,0x1
    80005038:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000503c:	6b85                	lui	s7,0x1
    8000503e:	c00b8b9b          	addiw	s7,s7,-1024
    80005042:	a861                	j	800050da <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005044:	6908                	ld	a0,16(a0)
    80005046:	00000097          	auipc	ra,0x0
    8000504a:	424080e7          	jalr	1060(ra) # 8000546a <pipewrite>
    8000504e:	8a2a                	mv	s4,a0
    80005050:	a045                	j	800050f0 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005052:	02451783          	lh	a5,36(a0)
    80005056:	03079693          	slli	a3,a5,0x30
    8000505a:	92c1                	srli	a3,a3,0x30
    8000505c:	4725                	li	a4,9
    8000505e:	0cd76263          	bltu	a4,a3,80005122 <filewrite+0x12c>
    80005062:	0792                	slli	a5,a5,0x4
    80005064:	00030717          	auipc	a4,0x30
    80005068:	44470713          	addi	a4,a4,1092 # 800354a8 <devsw>
    8000506c:	97ba                	add	a5,a5,a4
    8000506e:	679c                	ld	a5,8(a5)
    80005070:	cbdd                	beqz	a5,80005126 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005072:	4505                	li	a0,1
    80005074:	9782                	jalr	a5
    80005076:	8a2a                	mv	s4,a0
    80005078:	a8a5                	j	800050f0 <filewrite+0xfa>
    8000507a:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000507e:	00000097          	auipc	ra,0x0
    80005082:	8b0080e7          	jalr	-1872(ra) # 8000492e <begin_op>
      ilock(f->ip);
    80005086:	01893503          	ld	a0,24(s2)
    8000508a:	fffff097          	auipc	ra,0xfffff
    8000508e:	bd0080e7          	jalr	-1072(ra) # 80003c5a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005092:	8762                	mv	a4,s8
    80005094:	02092683          	lw	a3,32(s2)
    80005098:	01598633          	add	a2,s3,s5
    8000509c:	4585                	li	a1,1
    8000509e:	01893503          	ld	a0,24(s2)
    800050a2:	fffff097          	auipc	ra,0xfffff
    800050a6:	f64080e7          	jalr	-156(ra) # 80004006 <writei>
    800050aa:	84aa                	mv	s1,a0
    800050ac:	00a05763          	blez	a0,800050ba <filewrite+0xc4>
        f->off += r;
    800050b0:	02092783          	lw	a5,32(s2)
    800050b4:	9fa9                	addw	a5,a5,a0
    800050b6:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800050ba:	01893503          	ld	a0,24(s2)
    800050be:	fffff097          	auipc	ra,0xfffff
    800050c2:	c5e080e7          	jalr	-930(ra) # 80003d1c <iunlock>
      end_op();
    800050c6:	00000097          	auipc	ra,0x0
    800050ca:	8e8080e7          	jalr	-1816(ra) # 800049ae <end_op>

      if(r != n1){
    800050ce:	009c1f63          	bne	s8,s1,800050ec <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800050d2:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800050d6:	0149db63          	bge	s3,s4,800050ec <filewrite+0xf6>
      int n1 = n - i;
    800050da:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800050de:	84be                	mv	s1,a5
    800050e0:	2781                	sext.w	a5,a5
    800050e2:	f8fb5ce3          	bge	s6,a5,8000507a <filewrite+0x84>
    800050e6:	84de                	mv	s1,s7
    800050e8:	bf49                	j	8000507a <filewrite+0x84>
    int i = 0;
    800050ea:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800050ec:	013a1f63          	bne	s4,s3,8000510a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800050f0:	8552                	mv	a0,s4
    800050f2:	60a6                	ld	ra,72(sp)
    800050f4:	6406                	ld	s0,64(sp)
    800050f6:	74e2                	ld	s1,56(sp)
    800050f8:	7942                	ld	s2,48(sp)
    800050fa:	79a2                	ld	s3,40(sp)
    800050fc:	7a02                	ld	s4,32(sp)
    800050fe:	6ae2                	ld	s5,24(sp)
    80005100:	6b42                	ld	s6,16(sp)
    80005102:	6ba2                	ld	s7,8(sp)
    80005104:	6c02                	ld	s8,0(sp)
    80005106:	6161                	addi	sp,sp,80
    80005108:	8082                	ret
    ret = (i == n ? n : -1);
    8000510a:	5a7d                	li	s4,-1
    8000510c:	b7d5                	j	800050f0 <filewrite+0xfa>
    panic("filewrite");
    8000510e:	00003517          	auipc	a0,0x3
    80005112:	6c250513          	addi	a0,a0,1730 # 800087d0 <syscalls+0x2d8>
    80005116:	ffffb097          	auipc	ra,0xffffb
    8000511a:	428080e7          	jalr	1064(ra) # 8000053e <panic>
    return -1;
    8000511e:	5a7d                	li	s4,-1
    80005120:	bfc1                	j	800050f0 <filewrite+0xfa>
      return -1;
    80005122:	5a7d                	li	s4,-1
    80005124:	b7f1                	j	800050f0 <filewrite+0xfa>
    80005126:	5a7d                	li	s4,-1
    80005128:	b7e1                	j	800050f0 <filewrite+0xfa>

000000008000512a <kfileread>:

// Read from file f.
// addr is a kernel virtual address.
int
kfileread(struct file *f, uint64 addr, int n)
{
    8000512a:	7179                	addi	sp,sp,-48
    8000512c:	f406                	sd	ra,40(sp)
    8000512e:	f022                	sd	s0,32(sp)
    80005130:	ec26                	sd	s1,24(sp)
    80005132:	e84a                	sd	s2,16(sp)
    80005134:	e44e                	sd	s3,8(sp)
    80005136:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005138:	00854783          	lbu	a5,8(a0)
    8000513c:	c3d5                	beqz	a5,800051e0 <kfileread+0xb6>
    8000513e:	84aa                	mv	s1,a0
    80005140:	89ae                	mv	s3,a1
    80005142:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005144:	411c                	lw	a5,0(a0)
    80005146:	4705                	li	a4,1
    80005148:	04e78963          	beq	a5,a4,8000519a <kfileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000514c:	470d                	li	a4,3
    8000514e:	04e78d63          	beq	a5,a4,800051a8 <kfileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005152:	4709                	li	a4,2
    80005154:	06e79e63          	bne	a5,a4,800051d0 <kfileread+0xa6>
    ilock(f->ip);
    80005158:	6d08                	ld	a0,24(a0)
    8000515a:	fffff097          	auipc	ra,0xfffff
    8000515e:	b00080e7          	jalr	-1280(ra) # 80003c5a <ilock>
    if((r = readi(f->ip, 0, addr, f->off, n)) > 0)
    80005162:	874a                	mv	a4,s2
    80005164:	5094                	lw	a3,32(s1)
    80005166:	864e                	mv	a2,s3
    80005168:	4581                	li	a1,0
    8000516a:	6c88                	ld	a0,24(s1)
    8000516c:	fffff097          	auipc	ra,0xfffff
    80005170:	da2080e7          	jalr	-606(ra) # 80003f0e <readi>
    80005174:	892a                	mv	s2,a0
    80005176:	00a05563          	blez	a0,80005180 <kfileread+0x56>
      f->off += r;
    8000517a:	509c                	lw	a5,32(s1)
    8000517c:	9fa9                	addw	a5,a5,a0
    8000517e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005180:	6c88                	ld	a0,24(s1)
    80005182:	fffff097          	auipc	ra,0xfffff
    80005186:	b9a080e7          	jalr	-1126(ra) # 80003d1c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000518a:	854a                	mv	a0,s2
    8000518c:	70a2                	ld	ra,40(sp)
    8000518e:	7402                	ld	s0,32(sp)
    80005190:	64e2                	ld	s1,24(sp)
    80005192:	6942                	ld	s2,16(sp)
    80005194:	69a2                	ld	s3,8(sp)
    80005196:	6145                	addi	sp,sp,48
    80005198:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000519a:	6908                	ld	a0,16(a0)
    8000519c:	00000097          	auipc	ra,0x0
    800051a0:	3c6080e7          	jalr	966(ra) # 80005562 <piperead>
    800051a4:	892a                	mv	s2,a0
    800051a6:	b7d5                	j	8000518a <kfileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800051a8:	02451783          	lh	a5,36(a0)
    800051ac:	03079693          	slli	a3,a5,0x30
    800051b0:	92c1                	srli	a3,a3,0x30
    800051b2:	4725                	li	a4,9
    800051b4:	02d76863          	bltu	a4,a3,800051e4 <kfileread+0xba>
    800051b8:	0792                	slli	a5,a5,0x4
    800051ba:	00030717          	auipc	a4,0x30
    800051be:	2ee70713          	addi	a4,a4,750 # 800354a8 <devsw>
    800051c2:	97ba                	add	a5,a5,a4
    800051c4:	639c                	ld	a5,0(a5)
    800051c6:	c38d                	beqz	a5,800051e8 <kfileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800051c8:	4505                	li	a0,1
    800051ca:	9782                	jalr	a5
    800051cc:	892a                	mv	s2,a0
    800051ce:	bf75                	j	8000518a <kfileread+0x60>
    panic("fileread");
    800051d0:	00003517          	auipc	a0,0x3
    800051d4:	5f050513          	addi	a0,a0,1520 # 800087c0 <syscalls+0x2c8>
    800051d8:	ffffb097          	auipc	ra,0xffffb
    800051dc:	366080e7          	jalr	870(ra) # 8000053e <panic>
    return -1;
    800051e0:	597d                	li	s2,-1
    800051e2:	b765                	j	8000518a <kfileread+0x60>
      return -1;
    800051e4:	597d                	li	s2,-1
    800051e6:	b755                	j	8000518a <kfileread+0x60>
    800051e8:	597d                	li	s2,-1
    800051ea:	b745                	j	8000518a <kfileread+0x60>

00000000800051ec <kfilewrite>:

// Write to file f.
// addr is a kernel virtual address.
int
kfilewrite(struct file *f, uint64 addr, int n)
{
    800051ec:	715d                	addi	sp,sp,-80
    800051ee:	e486                	sd	ra,72(sp)
    800051f0:	e0a2                	sd	s0,64(sp)
    800051f2:	fc26                	sd	s1,56(sp)
    800051f4:	f84a                	sd	s2,48(sp)
    800051f6:	f44e                	sd	s3,40(sp)
    800051f8:	f052                	sd	s4,32(sp)
    800051fa:	ec56                	sd	s5,24(sp)
    800051fc:	e85a                	sd	s6,16(sp)
    800051fe:	e45e                	sd	s7,8(sp)
    80005200:	e062                	sd	s8,0(sp)
    80005202:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005204:	00954783          	lbu	a5,9(a0)
    80005208:	10078663          	beqz	a5,80005314 <kfilewrite+0x128>
    8000520c:	892a                	mv	s2,a0
    8000520e:	8aae                	mv	s5,a1
    80005210:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005212:	411c                	lw	a5,0(a0)
    80005214:	4705                	li	a4,1
    80005216:	02e78263          	beq	a5,a4,8000523a <kfilewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000521a:	470d                	li	a4,3
    8000521c:	02e78663          	beq	a5,a4,80005248 <kfilewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005220:	4709                	li	a4,2
    80005222:	0ee79163          	bne	a5,a4,80005304 <kfilewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005226:	0ac05d63          	blez	a2,800052e0 <kfilewrite+0xf4>
    int i = 0;
    8000522a:	4981                	li	s3,0
    8000522c:	6b05                	lui	s6,0x1
    8000522e:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005232:	6b85                	lui	s7,0x1
    80005234:	c00b8b9b          	addiw	s7,s7,-1024
    80005238:	a861                	j	800052d0 <kfilewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000523a:	6908                	ld	a0,16(a0)
    8000523c:	00000097          	auipc	ra,0x0
    80005240:	22e080e7          	jalr	558(ra) # 8000546a <pipewrite>
    80005244:	8a2a                	mv	s4,a0
    80005246:	a045                	j	800052e6 <kfilewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005248:	02451783          	lh	a5,36(a0)
    8000524c:	03079693          	slli	a3,a5,0x30
    80005250:	92c1                	srli	a3,a3,0x30
    80005252:	4725                	li	a4,9
    80005254:	0cd76263          	bltu	a4,a3,80005318 <kfilewrite+0x12c>
    80005258:	0792                	slli	a5,a5,0x4
    8000525a:	00030717          	auipc	a4,0x30
    8000525e:	24e70713          	addi	a4,a4,590 # 800354a8 <devsw>
    80005262:	97ba                	add	a5,a5,a4
    80005264:	679c                	ld	a5,8(a5)
    80005266:	cbdd                	beqz	a5,8000531c <kfilewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005268:	4505                	li	a0,1
    8000526a:	9782                	jalr	a5
    8000526c:	8a2a                	mv	s4,a0
    8000526e:	a8a5                	j	800052e6 <kfilewrite+0xfa>
    80005270:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005274:	fffff097          	auipc	ra,0xfffff
    80005278:	6ba080e7          	jalr	1722(ra) # 8000492e <begin_op>
      ilock(f->ip);
    8000527c:	01893503          	ld	a0,24(s2)
    80005280:	fffff097          	auipc	ra,0xfffff
    80005284:	9da080e7          	jalr	-1574(ra) # 80003c5a <ilock>
      if ((r = writei(f->ip, 0, addr + i, f->off, n1)) > 0)
    80005288:	8762                	mv	a4,s8
    8000528a:	02092683          	lw	a3,32(s2)
    8000528e:	01598633          	add	a2,s3,s5
    80005292:	4581                	li	a1,0
    80005294:	01893503          	ld	a0,24(s2)
    80005298:	fffff097          	auipc	ra,0xfffff
    8000529c:	d6e080e7          	jalr	-658(ra) # 80004006 <writei>
    800052a0:	84aa                	mv	s1,a0
    800052a2:	00a05763          	blez	a0,800052b0 <kfilewrite+0xc4>
        f->off += r;
    800052a6:	02092783          	lw	a5,32(s2)
    800052aa:	9fa9                	addw	a5,a5,a0
    800052ac:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800052b0:	01893503          	ld	a0,24(s2)
    800052b4:	fffff097          	auipc	ra,0xfffff
    800052b8:	a68080e7          	jalr	-1432(ra) # 80003d1c <iunlock>
      end_op();
    800052bc:	fffff097          	auipc	ra,0xfffff
    800052c0:	6f2080e7          	jalr	1778(ra) # 800049ae <end_op>

      if(r != n1){
    800052c4:	009c1f63          	bne	s8,s1,800052e2 <kfilewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800052c8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800052cc:	0149db63          	bge	s3,s4,800052e2 <kfilewrite+0xf6>
      int n1 = n - i;
    800052d0:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800052d4:	84be                	mv	s1,a5
    800052d6:	2781                	sext.w	a5,a5
    800052d8:	f8fb5ce3          	bge	s6,a5,80005270 <kfilewrite+0x84>
    800052dc:	84de                	mv	s1,s7
    800052de:	bf49                	j	80005270 <kfilewrite+0x84>
    int i = 0;
    800052e0:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800052e2:	013a1f63          	bne	s4,s3,80005300 <kfilewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
    800052e6:	8552                	mv	a0,s4
    800052e8:	60a6                	ld	ra,72(sp)
    800052ea:	6406                	ld	s0,64(sp)
    800052ec:	74e2                	ld	s1,56(sp)
    800052ee:	7942                	ld	s2,48(sp)
    800052f0:	79a2                	ld	s3,40(sp)
    800052f2:	7a02                	ld	s4,32(sp)
    800052f4:	6ae2                	ld	s5,24(sp)
    800052f6:	6b42                	ld	s6,16(sp)
    800052f8:	6ba2                	ld	s7,8(sp)
    800052fa:	6c02                	ld	s8,0(sp)
    800052fc:	6161                	addi	sp,sp,80
    800052fe:	8082                	ret
    ret = (i == n ? n : -1);
    80005300:	5a7d                	li	s4,-1
    80005302:	b7d5                	j	800052e6 <kfilewrite+0xfa>
    panic("filewrite");
    80005304:	00003517          	auipc	a0,0x3
    80005308:	4cc50513          	addi	a0,a0,1228 # 800087d0 <syscalls+0x2d8>
    8000530c:	ffffb097          	auipc	ra,0xffffb
    80005310:	232080e7          	jalr	562(ra) # 8000053e <panic>
    return -1;
    80005314:	5a7d                	li	s4,-1
    80005316:	bfc1                	j	800052e6 <kfilewrite+0xfa>
      return -1;
    80005318:	5a7d                	li	s4,-1
    8000531a:	b7f1                	j	800052e6 <kfilewrite+0xfa>
    8000531c:	5a7d                	li	s4,-1
    8000531e:	b7e1                	j	800052e6 <kfilewrite+0xfa>

0000000080005320 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005320:	7179                	addi	sp,sp,-48
    80005322:	f406                	sd	ra,40(sp)
    80005324:	f022                	sd	s0,32(sp)
    80005326:	ec26                	sd	s1,24(sp)
    80005328:	e84a                	sd	s2,16(sp)
    8000532a:	e44e                	sd	s3,8(sp)
    8000532c:	e052                	sd	s4,0(sp)
    8000532e:	1800                	addi	s0,sp,48
    80005330:	84aa                	mv	s1,a0
    80005332:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005334:	0005b023          	sd	zero,0(a1)
    80005338:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000533c:	00000097          	auipc	ra,0x0
    80005340:	a02080e7          	jalr	-1534(ra) # 80004d3e <filealloc>
    80005344:	e088                	sd	a0,0(s1)
    80005346:	c551                	beqz	a0,800053d2 <pipealloc+0xb2>
    80005348:	00000097          	auipc	ra,0x0
    8000534c:	9f6080e7          	jalr	-1546(ra) # 80004d3e <filealloc>
    80005350:	00aa3023          	sd	a0,0(s4)
    80005354:	c92d                	beqz	a0,800053c6 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005356:	ffffb097          	auipc	ra,0xffffb
    8000535a:	790080e7          	jalr	1936(ra) # 80000ae6 <kalloc>
    8000535e:	892a                	mv	s2,a0
    80005360:	c125                	beqz	a0,800053c0 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005362:	4985                	li	s3,1
    80005364:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005368:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000536c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005370:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005374:	00003597          	auipc	a1,0x3
    80005378:	46c58593          	addi	a1,a1,1132 # 800087e0 <syscalls+0x2e8>
    8000537c:	ffffb097          	auipc	ra,0xffffb
    80005380:	7ca080e7          	jalr	1994(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80005384:	609c                	ld	a5,0(s1)
    80005386:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000538a:	609c                	ld	a5,0(s1)
    8000538c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005390:	609c                	ld	a5,0(s1)
    80005392:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005396:	609c                	ld	a5,0(s1)
    80005398:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000539c:	000a3783          	ld	a5,0(s4)
    800053a0:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800053a4:	000a3783          	ld	a5,0(s4)
    800053a8:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800053ac:	000a3783          	ld	a5,0(s4)
    800053b0:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800053b4:	000a3783          	ld	a5,0(s4)
    800053b8:	0127b823          	sd	s2,16(a5)
  return 0;
    800053bc:	4501                	li	a0,0
    800053be:	a025                	j	800053e6 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800053c0:	6088                	ld	a0,0(s1)
    800053c2:	e501                	bnez	a0,800053ca <pipealloc+0xaa>
    800053c4:	a039                	j	800053d2 <pipealloc+0xb2>
    800053c6:	6088                	ld	a0,0(s1)
    800053c8:	c51d                	beqz	a0,800053f6 <pipealloc+0xd6>
    fileclose(*f0);
    800053ca:	00000097          	auipc	ra,0x0
    800053ce:	a30080e7          	jalr	-1488(ra) # 80004dfa <fileclose>
  if(*f1)
    800053d2:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800053d6:	557d                	li	a0,-1
  if(*f1)
    800053d8:	c799                	beqz	a5,800053e6 <pipealloc+0xc6>
    fileclose(*f1);
    800053da:	853e                	mv	a0,a5
    800053dc:	00000097          	auipc	ra,0x0
    800053e0:	a1e080e7          	jalr	-1506(ra) # 80004dfa <fileclose>
  return -1;
    800053e4:	557d                	li	a0,-1
}
    800053e6:	70a2                	ld	ra,40(sp)
    800053e8:	7402                	ld	s0,32(sp)
    800053ea:	64e2                	ld	s1,24(sp)
    800053ec:	6942                	ld	s2,16(sp)
    800053ee:	69a2                	ld	s3,8(sp)
    800053f0:	6a02                	ld	s4,0(sp)
    800053f2:	6145                	addi	sp,sp,48
    800053f4:	8082                	ret
  return -1;
    800053f6:	557d                	li	a0,-1
    800053f8:	b7fd                	j	800053e6 <pipealloc+0xc6>

00000000800053fa <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800053fa:	1101                	addi	sp,sp,-32
    800053fc:	ec06                	sd	ra,24(sp)
    800053fe:	e822                	sd	s0,16(sp)
    80005400:	e426                	sd	s1,8(sp)
    80005402:	e04a                	sd	s2,0(sp)
    80005404:	1000                	addi	s0,sp,32
    80005406:	84aa                	mv	s1,a0
    80005408:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000540a:	ffffb097          	auipc	ra,0xffffb
    8000540e:	7cc080e7          	jalr	1996(ra) # 80000bd6 <acquire>
  if(writable){
    80005412:	02090d63          	beqz	s2,8000544c <pipeclose+0x52>
    pi->writeopen = 0;
    80005416:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000541a:	21848513          	addi	a0,s1,536
    8000541e:	ffffd097          	auipc	ra,0xffffd
    80005422:	e94080e7          	jalr	-364(ra) # 800022b2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005426:	2204b783          	ld	a5,544(s1)
    8000542a:	eb95                	bnez	a5,8000545e <pipeclose+0x64>
    release(&pi->lock);
    8000542c:	8526                	mv	a0,s1
    8000542e:	ffffc097          	auipc	ra,0xffffc
    80005432:	85c080e7          	jalr	-1956(ra) # 80000c8a <release>
    kfree((char*)pi);
    80005436:	8526                	mv	a0,s1
    80005438:	ffffb097          	auipc	ra,0xffffb
    8000543c:	5b2080e7          	jalr	1458(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80005440:	60e2                	ld	ra,24(sp)
    80005442:	6442                	ld	s0,16(sp)
    80005444:	64a2                	ld	s1,8(sp)
    80005446:	6902                	ld	s2,0(sp)
    80005448:	6105                	addi	sp,sp,32
    8000544a:	8082                	ret
    pi->readopen = 0;
    8000544c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005450:	21c48513          	addi	a0,s1,540
    80005454:	ffffd097          	auipc	ra,0xffffd
    80005458:	e5e080e7          	jalr	-418(ra) # 800022b2 <wakeup>
    8000545c:	b7e9                	j	80005426 <pipeclose+0x2c>
    release(&pi->lock);
    8000545e:	8526                	mv	a0,s1
    80005460:	ffffc097          	auipc	ra,0xffffc
    80005464:	82a080e7          	jalr	-2006(ra) # 80000c8a <release>
}
    80005468:	bfe1                	j	80005440 <pipeclose+0x46>

000000008000546a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000546a:	711d                	addi	sp,sp,-96
    8000546c:	ec86                	sd	ra,88(sp)
    8000546e:	e8a2                	sd	s0,80(sp)
    80005470:	e4a6                	sd	s1,72(sp)
    80005472:	e0ca                	sd	s2,64(sp)
    80005474:	fc4e                	sd	s3,56(sp)
    80005476:	f852                	sd	s4,48(sp)
    80005478:	f456                	sd	s5,40(sp)
    8000547a:	f05a                	sd	s6,32(sp)
    8000547c:	ec5e                	sd	s7,24(sp)
    8000547e:	e862                	sd	s8,16(sp)
    80005480:	1080                	addi	s0,sp,96
    80005482:	84aa                	mv	s1,a0
    80005484:	8aae                	mv	s5,a1
    80005486:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005488:	ffffc097          	auipc	ra,0xffffc
    8000548c:	676080e7          	jalr	1654(ra) # 80001afe <myproc>
    80005490:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005492:	8526                	mv	a0,s1
    80005494:	ffffb097          	auipc	ra,0xffffb
    80005498:	742080e7          	jalr	1858(ra) # 80000bd6 <acquire>
  while(i < n){
    8000549c:	0b405663          	blez	s4,80005548 <pipewrite+0xde>
  int i = 0;
    800054a0:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800054a2:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800054a4:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800054a8:	21c48b93          	addi	s7,s1,540
    800054ac:	a089                	j	800054ee <pipewrite+0x84>
      release(&pi->lock);
    800054ae:	8526                	mv	a0,s1
    800054b0:	ffffb097          	auipc	ra,0xffffb
    800054b4:	7da080e7          	jalr	2010(ra) # 80000c8a <release>
      return -1;
    800054b8:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800054ba:	854a                	mv	a0,s2
    800054bc:	60e6                	ld	ra,88(sp)
    800054be:	6446                	ld	s0,80(sp)
    800054c0:	64a6                	ld	s1,72(sp)
    800054c2:	6906                	ld	s2,64(sp)
    800054c4:	79e2                	ld	s3,56(sp)
    800054c6:	7a42                	ld	s4,48(sp)
    800054c8:	7aa2                	ld	s5,40(sp)
    800054ca:	7b02                	ld	s6,32(sp)
    800054cc:	6be2                	ld	s7,24(sp)
    800054ce:	6c42                	ld	s8,16(sp)
    800054d0:	6125                	addi	sp,sp,96
    800054d2:	8082                	ret
      wakeup(&pi->nread);
    800054d4:	8562                	mv	a0,s8
    800054d6:	ffffd097          	auipc	ra,0xffffd
    800054da:	ddc080e7          	jalr	-548(ra) # 800022b2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800054de:	85a6                	mv	a1,s1
    800054e0:	855e                	mv	a0,s7
    800054e2:	ffffd097          	auipc	ra,0xffffd
    800054e6:	d6c080e7          	jalr	-660(ra) # 8000224e <sleep>
  while(i < n){
    800054ea:	07495063          	bge	s2,s4,8000554a <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    800054ee:	2204a783          	lw	a5,544(s1)
    800054f2:	dfd5                	beqz	a5,800054ae <pipewrite+0x44>
    800054f4:	854e                	mv	a0,s3
    800054f6:	ffffd097          	auipc	ra,0xffffd
    800054fa:	016080e7          	jalr	22(ra) # 8000250c <killed>
    800054fe:	f945                	bnez	a0,800054ae <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005500:	2184a783          	lw	a5,536(s1)
    80005504:	21c4a703          	lw	a4,540(s1)
    80005508:	2007879b          	addiw	a5,a5,512
    8000550c:	fcf704e3          	beq	a4,a5,800054d4 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005510:	4685                	li	a3,1
    80005512:	01590633          	add	a2,s2,s5
    80005516:	faf40593          	addi	a1,s0,-81
    8000551a:	0509b503          	ld	a0,80(s3)
    8000551e:	ffffc097          	auipc	ra,0xffffc
    80005522:	328080e7          	jalr	808(ra) # 80001846 <copyin>
    80005526:	03650263          	beq	a0,s6,8000554a <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000552a:	21c4a783          	lw	a5,540(s1)
    8000552e:	0017871b          	addiw	a4,a5,1
    80005532:	20e4ae23          	sw	a4,540(s1)
    80005536:	1ff7f793          	andi	a5,a5,511
    8000553a:	97a6                	add	a5,a5,s1
    8000553c:	faf44703          	lbu	a4,-81(s0)
    80005540:	00e78c23          	sb	a4,24(a5)
      i++;
    80005544:	2905                	addiw	s2,s2,1
    80005546:	b755                	j	800054ea <pipewrite+0x80>
  int i = 0;
    80005548:	4901                	li	s2,0
  wakeup(&pi->nread);
    8000554a:	21848513          	addi	a0,s1,536
    8000554e:	ffffd097          	auipc	ra,0xffffd
    80005552:	d64080e7          	jalr	-668(ra) # 800022b2 <wakeup>
  release(&pi->lock);
    80005556:	8526                	mv	a0,s1
    80005558:	ffffb097          	auipc	ra,0xffffb
    8000555c:	732080e7          	jalr	1842(ra) # 80000c8a <release>
  return i;
    80005560:	bfa9                	j	800054ba <pipewrite+0x50>

0000000080005562 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005562:	715d                	addi	sp,sp,-80
    80005564:	e486                	sd	ra,72(sp)
    80005566:	e0a2                	sd	s0,64(sp)
    80005568:	fc26                	sd	s1,56(sp)
    8000556a:	f84a                	sd	s2,48(sp)
    8000556c:	f44e                	sd	s3,40(sp)
    8000556e:	f052                	sd	s4,32(sp)
    80005570:	ec56                	sd	s5,24(sp)
    80005572:	e85a                	sd	s6,16(sp)
    80005574:	0880                	addi	s0,sp,80
    80005576:	84aa                	mv	s1,a0
    80005578:	892e                	mv	s2,a1
    8000557a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000557c:	ffffc097          	auipc	ra,0xffffc
    80005580:	582080e7          	jalr	1410(ra) # 80001afe <myproc>
    80005584:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005586:	8526                	mv	a0,s1
    80005588:	ffffb097          	auipc	ra,0xffffb
    8000558c:	64e080e7          	jalr	1614(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005590:	2184a703          	lw	a4,536(s1)
    80005594:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005598:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000559c:	02f71763          	bne	a4,a5,800055ca <piperead+0x68>
    800055a0:	2244a783          	lw	a5,548(s1)
    800055a4:	c39d                	beqz	a5,800055ca <piperead+0x68>
    if(killed(pr)){
    800055a6:	8552                	mv	a0,s4
    800055a8:	ffffd097          	auipc	ra,0xffffd
    800055ac:	f64080e7          	jalr	-156(ra) # 8000250c <killed>
    800055b0:	e941                	bnez	a0,80005640 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800055b2:	85a6                	mv	a1,s1
    800055b4:	854e                	mv	a0,s3
    800055b6:	ffffd097          	auipc	ra,0xffffd
    800055ba:	c98080e7          	jalr	-872(ra) # 8000224e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800055be:	2184a703          	lw	a4,536(s1)
    800055c2:	21c4a783          	lw	a5,540(s1)
    800055c6:	fcf70de3          	beq	a4,a5,800055a0 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800055ca:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800055cc:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800055ce:	05505363          	blez	s5,80005614 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    800055d2:	2184a783          	lw	a5,536(s1)
    800055d6:	21c4a703          	lw	a4,540(s1)
    800055da:	02f70d63          	beq	a4,a5,80005614 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800055de:	0017871b          	addiw	a4,a5,1
    800055e2:	20e4ac23          	sw	a4,536(s1)
    800055e6:	1ff7f793          	andi	a5,a5,511
    800055ea:	97a6                	add	a5,a5,s1
    800055ec:	0187c783          	lbu	a5,24(a5)
    800055f0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800055f4:	4685                	li	a3,1
    800055f6:	fbf40613          	addi	a2,s0,-65
    800055fa:	85ca                	mv	a1,s2
    800055fc:	050a3503          	ld	a0,80(s4)
    80005600:	ffffc097          	auipc	ra,0xffffc
    80005604:	1ba080e7          	jalr	442(ra) # 800017ba <copyout>
    80005608:	01650663          	beq	a0,s6,80005614 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000560c:	2985                	addiw	s3,s3,1
    8000560e:	0905                	addi	s2,s2,1
    80005610:	fd3a91e3          	bne	s5,s3,800055d2 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005614:	21c48513          	addi	a0,s1,540
    80005618:	ffffd097          	auipc	ra,0xffffd
    8000561c:	c9a080e7          	jalr	-870(ra) # 800022b2 <wakeup>
  release(&pi->lock);
    80005620:	8526                	mv	a0,s1
    80005622:	ffffb097          	auipc	ra,0xffffb
    80005626:	668080e7          	jalr	1640(ra) # 80000c8a <release>
  return i;
}
    8000562a:	854e                	mv	a0,s3
    8000562c:	60a6                	ld	ra,72(sp)
    8000562e:	6406                	ld	s0,64(sp)
    80005630:	74e2                	ld	s1,56(sp)
    80005632:	7942                	ld	s2,48(sp)
    80005634:	79a2                	ld	s3,40(sp)
    80005636:	7a02                	ld	s4,32(sp)
    80005638:	6ae2                	ld	s5,24(sp)
    8000563a:	6b42                	ld	s6,16(sp)
    8000563c:	6161                	addi	sp,sp,80
    8000563e:	8082                	ret
      release(&pi->lock);
    80005640:	8526                	mv	a0,s1
    80005642:	ffffb097          	auipc	ra,0xffffb
    80005646:	648080e7          	jalr	1608(ra) # 80000c8a <release>
      return -1;
    8000564a:	59fd                	li	s3,-1
    8000564c:	bff9                	j	8000562a <piperead+0xc8>

000000008000564e <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    8000564e:	1141                	addi	sp,sp,-16
    80005650:	e422                	sd	s0,8(sp)
    80005652:	0800                	addi	s0,sp,16
    80005654:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005656:	8905                	andi	a0,a0,1
    80005658:	c111                	beqz	a0,8000565c <flags2perm+0xe>
      perm = PTE_X;
    8000565a:	4521                	li	a0,8
    if(flags & 0x2)
    8000565c:	8b89                	andi	a5,a5,2
    8000565e:	c399                	beqz	a5,80005664 <flags2perm+0x16>
      perm |= PTE_W;
    80005660:	00456513          	ori	a0,a0,4
    return perm;
}
    80005664:	6422                	ld	s0,8(sp)
    80005666:	0141                	addi	sp,sp,16
    80005668:	8082                	ret

000000008000566a <exec>:

int
exec(char *path, char **argv)
{
    8000566a:	de010113          	addi	sp,sp,-544
    8000566e:	20113c23          	sd	ra,536(sp)
    80005672:	20813823          	sd	s0,528(sp)
    80005676:	20913423          	sd	s1,520(sp)
    8000567a:	21213023          	sd	s2,512(sp)
    8000567e:	ffce                	sd	s3,504(sp)
    80005680:	fbd2                	sd	s4,496(sp)
    80005682:	f7d6                	sd	s5,488(sp)
    80005684:	f3da                	sd	s6,480(sp)
    80005686:	efde                	sd	s7,472(sp)
    80005688:	ebe2                	sd	s8,464(sp)
    8000568a:	e7e6                	sd	s9,456(sp)
    8000568c:	e3ea                	sd	s10,448(sp)
    8000568e:	ff6e                	sd	s11,440(sp)
    80005690:	1400                	addi	s0,sp,544
    80005692:	dea43c23          	sd	a0,-520(s0)
    80005696:	deb43423          	sd	a1,-536(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000569a:	ffffc097          	auipc	ra,0xffffc
    8000569e:	464080e7          	jalr	1124(ra) # 80001afe <myproc>
    800056a2:	84aa                	mv	s1,a0

   //free the swap file when its not the shell& init proc 
  if(p->pid>2){
    800056a4:	5918                	lw	a4,48(a0)
    800056a6:	4789                	li	a5,2
    800056a8:	04e7df63          	bge	a5,a4,80005706 <exec+0x9c>
    struct metaData *page=p->pagesInPysical;
    800056ac:	28050713          	addi	a4,a0,640
    while(page< &p->pagesInPysical[MAX_PSYC_PAGES]){
    800056b0:	48050793          	addi	a5,a0,1152
    800056b4:	86be                	mv	a3,a5
      page->aging=0;
    800056b6:	00073c23          	sd	zero,24(a4)
      page->pageCreateTime=0;
    800056ba:	00073823          	sd	zero,16(a4)
      page->idxIsHere=0;
    800056be:	00073423          	sd	zero,8(a4)
      page->va=0;
    800056c2:	00073023          	sd	zero,0(a4)
      page++;
    800056c6:	02070713          	addi	a4,a4,32
    while(page< &p->pagesInPysical[MAX_PSYC_PAGES]){
    800056ca:	fed716e3          	bne	a4,a3,800056b6 <exec+0x4c>
    }
    
    page=p->pagesInSwap;
    while(page< &p->pagesInSwap[MAX_PSYC_PAGES]){
    800056ce:	68048713          	addi	a4,s1,1664
      page->aging=0;
    800056d2:	0007bc23          	sd	zero,24(a5)
      page->pageCreateTime=0;
    800056d6:	0007b823          	sd	zero,16(a5)
      page->idxIsHere=0;
    800056da:	0007b423          	sd	zero,8(a5)
      page->va=0;
    800056de:	0007b023          	sd	zero,0(a5)
      page++;
    800056e2:	02078793          	addi	a5,a5,32
    while(page< &p->pagesInSwap[MAX_PSYC_PAGES]){
    800056e6:	fee796e3          	bne	a5,a4,800056d2 <exec+0x68>
    }
    p->swapPagesCount=0;
    800056ea:	2604bc23          	sd	zero,632(s1)
    p->physicalPagesCount=0;
    800056ee:	2604b823          	sd	zero,624(s1)
    removeSwapFile(p);
    800056f2:	8526                	mv	a0,s1
    800056f4:	fffff097          	auipc	ra,0xfffff
    800056f8:	db8080e7          	jalr	-584(ra) # 800044ac <removeSwapFile>
    createSwapFile(p);
    800056fc:	8526                	mv	a0,s1
    800056fe:	fffff097          	auipc	ra,0xfffff
    80005702:	f56080e7          	jalr	-170(ra) # 80004654 <createSwapFile>
  }

  begin_op();
    80005706:	fffff097          	auipc	ra,0xfffff
    8000570a:	228080e7          	jalr	552(ra) # 8000492e <begin_op>

  if((ip = namei(path)) == 0){
    8000570e:	df843503          	ld	a0,-520(s0)
    80005712:	fffff097          	auipc	ra,0xfffff
    80005716:	cee080e7          	jalr	-786(ra) # 80004400 <namei>
    8000571a:	8aaa                	mv	s5,a0
    8000571c:	c935                	beqz	a0,80005790 <exec+0x126>
    end_op();
    return -1;
  }
  ilock(ip);
    8000571e:	ffffe097          	auipc	ra,0xffffe
    80005722:	53c080e7          	jalr	1340(ra) # 80003c5a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005726:	04000713          	li	a4,64
    8000572a:	4681                	li	a3,0
    8000572c:	e5040613          	addi	a2,s0,-432
    80005730:	4581                	li	a1,0
    80005732:	8556                	mv	a0,s5
    80005734:	ffffe097          	auipc	ra,0xffffe
    80005738:	7da080e7          	jalr	2010(ra) # 80003f0e <readi>
    8000573c:	04000793          	li	a5,64
    80005740:	00f51a63          	bne	a0,a5,80005754 <exec+0xea>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005744:	e5042703          	lw	a4,-432(s0)
    80005748:	464c47b7          	lui	a5,0x464c4
    8000574c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005750:	04f70663          	beq	a4,a5,8000579c <exec+0x132>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005754:	8556                	mv	a0,s5
    80005756:	ffffe097          	auipc	ra,0xffffe
    8000575a:	766080e7          	jalr	1894(ra) # 80003ebc <iunlockput>
    end_op();
    8000575e:	fffff097          	auipc	ra,0xfffff
    80005762:	250080e7          	jalr	592(ra) # 800049ae <end_op>
  }
  return -1;
    80005766:	557d                	li	a0,-1
}
    80005768:	21813083          	ld	ra,536(sp)
    8000576c:	21013403          	ld	s0,528(sp)
    80005770:	20813483          	ld	s1,520(sp)
    80005774:	20013903          	ld	s2,512(sp)
    80005778:	79fe                	ld	s3,504(sp)
    8000577a:	7a5e                	ld	s4,496(sp)
    8000577c:	7abe                	ld	s5,488(sp)
    8000577e:	7b1e                	ld	s6,480(sp)
    80005780:	6bfe                	ld	s7,472(sp)
    80005782:	6c5e                	ld	s8,464(sp)
    80005784:	6cbe                	ld	s9,456(sp)
    80005786:	6d1e                	ld	s10,448(sp)
    80005788:	7dfa                	ld	s11,440(sp)
    8000578a:	22010113          	addi	sp,sp,544
    8000578e:	8082                	ret
    end_op();
    80005790:	fffff097          	auipc	ra,0xfffff
    80005794:	21e080e7          	jalr	542(ra) # 800049ae <end_op>
    return -1;
    80005798:	557d                	li	a0,-1
    8000579a:	b7f9                	j	80005768 <exec+0xfe>
  if((pagetable = proc_pagetable(p)) == 0)
    8000579c:	8526                	mv	a0,s1
    8000579e:	ffffc097          	auipc	ra,0xffffc
    800057a2:	424080e7          	jalr	1060(ra) # 80001bc2 <proc_pagetable>
    800057a6:	8b2a                	mv	s6,a0
    800057a8:	d555                	beqz	a0,80005754 <exec+0xea>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800057aa:	e7042783          	lw	a5,-400(s0)
    800057ae:	e8845703          	lhu	a4,-376(s0)
    800057b2:	c735                	beqz	a4,8000581e <exec+0x1b4>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800057b4:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800057b6:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800057ba:	6a05                	lui	s4,0x1
    800057bc:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800057c0:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800057c4:	6d85                	lui	s11,0x1
    800057c6:	7d7d                	lui	s10,0xfffff
    800057c8:	a481                	j	80005a08 <exec+0x39e>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800057ca:	00003517          	auipc	a0,0x3
    800057ce:	01e50513          	addi	a0,a0,30 # 800087e8 <syscalls+0x2f0>
    800057d2:	ffffb097          	auipc	ra,0xffffb
    800057d6:	d6c080e7          	jalr	-660(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800057da:	874a                	mv	a4,s2
    800057dc:	009c86bb          	addw	a3,s9,s1
    800057e0:	4581                	li	a1,0
    800057e2:	8556                	mv	a0,s5
    800057e4:	ffffe097          	auipc	ra,0xffffe
    800057e8:	72a080e7          	jalr	1834(ra) # 80003f0e <readi>
    800057ec:	2501                	sext.w	a0,a0
    800057ee:	1aa91a63          	bne	s2,a0,800059a2 <exec+0x338>
  for(i = 0; i < sz; i += PGSIZE){
    800057f2:	009d84bb          	addw	s1,s11,s1
    800057f6:	013d09bb          	addw	s3,s10,s3
    800057fa:	1f74f763          	bgeu	s1,s7,800059e8 <exec+0x37e>
    pa = walkaddr(pagetable, va + i);
    800057fe:	02049593          	slli	a1,s1,0x20
    80005802:	9181                	srli	a1,a1,0x20
    80005804:	95e2                	add	a1,a1,s8
    80005806:	855a                	mv	a0,s6
    80005808:	ffffc097          	auipc	ra,0xffffc
    8000580c:	908080e7          	jalr	-1784(ra) # 80001110 <walkaddr>
    80005810:	862a                	mv	a2,a0
    if(pa == 0)
    80005812:	dd45                	beqz	a0,800057ca <exec+0x160>
      n = PGSIZE;
    80005814:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005816:	fd49f2e3          	bgeu	s3,s4,800057da <exec+0x170>
      n = sz - i;
    8000581a:	894e                	mv	s2,s3
    8000581c:	bf7d                	j	800057da <exec+0x170>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000581e:	4901                	li	s2,0
  iunlockput(ip);
    80005820:	8556                	mv	a0,s5
    80005822:	ffffe097          	auipc	ra,0xffffe
    80005826:	69a080e7          	jalr	1690(ra) # 80003ebc <iunlockput>
  end_op();
    8000582a:	fffff097          	auipc	ra,0xfffff
    8000582e:	184080e7          	jalr	388(ra) # 800049ae <end_op>
  p = myproc();
    80005832:	ffffc097          	auipc	ra,0xffffc
    80005836:	2cc080e7          	jalr	716(ra) # 80001afe <myproc>
    8000583a:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000583c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005840:	6785                	lui	a5,0x1
    80005842:	17fd                	addi	a5,a5,-1
    80005844:	993e                	add	s2,s2,a5
    80005846:	77fd                	lui	a5,0xfffff
    80005848:	00f977b3          	and	a5,s2,a5
    8000584c:	def43823          	sd	a5,-528(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005850:	4691                	li	a3,4
    80005852:	6609                	lui	a2,0x2
    80005854:	963e                	add	a2,a2,a5
    80005856:	85be                	mv	a1,a5
    80005858:	855a                	mv	a0,s6
    8000585a:	ffffc097          	auipc	ra,0xffffc
    8000585e:	c7a080e7          	jalr	-902(ra) # 800014d4 <uvmalloc>
    80005862:	8c2a                	mv	s8,a0
  ip = 0;
    80005864:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005866:	12050e63          	beqz	a0,800059a2 <exec+0x338>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000586a:	75f9                	lui	a1,0xffffe
    8000586c:	95aa                	add	a1,a1,a0
    8000586e:	855a                	mv	a0,s6
    80005870:	ffffc097          	auipc	ra,0xffffc
    80005874:	f18080e7          	jalr	-232(ra) # 80001788 <uvmclear>
  stackbase = sp - PGSIZE;
    80005878:	7afd                	lui	s5,0xfffff
    8000587a:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    8000587c:	de843783          	ld	a5,-536(s0)
    80005880:	6388                	ld	a0,0(a5)
    80005882:	c925                	beqz	a0,800058f2 <exec+0x288>
    80005884:	e9040993          	addi	s3,s0,-368
    80005888:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000588c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000588e:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005890:	ffffb097          	auipc	ra,0xffffb
    80005894:	5be080e7          	jalr	1470(ra) # 80000e4e <strlen>
    80005898:	0015079b          	addiw	a5,a0,1
    8000589c:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800058a0:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800058a4:	13596663          	bltu	s2,s5,800059d0 <exec+0x366>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800058a8:	de843d83          	ld	s11,-536(s0)
    800058ac:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800058b0:	8552                	mv	a0,s4
    800058b2:	ffffb097          	auipc	ra,0xffffb
    800058b6:	59c080e7          	jalr	1436(ra) # 80000e4e <strlen>
    800058ba:	0015069b          	addiw	a3,a0,1
    800058be:	8652                	mv	a2,s4
    800058c0:	85ca                	mv	a1,s2
    800058c2:	855a                	mv	a0,s6
    800058c4:	ffffc097          	auipc	ra,0xffffc
    800058c8:	ef6080e7          	jalr	-266(ra) # 800017ba <copyout>
    800058cc:	10054663          	bltz	a0,800059d8 <exec+0x36e>
    ustack[argc] = sp;
    800058d0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800058d4:	0485                	addi	s1,s1,1
    800058d6:	008d8793          	addi	a5,s11,8
    800058da:	def43423          	sd	a5,-536(s0)
    800058de:	008db503          	ld	a0,8(s11)
    800058e2:	c911                	beqz	a0,800058f6 <exec+0x28c>
    if(argc >= MAXARG)
    800058e4:	09a1                	addi	s3,s3,8
    800058e6:	fb9995e3          	bne	s3,s9,80005890 <exec+0x226>
  sz = sz1;
    800058ea:	df843823          	sd	s8,-528(s0)
  ip = 0;
    800058ee:	4a81                	li	s5,0
    800058f0:	a84d                	j	800059a2 <exec+0x338>
  sp = sz;
    800058f2:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800058f4:	4481                	li	s1,0
  ustack[argc] = 0;
    800058f6:	00349793          	slli	a5,s1,0x3
    800058fa:	f9040713          	addi	a4,s0,-112
    800058fe:	97ba                	add	a5,a5,a4
    80005900:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffc88c0>
  sp -= (argc+1) * sizeof(uint64);
    80005904:	00148693          	addi	a3,s1,1
    80005908:	068e                	slli	a3,a3,0x3
    8000590a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000590e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005912:	01597663          	bgeu	s2,s5,8000591e <exec+0x2b4>
  sz = sz1;
    80005916:	df843823          	sd	s8,-528(s0)
  ip = 0;
    8000591a:	4a81                	li	s5,0
    8000591c:	a059                	j	800059a2 <exec+0x338>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000591e:	e9040613          	addi	a2,s0,-368
    80005922:	85ca                	mv	a1,s2
    80005924:	855a                	mv	a0,s6
    80005926:	ffffc097          	auipc	ra,0xffffc
    8000592a:	e94080e7          	jalr	-364(ra) # 800017ba <copyout>
    8000592e:	0a054963          	bltz	a0,800059e0 <exec+0x376>
  p->trapframe->a1 = sp;
    80005932:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005936:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000593a:	df843783          	ld	a5,-520(s0)
    8000593e:	0007c703          	lbu	a4,0(a5)
    80005942:	cf11                	beqz	a4,8000595e <exec+0x2f4>
    80005944:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005946:	02f00693          	li	a3,47
    8000594a:	a039                	j	80005958 <exec+0x2ee>
      last = s+1;
    8000594c:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005950:	0785                	addi	a5,a5,1
    80005952:	fff7c703          	lbu	a4,-1(a5)
    80005956:	c701                	beqz	a4,8000595e <exec+0x2f4>
    if(*s == '/')
    80005958:	fed71ce3          	bne	a4,a3,80005950 <exec+0x2e6>
    8000595c:	bfc5                	j	8000594c <exec+0x2e2>
  safestrcpy(p->name, last, sizeof(p->name));
    8000595e:	4641                	li	a2,16
    80005960:	df843583          	ld	a1,-520(s0)
    80005964:	158b8513          	addi	a0,s7,344
    80005968:	ffffb097          	auipc	ra,0xffffb
    8000596c:	4b4080e7          	jalr	1204(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80005970:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005974:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005978:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000597c:	058bb783          	ld	a5,88(s7)
    80005980:	e6843703          	ld	a4,-408(s0)
    80005984:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005986:	058bb783          	ld	a5,88(s7)
    8000598a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000598e:	85ea                	mv	a1,s10
    80005990:	ffffc097          	auipc	ra,0xffffc
    80005994:	2ce080e7          	jalr	718(ra) # 80001c5e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005998:	0004851b          	sext.w	a0,s1
    8000599c:	b3f1                	j	80005768 <exec+0xfe>
    8000599e:	df243823          	sd	s2,-528(s0)
    proc_freepagetable(pagetable, sz);
    800059a2:	df043583          	ld	a1,-528(s0)
    800059a6:	855a                	mv	a0,s6
    800059a8:	ffffc097          	auipc	ra,0xffffc
    800059ac:	2b6080e7          	jalr	694(ra) # 80001c5e <proc_freepagetable>
  if(ip){
    800059b0:	da0a92e3          	bnez	s5,80005754 <exec+0xea>
  return -1;
    800059b4:	557d                	li	a0,-1
    800059b6:	bb4d                	j	80005768 <exec+0xfe>
    800059b8:	df243823          	sd	s2,-528(s0)
    800059bc:	b7dd                	j	800059a2 <exec+0x338>
    800059be:	df243823          	sd	s2,-528(s0)
    800059c2:	b7c5                	j	800059a2 <exec+0x338>
    800059c4:	df243823          	sd	s2,-528(s0)
    800059c8:	bfe9                	j	800059a2 <exec+0x338>
    800059ca:	df243823          	sd	s2,-528(s0)
    800059ce:	bfd1                	j	800059a2 <exec+0x338>
  sz = sz1;
    800059d0:	df843823          	sd	s8,-528(s0)
  ip = 0;
    800059d4:	4a81                	li	s5,0
    800059d6:	b7f1                	j	800059a2 <exec+0x338>
  sz = sz1;
    800059d8:	df843823          	sd	s8,-528(s0)
  ip = 0;
    800059dc:	4a81                	li	s5,0
    800059de:	b7d1                	j	800059a2 <exec+0x338>
  sz = sz1;
    800059e0:	df843823          	sd	s8,-528(s0)
  ip = 0;
    800059e4:	4a81                	li	s5,0
    800059e6:	bf75                	j	800059a2 <exec+0x338>
    sz = sz1;
    800059e8:	df043903          	ld	s2,-528(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800059ec:	e0843783          	ld	a5,-504(s0)
    800059f0:	0017869b          	addiw	a3,a5,1
    800059f4:	e0d43423          	sd	a3,-504(s0)
    800059f8:	e0043783          	ld	a5,-512(s0)
    800059fc:	0387879b          	addiw	a5,a5,56
    80005a00:	e8845703          	lhu	a4,-376(s0)
    80005a04:	e0e6dee3          	bge	a3,a4,80005820 <exec+0x1b6>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005a08:	2781                	sext.w	a5,a5
    80005a0a:	e0f43023          	sd	a5,-512(s0)
    80005a0e:	03800713          	li	a4,56
    80005a12:	86be                	mv	a3,a5
    80005a14:	e1840613          	addi	a2,s0,-488
    80005a18:	4581                	li	a1,0
    80005a1a:	8556                	mv	a0,s5
    80005a1c:	ffffe097          	auipc	ra,0xffffe
    80005a20:	4f2080e7          	jalr	1266(ra) # 80003f0e <readi>
    80005a24:	03800793          	li	a5,56
    80005a28:	f6f51be3          	bne	a0,a5,8000599e <exec+0x334>
    if(ph.type != ELF_PROG_LOAD)
    80005a2c:	e1842783          	lw	a5,-488(s0)
    80005a30:	4705                	li	a4,1
    80005a32:	fae79de3          	bne	a5,a4,800059ec <exec+0x382>
    if(ph.memsz < ph.filesz)
    80005a36:	e4043483          	ld	s1,-448(s0)
    80005a3a:	e3843783          	ld	a5,-456(s0)
    80005a3e:	f6f4ede3          	bltu	s1,a5,800059b8 <exec+0x34e>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005a42:	e2843783          	ld	a5,-472(s0)
    80005a46:	94be                	add	s1,s1,a5
    80005a48:	f6f4ebe3          	bltu	s1,a5,800059be <exec+0x354>
    if(ph.vaddr % PGSIZE != 0)
    80005a4c:	de043703          	ld	a4,-544(s0)
    80005a50:	8ff9                	and	a5,a5,a4
    80005a52:	fbad                	bnez	a5,800059c4 <exec+0x35a>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005a54:	e1c42503          	lw	a0,-484(s0)
    80005a58:	00000097          	auipc	ra,0x0
    80005a5c:	bf6080e7          	jalr	-1034(ra) # 8000564e <flags2perm>
    80005a60:	86aa                	mv	a3,a0
    80005a62:	8626                	mv	a2,s1
    80005a64:	85ca                	mv	a1,s2
    80005a66:	855a                	mv	a0,s6
    80005a68:	ffffc097          	auipc	ra,0xffffc
    80005a6c:	a6c080e7          	jalr	-1428(ra) # 800014d4 <uvmalloc>
    80005a70:	dea43823          	sd	a0,-528(s0)
    80005a74:	d939                	beqz	a0,800059ca <exec+0x360>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005a76:	e2843c03          	ld	s8,-472(s0)
    80005a7a:	e2042c83          	lw	s9,-480(s0)
    80005a7e:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005a82:	f60b83e3          	beqz	s7,800059e8 <exec+0x37e>
    80005a86:	89de                	mv	s3,s7
    80005a88:	4481                	li	s1,0
    80005a8a:	bb95                	j	800057fe <exec+0x194>

0000000080005a8c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005a8c:	7179                	addi	sp,sp,-48
    80005a8e:	f406                	sd	ra,40(sp)
    80005a90:	f022                	sd	s0,32(sp)
    80005a92:	ec26                	sd	s1,24(sp)
    80005a94:	e84a                	sd	s2,16(sp)
    80005a96:	1800                	addi	s0,sp,48
    80005a98:	892e                	mv	s2,a1
    80005a9a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005a9c:	fdc40593          	addi	a1,s0,-36
    80005aa0:	ffffd097          	auipc	ra,0xffffd
    80005aa4:	64e080e7          	jalr	1614(ra) # 800030ee <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005aa8:	fdc42703          	lw	a4,-36(s0)
    80005aac:	47bd                	li	a5,15
    80005aae:	02e7eb63          	bltu	a5,a4,80005ae4 <argfd+0x58>
    80005ab2:	ffffc097          	auipc	ra,0xffffc
    80005ab6:	04c080e7          	jalr	76(ra) # 80001afe <myproc>
    80005aba:	fdc42703          	lw	a4,-36(s0)
    80005abe:	01a70793          	addi	a5,a4,26
    80005ac2:	078e                	slli	a5,a5,0x3
    80005ac4:	953e                	add	a0,a0,a5
    80005ac6:	611c                	ld	a5,0(a0)
    80005ac8:	c385                	beqz	a5,80005ae8 <argfd+0x5c>
    return -1;
  if(pfd)
    80005aca:	00090463          	beqz	s2,80005ad2 <argfd+0x46>
    *pfd = fd;
    80005ace:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005ad2:	4501                	li	a0,0
  if(pf)
    80005ad4:	c091                	beqz	s1,80005ad8 <argfd+0x4c>
    *pf = f;
    80005ad6:	e09c                	sd	a5,0(s1)
}
    80005ad8:	70a2                	ld	ra,40(sp)
    80005ada:	7402                	ld	s0,32(sp)
    80005adc:	64e2                	ld	s1,24(sp)
    80005ade:	6942                	ld	s2,16(sp)
    80005ae0:	6145                	addi	sp,sp,48
    80005ae2:	8082                	ret
    return -1;
    80005ae4:	557d                	li	a0,-1
    80005ae6:	bfcd                	j	80005ad8 <argfd+0x4c>
    80005ae8:	557d                	li	a0,-1
    80005aea:	b7fd                	j	80005ad8 <argfd+0x4c>

0000000080005aec <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005aec:	1101                	addi	sp,sp,-32
    80005aee:	ec06                	sd	ra,24(sp)
    80005af0:	e822                	sd	s0,16(sp)
    80005af2:	e426                	sd	s1,8(sp)
    80005af4:	1000                	addi	s0,sp,32
    80005af6:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005af8:	ffffc097          	auipc	ra,0xffffc
    80005afc:	006080e7          	jalr	6(ra) # 80001afe <myproc>
    80005b00:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005b02:	0d050793          	addi	a5,a0,208
    80005b06:	4501                	li	a0,0
    80005b08:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005b0a:	6398                	ld	a4,0(a5)
    80005b0c:	cb19                	beqz	a4,80005b22 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005b0e:	2505                	addiw	a0,a0,1
    80005b10:	07a1                	addi	a5,a5,8
    80005b12:	fed51ce3          	bne	a0,a3,80005b0a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005b16:	557d                	li	a0,-1
}
    80005b18:	60e2                	ld	ra,24(sp)
    80005b1a:	6442                	ld	s0,16(sp)
    80005b1c:	64a2                	ld	s1,8(sp)
    80005b1e:	6105                	addi	sp,sp,32
    80005b20:	8082                	ret
      p->ofile[fd] = f;
    80005b22:	01a50793          	addi	a5,a0,26
    80005b26:	078e                	slli	a5,a5,0x3
    80005b28:	963e                	add	a2,a2,a5
    80005b2a:	e204                	sd	s1,0(a2)
      return fd;
    80005b2c:	b7f5                	j	80005b18 <fdalloc+0x2c>

0000000080005b2e <sys_dup>:

uint64
sys_dup(void)
{
    80005b2e:	7179                	addi	sp,sp,-48
    80005b30:	f406                	sd	ra,40(sp)
    80005b32:	f022                	sd	s0,32(sp)
    80005b34:	ec26                	sd	s1,24(sp)
    80005b36:	1800                	addi	s0,sp,48
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)
    80005b38:	fd840613          	addi	a2,s0,-40
    80005b3c:	4581                	li	a1,0
    80005b3e:	4501                	li	a0,0
    80005b40:	00000097          	auipc	ra,0x0
    80005b44:	f4c080e7          	jalr	-180(ra) # 80005a8c <argfd>
    return -1;
    80005b48:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005b4a:	02054363          	bltz	a0,80005b70 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005b4e:	fd843503          	ld	a0,-40(s0)
    80005b52:	00000097          	auipc	ra,0x0
    80005b56:	f9a080e7          	jalr	-102(ra) # 80005aec <fdalloc>
    80005b5a:	84aa                	mv	s1,a0
    return -1;
    80005b5c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005b5e:	00054963          	bltz	a0,80005b70 <sys_dup+0x42>
  filedup(f);
    80005b62:	fd843503          	ld	a0,-40(s0)
    80005b66:	fffff097          	auipc	ra,0xfffff
    80005b6a:	242080e7          	jalr	578(ra) # 80004da8 <filedup>
  return fd;
    80005b6e:	87a6                	mv	a5,s1
}
    80005b70:	853e                	mv	a0,a5
    80005b72:	70a2                	ld	ra,40(sp)
    80005b74:	7402                	ld	s0,32(sp)
    80005b76:	64e2                	ld	s1,24(sp)
    80005b78:	6145                	addi	sp,sp,48
    80005b7a:	8082                	ret

0000000080005b7c <sys_read>:

uint64
sys_read(void)
{
    80005b7c:	7179                	addi	sp,sp,-48
    80005b7e:	f406                	sd	ra,40(sp)
    80005b80:	f022                	sd	s0,32(sp)
    80005b82:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  argaddr(1, &p);
    80005b84:	fd840593          	addi	a1,s0,-40
    80005b88:	4505                	li	a0,1
    80005b8a:	ffffd097          	auipc	ra,0xffffd
    80005b8e:	584080e7          	jalr	1412(ra) # 8000310e <argaddr>
  argint(2, &n);
    80005b92:	fe440593          	addi	a1,s0,-28
    80005b96:	4509                	li	a0,2
    80005b98:	ffffd097          	auipc	ra,0xffffd
    80005b9c:	556080e7          	jalr	1366(ra) # 800030ee <argint>
  if(argfd(0, 0, &f) < 0)
    80005ba0:	fe840613          	addi	a2,s0,-24
    80005ba4:	4581                	li	a1,0
    80005ba6:	4501                	li	a0,0
    80005ba8:	00000097          	auipc	ra,0x0
    80005bac:	ee4080e7          	jalr	-284(ra) # 80005a8c <argfd>
    80005bb0:	87aa                	mv	a5,a0
    return -1;
    80005bb2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005bb4:	0007cc63          	bltz	a5,80005bcc <sys_read+0x50>
  return fileread(f, p, n);
    80005bb8:	fe442603          	lw	a2,-28(s0)
    80005bbc:	fd843583          	ld	a1,-40(s0)
    80005bc0:	fe843503          	ld	a0,-24(s0)
    80005bc4:	fffff097          	auipc	ra,0xfffff
    80005bc8:	370080e7          	jalr	880(ra) # 80004f34 <fileread>
}
    80005bcc:	70a2                	ld	ra,40(sp)
    80005bce:	7402                	ld	s0,32(sp)
    80005bd0:	6145                	addi	sp,sp,48
    80005bd2:	8082                	ret

0000000080005bd4 <sys_write>:

uint64
sys_write(void)
{
    80005bd4:	7179                	addi	sp,sp,-48
    80005bd6:	f406                	sd	ra,40(sp)
    80005bd8:	f022                	sd	s0,32(sp)
    80005bda:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;
  
  argaddr(1, &p);
    80005bdc:	fd840593          	addi	a1,s0,-40
    80005be0:	4505                	li	a0,1
    80005be2:	ffffd097          	auipc	ra,0xffffd
    80005be6:	52c080e7          	jalr	1324(ra) # 8000310e <argaddr>
  argint(2, &n);
    80005bea:	fe440593          	addi	a1,s0,-28
    80005bee:	4509                	li	a0,2
    80005bf0:	ffffd097          	auipc	ra,0xffffd
    80005bf4:	4fe080e7          	jalr	1278(ra) # 800030ee <argint>
  if(argfd(0, 0, &f) < 0)
    80005bf8:	fe840613          	addi	a2,s0,-24
    80005bfc:	4581                	li	a1,0
    80005bfe:	4501                	li	a0,0
    80005c00:	00000097          	auipc	ra,0x0
    80005c04:	e8c080e7          	jalr	-372(ra) # 80005a8c <argfd>
    80005c08:	87aa                	mv	a5,a0
    return -1;
    80005c0a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005c0c:	0007cc63          	bltz	a5,80005c24 <sys_write+0x50>

  return filewrite(f, p, n);
    80005c10:	fe442603          	lw	a2,-28(s0)
    80005c14:	fd843583          	ld	a1,-40(s0)
    80005c18:	fe843503          	ld	a0,-24(s0)
    80005c1c:	fffff097          	auipc	ra,0xfffff
    80005c20:	3da080e7          	jalr	986(ra) # 80004ff6 <filewrite>
}
    80005c24:	70a2                	ld	ra,40(sp)
    80005c26:	7402                	ld	s0,32(sp)
    80005c28:	6145                	addi	sp,sp,48
    80005c2a:	8082                	ret

0000000080005c2c <sys_close>:

uint64
sys_close(void)
{
    80005c2c:	1101                	addi	sp,sp,-32
    80005c2e:	ec06                	sd	ra,24(sp)
    80005c30:	e822                	sd	s0,16(sp)
    80005c32:	1000                	addi	s0,sp,32
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)
    80005c34:	fe040613          	addi	a2,s0,-32
    80005c38:	fec40593          	addi	a1,s0,-20
    80005c3c:	4501                	li	a0,0
    80005c3e:	00000097          	auipc	ra,0x0
    80005c42:	e4e080e7          	jalr	-434(ra) # 80005a8c <argfd>
    return -1;
    80005c46:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005c48:	02054463          	bltz	a0,80005c70 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005c4c:	ffffc097          	auipc	ra,0xffffc
    80005c50:	eb2080e7          	jalr	-334(ra) # 80001afe <myproc>
    80005c54:	fec42783          	lw	a5,-20(s0)
    80005c58:	07e9                	addi	a5,a5,26
    80005c5a:	078e                	slli	a5,a5,0x3
    80005c5c:	97aa                	add	a5,a5,a0
    80005c5e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005c62:	fe043503          	ld	a0,-32(s0)
    80005c66:	fffff097          	auipc	ra,0xfffff
    80005c6a:	194080e7          	jalr	404(ra) # 80004dfa <fileclose>
  return 0;
    80005c6e:	4781                	li	a5,0
}
    80005c70:	853e                	mv	a0,a5
    80005c72:	60e2                	ld	ra,24(sp)
    80005c74:	6442                	ld	s0,16(sp)
    80005c76:	6105                	addi	sp,sp,32
    80005c78:	8082                	ret

0000000080005c7a <sys_fstat>:

uint64
sys_fstat(void)
{
    80005c7a:	1101                	addi	sp,sp,-32
    80005c7c:	ec06                	sd	ra,24(sp)
    80005c7e:	e822                	sd	s0,16(sp)
    80005c80:	1000                	addi	s0,sp,32
  struct file *f;
  uint64 st; // user pointer to struct stat

  argaddr(1, &st);
    80005c82:	fe040593          	addi	a1,s0,-32
    80005c86:	4505                	li	a0,1
    80005c88:	ffffd097          	auipc	ra,0xffffd
    80005c8c:	486080e7          	jalr	1158(ra) # 8000310e <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005c90:	fe840613          	addi	a2,s0,-24
    80005c94:	4581                	li	a1,0
    80005c96:	4501                	li	a0,0
    80005c98:	00000097          	auipc	ra,0x0
    80005c9c:	df4080e7          	jalr	-524(ra) # 80005a8c <argfd>
    80005ca0:	87aa                	mv	a5,a0
    return -1;
    80005ca2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005ca4:	0007ca63          	bltz	a5,80005cb8 <sys_fstat+0x3e>
  return filestat(f, st);
    80005ca8:	fe043583          	ld	a1,-32(s0)
    80005cac:	fe843503          	ld	a0,-24(s0)
    80005cb0:	fffff097          	auipc	ra,0xfffff
    80005cb4:	212080e7          	jalr	530(ra) # 80004ec2 <filestat>
}
    80005cb8:	60e2                	ld	ra,24(sp)
    80005cba:	6442                	ld	s0,16(sp)
    80005cbc:	6105                	addi	sp,sp,32
    80005cbe:	8082                	ret

0000000080005cc0 <sys_link>:

// Create the path new as a link to the same inode as old.
uint64
sys_link(void)
{
    80005cc0:	7169                	addi	sp,sp,-304
    80005cc2:	f606                	sd	ra,296(sp)
    80005cc4:	f222                	sd	s0,288(sp)
    80005cc6:	ee26                	sd	s1,280(sp)
    80005cc8:	ea4a                	sd	s2,272(sp)
    80005cca:	1a00                	addi	s0,sp,304
  char name[DIRSIZ], new[MAXPATH], old[MAXPATH];
  struct inode *dp, *ip;

  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ccc:	08000613          	li	a2,128
    80005cd0:	ed040593          	addi	a1,s0,-304
    80005cd4:	4501                	li	a0,0
    80005cd6:	ffffd097          	auipc	ra,0xffffd
    80005cda:	458080e7          	jalr	1112(ra) # 8000312e <argstr>
    return -1;
    80005cde:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ce0:	10054e63          	bltz	a0,80005dfc <sys_link+0x13c>
    80005ce4:	08000613          	li	a2,128
    80005ce8:	f5040593          	addi	a1,s0,-176
    80005cec:	4505                	li	a0,1
    80005cee:	ffffd097          	auipc	ra,0xffffd
    80005cf2:	440080e7          	jalr	1088(ra) # 8000312e <argstr>
    return -1;
    80005cf6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005cf8:	10054263          	bltz	a0,80005dfc <sys_link+0x13c>

  begin_op();
    80005cfc:	fffff097          	auipc	ra,0xfffff
    80005d00:	c32080e7          	jalr	-974(ra) # 8000492e <begin_op>
  if((ip = namei(old)) == 0){
    80005d04:	ed040513          	addi	a0,s0,-304
    80005d08:	ffffe097          	auipc	ra,0xffffe
    80005d0c:	6f8080e7          	jalr	1784(ra) # 80004400 <namei>
    80005d10:	84aa                	mv	s1,a0
    80005d12:	c551                	beqz	a0,80005d9e <sys_link+0xde>
    end_op();
    return -1;
  }

  ilock(ip);
    80005d14:	ffffe097          	auipc	ra,0xffffe
    80005d18:	f46080e7          	jalr	-186(ra) # 80003c5a <ilock>
  if(ip->type == T_DIR){
    80005d1c:	04449703          	lh	a4,68(s1)
    80005d20:	4785                	li	a5,1
    80005d22:	08f70463          	beq	a4,a5,80005daa <sys_link+0xea>
    iunlockput(ip);
    end_op();
    return -1;
  }

  ip->nlink++;
    80005d26:	04a4d783          	lhu	a5,74(s1)
    80005d2a:	2785                	addiw	a5,a5,1
    80005d2c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005d30:	8526                	mv	a0,s1
    80005d32:	ffffe097          	auipc	ra,0xffffe
    80005d36:	e5e080e7          	jalr	-418(ra) # 80003b90 <iupdate>
  iunlock(ip);
    80005d3a:	8526                	mv	a0,s1
    80005d3c:	ffffe097          	auipc	ra,0xffffe
    80005d40:	fe0080e7          	jalr	-32(ra) # 80003d1c <iunlock>

  if((dp = nameiparent(new, name)) == 0)
    80005d44:	fd040593          	addi	a1,s0,-48
    80005d48:	f5040513          	addi	a0,s0,-176
    80005d4c:	ffffe097          	auipc	ra,0xffffe
    80005d50:	6d2080e7          	jalr	1746(ra) # 8000441e <nameiparent>
    80005d54:	892a                	mv	s2,a0
    80005d56:	c935                	beqz	a0,80005dca <sys_link+0x10a>
    goto bad;
  ilock(dp);
    80005d58:	ffffe097          	auipc	ra,0xffffe
    80005d5c:	f02080e7          	jalr	-254(ra) # 80003c5a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005d60:	00092703          	lw	a4,0(s2)
    80005d64:	409c                	lw	a5,0(s1)
    80005d66:	04f71d63          	bne	a4,a5,80005dc0 <sys_link+0x100>
    80005d6a:	40d0                	lw	a2,4(s1)
    80005d6c:	fd040593          	addi	a1,s0,-48
    80005d70:	854a                	mv	a0,s2
    80005d72:	ffffe097          	auipc	ra,0xffffe
    80005d76:	5dc080e7          	jalr	1500(ra) # 8000434e <dirlink>
    80005d7a:	04054363          	bltz	a0,80005dc0 <sys_link+0x100>
    iunlockput(dp);
    goto bad;
  }
  iunlockput(dp);
    80005d7e:	854a                	mv	a0,s2
    80005d80:	ffffe097          	auipc	ra,0xffffe
    80005d84:	13c080e7          	jalr	316(ra) # 80003ebc <iunlockput>
  iput(ip);
    80005d88:	8526                	mv	a0,s1
    80005d8a:	ffffe097          	auipc	ra,0xffffe
    80005d8e:	08a080e7          	jalr	138(ra) # 80003e14 <iput>

  end_op();
    80005d92:	fffff097          	auipc	ra,0xfffff
    80005d96:	c1c080e7          	jalr	-996(ra) # 800049ae <end_op>

  return 0;
    80005d9a:	4781                	li	a5,0
    80005d9c:	a085                	j	80005dfc <sys_link+0x13c>
    end_op();
    80005d9e:	fffff097          	auipc	ra,0xfffff
    80005da2:	c10080e7          	jalr	-1008(ra) # 800049ae <end_op>
    return -1;
    80005da6:	57fd                	li	a5,-1
    80005da8:	a891                	j	80005dfc <sys_link+0x13c>
    iunlockput(ip);
    80005daa:	8526                	mv	a0,s1
    80005dac:	ffffe097          	auipc	ra,0xffffe
    80005db0:	110080e7          	jalr	272(ra) # 80003ebc <iunlockput>
    end_op();
    80005db4:	fffff097          	auipc	ra,0xfffff
    80005db8:	bfa080e7          	jalr	-1030(ra) # 800049ae <end_op>
    return -1;
    80005dbc:	57fd                	li	a5,-1
    80005dbe:	a83d                	j	80005dfc <sys_link+0x13c>
    iunlockput(dp);
    80005dc0:	854a                	mv	a0,s2
    80005dc2:	ffffe097          	auipc	ra,0xffffe
    80005dc6:	0fa080e7          	jalr	250(ra) # 80003ebc <iunlockput>

bad:
  ilock(ip);
    80005dca:	8526                	mv	a0,s1
    80005dcc:	ffffe097          	auipc	ra,0xffffe
    80005dd0:	e8e080e7          	jalr	-370(ra) # 80003c5a <ilock>
  ip->nlink--;
    80005dd4:	04a4d783          	lhu	a5,74(s1)
    80005dd8:	37fd                	addiw	a5,a5,-1
    80005dda:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005dde:	8526                	mv	a0,s1
    80005de0:	ffffe097          	auipc	ra,0xffffe
    80005de4:	db0080e7          	jalr	-592(ra) # 80003b90 <iupdate>
  iunlockput(ip);
    80005de8:	8526                	mv	a0,s1
    80005dea:	ffffe097          	auipc	ra,0xffffe
    80005dee:	0d2080e7          	jalr	210(ra) # 80003ebc <iunlockput>
  end_op();
    80005df2:	fffff097          	auipc	ra,0xfffff
    80005df6:	bbc080e7          	jalr	-1092(ra) # 800049ae <end_op>
  return -1;
    80005dfa:	57fd                	li	a5,-1
}
    80005dfc:	853e                	mv	a0,a5
    80005dfe:	70b2                	ld	ra,296(sp)
    80005e00:	7412                	ld	s0,288(sp)
    80005e02:	64f2                	ld	s1,280(sp)
    80005e04:	6952                	ld	s2,272(sp)
    80005e06:	6155                	addi	sp,sp,304
    80005e08:	8082                	ret

0000000080005e0a <isdirempty>:
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e0a:	4578                	lw	a4,76(a0)
    80005e0c:	02000793          	li	a5,32
    80005e10:	04e7fa63          	bgeu	a5,a4,80005e64 <isdirempty+0x5a>
{
    80005e14:	7179                	addi	sp,sp,-48
    80005e16:	f406                	sd	ra,40(sp)
    80005e18:	f022                	sd	s0,32(sp)
    80005e1a:	ec26                	sd	s1,24(sp)
    80005e1c:	e84a                	sd	s2,16(sp)
    80005e1e:	1800                	addi	s0,sp,48
    80005e20:	892a                	mv	s2,a0
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e22:	02000493          	li	s1,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005e26:	4741                	li	a4,16
    80005e28:	86a6                	mv	a3,s1
    80005e2a:	fd040613          	addi	a2,s0,-48
    80005e2e:	4581                	li	a1,0
    80005e30:	854a                	mv	a0,s2
    80005e32:	ffffe097          	auipc	ra,0xffffe
    80005e36:	0dc080e7          	jalr	220(ra) # 80003f0e <readi>
    80005e3a:	47c1                	li	a5,16
    80005e3c:	00f51c63          	bne	a0,a5,80005e54 <isdirempty+0x4a>
      panic("isdirempty: readi");
    if(de.inum != 0)
    80005e40:	fd045783          	lhu	a5,-48(s0)
    80005e44:	e395                	bnez	a5,80005e68 <isdirempty+0x5e>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e46:	24c1                	addiw	s1,s1,16
    80005e48:	04c92783          	lw	a5,76(s2)
    80005e4c:	fcf4ede3          	bltu	s1,a5,80005e26 <isdirempty+0x1c>
      return 0;
  }
  return 1;
    80005e50:	4505                	li	a0,1
    80005e52:	a821                	j	80005e6a <isdirempty+0x60>
      panic("isdirempty: readi");
    80005e54:	00003517          	auipc	a0,0x3
    80005e58:	9b450513          	addi	a0,a0,-1612 # 80008808 <syscalls+0x310>
    80005e5c:	ffffa097          	auipc	ra,0xffffa
    80005e60:	6e2080e7          	jalr	1762(ra) # 8000053e <panic>
  return 1;
    80005e64:	4505                	li	a0,1
}
    80005e66:	8082                	ret
      return 0;
    80005e68:	4501                	li	a0,0
}
    80005e6a:	70a2                	ld	ra,40(sp)
    80005e6c:	7402                	ld	s0,32(sp)
    80005e6e:	64e2                	ld	s1,24(sp)
    80005e70:	6942                	ld	s2,16(sp)
    80005e72:	6145                	addi	sp,sp,48
    80005e74:	8082                	ret

0000000080005e76 <sys_unlink>:

uint64
sys_unlink(void)
{
    80005e76:	7155                	addi	sp,sp,-208
    80005e78:	e586                	sd	ra,200(sp)
    80005e7a:	e1a2                	sd	s0,192(sp)
    80005e7c:	fd26                	sd	s1,184(sp)
    80005e7e:	f94a                	sd	s2,176(sp)
    80005e80:	0980                	addi	s0,sp,208
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], path[MAXPATH];
  uint off;

  if(argstr(0, path, MAXPATH) < 0)
    80005e82:	08000613          	li	a2,128
    80005e86:	f4040593          	addi	a1,s0,-192
    80005e8a:	4501                	li	a0,0
    80005e8c:	ffffd097          	auipc	ra,0xffffd
    80005e90:	2a2080e7          	jalr	674(ra) # 8000312e <argstr>
    80005e94:	16054363          	bltz	a0,80005ffa <sys_unlink+0x184>
    return -1;

  begin_op();
    80005e98:	fffff097          	auipc	ra,0xfffff
    80005e9c:	a96080e7          	jalr	-1386(ra) # 8000492e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005ea0:	fc040593          	addi	a1,s0,-64
    80005ea4:	f4040513          	addi	a0,s0,-192
    80005ea8:	ffffe097          	auipc	ra,0xffffe
    80005eac:	576080e7          	jalr	1398(ra) # 8000441e <nameiparent>
    80005eb0:	84aa                	mv	s1,a0
    80005eb2:	c961                	beqz	a0,80005f82 <sys_unlink+0x10c>
    end_op();
    return -1;
  }

  ilock(dp);
    80005eb4:	ffffe097          	auipc	ra,0xffffe
    80005eb8:	da6080e7          	jalr	-602(ra) # 80003c5a <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005ebc:	00003597          	auipc	a1,0x3
    80005ec0:	82c58593          	addi	a1,a1,-2004 # 800086e8 <syscalls+0x1f0>
    80005ec4:	fc040513          	addi	a0,s0,-64
    80005ec8:	ffffe097          	auipc	ra,0xffffe
    80005ecc:	25c080e7          	jalr	604(ra) # 80004124 <namecmp>
    80005ed0:	c175                	beqz	a0,80005fb4 <sys_unlink+0x13e>
    80005ed2:	00003597          	auipc	a1,0x3
    80005ed6:	81e58593          	addi	a1,a1,-2018 # 800086f0 <syscalls+0x1f8>
    80005eda:	fc040513          	addi	a0,s0,-64
    80005ede:	ffffe097          	auipc	ra,0xffffe
    80005ee2:	246080e7          	jalr	582(ra) # 80004124 <namecmp>
    80005ee6:	c579                	beqz	a0,80005fb4 <sys_unlink+0x13e>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    80005ee8:	f3c40613          	addi	a2,s0,-196
    80005eec:	fc040593          	addi	a1,s0,-64
    80005ef0:	8526                	mv	a0,s1
    80005ef2:	ffffe097          	auipc	ra,0xffffe
    80005ef6:	24c080e7          	jalr	588(ra) # 8000413e <dirlookup>
    80005efa:	892a                	mv	s2,a0
    80005efc:	cd45                	beqz	a0,80005fb4 <sys_unlink+0x13e>
    goto bad;
  ilock(ip);
    80005efe:	ffffe097          	auipc	ra,0xffffe
    80005f02:	d5c080e7          	jalr	-676(ra) # 80003c5a <ilock>

  if(ip->nlink < 1)
    80005f06:	04a91783          	lh	a5,74(s2)
    80005f0a:	08f05263          	blez	a5,80005f8e <sys_unlink+0x118>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005f0e:	04491703          	lh	a4,68(s2)
    80005f12:	4785                	li	a5,1
    80005f14:	08f70563          	beq	a4,a5,80005f9e <sys_unlink+0x128>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    80005f18:	4641                	li	a2,16
    80005f1a:	4581                	li	a1,0
    80005f1c:	fd040513          	addi	a0,s0,-48
    80005f20:	ffffb097          	auipc	ra,0xffffb
    80005f24:	db2080e7          	jalr	-590(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005f28:	4741                	li	a4,16
    80005f2a:	f3c42683          	lw	a3,-196(s0)
    80005f2e:	fd040613          	addi	a2,s0,-48
    80005f32:	4581                	li	a1,0
    80005f34:	8526                	mv	a0,s1
    80005f36:	ffffe097          	auipc	ra,0xffffe
    80005f3a:	0d0080e7          	jalr	208(ra) # 80004006 <writei>
    80005f3e:	47c1                	li	a5,16
    80005f40:	08f51a63          	bne	a0,a5,80005fd4 <sys_unlink+0x15e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    80005f44:	04491703          	lh	a4,68(s2)
    80005f48:	4785                	li	a5,1
    80005f4a:	08f70d63          	beq	a4,a5,80005fe4 <sys_unlink+0x16e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    80005f4e:	8526                	mv	a0,s1
    80005f50:	ffffe097          	auipc	ra,0xffffe
    80005f54:	f6c080e7          	jalr	-148(ra) # 80003ebc <iunlockput>

  ip->nlink--;
    80005f58:	04a95783          	lhu	a5,74(s2)
    80005f5c:	37fd                	addiw	a5,a5,-1
    80005f5e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005f62:	854a                	mv	a0,s2
    80005f64:	ffffe097          	auipc	ra,0xffffe
    80005f68:	c2c080e7          	jalr	-980(ra) # 80003b90 <iupdate>
  iunlockput(ip);
    80005f6c:	854a                	mv	a0,s2
    80005f6e:	ffffe097          	auipc	ra,0xffffe
    80005f72:	f4e080e7          	jalr	-178(ra) # 80003ebc <iunlockput>

  end_op();
    80005f76:	fffff097          	auipc	ra,0xfffff
    80005f7a:	a38080e7          	jalr	-1480(ra) # 800049ae <end_op>

  return 0;
    80005f7e:	4501                	li	a0,0
    80005f80:	a0a1                	j	80005fc8 <sys_unlink+0x152>
    end_op();
    80005f82:	fffff097          	auipc	ra,0xfffff
    80005f86:	a2c080e7          	jalr	-1492(ra) # 800049ae <end_op>
    return -1;
    80005f8a:	557d                	li	a0,-1
    80005f8c:	a835                	j	80005fc8 <sys_unlink+0x152>
    panic("unlink: nlink < 1");
    80005f8e:	00002517          	auipc	a0,0x2
    80005f92:	76a50513          	addi	a0,a0,1898 # 800086f8 <syscalls+0x200>
    80005f96:	ffffa097          	auipc	ra,0xffffa
    80005f9a:	5a8080e7          	jalr	1448(ra) # 8000053e <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005f9e:	854a                	mv	a0,s2
    80005fa0:	00000097          	auipc	ra,0x0
    80005fa4:	e6a080e7          	jalr	-406(ra) # 80005e0a <isdirempty>
    80005fa8:	f925                	bnez	a0,80005f18 <sys_unlink+0xa2>
    iunlockput(ip);
    80005faa:	854a                	mv	a0,s2
    80005fac:	ffffe097          	auipc	ra,0xffffe
    80005fb0:	f10080e7          	jalr	-240(ra) # 80003ebc <iunlockput>

bad:
  iunlockput(dp);
    80005fb4:	8526                	mv	a0,s1
    80005fb6:	ffffe097          	auipc	ra,0xffffe
    80005fba:	f06080e7          	jalr	-250(ra) # 80003ebc <iunlockput>
  end_op();
    80005fbe:	fffff097          	auipc	ra,0xfffff
    80005fc2:	9f0080e7          	jalr	-1552(ra) # 800049ae <end_op>
  return -1;
    80005fc6:	557d                	li	a0,-1
}
    80005fc8:	60ae                	ld	ra,200(sp)
    80005fca:	640e                	ld	s0,192(sp)
    80005fcc:	74ea                	ld	s1,184(sp)
    80005fce:	794a                	ld	s2,176(sp)
    80005fd0:	6169                	addi	sp,sp,208
    80005fd2:	8082                	ret
    panic("unlink: writei");
    80005fd4:	00002517          	auipc	a0,0x2
    80005fd8:	73c50513          	addi	a0,a0,1852 # 80008710 <syscalls+0x218>
    80005fdc:	ffffa097          	auipc	ra,0xffffa
    80005fe0:	562080e7          	jalr	1378(ra) # 8000053e <panic>
    dp->nlink--;
    80005fe4:	04a4d783          	lhu	a5,74(s1)
    80005fe8:	37fd                	addiw	a5,a5,-1
    80005fea:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005fee:	8526                	mv	a0,s1
    80005ff0:	ffffe097          	auipc	ra,0xffffe
    80005ff4:	ba0080e7          	jalr	-1120(ra) # 80003b90 <iupdate>
    80005ff8:	bf99                	j	80005f4e <sys_unlink+0xd8>
    return -1;
    80005ffa:	557d                	li	a0,-1
    80005ffc:	b7f1                	j	80005fc8 <sys_unlink+0x152>

0000000080005ffe <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
    80005ffe:	715d                	addi	sp,sp,-80
    80006000:	e486                	sd	ra,72(sp)
    80006002:	e0a2                	sd	s0,64(sp)
    80006004:	fc26                	sd	s1,56(sp)
    80006006:	f84a                	sd	s2,48(sp)
    80006008:	f44e                	sd	s3,40(sp)
    8000600a:	f052                	sd	s4,32(sp)
    8000600c:	ec56                	sd	s5,24(sp)
    8000600e:	e85a                	sd	s6,16(sp)
    80006010:	0880                	addi	s0,sp,80
    80006012:	8b2e                	mv	s6,a1
    80006014:	89b2                	mv	s3,a2
    80006016:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80006018:	fb040593          	addi	a1,s0,-80
    8000601c:	ffffe097          	auipc	ra,0xffffe
    80006020:	402080e7          	jalr	1026(ra) # 8000441e <nameiparent>
    80006024:	84aa                	mv	s1,a0
    80006026:	14050f63          	beqz	a0,80006184 <create+0x186>
    return 0;

  ilock(dp);
    8000602a:	ffffe097          	auipc	ra,0xffffe
    8000602e:	c30080e7          	jalr	-976(ra) # 80003c5a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80006032:	4601                	li	a2,0
    80006034:	fb040593          	addi	a1,s0,-80
    80006038:	8526                	mv	a0,s1
    8000603a:	ffffe097          	auipc	ra,0xffffe
    8000603e:	104080e7          	jalr	260(ra) # 8000413e <dirlookup>
    80006042:	8aaa                	mv	s5,a0
    80006044:	c931                	beqz	a0,80006098 <create+0x9a>
    iunlockput(dp);
    80006046:	8526                	mv	a0,s1
    80006048:	ffffe097          	auipc	ra,0xffffe
    8000604c:	e74080e7          	jalr	-396(ra) # 80003ebc <iunlockput>
    ilock(ip);
    80006050:	8556                	mv	a0,s5
    80006052:	ffffe097          	auipc	ra,0xffffe
    80006056:	c08080e7          	jalr	-1016(ra) # 80003c5a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000605a:	000b059b          	sext.w	a1,s6
    8000605e:	4789                	li	a5,2
    80006060:	02f59563          	bne	a1,a5,8000608a <create+0x8c>
    80006064:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffc8a04>
    80006068:	37f9                	addiw	a5,a5,-2
    8000606a:	17c2                	slli	a5,a5,0x30
    8000606c:	93c1                	srli	a5,a5,0x30
    8000606e:	4705                	li	a4,1
    80006070:	00f76d63          	bltu	a4,a5,8000608a <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80006074:	8556                	mv	a0,s5
    80006076:	60a6                	ld	ra,72(sp)
    80006078:	6406                	ld	s0,64(sp)
    8000607a:	74e2                	ld	s1,56(sp)
    8000607c:	7942                	ld	s2,48(sp)
    8000607e:	79a2                	ld	s3,40(sp)
    80006080:	7a02                	ld	s4,32(sp)
    80006082:	6ae2                	ld	s5,24(sp)
    80006084:	6b42                	ld	s6,16(sp)
    80006086:	6161                	addi	sp,sp,80
    80006088:	8082                	ret
    iunlockput(ip);
    8000608a:	8556                	mv	a0,s5
    8000608c:	ffffe097          	auipc	ra,0xffffe
    80006090:	e30080e7          	jalr	-464(ra) # 80003ebc <iunlockput>
    return 0;
    80006094:	4a81                	li	s5,0
    80006096:	bff9                	j	80006074 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80006098:	85da                	mv	a1,s6
    8000609a:	4088                	lw	a0,0(s1)
    8000609c:	ffffe097          	auipc	ra,0xffffe
    800060a0:	a22080e7          	jalr	-1502(ra) # 80003abe <ialloc>
    800060a4:	8a2a                	mv	s4,a0
    800060a6:	c539                	beqz	a0,800060f4 <create+0xf6>
  ilock(ip);
    800060a8:	ffffe097          	auipc	ra,0xffffe
    800060ac:	bb2080e7          	jalr	-1102(ra) # 80003c5a <ilock>
  ip->major = major;
    800060b0:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800060b4:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800060b8:	4905                	li	s2,1
    800060ba:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800060be:	8552                	mv	a0,s4
    800060c0:	ffffe097          	auipc	ra,0xffffe
    800060c4:	ad0080e7          	jalr	-1328(ra) # 80003b90 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800060c8:	000b059b          	sext.w	a1,s6
    800060cc:	03258b63          	beq	a1,s2,80006102 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800060d0:	004a2603          	lw	a2,4(s4)
    800060d4:	fb040593          	addi	a1,s0,-80
    800060d8:	8526                	mv	a0,s1
    800060da:	ffffe097          	auipc	ra,0xffffe
    800060de:	274080e7          	jalr	628(ra) # 8000434e <dirlink>
    800060e2:	06054f63          	bltz	a0,80006160 <create+0x162>
  iunlockput(dp);
    800060e6:	8526                	mv	a0,s1
    800060e8:	ffffe097          	auipc	ra,0xffffe
    800060ec:	dd4080e7          	jalr	-556(ra) # 80003ebc <iunlockput>
  return ip;
    800060f0:	8ad2                	mv	s5,s4
    800060f2:	b749                	j	80006074 <create+0x76>
    iunlockput(dp);
    800060f4:	8526                	mv	a0,s1
    800060f6:	ffffe097          	auipc	ra,0xffffe
    800060fa:	dc6080e7          	jalr	-570(ra) # 80003ebc <iunlockput>
    return 0;
    800060fe:	8ad2                	mv	s5,s4
    80006100:	bf95                	j	80006074 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80006102:	004a2603          	lw	a2,4(s4)
    80006106:	00002597          	auipc	a1,0x2
    8000610a:	5e258593          	addi	a1,a1,1506 # 800086e8 <syscalls+0x1f0>
    8000610e:	8552                	mv	a0,s4
    80006110:	ffffe097          	auipc	ra,0xffffe
    80006114:	23e080e7          	jalr	574(ra) # 8000434e <dirlink>
    80006118:	04054463          	bltz	a0,80006160 <create+0x162>
    8000611c:	40d0                	lw	a2,4(s1)
    8000611e:	00002597          	auipc	a1,0x2
    80006122:	5d258593          	addi	a1,a1,1490 # 800086f0 <syscalls+0x1f8>
    80006126:	8552                	mv	a0,s4
    80006128:	ffffe097          	auipc	ra,0xffffe
    8000612c:	226080e7          	jalr	550(ra) # 8000434e <dirlink>
    80006130:	02054863          	bltz	a0,80006160 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80006134:	004a2603          	lw	a2,4(s4)
    80006138:	fb040593          	addi	a1,s0,-80
    8000613c:	8526                	mv	a0,s1
    8000613e:	ffffe097          	auipc	ra,0xffffe
    80006142:	210080e7          	jalr	528(ra) # 8000434e <dirlink>
    80006146:	00054d63          	bltz	a0,80006160 <create+0x162>
    dp->nlink++;  // for ".."
    8000614a:	04a4d783          	lhu	a5,74(s1)
    8000614e:	2785                	addiw	a5,a5,1
    80006150:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006154:	8526                	mv	a0,s1
    80006156:	ffffe097          	auipc	ra,0xffffe
    8000615a:	a3a080e7          	jalr	-1478(ra) # 80003b90 <iupdate>
    8000615e:	b761                	j	800060e6 <create+0xe8>
  ip->nlink = 0;
    80006160:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80006164:	8552                	mv	a0,s4
    80006166:	ffffe097          	auipc	ra,0xffffe
    8000616a:	a2a080e7          	jalr	-1494(ra) # 80003b90 <iupdate>
  iunlockput(ip);
    8000616e:	8552                	mv	a0,s4
    80006170:	ffffe097          	auipc	ra,0xffffe
    80006174:	d4c080e7          	jalr	-692(ra) # 80003ebc <iunlockput>
  iunlockput(dp);
    80006178:	8526                	mv	a0,s1
    8000617a:	ffffe097          	auipc	ra,0xffffe
    8000617e:	d42080e7          	jalr	-702(ra) # 80003ebc <iunlockput>
  return 0;
    80006182:	bdcd                	j	80006074 <create+0x76>
    return 0;
    80006184:	8aaa                	mv	s5,a0
    80006186:	b5fd                	j	80006074 <create+0x76>

0000000080006188 <sys_open>:

uint64
sys_open(void)
{
    80006188:	7131                	addi	sp,sp,-192
    8000618a:	fd06                	sd	ra,184(sp)
    8000618c:	f922                	sd	s0,176(sp)
    8000618e:	f526                	sd	s1,168(sp)
    80006190:	f14a                	sd	s2,160(sp)
    80006192:	ed4e                	sd	s3,152(sp)
    80006194:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80006196:	f4c40593          	addi	a1,s0,-180
    8000619a:	4505                	li	a0,1
    8000619c:	ffffd097          	auipc	ra,0xffffd
    800061a0:	f52080e7          	jalr	-174(ra) # 800030ee <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800061a4:	08000613          	li	a2,128
    800061a8:	f5040593          	addi	a1,s0,-176
    800061ac:	4501                	li	a0,0
    800061ae:	ffffd097          	auipc	ra,0xffffd
    800061b2:	f80080e7          	jalr	-128(ra) # 8000312e <argstr>
    800061b6:	87aa                	mv	a5,a0
    return -1;
    800061b8:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800061ba:	0a07c963          	bltz	a5,8000626c <sys_open+0xe4>

  begin_op();
    800061be:	ffffe097          	auipc	ra,0xffffe
    800061c2:	770080e7          	jalr	1904(ra) # 8000492e <begin_op>

  if(omode & O_CREATE){
    800061c6:	f4c42783          	lw	a5,-180(s0)
    800061ca:	2007f793          	andi	a5,a5,512
    800061ce:	cfc5                	beqz	a5,80006286 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800061d0:	4681                	li	a3,0
    800061d2:	4601                	li	a2,0
    800061d4:	4589                	li	a1,2
    800061d6:	f5040513          	addi	a0,s0,-176
    800061da:	00000097          	auipc	ra,0x0
    800061de:	e24080e7          	jalr	-476(ra) # 80005ffe <create>
    800061e2:	84aa                	mv	s1,a0
    if(ip == 0){
    800061e4:	c959                	beqz	a0,8000627a <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800061e6:	04449703          	lh	a4,68(s1)
    800061ea:	478d                	li	a5,3
    800061ec:	00f71763          	bne	a4,a5,800061fa <sys_open+0x72>
    800061f0:	0464d703          	lhu	a4,70(s1)
    800061f4:	47a5                	li	a5,9
    800061f6:	0ce7ed63          	bltu	a5,a4,800062d0 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800061fa:	fffff097          	auipc	ra,0xfffff
    800061fe:	b44080e7          	jalr	-1212(ra) # 80004d3e <filealloc>
    80006202:	89aa                	mv	s3,a0
    80006204:	10050363          	beqz	a0,8000630a <sys_open+0x182>
    80006208:	00000097          	auipc	ra,0x0
    8000620c:	8e4080e7          	jalr	-1820(ra) # 80005aec <fdalloc>
    80006210:	892a                	mv	s2,a0
    80006212:	0e054763          	bltz	a0,80006300 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006216:	04449703          	lh	a4,68(s1)
    8000621a:	478d                	li	a5,3
    8000621c:	0cf70563          	beq	a4,a5,800062e6 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006220:	4789                	li	a5,2
    80006222:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006226:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000622a:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000622e:	f4c42783          	lw	a5,-180(s0)
    80006232:	0017c713          	xori	a4,a5,1
    80006236:	8b05                	andi	a4,a4,1
    80006238:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000623c:	0037f713          	andi	a4,a5,3
    80006240:	00e03733          	snez	a4,a4
    80006244:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006248:	4007f793          	andi	a5,a5,1024
    8000624c:	c791                	beqz	a5,80006258 <sys_open+0xd0>
    8000624e:	04449703          	lh	a4,68(s1)
    80006252:	4789                	li	a5,2
    80006254:	0af70063          	beq	a4,a5,800062f4 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006258:	8526                	mv	a0,s1
    8000625a:	ffffe097          	auipc	ra,0xffffe
    8000625e:	ac2080e7          	jalr	-1342(ra) # 80003d1c <iunlock>
  end_op();
    80006262:	ffffe097          	auipc	ra,0xffffe
    80006266:	74c080e7          	jalr	1868(ra) # 800049ae <end_op>

  return fd;
    8000626a:	854a                	mv	a0,s2
}
    8000626c:	70ea                	ld	ra,184(sp)
    8000626e:	744a                	ld	s0,176(sp)
    80006270:	74aa                	ld	s1,168(sp)
    80006272:	790a                	ld	s2,160(sp)
    80006274:	69ea                	ld	s3,152(sp)
    80006276:	6129                	addi	sp,sp,192
    80006278:	8082                	ret
      end_op();
    8000627a:	ffffe097          	auipc	ra,0xffffe
    8000627e:	734080e7          	jalr	1844(ra) # 800049ae <end_op>
      return -1;
    80006282:	557d                	li	a0,-1
    80006284:	b7e5                	j	8000626c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006286:	f5040513          	addi	a0,s0,-176
    8000628a:	ffffe097          	auipc	ra,0xffffe
    8000628e:	176080e7          	jalr	374(ra) # 80004400 <namei>
    80006292:	84aa                	mv	s1,a0
    80006294:	c905                	beqz	a0,800062c4 <sys_open+0x13c>
    ilock(ip);
    80006296:	ffffe097          	auipc	ra,0xffffe
    8000629a:	9c4080e7          	jalr	-1596(ra) # 80003c5a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000629e:	04449703          	lh	a4,68(s1)
    800062a2:	4785                	li	a5,1
    800062a4:	f4f711e3          	bne	a4,a5,800061e6 <sys_open+0x5e>
    800062a8:	f4c42783          	lw	a5,-180(s0)
    800062ac:	d7b9                	beqz	a5,800061fa <sys_open+0x72>
      iunlockput(ip);
    800062ae:	8526                	mv	a0,s1
    800062b0:	ffffe097          	auipc	ra,0xffffe
    800062b4:	c0c080e7          	jalr	-1012(ra) # 80003ebc <iunlockput>
      end_op();
    800062b8:	ffffe097          	auipc	ra,0xffffe
    800062bc:	6f6080e7          	jalr	1782(ra) # 800049ae <end_op>
      return -1;
    800062c0:	557d                	li	a0,-1
    800062c2:	b76d                	j	8000626c <sys_open+0xe4>
      end_op();
    800062c4:	ffffe097          	auipc	ra,0xffffe
    800062c8:	6ea080e7          	jalr	1770(ra) # 800049ae <end_op>
      return -1;
    800062cc:	557d                	li	a0,-1
    800062ce:	bf79                	j	8000626c <sys_open+0xe4>
    iunlockput(ip);
    800062d0:	8526                	mv	a0,s1
    800062d2:	ffffe097          	auipc	ra,0xffffe
    800062d6:	bea080e7          	jalr	-1046(ra) # 80003ebc <iunlockput>
    end_op();
    800062da:	ffffe097          	auipc	ra,0xffffe
    800062de:	6d4080e7          	jalr	1748(ra) # 800049ae <end_op>
    return -1;
    800062e2:	557d                	li	a0,-1
    800062e4:	b761                	j	8000626c <sys_open+0xe4>
    f->type = FD_DEVICE;
    800062e6:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800062ea:	04649783          	lh	a5,70(s1)
    800062ee:	02f99223          	sh	a5,36(s3)
    800062f2:	bf25                	j	8000622a <sys_open+0xa2>
    itrunc(ip);
    800062f4:	8526                	mv	a0,s1
    800062f6:	ffffe097          	auipc	ra,0xffffe
    800062fa:	a72080e7          	jalr	-1422(ra) # 80003d68 <itrunc>
    800062fe:	bfa9                	j	80006258 <sys_open+0xd0>
      fileclose(f);
    80006300:	854e                	mv	a0,s3
    80006302:	fffff097          	auipc	ra,0xfffff
    80006306:	af8080e7          	jalr	-1288(ra) # 80004dfa <fileclose>
    iunlockput(ip);
    8000630a:	8526                	mv	a0,s1
    8000630c:	ffffe097          	auipc	ra,0xffffe
    80006310:	bb0080e7          	jalr	-1104(ra) # 80003ebc <iunlockput>
    end_op();
    80006314:	ffffe097          	auipc	ra,0xffffe
    80006318:	69a080e7          	jalr	1690(ra) # 800049ae <end_op>
    return -1;
    8000631c:	557d                	li	a0,-1
    8000631e:	b7b9                	j	8000626c <sys_open+0xe4>

0000000080006320 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006320:	7175                	addi	sp,sp,-144
    80006322:	e506                	sd	ra,136(sp)
    80006324:	e122                	sd	s0,128(sp)
    80006326:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006328:	ffffe097          	auipc	ra,0xffffe
    8000632c:	606080e7          	jalr	1542(ra) # 8000492e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006330:	08000613          	li	a2,128
    80006334:	f7040593          	addi	a1,s0,-144
    80006338:	4501                	li	a0,0
    8000633a:	ffffd097          	auipc	ra,0xffffd
    8000633e:	df4080e7          	jalr	-524(ra) # 8000312e <argstr>
    80006342:	02054963          	bltz	a0,80006374 <sys_mkdir+0x54>
    80006346:	4681                	li	a3,0
    80006348:	4601                	li	a2,0
    8000634a:	4585                	li	a1,1
    8000634c:	f7040513          	addi	a0,s0,-144
    80006350:	00000097          	auipc	ra,0x0
    80006354:	cae080e7          	jalr	-850(ra) # 80005ffe <create>
    80006358:	cd11                	beqz	a0,80006374 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000635a:	ffffe097          	auipc	ra,0xffffe
    8000635e:	b62080e7          	jalr	-1182(ra) # 80003ebc <iunlockput>
  end_op();
    80006362:	ffffe097          	auipc	ra,0xffffe
    80006366:	64c080e7          	jalr	1612(ra) # 800049ae <end_op>
  return 0;
    8000636a:	4501                	li	a0,0
}
    8000636c:	60aa                	ld	ra,136(sp)
    8000636e:	640a                	ld	s0,128(sp)
    80006370:	6149                	addi	sp,sp,144
    80006372:	8082                	ret
    end_op();
    80006374:	ffffe097          	auipc	ra,0xffffe
    80006378:	63a080e7          	jalr	1594(ra) # 800049ae <end_op>
    return -1;
    8000637c:	557d                	li	a0,-1
    8000637e:	b7fd                	j	8000636c <sys_mkdir+0x4c>

0000000080006380 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006380:	7135                	addi	sp,sp,-160
    80006382:	ed06                	sd	ra,152(sp)
    80006384:	e922                	sd	s0,144(sp)
    80006386:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006388:	ffffe097          	auipc	ra,0xffffe
    8000638c:	5a6080e7          	jalr	1446(ra) # 8000492e <begin_op>
  argint(1, &major);
    80006390:	f6c40593          	addi	a1,s0,-148
    80006394:	4505                	li	a0,1
    80006396:	ffffd097          	auipc	ra,0xffffd
    8000639a:	d58080e7          	jalr	-680(ra) # 800030ee <argint>
  argint(2, &minor);
    8000639e:	f6840593          	addi	a1,s0,-152
    800063a2:	4509                	li	a0,2
    800063a4:	ffffd097          	auipc	ra,0xffffd
    800063a8:	d4a080e7          	jalr	-694(ra) # 800030ee <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800063ac:	08000613          	li	a2,128
    800063b0:	f7040593          	addi	a1,s0,-144
    800063b4:	4501                	li	a0,0
    800063b6:	ffffd097          	auipc	ra,0xffffd
    800063ba:	d78080e7          	jalr	-648(ra) # 8000312e <argstr>
    800063be:	02054b63          	bltz	a0,800063f4 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800063c2:	f6841683          	lh	a3,-152(s0)
    800063c6:	f6c41603          	lh	a2,-148(s0)
    800063ca:	458d                	li	a1,3
    800063cc:	f7040513          	addi	a0,s0,-144
    800063d0:	00000097          	auipc	ra,0x0
    800063d4:	c2e080e7          	jalr	-978(ra) # 80005ffe <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800063d8:	cd11                	beqz	a0,800063f4 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800063da:	ffffe097          	auipc	ra,0xffffe
    800063de:	ae2080e7          	jalr	-1310(ra) # 80003ebc <iunlockput>
  end_op();
    800063e2:	ffffe097          	auipc	ra,0xffffe
    800063e6:	5cc080e7          	jalr	1484(ra) # 800049ae <end_op>
  return 0;
    800063ea:	4501                	li	a0,0
}
    800063ec:	60ea                	ld	ra,152(sp)
    800063ee:	644a                	ld	s0,144(sp)
    800063f0:	610d                	addi	sp,sp,160
    800063f2:	8082                	ret
    end_op();
    800063f4:	ffffe097          	auipc	ra,0xffffe
    800063f8:	5ba080e7          	jalr	1466(ra) # 800049ae <end_op>
    return -1;
    800063fc:	557d                	li	a0,-1
    800063fe:	b7fd                	j	800063ec <sys_mknod+0x6c>

0000000080006400 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006400:	7135                	addi	sp,sp,-160
    80006402:	ed06                	sd	ra,152(sp)
    80006404:	e922                	sd	s0,144(sp)
    80006406:	e526                	sd	s1,136(sp)
    80006408:	e14a                	sd	s2,128(sp)
    8000640a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000640c:	ffffb097          	auipc	ra,0xffffb
    80006410:	6f2080e7          	jalr	1778(ra) # 80001afe <myproc>
    80006414:	892a                	mv	s2,a0
  
  begin_op();
    80006416:	ffffe097          	auipc	ra,0xffffe
    8000641a:	518080e7          	jalr	1304(ra) # 8000492e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000641e:	08000613          	li	a2,128
    80006422:	f6040593          	addi	a1,s0,-160
    80006426:	4501                	li	a0,0
    80006428:	ffffd097          	auipc	ra,0xffffd
    8000642c:	d06080e7          	jalr	-762(ra) # 8000312e <argstr>
    80006430:	04054b63          	bltz	a0,80006486 <sys_chdir+0x86>
    80006434:	f6040513          	addi	a0,s0,-160
    80006438:	ffffe097          	auipc	ra,0xffffe
    8000643c:	fc8080e7          	jalr	-56(ra) # 80004400 <namei>
    80006440:	84aa                	mv	s1,a0
    80006442:	c131                	beqz	a0,80006486 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006444:	ffffe097          	auipc	ra,0xffffe
    80006448:	816080e7          	jalr	-2026(ra) # 80003c5a <ilock>
  if(ip->type != T_DIR){
    8000644c:	04449703          	lh	a4,68(s1)
    80006450:	4785                	li	a5,1
    80006452:	04f71063          	bne	a4,a5,80006492 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006456:	8526                	mv	a0,s1
    80006458:	ffffe097          	auipc	ra,0xffffe
    8000645c:	8c4080e7          	jalr	-1852(ra) # 80003d1c <iunlock>
  iput(p->cwd);
    80006460:	15093503          	ld	a0,336(s2)
    80006464:	ffffe097          	auipc	ra,0xffffe
    80006468:	9b0080e7          	jalr	-1616(ra) # 80003e14 <iput>
  end_op();
    8000646c:	ffffe097          	auipc	ra,0xffffe
    80006470:	542080e7          	jalr	1346(ra) # 800049ae <end_op>
  p->cwd = ip;
    80006474:	14993823          	sd	s1,336(s2)
  return 0;
    80006478:	4501                	li	a0,0
}
    8000647a:	60ea                	ld	ra,152(sp)
    8000647c:	644a                	ld	s0,144(sp)
    8000647e:	64aa                	ld	s1,136(sp)
    80006480:	690a                	ld	s2,128(sp)
    80006482:	610d                	addi	sp,sp,160
    80006484:	8082                	ret
    end_op();
    80006486:	ffffe097          	auipc	ra,0xffffe
    8000648a:	528080e7          	jalr	1320(ra) # 800049ae <end_op>
    return -1;
    8000648e:	557d                	li	a0,-1
    80006490:	b7ed                	j	8000647a <sys_chdir+0x7a>
    iunlockput(ip);
    80006492:	8526                	mv	a0,s1
    80006494:	ffffe097          	auipc	ra,0xffffe
    80006498:	a28080e7          	jalr	-1496(ra) # 80003ebc <iunlockput>
    end_op();
    8000649c:	ffffe097          	auipc	ra,0xffffe
    800064a0:	512080e7          	jalr	1298(ra) # 800049ae <end_op>
    return -1;
    800064a4:	557d                	li	a0,-1
    800064a6:	bfd1                	j	8000647a <sys_chdir+0x7a>

00000000800064a8 <sys_exec>:

uint64
sys_exec(void)
{
    800064a8:	7145                	addi	sp,sp,-464
    800064aa:	e786                	sd	ra,456(sp)
    800064ac:	e3a2                	sd	s0,448(sp)
    800064ae:	ff26                	sd	s1,440(sp)
    800064b0:	fb4a                	sd	s2,432(sp)
    800064b2:	f74e                	sd	s3,424(sp)
    800064b4:	f352                	sd	s4,416(sp)
    800064b6:	ef56                	sd	s5,408(sp)
    800064b8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800064ba:	e3840593          	addi	a1,s0,-456
    800064be:	4505                	li	a0,1
    800064c0:	ffffd097          	auipc	ra,0xffffd
    800064c4:	c4e080e7          	jalr	-946(ra) # 8000310e <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800064c8:	08000613          	li	a2,128
    800064cc:	f4040593          	addi	a1,s0,-192
    800064d0:	4501                	li	a0,0
    800064d2:	ffffd097          	auipc	ra,0xffffd
    800064d6:	c5c080e7          	jalr	-932(ra) # 8000312e <argstr>
    800064da:	87aa                	mv	a5,a0
    return -1;
    800064dc:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800064de:	0c07c263          	bltz	a5,800065a2 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800064e2:	10000613          	li	a2,256
    800064e6:	4581                	li	a1,0
    800064e8:	e4040513          	addi	a0,s0,-448
    800064ec:	ffffa097          	auipc	ra,0xffffa
    800064f0:	7e6080e7          	jalr	2022(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800064f4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800064f8:	89a6                	mv	s3,s1
    800064fa:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800064fc:	02000a13          	li	s4,32
    80006500:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006504:	00391793          	slli	a5,s2,0x3
    80006508:	e3040593          	addi	a1,s0,-464
    8000650c:	e3843503          	ld	a0,-456(s0)
    80006510:	953e                	add	a0,a0,a5
    80006512:	ffffd097          	auipc	ra,0xffffd
    80006516:	b3e080e7          	jalr	-1218(ra) # 80003050 <fetchaddr>
    8000651a:	02054a63          	bltz	a0,8000654e <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    8000651e:	e3043783          	ld	a5,-464(s0)
    80006522:	c3b9                	beqz	a5,80006568 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006524:	ffffa097          	auipc	ra,0xffffa
    80006528:	5c2080e7          	jalr	1474(ra) # 80000ae6 <kalloc>
    8000652c:	85aa                	mv	a1,a0
    8000652e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006532:	cd11                	beqz	a0,8000654e <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006534:	6605                	lui	a2,0x1
    80006536:	e3043503          	ld	a0,-464(s0)
    8000653a:	ffffd097          	auipc	ra,0xffffd
    8000653e:	b68080e7          	jalr	-1176(ra) # 800030a2 <fetchstr>
    80006542:	00054663          	bltz	a0,8000654e <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80006546:	0905                	addi	s2,s2,1
    80006548:	09a1                	addi	s3,s3,8
    8000654a:	fb491be3          	bne	s2,s4,80006500 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000654e:	10048913          	addi	s2,s1,256
    80006552:	6088                	ld	a0,0(s1)
    80006554:	c531                	beqz	a0,800065a0 <sys_exec+0xf8>
    kfree(argv[i]);
    80006556:	ffffa097          	auipc	ra,0xffffa
    8000655a:	494080e7          	jalr	1172(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000655e:	04a1                	addi	s1,s1,8
    80006560:	ff2499e3          	bne	s1,s2,80006552 <sys_exec+0xaa>
  return -1;
    80006564:	557d                	li	a0,-1
    80006566:	a835                	j	800065a2 <sys_exec+0xfa>
      argv[i] = 0;
    80006568:	0a8e                	slli	s5,s5,0x3
    8000656a:	fc040793          	addi	a5,s0,-64
    8000656e:	9abe                	add	s5,s5,a5
    80006570:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006574:	e4040593          	addi	a1,s0,-448
    80006578:	f4040513          	addi	a0,s0,-192
    8000657c:	fffff097          	auipc	ra,0xfffff
    80006580:	0ee080e7          	jalr	238(ra) # 8000566a <exec>
    80006584:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006586:	10048993          	addi	s3,s1,256
    8000658a:	6088                	ld	a0,0(s1)
    8000658c:	c901                	beqz	a0,8000659c <sys_exec+0xf4>
    kfree(argv[i]);
    8000658e:	ffffa097          	auipc	ra,0xffffa
    80006592:	45c080e7          	jalr	1116(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006596:	04a1                	addi	s1,s1,8
    80006598:	ff3499e3          	bne	s1,s3,8000658a <sys_exec+0xe2>
  return ret;
    8000659c:	854a                	mv	a0,s2
    8000659e:	a011                	j	800065a2 <sys_exec+0xfa>
  return -1;
    800065a0:	557d                	li	a0,-1
}
    800065a2:	60be                	ld	ra,456(sp)
    800065a4:	641e                	ld	s0,448(sp)
    800065a6:	74fa                	ld	s1,440(sp)
    800065a8:	795a                	ld	s2,432(sp)
    800065aa:	79ba                	ld	s3,424(sp)
    800065ac:	7a1a                	ld	s4,416(sp)
    800065ae:	6afa                	ld	s5,408(sp)
    800065b0:	6179                	addi	sp,sp,464
    800065b2:	8082                	ret

00000000800065b4 <sys_pipe>:

uint64
sys_pipe(void)
{
    800065b4:	7139                	addi	sp,sp,-64
    800065b6:	fc06                	sd	ra,56(sp)
    800065b8:	f822                	sd	s0,48(sp)
    800065ba:	f426                	sd	s1,40(sp)
    800065bc:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800065be:	ffffb097          	auipc	ra,0xffffb
    800065c2:	540080e7          	jalr	1344(ra) # 80001afe <myproc>
    800065c6:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800065c8:	fd840593          	addi	a1,s0,-40
    800065cc:	4501                	li	a0,0
    800065ce:	ffffd097          	auipc	ra,0xffffd
    800065d2:	b40080e7          	jalr	-1216(ra) # 8000310e <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800065d6:	fc840593          	addi	a1,s0,-56
    800065da:	fd040513          	addi	a0,s0,-48
    800065de:	fffff097          	auipc	ra,0xfffff
    800065e2:	d42080e7          	jalr	-702(ra) # 80005320 <pipealloc>
    return -1;
    800065e6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800065e8:	0c054463          	bltz	a0,800066b0 <sys_pipe+0xfc>
  fd0 = -1;
    800065ec:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800065f0:	fd043503          	ld	a0,-48(s0)
    800065f4:	fffff097          	auipc	ra,0xfffff
    800065f8:	4f8080e7          	jalr	1272(ra) # 80005aec <fdalloc>
    800065fc:	fca42223          	sw	a0,-60(s0)
    80006600:	08054b63          	bltz	a0,80006696 <sys_pipe+0xe2>
    80006604:	fc843503          	ld	a0,-56(s0)
    80006608:	fffff097          	auipc	ra,0xfffff
    8000660c:	4e4080e7          	jalr	1252(ra) # 80005aec <fdalloc>
    80006610:	fca42023          	sw	a0,-64(s0)
    80006614:	06054863          	bltz	a0,80006684 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006618:	4691                	li	a3,4
    8000661a:	fc440613          	addi	a2,s0,-60
    8000661e:	fd843583          	ld	a1,-40(s0)
    80006622:	68a8                	ld	a0,80(s1)
    80006624:	ffffb097          	auipc	ra,0xffffb
    80006628:	196080e7          	jalr	406(ra) # 800017ba <copyout>
    8000662c:	02054063          	bltz	a0,8000664c <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006630:	4691                	li	a3,4
    80006632:	fc040613          	addi	a2,s0,-64
    80006636:	fd843583          	ld	a1,-40(s0)
    8000663a:	0591                	addi	a1,a1,4
    8000663c:	68a8                	ld	a0,80(s1)
    8000663e:	ffffb097          	auipc	ra,0xffffb
    80006642:	17c080e7          	jalr	380(ra) # 800017ba <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006646:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006648:	06055463          	bgez	a0,800066b0 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    8000664c:	fc442783          	lw	a5,-60(s0)
    80006650:	07e9                	addi	a5,a5,26
    80006652:	078e                	slli	a5,a5,0x3
    80006654:	97a6                	add	a5,a5,s1
    80006656:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000665a:	fc042503          	lw	a0,-64(s0)
    8000665e:	0569                	addi	a0,a0,26
    80006660:	050e                	slli	a0,a0,0x3
    80006662:	94aa                	add	s1,s1,a0
    80006664:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006668:	fd043503          	ld	a0,-48(s0)
    8000666c:	ffffe097          	auipc	ra,0xffffe
    80006670:	78e080e7          	jalr	1934(ra) # 80004dfa <fileclose>
    fileclose(wf);
    80006674:	fc843503          	ld	a0,-56(s0)
    80006678:	ffffe097          	auipc	ra,0xffffe
    8000667c:	782080e7          	jalr	1922(ra) # 80004dfa <fileclose>
    return -1;
    80006680:	57fd                	li	a5,-1
    80006682:	a03d                	j	800066b0 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006684:	fc442783          	lw	a5,-60(s0)
    80006688:	0007c763          	bltz	a5,80006696 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    8000668c:	07e9                	addi	a5,a5,26
    8000668e:	078e                	slli	a5,a5,0x3
    80006690:	94be                	add	s1,s1,a5
    80006692:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006696:	fd043503          	ld	a0,-48(s0)
    8000669a:	ffffe097          	auipc	ra,0xffffe
    8000669e:	760080e7          	jalr	1888(ra) # 80004dfa <fileclose>
    fileclose(wf);
    800066a2:	fc843503          	ld	a0,-56(s0)
    800066a6:	ffffe097          	auipc	ra,0xffffe
    800066aa:	754080e7          	jalr	1876(ra) # 80004dfa <fileclose>
    return -1;
    800066ae:	57fd                	li	a5,-1
}
    800066b0:	853e                	mv	a0,a5
    800066b2:	70e2                	ld	ra,56(sp)
    800066b4:	7442                	ld	s0,48(sp)
    800066b6:	74a2                	ld	s1,40(sp)
    800066b8:	6121                	addi	sp,sp,64
    800066ba:	8082                	ret
    800066bc:	0000                	unimp
	...

00000000800066c0 <kernelvec>:
    800066c0:	7111                	addi	sp,sp,-256
    800066c2:	e006                	sd	ra,0(sp)
    800066c4:	e40a                	sd	sp,8(sp)
    800066c6:	e80e                	sd	gp,16(sp)
    800066c8:	ec12                	sd	tp,24(sp)
    800066ca:	f016                	sd	t0,32(sp)
    800066cc:	f41a                	sd	t1,40(sp)
    800066ce:	f81e                	sd	t2,48(sp)
    800066d0:	fc22                	sd	s0,56(sp)
    800066d2:	e0a6                	sd	s1,64(sp)
    800066d4:	e4aa                	sd	a0,72(sp)
    800066d6:	e8ae                	sd	a1,80(sp)
    800066d8:	ecb2                	sd	a2,88(sp)
    800066da:	f0b6                	sd	a3,96(sp)
    800066dc:	f4ba                	sd	a4,104(sp)
    800066de:	f8be                	sd	a5,112(sp)
    800066e0:	fcc2                	sd	a6,120(sp)
    800066e2:	e146                	sd	a7,128(sp)
    800066e4:	e54a                	sd	s2,136(sp)
    800066e6:	e94e                	sd	s3,144(sp)
    800066e8:	ed52                	sd	s4,152(sp)
    800066ea:	f156                	sd	s5,160(sp)
    800066ec:	f55a                	sd	s6,168(sp)
    800066ee:	f95e                	sd	s7,176(sp)
    800066f0:	fd62                	sd	s8,184(sp)
    800066f2:	e1e6                	sd	s9,192(sp)
    800066f4:	e5ea                	sd	s10,200(sp)
    800066f6:	e9ee                	sd	s11,208(sp)
    800066f8:	edf2                	sd	t3,216(sp)
    800066fa:	f1f6                	sd	t4,224(sp)
    800066fc:	f5fa                	sd	t5,232(sp)
    800066fe:	f9fe                	sd	t6,240(sp)
    80006700:	81dfc0ef          	jal	ra,80002f1c <kerneltrap>
    80006704:	6082                	ld	ra,0(sp)
    80006706:	6122                	ld	sp,8(sp)
    80006708:	61c2                	ld	gp,16(sp)
    8000670a:	7282                	ld	t0,32(sp)
    8000670c:	7322                	ld	t1,40(sp)
    8000670e:	73c2                	ld	t2,48(sp)
    80006710:	7462                	ld	s0,56(sp)
    80006712:	6486                	ld	s1,64(sp)
    80006714:	6526                	ld	a0,72(sp)
    80006716:	65c6                	ld	a1,80(sp)
    80006718:	6666                	ld	a2,88(sp)
    8000671a:	7686                	ld	a3,96(sp)
    8000671c:	7726                	ld	a4,104(sp)
    8000671e:	77c6                	ld	a5,112(sp)
    80006720:	7866                	ld	a6,120(sp)
    80006722:	688a                	ld	a7,128(sp)
    80006724:	692a                	ld	s2,136(sp)
    80006726:	69ca                	ld	s3,144(sp)
    80006728:	6a6a                	ld	s4,152(sp)
    8000672a:	7a8a                	ld	s5,160(sp)
    8000672c:	7b2a                	ld	s6,168(sp)
    8000672e:	7bca                	ld	s7,176(sp)
    80006730:	7c6a                	ld	s8,184(sp)
    80006732:	6c8e                	ld	s9,192(sp)
    80006734:	6d2e                	ld	s10,200(sp)
    80006736:	6dce                	ld	s11,208(sp)
    80006738:	6e6e                	ld	t3,216(sp)
    8000673a:	7e8e                	ld	t4,224(sp)
    8000673c:	7f2e                	ld	t5,232(sp)
    8000673e:	7fce                	ld	t6,240(sp)
    80006740:	6111                	addi	sp,sp,256
    80006742:	10200073          	sret
    80006746:	00000013          	nop
    8000674a:	00000013          	nop
    8000674e:	0001                	nop

0000000080006750 <timervec>:
    80006750:	34051573          	csrrw	a0,mscratch,a0
    80006754:	e10c                	sd	a1,0(a0)
    80006756:	e510                	sd	a2,8(a0)
    80006758:	e914                	sd	a3,16(a0)
    8000675a:	6d0c                	ld	a1,24(a0)
    8000675c:	7110                	ld	a2,32(a0)
    8000675e:	6194                	ld	a3,0(a1)
    80006760:	96b2                	add	a3,a3,a2
    80006762:	e194                	sd	a3,0(a1)
    80006764:	4589                	li	a1,2
    80006766:	14459073          	csrw	sip,a1
    8000676a:	6914                	ld	a3,16(a0)
    8000676c:	6510                	ld	a2,8(a0)
    8000676e:	610c                	ld	a1,0(a0)
    80006770:	34051573          	csrrw	a0,mscratch,a0
    80006774:	30200073          	mret
	...

000000008000677a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000677a:	1141                	addi	sp,sp,-16
    8000677c:	e422                	sd	s0,8(sp)
    8000677e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006780:	0c0007b7          	lui	a5,0xc000
    80006784:	4705                	li	a4,1
    80006786:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006788:	c3d8                	sw	a4,4(a5)
}
    8000678a:	6422                	ld	s0,8(sp)
    8000678c:	0141                	addi	sp,sp,16
    8000678e:	8082                	ret

0000000080006790 <plicinithart>:

void
plicinithart(void)
{
    80006790:	1141                	addi	sp,sp,-16
    80006792:	e406                	sd	ra,8(sp)
    80006794:	e022                	sd	s0,0(sp)
    80006796:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006798:	ffffb097          	auipc	ra,0xffffb
    8000679c:	33a080e7          	jalr	826(ra) # 80001ad2 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800067a0:	0085171b          	slliw	a4,a0,0x8
    800067a4:	0c0027b7          	lui	a5,0xc002
    800067a8:	97ba                	add	a5,a5,a4
    800067aa:	40200713          	li	a4,1026
    800067ae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800067b2:	00d5151b          	slliw	a0,a0,0xd
    800067b6:	0c2017b7          	lui	a5,0xc201
    800067ba:	953e                	add	a0,a0,a5
    800067bc:	00052023          	sw	zero,0(a0)
}
    800067c0:	60a2                	ld	ra,8(sp)
    800067c2:	6402                	ld	s0,0(sp)
    800067c4:	0141                	addi	sp,sp,16
    800067c6:	8082                	ret

00000000800067c8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800067c8:	1141                	addi	sp,sp,-16
    800067ca:	e406                	sd	ra,8(sp)
    800067cc:	e022                	sd	s0,0(sp)
    800067ce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800067d0:	ffffb097          	auipc	ra,0xffffb
    800067d4:	302080e7          	jalr	770(ra) # 80001ad2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800067d8:	00d5179b          	slliw	a5,a0,0xd
    800067dc:	0c201537          	lui	a0,0xc201
    800067e0:	953e                	add	a0,a0,a5
  return irq;
}
    800067e2:	4148                	lw	a0,4(a0)
    800067e4:	60a2                	ld	ra,8(sp)
    800067e6:	6402                	ld	s0,0(sp)
    800067e8:	0141                	addi	sp,sp,16
    800067ea:	8082                	ret

00000000800067ec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800067ec:	1101                	addi	sp,sp,-32
    800067ee:	ec06                	sd	ra,24(sp)
    800067f0:	e822                	sd	s0,16(sp)
    800067f2:	e426                	sd	s1,8(sp)
    800067f4:	1000                	addi	s0,sp,32
    800067f6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800067f8:	ffffb097          	auipc	ra,0xffffb
    800067fc:	2da080e7          	jalr	730(ra) # 80001ad2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006800:	00d5151b          	slliw	a0,a0,0xd
    80006804:	0c2017b7          	lui	a5,0xc201
    80006808:	97aa                	add	a5,a5,a0
    8000680a:	c3c4                	sw	s1,4(a5)
}
    8000680c:	60e2                	ld	ra,24(sp)
    8000680e:	6442                	ld	s0,16(sp)
    80006810:	64a2                	ld	s1,8(sp)
    80006812:	6105                	addi	sp,sp,32
    80006814:	8082                	ret

0000000080006816 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006816:	1141                	addi	sp,sp,-16
    80006818:	e406                	sd	ra,8(sp)
    8000681a:	e022                	sd	s0,0(sp)
    8000681c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000681e:	479d                	li	a5,7
    80006820:	04a7cc63          	blt	a5,a0,80006878 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006824:	00030797          	auipc	a5,0x30
    80006828:	cdc78793          	addi	a5,a5,-804 # 80036500 <disk>
    8000682c:	97aa                	add	a5,a5,a0
    8000682e:	0187c783          	lbu	a5,24(a5)
    80006832:	ebb9                	bnez	a5,80006888 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006834:	00451613          	slli	a2,a0,0x4
    80006838:	00030797          	auipc	a5,0x30
    8000683c:	cc878793          	addi	a5,a5,-824 # 80036500 <disk>
    80006840:	6394                	ld	a3,0(a5)
    80006842:	96b2                	add	a3,a3,a2
    80006844:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006848:	6398                	ld	a4,0(a5)
    8000684a:	9732                	add	a4,a4,a2
    8000684c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006850:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006854:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006858:	953e                	add	a0,a0,a5
    8000685a:	4785                	li	a5,1
    8000685c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006860:	00030517          	auipc	a0,0x30
    80006864:	cb850513          	addi	a0,a0,-840 # 80036518 <disk+0x18>
    80006868:	ffffc097          	auipc	ra,0xffffc
    8000686c:	a4a080e7          	jalr	-1462(ra) # 800022b2 <wakeup>
}
    80006870:	60a2                	ld	ra,8(sp)
    80006872:	6402                	ld	s0,0(sp)
    80006874:	0141                	addi	sp,sp,16
    80006876:	8082                	ret
    panic("free_desc 1");
    80006878:	00002517          	auipc	a0,0x2
    8000687c:	fa850513          	addi	a0,a0,-88 # 80008820 <syscalls+0x328>
    80006880:	ffffa097          	auipc	ra,0xffffa
    80006884:	cbe080e7          	jalr	-834(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006888:	00002517          	auipc	a0,0x2
    8000688c:	fa850513          	addi	a0,a0,-88 # 80008830 <syscalls+0x338>
    80006890:	ffffa097          	auipc	ra,0xffffa
    80006894:	cae080e7          	jalr	-850(ra) # 8000053e <panic>

0000000080006898 <virtio_disk_init>:
{
    80006898:	1101                	addi	sp,sp,-32
    8000689a:	ec06                	sd	ra,24(sp)
    8000689c:	e822                	sd	s0,16(sp)
    8000689e:	e426                	sd	s1,8(sp)
    800068a0:	e04a                	sd	s2,0(sp)
    800068a2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800068a4:	00002597          	auipc	a1,0x2
    800068a8:	f9c58593          	addi	a1,a1,-100 # 80008840 <syscalls+0x348>
    800068ac:	00030517          	auipc	a0,0x30
    800068b0:	d7c50513          	addi	a0,a0,-644 # 80036628 <disk+0x128>
    800068b4:	ffffa097          	auipc	ra,0xffffa
    800068b8:	292080e7          	jalr	658(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800068bc:	100017b7          	lui	a5,0x10001
    800068c0:	4398                	lw	a4,0(a5)
    800068c2:	2701                	sext.w	a4,a4
    800068c4:	747277b7          	lui	a5,0x74727
    800068c8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800068cc:	14f71c63          	bne	a4,a5,80006a24 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800068d0:	100017b7          	lui	a5,0x10001
    800068d4:	43dc                	lw	a5,4(a5)
    800068d6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800068d8:	4709                	li	a4,2
    800068da:	14e79563          	bne	a5,a4,80006a24 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800068de:	100017b7          	lui	a5,0x10001
    800068e2:	479c                	lw	a5,8(a5)
    800068e4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800068e6:	12e79f63          	bne	a5,a4,80006a24 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800068ea:	100017b7          	lui	a5,0x10001
    800068ee:	47d8                	lw	a4,12(a5)
    800068f0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800068f2:	554d47b7          	lui	a5,0x554d4
    800068f6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800068fa:	12f71563          	bne	a4,a5,80006a24 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    800068fe:	100017b7          	lui	a5,0x10001
    80006902:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006906:	4705                	li	a4,1
    80006908:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000690a:	470d                	li	a4,3
    8000690c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000690e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006910:	c7ffe737          	lui	a4,0xc7ffe
    80006914:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fc811f>
    80006918:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000691a:	2701                	sext.w	a4,a4
    8000691c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000691e:	472d                	li	a4,11
    80006920:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006922:	5bbc                	lw	a5,112(a5)
    80006924:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006928:	8ba1                	andi	a5,a5,8
    8000692a:	10078563          	beqz	a5,80006a34 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000692e:	100017b7          	lui	a5,0x10001
    80006932:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006936:	43fc                	lw	a5,68(a5)
    80006938:	2781                	sext.w	a5,a5
    8000693a:	10079563          	bnez	a5,80006a44 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000693e:	100017b7          	lui	a5,0x10001
    80006942:	5bdc                	lw	a5,52(a5)
    80006944:	2781                	sext.w	a5,a5
  if(max == 0)
    80006946:	10078763          	beqz	a5,80006a54 <virtio_disk_init+0x1bc>
  if(max < NUM)
    8000694a:	471d                	li	a4,7
    8000694c:	10f77c63          	bgeu	a4,a5,80006a64 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80006950:	ffffa097          	auipc	ra,0xffffa
    80006954:	196080e7          	jalr	406(ra) # 80000ae6 <kalloc>
    80006958:	00030497          	auipc	s1,0x30
    8000695c:	ba848493          	addi	s1,s1,-1112 # 80036500 <disk>
    80006960:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006962:	ffffa097          	auipc	ra,0xffffa
    80006966:	184080e7          	jalr	388(ra) # 80000ae6 <kalloc>
    8000696a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000696c:	ffffa097          	auipc	ra,0xffffa
    80006970:	17a080e7          	jalr	378(ra) # 80000ae6 <kalloc>
    80006974:	87aa                	mv	a5,a0
    80006976:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006978:	6088                	ld	a0,0(s1)
    8000697a:	cd6d                	beqz	a0,80006a74 <virtio_disk_init+0x1dc>
    8000697c:	00030717          	auipc	a4,0x30
    80006980:	b8c73703          	ld	a4,-1140(a4) # 80036508 <disk+0x8>
    80006984:	cb65                	beqz	a4,80006a74 <virtio_disk_init+0x1dc>
    80006986:	c7fd                	beqz	a5,80006a74 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80006988:	6605                	lui	a2,0x1
    8000698a:	4581                	li	a1,0
    8000698c:	ffffa097          	auipc	ra,0xffffa
    80006990:	346080e7          	jalr	838(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006994:	00030497          	auipc	s1,0x30
    80006998:	b6c48493          	addi	s1,s1,-1172 # 80036500 <disk>
    8000699c:	6605                	lui	a2,0x1
    8000699e:	4581                	li	a1,0
    800069a0:	6488                	ld	a0,8(s1)
    800069a2:	ffffa097          	auipc	ra,0xffffa
    800069a6:	330080e7          	jalr	816(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    800069aa:	6605                	lui	a2,0x1
    800069ac:	4581                	li	a1,0
    800069ae:	6888                	ld	a0,16(s1)
    800069b0:	ffffa097          	auipc	ra,0xffffa
    800069b4:	322080e7          	jalr	802(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800069b8:	100017b7          	lui	a5,0x10001
    800069bc:	4721                	li	a4,8
    800069be:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800069c0:	4098                	lw	a4,0(s1)
    800069c2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800069c6:	40d8                	lw	a4,4(s1)
    800069c8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800069cc:	6498                	ld	a4,8(s1)
    800069ce:	0007069b          	sext.w	a3,a4
    800069d2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800069d6:	9701                	srai	a4,a4,0x20
    800069d8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800069dc:	6898                	ld	a4,16(s1)
    800069de:	0007069b          	sext.w	a3,a4
    800069e2:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800069e6:	9701                	srai	a4,a4,0x20
    800069e8:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800069ec:	4705                	li	a4,1
    800069ee:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800069f0:	00e48c23          	sb	a4,24(s1)
    800069f4:	00e48ca3          	sb	a4,25(s1)
    800069f8:	00e48d23          	sb	a4,26(s1)
    800069fc:	00e48da3          	sb	a4,27(s1)
    80006a00:	00e48e23          	sb	a4,28(s1)
    80006a04:	00e48ea3          	sb	a4,29(s1)
    80006a08:	00e48f23          	sb	a4,30(s1)
    80006a0c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006a10:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a14:	0727a823          	sw	s2,112(a5)
}
    80006a18:	60e2                	ld	ra,24(sp)
    80006a1a:	6442                	ld	s0,16(sp)
    80006a1c:	64a2                	ld	s1,8(sp)
    80006a1e:	6902                	ld	s2,0(sp)
    80006a20:	6105                	addi	sp,sp,32
    80006a22:	8082                	ret
    panic("could not find virtio disk");
    80006a24:	00002517          	auipc	a0,0x2
    80006a28:	e2c50513          	addi	a0,a0,-468 # 80008850 <syscalls+0x358>
    80006a2c:	ffffa097          	auipc	ra,0xffffa
    80006a30:	b12080e7          	jalr	-1262(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006a34:	00002517          	auipc	a0,0x2
    80006a38:	e3c50513          	addi	a0,a0,-452 # 80008870 <syscalls+0x378>
    80006a3c:	ffffa097          	auipc	ra,0xffffa
    80006a40:	b02080e7          	jalr	-1278(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006a44:	00002517          	auipc	a0,0x2
    80006a48:	e4c50513          	addi	a0,a0,-436 # 80008890 <syscalls+0x398>
    80006a4c:	ffffa097          	auipc	ra,0xffffa
    80006a50:	af2080e7          	jalr	-1294(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006a54:	00002517          	auipc	a0,0x2
    80006a58:	e5c50513          	addi	a0,a0,-420 # 800088b0 <syscalls+0x3b8>
    80006a5c:	ffffa097          	auipc	ra,0xffffa
    80006a60:	ae2080e7          	jalr	-1310(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006a64:	00002517          	auipc	a0,0x2
    80006a68:	e6c50513          	addi	a0,a0,-404 # 800088d0 <syscalls+0x3d8>
    80006a6c:	ffffa097          	auipc	ra,0xffffa
    80006a70:	ad2080e7          	jalr	-1326(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80006a74:	00002517          	auipc	a0,0x2
    80006a78:	e7c50513          	addi	a0,a0,-388 # 800088f0 <syscalls+0x3f8>
    80006a7c:	ffffa097          	auipc	ra,0xffffa
    80006a80:	ac2080e7          	jalr	-1342(ra) # 8000053e <panic>

0000000080006a84 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006a84:	7119                	addi	sp,sp,-128
    80006a86:	fc86                	sd	ra,120(sp)
    80006a88:	f8a2                	sd	s0,112(sp)
    80006a8a:	f4a6                	sd	s1,104(sp)
    80006a8c:	f0ca                	sd	s2,96(sp)
    80006a8e:	ecce                	sd	s3,88(sp)
    80006a90:	e8d2                	sd	s4,80(sp)
    80006a92:	e4d6                	sd	s5,72(sp)
    80006a94:	e0da                	sd	s6,64(sp)
    80006a96:	fc5e                	sd	s7,56(sp)
    80006a98:	f862                	sd	s8,48(sp)
    80006a9a:	f466                	sd	s9,40(sp)
    80006a9c:	f06a                	sd	s10,32(sp)
    80006a9e:	ec6e                	sd	s11,24(sp)
    80006aa0:	0100                	addi	s0,sp,128
    80006aa2:	8aaa                	mv	s5,a0
    80006aa4:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006aa6:	00c52d03          	lw	s10,12(a0)
    80006aaa:	001d1d1b          	slliw	s10,s10,0x1
    80006aae:	1d02                	slli	s10,s10,0x20
    80006ab0:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006ab4:	00030517          	auipc	a0,0x30
    80006ab8:	b7450513          	addi	a0,a0,-1164 # 80036628 <disk+0x128>
    80006abc:	ffffa097          	auipc	ra,0xffffa
    80006ac0:	11a080e7          	jalr	282(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006ac4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006ac6:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006ac8:	00030b97          	auipc	s7,0x30
    80006acc:	a38b8b93          	addi	s7,s7,-1480 # 80036500 <disk>
  for(int i = 0; i < 3; i++){
    80006ad0:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006ad2:	00030c97          	auipc	s9,0x30
    80006ad6:	b56c8c93          	addi	s9,s9,-1194 # 80036628 <disk+0x128>
    80006ada:	a08d                	j	80006b3c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006adc:	00fb8733          	add	a4,s7,a5
    80006ae0:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006ae4:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006ae6:	0207c563          	bltz	a5,80006b10 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006aea:	2905                	addiw	s2,s2,1
    80006aec:	0611                	addi	a2,a2,4
    80006aee:	05690c63          	beq	s2,s6,80006b46 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006af2:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006af4:	00030717          	auipc	a4,0x30
    80006af8:	a0c70713          	addi	a4,a4,-1524 # 80036500 <disk>
    80006afc:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006afe:	01874683          	lbu	a3,24(a4)
    80006b02:	fee9                	bnez	a3,80006adc <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006b04:	2785                	addiw	a5,a5,1
    80006b06:	0705                	addi	a4,a4,1
    80006b08:	fe979be3          	bne	a5,s1,80006afe <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006b0c:	57fd                	li	a5,-1
    80006b0e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006b10:	01205d63          	blez	s2,80006b2a <virtio_disk_rw+0xa6>
    80006b14:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006b16:	000a2503          	lw	a0,0(s4)
    80006b1a:	00000097          	auipc	ra,0x0
    80006b1e:	cfc080e7          	jalr	-772(ra) # 80006816 <free_desc>
      for(int j = 0; j < i; j++)
    80006b22:	2d85                	addiw	s11,s11,1
    80006b24:	0a11                	addi	s4,s4,4
    80006b26:	ffb918e3          	bne	s2,s11,80006b16 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006b2a:	85e6                	mv	a1,s9
    80006b2c:	00030517          	auipc	a0,0x30
    80006b30:	9ec50513          	addi	a0,a0,-1556 # 80036518 <disk+0x18>
    80006b34:	ffffb097          	auipc	ra,0xffffb
    80006b38:	71a080e7          	jalr	1818(ra) # 8000224e <sleep>
  for(int i = 0; i < 3; i++){
    80006b3c:	f8040a13          	addi	s4,s0,-128
{
    80006b40:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006b42:	894e                	mv	s2,s3
    80006b44:	b77d                	j	80006af2 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006b46:	f8042583          	lw	a1,-128(s0)
    80006b4a:	00a58793          	addi	a5,a1,10
    80006b4e:	0792                	slli	a5,a5,0x4

  if(write)
    80006b50:	00030617          	auipc	a2,0x30
    80006b54:	9b060613          	addi	a2,a2,-1616 # 80036500 <disk>
    80006b58:	00f60733          	add	a4,a2,a5
    80006b5c:	018036b3          	snez	a3,s8
    80006b60:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006b62:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006b66:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006b6a:	f6078693          	addi	a3,a5,-160
    80006b6e:	6218                	ld	a4,0(a2)
    80006b70:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006b72:	00878513          	addi	a0,a5,8
    80006b76:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006b78:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006b7a:	6208                	ld	a0,0(a2)
    80006b7c:	96aa                	add	a3,a3,a0
    80006b7e:	4741                	li	a4,16
    80006b80:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006b82:	4705                	li	a4,1
    80006b84:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006b88:	f8442703          	lw	a4,-124(s0)
    80006b8c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006b90:	0712                	slli	a4,a4,0x4
    80006b92:	953a                	add	a0,a0,a4
    80006b94:	058a8693          	addi	a3,s5,88
    80006b98:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    80006b9a:	6208                	ld	a0,0(a2)
    80006b9c:	972a                	add	a4,a4,a0
    80006b9e:	40000693          	li	a3,1024
    80006ba2:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006ba4:	001c3c13          	seqz	s8,s8
    80006ba8:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006baa:	001c6c13          	ori	s8,s8,1
    80006bae:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006bb2:	f8842603          	lw	a2,-120(s0)
    80006bb6:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006bba:	00030697          	auipc	a3,0x30
    80006bbe:	94668693          	addi	a3,a3,-1722 # 80036500 <disk>
    80006bc2:	00258713          	addi	a4,a1,2
    80006bc6:	0712                	slli	a4,a4,0x4
    80006bc8:	9736                	add	a4,a4,a3
    80006bca:	587d                	li	a6,-1
    80006bcc:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006bd0:	0612                	slli	a2,a2,0x4
    80006bd2:	9532                	add	a0,a0,a2
    80006bd4:	f9078793          	addi	a5,a5,-112
    80006bd8:	97b6                	add	a5,a5,a3
    80006bda:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    80006bdc:	629c                	ld	a5,0(a3)
    80006bde:	97b2                	add	a5,a5,a2
    80006be0:	4605                	li	a2,1
    80006be2:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006be4:	4509                	li	a0,2
    80006be6:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    80006bea:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006bee:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006bf2:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006bf6:	6698                	ld	a4,8(a3)
    80006bf8:	00275783          	lhu	a5,2(a4)
    80006bfc:	8b9d                	andi	a5,a5,7
    80006bfe:	0786                	slli	a5,a5,0x1
    80006c00:	97ba                	add	a5,a5,a4
    80006c02:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006c06:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006c0a:	6698                	ld	a4,8(a3)
    80006c0c:	00275783          	lhu	a5,2(a4)
    80006c10:	2785                	addiw	a5,a5,1
    80006c12:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006c16:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006c1a:	100017b7          	lui	a5,0x10001
    80006c1e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006c22:	004aa783          	lw	a5,4(s5)
    80006c26:	02c79163          	bne	a5,a2,80006c48 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006c2a:	00030917          	auipc	s2,0x30
    80006c2e:	9fe90913          	addi	s2,s2,-1538 # 80036628 <disk+0x128>
  while(b->disk == 1) {
    80006c32:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006c34:	85ca                	mv	a1,s2
    80006c36:	8556                	mv	a0,s5
    80006c38:	ffffb097          	auipc	ra,0xffffb
    80006c3c:	616080e7          	jalr	1558(ra) # 8000224e <sleep>
  while(b->disk == 1) {
    80006c40:	004aa783          	lw	a5,4(s5)
    80006c44:	fe9788e3          	beq	a5,s1,80006c34 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006c48:	f8042903          	lw	s2,-128(s0)
    80006c4c:	00290793          	addi	a5,s2,2
    80006c50:	00479713          	slli	a4,a5,0x4
    80006c54:	00030797          	auipc	a5,0x30
    80006c58:	8ac78793          	addi	a5,a5,-1876 # 80036500 <disk>
    80006c5c:	97ba                	add	a5,a5,a4
    80006c5e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006c62:	00030997          	auipc	s3,0x30
    80006c66:	89e98993          	addi	s3,s3,-1890 # 80036500 <disk>
    80006c6a:	00491713          	slli	a4,s2,0x4
    80006c6e:	0009b783          	ld	a5,0(s3)
    80006c72:	97ba                	add	a5,a5,a4
    80006c74:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006c78:	854a                	mv	a0,s2
    80006c7a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006c7e:	00000097          	auipc	ra,0x0
    80006c82:	b98080e7          	jalr	-1128(ra) # 80006816 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006c86:	8885                	andi	s1,s1,1
    80006c88:	f0ed                	bnez	s1,80006c6a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006c8a:	00030517          	auipc	a0,0x30
    80006c8e:	99e50513          	addi	a0,a0,-1634 # 80036628 <disk+0x128>
    80006c92:	ffffa097          	auipc	ra,0xffffa
    80006c96:	ff8080e7          	jalr	-8(ra) # 80000c8a <release>
}
    80006c9a:	70e6                	ld	ra,120(sp)
    80006c9c:	7446                	ld	s0,112(sp)
    80006c9e:	74a6                	ld	s1,104(sp)
    80006ca0:	7906                	ld	s2,96(sp)
    80006ca2:	69e6                	ld	s3,88(sp)
    80006ca4:	6a46                	ld	s4,80(sp)
    80006ca6:	6aa6                	ld	s5,72(sp)
    80006ca8:	6b06                	ld	s6,64(sp)
    80006caa:	7be2                	ld	s7,56(sp)
    80006cac:	7c42                	ld	s8,48(sp)
    80006cae:	7ca2                	ld	s9,40(sp)
    80006cb0:	7d02                	ld	s10,32(sp)
    80006cb2:	6de2                	ld	s11,24(sp)
    80006cb4:	6109                	addi	sp,sp,128
    80006cb6:	8082                	ret

0000000080006cb8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006cb8:	1101                	addi	sp,sp,-32
    80006cba:	ec06                	sd	ra,24(sp)
    80006cbc:	e822                	sd	s0,16(sp)
    80006cbe:	e426                	sd	s1,8(sp)
    80006cc0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006cc2:	00030497          	auipc	s1,0x30
    80006cc6:	83e48493          	addi	s1,s1,-1986 # 80036500 <disk>
    80006cca:	00030517          	auipc	a0,0x30
    80006cce:	95e50513          	addi	a0,a0,-1698 # 80036628 <disk+0x128>
    80006cd2:	ffffa097          	auipc	ra,0xffffa
    80006cd6:	f04080e7          	jalr	-252(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006cda:	10001737          	lui	a4,0x10001
    80006cde:	533c                	lw	a5,96(a4)
    80006ce0:	8b8d                	andi	a5,a5,3
    80006ce2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006ce4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006ce8:	689c                	ld	a5,16(s1)
    80006cea:	0204d703          	lhu	a4,32(s1)
    80006cee:	0027d783          	lhu	a5,2(a5)
    80006cf2:	04f70863          	beq	a4,a5,80006d42 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006cf6:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006cfa:	6898                	ld	a4,16(s1)
    80006cfc:	0204d783          	lhu	a5,32(s1)
    80006d00:	8b9d                	andi	a5,a5,7
    80006d02:	078e                	slli	a5,a5,0x3
    80006d04:	97ba                	add	a5,a5,a4
    80006d06:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006d08:	00278713          	addi	a4,a5,2
    80006d0c:	0712                	slli	a4,a4,0x4
    80006d0e:	9726                	add	a4,a4,s1
    80006d10:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006d14:	e721                	bnez	a4,80006d5c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006d16:	0789                	addi	a5,a5,2
    80006d18:	0792                	slli	a5,a5,0x4
    80006d1a:	97a6                	add	a5,a5,s1
    80006d1c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006d1e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006d22:	ffffb097          	auipc	ra,0xffffb
    80006d26:	590080e7          	jalr	1424(ra) # 800022b2 <wakeup>

    disk.used_idx += 1;
    80006d2a:	0204d783          	lhu	a5,32(s1)
    80006d2e:	2785                	addiw	a5,a5,1
    80006d30:	17c2                	slli	a5,a5,0x30
    80006d32:	93c1                	srli	a5,a5,0x30
    80006d34:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006d38:	6898                	ld	a4,16(s1)
    80006d3a:	00275703          	lhu	a4,2(a4)
    80006d3e:	faf71ce3          	bne	a4,a5,80006cf6 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006d42:	00030517          	auipc	a0,0x30
    80006d46:	8e650513          	addi	a0,a0,-1818 # 80036628 <disk+0x128>
    80006d4a:	ffffa097          	auipc	ra,0xffffa
    80006d4e:	f40080e7          	jalr	-192(ra) # 80000c8a <release>
}
    80006d52:	60e2                	ld	ra,24(sp)
    80006d54:	6442                	ld	s0,16(sp)
    80006d56:	64a2                	ld	s1,8(sp)
    80006d58:	6105                	addi	sp,sp,32
    80006d5a:	8082                	ret
      panic("virtio_disk_intr status");
    80006d5c:	00002517          	auipc	a0,0x2
    80006d60:	bac50513          	addi	a0,a0,-1108 # 80008908 <syscalls+0x410>
    80006d64:	ffff9097          	auipc	ra,0xffff9
    80006d68:	7da080e7          	jalr	2010(ra) # 8000053e <panic>
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
