#include <stdio.h>
#include <stdint.h>

typedef struct {
    intptr_t val;
} handle1;

typedef struct {
    intptr_t val;
} handle2;

void foo(handle1 h1, handle2 * h2)
{
    h2->val = h1.val;
}

int main(void)
{
    handle1 h1;
    handle2 h2;
    foo(h1,&h2);
    // THIS SHOULD FAIL
    foo(h2,&h1);
    return 0;
}
