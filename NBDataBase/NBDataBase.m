//
//  NBDataBase.m
//  pengpeng
//
//  Created by feng on 14/12/9.
//  Copyright (c) 2014年 AsiaInnovations. All rights reserved.
//

#import "NBDataBase.h"
#import "NBSQLStatementHelper.h"
#import "NBBaseDBTableModel.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "NBDBNameHelper.h"
#import "NBDBHelper.h"
#import "NBDBDefine.h"
#import <FMDB/FMDatabaseQueue.h>
#import "NBDBConfigure.h"
#import "NBPrivateDataBase.h"
#import <sqlite3.h>
#import <pthread/pthread.h>

@interface NBDataBase () {
    pthread_mutex_t _lock;
}
//打开数据库
- (BOOL)openDB;

-(NSMutableArray * _Nonnull)queryBaseWithParams:(NBDBQueryParams * _Nonnull)params;
@end;


@implementation NBDataBase

- (void)dealloc
{
    //关闭数据库连接
    [self closeDB];
}

//单例实现
+ (instancetype _Nonnull)sharedInstance
{
    static NBDataBase *__NBDataBase_instance = nil;
    
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
        _registedClassesArray = [[NSMutableArray alloc] init];
        pthread_mutex_init(&_lock, NULL);
    }
    return self;
}

- (void)addRegisteClass:(Class _Nonnull)modelClass
{
    [self.registedClassesArray addObject:[NSValue valueWithPointer:(__bridge const void *)(modelClass)]];
}


- (void)setupDBWithDBPath:(NSString * _Nonnull)dbPath
{
    if (_dbPath == dbPath) {
        return;
    }
    pthread_mutex_lock(&_lock);
    _dbPath = dbPath;
    _isForceClosed = NO;
    pthread_mutex_unlock(&_lock);
}

/// 配置db库文件路径,源db是否已经加密
- (void)setupDBWithDBPath:(NSString * _Nonnull)dbPath isEncrypted:(BOOL)isEncrypted
{
    if (_dbPath == dbPath) {
        return;
    }
    pthread_mutex_lock(&_lock);
    _dbPath = dbPath;
    [self saveEncryptedStatus:isEncrypted];
    _isForceClosed = NO;
    pthread_mutex_unlock(&_lock);
}

#pragma mark - 建表/数据库升级
+ (void)updateTableInDB;
{
    //用事务来操作
    [[[[self class] sharedInstance] fmdbQueue] inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (NSValue *value in [[[self class] sharedInstance] registedClassesArray])
        {
            Class clazz = [value pointerValue];
            if ([clazz isSubclassOfClass:[NBBaseDBTableModel class]]) {
                NSString *tableName = [clazz getTableName];
                if (![db tableExists:tableName]) {
                    //表不存在，就创建
                    NSString *sql = createTableSQL(clazz);
                    if (sql) {
                        [db executeUpdate:sql];
                    }
                } else {
                    //表已存在，追加新增字段
                    NSMutableDictionary *propertiesDic = [NSMutableDictionary dictionary];
                    unsigned int outCount = 0;
                    Class c = clazz;
                    NSString *classString = NSStringFromClass(c);
                    while (![classString isEqualToString:NSStringFromClass(NSObject.class)]){
                        objc_property_t *properties = class_copyPropertyList(c, &outCount);
                        for (unsigned int i = 0; i<outCount; i++)
                        {
                            objc_property_t property = properties[i];
                            // name
                            const char *char_name = property_getName(property);
                            NSString *propertyName = [NSString stringWithUTF8String:char_name];
                            
                            //如果不是要写入数据库，就继续查找
                            if (![NBDBHelper isColumn:propertyName]) {
                                continue;
                            }
                            char *typeEncoding = property_copyAttributeValue(property, "T");
                            NSString *columnType = [NBDBHelper columnTypeStringWithDataType:typeEncoding];
                            free(typeEncoding);
                            if (!columnType) {//不支持的类型，继续
                                continue;
                            }
                            [propertiesDic setObject:columnType forKey:FMColumnNameFromPropertyName(propertyName)];
                        }
                        
                        c = class_getSuperclass(c);
                        classString = NSStringFromClass(c);
                        
                        free(properties);
                    }
                    
                    FMResultSet *rs = [db getTableSchema:tableName];
                    //check if column is present in table schema
                    while ([rs next])
                    {
                        NSString *columnName = [rs stringForColumn:@"name"];
                        [propertiesDic removeObjectForKey:columnName];
                        
                    }
                    [rs close];
                    // all columns in table are the same with properties in model
                    if (propertiesDic.count == 0)
                    {
                        continue;
                    }
                    
                    for (NSString *key in [propertiesDic allKeys])
                    {
                        NSString *columnType = [propertiesDic objectForKey:key];
                        if (!columnType) {//不支持的类型
                            continue;
                        }
                        NSString *columnName = key;
                        NSString *sql = [NSString stringWithFormat:@"alter table %@ add column %@ %@", tableName, columnName, columnType];
                        
                        if (![db executeUpdate:sql])
                        {
                            NSLog(@"oh no, add column to db failed, sql:[%@], errro code:%d, error message:%@", sql, db.lastErrorCode, db.lastErrorMessage);
                        }
                    }
                    
                }
            }
        }
        
    }];
}


#pragma mark - 关闭数据库

- (void)closeDB;
{
    pthread_mutex_lock(&_lock);
    [self.fmdbQueue close];
    _isOpened = NO;
    _isForceClosed = YES;
    pthread_mutex_unlock(&_lock);
}

/// 动态建一批表
+ (void)createTable:(Class _Nonnull)tableClass tableNames:(NSArray * _Nonnull)tableNameArray
{
    if (![[[self class] sharedInstance] openDB]) return;
    //用事务来操作
    Class clazz = tableClass;
    [[[[self class] sharedInstance] fmdbQueue] inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (NSString *tableName in tableNameArray)
        {
            if ([clazz isSubclassOfClass:[NBBaseDBTableModel class]]) {
                if (![db tableExists:tableName]) {
                    //表不存在，就创建
                    NSString *sql = createTableSQL(clazz);
                    if (sql) {
                        [db executeUpdate:sql];
                    }
                } else {
                    //表已存在，追加新增字段
                    NSMutableDictionary *propertiesDic = [NSMutableDictionary dictionary];
                    unsigned int outCount = 0;
                    Class c = clazz;
                    NSString *classString = NSStringFromClass(c);
                    while (![classString isEqualToString:NSStringFromClass(NSObject.class)]){
                        objc_property_t *properties = class_copyPropertyList(c, &outCount);
                        for (unsigned int i = 0; i<outCount; i++)
                        {
                            objc_property_t property = properties[i];
                            // name
                            const char *char_name = property_getName(property);
                            NSString *propertyName = [NSString stringWithUTF8String:char_name];
                            
                            //如果不是要写入数据库，就继续查找
                            if (![NBDBHelper isColumn:propertyName]) {
                                continue;
                            }
                            char *typeEncoding = property_copyAttributeValue(property, "T");
                            NSString *columnType = [NBDBHelper columnTypeStringWithDataType:typeEncoding];
                            free(typeEncoding);
                            if (!columnType) {//不支持的类型，继续
                                continue;
                            }
                            [propertiesDic setObject:columnType forKey:FMColumnNameFromPropertyName(propertyName)];
                        }
                        
                        c = class_getSuperclass(c);
                        classString = NSStringFromClass(c);
                        
                        free(properties);
                    }
                    
                    FMResultSet *rs = [db getTableSchema:tableName];
                    //check if column is present in table schema
                    while ([rs next])
                    {
                        NSString *columnName = [rs stringForColumn:@"name"];
                        [propertiesDic removeObjectForKey:columnName];
                        
                    }
                    [rs close];
                    // all columns in table are the same with properties in model
                    if (propertiesDic.count == 0)
                    {
                        continue;
                    }
                    
                    for (NSString *key in [propertiesDic allKeys])
                    {
                        NSString *columnType = [propertiesDic objectForKey:key];
                        if (!columnType) {//不支持的类型
                            continue;
                        }
                        NSString *columnName = key;
                        NSString *sql = [NSString stringWithFormat:@"alter table %@ add column %@ %@", tableName, columnName, columnType];
                        
                        if (![db executeUpdate:sql])
                        {
                            NSLog(@"oh no, add column to db failed, sql:[%@], errro code:%d, error message:%@", sql, db.lastErrorCode, db.lastErrorMessage);
                        }
                    }
                    
                }
            }
        }
        
    }];
}

/// 动态建一张表
+ (void)createTable:(Class _Nonnull)tableClass tableName:(NSString * _Nonnull)tableName
{
    if (![[[self class] sharedInstance] openDB]) return;
    [[self class] createTable:tableClass tableNames:@[tableName]];
}

#pragma mark - 插入操作
#pragma mark - - 插入一条记录
- (BOOL)insertToDBWithModel:(NBBaseDBTableModel * _Nonnull)model;
{
    NSAssert(model, @"model 不能为空");
    return [self insertToDBWithModel:model replace:NO];
}

- (BOOL)insertToDBWithModel:(NBBaseDBTableModel * _Nonnull)model replace:(BOOL)replace;
{
    NSAssert(model, @"model 不能为空");
    if (![self openDB]) return NO;
    __block BOOL execute = NO;
    NSMutableArray *array = nil;
    //sql语句
    NSString *sql = createInsertSQL(model,nil,replace,&array);
    if (sql) {
        //插入操作
        [self.fmdbQueue inDatabase:^(FMDatabase *db) {
            execute = [db executeUpdate:sql withArgumentsInArray:array];
        }];
    }
    
    return execute;
}

