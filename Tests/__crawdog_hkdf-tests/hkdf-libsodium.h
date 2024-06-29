#ifndef LIBSODIUM_HKDF_REF_H
#define LIBSODIUM_HKDF_REF_H

#include <stdlib.h>
#include <sodium.h>

int _libsodiumREF_hkdf_extract(unsigned char *prk, const unsigned char *salt, size_t salt_len, const unsigned char *ikm, size_t ikm_len);
int _libsodiumREF_hkdf_expand(unsigned char *out, const unsigned char *prk, size_t prk_len, const unsigned char *info, size_t info_len, size_t out_len);

#endif // LIBSODIUM_HKDF_REF_H