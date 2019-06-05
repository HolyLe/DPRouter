//
//  DPRouter.m
//  DiamondPark
//
//  Created by 麻小亮 on 2019/5/5.
//  Copyright © 2019 DiamondPark. All rights reserved.
//

#import "DPRouter.h"
#import <objc/runtime.h>
#import "DPRouter+Private.h"

@interface DPRouteStatusObject : NSObject
@property (nonatomic, copy) void (^ isMakeChanged) (void);
@end
@implementation DPRouteStatusObject

@end

@interface DPLevelSearch ()
{
    NSMutableDictionary *_dic;
    NSMutableArray *_levels;
}
@end

@implementation DPLevelSearch

- (void)addLevel:(NSInteger)level withData:(id)data key:(NSString *)key{
    NSNumber *number = @(level);
    if (!_dic) {
        _dic  = [NSMutableDictionary dictionary];
    }
    NSMutableDictionary *levelDic = [_dic objectForKey:number];
    if (!levelDic) {
        levelDic = [NSMutableDictionary dictionary];
        [_dic setObject:levelDic forKey:number];
    }
    
    [levelDic setObject:data forKey: dp_getRoutePathComponents(dp_getRoutePaths(key))];
    if (!_levels) {
        _levels = [NSMutableArray array];
    }
    [_levels addObject:number];
    [_levels sortUsingComparator:^NSComparisonResult(NSNumber *  _Nonnull obj1, NSNumber *  _Nonnull obj2) {
        return [obj2 compare:obj1];
    }];
}


- (DPRouteTuple *)getDataWithKey:(NSArray *)keys key:(NSString *)key{
    NSInteger count = keys.count;
    NSInteger max = [[_levels firstObject] integerValue];
    if (count > max){
        count = max;
    }
    NSNumber *number = @(count);
    NSInteger levelCount = [_levels count];
    NSInteger index = [_levels indexOfObject:number];
    while (index < levelCount) {
        number = [_levels objectAtIndex:index];
        count = [number integerValue];
        NSDictionary *dic = [_dic objectForKey:number];
        NSString *targetKey = dp_getRoutePathComponents([keys subarrayWithRange:NSMakeRange(0, count)]);
        id data = [dic objectForKey:targetKey];
        if (data) {
            return [DPRouteTuple tupleWithObjects:data,targetKey,nil];
        }else{
            index++;
        }
    }
    return nil;
}

@end

@interface DPRouteMapLinkNode : NSObject
{
    @package
    NSString *_key;
    NSString *_nextNodeString;
    CFMutableArrayRef _preNodes;
    __unsafe_unretained DPRouteMapLinkNode *_nextNode;
    BOOL _isChanged;
    DPRouteStatusObject * _value;
    CFIndex _nextPreIndex;
}
@property (nonatomic, copy) DPRouteMapLinkNode * (^getNextNode) (NSString *key);
@end

@implementation DPRouteMapLinkNode

- (void)addPreNode:(DPRouteMapLinkNode *)node{
    if (!_preNodes) {
        CFArrayCallBacks backs = {0,NULL,NULL,CFCopyDescription,CFEqual};
        _preNodes = CFArrayCreateMutable(0, 0, &backs);
    }
    CFIndex count = CFArrayGetCount(self->_preNodes);
    if (CFArrayContainsValue(self->_preNodes, CFRangeMake(0, count), (__bridge void *)node)) return;
    node->_nextNodeString = _key;
    node->_nextPreIndex = count;
    CFArrayAppendValue(_preNodes, (__bridge void  *)node);
    if (_value&&!_isChanged) {
        node->_value = _value;
    }
}

- (void)removePreNode:(DPRouteMapLinkNode *)node{
    if (!_preNodes) return;
    CFArrayRemoveValueAtIndex(_preNodes, node->_nextPreIndex);
    node->_nextPreIndex = 0;
    node->_nextNodeString = nil;
}

- (void)addNextNode:(DPRouteMapLinkNode *)node{
    if (_nextNode) {
        _value = nil;
        [_nextNode removePreNode:self];
    }
    _nextNode = node;
    if (node->_value) {
        _value = node->_value;
    }
    
    [_nextNode addPreNode:self];
    [self sendMapChanged];
}

static void modelSetWithArrayFunction(const void *value,void *context){
    DPRouteMapLinkNode *object = (__bridge DPRouteMapLinkNode *)value;
    object->_isChanged = YES;
    object->_value = nil;
    [object sendMapChanged];
}

- (void)sendMapChanged{
    if (!_preNodes) return;
    CFArrayApplyFunction(_preNodes, CFRangeMake(0, CFArrayGetCount(_preNodes)), modelSetWithArrayFunction, NULL);
}

