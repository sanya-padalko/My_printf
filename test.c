#include <stdio.h>

extern void my_printf(const char *format, ...);

int main() {
    my_printf("Hehe, char:%c, %d, %d, %c, %%, %x, %o, %b, %d!\n", 48, 49, 50, 51, 52, 53, 54, 55);
    my_printf("Hex: %x!\n", 0xfaa);
    my_printf("Oct: %o!\n", 0xfaa);
    my_printf("Bin: %b!\n", 0xfaa);
    my_printf("Dec: %d!\n", 0xfaa);
    my_printf("String: _%s!\n", "goal goal !!! _z");
}