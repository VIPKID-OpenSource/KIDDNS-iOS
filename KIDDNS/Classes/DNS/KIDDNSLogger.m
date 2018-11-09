//
//  KIDDNSLogger.m
//  KIDDNS
//
//  Created by yiyang on 2018/9/28.
//

#import <Foundation/Foundation.h>
#import "KIDDNSLogger.h"


@implementation KIDDNSResult

- (instancetype)init
{
    if (self = [super init]) {
        self.successAfterAll = NO;
        self.successByHTTPDNS = NO;
        self.useHTTPDNS = NO;
        self.useLocalDNS = NO;
    }
    return self;
}

- (NSString *)description
{
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"successAfterAll"] = @(self.successAfterAll);
    dict[@"successByHTTPDNS"] = @(self.successByHTTPDNS);
    dict[@"useHTTPDNS"] = @(self.useHTTPDNS);
    dict[@"useLocalDNS"] = @(self.useLocalDNS);
    dict[@"url"] = self.url;
    dict[@"URLProtocolName"] = self.URLProtocolName;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
    NSString *desc = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return desc;
}

@end
