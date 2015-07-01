//
//  SPRecord.h
//  SPFileCache
//
//  Created by Timothy Zelinsky on 22/06/2015.
//  Copyright (c) 2015 zelinsky. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPRecord : NSObject

@property(nonatomic, readonly) NSData *objectID;
@property(nonatomic, readonly) NSInteger version;

+(SPRecord *)recordWithObjectID:(NSData *)objectID version:(NSInteger)version andRootPath:(NSString*)path;
+(SPRecord *)recordAtPath:(NSString *)path;
-(void)touch;
-(BOOL)isValid;
-(NSData *)readData;
-(BOOL)writeData:(NSData*)data;
-(BOOL)removeData;
-(NSUInteger)size;
-(NSDate *)lastModified;

@end
