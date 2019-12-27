//
//  WVJSBMessage.h
//  ObjCWebViewJavaScriptBridge
//
//  Created by ouyanghuacom on 2019/12/26.
//  Copyright © 2019 ouyanghuacom. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface WVJSBMessage : NSObject

@property (nonatomic,copy  ,nullable) NSString *mid;
@property (nonatomic,copy  ,nullable) NSString *type;
@property (nonatomic,copy  ,nullable) NSString *from;
@property (nonatomic,copy  ,nullable) NSString *to;
@property (nonatomic,strong,nullable) id       parameter;
@property (nonatomic,strong,nullable) id       exception;

+ (instancetype)messageWithJSONString:(NSString*)JSONString;
- (instancetype)initWithJSONString:(NSString*)JSONString;
- (NSString* _Nullable)JSONString;

@end

NS_ASSUME_NONNULL_END
