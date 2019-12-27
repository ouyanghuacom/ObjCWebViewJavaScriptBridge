//
//  WVJSBScriptMessageHandler.m
//  ObjCWebViewJavaScriptBridge
//
//  Created by ouyanghuacom on 2019/12/26.
//  Copyright © 2019 ouyanghuacom. All rights reserved.
//

#import "WVJSBMessage.h"
#import "WVJSBScriptMessageHandler.h"
#import "WVJSBServer+Private.h"

@implementation WVJSBScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    [[WVJSBServer serverWithWebView:message.webView ns:message.name createIfNotExist:NO] handleMessage:({
        [[WVJSBMessage alloc]initWithJSONString:message.body];
    })];
}

@end
