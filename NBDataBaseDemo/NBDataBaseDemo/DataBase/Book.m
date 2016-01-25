//
//  Book.m
//
//  Created by zhangfenghh  on 15/9/21
//  Copyright (c) 2015 __MyCompanyName__. All rights reserved.
//

#import "Book.h"
#import "NBCommonDataBase.h"
#import "User.h"

NSString *const kBookBookId = @"bookId";
NSString *const kBookName = @"name";
NSString *const kBookInfoDic = @"infoDic";
NSString *const kBookAuthor = @"author";


@interface Book ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation Book

@synthesize _pk_bookId = _bookId;

#pragma mark - load
+ (void)load
{
    [[self getDataBase] addRegisteClass:self];
}

#pragma mark - NBDBTableModelProtocol
+ (NBDataBase *)getDataBase
{
    return [NBCommonDataBase sharedInstance];
}



+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict
{
    return [[self alloc] initWithDictionary:dict];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    
    // This check serves to make sure that a non-NSDictionary object
    // passed into the model class doesn't break the parsing.
    if(self && [dict isKindOfClass:[NSDictionary class]]) {
            self.bookId = [self objectOrNilForKey:kBookBookId fromDictionary:dict];
            self.name = [self objectOrNilForKey:kBookName fromDictionary:dict];
        self.infoDic = [self objectOrNilForKey:kBookInfoDic fromDictionary:dict];
        self.author = [User modelObjectWithDictionary:[dict objectForKey:kBookAuthor]];


    }
    
    return self;
    
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:self.bookId forKey:kBookBookId];
    [mutableDict setValue:self.name forKey:kBookName];
    [mutableDict setValue:self.infoDic forKey:kBookInfoDic];
    [mutableDict setValue:[self.author dictionaryRepresentation] forKey:kBookAuthor];

    return [NSDictionary dictionaryWithDictionary:mutableDict];
}

- (NSString *)description 
{
    return [NSString stringWithFormat:@"%@", [self dictionaryRepresentation]];
}

#pragma mark - Helper Method
- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict
{
    id object = [dict objectForKey:aKey];
    return [object isEqual:[NSNull null]] ? nil : object;
}


#pragma mark - NSCoding Methods

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];

    self.bookId = [aDecoder decodeObjectForKey:kBookBookId];
    self.name = [aDecoder decodeObjectForKey:kBookName];
    self.infoDic = [aDecoder decodeObjectForKey:kBookInfoDic];
    self.author = [aDecoder decodeObjectForKey:kBookAuthor];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_bookId forKey:kBookBookId];
    [aCoder encodeObject:_name forKey:kBookName];
    [aCoder encodeObject:_infoDic forKey:kBookInfoDic];
    [aCoder encodeObject:_author forKey:kBookAuthor];

}

- (id)copyWithZone:(NSZone *)zone
{
    Book *copy = [[Book alloc] init];
    
    if (copy) {

        copy.bookId = [self.bookId copyWithZone:zone];
        copy.name = [self.name copyWithZone:zone];
        copy.infoDic = [self.infoDic copyWithZone:zone];
        copy.author = [self.author copyWithZone:zone];

    }
    
    return copy;
}




@end
