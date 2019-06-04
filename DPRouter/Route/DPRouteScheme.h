//
//  DPRouteScheme.h
//  DiamondPark
//
//  Created by 麻小亮 on 2019/5/5.
//  Copyright © 2019 DiamondPark. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DPBaseRoute.h"
NS_ASSUME_NONNULL_BEGIN



@interface DPRouteScheme : NSObject

@property (nonatomic, copy) NSString * name;

- (void)bindShow:(void (^) (DPRouteScheme *scheme))show disappear:(void (^) (DPRouteScheme *scheme))disappear;

/**
 添加路由管理
 */
- (void)addRoute:(DPBaseRoute *)route;

/**
 将路由置顶
 */
- (void)bringRouteToHead:(DPBaseRoute *)route;

/**
 移除路由
 */
- (void)removeRoute:(DPBaseRoute *)route;

- (void)removeLastRoute;

- (void)removeFromHeadRoute;

- (void)removeFromAllRoute;

- (void)replaceFromLastRoute:(DPBaseRoute *)route;

- (void)replaceFromHeadRoute:(DPBaseRoute *)route;

- (void)replaceFromAllRoute:(DPBaseRoute *)route;


/**
 设置为当前正在显示的scheme
 */
- (void)setCurrentScheme;


/**
 消失
 */
- (void)dismissAppear;


@end

NS_ASSUME_NONNULL_END
