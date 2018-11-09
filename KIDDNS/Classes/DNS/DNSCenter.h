//
//  DNSCenter.h
//  KIDDNS
//
//  Created by yiyang on 2018/9/14.
//

#import <Foundation/Foundation.h>
#import "KIDDNSLogger.h"


/**
 DNS配置项
 */
@interface KIDDNSConfig : NSObject

/**
 阿里云HTTPDNS应用的account id
 */
@property (nonatomic, assign) int accountId;

/**
 阿里云HTTPDNS应用的app key
 */
@property (nonatomic, copy) NSString *key;

/**
 需要预解析的域名列表
 */
@property (nonatomic, copy) NSArray<NSString *> *presolvedHosts;

@end

/**
 DNS中心服务，通过此对象来开启或关闭HTTPDNS服务
 */
@interface DNSCenter : NSObject

/**
 白名单列表，支持正则匹配，如果设置了白名单，只有在白名单之内的域名才会进行HTTPDNS，如果没有设置白名单，则只要不在黑名单内，都视为在白名单内
 */
@property (nonatomic, copy) NSArray<NSString *> *whiteList;

/**
 黑名单列表，支持正则匹配，如果设置了黑名单，则黑名单内的域名都不会进行HTTPDNS，黑名单的优先级高于白名单.
 */
@property (nonatomic, copy) NSArray<NSString *> *blackList;

/**
 是否开启自动HTTPDNS服务
 */
@property (nonatomic, assign) BOOL automaticDNS;

/**
 获取默认的DNS中心服务

 @return DNSCenter
 */
+ (instancetype)defaultCenter;

- (instancetype)init NS_UNAVAILABLE;

/**
 使用配置项初始化HTTPDNS服务

 @param config HTTPDNS服务配置项
 */
- (void)initializeDNSServiceWithConfig:(KIDDNSConfig *)config;

/**
 添加日志记录对象

 @param logger 遵循KIDDNSLogger协议的日志对象
 */
- (void)addLogger:(id<KIDDNSLogger>)logger;

/**
 移除之前添加到DNSCenter的日志记录对象

 @param logger 之前添加到DNSCenter的日志对象
 */
- (void)removeLogger:(id<KIDDNSLogger>)logger;


/**
 返回URL对应的HTTPDNS网址。

 @param url 需要DNS解析的完整URL
 @return 返回解析过后的结果，完整URL。如果解析失败或者解析之后和原url一致，则返回nil
 */
- (NSString *)dnsResultForURL:(NSString *)url;

@end
