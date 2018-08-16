//
//  NBDataBase.h
//  pengpeng
//
//  Created by feng on 14/12/9.
//  Copyright (c) 2014年 AsiaInnovations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NBSQLStatementHelper.h"
@class FMDatabaseQueue;
@class NBBaseDBTableModel;
@interface NBDataBase : NSObject
{
    FMDatabaseQueue *_fmdbQueue;
}
@property (nonatomic, strong, nonnull) FMDatabaseQueue *fmdbQueue;
@property (nonatomic, strong, nonnull) NSString *dbPath;
@property (nonatomic, strong, nonnull) NSMutableArray *registedClassesArray;
@property (nonatomic, assign, readonly) BOOL isOpened;
@property (nonatomic, assign, readonly) BOOL isForceClosed;

//单例声明
+ (instancetype _Nonnull)sharedInstance;

/// 保存数据库表对应的model类
- (void)addRegisteClass:(Class _Nonnull)modelClass;

/// 配置db库文件路径
- (void)setupDBWithDBPath:(NSString * _Nonnull)dbPath;

/// 配置db库文件路径,源db是否已经加密
- (void)setupDBWithDBPath:(NSString * _Nonnull)dbPath isEncrypted:(BOOL)isEncrypted;

/// 数据库升级
+ (void)updateTableInDB;
/// 动态建一批表
+ (void)createTable:(Class _Nonnull)tableClass tableNames:(NSArray * _Nonnull)tableNameArray;
/// 动态建一张表
+ (void)createTable:(Class _Nonnull)tableClass tableName:(NSString * _Nonnull)tableName;

/// 关闭数据库
- (void)closeDB;

/// 库的当前版本号
- (NSString * _Nonnull)version;

/// 库的缓存的版本号
- (NSString * _Nonnull)cacheVersion;

//插入数据
- (BOOL)insertToDBWithModel:(NBBaseDBTableModel * _Nonnull)model;
- (BOOL)insertToDBWithModel:(NBBaseDBTableModel * _Nonnull)model replace:(BOOL)replace;
- (BOOL)insertToDBWithModel:(NBBaseDBTableModel * _Nonnull)model
                      table:(Class _Nonnull)tableClass
                    replace:(BOOL)replace;

- (BOOL)insertToDBWithModel:(NBBaseDBTableModel * _Nonnull)model update:(BOOL)update;
- (BOOL)insertToDBWithModel:(NBBaseDBTableModel * _Nonnull)model
                     update:(BOOL)update
                    columns:(id _Nonnull)columns;
- (BOOL)insertToDBWithModel:(NBBaseDBTableModel * _Nonnull)model
                      table:(Class _Nonnull)tableClass;
- (void)insertToDBWithModel:(NBBaseDBTableModel * _Nonnull)model
                      table:(Class _Nonnull)tableClass
                     update:(BOOL)update;


//插入一组数据
- (void)insertToDBWithDataArray:(NSArray * _Nonnull)array;
- (void)insertToDBWithDataArray:(NSArray * _Nonnull)array table:(Class _Nonnull)tableClass;
- (void)insertToDBWithDataArray:(NSArray * _Nonnull)array
                          table:(Class _Nonnull)tableClass
                        replace:(BOOL)replace;
/**
 *     向表中插入数据
 *   如果不存在就插入
 *   如果存在，replace:YES替换;replace:NO啥也不做
 */
- (void)insertToDBWithDataArray:(NSArray * _Nonnull)array
                          table:(Class _Nonnull)tableClass
                        columns:(id _Nonnull)columns
                        replace:(BOOL)replace;

/**
 *     向表中插入数据
 *   如果不存在就插入
 *   如果存在，update:YES更新;update:NO啥也不做
 */
- (void)insertToDBWithDataArray:(NSArray * _Nonnull)array
                          table:(Class _Nonnull)tableClass
                         update:(BOOL)update;
- (void)insertToDBWithDataArray:(NSArray * _Nonnull)array
                          table:(Class _Nonnull)tableClass
                        columns:(id _Nullable)columns
                         update:(BOOL)update;


/// 删除数据
- (BOOL)deleteRecordWithModel:(NBBaseDBTableModel * _Nonnull)model;

