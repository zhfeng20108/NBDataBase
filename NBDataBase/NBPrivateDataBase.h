//
//  NBPrivateDataBase.h
//  pengpeng
//
//  Created by ios_feng on 15/4/15.
//  Copyright (c) 2015年 AsiaInnovations. All rights reserved.
//

#import "NBDataBase.h"

@interface NBPrivateDataBase : NBDataBase
//单例声明
+ (NBPrivateDataBase *)sharedInstance;

//处理退出登录
- (void)onLogOut;
@end