- (DPRouteStatusObject *)findValue{
    if (_value && !_isChanged) return _value;
    DPRouteMapLinkNode *node = _nextNode;
    if (!node && _nextNodeString.length > 0 && _getNextNode) {
        node = _getNextNode(_nextNodeString);
    }
    if (node) {
        _value = [node findValue];
    }
    _isChanged = NO;
    return _value;
}

@end

@protocol DPRouteMapLineGetProtocol <NSObject>

- (DPRouteStatusObject *)objectForKeyedSubscript:(NSString *)key;

@end
@interface DPRouteMapLinkMap : NSObject
@property (nonatomic, strong) DPLevelSearch * search;
@end

@implementation DPRouteMapLinkMap

- (void)addOriginalUrl:(NSString *)url mapUrl:(NSString *)mapUrl originalData:(id <DPRouteMapLineGetProtocol>)data{
    if (mapUrl.length == 0) {
        DPRouteStatusObject *object = data[url];
        if (!object) return;
        DPRouteMapLinkNode *node = [DPRouteMapLinkNode new];
        node->_key = url;
        node->_value = object;
        __weak typeof(node)weakNode = node;
        object.isMakeChanged = ^{
            __strong typeof(weakNode)node = weakNode;
            [node sendMapChanged];
        };
        [self addObjectNode:node url:url];
        return;
    }
    data = nil;
    DPRouteMapLinkNode *node = [_search getDataWithKey:dp_getRoutePaths(mapUrl) key:mapUrl].first;
    if (node) {
        if ([node->_nextNodeString isEqualToString:url]&&!node->_isChanged) return;
    }else{
        node = [DPRouteMapLinkNode new];
        node->_key = mapUrl;
        node->_nextNodeString = url;
        __weak typeof(self)weakSelf = self;
        node.getNextNode = ^DPRouteMapLinkNode *(NSString *key) {
            __strong typeof(weakSelf)self = weakSelf;
            DPRouteTuple *tuple = [self.search getDataWithKey:dp_getRoutePaths(key) key:key];
            if (tuple.count!=2) return nil;
            
            return tuple.first;
        };
    }
    DPRouteMapLinkNode *nextNode = [_search getDataWithKey:dp_getRoutePaths(url) key:url].first;
    if (nextNode){
        [node addNextNode:nextNode];
    }else{
        node->_nextNodeString = url;
    }
    [self addObjectNode:node url:mapUrl];
}

- (void)addObjectNode:(DPRouteMapLinkNode *)node url:(NSString *)url{
    NSArray *paths = dp_getRoutePaths(url);
    [self.search addLevel:paths.count withData:node key:url];
}

- (__kindof DPRouteTuple *)getObjectByUrl:(NSString *)url{
    DPRouteTuple *tuple = [self.search getDataWithKey:dp_getRoutePaths(url) key:url];
    if (!tuple) return nil;
    DPRouteMapLinkNode*node = tuple.first;
    id object = [node findValue];
    NSMutableArray *array = [NSMutableArray array];
    if (object) {
        [array addObject:object];
    }
    [array addObject:tuple.second];
    return [DPRouteTuple tupleWithArray:array];
}

- (DPLevelSearch *)search{
    if (!_search) {
        _search = [DPLevelSearch new];
    }
    return _search;
}

@end

@interface DPRouterObjectCache : DPRouteStatusObject

@property (nonatomic, strong) NSMutableDictionary * routes;

@property (nonatomic, copy) void (^ blank) (void);
@end

@implementation DPRouterObjectCache

- (void)addRoute:(id)object forKeyName:(NSString *)name{
    [self.routes setObject:object forKey:name];
}

- (id)getRouteByKey:(NSString *)key{
    return self.routes[key];
}
- (void)removeKey:(NSString *)key{
    [self.routes removeObjectForKey:key];
    if (self.routes.count == 0) {
        if (self.blank) {
            _blank();
        }
    }
}

- (NSMutableDictionary *)routes{
    if (!_routes) {
        _routes = [NSMutableDictionary dictionary];
    }
    return _routes;
}

@end




@interface DPRouterRouteMapModel : DPRouteStatusObject
@property (nonatomic, copy) NSString * path;
@property (nonatomic, copy) NSArray * paths;
@property (nonatomic, strong) DPRouterObjectCache * cache;
@property (nonatomic, copy) NSString * routeName;
@end

@implementation DPRouterRouteMapModel
- (void)setCache:(DPRouterObjectCache *)cache{
    _cache = cache;
    __weak typeof(self)weakSelf = self;
    self.cache.blank = ^{
        weakSelf.isMakeChanged();
        weakSelf.cache = nil;
    };
}
@end
@interface DPRouterRouteMap : NSObject<DPRouteMapLineGetProtocol>
@property (nonatomic, strong) DPLevelSearch * search;
@end