/// 删除记录，使用where条件
- (BOOL)deleteRecordFromTable:(Class _Nonnull)tableClass where:(id _Nonnull)where;
/// 清除表里所有数据
- (BOOL)eraseTable:(Class _Nonnull)tableClass;

/// 删除表
- (BOOL)deleteTable: (Class _Nonnull)tableClass;


//更新数据表
-(BOOL)updateWithModel:(NBBaseDBTableModel * _Nonnull)model
                 where:(id  _Nonnull)where;
-(BOOL)updateWithModel:(NBBaseDBTableModel * _Nonnull)model
                   set:(id _Nonnull)sets
                 where:(id _Nullable)where;
-(BOOL)updateWithModel:(NBBaseDBTableModel * _Nonnull)model
                 table:(Class _Nonnull)tableClass
                   set:(id _Nullable)sets
                 where:(id _Nullable)where;
-(BOOL)updateTable:(Class _Nonnull)modelClass
               set:(id _Nonnull)sets
             where:(id _Nonnull)where;


//查询数据

/// 获取所有数据
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass;

/// 获取所有数据，带条件
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass where:(id _Nonnull)where;

/// 获取所有数据，带条件、排序
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass where:(id _Nullable)where orderBy:(NSString * _Nullable)orderBy;

-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                             where:(id _Nullable)where
                           orderBy:(NSString *_Nullable)orderBy
                            offset:(NSInteger)offset
                             count:(NSInteger)count;
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                           columns:(id _Nonnull)columns
                             where:(id _Nonnull)where
                           orderBy:(NSString * _Nonnull)orderBy
                            offset:(NSInteger)offset
                             count:(NSInteger)count;


-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                             table:(Class _Nonnull)tableClass;
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                             table:(Class _Nonnull)tableClass
                             where:(id _Nonnull)where;
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                             table:(Class _Nonnull)tableClass
                             where:(id _Nonnull)where
                           orderBy:(NSString * _Nonnull)orderBy;
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                             table:(Class _Nullable)tableClass
                             where:(id _Nullable)where
                           orderBy:(NSString * _Nullable)orderBy
                            offset:(NSInteger)offset
                             count:(NSInteger)count;


-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                             table:(Class _Nonnull)tableClass
                           columns:(id _Nonnull)columns;
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                             table:(Class _Nonnull)tableClass
                           columns:(id _Nonnull)columns
                             where:(id _Nonnull)where;
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                             table:(Class _Nonnull)tableClass
                           columns:(id _Nonnull)columns
                             where:(id _Nonnull)where
                           orderBy:(NSString * _Nonnull)orderBy;
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                             table:(Class _Nullable)tableClass
                           columns:(id _Nullable)columns
                             where:(id _Nullable)where
                           orderBy:(NSString * _Nullable)orderBy
                            offset:(NSInteger)offset
                             count:(NSInteger)count;
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass//出库的model
                             table:(Class _Nonnull)tableClass//主表
                  followTableClass:(Class _Nonnull)followTableClass//从表
                           columns:(id _Nonnull)columns//主表列
                     followColumns:(id _Nonnull)followColumns//从表列
                   leftJoinColumns:(id _Nonnull)leftJoinColumns//联合的列
                             where:(id _Nonnull)where//主表条件
                       followWhere:(id _Nonnull)followWhere//从表条件
                           orderBy:(NSString * _Nonnull)orderBy//排序
                            offset:(NSInteger)offset
                             count:(NSInteger)count;




//获得单一数据

/// 查询一条整型数据
- (NSInteger)queryIntegerdata:(Class _Nonnull)tableClass
                    fieldName:(NSString * _Nonnull)fieldName;
- (NSInteger)queryIntegerdata:(Class _Nonnull)tableClass
                    fieldName:(NSString * _Nonnull)fieldName
                        where:(id _Nullable)where;

/// 查询一条布尔型数据
- (BOOL)queryBooldata:(Class _Nonnull)tableClass fieldName:(NSString * _Nonnull)fieldName;
- (BOOL)queryBooldata:(Class _Nonnull)tableClass fieldName:(NSString * _Nonnull)fieldName where:(id _Nonnull)where;

