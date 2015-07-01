//
//  NSString+Extensions.m
//  SPFileCache
//
//  Created by Timothy Zelinsky on 29/06/2015.
//  Copyright (c) 2015 zelinsky. All rights reserved.
//

#import "NSString+Extensions.h"

@implementation NSString (Extensions)

#define kIntToHex @"%02x"

+(NSString *)hexStringFromInt:(int)val
{
    return [[NSString stringWithFormat:kIntToHex, val] uppercaseString];
}

@end
