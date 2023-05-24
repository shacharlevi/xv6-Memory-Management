
user/_ustack_test:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/stat.h"
#include "user/user.h"
#include "user/ustack.h"
int
main(int argc, char *argv[])
{
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
    if(ustack_free() > 0){
   8:	00001097          	auipc	ra,0x1
   c:	a14080e7          	jalr	-1516(ra) # a1c <ustack_free>
  10:	12a04a63          	bgtz	a0,144 <main+0x144>
        fprintf(2, "First free has failed\n");    
    }
    printf("%p\n", ustack_malloc(10));
  14:	4529                	li	a0,10
  16:	00001097          	auipc	ra,0x1
  1a:	990080e7          	jalr	-1648(ra) # 9a6 <ustack_malloc>
  1e:	85aa                	mv	a1,a0
  20:	00001517          	auipc	a0,0x1
  24:	aa850513          	addi	a0,a0,-1368 # ac8 <ustack_free+0xac>
  28:	00000097          	auipc	ra,0x0
  2c:	7dc080e7          	jalr	2012(ra) # 804 <printf>
    printf("%p\n", ustack_malloc(15));
  30:	453d                	li	a0,15
  32:	00001097          	auipc	ra,0x1
  36:	974080e7          	jalr	-1676(ra) # 9a6 <ustack_malloc>
  3a:	85aa                	mv	a1,a0
  3c:	00001517          	auipc	a0,0x1
  40:	a8c50513          	addi	a0,a0,-1396 # ac8 <ustack_free+0xac>
  44:	00000097          	auipc	ra,0x0
  48:	7c0080e7          	jalr	1984(ra) # 804 <printf>
    printf("%p\n", ustack_malloc(20));
  4c:	4551                	li	a0,20
  4e:	00001097          	auipc	ra,0x1
  52:	958080e7          	jalr	-1704(ra) # 9a6 <ustack_malloc>
  56:	85aa                	mv	a1,a0
  58:	00001517          	auipc	a0,0x1
  5c:	a7050513          	addi	a0,a0,-1424 # ac8 <ustack_free+0xac>
  60:	00000097          	auipc	ra,0x0
  64:	7a4080e7          	jalr	1956(ra) # 804 <printf>
    int val = ustack_free();
  68:	00001097          	auipc	ra,0x1
  6c:	9b4080e7          	jalr	-1612(ra) # a1c <ustack_free>
    if(val != 20){
  70:	47d1                	li	a5,20
  72:	0ef51363          	bne	a0,a5,158 <main+0x158>
        fprintf(2, "Val is equal to %d instead of 20\n", val);    
    }
    val = ustack_free();
  76:	00001097          	auipc	ra,0x1
  7a:	9a6080e7          	jalr	-1626(ra) # a1c <ustack_free>
    if(val != 15){
  7e:	47bd                	li	a5,15
  80:	0ef51763          	bne	a0,a5,16e <main+0x16e>
        fprintf(2, "Val is equal to %d instead of 15\n", val);    
    }
    val = ustack_free();
  84:	00001097          	auipc	ra,0x1
  88:	998080e7          	jalr	-1640(ra) # a1c <ustack_free>
    if(val != 10){
  8c:	47a9                	li	a5,10
  8e:	0ef51b63          	bne	a0,a5,184 <main+0x184>
        fprintf(2, "Val is equal to %d instead of 10\n", val);    
    }
    
    if(ustack_free() > 0){
  92:	00001097          	auipc	ra,0x1
  96:	98a080e7          	jalr	-1654(ra) # a1c <ustack_free>
  9a:	10a04063          	bgtz	a0,19a <main+0x19a>
        fprintf(2, "First free has failed\n");    
    }
    printf("%p\n", ustack_malloc(10));
  9e:	4529                	li	a0,10
  a0:	00001097          	auipc	ra,0x1
  a4:	906080e7          	jalr	-1786(ra) # 9a6 <ustack_malloc>
  a8:	85aa                	mv	a1,a0
  aa:	00001517          	auipc	a0,0x1
  ae:	a1e50513          	addi	a0,a0,-1506 # ac8 <ustack_free+0xac>
  b2:	00000097          	auipc	ra,0x0
  b6:	752080e7          	jalr	1874(ra) # 804 <printf>
    printf("%p\n", ustack_malloc(15));
  ba:	453d                	li	a0,15
  bc:	00001097          	auipc	ra,0x1
  c0:	8ea080e7          	jalr	-1814(ra) # 9a6 <ustack_malloc>
  c4:	85aa                	mv	a1,a0
  c6:	00001517          	auipc	a0,0x1
  ca:	a0250513          	addi	a0,a0,-1534 # ac8 <ustack_free+0xac>
  ce:	00000097          	auipc	ra,0x0
  d2:	736080e7          	jalr	1846(ra) # 804 <printf>
    printf("%p\n", ustack_malloc(20));
  d6:	4551                	li	a0,20
  d8:	00001097          	auipc	ra,0x1
  dc:	8ce080e7          	jalr	-1842(ra) # 9a6 <ustack_malloc>
  e0:	85aa                	mv	a1,a0
  e2:	00001517          	auipc	a0,0x1
  e6:	9e650513          	addi	a0,a0,-1562 # ac8 <ustack_free+0xac>
  ea:	00000097          	auipc	ra,0x0
  ee:	71a080e7          	jalr	1818(ra) # 804 <printf>
    
    val = ustack_free();
  f2:	00001097          	auipc	ra,0x1
  f6:	92a080e7          	jalr	-1750(ra) # a1c <ustack_free>
    if(val != 20){
  fa:	47d1                	li	a5,20
  fc:	0af51963          	bne	a0,a5,1ae <main+0x1ae>
        fprintf(2, "Val is equal to %d instead of 20\n", val);    
    }
    val = ustack_free();
 100:	00001097          	auipc	ra,0x1
 104:	91c080e7          	jalr	-1764(ra) # a1c <ustack_free>
    if(val != 15){
 108:	47bd                	li	a5,15
 10a:	0af51d63          	bne	a0,a5,1c4 <main+0x1c4>
        fprintf(2, "Val is equal to %d instead of 15\n", val);    
    }
    val = ustack_free();
 10e:	00001097          	auipc	ra,0x1
 112:	90e080e7          	jalr	-1778(ra) # a1c <ustack_free>
    if(val != 10){
 116:	47a9                	li	a5,10
 118:	0cf51163          	bne	a0,a5,1da <main+0x1da>
        fprintf(2, "Val is equal to %d instead of 10\n", val);    
    }
    
    if(ustack_free() > 0){
 11c:	00001097          	auipc	ra,0x1
 120:	900080e7          	jalr	-1792(ra) # a1c <ustack_free>
 124:	0ca04663          	bgtz	a0,1f0 <main+0x1f0>
        fprintf(2, "First free has failed\n");    
    }
    fprintf(2, "Finished testing\n");
 128:	00001597          	auipc	a1,0x1
 12c:	a2058593          	addi	a1,a1,-1504 # b48 <ustack_free+0x12c>
 130:	4509                	li	a0,2
 132:	00000097          	auipc	ra,0x0
 136:	6a4080e7          	jalr	1700(ra) # 7d6 <fprintf>
    exit(0);
 13a:	4501                	li	a0,0
 13c:	00000097          	auipc	ra,0x0
 140:	350080e7          	jalr	848(ra) # 48c <exit>
        fprintf(2, "First free has failed\n");    
 144:	00001597          	auipc	a1,0x1
 148:	96c58593          	addi	a1,a1,-1684 # ab0 <ustack_free+0x94>
 14c:	4509                	li	a0,2
 14e:	00000097          	auipc	ra,0x0
 152:	688080e7          	jalr	1672(ra) # 7d6 <fprintf>
 156:	bd7d                	j	14 <main+0x14>
        fprintf(2, "Val is equal to %d instead of 20\n", val);    
 158:	862a                	mv	a2,a0
 15a:	00001597          	auipc	a1,0x1
 15e:	97658593          	addi	a1,a1,-1674 # ad0 <ustack_free+0xb4>
 162:	4509                	li	a0,2
 164:	00000097          	auipc	ra,0x0
 168:	672080e7          	jalr	1650(ra) # 7d6 <fprintf>
 16c:	b729                	j	76 <main+0x76>
        fprintf(2, "Val is equal to %d instead of 15\n", val);    
 16e:	862a                	mv	a2,a0
 170:	00001597          	auipc	a1,0x1
 174:	98858593          	addi	a1,a1,-1656 # af8 <ustack_free+0xdc>
 178:	4509                	li	a0,2
 17a:	00000097          	auipc	ra,0x0
 17e:	65c080e7          	jalr	1628(ra) # 7d6 <fprintf>
 182:	b709                	j	84 <main+0x84>
        fprintf(2, "Val is equal to %d instead of 10\n", val);    
 184:	862a                	mv	a2,a0
 186:	00001597          	auipc	a1,0x1
 18a:	99a58593          	addi	a1,a1,-1638 # b20 <ustack_free+0x104>
 18e:	4509                	li	a0,2
 190:	00000097          	auipc	ra,0x0
 194:	646080e7          	jalr	1606(ra) # 7d6 <fprintf>
 198:	bded                	j	92 <main+0x92>
        fprintf(2, "First free has failed\n");    
 19a:	00001597          	auipc	a1,0x1
 19e:	91658593          	addi	a1,a1,-1770 # ab0 <ustack_free+0x94>
 1a2:	4509                	li	a0,2
 1a4:	00000097          	auipc	ra,0x0
 1a8:	632080e7          	jalr	1586(ra) # 7d6 <fprintf>
 1ac:	bdcd                	j	9e <main+0x9e>
        fprintf(2, "Val is equal to %d instead of 20\n", val);    
 1ae:	862a                	mv	a2,a0
 1b0:	00001597          	auipc	a1,0x1
 1b4:	92058593          	addi	a1,a1,-1760 # ad0 <ustack_free+0xb4>
 1b8:	4509                	li	a0,2
 1ba:	00000097          	auipc	ra,0x0
 1be:	61c080e7          	jalr	1564(ra) # 7d6 <fprintf>
 1c2:	bf3d                	j	100 <main+0x100>
        fprintf(2, "Val is equal to %d instead of 15\n", val);    
 1c4:	862a                	mv	a2,a0
 1c6:	00001597          	auipc	a1,0x1
 1ca:	93258593          	addi	a1,a1,-1742 # af8 <ustack_free+0xdc>
 1ce:	4509                	li	a0,2
 1d0:	00000097          	auipc	ra,0x0
 1d4:	606080e7          	jalr	1542(ra) # 7d6 <fprintf>
 1d8:	bf1d                	j	10e <main+0x10e>
        fprintf(2, "Val is equal to %d instead of 10\n", val);    
 1da:	862a                	mv	a2,a0
 1dc:	00001597          	auipc	a1,0x1
 1e0:	94458593          	addi	a1,a1,-1724 # b20 <ustack_free+0x104>
 1e4:	4509                	li	a0,2
 1e6:	00000097          	auipc	ra,0x0
 1ea:	5f0080e7          	jalr	1520(ra) # 7d6 <fprintf>
 1ee:	b73d                	j	11c <main+0x11c>
        fprintf(2, "First free has failed\n");    
 1f0:	00001597          	auipc	a1,0x1
 1f4:	8c058593          	addi	a1,a1,-1856 # ab0 <ustack_free+0x94>
 1f8:	4509                	li	a0,2
 1fa:	00000097          	auipc	ra,0x0
 1fe:	5dc080e7          	jalr	1500(ra) # 7d6 <fprintf>
 202:	b71d                	j	128 <main+0x128>

0000000000000204 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 204:	1141                	addi	sp,sp,-16
 206:	e406                	sd	ra,8(sp)
 208:	e022                	sd	s0,0(sp)
 20a:	0800                	addi	s0,sp,16
  extern int main();
  main();
 20c:	00000097          	auipc	ra,0x0
 210:	df4080e7          	jalr	-524(ra) # 0 <main>
  exit(0);
 214:	4501                	li	a0,0
 216:	00000097          	auipc	ra,0x0
 21a:	276080e7          	jalr	630(ra) # 48c <exit>

000000000000021e <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 21e:	1141                	addi	sp,sp,-16
 220:	e422                	sd	s0,8(sp)
 222:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 224:	87aa                	mv	a5,a0
 226:	0585                	addi	a1,a1,1
 228:	0785                	addi	a5,a5,1
 22a:	fff5c703          	lbu	a4,-1(a1)
 22e:	fee78fa3          	sb	a4,-1(a5)
 232:	fb75                	bnez	a4,226 <strcpy+0x8>
    ;
  return os;
}
 234:	6422                	ld	s0,8(sp)
 236:	0141                	addi	sp,sp,16
 238:	8082                	ret

