//
//  SecurityStore.m
//  SPFileCache
//
//  Created by Timothy Zelinsky on 23/06/2015.
//  Copyright (c) 2015 zelinsky. All rights reserved.
//

#import "SPSecurityStore.h"
#import <CommonCrypto/CommonDigest.h>

@interface SPSecurityStore()

@property(nonatomic, strong) NSDictionary *secrets;

@end

@implementation SPSecurityStore


#define kVersion 1.0

/*
 Note: This isn't a secure way of storing hashes. They shouldn't be here in clear text.
 A better way would be to retrieve them from a secure trusted backend store/
 OR generating them on the fly and storing them in a local keystore.
 For the purposes of the assignment this is the quickest approach.
*/

static SPSecurityStore *defaultStore = nil;
static dispatch_once_t onceToken;

+(SPSecurityStore *)defaultStore
{
    dispatch_once(&onceToken, ^{
        defaultStore = [[SPSecurityStore alloc] init];
    });
    return defaultStore;
}

-(id)init
{
    if (self = [super init]) {
        self.secrets = @{@(1.0): @"301Gxd0EfuRkMLYYemdgdkQy1Xt4yvpvMhoBL1ody"};
    }
    return self;
}

-(NSInteger)version
{
    return kVersion;
}


-(NSData *)hashForVersion:(NSInteger)version withObjectID:(NSData *)objectID andObject:(NSData*)object
{

    NSMutableData *hashableData = [[NSMutableData alloc] init];
    [hashableData appendData:[NSData dataWithBytes:&version length:sizeof(version)]];
    [hashableData appendData:objectID];
    [hashableData appendData:object];
    [hashableData appendData:[self.secrets[@(version)] dataUsingEncoding:NSUTF8StringEncoding]];
    unsigned int outputLength = CC_SHA1_DIGEST_LENGTH;
    unsigned char output[outputLength];
    
    CC_SHA1(hashableData.bytes, (unsigned int) hashableData.length, output);
    return [NSData dataWithBytes:output length:outputLength];
}

-(NSUInteger)hashLength
{
    return CC_SHA1_DIGEST_LENGTH;
}

@end
