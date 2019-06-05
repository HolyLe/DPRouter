//
//  Message.m
//  DPRouter
//
//  Created by 麻小亮 on 2019/6/4.
//  Copyright © 2019 麻小亮. All rights reserved.
//

#import "Message.h"

@implementation Message
- (void)jumpMethod{
    [[[DPRouter router] routeWithUrl:@"111"] addObserver:self routeWithType:@"text" tuple:^(DPRouteTuple * _Nonnull tuple, DPBaseRoute * _Nonnull route) {
        NSLog(@"%@", tuple.first);
        tuple.routeBack(^(id  _Nullable __autoreleasing * _Nonnull data) {
            *data = @"aaaa";
        });
    }];
    [[DPRouter router] openRouteUrl:@"111/message"];
    
}
@end
