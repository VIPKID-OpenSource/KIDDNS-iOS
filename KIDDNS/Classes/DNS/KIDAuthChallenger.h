//
//  KIDAuthChallenger.h
//  KIDDNS
//
//  Created by yiyang on 2018/9/14.
//

#import <Foundation/Foundation.h>

@interface KIDAuthChallenger : NSObject

/**
 处理证书校验的逻辑

 @param host 证书对应的域名
 @param session 请求对应的NSURLSession
 @param challenge 证书challenge
 @param completionHandler 校验的结果回调
 */
+ (void)didReceiveChallengeOnHost:(NSString *)host session:(NSURLSession *)session challenge:(NSURLAuthenticationChallenge *)challenge completion:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler;

@end
