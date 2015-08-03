//
//  NBDBNameHelper.h
//  pengpeng
//
//  Created by feng on 14/12/12.
//  Copyright (c) 2014年 AsiaInnovations. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString *FMSnakeCaseFromCamelCase(NSString *input);
NSString *FMLowerCamelCaseFromSnakeCase(NSString *input);
NSString *FMUpperCamelCaseFromSnakeCase(NSString *input);
NSString *FMDefaultTableNameFromModelName(NSString *input);
NSString *FMColumnNameFromPropertyName(NSString *propertyName);
SEL FMSetterSelectorFromColumnName(NSString *input);

/*
 XCTAssertEqualObjects(@"aaa_bbb_ccc", FMSnakeCaseFromCamelCase(@"aaaBbbCcc"));
 XCTAssertEqualObjects(@"aaa_bbb_ccc", FMSnakeCaseFromCamelCase(@"AaaBbbCcc"));
 XCTAssertEqualObjects(@"my_name_is_kohki_makimoto", FMSnakeCaseFromCamelCase(@"MyNameIsKohkiMakimoto"));
 
 XCTAssertEqualObjects(@"AaaBbbCcc", FMUpperCamelCaseFromSnakeCase(@"aaa_bbb_ccc"));
 XCTAssertEqualObjects(@"MyNameIsKohkiMakimoto", FMUpperCamelCaseFromSnakeCase(@"my_name_is_kohki_makimoto"));
 
 XCTAssertEqualObjects(@"aaaBbbCcc", FMLowerCamelCaseFromSnakeCase(@"aaa_bbb_ccc"));
 XCTAssertEqualObjects(@"myNameIsKohkiMakimoto", FMLowerCamelCaseFromSnakeCase(@"my_name_is_kohki_makimoto"));
 
 XCTAssertEqualObjects(@"users", FMDefaultTableNameFromModelName(@"FMXUser"));
 XCTAssertEqualObjects(@"articles", FMDefaultTableNameFromModelName(@"Article"));
 XCTAssertEqualObjects(@"web_users", FMDefaultTableNameFromModelName(@"ABWebUser"));
 XCTAssertEqualObjects(@"web_users", FMDefaultTableNameFromModelName(@"WebUser"));
 
 XCTAssertEqualObjects(@"bbb_a_a_as", FMDefaultTableNameFromModelName(@"AABbbAAA"));
 */