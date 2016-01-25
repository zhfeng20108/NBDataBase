//
//  NBSQLStatementHelper.m
//  pengpeng
//
//  Created by feng on 14/12/11.
//  Copyright (c) 2014年 AsiaInnovations. All rights reserved.
//

#import "NBSQLStatementHelper.h"

#import "NBBaseDBTableModel.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "NBDBHelper.h"
#define errorCodeWhereIsNil 111111111
NSString *sqlWhereAndValues(NSDictionary *dic,NSMutableArray *values);

NSMutableString *wherePrimaryKeySQLWithModel(NBBaseDBTableModel *model,NSMutableArray *__autoreleasing *values);

void sqlString(NSMutableString *sql,NSString *groupBy,NSString *orderby,NSInteger offset,NSInteger count);

NSString *dictionaryToSqlWhere(NSDictionary *dic,NSMutableArray *__autoreleasing *values);

NSMutableArray *extractWhereSql(NSMutableString *__autoreleasing *sql,id where,BOOL usePrimaryKeyWhenWhereIsNil,NBBaseDBTableModel *model,NSError *__autoreleasing *error);


NSString *createTableSQL(Class modelClass)
{
    return createTableSQLWithTableName(modelClass,nil);
}

NSString *createTableSQLWithTableName(Class tableClass,NSString *tableName)
{
    if (!tableName) {
        tableName = [tableClass performSelector:@selector(getTableName)];
    }
    if (tableName == nil) {
        return nil;
    }
    unsigned int outCount;
    Class c = tableClass;
    NSString *classString = NSStringFromClass(c);
    NSString *objectString = NSStringFromClass(NSObject.class);
    NSMutableString* table_pars = [NSMutableString string];
    
    while (![classString isEqualToString:objectString]){
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
            
            
            /*
             c char BOOL
             i int
             l long
             s short
             d double
             f float
             Q unsigned long long
             q long long
             L unsigned long
             l long
             B Boolean
             @ id //指针 对象
             ...  BOOL 获取到的表示 方式是 char
             .... ^i 表示  int*  一般都不会用到
             */
            char *typeEncoding = property_copyAttributeValue(property, "T");
            NSString *columnType = [NBDBHelper columnTypeStringWithDataType:typeEncoding];
            free(typeEncoding);
            if (!columnType) {//不支持的类型，继续
                continue;
            }
            if(table_pars.length > 0)
            {
                [table_pars appendString:@","];
            }
            [table_pars appendFormat:@"%@ %@",FMColumnNameFromPropertyName(propertyName),columnType];
        }
        
        c = class_getSuperclass(c);
        classString = NSStringFromClass(c);
        
        free(properties);
    }
    
    //取主键
    NSMutableString* pksb = [NSMutableString string];
    
    ///联合主键
    NSArray *primaryKeys = [NBDBHelper getPrimaryKeys:tableClass];
    
    if(primaryKeys.count>0)
    {
        pksb = [NSMutableString string];
        for (NSInteger i=0; i<primaryKeys.count; i++) {
            NSString* pk = [primaryKeys objectAtIndex:i];
            
            if(pksb.length>0){
                [pksb appendString:@","];
            }
            
            [pksb appendString:pk];
        }
        if(pksb.length>0)
        {
            [pksb insertString:@",PRIMARY KEY(" atIndex:0];
            [pksb appendString:@")"];
        }
    }
    if (table_pars.length<1) {
        return nil;
    }
    return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@%@)",tableName,table_pars,pksb];
}


NSString *createSelectSQL(Class modelClass,NSString *fieldName)
{
    NSString *tableName = [modelClass performSelector:@selector(getTableName)];
    return createSelectSQLWithTableName(tableName,fieldName);
}

NSString *createSelectSQLWithTableName(NSString *tableName,NSString *fieldName)
{
    if (!tableName) {
        return nil;
    }
    if (!fieldName) {
        fieldName = @"*";
    }
    return [NSString stringWithFormat:@"SELECT %@ FROM %@", fieldName,tableName];
}

