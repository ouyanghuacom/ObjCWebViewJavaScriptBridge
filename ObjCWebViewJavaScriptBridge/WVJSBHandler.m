//
//  WVJSBHandler.m
//  ObjCWebViewJavaScriptBridge
//
//  Created by ouyanghuacom on 2019/12/26.
//  Copyright © 2019 ouyanghuacom. All rights reserved.
//

#import "WVJSBHandler.h"

@interface WVJSBHandler ()

@property (nonatomic, copy) id (^eventBlock)(WVJSBConnection *connection, id _Nullable parameter, WVJSBAckBlock(^done)(void));
@property (nonatomic, copy) void (^cancelBlock)(id context);

@end

@implementation WVJSBHandler

- (WVJSBHandler *)onEvent:(id (^)(WVJSBConnection *connection, id _Nullable parameter, WVJSBAckBlock(^done)(void)))event{
    self.eventBlock = event;
    return self;
}

- (WVJSBHandler *)onCancel:(void (^)(id context))cancel{
    self.cancelBlock = cancel;
    return self;
}

@end
