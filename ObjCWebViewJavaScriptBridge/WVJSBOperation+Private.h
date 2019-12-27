//
//  WVJSBOperation+Private.h
//  ObjCWebViewJavaScriptBridge
//
//  Created by ouyanghuacom on 2019/12/26.
//  Copyright © 2019 ouyanghuacom. All rights reserved.
//

#import "WVJSBOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface WVJSBOperation (Private)

@property (nonatomic,copy  ) void(^retainBlock)(WVJSBOperation *operation);
@property (nonatomic,copy  ) void(^releaseBlock)(WVJSBOperation *operation);
@property (nonatomic,copy  ) void(^didCancelBlock)(WVJSBOperation *oepration);

- (void)ack:(id _Nullable)result exception:(id _Nullable)exception;

@end

NS_ASSUME_NONNULL_END
