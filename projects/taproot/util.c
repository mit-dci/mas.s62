#include <ctype.h>
#include <string.h>
#include <stdio.h>

size_t hex2bin(const char *hex, unsigned char *out) {
    static char HEXDIGITS[] = "0123456789abcdef";

    size_t i = 0;
    while (hex[i] && hex[i + 1]) {
        if (isalnum(hex[i]) && isalnum(hex[i + 1])) {
            const char *d1 = strchr(HEXDIGITS, tolower(hex[i])); 
            const char *d2 = strchr(HEXDIGITS, tolower(hex[i + 1])); 
            if (d1 == NULL || d2 == NULL) {
                return 0;
            }
            out[i / 2] = ((d1 - HEXDIGITS) << 4) + (d2 - HEXDIGITS);
        } else {
            return 0;
        }
        i += 2;
    }

    /* odd # of digits */
    if (hex[i]) {
        return 0;
    }
    return i / 2;
}

void bin2hex(char *out, const unsigned char *bin, size_t n) {
    static char HEXDIGITS[] = "0123456789abcdef";

    size_t i;
    for (i = 0; i < n; i++) {
        out[2*i] = HEXDIGITS[bin[i] >> 4];
        out[2*i + 1] = HEXDIGITS[bin[i] & 0xf];
    }
    out[2*i] = 0;
}
