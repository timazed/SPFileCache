//
//  SPRecord.m
//  SPFileCache
//
//  Created by Timothy Zelinsky on 22/06/2015.
//  Copyright (c) 2015 zelinsky. All rights reserved.
//

#import "SPRecord.h"
#import "NSData+Extensions.h"
#import "SPSecurityStore.h"

@interface SPRecord ()

@property(nonatomic, strong) NSURL *fileURL;
@property(nonatomic, strong) NSData *hash;

-(void)readMetadata;

@end

/**
 * RECORD STRUCTURE
 *  ------------------------
 * |     VERSION  HASH      |
 * |                        |
 * |      OBJECT-DATA       |
 *  ------------------------
 *
 * VERSION -- NSInteger (32bit)4bytes | (64bit)8bytes
 * HASH -- NSData 20bytes -(used for validation to ensure the record is tamper proof and corruption proof)
 * OBJECT-DATA -- NSata 10B to 10MB.
 */
@implementation SPRecord

#define kNSURLFileFormat @"file://%@"

@synthesize version = _version;
@synthesize hash = _hash;

+(SPRecord *)recordAtPath:(NSString *)path
{
    NSString *hexObjectID = [path lastPathComponent];
    NSData *objectID = [NSData dataFromHexString:hexObjectID];
    NSURL *fileURL = [NSURL  URLWithString:[NSString stringWithFormat:kNSURLFileFormat, path]];
    return [[SPRecord alloc] initWithID:objectID version:-1 andFileURL:fileURL];
}

+(SPRecord *)recordWithObjectID:(NSData *)objectID version:(NSInteger)version andRootPath:(NSString*)path
{
    NSString *hexObjectID = [objectID toHexString];
    NSString *folderOne = [hexObjectID substringWithRange:NSMakeRange(0, 2)];
    NSString *folderTwo = [hexObjectID substringWithRange:NSMakeRange(2, 2)];
    NSString *filePath = [[path stringByAppendingPathComponent:folderOne] stringByAppendingPathComponent:folderTwo];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //create the cache folder if it doesn't exist.
    if (![fileManager fileExistsAtPath:filePath]) {
        [fileManager createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSURL *fileURL = [NSURL URLWithString:[NSString stringWithFormat:kNSURLFileFormat , [filePath stringByAppendingPathComponent:hexObjectID]]];
    [fileManager createFileAtPath:[fileURL path] contents:nil attributes:nil];
    return [[SPRecord alloc] initWithID:objectID version:version andFileURL:fileURL];
}

-(id)initWithID:(NSData *)objectID version:(NSInteger)version andFileURL:(NSURL*)fileURL
{
    if (self = [super init]) {
        _objectID = objectID;
        _version = version;
        _fileURL = fileURL;
    }
    
    return self;
}

-(BOOL)isValid
{
    SPSecurityStore *securityStore = [SPSecurityStore defaultStore];
    NSData *newHash = [securityStore hashForVersion:self.version objectID:self.objectID andObject:[self readData]];
    return [newHash isEqualToData:self.hash];
}

-(NSData *)readData
{
    SPSecurityStore *securityStore = [SPSecurityStore defaultStore];
    NSError *error;
    NSFileHandle *readHandle = [NSFileHandle fileHandleForReadingFromURL:self.fileURL error:&error];
    NSUInteger offset = sizeof(_version) + [securityStore hashLength];
    [readHandle seekToFileOffset:offset];
    return [readHandle readDataToEndOfFile];
}

-(BOOL)writeData:(NSData *)data
{
    /* 
     NOTE this assumes we're using version one to write contents the file.
     When another format of the file is introduced I would split this SPRecord into a protocol
     and have specific implemntations handle the creation of the objects.
     construction of records would come from a Factory.
    */
    
    SPSecurityStore *securityStore = [SPSecurityStore defaultStore];
    NSMutableData *fileContents = [NSMutableData data];
    [fileContents appendData:[NSData dataWithBytes:&_version length:sizeof(_version)]];
    [fileContents appendData:[securityStore hashForVersion:self.version objectID:self.objectID andObject:data]];
    [fileContents appendData:data];
    
    NSError *error;
    NSFileHandle *writeHandle = [NSFileHandle fileHandleForWritingToURL:self.fileURL error:&error];
    if (error!= nil) {
        DLog(@"Failed to open file %@\nError: %@", self.fileURL, error);
        return NO;
    }
    @try {
        [writeHandle writeData:fileContents];
    }
    @catch (NSException *exception) {
        DLog(@"Failed to write object to file: %@\nError: %@", self.fileURL, exception);
        return NO;
    }
    return YES;
}

-(BOOL)removeData
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    BOOL result = [fileManager removeItemAtURL:self.fileURL error:&error];
    if (error != nil) {
        DLog(@"Error occured removing file: %@\nError: %@", self.fileURL, error);
    }
    return result;
}

-(NSUInteger)size
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSDictionary *attr = [fileManager attributesOfItemAtPath:[self.fileURL path] error:&error];
    if (error != nil) {
        DLog(@"Error getting record size at %@\nError: %@", [self.fileURL path], error);
        return -1;
    }
    return [attr fileSize];
}

-(void)touch
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    [fileManager setAttributes:@{NSFileModificationDate:[NSDate date]}
                  ofItemAtPath:[self.fileURL path]
                         error:&error];
    if (error != nil) {
        DLog(@"Error occured when trying to update the last modifed date: %@", error);
    }
}

-(NSDate *)lastModified
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSDictionary *attributes = [fileManager attributesOfItemAtPath:[self.fileURL path] error:&error];
    if (error != nil) {
        DLog(@"Error occured when trying to update the last modifed date: %@", error);
        return nil;
    }
    
    return [attributes fileModificationDate];
}

-(NSInteger)version
{
    if (_version == -1) {
        [self readMetadata];
    }
    return _version;
}

#pragma mark - 
#pragma Private Methods
-(NSData *)hash
{
    if (_hash == nil) {
        [self readMetadata];
    }
    return _hash;
}

-(void)readMetadata
{
    NSError *error;
    NSFileHandle *readHandle = [NSFileHandle fileHandleForReadingFromURL:self.fileURL error:&error];
    if (error != nil) {
        DLog(@"Unable to read record at %@\nError: %@", self.fileURL, error);
        return;
    }
    
    NSData *rawVersion = [readHandle readDataOfLength:sizeof(_version)];
    [rawVersion getBytes:&_version length:sizeof(_version)];
    
    SPSecurityStore *securityStore = [SPSecurityStore defaultStore];
    [readHandle seekToFileOffset:sizeof(_version)];
    _hash = [readHandle readDataOfLength:[securityStore hashLength]];
}

@end
