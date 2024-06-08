// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
#include "__craw.h"

#include <sys/random.h>

int __craw_get_system_errno() {
	return errno;
}

int __craw_get_entropy_bytes(uint8_t *out, const size_t len) {
	#ifndef _WIN32
	ssize_t ret = 0;
	size_t i;
	int fd;

	if (len > 256) {
		return -1;
	}

	#if defined(__OpenBSD__) || defined(__APPLE__) || (defined(__GLIBC__) && (__GLIBC__ > 2 || (__GLIBC__ == 2 && __GLIBC_MINOR__ >= 25)))
	if (getentropy(out, len) != 0) {
		return errno;
	} else {
		return 0;
	}
	#endif

	#if defined(__NR_getrandom) && defined(__linux__)
	if (syscall(__NR_getrandom, out, len, 0) != (ssize_t)len) {
		return errno;
	} else {
		return 0;
	}
	#endif

	fd = open("/dev/urandom", O_RDONLY);
	if (fd < 0) {
		return -1;
	}
	for (errno = 0, i = 0; i < len; i += ret, ret = 0) {
		ret = read(fd, out + i, len - i);
		if (ret <= 0) {
			ret = errno ? -errno : -EIO;
			break;
		}
	}
	close(fd);
	if (i < len) {
		return ret;
	} else {
		return 0;
	}
}
#else
#include <ntsecapi.h>
static inline bool __attribute__((__warn_unused_result__)) get_random_bytes(uint8_t *out, size_t len)
{
        return RtlGenRandom(out, len);
}
#endif