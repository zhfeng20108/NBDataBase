//
//  NBBaseDBTableModel.h
//  pengpeng
//
//  Created by feng on 14/12/12.
//  Copyright (c) 2014年 AsiaInnovations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NBSQLStatementHelper.h"
#import "NBDataBase.h"
#import "NBDBNameHelper.h"
@protocol NBDBTableModelProtocol

@required
+ (NBDataBase *)getDataBase;//配置库
+ (NSString*)getTableName;//配置数据库表名

@end

@interface NBBaseDBTableModel : NSObject<NBDBTableModelProtocol>

/// 入库，如果数据库已存在，是插入不进去的
- (BOOL)saveToDB;

/// 以更新的方式入库，会更新掉所有的字段，如果数据库里不存在这条记录，就会插入
- (BOOL)saveToDBUseUpdate;

/// 以替换的方式入库，如果数据库已存在记录则替换掉原来的记录，否则就直接插入
- (BOOL)saveToDBUseReplace;

/// 插入或更新指定的字段
- (BOOL)saveToDBUseUpdateWithColumns:(id)columns;

/// 更新指定的字段
- (BOOL)updateDBWithColumns:(id)columns;

/// 自动取主键，删记录
- (BOOL)deleteToDB;

/// 检查表中是否存在这条记录
-(BOOL)isExistsFromDB;


/// 入库，如果数据库已存在，是插入不进去的
- (BOOL)saveToDBTable:(NSString *)tableName;

/// 以更新的方式入库，会更新掉所有的字段，如果数据库里不存在这条记录，就会插入
- (void)saveToDBUseUpdateInTable:(NSString *)tableName;

/// 以替换的方式入库，如果数据库已存在记录则替换掉原来的记录，否则就直接插入
- (BOOL)saveToDBUseReplaceInTable:(NSString *)tableName;

/// 插入或更新指定的字段
- (BOOL)saveToDBTable:(NSString *)tableName updateColumns:(id)columns;

/// 更新指定的字段
- (BOOL)updateDBTable:(NSString *)tableName columns:(id)columns;

/// 自动取主键，删记录
- (BOOL)deleteFromDBTable:(NSString *)tableName;

/// 检查表中是否存在这条记录
-(BOOL)isExistsFromDBTable:(NSString *)tableName;

/// 给model的属性赋值
-(void)setValue:(id)value forKey:(NSString *)key typeEncoding:(const char *)typeEncoding;
@end
