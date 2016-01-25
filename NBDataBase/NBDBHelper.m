//
//  NBDBHelper.m
//  pengpeng
//
//  Created by feng on 14/12/16.
//  Copyright (c) 2014年 AsiaInnovations. All rights reserved.
//

#import "NBDBHelper.h"
#import "NBDBDefine.h"
#import <objc/message.h>
#import "NBDBNameHelper.h"
@implementation NBDBHelper

//判断名字是否是数据库的字段名
+ (BOOL)isColumn:(NSString *)name
{
    return [name rangeOfString:kNBNonColumn_Identify].location == NSNotFound;
}

//判断是否是主键
+ (BOOL)isPrimaryKey:(NSString *)name
{
    return [name rangeOfString:kNBPrimaryKey_Identify].location != NSNotFound;
}

//把属性的类型type转成数据库里支持的类型
+ (NSString *)columnTypeStringWithDataType:(const char *)type;
{
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
    NSString *columnType = nil;
    switch (type[0])
    {
        case 'i':// Numeric types
        case 's':
        case 'l':
        case 'q':
        case 'I':
        case 'S':
        case 'L':
        case 'Q':
        case 'f':
        case 'd':
        case 'B':
        {
            columnType = @"NUMERIC";
            break;
        }
        case 'c':
        case 'C':
        {
            columnType = @"CHAR";
            break;
        }
        case '*': // C-String
        {
            columnType = @"VARCHAR";
            break;
        }
        case '@': // Object
        {
            // The objcType for classes will always be at least 3 characters long
            if (strlen(type) >= 3)
            {
                // Copy the class name as a C-String
                char *cName = strndup(type + 2, strlen(type) - 3);
                // Convert to an NSString for easier manipulation
                NSString *name = @(cName);
                // Strip out and protocols from the end of the class name
                NSRange range = [name rangeOfString:@"<"];
                if (range.location != NSNotFound)
                {
                    name = [name substringToIndex:range.location];
                }
                // Get class from name, or default to NSObject if no name is found
                if ([name isEqualToString:@"NSString"]) {
                    columnType = @"VARCHAR";
                } else if ([name isEqualToString:@"NSData"]) {
                    columnType = @"BLOB";
                } else {
                    columnType = @"BLOB";
                }
                free(cName);
            }
            break;
        }
        case '{': // Struct
        case '[': // C-Array
        case '(': // Enum
        case '#': // Class
        case ':': // Selector
        case '^': // Pointer
        case 'b': // Bitfield
        case '?': // Unknown type
        default:
        {
            //若要做支持，封装NSValue对象
            columnType = nil; // Not supported
            NSLog(@"其它类型对象不支持写入数据库");
            break;
            
        }
    }
    
    return columnType;
}

//把数据库的类型转成OC支持的类名
+ (NSString *)classStringWithDataType:(const char *)type;
{
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
    NSString *classString = nil;
    switch (type[0])
    {
        case 'i':// Numeric types
        {
            classString = @"int";
            break;
        }
        case 's':
        {
            classString = @"short";
            break;
        }
        case 'l':
        {
            classString = @"long";
            break;
        }
        case 'q':
        {
            classString = @"long long";
            break;
        }
        case 'I':
        case 'S':
        case 'L':
        {
            classString = @"unsigned long";
            break;
        }
        case 'Q':
        {
            classString = @"unsigned long long";
            break;
        }
        case 'f':
        {
            classString = @"float";
            break;
        }
        case 'd':
        {
            classString = @"double";
            break;
        }
        case 'B':
        {
            classString = @"Bool";
        }
        case 'c':
        case 'C':
        {
            classString = @"char";
            break;
        }
        case '@': // Object
        {
            // The objcType for classes will always be at least 3 characters long
            if (strlen(type) >= 3)
            {
                // Copy the class name as a C-String
                char *cName = strndup(type + 2, strlen(type) - 3);
                // Convert to an NSString for easier manipulation
                NSString *name = @(cName);
                // Strip out and protocols from the end of the class name
                NSRange range = [name rangeOfString:@"<"];
                if (range.location != NSNotFound)
                {
                    name = [name substringToIndex:range.location];
                }
                // Get class from name, or default to NSObject if no name is found
                classString = name;
                free(cName);
            }
            break;
        }
        case '*': // C-String
        case '{': // Struct
        case '[': // C-Array
        case '(': // Enum
        case '#': // Class
        case ':': // Selector
        case '^': // Pointer
        case 'b': // Bitfield
        case '?': // Unknown type
        default:
        {
            //若要做支持，封装NSValue对象
            classString = nil; // Not supported
            break;
            
        }
    }
    
    return classString;
}

//检查字符串是否为空
+ (BOOL)checkStringIsEmpty:(NSString *)string
{
    if(string == nil)
    {
        return YES;
    }
    if([string isKindOfClass:[NSString class]] == NO)
    {
        return YES;
    }
    if(string.length == 0)
    {
        return YES;
    }
    return [[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""];
}

//获取类里的主键数组
+ (NSArray *)getPrimaryKeys:(Class)modelClass;
{
    Class c = [modelClass class];
    NSString *classString = NSStringFromClass(c);
    NSString *objectString = NSStringFromClass(NSObject.class);
    
    NSMutableArray *primaryKeys = [NSMutableArray array];
    
    while (![classString isEqualToString:objectString]){
        unsigned int outCount;
        objc_property_t *properties = class_copyPropertyList(c, &outCount);
        for (unsigned int i = 0; i<outCount; i++)
        {
            objc_property_t property = properties[i];
            // name
            const char *char_name = property_getName(property);
            NSString *propertyName = [NSString stringWithUTF8String:char_name];
            if ([NBDBHelper isPrimaryKey:propertyName]) {
                [primaryKeys addObject:FMColumnNameFromPropertyName(propertyName)];
            }
        }
        c = class_getSuperclass(c);
        classString = NSStringFromClass(c);
        free(properties);
    }
    
    return primaryKeys;
}


@end

@implementation NBDBQueryParams

@end

