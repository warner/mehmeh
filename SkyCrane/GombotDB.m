//
//  GombotDB.m
//  SkyCrane
//
//  Created by Dan Walkowski on 11/27/12.
//  Copyright (c) 2012 Mozilla. All rights reserved.
//

#import "GombotDB.h"
#import "MzPassword.h"
#import <CommonCrypto/CommonKeyDerivation.h>

#define GOMBOT_URL @"https://www.gombot.org"

#define DATA_FILE @"encryptedDB"

#define _SERVER @"www.gombot.org"
#define _SCHEME @"https"
#define _PORT @443
//replace with real path to db on server
#define _AUTHPATH @"/auth_key"
#define _CRYPTPATH @"/crypt_key"

static NSDictionary* private_data = nil;

@implementation GombotDB


+ (NSData*) getAuthSalt
{
  //for now, return fixed string
  return [@"identity.mozilla.com/gombot/v1/authentication" dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSData*) getCryptSalt
{
  //for now, return fixed string
  return [@"identity.mozilla.com/gombot/v1/encryption" dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSData*) getDerivedSalt:(NSString*)account
{
  NSString* temp = [NSString stringWithFormat: @"identity.mozilla.com/gombot/v1/derivation:%@", account];
  return [temp dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSData*) makeKeyWithPassword:(NSData*)password andSalt:(NSData*)salt andRounds:(int)rounds
{
  // How many rounds to use so that it takes 0.1s ?
//  int testRounds = CCCalibratePBKDF(kCCPBKDF2, passwordData.length, saltData.length, kCCPRFHmacAlgSHA256, 32, 100);
//  NSLog(@"testRounds: %d", testRounds);
  unsigned char key[32];
  CCKeyDerivationPBKDF(kCCPBKDF2, password.bytes, password.length, salt.bytes, salt.length, kCCPRFHmacAlgSHA256, rounds, key, 32);
  NSData* keyData = [NSData dataWithBytes:key length:32];

  return keyData;
}



+ (void) updateCredentialsWithAccount:(NSString*)account andPassword:(NSString*)password
{
  //make initial derived key
  NSData* derivedKey = [self makeKeyWithPassword: [password dataUsingEncoding:NSUTF8StringEncoding] andSalt:[self getDerivedSalt:account] andRounds:250000];
  NSLog(@"derived: %@", derivedKey);

  //first, use the password to create the auth and crypt key
  NSData* authKey = [self makeKeyWithPassword: derivedKey andSalt:[self getAuthSalt] andRounds:1];
  NSLog(@"auth: %@", authKey);
        
  NSData* cryptKey = [self makeKeyWithPassword: derivedKey andSalt:[self getCryptSalt] andRounds:1];
  NSLog(@"crypt: %@", cryptKey);

  //save both keychain items
  MzPassword* authKeychainItem = [[MzPassword alloc] initWithServer:_SERVER account:account scheme: _SCHEME port:_PORT path:_AUTHPATH];
  [authKeychainItem setPass:authKey];
  [authKeychainItem save];
  
  MzPassword* cryptKeychainItem = [[MzPassword alloc] initWithServer:_SERVER account:account scheme: _SCHEME port:_PORT path:_CRYPTPATH];
  [cryptKeychainItem setPass:cryptKey];
  [cryptKeychainItem save];

}



//This throws various exceptions for finding file, reading file, decrypting file, and parsing file.
// I think if a caller (currently SplashView and AuthView) get any of them, they need to dump the data file,
// re-auth, and try again.
+ (void)loadDataFile
{
  //Find credentials
  MzMatcher* cryptKeySearch = [MzMatcher createWithServer:_SERVER account:nil scheme:_SCHEME port:_PORT path:_CRYPTPATH];
  NSArray* keys = [cryptKeySearch findMatching];
  if ([keys count] < 1)
  {
    NSException *exception = [NSException exceptionWithName: @"CredentialException"
                                                     reason: @"no credentials found"
                                                   userInfo: nil];
    @throw exception;
  }
  NSLog(@"found credential: %@", keys);
  
  //If we don't have a file, download it.
  // this is not awesome.  I need to be doing this asynchronously, except on first launch after reset

  //Read file
  NSData* encryptedData = [GombotDB readEncrypteDataFile];

  //Decrypt file into JSON using credentials
  NSData* decryptedData = [GombotDB decryptDataFile:encryptedData withKey: keys[0]];

  //Parse JSON file into NSDictionary and save in private_data singleton
  NSDictionary* final = [GombotDB parseJSONdata:decryptedData];
  
  private_data = final;
}


//will return nil if no data file
+ (NSString*) getPin
{
  if (private_data)
  {
    return [private_data objectForKey:@"pin"];
  }
  else
  {
    return nil;
  }
}

//will return nil if no data file
+ (NSArray*) getSites
{
  if (private_data)
  {
    return [private_data objectForKey:@"passwords"];
  }
  else
  {
    return nil;
  }
}

///////////////support methods

+ (NSDictionary*) parseJSONdata: (NSData*)someJSON
{
  NSError* decodingError = nil;
  NSMutableDictionary* jsonBlob = [NSJSONSerialization JSONObjectWithData: someJSON options: NSJSONReadingMutableContainers error: &decodingError];
  
  if (decodingError != nil)
  {
    NSException *exception = [NSException exceptionWithName: @"ParseException"
                                                     reason: [decodingError description]
                                                   userInfo: nil];
    @throw exception;
  }
  
  if (jsonBlob == nil || [[jsonBlob allKeys] count] == 0)
  {
    NSException *exception = [NSException exceptionWithName: @"ParseException"
                                                     reason: @"empty data file"
                                                   userInfo: nil];
    @throw exception;
  }


  return jsonBlob;
}


////JUST RETURNS SAME DATA UNTIL DECRYPTION CODE IS AVAILABLE
+ (NSData*) decryptDataFile: (NSData*) encryptedData withKey:(NSString*) key
{
  //REPLACE THIS!!!!
  NSMutableData* plaintext= [NSMutableData dataWithData:encryptedData];
  
  //DECRYPTION CODE GOES HERE!!!!
  
//  if (/*decryptionfailure*/)
//  {
//    NSException *exception = [NSException exceptionWithName: @"DecryptionException"
//                                                     reason: /*description*/
//                                                   userInfo: nil];
//    @throw exception;
//  }

  return plaintext;
}


+ (NSString*) getDatafilePath
{
  NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [pathArray objectAtIndex:0];
  return [documentsDirectory stringByAppendingPathComponent:DATA_FILE];
}


//ERASE THE DB
+ (void) eraseDB
{
  NSError *error = nil;
  if ([[NSFileManager defaultManager] fileExistsAtPath:[self getDatafilePath]])
  {
    [[NSFileManager defaultManager] removeItemAtPath:[self getDatafilePath] error:&error];
    if (error != nil)
    {
      NSLog(@"Error deleting datafile: %@", [error description]);
    }
  }
}


//CLEAR THE KEYCHAIN
+ (void) clearKeychain
{

  MzMatcher* allPasswords = [MzMatcher createWithServer:nil account:nil scheme:nil port:nil path:nil];
  NSArray* results = [allPasswords findMatching];
  
  for(MzPassword* pwd in results)
  {
    NSDictionary* result = [pwd discard];
    NSLog(@"removed password: %@", result);
  }

}

+ (NSData*) readEncrypteDataFile
{
  NSError *error = nil;
  NSMutableData* fileData = [NSMutableData dataWithContentsOfFile:[self getDatafilePath] options:0 error:&error];

  if (error != nil)
  {
    NSException *exception = [NSException exceptionWithName: @"FileException"
                                                     reason: [error description]
                                                   userInfo: nil];
    @throw exception;
  }
  return fileData;
}


//DOWNLOAD DATAFILE
- (void) retrieveDataFile
{
  
  id completionHandler = ^(NSHTTPURLResponse* response, NSData* data, NSError* error)
  {
    if (error)
    {
      //Handle error
    }
    else
    {
      //Get data, save to file, tell UI to update.
    }
  };
  
  NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:GOMBOT_URL] cachePolicy: NSURLCacheStorageAllowed timeoutInterval: 5.0];

  [request setHTTPShouldHandleCookies: YES];
  [request setHTTPMethod: @"POST"];
//  [request setHTTPBody: [HTTP_BODY_DATA dataUsingEncoding: NSUTF8StringEncoding]];
  [request setValue: @"text/plain" forHTTPHeaderField: @"content-type"];
  
  [NSURLConnection sendAsynchronousRequest: request queue: [NSOperationQueue mainQueue]
                         completionHandler: completionHandler];
}

@end
