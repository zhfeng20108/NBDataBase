//
//  NBPrivateDataBase.m
//  pengpeng
//
//  Created by ios_feng on 15/4/15.
//  Copyright (c) 2015年 AsiaInnovations. All rights reserved.
//

#import "NBPrivateDataBase.h"
#import "NBDBDefine.h"
#import "NBDBConfigure.h"
@implementation NBPrivateDataBase

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype _Nonnull)sharedInstance
{
    static NBPrivateDataBase *__NBDataBase_instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __NBDataBase_instance = [[self alloc] init];
    });
    return __NBDataBase_instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLogOut) name:kNBLogOutNotificationName object:nil];
    }
    return self;
}
- (void)onLogOut
{
    //关闭数据库
    [self closeDB];
}

@end
