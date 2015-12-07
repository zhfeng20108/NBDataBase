//
//  NBBaseDBTableModel.m
//  pengpeng
//
//  Created by feng on 14/12/12.
//  Copyright (c) 2014年 AsiaInnovations. All rights reserved.
//

#import "NBBaseDBTableModel.h"
#import "NBDataBase.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <UIKit/UIKit.h>

#import "NBDBNameHelper.h"
#import "NBDBHelper.h"
@interface NBBaseDBTableModel ()
@end


@implementation NBBaseDBTableModel

//入库，如果数据库已存在，是插入不进去的
- (BOOL)saveToDB;
{
    //数据插入,如果存在，保留原来数据
    return [[[self class] getDataBase] insertToDBWithModel:self replace:NO];
}

//以更新的方式入库，会更新掉所有的字段，如果数据库里不存在这条记录，就会插入
- (BOOL)saveToDBUseUpdate;
{
    //数据插入
    return [[[self class] getDataBase] insertToDBWithModel:self update:YES];
}

//插入或更新指定的字段
- (BOOL)saveToDBUseUpdateWithColumns:(id)columns;
{
    //数据插入
    return [[[self class] getDataBase] insertToDBWithModel:self update:YES columns:columns];
}

//更新指定的字段
- (BOOL)updateDBWithColumns:(id)columns;
{
    //数据插入
    return [[[self class] getDataBase] updateWithModel:self set:columns where:nil];
}

//以替换的方式入库，如果数据库已存在记录则替换掉原来的记录，否则就直接插入
- (BOOL)saveToDBUseReplace;
{
    //数据插入
    return [[[self class] getDataBase] insertToDBWithModel:self replace:YES];
}

//自动取主键，删记录
- (BOOL)deleteToDB;
{
    //数据删除
    return [[[self class] getDataBase] deleteRecordWithModel:self];
}

//检查表中是否存在这条记录
-(BOOL)isExistsFromDB
{
    return [[[self class] getDataBase] isExistsWithModel:self];
}

/// 入库，如果数据库已存在，是插入不进去的
- (BOOL)saveToDBTable:(NSString *)tableName
{
    //数据插入,如果存在，保留原来数据
    return [[[self class] getDataBase] insertToDBWithModel:self tableName:tableName replace:NO];
}

/// 以更新的方式入库，会更新掉所有的字段，如果数据库里不存在这条记录，就会插入
- (void)saveToDBUseUpdateInTable:(NSString *)tableName
{
    //数据插入
    return [[[self class] getDataBase] insertToDBWithModel:self tableName:tableName update:YES];
}

/// 以替换的方式入库，如果数据库已存在记录则替换掉原来的记录，否则就直接插入
- (BOOL)saveToDBUseReplaceInTable:(NSString *)tableName
{
    //数据插入
    return [[[self class] getDataBase] insertToDBWithModel:self tableName:tableName replace:YES];
}

/// 插入或更新指定的字段
- (BOOL)saveToDBTable:(NSString *)tableName updateColumns:(id)columns
{
    return [[[self class] getDataBase] insertToDBWithModel:self tableName:tableName update:YES columns:columns];
}

/// 更新指定的字段
- (BOOL)updateDBTable:(NSString *)tableName columns:(id)columns
{
    return [[[self class] getDataBase] updateWithModel:self tableName:tableName set:columns where:nil];
}

/// 自动取主键，删记录
- (BOOL)deleteFromDBTable:(NSString *)tableName
{
    return [[[self class] getDataBase] deleteRecordWithModel:self tableName:tableName];
}

/// 检查表中是否存在这条记录
-(BOOL)isExistsFromDBTable:(NSString *)tableName
{
    return [[[self class] getDataBase] isExistsWithModel:self tableName:tableName];
}

#pragma mark - NBDBTableModelProtocol
+(NBDataBase *)getDataBase;
{
    return [NBDataBase sharedInstance];
}

//表名
+ (NSString *)getTableName
{
    return FMDefaultTableNameFromModelName(NSStringFromClass(self));
}

