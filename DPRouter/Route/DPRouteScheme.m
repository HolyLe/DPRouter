//
//  DPRouteScheme.m
//  DiamondPark
//
//  Created by 麻小亮 on 2019/5/5.
//  Copyright © 2019 DiamondPark. All rights reserved.
//

#import "DPRouteScheme.h"
#import "DPRouter+Private.h"

@interface DPRouteSchemeNode : NSObject{
    @package
    __unsafe_unretained DPRouteSchemeNode *_preNode;
    __unsafe_unretained DPRouteSchemeNode *_nextNode;
    id _key;
    __unsafe_unretained DPBaseRoute * _value;
}
@end

@implementation DPRouteSchemeNode
@end

@interface DPRouteSchemeNodeMap : NSObject{
    @package
    CFMutableDictionaryRef _dic;
    DPRouteSchemeNode *_head;
    DPRouteSchemeNode *_tail;
}

@end

@implementation DPRouteSchemeNodeMap

- (void)addNodeToHead:(DPRouteSchemeNode *)node{
    CFDictionarySetValue([self dic], (__bridge void *)node->_key, (__bridge void *)node);
    [[DPRouter router] storeRoute:node->_value];
    if (!_head) {
        _head = node;
    }
    if (!_tail) {
        _tail = node;
    }
}

- (void)bringNodeToHead:(DPRouteSchemeNode *)node{
    if (_head == node) return;
    if (_head) {
        _head->_preNode = node;
        if (node->_nextNode) {
            node->_nextNode->_preNode = node->_preNode;
        }
        if (node->_preNode) {
            node->_preNode->_nextNode = node->_nextNode;
        }
        node->_nextNode = _head;
        node->_preNode = nil;
    }
    _head = node;
}

- (void)removeNode:(DPRouteSchemeNode *)node{
    if (!_head) return;
    if (node->_preNode) {
        if (node->_nextNode) {
            node->_nextNode->_preNode = node->_preNode;
            node->_preNode->_nextNode = node->_nextNode;
        }else{
            node->_preNode->_nextNode = nil;
            _tail = node->_preNode;
        }
    }else{
        if (node->_nextNode) {
            node->_nextNode->_preNode = nil;
            _head = node->_nextNode;
        }
    }
    CFDictionaryRemoveValue(_dic, (__bridge void *)node->_key);
    if (CFDictionaryGetCount(_dic)==0) {
        _head = nil;
        _tail = nil;
    }
    [[DPRouter router] removeRoute:node->_value];
    node->_value = nil;
}


- (CFMutableDictionaryRef)dic{
    if (!_dic) {
        _dic =  CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    }
    return _dic;
}

- (DPRouteSchemeNode *)getNodeByRoute:(DPBaseRoute *)route{
    if (!_dic) return nil;
    return (DPRouteSchemeNode *)CFDictionaryGetValue(_dic, (__bridge void *)route.uniqueIdentify);
}

- (DPRouteSchemeNode *)createNodeByRoute:(DPBaseRoute *)route{
    DPRouteSchemeNode *node = [DPRouteSchemeNode new];
    node->_key = route.uniqueIdentify;
    node->_value = route;
    return node;
}

@end

@interface DPRouteScheme ()
@property (nonatomic, copy) void (^showEvent) (DPRouteScheme *scheme);
@property (nonatomic, copy) void (^dismissEvent) (DPRouteScheme *scheme);
@property (nonatomic, strong) DPRouteSchemeNodeMap * map;
@end

@implementation DPRouteScheme

- (void)bindShow:(void (^)(DPRouteScheme * _Nonnull))show disappear:(void (^)(DPRouteScheme * _Nonnull))disappear{
    self.showEvent = show;
    self.dismissEvent = disappear;
}

- (void)setCurrentScheme{
    if ([[DPRouter router] currentScheme] == self) return;
    [[[DPRouter router] currentScheme] dismissAppear];
    [[DPRouter router] setCurrentScheme:self];
    [[[DPRouter router] currentScheme] show];
}

- (void)addRoute:(DPBaseRoute *)route{
    DPRouteSchemeNode *node = [self.map getNodeByRoute:route];
    if (!node) {
        node = [self.map createNodeByRoute:route];
        [self.map addNodeToHead:node];
    }
    [self.map bringNodeToHead:node];
}

- (void)removeRoute:(DPBaseRoute *)route{
    DPRouteSchemeNode *node = [self.map getNodeByRoute:route];
    if (node) {
        [self.map removeNode:node];
    }
}

- (void)removeLastRoute{
    [self.map removeNode:self.map->_tail];
}

- (void)removeFromHeadRoute{
    DPRouteSchemeNode *node = self.map->_head->_nextNode;
    while (node==self.map->_head) {
        [self.map removeNode:node];
        node = node->_nextNode;
    }
}

- (void)removeFromAllRoute{
    DPRouteSchemeNode *node = self.map->_head;
    while (node) {
        [self.map removeNode:node];
        node = node->_nextNode;
    }
}

- (void)replaceFromLastRoute:(DPBaseRoute *)route{
    [self removeLastRoute];
    [self addRoute:route];
}

- (void)replaceFromAllRoute:(DPBaseRoute *)route{
    [self removeFromAllRoute];
    [self addRoute:route];
}

- (void)replaceFromHeadRoute:(DPBaseRoute *)route{
    [self removeFromHeadRoute];
    [self addRoute:route];
}

- (void)bringRouteToHead:(DPBaseRoute *)route{
    [self addRoute:route];
}

- (void)show{
    if (self.showEvent) {
        self.showEvent(self);
    }
}

- (void)dismissAppear{
    if (_map) {
        DPRouteSchemeNode *node = _map->_head;
        while (node) {
            node = node->_nextNode;
        }
    }
    if (self.dismissEvent) {
        self.dismissEvent(self);
    }
}

- (DPRouteSchemeNodeMap *)map{
    if (!_map) {
        _map = [DPRouteSchemeNodeMap new];
    }
    return _map;
}

@end
