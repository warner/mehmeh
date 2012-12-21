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
  [GombotDB clearKeychain];
  [super tearDown];
}

- (void) testHMAC
{
  [GombotDB clearKeychain];
  [GombotDB updateCredentialsWithAccount:@"andré@example.org" andPassword:@"pässwörd"];

  NSData* payload = [@"646174610c0c0c0c0c0c0c0c0c0c0c0c" hexToBytes];

  NSData* key = [GombotDB getKeyForPath:_HMACPATH];
  NSData* hmac = [GombotDB makeHMACFor:payload withKey:key];

  NSData* expected = [@"a3b6dba43a051a540c0a1a186e58524f9c1008a3dac16a33bb4439794edba2a8" hexToBytes];

  if (!hmac || ![hmac isEqualToData:expected])
  {
    STFail(@"testEncrypt failed: expected '%@' but got '%@'", expected, hmac);
  }
}


- (void) testEncrypt
{
  NSData* payload = [@"646174610c0c0c0c0c0c0c0c0c0c0c0c" hexToBytes];
  NSData* key = [@"b183ca20aaea6813ce6de640e72dee7e2d395a4f8e699708f2e99dfe7724ef33" hexToBytes];
  NSData* iv = [@"6a329494341af362581f7bf4c0577e4e" hexToBytes];

  NSData* encryptedData = [payload AES256EncryptWithKey:key andIV:iv];
  NSData* expected = [@"73165ae273aafb2033ec7286727f2469dbbf3f1b65bcb898d51beff33ac15ea5" hexToBytes];
  
  if (!encryptedData || ![encryptedData isEqualToData:expected])
  {
    STFail(@"testEncrypt failed: expected '%@' but got '%@'", expected, encryptedData);
  }
}


- (void) testDecryptWithUserInfoAndData
{
  [GombotDB clearKeychain];
  [GombotDB updateCredentialsWithAccount:@"andré@example.org" andPassword:@"pässwörd"];
  NSData* payload =  [@"6964656e746974792e6d6f7a696c6c612e636f6d2f676f6d626f742f76312f646174613a53c5b62914ed1c99122433cadcff8e7fbdff3597ac495f8784adb1d41b131c72fba29cef8fbc7e082a144de102736abc1f28b6346dc1e6f3e18399610e95abbfc4e6fa529eca5f8d2b067ce215bc376d993481bf78c9490eaff7506cdf8f665577e4f4cab4b74be148f2a7e4f8af1d67611c0e501458e63858daeb8c1b6422f1d342d4406079acf39453205d2098b3531cfe4cacf86b070e544ebc7777411f0aa0dfbb373825d29c75becba162835840d5be31ab43a38909eb49ddc3eaec8a3b24199292ad9e28545208b4940f1bf735fa6fc1ae55d04abe525ce2d43dd59a2a3efb4bd16e1554b665cd1c101aca223e0481ed3e3e6089a702662d2404cf9a7a212c585122d98b20e39f9f766cf8fd203f787bb7dc7c20671c7a86880d199b346c70ad80a358656692f1c6c04c50e3df" hexToBytes];
  NSData* plain = [GombotDB decryptData:payload withHMACKey:[GombotDB getKeyForPath:_HMACPATH] andAESKey:[GombotDB getKeyForPath:_AESPATH]];
  NSString* readable = [[NSString alloc] initWithData:plain encoding:NSUTF8StringEncoding];
  
  if (!readable || ![readable isEqualToString:@"{\"logins\": {\"mozilla.com\": [{\"username\": \"gömbottest\", \"password\": \"grëën\", \"hostname\": \"mozilla.com\", \"pinLocked\": false, \"supplementalInformation\": {\"ffNumber\": \"234324\"}}]}, \"version\": \"identity.mozilla.com/gombot/v1/userData\", \"pin\": \"1234\"}"])
  {
      STFail(@"testDecryptWithUserInfoAndData FAILED. Result was supposed to be '{\"logins\": {\"mozilla.com\": [{\"username\": \"gömbottest\", \"password\": \"grëën\", \"hostname\": \"mozilla.com\", \"pinLocked\": false, \"supplementalInformation\": {\"ffNumber\": \"234324\"}}]}, \"version\": \"identity.mozilla.com/gombot/v1/userData\", \"pin\": \"1234\"}', but was '%@' instead.", readable);
  }

}




@end