//set
-(void)setValue:(id)value forKey:(NSString *)key typeEncoding:(const char *)typeEncoding;
{
    NSString *propertyType = [NBDBHelper classStringWithDataType:typeEncoding];
    ///获取属性的Class
    Class columnClass = NSClassFromString(propertyType);
    
    id modelValue = nil;
    
    if(columnClass == nil)
    {
        ///当找不到 class 时，就是 基础类型 int,float CGRect 之类的
        
        NSString* columnType = propertyType;
        if([@"float_double_decimal" rangeOfString:columnType].location != NSNotFound)
        {
            double number = [value doubleValue];
            modelValue = [NSNumber numberWithDouble:number];
        }
        else if([@"int_char_short_long_long long_unsigned long_unsigned long long" rangeOfString:columnType].location != NSNotFound)
        {
            if ([columnType isEqualToString:@"long"]) {
                long number = [value longValue];
                modelValue = [NSNumber numberWithLong:number];
            }
            else if([columnType isEqualToString:@"long long"])
            {
                long long number = [value longLongValue];
                modelValue = [NSNumber numberWithLongLong:number];
            }
            else if([columnType isEqualToString:@"unsigned long"])
            {
                unsigned long number = [value unsignedLongValue];
                modelValue = [NSNumber numberWithUnsignedLong:number];
            }
            else if([columnType isEqualToString:@"unsigned long long"])
            {
                unsigned long long number = [value unsignedLongLongValue];
                modelValue = [NSNumber numberWithUnsignedLongLong:number];
            }
            else
            {
                NSInteger number = [value integerValue];
                modelValue = [NSNumber numberWithInteger:number];
            }
        }
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
        else if([columnType isEqualToString:@"CGRect"])
        {
            CGRect rect = CGRectFromString(value);
            modelValue = [NSValue valueWithCGRect:rect];
        }
        else if([columnType isEqualToString:@"CGPoint"])
        {
            CGPoint point = CGPointFromString(value);
            modelValue = [NSValue valueWithCGPoint:point];
        }
        else if([columnType isEqualToString:@"CGSize"])
        {
            CGSize size = CGSizeFromString(value);
            modelValue = [NSValue valueWithCGSize:size];
        }
        else if([columnType isEqualToString:@"_NSRange"])
        {
            NSRange range = NSRangeFromString(value);
            modelValue = [NSValue valueWithRange:range];
        }
#else
        else if([columnType hasSuffix:@"Rect"])
        {
            NSRect rect = NSRectFromString(value);
            modelValue = [NSValue valueWithRect:rect];
        }
        else if([columnType hasSuffix:@"Point"])
        {
            NSPoint point = NSPointFromString(value);
            modelValue = [NSValue valueWithPoint:point];
        }
        else if([columnType hasSuffix:@"Size"])
        {
            NSSize size = NSSizeFromString(value);
            modelValue = [NSValue valueWithSize:size];
        }
        else if([columnType hasSuffix:@"Range"])
        {
            NSRange range = NSRangeFromString(value);
            modelValue = [NSValue valueWithRange:range];
        }
#endif
        ///如果都没有值 默认给个0
        if(modelValue == nil)
        {
            modelValue = [NSNumber numberWithInt:0];
        }
    }
    else if([value length] == 0)
    {
        //为了不继续遍历
    }
    else if([columnClass isSubclassOfClass:[NSString class]])
    {
        modelValue = value;
    }
    else if([columnClass isSubclassOfClass:[NSNumber class]])
    {
        modelValue = [NSNumber numberWithDouble:[value doubleValue]];
    }
    else if([columnClass isSubclassOfClass:[NSDate class]])
    {
        //暂不支持NSDate
        modelValue = nil;
//        NSString* datestr = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//        NSDateFormatter* formatter = [self.class getModelDateFormatter];
//        if(formatter){
//            modelValue = [formatter dateFromString:datestr];
//        }
//        else{
//            modelValue = [LKDBUtils dateWithString:datestr];
//        }
    }
    else if([columnClass isSubclassOfClass:[UIColor class]])
    {
        NSString* color = value;
        NSArray* array = [color componentsSeparatedByString:@","];
        float r,g,b,a;
        r = [[array objectAtIndex:0] floatValue];
        g = [[array objectAtIndex:1] floatValue];
        b = [[array objectAtIndex:2] floatValue];
        a = [[array objectAtIndex:3] floatValue];
        
        modelValue = [UIColor colorWithRed:r green:g blue:b alpha:a];
    }
    else if([columnClass isSubclassOfClass:[UIImage class]])
    {
        //暂不支持
        modelValue = nil;
//        NSString* filename = value;
//        NSString* filepath = [self.class getDBImagePathWithName:filename];
//        if([LKDBUtils isFileExists:filepath])
//        {
//            LKDBImage* img = [[LKDBImage alloc] initWithContentsOfFile:filepath];
//            modelValue = img;
//        }
//        else
//        {
//            modelValue = nil;
//        }
    }
    else if([columnClass isSubclassOfClass:[NSData class]])
    {
        //暂不支持
        modelValue = nil;
//        NSString* filename = value;
//        NSString* filepath = [self.class getDBDataPathWithName:filename];
//        if([LKDBUtils isFileExists:filepath])
//        {
//            NSData* data = [NSData dataWithContentsOfFile:filepath];
//            modelValue = data;
//        }
//        else
//        {
//            modelValue = nil;
//        }
    }
    else
    {
        modelValue = nil;
//        modelValue = [self db_modelWithJsonValue:value];
//        if([modelValue isKindOfClass:columnClass] == NO)
//        {
//            modelValue = nil;
//        }
    }
    
    [self setValue:modelValue forKey:key];
}

@end