- (BOOL)insertToDBWithModel:(NBBaseDBTableModel * _Nonnull)model
                      table:(Class _Nonnull)tableClass
                    replace:(BOOL)replace
{
    NSAssert(model, @"model 不能为空");
    NSAssert(tableClass, @"tableClass 不能为空");
    if (![self openDB]) return NO;
    __block BOOL execute = NO;
    [self.fmdbQueue inDatabase:^(FMDatabase *db) {
        NSMutableArray *insertValues = nil;
        NSString *sql = createInsertSQLWithModelAndBeginClass(model,tableClass,replace, &insertValues);
        if (sql) {
            if (insertValues.count > 0) {
                execute = [db executeUpdate:sql withArgumentsInArray:insertValues];
            }
        }
    }];
    return execute;
}

- (BOOL)insertToDBWithModel:(NBBaseDBTableModel * _Nonnull)model update:(BOOL)update;
{
    NSAssert(model, @"model 不能为空");
    if (![self openDB]) return NO;
    __block BOOL execute = NO;
    
    //查询有没有这条记录
    if (update&&[self isExistsWithModel:model]) {//走更新操作
        NSMutableArray *updateValues = nil;
        NSString *sql = createUpdateSQL(model, nil, nil, &updateValues);
        if (sql) {
            //更新操作
            [self.fmdbQueue inDatabase:^(FMDatabase *db) {
                if (updateValues.count > 0) {
                    execute = [db executeUpdate:sql withArgumentsInArray:updateValues];
                } else {
                    execute = [db executeUpdate:sql];
                }
            }];
        }
        
    } else {
        //插入操作
        execute = [self insertToDBWithModel:model replace:NO];
    }
    return execute;
}

- (BOOL)insertToDBWithModel:(NBBaseDBTableModel * _Nonnull)model update:(BOOL)update columns:(id  _Nonnull)columns;
{
    NSAssert(model, @"model 不能为空");
    NSAssert(columns, @"columns 不能为空");
    if (![self openDB]) return NO;
    __block BOOL execute = NO;
    
    //查询有没有这条记录
    if (update&&[self isExistsWithModel:model]) {//走更新操作
        NSMutableArray *updateValues = nil;
        NSString *sql = createUpdateSQL(model, columns, nil, &updateValues);
        if (sql) {
            //更新操作
            [self.fmdbQueue inDatabase:^(FMDatabase *db) {
                if (updateValues.count > 0) {
                    execute = [db executeUpdate:sql withArgumentsInArray:updateValues];
                } else {
                    execute = [db executeUpdate:sql];
                }
            }];
        }
        
    } else {
        //插入操作
        execute = [self insertToDBWithModel:model replace:NO];
    }
    return execute;
}

- (BOOL)insertToDBWithModel:(NBBaseDBTableModel * _Nonnull)model
                      table:(Class _Nonnull)tableClass
{
    NSAssert(model, @"model 不能为空");
    if (![self openDB]) return NO;
    __block BOOL execute = NO;
    [self.fmdbQueue inDatabase:^(FMDatabase *db) {
        NSMutableArray *insertValues = nil;
        NSString *sql = createInsertSQLWithModelAndBeginClass(model,tableClass,NO, &insertValues);
        if (sql) {
            if (insertValues.count > 0) {
                execute = [db executeUpdate:sql withArgumentsInArray:insertValues];
            }
        }
    }];
    return execute;
}

- (void)insertToDBWithModel:(NBBaseDBTableModel * _Nonnull)model
                      table:(Class _Nonnull)tableClass
                     update:(BOOL)update;
{
    NSAssert(model, @"model 不能为空");
    [self insertToDBWithDataArray:@[model] table:tableClass update:update];
}


#pragma mark - - 插入一条记录 自定义tableName
- (BOOL)insertToDBWithModel:(NBBaseDBTableModel * _Nonnull)model
                  tableName:(NSString * _Nonnull)tableName
                     update:(BOOL)update
                    columns:(id _Nonnull)columns;
{
    NSAssert(model, @"model 不能为空");
    NSAssert(columns, @"columns 不能为空");
    if (![self openDB]) return NO;
    __block BOOL execute = NO;
    
    //查询有没有这条记录
    if (update&&[self isExistsWithModel:model tableName:tableName]) {//走更新操作
        NSMutableArray *updateValues = nil;
        NSString *sql = createUpdateSQLWithModelAndTableName(model, tableName, columns, nil, &updateValues);
        if (sql) {
            //更新操作
            [self.fmdbQueue inDatabase:^(FMDatabase *db) {
                if (updateValues.count > 0) {
                    execute = [db executeUpdate:sql withArgumentsInArray:updateValues];
                } else {
                    execute = [db executeUpdate:sql];
                }
            }];
        }
        
    } else {
        //插入操作
        execute = [self insertToDBWithModel:model tableName:tableName replace:NO];
    }
    return execute;
}
- (BOOL)insertToDBWithModel:(NBBaseDBTableModel * _Nonnull)model
                  tableName:(NSString * _Nonnull)tableName
                    replace:(BOOL)replace
{
    NSAssert(model, @"model 不能为空");
    NSAssert(tableName, @"tableName 不能为空");
    if (![self openDB]) return NO;
    __block BOOL execute = NO;
    [self.fmdbQueue inDatabase:^(FMDatabase *db) {
        [self createTableIfNotExists:db tableClass:model.class tableName:tableName];
        NSMutableArray *insertValues = nil;
        NSString *sql = createInsertSQL(model, tableName, replace, &insertValues);
        if (sql) {
            if (insertValues.count > 0) {
                execute = [db executeUpdate:sql withArgumentsInArray:insertValues];
            }
        }
    }];
    return execute;
}


- (BOOL)insertToDBWithModel:(NBBaseDBTableModel * _Nonnull)model
                  tableName:(NSString * _Nonnull)tableName
{
    return [self insertToDBWithModel:model tableName:tableName replace:NO];
}

- (void)insertToDBWithModel:(NBBaseDBTableModel * _Nonnull)model
                  tableName:(NSString * _Nonnull)tableName
                     update:(BOOL)update;
{
    NSAssert(model, @"model 不能为空");
    [self insertToDBWithDataArray:@[model] tableName:tableName update:update];
}


#pragma mark - - 插入一条以上记录
- (void)insertToDBWithDataArray:(NSArray * _Nonnull)array
{
    if (![self openDB]) return;
    if (array.count == 0) {
        return;
    }
    Class tableClass = [array.firstObject class];
    [self insertToDBWithDataArray:array table:tableClass replace:NO];
}

- (void)insertToDBWithDataArray:(NSArray * _Nonnull)array
                          table:(Class  _Nonnull)tableClass
{
    [self insertToDBWithDataArray:array table:tableClass replace:NO];
}
- (void)insertToDBWithDataArray:(NSArray * _Nonnull)array
                          table:(Class _Nonnull)tableClass
                        replace:(BOOL)replace
{
    if (![self openDB]) return;
    if (array.count==0) {
        return;
    }
    if ([array.firstObject isKindOfClass:[NBBaseDBTableModel class]]){//自定义对象
        if (array.count == 1) {
            [self.fmdbQueue inDatabase:^(FMDatabase *db) {
                NBBaseDBTableModel *data = [array firstObject];
                NSMutableArray *insertValues = nil;
                NSString *sql = createInsertSQLWithModelAndBeginClass(data,tableClass,replace, &insertValues);
                if (sql) {
                    if (insertValues.count > 0) {
                        [db executeUpdate:sql withArgumentsInArray:insertValues];
                    }
                }
            }];
        } else {//开启事务
            [self.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                for(NBBaseDBTableModel *data in array){
                    NSMutableArray *insertValues = nil;
                    NSString *sql = createInsertSQLWithModelAndBeginClass(data,tableClass,replace, &insertValues);
                    if (sql) {
                        if (insertValues.count > 0) {
                            [db executeUpdate:sql withArgumentsInArray:insertValues];
                        }
                    }
                }
            }];
        }
        
    } else {
        NSAssert(YES, @"数组里的数据类型不正确");
    }
    
}


- (void)insertToDBWithDataArray:(NSArray * _Nonnull)array
                          table:(Class _Nonnull)tableClass
                        columns:(id _Nonnull)columns
                        replace:(BOOL)replace;
{
    NSString *tableName = [tableClass getTableName];
    [self insertToDBWithDataArray:array tableName:tableName columns:columns replace:replace];
}


- (void)insertToDBWithDataArray:(NSArray * _Nonnull)array
                          table:(Class _Nonnull)tableClass
                         update:(BOOL)update;
{
    [self insertToDBWithDataArray:array table:tableClass columns:nil update:update];
    
}

- (void)insertToDBWithDataArray:(NSArray * _Nonnull)array
                          table:(Class _Nonnull)tableClass
                        columns:(id _Nullable)columns
                         update:(BOOL)update;
{
    NSString *tableName = [tableClass getTableName];
    [self insertToDBWithDataArray:array tableName:tableName columns:columns update:update];
}

