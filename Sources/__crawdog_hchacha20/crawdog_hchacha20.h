// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
// copyright (c) frank denis 2013-2024. all rights reserved.
#ifndef __CRAWDOG_HCHACHA20_H
#define __CRAWDOG_HCHACHA20_H

#include <stddef.h>

#define __CRAWDOG_HCHACHA20_OUTPUTBYTES 32U
size_t crypto_core_hchacha20_outputbytes(void);

#define __CRAWDOG_HCHACHA20_INPUTBYTES 16U
size_t crypto_core_hchacha20_inputbytes(void);

#define __CRAWDOG_HCHACHA20_KEYBYTES 32U
size_t crypto_core_hchacha20_keybytes(void);

#define __CRAWDOG_HCHACHA20_CONSTBYTES 16U
size_t crypto_core_hchacha20_constbytes(void);

int crypto_core_hchacha20(unsigned char *out, const unsigned char *in,
                          const unsigned char *k, const unsigned char *c)
            __attribute__ ((nonnull(1, 2, 3)));


#endif // __CRAWDOG_HCHACHA20_H
