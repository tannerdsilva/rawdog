#include <sys/types.h>

/* a structure that represents a raw byte representation */
typedef struct RAW_val {
	size_t		 mv_size;	/**< size of the data item */
	void		*mv_data;	/**< address of the data item */
} RAW_val;