000000000000023a <strcmp>:

int
strcmp(const char *p, const char *q)
{
 23a:	1141                	addi	sp,sp,-16
 23c:	e422                	sd	s0,8(sp)
 23e:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 240:	00054783          	lbu	a5,0(a0)
 244:	cb91                	beqz	a5,258 <strcmp+0x1e>
 246:	0005c703          	lbu	a4,0(a1)
 24a:	00f71763          	bne	a4,a5,258 <strcmp+0x1e>
    p++, q++;
 24e:	0505                	addi	a0,a0,1
 250:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 252:	00054783          	lbu	a5,0(a0)
 256:	fbe5                	bnez	a5,246 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 258:	0005c503          	lbu	a0,0(a1)
}
 25c:	40a7853b          	subw	a0,a5,a0
 260:	6422                	ld	s0,8(sp)
 262:	0141                	addi	sp,sp,16
 264:	8082                	ret

0000000000000266 <strlen>:

uint
strlen(const char *s)
{
 266:	1141                	addi	sp,sp,-16
 268:	e422                	sd	s0,8(sp)
 26a:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 26c:	00054783          	lbu	a5,0(a0)
 270:	cf91                	beqz	a5,28c <strlen+0x26>
 272:	0505                	addi	a0,a0,1
 274:	87aa                	mv	a5,a0
 276:	4685                	li	a3,1
 278:	9e89                	subw	a3,a3,a0
 27a:	00f6853b          	addw	a0,a3,a5
 27e:	0785                	addi	a5,a5,1
 280:	fff7c703          	lbu	a4,-1(a5)
 284:	fb7d                	bnez	a4,27a <strlen+0x14>
    ;
  return n;
}
 286:	6422                	ld	s0,8(sp)
 288:	0141                	addi	sp,sp,16
 28a:	8082                	ret
  for(n = 0; s[n]; n++)
 28c:	4501                	li	a0,0
 28e:	bfe5                	j	286 <strlen+0x20>

0000000000000290 <memset>:

