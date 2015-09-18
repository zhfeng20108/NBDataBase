//
//  NBDBConfigure.m
//  NBDataBaseDemo
//
//  Created by ios_feng on 15/9/18.
//  Copyright © 2015年 pepper. All rights reserved.
//

#import "NBDBConfigure.h"
static NSString *version_value;
static NSString *secret_key;
static NSString *current_userId;
static BOOL is_encrypted = NO;
static NSString *notification_name;
@implementation NBDBConfigure
+ (void)setLogOutNotificationName:(NSString *)notificationName
{
    notification_name = notificationName;
}

+ (void)setEncrypted:(BOOL)encrypted secretkey:(NSString *)secretkey
{
    is_encrypted = encrypted;
    secret_key = secretkey;
}

+ (void)setVersion:(NSString *)version
{
    version_value = version;
}

+ (void)setCurrentUserId:(NSString *)currentUserId
{
    current_userId = currentUserId;
}

+ (NSString *)version
{
    NSAssert(version_value.length>0, @"请配置数据库版本号");
    return version_value;
}

+ (NSString *)secretkey
{
    NSAssert(secret_key.length>0, @"请配置数据库密码");
    return secret_key;
}

+ (NSString *)currentUserId
{
    NSAssert(current_userId.length>0, @"请配置私有数据库当前用户");
    return current_userId;
}

+ (BOOL)isEncrypted
{
    return is_encrypted;
}

+ (NSString *)logOutNotificationName
{
    NSAssert(notification_name.length>0, @"请配置私有数据库登出时的通知名");
    return notification_name;
}


@end
