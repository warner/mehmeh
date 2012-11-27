//
//  GombotDB.m
//  SkyCrane
//
//  Created by Dan Walkowski on 11/27/12.
//  Copyright (c) 2012 Mozilla. All rights reserved.
//

#import "GombotDB.h"

@implementation GombotDB


//- (NSDictionary*) parseJSONdata: (NSData*)someJSON
//{
//  NSError* decodingError = nil;
//  NSMutableDictionary* jsonBlob = [NSJSONSerialization JSONObjectWithData: someJSON options: NSJSONReadingMutableContainers error: &decodingError];
//  if (decodingError)
//  {
//    NSLog(@"ERROR parsing json: %@", decodingError );
//    return nil;
//  }
//  else
//  {
//    return jsonBlob;
//  }
//}
//
////JUST RETURNS SAME DATA UNTIL DECRYPTION CODE IS AVAILABLE
//- (NSData*) decryptDataFile: (NSData*) encryptedData
//{
//  //REPLACE THIS!!!!
//  NSMutableData* plaintext= [NSMutableData dataWithData:encryptedData];
//  
//  //DECRYPTION CODE GOES HERE!!!!
//  
//  return plaintext;
//}
//
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
