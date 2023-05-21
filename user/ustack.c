#include "ustack.h"
#include "user/user.h"
#include "riscv.h"

static Header *top = 0;
static int counter = -1;

void *ustack_malloc(uint len)
{
    if (len > 512)
    {
        return (void *)-1;
    }
    if (counter >= PGSIZE)
    {
        return (void *)-1;
    }

    uint nUnits = (len + sizeof(Header) - 1) / sizeof(Header) + 1;
    Header *pointer = (Header *)sbrk(nUnits * sizeof(Header));
    // Header *pointer = (Header *)sbrk(len);

    if (pointer == (Header *)-1)
    {
        return (void *)-1;
    }
    pointer->s.size = nUnits;
    if (top == 0)
    {
        pointer->s.ptr = 0;
    }
    else
    {
        pointer->s.ptr = top;
    }
    counter++;
    top = pointer;
    return (void *)(pointer + 1);
}

int ustack_free(void)
{
    Header *p;
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
    return ret;
}