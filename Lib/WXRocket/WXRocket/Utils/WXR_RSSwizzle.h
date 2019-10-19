//
//  WXR_RSSwizzle.h
//  WXR_RSSwizzleTests
//
//  Created by Yan Rabovik on 05.09.13.
//
//

#import <Foundation/Foundation.h>

#pragma mark - Macros Based API

/// A macro for wrapping the return type of the swizzled method.
#define MTH_RSSWReturnType(type) type

/// A macro for wrapping arguments of the swizzled method.
#define MTH_RSSWArguments(arguments...) _MTH_RSSWArguments(arguments)

/// A macro for wrapping the replacement code for the swizzled method.
#define MTH_RSSWReplacement(code...) code

/// A macro for casting and calling original implementation.
/// May be used only in WXR_RSSwizzleInstanceMethod or WXR_RSSwizzleClassMethod macros.
#define MTH_RSSWCallOriginal(arguments...) _MTH_RSSWCallOriginal(arguments)

#pragma mark └ Swizzle Instance Method

/**
 Swizzles the instance method of the class with the new implementation.

 Example for swizzling `-(int)calculate:(int)number;` method:

 @code

 WXR_RSSwizzleInstanceMethod(classToSwizzle,
    @selector(calculate:),
    MTH_RSSWReturnType(int),
    MTH_RSSWArguments(int number),
    MTH_RSSWReplacement({
        // Calling original implementation.
        int res = MTH_RSSWCallOriginal(number);
        // Returning modified return value.
        return res + 1;
    }), 0, NULL);

 @endcode

 Swizzling frequently goes along with checking whether this particular class (or one of its superclasses) has been already swizzled. Here the `WXR_RSSwizzleMode` and `key` parameters can help. See +[WXR_RSSwizzle swizzleInstanceMethod:inClass:newImpFactory:mode:key:] for details.

 Swizzling is fully thread-safe.

 @param classToSwizzle The class with the method that should be swizzled.

 @param selector Selector of the method that should be swizzled.

 @param MTH_RSSWReturnType The return type of the swizzled method wrapped in the MTH_RSSWReturnType macro.

 @param MTH_RSSWArguments The arguments of the swizzled method wrapped in the MTH_RSSWArguments macro.

 @param MTH_RSSWReplacement The code of the new implementation of the swizzled method wrapped in the MTH_RSSWReplacement macro.

 @param WXR_RSSwizzleMode The mode is used in combination with the key to indicate whether the swizzling should be done for the given class. You can pass 0 for WXR_RSSwizzleModeAlways.

 @param key The key is used in combination with the mode to indicate whether the swizzling should be done for the given class. May be NULL if the mode is WXR_RSSwizzleModeAlways.

 @return YES if successfully swizzled and NO if swizzling has been already done for given key and class (or one of superclasses, depends on the mode).

 */
#define WXR_RSSwizzleInstanceMethod(classToSwizzle, \
    selector,                                       \
    MTH_RSSWReturnType,                             \
    MTH_RSSWArguments,                              \
    MTH_RSSWReplacement,                            \
    WXR_RSSwizzleMode,                              \
    key)                                            \
    _RSSwizzleInstanceMethod(classToSwizzle,        \
        selector,                                   \
        MTH_RSSWReturnType,                         \
        _MTH_RSSWWrapArg(MTH_RSSWArguments),        \
        _MTH_RSSWWrapArg(MTH_RSSWReplacement),      \
        WXR_RSSwizzleMode,                          \
        key)

#pragma mark └ Swizzle Class Method

/**
 Swizzles the class method of the class with the new implementation.

 Example for swizzling `+(int)calculate:(int)number;` method:

 @code

 WXR_RSSwizzleClassMethod(classToSwizzle,
    @selector(calculate:),
    MTH_RSSWReturnType(int),
    MTH_RSSWArguments(int number),
    MTH_RSSWReplacement({
        // Calling original implementation.
        int res = MTH_RSSWCallOriginal(number);
        // Returning modified return value.
        return res + 1;
    }));

 @endcode

 Swizzling is fully thread-safe.

 @param classToSwizzle The class with the method that should be swizzled.

 @param selector Selector of the method that should be swizzled.

 @param MTH_RSSWReturnType The return type of the swizzled method wrapped in the MTH_RSSWReturnType macro.

 @param MTH_RSSWArguments The arguments of the swizzled method wrapped in the MTH_RSSWArguments macro.

 @param MTH_RSSWReplacement The code of the new implementation of the swizzled method wrapped in the MTH_RSSWReplacement macro.

 */
#define WXR_RSSwizzleClassMethod(classToSwizzle, \
    selector,                                    \
    MTH_RSSWReturnType,                          \
    MTH_RSSWArguments,                           \
    MTH_RSSWReplacement)                         \
    _RSSwizzleClassMethod(classToSwizzle,        \
        selector,                                \
        MTH_RSSWReturnType,                      \
        _MTH_RSSWWrapArg(MTH_RSSWArguments),     \
        _MTH_RSSWWrapArg(MTH_RSSWReplacement))

#pragma mark - Main API

