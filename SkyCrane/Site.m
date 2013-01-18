//
//  Site.m
//  SkyCrane
//
//  Created by Dan Walkowski on 11/14/12.
//  Copyright (c) 2012 Mozilla. All rights reserved.
//

#import "Site.h"

@implementation Site
- (id) initWithName:(NSString*)name login:(NSString*)login url:(NSString*)url password:(NSString*)pass record:(NSDictionary *)record
{
  self = [super init];
  if (self) {
    _name = name;
    _login = login;
    _url = url;
    _pass = pass;
    _record = record;
  }
  return self;
}

- (NSString *)description {
  return [NSString stringWithFormat: @"%@\n%@\n%@\n%@\n", _name, _login, _url, _pass];
}

@end
