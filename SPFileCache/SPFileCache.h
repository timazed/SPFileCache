//
//  SPFileCache.h
//  SPFileCache
//
//  Created by Timothy Zelinsky on 9/06/2015.
//  Copyright (c) 2015 zelinsky. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * An object cache for small and medium sized objects.
 *
 * This interface is agnostic of the underlying storage model.
 */
@interface SPFileCache : NSObject 

/**
 * Create a file cache at the specified path.
 *
 * @return An SPFileCache at the specified path.
 */
+ (SPFileCache*)fileCacheAtPath:(NSString *)path;

/**
 * Remove an object from the cache.
 *
 * @param objectID the opaque object ID.
 * @return YES if the object is no longer available, NO on failure.
 */
- (BOOL)removeObjectWithID:(NSData *)objectID;

/**
 * Check for the existence of an object.
 *
 * The implementation of this method must be efficient, to
 * avoid the need of a separate cache for this lookup.
 *
 * @param objectID the opaque object ID.
 * @return YES if the object exists, NO on failure or missing object.
 */
- (BOOL)containsObjectWithID:(NSData *)objectID;

/**
 * Read an object.
 *
 * This method should fail if the object has become corrupt,
 * if the contents has been tampered with by a user, or if
 * the object does not exist.
 *
 * @param objectID the opaque object ID.
 * @param error an error pointer to which a potential error will be assigned.
 * @return the object if it exists, nil otherwise..
 */
- (NSData *)objectWithID:(NSData *)objectID error:(NSError **)error;

/**
 * Insert or replace an object.
 *
 * If the object does not exist, it will be added.
 * If it already exists, it should be completely replaced.
 *
 * @param objectID the opaque object ID.
 * @param object the data to store for the object.
 * @return YES if the object was written, and NO on failure.
 */
- (BOOL)writeObject:(NSData *)object withID:(NSData *)objectID;

/**
 * Return the current size of the cache in persistent storage.
 *
 * Note that this method must not fail.
 *
 * @return the current size in bytes.
 */
- (NSUInteger)size;

/**
 * Set the maximum size of the cache in persistent storage.
 *
 * This method guarantees the cache is no larger than maxSize upon
 * return.
 *
 * @param maxSize the maximum size in bytes.
 */
- (void)setMaxSize:(NSUInteger)maxSize;

@end