/**
 A function pointer to the original implementation of the swizzled method.
 */
typedef void (*WXR_RSSwizzleOriginalIMP)(void /* id, SEL, ... */);

/**
 WXR_RSSwizzleInfo is used in the new implementation block to get and call original implementation of the swizzled method.
 */
@interface WXR_RSSwizzleInfo : NSObject

/**
 Returns the original implementation of the swizzled method.

 It is actually either an original implementation if the swizzled class implements the method itself; or a super implementation fetched from one of the superclasses.

 @note You must always cast returned implementation to the appropriate function pointer when calling.

 @return A function pointer to the original implementation of the swizzled method.
 */
- (WXR_RSSwizzleOriginalIMP)getOriginalImplementation;

/// The selector of the swizzled method.
@property (nonatomic, readonly) SEL selector;

@end

/**
 A factory block returning the block for the new implementation of the swizzled method.

 You must always obtain original implementation with swizzleInfo and call it from the new implementation.

 @param swizzleInfo An info used to get and call the original implementation of the swizzled method.

 @return A block that implements a method.
 Its signature should be: `method_return_type ^(id self, method_args...)`.
 The selector is not available as a parameter to this block.
 */
typedef id (^WXR_RSSwizzleImpFactoryBlock)(WXR_RSSwizzleInfo *swizzleInfo);

typedef NS_ENUM(NSUInteger, WXR_RSSwizzleMode) {
    /// WXR_RSSwizzle always does swizzling.
    WXR_RSSwizzleModeAlways = 0,
    /// WXR_RSSwizzle does not do swizzling if the same class has been swizzled earlier with the same key.
    WXR_RSSwizzleModeOncePerClass = 1,
    /// WXR_RSSwizzle does not do swizzling if the same class or one of its superclasses have been swizzled earlier with the same key.
    /// @note There is no guarantee that your implementation will be called only once per method call. If the order of swizzling is: first inherited class, second superclass, then both swizzlings will be done and the new implementation will be called twice.
    WXR_RSSwizzleModeOncePerClassAndSuperclasses = 2
};

@interface WXR_RSSwizzle : NSObject

#pragma mark └ Swizzle Instance Method

/**
 Swizzles the instance method of the class with the new implementation.

 Original implementation must always be called from the new implementation. And because of the the fact that for safe and robust swizzling original implementation must be dynamically fetched at the time of calling and not at the time of swizzling, swizzling API is a little bit complicated.

 You should pass a factory block that returns the block for the new implementation of the swizzled method. And use swizzleInfo argument to retrieve and call original implementation.

 Example for swizzling `-(int)calculate:(int)number;` method:

 @code

 SEL selector = @selector(calculate:);
 [WXR_RSSwizzle
    swizzleInstanceMethod:selector
    inClass:classToSwizzle
    newImpFactory:^id(WXR_RSSwizzleInfo *swizzleInfo) {
        // This block will be used as the new implementation.
        return ^int(__unsafe_unretained id self, int num) {
            // You MUST always cast implementation to the correct function pointer.
            int (*originalIMP)(__unsafe_unretained id, SEL, int);
            originalIMP = (__typeof(originalIMP))[swizzleInfo getOriginalImplementation];
            // Calling original implementation.
            int res = originalIMP(self,selector,num);
            // Returning modified return value.
            return res + 1;
        };
    }
    mode:WXR_RSSwizzleModeAlways
    key:NULL];

 @endcode

 Swizzling frequently goes along with checking whether this particular class (or one of its superclasses) has been already swizzled. Here the `mode` and `key` parameters can help.

 Here is an example of swizzling `-(void)dealloc;` only in case when neither class and no one of its superclasses has been already swizzled with our key. However "Deallocating ..." message still may be logged multiple times per method call if swizzling was called primarily for an inherited class and later for one of its superclasses.

 @code

 static const void *key = &key;
 SEL selector = NSSelectorFromString(@"dealloc");
 [WXR_RSSwizzle
    swizzleInstanceMethod:selector
    inClass:classToSwizzle
    newImpFactory:^id(WXR_RSSwizzleInfo *swizzleInfo) {
        return ^void(__unsafe_unretained id self){
            NSLog(@"Deallocating %@.",self);

            void (*originalIMP)(__unsafe_unretained id, SEL);
            originalIMP = (__typeof(originalIMP))[swizzleInfo getOriginalImplementation];
            originalIMP(self,selector);
        };
    }
    mode:WXR_RSSwizzleModeOncePerClassAndSuperclasses
    key:key];

 @endcode

 Swizzling is fully thread-safe.

 @param selector Selector of the method that should be swizzled.

 @param classToSwizzle The class with the method that should be swizzled.

 @param factoryBlock The factory block returning the block for the new implementation of the swizzled method.

 @param mode The mode is used in combination with the key to indicate whether the swizzling should be done for the given class.

 @param key The key is used in combination with the mode to indicate whether the swizzling should be done for the given class. May be NULL if the mode is WXR_RSSwizzleModeAlways.

 @return YES if successfully swizzled and NO if swizzling has been already done for given key and class (or one of superclasses, depends on the mode).
 */
