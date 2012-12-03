//
//  MzPassword.m
//  Quickpass
//
//  Created by Dan Walkowski on 9/24/12.
//  Copyright (c) 2012 Mozilla. All rights reserved.
//

#import "MzPassword.h"
#import <Security/Security.h>

@implementation MzPassword

@synthesize server = server_;
@synthesize account = account_;
@synthesize scheme = scheme_;
@synthesize port = port_;
@synthesize path = path_;
@synthesize pass;

//To simplify things, you can SEARCH for multiple items, but can only SAVE and DISCARD them individually.

//This represents an internet password keychain item. These 5 index properties are immutable.
// Server and password must be specified, the other fields will get default values if you pass 'nil' for them.  ("http", 80, and "/")
- (id) initWithServer:(NSString*)server account:(NSString*)account scheme: (NSString*)scheme port:(NSNumber*)port path:(NSString*)path
{
  if (server && account)
  {
    self = [super init];
    if (self) {
      server_ = [server copy];
      account_ = [account copy];
      scheme_ = scheme?[scheme copy]:@"http";
      port_ = port?[port copy]:@80;
      path_ = path?[path copy]:@"/";
      pass = nil;
    }
    return self;
  }
  else
  {
    NSLog(@"Error: server and account must be specified");
    return nil;
  }
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"\n server: %@\n account: %@\n scheme: %@\n port: %@\n path: %@\n pass: %@\n ",
          self.server, self.account, self.scheme, self.port, self.path, self.pass];
}




//Save this password in the keychain. It is an error if more than one item in the keychain matches.
// If a matching item already exists in the keychain, it is discarded, and this one put in its place. 
- (BOOL) save
{
  if (!self.pass)
  {
    NSLog(@"Error: password property is empty.  Unable to save");
    return FALSE;
  }
  
  NSDictionary* removedItem = [self discard];
  if (!removedItem)
  {
    NSLog(@"Error: old item unable to be removed. new data not saved");
    return FALSE;
  }
  
  //If we make it here, the keychain is clear to add ourself, one way or another.
  NSDictionary* keychainVersionOfMe = [MzMatcher convertToKeychainItem:self];
  OSStatus status = SecItemAdd((__bridge CFDictionaryRef)keychainVersionOfMe, NULL);
  
  if (status)
  {
    //We could attempt to re-install the removed item here, as a failsafe
    NSLog(@"Error: failed to save item: %li", status);
    OSStatus recoveryStatus = SecItemAdd((__bridge CFDictionaryRef)removedItem, NULL);
    if (recoveryStatus) NSLog(@"Error: failed to re-add removed item.");
    return FALSE;
  }

  NSLog(@"Success: password saved");
  return TRUE;
}



//Remove the -single- matching password. Matching more than one is an error.
// returns one of three things:
//   nil (various errors, check log)
//   empty dictionary (success, didn't find matching item to remove)
//   full dictionary (success, item found, removed, and returned with attributes and data)
- (NSDictionary*) discard
{
  if (!(self.server && self.account && self.scheme && self.port && self.path))
  {
    NSLog(@"Error: index fields not fully specified. Not removed");
    return nil;
  }
  
  //Check to see if this item exists.
  NSMutableDictionary* keychainVersionOfMe = [MzMatcher convertToKeychainItem:self];
  
  MzMatcher* stub = [MzMatcher createFrom:self];
  NSArray* matches = [stub findMatching];
  if ([matches count]> 1)
  {
    NSLog(@"Error: multiple items match. This shouldn't be possible");
    return nil;
  }
  else if ([matches count] == 1)
  {
    //delete the existing one, using the stub.
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)keychainVersionOfMe);
    if (status)
    {
      NSLog(@"Error: failed to delete item: %li", status);
      return nil;
    }
    NSLog(@"Success: password removed");
    return matches[0];
  }
  
  NSLog(@"Success: password not found, so not removed");
  return @{};
}

@end










