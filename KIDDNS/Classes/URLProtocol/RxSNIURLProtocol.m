//
//  RxSNIURLProtocol.m
//  RxData
//
//  Created by yiyang on 2018/8/31.
//

#import "RxSNIURLProtocol.h"
#import "DNSCenter.h"
#import <objc/runtime.h>


#define kAnchorAlreadyAdded @"AnchorAlreadyAdded"

@interface RxSNIURLProtocol()<NSStreamDelegate> {
    NSInputStream *_inputStream;
    NSRunLoop *_currentRunloop;
    NSRunLoopMode _runloopMode;
    NSMutableURLRequest *_currentRequest;
    NSMutableURLRequest *_requestWithIP;
    NSMutableURLRequest *_requestWithDomain;
}
@end

@implementation RxSNIURLProtocol

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
    
    if ([request.URL.scheme isEqualToString:@"https"]) {
        NSString *dnsResultURL = [[DNSCenter defaultCenter] dnsResultForURL:request.URL.absoluteString];
        if (dnsResultURL.length > 0) {
            return YES;
        }
    }
    return NO;
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
    
    _requestWithDomain = [newQuest mutableCopy];
    
    NSString *dnsResultURL = [[DNSCenter defaultCenter] dnsResultForURL:newQuest.URL.absoluteString];
//    NSString *ip = nil;
    if (dnsResultURL.length > 0) {
        
        NSMutableDictionary *headers = [newQuest.allHTTPHeaderFields mutableCopy];
        if (headers == nil) {
            headers = [NSMutableDictionary new];
        }
        headers[@"Host"] = newQuest.URL.host;
        newQuest.allHTTPHeaderFields = [headers copy];
        
        newQuest.URL = [NSURL URLWithString:dnsResultURL];
        _requestWithIP = newQuest;
    }
    
    
    [self startRequest];
}

- (void)startRequest
{
    if (_requestWithIP != nil) {
        self.dnsResult.useHTTPDNS = YES;
        [self startRequest:_requestWithIP];
    } else {
        self.dnsResult.useLocalDNS = YES;
        [self startRequest:_requestWithDomain];
    }
}

- (void)startRequest:(NSURLRequest *)request
{
    if ([request isKindOfClass:[NSMutableURLRequest class]]) {
        _currentRequest = (NSMutableURLRequest *)request;
    } else {
        _currentRequest = [request mutableCopy];
    }
    
    NSDictionary *headers = request.allHTTPHeaderFields;
    CFStringRef requestBody = CFSTR("");
    CFDataRef bodyData = CFStringCreateExternalRepresentation(kCFAllocatorDefault, requestBody, kCFStringEncodingUTF8, 0);
    if (request.HTTPBody) {
        bodyData = (__bridge_retained CFDataRef)request.HTTPBody;
    } else if (request.HTTPBodyStream) {
        NSInputStream *bodyStream = request.HTTPBodyStream;
        NSInteger maxlength = 1024;
        uint8_t d[maxlength];
        BOOL eof = NO;
        NSMutableData *streamData = [NSMutableData new];
        [bodyStream open];
        while (!eof) {
            NSInteger bytesRead = [bodyStream read:d maxLength:maxlength];
            if (bytesRead == 0) {
                eof = YES;
            } else if (bytesRead == -1) {
                eof = YES;
            } else if (bodyStream.streamError == nil) {
                [streamData appendBytes:d length:bytesRead];
            }
        }
        bodyData = (__bridge_retained CFDataRef)[streamData copy];
        [bodyStream close];
    }
    
    CFStringRef url = (__bridge CFStringRef)[request.URL absoluteString];
    CFURLRef requestURL = CFURLCreateWithString(kCFAllocatorDefault, url, NULL);
    
    CFStringRef httpMethod = (__bridge_retained CFStringRef)request.HTTPMethod;
    
    CFHTTPMessageRef cfRequst = CFHTTPMessageCreateRequest(kCFAllocatorDefault, httpMethod, requestURL, kCFHTTPVersion1_1);
    // body
    CFHTTPMessageSetBody(cfRequst, bodyData);
    
    // header
    [headers enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        CFStringRef cfKey = (__bridge CFStringRef)key;
        CFStringRef cfValue = (__bridge CFStringRef)obj;
        CFHTTPMessageSetHeaderFieldValue(cfRequst, cfKey, cfValue);
    }];
    
    //cookies
    NSMutableArray *cookieArray = [NSMutableArray array];
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [cookieStorage cookies]) {
        if ([_requestWithDomain.URL.host containsString:cookie.domain]){
            [cookieArray addObject:cookie];
        }
    }
    
    if (cookieArray != nil && cookieArray.count > 0) {
        NSDictionary *cookieDic = [NSHTTPCookie requestHeaderFieldsWithCookies:cookieArray];
        if ([cookieDic objectForKey:@"Cookie"]) {
            NSString *cookieString = [cookieDic valueForKey:@"Cookie"];
            CFStringRef cfKey = (__bridge_retained CFStringRef)@"Cookie";
            CFStringRef cfValue = (__bridge_retained CFStringRef)cookieString;
            CFHTTPMessageSetHeaderFieldValue(cfRequst, cfKey, cfValue);
            
            CFRelease(cfKey);
            CFRelease(cfValue);
        }
    }

    CFReadStreamRef readStream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, cfRequst);
    _inputStream = (__bridge_transfer NSInputStream *)readStream;
    
    NSString *host = headers[@"host"];
    if (!host) {
        host = request.URL.host;
    }
    NSDictionary *sslProperties = [[NSDictionary alloc] initWithObjectsAndKeys:host, (__bridge id)kCFStreamSSLPeerName, nil];
    [_inputStream setProperty:sslProperties forKey:(__bridge_transfer NSString *)kCFStreamPropertySSLSettings];
    _inputStream.delegate = self;
    
    
    if (!_currentRunloop) {
        _currentRunloop = [NSRunLoop currentRunLoop];
    }
    if (!_runloopMode) {
        _runloopMode = NSRunLoopCommonModes;
        NSRunLoopMode mode = [NSRunLoop currentRunLoop].currentMode;
        if (mode != nil && ![mode isEqualToString:_runloopMode]) {
            _runloopMode = mode;
        }
    }
    
    [_inputStream scheduleInRunLoop:_currentRunloop forMode:_runloopMode];
    [_inputStream open];
    
    CFRelease(cfRequst);
    CFRelease(requestURL);
    cfRequst = NULL;
    CFRelease(bodyData);
    CFRelease(httpMethod);
}