void*
memset(void *dst, int c, uint n)
{
 290:	1141                	addi	sp,sp,-16
 292:	e422                	sd	s0,8(sp)
 294:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 296:	ca19                	beqz	a2,2ac <memset+0x1c>
 298:	87aa                	mv	a5,a0
 29a:	1602                	slli	a2,a2,0x20
 29c:	9201                	srli	a2,a2,0x20
 29e:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 2a2:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 2a6:	0785                	addi	a5,a5,1
 2a8:	fee79de3          	bne	a5,a4,2a2 <memset+0x12>
  }
  return dst;
}
 2ac:	6422                	ld	s0,8(sp)
 2ae:	0141                	addi	sp,sp,16
 2b0:	8082                	ret

00000000000002b2 <strchr>:

char*
strchr(const char *s, char c)
{
 2b2:	1141                	addi	sp,sp,-16
 2b4:	e422                	sd	s0,8(sp)
 2b6:	0800                	addi	s0,sp,16
  for(; *s; s++)
 2b8:	00054783          	lbu	a5,0(a0)
 2bc:	cb99                	beqz	a5,2d2 <strchr+0x20>
    if(*s == c)
 2be:	00f58763          	beq	a1,a5,2cc <strchr+0x1a>
  for(; *s; s++)
 2c2:	0505                	addi	a0,a0,1
 2c4:	00054783          	lbu	a5,0(a0)
 2c8:	fbfd                	bnez	a5,2be <strchr+0xc>
      return (char*)s;
  return 0;
 2ca:	4501                	li	a0,0
}
 2cc:	6422                	ld	s0,8(sp)
 2ce:	0141                	addi	sp,sp,16
 2d0:	8082                	ret
  return 0;
 2d2:	4501                	li	a0,0
 2d4:	bfe5                	j	2cc <strchr+0x1a>

00000000000002d6 <gets>:

char*
gets(char *buf, int max)
{
 2d6:	711d                	addi	sp,sp,-96
 2d8:	ec86                	sd	ra,88(sp)
 2da:	e8a2                	sd	s0,80(sp)
 2dc:	e4a6                	sd	s1,72(sp)
 2de:	e0ca                	sd	s2,64(sp)
 2e0:	fc4e                	sd	s3,56(sp)
 2e2:	f852                	sd	s4,48(sp)
 2e4:	f456                	sd	s5,40(sp)
 2e6:	f05a                	sd	s6,32(sp)
 2e8:	ec5e                	sd	s7,24(sp)
 2ea:	1080                	addi	s0,sp,96
 2ec:	8baa                	mv	s7,a0
 2ee:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 2f0:	892a                	mv	s2,a0
 2f2:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 2f4:	4aa9                	li	s5,10
 2f6:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 2f8:	89a6                	mv	s3,s1
 2fa:	2485                	addiw	s1,s1,1
 2fc:	0344d863          	bge	s1,s4,32c <gets+0x56>
    cc = read(0, &c, 1);
 300:	4605                	li	a2,1
 302:	faf40593          	addi	a1,s0,-81
 306:	4501                	li	a0,0
 308:	00000097          	auipc	ra,0x0
 30c:	19c080e7          	jalr	412(ra) # 4a4 <read>
    if(cc < 1)
 310:	00a05e63          	blez	a0,32c <gets+0x56>
    buf[i++] = c;
 314:	faf44783          	lbu	a5,-81(s0)
 318:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 31c:	01578763          	beq	a5,s5,32a <gets+0x54>
 320:	0905                	addi	s2,s2,1
 322:	fd679be3          	bne	a5,s6,2f8 <gets+0x22>
  for(i=0; i+1 < max; ){
 326:	89a6                	mv	s3,s1
 328:	a011                	j	32c <gets+0x56>
 32a:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 32c:	99de                	add	s3,s3,s7
 32e:	00098023          	sb	zero,0(s3)
  return buf;
}
 332:	855e                	mv	a0,s7
 334:	60e6                	ld	ra,88(sp)
 336:	6446                	ld	s0,80(sp)
 338:	64a6                	ld	s1,72(sp)
 33a:	6906                	ld	s2,64(sp)
 33c:	79e2                	ld	s3,56(sp)
 33e:	7a42                	ld	s4,48(sp)
 340:	7aa2                	ld	s5,40(sp)
 342:	7b02                	ld	s6,32(sp)
 344:	6be2                	ld	s7,24(sp)
 346:	6125                	addi	sp,sp,96
 348:	8082                	ret

000000000000034a <stat>:

int
stat(const char *n, struct stat *st)
{
 34a:	1101                	addi	sp,sp,-32
 34c:	ec06                	sd	ra,24(sp)
 34e:	e822                	sd	s0,16(sp)
 350:	e426                	sd	s1,8(sp)
 352:	e04a                	sd	s2,0(sp)
 354:	1000                	addi	s0,sp,32
 356:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 358:	4581                	li	a1,0
 35a:	00000097          	auipc	ra,0x0
 35e:	172080e7          	jalr	370(ra) # 4cc <open>
  if(fd < 0)
 362:	02054563          	bltz	a0,38c <stat+0x42>
 366:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 368:	85ca                	mv	a1,s2
 36a:	00000097          	auipc	ra,0x0
 36e:	17a080e7          	jalr	378(ra) # 4e4 <fstat>
 372:	892a                	mv	s2,a0
  close(fd);
 374:	8526                	mv	a0,s1
 376:	00000097          	auipc	ra,0x0
 37a:	13e080e7          	jalr	318(ra) # 4b4 <close>
  return r;
}
 37e:	854a                	mv	a0,s2
 380:	60e2                	ld	ra,24(sp)
 382:	6442                	ld	s0,16(sp)
 384:	64a2                	ld	s1,8(sp)
 386:	6902                	ld	s2,0(sp)
 388:	6105                	addi	sp,sp,32
 38a:	8082                	ret
    return -1;
 38c:	597d                	li	s2,-1
 38e:	bfc5                	j	37e <stat+0x34>

0000000000000390 <atoi>:

int
atoi(const char *s)
{
 390:	1141                	addi	sp,sp,-16
 392:	e422                	sd	s0,8(sp)
 394:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 396:	00054603          	lbu	a2,0(a0)
 39a:	fd06079b          	addiw	a5,a2,-48
 39e:	0ff7f793          	andi	a5,a5,255
 3a2:	4725                	li	a4,9
 3a4:	02f76963          	bltu	a4,a5,3d6 <atoi+0x46>
 3a8:	86aa                	mv	a3,a0
  n = 0;
 3aa:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 3ac:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 3ae:	0685                	addi	a3,a3,1
 3b0:	0025179b          	slliw	a5,a0,0x2
 3b4:	9fa9                	addw	a5,a5,a0
 3b6:	0017979b          	slliw	a5,a5,0x1
 3ba:	9fb1                	addw	a5,a5,a2
 3bc:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 3c0:	0006c603          	lbu	a2,0(a3)
 3c4:	fd06071b          	addiw	a4,a2,-48
 3c8:	0ff77713          	andi	a4,a4,255
 3cc:	fee5f1e3          	bgeu	a1,a4,3ae <atoi+0x1e>
  return n;
}
 3d0:	6422                	ld	s0,8(sp)
 3d2:	0141                	addi	sp,sp,16
 3d4:	8082                	ret
  n = 0;
 3d6:	4501                	li	a0,0
 3d8:	bfe5                	j	3d0 <atoi+0x40>

00000000000003da <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 3da:	1141                	addi	sp,sp,-16
 3dc:	e422                	sd	s0,8(sp)
 3de:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 3e0:	02b57463          	bgeu	a0,a1,408 <memmove+0x2e>
    while(n-- > 0)
 3e4:	00c05f63          	blez	a2,402 <memmove+0x28>
 3e8:	1602                	slli	a2,a2,0x20
 3ea:	9201                	srli	a2,a2,0x20
 3ec:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 3f0:	872a                	mv	a4,a0
      *dst++ = *src++;
 3f2:	0585                	addi	a1,a1,1
 3f4:	0705                	addi	a4,a4,1
 3f6:	fff5c683          	lbu	a3,-1(a1)
 3fa:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 3fe:	fee79ae3          	bne	a5,a4,3f2 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 402:	6422                	ld	s0,8(sp)
 404:	0141                	addi	sp,sp,16
 406:	8082                	ret
    dst += n;
 408:	00c50733          	add	a4,a0,a2
    src += n;
 40c:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 40e:	fec05ae3          	blez	a2,402 <memmove+0x28>
 412:	fff6079b          	addiw	a5,a2,-1
 416:	1782                	slli	a5,a5,0x20
 418:	9381                	srli	a5,a5,0x20
 41a:	fff7c793          	not	a5,a5
 41e:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 420:	15fd                	addi	a1,a1,-1
 422:	177d                	addi	a4,a4,-1
 424:	0005c683          	lbu	a3,0(a1)
 428:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 42c:	fee79ae3          	bne	a5,a4,420 <memmove+0x46>
 430:	bfc9                	j	402 <memmove+0x28>

0000000000000432 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 432:	1141                	addi	sp,sp,-16
 434:	e422                	sd	s0,8(sp)
 436:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 438:	ca05                	beqz	a2,468 <memcmp+0x36>
 43a:	fff6069b          	addiw	a3,a2,-1
 43e:	1682                	slli	a3,a3,0x20
 440:	9281                	srli	a3,a3,0x20
 442:	0685                	addi	a3,a3,1
 444:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 446:	00054783          	lbu	a5,0(a0)
 44a:	0005c703          	lbu	a4,0(a1)
 44e:	00e79863          	bne	a5,a4,45e <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 452:	0505                	addi	a0,a0,1
    p2++;
 454:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 456:	fed518e3          	bne	a0,a3,446 <memcmp+0x14>
  }
  return 0;
 45a:	4501                	li	a0,0
 45c:	a019                	j	462 <memcmp+0x30>
      return *p1 - *p2;
 45e:	40e7853b          	subw	a0,a5,a4
}
 462:	6422                	ld	s0,8(sp)
 464:	0141                	addi	sp,sp,16
 466:	8082                	ret
  return 0;
 468:	4501                	li	a0,0
 46a:	bfe5                	j	462 <memcmp+0x30>

