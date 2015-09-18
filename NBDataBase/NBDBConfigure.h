//
//  NBDBConfigure.h
//  NBDataBaseDemo
//
//  Created by ios_feng on 15/9/18.
//  Copyright © 2015年 pepper. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NBDBConfigure : NSObject
+ (void)setLogOutNotificationName:(NSString *)notificationName;
+ (void)setVersion:(NSString *)version;
+ (void)setEncrypted:(BOOL)encrypted secretkey:(NSString *)secretkey;
+ (void)setCurrentUserId:(NSString *)currentUserId;
+ (NSString *)version;
+ (NSString *)secretkey;
+ (NSString *)currentUserId;
+ (BOOL)isEncrypted;
+ (NSString *)logOutNotificationName;

@end
