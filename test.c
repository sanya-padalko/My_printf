#include <stdio.h>

extern void my_printf(const char *format, ...);

int main() {
    my_printf("%%%d\n%d %s %x %d%%%c%b\n", 5111111, -1, "love", 3802, 100, 33, 126);
}