000000000000046c <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 46c:	1141                	addi	sp,sp,-16
 46e:	e406                	sd	ra,8(sp)
 470:	e022                	sd	s0,0(sp)
 472:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 474:	00000097          	auipc	ra,0x0
 478:	f66080e7          	jalr	-154(ra) # 3da <memmove>
}
 47c:	60a2                	ld	ra,8(sp)
 47e:	6402                	ld	s0,0(sp)
 480:	0141                	addi	sp,sp,16
 482:	8082                	ret

0000000000000484 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 484:	4885                	li	a7,1
 ecall
 486:	00000073          	ecall
 ret
 48a:	8082                	ret

000000000000048c <exit>:
.global exit
exit:
 li a7, SYS_exit
 48c:	4889                	li	a7,2
 ecall
 48e:	00000073          	ecall
 ret
 492:	8082                	ret

0000000000000494 <wait>:
.global wait
wait:
 li a7, SYS_wait
 494:	488d                	li	a7,3
 ecall
 496:	00000073          	ecall
 ret
 49a:	8082                	ret

000000000000049c <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 49c:	4891                	li	a7,4
 ecall
 49e:	00000073          	ecall
 ret
 4a2:	8082                	ret

00000000000004a4 <read>:
.global read
read:
 li a7, SYS_read
 4a4:	4895                	li	a7,5
 ecall
 4a6:	00000073          	ecall
 ret
 4aa:	8082                	ret

00000000000004ac <write>:
.global write
write:
 li a7, SYS_write
 4ac:	48c1                	li	a7,16
 ecall
 4ae:	00000073          	ecall
 ret
 4b2:	8082                	ret

00000000000004b4 <close>:
.global close
close:
 li a7, SYS_close
 4b4:	48d5                	li	a7,21
 ecall
 4b6:	00000073          	ecall
 ret
 4ba:	8082                	ret

00000000000004bc <kill>:
.global kill
kill:
 li a7, SYS_kill
 4bc:	4899                	li	a7,6
 ecall
 4be:	00000073          	ecall
 ret
 4c2:	8082                	ret

00000000000004c4 <exec>:
.global exec
exec:
 li a7, SYS_exec
 4c4:	489d                	li	a7,7
 ecall
 4c6:	00000073          	ecall
 ret
 4ca:	8082                	ret

00000000000004cc <open>:
.global open
open:
 li a7, SYS_open
 4cc:	48bd                	li	a7,15
 ecall
 4ce:	00000073          	ecall
 ret
 4d2:	8082                	ret

00000000000004d4 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 4d4:	48c5                	li	a7,17
 ecall
 4d6:	00000073          	ecall
 ret
 4da:	8082                	ret

00000000000004dc <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 4dc:	48c9                	li	a7,18
 ecall
 4de:	00000073          	ecall
 ret
 4e2:	8082                	ret

00000000000004e4 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 4e4:	48a1                	li	a7,8
 ecall
 4e6:	00000073          	ecall
 ret
 4ea:	8082                	ret

00000000000004ec <link>:
.global link
link:
 li a7, SYS_link
 4ec:	48cd                	li	a7,19
 ecall
 4ee:	00000073          	ecall
 ret
 4f2:	8082                	ret

00000000000004f4 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 4f4:	48d1                	li	a7,20
 ecall
 4f6:	00000073          	ecall
 ret
 4fa:	8082                	ret

00000000000004fc <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 4fc:	48a5                	li	a7,9
 ecall
 4fe:	00000073          	ecall
 ret
 502:	8082                	ret

0000000000000504 <dup>:
.global dup
dup:
 li a7, SYS_dup
 504:	48a9                	li	a7,10
 ecall
 506:	00000073          	ecall
 ret
 50a:	8082                	ret

000000000000050c <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 50c:	48ad                	li	a7,11
 ecall
 50e:	00000073          	ecall
 ret
 512:	8082                	ret

0000000000000514 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 514:	48b1                	li	a7,12
 ecall
 516:	00000073          	ecall
 ret
 51a:	8082                	ret

000000000000051c <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 51c:	48b5                	li	a7,13
 ecall
 51e:	00000073          	ecall
 ret
 522:	8082                	ret

0000000000000524 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 524:	48b9                	li	a7,14
 ecall
 526:	00000073          	ecall
 ret
 52a:	8082                	ret

000000000000052c <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 52c:	1101                	addi	sp,sp,-32
 52e:	ec06                	sd	ra,24(sp)
 530:	e822                	sd	s0,16(sp)
 532:	1000                	addi	s0,sp,32
 534:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 538:	4605                	li	a2,1
 53a:	fef40593          	addi	a1,s0,-17
 53e:	00000097          	auipc	ra,0x0
 542:	f6e080e7          	jalr	-146(ra) # 4ac <write>
}
 546:	60e2                	ld	ra,24(sp)
 548:	6442                	ld	s0,16(sp)
 54a:	6105                	addi	sp,sp,32
 54c:	8082                	ret

