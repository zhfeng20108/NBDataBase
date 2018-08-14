//
//  ViewController.m
//  NBDataBaseDemo
//
//  Created by ios_feng on 15/7/31.
//  Copyright (c) 2015年 pepper. All rights reserved.
//

#import "ViewController.h"
#import "NBDBConfigure.h"
#import "NBCommonDataBase.h"
#import "NBUserDataBase.h"

#import "Book.h"
#import "User.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
    //设置当前数据库版本号
    [NBDBConfigure setVersion:@"0.0.2"];
    //设置加密的最小版本号
    [NBDBConfigure setSmallestEncrypteVersion:@"0.0.2"];
    //设置是否加密和密阴
    [NBDBConfigure setEncrypted:YES secretkey:@"12345690po"];

    //公共数据库
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [paths objectAtIndex:0];
    NSString *dbPath = [cacheDirectory stringByAppendingPathComponent:@"common.db"];
    NSLog(@"cacheDirectory:  %@",cacheDirectory);
    [[NBCommonDataBase sharedInstance] setupDBWithDBPath:dbPath];
   
    //私有数据库
    [NBDBConfigure setCurrentUserId:@"12345"];

    NSString *dbDirecotry = [cacheDirectory stringByAppendingPathComponent:[NBDBConfigure currentUserId]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dbDirecotry])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:dbDirecotry
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
    }
    NSString *dbPath2 = [dbDirecotry stringByAppendingPathComponent:@"user.db"];
    [[NBUserDataBase sharedInstance] setupDBWithDBPath:dbPath2];
    
    
    Book *book1 = [[Book alloc] init];
    book1.bookId = @"3";
    book1.name = @"11";
    book1.infoDic = @{@"key1":@"aa",@"key2":@"bb"};

    User *user = [[User alloc] init];
    user.uid = @"343";
    user.name = @"haha";
    user.age = 10;
    book1.author = user;
    
    //数据入库
    [book1 saveToDB];
    
    //查询
    NSArray *array = [[Book getDataBase] query:[Book class]];
    NSLog(@"查询出来的数据：%@",array);

    //更新
    book1.name = @"1111111";
    [book1 saveToDBUseUpdateWithColumns:@"_name"];
    //删除
    [book1 deleteToDB];
    
    Book *book2 = [[Book alloc] init];
    book2.bookId = @"2";
    book2.name = @"22";
    
    [book2 saveToDB];
    
    
    NSMutableArray *muArr = [NSMutableArray array];
    
    User *user1 = [[User alloc] init];
    user1.uid = @"1";
    user1.name = @"a";
    user1.age = 5;
    
    User *user2 = [[User alloc] init];
    user2.uid = @"2";
    user2.name = @"b";
    user2.age = 15;
    
    User *user3 = [[User alloc] init];
    user3.uid = @"3";
    user3.name = @"c";
    user3.age = 20;
    
    [muArr addObject:user1];
    [muArr addObject:user2];
    [muArr addObject:user3];
    //以事务方式入库，适合大量数据入库时调用
    [[User getDataBase] insertToDBWithDataArray:muArr];
    });
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
