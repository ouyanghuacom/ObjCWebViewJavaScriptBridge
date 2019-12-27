//
//  WVJSBServer+Private.h
//  ObjCWebViewJavaScriptBridge
//
//  Created by ouyanghuacom on 2019/12/26.
//  Copyright © 2019 ouyanghuacom. All rights reserved.
//

#import "WVJSBServer.h"

@class WVJSBMessage;

NS_ASSUME_NONNULL_BEGIN

@interface WVJSBServer (Private)

+ (instancetype)serverWithWebView:(id)webView ns:(NSString* _Nullable)ns createIfNotExist:(BOOL)createIfNotExist;

- (instancetype)initWithWebView:(id)webView ns:(NSString*)ns;

- (void)install;

- (void)query;

- (void)handleMessage:(WVJSBMessage *)message;

@end

NS_ASSUME_NONNULL_END