NSString *createSelectSQLWithPrimaryKey(NBBaseDBTableModel *model,NSString *fieldName,NSMutableArray *__autoreleasing *primaryKeyValues)
{
    NSString *tableName = [[model class] performSelector:@selector(getTableName)];
    return createSelectSQLWithPrimaryKeyAndTableName(model,tableName, fieldName, primaryKeyValues);
}

NSString *createSelectSQLWithPrimaryKeyAndTableName(NBBaseDBTableModel *model,NSString *tableName,NSString *fieldName,NSMutableArray *__autoreleasing *primaryKeyValues)
{
    if (!tableName) {
        return nil;
    }
    if (!fieldName) {
        fieldName = @"*";
    }
    NSMutableString *selectSql =  [NSMutableString stringWithFormat:@"SELECT %@ FROM %@", fieldName,tableName];
    [selectSql appendString:wherePrimaryKeySQLWithModel(model, primaryKeyValues)];
    
    return selectSql;
}


NSString *createUpdateSQLWithModelAndTableClass(NBBaseDBTableModel *model,Class tableClass,id sets,id where,NSMutableArray *__autoreleasing *updateValues)
{
    NSString *tableName = [tableClass performSelector:@selector(getTableName)];
    return createUpdateSQLWithModelAndTableName(model,tableName, sets,where, updateValues);
}

NSString *createUpdateSQLWithModelAndTableName(NBBaseDBTableModel *model,NSString *tableName,id sets,id where,NSMutableArray *__autoreleasing *updateValues)
{
    if(!updateValues)
        return nil;
    NSMutableString* updateKey = [NSMutableString string];
    *updateValues = [[NSMutableArray alloc] init];
    
    
    if (sets) {//格式：1.@"" 2. @"",@"",@"" 3.@"a=7" 4.@"a=1,b=2" 5.@{a:1,b:2} 6.NSarray
        if([sets isKindOfClass:[NSArray class]] || ([sets isKindOfClass:[NSString class]] && [[sets componentsSeparatedByString:@","] count] > 1)){
            NSArray *arr = [sets isKindOfClass:[NSArray class]]?sets:[sets componentsSeparatedByString:@","];
            for (NSString *key in arr) {
                if(updateKey.length > 0)
                {
                    [updateKey appendString:@","];
                }
                [updateKey appendFormat:@"%@=?",key];
                [*updateValues addObject:[model valueForKey:key]];
            }
        } else if ([sets isKindOfClass:[NSString class]]) {
            if([(NSString *)sets rangeOfString:@"="].length>0) {
                [updateKey appendFormat:@"%@",sets];
            } else {
                [updateKey appendFormat:@"%@=?",sets];
                [*updateValues addObject:[model valueForKey:sets]];
            }
        } else if ([sets isKindOfClass:[NSDictionary class]]) {
            NSArray *arr = [sets allKeys];
            for (NSString *key in arr) {
                if(updateKey.length > 0)
                {
                    [updateKey appendString:@","];
                }
                [updateKey appendFormat:@"%@=?",key];
                [*updateValues addObject:[sets valueForKey:key]];
            }
        }
    }
    
    NSString *classString = NSStringFromClass([model class]);
    NSString *objectString = NSStringFromClass(NSObject.class);
    Class c = [model class];
    unsigned int outCount;
    while (!sets && ![classString isEqualToString:objectString]){
        objc_property_t *properties = class_copyPropertyList(c, &outCount);
        for (unsigned int i = 0; i<outCount; i++)
        {
            objc_property_t property = properties[i];
            const char *char_name = property_getName(property);
            NSString *propertyName = [NSString stringWithUTF8String:char_name];
            if ([NBDBHelper isColumn:propertyName]) {
                const char *name = [FMColumnNameFromPropertyName(propertyName) UTF8String];
                Ivar ivar = class_getInstanceVariable([model class], name);
                NSString* key =[NSString stringWithUTF8String:ivar_getName(ivar)];
                //排除主键
                if ([NBDBHelper isPrimaryKey:propertyName]) {
                    continue;
                }
                
                if([model valueForKey:key]!=nil){
                    if(updateKey.length > 0)
                    {
                        [updateKey appendString:@","];
                    }
                    [updateKey appendFormat:@"%@=?",key];
                    [*updateValues addObject:[model valueForKey:key]];
                }
            }
        }
        c = class_getSuperclass(c);
        classString = NSStringFromClass(c);
        free(properties);
    }
    NSMutableString* updateSQL = [NSMutableString stringWithFormat:@"update %@ set %@ ",tableName,updateKey];
    
    //添加where 语句
    NSError *error = nil;
    NSMutableArray *array = extractWhereSql(&updateSQL, where,YES,model,&error);
    if (error) {//有错
        return nil;
    }
    [*updateValues addObjectsFromArray:array];
    
    return [NSString stringWithString:updateSQL];
}

