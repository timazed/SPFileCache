//
//  LRUCache.h
//  SPFileCache
//
//  Created by Timothy Zelinsky on 22/06/2015.
//  Copyright (c) 2015 zelinsky. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SPRecord;
@interface SPLRUCache : NSObject

@property(nonatomic, readonly) NSUInteger size;

-(SPRecord *)recordWithID:(NSData *)objectID;
-(void)setRecord:(SPRecord *)record withID:(NSData*)objectID;
-(void)removeRecordWithID:(NSData *)objectID;
-(void)touchRecordWithID:(NSData *)objectID;
-(SPRecord *)leastRecentlyUsedRecord;

@end
