//
//  DNSConfigureProxie.h
//  RxData
//
//  Created by caotianyuan on 2018/9/3.
//

#import <Foundation/Foundation.h>

@interface DNSConfigureProxie : NSObject

/**
 是否在设备上开启了代理

 @return YES: 开启了代理, NO: 没有开启代理
 */
+ (BOOL) configureProxies;

@end