NSString *createUpdateSQLWithTableName(NSString *tableName, id sets,id where,NSMutableArray *__autoreleasing *updateValues)
{
    if(!updateValues)
        return nil;
    NSMutableString* updateKey = [NSMutableString string];
    *updateValues = [[NSMutableArray alloc] init];
    
    
    if (sets) {//格式：1.@"a=1" 2. @"a=1,b=2"  3.@{a:1,b:2}
        if(([sets isKindOfClass:[NSString class]] && [sets length] > 0) && [(NSString *)sets rangeOfString:@"="].length>0){
            [updateKey appendFormat:@"%@",sets];
        } else if ([sets isKindOfClass:[NSDictionary class]]) {
            NSArray *arr = [sets allKeys];
            for (NSString *key in arr) {
                if(updateKey.length > 0)
                {
                    [updateKey appendString:@","];
                }
                [updateKey appendFormat:@"%@=?",key];
                [*updateValues addObject:[sets valueForKey:key]];
            }
        } else {
            assert(NO);
        }
    } else {
        assert(NO);
    }
    NSMutableString* updateSQL = [NSMutableString stringWithFormat:@"update %@ set %@ ",tableName,updateKey];
    //添加where 语句
    NSError *error = nil;
    NSMutableArray *array = extractWhereSql(&updateSQL, where,NO,nil,&error);
    [*updateValues addObjectsFromArray:array];
    
    return [NSString stringWithString:updateSQL];
}
NSString *createUpdateSQL(NBBaseDBTableModel *model,id sets,id where,NSMutableArray *__autoreleasing *updateValues)
{
    return createUpdateSQLWithModelAndTableClass(model, [model class], sets, where, updateValues);
}

NSString *createInsertSQL(NBBaseDBTableModel *model,NSString *tableName,BOOL replace,NSMutableArray *__autoreleasing *insertValues)
{
    return createInsertSQLWithColumns(model, tableName, nil, replace, insertValues);
}

