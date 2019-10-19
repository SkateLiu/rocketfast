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
#import <objc/runtime.h>

/*
 https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
 R          The property is read-only (readonly).
 C          The property is a copy of the value last assigned (copy).
 &          The property is a reference to the value last assigned (retain).
 N          The property is non-atomic (nonatomic).
 G<name>    The property defines a custom getter selector name. The name follows the G (for example, GcustomGetter,).
 S<name>    The property defines a custom setter selector name. The name follows the S (for example, ScustomSetter:,)
 D          The property is dynamic (@dynamic).
 W          The property is a weak reference (__weak).
 P          The property is eligible for garbage collection.
 t<encoding> Specifies the type using old-style encoding.
 #          The property is a Class struct

 eg:
 strongDelegate, T@"<PhotoDetailViewControllerDelegate1>",&,N,V_strongDelegate
 aString, T@"NSString",C,N,VaStringNewName
 fullScreenRatio, TB,R,N,V_fullScreenRatio
 networkReachability, T^{__SCNetworkReachability=},R,N,V_networkReachability
 completionHandler, T@?,C,N,V_completionHandler
 delegateQueue, T^{dispatch_queue_s=}
 statement, T^v,V_statement   // void *statement;
 classProperty, T#,&,N,V_classProperty  // Class classProperty;

 */


#ifdef __cplusplus
extern "C" {
#endif

typedef struct _wxrocket_property_box {
    const char *property_name;
    const char *attributtes_short;
    bool is_strong;
    bool is_copy;
    bool is_weak;
    bool is_readonly;
    bool is_nonatomic;
    bool is_dynamic;
    char ivar_name[512];
    char type_name[128];
} wxrocket_property_box;

wxrocket_property_box wxrocket_extract_property(objc_property_t property);

#ifdef __cplusplus
}
#endif
