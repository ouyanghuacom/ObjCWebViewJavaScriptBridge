//
//  WVJSBConnection+Private.h
//  ObjCWebViewJavaScriptBridge
//
//  Created by ouyanghuacom on 2019/12/26.
//  Copyright © 2019 ouyanghuacom. All rights reserved.
//

#import "WVJSBConnection.h"

NS_ASSUME_NONNULL_BEGIN

@interface WVJSBConnection (Private)

@property (nonatomic, copy) void(^sendBlock)(NSString *mid, NSString *type, id _Nullable parameter);
@property (nonatomic, copy, readonly) void(^receiveBlock)(NSString *mid, id _Nullable result, id _Nullable exception);

- (instancetype)initWithInfomation:(id)infomation;

@end

NS_ASSUME_NONNULL_END
