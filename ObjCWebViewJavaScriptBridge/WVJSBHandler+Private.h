//
//  WVJSBHandler+Private.h
//  ObjCWebViewJavaScriptBridge
//
//  Created by ouyanghuacom on 2019/12/26.
//  Copyright © 2019 ouyanghuacom. All rights reserved.
//

#import "WVJSBHandler.h"

NS_ASSUME_NONNULL_BEGIN

@interface WVJSBHandler (Private)

@property (nonatomic, copy, readonly, nullable) id (^eventBlock)(WVJSBConnection *connection, id _Nullable parameter, WVJSBAckBlock(^done)(void));
@property (nonatomic, copy, readonly, nullable) void (^cancelBlock)(id context);

@end

NS_ASSUME_NONNULL_END
