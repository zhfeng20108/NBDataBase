//
//  NBSQLStatementHelper.h
//  pengpeng
//
//  Created by feng on 14/12/11.
//  Copyright (c) 2014年 AsiaInnovations. All rights reserved.
//

#import <Foundation/Foundation.h>
#define NBSQLText @"text"
#define NBSQLInt @"integer"
#define NBSQLDouble @"float"
#define NBSQLBlob @"blob"
#define NBSQLNull @"null"

@class NBBaseDBTableModel;
@class NBDBQueryParams;

//生成建表的sql语句
NSString *createTableSQL(Class modelClass);
NSString *createTableSQLWithTableName(Class tableClass,NSString *tableName);
//生成插入语句
NSString *createInsertSQL(NBBaseDBTableModel *model,NSString *tableName,BOOL replace,NSMutableArray * __autoreleasing * insertValues);
//生成插入语句
NSString *createInsertSQLWithColumns(NBBaseDBTableModel *model,NSString *tableName,id columns,BOOL replace,NSMutableArray *__autoreleasing *insertValues);
//生成插入语句
NSString *createInsertSQLWithModelAndBeginClass(NBBaseDBTableModel *model,Class beginClass,BOOL replace,NSMutableArray * __autoreleasing * insertValues);

//生成更新语句
NSString *createUpdateSQL(NBBaseDBTableModel *model,id sets,id where,NSMutableArray *__autoreleasing *updateValues);
//生成更新语句
NSString *createUpdateSQLWithModelAndTableClass(NBBaseDBTableModel *model,Class tableClass,id sets,id where,NSMutableArray *__autoreleasing *updateValues);
NSString *createUpdateSQLWithModelAndTableName(NBBaseDBTableModel *model,NSString *tableName,id sets,id where,NSMutableArray *__autoreleasing *updateValues);
//生成更新语句
NSString *createUpdateSQLWithTableName(NSString *tableName, id sets,id where,NSMutableArray *__autoreleasing *updateValues);

//生成查询语句
NSString *createSelectSQLWithParams(NBDBQueryParams *params,NSMutableArray *__autoreleasing *selectValues);
//生成查询语句
NSString *createUnionSelectSQLWithParams(NBDBQueryParams *params,NSMutableArray *__autoreleasing *selectValues);
//生成查询语句
NSString *createSelectSQLWithPrimaryKey(NBBaseDBTableModel *model,NSString *fieldName,NSMutableArray *__autoreleasing *primaryKeyValues);
NSString *createSelectSQLWithPrimaryKeyAndTableName(NBBaseDBTableModel *model,NSString *tableName,NSString *fieldName,NSMutableArray *__autoreleasing *primaryKeyValues);
//生成查询语句
NSString *createSelectSQL(Class modelClass,NSString *fieldName);
NSString *createSelectSQLWithTableName(NSString *tableName,NSString *fieldName);

//生成删除语句
NSString *createDeleteSQL(NBBaseDBTableModel *model,id where,NSMutableArray *__autoreleasing*deleteValues);
/// 生成删除语句
NSString *createDeleteSQLWithModelAndTableName(NBBaseDBTableModel *model,NSString *tableName,id where,NSMutableArray *__autoreleasing *deleteValues);
//生成删除语句
NSString *createDeleteSQLWithTableName(NSString *tableName,id where,NSMutableArray *__autoreleasing *deleteValues);