- (void)stopLoading
{
    if (_inputStream.streamStatus == NSStreamStatusOpen) {
        [_inputStream removeFromRunLoop:_currentRunloop forMode:NSRunLoopCommonModes];
        [_inputStream setDelegate:nil];
        [_inputStream close];
    }
    [self.client URLProtocol:self didFailWithError:[[NSError alloc] initWithDomain:@"stop loading" code:-1 userInfo:nil]];
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    if (eventCode == NSStreamEventHasBytesAvailable) {
        CFReadStreamRef readStream = (__bridge CFReadStreamRef) aStream;
        CFHTTPMessageRef message = (CFHTTPMessageRef) CFReadStreamCopyProperty(readStream, kCFStreamPropertyHTTPResponseHeader);
        if (CFHTTPMessageIsHeaderComplete(message)) {
            // 以防response的header信息不完整
            UInt8 buffer[16 * 1024];
            UInt8 *buf = NULL;
            unsigned long length = 0;
            NSInputStream *inputstream = (NSInputStream *) aStream;
            BOOL alreadyAdded = [objc_getAssociatedObject(aStream, kAnchorAlreadyAdded) boolValue];
            if (!alreadyAdded) {
                objc_setAssociatedObject(aStream, kAnchorAlreadyAdded, @YES, OBJC_ASSOCIATION_RETAIN);
                // 通知client已收到response，只通知一次
                NSDictionary *headDict = (__bridge_transfer NSDictionary *) (CFHTTPMessageCopyAllHeaderFields(message));
                CFStringRef httpVersion = CFHTTPMessageCopyVersion(message);
                // 获取响应头部的状态码
                CFIndex myErrCode = CFHTTPMessageGetResponseStatusCode(message);
                NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:_currentRequest.URL statusCode:myErrCode HTTPVersion:(__bridge NSString *) httpVersion headerFields:headDict];
                
                [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
                
                CFRelease(httpVersion);
            }
            if (![inputstream getBuffer:&buf length:&length]) {
                NSInteger amount = [inputstream read:buffer maxLength:sizeof(buffer)];
                buf = buffer;
                length = amount;
            }
            NSData *data = [[NSData alloc] initWithBytes:buf length:length];
            
            [self.client URLProtocol:self didLoadData:data];
        }
        CFRelease(message);
    } else if (eventCode == NSStreamEventErrorOccurred) {
        [aStream removeFromRunLoop:_currentRunloop forMode:_runloopMode];
        [aStream setDelegate:nil];
        [aStream close];
        // 通知client发生错误了
        if (_currentRequest == _requestWithIP) {
            _requestWithIP = nil;
            [self startRequest];
        } else {
            [self logDNSResult];
            [self.client URLProtocol:self didFailWithError:[aStream streamError]];
        }
    } else if (eventCode == NSStreamEventEndEncountered) {
        if (_currentRequest == _requestWithIP) {
            self.dnsResult.successByHTTPDNS = YES;
        }
        self.dnsResult.successAfterAll = YES;
        [self logDNSResult];
        [self handleResponse];
    }
}

