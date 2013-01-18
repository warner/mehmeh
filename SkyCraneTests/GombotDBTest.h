//
//  GombotDBTest.h
//  SkyCrane
//
//  Created by Dan Walkowski on 11/27/12.
//  Copyright (c) 2012 Mozilla. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSData+Base64.h"
#import "NSString+Base64.h"

@interface GombotDB (Testing)

+ (NSData*) encryptData: (NSData*)message withHMACKey: (NSData*)HMACkey andAESKey: (NSData*)AESKey;
+ (NSData*) decryptData: (NSData*)encryptedData withHMACKey: (NSData*)HMACkey andAESKey: (NSData*)cryptKey;
+ (NSData*) getKeyForPath:(NSString*)keyPath;
+ (NSData*) makeHMACFor:(NSData*)payload withKey:(NSData*)key;
@end
