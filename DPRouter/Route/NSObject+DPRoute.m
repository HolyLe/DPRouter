//
//  NSObject+DPRoute.m
//  DiamondPark
//
//  Created by 麻小亮 on 2019/5/6.
//  Copyright © 2019 DiamondPark. All rights reserved.
//

#import "NSObject+DPRoute.h"
#import <objc/runtime.h>
#import <objc/message.h>
static const void *DPRuntimeDeallocTasks = &DPRuntimeDeallocTasks;


static inline NSMutableSet *DPSwizzledSet(){
    static NSMutableSet *set = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        set = [NSMutableSet set];
    });
    return set;
}
static inline void dp_swizzleDeallocIfNeed(Class swizzleClass){
    NSMutableSet *deallocSet = DPSwizzledSet();
    @synchronized (deallocSet) {
        NSString *className = NSStringFromClass(swizzleClass);
        if ([deallocSet containsObject:className]) return;
        SEL deallocSelector = sel_registerName("dealloc");
        
        __block void (* oldImp) (__unsafe_unretained id, SEL) = NULL;
        
        id newImpBlock = ^ (__unsafe_unretained id self){
            
            NSMutableArray *deallocTask = objc_getAssociatedObject(self, &DPRuntimeDeallocTasks);
            @synchronized (deallocTask) {
                if (deallocTask.count > 0) {
                    [deallocTask enumerateObjectsUsingBlock:^(dp_deallocTask obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        if (obj) {
                            obj(self);
                        }
                    }];
                    [deallocTask removeAllObjects];
                }
            }
            if (oldImp == NULL) {
                struct objc_super supperInfo = {
                    .receiver = self,
                    .super_class = class_getSuperclass(swizzleClass)
                };
                ((void (*) (struct objc_super *, SEL))objc_msgSendSuper)(&supperInfo, deallocSelector);
            }else{
                oldImp(self,deallocSelector);
            }
        };
        IMP newImp = imp_implementationWithBlock(newImpBlock);
        if (!class_addMethod(swizzleClass, deallocSelector, newImp, "v@:")) {
            Method deallocMethod = class_getInstanceMethod(swizzleClass, deallocSelector);
            oldImp = (__typeof__ (oldImp))method_getImplementation(deallocMethod);
            oldImp = (__typeof__ (oldImp))method_setImplementation(deallocMethod, newImp);
        }
        [deallocSet addObject:className];
    }
}
@implementation NSObject (DPRoute)
- (NSMutableArray<dp_deallocTask> *)dp_deallocTasks{
    NSMutableArray *tasks = objc_getAssociatedObject(self, &DPRuntimeDeallocTasks);
    if (tasks) return tasks;
    tasks = [NSMutableArray array];
    dp_swizzleDeallocIfNeed(object_getClass(self));
    objc_setAssociatedObject(self, &DPRuntimeDeallocTasks, tasks, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return tasks;
}

- (void)dp_addDellocTask:(dp_deallocTask)task{
    @synchronized ([self dp_deallocTasks]) {
        [[self dp_deallocTasks] addObject:task];
    }
}
@end
