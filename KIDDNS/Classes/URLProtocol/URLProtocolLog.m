//
//  URLProtocolLog.m
//  RxData
//
//  Created by yiyang on 2018/8/29.
//

#import "URLProtocolLog.h"

@interface URLProtocolLog()
{
    dispatch_queue_t queue;
}
@end

@implementation URLProtocolLog

+ (instancetype)sharedInstance {
    static URLProtocolLog *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [URLProtocolLog new];
    });
    return instance;
}

- (instancetype)init
{
    if (self = [super init]) {
        queue = dispatch_queue_create("rxdata.urlprotocol.log", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

+ (void)logWithPrefix:(NSString *)prefix format:(NSString *)format, ...
{
    
    va_list arguments;
    va_start(arguments, format);
    URLProtocolLog *log = [self sharedInstance];
    [log logWithPrefix:prefix format:format arguments:arguments];
    va_end(arguments);
}

- (void)logWithPrefix:(NSString *)prefix format:(NSString *)format arguments:(va_list)arguments
{
    assert(prefix != nil);
    assert(format != nil);
    
    NSString *  now;
    NSString *      str;
    
    now = [NSDate date].description;
    
    NSThread *thread = [NSThread currentThread];
    
    str = [[NSString alloc] initWithFormat:format arguments:arguments];
    assert(str != nil);
    
    fprintf(stderr, "[%s][%p][%s][%s] %s\n",now.UTF8String, thread, thread.name.UTF8String, [prefix UTF8String], [str UTF8String]);
}

@end
