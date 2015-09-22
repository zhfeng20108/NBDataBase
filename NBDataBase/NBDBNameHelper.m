//
//  NBDBNameHelper.m
//  pengpeng
//
//  Created by feng on 14/12/12.
//  Copyright (c) 2014年 AsiaInnovations. All rights reserved.
//

#import "NBDBNameHelper.h"
#import "NBDBDefine.h"

// see http://stackoverflow.com/questions/1918972/camelcase-to-underscores-and-back-in-objective-c

/**
 *  Get a snake case string from camel case.
 *
 *  @param input camel case string
 *
 *  @return snake case string
 */
NSString *FMSnakeCaseFromCamelCase(NSString *input)
{
    NSMutableString *output = [NSMutableString string];
    NSCharacterSet *uppercase = [NSCharacterSet uppercaseLetterCharacterSet];
    for (NSInteger idx = 0; idx < [input length]; idx += 1) {
        unichar c = [input characterAtIndex:idx];
        if ([uppercase characterIsMember:c] && idx == 0) {
            [output appendFormat:@"%@", [[NSString stringWithCharacters:&c length:1] lowercaseString]];
        } else if ([uppercase characterIsMember:c]) {
            [output appendFormat:@"_%@", [[NSString stringWithCharacters:&c length:1] lowercaseString]];
        } else {
            [output appendFormat:@"%C", c];
        }
    }
    return output;
}

/**
 *  Get a upper camel case string from snake case.
 *
 *  @param input snake case string
 *
 *  @return upper camel case string
 */
NSString *FMUpperCamelCaseFromSnakeCase(NSString *input)
{
    NSMutableString *output = [NSMutableString string];
    BOOL makeNextCharacterUpperCase = NO;
    for (NSInteger idx = 0; idx < [input length]; idx += 1) {
        unichar c = [input characterAtIndex:idx];
        if (idx == 0) {
            [output appendString:[[NSString stringWithCharacters:&c length:1] uppercaseString]];
        } else if (c == '_') {
            makeNextCharacterUpperCase = YES;
        } else if (makeNextCharacterUpperCase) {
            [output appendString:[[NSString stringWithCharacters:&c length:1] uppercaseString]];
            makeNextCharacterUpperCase = NO;
        } else {
            [output appendFormat:@"%C", c];
        }
    }
    return output;
}

/**
 *  Get a lower camel case string from snake case.
 *
 *  @param input snake case string
 *
 *  @return lower camel case string
 */
NSString *FMLowerCamelCaseFromSnakeCase(NSString *input)
{
    NSMutableString *output = [NSMutableString string];
    BOOL makeNextCharacterUpperCase = NO;
    for (NSInteger idx = 0; idx < [input length]; idx += 1) {
        unichar c = [input characterAtIndex:idx];
        if (c == '_') {
            makeNextCharacterUpperCase = YES;
        } else if (makeNextCharacterUpperCase) {
            [output appendString:[[NSString stringWithCharacters:&c length:1] uppercaseString]];
            makeNextCharacterUpperCase = NO;
        } else {
            [output appendFormat:@"%C", c];
        }
    }
    return output;
}

/**
 *  Get a table name from model class name.
 *
 *  @param input <#input description#>
 *
 *  @return <#return value description#>
 */
NSString *FMDefaultTableNameFromModelName(NSString *input)
{
    NSMutableString *output = [NSMutableString stringWithString:@"tb_"];
    NSCharacterSet *uppercase = [NSCharacterSet uppercaseLetterCharacterSet];
    
    BOOL isAlreadyRemovedPrefix = NO;
    
    for (NSInteger idx = 0; idx < [input length]; idx += 1) {
        unichar c = [input characterAtIndex:idx];
        unichar nc = 0;
        if (idx < ([input length] - 1)) {
            nc = [input characterAtIndex:idx + 1];
        }
        
        if ([uppercase characterIsMember:c] && [uppercase characterIsMember:nc] && !isAlreadyRemovedPrefix) {
            // remove prefix.
        } else if ([uppercase characterIsMember:c]) {
            if (!isAlreadyRemovedPrefix) {
                isAlreadyRemovedPrefix = YES;
                [output appendFormat:@"%@", [[NSString stringWithCharacters:&c length:1] lowercaseString]];
            } else {
                [output appendFormat:@"_%@", [[NSString stringWithCharacters:&c length:1] lowercaseString]];
            }
        } else {
            if (!isAlreadyRemovedPrefix) {
                isAlreadyRemovedPrefix = YES;
            }
            [output appendFormat:@"%C", c];
        }
    }
    
    // To plural form
    [output appendString:@"s"];
    
    return output;
}

//把属性名转成数据库表的列名
NSString *FMColumnNameFromPropertyName(NSString *propertyName)
{
    //去前缀
    NSMutableString *muStr = [NSMutableString stringWithFormat:@"_%@",propertyName];
    [muStr replaceOccurrencesOfString:kNBPrimaryKey_Identify withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, muStr.length-1)];
    [muStr replaceOccurrencesOfString:kNBNotnull_Identify withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, muStr.length-1)];
    [muStr replaceOccurrencesOfString:kNBDflt_value_Identify withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, muStr.length-1)];
    
    return [NSString stringWithString:muStr];
}


SEL FMSetterSelectorFromColumnName(NSString *input)
{
    return NSSelectorFromString([NSString stringWithFormat:@"set%@:", FMUpperCamelCaseFromSnakeCase(input)]);
}