#pragma mark - - 插入一条以上记录 自定义tableName
- (void)insertToDBWithDataArray:(NSArray * _Nonnull)array
                      tableName:(NSString * _Nonnull)tableName
{
    [self insertToDBWithDataArray:array tableName:tableName replace:NO];
}

- (void)insertToDBWithDataArray:(NSArray * _Nonnull)array
                      tableName:(NSString * _Nonnull)tableName
                        replace:(BOOL)replace
{
    if (![self openDB]) return;
    if (array.count==0) {
        return;
    }
    if ([array.firstObject isKindOfClass:[NBBaseDBTableModel class]]){//自定义对象
        if (array.count == 1) {
            [self insertToDBWithModel:[array firstObject] tableName:tableName replace:replace];
        } else {//开启事务
            [self.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                [self createTableIfNotExists:db tableClass:[[array firstObject] class] tableName:tableName];
                for(NBBaseDBTableModel *data in array){
                    NSMutableArray *insertValues = nil;
                    NSString *sql = createInsertSQL(data,tableName,replace, &insertValues);
                    if (sql) {
                        if (insertValues.count > 0) {
                            [db executeUpdate:sql withArgumentsInArray:insertValues];
                        }
                    }
                }
            }];
        }
        
    } else {
        NSAssert(YES, @"数组里的数据类型不正确");
    }
    
}

- (void)insertToDBWithDataArray:(NSArray * _Nonnull)array
                      tableName:(NSString * _Nonnull)tableName
                        columns:(id _Nonnull)columns
                        replace:(BOOL)replace;
{
    if (![self openDB]) return;
    if (array.count == 0) {
        return;
    }
    if ([array.firstObject isKindOfClass:[NBBaseDBTableModel class]]){//自定义对象
        if (array.count == 1) {
            [self.fmdbQueue inDatabase:^(FMDatabase *db) {
                [self createTableIfNotExists:db tableClass:[[array firstObject] class] tableName:tableName];
                NBBaseDBTableModel *data = [array firstObject];
                NSMutableArray *insertValues = nil;
                NSString *sql = createInsertSQLWithColumns(data,tableName,columns, replace, &insertValues);
                if (sql) {
                    if (insertValues.count > 0) {
                        [db executeUpdate:sql withArgumentsInArray:insertValues];
                    }
                }
            }];
        } else {//开启事务
            [self.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                [self createTableIfNotExists:db tableClass:[[array firstObject] class] tableName:tableName];
                for(NBBaseDBTableModel *data in array){
                    NSMutableArray *insertValues = nil;
                    NSString *sql = createInsertSQLWithColumns(data,tableName,columns, replace, &insertValues);
                    if (sql) {
                        if (insertValues.count > 0) {
                            [db executeUpdate:sql withArgumentsInArray:insertValues];
                        }
                    }
                }
            }];
        }
    } else {//NSString,NSNumber
        NSAssert(columns&&[columns isKindOfClass:[NSString class]], @"columns不能为空");
        if ([array.firstObject isKindOfClass:[NSString class]]) {
            if(array.count == 1) {
                [self.fmdbQueue inDatabase:^(FMDatabase *db) {
                    [self createTableIfNotExists:db tableClass:[[array firstObject] class] tableName:tableName];
                    NSObject *data = [array firstObject];
                    NSString *sql = [NSString stringWithFormat:@"%@ into %@ (%@) values ('%@')",replace?@"replace":@"insert or ignore",tableName,columns,data];
                    [db executeUpdate:sql];
                }];
            } else {
                [self.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                    [self createTableIfNotExists:db tableClass:[[array firstObject] class] tableName:tableName];
                    for(NSObject *data in array){
                        NSString *sql = [NSString stringWithFormat:@"%@ into %@ (%@) values ('%@')",replace?@"replace":@"insert or ignore",tableName,columns,data];
                        [db executeUpdate:sql];
                    }
                }];
            }
            
        } else if ([array.firstObject isKindOfClass:[NSNumber class]]) {
            if(array.count == 1) {
                [self.fmdbQueue inDatabase:^(FMDatabase *db) {
                    [self createTableIfNotExists:db tableClass:[[array firstObject] class] tableName:tableName];
                    NSObject *data = [array firstObject];
                    NSString *sql = [NSString stringWithFormat:@"%@ into %@ (%@) values (%@)",replace?@"replace":@"insert or ignore",tableName,columns,data];
                    [db executeUpdate:sql];
                }];
            } else {
                [self.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                    [self createTableIfNotExists:db tableClass:[[array firstObject] class] tableName:tableName];
                    for(NSObject *data in array){
                        NSString *sql = [NSString stringWithFormat:@"%@ into %@ (%@) values (%@)",replace?@"replace":@"insert or ignore",tableName,columns,data];
                        [db executeUpdate:sql];
                    }
                }];
            }
            
        } else {
            NSAssert(YES, @"不支持的类型%@",[array.firstObject class]);
        }
    }
}

- (void)insertToDBWithDataArray:(NSArray * _Nonnull)array
                      tableName:(NSString * _Nonnull)tableName
                         update:(BOOL)update;
{
    [self insertToDBWithDataArray:array tableName:tableName columns:nil update:update];
    
}

- (void)insertToDBWithDataArray:(NSArray * _Nonnull)array
                      tableName:(NSString * _Nonnull)tableName
                        columns:(id _Nullable)columns
                         update:(BOOL)update;
{
    if (![self openDB]) return;
    if(!array || array.count<1){
        return;// 说明data里无数据，不需要操作数据库
    }
    if (!update) {
        [self insertToDBWithDataArray:array tableName:tableName columns:columns replace:NO];
    } else {
        if(array.count==1) {
            [self.fmdbQueue inDatabase:^(FMDatabase *db) {
                [self createTableIfNotExists:db tableClass:[[array firstObject] class] tableName:tableName];
                //获取表信息
                FMResultSet *rs = [db getTableSchema:tableName];
                NSMutableArray *keyArray = [[NSMutableArray alloc] init];
                while ([rs next]) {
                    if([rs intForColumn:@"pk"]) {
                        [keyArray addObject:[rs stringForColumn:@"name"]];
                    }
                }
                [rs close];
                
                if ([array.firstObject isKindOfClass:[NSDictionary class]]) {
                    NSAssert(YES, @"暂不支持字典形式写入，需要了再实现");
                    
                } else if ([array.firstObject isKindOfClass:[NBBaseDBTableModel class]]){//自定义对象
                    for(NBBaseDBTableModel *data in array){
                        NSMutableArray *primaryKeyValues = nil;
                        NSString *sql = createSelectSQLWithPrimaryKeyAndTableName(data,tableName,nil,&primaryKeyValues);
                        if (!sql) {
                            continue;
                        }
                        FMResultSet *rs = nil;
                        if (primaryKeyValues.count > 0) {
                            rs = [db executeQuery:sql withArgumentsInArray:primaryKeyValues];
                        } else {
                            rs = [db executeQuery:sql];
                        }
                        NSDictionary *infoDict = nil;
                        while ([rs next]) {
                            infoDict = [rs resultDictionary];
                            break;
                        }
                        [rs close];
                        if (infoDict) {//存在
                            //生成更新语句
                            NSMutableArray *updateValues = nil;
                            NSString *updateSql = createUpdateSQLWithModelAndTableName(data, tableName,columns, nil, &updateValues);
                            if (updateSql) {
                                if (updateValues.count > 0) {
                                    [db executeUpdate:updateSql withArgumentsInArray:updateValues];
                                } else {
                                    [db executeUpdate:updateSql];
                                }
                            }
                        } else {
                            NSMutableArray *array = nil;
                            //sql语句
                            NSString *sql = createInsertSQLWithColumns(data, tableName, columns, NO,&array);
                            if (sql) {
                                [db executeUpdate:sql withArgumentsInArray:array];
                            }
                        }
                    }
                    
                    
                }
            }];
        } else {
            [self.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                [self createTableIfNotExists:db tableClass:[[array firstObject] class] tableName:tableName];
                //获取表信息
                FMResultSet *rs = [db getTableSchema:tableName];
                NSMutableArray *keyArray = [[NSMutableArray alloc] init];
                while ([rs next]) {
                    if([rs intForColumn:@"pk"]) {
                        [keyArray addObject:[rs stringForColumn:@"name"]];
                    }
                }
                [rs close];
                
                if ([array.firstObject isKindOfClass:[NSDictionary class]]) {
                    NSAssert(NO, @"暂不支持字典形式写入，需要了再实现");
                    
                } else if ([array.firstObject isKindOfClass:[NBBaseDBTableModel class]]){//自定义对象
                    for(NBBaseDBTableModel *data in array){
                        NSMutableArray *primaryKeyValues = nil;
                        NSString *sql = createSelectSQLWithPrimaryKey(data,nil,&primaryKeyValues);
                        if (!sql) {
                            continue;
                        }
                        FMResultSet *rs = nil;
                        if (primaryKeyValues.count > 0) {
                            rs = [db executeQuery:sql withArgumentsInArray:primaryKeyValues];
                        } else {
                            rs = [db executeQuery:sql];
                        }
                        NSDictionary *infoDict = nil;
                        while ([rs next]) {
                            infoDict = [rs resultDictionary];
                            break;
                        }
                        [rs close];
                        if (infoDict) {//存在
                            //生成更新语句
                            NSMutableArray *updateValues = nil;
                            NSString *updateSql = createUpdateSQLWithModelAndTableClass(data, data.class,columns, nil, &updateValues);
                            if (updateSql) {
                                if (updateValues.count > 0) {
                                    [db executeUpdate:updateSql withArgumentsInArray:updateValues];
                                } else {
                                    [db executeUpdate:updateSql];
                                }
                            }
                        } else {
                            NSMutableArray *array = nil;
                            //sql语句
                            NSString *sql = createInsertSQLWithColumns(data, nil, columns, NO,&array);
                            if (sql) {
                                [db executeUpdate:sql withArgumentsInArray:array];
                            }
                        }
                    }
                    
                    
                }
            }];
        }
    }
}



