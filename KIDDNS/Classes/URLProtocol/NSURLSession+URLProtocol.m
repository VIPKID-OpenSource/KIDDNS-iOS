//
//  NSURLSession+URLProtocol.m
//  RxData
//
//  Created by yiyang on 2018/8/30.
//

#import "NSURLSession+URLProtocol.h"
#import <objc/runtime.h>
#import "HBURLSessionMap.h"

@implementation NSURLSession (URLProtocol)

+ (void)load
{
    [self swizzleMethods];
}

+ (void)swizzleMethods
{
    NSArray<NSString *> *selectors = @[@"dataTaskWithRequest:", @"dataTaskWithURL:",@"uploadTaskWithRequest:fromFile:",@"uploadTaskWithRequest:fromData:",@"uploadTaskWithStreamedRequest:",@"downloadTaskWithRequest:",@"downloadTaskWithURL:",@"downloadTaskWithResumeData:"];
    [selectors enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        Method originalMethod = class_getInstanceMethod([NSURLSession class],NSSelectorFromString(obj));
        NSString *fakeSelector = [NSString stringWithFormat:@"fake_%@", obj];
        Method fakeMethod = class_getInstanceMethod([NSURLSession class], NSSelectorFromString(fakeSelector));
        method_exchangeImplementations(originalMethod, fakeMethod);
    }];
}

- (NSURLSessionDataTask *)fake_dataTaskWithRequest:(NSURLRequest *)request {
    NSURLSessionDataTask *task = [self fake_dataTaskWithRequest:request];
    NSLog(@"[URLSession] %@ %@ -> %p", NSStringFromSelector(_cmd), request.URL, task);
    [self recordTask:task];
    return task;
}

/* Creates a data task to retrieve the contents of the given URL. */
- (NSURLSessionDataTask *)fake_dataTaskWithURL:(NSURL *)url {
    NSURLSessionDataTask *task = [self fake_dataTaskWithURL:url];
    NSLog(@"[URLSession] %@ %@ -> %p", NSStringFromSelector(_cmd), url, task);
    
    [self recordTask:task];
    return task;
}

/* Creates an upload task with the given request.  The body of the request will be created from the file referenced by fileURL */
- (NSURLSessionUploadTask *)fake_uploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL {
    NSURLSessionUploadTask *task = [self fake_uploadTaskWithRequest:request fromFile:fileURL];
    NSLog(@"[URLSession] %@ %@ -> %p", NSStringFromSelector(_cmd), request.URL, task);

    [self recordTask:task];
    return task;
}

/* Creates an upload task with the given request.  The body of the request is provided from the bodyData. */
- (NSURLSessionUploadTask *)fake_uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)bodyData {
    NSURLSessionUploadTask * task = [self fake_uploadTaskWithRequest:request fromData:bodyData];
    NSLog(@"[URLSession] %@ %@ -> %p", NSStringFromSelector(_cmd), request.URL, task);

    [self recordTask:task];
    return task;
}

/* Creates an upload task with the given request.  The previously set body stream of the request (if any) is ignored and the URLSession:task:needNewBodyStream: delegate will be called when the body payload is required. */
- (NSURLSessionUploadTask *)fake_uploadTaskWithStreamedRequest:(NSURLRequest *)request {
    NSURLSessionUploadTask *task = [self fake_uploadTaskWithStreamedRequest:request];
    NSLog(@"[URLSession] %@ %@ -> %p", NSStringFromSelector(_cmd), request.URL, task);

    [self recordTask:task];
    return task;
}

/* Creates a download task with the given request. */
- (NSURLSessionDownloadTask *)fake_downloadTaskWithRequest:(NSURLRequest *)request {
    NSURLSessionDownloadTask *task = [self fake_downloadTaskWithRequest:request];
    NSLog(@"[URLSession] %@ %@ -> %p", NSStringFromSelector(_cmd), request.URL, task);

    [self recordTask:task];
    return task;
}

/* Creates a download task to download the contents of the given URL. */
- (NSURLSessionDownloadTask *)fake_downloadTaskWithURL:(NSURL *)url {
    NSURLSessionDownloadTask *task = [self fake_downloadTaskWithURL:url];
    NSLog(@"[URLSession] %@ %@ -> %p", NSStringFromSelector(_cmd), url, task);

    [self recordTask:task];
    return task;
}

/* Creates a download task with the resume data.  If the download cannot be successfully resumed, URLSession:task:didCompleteWithError: will be called. */
- (NSURLSessionDownloadTask *)fake_downloadTaskWithResumeData:(NSData *)resumeData {
    NSURLSessionDownloadTask *task = [self fake_downloadTaskWithResumeData:resumeData];
    NSLog(@"[URLSession] %@ -> %p", NSStringFromSelector(_cmd), task);

    [self recordTask:task];
    return task;
}

- (void)recordTask:(NSURLSessionTask *)task
{
    [HBURLSessionMap recordSessionTask:task ofSession:self];
}

@end


