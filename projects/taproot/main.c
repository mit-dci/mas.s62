#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stddef.h>
#include <secp256k1.h>
#include <assert.h>
#include <ctype.h>

#include "hash.h"
#include "util.h"

void taproot(char *argv[]) {
    secp256k1_context *ctx;
    unsigned char sk[32];

    // create secp256k1 context
    ctx = secp256k1_context_create(SECP256K1_CONTEXT_SIGN);

    // read in secret key j
    printf("j: %s\n", argv[1]);
    if (strlen(argv[1]) != 64 || !hex2bin(argv[1], sk)) {
        fprintf(stderr, "secret key %s needs to be a 64-char hex string\n", argv[1]);
        return;
    }

    // compute public key J for secret key j
    secp256k1_pubkey pk;
    unsigned char pk_bytes[33]; // compressed
    size_t pk_length = sizeof(pk_bytes);
    if (secp256k1_ec_pubkey_create(ctx, &pk, sk) == 1) {
        secp256k1_ec_pubkey_serialize(ctx, pk_bytes, &pk_length, &pk, SECP256K1_EC_COMPRESSED);

        // convert pubkey to human-readable hex form
        char pk_hex[67];
        bin2hex(pk_hex, pk_bytes, pk_length);
        printf("J: %s\n", pk_hex);
    } else {
        fprintf(stderr, "Unable to compute pubkey from privkey\n");
        return;
    }

    // read in script z, TODO: support human-readable script conversion
    unsigned char *script;
    size_t script_length = strlen(argv[2]);
    printf("script: %s\n", argv[2]);
    script = malloc(script_length);
    if (!hex2bin(argv[2], script)) {
        fprintf(stderr, "invalid script, must be in hex\n");
        return;
    }

    // initialize hasher
    secp256k1_sha256_t sha256;
    secp256k1_sha256_initialize(&sha256);
    unsigned char digest[32];

    // compute sha256(J || script) to derive new privkey c
    secp256k1_sha256_write(&sha256, pk_bytes, pk_length);
    secp256k1_sha256_write(&sha256, script, script_length);
    secp256k1_sha256_finalize(&sha256, digest);

    // tweak the private key with the newly calculated digest: c = j + h(J, z)
    if (secp256k1_ec_privkey_tweak_add(ctx, sk, digest) == 0) {
        fprintf(stderr, "tweaking private key failed");
        return;
    }
    char sk_hex[32];
    bin2hex(sk_hex, sk, 32);
    printf("c: %s\n", sk_hex);

    // compute C = J + h(J, z)G 
    secp256k1_pubkey tweaked_pk;
    unsigned char tweaked_pk_bytes[33]; // compressed
    size_t tweaked_pk_length = sizeof(tweaked_pk_bytes);
    if (secp256k1_ec_pubkey_create(ctx, &tweaked_pk, sk) == 1) {
        secp256k1_ec_pubkey_serialize(ctx, tweaked_pk_bytes, &tweaked_pk_length, &tweaked_pk, SECP256K1_EC_COMPRESSED);

        // convert tweaked pubkey to human-readable hex form
        char tweaked_pk_hex[67];
        bin2hex(tweaked_pk_hex, tweaked_pk_bytes, tweaked_pk_length);
        printf("C: %s\n", tweaked_pk_hex);
    } else {
        fprintf(stderr, "Unable to compute tweaked pubkey from tweaked privkey\n");
        return;
    }

    // TODO add support for converting to btc address

    free(script);
    secp256k1_context_destroy(ctx);
}

void print_usage() {
    fprintf(stderr, "Invalid arguments, should be: ./taproot <secret key> <script>\n");
}

int main(int argc, char *argv[]) {
    if (argc == 3) {
        taproot(argv);
        return 0;
    }

    print_usage();
    return 1;
}
