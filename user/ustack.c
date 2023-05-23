#include "ustack.h"
#include "user/user.h"

static void *top = 0;
static void* base = 0;
static uint prevLen = 0;

void *ustack_malloc(uint len)
{
    if (len > 512)
    {
        return (void *)-1;
    }
  
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
        top = (void*)((char*)top - 8 - prevLen);
    }
  
    return len;
}