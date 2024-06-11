// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
#ifndef _CRYPT_BLOWFISH_H
#define _CRYPT_BLOWFISH_H

extern int ___crawdog_crypt_output_magic(const char *setting, char *output, int size);
extern char *___crawdog_crypt_blowfish_rn(const char *key, const char *setting,
	char *output, int size);
extern char *___crawdog_crypt_gensalt_blowfish_rn(const char *prefix,
	unsigned long count,
	const char *input, int size, char *output, int output_size);

#endif