//
//  WVJSBConnection.m
//  ObjCWebViewJavaScriptBridge
//
//  Created by ouyanghuacom on 2019/12/26.
//  Copyright © 2019 ouyanghuacom. All rights reserved.
//

#import <stdatomic.h>

#import "WVJSBConnection.h"
#import "WVJSBOperation+Private.h"

@interface WVJSBConnection ()
{
    _Atomic(long long) _nextSeq;
}
@property (nonatomic, strong) id connectionInfomation;
@property (nonatomic, strong) NSMutableDictionary<NSString *, WVJSBOperation *> *operations;
@property (nonatomic, copy  ) void(^sendBlock)(NSString *mid,NSString *type,id _Nullable parameter);
@property (nonatomic, copy  ) void(^receiveBlock)(NSString *mid, id _Nullable result, id _Nullable exception);

@end

@implementation WVJSBConnection

- (void)dealloc{
   @synchronized (self.operations) {
       [self.operations enumerateKeysAndObjectsUsingBlock:^(NSString *key, WVJSBOperation *operation, BOOL *stop) {
           [operation ack:nil exception:@"connectionlost"];
       }];
   }
}

- (instancetype)initWithInfomation:(id)infomation{
    self = [super init];
    if (!self) return nil;
    self.connectionInfomation = infomation;
    self.operations = [NSMutableDictionary dictionary];
    __weak typeof(self) weakSelf = self;
    self.receiveBlock = ^(NSString *mid, id  _Nullable result,id _Nullable exception) {
        __strong typeof(weakSelf) self = weakSelf;
        @synchronized (self) {
             WVJSBOperation *operation = self.operations[mid];
             if (!operation) return;
             [operation ack:result exception:exception];
         }
    };
    return self;
}

- (WVJSBOperation *)event:(NSString*)type parameter:(id _Nullable)parameter{
    NSString *mid = [NSString stringWithFormat:@"%lld",atomic_fetch_add(&_nextSeq, 1)];
    __weak typeof(self) weakSelf = self;
    WVJSBOperation *operation = [[WVJSBOperation alloc]init];
    operation.retainBlock = ^(WVJSBOperation *operation) {
        __strong typeof(weakSelf) self = weakSelf;
        @synchronized (self.operations) {
            self.operations[mid] = operation;
        }
    };
    operation.releaseBlock = ^(WVJSBOperation *operation) {
        __strong typeof(weakSelf) self = weakSelf;
        @synchronized (self.operations) {
            self.operations[mid] = nil;
        }
    };
    operation.didCancelBlock = ^(WVJSBOperation *operation){
        __strong typeof(weakSelf) self = weakSelf;
        self.sendBlock(mid, @"cancel", nil);
    };
    self.sendBlock(mid, type, parameter);
    return operation;
}

@end