000000000000054e <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 54e:	7139                	addi	sp,sp,-64
 550:	fc06                	sd	ra,56(sp)
 552:	f822                	sd	s0,48(sp)
 554:	f426                	sd	s1,40(sp)
 556:	f04a                	sd	s2,32(sp)
 558:	ec4e                	sd	s3,24(sp)
 55a:	0080                	addi	s0,sp,64
 55c:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 55e:	c299                	beqz	a3,564 <printint+0x16>
 560:	0805c863          	bltz	a1,5f0 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 564:	2581                	sext.w	a1,a1
  neg = 0;
 566:	4881                	li	a7,0
 568:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 56c:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 56e:	2601                	sext.w	a2,a2
 570:	00000517          	auipc	a0,0x0
 574:	5f850513          	addi	a0,a0,1528 # b68 <digits>
 578:	883a                	mv	a6,a4
 57a:	2705                	addiw	a4,a4,1
 57c:	02c5f7bb          	remuw	a5,a1,a2
 580:	1782                	slli	a5,a5,0x20
 582:	9381                	srli	a5,a5,0x20
 584:	97aa                	add	a5,a5,a0
 586:	0007c783          	lbu	a5,0(a5)
 58a:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 58e:	0005879b          	sext.w	a5,a1
 592:	02c5d5bb          	divuw	a1,a1,a2
 596:	0685                	addi	a3,a3,1
 598:	fec7f0e3          	bgeu	a5,a2,578 <printint+0x2a>
  if(neg)
 59c:	00088b63          	beqz	a7,5b2 <printint+0x64>
    buf[i++] = '-';
 5a0:	fd040793          	addi	a5,s0,-48
 5a4:	973e                	add	a4,a4,a5
 5a6:	02d00793          	li	a5,45
 5aa:	fef70823          	sb	a5,-16(a4)
 5ae:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 5b2:	02e05863          	blez	a4,5e2 <printint+0x94>
 5b6:	fc040793          	addi	a5,s0,-64
 5ba:	00e78933          	add	s2,a5,a4
 5be:	fff78993          	addi	s3,a5,-1
 5c2:	99ba                	add	s3,s3,a4
 5c4:	377d                	addiw	a4,a4,-1
 5c6:	1702                	slli	a4,a4,0x20
 5c8:	9301                	srli	a4,a4,0x20
 5ca:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 5ce:	fff94583          	lbu	a1,-1(s2)
 5d2:	8526                	mv	a0,s1
 5d4:	00000097          	auipc	ra,0x0
 5d8:	f58080e7          	jalr	-168(ra) # 52c <putc>
  while(--i >= 0)
 5dc:	197d                	addi	s2,s2,-1
 5de:	ff3918e3          	bne	s2,s3,5ce <printint+0x80>
}
 5e2:	70e2                	ld	ra,56(sp)
 5e4:	7442                	ld	s0,48(sp)
 5e6:	74a2                	ld	s1,40(sp)
 5e8:	7902                	ld	s2,32(sp)
 5ea:	69e2                	ld	s3,24(sp)
 5ec:	6121                	addi	sp,sp,64
 5ee:	8082                	ret
    x = -xx;
 5f0:	40b005bb          	negw	a1,a1
    neg = 1;
 5f4:	4885                	li	a7,1
    x = -xx;
 5f6:	bf8d                	j	568 <printint+0x1a>

