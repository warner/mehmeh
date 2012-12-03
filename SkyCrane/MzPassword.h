//
//  MzPassword.h
//  Quickpass
//
//  Created by Dan Walkowski on 9/24/12.
//  Copyright (c) 2012 Mozilla. All rights reserved.
//

#import <Foundation/Foundation.h>


//This is a wrapper object aroud the keychain, providing a nicer API.
// It uses the base type of kSecClassInternetPassword, but you can always ignore the fields you don't want to use.

//The keychain item for kSecClassInternetPassword uses the following fields, but only the following five are used as keys:
  //kSecAttrServer
  //kSecAttrAccount
  //kSecAttrProtocol  //I renamed this 'scheme' in my code
  //kSecAttrPort
  //kSecAttrPath

//These may be useful, but are not primary keys:
  //kSecAttrAccessible
  //kSecAttrAccessGroup
  //kSecAttrCreationDate
  //kSecAttrModificationDate
  //kSecAttrDescription
  //kSecAttrComment
  //kSecAttrCreator
  //kSecAttrType
  //kSecAttrLabel
  //kSecAttrIsInvisible
  //kSecAttrIsNegative
  //kSecAttrSecurityDomain
  //kSecAttrAuthenticationType

@class MzMatcher;

//So, as a start, I will support only the primary field keys, the password, and add any others I might need later.
@interface MzPassword : NSObject
{
  @private
  NSString* server_;
  NSString* account_;
  NSString* scheme_;
  NSNumber* port_;
  NSString* path_;
}

@property (readonly, copy) NSString* server;
@property (readonly, copy) NSString* account;
@property (readonly, copy) NSString* scheme;
@property (readonly, copy) NSNumber* port;
@property (readonly, copy) NSString* path;
@property (copy) NSString* pass;


// THESE 5 FIELDS ARE IMMUTABLE
// Server and Account must be supplied. The rest will get default values if you pass 'nil' for them.  ("http", 80, and "/")
- (id) initWithServer:(NSString*)server account:(NSString*)account scheme: (NSString*)scheme port:(NSNumber*)port path:(NSString*)path;

//You can also just get/set to <MzPassword>.pass, it is the only mutable field in the object.
- (void) setPass:(NSString *)pass;

//Save the current state of this password object to the keychain.  If the current key field values match more than one keychain item,
// it is an error.
- (BOOL) save;

//Delete the current password object from the keychain.  If the current key field values match more than one keychain item,
// it is an error.
- (NSDictionary*) discard;

//pretty print output
- (NSString*) description;

@end




//This specifies the 5 index fields to match.  Unlike actual password items above, unspecified fields remain empty, thus matching anything.
@interface MzMatcher: NSObject

@property (retain) NSMutableDictionary* query;

//Copies the 5 key fields from the item you pass in, so that if it is contucted properly, will only match the item itself.
// Used to check to see if items already exist.
+ (MzMatcher*) createFrom: (MzPassword*)item;

//Specify which fields to match by hand. Passing nil for any of these 5 leaves them blank to match any value in that field.
// Passing nil for all of them is allowed.
+ (MzMatcher*) createWithServer:(NSString*)server account:(NSString*)account scheme: (NSString*)scheme port:(NSNumber*)port path:(NSString*)path;


//enforces the existence of the 5 index fields
+ (NSMutableDictionary*) convertToKeychainItem:(MzPassword*) xpwd;

+ (MzPassword*) convertToMzPassword:(NSDictionary*)secItemDict;


//Perform the search, and return an array of MzPasswords, possibly empty
- (NSArray*) findMatching;

@end
