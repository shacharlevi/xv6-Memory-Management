#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "user/ustack.h"
int
main(int argc, char *argv[])
{
    if(ustack_free() > 0){
        fprintf(2, "First free has failed\n");    
    }
    printf("%p\n", ustack_malloc(10));
    printf("%p\n", ustack_malloc(15));
    printf("%p\n", ustack_malloc(20));
    int val = ustack_free();
    if(val != 20){
        fprintf(2, "Val is equal to %d instead of 20\n", val);    
    }
    val = ustack_free();
    if(val != 15){
        fprintf(2, "Val is equal to %d instead of 15\n", val);    
    }
    val = ustack_free();
    if(val != 10){
        fprintf(2, "Val is equal to %d instead of 10\n", val);    
    }
    
    if(ustack_free() > 0){
        fprintf(2, "First free has failed\n");    
    }
    printf("%p\n", ustack_malloc(10));
    printf("%p\n", ustack_malloc(15));
    printf("%p\n", ustack_malloc(20));
    
    val = ustack_free();
    if(val != 20){
        fprintf(2, "Val is equal to %d instead of 20\n", val);    
    }
    val = ustack_free();
    if(val != 15){
        fprintf(2, "Val is equal to %d instead of 15\n", val);    
    }
    val = ustack_free();
    if(val != 10){
        fprintf(2, "Val is equal to %d instead of 10\n", val);    
    }
    
    if(ustack_free() > 0){
        fprintf(2, "First free has failed\n");    
    }
    fprintf(2, "Finished testing\n");
    exit(0);
}
