// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
// copyright (c) 2015 mehdi sotoodeh
#ifndef __CRAWDOG_EXTERNAL_CALLS_H
#define __CRAWDOG_EXTERNAL_CALLS_H

#include <memory.h>
#include <stdlib.h>

#define	mem_alloc(size)				malloc(size)
#define	mem_free(addr)				free(addr)
#define mem_clear(addr,size)		memset(addr,0,size)
#define mem_fill(addr,data,size)	memset(addr,data,size)

#endif  // __CRAWDOG_EXTERNAL_CALLS_H
