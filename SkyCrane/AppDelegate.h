//
//  AppDelegate.h
//  SkyCrane
//
//  Created by Dan Walkowski on 11/9/12.
//  Copyright (c) 2012 Mozilla. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
  NSTimer* dataRefreshTimer;
}

@property (strong, nonatomic) UIWindow *window;

@end
