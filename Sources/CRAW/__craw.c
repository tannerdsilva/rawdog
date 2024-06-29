#include "__craw.h"
#include <stdint.h>

int __craw_get_system_errno() {
	return errno;
}

#ifdef __APPLE__
#include <Security/SecRandom.h>
#endif

#if defined(__linux__) || defined(__unix__)
#include <unistd.h>
#include <fcntl.h>
#include <sys/syscall.h>
#endif

#ifdef _WIN32
#include <ntsecapi.h>
#endif

int __craw_get_entropy_bytes(uint8_t *out, const size_t len) {
	if (len > 256) {
		return -1; // limit the length to avoid large requests
	}

	#ifdef __APPLE__
	// use SecRandomCopyBytes on Apple platforms
	return SecRandomCopyBytes(kSecRandomDefault, len, out) == errSecSuccess ? 0 : errno;
	#endif

	#ifdef _WIN32
	// use RtlGenRandom on Windows platforms
	return RtlGenRandom(out, len) ? 0 : -1;
	#endif

	#if defined(__OpenBSD__)
	// use getentropy on OpenBSD
	return getentropy(out, len) == 0 ? 0 : errno;
	#endif

	#if defined(__linux__)
	// use getrandom syscall on Linux
	if (syscall(SYS_getrandom, out, len, 0) == (ssize_t)len) {
		return 0;
	} else {
		return errno;
	}
	#endif

	#if defined(__unix__) && !defined(__OpenBSD__) && !defined(__APPLE__)
	// use /dev/urandom on other UNIX-like systems
	int fd = open("/dev/urandom", O_RDONLY);
	if (fd < 0) {
		return -1;
	}

	ssize_t ret = 0;
	size_t i;
	for (i = 0; i < len; i += ret) {
		ret = read(fd, out + i, len - i);
		if (ret <= 0) {
			if (errno != 0) {
				ret = -errno;
			} else {
				ret = -EIO;
			}
			break;
		}
	}
	close(fd);
	return i < len ? ret : 0;
	#endif
}

void __craw_secure_zero_bytes(uint8_t *ptr, size_t size) {
    volatile uint8_t *volatile p = ptr;
    while (size--) {
        *p++ = 0;
    }
}

uint64_t __craw_assert_secure_zero_bytes(const uint8_t *volatile ptr, size_t size) {
    const volatile uint8_t *volatile p = (const volatile uint8_t *)ptr;
	volatile uint64_t sum = 0;
    for (size_t i = 0; i < size; i++) {
		sum |= p[i];
    }
	return sum;
}