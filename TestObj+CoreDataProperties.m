//
//  TestObj+CoreDataProperties.m
//  FirstIMAPP
//
//  Created by zhouBao on 2017/5/5.
//  Copyright © 2017年 MyOrg. All rights reserved.
//

#import "TestObj+CoreDataProperties.h"

@implementation TestObj (CoreDataProperties)

+ (NSFetchRequest<TestObj *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"TestObj"];
}

@dynamic attri1;
@dynamic attri2;

@end
