//
//  WVJSBServer.m
//  ObjCWebViewJavaScriptBridge
//
//  Created by ouyanghuacom on 2019/12/26.
//  Copyright © 2019 ouyanghuacom. All rights reserved.
//

#if TARGET_OS_IOS
@import UIKit;
#endif

@import WebKit;

#import "WVJSBMessage.h"
#import "WVJSBServer.h"
#import "WVJSBConnection+Private.h"
#import "WVJSBHandler+Private.h"
#import "WVJSBScriptMessageHandler.h"

static NSString * const WVJSBQueryFormat = @";(function(){try{return window['wvjsb_proxy_%@'].query();}catch(e){return '[]'};})();";

static NSString * const WVJSBSendFormat  = @";(function(){try{return window['wvjsb_proxy_%@'].send('%@');}catch(e){return ''};})();";

static inline NSString *WVJSBEscapedJSString(NSString *v){
    NSMutableString *s = [NSMutableString stringWithCapacity:v.length];
    for (NSUInteger i = 0,len = v.length;i<len;i++){
        unichar c = [v characterAtIndex:i];
        switch (c) {
            case '\\':
                [s appendString:@"\\\\"];
                break;
            case '\'':
                [s appendString:@"\\'"];
                break;
            case '"':
                [s appendString:@"\\\""];
                break;
            default:
                [s appendString:[NSString stringWithCharacters:&c length:1]];
                break;
        }
    }
    [s replaceOccurrencesOfString:@"\u2028" withString:@"\\u2028" options:0  range:NSMakeRange(0, s.length)];
    [s replaceOccurrencesOfString:@"\u2029" withString:@"\\u2029" options:0  range:NSMakeRange(0, s.length)];
    return s;
}


@interface WVJSBServer ()

@property (nonatomic,copy  ) NSString *ns;
@property (nonatomic,copy  ) NSString *proxy;
@property (nonatomic,copy  ) NSString *installJS;
@property (nonatomic,copy  ) NSString *safeToken;

@property (nonatomic,strong) NSMutableDictionary<NSString*,WVJSBConnection*> *connections;
@property (nonatomic,strong) NSMutableDictionary<NSString*,WVJSBHandler*> *handlers;
@property (nonatomic,strong) NSMutableDictionary<NSString*,void(^)(void)> *cancelBlocks;
@property (nonatomic,copy  ) void(^evaluate)(NSString *js,void(^completionHandler)(id result));

@end

@implementation WVJSBServer

+ (BOOL)canHandleWithWebView:(id)webView URLString:(NSString*_Nullable)URLString {
    static NSRegularExpression *canHandleRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        canHandleRegex = [NSRegularExpression regularExpressionWithPattern:@"^https://wvjsb/([^/]+)/([^/]+)$" options:0 error:nil];
    });
    NSTextCheckingResult *result = [canHandleRegex firstMatchInString:URLString options:0 range:NSMakeRange(0, URLString.length)];
    if (!result) return NO;
    NSString *ns = [URLString substringWithRange:[result rangeAtIndex:1]];
    WVJSBServer *server = [self serverWithWebView:webView ns:ns createIfNotExist:NO];
    if (!server) return YES;
    NSString *action = [URLString substringWithRange:[result rangeAtIndex:2]];
    if ([action isEqualToString:@"install"]) [server install];
    else if([action isEqualToString:@"query"]) [server query];
    return YES;
}

+ (instancetype)serverWithWebView:(id)webView ns:(NSString* _Nullable)ns{
    return [self serverWithWebView:webView ns:ns createIfNotExist:YES];
}

+ (instancetype)serverWithWebView:(id)webView ns:(NSString* _Nullable)ns createIfNotExist:(BOOL)createIfNotExist{
    static dispatch_semaphore_t lock;
    static NSMapTable<id,NSMutableDictionary*> *serversByWebView;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lock = dispatch_semaphore_create(1);
        serversByWebView = [NSMapTable weakToStrongObjectsMapTable];
    });
    if (ns.length == 0){
        ns = @"wvjsb_namespace";
    }
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    NSMutableDictionary *serversByName = [serversByWebView objectForKey:webView];
    if (!serversByName){
        serversByName = [NSMutableDictionary dictionary];
        [serversByWebView setObject:serversByName forKey:webView];
    }
    WVJSBServer *server = serversByName[ns];
    if (server)  {
        dispatch_semaphore_signal(lock);
        return server;
    }
    if (!createIfNotExist){
        dispatch_semaphore_signal(lock);
        return server;
    }
    server = [[self alloc]initWithWebView:webView ns:ns];
    serversByName[ns] = server;
    dispatch_semaphore_signal(lock);
    return server;
}

- (instancetype)initWithWebView:(id)webView ns:(NSString*)ns{
    self = [super init];
    if (!self) return nil;
    if (ns.length == 0) {
        NSParameterAssert(0);
        return nil;
    }
    self.ns = ns;
    self.proxy = [NSString stringWithFormat:@"wvjsb_proxy_%@",ns];
    self.connections = [NSMutableDictionary dictionary];
    self.handlers = [NSMutableDictionary dictionary];
    self.cancelBlocks = [NSMutableDictionary dictionary];
    if (![self initializeEvaluationWithWebView:webView]) {
        NSParameterAssert(0);
        return nil;
    }
    return self;
}