@implementation DPRouterRouteMap

- (DPLevelSearch *)search{
    if (!_search) {
        _search = [DPLevelSearch new];
    }
    return _search;
}

- (DPRouterRouteMapModel *)objectForKey:(NSString *)key{
    return [self objectForPaths:dp_getRoutePaths(key)];
}
- (DPRouteStatusObject *)objectForKeyedSubscript:(NSString *)key{
    return [self objectForKey:key];
}
- (DPRouterRouteMapModel *)objectForPaths:(NSArray *)componets{
    NSInteger count = componets.count;
    if (count == 0) return nil;
    return [self.search getDataWithKey:componets key: dp_getRoutePathComponents(componets)].first;
    
}
- (void)setObject:(id)object forKey:(NSString *)key{
    NSArray *keys = dp_getRoutePaths(key);
    
    DPRouterRouteMapModel *model = [self objectForPaths:keys];
    //如果url_identify已存在，则不进行任何操作
    if (!model) {
        model = [DPRouterRouteMapModel new];
        model.path = key;
        model.paths = keys;
        model.routeName = object;
        [self.search addLevel:keys.count withData:model key:key];
    }
}
@end

@implementation NSObject (Route)

+ (void)load{
    [DPRouter router];
}

@end

@interface DPRouter ()

@property (nonatomic, strong) NSMutableDictionary <NSString *, DPRouterObjectCache *>* schemeMap;

@property (nonatomic, strong) DPRouterRouteMap * routeNameMap;

@property (nonatomic, strong) DPRouteScheme * currentScheme;

@property (nonatomic, strong) DPRouteMapLinkMap * mapChangeScheme;

@property (nonatomic, strong) DPRouteMapLinkMap * mapChangeUrl;

@property (nonatomic, strong) DPRouteScheme * globalScheme;

@end

@implementation DPRouter

DPRouterRouteMap * initRouteMap(DPRouter *self){
    unsigned int count;
    Class *classes = objc_copyClassList(&count);
    DPRouterRouteMap *routeMap = [DPRouterRouteMap new];
    NSDate *date = [NSDate date];
    
    for (unsigned int i = 0; i< count; i++) {
        Class class = classes[i];
        Class cla = class;
        while (cla && cla != [NSObject class] && class!=[NSProxy class]) {
            if (cla == [DPBaseRoute class]) {
                NSString *identify = [class performSelector:@selector(url_identify)];
                if (identify.length > 0) {
                    [routeMap setObject:NSStringFromClass(class) forKey:identify];
                    [self.mapChangeUrl addOriginalUrl:identify mapUrl:@"" originalData:routeMap];
                }
                break;
            }
            cla = class_getSuperclass(cla);
        }
    }
    NSLog(@"耗时：：：：%f",[[NSDate date] timeIntervalSinceDate:date]);
    return routeMap;
}

+ (DPRouter *)router{
    static DPRouter *router = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        router = [DPRouter new];
        
    });
    return router;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _globalScheme = [DPRouteScheme new];
        _routeNameMap = initRouteMap(self);
    }
    return self;
}

- (DPRouteScheme *)schemeWithName:(NSString *)name{
    if (name.length == 0) return nil;
    DPRouteScheme *routeScheme = [self.schemeMap[name] getRouteByKey:name];
    if (!routeScheme) {
        DPRouteTuple *tuple = [self.mapChangeScheme getObjectByUrl:name];
        if (tuple.count == 2) {
            routeScheme = [[(DPRouterObjectCache *)tuple.first routes].allValues firstObject];
        }
    }
    return routeScheme;
}

- (void)registerScheme:(NSString *)scheme handle:(void (^)(DPRouteScheme * _Nonnull))handle{
    DPRouterObjectCache *cache = [self.schemeMap objectForKey:scheme];
    if (!cache) {
        cache = [DPRouterObjectCache new];
        [self.schemeMap setObject:cache forKey:scheme];
        [self.mapChangeScheme addOriginalUrl:scheme mapUrl:@"" originalData:self.schemeMap.copy];
    }
    DPRouteScheme *routeScheme = [DPRouteScheme new];
    routeScheme.name = scheme;
    if (handle) {
        handle(routeScheme);
    }
    [cache addRoute:routeScheme forKeyName:scheme];
}

- (void)changeRouteScheme:(NSString *)scheme handle:(void (^)(DPRouteScheme * _Nonnull))handle{
    DPRouteScheme *routeScheme = [self schemeWithName:scheme];
    if (!routeScheme) return;
    [routeScheme setCurrentScheme];
}

