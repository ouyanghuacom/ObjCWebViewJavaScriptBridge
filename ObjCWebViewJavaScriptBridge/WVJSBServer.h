//
//  WVJSBServer.h
//  ObjCWebViewJavaScriptBridge
//
//  Created by ouyanghuacom on 2019/12/26.
//  Copyright © 2019 ouyanghuacom. All rights reserved.
//

@import Foundation;

@class WVJSBHandler;

NS_ASSUME_NONNULL_BEGIN

@interface WVJSBServer : NSObject

+ (instancetype)serverWithWebView:(id)webView ns:(NSString* _Nullable)ns NS_SWIFT_NAME(init(webView:ns:));

+ (BOOL)canHandleWithWebView:(id)webView URLString:(NSString*_Nullable)URLString NS_SWIFT_NAME(canHandle(webView:URLString:));

- (WVJSBHandler *)on:(NSString*)type;

@end

NS_ASSUME_NONNULL_END
