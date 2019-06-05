//
//  RouteC.m
//  DPRouter
//
//  Created by 麻小亮 on 2019/6/5.
//  Copyright © 2019 麻小亮. All rights reserved.
//

#import "RouteC.h"

@implementation RouteC
+ (NSString *)url_identify{
    return @"111";
}
- (void)setup{
    [self registerUrl:@"save" handle:^BOOL(NSString * _Nonnull url, NSMutableDictionary * _Nonnull para, DPBaseRoute * _Nonnull route) {
        NSLog(@"%@",route[@"data"]);
        [route remove];
        return YES;
    }];
    
    [self registerUrl:@"message" handle:^BOOL(NSString * _Nonnull url, NSMutableDictionary * _Nonnull para, DPBaseRoute * _Nonnull route) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [route postRouteType:@"text" tuple:[DPRouteTuple tupleWithObjects:@"传递一个字符串", nil] routeBack:^(id  _Nonnull data, DPBaseRoute * _Nonnull route) {
                NSLog(@"从监听者回调的数据 %@",data);
            }];
        });
        return YES;
    }];
}
@end
