#include <stdio.h>
#include <stdint.h>

typedef struct {
    intptr_t val;
} handle;

int main(void)
{
    handle h;
    printf("&h=%p &h[0]=%p\n",&h,&(h.val));
    return 0;
}
