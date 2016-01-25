//
//  Book.h
//
//  Created by zhangfenghh  on 15/9/21
//  Copyright (c) 2015 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NBBaseDBTableModel.h"
@class User;

@interface Book : NBBaseDBTableModel <NSCoding, NSCopying>

@property (setter=setBookId:,getter=bookId,nonatomic, strong) NSString *_pk_bookId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDictionary *infoDic;
@property (nonatomic, strong) User *author;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
