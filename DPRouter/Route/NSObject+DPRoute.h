//
//  NSObject+DPRoute.h
//  DiamondPark
//
//  Created by 麻小亮 on 2019/5/6.
//  Copyright © 2019 DiamondPark. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DPRouteTuple.h"
NS_ASSUME_NONNULL_BEGIN
typedef void(^dp_deallocTask)(id object);
@interface NSObject (DPRoute)

/**
 添加销毁任务
 */
- (void)dp_addDellocTask:(dp_deallocTask)task;
@end

NS_ASSUME_NONNULL_END
