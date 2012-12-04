//
//  GombotDB.h
//  SkyCrane
//
//  Created by Dan Walkowski on 11/27/12.
//  Copyright (c) 2012 Mozilla. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GombotDB : NSObject

+ (void) updateCredentialsWithAccount:(NSString*)account andPassword:(NSString*)password;

//ERASE THE DB
+ (void) eraseDB;
//CLEAR THE KEYCHAIN
+ (void) clearKeychain;

//throws various exceptions for finding file, reading file, decrypting file, and parsing file
+ (void) loadDataFile;

//will return nil if no data file
+ (NSString*) getPin;

//will return nil if no data file
+ (NSArray*) getSites;

@end
