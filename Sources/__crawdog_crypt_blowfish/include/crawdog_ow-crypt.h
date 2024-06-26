// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
#ifndef _OW_CRYPT_H
#define _OW_CRYPT_H

#ifndef __GNUC__
#undef __const
#define __const const
#endif

#ifndef __SKIP_GNU
extern char *__crawdog_crypt(__const char *key, __const char *setting);
extern char *__crawdog_crypt_r(__const char *key, __const char *setting, void *data);
#endif

#ifndef __SKIP_OW
extern char *__crawdog_crypt_rn(__const char *key, __const char *setting,
	void *data, int size);
extern char *__crawdog_crypt_ra(__const char *key, __const char *setting,
	void **data, int *size);
extern char *__crawdog_crypt_gensalt(__const char *prefix, unsigned long count,
	__const char *input, int size);
extern char *__crawdog_crypt_gensalt_rn(__const char *prefix, unsigned long count,
	__const char *input, int size, char *output, int output_size);
extern char *__crawdog_crypt_gensalt_ra(__const char *prefix, unsigned long count,
	__const char *input, int size);
#endif

#endif