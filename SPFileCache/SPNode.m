//
//  SPNode.m
//  SPFileCache
//
//  Created by Timothy Zelinsky on 30/06/2015.
//  Copyright (c) 2015 zelinsky. All rights reserved.
//

#import "SPNode.h"

@implementation SPNode

+(SPNode *) nodeWithData:(id)data prev:(SPNode *)prev andNext:(SPNode *)next
{
    SPNode *node = [[SPNode alloc] init];
    node.next = next;
    node.prev = prev;
    node.data = data;
    return node;
};

@end
