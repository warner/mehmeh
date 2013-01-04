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


#define _GOMBOT_URL_TEMPORARY @"https://dl.dropbox.com/u/169445/gombotdata"                                         

//necessary for keychain
#define _HOST @"www.gombot.org"
#define _SCHEME @"https"
#define _PORT @443
#define _PATH @"/datafile"


#define _GOMBOT_URL [NSString stringWithFormat:@"%@://%@%@", _SCHEME, _HOST, _PATH]


#define DATA_FILE @"gombotdata"



static NSDictionary* private_data = nil;
static NSString* private_account = nil;
static NSMutableArray* private_sites = nil;
static NSMutableArray* private_pin = nil;

@implementation GombotDB


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
                                        andSalt:[self makeMasterSaltFrom:account]
                                      andRounds:250000];
  //NSLog(@"masterKey: %@", masterKey);

  //first, use the master key to create the auth, aes, and hmac keys
  NSData* authKey = [self makeKeyWithPassword: masterKey andSalt:[self getAuthSalt] andRounds:1];
  //NSLog(@"auth: %@", authKey);
        
  NSData* aesKey = [self makeKeyWithPassword: masterKey andSalt:[self getAesSalt] andRounds:1];
  //NSLog(@"aes: %@", aesKey);

  NSData* hmacKey = [self makeKeyWithPassword: masterKey andSalt:[self getHmacSalt] andRounds:1];
  //NSLog(@"hmac: %@", hmacKey);

  //save all three keychain items
  MzPassword* authKeychainItem = [[MzPassword alloc] initWithServer:_HOST account:account scheme: _SCHEME port:_PORT path:_AUTHPATH];
  [authKeychainItem setPass:authKey];
  [authKeychainItem save];
  
  MzPassword* aesKeychainItem = [[MzPassword alloc] initWithServer:_HOST account:account scheme: _SCHEME port:_PORT path:_AESPATH];
  [aesKeychainItem setPass:aesKey];
  [aesKeychainItem save];

  MzPassword* hmacKeychainItem = [[MzPassword alloc] initWithServer:_HOST account:account scheme: _SCHEME port:_PORT path:_HMACPATH];
  [hmacKeychainItem setPass:hmacKey];
  [hmacKeychainItem save];

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
  NSData* aesKey = [GombotDB getKeyForPath:_AESPATH];
  NSData* hmacKey = [GombotDB getKeyForPath:_HMACPATH];

  //Read file
  NSString* b64String = [GombotDB loadLocalEncryptedDataFile];

  NSData* encryptedData = [b64String base64DecodedData];

  //Decrypt file into JSON using credentials
  NSData* decryptedData = [GombotDB decryptData:encryptedData withHMACKey:hmacKey andAESKey: aesKey];

  //Parse JSON file into NSDictionary and save in private_data singleton
  NSDictionary* final = [GombotDB parseJSONdata:decryptedData];
  
  //massage the data into useful formats for display
  private_data = final;
  private_sites = [NSMutableArray array];
  
  for (NSArray* value in [[private_data objectForKey:@"logins"] allValues])
  {
    for (NSDictionary* entry in value)
    {
      Site* next = [[Site alloc] initWithName:[entry objectForKey:@"title"] login:[entry objectForKey:@"username"] url:[entry objectForKey:@"url"] password:[entry objectForKey:@"password"]];
      
      [private_sites addObject:next];
    }
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




/*email="foo@example.org", password="password", ciphertext=hex(02c8c23573cc3be3cd931486b509140f549a787135a7871a752932d1dcb9496c19460c21d70545af43a8226810617f1a9728c60b378b198b679fb5026321847b), should yield data="data"*/

/*step 1: compute HMAC on all but the last 32 bytes, compare it against the last 32 bytes, bail if mismatch
step 2: IV = first 16 bytes
step 3: decrypt (with aesKey and IV) everything in msg[16:-32]*/


+ (NSData*) decryptData: (NSData*)message withHMACKey: (NSData*)HMACkey andAESKey: (NSData*)AESKey
{
  // before anything else, check the version prefix
  NSData *versionPrefix = [@"identity.mozilla.com/gombot/v1/data:" dataUsingEncoding:NSUTF8StringEncoding];
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

  NSData* computedHMAC = [GombotDB makeHMACFor:hmacInput withKey:[GombotDB getKeyForPath:_HMACPATH]];
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
  
  NSData* plaintext = [payload AES256DecryptWithKey:[GombotDB getKeyForPath:_AESPATH] andIV:IV];

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
  //dump in-memory copies.
  private_data = nil;
  private_account = nil;
  private_sites = nil;
  private_pin = nil;
  
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

+ (NSString*) loadLocalEncryptedDataFile
{
  NSError *error = nil;
  //NSMutableData* fileData = [NSMutableData dataWithContentsOfFile:[self getDatafilePath] options:0 error:&error];

  NSString* fileData = [NSString stringWithContentsOfFile:[self getDatafilePath] encoding:NSUTF8StringEncoding error:&error];
  
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
+ (void) retrieveDataFromNetwork:(NotifyBlock)notifier
{
  //authenticate to the server, download the datafile, save it in the correct place, then decrypt/reload it, and notify the UI that
  // the data has updated.  This is done asynchronously, but synchronicity can be achieved by sending the callback necessary to
  // 'wake up' the caller
  
  id completionHandler = ^(NSHTTPURLResponse* response, NSData* data, NSError* error)
  {
    if (error)
    {
      //Handle error
      NSLog(@"Error getting file: %@", error);
    }
    else
    {
      //Get data, save to file, tell UI to update.
      //NSLog(@"Success getting file: %@", data);
      BOOL success = [[NSFileManager defaultManager] createFileAtPath:[GombotDB getDatafilePath] contents:data attributes:nil];
      if (!success) NSLog(@"failed to write new datafile");
    }
    
    notifier();
  };
  
  NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:_GOMBOT_URL_TEMPORARY] cachePolicy: NSURLCacheStorageAllowed timeoutInterval: 5.0];
  //Construct the HAWK header
  
  long timestamp = [[NSDate new] timeIntervalSince1970];
  
  //timestamp \n http method \n path \n host \n port \n and extra stuff
  NSString* hmacBody = [NSString stringWithFormat:@"%ld\nGET\n%@\n%@\n%@\n", timestamp, _PATH, _HOST, _PORT];
  //NSLog(@"hmac input= \n---------------------\n%@\n----------------------\n", hmacBody);
  
  NSData* hmac = [GombotDB makeHMACFor:[hmacBody dataUsingEncoding:NSUTF8StringEncoding] withKey:[GombotDB getKeyForPath:_AUTHPATH]];
  //NSLog(@"hmac= %@", hmac);
  
  NSString* hawkHeader = [NSString stringWithFormat:@"Hawk id=\"%@\", ts=\"%ld\", ext=\"\", mac=\"%@\"", private_account, timestamp, hmac];
  //NSLog(@"hawk header= %@", hawkHeader);
  

  [request setValue: hawkHeader forHTTPHeaderField: @"Authorization"];
  [request setValue: @"application/json" forHTTPHeaderField: @"content-type"];

  
  [request setHTTPMethod: @"GET"];
  
  NSLog(@"%@ :: %@", request, [request allHTTPHeaderFields] );
  [NSURLConnection sendAsynchronousRequest: request queue: [NSOperationQueue mainQueue] completionHandler: completionHandler];
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
