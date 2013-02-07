//
//  AppDelegate.m
//  SkyCrane
//
//  Created by Dan Walkowski on 11/9/12.
//  Copyright (c) 2012 Mozilla. All rights reserved.
//

#import "AppDelegate.h"
#import "GombotDB.h"
#import "Reachability.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  // Override point for customization after application launch.
  [self configureReachability];
  [GombotDB initUpdateLock];

  NSLog(@"#### FINISHED LAUNCHING");

  return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
  [dataRefreshTimer invalidate];
  dataRefreshTimer = nil;

  NSLog(@"#### BECAME INACTIVE");

}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
  // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  NSLog(@"#### ENTERED BACKGROUND");
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
  // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  NSLog(@"#### ENTERED FOREGROUND");

}

- (void) refreshData {
  if ([GombotDB getAccount])
  {
  NSLog(@"Refresh now: %@", [NSDate date]);
    
    @try {
      [GombotDB updateLocalData: (Notifier)^(BOOL updated, NSString* errorMessage) {
        if (updated)
        {
          //send out a notification that the local data has changed on disk, so anyone who cares can refresh themselves
          [[NSNotificationCenter defaultCenter] postNotificationName:@"DataRefreshed" object:self];
        }
        
      }];
    }
    @catch (NSException *exception) {
      NSLog(@"AppDelegate.refreshdata: %@", exception);
    }
  }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  dataRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:15
                                                      target:self
                                                    selector:@selector(refreshData)
                                                    userInfo:nil
                                                     repeats:YES];

  NSLog(@"#### BECAME ACTIVE");

}

- (void)applicationWillTerminate:(UIApplication *)application
{
  // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  NSLog(@"#### TERMINATED");

}

- (void)configureReachability
{
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(reachabilityChanged:)
                                               name:kReachabilityChangedNotification
                                             object:nil];
  
  Reachability * reach = [Reachability reachabilityWithHostname:@"dev.tobmog.org"];
  
//  reach.reachableBlock = ^(Reachability * reachability)
//  {
//    dispatch_async(dispatch_get_main_queue(), ^{
//    // block to handle change to reachable state
//    });
//  };
//  
//  reach.unreachableBlock = ^(Reachability * reachability)
//  {
//    dispatch_async(dispatch_get_main_queue(), ^{
  //    // block to handle change to unreachable state
//    });
//  };
  
  [reach startNotifier];

}


//IMPLEMENT  make use of this, now that we know whether or not we can reach 
-(void)reachabilityChanged:(NSNotification*)note
{
  Reachability * reach = [note object];
  
  if([reach isReachable])
  {
    NSLog(@"Notification Says Reachable");
  }
  else
  {
    NSLog(@"Notification Says Unreachable");
  }
}


@end
