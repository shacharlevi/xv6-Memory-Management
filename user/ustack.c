#include "ustack.h"
#include "user/user.h"
#include "riscv.h"

static void *top = 0;
static void* base = 0;
static int counter = -1;
static uint prevLen = 0;
void *ustack_malloc(uint len)
{
    if (len > 512)
    {
        return (void *)-1;
    }
    /*if (counter >= PGSIZE)
    {
        return (void *)-1;
    }*/

    // uint nUnits = (len + sizeof(Header) - 1) / sizeof(Header) + 1;
    // Header *pointer = (Header *)sbrk(nUnits * sizeof(Header));
    void *pointerLen = (void *)sbrk(8);
    if (pointerLen == (void *)-1)
    {
        return (void *)-1;
    }
    *((uint*)pointerLen + 1) = len;
    *((uint*) pointerLen) = prevLen;
    void *pointer = (void *)sbrk(len);
    prevLen = len;
    if (pointer == (void *)-1)
    {
        return (void *)-1;
    }
    if(base == 0){
        base = pointer;
    }
    top = pointer;
    return pointer;
}

int ustack_free(void)
{
    if(base == 0){
        return -1;
    }
    int isLast = 0;
    if(base == top){
        isLast = 1;
    }
    uint len = *((uint*)top-1);
    uint prevLen = *((uint*)top-2);
    void* newTop = (void*)sbrk(-len - 8);
    if(newTop == (void*) -1){
        return -1;
    }
    if(isLast == 1){
        top = 0;
        base = 0;
    } else {
        top = (void*)((char*)newTop - prevLen);
    }
    /*Header *p;
    int ret;
    if (counter == -1)
    {
        return -1;
    }

    if (top == 0)
    { // if empty
        return -1;
    }
    p = top;
    ret = (p->s.size - 1) * sizeof(Header);
    if (top->s.ptr == 0)
    {
        top = 0;
    }
    else
    {
        top = p->s.ptr;
    }
    counter--;
    return ret;*/
}