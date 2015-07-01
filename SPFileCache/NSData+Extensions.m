//
//  NSData+NSData_Extensions.m
//  SPFileCache
//
//  Created by Timothy Zelinsky on 10/06/2015.
//  Copyright (c) 2015 zelinsky. All rights reserved.
//

#import "NSData+Extensions.h"

@implementation NSData (Extensions)

-(NSString*) toHexString
{
    const unsigned char *dataBuffer = (const unsigned char *)[self bytes];
    
    if (!dataBuffer) {
        return [NSString string];
    }
    
    NSUInteger len  = [self length];
    NSMutableString *hexString  = [NSMutableString stringWithCapacity:(len * 2)];
    
    for (int i = 0; i < len; ++i) {
        NSString *hexSubString = [[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]] uppercaseString];
        [hexString appendString:hexSubString];
    }
    
    return [NSString stringWithString:hexString];
}

+(NSData*)dataFromHexString:(NSString *)hextString
{
    NSMutableData *data= [[NSMutableData alloc] init];
    unsigned char byte;
    char chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i<[hextString length]/2; i++) {
        chars[0] = [hextString characterAtIndex:i*2];
        chars[1] = [hextString characterAtIndex:i*2+1];
        byte = strtol(chars, NULL, 16);
        [data appendBytes:&byte length:1];
    }
    
    return [NSData dataWithData:data];
}

@end
