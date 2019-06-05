//
//  JumpMapping.m
//  DPRouter
//
//  Created by 麻小亮 on 2019/6/4.
//  Copyright © 2019 麻小亮. All rights reserved.
//

#import "JumpMapping.h"

@implementation JumpMapping
- (void)jumpMethod{
    [[DPRouter router] routeMapOriginalUrl:@"B/C" map:@"E"];
    [[DPRouter router] openRouteUrl:@"B/C/bb"];
    [[DPRouter router] openRouteUrl:@"E/bb"];
}
@end
