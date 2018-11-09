//
//  VKCacheFileInterceptor.m
//  Pods
//
//  Created by yiyang on 2017/9/9.
//
//

#import "HBHTTPURLProtocol.h"
#import "HBURLSessionDemux.h"
#import "HBMutableArray.m"
#import "URLProtocolLog.h"
#import "HBURLSessionMap.h"
#import <mach/mach_time.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "DNSCenter_internal.h"

static HBMutableArray *sRegisters;

@interface HBHTTPURLProtocol ()<NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

@property (atomic, strong, readwrite) NSThread *                        clientThread;       ///< The thread on which we should call the client.

/*! The run loop modes in which to call the client.
 *  \details The concurrency control here is complex.  It's set up on the client
 *  thread in -startLoading and then never modified.  It is, however, read by code
 *  running on other threads (specifically the main thread), so we deallocate it in
 *  -dealloc rather than in -stopLoading.  We can be sure that it's not read before
 *  it's set up because the main thread code that reads it can only be called after
 *  -startLoading has started the connection running.
 */

@property (atomic, copy,   readwrite) NSArray *                         modes;
@property (atomic, assign, readwrite) NSTimeInterval                    startTime;          ///< The start time of the request; written by client thread only; read by any thread.

@property (nonatomic, strong) NSURLSessionTask *originalTask;


@end

@implementation HBHTTPURLProtocol

+ (HBURLSessionDemux *)sharedDemux
{
    static HBURLSessionDemux *demux;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        demux = [[HBURLSessionDemux alloc] initWithConfiguration:sessionConfiguration];
    });
    
    return demux;
}

+ (void)start
{
    [URLProtocolLog logWithPrefix:@"URLProtocol" format:@"start URLProtocol"];
    [NSURLProtocol registerClass:self];
}

#pragma mark - Public Methods Only For HBCacheFileInterceptor

+ (void)registerInterceptor:(Class)interceptor
{
    if (![interceptor isSubclassOfClass:self]) {
        return;
    }
    NSString *key = NSStringFromClass(interceptor);
    if (key.length == 0) {
        return;
    }
    if (![self isInterceptorRegistered:interceptor]) {
        [sRegisters addObject:key];
        [NSURLProtocol registerClass:interceptor];
    }
}

+ (void)unregisterInterceptor:(Class)interceptor
{
    if (![interceptor isSubclassOfClass:self]) {
        return;
    }
    if (NSStringFromClass(interceptor).length == 0) {
        return;
    }
    if ([self isInterceptorRegistered:interceptor]) {
        [sRegisters removeObject:NSStringFromClass(interceptor)];
        [NSURLProtocol unregisterClass:interceptor];
    }
}

#pragma mark - Public Methods For SubClass & Non-override

+ (void)markRequestAsIgnored:(NSMutableURLRequest *)request
{
    [NSURLProtocol setProperty:@YES forKey:kOurRecursiveRequestFlagProperty inRequest:request];
}

+ (void)unmarkRequestAsIgnored:(NSMutableURLRequest *)request
{
    [NSURLProtocol removePropertyForKey:kOurRecursiveRequestFlagProperty inRequest:request];
}

+ (BOOL)isRequestIgnored:(NSURLRequest *)request
{
    if ([NSURLProtocol propertyForKey:kOurRecursiveRequestFlagProperty inRequest:request]) {
        return YES;
    }
    return NO;
}

#pragma mark - NSURLProtocol methods
/*! Used to mark our recursive requests so that we don't try to handle them (and thereby
 *  suffer an infinite recursive death).
 */