#pragma mark - Response

/**
 * 根据服务器返回的响应内容进行不同的处理
 */
- (void)handleResponse {
    // 获取响应头部信息
    CFReadStreamRef readStream = (__bridge CFReadStreamRef) _inputStream;
    CFHTTPMessageRef message = (CFHTTPMessageRef) CFReadStreamCopyProperty(readStream, kCFStreamPropertyHTTPResponseHeader);
    if (CFHTTPMessageIsHeaderComplete(message)) {
        // 确保response头部信息完整
        NSDictionary *headDict = (__bridge_transfer NSDictionary *) (CFHTTPMessageCopyAllHeaderFields(message));
        
        //cookies
        NSArray *cookieArray = [NSHTTPCookie cookiesWithResponseHeaderFields:headDict forURL:self.request.URL];
        if (cookieArray != nil) {
            NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
            for (NSHTTPCookie *cookie in cookieArray) {
                if ([self.request.URL.host containsString:cookie.domain]){
                    [cookieStorage setCookie:cookie];
                }
            }
        }
        
        // 获取响应头部的状态码
        CFIndex myErrCode = CFHTTPMessageGetResponseStatusCode(message);
        
        // 把当前请求关闭
        [_inputStream removeFromRunLoop:_currentRunloop forMode:_runloopMode];
        [_inputStream setDelegate:nil];
        [_inputStream close];
        
        if (myErrCode >= 200 && myErrCode < 300) {
            
            // 返回码为2xx，直接通知client
            [self.client URLProtocolDidFinishLoading:self];
            
        } else if (myErrCode >= 300 && myErrCode < 400) {
            // 返回码为3xx，需要重定向请求，继续访问重定向页面
            NSString *location = headDict[@"Location"];
            if (!location)
                location = headDict[@"location"];
            NSURL *url = [[NSURL alloc] initWithString:location];
            _currentRequest.URL = url;
            if ([[_currentRequest.HTTPMethod lowercaseString] isEqualToString:@"post"]) {
                // 根据RFC文档，当重定向请求为POST请求时，要将其转换为GET请求
                _currentRequest.HTTPMethod = @"GET";
                _currentRequest.HTTPBody = nil;
            }
            
            /***********重定向通知client处理或内部处理*************/
            // client处理
            // NSURLResponse* response = [[NSURLResponse alloc] initWithURL:curRequest.URL MIMEType:headDict[@"Content-Type"] expectedContentLength:[headDict[@"Content-Length"] integerValue] textEncodingName:@"UTF8"];
            // [self.client URLProtocol:self wasRedirectedToRequest:curRequest redirectResponse:response];
            
            // 内部处理，将url中的host通过HTTPDNS转换为IP，不能在startLoading线程中进行同步网络请求，会被阻塞
            _requestWithDomain = [_currentRequest mutableCopy];
            NSString *dnsResultURL = [[DNSCenter defaultCenter] dnsResultForURL:_currentRequest.URL.absoluteString];
            if (dnsResultURL.length > 0) {
                NSLog(@"Get IP from HTTPDNS Successfully!");
                _currentRequest.URL = [NSURL URLWithString:dnsResultURL];
                
                [_currentRequest setValue:url.host forHTTPHeaderField:@"host"];
                _requestWithIP = _currentRequest;
            }
            [self startRequest];
        } else {
            // 其他情况，直接返回响应信息给client
            [self.client URLProtocolDidFinishLoading:self];
        }
    } else {
        // 头部信息不完整，关闭inputstream，通知client
        [_inputStream removeFromRunLoop:_currentRunloop forMode:_runloopMode];
        [_inputStream setDelegate:nil];
        [_inputStream close];
        [self.client URLProtocolDidFinishLoading:self];
    }
    
    CFRelease(message);
}

@end
