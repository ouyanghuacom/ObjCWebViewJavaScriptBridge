//
//  ViewController.m
//  ObjCWebViewJavaScriptBridge Example macOS
//
//  Created by ouyanghuacom on 2019/12/26.
//  Copyright © 2019 ouyanghuacom. All rights reserved.
//

@import ObjCWebViewJavaScriptBridge;
@import WebKit;

#import "ViewController.h"

@interface ViewController () <WKNavigationDelegate>

@property (nonatomic,strong)WKWebView *webView;
@property (nonatomic,strong)NSMutableArray <WVJSBConnection *> *connections;
@property (nonatomic,strong)NSMutableArray <WVJSBOperation *> *operations;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.connections=[NSMutableArray array];
    self.operations=[NSMutableArray array];
    self.webView = ({
        WKWebView *v=[[WKWebView alloc]initWithFrame:CGRectZero configuration:[[WKWebViewConfiguration alloc]init]];
        v.enclosingScrollView.backgroundColor = [NSColor redColor];
        v.navigationDelegate = self;
        v;
    });
    [self.view addSubview:self.webView];
    self.webView.translatesAutoresizingMaskIntoConstraints=NO;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:88]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    WVJSBServer *server=[WVJSBServer serverWithWebView:self.webView ns:nil];
    [[server on:@"connect"] onEvent:^id (WVJSBConnection *connection, id parameter, WVJSBAckBlock (^done)(void)) {
        NSLog(@"%@ did connect",connection.connectionInfomation);
        @synchronized (self.connections) {
            [self.connections addObject:connection];
        }
        done();
        return nil;
    }];
    [[server on:@"disconnect"] onEvent:^id (WVJSBConnection *connection, id parameter, WVJSBAckBlock (^ done)(void)) {
        NSLog(@"%@ did disconnect",connection.connectionInfomation);
        @synchronized (self.connections) {
            [self.connections removeObject:connection];
        }
        done();
        return nil;
    }];
    [[server on:@"immediate"] onEvent:^id (WVJSBConnection *connection, id parameter, WVJSBAckBlock (^ done)(void)) {
        done()(@"[\\] ['] [\"] [\b] [\f] [\n] [\r] [\t] [\u2028] [\u2029]",nil);
        return nil;
    }];
    [[[server on:@"delayed"] onEvent:^id (WVJSBConnection *connection, id parameter, WVJSBAckBlock (^ done)(void)) {
        dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC*2), DBL_MAX, 0 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(timer, ^{
            if (arc4random()%2){
                done()(@"[\\] ['] [\"] [\b] [\f] [\n] [\r] [\t] [\u2028] [\u2029]",nil);
            }else{
                done()(nil, @"can not find host");
            }
        });
        dispatch_resume(timer);
        return timer;
    }] onCancel:^(id context) {
        dispatch_source_cancel(context);
    }];
    [self refresh];
    // Do any additional setup after loading the view.
}

- (void)refresh {
#warning make sure the URL is consistent to your web server
    NSString *URLString =@"http://127.0.0.1";
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:URLString]]];
}

- (void)immediate{
    @synchronized (self.connections) {
        __weak typeof(self) weakSelf=self;
        [self.connections enumerateObjectsUsingBlock:^(WVJSBConnection *connection, NSUInteger idx, BOOL * stop) {
            WVJSBOperation *operation = [[[connection event:@"immediate" parameter:nil] onAck:^(WVJSBOperation *operation ,id  _Nullable result, NSError * _Nullable error) {
                if (error){
                    NSLog(@"did receive immediate error: %@",error);
                }else{
                    NSLog(@"did receive immediate ack: %@",result);
                }
                __strong typeof(weakSelf) self=weakSelf;
                @synchronized (self.operations) {
                    [self.operations removeObject:operation];
                }
            }] timeout:10];
            @synchronized (self.operations) {
                [self.operations addObject:operation];
            }
        }];
    }
}

- (void)delayed {
    __weak typeof(self) weakSelf=self;
    @synchronized (self.connections) {
        [self.connections enumerateObjectsUsingBlock:^(WVJSBConnection *connection, NSUInteger idx, BOOL * _Nonnull stop) {
            WVJSBOperation *operation = [[[connection event:@"delayed" parameter:nil] onAck:^(WVJSBOperation *operation,id result, id exception) {
                if (exception){
                    NSLog(@"did receive delayed exception: %@",exception);
                }else{
                    NSLog(@"did receive delayed ack: %@",result);
                }
                __strong typeof(weakSelf) self=weakSelf;
                @synchronized (self.operations) {
                    [self.operations removeObject:operation];
                }
            }]timeout:10];
            @synchronized (self.operations) {
                [self.operations addObject:operation];
            }
        }];
    }
}

- (IBAction)cancel:(id)sender {
    @synchronized (self.operations) {
        [self.operations enumerateObjectsUsingBlock:^(WVJSBOperation *operation, NSUInteger idx, BOOL * _Nonnull stop) {
            [operation cancel];
        }];
        [self.operations removeAllObjects];
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    decisionHandler([WVJSBServer canHandleWithWebView:webView URLString:navigationAction.request.URL.absoluteString]?WKNavigationActionPolicyCancel:WKNavigationActionPolicyAllow);
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}


@end
