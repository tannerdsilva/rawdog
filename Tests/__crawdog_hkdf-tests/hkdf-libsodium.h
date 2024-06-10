#ifndef LIBSODIUM_HKDF_REF_H
#define LIBSODIUM_HKDF_REF_H

#include <stdlib.h>

int _libsodiumREF_hkdf_extract(const unsigned char *salt, size_t salt_len, const unsigned char *ikm, size_t ikm_len, unsigned char *prk);
int _libsodiumREF_hkdf_expand(const unsigned char *prk, const unsigned char *info, size_t info_len, unsigned char *okm, size_t okm_len);

#endif // LIBSODIUM_HKDF_REF_H