#pragma mark - 删除操作

- (BOOL)deleteRecordWithModel:(NBBaseDBTableModel * _Nonnull)model;
{
    if (!model) {
        NSAssert(model, @"model 不能为空");
        return NO;
    }
    if (![self openDB]) return NO;
    __block BOOL execute = NO;
    
    NSMutableArray *deleteValues = nil;
    //sql语句
    NSString *sql = createDeleteSQL(model,nil,&deleteValues);
    if (sql) {
        //删除操作
        [self.fmdbQueue inDatabase:^(FMDatabase *db) {
            if (deleteValues.count > 0) {
                execute = [db executeUpdate:sql withArgumentsInArray:deleteValues];
            } else {
                execute = [db executeUpdate:sql];
            }
        }];
    }
    
    
    return execute;
}

// 删除记录
- (BOOL)deleteRecordFromTable:(Class _Nonnull)tableClass where:(id _Nonnull)where;
{
    NSString *tableName = [tableClass getTableName];
    return [self deleteRecordFromTableName:tableName where:where];
}


//删除表
- (BOOL)deleteTable:(Class _Nonnull)tableClass;
{
    NSString *tableName = [tableClass getTableName];
    return [self deleteTableName:tableName];
}

//清除表-清数据
- (BOOL)eraseTable:(Class _Nonnull)tableClass;
{
    NSString *tableName = [tableClass getTableName];
    return [self eraseTableName:tableName];
}

#pragma mark - 删除操作 自定义tableName
- (BOOL)deleteRecordWithModel:(NBBaseDBTableModel * _Nonnull)model tableName:(NSString * _Nonnull)tableName;
{
    if (!model) {
        NSAssert(model, @"model 不能为空");
        return NO;
    }
    if (![self openDB]) return NO;
    __block BOOL execute = NO;
    
    NSMutableArray *deleteValues = nil;
    //sql语句
    NSString *sql = createDeleteSQLWithModelAndTableName(model, tableName,nil,&deleteValues);
    if (sql) {
        //删除操作
        [self.fmdbQueue inDatabase:^(FMDatabase *db) {
            if (deleteValues.count > 0) {
                execute = [db executeUpdate:sql withArgumentsInArray:deleteValues];
            } else {
                execute = [db executeUpdate:sql];
            }
        }];
    }
    
    
    return execute;
}

// 删除记录
- (BOOL)deleteRecordFromTableName:(NSString * _Nonnull)tableName where:(id _Nonnull)where;
{
    if (tableName.length == 0) {
        NSAssert(tableName.length>0, @"tableName 不能为空");
        return NO;
    }
    if (![self openDB]) return NO;
    NSMutableArray *deleteValues = nil;
    //sql语句
    NSString *sql = createDeleteSQLWithTableName(tableName, where, &deleteValues);
    __block BOOL success = NO;
    if (sql) {
        [self.fmdbQueue inDatabase:^(FMDatabase *db) {
            success = [db executeUpdate:sql withArgumentsInArray:deleteValues];
        }];
    }
    return success;
}

//删除表
- (BOOL)deleteTableName:(NSString * _Nonnull)tableName;
{
    if (tableName.length == 0) {
        NSAssert(tableName.length>0, @"tableName 不能为空");
        return NO;
    }
    if (![self openDB]) return NO;
    __block BOOL success = NO;
    [self.fmdbQueue inDatabase:^(FMDatabase *db) {
        success = [db executeUpdate:[@"DROP TABLE " stringByAppendingString:tableName]];
    }];
    return success;
}

//清除表-清数据
- (BOOL)eraseTableName:(NSString * _Nonnull)tableName;
{
    if(tableName.length == 0) {
        NSAssert(tableName.length>0, @"tableName 不能为空");
        return NO;
    }
    if (![self openDB]) return NO;
    __block BOOL success = NO;
    [self.fmdbQueue inDatabase:^(FMDatabase *db) {
        success = [db executeUpdate:[@"DELETE FROM " stringByAppendingString: tableName]];
    }];
    return success;
}



#pragma mark - 更新操作

-(BOOL)updateWithModel:(NBBaseDBTableModel * _Nonnull)model where:(id _Nonnull)where
{
    return [self updateWithModel:model table:[model class] set:nil where:where];
}

-(BOOL)updateWithModel:(NBBaseDBTableModel * _Nonnull)model set:(id _Nonnull)sets where:(id  _Nullable)where
{
    return [self updateWithModel:model table:[model class] set:sets where:where];
}
-(BOOL)updateWithModel:(NBBaseDBTableModel * _Nonnull)model
                 table:(Class _Nonnull)tableClass
                   set:(id _Nullable)sets
                 where:(id _Nullable)where
{
    if(model == nil) {
        NSAssert(model, @"model 不能为空");
        return NO;
    }
    if (![self openDB]) return NO;
    NSString *tableName =  [tableClass getTableName];
    if (tableName.length == 0) {
        NSAssert(tableName.length>0, @"tableName 不能为空");
        return NO;
    }
    
    __block BOOL execute = NO;
    
    [self.fmdbQueue inDatabase:^(FMDatabase *db) {
        //生成更新语句
        NSMutableArray *updateValues = nil;
        NSString *updateSql = createUpdateSQLWithModelAndTableClass(model, tableClass,sets, where, &updateValues);
        //NSLog(@"%@",updateSql);
        if (updateSql) {
            if (updateValues.count > 0) {
                execute = [db executeUpdate:updateSql withArgumentsInArray:updateValues];
            } else {
                execute = [db executeUpdate:updateSql];
            }
        }
        
    }];
    
    return execute;
}

-(BOOL)updateTable:(Class _Nonnull)modelClass set:(id _Nonnull)sets where:(id _Nonnull)where
{
    NSString *tableName = [modelClass getTableName];
    return [self updateTableName:tableName set:sets where:where];
}

#pragma mark - 更新操作 自定义tableName
-(BOOL)updateTableName:(NSString * _Nonnull)tableName
                   set:(id _Nonnull)sets
                 where:(id _Nonnull)where
{
    if(tableName.length == 0) {
        NSAssert(tableName.length>0, @"tableName 不能为空");
        return NO;
    }
    if (![self openDB]) return NO;
    __block BOOL execute = NO;
    
    [self.fmdbQueue inDatabase:^(FMDatabase *db) {
        //生成更新语句
        NSMutableArray *updateValues = nil;
        NSString *updateSql = createUpdateSQLWithTableName(tableName, sets, where, &updateValues);
        //NSLog(@"%@",updateSql);
        if (updateSql) {
            if (updateValues.count > 0) {
                execute = [db executeUpdate:updateSql withArgumentsInArray:updateValues];
            } else {
                execute = [db executeUpdate:updateSql];
            }
        }
        
    }];
    
    return execute;
}

-(BOOL)updateWithModel:(NBBaseDBTableModel * _Nonnull)model
             tableName:(NSString * _Nonnull)tableName
                   set:(id _Nonnull)sets
                 where:(id _Nullable)where
{
    if(model == nil) {
        NSAssert(model, @"model 不能为空");
        return NO;
    }
    
    if (tableName.length == 0) {
        NSAssert(tableName.length>0, @"tableName 不能为空");
        return NO;
    }
    if (![self openDB]) return NO;
    
    __block BOOL execute = NO;
    
    [self.fmdbQueue inDatabase:^(FMDatabase *db) {
        //生成更新语句
        NSMutableArray *updateValues = nil;
        NSString *updateSql = createUpdateSQLWithModelAndTableName(model, tableName,sets, where, &updateValues);
        //NSLog(@"%@",updateSql);
        if (updateSql) {
            if (updateValues.count > 0) {
                execute = [db executeUpdate:updateSql withArgumentsInArray:updateValues];
            } else {
                execute = [db executeUpdate:updateSql];
            }
        }
        
    }];
    
    return execute;
}

#pragma mark  - - 更新一条以上记录
-(void)updateWithDataArray:(NSArray * _Nonnull)array
{
    [self updateWithDataArray:array set:nil];
}
-(void)updateWithDataArray:(NSArray * _Nonnull)array set:(id _Nullable)sets
{
    if (array.count < 1) {
        return;
    }
    [self updateWithDataArray:array table:[array.firstObject class] set:sets];
}
-(void)updateWithDataArray:(NSArray * _Nonnull)array table:(Class _Nonnull)tableClass set:(id _Nullable)sets
{
    if (array.count == 0) {
        return;
    }
    if (![self openDB]) return;
    if ([array.firstObject isKindOfClass:[NBBaseDBTableModel class]]){//自定义对象
        if (array.count == 1) {
            [self updateWithModel:array.firstObject table:tableClass set:sets where:nil];
        } else {//开启事务
            [self.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                for(NBBaseDBTableModel *data in array){
                    //生成更新语句
                    NSMutableArray *updateValues = nil;
                    NSString *updateSql = createUpdateSQLWithModelAndTableClass(data, tableClass,sets, nil, &updateValues);
                    if (updateSql) {
                        if (updateValues.count > 0) {
                            [db executeUpdate:updateSql withArgumentsInArray:updateValues];
                        } else {
                            [db executeUpdate:updateSql];
                        }
                    }
                }
            }];
        }
    } else {
        NSAssert(YES, @"不支持的类型%@",[array.firstObject class]);
    }
}

