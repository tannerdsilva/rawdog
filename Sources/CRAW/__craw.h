// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.

#ifndef __CRAW_H
#define __CRAW_H

#include <string.h>
#include <stdint.h>
#include <stdlib.h>
#include <fcntl.h>
#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
#include <errno.h>
#include <stdbool.h>

int __craw_get_system_errno();

// capture entropy from the system. maximum of 256 bytes.
// returns 0 on success, errno on failure.
int __craw_get_entropy_bytes(uint8_t *buf, const size_t len);

// secure zeroing function
void __craw_secure_zero_bytes(uint8_t *ptr, size_t size);

// used to ensure that memory has been zeroed
uint64_t __craw_assert_secure_zero_bytes(const uint8_t *volatile ptr, size_t size);

#endif // __CRAW_H