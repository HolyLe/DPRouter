//
//  DPBaseRoute.h
//  DiamondPark
//
//  Created by 麻小亮 on 2019/5/5.
//  Copyright © 2019 DiamondPark. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DPRouteTuple.h"
#import "NSObject+DPRoute.h"
NS_ASSUME_NONNULL_BEGIN


@interface DPRouteTuple (Route)
/**
 处理一些消息发送数据
 */
@property (nonatomic, copy, readonly) void (^routeBack) (void (^ backData)(id _Nullable * _Nonnull data));

@end


@class DPRouteScheme;

@interface DPBaseRoute : NSObject



+ (NSString *)url_identify;


/**
 当前所在链路
 */
@property (nonatomic, copy, readonly) NSString * currentScheme;


/**
 主键Id
 */
@property (nonatomic, copy, readonly) NSString * primaryKey;

@property (nonatomic, copy, readonly) NSString * uniqueIdentify;
/**
 是否允许加载其他业务
 */
@property (nonatomic, assign) BOOL  isAllowedLoadOtherBusiness;


#pragma mark - 初始化数据 -

- (void)setup;

#pragma mark - 提供消息注册和发送的方法 -
/**
 监听，某个状态
 */
- (void)addObserver:(id)target routeWithType:(NSString *)type tuple:(void (^) (DPRouteTuple *tuple, DPBaseRoute *route))tuple;

/**
 发送消息
 */
- (void)postRouteType:(NSString *)type tuple:(DPRouteTuple *)tuple routeBack:(void (^) (id data, DPBaseRoute *route))routeBack;

#pragma mark - 提供方法注册和方法实现 -

/**
 注册

 @param url 注册的标识
 @param handle 回调，分别为注册的url标识，调用时传入的参数，路由对象自身
 */
- (void)registerUrl:(NSString *)url handle:(BOOL (^)( NSString *url, NSMutableDictionary *para, DPBaseRoute *route))handle;


/**
 打开
 
 @param url 方法
 @param para 参数
 @param hanle opensuccess，是否成功，tuple  .first,当前执行操作的key, .second，参数
 */
- (void)openUrl:(NSString *)url para:(NSDictionary *)para hanle:(void (^)(BOOL openSuccess, DPRouteTuple * tuple))hanle;


- (void)openUrl:(NSString *)url para:(NSDictionary *)para onScheme:(NSString *)scheme hanle:(void (^)(BOOL openSuccess, DPRouteTuple * tuple))hanle;
/**
 自己管理生命周期
 */
- (id)objectForUrl:(NSString *)url para:(NSDictionary *)para;

+ (NSString *)getRoutePrimaryKey:(NSDictionary *)para;


#pragma mark - 提供全局业务数据预存处 -

- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key;

- (id)objectForKeyedSubscript:(id <NSCopying>)key;

- (void)removeObjectForKey:(id <NSCopying>)key;

- (BOOL)containObjectForKey:(id <NSCopying>)key;

@end


@interface DPBaseRoute (LifeCircyle)

@property (nonatomic, copy) void (^ dismiss) (DPBaseRoute *baseRoute);

/**
 存储
 */
- (void)store;

/**
 添加到一个scheme
 */
- (void)addToCurentSchemeHandle:(void (^) (DPRouteScheme *scheme, DPBaseRoute *route))handle;

- (void)addToScheme:(NSString *)scheme handle:(void (^) (DPRouteScheme *scheme,DPBaseRoute *route))handle;


/**
 从一个scheme移除
 */
- (void)remove;

@end

@interface DPBaseRoute (Data)

@property (nonatomic, strong, readonly) NSMutableDictionary * registerUrlHandle;

@end
NS_ASSUME_NONNULL_END
