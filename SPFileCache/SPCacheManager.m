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

//-(BFTask *)createFoldersAt:(NSString*)path currDepth:(int)currDepth maxDepth:(int)maxDepth;
//-(NSString *)mkDirAt:(NSString*)path folderID:(int)folderID;
-(NSArray *)recordsAtPath:(NSString *)path;

@end

@implementation SPCacheManager

//#define kMaxDepth 2
#define kManifestFile @"mainfest.json"
#define kDefaultCacheMaxSize (1024 * 1024 * 1024) * 1 // 1GB
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
        
    }
    return maxSize;
}

-(void)setMaxCacheSize:(NSUInteger)maxSize atPath:(NSString *)path
{
    if ([self cacheExists:path]) {
        NSData *mainfest = [NSJSONSerialization dataWithJSONObject:@{kMaxSizeMetadataKey: @(maxSize)}
                                                           options:0
                                                             error:nil];

        [mainfest writeToFile:[path stringByAppendingPathComponent:kManifestFile] atomically:YES];
    }
}


//===========================================================
// PRIVATE METHODS
//===========================================================
#pragma mark -
#pragma Private Methods
//-(BFTask *)createFoldersAt:(NSString*)path currDepth:(int)currDepth maxDepth:(int)maxDepth
//{
//    if (currDepth == maxDepth) {
//        return nil;
//    }
//    BFExecutor *executor = [BFExecutor executorWithDispatchQueue:self.sessionQueue];
//    NSMutableArray *tasks = [NSMutableArray array];
//    for (int i=0; i<kMaxNumFolders; i++) {
//        [tasks addObject:[[BFTask taskFromExecutor:executor withBlock:^id{
//            NSString *folder = [self mkDirAt:path folderID:i];
//            BFTaskCompletionSource *source = [BFTaskCompletionSource taskCompletionSource];
//            [source setResult:folder];
//            return source.task;
//        }] continueWithBlock:^id(BFTask *task) {
//            return [self createFoldersAt: task.result currDepth:currDepth + 1  maxDepth:maxDepth];
//        }]];
//    }
//    NSLog(@"%d", tasks.count);
//    return [BFTask taskForCompletionOfAllTasks:tasks];
//}
//
//-(NSString *)mkDirAt:(NSString*)path folderID:(int)folderID
//{
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSString *folder = [path stringByAppendingPathComponent:[NSString stringWithFormat:kIntToHex, folderID]];
//    [fileManager createDirectoryAtPath:folder
//           withIntermediateDirectories:YES
//                            attributes:nil
//                                 error:nil];
//    
//    return folder;
//}

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


@end
