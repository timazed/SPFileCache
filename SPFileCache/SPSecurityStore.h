//
//  SecurityStore.h
//  SPFileCache
//
//  Created by Timothy Zelinsky on 23/06/2015.
//  Copyright (c) 2015 zelinsky. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPSecurityStore : NSObject

+(SPSecurityStore *)defaultStore;
-(NSInteger)version;
-(NSData *)hashForVersion:(NSInteger)version withObjectID:(NSData *)objectID andObject:(NSData*)object;
-(NSUInteger)hashLength;

@end