-(void)updateWithDataArray:(NSArray * _Nonnull)array tableName:(NSString * _Nonnull)tableName
{
    [self updateWithDataArray:array tableName:tableName set:nil];
}
-(void)updateWithDataArray:(NSArray * _Nonnull)array tableName:(NSString * _Nonnull)tableName set:(id _Nullable)sets
{
    if (array.count == 0) {
        return;
    }
    if (![self openDB]) return;
    if ([array.firstObject isKindOfClass:[NBBaseDBTableModel class]]){//自定义对象
        if (array.count == 1) {
            [self updateWithModel:array.firstObject tableName:tableName set:sets where:nil];
        } else {//开启事务
            [self.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                for(NBBaseDBTableModel *data in array){
                    //生成更新语句
                    NSMutableArray *updateValues = nil;
                    NSString *updateSql = createUpdateSQLWithModelAndTableName(data, tableName,sets, nil, &updateValues);
                    if (updateSql) {
                        if (updateValues.count > 0) {
                            [db executeUpdate:updateSql withArgumentsInArray:updateValues];
                        } else {
                            [db executeUpdate:updateSql];
                        }
                    }
                }
            }];
        }
    } else {
        NSAssert(YES, @"不支持的类型%@",[array.firstObject class]);
    }
}

#pragma mark- 查询操作
#pragma mark- - 查询多条数据
//获取所有数据
-(NSMutableArray * _Nullable)query:(Class)modelClass
{
    return [self query:modelClass table:nil where:nil orderBy:nil offset:0 count:0];
}
//获取所有数据，带条件
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass where:(id _Nonnull)where
{
    return [self query:modelClass table:nil where:where orderBy:nil offset:0 count:0];
}
//获取所有数据，带条件、排序
-(NSMutableArray *)query:(Class)modelClass
                   where:(id)where
                 orderBy:(NSString *)orderBy
{
    return [self query:modelClass table:nil where:where orderBy:orderBy offset:0 count:0];
}

-(NSMutableArray *)query:(Class)modelClass
                   where:(id)where
                 orderBy:(NSString *)orderBy
                  offset:(NSInteger)offset
                   count:(NSInteger)count
{
    return [self query:modelClass table:nil where:where orderBy:orderBy offset:offset count:count];
}

-(NSMutableArray *)query:(Class _Nonnull)modelClass
                 columns:(id _Nonnull)columns
                   where:(id _Nonnull)where
                 orderBy:(NSString * _Nonnull)orderBy
                  offset:(NSInteger)offset
                   count:(NSInteger)count
{
    return [self query:modelClass table:nil columns:columns where:where orderBy:orderBy offset:offset count:count];
}
#pragma mark- - 查询多条数据（出库的modelClass和数据库表对应的tableClass不一样的情况下使用以下接口）
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                             table:(Class _Nonnull)tableClass
{
    return [self query:modelClass table:tableClass columns:nil where:nil orderBy:nil offset:0 count:0];
}

-(NSMutableArray * _Nullable)query:(Class  _Nonnull)modelClass
                             table:(Class  _Nonnull)tableClass
                             where:(id  _Nonnull)where
{
    return [self query:modelClass table:tableClass columns:nil where:where orderBy:nil offset:0 count:0];
}
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                             table:(Class _Nonnull)tableClass
                             where:(id _Nonnull)where
                           orderBy:(NSString * _Nonnull)orderBy
{
    return [self query:modelClass table:tableClass columns:nil where:where orderBy:orderBy offset:0 count:0];
}
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                             table:(Class _Nullable)tableClass
                             where:(id _Nullable)where
                           orderBy:(NSString * _Nullable)orderBy
                            offset:(NSInteger)offset
                             count:(NSInteger)count
{
    return [self query:modelClass table:tableClass columns:nil where:where orderBy:orderBy offset:offset count:count];
}
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                             table:(Class _Nonnull)tableClass
                           columns:(id _Nonnull)columns
{
    return [self query:modelClass table:tableClass columns:columns where:nil orderBy:nil offset:0 count:0];
}
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                             table:(Class _Nonnull)tableClass
                           columns:(id _Nonnull)columns
                             where:(id _Nonnull)where
{
    return [self query:modelClass table:tableClass columns:columns where:where orderBy:nil offset:0 count:0];
}
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                             table:(Class _Nonnull)tableClass
                           columns:(id _Nonnull)columns
                             where:(id _Nonnull)where
                           orderBy:(NSString * _Nonnull)orderBy
{
    return [self query:modelClass table:tableClass columns:columns where:where orderBy:orderBy offset:0 count:0];
}
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                             table:(Class _Nullable)tableClass
                           columns:(id _Nullable)columns
                             where:(id _Nullable)where
                           orderBy:(NSString * _Nullable)orderBy
                            offset:(NSInteger)offset
                             count:(NSInteger)count
{
    NBDBQueryParams* params = [[NBDBQueryParams alloc]init];
    params.toClass = modelClass;
    if (tableClass) {
        params.tableClass = tableClass;
    } else {
        params.tableClass = params.toClass;
    }
    if([columns isKindOfClass:[NSArray class]])
    {
        params.columnArray = columns;
    }
    else if([columns isKindOfClass:[NSString class]])
    {
        params.columns = columns;
    }
    
    if([where isKindOfClass:[NSDictionary class]])
    {
        params.whereDic = where;
    }
    else if([where isKindOfClass:[NSString class]])
    {
        params.where = where;
    }
    
    params.orderBy = orderBy;
    params.offset = offset;
    params.count = count;
    
    return [self queryBaseWithParams:params];
}
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                             table:(Class _Nonnull)tableClass
                  followTableClass:(Class _Nonnull)followTableClass
                           columns:(id _Nonnull)columns
                     followColumns:(id _Nonnull)followColumns
                   leftJoinColumns:(id _Nonnull)leftJoinColumns
                             where:(id _Nonnull)where
                       followWhere:(id _Nonnull)followWhere
                           orderBy:(NSString * _Nonnull)orderBy
                            offset:(NSInteger)offset
                             count:(NSInteger)count
{
    NBDBQueryParams* params = [[NBDBQueryParams alloc]init];
    params.toClass = modelClass;
    if (tableClass) {
        params.tableClass = tableClass;
    } else {
        params.tableClass = params.toClass;
    }
    params.followTableClass = followTableClass;
    
    if([columns isKindOfClass:[NSArray class]])
    {
        params.columnArray = columns;
    }
    else if([columns isKindOfClass:[NSString class]])
    {
        params.columns = columns;
    }
    if([followColumns isKindOfClass:[NSArray class]])
    {
        params.followColumnsArray = followColumns;
    }
    else if([followColumns isKindOfClass:[NSString class]])
    {
        params.followColumns = followColumns;
    }
    
    if([leftJoinColumns isKindOfClass:[NSArray class]])
    {
        params.leftJoinColumnsArray = leftJoinColumns;
    }
    else if([leftJoinColumns isKindOfClass:[NSString class]])
    {
        params.leftJoinColumns = leftJoinColumns;
    }
    
    if([where isKindOfClass:[NSDictionary class]])
    {
        params.whereDic = where;
    }
    else if([where isKindOfClass:[NSString class]])
    {
        params.where = where;
    }
    if([followWhere isKindOfClass:[NSDictionary class]])
    {
        params.followWhereDic = followWhere;
    }
    else if([followWhere isKindOfClass:[NSString class]])
    {
        params.followWhere = followWhere;
    }
    
    params.orderBy = orderBy;
    params.offset = offset;
    params.count = count;
    
    return [self queryBaseWithParams:params];
}

#pragma mark- - 查询多条数据（出库的modelClass和数据库表对应的tableName不一样的情况下使用以下接口）
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                         tableName:(NSString * _Nonnull)tableName
{
    return [self query:modelClass tableName:tableName columns:nil where:nil orderBy:nil offset:0 count:0];
}

