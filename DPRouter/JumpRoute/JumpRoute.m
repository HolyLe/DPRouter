//
//  JumpRoute.m
//  DPRouter
//
//  Created by 麻小亮 on 2019/6/4.
//  Copyright © 2019 麻小亮. All rights reserved.
//

#import "JumpRoute.h"

@implementation JumpRoute
- (void)jumpMethod{
    [self jumpToAA];
    [self jumpTooAA];
    
}

/**
 调用A模块的aa方法
 */
- (void)jumpToAA{
    [[DPRouter router] openRouteUrl:@"A/aa"];
}

- (void)jumpTooAA{
    [[[DPRouter router] routeWithUrl:@"A"] openUrl:@"aa" para:@{} hanle:^(BOOL openSuccess, DPRouteTuple * _Nonnull tuple) {
        
    }];
}

@end
