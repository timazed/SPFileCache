//
//  SPFileManager.m
//  SPFileCache
//
//  Created by Timothy Zelinsky on 28/06/2015.
//  Copyright (c) 2015 zelinsky. All rights reserved.
//

#import "SPCacheManager.h"
#import "SPLRUCache.h"
#import "SPRecord.h"

@interface SPCacheManager ()

@property(nonatomic, strong) dispatch_queue_t sessionQueue;

-(NSArray *)recordsAtPath:(NSString *)path;
-(void)ensureFolderExists:(NSString *)path;

@end

@implementation SPCacheManager

#define kHiddenDir @".SPINFO"
#define kManifestFile @"MANIFEST.DAT"
#define kDefaultCacheMaxSize (1024 * 1024 * 1024) * 2 // 2 GB
#define kMaxSizeMetadataKey @"maxsize"
#define kMaxNumFolders 256

static SPCacheManager *manager = nil;
static dispatch_once_t onceToken;

+(SPCacheManager *)defaultManager
{
    dispatch_once(&onceToken, ^{
        manager = [[SPCacheManager alloc] init];
    });
    return manager;
}

-(id)init
{
    if (self = [super init]) {
        self.sessionQueue = dispatch_queue_create("com.spotify.SPCacheManager", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

-(BOOL)cacheExists:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:path];
}

-(SPLRUCache *)createCacheAtPath:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    return [[SPLRUCache alloc] init];
}

-(SPLRUCache *)loadLRUCacheAtPath:(NSString *)path
{
    //Note: Could be a potential bottle neck when the cache is huge. Potentially dispatch to separate threads to spead it up.
    NSMutableArray *records = [NSMutableArray array];
    for (int i=0; i<kMaxNumFolders; i++) {
        NSString *rootPath = [path stringByAppendingPathComponent: [NSString hexStringFromInt:i]];
        for (int j=0; j<kMaxNumFolders; j++) {
            NSString *recordsPath = [rootPath stringByAppendingPathComponent:[NSString hexStringFromInt: j]];
            [records addObjectsFromArray:[self recordsAtPath:recordsPath]];
        }
    }
    
    [records sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSDate *lastModifiedObj1 = [(SPRecord *)obj1 lastModified];
        NSDate *lastModifiedObj2 = [(SPRecord *)obj2 lastModified];
        return [lastModifiedObj1 compare:lastModifiedObj2];
    }];
    
    SPLRUCache *cache = [[SPLRUCache alloc] init];
    for (int i=0; i<records.count; i++) {
        SPRecord *record = records[i];
        [cache setRecord:record withID:record.objectID];
    }
    
    return cache;
}

-(NSUInteger)maxCacheSizeAtPath:(NSString *)path
{
    NSUInteger maxSize = kDefaultCacheMaxSize;
    if ([self cacheExists:path]) {
        NSString *manifest = [[path stringByAppendingPathComponent:kHiddenDir]
                                    stringByAppendingPathComponent:kManifestFile];

        NSData *data = [NSData dataWithContentsOfFile:manifest];
        if (data != nil) {
            NSUInteger tmpMaxSize;
            [data getBytes:&tmpMaxSize length:sizeof(maxSize)];
            if (tmpMaxSize > 0) {
                maxSize = tmpMaxSize;
            }
        }
    }
    return maxSize;
}

-(void)setMaxCacheSize:(NSUInteger)maxSize atPath:(NSString *)path
{
    if ([self cacheExists:path]) {
        NSString *mainfestFolder = [path stringByAppendingPathComponent:kHiddenDir];
        [self ensureFolderExists:mainfestFolder];
        NSData *data = [NSData dataWithBytes:&maxSize length:sizeof(maxSize)];
        [data writeToFile:[mainfestFolder stringByAppendingPathComponent:kManifestFile] atomically:YES];
    }
}

//===========================================================
// PRIVATE METHODS
//===========================================================
#pragma mark -
#pragma Private Methods
-(NSArray *)recordsAtPath:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:path];
    NSMutableArray *records = [NSMutableArray array];
    NSString *file;
    while ((file = [enumerator nextObject])) {
        if (file != nil) {
            [records addObject:[SPRecord recordAtPath: [path stringByAppendingPathComponent:file]]];
        }
    }
    return records;
}

-(void)ensureFolderExists:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path]) {
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
}


@end
