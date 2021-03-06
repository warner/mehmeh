//
//  GombotDB.h
//  SkyCrane
//
//  Created by Dan Walkowski on 11/27/12.
//  Copyright (c) 2012 Mozilla. All rights reserved.
//

#import <Foundation/Foundation.h>

//for storing fou different keys in keychain
#define _AUTHPATH @"/auth_key"
#define _AESPATH @"/aes_key"
#define _HMACPATH @"/hmac_key"

@interface GombotDB : NSObject

+ (void) updateCredentialsWithAccount:(NSString*)account andPassword:(NSString*)password;

//used by makeAuthenticatedRequestToHost call. It may not need to be exposed here, but it's handy
typedef void (^RequestCompletion)(NSInteger statusCode, NSData* body, NSError* err);

+ (void) makeAuthenticatedRequestToHost:(NSString*)host path:(NSString*)path port:(NSString*)port method:(NSString*)method body:(NSData*)body withCompletion:(RequestCompletion)externalCompletion;


//callback used by updateLocalData, telling the caller whether the data was updated, requiring a view refresh, and any error message.
typedef void (^Notifier)(BOOL updated, NSString* errorMessage);

+ (void) updateLocalData:(Notifier)ping;

//ERASE THE DB
+ (void) eraseDB;
//CLEAR THE KEYCHAIN
+ (void) clearKeychain;

//throws various exceptions for finding file, reading file, decrypting file, and parsing file
+ (void) loadDataFile;

//will return nil if no pin
+ (NSArray*) getPin;

//will return nil if no site list
+ (NSArray*) getSites;

@end


//Useful utilities exposed for other classes
@interface NSString (NSStringHexToBytes)
-(NSData*) hexToBytes ;
@end

@interface NSData (AES256)
- (NSData *)AES256DecryptWithKey:(NSData *)key andIV:(NSData*) iv;
- (NSData *)AES256EncryptWithKey:(NSData *)key andIV:(NSData*) iv;
@end
