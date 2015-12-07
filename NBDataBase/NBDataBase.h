//
//  NBDataBase.h
//  pengpeng
//
//  Created by feng on 14/12/9.
//  Copyright (c) 2014年 AsiaInnovations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabaseAdditions.h"
#import "NBSQLStatementHelper.h"
@class FMDatabaseQueue;
@class NBBaseDBTableModel;
@interface NBDataBase : NSObject
{
    FMDatabaseQueue *_fmdbQueue;
}
@property (nonatomic,strong) FMDatabaseQueue *fmdbQueue;
@property (nonatomic,strong) NSString *dbPath;
@property (nonatomic,strong) NSMutableArray *registedClassesArray;



//单例声明
+ (NBDataBase *)sharedInstance;

/// 保存数据库表对应的model类
- (void)addRegisteClass:(Class)modelClass;

/// 配置db库文件路径
- (void)setupDBWithDBPath:(NSString *)dbPath;

/// 数据库升级
+ (void)updateTableInDB;
/// 动态建一批表
+ (void)createTable:(Class)tableClass tableNames:(NSArray *)tableNameArray;
/// 动态建一张表
+ (void)createTable:(Class)tableClass tableName:(NSString *)tableName;

/// 关闭数据库
- (void)closeDB;

/// 库的当前版本号
- (NSString *)version;

/// 库的缓存的版本号
- (NSString *)cacheVersion;

//插入数据
- (BOOL)insertToDBWithModel:(NBBaseDBTableModel *)model;
- (BOOL)insertToDBWithModel:(NBBaseDBTableModel *)model replace:(BOOL)replace;
- (BOOL)insertToDBWithModel:(NBBaseDBTableModel *)model
                      table:(Class )tableClass
                    replace:(BOOL)replace;

- (BOOL)insertToDBWithModel:(NBBaseDBTableModel *)model update:(BOOL)update;
- (BOOL)insertToDBWithModel:(NBBaseDBTableModel *)model
                     update:(BOOL)update
                    columns:(id)columns;
- (BOOL)insertToDBWithModel:(NBBaseDBTableModel *)model
                      table:(Class )tableClass;
- (void)insertToDBWithModel:(NBBaseDBTableModel *)model
                      table:(Class )tableClass
                     update:(BOOL)update;


//插入一组数据
- (void)insertToDBWithDataArray:(NSArray *)array;
- (void)insertToDBWithDataArray:(NSArray *)array table:(Class )tableClass;
- (void)insertToDBWithDataArray:(NSArray *)array
                          table:(Class )tableClass
                        replace:(BOOL)replace;
/**
 *	 向表中插入数据
 *   如果不存在就插入
 *   如果存在，replace:YES替换;replace:NO啥也不做
 */
- (void)insertToDBWithDataArray:(NSArray *)array
                          table:(Class )tableClass
                        columns:(id)columns
                        replace:(BOOL)replace;

/**
 *	 向表中插入数据
 *   如果不存在就插入
 *   如果存在，update:YES更新;update:NO啥也不做
 */
- (void)insertToDBWithDataArray:(NSArray *)array
                          table:(Class )tableClass
                         update:(BOOL)update;
- (void)insertToDBWithDataArray:(NSArray *)array
                          table:(Class )tableClass
                        columns:(id)columns
                         update:(BOOL)update;


/// 删除数据
- (BOOL)deleteRecordWithModel:(NBBaseDBTableModel *)model;

/// 删除记录，使用where条件
- (BOOL)deleteRecordFromTable:(Class)tableClass where:(id)where;
/// 清除表里所有数据
- (BOOL)eraseTable:(Class)tableClass;

/// 删除表
- (BOOL)deleteTable: (Class)tableClass;


//更新数据表
-(BOOL)updateWithModel:(NBBaseDBTableModel *)model;
-(BOOL)updateWithModel:(NBBaseDBTableModel *)model
                   set:(id)sets;
-(BOOL)updateWithModel:(NBBaseDBTableModel *)model
                 table:(Class)tableClass
                   set:(id)sets;
-(BOOL)updateTable:(Class)modelClass
               set:(id)sets
             where:(id)where;


//查询数据

/// 获取所有数据
-(NSMutableArray *)query:(Class)modelClass;

/// 获取所有数据，带条件
-(NSMutableArray *)query:(Class)modelClass where:(id)where;

/// 获取所有数据，带条件、排序
-(NSMutableArray *)query:(Class)modelClass where:(id)where orderBy:(NSString *)orderBy;

-(NSMutableArray *)query:(Class)modelClass
                   where:(id)where
                 orderBy:(NSString *)orderBy
                  offset:(NSInteger)offset
                   count:(NSInteger)count;
-(NSMutableArray *)query:(Class)modelClass
                 columns:(id)columns
                   where:(id)where
                 orderBy:(NSString *)orderBy
                  offset:(NSInteger)offset
                   count:(NSInteger)count;


