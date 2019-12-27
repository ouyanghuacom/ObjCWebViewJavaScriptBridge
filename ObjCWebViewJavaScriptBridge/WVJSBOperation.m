//
//  WVJSBOperation.m
//  ObjCWebViewJavaScriptBridge
//
//  Created by ouyanghuacom on 2019/12/26.
//  Copyright © 2019 ouyanghuacom. All rights reserved.
//

#import "WVJSBOperation.h"

@interface WVJSBOperation()

@property (nonatomic,copy  ) void(^retainBlock)(WVJSBOperation *operation);
@property (nonatomic,copy  ) void(^releaseBlock)(WVJSBOperation *operation);
@property (nonatomic,copy  ) void(^didCancelBlock)(WVJSBOperation *oepration);
@property (nonatomic,copy  ) void(^ackBlock)(WVJSBOperation *operation,id result,id exception);
@property (nonatomic,strong) dispatch_source_t timer;
@property (nonatomic,assign) BOOL retained;
@property (nonatomic,assign) BOOL done;

@end

@implementation WVJSBOperation

- (WVJSBOperation*)onAck:(void(^)(WVJSBOperation *operation,id result,id exception))ack{
    @synchronized (self) {
        self.ackBlock = ack;
        if (self.done) {
            return self;
        }
        if (!self.retained){
            self.retained = YES;
            self.retainBlock(self);
        }
        return self;
    }
}

- (WVJSBOperation*)timeout:(NSTimeInterval)timeout{
    @synchronized (self) {
        if (self.done){
            return self;
        }
        if (!self.retained){
            self.retained = YES;
            self.retainBlock(self);
        }
        if (timeout <= 0) {
            NSParameterAssert(0);
            return self;
        }
        if (self.timer){
            dispatch_source_cancel(self.timer);
            self.timer = nil;
        }
        __weak typeof(self) weakSelf = self;
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(self.timer, dispatch_time(DISPATCH_TIME_NOW, timeout*NSEC_PER_SEC), DBL_MAX * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(self.timer, ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (self.done) return;
            self.done = YES;
            if (self.retained) self.releaseBlock(self);
            if (self.timer){
                dispatch_source_cancel(self.timer);
                self.timer = nil;
            }
            self.ackBlock(self, nil, @"timedout");
        });
        dispatch_resume(self.timer);
        return self;
    }
}

- (void)cancel{
    if (self.done) return;
    self.done = YES;
    self.releaseBlock(self);
    if (self.timer){
        dispatch_source_cancel(self.timer);
        self.timer = nil;
    }
    self.didCancelBlock(self);
    self.ackBlock(self, nil, @"cancelled");
}

- (void)ack:(id _Nullable)result exception:(id _Nullable)exception{
    @synchronized(self) {
        if (self.done) return;
        self.done = YES;
        self.releaseBlock(self);
        if (self.timer){
            dispatch_source_cancel(self.timer);
            self.timer = nil;
        }
        self.ackBlock(self, result, exception);
    }
}

@end
