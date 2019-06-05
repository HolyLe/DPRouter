//
//  DPRouteParsing.h
//  DiamondPark
//
//  Created by 麻小亮 on 2019/5/6.
//  Copyright © 2019 DiamondPark. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class DPBaseRoute;
@interface DPRouteParsing : NSObject
- (instancetype)initWithUrlString:(NSString *)url;
- (instancetype)initWithUrl:(NSURL *)url;

@property (nonatomic, copy, readonly) NSString * url;
@property (nonatomic, copy, readonly) NSString * scheme;
@property (nonatomic, copy, readonly) NSString * pathComponents;
@property (nonatomic, copy, readonly) NSArray * paths;
@property (nonatomic, copy, readonly) NSString * parameterString;
@property (nonatomic, strong, readonly) NSMutableDictionary * parameters;

- (void)reloadPaths:(NSArray *)paths;

@end

NS_ASSUME_NONNULL_END
