//
//  User.m
//
//  Created by zhangfenghh  on 15/9/21
//  Copyright (c) 2015 __MyCompanyName__. All rights reserved.
//

#import "User.h"
#import "NBUserDataBase.h"

NSString *const kUserUid = @"uid";
NSString *const kUserName = @"name";
NSString *const kUserAge = @"age";


@interface User ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation User

@synthesize _pk_uid = _uid;
@synthesize name = _name;
@synthesize age = _age;

#pragma mark - load
+ (void)load
{
    [[self getDataBase] addRegisteClass:self];
}

#pragma mark - NBDBTableModelProtocol
+ (NBDataBase *)getDataBase
{
    return [NBUserDataBase sharedInstance];
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
            self.uid = [self objectOrNilForKey:kUserUid fromDictionary:dict];
            self.name = [self objectOrNilForKey:kUserName fromDictionary:dict];
            self.age = [[self objectOrNilForKey:kUserAge fromDictionary:dict] doubleValue];

    }
    
    return self;
    
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:self.uid forKey:kUserUid];
    [mutableDict setValue:self.name forKey:kUserName];
    [mutableDict setValue:[NSNumber numberWithDouble:self.age] forKey:kUserAge];

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

    self.uid = [aDecoder decodeObjectForKey:kUserUid];
    self.name = [aDecoder decodeObjectForKey:kUserName];
    self.age = [aDecoder decodeDoubleForKey:kUserAge];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_uid forKey:kUserUid];
    [aCoder encodeObject:_name forKey:kUserName];
    [aCoder encodeDouble:_age forKey:kUserAge];
}

- (id)copyWithZone:(NSZone *)zone
{
    User *copy = [[User alloc] init];
    
    if (copy) {

        copy.uid = [self.uid copyWithZone:zone];
        copy.name = [self.name copyWithZone:zone];
        copy.age = self.age;
    }
    
    return copy;
}


@end
