//
//  DPBaseRoute.m
//  DiamondPark
//
//  Created by 麻小亮 on 2019/5/5.
//  Copyright © 2019 DiamondPark. All rights reserved.
//

#import "DPBaseRoute.h"
#import "NSObject+DPRoute.h"
#import "DPRouter.h"
#import "DPRouteParsing.h"
#import "DPRouteScheme.h"
#import "DPRouter+Private.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation DPRouteTuple(Route)

- (void (^)(void (^)(id  _Nullable __autoreleasing * _Nonnull)))routeBack{
    return objc_getAssociatedObject(self, @selector(routeBack));
}
- (void)setRouteBack:(void (^)(void (^)(id  _Nullable __autoreleasing * _Nonnull)))routeBack{
    objc_setAssociatedObject(self, @selector(routeBack), routeBack, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setDismiss:(void (^)(void))dismiss{
    objc_setAssociatedObject(self, @selector(dismiss), dismiss, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(void))dismiss{
    return objc_getAssociatedObject(self, @selector(dismiss));
}

@end



@interface DPRouter(Route)

@end

@interface DPRouteWeakObject : NSObject
@property (nonatomic, weak) id  obj;
@end

@implementation DPRouteWeakObject


@end
static NSString *DPBaseRouteParameters = @"kDPBaseRouteParameters";
@interface DPBaseRoute (){
    dispatch_semaphore_t _lock;
    NSInteger _observerCount;//观察者数量
    NSInteger _storeCount;//存储data的数量
    BOOL _isStore;//是否已经存储了
    DPRouteWeakObject *_weakObject;
}

/**
 所有的观察者
 */
@property (nonatomic, strong) NSMutableDictionary * observeBlocks;

/**
 预存储的数据
 */
@property (nonatomic, strong) NSMutableDictionary * storeData;


@property (nonatomic, strong) DPLevelSearch * levelSearch;

@property (nonatomic, weak) DPRouteScheme * scheme;

@end


@implementation DPBaseRoute

- (instancetype)init
{
    self = [super init];
    if (self) {
        _lock = dispatch_semaphore_create(1);
        [self setup];
    }
    return self;
}

- (void)setup{
    
}

- (void)lock{
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
}

- (void)unlock{
    dispatch_semaphore_signal(_lock);
}

+ (NSString *)url_identify{
    return @"Global";
}

- (NSString *)uniqueIdentify{
    return [NSString stringWithFormat:@"%@%@",[[self class]url_identify]?:@"", self.primaryKey];
}

- (NSString *)currentScheme{
    return self.scheme.name;
}

- (NSString *)primaryKey{
    NSString *key = [[self class] getRoutePrimaryKey:self.storeData[DPBaseRouteParameters]];
    if (!key) {
        key = @"";
    }
    return key;
}
//------------------消息发送与监听
- (void)addObserver:(id)target routeWithType:(nonnull NSString *)type tuple:(nonnull void (^)(DPRouteTuple * _Nonnull, DPBaseRoute * _Nonnull))tuple{
    [self lock];
    NSMutableArray *array = self.observeBlocks[type];
    if (!array) {
        array = [NSMutableArray array];
        [self.observeBlocks setObject:array forKey:type];
    }
    [array addObject:tuple];
    [self unlock];
    NSInteger count = array.count;
    if (_observerCount == 0 && count > 0) {
        [self storeIfNeed];
    }
    _observerCount = count;
    [target dp_addDellocTask:^(id  _Nonnull object) {
        [self lock];
        [array removeObject:tuple];
        [self unlock];
        NSInteger count = array.count;
        if (self->_observerCount > 0 && count == 0) {
            [self removeIfNeed];
        }
        self->_observerCount = count;
    }];
}

- (void)postRouteType:(NSString *)type tuple:(DPRouteTuple *)tuple routeBack:(nonnull void (^)(id _Nonnull, DPBaseRoute * _Nonnull))routeBack{
    [self lock];
    NSArray *array = [self.observeBlocks[type] copy];
    [self unlock];
    if (array.count > 0) {
        __block id data;
        __weak typeof(self)weakSelf = self;
        [tuple setRouteBack:^(void (^backData)(id  _Nullable __autoreleasing * _Nonnull data)) {
            __strong typeof(weakSelf)self = weakSelf;
            if (backData) {
                backData(&data);
            }
            if (routeBack) {
                routeBack(data,self);
            }
            data = nil;
        }];
        for (void (^obj)(DPRouteTuple *, DPBaseRoute *) in array) {
            obj(tuple, self);
        }
        
    }
}

- (NSMutableDictionary *)observeBlocks{
    if (!_observeBlocks) {
        _observeBlocks = [NSMutableDictionary dictionary];
    }
    return _observeBlocks;
}


///----------------------方法注册
- (void)registerUrl:(NSString *)url handle:(BOOL (^)(NSString * _Nonnull, NSMutableDictionary * _Nonnull, DPBaseRoute * _Nonnull))handle{
    if (!handle ||url.length == 0) return;
    [self.levelSearch addLevel:dp_getRoutePaths(url).count withData:handle key:url];
}


- (void)openUrl:(NSString *)url para:(nonnull NSDictionary *)para hanle:(nonnull void (^)(BOOL, DPRouteTuple * _Nonnull))hanle{
    [self openUrl:url para:para onScheme:@"" hanle:^(BOOL openSuccess, DPRouteTuple * _Nonnull tuple) {
        
    }];
}

- (void)openUrl:(NSString *)url para:(nonnull NSDictionary *)para onScheme:(nonnull NSString *)scheme hanle:(nonnull void (^)(BOOL, DPRouteTuple * _Nonnull))hanle{
    DPRouteScheme *routeScheme = self.scheme;
    if (![self.currentScheme isEqualToString:scheme]) {
        DPRouteScheme *preScheme = [[DPRouter router] schemeWithName:scheme];
        if (preScheme == nil) {
            preScheme = [DPRouter router].currentScheme;
        }
        if (preScheme == nil) {
            preScheme = [[DPRouter router] globalScheme];
        }
        if (preScheme != routeScheme) {
            [self remove];
            [self addToScheme:preScheme.name handle:^(DPRouteScheme * _Nonnull scheme, DPBaseRoute * _Nonnull route) {
                
            }];
        }
    }
    NSArray *totalPaths = dp_getRoutePaths(url);
    DPRouteTuple *tupleBack = [self.levelSearch getDataWithKey:totalPaths key:url];
    if (tupleBack.count!=2) {
        hanle(NO, [DPRouteTuple tupleWithArray:@[url,para]]);
        DPRouteParsing *parsing = [[DPRouteParsing alloc] initWithUrlString:url];
        NSMutableDictionary * mutablePara = para.mutableCopy;
        parsing.parameters = mutablePara.copy;
        if ([DPRouter router].unParsingUrl) {
            NSAssert(![DPRouter router].unParsingUrl(parsing, self, DPRouteUnPatsingUrlErrorTypeMethod), @"Class: %@ not Find Method :%@", [self class], url);
        }
        return;
    }
    BOOL (^registerHandle)(NSString *,NSMutableDictionary *, DPBaseRoute *) = tupleBack.first;
    NSString *key = tupleBack.second;
    NSArray *requirePaths = dp_getRoutePaths(key);
    NSInteger requireCount = requirePaths.count;
    NSInteger totalCount = totalPaths.count;
    NSMutableDictionary * mutablePara = para.mutableCopy;
    if (self.isAllowedLoadOtherBusiness && totalCount > requireCount) {
        hanle(registerHandle(key,mutablePara, self), [DPRouteTuple tupleWithObjects:key,para, nil]);
        DPRouteParsing *parsing = [DPRouteParsing new];
        parsing.parameters = mutablePara.copy;
        [parsing reloadPaths:[totalPaths subarrayWithRange:NSMakeRange(requireCount, totalCount - requireCount)]];
        [[DPRouter router] openParsing:parsing];
    }else{
        hanle(registerHandle(url,mutablePara, self), [DPRouteTuple tupleWithObjects:key,para, nil]);
    }
}

+ (NSString *)getRoutePrimaryKey:(NSDictionary *)para{
    return nil;
}

- (id)objectForUrl:(NSString *)url para:(NSDictionary *)para{
    return nil;
}
///----------------------预存储数据

- (void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key{
    [self lock];
    self.storeData[key] = obj;
    NSInteger count = self.storeData.count;
    if (_storeCount == 0 && count > 0) {
        [self storeIfNeed];
    }
    _storeCount = count;
    [self unlock];
}

- (id)objectForKeyedSubscript:(id<NSCopying>)key{
    [self lock];
    id data = self.storeData[key];
    [self unlock];
    return data;
}

- (void)removeObjectForKey:(id<NSCopying>)key{
    [self lock];
    [self.storeData removeObjectForKey:key];
    NSInteger count = self.storeData.count;
    if (_storeCount > 0 && count==0) {
        [self removeIfNeed];
    }
    _storeCount = count;
    [self unlock];
}



- (BOOL)containObjectForKey:(id<NSCopying>)key{
    [self lock];
    BOOL isContain = [self.storeData objectForKey:key];
    [self unlock];
    return isContain;
}

- (void)storeIfNeed{
    if (_observerCount > 0 || _storeCount > 0) {
        [self store];
    }
}

- (void)removeIfNeed{
    if (_observerCount == 0 && _storeCount == 0) {
        [self remove];
    }
}

- (NSMutableDictionary *)storeData{
    if (!_storeData) {
        _storeData = [NSMutableDictionary dictionary];
    }
    return _storeData;
}

- (DPLevelSearch *)levelSearch{
    if (!_levelSearch) {
        _levelSearch = [DPLevelSearch new];
    }
    return _levelSearch;
}

@end

@implementation DPBaseRoute (LifeCircyle)

- (void)store{
    if (_isStore) return;
    [[[DPRouter router] schemeWithName:@"kdp_global_scheme"] addRoute:self];
}

- (void)addToCurentSchemeHandle:(void (^)(DPRouteScheme * _Nonnull, DPBaseRoute * _Nonnull))handle{
    DPRouteScheme *routeScheme = [[DPRouter router] currentScheme];
    if (_isStore) {
        [self remove];
    }
    if (handle) {
        handle(routeScheme,self);
    }
    self.scheme = routeScheme;
    [routeScheme addRoute:self];
    _isStore = YES;
}

- (void)addToScheme:(NSString *)scheme handle:(nonnull void (^)(DPRouteScheme * _Nonnull, DPBaseRoute * _Nonnull))handle{
    DPRouteScheme *routeScheme = [[DPRouter router] schemeWithName:scheme];
    if (_isStore) {
        [self remove];
    }
    if (handle) {
        handle(routeScheme,self);
    }
    self.scheme = routeScheme;
    [routeScheme addRoute:self];
    _isStore = YES;
}

- (void)remove{
    if (!_isStore) return;
    _isStore = NO;
    if (self.dismiss) {
        self.dismiss(self);
    }
    [[[DPRouter router] schemeWithName:self.currentScheme] removeRoute:self];
}

- (void)setDismiss:(void (^)(DPBaseRoute * _Nonnull))dismiss{
    objc_setAssociatedObject(self, @selector(dismiss), dismiss, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(DPBaseRoute * _Nonnull))dismiss{
    return objc_getAssociatedObject(self, @selector(dismiss));
}
- (void)setCache:(DPRouterObjectCache *)cache{
    if (!_weakObject) {
        _weakObject = [DPRouteWeakObject new];
    }
    _weakObject.obj = cache;
}

- (DPRouterObjectCache *)cache{
    return _weakObject.obj;
}
@end




