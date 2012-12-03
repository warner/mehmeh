//
//  GombotDB.h
//  SkyCrane
//
//  Created by Dan Walkowski on 11/27/12.
//  Copyright (c) 2012 Mozilla. All rights reserved.
//

#import <Foundation/Foundation.h>
#define SITES_FILE @"sites.json"

@interface GombotDB : NSObject

+ (void) updateCredentialWithAccount:(NSString*)account andPassword:(NSString*)password;

//throws various exceptions for finding file, reading file, decrypting file, and parsing file
+ (void) loadDataFile:(NSString*)filename;

//will return nil if no data file
+ (NSString*) getPin;

//will return nil if no data file
+ (NSArray*) getSites;

@end