-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                         tableName:(NSString * _Nonnull)tableName
                             where:(id _Nonnull)where
{
    return [self query:modelClass tableName:tableName columns:nil where:where orderBy:nil offset:0 count:0];
}
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                         tableName:(NSString * _Nonnull)tableName
                             where:(id _Nonnull)where
                           orderBy:(NSString * _Nonnull)orderBy
{
    return [self query:modelClass tableName:tableName columns:nil where:where orderBy:orderBy offset:0 count:0];
}
-(NSMutableArray * _Nullable)query:(Class  _Nonnull)modelClass
                         tableName:(NSString *  _Nonnull)tableName
                             where:(id  _Nonnull)where
                           orderBy:(NSString *  _Nullable)orderBy
                            offset:(NSInteger)offset
                             count:(NSInteger)count
{
    return [self query:modelClass tableName:tableName columns:nil where:where orderBy:orderBy offset:offset count:count];
}
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                         tableName:(NSString * _Nonnull)tableName
                           columns:(id _Nonnull)columns
{
    return [self query:modelClass tableName:tableName  columns:columns where:nil orderBy:nil offset:0 count:0];
}
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                         tableName:(NSString * _Nonnull)tableName
                           columns:(id _Nonnull)columns
                             where:(id _Nonnull)where
{
    return [self query:modelClass tableName:tableName columns:columns where:where orderBy:nil offset:0 count:0];
}
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                         tableName:(NSString * _Nonnull)tableName
                           columns:(id _Nonnull)columns
                             where:(id _Nonnull)where
                           orderBy:(NSString * _Nonnull)orderBy
{
    return [self query:modelClass tableName:tableName columns:columns where:where orderBy:orderBy offset:0 count:0];
}
-(NSMutableArray * _Nullable)query:(Class _Nonnull)modelClass
                         tableName:(NSString * _Nonnull)tableName
                           columns:(id _Nullable)columns
                             where:(id _Nullable)where
                           orderBy:(NSString * _Nullable)orderBy
                            offset:(NSInteger)offset
                             count:(NSInteger)count
{
    NBDBQueryParams* params = [[NBDBQueryParams alloc]init];
    params.toClass = modelClass;
    if (tableName) {
        params.tableName = tableName;
    } else {
        params.tableClass = params.toClass;
    }
    
    if([columns isKindOfClass:[NSArray class]])
    {
        params.columnArray = columns;
    }
    else if([columns isKindOfClass:[NSString class]])
    {
        params.columns = columns;
    }
    
    if([where isKindOfClass:[NSDictionary class]])
    {
        params.whereDic = where;
    }
    else if([where isKindOfClass:[NSString class]])
    {
        params.where = where;
    }
    
    params.orderBy = orderBy;
    params.offset = offset;
    params.count = count;
    
    return [self queryBaseWithParams:params];
}
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
                   count:(NSInteger)count
{
    NBDBQueryParams* params = [[NBDBQueryParams alloc]init];
    params.toClass = modelClass;
    if (tableName) {
        params.tableName = tableName;
    } else {
        params.tableClass = params.toClass;
    }
    params.followTableName = followTableName;
    
    if([columns isKindOfClass:[NSArray class]])
    {
        params.columnArray = columns;
    }
    else if([columns isKindOfClass:[NSString class]])
    {
        params.columns = columns;
    }
    if([followColumns isKindOfClass:[NSArray class]])
    {
        params.followColumnsArray = followColumns;
    }
    else if([followColumns isKindOfClass:[NSString class]])
    {
        params.followColumns = followColumns;
    }
    
    if([leftJoinColumns isKindOfClass:[NSArray class]])
    {
        params.leftJoinColumnsArray = leftJoinColumns;
    }
    else if([leftJoinColumns isKindOfClass:[NSString class]])
    {
        params.leftJoinColumns = leftJoinColumns;
    }
    
    if([where isKindOfClass:[NSDictionary class]])
    {
        params.whereDic = where;
    }
    else if([where isKindOfClass:[NSString class]])
    {
        params.where = where;
    }
    if([followWhere isKindOfClass:[NSDictionary class]])
    {
        params.followWhereDic = followWhere;
    }
    else if([followWhere isKindOfClass:[NSString class]])
    {
        params.followWhere = followWhere;
    }
    
    params.orderBy = orderBy;
    params.offset = offset;
    params.count = count;
    
    return [self queryBaseWithParams:params];
}



#pragma mark- 查询一条数据
// 整型
- (NSInteger)queryIntegerdata:(Class _Nonnull)tableClass fieldName:(NSString * _Nonnull)fieldName
{
    return [self queryIntegerdata:tableClass fieldName:fieldName where:nil];
}
// 整型
- (NSInteger)queryIntegerdata:(Class _Nonnull)tableClass
                    fieldName:(NSString * _Nonnull)fieldName
                        where:(id _Nullable)where
{
    if (![self openDB]) return 0;
    NBDBQueryParams* params = [[NBDBQueryParams alloc]init];
    params.toClass = tableClass;
    if (tableClass) {
        params.tableClass = tableClass;
    } else {
        params.tableClass = params.toClass;
    }
    
    if([where isKindOfClass:[NSDictionary class]])
    {
        params.whereDic = where;
    }
    else if([where isKindOfClass:[NSString class]])
    {
        params.where = where;
    }
    params.columns = fieldName;
    params.usePrimaryKeyIfWhereIsNil = NO;//where为空时，不使用主键
    
    
    NSMutableArray* selectValues = nil;
    NSString *sql = createSelectSQLWithParams(params,&selectValues);
    __block NSInteger result = NO;
    if (sql) {
        [self.fmdbQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = nil;
            if (selectValues.count) {
                rs = [db executeQuery:sql withArgumentsInArray:selectValues];
            } else {
                rs = [db executeQuery:sql];
            }
            
            if ([rs next])
                result = [rs intForColumnIndex:0];
            [rs close];
        }];
        
    }
    return result;
}

// 布尔型
- (BOOL)queryBooldata:(Class _Nonnull)tableClass fieldName:(NSString * _Nonnull)fieldName
{
    return [self queryIntegerdata:tableClass fieldName:fieldName];
}

// 布尔型
- (BOOL)queryBooldata:(Class _Nonnull)tableClass fieldName:(NSString * _Nonnull)fieldName where:(id _Nonnull)where
{
    return [self queryIntegerdata:tableClass fieldName:fieldName where:where];
}

// 字符串型
- (NSString * _Nullable)queryStringdata:(Class _Nonnull)tableClass fieldName:(NSString * _Nonnull)fieldName
{
    if (![self openDB]) return nil;
    NSString *sql = createSelectSQL(tableClass,fieldName);
    __block NSString *result = @"";
    if (sql) {
        [self.fmdbQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:sql];
            if ([rs next])
                result = [rs stringForColumnIndex:0];
            [rs close];
        }];
    }
    
    return result;
}
// 字符串型
- (NSString * _Nullable)queryStringdata:(Class _Nonnull)tableClass fieldName:(NSString * _Nonnull)fieldName where:(id _Nonnull)where
{
    if (![self openDB]) return nil;
    NBDBQueryParams* params = [[NBDBQueryParams alloc]init];
    params.toClass = tableClass;
    if (tableClass) {
        params.tableClass = tableClass;
    } else {
        params.tableClass = params.toClass;
    }
    
    if([where isKindOfClass:[NSDictionary class]])
    {
        params.whereDic = where;
    }
    else if([where isKindOfClass:[NSString class]])
    {
        params.where = where;
    }
    params.columns = fieldName;
    params.usePrimaryKeyIfWhereIsNil = NO;//where为空时，不使用主键
    
    
    NSMutableArray* selectValues = nil;
    NSString *sql = createSelectSQLWithParams(params,&selectValues);
    __block NSString *result = nil;
    if (sql) {
        [self.fmdbQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = nil;
            if (selectValues.count) {
                rs = [db executeQuery:sql withArgumentsInArray:selectValues];
            } else {
                rs = [db executeQuery:sql];
            }
            
            if ([rs next])
                result = [rs stringForColumnIndex:0];
            [rs close];
        }];
        
    }
    return result;
}


// 二进制数据型
- (NSData * _Nullable)queryBlobdata:(Class _Nonnull)tableClass fieldName:(NSString * _Nonnull)fieldName
{
    if (![self openDB]) return nil;
    NSString *sql = createSelectSQL(tableClass,fieldName);
    __block NSData *result = nil;
    if (sql) {
        [self.fmdbQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:sql];
            if ([rs next])
                result = [rs dataForColumnIndex:0];
            [rs close];
        }];
    }
    return result;
}

// 自定义对象
- (NBBaseDBTableModel *)queryData:(Class _Nonnull)tableClass where:(id _Nonnull)where;
{
    NSArray *resultArray = [self query:tableClass where:where orderBy:nil offset:0 count:1];
    return resultArray.count>0?[resultArray firstObject]:nil;
}

// 自定义对象
- (NBBaseDBTableModel *)queryData:(Class _Nonnull)tableClass where:(id _Nonnull)where orderBy:(NSString * _Nonnull)orderBy
{
    NSArray *resultArray = [self query:tableClass where:where orderBy:orderBy offset:0 count:1];
    return resultArray.count>0?[resultArray firstObject]:nil;
}

#pragma mark- 查询一条数据 自定义tableName
// 整型
- (NSInteger)queryIntegerdataWithTableName:(NSString * _Nonnull)tableName fieldName:(NSString * _Nonnull)fieldName
{
    return [self queryIntegerdataWithTableName:tableName fieldName:fieldName where:nil];
}
// 整型
- (NSInteger)queryIntegerdataWithTableName:(NSString * _Nonnull)tableName
                                 fieldName:(NSString * _Nonnull)fieldName
                                     where:(id _Nullable)where
{
    if (![self openDB]) return 0;
    NBDBQueryParams* params = [[NBDBQueryParams alloc]init];
    if (tableName) {
        params.tableName = tableName;
    }
    
    if([where isKindOfClass:[NSDictionary class]])
    {
        params.whereDic = where;
    }
    else if([where isKindOfClass:[NSString class]])
    {
        params.where = where;
    }
    params.columns = fieldName;
    params.usePrimaryKeyIfWhereIsNil = NO;//where为空时，不使用主键
    
    
    NSMutableArray* selectValues = nil;
    NSString *sql = createSelectSQLWithParams(params,&selectValues);
    __block NSInteger result = NO;
    if (sql) {
        [self.fmdbQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = nil;
            if (selectValues.count) {
                rs = [db executeQuery:sql withArgumentsInArray:selectValues];
            } else {
                rs = [db executeQuery:sql];
            }
            
            if ([rs next])
                result = [rs intForColumnIndex:0];
            [rs close];
        }];
        
    }
    return result;
}

