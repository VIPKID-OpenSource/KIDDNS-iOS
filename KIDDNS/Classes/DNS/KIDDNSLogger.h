//
//  KIDDNSLogger.h
//  KIDDNS
//
//  Created by yiyang on 2018/9/28.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, KIDDNSLogLevel) {
    KIDDNSLogLevelVerbose,
    KIDDNSLogLevelInfo,
    KIDDNSLogLevelWarn,
    KIDDNSLogLevelError
};

@interface KIDDNSResult : NSObject

/**
 请求的URL
 */
@property (nonatomic, copy) NSString *url;

/**
 请求所走的NSURLProtocoln 类名
 */
@property (nonatomic, copy) NSString *URLProtocolName;

/**
 请求生命周期内是否使用过HTTPDNS服务
 */
@property (nonatomic, assign) BOOL useHTTPDNS;

/**
 请求生命周期内是否使用过默认的LocalDNS服务
 */
@property (nonatomic, assign) BOOL useLocalDNS;

/**
 请求是否通过HTTPDNS服务而成功完成
 */
@property (nonatomic, assign) BOOL successByHTTPDNS;

/**
 请求最终是否成功完成
 */
@property (nonatomic, assign) BOOL successAfterAll;

@end



NS_ASSUME_NONNULL_BEGIN

@protocol KIDDNSLogger <NSObject>

/**
 记录HTTPDNS的结果

 @param level 日志级别
 @param result HTTPDNS的结果
 */
- (void)logLevel:(KIDDNSLogLevel)level result:(KIDDNSResult *)result;

@end

NS_ASSUME_NONNULL_END