-(NSMutableArray *)query:(Class)modelClass
                   table:(Class)tableClass;
-(NSMutableArray *)query:(Class)modelClass
                   table:(Class)tableClass
                   where:(id)where;
-(NSMutableArray *)query:(Class)modelClass
                   table:(Class)tableClass
                   where:(id)where
                 orderBy:(NSString *)orderBy;
-(NSMutableArray *)query:(Class)modelClass
                   table:(Class)tableClass
                   where:(id)where
                 orderBy:(NSString *)orderBy
                  offset:(NSInteger)offset
                   count:(NSInteger)count;


-(NSMutableArray *)query:(Class)modelClass
                   table:(Class)tableClass
                 columns:(id)columns;
-(NSMutableArray *)query:(Class)modelClass
                   table:(Class)tableClass
                 columns:(id)columns
                   where:(id)where;
-(NSMutableArray *)query:(Class)modelClass
                   table:(Class)tableClass
                 columns:(id)columns
                   where:(id)where
                 orderBy:(NSString *)orderBy;
-(NSMutableArray *)query:(Class)modelClass
                   table:(Class)tableClass
                 columns:(id)columns
                   where:(id)where
                 orderBy:(NSString *)orderBy
                  offset:(NSInteger)offset
                   count:(NSInteger)count;
-(NSMutableArray *)query:(Class)modelClass//出库的model
                   table:(Class)tableClass//主表
        followTableClass:(Class)followTableClass//从表
                 columns:(id)columns//主表列
           followColumns:(id)followColumns//从表列
         leftJoinColumns:(id)leftJoinColumns//联合的列
                   where:(id)where//主表条件
             followWhere:(id)followWhere//从表条件
                 orderBy:(NSString *)orderBy//排序
                  offset:(NSInteger)offset
                   count:(NSInteger)count;




//获得单一数据

/// 查询一条整型数据
- (NSInteger)queryIntegerdata:(Class)tableClass
                  fieldName:(NSString *)fieldName;
- (NSInteger)queryIntegerdata:(Class)tableClass
                  fieldName:(NSString *)fieldName
                      where:(id)where;

/// 查询一条布尔型数据
- (BOOL)queryBooldata:(Class)tableClass fieldName:(NSString *)fieldName;
- (BOOL)queryBooldata:(Class)tableClass fieldName:(NSString *)fieldName where:(id)where;

/// 查询一条字符串型数据
- (NSString *)queryStringdata:(Class)tableClass fieldName:(NSString *)fieldName;
- (NSString *)queryStringdata:(Class)tableClass fieldName:(NSString *)fieldName where:(id)where;

/// 查询一条二进制数据型数据
- (NSData *)queryBlobdata:(Class)tableClass fieldName:(NSString *)fieldName;

/// 查询一条自定义数据
- (NBBaseDBTableModel *)queryData:(Class)tableClass where:(id)where;
- (NBBaseDBTableModel *)queryData:(Class)tableClass where:(id)where orderBy:(NSString *)orderBy;


/// 查询数据库表是否存在
- (BOOL)isExistTable:(Class)tableClass;

/// 查询某条记录是否存在
- (BOOL)isExistsWithModel:(NBBaseDBTableModel *)model;



#pragma mark - - 插入一条记录 自定义tableName
- (BOOL)insertToDBWithModel:(NBBaseDBTableModel *)model
                  tableName:(NSString *)tableName
                     update:(BOOL)update
                    columns:(id)columns;
- (BOOL)insertToDBWithModel:(NBBaseDBTableModel *)model
                  tableName:(NSString *)tableName
                    replace:(BOOL)replace;
- (BOOL)insertToDBWithModel:(NBBaseDBTableModel *)model
                  tableName:(NSString *)tableName;
- (void)insertToDBWithModel:(NBBaseDBTableModel *)model
                  tableName:(NSString *)tableName
                     update:(BOOL)update;

#pragma mark - - 插入一条以上记录 自定义tableName
- (void)insertToDBWithDataArray:(NSArray *)array
                      tableName:(NSString *)tableName;

- (void)insertToDBWithDataArray:(NSArray *)array
                      tableName:(NSString *)tableName
                        replace:(BOOL)replace;

- (void)insertToDBWithDataArray:(NSArray *)array
                      tableName:(NSString *)tableName
                        columns:(id)columns
                        replace:(BOOL)replace;

- (void)insertToDBWithDataArray:(NSArray *)array
                      tableName:(NSString *)tableName
                         update:(BOOL)update;

- (void)insertToDBWithDataArray:(NSArray *)array
                      tableName:(NSString *)tableName
                        columns:(id)columns
                         update:(BOOL)update;