// 布尔型
- (BOOL)queryBooldataWithTableName:(NSString * _Nonnull)tableName fieldName:(NSString * _Nonnull)fieldName
{
    return [self queryIntegerdataWithTableName:tableName fieldName:fieldName];
}

// 布尔型
- (BOOL)queryBooldataWithTableName:(NSString * _Nonnull)tableName fieldName:(NSString * _Nonnull)fieldName where:(id)where
{
    return [self queryIntegerdataWithTableName:tableName fieldName:fieldName where:where];
}

// 字符串型
- (NSString * _Nullable)queryStringdataWithTableName:(NSString * _Nonnull)tableName fieldName:(NSString * _Nonnull)fieldName
{
    if (![self openDB]) return nil;
    NSString *sql = createSelectSQLWithTableName(tableName,fieldName);
    __block NSString *result = @"";
    if (sql) {
        [self.fmdbQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:sql];
            if ([rs next])
                result = [rs stringForColumnIndex:0];
            [rs close];
        }];
    }
    
    return result;
}
// 字符串型
- (NSString * _Nullable)queryStringdataWithTableName:(NSString * _Nonnull)tableName fieldName:(NSString * _Nonnull)fieldName where:(id _Nonnull)where
{
    if (![self openDB]) return nil;
    NBDBQueryParams* params = [[NBDBQueryParams alloc]init];
    if (tableName) {
        params.tableName = tableName;
    }
    
    if([where isKindOfClass:[NSDictionary class]])
    {
        params.whereDic = where;
    }
    else if([where isKindOfClass:[NSString class]])
    {
        params.where = where;
    }
    params.columns = fieldName;
    params.usePrimaryKeyIfWhereIsNil = NO;//where为空时，不使用主键
    
    
    NSMutableArray* selectValues = nil;
    NSString *sql = createSelectSQLWithParams(params,&selectValues);
    __block NSString *result = nil;
    if (sql) {
        [self.fmdbQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = nil;
            if (selectValues.count) {
                rs = [db executeQuery:sql withArgumentsInArray:selectValues];
            } else {
                rs = [db executeQuery:sql];
            }
            
            if ([rs next])
                result = [rs stringForColumnIndex:0];
            [rs close];
        }];
        
    }
    return result;
}


// 二进制数据型
- (NSData * _Nullable)queryBlobdataWithTableName:(NSString * _Nonnull)tableName fieldName:(NSString * _Nonnull)fieldName
{
    if (![self openDB]) return nil;
    NSString *sql = createSelectSQLWithTableName(tableName,fieldName);
    __block NSData *result = nil;
    if (sql) {
        [self.fmdbQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:sql];
            if ([rs next])
                result = [rs dataForColumnIndex:0];
            [rs close];
        }];
    }
    return result;
}

// 自定义对象
- (NBBaseDBTableModel * _Nullable)queryData:(Class _Nonnull)modelClass tableName:(NSString * _Nonnull)tableName where:(id _Nonnull)where;
{
    NSArray *resultArray = [self query:modelClass tableName:tableName where:where orderBy:nil offset:0 count:1];
    return resultArray.count>0?[resultArray firstObject]:nil;
}

// 自定义对象
- (NBBaseDBTableModel * _Nullable)queryData:(Class _Nonnull)modelClass tableName:(NSString * _Nonnull)tableName where:(id _Nonnull)where orderBy:(NSString * _Nonnull)orderBy
{
    NSArray *resultArray = [self query:modelClass tableName:tableName where:where orderBy:orderBy offset:0 count:1];
    return resultArray.count>0?[resultArray firstObject]:nil;
}


#pragma mark - 是否存在记录
- (BOOL)isExistsWithModel:(NBBaseDBTableModel * _Nonnull)model;
{
    if (![self openDB]) return NO;
    __block BOOL isExist = NO;
    NSMutableArray *primaryKeyValues = nil;
    NSString *sql = createSelectSQLWithPrimaryKey(model,nil,&primaryKeyValues);
    if (!sql) {
        return NO;
    }
    [self.fmdbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = nil;
        if (primaryKeyValues.count > 0) {
            rs = [db executeQuery:sql withArgumentsInArray:primaryKeyValues];
        } else {
            rs = [db executeQuery:sql];
        }
        NSDictionary *infoDict = nil;
        while ([rs next]) {
            infoDict = [rs resultDictionary];
            break;
        }
        [rs close];
        if (infoDict) {
            isExist = YES;
        }
    }];
    return isExist;
}


//是否有对应的表
- (BOOL)isExistTable:(Class _Nonnull)tableClass
{
    NSString *tableName = [tableClass getTableName];
    return [self isExistTableName:tableName];
}

#pragma mark - 是否存在记录 自定义tableName
//是否有对应的表
- (BOOL)isExistTableName:(NSString * _Nonnull)tableName
{
    NSAssert(tableName.length>0, @"表名不能为空");
    if (![self openDB]) return NO;
    __block BOOL isExist = NO;
    [self.fmdbQueue inDatabase:^(FMDatabase *db) {
        isExist = [db tableExists:tableName];
    }];
    return isExist;
}

- (BOOL)isExistsWithModel:(NBBaseDBTableModel * _Nonnull)model tableName:(NSString * _Nonnull)tableName;
{
    if (![self openDB]) return NO;
    __block BOOL isExist = NO;
    NSMutableArray *primaryKeyValues = nil;
    NSString *sql = createSelectSQLWithPrimaryKeyAndTableName(model,tableName,nil,&primaryKeyValues);
    if (!sql) {
        return NO;
    }
    [self.fmdbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = nil;
        if (primaryKeyValues.count > 0) {
            rs = [db executeQuery:sql withArgumentsInArray:primaryKeyValues];
        } else {
            rs = [db executeQuery:sql];
        }
        NSDictionary *infoDict = nil;
        while ([rs next]) {
            infoDict = [rs resultDictionary];
            break;
        }
        [rs close];
        if (infoDict) {
            isExist = YES;
        }
    }];
    return isExist;
}

#pragma mark - 私有方法，打开数据库

- (BOOL)openDB
{
    if (self.isOpened) {
        return YES;
    }
    if (self.isForceClosed) {
        return NO;
    }
    pthread_mutex_lock(&_lock);
    BOOL success = self.isOpened;
    if (success) {
        pthread_mutex_unlock(&_lock);
        return success;
    }
    if (self.isForceClosed) {
        pthread_mutex_unlock(&_lock);
        return NO;
    }
    if (_dbPath.length < 1) {
        pthread_mutex_unlock(&_lock);
        return NO;
    }
    //升级数据库
    [self upgradeDatabase:_dbPath];
    @try {
        if (!_fmdbQueue) {
            _fmdbQueue = [FMDatabaseQueue databaseQueueWithPath:_dbPath];
            if (!_fmdbQueue) {
                success = NO;
            } else {
                [_fmdbQueue inDatabase:^(FMDatabase *db) {
                    if ([self isNeedEncrypted]) {
                        [db setKey:[NBDBConfigure secretkey]];
                    }
                    [db setShouldCacheStatements:YES];
                }];
            }
            
        }
        if (_fmdbQueue) {
            success = YES;
        }
    }
    @catch (NSException *exception) {
        success = NO;
    }
    @finally {
        
    }
    if (success) {
        //建表
        [[self class] updateTableInDB];
        //保存最新的数据库版本号
        [self saveVersionToLocal];
    }
    _isOpened = success;
    pthread_mutex_unlock(&_lock);
    return success;
}

///库的当前版本号
- (NSString * _Nonnull)version
{
    return [NBDBConfigure version];
}

///库的缓存的版本号
- (NSString * _Nonnull)cacheVersion
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:[self cacheVersionKey]];
}

