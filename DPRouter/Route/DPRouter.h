//
//  DPRouter.h
//  DiamondPark
//
//  Created by 麻小亮 on 2019/5/5.
//  Copyright © 2019 DiamondPark. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DPRouteScheme.h"
#import "DPRouteParsing.h"
NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSUInteger, DPRouteUnPatsingUrlErrorType) {
    DPRouteUnPatsingUrlErrorTypeClass,
    DPRouteUnPatsingUrlErrorTypeMethod
};
@interface DPRouter : NSObject

+ (DPRouter *)router;

@property (nonatomic, strong, readonly) DPRouteScheme * currentScheme;

/**
 全局链，只用作保存route
 */
@property (nonatomic, strong, readonly) DPRouteScheme * globalScheme;
/**
 打开一个路由
 */
- (void)openRouteUrl:(NSString *)url;

- (void)openRouteUrl:(NSString *)url withPara:(NSDictionary *)dic;

/**
 没有找到路由的回调
 */
@property (nonatomic, copy) BOOL (^unParsingUrl) (DPRouteParsing *parsing, DPBaseRoute *__nullable route,DPRouteUnPatsingUrlErrorType errorStatus);

#pragma mark - Scheme -
- (void)registerScheme:(NSString *)scheme handle:(void (^) (DPRouteScheme *scheme))handle;

- (void)changeRouteScheme:(NSString *)scheme handle:(void (^) (DPRouteScheme *scheme))handle;

- (void)deleteRouteScheme:(NSString *)scheme ifNeedInstead:(NSString *)needScheme;

- (DPRouteScheme *)schemeWithName:(NSString *)name;

#pragma mark - Route -

- (DPBaseRoute *)routeWithUrl:(NSString *)url;

#pragma mark - 路由映射 -
- (void)routeMapOriginalUrl:(NSString *)originalUrl map:(NSString *)mapUrl;

- (void)routeMapOriginalScheme:(NSString *)originalScheme map:(NSString *)mapScheme;

@end

#pragma mark - private -
/**
 分级搜索
 */
@interface DPLevelSearch : NSObject
- (void)addLevel:(NSInteger)level withData:(id)data key:(NSString *)key;
- (DPRouteTuple *)getDataWithKey:(NSArray *)keys key:(NSString *)key;
@end
NS_ASSUME_NONNULL_END
