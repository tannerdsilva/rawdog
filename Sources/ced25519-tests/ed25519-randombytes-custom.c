#ifndef ED25519_TEST

#include "ed25519-randombytes-custom.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void ED25519_FN(randombytes_unsafe)(void *p, size_t len) {
	FILE *f;
	size_t result;

	if (p == NULL || len == 0) {
		return; // handle invalid input
	}

	// open the /dev/urandom device
	f = fopen("/dev/urandom", "rb");
	if (f == NULL) {
		perror("Failed to open /dev/urandom");
		exit(EXIT_FAILURE); // exit if failed to open /dev/urandom
	}

    // read the bytes from the device
    result = fread(p, 1, len, f);
    if (result != len) {
        // this function expects to read len bytes, if it reads less than len bytes, it will zero out the buffer and exit
        memset(p, 0, len);
        perror("Failed to read enough random bytes");
        fclose(f);
        exit(EXIT_FAILURE);
    }
	// close the /dev/urandom device
    fclose(f);
}

#endif // ED25519_TEST