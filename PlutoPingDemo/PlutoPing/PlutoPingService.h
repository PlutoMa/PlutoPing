//
//  PlutoPingService.h
//  PlutoPingDemo
//
//  Created by Pluto on 2018/1/25.
//  Copyright © 2018年 Pluto. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const PltPingServiceFinishNotification;
extern NSString *const PltPingServiceResultKey;
extern NSString *const PltPingServiceResultSuccess;
extern NSString *const PltPingServiceResultFail;

@interface PlutoPingService : NSObject

+ (void)doInitWithAddress:(NSString *)address;

+ (void)configTimeout:(NSTimeInterval)timeout;

+ (void)start;

@end
