//
//  SPNode.h
//  SPFileCache
//
//  Created by Timothy Zelinsky on 30/06/2015.
//  Copyright (c) 2015 zelinsky. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface SPNode : NSObject

@property(nonatomic, strong) id data;
@property(nonatomic, strong) SPNode *prev;
@property(nonatomic, strong) SPNode *next;

+(SPNode *) nodeWithData:(id)data prev:(SPNode *)prev andNext:(SPNode *)next;

@end
