//
//  URLProtocolLog.h
//  RxData
//
//  Created by yiyang on 2018/8/29.
//

#import <Foundation/Foundation.h>

@interface URLProtocolLog : NSObject

+ (void)logWithPrefix:(NSString *)prefix format:(NSString *)format, ...;

@end
