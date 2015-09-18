//
//  NBDBHelper.h
//  pengpeng
//
//  Created by feng on 14/12/16.
//  Copyright (c) 2014年 AsiaInnovations. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NBDBHelper : NSObject
/// 判断名字是否是数据库的字段名
+ (BOOL)isColumn:(NSString *)name;
/// 判断是否是主键
+ (BOOL)isPrimaryKey:(NSString *)name;
/// 把属性的类型type转成数据库里支持的类型
+ (NSString *)columnTypeStringWithDataType:(const char *)type;
/// 把数据库的类型转成OC支持的类名
+ (NSString *)classStringWithDataType:(const char *)type;
/// 检查字符串是否为空
+ (BOOL)checkStringIsEmpty:(NSString *)string;
/// 获取类里的主键数组
+ (NSArray *)getPrimaryKeys:(Class)modelClass;


@end

@interface NBDBQueryParams : NSObject

///columns or array
@property(strong,nonatomic)NSString* columns;//列名
@property(strong,nonatomic)NSArray* columnArray;//列名数组

///followColumns or array
@property(strong,nonatomic)NSString* followColumns;//左连接第二个表的列名
@property(strong,nonatomic)NSArray* followColumnsArray;//左连接第二个表的列名数组


///where or dic
@property(strong,nonatomic)NSString* where;//条件语句，字符串形式
@property(strong,nonatomic)NSDictionary* whereDic;//条件语句，字典形式

//leftJoinColumns or array
@property(strong,nonatomic)NSString* leftJoinColumns;//左连接表的的列名，支持格式a和a,b,c
@property(strong,nonatomic)NSArray* leftJoinColumnsArray;//左连接表的列名数组,@[a,b]

///followWhere or dic
@property(strong,nonatomic)NSString* followWhere;//左连接第二个表的条件语句
@property(strong,nonatomic)NSDictionary* followWhereDic;//左连接第二个表条件语句的字典形式

@property(strong,nonatomic)NSString* groupBy;//分组
@property(strong,nonatomic)NSString* orderBy;//排序

@property(assign,nonatomic)NSInteger offset;//数据库分页用
@property(assign,nonatomic)NSInteger count;//读取的个数

@property(assign,nonatomic)Class toClass;//数据出库的类
@property(assign,nonatomic)Class tableClass;//主表对应的model类
@property(assign,nonatomic)Class followTableClass;//左连接第二个表对应的类
@property(assign,nonatomic)BOOL usePrimaryKeyIfWhereIsNil;//where条件为空时，是否使用主键



@property(copy,nonatomic)void(^callback)(NSMutableArray* results);

@end
