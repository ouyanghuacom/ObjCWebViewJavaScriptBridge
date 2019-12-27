//
//  WVJSBHandler.h
//  ObjCWebViewJavaScriptBridge
//
//  Created by ouyanghuacom on 2019/12/26.
//  Copyright © 2019 ouyanghuacom. All rights reserved.
//

@import Foundation;

@class WVJSBConnection;

typedef void (^WVJSBAckBlock)(id _Nullable result, id _Nullable exception);

NS_ASSUME_NONNULL_BEGIN

@interface WVJSBHandler : NSObject

- (WVJSBHandler *)onEvent:(id (^)(WVJSBConnection *connection, id _Nullable parameter, WVJSBAckBlock(^done)(void)))event;

- (WVJSBHandler *)onCancel:(void (^)(id context))cancel;

@end

NS_ASSUME_NONNULL_END
