#include "CRAW.h"
#include <errno.h>

/// returns the system error number.
int geterrno() {
	return errno;
}