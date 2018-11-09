//
//  DNSConfigureProxie.m
//  RxData
//
//  Created by caotianyuan on 2018/9/3.
//

#import "DNSConfigureProxie.h"

@implementation DNSConfigureProxie

+ (BOOL) configureProxies:(NSString *)urlString
{
    NSDictionary *proxySettings = CFBridgingRelease(CFNetworkCopySystemProxySettings());
    
    NSArray *proxies = nil;
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    
    proxies = CFBridgingRelease(CFNetworkCopyProxiesForURL((__bridge CFURLRef)url,
                                                           (__bridge CFDictionaryRef)proxySettings));
    if (proxies.count > 0)
    {
        NSDictionary *settings = [proxies objectAtIndex:0];
        NSString *host = [settings objectForKey:(NSString *)kCFProxyHostNameKey];
        NSString *port = [settings objectForKey:(NSString *)kCFProxyPortNumberKey];
        
        if (host || port)
        {
            return YES;
        }
    }
    return NO;
}

+ (BOOL) configureProxies {
    CFDictionaryRef dicRef = CFNetworkCopySystemProxySettings();
    const CFStringRef proxyCFstr = (const CFStringRef)CFDictionaryGetValue(dicRef, (const void*)kCFNetworkProxiesHTTPProxy);
    NSString* proxy = (__bridge NSString *)proxyCFstr;
    CFRelease(dicRef);
    if (proxy) {
        return YES;
    } else {
        return NO;
    }
}

@end
