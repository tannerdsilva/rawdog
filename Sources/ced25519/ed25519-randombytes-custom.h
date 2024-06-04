#ifndef ED25519_TEST

#ifndef ED25519_FN
#define ED25519_FN(x) ed25519_ ## x

#include <stdlib.h>

void ED25519_FN(ed25519_randombytes_unsafe)(void *p, size_t len);

#endif // ED25519_FN

#endif // ED25519_TEST