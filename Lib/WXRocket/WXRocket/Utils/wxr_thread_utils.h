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


#ifndef wxr_thread_utils_h
#define wxr_thread_utils_h

#include <stdbool.h>
#include <stdio.h>


#ifdef __cplusplus
extern "C" {
#endif // __cplusplus


bool wxr_suspend_all_child_threads(void);
bool wxr_resume_all_child_threads(void);


#ifdef __cplusplus
}
#endif // __cplusplus


#endif /* wxr_thread_utils_h */
