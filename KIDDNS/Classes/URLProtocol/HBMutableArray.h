//
//  HBMutableArray.h
//  RxData
//
//  Created by yiyang on 2018/8/29.
//

#import <Foundation/Foundation.h>

/**
 线程安全的可读写的数组
 */
@interface HBMutableArray : NSObject

- (BOOL)containsObject:(id)object;
- (void)addObject:(id)object;
- (void)removeObject:(id)object;
- (id)objectAtIndex:(NSUInteger)index;

@end
