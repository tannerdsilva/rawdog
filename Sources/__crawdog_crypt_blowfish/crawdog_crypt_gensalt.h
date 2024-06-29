// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
#ifndef _CRYPT_GENSALT_H
#define _CRYPT_GENSALT_H

extern unsigned char ___crawdog_crypt_itoa64[];
extern char *___crawdog_crypt_gensalt_traditional_rn(const char *prefix,
	unsigned long count,
	const char *input, int size, char *output, int output_size);
extern char *___crawdog_crypt_gensalt_extended_rn(const char *prefix,
	unsigned long count,
	const char *input, int size, char *output, int output_size);
extern char *___crawdog_crypt_gensalt_md5_rn(const char *prefix, unsigned long count,
	const char *input, int size, char *output, int output_size);

#endif