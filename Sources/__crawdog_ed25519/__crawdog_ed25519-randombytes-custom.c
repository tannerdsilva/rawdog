// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
#include <sys/fcntl.h>
#ifndef ED25519_TEST

#include "__crawdog_ed25519-randombytes-custom.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

void ED25519_FN(randombytes_unsafe)(void *p, size_t len) {
	int f;
	size_t result;

	if (p == NULL || len == 0) {
		return; // handle invalid input
	}

	// open the /dev/urandom device
	f = open("/dev/urandom", O_RDONLY);
	if (f <= 0) {
		perror("Failed to open /dev/urandom");
		exit(EXIT_FAILURE); // exit if failed to open /dev/urandom
	}

    // read the bytes from the device
    result = read(f, p, len);
    if (result != len) {
        // this function expects to read len bytes, if it reads less than len bytes, it will zero out the buffer and exit
        memset(p, 0, len);
        perror("Failed to read enough random bytes");
        close(f);
        exit(EXIT_FAILURE);
    }
	// close the /dev/urandom device
    close(f);
}

#endif // ED25519_TEST