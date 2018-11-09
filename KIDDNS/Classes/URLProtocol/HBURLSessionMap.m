//
//  HBURLSessionMap.m
//  RxData
//
//  Created by yiyang on 2018/8/31.
//

#import "HBURLSessionMap.h"

@interface HBURLSessionMap () {
    NSMapTable * _map;
    dispatch_queue_t _queue;
}
@end

@implementation HBURLSessionMap

+ (instancetype)sharedInstance {
    static HBURLSessionMap *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [HBURLSessionMap new];
    });
    return instance;
}

- (instancetype)init
{
    if (self = [super init]) {
        _map = [NSMapTable weakToWeakObjectsMapTable];
        _queue = dispatch_queue_create("com.rxdata.urlprotocol.sessionmap", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (NSURLSession *)fetchSessionOfTask:(NSURLSessionTask *)task
{
    __block NSURLSession *session = nil;
    dispatch_sync(_queue, ^{
        session = [self->_map objectForKey:task];
    });
    return session;
}

- (void)recordSessionTask:(NSURLSessionTask *)task ofSession:(NSURLSession *)session
{
    dispatch_barrier_async(_queue, ^{
        [self->_map setObject:session forKey:task];
    });
}

+ (NSURLSession *)fetchSessionOfTask:(NSURLSessionTask *)task
{
    return [[self sharedInstance] fetchSessionOfTask:task];
}

+ (void)recordSessionTask:(NSURLSessionTask *)task ofSession:(NSURLSession *)session
{
    [[self sharedInstance] recordSessionTask:task ofSession:session];
}

@end