static NSString * kOurRecursiveRequestFlagProperty = @"com.hybooster.cachefileInterceptor";

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    NSString *scheme = request.URL.scheme;

    if (!([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"])) {
        return NO;
    }
    if ([self isRequestIgnored:request]) {
        return NO;
    }
    
    return [self shouldInterceptRequest:request];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (instancetype)initWithTask:(NSURLSessionTask *)task cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id<NSURLProtocolClient>)client
{
    if (self = [super initWithTask:task cachedResponse:cachedResponse client:client]) {
        self.originalTask = task;
        KIDDNSResult *result = [KIDDNSResult new];
        result.url = task.currentRequest.URL.absoluteString;
        result.URLProtocolName = NSStringFromClass([self class]);
        self.dnsResult = result;
    }
    return self;
}

- (void)startLoading
{
    NSMutableURLRequest *newQuest = nil;
    if ([self.request isKindOfClass:[NSMutableURLRequest class]]) {
        newQuest = (NSMutableURLRequest *)self.request;
    } else {
        newQuest = [self.request mutableCopy];
    }
    
    [[self class] markRequestAsIgnored:newQuest];
    
    [[self class] rewriteRequest:newQuest];
    
    [self startRemoteRequest:newQuest];
    [URLProtocolLog logWithPrefix:@"URLProtocol" format:@"%@ -> %@:%@", NSStringFromSelector(_cmd), newQuest.URL, newQuest.HTTPMethod];
}

- (void)stopLoading
{
    [URLProtocolLog logWithPrefix:@"URLProtocol" format:@"%@", NSStringFromSelector(_cmd)];
    if (self.currentTask != nil) {
        [self.currentTask cancel];
        self.currentTask = nil;
    }
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler
{
    [URLProtocolLog logWithPrefix:@"URLProtocol" format:@"%@", NSStringFromSelector(_cmd)];
    if (self.currentTask == task) {
        NSMutableURLRequest *redirectRequest = [request mutableCopy];
        [[self class] unmarkRequestAsIgnored:redirectRequest];
        
        [[self client] URLProtocol:self wasRedirectedToRequest:redirectRequest redirectResponse:response];
        
        [self.currentTask cancel];
        
        [[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil]];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    
    [URLProtocolLog logWithPrefix:@"URLProtocol" format:@"%@", NSStringFromSelector(_cmd)];
    [self.client URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    if (task == self.originalTask) {
        return;
    }
    NSURLSession *originalSession = [HBURLSessionMap fetchSessionOfTask:self.originalTask];
    if (originalSession.delegate && [originalSession.delegate respondsToSelector:@selector(URLSession:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:)]) {
        [originalSession.delegateQueue addOperationWithBlock:^{
            [(id<NSURLSessionTaskDelegate>)originalSession.delegate URLSession:originalSession task:self.originalTask didSendBodyData:bytesSent totalBytesSent:totalBytesSent totalBytesExpectedToSend:totalBytesExpectedToSend];
        }];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    
    [URLProtocolLog logWithPrefix:@"URLProtocol" format:@"%@", NSStringFromSelector(_cmd)];
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    [URLProtocolLog logWithPrefix:@"URLProtocol" format:@"%@", NSStringFromSelector(_cmd)];
    if (error == nil) {
        [self.client URLProtocolDidFinishLoading:self];
    } else {
        if ([[error domain] isEqual:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
            // Do nothing.  This happens in two cases:
            //
            // o during a redirect, in which case the redirect code has already told the client about
            //   the failure
            //
            // o if the request is cancelled by a call to -stopLoading, in which case the client doesn't
            //   want to know about the failure
        } else {
            
            [self.client URLProtocol:self didFailWithError:error];
        }
    }
}

#pragma mark - Private Maintain Interceptors Methods

+ (BOOL)isInterceptorRegistered:(Class)interceptor
{
    NSString *key = NSStringFromClass(interceptor);
    if (key.length == 0) {
        return NO;
    }
    if (!sRegisters) {
        sRegisters = [HBMutableArray new];
        return NO;
    }
    return [sRegisters containsObject:key];
}

#pragma mark - Private Request Handler methods

- (NSURLSessionTask *)taskWithRequest:(NSURLRequest *)request
{
    NSMutableArray *modes = [NSMutableArray new];
    [modes addObject:NSDefaultRunLoopMode];
    
    NSString *currentMode = [[NSRunLoop currentRunLoop] currentMode];
    
    if (currentMode != nil && ![currentMode isEqualToString:NSDefaultRunLoopMode]) {
        [modes addObject:currentMode];
    }
    self.modes = modes;
    
    NSURLSessionTask *dataTask = [[[self class] sharedDemux] dataTaskWithRequest:request delegate:self modes:self.modes];
    return dataTask;
}

- (void)startRemoteRequest:(NSURLRequest *)request
{
    NSURLSessionTask *task = [self taskWithRequest:request];
    self.currentTask = task;
    [task resume];
}

- (void)logDNSResult
{
    [[[DNSCenter defaultCenter] loggers] enumerateObjectsUsingBlock:^(id<KIDDNSLogger>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj logLevel:KIDDNSLogLevelInfo result:self.dnsResult];
    }];
}

#pragma mark - SubClass Override Methods

+ (BOOL)shouldInterceptRequest:(NSURLRequest *)request
{
    return NO;
}

+ (void)rewriteRequest:(NSMutableURLRequest *)request
{
    
}
@end