/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//MzMatcher


//This specifies the 5 index fields to match.  Unlike  MzMatcher items above, unspecified fields remain empty, thus matching anything.
@implementation MzMatcher: NSObject

//Copies the 5 key fields from the item you pass in, so that if it is constructed properly, will only match the item itself.
// Used to check to see if items already exist.
+ (MzMatcher*) createFrom: (MzPassword*)item
{
  return [MzMatcher createWithServer:item.server account:item.account scheme:item.scheme port:item.port path:item.path];
}


//Specify which fields to match by hand. Passing nil for any of these 5 leaves them blank to match any value in that field.
// Passing nil for all of them is allowed.
+ (MzMatcher*) createWithServer:(NSString*)server account:(NSString*)account scheme: (NSString*)scheme port:(NSNumber*)port path:(NSString*)path
{
  MzMatcher* newSearch = [[MzMatcher alloc] init];
  newSearch.query = [NSMutableDictionary dictionary];
  
  //set base type of keychain item
  [newSearch.query setObject:(__bridge id)kSecClassInternetPassword forKey:(__bridge id)kSecClass];
  [newSearch.query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnAttributes];
    
  if (scheme)
  {
    if ([scheme caseInsensitiveCompare:@"http"] == NSOrderedSame)
      [newSearch.query setObject:(__bridge id)(kSecAttrProtocolHTTP) forKey:(__bridge id)kSecAttrProtocol];
    else if ([scheme caseInsensitiveCompare:@"https"] == NSOrderedSame)
      [newSearch.query setObject:(__bridge id)(kSecAttrProtocolHTTPS) forKey:(__bridge id)kSecAttrProtocol];
  }
  
  if (server)
  {
    NSData *encodedServer = [server dataUsingEncoding:NSUTF8StringEncoding];
    [newSearch.query setObject:encodedServer forKey:(__bridge id)kSecAttrServer];
  }
  
  if (port)
  {
    [newSearch.query setObject:port forKey:(__bridge id)kSecAttrPort];
  }
  
  if (path)
  {
    NSData *encodedPath = [path dataUsingEncoding:NSUTF8StringEncoding];
    [newSearch.query setObject:encodedPath forKey:(__bridge id)kSecAttrPath];
  }
  
  if (account)
  {
    NSData *encodedAccount = [account dataUsingEncoding:NSUTF8StringEncoding];
    [newSearch.query setObject:encodedAccount forKey:(__bridge id)kSecAttrAccount];
  }

  return newSearch;
}


//Tells the template to do the search, and returns an array of MzPasswords
- (NSArray*) findMatching
{  
  CFTypeRef			results = NULL;
  //turn it into a 'finding' template temporarily
  [self.query setObject:(__bridge id)kSecMatchLimitAll forKey:(__bridge id)kSecMatchLimit];
  [self.query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];

  OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)self.query, &results);
  
  //now reset it back to being usable for deleting
  [self.query removeObjectForKey:(__bridge id)kSecMatchLimit];
  [self.query removeObjectForKey:(__bridge id)kSecReturnData];
  
  //not finding anything is not an error
  if (status && status != errSecItemNotFound)
  {
    NSLog(@"Error: %ld while finding matches", status);
    return nil;
  }
  
  NSMutableArray* passes = [NSMutableArray array];
  for (NSDictionary* match in (__bridge NSArray*)results)
  {
    [passes addObject:[MzMatcher convertToMzPassword:match]];
  }
  return passes;
}

