//
//  DPRouter+Private.h
//  DiamondPark
//
//  Created by 麻小亮 on 2019/5/6.
//  Copyright © 2019 DiamondPark. All rights reserved.
//

#import "DPRouter.h"
#import "DPRouteParsing.h"
NS_ASSUME_NONNULL_BEGIN

static inline NSArray *dp_getRoutePaths(NSString *key){
    if (!key||![key isKindOfClass:[NSString class]]) return nil;
    NSArray *keys;
    if ([key containsString:@"/"]) {
        NSMutableArray *array = [key componentsSeparatedByString:@"/"].mutableCopy;
        [array removeObject:@""];
        keys = array.copy;
    }else{
        keys = @[key];
    }
    return keys;
}
static inline NSString *dp_getRoutePathComponents(NSArray *keys){
    if (!keys || ![keys isKindOfClass:[NSArray class]]) return @"";
    return [keys componentsJoinedByString:@"/"];
}
@interface DPRouter (Private)
@property (nonatomic, strong) DPRouteScheme * currentScheme;
@property (nonatomic, strong, readonly) DPRouteScheme * globalScheme;
- (void)storeRoute:(DPBaseRoute *)route;
- (void)removeRoute:(DPBaseRoute *)route;
- (void)openParsing:(nonnull DPRouteParsing *)parsing;
@end

@class DPRouterObjectCache;
@interface DPBaseRoute (Private)
- (void)openUrlWithParsing:(DPRouteParsing *)parsing;
@property (nonatomic, weak) DPRouterObjectCache * cache;
@end
@interface DPRouteParsing(Private)
@property (nonatomic, strong) NSDictionary * parameters;
@end
NS_ASSUME_NONNULL_END
