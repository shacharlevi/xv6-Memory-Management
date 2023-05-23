
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8d013103          	ld	sp,-1840(sp) # 800088d0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	8de70713          	addi	a4,a4,-1826 # 80008930 <timer_scratch>
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
    80000068:	05c78793          	addi	a5,a5,92 # 800060c0 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc85f>
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
    80000130:	386080e7          	jalr	902(ra) # 800024b2 <either_copyin>
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
    8000018e:	8e650513          	addi	a0,a0,-1818 # 80010a70 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8d648493          	addi	s1,s1,-1834 # 80010a70 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	96690913          	addi	s2,s2,-1690 # 80010b08 <cons+0x98>
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
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	134080e7          	jalr	308(ra) # 800022fc <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	e7e080e7          	jalr	-386(ra) # 80002054 <sleep>
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
    80000216:	24a080e7          	jalr	586(ra) # 8000245c <either_copyout>
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
    8000022a:	84a50513          	addi	a0,a0,-1974 # 80010a70 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	83450513          	addi	a0,a0,-1996 # 80010a70 <cons>
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
    80000276:	88f72b23          	sw	a5,-1898(a4) # 80010b08 <cons+0x98>
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
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	7a450513          	addi	a0,a0,1956 # 80010a70 <cons>
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
    800002f6:	216080e7          	jalr	534(ra) # 80002508 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	77650513          	addi	a0,a0,1910 # 80010a70 <cons>
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
    80000322:	75270713          	addi	a4,a4,1874 # 80010a70 <cons>
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
    8000034c:	72878793          	addi	a5,a5,1832 # 80010a70 <cons>
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
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7927a783          	lw	a5,1938(a5) # 80010b08 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6e670713          	addi	a4,a4,1766 # 80010a70 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6d648493          	addi	s1,s1,1750 # 80010a70 <cons>
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
    800003da:	69a70713          	addi	a4,a4,1690 # 80010a70 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	72f72223          	sw	a5,1828(a4) # 80010b10 <cons+0xa0>
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
    80000416:	65e78793          	addi	a5,a5,1630 # 80010a70 <cons>
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
    8000043a:	6cc7ab23          	sw	a2,1750(a5) # 80010b0c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6ca50513          	addi	a0,a0,1738 # 80010b08 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	c72080e7          	jalr	-910(ra) # 800020b8 <wakeup>
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
    80000464:	61050513          	addi	a0,a0,1552 # 80010a70 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	99078793          	addi	a5,a5,-1648 # 80020e08 <devsw>
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
    8000054e:	5e07a323          	sw	zero,1510(a5) # 80010b30 <pr+0x18>
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
    8000057e:	00008717          	auipc	a4,0x8
    80000582:	36f72923          	sw	a5,882(a4) # 800088f0 <panicked>
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
    800005be:	576dad83          	lw	s11,1398(s11) # 80010b30 <pr+0x18>
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
    800005fc:	52050513          	addi	a0,a0,1312 # 80010b18 <pr>
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
    8000075a:	3c250513          	addi	a0,a0,962 # 80010b18 <pr>
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
    80000776:	3a648493          	addi	s1,s1,934 # 80010b18 <pr>
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
    800007d6:	36650513          	addi	a0,a0,870 # 80010b38 <uart_tx_lock>
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
    80000802:	0f27a783          	lw	a5,242(a5) # 800088f0 <panicked>
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
    8000083a:	0c27b783          	ld	a5,194(a5) # 800088f8 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	0c273703          	ld	a4,194(a4) # 80008900 <uart_tx_w>
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
    80000864:	2d8a0a13          	addi	s4,s4,728 # 80010b38 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	09048493          	addi	s1,s1,144 # 800088f8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	09098993          	addi	s3,s3,144 # 80008900 <uart_tx_w>
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
    80000896:	826080e7          	jalr	-2010(ra) # 800020b8 <wakeup>
    
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
    800008d2:	26a50513          	addi	a0,a0,618 # 80010b38 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	0127a783          	lw	a5,18(a5) # 800088f0 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	01873703          	ld	a4,24(a4) # 80008900 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	0087b783          	ld	a5,8(a5) # 800088f8 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	23c98993          	addi	s3,s3,572 # 80010b38 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	ff448493          	addi	s1,s1,-12 # 800088f8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	ff490913          	addi	s2,s2,-12 # 80008900 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00001097          	auipc	ra,0x1
    80000920:	738080e7          	jalr	1848(ra) # 80002054 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	20648493          	addi	s1,s1,518 # 80010b38 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	fae7bd23          	sd	a4,-70(a5) # 80008900 <uart_tx_w>
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
    800009c0:	17c48493          	addi	s1,s1,380 # 80010b38 <uart_tx_lock>
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
    800009fe:	00021797          	auipc	a5,0x21
    80000a02:	5a278793          	addi	a5,a5,1442 # 80021fa0 <end>
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
    80000a22:	15290913          	addi	s2,s2,338 # 80010b70 <kmem>
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
    80000abe:	0b650513          	addi	a0,a0,182 # 80010b70 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	4d250513          	addi	a0,a0,1234 # 80021fa0 <end>
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
    80000af4:	08048493          	addi	s1,s1,128 # 80010b70 <kmem>
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
    80000b0c:	06850513          	addi	a0,a0,104 # 80010b70 <kmem>
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
    80000b38:	03c50513          	addi	a0,a0,60 # 80010b70 <kmem>
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
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
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
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
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
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
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
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
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
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
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
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a8070713          	addi	a4,a4,-1408 # 80008908 <started>
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
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6da080e7          	jalr	1754(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00001097          	auipc	ra,0x1
    80000ec2:	78a080e7          	jalr	1930(ra) # 80002648 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	23a080e7          	jalr	570(ra) # 80006100 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	fd4080e7          	jalr	-44(ra) # 80001ea2 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88a080e7          	jalr	-1910(ra) # 80000768 <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69a080e7          	jalr	1690(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68a080e7          	jalr	1674(ra) # 80000588 <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67a080e7          	jalr	1658(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00001097          	auipc	ra,0x1
    80000f3a:	6ea080e7          	jalr	1770(ra) # 80002620 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	70a080e7          	jalr	1802(ra) # 80002648 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	1a4080e7          	jalr	420(ra) # 800060ea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	1b2080e7          	jalr	434(ra) # 80006100 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	e2e080e7          	jalr	-466(ra) # 80002d84 <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	4d2080e7          	jalr	1234(ra) # 80003430 <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	782080e7          	jalr	1922(ra) # 800046e8 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	29a080e7          	jalr	666(ra) # 80006208 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d0e080e7          	jalr	-754(ra) # 80001c84 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	98f72223          	sw	a5,-1660(a4) # 80008908 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9787b783          	ld	a5,-1672(a5) # 80008910 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55a080e7          	jalr	1370(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	00a7d513          	srli	a0,a5,0xa
    80001096:	0532                	slli	a0,a0,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	77fd                	lui	a5,0xfffff
    800010bc:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	15fd                	addi	a1,a1,-1
    800010c2:	00c589b3          	add	s3,a1,a2
    800010c6:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010ca:	8952                	mv	s2,s4
    800010cc:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	434080e7          	jalr	1076(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	424080e7          	jalr	1060(ra) # 8000053e <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3d8080e7          	jalr	984(ra) # 8000053e <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	6aa7be23          	sd	a0,1724(a5) # 80008910 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28c080e7          	jalr	652(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27c080e7          	jalr	636(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26c080e7          	jalr	620(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25c080e7          	jalr	604(ra) # 8000053e <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6cc080e7          	jalr	1740(ra) # 800009ea <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	17e080e7          	jalr	382(ra) # 8000053e <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	767d                	lui	a2,0xfffff
    800013e4:	8f71                	and	a4,a4,a2
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff1                	and	a5,a5,a2
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6985                	lui	s3,0x1
    8000142e:	19fd                	addi	s3,s3,-1
    80001430:	95ce                	add	a1,a1,s3
    80001432:	79fd                	lui	s3,0xfffff
    80001434:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	54a080e7          	jalr	1354(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a821                	j	800014f4 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014e0:	0532                	slli	a0,a0,0xc
    800014e2:	00000097          	auipc	ra,0x0
    800014e6:	fe0080e7          	jalr	-32(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ea:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014ee:	04a1                	addi	s1,s1,8
    800014f0:	03248163          	beq	s1,s2,80001512 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014f4:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f6:	00f57793          	andi	a5,a0,15
    800014fa:	ff3782e3          	beq	a5,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014fe:	8905                	andi	a0,a0,1
    80001500:	d57d                	beqz	a0,800014ee <freewalk+0x2c>
      panic("freewalk: leaf");
    80001502:	00007517          	auipc	a0,0x7
    80001506:	c7650513          	addi	a0,a0,-906 # 80008178 <digits+0x138>
    8000150a:	fffff097          	auipc	ra,0xfffff
    8000150e:	034080e7          	jalr	52(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001512:	8552                	mv	a0,s4
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	4d6080e7          	jalr	1238(ra) # 800009ea <kfree>
}
    8000151c:	70a2                	ld	ra,40(sp)
    8000151e:	7402                	ld	s0,32(sp)
    80001520:	64e2                	ld	s1,24(sp)
    80001522:	6942                	ld	s2,16(sp)
    80001524:	69a2                	ld	s3,8(sp)
    80001526:	6a02                	ld	s4,0(sp)
    80001528:	6145                	addi	sp,sp,48
    8000152a:	8082                	ret

000000008000152c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152c:	1101                	addi	sp,sp,-32
    8000152e:	ec06                	sd	ra,24(sp)
    80001530:	e822                	sd	s0,16(sp)
    80001532:	e426                	sd	s1,8(sp)
    80001534:	1000                	addi	s0,sp,32
    80001536:	84aa                	mv	s1,a0
  if(sz > 0)
    80001538:	e999                	bnez	a1,8000154e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153a:	8526                	mv	a0,s1
    8000153c:	00000097          	auipc	ra,0x0
    80001540:	f86080e7          	jalr	-122(ra) # 800014c2 <freewalk>
}
    80001544:	60e2                	ld	ra,24(sp)
    80001546:	6442                	ld	s0,16(sp)
    80001548:	64a2                	ld	s1,8(sp)
    8000154a:	6105                	addi	sp,sp,32
    8000154c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000154e:	6605                	lui	a2,0x1
    80001550:	167d                	addi	a2,a2,-1
    80001552:	962e                	add	a2,a2,a1
    80001554:	4685                	li	a3,1
    80001556:	8231                	srli	a2,a2,0xc
    80001558:	4581                	li	a1,0
    8000155a:	00000097          	auipc	ra,0x0
    8000155e:	d0a080e7          	jalr	-758(ra) # 80001264 <uvmunmap>
    80001562:	bfe1                	j	8000153a <uvmfree+0xe>

0000000080001564 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001564:	c679                	beqz	a2,80001632 <uvmcopy+0xce>
{
    80001566:	715d                	addi	sp,sp,-80
    80001568:	e486                	sd	ra,72(sp)
    8000156a:	e0a2                	sd	s0,64(sp)
    8000156c:	fc26                	sd	s1,56(sp)
    8000156e:	f84a                	sd	s2,48(sp)
    80001570:	f44e                	sd	s3,40(sp)
    80001572:	f052                	sd	s4,32(sp)
    80001574:	ec56                	sd	s5,24(sp)
    80001576:	e85a                	sd	s6,16(sp)
    80001578:	e45e                	sd	s7,8(sp)
    8000157a:	0880                	addi	s0,sp,80
    8000157c:	8b2a                	mv	s6,a0
    8000157e:	8aae                	mv	s5,a1
    80001580:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001582:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001584:	4601                	li	a2,0
    80001586:	85ce                	mv	a1,s3
    80001588:	855a                	mv	a0,s6
    8000158a:	00000097          	auipc	ra,0x0
    8000158e:	a2c080e7          	jalr	-1492(ra) # 80000fb6 <walk>
    80001592:	c531                	beqz	a0,800015de <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001594:	6118                	ld	a4,0(a0)
    80001596:	00177793          	andi	a5,a4,1
    8000159a:	cbb1                	beqz	a5,800015ee <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000159c:	00a75593          	srli	a1,a4,0xa
    800015a0:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a4:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015a8:	fffff097          	auipc	ra,0xfffff
    800015ac:	53e080e7          	jalr	1342(ra) # 80000ae6 <kalloc>
    800015b0:	892a                	mv	s2,a0
    800015b2:	c939                	beqz	a0,80001608 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b4:	6605                	lui	a2,0x1
    800015b6:	85de                	mv	a1,s7
    800015b8:	fffff097          	auipc	ra,0xfffff
    800015bc:	776080e7          	jalr	1910(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c0:	8726                	mv	a4,s1
    800015c2:	86ca                	mv	a3,s2
    800015c4:	6605                	lui	a2,0x1
    800015c6:	85ce                	mv	a1,s3
    800015c8:	8556                	mv	a0,s5
    800015ca:	00000097          	auipc	ra,0x0
    800015ce:	ad4080e7          	jalr	-1324(ra) # 8000109e <mappages>
    800015d2:	e515                	bnez	a0,800015fe <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d4:	6785                	lui	a5,0x1
    800015d6:	99be                	add	s3,s3,a5
    800015d8:	fb49e6e3          	bltu	s3,s4,80001584 <uvmcopy+0x20>
    800015dc:	a081                	j	8000161c <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015de:	00007517          	auipc	a0,0x7
    800015e2:	baa50513          	addi	a0,a0,-1110 # 80008188 <digits+0x148>
    800015e6:	fffff097          	auipc	ra,0xfffff
    800015ea:	f58080e7          	jalr	-168(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015ee:	00007517          	auipc	a0,0x7
    800015f2:	bba50513          	addi	a0,a0,-1094 # 800081a8 <digits+0x168>
    800015f6:	fffff097          	auipc	ra,0xfffff
    800015fa:	f48080e7          	jalr	-184(ra) # 8000053e <panic>
      kfree(mem);
    800015fe:	854a                	mv	a0,s2
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	3ea080e7          	jalr	1002(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001608:	4685                	li	a3,1
    8000160a:	00c9d613          	srli	a2,s3,0xc
    8000160e:	4581                	li	a1,0
    80001610:	8556                	mv	a0,s5
    80001612:	00000097          	auipc	ra,0x0
    80001616:	c52080e7          	jalr	-942(ra) # 80001264 <uvmunmap>
  return -1;
    8000161a:	557d                	li	a0,-1
}
    8000161c:	60a6                	ld	ra,72(sp)
    8000161e:	6406                	ld	s0,64(sp)
    80001620:	74e2                	ld	s1,56(sp)
    80001622:	7942                	ld	s2,48(sp)
    80001624:	79a2                	ld	s3,40(sp)
    80001626:	7a02                	ld	s4,32(sp)
    80001628:	6ae2                	ld	s5,24(sp)
    8000162a:	6b42                	ld	s6,16(sp)
    8000162c:	6ba2                	ld	s7,8(sp)
    8000162e:	6161                	addi	sp,sp,80
    80001630:	8082                	ret
  return 0;
    80001632:	4501                	li	a0,0
}
    80001634:	8082                	ret

0000000080001636 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001636:	1141                	addi	sp,sp,-16
    80001638:	e406                	sd	ra,8(sp)
    8000163a:	e022                	sd	s0,0(sp)
    8000163c:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000163e:	4601                	li	a2,0
    80001640:	00000097          	auipc	ra,0x0
    80001644:	976080e7          	jalr	-1674(ra) # 80000fb6 <walk>
  if(pte == 0)
    80001648:	c901                	beqz	a0,80001658 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164a:	611c                	ld	a5,0(a0)
    8000164c:	9bbd                	andi	a5,a5,-17
    8000164e:	e11c                	sd	a5,0(a0)
}
    80001650:	60a2                	ld	ra,8(sp)
    80001652:	6402                	ld	s0,0(sp)
    80001654:	0141                	addi	sp,sp,16
    80001656:	8082                	ret
    panic("uvmclear");
    80001658:	00007517          	auipc	a0,0x7
    8000165c:	b7050513          	addi	a0,a0,-1168 # 800081c8 <digits+0x188>
    80001660:	fffff097          	auipc	ra,0xfffff
    80001664:	ede080e7          	jalr	-290(ra) # 8000053e <panic>

0000000080001668 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001668:	c6bd                	beqz	a3,800016d6 <copyout+0x6e>
{
    8000166a:	715d                	addi	sp,sp,-80
    8000166c:	e486                	sd	ra,72(sp)
    8000166e:	e0a2                	sd	s0,64(sp)
    80001670:	fc26                	sd	s1,56(sp)
    80001672:	f84a                	sd	s2,48(sp)
    80001674:	f44e                	sd	s3,40(sp)
    80001676:	f052                	sd	s4,32(sp)
    80001678:	ec56                	sd	s5,24(sp)
    8000167a:	e85a                	sd	s6,16(sp)
    8000167c:	e45e                	sd	s7,8(sp)
    8000167e:	e062                	sd	s8,0(sp)
    80001680:	0880                	addi	s0,sp,80
    80001682:	8b2a                	mv	s6,a0
    80001684:	8c2e                	mv	s8,a1
    80001686:	8a32                	mv	s4,a2
    80001688:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000168c:	6a85                	lui	s5,0x1
    8000168e:	a015                	j	800016b2 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001690:	9562                	add	a0,a0,s8
    80001692:	0004861b          	sext.w	a2,s1
    80001696:	85d2                	mv	a1,s4
    80001698:	41250533          	sub	a0,a0,s2
    8000169c:	fffff097          	auipc	ra,0xfffff
    800016a0:	692080e7          	jalr	1682(ra) # 80000d2e <memmove>

    len -= n;
    800016a4:	409989b3          	sub	s3,s3,s1
    src += n;
    800016a8:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016aa:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ae:	02098263          	beqz	s3,800016d2 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016b6:	85ca                	mv	a1,s2
    800016b8:	855a                	mv	a0,s6
    800016ba:	00000097          	auipc	ra,0x0
    800016be:	9a2080e7          	jalr	-1630(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c2:	cd01                	beqz	a0,800016da <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c4:	418904b3          	sub	s1,s2,s8
    800016c8:	94d6                	add	s1,s1,s5
    if(n > len)
    800016ca:	fc99f3e3          	bgeu	s3,s1,80001690 <copyout+0x28>
    800016ce:	84ce                	mv	s1,s3
    800016d0:	b7c1                	j	80001690 <copyout+0x28>
  }
  return 0;
    800016d2:	4501                	li	a0,0
    800016d4:	a021                	j	800016dc <copyout+0x74>
    800016d6:	4501                	li	a0,0
}
    800016d8:	8082                	ret
      return -1;
    800016da:	557d                	li	a0,-1
}
    800016dc:	60a6                	ld	ra,72(sp)
    800016de:	6406                	ld	s0,64(sp)
    800016e0:	74e2                	ld	s1,56(sp)
    800016e2:	7942                	ld	s2,48(sp)
    800016e4:	79a2                	ld	s3,40(sp)
    800016e6:	7a02                	ld	s4,32(sp)
    800016e8:	6ae2                	ld	s5,24(sp)
    800016ea:	6b42                	ld	s6,16(sp)
    800016ec:	6ba2                	ld	s7,8(sp)
    800016ee:	6c02                	ld	s8,0(sp)
    800016f0:	6161                	addi	sp,sp,80
    800016f2:	8082                	ret

00000000800016f4 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f4:	caa5                	beqz	a3,80001764 <copyin+0x70>
{
    800016f6:	715d                	addi	sp,sp,-80
    800016f8:	e486                	sd	ra,72(sp)
    800016fa:	e0a2                	sd	s0,64(sp)
    800016fc:	fc26                	sd	s1,56(sp)
    800016fe:	f84a                	sd	s2,48(sp)
    80001700:	f44e                	sd	s3,40(sp)
    80001702:	f052                	sd	s4,32(sp)
    80001704:	ec56                	sd	s5,24(sp)
    80001706:	e85a                	sd	s6,16(sp)
    80001708:	e45e                	sd	s7,8(sp)
    8000170a:	e062                	sd	s8,0(sp)
    8000170c:	0880                	addi	s0,sp,80
    8000170e:	8b2a                	mv	s6,a0
    80001710:	8a2e                	mv	s4,a1
    80001712:	8c32                	mv	s8,a2
    80001714:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001716:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001718:	6a85                	lui	s5,0x1
    8000171a:	a01d                	j	80001740 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000171c:	018505b3          	add	a1,a0,s8
    80001720:	0004861b          	sext.w	a2,s1
    80001724:	412585b3          	sub	a1,a1,s2
    80001728:	8552                	mv	a0,s4
    8000172a:	fffff097          	auipc	ra,0xfffff
    8000172e:	604080e7          	jalr	1540(ra) # 80000d2e <memmove>

    len -= n;
    80001732:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001736:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001738:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000173c:	02098263          	beqz	s3,80001760 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001740:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001744:	85ca                	mv	a1,s2
    80001746:	855a                	mv	a0,s6
    80001748:	00000097          	auipc	ra,0x0
    8000174c:	914080e7          	jalr	-1772(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001750:	cd01                	beqz	a0,80001768 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001752:	418904b3          	sub	s1,s2,s8
    80001756:	94d6                	add	s1,s1,s5
    if(n > len)
    80001758:	fc99f2e3          	bgeu	s3,s1,8000171c <copyin+0x28>
    8000175c:	84ce                	mv	s1,s3
    8000175e:	bf7d                	j	8000171c <copyin+0x28>
  }
  return 0;
    80001760:	4501                	li	a0,0
    80001762:	a021                	j	8000176a <copyin+0x76>
    80001764:	4501                	li	a0,0
}
    80001766:	8082                	ret
      return -1;
    80001768:	557d                	li	a0,-1
}
    8000176a:	60a6                	ld	ra,72(sp)
    8000176c:	6406                	ld	s0,64(sp)
    8000176e:	74e2                	ld	s1,56(sp)
    80001770:	7942                	ld	s2,48(sp)
    80001772:	79a2                	ld	s3,40(sp)
    80001774:	7a02                	ld	s4,32(sp)
    80001776:	6ae2                	ld	s5,24(sp)
    80001778:	6b42                	ld	s6,16(sp)
    8000177a:	6ba2                	ld	s7,8(sp)
    8000177c:	6c02                	ld	s8,0(sp)
    8000177e:	6161                	addi	sp,sp,80
    80001780:	8082                	ret

0000000080001782 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001782:	c6c5                	beqz	a3,8000182a <copyinstr+0xa8>
{
    80001784:	715d                	addi	sp,sp,-80
    80001786:	e486                	sd	ra,72(sp)
    80001788:	e0a2                	sd	s0,64(sp)
    8000178a:	fc26                	sd	s1,56(sp)
    8000178c:	f84a                	sd	s2,48(sp)
    8000178e:	f44e                	sd	s3,40(sp)
    80001790:	f052                	sd	s4,32(sp)
    80001792:	ec56                	sd	s5,24(sp)
    80001794:	e85a                	sd	s6,16(sp)
    80001796:	e45e                	sd	s7,8(sp)
    80001798:	0880                	addi	s0,sp,80
    8000179a:	8a2a                	mv	s4,a0
    8000179c:	8b2e                	mv	s6,a1
    8000179e:	8bb2                	mv	s7,a2
    800017a0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a4:	6985                	lui	s3,0x1
    800017a6:	a035                	j	800017d2 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017a8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017ac:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017ae:	0017b793          	seqz	a5,a5
    800017b2:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b6:	60a6                	ld	ra,72(sp)
    800017b8:	6406                	ld	s0,64(sp)
    800017ba:	74e2                	ld	s1,56(sp)
    800017bc:	7942                	ld	s2,48(sp)
    800017be:	79a2                	ld	s3,40(sp)
    800017c0:	7a02                	ld	s4,32(sp)
    800017c2:	6ae2                	ld	s5,24(sp)
    800017c4:	6b42                	ld	s6,16(sp)
    800017c6:	6ba2                	ld	s7,8(sp)
    800017c8:	6161                	addi	sp,sp,80
    800017ca:	8082                	ret
    srcva = va0 + PGSIZE;
    800017cc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d0:	c8a9                	beqz	s1,80001822 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017d2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d6:	85ca                	mv	a1,s2
    800017d8:	8552                	mv	a0,s4
    800017da:	00000097          	auipc	ra,0x0
    800017de:	882080e7          	jalr	-1918(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e2:	c131                	beqz	a0,80001826 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017e4:	41790833          	sub	a6,s2,s7
    800017e8:	984e                	add	a6,a6,s3
    if(n > max)
    800017ea:	0104f363          	bgeu	s1,a6,800017f0 <copyinstr+0x6e>
    800017ee:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f0:	955e                	add	a0,a0,s7
    800017f2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f6:	fc080be3          	beqz	a6,800017cc <copyinstr+0x4a>
    800017fa:	985a                	add	a6,a6,s6
    800017fc:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fe:	41650633          	sub	a2,a0,s6
    80001802:	14fd                	addi	s1,s1,-1
    80001804:	9b26                	add	s6,s6,s1
    80001806:	00f60733          	add	a4,a2,a5
    8000180a:	00074703          	lbu	a4,0(a4)
    8000180e:	df49                	beqz	a4,800017a8 <copyinstr+0x26>
        *dst = *p;
    80001810:	00e78023          	sb	a4,0(a5)
      --max;
    80001814:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001818:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181a:	ff0796e3          	bne	a5,a6,80001806 <copyinstr+0x84>
      dst++;
    8000181e:	8b42                	mv	s6,a6
    80001820:	b775                	j	800017cc <copyinstr+0x4a>
    80001822:	4781                	li	a5,0
    80001824:	b769                	j	800017ae <copyinstr+0x2c>
      return -1;
    80001826:	557d                	li	a0,-1
    80001828:	b779                	j	800017b6 <copyinstr+0x34>
  int got_null = 0;
    8000182a:	4781                	li	a5,0
  if(got_null){
    8000182c:	0017b793          	seqz	a5,a5
    80001830:	40f00533          	neg	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000184c:	0000f497          	auipc	s1,0xf
    80001850:	77448493          	addi	s1,s1,1908 # 80010fc0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1
    80001864:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001866:	00015a17          	auipc	s4,0x15
    8000186a:	35aa0a13          	addi	s4,s4,858 # 80016bc0 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if(pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	8591                	srai	a1,a1,0x4
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a0:	17048493          	addi	s1,s1,368
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7a080e7          	jalr	-902(ra) # 8000053e <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	2a850513          	addi	a0,a0,680 # 80010b90 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	2a850513          	addi	a0,a0,680 # 80010ba8 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	6b048493          	addi	s1,s1,1712 # 80010fc0 <proc>
      initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1
    80001930:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001932:	00015997          	auipc	s3,0x15
    80001936:	28e98993          	addi	s3,s3,654 # 80016bc0 <tickslock>
      initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	8791                	srai	a5,a5,0x4
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001964:	17048493          	addi	s1,s1,368
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	22450513          	addi	a0,a0,548 # 80010bc0 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	1cc70713          	addi	a4,a4,460 # 80010b90 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first) {
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	e847a783          	lw	a5,-380(a5) # 80008880 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	c5a080e7          	jalr	-934(ra) # 80002660 <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e607a523          	sw	zero,-406(a5) # 80008880 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	990080e7          	jalr	-1648(ra) # 800033b0 <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	15a90913          	addi	s2,s2,346 # 80010b90 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	e3c78793          	addi	a5,a5,-452 # 80008884 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	05893683          	ld	a3,88(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a52080e7          	jalr	-1454(ra) # 8000152c <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2c080e7          	jalr	-1492(ra) # 8000152c <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e2080e7          	jalr	-1566(ra) # 8000152c <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b6a:	6d28                	ld	a0,88(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7c080e7          	jalr	-388(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001b76:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b7a:	68a8                	ld	a0,80(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	64ac                	ld	a1,72(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc2:	0000f497          	auipc	s1,0xf
    80001bc6:	3fe48493          	addi	s1,s1,1022 # 80010fc0 <proc>
    80001bca:	00015917          	auipc	s2,0x15
    80001bce:	ff690913          	addi	s2,s2,-10 # 80016bc0 <tickslock>
    acquire(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	cf81                	beqz	a5,80001bf6 <allocproc+0x40>
      release(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bea:	17048493          	addi	s1,s1,368
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a889                	j	80001c46 <allocproc+0x90>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	ee2080e7          	jalr	-286(ra) # 80000ae6 <kalloc>
    80001c0c:	892a                	mv	s2,a0
    80001c0e:	eca8                	sd	a0,88(s1)
    80001c10:	c131                	beqz	a0,80001c54 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c12:	8526                	mv	a0,s1
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	e5c080e7          	jalr	-420(ra) # 80001a70 <proc_pagetable>
    80001c1c:	892a                	mv	s2,a0
    80001c1e:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c20:	c531                	beqz	a0,80001c6c <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c22:	07000613          	li	a2,112
    80001c26:	4581                	li	a1,0
    80001c28:	06048513          	addi	a0,s1,96
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	0a6080e7          	jalr	166(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c34:	00000797          	auipc	a5,0x0
    80001c38:	db078793          	addi	a5,a5,-592 # 800019e4 <forkret>
    80001c3c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c3e:	60bc                	ld	a5,64(s1)
    80001c40:	6705                	lui	a4,0x1
    80001c42:	97ba                	add	a5,a5,a4
    80001c44:	f4bc                	sd	a5,104(s1)
}
    80001c46:	8526                	mv	a0,s1
    80001c48:	60e2                	ld	ra,24(sp)
    80001c4a:	6442                	ld	s0,16(sp)
    80001c4c:	64a2                	ld	s1,8(sp)
    80001c4e:	6902                	ld	s2,0(sp)
    80001c50:	6105                	addi	sp,sp,32
    80001c52:	8082                	ret
    freeproc(p);
    80001c54:	8526                	mv	a0,s1
    80001c56:	00000097          	auipc	ra,0x0
    80001c5a:	f08080e7          	jalr	-248(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c5e:	8526                	mv	a0,s1
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	02a080e7          	jalr	42(ra) # 80000c8a <release>
    return 0;
    80001c68:	84ca                	mv	s1,s2
    80001c6a:	bff1                	j	80001c46 <allocproc+0x90>
    freeproc(p);
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	00000097          	auipc	ra,0x0
    80001c72:	ef0080e7          	jalr	-272(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c76:	8526                	mv	a0,s1
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	012080e7          	jalr	18(ra) # 80000c8a <release>
    return 0;
    80001c80:	84ca                	mv	s1,s2
    80001c82:	b7d1                	j	80001c46 <allocproc+0x90>

0000000080001c84 <userinit>:
{
    80001c84:	1101                	addi	sp,sp,-32
    80001c86:	ec06                	sd	ra,24(sp)
    80001c88:	e822                	sd	s0,16(sp)
    80001c8a:	e426                	sd	s1,8(sp)
    80001c8c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c8e:	00000097          	auipc	ra,0x0
    80001c92:	f28080e7          	jalr	-216(ra) # 80001bb6 <allocproc>
    80001c96:	84aa                	mv	s1,a0
  initproc = p;
    80001c98:	00007797          	auipc	a5,0x7
    80001c9c:	c8a7b023          	sd	a0,-896(a5) # 80008918 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ca0:	03400613          	li	a2,52
    80001ca4:	00007597          	auipc	a1,0x7
    80001ca8:	bec58593          	addi	a1,a1,-1044 # 80008890 <initcode>
    80001cac:	6928                	ld	a0,80(a0)
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	6a8080e7          	jalr	1704(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cb6:	6785                	lui	a5,0x1
    80001cb8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cba:	6cb8                	ld	a4,88(s1)
    80001cbc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cc0:	6cb8                	ld	a4,88(s1)
    80001cc2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cc4:	4641                	li	a2,16
    80001cc6:	00006597          	auipc	a1,0x6
    80001cca:	53a58593          	addi	a1,a1,1338 # 80008200 <digits+0x1c0>
    80001cce:	15848513          	addi	a0,s1,344
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	14a080e7          	jalr	330(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001cda:	00006517          	auipc	a0,0x6
    80001cde:	53650513          	addi	a0,a0,1334 # 80008210 <digits+0x1d0>
    80001ce2:	00002097          	auipc	ra,0x2
    80001ce6:	0f0080e7          	jalr	240(ra) # 80003dd2 <namei>
    80001cea:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cee:	478d                	li	a5,3
    80001cf0:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	f96080e7          	jalr	-106(ra) # 80000c8a <release>
}
    80001cfc:	60e2                	ld	ra,24(sp)
    80001cfe:	6442                	ld	s0,16(sp)
    80001d00:	64a2                	ld	s1,8(sp)
    80001d02:	6105                	addi	sp,sp,32
    80001d04:	8082                	ret

0000000080001d06 <growproc>:
{
    80001d06:	1101                	addi	sp,sp,-32
    80001d08:	ec06                	sd	ra,24(sp)
    80001d0a:	e822                	sd	s0,16(sp)
    80001d0c:	e426                	sd	s1,8(sp)
    80001d0e:	e04a                	sd	s2,0(sp)
    80001d10:	1000                	addi	s0,sp,32
    80001d12:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	c98080e7          	jalr	-872(ra) # 800019ac <myproc>
    80001d1c:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d1e:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d20:	01204c63          	bgtz	s2,80001d38 <growproc+0x32>
  } else if(n < 0){
    80001d24:	02094663          	bltz	s2,80001d50 <growproc+0x4a>
  p->sz = sz;
    80001d28:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d2a:	4501                	li	a0,0
}
    80001d2c:	60e2                	ld	ra,24(sp)
    80001d2e:	6442                	ld	s0,16(sp)
    80001d30:	64a2                	ld	s1,8(sp)
    80001d32:	6902                	ld	s2,0(sp)
    80001d34:	6105                	addi	sp,sp,32
    80001d36:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d38:	4691                	li	a3,4
    80001d3a:	00b90633          	add	a2,s2,a1
    80001d3e:	6928                	ld	a0,80(a0)
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	6d0080e7          	jalr	1744(ra) # 80001410 <uvmalloc>
    80001d48:	85aa                	mv	a1,a0
    80001d4a:	fd79                	bnez	a0,80001d28 <growproc+0x22>
      return -1;
    80001d4c:	557d                	li	a0,-1
    80001d4e:	bff9                	j	80001d2c <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d50:	00b90633          	add	a2,s2,a1
    80001d54:	6928                	ld	a0,80(a0)
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	672080e7          	jalr	1650(ra) # 800013c8 <uvmdealloc>
    80001d5e:	85aa                	mv	a1,a0
    80001d60:	b7e1                	j	80001d28 <growproc+0x22>

0000000080001d62 <fork>:
{
    80001d62:	7139                	addi	sp,sp,-64
    80001d64:	fc06                	sd	ra,56(sp)
    80001d66:	f822                	sd	s0,48(sp)
    80001d68:	f426                	sd	s1,40(sp)
    80001d6a:	f04a                	sd	s2,32(sp)
    80001d6c:	ec4e                	sd	s3,24(sp)
    80001d6e:	e852                	sd	s4,16(sp)
    80001d70:	e456                	sd	s5,8(sp)
    80001d72:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d74:	00000097          	auipc	ra,0x0
    80001d78:	c38080e7          	jalr	-968(ra) # 800019ac <myproc>
    80001d7c:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d7e:	00000097          	auipc	ra,0x0
    80001d82:	e38080e7          	jalr	-456(ra) # 80001bb6 <allocproc>
    80001d86:	10050c63          	beqz	a0,80001e9e <fork+0x13c>
    80001d8a:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d8c:	048ab603          	ld	a2,72(s5)
    80001d90:	692c                	ld	a1,80(a0)
    80001d92:	050ab503          	ld	a0,80(s5)
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	7ce080e7          	jalr	1998(ra) # 80001564 <uvmcopy>
    80001d9e:	04054863          	bltz	a0,80001dee <fork+0x8c>
  np->sz = p->sz;
    80001da2:	048ab783          	ld	a5,72(s5)
    80001da6:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001daa:	058ab683          	ld	a3,88(s5)
    80001dae:	87b6                	mv	a5,a3
    80001db0:	058a3703          	ld	a4,88(s4)
    80001db4:	12068693          	addi	a3,a3,288
    80001db8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dbc:	6788                	ld	a0,8(a5)
    80001dbe:	6b8c                	ld	a1,16(a5)
    80001dc0:	6f90                	ld	a2,24(a5)
    80001dc2:	01073023          	sd	a6,0(a4)
    80001dc6:	e708                	sd	a0,8(a4)
    80001dc8:	eb0c                	sd	a1,16(a4)
    80001dca:	ef10                	sd	a2,24(a4)
    80001dcc:	02078793          	addi	a5,a5,32
    80001dd0:	02070713          	addi	a4,a4,32
    80001dd4:	fed792e3          	bne	a5,a3,80001db8 <fork+0x56>
  np->trapframe->a0 = 0;
    80001dd8:	058a3783          	ld	a5,88(s4)
    80001ddc:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001de0:	0d0a8493          	addi	s1,s5,208
    80001de4:	0d0a0913          	addi	s2,s4,208
    80001de8:	150a8993          	addi	s3,s5,336
    80001dec:	a00d                	j	80001e0e <fork+0xac>
    freeproc(np);
    80001dee:	8552                	mv	a0,s4
    80001df0:	00000097          	auipc	ra,0x0
    80001df4:	d6e080e7          	jalr	-658(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001df8:	8552                	mv	a0,s4
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	e90080e7          	jalr	-368(ra) # 80000c8a <release>
    return -1;
    80001e02:	597d                	li	s2,-1
    80001e04:	a059                	j	80001e8a <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e06:	04a1                	addi	s1,s1,8
    80001e08:	0921                	addi	s2,s2,8
    80001e0a:	01348b63          	beq	s1,s3,80001e20 <fork+0xbe>
    if(p->ofile[i])
    80001e0e:	6088                	ld	a0,0(s1)
    80001e10:	d97d                	beqz	a0,80001e06 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e12:	00003097          	auipc	ra,0x3
    80001e16:	968080e7          	jalr	-1688(ra) # 8000477a <filedup>
    80001e1a:	00a93023          	sd	a0,0(s2)
    80001e1e:	b7e5                	j	80001e06 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e20:	150ab503          	ld	a0,336(s5)
    80001e24:	00001097          	auipc	ra,0x1
    80001e28:	7ca080e7          	jalr	1994(ra) # 800035ee <idup>
    80001e2c:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e30:	4641                	li	a2,16
    80001e32:	158a8593          	addi	a1,s5,344
    80001e36:	158a0513          	addi	a0,s4,344
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	fe2080e7          	jalr	-30(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e42:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e46:	8552                	mv	a0,s4
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	e42080e7          	jalr	-446(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e50:	0000f497          	auipc	s1,0xf
    80001e54:	d5848493          	addi	s1,s1,-680 # 80010ba8 <wait_lock>
    80001e58:	8526                	mv	a0,s1
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	d7c080e7          	jalr	-644(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e62:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e66:	8526                	mv	a0,s1
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	e22080e7          	jalr	-478(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e70:	8552                	mv	a0,s4
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	d64080e7          	jalr	-668(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e7a:	478d                	li	a5,3
    80001e7c:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e80:	8552                	mv	a0,s4
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	e08080e7          	jalr	-504(ra) # 80000c8a <release>
}
    80001e8a:	854a                	mv	a0,s2
    80001e8c:	70e2                	ld	ra,56(sp)
    80001e8e:	7442                	ld	s0,48(sp)
    80001e90:	74a2                	ld	s1,40(sp)
    80001e92:	7902                	ld	s2,32(sp)
    80001e94:	69e2                	ld	s3,24(sp)
    80001e96:	6a42                	ld	s4,16(sp)
    80001e98:	6aa2                	ld	s5,8(sp)
    80001e9a:	6121                	addi	sp,sp,64
    80001e9c:	8082                	ret
    return -1;
    80001e9e:	597d                	li	s2,-1
    80001ea0:	b7ed                	j	80001e8a <fork+0x128>

0000000080001ea2 <scheduler>:
{
    80001ea2:	7139                	addi	sp,sp,-64
    80001ea4:	fc06                	sd	ra,56(sp)
    80001ea6:	f822                	sd	s0,48(sp)
    80001ea8:	f426                	sd	s1,40(sp)
    80001eaa:	f04a                	sd	s2,32(sp)
    80001eac:	ec4e                	sd	s3,24(sp)
    80001eae:	e852                	sd	s4,16(sp)
    80001eb0:	e456                	sd	s5,8(sp)
    80001eb2:	e05a                	sd	s6,0(sp)
    80001eb4:	0080                	addi	s0,sp,64
    80001eb6:	8792                	mv	a5,tp
  int id = r_tp();
    80001eb8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eba:	00779a93          	slli	s5,a5,0x7
    80001ebe:	0000f717          	auipc	a4,0xf
    80001ec2:	cd270713          	addi	a4,a4,-814 # 80010b90 <pid_lock>
    80001ec6:	9756                	add	a4,a4,s5
    80001ec8:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ecc:	0000f717          	auipc	a4,0xf
    80001ed0:	cfc70713          	addi	a4,a4,-772 # 80010bc8 <cpus+0x8>
    80001ed4:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ed6:	498d                	li	s3,3
        p->state = RUNNING;
    80001ed8:	4b11                	li	s6,4
        c->proc = p;
    80001eda:	079e                	slli	a5,a5,0x7
    80001edc:	0000fa17          	auipc	s4,0xf
    80001ee0:	cb4a0a13          	addi	s4,s4,-844 # 80010b90 <pid_lock>
    80001ee4:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ee6:	00015917          	auipc	s2,0x15
    80001eea:	cda90913          	addi	s2,s2,-806 # 80016bc0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001eee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ef2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ef6:	10079073          	csrw	sstatus,a5
    80001efa:	0000f497          	auipc	s1,0xf
    80001efe:	0c648493          	addi	s1,s1,198 # 80010fc0 <proc>
    80001f02:	a811                	j	80001f16 <scheduler+0x74>
      release(&p->lock);
    80001f04:	8526                	mv	a0,s1
    80001f06:	fffff097          	auipc	ra,0xfffff
    80001f0a:	d84080e7          	jalr	-636(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f0e:	17048493          	addi	s1,s1,368
    80001f12:	fd248ee3          	beq	s1,s2,80001eee <scheduler+0x4c>
      acquire(&p->lock);
    80001f16:	8526                	mv	a0,s1
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	cbe080e7          	jalr	-834(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    80001f20:	4c9c                	lw	a5,24(s1)
    80001f22:	ff3791e3          	bne	a5,s3,80001f04 <scheduler+0x62>
        p->state = RUNNING;
    80001f26:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f2a:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f2e:	06048593          	addi	a1,s1,96
    80001f32:	8556                	mv	a0,s5
    80001f34:	00000097          	auipc	ra,0x0
    80001f38:	682080e7          	jalr	1666(ra) # 800025b6 <swtch>
        c->proc = 0;
    80001f3c:	020a3823          	sd	zero,48(s4)
    80001f40:	b7d1                	j	80001f04 <scheduler+0x62>

0000000080001f42 <sched>:
{
    80001f42:	7179                	addi	sp,sp,-48
    80001f44:	f406                	sd	ra,40(sp)
    80001f46:	f022                	sd	s0,32(sp)
    80001f48:	ec26                	sd	s1,24(sp)
    80001f4a:	e84a                	sd	s2,16(sp)
    80001f4c:	e44e                	sd	s3,8(sp)
    80001f4e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f50:	00000097          	auipc	ra,0x0
    80001f54:	a5c080e7          	jalr	-1444(ra) # 800019ac <myproc>
    80001f58:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	c02080e7          	jalr	-1022(ra) # 80000b5c <holding>
    80001f62:	c93d                	beqz	a0,80001fd8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f64:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f66:	2781                	sext.w	a5,a5
    80001f68:	079e                	slli	a5,a5,0x7
    80001f6a:	0000f717          	auipc	a4,0xf
    80001f6e:	c2670713          	addi	a4,a4,-986 # 80010b90 <pid_lock>
    80001f72:	97ba                	add	a5,a5,a4
    80001f74:	0a87a703          	lw	a4,168(a5)
    80001f78:	4785                	li	a5,1
    80001f7a:	06f71763          	bne	a4,a5,80001fe8 <sched+0xa6>
  if(p->state == RUNNING)
    80001f7e:	4c98                	lw	a4,24(s1)
    80001f80:	4791                	li	a5,4
    80001f82:	06f70b63          	beq	a4,a5,80001ff8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f86:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f8a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f8c:	efb5                	bnez	a5,80002008 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f8e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f90:	0000f917          	auipc	s2,0xf
    80001f94:	c0090913          	addi	s2,s2,-1024 # 80010b90 <pid_lock>
    80001f98:	2781                	sext.w	a5,a5
    80001f9a:	079e                	slli	a5,a5,0x7
    80001f9c:	97ca                	add	a5,a5,s2
    80001f9e:	0ac7a983          	lw	s3,172(a5)
    80001fa2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fa4:	2781                	sext.w	a5,a5
    80001fa6:	079e                	slli	a5,a5,0x7
    80001fa8:	0000f597          	auipc	a1,0xf
    80001fac:	c2058593          	addi	a1,a1,-992 # 80010bc8 <cpus+0x8>
    80001fb0:	95be                	add	a1,a1,a5
    80001fb2:	06048513          	addi	a0,s1,96
    80001fb6:	00000097          	auipc	ra,0x0
    80001fba:	600080e7          	jalr	1536(ra) # 800025b6 <swtch>
    80001fbe:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fc0:	2781                	sext.w	a5,a5
    80001fc2:	079e                	slli	a5,a5,0x7
    80001fc4:	97ca                	add	a5,a5,s2
    80001fc6:	0b37a623          	sw	s3,172(a5)
}
    80001fca:	70a2                	ld	ra,40(sp)
    80001fcc:	7402                	ld	s0,32(sp)
    80001fce:	64e2                	ld	s1,24(sp)
    80001fd0:	6942                	ld	s2,16(sp)
    80001fd2:	69a2                	ld	s3,8(sp)
    80001fd4:	6145                	addi	sp,sp,48
    80001fd6:	8082                	ret
    panic("sched p->lock");
    80001fd8:	00006517          	auipc	a0,0x6
    80001fdc:	24050513          	addi	a0,a0,576 # 80008218 <digits+0x1d8>
    80001fe0:	ffffe097          	auipc	ra,0xffffe
    80001fe4:	55e080e7          	jalr	1374(ra) # 8000053e <panic>
    panic("sched locks");
    80001fe8:	00006517          	auipc	a0,0x6
    80001fec:	24050513          	addi	a0,a0,576 # 80008228 <digits+0x1e8>
    80001ff0:	ffffe097          	auipc	ra,0xffffe
    80001ff4:	54e080e7          	jalr	1358(ra) # 8000053e <panic>
    panic("sched running");
    80001ff8:	00006517          	auipc	a0,0x6
    80001ffc:	24050513          	addi	a0,a0,576 # 80008238 <digits+0x1f8>
    80002000:	ffffe097          	auipc	ra,0xffffe
    80002004:	53e080e7          	jalr	1342(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002008:	00006517          	auipc	a0,0x6
    8000200c:	24050513          	addi	a0,a0,576 # 80008248 <digits+0x208>
    80002010:	ffffe097          	auipc	ra,0xffffe
    80002014:	52e080e7          	jalr	1326(ra) # 8000053e <panic>

0000000080002018 <yield>:
{
    80002018:	1101                	addi	sp,sp,-32
    8000201a:	ec06                	sd	ra,24(sp)
    8000201c:	e822                	sd	s0,16(sp)
    8000201e:	e426                	sd	s1,8(sp)
    80002020:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002022:	00000097          	auipc	ra,0x0
    80002026:	98a080e7          	jalr	-1654(ra) # 800019ac <myproc>
    8000202a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	baa080e7          	jalr	-1110(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002034:	478d                	li	a5,3
    80002036:	cc9c                	sw	a5,24(s1)
  sched();
    80002038:	00000097          	auipc	ra,0x0
    8000203c:	f0a080e7          	jalr	-246(ra) # 80001f42 <sched>
  release(&p->lock);
    80002040:	8526                	mv	a0,s1
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	c48080e7          	jalr	-952(ra) # 80000c8a <release>
}
    8000204a:	60e2                	ld	ra,24(sp)
    8000204c:	6442                	ld	s0,16(sp)
    8000204e:	64a2                	ld	s1,8(sp)
    80002050:	6105                	addi	sp,sp,32
    80002052:	8082                	ret

0000000080002054 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002054:	7179                	addi	sp,sp,-48
    80002056:	f406                	sd	ra,40(sp)
    80002058:	f022                	sd	s0,32(sp)
    8000205a:	ec26                	sd	s1,24(sp)
    8000205c:	e84a                	sd	s2,16(sp)
    8000205e:	e44e                	sd	s3,8(sp)
    80002060:	1800                	addi	s0,sp,48
    80002062:	89aa                	mv	s3,a0
    80002064:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002066:	00000097          	auipc	ra,0x0
    8000206a:	946080e7          	jalr	-1722(ra) # 800019ac <myproc>
    8000206e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002070:	fffff097          	auipc	ra,0xfffff
    80002074:	b66080e7          	jalr	-1178(ra) # 80000bd6 <acquire>
  release(lk);
    80002078:	854a                	mv	a0,s2
    8000207a:	fffff097          	auipc	ra,0xfffff
    8000207e:	c10080e7          	jalr	-1008(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002082:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002086:	4789                	li	a5,2
    80002088:	cc9c                	sw	a5,24(s1)

  sched();
    8000208a:	00000097          	auipc	ra,0x0
    8000208e:	eb8080e7          	jalr	-328(ra) # 80001f42 <sched>

  // Tidy up.
  p->chan = 0;
    80002092:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002096:	8526                	mv	a0,s1
    80002098:	fffff097          	auipc	ra,0xfffff
    8000209c:	bf2080e7          	jalr	-1038(ra) # 80000c8a <release>
  acquire(lk);
    800020a0:	854a                	mv	a0,s2
    800020a2:	fffff097          	auipc	ra,0xfffff
    800020a6:	b34080e7          	jalr	-1228(ra) # 80000bd6 <acquire>
}
    800020aa:	70a2                	ld	ra,40(sp)
    800020ac:	7402                	ld	s0,32(sp)
    800020ae:	64e2                	ld	s1,24(sp)
    800020b0:	6942                	ld	s2,16(sp)
    800020b2:	69a2                	ld	s3,8(sp)
    800020b4:	6145                	addi	sp,sp,48
    800020b6:	8082                	ret

00000000800020b8 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020b8:	7139                	addi	sp,sp,-64
    800020ba:	fc06                	sd	ra,56(sp)
    800020bc:	f822                	sd	s0,48(sp)
    800020be:	f426                	sd	s1,40(sp)
    800020c0:	f04a                	sd	s2,32(sp)
    800020c2:	ec4e                	sd	s3,24(sp)
    800020c4:	e852                	sd	s4,16(sp)
    800020c6:	e456                	sd	s5,8(sp)
    800020c8:	0080                	addi	s0,sp,64
    800020ca:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020cc:	0000f497          	auipc	s1,0xf
    800020d0:	ef448493          	addi	s1,s1,-268 # 80010fc0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020d4:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020d6:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020d8:	00015917          	auipc	s2,0x15
    800020dc:	ae890913          	addi	s2,s2,-1304 # 80016bc0 <tickslock>
    800020e0:	a811                	j	800020f4 <wakeup+0x3c>
      }
      release(&p->lock);
    800020e2:	8526                	mv	a0,s1
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	ba6080e7          	jalr	-1114(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800020ec:	17048493          	addi	s1,s1,368
    800020f0:	03248663          	beq	s1,s2,8000211c <wakeup+0x64>
    if(p != myproc()){
    800020f4:	00000097          	auipc	ra,0x0
    800020f8:	8b8080e7          	jalr	-1864(ra) # 800019ac <myproc>
    800020fc:	fea488e3          	beq	s1,a0,800020ec <wakeup+0x34>
      acquire(&p->lock);
    80002100:	8526                	mv	a0,s1
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	ad4080e7          	jalr	-1324(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000210a:	4c9c                	lw	a5,24(s1)
    8000210c:	fd379be3          	bne	a5,s3,800020e2 <wakeup+0x2a>
    80002110:	709c                	ld	a5,32(s1)
    80002112:	fd4798e3          	bne	a5,s4,800020e2 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002116:	0154ac23          	sw	s5,24(s1)
    8000211a:	b7e1                	j	800020e2 <wakeup+0x2a>
    }
  }
}
    8000211c:	70e2                	ld	ra,56(sp)
    8000211e:	7442                	ld	s0,48(sp)
    80002120:	74a2                	ld	s1,40(sp)
    80002122:	7902                	ld	s2,32(sp)
    80002124:	69e2                	ld	s3,24(sp)
    80002126:	6a42                	ld	s4,16(sp)
    80002128:	6aa2                	ld	s5,8(sp)
    8000212a:	6121                	addi	sp,sp,64
    8000212c:	8082                	ret

000000008000212e <reparent>:
{
    8000212e:	7179                	addi	sp,sp,-48
    80002130:	f406                	sd	ra,40(sp)
    80002132:	f022                	sd	s0,32(sp)
    80002134:	ec26                	sd	s1,24(sp)
    80002136:	e84a                	sd	s2,16(sp)
    80002138:	e44e                	sd	s3,8(sp)
    8000213a:	e052                	sd	s4,0(sp)
    8000213c:	1800                	addi	s0,sp,48
    8000213e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002140:	0000f497          	auipc	s1,0xf
    80002144:	e8048493          	addi	s1,s1,-384 # 80010fc0 <proc>
      pp->parent = initproc;
    80002148:	00006a17          	auipc	s4,0x6
    8000214c:	7d0a0a13          	addi	s4,s4,2000 # 80008918 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002150:	00015997          	auipc	s3,0x15
    80002154:	a7098993          	addi	s3,s3,-1424 # 80016bc0 <tickslock>
    80002158:	a029                	j	80002162 <reparent+0x34>
    8000215a:	17048493          	addi	s1,s1,368
    8000215e:	01348d63          	beq	s1,s3,80002178 <reparent+0x4a>
    if(pp->parent == p){
    80002162:	7c9c                	ld	a5,56(s1)
    80002164:	ff279be3          	bne	a5,s2,8000215a <reparent+0x2c>
      pp->parent = initproc;
    80002168:	000a3503          	ld	a0,0(s4)
    8000216c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000216e:	00000097          	auipc	ra,0x0
    80002172:	f4a080e7          	jalr	-182(ra) # 800020b8 <wakeup>
    80002176:	b7d5                	j	8000215a <reparent+0x2c>
}
    80002178:	70a2                	ld	ra,40(sp)
    8000217a:	7402                	ld	s0,32(sp)
    8000217c:	64e2                	ld	s1,24(sp)
    8000217e:	6942                	ld	s2,16(sp)
    80002180:	69a2                	ld	s3,8(sp)
    80002182:	6a02                	ld	s4,0(sp)
    80002184:	6145                	addi	sp,sp,48
    80002186:	8082                	ret

0000000080002188 <exit>:
{
    80002188:	7179                	addi	sp,sp,-48
    8000218a:	f406                	sd	ra,40(sp)
    8000218c:	f022                	sd	s0,32(sp)
    8000218e:	ec26                	sd	s1,24(sp)
    80002190:	e84a                	sd	s2,16(sp)
    80002192:	e44e                	sd	s3,8(sp)
    80002194:	e052                	sd	s4,0(sp)
    80002196:	1800                	addi	s0,sp,48
    80002198:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000219a:	00000097          	auipc	ra,0x0
    8000219e:	812080e7          	jalr	-2030(ra) # 800019ac <myproc>
    800021a2:	89aa                	mv	s3,a0
  if(p == initproc)
    800021a4:	00006797          	auipc	a5,0x6
    800021a8:	7747b783          	ld	a5,1908(a5) # 80008918 <initproc>
    800021ac:	0d050493          	addi	s1,a0,208
    800021b0:	15050913          	addi	s2,a0,336
    800021b4:	02a79363          	bne	a5,a0,800021da <exit+0x52>
    panic("init exiting");
    800021b8:	00006517          	auipc	a0,0x6
    800021bc:	0a850513          	addi	a0,a0,168 # 80008260 <digits+0x220>
    800021c0:	ffffe097          	auipc	ra,0xffffe
    800021c4:	37e080e7          	jalr	894(ra) # 8000053e <panic>
      fileclose(f);
    800021c8:	00002097          	auipc	ra,0x2
    800021cc:	604080e7          	jalr	1540(ra) # 800047cc <fileclose>
      p->ofile[fd] = 0;
    800021d0:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021d4:	04a1                	addi	s1,s1,8
    800021d6:	01248563          	beq	s1,s2,800021e0 <exit+0x58>
    if(p->ofile[fd]){
    800021da:	6088                	ld	a0,0(s1)
    800021dc:	f575                	bnez	a0,800021c8 <exit+0x40>
    800021de:	bfdd                	j	800021d4 <exit+0x4c>
  begin_op();
    800021e0:	00002097          	auipc	ra,0x2
    800021e4:	120080e7          	jalr	288(ra) # 80004300 <begin_op>
  iput(p->cwd);
    800021e8:	1509b503          	ld	a0,336(s3)
    800021ec:	00001097          	auipc	ra,0x1
    800021f0:	5fa080e7          	jalr	1530(ra) # 800037e6 <iput>
  end_op();
    800021f4:	00002097          	auipc	ra,0x2
    800021f8:	18c080e7          	jalr	396(ra) # 80004380 <end_op>
  p->cwd = 0;
    800021fc:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002200:	0000f497          	auipc	s1,0xf
    80002204:	9a848493          	addi	s1,s1,-1624 # 80010ba8 <wait_lock>
    80002208:	8526                	mv	a0,s1
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	9cc080e7          	jalr	-1588(ra) # 80000bd6 <acquire>
  reparent(p);
    80002212:	854e                	mv	a0,s3
    80002214:	00000097          	auipc	ra,0x0
    80002218:	f1a080e7          	jalr	-230(ra) # 8000212e <reparent>
  wakeup(p->parent);
    8000221c:	0389b503          	ld	a0,56(s3)
    80002220:	00000097          	auipc	ra,0x0
    80002224:	e98080e7          	jalr	-360(ra) # 800020b8 <wakeup>
  acquire(&p->lock);
    80002228:	854e                	mv	a0,s3
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	9ac080e7          	jalr	-1620(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002232:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002236:	4795                	li	a5,5
    80002238:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000223c:	8526                	mv	a0,s1
    8000223e:	fffff097          	auipc	ra,0xfffff
    80002242:	a4c080e7          	jalr	-1460(ra) # 80000c8a <release>
  sched();
    80002246:	00000097          	auipc	ra,0x0
    8000224a:	cfc080e7          	jalr	-772(ra) # 80001f42 <sched>
  panic("zombie exit");
    8000224e:	00006517          	auipc	a0,0x6
    80002252:	02250513          	addi	a0,a0,34 # 80008270 <digits+0x230>
    80002256:	ffffe097          	auipc	ra,0xffffe
    8000225a:	2e8080e7          	jalr	744(ra) # 8000053e <panic>

000000008000225e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000225e:	7179                	addi	sp,sp,-48
    80002260:	f406                	sd	ra,40(sp)
    80002262:	f022                	sd	s0,32(sp)
    80002264:	ec26                	sd	s1,24(sp)
    80002266:	e84a                	sd	s2,16(sp)
    80002268:	e44e                	sd	s3,8(sp)
    8000226a:	1800                	addi	s0,sp,48
    8000226c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000226e:	0000f497          	auipc	s1,0xf
    80002272:	d5248493          	addi	s1,s1,-686 # 80010fc0 <proc>
    80002276:	00015997          	auipc	s3,0x15
    8000227a:	94a98993          	addi	s3,s3,-1718 # 80016bc0 <tickslock>
    acquire(&p->lock);
    8000227e:	8526                	mv	a0,s1
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	956080e7          	jalr	-1706(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    80002288:	589c                	lw	a5,48(s1)
    8000228a:	01278d63          	beq	a5,s2,800022a4 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000228e:	8526                	mv	a0,s1
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	9fa080e7          	jalr	-1542(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002298:	17048493          	addi	s1,s1,368
    8000229c:	ff3491e3          	bne	s1,s3,8000227e <kill+0x20>
  }
  return -1;
    800022a0:	557d                	li	a0,-1
    800022a2:	a829                	j	800022bc <kill+0x5e>
      p->killed = 1;
    800022a4:	4785                	li	a5,1
    800022a6:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022a8:	4c98                	lw	a4,24(s1)
    800022aa:	4789                	li	a5,2
    800022ac:	00f70f63          	beq	a4,a5,800022ca <kill+0x6c>
      release(&p->lock);
    800022b0:	8526                	mv	a0,s1
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	9d8080e7          	jalr	-1576(ra) # 80000c8a <release>
      return 0;
    800022ba:	4501                	li	a0,0
}
    800022bc:	70a2                	ld	ra,40(sp)
    800022be:	7402                	ld	s0,32(sp)
    800022c0:	64e2                	ld	s1,24(sp)
    800022c2:	6942                	ld	s2,16(sp)
    800022c4:	69a2                	ld	s3,8(sp)
    800022c6:	6145                	addi	sp,sp,48
    800022c8:	8082                	ret
        p->state = RUNNABLE;
    800022ca:	478d                	li	a5,3
    800022cc:	cc9c                	sw	a5,24(s1)
    800022ce:	b7cd                	j	800022b0 <kill+0x52>

00000000800022d0 <setkilled>:

void
setkilled(struct proc *p)
{
    800022d0:	1101                	addi	sp,sp,-32
    800022d2:	ec06                	sd	ra,24(sp)
    800022d4:	e822                	sd	s0,16(sp)
    800022d6:	e426                	sd	s1,8(sp)
    800022d8:	1000                	addi	s0,sp,32
    800022da:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	8fa080e7          	jalr	-1798(ra) # 80000bd6 <acquire>
  p->killed = 1;
    800022e4:	4785                	li	a5,1
    800022e6:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800022e8:	8526                	mv	a0,s1
    800022ea:	fffff097          	auipc	ra,0xfffff
    800022ee:	9a0080e7          	jalr	-1632(ra) # 80000c8a <release>
}
    800022f2:	60e2                	ld	ra,24(sp)
    800022f4:	6442                	ld	s0,16(sp)
    800022f6:	64a2                	ld	s1,8(sp)
    800022f8:	6105                	addi	sp,sp,32
    800022fa:	8082                	ret

00000000800022fc <killed>:

int
killed(struct proc *p)
{
    800022fc:	1101                	addi	sp,sp,-32
    800022fe:	ec06                	sd	ra,24(sp)
    80002300:	e822                	sd	s0,16(sp)
    80002302:	e426                	sd	s1,8(sp)
    80002304:	e04a                	sd	s2,0(sp)
    80002306:	1000                	addi	s0,sp,32
    80002308:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	8cc080e7          	jalr	-1844(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002312:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002316:	8526                	mv	a0,s1
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	972080e7          	jalr	-1678(ra) # 80000c8a <release>
  return k;
}
    80002320:	854a                	mv	a0,s2
    80002322:	60e2                	ld	ra,24(sp)
    80002324:	6442                	ld	s0,16(sp)
    80002326:	64a2                	ld	s1,8(sp)
    80002328:	6902                	ld	s2,0(sp)
    8000232a:	6105                	addi	sp,sp,32
    8000232c:	8082                	ret

000000008000232e <wait>:
{
    8000232e:	715d                	addi	sp,sp,-80
    80002330:	e486                	sd	ra,72(sp)
    80002332:	e0a2                	sd	s0,64(sp)
    80002334:	fc26                	sd	s1,56(sp)
    80002336:	f84a                	sd	s2,48(sp)
    80002338:	f44e                	sd	s3,40(sp)
    8000233a:	f052                	sd	s4,32(sp)
    8000233c:	ec56                	sd	s5,24(sp)
    8000233e:	e85a                	sd	s6,16(sp)
    80002340:	e45e                	sd	s7,8(sp)
    80002342:	e062                	sd	s8,0(sp)
    80002344:	0880                	addi	s0,sp,80
    80002346:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	664080e7          	jalr	1636(ra) # 800019ac <myproc>
    80002350:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002352:	0000f517          	auipc	a0,0xf
    80002356:	85650513          	addi	a0,a0,-1962 # 80010ba8 <wait_lock>
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	87c080e7          	jalr	-1924(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002362:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002364:	4a15                	li	s4,5
        havekids = 1;
    80002366:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002368:	00015997          	auipc	s3,0x15
    8000236c:	85898993          	addi	s3,s3,-1960 # 80016bc0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002370:	0000fc17          	auipc	s8,0xf
    80002374:	838c0c13          	addi	s8,s8,-1992 # 80010ba8 <wait_lock>
    havekids = 0;
    80002378:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000237a:	0000f497          	auipc	s1,0xf
    8000237e:	c4648493          	addi	s1,s1,-954 # 80010fc0 <proc>
    80002382:	a0bd                	j	800023f0 <wait+0xc2>
          pid = pp->pid;
    80002384:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002388:	000b0e63          	beqz	s6,800023a4 <wait+0x76>
    8000238c:	4691                	li	a3,4
    8000238e:	02c48613          	addi	a2,s1,44
    80002392:	85da                	mv	a1,s6
    80002394:	05093503          	ld	a0,80(s2)
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	2d0080e7          	jalr	720(ra) # 80001668 <copyout>
    800023a0:	02054563          	bltz	a0,800023ca <wait+0x9c>
          freeproc(pp);
    800023a4:	8526                	mv	a0,s1
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	7b8080e7          	jalr	1976(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    800023ae:	8526                	mv	a0,s1
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	8da080e7          	jalr	-1830(ra) # 80000c8a <release>
          release(&wait_lock);
    800023b8:	0000e517          	auipc	a0,0xe
    800023bc:	7f050513          	addi	a0,a0,2032 # 80010ba8 <wait_lock>
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	8ca080e7          	jalr	-1846(ra) # 80000c8a <release>
          return pid;
    800023c8:	a0b5                	j	80002434 <wait+0x106>
            release(&pp->lock);
    800023ca:	8526                	mv	a0,s1
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	8be080e7          	jalr	-1858(ra) # 80000c8a <release>
            release(&wait_lock);
    800023d4:	0000e517          	auipc	a0,0xe
    800023d8:	7d450513          	addi	a0,a0,2004 # 80010ba8 <wait_lock>
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	8ae080e7          	jalr	-1874(ra) # 80000c8a <release>
            return -1;
    800023e4:	59fd                	li	s3,-1
    800023e6:	a0b9                	j	80002434 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023e8:	17048493          	addi	s1,s1,368
    800023ec:	03348463          	beq	s1,s3,80002414 <wait+0xe6>
      if(pp->parent == p){
    800023f0:	7c9c                	ld	a5,56(s1)
    800023f2:	ff279be3          	bne	a5,s2,800023e8 <wait+0xba>
        acquire(&pp->lock);
    800023f6:	8526                	mv	a0,s1
    800023f8:	ffffe097          	auipc	ra,0xffffe
    800023fc:	7de080e7          	jalr	2014(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    80002400:	4c9c                	lw	a5,24(s1)
    80002402:	f94781e3          	beq	a5,s4,80002384 <wait+0x56>
        release(&pp->lock);
    80002406:	8526                	mv	a0,s1
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	882080e7          	jalr	-1918(ra) # 80000c8a <release>
        havekids = 1;
    80002410:	8756                	mv	a4,s5
    80002412:	bfd9                	j	800023e8 <wait+0xba>
    if(!havekids || killed(p)){
    80002414:	c719                	beqz	a4,80002422 <wait+0xf4>
    80002416:	854a                	mv	a0,s2
    80002418:	00000097          	auipc	ra,0x0
    8000241c:	ee4080e7          	jalr	-284(ra) # 800022fc <killed>
    80002420:	c51d                	beqz	a0,8000244e <wait+0x120>
      release(&wait_lock);
    80002422:	0000e517          	auipc	a0,0xe
    80002426:	78650513          	addi	a0,a0,1926 # 80010ba8 <wait_lock>
    8000242a:	fffff097          	auipc	ra,0xfffff
    8000242e:	860080e7          	jalr	-1952(ra) # 80000c8a <release>
      return -1;
    80002432:	59fd                	li	s3,-1
}
    80002434:	854e                	mv	a0,s3
    80002436:	60a6                	ld	ra,72(sp)
    80002438:	6406                	ld	s0,64(sp)
    8000243a:	74e2                	ld	s1,56(sp)
    8000243c:	7942                	ld	s2,48(sp)
    8000243e:	79a2                	ld	s3,40(sp)
    80002440:	7a02                	ld	s4,32(sp)
    80002442:	6ae2                	ld	s5,24(sp)
    80002444:	6b42                	ld	s6,16(sp)
    80002446:	6ba2                	ld	s7,8(sp)
    80002448:	6c02                	ld	s8,0(sp)
    8000244a:	6161                	addi	sp,sp,80
    8000244c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000244e:	85e2                	mv	a1,s8
    80002450:	854a                	mv	a0,s2
    80002452:	00000097          	auipc	ra,0x0
    80002456:	c02080e7          	jalr	-1022(ra) # 80002054 <sleep>
    havekids = 0;
    8000245a:	bf39                	j	80002378 <wait+0x4a>

000000008000245c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000245c:	7179                	addi	sp,sp,-48
    8000245e:	f406                	sd	ra,40(sp)
    80002460:	f022                	sd	s0,32(sp)
    80002462:	ec26                	sd	s1,24(sp)
    80002464:	e84a                	sd	s2,16(sp)
    80002466:	e44e                	sd	s3,8(sp)
    80002468:	e052                	sd	s4,0(sp)
    8000246a:	1800                	addi	s0,sp,48
    8000246c:	84aa                	mv	s1,a0
    8000246e:	892e                	mv	s2,a1
    80002470:	89b2                	mv	s3,a2
    80002472:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002474:	fffff097          	auipc	ra,0xfffff
    80002478:	538080e7          	jalr	1336(ra) # 800019ac <myproc>
  if(user_dst){
    8000247c:	c08d                	beqz	s1,8000249e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000247e:	86d2                	mv	a3,s4
    80002480:	864e                	mv	a2,s3
    80002482:	85ca                	mv	a1,s2
    80002484:	6928                	ld	a0,80(a0)
    80002486:	fffff097          	auipc	ra,0xfffff
    8000248a:	1e2080e7          	jalr	482(ra) # 80001668 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000248e:	70a2                	ld	ra,40(sp)
    80002490:	7402                	ld	s0,32(sp)
    80002492:	64e2                	ld	s1,24(sp)
    80002494:	6942                	ld	s2,16(sp)
    80002496:	69a2                	ld	s3,8(sp)
    80002498:	6a02                	ld	s4,0(sp)
    8000249a:	6145                	addi	sp,sp,48
    8000249c:	8082                	ret
    memmove((char *)dst, src, len);
    8000249e:	000a061b          	sext.w	a2,s4
    800024a2:	85ce                	mv	a1,s3
    800024a4:	854a                	mv	a0,s2
    800024a6:	fffff097          	auipc	ra,0xfffff
    800024aa:	888080e7          	jalr	-1912(ra) # 80000d2e <memmove>
    return 0;
    800024ae:	8526                	mv	a0,s1
    800024b0:	bff9                	j	8000248e <either_copyout+0x32>

00000000800024b2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024b2:	7179                	addi	sp,sp,-48
    800024b4:	f406                	sd	ra,40(sp)
    800024b6:	f022                	sd	s0,32(sp)
    800024b8:	ec26                	sd	s1,24(sp)
    800024ba:	e84a                	sd	s2,16(sp)
    800024bc:	e44e                	sd	s3,8(sp)
    800024be:	e052                	sd	s4,0(sp)
    800024c0:	1800                	addi	s0,sp,48
    800024c2:	892a                	mv	s2,a0
    800024c4:	84ae                	mv	s1,a1
    800024c6:	89b2                	mv	s3,a2
    800024c8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ca:	fffff097          	auipc	ra,0xfffff
    800024ce:	4e2080e7          	jalr	1250(ra) # 800019ac <myproc>
  if(user_src){
    800024d2:	c08d                	beqz	s1,800024f4 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024d4:	86d2                	mv	a3,s4
    800024d6:	864e                	mv	a2,s3
    800024d8:	85ca                	mv	a1,s2
    800024da:	6928                	ld	a0,80(a0)
    800024dc:	fffff097          	auipc	ra,0xfffff
    800024e0:	218080e7          	jalr	536(ra) # 800016f4 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024e4:	70a2                	ld	ra,40(sp)
    800024e6:	7402                	ld	s0,32(sp)
    800024e8:	64e2                	ld	s1,24(sp)
    800024ea:	6942                	ld	s2,16(sp)
    800024ec:	69a2                	ld	s3,8(sp)
    800024ee:	6a02                	ld	s4,0(sp)
    800024f0:	6145                	addi	sp,sp,48
    800024f2:	8082                	ret
    memmove(dst, (char*)src, len);
    800024f4:	000a061b          	sext.w	a2,s4
    800024f8:	85ce                	mv	a1,s3
    800024fa:	854a                	mv	a0,s2
    800024fc:	fffff097          	auipc	ra,0xfffff
    80002500:	832080e7          	jalr	-1998(ra) # 80000d2e <memmove>
    return 0;
    80002504:	8526                	mv	a0,s1
    80002506:	bff9                	j	800024e4 <either_copyin+0x32>

0000000080002508 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002508:	715d                	addi	sp,sp,-80
    8000250a:	e486                	sd	ra,72(sp)
    8000250c:	e0a2                	sd	s0,64(sp)
    8000250e:	fc26                	sd	s1,56(sp)
    80002510:	f84a                	sd	s2,48(sp)
    80002512:	f44e                	sd	s3,40(sp)
    80002514:	f052                	sd	s4,32(sp)
    80002516:	ec56                	sd	s5,24(sp)
    80002518:	e85a                	sd	s6,16(sp)
    8000251a:	e45e                	sd	s7,8(sp)
    8000251c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000251e:	00006517          	auipc	a0,0x6
    80002522:	baa50513          	addi	a0,a0,-1110 # 800080c8 <digits+0x88>
    80002526:	ffffe097          	auipc	ra,0xffffe
    8000252a:	062080e7          	jalr	98(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000252e:	0000f497          	auipc	s1,0xf
    80002532:	bea48493          	addi	s1,s1,-1046 # 80011118 <proc+0x158>
    80002536:	00014917          	auipc	s2,0x14
    8000253a:	7e290913          	addi	s2,s2,2018 # 80016d18 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000253e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002540:	00006997          	auipc	s3,0x6
    80002544:	d4098993          	addi	s3,s3,-704 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002548:	00006a97          	auipc	s5,0x6
    8000254c:	d40a8a93          	addi	s5,s5,-704 # 80008288 <digits+0x248>
    printf("\n");
    80002550:	00006a17          	auipc	s4,0x6
    80002554:	b78a0a13          	addi	s4,s4,-1160 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002558:	00006b97          	auipc	s7,0x6
    8000255c:	d70b8b93          	addi	s7,s7,-656 # 800082c8 <states.0>
    80002560:	a00d                	j	80002582 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002562:	ed86a583          	lw	a1,-296(a3)
    80002566:	8556                	mv	a0,s5
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	020080e7          	jalr	32(ra) # 80000588 <printf>
    printf("\n");
    80002570:	8552                	mv	a0,s4
    80002572:	ffffe097          	auipc	ra,0xffffe
    80002576:	016080e7          	jalr	22(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000257a:	17048493          	addi	s1,s1,368
    8000257e:	03248163          	beq	s1,s2,800025a0 <procdump+0x98>
    if(p->state == UNUSED)
    80002582:	86a6                	mv	a3,s1
    80002584:	ec04a783          	lw	a5,-320(s1)
    80002588:	dbed                	beqz	a5,8000257a <procdump+0x72>
      state = "???";
    8000258a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000258c:	fcfb6be3          	bltu	s6,a5,80002562 <procdump+0x5a>
    80002590:	1782                	slli	a5,a5,0x20
    80002592:	9381                	srli	a5,a5,0x20
    80002594:	078e                	slli	a5,a5,0x3
    80002596:	97de                	add	a5,a5,s7
    80002598:	6390                	ld	a2,0(a5)
    8000259a:	f661                	bnez	a2,80002562 <procdump+0x5a>
      state = "???";
    8000259c:	864e                	mv	a2,s3
    8000259e:	b7d1                	j	80002562 <procdump+0x5a>
  }
}
    800025a0:	60a6                	ld	ra,72(sp)
    800025a2:	6406                	ld	s0,64(sp)
    800025a4:	74e2                	ld	s1,56(sp)
    800025a6:	7942                	ld	s2,48(sp)
    800025a8:	79a2                	ld	s3,40(sp)
    800025aa:	7a02                	ld	s4,32(sp)
    800025ac:	6ae2                	ld	s5,24(sp)
    800025ae:	6b42                	ld	s6,16(sp)
    800025b0:	6ba2                	ld	s7,8(sp)
    800025b2:	6161                	addi	sp,sp,80
    800025b4:	8082                	ret

00000000800025b6 <swtch>:
    800025b6:	00153023          	sd	ra,0(a0)
    800025ba:	00253423          	sd	sp,8(a0)
    800025be:	e900                	sd	s0,16(a0)
    800025c0:	ed04                	sd	s1,24(a0)
    800025c2:	03253023          	sd	s2,32(a0)
    800025c6:	03353423          	sd	s3,40(a0)
    800025ca:	03453823          	sd	s4,48(a0)
    800025ce:	03553c23          	sd	s5,56(a0)
    800025d2:	05653023          	sd	s6,64(a0)
    800025d6:	05753423          	sd	s7,72(a0)
    800025da:	05853823          	sd	s8,80(a0)
    800025de:	05953c23          	sd	s9,88(a0)
    800025e2:	07a53023          	sd	s10,96(a0)
    800025e6:	07b53423          	sd	s11,104(a0)
    800025ea:	0005b083          	ld	ra,0(a1)
    800025ee:	0085b103          	ld	sp,8(a1)
    800025f2:	6980                	ld	s0,16(a1)
    800025f4:	6d84                	ld	s1,24(a1)
    800025f6:	0205b903          	ld	s2,32(a1)
    800025fa:	0285b983          	ld	s3,40(a1)
    800025fe:	0305ba03          	ld	s4,48(a1)
    80002602:	0385ba83          	ld	s5,56(a1)
    80002606:	0405bb03          	ld	s6,64(a1)
    8000260a:	0485bb83          	ld	s7,72(a1)
    8000260e:	0505bc03          	ld	s8,80(a1)
    80002612:	0585bc83          	ld	s9,88(a1)
    80002616:	0605bd03          	ld	s10,96(a1)
    8000261a:	0685bd83          	ld	s11,104(a1)
    8000261e:	8082                	ret

0000000080002620 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002620:	1141                	addi	sp,sp,-16
    80002622:	e406                	sd	ra,8(sp)
    80002624:	e022                	sd	s0,0(sp)
    80002626:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002628:	00006597          	auipc	a1,0x6
    8000262c:	cd058593          	addi	a1,a1,-816 # 800082f8 <states.0+0x30>
    80002630:	00014517          	auipc	a0,0x14
    80002634:	59050513          	addi	a0,a0,1424 # 80016bc0 <tickslock>
    80002638:	ffffe097          	auipc	ra,0xffffe
    8000263c:	50e080e7          	jalr	1294(ra) # 80000b46 <initlock>
}
    80002640:	60a2                	ld	ra,8(sp)
    80002642:	6402                	ld	s0,0(sp)
    80002644:	0141                	addi	sp,sp,16
    80002646:	8082                	ret

0000000080002648 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002648:	1141                	addi	sp,sp,-16
    8000264a:	e422                	sd	s0,8(sp)
    8000264c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000264e:	00004797          	auipc	a5,0x4
    80002652:	9e278793          	addi	a5,a5,-1566 # 80006030 <kernelvec>
    80002656:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000265a:	6422                	ld	s0,8(sp)
    8000265c:	0141                	addi	sp,sp,16
    8000265e:	8082                	ret

0000000080002660 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002660:	1141                	addi	sp,sp,-16
    80002662:	e406                	sd	ra,8(sp)
    80002664:	e022                	sd	s0,0(sp)
    80002666:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002668:	fffff097          	auipc	ra,0xfffff
    8000266c:	344080e7          	jalr	836(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002670:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002674:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002676:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000267a:	00005617          	auipc	a2,0x5
    8000267e:	98660613          	addi	a2,a2,-1658 # 80007000 <_trampoline>
    80002682:	00005697          	auipc	a3,0x5
    80002686:	97e68693          	addi	a3,a3,-1666 # 80007000 <_trampoline>
    8000268a:	8e91                	sub	a3,a3,a2
    8000268c:	040007b7          	lui	a5,0x4000
    80002690:	17fd                	addi	a5,a5,-1
    80002692:	07b2                	slli	a5,a5,0xc
    80002694:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002696:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000269a:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000269c:	180026f3          	csrr	a3,satp
    800026a0:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026a2:	6d38                	ld	a4,88(a0)
    800026a4:	6134                	ld	a3,64(a0)
    800026a6:	6585                	lui	a1,0x1
    800026a8:	96ae                	add	a3,a3,a1
    800026aa:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026ac:	6d38                	ld	a4,88(a0)
    800026ae:	00000697          	auipc	a3,0x0
    800026b2:	13068693          	addi	a3,a3,304 # 800027de <usertrap>
    800026b6:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026b8:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026ba:	8692                	mv	a3,tp
    800026bc:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026be:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026c2:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026c6:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026ca:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026ce:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026d0:	6f18                	ld	a4,24(a4)
    800026d2:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026d6:	6928                	ld	a0,80(a0)
    800026d8:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800026da:	00005717          	auipc	a4,0x5
    800026de:	9c270713          	addi	a4,a4,-1598 # 8000709c <userret>
    800026e2:	8f11                	sub	a4,a4,a2
    800026e4:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800026e6:	577d                	li	a4,-1
    800026e8:	177e                	slli	a4,a4,0x3f
    800026ea:	8d59                	or	a0,a0,a4
    800026ec:	9782                	jalr	a5
}
    800026ee:	60a2                	ld	ra,8(sp)
    800026f0:	6402                	ld	s0,0(sp)
    800026f2:	0141                	addi	sp,sp,16
    800026f4:	8082                	ret

00000000800026f6 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800026f6:	1101                	addi	sp,sp,-32
    800026f8:	ec06                	sd	ra,24(sp)
    800026fa:	e822                	sd	s0,16(sp)
    800026fc:	e426                	sd	s1,8(sp)
    800026fe:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002700:	00014497          	auipc	s1,0x14
    80002704:	4c048493          	addi	s1,s1,1216 # 80016bc0 <tickslock>
    80002708:	8526                	mv	a0,s1
    8000270a:	ffffe097          	auipc	ra,0xffffe
    8000270e:	4cc080e7          	jalr	1228(ra) # 80000bd6 <acquire>
  ticks++;
    80002712:	00006517          	auipc	a0,0x6
    80002716:	20e50513          	addi	a0,a0,526 # 80008920 <ticks>
    8000271a:	411c                	lw	a5,0(a0)
    8000271c:	2785                	addiw	a5,a5,1
    8000271e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002720:	00000097          	auipc	ra,0x0
    80002724:	998080e7          	jalr	-1640(ra) # 800020b8 <wakeup>
  release(&tickslock);
    80002728:	8526                	mv	a0,s1
    8000272a:	ffffe097          	auipc	ra,0xffffe
    8000272e:	560080e7          	jalr	1376(ra) # 80000c8a <release>
}
    80002732:	60e2                	ld	ra,24(sp)
    80002734:	6442                	ld	s0,16(sp)
    80002736:	64a2                	ld	s1,8(sp)
    80002738:	6105                	addi	sp,sp,32
    8000273a:	8082                	ret

000000008000273c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000273c:	1101                	addi	sp,sp,-32
    8000273e:	ec06                	sd	ra,24(sp)
    80002740:	e822                	sd	s0,16(sp)
    80002742:	e426                	sd	s1,8(sp)
    80002744:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002746:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000274a:	00074d63          	bltz	a4,80002764 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000274e:	57fd                	li	a5,-1
    80002750:	17fe                	slli	a5,a5,0x3f
    80002752:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002754:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002756:	06f70363          	beq	a4,a5,800027bc <devintr+0x80>
  }
}
    8000275a:	60e2                	ld	ra,24(sp)
    8000275c:	6442                	ld	s0,16(sp)
    8000275e:	64a2                	ld	s1,8(sp)
    80002760:	6105                	addi	sp,sp,32
    80002762:	8082                	ret
     (scause & 0xff) == 9){
    80002764:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002768:	46a5                	li	a3,9
    8000276a:	fed792e3          	bne	a5,a3,8000274e <devintr+0x12>
    int irq = plic_claim();
    8000276e:	00004097          	auipc	ra,0x4
    80002772:	9ca080e7          	jalr	-1590(ra) # 80006138 <plic_claim>
    80002776:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002778:	47a9                	li	a5,10
    8000277a:	02f50763          	beq	a0,a5,800027a8 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000277e:	4785                	li	a5,1
    80002780:	02f50963          	beq	a0,a5,800027b2 <devintr+0x76>
    return 1;
    80002784:	4505                	li	a0,1
    } else if(irq){
    80002786:	d8f1                	beqz	s1,8000275a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002788:	85a6                	mv	a1,s1
    8000278a:	00006517          	auipc	a0,0x6
    8000278e:	b7650513          	addi	a0,a0,-1162 # 80008300 <states.0+0x38>
    80002792:	ffffe097          	auipc	ra,0xffffe
    80002796:	df6080e7          	jalr	-522(ra) # 80000588 <printf>
      plic_complete(irq);
    8000279a:	8526                	mv	a0,s1
    8000279c:	00004097          	auipc	ra,0x4
    800027a0:	9c0080e7          	jalr	-1600(ra) # 8000615c <plic_complete>
    return 1;
    800027a4:	4505                	li	a0,1
    800027a6:	bf55                	j	8000275a <devintr+0x1e>
      uartintr();
    800027a8:	ffffe097          	auipc	ra,0xffffe
    800027ac:	1f2080e7          	jalr	498(ra) # 8000099a <uartintr>
    800027b0:	b7ed                	j	8000279a <devintr+0x5e>
      virtio_disk_intr();
    800027b2:	00004097          	auipc	ra,0x4
    800027b6:	e76080e7          	jalr	-394(ra) # 80006628 <virtio_disk_intr>
    800027ba:	b7c5                	j	8000279a <devintr+0x5e>
    if(cpuid() == 0){
    800027bc:	fffff097          	auipc	ra,0xfffff
    800027c0:	1c4080e7          	jalr	452(ra) # 80001980 <cpuid>
    800027c4:	c901                	beqz	a0,800027d4 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027c6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027ca:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027cc:	14479073          	csrw	sip,a5
    return 2;
    800027d0:	4509                	li	a0,2
    800027d2:	b761                	j	8000275a <devintr+0x1e>
      clockintr();
    800027d4:	00000097          	auipc	ra,0x0
    800027d8:	f22080e7          	jalr	-222(ra) # 800026f6 <clockintr>
    800027dc:	b7ed                	j	800027c6 <devintr+0x8a>

00000000800027de <usertrap>:
{
    800027de:	1101                	addi	sp,sp,-32
    800027e0:	ec06                	sd	ra,24(sp)
    800027e2:	e822                	sd	s0,16(sp)
    800027e4:	e426                	sd	s1,8(sp)
    800027e6:	e04a                	sd	s2,0(sp)
    800027e8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027ea:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800027ee:	1007f793          	andi	a5,a5,256
    800027f2:	e3b1                	bnez	a5,80002836 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027f4:	00004797          	auipc	a5,0x4
    800027f8:	83c78793          	addi	a5,a5,-1988 # 80006030 <kernelvec>
    800027fc:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002800:	fffff097          	auipc	ra,0xfffff
    80002804:	1ac080e7          	jalr	428(ra) # 800019ac <myproc>
    80002808:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000280a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000280c:	14102773          	csrr	a4,sepc
    80002810:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002812:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002816:	47a1                	li	a5,8
    80002818:	02f70763          	beq	a4,a5,80002846 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    8000281c:	00000097          	auipc	ra,0x0
    80002820:	f20080e7          	jalr	-224(ra) # 8000273c <devintr>
    80002824:	892a                	mv	s2,a0
    80002826:	c151                	beqz	a0,800028aa <usertrap+0xcc>
  if(killed(p))
    80002828:	8526                	mv	a0,s1
    8000282a:	00000097          	auipc	ra,0x0
    8000282e:	ad2080e7          	jalr	-1326(ra) # 800022fc <killed>
    80002832:	c929                	beqz	a0,80002884 <usertrap+0xa6>
    80002834:	a099                	j	8000287a <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002836:	00006517          	auipc	a0,0x6
    8000283a:	aea50513          	addi	a0,a0,-1302 # 80008320 <states.0+0x58>
    8000283e:	ffffe097          	auipc	ra,0xffffe
    80002842:	d00080e7          	jalr	-768(ra) # 8000053e <panic>
    if(killed(p))
    80002846:	00000097          	auipc	ra,0x0
    8000284a:	ab6080e7          	jalr	-1354(ra) # 800022fc <killed>
    8000284e:	e921                	bnez	a0,8000289e <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002850:	6cb8                	ld	a4,88(s1)
    80002852:	6f1c                	ld	a5,24(a4)
    80002854:	0791                	addi	a5,a5,4
    80002856:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002858:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000285c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002860:	10079073          	csrw	sstatus,a5
    syscall();
    80002864:	00000097          	auipc	ra,0x0
    80002868:	2d4080e7          	jalr	724(ra) # 80002b38 <syscall>
  if(killed(p))
    8000286c:	8526                	mv	a0,s1
    8000286e:	00000097          	auipc	ra,0x0
    80002872:	a8e080e7          	jalr	-1394(ra) # 800022fc <killed>
    80002876:	c911                	beqz	a0,8000288a <usertrap+0xac>
    80002878:	4901                	li	s2,0
    exit(-1);
    8000287a:	557d                	li	a0,-1
    8000287c:	00000097          	auipc	ra,0x0
    80002880:	90c080e7          	jalr	-1780(ra) # 80002188 <exit>
  if(which_dev == 2)
    80002884:	4789                	li	a5,2
    80002886:	04f90f63          	beq	s2,a5,800028e4 <usertrap+0x106>
  usertrapret();
    8000288a:	00000097          	auipc	ra,0x0
    8000288e:	dd6080e7          	jalr	-554(ra) # 80002660 <usertrapret>
}
    80002892:	60e2                	ld	ra,24(sp)
    80002894:	6442                	ld	s0,16(sp)
    80002896:	64a2                	ld	s1,8(sp)
    80002898:	6902                	ld	s2,0(sp)
    8000289a:	6105                	addi	sp,sp,32
    8000289c:	8082                	ret
      exit(-1);
    8000289e:	557d                	li	a0,-1
    800028a0:	00000097          	auipc	ra,0x0
    800028a4:	8e8080e7          	jalr	-1816(ra) # 80002188 <exit>
    800028a8:	b765                	j	80002850 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028aa:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028ae:	5890                	lw	a2,48(s1)
    800028b0:	00006517          	auipc	a0,0x6
    800028b4:	a9050513          	addi	a0,a0,-1392 # 80008340 <states.0+0x78>
    800028b8:	ffffe097          	auipc	ra,0xffffe
    800028bc:	cd0080e7          	jalr	-816(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028c0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028c4:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028c8:	00006517          	auipc	a0,0x6
    800028cc:	aa850513          	addi	a0,a0,-1368 # 80008370 <states.0+0xa8>
    800028d0:	ffffe097          	auipc	ra,0xffffe
    800028d4:	cb8080e7          	jalr	-840(ra) # 80000588 <printf>
    setkilled(p);
    800028d8:	8526                	mv	a0,s1
    800028da:	00000097          	auipc	ra,0x0
    800028de:	9f6080e7          	jalr	-1546(ra) # 800022d0 <setkilled>
    800028e2:	b769                	j	8000286c <usertrap+0x8e>
    yield();
    800028e4:	fffff097          	auipc	ra,0xfffff
    800028e8:	734080e7          	jalr	1844(ra) # 80002018 <yield>
    800028ec:	bf79                	j	8000288a <usertrap+0xac>

00000000800028ee <kerneltrap>:
{
    800028ee:	7179                	addi	sp,sp,-48
    800028f0:	f406                	sd	ra,40(sp)
    800028f2:	f022                	sd	s0,32(sp)
    800028f4:	ec26                	sd	s1,24(sp)
    800028f6:	e84a                	sd	s2,16(sp)
    800028f8:	e44e                	sd	s3,8(sp)
    800028fa:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028fc:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002900:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002904:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002908:	1004f793          	andi	a5,s1,256
    8000290c:	cb85                	beqz	a5,8000293c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000290e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002912:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002914:	ef85                	bnez	a5,8000294c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002916:	00000097          	auipc	ra,0x0
    8000291a:	e26080e7          	jalr	-474(ra) # 8000273c <devintr>
    8000291e:	cd1d                	beqz	a0,8000295c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002920:	4789                	li	a5,2
    80002922:	06f50a63          	beq	a0,a5,80002996 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002926:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000292a:	10049073          	csrw	sstatus,s1
}
    8000292e:	70a2                	ld	ra,40(sp)
    80002930:	7402                	ld	s0,32(sp)
    80002932:	64e2                	ld	s1,24(sp)
    80002934:	6942                	ld	s2,16(sp)
    80002936:	69a2                	ld	s3,8(sp)
    80002938:	6145                	addi	sp,sp,48
    8000293a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000293c:	00006517          	auipc	a0,0x6
    80002940:	a5450513          	addi	a0,a0,-1452 # 80008390 <states.0+0xc8>
    80002944:	ffffe097          	auipc	ra,0xffffe
    80002948:	bfa080e7          	jalr	-1030(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    8000294c:	00006517          	auipc	a0,0x6
    80002950:	a6c50513          	addi	a0,a0,-1428 # 800083b8 <states.0+0xf0>
    80002954:	ffffe097          	auipc	ra,0xffffe
    80002958:	bea080e7          	jalr	-1046(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    8000295c:	85ce                	mv	a1,s3
    8000295e:	00006517          	auipc	a0,0x6
    80002962:	a7a50513          	addi	a0,a0,-1414 # 800083d8 <states.0+0x110>
    80002966:	ffffe097          	auipc	ra,0xffffe
    8000296a:	c22080e7          	jalr	-990(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000296e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002972:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002976:	00006517          	auipc	a0,0x6
    8000297a:	a7250513          	addi	a0,a0,-1422 # 800083e8 <states.0+0x120>
    8000297e:	ffffe097          	auipc	ra,0xffffe
    80002982:	c0a080e7          	jalr	-1014(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002986:	00006517          	auipc	a0,0x6
    8000298a:	a7a50513          	addi	a0,a0,-1414 # 80008400 <states.0+0x138>
    8000298e:	ffffe097          	auipc	ra,0xffffe
    80002992:	bb0080e7          	jalr	-1104(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002996:	fffff097          	auipc	ra,0xfffff
    8000299a:	016080e7          	jalr	22(ra) # 800019ac <myproc>
    8000299e:	d541                	beqz	a0,80002926 <kerneltrap+0x38>
    800029a0:	fffff097          	auipc	ra,0xfffff
    800029a4:	00c080e7          	jalr	12(ra) # 800019ac <myproc>
    800029a8:	4d18                	lw	a4,24(a0)
    800029aa:	4791                	li	a5,4
    800029ac:	f6f71de3          	bne	a4,a5,80002926 <kerneltrap+0x38>
    yield();
    800029b0:	fffff097          	auipc	ra,0xfffff
    800029b4:	668080e7          	jalr	1640(ra) # 80002018 <yield>
    800029b8:	b7bd                	j	80002926 <kerneltrap+0x38>

00000000800029ba <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800029ba:	1101                	addi	sp,sp,-32
    800029bc:	ec06                	sd	ra,24(sp)
    800029be:	e822                	sd	s0,16(sp)
    800029c0:	e426                	sd	s1,8(sp)
    800029c2:	1000                	addi	s0,sp,32
    800029c4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029c6:	fffff097          	auipc	ra,0xfffff
    800029ca:	fe6080e7          	jalr	-26(ra) # 800019ac <myproc>
  switch (n) {
    800029ce:	4795                	li	a5,5
    800029d0:	0497e163          	bltu	a5,s1,80002a12 <argraw+0x58>
    800029d4:	048a                	slli	s1,s1,0x2
    800029d6:	00006717          	auipc	a4,0x6
    800029da:	a6270713          	addi	a4,a4,-1438 # 80008438 <states.0+0x170>
    800029de:	94ba                	add	s1,s1,a4
    800029e0:	409c                	lw	a5,0(s1)
    800029e2:	97ba                	add	a5,a5,a4
    800029e4:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800029e6:	6d3c                	ld	a5,88(a0)
    800029e8:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800029ea:	60e2                	ld	ra,24(sp)
    800029ec:	6442                	ld	s0,16(sp)
    800029ee:	64a2                	ld	s1,8(sp)
    800029f0:	6105                	addi	sp,sp,32
    800029f2:	8082                	ret
    return p->trapframe->a1;
    800029f4:	6d3c                	ld	a5,88(a0)
    800029f6:	7fa8                	ld	a0,120(a5)
    800029f8:	bfcd                	j	800029ea <argraw+0x30>
    return p->trapframe->a2;
    800029fa:	6d3c                	ld	a5,88(a0)
    800029fc:	63c8                	ld	a0,128(a5)
    800029fe:	b7f5                	j	800029ea <argraw+0x30>
    return p->trapframe->a3;
    80002a00:	6d3c                	ld	a5,88(a0)
    80002a02:	67c8                	ld	a0,136(a5)
    80002a04:	b7dd                	j	800029ea <argraw+0x30>
    return p->trapframe->a4;
    80002a06:	6d3c                	ld	a5,88(a0)
    80002a08:	6bc8                	ld	a0,144(a5)
    80002a0a:	b7c5                	j	800029ea <argraw+0x30>
    return p->trapframe->a5;
    80002a0c:	6d3c                	ld	a5,88(a0)
    80002a0e:	6fc8                	ld	a0,152(a5)
    80002a10:	bfe9                	j	800029ea <argraw+0x30>
  panic("argraw");
    80002a12:	00006517          	auipc	a0,0x6
    80002a16:	9fe50513          	addi	a0,a0,-1538 # 80008410 <states.0+0x148>
    80002a1a:	ffffe097          	auipc	ra,0xffffe
    80002a1e:	b24080e7          	jalr	-1244(ra) # 8000053e <panic>

0000000080002a22 <fetchaddr>:
{
    80002a22:	1101                	addi	sp,sp,-32
    80002a24:	ec06                	sd	ra,24(sp)
    80002a26:	e822                	sd	s0,16(sp)
    80002a28:	e426                	sd	s1,8(sp)
    80002a2a:	e04a                	sd	s2,0(sp)
    80002a2c:	1000                	addi	s0,sp,32
    80002a2e:	84aa                	mv	s1,a0
    80002a30:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a32:	fffff097          	auipc	ra,0xfffff
    80002a36:	f7a080e7          	jalr	-134(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002a3a:	653c                	ld	a5,72(a0)
    80002a3c:	02f4f863          	bgeu	s1,a5,80002a6c <fetchaddr+0x4a>
    80002a40:	00848713          	addi	a4,s1,8
    80002a44:	02e7e663          	bltu	a5,a4,80002a70 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a48:	46a1                	li	a3,8
    80002a4a:	8626                	mv	a2,s1
    80002a4c:	85ca                	mv	a1,s2
    80002a4e:	6928                	ld	a0,80(a0)
    80002a50:	fffff097          	auipc	ra,0xfffff
    80002a54:	ca4080e7          	jalr	-860(ra) # 800016f4 <copyin>
    80002a58:	00a03533          	snez	a0,a0
    80002a5c:	40a00533          	neg	a0,a0
}
    80002a60:	60e2                	ld	ra,24(sp)
    80002a62:	6442                	ld	s0,16(sp)
    80002a64:	64a2                	ld	s1,8(sp)
    80002a66:	6902                	ld	s2,0(sp)
    80002a68:	6105                	addi	sp,sp,32
    80002a6a:	8082                	ret
    return -1;
    80002a6c:	557d                	li	a0,-1
    80002a6e:	bfcd                	j	80002a60 <fetchaddr+0x3e>
    80002a70:	557d                	li	a0,-1
    80002a72:	b7fd                	j	80002a60 <fetchaddr+0x3e>

0000000080002a74 <fetchstr>:
{
    80002a74:	7179                	addi	sp,sp,-48
    80002a76:	f406                	sd	ra,40(sp)
    80002a78:	f022                	sd	s0,32(sp)
    80002a7a:	ec26                	sd	s1,24(sp)
    80002a7c:	e84a                	sd	s2,16(sp)
    80002a7e:	e44e                	sd	s3,8(sp)
    80002a80:	1800                	addi	s0,sp,48
    80002a82:	892a                	mv	s2,a0
    80002a84:	84ae                	mv	s1,a1
    80002a86:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a88:	fffff097          	auipc	ra,0xfffff
    80002a8c:	f24080e7          	jalr	-220(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002a90:	86ce                	mv	a3,s3
    80002a92:	864a                	mv	a2,s2
    80002a94:	85a6                	mv	a1,s1
    80002a96:	6928                	ld	a0,80(a0)
    80002a98:	fffff097          	auipc	ra,0xfffff
    80002a9c:	cea080e7          	jalr	-790(ra) # 80001782 <copyinstr>
    80002aa0:	00054e63          	bltz	a0,80002abc <fetchstr+0x48>
  return strlen(buf);
    80002aa4:	8526                	mv	a0,s1
    80002aa6:	ffffe097          	auipc	ra,0xffffe
    80002aaa:	3a8080e7          	jalr	936(ra) # 80000e4e <strlen>
}
    80002aae:	70a2                	ld	ra,40(sp)
    80002ab0:	7402                	ld	s0,32(sp)
    80002ab2:	64e2                	ld	s1,24(sp)
    80002ab4:	6942                	ld	s2,16(sp)
    80002ab6:	69a2                	ld	s3,8(sp)
    80002ab8:	6145                	addi	sp,sp,48
    80002aba:	8082                	ret
    return -1;
    80002abc:	557d                	li	a0,-1
    80002abe:	bfc5                	j	80002aae <fetchstr+0x3a>

0000000080002ac0 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002ac0:	1101                	addi	sp,sp,-32
    80002ac2:	ec06                	sd	ra,24(sp)
    80002ac4:	e822                	sd	s0,16(sp)
    80002ac6:	e426                	sd	s1,8(sp)
    80002ac8:	1000                	addi	s0,sp,32
    80002aca:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002acc:	00000097          	auipc	ra,0x0
    80002ad0:	eee080e7          	jalr	-274(ra) # 800029ba <argraw>
    80002ad4:	c088                	sw	a0,0(s1)
}
    80002ad6:	60e2                	ld	ra,24(sp)
    80002ad8:	6442                	ld	s0,16(sp)
    80002ada:	64a2                	ld	s1,8(sp)
    80002adc:	6105                	addi	sp,sp,32
    80002ade:	8082                	ret

0000000080002ae0 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002ae0:	1101                	addi	sp,sp,-32
    80002ae2:	ec06                	sd	ra,24(sp)
    80002ae4:	e822                	sd	s0,16(sp)
    80002ae6:	e426                	sd	s1,8(sp)
    80002ae8:	1000                	addi	s0,sp,32
    80002aea:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002aec:	00000097          	auipc	ra,0x0
    80002af0:	ece080e7          	jalr	-306(ra) # 800029ba <argraw>
    80002af4:	e088                	sd	a0,0(s1)
}
    80002af6:	60e2                	ld	ra,24(sp)
    80002af8:	6442                	ld	s0,16(sp)
    80002afa:	64a2                	ld	s1,8(sp)
    80002afc:	6105                	addi	sp,sp,32
    80002afe:	8082                	ret

0000000080002b00 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b00:	7179                	addi	sp,sp,-48
    80002b02:	f406                	sd	ra,40(sp)
    80002b04:	f022                	sd	s0,32(sp)
    80002b06:	ec26                	sd	s1,24(sp)
    80002b08:	e84a                	sd	s2,16(sp)
    80002b0a:	1800                	addi	s0,sp,48
    80002b0c:	84ae                	mv	s1,a1
    80002b0e:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002b10:	fd840593          	addi	a1,s0,-40
    80002b14:	00000097          	auipc	ra,0x0
    80002b18:	fcc080e7          	jalr	-52(ra) # 80002ae0 <argaddr>
  return fetchstr(addr, buf, max);
    80002b1c:	864a                	mv	a2,s2
    80002b1e:	85a6                	mv	a1,s1
    80002b20:	fd843503          	ld	a0,-40(s0)
    80002b24:	00000097          	auipc	ra,0x0
    80002b28:	f50080e7          	jalr	-176(ra) # 80002a74 <fetchstr>
}
    80002b2c:	70a2                	ld	ra,40(sp)
    80002b2e:	7402                	ld	s0,32(sp)
    80002b30:	64e2                	ld	s1,24(sp)
    80002b32:	6942                	ld	s2,16(sp)
    80002b34:	6145                	addi	sp,sp,48
    80002b36:	8082                	ret

0000000080002b38 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002b38:	1101                	addi	sp,sp,-32
    80002b3a:	ec06                	sd	ra,24(sp)
    80002b3c:	e822                	sd	s0,16(sp)
    80002b3e:	e426                	sd	s1,8(sp)
    80002b40:	e04a                	sd	s2,0(sp)
    80002b42:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b44:	fffff097          	auipc	ra,0xfffff
    80002b48:	e68080e7          	jalr	-408(ra) # 800019ac <myproc>
    80002b4c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b4e:	05853903          	ld	s2,88(a0)
    80002b52:	0a893783          	ld	a5,168(s2)
    80002b56:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b5a:	37fd                	addiw	a5,a5,-1
    80002b5c:	4751                	li	a4,20
    80002b5e:	00f76f63          	bltu	a4,a5,80002b7c <syscall+0x44>
    80002b62:	00369713          	slli	a4,a3,0x3
    80002b66:	00006797          	auipc	a5,0x6
    80002b6a:	8ea78793          	addi	a5,a5,-1814 # 80008450 <syscalls>
    80002b6e:	97ba                	add	a5,a5,a4
    80002b70:	639c                	ld	a5,0(a5)
    80002b72:	c789                	beqz	a5,80002b7c <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002b74:	9782                	jalr	a5
    80002b76:	06a93823          	sd	a0,112(s2)
    80002b7a:	a839                	j	80002b98 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b7c:	15848613          	addi	a2,s1,344
    80002b80:	588c                	lw	a1,48(s1)
    80002b82:	00006517          	auipc	a0,0x6
    80002b86:	89650513          	addi	a0,a0,-1898 # 80008418 <states.0+0x150>
    80002b8a:	ffffe097          	auipc	ra,0xffffe
    80002b8e:	9fe080e7          	jalr	-1538(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002b92:	6cbc                	ld	a5,88(s1)
    80002b94:	577d                	li	a4,-1
    80002b96:	fbb8                	sd	a4,112(a5)
  }
}
    80002b98:	60e2                	ld	ra,24(sp)
    80002b9a:	6442                	ld	s0,16(sp)
    80002b9c:	64a2                	ld	s1,8(sp)
    80002b9e:	6902                	ld	s2,0(sp)
    80002ba0:	6105                	addi	sp,sp,32
    80002ba2:	8082                	ret

0000000080002ba4 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ba4:	1101                	addi	sp,sp,-32
    80002ba6:	ec06                	sd	ra,24(sp)
    80002ba8:	e822                	sd	s0,16(sp)
    80002baa:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002bac:	fec40593          	addi	a1,s0,-20
    80002bb0:	4501                	li	a0,0
    80002bb2:	00000097          	auipc	ra,0x0
    80002bb6:	f0e080e7          	jalr	-242(ra) # 80002ac0 <argint>
  exit(n);
    80002bba:	fec42503          	lw	a0,-20(s0)
    80002bbe:	fffff097          	auipc	ra,0xfffff
    80002bc2:	5ca080e7          	jalr	1482(ra) # 80002188 <exit>
  return 0;  // not reached
}
    80002bc6:	4501                	li	a0,0
    80002bc8:	60e2                	ld	ra,24(sp)
    80002bca:	6442                	ld	s0,16(sp)
    80002bcc:	6105                	addi	sp,sp,32
    80002bce:	8082                	ret

0000000080002bd0 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002bd0:	1141                	addi	sp,sp,-16
    80002bd2:	e406                	sd	ra,8(sp)
    80002bd4:	e022                	sd	s0,0(sp)
    80002bd6:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002bd8:	fffff097          	auipc	ra,0xfffff
    80002bdc:	dd4080e7          	jalr	-556(ra) # 800019ac <myproc>
}
    80002be0:	5908                	lw	a0,48(a0)
    80002be2:	60a2                	ld	ra,8(sp)
    80002be4:	6402                	ld	s0,0(sp)
    80002be6:	0141                	addi	sp,sp,16
    80002be8:	8082                	ret

0000000080002bea <sys_fork>:

uint64
sys_fork(void)
{
    80002bea:	1141                	addi	sp,sp,-16
    80002bec:	e406                	sd	ra,8(sp)
    80002bee:	e022                	sd	s0,0(sp)
    80002bf0:	0800                	addi	s0,sp,16
  return fork();
    80002bf2:	fffff097          	auipc	ra,0xfffff
    80002bf6:	170080e7          	jalr	368(ra) # 80001d62 <fork>
}
    80002bfa:	60a2                	ld	ra,8(sp)
    80002bfc:	6402                	ld	s0,0(sp)
    80002bfe:	0141                	addi	sp,sp,16
    80002c00:	8082                	ret

0000000080002c02 <sys_wait>:

uint64
sys_wait(void)
{
    80002c02:	1101                	addi	sp,sp,-32
    80002c04:	ec06                	sd	ra,24(sp)
    80002c06:	e822                	sd	s0,16(sp)
    80002c08:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002c0a:	fe840593          	addi	a1,s0,-24
    80002c0e:	4501                	li	a0,0
    80002c10:	00000097          	auipc	ra,0x0
    80002c14:	ed0080e7          	jalr	-304(ra) # 80002ae0 <argaddr>
  return wait(p);
    80002c18:	fe843503          	ld	a0,-24(s0)
    80002c1c:	fffff097          	auipc	ra,0xfffff
    80002c20:	712080e7          	jalr	1810(ra) # 8000232e <wait>
}
    80002c24:	60e2                	ld	ra,24(sp)
    80002c26:	6442                	ld	s0,16(sp)
    80002c28:	6105                	addi	sp,sp,32
    80002c2a:	8082                	ret

0000000080002c2c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c2c:	7179                	addi	sp,sp,-48
    80002c2e:	f406                	sd	ra,40(sp)
    80002c30:	f022                	sd	s0,32(sp)
    80002c32:	ec26                	sd	s1,24(sp)
    80002c34:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002c36:	fdc40593          	addi	a1,s0,-36
    80002c3a:	4501                	li	a0,0
    80002c3c:	00000097          	auipc	ra,0x0
    80002c40:	e84080e7          	jalr	-380(ra) # 80002ac0 <argint>
  addr = myproc()->sz;
    80002c44:	fffff097          	auipc	ra,0xfffff
    80002c48:	d68080e7          	jalr	-664(ra) # 800019ac <myproc>
    80002c4c:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002c4e:	fdc42503          	lw	a0,-36(s0)
    80002c52:	fffff097          	auipc	ra,0xfffff
    80002c56:	0b4080e7          	jalr	180(ra) # 80001d06 <growproc>
    80002c5a:	00054863          	bltz	a0,80002c6a <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002c5e:	8526                	mv	a0,s1
    80002c60:	70a2                	ld	ra,40(sp)
    80002c62:	7402                	ld	s0,32(sp)
    80002c64:	64e2                	ld	s1,24(sp)
    80002c66:	6145                	addi	sp,sp,48
    80002c68:	8082                	ret
    return -1;
    80002c6a:	54fd                	li	s1,-1
    80002c6c:	bfcd                	j	80002c5e <sys_sbrk+0x32>

0000000080002c6e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c6e:	7139                	addi	sp,sp,-64
    80002c70:	fc06                	sd	ra,56(sp)
    80002c72:	f822                	sd	s0,48(sp)
    80002c74:	f426                	sd	s1,40(sp)
    80002c76:	f04a                	sd	s2,32(sp)
    80002c78:	ec4e                	sd	s3,24(sp)
    80002c7a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002c7c:	fcc40593          	addi	a1,s0,-52
    80002c80:	4501                	li	a0,0
    80002c82:	00000097          	auipc	ra,0x0
    80002c86:	e3e080e7          	jalr	-450(ra) # 80002ac0 <argint>
  acquire(&tickslock);
    80002c8a:	00014517          	auipc	a0,0x14
    80002c8e:	f3650513          	addi	a0,a0,-202 # 80016bc0 <tickslock>
    80002c92:	ffffe097          	auipc	ra,0xffffe
    80002c96:	f44080e7          	jalr	-188(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002c9a:	00006917          	auipc	s2,0x6
    80002c9e:	c8692903          	lw	s2,-890(s2) # 80008920 <ticks>
  while(ticks - ticks0 < n){
    80002ca2:	fcc42783          	lw	a5,-52(s0)
    80002ca6:	cf9d                	beqz	a5,80002ce4 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ca8:	00014997          	auipc	s3,0x14
    80002cac:	f1898993          	addi	s3,s3,-232 # 80016bc0 <tickslock>
    80002cb0:	00006497          	auipc	s1,0x6
    80002cb4:	c7048493          	addi	s1,s1,-912 # 80008920 <ticks>
    if(killed(myproc())){
    80002cb8:	fffff097          	auipc	ra,0xfffff
    80002cbc:	cf4080e7          	jalr	-780(ra) # 800019ac <myproc>
    80002cc0:	fffff097          	auipc	ra,0xfffff
    80002cc4:	63c080e7          	jalr	1596(ra) # 800022fc <killed>
    80002cc8:	ed15                	bnez	a0,80002d04 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002cca:	85ce                	mv	a1,s3
    80002ccc:	8526                	mv	a0,s1
    80002cce:	fffff097          	auipc	ra,0xfffff
    80002cd2:	386080e7          	jalr	902(ra) # 80002054 <sleep>
  while(ticks - ticks0 < n){
    80002cd6:	409c                	lw	a5,0(s1)
    80002cd8:	412787bb          	subw	a5,a5,s2
    80002cdc:	fcc42703          	lw	a4,-52(s0)
    80002ce0:	fce7ece3          	bltu	a5,a4,80002cb8 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002ce4:	00014517          	auipc	a0,0x14
    80002ce8:	edc50513          	addi	a0,a0,-292 # 80016bc0 <tickslock>
    80002cec:	ffffe097          	auipc	ra,0xffffe
    80002cf0:	f9e080e7          	jalr	-98(ra) # 80000c8a <release>
  return 0;
    80002cf4:	4501                	li	a0,0
}
    80002cf6:	70e2                	ld	ra,56(sp)
    80002cf8:	7442                	ld	s0,48(sp)
    80002cfa:	74a2                	ld	s1,40(sp)
    80002cfc:	7902                	ld	s2,32(sp)
    80002cfe:	69e2                	ld	s3,24(sp)
    80002d00:	6121                	addi	sp,sp,64
    80002d02:	8082                	ret
      release(&tickslock);
    80002d04:	00014517          	auipc	a0,0x14
    80002d08:	ebc50513          	addi	a0,a0,-324 # 80016bc0 <tickslock>
    80002d0c:	ffffe097          	auipc	ra,0xffffe
    80002d10:	f7e080e7          	jalr	-130(ra) # 80000c8a <release>
      return -1;
    80002d14:	557d                	li	a0,-1
    80002d16:	b7c5                	j	80002cf6 <sys_sleep+0x88>

0000000080002d18 <sys_kill>:

uint64
sys_kill(void)
{
    80002d18:	1101                	addi	sp,sp,-32
    80002d1a:	ec06                	sd	ra,24(sp)
    80002d1c:	e822                	sd	s0,16(sp)
    80002d1e:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002d20:	fec40593          	addi	a1,s0,-20
    80002d24:	4501                	li	a0,0
    80002d26:	00000097          	auipc	ra,0x0
    80002d2a:	d9a080e7          	jalr	-614(ra) # 80002ac0 <argint>
  return kill(pid);
    80002d2e:	fec42503          	lw	a0,-20(s0)
    80002d32:	fffff097          	auipc	ra,0xfffff
    80002d36:	52c080e7          	jalr	1324(ra) # 8000225e <kill>
}
    80002d3a:	60e2                	ld	ra,24(sp)
    80002d3c:	6442                	ld	s0,16(sp)
    80002d3e:	6105                	addi	sp,sp,32
    80002d40:	8082                	ret

0000000080002d42 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d42:	1101                	addi	sp,sp,-32
    80002d44:	ec06                	sd	ra,24(sp)
    80002d46:	e822                	sd	s0,16(sp)
    80002d48:	e426                	sd	s1,8(sp)
    80002d4a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d4c:	00014517          	auipc	a0,0x14
    80002d50:	e7450513          	addi	a0,a0,-396 # 80016bc0 <tickslock>
    80002d54:	ffffe097          	auipc	ra,0xffffe
    80002d58:	e82080e7          	jalr	-382(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002d5c:	00006497          	auipc	s1,0x6
    80002d60:	bc44a483          	lw	s1,-1084(s1) # 80008920 <ticks>
  release(&tickslock);
    80002d64:	00014517          	auipc	a0,0x14
    80002d68:	e5c50513          	addi	a0,a0,-420 # 80016bc0 <tickslock>
    80002d6c:	ffffe097          	auipc	ra,0xffffe
    80002d70:	f1e080e7          	jalr	-226(ra) # 80000c8a <release>
  return xticks;
}
    80002d74:	02049513          	slli	a0,s1,0x20
    80002d78:	9101                	srli	a0,a0,0x20
    80002d7a:	60e2                	ld	ra,24(sp)
    80002d7c:	6442                	ld	s0,16(sp)
    80002d7e:	64a2                	ld	s1,8(sp)
    80002d80:	6105                	addi	sp,sp,32
    80002d82:	8082                	ret

0000000080002d84 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002d84:	7179                	addi	sp,sp,-48
    80002d86:	f406                	sd	ra,40(sp)
    80002d88:	f022                	sd	s0,32(sp)
    80002d8a:	ec26                	sd	s1,24(sp)
    80002d8c:	e84a                	sd	s2,16(sp)
    80002d8e:	e44e                	sd	s3,8(sp)
    80002d90:	e052                	sd	s4,0(sp)
    80002d92:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002d94:	00005597          	auipc	a1,0x5
    80002d98:	76c58593          	addi	a1,a1,1900 # 80008500 <syscalls+0xb0>
    80002d9c:	00014517          	auipc	a0,0x14
    80002da0:	e3c50513          	addi	a0,a0,-452 # 80016bd8 <bcache>
    80002da4:	ffffe097          	auipc	ra,0xffffe
    80002da8:	da2080e7          	jalr	-606(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002dac:	0001c797          	auipc	a5,0x1c
    80002db0:	e2c78793          	addi	a5,a5,-468 # 8001ebd8 <bcache+0x8000>
    80002db4:	0001c717          	auipc	a4,0x1c
    80002db8:	08c70713          	addi	a4,a4,140 # 8001ee40 <bcache+0x8268>
    80002dbc:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002dc0:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002dc4:	00014497          	auipc	s1,0x14
    80002dc8:	e2c48493          	addi	s1,s1,-468 # 80016bf0 <bcache+0x18>
    b->next = bcache.head.next;
    80002dcc:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002dce:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002dd0:	00005a17          	auipc	s4,0x5
    80002dd4:	738a0a13          	addi	s4,s4,1848 # 80008508 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002dd8:	2b893783          	ld	a5,696(s2)
    80002ddc:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002dde:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002de2:	85d2                	mv	a1,s4
    80002de4:	01048513          	addi	a0,s1,16
    80002de8:	00001097          	auipc	ra,0x1
    80002dec:	7d6080e7          	jalr	2006(ra) # 800045be <initsleeplock>
    bcache.head.next->prev = b;
    80002df0:	2b893783          	ld	a5,696(s2)
    80002df4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002df6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002dfa:	45848493          	addi	s1,s1,1112
    80002dfe:	fd349de3          	bne	s1,s3,80002dd8 <binit+0x54>
  }
}
    80002e02:	70a2                	ld	ra,40(sp)
    80002e04:	7402                	ld	s0,32(sp)
    80002e06:	64e2                	ld	s1,24(sp)
    80002e08:	6942                	ld	s2,16(sp)
    80002e0a:	69a2                	ld	s3,8(sp)
    80002e0c:	6a02                	ld	s4,0(sp)
    80002e0e:	6145                	addi	sp,sp,48
    80002e10:	8082                	ret

0000000080002e12 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e12:	7179                	addi	sp,sp,-48
    80002e14:	f406                	sd	ra,40(sp)
    80002e16:	f022                	sd	s0,32(sp)
    80002e18:	ec26                	sd	s1,24(sp)
    80002e1a:	e84a                	sd	s2,16(sp)
    80002e1c:	e44e                	sd	s3,8(sp)
    80002e1e:	1800                	addi	s0,sp,48
    80002e20:	892a                	mv	s2,a0
    80002e22:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002e24:	00014517          	auipc	a0,0x14
    80002e28:	db450513          	addi	a0,a0,-588 # 80016bd8 <bcache>
    80002e2c:	ffffe097          	auipc	ra,0xffffe
    80002e30:	daa080e7          	jalr	-598(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e34:	0001c497          	auipc	s1,0x1c
    80002e38:	05c4b483          	ld	s1,92(s1) # 8001ee90 <bcache+0x82b8>
    80002e3c:	0001c797          	auipc	a5,0x1c
    80002e40:	00478793          	addi	a5,a5,4 # 8001ee40 <bcache+0x8268>
    80002e44:	02f48f63          	beq	s1,a5,80002e82 <bread+0x70>
    80002e48:	873e                	mv	a4,a5
    80002e4a:	a021                	j	80002e52 <bread+0x40>
    80002e4c:	68a4                	ld	s1,80(s1)
    80002e4e:	02e48a63          	beq	s1,a4,80002e82 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e52:	449c                	lw	a5,8(s1)
    80002e54:	ff279ce3          	bne	a5,s2,80002e4c <bread+0x3a>
    80002e58:	44dc                	lw	a5,12(s1)
    80002e5a:	ff3799e3          	bne	a5,s3,80002e4c <bread+0x3a>
      b->refcnt++;
    80002e5e:	40bc                	lw	a5,64(s1)
    80002e60:	2785                	addiw	a5,a5,1
    80002e62:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e64:	00014517          	auipc	a0,0x14
    80002e68:	d7450513          	addi	a0,a0,-652 # 80016bd8 <bcache>
    80002e6c:	ffffe097          	auipc	ra,0xffffe
    80002e70:	e1e080e7          	jalr	-482(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002e74:	01048513          	addi	a0,s1,16
    80002e78:	00001097          	auipc	ra,0x1
    80002e7c:	780080e7          	jalr	1920(ra) # 800045f8 <acquiresleep>
      return b;
    80002e80:	a8b9                	j	80002ede <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e82:	0001c497          	auipc	s1,0x1c
    80002e86:	0064b483          	ld	s1,6(s1) # 8001ee88 <bcache+0x82b0>
    80002e8a:	0001c797          	auipc	a5,0x1c
    80002e8e:	fb678793          	addi	a5,a5,-74 # 8001ee40 <bcache+0x8268>
    80002e92:	00f48863          	beq	s1,a5,80002ea2 <bread+0x90>
    80002e96:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002e98:	40bc                	lw	a5,64(s1)
    80002e9a:	cf81                	beqz	a5,80002eb2 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e9c:	64a4                	ld	s1,72(s1)
    80002e9e:	fee49de3          	bne	s1,a4,80002e98 <bread+0x86>
  panic("bget: no buffers");
    80002ea2:	00005517          	auipc	a0,0x5
    80002ea6:	66e50513          	addi	a0,a0,1646 # 80008510 <syscalls+0xc0>
    80002eaa:	ffffd097          	auipc	ra,0xffffd
    80002eae:	694080e7          	jalr	1684(ra) # 8000053e <panic>
      b->dev = dev;
    80002eb2:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002eb6:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002eba:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002ebe:	4785                	li	a5,1
    80002ec0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ec2:	00014517          	auipc	a0,0x14
    80002ec6:	d1650513          	addi	a0,a0,-746 # 80016bd8 <bcache>
    80002eca:	ffffe097          	auipc	ra,0xffffe
    80002ece:	dc0080e7          	jalr	-576(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002ed2:	01048513          	addi	a0,s1,16
    80002ed6:	00001097          	auipc	ra,0x1
    80002eda:	722080e7          	jalr	1826(ra) # 800045f8 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002ede:	409c                	lw	a5,0(s1)
    80002ee0:	cb89                	beqz	a5,80002ef2 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002ee2:	8526                	mv	a0,s1
    80002ee4:	70a2                	ld	ra,40(sp)
    80002ee6:	7402                	ld	s0,32(sp)
    80002ee8:	64e2                	ld	s1,24(sp)
    80002eea:	6942                	ld	s2,16(sp)
    80002eec:	69a2                	ld	s3,8(sp)
    80002eee:	6145                	addi	sp,sp,48
    80002ef0:	8082                	ret
    virtio_disk_rw(b, 0);
    80002ef2:	4581                	li	a1,0
    80002ef4:	8526                	mv	a0,s1
    80002ef6:	00003097          	auipc	ra,0x3
    80002efa:	4fe080e7          	jalr	1278(ra) # 800063f4 <virtio_disk_rw>
    b->valid = 1;
    80002efe:	4785                	li	a5,1
    80002f00:	c09c                	sw	a5,0(s1)
  return b;
    80002f02:	b7c5                	j	80002ee2 <bread+0xd0>

0000000080002f04 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f04:	1101                	addi	sp,sp,-32
    80002f06:	ec06                	sd	ra,24(sp)
    80002f08:	e822                	sd	s0,16(sp)
    80002f0a:	e426                	sd	s1,8(sp)
    80002f0c:	1000                	addi	s0,sp,32
    80002f0e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f10:	0541                	addi	a0,a0,16
    80002f12:	00001097          	auipc	ra,0x1
    80002f16:	780080e7          	jalr	1920(ra) # 80004692 <holdingsleep>
    80002f1a:	cd01                	beqz	a0,80002f32 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002f1c:	4585                	li	a1,1
    80002f1e:	8526                	mv	a0,s1
    80002f20:	00003097          	auipc	ra,0x3
    80002f24:	4d4080e7          	jalr	1236(ra) # 800063f4 <virtio_disk_rw>
}
    80002f28:	60e2                	ld	ra,24(sp)
    80002f2a:	6442                	ld	s0,16(sp)
    80002f2c:	64a2                	ld	s1,8(sp)
    80002f2e:	6105                	addi	sp,sp,32
    80002f30:	8082                	ret
    panic("bwrite");
    80002f32:	00005517          	auipc	a0,0x5
    80002f36:	5f650513          	addi	a0,a0,1526 # 80008528 <syscalls+0xd8>
    80002f3a:	ffffd097          	auipc	ra,0xffffd
    80002f3e:	604080e7          	jalr	1540(ra) # 8000053e <panic>

0000000080002f42 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f42:	1101                	addi	sp,sp,-32
    80002f44:	ec06                	sd	ra,24(sp)
    80002f46:	e822                	sd	s0,16(sp)
    80002f48:	e426                	sd	s1,8(sp)
    80002f4a:	e04a                	sd	s2,0(sp)
    80002f4c:	1000                	addi	s0,sp,32
    80002f4e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f50:	01050913          	addi	s2,a0,16
    80002f54:	854a                	mv	a0,s2
    80002f56:	00001097          	auipc	ra,0x1
    80002f5a:	73c080e7          	jalr	1852(ra) # 80004692 <holdingsleep>
    80002f5e:	c92d                	beqz	a0,80002fd0 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002f60:	854a                	mv	a0,s2
    80002f62:	00001097          	auipc	ra,0x1
    80002f66:	6ec080e7          	jalr	1772(ra) # 8000464e <releasesleep>

  acquire(&bcache.lock);
    80002f6a:	00014517          	auipc	a0,0x14
    80002f6e:	c6e50513          	addi	a0,a0,-914 # 80016bd8 <bcache>
    80002f72:	ffffe097          	auipc	ra,0xffffe
    80002f76:	c64080e7          	jalr	-924(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80002f7a:	40bc                	lw	a5,64(s1)
    80002f7c:	37fd                	addiw	a5,a5,-1
    80002f7e:	0007871b          	sext.w	a4,a5
    80002f82:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002f84:	eb05                	bnez	a4,80002fb4 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002f86:	68bc                	ld	a5,80(s1)
    80002f88:	64b8                	ld	a4,72(s1)
    80002f8a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002f8c:	64bc                	ld	a5,72(s1)
    80002f8e:	68b8                	ld	a4,80(s1)
    80002f90:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002f92:	0001c797          	auipc	a5,0x1c
    80002f96:	c4678793          	addi	a5,a5,-954 # 8001ebd8 <bcache+0x8000>
    80002f9a:	2b87b703          	ld	a4,696(a5)
    80002f9e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002fa0:	0001c717          	auipc	a4,0x1c
    80002fa4:	ea070713          	addi	a4,a4,-352 # 8001ee40 <bcache+0x8268>
    80002fa8:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002faa:	2b87b703          	ld	a4,696(a5)
    80002fae:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002fb0:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002fb4:	00014517          	auipc	a0,0x14
    80002fb8:	c2450513          	addi	a0,a0,-988 # 80016bd8 <bcache>
    80002fbc:	ffffe097          	auipc	ra,0xffffe
    80002fc0:	cce080e7          	jalr	-818(ra) # 80000c8a <release>
}
    80002fc4:	60e2                	ld	ra,24(sp)
    80002fc6:	6442                	ld	s0,16(sp)
    80002fc8:	64a2                	ld	s1,8(sp)
    80002fca:	6902                	ld	s2,0(sp)
    80002fcc:	6105                	addi	sp,sp,32
    80002fce:	8082                	ret
    panic("brelse");
    80002fd0:	00005517          	auipc	a0,0x5
    80002fd4:	56050513          	addi	a0,a0,1376 # 80008530 <syscalls+0xe0>
    80002fd8:	ffffd097          	auipc	ra,0xffffd
    80002fdc:	566080e7          	jalr	1382(ra) # 8000053e <panic>

0000000080002fe0 <bpin>:

void
bpin(struct buf *b) {
    80002fe0:	1101                	addi	sp,sp,-32
    80002fe2:	ec06                	sd	ra,24(sp)
    80002fe4:	e822                	sd	s0,16(sp)
    80002fe6:	e426                	sd	s1,8(sp)
    80002fe8:	1000                	addi	s0,sp,32
    80002fea:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002fec:	00014517          	auipc	a0,0x14
    80002ff0:	bec50513          	addi	a0,a0,-1044 # 80016bd8 <bcache>
    80002ff4:	ffffe097          	auipc	ra,0xffffe
    80002ff8:	be2080e7          	jalr	-1054(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80002ffc:	40bc                	lw	a5,64(s1)
    80002ffe:	2785                	addiw	a5,a5,1
    80003000:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003002:	00014517          	auipc	a0,0x14
    80003006:	bd650513          	addi	a0,a0,-1066 # 80016bd8 <bcache>
    8000300a:	ffffe097          	auipc	ra,0xffffe
    8000300e:	c80080e7          	jalr	-896(ra) # 80000c8a <release>
}
    80003012:	60e2                	ld	ra,24(sp)
    80003014:	6442                	ld	s0,16(sp)
    80003016:	64a2                	ld	s1,8(sp)
    80003018:	6105                	addi	sp,sp,32
    8000301a:	8082                	ret

000000008000301c <bunpin>:

void
bunpin(struct buf *b) {
    8000301c:	1101                	addi	sp,sp,-32
    8000301e:	ec06                	sd	ra,24(sp)
    80003020:	e822                	sd	s0,16(sp)
    80003022:	e426                	sd	s1,8(sp)
    80003024:	1000                	addi	s0,sp,32
    80003026:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003028:	00014517          	auipc	a0,0x14
    8000302c:	bb050513          	addi	a0,a0,-1104 # 80016bd8 <bcache>
    80003030:	ffffe097          	auipc	ra,0xffffe
    80003034:	ba6080e7          	jalr	-1114(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003038:	40bc                	lw	a5,64(s1)
    8000303a:	37fd                	addiw	a5,a5,-1
    8000303c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000303e:	00014517          	auipc	a0,0x14
    80003042:	b9a50513          	addi	a0,a0,-1126 # 80016bd8 <bcache>
    80003046:	ffffe097          	auipc	ra,0xffffe
    8000304a:	c44080e7          	jalr	-956(ra) # 80000c8a <release>
}
    8000304e:	60e2                	ld	ra,24(sp)
    80003050:	6442                	ld	s0,16(sp)
    80003052:	64a2                	ld	s1,8(sp)
    80003054:	6105                	addi	sp,sp,32
    80003056:	8082                	ret

0000000080003058 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003058:	1101                	addi	sp,sp,-32
    8000305a:	ec06                	sd	ra,24(sp)
    8000305c:	e822                	sd	s0,16(sp)
    8000305e:	e426                	sd	s1,8(sp)
    80003060:	e04a                	sd	s2,0(sp)
    80003062:	1000                	addi	s0,sp,32
    80003064:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003066:	00d5d59b          	srliw	a1,a1,0xd
    8000306a:	0001c797          	auipc	a5,0x1c
    8000306e:	24a7a783          	lw	a5,586(a5) # 8001f2b4 <sb+0x1c>
    80003072:	9dbd                	addw	a1,a1,a5
    80003074:	00000097          	auipc	ra,0x0
    80003078:	d9e080e7          	jalr	-610(ra) # 80002e12 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000307c:	0074f713          	andi	a4,s1,7
    80003080:	4785                	li	a5,1
    80003082:	00e797bb          	sllw	a5,a5,a4
  if ((bp->data[bi / 8] & m) == 0)
    80003086:	14ce                	slli	s1,s1,0x33
    80003088:	90d9                	srli	s1,s1,0x36
    8000308a:	00950733          	add	a4,a0,s1
    8000308e:	05874703          	lbu	a4,88(a4)
    80003092:	00e7f6b3          	and	a3,a5,a4
    80003096:	c69d                	beqz	a3,800030c4 <bfree+0x6c>
    80003098:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi / 8] &= ~m;
    8000309a:	94aa                	add	s1,s1,a0
    8000309c:	fff7c793          	not	a5,a5
    800030a0:	8ff9                	and	a5,a5,a4
    800030a2:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800030a6:	00001097          	auipc	ra,0x1
    800030aa:	432080e7          	jalr	1074(ra) # 800044d8 <log_write>
  brelse(bp);
    800030ae:	854a                	mv	a0,s2
    800030b0:	00000097          	auipc	ra,0x0
    800030b4:	e92080e7          	jalr	-366(ra) # 80002f42 <brelse>
}
    800030b8:	60e2                	ld	ra,24(sp)
    800030ba:	6442                	ld	s0,16(sp)
    800030bc:	64a2                	ld	s1,8(sp)
    800030be:	6902                	ld	s2,0(sp)
    800030c0:	6105                	addi	sp,sp,32
    800030c2:	8082                	ret
    panic("freeing free block");
    800030c4:	00005517          	auipc	a0,0x5
    800030c8:	47450513          	addi	a0,a0,1140 # 80008538 <syscalls+0xe8>
    800030cc:	ffffd097          	auipc	ra,0xffffd
    800030d0:	472080e7          	jalr	1138(ra) # 8000053e <panic>

00000000800030d4 <balloc>:
{
    800030d4:	711d                	addi	sp,sp,-96
    800030d6:	ec86                	sd	ra,88(sp)
    800030d8:	e8a2                	sd	s0,80(sp)
    800030da:	e4a6                	sd	s1,72(sp)
    800030dc:	e0ca                	sd	s2,64(sp)
    800030de:	fc4e                	sd	s3,56(sp)
    800030e0:	f852                	sd	s4,48(sp)
    800030e2:	f456                	sd	s5,40(sp)
    800030e4:	f05a                	sd	s6,32(sp)
    800030e6:	ec5e                	sd	s7,24(sp)
    800030e8:	e862                	sd	s8,16(sp)
    800030ea:	e466                	sd	s9,8(sp)
    800030ec:	1080                	addi	s0,sp,96
  for (b = 0; b < sb.size; b += BPB)
    800030ee:	0001c797          	auipc	a5,0x1c
    800030f2:	1ae7a783          	lw	a5,430(a5) # 8001f29c <sb+0x4>
    800030f6:	10078163          	beqz	a5,800031f8 <balloc+0x124>
    800030fa:	8baa                	mv	s7,a0
    800030fc:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800030fe:	0001cb17          	auipc	s6,0x1c
    80003102:	19ab0b13          	addi	s6,s6,410 # 8001f298 <sb>
    for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    80003106:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003108:	4985                	li	s3,1
    for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    8000310a:	6a09                	lui	s4,0x2
  for (b = 0; b < sb.size; b += BPB)
    8000310c:	6c89                	lui	s9,0x2
    8000310e:	a061                	j	80003196 <balloc+0xc2>
        bp->data[bi / 8] |= m; // Mark block in use.
    80003110:	974a                	add	a4,a4,s2
    80003112:	8fd5                	or	a5,a5,a3
    80003114:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003118:	854a                	mv	a0,s2
    8000311a:	00001097          	auipc	ra,0x1
    8000311e:	3be080e7          	jalr	958(ra) # 800044d8 <log_write>
        brelse(bp);
    80003122:	854a                	mv	a0,s2
    80003124:	00000097          	auipc	ra,0x0
    80003128:	e1e080e7          	jalr	-482(ra) # 80002f42 <brelse>
  bp = bread(dev, bno);
    8000312c:	85a6                	mv	a1,s1
    8000312e:	855e                	mv	a0,s7
    80003130:	00000097          	auipc	ra,0x0
    80003134:	ce2080e7          	jalr	-798(ra) # 80002e12 <bread>
    80003138:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000313a:	40000613          	li	a2,1024
    8000313e:	4581                	li	a1,0
    80003140:	05850513          	addi	a0,a0,88
    80003144:	ffffe097          	auipc	ra,0xffffe
    80003148:	b8e080e7          	jalr	-1138(ra) # 80000cd2 <memset>
  log_write(bp);
    8000314c:	854a                	mv	a0,s2
    8000314e:	00001097          	auipc	ra,0x1
    80003152:	38a080e7          	jalr	906(ra) # 800044d8 <log_write>
  brelse(bp);
    80003156:	854a                	mv	a0,s2
    80003158:	00000097          	auipc	ra,0x0
    8000315c:	dea080e7          	jalr	-534(ra) # 80002f42 <brelse>
}
    80003160:	8526                	mv	a0,s1
    80003162:	60e6                	ld	ra,88(sp)
    80003164:	6446                	ld	s0,80(sp)
    80003166:	64a6                	ld	s1,72(sp)
    80003168:	6906                	ld	s2,64(sp)
    8000316a:	79e2                	ld	s3,56(sp)
    8000316c:	7a42                	ld	s4,48(sp)
    8000316e:	7aa2                	ld	s5,40(sp)
    80003170:	7b02                	ld	s6,32(sp)
    80003172:	6be2                	ld	s7,24(sp)
    80003174:	6c42                	ld	s8,16(sp)
    80003176:	6ca2                	ld	s9,8(sp)
    80003178:	6125                	addi	sp,sp,96
    8000317a:	8082                	ret
    brelse(bp);
    8000317c:	854a                	mv	a0,s2
    8000317e:	00000097          	auipc	ra,0x0
    80003182:	dc4080e7          	jalr	-572(ra) # 80002f42 <brelse>
  for (b = 0; b < sb.size; b += BPB)
    80003186:	015c87bb          	addw	a5,s9,s5
    8000318a:	00078a9b          	sext.w	s5,a5
    8000318e:	004b2703          	lw	a4,4(s6)
    80003192:	06eaf363          	bgeu	s5,a4,800031f8 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003196:	41fad79b          	sraiw	a5,s5,0x1f
    8000319a:	0137d79b          	srliw	a5,a5,0x13
    8000319e:	015787bb          	addw	a5,a5,s5
    800031a2:	40d7d79b          	sraiw	a5,a5,0xd
    800031a6:	01cb2583          	lw	a1,28(s6)
    800031aa:	9dbd                	addw	a1,a1,a5
    800031ac:	855e                	mv	a0,s7
    800031ae:	00000097          	auipc	ra,0x0
    800031b2:	c64080e7          	jalr	-924(ra) # 80002e12 <bread>
    800031b6:	892a                	mv	s2,a0
    for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    800031b8:	004b2503          	lw	a0,4(s6)
    800031bc:	000a849b          	sext.w	s1,s5
    800031c0:	8662                	mv	a2,s8
    800031c2:	faa4fde3          	bgeu	s1,a0,8000317c <balloc+0xa8>
      m = 1 << (bi % 8);
    800031c6:	41f6579b          	sraiw	a5,a2,0x1f
    800031ca:	01d7d69b          	srliw	a3,a5,0x1d
    800031ce:	00c6873b          	addw	a4,a3,a2
    800031d2:	00777793          	andi	a5,a4,7
    800031d6:	9f95                	subw	a5,a5,a3
    800031d8:	00f997bb          	sllw	a5,s3,a5
      if ((bp->data[bi / 8] & m) == 0)
    800031dc:	4037571b          	sraiw	a4,a4,0x3
    800031e0:	00e906b3          	add	a3,s2,a4
    800031e4:	0586c683          	lbu	a3,88(a3)
    800031e8:	00d7f5b3          	and	a1,a5,a3
    800031ec:	d195                	beqz	a1,80003110 <balloc+0x3c>
    for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    800031ee:	2605                	addiw	a2,a2,1
    800031f0:	2485                	addiw	s1,s1,1
    800031f2:	fd4618e3          	bne	a2,s4,800031c2 <balloc+0xee>
    800031f6:	b759                	j	8000317c <balloc+0xa8>
  printf("balloc: out of blocks\n");
    800031f8:	00005517          	auipc	a0,0x5
    800031fc:	35850513          	addi	a0,a0,856 # 80008550 <syscalls+0x100>
    80003200:	ffffd097          	auipc	ra,0xffffd
    80003204:	388080e7          	jalr	904(ra) # 80000588 <printf>
  return 0;
    80003208:	4481                	li	s1,0
    8000320a:	bf99                	j	80003160 <balloc+0x8c>

000000008000320c <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000320c:	7179                	addi	sp,sp,-48
    8000320e:	f406                	sd	ra,40(sp)
    80003210:	f022                	sd	s0,32(sp)
    80003212:	ec26                	sd	s1,24(sp)
    80003214:	e84a                	sd	s2,16(sp)
    80003216:	e44e                	sd	s3,8(sp)
    80003218:	e052                	sd	s4,0(sp)
    8000321a:	1800                	addi	s0,sp,48
    8000321c:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if (bn < NDIRECT)
    8000321e:	47ad                	li	a5,11
    80003220:	02b7e763          	bltu	a5,a1,8000324e <bmap+0x42>
  {
    if ((addr = ip->addrs[bn]) == 0)
    80003224:	02059493          	slli	s1,a1,0x20
    80003228:	9081                	srli	s1,s1,0x20
    8000322a:	048a                	slli	s1,s1,0x2
    8000322c:	94aa                	add	s1,s1,a0
    8000322e:	0504a903          	lw	s2,80(s1)
    80003232:	06091e63          	bnez	s2,800032ae <bmap+0xa2>
    {
      addr = balloc(ip->dev);
    80003236:	4108                	lw	a0,0(a0)
    80003238:	00000097          	auipc	ra,0x0
    8000323c:	e9c080e7          	jalr	-356(ra) # 800030d4 <balloc>
    80003240:	0005091b          	sext.w	s2,a0
      if (addr == 0)
    80003244:	06090563          	beqz	s2,800032ae <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003248:	0524a823          	sw	s2,80(s1)
    8000324c:	a08d                	j	800032ae <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000324e:	ff45849b          	addiw	s1,a1,-12
    80003252:	0004871b          	sext.w	a4,s1

  if (bn < NINDIRECT)
    80003256:	0ff00793          	li	a5,255
    8000325a:	08e7e563          	bltu	a5,a4,800032e4 <bmap+0xd8>
  {
    // Load indirect block, allocating if necessary.
    if ((addr = ip->addrs[NDIRECT]) == 0)
    8000325e:	08052903          	lw	s2,128(a0)
    80003262:	00091d63          	bnez	s2,8000327c <bmap+0x70>
    {
      addr = balloc(ip->dev);
    80003266:	4108                	lw	a0,0(a0)
    80003268:	00000097          	auipc	ra,0x0
    8000326c:	e6c080e7          	jalr	-404(ra) # 800030d4 <balloc>
    80003270:	0005091b          	sext.w	s2,a0
      if (addr == 0)
    80003274:	02090d63          	beqz	s2,800032ae <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003278:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000327c:	85ca                	mv	a1,s2
    8000327e:	0009a503          	lw	a0,0(s3)
    80003282:	00000097          	auipc	ra,0x0
    80003286:	b90080e7          	jalr	-1136(ra) # 80002e12 <bread>
    8000328a:	8a2a                	mv	s4,a0
    a = (uint *)bp->data;
    8000328c:	05850793          	addi	a5,a0,88
    if ((addr = a[bn]) == 0)
    80003290:	02049593          	slli	a1,s1,0x20
    80003294:	9181                	srli	a1,a1,0x20
    80003296:	058a                	slli	a1,a1,0x2
    80003298:	00b784b3          	add	s1,a5,a1
    8000329c:	0004a903          	lw	s2,0(s1)
    800032a0:	02090063          	beqz	s2,800032c0 <bmap+0xb4>
      {
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800032a4:	8552                	mv	a0,s4
    800032a6:	00000097          	auipc	ra,0x0
    800032aa:	c9c080e7          	jalr	-868(ra) # 80002f42 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800032ae:	854a                	mv	a0,s2
    800032b0:	70a2                	ld	ra,40(sp)
    800032b2:	7402                	ld	s0,32(sp)
    800032b4:	64e2                	ld	s1,24(sp)
    800032b6:	6942                	ld	s2,16(sp)
    800032b8:	69a2                	ld	s3,8(sp)
    800032ba:	6a02                	ld	s4,0(sp)
    800032bc:	6145                	addi	sp,sp,48
    800032be:	8082                	ret
      addr = balloc(ip->dev);
    800032c0:	0009a503          	lw	a0,0(s3)
    800032c4:	00000097          	auipc	ra,0x0
    800032c8:	e10080e7          	jalr	-496(ra) # 800030d4 <balloc>
    800032cc:	0005091b          	sext.w	s2,a0
      if (addr)
    800032d0:	fc090ae3          	beqz	s2,800032a4 <bmap+0x98>
        a[bn] = addr;
    800032d4:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800032d8:	8552                	mv	a0,s4
    800032da:	00001097          	auipc	ra,0x1
    800032de:	1fe080e7          	jalr	510(ra) # 800044d8 <log_write>
    800032e2:	b7c9                	j	800032a4 <bmap+0x98>
  panic("bmap: out of range");
    800032e4:	00005517          	auipc	a0,0x5
    800032e8:	28450513          	addi	a0,a0,644 # 80008568 <syscalls+0x118>
    800032ec:	ffffd097          	auipc	ra,0xffffd
    800032f0:	252080e7          	jalr	594(ra) # 8000053e <panic>

00000000800032f4 <iget>:
{
    800032f4:	7179                	addi	sp,sp,-48
    800032f6:	f406                	sd	ra,40(sp)
    800032f8:	f022                	sd	s0,32(sp)
    800032fa:	ec26                	sd	s1,24(sp)
    800032fc:	e84a                	sd	s2,16(sp)
    800032fe:	e44e                	sd	s3,8(sp)
    80003300:	e052                	sd	s4,0(sp)
    80003302:	1800                	addi	s0,sp,48
    80003304:	89aa                	mv	s3,a0
    80003306:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003308:	0001c517          	auipc	a0,0x1c
    8000330c:	fb050513          	addi	a0,a0,-80 # 8001f2b8 <itable>
    80003310:	ffffe097          	auipc	ra,0xffffe
    80003314:	8c6080e7          	jalr	-1850(ra) # 80000bd6 <acquire>
  empty = 0;
    80003318:	4901                	li	s2,0
  for (ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++)
    8000331a:	0001c497          	auipc	s1,0x1c
    8000331e:	fb648493          	addi	s1,s1,-74 # 8001f2d0 <itable+0x18>
    80003322:	0001e697          	auipc	a3,0x1e
    80003326:	a3e68693          	addi	a3,a3,-1474 # 80020d60 <log>
    8000332a:	a039                	j	80003338 <iget+0x44>
    if (empty == 0 && ip->ref == 0) // Remember empty slot.
    8000332c:	02090b63          	beqz	s2,80003362 <iget+0x6e>
  for (ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++)
    80003330:	08848493          	addi	s1,s1,136
    80003334:	02d48a63          	beq	s1,a3,80003368 <iget+0x74>
    if (ip->ref > 0 && ip->dev == dev && ip->inum == inum)
    80003338:	449c                	lw	a5,8(s1)
    8000333a:	fef059e3          	blez	a5,8000332c <iget+0x38>
    8000333e:	4098                	lw	a4,0(s1)
    80003340:	ff3716e3          	bne	a4,s3,8000332c <iget+0x38>
    80003344:	40d8                	lw	a4,4(s1)
    80003346:	ff4713e3          	bne	a4,s4,8000332c <iget+0x38>
      ip->ref++;
    8000334a:	2785                	addiw	a5,a5,1
    8000334c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000334e:	0001c517          	auipc	a0,0x1c
    80003352:	f6a50513          	addi	a0,a0,-150 # 8001f2b8 <itable>
    80003356:	ffffe097          	auipc	ra,0xffffe
    8000335a:	934080e7          	jalr	-1740(ra) # 80000c8a <release>
      return ip;
    8000335e:	8926                	mv	s2,s1
    80003360:	a03d                	j	8000338e <iget+0x9a>
    if (empty == 0 && ip->ref == 0) // Remember empty slot.
    80003362:	f7f9                	bnez	a5,80003330 <iget+0x3c>
    80003364:	8926                	mv	s2,s1
    80003366:	b7e9                	j	80003330 <iget+0x3c>
  if (empty == 0)
    80003368:	02090c63          	beqz	s2,800033a0 <iget+0xac>
  ip->dev = dev;
    8000336c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003370:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003374:	4785                	li	a5,1
    80003376:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000337a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000337e:	0001c517          	auipc	a0,0x1c
    80003382:	f3a50513          	addi	a0,a0,-198 # 8001f2b8 <itable>
    80003386:	ffffe097          	auipc	ra,0xffffe
    8000338a:	904080e7          	jalr	-1788(ra) # 80000c8a <release>
}
    8000338e:	854a                	mv	a0,s2
    80003390:	70a2                	ld	ra,40(sp)
    80003392:	7402                	ld	s0,32(sp)
    80003394:	64e2                	ld	s1,24(sp)
    80003396:	6942                	ld	s2,16(sp)
    80003398:	69a2                	ld	s3,8(sp)
    8000339a:	6a02                	ld	s4,0(sp)
    8000339c:	6145                	addi	sp,sp,48
    8000339e:	8082                	ret
    panic("iget: no inodes");
    800033a0:	00005517          	auipc	a0,0x5
    800033a4:	1e050513          	addi	a0,a0,480 # 80008580 <syscalls+0x130>
    800033a8:	ffffd097          	auipc	ra,0xffffd
    800033ac:	196080e7          	jalr	406(ra) # 8000053e <panic>

00000000800033b0 <fsinit>:
{
    800033b0:	7179                	addi	sp,sp,-48
    800033b2:	f406                	sd	ra,40(sp)
    800033b4:	f022                	sd	s0,32(sp)
    800033b6:	ec26                	sd	s1,24(sp)
    800033b8:	e84a                	sd	s2,16(sp)
    800033ba:	e44e                	sd	s3,8(sp)
    800033bc:	1800                	addi	s0,sp,48
    800033be:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800033c0:	4585                	li	a1,1
    800033c2:	00000097          	auipc	ra,0x0
    800033c6:	a50080e7          	jalr	-1456(ra) # 80002e12 <bread>
    800033ca:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800033cc:	0001c997          	auipc	s3,0x1c
    800033d0:	ecc98993          	addi	s3,s3,-308 # 8001f298 <sb>
    800033d4:	02000613          	li	a2,32
    800033d8:	05850593          	addi	a1,a0,88
    800033dc:	854e                	mv	a0,s3
    800033de:	ffffe097          	auipc	ra,0xffffe
    800033e2:	950080e7          	jalr	-1712(ra) # 80000d2e <memmove>
  brelse(bp);
    800033e6:	8526                	mv	a0,s1
    800033e8:	00000097          	auipc	ra,0x0
    800033ec:	b5a080e7          	jalr	-1190(ra) # 80002f42 <brelse>
  if (sb.magic != FSMAGIC)
    800033f0:	0009a703          	lw	a4,0(s3)
    800033f4:	102037b7          	lui	a5,0x10203
    800033f8:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800033fc:	02f71263          	bne	a4,a5,80003420 <fsinit+0x70>
  initlog(dev, &sb);
    80003400:	0001c597          	auipc	a1,0x1c
    80003404:	e9858593          	addi	a1,a1,-360 # 8001f298 <sb>
    80003408:	854a                	mv	a0,s2
    8000340a:	00001097          	auipc	ra,0x1
    8000340e:	e52080e7          	jalr	-430(ra) # 8000425c <initlog>
}
    80003412:	70a2                	ld	ra,40(sp)
    80003414:	7402                	ld	s0,32(sp)
    80003416:	64e2                	ld	s1,24(sp)
    80003418:	6942                	ld	s2,16(sp)
    8000341a:	69a2                	ld	s3,8(sp)
    8000341c:	6145                	addi	sp,sp,48
    8000341e:	8082                	ret
    panic("invalid file system");
    80003420:	00005517          	auipc	a0,0x5
    80003424:	17050513          	addi	a0,a0,368 # 80008590 <syscalls+0x140>
    80003428:	ffffd097          	auipc	ra,0xffffd
    8000342c:	116080e7          	jalr	278(ra) # 8000053e <panic>

0000000080003430 <iinit>:
{
    80003430:	7179                	addi	sp,sp,-48
    80003432:	f406                	sd	ra,40(sp)
    80003434:	f022                	sd	s0,32(sp)
    80003436:	ec26                	sd	s1,24(sp)
    80003438:	e84a                	sd	s2,16(sp)
    8000343a:	e44e                	sd	s3,8(sp)
    8000343c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000343e:	00005597          	auipc	a1,0x5
    80003442:	16a58593          	addi	a1,a1,362 # 800085a8 <syscalls+0x158>
    80003446:	0001c517          	auipc	a0,0x1c
    8000344a:	e7250513          	addi	a0,a0,-398 # 8001f2b8 <itable>
    8000344e:	ffffd097          	auipc	ra,0xffffd
    80003452:	6f8080e7          	jalr	1784(ra) # 80000b46 <initlock>
  for (i = 0; i < NINODE; i++)
    80003456:	0001c497          	auipc	s1,0x1c
    8000345a:	e8a48493          	addi	s1,s1,-374 # 8001f2e0 <itable+0x28>
    8000345e:	0001e997          	auipc	s3,0x1e
    80003462:	91298993          	addi	s3,s3,-1774 # 80020d70 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003466:	00005917          	auipc	s2,0x5
    8000346a:	14a90913          	addi	s2,s2,330 # 800085b0 <syscalls+0x160>
    8000346e:	85ca                	mv	a1,s2
    80003470:	8526                	mv	a0,s1
    80003472:	00001097          	auipc	ra,0x1
    80003476:	14c080e7          	jalr	332(ra) # 800045be <initsleeplock>
  for (i = 0; i < NINODE; i++)
    8000347a:	08848493          	addi	s1,s1,136
    8000347e:	ff3498e3          	bne	s1,s3,8000346e <iinit+0x3e>
}
    80003482:	70a2                	ld	ra,40(sp)
    80003484:	7402                	ld	s0,32(sp)
    80003486:	64e2                	ld	s1,24(sp)
    80003488:	6942                	ld	s2,16(sp)
    8000348a:	69a2                	ld	s3,8(sp)
    8000348c:	6145                	addi	sp,sp,48
    8000348e:	8082                	ret

0000000080003490 <ialloc>:
{
    80003490:	715d                	addi	sp,sp,-80
    80003492:	e486                	sd	ra,72(sp)
    80003494:	e0a2                	sd	s0,64(sp)
    80003496:	fc26                	sd	s1,56(sp)
    80003498:	f84a                	sd	s2,48(sp)
    8000349a:	f44e                	sd	s3,40(sp)
    8000349c:	f052                	sd	s4,32(sp)
    8000349e:	ec56                	sd	s5,24(sp)
    800034a0:	e85a                	sd	s6,16(sp)
    800034a2:	e45e                	sd	s7,8(sp)
    800034a4:	0880                	addi	s0,sp,80
  for (inum = 1; inum < sb.ninodes; inum++)
    800034a6:	0001c717          	auipc	a4,0x1c
    800034aa:	dfe72703          	lw	a4,-514(a4) # 8001f2a4 <sb+0xc>
    800034ae:	4785                	li	a5,1
    800034b0:	04e7fa63          	bgeu	a5,a4,80003504 <ialloc+0x74>
    800034b4:	8aaa                	mv	s5,a0
    800034b6:	8bae                	mv	s7,a1
    800034b8:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800034ba:	0001ca17          	auipc	s4,0x1c
    800034be:	ddea0a13          	addi	s4,s4,-546 # 8001f298 <sb>
    800034c2:	00048b1b          	sext.w	s6,s1
    800034c6:	0044d793          	srli	a5,s1,0x4
    800034ca:	018a2583          	lw	a1,24(s4)
    800034ce:	9dbd                	addw	a1,a1,a5
    800034d0:	8556                	mv	a0,s5
    800034d2:	00000097          	auipc	ra,0x0
    800034d6:	940080e7          	jalr	-1728(ra) # 80002e12 <bread>
    800034da:	892a                	mv	s2,a0
    dip = (struct dinode *)bp->data + inum % IPB;
    800034dc:	05850993          	addi	s3,a0,88
    800034e0:	00f4f793          	andi	a5,s1,15
    800034e4:	079a                	slli	a5,a5,0x6
    800034e6:	99be                	add	s3,s3,a5
    if (dip->type == 0)
    800034e8:	00099783          	lh	a5,0(s3)
    800034ec:	c3a1                	beqz	a5,8000352c <ialloc+0x9c>
    brelse(bp);
    800034ee:	00000097          	auipc	ra,0x0
    800034f2:	a54080e7          	jalr	-1452(ra) # 80002f42 <brelse>
  for (inum = 1; inum < sb.ninodes; inum++)
    800034f6:	0485                	addi	s1,s1,1
    800034f8:	00ca2703          	lw	a4,12(s4)
    800034fc:	0004879b          	sext.w	a5,s1
    80003500:	fce7e1e3          	bltu	a5,a4,800034c2 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003504:	00005517          	auipc	a0,0x5
    80003508:	0b450513          	addi	a0,a0,180 # 800085b8 <syscalls+0x168>
    8000350c:	ffffd097          	auipc	ra,0xffffd
    80003510:	07c080e7          	jalr	124(ra) # 80000588 <printf>
  return 0;
    80003514:	4501                	li	a0,0
}
    80003516:	60a6                	ld	ra,72(sp)
    80003518:	6406                	ld	s0,64(sp)
    8000351a:	74e2                	ld	s1,56(sp)
    8000351c:	7942                	ld	s2,48(sp)
    8000351e:	79a2                	ld	s3,40(sp)
    80003520:	7a02                	ld	s4,32(sp)
    80003522:	6ae2                	ld	s5,24(sp)
    80003524:	6b42                	ld	s6,16(sp)
    80003526:	6ba2                	ld	s7,8(sp)
    80003528:	6161                	addi	sp,sp,80
    8000352a:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000352c:	04000613          	li	a2,64
    80003530:	4581                	li	a1,0
    80003532:	854e                	mv	a0,s3
    80003534:	ffffd097          	auipc	ra,0xffffd
    80003538:	79e080e7          	jalr	1950(ra) # 80000cd2 <memset>
      dip->type = type;
    8000353c:	01799023          	sh	s7,0(s3)
      log_write(bp); // mark it allocated on the disk
    80003540:	854a                	mv	a0,s2
    80003542:	00001097          	auipc	ra,0x1
    80003546:	f96080e7          	jalr	-106(ra) # 800044d8 <log_write>
      brelse(bp);
    8000354a:	854a                	mv	a0,s2
    8000354c:	00000097          	auipc	ra,0x0
    80003550:	9f6080e7          	jalr	-1546(ra) # 80002f42 <brelse>
      return iget(dev, inum);
    80003554:	85da                	mv	a1,s6
    80003556:	8556                	mv	a0,s5
    80003558:	00000097          	auipc	ra,0x0
    8000355c:	d9c080e7          	jalr	-612(ra) # 800032f4 <iget>
    80003560:	bf5d                	j	80003516 <ialloc+0x86>

0000000080003562 <iupdate>:
{
    80003562:	1101                	addi	sp,sp,-32
    80003564:	ec06                	sd	ra,24(sp)
    80003566:	e822                	sd	s0,16(sp)
    80003568:	e426                	sd	s1,8(sp)
    8000356a:	e04a                	sd	s2,0(sp)
    8000356c:	1000                	addi	s0,sp,32
    8000356e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003570:	415c                	lw	a5,4(a0)
    80003572:	0047d79b          	srliw	a5,a5,0x4
    80003576:	0001c597          	auipc	a1,0x1c
    8000357a:	d3a5a583          	lw	a1,-710(a1) # 8001f2b0 <sb+0x18>
    8000357e:	9dbd                	addw	a1,a1,a5
    80003580:	4108                	lw	a0,0(a0)
    80003582:	00000097          	auipc	ra,0x0
    80003586:	890080e7          	jalr	-1904(ra) # 80002e12 <bread>
    8000358a:	892a                	mv	s2,a0
  dip = (struct dinode *)bp->data + ip->inum % IPB;
    8000358c:	05850793          	addi	a5,a0,88
    80003590:	40c8                	lw	a0,4(s1)
    80003592:	893d                	andi	a0,a0,15
    80003594:	051a                	slli	a0,a0,0x6
    80003596:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003598:	04449703          	lh	a4,68(s1)
    8000359c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800035a0:	04649703          	lh	a4,70(s1)
    800035a4:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800035a8:	04849703          	lh	a4,72(s1)
    800035ac:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800035b0:	04a49703          	lh	a4,74(s1)
    800035b4:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800035b8:	44f8                	lw	a4,76(s1)
    800035ba:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800035bc:	03400613          	li	a2,52
    800035c0:	05048593          	addi	a1,s1,80
    800035c4:	0531                	addi	a0,a0,12
    800035c6:	ffffd097          	auipc	ra,0xffffd
    800035ca:	768080e7          	jalr	1896(ra) # 80000d2e <memmove>
  log_write(bp);
    800035ce:	854a                	mv	a0,s2
    800035d0:	00001097          	auipc	ra,0x1
    800035d4:	f08080e7          	jalr	-248(ra) # 800044d8 <log_write>
  brelse(bp);
    800035d8:	854a                	mv	a0,s2
    800035da:	00000097          	auipc	ra,0x0
    800035de:	968080e7          	jalr	-1688(ra) # 80002f42 <brelse>
}
    800035e2:	60e2                	ld	ra,24(sp)
    800035e4:	6442                	ld	s0,16(sp)
    800035e6:	64a2                	ld	s1,8(sp)
    800035e8:	6902                	ld	s2,0(sp)
    800035ea:	6105                	addi	sp,sp,32
    800035ec:	8082                	ret

00000000800035ee <idup>:
{
    800035ee:	1101                	addi	sp,sp,-32
    800035f0:	ec06                	sd	ra,24(sp)
    800035f2:	e822                	sd	s0,16(sp)
    800035f4:	e426                	sd	s1,8(sp)
    800035f6:	1000                	addi	s0,sp,32
    800035f8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800035fa:	0001c517          	auipc	a0,0x1c
    800035fe:	cbe50513          	addi	a0,a0,-834 # 8001f2b8 <itable>
    80003602:	ffffd097          	auipc	ra,0xffffd
    80003606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
  ip->ref++;
    8000360a:	449c                	lw	a5,8(s1)
    8000360c:	2785                	addiw	a5,a5,1
    8000360e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003610:	0001c517          	auipc	a0,0x1c
    80003614:	ca850513          	addi	a0,a0,-856 # 8001f2b8 <itable>
    80003618:	ffffd097          	auipc	ra,0xffffd
    8000361c:	672080e7          	jalr	1650(ra) # 80000c8a <release>
}
    80003620:	8526                	mv	a0,s1
    80003622:	60e2                	ld	ra,24(sp)
    80003624:	6442                	ld	s0,16(sp)
    80003626:	64a2                	ld	s1,8(sp)
    80003628:	6105                	addi	sp,sp,32
    8000362a:	8082                	ret

000000008000362c <ilock>:
{
    8000362c:	1101                	addi	sp,sp,-32
    8000362e:	ec06                	sd	ra,24(sp)
    80003630:	e822                	sd	s0,16(sp)
    80003632:	e426                	sd	s1,8(sp)
    80003634:	e04a                	sd	s2,0(sp)
    80003636:	1000                	addi	s0,sp,32
  if (ip == 0 || ip->ref < 1)
    80003638:	c115                	beqz	a0,8000365c <ilock+0x30>
    8000363a:	84aa                	mv	s1,a0
    8000363c:	451c                	lw	a5,8(a0)
    8000363e:	00f05f63          	blez	a5,8000365c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003642:	0541                	addi	a0,a0,16
    80003644:	00001097          	auipc	ra,0x1
    80003648:	fb4080e7          	jalr	-76(ra) # 800045f8 <acquiresleep>
  if (ip->valid == 0)
    8000364c:	40bc                	lw	a5,64(s1)
    8000364e:	cf99                	beqz	a5,8000366c <ilock+0x40>
}
    80003650:	60e2                	ld	ra,24(sp)
    80003652:	6442                	ld	s0,16(sp)
    80003654:	64a2                	ld	s1,8(sp)
    80003656:	6902                	ld	s2,0(sp)
    80003658:	6105                	addi	sp,sp,32
    8000365a:	8082                	ret
    panic("ilock");
    8000365c:	00005517          	auipc	a0,0x5
    80003660:	f7450513          	addi	a0,a0,-140 # 800085d0 <syscalls+0x180>
    80003664:	ffffd097          	auipc	ra,0xffffd
    80003668:	eda080e7          	jalr	-294(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000366c:	40dc                	lw	a5,4(s1)
    8000366e:	0047d79b          	srliw	a5,a5,0x4
    80003672:	0001c597          	auipc	a1,0x1c
    80003676:	c3e5a583          	lw	a1,-962(a1) # 8001f2b0 <sb+0x18>
    8000367a:	9dbd                	addw	a1,a1,a5
    8000367c:	4088                	lw	a0,0(s1)
    8000367e:	fffff097          	auipc	ra,0xfffff
    80003682:	794080e7          	jalr	1940(ra) # 80002e12 <bread>
    80003686:	892a                	mv	s2,a0
    dip = (struct dinode *)bp->data + ip->inum % IPB;
    80003688:	05850593          	addi	a1,a0,88
    8000368c:	40dc                	lw	a5,4(s1)
    8000368e:	8bbd                	andi	a5,a5,15
    80003690:	079a                	slli	a5,a5,0x6
    80003692:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003694:	00059783          	lh	a5,0(a1)
    80003698:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000369c:	00259783          	lh	a5,2(a1)
    800036a0:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800036a4:	00459783          	lh	a5,4(a1)
    800036a8:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800036ac:	00659783          	lh	a5,6(a1)
    800036b0:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800036b4:	459c                	lw	a5,8(a1)
    800036b6:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800036b8:	03400613          	li	a2,52
    800036bc:	05b1                	addi	a1,a1,12
    800036be:	05048513          	addi	a0,s1,80
    800036c2:	ffffd097          	auipc	ra,0xffffd
    800036c6:	66c080e7          	jalr	1644(ra) # 80000d2e <memmove>
    brelse(bp);
    800036ca:	854a                	mv	a0,s2
    800036cc:	00000097          	auipc	ra,0x0
    800036d0:	876080e7          	jalr	-1930(ra) # 80002f42 <brelse>
    ip->valid = 1;
    800036d4:	4785                	li	a5,1
    800036d6:	c0bc                	sw	a5,64(s1)
    if (ip->type == 0)
    800036d8:	04449783          	lh	a5,68(s1)
    800036dc:	fbb5                	bnez	a5,80003650 <ilock+0x24>
      panic("ilock: no type");
    800036de:	00005517          	auipc	a0,0x5
    800036e2:	efa50513          	addi	a0,a0,-262 # 800085d8 <syscalls+0x188>
    800036e6:	ffffd097          	auipc	ra,0xffffd
    800036ea:	e58080e7          	jalr	-424(ra) # 8000053e <panic>

00000000800036ee <iunlock>:
{
    800036ee:	1101                	addi	sp,sp,-32
    800036f0:	ec06                	sd	ra,24(sp)
    800036f2:	e822                	sd	s0,16(sp)
    800036f4:	e426                	sd	s1,8(sp)
    800036f6:	e04a                	sd	s2,0(sp)
    800036f8:	1000                	addi	s0,sp,32
  if (ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800036fa:	c905                	beqz	a0,8000372a <iunlock+0x3c>
    800036fc:	84aa                	mv	s1,a0
    800036fe:	01050913          	addi	s2,a0,16
    80003702:	854a                	mv	a0,s2
    80003704:	00001097          	auipc	ra,0x1
    80003708:	f8e080e7          	jalr	-114(ra) # 80004692 <holdingsleep>
    8000370c:	cd19                	beqz	a0,8000372a <iunlock+0x3c>
    8000370e:	449c                	lw	a5,8(s1)
    80003710:	00f05d63          	blez	a5,8000372a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003714:	854a                	mv	a0,s2
    80003716:	00001097          	auipc	ra,0x1
    8000371a:	f38080e7          	jalr	-200(ra) # 8000464e <releasesleep>
}
    8000371e:	60e2                	ld	ra,24(sp)
    80003720:	6442                	ld	s0,16(sp)
    80003722:	64a2                	ld	s1,8(sp)
    80003724:	6902                	ld	s2,0(sp)
    80003726:	6105                	addi	sp,sp,32
    80003728:	8082                	ret
    panic("iunlock");
    8000372a:	00005517          	auipc	a0,0x5
    8000372e:	ebe50513          	addi	a0,a0,-322 # 800085e8 <syscalls+0x198>
    80003732:	ffffd097          	auipc	ra,0xffffd
    80003736:	e0c080e7          	jalr	-500(ra) # 8000053e <panic>

000000008000373a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void itrunc(struct inode *ip)
{
    8000373a:	7179                	addi	sp,sp,-48
    8000373c:	f406                	sd	ra,40(sp)
    8000373e:	f022                	sd	s0,32(sp)
    80003740:	ec26                	sd	s1,24(sp)
    80003742:	e84a                	sd	s2,16(sp)
    80003744:	e44e                	sd	s3,8(sp)
    80003746:	e052                	sd	s4,0(sp)
    80003748:	1800                	addi	s0,sp,48
    8000374a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for (i = 0; i < NDIRECT; i++)
    8000374c:	05050493          	addi	s1,a0,80
    80003750:	08050913          	addi	s2,a0,128
    80003754:	a021                	j	8000375c <itrunc+0x22>
    80003756:	0491                	addi	s1,s1,4
    80003758:	01248d63          	beq	s1,s2,80003772 <itrunc+0x38>
  {
    if (ip->addrs[i])
    8000375c:	408c                	lw	a1,0(s1)
    8000375e:	dde5                	beqz	a1,80003756 <itrunc+0x1c>
    {
      bfree(ip->dev, ip->addrs[i]);
    80003760:	0009a503          	lw	a0,0(s3)
    80003764:	00000097          	auipc	ra,0x0
    80003768:	8f4080e7          	jalr	-1804(ra) # 80003058 <bfree>
      ip->addrs[i] = 0;
    8000376c:	0004a023          	sw	zero,0(s1)
    80003770:	b7dd                	j	80003756 <itrunc+0x1c>
    }
  }

  if (ip->addrs[NDIRECT])
    80003772:	0809a583          	lw	a1,128(s3)
    80003776:	e185                	bnez	a1,80003796 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003778:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000377c:	854e                	mv	a0,s3
    8000377e:	00000097          	auipc	ra,0x0
    80003782:	de4080e7          	jalr	-540(ra) # 80003562 <iupdate>
}
    80003786:	70a2                	ld	ra,40(sp)
    80003788:	7402                	ld	s0,32(sp)
    8000378a:	64e2                	ld	s1,24(sp)
    8000378c:	6942                	ld	s2,16(sp)
    8000378e:	69a2                	ld	s3,8(sp)
    80003790:	6a02                	ld	s4,0(sp)
    80003792:	6145                	addi	sp,sp,48
    80003794:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003796:	0009a503          	lw	a0,0(s3)
    8000379a:	fffff097          	auipc	ra,0xfffff
    8000379e:	678080e7          	jalr	1656(ra) # 80002e12 <bread>
    800037a2:	8a2a                	mv	s4,a0
    for (j = 0; j < NINDIRECT; j++)
    800037a4:	05850493          	addi	s1,a0,88
    800037a8:	45850913          	addi	s2,a0,1112
    800037ac:	a021                	j	800037b4 <itrunc+0x7a>
    800037ae:	0491                	addi	s1,s1,4
    800037b0:	01248b63          	beq	s1,s2,800037c6 <itrunc+0x8c>
      if (a[j])
    800037b4:	408c                	lw	a1,0(s1)
    800037b6:	dde5                	beqz	a1,800037ae <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800037b8:	0009a503          	lw	a0,0(s3)
    800037bc:	00000097          	auipc	ra,0x0
    800037c0:	89c080e7          	jalr	-1892(ra) # 80003058 <bfree>
    800037c4:	b7ed                	j	800037ae <itrunc+0x74>
    brelse(bp);
    800037c6:	8552                	mv	a0,s4
    800037c8:	fffff097          	auipc	ra,0xfffff
    800037cc:	77a080e7          	jalr	1914(ra) # 80002f42 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800037d0:	0809a583          	lw	a1,128(s3)
    800037d4:	0009a503          	lw	a0,0(s3)
    800037d8:	00000097          	auipc	ra,0x0
    800037dc:	880080e7          	jalr	-1920(ra) # 80003058 <bfree>
    ip->addrs[NDIRECT] = 0;
    800037e0:	0809a023          	sw	zero,128(s3)
    800037e4:	bf51                	j	80003778 <itrunc+0x3e>

00000000800037e6 <iput>:
{
    800037e6:	1101                	addi	sp,sp,-32
    800037e8:	ec06                	sd	ra,24(sp)
    800037ea:	e822                	sd	s0,16(sp)
    800037ec:	e426                	sd	s1,8(sp)
    800037ee:	e04a                	sd	s2,0(sp)
    800037f0:	1000                	addi	s0,sp,32
    800037f2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800037f4:	0001c517          	auipc	a0,0x1c
    800037f8:	ac450513          	addi	a0,a0,-1340 # 8001f2b8 <itable>
    800037fc:	ffffd097          	auipc	ra,0xffffd
    80003800:	3da080e7          	jalr	986(ra) # 80000bd6 <acquire>
  if (ip->ref == 1 && ip->valid && ip->nlink == 0)
    80003804:	4498                	lw	a4,8(s1)
    80003806:	4785                	li	a5,1
    80003808:	02f70363          	beq	a4,a5,8000382e <iput+0x48>
  ip->ref--;
    8000380c:	449c                	lw	a5,8(s1)
    8000380e:	37fd                	addiw	a5,a5,-1
    80003810:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003812:	0001c517          	auipc	a0,0x1c
    80003816:	aa650513          	addi	a0,a0,-1370 # 8001f2b8 <itable>
    8000381a:	ffffd097          	auipc	ra,0xffffd
    8000381e:	470080e7          	jalr	1136(ra) # 80000c8a <release>
}
    80003822:	60e2                	ld	ra,24(sp)
    80003824:	6442                	ld	s0,16(sp)
    80003826:	64a2                	ld	s1,8(sp)
    80003828:	6902                	ld	s2,0(sp)
    8000382a:	6105                	addi	sp,sp,32
    8000382c:	8082                	ret
  if (ip->ref == 1 && ip->valid && ip->nlink == 0)
    8000382e:	40bc                	lw	a5,64(s1)
    80003830:	dff1                	beqz	a5,8000380c <iput+0x26>
    80003832:	04a49783          	lh	a5,74(s1)
    80003836:	fbf9                	bnez	a5,8000380c <iput+0x26>
    acquiresleep(&ip->lock);
    80003838:	01048913          	addi	s2,s1,16
    8000383c:	854a                	mv	a0,s2
    8000383e:	00001097          	auipc	ra,0x1
    80003842:	dba080e7          	jalr	-582(ra) # 800045f8 <acquiresleep>
    release(&itable.lock);
    80003846:	0001c517          	auipc	a0,0x1c
    8000384a:	a7250513          	addi	a0,a0,-1422 # 8001f2b8 <itable>
    8000384e:	ffffd097          	auipc	ra,0xffffd
    80003852:	43c080e7          	jalr	1084(ra) # 80000c8a <release>
    itrunc(ip);
    80003856:	8526                	mv	a0,s1
    80003858:	00000097          	auipc	ra,0x0
    8000385c:	ee2080e7          	jalr	-286(ra) # 8000373a <itrunc>
    ip->type = 0;
    80003860:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003864:	8526                	mv	a0,s1
    80003866:	00000097          	auipc	ra,0x0
    8000386a:	cfc080e7          	jalr	-772(ra) # 80003562 <iupdate>
    ip->valid = 0;
    8000386e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003872:	854a                	mv	a0,s2
    80003874:	00001097          	auipc	ra,0x1
    80003878:	dda080e7          	jalr	-550(ra) # 8000464e <releasesleep>
    acquire(&itable.lock);
    8000387c:	0001c517          	auipc	a0,0x1c
    80003880:	a3c50513          	addi	a0,a0,-1476 # 8001f2b8 <itable>
    80003884:	ffffd097          	auipc	ra,0xffffd
    80003888:	352080e7          	jalr	850(ra) # 80000bd6 <acquire>
    8000388c:	b741                	j	8000380c <iput+0x26>

000000008000388e <iunlockput>:
{
    8000388e:	1101                	addi	sp,sp,-32
    80003890:	ec06                	sd	ra,24(sp)
    80003892:	e822                	sd	s0,16(sp)
    80003894:	e426                	sd	s1,8(sp)
    80003896:	1000                	addi	s0,sp,32
    80003898:	84aa                	mv	s1,a0
  iunlock(ip);
    8000389a:	00000097          	auipc	ra,0x0
    8000389e:	e54080e7          	jalr	-428(ra) # 800036ee <iunlock>
  iput(ip);
    800038a2:	8526                	mv	a0,s1
    800038a4:	00000097          	auipc	ra,0x0
    800038a8:	f42080e7          	jalr	-190(ra) # 800037e6 <iput>
}
    800038ac:	60e2                	ld	ra,24(sp)
    800038ae:	6442                	ld	s0,16(sp)
    800038b0:	64a2                	ld	s1,8(sp)
    800038b2:	6105                	addi	sp,sp,32
    800038b4:	8082                	ret

00000000800038b6 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void stati(struct inode *ip, struct stat *st)
{
    800038b6:	1141                	addi	sp,sp,-16
    800038b8:	e422                	sd	s0,8(sp)
    800038ba:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800038bc:	411c                	lw	a5,0(a0)
    800038be:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800038c0:	415c                	lw	a5,4(a0)
    800038c2:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800038c4:	04451783          	lh	a5,68(a0)
    800038c8:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800038cc:	04a51783          	lh	a5,74(a0)
    800038d0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800038d4:	04c56783          	lwu	a5,76(a0)
    800038d8:	e99c                	sd	a5,16(a1)
}
    800038da:	6422                	ld	s0,8(sp)
    800038dc:	0141                	addi	sp,sp,16
    800038de:	8082                	ret

00000000800038e0 <readi>:
int readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if (off > ip->size || off + n < off)
    800038e0:	457c                	lw	a5,76(a0)
    800038e2:	0ed7e963          	bltu	a5,a3,800039d4 <readi+0xf4>
{
    800038e6:	7159                	addi	sp,sp,-112
    800038e8:	f486                	sd	ra,104(sp)
    800038ea:	f0a2                	sd	s0,96(sp)
    800038ec:	eca6                	sd	s1,88(sp)
    800038ee:	e8ca                	sd	s2,80(sp)
    800038f0:	e4ce                	sd	s3,72(sp)
    800038f2:	e0d2                	sd	s4,64(sp)
    800038f4:	fc56                	sd	s5,56(sp)
    800038f6:	f85a                	sd	s6,48(sp)
    800038f8:	f45e                	sd	s7,40(sp)
    800038fa:	f062                	sd	s8,32(sp)
    800038fc:	ec66                	sd	s9,24(sp)
    800038fe:	e86a                	sd	s10,16(sp)
    80003900:	e46e                	sd	s11,8(sp)
    80003902:	1880                	addi	s0,sp,112
    80003904:	8b2a                	mv	s6,a0
    80003906:	8bae                	mv	s7,a1
    80003908:	8a32                	mv	s4,a2
    8000390a:	84b6                	mv	s1,a3
    8000390c:	8aba                	mv	s5,a4
  if (off > ip->size || off + n < off)
    8000390e:	9f35                	addw	a4,a4,a3
    return 0;
    80003910:	4501                	li	a0,0
  if (off > ip->size || off + n < off)
    80003912:	0ad76063          	bltu	a4,a3,800039b2 <readi+0xd2>
  if (off + n > ip->size)
    80003916:	00e7f463          	bgeu	a5,a4,8000391e <readi+0x3e>
    n = ip->size - off;
    8000391a:	40d78abb          	subw	s5,a5,a3

  for (tot = 0; tot < n; tot += m, off += m, dst += m)
    8000391e:	0a0a8963          	beqz	s5,800039d0 <readi+0xf0>
    80003922:	4981                	li	s3,0
  {
    uint addr = bmap(ip, off / BSIZE);
    if (addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off % BSIZE);
    80003924:	40000c93          	li	s9,1024
    if (either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1)
    80003928:	5c7d                	li	s8,-1
    8000392a:	a82d                	j	80003964 <readi+0x84>
    8000392c:	020d1d93          	slli	s11,s10,0x20
    80003930:	020ddd93          	srli	s11,s11,0x20
    80003934:	05890793          	addi	a5,s2,88
    80003938:	86ee                	mv	a3,s11
    8000393a:	963e                	add	a2,a2,a5
    8000393c:	85d2                	mv	a1,s4
    8000393e:	855e                	mv	a0,s7
    80003940:	fffff097          	auipc	ra,0xfffff
    80003944:	b1c080e7          	jalr	-1252(ra) # 8000245c <either_copyout>
    80003948:	05850d63          	beq	a0,s8,800039a2 <readi+0xc2>
    {
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000394c:	854a                	mv	a0,s2
    8000394e:	fffff097          	auipc	ra,0xfffff
    80003952:	5f4080e7          	jalr	1524(ra) # 80002f42 <brelse>
  for (tot = 0; tot < n; tot += m, off += m, dst += m)
    80003956:	013d09bb          	addw	s3,s10,s3
    8000395a:	009d04bb          	addw	s1,s10,s1
    8000395e:	9a6e                	add	s4,s4,s11
    80003960:	0559f763          	bgeu	s3,s5,800039ae <readi+0xce>
    uint addr = bmap(ip, off / BSIZE);
    80003964:	00a4d59b          	srliw	a1,s1,0xa
    80003968:	855a                	mv	a0,s6
    8000396a:	00000097          	auipc	ra,0x0
    8000396e:	8a2080e7          	jalr	-1886(ra) # 8000320c <bmap>
    80003972:	0005059b          	sext.w	a1,a0
    if (addr == 0)
    80003976:	cd85                	beqz	a1,800039ae <readi+0xce>
    bp = bread(ip->dev, addr);
    80003978:	000b2503          	lw	a0,0(s6)
    8000397c:	fffff097          	auipc	ra,0xfffff
    80003980:	496080e7          	jalr	1174(ra) # 80002e12 <bread>
    80003984:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off % BSIZE);
    80003986:	3ff4f613          	andi	a2,s1,1023
    8000398a:	40cc87bb          	subw	a5,s9,a2
    8000398e:	413a873b          	subw	a4,s5,s3
    80003992:	8d3e                	mv	s10,a5
    80003994:	2781                	sext.w	a5,a5
    80003996:	0007069b          	sext.w	a3,a4
    8000399a:	f8f6f9e3          	bgeu	a3,a5,8000392c <readi+0x4c>
    8000399e:	8d3a                	mv	s10,a4
    800039a0:	b771                	j	8000392c <readi+0x4c>
      brelse(bp);
    800039a2:	854a                	mv	a0,s2
    800039a4:	fffff097          	auipc	ra,0xfffff
    800039a8:	59e080e7          	jalr	1438(ra) # 80002f42 <brelse>
      tot = -1;
    800039ac:	59fd                	li	s3,-1
  }
  return tot;
    800039ae:	0009851b          	sext.w	a0,s3
}
    800039b2:	70a6                	ld	ra,104(sp)
    800039b4:	7406                	ld	s0,96(sp)
    800039b6:	64e6                	ld	s1,88(sp)
    800039b8:	6946                	ld	s2,80(sp)
    800039ba:	69a6                	ld	s3,72(sp)
    800039bc:	6a06                	ld	s4,64(sp)
    800039be:	7ae2                	ld	s5,56(sp)
    800039c0:	7b42                	ld	s6,48(sp)
    800039c2:	7ba2                	ld	s7,40(sp)
    800039c4:	7c02                	ld	s8,32(sp)
    800039c6:	6ce2                	ld	s9,24(sp)
    800039c8:	6d42                	ld	s10,16(sp)
    800039ca:	6da2                	ld	s11,8(sp)
    800039cc:	6165                	addi	sp,sp,112
    800039ce:	8082                	ret
  for (tot = 0; tot < n; tot += m, off += m, dst += m)
    800039d0:	89d6                	mv	s3,s5
    800039d2:	bff1                	j	800039ae <readi+0xce>
    return 0;
    800039d4:	4501                	li	a0,0
}
    800039d6:	8082                	ret

00000000800039d8 <writei>:
int writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if (off > ip->size || off + n < off)
    800039d8:	457c                	lw	a5,76(a0)
    800039da:	10d7e863          	bltu	a5,a3,80003aea <writei+0x112>
{
    800039de:	7159                	addi	sp,sp,-112
    800039e0:	f486                	sd	ra,104(sp)
    800039e2:	f0a2                	sd	s0,96(sp)
    800039e4:	eca6                	sd	s1,88(sp)
    800039e6:	e8ca                	sd	s2,80(sp)
    800039e8:	e4ce                	sd	s3,72(sp)
    800039ea:	e0d2                	sd	s4,64(sp)
    800039ec:	fc56                	sd	s5,56(sp)
    800039ee:	f85a                	sd	s6,48(sp)
    800039f0:	f45e                	sd	s7,40(sp)
    800039f2:	f062                	sd	s8,32(sp)
    800039f4:	ec66                	sd	s9,24(sp)
    800039f6:	e86a                	sd	s10,16(sp)
    800039f8:	e46e                	sd	s11,8(sp)
    800039fa:	1880                	addi	s0,sp,112
    800039fc:	8aaa                	mv	s5,a0
    800039fe:	8bae                	mv	s7,a1
    80003a00:	8a32                	mv	s4,a2
    80003a02:	8936                	mv	s2,a3
    80003a04:	8b3a                	mv	s6,a4
  if (off > ip->size || off + n < off)
    80003a06:	00e687bb          	addw	a5,a3,a4
    80003a0a:	0ed7e263          	bltu	a5,a3,80003aee <writei+0x116>
    return -1;
  if (off + n > MAXFILE * BSIZE)
    80003a0e:	00043737          	lui	a4,0x43
    80003a12:	0ef76063          	bltu	a4,a5,80003af2 <writei+0x11a>
    return -1;

  for (tot = 0; tot < n; tot += m, off += m, src += m)
    80003a16:	0c0b0863          	beqz	s6,80003ae6 <writei+0x10e>
    80003a1a:	4981                	li	s3,0
  {
    uint addr = bmap(ip, off / BSIZE);
    if (addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off % BSIZE);
    80003a1c:	40000c93          	li	s9,1024
    if (either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1)
    80003a20:	5c7d                	li	s8,-1
    80003a22:	a091                	j	80003a66 <writei+0x8e>
    80003a24:	020d1d93          	slli	s11,s10,0x20
    80003a28:	020ddd93          	srli	s11,s11,0x20
    80003a2c:	05848793          	addi	a5,s1,88
    80003a30:	86ee                	mv	a3,s11
    80003a32:	8652                	mv	a2,s4
    80003a34:	85de                	mv	a1,s7
    80003a36:	953e                	add	a0,a0,a5
    80003a38:	fffff097          	auipc	ra,0xfffff
    80003a3c:	a7a080e7          	jalr	-1414(ra) # 800024b2 <either_copyin>
    80003a40:	07850263          	beq	a0,s8,80003aa4 <writei+0xcc>
    {
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a44:	8526                	mv	a0,s1
    80003a46:	00001097          	auipc	ra,0x1
    80003a4a:	a92080e7          	jalr	-1390(ra) # 800044d8 <log_write>
    brelse(bp);
    80003a4e:	8526                	mv	a0,s1
    80003a50:	fffff097          	auipc	ra,0xfffff
    80003a54:	4f2080e7          	jalr	1266(ra) # 80002f42 <brelse>
  for (tot = 0; tot < n; tot += m, off += m, src += m)
    80003a58:	013d09bb          	addw	s3,s10,s3
    80003a5c:	012d093b          	addw	s2,s10,s2
    80003a60:	9a6e                	add	s4,s4,s11
    80003a62:	0569f663          	bgeu	s3,s6,80003aae <writei+0xd6>
    uint addr = bmap(ip, off / BSIZE);
    80003a66:	00a9559b          	srliw	a1,s2,0xa
    80003a6a:	8556                	mv	a0,s5
    80003a6c:	fffff097          	auipc	ra,0xfffff
    80003a70:	7a0080e7          	jalr	1952(ra) # 8000320c <bmap>
    80003a74:	0005059b          	sext.w	a1,a0
    if (addr == 0)
    80003a78:	c99d                	beqz	a1,80003aae <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003a7a:	000aa503          	lw	a0,0(s5)
    80003a7e:	fffff097          	auipc	ra,0xfffff
    80003a82:	394080e7          	jalr	916(ra) # 80002e12 <bread>
    80003a86:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off % BSIZE);
    80003a88:	3ff97513          	andi	a0,s2,1023
    80003a8c:	40ac87bb          	subw	a5,s9,a0
    80003a90:	413b073b          	subw	a4,s6,s3
    80003a94:	8d3e                	mv	s10,a5
    80003a96:	2781                	sext.w	a5,a5
    80003a98:	0007069b          	sext.w	a3,a4
    80003a9c:	f8f6f4e3          	bgeu	a3,a5,80003a24 <writei+0x4c>
    80003aa0:	8d3a                	mv	s10,a4
    80003aa2:	b749                	j	80003a24 <writei+0x4c>
      brelse(bp);
    80003aa4:	8526                	mv	a0,s1
    80003aa6:	fffff097          	auipc	ra,0xfffff
    80003aaa:	49c080e7          	jalr	1180(ra) # 80002f42 <brelse>
  }

  if (off > ip->size)
    80003aae:	04caa783          	lw	a5,76(s5)
    80003ab2:	0127f463          	bgeu	a5,s2,80003aba <writei+0xe2>
    ip->size = off;
    80003ab6:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003aba:	8556                	mv	a0,s5
    80003abc:	00000097          	auipc	ra,0x0
    80003ac0:	aa6080e7          	jalr	-1370(ra) # 80003562 <iupdate>

  return tot;
    80003ac4:	0009851b          	sext.w	a0,s3
}
    80003ac8:	70a6                	ld	ra,104(sp)
    80003aca:	7406                	ld	s0,96(sp)
    80003acc:	64e6                	ld	s1,88(sp)
    80003ace:	6946                	ld	s2,80(sp)
    80003ad0:	69a6                	ld	s3,72(sp)
    80003ad2:	6a06                	ld	s4,64(sp)
    80003ad4:	7ae2                	ld	s5,56(sp)
    80003ad6:	7b42                	ld	s6,48(sp)
    80003ad8:	7ba2                	ld	s7,40(sp)
    80003ada:	7c02                	ld	s8,32(sp)
    80003adc:	6ce2                	ld	s9,24(sp)
    80003ade:	6d42                	ld	s10,16(sp)
    80003ae0:	6da2                	ld	s11,8(sp)
    80003ae2:	6165                	addi	sp,sp,112
    80003ae4:	8082                	ret
  for (tot = 0; tot < n; tot += m, off += m, src += m)
    80003ae6:	89da                	mv	s3,s6
    80003ae8:	bfc9                	j	80003aba <writei+0xe2>
    return -1;
    80003aea:	557d                	li	a0,-1
}
    80003aec:	8082                	ret
    return -1;
    80003aee:	557d                	li	a0,-1
    80003af0:	bfe1                	j	80003ac8 <writei+0xf0>
    return -1;
    80003af2:	557d                	li	a0,-1
    80003af4:	bfd1                	j	80003ac8 <writei+0xf0>

0000000080003af6 <namecmp>:

// Directories

int namecmp(const char *s, const char *t)
{
    80003af6:	1141                	addi	sp,sp,-16
    80003af8:	e406                	sd	ra,8(sp)
    80003afa:	e022                	sd	s0,0(sp)
    80003afc:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003afe:	4639                	li	a2,14
    80003b00:	ffffd097          	auipc	ra,0xffffd
    80003b04:	2a2080e7          	jalr	674(ra) # 80000da2 <strncmp>
}
    80003b08:	60a2                	ld	ra,8(sp)
    80003b0a:	6402                	ld	s0,0(sp)
    80003b0c:	0141                	addi	sp,sp,16
    80003b0e:	8082                	ret

0000000080003b10 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode *
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b10:	7139                	addi	sp,sp,-64
    80003b12:	fc06                	sd	ra,56(sp)
    80003b14:	f822                	sd	s0,48(sp)
    80003b16:	f426                	sd	s1,40(sp)
    80003b18:	f04a                	sd	s2,32(sp)
    80003b1a:	ec4e                	sd	s3,24(sp)
    80003b1c:	e852                	sd	s4,16(sp)
    80003b1e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if (dp->type != T_DIR)
    80003b20:	04451703          	lh	a4,68(a0)
    80003b24:	4785                	li	a5,1
    80003b26:	00f71a63          	bne	a4,a5,80003b3a <dirlookup+0x2a>
    80003b2a:	892a                	mv	s2,a0
    80003b2c:	89ae                	mv	s3,a1
    80003b2e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for (off = 0; off < dp->size; off += sizeof(de))
    80003b30:	457c                	lw	a5,76(a0)
    80003b32:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b34:	4501                	li	a0,0
  for (off = 0; off < dp->size; off += sizeof(de))
    80003b36:	e79d                	bnez	a5,80003b64 <dirlookup+0x54>
    80003b38:	a8a5                	j	80003bb0 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003b3a:	00005517          	auipc	a0,0x5
    80003b3e:	ab650513          	addi	a0,a0,-1354 # 800085f0 <syscalls+0x1a0>
    80003b42:	ffffd097          	auipc	ra,0xffffd
    80003b46:	9fc080e7          	jalr	-1540(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003b4a:	00005517          	auipc	a0,0x5
    80003b4e:	abe50513          	addi	a0,a0,-1346 # 80008608 <syscalls+0x1b8>
    80003b52:	ffffd097          	auipc	ra,0xffffd
    80003b56:	9ec080e7          	jalr	-1556(ra) # 8000053e <panic>
  for (off = 0; off < dp->size; off += sizeof(de))
    80003b5a:	24c1                	addiw	s1,s1,16
    80003b5c:	04c92783          	lw	a5,76(s2)
    80003b60:	04f4f763          	bgeu	s1,a5,80003bae <dirlookup+0x9e>
    if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b64:	4741                	li	a4,16
    80003b66:	86a6                	mv	a3,s1
    80003b68:	fc040613          	addi	a2,s0,-64
    80003b6c:	4581                	li	a1,0
    80003b6e:	854a                	mv	a0,s2
    80003b70:	00000097          	auipc	ra,0x0
    80003b74:	d70080e7          	jalr	-656(ra) # 800038e0 <readi>
    80003b78:	47c1                	li	a5,16
    80003b7a:	fcf518e3          	bne	a0,a5,80003b4a <dirlookup+0x3a>
    if (de.inum == 0)
    80003b7e:	fc045783          	lhu	a5,-64(s0)
    80003b82:	dfe1                	beqz	a5,80003b5a <dirlookup+0x4a>
    if (namecmp(name, de.name) == 0)
    80003b84:	fc240593          	addi	a1,s0,-62
    80003b88:	854e                	mv	a0,s3
    80003b8a:	00000097          	auipc	ra,0x0
    80003b8e:	f6c080e7          	jalr	-148(ra) # 80003af6 <namecmp>
    80003b92:	f561                	bnez	a0,80003b5a <dirlookup+0x4a>
      if (poff)
    80003b94:	000a0463          	beqz	s4,80003b9c <dirlookup+0x8c>
        *poff = off;
    80003b98:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003b9c:	fc045583          	lhu	a1,-64(s0)
    80003ba0:	00092503          	lw	a0,0(s2)
    80003ba4:	fffff097          	auipc	ra,0xfffff
    80003ba8:	750080e7          	jalr	1872(ra) # 800032f4 <iget>
    80003bac:	a011                	j	80003bb0 <dirlookup+0xa0>
  return 0;
    80003bae:	4501                	li	a0,0
}
    80003bb0:	70e2                	ld	ra,56(sp)
    80003bb2:	7442                	ld	s0,48(sp)
    80003bb4:	74a2                	ld	s1,40(sp)
    80003bb6:	7902                	ld	s2,32(sp)
    80003bb8:	69e2                	ld	s3,24(sp)
    80003bba:	6a42                	ld	s4,16(sp)
    80003bbc:	6121                	addi	sp,sp,64
    80003bbe:	8082                	ret

0000000080003bc0 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode *
namex(char *path, int nameiparent, char *name)
{
    80003bc0:	711d                	addi	sp,sp,-96
    80003bc2:	ec86                	sd	ra,88(sp)
    80003bc4:	e8a2                	sd	s0,80(sp)
    80003bc6:	e4a6                	sd	s1,72(sp)
    80003bc8:	e0ca                	sd	s2,64(sp)
    80003bca:	fc4e                	sd	s3,56(sp)
    80003bcc:	f852                	sd	s4,48(sp)
    80003bce:	f456                	sd	s5,40(sp)
    80003bd0:	f05a                	sd	s6,32(sp)
    80003bd2:	ec5e                	sd	s7,24(sp)
    80003bd4:	e862                	sd	s8,16(sp)
    80003bd6:	e466                	sd	s9,8(sp)
    80003bd8:	1080                	addi	s0,sp,96
    80003bda:	84aa                	mv	s1,a0
    80003bdc:	8aae                	mv	s5,a1
    80003bde:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if (*path == '/')
    80003be0:	00054703          	lbu	a4,0(a0)
    80003be4:	02f00793          	li	a5,47
    80003be8:	02f70363          	beq	a4,a5,80003c0e <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003bec:	ffffe097          	auipc	ra,0xffffe
    80003bf0:	dc0080e7          	jalr	-576(ra) # 800019ac <myproc>
    80003bf4:	15053503          	ld	a0,336(a0)
    80003bf8:	00000097          	auipc	ra,0x0
    80003bfc:	9f6080e7          	jalr	-1546(ra) # 800035ee <idup>
    80003c00:	89aa                	mv	s3,a0
  while (*path == '/')
    80003c02:	02f00913          	li	s2,47
  len = path - s;
    80003c06:	4b01                	li	s6,0
  if (len >= DIRSIZ)
    80003c08:	4c35                	li	s8,13

  while ((path = skipelem(path, name)) != 0)
  {
    ilock(ip);
    if (ip->type != T_DIR)
    80003c0a:	4b85                	li	s7,1
    80003c0c:	a865                	j	80003cc4 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003c0e:	4585                	li	a1,1
    80003c10:	4505                	li	a0,1
    80003c12:	fffff097          	auipc	ra,0xfffff
    80003c16:	6e2080e7          	jalr	1762(ra) # 800032f4 <iget>
    80003c1a:	89aa                	mv	s3,a0
    80003c1c:	b7dd                	j	80003c02 <namex+0x42>
    {
      iunlockput(ip);
    80003c1e:	854e                	mv	a0,s3
    80003c20:	00000097          	auipc	ra,0x0
    80003c24:	c6e080e7          	jalr	-914(ra) # 8000388e <iunlockput>
      return 0;
    80003c28:	4981                	li	s3,0
  {
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c2a:	854e                	mv	a0,s3
    80003c2c:	60e6                	ld	ra,88(sp)
    80003c2e:	6446                	ld	s0,80(sp)
    80003c30:	64a6                	ld	s1,72(sp)
    80003c32:	6906                	ld	s2,64(sp)
    80003c34:	79e2                	ld	s3,56(sp)
    80003c36:	7a42                	ld	s4,48(sp)
    80003c38:	7aa2                	ld	s5,40(sp)
    80003c3a:	7b02                	ld	s6,32(sp)
    80003c3c:	6be2                	ld	s7,24(sp)
    80003c3e:	6c42                	ld	s8,16(sp)
    80003c40:	6ca2                	ld	s9,8(sp)
    80003c42:	6125                	addi	sp,sp,96
    80003c44:	8082                	ret
      iunlock(ip);
    80003c46:	854e                	mv	a0,s3
    80003c48:	00000097          	auipc	ra,0x0
    80003c4c:	aa6080e7          	jalr	-1370(ra) # 800036ee <iunlock>
      return ip;
    80003c50:	bfe9                	j	80003c2a <namex+0x6a>
      iunlockput(ip);
    80003c52:	854e                	mv	a0,s3
    80003c54:	00000097          	auipc	ra,0x0
    80003c58:	c3a080e7          	jalr	-966(ra) # 8000388e <iunlockput>
      return 0;
    80003c5c:	89e6                	mv	s3,s9
    80003c5e:	b7f1                	j	80003c2a <namex+0x6a>
  len = path - s;
    80003c60:	40b48633          	sub	a2,s1,a1
    80003c64:	00060c9b          	sext.w	s9,a2
  if (len >= DIRSIZ)
    80003c68:	099c5463          	bge	s8,s9,80003cf0 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003c6c:	4639                	li	a2,14
    80003c6e:	8552                	mv	a0,s4
    80003c70:	ffffd097          	auipc	ra,0xffffd
    80003c74:	0be080e7          	jalr	190(ra) # 80000d2e <memmove>
  while (*path == '/')
    80003c78:	0004c783          	lbu	a5,0(s1)
    80003c7c:	01279763          	bne	a5,s2,80003c8a <namex+0xca>
    path++;
    80003c80:	0485                	addi	s1,s1,1
  while (*path == '/')
    80003c82:	0004c783          	lbu	a5,0(s1)
    80003c86:	ff278de3          	beq	a5,s2,80003c80 <namex+0xc0>
    ilock(ip);
    80003c8a:	854e                	mv	a0,s3
    80003c8c:	00000097          	auipc	ra,0x0
    80003c90:	9a0080e7          	jalr	-1632(ra) # 8000362c <ilock>
    if (ip->type != T_DIR)
    80003c94:	04499783          	lh	a5,68(s3)
    80003c98:	f97793e3          	bne	a5,s7,80003c1e <namex+0x5e>
    if (nameiparent && *path == '\0')
    80003c9c:	000a8563          	beqz	s5,80003ca6 <namex+0xe6>
    80003ca0:	0004c783          	lbu	a5,0(s1)
    80003ca4:	d3cd                	beqz	a5,80003c46 <namex+0x86>
    if ((next = dirlookup(ip, name, 0)) == 0)
    80003ca6:	865a                	mv	a2,s6
    80003ca8:	85d2                	mv	a1,s4
    80003caa:	854e                	mv	a0,s3
    80003cac:	00000097          	auipc	ra,0x0
    80003cb0:	e64080e7          	jalr	-412(ra) # 80003b10 <dirlookup>
    80003cb4:	8caa                	mv	s9,a0
    80003cb6:	dd51                	beqz	a0,80003c52 <namex+0x92>
    iunlockput(ip);
    80003cb8:	854e                	mv	a0,s3
    80003cba:	00000097          	auipc	ra,0x0
    80003cbe:	bd4080e7          	jalr	-1068(ra) # 8000388e <iunlockput>
    ip = next;
    80003cc2:	89e6                	mv	s3,s9
  while (*path == '/')
    80003cc4:	0004c783          	lbu	a5,0(s1)
    80003cc8:	05279763          	bne	a5,s2,80003d16 <namex+0x156>
    path++;
    80003ccc:	0485                	addi	s1,s1,1
  while (*path == '/')
    80003cce:	0004c783          	lbu	a5,0(s1)
    80003cd2:	ff278de3          	beq	a5,s2,80003ccc <namex+0x10c>
  if (*path == 0)
    80003cd6:	c79d                	beqz	a5,80003d04 <namex+0x144>
    path++;
    80003cd8:	85a6                	mv	a1,s1
  len = path - s;
    80003cda:	8cda                	mv	s9,s6
    80003cdc:	865a                	mv	a2,s6
  while (*path != '/' && *path != 0)
    80003cde:	01278963          	beq	a5,s2,80003cf0 <namex+0x130>
    80003ce2:	dfbd                	beqz	a5,80003c60 <namex+0xa0>
    path++;
    80003ce4:	0485                	addi	s1,s1,1
  while (*path != '/' && *path != 0)
    80003ce6:	0004c783          	lbu	a5,0(s1)
    80003cea:	ff279ce3          	bne	a5,s2,80003ce2 <namex+0x122>
    80003cee:	bf8d                	j	80003c60 <namex+0xa0>
    memmove(name, s, len);
    80003cf0:	2601                	sext.w	a2,a2
    80003cf2:	8552                	mv	a0,s4
    80003cf4:	ffffd097          	auipc	ra,0xffffd
    80003cf8:	03a080e7          	jalr	58(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003cfc:	9cd2                	add	s9,s9,s4
    80003cfe:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003d02:	bf9d                	j	80003c78 <namex+0xb8>
  if (nameiparent)
    80003d04:	f20a83e3          	beqz	s5,80003c2a <namex+0x6a>
    iput(ip);
    80003d08:	854e                	mv	a0,s3
    80003d0a:	00000097          	auipc	ra,0x0
    80003d0e:	adc080e7          	jalr	-1316(ra) # 800037e6 <iput>
    return 0;
    80003d12:	4981                	li	s3,0
    80003d14:	bf19                	j	80003c2a <namex+0x6a>
  if (*path == 0)
    80003d16:	d7fd                	beqz	a5,80003d04 <namex+0x144>
  while (*path != '/' && *path != 0)
    80003d18:	0004c783          	lbu	a5,0(s1)
    80003d1c:	85a6                	mv	a1,s1
    80003d1e:	b7d1                	j	80003ce2 <namex+0x122>

0000000080003d20 <dirlink>:
{
    80003d20:	7139                	addi	sp,sp,-64
    80003d22:	fc06                	sd	ra,56(sp)
    80003d24:	f822                	sd	s0,48(sp)
    80003d26:	f426                	sd	s1,40(sp)
    80003d28:	f04a                	sd	s2,32(sp)
    80003d2a:	ec4e                	sd	s3,24(sp)
    80003d2c:	e852                	sd	s4,16(sp)
    80003d2e:	0080                	addi	s0,sp,64
    80003d30:	892a                	mv	s2,a0
    80003d32:	8a2e                	mv	s4,a1
    80003d34:	89b2                	mv	s3,a2
  if ((ip = dirlookup(dp, name, 0)) != 0)
    80003d36:	4601                	li	a2,0
    80003d38:	00000097          	auipc	ra,0x0
    80003d3c:	dd8080e7          	jalr	-552(ra) # 80003b10 <dirlookup>
    80003d40:	e93d                	bnez	a0,80003db6 <dirlink+0x96>
  for (off = 0; off < dp->size; off += sizeof(de))
    80003d42:	04c92483          	lw	s1,76(s2)
    80003d46:	c49d                	beqz	s1,80003d74 <dirlink+0x54>
    80003d48:	4481                	li	s1,0
    if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d4a:	4741                	li	a4,16
    80003d4c:	86a6                	mv	a3,s1
    80003d4e:	fc040613          	addi	a2,s0,-64
    80003d52:	4581                	li	a1,0
    80003d54:	854a                	mv	a0,s2
    80003d56:	00000097          	auipc	ra,0x0
    80003d5a:	b8a080e7          	jalr	-1142(ra) # 800038e0 <readi>
    80003d5e:	47c1                	li	a5,16
    80003d60:	06f51163          	bne	a0,a5,80003dc2 <dirlink+0xa2>
    if (de.inum == 0)
    80003d64:	fc045783          	lhu	a5,-64(s0)
    80003d68:	c791                	beqz	a5,80003d74 <dirlink+0x54>
  for (off = 0; off < dp->size; off += sizeof(de))
    80003d6a:	24c1                	addiw	s1,s1,16
    80003d6c:	04c92783          	lw	a5,76(s2)
    80003d70:	fcf4ede3          	bltu	s1,a5,80003d4a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003d74:	4639                	li	a2,14
    80003d76:	85d2                	mv	a1,s4
    80003d78:	fc240513          	addi	a0,s0,-62
    80003d7c:	ffffd097          	auipc	ra,0xffffd
    80003d80:	062080e7          	jalr	98(ra) # 80000dde <strncpy>
  de.inum = inum;
    80003d84:	fd341023          	sh	s3,-64(s0)
  if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d88:	4741                	li	a4,16
    80003d8a:	86a6                	mv	a3,s1
    80003d8c:	fc040613          	addi	a2,s0,-64
    80003d90:	4581                	li	a1,0
    80003d92:	854a                	mv	a0,s2
    80003d94:	00000097          	auipc	ra,0x0
    80003d98:	c44080e7          	jalr	-956(ra) # 800039d8 <writei>
    80003d9c:	1541                	addi	a0,a0,-16
    80003d9e:	00a03533          	snez	a0,a0
    80003da2:	40a00533          	neg	a0,a0
}
    80003da6:	70e2                	ld	ra,56(sp)
    80003da8:	7442                	ld	s0,48(sp)
    80003daa:	74a2                	ld	s1,40(sp)
    80003dac:	7902                	ld	s2,32(sp)
    80003dae:	69e2                	ld	s3,24(sp)
    80003db0:	6a42                	ld	s4,16(sp)
    80003db2:	6121                	addi	sp,sp,64
    80003db4:	8082                	ret
    iput(ip);
    80003db6:	00000097          	auipc	ra,0x0
    80003dba:	a30080e7          	jalr	-1488(ra) # 800037e6 <iput>
    return -1;
    80003dbe:	557d                	li	a0,-1
    80003dc0:	b7dd                	j	80003da6 <dirlink+0x86>
      panic("dirlink read");
    80003dc2:	00005517          	auipc	a0,0x5
    80003dc6:	85650513          	addi	a0,a0,-1962 # 80008618 <syscalls+0x1c8>
    80003dca:	ffffc097          	auipc	ra,0xffffc
    80003dce:	774080e7          	jalr	1908(ra) # 8000053e <panic>

0000000080003dd2 <namei>:

struct inode *
namei(char *path)
{
    80003dd2:	1101                	addi	sp,sp,-32
    80003dd4:	ec06                	sd	ra,24(sp)
    80003dd6:	e822                	sd	s0,16(sp)
    80003dd8:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003dda:	fe040613          	addi	a2,s0,-32
    80003dde:	4581                	li	a1,0
    80003de0:	00000097          	auipc	ra,0x0
    80003de4:	de0080e7          	jalr	-544(ra) # 80003bc0 <namex>
}
    80003de8:	60e2                	ld	ra,24(sp)
    80003dea:	6442                	ld	s0,16(sp)
    80003dec:	6105                	addi	sp,sp,32
    80003dee:	8082                	ret

0000000080003df0 <nameiparent>:

struct inode *
nameiparent(char *path, char *name)
{
    80003df0:	1141                	addi	sp,sp,-16
    80003df2:	e406                	sd	ra,8(sp)
    80003df4:	e022                	sd	s0,0(sp)
    80003df6:	0800                	addi	s0,sp,16
    80003df8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003dfa:	4585                	li	a1,1
    80003dfc:	00000097          	auipc	ra,0x0
    80003e00:	dc4080e7          	jalr	-572(ra) # 80003bc0 <namex>
}
    80003e04:	60a2                	ld	ra,8(sp)
    80003e06:	6402                	ld	s0,0(sp)
    80003e08:	0141                	addi	sp,sp,16
    80003e0a:	8082                	ret

0000000080003e0c <itoa>:

#include "fcntl.h"
#define DIGITS 14

char *itoa(int i, char b[])
{
    80003e0c:	1101                	addi	sp,sp,-32
    80003e0e:	ec22                	sd	s0,24(sp)
    80003e10:	1000                	addi	s0,sp,32
    80003e12:	872a                	mv	a4,a0
    80003e14:	852e                	mv	a0,a1
  char const digit[] = "0123456789";
    80003e16:	00005797          	auipc	a5,0x5
    80003e1a:	81278793          	addi	a5,a5,-2030 # 80008628 <syscalls+0x1d8>
    80003e1e:	6394                	ld	a3,0(a5)
    80003e20:	fed43023          	sd	a3,-32(s0)
    80003e24:	0087d683          	lhu	a3,8(a5)
    80003e28:	fed41423          	sh	a3,-24(s0)
    80003e2c:	00a7c783          	lbu	a5,10(a5)
    80003e30:	fef40523          	sb	a5,-22(s0)
  char *p = b;
    80003e34:	87ae                	mv	a5,a1
  if (i < 0)
    80003e36:	02074b63          	bltz	a4,80003e6c <itoa+0x60>
  {
    *p++ = '-';
    i *= -1;
  }
  int shifter = i;
    80003e3a:	86ba                	mv	a3,a4
  do
  { // Move to where representation ends
    ++p;
    shifter = shifter / 10;
    80003e3c:	4629                	li	a2,10
    ++p;
    80003e3e:	0785                	addi	a5,a5,1
    shifter = shifter / 10;
    80003e40:	02c6c6bb          	divw	a3,a3,a2
  } while (shifter);
    80003e44:	feed                	bnez	a3,80003e3e <itoa+0x32>
  *p = '\0';
    80003e46:	00078023          	sb	zero,0(a5)
  do
  { // Move back, inserting digits as u go
    *--p = digit[i % 10];
    80003e4a:	4629                	li	a2,10
    80003e4c:	17fd                	addi	a5,a5,-1
    80003e4e:	02c766bb          	remw	a3,a4,a2
    80003e52:	ff040593          	addi	a1,s0,-16
    80003e56:	96ae                	add	a3,a3,a1
    80003e58:	ff06c683          	lbu	a3,-16(a3)
    80003e5c:	00d78023          	sb	a3,0(a5)
    i = i / 10;
    80003e60:	02c7473b          	divw	a4,a4,a2
  } while (i);
    80003e64:	f765                	bnez	a4,80003e4c <itoa+0x40>
  return b;
}
    80003e66:	6462                	ld	s0,24(sp)
    80003e68:	6105                	addi	sp,sp,32
    80003e6a:	8082                	ret
    *p++ = '-';
    80003e6c:	00158793          	addi	a5,a1,1
    80003e70:	02d00693          	li	a3,45
    80003e74:	00d58023          	sb	a3,0(a1)
    i *= -1;
    80003e78:	40e0073b          	negw	a4,a4
    80003e7c:	bf7d                	j	80003e3a <itoa+0x2e>

0000000080003e7e <removeSwapFile>:
// remove swap file of proc p;
int removeSwapFile(struct proc *p)
{
    80003e7e:	711d                	addi	sp,sp,-96
    80003e80:	ec86                	sd	ra,88(sp)
    80003e82:	e8a2                	sd	s0,80(sp)
    80003e84:	e4a6                	sd	s1,72(sp)
    80003e86:	e0ca                	sd	s2,64(sp)
    80003e88:	1080                	addi	s0,sp,96
    80003e8a:	84aa                	mv	s1,a0
  // path of proccess
  char path[DIGITS];
  memmove(path, "/.swap", 6);
    80003e8c:	4619                	li	a2,6
    80003e8e:	00004597          	auipc	a1,0x4
    80003e92:	7aa58593          	addi	a1,a1,1962 # 80008638 <syscalls+0x1e8>
    80003e96:	fd040513          	addi	a0,s0,-48
    80003e9a:	ffffd097          	auipc	ra,0xffffd
    80003e9e:	e94080e7          	jalr	-364(ra) # 80000d2e <memmove>
  itoa(p->pid, path + 6);
    80003ea2:	fd640593          	addi	a1,s0,-42
    80003ea6:	5888                	lw	a0,48(s1)
    80003ea8:	00000097          	auipc	ra,0x0
    80003eac:	f64080e7          	jalr	-156(ra) # 80003e0c <itoa>
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ];
  uint off;

  if (0 == p->swapFile)
    80003eb0:	1684b503          	ld	a0,360(s1)
    80003eb4:	16050763          	beqz	a0,80004022 <removeSwapFile+0x1a4>
  {
    return -1;
  }
  fileclose(p->swapFile);
    80003eb8:	00001097          	auipc	ra,0x1
    80003ebc:	914080e7          	jalr	-1772(ra) # 800047cc <fileclose>

  begin_op();
    80003ec0:	00000097          	auipc	ra,0x0
    80003ec4:	440080e7          	jalr	1088(ra) # 80004300 <begin_op>
  if ((dp = nameiparent(path, name)) == 0)
    80003ec8:	fb040593          	addi	a1,s0,-80
    80003ecc:	fd040513          	addi	a0,s0,-48
    80003ed0:	00000097          	auipc	ra,0x0
    80003ed4:	f20080e7          	jalr	-224(ra) # 80003df0 <nameiparent>
    80003ed8:	892a                	mv	s2,a0
    80003eda:	cd69                	beqz	a0,80003fb4 <removeSwapFile+0x136>
  {
    end_op();
    return -1;
  }

  ilock(dp);
    80003edc:	fffff097          	auipc	ra,0xfffff
    80003ee0:	750080e7          	jalr	1872(ra) # 8000362c <ilock>

  // Cannot unlink "." or "..".
  if (namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80003ee4:	00004597          	auipc	a1,0x4
    80003ee8:	75c58593          	addi	a1,a1,1884 # 80008640 <syscalls+0x1f0>
    80003eec:	fb040513          	addi	a0,s0,-80
    80003ef0:	00000097          	auipc	ra,0x0
    80003ef4:	c06080e7          	jalr	-1018(ra) # 80003af6 <namecmp>
    80003ef8:	c57d                	beqz	a0,80003fe6 <removeSwapFile+0x168>
    80003efa:	00004597          	auipc	a1,0x4
    80003efe:	74e58593          	addi	a1,a1,1870 # 80008648 <syscalls+0x1f8>
    80003f02:	fb040513          	addi	a0,s0,-80
    80003f06:	00000097          	auipc	ra,0x0
    80003f0a:	bf0080e7          	jalr	-1040(ra) # 80003af6 <namecmp>
    80003f0e:	cd61                	beqz	a0,80003fe6 <removeSwapFile+0x168>
    goto bad;

  if ((ip = dirlookup(dp, name, &off)) == 0)
    80003f10:	fac40613          	addi	a2,s0,-84
    80003f14:	fb040593          	addi	a1,s0,-80
    80003f18:	854a                	mv	a0,s2
    80003f1a:	00000097          	auipc	ra,0x0
    80003f1e:	bf6080e7          	jalr	-1034(ra) # 80003b10 <dirlookup>
    80003f22:	84aa                	mv	s1,a0
    80003f24:	c169                	beqz	a0,80003fe6 <removeSwapFile+0x168>
    goto bad;
  ilock(ip);
    80003f26:	fffff097          	auipc	ra,0xfffff
    80003f2a:	706080e7          	jalr	1798(ra) # 8000362c <ilock>

  if (ip->nlink < 1)
    80003f2e:	04a49783          	lh	a5,74(s1)
    80003f32:	08f05763          	blez	a5,80003fc0 <removeSwapFile+0x142>
    panic("unlink: nlink < 1");
  if (ip->type == T_DIR && !isdirempty(ip))
    80003f36:	04449703          	lh	a4,68(s1)
    80003f3a:	4785                	li	a5,1
    80003f3c:	08f70a63          	beq	a4,a5,80003fd0 <removeSwapFile+0x152>
  {
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    80003f40:	4641                	li	a2,16
    80003f42:	4581                	li	a1,0
    80003f44:	fc040513          	addi	a0,s0,-64
    80003f48:	ffffd097          	auipc	ra,0xffffd
    80003f4c:	d8a080e7          	jalr	-630(ra) # 80000cd2 <memset>
  if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f50:	4741                	li	a4,16
    80003f52:	fac42683          	lw	a3,-84(s0)
    80003f56:	fc040613          	addi	a2,s0,-64
    80003f5a:	4581                	li	a1,0
    80003f5c:	854a                	mv	a0,s2
    80003f5e:	00000097          	auipc	ra,0x0
    80003f62:	a7a080e7          	jalr	-1414(ra) # 800039d8 <writei>
    80003f66:	47c1                	li	a5,16
    80003f68:	08f51a63          	bne	a0,a5,80003ffc <removeSwapFile+0x17e>
    panic("unlink: writei");
  if (ip->type == T_DIR)
    80003f6c:	04449703          	lh	a4,68(s1)
    80003f70:	4785                	li	a5,1
    80003f72:	08f70d63          	beq	a4,a5,8000400c <removeSwapFile+0x18e>
  {
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    80003f76:	854a                	mv	a0,s2
    80003f78:	00000097          	auipc	ra,0x0
    80003f7c:	916080e7          	jalr	-1770(ra) # 8000388e <iunlockput>

  ip->nlink--;
    80003f80:	04a4d783          	lhu	a5,74(s1)
    80003f84:	37fd                	addiw	a5,a5,-1
    80003f86:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80003f8a:	8526                	mv	a0,s1
    80003f8c:	fffff097          	auipc	ra,0xfffff
    80003f90:	5d6080e7          	jalr	1494(ra) # 80003562 <iupdate>
  iunlockput(ip);
    80003f94:	8526                	mv	a0,s1
    80003f96:	00000097          	auipc	ra,0x0
    80003f9a:	8f8080e7          	jalr	-1800(ra) # 8000388e <iunlockput>

  end_op();
    80003f9e:	00000097          	auipc	ra,0x0
    80003fa2:	3e2080e7          	jalr	994(ra) # 80004380 <end_op>

  return 0;
    80003fa6:	4501                	li	a0,0

bad:
  iunlockput(dp);
  end_op();
  return -1;
}
    80003fa8:	60e6                	ld	ra,88(sp)
    80003faa:	6446                	ld	s0,80(sp)
    80003fac:	64a6                	ld	s1,72(sp)
    80003fae:	6906                	ld	s2,64(sp)
    80003fb0:	6125                	addi	sp,sp,96
    80003fb2:	8082                	ret
    end_op();
    80003fb4:	00000097          	auipc	ra,0x0
    80003fb8:	3cc080e7          	jalr	972(ra) # 80004380 <end_op>
    return -1;
    80003fbc:	557d                	li	a0,-1
    80003fbe:	b7ed                	j	80003fa8 <removeSwapFile+0x12a>
    panic("unlink: nlink < 1");
    80003fc0:	00004517          	auipc	a0,0x4
    80003fc4:	69050513          	addi	a0,a0,1680 # 80008650 <syscalls+0x200>
    80003fc8:	ffffc097          	auipc	ra,0xffffc
    80003fcc:	576080e7          	jalr	1398(ra) # 8000053e <panic>
  if (ip->type == T_DIR && !isdirempty(ip))
    80003fd0:	8526                	mv	a0,s1
    80003fd2:	00001097          	auipc	ra,0x1
    80003fd6:	7a8080e7          	jalr	1960(ra) # 8000577a <isdirempty>
    80003fda:	f13d                	bnez	a0,80003f40 <removeSwapFile+0xc2>
    iunlockput(ip);
    80003fdc:	8526                	mv	a0,s1
    80003fde:	00000097          	auipc	ra,0x0
    80003fe2:	8b0080e7          	jalr	-1872(ra) # 8000388e <iunlockput>
  iunlockput(dp);
    80003fe6:	854a                	mv	a0,s2
    80003fe8:	00000097          	auipc	ra,0x0
    80003fec:	8a6080e7          	jalr	-1882(ra) # 8000388e <iunlockput>
  end_op();
    80003ff0:	00000097          	auipc	ra,0x0
    80003ff4:	390080e7          	jalr	912(ra) # 80004380 <end_op>
  return -1;
    80003ff8:	557d                	li	a0,-1
    80003ffa:	b77d                	j	80003fa8 <removeSwapFile+0x12a>
    panic("unlink: writei");
    80003ffc:	00004517          	auipc	a0,0x4
    80004000:	66c50513          	addi	a0,a0,1644 # 80008668 <syscalls+0x218>
    80004004:	ffffc097          	auipc	ra,0xffffc
    80004008:	53a080e7          	jalr	1338(ra) # 8000053e <panic>
    dp->nlink--;
    8000400c:	04a95783          	lhu	a5,74(s2)
    80004010:	37fd                	addiw	a5,a5,-1
    80004012:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80004016:	854a                	mv	a0,s2
    80004018:	fffff097          	auipc	ra,0xfffff
    8000401c:	54a080e7          	jalr	1354(ra) # 80003562 <iupdate>
    80004020:	bf99                	j	80003f76 <removeSwapFile+0xf8>
    return -1;
    80004022:	557d                	li	a0,-1
    80004024:	b751                	j	80003fa8 <removeSwapFile+0x12a>

0000000080004026 <createSwapFile>:

// return 0 on success
int createSwapFile(struct proc *p)
{
    80004026:	7179                	addi	sp,sp,-48
    80004028:	f406                	sd	ra,40(sp)
    8000402a:	f022                	sd	s0,32(sp)
    8000402c:	ec26                	sd	s1,24(sp)
    8000402e:	e84a                	sd	s2,16(sp)
    80004030:	1800                	addi	s0,sp,48
    80004032:	84aa                	mv	s1,a0

  char path[DIGITS];
  memmove(path, "/.swap", 6);
    80004034:	4619                	li	a2,6
    80004036:	00004597          	auipc	a1,0x4
    8000403a:	60258593          	addi	a1,a1,1538 # 80008638 <syscalls+0x1e8>
    8000403e:	fd040513          	addi	a0,s0,-48
    80004042:	ffffd097          	auipc	ra,0xffffd
    80004046:	cec080e7          	jalr	-788(ra) # 80000d2e <memmove>
  itoa(p->pid, path + 6);
    8000404a:	fd640593          	addi	a1,s0,-42
    8000404e:	5888                	lw	a0,48(s1)
    80004050:	00000097          	auipc	ra,0x0
    80004054:	dbc080e7          	jalr	-580(ra) # 80003e0c <itoa>

  begin_op();
    80004058:	00000097          	auipc	ra,0x0
    8000405c:	2a8080e7          	jalr	680(ra) # 80004300 <begin_op>

  struct inode *in = create(path, T_FILE, 0, 0);
    80004060:	4681                	li	a3,0
    80004062:	4601                	li	a2,0
    80004064:	4589                	li	a1,2
    80004066:	fd040513          	addi	a0,s0,-48
    8000406a:	00002097          	auipc	ra,0x2
    8000406e:	904080e7          	jalr	-1788(ra) # 8000596e <create>
    80004072:	892a                	mv	s2,a0
  iunlock(in);
    80004074:	fffff097          	auipc	ra,0xfffff
    80004078:	67a080e7          	jalr	1658(ra) # 800036ee <iunlock>
  p->swapFile = filealloc();
    8000407c:	00000097          	auipc	ra,0x0
    80004080:	694080e7          	jalr	1684(ra) # 80004710 <filealloc>
    80004084:	16a4b423          	sd	a0,360(s1)
  if (p->swapFile == 0)
    80004088:	cd1d                	beqz	a0,800040c6 <createSwapFile+0xa0>
    panic("no slot for files on /store");

  p->swapFile->ip = in;
    8000408a:	01253c23          	sd	s2,24(a0)
  p->swapFile->type = FD_INODE;
    8000408e:	1684b703          	ld	a4,360(s1)
    80004092:	4789                	li	a5,2
    80004094:	c31c                	sw	a5,0(a4)
  p->swapFile->off = 0;
    80004096:	1684b703          	ld	a4,360(s1)
    8000409a:	02072023          	sw	zero,32(a4) # 43020 <_entry-0x7ffbcfe0>
  p->swapFile->readable = O_WRONLY;
    8000409e:	1684b703          	ld	a4,360(s1)
    800040a2:	4685                	li	a3,1
    800040a4:	00d70423          	sb	a3,8(a4)
  p->swapFile->writable = O_RDWR;
    800040a8:	1684b703          	ld	a4,360(s1)
    800040ac:	00f704a3          	sb	a5,9(a4)
  end_op();
    800040b0:	00000097          	auipc	ra,0x0
    800040b4:	2d0080e7          	jalr	720(ra) # 80004380 <end_op>

  return 0;
}
    800040b8:	4501                	li	a0,0
    800040ba:	70a2                	ld	ra,40(sp)
    800040bc:	7402                	ld	s0,32(sp)
    800040be:	64e2                	ld	s1,24(sp)
    800040c0:	6942                	ld	s2,16(sp)
    800040c2:	6145                	addi	sp,sp,48
    800040c4:	8082                	ret
    panic("no slot for files on /store");
    800040c6:	00004517          	auipc	a0,0x4
    800040ca:	5b250513          	addi	a0,a0,1458 # 80008678 <syscalls+0x228>
    800040ce:	ffffc097          	auipc	ra,0xffffc
    800040d2:	470080e7          	jalr	1136(ra) # 8000053e <panic>

00000000800040d6 <writeToSwapFile>:

// return as sys_write (-1 when error)
int writeToSwapFile(struct proc *p, char *buffer, uint placeOnFile, uint size)
{
    800040d6:	1141                	addi	sp,sp,-16
    800040d8:	e406                	sd	ra,8(sp)
    800040da:	e022                	sd	s0,0(sp)
    800040dc:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    800040de:	16853783          	ld	a5,360(a0)
    800040e2:	d390                	sw	a2,32(a5)
  return kfilewrite(p->swapFile, (uint64)buffer, size);
    800040e4:	8636                	mv	a2,a3
    800040e6:	16853503          	ld	a0,360(a0)
    800040ea:	00001097          	auipc	ra,0x1
    800040ee:	ad4080e7          	jalr	-1324(ra) # 80004bbe <kfilewrite>
}
    800040f2:	60a2                	ld	ra,8(sp)
    800040f4:	6402                	ld	s0,0(sp)
    800040f6:	0141                	addi	sp,sp,16
    800040f8:	8082                	ret

00000000800040fa <readFromSwapFile>:

// return as sys_read (-1 when error)
int readFromSwapFile(struct proc *p, char *buffer, uint placeOnFile, uint size)
{
    800040fa:	1141                	addi	sp,sp,-16
    800040fc:	e406                	sd	ra,8(sp)
    800040fe:	e022                	sd	s0,0(sp)
    80004100:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    80004102:	16853783          	ld	a5,360(a0)
    80004106:	d390                	sw	a2,32(a5)
  return kfileread(p->swapFile, (uint64)buffer, size);
    80004108:	8636                	mv	a2,a3
    8000410a:	16853503          	ld	a0,360(a0)
    8000410e:	00001097          	auipc	ra,0x1
    80004112:	9ee080e7          	jalr	-1554(ra) # 80004afc <kfileread>
    80004116:	60a2                	ld	ra,8(sp)
    80004118:	6402                	ld	s0,0(sp)
    8000411a:	0141                	addi	sp,sp,16
    8000411c:	8082                	ret

000000008000411e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000411e:	1101                	addi	sp,sp,-32
    80004120:	ec06                	sd	ra,24(sp)
    80004122:	e822                	sd	s0,16(sp)
    80004124:	e426                	sd	s1,8(sp)
    80004126:	e04a                	sd	s2,0(sp)
    80004128:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000412a:	0001d917          	auipc	s2,0x1d
    8000412e:	c3690913          	addi	s2,s2,-970 # 80020d60 <log>
    80004132:	01892583          	lw	a1,24(s2)
    80004136:	02892503          	lw	a0,40(s2)
    8000413a:	fffff097          	auipc	ra,0xfffff
    8000413e:	cd8080e7          	jalr	-808(ra) # 80002e12 <bread>
    80004142:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004144:	02c92683          	lw	a3,44(s2)
    80004148:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000414a:	02d05763          	blez	a3,80004178 <write_head+0x5a>
    8000414e:	0001d797          	auipc	a5,0x1d
    80004152:	c4278793          	addi	a5,a5,-958 # 80020d90 <log+0x30>
    80004156:	05c50713          	addi	a4,a0,92
    8000415a:	36fd                	addiw	a3,a3,-1
    8000415c:	1682                	slli	a3,a3,0x20
    8000415e:	9281                	srli	a3,a3,0x20
    80004160:	068a                	slli	a3,a3,0x2
    80004162:	0001d617          	auipc	a2,0x1d
    80004166:	c3260613          	addi	a2,a2,-974 # 80020d94 <log+0x34>
    8000416a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000416c:	4390                	lw	a2,0(a5)
    8000416e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004170:	0791                	addi	a5,a5,4
    80004172:	0711                	addi	a4,a4,4
    80004174:	fed79ce3          	bne	a5,a3,8000416c <write_head+0x4e>
  }
  bwrite(buf);
    80004178:	8526                	mv	a0,s1
    8000417a:	fffff097          	auipc	ra,0xfffff
    8000417e:	d8a080e7          	jalr	-630(ra) # 80002f04 <bwrite>
  brelse(buf);
    80004182:	8526                	mv	a0,s1
    80004184:	fffff097          	auipc	ra,0xfffff
    80004188:	dbe080e7          	jalr	-578(ra) # 80002f42 <brelse>
}
    8000418c:	60e2                	ld	ra,24(sp)
    8000418e:	6442                	ld	s0,16(sp)
    80004190:	64a2                	ld	s1,8(sp)
    80004192:	6902                	ld	s2,0(sp)
    80004194:	6105                	addi	sp,sp,32
    80004196:	8082                	ret

0000000080004198 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004198:	0001d797          	auipc	a5,0x1d
    8000419c:	bf47a783          	lw	a5,-1036(a5) # 80020d8c <log+0x2c>
    800041a0:	0af05d63          	blez	a5,8000425a <install_trans+0xc2>
{
    800041a4:	7139                	addi	sp,sp,-64
    800041a6:	fc06                	sd	ra,56(sp)
    800041a8:	f822                	sd	s0,48(sp)
    800041aa:	f426                	sd	s1,40(sp)
    800041ac:	f04a                	sd	s2,32(sp)
    800041ae:	ec4e                	sd	s3,24(sp)
    800041b0:	e852                	sd	s4,16(sp)
    800041b2:	e456                	sd	s5,8(sp)
    800041b4:	e05a                	sd	s6,0(sp)
    800041b6:	0080                	addi	s0,sp,64
    800041b8:	8b2a                	mv	s6,a0
    800041ba:	0001da97          	auipc	s5,0x1d
    800041be:	bd6a8a93          	addi	s5,s5,-1066 # 80020d90 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041c2:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041c4:	0001d997          	auipc	s3,0x1d
    800041c8:	b9c98993          	addi	s3,s3,-1124 # 80020d60 <log>
    800041cc:	a00d                	j	800041ee <install_trans+0x56>
    brelse(lbuf);
    800041ce:	854a                	mv	a0,s2
    800041d0:	fffff097          	auipc	ra,0xfffff
    800041d4:	d72080e7          	jalr	-654(ra) # 80002f42 <brelse>
    brelse(dbuf);
    800041d8:	8526                	mv	a0,s1
    800041da:	fffff097          	auipc	ra,0xfffff
    800041de:	d68080e7          	jalr	-664(ra) # 80002f42 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041e2:	2a05                	addiw	s4,s4,1
    800041e4:	0a91                	addi	s5,s5,4
    800041e6:	02c9a783          	lw	a5,44(s3)
    800041ea:	04fa5e63          	bge	s4,a5,80004246 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041ee:	0189a583          	lw	a1,24(s3)
    800041f2:	014585bb          	addw	a1,a1,s4
    800041f6:	2585                	addiw	a1,a1,1
    800041f8:	0289a503          	lw	a0,40(s3)
    800041fc:	fffff097          	auipc	ra,0xfffff
    80004200:	c16080e7          	jalr	-1002(ra) # 80002e12 <bread>
    80004204:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004206:	000aa583          	lw	a1,0(s5)
    8000420a:	0289a503          	lw	a0,40(s3)
    8000420e:	fffff097          	auipc	ra,0xfffff
    80004212:	c04080e7          	jalr	-1020(ra) # 80002e12 <bread>
    80004216:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004218:	40000613          	li	a2,1024
    8000421c:	05890593          	addi	a1,s2,88
    80004220:	05850513          	addi	a0,a0,88
    80004224:	ffffd097          	auipc	ra,0xffffd
    80004228:	b0a080e7          	jalr	-1270(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    8000422c:	8526                	mv	a0,s1
    8000422e:	fffff097          	auipc	ra,0xfffff
    80004232:	cd6080e7          	jalr	-810(ra) # 80002f04 <bwrite>
    if(recovering == 0)
    80004236:	f80b1ce3          	bnez	s6,800041ce <install_trans+0x36>
      bunpin(dbuf);
    8000423a:	8526                	mv	a0,s1
    8000423c:	fffff097          	auipc	ra,0xfffff
    80004240:	de0080e7          	jalr	-544(ra) # 8000301c <bunpin>
    80004244:	b769                	j	800041ce <install_trans+0x36>
}
    80004246:	70e2                	ld	ra,56(sp)
    80004248:	7442                	ld	s0,48(sp)
    8000424a:	74a2                	ld	s1,40(sp)
    8000424c:	7902                	ld	s2,32(sp)
    8000424e:	69e2                	ld	s3,24(sp)
    80004250:	6a42                	ld	s4,16(sp)
    80004252:	6aa2                	ld	s5,8(sp)
    80004254:	6b02                	ld	s6,0(sp)
    80004256:	6121                	addi	sp,sp,64
    80004258:	8082                	ret
    8000425a:	8082                	ret

000000008000425c <initlog>:
{
    8000425c:	7179                	addi	sp,sp,-48
    8000425e:	f406                	sd	ra,40(sp)
    80004260:	f022                	sd	s0,32(sp)
    80004262:	ec26                	sd	s1,24(sp)
    80004264:	e84a                	sd	s2,16(sp)
    80004266:	e44e                	sd	s3,8(sp)
    80004268:	1800                	addi	s0,sp,48
    8000426a:	892a                	mv	s2,a0
    8000426c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000426e:	0001d497          	auipc	s1,0x1d
    80004272:	af248493          	addi	s1,s1,-1294 # 80020d60 <log>
    80004276:	00004597          	auipc	a1,0x4
    8000427a:	42258593          	addi	a1,a1,1058 # 80008698 <syscalls+0x248>
    8000427e:	8526                	mv	a0,s1
    80004280:	ffffd097          	auipc	ra,0xffffd
    80004284:	8c6080e7          	jalr	-1850(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004288:	0149a583          	lw	a1,20(s3)
    8000428c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000428e:	0109a783          	lw	a5,16(s3)
    80004292:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004294:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004298:	854a                	mv	a0,s2
    8000429a:	fffff097          	auipc	ra,0xfffff
    8000429e:	b78080e7          	jalr	-1160(ra) # 80002e12 <bread>
  log.lh.n = lh->n;
    800042a2:	4d34                	lw	a3,88(a0)
    800042a4:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042a6:	02d05563          	blez	a3,800042d0 <initlog+0x74>
    800042aa:	05c50793          	addi	a5,a0,92
    800042ae:	0001d717          	auipc	a4,0x1d
    800042b2:	ae270713          	addi	a4,a4,-1310 # 80020d90 <log+0x30>
    800042b6:	36fd                	addiw	a3,a3,-1
    800042b8:	1682                	slli	a3,a3,0x20
    800042ba:	9281                	srli	a3,a3,0x20
    800042bc:	068a                	slli	a3,a3,0x2
    800042be:	06050613          	addi	a2,a0,96
    800042c2:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800042c4:	4390                	lw	a2,0(a5)
    800042c6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800042c8:	0791                	addi	a5,a5,4
    800042ca:	0711                	addi	a4,a4,4
    800042cc:	fed79ce3          	bne	a5,a3,800042c4 <initlog+0x68>
  brelse(buf);
    800042d0:	fffff097          	auipc	ra,0xfffff
    800042d4:	c72080e7          	jalr	-910(ra) # 80002f42 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800042d8:	4505                	li	a0,1
    800042da:	00000097          	auipc	ra,0x0
    800042de:	ebe080e7          	jalr	-322(ra) # 80004198 <install_trans>
  log.lh.n = 0;
    800042e2:	0001d797          	auipc	a5,0x1d
    800042e6:	aa07a523          	sw	zero,-1366(a5) # 80020d8c <log+0x2c>
  write_head(); // clear the log
    800042ea:	00000097          	auipc	ra,0x0
    800042ee:	e34080e7          	jalr	-460(ra) # 8000411e <write_head>
}
    800042f2:	70a2                	ld	ra,40(sp)
    800042f4:	7402                	ld	s0,32(sp)
    800042f6:	64e2                	ld	s1,24(sp)
    800042f8:	6942                	ld	s2,16(sp)
    800042fa:	69a2                	ld	s3,8(sp)
    800042fc:	6145                	addi	sp,sp,48
    800042fe:	8082                	ret

0000000080004300 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004300:	1101                	addi	sp,sp,-32
    80004302:	ec06                	sd	ra,24(sp)
    80004304:	e822                	sd	s0,16(sp)
    80004306:	e426                	sd	s1,8(sp)
    80004308:	e04a                	sd	s2,0(sp)
    8000430a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000430c:	0001d517          	auipc	a0,0x1d
    80004310:	a5450513          	addi	a0,a0,-1452 # 80020d60 <log>
    80004314:	ffffd097          	auipc	ra,0xffffd
    80004318:	8c2080e7          	jalr	-1854(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    8000431c:	0001d497          	auipc	s1,0x1d
    80004320:	a4448493          	addi	s1,s1,-1468 # 80020d60 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004324:	4979                	li	s2,30
    80004326:	a039                	j	80004334 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004328:	85a6                	mv	a1,s1
    8000432a:	8526                	mv	a0,s1
    8000432c:	ffffe097          	auipc	ra,0xffffe
    80004330:	d28080e7          	jalr	-728(ra) # 80002054 <sleep>
    if(log.committing){
    80004334:	50dc                	lw	a5,36(s1)
    80004336:	fbed                	bnez	a5,80004328 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004338:	509c                	lw	a5,32(s1)
    8000433a:	0017871b          	addiw	a4,a5,1
    8000433e:	0007069b          	sext.w	a3,a4
    80004342:	0027179b          	slliw	a5,a4,0x2
    80004346:	9fb9                	addw	a5,a5,a4
    80004348:	0017979b          	slliw	a5,a5,0x1
    8000434c:	54d8                	lw	a4,44(s1)
    8000434e:	9fb9                	addw	a5,a5,a4
    80004350:	00f95963          	bge	s2,a5,80004362 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004354:	85a6                	mv	a1,s1
    80004356:	8526                	mv	a0,s1
    80004358:	ffffe097          	auipc	ra,0xffffe
    8000435c:	cfc080e7          	jalr	-772(ra) # 80002054 <sleep>
    80004360:	bfd1                	j	80004334 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004362:	0001d517          	auipc	a0,0x1d
    80004366:	9fe50513          	addi	a0,a0,-1538 # 80020d60 <log>
    8000436a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000436c:	ffffd097          	auipc	ra,0xffffd
    80004370:	91e080e7          	jalr	-1762(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004374:	60e2                	ld	ra,24(sp)
    80004376:	6442                	ld	s0,16(sp)
    80004378:	64a2                	ld	s1,8(sp)
    8000437a:	6902                	ld	s2,0(sp)
    8000437c:	6105                	addi	sp,sp,32
    8000437e:	8082                	ret

0000000080004380 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004380:	7139                	addi	sp,sp,-64
    80004382:	fc06                	sd	ra,56(sp)
    80004384:	f822                	sd	s0,48(sp)
    80004386:	f426                	sd	s1,40(sp)
    80004388:	f04a                	sd	s2,32(sp)
    8000438a:	ec4e                	sd	s3,24(sp)
    8000438c:	e852                	sd	s4,16(sp)
    8000438e:	e456                	sd	s5,8(sp)
    80004390:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004392:	0001d497          	auipc	s1,0x1d
    80004396:	9ce48493          	addi	s1,s1,-1586 # 80020d60 <log>
    8000439a:	8526                	mv	a0,s1
    8000439c:	ffffd097          	auipc	ra,0xffffd
    800043a0:	83a080e7          	jalr	-1990(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800043a4:	509c                	lw	a5,32(s1)
    800043a6:	37fd                	addiw	a5,a5,-1
    800043a8:	0007891b          	sext.w	s2,a5
    800043ac:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043ae:	50dc                	lw	a5,36(s1)
    800043b0:	e7b9                	bnez	a5,800043fe <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043b2:	04091e63          	bnez	s2,8000440e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800043b6:	0001d497          	auipc	s1,0x1d
    800043ba:	9aa48493          	addi	s1,s1,-1622 # 80020d60 <log>
    800043be:	4785                	li	a5,1
    800043c0:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800043c2:	8526                	mv	a0,s1
    800043c4:	ffffd097          	auipc	ra,0xffffd
    800043c8:	8c6080e7          	jalr	-1850(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800043cc:	54dc                	lw	a5,44(s1)
    800043ce:	06f04763          	bgtz	a5,8000443c <end_op+0xbc>
    acquire(&log.lock);
    800043d2:	0001d497          	auipc	s1,0x1d
    800043d6:	98e48493          	addi	s1,s1,-1650 # 80020d60 <log>
    800043da:	8526                	mv	a0,s1
    800043dc:	ffffc097          	auipc	ra,0xffffc
    800043e0:	7fa080e7          	jalr	2042(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800043e4:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800043e8:	8526                	mv	a0,s1
    800043ea:	ffffe097          	auipc	ra,0xffffe
    800043ee:	cce080e7          	jalr	-818(ra) # 800020b8 <wakeup>
    release(&log.lock);
    800043f2:	8526                	mv	a0,s1
    800043f4:	ffffd097          	auipc	ra,0xffffd
    800043f8:	896080e7          	jalr	-1898(ra) # 80000c8a <release>
}
    800043fc:	a03d                	j	8000442a <end_op+0xaa>
    panic("log.committing");
    800043fe:	00004517          	auipc	a0,0x4
    80004402:	2a250513          	addi	a0,a0,674 # 800086a0 <syscalls+0x250>
    80004406:	ffffc097          	auipc	ra,0xffffc
    8000440a:	138080e7          	jalr	312(ra) # 8000053e <panic>
    wakeup(&log);
    8000440e:	0001d497          	auipc	s1,0x1d
    80004412:	95248493          	addi	s1,s1,-1710 # 80020d60 <log>
    80004416:	8526                	mv	a0,s1
    80004418:	ffffe097          	auipc	ra,0xffffe
    8000441c:	ca0080e7          	jalr	-864(ra) # 800020b8 <wakeup>
  release(&log.lock);
    80004420:	8526                	mv	a0,s1
    80004422:	ffffd097          	auipc	ra,0xffffd
    80004426:	868080e7          	jalr	-1944(ra) # 80000c8a <release>
}
    8000442a:	70e2                	ld	ra,56(sp)
    8000442c:	7442                	ld	s0,48(sp)
    8000442e:	74a2                	ld	s1,40(sp)
    80004430:	7902                	ld	s2,32(sp)
    80004432:	69e2                	ld	s3,24(sp)
    80004434:	6a42                	ld	s4,16(sp)
    80004436:	6aa2                	ld	s5,8(sp)
    80004438:	6121                	addi	sp,sp,64
    8000443a:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000443c:	0001da97          	auipc	s5,0x1d
    80004440:	954a8a93          	addi	s5,s5,-1708 # 80020d90 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004444:	0001da17          	auipc	s4,0x1d
    80004448:	91ca0a13          	addi	s4,s4,-1764 # 80020d60 <log>
    8000444c:	018a2583          	lw	a1,24(s4)
    80004450:	012585bb          	addw	a1,a1,s2
    80004454:	2585                	addiw	a1,a1,1
    80004456:	028a2503          	lw	a0,40(s4)
    8000445a:	fffff097          	auipc	ra,0xfffff
    8000445e:	9b8080e7          	jalr	-1608(ra) # 80002e12 <bread>
    80004462:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004464:	000aa583          	lw	a1,0(s5)
    80004468:	028a2503          	lw	a0,40(s4)
    8000446c:	fffff097          	auipc	ra,0xfffff
    80004470:	9a6080e7          	jalr	-1626(ra) # 80002e12 <bread>
    80004474:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004476:	40000613          	li	a2,1024
    8000447a:	05850593          	addi	a1,a0,88
    8000447e:	05848513          	addi	a0,s1,88
    80004482:	ffffd097          	auipc	ra,0xffffd
    80004486:	8ac080e7          	jalr	-1876(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    8000448a:	8526                	mv	a0,s1
    8000448c:	fffff097          	auipc	ra,0xfffff
    80004490:	a78080e7          	jalr	-1416(ra) # 80002f04 <bwrite>
    brelse(from);
    80004494:	854e                	mv	a0,s3
    80004496:	fffff097          	auipc	ra,0xfffff
    8000449a:	aac080e7          	jalr	-1364(ra) # 80002f42 <brelse>
    brelse(to);
    8000449e:	8526                	mv	a0,s1
    800044a0:	fffff097          	auipc	ra,0xfffff
    800044a4:	aa2080e7          	jalr	-1374(ra) # 80002f42 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044a8:	2905                	addiw	s2,s2,1
    800044aa:	0a91                	addi	s5,s5,4
    800044ac:	02ca2783          	lw	a5,44(s4)
    800044b0:	f8f94ee3          	blt	s2,a5,8000444c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044b4:	00000097          	auipc	ra,0x0
    800044b8:	c6a080e7          	jalr	-918(ra) # 8000411e <write_head>
    install_trans(0); // Now install writes to home locations
    800044bc:	4501                	li	a0,0
    800044be:	00000097          	auipc	ra,0x0
    800044c2:	cda080e7          	jalr	-806(ra) # 80004198 <install_trans>
    log.lh.n = 0;
    800044c6:	0001d797          	auipc	a5,0x1d
    800044ca:	8c07a323          	sw	zero,-1850(a5) # 80020d8c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800044ce:	00000097          	auipc	ra,0x0
    800044d2:	c50080e7          	jalr	-944(ra) # 8000411e <write_head>
    800044d6:	bdf5                	j	800043d2 <end_op+0x52>

00000000800044d8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800044d8:	1101                	addi	sp,sp,-32
    800044da:	ec06                	sd	ra,24(sp)
    800044dc:	e822                	sd	s0,16(sp)
    800044de:	e426                	sd	s1,8(sp)
    800044e0:	e04a                	sd	s2,0(sp)
    800044e2:	1000                	addi	s0,sp,32
    800044e4:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800044e6:	0001d917          	auipc	s2,0x1d
    800044ea:	87a90913          	addi	s2,s2,-1926 # 80020d60 <log>
    800044ee:	854a                	mv	a0,s2
    800044f0:	ffffc097          	auipc	ra,0xffffc
    800044f4:	6e6080e7          	jalr	1766(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800044f8:	02c92603          	lw	a2,44(s2)
    800044fc:	47f5                	li	a5,29
    800044fe:	06c7c563          	blt	a5,a2,80004568 <log_write+0x90>
    80004502:	0001d797          	auipc	a5,0x1d
    80004506:	87a7a783          	lw	a5,-1926(a5) # 80020d7c <log+0x1c>
    8000450a:	37fd                	addiw	a5,a5,-1
    8000450c:	04f65e63          	bge	a2,a5,80004568 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004510:	0001d797          	auipc	a5,0x1d
    80004514:	8707a783          	lw	a5,-1936(a5) # 80020d80 <log+0x20>
    80004518:	06f05063          	blez	a5,80004578 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000451c:	4781                	li	a5,0
    8000451e:	06c05563          	blez	a2,80004588 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004522:	44cc                	lw	a1,12(s1)
    80004524:	0001d717          	auipc	a4,0x1d
    80004528:	86c70713          	addi	a4,a4,-1940 # 80020d90 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000452c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000452e:	4314                	lw	a3,0(a4)
    80004530:	04b68c63          	beq	a3,a1,80004588 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004534:	2785                	addiw	a5,a5,1
    80004536:	0711                	addi	a4,a4,4
    80004538:	fef61be3          	bne	a2,a5,8000452e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000453c:	0621                	addi	a2,a2,8
    8000453e:	060a                	slli	a2,a2,0x2
    80004540:	0001d797          	auipc	a5,0x1d
    80004544:	82078793          	addi	a5,a5,-2016 # 80020d60 <log>
    80004548:	963e                	add	a2,a2,a5
    8000454a:	44dc                	lw	a5,12(s1)
    8000454c:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000454e:	8526                	mv	a0,s1
    80004550:	fffff097          	auipc	ra,0xfffff
    80004554:	a90080e7          	jalr	-1392(ra) # 80002fe0 <bpin>
    log.lh.n++;
    80004558:	0001d717          	auipc	a4,0x1d
    8000455c:	80870713          	addi	a4,a4,-2040 # 80020d60 <log>
    80004560:	575c                	lw	a5,44(a4)
    80004562:	2785                	addiw	a5,a5,1
    80004564:	d75c                	sw	a5,44(a4)
    80004566:	a835                	j	800045a2 <log_write+0xca>
    panic("too big a transaction");
    80004568:	00004517          	auipc	a0,0x4
    8000456c:	14850513          	addi	a0,a0,328 # 800086b0 <syscalls+0x260>
    80004570:	ffffc097          	auipc	ra,0xffffc
    80004574:	fce080e7          	jalr	-50(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004578:	00004517          	auipc	a0,0x4
    8000457c:	15050513          	addi	a0,a0,336 # 800086c8 <syscalls+0x278>
    80004580:	ffffc097          	auipc	ra,0xffffc
    80004584:	fbe080e7          	jalr	-66(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004588:	00878713          	addi	a4,a5,8
    8000458c:	00271693          	slli	a3,a4,0x2
    80004590:	0001c717          	auipc	a4,0x1c
    80004594:	7d070713          	addi	a4,a4,2000 # 80020d60 <log>
    80004598:	9736                	add	a4,a4,a3
    8000459a:	44d4                	lw	a3,12(s1)
    8000459c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000459e:	faf608e3          	beq	a2,a5,8000454e <log_write+0x76>
  }
  release(&log.lock);
    800045a2:	0001c517          	auipc	a0,0x1c
    800045a6:	7be50513          	addi	a0,a0,1982 # 80020d60 <log>
    800045aa:	ffffc097          	auipc	ra,0xffffc
    800045ae:	6e0080e7          	jalr	1760(ra) # 80000c8a <release>
}
    800045b2:	60e2                	ld	ra,24(sp)
    800045b4:	6442                	ld	s0,16(sp)
    800045b6:	64a2                	ld	s1,8(sp)
    800045b8:	6902                	ld	s2,0(sp)
    800045ba:	6105                	addi	sp,sp,32
    800045bc:	8082                	ret

00000000800045be <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800045be:	1101                	addi	sp,sp,-32
    800045c0:	ec06                	sd	ra,24(sp)
    800045c2:	e822                	sd	s0,16(sp)
    800045c4:	e426                	sd	s1,8(sp)
    800045c6:	e04a                	sd	s2,0(sp)
    800045c8:	1000                	addi	s0,sp,32
    800045ca:	84aa                	mv	s1,a0
    800045cc:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800045ce:	00004597          	auipc	a1,0x4
    800045d2:	11a58593          	addi	a1,a1,282 # 800086e8 <syscalls+0x298>
    800045d6:	0521                	addi	a0,a0,8
    800045d8:	ffffc097          	auipc	ra,0xffffc
    800045dc:	56e080e7          	jalr	1390(ra) # 80000b46 <initlock>
  lk->name = name;
    800045e0:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800045e4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045e8:	0204a423          	sw	zero,40(s1)
}
    800045ec:	60e2                	ld	ra,24(sp)
    800045ee:	6442                	ld	s0,16(sp)
    800045f0:	64a2                	ld	s1,8(sp)
    800045f2:	6902                	ld	s2,0(sp)
    800045f4:	6105                	addi	sp,sp,32
    800045f6:	8082                	ret

00000000800045f8 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800045f8:	1101                	addi	sp,sp,-32
    800045fa:	ec06                	sd	ra,24(sp)
    800045fc:	e822                	sd	s0,16(sp)
    800045fe:	e426                	sd	s1,8(sp)
    80004600:	e04a                	sd	s2,0(sp)
    80004602:	1000                	addi	s0,sp,32
    80004604:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004606:	00850913          	addi	s2,a0,8
    8000460a:	854a                	mv	a0,s2
    8000460c:	ffffc097          	auipc	ra,0xffffc
    80004610:	5ca080e7          	jalr	1482(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004614:	409c                	lw	a5,0(s1)
    80004616:	cb89                	beqz	a5,80004628 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004618:	85ca                	mv	a1,s2
    8000461a:	8526                	mv	a0,s1
    8000461c:	ffffe097          	auipc	ra,0xffffe
    80004620:	a38080e7          	jalr	-1480(ra) # 80002054 <sleep>
  while (lk->locked) {
    80004624:	409c                	lw	a5,0(s1)
    80004626:	fbed                	bnez	a5,80004618 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004628:	4785                	li	a5,1
    8000462a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000462c:	ffffd097          	auipc	ra,0xffffd
    80004630:	380080e7          	jalr	896(ra) # 800019ac <myproc>
    80004634:	591c                	lw	a5,48(a0)
    80004636:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004638:	854a                	mv	a0,s2
    8000463a:	ffffc097          	auipc	ra,0xffffc
    8000463e:	650080e7          	jalr	1616(ra) # 80000c8a <release>
}
    80004642:	60e2                	ld	ra,24(sp)
    80004644:	6442                	ld	s0,16(sp)
    80004646:	64a2                	ld	s1,8(sp)
    80004648:	6902                	ld	s2,0(sp)
    8000464a:	6105                	addi	sp,sp,32
    8000464c:	8082                	ret

000000008000464e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000464e:	1101                	addi	sp,sp,-32
    80004650:	ec06                	sd	ra,24(sp)
    80004652:	e822                	sd	s0,16(sp)
    80004654:	e426                	sd	s1,8(sp)
    80004656:	e04a                	sd	s2,0(sp)
    80004658:	1000                	addi	s0,sp,32
    8000465a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000465c:	00850913          	addi	s2,a0,8
    80004660:	854a                	mv	a0,s2
    80004662:	ffffc097          	auipc	ra,0xffffc
    80004666:	574080e7          	jalr	1396(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    8000466a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000466e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004672:	8526                	mv	a0,s1
    80004674:	ffffe097          	auipc	ra,0xffffe
    80004678:	a44080e7          	jalr	-1468(ra) # 800020b8 <wakeup>
  release(&lk->lk);
    8000467c:	854a                	mv	a0,s2
    8000467e:	ffffc097          	auipc	ra,0xffffc
    80004682:	60c080e7          	jalr	1548(ra) # 80000c8a <release>
}
    80004686:	60e2                	ld	ra,24(sp)
    80004688:	6442                	ld	s0,16(sp)
    8000468a:	64a2                	ld	s1,8(sp)
    8000468c:	6902                	ld	s2,0(sp)
    8000468e:	6105                	addi	sp,sp,32
    80004690:	8082                	ret

0000000080004692 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004692:	7179                	addi	sp,sp,-48
    80004694:	f406                	sd	ra,40(sp)
    80004696:	f022                	sd	s0,32(sp)
    80004698:	ec26                	sd	s1,24(sp)
    8000469a:	e84a                	sd	s2,16(sp)
    8000469c:	e44e                	sd	s3,8(sp)
    8000469e:	1800                	addi	s0,sp,48
    800046a0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046a2:	00850913          	addi	s2,a0,8
    800046a6:	854a                	mv	a0,s2
    800046a8:	ffffc097          	auipc	ra,0xffffc
    800046ac:	52e080e7          	jalr	1326(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046b0:	409c                	lw	a5,0(s1)
    800046b2:	ef99                	bnez	a5,800046d0 <holdingsleep+0x3e>
    800046b4:	4481                	li	s1,0
  release(&lk->lk);
    800046b6:	854a                	mv	a0,s2
    800046b8:	ffffc097          	auipc	ra,0xffffc
    800046bc:	5d2080e7          	jalr	1490(ra) # 80000c8a <release>
  return r;
}
    800046c0:	8526                	mv	a0,s1
    800046c2:	70a2                	ld	ra,40(sp)
    800046c4:	7402                	ld	s0,32(sp)
    800046c6:	64e2                	ld	s1,24(sp)
    800046c8:	6942                	ld	s2,16(sp)
    800046ca:	69a2                	ld	s3,8(sp)
    800046cc:	6145                	addi	sp,sp,48
    800046ce:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800046d0:	0284a983          	lw	s3,40(s1)
    800046d4:	ffffd097          	auipc	ra,0xffffd
    800046d8:	2d8080e7          	jalr	728(ra) # 800019ac <myproc>
    800046dc:	5904                	lw	s1,48(a0)
    800046de:	413484b3          	sub	s1,s1,s3
    800046e2:	0014b493          	seqz	s1,s1
    800046e6:	bfc1                	j	800046b6 <holdingsleep+0x24>

00000000800046e8 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800046e8:	1141                	addi	sp,sp,-16
    800046ea:	e406                	sd	ra,8(sp)
    800046ec:	e022                	sd	s0,0(sp)
    800046ee:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800046f0:	00004597          	auipc	a1,0x4
    800046f4:	00858593          	addi	a1,a1,8 # 800086f8 <syscalls+0x2a8>
    800046f8:	0001c517          	auipc	a0,0x1c
    800046fc:	7b050513          	addi	a0,a0,1968 # 80020ea8 <ftable>
    80004700:	ffffc097          	auipc	ra,0xffffc
    80004704:	446080e7          	jalr	1094(ra) # 80000b46 <initlock>
}
    80004708:	60a2                	ld	ra,8(sp)
    8000470a:	6402                	ld	s0,0(sp)
    8000470c:	0141                	addi	sp,sp,16
    8000470e:	8082                	ret

0000000080004710 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004710:	1101                	addi	sp,sp,-32
    80004712:	ec06                	sd	ra,24(sp)
    80004714:	e822                	sd	s0,16(sp)
    80004716:	e426                	sd	s1,8(sp)
    80004718:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000471a:	0001c517          	auipc	a0,0x1c
    8000471e:	78e50513          	addi	a0,a0,1934 # 80020ea8 <ftable>
    80004722:	ffffc097          	auipc	ra,0xffffc
    80004726:	4b4080e7          	jalr	1204(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000472a:	0001c497          	auipc	s1,0x1c
    8000472e:	79648493          	addi	s1,s1,1942 # 80020ec0 <ftable+0x18>
    80004732:	0001d717          	auipc	a4,0x1d
    80004736:	72e70713          	addi	a4,a4,1838 # 80021e60 <disk>
    if(f->ref == 0){
    8000473a:	40dc                	lw	a5,4(s1)
    8000473c:	cf99                	beqz	a5,8000475a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000473e:	02848493          	addi	s1,s1,40
    80004742:	fee49ce3          	bne	s1,a4,8000473a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004746:	0001c517          	auipc	a0,0x1c
    8000474a:	76250513          	addi	a0,a0,1890 # 80020ea8 <ftable>
    8000474e:	ffffc097          	auipc	ra,0xffffc
    80004752:	53c080e7          	jalr	1340(ra) # 80000c8a <release>
  return 0;
    80004756:	4481                	li	s1,0
    80004758:	a819                	j	8000476e <filealloc+0x5e>
      f->ref = 1;
    8000475a:	4785                	li	a5,1
    8000475c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000475e:	0001c517          	auipc	a0,0x1c
    80004762:	74a50513          	addi	a0,a0,1866 # 80020ea8 <ftable>
    80004766:	ffffc097          	auipc	ra,0xffffc
    8000476a:	524080e7          	jalr	1316(ra) # 80000c8a <release>
}
    8000476e:	8526                	mv	a0,s1
    80004770:	60e2                	ld	ra,24(sp)
    80004772:	6442                	ld	s0,16(sp)
    80004774:	64a2                	ld	s1,8(sp)
    80004776:	6105                	addi	sp,sp,32
    80004778:	8082                	ret

000000008000477a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000477a:	1101                	addi	sp,sp,-32
    8000477c:	ec06                	sd	ra,24(sp)
    8000477e:	e822                	sd	s0,16(sp)
    80004780:	e426                	sd	s1,8(sp)
    80004782:	1000                	addi	s0,sp,32
    80004784:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004786:	0001c517          	auipc	a0,0x1c
    8000478a:	72250513          	addi	a0,a0,1826 # 80020ea8 <ftable>
    8000478e:	ffffc097          	auipc	ra,0xffffc
    80004792:	448080e7          	jalr	1096(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004796:	40dc                	lw	a5,4(s1)
    80004798:	02f05263          	blez	a5,800047bc <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000479c:	2785                	addiw	a5,a5,1
    8000479e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047a0:	0001c517          	auipc	a0,0x1c
    800047a4:	70850513          	addi	a0,a0,1800 # 80020ea8 <ftable>
    800047a8:	ffffc097          	auipc	ra,0xffffc
    800047ac:	4e2080e7          	jalr	1250(ra) # 80000c8a <release>
  return f;
}
    800047b0:	8526                	mv	a0,s1
    800047b2:	60e2                	ld	ra,24(sp)
    800047b4:	6442                	ld	s0,16(sp)
    800047b6:	64a2                	ld	s1,8(sp)
    800047b8:	6105                	addi	sp,sp,32
    800047ba:	8082                	ret
    panic("filedup");
    800047bc:	00004517          	auipc	a0,0x4
    800047c0:	f4450513          	addi	a0,a0,-188 # 80008700 <syscalls+0x2b0>
    800047c4:	ffffc097          	auipc	ra,0xffffc
    800047c8:	d7a080e7          	jalr	-646(ra) # 8000053e <panic>

00000000800047cc <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800047cc:	7139                	addi	sp,sp,-64
    800047ce:	fc06                	sd	ra,56(sp)
    800047d0:	f822                	sd	s0,48(sp)
    800047d2:	f426                	sd	s1,40(sp)
    800047d4:	f04a                	sd	s2,32(sp)
    800047d6:	ec4e                	sd	s3,24(sp)
    800047d8:	e852                	sd	s4,16(sp)
    800047da:	e456                	sd	s5,8(sp)
    800047dc:	0080                	addi	s0,sp,64
    800047de:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800047e0:	0001c517          	auipc	a0,0x1c
    800047e4:	6c850513          	addi	a0,a0,1736 # 80020ea8 <ftable>
    800047e8:	ffffc097          	auipc	ra,0xffffc
    800047ec:	3ee080e7          	jalr	1006(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800047f0:	40dc                	lw	a5,4(s1)
    800047f2:	06f05163          	blez	a5,80004854 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800047f6:	37fd                	addiw	a5,a5,-1
    800047f8:	0007871b          	sext.w	a4,a5
    800047fc:	c0dc                	sw	a5,4(s1)
    800047fe:	06e04363          	bgtz	a4,80004864 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004802:	0004a903          	lw	s2,0(s1)
    80004806:	0094ca83          	lbu	s5,9(s1)
    8000480a:	0104ba03          	ld	s4,16(s1)
    8000480e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004812:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004816:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000481a:	0001c517          	auipc	a0,0x1c
    8000481e:	68e50513          	addi	a0,a0,1678 # 80020ea8 <ftable>
    80004822:	ffffc097          	auipc	ra,0xffffc
    80004826:	468080e7          	jalr	1128(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    8000482a:	4785                	li	a5,1
    8000482c:	04f90d63          	beq	s2,a5,80004886 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004830:	3979                	addiw	s2,s2,-2
    80004832:	4785                	li	a5,1
    80004834:	0527e063          	bltu	a5,s2,80004874 <fileclose+0xa8>
    begin_op();
    80004838:	00000097          	auipc	ra,0x0
    8000483c:	ac8080e7          	jalr	-1336(ra) # 80004300 <begin_op>
    iput(ff.ip);
    80004840:	854e                	mv	a0,s3
    80004842:	fffff097          	auipc	ra,0xfffff
    80004846:	fa4080e7          	jalr	-92(ra) # 800037e6 <iput>
    end_op();
    8000484a:	00000097          	auipc	ra,0x0
    8000484e:	b36080e7          	jalr	-1226(ra) # 80004380 <end_op>
    80004852:	a00d                	j	80004874 <fileclose+0xa8>
    panic("fileclose");
    80004854:	00004517          	auipc	a0,0x4
    80004858:	eb450513          	addi	a0,a0,-332 # 80008708 <syscalls+0x2b8>
    8000485c:	ffffc097          	auipc	ra,0xffffc
    80004860:	ce2080e7          	jalr	-798(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004864:	0001c517          	auipc	a0,0x1c
    80004868:	64450513          	addi	a0,a0,1604 # 80020ea8 <ftable>
    8000486c:	ffffc097          	auipc	ra,0xffffc
    80004870:	41e080e7          	jalr	1054(ra) # 80000c8a <release>
  }
}
    80004874:	70e2                	ld	ra,56(sp)
    80004876:	7442                	ld	s0,48(sp)
    80004878:	74a2                	ld	s1,40(sp)
    8000487a:	7902                	ld	s2,32(sp)
    8000487c:	69e2                	ld	s3,24(sp)
    8000487e:	6a42                	ld	s4,16(sp)
    80004880:	6aa2                	ld	s5,8(sp)
    80004882:	6121                	addi	sp,sp,64
    80004884:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004886:	85d6                	mv	a1,s5
    80004888:	8552                	mv	a0,s4
    8000488a:	00000097          	auipc	ra,0x0
    8000488e:	542080e7          	jalr	1346(ra) # 80004dcc <pipeclose>
    80004892:	b7cd                	j	80004874 <fileclose+0xa8>

0000000080004894 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004894:	715d                	addi	sp,sp,-80
    80004896:	e486                	sd	ra,72(sp)
    80004898:	e0a2                	sd	s0,64(sp)
    8000489a:	fc26                	sd	s1,56(sp)
    8000489c:	f84a                	sd	s2,48(sp)
    8000489e:	f44e                	sd	s3,40(sp)
    800048a0:	0880                	addi	s0,sp,80
    800048a2:	84aa                	mv	s1,a0
    800048a4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048a6:	ffffd097          	auipc	ra,0xffffd
    800048aa:	106080e7          	jalr	262(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048ae:	409c                	lw	a5,0(s1)
    800048b0:	37f9                	addiw	a5,a5,-2
    800048b2:	4705                	li	a4,1
    800048b4:	04f76763          	bltu	a4,a5,80004902 <filestat+0x6e>
    800048b8:	892a                	mv	s2,a0
    ilock(f->ip);
    800048ba:	6c88                	ld	a0,24(s1)
    800048bc:	fffff097          	auipc	ra,0xfffff
    800048c0:	d70080e7          	jalr	-656(ra) # 8000362c <ilock>
    stati(f->ip, &st);
    800048c4:	fb840593          	addi	a1,s0,-72
    800048c8:	6c88                	ld	a0,24(s1)
    800048ca:	fffff097          	auipc	ra,0xfffff
    800048ce:	fec080e7          	jalr	-20(ra) # 800038b6 <stati>
    iunlock(f->ip);
    800048d2:	6c88                	ld	a0,24(s1)
    800048d4:	fffff097          	auipc	ra,0xfffff
    800048d8:	e1a080e7          	jalr	-486(ra) # 800036ee <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800048dc:	46e1                	li	a3,24
    800048de:	fb840613          	addi	a2,s0,-72
    800048e2:	85ce                	mv	a1,s3
    800048e4:	05093503          	ld	a0,80(s2)
    800048e8:	ffffd097          	auipc	ra,0xffffd
    800048ec:	d80080e7          	jalr	-640(ra) # 80001668 <copyout>
    800048f0:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800048f4:	60a6                	ld	ra,72(sp)
    800048f6:	6406                	ld	s0,64(sp)
    800048f8:	74e2                	ld	s1,56(sp)
    800048fa:	7942                	ld	s2,48(sp)
    800048fc:	79a2                	ld	s3,40(sp)
    800048fe:	6161                	addi	sp,sp,80
    80004900:	8082                	ret
  return -1;
    80004902:	557d                	li	a0,-1
    80004904:	bfc5                	j	800048f4 <filestat+0x60>

0000000080004906 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004906:	7179                	addi	sp,sp,-48
    80004908:	f406                	sd	ra,40(sp)
    8000490a:	f022                	sd	s0,32(sp)
    8000490c:	ec26                	sd	s1,24(sp)
    8000490e:	e84a                	sd	s2,16(sp)
    80004910:	e44e                	sd	s3,8(sp)
    80004912:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004914:	00854783          	lbu	a5,8(a0)
    80004918:	c3d5                	beqz	a5,800049bc <fileread+0xb6>
    8000491a:	84aa                	mv	s1,a0
    8000491c:	89ae                	mv	s3,a1
    8000491e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004920:	411c                	lw	a5,0(a0)
    80004922:	4705                	li	a4,1
    80004924:	04e78963          	beq	a5,a4,80004976 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004928:	470d                	li	a4,3
    8000492a:	04e78d63          	beq	a5,a4,80004984 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000492e:	4709                	li	a4,2
    80004930:	06e79e63          	bne	a5,a4,800049ac <fileread+0xa6>
    ilock(f->ip);
    80004934:	6d08                	ld	a0,24(a0)
    80004936:	fffff097          	auipc	ra,0xfffff
    8000493a:	cf6080e7          	jalr	-778(ra) # 8000362c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000493e:	874a                	mv	a4,s2
    80004940:	5094                	lw	a3,32(s1)
    80004942:	864e                	mv	a2,s3
    80004944:	4585                	li	a1,1
    80004946:	6c88                	ld	a0,24(s1)
    80004948:	fffff097          	auipc	ra,0xfffff
    8000494c:	f98080e7          	jalr	-104(ra) # 800038e0 <readi>
    80004950:	892a                	mv	s2,a0
    80004952:	00a05563          	blez	a0,8000495c <fileread+0x56>
      f->off += r;
    80004956:	509c                	lw	a5,32(s1)
    80004958:	9fa9                	addw	a5,a5,a0
    8000495a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000495c:	6c88                	ld	a0,24(s1)
    8000495e:	fffff097          	auipc	ra,0xfffff
    80004962:	d90080e7          	jalr	-624(ra) # 800036ee <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004966:	854a                	mv	a0,s2
    80004968:	70a2                	ld	ra,40(sp)
    8000496a:	7402                	ld	s0,32(sp)
    8000496c:	64e2                	ld	s1,24(sp)
    8000496e:	6942                	ld	s2,16(sp)
    80004970:	69a2                	ld	s3,8(sp)
    80004972:	6145                	addi	sp,sp,48
    80004974:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004976:	6908                	ld	a0,16(a0)
    80004978:	00000097          	auipc	ra,0x0
    8000497c:	5bc080e7          	jalr	1468(ra) # 80004f34 <piperead>
    80004980:	892a                	mv	s2,a0
    80004982:	b7d5                	j	80004966 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004984:	02451783          	lh	a5,36(a0)
    80004988:	03079693          	slli	a3,a5,0x30
    8000498c:	92c1                	srli	a3,a3,0x30
    8000498e:	4725                	li	a4,9
    80004990:	02d76863          	bltu	a4,a3,800049c0 <fileread+0xba>
    80004994:	0792                	slli	a5,a5,0x4
    80004996:	0001c717          	auipc	a4,0x1c
    8000499a:	47270713          	addi	a4,a4,1138 # 80020e08 <devsw>
    8000499e:	97ba                	add	a5,a5,a4
    800049a0:	639c                	ld	a5,0(a5)
    800049a2:	c38d                	beqz	a5,800049c4 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049a4:	4505                	li	a0,1
    800049a6:	9782                	jalr	a5
    800049a8:	892a                	mv	s2,a0
    800049aa:	bf75                	j	80004966 <fileread+0x60>
    panic("fileread");
    800049ac:	00004517          	auipc	a0,0x4
    800049b0:	d6c50513          	addi	a0,a0,-660 # 80008718 <syscalls+0x2c8>
    800049b4:	ffffc097          	auipc	ra,0xffffc
    800049b8:	b8a080e7          	jalr	-1142(ra) # 8000053e <panic>
    return -1;
    800049bc:	597d                	li	s2,-1
    800049be:	b765                	j	80004966 <fileread+0x60>
      return -1;
    800049c0:	597d                	li	s2,-1
    800049c2:	b755                	j	80004966 <fileread+0x60>
    800049c4:	597d                	li	s2,-1
    800049c6:	b745                	j	80004966 <fileread+0x60>

00000000800049c8 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800049c8:	715d                	addi	sp,sp,-80
    800049ca:	e486                	sd	ra,72(sp)
    800049cc:	e0a2                	sd	s0,64(sp)
    800049ce:	fc26                	sd	s1,56(sp)
    800049d0:	f84a                	sd	s2,48(sp)
    800049d2:	f44e                	sd	s3,40(sp)
    800049d4:	f052                	sd	s4,32(sp)
    800049d6:	ec56                	sd	s5,24(sp)
    800049d8:	e85a                	sd	s6,16(sp)
    800049da:	e45e                	sd	s7,8(sp)
    800049dc:	e062                	sd	s8,0(sp)
    800049de:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800049e0:	00954783          	lbu	a5,9(a0)
    800049e4:	10078663          	beqz	a5,80004af0 <filewrite+0x128>
    800049e8:	892a                	mv	s2,a0
    800049ea:	8aae                	mv	s5,a1
    800049ec:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800049ee:	411c                	lw	a5,0(a0)
    800049f0:	4705                	li	a4,1
    800049f2:	02e78263          	beq	a5,a4,80004a16 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049f6:	470d                	li	a4,3
    800049f8:	02e78663          	beq	a5,a4,80004a24 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800049fc:	4709                	li	a4,2
    800049fe:	0ee79163          	bne	a5,a4,80004ae0 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a02:	0ac05d63          	blez	a2,80004abc <filewrite+0xf4>
    int i = 0;
    80004a06:	4981                	li	s3,0
    80004a08:	6b05                	lui	s6,0x1
    80004a0a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a0e:	6b85                	lui	s7,0x1
    80004a10:	c00b8b9b          	addiw	s7,s7,-1024
    80004a14:	a861                	j	80004aac <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004a16:	6908                	ld	a0,16(a0)
    80004a18:	00000097          	auipc	ra,0x0
    80004a1c:	424080e7          	jalr	1060(ra) # 80004e3c <pipewrite>
    80004a20:	8a2a                	mv	s4,a0
    80004a22:	a045                	j	80004ac2 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a24:	02451783          	lh	a5,36(a0)
    80004a28:	03079693          	slli	a3,a5,0x30
    80004a2c:	92c1                	srli	a3,a3,0x30
    80004a2e:	4725                	li	a4,9
    80004a30:	0cd76263          	bltu	a4,a3,80004af4 <filewrite+0x12c>
    80004a34:	0792                	slli	a5,a5,0x4
    80004a36:	0001c717          	auipc	a4,0x1c
    80004a3a:	3d270713          	addi	a4,a4,978 # 80020e08 <devsw>
    80004a3e:	97ba                	add	a5,a5,a4
    80004a40:	679c                	ld	a5,8(a5)
    80004a42:	cbdd                	beqz	a5,80004af8 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a44:	4505                	li	a0,1
    80004a46:	9782                	jalr	a5
    80004a48:	8a2a                	mv	s4,a0
    80004a4a:	a8a5                	j	80004ac2 <filewrite+0xfa>
    80004a4c:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a50:	00000097          	auipc	ra,0x0
    80004a54:	8b0080e7          	jalr	-1872(ra) # 80004300 <begin_op>
      ilock(f->ip);
    80004a58:	01893503          	ld	a0,24(s2)
    80004a5c:	fffff097          	auipc	ra,0xfffff
    80004a60:	bd0080e7          	jalr	-1072(ra) # 8000362c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a64:	8762                	mv	a4,s8
    80004a66:	02092683          	lw	a3,32(s2)
    80004a6a:	01598633          	add	a2,s3,s5
    80004a6e:	4585                	li	a1,1
    80004a70:	01893503          	ld	a0,24(s2)
    80004a74:	fffff097          	auipc	ra,0xfffff
    80004a78:	f64080e7          	jalr	-156(ra) # 800039d8 <writei>
    80004a7c:	84aa                	mv	s1,a0
    80004a7e:	00a05763          	blez	a0,80004a8c <filewrite+0xc4>
        f->off += r;
    80004a82:	02092783          	lw	a5,32(s2)
    80004a86:	9fa9                	addw	a5,a5,a0
    80004a88:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a8c:	01893503          	ld	a0,24(s2)
    80004a90:	fffff097          	auipc	ra,0xfffff
    80004a94:	c5e080e7          	jalr	-930(ra) # 800036ee <iunlock>
      end_op();
    80004a98:	00000097          	auipc	ra,0x0
    80004a9c:	8e8080e7          	jalr	-1816(ra) # 80004380 <end_op>

      if(r != n1){
    80004aa0:	009c1f63          	bne	s8,s1,80004abe <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004aa4:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004aa8:	0149db63          	bge	s3,s4,80004abe <filewrite+0xf6>
      int n1 = n - i;
    80004aac:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004ab0:	84be                	mv	s1,a5
    80004ab2:	2781                	sext.w	a5,a5
    80004ab4:	f8fb5ce3          	bge	s6,a5,80004a4c <filewrite+0x84>
    80004ab8:	84de                	mv	s1,s7
    80004aba:	bf49                	j	80004a4c <filewrite+0x84>
    int i = 0;
    80004abc:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004abe:	013a1f63          	bne	s4,s3,80004adc <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ac2:	8552                	mv	a0,s4
    80004ac4:	60a6                	ld	ra,72(sp)
    80004ac6:	6406                	ld	s0,64(sp)
    80004ac8:	74e2                	ld	s1,56(sp)
    80004aca:	7942                	ld	s2,48(sp)
    80004acc:	79a2                	ld	s3,40(sp)
    80004ace:	7a02                	ld	s4,32(sp)
    80004ad0:	6ae2                	ld	s5,24(sp)
    80004ad2:	6b42                	ld	s6,16(sp)
    80004ad4:	6ba2                	ld	s7,8(sp)
    80004ad6:	6c02                	ld	s8,0(sp)
    80004ad8:	6161                	addi	sp,sp,80
    80004ada:	8082                	ret
    ret = (i == n ? n : -1);
    80004adc:	5a7d                	li	s4,-1
    80004ade:	b7d5                	j	80004ac2 <filewrite+0xfa>
    panic("filewrite");
    80004ae0:	00004517          	auipc	a0,0x4
    80004ae4:	c4850513          	addi	a0,a0,-952 # 80008728 <syscalls+0x2d8>
    80004ae8:	ffffc097          	auipc	ra,0xffffc
    80004aec:	a56080e7          	jalr	-1450(ra) # 8000053e <panic>
    return -1;
    80004af0:	5a7d                	li	s4,-1
    80004af2:	bfc1                	j	80004ac2 <filewrite+0xfa>
      return -1;
    80004af4:	5a7d                	li	s4,-1
    80004af6:	b7f1                	j	80004ac2 <filewrite+0xfa>
    80004af8:	5a7d                	li	s4,-1
    80004afa:	b7e1                	j	80004ac2 <filewrite+0xfa>

0000000080004afc <kfileread>:

// Read from file f.
// addr is a kernel virtual address.
int
kfileread(struct file *f, uint64 addr, int n)
{
    80004afc:	7179                	addi	sp,sp,-48
    80004afe:	f406                	sd	ra,40(sp)
    80004b00:	f022                	sd	s0,32(sp)
    80004b02:	ec26                	sd	s1,24(sp)
    80004b04:	e84a                	sd	s2,16(sp)
    80004b06:	e44e                	sd	s3,8(sp)
    80004b08:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b0a:	00854783          	lbu	a5,8(a0)
    80004b0e:	c3d5                	beqz	a5,80004bb2 <kfileread+0xb6>
    80004b10:	84aa                	mv	s1,a0
    80004b12:	89ae                	mv	s3,a1
    80004b14:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b16:	411c                	lw	a5,0(a0)
    80004b18:	4705                	li	a4,1
    80004b1a:	04e78963          	beq	a5,a4,80004b6c <kfileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b1e:	470d                	li	a4,3
    80004b20:	04e78d63          	beq	a5,a4,80004b7a <kfileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b24:	4709                	li	a4,2
    80004b26:	06e79e63          	bne	a5,a4,80004ba2 <kfileread+0xa6>
    ilock(f->ip);
    80004b2a:	6d08                	ld	a0,24(a0)
    80004b2c:	fffff097          	auipc	ra,0xfffff
    80004b30:	b00080e7          	jalr	-1280(ra) # 8000362c <ilock>
    if((r = readi(f->ip, 0, addr, f->off, n)) > 0)
    80004b34:	874a                	mv	a4,s2
    80004b36:	5094                	lw	a3,32(s1)
    80004b38:	864e                	mv	a2,s3
    80004b3a:	4581                	li	a1,0
    80004b3c:	6c88                	ld	a0,24(s1)
    80004b3e:	fffff097          	auipc	ra,0xfffff
    80004b42:	da2080e7          	jalr	-606(ra) # 800038e0 <readi>
    80004b46:	892a                	mv	s2,a0
    80004b48:	00a05563          	blez	a0,80004b52 <kfileread+0x56>
      f->off += r;
    80004b4c:	509c                	lw	a5,32(s1)
    80004b4e:	9fa9                	addw	a5,a5,a0
    80004b50:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004b52:	6c88                	ld	a0,24(s1)
    80004b54:	fffff097          	auipc	ra,0xfffff
    80004b58:	b9a080e7          	jalr	-1126(ra) # 800036ee <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004b5c:	854a                	mv	a0,s2
    80004b5e:	70a2                	ld	ra,40(sp)
    80004b60:	7402                	ld	s0,32(sp)
    80004b62:	64e2                	ld	s1,24(sp)
    80004b64:	6942                	ld	s2,16(sp)
    80004b66:	69a2                	ld	s3,8(sp)
    80004b68:	6145                	addi	sp,sp,48
    80004b6a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004b6c:	6908                	ld	a0,16(a0)
    80004b6e:	00000097          	auipc	ra,0x0
    80004b72:	3c6080e7          	jalr	966(ra) # 80004f34 <piperead>
    80004b76:	892a                	mv	s2,a0
    80004b78:	b7d5                	j	80004b5c <kfileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b7a:	02451783          	lh	a5,36(a0)
    80004b7e:	03079693          	slli	a3,a5,0x30
    80004b82:	92c1                	srli	a3,a3,0x30
    80004b84:	4725                	li	a4,9
    80004b86:	02d76863          	bltu	a4,a3,80004bb6 <kfileread+0xba>
    80004b8a:	0792                	slli	a5,a5,0x4
    80004b8c:	0001c717          	auipc	a4,0x1c
    80004b90:	27c70713          	addi	a4,a4,636 # 80020e08 <devsw>
    80004b94:	97ba                	add	a5,a5,a4
    80004b96:	639c                	ld	a5,0(a5)
    80004b98:	c38d                	beqz	a5,80004bba <kfileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004b9a:	4505                	li	a0,1
    80004b9c:	9782                	jalr	a5
    80004b9e:	892a                	mv	s2,a0
    80004ba0:	bf75                	j	80004b5c <kfileread+0x60>
    panic("fileread");
    80004ba2:	00004517          	auipc	a0,0x4
    80004ba6:	b7650513          	addi	a0,a0,-1162 # 80008718 <syscalls+0x2c8>
    80004baa:	ffffc097          	auipc	ra,0xffffc
    80004bae:	994080e7          	jalr	-1644(ra) # 8000053e <panic>
    return -1;
    80004bb2:	597d                	li	s2,-1
    80004bb4:	b765                	j	80004b5c <kfileread+0x60>
      return -1;
    80004bb6:	597d                	li	s2,-1
    80004bb8:	b755                	j	80004b5c <kfileread+0x60>
    80004bba:	597d                	li	s2,-1
    80004bbc:	b745                	j	80004b5c <kfileread+0x60>

0000000080004bbe <kfilewrite>:

// Write to file f.
// addr is a kernel virtual address.
int
kfilewrite(struct file *f, uint64 addr, int n)
{
    80004bbe:	715d                	addi	sp,sp,-80
    80004bc0:	e486                	sd	ra,72(sp)
    80004bc2:	e0a2                	sd	s0,64(sp)
    80004bc4:	fc26                	sd	s1,56(sp)
    80004bc6:	f84a                	sd	s2,48(sp)
    80004bc8:	f44e                	sd	s3,40(sp)
    80004bca:	f052                	sd	s4,32(sp)
    80004bcc:	ec56                	sd	s5,24(sp)
    80004bce:	e85a                	sd	s6,16(sp)
    80004bd0:	e45e                	sd	s7,8(sp)
    80004bd2:	e062                	sd	s8,0(sp)
    80004bd4:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004bd6:	00954783          	lbu	a5,9(a0)
    80004bda:	10078663          	beqz	a5,80004ce6 <kfilewrite+0x128>
    80004bde:	892a                	mv	s2,a0
    80004be0:	8aae                	mv	s5,a1
    80004be2:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004be4:	411c                	lw	a5,0(a0)
    80004be6:	4705                	li	a4,1
    80004be8:	02e78263          	beq	a5,a4,80004c0c <kfilewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004bec:	470d                	li	a4,3
    80004bee:	02e78663          	beq	a5,a4,80004c1a <kfilewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004bf2:	4709                	li	a4,2
    80004bf4:	0ee79163          	bne	a5,a4,80004cd6 <kfilewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004bf8:	0ac05d63          	blez	a2,80004cb2 <kfilewrite+0xf4>
    int i = 0;
    80004bfc:	4981                	li	s3,0
    80004bfe:	6b05                	lui	s6,0x1
    80004c00:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004c04:	6b85                	lui	s7,0x1
    80004c06:	c00b8b9b          	addiw	s7,s7,-1024
    80004c0a:	a861                	j	80004ca2 <kfilewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004c0c:	6908                	ld	a0,16(a0)
    80004c0e:	00000097          	auipc	ra,0x0
    80004c12:	22e080e7          	jalr	558(ra) # 80004e3c <pipewrite>
    80004c16:	8a2a                	mv	s4,a0
    80004c18:	a045                	j	80004cb8 <kfilewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c1a:	02451783          	lh	a5,36(a0)
    80004c1e:	03079693          	slli	a3,a5,0x30
    80004c22:	92c1                	srli	a3,a3,0x30
    80004c24:	4725                	li	a4,9
    80004c26:	0cd76263          	bltu	a4,a3,80004cea <kfilewrite+0x12c>
    80004c2a:	0792                	slli	a5,a5,0x4
    80004c2c:	0001c717          	auipc	a4,0x1c
    80004c30:	1dc70713          	addi	a4,a4,476 # 80020e08 <devsw>
    80004c34:	97ba                	add	a5,a5,a4
    80004c36:	679c                	ld	a5,8(a5)
    80004c38:	cbdd                	beqz	a5,80004cee <kfilewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004c3a:	4505                	li	a0,1
    80004c3c:	9782                	jalr	a5
    80004c3e:	8a2a                	mv	s4,a0
    80004c40:	a8a5                	j	80004cb8 <kfilewrite+0xfa>
    80004c42:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004c46:	fffff097          	auipc	ra,0xfffff
    80004c4a:	6ba080e7          	jalr	1722(ra) # 80004300 <begin_op>
      ilock(f->ip);
    80004c4e:	01893503          	ld	a0,24(s2)
    80004c52:	fffff097          	auipc	ra,0xfffff
    80004c56:	9da080e7          	jalr	-1574(ra) # 8000362c <ilock>
      if ((r = writei(f->ip, 0, addr + i, f->off, n1)) > 0)
    80004c5a:	8762                	mv	a4,s8
    80004c5c:	02092683          	lw	a3,32(s2)
    80004c60:	01598633          	add	a2,s3,s5
    80004c64:	4581                	li	a1,0
    80004c66:	01893503          	ld	a0,24(s2)
    80004c6a:	fffff097          	auipc	ra,0xfffff
    80004c6e:	d6e080e7          	jalr	-658(ra) # 800039d8 <writei>
    80004c72:	84aa                	mv	s1,a0
    80004c74:	00a05763          	blez	a0,80004c82 <kfilewrite+0xc4>
        f->off += r;
    80004c78:	02092783          	lw	a5,32(s2)
    80004c7c:	9fa9                	addw	a5,a5,a0
    80004c7e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c82:	01893503          	ld	a0,24(s2)
    80004c86:	fffff097          	auipc	ra,0xfffff
    80004c8a:	a68080e7          	jalr	-1432(ra) # 800036ee <iunlock>
      end_op();
    80004c8e:	fffff097          	auipc	ra,0xfffff
    80004c92:	6f2080e7          	jalr	1778(ra) # 80004380 <end_op>

      if(r != n1){
    80004c96:	009c1f63          	bne	s8,s1,80004cb4 <kfilewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004c9a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004c9e:	0149db63          	bge	s3,s4,80004cb4 <kfilewrite+0xf6>
      int n1 = n - i;
    80004ca2:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004ca6:	84be                	mv	s1,a5
    80004ca8:	2781                	sext.w	a5,a5
    80004caa:	f8fb5ce3          	bge	s6,a5,80004c42 <kfilewrite+0x84>
    80004cae:	84de                	mv	s1,s7
    80004cb0:	bf49                	j	80004c42 <kfilewrite+0x84>
    int i = 0;
    80004cb2:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004cb4:	013a1f63          	bne	s4,s3,80004cd2 <kfilewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
    80004cb8:	8552                	mv	a0,s4
    80004cba:	60a6                	ld	ra,72(sp)
    80004cbc:	6406                	ld	s0,64(sp)
    80004cbe:	74e2                	ld	s1,56(sp)
    80004cc0:	7942                	ld	s2,48(sp)
    80004cc2:	79a2                	ld	s3,40(sp)
    80004cc4:	7a02                	ld	s4,32(sp)
    80004cc6:	6ae2                	ld	s5,24(sp)
    80004cc8:	6b42                	ld	s6,16(sp)
    80004cca:	6ba2                	ld	s7,8(sp)
    80004ccc:	6c02                	ld	s8,0(sp)
    80004cce:	6161                	addi	sp,sp,80
    80004cd0:	8082                	ret
    ret = (i == n ? n : -1);
    80004cd2:	5a7d                	li	s4,-1
    80004cd4:	b7d5                	j	80004cb8 <kfilewrite+0xfa>
    panic("filewrite");
    80004cd6:	00004517          	auipc	a0,0x4
    80004cda:	a5250513          	addi	a0,a0,-1454 # 80008728 <syscalls+0x2d8>
    80004cde:	ffffc097          	auipc	ra,0xffffc
    80004ce2:	860080e7          	jalr	-1952(ra) # 8000053e <panic>
    return -1;
    80004ce6:	5a7d                	li	s4,-1
    80004ce8:	bfc1                	j	80004cb8 <kfilewrite+0xfa>
      return -1;
    80004cea:	5a7d                	li	s4,-1
    80004cec:	b7f1                	j	80004cb8 <kfilewrite+0xfa>
    80004cee:	5a7d                	li	s4,-1
    80004cf0:	b7e1                	j	80004cb8 <kfilewrite+0xfa>

0000000080004cf2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004cf2:	7179                	addi	sp,sp,-48
    80004cf4:	f406                	sd	ra,40(sp)
    80004cf6:	f022                	sd	s0,32(sp)
    80004cf8:	ec26                	sd	s1,24(sp)
    80004cfa:	e84a                	sd	s2,16(sp)
    80004cfc:	e44e                	sd	s3,8(sp)
    80004cfe:	e052                	sd	s4,0(sp)
    80004d00:	1800                	addi	s0,sp,48
    80004d02:	84aa                	mv	s1,a0
    80004d04:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d06:	0005b023          	sd	zero,0(a1)
    80004d0a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d0e:	00000097          	auipc	ra,0x0
    80004d12:	a02080e7          	jalr	-1534(ra) # 80004710 <filealloc>
    80004d16:	e088                	sd	a0,0(s1)
    80004d18:	c551                	beqz	a0,80004da4 <pipealloc+0xb2>
    80004d1a:	00000097          	auipc	ra,0x0
    80004d1e:	9f6080e7          	jalr	-1546(ra) # 80004710 <filealloc>
    80004d22:	00aa3023          	sd	a0,0(s4)
    80004d26:	c92d                	beqz	a0,80004d98 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d28:	ffffc097          	auipc	ra,0xffffc
    80004d2c:	dbe080e7          	jalr	-578(ra) # 80000ae6 <kalloc>
    80004d30:	892a                	mv	s2,a0
    80004d32:	c125                	beqz	a0,80004d92 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d34:	4985                	li	s3,1
    80004d36:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d3a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d3e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004d42:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004d46:	00004597          	auipc	a1,0x4
    80004d4a:	9f258593          	addi	a1,a1,-1550 # 80008738 <syscalls+0x2e8>
    80004d4e:	ffffc097          	auipc	ra,0xffffc
    80004d52:	df8080e7          	jalr	-520(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004d56:	609c                	ld	a5,0(s1)
    80004d58:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004d5c:	609c                	ld	a5,0(s1)
    80004d5e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004d62:	609c                	ld	a5,0(s1)
    80004d64:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004d68:	609c                	ld	a5,0(s1)
    80004d6a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004d6e:	000a3783          	ld	a5,0(s4)
    80004d72:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004d76:	000a3783          	ld	a5,0(s4)
    80004d7a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d7e:	000a3783          	ld	a5,0(s4)
    80004d82:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004d86:	000a3783          	ld	a5,0(s4)
    80004d8a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004d8e:	4501                	li	a0,0
    80004d90:	a025                	j	80004db8 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004d92:	6088                	ld	a0,0(s1)
    80004d94:	e501                	bnez	a0,80004d9c <pipealloc+0xaa>
    80004d96:	a039                	j	80004da4 <pipealloc+0xb2>
    80004d98:	6088                	ld	a0,0(s1)
    80004d9a:	c51d                	beqz	a0,80004dc8 <pipealloc+0xd6>
    fileclose(*f0);
    80004d9c:	00000097          	auipc	ra,0x0
    80004da0:	a30080e7          	jalr	-1488(ra) # 800047cc <fileclose>
  if(*f1)
    80004da4:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004da8:	557d                	li	a0,-1
  if(*f1)
    80004daa:	c799                	beqz	a5,80004db8 <pipealloc+0xc6>
    fileclose(*f1);
    80004dac:	853e                	mv	a0,a5
    80004dae:	00000097          	auipc	ra,0x0
    80004db2:	a1e080e7          	jalr	-1506(ra) # 800047cc <fileclose>
  return -1;
    80004db6:	557d                	li	a0,-1
}
    80004db8:	70a2                	ld	ra,40(sp)
    80004dba:	7402                	ld	s0,32(sp)
    80004dbc:	64e2                	ld	s1,24(sp)
    80004dbe:	6942                	ld	s2,16(sp)
    80004dc0:	69a2                	ld	s3,8(sp)
    80004dc2:	6a02                	ld	s4,0(sp)
    80004dc4:	6145                	addi	sp,sp,48
    80004dc6:	8082                	ret
  return -1;
    80004dc8:	557d                	li	a0,-1
    80004dca:	b7fd                	j	80004db8 <pipealloc+0xc6>

0000000080004dcc <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004dcc:	1101                	addi	sp,sp,-32
    80004dce:	ec06                	sd	ra,24(sp)
    80004dd0:	e822                	sd	s0,16(sp)
    80004dd2:	e426                	sd	s1,8(sp)
    80004dd4:	e04a                	sd	s2,0(sp)
    80004dd6:	1000                	addi	s0,sp,32
    80004dd8:	84aa                	mv	s1,a0
    80004dda:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ddc:	ffffc097          	auipc	ra,0xffffc
    80004de0:	dfa080e7          	jalr	-518(ra) # 80000bd6 <acquire>
  if(writable){
    80004de4:	02090d63          	beqz	s2,80004e1e <pipeclose+0x52>
    pi->writeopen = 0;
    80004de8:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004dec:	21848513          	addi	a0,s1,536
    80004df0:	ffffd097          	auipc	ra,0xffffd
    80004df4:	2c8080e7          	jalr	712(ra) # 800020b8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004df8:	2204b783          	ld	a5,544(s1)
    80004dfc:	eb95                	bnez	a5,80004e30 <pipeclose+0x64>
    release(&pi->lock);
    80004dfe:	8526                	mv	a0,s1
    80004e00:	ffffc097          	auipc	ra,0xffffc
    80004e04:	e8a080e7          	jalr	-374(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004e08:	8526                	mv	a0,s1
    80004e0a:	ffffc097          	auipc	ra,0xffffc
    80004e0e:	be0080e7          	jalr	-1056(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004e12:	60e2                	ld	ra,24(sp)
    80004e14:	6442                	ld	s0,16(sp)
    80004e16:	64a2                	ld	s1,8(sp)
    80004e18:	6902                	ld	s2,0(sp)
    80004e1a:	6105                	addi	sp,sp,32
    80004e1c:	8082                	ret
    pi->readopen = 0;
    80004e1e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e22:	21c48513          	addi	a0,s1,540
    80004e26:	ffffd097          	auipc	ra,0xffffd
    80004e2a:	292080e7          	jalr	658(ra) # 800020b8 <wakeup>
    80004e2e:	b7e9                	j	80004df8 <pipeclose+0x2c>
    release(&pi->lock);
    80004e30:	8526                	mv	a0,s1
    80004e32:	ffffc097          	auipc	ra,0xffffc
    80004e36:	e58080e7          	jalr	-424(ra) # 80000c8a <release>
}
    80004e3a:	bfe1                	j	80004e12 <pipeclose+0x46>

0000000080004e3c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e3c:	711d                	addi	sp,sp,-96
    80004e3e:	ec86                	sd	ra,88(sp)
    80004e40:	e8a2                	sd	s0,80(sp)
    80004e42:	e4a6                	sd	s1,72(sp)
    80004e44:	e0ca                	sd	s2,64(sp)
    80004e46:	fc4e                	sd	s3,56(sp)
    80004e48:	f852                	sd	s4,48(sp)
    80004e4a:	f456                	sd	s5,40(sp)
    80004e4c:	f05a                	sd	s6,32(sp)
    80004e4e:	ec5e                	sd	s7,24(sp)
    80004e50:	e862                	sd	s8,16(sp)
    80004e52:	1080                	addi	s0,sp,96
    80004e54:	84aa                	mv	s1,a0
    80004e56:	8aae                	mv	s5,a1
    80004e58:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004e5a:	ffffd097          	auipc	ra,0xffffd
    80004e5e:	b52080e7          	jalr	-1198(ra) # 800019ac <myproc>
    80004e62:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004e64:	8526                	mv	a0,s1
    80004e66:	ffffc097          	auipc	ra,0xffffc
    80004e6a:	d70080e7          	jalr	-656(ra) # 80000bd6 <acquire>
  while(i < n){
    80004e6e:	0b405663          	blez	s4,80004f1a <pipewrite+0xde>
  int i = 0;
    80004e72:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e74:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004e76:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004e7a:	21c48b93          	addi	s7,s1,540
    80004e7e:	a089                	j	80004ec0 <pipewrite+0x84>
      release(&pi->lock);
    80004e80:	8526                	mv	a0,s1
    80004e82:	ffffc097          	auipc	ra,0xffffc
    80004e86:	e08080e7          	jalr	-504(ra) # 80000c8a <release>
      return -1;
    80004e8a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004e8c:	854a                	mv	a0,s2
    80004e8e:	60e6                	ld	ra,88(sp)
    80004e90:	6446                	ld	s0,80(sp)
    80004e92:	64a6                	ld	s1,72(sp)
    80004e94:	6906                	ld	s2,64(sp)
    80004e96:	79e2                	ld	s3,56(sp)
    80004e98:	7a42                	ld	s4,48(sp)
    80004e9a:	7aa2                	ld	s5,40(sp)
    80004e9c:	7b02                	ld	s6,32(sp)
    80004e9e:	6be2                	ld	s7,24(sp)
    80004ea0:	6c42                	ld	s8,16(sp)
    80004ea2:	6125                	addi	sp,sp,96
    80004ea4:	8082                	ret
      wakeup(&pi->nread);
    80004ea6:	8562                	mv	a0,s8
    80004ea8:	ffffd097          	auipc	ra,0xffffd
    80004eac:	210080e7          	jalr	528(ra) # 800020b8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004eb0:	85a6                	mv	a1,s1
    80004eb2:	855e                	mv	a0,s7
    80004eb4:	ffffd097          	auipc	ra,0xffffd
    80004eb8:	1a0080e7          	jalr	416(ra) # 80002054 <sleep>
  while(i < n){
    80004ebc:	07495063          	bge	s2,s4,80004f1c <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004ec0:	2204a783          	lw	a5,544(s1)
    80004ec4:	dfd5                	beqz	a5,80004e80 <pipewrite+0x44>
    80004ec6:	854e                	mv	a0,s3
    80004ec8:	ffffd097          	auipc	ra,0xffffd
    80004ecc:	434080e7          	jalr	1076(ra) # 800022fc <killed>
    80004ed0:	f945                	bnez	a0,80004e80 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ed2:	2184a783          	lw	a5,536(s1)
    80004ed6:	21c4a703          	lw	a4,540(s1)
    80004eda:	2007879b          	addiw	a5,a5,512
    80004ede:	fcf704e3          	beq	a4,a5,80004ea6 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ee2:	4685                	li	a3,1
    80004ee4:	01590633          	add	a2,s2,s5
    80004ee8:	faf40593          	addi	a1,s0,-81
    80004eec:	0509b503          	ld	a0,80(s3)
    80004ef0:	ffffd097          	auipc	ra,0xffffd
    80004ef4:	804080e7          	jalr	-2044(ra) # 800016f4 <copyin>
    80004ef8:	03650263          	beq	a0,s6,80004f1c <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004efc:	21c4a783          	lw	a5,540(s1)
    80004f00:	0017871b          	addiw	a4,a5,1
    80004f04:	20e4ae23          	sw	a4,540(s1)
    80004f08:	1ff7f793          	andi	a5,a5,511
    80004f0c:	97a6                	add	a5,a5,s1
    80004f0e:	faf44703          	lbu	a4,-81(s0)
    80004f12:	00e78c23          	sb	a4,24(a5)
      i++;
    80004f16:	2905                	addiw	s2,s2,1
    80004f18:	b755                	j	80004ebc <pipewrite+0x80>
  int i = 0;
    80004f1a:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004f1c:	21848513          	addi	a0,s1,536
    80004f20:	ffffd097          	auipc	ra,0xffffd
    80004f24:	198080e7          	jalr	408(ra) # 800020b8 <wakeup>
  release(&pi->lock);
    80004f28:	8526                	mv	a0,s1
    80004f2a:	ffffc097          	auipc	ra,0xffffc
    80004f2e:	d60080e7          	jalr	-672(ra) # 80000c8a <release>
  return i;
    80004f32:	bfa9                	j	80004e8c <pipewrite+0x50>

0000000080004f34 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f34:	715d                	addi	sp,sp,-80
    80004f36:	e486                	sd	ra,72(sp)
    80004f38:	e0a2                	sd	s0,64(sp)
    80004f3a:	fc26                	sd	s1,56(sp)
    80004f3c:	f84a                	sd	s2,48(sp)
    80004f3e:	f44e                	sd	s3,40(sp)
    80004f40:	f052                	sd	s4,32(sp)
    80004f42:	ec56                	sd	s5,24(sp)
    80004f44:	e85a                	sd	s6,16(sp)
    80004f46:	0880                	addi	s0,sp,80
    80004f48:	84aa                	mv	s1,a0
    80004f4a:	892e                	mv	s2,a1
    80004f4c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004f4e:	ffffd097          	auipc	ra,0xffffd
    80004f52:	a5e080e7          	jalr	-1442(ra) # 800019ac <myproc>
    80004f56:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004f58:	8526                	mv	a0,s1
    80004f5a:	ffffc097          	auipc	ra,0xffffc
    80004f5e:	c7c080e7          	jalr	-900(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f62:	2184a703          	lw	a4,536(s1)
    80004f66:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f6a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f6e:	02f71763          	bne	a4,a5,80004f9c <piperead+0x68>
    80004f72:	2244a783          	lw	a5,548(s1)
    80004f76:	c39d                	beqz	a5,80004f9c <piperead+0x68>
    if(killed(pr)){
    80004f78:	8552                	mv	a0,s4
    80004f7a:	ffffd097          	auipc	ra,0xffffd
    80004f7e:	382080e7          	jalr	898(ra) # 800022fc <killed>
    80004f82:	e941                	bnez	a0,80005012 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f84:	85a6                	mv	a1,s1
    80004f86:	854e                	mv	a0,s3
    80004f88:	ffffd097          	auipc	ra,0xffffd
    80004f8c:	0cc080e7          	jalr	204(ra) # 80002054 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f90:	2184a703          	lw	a4,536(s1)
    80004f94:	21c4a783          	lw	a5,540(s1)
    80004f98:	fcf70de3          	beq	a4,a5,80004f72 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f9c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f9e:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fa0:	05505363          	blez	s5,80004fe6 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004fa4:	2184a783          	lw	a5,536(s1)
    80004fa8:	21c4a703          	lw	a4,540(s1)
    80004fac:	02f70d63          	beq	a4,a5,80004fe6 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004fb0:	0017871b          	addiw	a4,a5,1
    80004fb4:	20e4ac23          	sw	a4,536(s1)
    80004fb8:	1ff7f793          	andi	a5,a5,511
    80004fbc:	97a6                	add	a5,a5,s1
    80004fbe:	0187c783          	lbu	a5,24(a5)
    80004fc2:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004fc6:	4685                	li	a3,1
    80004fc8:	fbf40613          	addi	a2,s0,-65
    80004fcc:	85ca                	mv	a1,s2
    80004fce:	050a3503          	ld	a0,80(s4)
    80004fd2:	ffffc097          	auipc	ra,0xffffc
    80004fd6:	696080e7          	jalr	1686(ra) # 80001668 <copyout>
    80004fda:	01650663          	beq	a0,s6,80004fe6 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fde:	2985                	addiw	s3,s3,1
    80004fe0:	0905                	addi	s2,s2,1
    80004fe2:	fd3a91e3          	bne	s5,s3,80004fa4 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004fe6:	21c48513          	addi	a0,s1,540
    80004fea:	ffffd097          	auipc	ra,0xffffd
    80004fee:	0ce080e7          	jalr	206(ra) # 800020b8 <wakeup>
  release(&pi->lock);
    80004ff2:	8526                	mv	a0,s1
    80004ff4:	ffffc097          	auipc	ra,0xffffc
    80004ff8:	c96080e7          	jalr	-874(ra) # 80000c8a <release>
  return i;
}
    80004ffc:	854e                	mv	a0,s3
    80004ffe:	60a6                	ld	ra,72(sp)
    80005000:	6406                	ld	s0,64(sp)
    80005002:	74e2                	ld	s1,56(sp)
    80005004:	7942                	ld	s2,48(sp)
    80005006:	79a2                	ld	s3,40(sp)
    80005008:	7a02                	ld	s4,32(sp)
    8000500a:	6ae2                	ld	s5,24(sp)
    8000500c:	6b42                	ld	s6,16(sp)
    8000500e:	6161                	addi	sp,sp,80
    80005010:	8082                	ret
      release(&pi->lock);
    80005012:	8526                	mv	a0,s1
    80005014:	ffffc097          	auipc	ra,0xffffc
    80005018:	c76080e7          	jalr	-906(ra) # 80000c8a <release>
      return -1;
    8000501c:	59fd                	li	s3,-1
    8000501e:	bff9                	j	80004ffc <piperead+0xc8>

0000000080005020 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005020:	1141                	addi	sp,sp,-16
    80005022:	e422                	sd	s0,8(sp)
    80005024:	0800                	addi	s0,sp,16
    80005026:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005028:	8905                	andi	a0,a0,1
    8000502a:	c111                	beqz	a0,8000502e <flags2perm+0xe>
      perm = PTE_X;
    8000502c:	4521                	li	a0,8
    if(flags & 0x2)
    8000502e:	8b89                	andi	a5,a5,2
    80005030:	c399                	beqz	a5,80005036 <flags2perm+0x16>
      perm |= PTE_W;
    80005032:	00456513          	ori	a0,a0,4
    return perm;
}
    80005036:	6422                	ld	s0,8(sp)
    80005038:	0141                	addi	sp,sp,16
    8000503a:	8082                	ret

000000008000503c <exec>:

int
exec(char *path, char **argv)
{
    8000503c:	de010113          	addi	sp,sp,-544
    80005040:	20113c23          	sd	ra,536(sp)
    80005044:	20813823          	sd	s0,528(sp)
    80005048:	20913423          	sd	s1,520(sp)
    8000504c:	21213023          	sd	s2,512(sp)
    80005050:	ffce                	sd	s3,504(sp)
    80005052:	fbd2                	sd	s4,496(sp)
    80005054:	f7d6                	sd	s5,488(sp)
    80005056:	f3da                	sd	s6,480(sp)
    80005058:	efde                	sd	s7,472(sp)
    8000505a:	ebe2                	sd	s8,464(sp)
    8000505c:	e7e6                	sd	s9,456(sp)
    8000505e:	e3ea                	sd	s10,448(sp)
    80005060:	ff6e                	sd	s11,440(sp)
    80005062:	1400                	addi	s0,sp,544
    80005064:	892a                	mv	s2,a0
    80005066:	dea43423          	sd	a0,-536(s0)
    8000506a:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000506e:	ffffd097          	auipc	ra,0xffffd
    80005072:	93e080e7          	jalr	-1730(ra) # 800019ac <myproc>
    80005076:	84aa                	mv	s1,a0

  begin_op();
    80005078:	fffff097          	auipc	ra,0xfffff
    8000507c:	288080e7          	jalr	648(ra) # 80004300 <begin_op>

  if((ip = namei(path)) == 0){
    80005080:	854a                	mv	a0,s2
    80005082:	fffff097          	auipc	ra,0xfffff
    80005086:	d50080e7          	jalr	-688(ra) # 80003dd2 <namei>
    8000508a:	c93d                	beqz	a0,80005100 <exec+0xc4>
    8000508c:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000508e:	ffffe097          	auipc	ra,0xffffe
    80005092:	59e080e7          	jalr	1438(ra) # 8000362c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005096:	04000713          	li	a4,64
    8000509a:	4681                	li	a3,0
    8000509c:	e5040613          	addi	a2,s0,-432
    800050a0:	4581                	li	a1,0
    800050a2:	8556                	mv	a0,s5
    800050a4:	fffff097          	auipc	ra,0xfffff
    800050a8:	83c080e7          	jalr	-1988(ra) # 800038e0 <readi>
    800050ac:	04000793          	li	a5,64
    800050b0:	00f51a63          	bne	a0,a5,800050c4 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800050b4:	e5042703          	lw	a4,-432(s0)
    800050b8:	464c47b7          	lui	a5,0x464c4
    800050bc:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800050c0:	04f70663          	beq	a4,a5,8000510c <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800050c4:	8556                	mv	a0,s5
    800050c6:	ffffe097          	auipc	ra,0xffffe
    800050ca:	7c8080e7          	jalr	1992(ra) # 8000388e <iunlockput>
    end_op();
    800050ce:	fffff097          	auipc	ra,0xfffff
    800050d2:	2b2080e7          	jalr	690(ra) # 80004380 <end_op>
  }
  return -1;
    800050d6:	557d                	li	a0,-1
}
    800050d8:	21813083          	ld	ra,536(sp)
    800050dc:	21013403          	ld	s0,528(sp)
    800050e0:	20813483          	ld	s1,520(sp)
    800050e4:	20013903          	ld	s2,512(sp)
    800050e8:	79fe                	ld	s3,504(sp)
    800050ea:	7a5e                	ld	s4,496(sp)
    800050ec:	7abe                	ld	s5,488(sp)
    800050ee:	7b1e                	ld	s6,480(sp)
    800050f0:	6bfe                	ld	s7,472(sp)
    800050f2:	6c5e                	ld	s8,464(sp)
    800050f4:	6cbe                	ld	s9,456(sp)
    800050f6:	6d1e                	ld	s10,448(sp)
    800050f8:	7dfa                	ld	s11,440(sp)
    800050fa:	22010113          	addi	sp,sp,544
    800050fe:	8082                	ret
    end_op();
    80005100:	fffff097          	auipc	ra,0xfffff
    80005104:	280080e7          	jalr	640(ra) # 80004380 <end_op>
    return -1;
    80005108:	557d                	li	a0,-1
    8000510a:	b7f9                	j	800050d8 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    8000510c:	8526                	mv	a0,s1
    8000510e:	ffffd097          	auipc	ra,0xffffd
    80005112:	962080e7          	jalr	-1694(ra) # 80001a70 <proc_pagetable>
    80005116:	8b2a                	mv	s6,a0
    80005118:	d555                	beqz	a0,800050c4 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000511a:	e7042783          	lw	a5,-400(s0)
    8000511e:	e8845703          	lhu	a4,-376(s0)
    80005122:	c735                	beqz	a4,8000518e <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005124:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005126:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    8000512a:	6a05                	lui	s4,0x1
    8000512c:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005130:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005134:	6d85                	lui	s11,0x1
    80005136:	7d7d                	lui	s10,0xfffff
    80005138:	a481                	j	80005378 <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000513a:	00003517          	auipc	a0,0x3
    8000513e:	60650513          	addi	a0,a0,1542 # 80008740 <syscalls+0x2f0>
    80005142:	ffffb097          	auipc	ra,0xffffb
    80005146:	3fc080e7          	jalr	1020(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000514a:	874a                	mv	a4,s2
    8000514c:	009c86bb          	addw	a3,s9,s1
    80005150:	4581                	li	a1,0
    80005152:	8556                	mv	a0,s5
    80005154:	ffffe097          	auipc	ra,0xffffe
    80005158:	78c080e7          	jalr	1932(ra) # 800038e0 <readi>
    8000515c:	2501                	sext.w	a0,a0
    8000515e:	1aa91a63          	bne	s2,a0,80005312 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80005162:	009d84bb          	addw	s1,s11,s1
    80005166:	013d09bb          	addw	s3,s10,s3
    8000516a:	1f74f763          	bgeu	s1,s7,80005358 <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    8000516e:	02049593          	slli	a1,s1,0x20
    80005172:	9181                	srli	a1,a1,0x20
    80005174:	95e2                	add	a1,a1,s8
    80005176:	855a                	mv	a0,s6
    80005178:	ffffc097          	auipc	ra,0xffffc
    8000517c:	ee4080e7          	jalr	-284(ra) # 8000105c <walkaddr>
    80005180:	862a                	mv	a2,a0
    if(pa == 0)
    80005182:	dd45                	beqz	a0,8000513a <exec+0xfe>
      n = PGSIZE;
    80005184:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005186:	fd49f2e3          	bgeu	s3,s4,8000514a <exec+0x10e>
      n = sz - i;
    8000518a:	894e                	mv	s2,s3
    8000518c:	bf7d                	j	8000514a <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000518e:	4901                	li	s2,0
  iunlockput(ip);
    80005190:	8556                	mv	a0,s5
    80005192:	ffffe097          	auipc	ra,0xffffe
    80005196:	6fc080e7          	jalr	1788(ra) # 8000388e <iunlockput>
  end_op();
    8000519a:	fffff097          	auipc	ra,0xfffff
    8000519e:	1e6080e7          	jalr	486(ra) # 80004380 <end_op>
  p = myproc();
    800051a2:	ffffd097          	auipc	ra,0xffffd
    800051a6:	80a080e7          	jalr	-2038(ra) # 800019ac <myproc>
    800051aa:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800051ac:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800051b0:	6785                	lui	a5,0x1
    800051b2:	17fd                	addi	a5,a5,-1
    800051b4:	993e                	add	s2,s2,a5
    800051b6:	77fd                	lui	a5,0xfffff
    800051b8:	00f977b3          	and	a5,s2,a5
    800051bc:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800051c0:	4691                	li	a3,4
    800051c2:	6609                	lui	a2,0x2
    800051c4:	963e                	add	a2,a2,a5
    800051c6:	85be                	mv	a1,a5
    800051c8:	855a                	mv	a0,s6
    800051ca:	ffffc097          	auipc	ra,0xffffc
    800051ce:	246080e7          	jalr	582(ra) # 80001410 <uvmalloc>
    800051d2:	8c2a                	mv	s8,a0
  ip = 0;
    800051d4:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800051d6:	12050e63          	beqz	a0,80005312 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800051da:	75f9                	lui	a1,0xffffe
    800051dc:	95aa                	add	a1,a1,a0
    800051de:	855a                	mv	a0,s6
    800051e0:	ffffc097          	auipc	ra,0xffffc
    800051e4:	456080e7          	jalr	1110(ra) # 80001636 <uvmclear>
  stackbase = sp - PGSIZE;
    800051e8:	7afd                	lui	s5,0xfffff
    800051ea:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800051ec:	df043783          	ld	a5,-528(s0)
    800051f0:	6388                	ld	a0,0(a5)
    800051f2:	c925                	beqz	a0,80005262 <exec+0x226>
    800051f4:	e9040993          	addi	s3,s0,-368
    800051f8:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800051fc:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800051fe:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005200:	ffffc097          	auipc	ra,0xffffc
    80005204:	c4e080e7          	jalr	-946(ra) # 80000e4e <strlen>
    80005208:	0015079b          	addiw	a5,a0,1
    8000520c:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005210:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005214:	13596663          	bltu	s2,s5,80005340 <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005218:	df043d83          	ld	s11,-528(s0)
    8000521c:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005220:	8552                	mv	a0,s4
    80005222:	ffffc097          	auipc	ra,0xffffc
    80005226:	c2c080e7          	jalr	-980(ra) # 80000e4e <strlen>
    8000522a:	0015069b          	addiw	a3,a0,1
    8000522e:	8652                	mv	a2,s4
    80005230:	85ca                	mv	a1,s2
    80005232:	855a                	mv	a0,s6
    80005234:	ffffc097          	auipc	ra,0xffffc
    80005238:	434080e7          	jalr	1076(ra) # 80001668 <copyout>
    8000523c:	10054663          	bltz	a0,80005348 <exec+0x30c>
    ustack[argc] = sp;
    80005240:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005244:	0485                	addi	s1,s1,1
    80005246:	008d8793          	addi	a5,s11,8
    8000524a:	def43823          	sd	a5,-528(s0)
    8000524e:	008db503          	ld	a0,8(s11)
    80005252:	c911                	beqz	a0,80005266 <exec+0x22a>
    if(argc >= MAXARG)
    80005254:	09a1                	addi	s3,s3,8
    80005256:	fb3c95e3          	bne	s9,s3,80005200 <exec+0x1c4>
  sz = sz1;
    8000525a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000525e:	4a81                	li	s5,0
    80005260:	a84d                	j	80005312 <exec+0x2d6>
  sp = sz;
    80005262:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005264:	4481                	li	s1,0
  ustack[argc] = 0;
    80005266:	00349793          	slli	a5,s1,0x3
    8000526a:	f9040713          	addi	a4,s0,-112
    8000526e:	97ba                	add	a5,a5,a4
    80005270:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffdcf60>
  sp -= (argc+1) * sizeof(uint64);
    80005274:	00148693          	addi	a3,s1,1
    80005278:	068e                	slli	a3,a3,0x3
    8000527a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000527e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005282:	01597663          	bgeu	s2,s5,8000528e <exec+0x252>
  sz = sz1;
    80005286:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000528a:	4a81                	li	s5,0
    8000528c:	a059                	j	80005312 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000528e:	e9040613          	addi	a2,s0,-368
    80005292:	85ca                	mv	a1,s2
    80005294:	855a                	mv	a0,s6
    80005296:	ffffc097          	auipc	ra,0xffffc
    8000529a:	3d2080e7          	jalr	978(ra) # 80001668 <copyout>
    8000529e:	0a054963          	bltz	a0,80005350 <exec+0x314>
  p->trapframe->a1 = sp;
    800052a2:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    800052a6:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800052aa:	de843783          	ld	a5,-536(s0)
    800052ae:	0007c703          	lbu	a4,0(a5)
    800052b2:	cf11                	beqz	a4,800052ce <exec+0x292>
    800052b4:	0785                	addi	a5,a5,1
    if(*s == '/')
    800052b6:	02f00693          	li	a3,47
    800052ba:	a039                	j	800052c8 <exec+0x28c>
      last = s+1;
    800052bc:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800052c0:	0785                	addi	a5,a5,1
    800052c2:	fff7c703          	lbu	a4,-1(a5)
    800052c6:	c701                	beqz	a4,800052ce <exec+0x292>
    if(*s == '/')
    800052c8:	fed71ce3          	bne	a4,a3,800052c0 <exec+0x284>
    800052cc:	bfc5                	j	800052bc <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    800052ce:	4641                	li	a2,16
    800052d0:	de843583          	ld	a1,-536(s0)
    800052d4:	158b8513          	addi	a0,s7,344
    800052d8:	ffffc097          	auipc	ra,0xffffc
    800052dc:	b44080e7          	jalr	-1212(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    800052e0:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800052e4:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800052e8:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800052ec:	058bb783          	ld	a5,88(s7)
    800052f0:	e6843703          	ld	a4,-408(s0)
    800052f4:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800052f6:	058bb783          	ld	a5,88(s7)
    800052fa:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800052fe:	85ea                	mv	a1,s10
    80005300:	ffffd097          	auipc	ra,0xffffd
    80005304:	80c080e7          	jalr	-2036(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005308:	0004851b          	sext.w	a0,s1
    8000530c:	b3f1                	j	800050d8 <exec+0x9c>
    8000530e:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005312:	df843583          	ld	a1,-520(s0)
    80005316:	855a                	mv	a0,s6
    80005318:	ffffc097          	auipc	ra,0xffffc
    8000531c:	7f4080e7          	jalr	2036(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    80005320:	da0a92e3          	bnez	s5,800050c4 <exec+0x88>
  return -1;
    80005324:	557d                	li	a0,-1
    80005326:	bb4d                	j	800050d8 <exec+0x9c>
    80005328:	df243c23          	sd	s2,-520(s0)
    8000532c:	b7dd                	j	80005312 <exec+0x2d6>
    8000532e:	df243c23          	sd	s2,-520(s0)
    80005332:	b7c5                	j	80005312 <exec+0x2d6>
    80005334:	df243c23          	sd	s2,-520(s0)
    80005338:	bfe9                	j	80005312 <exec+0x2d6>
    8000533a:	df243c23          	sd	s2,-520(s0)
    8000533e:	bfd1                	j	80005312 <exec+0x2d6>
  sz = sz1;
    80005340:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005344:	4a81                	li	s5,0
    80005346:	b7f1                	j	80005312 <exec+0x2d6>
  sz = sz1;
    80005348:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000534c:	4a81                	li	s5,0
    8000534e:	b7d1                	j	80005312 <exec+0x2d6>
  sz = sz1;
    80005350:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005354:	4a81                	li	s5,0
    80005356:	bf75                	j	80005312 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005358:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000535c:	e0843783          	ld	a5,-504(s0)
    80005360:	0017869b          	addiw	a3,a5,1
    80005364:	e0d43423          	sd	a3,-504(s0)
    80005368:	e0043783          	ld	a5,-512(s0)
    8000536c:	0387879b          	addiw	a5,a5,56
    80005370:	e8845703          	lhu	a4,-376(s0)
    80005374:	e0e6dee3          	bge	a3,a4,80005190 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005378:	2781                	sext.w	a5,a5
    8000537a:	e0f43023          	sd	a5,-512(s0)
    8000537e:	03800713          	li	a4,56
    80005382:	86be                	mv	a3,a5
    80005384:	e1840613          	addi	a2,s0,-488
    80005388:	4581                	li	a1,0
    8000538a:	8556                	mv	a0,s5
    8000538c:	ffffe097          	auipc	ra,0xffffe
    80005390:	554080e7          	jalr	1364(ra) # 800038e0 <readi>
    80005394:	03800793          	li	a5,56
    80005398:	f6f51be3          	bne	a0,a5,8000530e <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    8000539c:	e1842783          	lw	a5,-488(s0)
    800053a0:	4705                	li	a4,1
    800053a2:	fae79de3          	bne	a5,a4,8000535c <exec+0x320>
    if(ph.memsz < ph.filesz)
    800053a6:	e4043483          	ld	s1,-448(s0)
    800053aa:	e3843783          	ld	a5,-456(s0)
    800053ae:	f6f4ede3          	bltu	s1,a5,80005328 <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800053b2:	e2843783          	ld	a5,-472(s0)
    800053b6:	94be                	add	s1,s1,a5
    800053b8:	f6f4ebe3          	bltu	s1,a5,8000532e <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    800053bc:	de043703          	ld	a4,-544(s0)
    800053c0:	8ff9                	and	a5,a5,a4
    800053c2:	fbad                	bnez	a5,80005334 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800053c4:	e1c42503          	lw	a0,-484(s0)
    800053c8:	00000097          	auipc	ra,0x0
    800053cc:	c58080e7          	jalr	-936(ra) # 80005020 <flags2perm>
    800053d0:	86aa                	mv	a3,a0
    800053d2:	8626                	mv	a2,s1
    800053d4:	85ca                	mv	a1,s2
    800053d6:	855a                	mv	a0,s6
    800053d8:	ffffc097          	auipc	ra,0xffffc
    800053dc:	038080e7          	jalr	56(ra) # 80001410 <uvmalloc>
    800053e0:	dea43c23          	sd	a0,-520(s0)
    800053e4:	d939                	beqz	a0,8000533a <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800053e6:	e2843c03          	ld	s8,-472(s0)
    800053ea:	e2042c83          	lw	s9,-480(s0)
    800053ee:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800053f2:	f60b83e3          	beqz	s7,80005358 <exec+0x31c>
    800053f6:	89de                	mv	s3,s7
    800053f8:	4481                	li	s1,0
    800053fa:	bb95                	j	8000516e <exec+0x132>

00000000800053fc <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800053fc:	7179                	addi	sp,sp,-48
    800053fe:	f406                	sd	ra,40(sp)
    80005400:	f022                	sd	s0,32(sp)
    80005402:	ec26                	sd	s1,24(sp)
    80005404:	e84a                	sd	s2,16(sp)
    80005406:	1800                	addi	s0,sp,48
    80005408:	892e                	mv	s2,a1
    8000540a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000540c:	fdc40593          	addi	a1,s0,-36
    80005410:	ffffd097          	auipc	ra,0xffffd
    80005414:	6b0080e7          	jalr	1712(ra) # 80002ac0 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005418:	fdc42703          	lw	a4,-36(s0)
    8000541c:	47bd                	li	a5,15
    8000541e:	02e7eb63          	bltu	a5,a4,80005454 <argfd+0x58>
    80005422:	ffffc097          	auipc	ra,0xffffc
    80005426:	58a080e7          	jalr	1418(ra) # 800019ac <myproc>
    8000542a:	fdc42703          	lw	a4,-36(s0)
    8000542e:	01a70793          	addi	a5,a4,26
    80005432:	078e                	slli	a5,a5,0x3
    80005434:	953e                	add	a0,a0,a5
    80005436:	611c                	ld	a5,0(a0)
    80005438:	c385                	beqz	a5,80005458 <argfd+0x5c>
    return -1;
  if(pfd)
    8000543a:	00090463          	beqz	s2,80005442 <argfd+0x46>
    *pfd = fd;
    8000543e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005442:	4501                	li	a0,0
  if(pf)
    80005444:	c091                	beqz	s1,80005448 <argfd+0x4c>
    *pf = f;
    80005446:	e09c                	sd	a5,0(s1)
}
    80005448:	70a2                	ld	ra,40(sp)
    8000544a:	7402                	ld	s0,32(sp)
    8000544c:	64e2                	ld	s1,24(sp)
    8000544e:	6942                	ld	s2,16(sp)
    80005450:	6145                	addi	sp,sp,48
    80005452:	8082                	ret
    return -1;
    80005454:	557d                	li	a0,-1
    80005456:	bfcd                	j	80005448 <argfd+0x4c>
    80005458:	557d                	li	a0,-1
    8000545a:	b7fd                	j	80005448 <argfd+0x4c>

000000008000545c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000545c:	1101                	addi	sp,sp,-32
    8000545e:	ec06                	sd	ra,24(sp)
    80005460:	e822                	sd	s0,16(sp)
    80005462:	e426                	sd	s1,8(sp)
    80005464:	1000                	addi	s0,sp,32
    80005466:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005468:	ffffc097          	auipc	ra,0xffffc
    8000546c:	544080e7          	jalr	1348(ra) # 800019ac <myproc>
    80005470:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005472:	0d050793          	addi	a5,a0,208
    80005476:	4501                	li	a0,0
    80005478:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000547a:	6398                	ld	a4,0(a5)
    8000547c:	cb19                	beqz	a4,80005492 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000547e:	2505                	addiw	a0,a0,1
    80005480:	07a1                	addi	a5,a5,8
    80005482:	fed51ce3          	bne	a0,a3,8000547a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005486:	557d                	li	a0,-1
}
    80005488:	60e2                	ld	ra,24(sp)
    8000548a:	6442                	ld	s0,16(sp)
    8000548c:	64a2                	ld	s1,8(sp)
    8000548e:	6105                	addi	sp,sp,32
    80005490:	8082                	ret
      p->ofile[fd] = f;
    80005492:	01a50793          	addi	a5,a0,26
    80005496:	078e                	slli	a5,a5,0x3
    80005498:	963e                	add	a2,a2,a5
    8000549a:	e204                	sd	s1,0(a2)
      return fd;
    8000549c:	b7f5                	j	80005488 <fdalloc+0x2c>

000000008000549e <sys_dup>:

uint64
sys_dup(void)
{
    8000549e:	7179                	addi	sp,sp,-48
    800054a0:	f406                	sd	ra,40(sp)
    800054a2:	f022                	sd	s0,32(sp)
    800054a4:	ec26                	sd	s1,24(sp)
    800054a6:	1800                	addi	s0,sp,48
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)
    800054a8:	fd840613          	addi	a2,s0,-40
    800054ac:	4581                	li	a1,0
    800054ae:	4501                	li	a0,0
    800054b0:	00000097          	auipc	ra,0x0
    800054b4:	f4c080e7          	jalr	-180(ra) # 800053fc <argfd>
    return -1;
    800054b8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800054ba:	02054363          	bltz	a0,800054e0 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800054be:	fd843503          	ld	a0,-40(s0)
    800054c2:	00000097          	auipc	ra,0x0
    800054c6:	f9a080e7          	jalr	-102(ra) # 8000545c <fdalloc>
    800054ca:	84aa                	mv	s1,a0
    return -1;
    800054cc:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800054ce:	00054963          	bltz	a0,800054e0 <sys_dup+0x42>
  filedup(f);
    800054d2:	fd843503          	ld	a0,-40(s0)
    800054d6:	fffff097          	auipc	ra,0xfffff
    800054da:	2a4080e7          	jalr	676(ra) # 8000477a <filedup>
  return fd;
    800054de:	87a6                	mv	a5,s1
}
    800054e0:	853e                	mv	a0,a5
    800054e2:	70a2                	ld	ra,40(sp)
    800054e4:	7402                	ld	s0,32(sp)
    800054e6:	64e2                	ld	s1,24(sp)
    800054e8:	6145                	addi	sp,sp,48
    800054ea:	8082                	ret

00000000800054ec <sys_read>:

uint64
sys_read(void)
{
    800054ec:	7179                	addi	sp,sp,-48
    800054ee:	f406                	sd	ra,40(sp)
    800054f0:	f022                	sd	s0,32(sp)
    800054f2:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  argaddr(1, &p);
    800054f4:	fd840593          	addi	a1,s0,-40
    800054f8:	4505                	li	a0,1
    800054fa:	ffffd097          	auipc	ra,0xffffd
    800054fe:	5e6080e7          	jalr	1510(ra) # 80002ae0 <argaddr>
  argint(2, &n);
    80005502:	fe440593          	addi	a1,s0,-28
    80005506:	4509                	li	a0,2
    80005508:	ffffd097          	auipc	ra,0xffffd
    8000550c:	5b8080e7          	jalr	1464(ra) # 80002ac0 <argint>
  if(argfd(0, 0, &f) < 0)
    80005510:	fe840613          	addi	a2,s0,-24
    80005514:	4581                	li	a1,0
    80005516:	4501                	li	a0,0
    80005518:	00000097          	auipc	ra,0x0
    8000551c:	ee4080e7          	jalr	-284(ra) # 800053fc <argfd>
    80005520:	87aa                	mv	a5,a0
    return -1;
    80005522:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005524:	0007cc63          	bltz	a5,8000553c <sys_read+0x50>
  return fileread(f, p, n);
    80005528:	fe442603          	lw	a2,-28(s0)
    8000552c:	fd843583          	ld	a1,-40(s0)
    80005530:	fe843503          	ld	a0,-24(s0)
    80005534:	fffff097          	auipc	ra,0xfffff
    80005538:	3d2080e7          	jalr	978(ra) # 80004906 <fileread>
}
    8000553c:	70a2                	ld	ra,40(sp)
    8000553e:	7402                	ld	s0,32(sp)
    80005540:	6145                	addi	sp,sp,48
    80005542:	8082                	ret

0000000080005544 <sys_write>:

uint64
sys_write(void)
{
    80005544:	7179                	addi	sp,sp,-48
    80005546:	f406                	sd	ra,40(sp)
    80005548:	f022                	sd	s0,32(sp)
    8000554a:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;
  
  argaddr(1, &p);
    8000554c:	fd840593          	addi	a1,s0,-40
    80005550:	4505                	li	a0,1
    80005552:	ffffd097          	auipc	ra,0xffffd
    80005556:	58e080e7          	jalr	1422(ra) # 80002ae0 <argaddr>
  argint(2, &n);
    8000555a:	fe440593          	addi	a1,s0,-28
    8000555e:	4509                	li	a0,2
    80005560:	ffffd097          	auipc	ra,0xffffd
    80005564:	560080e7          	jalr	1376(ra) # 80002ac0 <argint>
  if(argfd(0, 0, &f) < 0)
    80005568:	fe840613          	addi	a2,s0,-24
    8000556c:	4581                	li	a1,0
    8000556e:	4501                	li	a0,0
    80005570:	00000097          	auipc	ra,0x0
    80005574:	e8c080e7          	jalr	-372(ra) # 800053fc <argfd>
    80005578:	87aa                	mv	a5,a0
    return -1;
    8000557a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000557c:	0007cc63          	bltz	a5,80005594 <sys_write+0x50>

  return filewrite(f, p, n);
    80005580:	fe442603          	lw	a2,-28(s0)
    80005584:	fd843583          	ld	a1,-40(s0)
    80005588:	fe843503          	ld	a0,-24(s0)
    8000558c:	fffff097          	auipc	ra,0xfffff
    80005590:	43c080e7          	jalr	1084(ra) # 800049c8 <filewrite>
}
    80005594:	70a2                	ld	ra,40(sp)
    80005596:	7402                	ld	s0,32(sp)
    80005598:	6145                	addi	sp,sp,48
    8000559a:	8082                	ret

000000008000559c <sys_close>:

uint64
sys_close(void)
{
    8000559c:	1101                	addi	sp,sp,-32
    8000559e:	ec06                	sd	ra,24(sp)
    800055a0:	e822                	sd	s0,16(sp)
    800055a2:	1000                	addi	s0,sp,32
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)
    800055a4:	fe040613          	addi	a2,s0,-32
    800055a8:	fec40593          	addi	a1,s0,-20
    800055ac:	4501                	li	a0,0
    800055ae:	00000097          	auipc	ra,0x0
    800055b2:	e4e080e7          	jalr	-434(ra) # 800053fc <argfd>
    return -1;
    800055b6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800055b8:	02054463          	bltz	a0,800055e0 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800055bc:	ffffc097          	auipc	ra,0xffffc
    800055c0:	3f0080e7          	jalr	1008(ra) # 800019ac <myproc>
    800055c4:	fec42783          	lw	a5,-20(s0)
    800055c8:	07e9                	addi	a5,a5,26
    800055ca:	078e                	slli	a5,a5,0x3
    800055cc:	97aa                	add	a5,a5,a0
    800055ce:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800055d2:	fe043503          	ld	a0,-32(s0)
    800055d6:	fffff097          	auipc	ra,0xfffff
    800055da:	1f6080e7          	jalr	502(ra) # 800047cc <fileclose>
  return 0;
    800055de:	4781                	li	a5,0
}
    800055e0:	853e                	mv	a0,a5
    800055e2:	60e2                	ld	ra,24(sp)
    800055e4:	6442                	ld	s0,16(sp)
    800055e6:	6105                	addi	sp,sp,32
    800055e8:	8082                	ret

00000000800055ea <sys_fstat>:

uint64
sys_fstat(void)
{
    800055ea:	1101                	addi	sp,sp,-32
    800055ec:	ec06                	sd	ra,24(sp)
    800055ee:	e822                	sd	s0,16(sp)
    800055f0:	1000                	addi	s0,sp,32
  struct file *f;
  uint64 st; // user pointer to struct stat

  argaddr(1, &st);
    800055f2:	fe040593          	addi	a1,s0,-32
    800055f6:	4505                	li	a0,1
    800055f8:	ffffd097          	auipc	ra,0xffffd
    800055fc:	4e8080e7          	jalr	1256(ra) # 80002ae0 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005600:	fe840613          	addi	a2,s0,-24
    80005604:	4581                	li	a1,0
    80005606:	4501                	li	a0,0
    80005608:	00000097          	auipc	ra,0x0
    8000560c:	df4080e7          	jalr	-524(ra) # 800053fc <argfd>
    80005610:	87aa                	mv	a5,a0
    return -1;
    80005612:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005614:	0007ca63          	bltz	a5,80005628 <sys_fstat+0x3e>
  return filestat(f, st);
    80005618:	fe043583          	ld	a1,-32(s0)
    8000561c:	fe843503          	ld	a0,-24(s0)
    80005620:	fffff097          	auipc	ra,0xfffff
    80005624:	274080e7          	jalr	628(ra) # 80004894 <filestat>
}
    80005628:	60e2                	ld	ra,24(sp)
    8000562a:	6442                	ld	s0,16(sp)
    8000562c:	6105                	addi	sp,sp,32
    8000562e:	8082                	ret

0000000080005630 <sys_link>:

// Create the path new as a link to the same inode as old.
uint64
sys_link(void)
{
    80005630:	7169                	addi	sp,sp,-304
    80005632:	f606                	sd	ra,296(sp)
    80005634:	f222                	sd	s0,288(sp)
    80005636:	ee26                	sd	s1,280(sp)
    80005638:	ea4a                	sd	s2,272(sp)
    8000563a:	1a00                	addi	s0,sp,304
  char name[DIRSIZ], new[MAXPATH], old[MAXPATH];
  struct inode *dp, *ip;

  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000563c:	08000613          	li	a2,128
    80005640:	ed040593          	addi	a1,s0,-304
    80005644:	4501                	li	a0,0
    80005646:	ffffd097          	auipc	ra,0xffffd
    8000564a:	4ba080e7          	jalr	1210(ra) # 80002b00 <argstr>
    return -1;
    8000564e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005650:	10054e63          	bltz	a0,8000576c <sys_link+0x13c>
    80005654:	08000613          	li	a2,128
    80005658:	f5040593          	addi	a1,s0,-176
    8000565c:	4505                	li	a0,1
    8000565e:	ffffd097          	auipc	ra,0xffffd
    80005662:	4a2080e7          	jalr	1186(ra) # 80002b00 <argstr>
    return -1;
    80005666:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005668:	10054263          	bltz	a0,8000576c <sys_link+0x13c>

  begin_op();
    8000566c:	fffff097          	auipc	ra,0xfffff
    80005670:	c94080e7          	jalr	-876(ra) # 80004300 <begin_op>
  if((ip = namei(old)) == 0){
    80005674:	ed040513          	addi	a0,s0,-304
    80005678:	ffffe097          	auipc	ra,0xffffe
    8000567c:	75a080e7          	jalr	1882(ra) # 80003dd2 <namei>
    80005680:	84aa                	mv	s1,a0
    80005682:	c551                	beqz	a0,8000570e <sys_link+0xde>
    end_op();
    return -1;
  }

  ilock(ip);
    80005684:	ffffe097          	auipc	ra,0xffffe
    80005688:	fa8080e7          	jalr	-88(ra) # 8000362c <ilock>
  if(ip->type == T_DIR){
    8000568c:	04449703          	lh	a4,68(s1)
    80005690:	4785                	li	a5,1
    80005692:	08f70463          	beq	a4,a5,8000571a <sys_link+0xea>
    iunlockput(ip);
    end_op();
    return -1;
  }

  ip->nlink++;
    80005696:	04a4d783          	lhu	a5,74(s1)
    8000569a:	2785                	addiw	a5,a5,1
    8000569c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056a0:	8526                	mv	a0,s1
    800056a2:	ffffe097          	auipc	ra,0xffffe
    800056a6:	ec0080e7          	jalr	-320(ra) # 80003562 <iupdate>
  iunlock(ip);
    800056aa:	8526                	mv	a0,s1
    800056ac:	ffffe097          	auipc	ra,0xffffe
    800056b0:	042080e7          	jalr	66(ra) # 800036ee <iunlock>

  if((dp = nameiparent(new, name)) == 0)
    800056b4:	fd040593          	addi	a1,s0,-48
    800056b8:	f5040513          	addi	a0,s0,-176
    800056bc:	ffffe097          	auipc	ra,0xffffe
    800056c0:	734080e7          	jalr	1844(ra) # 80003df0 <nameiparent>
    800056c4:	892a                	mv	s2,a0
    800056c6:	c935                	beqz	a0,8000573a <sys_link+0x10a>
    goto bad;
  ilock(dp);
    800056c8:	ffffe097          	auipc	ra,0xffffe
    800056cc:	f64080e7          	jalr	-156(ra) # 8000362c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800056d0:	00092703          	lw	a4,0(s2)
    800056d4:	409c                	lw	a5,0(s1)
    800056d6:	04f71d63          	bne	a4,a5,80005730 <sys_link+0x100>
    800056da:	40d0                	lw	a2,4(s1)
    800056dc:	fd040593          	addi	a1,s0,-48
    800056e0:	854a                	mv	a0,s2
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	63e080e7          	jalr	1598(ra) # 80003d20 <dirlink>
    800056ea:	04054363          	bltz	a0,80005730 <sys_link+0x100>
    iunlockput(dp);
    goto bad;
  }
  iunlockput(dp);
    800056ee:	854a                	mv	a0,s2
    800056f0:	ffffe097          	auipc	ra,0xffffe
    800056f4:	19e080e7          	jalr	414(ra) # 8000388e <iunlockput>
  iput(ip);
    800056f8:	8526                	mv	a0,s1
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	0ec080e7          	jalr	236(ra) # 800037e6 <iput>

  end_op();
    80005702:	fffff097          	auipc	ra,0xfffff
    80005706:	c7e080e7          	jalr	-898(ra) # 80004380 <end_op>

  return 0;
    8000570a:	4781                	li	a5,0
    8000570c:	a085                	j	8000576c <sys_link+0x13c>
    end_op();
    8000570e:	fffff097          	auipc	ra,0xfffff
    80005712:	c72080e7          	jalr	-910(ra) # 80004380 <end_op>
    return -1;
    80005716:	57fd                	li	a5,-1
    80005718:	a891                	j	8000576c <sys_link+0x13c>
    iunlockput(ip);
    8000571a:	8526                	mv	a0,s1
    8000571c:	ffffe097          	auipc	ra,0xffffe
    80005720:	172080e7          	jalr	370(ra) # 8000388e <iunlockput>
    end_op();
    80005724:	fffff097          	auipc	ra,0xfffff
    80005728:	c5c080e7          	jalr	-932(ra) # 80004380 <end_op>
    return -1;
    8000572c:	57fd                	li	a5,-1
    8000572e:	a83d                	j	8000576c <sys_link+0x13c>
    iunlockput(dp);
    80005730:	854a                	mv	a0,s2
    80005732:	ffffe097          	auipc	ra,0xffffe
    80005736:	15c080e7          	jalr	348(ra) # 8000388e <iunlockput>

bad:
  ilock(ip);
    8000573a:	8526                	mv	a0,s1
    8000573c:	ffffe097          	auipc	ra,0xffffe
    80005740:	ef0080e7          	jalr	-272(ra) # 8000362c <ilock>
  ip->nlink--;
    80005744:	04a4d783          	lhu	a5,74(s1)
    80005748:	37fd                	addiw	a5,a5,-1
    8000574a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000574e:	8526                	mv	a0,s1
    80005750:	ffffe097          	auipc	ra,0xffffe
    80005754:	e12080e7          	jalr	-494(ra) # 80003562 <iupdate>
  iunlockput(ip);
    80005758:	8526                	mv	a0,s1
    8000575a:	ffffe097          	auipc	ra,0xffffe
    8000575e:	134080e7          	jalr	308(ra) # 8000388e <iunlockput>
  end_op();
    80005762:	fffff097          	auipc	ra,0xfffff
    80005766:	c1e080e7          	jalr	-994(ra) # 80004380 <end_op>
  return -1;
    8000576a:	57fd                	li	a5,-1
}
    8000576c:	853e                	mv	a0,a5
    8000576e:	70b2                	ld	ra,296(sp)
    80005770:	7412                	ld	s0,288(sp)
    80005772:	64f2                	ld	s1,280(sp)
    80005774:	6952                	ld	s2,272(sp)
    80005776:	6155                	addi	sp,sp,304
    80005778:	8082                	ret

000000008000577a <isdirempty>:
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000577a:	4578                	lw	a4,76(a0)
    8000577c:	02000793          	li	a5,32
    80005780:	04e7fa63          	bgeu	a5,a4,800057d4 <isdirempty+0x5a>
{
    80005784:	7179                	addi	sp,sp,-48
    80005786:	f406                	sd	ra,40(sp)
    80005788:	f022                	sd	s0,32(sp)
    8000578a:	ec26                	sd	s1,24(sp)
    8000578c:	e84a                	sd	s2,16(sp)
    8000578e:	1800                	addi	s0,sp,48
    80005790:	892a                	mv	s2,a0
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005792:	02000493          	li	s1,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005796:	4741                	li	a4,16
    80005798:	86a6                	mv	a3,s1
    8000579a:	fd040613          	addi	a2,s0,-48
    8000579e:	4581                	li	a1,0
    800057a0:	854a                	mv	a0,s2
    800057a2:	ffffe097          	auipc	ra,0xffffe
    800057a6:	13e080e7          	jalr	318(ra) # 800038e0 <readi>
    800057aa:	47c1                	li	a5,16
    800057ac:	00f51c63          	bne	a0,a5,800057c4 <isdirempty+0x4a>
      panic("isdirempty: readi");
    if(de.inum != 0)
    800057b0:	fd045783          	lhu	a5,-48(s0)
    800057b4:	e395                	bnez	a5,800057d8 <isdirempty+0x5e>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057b6:	24c1                	addiw	s1,s1,16
    800057b8:	04c92783          	lw	a5,76(s2)
    800057bc:	fcf4ede3          	bltu	s1,a5,80005796 <isdirempty+0x1c>
      return 0;
  }
  return 1;
    800057c0:	4505                	li	a0,1
    800057c2:	a821                	j	800057da <isdirempty+0x60>
      panic("isdirempty: readi");
    800057c4:	00003517          	auipc	a0,0x3
    800057c8:	f9c50513          	addi	a0,a0,-100 # 80008760 <syscalls+0x310>
    800057cc:	ffffb097          	auipc	ra,0xffffb
    800057d0:	d72080e7          	jalr	-654(ra) # 8000053e <panic>
  return 1;
    800057d4:	4505                	li	a0,1
}
    800057d6:	8082                	ret
      return 0;
    800057d8:	4501                	li	a0,0
}
    800057da:	70a2                	ld	ra,40(sp)
    800057dc:	7402                	ld	s0,32(sp)
    800057de:	64e2                	ld	s1,24(sp)
    800057e0:	6942                	ld	s2,16(sp)
    800057e2:	6145                	addi	sp,sp,48
    800057e4:	8082                	ret

00000000800057e6 <sys_unlink>:

uint64
sys_unlink(void)
{
    800057e6:	7155                	addi	sp,sp,-208
    800057e8:	e586                	sd	ra,200(sp)
    800057ea:	e1a2                	sd	s0,192(sp)
    800057ec:	fd26                	sd	s1,184(sp)
    800057ee:	f94a                	sd	s2,176(sp)
    800057f0:	0980                	addi	s0,sp,208
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], path[MAXPATH];
  uint off;

  if(argstr(0, path, MAXPATH) < 0)
    800057f2:	08000613          	li	a2,128
    800057f6:	f4040593          	addi	a1,s0,-192
    800057fa:	4501                	li	a0,0
    800057fc:	ffffd097          	auipc	ra,0xffffd
    80005800:	304080e7          	jalr	772(ra) # 80002b00 <argstr>
    80005804:	16054363          	bltz	a0,8000596a <sys_unlink+0x184>
    return -1;

  begin_op();
    80005808:	fffff097          	auipc	ra,0xfffff
    8000580c:	af8080e7          	jalr	-1288(ra) # 80004300 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005810:	fc040593          	addi	a1,s0,-64
    80005814:	f4040513          	addi	a0,s0,-192
    80005818:	ffffe097          	auipc	ra,0xffffe
    8000581c:	5d8080e7          	jalr	1496(ra) # 80003df0 <nameiparent>
    80005820:	84aa                	mv	s1,a0
    80005822:	c961                	beqz	a0,800058f2 <sys_unlink+0x10c>
    end_op();
    return -1;
  }

  ilock(dp);
    80005824:	ffffe097          	auipc	ra,0xffffe
    80005828:	e08080e7          	jalr	-504(ra) # 8000362c <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000582c:	00003597          	auipc	a1,0x3
    80005830:	e1458593          	addi	a1,a1,-492 # 80008640 <syscalls+0x1f0>
    80005834:	fc040513          	addi	a0,s0,-64
    80005838:	ffffe097          	auipc	ra,0xffffe
    8000583c:	2be080e7          	jalr	702(ra) # 80003af6 <namecmp>
    80005840:	c175                	beqz	a0,80005924 <sys_unlink+0x13e>
    80005842:	00003597          	auipc	a1,0x3
    80005846:	e0658593          	addi	a1,a1,-506 # 80008648 <syscalls+0x1f8>
    8000584a:	fc040513          	addi	a0,s0,-64
    8000584e:	ffffe097          	auipc	ra,0xffffe
    80005852:	2a8080e7          	jalr	680(ra) # 80003af6 <namecmp>
    80005856:	c579                	beqz	a0,80005924 <sys_unlink+0x13e>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    80005858:	f3c40613          	addi	a2,s0,-196
    8000585c:	fc040593          	addi	a1,s0,-64
    80005860:	8526                	mv	a0,s1
    80005862:	ffffe097          	auipc	ra,0xffffe
    80005866:	2ae080e7          	jalr	686(ra) # 80003b10 <dirlookup>
    8000586a:	892a                	mv	s2,a0
    8000586c:	cd45                	beqz	a0,80005924 <sys_unlink+0x13e>
    goto bad;
  ilock(ip);
    8000586e:	ffffe097          	auipc	ra,0xffffe
    80005872:	dbe080e7          	jalr	-578(ra) # 8000362c <ilock>

  if(ip->nlink < 1)
    80005876:	04a91783          	lh	a5,74(s2)
    8000587a:	08f05263          	blez	a5,800058fe <sys_unlink+0x118>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000587e:	04491703          	lh	a4,68(s2)
    80005882:	4785                	li	a5,1
    80005884:	08f70563          	beq	a4,a5,8000590e <sys_unlink+0x128>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    80005888:	4641                	li	a2,16
    8000588a:	4581                	li	a1,0
    8000588c:	fd040513          	addi	a0,s0,-48
    80005890:	ffffb097          	auipc	ra,0xffffb
    80005894:	442080e7          	jalr	1090(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005898:	4741                	li	a4,16
    8000589a:	f3c42683          	lw	a3,-196(s0)
    8000589e:	fd040613          	addi	a2,s0,-48
    800058a2:	4581                	li	a1,0
    800058a4:	8526                	mv	a0,s1
    800058a6:	ffffe097          	auipc	ra,0xffffe
    800058aa:	132080e7          	jalr	306(ra) # 800039d8 <writei>
    800058ae:	47c1                	li	a5,16
    800058b0:	08f51a63          	bne	a0,a5,80005944 <sys_unlink+0x15e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    800058b4:	04491703          	lh	a4,68(s2)
    800058b8:	4785                	li	a5,1
    800058ba:	08f70d63          	beq	a4,a5,80005954 <sys_unlink+0x16e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    800058be:	8526                	mv	a0,s1
    800058c0:	ffffe097          	auipc	ra,0xffffe
    800058c4:	fce080e7          	jalr	-50(ra) # 8000388e <iunlockput>

  ip->nlink--;
    800058c8:	04a95783          	lhu	a5,74(s2)
    800058cc:	37fd                	addiw	a5,a5,-1
    800058ce:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800058d2:	854a                	mv	a0,s2
    800058d4:	ffffe097          	auipc	ra,0xffffe
    800058d8:	c8e080e7          	jalr	-882(ra) # 80003562 <iupdate>
  iunlockput(ip);
    800058dc:	854a                	mv	a0,s2
    800058de:	ffffe097          	auipc	ra,0xffffe
    800058e2:	fb0080e7          	jalr	-80(ra) # 8000388e <iunlockput>

  end_op();
    800058e6:	fffff097          	auipc	ra,0xfffff
    800058ea:	a9a080e7          	jalr	-1382(ra) # 80004380 <end_op>

  return 0;
    800058ee:	4501                	li	a0,0
    800058f0:	a0a1                	j	80005938 <sys_unlink+0x152>
    end_op();
    800058f2:	fffff097          	auipc	ra,0xfffff
    800058f6:	a8e080e7          	jalr	-1394(ra) # 80004380 <end_op>
    return -1;
    800058fa:	557d                	li	a0,-1
    800058fc:	a835                	j	80005938 <sys_unlink+0x152>
    panic("unlink: nlink < 1");
    800058fe:	00003517          	auipc	a0,0x3
    80005902:	d5250513          	addi	a0,a0,-686 # 80008650 <syscalls+0x200>
    80005906:	ffffb097          	auipc	ra,0xffffb
    8000590a:	c38080e7          	jalr	-968(ra) # 8000053e <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000590e:	854a                	mv	a0,s2
    80005910:	00000097          	auipc	ra,0x0
    80005914:	e6a080e7          	jalr	-406(ra) # 8000577a <isdirempty>
    80005918:	f925                	bnez	a0,80005888 <sys_unlink+0xa2>
    iunlockput(ip);
    8000591a:	854a                	mv	a0,s2
    8000591c:	ffffe097          	auipc	ra,0xffffe
    80005920:	f72080e7          	jalr	-142(ra) # 8000388e <iunlockput>

bad:
  iunlockput(dp);
    80005924:	8526                	mv	a0,s1
    80005926:	ffffe097          	auipc	ra,0xffffe
    8000592a:	f68080e7          	jalr	-152(ra) # 8000388e <iunlockput>
  end_op();
    8000592e:	fffff097          	auipc	ra,0xfffff
    80005932:	a52080e7          	jalr	-1454(ra) # 80004380 <end_op>
  return -1;
    80005936:	557d                	li	a0,-1
}
    80005938:	60ae                	ld	ra,200(sp)
    8000593a:	640e                	ld	s0,192(sp)
    8000593c:	74ea                	ld	s1,184(sp)
    8000593e:	794a                	ld	s2,176(sp)
    80005940:	6169                	addi	sp,sp,208
    80005942:	8082                	ret
    panic("unlink: writei");
    80005944:	00003517          	auipc	a0,0x3
    80005948:	d2450513          	addi	a0,a0,-732 # 80008668 <syscalls+0x218>
    8000594c:	ffffb097          	auipc	ra,0xffffb
    80005950:	bf2080e7          	jalr	-1038(ra) # 8000053e <panic>
    dp->nlink--;
    80005954:	04a4d783          	lhu	a5,74(s1)
    80005958:	37fd                	addiw	a5,a5,-1
    8000595a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000595e:	8526                	mv	a0,s1
    80005960:	ffffe097          	auipc	ra,0xffffe
    80005964:	c02080e7          	jalr	-1022(ra) # 80003562 <iupdate>
    80005968:	bf99                	j	800058be <sys_unlink+0xd8>
    return -1;
    8000596a:	557d                	li	a0,-1
    8000596c:	b7f1                	j	80005938 <sys_unlink+0x152>

000000008000596e <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
    8000596e:	715d                	addi	sp,sp,-80
    80005970:	e486                	sd	ra,72(sp)
    80005972:	e0a2                	sd	s0,64(sp)
    80005974:	fc26                	sd	s1,56(sp)
    80005976:	f84a                	sd	s2,48(sp)
    80005978:	f44e                	sd	s3,40(sp)
    8000597a:	f052                	sd	s4,32(sp)
    8000597c:	ec56                	sd	s5,24(sp)
    8000597e:	e85a                	sd	s6,16(sp)
    80005980:	0880                	addi	s0,sp,80
    80005982:	8b2e                	mv	s6,a1
    80005984:	89b2                	mv	s3,a2
    80005986:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005988:	fb040593          	addi	a1,s0,-80
    8000598c:	ffffe097          	auipc	ra,0xffffe
    80005990:	464080e7          	jalr	1124(ra) # 80003df0 <nameiparent>
    80005994:	84aa                	mv	s1,a0
    80005996:	14050f63          	beqz	a0,80005af4 <create+0x186>
    return 0;

  ilock(dp);
    8000599a:	ffffe097          	auipc	ra,0xffffe
    8000599e:	c92080e7          	jalr	-878(ra) # 8000362c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800059a2:	4601                	li	a2,0
    800059a4:	fb040593          	addi	a1,s0,-80
    800059a8:	8526                	mv	a0,s1
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	166080e7          	jalr	358(ra) # 80003b10 <dirlookup>
    800059b2:	8aaa                	mv	s5,a0
    800059b4:	c931                	beqz	a0,80005a08 <create+0x9a>
    iunlockput(dp);
    800059b6:	8526                	mv	a0,s1
    800059b8:	ffffe097          	auipc	ra,0xffffe
    800059bc:	ed6080e7          	jalr	-298(ra) # 8000388e <iunlockput>
    ilock(ip);
    800059c0:	8556                	mv	a0,s5
    800059c2:	ffffe097          	auipc	ra,0xffffe
    800059c6:	c6a080e7          	jalr	-918(ra) # 8000362c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800059ca:	000b059b          	sext.w	a1,s6
    800059ce:	4789                	li	a5,2
    800059d0:	02f59563          	bne	a1,a5,800059fa <create+0x8c>
    800059d4:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdd0a4>
    800059d8:	37f9                	addiw	a5,a5,-2
    800059da:	17c2                	slli	a5,a5,0x30
    800059dc:	93c1                	srli	a5,a5,0x30
    800059de:	4705                	li	a4,1
    800059e0:	00f76d63          	bltu	a4,a5,800059fa <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800059e4:	8556                	mv	a0,s5
    800059e6:	60a6                	ld	ra,72(sp)
    800059e8:	6406                	ld	s0,64(sp)
    800059ea:	74e2                	ld	s1,56(sp)
    800059ec:	7942                	ld	s2,48(sp)
    800059ee:	79a2                	ld	s3,40(sp)
    800059f0:	7a02                	ld	s4,32(sp)
    800059f2:	6ae2                	ld	s5,24(sp)
    800059f4:	6b42                	ld	s6,16(sp)
    800059f6:	6161                	addi	sp,sp,80
    800059f8:	8082                	ret
    iunlockput(ip);
    800059fa:	8556                	mv	a0,s5
    800059fc:	ffffe097          	auipc	ra,0xffffe
    80005a00:	e92080e7          	jalr	-366(ra) # 8000388e <iunlockput>
    return 0;
    80005a04:	4a81                	li	s5,0
    80005a06:	bff9                	j	800059e4 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005a08:	85da                	mv	a1,s6
    80005a0a:	4088                	lw	a0,0(s1)
    80005a0c:	ffffe097          	auipc	ra,0xffffe
    80005a10:	a84080e7          	jalr	-1404(ra) # 80003490 <ialloc>
    80005a14:	8a2a                	mv	s4,a0
    80005a16:	c539                	beqz	a0,80005a64 <create+0xf6>
  ilock(ip);
    80005a18:	ffffe097          	auipc	ra,0xffffe
    80005a1c:	c14080e7          	jalr	-1004(ra) # 8000362c <ilock>
  ip->major = major;
    80005a20:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005a24:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005a28:	4905                	li	s2,1
    80005a2a:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005a2e:	8552                	mv	a0,s4
    80005a30:	ffffe097          	auipc	ra,0xffffe
    80005a34:	b32080e7          	jalr	-1230(ra) # 80003562 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005a38:	000b059b          	sext.w	a1,s6
    80005a3c:	03258b63          	beq	a1,s2,80005a72 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005a40:	004a2603          	lw	a2,4(s4)
    80005a44:	fb040593          	addi	a1,s0,-80
    80005a48:	8526                	mv	a0,s1
    80005a4a:	ffffe097          	auipc	ra,0xffffe
    80005a4e:	2d6080e7          	jalr	726(ra) # 80003d20 <dirlink>
    80005a52:	06054f63          	bltz	a0,80005ad0 <create+0x162>
  iunlockput(dp);
    80005a56:	8526                	mv	a0,s1
    80005a58:	ffffe097          	auipc	ra,0xffffe
    80005a5c:	e36080e7          	jalr	-458(ra) # 8000388e <iunlockput>
  return ip;
    80005a60:	8ad2                	mv	s5,s4
    80005a62:	b749                	j	800059e4 <create+0x76>
    iunlockput(dp);
    80005a64:	8526                	mv	a0,s1
    80005a66:	ffffe097          	auipc	ra,0xffffe
    80005a6a:	e28080e7          	jalr	-472(ra) # 8000388e <iunlockput>
    return 0;
    80005a6e:	8ad2                	mv	s5,s4
    80005a70:	bf95                	j	800059e4 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005a72:	004a2603          	lw	a2,4(s4)
    80005a76:	00003597          	auipc	a1,0x3
    80005a7a:	bca58593          	addi	a1,a1,-1078 # 80008640 <syscalls+0x1f0>
    80005a7e:	8552                	mv	a0,s4
    80005a80:	ffffe097          	auipc	ra,0xffffe
    80005a84:	2a0080e7          	jalr	672(ra) # 80003d20 <dirlink>
    80005a88:	04054463          	bltz	a0,80005ad0 <create+0x162>
    80005a8c:	40d0                	lw	a2,4(s1)
    80005a8e:	00003597          	auipc	a1,0x3
    80005a92:	bba58593          	addi	a1,a1,-1094 # 80008648 <syscalls+0x1f8>
    80005a96:	8552                	mv	a0,s4
    80005a98:	ffffe097          	auipc	ra,0xffffe
    80005a9c:	288080e7          	jalr	648(ra) # 80003d20 <dirlink>
    80005aa0:	02054863          	bltz	a0,80005ad0 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005aa4:	004a2603          	lw	a2,4(s4)
    80005aa8:	fb040593          	addi	a1,s0,-80
    80005aac:	8526                	mv	a0,s1
    80005aae:	ffffe097          	auipc	ra,0xffffe
    80005ab2:	272080e7          	jalr	626(ra) # 80003d20 <dirlink>
    80005ab6:	00054d63          	bltz	a0,80005ad0 <create+0x162>
    dp->nlink++;  // for ".."
    80005aba:	04a4d783          	lhu	a5,74(s1)
    80005abe:	2785                	addiw	a5,a5,1
    80005ac0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005ac4:	8526                	mv	a0,s1
    80005ac6:	ffffe097          	auipc	ra,0xffffe
    80005aca:	a9c080e7          	jalr	-1380(ra) # 80003562 <iupdate>
    80005ace:	b761                	j	80005a56 <create+0xe8>
  ip->nlink = 0;
    80005ad0:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005ad4:	8552                	mv	a0,s4
    80005ad6:	ffffe097          	auipc	ra,0xffffe
    80005ada:	a8c080e7          	jalr	-1396(ra) # 80003562 <iupdate>
  iunlockput(ip);
    80005ade:	8552                	mv	a0,s4
    80005ae0:	ffffe097          	auipc	ra,0xffffe
    80005ae4:	dae080e7          	jalr	-594(ra) # 8000388e <iunlockput>
  iunlockput(dp);
    80005ae8:	8526                	mv	a0,s1
    80005aea:	ffffe097          	auipc	ra,0xffffe
    80005aee:	da4080e7          	jalr	-604(ra) # 8000388e <iunlockput>
  return 0;
    80005af2:	bdcd                	j	800059e4 <create+0x76>
    return 0;
    80005af4:	8aaa                	mv	s5,a0
    80005af6:	b5fd                	j	800059e4 <create+0x76>

0000000080005af8 <sys_open>:

uint64
sys_open(void)
{
    80005af8:	7131                	addi	sp,sp,-192
    80005afa:	fd06                	sd	ra,184(sp)
    80005afc:	f922                	sd	s0,176(sp)
    80005afe:	f526                	sd	s1,168(sp)
    80005b00:	f14a                	sd	s2,160(sp)
    80005b02:	ed4e                	sd	s3,152(sp)
    80005b04:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005b06:	f4c40593          	addi	a1,s0,-180
    80005b0a:	4505                	li	a0,1
    80005b0c:	ffffd097          	auipc	ra,0xffffd
    80005b10:	fb4080e7          	jalr	-76(ra) # 80002ac0 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005b14:	08000613          	li	a2,128
    80005b18:	f5040593          	addi	a1,s0,-176
    80005b1c:	4501                	li	a0,0
    80005b1e:	ffffd097          	auipc	ra,0xffffd
    80005b22:	fe2080e7          	jalr	-30(ra) # 80002b00 <argstr>
    80005b26:	87aa                	mv	a5,a0
    return -1;
    80005b28:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005b2a:	0a07c963          	bltz	a5,80005bdc <sys_open+0xe4>

  begin_op();
    80005b2e:	ffffe097          	auipc	ra,0xffffe
    80005b32:	7d2080e7          	jalr	2002(ra) # 80004300 <begin_op>

  if(omode & O_CREATE){
    80005b36:	f4c42783          	lw	a5,-180(s0)
    80005b3a:	2007f793          	andi	a5,a5,512
    80005b3e:	cfc5                	beqz	a5,80005bf6 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005b40:	4681                	li	a3,0
    80005b42:	4601                	li	a2,0
    80005b44:	4589                	li	a1,2
    80005b46:	f5040513          	addi	a0,s0,-176
    80005b4a:	00000097          	auipc	ra,0x0
    80005b4e:	e24080e7          	jalr	-476(ra) # 8000596e <create>
    80005b52:	84aa                	mv	s1,a0
    if(ip == 0){
    80005b54:	c959                	beqz	a0,80005bea <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b56:	04449703          	lh	a4,68(s1)
    80005b5a:	478d                	li	a5,3
    80005b5c:	00f71763          	bne	a4,a5,80005b6a <sys_open+0x72>
    80005b60:	0464d703          	lhu	a4,70(s1)
    80005b64:	47a5                	li	a5,9
    80005b66:	0ce7ed63          	bltu	a5,a4,80005c40 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b6a:	fffff097          	auipc	ra,0xfffff
    80005b6e:	ba6080e7          	jalr	-1114(ra) # 80004710 <filealloc>
    80005b72:	89aa                	mv	s3,a0
    80005b74:	10050363          	beqz	a0,80005c7a <sys_open+0x182>
    80005b78:	00000097          	auipc	ra,0x0
    80005b7c:	8e4080e7          	jalr	-1820(ra) # 8000545c <fdalloc>
    80005b80:	892a                	mv	s2,a0
    80005b82:	0e054763          	bltz	a0,80005c70 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b86:	04449703          	lh	a4,68(s1)
    80005b8a:	478d                	li	a5,3
    80005b8c:	0cf70563          	beq	a4,a5,80005c56 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b90:	4789                	li	a5,2
    80005b92:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b96:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b9a:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b9e:	f4c42783          	lw	a5,-180(s0)
    80005ba2:	0017c713          	xori	a4,a5,1
    80005ba6:	8b05                	andi	a4,a4,1
    80005ba8:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005bac:	0037f713          	andi	a4,a5,3
    80005bb0:	00e03733          	snez	a4,a4
    80005bb4:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005bb8:	4007f793          	andi	a5,a5,1024
    80005bbc:	c791                	beqz	a5,80005bc8 <sys_open+0xd0>
    80005bbe:	04449703          	lh	a4,68(s1)
    80005bc2:	4789                	li	a5,2
    80005bc4:	0af70063          	beq	a4,a5,80005c64 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005bc8:	8526                	mv	a0,s1
    80005bca:	ffffe097          	auipc	ra,0xffffe
    80005bce:	b24080e7          	jalr	-1244(ra) # 800036ee <iunlock>
  end_op();
    80005bd2:	ffffe097          	auipc	ra,0xffffe
    80005bd6:	7ae080e7          	jalr	1966(ra) # 80004380 <end_op>

  return fd;
    80005bda:	854a                	mv	a0,s2
}
    80005bdc:	70ea                	ld	ra,184(sp)
    80005bde:	744a                	ld	s0,176(sp)
    80005be0:	74aa                	ld	s1,168(sp)
    80005be2:	790a                	ld	s2,160(sp)
    80005be4:	69ea                	ld	s3,152(sp)
    80005be6:	6129                	addi	sp,sp,192
    80005be8:	8082                	ret
      end_op();
    80005bea:	ffffe097          	auipc	ra,0xffffe
    80005bee:	796080e7          	jalr	1942(ra) # 80004380 <end_op>
      return -1;
    80005bf2:	557d                	li	a0,-1
    80005bf4:	b7e5                	j	80005bdc <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005bf6:	f5040513          	addi	a0,s0,-176
    80005bfa:	ffffe097          	auipc	ra,0xffffe
    80005bfe:	1d8080e7          	jalr	472(ra) # 80003dd2 <namei>
    80005c02:	84aa                	mv	s1,a0
    80005c04:	c905                	beqz	a0,80005c34 <sys_open+0x13c>
    ilock(ip);
    80005c06:	ffffe097          	auipc	ra,0xffffe
    80005c0a:	a26080e7          	jalr	-1498(ra) # 8000362c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c0e:	04449703          	lh	a4,68(s1)
    80005c12:	4785                	li	a5,1
    80005c14:	f4f711e3          	bne	a4,a5,80005b56 <sys_open+0x5e>
    80005c18:	f4c42783          	lw	a5,-180(s0)
    80005c1c:	d7b9                	beqz	a5,80005b6a <sys_open+0x72>
      iunlockput(ip);
    80005c1e:	8526                	mv	a0,s1
    80005c20:	ffffe097          	auipc	ra,0xffffe
    80005c24:	c6e080e7          	jalr	-914(ra) # 8000388e <iunlockput>
      end_op();
    80005c28:	ffffe097          	auipc	ra,0xffffe
    80005c2c:	758080e7          	jalr	1880(ra) # 80004380 <end_op>
      return -1;
    80005c30:	557d                	li	a0,-1
    80005c32:	b76d                	j	80005bdc <sys_open+0xe4>
      end_op();
    80005c34:	ffffe097          	auipc	ra,0xffffe
    80005c38:	74c080e7          	jalr	1868(ra) # 80004380 <end_op>
      return -1;
    80005c3c:	557d                	li	a0,-1
    80005c3e:	bf79                	j	80005bdc <sys_open+0xe4>
    iunlockput(ip);
    80005c40:	8526                	mv	a0,s1
    80005c42:	ffffe097          	auipc	ra,0xffffe
    80005c46:	c4c080e7          	jalr	-948(ra) # 8000388e <iunlockput>
    end_op();
    80005c4a:	ffffe097          	auipc	ra,0xffffe
    80005c4e:	736080e7          	jalr	1846(ra) # 80004380 <end_op>
    return -1;
    80005c52:	557d                	li	a0,-1
    80005c54:	b761                	j	80005bdc <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005c56:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005c5a:	04649783          	lh	a5,70(s1)
    80005c5e:	02f99223          	sh	a5,36(s3)
    80005c62:	bf25                	j	80005b9a <sys_open+0xa2>
    itrunc(ip);
    80005c64:	8526                	mv	a0,s1
    80005c66:	ffffe097          	auipc	ra,0xffffe
    80005c6a:	ad4080e7          	jalr	-1324(ra) # 8000373a <itrunc>
    80005c6e:	bfa9                	j	80005bc8 <sys_open+0xd0>
      fileclose(f);
    80005c70:	854e                	mv	a0,s3
    80005c72:	fffff097          	auipc	ra,0xfffff
    80005c76:	b5a080e7          	jalr	-1190(ra) # 800047cc <fileclose>
    iunlockput(ip);
    80005c7a:	8526                	mv	a0,s1
    80005c7c:	ffffe097          	auipc	ra,0xffffe
    80005c80:	c12080e7          	jalr	-1006(ra) # 8000388e <iunlockput>
    end_op();
    80005c84:	ffffe097          	auipc	ra,0xffffe
    80005c88:	6fc080e7          	jalr	1788(ra) # 80004380 <end_op>
    return -1;
    80005c8c:	557d                	li	a0,-1
    80005c8e:	b7b9                	j	80005bdc <sys_open+0xe4>

0000000080005c90 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c90:	7175                	addi	sp,sp,-144
    80005c92:	e506                	sd	ra,136(sp)
    80005c94:	e122                	sd	s0,128(sp)
    80005c96:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c98:	ffffe097          	auipc	ra,0xffffe
    80005c9c:	668080e7          	jalr	1640(ra) # 80004300 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005ca0:	08000613          	li	a2,128
    80005ca4:	f7040593          	addi	a1,s0,-144
    80005ca8:	4501                	li	a0,0
    80005caa:	ffffd097          	auipc	ra,0xffffd
    80005cae:	e56080e7          	jalr	-426(ra) # 80002b00 <argstr>
    80005cb2:	02054963          	bltz	a0,80005ce4 <sys_mkdir+0x54>
    80005cb6:	4681                	li	a3,0
    80005cb8:	4601                	li	a2,0
    80005cba:	4585                	li	a1,1
    80005cbc:	f7040513          	addi	a0,s0,-144
    80005cc0:	00000097          	auipc	ra,0x0
    80005cc4:	cae080e7          	jalr	-850(ra) # 8000596e <create>
    80005cc8:	cd11                	beqz	a0,80005ce4 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cca:	ffffe097          	auipc	ra,0xffffe
    80005cce:	bc4080e7          	jalr	-1084(ra) # 8000388e <iunlockput>
  end_op();
    80005cd2:	ffffe097          	auipc	ra,0xffffe
    80005cd6:	6ae080e7          	jalr	1710(ra) # 80004380 <end_op>
  return 0;
    80005cda:	4501                	li	a0,0
}
    80005cdc:	60aa                	ld	ra,136(sp)
    80005cde:	640a                	ld	s0,128(sp)
    80005ce0:	6149                	addi	sp,sp,144
    80005ce2:	8082                	ret
    end_op();
    80005ce4:	ffffe097          	auipc	ra,0xffffe
    80005ce8:	69c080e7          	jalr	1692(ra) # 80004380 <end_op>
    return -1;
    80005cec:	557d                	li	a0,-1
    80005cee:	b7fd                	j	80005cdc <sys_mkdir+0x4c>

0000000080005cf0 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005cf0:	7135                	addi	sp,sp,-160
    80005cf2:	ed06                	sd	ra,152(sp)
    80005cf4:	e922                	sd	s0,144(sp)
    80005cf6:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005cf8:	ffffe097          	auipc	ra,0xffffe
    80005cfc:	608080e7          	jalr	1544(ra) # 80004300 <begin_op>
  argint(1, &major);
    80005d00:	f6c40593          	addi	a1,s0,-148
    80005d04:	4505                	li	a0,1
    80005d06:	ffffd097          	auipc	ra,0xffffd
    80005d0a:	dba080e7          	jalr	-582(ra) # 80002ac0 <argint>
  argint(2, &minor);
    80005d0e:	f6840593          	addi	a1,s0,-152
    80005d12:	4509                	li	a0,2
    80005d14:	ffffd097          	auipc	ra,0xffffd
    80005d18:	dac080e7          	jalr	-596(ra) # 80002ac0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d1c:	08000613          	li	a2,128
    80005d20:	f7040593          	addi	a1,s0,-144
    80005d24:	4501                	li	a0,0
    80005d26:	ffffd097          	auipc	ra,0xffffd
    80005d2a:	dda080e7          	jalr	-550(ra) # 80002b00 <argstr>
    80005d2e:	02054b63          	bltz	a0,80005d64 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d32:	f6841683          	lh	a3,-152(s0)
    80005d36:	f6c41603          	lh	a2,-148(s0)
    80005d3a:	458d                	li	a1,3
    80005d3c:	f7040513          	addi	a0,s0,-144
    80005d40:	00000097          	auipc	ra,0x0
    80005d44:	c2e080e7          	jalr	-978(ra) # 8000596e <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d48:	cd11                	beqz	a0,80005d64 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d4a:	ffffe097          	auipc	ra,0xffffe
    80005d4e:	b44080e7          	jalr	-1212(ra) # 8000388e <iunlockput>
  end_op();
    80005d52:	ffffe097          	auipc	ra,0xffffe
    80005d56:	62e080e7          	jalr	1582(ra) # 80004380 <end_op>
  return 0;
    80005d5a:	4501                	li	a0,0
}
    80005d5c:	60ea                	ld	ra,152(sp)
    80005d5e:	644a                	ld	s0,144(sp)
    80005d60:	610d                	addi	sp,sp,160
    80005d62:	8082                	ret
    end_op();
    80005d64:	ffffe097          	auipc	ra,0xffffe
    80005d68:	61c080e7          	jalr	1564(ra) # 80004380 <end_op>
    return -1;
    80005d6c:	557d                	li	a0,-1
    80005d6e:	b7fd                	j	80005d5c <sys_mknod+0x6c>

0000000080005d70 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d70:	7135                	addi	sp,sp,-160
    80005d72:	ed06                	sd	ra,152(sp)
    80005d74:	e922                	sd	s0,144(sp)
    80005d76:	e526                	sd	s1,136(sp)
    80005d78:	e14a                	sd	s2,128(sp)
    80005d7a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d7c:	ffffc097          	auipc	ra,0xffffc
    80005d80:	c30080e7          	jalr	-976(ra) # 800019ac <myproc>
    80005d84:	892a                	mv	s2,a0
  
  begin_op();
    80005d86:	ffffe097          	auipc	ra,0xffffe
    80005d8a:	57a080e7          	jalr	1402(ra) # 80004300 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d8e:	08000613          	li	a2,128
    80005d92:	f6040593          	addi	a1,s0,-160
    80005d96:	4501                	li	a0,0
    80005d98:	ffffd097          	auipc	ra,0xffffd
    80005d9c:	d68080e7          	jalr	-664(ra) # 80002b00 <argstr>
    80005da0:	04054b63          	bltz	a0,80005df6 <sys_chdir+0x86>
    80005da4:	f6040513          	addi	a0,s0,-160
    80005da8:	ffffe097          	auipc	ra,0xffffe
    80005dac:	02a080e7          	jalr	42(ra) # 80003dd2 <namei>
    80005db0:	84aa                	mv	s1,a0
    80005db2:	c131                	beqz	a0,80005df6 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005db4:	ffffe097          	auipc	ra,0xffffe
    80005db8:	878080e7          	jalr	-1928(ra) # 8000362c <ilock>
  if(ip->type != T_DIR){
    80005dbc:	04449703          	lh	a4,68(s1)
    80005dc0:	4785                	li	a5,1
    80005dc2:	04f71063          	bne	a4,a5,80005e02 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005dc6:	8526                	mv	a0,s1
    80005dc8:	ffffe097          	auipc	ra,0xffffe
    80005dcc:	926080e7          	jalr	-1754(ra) # 800036ee <iunlock>
  iput(p->cwd);
    80005dd0:	15093503          	ld	a0,336(s2)
    80005dd4:	ffffe097          	auipc	ra,0xffffe
    80005dd8:	a12080e7          	jalr	-1518(ra) # 800037e6 <iput>
  end_op();
    80005ddc:	ffffe097          	auipc	ra,0xffffe
    80005de0:	5a4080e7          	jalr	1444(ra) # 80004380 <end_op>
  p->cwd = ip;
    80005de4:	14993823          	sd	s1,336(s2)
  return 0;
    80005de8:	4501                	li	a0,0
}
    80005dea:	60ea                	ld	ra,152(sp)
    80005dec:	644a                	ld	s0,144(sp)
    80005dee:	64aa                	ld	s1,136(sp)
    80005df0:	690a                	ld	s2,128(sp)
    80005df2:	610d                	addi	sp,sp,160
    80005df4:	8082                	ret
    end_op();
    80005df6:	ffffe097          	auipc	ra,0xffffe
    80005dfa:	58a080e7          	jalr	1418(ra) # 80004380 <end_op>
    return -1;
    80005dfe:	557d                	li	a0,-1
    80005e00:	b7ed                	j	80005dea <sys_chdir+0x7a>
    iunlockput(ip);
    80005e02:	8526                	mv	a0,s1
    80005e04:	ffffe097          	auipc	ra,0xffffe
    80005e08:	a8a080e7          	jalr	-1398(ra) # 8000388e <iunlockput>
    end_op();
    80005e0c:	ffffe097          	auipc	ra,0xffffe
    80005e10:	574080e7          	jalr	1396(ra) # 80004380 <end_op>
    return -1;
    80005e14:	557d                	li	a0,-1
    80005e16:	bfd1                	j	80005dea <sys_chdir+0x7a>

0000000080005e18 <sys_exec>:

uint64
sys_exec(void)
{
    80005e18:	7145                	addi	sp,sp,-464
    80005e1a:	e786                	sd	ra,456(sp)
    80005e1c:	e3a2                	sd	s0,448(sp)
    80005e1e:	ff26                	sd	s1,440(sp)
    80005e20:	fb4a                	sd	s2,432(sp)
    80005e22:	f74e                	sd	s3,424(sp)
    80005e24:	f352                	sd	s4,416(sp)
    80005e26:	ef56                	sd	s5,408(sp)
    80005e28:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005e2a:	e3840593          	addi	a1,s0,-456
    80005e2e:	4505                	li	a0,1
    80005e30:	ffffd097          	auipc	ra,0xffffd
    80005e34:	cb0080e7          	jalr	-848(ra) # 80002ae0 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005e38:	08000613          	li	a2,128
    80005e3c:	f4040593          	addi	a1,s0,-192
    80005e40:	4501                	li	a0,0
    80005e42:	ffffd097          	auipc	ra,0xffffd
    80005e46:	cbe080e7          	jalr	-834(ra) # 80002b00 <argstr>
    80005e4a:	87aa                	mv	a5,a0
    return -1;
    80005e4c:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005e4e:	0c07c263          	bltz	a5,80005f12 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005e52:	10000613          	li	a2,256
    80005e56:	4581                	li	a1,0
    80005e58:	e4040513          	addi	a0,s0,-448
    80005e5c:	ffffb097          	auipc	ra,0xffffb
    80005e60:	e76080e7          	jalr	-394(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e64:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005e68:	89a6                	mv	s3,s1
    80005e6a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e6c:	02000a13          	li	s4,32
    80005e70:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e74:	00391793          	slli	a5,s2,0x3
    80005e78:	e3040593          	addi	a1,s0,-464
    80005e7c:	e3843503          	ld	a0,-456(s0)
    80005e80:	953e                	add	a0,a0,a5
    80005e82:	ffffd097          	auipc	ra,0xffffd
    80005e86:	ba0080e7          	jalr	-1120(ra) # 80002a22 <fetchaddr>
    80005e8a:	02054a63          	bltz	a0,80005ebe <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005e8e:	e3043783          	ld	a5,-464(s0)
    80005e92:	c3b9                	beqz	a5,80005ed8 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e94:	ffffb097          	auipc	ra,0xffffb
    80005e98:	c52080e7          	jalr	-942(ra) # 80000ae6 <kalloc>
    80005e9c:	85aa                	mv	a1,a0
    80005e9e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ea2:	cd11                	beqz	a0,80005ebe <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ea4:	6605                	lui	a2,0x1
    80005ea6:	e3043503          	ld	a0,-464(s0)
    80005eaa:	ffffd097          	auipc	ra,0xffffd
    80005eae:	bca080e7          	jalr	-1078(ra) # 80002a74 <fetchstr>
    80005eb2:	00054663          	bltz	a0,80005ebe <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005eb6:	0905                	addi	s2,s2,1
    80005eb8:	09a1                	addi	s3,s3,8
    80005eba:	fb491be3          	bne	s2,s4,80005e70 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ebe:	10048913          	addi	s2,s1,256
    80005ec2:	6088                	ld	a0,0(s1)
    80005ec4:	c531                	beqz	a0,80005f10 <sys_exec+0xf8>
    kfree(argv[i]);
    80005ec6:	ffffb097          	auipc	ra,0xffffb
    80005eca:	b24080e7          	jalr	-1244(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ece:	04a1                	addi	s1,s1,8
    80005ed0:	ff2499e3          	bne	s1,s2,80005ec2 <sys_exec+0xaa>
  return -1;
    80005ed4:	557d                	li	a0,-1
    80005ed6:	a835                	j	80005f12 <sys_exec+0xfa>
      argv[i] = 0;
    80005ed8:	0a8e                	slli	s5,s5,0x3
    80005eda:	fc040793          	addi	a5,s0,-64
    80005ede:	9abe                	add	s5,s5,a5
    80005ee0:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ee4:	e4040593          	addi	a1,s0,-448
    80005ee8:	f4040513          	addi	a0,s0,-192
    80005eec:	fffff097          	auipc	ra,0xfffff
    80005ef0:	150080e7          	jalr	336(ra) # 8000503c <exec>
    80005ef4:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ef6:	10048993          	addi	s3,s1,256
    80005efa:	6088                	ld	a0,0(s1)
    80005efc:	c901                	beqz	a0,80005f0c <sys_exec+0xf4>
    kfree(argv[i]);
    80005efe:	ffffb097          	auipc	ra,0xffffb
    80005f02:	aec080e7          	jalr	-1300(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f06:	04a1                	addi	s1,s1,8
    80005f08:	ff3499e3          	bne	s1,s3,80005efa <sys_exec+0xe2>
  return ret;
    80005f0c:	854a                	mv	a0,s2
    80005f0e:	a011                	j	80005f12 <sys_exec+0xfa>
  return -1;
    80005f10:	557d                	li	a0,-1
}
    80005f12:	60be                	ld	ra,456(sp)
    80005f14:	641e                	ld	s0,448(sp)
    80005f16:	74fa                	ld	s1,440(sp)
    80005f18:	795a                	ld	s2,432(sp)
    80005f1a:	79ba                	ld	s3,424(sp)
    80005f1c:	7a1a                	ld	s4,416(sp)
    80005f1e:	6afa                	ld	s5,408(sp)
    80005f20:	6179                	addi	sp,sp,464
    80005f22:	8082                	ret

0000000080005f24 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f24:	7139                	addi	sp,sp,-64
    80005f26:	fc06                	sd	ra,56(sp)
    80005f28:	f822                	sd	s0,48(sp)
    80005f2a:	f426                	sd	s1,40(sp)
    80005f2c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f2e:	ffffc097          	auipc	ra,0xffffc
    80005f32:	a7e080e7          	jalr	-1410(ra) # 800019ac <myproc>
    80005f36:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005f38:	fd840593          	addi	a1,s0,-40
    80005f3c:	4501                	li	a0,0
    80005f3e:	ffffd097          	auipc	ra,0xffffd
    80005f42:	ba2080e7          	jalr	-1118(ra) # 80002ae0 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005f46:	fc840593          	addi	a1,s0,-56
    80005f4a:	fd040513          	addi	a0,s0,-48
    80005f4e:	fffff097          	auipc	ra,0xfffff
    80005f52:	da4080e7          	jalr	-604(ra) # 80004cf2 <pipealloc>
    return -1;
    80005f56:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f58:	0c054463          	bltz	a0,80006020 <sys_pipe+0xfc>
  fd0 = -1;
    80005f5c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f60:	fd043503          	ld	a0,-48(s0)
    80005f64:	fffff097          	auipc	ra,0xfffff
    80005f68:	4f8080e7          	jalr	1272(ra) # 8000545c <fdalloc>
    80005f6c:	fca42223          	sw	a0,-60(s0)
    80005f70:	08054b63          	bltz	a0,80006006 <sys_pipe+0xe2>
    80005f74:	fc843503          	ld	a0,-56(s0)
    80005f78:	fffff097          	auipc	ra,0xfffff
    80005f7c:	4e4080e7          	jalr	1252(ra) # 8000545c <fdalloc>
    80005f80:	fca42023          	sw	a0,-64(s0)
    80005f84:	06054863          	bltz	a0,80005ff4 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f88:	4691                	li	a3,4
    80005f8a:	fc440613          	addi	a2,s0,-60
    80005f8e:	fd843583          	ld	a1,-40(s0)
    80005f92:	68a8                	ld	a0,80(s1)
    80005f94:	ffffb097          	auipc	ra,0xffffb
    80005f98:	6d4080e7          	jalr	1748(ra) # 80001668 <copyout>
    80005f9c:	02054063          	bltz	a0,80005fbc <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005fa0:	4691                	li	a3,4
    80005fa2:	fc040613          	addi	a2,s0,-64
    80005fa6:	fd843583          	ld	a1,-40(s0)
    80005faa:	0591                	addi	a1,a1,4
    80005fac:	68a8                	ld	a0,80(s1)
    80005fae:	ffffb097          	auipc	ra,0xffffb
    80005fb2:	6ba080e7          	jalr	1722(ra) # 80001668 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005fb6:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fb8:	06055463          	bgez	a0,80006020 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005fbc:	fc442783          	lw	a5,-60(s0)
    80005fc0:	07e9                	addi	a5,a5,26
    80005fc2:	078e                	slli	a5,a5,0x3
    80005fc4:	97a6                	add	a5,a5,s1
    80005fc6:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005fca:	fc042503          	lw	a0,-64(s0)
    80005fce:	0569                	addi	a0,a0,26
    80005fd0:	050e                	slli	a0,a0,0x3
    80005fd2:	94aa                	add	s1,s1,a0
    80005fd4:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005fd8:	fd043503          	ld	a0,-48(s0)
    80005fdc:	ffffe097          	auipc	ra,0xffffe
    80005fe0:	7f0080e7          	jalr	2032(ra) # 800047cc <fileclose>
    fileclose(wf);
    80005fe4:	fc843503          	ld	a0,-56(s0)
    80005fe8:	ffffe097          	auipc	ra,0xffffe
    80005fec:	7e4080e7          	jalr	2020(ra) # 800047cc <fileclose>
    return -1;
    80005ff0:	57fd                	li	a5,-1
    80005ff2:	a03d                	j	80006020 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005ff4:	fc442783          	lw	a5,-60(s0)
    80005ff8:	0007c763          	bltz	a5,80006006 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005ffc:	07e9                	addi	a5,a5,26
    80005ffe:	078e                	slli	a5,a5,0x3
    80006000:	94be                	add	s1,s1,a5
    80006002:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006006:	fd043503          	ld	a0,-48(s0)
    8000600a:	ffffe097          	auipc	ra,0xffffe
    8000600e:	7c2080e7          	jalr	1986(ra) # 800047cc <fileclose>
    fileclose(wf);
    80006012:	fc843503          	ld	a0,-56(s0)
    80006016:	ffffe097          	auipc	ra,0xffffe
    8000601a:	7b6080e7          	jalr	1974(ra) # 800047cc <fileclose>
    return -1;
    8000601e:	57fd                	li	a5,-1
}
    80006020:	853e                	mv	a0,a5
    80006022:	70e2                	ld	ra,56(sp)
    80006024:	7442                	ld	s0,48(sp)
    80006026:	74a2                	ld	s1,40(sp)
    80006028:	6121                	addi	sp,sp,64
    8000602a:	8082                	ret
    8000602c:	0000                	unimp
	...

0000000080006030 <kernelvec>:
    80006030:	7111                	addi	sp,sp,-256
    80006032:	e006                	sd	ra,0(sp)
    80006034:	e40a                	sd	sp,8(sp)
    80006036:	e80e                	sd	gp,16(sp)
    80006038:	ec12                	sd	tp,24(sp)
    8000603a:	f016                	sd	t0,32(sp)
    8000603c:	f41a                	sd	t1,40(sp)
    8000603e:	f81e                	sd	t2,48(sp)
    80006040:	fc22                	sd	s0,56(sp)
    80006042:	e0a6                	sd	s1,64(sp)
    80006044:	e4aa                	sd	a0,72(sp)
    80006046:	e8ae                	sd	a1,80(sp)
    80006048:	ecb2                	sd	a2,88(sp)
    8000604a:	f0b6                	sd	a3,96(sp)
    8000604c:	f4ba                	sd	a4,104(sp)
    8000604e:	f8be                	sd	a5,112(sp)
    80006050:	fcc2                	sd	a6,120(sp)
    80006052:	e146                	sd	a7,128(sp)
    80006054:	e54a                	sd	s2,136(sp)
    80006056:	e94e                	sd	s3,144(sp)
    80006058:	ed52                	sd	s4,152(sp)
    8000605a:	f156                	sd	s5,160(sp)
    8000605c:	f55a                	sd	s6,168(sp)
    8000605e:	f95e                	sd	s7,176(sp)
    80006060:	fd62                	sd	s8,184(sp)
    80006062:	e1e6                	sd	s9,192(sp)
    80006064:	e5ea                	sd	s10,200(sp)
    80006066:	e9ee                	sd	s11,208(sp)
    80006068:	edf2                	sd	t3,216(sp)
    8000606a:	f1f6                	sd	t4,224(sp)
    8000606c:	f5fa                	sd	t5,232(sp)
    8000606e:	f9fe                	sd	t6,240(sp)
    80006070:	87ffc0ef          	jal	ra,800028ee <kerneltrap>
    80006074:	6082                	ld	ra,0(sp)
    80006076:	6122                	ld	sp,8(sp)
    80006078:	61c2                	ld	gp,16(sp)
    8000607a:	7282                	ld	t0,32(sp)
    8000607c:	7322                	ld	t1,40(sp)
    8000607e:	73c2                	ld	t2,48(sp)
    80006080:	7462                	ld	s0,56(sp)
    80006082:	6486                	ld	s1,64(sp)
    80006084:	6526                	ld	a0,72(sp)
    80006086:	65c6                	ld	a1,80(sp)
    80006088:	6666                	ld	a2,88(sp)
    8000608a:	7686                	ld	a3,96(sp)
    8000608c:	7726                	ld	a4,104(sp)
    8000608e:	77c6                	ld	a5,112(sp)
    80006090:	7866                	ld	a6,120(sp)
    80006092:	688a                	ld	a7,128(sp)
    80006094:	692a                	ld	s2,136(sp)
    80006096:	69ca                	ld	s3,144(sp)
    80006098:	6a6a                	ld	s4,152(sp)
    8000609a:	7a8a                	ld	s5,160(sp)
    8000609c:	7b2a                	ld	s6,168(sp)
    8000609e:	7bca                	ld	s7,176(sp)
    800060a0:	7c6a                	ld	s8,184(sp)
    800060a2:	6c8e                	ld	s9,192(sp)
    800060a4:	6d2e                	ld	s10,200(sp)
    800060a6:	6dce                	ld	s11,208(sp)
    800060a8:	6e6e                	ld	t3,216(sp)
    800060aa:	7e8e                	ld	t4,224(sp)
    800060ac:	7f2e                	ld	t5,232(sp)
    800060ae:	7fce                	ld	t6,240(sp)
    800060b0:	6111                	addi	sp,sp,256
    800060b2:	10200073          	sret
    800060b6:	00000013          	nop
    800060ba:	00000013          	nop
    800060be:	0001                	nop

00000000800060c0 <timervec>:
    800060c0:	34051573          	csrrw	a0,mscratch,a0
    800060c4:	e10c                	sd	a1,0(a0)
    800060c6:	e510                	sd	a2,8(a0)
    800060c8:	e914                	sd	a3,16(a0)
    800060ca:	6d0c                	ld	a1,24(a0)
    800060cc:	7110                	ld	a2,32(a0)
    800060ce:	6194                	ld	a3,0(a1)
    800060d0:	96b2                	add	a3,a3,a2
    800060d2:	e194                	sd	a3,0(a1)
    800060d4:	4589                	li	a1,2
    800060d6:	14459073          	csrw	sip,a1
    800060da:	6914                	ld	a3,16(a0)
    800060dc:	6510                	ld	a2,8(a0)
    800060de:	610c                	ld	a1,0(a0)
    800060e0:	34051573          	csrrw	a0,mscratch,a0
    800060e4:	30200073          	mret
	...

00000000800060ea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800060ea:	1141                	addi	sp,sp,-16
    800060ec:	e422                	sd	s0,8(sp)
    800060ee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800060f0:	0c0007b7          	lui	a5,0xc000
    800060f4:	4705                	li	a4,1
    800060f6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800060f8:	c3d8                	sw	a4,4(a5)
}
    800060fa:	6422                	ld	s0,8(sp)
    800060fc:	0141                	addi	sp,sp,16
    800060fe:	8082                	ret

0000000080006100 <plicinithart>:

void
plicinithart(void)
{
    80006100:	1141                	addi	sp,sp,-16
    80006102:	e406                	sd	ra,8(sp)
    80006104:	e022                	sd	s0,0(sp)
    80006106:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006108:	ffffc097          	auipc	ra,0xffffc
    8000610c:	878080e7          	jalr	-1928(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006110:	0085171b          	slliw	a4,a0,0x8
    80006114:	0c0027b7          	lui	a5,0xc002
    80006118:	97ba                	add	a5,a5,a4
    8000611a:	40200713          	li	a4,1026
    8000611e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006122:	00d5151b          	slliw	a0,a0,0xd
    80006126:	0c2017b7          	lui	a5,0xc201
    8000612a:	953e                	add	a0,a0,a5
    8000612c:	00052023          	sw	zero,0(a0)
}
    80006130:	60a2                	ld	ra,8(sp)
    80006132:	6402                	ld	s0,0(sp)
    80006134:	0141                	addi	sp,sp,16
    80006136:	8082                	ret

0000000080006138 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006138:	1141                	addi	sp,sp,-16
    8000613a:	e406                	sd	ra,8(sp)
    8000613c:	e022                	sd	s0,0(sp)
    8000613e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006140:	ffffc097          	auipc	ra,0xffffc
    80006144:	840080e7          	jalr	-1984(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006148:	00d5179b          	slliw	a5,a0,0xd
    8000614c:	0c201537          	lui	a0,0xc201
    80006150:	953e                	add	a0,a0,a5
  return irq;
}
    80006152:	4148                	lw	a0,4(a0)
    80006154:	60a2                	ld	ra,8(sp)
    80006156:	6402                	ld	s0,0(sp)
    80006158:	0141                	addi	sp,sp,16
    8000615a:	8082                	ret

000000008000615c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000615c:	1101                	addi	sp,sp,-32
    8000615e:	ec06                	sd	ra,24(sp)
    80006160:	e822                	sd	s0,16(sp)
    80006162:	e426                	sd	s1,8(sp)
    80006164:	1000                	addi	s0,sp,32
    80006166:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006168:	ffffc097          	auipc	ra,0xffffc
    8000616c:	818080e7          	jalr	-2024(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006170:	00d5151b          	slliw	a0,a0,0xd
    80006174:	0c2017b7          	lui	a5,0xc201
    80006178:	97aa                	add	a5,a5,a0
    8000617a:	c3c4                	sw	s1,4(a5)
}
    8000617c:	60e2                	ld	ra,24(sp)
    8000617e:	6442                	ld	s0,16(sp)
    80006180:	64a2                	ld	s1,8(sp)
    80006182:	6105                	addi	sp,sp,32
    80006184:	8082                	ret

0000000080006186 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006186:	1141                	addi	sp,sp,-16
    80006188:	e406                	sd	ra,8(sp)
    8000618a:	e022                	sd	s0,0(sp)
    8000618c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000618e:	479d                	li	a5,7
    80006190:	04a7cc63          	blt	a5,a0,800061e8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006194:	0001c797          	auipc	a5,0x1c
    80006198:	ccc78793          	addi	a5,a5,-820 # 80021e60 <disk>
    8000619c:	97aa                	add	a5,a5,a0
    8000619e:	0187c783          	lbu	a5,24(a5)
    800061a2:	ebb9                	bnez	a5,800061f8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800061a4:	00451613          	slli	a2,a0,0x4
    800061a8:	0001c797          	auipc	a5,0x1c
    800061ac:	cb878793          	addi	a5,a5,-840 # 80021e60 <disk>
    800061b0:	6394                	ld	a3,0(a5)
    800061b2:	96b2                	add	a3,a3,a2
    800061b4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800061b8:	6398                	ld	a4,0(a5)
    800061ba:	9732                	add	a4,a4,a2
    800061bc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800061c0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800061c4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800061c8:	953e                	add	a0,a0,a5
    800061ca:	4785                	li	a5,1
    800061cc:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    800061d0:	0001c517          	auipc	a0,0x1c
    800061d4:	ca850513          	addi	a0,a0,-856 # 80021e78 <disk+0x18>
    800061d8:	ffffc097          	auipc	ra,0xffffc
    800061dc:	ee0080e7          	jalr	-288(ra) # 800020b8 <wakeup>
}
    800061e0:	60a2                	ld	ra,8(sp)
    800061e2:	6402                	ld	s0,0(sp)
    800061e4:	0141                	addi	sp,sp,16
    800061e6:	8082                	ret
    panic("free_desc 1");
    800061e8:	00002517          	auipc	a0,0x2
    800061ec:	59050513          	addi	a0,a0,1424 # 80008778 <syscalls+0x328>
    800061f0:	ffffa097          	auipc	ra,0xffffa
    800061f4:	34e080e7          	jalr	846(ra) # 8000053e <panic>
    panic("free_desc 2");
    800061f8:	00002517          	auipc	a0,0x2
    800061fc:	59050513          	addi	a0,a0,1424 # 80008788 <syscalls+0x338>
    80006200:	ffffa097          	auipc	ra,0xffffa
    80006204:	33e080e7          	jalr	830(ra) # 8000053e <panic>

0000000080006208 <virtio_disk_init>:
{
    80006208:	1101                	addi	sp,sp,-32
    8000620a:	ec06                	sd	ra,24(sp)
    8000620c:	e822                	sd	s0,16(sp)
    8000620e:	e426                	sd	s1,8(sp)
    80006210:	e04a                	sd	s2,0(sp)
    80006212:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006214:	00002597          	auipc	a1,0x2
    80006218:	58458593          	addi	a1,a1,1412 # 80008798 <syscalls+0x348>
    8000621c:	0001c517          	auipc	a0,0x1c
    80006220:	d6c50513          	addi	a0,a0,-660 # 80021f88 <disk+0x128>
    80006224:	ffffb097          	auipc	ra,0xffffb
    80006228:	922080e7          	jalr	-1758(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000622c:	100017b7          	lui	a5,0x10001
    80006230:	4398                	lw	a4,0(a5)
    80006232:	2701                	sext.w	a4,a4
    80006234:	747277b7          	lui	a5,0x74727
    80006238:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000623c:	14f71c63          	bne	a4,a5,80006394 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006240:	100017b7          	lui	a5,0x10001
    80006244:	43dc                	lw	a5,4(a5)
    80006246:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006248:	4709                	li	a4,2
    8000624a:	14e79563          	bne	a5,a4,80006394 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000624e:	100017b7          	lui	a5,0x10001
    80006252:	479c                	lw	a5,8(a5)
    80006254:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006256:	12e79f63          	bne	a5,a4,80006394 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000625a:	100017b7          	lui	a5,0x10001
    8000625e:	47d8                	lw	a4,12(a5)
    80006260:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006262:	554d47b7          	lui	a5,0x554d4
    80006266:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000626a:	12f71563          	bne	a4,a5,80006394 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000626e:	100017b7          	lui	a5,0x10001
    80006272:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006276:	4705                	li	a4,1
    80006278:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000627a:	470d                	li	a4,3
    8000627c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000627e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006280:	c7ffe737          	lui	a4,0xc7ffe
    80006284:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc7bf>
    80006288:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000628a:	2701                	sext.w	a4,a4
    8000628c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000628e:	472d                	li	a4,11
    80006290:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006292:	5bbc                	lw	a5,112(a5)
    80006294:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006298:	8ba1                	andi	a5,a5,8
    8000629a:	10078563          	beqz	a5,800063a4 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000629e:	100017b7          	lui	a5,0x10001
    800062a2:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800062a6:	43fc                	lw	a5,68(a5)
    800062a8:	2781                	sext.w	a5,a5
    800062aa:	10079563          	bnez	a5,800063b4 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800062ae:	100017b7          	lui	a5,0x10001
    800062b2:	5bdc                	lw	a5,52(a5)
    800062b4:	2781                	sext.w	a5,a5
  if(max == 0)
    800062b6:	10078763          	beqz	a5,800063c4 <virtio_disk_init+0x1bc>
  if(max < NUM)
    800062ba:	471d                	li	a4,7
    800062bc:	10f77c63          	bgeu	a4,a5,800063d4 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    800062c0:	ffffb097          	auipc	ra,0xffffb
    800062c4:	826080e7          	jalr	-2010(ra) # 80000ae6 <kalloc>
    800062c8:	0001c497          	auipc	s1,0x1c
    800062cc:	b9848493          	addi	s1,s1,-1128 # 80021e60 <disk>
    800062d0:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800062d2:	ffffb097          	auipc	ra,0xffffb
    800062d6:	814080e7          	jalr	-2028(ra) # 80000ae6 <kalloc>
    800062da:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800062dc:	ffffb097          	auipc	ra,0xffffb
    800062e0:	80a080e7          	jalr	-2038(ra) # 80000ae6 <kalloc>
    800062e4:	87aa                	mv	a5,a0
    800062e6:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800062e8:	6088                	ld	a0,0(s1)
    800062ea:	cd6d                	beqz	a0,800063e4 <virtio_disk_init+0x1dc>
    800062ec:	0001c717          	auipc	a4,0x1c
    800062f0:	b7c73703          	ld	a4,-1156(a4) # 80021e68 <disk+0x8>
    800062f4:	cb65                	beqz	a4,800063e4 <virtio_disk_init+0x1dc>
    800062f6:	c7fd                	beqz	a5,800063e4 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    800062f8:	6605                	lui	a2,0x1
    800062fa:	4581                	li	a1,0
    800062fc:	ffffb097          	auipc	ra,0xffffb
    80006300:	9d6080e7          	jalr	-1578(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006304:	0001c497          	auipc	s1,0x1c
    80006308:	b5c48493          	addi	s1,s1,-1188 # 80021e60 <disk>
    8000630c:	6605                	lui	a2,0x1
    8000630e:	4581                	li	a1,0
    80006310:	6488                	ld	a0,8(s1)
    80006312:	ffffb097          	auipc	ra,0xffffb
    80006316:	9c0080e7          	jalr	-1600(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    8000631a:	6605                	lui	a2,0x1
    8000631c:	4581                	li	a1,0
    8000631e:	6888                	ld	a0,16(s1)
    80006320:	ffffb097          	auipc	ra,0xffffb
    80006324:	9b2080e7          	jalr	-1614(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006328:	100017b7          	lui	a5,0x10001
    8000632c:	4721                	li	a4,8
    8000632e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006330:	4098                	lw	a4,0(s1)
    80006332:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006336:	40d8                	lw	a4,4(s1)
    80006338:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000633c:	6498                	ld	a4,8(s1)
    8000633e:	0007069b          	sext.w	a3,a4
    80006342:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006346:	9701                	srai	a4,a4,0x20
    80006348:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000634c:	6898                	ld	a4,16(s1)
    8000634e:	0007069b          	sext.w	a3,a4
    80006352:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006356:	9701                	srai	a4,a4,0x20
    80006358:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000635c:	4705                	li	a4,1
    8000635e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006360:	00e48c23          	sb	a4,24(s1)
    80006364:	00e48ca3          	sb	a4,25(s1)
    80006368:	00e48d23          	sb	a4,26(s1)
    8000636c:	00e48da3          	sb	a4,27(s1)
    80006370:	00e48e23          	sb	a4,28(s1)
    80006374:	00e48ea3          	sb	a4,29(s1)
    80006378:	00e48f23          	sb	a4,30(s1)
    8000637c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006380:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006384:	0727a823          	sw	s2,112(a5)
}
    80006388:	60e2                	ld	ra,24(sp)
    8000638a:	6442                	ld	s0,16(sp)
    8000638c:	64a2                	ld	s1,8(sp)
    8000638e:	6902                	ld	s2,0(sp)
    80006390:	6105                	addi	sp,sp,32
    80006392:	8082                	ret
    panic("could not find virtio disk");
    80006394:	00002517          	auipc	a0,0x2
    80006398:	41450513          	addi	a0,a0,1044 # 800087a8 <syscalls+0x358>
    8000639c:	ffffa097          	auipc	ra,0xffffa
    800063a0:	1a2080e7          	jalr	418(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    800063a4:	00002517          	auipc	a0,0x2
    800063a8:	42450513          	addi	a0,a0,1060 # 800087c8 <syscalls+0x378>
    800063ac:	ffffa097          	auipc	ra,0xffffa
    800063b0:	192080e7          	jalr	402(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    800063b4:	00002517          	auipc	a0,0x2
    800063b8:	43450513          	addi	a0,a0,1076 # 800087e8 <syscalls+0x398>
    800063bc:	ffffa097          	auipc	ra,0xffffa
    800063c0:	182080e7          	jalr	386(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800063c4:	00002517          	auipc	a0,0x2
    800063c8:	44450513          	addi	a0,a0,1092 # 80008808 <syscalls+0x3b8>
    800063cc:	ffffa097          	auipc	ra,0xffffa
    800063d0:	172080e7          	jalr	370(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800063d4:	00002517          	auipc	a0,0x2
    800063d8:	45450513          	addi	a0,a0,1108 # 80008828 <syscalls+0x3d8>
    800063dc:	ffffa097          	auipc	ra,0xffffa
    800063e0:	162080e7          	jalr	354(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    800063e4:	00002517          	auipc	a0,0x2
    800063e8:	46450513          	addi	a0,a0,1124 # 80008848 <syscalls+0x3f8>
    800063ec:	ffffa097          	auipc	ra,0xffffa
    800063f0:	152080e7          	jalr	338(ra) # 8000053e <panic>

00000000800063f4 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800063f4:	7119                	addi	sp,sp,-128
    800063f6:	fc86                	sd	ra,120(sp)
    800063f8:	f8a2                	sd	s0,112(sp)
    800063fa:	f4a6                	sd	s1,104(sp)
    800063fc:	f0ca                	sd	s2,96(sp)
    800063fe:	ecce                	sd	s3,88(sp)
    80006400:	e8d2                	sd	s4,80(sp)
    80006402:	e4d6                	sd	s5,72(sp)
    80006404:	e0da                	sd	s6,64(sp)
    80006406:	fc5e                	sd	s7,56(sp)
    80006408:	f862                	sd	s8,48(sp)
    8000640a:	f466                	sd	s9,40(sp)
    8000640c:	f06a                	sd	s10,32(sp)
    8000640e:	ec6e                	sd	s11,24(sp)
    80006410:	0100                	addi	s0,sp,128
    80006412:	8aaa                	mv	s5,a0
    80006414:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006416:	00c52d03          	lw	s10,12(a0)
    8000641a:	001d1d1b          	slliw	s10,s10,0x1
    8000641e:	1d02                	slli	s10,s10,0x20
    80006420:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006424:	0001c517          	auipc	a0,0x1c
    80006428:	b6450513          	addi	a0,a0,-1180 # 80021f88 <disk+0x128>
    8000642c:	ffffa097          	auipc	ra,0xffffa
    80006430:	7aa080e7          	jalr	1962(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006434:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006436:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006438:	0001cb97          	auipc	s7,0x1c
    8000643c:	a28b8b93          	addi	s7,s7,-1496 # 80021e60 <disk>
  for(int i = 0; i < 3; i++){
    80006440:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006442:	0001cc97          	auipc	s9,0x1c
    80006446:	b46c8c93          	addi	s9,s9,-1210 # 80021f88 <disk+0x128>
    8000644a:	a08d                	j	800064ac <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000644c:	00fb8733          	add	a4,s7,a5
    80006450:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006454:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006456:	0207c563          	bltz	a5,80006480 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000645a:	2905                	addiw	s2,s2,1
    8000645c:	0611                	addi	a2,a2,4
    8000645e:	05690c63          	beq	s2,s6,800064b6 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006462:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006464:	0001c717          	auipc	a4,0x1c
    80006468:	9fc70713          	addi	a4,a4,-1540 # 80021e60 <disk>
    8000646c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000646e:	01874683          	lbu	a3,24(a4)
    80006472:	fee9                	bnez	a3,8000644c <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006474:	2785                	addiw	a5,a5,1
    80006476:	0705                	addi	a4,a4,1
    80006478:	fe979be3          	bne	a5,s1,8000646e <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000647c:	57fd                	li	a5,-1
    8000647e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006480:	01205d63          	blez	s2,8000649a <virtio_disk_rw+0xa6>
    80006484:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006486:	000a2503          	lw	a0,0(s4)
    8000648a:	00000097          	auipc	ra,0x0
    8000648e:	cfc080e7          	jalr	-772(ra) # 80006186 <free_desc>
      for(int j = 0; j < i; j++)
    80006492:	2d85                	addiw	s11,s11,1
    80006494:	0a11                	addi	s4,s4,4
    80006496:	ffb918e3          	bne	s2,s11,80006486 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000649a:	85e6                	mv	a1,s9
    8000649c:	0001c517          	auipc	a0,0x1c
    800064a0:	9dc50513          	addi	a0,a0,-1572 # 80021e78 <disk+0x18>
    800064a4:	ffffc097          	auipc	ra,0xffffc
    800064a8:	bb0080e7          	jalr	-1104(ra) # 80002054 <sleep>
  for(int i = 0; i < 3; i++){
    800064ac:	f8040a13          	addi	s4,s0,-128
{
    800064b0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800064b2:	894e                	mv	s2,s3
    800064b4:	b77d                	j	80006462 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800064b6:	f8042583          	lw	a1,-128(s0)
    800064ba:	00a58793          	addi	a5,a1,10
    800064be:	0792                	slli	a5,a5,0x4

  if(write)
    800064c0:	0001c617          	auipc	a2,0x1c
    800064c4:	9a060613          	addi	a2,a2,-1632 # 80021e60 <disk>
    800064c8:	00f60733          	add	a4,a2,a5
    800064cc:	018036b3          	snez	a3,s8
    800064d0:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800064d2:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    800064d6:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800064da:	f6078693          	addi	a3,a5,-160
    800064de:	6218                	ld	a4,0(a2)
    800064e0:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800064e2:	00878513          	addi	a0,a5,8
    800064e6:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    800064e8:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800064ea:	6208                	ld	a0,0(a2)
    800064ec:	96aa                	add	a3,a3,a0
    800064ee:	4741                	li	a4,16
    800064f0:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800064f2:	4705                	li	a4,1
    800064f4:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800064f8:	f8442703          	lw	a4,-124(s0)
    800064fc:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006500:	0712                	slli	a4,a4,0x4
    80006502:	953a                	add	a0,a0,a4
    80006504:	058a8693          	addi	a3,s5,88
    80006508:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000650a:	6208                	ld	a0,0(a2)
    8000650c:	972a                	add	a4,a4,a0
    8000650e:	40000693          	li	a3,1024
    80006512:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006514:	001c3c13          	seqz	s8,s8
    80006518:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000651a:	001c6c13          	ori	s8,s8,1
    8000651e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006522:	f8842603          	lw	a2,-120(s0)
    80006526:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000652a:	0001c697          	auipc	a3,0x1c
    8000652e:	93668693          	addi	a3,a3,-1738 # 80021e60 <disk>
    80006532:	00258713          	addi	a4,a1,2
    80006536:	0712                	slli	a4,a4,0x4
    80006538:	9736                	add	a4,a4,a3
    8000653a:	587d                	li	a6,-1
    8000653c:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006540:	0612                	slli	a2,a2,0x4
    80006542:	9532                	add	a0,a0,a2
    80006544:	f9078793          	addi	a5,a5,-112
    80006548:	97b6                	add	a5,a5,a3
    8000654a:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    8000654c:	629c                	ld	a5,0(a3)
    8000654e:	97b2                	add	a5,a5,a2
    80006550:	4605                	li	a2,1
    80006552:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006554:	4509                	li	a0,2
    80006556:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    8000655a:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000655e:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006562:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006566:	6698                	ld	a4,8(a3)
    80006568:	00275783          	lhu	a5,2(a4)
    8000656c:	8b9d                	andi	a5,a5,7
    8000656e:	0786                	slli	a5,a5,0x1
    80006570:	97ba                	add	a5,a5,a4
    80006572:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006576:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000657a:	6698                	ld	a4,8(a3)
    8000657c:	00275783          	lhu	a5,2(a4)
    80006580:	2785                	addiw	a5,a5,1
    80006582:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006586:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000658a:	100017b7          	lui	a5,0x10001
    8000658e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006592:	004aa783          	lw	a5,4(s5)
    80006596:	02c79163          	bne	a5,a2,800065b8 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    8000659a:	0001c917          	auipc	s2,0x1c
    8000659e:	9ee90913          	addi	s2,s2,-1554 # 80021f88 <disk+0x128>
  while(b->disk == 1) {
    800065a2:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800065a4:	85ca                	mv	a1,s2
    800065a6:	8556                	mv	a0,s5
    800065a8:	ffffc097          	auipc	ra,0xffffc
    800065ac:	aac080e7          	jalr	-1364(ra) # 80002054 <sleep>
  while(b->disk == 1) {
    800065b0:	004aa783          	lw	a5,4(s5)
    800065b4:	fe9788e3          	beq	a5,s1,800065a4 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800065b8:	f8042903          	lw	s2,-128(s0)
    800065bc:	00290793          	addi	a5,s2,2
    800065c0:	00479713          	slli	a4,a5,0x4
    800065c4:	0001c797          	auipc	a5,0x1c
    800065c8:	89c78793          	addi	a5,a5,-1892 # 80021e60 <disk>
    800065cc:	97ba                	add	a5,a5,a4
    800065ce:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800065d2:	0001c997          	auipc	s3,0x1c
    800065d6:	88e98993          	addi	s3,s3,-1906 # 80021e60 <disk>
    800065da:	00491713          	slli	a4,s2,0x4
    800065de:	0009b783          	ld	a5,0(s3)
    800065e2:	97ba                	add	a5,a5,a4
    800065e4:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800065e8:	854a                	mv	a0,s2
    800065ea:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800065ee:	00000097          	auipc	ra,0x0
    800065f2:	b98080e7          	jalr	-1128(ra) # 80006186 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800065f6:	8885                	andi	s1,s1,1
    800065f8:	f0ed                	bnez	s1,800065da <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800065fa:	0001c517          	auipc	a0,0x1c
    800065fe:	98e50513          	addi	a0,a0,-1650 # 80021f88 <disk+0x128>
    80006602:	ffffa097          	auipc	ra,0xffffa
    80006606:	688080e7          	jalr	1672(ra) # 80000c8a <release>
}
    8000660a:	70e6                	ld	ra,120(sp)
    8000660c:	7446                	ld	s0,112(sp)
    8000660e:	74a6                	ld	s1,104(sp)
    80006610:	7906                	ld	s2,96(sp)
    80006612:	69e6                	ld	s3,88(sp)
    80006614:	6a46                	ld	s4,80(sp)
    80006616:	6aa6                	ld	s5,72(sp)
    80006618:	6b06                	ld	s6,64(sp)
    8000661a:	7be2                	ld	s7,56(sp)
    8000661c:	7c42                	ld	s8,48(sp)
    8000661e:	7ca2                	ld	s9,40(sp)
    80006620:	7d02                	ld	s10,32(sp)
    80006622:	6de2                	ld	s11,24(sp)
    80006624:	6109                	addi	sp,sp,128
    80006626:	8082                	ret

0000000080006628 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006628:	1101                	addi	sp,sp,-32
    8000662a:	ec06                	sd	ra,24(sp)
    8000662c:	e822                	sd	s0,16(sp)
    8000662e:	e426                	sd	s1,8(sp)
    80006630:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006632:	0001c497          	auipc	s1,0x1c
    80006636:	82e48493          	addi	s1,s1,-2002 # 80021e60 <disk>
    8000663a:	0001c517          	auipc	a0,0x1c
    8000663e:	94e50513          	addi	a0,a0,-1714 # 80021f88 <disk+0x128>
    80006642:	ffffa097          	auipc	ra,0xffffa
    80006646:	594080e7          	jalr	1428(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000664a:	10001737          	lui	a4,0x10001
    8000664e:	533c                	lw	a5,96(a4)
    80006650:	8b8d                	andi	a5,a5,3
    80006652:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006654:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006658:	689c                	ld	a5,16(s1)
    8000665a:	0204d703          	lhu	a4,32(s1)
    8000665e:	0027d783          	lhu	a5,2(a5)
    80006662:	04f70863          	beq	a4,a5,800066b2 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006666:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000666a:	6898                	ld	a4,16(s1)
    8000666c:	0204d783          	lhu	a5,32(s1)
    80006670:	8b9d                	andi	a5,a5,7
    80006672:	078e                	slli	a5,a5,0x3
    80006674:	97ba                	add	a5,a5,a4
    80006676:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006678:	00278713          	addi	a4,a5,2
    8000667c:	0712                	slli	a4,a4,0x4
    8000667e:	9726                	add	a4,a4,s1
    80006680:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006684:	e721                	bnez	a4,800066cc <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006686:	0789                	addi	a5,a5,2
    80006688:	0792                	slli	a5,a5,0x4
    8000668a:	97a6                	add	a5,a5,s1
    8000668c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000668e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006692:	ffffc097          	auipc	ra,0xffffc
    80006696:	a26080e7          	jalr	-1498(ra) # 800020b8 <wakeup>

    disk.used_idx += 1;
    8000669a:	0204d783          	lhu	a5,32(s1)
    8000669e:	2785                	addiw	a5,a5,1
    800066a0:	17c2                	slli	a5,a5,0x30
    800066a2:	93c1                	srli	a5,a5,0x30
    800066a4:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800066a8:	6898                	ld	a4,16(s1)
    800066aa:	00275703          	lhu	a4,2(a4)
    800066ae:	faf71ce3          	bne	a4,a5,80006666 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800066b2:	0001c517          	auipc	a0,0x1c
    800066b6:	8d650513          	addi	a0,a0,-1834 # 80021f88 <disk+0x128>
    800066ba:	ffffa097          	auipc	ra,0xffffa
    800066be:	5d0080e7          	jalr	1488(ra) # 80000c8a <release>
}
    800066c2:	60e2                	ld	ra,24(sp)
    800066c4:	6442                	ld	s0,16(sp)
    800066c6:	64a2                	ld	s1,8(sp)
    800066c8:	6105                	addi	sp,sp,32
    800066ca:	8082                	ret
      panic("virtio_disk_intr status");
    800066cc:	00002517          	auipc	a0,0x2
    800066d0:	19450513          	addi	a0,a0,404 # 80008860 <syscalls+0x410>
    800066d4:	ffffa097          	auipc	ra,0xffffa
    800066d8:	e6a080e7          	jalr	-406(ra) # 8000053e <panic>
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
