// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
#ifndef __CRAWDOG_ARGON2_THREAD_H
#define __CRAWDOG_ARGON2_THREAD_H

#if !defined(__CRAWDOG_ARGON2_NO_THREADS)

/*
        Here we implement an abstraction layer for the simpĺe requirements
        of the Argon2 code. We only require 3 primitives---thread creation,
        joining, and termination---so full emulation of the pthreads API
        is unwarranted. Currently we wrap pthreads and Win32 threads.

        The API defines 2 types: the function pointer type,
   __crawdog_argon2_thread_func_t,
        and the type of the thread handle---__crawdog_argon2_thread_handle_t.
*/
#if defined(_WIN32)
#include <process.h>
typedef unsigned(__stdcall *__crawdog_argon2_thread_func_t)(void *);
typedef uintptr_t __crawdog_argon2_thread_handle_t;
#else
#include <pthread.h>
typedef void *(*__crawdog_argon2_thread_func_t)(void *);
typedef pthread_t __crawdog_argon2_thread_handle_t;
#endif

/* Creates a thread
 * @param handle pointer to a thread handle, which is the output of this
 * function. Must not be NULL.
 * @param func A function pointer for the thread's entry point. Must not be
 * NULL.
 * @param args Pointer that is passed as an argument to @func. May be NULL.
 * @return 0 if @handle and @func are valid pointers and a thread is successfully
 * created.
 */
int __crawdog_argon2_thread_create(__crawdog_argon2_thread_handle_t *handle,
                         __crawdog_argon2_thread_func_t func, void *args);

/* Waits for a thread to terminate
 * @param handle Handle to a thread created with __crawdog_argon2_thread_create.
 * @return 0 if @handle is a valid handle, and joining completed successfully.
*/
int __crawdog_argon2_thread_join(__crawdog_argon2_thread_handle_t handle);

/* Terminate the current thread. Must be run inside a thread created by
 * __crawdog_argon2_thread_create.
*/
void __crawdog_argon2_thread_exit(void);

#endif /* __CRAWDOG_ARGON2_NO_THREADS */
#endif
