//
//  WVJSBConnection.h
//  ObjCWebViewJavaScriptBridge
//
//  Created by ouyanghuacom on 2019/12/26.
//  Copyright © 2019 ouyanghuacom. All rights reserved.
//

@import Foundation;

@class WVJSBOperation;

NS_ASSUME_NONNULL_BEGIN

@interface WVJSBConnection : NSObject

@property (nonatomic, strong, readonly, nullable) id connectionInfomation;

- (WVJSBOperation *)event:(NSString*)type parameter:(id _Nullable)parameter NS_SWIFT_NAME(event(type:parameter:));

@end

NS_ASSUME_NONNULL_END
