//
//  RouteB.m
//  DPRouter
//
//  Created by 麻小亮 on 2019/6/4.
//  Copyright © 2019 麻小亮. All rights reserved.
//

#import "RouteA.h"
#import "ViewControllerA.h"
@implementation RouteA

+ (NSString *)url_identify{
    return @"A";
}

- (void)setup{
    [self registerUrl:@"aa" handle:^BOOL(NSString * _Nonnull url, NSMutableDictionary * _Nonnull para, DPBaseRoute * _Nonnull route) {
        NSLog(@"调用方法");
        [route remove];
        return YES;
    }];
    [self registerUrl:@"jumpToVCA" handle:^BOOL(NSString * _Nonnull url, NSMutableDictionary * _Nonnull para, DPBaseRoute * _Nonnull route) {
        
        return YES;
    }];
}
- (void)dealloc
{
    NSLog(@"A模块路由销毁了");
}
@end
