#include <stdio.h>

extern void my_printf(const char *format, ...);

int main() {
    my_printf("Hehe, char:%c, %%!\n", 68);
    my_printf("Hex: %x!\n", 0xfaa);
    my_printf("Oct: %o!\n", 0xfaa);
    my_printf("Bin: %b!\n", 0xfaa);
    my_printf("Dec: %d!\n", 0xfaa);
    my_printf("String: %s!\n", "goida goida _z");
    // my_printf("Percent sign: %%\n");
    // my_printf("Single char: %c\n", 'A');
    // my_printf("Two chars: %c %c\n", 'X', 'Y');
    // my_printf("Two chars and percent: %c %% %c\n", '1', '2');
    // my_printf("Char from number: %c\n", 33);
    // my_printf("Hex: %x\n", 0xdeadc0ff);
    // my_printf("Bin: %b\n", 12);
    // my_printf("Oct: %o\n", 0xF000000C); // 11 110 000 000 000 000 000 000 000 001 100  
    // my_printf("Dec: %d\n", -2147483648);
    // my_printf("Dec: %b\n", -2147483648);
    // my_printf("String: %s\n", "goida");
}