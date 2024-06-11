// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
#if !defined(__CRAWDOG_ARGON2_NO_THREADS)

#include "crawdog_thread.h"
#if defined(_WIN32)
#include <windows.h>
#endif

int __crawdog_argon2_thread_create(__crawdog_argon2_thread_handle_t *handle,
                         __crawdog_argon2_thread_func_t func, void *args) {
    if (NULL == handle || func == NULL) {
        return -1;
    }
#if defined(_WIN32)
    *handle = _beginthreadex(NULL, 0, func, args, 0, NULL);
    return *handle != 0 ? 0 : -1;
#else
    return pthread_create(handle, NULL, func, args);
#endif
}

int __crawdog_argon2_thread_join(__crawdog_argon2_thread_handle_t handle) {
#if defined(_WIN32)
    if (WaitForSingleObject((HANDLE)handle, INFINITE) == WAIT_OBJECT_0) {
        return CloseHandle((HANDLE)handle) != 0 ? 0 : -1;
    }
    return -1;
#else
    return pthread_join(handle, NULL);
#endif
}

void __crawdog_argon2_thread_exit(void) {
#if defined(_WIN32)
    _endthreadex(0);
#else
    pthread_exit(NULL);
#endif
}

#endif /* __CRAWDOG_ARGON2_NO_THREADS */
