//
//  TestObj+CoreDataProperties.h
//  FirstIMAPP
//
//  Created by zhouBao on 2017/5/5.
//  Copyright © 2017年 MyOrg. All rights reserved.
//

#import "TestObj+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface TestObj (CoreDataProperties)

+ (NSFetchRequest<TestObj *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *attri1;
@property (nullable, nonatomic, retain) NSData *attri2;

@end

NS_ASSUME_NONNULL_END
