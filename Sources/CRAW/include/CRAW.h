#include <sys/types.h>
#include <string.h>

// pointer type.
typedef const void*_Nullable ptr_t;

// generic raw value type.
typedef struct rawval_t {
	uint64_t rawval_size;
	const ptr_t rawval_data;
} rawval_t;

// initialize a new rawval structure with a given uint64, const ptr_t
rawval_t rawval_init(uint64_t size, const ptr_t data) {
	rawval_t newVal = { size, data };
	return newVal;
}