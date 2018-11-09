//
//  HBURLSessionMap.h
//  RxData
//
//  Created by yiyang on 2018/8/31.
//

#import <Foundation/Foundation.h>

@interface HBURLSessionMap : NSObject

+ (NSURLSession *)fetchSessionOfTask:(NSURLSessionTask *)task;
+ (void)recordSessionTask:(NSURLSessionTask *)task ofSession:(NSURLSession *)session;

@end
