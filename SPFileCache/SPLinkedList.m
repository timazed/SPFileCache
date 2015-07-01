//
//  SPLinkedList.m
//  SPFileCache
//
//  Created by Timothy Zelinsky on 22/06/2015.
//  Copyright (c) 2015 zelinsky. All rights reserved.
//

#import "SPLinkedList.h"
#import "SPNode.h"

@implementation SPLinkedList

-(id)init
{
    if (self = [super init]) {
        _first = _last = nil;
        _count = 0;
    }
    return self;
}

-(BOOL)isEmpty
{
    return _count == 0;
}

-(SPNode *)addToBack:(id)object
{
    SPNode *node = [SPNode nodeWithData:object prev:self.last andNext:nil];
    
    if ([self isEmpty]) {
        _first = _last = node;
    } else {
        _last.next = node;
        _last = node;
    }
    
    _count++;
    return node;
}

-(void)moveNodeToBack:(SPNode *)node
{
    SPNode *prev = node.prev;
    SPNode *next = node.next;
    
    prev.next = next;
    next.prev = prev;
    
    _last.next = node;
    node.prev = _last;
    node.next = nil;
    _last = node;
}

- (void)removeNode:(SPNode *)node
{
    if (_count == 1) {
        _first = _last = nil;
    } else if (node.prev == nil) {
        _first = _first.next;
        _first.prev = nil;
    } else if (node.next == nil) {
        _last = _last.prev;
        _last.next = nil;
    } else {
        SPNode *prev = node.prev;
        SPNode *next = node.next;
        
        prev.next = next;
        next.prev = prev;
    }
    
    node = nil;
    _count--;
}


@end
