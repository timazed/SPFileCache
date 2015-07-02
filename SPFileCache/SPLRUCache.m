//
//  LRUCache.m
//  SPFileCache
//
//  Created by Timothy Zelinsky on 22/06/2015.
//  Copyright (c) 2015 zelinsky. All rights reserved.
//

#import "SPLRUCache.h"
#import "SPLinkedList.h"
#import "SPRecord.h"
#import "SPNode.h"

@interface SPLRUCache()

@property(nonatomic, strong) NSMutableDictionary *recordRegistry;
@property(nonatomic, strong) SPLinkedList *orderedRecords;

-(void)setNode:(SPNode*)node withID:(NSData*)objectID;

@end

@implementation SPLRUCache

@synthesize size = _size;

-(id)init
{
    if (self = [super init]) {
        self.recordRegistry = [NSMutableDictionary dictionary];
        self.orderedRecords = [[SPLinkedList alloc] init];
    }
    return self;
}

-(SPRecord *)recordWithID:(NSData *)objectID
{
    SPNode *node = self.recordRegistry[objectID];
    return node.data;
}

-(void)setRecord:(SPRecord *)record withID:(NSData*)objectID
{
    SPNode *node = [self.orderedRecords addToBack:record];
    [self setNode:node withID:objectID];
}

-(void)removeRecordWithID:(NSData *)objectID
{
    SPNode *node = self.recordRegistry[objectID];
    [self.recordRegistry removeObjectForKey:objectID];
    _size -= [(SPRecord *)(node.data) size];
    [self.orderedRecords removeNode:node];
}

-(void)touchRecordWithID:(NSData *)objectID;
{
    SPNode *node = self.recordRegistry[objectID];
    [(SPRecord*)node.data touch];
    [self.orderedRecords moveNodeToBack:node];
}

-(SPRecord *)leastRecentlyUsedRecord
{
    if (self.recordRegistry.count > 0) {
        return (SPRecord *)[self.orderedRecords first].data;
    }
    return nil;
}


#pragma mark - 
#pragma mark Private Methods
-(void)setNode:(SPNode *)node withID:(NSData *)objectID
{
    SPNode *existingNode = self.recordRegistry[objectID];
    if (existingNode != nil) {
        _size -= [(SPRecord *)(existingNode.data) size];
    }
    _size += [(SPRecord *)(node.data) size];
    self.recordRegistry[objectID] = node;
}

@end
