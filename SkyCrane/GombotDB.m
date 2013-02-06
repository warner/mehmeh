//
//  GombotDB.m
//  SkyCrane
//
//  Created by Dan Walkowski on 11/27/12.
//  Copyright (c) 2012 Mozilla. All rights reserved.
//

#import "GombotDB.h"
#import "MzPassword.h"
#import "Site.h"
#import <CommonCrypto/CommonKeyDerivation.h>
#import "NSData+Base64.h"
#import "NSString+Base64.h"


//#define _GOMBOT_URL_TEMPORARY @"https://dl.dropbox.com/u/169445/gombotdata"

//necessary for keychain
#ifdef DEVSERVER
#define _HOST @"dev.tobmog.org"
#define _SCHEME @"http"
#define _PORTSTRING @"80"
#define _PORT @80
#define _TIMESTAMP_PATH @"/api/v1/payload/timestamp"
#define _PAYLOAD_PATH @"/api/v1/payload"
#else
#define _HOST @"gombot.org"
#define _SCHEME @"https"
#define _PORTSTRING @"443"
#define _PORT @443
#define _TIMESTAMP_PATH @"/api/v1/payload/timestamp"
#define _PAYLOAD_PATH @"/api/v1/payload"
#endif


#define LOCAL_DATA_FILE @"gombotdata"

#define VERSION_PREFIX_1 @"identity.mozilla.com/gombot/v1/data:"


static NSDictionary* private_data = nil;
static NSString* private_account = nil;
static NSMutableArray* private_sites = nil;
static NSInteger private_timestamp = 0;
static NSMutableArray* private_pin = nil;

static UIBackgroundTaskIdentifier backgroundUpdateTask;
static NSLock *updateLock;

@implementation GombotDB

+ (void) initUpdateLock
{
  updateLock = [[NSLock alloc] init];
}

