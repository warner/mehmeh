//
//  GombotDB.m
//  SkyCrane
//
//  Created by Dan Walkowski on 11/27/12.
//  Copyright (c) 2012 Mozilla. All rights reserved.
//

#import "GombotDB.h"
#import "MzPassword.h"

#define _SERVER @"www.gombot.org"
#define _SCHEME @"https"
#define _PORT @443
#define _PATH @"/"

static NSDictionary* private_data = nil;

@implementation GombotDB

+ (void) updateCredentialWithAccount:(NSString*)account andPassword:(NSString*)password
{
  //save the keychain item
  MzPassword* cred = [[MzPassword alloc] initWithServer:_SERVER account:account scheme: _SCHEME port:_PORT path:_PATH];
  [cred setPass:password];
  [cred save];
}


//This throws various exceptions for finding file, reading file, decrypting file, and parsing file.
// I think if a caller (currently SplashView and AuthView) get any of them, they need to dump the data file,
// re-auth, and try again.
+ (void)loadDataFile:(NSString*)filename
{
  //Find credentials
  MzMatcher* search = [MzMatcher createWithServer:_SERVER account:nil scheme:_SCHEME port:_PORT path:_PATH];
  NSArray* creds = [search findMatching];
  if ([creds count] < 1)
  {
    NSException *exception = [NSException exceptionWithName: @"CredentialException"
                                                     reason: @"no credentials found"
                                                   userInfo: nil];
    @throw exception;
  }
  NSLog(@"found credential: %@", creds);
  

  //Read file
  NSData* encryptedData = [GombotDB readEncrypteDataFile:(NSString*)filename];

  //Decrypt file into JSON using credentials
  NSData* decryptedData = [GombotDB decryptDataFile:encryptedData];

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
+ (NSData*) decryptDataFile: (NSData*) encryptedData
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

+ (NSData*) readEncrypteDataFile:(NSString*)filename
{
  NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [pathArray objectAtIndex:0];
  NSString *filePath = [documentsDirectory stringByAppendingPathComponent:filename];

  NSError *error = nil;
  NSMutableData* fileData = [NSMutableData dataWithContentsOfFile:filePath options:0 error:&error];

  if (error != nil)
  {
    NSException *exception = [NSException exceptionWithName: @"FileException"
                                                     reason: [error description]
                                                   userInfo: nil];
    @throw exception;
  }
  return fileData;
}

////We need to check for, and then decrypt yhe data file while showing this screen.  Why?
//// Because it contains the PIN, which must be entered correctly on the next screen.
//// So, counter-intuitively, we decrypt the data with the password from the keychain, BEFORE the
//// user enters the correct PIN.
//- (BOOL) getSiteData
//{
//  //First, check to see if the data file exists
//  NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//  NSString *documentsDirectory = [pathArray objectAtIndex:0];
//  NSString *filePath = [documentsDirectory stringByAppendingPathComponent:SITES_FILE];
//  
//  NSError *error = nil;
//  NSMutableData* fileData = [NSMutableData dataWithContentsOfFile:filePath options:0 error:&error];
//  
//  
//  if (error != nil)
//  {
//    NSLog(@"Error loading file data: %@", [error description]);
//  }
//  else
//  {
//    NSData* decryptedData = [self decryptDataFile: fileData];
//    if (decryptedData)
//    {
//      _siteData  = [self parseJSONdata:decryptedData];
//      if (_siteData)
//      {
//        return TRUE;
//      }
//      else
//      {
//        NSLog(@"JSON parsing failed");
//        return FALSE;
//      }
//    }
//    else
//    {
//      NSLog(@"Error decrypting data file");
//    }
//  }
//  _siteData = nil;
//  return FALSE;
//}
//

@end
