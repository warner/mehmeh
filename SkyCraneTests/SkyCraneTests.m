//
//  SkyCraneTests.m
//  SkyCraneTests
//
//  Created by Dan Walkowski on 11/9/12.
//  Copyright (c) 2012 Mozilla. All rights reserved.
//

#import "SkyCraneTests.h"
#import "GombotDB.h"
#import "GombotDBTest.h"


@implementation SkyCraneTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
  
    [super tearDown];
}

//- (void) testEncrypt
//{
//  //NSMutableData* payload = [NSMutableData dataWithLength:16];
//  NSData* payload = [@"646174610c0c0c0c0c0c0c0c0c0c0c0c" hexToBytes];
//  //NSData* key = [NSMutableData dataWithLength:32];
//  NSData* key = [@"b183ca20aaea6813ce6de640e72dee7e2d395a4f8e699708f2e99dfe7724ef33" hexToBytes];
//
//  //NSData* iv = [NSMutableData dataWithLength:16];
//  NSData* iv = [@"6a329494341af362581f7bf4c0577e4e " hexToBytes];
//
//  NSData* encryptedData = [payload AES256EncryptWithKey:key andIV:iv];
//  
//  NSLog(@"ENCRYPT OUTPUT: %@", encryptedData);
//}


//- (void) testDecryptWarner
//{
//  //NSMutableData* payload = [NSMutableData dataWithLength:16];
//  NSData* payload = [@"73165ae273aafb2033ec7286727f2469" hexToBytes];
//  
//  //NSData* key = [NSMutableData dataWithLength:32];
//  NSData* key = [@"b183ca20aaea6813ce6de640e72dee7e2d395a4f8e699708f2e99dfe7724ef33" hexToBytes];
//  
//  //NSData* iv = [NSMutableData dataWithLength:16];
//  NSData* iv = [@"6a329494341af362581f7bf4c0577e4e " hexToBytes];
//  
//  NSData* plaintext = [payload AES256DecryptWithKey:key andIV:iv];
//  
//  NSLog(@"DECRYPT OUTPUT: %@", plaintext);
//}
//
//
//
//- (void) testDecrypt
//{
//  [GombotDB updateCredentialsWithAccount:@"foo@example.org" andPassword:@"password"];
//  //NSData* DATA = [@"02c8c23573cc3be3cd931486b509140f549a787135a7871a752932d1dcb9496c19460c21d70545af43a8226810617f1a9728c60b378b198b679fb5026321847b" hexToBytes];
//  NSData* DATA =   [@"6a329494341af362581f7bf4c0577e4e73165ae273aafb2033ec7286727f24694b57122dc84d7832089887f6c9a9f64eca516a7324976b58a93738b956f81c20" hexToBytes];
//  
//  NSData* plain = [GombotDB decryptData:DATA withHMACKey:[GombotDB getKeyForPath:_HMACPATH] andCryptKey:[GombotDB getKeyForPath:_AESPATH]];
//  NSLog(@"raw version:  %@", plain);
//  
//  NSString *response = [[NSString alloc] initWithData:plain encoding:NSUTF8StringEncoding];
//
//  NSLog(@"string version: %@", response);
//  
//}

- (void) testDecryptWithUserInfoAndData
{
  [GombotDB updateCredentialsWithAccount:@"foo@example.org" andPassword:@"password"];
  NSData* DATA =  [@"6a329494341af362581f7bf4c0577e4e73165ae273aafb2033ec7286727f24694b57122dc84d7832089887f6c9a9f64eca516a7324976b58a93738b956f81c20" hexToBytes];
  NSData* plain = [GombotDB decryptData:DATA withHMACKey:[GombotDB getKeyForPath:_HMACPATH] andCryptKey:[GombotDB getKeyForPath:_AESPATH]];
  NSString* readable = [[NSString alloc] initWithData:plain encoding:NSUTF8StringEncoding];
  
  if (!readable || ![readable isEqualToString:@"data"])
  {
      STFail(@"testDecryptWithUserInfoAndData FAILED. Result was supposed to be 'data', but was '%@' instead.", readable);
  }

}

////TEST CODE
//- (void) testHMAC
//{
//  //timestamp \n http method \n path \n host \n port \n and extra stuff
//  NSString* input = @"1352177818\nGET\n/v1/foo\napi.gombot.org\n10\none time only please\n";
//  
//  NSData* key = [@"I0aVNap4YYwJItXT409giaxMA4K313Q+iHerYBsgtu4=" dataUsingEncoding:NSUTF8StringEncoding];
//  NSData* hmac = [GombotDB makeHMACFor:[input dataUsingEncoding:NSUTF8StringEncoding] withKey:key];
//  
//  NSLog(@"correct = 2JSJGewL+/9eoCKgf51mEbhI4cZuEVqNEeZkC3SfXp4=     computed = %@", [hmac base64EncodedString]);
//}



//- (void)testExample
//{
//    STFail(@"Unit tests are not implemented yet in SkyCraneTests");
//}
//
@end
