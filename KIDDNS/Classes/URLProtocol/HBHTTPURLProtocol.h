//
//  VKCacheFileInterceptor.h
//  Pods
//
//  Created by yiyang on 2017/9/9.
//
//

#import <Foundation/Foundation.h>

@class KIDDNSResult;

@interface HBHTTPURLProtocol : NSURLProtocol

@property (atomic, strong, readwrite) NSURLSessionTask *            currentTask;               ///< The NSURLSession task for that request; client thread only.
@property (nonatomic, strong) KIDDNSResult *dnsResult;

+ (void)start;

+ (void)registerInterceptor:(Class)interceptor;
+ (void)unregisterInterceptor:(Class)interceptor;

+ (void)markRequestAsIgnored:(NSMutableURLRequest *)request;
+ (void)unmarkRequestAsIgnored:(NSMutableURLRequest *)request;

+ (BOOL)shouldInterceptRequest:(NSURLRequest *)request;
+ (void)rewriteRequest:(NSMutableURLRequest *)request;

- (void)startRemoteRequest:(NSURLRequest *)request;

- (NSURLSessionTask *)taskWithRequest:(NSURLRequest *)request;

- (void)logDNSResult;

@end