00000000000005f8 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 5f8:	7119                	addi	sp,sp,-128
 5fa:	fc86                	sd	ra,120(sp)
 5fc:	f8a2                	sd	s0,112(sp)
 5fe:	f4a6                	sd	s1,104(sp)
 600:	f0ca                	sd	s2,96(sp)
 602:	ecce                	sd	s3,88(sp)
 604:	e8d2                	sd	s4,80(sp)
 606:	e4d6                	sd	s5,72(sp)
 608:	e0da                	sd	s6,64(sp)
 60a:	fc5e                	sd	s7,56(sp)
 60c:	f862                	sd	s8,48(sp)
 60e:	f466                	sd	s9,40(sp)
 610:	f06a                	sd	s10,32(sp)
 612:	ec6e                	sd	s11,24(sp)
 614:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 616:	0005c903          	lbu	s2,0(a1)
 61a:	18090f63          	beqz	s2,7b8 <vprintf+0x1c0>
 61e:	8aaa                	mv	s5,a0
 620:	8b32                	mv	s6,a2
 622:	00158493          	addi	s1,a1,1
  state = 0;
 626:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 628:	02500a13          	li	s4,37
      if(c == 'd'){
 62c:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 630:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 634:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 638:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 63c:	00000b97          	auipc	s7,0x0
 640:	52cb8b93          	addi	s7,s7,1324 # b68 <digits>
 644:	a839                	j	662 <vprintf+0x6a>
        putc(fd, c);
 646:	85ca                	mv	a1,s2
 648:	8556                	mv	a0,s5
 64a:	00000097          	auipc	ra,0x0
 64e:	ee2080e7          	jalr	-286(ra) # 52c <putc>
 652:	a019                	j	658 <vprintf+0x60>
    } else if(state == '%'){
 654:	01498f63          	beq	s3,s4,672 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 658:	0485                	addi	s1,s1,1
 65a:	fff4c903          	lbu	s2,-1(s1)
 65e:	14090d63          	beqz	s2,7b8 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 662:	0009079b          	sext.w	a5,s2
    if(state == 0){
 666:	fe0997e3          	bnez	s3,654 <vprintf+0x5c>
      if(c == '%'){
 66a:	fd479ee3          	bne	a5,s4,646 <vprintf+0x4e>
        state = '%';
 66e:	89be                	mv	s3,a5
 670:	b7e5                	j	658 <vprintf+0x60>
      if(c == 'd'){
 672:	05878063          	beq	a5,s8,6b2 <vprintf+0xba>
      } else if(c == 'l') {
 676:	05978c63          	beq	a5,s9,6ce <vprintf+0xd6>
      } else if(c == 'x') {
 67a:	07a78863          	beq	a5,s10,6ea <vprintf+0xf2>
      } else if(c == 'p') {
 67e:	09b78463          	beq	a5,s11,706 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 682:	07300713          	li	a4,115
 686:	0ce78663          	beq	a5,a4,752 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 68a:	06300713          	li	a4,99
 68e:	0ee78e63          	beq	a5,a4,78a <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 692:	11478863          	beq	a5,s4,7a2 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 696:	85d2                	mv	a1,s4
 698:	8556                	mv	a0,s5
 69a:	00000097          	auipc	ra,0x0
 69e:	e92080e7          	jalr	-366(ra) # 52c <putc>
        putc(fd, c);
 6a2:	85ca                	mv	a1,s2
 6a4:	8556                	mv	a0,s5
 6a6:	00000097          	auipc	ra,0x0
 6aa:	e86080e7          	jalr	-378(ra) # 52c <putc>
      }
      state = 0;
 6ae:	4981                	li	s3,0
 6b0:	b765                	j	658 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 6b2:	008b0913          	addi	s2,s6,8
 6b6:	4685                	li	a3,1
 6b8:	4629                	li	a2,10
 6ba:	000b2583          	lw	a1,0(s6)
 6be:	8556                	mv	a0,s5
 6c0:	00000097          	auipc	ra,0x0
 6c4:	e8e080e7          	jalr	-370(ra) # 54e <printint>
 6c8:	8b4a                	mv	s6,s2
      state = 0;
 6ca:	4981                	li	s3,0
 6cc:	b771                	j	658 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 6ce:	008b0913          	addi	s2,s6,8
 6d2:	4681                	li	a3,0
 6d4:	4629                	li	a2,10
 6d6:	000b2583          	lw	a1,0(s6)
 6da:	8556                	mv	a0,s5
 6dc:	00000097          	auipc	ra,0x0
 6e0:	e72080e7          	jalr	-398(ra) # 54e <printint>
 6e4:	8b4a                	mv	s6,s2
      state = 0;
 6e6:	4981                	li	s3,0
 6e8:	bf85                	j	658 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 6ea:	008b0913          	addi	s2,s6,8
 6ee:	4681                	li	a3,0
 6f0:	4641                	li	a2,16
 6f2:	000b2583          	lw	a1,0(s6)
 6f6:	8556                	mv	a0,s5
 6f8:	00000097          	auipc	ra,0x0
 6fc:	e56080e7          	jalr	-426(ra) # 54e <printint>
 700:	8b4a                	mv	s6,s2
      state = 0;
 702:	4981                	li	s3,0
 704:	bf91                	j	658 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 706:	008b0793          	addi	a5,s6,8
 70a:	f8f43423          	sd	a5,-120(s0)
 70e:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 712:	03000593          	li	a1,48
 716:	8556                	mv	a0,s5
 718:	00000097          	auipc	ra,0x0
 71c:	e14080e7          	jalr	-492(ra) # 52c <putc>
  putc(fd, 'x');
 720:	85ea                	mv	a1,s10
 722:	8556                	mv	a0,s5
 724:	00000097          	auipc	ra,0x0
 728:	e08080e7          	jalr	-504(ra) # 52c <putc>
 72c:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 72e:	03c9d793          	srli	a5,s3,0x3c
 732:	97de                	add	a5,a5,s7
 734:	0007c583          	lbu	a1,0(a5)
 738:	8556                	mv	a0,s5
 73a:	00000097          	auipc	ra,0x0
 73e:	df2080e7          	jalr	-526(ra) # 52c <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 742:	0992                	slli	s3,s3,0x4
 744:	397d                	addiw	s2,s2,-1
 746:	fe0914e3          	bnez	s2,72e <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 74a:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 74e:	4981                	li	s3,0
 750:	b721                	j	658 <vprintf+0x60>
        s = va_arg(ap, char*);
 752:	008b0993          	addi	s3,s6,8
 756:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 75a:	02090163          	beqz	s2,77c <vprintf+0x184>
        while(*s != 0){
 75e:	00094583          	lbu	a1,0(s2)
 762:	c9a1                	beqz	a1,7b2 <vprintf+0x1ba>
          putc(fd, *s);
 764:	8556                	mv	a0,s5
 766:	00000097          	auipc	ra,0x0
 76a:	dc6080e7          	jalr	-570(ra) # 52c <putc>
          s++;
 76e:	0905                	addi	s2,s2,1
        while(*s != 0){
 770:	00094583          	lbu	a1,0(s2)
 774:	f9e5                	bnez	a1,764 <vprintf+0x16c>
        s = va_arg(ap, char*);
 776:	8b4e                	mv	s6,s3
      state = 0;
 778:	4981                	li	s3,0
 77a:	bdf9                	j	658 <vprintf+0x60>
          s = "(null)";
 77c:	00000917          	auipc	s2,0x0
 780:	3e490913          	addi	s2,s2,996 # b60 <ustack_free+0x144>
        while(*s != 0){
 784:	02800593          	li	a1,40
 788:	bff1                	j	764 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 78a:	008b0913          	addi	s2,s6,8
 78e:	000b4583          	lbu	a1,0(s6)
 792:	8556                	mv	a0,s5
 794:	00000097          	auipc	ra,0x0
 798:	d98080e7          	jalr	-616(ra) # 52c <putc>
 79c:	8b4a                	mv	s6,s2
      state = 0;
 79e:	4981                	li	s3,0
 7a0:	bd65                	j	658 <vprintf+0x60>
        putc(fd, c);
 7a2:	85d2                	mv	a1,s4
 7a4:	8556                	mv	a0,s5
 7a6:	00000097          	auipc	ra,0x0
 7aa:	d86080e7          	jalr	-634(ra) # 52c <putc>
      state = 0;
 7ae:	4981                	li	s3,0
 7b0:	b565                	j	658 <vprintf+0x60>
        s = va_arg(ap, char*);
 7b2:	8b4e                	mv	s6,s3
      state = 0;
 7b4:	4981                	li	s3,0
 7b6:	b54d                	j	658 <vprintf+0x60>
    }
  }
}
 7b8:	70e6                	ld	ra,120(sp)
 7ba:	7446                	ld	s0,112(sp)
 7bc:	74a6                	ld	s1,104(sp)
 7be:	7906                	ld	s2,96(sp)
 7c0:	69e6                	ld	s3,88(sp)
 7c2:	6a46                	ld	s4,80(sp)
 7c4:	6aa6                	ld	s5,72(sp)
 7c6:	6b06                	ld	s6,64(sp)
 7c8:	7be2                	ld	s7,56(sp)
 7ca:	7c42                	ld	s8,48(sp)
 7cc:	7ca2                	ld	s9,40(sp)
 7ce:	7d02                	ld	s10,32(sp)
 7d0:	6de2                	ld	s11,24(sp)
 7d2:	6109                	addi	sp,sp,128
 7d4:	8082                	ret

00000000000007d6 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 7d6:	715d                	addi	sp,sp,-80
 7d8:	ec06                	sd	ra,24(sp)
 7da:	e822                	sd	s0,16(sp)
 7dc:	1000                	addi	s0,sp,32
 7de:	e010                	sd	a2,0(s0)
 7e0:	e414                	sd	a3,8(s0)
 7e2:	e818                	sd	a4,16(s0)
 7e4:	ec1c                	sd	a5,24(s0)
 7e6:	03043023          	sd	a6,32(s0)
 7ea:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 7ee:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 7f2:	8622                	mv	a2,s0
 7f4:	00000097          	auipc	ra,0x0
 7f8:	e04080e7          	jalr	-508(ra) # 5f8 <vprintf>
}
 7fc:	60e2                	ld	ra,24(sp)
 7fe:	6442                	ld	s0,16(sp)
 800:	6161                	addi	sp,sp,80
 802:	8082                	ret

0000000000000804 <printf>:

void
printf(const char *fmt, ...)
{
 804:	711d                	addi	sp,sp,-96
 806:	ec06                	sd	ra,24(sp)
 808:	e822                	sd	s0,16(sp)
 80a:	1000                	addi	s0,sp,32
 80c:	e40c                	sd	a1,8(s0)
 80e:	e810                	sd	a2,16(s0)
 810:	ec14                	sd	a3,24(s0)
 812:	f018                	sd	a4,32(s0)
 814:	f41c                	sd	a5,40(s0)
 816:	03043823          	sd	a6,48(s0)
 81a:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 81e:	00840613          	addi	a2,s0,8
 822:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 826:	85aa                	mv	a1,a0
 828:	4505                	li	a0,1
 82a:	00000097          	auipc	ra,0x0
 82e:	dce080e7          	jalr	-562(ra) # 5f8 <vprintf>
}
 832:	60e2                	ld	ra,24(sp)
 834:	6442                	ld	s0,16(sp)
 836:	6125                	addi	sp,sp,96
 838:	8082                	ret

000000000000083a <free>:

static Header base;
static Header *freep; // free blocks in memory

void free(void *ap)
{
 83a:	1141                	addi	sp,sp,-16
 83c:	e422                	sd	s0,8(sp)
 83e:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header *)ap - 1;
 840:	ff050693          	addi	a3,a0,-16
  for (p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 844:	00000797          	auipc	a5,0x0
 848:	7bc7b783          	ld	a5,1980(a5) # 1000 <freep>
 84c:	a805                	j	87c <free+0x42>
    if (p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  // merge previos to me
  if (bp + bp->s.size == p->s.ptr)
  {
    bp->s.size += p->s.ptr->s.size;
 84e:	4618                	lw	a4,8(a2)
 850:	9db9                	addw	a1,a1,a4
 852:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 856:	6398                	ld	a4,0(a5)
 858:	6318                	ld	a4,0(a4)
 85a:	fee53823          	sd	a4,-16(a0)
 85e:	a091                	j	8a2 <free+0x68>
  else
    bp->s.ptr = p->s.ptr;
  // merge next to me
  if (p + p->s.size == bp)
  {
    p->s.size += bp->s.size;
 860:	ff852703          	lw	a4,-8(a0)
 864:	9e39                	addw	a2,a2,a4
 866:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 868:	ff053703          	ld	a4,-16(a0)
 86c:	e398                	sd	a4,0(a5)
 86e:	a099                	j	8b4 <free+0x7a>
    if (p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 870:	6398                	ld	a4,0(a5)
 872:	00e7e463          	bltu	a5,a4,87a <free+0x40>
 876:	00e6ea63          	bltu	a3,a4,88a <free+0x50>
{
 87a:	87ba                	mv	a5,a4
  for (p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 87c:	fed7fae3          	bgeu	a5,a3,870 <free+0x36>
 880:	6398                	ld	a4,0(a5)
 882:	00e6e463          	bltu	a3,a4,88a <free+0x50>
    if (p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 886:	fee7eae3          	bltu	a5,a4,87a <free+0x40>
  if (bp + bp->s.size == p->s.ptr)
 88a:	ff852583          	lw	a1,-8(a0)
 88e:	6390                	ld	a2,0(a5)
 890:	02059713          	slli	a4,a1,0x20
 894:	9301                	srli	a4,a4,0x20
 896:	0712                	slli	a4,a4,0x4
 898:	9736                	add	a4,a4,a3
 89a:	fae60ae3          	beq	a2,a4,84e <free+0x14>
    bp->s.ptr = p->s.ptr;
 89e:	fec53823          	sd	a2,-16(a0)
  if (p + p->s.size == bp)
 8a2:	4790                	lw	a2,8(a5)
 8a4:	02061713          	slli	a4,a2,0x20
 8a8:	9301                	srli	a4,a4,0x20
 8aa:	0712                	slli	a4,a4,0x4
 8ac:	973e                	add	a4,a4,a5
 8ae:	fae689e3          	beq	a3,a4,860 <free+0x26>
  }
  else
    p->s.ptr = bp;
 8b2:	e394                	sd	a3,0(a5)
  // update the free list
  freep = p;
 8b4:	00000717          	auipc	a4,0x0
 8b8:	74f73623          	sd	a5,1868(a4) # 1000 <freep>
}
 8bc:	6422                	ld	s0,8(sp)
 8be:	0141                	addi	sp,sp,16
 8c0:	8082                	ret

00000000000008c2 <malloc>:
  return freep;
}

void *
malloc(uint nbytes)
{
 8c2:	7139                	addi	sp,sp,-64
 8c4:	fc06                	sd	ra,56(sp)
 8c6:	f822                	sd	s0,48(sp)
 8c8:	f426                	sd	s1,40(sp)
 8ca:	f04a                	sd	s2,32(sp)
 8cc:	ec4e                	sd	s3,24(sp)
 8ce:	e852                	sd	s4,16(sp)
 8d0:	e456                	sd	s5,8(sp)
 8d2:	e05a                	sd	s6,0(sp)
 8d4:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1) / sizeof(Header) + 1;
 8d6:	02051493          	slli	s1,a0,0x20
 8da:	9081                	srli	s1,s1,0x20
 8dc:	04bd                	addi	s1,s1,15
 8de:	8091                	srli	s1,s1,0x4
 8e0:	0014899b          	addiw	s3,s1,1
 8e4:	0485                	addi	s1,s1,1
  if ((prevp = freep) == 0)
 8e6:	00000517          	auipc	a0,0x0
 8ea:	71a53503          	ld	a0,1818(a0) # 1000 <freep>
 8ee:	c515                	beqz	a0,91a <malloc+0x58>
  {
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for (p = prevp->s.ptr;; prevp = p, p = p->s.ptr)
 8f0:	611c                	ld	a5,0(a0)
  {
    if (p->s.size >= nunits)
 8f2:	4798                	lw	a4,8(a5)
 8f4:	02977f63          	bgeu	a4,s1,932 <malloc+0x70>
 8f8:	8a4e                	mv	s4,s3
 8fa:	0009871b          	sext.w	a4,s3
 8fe:	6685                	lui	a3,0x1
 900:	00d77363          	bgeu	a4,a3,906 <malloc+0x44>
 904:	6a05                	lui	s4,0x1
 906:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 90a:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void *)(p + 1);
    }
    if (p == freep)
 90e:	00000917          	auipc	s2,0x0
 912:	6f290913          	addi	s2,s2,1778 # 1000 <freep>
  if (p == (char *)-1)
 916:	5afd                	li	s5,-1
 918:	a88d                	j	98a <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 91a:	00000797          	auipc	a5,0x0
 91e:	70678793          	addi	a5,a5,1798 # 1020 <base>
 922:	00000717          	auipc	a4,0x0
 926:	6cf73f23          	sd	a5,1758(a4) # 1000 <freep>
 92a:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 92c:	0007a423          	sw	zero,8(a5)
    if (p->s.size >= nunits)
 930:	b7e1                	j	8f8 <malloc+0x36>
      if (p->s.size == nunits)
 932:	02e48b63          	beq	s1,a4,968 <malloc+0xa6>
        p->s.size -= nunits;
 936:	4137073b          	subw	a4,a4,s3
 93a:	c798                	sw	a4,8(a5)
        p += p->s.size;
 93c:	1702                	slli	a4,a4,0x20
 93e:	9301                	srli	a4,a4,0x20
 940:	0712                	slli	a4,a4,0x4
 942:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 944:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 948:	00000717          	auipc	a4,0x0
 94c:	6aa73c23          	sd	a0,1720(a4) # 1000 <freep>
      return (void *)(p + 1);
 950:	01078513          	addi	a0,a5,16
      if ((p = morecore(nunits)) == 0)
        return 0;
  }
}
 954:	70e2                	ld	ra,56(sp)
 956:	7442                	ld	s0,48(sp)
 958:	74a2                	ld	s1,40(sp)
 95a:	7902                	ld	s2,32(sp)
 95c:	69e2                	ld	s3,24(sp)
 95e:	6a42                	ld	s4,16(sp)
 960:	6aa2                	ld	s5,8(sp)
 962:	6b02                	ld	s6,0(sp)
 964:	6121                	addi	sp,sp,64
 966:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 968:	6398                	ld	a4,0(a5)
 96a:	e118                	sd	a4,0(a0)
 96c:	bff1                	j	948 <malloc+0x86>
  hp->s.size = nu;
 96e:	01652423          	sw	s6,8(a0)
  free((void *)(hp + 1));
 972:	0541                	addi	a0,a0,16
 974:	00000097          	auipc	ra,0x0
 978:	ec6080e7          	jalr	-314(ra) # 83a <free>
  return freep;
 97c:	00093503          	ld	a0,0(s2)
      if ((p = morecore(nunits)) == 0)
 980:	d971                	beqz	a0,954 <malloc+0x92>
  for (p = prevp->s.ptr;; prevp = p, p = p->s.ptr)
 982:	611c                	ld	a5,0(a0)
    if (p->s.size >= nunits)
 984:	4798                	lw	a4,8(a5)
 986:	fa9776e3          	bgeu	a4,s1,932 <malloc+0x70>
    if (p == freep)
 98a:	00093703          	ld	a4,0(s2)
 98e:	853e                	mv	a0,a5
 990:	fef719e3          	bne	a4,a5,982 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 994:	8552                	mv	a0,s4
 996:	00000097          	auipc	ra,0x0
 99a:	b7e080e7          	jalr	-1154(ra) # 514 <sbrk>
  if (p == (char *)-1)
 99e:	fd5518e3          	bne	a0,s5,96e <malloc+0xac>
        return 0;
 9a2:	4501                	li	a0,0
 9a4:	bf45                	j	954 <malloc+0x92>

00000000000009a6 <ustack_malloc>:
static void* base = 0;
static uint prevLen = 0;

void *ustack_malloc(uint len)
{
    if (len > 512)
 9a6:	20000793          	li	a5,512
 9aa:	00a7f463          	bgeu	a5,a0,9b2 <ustack_malloc+0xc>
    {
        return (void *)-1;
 9ae:	557d                	li	a0,-1
    if(base == 0){
        base = pointer;
    }
    top = pointer;
    return pointer;
}
 9b0:	8082                	ret
{
 9b2:	1101                	addi	sp,sp,-32
 9b4:	ec06                	sd	ra,24(sp)
 9b6:	e822                	sd	s0,16(sp)
 9b8:	e426                	sd	s1,8(sp)
 9ba:	e04a                	sd	s2,0(sp)
 9bc:	1000                	addi	s0,sp,32
 9be:	84aa                	mv	s1,a0
    void *pointerLen = (void *)sbrk(8);
 9c0:	4521                	li	a0,8
 9c2:	00000097          	auipc	ra,0x0
 9c6:	b52080e7          	jalr	-1198(ra) # 514 <sbrk>
    if (pointerLen == (void *)-1)
 9ca:	57fd                	li	a5,-1
 9cc:	02f50d63          	beq	a0,a5,a06 <ustack_malloc+0x60>
    *((uint*)pointerLen + 1) = len;
 9d0:	c144                	sw	s1,4(a0)
    *((uint*) pointerLen) = prevLen;
 9d2:	00000917          	auipc	s2,0x0
 9d6:	63690913          	addi	s2,s2,1590 # 1008 <prevLen>
 9da:	00092783          	lw	a5,0(s2)
 9de:	c11c                	sw	a5,0(a0)
    void *pointer = (void *)sbrk(len);
 9e0:	8526                	mv	a0,s1
 9e2:	00000097          	auipc	ra,0x0
 9e6:	b32080e7          	jalr	-1230(ra) # 514 <sbrk>
    prevLen = len;
 9ea:	00992023          	sw	s1,0(s2)
    if (pointer == (void *)-1)
 9ee:	57fd                	li	a5,-1
 9f0:	00f50b63          	beq	a0,a5,a06 <ustack_malloc+0x60>
    if(base == 0){
 9f4:	00000797          	auipc	a5,0x0
 9f8:	61c7b783          	ld	a5,1564(a5) # 1010 <base>
 9fc:	cb99                	beqz	a5,a12 <ustack_malloc+0x6c>
    top = pointer;
 9fe:	00000797          	auipc	a5,0x0
 a02:	60a7bd23          	sd	a0,1562(a5) # 1018 <top>
}
 a06:	60e2                	ld	ra,24(sp)
 a08:	6442                	ld	s0,16(sp)
 a0a:	64a2                	ld	s1,8(sp)
 a0c:	6902                	ld	s2,0(sp)
 a0e:	6105                	addi	sp,sp,32
 a10:	8082                	ret
        base = pointer;
 a12:	00000797          	auipc	a5,0x0
 a16:	5ea7bf23          	sd	a0,1534(a5) # 1010 <base>
 a1a:	b7d5                	j	9fe <ustack_malloc+0x58>

0000000000000a1c <ustack_free>:



int ustack_free(void)
{
 a1c:	7179                	addi	sp,sp,-48
 a1e:	f406                	sd	ra,40(sp)
 a20:	f022                	sd	s0,32(sp)
 a22:	ec26                	sd	s1,24(sp)
 a24:	e84a                	sd	s2,16(sp)
 a26:	e44e                	sd	s3,8(sp)
 a28:	e052                	sd	s4,0(sp)
 a2a:	1800                	addi	s0,sp,48
    if(base == 0){
 a2c:	00000997          	auipc	s3,0x0
 a30:	5e49b983          	ld	s3,1508(s3) # 1010 <base>
 a34:	06098763          	beqz	s3,aa2 <ustack_free+0x86>
        return -1;
    }
    int isLast = 0;
    if(base == top){
 a38:	00000917          	auipc	s2,0x0
 a3c:	5e093903          	ld	s2,1504(s2) # 1018 <top>
        isLast = 1;
    }
    uint len = *((uint*)top-1);
 a40:	ffc92483          	lw	s1,-4(s2)
    uint prevLen = *((uint*)top-2);
 a44:	ff892a03          	lw	s4,-8(s2)
    void* newTop = (void*)sbrk(-len - 8);
 a48:	5561                	li	a0,-8
 a4a:	9d05                	subw	a0,a0,s1
 a4c:	00000097          	auipc	ra,0x0
 a50:	ac8080e7          	jalr	-1336(ra) # 514 <sbrk>
    if(newTop == (void*) -1){
 a54:	57fd                	li	a5,-1
 a56:	04f50863          	beq	a0,a5,aa6 <ustack_free+0x8a>
        return -1;
    }
    if(isLast == 1){
 a5a:	03298b63          	beq	s3,s2,a90 <ustack_free+0x74>
        top = 0;
        base = 0;
    } else {
        top = (void*)((char*)top - 8 - prevLen);
 a5e:	00000717          	auipc	a4,0x0
 a62:	5ba70713          	addi	a4,a4,1466 # 1018 <top>
 a66:	1a02                	slli	s4,s4,0x20
 a68:	020a5a13          	srli	s4,s4,0x20
 a6c:	57e1                	li	a5,-8
 a6e:	414787b3          	sub	a5,a5,s4
 a72:	00073a03          	ld	s4,0(a4)
 a76:	9a3e                	add	s4,s4,a5
 a78:	01473023          	sd	s4,0(a4)
    }
  
    return len;
 a7c:	0004851b          	sext.w	a0,s1
 a80:	70a2                	ld	ra,40(sp)
 a82:	7402                	ld	s0,32(sp)
 a84:	64e2                	ld	s1,24(sp)
 a86:	6942                	ld	s2,16(sp)
 a88:	69a2                	ld	s3,8(sp)
 a8a:	6a02                	ld	s4,0(sp)
 a8c:	6145                	addi	sp,sp,48
 a8e:	8082                	ret
        top = 0;
 a90:	00000797          	auipc	a5,0x0
 a94:	5807b423          	sd	zero,1416(a5) # 1018 <top>
        base = 0;
 a98:	00000797          	auipc	a5,0x0
 a9c:	5607bc23          	sd	zero,1400(a5) # 1010 <base>
 aa0:	bff1                	j	a7c <ustack_free+0x60>
        return -1;
 aa2:	557d                	li	a0,-1
 aa4:	bff1                	j	a80 <ustack_free+0x64>
        return -1;
 aa6:	557d                	li	a0,-1
 aa8:	bfe1                	j	a80 <ustack_free+0x64>