//Fearing that the salts for these keys may become generated in the future, I have put them in functions here
+ (NSData*) makeMasterSaltFrom:(NSString*)userAccount
{
    NSString* temp = [NSString stringWithFormat: @"identity.mozilla.com/gombot/v1/master:%@", userAccount];
    return [temp dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSData*) makeMasterSecretFrom:(NSString*)secretInfo andPassword:(NSString*)userPassword
{
    NSString* temp = [NSString stringWithFormat: @"%@:%@", secretInfo, userPassword];
    return [temp dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSData*) getAuthSalt
{
  //for now, return fixed string
  return [@"identity.mozilla.com/gombot/v1/authentication" dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSData*) getAesSalt
{
  //for now, return fixed string
  return [@"identity.mozilla.com/gombot/v1/data/AES" dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSData*) getHmacSalt
{
  //for now, return fixed string
  return [@"identity.mozilla.com/gombot/v1/data/HMAC" dataUsingEncoding:NSUTF8StringEncoding];
}


+ (NSData*) makeKeyWithPassword:(NSData*)password andSalt:(NSData*)salt andRounds:(int)rounds
{
  unsigned char key[32];
  CCKeyDerivationPBKDF(kCCPBKDF2, password.bytes, password.length, salt.bytes, salt.length, kCCPRFHmacAlgSHA256, rounds, key, 32);
  NSData* keyData = [NSData dataWithBytes:key length:32];

  return keyData;
}



+ (void) updateCredentialsWithAccount:(NSString*)account andPassword:(NSString*)password
{
  //save the account info (email)
  private_account = account;
  
  //make initial derived master key
  NSData* masterKey = [self makeKeyWithPassword: [self makeMasterSecretFrom:@"" andPassword:password]
                                        andSalt:[self makeMasterSaltFrom:private_account]
                                      andRounds:250000];

  //first, use the master key to create the auth, aes, and hmac keys
  NSData* authKey = [self makeKeyWithPassword: masterKey andSalt:[self getAuthSalt] andRounds:1];
  //NSLog(@"auth: %@", authKey);
        
  NSData* aesKey = [self makeKeyWithPassword: masterKey andSalt:[self getAesSalt] andRounds:1];
  //NSLog(@"aes: %@", aesKey);

  NSData* hmacKey = [self makeKeyWithPassword: masterKey andSalt:[self getHmacSalt] andRounds:1];
  //NSLog(@"hmac: %@", hmacKey);

  //save all three keychain items
  MzPassword* authKeychainItem = [[MzPassword alloc] initWithServer:_HOST account:private_account scheme: _SCHEME port:_PORT path:_AUTHPATH];
  [authKeychainItem setPass:authKey];
  [authKeychainItem save];
  
  MzPassword* aesKeychainItem = [[MzPassword alloc] initWithServer:_HOST account:private_account scheme: _SCHEME port:_PORT path:_AESPATH];
  [aesKeychainItem setPass:aesKey];
  [aesKeychainItem save];

  MzPassword* hmacKeychainItem = [[MzPassword alloc] initWithServer:_HOST account:private_account scheme: _SCHEME port:_PORT path:_HMACPATH];
  [hmacKeychainItem setPass:hmacKey];
  [hmacKeychainItem save];

}

+ (NSString*) getAccount
{
  MzMatcher* keySearch = [MzMatcher createWithServer:_HOST account:nil scheme:_SCHEME port:_PORT path:_AUTHPATH];
  NSArray* keys = [keySearch findMatching];
  if ([keys count] != 1 || !keys[0])
  {
    NSException *exception = [NSException exceptionWithName: @"CredentialException"
                                                     reason: [NSString stringWithFormat:@"Unable to load account name"]
                                                   userInfo: nil];
    @throw exception;
  }
  
  MzPassword* key = keys[0];
  return key.account;
}


+ (NSData*) getKeyForPath:(NSString*)keyPath
{
  MzMatcher* keySearch = [MzMatcher createWithServer:_HOST account:nil scheme:_SCHEME port:_PORT path:keyPath];
  NSArray* keys = [keySearch findMatching];
  if ([keys count] != 1 || !keys[0])
  {
    NSException *exception = [NSException exceptionWithName: @"CredentialException"
                                                     reason: [NSString stringWithFormat:@"no key found for path: %@", keyPath]
                                                   userInfo: nil];
    @throw exception;
  }
  
  MzPassword* key = keys[0];
  return key.pass;
}


//This throws various exceptions for finding file, reading file, decrypting file, and parsing file.
// I think if a caller (currently SplashView and AuthView) get any of them, they need to dump the data file,
// re-auth, and try again.
+ (void)loadDataFile
{
  //Find neccessary keys
  NSData* aesKey = [self getKeyForPath:_AESPATH];
  NSData* hmacKey = [self getKeyForPath:_HMACPATH];

  //Read file, which is actually JSON
  
  NSData* fileData = [self loadLocalEncryptedDataFile];
  NSDictionary* fileDict = [self parseJSONdata:fileData];
  NSString* payload = [fileDict objectForKey:@"payload"];
  
  NSData* encryptedData = [payload base64DecodedData];

  //Decrypt file into JSON using credentials
  NSData* decryptedData = [self decryptData:encryptedData withHMACKey:hmacKey andAESKey: aesKey];

  //Parse JSON file into NSDictionary and save in private_data singleton
  NSDictionary* final = [self parseJSONdata:decryptedData];
  
  //massage the data into useful formats for display
  private_account = [self getAccount];
  private_data = final;
  private_sites = [NSMutableArray array];
  
  for (NSDictionary* site_entry in [private_data objectForKey:@"logins"])
  {
    Site* next = [[Site alloc] initWithName:[site_entry objectForKey:@"title"] login:[site_entry objectForKey:@"username"] url:[site_entry objectForKey:@"loginurl"] password:[site_entry objectForKey:@"password"] record:site_entry];
      
      [private_sites addObject:next];
  }
  //Sort the results
  NSSortDescriptor *nameSort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
  NSSortDescriptor *loginSort = [NSSortDescriptor sortDescriptorWithKey:@"login" ascending:YES];
  
  [private_sites sortUsingDescriptors:@[nameSort, loginSort]];

  //pins are 4 digits long
  private_pin = [NSMutableArray arrayWithCapacity:4];
  NSString* pinStr = [private_data objectForKey:@"pin"];
  
  for (int j=0; j<4; j++)
  {
    private_pin[j] = [NSNumber numberWithInt:[[pinStr substringWithRange:NSMakeRange(j, 1)] intValue]];
  }
  private_timestamp = [[fileDict objectForKey:@"updated"] integerValue];
}


//will return nil if no data file
+ (NSArray*) getPin
{
  if (private_data)
  {
    return private_pin;
  }
  else
  {
    return nil;
  }
}

//will return nil if no data file
+ (NSArray*) getSites
{
  if (private_sites)
  {
    return private_sites;
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
                                                     reason: @"Encrypted data file is empty"
                                                   userInfo: nil];
    @throw exception;
  }

  return jsonBlob;
}




+ (NSData*) encryptData: (NSData*)message withHMACKey: (NSData*)HMACkey andAESKey: (NSData*)AESKey
{
  // before anything else, check the version prefix
  NSData *versionPrefix = [VERSION_PREFIX_1 dataUsingEncoding:NSUTF8StringEncoding];
  
  NSMutableData* outputBuffer = [NSMutableData dataWithData:versionPrefix];
  
  //FIX! correct IV calculation!!
  NSData* IV = [@"0000000000000000" dataUsingEncoding:NSUTF8StringEncoding];
  [outputBuffer appendData:IV];
  NSData* ciphertext = [message AES256EncryptWithKey:AESKey andIV:IV];
  [outputBuffer appendData:ciphertext];
  
  NSData* computedHMAC = [self makeHMACFor:outputBuffer withKey:HMACkey];
  NSLog(@"computed hmac: %@", computedHMAC);
  
  [outputBuffer appendData:computedHMAC];
    
  return outputBuffer;
}




/*email="foo@example.org", password="password", ciphertext=hex(02c8c23573cc3be3cd931486b509140f549a787135a7871a752932d1dcb9496c19460c21d70545af43a8226810617f1a9728c60b378b198b679fb5026321847b), should yield data="data"*/

/*step 1: compute HMAC on all but the last 32 bytes, compare it against the last 32 bytes, bail if mismatch
step 2: IV = first 16 bytes
step 3: decrypt (with aesKey and IV) everything in msg[16:-32]*/


+ (NSData*) decryptData: (NSData*)message withHMACKey: (NSData*)HMACkey andAESKey: (NSData*)AESKey
{
  // before anything else, check the version prefix
  NSData *versionPrefix = [VERSION_PREFIX_1 dataUsingEncoding:NSUTF8StringEncoding];
  NSUInteger verlen = [versionPrefix length];
  NSData *gotPrefix = [message subdataWithRange:NSMakeRange(0, verlen)];
  if (![gotPrefix isEqualToData:versionPrefix]) {
    NSLog(@"unrecognized version prefix '%@'", gotPrefix);
    NSException *exception = [NSException exceptionWithName:@"DecryptException"
                                                     reason:@"unrecognized version prefix"
                                                   userInfo:nil];
    @throw exception;
  }

  //First, compute hmac of everything except the last 32 bytes
  NSData* hmacInput = [message subdataWithRange:NSMakeRange(0, [message length]-32)];
  //NSLog(@"hmac input (iv+enc): %@", hmacInput);
  
  NSData* hmacValue = [message subdataWithRange:NSMakeRange([message length]-32, 32)];
  //NSLog(@"message hmac: %@", hmacValue);

  NSData* computedHMAC = [self makeHMACFor:hmacInput withKey:HMACkey];
  //NSLog(@"computed hmac: %@", computedHMAC);
  // TODO: use constant-time comparison here, to avoid a timing attack
  if (![computedHMAC isEqualToData:hmacValue]) {
    NSLog(@"invalid HMAC: encrypted data is corrupt");
    NSException *exception = [NSException exceptionWithName:@"DecryptException"
                                                     reason:@"invalid HMAC"
                                                   userInfo:nil];
    @throw exception;
  }

  // remove the version prefix after the MAC check but before decryption

  //Second, extract the IV and payload, and decrypt
  NSData* IV = [message subdataWithRange:NSMakeRange(verlen, 16)];
  //NSLog(@"message IV: %@", IV);

  NSData* payload = [message subdataWithRange:NSMakeRange(verlen+16, [message length]-verlen-16-32)];
  //NSLog(@"message payload: %@", payload);
  
  NSData* plaintext = [payload AES256DecryptWithKey:AESKey andIV:IV];

  return plaintext;
}


+ (NSString*) getDatafilePath
{
  NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [pathArray objectAtIndex:0];
  return [documentsDirectory stringByAppendingPathComponent:LOCAL_DATA_FILE];
}


//ERASE THE DB
+ (void) eraseDB
{
  NSError *error = nil;
  //dump in-memory copies.
  private_data = nil;
  private_account = nil;
  private_sites = nil;
  private_pin = nil;
  private_timestamp = 0;
  
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
    if (!result) NSLog(@"failed to remove password");
  }

}

+ (NSData*) loadLocalEncryptedDataFile
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


//Send HAWK authenticated requests

//ASYNCH  NO LONGER USED!

//typedef void (^RequestCompletion)(NSInteger statusCode, NSData* body, NSError* err);

//+ (void) makeAuthenticatedRequestToHost:(NSString*)host path:(NSString*)path port:(NSString*)port method:(NSString*)method body:(NSData*)body withCompletion:(RequestCompletion)externalCompletion
//{
//  //what time is it?
//  long timestamp = [[NSDate new] timeIntervalSince1970];
//
//  //carefully assemble the bytes that are used to create the MAC. NOTE the extra empty line at the end!
//  NSString* hmacInput = [NSString stringWithFormat:@"%ld\n%@\n%@\n%@\n%@\n\n", timestamp, method, path, host, port];
//
//  //generate the MAC for this string
//  NSData* hmacOutput = [self makeHMACFor:[hmacInput dataUsingEncoding:NSUTF8StringEncoding] withKey:[self getKeyForPath:_AUTHPATH]];
//
//  //create the request
//  NSURL* requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@:%@%@", _SCHEME, host, port, path]];
//  NSMutableURLRequest* hawkRequest = [[NSMutableURLRequest alloc] initWithURL: requestURL cachePolicy: NSURLCacheStorageNotAllowed timeoutInterval: 5.0];
//
//  //create the hawk auth header
//  NSString* hawkHeader = [NSString stringWithFormat:@"Hawk id=\"%@\", ts=\"%ld\", ext=\"\", mac=\"%@\"", private_account, timestamp, [hmacOutput base64EncodedString]];
//
//  [hawkRequest setValue: hawkHeader forHTTPHeaderField: @"Authorization"];
//  [hawkRequest setValue: @"application/json" forHTTPHeaderField: @"content-type"];
//  [hawkRequest setHTTPMethod: method];
//  
//  if ([method isEqualToString:@"PUT"] && body != nil)
//  {
//    [hawkRequest setHTTPBody: body];
//  }
//  
//  //get ready to send it, by creating a block to handle the callbacks
//  id internalHandler = ^(NSHTTPURLResponse* response, NSData* data, NSError* error)
//  {
//    if (error || [response statusCode] != 200)
//    {
//      NSLog(@"request error. response code: %d  error: %@", [response statusCode], error);
//      externalCompletion([response statusCode], nil, error);
//    }
//    else
//    {
//      NSLog(@"request success");
//      externalCompletion([response statusCode], data, error);
//    }
//  };
//
//  NSString* bodyString = [[NSString alloc] initWithData:[hawkRequest HTTPBody] encoding:NSUTF8StringEncoding];
//  
//  NSLog(@"Request: %@\n %@\n %@\n %@", [hawkRequest HTTPMethod], hawkRequest, [hawkRequest allHTTPHeaderFields], bodyString );
//  [NSURLConnection sendAsynchronousRequest: hawkRequest queue: [NSOperationQueue mainQueue] completionHandler: internalHandler];
//
//}


+ (NSData*) makeSynchronousAuthenticatedRequestToHost:(NSString*)host path:(NSString*)path port:(NSString*)port method:(NSString*)method body:(NSData*)sendBody returningResponse:(NSURLResponse **)response error:(NSError **)error
{
  //what time is it?
  long timestamp = [[NSDate new] timeIntervalSince1970];
  
  //carefully assemble the bytes that are used to create the MAC. NOTE the extra empty line at the end!
  NSString* hmacInput = [NSString stringWithFormat:@"%ld\n%@\n%@\n%@\n%@\n\n", timestamp, method, path, host, port];
  
  //generate the MAC for this string
  NSData* hmacOutput = [self makeHMACFor:[hmacInput dataUsingEncoding:NSUTF8StringEncoding] withKey:[self getKeyForPath:_AUTHPATH]];
  
  //create the request
  NSURL* requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@:%@%@", _SCHEME, host, port, path]];
  NSMutableURLRequest* hawkRequest = [[NSMutableURLRequest alloc] initWithURL: requestURL cachePolicy: NSURLCacheStorageNotAllowed timeoutInterval: 5.0];
  
  //create the hawk auth header
  NSString* hawkHeader = [NSString stringWithFormat:@"Hawk id=\"%@\", ts=\"%ld\", ext=\"\", mac=\"%@\"", private_account, timestamp, [hmacOutput base64EncodedString]];
  
  [hawkRequest setValue: hawkHeader forHTTPHeaderField: @"Authorization"];
  [hawkRequest setValue: @"application/json" forHTTPHeaderField: @"content-type"];
  [hawkRequest setHTTPMethod: method];
  
  if ([method isEqualToString:@"PUT"] && sendBody != nil)
  {
    [hawkRequest setHTTPBody: sendBody];
  }
    
  NSString* bodyString = [[NSString alloc] initWithData:[hawkRequest HTTPBody] encoding:NSUTF8StringEncoding];
  
  NSLog(@"Request: %@\n %@\n %@\n %@", [hawkRequest HTTPMethod], hawkRequest, [hawkRequest allHTTPHeaderFields], bodyString);
  NSData* responseData = [NSURLConnection sendSynchronousRequest:hawkRequest returningResponse:response error:error];

  return responseData;
}



// boolean tells you whether the data was updated, requiring a UI refresh, and userMessage != nil indicates an error, and should be displayed to the user
+ (void) updateLocalData:(Notifier)ping
{
  //PREVENT more than one thread running through here at a time
  if ([updateLock tryLock]) {

    NSLog(@"Checking data freshness");
    //check for connectivity
    
    [self beginBackgroundUpdateTask];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      
      
      NSString* userMessage = nil;
      BOOL needsUpdate = NO;
      BOOL wasUpdated = NO;

      
      /////////////////////////////////////////////////////////////////////////////////
      //make the timestamp check to see if data on server is newer
      NSHTTPURLResponse* tsResponse;
      NSError*       tsError;
      NSData*       tsResponseBody = [self makeSynchronousAuthenticatedRequestToHost:_HOST path:_TIMESTAMP_PATH port:_PORTSTRING method:@"GET" body:nil returningResponse:&tsResponse error:&tsError];
      
      //if not fresh
      if ([tsResponse statusCode] == 200)
      {
        NSDictionary* timestampBlob = [self parseJSONdata:tsResponseBody];
        long serverDate = [[timestampBlob objectForKey:@"updated"] integerValue];
        
        if (private_timestamp < serverDate)
        {
          NSLog(@"Data is stale, needs update");
          needsUpdate = YES;
        }
        else
        {
          NSLog(@"data is fresh");
        }
      }
      else
      {
        //data was not updated, with error
        //why does auth failure return 13?
        NSLog(@"error checking data freshness: %d", [tsResponse statusCode]);
        
        if ([tsResponse statusCode] == 13) {
          userMessage = @"Incorrect Account or Password";
        }
        else
        {
          userMessage = [NSString stringWithFormat: @"Server returned code: %d (timestamp)", [tsResponse statusCode]];
        }
      }
      
      /////////////////////////////////////////////////////////////////////////////////

      if (needsUpdate)
      {
        NSHTTPURLResponse* payloadResponse;
        NSError*       payloadError;
        NSData*        payloadResponseBody = [self makeSynchronousAuthenticatedRequestToHost:_HOST path:_PAYLOAD_PATH port:_PORTSTRING method:@"GET" body:nil returningResponse:&payloadResponse error:&payloadError];
        
        if ([payloadResponse statusCode] == 200)
        {
          BOOL success = [[NSFileManager defaultManager] createFileAtPath:[self getDatafilePath] contents:payloadResponseBody attributes:nil];
          if (success)
          {
            wasUpdated = YES;
          }
          else
          {
            NSLog(@"failed to write new datafile");
            userMessage = @"Unable to create local database file.";
          }
        }
        else
        {
          //data was not updated, with error
          //why does auth failure return 13?
          if ([payloadResponse statusCode] == 13) {
            userMessage = @"Incorrect Account or Password";
          }
          else
          {
            userMessage = [NSString stringWithFormat: @"Server returned code: %d (payload)", [payloadResponse statusCode]];
          }
        }
      }
      
      //Tell the UI to update if necessary
      [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        ping(wasUpdated, userMessage);
      }];
      
      [self endBackgroundUpdateTask];

      
    });
    
    [updateLock unlock];

  }
  else
  {
    NSLog(@"updateLock not available. different thread already updating data");
  }
  
}



