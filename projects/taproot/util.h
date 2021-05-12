
/** Convert a hex-encoded byte array into a native one. Return the length read. */
size_t hex2bin(const char *hex, unsigned char *out);

/** Encode a byte array into a null-terminated lowercase hex string */
void bin2hex(char *out, const unsigned char *bin, size_t n);