NSString *createInsertSQLWithColumns(NBBaseDBTableModel *model,NSString *tableName,id columns,BOOL replace,NSMutableArray *__autoreleasing *insertValues)
{
    NSString *tablename = nil;
    if (tableName) {
        tablename = tableName;
    } else {
        tablename = [[model class] performSelector:@selector(getTableName)];
        if (tablename == nil) {
            return nil;
        }
    }
    
    *insertValues = [[NSMutableArray alloc] init];
    
    NSString *sqlString = @"insert ";
    sqlString = [sqlString stringByAppendingString:replace?@"or replace into ":@"or ignore into "];
    sqlString = [sqlString stringByAppendingString:tablename];
    sqlString = [sqlString stringByAppendingString:@" ("];
    
    NSMutableString* insertKeyString = [NSMutableString stringWithCapacity:0];
    NSMutableString* insertValuesString = [NSMutableString stringWithCapacity:0];
    
    if (columns) {
        NSArray *columnsArray = nil;
        if ([columns isKindOfClass:[NSString class]]) {
            columnsArray = [(NSString *)columns componentsSeparatedByString:@","];
        } else if([columns isKindOfClass:[NSArray class]]){
            columnsArray = columns;
        } else {
            assert(NO);
        }
        for (int i=0; i<columnsArray.count; ++i) {
            id value = [model valueForKey:[columnsArray objectAtIndex:i]];
            if(value!=nil){
                if(insertKeyString.length>0)
                {
                    [insertKeyString appendString:@","];
                    [insertValuesString appendString:@","];
                }
                
                [insertKeyString appendString:[columnsArray objectAtIndex:i]];
                [insertValuesString appendString:@"?"];
                
                [*insertValues addObject:value];
                
            }
        }
    } else {
        NSString *classString = NSStringFromClass([model class]);
        NSString *objectString = NSStringFromClass(NSObject.class);
        Class c = [model class];
        unsigned int outCount;
        while (![classString isEqualToString:objectString]){
            objc_property_t *properties = class_copyPropertyList(c, &outCount);
            for (unsigned int i = 0; i<outCount; i++)
            {
                objc_property_t property = properties[i];
                char *typeEncoding = property_copyAttributeValue(property, "T");
                NSString *columnType = [NBDBHelper columnTypeStringWithDataType:typeEncoding];
                const char *char_name = property_getName(property);
                NSString *propertyName = [NSString stringWithUTF8String:char_name];
                if ([NBDBHelper isColumn:propertyName]) {
                    const char *name = [FMColumnNameFromPropertyName(propertyName) UTF8String];
                    Ivar ivar = class_getInstanceVariable([model class], name);
                    NSString* key =[NSString stringWithUTF8String:ivar_getName(ivar)];
                    id value = [model valueForKey:key];
                    if(value!=nil){
                        if(insertKeyString.length>0)
                        {
                            [insertKeyString appendString:@","];
                            [insertValuesString appendString:@","];
                        }
                        
                        [insertKeyString appendString:key];
                        [insertValuesString appendString:@"?"];
                        if ([columnType isEqualToString:@"BLOB"] && ![value isKindOfClass:[NSData class]]) {
                            value = [NSKeyedArchiver archivedDataWithRootObject:value];
                        }
                        [*insertValues addObject:value];
                        
                    }
                }
            }
            c = class_getSuperclass(c);
            classString = NSStringFromClass(c);
            free(properties);
        }
    }
    
    if ([insertValuesString isEqualToString:@""]) {
        return nil;
    }
    sqlString = [sqlString stringByAppendingFormat:@"%@) values (%@)",insertKeyString,insertValuesString];
    
    return sqlString;
}

NSString *createInsertSQLWithModelAndBeginClass(NBBaseDBTableModel *model,Class beginClass,BOOL replace,NSMutableArray * __autoreleasing * insertValues)
{
    NSString *tablename = [beginClass performSelector:@selector(getTableName)];
    if (tablename == nil) {
        return nil;
    }
    
    *insertValues = [[NSMutableArray alloc] init];
    
    NSString *sqlString = @"insert ";
    sqlString = [sqlString stringByAppendingString:replace?@"or replace into ":@"or ignore into "];
    sqlString = [sqlString stringByAppendingString:tablename];
    sqlString = [sqlString stringByAppendingString:@" ("];
    
    NSMutableString* insertKeyString = [NSMutableString stringWithCapacity:0];
    NSMutableString* insertValuesString = [NSMutableString stringWithCapacity:0];
    
    NSString *classString = NSStringFromClass([model class]);
    Class c = [model class];

    if (beginClass) {
        classString = NSStringFromClass(beginClass);
        c = beginClass;
    }
    NSString *objectString = NSStringFromClass(NSObject.class);
    unsigned int outCount;
    
    while (![classString isEqualToString:objectString]){
        objc_property_t *properties = class_copyPropertyList(c, &outCount);
        for (unsigned int i = 0; i<outCount; i++)
        {
            objc_property_t property = properties[i];
            const char *char_name = property_getName(property);
            NSString *propertyName = [NSString stringWithUTF8String:char_name];
            if ([NBDBHelper isColumn:propertyName]) {
                const char *name = [FMColumnNameFromPropertyName(propertyName) UTF8String];
                Ivar ivar = class_getInstanceVariable([model class], name);
                NSString* key =[NSString stringWithUTF8String:ivar_getName(ivar)];
                id value = [model valueForKey:key];
                if(value!=nil){
                    if(insertKeyString.length>0)
                    {
                        [insertKeyString appendString:@","];
                        [insertValuesString appendString:@","];
                    }
                    
                    [insertKeyString appendString:key];
                    [insertValuesString appendString:@"?"];
                    
                    [*insertValues addObject:value];
                    
                }
            }
        }
        c = class_getSuperclass(c);
        classString = NSStringFromClass(c);
        free(properties);
    }
    if ([insertValuesString isEqualToString:@""]) {
        return nil;
    }
    sqlString = [sqlString stringByAppendingFormat:@"%@) values (%@)",insertKeyString,insertValuesString];
    
    return sqlString;
}