- (void)saveVersionToLocal
{
    if ([[self version] isEqualToString:[[NSUserDefaults standardUserDefaults] valueForKey:[self cacheVersionKey]]]) {
        return;
    }
    [[NSUserDefaults standardUserDefaults] setValue:[self version] forKey:[self cacheVersionKey]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString * _Nonnull)cacheVersionKey
{
    NSString *uid = @"";
    if ([self isKindOfClass:[NBPrivateDataBase class]]) {
        uid = [NBDBConfigure currentUserId];
    }
    return [NSString stringWithFormat:@"%@_%@",uid,[_dbPath lastPathComponent]];
}

- (BOOL)isNeedEncrypted
{
    BOOL needEncrypte = NO;
    if ([[NBDBConfigure version] compare:[NBDBConfigure smallestEncrypteVersion]] != NSOrderedAscending && [NBDBConfigure isEncrypted]) {
        needEncrypte = YES;
    }
    return needEncrypte;
}

- (BOOL)isEncrypted
{
    return [[[NSUserDefaults standardUserDefaults] valueForKey:[self cacheEncryptedStatusKey]] boolValue];
}

- (void)saveEncryptedStatus:(BOOL)encrypted
{
    if (encrypted == [[[NSUserDefaults standardUserDefaults] valueForKey:[self cacheEncryptedStatusKey]] boolValue]) {
        return;
    }
    [[NSUserDefaults standardUserDefaults] setValue:@(encrypted) forKey:[self cacheEncryptedStatusKey]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (NSString * _Nonnull)cacheEncryptedStatusKey
{
    NSString *uid = @"";
    if ([self isKindOfClass:[NBPrivateDataBase class]]) {
        uid = [NBDBConfigure currentUserId];
    }
    return [NSString stringWithFormat:@"%@_%@_EncryptedStatus",uid,[_dbPath lastPathComponent]];
}




#pragma mark - 私有方法，升级整个数据库为加密数据库
- (void)upgradeDatabase:(NSString * _Nonnull)path
{
    BOOL needEncrypte = [self isNeedEncrypted];
    BOOL isEncrypted = [self isEncrypted];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path])
    {
        //库文件不存在，不需要向下走
        if (needEncrypte) {
            [self saveEncryptedStatus:YES];
        } else {
            [self saveEncryptedStatus:NO];
        }
        return;
    }
    if (needEncrypte && isEncrypted) {//需要加密并且也加过密了
        //啥也不做
    } else if (needEncrypte && !isEncrypted) {//需要加密但尚未加密
        NSString *tmppath = [self changeDatabasePath:path];
        if(tmppath){
            const char* sqlQ = [[NSString stringWithFormat:@"ATTACH DATABASE '%@' AS encrypted KEY '%@';",path,[NBDBConfigure secretkey]] UTF8String];
            sqlite3 *unencrypted_DB;
            if (sqlite3_open([tmppath UTF8String], &unencrypted_DB) == SQLITE_OK) {
                
                // Attach empty encrypted database to unencrypted database
                sqlite3_exec(unencrypted_DB, sqlQ, NULL, NULL, NULL);
                // export database
                sqlite3_exec(unencrypted_DB, "SELECT sqlcipher_export('encrypted');", NULL, NULL, NULL);
                // Detach encrypted database
                sqlite3_exec(unencrypted_DB, "DETACH DATABASE encrypted;", NULL, NULL, NULL);
                sqlite3_close(unencrypted_DB);
                //delete tmp database
                [self removeDatabasePath:tmppath];
                [self saveEncryptedStatus:YES];
            }
            else {
                sqlite3_close(unencrypted_DB);
                NSAssert1(NO, @"Failed to open database with message ‘%s‘.", sqlite3_errmsg(unencrypted_DB));
            }
        }
    } else if (!needEncrypte) {
        //先看数据库是否是加密的
        if (!isEncrypted) {
            //没有加密，啥也不做
        } else {
            //解密
            NSString *tmppath = [self changeDatabasePath:path];
            if(tmppath){
                const char* sqlQ = [[NSString stringWithFormat:@"ATTACH DATABASE '%@' AS encrypted KEY '%@';",path,[NBDBConfigure secretkey]] UTF8String];
                sqlite3 *unencrypted_DB;
                if (sqlite3_open([tmppath UTF8String], &unencrypted_DB) == SQLITE_OK) {
                    
                    // Attach empty encrypted database to unencrypted database
                    sqlite3_exec(unencrypted_DB, sqlQ, NULL, NULL, NULL);
                    // export database
                    sqlite3_exec(unencrypted_DB, "SELECT sqlcipher_export('encrypted');", NULL, NULL, NULL);
                    // Detach encrypted database
                    sqlite3_exec(unencrypted_DB, "DETACH DATABASE encrypted;", NULL, NULL, NULL);
                    sqlite3_close(unencrypted_DB);
                    //delete tmp database
                    [self removeDatabasePath:tmppath];
                    [self saveEncryptedStatus:NO];
                }
                else {
                    sqlite3_close(unencrypted_DB);
                    NSAssert1(NO, @"Failed to open database with message ‘%s‘.", sqlite3_errmsg(unencrypted_DB));
                }
            }
        }
    }
}

- (NSString * _Nonnull)changeDatabasePath:(NSString * _Nonnull)path
{
    NSError * err = NULL;
    NSFileManager * fm = [NSFileManager defaultManager];
    NSString *tmppath = [NSString stringWithFormat:@"%@.tmp",path];
    BOOL result = [fm moveItemAtPath:path toPath:tmppath error:&err];
    if(!result){
        NSLog(@"Error: %@", err);
        return nil;
    }else{
        return tmppath;
    }
}

- (BOOL)removeDatabasePath:(NSString * _Nonnull)path
{
    NSError *err = NULL;
    NSFileManager * fm = [NSFileManager defaultManager];
    BOOL result = [fm removeItemAtPath:path error:&err];
    if(!result){
        NSLog(@"Error: %@", err);
        return NO;
    }else{
        return YES;
    }
}
#pragma mark - 私有方法，查询数据库
-(NSMutableArray * _Nonnull)queryBaseWithParams:(NBDBQueryParams * _Nonnull)params
{
    if (![self openDB]) return [NSMutableArray arrayWithCapacity:0];
    NSUInteger columnCount = 0;
    if(params.columnArray.count > 0)
    {
        columnCount = params.columnArray.count;
    }
    else if([NBDBHelper checkStringIsEmpty:params.columns] == NO)
    {
        NSArray* array = [params.columns componentsSeparatedByString:@","];
        columnCount = array.count;
    }
    if (params.followColumnsArray.count>0) {
        columnCount += params.followColumnsArray.count;
    }
    else if([NBDBHelper checkStringIsEmpty:params.followColumns] == NO)
    {
        NSArray* array = [params.followColumns componentsSeparatedByString:@","];
        columnCount += array.count;
    }
    
    NSMutableArray* whereValues = nil;
    NSString *query = nil;
    if (!params.followTableClass) {
        query = createSelectSQLWithParams(params,&whereValues);
    } else {//联合查询
        query = createUnionSelectSQLWithParams(params,&whereValues);
    }
    
    __block NSMutableArray* results = nil;
    [self.fmdbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet* set = nil;
        if(whereValues.count == 0)
        {
            set = [db executeQuery:query];
        }
        else
        {
            set = [db executeQuery:query withArgumentsInArray:whereValues];
        }
        
        if(columnCount == 1)
        {
            results = [self executeOneColumnResult:set class:params.toClass];
        }
        else
        {
            results = [self executeResult:set class:params.toClass];
        }
        
        [set close];
    }];
    if (!results) {
        results = [NSMutableArray arrayWithCapacity:0];
    }
    return results;
}

- (void)createTableIfNotExists:(FMDatabase * _Nonnull)db tableClass:(Class _Nonnull)tableClass tableName:(NSString * _Nonnull)tableName
{
    if (![db tableExists:tableName]) {
        //表不存在，就创建
        NSString *sql = createTableSQLWithTableName(tableClass,tableName);
        if (sql) {
            [db executeUpdate:sql];
        }
    }
}


#pragma mark - 私有方法，获取查询结果数据集
- (NSMutableArray * _Nonnull)executeOneColumnResult:(FMResultSet * _Nonnull)set class:(Class _Nonnull)modelClass
{
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:0];
    while ([set next]) {
        id obj = [set objectForColumnIndex:0];
        if(obj && ![obj isEqual:[NSNull null]])
        {
            [array addObject:obj];
        }
    }
    return array;
}
- (NSMutableArray * _Nonnull)executeResult:(FMResultSet * _Nonnull)set class:(Class _Nonnull)modelClass
{
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:0];
    NSInteger columnCount = [set columnCount];
    if ([NSStringFromClass(modelClass) isEqualToString:NSStringFromClass([NSDictionary class])]) {
        while ([set next]){
            
            NSMutableDictionary* bindingModel = [[NSMutableDictionary alloc]init];
            
            for (int i=0; i<columnCount; i++) {
                
                NSString* sqlName = [set columnNameForIndex:i];
                NSString* key = [sqlName hasPrefix:@"_"] ? [sqlName stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""] : sqlName;
                //赋值
                id value = [set objectForColumnIndex:i];
                
                if (![value isEqual:[NSNull null]] && value) {
                    [bindingModel setValue:value forKey:key];
                }
                
            }
            [array addObject:bindingModel];
        }
        return array;
    }
    else if ([modelClass isSubclassOfClass:[NBBaseDBTableModel class]]) {
        while ([set next]){
            NBBaseDBTableModel* bindingModel = [[modelClass alloc]init];
            for (int i=0; i<columnCount; i++) {
                
                NSString* sqlName = [set columnNameForIndex:i];
                NSString *method = [sqlName substringFromIndex:1];//去掉下划线 _
                if ([bindingModel respondsToSelector:NSSelectorFromString(method)]) {
                    Ivar ivar = class_getInstanceVariable(modelClass, [sqlName UTF8String]);
                    NSString* key =[NSString stringWithUTF8String:ivar_getName(ivar)];
                    const char *typeEncoding = ivar_getTypeEncoding(ivar);
                    //赋值
                    id value = [set objectForColumnIndex:i];
                    
                    if (![value isEqual:[NSNull null]] && value) {
                        [bindingModel setValue:value forKey:key typeEncoding:typeEncoding];
                    }
                }
            }
            [array addObject:bindingModel];
        }
    } else {//其它对象
        while ([set next]){
            NSObject* bindingModel = [[modelClass alloc]init];
            //赋值
            id value = [set objectForColumnIndex:0];
            if (![value isEqual:[NSNull null]] && value) {
                bindingModel = value;
            }
            [array addObject:bindingModel];
        }
    }
    
    return array;
}

@end
