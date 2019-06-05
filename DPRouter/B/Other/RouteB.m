//
//  RouteA.m
//  DPRouter
//
//  Created by 麻小亮 on 2019/6/4.
//  Copyright © 2019 麻小亮. All rights reserved.
//

#import "RouteB.h"

@implementation RouteB

+ (NSString *)url_identify{
    return @"B/C";
}

- (void)setup{
    [self registerUrl:@"bb" handle:^BOOL(NSString * _Nonnull url, NSMutableDictionary * _Nonnull para, DPBaseRoute * _Nonnull route) {
        NSLog(@"routeB bb");
        [route remove];
        return YES;
    }];
}
@end
