//
//  SaveDataPre.m
//  DPRouter
//
//  Created by 麻小亮 on 2019/6/4.
//  Copyright © 2019 麻小亮. All rights reserved.
//

#import "SaveDataPre.h"

@implementation SaveDataPre
- (void)jumpMethod{
    [[DPRouter router] routeWithUrl:@"111"][@"data"] = @"数据";
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[DPRouter router] openRouteUrl:@"111/save"];
    });
}
@end
