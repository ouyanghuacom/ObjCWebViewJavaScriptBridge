//
//  WVJSBOperation.h
//  ObjCWebViewJavaScriptBridge
//
//  Created by ouyanghuacom on 2019/12/26.
//  Copyright © 2019 ouyanghuacom. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface WVJSBOperation : NSObject

- (WVJSBOperation*)onAck:(void(^)(WVJSBOperation *operation,id _Nullable result,id _Nullable exception))ack;

- (WVJSBOperation*)timeout:(NSTimeInterval)timeout;

- (void)cancel;

@end

NS_ASSUME_NONNULL_END
