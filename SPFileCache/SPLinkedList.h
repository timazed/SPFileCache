//
//  SPLinkedList.h
//  SPFileCache
//
//  Created by Timothy Zelinsky on 22/06/2015.
//  Copyright (c) 2015 zelinsky. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SPNode;
@interface SPLinkedList : NSObject

@property(nonatomic, readonly) NSInteger count;
@property(nonatomic, readonly) SPNode *first;
@property(nonatomic, readonly) SPNode *last;


-(SPNode *)addToBack:(id)object;
-(void)moveNodeToBack:(SPNode *)node;
-(void)removeNode:(SPNode *)node;

@end
