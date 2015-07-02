//
//  SPFileCahceTest.m
//  SPFileCache
//
//  Created by Timothy Zelinsky on 29/06/2015.
//  Copyright (c) 2015 zelinsky. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <SPFileCache/SPFileCache.h>
#import "NSData+Extensions.h"

@interface SPFileCahceTest : XCTestCase

@property (nonatomic, strong) SPFileCache *cache;

@end

@implementation SPFileCahceTest

#define kFileCachPath @"/Users/tima/Documents/Projects/SPFileCache/SPFileCacheTests"
#define kCachFolder @"SPDATA"

#define kObjectIDSize 32
#define kObjectSize (1024 * 1024) * 10

#define kLargeObjectID 36
#define kSmallObjectID 0

#define kLargeObject ((1024 * 1024) * 10) + 4
#define kSmallObject 8

#define kMaxCacheSize (1024 * 1024) * 51
#define kMaxNumOfObjects 5

- (void)setUp
{
    [super setUp];
    self.cache = [SPFileCache fileCacheAtPath:kFileCachPath];

    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

/**
 * 1. check if object exists.
 * 2. write object to cache.
 * 3. check if object exists.
 * 4. read object from cache compare with original.
 * 5. remove object from cache.
 * 6. check if object exits.
 */
- (void)testHappyCase
{
    NSData *objectID = [self generateDataWithSize:kObjectIDSize];
    XCTAssert(![self.cache containsObjectWithID:objectID], @"Object shouldn't exist!");
    NSData *object = [self generateDataWithSize:kObjectSize];
    XCTAssert([self.cache writeObject:object withID:objectID], @"Object should have been written to cache!");
    XCTAssert([self.cache containsObjectWithID:objectID], @"Object should exist!");
    NSError *error;
    NSData *cachedObject = [self.cache objectWithID:objectID error:&error];
    if (error != nil) {
        XCTFail(@"%@", [error description]);
    }
    XCTAssert([object isEqual:cachedObject], @"Objects should be equal WTF!");
    XCTAssert([self.cache removeObjectWithID:objectID], @"Object should have removed!");
    XCTAssert(![self.cache containsObjectWithID:objectID], @"Object should not exist!");
}

/**
 * 1. write object to cache.
 * 2. check if object exists.
 * 3. tamper with object.
 * 4. read object.
 */
-(void) testErrorChecking
{
    NSData *objectID = [self generateDataWithSize:kObjectIDSize];
    NSData *object = [self generateDataWithSize:kObjectSize];
    XCTAssert([self.cache writeObject:object withID:objectID], @"Object should have been written to cache!");
    XCTAssert([self.cache containsObjectWithID:objectID], @"Object Exists!");
    
    NSString *hexObjectID = [objectID toHexString];
    NSString *subFolderOne = [hexObjectID substringWithRange:NSMakeRange(0, 2)];
    NSString *subFolderTwo = [hexObjectID substringWithRange:NSMakeRange(2, 2)];
    NSString *filePath = [[[[kFileCachPath stringByAppendingPathComponent:kCachFolder]
                            stringByAppendingPathComponent:subFolderOne]
                            stringByAppendingPathComponent:subFolderTwo]
                            stringByAppendingPathComponent:hexObjectID];
    
    NSFileHandle *writeHandle = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
    [writeHandle seekToFileOffset:1000];
    [writeHandle writeData:[self generateDataWithSize:sizeof(int) * 2]];
    
    NSError *error;
    XCTAssert([self.cache objectWithID:objectID error:&error] == nil, @"Object should be nil");
    XCTAssert(error != nil, @"The object should be invalid!");
    XCTAssert(error.code == 2, @"The object should have had an error code of 2 for not safe");
}

/**
 * 1. write object too big - should fail.
 * 2. write object too small - should fail.
 * 3. use objectID too small - should fail.
 * 4. use objectID too big - should fail.
 */
-(void)testObjectValidation
{
    NSData *objectID = [self generateDataWithSize:kObjectSize];
    NSData *object = [self generateDataWithSize:kObjectSize];

    NSData *largeObject = [self generateDataWithSize:kLargeObject];
    XCTAssert(![self.cache writeObject:largeObject withID:objectID], @"Object too large waaah!");
    largeObject = nil;
    
    NSData *smallObject = [self generateDataWithSize:kSmallObject];
    XCTAssert(![self.cache writeObject:smallObject withID:objectID], @"Object too small waaah!");
    smallObject = nil;
    
    
    NSData *largeObjectID = [self generateDataWithSize:kLargeObjectID];
    XCTAssert(![self.cache writeObject:object withID:largeObjectID], @"ObjectID was too large waaah!");
    
    NSData *smallObjectID = [self generateDataWithSize:kSmallObjectID];
    XCTAssert(![self.cache writeObject:object withID:smallObjectID], @"Object was too small waah!");
}

/**
 * 1. write objects to max size of cache.
 * 2. check if first record is kicked out.
 * 3. read second object.
 * 4. write object.
 * 5. ensure second object wasn't kicked out.
 */
-(void)testLRUFunctionality
{
    NSData *firstObjectID = [self generateDataWithSize:kObjectIDSize];
    NSData *secondObjectID = [self generateDataWithSize:kObjectIDSize];
    NSData *object = [self generateDataWithSize:kObjectSize];
    [self.cache setMaxSize:kMaxCacheSize];

    [self.cache writeObject:object withID:firstObjectID];
    [self.cache writeObject:object withID:secondObjectID];
    
    for (int i=2; i<kMaxNumOfObjects; i++) {
        [self.cache writeObject:object withID:[self generateDataWithSize:kObjectIDSize]];
    }
    
    //write object that goes over the limit.
    [self.cache writeObject:object withID:[self generateDataWithSize:kObjectIDSize]];
    
    XCTAssert(![self.cache containsObjectWithID:firstObjectID]);
    XCTAssert([[self.cache objectWithID:secondObjectID error:nil] isEqualToData:object], @"Objects should be equal!");
    
    //write another object to make sure second object wasn't kicked out.
    XCTAssert([self.cache containsObjectWithID:secondObjectID], @"Second object should still be there!");
}

/**
 * measure how fast containsObject is.
 */
- (void)testPerformanceExample
{
    NSData *objectID = [self generateDataWithSize:kObjectIDSize];
    [self.cache writeObject:[self generateDataWithSize:kObjectSize] withID:objectID];
    // This is an example of a performance test case.
    [self measureBlock:^{
        [self.cache objectWithID:objectID error:nil];
    }];
}

-(NSData *)generateDataWithSize:(int)size
{
    NSMutableData *data = [NSMutableData dataWithCapacity:size];
    for (unsigned int i=0; i<size/sizeof(u_int32_t); i++) {
        u_int32_t bytes = arc4random();
        [data appendBytes:(void*)&bytes length:sizeof(u_int32_t)];
    }
    return data;
}

@end
