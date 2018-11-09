//
//  RxHTTPDNSURLProtocol.m
//  RxData
//
//  Created by yiyang on 2018/8/29.
//

#import "RxHTTPDNSURLProtocol.h"
#import "DNSCenter.h"
#import "KIDAuthChallenger.h"
#import "DNSCenter_internal.h"

@interface RxHTTPDNSURLProtocol()

@property (nonatomic, strong) NSURLSessionTask *taskWithIP;
@property (nonatomic, strong) NSURLSessionTask *taskWithDomain;

@end

@implementation RxHTTPDNSURLProtocol

+ (BOOL)shouldInterceptRequest:(NSURLRequest *)request
{
    if ([DNSCenter defaultCenter].automaticDNS == NO) {
        return NO;
    }
    NSString *ua = request.allHTTPHeaderFields[@"User-Agent"];
    if ([ua containsString:@"Mozilla"]) {
        return NO;
    }

    NSString *host = request.URL.host;
    if ([host containsString:@"taobao"] || [host containsString:@"aliyun"]) {
        return NO;
    }
    NSString *dnsResultURL = [[DNSCenter defaultCenter] dnsResultForURL:request.URL.absoluteString];
    if (dnsResultURL.length > 0) {
        return YES;
    }
    return NO;
}

- (void)startLoading
{
    self.taskWithDomain = nil;
    self.taskWithIP = nil;
    NSMutableURLRequest *newQuest = nil;
    if ([self.request isKindOfClass:[NSMutableURLRequest class]]) {
        newQuest = (NSMutableURLRequest *)self.request;
    } else {
        newQuest = [self.request mutableCopy];
    }
    
    [[self class] markRequestAsIgnored:newQuest];
    
    self.taskWithDomain = [self taskWithRequest:newQuest];
    
    NSString *dnsResultURL = [[DNSCenter defaultCenter] dnsResultForURL:newQuest.URL.absoluteString];
    if (dnsResultURL.length > 0) {
        
        NSMutableDictionary *headers = [newQuest.allHTTPHeaderFields mutableCopy];
        if (headers == nil) {
            headers = [NSMutableDictionary new];
        }
        headers[@"Host"] = newQuest.URL.host;
        
        //cookies
        NSMutableArray *cookieArray = [NSMutableArray array];
        NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (NSHTTPCookie *cookie in [cookieStorage cookies]) {
            if ([_taskWithDomain.currentRequest.URL.host containsString:cookie.domain]){
                [cookieArray addObject:cookie];
            }
        }
        if (cookieArray != nil && cookieArray.count > 0) {
            NSDictionary *cookieDic = [NSHTTPCookie requestHeaderFieldsWithCookies:cookieArray];
            if ([cookieDic objectForKey:@"Cookie"]) {
                [headers setValue:cookieDic[@"Cookie"] forKey:@"Cookie"];
            }
        }
        
        newQuest.allHTTPHeaderFields = [headers copy];
        newQuest.URL = [NSURL URLWithString:dnsResultURL];
        self.taskWithIP = [self taskWithRequest:newQuest];
    }
    [self startTask];
}

- (void)startTask
{
    if (self.taskWithIP) {
        self.currentTask = self.taskWithIP;
        self.dnsResult.useHTTPDNS = YES;
    } else if (self.taskWithDomain) {
        self.currentTask = self.taskWithDomain;
        self.dnsResult.useLocalDNS = YES;
    }
    if (self.currentTask) {
        [self.currentTask resume];
    }
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
{
    
    [KIDAuthChallenger didReceiveChallengeOnHost:self.taskWithDomain.currentRequest.URL.host session:session challenge:challenge completion:completionHandler];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    //cookies
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
    NSArray *cookieArray = [NSHTTPCookie cookiesWithResponseHeaderFields:response.allHeaderFields forURL:self.request.URL];
    if (cookieArray != nil) {
        NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (NSHTTPCookie *cookie in cookieArray) {
            if ([self.request.URL.host containsString:cookie.domain]){
                [cookieStorage setCookie:cookie];
            }
        }
    }
    
    if (error == nil) {
        [self.client URLProtocolDidFinishLoading:self];
        if (task == self.taskWithIP) {
            self.dnsResult.successByHTTPDNS = YES;
        }
        self.dnsResult.successAfterAll = YES;
        [self logDNSResult];
    } else {
        if (task == self.taskWithIP) {
            NSLog(@"[DNSProtocol] ip task failed, retry with domain task");
            self.taskWithIP = nil;
            self.dnsResult.successByHTTPDNS = NO;
            [self startTask];
            return;
        }
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
        [self logDNSResult];
    }
}

@end
