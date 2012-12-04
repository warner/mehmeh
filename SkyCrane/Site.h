//
//  Site.h
//  SkyCrane
//
//  Created by Dan Walkowski on 11/14/12.
//  Copyright (c) 2012 Mozilla. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Site : NSObject
@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) NSString* login;
@property (strong, nonatomic) NSString* url;
@property (strong, nonatomic) NSString* pass;
@property BOOL prot;

- (id) initWithName:(NSString*)name login:(NSString*)login url:(NSString*)url password:(NSString*)pass;
- (NSString *)description;
@end
