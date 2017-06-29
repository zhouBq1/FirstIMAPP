//
//  suanfaTest.m
//  FirstIMAPP
//
//  Created by zhouBao on 2017/5/3.
//  Copyright © 2017年 MyOrg. All rights reserved.
//

#import "suanfaTest.h"

#define SOURCE_ARRAY_COUNT 10000

#define SWAP_I(A ,B) {NSInteger tmp = A ;A = B ;B = tmp;}

@interface suanfaTest ()

{
    NSMutableArray *sourceArray;
    NSLock * lock;
}
@end

@implementation suanfaTest

-(id) init
{
    if (self = [super init]) {
        
        sourceArray = [NSMutableArray array];
        [self getSourceArray];
    }
    return self;
}

#pragma mark 排序测试
-(void) testFS
{
    NSDate * beforeDate = [NSDate date];
    NSMutableArray * sortedArray = [self sortedArrayByFastSort:sourceArray];
    NSDate * afterDate = [NSDate date];
    NSTimeInterval timeinterval = [afterDate timeIntervalSinceDate:beforeDate];
    if (sortedArray ) {
        
        NSLog(@"success : %@",[NSString stringWithFormat:@"fs suanfa cost %f ,sorted array is %@" ,timeinterval ,sortedArray]);
    }
    else
    {
        NSLog(@"fail :%@" ,[NSString stringWithFormat:@"fs suanfa sorted fail"]);
    }
}

-(void) testMS
{

    NSDate * beforeDate = [NSDate date];
    NSMutableArray * sortedArray = [self sortedArrayByMergeSort:sourceArray];
    NSDate * afterDate = [NSDate date];
    NSTimeInterval timeinterval = [afterDate timeIntervalSinceDate:beforeDate];
    if (sortedArray) {
        NSLog(@"success: %@" ,[NSString stringWithFormat:@"ms suanfa cost %f ,sorted array is %@" ,timeinterval ,sortedArray]);
    }
    else
    {
        NSLog(@"fail : %@" ,[NSString stringWithFormat:@"ms suanfa sorted fail"]);
    }
}

#pragma mark 查找测试
-(void) testSearch_bs
{
    int searchNumIndex = rand()%SOURCE_ARRAY_COUNT;
    int searchNum = [sourceArray[searchNumIndex] intValue];
    NSMutableArray * sortedArray = [self sortedArrayByFastSort:sourceArray];
    NSDate * beforeDate = [NSDate date];
    NSInteger index = [self recursionForBinarySearch:searchNum inArray:sortedArray];
    NSDate *afterDate = [NSDate date];
    NSTimeInterval timeinterval = [afterDate timeIntervalSinceDate:beforeDate];
    if ([sortedArray indexOfObject:@(searchNum)] == index) {
        NSLog(@"success :%@" ,[NSString stringWithFormat:@"bs cost %f ,the searched index :%ld is equal to function objIndex:%ld" ,timeinterval ,index ,[sortedArray indexOfObject:@(searchNum)]]);
    }
    else
    {
        if (index < 0) {
            NSLog(@"fail : %@" ,[NSString stringWithFormat:@"bs didn't search the obj index"]);
        }
        NSLog(@"fail : %@" ,[NSString stringWithFormat:@"bs search failed ,index:%ld ,the function objIndex:%ld" ,index ,[sortedArray indexOfObject:@(searchNum)] ]);
    }
}
#pragma mark ----
#pragma mark 快速排序
/**
 快速排序算法

 @param unsortedArray 传入的原始数据
 @return 排序之后的数据
 */
-(NSMutableArray *) sortedArrayByFastSort:(NSArray *) unsortedArray
{
    NSMutableArray *toSortArray = [NSMutableArray arrayWithArray:unsortedArray];
    [self recursionToSort:toSortArray byPivotIndex:[unsortedArray count]/2];
    return toSortArray;
}


/**
 递归获取部分排序 ,

 @param tmpArray 传入需要排序的临时数组
 @param index 基准数的index
 */
-(void) recursionToSort:(NSMutableArray *) tmpArray byPivotIndex:(NSInteger) index
{
    @autoreleasepool {
        if (!tmpArray ||  tmpArray.count < index || tmpArray.count <= 1) {
            return;
        }
        [lock lock];
        NSNumber *pivotValue = [tmpArray objectAtIndex:index];
        int pivot = [pivotValue intValue];
        NSMutableArray *smallerArray = [NSMutableArray array];
        NSMutableArray *biggerArray = [NSMutableArray array];
        NSMutableArray *equalArray = [NSMutableArray array];
        
        for (NSNumber * value in tmpArray) {
            if ([value intValue] < pivot)
            {
                [smallerArray addObject:value];
            }
            else if([value intValue] > pivot)
            {
                [biggerArray addObject:value];
            }
            else
            {
                [equalArray addObject:value];
            }
        }
        
        
        [tmpArray removeAllObjects];
        [self recursionToSort:smallerArray byPivotIndex:[smallerArray count]/2];
        [tmpArray addObjectsFromArray:smallerArray];
        [tmpArray addObjectsFromArray:equalArray];
        [self recursionToSort:biggerArray byPivotIndex:[biggerArray count]/2];
        [tmpArray addObjectsFromArray:biggerArray];
    
        [lock unlock];
    }
}