+ (MzPassword*) convertToMzPassword:(NSDictionary*)secItemDict
{
  NSString* scheme;
  NSNumber* encodedScheme = [secItemDict objectForKey:(__bridge id)kSecAttrProtocol];
  if ([encodedScheme intValue] == [(__bridge NSNumber *)kSecAttrProtocolHTTP intValue])
    scheme = @"http";
  else if ([encodedScheme intValue] == [(__bridge NSNumber *)kSecAttrProtocolHTTP intValue])
    scheme = @"https";

  NSData *encodedServer = [secItemDict objectForKey:(__bridge id)kSecAttrServer];
  NSString *server = [[NSString alloc] initWithBytes:[encodedServer bytes] length:[encodedServer length] encoding:NSUTF8StringEncoding];

  NSNumber* port = [secItemDict objectForKey:(__bridge id)kSecAttrPort];

  NSData *encodedPath = [secItemDict objectForKey:(__bridge id)kSecAttrPath];
  NSString *path = [[NSString alloc] initWithBytes:[encodedPath bytes] length:[encodedPath length] encoding:NSUTF8StringEncoding];

  NSData* encodedAccount = [secItemDict objectForKey:(__bridge id)kSecAttrAccount];
  NSString* account = [[NSString alloc] initWithBytes:[encodedAccount bytes] length:[encodedAccount length] encoding:NSUTF8StringEncoding];

  NSData* encodedPassword = [secItemDict objectForKey:(__bridge id)kSecValueData];
  NSString* password = [[NSString alloc] initWithBytes:[encodedPassword bytes] length:[encodedPassword length] encoding:NSUTF8StringEncoding];
  
  MzPassword* newItem = [[MzPassword alloc] initWithServer:server account:account scheme:scheme port:port path:path];
  newItem.pass = password;
  
  return newItem;
}


//enforces the existence of the 5 index fields. password is optional at this point, and only required before save.
+ (NSMutableDictionary*) convertToKeychainItem:(MzPassword*)xpwd
{
  NSMutableDictionary* secDict = [NSMutableDictionary dictionary];
  [secDict setObject:(__bridge id)kSecClassInternetPassword forKey:(__bridge id)kSecClass];
  
  if (xpwd.scheme)
  {
    if ([xpwd.scheme caseInsensitiveCompare:@"http"] == NSOrderedSame)
      [secDict setObject:(__bridge id)(kSecAttrProtocolHTTP) forKey:(__bridge id)kSecAttrProtocol];
    else if ([xpwd.scheme caseInsensitiveCompare:@"https"] == NSOrderedSame)
      [secDict setObject:(__bridge id)(kSecAttrProtocolHTTPS) forKey:(__bridge id)kSecAttrProtocol];
  }
  else
  {
    NSLog(@"Error: MzPassword missing scheme");
    return nil;
  }
  
  if (xpwd.server)
  {
    NSData *encodedServer = [xpwd.server dataUsingEncoding:NSUTF8StringEncoding];
    [secDict setObject:encodedServer forKey:(__bridge id)kSecAttrServer];
  }
  else
  {
    NSLog(@"Error: MzPassword missing server");
    return nil;
  }
  
  if (xpwd.port)
  {
    [secDict setObject:xpwd.port forKey:(__bridge id)kSecAttrPort];
  }
  else
  {
    NSLog(@"Error: MzPassword missing port");
    return nil;
  }
  
  if (xpwd.path)
  {
    NSData *encodedPath = [xpwd.path dataUsingEncoding:NSUTF8StringEncoding];
    [secDict setObject:encodedPath forKey:(__bridge id)kSecAttrPath];
  }
  else
  {
    NSLog(@"Error: MzPassword missing path");
    return nil;
  }
  
  
  if (xpwd.account)
  {
    NSData *encodedAccount = [xpwd.account dataUsingEncoding:NSUTF8StringEncoding];
    [secDict setObject:encodedAccount forKey:(__bridge id)kSecAttrAccount];
  }
  else
  {
    NSLog(@"Error: MzPassword missing account");
    return nil;
  }
  
  //password is optional, only required if you are saving, and it is checked there.
  if (xpwd.pass)
  {
    NSData *passwordData = [xpwd.pass dataUsingEncoding:NSUTF8StringEncoding];
    [secDict setObject:passwordData forKey:(__bridge id)kSecValueData];
  }
  
  return secDict;
}

@end