- (void)install{
    self.evaluate(self.installJS,nil);
}

- (void)query{
    __weak typeof(self) weakSelf = self;
     self.evaluate([NSString stringWithFormat:WVJSBQueryFormat,self.ns], ^(id result) {
         __strong typeof(weakSelf) self = weakSelf;
         if ([result length] == 0) return;
         NSError *error;
         NSArray *messages = [NSJSONSerialization JSONObjectWithData:[result dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
         if (error){
             NSParameterAssert(0);
             return;
         }
         [messages enumerateObjectsUsingBlock:^(NSString *_Nonnull JSONString, NSUInteger idx, BOOL * _Nonnull stop) {
             [self handleMessage:({
                 [[WVJSBMessage alloc]initWithJSONString:JSONString];
             })];
         }];
     });
}

- (WVJSBHandler *)on:(NSString*)type{
    @synchronized (self.handlers) {
         WVJSBHandler *handler = self.handlers[type];
         if (handler) {
             return handler;
         }
         handler = [[WVJSBHandler alloc]init];
         self.handlers[type] = handler;
         return handler;
     }
}

- (void)sendMessage:(WVJSBMessage*)message completion:(void(^)(BOOL success))completion{
    NSString *JSONString = [message JSONString];
    if (!JSONString){
        NSParameterAssert(0);
        if(completion) completion(NO);
        return;
    }
    self.evaluate([NSString stringWithFormat:WVJSBSendFormat,self.ns,WVJSBEscapedJSString(JSONString)],^(id result){
        if(completion) completion([result length]>0);
    });
}

- (void)handleMessage:(WVJSBMessage *)message{
    if (!message){
        NSParameterAssert(0);
        return;
    }
    NSString *to   = message.to;
    NSString *from = message.from;
    NSString *type = message.type;
    if (from.length == 0){
        return;
    }
    if (type.length == 0){
        return;
    }
    if (![self.ns isEqualToString:to]) {
        return;
    }
    NSString *mid = message.mid;
    id parameter  = message.parameter;
    id exception  = message.exception;
    if ([self.proxy isEqualToString:from]){
        //window did unload
        if ([@"disconnect" isEqualToString:type]){
            WVJSBHandler *handler;
            @synchronized (self.handlers) {
                handler = self.handlers[@"disconnect"];
            }
            @synchronized (self.connections) {
                if (handler) [self.connections enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, WVJSBConnection * _Nonnull connection, BOOL * _Nonnull stop) {
                            handler.eventBlock(connection, nil, ^WVJSBAckBlock _Nonnull{
                                return ^(id result, id exception){};
                            });
                    }];
                [self.connections removeAllObjects];
            }
        }
        return;
    }
    
    if ([@"disconnect" isEqualToString:type]){
        WVJSBConnection *connection;
        @synchronized (self.connections) {
            connection = self.connections[from];
            if (!connection) return;
            self.connections[from] = nil;
        }
        WVJSBHandler *handler;
        @synchronized (self.handlers) {
            handler = self.handlers[type];
        }
        if (handler) handler.eventBlock(connection, nil, ^WVJSBAckBlock _Nonnull{
                return ^(id result, id exception){};
            });
        return;
    }
    __weak typeof(self) weakSelf = self;
    if ([@"connect" isEqualToString:type]){
        __strong typeof(weakSelf) self = weakSelf;
        WVJSBConnection *connection;
        @synchronized (self.connections) {
            connection = self.connections[from];
            if (connection) return;
            connection = ({
                WVJSBConnection *v = [[WVJSBConnection alloc]initWithInfomation:parameter];
                v;
            });
            self.connections[from] = connection;
        }
        __weak typeof(connection) weakConnection = connection;
        connection.sendBlock = ^(NSString *mid, NSString *type, id parameter) {
            __strong typeof(weakSelf) self = weakSelf;
            [self sendMessage:({
                WVJSBMessage *v = [[WVJSBMessage alloc]init];
                v.mid = mid;
                v.from = self.ns;
                v.to = from;
                v.type = type;
                v.parameter = parameter;
                v;
            }) completion:^(BOOL success) {
                if (success) return;
                __strong typeof(weakConnection) connection = weakConnection;
                connection.receiveBlock(mid, nil, @"connection lost");
            }];
        };
        [connection event:@"connect" parameter:nil];
        WVJSBHandler *handler;
        @synchronized (self.handlers) {
            handler = self.handlers[type];
        }
        if (handler) handler.eventBlock(connection, nil, ^WVJSBAckBlock _Nonnull{
                return ^(id result, id exception){};
            });
        return;
    }
    
    if ([@"ack" isEqualToString:type]){
        WVJSBConnection *connection;
        @synchronized (self.connections) {
            connection = self.connections[from];
        }
        if (!connection) return;
        connection.receiveBlock(mid, parameter, exception);
        WVJSBHandler *handler;
        @synchronized (self.handlers) {
            handler = self.handlers[type];
        }
        if (handler) handler.eventBlock(connection, nil, ^WVJSBAckBlock _Nonnull{
                return ^(id result, id exception){};
            });
        return;
    }
    NSString *cancelId = [NSString stringWithFormat:@"%@-%@",from, mid];
    if ([@"cancel" isEqualToString:type]){
        void(^cancelBlock)(void);
        @synchronized (self.cancelBlocks) {
            cancelBlock = self.cancelBlocks[cancelId];
        }
        if (!cancelBlock) return;
        cancelBlock();
        return;
    }
    WVJSBHandler *handler;
    @synchronized (self.handlers) {
        handler = self.handlers[type];
    }
    if (!handler) return;
    WVJSBConnection *connection;
    @synchronized (self.connections) {
        connection = self.connections[from];
    }
    id context;
    if (handler.eventBlock){
        context = handler.eventBlock(connection, message.parameter, ^{
            __strong typeof(weakSelf) self = weakSelf;
            @synchronized (self.cancelBlocks) {
                self.cancelBlocks[cancelId] = nil;
            }
            return ^(id result, id exception) {
                __strong typeof(weakSelf) self = weakSelf;
                [self sendMessage:({
                    WVJSBMessage *v = [[WVJSBMessage alloc]init];
                    v.mid = mid;
                    v.type = @"ack";
                    v.from = self.ns;
                    v.to = from;
                    v.parameter = result;
                    v.exception = exception;
                    v;
                }) completion:nil];
            };
        });
    }
    if (handler.cancelBlock) {
        @synchronized (self.cancelBlocks) {
            self.cancelBlocks[cancelId] = ^(){
                handler.cancelBlock(context);
                __strong typeof(weakSelf) self = weakSelf;
                self.cancelBlocks[cancelId] = nil;
            };
        }
    }
}

- (BOOL)initializeEvaluationWithWebView:(id)webView{
    __weak typeof(webView) weakWebView = webView;
#if TARGET_OS_OSX
    if ([webView isKindOfClass:WebView.class]){
        self.evaluate = ^(NSString *js, void (^completionHandler)(id result)) {
            if ([NSThread isMainThread]){
                __strong typeof(weakWebView) webView = weakWebView;
                id result = [(WebView*)webView stringByEvaluatingJavaScriptFromString:js];
                if(completionHandler) completionHandler(result);
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(weakWebView) webView = weakWebView;
                    id result = [(WebView*)webView stringByEvaluatingJavaScriptFromString:js];
                    if(completionHandler) completionHandler(result);
                });
            }
        };
        return YES;
    }