NSString *createDeleteSQL(NBBaseDBTableModel *model,id where,NSMutableArray *__autoreleasing *deleteValues)
{
    NSString *tableName = [[model class] performSelector:@selector(getTableName)];
    NSMutableString* deleteSQL = [NSMutableString stringWithFormat:@"DELETE FROM %@",tableName];
    NSError *error = nil;
    NSMutableArray *array = extractWhereSql(&deleteSQL, where, YES, model,&error);
    if (error) {
        return nil;
    }
    *deleteValues = array;
    return [NSString stringWithString:deleteSQL];
    
}

NSString *createDeleteSQLWithModelAndTableName(NBBaseDBTableModel *model,NSString *tableName,id where,NSMutableArray *__autoreleasing *deleteValues)
{
    if (!tableName) {
        tableName = [[model class] performSelector:@selector(getTableName)];
    }
    NSMutableString* deleteSQL = [NSMutableString stringWithFormat:@"DELETE FROM %@",tableName];
    NSError *error = nil;
    NSMutableArray *array = extractWhereSql(&deleteSQL, where, YES, model,&error);
    if (error) {
        return nil;
    }
    *deleteValues = array;
    return [NSString stringWithString:deleteSQL];
    
}

NSString *createDeleteSQLWithTableName(NSString *tableName,id where,NSMutableArray *__autoreleasing *deleteValues)
{
    assert(where);//where不能为空
    
    NSMutableString* deleteSQL = [NSMutableString stringWithFormat:@"DELETE FROM %@",tableName];
    NSError *error = nil;
    NSMutableArray *array = extractWhereSql(&deleteSQL, where, NO, nil,&error);
    if (error) {
        return nil;
    }
    *deleteValues = array;
    return [NSString stringWithString:deleteSQL];
}

//dic where parse
NSString *dictionaryToSqlWhere(NSDictionary *dic,NSMutableArray *__autoreleasing *values)
{
    NSMutableString* wherekey = [NSMutableString stringWithCapacity:0];
    if(dic != nil && dic.count >0 )
    {
        if (!values) {
            *values = [[NSMutableArray alloc] init];
        } else {
            [*values removeAllObjects];
        }
        NSArray* keys = dic.allKeys;
        for (NSInteger i=0; i< keys.count;i++) {
            
            NSString* key = [keys objectAtIndex:i];
            id va = [dic objectForKey:key];
            if([va isKindOfClass:[NSArray class]])
            {
                NSArray* vlist = va;
                if(vlist.count==0)
                    continue;
                
                if(wherekey.length > 0)
                    [wherekey appendString:@" and"];
                
                [wherekey appendFormat:@" %@ in(",key];
                
                for (NSInteger j=0; j<vlist.count; j++) {
                    
                    [wherekey appendString:@"?"];
                    if(j== vlist.count-1)
                        [wherekey appendString:@")"];
                    else
                        [wherekey appendString:@","];
                    
                    [*values addObject:[vlist objectAtIndex:j]];
                }
            }
            else
            {
                if(wherekey.length > 0)
                    [wherekey appendFormat:@" and %@=?",key];
                else
                    [wherekey appendFormat:@" %@=?",key];
                
                [*values addObject:va];
            }
            
        }
    }
    return wherekey;
}

