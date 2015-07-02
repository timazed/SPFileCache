//
//  SPFileCache.m
//  SPFileCache
//
//  Created by Timothy Zelinsky on 9/06/2015.
//  Copyright (c) 2015 zelinsky. All rights reserved.
//

#import "SPFileCache.h"
#import "SPRecord.h"
#import "SPLRUCache.h"
#import "SPSecurityStore.h"
#import "SPCacheManager.h"

@interface SPFileCache()

@property(nonatomic, strong) NSString *rootPath;
@property(nonatomic, strong) SPLRUCache *cache;
@property(nonatomic, assign) NSUInteger maxSize;

-(id)initWithPath:(NSString*)path maxSize:(NSUInteger)maxSize cache:(SPLRUCache *)cache;
-(BOOL)validateObjectID:(NSData *)objectID;
-(BOOL)validateObject:(NSData *)object;
-(void)removeOverCapacityObjects;

@end

@implementation SPFileCache

#define kCacheRootFolderName @"SPDATA"

#define kDomain @"com.spotify.SPCache"
#define kRecordNotFound 1
#define kRecordNotSafe 2
#define kRecordReadError 3
#define kObjectIDInvalid 4

#define kObjectIDMaxSize 32
#define k10B 10
#define k10MB 1024 * 1024 * 10

#define kErrorMsg @"message"

+(SPFileCache*)fileCacheAtPath:(NSString *)path
{
    NSString *rootPath = [path stringByAppendingPathComponent:kCacheRootFolderName];
    SPCacheManager *cacheManager = [SPCacheManager defaultManager];
    SPLRUCache *cache = nil;
    if (![cacheManager cacheExists:rootPath]) {
        cache = [cacheManager createCacheAtPath:rootPath];
    } else {
        cache = [cacheManager loadLRUCacheAtPath:rootPath];
    }

    NSUInteger maxSize = [cacheManager maxCacheSizeAtPath:rootPath];
    return [[SPFileCache alloc] initWithPath:rootPath maxSize:maxSize cache:cache];
}

-(id)initWithPath:(NSString*)path maxSize:(NSUInteger)maxSize cache:(SPLRUCache *)cache
{
    if (self = [super init]) {
        self.rootPath = path;
        self.cache = cache;
        self.maxSize = maxSize;
    }
    
    return self;
}


-(BOOL)containsObjectWithID:(NSData *)objectID
{
    if (![self validateObjectID:objectID]) {
        return NO;
    }
    return ([self.cache recordWithID:objectID] != nil);
}

-(NSData*)objectWithID:(NSData *)objectID error:(NSError *__autoreleasing *)error
{
    if (![self validateObjectID:objectID]) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:kDomain
                                         code:kObjectIDInvalid
                                     userInfo:@{kErrorMsg: @"ObjectID is invalid. Must be 0 < objectID <= 32bytes"}];
        }
        return nil;
    }

    SPRecord *record = [self.cache recordWithID:objectID];
    NSData *data = nil;
    if (record == nil) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:kDomain code:kRecordNotFound userInfo:@{kErrorMsg: @"Object not found!"}];
        }
    } else if (![record isValid]) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:kDomain code:kRecordNotSafe userInfo:@{kErrorMsg: @"Object has been corrupted"}];
        }
    } else {
        data = [record readData];
        if (data != nil) {
            [self.cache touchRecordWithID:objectID];
        } else if (error != NULL){
            *error = [NSError errorWithDomain:kDomain code:kRecordReadError userInfo:@{kErrorMsg: @"Unable to read object"}];
        }
    }
    
    return data;
}

-(BOOL)writeObject:(NSData *)object withID:(NSData *)objectID
{
    BOOL success = NO;
    
    if ([self validateObjectID:objectID andObject:object]) {
        SPRecord *record = [self.cache recordWithID:objectID];
        if (record != nil) {
            success = [record writeData:object];
            if (success) {
                [self.cache touchRecordWithID:objectID];
            }
        } else {
            SPSecurityStore *securityStore = [SPSecurityStore defaultStore];
            record = [SPRecord recordWithObjectID: objectID
                                       version:[securityStore version]
                                      andRootPath:self.rootPath];
            success = [record writeData:object];
            if (success) {
                [self.cache setRecord:record withID:objectID];
            }
        }
        
        [self removeOverCapacityObjects];
    }
    
    return success;
}

-(BOOL)removeObjectWithID:(NSData *)objectID
{
    BOOL removed = NO;
    if ([self validateObjectID:objectID]) {
        SPRecord *record = [self.cache recordWithID:objectID];
        [self.cache removeRecordWithID:objectID];
        removed = [record removeData];
        if (!removed) {
            // if we failed to remove the data add the record back.
            [self.cache setRecord:record withID:objectID];
        }
    }
    return removed;
}

-(NSUInteger)size
{
    return [self.cache size];
}

-(void)setMaxSize:(NSUInteger)maxSize
{
    if (maxSize > 0) {
        _maxSize = maxSize;
        [self removeOverCapacityObjects];
        SPCacheManager *cacheManager = [SPCacheManager defaultManager];
        [cacheManager setMaxCacheSize:maxSize atPath:self.rootPath];
    }
}
        
        
#pragma mark -
#pragma mark Private Methods
-(BOOL)validateObjectID:(NSData *)objectID andObject:(NSData *)object
{
    if (![self validateObjectID:objectID] || ![self validateObject:object]) {
        DLog(@"ObjectID should be 0B < objectID <= 32B and Object should be 10B <= object <= 10MB");
        return NO;
    }
    
    if ((object.length + objectID.length) > _maxSize) {
        DLog(@"This object is too big for the cache.");
        return NO;
    }
    
    return YES;
}

-(BOOL)validateObjectID:(NSData *)objectID
{
    return (objectID.length > 0 && objectID.length <= kObjectIDMaxSize);
}

-(BOOL)validateObject:(NSData *)object
{
    return (object.length >= k10B && object.length <= k10MB);
}
        
-(void)removeOverCapacityObjects
{
    while (self.cache.size > self.maxSize) {
        SPRecord *record = [self.cache leastRecentlyUsedRecord];
        [self removeObjectWithID:record.objectID];
    }
}

@end
