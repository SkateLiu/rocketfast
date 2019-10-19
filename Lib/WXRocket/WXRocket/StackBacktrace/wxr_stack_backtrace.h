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


#ifndef wxr_stack_backtrace_h
#define wxr_stack_backtrace_h

#include <mach/mach.h>
#include <stdio.h>

#define WXRocketStackBacktracePerformanceTestEnabled 0

#ifdef WXRocketStackBacktracePerformanceTestEnabled
#define _InternalMTHStackBacktracePerformanceTestEnabled WXRocketStackBacktracePerformanceTestEnabled
#else
#define _InternalMTHStackBacktracePerformanceTestEnabled NO
#endif


#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    uintptr_t *frames;
    size_t frames_size;
} wxr_stack_backtrace;

wxr_stack_backtrace *wxr_malloc_stack_backtrace(void);
void wxr_free_stack_backtrace(wxr_stack_backtrace *stack_backtrace);

bool wxr_stack_backtrace_of_thread(thread_t thread, wxr_stack_backtrace *stack_backtrace, const size_t backtrace_depth_max, uintptr_t top_frames_to_skip);

#ifdef __cplusplus
}
#endif

#endif /* wxr_stack_backtrace_h */
