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
#define _CRYPTPATH @"/crypt_key"
#define _AESPATH @"/aes_key"
#define _HMACPATH @"/hmac_key"

typedef void (^NotifyBlock)(void);

@interface GombotDB : NSObject

+ (void) updateCredentialsWithAccount:(NSString*)account andPassword:(NSString*)password;
+ (void) retrieveDataFromNetwork:(NotifyBlock)notifier;

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
