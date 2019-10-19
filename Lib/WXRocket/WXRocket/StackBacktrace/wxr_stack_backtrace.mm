//
// Copyright (c) 2019-present, TT, Inc.
// All rights reserved.
//
// This source code is licensed under the license found in the LICENSE file in
// the root directory of this source tree.
//
// Created on: 2019/10/18
// Created by: TT
//


#include "wxr_stack_backtrace.h"

#include <dlfcn.h>
#include <inttypes.h>
#include <limits.h>
#include <mach/mach_time.h>
#include <pthread.h>
#include <string.h>
#include <sys/time.h>
#include <sys/types.h>

#pragma - mark DEFINE MACRO FOR DIFFERENT CPU ARCHITECTURE
#if defined(__arm64__)
#define DETAG_INSTRUCTION_ADDRESS(A) ((A) & ~(3UL))
#define MT_THREAD_STATE_COUNT ARM_THREAD_STATE64_COUNT
#define MT_THREAD_STATE ARM_THREAD_STATE64
#define MT_FRAME_POINTER __fp
#define MT_STACK_POINTER __sp
#define MT_INSTRUCTION_ADDRESS __pc

#elif defined(__arm__)
#define DETAG_INSTRUCTION_ADDRESS(A) ((A) & ~(1UL))
#define MT_THREAD_STATE_COUNT ARM_THREAD_STATE_COUNT
#define MT_THREAD_STATE ARM_THREAD_STATE
#define MT_FRAME_POINTER __r[7]
#define MT_STACK_POINTER __sp
#define MT_INSTRUCTION_ADDRESS __pc

#elif defined(__x86_64__)
#define DETAG_INSTRUCTION_ADDRESS(A) (A)
#define MT_THREAD_STATE_COUNT x86_THREAD_STATE64_COUNT
#define MT_THREAD_STATE x86_THREAD_STATE64
#define MT_FRAME_POINTER __rbp
#define MT_STACK_POINTER __rsp
#define MT_INSTRUCTION_ADDRESS __rip

#elif defined(__i386__)
#define DETAG_INSTRUCTION_ADDRESS(A) (A)
#define MT_THREAD_STATE_COUNT x86_THREAD_STATE32_COUNT
#define MT_THREAD_STATE x86_THREAD_STATE32
#define MT_FRAME_POINTER __ebp
#define MT_STACK_POINTER __esp
#define MT_INSTRUCTION_ADDRESS __eip

#endif

#define CALL_INSTRUCTION_FROM_RETURN_ADDRESS(A) (DETAG_INSTRUCTION_ADDRESS((A)) - 1)

typedef struct _wxr_stackframe_entity {
    const struct _wxr_stackframe_entity *const previous;
    const uintptr_t return_address;
} wxr_stackframe_entity;

static kern_return_t wxr_mach_copy_mem(const void *const src, void *const dst, const size_t num_bytes) {
    vm_size_t bytes_copied = 0;
    return vm_read_overwrite(mach_task_self(), (vm_address_t)src, (vm_size_t)num_bytes, (vm_address_t)dst, &bytes_copied);
}

wxr_stack_backtrace *wxr_malloc_stack_backtrace() {
    wxr_stack_backtrace *stackframes = (wxr_stack_backtrace *)malloc(sizeof(wxr_stack_backtrace));
    if (stackframes) {
        memset(stackframes, 0, sizeof(wxr_stack_backtrace));
    }
    return stackframes;
}

void wxr_free_stack_backtrace(wxr_stack_backtrace *stackframes) {
    if (stackframes == nil)
        return;

    if (stackframes->frames) {
        free(stackframes->frames);
        stackframes->frames = nil;
    }
    stackframes->frames_size = 0;

    free(stackframes);
}

bool wxr_stack_backtrace_of_thread(thread_t thread, wxr_stack_backtrace *out_stack_backtrace, const size_t backtrace_depth_max, uintptr_t top_frames_to_skip) {
    if (out_stack_backtrace == nil)
        return false;

    _STRUCT_MCONTEXT machine_context;
    mach_msg_type_number_t state_count = MT_THREAD_STATE_COUNT;
    kern_return_t kr = thread_get_state(thread, MT_THREAD_STATE, (thread_state_t)(&machine_context.__ss), &state_count);
    if (kr != KERN_SUCCESS) {
        return false;
    }

    size_t frames_size = 0;
    uintptr_t backtrace_frames[backtrace_depth_max];

    const uintptr_t instruction_addr = machine_context.__ss.MT_INSTRUCTION_ADDRESS;
    if (instruction_addr) {
        backtrace_frames[frames_size++] = instruction_addr;
    } else {
        out_stack_backtrace->frames_size = frames_size;
        return false;
    }

    uintptr_t link_register = 0;

#if defined(__i386__) || defined(__x86_64__)
    link_register = 0;
#else
    link_register = machine_context.__ss.__lr;
#endif //mt_mach_linkRegister(&machineContext);

    if (link_register) {
        backtrace_frames[frames_size++] = CALL_INSTRUCTION_FROM_RETURN_ADDRESS(link_register);
    }

    // get frame point
    wxr_stackframe_entity frame = {NULL, 0};
    const uintptr_t frame_ptr = machine_context.__ss.MT_FRAME_POINTER;
    if (frame_ptr == 0 || wxr_mach_copy_mem((void *)frame_ptr, &frame, sizeof(frame)) != KERN_SUCCESS) {
        out_stack_backtrace->frames_size = frames_size;
        return false;
    }

    for (; frames_size < backtrace_depth_max; frames_size++) {
        backtrace_frames[frames_size] = CALL_INSTRUCTION_FROM_RETURN_ADDRESS(frame.return_address);
        if (backtrace_frames[frames_size] == 0 || frame.previous == 0 || wxr_mach_copy_mem(frame.previous, &frame, sizeof(frame)) != KERN_SUCCESS) {
            break;
        }
    }

    if (top_frames_to_skip >= frames_size) {
        out_stack_backtrace->frames_size = 0;
        out_stack_backtrace->frames = NULL;
        return false;
    }

    size_t output_frames_size = frames_size - top_frames_to_skip;
    out_stack_backtrace->frames_size = output_frames_size;
    out_stack_backtrace->frames = (uintptr_t *)malloc(sizeof(uintptr_t) * output_frames_size);
    memcpy(out_stack_backtrace->frames, backtrace_frames + top_frames_to_skip, sizeof(uintptr_t) * output_frames_size);
    return true;
}