/// 查询一条字符串型数据
- (NSString * _Nullable)queryStringdata:(Class _Nonnull)tableClass fieldName:(NSString * _Nonnull)fieldName;
- (NSString * _Nullable)queryStringdata:(Class _Nonnull)tableClass fieldName:(NSString * _Nonnull)fieldName where:(id _Nonnull)where;

/// 查询一条二进制数据型数据
- (NSData * _Nullable)queryBlobdata:(Class _Nonnull)tableClass fieldName:(NSString * _Nonnull)fieldName;

/// 查询一条自定义数据
- (NBBaseDBTableModel * _Nullable)queryData:(Class _Nonnull)tableClass where:(id _Nonnull)where;
- (NBBaseDBTableModel * _Nullable)queryData:(Class _Nonnull)tableClass where:(id _Nonnull)where orderBy:(NSString * _Nonnull)orderBy;


/// 查询数据库表是否存在
- (BOOL)isExistTable:(Class _Nonnull)tableClass;

/// 查询某条记录是否存在
- (BOOL)isExistsWithModel:(NBBaseDBTableModel * _Nonnull)model;



#pragma mark - - 插入一条记录 自定义tableName
- (BOOL)insertToDBWithModel:(NBBaseDBTableModel * _Nonnull)model
                  tableName:(NSString * _Nonnull)tableName
                     update:(BOOL)update
                    columns:(id _Nonnull)columns;
- (BOOL)insertToDBWithModel:(NBBaseDBTableModel * _Nonnull)model
                  tableName:(NSString * _Nonnull)tableName
                    replace:(BOOL)replace;
- (BOOL)insertToDBWithModel:(NBBaseDBTableModel * _Nonnull)model
                  tableName:(NSString * _Nonnull)tableName;
- (void)insertToDBWithModel:(NBBaseDBTableModel * _Nonnull)model
                  tableName:(NSString * _Nonnull)tableName
                     update:(BOOL)update;

#pragma mark - - 插入一条以上记录 自定义tableName
- (void)insertToDBWithDataArray:(NSArray * _Nonnull)array
                      tableName:(NSString * _Nonnull)tableName;

- (void)insertToDBWithDataArray:(NSArray * _Nonnull)array
                      tableName:(NSString * _Nonnull)tableName
                        replace:(BOOL)replace;

- (void)insertToDBWithDataArray:(NSArray * _Nonnull)array
                      tableName:(NSString * _Nonnull)tableName
                        columns:(id _Nonnull)columns
                        replace:(BOOL)replace;

- (void)insertToDBWithDataArray:(NSArray * _Nonnull)array
                      tableName:(NSString * _Nonnull)tableName
                         update:(BOOL)update;

- (void)insertToDBWithDataArray:(NSArray * _Nonnull)array
                      tableName:(NSString * _Nonnull)tableName
                        columns:(id _Nullable)columns
                         update:(BOOL)update;

#pragma mark - 删除操作 自定义tableName
/// 删除记录
- (BOOL)deleteRecordWithModel:(NBBaseDBTableModel * _Nonnull)model tableName:(NSString * _Nonnull)tableName;
/// 删除记录
- (BOOL)deleteRecordFromTableName:(NSString * _Nonnull)tableName where:(id _Nonnull)where;
/// 删除表
- (BOOL)deleteTableName:(NSString * _Nonnull)tableName;
/// 清除表-清数据
- (BOOL)eraseTableName:(NSString * _Nonnull)tableName;


#pragma mark - 更新操作 自定义tableName
-(BOOL)updateTableName:(NSString * _Nonnull)tableName
                   set:(id _Nonnull)sets
                 where:(id _Nonnull)where;
-(BOOL)updateWithModel:(NBBaseDBTableModel * _Nonnull)model
             tableName:(NSString * _Nonnull)tableName
                   set:(id _Nonnull)sets
                 where:(id _Nullable)where;

#pragma mark  - 更新一条以上记录
-(void)updateWithDataArray:(NSArray * _Nonnull)array;
-(void)updateWithDataArray:(NSArray * _Nonnull)array set:(id _Nullable)sets;
-(void)updateWithDataArray:(NSArray * _Nonnull)array table:(Class _Nonnull)tableClass set:(id _Nullable)sets;
-(void)updateWithDataArray:(NSArray * _Nonnull)array tableName:(NSString * _Nonnull)tableName;
-(void)updateWithDataArray:(NSArray * _Nonnull)array tableName:(NSString * _Nonnull)tableName set:(id _Nullable)sets;

