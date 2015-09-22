//
//  User.h
//
//  Created by zhangfenghh  on 15/9/21
//  Copyright (c) 2015 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NBBaseDBTableModel.h"


@interface User : NBBaseDBTableModel <NSCoding, NSCopying>

@property (setter=setUid:,getter=uid,nonatomic, strong) NSString *_pk_uid;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) double age;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