+ (void) beginBackgroundUpdateTask
{
  backgroundUpdateTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
    [self endBackgroundUpdateTask];
  }];
}

+ (void) endBackgroundUpdateTask
{
  [[UIApplication sharedApplication] endBackgroundTask: backgroundUpdateTask];
  backgroundUpdateTask = UIBackgroundTaskInvalid;
}






+ (NSData*) makeHMACFor:(NSData*)payload withKey:(NSData*)key
{
  unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
  CCHmac(kCCHmacAlgSHA256, [key bytes], [key length], [payload bytes], [payload length], cHMAC);
  return [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
}



@end




@implementation NSString (NSStringHexToBytes)
-(NSData*) hexToBytes {
  NSMutableData* data = [NSMutableData data];
  int idx;
  for (idx = 0; idx+2 <= self.length; idx+=2) {
    NSRange range = NSMakeRange(idx, 2);
    NSString* hexStr = [self substringWithRange:range];
    NSScanner* scanner = [NSScanner scannerWithString:hexStr];
    unsigned int intValue;
    [scanner scanHexInt:&intValue];
    [data appendBytes:&intValue length:1];
  }
  return data;
}
@end

#import <CommonCrypto/CommonCryptor.h>

@implementation NSData (AES256)

- (NSData *)AES256EncryptWithKey:(NSData *)key andIV:(NSData*) iv {
	// 'key' should be 32 bytes for AES256, will be null-padded otherwise
		
	//See the doc: For block ciphers, the output size will always be less than or
	//equal to the input size plus the size of one block.
	//That's why we need to add the size of one block here
  NSMutableData* encryptBuffer = [NSMutableData dataWithLength:[self length] + kCCBlockSizeAES128];
	
	size_t numBytesEncrypted = 0;
	CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                        [key bytes], kCCKeySizeAES256,
                                        [iv bytes] /* initialization vector */,
                                        [self bytes], [self length], /* input */
                                        [encryptBuffer mutableBytes], [encryptBuffer length], /* output */
                                        &numBytesEncrypted);
	if (cryptStatus == kCCSuccess) {
    [encryptBuffer setLength:numBytesEncrypted];
    return encryptBuffer;
	}
  
	return nil;
}


- (NSData *)AES256DecryptWithKey:(NSData *)key andIV:(NSData*) iv {
	// 'key' should be 32 bytes for AES256, will be null-padded otherwise
		
	//See the doc: For block ciphers, the output size will always be less than or
	//equal to the input size plus the size of one block.
	//That's why we need to add the size of one block here
  NSMutableData* decryptBuffer = [NSMutableData dataWithLength:[self length] + kCCBlockSizeAES128];
	
	size_t numBytesDecrypted = 0;
	CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                        [key bytes], kCCKeySizeAES256,
                                        [iv bytes] /* initialization vector */,
                                        [self bytes], [self length], /* input */
                                        [decryptBuffer mutableBytes], [decryptBuffer length], /* output */
                                        &numBytesDecrypted);
	
	if (cryptStatus == kCCSuccess) {
    [decryptBuffer setLength:numBytesDecrypted];
    return decryptBuffer;
	}
  
  return nil;
}

@end
