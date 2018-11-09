//
//  HBMutableArray.m
//  RxData
//
//  Created by yiyang on 2018/8/29.
//

#import "HBMutableArray.h"

@interface HBMutableArray()
@property (nonatomic, strong) NSMutableArray *array;
@property (nonatomic, strong) dispatch_queue_t queue;
@end

@implementation HBMutableArray

- (instancetype)init {
    if (self = [super init]) {
        _array = [NSMutableArray new];
        _queue = dispatch_queue_create("rxdata.hbarray.queue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (BOOL)containsObject:(id)object
{
    __block BOOL result = NO;
    dispatch_sync(_queue, ^{
        result = [self.array containsObject:object];
    });
    return result;
}

- (id)objectAtIndex:(NSUInteger)index
{
    __block id result = nil;
    dispatch_sync(_queue, ^{
        result = [self.array objectAtIndex:index];
    });
    return result;
}

- (void)addObject:(id)object
{
    dispatch_barrier_async(_queue, ^{
        [self.array addObject:object];
    });
}

- (void)removeObject:(id)object
{
    dispatch_barrier_async(_queue, ^{
        [self.array removeObject:object];
    });
}

@end