#pragma mark --- 
#pragma mark 堆排序
-(NSMutableArray *) sortedArrayByHeapSort: (NSMutableArray *) unsortedArray
{
    NSMutableArray * toSortedArray = [NSMutableArray arrayWithArray:unsortedArray];
    return toSortedArray;
}

-(void) recursionForHeapSort:(NSMutableArray *) tmpArray
{
    
}

#pragma mark --- 
#pragma mark 归并排序
-(NSMutableArray *) sortedArrayByMergeSort:(NSMutableArray *) unsortedArray
{
    NSMutableArray * toSortedArray = [NSMutableArray arrayWithArray:unsortedArray];
    NSMutableArray * sortedArray = [NSMutableArray arrayWithCapacity:[toSortedArray count]];
    [self recursionForMergeSort:toSortedArray startP1:0 startP2:[toSortedArray count]/2 sortedArray:&sortedArray];
    return  sortedArray;
}


/**
 归并排序过程中使用的递归方法
 不能再递归过程中直接操作传入的原始数据的数。传入之后对象仍然持有该实例 ，？为什么不能同步更改，

 @param tmpArray 传入的元数据
 @param start1 进行归并排序的开始位置
 @param start2 归并排序的第二个起始位置
 @param sortedArray 用于存储排序之后的数据。
 */
-(void) recursionForMergeSort:(NSMutableArray *) tmpArray startP1:(NSInteger) start1 startP2:(NSInteger) start2 sortedArray:(NSMutableArray **) sortedArray
{
    if (start2 < start1) {
        SWAP_I(start1, start2);
    }
    if (start1 > [tmpArray count]|| start2 > [tmpArray count] || [tmpArray count] <= 1) {
        [(*sortedArray) addObjectsFromArray:tmpArray];
        return;
    }
    @autoreleasepool {
        NSMutableArray * toSortArray1 = [NSMutableArray arrayWithArray:[tmpArray subarrayWithRange:NSMakeRange(start1, start2 - start1)]];
        NSMutableArray * toSortArray2 = [NSMutableArray arrayWithArray:[tmpArray subarrayWithRange:NSMakeRange(start2, [tmpArray count] - start2)]];
        
        NSMutableArray * sortedArray1 = [NSMutableArray arrayWithCapacity:[toSortArray1 count]];
        NSMutableArray * sortedArray2 = [NSMutableArray arrayWithCapacity:[toSortArray2 count]];
        [self recursionForMergeSort:toSortArray1 startP1:0 startP2:[toSortArray1 count]/2 sortedArray:&sortedArray1];
        [self recursionForMergeSort:toSortArray2 startP1:0 startP2:[toSortArray2 count]/2 sortedArray:&sortedArray2];
        
        
        for (NSInteger index1 = 0 ,index2 = 0 ; index1 < [sortedArray1 count] && index2 < [sortedArray2 count]; ) {
            
            if ([sortedArray1[index1] intValue] >= [sortedArray2[index2] intValue]) {
                [*sortedArray addObject:sortedArray2[index2]];
            }
            else
            {
                [*sortedArray addObject:sortedArray1[index1]];
            }
            //这里tosort count为1时候没有进行比较 ，直接将之后的数据进行添加，错误。
            if (index1 >= [sortedArray1 count] -1 && [sortedArray1[index1] intValue] < [sortedArray2[index2] intValue]) {
                [*sortedArray addObjectsFromArray:[sortedArray2 subarrayWithRange:NSMakeRange(index2, [sortedArray2 count] - index2)]];
                return;
            }
            else if(index2 >= [sortedArray2 count] - 1 && [sortedArray1[index1] intValue] > [sortedArray2[index2] intValue])
            {
                [*sortedArray addObjectsFromArray:[sortedArray1 subarrayWithRange:NSMakeRange(index1, [sortedArray1 count] - index1)]];
                return ;
            }
            
            if ([sortedArray1[index1] intValue] >= [sortedArray2[index2] intValue]) {
                index2 ++;
            }
            else
            {
                index1 ++;
            }
        }
    }
}

#pragma mark ----
#pragma mark 查找算法 ---二分查找

-(NSInteger) recursionForBinarySearch:(int) searchValue inArray:(NSArray *) searchArray
{
    
    
    return -1;
}


#pragma mark ----
#pragma mark 获取元数据
/**
 获取排序的初始化数据
 */
-(void) getSourceArray
{

    if (sourceArray && [sourceArray count] > 0) {
        return;
    }
    for (NSInteger index =0 ; index < SOURCE_ARRAY_COUNT; index ++) {
        int randV = rand();
        NSNumber *randValue = @(randV);
        [sourceArray addObject:randValue];
    }
    NSLog(@"the source array :%@" ,sourceArray);
}
@end