#pragma mark- - 查询多条数据（出库的modelClass和数据库表对应的tableName不一样的情况下使用以下接口）
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                         tableName:(NSString * _Nonnull)tableName;
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                         tableName:(NSString * _Nonnull)tableName
                             where:(id _Nonnull)where;
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                         tableName:(NSString * _Nonnull)tableName
                             where:(id _Nonnull)where
                           orderBy:(NSString * _Nonnull)orderBy;
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                         tableName:(NSString * _Nonnull)tableName
                             where:(id _Nonnull)where
                           orderBy:(NSString * _Nullable)orderBy
                            offset:(NSInteger)offset
                             count:(NSInteger)count;
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                         tableName:(NSString * _Nonnull)tableName
                           columns:(id _Nonnull)columns;
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                         tableName:(NSString * _Nonnull)tableName
                           columns:(id _Nonnull)columns
                             where:(id _Nonnull)where;
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                         tableName:(NSString * _Nonnull)tableName
                           columns:(id _Nonnull)columns
                             where:(id _Nonnull)where
                           orderBy:(NSString * _Nonnull)orderBy;
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                         tableName:(NSString * _Nonnull)tableName
                           columns:(id _Nullable)columns
                             where:(id _Nullable)where
                           orderBy:(NSString * _Nullable)orderBy
                            offset:(NSInteger)offset
                             count:(NSInteger)count;
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                         tableName:(NSString * _Nonnull)tableName
                   followTableName:(NSString * _Nonnull)followTableName
                           columns:(id _Nonnull)columns
                     followColumns:(id _Nonnull)followColumns
                   leftJoinColumns:(id _Nonnull)leftJoinColumns
                             where:(id _Nonnull)where
                       followWhere:(id _Nonnull)followWhere
                           orderBy:(NSString * _Nonnull)orderBy
                            offset:(NSInteger)offset
                             count:(NSInteger)count;

#pragma mark- 查询一条数据 自定义tableName
// 整型
- (NSInteger)queryIntegerdataWithTableName:(NSString * _Nonnull)tableName fieldName:(NSString * _Nonnull)fieldName;
// 整型
- (NSInteger)queryIntegerdataWithTableName:(NSString * _Nonnull)tableName
                                 fieldName:(NSString * _Nonnull)fieldName
                                     where:(id _Nullable)where;

// 布尔型
- (BOOL)queryBooldataWithTableName:(NSString * _Nonnull)tableName fieldName:(NSString * _Nonnull)fieldName;

// 布尔型
- (BOOL)queryBooldataWithTableName:(NSString * _Nonnull)tableName fieldName:(NSString * _Nonnull)fieldName where:(id _Nonnull)where;

// 字符串型
- (NSString * _Nullable)queryStringdataWithTableName:(NSString * _Nonnull)tableName fieldName:(NSString * _Nonnull)fieldName;
// 字符串型
- (NSString * _Nullable)queryStringdataWithTableName:(NSString * _Nonnull)tableName
                                           fieldName:(NSString * _Nonnull)fieldName
                                               where:(id _Nonnull)where;

// 二进制数据型
- (NSData * _Nullable)queryBlobdataWithTableName:(NSString * _Nonnull)tableName fieldName:(NSString * _Nonnull)fieldName;

// 自定义对象
- (NBBaseDBTableModel * _Nullable)queryData:(Class _Nonnull)modelClass
                                  tableName:(NSString * _Nonnull)tableName
                                      where:(id _Nonnull)where;

// 自定义对象
- (NBBaseDBTableModel * _Nullable)queryData:(Class _Nonnull)modelClass
                                  tableName:(NSString * _Nonnull)tableName
                                      where:(id _Nonnull)where
                                    orderBy:(NSString * _Nonnull)orderBy;
#pragma mark - 是否存在记录 自定义tableName
/// 是否有对应的表
- (BOOL)isExistTableName:(NSString * _Nonnull)tableName;
/// 是否存在记录
- (BOOL)isExistsWithModel:(NBBaseDBTableModel * _Nonnull)model tableName:(NSString * _Nonnull)tableName;

@end
