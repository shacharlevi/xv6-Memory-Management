
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a0013103          	ld	sp,-1536(sp) # 80008a00 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	a0e70713          	addi	a4,a4,-1522 # 80008a60 <timer_scratch>
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
    80000064:	00007797          	auipc	a5,0x7
    80000068:	86c78793          	addi	a5,a5,-1940 # 800068d0 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffc812f>
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
    80000130:	5a4080e7          	jalr	1444(ra) # 800026d0 <either_copyin>
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
    8000018e:	a1650513          	addi	a0,a0,-1514 # 80010ba0 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	a0648493          	addi	s1,s1,-1530 # 80010ba0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	a9690913          	addi	s2,s2,-1386 # 80010c38 <cons+0x98>
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
    800001c4:	942080e7          	jalr	-1726(ra) # 80001b02 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	352080e7          	jalr	850(ra) # 8000251a <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	086080e7          	jalr	134(ra) # 8000225c <sleep>
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
    80000216:	468080e7          	jalr	1128(ra) # 8000267a <either_copyout>
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
    8000022a:	97a50513          	addi	a0,a0,-1670 # 80010ba0 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	96450513          	addi	a0,a0,-1692 # 80010ba0 <cons>
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
    80000276:	9cf72323          	sw	a5,-1594(a4) # 80010c38 <cons+0x98>
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
    800002d0:	8d450513          	addi	a0,a0,-1836 # 80010ba0 <cons>
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
    800002f6:	434080e7          	jalr	1076(ra) # 80002726 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	8a650513          	addi	a0,a0,-1882 # 80010ba0 <cons>
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
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	88270713          	addi	a4,a4,-1918 # 80010ba0 <cons>
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
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	85878793          	addi	a5,a5,-1960 # 80010ba0 <cons>
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
    8000037a:	8c27a783          	lw	a5,-1854(a5) # 80010c38 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	81670713          	addi	a4,a4,-2026 # 80010ba0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	80648493          	addi	s1,s1,-2042 # 80010ba0 <cons>
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
    800003da:	7ca70713          	addi	a4,a4,1994 # 80010ba0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	84f72a23          	sw	a5,-1964(a4) # 80010c40 <cons+0xa0>
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
    80000416:	78e78793          	addi	a5,a5,1934 # 80010ba0 <cons>
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
    8000043a:	80c7a323          	sw	a2,-2042(a5) # 80010c3c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	7fa50513          	addi	a0,a0,2042 # 80010c38 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	e7a080e7          	jalr	-390(ra) # 800022c0 <wakeup>
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
    80000464:	74050513          	addi	a0,a0,1856 # 80010ba0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00035797          	auipc	a5,0x35
    8000047c:	0c078793          	addi	a5,a5,192 # 80035538 <devsw>
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
    8000054e:	7007ab23          	sw	zero,1814(a5) # 80010c60 <pr+0x18>
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
    80000570:	e4c50513          	addi	a0,a0,-436 # 800083b8 <states.0+0x80>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00008717          	auipc	a4,0x8
    80000582:	4af72123          	sw	a5,1186(a4) # 80008a20 <panicked>
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
    800005be:	6a6dad83          	lw	s11,1702(s11) # 80010c60 <pr+0x18>
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
    800005fc:	65050513          	addi	a0,a0,1616 # 80010c48 <pr>
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
    8000075a:	4f250513          	addi	a0,a0,1266 # 80010c48 <pr>
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
    80000776:	4d648493          	addi	s1,s1,1238 # 80010c48 <pr>
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
    800007d6:	49650513          	addi	a0,a0,1174 # 80010c68 <uart_tx_lock>
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
    80000802:	2227a783          	lw	a5,546(a5) # 80008a20 <panicked>
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
    8000083a:	1f27b783          	ld	a5,498(a5) # 80008a28 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	1f273703          	ld	a4,498(a4) # 80008a30 <uart_tx_w>
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
    80000864:	408a0a13          	addi	s4,s4,1032 # 80010c68 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	1c048493          	addi	s1,s1,448 # 80008a28 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	1c098993          	addi	s3,s3,448 # 80008a30 <uart_tx_w>
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
    80000896:	a2e080e7          	jalr	-1490(ra) # 800022c0 <wakeup>
    
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
    800008d2:	39a50513          	addi	a0,a0,922 # 80010c68 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	1427a783          	lw	a5,322(a5) # 80008a20 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	14873703          	ld	a4,328(a4) # 80008a30 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	1387b783          	ld	a5,312(a5) # 80008a28 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	36c98993          	addi	s3,s3,876 # 80010c68 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	12448493          	addi	s1,s1,292 # 80008a28 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	12490913          	addi	s2,s2,292 # 80008a30 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00002097          	auipc	ra,0x2
    80000920:	940080e7          	jalr	-1728(ra) # 8000225c <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	33648493          	addi	s1,s1,822 # 80010c68 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	0ee7b523          	sd	a4,234(a5) # 80008a30 <uart_tx_w>
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
    800009c0:	2ac48493          	addi	s1,s1,684 # 80010c68 <uart_tx_lock>
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
    80000a02:	cd278793          	addi	a5,a5,-814 # 800366d0 <end>
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
    80000a22:	28290913          	addi	s2,s2,642 # 80010ca0 <kmem>
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
    80000abe:	1e650513          	addi	a0,a0,486 # 80010ca0 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00036517          	auipc	a0,0x36
    80000ad2:	c0250513          	addi	a0,a0,-1022 # 800366d0 <end>
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
    80000af4:	1b048493          	addi	s1,s1,432 # 80010ca0 <kmem>
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
    80000b0c:	19850513          	addi	a0,a0,408 # 80010ca0 <kmem>
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
    80000b38:	16c50513          	addi	a0,a0,364 # 80010ca0 <kmem>
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
    80000b74:	f76080e7          	jalr	-138(ra) # 80001ae6 <mycpu>
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
    80000ba6:	f44080e7          	jalr	-188(ra) # 80001ae6 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	f38080e7          	jalr	-200(ra) # 80001ae6 <mycpu>
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
    80000bca:	f20080e7          	jalr	-224(ra) # 80001ae6 <mycpu>
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
    80000c0a:	ee0080e7          	jalr	-288(ra) # 80001ae6 <mycpu>
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
    80000c36:	eb4080e7          	jalr	-332(ra) # 80001ae6 <mycpu>
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
    80000e84:	c56080e7          	jalr	-938(ra) # 80001ad6 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	bb070713          	addi	a4,a4,-1104 # 80008a38 <started>
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
    80000ea0:	c3a080e7          	jalr	-966(ra) # 80001ad6 <cpuid>
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
    80000ec2:	ce0080e7          	jalr	-800(ra) # 80002b9e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00006097          	auipc	ra,0x6
    80000eca:	a4a080e7          	jalr	-1462(ra) # 80006910 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	1dc080e7          	jalr	476(ra) # 800020aa <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88a080e7          	jalr	-1910(ra) # 80000768 <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	4d250513          	addi	a0,a0,1234 # 800083b8 <states.0+0x80>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69a080e7          	jalr	1690(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68a080e7          	jalr	1674(ra) # 80000588 <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	4b250513          	addi	a0,a0,1202 # 800083b8 <states.0+0x80>
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
    80000f32:	af4080e7          	jalr	-1292(ra) # 80001a22 <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	c40080e7          	jalr	-960(ra) # 80002b76 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	c60080e7          	jalr	-928(ra) # 80002b9e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00006097          	auipc	ra,0x6
    80000f4a:	9b4080e7          	jalr	-1612(ra) # 800068fa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00006097          	auipc	ra,0x6
    80000f52:	9c2080e7          	jalr	-1598(ra) # 80006910 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	500080e7          	jalr	1280(ra) # 80003456 <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	ba4080e7          	jalr	-1116(ra) # 80003b02 <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	e90080e7          	jalr	-368(ra) # 80004df6 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00006097          	auipc	ra,0x6
    80000f72:	aaa080e7          	jalr	-1366(ra) # 80006a18 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	e74080e7          	jalr	-396(ra) # 80001dea <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	aaf72a23          	sw	a5,-1356(a4) # 80008a38 <started>
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
    80000faa:	b5c080e7          	jalr	-1188(ra) # 80001b02 <myproc>
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
    80001050:	9f47b783          	ld	a5,-1548(a5) # 80008a40 <kernel_pagetable>
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
    800012e6:	6aa080e7          	jalr	1706(ra) # 8000198c <proc_mapstacks>
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
    8000130c:	72a7bc23          	sd	a0,1848(a5) # 80008a40 <kernel_pagetable>
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
    #ifndef NONE
    helperUnmap( a , pte, do_free, pagetable);
    #endif
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
    800014d4:	12b66e63          	bltu	a2,a1,80001610 <uvmalloc+0x13c>
{
    800014d8:	711d                	addi	sp,sp,-96
    800014da:	ec86                	sd	ra,88(sp)
    800014dc:	e8a2                	sd	s0,80(sp)
    800014de:	e4a6                	sd	s1,72(sp)
    800014e0:	e0ca                	sd	s2,64(sp)
    800014e2:	fc4e                	sd	s3,56(sp)
    800014e4:	f852                	sd	s4,48(sp)
    800014e6:	f456                	sd	s5,40(sp)
    800014e8:	f05a                	sd	s6,32(sp)
    800014ea:	ec5e                	sd	s7,24(sp)
    800014ec:	e862                	sd	s8,16(sp)
    800014ee:	e466                	sd	s9,8(sp)
    800014f0:	e06a                	sd	s10,0(sp)
    800014f2:	1080                	addi	s0,sp,96
    800014f4:	89aa                	mv	s3,a0
    800014f6:	8ab2                	mv	s5,a2
  oldsz = PGROUNDUP(oldsz);
    800014f8:	6a05                	lui	s4,0x1
    800014fa:	1a7d                	addi	s4,s4,-1
    800014fc:	95d2                	add	a1,a1,s4
    800014fe:	7a7d                	lui	s4,0xfffff
    80001500:	0145fa33          	and	s4,a1,s4
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001504:	10ca7863          	bgeu	s4,a2,80001614 <uvmalloc+0x140>
    80001508:	8952                	mv	s2,s4
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000150a:	0126eb13          	ori	s6,a3,18
    if(p->pid>2){
    8000150e:	4b89                	li	s7,2
      if(p->physicalPagesCount==MAX_PSYC_PAGES){
    80001510:	4cc1                	li	s9,16
      page->idxIsHere=1;
    80001512:	4c05                	li	s8,1
    80001514:	a869                	j	800015ae <uvmalloc+0xda>
      uvmdealloc(pagetable, a, oldsz);
    80001516:	8652                	mv	a2,s4
    80001518:	85ca                	mv	a1,s2
    8000151a:	854e                	mv	a0,s3
    8000151c:	00000097          	auipc	ra,0x0
    80001520:	f70080e7          	jalr	-144(ra) # 8000148c <uvmdealloc>
      return 0;
    80001524:	4501                	li	a0,0
}
    80001526:	60e6                	ld	ra,88(sp)
    80001528:	6446                	ld	s0,80(sp)
    8000152a:	64a6                	ld	s1,72(sp)
    8000152c:	6906                	ld	s2,64(sp)
    8000152e:	79e2                	ld	s3,56(sp)
    80001530:	7a42                	ld	s4,48(sp)
    80001532:	7aa2                	ld	s5,40(sp)
    80001534:	7b02                	ld	s6,32(sp)
    80001536:	6be2                	ld	s7,24(sp)
    80001538:	6c42                	ld	s8,16(sp)
    8000153a:	6ca2                	ld	s9,8(sp)
    8000153c:	6d02                	ld	s10,0(sp)
    8000153e:	6125                	addi	sp,sp,96
    80001540:	8082                	ret
      kfree(mem);
    80001542:	8526                	mv	a0,s1
    80001544:	fffff097          	auipc	ra,0xfffff
    80001548:	4a6080e7          	jalr	1190(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000154c:	8652                	mv	a2,s4
    8000154e:	85ca                	mv	a1,s2
    80001550:	854e                	mv	a0,s3
    80001552:	00000097          	auipc	ra,0x0
    80001556:	f3a080e7          	jalr	-198(ra) # 8000148c <uvmdealloc>
      return 0;
    8000155a:	4501                	li	a0,0
    8000155c:	b7e9                	j	80001526 <uvmalloc+0x52>
        swapOutFromPysc(pagetable,p);
    8000155e:	85aa                	mv	a1,a0
    80001560:	854e                	mv	a0,s3
    80001562:	00001097          	auipc	ra,0x1
    80001566:	43e080e7          	jalr	1086(ra) # 800029a0 <swapOutFromPysc>
    8000156a:	a069                	j	800015f4 <uvmalloc+0x120>
          freeIdx=(int)(page-(p->pagesInPysical));
    8000156c:	8f91                	sub	a5,a5,a2
    8000156e:	8795                	srai	a5,a5,0x5
    80001570:	00078d1b          	sext.w	s10,a5
      page->idxIsHere=1;
    80001574:	005d1793          	slli	a5,s10,0x5
    80001578:	97a6                	add	a5,a5,s1
    8000157a:	2987b423          	sd	s8,648(a5) # 1288 <_entry-0x7fffed78>
      page->va=a;
    8000157e:	2927b023          	sd	s2,640(a5)
      p->physicalPagesCount++;
    80001582:	2704b783          	ld	a5,624(s1)
    80001586:	0785                	addi	a5,a5,1
    80001588:	26f4b823          	sd	a5,624(s1)
      pte_t* entry = walk(pagetable, page->va, 0);
    8000158c:	4601                	li	a2,0
    8000158e:	85ca                	mv	a1,s2
    80001590:	854e                	mv	a0,s3
    80001592:	00000097          	auipc	ra,0x0
    80001596:	ad8080e7          	jalr	-1320(ra) # 8000106a <walk>
      *entry = ~PTE_PG & *entry; //turn off the swap bit
    8000159a:	611c                	ld	a5,0(a0)
    8000159c:	dff7f793          	andi	a5,a5,-513
      *entry = PTE_V | *entry;
    800015a0:	0017e793          	ori	a5,a5,1
    800015a4:	e11c                	sd	a5,0(a0)
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015a6:	6785                	lui	a5,0x1
    800015a8:	993e                	add	s2,s2,a5
    800015aa:	07597163          	bgeu	s2,s5,8000160c <uvmalloc+0x138>
    mem = kalloc();
    800015ae:	fffff097          	auipc	ra,0xfffff
    800015b2:	538080e7          	jalr	1336(ra) # 80000ae6 <kalloc>
    800015b6:	84aa                	mv	s1,a0
    if(mem == 0){
    800015b8:	dd39                	beqz	a0,80001516 <uvmalloc+0x42>
    memset(mem, 0, PGSIZE);
    800015ba:	6605                	lui	a2,0x1
    800015bc:	4581                	li	a1,0
    800015be:	fffff097          	auipc	ra,0xfffff
    800015c2:	714080e7          	jalr	1812(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800015c6:	875a                	mv	a4,s6
    800015c8:	86a6                	mv	a3,s1
    800015ca:	6605                	lui	a2,0x1
    800015cc:	85ca                	mv	a1,s2
    800015ce:	854e                	mv	a0,s3
    800015d0:	00000097          	auipc	ra,0x0
    800015d4:	b82080e7          	jalr	-1150(ra) # 80001152 <mappages>
    800015d8:	8d2a                	mv	s10,a0
    800015da:	f525                	bnez	a0,80001542 <uvmalloc+0x6e>
    struct proc *p=myproc();
    800015dc:	00000097          	auipc	ra,0x0
    800015e0:	526080e7          	jalr	1318(ra) # 80001b02 <myproc>
    800015e4:	84aa                	mv	s1,a0
    if(p->pid>2){
    800015e6:	591c                	lw	a5,48(a0)
    800015e8:	fafbdfe3          	bge	s7,a5,800015a6 <uvmalloc+0xd2>
      if(p->physicalPagesCount==MAX_PSYC_PAGES){
    800015ec:	27053783          	ld	a5,624(a0)
    800015f0:	f79787e3          	beq	a5,s9,8000155e <uvmalloc+0x8a>
      for(page = p->pagesInPysical; page < &p->pagesInPysical[MAX_PSYC_PAGES]; page++ ){
    800015f4:	28048613          	addi	a2,s1,640
    800015f8:	48048693          	addi	a3,s1,1152
    800015fc:	87b2                	mv	a5,a2
        if(page->idxIsHere==0){
    800015fe:	6798                	ld	a4,8(a5)
    80001600:	d735                	beqz	a4,8000156c <uvmalloc+0x98>
      for(page = p->pagesInPysical; page < &p->pagesInPysical[MAX_PSYC_PAGES]; page++ ){
    80001602:	02078793          	addi	a5,a5,32 # 1020 <_entry-0x7fffefe0>
    80001606:	fed79ce3          	bne	a5,a3,800015fe <uvmalloc+0x12a>
    8000160a:	b7ad                	j	80001574 <uvmalloc+0xa0>
  return newsz;
    8000160c:	8556                	mv	a0,s5
    8000160e:	bf21                	j	80001526 <uvmalloc+0x52>
    return oldsz;
    80001610:	852e                	mv	a0,a1
}
    80001612:	8082                	ret
  return newsz;
    80001614:	8532                	mv	a0,a2
    80001616:	bf01                	j	80001526 <uvmalloc+0x52>

0000000080001618 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001618:	7179                	addi	sp,sp,-48
    8000161a:	f406                	sd	ra,40(sp)
    8000161c:	f022                	sd	s0,32(sp)
    8000161e:	ec26                	sd	s1,24(sp)
    80001620:	e84a                	sd	s2,16(sp)
    80001622:	e44e                	sd	s3,8(sp)
    80001624:	e052                	sd	s4,0(sp)
    80001626:	1800                	addi	s0,sp,48
    80001628:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000162a:	84aa                	mv	s1,a0
    8000162c:	6905                	lui	s2,0x1
    8000162e:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001630:	4985                	li	s3,1
    80001632:	a821                	j	8000164a <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001634:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001636:	0532                	slli	a0,a0,0xc
    80001638:	00000097          	auipc	ra,0x0
    8000163c:	fe0080e7          	jalr	-32(ra) # 80001618 <freewalk>
      pagetable[i] = 0;
    80001640:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001644:	04a1                	addi	s1,s1,8
    80001646:	03248163          	beq	s1,s2,80001668 <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000164a:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000164c:	00f57793          	andi	a5,a0,15
    80001650:	ff3782e3          	beq	a5,s3,80001634 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001654:	8905                	andi	a0,a0,1
    80001656:	d57d                	beqz	a0,80001644 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001658:	00007517          	auipc	a0,0x7
    8000165c:	b2050513          	addi	a0,a0,-1248 # 80008178 <digits+0x138>
    80001660:	fffff097          	auipc	ra,0xfffff
    80001664:	ede080e7          	jalr	-290(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001668:	8552                	mv	a0,s4
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	380080e7          	jalr	896(ra) # 800009ea <kfree>
}
    80001672:	70a2                	ld	ra,40(sp)
    80001674:	7402                	ld	s0,32(sp)
    80001676:	64e2                	ld	s1,24(sp)
    80001678:	6942                	ld	s2,16(sp)
    8000167a:	69a2                	ld	s3,8(sp)
    8000167c:	6a02                	ld	s4,0(sp)
    8000167e:	6145                	addi	sp,sp,48
    80001680:	8082                	ret

0000000080001682 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001682:	1101                	addi	sp,sp,-32
    80001684:	ec06                	sd	ra,24(sp)
    80001686:	e822                	sd	s0,16(sp)
    80001688:	e426                	sd	s1,8(sp)
    8000168a:	1000                	addi	s0,sp,32
    8000168c:	84aa                	mv	s1,a0
  if(sz > 0)
    8000168e:	e999                	bnez	a1,800016a4 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001690:	8526                	mv	a0,s1
    80001692:	00000097          	auipc	ra,0x0
    80001696:	f86080e7          	jalr	-122(ra) # 80001618 <freewalk>
}
    8000169a:	60e2                	ld	ra,24(sp)
    8000169c:	6442                	ld	s0,16(sp)
    8000169e:	64a2                	ld	s1,8(sp)
    800016a0:	6105                	addi	sp,sp,32
    800016a2:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800016a4:	6605                	lui	a2,0x1
    800016a6:	167d                	addi	a2,a2,-1
    800016a8:	962e                	add	a2,a2,a1
    800016aa:	4685                	li	a3,1
    800016ac:	8231                	srli	a2,a2,0xc
    800016ae:	4581                	li	a1,0
    800016b0:	00000097          	auipc	ra,0x0
    800016b4:	c68080e7          	jalr	-920(ra) # 80001318 <uvmunmap>
    800016b8:	bfe1                	j	80001690 <uvmfree+0xe>

00000000800016ba <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800016ba:	c679                	beqz	a2,80001788 <uvmcopy+0xce>
{
    800016bc:	715d                	addi	sp,sp,-80
    800016be:	e486                	sd	ra,72(sp)
    800016c0:	e0a2                	sd	s0,64(sp)
    800016c2:	fc26                	sd	s1,56(sp)
    800016c4:	f84a                	sd	s2,48(sp)
    800016c6:	f44e                	sd	s3,40(sp)
    800016c8:	f052                	sd	s4,32(sp)
    800016ca:	ec56                	sd	s5,24(sp)
    800016cc:	e85a                	sd	s6,16(sp)
    800016ce:	e45e                	sd	s7,8(sp)
    800016d0:	0880                	addi	s0,sp,80
    800016d2:	8b2a                	mv	s6,a0
    800016d4:	8aae                	mv	s5,a1
    800016d6:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800016d8:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800016da:	4601                	li	a2,0
    800016dc:	85ce                	mv	a1,s3
    800016de:	855a                	mv	a0,s6
    800016e0:	00000097          	auipc	ra,0x0
    800016e4:	98a080e7          	jalr	-1654(ra) # 8000106a <walk>
    800016e8:	c531                	beqz	a0,80001734 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800016ea:	6118                	ld	a4,0(a0)
    800016ec:	00177793          	andi	a5,a4,1
    800016f0:	cbb1                	beqz	a5,80001744 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800016f2:	00a75593          	srli	a1,a4,0xa
    800016f6:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800016fa:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800016fe:	fffff097          	auipc	ra,0xfffff
    80001702:	3e8080e7          	jalr	1000(ra) # 80000ae6 <kalloc>
    80001706:	892a                	mv	s2,a0
    80001708:	c939                	beqz	a0,8000175e <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000170a:	6605                	lui	a2,0x1
    8000170c:	85de                	mv	a1,s7
    8000170e:	fffff097          	auipc	ra,0xfffff
    80001712:	620080e7          	jalr	1568(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001716:	8726                	mv	a4,s1
    80001718:	86ca                	mv	a3,s2
    8000171a:	6605                	lui	a2,0x1
    8000171c:	85ce                	mv	a1,s3
    8000171e:	8556                	mv	a0,s5
    80001720:	00000097          	auipc	ra,0x0
    80001724:	a32080e7          	jalr	-1486(ra) # 80001152 <mappages>
    80001728:	e515                	bnez	a0,80001754 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000172a:	6785                	lui	a5,0x1
    8000172c:	99be                	add	s3,s3,a5
    8000172e:	fb49e6e3          	bltu	s3,s4,800016da <uvmcopy+0x20>
    80001732:	a081                	j	80001772 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001734:	00007517          	auipc	a0,0x7
    80001738:	a5450513          	addi	a0,a0,-1452 # 80008188 <digits+0x148>
    8000173c:	fffff097          	auipc	ra,0xfffff
    80001740:	e02080e7          	jalr	-510(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    80001744:	00007517          	auipc	a0,0x7
    80001748:	a6450513          	addi	a0,a0,-1436 # 800081a8 <digits+0x168>
    8000174c:	fffff097          	auipc	ra,0xfffff
    80001750:	df2080e7          	jalr	-526(ra) # 8000053e <panic>
      kfree(mem);
    80001754:	854a                	mv	a0,s2
    80001756:	fffff097          	auipc	ra,0xfffff
    8000175a:	294080e7          	jalr	660(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000175e:	4685                	li	a3,1
    80001760:	00c9d613          	srli	a2,s3,0xc
    80001764:	4581                	li	a1,0
    80001766:	8556                	mv	a0,s5
    80001768:	00000097          	auipc	ra,0x0
    8000176c:	bb0080e7          	jalr	-1104(ra) # 80001318 <uvmunmap>
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
    80001784:	6161                	addi	sp,sp,80
    80001786:	8082                	ret
  return 0;
    80001788:	4501                	li	a0,0
}
    8000178a:	8082                	ret

000000008000178c <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000178c:	1141                	addi	sp,sp,-16
    8000178e:	e406                	sd	ra,8(sp)
    80001790:	e022                	sd	s0,0(sp)
    80001792:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001794:	4601                	li	a2,0
    80001796:	00000097          	auipc	ra,0x0
    8000179a:	8d4080e7          	jalr	-1836(ra) # 8000106a <walk>
  if(pte == 0)
    8000179e:	c901                	beqz	a0,800017ae <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800017a0:	611c                	ld	a5,0(a0)
    800017a2:	9bbd                	andi	a5,a5,-17
    800017a4:	e11c                	sd	a5,0(a0)
}
    800017a6:	60a2                	ld	ra,8(sp)
    800017a8:	6402                	ld	s0,0(sp)
    800017aa:	0141                	addi	sp,sp,16
    800017ac:	8082                	ret
    panic("uvmclear");
    800017ae:	00007517          	auipc	a0,0x7
    800017b2:	a1a50513          	addi	a0,a0,-1510 # 800081c8 <digits+0x188>
    800017b6:	fffff097          	auipc	ra,0xfffff
    800017ba:	d88080e7          	jalr	-632(ra) # 8000053e <panic>

00000000800017be <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017be:	c6bd                	beqz	a3,8000182c <copyout+0x6e>
{
    800017c0:	715d                	addi	sp,sp,-80
    800017c2:	e486                	sd	ra,72(sp)
    800017c4:	e0a2                	sd	s0,64(sp)
    800017c6:	fc26                	sd	s1,56(sp)
    800017c8:	f84a                	sd	s2,48(sp)
    800017ca:	f44e                	sd	s3,40(sp)
    800017cc:	f052                	sd	s4,32(sp)
    800017ce:	ec56                	sd	s5,24(sp)
    800017d0:	e85a                	sd	s6,16(sp)
    800017d2:	e45e                	sd	s7,8(sp)
    800017d4:	e062                	sd	s8,0(sp)
    800017d6:	0880                	addi	s0,sp,80
    800017d8:	8b2a                	mv	s6,a0
    800017da:	8c2e                	mv	s8,a1
    800017dc:	8a32                	mv	s4,a2
    800017de:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800017e0:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800017e2:	6a85                	lui	s5,0x1
    800017e4:	a015                	j	80001808 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800017e6:	9562                	add	a0,a0,s8
    800017e8:	0004861b          	sext.w	a2,s1
    800017ec:	85d2                	mv	a1,s4
    800017ee:	41250533          	sub	a0,a0,s2
    800017f2:	fffff097          	auipc	ra,0xfffff
    800017f6:	53c080e7          	jalr	1340(ra) # 80000d2e <memmove>

    len -= n;
    800017fa:	409989b3          	sub	s3,s3,s1
    src += n;
    800017fe:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001800:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001804:	02098263          	beqz	s3,80001828 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001808:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000180c:	85ca                	mv	a1,s2
    8000180e:	855a                	mv	a0,s6
    80001810:	00000097          	auipc	ra,0x0
    80001814:	900080e7          	jalr	-1792(ra) # 80001110 <walkaddr>
    if(pa0 == 0)
    80001818:	cd01                	beqz	a0,80001830 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000181a:	418904b3          	sub	s1,s2,s8
    8000181e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001820:	fc99f3e3          	bgeu	s3,s1,800017e6 <copyout+0x28>
    80001824:	84ce                	mv	s1,s3
    80001826:	b7c1                	j	800017e6 <copyout+0x28>
  }
  return 0;
    80001828:	4501                	li	a0,0
    8000182a:	a021                	j	80001832 <copyout+0x74>
    8000182c:	4501                	li	a0,0
}
    8000182e:	8082                	ret
      return -1;
    80001830:	557d                	li	a0,-1
}
    80001832:	60a6                	ld	ra,72(sp)
    80001834:	6406                	ld	s0,64(sp)
    80001836:	74e2                	ld	s1,56(sp)
    80001838:	7942                	ld	s2,48(sp)
    8000183a:	79a2                	ld	s3,40(sp)
    8000183c:	7a02                	ld	s4,32(sp)
    8000183e:	6ae2                	ld	s5,24(sp)
    80001840:	6b42                	ld	s6,16(sp)
    80001842:	6ba2                	ld	s7,8(sp)
    80001844:	6c02                	ld	s8,0(sp)
    80001846:	6161                	addi	sp,sp,80
    80001848:	8082                	ret

000000008000184a <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000184a:	caa5                	beqz	a3,800018ba <copyin+0x70>
{
    8000184c:	715d                	addi	sp,sp,-80
    8000184e:	e486                	sd	ra,72(sp)
    80001850:	e0a2                	sd	s0,64(sp)
    80001852:	fc26                	sd	s1,56(sp)
    80001854:	f84a                	sd	s2,48(sp)
    80001856:	f44e                	sd	s3,40(sp)
    80001858:	f052                	sd	s4,32(sp)
    8000185a:	ec56                	sd	s5,24(sp)
    8000185c:	e85a                	sd	s6,16(sp)
    8000185e:	e45e                	sd	s7,8(sp)
    80001860:	e062                	sd	s8,0(sp)
    80001862:	0880                	addi	s0,sp,80
    80001864:	8b2a                	mv	s6,a0
    80001866:	8a2e                	mv	s4,a1
    80001868:	8c32                	mv	s8,a2
    8000186a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000186c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000186e:	6a85                	lui	s5,0x1
    80001870:	a01d                	j	80001896 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001872:	018505b3          	add	a1,a0,s8
    80001876:	0004861b          	sext.w	a2,s1
    8000187a:	412585b3          	sub	a1,a1,s2
    8000187e:	8552                	mv	a0,s4
    80001880:	fffff097          	auipc	ra,0xfffff
    80001884:	4ae080e7          	jalr	1198(ra) # 80000d2e <memmove>

    len -= n;
    80001888:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000188c:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000188e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001892:	02098263          	beqz	s3,800018b6 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001896:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000189a:	85ca                	mv	a1,s2
    8000189c:	855a                	mv	a0,s6
    8000189e:	00000097          	auipc	ra,0x0
    800018a2:	872080e7          	jalr	-1934(ra) # 80001110 <walkaddr>
    if(pa0 == 0)
    800018a6:	cd01                	beqz	a0,800018be <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800018a8:	418904b3          	sub	s1,s2,s8
    800018ac:	94d6                	add	s1,s1,s5
    if(n > len)
    800018ae:	fc99f2e3          	bgeu	s3,s1,80001872 <copyin+0x28>
    800018b2:	84ce                	mv	s1,s3
    800018b4:	bf7d                	j	80001872 <copyin+0x28>
  }
  return 0;
    800018b6:	4501                	li	a0,0
    800018b8:	a021                	j	800018c0 <copyin+0x76>
    800018ba:	4501                	li	a0,0
}
    800018bc:	8082                	ret
      return -1;
    800018be:	557d                	li	a0,-1
}
    800018c0:	60a6                	ld	ra,72(sp)
    800018c2:	6406                	ld	s0,64(sp)
    800018c4:	74e2                	ld	s1,56(sp)
    800018c6:	7942                	ld	s2,48(sp)
    800018c8:	79a2                	ld	s3,40(sp)
    800018ca:	7a02                	ld	s4,32(sp)
    800018cc:	6ae2                	ld	s5,24(sp)
    800018ce:	6b42                	ld	s6,16(sp)
    800018d0:	6ba2                	ld	s7,8(sp)
    800018d2:	6c02                	ld	s8,0(sp)
    800018d4:	6161                	addi	sp,sp,80
    800018d6:	8082                	ret

00000000800018d8 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800018d8:	c6c5                	beqz	a3,80001980 <copyinstr+0xa8>
{
    800018da:	715d                	addi	sp,sp,-80
    800018dc:	e486                	sd	ra,72(sp)
    800018de:	e0a2                	sd	s0,64(sp)
    800018e0:	fc26                	sd	s1,56(sp)
    800018e2:	f84a                	sd	s2,48(sp)
    800018e4:	f44e                	sd	s3,40(sp)
    800018e6:	f052                	sd	s4,32(sp)
    800018e8:	ec56                	sd	s5,24(sp)
    800018ea:	e85a                	sd	s6,16(sp)
    800018ec:	e45e                	sd	s7,8(sp)
    800018ee:	0880                	addi	s0,sp,80
    800018f0:	8a2a                	mv	s4,a0
    800018f2:	8b2e                	mv	s6,a1
    800018f4:	8bb2                	mv	s7,a2
    800018f6:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800018f8:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018fa:	6985                	lui	s3,0x1
    800018fc:	a035                	j	80001928 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800018fe:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001902:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001904:	0017b793          	seqz	a5,a5
    80001908:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000190c:	60a6                	ld	ra,72(sp)
    8000190e:	6406                	ld	s0,64(sp)
    80001910:	74e2                	ld	s1,56(sp)
    80001912:	7942                	ld	s2,48(sp)
    80001914:	79a2                	ld	s3,40(sp)
    80001916:	7a02                	ld	s4,32(sp)
    80001918:	6ae2                	ld	s5,24(sp)
    8000191a:	6b42                	ld	s6,16(sp)
    8000191c:	6ba2                	ld	s7,8(sp)
    8000191e:	6161                	addi	sp,sp,80
    80001920:	8082                	ret
    srcva = va0 + PGSIZE;
    80001922:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001926:	c8a9                	beqz	s1,80001978 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001928:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000192c:	85ca                	mv	a1,s2
    8000192e:	8552                	mv	a0,s4
    80001930:	fffff097          	auipc	ra,0xfffff
    80001934:	7e0080e7          	jalr	2016(ra) # 80001110 <walkaddr>
    if(pa0 == 0)
    80001938:	c131                	beqz	a0,8000197c <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    8000193a:	41790833          	sub	a6,s2,s7
    8000193e:	984e                	add	a6,a6,s3
    if(n > max)
    80001940:	0104f363          	bgeu	s1,a6,80001946 <copyinstr+0x6e>
    80001944:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001946:	955e                	add	a0,a0,s7
    80001948:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000194c:	fc080be3          	beqz	a6,80001922 <copyinstr+0x4a>
    80001950:	985a                	add	a6,a6,s6
    80001952:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001954:	41650633          	sub	a2,a0,s6
    80001958:	14fd                	addi	s1,s1,-1
    8000195a:	9b26                	add	s6,s6,s1
    8000195c:	00f60733          	add	a4,a2,a5
    80001960:	00074703          	lbu	a4,0(a4)
    80001964:	df49                	beqz	a4,800018fe <copyinstr+0x26>
        *dst = *p;
    80001966:	00e78023          	sb	a4,0(a5)
      --max;
    8000196a:	40fb04b3          	sub	s1,s6,a5
      dst++;
    8000196e:	0785                	addi	a5,a5,1
    while(n > 0){
    80001970:	ff0796e3          	bne	a5,a6,8000195c <copyinstr+0x84>
      dst++;
    80001974:	8b42                	mv	s6,a6
    80001976:	b775                	j	80001922 <copyinstr+0x4a>
    80001978:	4781                	li	a5,0
    8000197a:	b769                	j	80001904 <copyinstr+0x2c>
      return -1;
    8000197c:	557d                	li	a0,-1
    8000197e:	b779                	j	8000190c <copyinstr+0x34>
  int got_null = 0;
    80001980:	4781                	li	a5,0
  if(got_null){
    80001982:	0017b793          	seqz	a5,a5
    80001986:	40f00533          	neg	a0,a5
}
    8000198a:	8082                	ret

000000008000198c <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    8000198c:	7139                	addi	sp,sp,-64
    8000198e:	fc06                	sd	ra,56(sp)
    80001990:	f822                	sd	s0,48(sp)
    80001992:	f426                	sd	s1,40(sp)
    80001994:	f04a                	sd	s2,32(sp)
    80001996:	ec4e                	sd	s3,24(sp)
    80001998:	e852                	sd	s4,16(sp)
    8000199a:	e456                	sd	s5,8(sp)
    8000199c:	e05a                	sd	s6,0(sp)
    8000199e:	0080                	addi	s0,sp,64
    800019a0:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800019a2:	0000f497          	auipc	s1,0xf
    800019a6:	74e48493          	addi	s1,s1,1870 # 800110f0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800019aa:	8b26                	mv	s6,s1
    800019ac:	00006a97          	auipc	s5,0x6
    800019b0:	654a8a93          	addi	s5,s5,1620 # 80008000 <etext>
    800019b4:	04000937          	lui	s2,0x4000
    800019b8:	197d                	addi	s2,s2,-1
    800019ba:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019bc:	0002aa17          	auipc	s4,0x2a
    800019c0:	934a0a13          	addi	s4,s4,-1740 # 8002b2f0 <tickslock>
    char *pa = kalloc();
    800019c4:	fffff097          	auipc	ra,0xfffff
    800019c8:	122080e7          	jalr	290(ra) # 80000ae6 <kalloc>
    800019cc:	862a                	mv	a2,a0
    if(pa == 0)
    800019ce:	c131                	beqz	a0,80001a12 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800019d0:	416485b3          	sub	a1,s1,s6
    800019d4:	858d                	srai	a1,a1,0x3
    800019d6:	000ab783          	ld	a5,0(s5)
    800019da:	02f585b3          	mul	a1,a1,a5
    800019de:	2585                	addiw	a1,a1,1
    800019e0:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019e4:	4719                	li	a4,6
    800019e6:	6685                	lui	a3,0x1
    800019e8:	40b905b3          	sub	a1,s2,a1
    800019ec:	854e                	mv	a0,s3
    800019ee:	00000097          	auipc	ra,0x0
    800019f2:	804080e7          	jalr	-2044(ra) # 800011f2 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019f6:	68848493          	addi	s1,s1,1672
    800019fa:	fd4495e3          	bne	s1,s4,800019c4 <proc_mapstacks+0x38>
  }
}
    800019fe:	70e2                	ld	ra,56(sp)
    80001a00:	7442                	ld	s0,48(sp)
    80001a02:	74a2                	ld	s1,40(sp)
    80001a04:	7902                	ld	s2,32(sp)
    80001a06:	69e2                	ld	s3,24(sp)
    80001a08:	6a42                	ld	s4,16(sp)
    80001a0a:	6aa2                	ld	s5,8(sp)
    80001a0c:	6b02                	ld	s6,0(sp)
    80001a0e:	6121                	addi	sp,sp,64
    80001a10:	8082                	ret
      panic("kalloc");
    80001a12:	00006517          	auipc	a0,0x6
    80001a16:	7c650513          	addi	a0,a0,1990 # 800081d8 <digits+0x198>
    80001a1a:	fffff097          	auipc	ra,0xfffff
    80001a1e:	b24080e7          	jalr	-1244(ra) # 8000053e <panic>

0000000080001a22 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001a22:	7139                	addi	sp,sp,-64
    80001a24:	fc06                	sd	ra,56(sp)
    80001a26:	f822                	sd	s0,48(sp)
    80001a28:	f426                	sd	s1,40(sp)
    80001a2a:	f04a                	sd	s2,32(sp)
    80001a2c:	ec4e                	sd	s3,24(sp)
    80001a2e:	e852                	sd	s4,16(sp)
    80001a30:	e456                	sd	s5,8(sp)
    80001a32:	e05a                	sd	s6,0(sp)
    80001a34:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001a36:	00006597          	auipc	a1,0x6
    80001a3a:	7aa58593          	addi	a1,a1,1962 # 800081e0 <digits+0x1a0>
    80001a3e:	0000f517          	auipc	a0,0xf
    80001a42:	28250513          	addi	a0,a0,642 # 80010cc0 <pid_lock>
    80001a46:	fffff097          	auipc	ra,0xfffff
    80001a4a:	100080e7          	jalr	256(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a4e:	00006597          	auipc	a1,0x6
    80001a52:	79a58593          	addi	a1,a1,1946 # 800081e8 <digits+0x1a8>
    80001a56:	0000f517          	auipc	a0,0xf
    80001a5a:	28250513          	addi	a0,a0,642 # 80010cd8 <wait_lock>
    80001a5e:	fffff097          	auipc	ra,0xfffff
    80001a62:	0e8080e7          	jalr	232(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a66:	0000f497          	auipc	s1,0xf
    80001a6a:	68a48493          	addi	s1,s1,1674 # 800110f0 <proc>
      initlock(&p->lock, "proc");
    80001a6e:	00006b17          	auipc	s6,0x6
    80001a72:	78ab0b13          	addi	s6,s6,1930 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001a76:	8aa6                	mv	s5,s1
    80001a78:	00006a17          	auipc	s4,0x6
    80001a7c:	588a0a13          	addi	s4,s4,1416 # 80008000 <etext>
    80001a80:	04000937          	lui	s2,0x4000
    80001a84:	197d                	addi	s2,s2,-1
    80001a86:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a88:	0002a997          	auipc	s3,0x2a
    80001a8c:	86898993          	addi	s3,s3,-1944 # 8002b2f0 <tickslock>
      initlock(&p->lock, "proc");
    80001a90:	85da                	mv	a1,s6
    80001a92:	8526                	mv	a0,s1
    80001a94:	fffff097          	auipc	ra,0xfffff
    80001a98:	0b2080e7          	jalr	178(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    80001a9c:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001aa0:	415487b3          	sub	a5,s1,s5
    80001aa4:	878d                	srai	a5,a5,0x3
    80001aa6:	000a3703          	ld	a4,0(s4)
    80001aaa:	02e787b3          	mul	a5,a5,a4
    80001aae:	2785                	addiw	a5,a5,1
    80001ab0:	00d7979b          	slliw	a5,a5,0xd
    80001ab4:	40f907b3          	sub	a5,s2,a5
    80001ab8:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001aba:	68848493          	addi	s1,s1,1672
    80001abe:	fd3499e3          	bne	s1,s3,80001a90 <procinit+0x6e>
  }
}
    80001ac2:	70e2                	ld	ra,56(sp)
    80001ac4:	7442                	ld	s0,48(sp)
    80001ac6:	74a2                	ld	s1,40(sp)
    80001ac8:	7902                	ld	s2,32(sp)
    80001aca:	69e2                	ld	s3,24(sp)
    80001acc:	6a42                	ld	s4,16(sp)
    80001ace:	6aa2                	ld	s5,8(sp)
    80001ad0:	6b02                	ld	s6,0(sp)
    80001ad2:	6121                	addi	sp,sp,64
    80001ad4:	8082                	ret

0000000080001ad6 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001ad6:	1141                	addi	sp,sp,-16
    80001ad8:	e422                	sd	s0,8(sp)
    80001ada:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001adc:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001ade:	2501                	sext.w	a0,a0
    80001ae0:	6422                	ld	s0,8(sp)
    80001ae2:	0141                	addi	sp,sp,16
    80001ae4:	8082                	ret

0000000080001ae6 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001ae6:	1141                	addi	sp,sp,-16
    80001ae8:	e422                	sd	s0,8(sp)
    80001aea:	0800                	addi	s0,sp,16
    80001aec:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001aee:	2781                	sext.w	a5,a5
    80001af0:	079e                	slli	a5,a5,0x7
  return c;
}
    80001af2:	0000f517          	auipc	a0,0xf
    80001af6:	1fe50513          	addi	a0,a0,510 # 80010cf0 <cpus>
    80001afa:	953e                	add	a0,a0,a5
    80001afc:	6422                	ld	s0,8(sp)
    80001afe:	0141                	addi	sp,sp,16
    80001b00:	8082                	ret

0000000080001b02 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001b02:	1101                	addi	sp,sp,-32
    80001b04:	ec06                	sd	ra,24(sp)
    80001b06:	e822                	sd	s0,16(sp)
    80001b08:	e426                	sd	s1,8(sp)
    80001b0a:	1000                	addi	s0,sp,32
  push_off();
    80001b0c:	fffff097          	auipc	ra,0xfffff
    80001b10:	07e080e7          	jalr	126(ra) # 80000b8a <push_off>
    80001b14:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b16:	2781                	sext.w	a5,a5
    80001b18:	079e                	slli	a5,a5,0x7
    80001b1a:	0000f717          	auipc	a4,0xf
    80001b1e:	1a670713          	addi	a4,a4,422 # 80010cc0 <pid_lock>
    80001b22:	97ba                	add	a5,a5,a4
    80001b24:	7b84                	ld	s1,48(a5)
  pop_off();
    80001b26:	fffff097          	auipc	ra,0xfffff
    80001b2a:	104080e7          	jalr	260(ra) # 80000c2a <pop_off>
  return p;
}
    80001b2e:	8526                	mv	a0,s1
    80001b30:	60e2                	ld	ra,24(sp)
    80001b32:	6442                	ld	s0,16(sp)
    80001b34:	64a2                	ld	s1,8(sp)
    80001b36:	6105                	addi	sp,sp,32
    80001b38:	8082                	ret

0000000080001b3a <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001b3a:	1141                	addi	sp,sp,-16
    80001b3c:	e406                	sd	ra,8(sp)
    80001b3e:	e022                	sd	s0,0(sp)
    80001b40:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001b42:	00000097          	auipc	ra,0x0
    80001b46:	fc0080e7          	jalr	-64(ra) # 80001b02 <myproc>
    80001b4a:	fffff097          	auipc	ra,0xfffff
    80001b4e:	140080e7          	jalr	320(ra) # 80000c8a <release>

  if (first) {
    80001b52:	00007797          	auipc	a5,0x7
    80001b56:	e5e7a783          	lw	a5,-418(a5) # 800089b0 <first.1>
    80001b5a:	eb89                	bnez	a5,80001b6c <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b5c:	00001097          	auipc	ra,0x1
    80001b60:	05a080e7          	jalr	90(ra) # 80002bb6 <usertrapret>
}
    80001b64:	60a2                	ld	ra,8(sp)
    80001b66:	6402                	ld	s0,0(sp)
    80001b68:	0141                	addi	sp,sp,16
    80001b6a:	8082                	ret
    first = 0;
    80001b6c:	00007797          	auipc	a5,0x7
    80001b70:	e407a223          	sw	zero,-444(a5) # 800089b0 <first.1>
    fsinit(ROOTDEV);
    80001b74:	4505                	li	a0,1
    80001b76:	00002097          	auipc	ra,0x2
    80001b7a:	f0c080e7          	jalr	-244(ra) # 80003a82 <fsinit>
    80001b7e:	bff9                	j	80001b5c <forkret+0x22>

0000000080001b80 <allocpid>:
{
    80001b80:	1101                	addi	sp,sp,-32
    80001b82:	ec06                	sd	ra,24(sp)
    80001b84:	e822                	sd	s0,16(sp)
    80001b86:	e426                	sd	s1,8(sp)
    80001b88:	e04a                	sd	s2,0(sp)
    80001b8a:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b8c:	0000f917          	auipc	s2,0xf
    80001b90:	13490913          	addi	s2,s2,308 # 80010cc0 <pid_lock>
    80001b94:	854a                	mv	a0,s2
    80001b96:	fffff097          	auipc	ra,0xfffff
    80001b9a:	040080e7          	jalr	64(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001b9e:	00007797          	auipc	a5,0x7
    80001ba2:	e1678793          	addi	a5,a5,-490 # 800089b4 <nextpid>
    80001ba6:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ba8:	0014871b          	addiw	a4,s1,1
    80001bac:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001bae:	854a                	mv	a0,s2
    80001bb0:	fffff097          	auipc	ra,0xfffff
    80001bb4:	0da080e7          	jalr	218(ra) # 80000c8a <release>
}
    80001bb8:	8526                	mv	a0,s1
    80001bba:	60e2                	ld	ra,24(sp)
    80001bbc:	6442                	ld	s0,16(sp)
    80001bbe:	64a2                	ld	s1,8(sp)
    80001bc0:	6902                	ld	s2,0(sp)
    80001bc2:	6105                	addi	sp,sp,32
    80001bc4:	8082                	ret

0000000080001bc6 <proc_pagetable>:
{
    80001bc6:	1101                	addi	sp,sp,-32
    80001bc8:	ec06                	sd	ra,24(sp)
    80001bca:	e822                	sd	s0,16(sp)
    80001bcc:	e426                	sd	s1,8(sp)
    80001bce:	e04a                	sd	s2,0(sp)
    80001bd0:	1000                	addi	s0,sp,32
    80001bd2:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001bd4:	00000097          	auipc	ra,0x0
    80001bd8:	818080e7          	jalr	-2024(ra) # 800013ec <uvmcreate>
    80001bdc:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001bde:	c121                	beqz	a0,80001c1e <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001be0:	4729                	li	a4,10
    80001be2:	00005697          	auipc	a3,0x5
    80001be6:	41e68693          	addi	a3,a3,1054 # 80007000 <_trampoline>
    80001bea:	6605                	lui	a2,0x1
    80001bec:	040005b7          	lui	a1,0x4000
    80001bf0:	15fd                	addi	a1,a1,-1
    80001bf2:	05b2                	slli	a1,a1,0xc
    80001bf4:	fffff097          	auipc	ra,0xfffff
    80001bf8:	55e080e7          	jalr	1374(ra) # 80001152 <mappages>
    80001bfc:	02054863          	bltz	a0,80001c2c <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c00:	4719                	li	a4,6
    80001c02:	05893683          	ld	a3,88(s2)
    80001c06:	6605                	lui	a2,0x1
    80001c08:	020005b7          	lui	a1,0x2000
    80001c0c:	15fd                	addi	a1,a1,-1
    80001c0e:	05b6                	slli	a1,a1,0xd
    80001c10:	8526                	mv	a0,s1
    80001c12:	fffff097          	auipc	ra,0xfffff
    80001c16:	540080e7          	jalr	1344(ra) # 80001152 <mappages>
    80001c1a:	02054163          	bltz	a0,80001c3c <proc_pagetable+0x76>
}
    80001c1e:	8526                	mv	a0,s1
    80001c20:	60e2                	ld	ra,24(sp)
    80001c22:	6442                	ld	s0,16(sp)
    80001c24:	64a2                	ld	s1,8(sp)
    80001c26:	6902                	ld	s2,0(sp)
    80001c28:	6105                	addi	sp,sp,32
    80001c2a:	8082                	ret
    uvmfree(pagetable, 0);
    80001c2c:	4581                	li	a1,0
    80001c2e:	8526                	mv	a0,s1
    80001c30:	00000097          	auipc	ra,0x0
    80001c34:	a52080e7          	jalr	-1454(ra) # 80001682 <uvmfree>
    return 0;
    80001c38:	4481                	li	s1,0
    80001c3a:	b7d5                	j	80001c1e <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c3c:	4681                	li	a3,0
    80001c3e:	4605                	li	a2,1
    80001c40:	040005b7          	lui	a1,0x4000
    80001c44:	15fd                	addi	a1,a1,-1
    80001c46:	05b2                	slli	a1,a1,0xc
    80001c48:	8526                	mv	a0,s1
    80001c4a:	fffff097          	auipc	ra,0xfffff
    80001c4e:	6ce080e7          	jalr	1742(ra) # 80001318 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c52:	4581                	li	a1,0
    80001c54:	8526                	mv	a0,s1
    80001c56:	00000097          	auipc	ra,0x0
    80001c5a:	a2c080e7          	jalr	-1492(ra) # 80001682 <uvmfree>
    return 0;
    80001c5e:	4481                	li	s1,0
    80001c60:	bf7d                	j	80001c1e <proc_pagetable+0x58>

0000000080001c62 <proc_freepagetable>:
{
    80001c62:	1101                	addi	sp,sp,-32
    80001c64:	ec06                	sd	ra,24(sp)
    80001c66:	e822                	sd	s0,16(sp)
    80001c68:	e426                	sd	s1,8(sp)
    80001c6a:	e04a                	sd	s2,0(sp)
    80001c6c:	1000                	addi	s0,sp,32
    80001c6e:	84aa                	mv	s1,a0
    80001c70:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c72:	4681                	li	a3,0
    80001c74:	4605                	li	a2,1
    80001c76:	040005b7          	lui	a1,0x4000
    80001c7a:	15fd                	addi	a1,a1,-1
    80001c7c:	05b2                	slli	a1,a1,0xc
    80001c7e:	fffff097          	auipc	ra,0xfffff
    80001c82:	69a080e7          	jalr	1690(ra) # 80001318 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c86:	4681                	li	a3,0
    80001c88:	4605                	li	a2,1
    80001c8a:	020005b7          	lui	a1,0x2000
    80001c8e:	15fd                	addi	a1,a1,-1
    80001c90:	05b6                	slli	a1,a1,0xd
    80001c92:	8526                	mv	a0,s1
    80001c94:	fffff097          	auipc	ra,0xfffff
    80001c98:	684080e7          	jalr	1668(ra) # 80001318 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c9c:	85ca                	mv	a1,s2
    80001c9e:	8526                	mv	a0,s1
    80001ca0:	00000097          	auipc	ra,0x0
    80001ca4:	9e2080e7          	jalr	-1566(ra) # 80001682 <uvmfree>
}
    80001ca8:	60e2                	ld	ra,24(sp)
    80001caa:	6442                	ld	s0,16(sp)
    80001cac:	64a2                	ld	s1,8(sp)
    80001cae:	6902                	ld	s2,0(sp)
    80001cb0:	6105                	addi	sp,sp,32
    80001cb2:	8082                	ret

0000000080001cb4 <freeproc>:
{
    80001cb4:	1101                	addi	sp,sp,-32
    80001cb6:	ec06                	sd	ra,24(sp)
    80001cb8:	e822                	sd	s0,16(sp)
    80001cba:	e426                	sd	s1,8(sp)
    80001cbc:	1000                	addi	s0,sp,32
    80001cbe:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001cc0:	6d28                	ld	a0,88(a0)
    80001cc2:	c509                	beqz	a0,80001ccc <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001cc4:	fffff097          	auipc	ra,0xfffff
    80001cc8:	d26080e7          	jalr	-730(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001ccc:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001cd0:	68a8                	ld	a0,80(s1)
    80001cd2:	c511                	beqz	a0,80001cde <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001cd4:	64ac                	ld	a1,72(s1)
    80001cd6:	00000097          	auipc	ra,0x0
    80001cda:	f8c080e7          	jalr	-116(ra) # 80001c62 <proc_freepagetable>
  p->pagetable = 0;
    80001cde:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001ce2:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001ce6:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001cea:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001cee:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001cf2:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001cf6:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001cfa:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001cfe:	0004ac23          	sw	zero,24(s1)
  p->swapPagesCount=0;
    80001d02:	2604bc23          	sd	zero,632(s1)
  p->physicalPagesCount=0;
    80001d06:	2604b823          	sd	zero,624(s1)
  p->helpPageTimer=0;
    80001d0a:	6804b023          	sd	zero,1664(s1)
}
    80001d0e:	60e2                	ld	ra,24(sp)
    80001d10:	6442                	ld	s0,16(sp)
    80001d12:	64a2                	ld	s1,8(sp)
    80001d14:	6105                	addi	sp,sp,32
    80001d16:	8082                	ret

0000000080001d18 <allocproc>:
{
    80001d18:	1101                	addi	sp,sp,-32
    80001d1a:	ec06                	sd	ra,24(sp)
    80001d1c:	e822                	sd	s0,16(sp)
    80001d1e:	e426                	sd	s1,8(sp)
    80001d20:	e04a                	sd	s2,0(sp)
    80001d22:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d24:	0000f497          	auipc	s1,0xf
    80001d28:	3cc48493          	addi	s1,s1,972 # 800110f0 <proc>
    80001d2c:	00029917          	auipc	s2,0x29
    80001d30:	5c490913          	addi	s2,s2,1476 # 8002b2f0 <tickslock>
    acquire(&p->lock);
    80001d34:	8526                	mv	a0,s1
    80001d36:	fffff097          	auipc	ra,0xfffff
    80001d3a:	ea0080e7          	jalr	-352(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001d3e:	4c9c                	lw	a5,24(s1)
    80001d40:	cf81                	beqz	a5,80001d58 <allocproc+0x40>
      release(&p->lock);
    80001d42:	8526                	mv	a0,s1
    80001d44:	fffff097          	auipc	ra,0xfffff
    80001d48:	f46080e7          	jalr	-186(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d4c:	68848493          	addi	s1,s1,1672
    80001d50:	ff2492e3          	bne	s1,s2,80001d34 <allocproc+0x1c>
  return 0;
    80001d54:	4481                	li	s1,0
    80001d56:	a899                	j	80001dac <allocproc+0x94>
  p->pid = allocpid();
    80001d58:	00000097          	auipc	ra,0x0
    80001d5c:	e28080e7          	jalr	-472(ra) # 80001b80 <allocpid>
    80001d60:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d62:	4785                	li	a5,1
    80001d64:	cc9c                	sw	a5,24(s1)
  p ->helpPageTimer=0;
    80001d66:	6804b023          	sd	zero,1664(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d6a:	fffff097          	auipc	ra,0xfffff
    80001d6e:	d7c080e7          	jalr	-644(ra) # 80000ae6 <kalloc>
    80001d72:	892a                	mv	s2,a0
    80001d74:	eca8                	sd	a0,88(s1)
    80001d76:	c131                	beqz	a0,80001dba <allocproc+0xa2>
  p->pagetable = proc_pagetable(p);
    80001d78:	8526                	mv	a0,s1
    80001d7a:	00000097          	auipc	ra,0x0
    80001d7e:	e4c080e7          	jalr	-436(ra) # 80001bc6 <proc_pagetable>
    80001d82:	892a                	mv	s2,a0
    80001d84:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d86:	c531                	beqz	a0,80001dd2 <allocproc+0xba>
  memset(&p->context, 0, sizeof(p->context));
    80001d88:	07000613          	li	a2,112
    80001d8c:	4581                	li	a1,0
    80001d8e:	06048513          	addi	a0,s1,96
    80001d92:	fffff097          	auipc	ra,0xfffff
    80001d96:	f40080e7          	jalr	-192(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001d9a:	00000797          	auipc	a5,0x0
    80001d9e:	da078793          	addi	a5,a5,-608 # 80001b3a <forkret>
    80001da2:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001da4:	60bc                	ld	a5,64(s1)
    80001da6:	6705                	lui	a4,0x1
    80001da8:	97ba                	add	a5,a5,a4
    80001daa:	f4bc                	sd	a5,104(s1)
}
    80001dac:	8526                	mv	a0,s1
    80001dae:	60e2                	ld	ra,24(sp)
    80001db0:	6442                	ld	s0,16(sp)
    80001db2:	64a2                	ld	s1,8(sp)
    80001db4:	6902                	ld	s2,0(sp)
    80001db6:	6105                	addi	sp,sp,32
    80001db8:	8082                	ret
    freeproc(p);
    80001dba:	8526                	mv	a0,s1
    80001dbc:	00000097          	auipc	ra,0x0
    80001dc0:	ef8080e7          	jalr	-264(ra) # 80001cb4 <freeproc>
    release(&p->lock);
    80001dc4:	8526                	mv	a0,s1
    80001dc6:	fffff097          	auipc	ra,0xfffff
    80001dca:	ec4080e7          	jalr	-316(ra) # 80000c8a <release>
    return 0;
    80001dce:	84ca                	mv	s1,s2
    80001dd0:	bff1                	j	80001dac <allocproc+0x94>
    freeproc(p);
    80001dd2:	8526                	mv	a0,s1
    80001dd4:	00000097          	auipc	ra,0x0
    80001dd8:	ee0080e7          	jalr	-288(ra) # 80001cb4 <freeproc>
    release(&p->lock);
    80001ddc:	8526                	mv	a0,s1
    80001dde:	fffff097          	auipc	ra,0xfffff
    80001de2:	eac080e7          	jalr	-340(ra) # 80000c8a <release>
    return 0;
    80001de6:	84ca                	mv	s1,s2
    80001de8:	b7d1                	j	80001dac <allocproc+0x94>

0000000080001dea <userinit>:
{
    80001dea:	1101                	addi	sp,sp,-32
    80001dec:	ec06                	sd	ra,24(sp)
    80001dee:	e822                	sd	s0,16(sp)
    80001df0:	e426                	sd	s1,8(sp)
    80001df2:	1000                	addi	s0,sp,32
  p = allocproc();
    80001df4:	00000097          	auipc	ra,0x0
    80001df8:	f24080e7          	jalr	-220(ra) # 80001d18 <allocproc>
    80001dfc:	84aa                	mv	s1,a0
  initproc = p;
    80001dfe:	00007797          	auipc	a5,0x7
    80001e02:	c4a7b523          	sd	a0,-950(a5) # 80008a48 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001e06:	03400613          	li	a2,52
    80001e0a:	00007597          	auipc	a1,0x7
    80001e0e:	bb658593          	addi	a1,a1,-1098 # 800089c0 <initcode>
    80001e12:	6928                	ld	a0,80(a0)
    80001e14:	fffff097          	auipc	ra,0xfffff
    80001e18:	606080e7          	jalr	1542(ra) # 8000141a <uvmfirst>
  p->sz = PGSIZE;
    80001e1c:	6785                	lui	a5,0x1
    80001e1e:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001e20:	6cb8                	ld	a4,88(s1)
    80001e22:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001e26:	6cb8                	ld	a4,88(s1)
    80001e28:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e2a:	4641                	li	a2,16
    80001e2c:	00006597          	auipc	a1,0x6
    80001e30:	3d458593          	addi	a1,a1,980 # 80008200 <digits+0x1c0>
    80001e34:	15848513          	addi	a0,s1,344
    80001e38:	fffff097          	auipc	ra,0xfffff
    80001e3c:	fe4080e7          	jalr	-28(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001e40:	00006517          	auipc	a0,0x6
    80001e44:	3d050513          	addi	a0,a0,976 # 80008210 <digits+0x1d0>
    80001e48:	00002097          	auipc	ra,0x2
    80001e4c:	65c080e7          	jalr	1628(ra) # 800044a4 <namei>
    80001e50:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e54:	478d                	li	a5,3
    80001e56:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e58:	8526                	mv	a0,s1
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	e30080e7          	jalr	-464(ra) # 80000c8a <release>
}
    80001e62:	60e2                	ld	ra,24(sp)
    80001e64:	6442                	ld	s0,16(sp)
    80001e66:	64a2                	ld	s1,8(sp)
    80001e68:	6105                	addi	sp,sp,32
    80001e6a:	8082                	ret

0000000080001e6c <growproc>:
{
    80001e6c:	1101                	addi	sp,sp,-32
    80001e6e:	ec06                	sd	ra,24(sp)
    80001e70:	e822                	sd	s0,16(sp)
    80001e72:	e426                	sd	s1,8(sp)
    80001e74:	e04a                	sd	s2,0(sp)
    80001e76:	1000                	addi	s0,sp,32
    80001e78:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001e7a:	00000097          	auipc	ra,0x0
    80001e7e:	c88080e7          	jalr	-888(ra) # 80001b02 <myproc>
    80001e82:	84aa                	mv	s1,a0
  sz = p->sz;
    80001e84:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001e86:	01204c63          	bgtz	s2,80001e9e <growproc+0x32>
  } else if(n < 0){
    80001e8a:	02094663          	bltz	s2,80001eb6 <growproc+0x4a>
  p->sz = sz;
    80001e8e:	e4ac                	sd	a1,72(s1)
  return 0;
    80001e90:	4501                	li	a0,0
}
    80001e92:	60e2                	ld	ra,24(sp)
    80001e94:	6442                	ld	s0,16(sp)
    80001e96:	64a2                	ld	s1,8(sp)
    80001e98:	6902                	ld	s2,0(sp)
    80001e9a:	6105                	addi	sp,sp,32
    80001e9c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001e9e:	4691                	li	a3,4
    80001ea0:	00b90633          	add	a2,s2,a1
    80001ea4:	6928                	ld	a0,80(a0)
    80001ea6:	fffff097          	auipc	ra,0xfffff
    80001eaa:	62e080e7          	jalr	1582(ra) # 800014d4 <uvmalloc>
    80001eae:	85aa                	mv	a1,a0
    80001eb0:	fd79                	bnez	a0,80001e8e <growproc+0x22>
      return -1;
    80001eb2:	557d                	li	a0,-1
    80001eb4:	bff9                	j	80001e92 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001eb6:	00b90633          	add	a2,s2,a1
    80001eba:	6928                	ld	a0,80(a0)
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	5d0080e7          	jalr	1488(ra) # 8000148c <uvmdealloc>
    80001ec4:	85aa                	mv	a1,a0
    80001ec6:	b7e1                	j	80001e8e <growproc+0x22>

0000000080001ec8 <fork>:
{
    80001ec8:	7139                	addi	sp,sp,-64
    80001eca:	fc06                	sd	ra,56(sp)
    80001ecc:	f822                	sd	s0,48(sp)
    80001ece:	f426                	sd	s1,40(sp)
    80001ed0:	f04a                	sd	s2,32(sp)
    80001ed2:	ec4e                	sd	s3,24(sp)
    80001ed4:	e852                	sd	s4,16(sp)
    80001ed6:	e456                	sd	s5,8(sp)
    80001ed8:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001eda:	00000097          	auipc	ra,0x0
    80001ede:	c28080e7          	jalr	-984(ra) # 80001b02 <myproc>
    80001ee2:	8a2a                	mv	s4,a0
  if((np = allocproc()) == 0){
    80001ee4:	00000097          	auipc	ra,0x0
    80001ee8:	e34080e7          	jalr	-460(ra) # 80001d18 <allocproc>
    80001eec:	1a050d63          	beqz	a0,800020a6 <fork+0x1de>
    80001ef0:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001ef2:	048a3603          	ld	a2,72(s4)
    80001ef6:	692c                	ld	a1,80(a0)
    80001ef8:	050a3503          	ld	a0,80(s4)
    80001efc:	fffff097          	auipc	ra,0xfffff
    80001f00:	7be080e7          	jalr	1982(ra) # 800016ba <uvmcopy>
    80001f04:	04054863          	bltz	a0,80001f54 <fork+0x8c>
  np->sz = p->sz;
    80001f08:	048a3783          	ld	a5,72(s4)
    80001f0c:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001f10:	058a3683          	ld	a3,88(s4)
    80001f14:	87b6                	mv	a5,a3
    80001f16:	0589b703          	ld	a4,88(s3)
    80001f1a:	12068693          	addi	a3,a3,288
    80001f1e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f22:	6788                	ld	a0,8(a5)
    80001f24:	6b8c                	ld	a1,16(a5)
    80001f26:	6f90                	ld	a2,24(a5)
    80001f28:	01073023          	sd	a6,0(a4)
    80001f2c:	e708                	sd	a0,8(a4)
    80001f2e:	eb0c                	sd	a1,16(a4)
    80001f30:	ef10                	sd	a2,24(a4)
    80001f32:	02078793          	addi	a5,a5,32
    80001f36:	02070713          	addi	a4,a4,32
    80001f3a:	fed792e3          	bne	a5,a3,80001f1e <fork+0x56>
  np->trapframe->a0 = 0;
    80001f3e:	0589b783          	ld	a5,88(s3)
    80001f42:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001f46:	0d0a0493          	addi	s1,s4,208
    80001f4a:	0d098913          	addi	s2,s3,208
    80001f4e:	150a0a93          	addi	s5,s4,336
    80001f52:	a00d                	j	80001f74 <fork+0xac>
    freeproc(np);
    80001f54:	854e                	mv	a0,s3
    80001f56:	00000097          	auipc	ra,0x0
    80001f5a:	d5e080e7          	jalr	-674(ra) # 80001cb4 <freeproc>
    release(&np->lock);
    80001f5e:	854e                	mv	a0,s3
    80001f60:	fffff097          	auipc	ra,0xfffff
    80001f64:	d2a080e7          	jalr	-726(ra) # 80000c8a <release>
    return -1;
    80001f68:	5afd                	li	s5,-1
    80001f6a:	aa31                	j	80002086 <fork+0x1be>
  for(i = 0; i < NOFILE; i++)
    80001f6c:	04a1                	addi	s1,s1,8
    80001f6e:	0921                	addi	s2,s2,8
    80001f70:	01548b63          	beq	s1,s5,80001f86 <fork+0xbe>
    if(p->ofile[i])
    80001f74:	6088                	ld	a0,0(s1)
    80001f76:	d97d                	beqz	a0,80001f6c <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f78:	00003097          	auipc	ra,0x3
    80001f7c:	f10080e7          	jalr	-240(ra) # 80004e88 <filedup>
    80001f80:	00a93023          	sd	a0,0(s2)
    80001f84:	b7e5                	j	80001f6c <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001f86:	150a3503          	ld	a0,336(s4)
    80001f8a:	00002097          	auipc	ra,0x2
    80001f8e:	d36080e7          	jalr	-714(ra) # 80003cc0 <idup>
    80001f92:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f96:	4641                	li	a2,16
    80001f98:	158a0593          	addi	a1,s4,344
    80001f9c:	15898513          	addi	a0,s3,344
    80001fa0:	fffff097          	auipc	ra,0xfffff
    80001fa4:	e7c080e7          	jalr	-388(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001fa8:	0309aa83          	lw	s5,48(s3)
  release(&np->lock);
    80001fac:	854e                	mv	a0,s3
    80001fae:	fffff097          	auipc	ra,0xfffff
    80001fb2:	cdc080e7          	jalr	-804(ra) # 80000c8a <release>
    if(np->pid>2)
    80001fb6:	0309a703          	lw	a4,48(s3)
    80001fba:	4789                	li	a5,2
    80001fbc:	0ce7cf63          	blt	a5,a4,8000209a <fork+0x1d2>
    if(p->pid >2){//dont copy init &shell 
    80001fc0:	030a2703          	lw	a4,48(s4)
    80001fc4:	4789                	li	a5,2
    80001fc6:	08e7d363          	bge	a5,a4,8000204c <fork+0x184>
    80001fca:	280a0793          	addi	a5,s4,640
    80001fce:	28098713          	addi	a4,s3,640
    80001fd2:	480a0613          	addi	a2,s4,1152
        np->pagesInPysical[idx].va=p->pagesInPysical[idx].va;
    80001fd6:	6394                	ld	a3,0(a5)
    80001fd8:	e314                	sd	a3,0(a4)
        np->pagesInPysical[idx].idxIsHere=p->pagesInPysical[idx].idxIsHere;
    80001fda:	6794                	ld	a3,8(a5)
    80001fdc:	e714                	sd	a3,8(a4)
        np->pagesInSwap[idx].va=p->pagesInSwap[idx].va;
    80001fde:	2007b683          	ld	a3,512(a5)
    80001fe2:	20d73023          	sd	a3,512(a4)
        np->pagesInSwap[idx].idxIsHere=p->pagesInSwap[idx].idxIsHere;
    80001fe6:	2087b683          	ld	a3,520(a5)
    80001fea:	20d73423          	sd	a3,520(a4)
      while(idx<MAX_PSYC_PAGES){
    80001fee:	02078793          	addi	a5,a5,32
    80001ff2:	02070713          	addi	a4,a4,32
    80001ff6:	fec790e3          	bne	a5,a2,80001fd6 <fork+0x10e>
      np->physicalPagesCount=p->physicalPagesCount;
    80001ffa:	270a3783          	ld	a5,624(s4)
    80001ffe:	26f9b823          	sd	a5,624(s3)
      np->swapPagesCount=p->swapPagesCount;
    80002002:	278a3783          	ld	a5,632(s4)
    80002006:	26f9bc23          	sd	a5,632(s3)
      np->helpPageTimer=  p->helpPageTimer;
    8000200a:	680a3783          	ld	a5,1664(s4)
    8000200e:	68f9b023          	sd	a5,1664(s3)
    char *space =kalloc();
    80002012:	fffff097          	auipc	ra,0xfffff
    80002016:	ad4080e7          	jalr	-1324(ra) # 80000ae6 <kalloc>
    8000201a:	892a                	mv	s2,a0
    8000201c:	44c1                	li	s1,16
      readFromSwapFile(p,space,i*PGSIZE,PGSIZE);
    8000201e:	6685                	lui	a3,0x1
    80002020:	6641                	lui	a2,0x10
    80002022:	85ca                	mv	a1,s2
    80002024:	8552                	mv	a0,s4
    80002026:	00002097          	auipc	ra,0x2
    8000202a:	7e2080e7          	jalr	2018(ra) # 80004808 <readFromSwapFile>
      writeToSwapFile(np,space,i*PGSIZE,PGSIZE);
    8000202e:	6685                	lui	a3,0x1
    80002030:	6641                	lui	a2,0x10
    80002032:	85ca                	mv	a1,s2
    80002034:	854e                	mv	a0,s3
    80002036:	00002097          	auipc	ra,0x2
    8000203a:	772080e7          	jalr	1906(ra) # 800047a8 <writeToSwapFile>
    while(idx<MAX_PSYC_PAGES){
    8000203e:	34fd                	addiw	s1,s1,-1
    80002040:	fcf9                	bnez	s1,8000201e <fork+0x156>
    kfree(space);
    80002042:	854a                	mv	a0,s2
    80002044:	fffff097          	auipc	ra,0xfffff
    80002048:	9a6080e7          	jalr	-1626(ra) # 800009ea <kfree>
  acquire(&wait_lock);
    8000204c:	0000f497          	auipc	s1,0xf
    80002050:	c8c48493          	addi	s1,s1,-884 # 80010cd8 <wait_lock>
    80002054:	8526                	mv	a0,s1
    80002056:	fffff097          	auipc	ra,0xfffff
    8000205a:	b80080e7          	jalr	-1152(ra) # 80000bd6 <acquire>
  np->parent = p;
    8000205e:	0349bc23          	sd	s4,56(s3)
  release(&wait_lock);
    80002062:	8526                	mv	a0,s1
    80002064:	fffff097          	auipc	ra,0xfffff
    80002068:	c26080e7          	jalr	-986(ra) # 80000c8a <release>
  acquire(&np->lock);
    8000206c:	854e                	mv	a0,s3
    8000206e:	fffff097          	auipc	ra,0xfffff
    80002072:	b68080e7          	jalr	-1176(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80002076:	478d                	li	a5,3
    80002078:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    8000207c:	854e                	mv	a0,s3
    8000207e:	fffff097          	auipc	ra,0xfffff
    80002082:	c0c080e7          	jalr	-1012(ra) # 80000c8a <release>
}
    80002086:	8556                	mv	a0,s5
    80002088:	70e2                	ld	ra,56(sp)
    8000208a:	7442                	ld	s0,48(sp)
    8000208c:	74a2                	ld	s1,40(sp)
    8000208e:	7902                	ld	s2,32(sp)
    80002090:	69e2                	ld	s3,24(sp)
    80002092:	6a42                	ld	s4,16(sp)
    80002094:	6aa2                	ld	s5,8(sp)
    80002096:	6121                	addi	sp,sp,64
    80002098:	8082                	ret
      createSwapFile(np);
    8000209a:	854e                	mv	a0,s3
    8000209c:	00002097          	auipc	ra,0x2
    800020a0:	65c080e7          	jalr	1628(ra) # 800046f8 <createSwapFile>
    800020a4:	bf31                	j	80001fc0 <fork+0xf8>
    return -1;
    800020a6:	5afd                	li	s5,-1
    800020a8:	bff9                	j	80002086 <fork+0x1be>

00000000800020aa <scheduler>:
{
    800020aa:	7139                	addi	sp,sp,-64
    800020ac:	fc06                	sd	ra,56(sp)
    800020ae:	f822                	sd	s0,48(sp)
    800020b0:	f426                	sd	s1,40(sp)
    800020b2:	f04a                	sd	s2,32(sp)
    800020b4:	ec4e                	sd	s3,24(sp)
    800020b6:	e852                	sd	s4,16(sp)
    800020b8:	e456                	sd	s5,8(sp)
    800020ba:	e05a                	sd	s6,0(sp)
    800020bc:	0080                	addi	s0,sp,64
    800020be:	8792                	mv	a5,tp
  int id = r_tp();
    800020c0:	2781                	sext.w	a5,a5
  c->proc = 0;
    800020c2:	00779a93          	slli	s5,a5,0x7
    800020c6:	0000f717          	auipc	a4,0xf
    800020ca:	bfa70713          	addi	a4,a4,-1030 # 80010cc0 <pid_lock>
    800020ce:	9756                	add	a4,a4,s5
    800020d0:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    800020d4:	0000f717          	auipc	a4,0xf
    800020d8:	c2470713          	addi	a4,a4,-988 # 80010cf8 <cpus+0x8>
    800020dc:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    800020de:	498d                	li	s3,3
        p->state = RUNNING;
    800020e0:	4b11                	li	s6,4
        c->proc = p;
    800020e2:	079e                	slli	a5,a5,0x7
    800020e4:	0000fa17          	auipc	s4,0xf
    800020e8:	bdca0a13          	addi	s4,s4,-1060 # 80010cc0 <pid_lock>
    800020ec:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800020ee:	00029917          	auipc	s2,0x29
    800020f2:	20290913          	addi	s2,s2,514 # 8002b2f0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020f6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020fa:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020fe:	10079073          	csrw	sstatus,a5
    80002102:	0000f497          	auipc	s1,0xf
    80002106:	fee48493          	addi	s1,s1,-18 # 800110f0 <proc>
    8000210a:	a811                	j	8000211e <scheduler+0x74>
      release(&p->lock);
    8000210c:	8526                	mv	a0,s1
    8000210e:	fffff097          	auipc	ra,0xfffff
    80002112:	b7c080e7          	jalr	-1156(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002116:	68848493          	addi	s1,s1,1672
    8000211a:	fd248ee3          	beq	s1,s2,800020f6 <scheduler+0x4c>
      acquire(&p->lock);
    8000211e:	8526                	mv	a0,s1
    80002120:	fffff097          	auipc	ra,0xfffff
    80002124:	ab6080e7          	jalr	-1354(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    80002128:	4c9c                	lw	a5,24(s1)
    8000212a:	ff3791e3          	bne	a5,s3,8000210c <scheduler+0x62>
        p->state = RUNNING;
    8000212e:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002132:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002136:	06048593          	addi	a1,s1,96
    8000213a:	8556                	mv	a0,s5
    8000213c:	00001097          	auipc	ra,0x1
    80002140:	9d0080e7          	jalr	-1584(ra) # 80002b0c <swtch>
        c->proc = 0;
    80002144:	020a3823          	sd	zero,48(s4)
    80002148:	b7d1                	j	8000210c <scheduler+0x62>

000000008000214a <sched>:
{
    8000214a:	7179                	addi	sp,sp,-48
    8000214c:	f406                	sd	ra,40(sp)
    8000214e:	f022                	sd	s0,32(sp)
    80002150:	ec26                	sd	s1,24(sp)
    80002152:	e84a                	sd	s2,16(sp)
    80002154:	e44e                	sd	s3,8(sp)
    80002156:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002158:	00000097          	auipc	ra,0x0
    8000215c:	9aa080e7          	jalr	-1622(ra) # 80001b02 <myproc>
    80002160:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002162:	fffff097          	auipc	ra,0xfffff
    80002166:	9fa080e7          	jalr	-1542(ra) # 80000b5c <holding>
    8000216a:	c93d                	beqz	a0,800021e0 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000216c:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000216e:	2781                	sext.w	a5,a5
    80002170:	079e                	slli	a5,a5,0x7
    80002172:	0000f717          	auipc	a4,0xf
    80002176:	b4e70713          	addi	a4,a4,-1202 # 80010cc0 <pid_lock>
    8000217a:	97ba                	add	a5,a5,a4
    8000217c:	0a87a703          	lw	a4,168(a5)
    80002180:	4785                	li	a5,1
    80002182:	06f71763          	bne	a4,a5,800021f0 <sched+0xa6>
  if(p->state == RUNNING)
    80002186:	4c98                	lw	a4,24(s1)
    80002188:	4791                	li	a5,4
    8000218a:	06f70b63          	beq	a4,a5,80002200 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000218e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002192:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002194:	efb5                	bnez	a5,80002210 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002196:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002198:	0000f917          	auipc	s2,0xf
    8000219c:	b2890913          	addi	s2,s2,-1240 # 80010cc0 <pid_lock>
    800021a0:	2781                	sext.w	a5,a5
    800021a2:	079e                	slli	a5,a5,0x7
    800021a4:	97ca                	add	a5,a5,s2
    800021a6:	0ac7a983          	lw	s3,172(a5)
    800021aa:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800021ac:	2781                	sext.w	a5,a5
    800021ae:	079e                	slli	a5,a5,0x7
    800021b0:	0000f597          	auipc	a1,0xf
    800021b4:	b4858593          	addi	a1,a1,-1208 # 80010cf8 <cpus+0x8>
    800021b8:	95be                	add	a1,a1,a5
    800021ba:	06048513          	addi	a0,s1,96
    800021be:	00001097          	auipc	ra,0x1
    800021c2:	94e080e7          	jalr	-1714(ra) # 80002b0c <swtch>
    800021c6:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021c8:	2781                	sext.w	a5,a5
    800021ca:	079e                	slli	a5,a5,0x7
    800021cc:	97ca                	add	a5,a5,s2
    800021ce:	0b37a623          	sw	s3,172(a5)
}
    800021d2:	70a2                	ld	ra,40(sp)
    800021d4:	7402                	ld	s0,32(sp)
    800021d6:	64e2                	ld	s1,24(sp)
    800021d8:	6942                	ld	s2,16(sp)
    800021da:	69a2                	ld	s3,8(sp)
    800021dc:	6145                	addi	sp,sp,48
    800021de:	8082                	ret
    panic("sched p->lock");
    800021e0:	00006517          	auipc	a0,0x6
    800021e4:	03850513          	addi	a0,a0,56 # 80008218 <digits+0x1d8>
    800021e8:	ffffe097          	auipc	ra,0xffffe
    800021ec:	356080e7          	jalr	854(ra) # 8000053e <panic>
    panic("sched locks");
    800021f0:	00006517          	auipc	a0,0x6
    800021f4:	03850513          	addi	a0,a0,56 # 80008228 <digits+0x1e8>
    800021f8:	ffffe097          	auipc	ra,0xffffe
    800021fc:	346080e7          	jalr	838(ra) # 8000053e <panic>
    panic("sched running");
    80002200:	00006517          	auipc	a0,0x6
    80002204:	03850513          	addi	a0,a0,56 # 80008238 <digits+0x1f8>
    80002208:	ffffe097          	auipc	ra,0xffffe
    8000220c:	336080e7          	jalr	822(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002210:	00006517          	auipc	a0,0x6
    80002214:	03850513          	addi	a0,a0,56 # 80008248 <digits+0x208>
    80002218:	ffffe097          	auipc	ra,0xffffe
    8000221c:	326080e7          	jalr	806(ra) # 8000053e <panic>

0000000080002220 <yield>:
{
    80002220:	1101                	addi	sp,sp,-32
    80002222:	ec06                	sd	ra,24(sp)
    80002224:	e822                	sd	s0,16(sp)
    80002226:	e426                	sd	s1,8(sp)
    80002228:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000222a:	00000097          	auipc	ra,0x0
    8000222e:	8d8080e7          	jalr	-1832(ra) # 80001b02 <myproc>
    80002232:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002234:	fffff097          	auipc	ra,0xfffff
    80002238:	9a2080e7          	jalr	-1630(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    8000223c:	478d                	li	a5,3
    8000223e:	cc9c                	sw	a5,24(s1)
  sched();
    80002240:	00000097          	auipc	ra,0x0
    80002244:	f0a080e7          	jalr	-246(ra) # 8000214a <sched>
  release(&p->lock);
    80002248:	8526                	mv	a0,s1
    8000224a:	fffff097          	auipc	ra,0xfffff
    8000224e:	a40080e7          	jalr	-1472(ra) # 80000c8a <release>
}
    80002252:	60e2                	ld	ra,24(sp)
    80002254:	6442                	ld	s0,16(sp)
    80002256:	64a2                	ld	s1,8(sp)
    80002258:	6105                	addi	sp,sp,32
    8000225a:	8082                	ret

000000008000225c <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000225c:	7179                	addi	sp,sp,-48
    8000225e:	f406                	sd	ra,40(sp)
    80002260:	f022                	sd	s0,32(sp)
    80002262:	ec26                	sd	s1,24(sp)
    80002264:	e84a                	sd	s2,16(sp)
    80002266:	e44e                	sd	s3,8(sp)
    80002268:	1800                	addi	s0,sp,48
    8000226a:	89aa                	mv	s3,a0
    8000226c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000226e:	00000097          	auipc	ra,0x0
    80002272:	894080e7          	jalr	-1900(ra) # 80001b02 <myproc>
    80002276:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002278:	fffff097          	auipc	ra,0xfffff
    8000227c:	95e080e7          	jalr	-1698(ra) # 80000bd6 <acquire>
  release(lk);
    80002280:	854a                	mv	a0,s2
    80002282:	fffff097          	auipc	ra,0xfffff
    80002286:	a08080e7          	jalr	-1528(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    8000228a:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000228e:	4789                	li	a5,2
    80002290:	cc9c                	sw	a5,24(s1)

  sched();
    80002292:	00000097          	auipc	ra,0x0
    80002296:	eb8080e7          	jalr	-328(ra) # 8000214a <sched>

  // Tidy up.
  p->chan = 0;
    8000229a:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000229e:	8526                	mv	a0,s1
    800022a0:	fffff097          	auipc	ra,0xfffff
    800022a4:	9ea080e7          	jalr	-1558(ra) # 80000c8a <release>
  acquire(lk);
    800022a8:	854a                	mv	a0,s2
    800022aa:	fffff097          	auipc	ra,0xfffff
    800022ae:	92c080e7          	jalr	-1748(ra) # 80000bd6 <acquire>
}
    800022b2:	70a2                	ld	ra,40(sp)
    800022b4:	7402                	ld	s0,32(sp)
    800022b6:	64e2                	ld	s1,24(sp)
    800022b8:	6942                	ld	s2,16(sp)
    800022ba:	69a2                	ld	s3,8(sp)
    800022bc:	6145                	addi	sp,sp,48
    800022be:	8082                	ret

00000000800022c0 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800022c0:	7139                	addi	sp,sp,-64
    800022c2:	fc06                	sd	ra,56(sp)
    800022c4:	f822                	sd	s0,48(sp)
    800022c6:	f426                	sd	s1,40(sp)
    800022c8:	f04a                	sd	s2,32(sp)
    800022ca:	ec4e                	sd	s3,24(sp)
    800022cc:	e852                	sd	s4,16(sp)
    800022ce:	e456                	sd	s5,8(sp)
    800022d0:	0080                	addi	s0,sp,64
    800022d2:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800022d4:	0000f497          	auipc	s1,0xf
    800022d8:	e1c48493          	addi	s1,s1,-484 # 800110f0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800022dc:	4989                	li	s3,2
        p->state = RUNNABLE;
    800022de:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800022e0:	00029917          	auipc	s2,0x29
    800022e4:	01090913          	addi	s2,s2,16 # 8002b2f0 <tickslock>
    800022e8:	a811                	j	800022fc <wakeup+0x3c>
      }
      release(&p->lock);
    800022ea:	8526                	mv	a0,s1
    800022ec:	fffff097          	auipc	ra,0xfffff
    800022f0:	99e080e7          	jalr	-1634(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800022f4:	68848493          	addi	s1,s1,1672
    800022f8:	03248663          	beq	s1,s2,80002324 <wakeup+0x64>
    if(p != myproc()){
    800022fc:	00000097          	auipc	ra,0x0
    80002300:	806080e7          	jalr	-2042(ra) # 80001b02 <myproc>
    80002304:	fea488e3          	beq	s1,a0,800022f4 <wakeup+0x34>
      acquire(&p->lock);
    80002308:	8526                	mv	a0,s1
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	8cc080e7          	jalr	-1844(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002312:	4c9c                	lw	a5,24(s1)
    80002314:	fd379be3          	bne	a5,s3,800022ea <wakeup+0x2a>
    80002318:	709c                	ld	a5,32(s1)
    8000231a:	fd4798e3          	bne	a5,s4,800022ea <wakeup+0x2a>
        p->state = RUNNABLE;
    8000231e:	0154ac23          	sw	s5,24(s1)
    80002322:	b7e1                	j	800022ea <wakeup+0x2a>
    }
  }
}
    80002324:	70e2                	ld	ra,56(sp)
    80002326:	7442                	ld	s0,48(sp)
    80002328:	74a2                	ld	s1,40(sp)
    8000232a:	7902                	ld	s2,32(sp)
    8000232c:	69e2                	ld	s3,24(sp)
    8000232e:	6a42                	ld	s4,16(sp)
    80002330:	6aa2                	ld	s5,8(sp)
    80002332:	6121                	addi	sp,sp,64
    80002334:	8082                	ret

0000000080002336 <reparent>:
{
    80002336:	7179                	addi	sp,sp,-48
    80002338:	f406                	sd	ra,40(sp)
    8000233a:	f022                	sd	s0,32(sp)
    8000233c:	ec26                	sd	s1,24(sp)
    8000233e:	e84a                	sd	s2,16(sp)
    80002340:	e44e                	sd	s3,8(sp)
    80002342:	e052                	sd	s4,0(sp)
    80002344:	1800                	addi	s0,sp,48
    80002346:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002348:	0000f497          	auipc	s1,0xf
    8000234c:	da848493          	addi	s1,s1,-600 # 800110f0 <proc>
      pp->parent = initproc;
    80002350:	00006a17          	auipc	s4,0x6
    80002354:	6f8a0a13          	addi	s4,s4,1784 # 80008a48 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002358:	00029997          	auipc	s3,0x29
    8000235c:	f9898993          	addi	s3,s3,-104 # 8002b2f0 <tickslock>
    80002360:	a029                	j	8000236a <reparent+0x34>
    80002362:	68848493          	addi	s1,s1,1672
    80002366:	01348d63          	beq	s1,s3,80002380 <reparent+0x4a>
    if(pp->parent == p){
    8000236a:	7c9c                	ld	a5,56(s1)
    8000236c:	ff279be3          	bne	a5,s2,80002362 <reparent+0x2c>
      pp->parent = initproc;
    80002370:	000a3503          	ld	a0,0(s4)
    80002374:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002376:	00000097          	auipc	ra,0x0
    8000237a:	f4a080e7          	jalr	-182(ra) # 800022c0 <wakeup>
    8000237e:	b7d5                	j	80002362 <reparent+0x2c>
}
    80002380:	70a2                	ld	ra,40(sp)
    80002382:	7402                	ld	s0,32(sp)
    80002384:	64e2                	ld	s1,24(sp)
    80002386:	6942                	ld	s2,16(sp)
    80002388:	69a2                	ld	s3,8(sp)
    8000238a:	6a02                	ld	s4,0(sp)
    8000238c:	6145                	addi	sp,sp,48
    8000238e:	8082                	ret

0000000080002390 <exit>:
{
    80002390:	7179                	addi	sp,sp,-48
    80002392:	f406                	sd	ra,40(sp)
    80002394:	f022                	sd	s0,32(sp)
    80002396:	ec26                	sd	s1,24(sp)
    80002398:	e84a                	sd	s2,16(sp)
    8000239a:	e44e                	sd	s3,8(sp)
    8000239c:	e052                	sd	s4,0(sp)
    8000239e:	1800                	addi	s0,sp,48
    800023a0:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800023a2:	fffff097          	auipc	ra,0xfffff
    800023a6:	760080e7          	jalr	1888(ra) # 80001b02 <myproc>
    800023aa:	89aa                	mv	s3,a0
  if(p == initproc)
    800023ac:	00006797          	auipc	a5,0x6
    800023b0:	69c7b783          	ld	a5,1692(a5) # 80008a48 <initproc>
    800023b4:	0d050493          	addi	s1,a0,208
    800023b8:	15050913          	addi	s2,a0,336
    800023bc:	02a79363          	bne	a5,a0,800023e2 <exit+0x52>
    panic("init exiting");
    800023c0:	00006517          	auipc	a0,0x6
    800023c4:	ea050513          	addi	a0,a0,-352 # 80008260 <digits+0x220>
    800023c8:	ffffe097          	auipc	ra,0xffffe
    800023cc:	176080e7          	jalr	374(ra) # 8000053e <panic>
      fileclose(f);
    800023d0:	00003097          	auipc	ra,0x3
    800023d4:	b0a080e7          	jalr	-1270(ra) # 80004eda <fileclose>
      p->ofile[fd] = 0;
    800023d8:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800023dc:	04a1                	addi	s1,s1,8
    800023de:	01248563          	beq	s1,s2,800023e8 <exit+0x58>
    if(p->ofile[fd]){
    800023e2:	6088                	ld	a0,0(s1)
    800023e4:	f575                	bnez	a0,800023d0 <exit+0x40>
    800023e6:	bfdd                	j	800023dc <exit+0x4c>
  if(p->pid>2){
    800023e8:	0309a703          	lw	a4,48(s3)
    800023ec:	4789                	li	a5,2
    800023ee:	08e7c163          	blt	a5,a4,80002470 <exit+0xe0>
  begin_op();
    800023f2:	00002097          	auipc	ra,0x2
    800023f6:	61c080e7          	jalr	1564(ra) # 80004a0e <begin_op>
  iput(p->cwd);
    800023fa:	1509b503          	ld	a0,336(s3)
    800023fe:	00002097          	auipc	ra,0x2
    80002402:	aba080e7          	jalr	-1350(ra) # 80003eb8 <iput>
  end_op();
    80002406:	00002097          	auipc	ra,0x2
    8000240a:	688080e7          	jalr	1672(ra) # 80004a8e <end_op>
  p->cwd = 0;
    8000240e:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002412:	0000f497          	auipc	s1,0xf
    80002416:	8c648493          	addi	s1,s1,-1850 # 80010cd8 <wait_lock>
    8000241a:	8526                	mv	a0,s1
    8000241c:	ffffe097          	auipc	ra,0xffffe
    80002420:	7ba080e7          	jalr	1978(ra) # 80000bd6 <acquire>
  reparent(p);
    80002424:	854e                	mv	a0,s3
    80002426:	00000097          	auipc	ra,0x0
    8000242a:	f10080e7          	jalr	-240(ra) # 80002336 <reparent>
  wakeup(p->parent);
    8000242e:	0389b503          	ld	a0,56(s3)
    80002432:	00000097          	auipc	ra,0x0
    80002436:	e8e080e7          	jalr	-370(ra) # 800022c0 <wakeup>
  acquire(&p->lock);
    8000243a:	854e                	mv	a0,s3
    8000243c:	ffffe097          	auipc	ra,0xffffe
    80002440:	79a080e7          	jalr	1946(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002444:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002448:	4795                	li	a5,5
    8000244a:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000244e:	8526                	mv	a0,s1
    80002450:	fffff097          	auipc	ra,0xfffff
    80002454:	83a080e7          	jalr	-1990(ra) # 80000c8a <release>
  sched();
    80002458:	00000097          	auipc	ra,0x0
    8000245c:	cf2080e7          	jalr	-782(ra) # 8000214a <sched>
  panic("zombie exit");
    80002460:	00006517          	auipc	a0,0x6
    80002464:	e1050513          	addi	a0,a0,-496 # 80008270 <digits+0x230>
    80002468:	ffffe097          	auipc	ra,0xffffe
    8000246c:	0d6080e7          	jalr	214(ra) # 8000053e <panic>
    removeSwapFile(p);
    80002470:	854e                	mv	a0,s3
    80002472:	00002097          	auipc	ra,0x2
    80002476:	0de080e7          	jalr	222(ra) # 80004550 <removeSwapFile>
    8000247a:	bfa5                	j	800023f2 <exit+0x62>

000000008000247c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000247c:	7179                	addi	sp,sp,-48
    8000247e:	f406                	sd	ra,40(sp)
    80002480:	f022                	sd	s0,32(sp)
    80002482:	ec26                	sd	s1,24(sp)
    80002484:	e84a                	sd	s2,16(sp)
    80002486:	e44e                	sd	s3,8(sp)
    80002488:	1800                	addi	s0,sp,48
    8000248a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000248c:	0000f497          	auipc	s1,0xf
    80002490:	c6448493          	addi	s1,s1,-924 # 800110f0 <proc>
    80002494:	00029997          	auipc	s3,0x29
    80002498:	e5c98993          	addi	s3,s3,-420 # 8002b2f0 <tickslock>
    acquire(&p->lock);
    8000249c:	8526                	mv	a0,s1
    8000249e:	ffffe097          	auipc	ra,0xffffe
    800024a2:	738080e7          	jalr	1848(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    800024a6:	589c                	lw	a5,48(s1)
    800024a8:	01278d63          	beq	a5,s2,800024c2 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024ac:	8526                	mv	a0,s1
    800024ae:	ffffe097          	auipc	ra,0xffffe
    800024b2:	7dc080e7          	jalr	2012(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800024b6:	68848493          	addi	s1,s1,1672
    800024ba:	ff3491e3          	bne	s1,s3,8000249c <kill+0x20>
  }
  return -1;
    800024be:	557d                	li	a0,-1
    800024c0:	a829                	j	800024da <kill+0x5e>
      p->killed = 1;
    800024c2:	4785                	li	a5,1
    800024c4:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800024c6:	4c98                	lw	a4,24(s1)
    800024c8:	4789                	li	a5,2
    800024ca:	00f70f63          	beq	a4,a5,800024e8 <kill+0x6c>
      release(&p->lock);
    800024ce:	8526                	mv	a0,s1
    800024d0:	ffffe097          	auipc	ra,0xffffe
    800024d4:	7ba080e7          	jalr	1978(ra) # 80000c8a <release>
      return 0;
    800024d8:	4501                	li	a0,0
}
    800024da:	70a2                	ld	ra,40(sp)
    800024dc:	7402                	ld	s0,32(sp)
    800024de:	64e2                	ld	s1,24(sp)
    800024e0:	6942                	ld	s2,16(sp)
    800024e2:	69a2                	ld	s3,8(sp)
    800024e4:	6145                	addi	sp,sp,48
    800024e6:	8082                	ret
        p->state = RUNNABLE;
    800024e8:	478d                	li	a5,3
    800024ea:	cc9c                	sw	a5,24(s1)
    800024ec:	b7cd                	j	800024ce <kill+0x52>

00000000800024ee <setkilled>:

void
setkilled(struct proc *p)
{
    800024ee:	1101                	addi	sp,sp,-32
    800024f0:	ec06                	sd	ra,24(sp)
    800024f2:	e822                	sd	s0,16(sp)
    800024f4:	e426                	sd	s1,8(sp)
    800024f6:	1000                	addi	s0,sp,32
    800024f8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800024fa:	ffffe097          	auipc	ra,0xffffe
    800024fe:	6dc080e7          	jalr	1756(ra) # 80000bd6 <acquire>
  p->killed = 1;
    80002502:	4785                	li	a5,1
    80002504:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002506:	8526                	mv	a0,s1
    80002508:	ffffe097          	auipc	ra,0xffffe
    8000250c:	782080e7          	jalr	1922(ra) # 80000c8a <release>
}
    80002510:	60e2                	ld	ra,24(sp)
    80002512:	6442                	ld	s0,16(sp)
    80002514:	64a2                	ld	s1,8(sp)
    80002516:	6105                	addi	sp,sp,32
    80002518:	8082                	ret

000000008000251a <killed>:

int
killed(struct proc *p)
{
    8000251a:	1101                	addi	sp,sp,-32
    8000251c:	ec06                	sd	ra,24(sp)
    8000251e:	e822                	sd	s0,16(sp)
    80002520:	e426                	sd	s1,8(sp)
    80002522:	e04a                	sd	s2,0(sp)
    80002524:	1000                	addi	s0,sp,32
    80002526:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002528:	ffffe097          	auipc	ra,0xffffe
    8000252c:	6ae080e7          	jalr	1710(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002530:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002534:	8526                	mv	a0,s1
    80002536:	ffffe097          	auipc	ra,0xffffe
    8000253a:	754080e7          	jalr	1876(ra) # 80000c8a <release>
  return k;
}
    8000253e:	854a                	mv	a0,s2
    80002540:	60e2                	ld	ra,24(sp)
    80002542:	6442                	ld	s0,16(sp)
    80002544:	64a2                	ld	s1,8(sp)
    80002546:	6902                	ld	s2,0(sp)
    80002548:	6105                	addi	sp,sp,32
    8000254a:	8082                	ret

000000008000254c <wait>:
{
    8000254c:	715d                	addi	sp,sp,-80
    8000254e:	e486                	sd	ra,72(sp)
    80002550:	e0a2                	sd	s0,64(sp)
    80002552:	fc26                	sd	s1,56(sp)
    80002554:	f84a                	sd	s2,48(sp)
    80002556:	f44e                	sd	s3,40(sp)
    80002558:	f052                	sd	s4,32(sp)
    8000255a:	ec56                	sd	s5,24(sp)
    8000255c:	e85a                	sd	s6,16(sp)
    8000255e:	e45e                	sd	s7,8(sp)
    80002560:	e062                	sd	s8,0(sp)
    80002562:	0880                	addi	s0,sp,80
    80002564:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002566:	fffff097          	auipc	ra,0xfffff
    8000256a:	59c080e7          	jalr	1436(ra) # 80001b02 <myproc>
    8000256e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002570:	0000e517          	auipc	a0,0xe
    80002574:	76850513          	addi	a0,a0,1896 # 80010cd8 <wait_lock>
    80002578:	ffffe097          	auipc	ra,0xffffe
    8000257c:	65e080e7          	jalr	1630(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002580:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002582:	4a15                	li	s4,5
        havekids = 1;
    80002584:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002586:	00029997          	auipc	s3,0x29
    8000258a:	d6a98993          	addi	s3,s3,-662 # 8002b2f0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000258e:	0000ec17          	auipc	s8,0xe
    80002592:	74ac0c13          	addi	s8,s8,1866 # 80010cd8 <wait_lock>
    havekids = 0;
    80002596:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002598:	0000f497          	auipc	s1,0xf
    8000259c:	b5848493          	addi	s1,s1,-1192 # 800110f0 <proc>
    800025a0:	a0bd                	j	8000260e <wait+0xc2>
          pid = pp->pid;
    800025a2:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800025a6:	000b0e63          	beqz	s6,800025c2 <wait+0x76>
    800025aa:	4691                	li	a3,4
    800025ac:	02c48613          	addi	a2,s1,44
    800025b0:	85da                	mv	a1,s6
    800025b2:	05093503          	ld	a0,80(s2)
    800025b6:	fffff097          	auipc	ra,0xfffff
    800025ba:	208080e7          	jalr	520(ra) # 800017be <copyout>
    800025be:	02054563          	bltz	a0,800025e8 <wait+0x9c>
          freeproc(pp);
    800025c2:	8526                	mv	a0,s1
    800025c4:	fffff097          	auipc	ra,0xfffff
    800025c8:	6f0080e7          	jalr	1776(ra) # 80001cb4 <freeproc>
          release(&pp->lock);
    800025cc:	8526                	mv	a0,s1
    800025ce:	ffffe097          	auipc	ra,0xffffe
    800025d2:	6bc080e7          	jalr	1724(ra) # 80000c8a <release>
          release(&wait_lock);
    800025d6:	0000e517          	auipc	a0,0xe
    800025da:	70250513          	addi	a0,a0,1794 # 80010cd8 <wait_lock>
    800025de:	ffffe097          	auipc	ra,0xffffe
    800025e2:	6ac080e7          	jalr	1708(ra) # 80000c8a <release>
          return pid;
    800025e6:	a0b5                	j	80002652 <wait+0x106>
            release(&pp->lock);
    800025e8:	8526                	mv	a0,s1
    800025ea:	ffffe097          	auipc	ra,0xffffe
    800025ee:	6a0080e7          	jalr	1696(ra) # 80000c8a <release>
            release(&wait_lock);
    800025f2:	0000e517          	auipc	a0,0xe
    800025f6:	6e650513          	addi	a0,a0,1766 # 80010cd8 <wait_lock>
    800025fa:	ffffe097          	auipc	ra,0xffffe
    800025fe:	690080e7          	jalr	1680(ra) # 80000c8a <release>
            return -1;
    80002602:	59fd                	li	s3,-1
    80002604:	a0b9                	j	80002652 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002606:	68848493          	addi	s1,s1,1672
    8000260a:	03348463          	beq	s1,s3,80002632 <wait+0xe6>
      if(pp->parent == p){
    8000260e:	7c9c                	ld	a5,56(s1)
    80002610:	ff279be3          	bne	a5,s2,80002606 <wait+0xba>
        acquire(&pp->lock);
    80002614:	8526                	mv	a0,s1
    80002616:	ffffe097          	auipc	ra,0xffffe
    8000261a:	5c0080e7          	jalr	1472(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    8000261e:	4c9c                	lw	a5,24(s1)
    80002620:	f94781e3          	beq	a5,s4,800025a2 <wait+0x56>
        release(&pp->lock);
    80002624:	8526                	mv	a0,s1
    80002626:	ffffe097          	auipc	ra,0xffffe
    8000262a:	664080e7          	jalr	1636(ra) # 80000c8a <release>
        havekids = 1;
    8000262e:	8756                	mv	a4,s5
    80002630:	bfd9                	j	80002606 <wait+0xba>
    if(!havekids || killed(p)){
    80002632:	c719                	beqz	a4,80002640 <wait+0xf4>
    80002634:	854a                	mv	a0,s2
    80002636:	00000097          	auipc	ra,0x0
    8000263a:	ee4080e7          	jalr	-284(ra) # 8000251a <killed>
    8000263e:	c51d                	beqz	a0,8000266c <wait+0x120>
      release(&wait_lock);
    80002640:	0000e517          	auipc	a0,0xe
    80002644:	69850513          	addi	a0,a0,1688 # 80010cd8 <wait_lock>
    80002648:	ffffe097          	auipc	ra,0xffffe
    8000264c:	642080e7          	jalr	1602(ra) # 80000c8a <release>
      return -1;
    80002650:	59fd                	li	s3,-1
}
    80002652:	854e                	mv	a0,s3
    80002654:	60a6                	ld	ra,72(sp)
    80002656:	6406                	ld	s0,64(sp)
    80002658:	74e2                	ld	s1,56(sp)
    8000265a:	7942                	ld	s2,48(sp)
    8000265c:	79a2                	ld	s3,40(sp)
    8000265e:	7a02                	ld	s4,32(sp)
    80002660:	6ae2                	ld	s5,24(sp)
    80002662:	6b42                	ld	s6,16(sp)
    80002664:	6ba2                	ld	s7,8(sp)
    80002666:	6c02                	ld	s8,0(sp)
    80002668:	6161                	addi	sp,sp,80
    8000266a:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000266c:	85e2                	mv	a1,s8
    8000266e:	854a                	mv	a0,s2
    80002670:	00000097          	auipc	ra,0x0
    80002674:	bec080e7          	jalr	-1044(ra) # 8000225c <sleep>
    havekids = 0;
    80002678:	bf39                	j	80002596 <wait+0x4a>

000000008000267a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000267a:	7179                	addi	sp,sp,-48
    8000267c:	f406                	sd	ra,40(sp)
    8000267e:	f022                	sd	s0,32(sp)
    80002680:	ec26                	sd	s1,24(sp)
    80002682:	e84a                	sd	s2,16(sp)
    80002684:	e44e                	sd	s3,8(sp)
    80002686:	e052                	sd	s4,0(sp)
    80002688:	1800                	addi	s0,sp,48
    8000268a:	84aa                	mv	s1,a0
    8000268c:	892e                	mv	s2,a1
    8000268e:	89b2                	mv	s3,a2
    80002690:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002692:	fffff097          	auipc	ra,0xfffff
    80002696:	470080e7          	jalr	1136(ra) # 80001b02 <myproc>
  if(user_dst){
    8000269a:	c08d                	beqz	s1,800026bc <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000269c:	86d2                	mv	a3,s4
    8000269e:	864e                	mv	a2,s3
    800026a0:	85ca                	mv	a1,s2
    800026a2:	6928                	ld	a0,80(a0)
    800026a4:	fffff097          	auipc	ra,0xfffff
    800026a8:	11a080e7          	jalr	282(ra) # 800017be <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800026ac:	70a2                	ld	ra,40(sp)
    800026ae:	7402                	ld	s0,32(sp)
    800026b0:	64e2                	ld	s1,24(sp)
    800026b2:	6942                	ld	s2,16(sp)
    800026b4:	69a2                	ld	s3,8(sp)
    800026b6:	6a02                	ld	s4,0(sp)
    800026b8:	6145                	addi	sp,sp,48
    800026ba:	8082                	ret
    memmove((char *)dst, src, len);
    800026bc:	000a061b          	sext.w	a2,s4
    800026c0:	85ce                	mv	a1,s3
    800026c2:	854a                	mv	a0,s2
    800026c4:	ffffe097          	auipc	ra,0xffffe
    800026c8:	66a080e7          	jalr	1642(ra) # 80000d2e <memmove>
    return 0;
    800026cc:	8526                	mv	a0,s1
    800026ce:	bff9                	j	800026ac <either_copyout+0x32>

00000000800026d0 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026d0:	7179                	addi	sp,sp,-48
    800026d2:	f406                	sd	ra,40(sp)
    800026d4:	f022                	sd	s0,32(sp)
    800026d6:	ec26                	sd	s1,24(sp)
    800026d8:	e84a                	sd	s2,16(sp)
    800026da:	e44e                	sd	s3,8(sp)
    800026dc:	e052                	sd	s4,0(sp)
    800026de:	1800                	addi	s0,sp,48
    800026e0:	892a                	mv	s2,a0
    800026e2:	84ae                	mv	s1,a1
    800026e4:	89b2                	mv	s3,a2
    800026e6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026e8:	fffff097          	auipc	ra,0xfffff
    800026ec:	41a080e7          	jalr	1050(ra) # 80001b02 <myproc>
  if(user_src){
    800026f0:	c08d                	beqz	s1,80002712 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800026f2:	86d2                	mv	a3,s4
    800026f4:	864e                	mv	a2,s3
    800026f6:	85ca                	mv	a1,s2
    800026f8:	6928                	ld	a0,80(a0)
    800026fa:	fffff097          	auipc	ra,0xfffff
    800026fe:	150080e7          	jalr	336(ra) # 8000184a <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002702:	70a2                	ld	ra,40(sp)
    80002704:	7402                	ld	s0,32(sp)
    80002706:	64e2                	ld	s1,24(sp)
    80002708:	6942                	ld	s2,16(sp)
    8000270a:	69a2                	ld	s3,8(sp)
    8000270c:	6a02                	ld	s4,0(sp)
    8000270e:	6145                	addi	sp,sp,48
    80002710:	8082                	ret
    memmove(dst, (char*)src, len);
    80002712:	000a061b          	sext.w	a2,s4
    80002716:	85ce                	mv	a1,s3
    80002718:	854a                	mv	a0,s2
    8000271a:	ffffe097          	auipc	ra,0xffffe
    8000271e:	614080e7          	jalr	1556(ra) # 80000d2e <memmove>
    return 0;
    80002722:	8526                	mv	a0,s1
    80002724:	bff9                	j	80002702 <either_copyin+0x32>

0000000080002726 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002726:	715d                	addi	sp,sp,-80
    80002728:	e486                	sd	ra,72(sp)
    8000272a:	e0a2                	sd	s0,64(sp)
    8000272c:	fc26                	sd	s1,56(sp)
    8000272e:	f84a                	sd	s2,48(sp)
    80002730:	f44e                	sd	s3,40(sp)
    80002732:	f052                	sd	s4,32(sp)
    80002734:	ec56                	sd	s5,24(sp)
    80002736:	e85a                	sd	s6,16(sp)
    80002738:	e45e                	sd	s7,8(sp)
    8000273a:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000273c:	00006517          	auipc	a0,0x6
    80002740:	c7c50513          	addi	a0,a0,-900 # 800083b8 <states.0+0x80>
    80002744:	ffffe097          	auipc	ra,0xffffe
    80002748:	e44080e7          	jalr	-444(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000274c:	0000f497          	auipc	s1,0xf
    80002750:	afc48493          	addi	s1,s1,-1284 # 80011248 <proc+0x158>
    80002754:	00029917          	auipc	s2,0x29
    80002758:	cf490913          	addi	s2,s2,-780 # 8002b448 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000275c:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000275e:	00006997          	auipc	s3,0x6
    80002762:	b2298993          	addi	s3,s3,-1246 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002766:	00006a97          	auipc	s5,0x6
    8000276a:	b22a8a93          	addi	s5,s5,-1246 # 80008288 <digits+0x248>
    printf("\n");
    8000276e:	00006a17          	auipc	s4,0x6
    80002772:	c4aa0a13          	addi	s4,s4,-950 # 800083b8 <states.0+0x80>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002776:	00006b97          	auipc	s7,0x6
    8000277a:	bc2b8b93          	addi	s7,s7,-1086 # 80008338 <states.0>
    8000277e:	a00d                	j	800027a0 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002780:	ed86a583          	lw	a1,-296(a3) # ed8 <_entry-0x7ffff128>
    80002784:	8556                	mv	a0,s5
    80002786:	ffffe097          	auipc	ra,0xffffe
    8000278a:	e02080e7          	jalr	-510(ra) # 80000588 <printf>
    printf("\n");
    8000278e:	8552                	mv	a0,s4
    80002790:	ffffe097          	auipc	ra,0xffffe
    80002794:	df8080e7          	jalr	-520(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002798:	68848493          	addi	s1,s1,1672
    8000279c:	03248163          	beq	s1,s2,800027be <procdump+0x98>
    if(p->state == UNUSED)
    800027a0:	86a6                	mv	a3,s1
    800027a2:	ec04a783          	lw	a5,-320(s1)
    800027a6:	dbed                	beqz	a5,80002798 <procdump+0x72>
      state = "???";
    800027a8:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027aa:	fcfb6be3          	bltu	s6,a5,80002780 <procdump+0x5a>
    800027ae:	1782                	slli	a5,a5,0x20
    800027b0:	9381                	srli	a5,a5,0x20
    800027b2:	078e                	slli	a5,a5,0x3
    800027b4:	97de                	add	a5,a5,s7
    800027b6:	6390                	ld	a2,0(a5)
    800027b8:	f661                	bnez	a2,80002780 <procdump+0x5a>
      state = "???";
    800027ba:	864e                	mv	a2,s3
    800027bc:	b7d1                	j	80002780 <procdump+0x5a>
  }
}
    800027be:	60a6                	ld	ra,72(sp)
    800027c0:	6406                	ld	s0,64(sp)
    800027c2:	74e2                	ld	s1,56(sp)
    800027c4:	7942                	ld	s2,48(sp)
    800027c6:	79a2                	ld	s3,40(sp)
    800027c8:	7a02                	ld	s4,32(sp)
    800027ca:	6ae2                	ld	s5,24(sp)
    800027cc:	6b42                	ld	s6,16(sp)
    800027ce:	6ba2                	ld	s7,8(sp)
    800027d0:	6161                	addi	sp,sp,80
    800027d2:	8082                	ret

00000000800027d4 <pageSwapPolicy>:
// }



  int 
  pageSwapPolicy(){
    800027d4:	1141                	addi	sp,sp,-16
    800027d6:	e422                	sd	s0,8(sp)
    800027d8:	0800                	addi	s0,sp,16
    #ifdef NONE
    return 1;
    #endif

    return 1;
  }
    800027da:	4505                	li	a0,1
    800027dc:	6422                	ld	s0,8(sp)
    800027de:	0141                	addi	sp,sp,16
    800027e0:	8082                	ret

00000000800027e2 <nfua>:


int
nfua(){
    800027e2:	1141                	addi	sp,sp,-16
    800027e4:	e406                	sd	ra,8(sp)
    800027e6:	e022                	sd	s0,0(sp)
    800027e8:	0800                	addi	s0,sp,16
struct proc *proc = myproc();
    800027ea:	fffff097          	auipc	ra,0xfffff
    800027ee:	318080e7          	jalr	792(ra) # 80001b02 <myproc>
    800027f2:	85aa                	mv	a1,a0
uint64 lowest =  __UINT64_MAX__;
int lowestIdx = 1;
struct metaData *page = proc->pagesInPysical+1;//start from the second idx  
    800027f4:	2a050793          	addi	a5,a0,672
while(page < &proc->pagesInPysical[MAX_PSYC_PAGES]){
    800027f8:	48050693          	addi	a3,a0,1152
int lowestIdx = 1;
    800027fc:	4505                	li	a0,1
uint64 lowest =  __UINT64_MAX__;
    800027fe:	567d                	li	a2,-1
  if(page->idxIsHere && page->aging < lowest){
    lowest = page->aging;
    lowestIdx= (int)(page-(proc->pagesInPysical));
    80002800:	28058593          	addi	a1,a1,640
    80002804:	a029                	j	8000280e <nfua+0x2c>
  }
  page++;
    80002806:	02078793          	addi	a5,a5,32
while(page < &proc->pagesInPysical[MAX_PSYC_PAGES]){
    8000280a:	00f68d63          	beq	a3,a5,80002824 <nfua+0x42>
  if(page->idxIsHere && page->aging < lowest){
    8000280e:	6798                	ld	a4,8(a5)
    80002810:	db7d                	beqz	a4,80002806 <nfua+0x24>
    80002812:	6f98                	ld	a4,24(a5)
    80002814:	fec779e3          	bgeu	a4,a2,80002806 <nfua+0x24>
    lowestIdx= (int)(page-(proc->pagesInPysical));
    80002818:	40b78533          	sub	a0,a5,a1
    8000281c:	8515                	srai	a0,a0,0x5
    8000281e:	2501                	sext.w	a0,a0
    lowest = page->aging;
    80002820:	863a                	mv	a2,a4
    80002822:	b7d5                	j	80002806 <nfua+0x24>
}
return lowestIdx;
}
    80002824:	60a2                	ld	ra,8(sp)
    80002826:	6402                	ld	s0,0(sp)
    80002828:	0141                	addi	sp,sp,16
    8000282a:	8082                	ret

000000008000282c <lafa>:

int
lafa(){
    8000282c:	1141                	addi	sp,sp,-16
    8000282e:	e406                	sd	ra,8(sp)
    80002830:	e022                	sd	s0,0(sp)
    80002832:	0800                	addi	s0,sp,16
  struct metaData *pg;
  int minOnes = 64;
  int minIdx = -1;
  struct proc *p=myproc();
    80002834:	fffff097          	auipc	ra,0xfffff
    80002838:	2ce080e7          	jalr	718(ra) # 80001b02 <myproc>

  for (pg = p->pagesInPysical; pg < &p->pagesInPysical[MAX_PSYC_PAGES]; pg++) {
    8000283c:	28050e93          	addi	t4,a0,640
    80002840:	48050893          	addi	a7,a0,1152
    80002844:	8876                	mv	a6,t4
  int minIdx = -1;
    80002846:	557d                	li	a0,-1
  int minOnes = 64;
    80002848:	04000e13          	li	t3,64
    if (pg->idxIsHere) {
      int ones = 0;
      for (int i = 0; i < 64; i++) {
    8000284c:	4301                	li	t1,0
    8000284e:	04000593          	li	a1,64
        if ((pg->aging >> i) & 1) {
          ones++;
        }
      }
      if (ones < minOnes || (minIdx == -1 && ones <= minOnes)) {
    80002852:	5f7d                	li	t5,-1
    80002854:	a80d                	j	80002886 <lafa+0x5a>
      for (int i = 0; i < 64; i++) {
    80002856:	2785                	addiw	a5,a5,1
    80002858:	00b78863          	beq	a5,a1,80002868 <lafa+0x3c>
        if ((pg->aging >> i) & 1) {
    8000285c:	00f65733          	srl	a4,a2,a5
    80002860:	8b05                	andi	a4,a4,1
    80002862:	db75                	beqz	a4,80002856 <lafa+0x2a>
          ones++;
    80002864:	2685                	addiw	a3,a3,1
    80002866:	bfc5                	j	80002856 <lafa+0x2a>
      if (ones < minOnes || (minIdx == -1 && ones <= minOnes)) {
    80002868:	01c6c663          	blt	a3,t3,80002874 <lafa+0x48>
    8000286c:	01e51963          	bne	a0,t5,8000287e <lafa+0x52>
    80002870:	01c69763          	bne	a3,t3,8000287e <lafa+0x52>
        minOnes = ones;
        minIdx = (int)(pg - p->pagesInPysical);
    80002874:	41d80533          	sub	a0,a6,t4
    80002878:	8515                	srai	a0,a0,0x5
    8000287a:	2501                	sext.w	a0,a0
    8000287c:	8e36                	mv	t3,a3
  for (pg = p->pagesInPysical; pg < &p->pagesInPysical[MAX_PSYC_PAGES]; pg++) {
    8000287e:	02080813          	addi	a6,a6,32
    80002882:	01180a63          	beq	a6,a7,80002896 <lafa+0x6a>
    if (pg->idxIsHere) {
    80002886:	00883783          	ld	a5,8(a6)
    8000288a:	dbf5                	beqz	a5,8000287e <lafa+0x52>
        if ((pg->aging >> i) & 1) {
    8000288c:	01883603          	ld	a2,24(a6)
      for (int i = 0; i < 64; i++) {
    80002890:	879a                	mv	a5,t1
      int ones = 0;
    80002892:	869a                	mv	a3,t1
    80002894:	b7e1                	j	8000285c <lafa+0x30>
      }
    }
  }
  return minIdx;
}
    80002896:	60a2                	ld	ra,8(sp)
    80002898:	6402                	ld	s0,0(sp)
    8000289a:	0141                	addi	sp,sp,16
    8000289c:	8082                	ret

000000008000289e <scfifo>:

int 
scfifo(){
    8000289e:	1101                	addi	sp,sp,-32
    800028a0:	ec06                	sd	ra,24(sp)
    800028a2:	e822                	sd	s0,16(sp)
    800028a4:	e426                	sd	s1,8(sp)
    800028a6:	e04a                	sd	s2,0(sp)
    800028a8:	1000                	addi	s0,sp,32
    struct proc *p=myproc();
    800028aa:	fffff097          	auipc	ra,0xfffff
    800028ae:	258080e7          	jalr	600(ra) # 80001b02 <myproc>
    800028b2:	892a                	mv	s2,a0

  struct metaData *page=p->pagesInPysical;
    800028b4:	28050593          	addi	a1,a0,640
  uint64 lowestCreateTime = __UINT64_MAX__;
  int lowestCreateIdx = -1;

  while (page < &p->pagesInPysical[MAX_PSYC_PAGES]) {
    800028b8:	48050693          	addi	a3,a0,1152
  struct metaData *page=p->pagesInPysical;
    800028bc:	87ae                	mv	a5,a1
  int lowestCreateIdx = -1;
    800028be:	54fd                	li	s1,-1
  uint64 lowestCreateTime = __UINT64_MAX__;
    800028c0:	567d                	li	a2,-1
    800028c2:	a029                	j	800028cc <scfifo+0x2e>
    if (page->idxIsHere && page->pageCreateTime <= lowestCreateTime) {
      lowestCreateIdx = (int)(page - p->pagesInPysical);
      lowestCreateTime = page->pageCreateTime;
    }
    page++;
    800028c4:	02078793          	addi	a5,a5,32
  while (page < &p->pagesInPysical[MAX_PSYC_PAGES]) {
    800028c8:	00f68e63          	beq	a3,a5,800028e4 <scfifo+0x46>
    if (page->idxIsHere && page->pageCreateTime <= lowestCreateTime) {
    800028cc:	6798                	ld	a4,8(a5)
    800028ce:	db7d                	beqz	a4,800028c4 <scfifo+0x26>
    800028d0:	6b98                	ld	a4,16(a5)
    800028d2:	fee669e3          	bltu	a2,a4,800028c4 <scfifo+0x26>
      lowestCreateIdx = (int)(page - p->pagesInPysical);
    800028d6:	40b78633          	sub	a2,a5,a1
    800028da:	8615                	srai	a2,a2,0x5
    800028dc:	0006049b          	sext.w	s1,a2
      lowestCreateTime = page->pageCreateTime;
    800028e0:	863a                	mv	a2,a4
    800028e2:	b7cd                	j	800028c4 <scfifo+0x26>
  }

  pte_t *pte = walk(p->pagetable, p->pagesInPysical[lowestCreateIdx].va, 0);
    800028e4:	01448793          	addi	a5,s1,20
    800028e8:	0796                	slli	a5,a5,0x5
    800028ea:	97ca                	add	a5,a5,s2
    800028ec:	4601                	li	a2,0
    800028ee:	638c                	ld	a1,0(a5)
    800028f0:	05093503          	ld	a0,80(s2)
    800028f4:	ffffe097          	auipc	ra,0xffffe
    800028f8:	776080e7          	jalr	1910(ra) # 8000106a <walk>
  if ((*pte & PTE_A) != 0) {
    800028fc:	611c                	ld	a5,0(a0)
    800028fe:	0407f713          	andi	a4,a5,64
    80002902:	cf11                	beqz	a4,8000291e <scfifo+0x80>
    *pte =*pte & ~PTE_A;
    80002904:	fbf7f793          	andi	a5,a5,-65
    80002908:	e11c                	sd	a5,0(a0)
    p->helpPageTimer++;
    8000290a:	68093783          	ld	a5,1664(s2)
    8000290e:	0785                	addi	a5,a5,1
    80002910:	68f93023          	sd	a5,1664(s2)
    p->pagesInPysical[lowestCreateIdx].pageCreateTime = p->helpPageTimer;
    80002914:	00549713          	slli	a4,s1,0x5
    80002918:	993a                	add	s2,s2,a4
    8000291a:	28f93823          	sd	a5,656(s2)
  }
  return lowestCreateIdx;
}
    8000291e:	8526                	mv	a0,s1
    80002920:	60e2                	ld	ra,24(sp)
    80002922:	6442                	ld	s0,16(sp)
    80002924:	64a2                	ld	s1,8(sp)
    80002926:	6902                	ld	s2,0(sp)
    80002928:	6105                	addi	sp,sp,32
    8000292a:	8082                	ret

000000008000292c <agePage>:

void agePage() {
    8000292c:	7179                	addi	sp,sp,-48
    8000292e:	f406                	sd	ra,40(sp)
    80002930:	f022                	sd	s0,32(sp)
    80002932:	ec26                	sd	s1,24(sp)
    80002934:	e84a                	sd	s2,16(sp)
    80002936:	e44e                	sd	s3,8(sp)
    80002938:	e052                	sd	s4,0(sp)
    8000293a:	1800                	addi	s0,sp,48
  struct metaData *page;
  pte_t *entry;
  struct proc *p=myproc();
    8000293c:	fffff097          	auipc	ra,0xfffff
    80002940:	1c6080e7          	jalr	454(ra) # 80001b02 <myproc>
    80002944:	89aa                	mv	s3,a0
  for (page = p->pagesInPysical; page < &p->pagesInPysical[MAX_PSYC_PAGES]; page++) {
    80002946:	28050493          	addi	s1,a0,640
    8000294a:	48050913          	addi	s2,a0,1152
    if (page->idxIsHere) {
      entry = walk(p->pagetable, page->va, 0);
      if ((*entry & PTE_A) != 0) {
        page->aging = (page->aging >> 1) | (1ULL << 63);
    8000294e:	5a7d                	li	s4,-1
    80002950:	1a7e                	slli	s4,s4,0x3f
    80002952:	a821                	j	8000296a <agePage+0x3e>
      } else {
        page->aging = (page->aging >> 1);
    80002954:	6c9c                	ld	a5,24(s1)
    80002956:	8385                	srli	a5,a5,0x1
    80002958:	ec9c                	sd	a5,24(s1)
      }
      *entry = *entry & ~PTE_A;
    8000295a:	611c                	ld	a5,0(a0)
    8000295c:	fbf7f793          	andi	a5,a5,-65
    80002960:	e11c                	sd	a5,0(a0)
  for (page = p->pagesInPysical; page < &p->pagesInPysical[MAX_PSYC_PAGES]; page++) {
    80002962:	02048493          	addi	s1,s1,32
    80002966:	02990563          	beq	s2,s1,80002990 <agePage+0x64>
    if (page->idxIsHere) {
    8000296a:	649c                	ld	a5,8(s1)
    8000296c:	dbfd                	beqz	a5,80002962 <agePage+0x36>
      entry = walk(p->pagetable, page->va, 0);
    8000296e:	4601                	li	a2,0
    80002970:	608c                	ld	a1,0(s1)
    80002972:	0509b503          	ld	a0,80(s3)
    80002976:	ffffe097          	auipc	ra,0xffffe
    8000297a:	6f4080e7          	jalr	1780(ra) # 8000106a <walk>
      if ((*entry & PTE_A) != 0) {
    8000297e:	611c                	ld	a5,0(a0)
    80002980:	0407f793          	andi	a5,a5,64
    80002984:	dbe1                	beqz	a5,80002954 <agePage+0x28>
        page->aging = (page->aging >> 1) | (1ULL << 63);
    80002986:	6c9c                	ld	a5,24(s1)
    80002988:	8385                	srli	a5,a5,0x1
    8000298a:	0147e7b3          	or	a5,a5,s4
    8000298e:	b7e9                	j	80002958 <agePage+0x2c>
    }
  }
}
    80002990:	70a2                	ld	ra,40(sp)
    80002992:	7402                	ld	s0,32(sp)
    80002994:	64e2                	ld	s1,24(sp)
    80002996:	6942                	ld	s2,16(sp)
    80002998:	69a2                	ld	s3,8(sp)
    8000299a:	6a02                	ld	s4,0(sp)
    8000299c:	6145                	addi	sp,sp,48
    8000299e:	8082                	ret

00000000800029a0 <swapOutFromPysc>:


//ADDED 4.2
//swap out from pysc == swap in swap file
int 
swapOutFromPysc(pagetable_t pagetable,struct proc *p){
    800029a0:	7139                	addi	sp,sp,-64
    800029a2:	fc06                	sd	ra,56(sp)
    800029a4:	f822                	sd	s0,48(sp)
    800029a6:	f426                	sd	s1,40(sp)
    800029a8:	f04a                	sd	s2,32(sp)
    800029aa:	ec4e                	sd	s3,24(sp)
    800029ac:	e852                	sd	s4,16(sp)
    800029ae:	e456                	sd	s5,8(sp)
    800029b0:	e05a                	sd	s6,0(sp)
    800029b2:	0080                	addi	s0,sp,64
       if(p->physicalPagesCount+p->swapPagesCount==MAX_TOTAL_PAGES){
    800029b4:	2705b783          	ld	a5,624(a1)
    800029b8:	2785b703          	ld	a4,632(a1)
    800029bc:	97ba                	add	a5,a5,a4
    800029be:	02000713          	li	a4,32
    800029c2:	06e78c63          	beq	a5,a4,80002a3a <swapOutFromPysc+0x9a>
    800029c6:	8aaa                	mv	s5,a0
    800029c8:	892e                	mv	s2,a1
        printf("exceeded number of possible pages\n");
        return -1;
      }
        printf("2here\n");
    800029ca:	00006517          	auipc	a0,0x6
    800029ce:	8f650513          	addi	a0,a0,-1802 # 800082c0 <digits+0x280>
    800029d2:	ffffe097          	auipc	ra,0xffffe
    800029d6:	bb6080e7          	jalr	-1098(ra) # 80000588 <printf>
      //idx of page to removed from pysical memory 
      int idx = pageSwapPolicy(); 
      printf("choosen idx:%d\n",idx);
    800029da:	4585                	li	a1,1
    800029dc:	00006517          	auipc	a0,0x6
    800029e0:	8ec50513          	addi	a0,a0,-1812 # 800082c8 <digits+0x288>
    800029e4:	ffffe097          	auipc	ra,0xffffe
    800029e8:	ba4080e7          	jalr	-1116(ra) # 80000588 <printf>
      struct metaData *removedPageFromPsyc = &p->pagesInPysical[idx];
              printf("3here\n");
    800029ec:	00006517          	auipc	a0,0x6
    800029f0:	8ec50513          	addi	a0,a0,-1812 # 800082d8 <digits+0x298>
    800029f4:	ffffe097          	auipc	ra,0xffffe
    800029f8:	b94080e7          	jalr	-1132(ra) # 80000588 <printf>

      //looking for free struct into pagesInSwap to put the removed page
      for(struct metaData *page = p->pagesInSwap; page < &p->pagesInSwap[MAX_PSYC_PAGES]; page++){
    800029fc:	48090b13          	addi	s6,s2,1152
    80002a00:	68090a13          	addi	s4,s2,1664
    80002a04:	84da                	mv	s1,s6
        //empty space in the swapArr is found
          printf("4here\n");
    80002a06:	00006997          	auipc	s3,0x6
    80002a0a:	8da98993          	addi	s3,s3,-1830 # 800082e0 <digits+0x2a0>
    80002a0e:	854e                	mv	a0,s3
    80002a10:	ffffe097          	auipc	ra,0xffffe
    80002a14:	b78080e7          	jalr	-1160(ra) # 80000588 <printf>
        if(page->idxIsHere==0){
    80002a18:	649c                	ld	a5,8(s1)
    80002a1a:	cb95                	beqz	a5,80002a4e <swapOutFromPysc+0xae>
      for(struct metaData *page = p->pagesInSwap; page < &p->pagesInSwap[MAX_PSYC_PAGES]; page++){
    80002a1c:	02048493          	addi	s1,s1,32
    80002a20:	fe9a17e3          	bne	s4,s1,80002a0e <swapOutFromPysc+0x6e>

          sfence_vma(); // flush to TLB
          break;
      }
    }
    return 0;
    80002a24:	4501                	li	a0,0
  }
    80002a26:	70e2                	ld	ra,56(sp)
    80002a28:	7442                	ld	s0,48(sp)
    80002a2a:	74a2                	ld	s1,40(sp)
    80002a2c:	7902                	ld	s2,32(sp)
    80002a2e:	69e2                	ld	s3,24(sp)
    80002a30:	6a42                	ld	s4,16(sp)
    80002a32:	6aa2                	ld	s5,8(sp)
    80002a34:	6b02                	ld	s6,0(sp)
    80002a36:	6121                	addi	sp,sp,64
    80002a38:	8082                	ret
        printf("exceeded number of possible pages\n");
    80002a3a:	00006517          	auipc	a0,0x6
    80002a3e:	85e50513          	addi	a0,a0,-1954 # 80008298 <digits+0x258>
    80002a42:	ffffe097          	auipc	ra,0xffffe
    80002a46:	b46080e7          	jalr	-1210(ra) # 80000588 <printf>
        return -1;
    80002a4a:	557d                	li	a0,-1
    80002a4c:	bfe9                	j	80002a26 <swapOutFromPysc+0x86>
          page->idxIsHere = 1;
    80002a4e:	4785                	li	a5,1
    80002a50:	e49c                	sd	a5,8(s1)
          page->va=removedPageFromPsyc->va;
    80002a52:	2a093583          	ld	a1,672(s2)
    80002a56:	e08c                	sd	a1,0(s1)
          pte_t* entry = walk(pagetable, page->va, 0);
    80002a58:	4601                	li	a2,0
    80002a5a:	8556                	mv	a0,s5
    80002a5c:	ffffe097          	auipc	ra,0xffffe
    80002a60:	60e080e7          	jalr	1550(ra) # 8000106a <walk>
    80002a64:	8a2a                	mv	s4,a0
          uint64 pa= PTE2PA(*entry);
    80002a66:	00053983          	ld	s3,0(a0)
    80002a6a:	00a9d993          	srli	s3,s3,0xa
    80002a6e:	09b2                	slli	s3,s3,0xc
                    printf("5here\n");
    80002a70:	00006517          	auipc	a0,0x6
    80002a74:	87850513          	addi	a0,a0,-1928 # 800082e8 <digits+0x2a8>
    80002a78:	ffffe097          	auipc	ra,0xffffe
    80002a7c:	b10080e7          	jalr	-1264(ra) # 80000588 <printf>
          uint64 off=(page-p->pagesInSwap) * PGSIZE;
    80002a80:	41648633          	sub	a2,s1,s6
    80002a84:	061e                	slli	a2,a2,0x7
          if(writeToSwapFile(p,(char *)pa,off, PGSIZE)< PGSIZE){
    80002a86:	6685                	lui	a3,0x1
    80002a88:	2601                	sext.w	a2,a2
    80002a8a:	85ce                	mv	a1,s3
    80002a8c:	854a                	mv	a0,s2
    80002a8e:	00002097          	auipc	ra,0x2
    80002a92:	d1a080e7          	jalr	-742(ra) # 800047a8 <writeToSwapFile>
    80002a96:	6785                	lui	a5,0x1
    80002a98:	06f54063          	blt	a0,a5,80002af8 <swapOutFromPysc+0x158>
            printf("6here\n");
    80002a9c:	00006517          	auipc	a0,0x6
    80002aa0:	85c50513          	addi	a0,a0,-1956 # 800082f8 <digits+0x2b8>
    80002aa4:	ffffe097          	auipc	ra,0xffffe
    80002aa8:	ae4080e7          	jalr	-1308(ra) # 80000588 <printf>
          p->swapPagesCount++;
    80002aac:	27893783          	ld	a5,632(s2)
    80002ab0:	0785                	addi	a5,a5,1
    80002ab2:	26f93c23          	sd	a5,632(s2)
          kfree((void *)pa);
    80002ab6:	854e                	mv	a0,s3
    80002ab8:	ffffe097          	auipc	ra,0xffffe
    80002abc:	f32080e7          	jalr	-206(ra) # 800009ea <kfree>
          *entry = ~PTE_V & *entry;//not present in pte anymore 
    80002ac0:	000a3783          	ld	a5,0(s4)
    80002ac4:	9bf9                	andi	a5,a5,-2
    80002ac6:	2007e793          	ori	a5,a5,512
    80002aca:	00fa3023          	sd	a5,0(s4)
          removedPageFromPsyc->idxIsHere=0;
    80002ace:	2a093423          	sd	zero,680(s2)
          removedPageFromPsyc->va=0;
    80002ad2:	2a093023          	sd	zero,672(s2)
          p->physicalPagesCount--;
    80002ad6:	27093783          	ld	a5,624(s2)
    80002ada:	17fd                	addi	a5,a5,-1
    80002adc:	26f93823          	sd	a5,624(s2)
                              printf("7here\n");
    80002ae0:	00006517          	auipc	a0,0x6
    80002ae4:	82050513          	addi	a0,a0,-2016 # 80008300 <digits+0x2c0>
    80002ae8:	ffffe097          	auipc	ra,0xffffe
    80002aec:	aa0080e7          	jalr	-1376(ra) # 80000588 <printf>
  asm volatile("sfence.vma zero, zero");
    80002af0:	12000073          	sfence.vma
    return 0;
    80002af4:	4501                	li	a0,0
}
    80002af6:	bf05                	j	80002a26 <swapOutFromPysc+0x86>
            printf("10here\n");
    80002af8:	00005517          	auipc	a0,0x5
    80002afc:	7f850513          	addi	a0,a0,2040 # 800082f0 <digits+0x2b0>
    80002b00:	ffffe097          	auipc	ra,0xffffe
    80002b04:	a88080e7          	jalr	-1400(ra) # 80000588 <printf>
            return -1;
    80002b08:	557d                	li	a0,-1
    80002b0a:	bf31                	j	80002a26 <swapOutFromPysc+0x86>

0000000080002b0c <swtch>:
    80002b0c:	00153023          	sd	ra,0(a0)
    80002b10:	00253423          	sd	sp,8(a0)
    80002b14:	e900                	sd	s0,16(a0)
    80002b16:	ed04                	sd	s1,24(a0)
    80002b18:	03253023          	sd	s2,32(a0)
    80002b1c:	03353423          	sd	s3,40(a0)
    80002b20:	03453823          	sd	s4,48(a0)
    80002b24:	03553c23          	sd	s5,56(a0)
    80002b28:	05653023          	sd	s6,64(a0)
    80002b2c:	05753423          	sd	s7,72(a0)
    80002b30:	05853823          	sd	s8,80(a0)
    80002b34:	05953c23          	sd	s9,88(a0)
    80002b38:	07a53023          	sd	s10,96(a0)
    80002b3c:	07b53423          	sd	s11,104(a0)
    80002b40:	0005b083          	ld	ra,0(a1)
    80002b44:	0085b103          	ld	sp,8(a1)
    80002b48:	6980                	ld	s0,16(a1)
    80002b4a:	6d84                	ld	s1,24(a1)
    80002b4c:	0205b903          	ld	s2,32(a1)
    80002b50:	0285b983          	ld	s3,40(a1)
    80002b54:	0305ba03          	ld	s4,48(a1)
    80002b58:	0385ba83          	ld	s5,56(a1)
    80002b5c:	0405bb03          	ld	s6,64(a1)
    80002b60:	0485bb83          	ld	s7,72(a1)
    80002b64:	0505bc03          	ld	s8,80(a1)
    80002b68:	0585bc83          	ld	s9,88(a1)
    80002b6c:	0605bd03          	ld	s10,96(a1)
    80002b70:	0685bd83          	ld	s11,104(a1)
    80002b74:	8082                	ret

0000000080002b76 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002b76:	1141                	addi	sp,sp,-16
    80002b78:	e406                	sd	ra,8(sp)
    80002b7a:	e022                	sd	s0,0(sp)
    80002b7c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b7e:	00005597          	auipc	a1,0x5
    80002b82:	7ea58593          	addi	a1,a1,2026 # 80008368 <states.0+0x30>
    80002b86:	00028517          	auipc	a0,0x28
    80002b8a:	76a50513          	addi	a0,a0,1898 # 8002b2f0 <tickslock>
    80002b8e:	ffffe097          	auipc	ra,0xffffe
    80002b92:	fb8080e7          	jalr	-72(ra) # 80000b46 <initlock>
}
    80002b96:	60a2                	ld	ra,8(sp)
    80002b98:	6402                	ld	s0,0(sp)
    80002b9a:	0141                	addi	sp,sp,16
    80002b9c:	8082                	ret

0000000080002b9e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002b9e:	1141                	addi	sp,sp,-16
    80002ba0:	e422                	sd	s0,8(sp)
    80002ba2:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ba4:	00004797          	auipc	a5,0x4
    80002ba8:	c9c78793          	addi	a5,a5,-868 # 80006840 <kernelvec>
    80002bac:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002bb0:	6422                	ld	s0,8(sp)
    80002bb2:	0141                	addi	sp,sp,16
    80002bb4:	8082                	ret

0000000080002bb6 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002bb6:	1141                	addi	sp,sp,-16
    80002bb8:	e406                	sd	ra,8(sp)
    80002bba:	e022                	sd	s0,0(sp)
    80002bbc:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002bbe:	fffff097          	auipc	ra,0xfffff
    80002bc2:	f44080e7          	jalr	-188(ra) # 80001b02 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bc6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002bca:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bcc:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002bd0:	00004617          	auipc	a2,0x4
    80002bd4:	43060613          	addi	a2,a2,1072 # 80007000 <_trampoline>
    80002bd8:	00004697          	auipc	a3,0x4
    80002bdc:	42868693          	addi	a3,a3,1064 # 80007000 <_trampoline>
    80002be0:	8e91                	sub	a3,a3,a2
    80002be2:	040007b7          	lui	a5,0x4000
    80002be6:	17fd                	addi	a5,a5,-1
    80002be8:	07b2                	slli	a5,a5,0xc
    80002bea:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bec:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002bf0:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002bf2:	180026f3          	csrr	a3,satp
    80002bf6:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002bf8:	6d38                	ld	a4,88(a0)
    80002bfa:	6134                	ld	a3,64(a0)
    80002bfc:	6585                	lui	a1,0x1
    80002bfe:	96ae                	add	a3,a3,a1
    80002c00:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c02:	6d38                	ld	a4,88(a0)
    80002c04:	00000697          	auipc	a3,0x0
    80002c08:	2ac68693          	addi	a3,a3,684 # 80002eb0 <usertrap>
    80002c0c:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002c0e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c10:	8692                	mv	a3,tp
    80002c12:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c14:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c18:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c1c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c20:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c24:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c26:	6f18                	ld	a4,24(a4)
    80002c28:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c2c:	6928                	ld	a0,80(a0)
    80002c2e:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002c30:	00004717          	auipc	a4,0x4
    80002c34:	46c70713          	addi	a4,a4,1132 # 8000709c <userret>
    80002c38:	8f11                	sub	a4,a4,a2
    80002c3a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002c3c:	577d                	li	a4,-1
    80002c3e:	177e                	slli	a4,a4,0x3f
    80002c40:	8d59                	or	a0,a0,a4
    80002c42:	9782                	jalr	a5
}
    80002c44:	60a2                	ld	ra,8(sp)
    80002c46:	6402                	ld	s0,0(sp)
    80002c48:	0141                	addi	sp,sp,16
    80002c4a:	8082                	ret

0000000080002c4c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002c4c:	1101                	addi	sp,sp,-32
    80002c4e:	ec06                	sd	ra,24(sp)
    80002c50:	e822                	sd	s0,16(sp)
    80002c52:	e426                	sd	s1,8(sp)
    80002c54:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002c56:	00028497          	auipc	s1,0x28
    80002c5a:	69a48493          	addi	s1,s1,1690 # 8002b2f0 <tickslock>
    80002c5e:	8526                	mv	a0,s1
    80002c60:	ffffe097          	auipc	ra,0xffffe
    80002c64:	f76080e7          	jalr	-138(ra) # 80000bd6 <acquire>
  ticks++;
    80002c68:	00006517          	auipc	a0,0x6
    80002c6c:	de850513          	addi	a0,a0,-536 # 80008a50 <ticks>
    80002c70:	411c                	lw	a5,0(a0)
    80002c72:	2785                	addiw	a5,a5,1
    80002c74:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002c76:	fffff097          	auipc	ra,0xfffff
    80002c7a:	64a080e7          	jalr	1610(ra) # 800022c0 <wakeup>
  release(&tickslock);
    80002c7e:	8526                	mv	a0,s1
    80002c80:	ffffe097          	auipc	ra,0xffffe
    80002c84:	00a080e7          	jalr	10(ra) # 80000c8a <release>
}
    80002c88:	60e2                	ld	ra,24(sp)
    80002c8a:	6442                	ld	s0,16(sp)
    80002c8c:	64a2                	ld	s1,8(sp)
    80002c8e:	6105                	addi	sp,sp,32
    80002c90:	8082                	ret

0000000080002c92 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002c92:	7139                	addi	sp,sp,-64
    80002c94:	fc06                	sd	ra,56(sp)
    80002c96:	f822                	sd	s0,48(sp)
    80002c98:	f426                	sd	s1,40(sp)
    80002c9a:	f04a                	sd	s2,32(sp)
    80002c9c:	ec4e                	sd	s3,24(sp)
    80002c9e:	e852                	sd	s4,16(sp)
    80002ca0:	e456                	sd	s5,8(sp)
    80002ca2:	0080                	addi	s0,sp,64
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ca4:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002ca8:	08074863          	bltz	a4,80002d38 <devintr+0xa6>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002cac:	57fd                	li	a5,-1
    80002cae:	17fe                	slli	a5,a5,0x3f
    80002cb0:	0785                	addi	a5,a5,1
    80002cb2:	0cf70f63          	beq	a4,a5,80002d90 <devintr+0xfe>
    80002cb6:	14202773          	csrr	a4,scause

    return 2;
    
  }//ADDED
  #ifndef NONE
  else if(r_scause() == 13 || r_scause() == 15){
    80002cba:	47b5                	li	a5,13
    80002cbc:	00f70863          	beq	a4,a5,80002ccc <devintr+0x3a>
    80002cc0:	14202773          	csrr	a4,scause
    80002cc4:	47bd                	li	a5,15
      return 1;
    }
  }
  #endif 
  else {
    return 0;
    80002cc6:	4501                	li	a0,0
  else if(r_scause() == 13 || r_scause() == 15){
    80002cc8:	04f71f63          	bne	a4,a5,80002d26 <devintr+0x94>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ccc:	143024f3          	csrr	s1,stval
    struct proc *p= myproc();
    80002cd0:	fffff097          	auipc	ra,0xfffff
    80002cd4:	e32080e7          	jalr	-462(ra) # 80001b02 <myproc>
    80002cd8:	892a                	mv	s2,a0
    if ((*(walk(p->pagetable, va, 0)) & PTE_PG) == 0){
    80002cda:	4601                	li	a2,0
    80002cdc:	85a6                	mv	a1,s1
    80002cde:	6928                	ld	a0,80(a0)
    80002ce0:	ffffe097          	auipc	ra,0xffffe
    80002ce4:	38a080e7          	jalr	906(ra) # 8000106a <walk>
    80002ce8:	611c                	ld	a5,0(a0)
    80002cea:	2007f793          	andi	a5,a5,512
    80002cee:	c3f1                	beqz	a5,80002db2 <devintr+0x120>
      if(p->physicalPagesCount ==MAX_PSYC_PAGES){
    80002cf0:	27093703          	ld	a4,624(s2)
    80002cf4:	47c1                	li	a5,16
    80002cf6:	0ef70863          	beq	a4,a5,80002de6 <devintr+0x154>
      char *space= kalloc();
    80002cfa:	ffffe097          	auipc	ra,0xffffe
    80002cfe:	dec080e7          	jalr	-532(ra) # 80000ae6 <kalloc>
    80002d02:	89aa                	mv	s3,a0
      uint64 newVa = PGROUNDDOWN(va);
    80002d04:	75fd                	lui	a1,0xfffff
    80002d06:	8de5                	and	a1,a1,s1
      for(struct metaData *page=p->pagesInSwap;page<&p->pagesInSwap[MAX_PSYC_PAGES];page++){
    80002d08:	48090a93          	addi	s5,s2,1152
    80002d0c:	68090713          	addi	a4,s2,1664
    80002d10:	84d6                	mv	s1,s5
        if(page->va==newVa){
    80002d12:	609c                	ld	a5,0(s1)
    80002d14:	0eb78963          	beq	a5,a1,80002e06 <devintr+0x174>
      for(struct metaData *page=p->pagesInSwap;page<&p->pagesInSwap[MAX_PSYC_PAGES];page++){
    80002d18:	02048493          	addi	s1,s1,32
    80002d1c:	fee49be3          	bne	s1,a4,80002d12 <devintr+0x80>
  asm volatile("sfence.vma zero, zero");
    80002d20:	12000073          	sfence.vma
      return 1;
    80002d24:	4505                	li	a0,1
  }

}
    80002d26:	70e2                	ld	ra,56(sp)
    80002d28:	7442                	ld	s0,48(sp)
    80002d2a:	74a2                	ld	s1,40(sp)
    80002d2c:	7902                	ld	s2,32(sp)
    80002d2e:	69e2                	ld	s3,24(sp)
    80002d30:	6a42                	ld	s4,16(sp)
    80002d32:	6aa2                	ld	s5,8(sp)
    80002d34:	6121                	addi	sp,sp,64
    80002d36:	8082                	ret
     (scause & 0xff) == 9){
    80002d38:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002d3c:	46a5                	li	a3,9
    80002d3e:	f6d797e3          	bne	a5,a3,80002cac <devintr+0x1a>
    int irq = plic_claim();
    80002d42:	00004097          	auipc	ra,0x4
    80002d46:	c06080e7          	jalr	-1018(ra) # 80006948 <plic_claim>
    80002d4a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002d4c:	47a9                	li	a5,10
    80002d4e:	02f50763          	beq	a0,a5,80002d7c <devintr+0xea>
    } else if(irq == VIRTIO0_IRQ){
    80002d52:	4785                	li	a5,1
    80002d54:	02f50963          	beq	a0,a5,80002d86 <devintr+0xf4>
    return 1;
    80002d58:	4505                	li	a0,1
    } else if(irq){
    80002d5a:	d4f1                	beqz	s1,80002d26 <devintr+0x94>
      printf("unexpected interrupt irq=%d\n", irq);
    80002d5c:	85a6                	mv	a1,s1
    80002d5e:	00005517          	auipc	a0,0x5
    80002d62:	61250513          	addi	a0,a0,1554 # 80008370 <states.0+0x38>
    80002d66:	ffffe097          	auipc	ra,0xffffe
    80002d6a:	822080e7          	jalr	-2014(ra) # 80000588 <printf>
      plic_complete(irq);
    80002d6e:	8526                	mv	a0,s1
    80002d70:	00004097          	auipc	ra,0x4
    80002d74:	bfc080e7          	jalr	-1028(ra) # 8000696c <plic_complete>
    return 1;
    80002d78:	4505                	li	a0,1
    80002d7a:	b775                	j	80002d26 <devintr+0x94>
      uartintr();
    80002d7c:	ffffe097          	auipc	ra,0xffffe
    80002d80:	c1e080e7          	jalr	-994(ra) # 8000099a <uartintr>
    80002d84:	b7ed                	j	80002d6e <devintr+0xdc>
      virtio_disk_intr();
    80002d86:	00004097          	auipc	ra,0x4
    80002d8a:	0b2080e7          	jalr	178(ra) # 80006e38 <virtio_disk_intr>
    80002d8e:	b7c5                	j	80002d6e <devintr+0xdc>
    if(cpuid() == 0){
    80002d90:	fffff097          	auipc	ra,0xfffff
    80002d94:	d46080e7          	jalr	-698(ra) # 80001ad6 <cpuid>
    80002d98:	c901                	beqz	a0,80002da8 <devintr+0x116>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d9a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d9e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002da0:	14479073          	csrw	sip,a5
    return 2;
    80002da4:	4509                	li	a0,2
    80002da6:	b741                	j	80002d26 <devintr+0x94>
      clockintr();
    80002da8:	00000097          	auipc	ra,0x0
    80002dac:	ea4080e7          	jalr	-348(ra) # 80002c4c <clockintr>
    80002db0:	b7ed                	j	80002d9a <devintr+0x108>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002db2:	142025f3          	csrr	a1,scause
      printf("usertrap(): segmentation fault %p pid=%d\n", r_scause(), p->pid);
    80002db6:	03092603          	lw	a2,48(s2)
    80002dba:	00005517          	auipc	a0,0x5
    80002dbe:	5d650513          	addi	a0,a0,1494 # 80008390 <states.0+0x58>
    80002dc2:	ffffd097          	auipc	ra,0xffffd
    80002dc6:	7c6080e7          	jalr	1990(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dca:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002dce:	14302673          	csrr	a2,stval
      printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002dd2:	00005517          	auipc	a0,0x5
    80002dd6:	5ee50513          	addi	a0,a0,1518 # 800083c0 <states.0+0x88>
    80002dda:	ffffd097          	auipc	ra,0xffffd
    80002dde:	7ae080e7          	jalr	1966(ra) # 80000588 <printf>
      return 0;
    80002de2:	4501                	li	a0,0
    80002de4:	b789                	j	80002d26 <devintr+0x94>
        printf("1here1\n");
    80002de6:	00005517          	auipc	a0,0x5
    80002dea:	5fa50513          	addi	a0,a0,1530 # 800083e0 <states.0+0xa8>
    80002dee:	ffffd097          	auipc	ra,0xffffd
    80002df2:	79a080e7          	jalr	1946(ra) # 80000588 <printf>
        swapOutFromPysc(p->pagetable,p);
    80002df6:	85ca                	mv	a1,s2
    80002df8:	05093503          	ld	a0,80(s2)
    80002dfc:	00000097          	auipc	ra,0x0
    80002e00:	ba4080e7          	jalr	-1116(ra) # 800029a0 <swapOutFromPysc>
    80002e04:	bddd                	j	80002cfa <devintr+0x68>
          pte_t *entry = walk(p->pagetable, newVa, 0);
    80002e06:	4601                	li	a2,0
    80002e08:	05093503          	ld	a0,80(s2)
    80002e0c:	ffffe097          	auipc	ra,0xffffe
    80002e10:	25e080e7          	jalr	606(ra) # 8000106a <walk>
    80002e14:	8a2a                	mv	s4,a0
             if (readFromSwapFile(p, space,(page-p->pagesInSwap)*PGSIZE, PGSIZE) < PGSIZE){
    80002e16:	41548633          	sub	a2,s1,s5
    80002e1a:	6685                	lui	a3,0x1
    80002e1c:	0076161b          	slliw	a2,a2,0x7
    80002e20:	85ce                	mv	a1,s3
    80002e22:	854a                	mv	a0,s2
    80002e24:	00002097          	auipc	ra,0x2
    80002e28:	9e4080e7          	jalr	-1564(ra) # 80004808 <readFromSwapFile>
    80002e2c:	6785                	lui	a5,0x1
    80002e2e:	06f54463          	blt	a0,a5,80002e96 <devintr+0x204>
        for(freeP = p->pagesInPysical; freeP < &p->pagesInPysical[MAX_PSYC_PAGES]; freeP++ ){
    80002e32:	28090613          	addi	a2,s2,640
    80002e36:	48090693          	addi	a3,s2,1152
    80002e3a:	87b2                	mv	a5,a2
          if(freeP->idxIsHere==0){
    80002e3c:	6798                	ld	a4,8(a5)
    80002e3e:	c72d                	beqz	a4,80002ea8 <devintr+0x216>
        for(freeP = p->pagesInPysical; freeP < &p->pagesInPysical[MAX_PSYC_PAGES]; freeP++ ){
    80002e40:	02078793          	addi	a5,a5,32 # 1020 <_entry-0x7fffefe0>
    80002e44:	fed79ce3          	bne	a5,a3,80002e3c <devintr+0x1aa>
        int freeIdx=0; 
    80002e48:	4781                	li	a5,0
        freeP->idxIsHere=1;
    80002e4a:	0796                	slli	a5,a5,0x5
    80002e4c:	97ca                	add	a5,a5,s2
    80002e4e:	4705                	li	a4,1
    80002e50:	28e7b423          	sd	a4,648(a5)
        freeP->va=page->va;
    80002e54:	6098                	ld	a4,0(s1)
    80002e56:	28e7b023          	sd	a4,640(a5)
        p->physicalPagesCount++;//we update our counter as well 
    80002e5a:	27093783          	ld	a5,624(s2)
    80002e5e:	0785                	addi	a5,a5,1
    80002e60:	26f93823          	sd	a5,624(s2)
        p->swapPagesCount--;
    80002e64:	27893783          	ld	a5,632(s2)
    80002e68:	17fd                	addi	a5,a5,-1
    80002e6a:	26f93c23          	sd	a5,632(s2)
        page->idxIsHere=0;
    80002e6e:	0004b423          	sd	zero,8(s1)
        page->va=0;
    80002e72:	0004b023          	sd	zero,0(s1)
        page->aging=0;
    80002e76:	0004bc23          	sd	zero,24(s1)
        *entry= PA2PTE((uint64)space)|PTE_FLAGS(*entry);
    80002e7a:	00c9d993          	srli	s3,s3,0xc
    80002e7e:	09aa                	slli	s3,s3,0xa
    80002e80:	000a3783          	ld	a5,0(s4)
    80002e84:	1ff7f793          	andi	a5,a5,511
        *entry=*entry & ~PTE_PG;
    80002e88:	0137e9b3          	or	s3,a5,s3
        *entry=*entry | PTE_V;
    80002e8c:	0019e993          	ori	s3,s3,1
    80002e90:	013a3023          	sd	s3,0(s4)
        break;
    80002e94:	b571                	j	80002d20 <devintr+0x8e>
              printf("error: readFromSwapFile less than PGSIZE chars in usertrap\
    80002e96:	00005517          	auipc	a0,0x5
    80002e9a:	55250513          	addi	a0,a0,1362 # 800083e8 <states.0+0xb0>
    80002e9e:	ffffd097          	auipc	ra,0xffffd
    80002ea2:	6ea080e7          	jalr	1770(ra) # 80000588 <printf>
    80002ea6:	b771                	j	80002e32 <devintr+0x1a0>
            freeIdx=(int)(freeP-(p->pagesInPysical));
    80002ea8:	8f91                	sub	a5,a5,a2
    80002eaa:	8795                	srai	a5,a5,0x5
    80002eac:	2781                	sext.w	a5,a5
            break;
    80002eae:	bf71                	j	80002e4a <devintr+0x1b8>

0000000080002eb0 <usertrap>:
{
    80002eb0:	1101                	addi	sp,sp,-32
    80002eb2:	ec06                	sd	ra,24(sp)
    80002eb4:	e822                	sd	s0,16(sp)
    80002eb6:	e426                	sd	s1,8(sp)
    80002eb8:	e04a                	sd	s2,0(sp)
    80002eba:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ebc:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002ec0:	1007f793          	andi	a5,a5,256
    80002ec4:	e3b1                	bnez	a5,80002f08 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ec6:	00004797          	auipc	a5,0x4
    80002eca:	97a78793          	addi	a5,a5,-1670 # 80006840 <kernelvec>
    80002ece:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002ed2:	fffff097          	auipc	ra,0xfffff
    80002ed6:	c30080e7          	jalr	-976(ra) # 80001b02 <myproc>
    80002eda:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002edc:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ede:	14102773          	csrr	a4,sepc
    80002ee2:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ee4:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002ee8:	47a1                	li	a5,8
    80002eea:	02f70763          	beq	a4,a5,80002f18 <usertrap+0x68>
   } else if((which_dev = devintr()) != 0){
    80002eee:	00000097          	auipc	ra,0x0
    80002ef2:	da4080e7          	jalr	-604(ra) # 80002c92 <devintr>
    80002ef6:	892a                	mv	s2,a0
    80002ef8:	c151                	beqz	a0,80002f7c <usertrap+0xcc>
  if(killed(p))
    80002efa:	8526                	mv	a0,s1
    80002efc:	fffff097          	auipc	ra,0xfffff
    80002f00:	61e080e7          	jalr	1566(ra) # 8000251a <killed>
    80002f04:	c929                	beqz	a0,80002f56 <usertrap+0xa6>
    80002f06:	a099                	j	80002f4c <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002f08:	00005517          	auipc	a0,0x5
    80002f0c:	53050513          	addi	a0,a0,1328 # 80008438 <states.0+0x100>
    80002f10:	ffffd097          	auipc	ra,0xffffd
    80002f14:	62e080e7          	jalr	1582(ra) # 8000053e <panic>
    if(killed(p))
    80002f18:	fffff097          	auipc	ra,0xfffff
    80002f1c:	602080e7          	jalr	1538(ra) # 8000251a <killed>
    80002f20:	e921                	bnez	a0,80002f70 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002f22:	6cb8                	ld	a4,88(s1)
    80002f24:	6f1c                	ld	a5,24(a4)
    80002f26:	0791                	addi	a5,a5,4
    80002f28:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f2a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002f2e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f32:	10079073          	csrw	sstatus,a5
    syscall();
    80002f36:	00000097          	auipc	ra,0x0
    80002f3a:	2d4080e7          	jalr	724(ra) # 8000320a <syscall>
  if(killed(p))
    80002f3e:	8526                	mv	a0,s1
    80002f40:	fffff097          	auipc	ra,0xfffff
    80002f44:	5da080e7          	jalr	1498(ra) # 8000251a <killed>
    80002f48:	c911                	beqz	a0,80002f5c <usertrap+0xac>
    80002f4a:	4901                	li	s2,0
    exit(-1);
    80002f4c:	557d                	li	a0,-1
    80002f4e:	fffff097          	auipc	ra,0xfffff
    80002f52:	442080e7          	jalr	1090(ra) # 80002390 <exit>
  if(which_dev == 2)
    80002f56:	4789                	li	a5,2
    80002f58:	04f90f63          	beq	s2,a5,80002fb6 <usertrap+0x106>
  usertrapret();
    80002f5c:	00000097          	auipc	ra,0x0
    80002f60:	c5a080e7          	jalr	-934(ra) # 80002bb6 <usertrapret>
}
    80002f64:	60e2                	ld	ra,24(sp)
    80002f66:	6442                	ld	s0,16(sp)
    80002f68:	64a2                	ld	s1,8(sp)
    80002f6a:	6902                	ld	s2,0(sp)
    80002f6c:	6105                	addi	sp,sp,32
    80002f6e:	8082                	ret
      exit(-1);
    80002f70:	557d                	li	a0,-1
    80002f72:	fffff097          	auipc	ra,0xfffff
    80002f76:	41e080e7          	jalr	1054(ra) # 80002390 <exit>
    80002f7a:	b765                	j	80002f22 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f7c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002f80:	5890                	lw	a2,48(s1)
    80002f82:	00005517          	auipc	a0,0x5
    80002f86:	4d650513          	addi	a0,a0,1238 # 80008458 <states.0+0x120>
    80002f8a:	ffffd097          	auipc	ra,0xffffd
    80002f8e:	5fe080e7          	jalr	1534(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f92:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f96:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f9a:	00005517          	auipc	a0,0x5
    80002f9e:	42650513          	addi	a0,a0,1062 # 800083c0 <states.0+0x88>
    80002fa2:	ffffd097          	auipc	ra,0xffffd
    80002fa6:	5e6080e7          	jalr	1510(ra) # 80000588 <printf>
    setkilled(p);
    80002faa:	8526                	mv	a0,s1
    80002fac:	fffff097          	auipc	ra,0xfffff
    80002fb0:	542080e7          	jalr	1346(ra) # 800024ee <setkilled>
    80002fb4:	b769                	j	80002f3e <usertrap+0x8e>
    yield();
    80002fb6:	fffff097          	auipc	ra,0xfffff
    80002fba:	26a080e7          	jalr	618(ra) # 80002220 <yield>
    80002fbe:	bf79                	j	80002f5c <usertrap+0xac>

0000000080002fc0 <kerneltrap>:
{
    80002fc0:	7179                	addi	sp,sp,-48
    80002fc2:	f406                	sd	ra,40(sp)
    80002fc4:	f022                	sd	s0,32(sp)
    80002fc6:	ec26                	sd	s1,24(sp)
    80002fc8:	e84a                	sd	s2,16(sp)
    80002fca:	e44e                	sd	s3,8(sp)
    80002fcc:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fce:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fd2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002fd6:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002fda:	1004f793          	andi	a5,s1,256
    80002fde:	cb85                	beqz	a5,8000300e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fe0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002fe4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002fe6:	ef85                	bnez	a5,8000301e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002fe8:	00000097          	auipc	ra,0x0
    80002fec:	caa080e7          	jalr	-854(ra) # 80002c92 <devintr>
    80002ff0:	cd1d                	beqz	a0,8000302e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ff2:	4789                	li	a5,2
    80002ff4:	06f50a63          	beq	a0,a5,80003068 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ff8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ffc:	10049073          	csrw	sstatus,s1
}
    80003000:	70a2                	ld	ra,40(sp)
    80003002:	7402                	ld	s0,32(sp)
    80003004:	64e2                	ld	s1,24(sp)
    80003006:	6942                	ld	s2,16(sp)
    80003008:	69a2                	ld	s3,8(sp)
    8000300a:	6145                	addi	sp,sp,48
    8000300c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000300e:	00005517          	auipc	a0,0x5
    80003012:	47a50513          	addi	a0,a0,1146 # 80008488 <states.0+0x150>
    80003016:	ffffd097          	auipc	ra,0xffffd
    8000301a:	528080e7          	jalr	1320(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    8000301e:	00005517          	auipc	a0,0x5
    80003022:	49250513          	addi	a0,a0,1170 # 800084b0 <states.0+0x178>
    80003026:	ffffd097          	auipc	ra,0xffffd
    8000302a:	518080e7          	jalr	1304(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    8000302e:	85ce                	mv	a1,s3
    80003030:	00005517          	auipc	a0,0x5
    80003034:	4a050513          	addi	a0,a0,1184 # 800084d0 <states.0+0x198>
    80003038:	ffffd097          	auipc	ra,0xffffd
    8000303c:	550080e7          	jalr	1360(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003040:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003044:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003048:	00005517          	auipc	a0,0x5
    8000304c:	49850513          	addi	a0,a0,1176 # 800084e0 <states.0+0x1a8>
    80003050:	ffffd097          	auipc	ra,0xffffd
    80003054:	538080e7          	jalr	1336(ra) # 80000588 <printf>
    panic("kerneltrap");
    80003058:	00005517          	auipc	a0,0x5
    8000305c:	4a050513          	addi	a0,a0,1184 # 800084f8 <states.0+0x1c0>
    80003060:	ffffd097          	auipc	ra,0xffffd
    80003064:	4de080e7          	jalr	1246(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003068:	fffff097          	auipc	ra,0xfffff
    8000306c:	a9a080e7          	jalr	-1382(ra) # 80001b02 <myproc>
    80003070:	d541                	beqz	a0,80002ff8 <kerneltrap+0x38>
    80003072:	fffff097          	auipc	ra,0xfffff
    80003076:	a90080e7          	jalr	-1392(ra) # 80001b02 <myproc>
    8000307a:	4d18                	lw	a4,24(a0)
    8000307c:	4791                	li	a5,4
    8000307e:	f6f71de3          	bne	a4,a5,80002ff8 <kerneltrap+0x38>
    yield();
    80003082:	fffff097          	auipc	ra,0xfffff
    80003086:	19e080e7          	jalr	414(ra) # 80002220 <yield>
    8000308a:	b7bd                	j	80002ff8 <kerneltrap+0x38>

000000008000308c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000308c:	1101                	addi	sp,sp,-32
    8000308e:	ec06                	sd	ra,24(sp)
    80003090:	e822                	sd	s0,16(sp)
    80003092:	e426                	sd	s1,8(sp)
    80003094:	1000                	addi	s0,sp,32
    80003096:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003098:	fffff097          	auipc	ra,0xfffff
    8000309c:	a6a080e7          	jalr	-1430(ra) # 80001b02 <myproc>
  switch (n) {
    800030a0:	4795                	li	a5,5
    800030a2:	0497e163          	bltu	a5,s1,800030e4 <argraw+0x58>
    800030a6:	048a                	slli	s1,s1,0x2
    800030a8:	00005717          	auipc	a4,0x5
    800030ac:	48870713          	addi	a4,a4,1160 # 80008530 <states.0+0x1f8>
    800030b0:	94ba                	add	s1,s1,a4
    800030b2:	409c                	lw	a5,0(s1)
    800030b4:	97ba                	add	a5,a5,a4
    800030b6:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800030b8:	6d3c                	ld	a5,88(a0)
    800030ba:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800030bc:	60e2                	ld	ra,24(sp)
    800030be:	6442                	ld	s0,16(sp)
    800030c0:	64a2                	ld	s1,8(sp)
    800030c2:	6105                	addi	sp,sp,32
    800030c4:	8082                	ret
    return p->trapframe->a1;
    800030c6:	6d3c                	ld	a5,88(a0)
    800030c8:	7fa8                	ld	a0,120(a5)
    800030ca:	bfcd                	j	800030bc <argraw+0x30>
    return p->trapframe->a2;
    800030cc:	6d3c                	ld	a5,88(a0)
    800030ce:	63c8                	ld	a0,128(a5)
    800030d0:	b7f5                	j	800030bc <argraw+0x30>
    return p->trapframe->a3;
    800030d2:	6d3c                	ld	a5,88(a0)
    800030d4:	67c8                	ld	a0,136(a5)
    800030d6:	b7dd                	j	800030bc <argraw+0x30>
    return p->trapframe->a4;
    800030d8:	6d3c                	ld	a5,88(a0)
    800030da:	6bc8                	ld	a0,144(a5)
    800030dc:	b7c5                	j	800030bc <argraw+0x30>
    return p->trapframe->a5;
    800030de:	6d3c                	ld	a5,88(a0)
    800030e0:	6fc8                	ld	a0,152(a5)
    800030e2:	bfe9                	j	800030bc <argraw+0x30>
  panic("argraw");
    800030e4:	00005517          	auipc	a0,0x5
    800030e8:	42450513          	addi	a0,a0,1060 # 80008508 <states.0+0x1d0>
    800030ec:	ffffd097          	auipc	ra,0xffffd
    800030f0:	452080e7          	jalr	1106(ra) # 8000053e <panic>

00000000800030f4 <fetchaddr>:
{
    800030f4:	1101                	addi	sp,sp,-32
    800030f6:	ec06                	sd	ra,24(sp)
    800030f8:	e822                	sd	s0,16(sp)
    800030fa:	e426                	sd	s1,8(sp)
    800030fc:	e04a                	sd	s2,0(sp)
    800030fe:	1000                	addi	s0,sp,32
    80003100:	84aa                	mv	s1,a0
    80003102:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003104:	fffff097          	auipc	ra,0xfffff
    80003108:	9fe080e7          	jalr	-1538(ra) # 80001b02 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    8000310c:	653c                	ld	a5,72(a0)
    8000310e:	02f4f863          	bgeu	s1,a5,8000313e <fetchaddr+0x4a>
    80003112:	00848713          	addi	a4,s1,8
    80003116:	02e7e663          	bltu	a5,a4,80003142 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000311a:	46a1                	li	a3,8
    8000311c:	8626                	mv	a2,s1
    8000311e:	85ca                	mv	a1,s2
    80003120:	6928                	ld	a0,80(a0)
    80003122:	ffffe097          	auipc	ra,0xffffe
    80003126:	728080e7          	jalr	1832(ra) # 8000184a <copyin>
    8000312a:	00a03533          	snez	a0,a0
    8000312e:	40a00533          	neg	a0,a0
}
    80003132:	60e2                	ld	ra,24(sp)
    80003134:	6442                	ld	s0,16(sp)
    80003136:	64a2                	ld	s1,8(sp)
    80003138:	6902                	ld	s2,0(sp)
    8000313a:	6105                	addi	sp,sp,32
    8000313c:	8082                	ret
    return -1;
    8000313e:	557d                	li	a0,-1
    80003140:	bfcd                	j	80003132 <fetchaddr+0x3e>
    80003142:	557d                	li	a0,-1
    80003144:	b7fd                	j	80003132 <fetchaddr+0x3e>

0000000080003146 <fetchstr>:
{
    80003146:	7179                	addi	sp,sp,-48
    80003148:	f406                	sd	ra,40(sp)
    8000314a:	f022                	sd	s0,32(sp)
    8000314c:	ec26                	sd	s1,24(sp)
    8000314e:	e84a                	sd	s2,16(sp)
    80003150:	e44e                	sd	s3,8(sp)
    80003152:	1800                	addi	s0,sp,48
    80003154:	892a                	mv	s2,a0
    80003156:	84ae                	mv	s1,a1
    80003158:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000315a:	fffff097          	auipc	ra,0xfffff
    8000315e:	9a8080e7          	jalr	-1624(ra) # 80001b02 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80003162:	86ce                	mv	a3,s3
    80003164:	864a                	mv	a2,s2
    80003166:	85a6                	mv	a1,s1
    80003168:	6928                	ld	a0,80(a0)
    8000316a:	ffffe097          	auipc	ra,0xffffe
    8000316e:	76e080e7          	jalr	1902(ra) # 800018d8 <copyinstr>
    80003172:	00054e63          	bltz	a0,8000318e <fetchstr+0x48>
  return strlen(buf);
    80003176:	8526                	mv	a0,s1
    80003178:	ffffe097          	auipc	ra,0xffffe
    8000317c:	cd6080e7          	jalr	-810(ra) # 80000e4e <strlen>
}
    80003180:	70a2                	ld	ra,40(sp)
    80003182:	7402                	ld	s0,32(sp)
    80003184:	64e2                	ld	s1,24(sp)
    80003186:	6942                	ld	s2,16(sp)
    80003188:	69a2                	ld	s3,8(sp)
    8000318a:	6145                	addi	sp,sp,48
    8000318c:	8082                	ret
    return -1;
    8000318e:	557d                	li	a0,-1
    80003190:	bfc5                	j	80003180 <fetchstr+0x3a>

0000000080003192 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80003192:	1101                	addi	sp,sp,-32
    80003194:	ec06                	sd	ra,24(sp)
    80003196:	e822                	sd	s0,16(sp)
    80003198:	e426                	sd	s1,8(sp)
    8000319a:	1000                	addi	s0,sp,32
    8000319c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000319e:	00000097          	auipc	ra,0x0
    800031a2:	eee080e7          	jalr	-274(ra) # 8000308c <argraw>
    800031a6:	c088                	sw	a0,0(s1)
}
    800031a8:	60e2                	ld	ra,24(sp)
    800031aa:	6442                	ld	s0,16(sp)
    800031ac:	64a2                	ld	s1,8(sp)
    800031ae:	6105                	addi	sp,sp,32
    800031b0:	8082                	ret

00000000800031b2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    800031b2:	1101                	addi	sp,sp,-32
    800031b4:	ec06                	sd	ra,24(sp)
    800031b6:	e822                	sd	s0,16(sp)
    800031b8:	e426                	sd	s1,8(sp)
    800031ba:	1000                	addi	s0,sp,32
    800031bc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800031be:	00000097          	auipc	ra,0x0
    800031c2:	ece080e7          	jalr	-306(ra) # 8000308c <argraw>
    800031c6:	e088                	sd	a0,0(s1)
}
    800031c8:	60e2                	ld	ra,24(sp)
    800031ca:	6442                	ld	s0,16(sp)
    800031cc:	64a2                	ld	s1,8(sp)
    800031ce:	6105                	addi	sp,sp,32
    800031d0:	8082                	ret

00000000800031d2 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800031d2:	7179                	addi	sp,sp,-48
    800031d4:	f406                	sd	ra,40(sp)
    800031d6:	f022                	sd	s0,32(sp)
    800031d8:	ec26                	sd	s1,24(sp)
    800031da:	e84a                	sd	s2,16(sp)
    800031dc:	1800                	addi	s0,sp,48
    800031de:	84ae                	mv	s1,a1
    800031e0:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800031e2:	fd840593          	addi	a1,s0,-40
    800031e6:	00000097          	auipc	ra,0x0
    800031ea:	fcc080e7          	jalr	-52(ra) # 800031b2 <argaddr>
  return fetchstr(addr, buf, max);
    800031ee:	864a                	mv	a2,s2
    800031f0:	85a6                	mv	a1,s1
    800031f2:	fd843503          	ld	a0,-40(s0)
    800031f6:	00000097          	auipc	ra,0x0
    800031fa:	f50080e7          	jalr	-176(ra) # 80003146 <fetchstr>
}
    800031fe:	70a2                	ld	ra,40(sp)
    80003200:	7402                	ld	s0,32(sp)
    80003202:	64e2                	ld	s1,24(sp)
    80003204:	6942                	ld	s2,16(sp)
    80003206:	6145                	addi	sp,sp,48
    80003208:	8082                	ret

000000008000320a <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    8000320a:	1101                	addi	sp,sp,-32
    8000320c:	ec06                	sd	ra,24(sp)
    8000320e:	e822                	sd	s0,16(sp)
    80003210:	e426                	sd	s1,8(sp)
    80003212:	e04a                	sd	s2,0(sp)
    80003214:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003216:	fffff097          	auipc	ra,0xfffff
    8000321a:	8ec080e7          	jalr	-1812(ra) # 80001b02 <myproc>
    8000321e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003220:	05853903          	ld	s2,88(a0)
    80003224:	0a893783          	ld	a5,168(s2)
    80003228:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000322c:	37fd                	addiw	a5,a5,-1
    8000322e:	4751                	li	a4,20
    80003230:	00f76f63          	bltu	a4,a5,8000324e <syscall+0x44>
    80003234:	00369713          	slli	a4,a3,0x3
    80003238:	00005797          	auipc	a5,0x5
    8000323c:	31078793          	addi	a5,a5,784 # 80008548 <syscalls>
    80003240:	97ba                	add	a5,a5,a4
    80003242:	639c                	ld	a5,0(a5)
    80003244:	c789                	beqz	a5,8000324e <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80003246:	9782                	jalr	a5
    80003248:	06a93823          	sd	a0,112(s2)
    8000324c:	a839                	j	8000326a <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000324e:	15848613          	addi	a2,s1,344
    80003252:	588c                	lw	a1,48(s1)
    80003254:	00005517          	auipc	a0,0x5
    80003258:	2bc50513          	addi	a0,a0,700 # 80008510 <states.0+0x1d8>
    8000325c:	ffffd097          	auipc	ra,0xffffd
    80003260:	32c080e7          	jalr	812(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003264:	6cbc                	ld	a5,88(s1)
    80003266:	577d                	li	a4,-1
    80003268:	fbb8                	sd	a4,112(a5)
  }
}
    8000326a:	60e2                	ld	ra,24(sp)
    8000326c:	6442                	ld	s0,16(sp)
    8000326e:	64a2                	ld	s1,8(sp)
    80003270:	6902                	ld	s2,0(sp)
    80003272:	6105                	addi	sp,sp,32
    80003274:	8082                	ret

0000000080003276 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003276:	1101                	addi	sp,sp,-32
    80003278:	ec06                	sd	ra,24(sp)
    8000327a:	e822                	sd	s0,16(sp)
    8000327c:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    8000327e:	fec40593          	addi	a1,s0,-20
    80003282:	4501                	li	a0,0
    80003284:	00000097          	auipc	ra,0x0
    80003288:	f0e080e7          	jalr	-242(ra) # 80003192 <argint>
  exit(n);
    8000328c:	fec42503          	lw	a0,-20(s0)
    80003290:	fffff097          	auipc	ra,0xfffff
    80003294:	100080e7          	jalr	256(ra) # 80002390 <exit>
  return 0;  // not reached
}
    80003298:	4501                	li	a0,0
    8000329a:	60e2                	ld	ra,24(sp)
    8000329c:	6442                	ld	s0,16(sp)
    8000329e:	6105                	addi	sp,sp,32
    800032a0:	8082                	ret

00000000800032a2 <sys_getpid>:

uint64
sys_getpid(void)
{
    800032a2:	1141                	addi	sp,sp,-16
    800032a4:	e406                	sd	ra,8(sp)
    800032a6:	e022                	sd	s0,0(sp)
    800032a8:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800032aa:	fffff097          	auipc	ra,0xfffff
    800032ae:	858080e7          	jalr	-1960(ra) # 80001b02 <myproc>
}
    800032b2:	5908                	lw	a0,48(a0)
    800032b4:	60a2                	ld	ra,8(sp)
    800032b6:	6402                	ld	s0,0(sp)
    800032b8:	0141                	addi	sp,sp,16
    800032ba:	8082                	ret

00000000800032bc <sys_fork>:

uint64
sys_fork(void)
{
    800032bc:	1141                	addi	sp,sp,-16
    800032be:	e406                	sd	ra,8(sp)
    800032c0:	e022                	sd	s0,0(sp)
    800032c2:	0800                	addi	s0,sp,16
  return fork();
    800032c4:	fffff097          	auipc	ra,0xfffff
    800032c8:	c04080e7          	jalr	-1020(ra) # 80001ec8 <fork>
}
    800032cc:	60a2                	ld	ra,8(sp)
    800032ce:	6402                	ld	s0,0(sp)
    800032d0:	0141                	addi	sp,sp,16
    800032d2:	8082                	ret

00000000800032d4 <sys_wait>:

uint64
sys_wait(void)
{
    800032d4:	1101                	addi	sp,sp,-32
    800032d6:	ec06                	sd	ra,24(sp)
    800032d8:	e822                	sd	s0,16(sp)
    800032da:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    800032dc:	fe840593          	addi	a1,s0,-24
    800032e0:	4501                	li	a0,0
    800032e2:	00000097          	auipc	ra,0x0
    800032e6:	ed0080e7          	jalr	-304(ra) # 800031b2 <argaddr>
  return wait(p);
    800032ea:	fe843503          	ld	a0,-24(s0)
    800032ee:	fffff097          	auipc	ra,0xfffff
    800032f2:	25e080e7          	jalr	606(ra) # 8000254c <wait>
}
    800032f6:	60e2                	ld	ra,24(sp)
    800032f8:	6442                	ld	s0,16(sp)
    800032fa:	6105                	addi	sp,sp,32
    800032fc:	8082                	ret

00000000800032fe <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800032fe:	7179                	addi	sp,sp,-48
    80003300:	f406                	sd	ra,40(sp)
    80003302:	f022                	sd	s0,32(sp)
    80003304:	ec26                	sd	s1,24(sp)
    80003306:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003308:	fdc40593          	addi	a1,s0,-36
    8000330c:	4501                	li	a0,0
    8000330e:	00000097          	auipc	ra,0x0
    80003312:	e84080e7          	jalr	-380(ra) # 80003192 <argint>
  addr = myproc()->sz;
    80003316:	ffffe097          	auipc	ra,0xffffe
    8000331a:	7ec080e7          	jalr	2028(ra) # 80001b02 <myproc>
    8000331e:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80003320:	fdc42503          	lw	a0,-36(s0)
    80003324:	fffff097          	auipc	ra,0xfffff
    80003328:	b48080e7          	jalr	-1208(ra) # 80001e6c <growproc>
    8000332c:	00054863          	bltz	a0,8000333c <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80003330:	8526                	mv	a0,s1
    80003332:	70a2                	ld	ra,40(sp)
    80003334:	7402                	ld	s0,32(sp)
    80003336:	64e2                	ld	s1,24(sp)
    80003338:	6145                	addi	sp,sp,48
    8000333a:	8082                	ret
    return -1;
    8000333c:	54fd                	li	s1,-1
    8000333e:	bfcd                	j	80003330 <sys_sbrk+0x32>

0000000080003340 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003340:	7139                	addi	sp,sp,-64
    80003342:	fc06                	sd	ra,56(sp)
    80003344:	f822                	sd	s0,48(sp)
    80003346:	f426                	sd	s1,40(sp)
    80003348:	f04a                	sd	s2,32(sp)
    8000334a:	ec4e                	sd	s3,24(sp)
    8000334c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    8000334e:	fcc40593          	addi	a1,s0,-52
    80003352:	4501                	li	a0,0
    80003354:	00000097          	auipc	ra,0x0
    80003358:	e3e080e7          	jalr	-450(ra) # 80003192 <argint>
  acquire(&tickslock);
    8000335c:	00028517          	auipc	a0,0x28
    80003360:	f9450513          	addi	a0,a0,-108 # 8002b2f0 <tickslock>
    80003364:	ffffe097          	auipc	ra,0xffffe
    80003368:	872080e7          	jalr	-1934(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    8000336c:	00005917          	auipc	s2,0x5
    80003370:	6e492903          	lw	s2,1764(s2) # 80008a50 <ticks>
  while(ticks - ticks0 < n){
    80003374:	fcc42783          	lw	a5,-52(s0)
    80003378:	cf9d                	beqz	a5,800033b6 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000337a:	00028997          	auipc	s3,0x28
    8000337e:	f7698993          	addi	s3,s3,-138 # 8002b2f0 <tickslock>
    80003382:	00005497          	auipc	s1,0x5
    80003386:	6ce48493          	addi	s1,s1,1742 # 80008a50 <ticks>
    if(killed(myproc())){
    8000338a:	ffffe097          	auipc	ra,0xffffe
    8000338e:	778080e7          	jalr	1912(ra) # 80001b02 <myproc>
    80003392:	fffff097          	auipc	ra,0xfffff
    80003396:	188080e7          	jalr	392(ra) # 8000251a <killed>
    8000339a:	ed15                	bnez	a0,800033d6 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    8000339c:	85ce                	mv	a1,s3
    8000339e:	8526                	mv	a0,s1
    800033a0:	fffff097          	auipc	ra,0xfffff
    800033a4:	ebc080e7          	jalr	-324(ra) # 8000225c <sleep>
  while(ticks - ticks0 < n){
    800033a8:	409c                	lw	a5,0(s1)
    800033aa:	412787bb          	subw	a5,a5,s2
    800033ae:	fcc42703          	lw	a4,-52(s0)
    800033b2:	fce7ece3          	bltu	a5,a4,8000338a <sys_sleep+0x4a>
  }
  release(&tickslock);
    800033b6:	00028517          	auipc	a0,0x28
    800033ba:	f3a50513          	addi	a0,a0,-198 # 8002b2f0 <tickslock>
    800033be:	ffffe097          	auipc	ra,0xffffe
    800033c2:	8cc080e7          	jalr	-1844(ra) # 80000c8a <release>
  return 0;
    800033c6:	4501                	li	a0,0
}
    800033c8:	70e2                	ld	ra,56(sp)
    800033ca:	7442                	ld	s0,48(sp)
    800033cc:	74a2                	ld	s1,40(sp)
    800033ce:	7902                	ld	s2,32(sp)
    800033d0:	69e2                	ld	s3,24(sp)
    800033d2:	6121                	addi	sp,sp,64
    800033d4:	8082                	ret
      release(&tickslock);
    800033d6:	00028517          	auipc	a0,0x28
    800033da:	f1a50513          	addi	a0,a0,-230 # 8002b2f0 <tickslock>
    800033de:	ffffe097          	auipc	ra,0xffffe
    800033e2:	8ac080e7          	jalr	-1876(ra) # 80000c8a <release>
      return -1;
    800033e6:	557d                	li	a0,-1
    800033e8:	b7c5                	j	800033c8 <sys_sleep+0x88>

00000000800033ea <sys_kill>:

uint64
sys_kill(void)
{
    800033ea:	1101                	addi	sp,sp,-32
    800033ec:	ec06                	sd	ra,24(sp)
    800033ee:	e822                	sd	s0,16(sp)
    800033f0:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    800033f2:	fec40593          	addi	a1,s0,-20
    800033f6:	4501                	li	a0,0
    800033f8:	00000097          	auipc	ra,0x0
    800033fc:	d9a080e7          	jalr	-614(ra) # 80003192 <argint>
  return kill(pid);
    80003400:	fec42503          	lw	a0,-20(s0)
    80003404:	fffff097          	auipc	ra,0xfffff
    80003408:	078080e7          	jalr	120(ra) # 8000247c <kill>
}
    8000340c:	60e2                	ld	ra,24(sp)
    8000340e:	6442                	ld	s0,16(sp)
    80003410:	6105                	addi	sp,sp,32
    80003412:	8082                	ret

0000000080003414 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003414:	1101                	addi	sp,sp,-32
    80003416:	ec06                	sd	ra,24(sp)
    80003418:	e822                	sd	s0,16(sp)
    8000341a:	e426                	sd	s1,8(sp)
    8000341c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000341e:	00028517          	auipc	a0,0x28
    80003422:	ed250513          	addi	a0,a0,-302 # 8002b2f0 <tickslock>
    80003426:	ffffd097          	auipc	ra,0xffffd
    8000342a:	7b0080e7          	jalr	1968(ra) # 80000bd6 <acquire>
  xticks = ticks;
    8000342e:	00005497          	auipc	s1,0x5
    80003432:	6224a483          	lw	s1,1570(s1) # 80008a50 <ticks>
  release(&tickslock);
    80003436:	00028517          	auipc	a0,0x28
    8000343a:	eba50513          	addi	a0,a0,-326 # 8002b2f0 <tickslock>
    8000343e:	ffffe097          	auipc	ra,0xffffe
    80003442:	84c080e7          	jalr	-1972(ra) # 80000c8a <release>
  return xticks;
}
    80003446:	02049513          	slli	a0,s1,0x20
    8000344a:	9101                	srli	a0,a0,0x20
    8000344c:	60e2                	ld	ra,24(sp)
    8000344e:	6442                	ld	s0,16(sp)
    80003450:	64a2                	ld	s1,8(sp)
    80003452:	6105                	addi	sp,sp,32
    80003454:	8082                	ret

0000000080003456 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003456:	7179                	addi	sp,sp,-48
    80003458:	f406                	sd	ra,40(sp)
    8000345a:	f022                	sd	s0,32(sp)
    8000345c:	ec26                	sd	s1,24(sp)
    8000345e:	e84a                	sd	s2,16(sp)
    80003460:	e44e                	sd	s3,8(sp)
    80003462:	e052                	sd	s4,0(sp)
    80003464:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003466:	00005597          	auipc	a1,0x5
    8000346a:	19258593          	addi	a1,a1,402 # 800085f8 <syscalls+0xb0>
    8000346e:	00028517          	auipc	a0,0x28
    80003472:	e9a50513          	addi	a0,a0,-358 # 8002b308 <bcache>
    80003476:	ffffd097          	auipc	ra,0xffffd
    8000347a:	6d0080e7          	jalr	1744(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000347e:	00030797          	auipc	a5,0x30
    80003482:	e8a78793          	addi	a5,a5,-374 # 80033308 <bcache+0x8000>
    80003486:	00030717          	auipc	a4,0x30
    8000348a:	0ea70713          	addi	a4,a4,234 # 80033570 <bcache+0x8268>
    8000348e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003492:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003496:	00028497          	auipc	s1,0x28
    8000349a:	e8a48493          	addi	s1,s1,-374 # 8002b320 <bcache+0x18>
    b->next = bcache.head.next;
    8000349e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800034a0:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800034a2:	00005a17          	auipc	s4,0x5
    800034a6:	15ea0a13          	addi	s4,s4,350 # 80008600 <syscalls+0xb8>
    b->next = bcache.head.next;
    800034aa:	2b893783          	ld	a5,696(s2)
    800034ae:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800034b0:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800034b4:	85d2                	mv	a1,s4
    800034b6:	01048513          	addi	a0,s1,16
    800034ba:	00002097          	auipc	ra,0x2
    800034be:	812080e7          	jalr	-2030(ra) # 80004ccc <initsleeplock>
    bcache.head.next->prev = b;
    800034c2:	2b893783          	ld	a5,696(s2)
    800034c6:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800034c8:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034cc:	45848493          	addi	s1,s1,1112
    800034d0:	fd349de3          	bne	s1,s3,800034aa <binit+0x54>
  }
}
    800034d4:	70a2                	ld	ra,40(sp)
    800034d6:	7402                	ld	s0,32(sp)
    800034d8:	64e2                	ld	s1,24(sp)
    800034da:	6942                	ld	s2,16(sp)
    800034dc:	69a2                	ld	s3,8(sp)
    800034de:	6a02                	ld	s4,0(sp)
    800034e0:	6145                	addi	sp,sp,48
    800034e2:	8082                	ret

00000000800034e4 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800034e4:	7179                	addi	sp,sp,-48
    800034e6:	f406                	sd	ra,40(sp)
    800034e8:	f022                	sd	s0,32(sp)
    800034ea:	ec26                	sd	s1,24(sp)
    800034ec:	e84a                	sd	s2,16(sp)
    800034ee:	e44e                	sd	s3,8(sp)
    800034f0:	1800                	addi	s0,sp,48
    800034f2:	892a                	mv	s2,a0
    800034f4:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800034f6:	00028517          	auipc	a0,0x28
    800034fa:	e1250513          	addi	a0,a0,-494 # 8002b308 <bcache>
    800034fe:	ffffd097          	auipc	ra,0xffffd
    80003502:	6d8080e7          	jalr	1752(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003506:	00030497          	auipc	s1,0x30
    8000350a:	0ba4b483          	ld	s1,186(s1) # 800335c0 <bcache+0x82b8>
    8000350e:	00030797          	auipc	a5,0x30
    80003512:	06278793          	addi	a5,a5,98 # 80033570 <bcache+0x8268>
    80003516:	02f48f63          	beq	s1,a5,80003554 <bread+0x70>
    8000351a:	873e                	mv	a4,a5
    8000351c:	a021                	j	80003524 <bread+0x40>
    8000351e:	68a4                	ld	s1,80(s1)
    80003520:	02e48a63          	beq	s1,a4,80003554 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003524:	449c                	lw	a5,8(s1)
    80003526:	ff279ce3          	bne	a5,s2,8000351e <bread+0x3a>
    8000352a:	44dc                	lw	a5,12(s1)
    8000352c:	ff3799e3          	bne	a5,s3,8000351e <bread+0x3a>
      b->refcnt++;
    80003530:	40bc                	lw	a5,64(s1)
    80003532:	2785                	addiw	a5,a5,1
    80003534:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003536:	00028517          	auipc	a0,0x28
    8000353a:	dd250513          	addi	a0,a0,-558 # 8002b308 <bcache>
    8000353e:	ffffd097          	auipc	ra,0xffffd
    80003542:	74c080e7          	jalr	1868(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003546:	01048513          	addi	a0,s1,16
    8000354a:	00001097          	auipc	ra,0x1
    8000354e:	7bc080e7          	jalr	1980(ra) # 80004d06 <acquiresleep>
      return b;
    80003552:	a8b9                	j	800035b0 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003554:	00030497          	auipc	s1,0x30
    80003558:	0644b483          	ld	s1,100(s1) # 800335b8 <bcache+0x82b0>
    8000355c:	00030797          	auipc	a5,0x30
    80003560:	01478793          	addi	a5,a5,20 # 80033570 <bcache+0x8268>
    80003564:	00f48863          	beq	s1,a5,80003574 <bread+0x90>
    80003568:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000356a:	40bc                	lw	a5,64(s1)
    8000356c:	cf81                	beqz	a5,80003584 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000356e:	64a4                	ld	s1,72(s1)
    80003570:	fee49de3          	bne	s1,a4,8000356a <bread+0x86>
  panic("bget: no buffers");
    80003574:	00005517          	auipc	a0,0x5
    80003578:	09450513          	addi	a0,a0,148 # 80008608 <syscalls+0xc0>
    8000357c:	ffffd097          	auipc	ra,0xffffd
    80003580:	fc2080e7          	jalr	-62(ra) # 8000053e <panic>
      b->dev = dev;
    80003584:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003588:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000358c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003590:	4785                	li	a5,1
    80003592:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003594:	00028517          	auipc	a0,0x28
    80003598:	d7450513          	addi	a0,a0,-652 # 8002b308 <bcache>
    8000359c:	ffffd097          	auipc	ra,0xffffd
    800035a0:	6ee080e7          	jalr	1774(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800035a4:	01048513          	addi	a0,s1,16
    800035a8:	00001097          	auipc	ra,0x1
    800035ac:	75e080e7          	jalr	1886(ra) # 80004d06 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800035b0:	409c                	lw	a5,0(s1)
    800035b2:	cb89                	beqz	a5,800035c4 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800035b4:	8526                	mv	a0,s1
    800035b6:	70a2                	ld	ra,40(sp)
    800035b8:	7402                	ld	s0,32(sp)
    800035ba:	64e2                	ld	s1,24(sp)
    800035bc:	6942                	ld	s2,16(sp)
    800035be:	69a2                	ld	s3,8(sp)
    800035c0:	6145                	addi	sp,sp,48
    800035c2:	8082                	ret
    virtio_disk_rw(b, 0);
    800035c4:	4581                	li	a1,0
    800035c6:	8526                	mv	a0,s1
    800035c8:	00003097          	auipc	ra,0x3
    800035cc:	63c080e7          	jalr	1596(ra) # 80006c04 <virtio_disk_rw>
    b->valid = 1;
    800035d0:	4785                	li	a5,1
    800035d2:	c09c                	sw	a5,0(s1)
  return b;
    800035d4:	b7c5                	j	800035b4 <bread+0xd0>

00000000800035d6 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800035d6:	1101                	addi	sp,sp,-32
    800035d8:	ec06                	sd	ra,24(sp)
    800035da:	e822                	sd	s0,16(sp)
    800035dc:	e426                	sd	s1,8(sp)
    800035de:	1000                	addi	s0,sp,32
    800035e0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800035e2:	0541                	addi	a0,a0,16
    800035e4:	00001097          	auipc	ra,0x1
    800035e8:	7bc080e7          	jalr	1980(ra) # 80004da0 <holdingsleep>
    800035ec:	cd01                	beqz	a0,80003604 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800035ee:	4585                	li	a1,1
    800035f0:	8526                	mv	a0,s1
    800035f2:	00003097          	auipc	ra,0x3
    800035f6:	612080e7          	jalr	1554(ra) # 80006c04 <virtio_disk_rw>
}
    800035fa:	60e2                	ld	ra,24(sp)
    800035fc:	6442                	ld	s0,16(sp)
    800035fe:	64a2                	ld	s1,8(sp)
    80003600:	6105                	addi	sp,sp,32
    80003602:	8082                	ret
    panic("bwrite");
    80003604:	00005517          	auipc	a0,0x5
    80003608:	01c50513          	addi	a0,a0,28 # 80008620 <syscalls+0xd8>
    8000360c:	ffffd097          	auipc	ra,0xffffd
    80003610:	f32080e7          	jalr	-206(ra) # 8000053e <panic>

0000000080003614 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003614:	1101                	addi	sp,sp,-32
    80003616:	ec06                	sd	ra,24(sp)
    80003618:	e822                	sd	s0,16(sp)
    8000361a:	e426                	sd	s1,8(sp)
    8000361c:	e04a                	sd	s2,0(sp)
    8000361e:	1000                	addi	s0,sp,32
    80003620:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003622:	01050913          	addi	s2,a0,16
    80003626:	854a                	mv	a0,s2
    80003628:	00001097          	auipc	ra,0x1
    8000362c:	778080e7          	jalr	1912(ra) # 80004da0 <holdingsleep>
    80003630:	c92d                	beqz	a0,800036a2 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003632:	854a                	mv	a0,s2
    80003634:	00001097          	auipc	ra,0x1
    80003638:	728080e7          	jalr	1832(ra) # 80004d5c <releasesleep>

  acquire(&bcache.lock);
    8000363c:	00028517          	auipc	a0,0x28
    80003640:	ccc50513          	addi	a0,a0,-820 # 8002b308 <bcache>
    80003644:	ffffd097          	auipc	ra,0xffffd
    80003648:	592080e7          	jalr	1426(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000364c:	40bc                	lw	a5,64(s1)
    8000364e:	37fd                	addiw	a5,a5,-1
    80003650:	0007871b          	sext.w	a4,a5
    80003654:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003656:	eb05                	bnez	a4,80003686 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003658:	68bc                	ld	a5,80(s1)
    8000365a:	64b8                	ld	a4,72(s1)
    8000365c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000365e:	64bc                	ld	a5,72(s1)
    80003660:	68b8                	ld	a4,80(s1)
    80003662:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003664:	00030797          	auipc	a5,0x30
    80003668:	ca478793          	addi	a5,a5,-860 # 80033308 <bcache+0x8000>
    8000366c:	2b87b703          	ld	a4,696(a5)
    80003670:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003672:	00030717          	auipc	a4,0x30
    80003676:	efe70713          	addi	a4,a4,-258 # 80033570 <bcache+0x8268>
    8000367a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000367c:	2b87b703          	ld	a4,696(a5)
    80003680:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003682:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003686:	00028517          	auipc	a0,0x28
    8000368a:	c8250513          	addi	a0,a0,-894 # 8002b308 <bcache>
    8000368e:	ffffd097          	auipc	ra,0xffffd
    80003692:	5fc080e7          	jalr	1532(ra) # 80000c8a <release>
}
    80003696:	60e2                	ld	ra,24(sp)
    80003698:	6442                	ld	s0,16(sp)
    8000369a:	64a2                	ld	s1,8(sp)
    8000369c:	6902                	ld	s2,0(sp)
    8000369e:	6105                	addi	sp,sp,32
    800036a0:	8082                	ret
    panic("brelse");
    800036a2:	00005517          	auipc	a0,0x5
    800036a6:	f8650513          	addi	a0,a0,-122 # 80008628 <syscalls+0xe0>
    800036aa:	ffffd097          	auipc	ra,0xffffd
    800036ae:	e94080e7          	jalr	-364(ra) # 8000053e <panic>

00000000800036b2 <bpin>:

void
bpin(struct buf *b) {
    800036b2:	1101                	addi	sp,sp,-32
    800036b4:	ec06                	sd	ra,24(sp)
    800036b6:	e822                	sd	s0,16(sp)
    800036b8:	e426                	sd	s1,8(sp)
    800036ba:	1000                	addi	s0,sp,32
    800036bc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036be:	00028517          	auipc	a0,0x28
    800036c2:	c4a50513          	addi	a0,a0,-950 # 8002b308 <bcache>
    800036c6:	ffffd097          	auipc	ra,0xffffd
    800036ca:	510080e7          	jalr	1296(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800036ce:	40bc                	lw	a5,64(s1)
    800036d0:	2785                	addiw	a5,a5,1
    800036d2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036d4:	00028517          	auipc	a0,0x28
    800036d8:	c3450513          	addi	a0,a0,-972 # 8002b308 <bcache>
    800036dc:	ffffd097          	auipc	ra,0xffffd
    800036e0:	5ae080e7          	jalr	1454(ra) # 80000c8a <release>
}
    800036e4:	60e2                	ld	ra,24(sp)
    800036e6:	6442                	ld	s0,16(sp)
    800036e8:	64a2                	ld	s1,8(sp)
    800036ea:	6105                	addi	sp,sp,32
    800036ec:	8082                	ret

00000000800036ee <bunpin>:

void
bunpin(struct buf *b) {
    800036ee:	1101                	addi	sp,sp,-32
    800036f0:	ec06                	sd	ra,24(sp)
    800036f2:	e822                	sd	s0,16(sp)
    800036f4:	e426                	sd	s1,8(sp)
    800036f6:	1000                	addi	s0,sp,32
    800036f8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036fa:	00028517          	auipc	a0,0x28
    800036fe:	c0e50513          	addi	a0,a0,-1010 # 8002b308 <bcache>
    80003702:	ffffd097          	auipc	ra,0xffffd
    80003706:	4d4080e7          	jalr	1236(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000370a:	40bc                	lw	a5,64(s1)
    8000370c:	37fd                	addiw	a5,a5,-1
    8000370e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003710:	00028517          	auipc	a0,0x28
    80003714:	bf850513          	addi	a0,a0,-1032 # 8002b308 <bcache>
    80003718:	ffffd097          	auipc	ra,0xffffd
    8000371c:	572080e7          	jalr	1394(ra) # 80000c8a <release>
}
    80003720:	60e2                	ld	ra,24(sp)
    80003722:	6442                	ld	s0,16(sp)
    80003724:	64a2                	ld	s1,8(sp)
    80003726:	6105                	addi	sp,sp,32
    80003728:	8082                	ret

000000008000372a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000372a:	1101                	addi	sp,sp,-32
    8000372c:	ec06                	sd	ra,24(sp)
    8000372e:	e822                	sd	s0,16(sp)
    80003730:	e426                	sd	s1,8(sp)
    80003732:	e04a                	sd	s2,0(sp)
    80003734:	1000                	addi	s0,sp,32
    80003736:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003738:	00d5d59b          	srliw	a1,a1,0xd
    8000373c:	00030797          	auipc	a5,0x30
    80003740:	2a87a783          	lw	a5,680(a5) # 800339e4 <sb+0x1c>
    80003744:	9dbd                	addw	a1,a1,a5
    80003746:	00000097          	auipc	ra,0x0
    8000374a:	d9e080e7          	jalr	-610(ra) # 800034e4 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000374e:	0074f713          	andi	a4,s1,7
    80003752:	4785                	li	a5,1
    80003754:	00e797bb          	sllw	a5,a5,a4
  if ((bp->data[bi / 8] & m) == 0)
    80003758:	14ce                	slli	s1,s1,0x33
    8000375a:	90d9                	srli	s1,s1,0x36
    8000375c:	00950733          	add	a4,a0,s1
    80003760:	05874703          	lbu	a4,88(a4)
    80003764:	00e7f6b3          	and	a3,a5,a4
    80003768:	c69d                	beqz	a3,80003796 <bfree+0x6c>
    8000376a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi / 8] &= ~m;
    8000376c:	94aa                	add	s1,s1,a0
    8000376e:	fff7c793          	not	a5,a5
    80003772:	8ff9                	and	a5,a5,a4
    80003774:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003778:	00001097          	auipc	ra,0x1
    8000377c:	46e080e7          	jalr	1134(ra) # 80004be6 <log_write>
  brelse(bp);
    80003780:	854a                	mv	a0,s2
    80003782:	00000097          	auipc	ra,0x0
    80003786:	e92080e7          	jalr	-366(ra) # 80003614 <brelse>
}
    8000378a:	60e2                	ld	ra,24(sp)
    8000378c:	6442                	ld	s0,16(sp)
    8000378e:	64a2                	ld	s1,8(sp)
    80003790:	6902                	ld	s2,0(sp)
    80003792:	6105                	addi	sp,sp,32
    80003794:	8082                	ret
    panic("freeing free block");
    80003796:	00005517          	auipc	a0,0x5
    8000379a:	e9a50513          	addi	a0,a0,-358 # 80008630 <syscalls+0xe8>
    8000379e:	ffffd097          	auipc	ra,0xffffd
    800037a2:	da0080e7          	jalr	-608(ra) # 8000053e <panic>

00000000800037a6 <balloc>:
{
    800037a6:	711d                	addi	sp,sp,-96
    800037a8:	ec86                	sd	ra,88(sp)
    800037aa:	e8a2                	sd	s0,80(sp)
    800037ac:	e4a6                	sd	s1,72(sp)
    800037ae:	e0ca                	sd	s2,64(sp)
    800037b0:	fc4e                	sd	s3,56(sp)
    800037b2:	f852                	sd	s4,48(sp)
    800037b4:	f456                	sd	s5,40(sp)
    800037b6:	f05a                	sd	s6,32(sp)
    800037b8:	ec5e                	sd	s7,24(sp)
    800037ba:	e862                	sd	s8,16(sp)
    800037bc:	e466                	sd	s9,8(sp)
    800037be:	1080                	addi	s0,sp,96
  for (b = 0; b < sb.size; b += BPB)
    800037c0:	00030797          	auipc	a5,0x30
    800037c4:	20c7a783          	lw	a5,524(a5) # 800339cc <sb+0x4>
    800037c8:	10078163          	beqz	a5,800038ca <balloc+0x124>
    800037cc:	8baa                	mv	s7,a0
    800037ce:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800037d0:	00030b17          	auipc	s6,0x30
    800037d4:	1f8b0b13          	addi	s6,s6,504 # 800339c8 <sb>
    for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    800037d8:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800037da:	4985                	li	s3,1
    for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    800037dc:	6a09                	lui	s4,0x2
  for (b = 0; b < sb.size; b += BPB)
    800037de:	6c89                	lui	s9,0x2
    800037e0:	a061                	j	80003868 <balloc+0xc2>
        bp->data[bi / 8] |= m; // Mark block in use.
    800037e2:	974a                	add	a4,a4,s2
    800037e4:	8fd5                	or	a5,a5,a3
    800037e6:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800037ea:	854a                	mv	a0,s2
    800037ec:	00001097          	auipc	ra,0x1
    800037f0:	3fa080e7          	jalr	1018(ra) # 80004be6 <log_write>
        brelse(bp);
    800037f4:	854a                	mv	a0,s2
    800037f6:	00000097          	auipc	ra,0x0
    800037fa:	e1e080e7          	jalr	-482(ra) # 80003614 <brelse>
  bp = bread(dev, bno);
    800037fe:	85a6                	mv	a1,s1
    80003800:	855e                	mv	a0,s7
    80003802:	00000097          	auipc	ra,0x0
    80003806:	ce2080e7          	jalr	-798(ra) # 800034e4 <bread>
    8000380a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000380c:	40000613          	li	a2,1024
    80003810:	4581                	li	a1,0
    80003812:	05850513          	addi	a0,a0,88
    80003816:	ffffd097          	auipc	ra,0xffffd
    8000381a:	4bc080e7          	jalr	1212(ra) # 80000cd2 <memset>
  log_write(bp);
    8000381e:	854a                	mv	a0,s2
    80003820:	00001097          	auipc	ra,0x1
    80003824:	3c6080e7          	jalr	966(ra) # 80004be6 <log_write>
  brelse(bp);
    80003828:	854a                	mv	a0,s2
    8000382a:	00000097          	auipc	ra,0x0
    8000382e:	dea080e7          	jalr	-534(ra) # 80003614 <brelse>
}
    80003832:	8526                	mv	a0,s1
    80003834:	60e6                	ld	ra,88(sp)
    80003836:	6446                	ld	s0,80(sp)
    80003838:	64a6                	ld	s1,72(sp)
    8000383a:	6906                	ld	s2,64(sp)
    8000383c:	79e2                	ld	s3,56(sp)
    8000383e:	7a42                	ld	s4,48(sp)
    80003840:	7aa2                	ld	s5,40(sp)
    80003842:	7b02                	ld	s6,32(sp)
    80003844:	6be2                	ld	s7,24(sp)
    80003846:	6c42                	ld	s8,16(sp)
    80003848:	6ca2                	ld	s9,8(sp)
    8000384a:	6125                	addi	sp,sp,96
    8000384c:	8082                	ret
    brelse(bp);
    8000384e:	854a                	mv	a0,s2
    80003850:	00000097          	auipc	ra,0x0
    80003854:	dc4080e7          	jalr	-572(ra) # 80003614 <brelse>
  for (b = 0; b < sb.size; b += BPB)
    80003858:	015c87bb          	addw	a5,s9,s5
    8000385c:	00078a9b          	sext.w	s5,a5
    80003860:	004b2703          	lw	a4,4(s6)
    80003864:	06eaf363          	bgeu	s5,a4,800038ca <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003868:	41fad79b          	sraiw	a5,s5,0x1f
    8000386c:	0137d79b          	srliw	a5,a5,0x13
    80003870:	015787bb          	addw	a5,a5,s5
    80003874:	40d7d79b          	sraiw	a5,a5,0xd
    80003878:	01cb2583          	lw	a1,28(s6)
    8000387c:	9dbd                	addw	a1,a1,a5
    8000387e:	855e                	mv	a0,s7
    80003880:	00000097          	auipc	ra,0x0
    80003884:	c64080e7          	jalr	-924(ra) # 800034e4 <bread>
    80003888:	892a                	mv	s2,a0
    for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    8000388a:	004b2503          	lw	a0,4(s6)
    8000388e:	000a849b          	sext.w	s1,s5
    80003892:	8662                	mv	a2,s8
    80003894:	faa4fde3          	bgeu	s1,a0,8000384e <balloc+0xa8>
      m = 1 << (bi % 8);
    80003898:	41f6579b          	sraiw	a5,a2,0x1f
    8000389c:	01d7d69b          	srliw	a3,a5,0x1d
    800038a0:	00c6873b          	addw	a4,a3,a2
    800038a4:	00777793          	andi	a5,a4,7
    800038a8:	9f95                	subw	a5,a5,a3
    800038aa:	00f997bb          	sllw	a5,s3,a5
      if ((bp->data[bi / 8] & m) == 0)
    800038ae:	4037571b          	sraiw	a4,a4,0x3
    800038b2:	00e906b3          	add	a3,s2,a4
    800038b6:	0586c683          	lbu	a3,88(a3) # 1058 <_entry-0x7fffefa8>
    800038ba:	00d7f5b3          	and	a1,a5,a3
    800038be:	d195                	beqz	a1,800037e2 <balloc+0x3c>
    for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    800038c0:	2605                	addiw	a2,a2,1
    800038c2:	2485                	addiw	s1,s1,1
    800038c4:	fd4618e3          	bne	a2,s4,80003894 <balloc+0xee>
    800038c8:	b759                	j	8000384e <balloc+0xa8>
  printf("balloc: out of blocks\n");
    800038ca:	00005517          	auipc	a0,0x5
    800038ce:	d7e50513          	addi	a0,a0,-642 # 80008648 <syscalls+0x100>
    800038d2:	ffffd097          	auipc	ra,0xffffd
    800038d6:	cb6080e7          	jalr	-842(ra) # 80000588 <printf>
  return 0;
    800038da:	4481                	li	s1,0
    800038dc:	bf99                	j	80003832 <balloc+0x8c>

00000000800038de <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800038de:	7179                	addi	sp,sp,-48
    800038e0:	f406                	sd	ra,40(sp)
    800038e2:	f022                	sd	s0,32(sp)
    800038e4:	ec26                	sd	s1,24(sp)
    800038e6:	e84a                	sd	s2,16(sp)
    800038e8:	e44e                	sd	s3,8(sp)
    800038ea:	e052                	sd	s4,0(sp)
    800038ec:	1800                	addi	s0,sp,48
    800038ee:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if (bn < NDIRECT)
    800038f0:	47ad                	li	a5,11
    800038f2:	02b7e763          	bltu	a5,a1,80003920 <bmap+0x42>
  {
    if ((addr = ip->addrs[bn]) == 0)
    800038f6:	02059493          	slli	s1,a1,0x20
    800038fa:	9081                	srli	s1,s1,0x20
    800038fc:	048a                	slli	s1,s1,0x2
    800038fe:	94aa                	add	s1,s1,a0
    80003900:	0504a903          	lw	s2,80(s1)
    80003904:	06091e63          	bnez	s2,80003980 <bmap+0xa2>
    {
      addr = balloc(ip->dev);
    80003908:	4108                	lw	a0,0(a0)
    8000390a:	00000097          	auipc	ra,0x0
    8000390e:	e9c080e7          	jalr	-356(ra) # 800037a6 <balloc>
    80003912:	0005091b          	sext.w	s2,a0
      if (addr == 0)
    80003916:	06090563          	beqz	s2,80003980 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    8000391a:	0524a823          	sw	s2,80(s1)
    8000391e:	a08d                	j	80003980 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003920:	ff45849b          	addiw	s1,a1,-12
    80003924:	0004871b          	sext.w	a4,s1

  if (bn < NINDIRECT)
    80003928:	0ff00793          	li	a5,255
    8000392c:	08e7e563          	bltu	a5,a4,800039b6 <bmap+0xd8>
  {
    // Load indirect block, allocating if necessary.
    if ((addr = ip->addrs[NDIRECT]) == 0)
    80003930:	08052903          	lw	s2,128(a0)
    80003934:	00091d63          	bnez	s2,8000394e <bmap+0x70>
    {
      addr = balloc(ip->dev);
    80003938:	4108                	lw	a0,0(a0)
    8000393a:	00000097          	auipc	ra,0x0
    8000393e:	e6c080e7          	jalr	-404(ra) # 800037a6 <balloc>
    80003942:	0005091b          	sext.w	s2,a0
      if (addr == 0)
    80003946:	02090d63          	beqz	s2,80003980 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000394a:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000394e:	85ca                	mv	a1,s2
    80003950:	0009a503          	lw	a0,0(s3)
    80003954:	00000097          	auipc	ra,0x0
    80003958:	b90080e7          	jalr	-1136(ra) # 800034e4 <bread>
    8000395c:	8a2a                	mv	s4,a0
    a = (uint *)bp->data;
    8000395e:	05850793          	addi	a5,a0,88
    if ((addr = a[bn]) == 0)
    80003962:	02049593          	slli	a1,s1,0x20
    80003966:	9181                	srli	a1,a1,0x20
    80003968:	058a                	slli	a1,a1,0x2
    8000396a:	00b784b3          	add	s1,a5,a1
    8000396e:	0004a903          	lw	s2,0(s1)
    80003972:	02090063          	beqz	s2,80003992 <bmap+0xb4>
      {
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003976:	8552                	mv	a0,s4
    80003978:	00000097          	auipc	ra,0x0
    8000397c:	c9c080e7          	jalr	-868(ra) # 80003614 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003980:	854a                	mv	a0,s2
    80003982:	70a2                	ld	ra,40(sp)
    80003984:	7402                	ld	s0,32(sp)
    80003986:	64e2                	ld	s1,24(sp)
    80003988:	6942                	ld	s2,16(sp)
    8000398a:	69a2                	ld	s3,8(sp)
    8000398c:	6a02                	ld	s4,0(sp)
    8000398e:	6145                	addi	sp,sp,48
    80003990:	8082                	ret
      addr = balloc(ip->dev);
    80003992:	0009a503          	lw	a0,0(s3)
    80003996:	00000097          	auipc	ra,0x0
    8000399a:	e10080e7          	jalr	-496(ra) # 800037a6 <balloc>
    8000399e:	0005091b          	sext.w	s2,a0
      if (addr)
    800039a2:	fc090ae3          	beqz	s2,80003976 <bmap+0x98>
        a[bn] = addr;
    800039a6:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800039aa:	8552                	mv	a0,s4
    800039ac:	00001097          	auipc	ra,0x1
    800039b0:	23a080e7          	jalr	570(ra) # 80004be6 <log_write>
    800039b4:	b7c9                	j	80003976 <bmap+0x98>
  panic("bmap: out of range");
    800039b6:	00005517          	auipc	a0,0x5
    800039ba:	caa50513          	addi	a0,a0,-854 # 80008660 <syscalls+0x118>
    800039be:	ffffd097          	auipc	ra,0xffffd
    800039c2:	b80080e7          	jalr	-1152(ra) # 8000053e <panic>

00000000800039c6 <iget>:
{
    800039c6:	7179                	addi	sp,sp,-48
    800039c8:	f406                	sd	ra,40(sp)
    800039ca:	f022                	sd	s0,32(sp)
    800039cc:	ec26                	sd	s1,24(sp)
    800039ce:	e84a                	sd	s2,16(sp)
    800039d0:	e44e                	sd	s3,8(sp)
    800039d2:	e052                	sd	s4,0(sp)
    800039d4:	1800                	addi	s0,sp,48
    800039d6:	89aa                	mv	s3,a0
    800039d8:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800039da:	00030517          	auipc	a0,0x30
    800039de:	00e50513          	addi	a0,a0,14 # 800339e8 <itable>
    800039e2:	ffffd097          	auipc	ra,0xffffd
    800039e6:	1f4080e7          	jalr	500(ra) # 80000bd6 <acquire>
  empty = 0;
    800039ea:	4901                	li	s2,0
  for (ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++)
    800039ec:	00030497          	auipc	s1,0x30
    800039f0:	01448493          	addi	s1,s1,20 # 80033a00 <itable+0x18>
    800039f4:	00032697          	auipc	a3,0x32
    800039f8:	a9c68693          	addi	a3,a3,-1380 # 80035490 <log>
    800039fc:	a039                	j	80003a0a <iget+0x44>
    if (empty == 0 && ip->ref == 0) // Remember empty slot.
    800039fe:	02090b63          	beqz	s2,80003a34 <iget+0x6e>
  for (ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++)
    80003a02:	08848493          	addi	s1,s1,136
    80003a06:	02d48a63          	beq	s1,a3,80003a3a <iget+0x74>
    if (ip->ref > 0 && ip->dev == dev && ip->inum == inum)
    80003a0a:	449c                	lw	a5,8(s1)
    80003a0c:	fef059e3          	blez	a5,800039fe <iget+0x38>
    80003a10:	4098                	lw	a4,0(s1)
    80003a12:	ff3716e3          	bne	a4,s3,800039fe <iget+0x38>
    80003a16:	40d8                	lw	a4,4(s1)
    80003a18:	ff4713e3          	bne	a4,s4,800039fe <iget+0x38>
      ip->ref++;
    80003a1c:	2785                	addiw	a5,a5,1
    80003a1e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003a20:	00030517          	auipc	a0,0x30
    80003a24:	fc850513          	addi	a0,a0,-56 # 800339e8 <itable>
    80003a28:	ffffd097          	auipc	ra,0xffffd
    80003a2c:	262080e7          	jalr	610(ra) # 80000c8a <release>
      return ip;
    80003a30:	8926                	mv	s2,s1
    80003a32:	a03d                	j	80003a60 <iget+0x9a>
    if (empty == 0 && ip->ref == 0) // Remember empty slot.
    80003a34:	f7f9                	bnez	a5,80003a02 <iget+0x3c>
    80003a36:	8926                	mv	s2,s1
    80003a38:	b7e9                	j	80003a02 <iget+0x3c>
  if (empty == 0)
    80003a3a:	02090c63          	beqz	s2,80003a72 <iget+0xac>
  ip->dev = dev;
    80003a3e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003a42:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003a46:	4785                	li	a5,1
    80003a48:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003a4c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003a50:	00030517          	auipc	a0,0x30
    80003a54:	f9850513          	addi	a0,a0,-104 # 800339e8 <itable>
    80003a58:	ffffd097          	auipc	ra,0xffffd
    80003a5c:	232080e7          	jalr	562(ra) # 80000c8a <release>
}
    80003a60:	854a                	mv	a0,s2
    80003a62:	70a2                	ld	ra,40(sp)
    80003a64:	7402                	ld	s0,32(sp)
    80003a66:	64e2                	ld	s1,24(sp)
    80003a68:	6942                	ld	s2,16(sp)
    80003a6a:	69a2                	ld	s3,8(sp)
    80003a6c:	6a02                	ld	s4,0(sp)
    80003a6e:	6145                	addi	sp,sp,48
    80003a70:	8082                	ret
    panic("iget: no inodes");
    80003a72:	00005517          	auipc	a0,0x5
    80003a76:	c0650513          	addi	a0,a0,-1018 # 80008678 <syscalls+0x130>
    80003a7a:	ffffd097          	auipc	ra,0xffffd
    80003a7e:	ac4080e7          	jalr	-1340(ra) # 8000053e <panic>

0000000080003a82 <fsinit>:
{
    80003a82:	7179                	addi	sp,sp,-48
    80003a84:	f406                	sd	ra,40(sp)
    80003a86:	f022                	sd	s0,32(sp)
    80003a88:	ec26                	sd	s1,24(sp)
    80003a8a:	e84a                	sd	s2,16(sp)
    80003a8c:	e44e                	sd	s3,8(sp)
    80003a8e:	1800                	addi	s0,sp,48
    80003a90:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003a92:	4585                	li	a1,1
    80003a94:	00000097          	auipc	ra,0x0
    80003a98:	a50080e7          	jalr	-1456(ra) # 800034e4 <bread>
    80003a9c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003a9e:	00030997          	auipc	s3,0x30
    80003aa2:	f2a98993          	addi	s3,s3,-214 # 800339c8 <sb>
    80003aa6:	02000613          	li	a2,32
    80003aaa:	05850593          	addi	a1,a0,88
    80003aae:	854e                	mv	a0,s3
    80003ab0:	ffffd097          	auipc	ra,0xffffd
    80003ab4:	27e080e7          	jalr	638(ra) # 80000d2e <memmove>
  brelse(bp);
    80003ab8:	8526                	mv	a0,s1
    80003aba:	00000097          	auipc	ra,0x0
    80003abe:	b5a080e7          	jalr	-1190(ra) # 80003614 <brelse>
  if (sb.magic != FSMAGIC)
    80003ac2:	0009a703          	lw	a4,0(s3)
    80003ac6:	102037b7          	lui	a5,0x10203
    80003aca:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003ace:	02f71263          	bne	a4,a5,80003af2 <fsinit+0x70>
  initlog(dev, &sb);
    80003ad2:	00030597          	auipc	a1,0x30
    80003ad6:	ef658593          	addi	a1,a1,-266 # 800339c8 <sb>
    80003ada:	854a                	mv	a0,s2
    80003adc:	00001097          	auipc	ra,0x1
    80003ae0:	e8e080e7          	jalr	-370(ra) # 8000496a <initlog>
}
    80003ae4:	70a2                	ld	ra,40(sp)
    80003ae6:	7402                	ld	s0,32(sp)
    80003ae8:	64e2                	ld	s1,24(sp)
    80003aea:	6942                	ld	s2,16(sp)
    80003aec:	69a2                	ld	s3,8(sp)
    80003aee:	6145                	addi	sp,sp,48
    80003af0:	8082                	ret
    panic("invalid file system");
    80003af2:	00005517          	auipc	a0,0x5
    80003af6:	b9650513          	addi	a0,a0,-1130 # 80008688 <syscalls+0x140>
    80003afa:	ffffd097          	auipc	ra,0xffffd
    80003afe:	a44080e7          	jalr	-1468(ra) # 8000053e <panic>

0000000080003b02 <iinit>:
{
    80003b02:	7179                	addi	sp,sp,-48
    80003b04:	f406                	sd	ra,40(sp)
    80003b06:	f022                	sd	s0,32(sp)
    80003b08:	ec26                	sd	s1,24(sp)
    80003b0a:	e84a                	sd	s2,16(sp)
    80003b0c:	e44e                	sd	s3,8(sp)
    80003b0e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003b10:	00005597          	auipc	a1,0x5
    80003b14:	b9058593          	addi	a1,a1,-1136 # 800086a0 <syscalls+0x158>
    80003b18:	00030517          	auipc	a0,0x30
    80003b1c:	ed050513          	addi	a0,a0,-304 # 800339e8 <itable>
    80003b20:	ffffd097          	auipc	ra,0xffffd
    80003b24:	026080e7          	jalr	38(ra) # 80000b46 <initlock>
  for (i = 0; i < NINODE; i++)
    80003b28:	00030497          	auipc	s1,0x30
    80003b2c:	ee848493          	addi	s1,s1,-280 # 80033a10 <itable+0x28>
    80003b30:	00032997          	auipc	s3,0x32
    80003b34:	97098993          	addi	s3,s3,-1680 # 800354a0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003b38:	00005917          	auipc	s2,0x5
    80003b3c:	b7090913          	addi	s2,s2,-1168 # 800086a8 <syscalls+0x160>
    80003b40:	85ca                	mv	a1,s2
    80003b42:	8526                	mv	a0,s1
    80003b44:	00001097          	auipc	ra,0x1
    80003b48:	188080e7          	jalr	392(ra) # 80004ccc <initsleeplock>
  for (i = 0; i < NINODE; i++)
    80003b4c:	08848493          	addi	s1,s1,136
    80003b50:	ff3498e3          	bne	s1,s3,80003b40 <iinit+0x3e>
}
    80003b54:	70a2                	ld	ra,40(sp)
    80003b56:	7402                	ld	s0,32(sp)
    80003b58:	64e2                	ld	s1,24(sp)
    80003b5a:	6942                	ld	s2,16(sp)
    80003b5c:	69a2                	ld	s3,8(sp)
    80003b5e:	6145                	addi	sp,sp,48
    80003b60:	8082                	ret

0000000080003b62 <ialloc>:
{
    80003b62:	715d                	addi	sp,sp,-80
    80003b64:	e486                	sd	ra,72(sp)
    80003b66:	e0a2                	sd	s0,64(sp)
    80003b68:	fc26                	sd	s1,56(sp)
    80003b6a:	f84a                	sd	s2,48(sp)
    80003b6c:	f44e                	sd	s3,40(sp)
    80003b6e:	f052                	sd	s4,32(sp)
    80003b70:	ec56                	sd	s5,24(sp)
    80003b72:	e85a                	sd	s6,16(sp)
    80003b74:	e45e                	sd	s7,8(sp)
    80003b76:	0880                	addi	s0,sp,80
  for (inum = 1; inum < sb.ninodes; inum++)
    80003b78:	00030717          	auipc	a4,0x30
    80003b7c:	e5c72703          	lw	a4,-420(a4) # 800339d4 <sb+0xc>
    80003b80:	4785                	li	a5,1
    80003b82:	04e7fa63          	bgeu	a5,a4,80003bd6 <ialloc+0x74>
    80003b86:	8aaa                	mv	s5,a0
    80003b88:	8bae                	mv	s7,a1
    80003b8a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003b8c:	00030a17          	auipc	s4,0x30
    80003b90:	e3ca0a13          	addi	s4,s4,-452 # 800339c8 <sb>
    80003b94:	00048b1b          	sext.w	s6,s1
    80003b98:	0044d793          	srli	a5,s1,0x4
    80003b9c:	018a2583          	lw	a1,24(s4)
    80003ba0:	9dbd                	addw	a1,a1,a5
    80003ba2:	8556                	mv	a0,s5
    80003ba4:	00000097          	auipc	ra,0x0
    80003ba8:	940080e7          	jalr	-1728(ra) # 800034e4 <bread>
    80003bac:	892a                	mv	s2,a0
    dip = (struct dinode *)bp->data + inum % IPB;
    80003bae:	05850993          	addi	s3,a0,88
    80003bb2:	00f4f793          	andi	a5,s1,15
    80003bb6:	079a                	slli	a5,a5,0x6
    80003bb8:	99be                	add	s3,s3,a5
    if (dip->type == 0)
    80003bba:	00099783          	lh	a5,0(s3)
    80003bbe:	c3a1                	beqz	a5,80003bfe <ialloc+0x9c>
    brelse(bp);
    80003bc0:	00000097          	auipc	ra,0x0
    80003bc4:	a54080e7          	jalr	-1452(ra) # 80003614 <brelse>
  for (inum = 1; inum < sb.ninodes; inum++)
    80003bc8:	0485                	addi	s1,s1,1
    80003bca:	00ca2703          	lw	a4,12(s4)
    80003bce:	0004879b          	sext.w	a5,s1
    80003bd2:	fce7e1e3          	bltu	a5,a4,80003b94 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003bd6:	00005517          	auipc	a0,0x5
    80003bda:	ada50513          	addi	a0,a0,-1318 # 800086b0 <syscalls+0x168>
    80003bde:	ffffd097          	auipc	ra,0xffffd
    80003be2:	9aa080e7          	jalr	-1622(ra) # 80000588 <printf>
  return 0;
    80003be6:	4501                	li	a0,0
}
    80003be8:	60a6                	ld	ra,72(sp)
    80003bea:	6406                	ld	s0,64(sp)
    80003bec:	74e2                	ld	s1,56(sp)
    80003bee:	7942                	ld	s2,48(sp)
    80003bf0:	79a2                	ld	s3,40(sp)
    80003bf2:	7a02                	ld	s4,32(sp)
    80003bf4:	6ae2                	ld	s5,24(sp)
    80003bf6:	6b42                	ld	s6,16(sp)
    80003bf8:	6ba2                	ld	s7,8(sp)
    80003bfa:	6161                	addi	sp,sp,80
    80003bfc:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003bfe:	04000613          	li	a2,64
    80003c02:	4581                	li	a1,0
    80003c04:	854e                	mv	a0,s3
    80003c06:	ffffd097          	auipc	ra,0xffffd
    80003c0a:	0cc080e7          	jalr	204(ra) # 80000cd2 <memset>
      dip->type = type;
    80003c0e:	01799023          	sh	s7,0(s3)
      log_write(bp); // mark it allocated on the disk
    80003c12:	854a                	mv	a0,s2
    80003c14:	00001097          	auipc	ra,0x1
    80003c18:	fd2080e7          	jalr	-46(ra) # 80004be6 <log_write>
      brelse(bp);
    80003c1c:	854a                	mv	a0,s2
    80003c1e:	00000097          	auipc	ra,0x0
    80003c22:	9f6080e7          	jalr	-1546(ra) # 80003614 <brelse>
      return iget(dev, inum);
    80003c26:	85da                	mv	a1,s6
    80003c28:	8556                	mv	a0,s5
    80003c2a:	00000097          	auipc	ra,0x0
    80003c2e:	d9c080e7          	jalr	-612(ra) # 800039c6 <iget>
    80003c32:	bf5d                	j	80003be8 <ialloc+0x86>

0000000080003c34 <iupdate>:
{
    80003c34:	1101                	addi	sp,sp,-32
    80003c36:	ec06                	sd	ra,24(sp)
    80003c38:	e822                	sd	s0,16(sp)
    80003c3a:	e426                	sd	s1,8(sp)
    80003c3c:	e04a                	sd	s2,0(sp)
    80003c3e:	1000                	addi	s0,sp,32
    80003c40:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c42:	415c                	lw	a5,4(a0)
    80003c44:	0047d79b          	srliw	a5,a5,0x4
    80003c48:	00030597          	auipc	a1,0x30
    80003c4c:	d985a583          	lw	a1,-616(a1) # 800339e0 <sb+0x18>
    80003c50:	9dbd                	addw	a1,a1,a5
    80003c52:	4108                	lw	a0,0(a0)
    80003c54:	00000097          	auipc	ra,0x0
    80003c58:	890080e7          	jalr	-1904(ra) # 800034e4 <bread>
    80003c5c:	892a                	mv	s2,a0
  dip = (struct dinode *)bp->data + ip->inum % IPB;
    80003c5e:	05850793          	addi	a5,a0,88
    80003c62:	40c8                	lw	a0,4(s1)
    80003c64:	893d                	andi	a0,a0,15
    80003c66:	051a                	slli	a0,a0,0x6
    80003c68:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003c6a:	04449703          	lh	a4,68(s1)
    80003c6e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003c72:	04649703          	lh	a4,70(s1)
    80003c76:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003c7a:	04849703          	lh	a4,72(s1)
    80003c7e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003c82:	04a49703          	lh	a4,74(s1)
    80003c86:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003c8a:	44f8                	lw	a4,76(s1)
    80003c8c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003c8e:	03400613          	li	a2,52
    80003c92:	05048593          	addi	a1,s1,80
    80003c96:	0531                	addi	a0,a0,12
    80003c98:	ffffd097          	auipc	ra,0xffffd
    80003c9c:	096080e7          	jalr	150(ra) # 80000d2e <memmove>
  log_write(bp);
    80003ca0:	854a                	mv	a0,s2
    80003ca2:	00001097          	auipc	ra,0x1
    80003ca6:	f44080e7          	jalr	-188(ra) # 80004be6 <log_write>
  brelse(bp);
    80003caa:	854a                	mv	a0,s2
    80003cac:	00000097          	auipc	ra,0x0
    80003cb0:	968080e7          	jalr	-1688(ra) # 80003614 <brelse>
}
    80003cb4:	60e2                	ld	ra,24(sp)
    80003cb6:	6442                	ld	s0,16(sp)
    80003cb8:	64a2                	ld	s1,8(sp)
    80003cba:	6902                	ld	s2,0(sp)
    80003cbc:	6105                	addi	sp,sp,32
    80003cbe:	8082                	ret

0000000080003cc0 <idup>:
{
    80003cc0:	1101                	addi	sp,sp,-32
    80003cc2:	ec06                	sd	ra,24(sp)
    80003cc4:	e822                	sd	s0,16(sp)
    80003cc6:	e426                	sd	s1,8(sp)
    80003cc8:	1000                	addi	s0,sp,32
    80003cca:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ccc:	00030517          	auipc	a0,0x30
    80003cd0:	d1c50513          	addi	a0,a0,-740 # 800339e8 <itable>
    80003cd4:	ffffd097          	auipc	ra,0xffffd
    80003cd8:	f02080e7          	jalr	-254(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003cdc:	449c                	lw	a5,8(s1)
    80003cde:	2785                	addiw	a5,a5,1
    80003ce0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ce2:	00030517          	auipc	a0,0x30
    80003ce6:	d0650513          	addi	a0,a0,-762 # 800339e8 <itable>
    80003cea:	ffffd097          	auipc	ra,0xffffd
    80003cee:	fa0080e7          	jalr	-96(ra) # 80000c8a <release>
}
    80003cf2:	8526                	mv	a0,s1
    80003cf4:	60e2                	ld	ra,24(sp)
    80003cf6:	6442                	ld	s0,16(sp)
    80003cf8:	64a2                	ld	s1,8(sp)
    80003cfa:	6105                	addi	sp,sp,32
    80003cfc:	8082                	ret

0000000080003cfe <ilock>:
{
    80003cfe:	1101                	addi	sp,sp,-32
    80003d00:	ec06                	sd	ra,24(sp)
    80003d02:	e822                	sd	s0,16(sp)
    80003d04:	e426                	sd	s1,8(sp)
    80003d06:	e04a                	sd	s2,0(sp)
    80003d08:	1000                	addi	s0,sp,32
  if (ip == 0 || ip->ref < 1)
    80003d0a:	c115                	beqz	a0,80003d2e <ilock+0x30>
    80003d0c:	84aa                	mv	s1,a0
    80003d0e:	451c                	lw	a5,8(a0)
    80003d10:	00f05f63          	blez	a5,80003d2e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003d14:	0541                	addi	a0,a0,16
    80003d16:	00001097          	auipc	ra,0x1
    80003d1a:	ff0080e7          	jalr	-16(ra) # 80004d06 <acquiresleep>
  if (ip->valid == 0)
    80003d1e:	40bc                	lw	a5,64(s1)
    80003d20:	cf99                	beqz	a5,80003d3e <ilock+0x40>
}
    80003d22:	60e2                	ld	ra,24(sp)
    80003d24:	6442                	ld	s0,16(sp)
    80003d26:	64a2                	ld	s1,8(sp)
    80003d28:	6902                	ld	s2,0(sp)
    80003d2a:	6105                	addi	sp,sp,32
    80003d2c:	8082                	ret
    panic("ilock");
    80003d2e:	00005517          	auipc	a0,0x5
    80003d32:	99a50513          	addi	a0,a0,-1638 # 800086c8 <syscalls+0x180>
    80003d36:	ffffd097          	auipc	ra,0xffffd
    80003d3a:	808080e7          	jalr	-2040(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d3e:	40dc                	lw	a5,4(s1)
    80003d40:	0047d79b          	srliw	a5,a5,0x4
    80003d44:	00030597          	auipc	a1,0x30
    80003d48:	c9c5a583          	lw	a1,-868(a1) # 800339e0 <sb+0x18>
    80003d4c:	9dbd                	addw	a1,a1,a5
    80003d4e:	4088                	lw	a0,0(s1)
    80003d50:	fffff097          	auipc	ra,0xfffff
    80003d54:	794080e7          	jalr	1940(ra) # 800034e4 <bread>
    80003d58:	892a                	mv	s2,a0
    dip = (struct dinode *)bp->data + ip->inum % IPB;
    80003d5a:	05850593          	addi	a1,a0,88
    80003d5e:	40dc                	lw	a5,4(s1)
    80003d60:	8bbd                	andi	a5,a5,15
    80003d62:	079a                	slli	a5,a5,0x6
    80003d64:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d66:	00059783          	lh	a5,0(a1)
    80003d6a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003d6e:	00259783          	lh	a5,2(a1)
    80003d72:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003d76:	00459783          	lh	a5,4(a1)
    80003d7a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003d7e:	00659783          	lh	a5,6(a1)
    80003d82:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003d86:	459c                	lw	a5,8(a1)
    80003d88:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003d8a:	03400613          	li	a2,52
    80003d8e:	05b1                	addi	a1,a1,12
    80003d90:	05048513          	addi	a0,s1,80
    80003d94:	ffffd097          	auipc	ra,0xffffd
    80003d98:	f9a080e7          	jalr	-102(ra) # 80000d2e <memmove>
    brelse(bp);
    80003d9c:	854a                	mv	a0,s2
    80003d9e:	00000097          	auipc	ra,0x0
    80003da2:	876080e7          	jalr	-1930(ra) # 80003614 <brelse>
    ip->valid = 1;
    80003da6:	4785                	li	a5,1
    80003da8:	c0bc                	sw	a5,64(s1)
    if (ip->type == 0)
    80003daa:	04449783          	lh	a5,68(s1)
    80003dae:	fbb5                	bnez	a5,80003d22 <ilock+0x24>
      panic("ilock: no type");
    80003db0:	00005517          	auipc	a0,0x5
    80003db4:	92050513          	addi	a0,a0,-1760 # 800086d0 <syscalls+0x188>
    80003db8:	ffffc097          	auipc	ra,0xffffc
    80003dbc:	786080e7          	jalr	1926(ra) # 8000053e <panic>

0000000080003dc0 <iunlock>:
{
    80003dc0:	1101                	addi	sp,sp,-32
    80003dc2:	ec06                	sd	ra,24(sp)
    80003dc4:	e822                	sd	s0,16(sp)
    80003dc6:	e426                	sd	s1,8(sp)
    80003dc8:	e04a                	sd	s2,0(sp)
    80003dca:	1000                	addi	s0,sp,32
  if (ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003dcc:	c905                	beqz	a0,80003dfc <iunlock+0x3c>
    80003dce:	84aa                	mv	s1,a0
    80003dd0:	01050913          	addi	s2,a0,16
    80003dd4:	854a                	mv	a0,s2
    80003dd6:	00001097          	auipc	ra,0x1
    80003dda:	fca080e7          	jalr	-54(ra) # 80004da0 <holdingsleep>
    80003dde:	cd19                	beqz	a0,80003dfc <iunlock+0x3c>
    80003de0:	449c                	lw	a5,8(s1)
    80003de2:	00f05d63          	blez	a5,80003dfc <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003de6:	854a                	mv	a0,s2
    80003de8:	00001097          	auipc	ra,0x1
    80003dec:	f74080e7          	jalr	-140(ra) # 80004d5c <releasesleep>
}
    80003df0:	60e2                	ld	ra,24(sp)
    80003df2:	6442                	ld	s0,16(sp)
    80003df4:	64a2                	ld	s1,8(sp)
    80003df6:	6902                	ld	s2,0(sp)
    80003df8:	6105                	addi	sp,sp,32
    80003dfa:	8082                	ret
    panic("iunlock");
    80003dfc:	00005517          	auipc	a0,0x5
    80003e00:	8e450513          	addi	a0,a0,-1820 # 800086e0 <syscalls+0x198>
    80003e04:	ffffc097          	auipc	ra,0xffffc
    80003e08:	73a080e7          	jalr	1850(ra) # 8000053e <panic>

0000000080003e0c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void itrunc(struct inode *ip)
{
    80003e0c:	7179                	addi	sp,sp,-48
    80003e0e:	f406                	sd	ra,40(sp)
    80003e10:	f022                	sd	s0,32(sp)
    80003e12:	ec26                	sd	s1,24(sp)
    80003e14:	e84a                	sd	s2,16(sp)
    80003e16:	e44e                	sd	s3,8(sp)
    80003e18:	e052                	sd	s4,0(sp)
    80003e1a:	1800                	addi	s0,sp,48
    80003e1c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for (i = 0; i < NDIRECT; i++)
    80003e1e:	05050493          	addi	s1,a0,80
    80003e22:	08050913          	addi	s2,a0,128
    80003e26:	a021                	j	80003e2e <itrunc+0x22>
    80003e28:	0491                	addi	s1,s1,4
    80003e2a:	01248d63          	beq	s1,s2,80003e44 <itrunc+0x38>
  {
    if (ip->addrs[i])
    80003e2e:	408c                	lw	a1,0(s1)
    80003e30:	dde5                	beqz	a1,80003e28 <itrunc+0x1c>
    {
      bfree(ip->dev, ip->addrs[i]);
    80003e32:	0009a503          	lw	a0,0(s3)
    80003e36:	00000097          	auipc	ra,0x0
    80003e3a:	8f4080e7          	jalr	-1804(ra) # 8000372a <bfree>
      ip->addrs[i] = 0;
    80003e3e:	0004a023          	sw	zero,0(s1)
    80003e42:	b7dd                	j	80003e28 <itrunc+0x1c>
    }
  }

  if (ip->addrs[NDIRECT])
    80003e44:	0809a583          	lw	a1,128(s3)
    80003e48:	e185                	bnez	a1,80003e68 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003e4a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003e4e:	854e                	mv	a0,s3
    80003e50:	00000097          	auipc	ra,0x0
    80003e54:	de4080e7          	jalr	-540(ra) # 80003c34 <iupdate>
}
    80003e58:	70a2                	ld	ra,40(sp)
    80003e5a:	7402                	ld	s0,32(sp)
    80003e5c:	64e2                	ld	s1,24(sp)
    80003e5e:	6942                	ld	s2,16(sp)
    80003e60:	69a2                	ld	s3,8(sp)
    80003e62:	6a02                	ld	s4,0(sp)
    80003e64:	6145                	addi	sp,sp,48
    80003e66:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e68:	0009a503          	lw	a0,0(s3)
    80003e6c:	fffff097          	auipc	ra,0xfffff
    80003e70:	678080e7          	jalr	1656(ra) # 800034e4 <bread>
    80003e74:	8a2a                	mv	s4,a0
    for (j = 0; j < NINDIRECT; j++)
    80003e76:	05850493          	addi	s1,a0,88
    80003e7a:	45850913          	addi	s2,a0,1112
    80003e7e:	a021                	j	80003e86 <itrunc+0x7a>
    80003e80:	0491                	addi	s1,s1,4
    80003e82:	01248b63          	beq	s1,s2,80003e98 <itrunc+0x8c>
      if (a[j])
    80003e86:	408c                	lw	a1,0(s1)
    80003e88:	dde5                	beqz	a1,80003e80 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003e8a:	0009a503          	lw	a0,0(s3)
    80003e8e:	00000097          	auipc	ra,0x0
    80003e92:	89c080e7          	jalr	-1892(ra) # 8000372a <bfree>
    80003e96:	b7ed                	j	80003e80 <itrunc+0x74>
    brelse(bp);
    80003e98:	8552                	mv	a0,s4
    80003e9a:	fffff097          	auipc	ra,0xfffff
    80003e9e:	77a080e7          	jalr	1914(ra) # 80003614 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ea2:	0809a583          	lw	a1,128(s3)
    80003ea6:	0009a503          	lw	a0,0(s3)
    80003eaa:	00000097          	auipc	ra,0x0
    80003eae:	880080e7          	jalr	-1920(ra) # 8000372a <bfree>
    ip->addrs[NDIRECT] = 0;
    80003eb2:	0809a023          	sw	zero,128(s3)
    80003eb6:	bf51                	j	80003e4a <itrunc+0x3e>

0000000080003eb8 <iput>:
{
    80003eb8:	1101                	addi	sp,sp,-32
    80003eba:	ec06                	sd	ra,24(sp)
    80003ebc:	e822                	sd	s0,16(sp)
    80003ebe:	e426                	sd	s1,8(sp)
    80003ec0:	e04a                	sd	s2,0(sp)
    80003ec2:	1000                	addi	s0,sp,32
    80003ec4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ec6:	00030517          	auipc	a0,0x30
    80003eca:	b2250513          	addi	a0,a0,-1246 # 800339e8 <itable>
    80003ece:	ffffd097          	auipc	ra,0xffffd
    80003ed2:	d08080e7          	jalr	-760(ra) # 80000bd6 <acquire>
  if (ip->ref == 1 && ip->valid && ip->nlink == 0)
    80003ed6:	4498                	lw	a4,8(s1)
    80003ed8:	4785                	li	a5,1
    80003eda:	02f70363          	beq	a4,a5,80003f00 <iput+0x48>
  ip->ref--;
    80003ede:	449c                	lw	a5,8(s1)
    80003ee0:	37fd                	addiw	a5,a5,-1
    80003ee2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ee4:	00030517          	auipc	a0,0x30
    80003ee8:	b0450513          	addi	a0,a0,-1276 # 800339e8 <itable>
    80003eec:	ffffd097          	auipc	ra,0xffffd
    80003ef0:	d9e080e7          	jalr	-610(ra) # 80000c8a <release>
}
    80003ef4:	60e2                	ld	ra,24(sp)
    80003ef6:	6442                	ld	s0,16(sp)
    80003ef8:	64a2                	ld	s1,8(sp)
    80003efa:	6902                	ld	s2,0(sp)
    80003efc:	6105                	addi	sp,sp,32
    80003efe:	8082                	ret
  if (ip->ref == 1 && ip->valid && ip->nlink == 0)
    80003f00:	40bc                	lw	a5,64(s1)
    80003f02:	dff1                	beqz	a5,80003ede <iput+0x26>
    80003f04:	04a49783          	lh	a5,74(s1)
    80003f08:	fbf9                	bnez	a5,80003ede <iput+0x26>
    acquiresleep(&ip->lock);
    80003f0a:	01048913          	addi	s2,s1,16
    80003f0e:	854a                	mv	a0,s2
    80003f10:	00001097          	auipc	ra,0x1
    80003f14:	df6080e7          	jalr	-522(ra) # 80004d06 <acquiresleep>
    release(&itable.lock);
    80003f18:	00030517          	auipc	a0,0x30
    80003f1c:	ad050513          	addi	a0,a0,-1328 # 800339e8 <itable>
    80003f20:	ffffd097          	auipc	ra,0xffffd
    80003f24:	d6a080e7          	jalr	-662(ra) # 80000c8a <release>
    itrunc(ip);
    80003f28:	8526                	mv	a0,s1
    80003f2a:	00000097          	auipc	ra,0x0
    80003f2e:	ee2080e7          	jalr	-286(ra) # 80003e0c <itrunc>
    ip->type = 0;
    80003f32:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003f36:	8526                	mv	a0,s1
    80003f38:	00000097          	auipc	ra,0x0
    80003f3c:	cfc080e7          	jalr	-772(ra) # 80003c34 <iupdate>
    ip->valid = 0;
    80003f40:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003f44:	854a                	mv	a0,s2
    80003f46:	00001097          	auipc	ra,0x1
    80003f4a:	e16080e7          	jalr	-490(ra) # 80004d5c <releasesleep>
    acquire(&itable.lock);
    80003f4e:	00030517          	auipc	a0,0x30
    80003f52:	a9a50513          	addi	a0,a0,-1382 # 800339e8 <itable>
    80003f56:	ffffd097          	auipc	ra,0xffffd
    80003f5a:	c80080e7          	jalr	-896(ra) # 80000bd6 <acquire>
    80003f5e:	b741                	j	80003ede <iput+0x26>

0000000080003f60 <iunlockput>:
{
    80003f60:	1101                	addi	sp,sp,-32
    80003f62:	ec06                	sd	ra,24(sp)
    80003f64:	e822                	sd	s0,16(sp)
    80003f66:	e426                	sd	s1,8(sp)
    80003f68:	1000                	addi	s0,sp,32
    80003f6a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f6c:	00000097          	auipc	ra,0x0
    80003f70:	e54080e7          	jalr	-428(ra) # 80003dc0 <iunlock>
  iput(ip);
    80003f74:	8526                	mv	a0,s1
    80003f76:	00000097          	auipc	ra,0x0
    80003f7a:	f42080e7          	jalr	-190(ra) # 80003eb8 <iput>
}
    80003f7e:	60e2                	ld	ra,24(sp)
    80003f80:	6442                	ld	s0,16(sp)
    80003f82:	64a2                	ld	s1,8(sp)
    80003f84:	6105                	addi	sp,sp,32
    80003f86:	8082                	ret

0000000080003f88 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void stati(struct inode *ip, struct stat *st)
{
    80003f88:	1141                	addi	sp,sp,-16
    80003f8a:	e422                	sd	s0,8(sp)
    80003f8c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003f8e:	411c                	lw	a5,0(a0)
    80003f90:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003f92:	415c                	lw	a5,4(a0)
    80003f94:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003f96:	04451783          	lh	a5,68(a0)
    80003f9a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003f9e:	04a51783          	lh	a5,74(a0)
    80003fa2:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003fa6:	04c56783          	lwu	a5,76(a0)
    80003faa:	e99c                	sd	a5,16(a1)
}
    80003fac:	6422                	ld	s0,8(sp)
    80003fae:	0141                	addi	sp,sp,16
    80003fb0:	8082                	ret

0000000080003fb2 <readi>:
int readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if (off > ip->size || off + n < off)
    80003fb2:	457c                	lw	a5,76(a0)
    80003fb4:	0ed7e963          	bltu	a5,a3,800040a6 <readi+0xf4>
{
    80003fb8:	7159                	addi	sp,sp,-112
    80003fba:	f486                	sd	ra,104(sp)
    80003fbc:	f0a2                	sd	s0,96(sp)
    80003fbe:	eca6                	sd	s1,88(sp)
    80003fc0:	e8ca                	sd	s2,80(sp)
    80003fc2:	e4ce                	sd	s3,72(sp)
    80003fc4:	e0d2                	sd	s4,64(sp)
    80003fc6:	fc56                	sd	s5,56(sp)
    80003fc8:	f85a                	sd	s6,48(sp)
    80003fca:	f45e                	sd	s7,40(sp)
    80003fcc:	f062                	sd	s8,32(sp)
    80003fce:	ec66                	sd	s9,24(sp)
    80003fd0:	e86a                	sd	s10,16(sp)
    80003fd2:	e46e                	sd	s11,8(sp)
    80003fd4:	1880                	addi	s0,sp,112
    80003fd6:	8b2a                	mv	s6,a0
    80003fd8:	8bae                	mv	s7,a1
    80003fda:	8a32                	mv	s4,a2
    80003fdc:	84b6                	mv	s1,a3
    80003fde:	8aba                	mv	s5,a4
  if (off > ip->size || off + n < off)
    80003fe0:	9f35                	addw	a4,a4,a3
    return 0;
    80003fe2:	4501                	li	a0,0
  if (off > ip->size || off + n < off)
    80003fe4:	0ad76063          	bltu	a4,a3,80004084 <readi+0xd2>
  if (off + n > ip->size)
    80003fe8:	00e7f463          	bgeu	a5,a4,80003ff0 <readi+0x3e>
    n = ip->size - off;
    80003fec:	40d78abb          	subw	s5,a5,a3

  for (tot = 0; tot < n; tot += m, off += m, dst += m)
    80003ff0:	0a0a8963          	beqz	s5,800040a2 <readi+0xf0>
    80003ff4:	4981                	li	s3,0
  {
    uint addr = bmap(ip, off / BSIZE);
    if (addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off % BSIZE);
    80003ff6:	40000c93          	li	s9,1024
    if (either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1)
    80003ffa:	5c7d                	li	s8,-1
    80003ffc:	a82d                	j	80004036 <readi+0x84>
    80003ffe:	020d1d93          	slli	s11,s10,0x20
    80004002:	020ddd93          	srli	s11,s11,0x20
    80004006:	05890793          	addi	a5,s2,88
    8000400a:	86ee                	mv	a3,s11
    8000400c:	963e                	add	a2,a2,a5
    8000400e:	85d2                	mv	a1,s4
    80004010:	855e                	mv	a0,s7
    80004012:	ffffe097          	auipc	ra,0xffffe
    80004016:	668080e7          	jalr	1640(ra) # 8000267a <either_copyout>
    8000401a:	05850d63          	beq	a0,s8,80004074 <readi+0xc2>
    {
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000401e:	854a                	mv	a0,s2
    80004020:	fffff097          	auipc	ra,0xfffff
    80004024:	5f4080e7          	jalr	1524(ra) # 80003614 <brelse>
  for (tot = 0; tot < n; tot += m, off += m, dst += m)
    80004028:	013d09bb          	addw	s3,s10,s3
    8000402c:	009d04bb          	addw	s1,s10,s1
    80004030:	9a6e                	add	s4,s4,s11
    80004032:	0559f763          	bgeu	s3,s5,80004080 <readi+0xce>
    uint addr = bmap(ip, off / BSIZE);
    80004036:	00a4d59b          	srliw	a1,s1,0xa
    8000403a:	855a                	mv	a0,s6
    8000403c:	00000097          	auipc	ra,0x0
    80004040:	8a2080e7          	jalr	-1886(ra) # 800038de <bmap>
    80004044:	0005059b          	sext.w	a1,a0
    if (addr == 0)
    80004048:	cd85                	beqz	a1,80004080 <readi+0xce>
    bp = bread(ip->dev, addr);
    8000404a:	000b2503          	lw	a0,0(s6)
    8000404e:	fffff097          	auipc	ra,0xfffff
    80004052:	496080e7          	jalr	1174(ra) # 800034e4 <bread>
    80004056:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off % BSIZE);
    80004058:	3ff4f613          	andi	a2,s1,1023
    8000405c:	40cc87bb          	subw	a5,s9,a2
    80004060:	413a873b          	subw	a4,s5,s3
    80004064:	8d3e                	mv	s10,a5
    80004066:	2781                	sext.w	a5,a5
    80004068:	0007069b          	sext.w	a3,a4
    8000406c:	f8f6f9e3          	bgeu	a3,a5,80003ffe <readi+0x4c>
    80004070:	8d3a                	mv	s10,a4
    80004072:	b771                	j	80003ffe <readi+0x4c>
      brelse(bp);
    80004074:	854a                	mv	a0,s2
    80004076:	fffff097          	auipc	ra,0xfffff
    8000407a:	59e080e7          	jalr	1438(ra) # 80003614 <brelse>
      tot = -1;
    8000407e:	59fd                	li	s3,-1
  }
  return tot;
    80004080:	0009851b          	sext.w	a0,s3
}
    80004084:	70a6                	ld	ra,104(sp)
    80004086:	7406                	ld	s0,96(sp)
    80004088:	64e6                	ld	s1,88(sp)
    8000408a:	6946                	ld	s2,80(sp)
    8000408c:	69a6                	ld	s3,72(sp)
    8000408e:	6a06                	ld	s4,64(sp)
    80004090:	7ae2                	ld	s5,56(sp)
    80004092:	7b42                	ld	s6,48(sp)
    80004094:	7ba2                	ld	s7,40(sp)
    80004096:	7c02                	ld	s8,32(sp)
    80004098:	6ce2                	ld	s9,24(sp)
    8000409a:	6d42                	ld	s10,16(sp)
    8000409c:	6da2                	ld	s11,8(sp)
    8000409e:	6165                	addi	sp,sp,112
    800040a0:	8082                	ret
  for (tot = 0; tot < n; tot += m, off += m, dst += m)
    800040a2:	89d6                	mv	s3,s5
    800040a4:	bff1                	j	80004080 <readi+0xce>
    return 0;
    800040a6:	4501                	li	a0,0
}
    800040a8:	8082                	ret

00000000800040aa <writei>:
int writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if (off > ip->size || off + n < off)
    800040aa:	457c                	lw	a5,76(a0)
    800040ac:	10d7e863          	bltu	a5,a3,800041bc <writei+0x112>
{
    800040b0:	7159                	addi	sp,sp,-112
    800040b2:	f486                	sd	ra,104(sp)
    800040b4:	f0a2                	sd	s0,96(sp)
    800040b6:	eca6                	sd	s1,88(sp)
    800040b8:	e8ca                	sd	s2,80(sp)
    800040ba:	e4ce                	sd	s3,72(sp)
    800040bc:	e0d2                	sd	s4,64(sp)
    800040be:	fc56                	sd	s5,56(sp)
    800040c0:	f85a                	sd	s6,48(sp)
    800040c2:	f45e                	sd	s7,40(sp)
    800040c4:	f062                	sd	s8,32(sp)
    800040c6:	ec66                	sd	s9,24(sp)
    800040c8:	e86a                	sd	s10,16(sp)
    800040ca:	e46e                	sd	s11,8(sp)
    800040cc:	1880                	addi	s0,sp,112
    800040ce:	8aaa                	mv	s5,a0
    800040d0:	8bae                	mv	s7,a1
    800040d2:	8a32                	mv	s4,a2
    800040d4:	8936                	mv	s2,a3
    800040d6:	8b3a                	mv	s6,a4
  if (off > ip->size || off + n < off)
    800040d8:	00e687bb          	addw	a5,a3,a4
    800040dc:	0ed7e263          	bltu	a5,a3,800041c0 <writei+0x116>
    return -1;
  if (off + n > MAXFILE * BSIZE)
    800040e0:	00043737          	lui	a4,0x43
    800040e4:	0ef76063          	bltu	a4,a5,800041c4 <writei+0x11a>
    return -1;

  for (tot = 0; tot < n; tot += m, off += m, src += m)
    800040e8:	0c0b0863          	beqz	s6,800041b8 <writei+0x10e>
    800040ec:	4981                	li	s3,0
  {
    uint addr = bmap(ip, off / BSIZE);
    if (addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off % BSIZE);
    800040ee:	40000c93          	li	s9,1024
    if (either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1)
    800040f2:	5c7d                	li	s8,-1
    800040f4:	a091                	j	80004138 <writei+0x8e>
    800040f6:	020d1d93          	slli	s11,s10,0x20
    800040fa:	020ddd93          	srli	s11,s11,0x20
    800040fe:	05848793          	addi	a5,s1,88
    80004102:	86ee                	mv	a3,s11
    80004104:	8652                	mv	a2,s4
    80004106:	85de                	mv	a1,s7
    80004108:	953e                	add	a0,a0,a5
    8000410a:	ffffe097          	auipc	ra,0xffffe
    8000410e:	5c6080e7          	jalr	1478(ra) # 800026d0 <either_copyin>
    80004112:	07850263          	beq	a0,s8,80004176 <writei+0xcc>
    {
      brelse(bp);
      break;
    }
    log_write(bp);
    80004116:	8526                	mv	a0,s1
    80004118:	00001097          	auipc	ra,0x1
    8000411c:	ace080e7          	jalr	-1330(ra) # 80004be6 <log_write>
    brelse(bp);
    80004120:	8526                	mv	a0,s1
    80004122:	fffff097          	auipc	ra,0xfffff
    80004126:	4f2080e7          	jalr	1266(ra) # 80003614 <brelse>
  for (tot = 0; tot < n; tot += m, off += m, src += m)
    8000412a:	013d09bb          	addw	s3,s10,s3
    8000412e:	012d093b          	addw	s2,s10,s2
    80004132:	9a6e                	add	s4,s4,s11
    80004134:	0569f663          	bgeu	s3,s6,80004180 <writei+0xd6>
    uint addr = bmap(ip, off / BSIZE);
    80004138:	00a9559b          	srliw	a1,s2,0xa
    8000413c:	8556                	mv	a0,s5
    8000413e:	fffff097          	auipc	ra,0xfffff
    80004142:	7a0080e7          	jalr	1952(ra) # 800038de <bmap>
    80004146:	0005059b          	sext.w	a1,a0
    if (addr == 0)
    8000414a:	c99d                	beqz	a1,80004180 <writei+0xd6>
    bp = bread(ip->dev, addr);
    8000414c:	000aa503          	lw	a0,0(s5)
    80004150:	fffff097          	auipc	ra,0xfffff
    80004154:	394080e7          	jalr	916(ra) # 800034e4 <bread>
    80004158:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off % BSIZE);
    8000415a:	3ff97513          	andi	a0,s2,1023
    8000415e:	40ac87bb          	subw	a5,s9,a0
    80004162:	413b073b          	subw	a4,s6,s3
    80004166:	8d3e                	mv	s10,a5
    80004168:	2781                	sext.w	a5,a5
    8000416a:	0007069b          	sext.w	a3,a4
    8000416e:	f8f6f4e3          	bgeu	a3,a5,800040f6 <writei+0x4c>
    80004172:	8d3a                	mv	s10,a4
    80004174:	b749                	j	800040f6 <writei+0x4c>
      brelse(bp);
    80004176:	8526                	mv	a0,s1
    80004178:	fffff097          	auipc	ra,0xfffff
    8000417c:	49c080e7          	jalr	1180(ra) # 80003614 <brelse>
  }

  if (off > ip->size)
    80004180:	04caa783          	lw	a5,76(s5)
    80004184:	0127f463          	bgeu	a5,s2,8000418c <writei+0xe2>
    ip->size = off;
    80004188:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000418c:	8556                	mv	a0,s5
    8000418e:	00000097          	auipc	ra,0x0
    80004192:	aa6080e7          	jalr	-1370(ra) # 80003c34 <iupdate>

  return tot;
    80004196:	0009851b          	sext.w	a0,s3
}
    8000419a:	70a6                	ld	ra,104(sp)
    8000419c:	7406                	ld	s0,96(sp)
    8000419e:	64e6                	ld	s1,88(sp)
    800041a0:	6946                	ld	s2,80(sp)
    800041a2:	69a6                	ld	s3,72(sp)
    800041a4:	6a06                	ld	s4,64(sp)
    800041a6:	7ae2                	ld	s5,56(sp)
    800041a8:	7b42                	ld	s6,48(sp)
    800041aa:	7ba2                	ld	s7,40(sp)
    800041ac:	7c02                	ld	s8,32(sp)
    800041ae:	6ce2                	ld	s9,24(sp)
    800041b0:	6d42                	ld	s10,16(sp)
    800041b2:	6da2                	ld	s11,8(sp)
    800041b4:	6165                	addi	sp,sp,112
    800041b6:	8082                	ret
  for (tot = 0; tot < n; tot += m, off += m, src += m)
    800041b8:	89da                	mv	s3,s6
    800041ba:	bfc9                	j	8000418c <writei+0xe2>
    return -1;
    800041bc:	557d                	li	a0,-1
}
    800041be:	8082                	ret
    return -1;
    800041c0:	557d                	li	a0,-1
    800041c2:	bfe1                	j	8000419a <writei+0xf0>
    return -1;
    800041c4:	557d                	li	a0,-1
    800041c6:	bfd1                	j	8000419a <writei+0xf0>

00000000800041c8 <namecmp>:

// Directories

int namecmp(const char *s, const char *t)
{
    800041c8:	1141                	addi	sp,sp,-16
    800041ca:	e406                	sd	ra,8(sp)
    800041cc:	e022                	sd	s0,0(sp)
    800041ce:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800041d0:	4639                	li	a2,14
    800041d2:	ffffd097          	auipc	ra,0xffffd
    800041d6:	bd0080e7          	jalr	-1072(ra) # 80000da2 <strncmp>
}
    800041da:	60a2                	ld	ra,8(sp)
    800041dc:	6402                	ld	s0,0(sp)
    800041de:	0141                	addi	sp,sp,16
    800041e0:	8082                	ret

00000000800041e2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode *
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800041e2:	7139                	addi	sp,sp,-64
    800041e4:	fc06                	sd	ra,56(sp)
    800041e6:	f822                	sd	s0,48(sp)
    800041e8:	f426                	sd	s1,40(sp)
    800041ea:	f04a                	sd	s2,32(sp)
    800041ec:	ec4e                	sd	s3,24(sp)
    800041ee:	e852                	sd	s4,16(sp)
    800041f0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if (dp->type != T_DIR)
    800041f2:	04451703          	lh	a4,68(a0)
    800041f6:	4785                	li	a5,1
    800041f8:	00f71a63          	bne	a4,a5,8000420c <dirlookup+0x2a>
    800041fc:	892a                	mv	s2,a0
    800041fe:	89ae                	mv	s3,a1
    80004200:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for (off = 0; off < dp->size; off += sizeof(de))
    80004202:	457c                	lw	a5,76(a0)
    80004204:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004206:	4501                	li	a0,0
  for (off = 0; off < dp->size; off += sizeof(de))
    80004208:	e79d                	bnez	a5,80004236 <dirlookup+0x54>
    8000420a:	a8a5                	j	80004282 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000420c:	00004517          	auipc	a0,0x4
    80004210:	4dc50513          	addi	a0,a0,1244 # 800086e8 <syscalls+0x1a0>
    80004214:	ffffc097          	auipc	ra,0xffffc
    80004218:	32a080e7          	jalr	810(ra) # 8000053e <panic>
      panic("dirlookup read");
    8000421c:	00004517          	auipc	a0,0x4
    80004220:	4e450513          	addi	a0,a0,1252 # 80008700 <syscalls+0x1b8>
    80004224:	ffffc097          	auipc	ra,0xffffc
    80004228:	31a080e7          	jalr	794(ra) # 8000053e <panic>
  for (off = 0; off < dp->size; off += sizeof(de))
    8000422c:	24c1                	addiw	s1,s1,16
    8000422e:	04c92783          	lw	a5,76(s2)
    80004232:	04f4f763          	bgeu	s1,a5,80004280 <dirlookup+0x9e>
    if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004236:	4741                	li	a4,16
    80004238:	86a6                	mv	a3,s1
    8000423a:	fc040613          	addi	a2,s0,-64
    8000423e:	4581                	li	a1,0
    80004240:	854a                	mv	a0,s2
    80004242:	00000097          	auipc	ra,0x0
    80004246:	d70080e7          	jalr	-656(ra) # 80003fb2 <readi>
    8000424a:	47c1                	li	a5,16
    8000424c:	fcf518e3          	bne	a0,a5,8000421c <dirlookup+0x3a>
    if (de.inum == 0)
    80004250:	fc045783          	lhu	a5,-64(s0)
    80004254:	dfe1                	beqz	a5,8000422c <dirlookup+0x4a>
    if (namecmp(name, de.name) == 0)
    80004256:	fc240593          	addi	a1,s0,-62
    8000425a:	854e                	mv	a0,s3
    8000425c:	00000097          	auipc	ra,0x0
    80004260:	f6c080e7          	jalr	-148(ra) # 800041c8 <namecmp>
    80004264:	f561                	bnez	a0,8000422c <dirlookup+0x4a>
      if (poff)
    80004266:	000a0463          	beqz	s4,8000426e <dirlookup+0x8c>
        *poff = off;
    8000426a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000426e:	fc045583          	lhu	a1,-64(s0)
    80004272:	00092503          	lw	a0,0(s2)
    80004276:	fffff097          	auipc	ra,0xfffff
    8000427a:	750080e7          	jalr	1872(ra) # 800039c6 <iget>
    8000427e:	a011                	j	80004282 <dirlookup+0xa0>
  return 0;
    80004280:	4501                	li	a0,0
}
    80004282:	70e2                	ld	ra,56(sp)
    80004284:	7442                	ld	s0,48(sp)
    80004286:	74a2                	ld	s1,40(sp)
    80004288:	7902                	ld	s2,32(sp)
    8000428a:	69e2                	ld	s3,24(sp)
    8000428c:	6a42                	ld	s4,16(sp)
    8000428e:	6121                	addi	sp,sp,64
    80004290:	8082                	ret

0000000080004292 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode *
namex(char *path, int nameiparent, char *name)
{
    80004292:	711d                	addi	sp,sp,-96
    80004294:	ec86                	sd	ra,88(sp)
    80004296:	e8a2                	sd	s0,80(sp)
    80004298:	e4a6                	sd	s1,72(sp)
    8000429a:	e0ca                	sd	s2,64(sp)
    8000429c:	fc4e                	sd	s3,56(sp)
    8000429e:	f852                	sd	s4,48(sp)
    800042a0:	f456                	sd	s5,40(sp)
    800042a2:	f05a                	sd	s6,32(sp)
    800042a4:	ec5e                	sd	s7,24(sp)
    800042a6:	e862                	sd	s8,16(sp)
    800042a8:	e466                	sd	s9,8(sp)
    800042aa:	1080                	addi	s0,sp,96
    800042ac:	84aa                	mv	s1,a0
    800042ae:	8aae                	mv	s5,a1
    800042b0:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if (*path == '/')
    800042b2:	00054703          	lbu	a4,0(a0)
    800042b6:	02f00793          	li	a5,47
    800042ba:	02f70363          	beq	a4,a5,800042e0 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800042be:	ffffe097          	auipc	ra,0xffffe
    800042c2:	844080e7          	jalr	-1980(ra) # 80001b02 <myproc>
    800042c6:	15053503          	ld	a0,336(a0)
    800042ca:	00000097          	auipc	ra,0x0
    800042ce:	9f6080e7          	jalr	-1546(ra) # 80003cc0 <idup>
    800042d2:	89aa                	mv	s3,a0
  while (*path == '/')
    800042d4:	02f00913          	li	s2,47
  len = path - s;
    800042d8:	4b01                	li	s6,0
  if (len >= DIRSIZ)
    800042da:	4c35                	li	s8,13

  while ((path = skipelem(path, name)) != 0)
  {
    ilock(ip);
    if (ip->type != T_DIR)
    800042dc:	4b85                	li	s7,1
    800042de:	a865                	j	80004396 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800042e0:	4585                	li	a1,1
    800042e2:	4505                	li	a0,1
    800042e4:	fffff097          	auipc	ra,0xfffff
    800042e8:	6e2080e7          	jalr	1762(ra) # 800039c6 <iget>
    800042ec:	89aa                	mv	s3,a0
    800042ee:	b7dd                	j	800042d4 <namex+0x42>
    {
      iunlockput(ip);
    800042f0:	854e                	mv	a0,s3
    800042f2:	00000097          	auipc	ra,0x0
    800042f6:	c6e080e7          	jalr	-914(ra) # 80003f60 <iunlockput>
      return 0;
    800042fa:	4981                	li	s3,0
  {
    iput(ip);
    return 0;
  }
  return ip;
}
    800042fc:	854e                	mv	a0,s3
    800042fe:	60e6                	ld	ra,88(sp)
    80004300:	6446                	ld	s0,80(sp)
    80004302:	64a6                	ld	s1,72(sp)
    80004304:	6906                	ld	s2,64(sp)
    80004306:	79e2                	ld	s3,56(sp)
    80004308:	7a42                	ld	s4,48(sp)
    8000430a:	7aa2                	ld	s5,40(sp)
    8000430c:	7b02                	ld	s6,32(sp)
    8000430e:	6be2                	ld	s7,24(sp)
    80004310:	6c42                	ld	s8,16(sp)
    80004312:	6ca2                	ld	s9,8(sp)
    80004314:	6125                	addi	sp,sp,96
    80004316:	8082                	ret
      iunlock(ip);
    80004318:	854e                	mv	a0,s3
    8000431a:	00000097          	auipc	ra,0x0
    8000431e:	aa6080e7          	jalr	-1370(ra) # 80003dc0 <iunlock>
      return ip;
    80004322:	bfe9                	j	800042fc <namex+0x6a>
      iunlockput(ip);
    80004324:	854e                	mv	a0,s3
    80004326:	00000097          	auipc	ra,0x0
    8000432a:	c3a080e7          	jalr	-966(ra) # 80003f60 <iunlockput>
      return 0;
    8000432e:	89e6                	mv	s3,s9
    80004330:	b7f1                	j	800042fc <namex+0x6a>
  len = path - s;
    80004332:	40b48633          	sub	a2,s1,a1
    80004336:	00060c9b          	sext.w	s9,a2
  if (len >= DIRSIZ)
    8000433a:	099c5463          	bge	s8,s9,800043c2 <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000433e:	4639                	li	a2,14
    80004340:	8552                	mv	a0,s4
    80004342:	ffffd097          	auipc	ra,0xffffd
    80004346:	9ec080e7          	jalr	-1556(ra) # 80000d2e <memmove>
  while (*path == '/')
    8000434a:	0004c783          	lbu	a5,0(s1)
    8000434e:	01279763          	bne	a5,s2,8000435c <namex+0xca>
    path++;
    80004352:	0485                	addi	s1,s1,1
  while (*path == '/')
    80004354:	0004c783          	lbu	a5,0(s1)
    80004358:	ff278de3          	beq	a5,s2,80004352 <namex+0xc0>
    ilock(ip);
    8000435c:	854e                	mv	a0,s3
    8000435e:	00000097          	auipc	ra,0x0
    80004362:	9a0080e7          	jalr	-1632(ra) # 80003cfe <ilock>
    if (ip->type != T_DIR)
    80004366:	04499783          	lh	a5,68(s3)
    8000436a:	f97793e3          	bne	a5,s7,800042f0 <namex+0x5e>
    if (nameiparent && *path == '\0')
    8000436e:	000a8563          	beqz	s5,80004378 <namex+0xe6>
    80004372:	0004c783          	lbu	a5,0(s1)
    80004376:	d3cd                	beqz	a5,80004318 <namex+0x86>
    if ((next = dirlookup(ip, name, 0)) == 0)
    80004378:	865a                	mv	a2,s6
    8000437a:	85d2                	mv	a1,s4
    8000437c:	854e                	mv	a0,s3
    8000437e:	00000097          	auipc	ra,0x0
    80004382:	e64080e7          	jalr	-412(ra) # 800041e2 <dirlookup>
    80004386:	8caa                	mv	s9,a0
    80004388:	dd51                	beqz	a0,80004324 <namex+0x92>
    iunlockput(ip);
    8000438a:	854e                	mv	a0,s3
    8000438c:	00000097          	auipc	ra,0x0
    80004390:	bd4080e7          	jalr	-1068(ra) # 80003f60 <iunlockput>
    ip = next;
    80004394:	89e6                	mv	s3,s9
  while (*path == '/')
    80004396:	0004c783          	lbu	a5,0(s1)
    8000439a:	05279763          	bne	a5,s2,800043e8 <namex+0x156>
    path++;
    8000439e:	0485                	addi	s1,s1,1
  while (*path == '/')
    800043a0:	0004c783          	lbu	a5,0(s1)
    800043a4:	ff278de3          	beq	a5,s2,8000439e <namex+0x10c>
  if (*path == 0)
    800043a8:	c79d                	beqz	a5,800043d6 <namex+0x144>
    path++;
    800043aa:	85a6                	mv	a1,s1
  len = path - s;
    800043ac:	8cda                	mv	s9,s6
    800043ae:	865a                	mv	a2,s6
  while (*path != '/' && *path != 0)
    800043b0:	01278963          	beq	a5,s2,800043c2 <namex+0x130>
    800043b4:	dfbd                	beqz	a5,80004332 <namex+0xa0>
    path++;
    800043b6:	0485                	addi	s1,s1,1
  while (*path != '/' && *path != 0)
    800043b8:	0004c783          	lbu	a5,0(s1)
    800043bc:	ff279ce3          	bne	a5,s2,800043b4 <namex+0x122>
    800043c0:	bf8d                	j	80004332 <namex+0xa0>
    memmove(name, s, len);
    800043c2:	2601                	sext.w	a2,a2
    800043c4:	8552                	mv	a0,s4
    800043c6:	ffffd097          	auipc	ra,0xffffd
    800043ca:	968080e7          	jalr	-1688(ra) # 80000d2e <memmove>
    name[len] = 0;
    800043ce:	9cd2                	add	s9,s9,s4
    800043d0:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800043d4:	bf9d                	j	8000434a <namex+0xb8>
  if (nameiparent)
    800043d6:	f20a83e3          	beqz	s5,800042fc <namex+0x6a>
    iput(ip);
    800043da:	854e                	mv	a0,s3
    800043dc:	00000097          	auipc	ra,0x0
    800043e0:	adc080e7          	jalr	-1316(ra) # 80003eb8 <iput>
    return 0;
    800043e4:	4981                	li	s3,0
    800043e6:	bf19                	j	800042fc <namex+0x6a>
  if (*path == 0)
    800043e8:	d7fd                	beqz	a5,800043d6 <namex+0x144>
  while (*path != '/' && *path != 0)
    800043ea:	0004c783          	lbu	a5,0(s1)
    800043ee:	85a6                	mv	a1,s1
    800043f0:	b7d1                	j	800043b4 <namex+0x122>

00000000800043f2 <dirlink>:
{
    800043f2:	7139                	addi	sp,sp,-64
    800043f4:	fc06                	sd	ra,56(sp)
    800043f6:	f822                	sd	s0,48(sp)
    800043f8:	f426                	sd	s1,40(sp)
    800043fa:	f04a                	sd	s2,32(sp)
    800043fc:	ec4e                	sd	s3,24(sp)
    800043fe:	e852                	sd	s4,16(sp)
    80004400:	0080                	addi	s0,sp,64
    80004402:	892a                	mv	s2,a0
    80004404:	8a2e                	mv	s4,a1
    80004406:	89b2                	mv	s3,a2
  if ((ip = dirlookup(dp, name, 0)) != 0)
    80004408:	4601                	li	a2,0
    8000440a:	00000097          	auipc	ra,0x0
    8000440e:	dd8080e7          	jalr	-552(ra) # 800041e2 <dirlookup>
    80004412:	e93d                	bnez	a0,80004488 <dirlink+0x96>
  for (off = 0; off < dp->size; off += sizeof(de))
    80004414:	04c92483          	lw	s1,76(s2)
    80004418:	c49d                	beqz	s1,80004446 <dirlink+0x54>
    8000441a:	4481                	li	s1,0
    if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000441c:	4741                	li	a4,16
    8000441e:	86a6                	mv	a3,s1
    80004420:	fc040613          	addi	a2,s0,-64
    80004424:	4581                	li	a1,0
    80004426:	854a                	mv	a0,s2
    80004428:	00000097          	auipc	ra,0x0
    8000442c:	b8a080e7          	jalr	-1142(ra) # 80003fb2 <readi>
    80004430:	47c1                	li	a5,16
    80004432:	06f51163          	bne	a0,a5,80004494 <dirlink+0xa2>
    if (de.inum == 0)
    80004436:	fc045783          	lhu	a5,-64(s0)
    8000443a:	c791                	beqz	a5,80004446 <dirlink+0x54>
  for (off = 0; off < dp->size; off += sizeof(de))
    8000443c:	24c1                	addiw	s1,s1,16
    8000443e:	04c92783          	lw	a5,76(s2)
    80004442:	fcf4ede3          	bltu	s1,a5,8000441c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004446:	4639                	li	a2,14
    80004448:	85d2                	mv	a1,s4
    8000444a:	fc240513          	addi	a0,s0,-62
    8000444e:	ffffd097          	auipc	ra,0xffffd
    80004452:	990080e7          	jalr	-1648(ra) # 80000dde <strncpy>
  de.inum = inum;
    80004456:	fd341023          	sh	s3,-64(s0)
  if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000445a:	4741                	li	a4,16
    8000445c:	86a6                	mv	a3,s1
    8000445e:	fc040613          	addi	a2,s0,-64
    80004462:	4581                	li	a1,0
    80004464:	854a                	mv	a0,s2
    80004466:	00000097          	auipc	ra,0x0
    8000446a:	c44080e7          	jalr	-956(ra) # 800040aa <writei>
    8000446e:	1541                	addi	a0,a0,-16
    80004470:	00a03533          	snez	a0,a0
    80004474:	40a00533          	neg	a0,a0
}
    80004478:	70e2                	ld	ra,56(sp)
    8000447a:	7442                	ld	s0,48(sp)
    8000447c:	74a2                	ld	s1,40(sp)
    8000447e:	7902                	ld	s2,32(sp)
    80004480:	69e2                	ld	s3,24(sp)
    80004482:	6a42                	ld	s4,16(sp)
    80004484:	6121                	addi	sp,sp,64
    80004486:	8082                	ret
    iput(ip);
    80004488:	00000097          	auipc	ra,0x0
    8000448c:	a30080e7          	jalr	-1488(ra) # 80003eb8 <iput>
    return -1;
    80004490:	557d                	li	a0,-1
    80004492:	b7dd                	j	80004478 <dirlink+0x86>
      panic("dirlink read");
    80004494:	00004517          	auipc	a0,0x4
    80004498:	27c50513          	addi	a0,a0,636 # 80008710 <syscalls+0x1c8>
    8000449c:	ffffc097          	auipc	ra,0xffffc
    800044a0:	0a2080e7          	jalr	162(ra) # 8000053e <panic>

00000000800044a4 <namei>:

struct inode *
namei(char *path)
{
    800044a4:	1101                	addi	sp,sp,-32
    800044a6:	ec06                	sd	ra,24(sp)
    800044a8:	e822                	sd	s0,16(sp)
    800044aa:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800044ac:	fe040613          	addi	a2,s0,-32
    800044b0:	4581                	li	a1,0
    800044b2:	00000097          	auipc	ra,0x0
    800044b6:	de0080e7          	jalr	-544(ra) # 80004292 <namex>
}
    800044ba:	60e2                	ld	ra,24(sp)
    800044bc:	6442                	ld	s0,16(sp)
    800044be:	6105                	addi	sp,sp,32
    800044c0:	8082                	ret

00000000800044c2 <nameiparent>:

struct inode *
nameiparent(char *path, char *name)
{
    800044c2:	1141                	addi	sp,sp,-16
    800044c4:	e406                	sd	ra,8(sp)
    800044c6:	e022                	sd	s0,0(sp)
    800044c8:	0800                	addi	s0,sp,16
    800044ca:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800044cc:	4585                	li	a1,1
    800044ce:	00000097          	auipc	ra,0x0
    800044d2:	dc4080e7          	jalr	-572(ra) # 80004292 <namex>
}
    800044d6:	60a2                	ld	ra,8(sp)
    800044d8:	6402                	ld	s0,0(sp)
    800044da:	0141                	addi	sp,sp,16
    800044dc:	8082                	ret

00000000800044de <itoa>:

#include "fcntl.h"
#define DIGITS 14

char *itoa(int i, char b[])
{
    800044de:	1101                	addi	sp,sp,-32
    800044e0:	ec22                	sd	s0,24(sp)
    800044e2:	1000                	addi	s0,sp,32
    800044e4:	872a                	mv	a4,a0
    800044e6:	852e                	mv	a0,a1
  char const digit[] = "0123456789";
    800044e8:	00004797          	auipc	a5,0x4
    800044ec:	23878793          	addi	a5,a5,568 # 80008720 <syscalls+0x1d8>
    800044f0:	6394                	ld	a3,0(a5)
    800044f2:	fed43023          	sd	a3,-32(s0)
    800044f6:	0087d683          	lhu	a3,8(a5)
    800044fa:	fed41423          	sh	a3,-24(s0)
    800044fe:	00a7c783          	lbu	a5,10(a5)
    80004502:	fef40523          	sb	a5,-22(s0)
  char *p = b;
    80004506:	87ae                	mv	a5,a1
  if (i < 0)
    80004508:	02074b63          	bltz	a4,8000453e <itoa+0x60>
  {
    *p++ = '-';
    i *= -1;
  }
  int shifter = i;
    8000450c:	86ba                	mv	a3,a4
  do
  { // Move to where representation ends
    ++p;
    shifter = shifter / 10;
    8000450e:	4629                	li	a2,10
    ++p;
    80004510:	0785                	addi	a5,a5,1
    shifter = shifter / 10;
    80004512:	02c6c6bb          	divw	a3,a3,a2
  } while (shifter);
    80004516:	feed                	bnez	a3,80004510 <itoa+0x32>
  *p = '\0';
    80004518:	00078023          	sb	zero,0(a5)
  do
  { // Move back, inserting digits as u go
    *--p = digit[i % 10];
    8000451c:	4629                	li	a2,10
    8000451e:	17fd                	addi	a5,a5,-1
    80004520:	02c766bb          	remw	a3,a4,a2
    80004524:	ff040593          	addi	a1,s0,-16
    80004528:	96ae                	add	a3,a3,a1
    8000452a:	ff06c683          	lbu	a3,-16(a3)
    8000452e:	00d78023          	sb	a3,0(a5)
    i = i / 10;
    80004532:	02c7473b          	divw	a4,a4,a2
  } while (i);
    80004536:	f765                	bnez	a4,8000451e <itoa+0x40>
  return b;
}
    80004538:	6462                	ld	s0,24(sp)
    8000453a:	6105                	addi	sp,sp,32
    8000453c:	8082                	ret
    *p++ = '-';
    8000453e:	00158793          	addi	a5,a1,1
    80004542:	02d00693          	li	a3,45
    80004546:	00d58023          	sb	a3,0(a1)
    i *= -1;
    8000454a:	40e0073b          	negw	a4,a4
    8000454e:	bf7d                	j	8000450c <itoa+0x2e>

0000000080004550 <removeSwapFile>:
// remove swap file of proc p;
int removeSwapFile(struct proc *p)
{
    80004550:	711d                	addi	sp,sp,-96
    80004552:	ec86                	sd	ra,88(sp)
    80004554:	e8a2                	sd	s0,80(sp)
    80004556:	e4a6                	sd	s1,72(sp)
    80004558:	e0ca                	sd	s2,64(sp)
    8000455a:	1080                	addi	s0,sp,96
    8000455c:	84aa                	mv	s1,a0
  // path of proccess
  char path[DIGITS];
  memmove(path, "/.swap", 6);
    8000455e:	4619                	li	a2,6
    80004560:	00004597          	auipc	a1,0x4
    80004564:	1d058593          	addi	a1,a1,464 # 80008730 <syscalls+0x1e8>
    80004568:	fd040513          	addi	a0,s0,-48
    8000456c:	ffffc097          	auipc	ra,0xffffc
    80004570:	7c2080e7          	jalr	1986(ra) # 80000d2e <memmove>
  itoa(p->pid, path + 6);
    80004574:	fd640593          	addi	a1,s0,-42
    80004578:	5888                	lw	a0,48(s1)
    8000457a:	00000097          	auipc	ra,0x0
    8000457e:	f64080e7          	jalr	-156(ra) # 800044de <itoa>
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ];
  uint off;

  if (0 == p->swapFile)
    80004582:	1684b503          	ld	a0,360(s1)
    80004586:	16050763          	beqz	a0,800046f4 <removeSwapFile+0x1a4>
  {
    return -1;
  }
  fileclose(p->swapFile);
    8000458a:	00001097          	auipc	ra,0x1
    8000458e:	950080e7          	jalr	-1712(ra) # 80004eda <fileclose>

  begin_op();
    80004592:	00000097          	auipc	ra,0x0
    80004596:	47c080e7          	jalr	1148(ra) # 80004a0e <begin_op>
  if ((dp = nameiparent(path, name)) == 0)
    8000459a:	fb040593          	addi	a1,s0,-80
    8000459e:	fd040513          	addi	a0,s0,-48
    800045a2:	00000097          	auipc	ra,0x0
    800045a6:	f20080e7          	jalr	-224(ra) # 800044c2 <nameiparent>
    800045aa:	892a                	mv	s2,a0
    800045ac:	cd69                	beqz	a0,80004686 <removeSwapFile+0x136>
  {
    end_op();
    return -1;
  }

  ilock(dp);
    800045ae:	fffff097          	auipc	ra,0xfffff
    800045b2:	750080e7          	jalr	1872(ra) # 80003cfe <ilock>

  // Cannot unlink "." or "..".
  if (namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800045b6:	00004597          	auipc	a1,0x4
    800045ba:	18258593          	addi	a1,a1,386 # 80008738 <syscalls+0x1f0>
    800045be:	fb040513          	addi	a0,s0,-80
    800045c2:	00000097          	auipc	ra,0x0
    800045c6:	c06080e7          	jalr	-1018(ra) # 800041c8 <namecmp>
    800045ca:	c57d                	beqz	a0,800046b8 <removeSwapFile+0x168>
    800045cc:	00004597          	auipc	a1,0x4
    800045d0:	17458593          	addi	a1,a1,372 # 80008740 <syscalls+0x1f8>
    800045d4:	fb040513          	addi	a0,s0,-80
    800045d8:	00000097          	auipc	ra,0x0
    800045dc:	bf0080e7          	jalr	-1040(ra) # 800041c8 <namecmp>
    800045e0:	cd61                	beqz	a0,800046b8 <removeSwapFile+0x168>
    goto bad;

  if ((ip = dirlookup(dp, name, &off)) == 0)
    800045e2:	fac40613          	addi	a2,s0,-84
    800045e6:	fb040593          	addi	a1,s0,-80
    800045ea:	854a                	mv	a0,s2
    800045ec:	00000097          	auipc	ra,0x0
    800045f0:	bf6080e7          	jalr	-1034(ra) # 800041e2 <dirlookup>
    800045f4:	84aa                	mv	s1,a0
    800045f6:	c169                	beqz	a0,800046b8 <removeSwapFile+0x168>
    goto bad;
  ilock(ip);
    800045f8:	fffff097          	auipc	ra,0xfffff
    800045fc:	706080e7          	jalr	1798(ra) # 80003cfe <ilock>

  if (ip->nlink < 1)
    80004600:	04a49783          	lh	a5,74(s1)
    80004604:	08f05763          	blez	a5,80004692 <removeSwapFile+0x142>
    panic("unlink: nlink < 1");
  if (ip->type == T_DIR && !isdirempty(ip))
    80004608:	04449703          	lh	a4,68(s1)
    8000460c:	4785                	li	a5,1
    8000460e:	08f70a63          	beq	a4,a5,800046a2 <removeSwapFile+0x152>
  {
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    80004612:	4641                	li	a2,16
    80004614:	4581                	li	a1,0
    80004616:	fc040513          	addi	a0,s0,-64
    8000461a:	ffffc097          	auipc	ra,0xffffc
    8000461e:	6b8080e7          	jalr	1720(ra) # 80000cd2 <memset>
  if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004622:	4741                	li	a4,16
    80004624:	fac42683          	lw	a3,-84(s0)
    80004628:	fc040613          	addi	a2,s0,-64
    8000462c:	4581                	li	a1,0
    8000462e:	854a                	mv	a0,s2
    80004630:	00000097          	auipc	ra,0x0
    80004634:	a7a080e7          	jalr	-1414(ra) # 800040aa <writei>
    80004638:	47c1                	li	a5,16
    8000463a:	08f51a63          	bne	a0,a5,800046ce <removeSwapFile+0x17e>
    panic("unlink: writei");
  if (ip->type == T_DIR)
    8000463e:	04449703          	lh	a4,68(s1)
    80004642:	4785                	li	a5,1
    80004644:	08f70d63          	beq	a4,a5,800046de <removeSwapFile+0x18e>
  {
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    80004648:	854a                	mv	a0,s2
    8000464a:	00000097          	auipc	ra,0x0
    8000464e:	916080e7          	jalr	-1770(ra) # 80003f60 <iunlockput>

  ip->nlink--;
    80004652:	04a4d783          	lhu	a5,74(s1)
    80004656:	37fd                	addiw	a5,a5,-1
    80004658:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000465c:	8526                	mv	a0,s1
    8000465e:	fffff097          	auipc	ra,0xfffff
    80004662:	5d6080e7          	jalr	1494(ra) # 80003c34 <iupdate>
  iunlockput(ip);
    80004666:	8526                	mv	a0,s1
    80004668:	00000097          	auipc	ra,0x0
    8000466c:	8f8080e7          	jalr	-1800(ra) # 80003f60 <iunlockput>

  end_op();
    80004670:	00000097          	auipc	ra,0x0
    80004674:	41e080e7          	jalr	1054(ra) # 80004a8e <end_op>

  return 0;
    80004678:	4501                	li	a0,0

bad:
  iunlockput(dp);
  end_op();
  return -1;
}
    8000467a:	60e6                	ld	ra,88(sp)
    8000467c:	6446                	ld	s0,80(sp)
    8000467e:	64a6                	ld	s1,72(sp)
    80004680:	6906                	ld	s2,64(sp)
    80004682:	6125                	addi	sp,sp,96
    80004684:	8082                	ret
    end_op();
    80004686:	00000097          	auipc	ra,0x0
    8000468a:	408080e7          	jalr	1032(ra) # 80004a8e <end_op>
    return -1;
    8000468e:	557d                	li	a0,-1
    80004690:	b7ed                	j	8000467a <removeSwapFile+0x12a>
    panic("unlink: nlink < 1");
    80004692:	00004517          	auipc	a0,0x4
    80004696:	0b650513          	addi	a0,a0,182 # 80008748 <syscalls+0x200>
    8000469a:	ffffc097          	auipc	ra,0xffffc
    8000469e:	ea4080e7          	jalr	-348(ra) # 8000053e <panic>
  if (ip->type == T_DIR && !isdirempty(ip))
    800046a2:	8526                	mv	a0,s1
    800046a4:	00002097          	auipc	ra,0x2
    800046a8:	8e2080e7          	jalr	-1822(ra) # 80005f86 <isdirempty>
    800046ac:	f13d                	bnez	a0,80004612 <removeSwapFile+0xc2>
    iunlockput(ip);
    800046ae:	8526                	mv	a0,s1
    800046b0:	00000097          	auipc	ra,0x0
    800046b4:	8b0080e7          	jalr	-1872(ra) # 80003f60 <iunlockput>
  iunlockput(dp);
    800046b8:	854a                	mv	a0,s2
    800046ba:	00000097          	auipc	ra,0x0
    800046be:	8a6080e7          	jalr	-1882(ra) # 80003f60 <iunlockput>
  end_op();
    800046c2:	00000097          	auipc	ra,0x0
    800046c6:	3cc080e7          	jalr	972(ra) # 80004a8e <end_op>
  return -1;
    800046ca:	557d                	li	a0,-1
    800046cc:	b77d                	j	8000467a <removeSwapFile+0x12a>
    panic("unlink: writei");
    800046ce:	00004517          	auipc	a0,0x4
    800046d2:	09250513          	addi	a0,a0,146 # 80008760 <syscalls+0x218>
    800046d6:	ffffc097          	auipc	ra,0xffffc
    800046da:	e68080e7          	jalr	-408(ra) # 8000053e <panic>
    dp->nlink--;
    800046de:	04a95783          	lhu	a5,74(s2)
    800046e2:	37fd                	addiw	a5,a5,-1
    800046e4:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800046e8:	854a                	mv	a0,s2
    800046ea:	fffff097          	auipc	ra,0xfffff
    800046ee:	54a080e7          	jalr	1354(ra) # 80003c34 <iupdate>
    800046f2:	bf99                	j	80004648 <removeSwapFile+0xf8>
    return -1;
    800046f4:	557d                	li	a0,-1
    800046f6:	b751                	j	8000467a <removeSwapFile+0x12a>

00000000800046f8 <createSwapFile>:

// return 0 on success
int createSwapFile(struct proc *p)
{
    800046f8:	7179                	addi	sp,sp,-48
    800046fa:	f406                	sd	ra,40(sp)
    800046fc:	f022                	sd	s0,32(sp)
    800046fe:	ec26                	sd	s1,24(sp)
    80004700:	e84a                	sd	s2,16(sp)
    80004702:	1800                	addi	s0,sp,48
    80004704:	84aa                	mv	s1,a0

  char path[DIGITS];
  memmove(path, "/.swap", 6);
    80004706:	4619                	li	a2,6
    80004708:	00004597          	auipc	a1,0x4
    8000470c:	02858593          	addi	a1,a1,40 # 80008730 <syscalls+0x1e8>
    80004710:	fd040513          	addi	a0,s0,-48
    80004714:	ffffc097          	auipc	ra,0xffffc
    80004718:	61a080e7          	jalr	1562(ra) # 80000d2e <memmove>
  itoa(p->pid, path + 6);
    8000471c:	fd640593          	addi	a1,s0,-42
    80004720:	5888                	lw	a0,48(s1)
    80004722:	00000097          	auipc	ra,0x0
    80004726:	dbc080e7          	jalr	-580(ra) # 800044de <itoa>

  begin_op();
    8000472a:	00000097          	auipc	ra,0x0
    8000472e:	2e4080e7          	jalr	740(ra) # 80004a0e <begin_op>

  struct inode *in = create(path, T_FILE, 0, 0);
    80004732:	4681                	li	a3,0
    80004734:	4601                	li	a2,0
    80004736:	4589                	li	a1,2
    80004738:	fd040513          	addi	a0,s0,-48
    8000473c:	00002097          	auipc	ra,0x2
    80004740:	a3e080e7          	jalr	-1474(ra) # 8000617a <create>
    80004744:	892a                	mv	s2,a0
  iunlock(in);
    80004746:	fffff097          	auipc	ra,0xfffff
    8000474a:	67a080e7          	jalr	1658(ra) # 80003dc0 <iunlock>
  p->swapFile = filealloc();
    8000474e:	00000097          	auipc	ra,0x0
    80004752:	6d0080e7          	jalr	1744(ra) # 80004e1e <filealloc>
    80004756:	16a4b423          	sd	a0,360(s1)
  if (p->swapFile == 0)
    8000475a:	cd1d                	beqz	a0,80004798 <createSwapFile+0xa0>
    panic("no slot for files on /store");

  p->swapFile->ip = in;
    8000475c:	01253c23          	sd	s2,24(a0)
  p->swapFile->type = FD_INODE;
    80004760:	1684b703          	ld	a4,360(s1)
    80004764:	4789                	li	a5,2
    80004766:	c31c                	sw	a5,0(a4)
  p->swapFile->off = 0;
    80004768:	1684b703          	ld	a4,360(s1)
    8000476c:	02072023          	sw	zero,32(a4) # 43020 <_entry-0x7ffbcfe0>
  p->swapFile->readable = O_WRONLY;
    80004770:	1684b703          	ld	a4,360(s1)
    80004774:	4685                	li	a3,1
    80004776:	00d70423          	sb	a3,8(a4)
  p->swapFile->writable = O_RDWR;
    8000477a:	1684b703          	ld	a4,360(s1)
    8000477e:	00f704a3          	sb	a5,9(a4)
  end_op();
    80004782:	00000097          	auipc	ra,0x0
    80004786:	30c080e7          	jalr	780(ra) # 80004a8e <end_op>

  return 0;
}
    8000478a:	4501                	li	a0,0
    8000478c:	70a2                	ld	ra,40(sp)
    8000478e:	7402                	ld	s0,32(sp)
    80004790:	64e2                	ld	s1,24(sp)
    80004792:	6942                	ld	s2,16(sp)
    80004794:	6145                	addi	sp,sp,48
    80004796:	8082                	ret
    panic("no slot for files on /store");
    80004798:	00004517          	auipc	a0,0x4
    8000479c:	fd850513          	addi	a0,a0,-40 # 80008770 <syscalls+0x228>
    800047a0:	ffffc097          	auipc	ra,0xffffc
    800047a4:	d9e080e7          	jalr	-610(ra) # 8000053e <panic>

00000000800047a8 <writeToSwapFile>:

// return as sys_write (-1 when error)
int writeToSwapFile(struct proc *p, char *buffer, uint placeOnFile, uint size)
{
    800047a8:	7179                	addi	sp,sp,-48
    800047aa:	f406                	sd	ra,40(sp)
    800047ac:	f022                	sd	s0,32(sp)
    800047ae:	ec26                	sd	s1,24(sp)
    800047b0:	e84a                	sd	s2,16(sp)
    800047b2:	e44e                	sd	s3,8(sp)
    800047b4:	e052                	sd	s4,0(sp)
    800047b6:	1800                	addi	s0,sp,48
    800047b8:	84aa                	mv	s1,a0
    800047ba:	892e                	mv	s2,a1
    800047bc:	8a32                	mv	s4,a2
    800047be:	89b6                	mv	s3,a3
  printf("8here\n");
    800047c0:	00004517          	auipc	a0,0x4
    800047c4:	fd050513          	addi	a0,a0,-48 # 80008790 <syscalls+0x248>
    800047c8:	ffffc097          	auipc	ra,0xffffc
    800047cc:	dc0080e7          	jalr	-576(ra) # 80000588 <printf>
  p->swapFile->off = placeOnFile;
    800047d0:	1684b783          	ld	a5,360(s1)
    800047d4:	0347a023          	sw	s4,32(a5)
    printf("9here\n");
    800047d8:	00004517          	auipc	a0,0x4
    800047dc:	fc050513          	addi	a0,a0,-64 # 80008798 <syscalls+0x250>
    800047e0:	ffffc097          	auipc	ra,0xffffc
    800047e4:	da8080e7          	jalr	-600(ra) # 80000588 <printf>

  return kfilewrite(p->swapFile, (uint64)buffer, size);
    800047e8:	864e                	mv	a2,s3
    800047ea:	85ca                	mv	a1,s2
    800047ec:	1684b503          	ld	a0,360(s1)
    800047f0:	00001097          	auipc	ra,0x1
    800047f4:	adc080e7          	jalr	-1316(ra) # 800052cc <kfilewrite>
}
    800047f8:	70a2                	ld	ra,40(sp)
    800047fa:	7402                	ld	s0,32(sp)
    800047fc:	64e2                	ld	s1,24(sp)
    800047fe:	6942                	ld	s2,16(sp)
    80004800:	69a2                	ld	s3,8(sp)
    80004802:	6a02                	ld	s4,0(sp)
    80004804:	6145                	addi	sp,sp,48
    80004806:	8082                	ret

0000000080004808 <readFromSwapFile>:

// return as sys_read (-1 when error)
int readFromSwapFile(struct proc *p, char *buffer, uint placeOnFile, uint size)
{
    80004808:	1141                	addi	sp,sp,-16
    8000480a:	e406                	sd	ra,8(sp)
    8000480c:	e022                	sd	s0,0(sp)
    8000480e:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    80004810:	16853783          	ld	a5,360(a0)
    80004814:	d390                	sw	a2,32(a5)
  return kfileread(p->swapFile, (uint64)buffer, size);
    80004816:	8636                	mv	a2,a3
    80004818:	16853503          	ld	a0,360(a0)
    8000481c:	00001097          	auipc	ra,0x1
    80004820:	9ee080e7          	jalr	-1554(ra) # 8000520a <kfileread>
    80004824:	60a2                	ld	ra,8(sp)
    80004826:	6402                	ld	s0,0(sp)
    80004828:	0141                	addi	sp,sp,16
    8000482a:	8082                	ret

000000008000482c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000482c:	1101                	addi	sp,sp,-32
    8000482e:	ec06                	sd	ra,24(sp)
    80004830:	e822                	sd	s0,16(sp)
    80004832:	e426                	sd	s1,8(sp)
    80004834:	e04a                	sd	s2,0(sp)
    80004836:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004838:	00031917          	auipc	s2,0x31
    8000483c:	c5890913          	addi	s2,s2,-936 # 80035490 <log>
    80004840:	01892583          	lw	a1,24(s2)
    80004844:	02892503          	lw	a0,40(s2)
    80004848:	fffff097          	auipc	ra,0xfffff
    8000484c:	c9c080e7          	jalr	-868(ra) # 800034e4 <bread>
    80004850:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004852:	02c92683          	lw	a3,44(s2)
    80004856:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004858:	02d05763          	blez	a3,80004886 <write_head+0x5a>
    8000485c:	00031797          	auipc	a5,0x31
    80004860:	c6478793          	addi	a5,a5,-924 # 800354c0 <log+0x30>
    80004864:	05c50713          	addi	a4,a0,92
    80004868:	36fd                	addiw	a3,a3,-1
    8000486a:	1682                	slli	a3,a3,0x20
    8000486c:	9281                	srli	a3,a3,0x20
    8000486e:	068a                	slli	a3,a3,0x2
    80004870:	00031617          	auipc	a2,0x31
    80004874:	c5460613          	addi	a2,a2,-940 # 800354c4 <log+0x34>
    80004878:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000487a:	4390                	lw	a2,0(a5)
    8000487c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000487e:	0791                	addi	a5,a5,4
    80004880:	0711                	addi	a4,a4,4
    80004882:	fed79ce3          	bne	a5,a3,8000487a <write_head+0x4e>
  }
  bwrite(buf);
    80004886:	8526                	mv	a0,s1
    80004888:	fffff097          	auipc	ra,0xfffff
    8000488c:	d4e080e7          	jalr	-690(ra) # 800035d6 <bwrite>
  brelse(buf);
    80004890:	8526                	mv	a0,s1
    80004892:	fffff097          	auipc	ra,0xfffff
    80004896:	d82080e7          	jalr	-638(ra) # 80003614 <brelse>
}
    8000489a:	60e2                	ld	ra,24(sp)
    8000489c:	6442                	ld	s0,16(sp)
    8000489e:	64a2                	ld	s1,8(sp)
    800048a0:	6902                	ld	s2,0(sp)
    800048a2:	6105                	addi	sp,sp,32
    800048a4:	8082                	ret

00000000800048a6 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800048a6:	00031797          	auipc	a5,0x31
    800048aa:	c167a783          	lw	a5,-1002(a5) # 800354bc <log+0x2c>
    800048ae:	0af05d63          	blez	a5,80004968 <install_trans+0xc2>
{
    800048b2:	7139                	addi	sp,sp,-64
    800048b4:	fc06                	sd	ra,56(sp)
    800048b6:	f822                	sd	s0,48(sp)
    800048b8:	f426                	sd	s1,40(sp)
    800048ba:	f04a                	sd	s2,32(sp)
    800048bc:	ec4e                	sd	s3,24(sp)
    800048be:	e852                	sd	s4,16(sp)
    800048c0:	e456                	sd	s5,8(sp)
    800048c2:	e05a                	sd	s6,0(sp)
    800048c4:	0080                	addi	s0,sp,64
    800048c6:	8b2a                	mv	s6,a0
    800048c8:	00031a97          	auipc	s5,0x31
    800048cc:	bf8a8a93          	addi	s5,s5,-1032 # 800354c0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048d0:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800048d2:	00031997          	auipc	s3,0x31
    800048d6:	bbe98993          	addi	s3,s3,-1090 # 80035490 <log>
    800048da:	a00d                	j	800048fc <install_trans+0x56>
    brelse(lbuf);
    800048dc:	854a                	mv	a0,s2
    800048de:	fffff097          	auipc	ra,0xfffff
    800048e2:	d36080e7          	jalr	-714(ra) # 80003614 <brelse>
    brelse(dbuf);
    800048e6:	8526                	mv	a0,s1
    800048e8:	fffff097          	auipc	ra,0xfffff
    800048ec:	d2c080e7          	jalr	-724(ra) # 80003614 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048f0:	2a05                	addiw	s4,s4,1
    800048f2:	0a91                	addi	s5,s5,4
    800048f4:	02c9a783          	lw	a5,44(s3)
    800048f8:	04fa5e63          	bge	s4,a5,80004954 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800048fc:	0189a583          	lw	a1,24(s3)
    80004900:	014585bb          	addw	a1,a1,s4
    80004904:	2585                	addiw	a1,a1,1
    80004906:	0289a503          	lw	a0,40(s3)
    8000490a:	fffff097          	auipc	ra,0xfffff
    8000490e:	bda080e7          	jalr	-1062(ra) # 800034e4 <bread>
    80004912:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004914:	000aa583          	lw	a1,0(s5)
    80004918:	0289a503          	lw	a0,40(s3)
    8000491c:	fffff097          	auipc	ra,0xfffff
    80004920:	bc8080e7          	jalr	-1080(ra) # 800034e4 <bread>
    80004924:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004926:	40000613          	li	a2,1024
    8000492a:	05890593          	addi	a1,s2,88
    8000492e:	05850513          	addi	a0,a0,88
    80004932:	ffffc097          	auipc	ra,0xffffc
    80004936:	3fc080e7          	jalr	1020(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    8000493a:	8526                	mv	a0,s1
    8000493c:	fffff097          	auipc	ra,0xfffff
    80004940:	c9a080e7          	jalr	-870(ra) # 800035d6 <bwrite>
    if(recovering == 0)
    80004944:	f80b1ce3          	bnez	s6,800048dc <install_trans+0x36>
      bunpin(dbuf);
    80004948:	8526                	mv	a0,s1
    8000494a:	fffff097          	auipc	ra,0xfffff
    8000494e:	da4080e7          	jalr	-604(ra) # 800036ee <bunpin>
    80004952:	b769                	j	800048dc <install_trans+0x36>
}
    80004954:	70e2                	ld	ra,56(sp)
    80004956:	7442                	ld	s0,48(sp)
    80004958:	74a2                	ld	s1,40(sp)
    8000495a:	7902                	ld	s2,32(sp)
    8000495c:	69e2                	ld	s3,24(sp)
    8000495e:	6a42                	ld	s4,16(sp)
    80004960:	6aa2                	ld	s5,8(sp)
    80004962:	6b02                	ld	s6,0(sp)
    80004964:	6121                	addi	sp,sp,64
    80004966:	8082                	ret
    80004968:	8082                	ret

000000008000496a <initlog>:
{
    8000496a:	7179                	addi	sp,sp,-48
    8000496c:	f406                	sd	ra,40(sp)
    8000496e:	f022                	sd	s0,32(sp)
    80004970:	ec26                	sd	s1,24(sp)
    80004972:	e84a                	sd	s2,16(sp)
    80004974:	e44e                	sd	s3,8(sp)
    80004976:	1800                	addi	s0,sp,48
    80004978:	892a                	mv	s2,a0
    8000497a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000497c:	00031497          	auipc	s1,0x31
    80004980:	b1448493          	addi	s1,s1,-1260 # 80035490 <log>
    80004984:	00004597          	auipc	a1,0x4
    80004988:	e1c58593          	addi	a1,a1,-484 # 800087a0 <syscalls+0x258>
    8000498c:	8526                	mv	a0,s1
    8000498e:	ffffc097          	auipc	ra,0xffffc
    80004992:	1b8080e7          	jalr	440(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004996:	0149a583          	lw	a1,20(s3)
    8000499a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000499c:	0109a783          	lw	a5,16(s3)
    800049a0:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800049a2:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800049a6:	854a                	mv	a0,s2
    800049a8:	fffff097          	auipc	ra,0xfffff
    800049ac:	b3c080e7          	jalr	-1220(ra) # 800034e4 <bread>
  log.lh.n = lh->n;
    800049b0:	4d34                	lw	a3,88(a0)
    800049b2:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800049b4:	02d05563          	blez	a3,800049de <initlog+0x74>
    800049b8:	05c50793          	addi	a5,a0,92
    800049bc:	00031717          	auipc	a4,0x31
    800049c0:	b0470713          	addi	a4,a4,-1276 # 800354c0 <log+0x30>
    800049c4:	36fd                	addiw	a3,a3,-1
    800049c6:	1682                	slli	a3,a3,0x20
    800049c8:	9281                	srli	a3,a3,0x20
    800049ca:	068a                	slli	a3,a3,0x2
    800049cc:	06050613          	addi	a2,a0,96
    800049d0:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800049d2:	4390                	lw	a2,0(a5)
    800049d4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800049d6:	0791                	addi	a5,a5,4
    800049d8:	0711                	addi	a4,a4,4
    800049da:	fed79ce3          	bne	a5,a3,800049d2 <initlog+0x68>
  brelse(buf);
    800049de:	fffff097          	auipc	ra,0xfffff
    800049e2:	c36080e7          	jalr	-970(ra) # 80003614 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800049e6:	4505                	li	a0,1
    800049e8:	00000097          	auipc	ra,0x0
    800049ec:	ebe080e7          	jalr	-322(ra) # 800048a6 <install_trans>
  log.lh.n = 0;
    800049f0:	00031797          	auipc	a5,0x31
    800049f4:	ac07a623          	sw	zero,-1332(a5) # 800354bc <log+0x2c>
  write_head(); // clear the log
    800049f8:	00000097          	auipc	ra,0x0
    800049fc:	e34080e7          	jalr	-460(ra) # 8000482c <write_head>
}
    80004a00:	70a2                	ld	ra,40(sp)
    80004a02:	7402                	ld	s0,32(sp)
    80004a04:	64e2                	ld	s1,24(sp)
    80004a06:	6942                	ld	s2,16(sp)
    80004a08:	69a2                	ld	s3,8(sp)
    80004a0a:	6145                	addi	sp,sp,48
    80004a0c:	8082                	ret

0000000080004a0e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004a0e:	1101                	addi	sp,sp,-32
    80004a10:	ec06                	sd	ra,24(sp)
    80004a12:	e822                	sd	s0,16(sp)
    80004a14:	e426                	sd	s1,8(sp)
    80004a16:	e04a                	sd	s2,0(sp)
    80004a18:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004a1a:	00031517          	auipc	a0,0x31
    80004a1e:	a7650513          	addi	a0,a0,-1418 # 80035490 <log>
    80004a22:	ffffc097          	auipc	ra,0xffffc
    80004a26:	1b4080e7          	jalr	436(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004a2a:	00031497          	auipc	s1,0x31
    80004a2e:	a6648493          	addi	s1,s1,-1434 # 80035490 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004a32:	4979                	li	s2,30
    80004a34:	a039                	j	80004a42 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004a36:	85a6                	mv	a1,s1
    80004a38:	8526                	mv	a0,s1
    80004a3a:	ffffe097          	auipc	ra,0xffffe
    80004a3e:	822080e7          	jalr	-2014(ra) # 8000225c <sleep>
    if(log.committing){
    80004a42:	50dc                	lw	a5,36(s1)
    80004a44:	fbed                	bnez	a5,80004a36 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004a46:	509c                	lw	a5,32(s1)
    80004a48:	0017871b          	addiw	a4,a5,1
    80004a4c:	0007069b          	sext.w	a3,a4
    80004a50:	0027179b          	slliw	a5,a4,0x2
    80004a54:	9fb9                	addw	a5,a5,a4
    80004a56:	0017979b          	slliw	a5,a5,0x1
    80004a5a:	54d8                	lw	a4,44(s1)
    80004a5c:	9fb9                	addw	a5,a5,a4
    80004a5e:	00f95963          	bge	s2,a5,80004a70 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004a62:	85a6                	mv	a1,s1
    80004a64:	8526                	mv	a0,s1
    80004a66:	ffffd097          	auipc	ra,0xffffd
    80004a6a:	7f6080e7          	jalr	2038(ra) # 8000225c <sleep>
    80004a6e:	bfd1                	j	80004a42 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004a70:	00031517          	auipc	a0,0x31
    80004a74:	a2050513          	addi	a0,a0,-1504 # 80035490 <log>
    80004a78:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004a7a:	ffffc097          	auipc	ra,0xffffc
    80004a7e:	210080e7          	jalr	528(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004a82:	60e2                	ld	ra,24(sp)
    80004a84:	6442                	ld	s0,16(sp)
    80004a86:	64a2                	ld	s1,8(sp)
    80004a88:	6902                	ld	s2,0(sp)
    80004a8a:	6105                	addi	sp,sp,32
    80004a8c:	8082                	ret

0000000080004a8e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004a8e:	7139                	addi	sp,sp,-64
    80004a90:	fc06                	sd	ra,56(sp)
    80004a92:	f822                	sd	s0,48(sp)
    80004a94:	f426                	sd	s1,40(sp)
    80004a96:	f04a                	sd	s2,32(sp)
    80004a98:	ec4e                	sd	s3,24(sp)
    80004a9a:	e852                	sd	s4,16(sp)
    80004a9c:	e456                	sd	s5,8(sp)
    80004a9e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004aa0:	00031497          	auipc	s1,0x31
    80004aa4:	9f048493          	addi	s1,s1,-1552 # 80035490 <log>
    80004aa8:	8526                	mv	a0,s1
    80004aaa:	ffffc097          	auipc	ra,0xffffc
    80004aae:	12c080e7          	jalr	300(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004ab2:	509c                	lw	a5,32(s1)
    80004ab4:	37fd                	addiw	a5,a5,-1
    80004ab6:	0007891b          	sext.w	s2,a5
    80004aba:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004abc:	50dc                	lw	a5,36(s1)
    80004abe:	e7b9                	bnez	a5,80004b0c <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004ac0:	04091e63          	bnez	s2,80004b1c <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004ac4:	00031497          	auipc	s1,0x31
    80004ac8:	9cc48493          	addi	s1,s1,-1588 # 80035490 <log>
    80004acc:	4785                	li	a5,1
    80004ace:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004ad0:	8526                	mv	a0,s1
    80004ad2:	ffffc097          	auipc	ra,0xffffc
    80004ad6:	1b8080e7          	jalr	440(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004ada:	54dc                	lw	a5,44(s1)
    80004adc:	06f04763          	bgtz	a5,80004b4a <end_op+0xbc>
    acquire(&log.lock);
    80004ae0:	00031497          	auipc	s1,0x31
    80004ae4:	9b048493          	addi	s1,s1,-1616 # 80035490 <log>
    80004ae8:	8526                	mv	a0,s1
    80004aea:	ffffc097          	auipc	ra,0xffffc
    80004aee:	0ec080e7          	jalr	236(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004af2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004af6:	8526                	mv	a0,s1
    80004af8:	ffffd097          	auipc	ra,0xffffd
    80004afc:	7c8080e7          	jalr	1992(ra) # 800022c0 <wakeup>
    release(&log.lock);
    80004b00:	8526                	mv	a0,s1
    80004b02:	ffffc097          	auipc	ra,0xffffc
    80004b06:	188080e7          	jalr	392(ra) # 80000c8a <release>
}
    80004b0a:	a03d                	j	80004b38 <end_op+0xaa>
    panic("log.committing");
    80004b0c:	00004517          	auipc	a0,0x4
    80004b10:	c9c50513          	addi	a0,a0,-868 # 800087a8 <syscalls+0x260>
    80004b14:	ffffc097          	auipc	ra,0xffffc
    80004b18:	a2a080e7          	jalr	-1494(ra) # 8000053e <panic>
    wakeup(&log);
    80004b1c:	00031497          	auipc	s1,0x31
    80004b20:	97448493          	addi	s1,s1,-1676 # 80035490 <log>
    80004b24:	8526                	mv	a0,s1
    80004b26:	ffffd097          	auipc	ra,0xffffd
    80004b2a:	79a080e7          	jalr	1946(ra) # 800022c0 <wakeup>
  release(&log.lock);
    80004b2e:	8526                	mv	a0,s1
    80004b30:	ffffc097          	auipc	ra,0xffffc
    80004b34:	15a080e7          	jalr	346(ra) # 80000c8a <release>
}
    80004b38:	70e2                	ld	ra,56(sp)
    80004b3a:	7442                	ld	s0,48(sp)
    80004b3c:	74a2                	ld	s1,40(sp)
    80004b3e:	7902                	ld	s2,32(sp)
    80004b40:	69e2                	ld	s3,24(sp)
    80004b42:	6a42                	ld	s4,16(sp)
    80004b44:	6aa2                	ld	s5,8(sp)
    80004b46:	6121                	addi	sp,sp,64
    80004b48:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b4a:	00031a97          	auipc	s5,0x31
    80004b4e:	976a8a93          	addi	s5,s5,-1674 # 800354c0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004b52:	00031a17          	auipc	s4,0x31
    80004b56:	93ea0a13          	addi	s4,s4,-1730 # 80035490 <log>
    80004b5a:	018a2583          	lw	a1,24(s4)
    80004b5e:	012585bb          	addw	a1,a1,s2
    80004b62:	2585                	addiw	a1,a1,1
    80004b64:	028a2503          	lw	a0,40(s4)
    80004b68:	fffff097          	auipc	ra,0xfffff
    80004b6c:	97c080e7          	jalr	-1668(ra) # 800034e4 <bread>
    80004b70:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004b72:	000aa583          	lw	a1,0(s5)
    80004b76:	028a2503          	lw	a0,40(s4)
    80004b7a:	fffff097          	auipc	ra,0xfffff
    80004b7e:	96a080e7          	jalr	-1686(ra) # 800034e4 <bread>
    80004b82:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004b84:	40000613          	li	a2,1024
    80004b88:	05850593          	addi	a1,a0,88
    80004b8c:	05848513          	addi	a0,s1,88
    80004b90:	ffffc097          	auipc	ra,0xffffc
    80004b94:	19e080e7          	jalr	414(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004b98:	8526                	mv	a0,s1
    80004b9a:	fffff097          	auipc	ra,0xfffff
    80004b9e:	a3c080e7          	jalr	-1476(ra) # 800035d6 <bwrite>
    brelse(from);
    80004ba2:	854e                	mv	a0,s3
    80004ba4:	fffff097          	auipc	ra,0xfffff
    80004ba8:	a70080e7          	jalr	-1424(ra) # 80003614 <brelse>
    brelse(to);
    80004bac:	8526                	mv	a0,s1
    80004bae:	fffff097          	auipc	ra,0xfffff
    80004bb2:	a66080e7          	jalr	-1434(ra) # 80003614 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004bb6:	2905                	addiw	s2,s2,1
    80004bb8:	0a91                	addi	s5,s5,4
    80004bba:	02ca2783          	lw	a5,44(s4)
    80004bbe:	f8f94ee3          	blt	s2,a5,80004b5a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004bc2:	00000097          	auipc	ra,0x0
    80004bc6:	c6a080e7          	jalr	-918(ra) # 8000482c <write_head>
    install_trans(0); // Now install writes to home locations
    80004bca:	4501                	li	a0,0
    80004bcc:	00000097          	auipc	ra,0x0
    80004bd0:	cda080e7          	jalr	-806(ra) # 800048a6 <install_trans>
    log.lh.n = 0;
    80004bd4:	00031797          	auipc	a5,0x31
    80004bd8:	8e07a423          	sw	zero,-1816(a5) # 800354bc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004bdc:	00000097          	auipc	ra,0x0
    80004be0:	c50080e7          	jalr	-944(ra) # 8000482c <write_head>
    80004be4:	bdf5                	j	80004ae0 <end_op+0x52>

0000000080004be6 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004be6:	1101                	addi	sp,sp,-32
    80004be8:	ec06                	sd	ra,24(sp)
    80004bea:	e822                	sd	s0,16(sp)
    80004bec:	e426                	sd	s1,8(sp)
    80004bee:	e04a                	sd	s2,0(sp)
    80004bf0:	1000                	addi	s0,sp,32
    80004bf2:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004bf4:	00031917          	auipc	s2,0x31
    80004bf8:	89c90913          	addi	s2,s2,-1892 # 80035490 <log>
    80004bfc:	854a                	mv	a0,s2
    80004bfe:	ffffc097          	auipc	ra,0xffffc
    80004c02:	fd8080e7          	jalr	-40(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004c06:	02c92603          	lw	a2,44(s2)
    80004c0a:	47f5                	li	a5,29
    80004c0c:	06c7c563          	blt	a5,a2,80004c76 <log_write+0x90>
    80004c10:	00031797          	auipc	a5,0x31
    80004c14:	89c7a783          	lw	a5,-1892(a5) # 800354ac <log+0x1c>
    80004c18:	37fd                	addiw	a5,a5,-1
    80004c1a:	04f65e63          	bge	a2,a5,80004c76 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004c1e:	00031797          	auipc	a5,0x31
    80004c22:	8927a783          	lw	a5,-1902(a5) # 800354b0 <log+0x20>
    80004c26:	06f05063          	blez	a5,80004c86 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004c2a:	4781                	li	a5,0
    80004c2c:	06c05563          	blez	a2,80004c96 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004c30:	44cc                	lw	a1,12(s1)
    80004c32:	00031717          	auipc	a4,0x31
    80004c36:	88e70713          	addi	a4,a4,-1906 # 800354c0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004c3a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004c3c:	4314                	lw	a3,0(a4)
    80004c3e:	04b68c63          	beq	a3,a1,80004c96 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004c42:	2785                	addiw	a5,a5,1
    80004c44:	0711                	addi	a4,a4,4
    80004c46:	fef61be3          	bne	a2,a5,80004c3c <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004c4a:	0621                	addi	a2,a2,8
    80004c4c:	060a                	slli	a2,a2,0x2
    80004c4e:	00031797          	auipc	a5,0x31
    80004c52:	84278793          	addi	a5,a5,-1982 # 80035490 <log>
    80004c56:	963e                	add	a2,a2,a5
    80004c58:	44dc                	lw	a5,12(s1)
    80004c5a:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004c5c:	8526                	mv	a0,s1
    80004c5e:	fffff097          	auipc	ra,0xfffff
    80004c62:	a54080e7          	jalr	-1452(ra) # 800036b2 <bpin>
    log.lh.n++;
    80004c66:	00031717          	auipc	a4,0x31
    80004c6a:	82a70713          	addi	a4,a4,-2006 # 80035490 <log>
    80004c6e:	575c                	lw	a5,44(a4)
    80004c70:	2785                	addiw	a5,a5,1
    80004c72:	d75c                	sw	a5,44(a4)
    80004c74:	a835                	j	80004cb0 <log_write+0xca>
    panic("too big a transaction");
    80004c76:	00004517          	auipc	a0,0x4
    80004c7a:	b4250513          	addi	a0,a0,-1214 # 800087b8 <syscalls+0x270>
    80004c7e:	ffffc097          	auipc	ra,0xffffc
    80004c82:	8c0080e7          	jalr	-1856(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004c86:	00004517          	auipc	a0,0x4
    80004c8a:	b4a50513          	addi	a0,a0,-1206 # 800087d0 <syscalls+0x288>
    80004c8e:	ffffc097          	auipc	ra,0xffffc
    80004c92:	8b0080e7          	jalr	-1872(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004c96:	00878713          	addi	a4,a5,8
    80004c9a:	00271693          	slli	a3,a4,0x2
    80004c9e:	00030717          	auipc	a4,0x30
    80004ca2:	7f270713          	addi	a4,a4,2034 # 80035490 <log>
    80004ca6:	9736                	add	a4,a4,a3
    80004ca8:	44d4                	lw	a3,12(s1)
    80004caa:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004cac:	faf608e3          	beq	a2,a5,80004c5c <log_write+0x76>
  }
  release(&log.lock);
    80004cb0:	00030517          	auipc	a0,0x30
    80004cb4:	7e050513          	addi	a0,a0,2016 # 80035490 <log>
    80004cb8:	ffffc097          	auipc	ra,0xffffc
    80004cbc:	fd2080e7          	jalr	-46(ra) # 80000c8a <release>
}
    80004cc0:	60e2                	ld	ra,24(sp)
    80004cc2:	6442                	ld	s0,16(sp)
    80004cc4:	64a2                	ld	s1,8(sp)
    80004cc6:	6902                	ld	s2,0(sp)
    80004cc8:	6105                	addi	sp,sp,32
    80004cca:	8082                	ret

0000000080004ccc <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004ccc:	1101                	addi	sp,sp,-32
    80004cce:	ec06                	sd	ra,24(sp)
    80004cd0:	e822                	sd	s0,16(sp)
    80004cd2:	e426                	sd	s1,8(sp)
    80004cd4:	e04a                	sd	s2,0(sp)
    80004cd6:	1000                	addi	s0,sp,32
    80004cd8:	84aa                	mv	s1,a0
    80004cda:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004cdc:	00004597          	auipc	a1,0x4
    80004ce0:	b1458593          	addi	a1,a1,-1260 # 800087f0 <syscalls+0x2a8>
    80004ce4:	0521                	addi	a0,a0,8
    80004ce6:	ffffc097          	auipc	ra,0xffffc
    80004cea:	e60080e7          	jalr	-416(ra) # 80000b46 <initlock>
  lk->name = name;
    80004cee:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004cf2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004cf6:	0204a423          	sw	zero,40(s1)
}
    80004cfa:	60e2                	ld	ra,24(sp)
    80004cfc:	6442                	ld	s0,16(sp)
    80004cfe:	64a2                	ld	s1,8(sp)
    80004d00:	6902                	ld	s2,0(sp)
    80004d02:	6105                	addi	sp,sp,32
    80004d04:	8082                	ret

0000000080004d06 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004d06:	1101                	addi	sp,sp,-32
    80004d08:	ec06                	sd	ra,24(sp)
    80004d0a:	e822                	sd	s0,16(sp)
    80004d0c:	e426                	sd	s1,8(sp)
    80004d0e:	e04a                	sd	s2,0(sp)
    80004d10:	1000                	addi	s0,sp,32
    80004d12:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004d14:	00850913          	addi	s2,a0,8
    80004d18:	854a                	mv	a0,s2
    80004d1a:	ffffc097          	auipc	ra,0xffffc
    80004d1e:	ebc080e7          	jalr	-324(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004d22:	409c                	lw	a5,0(s1)
    80004d24:	cb89                	beqz	a5,80004d36 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004d26:	85ca                	mv	a1,s2
    80004d28:	8526                	mv	a0,s1
    80004d2a:	ffffd097          	auipc	ra,0xffffd
    80004d2e:	532080e7          	jalr	1330(ra) # 8000225c <sleep>
  while (lk->locked) {
    80004d32:	409c                	lw	a5,0(s1)
    80004d34:	fbed                	bnez	a5,80004d26 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004d36:	4785                	li	a5,1
    80004d38:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004d3a:	ffffd097          	auipc	ra,0xffffd
    80004d3e:	dc8080e7          	jalr	-568(ra) # 80001b02 <myproc>
    80004d42:	591c                	lw	a5,48(a0)
    80004d44:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004d46:	854a                	mv	a0,s2
    80004d48:	ffffc097          	auipc	ra,0xffffc
    80004d4c:	f42080e7          	jalr	-190(ra) # 80000c8a <release>
}
    80004d50:	60e2                	ld	ra,24(sp)
    80004d52:	6442                	ld	s0,16(sp)
    80004d54:	64a2                	ld	s1,8(sp)
    80004d56:	6902                	ld	s2,0(sp)
    80004d58:	6105                	addi	sp,sp,32
    80004d5a:	8082                	ret

0000000080004d5c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004d5c:	1101                	addi	sp,sp,-32
    80004d5e:	ec06                	sd	ra,24(sp)
    80004d60:	e822                	sd	s0,16(sp)
    80004d62:	e426                	sd	s1,8(sp)
    80004d64:	e04a                	sd	s2,0(sp)
    80004d66:	1000                	addi	s0,sp,32
    80004d68:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004d6a:	00850913          	addi	s2,a0,8
    80004d6e:	854a                	mv	a0,s2
    80004d70:	ffffc097          	auipc	ra,0xffffc
    80004d74:	e66080e7          	jalr	-410(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004d78:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004d7c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004d80:	8526                	mv	a0,s1
    80004d82:	ffffd097          	auipc	ra,0xffffd
    80004d86:	53e080e7          	jalr	1342(ra) # 800022c0 <wakeup>
  release(&lk->lk);
    80004d8a:	854a                	mv	a0,s2
    80004d8c:	ffffc097          	auipc	ra,0xffffc
    80004d90:	efe080e7          	jalr	-258(ra) # 80000c8a <release>
}
    80004d94:	60e2                	ld	ra,24(sp)
    80004d96:	6442                	ld	s0,16(sp)
    80004d98:	64a2                	ld	s1,8(sp)
    80004d9a:	6902                	ld	s2,0(sp)
    80004d9c:	6105                	addi	sp,sp,32
    80004d9e:	8082                	ret

0000000080004da0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004da0:	7179                	addi	sp,sp,-48
    80004da2:	f406                	sd	ra,40(sp)
    80004da4:	f022                	sd	s0,32(sp)
    80004da6:	ec26                	sd	s1,24(sp)
    80004da8:	e84a                	sd	s2,16(sp)
    80004daa:	e44e                	sd	s3,8(sp)
    80004dac:	1800                	addi	s0,sp,48
    80004dae:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004db0:	00850913          	addi	s2,a0,8
    80004db4:	854a                	mv	a0,s2
    80004db6:	ffffc097          	auipc	ra,0xffffc
    80004dba:	e20080e7          	jalr	-480(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004dbe:	409c                	lw	a5,0(s1)
    80004dc0:	ef99                	bnez	a5,80004dde <holdingsleep+0x3e>
    80004dc2:	4481                	li	s1,0
  release(&lk->lk);
    80004dc4:	854a                	mv	a0,s2
    80004dc6:	ffffc097          	auipc	ra,0xffffc
    80004dca:	ec4080e7          	jalr	-316(ra) # 80000c8a <release>
  return r;
}
    80004dce:	8526                	mv	a0,s1
    80004dd0:	70a2                	ld	ra,40(sp)
    80004dd2:	7402                	ld	s0,32(sp)
    80004dd4:	64e2                	ld	s1,24(sp)
    80004dd6:	6942                	ld	s2,16(sp)
    80004dd8:	69a2                	ld	s3,8(sp)
    80004dda:	6145                	addi	sp,sp,48
    80004ddc:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004dde:	0284a983          	lw	s3,40(s1)
    80004de2:	ffffd097          	auipc	ra,0xffffd
    80004de6:	d20080e7          	jalr	-736(ra) # 80001b02 <myproc>
    80004dea:	5904                	lw	s1,48(a0)
    80004dec:	413484b3          	sub	s1,s1,s3
    80004df0:	0014b493          	seqz	s1,s1
    80004df4:	bfc1                	j	80004dc4 <holdingsleep+0x24>

0000000080004df6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004df6:	1141                	addi	sp,sp,-16
    80004df8:	e406                	sd	ra,8(sp)
    80004dfa:	e022                	sd	s0,0(sp)
    80004dfc:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004dfe:	00004597          	auipc	a1,0x4
    80004e02:	a0258593          	addi	a1,a1,-1534 # 80008800 <syscalls+0x2b8>
    80004e06:	00030517          	auipc	a0,0x30
    80004e0a:	7d250513          	addi	a0,a0,2002 # 800355d8 <ftable>
    80004e0e:	ffffc097          	auipc	ra,0xffffc
    80004e12:	d38080e7          	jalr	-712(ra) # 80000b46 <initlock>
}
    80004e16:	60a2                	ld	ra,8(sp)
    80004e18:	6402                	ld	s0,0(sp)
    80004e1a:	0141                	addi	sp,sp,16
    80004e1c:	8082                	ret

0000000080004e1e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004e1e:	1101                	addi	sp,sp,-32
    80004e20:	ec06                	sd	ra,24(sp)
    80004e22:	e822                	sd	s0,16(sp)
    80004e24:	e426                	sd	s1,8(sp)
    80004e26:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004e28:	00030517          	auipc	a0,0x30
    80004e2c:	7b050513          	addi	a0,a0,1968 # 800355d8 <ftable>
    80004e30:	ffffc097          	auipc	ra,0xffffc
    80004e34:	da6080e7          	jalr	-602(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004e38:	00030497          	auipc	s1,0x30
    80004e3c:	7b848493          	addi	s1,s1,1976 # 800355f0 <ftable+0x18>
    80004e40:	00031717          	auipc	a4,0x31
    80004e44:	75070713          	addi	a4,a4,1872 # 80036590 <disk>
    if(f->ref == 0){
    80004e48:	40dc                	lw	a5,4(s1)
    80004e4a:	cf99                	beqz	a5,80004e68 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004e4c:	02848493          	addi	s1,s1,40
    80004e50:	fee49ce3          	bne	s1,a4,80004e48 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004e54:	00030517          	auipc	a0,0x30
    80004e58:	78450513          	addi	a0,a0,1924 # 800355d8 <ftable>
    80004e5c:	ffffc097          	auipc	ra,0xffffc
    80004e60:	e2e080e7          	jalr	-466(ra) # 80000c8a <release>
  return 0;
    80004e64:	4481                	li	s1,0
    80004e66:	a819                	j	80004e7c <filealloc+0x5e>
      f->ref = 1;
    80004e68:	4785                	li	a5,1
    80004e6a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004e6c:	00030517          	auipc	a0,0x30
    80004e70:	76c50513          	addi	a0,a0,1900 # 800355d8 <ftable>
    80004e74:	ffffc097          	auipc	ra,0xffffc
    80004e78:	e16080e7          	jalr	-490(ra) # 80000c8a <release>
}
    80004e7c:	8526                	mv	a0,s1
    80004e7e:	60e2                	ld	ra,24(sp)
    80004e80:	6442                	ld	s0,16(sp)
    80004e82:	64a2                	ld	s1,8(sp)
    80004e84:	6105                	addi	sp,sp,32
    80004e86:	8082                	ret

0000000080004e88 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004e88:	1101                	addi	sp,sp,-32
    80004e8a:	ec06                	sd	ra,24(sp)
    80004e8c:	e822                	sd	s0,16(sp)
    80004e8e:	e426                	sd	s1,8(sp)
    80004e90:	1000                	addi	s0,sp,32
    80004e92:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004e94:	00030517          	auipc	a0,0x30
    80004e98:	74450513          	addi	a0,a0,1860 # 800355d8 <ftable>
    80004e9c:	ffffc097          	auipc	ra,0xffffc
    80004ea0:	d3a080e7          	jalr	-710(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004ea4:	40dc                	lw	a5,4(s1)
    80004ea6:	02f05263          	blez	a5,80004eca <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004eaa:	2785                	addiw	a5,a5,1
    80004eac:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004eae:	00030517          	auipc	a0,0x30
    80004eb2:	72a50513          	addi	a0,a0,1834 # 800355d8 <ftable>
    80004eb6:	ffffc097          	auipc	ra,0xffffc
    80004eba:	dd4080e7          	jalr	-556(ra) # 80000c8a <release>
  return f;
}
    80004ebe:	8526                	mv	a0,s1
    80004ec0:	60e2                	ld	ra,24(sp)
    80004ec2:	6442                	ld	s0,16(sp)
    80004ec4:	64a2                	ld	s1,8(sp)
    80004ec6:	6105                	addi	sp,sp,32
    80004ec8:	8082                	ret
    panic("filedup");
    80004eca:	00004517          	auipc	a0,0x4
    80004ece:	93e50513          	addi	a0,a0,-1730 # 80008808 <syscalls+0x2c0>
    80004ed2:	ffffb097          	auipc	ra,0xffffb
    80004ed6:	66c080e7          	jalr	1644(ra) # 8000053e <panic>

0000000080004eda <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004eda:	7139                	addi	sp,sp,-64
    80004edc:	fc06                	sd	ra,56(sp)
    80004ede:	f822                	sd	s0,48(sp)
    80004ee0:	f426                	sd	s1,40(sp)
    80004ee2:	f04a                	sd	s2,32(sp)
    80004ee4:	ec4e                	sd	s3,24(sp)
    80004ee6:	e852                	sd	s4,16(sp)
    80004ee8:	e456                	sd	s5,8(sp)
    80004eea:	0080                	addi	s0,sp,64
    80004eec:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004eee:	00030517          	auipc	a0,0x30
    80004ef2:	6ea50513          	addi	a0,a0,1770 # 800355d8 <ftable>
    80004ef6:	ffffc097          	auipc	ra,0xffffc
    80004efa:	ce0080e7          	jalr	-800(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004efe:	40dc                	lw	a5,4(s1)
    80004f00:	06f05163          	blez	a5,80004f62 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004f04:	37fd                	addiw	a5,a5,-1
    80004f06:	0007871b          	sext.w	a4,a5
    80004f0a:	c0dc                	sw	a5,4(s1)
    80004f0c:	06e04363          	bgtz	a4,80004f72 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004f10:	0004a903          	lw	s2,0(s1)
    80004f14:	0094ca83          	lbu	s5,9(s1)
    80004f18:	0104ba03          	ld	s4,16(s1)
    80004f1c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004f20:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004f24:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004f28:	00030517          	auipc	a0,0x30
    80004f2c:	6b050513          	addi	a0,a0,1712 # 800355d8 <ftable>
    80004f30:	ffffc097          	auipc	ra,0xffffc
    80004f34:	d5a080e7          	jalr	-678(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004f38:	4785                	li	a5,1
    80004f3a:	04f90d63          	beq	s2,a5,80004f94 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004f3e:	3979                	addiw	s2,s2,-2
    80004f40:	4785                	li	a5,1
    80004f42:	0527e063          	bltu	a5,s2,80004f82 <fileclose+0xa8>
    begin_op();
    80004f46:	00000097          	auipc	ra,0x0
    80004f4a:	ac8080e7          	jalr	-1336(ra) # 80004a0e <begin_op>
    iput(ff.ip);
    80004f4e:	854e                	mv	a0,s3
    80004f50:	fffff097          	auipc	ra,0xfffff
    80004f54:	f68080e7          	jalr	-152(ra) # 80003eb8 <iput>
    end_op();
    80004f58:	00000097          	auipc	ra,0x0
    80004f5c:	b36080e7          	jalr	-1226(ra) # 80004a8e <end_op>
    80004f60:	a00d                	j	80004f82 <fileclose+0xa8>
    panic("fileclose");
    80004f62:	00004517          	auipc	a0,0x4
    80004f66:	8ae50513          	addi	a0,a0,-1874 # 80008810 <syscalls+0x2c8>
    80004f6a:	ffffb097          	auipc	ra,0xffffb
    80004f6e:	5d4080e7          	jalr	1492(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004f72:	00030517          	auipc	a0,0x30
    80004f76:	66650513          	addi	a0,a0,1638 # 800355d8 <ftable>
    80004f7a:	ffffc097          	auipc	ra,0xffffc
    80004f7e:	d10080e7          	jalr	-752(ra) # 80000c8a <release>
  }
}
    80004f82:	70e2                	ld	ra,56(sp)
    80004f84:	7442                	ld	s0,48(sp)
    80004f86:	74a2                	ld	s1,40(sp)
    80004f88:	7902                	ld	s2,32(sp)
    80004f8a:	69e2                	ld	s3,24(sp)
    80004f8c:	6a42                	ld	s4,16(sp)
    80004f8e:	6aa2                	ld	s5,8(sp)
    80004f90:	6121                	addi	sp,sp,64
    80004f92:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004f94:	85d6                	mv	a1,s5
    80004f96:	8552                	mv	a0,s4
    80004f98:	00000097          	auipc	ra,0x0
    80004f9c:	5de080e7          	jalr	1502(ra) # 80005576 <pipeclose>
    80004fa0:	b7cd                	j	80004f82 <fileclose+0xa8>

0000000080004fa2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004fa2:	715d                	addi	sp,sp,-80
    80004fa4:	e486                	sd	ra,72(sp)
    80004fa6:	e0a2                	sd	s0,64(sp)
    80004fa8:	fc26                	sd	s1,56(sp)
    80004faa:	f84a                	sd	s2,48(sp)
    80004fac:	f44e                	sd	s3,40(sp)
    80004fae:	0880                	addi	s0,sp,80
    80004fb0:	84aa                	mv	s1,a0
    80004fb2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004fb4:	ffffd097          	auipc	ra,0xffffd
    80004fb8:	b4e080e7          	jalr	-1202(ra) # 80001b02 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004fbc:	409c                	lw	a5,0(s1)
    80004fbe:	37f9                	addiw	a5,a5,-2
    80004fc0:	4705                	li	a4,1
    80004fc2:	04f76763          	bltu	a4,a5,80005010 <filestat+0x6e>
    80004fc6:	892a                	mv	s2,a0
    ilock(f->ip);
    80004fc8:	6c88                	ld	a0,24(s1)
    80004fca:	fffff097          	auipc	ra,0xfffff
    80004fce:	d34080e7          	jalr	-716(ra) # 80003cfe <ilock>
    stati(f->ip, &st);
    80004fd2:	fb840593          	addi	a1,s0,-72
    80004fd6:	6c88                	ld	a0,24(s1)
    80004fd8:	fffff097          	auipc	ra,0xfffff
    80004fdc:	fb0080e7          	jalr	-80(ra) # 80003f88 <stati>
    iunlock(f->ip);
    80004fe0:	6c88                	ld	a0,24(s1)
    80004fe2:	fffff097          	auipc	ra,0xfffff
    80004fe6:	dde080e7          	jalr	-546(ra) # 80003dc0 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004fea:	46e1                	li	a3,24
    80004fec:	fb840613          	addi	a2,s0,-72
    80004ff0:	85ce                	mv	a1,s3
    80004ff2:	05093503          	ld	a0,80(s2)
    80004ff6:	ffffc097          	auipc	ra,0xffffc
    80004ffa:	7c8080e7          	jalr	1992(ra) # 800017be <copyout>
    80004ffe:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80005002:	60a6                	ld	ra,72(sp)
    80005004:	6406                	ld	s0,64(sp)
    80005006:	74e2                	ld	s1,56(sp)
    80005008:	7942                	ld	s2,48(sp)
    8000500a:	79a2                	ld	s3,40(sp)
    8000500c:	6161                	addi	sp,sp,80
    8000500e:	8082                	ret
  return -1;
    80005010:	557d                	li	a0,-1
    80005012:	bfc5                	j	80005002 <filestat+0x60>

0000000080005014 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80005014:	7179                	addi	sp,sp,-48
    80005016:	f406                	sd	ra,40(sp)
    80005018:	f022                	sd	s0,32(sp)
    8000501a:	ec26                	sd	s1,24(sp)
    8000501c:	e84a                	sd	s2,16(sp)
    8000501e:	e44e                	sd	s3,8(sp)
    80005020:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005022:	00854783          	lbu	a5,8(a0)
    80005026:	c3d5                	beqz	a5,800050ca <fileread+0xb6>
    80005028:	84aa                	mv	s1,a0
    8000502a:	89ae                	mv	s3,a1
    8000502c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000502e:	411c                	lw	a5,0(a0)
    80005030:	4705                	li	a4,1
    80005032:	04e78963          	beq	a5,a4,80005084 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005036:	470d                	li	a4,3
    80005038:	04e78d63          	beq	a5,a4,80005092 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000503c:	4709                	li	a4,2
    8000503e:	06e79e63          	bne	a5,a4,800050ba <fileread+0xa6>
    ilock(f->ip);
    80005042:	6d08                	ld	a0,24(a0)
    80005044:	fffff097          	auipc	ra,0xfffff
    80005048:	cba080e7          	jalr	-838(ra) # 80003cfe <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000504c:	874a                	mv	a4,s2
    8000504e:	5094                	lw	a3,32(s1)
    80005050:	864e                	mv	a2,s3
    80005052:	4585                	li	a1,1
    80005054:	6c88                	ld	a0,24(s1)
    80005056:	fffff097          	auipc	ra,0xfffff
    8000505a:	f5c080e7          	jalr	-164(ra) # 80003fb2 <readi>
    8000505e:	892a                	mv	s2,a0
    80005060:	00a05563          	blez	a0,8000506a <fileread+0x56>
      f->off += r;
    80005064:	509c                	lw	a5,32(s1)
    80005066:	9fa9                	addw	a5,a5,a0
    80005068:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000506a:	6c88                	ld	a0,24(s1)
    8000506c:	fffff097          	auipc	ra,0xfffff
    80005070:	d54080e7          	jalr	-684(ra) # 80003dc0 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005074:	854a                	mv	a0,s2
    80005076:	70a2                	ld	ra,40(sp)
    80005078:	7402                	ld	s0,32(sp)
    8000507a:	64e2                	ld	s1,24(sp)
    8000507c:	6942                	ld	s2,16(sp)
    8000507e:	69a2                	ld	s3,8(sp)
    80005080:	6145                	addi	sp,sp,48
    80005082:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005084:	6908                	ld	a0,16(a0)
    80005086:	00000097          	auipc	ra,0x0
    8000508a:	658080e7          	jalr	1624(ra) # 800056de <piperead>
    8000508e:	892a                	mv	s2,a0
    80005090:	b7d5                	j	80005074 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005092:	02451783          	lh	a5,36(a0)
    80005096:	03079693          	slli	a3,a5,0x30
    8000509a:	92c1                	srli	a3,a3,0x30
    8000509c:	4725                	li	a4,9
    8000509e:	02d76863          	bltu	a4,a3,800050ce <fileread+0xba>
    800050a2:	0792                	slli	a5,a5,0x4
    800050a4:	00030717          	auipc	a4,0x30
    800050a8:	49470713          	addi	a4,a4,1172 # 80035538 <devsw>
    800050ac:	97ba                	add	a5,a5,a4
    800050ae:	639c                	ld	a5,0(a5)
    800050b0:	c38d                	beqz	a5,800050d2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800050b2:	4505                	li	a0,1
    800050b4:	9782                	jalr	a5
    800050b6:	892a                	mv	s2,a0
    800050b8:	bf75                	j	80005074 <fileread+0x60>
    panic("fileread");
    800050ba:	00003517          	auipc	a0,0x3
    800050be:	76650513          	addi	a0,a0,1894 # 80008820 <syscalls+0x2d8>
    800050c2:	ffffb097          	auipc	ra,0xffffb
    800050c6:	47c080e7          	jalr	1148(ra) # 8000053e <panic>
    return -1;
    800050ca:	597d                	li	s2,-1
    800050cc:	b765                	j	80005074 <fileread+0x60>
      return -1;
    800050ce:	597d                	li	s2,-1
    800050d0:	b755                	j	80005074 <fileread+0x60>
    800050d2:	597d                	li	s2,-1
    800050d4:	b745                	j	80005074 <fileread+0x60>

00000000800050d6 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800050d6:	715d                	addi	sp,sp,-80
    800050d8:	e486                	sd	ra,72(sp)
    800050da:	e0a2                	sd	s0,64(sp)
    800050dc:	fc26                	sd	s1,56(sp)
    800050de:	f84a                	sd	s2,48(sp)
    800050e0:	f44e                	sd	s3,40(sp)
    800050e2:	f052                	sd	s4,32(sp)
    800050e4:	ec56                	sd	s5,24(sp)
    800050e6:	e85a                	sd	s6,16(sp)
    800050e8:	e45e                	sd	s7,8(sp)
    800050ea:	e062                	sd	s8,0(sp)
    800050ec:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800050ee:	00954783          	lbu	a5,9(a0)
    800050f2:	10078663          	beqz	a5,800051fe <filewrite+0x128>
    800050f6:	892a                	mv	s2,a0
    800050f8:	8aae                	mv	s5,a1
    800050fa:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800050fc:	411c                	lw	a5,0(a0)
    800050fe:	4705                	li	a4,1
    80005100:	02e78263          	beq	a5,a4,80005124 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005104:	470d                	li	a4,3
    80005106:	02e78663          	beq	a5,a4,80005132 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000510a:	4709                	li	a4,2
    8000510c:	0ee79163          	bne	a5,a4,800051ee <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005110:	0ac05d63          	blez	a2,800051ca <filewrite+0xf4>
    int i = 0;
    80005114:	4981                	li	s3,0
    80005116:	6b05                	lui	s6,0x1
    80005118:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000511c:	6b85                	lui	s7,0x1
    8000511e:	c00b8b9b          	addiw	s7,s7,-1024
    80005122:	a861                	j	800051ba <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005124:	6908                	ld	a0,16(a0)
    80005126:	00000097          	auipc	ra,0x0
    8000512a:	4c0080e7          	jalr	1216(ra) # 800055e6 <pipewrite>
    8000512e:	8a2a                	mv	s4,a0
    80005130:	a045                	j	800051d0 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005132:	02451783          	lh	a5,36(a0)
    80005136:	03079693          	slli	a3,a5,0x30
    8000513a:	92c1                	srli	a3,a3,0x30
    8000513c:	4725                	li	a4,9
    8000513e:	0cd76263          	bltu	a4,a3,80005202 <filewrite+0x12c>
    80005142:	0792                	slli	a5,a5,0x4
    80005144:	00030717          	auipc	a4,0x30
    80005148:	3f470713          	addi	a4,a4,1012 # 80035538 <devsw>
    8000514c:	97ba                	add	a5,a5,a4
    8000514e:	679c                	ld	a5,8(a5)
    80005150:	cbdd                	beqz	a5,80005206 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005152:	4505                	li	a0,1
    80005154:	9782                	jalr	a5
    80005156:	8a2a                	mv	s4,a0
    80005158:	a8a5                	j	800051d0 <filewrite+0xfa>
    8000515a:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000515e:	00000097          	auipc	ra,0x0
    80005162:	8b0080e7          	jalr	-1872(ra) # 80004a0e <begin_op>
      ilock(f->ip);
    80005166:	01893503          	ld	a0,24(s2)
    8000516a:	fffff097          	auipc	ra,0xfffff
    8000516e:	b94080e7          	jalr	-1132(ra) # 80003cfe <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005172:	8762                	mv	a4,s8
    80005174:	02092683          	lw	a3,32(s2)
    80005178:	01598633          	add	a2,s3,s5
    8000517c:	4585                	li	a1,1
    8000517e:	01893503          	ld	a0,24(s2)
    80005182:	fffff097          	auipc	ra,0xfffff
    80005186:	f28080e7          	jalr	-216(ra) # 800040aa <writei>
    8000518a:	84aa                	mv	s1,a0
    8000518c:	00a05763          	blez	a0,8000519a <filewrite+0xc4>
        f->off += r;
    80005190:	02092783          	lw	a5,32(s2)
    80005194:	9fa9                	addw	a5,a5,a0
    80005196:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000519a:	01893503          	ld	a0,24(s2)
    8000519e:	fffff097          	auipc	ra,0xfffff
    800051a2:	c22080e7          	jalr	-990(ra) # 80003dc0 <iunlock>
      end_op();
    800051a6:	00000097          	auipc	ra,0x0
    800051aa:	8e8080e7          	jalr	-1816(ra) # 80004a8e <end_op>

      if(r != n1){
    800051ae:	009c1f63          	bne	s8,s1,800051cc <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800051b2:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800051b6:	0149db63          	bge	s3,s4,800051cc <filewrite+0xf6>
      int n1 = n - i;
    800051ba:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800051be:	84be                	mv	s1,a5
    800051c0:	2781                	sext.w	a5,a5
    800051c2:	f8fb5ce3          	bge	s6,a5,8000515a <filewrite+0x84>
    800051c6:	84de                	mv	s1,s7
    800051c8:	bf49                	j	8000515a <filewrite+0x84>
    int i = 0;
    800051ca:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800051cc:	013a1f63          	bne	s4,s3,800051ea <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800051d0:	8552                	mv	a0,s4
    800051d2:	60a6                	ld	ra,72(sp)
    800051d4:	6406                	ld	s0,64(sp)
    800051d6:	74e2                	ld	s1,56(sp)
    800051d8:	7942                	ld	s2,48(sp)
    800051da:	79a2                	ld	s3,40(sp)
    800051dc:	7a02                	ld	s4,32(sp)
    800051de:	6ae2                	ld	s5,24(sp)
    800051e0:	6b42                	ld	s6,16(sp)
    800051e2:	6ba2                	ld	s7,8(sp)
    800051e4:	6c02                	ld	s8,0(sp)
    800051e6:	6161                	addi	sp,sp,80
    800051e8:	8082                	ret
    ret = (i == n ? n : -1);
    800051ea:	5a7d                	li	s4,-1
    800051ec:	b7d5                	j	800051d0 <filewrite+0xfa>
    panic("filewrite");
    800051ee:	00003517          	auipc	a0,0x3
    800051f2:	64250513          	addi	a0,a0,1602 # 80008830 <syscalls+0x2e8>
    800051f6:	ffffb097          	auipc	ra,0xffffb
    800051fa:	348080e7          	jalr	840(ra) # 8000053e <panic>
    return -1;
    800051fe:	5a7d                	li	s4,-1
    80005200:	bfc1                	j	800051d0 <filewrite+0xfa>
      return -1;
    80005202:	5a7d                	li	s4,-1
    80005204:	b7f1                	j	800051d0 <filewrite+0xfa>
    80005206:	5a7d                	li	s4,-1
    80005208:	b7e1                	j	800051d0 <filewrite+0xfa>

000000008000520a <kfileread>:

// Read from file f.
// addr is a kernel virtual address.
int
kfileread(struct file *f, uint64 addr, int n)
{
    8000520a:	7179                	addi	sp,sp,-48
    8000520c:	f406                	sd	ra,40(sp)
    8000520e:	f022                	sd	s0,32(sp)
    80005210:	ec26                	sd	s1,24(sp)
    80005212:	e84a                	sd	s2,16(sp)
    80005214:	e44e                	sd	s3,8(sp)
    80005216:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005218:	00854783          	lbu	a5,8(a0)
    8000521c:	c3d5                	beqz	a5,800052c0 <kfileread+0xb6>
    8000521e:	84aa                	mv	s1,a0
    80005220:	89ae                	mv	s3,a1
    80005222:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005224:	411c                	lw	a5,0(a0)
    80005226:	4705                	li	a4,1
    80005228:	04e78963          	beq	a5,a4,8000527a <kfileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000522c:	470d                	li	a4,3
    8000522e:	04e78d63          	beq	a5,a4,80005288 <kfileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005232:	4709                	li	a4,2
    80005234:	06e79e63          	bne	a5,a4,800052b0 <kfileread+0xa6>
    ilock(f->ip);
    80005238:	6d08                	ld	a0,24(a0)
    8000523a:	fffff097          	auipc	ra,0xfffff
    8000523e:	ac4080e7          	jalr	-1340(ra) # 80003cfe <ilock>
    if((r = readi(f->ip, 0, addr, f->off, n)) > 0)
    80005242:	874a                	mv	a4,s2
    80005244:	5094                	lw	a3,32(s1)
    80005246:	864e                	mv	a2,s3
    80005248:	4581                	li	a1,0
    8000524a:	6c88                	ld	a0,24(s1)
    8000524c:	fffff097          	auipc	ra,0xfffff
    80005250:	d66080e7          	jalr	-666(ra) # 80003fb2 <readi>
    80005254:	892a                	mv	s2,a0
    80005256:	00a05563          	blez	a0,80005260 <kfileread+0x56>
      f->off += r;
    8000525a:	509c                	lw	a5,32(s1)
    8000525c:	9fa9                	addw	a5,a5,a0
    8000525e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005260:	6c88                	ld	a0,24(s1)
    80005262:	fffff097          	auipc	ra,0xfffff
    80005266:	b5e080e7          	jalr	-1186(ra) # 80003dc0 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000526a:	854a                	mv	a0,s2
    8000526c:	70a2                	ld	ra,40(sp)
    8000526e:	7402                	ld	s0,32(sp)
    80005270:	64e2                	ld	s1,24(sp)
    80005272:	6942                	ld	s2,16(sp)
    80005274:	69a2                	ld	s3,8(sp)
    80005276:	6145                	addi	sp,sp,48
    80005278:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000527a:	6908                	ld	a0,16(a0)
    8000527c:	00000097          	auipc	ra,0x0
    80005280:	462080e7          	jalr	1122(ra) # 800056de <piperead>
    80005284:	892a                	mv	s2,a0
    80005286:	b7d5                	j	8000526a <kfileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005288:	02451783          	lh	a5,36(a0)
    8000528c:	03079693          	slli	a3,a5,0x30
    80005290:	92c1                	srli	a3,a3,0x30
    80005292:	4725                	li	a4,9
    80005294:	02d76863          	bltu	a4,a3,800052c4 <kfileread+0xba>
    80005298:	0792                	slli	a5,a5,0x4
    8000529a:	00030717          	auipc	a4,0x30
    8000529e:	29e70713          	addi	a4,a4,670 # 80035538 <devsw>
    800052a2:	97ba                	add	a5,a5,a4
    800052a4:	639c                	ld	a5,0(a5)
    800052a6:	c38d                	beqz	a5,800052c8 <kfileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800052a8:	4505                	li	a0,1
    800052aa:	9782                	jalr	a5
    800052ac:	892a                	mv	s2,a0
    800052ae:	bf75                	j	8000526a <kfileread+0x60>
    panic("fileread");
    800052b0:	00003517          	auipc	a0,0x3
    800052b4:	57050513          	addi	a0,a0,1392 # 80008820 <syscalls+0x2d8>
    800052b8:	ffffb097          	auipc	ra,0xffffb
    800052bc:	286080e7          	jalr	646(ra) # 8000053e <panic>
    return -1;
    800052c0:	597d                	li	s2,-1
    800052c2:	b765                	j	8000526a <kfileread+0x60>
      return -1;
    800052c4:	597d                	li	s2,-1
    800052c6:	b755                	j	8000526a <kfileread+0x60>
    800052c8:	597d                	li	s2,-1
    800052ca:	b745                	j	8000526a <kfileread+0x60>

00000000800052cc <kfilewrite>:

// Write to file f.
// addr is a kernel virtual address.
int
kfilewrite(struct file *f, uint64 addr, int n)
{
    800052cc:	7119                	addi	sp,sp,-128
    800052ce:	fc86                	sd	ra,120(sp)
    800052d0:	f8a2                	sd	s0,112(sp)
    800052d2:	f4a6                	sd	s1,104(sp)
    800052d4:	f0ca                	sd	s2,96(sp)
    800052d6:	ecce                	sd	s3,88(sp)
    800052d8:	e8d2                	sd	s4,80(sp)
    800052da:	e4d6                	sd	s5,72(sp)
    800052dc:	e0da                	sd	s6,64(sp)
    800052de:	fc5e                	sd	s7,56(sp)
    800052e0:	f862                	sd	s8,48(sp)
    800052e2:	f466                	sd	s9,40(sp)
    800052e4:	f06a                	sd	s10,32(sp)
    800052e6:	ec6e                	sd	s11,24(sp)
    800052e8:	0100                	addi	s0,sp,128
  int r, ret = 0;
  if(f->writable == 0)
    800052ea:	00954783          	lbu	a5,9(a0)
    800052ee:	1a078163          	beqz	a5,80005490 <kfilewrite+0x1c4>
    800052f2:	892a                	mv	s2,a0
    800052f4:	8b2e                	mv	s6,a1
    800052f6:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800052f8:	411c                	lw	a5,0(a0)
    800052fa:	4705                	li	a4,1
    800052fc:	04e78c63          	beq	a5,a4,80005354 <kfilewrite+0x88>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005300:	470d                	li	a4,3
    80005302:	06e78063          	beq	a5,a4,80005362 <kfilewrite+0x96>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005306:	4709                	li	a4,2
    80005308:	16e79c63          	bne	a5,a4,80005480 <kfilewrite+0x1b4>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    printf("15here\n");
    8000530c:	00003517          	auipc	a0,0x3
    80005310:	53450513          	addi	a0,a0,1332 # 80008840 <syscalls+0x2f8>
    80005314:	ffffb097          	auipc	ra,0xffffb
    80005318:	274080e7          	jalr	628(ra) # 80000588 <printf>
    while(i < n){
    8000531c:	11405d63          	blez	s4,80005436 <kfilewrite+0x16a>
    int i = 0;
    80005320:	4981                	li	s3,0
    80005322:	6b85                	lui	s7,0x1
    80005324:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80005328:	6785                	lui	a5,0x1
    8000532a:	c007879b          	addiw	a5,a5,-1024
    8000532e:	f8f42623          	sw	a5,-116(s0)
      int n1 = n - i;
      if(n1 > max)
        n1 = max;
    printf("16here\n");
    80005332:	00003d97          	auipc	s11,0x3
    80005336:	516d8d93          	addi	s11,s11,1302 # 80008848 <syscalls+0x300>

      begin_op();
          printf("17here\n");
    8000533a:	00003d17          	auipc	s10,0x3
    8000533e:	516d0d13          	addi	s10,s10,1302 # 80008850 <syscalls+0x308>

      ilock(f->ip);
      if ((r = writei(f->ip, 0, addr + i, f->off, n1)) > 0)
        f->off += r;
      
      printf("18here\n");
    80005342:	00003c97          	auipc	s9,0x3
    80005346:	516c8c93          	addi	s9,s9,1302 # 80008858 <syscalls+0x310>

      iunlock(f->ip);
          printf("19here\n");
    8000534a:	00003c17          	auipc	s8,0x3
    8000534e:	516c0c13          	addi	s8,s8,1302 # 80008860 <syscalls+0x318>
    80005352:	a8c9                	j	80005424 <kfilewrite+0x158>
    ret = pipewrite(f->pipe, addr, n);
    80005354:	6908                	ld	a0,16(a0)
    80005356:	00000097          	auipc	ra,0x0
    8000535a:	290080e7          	jalr	656(ra) # 800055e6 <pipewrite>
    8000535e:	84aa                	mv	s1,a0
    80005360:	a8c5                	j	80005450 <kfilewrite+0x184>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005362:	02451783          	lh	a5,36(a0)
    80005366:	03079693          	slli	a3,a5,0x30
    8000536a:	92c1                	srli	a3,a3,0x30
    8000536c:	4725                	li	a4,9
    8000536e:	12d76363          	bltu	a4,a3,80005494 <kfilewrite+0x1c8>
    80005372:	0792                	slli	a5,a5,0x4
    80005374:	00030717          	auipc	a4,0x30
    80005378:	1c470713          	addi	a4,a4,452 # 80035538 <devsw>
    8000537c:	97ba                	add	a5,a5,a4
    8000537e:	679c                	ld	a5,8(a5)
    80005380:	10078c63          	beqz	a5,80005498 <kfilewrite+0x1cc>
    ret = devsw[f->major].write(1, addr, n);
    80005384:	4505                	li	a0,1
    80005386:	9782                	jalr	a5
    80005388:	84aa                	mv	s1,a0
    8000538a:	a0d9                	j	80005450 <kfilewrite+0x184>
    8000538c:	00048a9b          	sext.w	s5,s1
    printf("16here\n");
    80005390:	856e                	mv	a0,s11
    80005392:	ffffb097          	auipc	ra,0xffffb
    80005396:	1f6080e7          	jalr	502(ra) # 80000588 <printf>
      begin_op();
    8000539a:	fffff097          	auipc	ra,0xfffff
    8000539e:	674080e7          	jalr	1652(ra) # 80004a0e <begin_op>
          printf("17here\n");
    800053a2:	856a                	mv	a0,s10
    800053a4:	ffffb097          	auipc	ra,0xffffb
    800053a8:	1e4080e7          	jalr	484(ra) # 80000588 <printf>
      ilock(f->ip);
    800053ac:	01893503          	ld	a0,24(s2)
    800053b0:	fffff097          	auipc	ra,0xfffff
    800053b4:	94e080e7          	jalr	-1714(ra) # 80003cfe <ilock>
      if ((r = writei(f->ip, 0, addr + i, f->off, n1)) > 0)
    800053b8:	8756                	mv	a4,s5
    800053ba:	02092683          	lw	a3,32(s2)
    800053be:	01698633          	add	a2,s3,s6
    800053c2:	4581                	li	a1,0
    800053c4:	01893503          	ld	a0,24(s2)
    800053c8:	fffff097          	auipc	ra,0xfffff
    800053cc:	ce2080e7          	jalr	-798(ra) # 800040aa <writei>
    800053d0:	84aa                	mv	s1,a0
    800053d2:	00a05763          	blez	a0,800053e0 <kfilewrite+0x114>
        f->off += r;
    800053d6:	02092783          	lw	a5,32(s2)
    800053da:	9fa9                	addw	a5,a5,a0
    800053dc:	02f92023          	sw	a5,32(s2)
      printf("18here\n");
    800053e0:	8566                	mv	a0,s9
    800053e2:	ffffb097          	auipc	ra,0xffffb
    800053e6:	1a6080e7          	jalr	422(ra) # 80000588 <printf>
      iunlock(f->ip);
    800053ea:	01893503          	ld	a0,24(s2)
    800053ee:	fffff097          	auipc	ra,0xfffff
    800053f2:	9d2080e7          	jalr	-1582(ra) # 80003dc0 <iunlock>
          printf("19here\n");
    800053f6:	8562                	mv	a0,s8
    800053f8:	ffffb097          	auipc	ra,0xffffb
    800053fc:	190080e7          	jalr	400(ra) # 80000588 <printf>

      end_op();
    80005400:	fffff097          	auipc	ra,0xfffff
    80005404:	68e080e7          	jalr	1678(ra) # 80004a8e <end_op>
    printf("20here\n");
    80005408:	00003517          	auipc	a0,0x3
    8000540c:	46050513          	addi	a0,a0,1120 # 80008868 <syscalls+0x320>
    80005410:	ffffb097          	auipc	ra,0xffffb
    80005414:	178080e7          	jalr	376(ra) # 80000588 <printf>

      if(r != n1){
    80005418:	029a9063          	bne	s5,s1,80005438 <kfilewrite+0x16c>
        // error from writei
        break;
      }
      i += r;
    8000541c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005420:	0149dc63          	bge	s3,s4,80005438 <kfilewrite+0x16c>
      int n1 = n - i;
    80005424:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005428:	84be                	mv	s1,a5
    8000542a:	2781                	sext.w	a5,a5
    8000542c:	f6fbd0e3          	bge	s7,a5,8000538c <kfilewrite+0xc0>
    80005430:	f8c42483          	lw	s1,-116(s0)
    80005434:	bfa1                	j	8000538c <kfilewrite+0xc0>
    int i = 0;
    80005436:	4981                	li	s3,0
    }
    printf("18here\n");
    80005438:	00003517          	auipc	a0,0x3
    8000543c:	42050513          	addi	a0,a0,1056 # 80008858 <syscalls+0x310>
    80005440:	ffffb097          	auipc	ra,0xffffb
    80005444:	148080e7          	jalr	328(ra) # 80000588 <printf>
    ret = (i == n ? n : -1);
    80005448:	84d2                	mv	s1,s4
    8000544a:	013a0363          	beq	s4,s3,80005450 <kfilewrite+0x184>
    8000544e:	54fd                	li	s1,-1
  } else {
    panic("filewrite");
  }
printf("19here\n");
    80005450:	00003517          	auipc	a0,0x3
    80005454:	41050513          	addi	a0,a0,1040 # 80008860 <syscalls+0x318>
    80005458:	ffffb097          	auipc	ra,0xffffb
    8000545c:	130080e7          	jalr	304(ra) # 80000588 <printf>
  return ret;
    80005460:	8526                	mv	a0,s1
    80005462:	70e6                	ld	ra,120(sp)
    80005464:	7446                	ld	s0,112(sp)
    80005466:	74a6                	ld	s1,104(sp)
    80005468:	7906                	ld	s2,96(sp)
    8000546a:	69e6                	ld	s3,88(sp)
    8000546c:	6a46                	ld	s4,80(sp)
    8000546e:	6aa6                	ld	s5,72(sp)
    80005470:	6b06                	ld	s6,64(sp)
    80005472:	7be2                	ld	s7,56(sp)
    80005474:	7c42                	ld	s8,48(sp)
    80005476:	7ca2                	ld	s9,40(sp)
    80005478:	7d02                	ld	s10,32(sp)
    8000547a:	6de2                	ld	s11,24(sp)
    8000547c:	6109                	addi	sp,sp,128
    8000547e:	8082                	ret
    panic("filewrite");
    80005480:	00003517          	auipc	a0,0x3
    80005484:	3b050513          	addi	a0,a0,944 # 80008830 <syscalls+0x2e8>
    80005488:	ffffb097          	auipc	ra,0xffffb
    8000548c:	0b6080e7          	jalr	182(ra) # 8000053e <panic>
    return -1;
    80005490:	54fd                	li	s1,-1
    80005492:	b7f9                	j	80005460 <kfilewrite+0x194>
      return -1;
    80005494:	54fd                	li	s1,-1
    80005496:	b7e9                	j	80005460 <kfilewrite+0x194>
    80005498:	54fd                	li	s1,-1
    8000549a:	b7d9                	j	80005460 <kfilewrite+0x194>

000000008000549c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000549c:	7179                	addi	sp,sp,-48
    8000549e:	f406                	sd	ra,40(sp)
    800054a0:	f022                	sd	s0,32(sp)
    800054a2:	ec26                	sd	s1,24(sp)
    800054a4:	e84a                	sd	s2,16(sp)
    800054a6:	e44e                	sd	s3,8(sp)
    800054a8:	e052                	sd	s4,0(sp)
    800054aa:	1800                	addi	s0,sp,48
    800054ac:	84aa                	mv	s1,a0
    800054ae:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800054b0:	0005b023          	sd	zero,0(a1)
    800054b4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800054b8:	00000097          	auipc	ra,0x0
    800054bc:	966080e7          	jalr	-1690(ra) # 80004e1e <filealloc>
    800054c0:	e088                	sd	a0,0(s1)
    800054c2:	c551                	beqz	a0,8000554e <pipealloc+0xb2>
    800054c4:	00000097          	auipc	ra,0x0
    800054c8:	95a080e7          	jalr	-1702(ra) # 80004e1e <filealloc>
    800054cc:	00aa3023          	sd	a0,0(s4)
    800054d0:	c92d                	beqz	a0,80005542 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800054d2:	ffffb097          	auipc	ra,0xffffb
    800054d6:	614080e7          	jalr	1556(ra) # 80000ae6 <kalloc>
    800054da:	892a                	mv	s2,a0
    800054dc:	c125                	beqz	a0,8000553c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800054de:	4985                	li	s3,1
    800054e0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800054e4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800054e8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800054ec:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800054f0:	00003597          	auipc	a1,0x3
    800054f4:	38058593          	addi	a1,a1,896 # 80008870 <syscalls+0x328>
    800054f8:	ffffb097          	auipc	ra,0xffffb
    800054fc:	64e080e7          	jalr	1614(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80005500:	609c                	ld	a5,0(s1)
    80005502:	0137a023          	sw	s3,0(a5) # 1000 <_entry-0x7ffff000>
  (*f0)->readable = 1;
    80005506:	609c                	ld	a5,0(s1)
    80005508:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000550c:	609c                	ld	a5,0(s1)
    8000550e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005512:	609c                	ld	a5,0(s1)
    80005514:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005518:	000a3783          	ld	a5,0(s4)
    8000551c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005520:	000a3783          	ld	a5,0(s4)
    80005524:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005528:	000a3783          	ld	a5,0(s4)
    8000552c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005530:	000a3783          	ld	a5,0(s4)
    80005534:	0127b823          	sd	s2,16(a5)
  return 0;
    80005538:	4501                	li	a0,0
    8000553a:	a025                	j	80005562 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000553c:	6088                	ld	a0,0(s1)
    8000553e:	e501                	bnez	a0,80005546 <pipealloc+0xaa>
    80005540:	a039                	j	8000554e <pipealloc+0xb2>
    80005542:	6088                	ld	a0,0(s1)
    80005544:	c51d                	beqz	a0,80005572 <pipealloc+0xd6>
    fileclose(*f0);
    80005546:	00000097          	auipc	ra,0x0
    8000554a:	994080e7          	jalr	-1644(ra) # 80004eda <fileclose>
  if(*f1)
    8000554e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005552:	557d                	li	a0,-1
  if(*f1)
    80005554:	c799                	beqz	a5,80005562 <pipealloc+0xc6>
    fileclose(*f1);
    80005556:	853e                	mv	a0,a5
    80005558:	00000097          	auipc	ra,0x0
    8000555c:	982080e7          	jalr	-1662(ra) # 80004eda <fileclose>
  return -1;
    80005560:	557d                	li	a0,-1
}
    80005562:	70a2                	ld	ra,40(sp)
    80005564:	7402                	ld	s0,32(sp)
    80005566:	64e2                	ld	s1,24(sp)
    80005568:	6942                	ld	s2,16(sp)
    8000556a:	69a2                	ld	s3,8(sp)
    8000556c:	6a02                	ld	s4,0(sp)
    8000556e:	6145                	addi	sp,sp,48
    80005570:	8082                	ret
  return -1;
    80005572:	557d                	li	a0,-1
    80005574:	b7fd                	j	80005562 <pipealloc+0xc6>

0000000080005576 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005576:	1101                	addi	sp,sp,-32
    80005578:	ec06                	sd	ra,24(sp)
    8000557a:	e822                	sd	s0,16(sp)
    8000557c:	e426                	sd	s1,8(sp)
    8000557e:	e04a                	sd	s2,0(sp)
    80005580:	1000                	addi	s0,sp,32
    80005582:	84aa                	mv	s1,a0
    80005584:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005586:	ffffb097          	auipc	ra,0xffffb
    8000558a:	650080e7          	jalr	1616(ra) # 80000bd6 <acquire>
  if(writable){
    8000558e:	02090d63          	beqz	s2,800055c8 <pipeclose+0x52>
    pi->writeopen = 0;
    80005592:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005596:	21848513          	addi	a0,s1,536
    8000559a:	ffffd097          	auipc	ra,0xffffd
    8000559e:	d26080e7          	jalr	-730(ra) # 800022c0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800055a2:	2204b783          	ld	a5,544(s1)
    800055a6:	eb95                	bnez	a5,800055da <pipeclose+0x64>
    release(&pi->lock);
    800055a8:	8526                	mv	a0,s1
    800055aa:	ffffb097          	auipc	ra,0xffffb
    800055ae:	6e0080e7          	jalr	1760(ra) # 80000c8a <release>
    kfree((char*)pi);
    800055b2:	8526                	mv	a0,s1
    800055b4:	ffffb097          	auipc	ra,0xffffb
    800055b8:	436080e7          	jalr	1078(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    800055bc:	60e2                	ld	ra,24(sp)
    800055be:	6442                	ld	s0,16(sp)
    800055c0:	64a2                	ld	s1,8(sp)
    800055c2:	6902                	ld	s2,0(sp)
    800055c4:	6105                	addi	sp,sp,32
    800055c6:	8082                	ret
    pi->readopen = 0;
    800055c8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800055cc:	21c48513          	addi	a0,s1,540
    800055d0:	ffffd097          	auipc	ra,0xffffd
    800055d4:	cf0080e7          	jalr	-784(ra) # 800022c0 <wakeup>
    800055d8:	b7e9                	j	800055a2 <pipeclose+0x2c>
    release(&pi->lock);
    800055da:	8526                	mv	a0,s1
    800055dc:	ffffb097          	auipc	ra,0xffffb
    800055e0:	6ae080e7          	jalr	1710(ra) # 80000c8a <release>
}
    800055e4:	bfe1                	j	800055bc <pipeclose+0x46>

00000000800055e6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800055e6:	711d                	addi	sp,sp,-96
    800055e8:	ec86                	sd	ra,88(sp)
    800055ea:	e8a2                	sd	s0,80(sp)
    800055ec:	e4a6                	sd	s1,72(sp)
    800055ee:	e0ca                	sd	s2,64(sp)
    800055f0:	fc4e                	sd	s3,56(sp)
    800055f2:	f852                	sd	s4,48(sp)
    800055f4:	f456                	sd	s5,40(sp)
    800055f6:	f05a                	sd	s6,32(sp)
    800055f8:	ec5e                	sd	s7,24(sp)
    800055fa:	e862                	sd	s8,16(sp)
    800055fc:	1080                	addi	s0,sp,96
    800055fe:	84aa                	mv	s1,a0
    80005600:	8aae                	mv	s5,a1
    80005602:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005604:	ffffc097          	auipc	ra,0xffffc
    80005608:	4fe080e7          	jalr	1278(ra) # 80001b02 <myproc>
    8000560c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000560e:	8526                	mv	a0,s1
    80005610:	ffffb097          	auipc	ra,0xffffb
    80005614:	5c6080e7          	jalr	1478(ra) # 80000bd6 <acquire>
  while(i < n){
    80005618:	0b405663          	blez	s4,800056c4 <pipewrite+0xde>
  int i = 0;
    8000561c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000561e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005620:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005624:	21c48b93          	addi	s7,s1,540
    80005628:	a089                	j	8000566a <pipewrite+0x84>
      release(&pi->lock);
    8000562a:	8526                	mv	a0,s1
    8000562c:	ffffb097          	auipc	ra,0xffffb
    80005630:	65e080e7          	jalr	1630(ra) # 80000c8a <release>
      return -1;
    80005634:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005636:	854a                	mv	a0,s2
    80005638:	60e6                	ld	ra,88(sp)
    8000563a:	6446                	ld	s0,80(sp)
    8000563c:	64a6                	ld	s1,72(sp)
    8000563e:	6906                	ld	s2,64(sp)
    80005640:	79e2                	ld	s3,56(sp)
    80005642:	7a42                	ld	s4,48(sp)
    80005644:	7aa2                	ld	s5,40(sp)
    80005646:	7b02                	ld	s6,32(sp)
    80005648:	6be2                	ld	s7,24(sp)
    8000564a:	6c42                	ld	s8,16(sp)
    8000564c:	6125                	addi	sp,sp,96
    8000564e:	8082                	ret
      wakeup(&pi->nread);
    80005650:	8562                	mv	a0,s8
    80005652:	ffffd097          	auipc	ra,0xffffd
    80005656:	c6e080e7          	jalr	-914(ra) # 800022c0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000565a:	85a6                	mv	a1,s1
    8000565c:	855e                	mv	a0,s7
    8000565e:	ffffd097          	auipc	ra,0xffffd
    80005662:	bfe080e7          	jalr	-1026(ra) # 8000225c <sleep>
  while(i < n){
    80005666:	07495063          	bge	s2,s4,800056c6 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    8000566a:	2204a783          	lw	a5,544(s1)
    8000566e:	dfd5                	beqz	a5,8000562a <pipewrite+0x44>
    80005670:	854e                	mv	a0,s3
    80005672:	ffffd097          	auipc	ra,0xffffd
    80005676:	ea8080e7          	jalr	-344(ra) # 8000251a <killed>
    8000567a:	f945                	bnez	a0,8000562a <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000567c:	2184a783          	lw	a5,536(s1)
    80005680:	21c4a703          	lw	a4,540(s1)
    80005684:	2007879b          	addiw	a5,a5,512
    80005688:	fcf704e3          	beq	a4,a5,80005650 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000568c:	4685                	li	a3,1
    8000568e:	01590633          	add	a2,s2,s5
    80005692:	faf40593          	addi	a1,s0,-81
    80005696:	0509b503          	ld	a0,80(s3)
    8000569a:	ffffc097          	auipc	ra,0xffffc
    8000569e:	1b0080e7          	jalr	432(ra) # 8000184a <copyin>
    800056a2:	03650263          	beq	a0,s6,800056c6 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800056a6:	21c4a783          	lw	a5,540(s1)
    800056aa:	0017871b          	addiw	a4,a5,1
    800056ae:	20e4ae23          	sw	a4,540(s1)
    800056b2:	1ff7f793          	andi	a5,a5,511
    800056b6:	97a6                	add	a5,a5,s1
    800056b8:	faf44703          	lbu	a4,-81(s0)
    800056bc:	00e78c23          	sb	a4,24(a5)
      i++;
    800056c0:	2905                	addiw	s2,s2,1
    800056c2:	b755                	j	80005666 <pipewrite+0x80>
  int i = 0;
    800056c4:	4901                	li	s2,0
  wakeup(&pi->nread);
    800056c6:	21848513          	addi	a0,s1,536
    800056ca:	ffffd097          	auipc	ra,0xffffd
    800056ce:	bf6080e7          	jalr	-1034(ra) # 800022c0 <wakeup>
  release(&pi->lock);
    800056d2:	8526                	mv	a0,s1
    800056d4:	ffffb097          	auipc	ra,0xffffb
    800056d8:	5b6080e7          	jalr	1462(ra) # 80000c8a <release>
  return i;
    800056dc:	bfa9                	j	80005636 <pipewrite+0x50>

00000000800056de <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800056de:	715d                	addi	sp,sp,-80
    800056e0:	e486                	sd	ra,72(sp)
    800056e2:	e0a2                	sd	s0,64(sp)
    800056e4:	fc26                	sd	s1,56(sp)
    800056e6:	f84a                	sd	s2,48(sp)
    800056e8:	f44e                	sd	s3,40(sp)
    800056ea:	f052                	sd	s4,32(sp)
    800056ec:	ec56                	sd	s5,24(sp)
    800056ee:	e85a                	sd	s6,16(sp)
    800056f0:	0880                	addi	s0,sp,80
    800056f2:	84aa                	mv	s1,a0
    800056f4:	892e                	mv	s2,a1
    800056f6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800056f8:	ffffc097          	auipc	ra,0xffffc
    800056fc:	40a080e7          	jalr	1034(ra) # 80001b02 <myproc>
    80005700:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005702:	8526                	mv	a0,s1
    80005704:	ffffb097          	auipc	ra,0xffffb
    80005708:	4d2080e7          	jalr	1234(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000570c:	2184a703          	lw	a4,536(s1)
    80005710:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005714:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005718:	02f71763          	bne	a4,a5,80005746 <piperead+0x68>
    8000571c:	2244a783          	lw	a5,548(s1)
    80005720:	c39d                	beqz	a5,80005746 <piperead+0x68>
    if(killed(pr)){
    80005722:	8552                	mv	a0,s4
    80005724:	ffffd097          	auipc	ra,0xffffd
    80005728:	df6080e7          	jalr	-522(ra) # 8000251a <killed>
    8000572c:	e941                	bnez	a0,800057bc <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000572e:	85a6                	mv	a1,s1
    80005730:	854e                	mv	a0,s3
    80005732:	ffffd097          	auipc	ra,0xffffd
    80005736:	b2a080e7          	jalr	-1238(ra) # 8000225c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000573a:	2184a703          	lw	a4,536(s1)
    8000573e:	21c4a783          	lw	a5,540(s1)
    80005742:	fcf70de3          	beq	a4,a5,8000571c <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005746:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005748:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000574a:	05505363          	blez	s5,80005790 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    8000574e:	2184a783          	lw	a5,536(s1)
    80005752:	21c4a703          	lw	a4,540(s1)
    80005756:	02f70d63          	beq	a4,a5,80005790 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000575a:	0017871b          	addiw	a4,a5,1
    8000575e:	20e4ac23          	sw	a4,536(s1)
    80005762:	1ff7f793          	andi	a5,a5,511
    80005766:	97a6                	add	a5,a5,s1
    80005768:	0187c783          	lbu	a5,24(a5)
    8000576c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005770:	4685                	li	a3,1
    80005772:	fbf40613          	addi	a2,s0,-65
    80005776:	85ca                	mv	a1,s2
    80005778:	050a3503          	ld	a0,80(s4)
    8000577c:	ffffc097          	auipc	ra,0xffffc
    80005780:	042080e7          	jalr	66(ra) # 800017be <copyout>
    80005784:	01650663          	beq	a0,s6,80005790 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005788:	2985                	addiw	s3,s3,1
    8000578a:	0905                	addi	s2,s2,1
    8000578c:	fd3a91e3          	bne	s5,s3,8000574e <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005790:	21c48513          	addi	a0,s1,540
    80005794:	ffffd097          	auipc	ra,0xffffd
    80005798:	b2c080e7          	jalr	-1236(ra) # 800022c0 <wakeup>
  release(&pi->lock);
    8000579c:	8526                	mv	a0,s1
    8000579e:	ffffb097          	auipc	ra,0xffffb
    800057a2:	4ec080e7          	jalr	1260(ra) # 80000c8a <release>
  return i;
}
    800057a6:	854e                	mv	a0,s3
    800057a8:	60a6                	ld	ra,72(sp)
    800057aa:	6406                	ld	s0,64(sp)
    800057ac:	74e2                	ld	s1,56(sp)
    800057ae:	7942                	ld	s2,48(sp)
    800057b0:	79a2                	ld	s3,40(sp)
    800057b2:	7a02                	ld	s4,32(sp)
    800057b4:	6ae2                	ld	s5,24(sp)
    800057b6:	6b42                	ld	s6,16(sp)
    800057b8:	6161                	addi	sp,sp,80
    800057ba:	8082                	ret
      release(&pi->lock);
    800057bc:	8526                	mv	a0,s1
    800057be:	ffffb097          	auipc	ra,0xffffb
    800057c2:	4cc080e7          	jalr	1228(ra) # 80000c8a <release>
      return -1;
    800057c6:	59fd                	li	s3,-1
    800057c8:	bff9                	j	800057a6 <piperead+0xc8>

00000000800057ca <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    800057ca:	1141                	addi	sp,sp,-16
    800057cc:	e422                	sd	s0,8(sp)
    800057ce:	0800                	addi	s0,sp,16
    800057d0:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800057d2:	8905                	andi	a0,a0,1
    800057d4:	c111                	beqz	a0,800057d8 <flags2perm+0xe>
      perm = PTE_X;
    800057d6:	4521                	li	a0,8
    if(flags & 0x2)
    800057d8:	8b89                	andi	a5,a5,2
    800057da:	c399                	beqz	a5,800057e0 <flags2perm+0x16>
      perm |= PTE_W;
    800057dc:	00456513          	ori	a0,a0,4
    return perm;
}
    800057e0:	6422                	ld	s0,8(sp)
    800057e2:	0141                	addi	sp,sp,16
    800057e4:	8082                	ret

00000000800057e6 <exec>:

int
exec(char *path, char **argv)
{
    800057e6:	de010113          	addi	sp,sp,-544
    800057ea:	20113c23          	sd	ra,536(sp)
    800057ee:	20813823          	sd	s0,528(sp)
    800057f2:	20913423          	sd	s1,520(sp)
    800057f6:	21213023          	sd	s2,512(sp)
    800057fa:	ffce                	sd	s3,504(sp)
    800057fc:	fbd2                	sd	s4,496(sp)
    800057fe:	f7d6                	sd	s5,488(sp)
    80005800:	f3da                	sd	s6,480(sp)
    80005802:	efde                	sd	s7,472(sp)
    80005804:	ebe2                	sd	s8,464(sp)
    80005806:	e7e6                	sd	s9,456(sp)
    80005808:	e3ea                	sd	s10,448(sp)
    8000580a:	ff6e                	sd	s11,440(sp)
    8000580c:	1400                	addi	s0,sp,544
    8000580e:	dea43c23          	sd	a0,-520(s0)
    80005812:	deb43423          	sd	a1,-536(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005816:	ffffc097          	auipc	ra,0xffffc
    8000581a:	2ec080e7          	jalr	748(ra) # 80001b02 <myproc>
    8000581e:	84aa                	mv	s1,a0

   //free the swap file when its not the shell& init proc 
  if(p->pid>2){
    80005820:	5918                	lw	a4,48(a0)
    80005822:	4789                	li	a5,2
    80005824:	04e7df63          	bge	a5,a4,80005882 <exec+0x9c>
    struct metaData *page=p->pagesInPysical;
    80005828:	28050713          	addi	a4,a0,640
    while(page< &p->pagesInPysical[MAX_PSYC_PAGES]){
    8000582c:	48050793          	addi	a5,a0,1152
    80005830:	86be                	mv	a3,a5
      page->aging=0;
    80005832:	00073c23          	sd	zero,24(a4)
      page->pageCreateTime=0;
    80005836:	00073823          	sd	zero,16(a4)
      page->idxIsHere=0;
    8000583a:	00073423          	sd	zero,8(a4)
      page->va=0;
    8000583e:	00073023          	sd	zero,0(a4)
      page++;
    80005842:	02070713          	addi	a4,a4,32
    while(page< &p->pagesInPysical[MAX_PSYC_PAGES]){
    80005846:	fed716e3          	bne	a4,a3,80005832 <exec+0x4c>
    }
    
    page=p->pagesInSwap;
    while(page< &p->pagesInSwap[MAX_PSYC_PAGES]){
    8000584a:	68048713          	addi	a4,s1,1664
      page->aging=0;
    8000584e:	0007bc23          	sd	zero,24(a5)
      page->pageCreateTime=0;
    80005852:	0007b823          	sd	zero,16(a5)
      page->idxIsHere=0;
    80005856:	0007b423          	sd	zero,8(a5)
      page->va=0;
    8000585a:	0007b023          	sd	zero,0(a5)
      page++;
    8000585e:	02078793          	addi	a5,a5,32
    while(page< &p->pagesInSwap[MAX_PSYC_PAGES]){
    80005862:	fee796e3          	bne	a5,a4,8000584e <exec+0x68>
    }
    p->swapPagesCount=0;
    80005866:	2604bc23          	sd	zero,632(s1)
    p->physicalPagesCount=0;
    8000586a:	2604b823          	sd	zero,624(s1)
    removeSwapFile(p);
    8000586e:	8526                	mv	a0,s1
    80005870:	fffff097          	auipc	ra,0xfffff
    80005874:	ce0080e7          	jalr	-800(ra) # 80004550 <removeSwapFile>
    createSwapFile(p);
    80005878:	8526                	mv	a0,s1
    8000587a:	fffff097          	auipc	ra,0xfffff
    8000587e:	e7e080e7          	jalr	-386(ra) # 800046f8 <createSwapFile>
  }

  begin_op();
    80005882:	fffff097          	auipc	ra,0xfffff
    80005886:	18c080e7          	jalr	396(ra) # 80004a0e <begin_op>

  if((ip = namei(path)) == 0){
    8000588a:	df843503          	ld	a0,-520(s0)
    8000588e:	fffff097          	auipc	ra,0xfffff
    80005892:	c16080e7          	jalr	-1002(ra) # 800044a4 <namei>
    80005896:	8aaa                	mv	s5,a0
    80005898:	c935                	beqz	a0,8000590c <exec+0x126>
    end_op();
    return -1;
  }
  ilock(ip);
    8000589a:	ffffe097          	auipc	ra,0xffffe
    8000589e:	464080e7          	jalr	1124(ra) # 80003cfe <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800058a2:	04000713          	li	a4,64
    800058a6:	4681                	li	a3,0
    800058a8:	e5040613          	addi	a2,s0,-432
    800058ac:	4581                	li	a1,0
    800058ae:	8556                	mv	a0,s5
    800058b0:	ffffe097          	auipc	ra,0xffffe
    800058b4:	702080e7          	jalr	1794(ra) # 80003fb2 <readi>
    800058b8:	04000793          	li	a5,64
    800058bc:	00f51a63          	bne	a0,a5,800058d0 <exec+0xea>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800058c0:	e5042703          	lw	a4,-432(s0)
    800058c4:	464c47b7          	lui	a5,0x464c4
    800058c8:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800058cc:	04f70663          	beq	a4,a5,80005918 <exec+0x132>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800058d0:	8556                	mv	a0,s5
    800058d2:	ffffe097          	auipc	ra,0xffffe
    800058d6:	68e080e7          	jalr	1678(ra) # 80003f60 <iunlockput>
    end_op();
    800058da:	fffff097          	auipc	ra,0xfffff
    800058de:	1b4080e7          	jalr	436(ra) # 80004a8e <end_op>
  }
  return -1;
    800058e2:	557d                	li	a0,-1
}
    800058e4:	21813083          	ld	ra,536(sp)
    800058e8:	21013403          	ld	s0,528(sp)
    800058ec:	20813483          	ld	s1,520(sp)
    800058f0:	20013903          	ld	s2,512(sp)
    800058f4:	79fe                	ld	s3,504(sp)
    800058f6:	7a5e                	ld	s4,496(sp)
    800058f8:	7abe                	ld	s5,488(sp)
    800058fa:	7b1e                	ld	s6,480(sp)
    800058fc:	6bfe                	ld	s7,472(sp)
    800058fe:	6c5e                	ld	s8,464(sp)
    80005900:	6cbe                	ld	s9,456(sp)
    80005902:	6d1e                	ld	s10,448(sp)
    80005904:	7dfa                	ld	s11,440(sp)
    80005906:	22010113          	addi	sp,sp,544
    8000590a:	8082                	ret
    end_op();
    8000590c:	fffff097          	auipc	ra,0xfffff
    80005910:	182080e7          	jalr	386(ra) # 80004a8e <end_op>
    return -1;
    80005914:	557d                	li	a0,-1
    80005916:	b7f9                	j	800058e4 <exec+0xfe>
  if((pagetable = proc_pagetable(p)) == 0)
    80005918:	8526                	mv	a0,s1
    8000591a:	ffffc097          	auipc	ra,0xffffc
    8000591e:	2ac080e7          	jalr	684(ra) # 80001bc6 <proc_pagetable>
    80005922:	8b2a                	mv	s6,a0
    80005924:	d555                	beqz	a0,800058d0 <exec+0xea>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005926:	e7042783          	lw	a5,-400(s0)
    8000592a:	e8845703          	lhu	a4,-376(s0)
    8000592e:	c735                	beqz	a4,8000599a <exec+0x1b4>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005930:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005932:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005936:	6a05                	lui	s4,0x1
    80005938:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    8000593c:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005940:	6d85                	lui	s11,0x1
    80005942:	7d7d                	lui	s10,0xfffff
    80005944:	a481                	j	80005b84 <exec+0x39e>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005946:	00003517          	auipc	a0,0x3
    8000594a:	f3250513          	addi	a0,a0,-206 # 80008878 <syscalls+0x330>
    8000594e:	ffffb097          	auipc	ra,0xffffb
    80005952:	bf0080e7          	jalr	-1040(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005956:	874a                	mv	a4,s2
    80005958:	009c86bb          	addw	a3,s9,s1
    8000595c:	4581                	li	a1,0
    8000595e:	8556                	mv	a0,s5
    80005960:	ffffe097          	auipc	ra,0xffffe
    80005964:	652080e7          	jalr	1618(ra) # 80003fb2 <readi>
    80005968:	2501                	sext.w	a0,a0
    8000596a:	1aa91a63          	bne	s2,a0,80005b1e <exec+0x338>
  for(i = 0; i < sz; i += PGSIZE){
    8000596e:	009d84bb          	addw	s1,s11,s1
    80005972:	013d09bb          	addw	s3,s10,s3
    80005976:	1f74f763          	bgeu	s1,s7,80005b64 <exec+0x37e>
    pa = walkaddr(pagetable, va + i);
    8000597a:	02049593          	slli	a1,s1,0x20
    8000597e:	9181                	srli	a1,a1,0x20
    80005980:	95e2                	add	a1,a1,s8
    80005982:	855a                	mv	a0,s6
    80005984:	ffffb097          	auipc	ra,0xffffb
    80005988:	78c080e7          	jalr	1932(ra) # 80001110 <walkaddr>
    8000598c:	862a                	mv	a2,a0
    if(pa == 0)
    8000598e:	dd45                	beqz	a0,80005946 <exec+0x160>
      n = PGSIZE;
    80005990:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005992:	fd49f2e3          	bgeu	s3,s4,80005956 <exec+0x170>
      n = sz - i;
    80005996:	894e                	mv	s2,s3
    80005998:	bf7d                	j	80005956 <exec+0x170>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000599a:	4901                	li	s2,0
  iunlockput(ip);
    8000599c:	8556                	mv	a0,s5
    8000599e:	ffffe097          	auipc	ra,0xffffe
    800059a2:	5c2080e7          	jalr	1474(ra) # 80003f60 <iunlockput>
  end_op();
    800059a6:	fffff097          	auipc	ra,0xfffff
    800059aa:	0e8080e7          	jalr	232(ra) # 80004a8e <end_op>
  p = myproc();
    800059ae:	ffffc097          	auipc	ra,0xffffc
    800059b2:	154080e7          	jalr	340(ra) # 80001b02 <myproc>
    800059b6:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800059b8:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800059bc:	6785                	lui	a5,0x1
    800059be:	17fd                	addi	a5,a5,-1
    800059c0:	993e                	add	s2,s2,a5
    800059c2:	77fd                	lui	a5,0xfffff
    800059c4:	00f977b3          	and	a5,s2,a5
    800059c8:	def43823          	sd	a5,-528(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800059cc:	4691                	li	a3,4
    800059ce:	6609                	lui	a2,0x2
    800059d0:	963e                	add	a2,a2,a5
    800059d2:	85be                	mv	a1,a5
    800059d4:	855a                	mv	a0,s6
    800059d6:	ffffc097          	auipc	ra,0xffffc
    800059da:	afe080e7          	jalr	-1282(ra) # 800014d4 <uvmalloc>
    800059de:	8c2a                	mv	s8,a0
  ip = 0;
    800059e0:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800059e2:	12050e63          	beqz	a0,80005b1e <exec+0x338>
  uvmclear(pagetable, sz-2*PGSIZE);
    800059e6:	75f9                	lui	a1,0xffffe
    800059e8:	95aa                	add	a1,a1,a0
    800059ea:	855a                	mv	a0,s6
    800059ec:	ffffc097          	auipc	ra,0xffffc
    800059f0:	da0080e7          	jalr	-608(ra) # 8000178c <uvmclear>
  stackbase = sp - PGSIZE;
    800059f4:	7afd                	lui	s5,0xfffff
    800059f6:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800059f8:	de843783          	ld	a5,-536(s0)
    800059fc:	6388                	ld	a0,0(a5)
    800059fe:	c925                	beqz	a0,80005a6e <exec+0x288>
    80005a00:	e9040993          	addi	s3,s0,-368
    80005a04:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005a08:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005a0a:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005a0c:	ffffb097          	auipc	ra,0xffffb
    80005a10:	442080e7          	jalr	1090(ra) # 80000e4e <strlen>
    80005a14:	0015079b          	addiw	a5,a0,1
    80005a18:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005a1c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005a20:	13596663          	bltu	s2,s5,80005b4c <exec+0x366>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005a24:	de843d83          	ld	s11,-536(s0)
    80005a28:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005a2c:	8552                	mv	a0,s4
    80005a2e:	ffffb097          	auipc	ra,0xffffb
    80005a32:	420080e7          	jalr	1056(ra) # 80000e4e <strlen>
    80005a36:	0015069b          	addiw	a3,a0,1
    80005a3a:	8652                	mv	a2,s4
    80005a3c:	85ca                	mv	a1,s2
    80005a3e:	855a                	mv	a0,s6
    80005a40:	ffffc097          	auipc	ra,0xffffc
    80005a44:	d7e080e7          	jalr	-642(ra) # 800017be <copyout>
    80005a48:	10054663          	bltz	a0,80005b54 <exec+0x36e>
    ustack[argc] = sp;
    80005a4c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005a50:	0485                	addi	s1,s1,1
    80005a52:	008d8793          	addi	a5,s11,8
    80005a56:	def43423          	sd	a5,-536(s0)
    80005a5a:	008db503          	ld	a0,8(s11)
    80005a5e:	c911                	beqz	a0,80005a72 <exec+0x28c>
    if(argc >= MAXARG)
    80005a60:	09a1                	addi	s3,s3,8
    80005a62:	fb9995e3          	bne	s3,s9,80005a0c <exec+0x226>
  sz = sz1;
    80005a66:	df843823          	sd	s8,-528(s0)
  ip = 0;
    80005a6a:	4a81                	li	s5,0
    80005a6c:	a84d                	j	80005b1e <exec+0x338>
  sp = sz;
    80005a6e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005a70:	4481                	li	s1,0
  ustack[argc] = 0;
    80005a72:	00349793          	slli	a5,s1,0x3
    80005a76:	f9040713          	addi	a4,s0,-112
    80005a7a:	97ba                	add	a5,a5,a4
    80005a7c:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffc8830>
  sp -= (argc+1) * sizeof(uint64);
    80005a80:	00148693          	addi	a3,s1,1
    80005a84:	068e                	slli	a3,a3,0x3
    80005a86:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005a8a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005a8e:	01597663          	bgeu	s2,s5,80005a9a <exec+0x2b4>
  sz = sz1;
    80005a92:	df843823          	sd	s8,-528(s0)
  ip = 0;
    80005a96:	4a81                	li	s5,0
    80005a98:	a059                	j	80005b1e <exec+0x338>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005a9a:	e9040613          	addi	a2,s0,-368
    80005a9e:	85ca                	mv	a1,s2
    80005aa0:	855a                	mv	a0,s6
    80005aa2:	ffffc097          	auipc	ra,0xffffc
    80005aa6:	d1c080e7          	jalr	-740(ra) # 800017be <copyout>
    80005aaa:	0a054963          	bltz	a0,80005b5c <exec+0x376>
  p->trapframe->a1 = sp;
    80005aae:	058bb783          	ld	a5,88(s7)
    80005ab2:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005ab6:	df843783          	ld	a5,-520(s0)
    80005aba:	0007c703          	lbu	a4,0(a5)
    80005abe:	cf11                	beqz	a4,80005ada <exec+0x2f4>
    80005ac0:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005ac2:	02f00693          	li	a3,47
    80005ac6:	a039                	j	80005ad4 <exec+0x2ee>
      last = s+1;
    80005ac8:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005acc:	0785                	addi	a5,a5,1
    80005ace:	fff7c703          	lbu	a4,-1(a5)
    80005ad2:	c701                	beqz	a4,80005ada <exec+0x2f4>
    if(*s == '/')
    80005ad4:	fed71ce3          	bne	a4,a3,80005acc <exec+0x2e6>
    80005ad8:	bfc5                	j	80005ac8 <exec+0x2e2>
  safestrcpy(p->name, last, sizeof(p->name));
    80005ada:	4641                	li	a2,16
    80005adc:	df843583          	ld	a1,-520(s0)
    80005ae0:	158b8513          	addi	a0,s7,344
    80005ae4:	ffffb097          	auipc	ra,0xffffb
    80005ae8:	338080e7          	jalr	824(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80005aec:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005af0:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005af4:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005af8:	058bb783          	ld	a5,88(s7)
    80005afc:	e6843703          	ld	a4,-408(s0)
    80005b00:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005b02:	058bb783          	ld	a5,88(s7)
    80005b06:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005b0a:	85ea                	mv	a1,s10
    80005b0c:	ffffc097          	auipc	ra,0xffffc
    80005b10:	156080e7          	jalr	342(ra) # 80001c62 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005b14:	0004851b          	sext.w	a0,s1
    80005b18:	b3f1                	j	800058e4 <exec+0xfe>
    80005b1a:	df243823          	sd	s2,-528(s0)
    proc_freepagetable(pagetable, sz);
    80005b1e:	df043583          	ld	a1,-528(s0)
    80005b22:	855a                	mv	a0,s6
    80005b24:	ffffc097          	auipc	ra,0xffffc
    80005b28:	13e080e7          	jalr	318(ra) # 80001c62 <proc_freepagetable>
  if(ip){
    80005b2c:	da0a92e3          	bnez	s5,800058d0 <exec+0xea>
  return -1;
    80005b30:	557d                	li	a0,-1
    80005b32:	bb4d                	j	800058e4 <exec+0xfe>
    80005b34:	df243823          	sd	s2,-528(s0)
    80005b38:	b7dd                	j	80005b1e <exec+0x338>
    80005b3a:	df243823          	sd	s2,-528(s0)
    80005b3e:	b7c5                	j	80005b1e <exec+0x338>
    80005b40:	df243823          	sd	s2,-528(s0)
    80005b44:	bfe9                	j	80005b1e <exec+0x338>
    80005b46:	df243823          	sd	s2,-528(s0)
    80005b4a:	bfd1                	j	80005b1e <exec+0x338>
  sz = sz1;
    80005b4c:	df843823          	sd	s8,-528(s0)
  ip = 0;
    80005b50:	4a81                	li	s5,0
    80005b52:	b7f1                	j	80005b1e <exec+0x338>
  sz = sz1;
    80005b54:	df843823          	sd	s8,-528(s0)
  ip = 0;
    80005b58:	4a81                	li	s5,0
    80005b5a:	b7d1                	j	80005b1e <exec+0x338>
  sz = sz1;
    80005b5c:	df843823          	sd	s8,-528(s0)
  ip = 0;
    80005b60:	4a81                	li	s5,0
    80005b62:	bf75                	j	80005b1e <exec+0x338>
    sz = sz1;
    80005b64:	df043903          	ld	s2,-528(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005b68:	e0843783          	ld	a5,-504(s0)
    80005b6c:	0017869b          	addiw	a3,a5,1
    80005b70:	e0d43423          	sd	a3,-504(s0)
    80005b74:	e0043783          	ld	a5,-512(s0)
    80005b78:	0387879b          	addiw	a5,a5,56
    80005b7c:	e8845703          	lhu	a4,-376(s0)
    80005b80:	e0e6dee3          	bge	a3,a4,8000599c <exec+0x1b6>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005b84:	2781                	sext.w	a5,a5
    80005b86:	e0f43023          	sd	a5,-512(s0)
    80005b8a:	03800713          	li	a4,56
    80005b8e:	86be                	mv	a3,a5
    80005b90:	e1840613          	addi	a2,s0,-488
    80005b94:	4581                	li	a1,0
    80005b96:	8556                	mv	a0,s5
    80005b98:	ffffe097          	auipc	ra,0xffffe
    80005b9c:	41a080e7          	jalr	1050(ra) # 80003fb2 <readi>
    80005ba0:	03800793          	li	a5,56
    80005ba4:	f6f51be3          	bne	a0,a5,80005b1a <exec+0x334>
    if(ph.type != ELF_PROG_LOAD)
    80005ba8:	e1842783          	lw	a5,-488(s0)
    80005bac:	4705                	li	a4,1
    80005bae:	fae79de3          	bne	a5,a4,80005b68 <exec+0x382>
    if(ph.memsz < ph.filesz)
    80005bb2:	e4043483          	ld	s1,-448(s0)
    80005bb6:	e3843783          	ld	a5,-456(s0)
    80005bba:	f6f4ede3          	bltu	s1,a5,80005b34 <exec+0x34e>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005bbe:	e2843783          	ld	a5,-472(s0)
    80005bc2:	94be                	add	s1,s1,a5
    80005bc4:	f6f4ebe3          	bltu	s1,a5,80005b3a <exec+0x354>
    if(ph.vaddr % PGSIZE != 0)
    80005bc8:	de043703          	ld	a4,-544(s0)
    80005bcc:	8ff9                	and	a5,a5,a4
    80005bce:	fbad                	bnez	a5,80005b40 <exec+0x35a>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005bd0:	e1c42503          	lw	a0,-484(s0)
    80005bd4:	00000097          	auipc	ra,0x0
    80005bd8:	bf6080e7          	jalr	-1034(ra) # 800057ca <flags2perm>
    80005bdc:	86aa                	mv	a3,a0
    80005bde:	8626                	mv	a2,s1
    80005be0:	85ca                	mv	a1,s2
    80005be2:	855a                	mv	a0,s6
    80005be4:	ffffc097          	auipc	ra,0xffffc
    80005be8:	8f0080e7          	jalr	-1808(ra) # 800014d4 <uvmalloc>
    80005bec:	dea43823          	sd	a0,-528(s0)
    80005bf0:	d939                	beqz	a0,80005b46 <exec+0x360>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005bf2:	e2843c03          	ld	s8,-472(s0)
    80005bf6:	e2042c83          	lw	s9,-480(s0)
    80005bfa:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005bfe:	f60b83e3          	beqz	s7,80005b64 <exec+0x37e>
    80005c02:	89de                	mv	s3,s7
    80005c04:	4481                	li	s1,0
    80005c06:	bb95                	j	8000597a <exec+0x194>

0000000080005c08 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005c08:	7179                	addi	sp,sp,-48
    80005c0a:	f406                	sd	ra,40(sp)
    80005c0c:	f022                	sd	s0,32(sp)
    80005c0e:	ec26                	sd	s1,24(sp)
    80005c10:	e84a                	sd	s2,16(sp)
    80005c12:	1800                	addi	s0,sp,48
    80005c14:	892e                	mv	s2,a1
    80005c16:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005c18:	fdc40593          	addi	a1,s0,-36
    80005c1c:	ffffd097          	auipc	ra,0xffffd
    80005c20:	576080e7          	jalr	1398(ra) # 80003192 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005c24:	fdc42703          	lw	a4,-36(s0)
    80005c28:	47bd                	li	a5,15
    80005c2a:	02e7eb63          	bltu	a5,a4,80005c60 <argfd+0x58>
    80005c2e:	ffffc097          	auipc	ra,0xffffc
    80005c32:	ed4080e7          	jalr	-300(ra) # 80001b02 <myproc>
    80005c36:	fdc42703          	lw	a4,-36(s0)
    80005c3a:	01a70793          	addi	a5,a4,26
    80005c3e:	078e                	slli	a5,a5,0x3
    80005c40:	953e                	add	a0,a0,a5
    80005c42:	611c                	ld	a5,0(a0)
    80005c44:	c385                	beqz	a5,80005c64 <argfd+0x5c>
    return -1;
  if(pfd)
    80005c46:	00090463          	beqz	s2,80005c4e <argfd+0x46>
    *pfd = fd;
    80005c4a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005c4e:	4501                	li	a0,0
  if(pf)
    80005c50:	c091                	beqz	s1,80005c54 <argfd+0x4c>
    *pf = f;
    80005c52:	e09c                	sd	a5,0(s1)
}
    80005c54:	70a2                	ld	ra,40(sp)
    80005c56:	7402                	ld	s0,32(sp)
    80005c58:	64e2                	ld	s1,24(sp)
    80005c5a:	6942                	ld	s2,16(sp)
    80005c5c:	6145                	addi	sp,sp,48
    80005c5e:	8082                	ret
    return -1;
    80005c60:	557d                	li	a0,-1
    80005c62:	bfcd                	j	80005c54 <argfd+0x4c>
    80005c64:	557d                	li	a0,-1
    80005c66:	b7fd                	j	80005c54 <argfd+0x4c>

0000000080005c68 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005c68:	1101                	addi	sp,sp,-32
    80005c6a:	ec06                	sd	ra,24(sp)
    80005c6c:	e822                	sd	s0,16(sp)
    80005c6e:	e426                	sd	s1,8(sp)
    80005c70:	1000                	addi	s0,sp,32
    80005c72:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005c74:	ffffc097          	auipc	ra,0xffffc
    80005c78:	e8e080e7          	jalr	-370(ra) # 80001b02 <myproc>
    80005c7c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005c7e:	0d050793          	addi	a5,a0,208
    80005c82:	4501                	li	a0,0
    80005c84:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005c86:	6398                	ld	a4,0(a5)
    80005c88:	cb19                	beqz	a4,80005c9e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005c8a:	2505                	addiw	a0,a0,1
    80005c8c:	07a1                	addi	a5,a5,8
    80005c8e:	fed51ce3          	bne	a0,a3,80005c86 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005c92:	557d                	li	a0,-1
}
    80005c94:	60e2                	ld	ra,24(sp)
    80005c96:	6442                	ld	s0,16(sp)
    80005c98:	64a2                	ld	s1,8(sp)
    80005c9a:	6105                	addi	sp,sp,32
    80005c9c:	8082                	ret
      p->ofile[fd] = f;
    80005c9e:	01a50793          	addi	a5,a0,26
    80005ca2:	078e                	slli	a5,a5,0x3
    80005ca4:	963e                	add	a2,a2,a5
    80005ca6:	e204                	sd	s1,0(a2)
      return fd;
    80005ca8:	b7f5                	j	80005c94 <fdalloc+0x2c>

0000000080005caa <sys_dup>:

uint64
sys_dup(void)
{
    80005caa:	7179                	addi	sp,sp,-48
    80005cac:	f406                	sd	ra,40(sp)
    80005cae:	f022                	sd	s0,32(sp)
    80005cb0:	ec26                	sd	s1,24(sp)
    80005cb2:	1800                	addi	s0,sp,48
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)
    80005cb4:	fd840613          	addi	a2,s0,-40
    80005cb8:	4581                	li	a1,0
    80005cba:	4501                	li	a0,0
    80005cbc:	00000097          	auipc	ra,0x0
    80005cc0:	f4c080e7          	jalr	-180(ra) # 80005c08 <argfd>
    return -1;
    80005cc4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005cc6:	02054363          	bltz	a0,80005cec <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005cca:	fd843503          	ld	a0,-40(s0)
    80005cce:	00000097          	auipc	ra,0x0
    80005cd2:	f9a080e7          	jalr	-102(ra) # 80005c68 <fdalloc>
    80005cd6:	84aa                	mv	s1,a0
    return -1;
    80005cd8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005cda:	00054963          	bltz	a0,80005cec <sys_dup+0x42>
  filedup(f);
    80005cde:	fd843503          	ld	a0,-40(s0)
    80005ce2:	fffff097          	auipc	ra,0xfffff
    80005ce6:	1a6080e7          	jalr	422(ra) # 80004e88 <filedup>
  return fd;
    80005cea:	87a6                	mv	a5,s1
}
    80005cec:	853e                	mv	a0,a5
    80005cee:	70a2                	ld	ra,40(sp)
    80005cf0:	7402                	ld	s0,32(sp)
    80005cf2:	64e2                	ld	s1,24(sp)
    80005cf4:	6145                	addi	sp,sp,48
    80005cf6:	8082                	ret

0000000080005cf8 <sys_read>:

uint64
sys_read(void)
{
    80005cf8:	7179                	addi	sp,sp,-48
    80005cfa:	f406                	sd	ra,40(sp)
    80005cfc:	f022                	sd	s0,32(sp)
    80005cfe:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  argaddr(1, &p);
    80005d00:	fd840593          	addi	a1,s0,-40
    80005d04:	4505                	li	a0,1
    80005d06:	ffffd097          	auipc	ra,0xffffd
    80005d0a:	4ac080e7          	jalr	1196(ra) # 800031b2 <argaddr>
  argint(2, &n);
    80005d0e:	fe440593          	addi	a1,s0,-28
    80005d12:	4509                	li	a0,2
    80005d14:	ffffd097          	auipc	ra,0xffffd
    80005d18:	47e080e7          	jalr	1150(ra) # 80003192 <argint>
  if(argfd(0, 0, &f) < 0)
    80005d1c:	fe840613          	addi	a2,s0,-24
    80005d20:	4581                	li	a1,0
    80005d22:	4501                	li	a0,0
    80005d24:	00000097          	auipc	ra,0x0
    80005d28:	ee4080e7          	jalr	-284(ra) # 80005c08 <argfd>
    80005d2c:	87aa                	mv	a5,a0
    return -1;
    80005d2e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005d30:	0007cc63          	bltz	a5,80005d48 <sys_read+0x50>
  return fileread(f, p, n);
    80005d34:	fe442603          	lw	a2,-28(s0)
    80005d38:	fd843583          	ld	a1,-40(s0)
    80005d3c:	fe843503          	ld	a0,-24(s0)
    80005d40:	fffff097          	auipc	ra,0xfffff
    80005d44:	2d4080e7          	jalr	724(ra) # 80005014 <fileread>
}
    80005d48:	70a2                	ld	ra,40(sp)
    80005d4a:	7402                	ld	s0,32(sp)
    80005d4c:	6145                	addi	sp,sp,48
    80005d4e:	8082                	ret

0000000080005d50 <sys_write>:

uint64
sys_write(void)
{
    80005d50:	7179                	addi	sp,sp,-48
    80005d52:	f406                	sd	ra,40(sp)
    80005d54:	f022                	sd	s0,32(sp)
    80005d56:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;
  
  argaddr(1, &p);
    80005d58:	fd840593          	addi	a1,s0,-40
    80005d5c:	4505                	li	a0,1
    80005d5e:	ffffd097          	auipc	ra,0xffffd
    80005d62:	454080e7          	jalr	1108(ra) # 800031b2 <argaddr>
  argint(2, &n);
    80005d66:	fe440593          	addi	a1,s0,-28
    80005d6a:	4509                	li	a0,2
    80005d6c:	ffffd097          	auipc	ra,0xffffd
    80005d70:	426080e7          	jalr	1062(ra) # 80003192 <argint>
  if(argfd(0, 0, &f) < 0)
    80005d74:	fe840613          	addi	a2,s0,-24
    80005d78:	4581                	li	a1,0
    80005d7a:	4501                	li	a0,0
    80005d7c:	00000097          	auipc	ra,0x0
    80005d80:	e8c080e7          	jalr	-372(ra) # 80005c08 <argfd>
    80005d84:	87aa                	mv	a5,a0
    return -1;
    80005d86:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005d88:	0007cc63          	bltz	a5,80005da0 <sys_write+0x50>

  return filewrite(f, p, n);
    80005d8c:	fe442603          	lw	a2,-28(s0)
    80005d90:	fd843583          	ld	a1,-40(s0)
    80005d94:	fe843503          	ld	a0,-24(s0)
    80005d98:	fffff097          	auipc	ra,0xfffff
    80005d9c:	33e080e7          	jalr	830(ra) # 800050d6 <filewrite>
}
    80005da0:	70a2                	ld	ra,40(sp)
    80005da2:	7402                	ld	s0,32(sp)
    80005da4:	6145                	addi	sp,sp,48
    80005da6:	8082                	ret

0000000080005da8 <sys_close>:

uint64
sys_close(void)
{
    80005da8:	1101                	addi	sp,sp,-32
    80005daa:	ec06                	sd	ra,24(sp)
    80005dac:	e822                	sd	s0,16(sp)
    80005dae:	1000                	addi	s0,sp,32
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)
    80005db0:	fe040613          	addi	a2,s0,-32
    80005db4:	fec40593          	addi	a1,s0,-20
    80005db8:	4501                	li	a0,0
    80005dba:	00000097          	auipc	ra,0x0
    80005dbe:	e4e080e7          	jalr	-434(ra) # 80005c08 <argfd>
    return -1;
    80005dc2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005dc4:	02054463          	bltz	a0,80005dec <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005dc8:	ffffc097          	auipc	ra,0xffffc
    80005dcc:	d3a080e7          	jalr	-710(ra) # 80001b02 <myproc>
    80005dd0:	fec42783          	lw	a5,-20(s0)
    80005dd4:	07e9                	addi	a5,a5,26
    80005dd6:	078e                	slli	a5,a5,0x3
    80005dd8:	97aa                	add	a5,a5,a0
    80005dda:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005dde:	fe043503          	ld	a0,-32(s0)
    80005de2:	fffff097          	auipc	ra,0xfffff
    80005de6:	0f8080e7          	jalr	248(ra) # 80004eda <fileclose>
  return 0;
    80005dea:	4781                	li	a5,0
}
    80005dec:	853e                	mv	a0,a5
    80005dee:	60e2                	ld	ra,24(sp)
    80005df0:	6442                	ld	s0,16(sp)
    80005df2:	6105                	addi	sp,sp,32
    80005df4:	8082                	ret

0000000080005df6 <sys_fstat>:

uint64
sys_fstat(void)
{
    80005df6:	1101                	addi	sp,sp,-32
    80005df8:	ec06                	sd	ra,24(sp)
    80005dfa:	e822                	sd	s0,16(sp)
    80005dfc:	1000                	addi	s0,sp,32
  struct file *f;
  uint64 st; // user pointer to struct stat

  argaddr(1, &st);
    80005dfe:	fe040593          	addi	a1,s0,-32
    80005e02:	4505                	li	a0,1
    80005e04:	ffffd097          	auipc	ra,0xffffd
    80005e08:	3ae080e7          	jalr	942(ra) # 800031b2 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005e0c:	fe840613          	addi	a2,s0,-24
    80005e10:	4581                	li	a1,0
    80005e12:	4501                	li	a0,0
    80005e14:	00000097          	auipc	ra,0x0
    80005e18:	df4080e7          	jalr	-524(ra) # 80005c08 <argfd>
    80005e1c:	87aa                	mv	a5,a0
    return -1;
    80005e1e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005e20:	0007ca63          	bltz	a5,80005e34 <sys_fstat+0x3e>
  return filestat(f, st);
    80005e24:	fe043583          	ld	a1,-32(s0)
    80005e28:	fe843503          	ld	a0,-24(s0)
    80005e2c:	fffff097          	auipc	ra,0xfffff
    80005e30:	176080e7          	jalr	374(ra) # 80004fa2 <filestat>
}
    80005e34:	60e2                	ld	ra,24(sp)
    80005e36:	6442                	ld	s0,16(sp)
    80005e38:	6105                	addi	sp,sp,32
    80005e3a:	8082                	ret

0000000080005e3c <sys_link>:

// Create the path new as a link to the same inode as old.
uint64
sys_link(void)
{
    80005e3c:	7169                	addi	sp,sp,-304
    80005e3e:	f606                	sd	ra,296(sp)
    80005e40:	f222                	sd	s0,288(sp)
    80005e42:	ee26                	sd	s1,280(sp)
    80005e44:	ea4a                	sd	s2,272(sp)
    80005e46:	1a00                	addi	s0,sp,304
  char name[DIRSIZ], new[MAXPATH], old[MAXPATH];
  struct inode *dp, *ip;

  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005e48:	08000613          	li	a2,128
    80005e4c:	ed040593          	addi	a1,s0,-304
    80005e50:	4501                	li	a0,0
    80005e52:	ffffd097          	auipc	ra,0xffffd
    80005e56:	380080e7          	jalr	896(ra) # 800031d2 <argstr>
    return -1;
    80005e5a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005e5c:	10054e63          	bltz	a0,80005f78 <sys_link+0x13c>
    80005e60:	08000613          	li	a2,128
    80005e64:	f5040593          	addi	a1,s0,-176
    80005e68:	4505                	li	a0,1
    80005e6a:	ffffd097          	auipc	ra,0xffffd
    80005e6e:	368080e7          	jalr	872(ra) # 800031d2 <argstr>
    return -1;
    80005e72:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005e74:	10054263          	bltz	a0,80005f78 <sys_link+0x13c>

  begin_op();
    80005e78:	fffff097          	auipc	ra,0xfffff
    80005e7c:	b96080e7          	jalr	-1130(ra) # 80004a0e <begin_op>
  if((ip = namei(old)) == 0){
    80005e80:	ed040513          	addi	a0,s0,-304
    80005e84:	ffffe097          	auipc	ra,0xffffe
    80005e88:	620080e7          	jalr	1568(ra) # 800044a4 <namei>
    80005e8c:	84aa                	mv	s1,a0
    80005e8e:	c551                	beqz	a0,80005f1a <sys_link+0xde>
    end_op();
    return -1;
  }

  ilock(ip);
    80005e90:	ffffe097          	auipc	ra,0xffffe
    80005e94:	e6e080e7          	jalr	-402(ra) # 80003cfe <ilock>
  if(ip->type == T_DIR){
    80005e98:	04449703          	lh	a4,68(s1)
    80005e9c:	4785                	li	a5,1
    80005e9e:	08f70463          	beq	a4,a5,80005f26 <sys_link+0xea>
    iunlockput(ip);
    end_op();
    return -1;
  }

  ip->nlink++;
    80005ea2:	04a4d783          	lhu	a5,74(s1)
    80005ea6:	2785                	addiw	a5,a5,1
    80005ea8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005eac:	8526                	mv	a0,s1
    80005eae:	ffffe097          	auipc	ra,0xffffe
    80005eb2:	d86080e7          	jalr	-634(ra) # 80003c34 <iupdate>
  iunlock(ip);
    80005eb6:	8526                	mv	a0,s1
    80005eb8:	ffffe097          	auipc	ra,0xffffe
    80005ebc:	f08080e7          	jalr	-248(ra) # 80003dc0 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
    80005ec0:	fd040593          	addi	a1,s0,-48
    80005ec4:	f5040513          	addi	a0,s0,-176
    80005ec8:	ffffe097          	auipc	ra,0xffffe
    80005ecc:	5fa080e7          	jalr	1530(ra) # 800044c2 <nameiparent>
    80005ed0:	892a                	mv	s2,a0
    80005ed2:	c935                	beqz	a0,80005f46 <sys_link+0x10a>
    goto bad;
  ilock(dp);
    80005ed4:	ffffe097          	auipc	ra,0xffffe
    80005ed8:	e2a080e7          	jalr	-470(ra) # 80003cfe <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005edc:	00092703          	lw	a4,0(s2)
    80005ee0:	409c                	lw	a5,0(s1)
    80005ee2:	04f71d63          	bne	a4,a5,80005f3c <sys_link+0x100>
    80005ee6:	40d0                	lw	a2,4(s1)
    80005ee8:	fd040593          	addi	a1,s0,-48
    80005eec:	854a                	mv	a0,s2
    80005eee:	ffffe097          	auipc	ra,0xffffe
    80005ef2:	504080e7          	jalr	1284(ra) # 800043f2 <dirlink>
    80005ef6:	04054363          	bltz	a0,80005f3c <sys_link+0x100>
    iunlockput(dp);
    goto bad;
  }
  iunlockput(dp);
    80005efa:	854a                	mv	a0,s2
    80005efc:	ffffe097          	auipc	ra,0xffffe
    80005f00:	064080e7          	jalr	100(ra) # 80003f60 <iunlockput>
  iput(ip);
    80005f04:	8526                	mv	a0,s1
    80005f06:	ffffe097          	auipc	ra,0xffffe
    80005f0a:	fb2080e7          	jalr	-78(ra) # 80003eb8 <iput>

  end_op();
    80005f0e:	fffff097          	auipc	ra,0xfffff
    80005f12:	b80080e7          	jalr	-1152(ra) # 80004a8e <end_op>

  return 0;
    80005f16:	4781                	li	a5,0
    80005f18:	a085                	j	80005f78 <sys_link+0x13c>
    end_op();
    80005f1a:	fffff097          	auipc	ra,0xfffff
    80005f1e:	b74080e7          	jalr	-1164(ra) # 80004a8e <end_op>
    return -1;
    80005f22:	57fd                	li	a5,-1
    80005f24:	a891                	j	80005f78 <sys_link+0x13c>
    iunlockput(ip);
    80005f26:	8526                	mv	a0,s1
    80005f28:	ffffe097          	auipc	ra,0xffffe
    80005f2c:	038080e7          	jalr	56(ra) # 80003f60 <iunlockput>
    end_op();
    80005f30:	fffff097          	auipc	ra,0xfffff
    80005f34:	b5e080e7          	jalr	-1186(ra) # 80004a8e <end_op>
    return -1;
    80005f38:	57fd                	li	a5,-1
    80005f3a:	a83d                	j	80005f78 <sys_link+0x13c>
    iunlockput(dp);
    80005f3c:	854a                	mv	a0,s2
    80005f3e:	ffffe097          	auipc	ra,0xffffe
    80005f42:	022080e7          	jalr	34(ra) # 80003f60 <iunlockput>

bad:
  ilock(ip);
    80005f46:	8526                	mv	a0,s1
    80005f48:	ffffe097          	auipc	ra,0xffffe
    80005f4c:	db6080e7          	jalr	-586(ra) # 80003cfe <ilock>
  ip->nlink--;
    80005f50:	04a4d783          	lhu	a5,74(s1)
    80005f54:	37fd                	addiw	a5,a5,-1
    80005f56:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005f5a:	8526                	mv	a0,s1
    80005f5c:	ffffe097          	auipc	ra,0xffffe
    80005f60:	cd8080e7          	jalr	-808(ra) # 80003c34 <iupdate>
  iunlockput(ip);
    80005f64:	8526                	mv	a0,s1
    80005f66:	ffffe097          	auipc	ra,0xffffe
    80005f6a:	ffa080e7          	jalr	-6(ra) # 80003f60 <iunlockput>
  end_op();
    80005f6e:	fffff097          	auipc	ra,0xfffff
    80005f72:	b20080e7          	jalr	-1248(ra) # 80004a8e <end_op>
  return -1;
    80005f76:	57fd                	li	a5,-1
}
    80005f78:	853e                	mv	a0,a5
    80005f7a:	70b2                	ld	ra,296(sp)
    80005f7c:	7412                	ld	s0,288(sp)
    80005f7e:	64f2                	ld	s1,280(sp)
    80005f80:	6952                	ld	s2,272(sp)
    80005f82:	6155                	addi	sp,sp,304
    80005f84:	8082                	ret

0000000080005f86 <isdirempty>:
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005f86:	4578                	lw	a4,76(a0)
    80005f88:	02000793          	li	a5,32
    80005f8c:	04e7fa63          	bgeu	a5,a4,80005fe0 <isdirempty+0x5a>
{
    80005f90:	7179                	addi	sp,sp,-48
    80005f92:	f406                	sd	ra,40(sp)
    80005f94:	f022                	sd	s0,32(sp)
    80005f96:	ec26                	sd	s1,24(sp)
    80005f98:	e84a                	sd	s2,16(sp)
    80005f9a:	1800                	addi	s0,sp,48
    80005f9c:	892a                	mv	s2,a0
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005f9e:	02000493          	li	s1,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005fa2:	4741                	li	a4,16
    80005fa4:	86a6                	mv	a3,s1
    80005fa6:	fd040613          	addi	a2,s0,-48
    80005faa:	4581                	li	a1,0
    80005fac:	854a                	mv	a0,s2
    80005fae:	ffffe097          	auipc	ra,0xffffe
    80005fb2:	004080e7          	jalr	4(ra) # 80003fb2 <readi>
    80005fb6:	47c1                	li	a5,16
    80005fb8:	00f51c63          	bne	a0,a5,80005fd0 <isdirempty+0x4a>
      panic("isdirempty: readi");
    if(de.inum != 0)
    80005fbc:	fd045783          	lhu	a5,-48(s0)
    80005fc0:	e395                	bnez	a5,80005fe4 <isdirempty+0x5e>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005fc2:	24c1                	addiw	s1,s1,16
    80005fc4:	04c92783          	lw	a5,76(s2)
    80005fc8:	fcf4ede3          	bltu	s1,a5,80005fa2 <isdirempty+0x1c>
      return 0;
  }
  return 1;
    80005fcc:	4505                	li	a0,1
    80005fce:	a821                	j	80005fe6 <isdirempty+0x60>
      panic("isdirempty: readi");
    80005fd0:	00003517          	auipc	a0,0x3
    80005fd4:	8c850513          	addi	a0,a0,-1848 # 80008898 <syscalls+0x350>
    80005fd8:	ffffa097          	auipc	ra,0xffffa
    80005fdc:	566080e7          	jalr	1382(ra) # 8000053e <panic>
  return 1;
    80005fe0:	4505                	li	a0,1
}
    80005fe2:	8082                	ret
      return 0;
    80005fe4:	4501                	li	a0,0
}
    80005fe6:	70a2                	ld	ra,40(sp)
    80005fe8:	7402                	ld	s0,32(sp)
    80005fea:	64e2                	ld	s1,24(sp)
    80005fec:	6942                	ld	s2,16(sp)
    80005fee:	6145                	addi	sp,sp,48
    80005ff0:	8082                	ret

0000000080005ff2 <sys_unlink>:

uint64
sys_unlink(void)
{
    80005ff2:	7155                	addi	sp,sp,-208
    80005ff4:	e586                	sd	ra,200(sp)
    80005ff6:	e1a2                	sd	s0,192(sp)
    80005ff8:	fd26                	sd	s1,184(sp)
    80005ffa:	f94a                	sd	s2,176(sp)
    80005ffc:	0980                	addi	s0,sp,208
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], path[MAXPATH];
  uint off;

  if(argstr(0, path, MAXPATH) < 0)
    80005ffe:	08000613          	li	a2,128
    80006002:	f4040593          	addi	a1,s0,-192
    80006006:	4501                	li	a0,0
    80006008:	ffffd097          	auipc	ra,0xffffd
    8000600c:	1ca080e7          	jalr	458(ra) # 800031d2 <argstr>
    80006010:	16054363          	bltz	a0,80006176 <sys_unlink+0x184>
    return -1;

  begin_op();
    80006014:	fffff097          	auipc	ra,0xfffff
    80006018:	9fa080e7          	jalr	-1542(ra) # 80004a0e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000601c:	fc040593          	addi	a1,s0,-64
    80006020:	f4040513          	addi	a0,s0,-192
    80006024:	ffffe097          	auipc	ra,0xffffe
    80006028:	49e080e7          	jalr	1182(ra) # 800044c2 <nameiparent>
    8000602c:	84aa                	mv	s1,a0
    8000602e:	c961                	beqz	a0,800060fe <sys_unlink+0x10c>
    end_op();
    return -1;
  }

  ilock(dp);
    80006030:	ffffe097          	auipc	ra,0xffffe
    80006034:	cce080e7          	jalr	-818(ra) # 80003cfe <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80006038:	00002597          	auipc	a1,0x2
    8000603c:	70058593          	addi	a1,a1,1792 # 80008738 <syscalls+0x1f0>
    80006040:	fc040513          	addi	a0,s0,-64
    80006044:	ffffe097          	auipc	ra,0xffffe
    80006048:	184080e7          	jalr	388(ra) # 800041c8 <namecmp>
    8000604c:	c175                	beqz	a0,80006130 <sys_unlink+0x13e>
    8000604e:	00002597          	auipc	a1,0x2
    80006052:	6f258593          	addi	a1,a1,1778 # 80008740 <syscalls+0x1f8>
    80006056:	fc040513          	addi	a0,s0,-64
    8000605a:	ffffe097          	auipc	ra,0xffffe
    8000605e:	16e080e7          	jalr	366(ra) # 800041c8 <namecmp>
    80006062:	c579                	beqz	a0,80006130 <sys_unlink+0x13e>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    80006064:	f3c40613          	addi	a2,s0,-196
    80006068:	fc040593          	addi	a1,s0,-64
    8000606c:	8526                	mv	a0,s1
    8000606e:	ffffe097          	auipc	ra,0xffffe
    80006072:	174080e7          	jalr	372(ra) # 800041e2 <dirlookup>
    80006076:	892a                	mv	s2,a0
    80006078:	cd45                	beqz	a0,80006130 <sys_unlink+0x13e>
    goto bad;
  ilock(ip);
    8000607a:	ffffe097          	auipc	ra,0xffffe
    8000607e:	c84080e7          	jalr	-892(ra) # 80003cfe <ilock>

  if(ip->nlink < 1)
    80006082:	04a91783          	lh	a5,74(s2)
    80006086:	08f05263          	blez	a5,8000610a <sys_unlink+0x118>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000608a:	04491703          	lh	a4,68(s2)
    8000608e:	4785                	li	a5,1
    80006090:	08f70563          	beq	a4,a5,8000611a <sys_unlink+0x128>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    80006094:	4641                	li	a2,16
    80006096:	4581                	li	a1,0
    80006098:	fd040513          	addi	a0,s0,-48
    8000609c:	ffffb097          	auipc	ra,0xffffb
    800060a0:	c36080e7          	jalr	-970(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800060a4:	4741                	li	a4,16
    800060a6:	f3c42683          	lw	a3,-196(s0)
    800060aa:	fd040613          	addi	a2,s0,-48
    800060ae:	4581                	li	a1,0
    800060b0:	8526                	mv	a0,s1
    800060b2:	ffffe097          	auipc	ra,0xffffe
    800060b6:	ff8080e7          	jalr	-8(ra) # 800040aa <writei>
    800060ba:	47c1                	li	a5,16
    800060bc:	08f51a63          	bne	a0,a5,80006150 <sys_unlink+0x15e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    800060c0:	04491703          	lh	a4,68(s2)
    800060c4:	4785                	li	a5,1
    800060c6:	08f70d63          	beq	a4,a5,80006160 <sys_unlink+0x16e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    800060ca:	8526                	mv	a0,s1
    800060cc:	ffffe097          	auipc	ra,0xffffe
    800060d0:	e94080e7          	jalr	-364(ra) # 80003f60 <iunlockput>

  ip->nlink--;
    800060d4:	04a95783          	lhu	a5,74(s2)
    800060d8:	37fd                	addiw	a5,a5,-1
    800060da:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800060de:	854a                	mv	a0,s2
    800060e0:	ffffe097          	auipc	ra,0xffffe
    800060e4:	b54080e7          	jalr	-1196(ra) # 80003c34 <iupdate>
  iunlockput(ip);
    800060e8:	854a                	mv	a0,s2
    800060ea:	ffffe097          	auipc	ra,0xffffe
    800060ee:	e76080e7          	jalr	-394(ra) # 80003f60 <iunlockput>

  end_op();
    800060f2:	fffff097          	auipc	ra,0xfffff
    800060f6:	99c080e7          	jalr	-1636(ra) # 80004a8e <end_op>

  return 0;
    800060fa:	4501                	li	a0,0
    800060fc:	a0a1                	j	80006144 <sys_unlink+0x152>
    end_op();
    800060fe:	fffff097          	auipc	ra,0xfffff
    80006102:	990080e7          	jalr	-1648(ra) # 80004a8e <end_op>
    return -1;
    80006106:	557d                	li	a0,-1
    80006108:	a835                	j	80006144 <sys_unlink+0x152>
    panic("unlink: nlink < 1");
    8000610a:	00002517          	auipc	a0,0x2
    8000610e:	63e50513          	addi	a0,a0,1598 # 80008748 <syscalls+0x200>
    80006112:	ffffa097          	auipc	ra,0xffffa
    80006116:	42c080e7          	jalr	1068(ra) # 8000053e <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000611a:	854a                	mv	a0,s2
    8000611c:	00000097          	auipc	ra,0x0
    80006120:	e6a080e7          	jalr	-406(ra) # 80005f86 <isdirempty>
    80006124:	f925                	bnez	a0,80006094 <sys_unlink+0xa2>
    iunlockput(ip);
    80006126:	854a                	mv	a0,s2
    80006128:	ffffe097          	auipc	ra,0xffffe
    8000612c:	e38080e7          	jalr	-456(ra) # 80003f60 <iunlockput>

bad:
  iunlockput(dp);
    80006130:	8526                	mv	a0,s1
    80006132:	ffffe097          	auipc	ra,0xffffe
    80006136:	e2e080e7          	jalr	-466(ra) # 80003f60 <iunlockput>
  end_op();
    8000613a:	fffff097          	auipc	ra,0xfffff
    8000613e:	954080e7          	jalr	-1708(ra) # 80004a8e <end_op>
  return -1;
    80006142:	557d                	li	a0,-1
}
    80006144:	60ae                	ld	ra,200(sp)
    80006146:	640e                	ld	s0,192(sp)
    80006148:	74ea                	ld	s1,184(sp)
    8000614a:	794a                	ld	s2,176(sp)
    8000614c:	6169                	addi	sp,sp,208
    8000614e:	8082                	ret
    panic("unlink: writei");
    80006150:	00002517          	auipc	a0,0x2
    80006154:	61050513          	addi	a0,a0,1552 # 80008760 <syscalls+0x218>
    80006158:	ffffa097          	auipc	ra,0xffffa
    8000615c:	3e6080e7          	jalr	998(ra) # 8000053e <panic>
    dp->nlink--;
    80006160:	04a4d783          	lhu	a5,74(s1)
    80006164:	37fd                	addiw	a5,a5,-1
    80006166:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000616a:	8526                	mv	a0,s1
    8000616c:	ffffe097          	auipc	ra,0xffffe
    80006170:	ac8080e7          	jalr	-1336(ra) # 80003c34 <iupdate>
    80006174:	bf99                	j	800060ca <sys_unlink+0xd8>
    return -1;
    80006176:	557d                	li	a0,-1
    80006178:	b7f1                	j	80006144 <sys_unlink+0x152>

000000008000617a <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
    8000617a:	715d                	addi	sp,sp,-80
    8000617c:	e486                	sd	ra,72(sp)
    8000617e:	e0a2                	sd	s0,64(sp)
    80006180:	fc26                	sd	s1,56(sp)
    80006182:	f84a                	sd	s2,48(sp)
    80006184:	f44e                	sd	s3,40(sp)
    80006186:	f052                	sd	s4,32(sp)
    80006188:	ec56                	sd	s5,24(sp)
    8000618a:	e85a                	sd	s6,16(sp)
    8000618c:	0880                	addi	s0,sp,80
    8000618e:	8b2e                	mv	s6,a1
    80006190:	89b2                	mv	s3,a2
    80006192:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80006194:	fb040593          	addi	a1,s0,-80
    80006198:	ffffe097          	auipc	ra,0xffffe
    8000619c:	32a080e7          	jalr	810(ra) # 800044c2 <nameiparent>
    800061a0:	84aa                	mv	s1,a0
    800061a2:	14050f63          	beqz	a0,80006300 <create+0x186>
    return 0;

  ilock(dp);
    800061a6:	ffffe097          	auipc	ra,0xffffe
    800061aa:	b58080e7          	jalr	-1192(ra) # 80003cfe <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800061ae:	4601                	li	a2,0
    800061b0:	fb040593          	addi	a1,s0,-80
    800061b4:	8526                	mv	a0,s1
    800061b6:	ffffe097          	auipc	ra,0xffffe
    800061ba:	02c080e7          	jalr	44(ra) # 800041e2 <dirlookup>
    800061be:	8aaa                	mv	s5,a0
    800061c0:	c931                	beqz	a0,80006214 <create+0x9a>
    iunlockput(dp);
    800061c2:	8526                	mv	a0,s1
    800061c4:	ffffe097          	auipc	ra,0xffffe
    800061c8:	d9c080e7          	jalr	-612(ra) # 80003f60 <iunlockput>
    ilock(ip);
    800061cc:	8556                	mv	a0,s5
    800061ce:	ffffe097          	auipc	ra,0xffffe
    800061d2:	b30080e7          	jalr	-1232(ra) # 80003cfe <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800061d6:	000b059b          	sext.w	a1,s6
    800061da:	4789                	li	a5,2
    800061dc:	02f59563          	bne	a1,a5,80006206 <create+0x8c>
    800061e0:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffc8974>
    800061e4:	37f9                	addiw	a5,a5,-2
    800061e6:	17c2                	slli	a5,a5,0x30
    800061e8:	93c1                	srli	a5,a5,0x30
    800061ea:	4705                	li	a4,1
    800061ec:	00f76d63          	bltu	a4,a5,80006206 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800061f0:	8556                	mv	a0,s5
    800061f2:	60a6                	ld	ra,72(sp)
    800061f4:	6406                	ld	s0,64(sp)
    800061f6:	74e2                	ld	s1,56(sp)
    800061f8:	7942                	ld	s2,48(sp)
    800061fa:	79a2                	ld	s3,40(sp)
    800061fc:	7a02                	ld	s4,32(sp)
    800061fe:	6ae2                	ld	s5,24(sp)
    80006200:	6b42                	ld	s6,16(sp)
    80006202:	6161                	addi	sp,sp,80
    80006204:	8082                	ret
    iunlockput(ip);
    80006206:	8556                	mv	a0,s5
    80006208:	ffffe097          	auipc	ra,0xffffe
    8000620c:	d58080e7          	jalr	-680(ra) # 80003f60 <iunlockput>
    return 0;
    80006210:	4a81                	li	s5,0
    80006212:	bff9                	j	800061f0 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80006214:	85da                	mv	a1,s6
    80006216:	4088                	lw	a0,0(s1)
    80006218:	ffffe097          	auipc	ra,0xffffe
    8000621c:	94a080e7          	jalr	-1718(ra) # 80003b62 <ialloc>
    80006220:	8a2a                	mv	s4,a0
    80006222:	c539                	beqz	a0,80006270 <create+0xf6>
  ilock(ip);
    80006224:	ffffe097          	auipc	ra,0xffffe
    80006228:	ada080e7          	jalr	-1318(ra) # 80003cfe <ilock>
  ip->major = major;
    8000622c:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80006230:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80006234:	4905                	li	s2,1
    80006236:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000623a:	8552                	mv	a0,s4
    8000623c:	ffffe097          	auipc	ra,0xffffe
    80006240:	9f8080e7          	jalr	-1544(ra) # 80003c34 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80006244:	000b059b          	sext.w	a1,s6
    80006248:	03258b63          	beq	a1,s2,8000627e <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    8000624c:	004a2603          	lw	a2,4(s4)
    80006250:	fb040593          	addi	a1,s0,-80
    80006254:	8526                	mv	a0,s1
    80006256:	ffffe097          	auipc	ra,0xffffe
    8000625a:	19c080e7          	jalr	412(ra) # 800043f2 <dirlink>
    8000625e:	06054f63          	bltz	a0,800062dc <create+0x162>
  iunlockput(dp);
    80006262:	8526                	mv	a0,s1
    80006264:	ffffe097          	auipc	ra,0xffffe
    80006268:	cfc080e7          	jalr	-772(ra) # 80003f60 <iunlockput>
  return ip;
    8000626c:	8ad2                	mv	s5,s4
    8000626e:	b749                	j	800061f0 <create+0x76>
    iunlockput(dp);
    80006270:	8526                	mv	a0,s1
    80006272:	ffffe097          	auipc	ra,0xffffe
    80006276:	cee080e7          	jalr	-786(ra) # 80003f60 <iunlockput>
    return 0;
    8000627a:	8ad2                	mv	s5,s4
    8000627c:	bf95                	j	800061f0 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000627e:	004a2603          	lw	a2,4(s4)
    80006282:	00002597          	auipc	a1,0x2
    80006286:	4b658593          	addi	a1,a1,1206 # 80008738 <syscalls+0x1f0>
    8000628a:	8552                	mv	a0,s4
    8000628c:	ffffe097          	auipc	ra,0xffffe
    80006290:	166080e7          	jalr	358(ra) # 800043f2 <dirlink>
    80006294:	04054463          	bltz	a0,800062dc <create+0x162>
    80006298:	40d0                	lw	a2,4(s1)
    8000629a:	00002597          	auipc	a1,0x2
    8000629e:	4a658593          	addi	a1,a1,1190 # 80008740 <syscalls+0x1f8>
    800062a2:	8552                	mv	a0,s4
    800062a4:	ffffe097          	auipc	ra,0xffffe
    800062a8:	14e080e7          	jalr	334(ra) # 800043f2 <dirlink>
    800062ac:	02054863          	bltz	a0,800062dc <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800062b0:	004a2603          	lw	a2,4(s4)
    800062b4:	fb040593          	addi	a1,s0,-80
    800062b8:	8526                	mv	a0,s1
    800062ba:	ffffe097          	auipc	ra,0xffffe
    800062be:	138080e7          	jalr	312(ra) # 800043f2 <dirlink>
    800062c2:	00054d63          	bltz	a0,800062dc <create+0x162>
    dp->nlink++;  // for ".."
    800062c6:	04a4d783          	lhu	a5,74(s1)
    800062ca:	2785                	addiw	a5,a5,1
    800062cc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800062d0:	8526                	mv	a0,s1
    800062d2:	ffffe097          	auipc	ra,0xffffe
    800062d6:	962080e7          	jalr	-1694(ra) # 80003c34 <iupdate>
    800062da:	b761                	j	80006262 <create+0xe8>
  ip->nlink = 0;
    800062dc:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800062e0:	8552                	mv	a0,s4
    800062e2:	ffffe097          	auipc	ra,0xffffe
    800062e6:	952080e7          	jalr	-1710(ra) # 80003c34 <iupdate>
  iunlockput(ip);
    800062ea:	8552                	mv	a0,s4
    800062ec:	ffffe097          	auipc	ra,0xffffe
    800062f0:	c74080e7          	jalr	-908(ra) # 80003f60 <iunlockput>
  iunlockput(dp);
    800062f4:	8526                	mv	a0,s1
    800062f6:	ffffe097          	auipc	ra,0xffffe
    800062fa:	c6a080e7          	jalr	-918(ra) # 80003f60 <iunlockput>
  return 0;
    800062fe:	bdcd                	j	800061f0 <create+0x76>
    return 0;
    80006300:	8aaa                	mv	s5,a0
    80006302:	b5fd                	j	800061f0 <create+0x76>

0000000080006304 <sys_open>:

uint64
sys_open(void)
{
    80006304:	7131                	addi	sp,sp,-192
    80006306:	fd06                	sd	ra,184(sp)
    80006308:	f922                	sd	s0,176(sp)
    8000630a:	f526                	sd	s1,168(sp)
    8000630c:	f14a                	sd	s2,160(sp)
    8000630e:	ed4e                	sd	s3,152(sp)
    80006310:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80006312:	f4c40593          	addi	a1,s0,-180
    80006316:	4505                	li	a0,1
    80006318:	ffffd097          	auipc	ra,0xffffd
    8000631c:	e7a080e7          	jalr	-390(ra) # 80003192 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80006320:	08000613          	li	a2,128
    80006324:	f5040593          	addi	a1,s0,-176
    80006328:	4501                	li	a0,0
    8000632a:	ffffd097          	auipc	ra,0xffffd
    8000632e:	ea8080e7          	jalr	-344(ra) # 800031d2 <argstr>
    80006332:	87aa                	mv	a5,a0
    return -1;
    80006334:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80006336:	0a07c963          	bltz	a5,800063e8 <sys_open+0xe4>

  begin_op();
    8000633a:	ffffe097          	auipc	ra,0xffffe
    8000633e:	6d4080e7          	jalr	1748(ra) # 80004a0e <begin_op>

  if(omode & O_CREATE){
    80006342:	f4c42783          	lw	a5,-180(s0)
    80006346:	2007f793          	andi	a5,a5,512
    8000634a:	cfc5                	beqz	a5,80006402 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000634c:	4681                	li	a3,0
    8000634e:	4601                	li	a2,0
    80006350:	4589                	li	a1,2
    80006352:	f5040513          	addi	a0,s0,-176
    80006356:	00000097          	auipc	ra,0x0
    8000635a:	e24080e7          	jalr	-476(ra) # 8000617a <create>
    8000635e:	84aa                	mv	s1,a0
    if(ip == 0){
    80006360:	c959                	beqz	a0,800063f6 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006362:	04449703          	lh	a4,68(s1)
    80006366:	478d                	li	a5,3
    80006368:	00f71763          	bne	a4,a5,80006376 <sys_open+0x72>
    8000636c:	0464d703          	lhu	a4,70(s1)
    80006370:	47a5                	li	a5,9
    80006372:	0ce7ed63          	bltu	a5,a4,8000644c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006376:	fffff097          	auipc	ra,0xfffff
    8000637a:	aa8080e7          	jalr	-1368(ra) # 80004e1e <filealloc>
    8000637e:	89aa                	mv	s3,a0
    80006380:	10050363          	beqz	a0,80006486 <sys_open+0x182>
    80006384:	00000097          	auipc	ra,0x0
    80006388:	8e4080e7          	jalr	-1820(ra) # 80005c68 <fdalloc>
    8000638c:	892a                	mv	s2,a0
    8000638e:	0e054763          	bltz	a0,8000647c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006392:	04449703          	lh	a4,68(s1)
    80006396:	478d                	li	a5,3
    80006398:	0cf70563          	beq	a4,a5,80006462 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000639c:	4789                	li	a5,2
    8000639e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800063a2:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800063a6:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800063aa:	f4c42783          	lw	a5,-180(s0)
    800063ae:	0017c713          	xori	a4,a5,1
    800063b2:	8b05                	andi	a4,a4,1
    800063b4:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800063b8:	0037f713          	andi	a4,a5,3
    800063bc:	00e03733          	snez	a4,a4
    800063c0:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800063c4:	4007f793          	andi	a5,a5,1024
    800063c8:	c791                	beqz	a5,800063d4 <sys_open+0xd0>
    800063ca:	04449703          	lh	a4,68(s1)
    800063ce:	4789                	li	a5,2
    800063d0:	0af70063          	beq	a4,a5,80006470 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800063d4:	8526                	mv	a0,s1
    800063d6:	ffffe097          	auipc	ra,0xffffe
    800063da:	9ea080e7          	jalr	-1558(ra) # 80003dc0 <iunlock>
  end_op();
    800063de:	ffffe097          	auipc	ra,0xffffe
    800063e2:	6b0080e7          	jalr	1712(ra) # 80004a8e <end_op>

  return fd;
    800063e6:	854a                	mv	a0,s2
}
    800063e8:	70ea                	ld	ra,184(sp)
    800063ea:	744a                	ld	s0,176(sp)
    800063ec:	74aa                	ld	s1,168(sp)
    800063ee:	790a                	ld	s2,160(sp)
    800063f0:	69ea                	ld	s3,152(sp)
    800063f2:	6129                	addi	sp,sp,192
    800063f4:	8082                	ret
      end_op();
    800063f6:	ffffe097          	auipc	ra,0xffffe
    800063fa:	698080e7          	jalr	1688(ra) # 80004a8e <end_op>
      return -1;
    800063fe:	557d                	li	a0,-1
    80006400:	b7e5                	j	800063e8 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006402:	f5040513          	addi	a0,s0,-176
    80006406:	ffffe097          	auipc	ra,0xffffe
    8000640a:	09e080e7          	jalr	158(ra) # 800044a4 <namei>
    8000640e:	84aa                	mv	s1,a0
    80006410:	c905                	beqz	a0,80006440 <sys_open+0x13c>
    ilock(ip);
    80006412:	ffffe097          	auipc	ra,0xffffe
    80006416:	8ec080e7          	jalr	-1812(ra) # 80003cfe <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000641a:	04449703          	lh	a4,68(s1)
    8000641e:	4785                	li	a5,1
    80006420:	f4f711e3          	bne	a4,a5,80006362 <sys_open+0x5e>
    80006424:	f4c42783          	lw	a5,-180(s0)
    80006428:	d7b9                	beqz	a5,80006376 <sys_open+0x72>
      iunlockput(ip);
    8000642a:	8526                	mv	a0,s1
    8000642c:	ffffe097          	auipc	ra,0xffffe
    80006430:	b34080e7          	jalr	-1228(ra) # 80003f60 <iunlockput>
      end_op();
    80006434:	ffffe097          	auipc	ra,0xffffe
    80006438:	65a080e7          	jalr	1626(ra) # 80004a8e <end_op>
      return -1;
    8000643c:	557d                	li	a0,-1
    8000643e:	b76d                	j	800063e8 <sys_open+0xe4>
      end_op();
    80006440:	ffffe097          	auipc	ra,0xffffe
    80006444:	64e080e7          	jalr	1614(ra) # 80004a8e <end_op>
      return -1;
    80006448:	557d                	li	a0,-1
    8000644a:	bf79                	j	800063e8 <sys_open+0xe4>
    iunlockput(ip);
    8000644c:	8526                	mv	a0,s1
    8000644e:	ffffe097          	auipc	ra,0xffffe
    80006452:	b12080e7          	jalr	-1262(ra) # 80003f60 <iunlockput>
    end_op();
    80006456:	ffffe097          	auipc	ra,0xffffe
    8000645a:	638080e7          	jalr	1592(ra) # 80004a8e <end_op>
    return -1;
    8000645e:	557d                	li	a0,-1
    80006460:	b761                	j	800063e8 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006462:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006466:	04649783          	lh	a5,70(s1)
    8000646a:	02f99223          	sh	a5,36(s3)
    8000646e:	bf25                	j	800063a6 <sys_open+0xa2>
    itrunc(ip);
    80006470:	8526                	mv	a0,s1
    80006472:	ffffe097          	auipc	ra,0xffffe
    80006476:	99a080e7          	jalr	-1638(ra) # 80003e0c <itrunc>
    8000647a:	bfa9                	j	800063d4 <sys_open+0xd0>
      fileclose(f);
    8000647c:	854e                	mv	a0,s3
    8000647e:	fffff097          	auipc	ra,0xfffff
    80006482:	a5c080e7          	jalr	-1444(ra) # 80004eda <fileclose>
    iunlockput(ip);
    80006486:	8526                	mv	a0,s1
    80006488:	ffffe097          	auipc	ra,0xffffe
    8000648c:	ad8080e7          	jalr	-1320(ra) # 80003f60 <iunlockput>
    end_op();
    80006490:	ffffe097          	auipc	ra,0xffffe
    80006494:	5fe080e7          	jalr	1534(ra) # 80004a8e <end_op>
    return -1;
    80006498:	557d                	li	a0,-1
    8000649a:	b7b9                	j	800063e8 <sys_open+0xe4>

000000008000649c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000649c:	7175                	addi	sp,sp,-144
    8000649e:	e506                	sd	ra,136(sp)
    800064a0:	e122                	sd	s0,128(sp)
    800064a2:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800064a4:	ffffe097          	auipc	ra,0xffffe
    800064a8:	56a080e7          	jalr	1386(ra) # 80004a0e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800064ac:	08000613          	li	a2,128
    800064b0:	f7040593          	addi	a1,s0,-144
    800064b4:	4501                	li	a0,0
    800064b6:	ffffd097          	auipc	ra,0xffffd
    800064ba:	d1c080e7          	jalr	-740(ra) # 800031d2 <argstr>
    800064be:	02054963          	bltz	a0,800064f0 <sys_mkdir+0x54>
    800064c2:	4681                	li	a3,0
    800064c4:	4601                	li	a2,0
    800064c6:	4585                	li	a1,1
    800064c8:	f7040513          	addi	a0,s0,-144
    800064cc:	00000097          	auipc	ra,0x0
    800064d0:	cae080e7          	jalr	-850(ra) # 8000617a <create>
    800064d4:	cd11                	beqz	a0,800064f0 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800064d6:	ffffe097          	auipc	ra,0xffffe
    800064da:	a8a080e7          	jalr	-1398(ra) # 80003f60 <iunlockput>
  end_op();
    800064de:	ffffe097          	auipc	ra,0xffffe
    800064e2:	5b0080e7          	jalr	1456(ra) # 80004a8e <end_op>
  return 0;
    800064e6:	4501                	li	a0,0
}
    800064e8:	60aa                	ld	ra,136(sp)
    800064ea:	640a                	ld	s0,128(sp)
    800064ec:	6149                	addi	sp,sp,144
    800064ee:	8082                	ret
    end_op();
    800064f0:	ffffe097          	auipc	ra,0xffffe
    800064f4:	59e080e7          	jalr	1438(ra) # 80004a8e <end_op>
    return -1;
    800064f8:	557d                	li	a0,-1
    800064fa:	b7fd                	j	800064e8 <sys_mkdir+0x4c>

00000000800064fc <sys_mknod>:

uint64
sys_mknod(void)
{
    800064fc:	7135                	addi	sp,sp,-160
    800064fe:	ed06                	sd	ra,152(sp)
    80006500:	e922                	sd	s0,144(sp)
    80006502:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006504:	ffffe097          	auipc	ra,0xffffe
    80006508:	50a080e7          	jalr	1290(ra) # 80004a0e <begin_op>
  argint(1, &major);
    8000650c:	f6c40593          	addi	a1,s0,-148
    80006510:	4505                	li	a0,1
    80006512:	ffffd097          	auipc	ra,0xffffd
    80006516:	c80080e7          	jalr	-896(ra) # 80003192 <argint>
  argint(2, &minor);
    8000651a:	f6840593          	addi	a1,s0,-152
    8000651e:	4509                	li	a0,2
    80006520:	ffffd097          	auipc	ra,0xffffd
    80006524:	c72080e7          	jalr	-910(ra) # 80003192 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006528:	08000613          	li	a2,128
    8000652c:	f7040593          	addi	a1,s0,-144
    80006530:	4501                	li	a0,0
    80006532:	ffffd097          	auipc	ra,0xffffd
    80006536:	ca0080e7          	jalr	-864(ra) # 800031d2 <argstr>
    8000653a:	02054b63          	bltz	a0,80006570 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000653e:	f6841683          	lh	a3,-152(s0)
    80006542:	f6c41603          	lh	a2,-148(s0)
    80006546:	458d                	li	a1,3
    80006548:	f7040513          	addi	a0,s0,-144
    8000654c:	00000097          	auipc	ra,0x0
    80006550:	c2e080e7          	jalr	-978(ra) # 8000617a <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006554:	cd11                	beqz	a0,80006570 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006556:	ffffe097          	auipc	ra,0xffffe
    8000655a:	a0a080e7          	jalr	-1526(ra) # 80003f60 <iunlockput>
  end_op();
    8000655e:	ffffe097          	auipc	ra,0xffffe
    80006562:	530080e7          	jalr	1328(ra) # 80004a8e <end_op>
  return 0;
    80006566:	4501                	li	a0,0
}
    80006568:	60ea                	ld	ra,152(sp)
    8000656a:	644a                	ld	s0,144(sp)
    8000656c:	610d                	addi	sp,sp,160
    8000656e:	8082                	ret
    end_op();
    80006570:	ffffe097          	auipc	ra,0xffffe
    80006574:	51e080e7          	jalr	1310(ra) # 80004a8e <end_op>
    return -1;
    80006578:	557d                	li	a0,-1
    8000657a:	b7fd                	j	80006568 <sys_mknod+0x6c>

000000008000657c <sys_chdir>:

uint64
sys_chdir(void)
{
    8000657c:	7135                	addi	sp,sp,-160
    8000657e:	ed06                	sd	ra,152(sp)
    80006580:	e922                	sd	s0,144(sp)
    80006582:	e526                	sd	s1,136(sp)
    80006584:	e14a                	sd	s2,128(sp)
    80006586:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006588:	ffffb097          	auipc	ra,0xffffb
    8000658c:	57a080e7          	jalr	1402(ra) # 80001b02 <myproc>
    80006590:	892a                	mv	s2,a0
  
  begin_op();
    80006592:	ffffe097          	auipc	ra,0xffffe
    80006596:	47c080e7          	jalr	1148(ra) # 80004a0e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000659a:	08000613          	li	a2,128
    8000659e:	f6040593          	addi	a1,s0,-160
    800065a2:	4501                	li	a0,0
    800065a4:	ffffd097          	auipc	ra,0xffffd
    800065a8:	c2e080e7          	jalr	-978(ra) # 800031d2 <argstr>
    800065ac:	04054b63          	bltz	a0,80006602 <sys_chdir+0x86>
    800065b0:	f6040513          	addi	a0,s0,-160
    800065b4:	ffffe097          	auipc	ra,0xffffe
    800065b8:	ef0080e7          	jalr	-272(ra) # 800044a4 <namei>
    800065bc:	84aa                	mv	s1,a0
    800065be:	c131                	beqz	a0,80006602 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800065c0:	ffffd097          	auipc	ra,0xffffd
    800065c4:	73e080e7          	jalr	1854(ra) # 80003cfe <ilock>
  if(ip->type != T_DIR){
    800065c8:	04449703          	lh	a4,68(s1)
    800065cc:	4785                	li	a5,1
    800065ce:	04f71063          	bne	a4,a5,8000660e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800065d2:	8526                	mv	a0,s1
    800065d4:	ffffd097          	auipc	ra,0xffffd
    800065d8:	7ec080e7          	jalr	2028(ra) # 80003dc0 <iunlock>
  iput(p->cwd);
    800065dc:	15093503          	ld	a0,336(s2)
    800065e0:	ffffe097          	auipc	ra,0xffffe
    800065e4:	8d8080e7          	jalr	-1832(ra) # 80003eb8 <iput>
  end_op();
    800065e8:	ffffe097          	auipc	ra,0xffffe
    800065ec:	4a6080e7          	jalr	1190(ra) # 80004a8e <end_op>
  p->cwd = ip;
    800065f0:	14993823          	sd	s1,336(s2)
  return 0;
    800065f4:	4501                	li	a0,0
}
    800065f6:	60ea                	ld	ra,152(sp)
    800065f8:	644a                	ld	s0,144(sp)
    800065fa:	64aa                	ld	s1,136(sp)
    800065fc:	690a                	ld	s2,128(sp)
    800065fe:	610d                	addi	sp,sp,160
    80006600:	8082                	ret
    end_op();
    80006602:	ffffe097          	auipc	ra,0xffffe
    80006606:	48c080e7          	jalr	1164(ra) # 80004a8e <end_op>
    return -1;
    8000660a:	557d                	li	a0,-1
    8000660c:	b7ed                	j	800065f6 <sys_chdir+0x7a>
    iunlockput(ip);
    8000660e:	8526                	mv	a0,s1
    80006610:	ffffe097          	auipc	ra,0xffffe
    80006614:	950080e7          	jalr	-1712(ra) # 80003f60 <iunlockput>
    end_op();
    80006618:	ffffe097          	auipc	ra,0xffffe
    8000661c:	476080e7          	jalr	1142(ra) # 80004a8e <end_op>
    return -1;
    80006620:	557d                	li	a0,-1
    80006622:	bfd1                	j	800065f6 <sys_chdir+0x7a>

0000000080006624 <sys_exec>:

uint64
sys_exec(void)
{
    80006624:	7145                	addi	sp,sp,-464
    80006626:	e786                	sd	ra,456(sp)
    80006628:	e3a2                	sd	s0,448(sp)
    8000662a:	ff26                	sd	s1,440(sp)
    8000662c:	fb4a                	sd	s2,432(sp)
    8000662e:	f74e                	sd	s3,424(sp)
    80006630:	f352                	sd	s4,416(sp)
    80006632:	ef56                	sd	s5,408(sp)
    80006634:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006636:	e3840593          	addi	a1,s0,-456
    8000663a:	4505                	li	a0,1
    8000663c:	ffffd097          	auipc	ra,0xffffd
    80006640:	b76080e7          	jalr	-1162(ra) # 800031b2 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006644:	08000613          	li	a2,128
    80006648:	f4040593          	addi	a1,s0,-192
    8000664c:	4501                	li	a0,0
    8000664e:	ffffd097          	auipc	ra,0xffffd
    80006652:	b84080e7          	jalr	-1148(ra) # 800031d2 <argstr>
    80006656:	87aa                	mv	a5,a0
    return -1;
    80006658:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    8000665a:	0c07c263          	bltz	a5,8000671e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    8000665e:	10000613          	li	a2,256
    80006662:	4581                	li	a1,0
    80006664:	e4040513          	addi	a0,s0,-448
    80006668:	ffffa097          	auipc	ra,0xffffa
    8000666c:	66a080e7          	jalr	1642(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006670:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006674:	89a6                	mv	s3,s1
    80006676:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006678:	02000a13          	li	s4,32
    8000667c:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006680:	00391793          	slli	a5,s2,0x3
    80006684:	e3040593          	addi	a1,s0,-464
    80006688:	e3843503          	ld	a0,-456(s0)
    8000668c:	953e                	add	a0,a0,a5
    8000668e:	ffffd097          	auipc	ra,0xffffd
    80006692:	a66080e7          	jalr	-1434(ra) # 800030f4 <fetchaddr>
    80006696:	02054a63          	bltz	a0,800066ca <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    8000669a:	e3043783          	ld	a5,-464(s0)
    8000669e:	c3b9                	beqz	a5,800066e4 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800066a0:	ffffa097          	auipc	ra,0xffffa
    800066a4:	446080e7          	jalr	1094(ra) # 80000ae6 <kalloc>
    800066a8:	85aa                	mv	a1,a0
    800066aa:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800066ae:	cd11                	beqz	a0,800066ca <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800066b0:	6605                	lui	a2,0x1
    800066b2:	e3043503          	ld	a0,-464(s0)
    800066b6:	ffffd097          	auipc	ra,0xffffd
    800066ba:	a90080e7          	jalr	-1392(ra) # 80003146 <fetchstr>
    800066be:	00054663          	bltz	a0,800066ca <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    800066c2:	0905                	addi	s2,s2,1
    800066c4:	09a1                	addi	s3,s3,8
    800066c6:	fb491be3          	bne	s2,s4,8000667c <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800066ca:	10048913          	addi	s2,s1,256
    800066ce:	6088                	ld	a0,0(s1)
    800066d0:	c531                	beqz	a0,8000671c <sys_exec+0xf8>
    kfree(argv[i]);
    800066d2:	ffffa097          	auipc	ra,0xffffa
    800066d6:	318080e7          	jalr	792(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800066da:	04a1                	addi	s1,s1,8
    800066dc:	ff2499e3          	bne	s1,s2,800066ce <sys_exec+0xaa>
  return -1;
    800066e0:	557d                	li	a0,-1
    800066e2:	a835                	j	8000671e <sys_exec+0xfa>
      argv[i] = 0;
    800066e4:	0a8e                	slli	s5,s5,0x3
    800066e6:	fc040793          	addi	a5,s0,-64
    800066ea:	9abe                	add	s5,s5,a5
    800066ec:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800066f0:	e4040593          	addi	a1,s0,-448
    800066f4:	f4040513          	addi	a0,s0,-192
    800066f8:	fffff097          	auipc	ra,0xfffff
    800066fc:	0ee080e7          	jalr	238(ra) # 800057e6 <exec>
    80006700:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006702:	10048993          	addi	s3,s1,256
    80006706:	6088                	ld	a0,0(s1)
    80006708:	c901                	beqz	a0,80006718 <sys_exec+0xf4>
    kfree(argv[i]);
    8000670a:	ffffa097          	auipc	ra,0xffffa
    8000670e:	2e0080e7          	jalr	736(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006712:	04a1                	addi	s1,s1,8
    80006714:	ff3499e3          	bne	s1,s3,80006706 <sys_exec+0xe2>
  return ret;
    80006718:	854a                	mv	a0,s2
    8000671a:	a011                	j	8000671e <sys_exec+0xfa>
  return -1;
    8000671c:	557d                	li	a0,-1
}
    8000671e:	60be                	ld	ra,456(sp)
    80006720:	641e                	ld	s0,448(sp)
    80006722:	74fa                	ld	s1,440(sp)
    80006724:	795a                	ld	s2,432(sp)
    80006726:	79ba                	ld	s3,424(sp)
    80006728:	7a1a                	ld	s4,416(sp)
    8000672a:	6afa                	ld	s5,408(sp)
    8000672c:	6179                	addi	sp,sp,464
    8000672e:	8082                	ret

0000000080006730 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006730:	7139                	addi	sp,sp,-64
    80006732:	fc06                	sd	ra,56(sp)
    80006734:	f822                	sd	s0,48(sp)
    80006736:	f426                	sd	s1,40(sp)
    80006738:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000673a:	ffffb097          	auipc	ra,0xffffb
    8000673e:	3c8080e7          	jalr	968(ra) # 80001b02 <myproc>
    80006742:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006744:	fd840593          	addi	a1,s0,-40
    80006748:	4501                	li	a0,0
    8000674a:	ffffd097          	auipc	ra,0xffffd
    8000674e:	a68080e7          	jalr	-1432(ra) # 800031b2 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006752:	fc840593          	addi	a1,s0,-56
    80006756:	fd040513          	addi	a0,s0,-48
    8000675a:	fffff097          	auipc	ra,0xfffff
    8000675e:	d42080e7          	jalr	-702(ra) # 8000549c <pipealloc>
    return -1;
    80006762:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006764:	0c054463          	bltz	a0,8000682c <sys_pipe+0xfc>
  fd0 = -1;
    80006768:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000676c:	fd043503          	ld	a0,-48(s0)
    80006770:	fffff097          	auipc	ra,0xfffff
    80006774:	4f8080e7          	jalr	1272(ra) # 80005c68 <fdalloc>
    80006778:	fca42223          	sw	a0,-60(s0)
    8000677c:	08054b63          	bltz	a0,80006812 <sys_pipe+0xe2>
    80006780:	fc843503          	ld	a0,-56(s0)
    80006784:	fffff097          	auipc	ra,0xfffff
    80006788:	4e4080e7          	jalr	1252(ra) # 80005c68 <fdalloc>
    8000678c:	fca42023          	sw	a0,-64(s0)
    80006790:	06054863          	bltz	a0,80006800 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006794:	4691                	li	a3,4
    80006796:	fc440613          	addi	a2,s0,-60
    8000679a:	fd843583          	ld	a1,-40(s0)
    8000679e:	68a8                	ld	a0,80(s1)
    800067a0:	ffffb097          	auipc	ra,0xffffb
    800067a4:	01e080e7          	jalr	30(ra) # 800017be <copyout>
    800067a8:	02054063          	bltz	a0,800067c8 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800067ac:	4691                	li	a3,4
    800067ae:	fc040613          	addi	a2,s0,-64
    800067b2:	fd843583          	ld	a1,-40(s0)
    800067b6:	0591                	addi	a1,a1,4
    800067b8:	68a8                	ld	a0,80(s1)
    800067ba:	ffffb097          	auipc	ra,0xffffb
    800067be:	004080e7          	jalr	4(ra) # 800017be <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800067c2:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800067c4:	06055463          	bgez	a0,8000682c <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800067c8:	fc442783          	lw	a5,-60(s0)
    800067cc:	07e9                	addi	a5,a5,26
    800067ce:	078e                	slli	a5,a5,0x3
    800067d0:	97a6                	add	a5,a5,s1
    800067d2:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800067d6:	fc042503          	lw	a0,-64(s0)
    800067da:	0569                	addi	a0,a0,26
    800067dc:	050e                	slli	a0,a0,0x3
    800067de:	94aa                	add	s1,s1,a0
    800067e0:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800067e4:	fd043503          	ld	a0,-48(s0)
    800067e8:	ffffe097          	auipc	ra,0xffffe
    800067ec:	6f2080e7          	jalr	1778(ra) # 80004eda <fileclose>
    fileclose(wf);
    800067f0:	fc843503          	ld	a0,-56(s0)
    800067f4:	ffffe097          	auipc	ra,0xffffe
    800067f8:	6e6080e7          	jalr	1766(ra) # 80004eda <fileclose>
    return -1;
    800067fc:	57fd                	li	a5,-1
    800067fe:	a03d                	j	8000682c <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006800:	fc442783          	lw	a5,-60(s0)
    80006804:	0007c763          	bltz	a5,80006812 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006808:	07e9                	addi	a5,a5,26
    8000680a:	078e                	slli	a5,a5,0x3
    8000680c:	94be                	add	s1,s1,a5
    8000680e:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006812:	fd043503          	ld	a0,-48(s0)
    80006816:	ffffe097          	auipc	ra,0xffffe
    8000681a:	6c4080e7          	jalr	1732(ra) # 80004eda <fileclose>
    fileclose(wf);
    8000681e:	fc843503          	ld	a0,-56(s0)
    80006822:	ffffe097          	auipc	ra,0xffffe
    80006826:	6b8080e7          	jalr	1720(ra) # 80004eda <fileclose>
    return -1;
    8000682a:	57fd                	li	a5,-1
}
    8000682c:	853e                	mv	a0,a5
    8000682e:	70e2                	ld	ra,56(sp)
    80006830:	7442                	ld	s0,48(sp)
    80006832:	74a2                	ld	s1,40(sp)
    80006834:	6121                	addi	sp,sp,64
    80006836:	8082                	ret
	...

0000000080006840 <kernelvec>:
    80006840:	7111                	addi	sp,sp,-256
    80006842:	e006                	sd	ra,0(sp)
    80006844:	e40a                	sd	sp,8(sp)
    80006846:	e80e                	sd	gp,16(sp)
    80006848:	ec12                	sd	tp,24(sp)
    8000684a:	f016                	sd	t0,32(sp)
    8000684c:	f41a                	sd	t1,40(sp)
    8000684e:	f81e                	sd	t2,48(sp)
    80006850:	fc22                	sd	s0,56(sp)
    80006852:	e0a6                	sd	s1,64(sp)
    80006854:	e4aa                	sd	a0,72(sp)
    80006856:	e8ae                	sd	a1,80(sp)
    80006858:	ecb2                	sd	a2,88(sp)
    8000685a:	f0b6                	sd	a3,96(sp)
    8000685c:	f4ba                	sd	a4,104(sp)
    8000685e:	f8be                	sd	a5,112(sp)
    80006860:	fcc2                	sd	a6,120(sp)
    80006862:	e146                	sd	a7,128(sp)
    80006864:	e54a                	sd	s2,136(sp)
    80006866:	e94e                	sd	s3,144(sp)
    80006868:	ed52                	sd	s4,152(sp)
    8000686a:	f156                	sd	s5,160(sp)
    8000686c:	f55a                	sd	s6,168(sp)
    8000686e:	f95e                	sd	s7,176(sp)
    80006870:	fd62                	sd	s8,184(sp)
    80006872:	e1e6                	sd	s9,192(sp)
    80006874:	e5ea                	sd	s10,200(sp)
    80006876:	e9ee                	sd	s11,208(sp)
    80006878:	edf2                	sd	t3,216(sp)
    8000687a:	f1f6                	sd	t4,224(sp)
    8000687c:	f5fa                	sd	t5,232(sp)
    8000687e:	f9fe                	sd	t6,240(sp)
    80006880:	f40fc0ef          	jal	ra,80002fc0 <kerneltrap>
    80006884:	6082                	ld	ra,0(sp)
    80006886:	6122                	ld	sp,8(sp)
    80006888:	61c2                	ld	gp,16(sp)
    8000688a:	7282                	ld	t0,32(sp)
    8000688c:	7322                	ld	t1,40(sp)
    8000688e:	73c2                	ld	t2,48(sp)
    80006890:	7462                	ld	s0,56(sp)
    80006892:	6486                	ld	s1,64(sp)
    80006894:	6526                	ld	a0,72(sp)
    80006896:	65c6                	ld	a1,80(sp)
    80006898:	6666                	ld	a2,88(sp)
    8000689a:	7686                	ld	a3,96(sp)
    8000689c:	7726                	ld	a4,104(sp)
    8000689e:	77c6                	ld	a5,112(sp)
    800068a0:	7866                	ld	a6,120(sp)
    800068a2:	688a                	ld	a7,128(sp)
    800068a4:	692a                	ld	s2,136(sp)
    800068a6:	69ca                	ld	s3,144(sp)
    800068a8:	6a6a                	ld	s4,152(sp)
    800068aa:	7a8a                	ld	s5,160(sp)
    800068ac:	7b2a                	ld	s6,168(sp)
    800068ae:	7bca                	ld	s7,176(sp)
    800068b0:	7c6a                	ld	s8,184(sp)
    800068b2:	6c8e                	ld	s9,192(sp)
    800068b4:	6d2e                	ld	s10,200(sp)
    800068b6:	6dce                	ld	s11,208(sp)
    800068b8:	6e6e                	ld	t3,216(sp)
    800068ba:	7e8e                	ld	t4,224(sp)
    800068bc:	7f2e                	ld	t5,232(sp)
    800068be:	7fce                	ld	t6,240(sp)
    800068c0:	6111                	addi	sp,sp,256
    800068c2:	10200073          	sret
    800068c6:	00000013          	nop
    800068ca:	00000013          	nop
    800068ce:	0001                	nop

00000000800068d0 <timervec>:
    800068d0:	34051573          	csrrw	a0,mscratch,a0
    800068d4:	e10c                	sd	a1,0(a0)
    800068d6:	e510                	sd	a2,8(a0)
    800068d8:	e914                	sd	a3,16(a0)
    800068da:	6d0c                	ld	a1,24(a0)
    800068dc:	7110                	ld	a2,32(a0)
    800068de:	6194                	ld	a3,0(a1)
    800068e0:	96b2                	add	a3,a3,a2
    800068e2:	e194                	sd	a3,0(a1)
    800068e4:	4589                	li	a1,2
    800068e6:	14459073          	csrw	sip,a1
    800068ea:	6914                	ld	a3,16(a0)
    800068ec:	6510                	ld	a2,8(a0)
    800068ee:	610c                	ld	a1,0(a0)
    800068f0:	34051573          	csrrw	a0,mscratch,a0
    800068f4:	30200073          	mret
	...

00000000800068fa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800068fa:	1141                	addi	sp,sp,-16
    800068fc:	e422                	sd	s0,8(sp)
    800068fe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006900:	0c0007b7          	lui	a5,0xc000
    80006904:	4705                	li	a4,1
    80006906:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006908:	c3d8                	sw	a4,4(a5)
}
    8000690a:	6422                	ld	s0,8(sp)
    8000690c:	0141                	addi	sp,sp,16
    8000690e:	8082                	ret

0000000080006910 <plicinithart>:

void
plicinithart(void)
{
    80006910:	1141                	addi	sp,sp,-16
    80006912:	e406                	sd	ra,8(sp)
    80006914:	e022                	sd	s0,0(sp)
    80006916:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006918:	ffffb097          	auipc	ra,0xffffb
    8000691c:	1be080e7          	jalr	446(ra) # 80001ad6 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006920:	0085171b          	slliw	a4,a0,0x8
    80006924:	0c0027b7          	lui	a5,0xc002
    80006928:	97ba                	add	a5,a5,a4
    8000692a:	40200713          	li	a4,1026
    8000692e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006932:	00d5151b          	slliw	a0,a0,0xd
    80006936:	0c2017b7          	lui	a5,0xc201
    8000693a:	953e                	add	a0,a0,a5
    8000693c:	00052023          	sw	zero,0(a0)
}
    80006940:	60a2                	ld	ra,8(sp)
    80006942:	6402                	ld	s0,0(sp)
    80006944:	0141                	addi	sp,sp,16
    80006946:	8082                	ret

0000000080006948 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006948:	1141                	addi	sp,sp,-16
    8000694a:	e406                	sd	ra,8(sp)
    8000694c:	e022                	sd	s0,0(sp)
    8000694e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006950:	ffffb097          	auipc	ra,0xffffb
    80006954:	186080e7          	jalr	390(ra) # 80001ad6 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006958:	00d5179b          	slliw	a5,a0,0xd
    8000695c:	0c201537          	lui	a0,0xc201
    80006960:	953e                	add	a0,a0,a5
  return irq;
}
    80006962:	4148                	lw	a0,4(a0)
    80006964:	60a2                	ld	ra,8(sp)
    80006966:	6402                	ld	s0,0(sp)
    80006968:	0141                	addi	sp,sp,16
    8000696a:	8082                	ret

000000008000696c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000696c:	1101                	addi	sp,sp,-32
    8000696e:	ec06                	sd	ra,24(sp)
    80006970:	e822                	sd	s0,16(sp)
    80006972:	e426                	sd	s1,8(sp)
    80006974:	1000                	addi	s0,sp,32
    80006976:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006978:	ffffb097          	auipc	ra,0xffffb
    8000697c:	15e080e7          	jalr	350(ra) # 80001ad6 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006980:	00d5151b          	slliw	a0,a0,0xd
    80006984:	0c2017b7          	lui	a5,0xc201
    80006988:	97aa                	add	a5,a5,a0
    8000698a:	c3c4                	sw	s1,4(a5)
}
    8000698c:	60e2                	ld	ra,24(sp)
    8000698e:	6442                	ld	s0,16(sp)
    80006990:	64a2                	ld	s1,8(sp)
    80006992:	6105                	addi	sp,sp,32
    80006994:	8082                	ret

0000000080006996 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006996:	1141                	addi	sp,sp,-16
    80006998:	e406                	sd	ra,8(sp)
    8000699a:	e022                	sd	s0,0(sp)
    8000699c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000699e:	479d                	li	a5,7
    800069a0:	04a7cc63          	blt	a5,a0,800069f8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800069a4:	00030797          	auipc	a5,0x30
    800069a8:	bec78793          	addi	a5,a5,-1044 # 80036590 <disk>
    800069ac:	97aa                	add	a5,a5,a0
    800069ae:	0187c783          	lbu	a5,24(a5)
    800069b2:	ebb9                	bnez	a5,80006a08 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800069b4:	00451613          	slli	a2,a0,0x4
    800069b8:	00030797          	auipc	a5,0x30
    800069bc:	bd878793          	addi	a5,a5,-1064 # 80036590 <disk>
    800069c0:	6394                	ld	a3,0(a5)
    800069c2:	96b2                	add	a3,a3,a2
    800069c4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800069c8:	6398                	ld	a4,0(a5)
    800069ca:	9732                	add	a4,a4,a2
    800069cc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800069d0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800069d4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800069d8:	953e                	add	a0,a0,a5
    800069da:	4785                	li	a5,1
    800069dc:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    800069e0:	00030517          	auipc	a0,0x30
    800069e4:	bc850513          	addi	a0,a0,-1080 # 800365a8 <disk+0x18>
    800069e8:	ffffc097          	auipc	ra,0xffffc
    800069ec:	8d8080e7          	jalr	-1832(ra) # 800022c0 <wakeup>
}
    800069f0:	60a2                	ld	ra,8(sp)
    800069f2:	6402                	ld	s0,0(sp)
    800069f4:	0141                	addi	sp,sp,16
    800069f6:	8082                	ret
    panic("free_desc 1");
    800069f8:	00002517          	auipc	a0,0x2
    800069fc:	eb850513          	addi	a0,a0,-328 # 800088b0 <syscalls+0x368>
    80006a00:	ffffa097          	auipc	ra,0xffffa
    80006a04:	b3e080e7          	jalr	-1218(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006a08:	00002517          	auipc	a0,0x2
    80006a0c:	eb850513          	addi	a0,a0,-328 # 800088c0 <syscalls+0x378>
    80006a10:	ffffa097          	auipc	ra,0xffffa
    80006a14:	b2e080e7          	jalr	-1234(ra) # 8000053e <panic>

0000000080006a18 <virtio_disk_init>:
{
    80006a18:	1101                	addi	sp,sp,-32
    80006a1a:	ec06                	sd	ra,24(sp)
    80006a1c:	e822                	sd	s0,16(sp)
    80006a1e:	e426                	sd	s1,8(sp)
    80006a20:	e04a                	sd	s2,0(sp)
    80006a22:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006a24:	00002597          	auipc	a1,0x2
    80006a28:	eac58593          	addi	a1,a1,-340 # 800088d0 <syscalls+0x388>
    80006a2c:	00030517          	auipc	a0,0x30
    80006a30:	c8c50513          	addi	a0,a0,-884 # 800366b8 <disk+0x128>
    80006a34:	ffffa097          	auipc	ra,0xffffa
    80006a38:	112080e7          	jalr	274(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006a3c:	100017b7          	lui	a5,0x10001
    80006a40:	4398                	lw	a4,0(a5)
    80006a42:	2701                	sext.w	a4,a4
    80006a44:	747277b7          	lui	a5,0x74727
    80006a48:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006a4c:	14f71c63          	bne	a4,a5,80006ba4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006a50:	100017b7          	lui	a5,0x10001
    80006a54:	43dc                	lw	a5,4(a5)
    80006a56:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006a58:	4709                	li	a4,2
    80006a5a:	14e79563          	bne	a5,a4,80006ba4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006a5e:	100017b7          	lui	a5,0x10001
    80006a62:	479c                	lw	a5,8(a5)
    80006a64:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006a66:	12e79f63          	bne	a5,a4,80006ba4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006a6a:	100017b7          	lui	a5,0x10001
    80006a6e:	47d8                	lw	a4,12(a5)
    80006a70:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006a72:	554d47b7          	lui	a5,0x554d4
    80006a76:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006a7a:	12f71563          	bne	a4,a5,80006ba4 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a7e:	100017b7          	lui	a5,0x10001
    80006a82:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a86:	4705                	li	a4,1
    80006a88:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a8a:	470d                	li	a4,3
    80006a8c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006a8e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006a90:	c7ffe737          	lui	a4,0xc7ffe
    80006a94:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fc808f>
    80006a98:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006a9a:	2701                	sext.w	a4,a4
    80006a9c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a9e:	472d                	li	a4,11
    80006aa0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006aa2:	5bbc                	lw	a5,112(a5)
    80006aa4:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006aa8:	8ba1                	andi	a5,a5,8
    80006aaa:	10078563          	beqz	a5,80006bb4 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006aae:	100017b7          	lui	a5,0x10001
    80006ab2:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006ab6:	43fc                	lw	a5,68(a5)
    80006ab8:	2781                	sext.w	a5,a5
    80006aba:	10079563          	bnez	a5,80006bc4 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006abe:	100017b7          	lui	a5,0x10001
    80006ac2:	5bdc                	lw	a5,52(a5)
    80006ac4:	2781                	sext.w	a5,a5
  if(max == 0)
    80006ac6:	10078763          	beqz	a5,80006bd4 <virtio_disk_init+0x1bc>
  if(max < NUM)
    80006aca:	471d                	li	a4,7
    80006acc:	10f77c63          	bgeu	a4,a5,80006be4 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80006ad0:	ffffa097          	auipc	ra,0xffffa
    80006ad4:	016080e7          	jalr	22(ra) # 80000ae6 <kalloc>
    80006ad8:	00030497          	auipc	s1,0x30
    80006adc:	ab848493          	addi	s1,s1,-1352 # 80036590 <disk>
    80006ae0:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006ae2:	ffffa097          	auipc	ra,0xffffa
    80006ae6:	004080e7          	jalr	4(ra) # 80000ae6 <kalloc>
    80006aea:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80006aec:	ffffa097          	auipc	ra,0xffffa
    80006af0:	ffa080e7          	jalr	-6(ra) # 80000ae6 <kalloc>
    80006af4:	87aa                	mv	a5,a0
    80006af6:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006af8:	6088                	ld	a0,0(s1)
    80006afa:	cd6d                	beqz	a0,80006bf4 <virtio_disk_init+0x1dc>
    80006afc:	00030717          	auipc	a4,0x30
    80006b00:	a9c73703          	ld	a4,-1380(a4) # 80036598 <disk+0x8>
    80006b04:	cb65                	beqz	a4,80006bf4 <virtio_disk_init+0x1dc>
    80006b06:	c7fd                	beqz	a5,80006bf4 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80006b08:	6605                	lui	a2,0x1
    80006b0a:	4581                	li	a1,0
    80006b0c:	ffffa097          	auipc	ra,0xffffa
    80006b10:	1c6080e7          	jalr	454(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006b14:	00030497          	auipc	s1,0x30
    80006b18:	a7c48493          	addi	s1,s1,-1412 # 80036590 <disk>
    80006b1c:	6605                	lui	a2,0x1
    80006b1e:	4581                	li	a1,0
    80006b20:	6488                	ld	a0,8(s1)
    80006b22:	ffffa097          	auipc	ra,0xffffa
    80006b26:	1b0080e7          	jalr	432(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80006b2a:	6605                	lui	a2,0x1
    80006b2c:	4581                	li	a1,0
    80006b2e:	6888                	ld	a0,16(s1)
    80006b30:	ffffa097          	auipc	ra,0xffffa
    80006b34:	1a2080e7          	jalr	418(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006b38:	100017b7          	lui	a5,0x10001
    80006b3c:	4721                	li	a4,8
    80006b3e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006b40:	4098                	lw	a4,0(s1)
    80006b42:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006b46:	40d8                	lw	a4,4(s1)
    80006b48:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80006b4c:	6498                	ld	a4,8(s1)
    80006b4e:	0007069b          	sext.w	a3,a4
    80006b52:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006b56:	9701                	srai	a4,a4,0x20
    80006b58:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80006b5c:	6898                	ld	a4,16(s1)
    80006b5e:	0007069b          	sext.w	a3,a4
    80006b62:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006b66:	9701                	srai	a4,a4,0x20
    80006b68:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80006b6c:	4705                	li	a4,1
    80006b6e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006b70:	00e48c23          	sb	a4,24(s1)
    80006b74:	00e48ca3          	sb	a4,25(s1)
    80006b78:	00e48d23          	sb	a4,26(s1)
    80006b7c:	00e48da3          	sb	a4,27(s1)
    80006b80:	00e48e23          	sb	a4,28(s1)
    80006b84:	00e48ea3          	sb	a4,29(s1)
    80006b88:	00e48f23          	sb	a4,30(s1)
    80006b8c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006b90:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006b94:	0727a823          	sw	s2,112(a5)
}
    80006b98:	60e2                	ld	ra,24(sp)
    80006b9a:	6442                	ld	s0,16(sp)
    80006b9c:	64a2                	ld	s1,8(sp)
    80006b9e:	6902                	ld	s2,0(sp)
    80006ba0:	6105                	addi	sp,sp,32
    80006ba2:	8082                	ret
    panic("could not find virtio disk");
    80006ba4:	00002517          	auipc	a0,0x2
    80006ba8:	d3c50513          	addi	a0,a0,-708 # 800088e0 <syscalls+0x398>
    80006bac:	ffffa097          	auipc	ra,0xffffa
    80006bb0:	992080e7          	jalr	-1646(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006bb4:	00002517          	auipc	a0,0x2
    80006bb8:	d4c50513          	addi	a0,a0,-692 # 80008900 <syscalls+0x3b8>
    80006bbc:	ffffa097          	auipc	ra,0xffffa
    80006bc0:	982080e7          	jalr	-1662(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006bc4:	00002517          	auipc	a0,0x2
    80006bc8:	d5c50513          	addi	a0,a0,-676 # 80008920 <syscalls+0x3d8>
    80006bcc:	ffffa097          	auipc	ra,0xffffa
    80006bd0:	972080e7          	jalr	-1678(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006bd4:	00002517          	auipc	a0,0x2
    80006bd8:	d6c50513          	addi	a0,a0,-660 # 80008940 <syscalls+0x3f8>
    80006bdc:	ffffa097          	auipc	ra,0xffffa
    80006be0:	962080e7          	jalr	-1694(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006be4:	00002517          	auipc	a0,0x2
    80006be8:	d7c50513          	addi	a0,a0,-644 # 80008960 <syscalls+0x418>
    80006bec:	ffffa097          	auipc	ra,0xffffa
    80006bf0:	952080e7          	jalr	-1710(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80006bf4:	00002517          	auipc	a0,0x2
    80006bf8:	d8c50513          	addi	a0,a0,-628 # 80008980 <syscalls+0x438>
    80006bfc:	ffffa097          	auipc	ra,0xffffa
    80006c00:	942080e7          	jalr	-1726(ra) # 8000053e <panic>

0000000080006c04 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006c04:	7119                	addi	sp,sp,-128
    80006c06:	fc86                	sd	ra,120(sp)
    80006c08:	f8a2                	sd	s0,112(sp)
    80006c0a:	f4a6                	sd	s1,104(sp)
    80006c0c:	f0ca                	sd	s2,96(sp)
    80006c0e:	ecce                	sd	s3,88(sp)
    80006c10:	e8d2                	sd	s4,80(sp)
    80006c12:	e4d6                	sd	s5,72(sp)
    80006c14:	e0da                	sd	s6,64(sp)
    80006c16:	fc5e                	sd	s7,56(sp)
    80006c18:	f862                	sd	s8,48(sp)
    80006c1a:	f466                	sd	s9,40(sp)
    80006c1c:	f06a                	sd	s10,32(sp)
    80006c1e:	ec6e                	sd	s11,24(sp)
    80006c20:	0100                	addi	s0,sp,128
    80006c22:	8aaa                	mv	s5,a0
    80006c24:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006c26:	00c52d03          	lw	s10,12(a0)
    80006c2a:	001d1d1b          	slliw	s10,s10,0x1
    80006c2e:	1d02                	slli	s10,s10,0x20
    80006c30:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006c34:	00030517          	auipc	a0,0x30
    80006c38:	a8450513          	addi	a0,a0,-1404 # 800366b8 <disk+0x128>
    80006c3c:	ffffa097          	auipc	ra,0xffffa
    80006c40:	f9a080e7          	jalr	-102(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006c44:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006c46:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006c48:	00030b97          	auipc	s7,0x30
    80006c4c:	948b8b93          	addi	s7,s7,-1720 # 80036590 <disk>
  for(int i = 0; i < 3; i++){
    80006c50:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006c52:	00030c97          	auipc	s9,0x30
    80006c56:	a66c8c93          	addi	s9,s9,-1434 # 800366b8 <disk+0x128>
    80006c5a:	a08d                	j	80006cbc <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006c5c:	00fb8733          	add	a4,s7,a5
    80006c60:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006c64:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006c66:	0207c563          	bltz	a5,80006c90 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006c6a:	2905                	addiw	s2,s2,1
    80006c6c:	0611                	addi	a2,a2,4
    80006c6e:	05690c63          	beq	s2,s6,80006cc6 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006c72:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006c74:	00030717          	auipc	a4,0x30
    80006c78:	91c70713          	addi	a4,a4,-1764 # 80036590 <disk>
    80006c7c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006c7e:	01874683          	lbu	a3,24(a4)
    80006c82:	fee9                	bnez	a3,80006c5c <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006c84:	2785                	addiw	a5,a5,1
    80006c86:	0705                	addi	a4,a4,1
    80006c88:	fe979be3          	bne	a5,s1,80006c7e <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006c8c:	57fd                	li	a5,-1
    80006c8e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006c90:	01205d63          	blez	s2,80006caa <virtio_disk_rw+0xa6>
    80006c94:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006c96:	000a2503          	lw	a0,0(s4)
    80006c9a:	00000097          	auipc	ra,0x0
    80006c9e:	cfc080e7          	jalr	-772(ra) # 80006996 <free_desc>
      for(int j = 0; j < i; j++)
    80006ca2:	2d85                	addiw	s11,s11,1
    80006ca4:	0a11                	addi	s4,s4,4
    80006ca6:	ffb918e3          	bne	s2,s11,80006c96 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006caa:	85e6                	mv	a1,s9
    80006cac:	00030517          	auipc	a0,0x30
    80006cb0:	8fc50513          	addi	a0,a0,-1796 # 800365a8 <disk+0x18>
    80006cb4:	ffffb097          	auipc	ra,0xffffb
    80006cb8:	5a8080e7          	jalr	1448(ra) # 8000225c <sleep>
  for(int i = 0; i < 3; i++){
    80006cbc:	f8040a13          	addi	s4,s0,-128
{
    80006cc0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006cc2:	894e                	mv	s2,s3
    80006cc4:	b77d                	j	80006c72 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006cc6:	f8042583          	lw	a1,-128(s0)
    80006cca:	00a58793          	addi	a5,a1,10
    80006cce:	0792                	slli	a5,a5,0x4

  if(write)
    80006cd0:	00030617          	auipc	a2,0x30
    80006cd4:	8c060613          	addi	a2,a2,-1856 # 80036590 <disk>
    80006cd8:	00f60733          	add	a4,a2,a5
    80006cdc:	018036b3          	snez	a3,s8
    80006ce0:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006ce2:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006ce6:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006cea:	f6078693          	addi	a3,a5,-160
    80006cee:	6218                	ld	a4,0(a2)
    80006cf0:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006cf2:	00878513          	addi	a0,a5,8
    80006cf6:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006cf8:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006cfa:	6208                	ld	a0,0(a2)
    80006cfc:	96aa                	add	a3,a3,a0
    80006cfe:	4741                	li	a4,16
    80006d00:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006d02:	4705                	li	a4,1
    80006d04:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006d08:	f8442703          	lw	a4,-124(s0)
    80006d0c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006d10:	0712                	slli	a4,a4,0x4
    80006d12:	953a                	add	a0,a0,a4
    80006d14:	058a8693          	addi	a3,s5,88
    80006d18:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    80006d1a:	6208                	ld	a0,0(a2)
    80006d1c:	972a                	add	a4,a4,a0
    80006d1e:	40000693          	li	a3,1024
    80006d22:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006d24:	001c3c13          	seqz	s8,s8
    80006d28:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006d2a:	001c6c13          	ori	s8,s8,1
    80006d2e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006d32:	f8842603          	lw	a2,-120(s0)
    80006d36:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006d3a:	00030697          	auipc	a3,0x30
    80006d3e:	85668693          	addi	a3,a3,-1962 # 80036590 <disk>
    80006d42:	00258713          	addi	a4,a1,2
    80006d46:	0712                	slli	a4,a4,0x4
    80006d48:	9736                	add	a4,a4,a3
    80006d4a:	587d                	li	a6,-1
    80006d4c:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006d50:	0612                	slli	a2,a2,0x4
    80006d52:	9532                	add	a0,a0,a2
    80006d54:	f9078793          	addi	a5,a5,-112
    80006d58:	97b6                	add	a5,a5,a3
    80006d5a:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    80006d5c:	629c                	ld	a5,0(a3)
    80006d5e:	97b2                	add	a5,a5,a2
    80006d60:	4605                	li	a2,1
    80006d62:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006d64:	4509                	li	a0,2
    80006d66:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    80006d6a:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006d6e:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006d72:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006d76:	6698                	ld	a4,8(a3)
    80006d78:	00275783          	lhu	a5,2(a4)
    80006d7c:	8b9d                	andi	a5,a5,7
    80006d7e:	0786                	slli	a5,a5,0x1
    80006d80:	97ba                	add	a5,a5,a4
    80006d82:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006d86:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006d8a:	6698                	ld	a4,8(a3)
    80006d8c:	00275783          	lhu	a5,2(a4)
    80006d90:	2785                	addiw	a5,a5,1
    80006d92:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006d96:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006d9a:	100017b7          	lui	a5,0x10001
    80006d9e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006da2:	004aa783          	lw	a5,4(s5)
    80006da6:	02c79163          	bne	a5,a2,80006dc8 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006daa:	00030917          	auipc	s2,0x30
    80006dae:	90e90913          	addi	s2,s2,-1778 # 800366b8 <disk+0x128>
  while(b->disk == 1) {
    80006db2:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006db4:	85ca                	mv	a1,s2
    80006db6:	8556                	mv	a0,s5
    80006db8:	ffffb097          	auipc	ra,0xffffb
    80006dbc:	4a4080e7          	jalr	1188(ra) # 8000225c <sleep>
  while(b->disk == 1) {
    80006dc0:	004aa783          	lw	a5,4(s5)
    80006dc4:	fe9788e3          	beq	a5,s1,80006db4 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006dc8:	f8042903          	lw	s2,-128(s0)
    80006dcc:	00290793          	addi	a5,s2,2
    80006dd0:	00479713          	slli	a4,a5,0x4
    80006dd4:	0002f797          	auipc	a5,0x2f
    80006dd8:	7bc78793          	addi	a5,a5,1980 # 80036590 <disk>
    80006ddc:	97ba                	add	a5,a5,a4
    80006dde:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006de2:	0002f997          	auipc	s3,0x2f
    80006de6:	7ae98993          	addi	s3,s3,1966 # 80036590 <disk>
    80006dea:	00491713          	slli	a4,s2,0x4
    80006dee:	0009b783          	ld	a5,0(s3)
    80006df2:	97ba                	add	a5,a5,a4
    80006df4:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006df8:	854a                	mv	a0,s2
    80006dfa:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006dfe:	00000097          	auipc	ra,0x0
    80006e02:	b98080e7          	jalr	-1128(ra) # 80006996 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006e06:	8885                	andi	s1,s1,1
    80006e08:	f0ed                	bnez	s1,80006dea <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006e0a:	00030517          	auipc	a0,0x30
    80006e0e:	8ae50513          	addi	a0,a0,-1874 # 800366b8 <disk+0x128>
    80006e12:	ffffa097          	auipc	ra,0xffffa
    80006e16:	e78080e7          	jalr	-392(ra) # 80000c8a <release>
}
    80006e1a:	70e6                	ld	ra,120(sp)
    80006e1c:	7446                	ld	s0,112(sp)
    80006e1e:	74a6                	ld	s1,104(sp)
    80006e20:	7906                	ld	s2,96(sp)
    80006e22:	69e6                	ld	s3,88(sp)
    80006e24:	6a46                	ld	s4,80(sp)
    80006e26:	6aa6                	ld	s5,72(sp)
    80006e28:	6b06                	ld	s6,64(sp)
    80006e2a:	7be2                	ld	s7,56(sp)
    80006e2c:	7c42                	ld	s8,48(sp)
    80006e2e:	7ca2                	ld	s9,40(sp)
    80006e30:	7d02                	ld	s10,32(sp)
    80006e32:	6de2                	ld	s11,24(sp)
    80006e34:	6109                	addi	sp,sp,128
    80006e36:	8082                	ret

0000000080006e38 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006e38:	1101                	addi	sp,sp,-32
    80006e3a:	ec06                	sd	ra,24(sp)
    80006e3c:	e822                	sd	s0,16(sp)
    80006e3e:	e426                	sd	s1,8(sp)
    80006e40:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006e42:	0002f497          	auipc	s1,0x2f
    80006e46:	74e48493          	addi	s1,s1,1870 # 80036590 <disk>
    80006e4a:	00030517          	auipc	a0,0x30
    80006e4e:	86e50513          	addi	a0,a0,-1938 # 800366b8 <disk+0x128>
    80006e52:	ffffa097          	auipc	ra,0xffffa
    80006e56:	d84080e7          	jalr	-636(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006e5a:	10001737          	lui	a4,0x10001
    80006e5e:	533c                	lw	a5,96(a4)
    80006e60:	8b8d                	andi	a5,a5,3
    80006e62:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006e64:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006e68:	689c                	ld	a5,16(s1)
    80006e6a:	0204d703          	lhu	a4,32(s1)
    80006e6e:	0027d783          	lhu	a5,2(a5)
    80006e72:	04f70863          	beq	a4,a5,80006ec2 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006e76:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006e7a:	6898                	ld	a4,16(s1)
    80006e7c:	0204d783          	lhu	a5,32(s1)
    80006e80:	8b9d                	andi	a5,a5,7
    80006e82:	078e                	slli	a5,a5,0x3
    80006e84:	97ba                	add	a5,a5,a4
    80006e86:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006e88:	00278713          	addi	a4,a5,2
    80006e8c:	0712                	slli	a4,a4,0x4
    80006e8e:	9726                	add	a4,a4,s1
    80006e90:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006e94:	e721                	bnez	a4,80006edc <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006e96:	0789                	addi	a5,a5,2
    80006e98:	0792                	slli	a5,a5,0x4
    80006e9a:	97a6                	add	a5,a5,s1
    80006e9c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006e9e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006ea2:	ffffb097          	auipc	ra,0xffffb
    80006ea6:	41e080e7          	jalr	1054(ra) # 800022c0 <wakeup>

    disk.used_idx += 1;
    80006eaa:	0204d783          	lhu	a5,32(s1)
    80006eae:	2785                	addiw	a5,a5,1
    80006eb0:	17c2                	slli	a5,a5,0x30
    80006eb2:	93c1                	srli	a5,a5,0x30
    80006eb4:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006eb8:	6898                	ld	a4,16(s1)
    80006eba:	00275703          	lhu	a4,2(a4)
    80006ebe:	faf71ce3          	bne	a4,a5,80006e76 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006ec2:	0002f517          	auipc	a0,0x2f
    80006ec6:	7f650513          	addi	a0,a0,2038 # 800366b8 <disk+0x128>
    80006eca:	ffffa097          	auipc	ra,0xffffa
    80006ece:	dc0080e7          	jalr	-576(ra) # 80000c8a <release>
}
    80006ed2:	60e2                	ld	ra,24(sp)
    80006ed4:	6442                	ld	s0,16(sp)
    80006ed6:	64a2                	ld	s1,8(sp)
    80006ed8:	6105                	addi	sp,sp,32
    80006eda:	8082                	ret
      panic("virtio_disk_intr status");
    80006edc:	00002517          	auipc	a0,0x2
    80006ee0:	abc50513          	addi	a0,a0,-1348 # 80008998 <syscalls+0x450>
    80006ee4:	ffff9097          	auipc	ra,0xffff9
    80006ee8:	65a080e7          	jalr	1626(ra) # 8000053e <panic>
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
