// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
#include <sodium.h>
#include <stdlib.h>
#include <string.h>

int _libsodiumREF_hkdf_extract(const unsigned char *salt, size_t salt_len, const unsigned char *ikm, size_t ikm_len, unsigned char *prk) {
    return crypto_auth_hmacsha256(prk, ikm, ikm_len, salt);
}

int _libsodiumREF_hkdf_expand(const unsigned char *prk, const unsigned char *info, size_t info_len, unsigned char *okm, size_t okm_len) {
    unsigned char t[crypto_auth_hmacsha256_BYTES];
    unsigned char *prev = NULL;
    int i;
    size_t len = 0;
    for (i = 1; len < okm_len; i++) {
        crypto_auth_hmacsha256_state st;
        crypto_auth_hmacsha256_init(&st, prk, crypto_auth_hmacsha256_KEYBYTES);
        if (prev != NULL) {
            crypto_auth_hmacsha256_update(&st, prev, crypto_auth_hmacsha256_BYTES);
        }
        crypto_auth_hmacsha256_update(&st, info, info_len);
        unsigned char c = i;
        crypto_auth_hmacsha256_update(&st, &c, 1);
        crypto_auth_hmacsha256_final(&st, t);
        size_t copy_len = (okm_len - len < crypto_auth_hmacsha256_BYTES) ? okm_len - len : crypto_auth_hmacsha256_BYTES;
        memcpy(okm + len, t, copy_len);
        len += copy_len;
        prev = t;
    }
    return 0;
}