+ (BOOL)swizzleInstanceMethod:(SEL)selector
                      inClass:(Class)classToSwizzle
                newImpFactory:(WXR_RSSwizzleImpFactoryBlock)factoryBlock
                         mode:(WXR_RSSwizzleMode)mode
                          key:(const void *)key;

#pragma mark └ Swizzle Class method

/**
 Swizzles the class method of the class with the new implementation.

 Original implementation must always be called from the new implementation. And because of the the fact that for safe and robust swizzling original implementation must be dynamically fetched at the time of calling and not at the time of swizzling, swizzling API is a little bit complicated.

 You should pass a factory block that returns the block for the new implementation of the swizzled method. And use swizzleInfo argument to retrieve and call original implementation.

 Example for swizzling `+(int)calculate:(int)number;` method:

 @code

 SEL selector = @selector(calculate:);
 [WXR_RSSwizzle
    swizzleClassMethod:selector
    inClass:classToSwizzle
    newImpFactory:^id(WXR_RSSwizzleInfo *swizzleInfo) {
        // This block will be used as the new implementation.
        return ^int(__unsafe_unretained id self, int num){
            // You MUST always cast implementation to the correct function pointer.
            int (*originalIMP)(__unsafe_unretained id, SEL, int);
            originalIMP = (__typeof(originalIMP))[swizzleInfo getOriginalImplementation];
            // Calling original implementation.
            int res = originalIMP(self,selector,num);
            // Returning modified return value.
            return res + 1;
        };
    }];

 @endcode

 Swizzling is fully thread-safe.

 @param selector Selector of the method that should be swizzled.

 @param classToSwizzle The class with the method that should be swizzled.

 @param factoryBlock The factory block returning the block for the new implementation of the swizzled method.
 */
+ (void)swizzleClassMethod:(SEL)selector
                   inClass:(Class)classToSwizzle
             newImpFactory:(WXR_RSSwizzleImpFactoryBlock)factoryBlock;

@end

#pragma mark - Implementation details
// Do not write code that depends on anything below this line.

// Wrapping arguments to pass them as a single argument to another macro.
#define _MTH_RSSWWrapArg(args...) args

#define _MTH_RSSWDel2Arg(a1, a2, args...) a1, ##args
#define _MTH_RSSWDel3Arg(a1, a2, a3, args...) a1, a2, ##args

// To prevent comma issues if there are no arguments we add one dummy argument
// and remove it later.
#define _MTH_RSSWArguments(arguments...) DEL, ##arguments

#define _RSSwizzleInstanceMethod(classToSwizzle,                                                           \
    selector,                                                                                              \
    MTH_RSSWReturnType,                                                                                    \
    MTH_RSSWArguments,                                                                                     \
    MTH_RSSWReplacement,                                                                                   \
    WXR_RSSwizzleMode,                                                                                     \
    KEY)                                                                                                   \
    [WXR_RSSwizzle                                                                                         \
        swizzleInstanceMethod:selector                                                                     \
                      inClass:[classToSwizzle class]                                                       \
                newImpFactory:^id(WXR_RSSwizzleInfo *swizzleInfo) {                                        \
                    MTH_RSSWReturnType (*originalImplementation_)(_MTH_RSSWDel3Arg(__unsafe_unretained id, \
                        SEL,                                                                               \
                        MTH_RSSWArguments));                                                               \
                    SEL selector_ = selector;                                                              \
                    return ^MTH_RSSWReturnType(_MTH_RSSWDel2Arg(__unsafe_unretained id self,               \
                        MTH_RSSWArguments)) {                                                              \
                        MTH_RSSWReplacement                                                                \
                    };                                                                                     \
                }                                                                                          \
                         mode:WXR_RSSwizzleMode                                                            \
                          key:KEY];

#define _RSSwizzleClassMethod(classToSwizzle,                                                           \
    selector,                                                                                           \
    MTH_RSSWReturnType,                                                                                 \
    MTH_RSSWArguments,                                                                                  \
    MTH_RSSWReplacement)                                                                                \
    [WXR_RSSwizzle                                                                                      \
        swizzleClassMethod:selector                                                                     \
                   inClass:[classToSwizzle class]                                                       \
             newImpFactory:^id(WXR_RSSwizzleInfo *swizzleInfo) {                                        \
                 MTH_RSSWReturnType (*originalImplementation_)(_MTH_RSSWDel3Arg(__unsafe_unretained id, \
                     SEL,                                                                               \
                     MTH_RSSWArguments));                                                               \
                 SEL selector_ = selector;                                                              \
                 return ^MTH_RSSWReturnType(_MTH_RSSWDel2Arg(__unsafe_unretained id self,               \
                     MTH_RSSWArguments)) {                                                              \
                     MTH_RSSWReplacement                                                                \
                 };                                                                                     \
             }];

#define _MTH_RSSWCallOriginal(arguments...)          \
    ((__typeof(originalImplementation_))[swizzleInfo \
            getOriginalImplementation])(self,        \
        selector_,                                   \
        ##arguments)