void sqlString(NSMutableString *sql,NSString *groupBy,NSString *orderby,NSInteger offset,NSInteger count)
{
    if([NBDBHelper checkStringIsEmpty:groupBy] == NO)
    {
        [sql appendFormat:@" group by %@",groupBy];
    }
    if([NBDBHelper checkStringIsEmpty:orderby] == NO)
    {
        [sql appendFormat:@" order by %@",orderby];
    }
    if(count >0)
    {
        [sql appendFormat:@" limit %ld offset %ld",(long)count,(long)offset];
    }
    else if(offset > 0)
    {
        [sql appendFormat:@" limit %d offset %ld",INT_MAX,(long)offset];
    }
}

NSString *sqlWhereAndValues(NSDictionary *dic,NSMutableArray *values)
{
    NSMutableString* wherekey = [NSMutableString stringWithCapacity:0];
    if(dic != nil && dic.count >0 )
    {
        NSArray* keys = dic.allKeys;
        for (NSInteger i=0; i< keys.count;i++) {
            
            NSString* key = [keys objectAtIndex:i];
            id va = [dic objectForKey:key];
            if([va isKindOfClass:[NSArray class]])
            {
                NSArray* vlist = va;
                if(vlist.count==0)
                    continue;
                
                if(wherekey.length > 0)
                    [wherekey appendString:@" and"];
                
                [wherekey appendFormat:@" %@ in(",key];
                
                for (NSInteger j=0; j<vlist.count; j++) {
                    
                    [wherekey appendString:@"?"];
                    if(j== vlist.count-1)
                        [wherekey appendString:@")"];
                    else
                        [wherekey appendString:@","];
                    
                    [values addObject:[vlist objectAtIndex:j]];
                }
            }
            else
            {
                if(wherekey.length > 0)
                    [wherekey appendFormat:@" and %@=?",key];
                else
                    [wherekey appendFormat:@" %@=?",key];
                
                [values addObject:va];
            }
            
        }
    }
    return wherekey;
}

//where sql statements about model primary keys
NSMutableString *wherePrimaryKeySQLWithModel(NBBaseDBTableModel *model,NSMutableArray *__autoreleasing *values)
{
    Class c = [model class];
    NSString *classString = NSStringFromClass(c);
    NSString *objectString = NSStringFromClass(NSObject.class);
    *values = [[NSMutableArray alloc] init];
    NSMutableString* pwhere = [NSMutableString string];
    unsigned int outCount;
    while (![classString isEqualToString:objectString]){
        objc_property_t *properties = class_copyPropertyList(c, &outCount);
        for (unsigned int i = 0; i<outCount; i++)
        {
            objc_property_t property = properties[i];
            const char *char_name = property_getName(property);
            NSString *propertyName = [NSString stringWithUTF8String:char_name];
            if ([NBDBHelper isPrimaryKey:propertyName]) {
                const char *name = [FMColumnNameFromPropertyName(propertyName) UTF8String];
                Ivar ivar = class_getInstanceVariable([c class], name);
                NSString* key =[NSString stringWithUTF8String:ivar_getName(ivar)];
                if([model valueForKey:key]!=nil){
                    
                    if(pwhere.length>0)
                    {
                        [pwhere appendString:@"and"];
                    } else {
                        [pwhere appendString:@" where "];
                    }
                    [pwhere appendFormat:@" %@=? ",key];
                    [*values addObject:[model valueForKey:key]];
                }
            }
        }
        c = class_getSuperclass(c);
        classString = NSStringFromClass(c);
        free(properties);
    }
    assert(pwhere.length);
    return pwhere;
}

