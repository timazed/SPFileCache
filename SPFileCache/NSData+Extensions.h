//
//  NSData+NSData_Extensions.h
//  SPFileCache
//
//  Created by Timothy Zelinsky on 10/06/2015.
//  Copyright (c) 2015 zelinsky. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (Extensions)

+(NSData*)dataFromHexString:(NSString *)hextString;

-(NSString*) toHexString;


@end