#elif !TARGET_OS_UIKITFORMAC
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        if ([webView isKindOfClass:UIWebView.class]){
            self.evaluate = ^(NSString *js, void (^completionHandler)(id result)) {
                if ([NSThread isMainThread]){
                    __strong typeof(weakWebView) webView = weakWebView;
                    id result = [(UIWebView*)webView stringByEvaluatingJavaScriptFromString:js];
                    if(completionHandler) completionHandler(result);
                }else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        __strong typeof(weakWebView) webView = weakWebView;
                        id result = [(UIWebView*)webView stringByEvaluatingJavaScriptFromString:js];
                        if(completionHandler) completionHandler(result);
                    });
                }
            };
            return YES;
        }
    #pragma clang diagnostic pop
#endif
    if ([webView isKindOfClass:WKWebView.class]){
        //        [[(WKWebView*)webView configuration].userContentController addUserScript:[[WKUserScript alloc]initWithSource:[[NSString stringWithContentsOfFile:[[NSBundle bundleForClass:WVJSBServer.class] pathForResource:@"Proxy" ofType:@"js"] encoding:NSUTF8StringEncoding error:nil] stringByReplacingOccurrencesOfString:@"wvjsb_namespace" withString:self.ns] injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES]];
        [[(WKWebView*)webView configuration].userContentController addScriptMessageHandler:[[WVJSBScriptMessageHandler alloc]init] name:self.ns];
        self.evaluate = ^(NSString *js, void (^completionHandler)(id result)) {
            if ([NSThread isMainThread]){
                __strong typeof(weakWebView) webView = weakWebView;
                [(WKWebView*)webView evaluateJavaScript:js completionHandler:^(id result, NSError * error) {
                    if(completionHandler) completionHandler(result);
                }];
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(weakWebView) webView = weakWebView;
                    [(WKWebView*)webView evaluateJavaScript:js completionHandler:^(id result, NSError * error) {
                        if(completionHandler) completionHandler(result);
                    }];
                });
            }
        };
        return YES;
    }
    return NO;
}

- (NSString*)installJS{
    if (_installJS) return _installJS;
    _installJS = [[NSString stringWithContentsOfFile:[[NSBundle bundleForClass:WVJSBServer.class] pathForResource:@"Proxy" ofType:@"js"] encoding:NSUTF8StringEncoding error:nil] stringByReplacingOccurrencesOfString:@"wvjsb_namespace" withString:self.ns];
    return _installJS;
}
@end
