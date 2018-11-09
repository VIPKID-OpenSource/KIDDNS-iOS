//
//  DNSCenter.m
//  KIDDNS
//
//  Created by yiyang on 2018/9/14.
//

#import "DNSCenter.h"
#import "DNSConfigureProxie.h"
#import "RxHTTPDNSURLProtocol.h"
#import "RxSNIURLProtocol.h"
#import <objc/runtime.h>

#import <AlicloudHttpDNS/AlicloudHttpDNS.h>

static NSMutableArray<Class> *newProtocolClasses = nil;

@implementation KIDDNSConfig

@end

@interface DNSCenter ()<HttpDNSDegradationDelegate>

@property (nonatomic, strong) HttpDnsService *dnsService;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, assign) int accountID;

@property (nonatomic, strong) NSMutableArray *loggers;

@end

@implementation DNSCenter

+ (instancetype)defaultCenter
{
    static DNSCenter *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        newProtocolClasses = [NSMutableArray new];
        [self swizzleProtocolClasses];
        
        instance = [[DNSCenter alloc] initWithAccountID:0 andKey:nil];
        
    });
    return instance;
}

- (instancetype)initWithAccountID:(int)accountID andKey:(NSString *)key
{
    if (self = [super init]) {
        self.automaticDNS = YES;
        self.key = key;
        self.accountID = accountID;
    }
    return self;
}

- (void)initializeDNSService
{
    
    self.dnsService = [[HttpDnsService alloc] initWithAccountID:self.accountID secretKey:self.key];
    [self.dnsService setCachedIPEnabled:YES];
    [self.dnsService setExpiredIPEnabled:YES];
    [self.dnsService setHTTPSRequestEnabled:YES];
    self.dnsService.delegate = self;
    
#if DEBUG
    [self.dnsService setLogEnabled:YES];
#else
    [self.dnsService setLogEnabled:NO];
#endif
}

- (void)initializeDNSServiceWithConfig:(KIDDNSConfig *)config
{
    self.accountID = config.accountId;
    self.key = config.key;
    
    [self initializeDNSServiceWithPresolvedHost:config.presolvedHosts];
}

- (void)initializeDNSServiceWithPresolvedHost:(NSArray<NSString *> *)hosts
{
    [self initializeDNSService];
    [self.dnsService setPreResolveHosts:hosts];
}

- (NSString *)dnsResultForURL:(NSString *)url
{
    NSURL *originalURL = [NSURL URLWithString:url];
    if (originalURL == nil) {
        return nil;
    }
    if ([DNSConfigureProxie configureProxies]) {
        return nil;
    }
    NSString *originalHost = originalURL.host;
    if ([self isIP:originalHost]) {
        return nil;
    }
    NSString *dnsResultIP = [self.dnsService getIpByHostAsyncInURLFormat:originalHost];
    
    if (dnsResultIP.length == 0) {
        return nil;
    }
    if ([dnsResultIP isEqualToString:originalHost]) {
        return nil;
    }
    NSURLComponents *originalComponents = [NSURLComponents componentsWithURL:originalURL resolvingAgainstBaseURL:NO];
    originalComponents.host = dnsResultIP;
    
    return originalComponents.URL.absoluteString;
}

- (void)automaticEnableDidChange:(BOOL)automatic
{
    if (automatic) {
        [[self class] registerURLProtocol:[RxHTTPDNSURLProtocol class]];
        [[self class] registerURLProtocol:[RxSNIURLProtocol class]];
    } else {
        [[self class] unregisterURLProtocol:[RxHTTPDNSURLProtocol class]];
        [[self class] unregisterURLProtocol:[RxSNIURLProtocol class]];
    }
}

+ (void)registerURLProtocol:(Class)protocolClass
{
    [NSURLProtocol registerClass:protocolClass];
    [newProtocolClasses addObject:protocolClass];
}

+ (void)unregisterURLProtocol:(Class)protocolClass
{
    [NSURLProtocol unregisterClass:protocolClass];
    [newProtocolClasses removeObject:protocolClass];
}

+ (void)swizzleProtocolClasses
{
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    Class configClass = object_getClass(config);
    Method method1 = class_getInstanceMethod(configClass, @selector(protocolClasses));
    Method method2 = class_getInstanceMethod([NSURLSessionConfiguration class], @selector(fake_protocolClasses));
    method_exchangeImplementations(method1, method2);
}

#pragma mark - Loggers

- (void)addLogger:(id<KIDDNSLogger>)logger
{
    [self.loggers addObject:logger];
}

- (void)removeLogger:(id<KIDDNSLogger>)logger
{
    [self.loggers removeObject:logger];
}

#pragma mark - Getter & Setter

- (void)setAutomaticDNS:(BOOL)automaticDNS
{
    if (_automaticDNS != automaticDNS) {
        _automaticDNS = automaticDNS;
        [self automaticEnableDidChange:_automaticDNS];
    }
}

- (NSMutableArray *)loggers
{
    if (_loggers == nil) {
        _loggers = [NSMutableArray new];
    }
    return _loggers;
}

- (BOOL)isIP:(NSString *)ip
{
    NSString *ipv4 = @"^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$";
    NSString *ipv6 = @"([a-f0-9]{1,4}(:[a-f0-9]{1,4}){7}|[a-f0-9]{1,4}(:[a-f0-9]{1,4}){0,7}::[a-f0-9]{0,4}(:[a-f0-9]{1,4}){0,7})";
    NSPredicate *predicateIPV4 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", ipv4];
    NSPredicate *predicateIPV6 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", ipv6];
    if ([predicateIPV4 evaluateWithObject:ip] || [predicateIPV6 evaluateWithObject:ip]) {
        return YES;
    }
    return NO;
}

#pragma mark - HttpDNSDegradationDelegate

- (BOOL)shouldDegradeHTTPDNS:(NSString *)hostName
{
    if (hostName.length == 0) {
        return YES;
    }
    BOOL shouldDegrade = NO;
    NSArray<NSString *> *blackList = [self.blackList copy];
    for (NSString *item in blackList) {
        if ([hostName rangeOfString:item options:NSRegularExpressionSearch].location != NSNotFound) {
            shouldDegrade = YES;
            break;
        }
    }
    if (shouldDegrade == NO) {
        shouldDegrade = YES;
        NSArray<NSString *> *whiteList = [self.whiteList copy];
        for (NSString *item in whiteList) {
            if ([hostName rangeOfString:item options:NSRegularExpressionSearch].location != NSNotFound) {
                shouldDegrade = NO;
                break;
            }
        }
        // 如果没有设置白名单，则视为都在白名单内
        if (whiteList.count == 0) {
            shouldDegrade = NO;
        }
    }
    return shouldDegrade;
}

@end

@interface NSURLSessionConfiguration(protocol)
@end

@implementation NSURLSessionConfiguration(protocol)

- (NSArray<Class> *)fake_protocolClasses
{
    NSArray<Class> *clazzes = [self fake_protocolClasses];
    if (clazzes.count == 0) {
        return @[];
    }
    NSMutableArray *resultProtocols = [NSMutableArray arrayWithArray:clazzes];
    NSArray<Class> *newProtocols = [newProtocolClasses copy];
    if (newProtocols.count == 0) {
        return clazzes;
    }
    [newProtocols enumerateObjectsUsingBlock:^(Class  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([resultProtocols containsObject:obj] == NO) {
            [resultProtocols insertObject:obj atIndex:0];
        }
    }];
    
    return resultProtocols;
}

@end