#pragma mark - 删除操作 自定义tableName
/// 删除记录
- (BOOL)deleteRecordWithModel:(NBBaseDBTableModel *)model tableName:(NSString *)tableName;
/// 删除记录
- (BOOL)deleteRecordFromTableName:(NSString *)tableName where:(id)where;
/// 删除表
- (BOOL)deleteTableName:(NSString *)tableName;
/// 清除表-清数据
- (BOOL)eraseTableName:(NSString *)tableName;


#pragma mark - 更新操作 自定义tableName
-(BOOL)updateTableName:(NSString *)tableName
                   set:(id)sets
                 where:(id)where;
-(BOOL)updateWithModel:(NBBaseDBTableModel *)model
             tableName:(NSString *)tableName
                   set:(id)sets;

#pragma mark  - 更新一条以上记录
-(void)updateWithDataArray:(NSArray *)array;
-(void)updateWithDataArray:(NSArray *)array set:(id)sets;
-(void)updateWithDataArray:(NSArray *)array table:(Class)tableClass set:(id)sets;
-(void)updateWithDataArray:(NSArray *)array tableName:(NSString *)tableName;
-(void)updateWithDataArray:(NSArray *)array tableName:(NSString *)tableName set:(id)sets;

#pragma mark- - 查询多条数据（出库的modelClass和数据库表对应的tableName不一样的情况下使用以下接口）
-(NSMutableArray *)query:(Class)modelClass
               tableName:(NSString *)tableName;
-(NSMutableArray *)query:(Class)modelClass
               tableName:(NSString *)tableName
                   where:(id)where;
-(NSMutableArray *)query:(Class)modelClass
               tableName:(NSString *)tableName
                   where:(id)where
                 orderBy:(NSString *)orderBy;
-(NSMutableArray *)query:(Class)modelClass
               tableName:(NSString *)tableName
                   where:(id)where
                 orderBy:(NSString *)orderBy
                  offset:(NSInteger)offset
                   count:(NSInteger)count;
-(NSMutableArray *)query:(Class)modelClass
               tableName:(NSString *)tableName
                 columns:(id)columns;
-(NSMutableArray *)query:(Class)modelClass
               tableName:(NSString *)tableName
                 columns:(id)columns
                   where:(id)where;
-(NSMutableArray *)query:(Class)modelClass
               tableName:(NSString *)tableName
                 columns:(id)columns
                   where:(id)where
                 orderBy:(NSString *)orderBy;
-(NSMutableArray *)query:(Class)modelClass
               tableName:(NSString *)tableName
                 columns:(id)columns
                   where:(id)where
                 orderBy:(NSString *)orderBy
                  offset:(NSInteger)offset
                   count:(NSInteger)count;
-(NSMutableArray *)query:(Class)modelClass
               tableName:(NSString *)tableName
         followTableName:(NSString *)followTableName
                 columns:(id)columns
           followColumns:(id)followColumns
         leftJoinColumns:(id)leftJoinColumns
                   where:(id)where
             followWhere:(id)followWhere
                 orderBy:(NSString *)orderBy
                  offset:(NSInteger)offset
                   count:(NSInteger)count;

#pragma mark- 查询一条数据 自定义tableName
// 整型
- (NSInteger)queryIntegerdataWithTableName:(NSString *)tableName fieldName:(NSString *)fieldName;
// 整型
- (NSInteger)queryIntegerdataWithTableName:(NSString *)tableName
                                 fieldName:(NSString *)fieldName
                                     where:(id)where;

// 布尔型
- (BOOL)queryBooldataWithTableName:(NSString *)tableName fieldName:(NSString *)fieldName;

// 布尔型
- (BOOL)queryBooldataWithTableName:(NSString *)tableName fieldName:(NSString *)fieldName where:(id)where;

// 字符串型
- (NSString *)queryStringdataWithTableName:(NSString *)tableName fieldName:(NSString *)fieldName;
// 字符串型
- (NSString *)queryStringdataWithTableName:(NSString *)tableName
                                 fieldName:(NSString *)fieldName
                                     where:(id)where;

// 二进制数据型
- (NSData *)queryBlobdataWithTableName:(NSString *)tableName fieldName:(NSString *)fieldName;

// 自定义对象
- (NBBaseDBTableModel *)queryData:(Class)modelClass
                        tableName:(NSString *)tableName
                            where:(id)where;

// 自定义对象
- (NBBaseDBTableModel *)queryData:(Class)modelClass
                        tableName:(NSString *)tableName
                            where:(id)where
                          orderBy:(NSString *)orderBy;
#pragma mark - 是否存在记录 自定义tableName
/// 是否有对应的表
- (BOOL)isExistTableName:(NSString *)tableName;
/// 是否存在记录
- (BOOL)isExistsWithModel:(NBBaseDBTableModel *)model tableName:(NSString *)tableName;

@end