- (void)deleteRouteScheme:(NSString *)scheme ifNeedInstead:(nonnull NSString *)needScheme{
    DPRouteScheme *routeScheme = [self schemeWithName:scheme];
    if (!routeScheme) return;
    if (routeScheme == self.currentScheme) {
        DPRouteScheme *routeReplaceScheme = [self schemeWithName:needScheme];
        if (!routeReplaceScheme) return;
        [routeReplaceScheme setCurrentScheme];
    }
    self.schemeMap[scheme].isMakeChanged();
    [self.schemeMap removeObjectForKey:scheme];
}

- (void)openRouteUrl:(NSString *)url{
    [self openRouteUrl:url withPara:@{}];
}

- (void)openRouteUrl:(NSString *)url withPara:(NSDictionary *)dic{
    DPRouteParsing * _parsing = [[DPRouteParsing alloc] initWithUrlString:url];
    if (dic) {
        [_parsing.parameters addEntriesFromDictionary:dic];
    }
    DPRouteScheme *scheme = [self schemeWithName:_parsing.scheme];
    if (!scheme) {
        scheme = self.currentScheme;
        if (_parsing.scheme) {
            [_parsing reloadPaths:[@[_parsing.scheme] arrayByAddingObjectsFromArray:_parsing.paths]];
        }
    }
    [scheme setCurrentScheme];
    [self openParsing:_parsing];
}

- (DPBaseRoute *)getRouteByParsing:(DPRouteParsing *)parsing{
    //先去routeNameMap查询原始的路路由数据
    DPRouterRouteMapModel *model = [self.routeNameMap objectForPaths:parsing.paths];
    NSString *key;
    if (!model){ //如果查询结果是nil，则去映射⾥里里⾯面查找
        DPRouteTuple *tuple = [self.mapChangeUrl getObjectByUrl:parsing.pathComponents];
        model = tuple.first;
        key = tuple.last;
    }
    //如果为空返回
    if (!model) {
        if (self.unParsingUrl) {
            if (!self.unParsingUrl(parsing, nil, DPRouteUnPatsingUrlErrorTypeClass))
                NSAssert(0, @"%@ not Find Route", parsing);
        }
        return nil;
    }
    DPRouterObjectCache *cache = model.cache;
    if (!cache) {
        cache = [DPRouterObjectCache new];
        model.cache = cache;
    }
    DPBaseRoute *route;
    Class class = NSClassFromString(model.routeName);
    
    NSString *primaryKey = [class performSelector:@selector(getRoutePrimaryKey:) withObject:parsing.parameters]?:@"";
    //cache查询路路由业务是否已存在，不不存在创建
    route = [cache getRouteByKey:primaryKey]; if (!route) {
        route = [class new];
        route.cache = cache;
    }
    NSInteger count = (key? dp_getRoutePaths(key):model.paths).count; //更更新解析数据，去除已解析的数据
    [parsing reloadPaths:[parsing.paths subarrayWithRange:NSMakeRange(count, parsing.paths.count - count)]];
    return route;
}




- (DPBaseRoute *)routeWithUrl:(NSString *)url{
    return [self getRouteByParsing:[[DPRouteParsing alloc]initWithUrlString:url]];
}



- (NSMutableDictionary *)schemeMap{
    if (!_schemeMap) {
        _schemeMap = [NSMutableDictionary dictionary];
    }
    return _schemeMap;
}

- (DPRouteMapLinkMap *)mapChangeUrl{
    if (!_mapChangeUrl) {
        _mapChangeUrl = [DPRouteMapLinkMap new];
    }
    return _mapChangeUrl;
}

- (DPRouteMapLinkMap *)mapChangeScheme{
    if (!_mapChangeScheme) {
        _mapChangeScheme = [DPRouteMapLinkMap new];
    }
    return _mapChangeScheme;
}

- (void)routeMapOriginalUrl:(NSString *)originalUrl map:(NSString *)mapUrl{
    [self.mapChangeUrl addOriginalUrl:originalUrl mapUrl:mapUrl originalData:self.routeNameMap];
}

- (void)routeMapOriginalScheme:(NSString *)originalScheme map:(NSString *)mapScheme{
    [self.mapChangeScheme addOriginalUrl:originalScheme mapUrl:mapScheme originalData:(id<DPRouteMapLineGetProtocol>)self.schemeMap];
}


@end
@implementation DPRouter (Private)

- (void)removeRoute:(DPBaseRoute *)route{
    [route.cache removeKey:route.primaryKey];
}

- (void)storeRoute:(DPBaseRoute *)route{
    [route.cache addRoute:route forKeyName:route.primaryKey];
}

- (void)openParsing:(nonnull DPRouteParsing *)parsing{
    [[self getRouteByParsing:parsing] openUrl:parsing.pathComponents para:parsing.parameters hanle:^(BOOL openSuccess, DPRouteTuple * _Nonnull tuple) {
        
    }];
}
@end

