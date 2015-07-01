//
//  SPFileManager.h
//  SPFileCache
//
//  Created by Timothy Zelinsky on 28/06/2015.
//  Copyright (c) 2015 zelinsky. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SPLRUCache;
@interface SPCacheManager : NSObject

+(SPCacheManager *)defaultManager;
-(BOOL)cacheExists:(NSString *)path;
-(SPLRUCache *)createCacheAtPath:(NSString *)path;
-(SPLRUCache *)loadLRUCacheAtPath:(NSString *)path;
-(NSUInteger)maxCacheSizeAtPath:(NSString *)path;
-(void)setMaxCacheSize:(NSUInteger)maxSize atPath:(NSString *)path;

@end
