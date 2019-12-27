//
//  WVJSBMessage.h
//  ObjCWebViewJavaScriptBridge
//
//  Created by ouyanghuacom on 2019/12/26.
//  Copyright © 2019 ouyanghuacom. All rights reserved.
//

#import "WVJSBMessage.h"

@implementation WVJSBMessage

+ (instancetype)messageWithJSONString:(NSString*)JSONString{
    return [[self alloc]initWithJSONString:JSONString];
}

- (instancetype)initWithJSONString:(NSString *)JSONString{
    if (JSONString.length==0){
        return nil;
    }
    NSError *e;
    NSDictionary *message = [NSJSONSerialization JSONObjectWithData:[JSONString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&e];
    if (e||!message){
        NSParameterAssert(0);
        return nil;
    }
    NSString *mid  = message[@"id"];
    NSString *from = message[@"from"];
    NSString *to   = message[@"to"];
    NSString *type = message[@"type"];
    id parameter   = message[@"parameter"];
    id exception   = message[@"exception"];
    self = [self init];
    if (!self) return nil;
    self.from      = from;
    self.to        = to;
    self.mid       = mid;
    self.type      = type;
    self.parameter = parameter;
    self.exception = exception;
    return self;
}

- (NSString*)JSONString{
    NSMutableDictionary *message = [NSMutableDictionary dictionaryWithCapacity:6];
    message[@"id"]        = self.mid;
    message[@"type"]      = self.type;
    message[@"from"]      = self.from;
    message[@"to"]        = self.to;
    message[@"parameter"] = self.parameter;
    message[@"exception"] = self.exception;
    NSError *e;
    NSData *data = [NSJSONSerialization dataWithJSONObject:message options:0 error:&e];
    if (e){
        NSParameterAssert(0);
        return nil;
    }
    return [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
}

@end