NSString *createSelectSQLWithParams(NBDBQueryParams *params,NSMutableArray *__autoreleasing *selectValues)
{
    if(params.toClass == nil)
    {
        NSLog(@" toClass is nil");
        return nil;
    }
    
    NSString* db_tableName = params.tableName;
    if (!db_tableName) {
        db_tableName = [params.tableClass getTableName];
    }
    if (!db_tableName) {
        db_tableName = [params.toClass getTableName];
    }
    if([NBDBHelper checkStringIsEmpty:db_tableName])
    {
        NSLog(@" tableName is empty");
        return nil;
    }
    *selectValues = [[NSMutableArray alloc] init];
    NSString* columnsString = nil;
    if(params.columnArray.count > 0)
    {
        columnsString = [params.columnArray componentsJoinedByString:@","];
    }
    else if([NBDBHelper checkStringIsEmpty:params.columns] == NO)
    {
        columnsString = params.columns;
    }
    else
    {
        columnsString = @"*";
    }
    
    NSMutableString* query = [NSMutableString stringWithFormat:@"select %@ from @t",columnsString];
    NSError *error = nil;
    NSMutableArray *array  = extractWhereSql(&query, params.whereDic.count>0?params.whereDic:params.where, params.usePrimaryKeyIfWhereIsNil, nil,&error);
    [*selectValues addObjectsFromArray:array];
    
    sqlString(query,params.groupBy,params.orderBy,params.offset,params.count);
    
    //replace @t to model table name
    NSString* replaceTableName = [NSString stringWithFormat:@" %@ ",db_tableName];
    if([query hasSuffix:@" @t"])
    {
        [query appendString:@" "];
    }
    [query replaceOccurrencesOfString:@" @t " withString:replaceTableName options:NSCaseInsensitiveSearch range:NSMakeRange(0, query.length)];
    
    return [NSString stringWithString:query];
}
NSString *createUnionSelectSQLWithParams(NBDBQueryParams *params,NSMutableArray *__autoreleasing *selectValues)
{
    if(params.toClass == nil)
    {
        NSLog(@" toClass is nil");
        return nil;
    }
    
    NSString* mainTableName = params.tableName;
    if (!mainTableName) {
        mainTableName = [params.tableClass getTableName];
    }
    if (!mainTableName) {
        mainTableName = [params.toClass getTableName];
    }
    if([NBDBHelper checkStringIsEmpty:mainTableName])
    {
        NSLog(@" tableName is empty");
        return nil;
    }
    
    NSString *followTableName = params.followTableName;
    if (!followTableName) {
        followTableName = [params.followTableClass getTableName];
    }
    
    *selectValues = [[NSMutableArray alloc] init];
    NSMutableString* columnsString = [NSMutableString string];
    NSUInteger columnCount = 0;
    if(params.columnArray.count > 0 || [NBDBHelper checkStringIsEmpty:params.columns] == NO)
    {
        NSArray *array = params.columnArray.count>0?params.columnArray:[params.columns componentsSeparatedByString:@","];
        columnCount = array.count;
        for (int i=0;i<array.count;++i) {
            NSString *column = [array objectAtIndex:i];
            if (i==0) {
                [columnsString appendFormat:@"%@.%@",mainTableName,column];
            } else {
                [columnsString appendFormat:@"%@.%@",mainTableName,column];
            }
            if (i!=array.count-1) {
                [columnsString appendString:@","];
            }
        }
    } else
    {
        
    }
    if(params.followColumnsArray.count > 0 || [NBDBHelper checkStringIsEmpty:params.followColumns] == NO)
    {
         NSArray *array = params.followColumnsArray.count>0?params.followColumnsArray:[params.followColumns componentsSeparatedByString:@","];
        
        for (int i=0;i<array.count;++i) {
            NSString *column = [array objectAtIndex:i];
            if (i==0) {
                if (columnsString.length>1) {
                    [columnsString appendString:@","];
                }
                [columnsString appendFormat:@"%@.%@",followTableName,column];

            } else {
                [columnsString appendFormat:@" %@.%@",followTableName,column];
            }
            if (i!=array.count-1) {
                [columnsString appendString:@","];
            }
        }
    } else
    {
        
    }
    if (columnsString.length<1) {
        [columnsString appendString:@"*"];
    }
    
    
    NSMutableString* query = [NSMutableString stringWithFormat:@"select %@ from @t left join %@",columnsString,followTableName];
    
    NSMutableString *onString = [NSMutableString string];
    NSMutableArray* values = nil;
    if (params.leftJoinColumnsArray.count > 0 || [NBDBHelper checkStringIsEmpty:params.leftJoinColumns]==NO) {
        NSArray *array = params.leftJoinColumnsArray.count > 0?params.leftJoinColumnsArray:[params.leftJoinColumns componentsSeparatedByString:@","];
        for (int i=0;i<[array count];++i) {
            NSString *column = [array objectAtIndex:i];
            if (i==0) {
                [onString appendString:@" on"];
            } else {
                [onString appendString:@" and"];
            }
            [onString appendFormat:@" %@.%@=%@.%@ ",mainTableName,column,followTableName,column];
        }
    } else {
    }
    
    if (params.followWhereDic)
    {
        NSDictionary* dicWhere = params.followWhereDic;
        if(dicWhere.count > 0)
        {
            values = [NSMutableArray arrayWithCapacity:dicWhere.count];
            NSString* wherekey = dictionaryToSqlWhere(dicWhere, &values);
            [*selectValues addObjectsFromArray:values];
            [onString appendFormat:@" and %@.%@",followTableName,wherekey];
        }
    } else if([NBDBHelper checkStringIsEmpty:params.followWhere]==NO)
    {
        [onString appendFormat:@" and %@",params.followWhere];
    }
    else //followWhere为空
    {
    }
    [query appendString:onString];
    
    
    if (params.whereDic)
    {
        NSDictionary* dicWhere = params.whereDic;
        if(dicWhere.count > 0)
        {
            values = [NSMutableArray arrayWithCapacity:dicWhere.count];
            NSString* wherekey = dictionaryToSqlWhere(dicWhere, &values);
            [*selectValues addObjectsFromArray:values];
            [query appendFormat:@" where %@.%@",mainTableName,wherekey];
        }
    } else if([NBDBHelper checkStringIsEmpty:params.where]==NO)
    {
        [query appendFormat:@" where %@",params.where];
    }
    else //where为空
    {
    }
    
    sqlString(query,params.groupBy,params.orderBy,params.offset,params.count);
    
    //replace @t to model table name
    NSString* replaceTableName = [NSString stringWithFormat:@" %@ ",mainTableName];
    if([query hasSuffix:@" @t"])
    {
        [query appendString:@" "];
    }
    [query replaceOccurrencesOfString:@" @t " withString:replaceTableName options:NSCaseInsensitiveSearch range:NSMakeRange(0, query.length)];
    
    return [NSString stringWithString:query];
}

