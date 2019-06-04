//
//  DPRouteParsing.m
//  DiamondPark
//
//  Created by 麻小亮 on 2019/5/6.
//  Copyright © 2019 DiamondPark. All rights reserved.
//

#import "DPRouteParsing.h"

@interface DPRouteParsing ()
@property (nonatomic, copy) NSString * scheme;
@property (nonatomic, copy) NSString * pathComponents;
@property (nonatomic, copy) NSArray * paths;
@property (nonatomic, copy) NSString * parameterString;
@property (nonatomic, strong) NSDictionary * parameters;
@end
@implementation DPRouteParsing

- (instancetype)initWithUrl:(NSURL *)url{
    return [self initWithUrlString:url.absoluteString];
}

- (instancetype)initWithUrlString:(NSString *)url{
    if (self = [super init]) {
        [self parsing:url];
    }
    return self;
}

- (void)parsing:(NSString *)string{
    
    if ([string containsString:@"?"]) {
        NSArray *strings = [string componentsSeparatedByString:@"?"];
        string = [strings firstObject];
        if (string.length == 0) return;
        _parameterString = [strings lastObject];
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        NSArray *array = [_parameterString componentsSeparatedByString:@"&"];
        for (NSString*parameterString in array) {
            NSArray *para = [parameterString componentsSeparatedByString:@"="];
            [dic setValue:[para lastObject] forKey:[para firstObject]];
        }
        _parameters = dic.copy;
    }
    NSRange indexRange = [string rangeOfString:@"https://"];
    if (indexRange.location == NSNotFound) {
        indexRange = [string rangeOfString:@"http://"];
    }
    NSMutableArray *paths = [NSMutableArray array];
    if (indexRange.location != NSNotFound) {
        NSString *subString = [string substringFromIndex:indexRange.length + indexRange.location];
       NSArray *urlSubs = [subString componentsSeparatedByString:@"/"];
        if (urlSubs.count == 0) return;
        if ([[urlSubs firstObject] length]==0) return;
        _scheme = [[string substringWithRange:indexRange] stringByAppendingString:urlSubs.firstObject];
        [paths addObjectsFromArray: [urlSubs subarrayWithRange:NSMakeRange(1, urlSubs.count - 1)]];
    }else if ([string containsString:@"://"]){
        NSArray *com = [string componentsSeparatedByString:@"://"];
        if ([[com firstObject] length] > 0){
            _scheme = [[com firstObject] stringByAppendingString:@"://"];
        }
        if ([[com lastObject] length] == 0) return;
        [paths addObjectsFromArray: [[com lastObject] componentsSeparatedByString:@"/"]];
    }else{
        [paths addObjectsFromArray:[string componentsSeparatedByString:@"/"]];
    }
    if (paths.count > 0) {
        [paths removeObject:@""];
        if (paths.count == 0) return;
        _paths = [paths copy];
        _pathComponents = [_paths componentsJoinedByString:@"/"];
    }
}

- (void)reloadPaths:(NSArray *)paths{
    _paths = paths;
    _pathComponents = [paths componentsJoinedByString:@"/"];
}

- (NSString *)description
{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    dic[@"scheme"] = _scheme?:@"";
    dic[@"pathComponents"] = _pathComponents?:@"";
    dic[@"parameters"] = _parameters?:@{};
    return [NSString stringWithFormat:@"%@", dic.copy];
}
@end
