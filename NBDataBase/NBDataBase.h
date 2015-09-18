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
-(BOOL)updateWithModel:(NBBaseDBTableModel *)model where:(id)where;
-(BOOL)updateWithModel:(NBBaseDBTableModel *)model
                   set:(id)sets
                 where:(id)where;
-(BOOL)updateWithModel:(NBBaseDBTableModel *)model
                 table:(Class)tableClass
                   set:(id)sets
                 where:(id)where;
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



@end