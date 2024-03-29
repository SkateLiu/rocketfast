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


#import <Foundation/Foundation.h>

#include <mach/vm_types.h>
#include <stdbool.h>

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

/**
 cache dyld images info to filepath.
 */
void wxra_setup_dyld_images_dumper_with_path(NSString *filepath);

/**
 detect if the given frame address is a system libraries method.
 */
boolean_t wxra_addr_is_in_sys_libraries(vm_address_t address);

/**
 check if the given symbol address is within the interval of all dyld images.
 */
boolean_t wxra_symbol_addr_check_basic(vm_address_t address);


/****************************************************************************/
#pragma mark -

boolean_t wxra_start_dyld_restore(NSString *cachedDyldImages);

uint64_t wxra_dyld_restore_address(uint64_t org_address);

void wxra_end_dyld_restore(void);

NS_ASSUME_NONNULL_END

#ifdef __cplusplus
}
#endif
