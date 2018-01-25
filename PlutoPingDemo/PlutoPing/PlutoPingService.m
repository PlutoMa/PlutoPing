//
//  PlutoPingService.m
//  PlutoPingDemo
//
//  Created by Pluto on 2018/1/25.
//  Copyright © 2018年 Pluto. All rights reserved.
//

#import "PlutoPingService.h"
#import "SimplePing.h"

NSString *const PltPingServiceFinishNotification = @"PltPingServerFinishNotification";
NSString *const PltPingServiceResultKey = @"PltPingServerResultKey";
NSString *const PltPingServiceResultSuccess = @"PltPingServerResultSuccess";
NSString *const PltPingServiceResultFail = @"PltPingServerResultFail";

static const NSUInteger maxFailCount = 2;

@interface PlutoPingService () <SimplePingDelegate>
@property (nonatomic, strong) SimplePing *simplePing;
@property (nonatomic, assign) BOOL haveStart;
@property (nonatomic, assign) NSTimeInterval timeout;
@property (nonatomic, assign) NSUInteger failCount;
@end

@implementation PlutoPingService

+ (void)doInitWithAddress:(NSString *)address {
    if (address == nil ||
        ([PlutoPingService sharedService].simplePing &&
         [[PlutoPingService sharedService].simplePing.hostName isEqualToString:address])) {
            return;
        }
    [PlutoPingService sharedService].simplePing = nil;
    [PlutoPingService sharedService].timeout = 1000;
    [PlutoPingService sharedService].failCount = 0;
    [PlutoPingService sharedService].simplePing = [[SimplePing alloc] initWithHostName:address];
    [PlutoPingService sharedService].haveStart = NO;
    [PlutoPingService sharedService].simplePing.delegate = [PlutoPingService sharedService];
}

+ (void)configTimeout:(NSTimeInterval)timeout {
    if ([PlutoPingService sharedService]) {
        [PlutoPingService sharedService].timeout = timeout;
    }
}

+ (void)start {
    if ([PlutoPingService sharedService].simplePing == nil ||
        [PlutoPingService sharedService].haveStart == YES) {
        return;
    }
    [PlutoPingService sharedService].haveStart = YES;
    [PlutoPingService sharedService].failCount = 0;
    [[PlutoPingService sharedService].simplePing start];
}


#pragma mark - private

static PlutoPingService *server = nil;
+ (instancetype)sharedService {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        server = [[PlutoPingService alloc] init];
    });
    return server;
}

- (void)failPing {
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(failPing) object:nil];
    if (self.simplePing.hostAddress && self.failCount < maxFailCount) {
        self.failCount++;
        [self.simplePing sendPingWithData:nil];
        [self performSelector:@selector(failPing) withObject:nil afterDelay:self.timeout / 1000.0];
    } else {
        [self stop];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:PltPingServiceFinishNotification object:nil userInfo:@{PltPingServiceResultKey : PltPingServiceResultFail}];
        });
    }
}

- (void)successPing {
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(failPing) object:nil];
    [self stop];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:PltPingServiceFinishNotification object:nil userInfo:@{PltPingServiceResultKey : PltPingServiceResultSuccess}];
    });
}

- (void)stop {
    [self.simplePing stop];
    self.haveStart = NO;
    self.failCount = 0;
}


#pragma mark - SimplePingDelegate

- (void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address {
    if (self.simplePing.hostAddress) {
        [pinger sendPingWithData:nil];
        [self performSelector:@selector(failPing) withObject:nil afterDelay:self.timeout / 1000.0];
    } else {
        [self failPing];
    }
}

- (void)simplePing:(SimplePing *)pinger didFailWithError:(NSError *)error {
    NSLog(@"%s  %d", __func__, __LINE__);
    if (self.failCount < maxFailCount) {
        self.failCount++;
        [pinger start];
    } else {
        [self failPing];
    }
}

- (void)simplePing:(SimplePing *)pinger didSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber {
    //Do Nothing
}

- (void)simplePing:(SimplePing *)pinger didFailToSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber error:(NSError *)error {
    NSLog(@"%s  %d", __func__, __LINE__);
    if (self.simplePing.hostAddress && self.failCount < maxFailCount) {
        self.failCount++;
        [pinger sendPingWithData:nil];
    } else {
        [self failPing];
    }
}

- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber {
    NSLog(@"%s  %d", __func__, __LINE__);
    [self successPing];
}

- (void)simplePing:(SimplePing *)pinger didReceiveUnexpectedPacket:(NSData *)packet {
    NSLog(@"%s  %d", __func__, __LINE__);
    if (self.simplePing.hostAddress && self.failCount < maxFailCount) {
        self.failCount++;
        [pinger sendPingWithData:nil];
    } else {
        [self failPing];
    }
}

@end
