//
//  GombotDBTest.h
//  SkyCrane
//
//  Created by Dan Walkowski on 11/27/12.
//  Copyright (c) 2012 Mozilla. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GombotDB (Testing)

+ (NSData*) decryptData: (NSData*)encryptedData withHMACKey: (NSData*)HMACkey andCryptKey: (NSData*)cryptKey;
+ (NSData*) getKeyForPath:(NSString*)keyPath;

@end