//splice 'where' 拼接where语句
NSMutableArray *extractWhereSql(NSMutableString *__autoreleasing *sql,id where,BOOL usePrimaryKeyWhenWhereIsNil,NBBaseDBTableModel *model,NSError *__autoreleasing *error)
{
    NSMutableArray* values = nil;
    if([where isKindOfClass:[NSString class]] && [NBDBHelper checkStringIsEmpty:where]==NO)
    {
        [*sql appendFormat:@" where %@",where];
    }
    else if ([where isKindOfClass:[NSDictionary class]])
    {
        NSDictionary* dicWhere = where;
        if(dicWhere.count > 0)
        {
            values = [NSMutableArray arrayWithCapacity:dicWhere.count];
            NSString* wherekey = dictionaryToSqlWhere(where, &values);
            [*sql appendFormat:@" where %@",wherekey];
        } else {
            *error = [[NSError alloc] initWithDomain:@"where 条件是空" code:errorCodeWhereIsNil userInfo:nil];
            assert(NO);
        }
    }
    else //where为空 用主键
    {
        if (usePrimaryKeyWhenWhereIsNil) {
            if (!model) {
                *error = [[NSError alloc] initWithDomain:@"where 条件是空" code:errorCodeWhereIsNil userInfo:nil];
                assert(NO);
                return nil;
            }
            NSMutableArray *array = nil;
            NSString* pwhere = wherePrimaryKeySQLWithModel(model,&array);

            if (!values) {
                values = [NSMutableArray array];
            }
            [values addObjectsFromArray:array];
            if(pwhere.length ==0)
            {
                *error = [[NSError alloc] initWithDomain:@"where 条件是空" code:errorCodeWhereIsNil userInfo:nil];
                assert(NO);
                NSLog(@"database update fail : %@ no find primary key!",NSStringFromClass([model class]));
                return nil;
            }
            [*sql appendString:pwhere];
        } else {
            //啥也不做，也就是不加 where
        }
        
        
    }
    return values;
}


