// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
// #include <sodium.h>
#include "hkdf-libsodium.h"
#include <string.h>
#include <stdlib.h>

int _libsodiumREF_hkdf_extract(unsigned char *prk, const unsigned char *salt, size_t salt_len, const unsigned char *ikm, size_t ikm_len) {
    if (salt == NULL) {
        // Use a zeroed salt if none is provided
        unsigned char zero_salt[crypto_auth_hmacsha512_BYTES] = {0};
        salt = zero_salt;
        salt_len = sizeof(zero_salt);
    }

    // Using HMAC-SHA-512 for the extraction phase
    crypto_auth_hmacsha512_state state;
    crypto_auth_hmacsha512_init(&state, salt, salt_len);
    crypto_auth_hmacsha512_update(&state, ikm, ikm_len);
    crypto_auth_hmacsha512_final(&state, prk);

    return 0; // Return 0 on success
}

int _libsodiumREF_hkdf_expand(unsigned char *out, const unsigned char *prk, size_t prk_len, const unsigned char *info, size_t info_len, size_t out_len) {
    unsigned char t[crypto_auth_hmacsha512_BYTES];
    size_t t_len = 0;
    size_t n = (out_len + crypto_auth_hmacsha512_BYTES - 1) / crypto_auth_hmacsha512_BYTES;
    size_t rem_len = out_len;

    for (unsigned int i = 0; i < n; i++) {
        crypto_auth_hmacsha512_state state;
        crypto_auth_hmacsha512_init(&state, prk, prk_len);
        if (i > 0) {
            crypto_auth_hmacsha512_update(&state, t, t_len);
        }
        crypto_auth_hmacsha512_update(&state, info, info_len);
        unsigned char c = i + 1;
        crypto_auth_hmacsha512_update(&state, &c, 1);
        crypto_auth_hmacsha512_final(&state, t);

        memcpy(out, t, (rem_len < sizeof(t) ? rem_len : sizeof(t)));
        out += sizeof(t);
        rem_len -= sizeof(t);
        t_len = sizeof(t);
    }

    return 0; // Return 0 on success
}