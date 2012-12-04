//
//  SplashViewController.m
//  SkyCrane
//
//  Created by Dan Walkowski on 11/20/12.
//  Copyright (c) 2012 Mozilla. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

#import "SplashViewController.h"
#import "PINViewController.h"
#import "GombotDB.h"

@interface SplashViewController ()

@end

@implementation SplashViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

  
  [UIView animateWithDuration:2 delay:0.0 options:UIViewAnimationCurveEaseOut animations:^{_titleView.transform =CGAffineTransformMakeScale(1.4, 1.4);} completion:^(BOOL done){}];

  [UIView animateWithDuration:8.0 delay:0.0 options:UIViewAnimationOptionRepeat|UIViewAnimationOptionCurveLinear|UIViewAnimationOptionBeginFromCurrentState animations:^{_background.transform = CGAffineTransformMakeRotation(M_PI/2);} completion:^(BOOL done){}];
  
}


-(void)viewDidAppear:(BOOL)animated
{
  @try
  {
    [GombotDB loadDataFile];
  }
  @catch (NSException *exception)
  {
    NSLog(@"%@", exception);
    [self performSelector:@selector(switchTo:) withObject:@"SplashToFetch" afterDelay:2];
    return;
  }
  
  
  //double check we have a good db
  if ([GombotDB getPin])
  {
    [self performSelector:@selector(switchTo:) withObject:@"SplashToPin" afterDelay:2];
  }
  else
  {
    [self performSelector:@selector(switchTo:) withObject:@"SplashToFetch" afterDelay:2];
  }
}

- (void) switchTo:(NSString*)segueName
{
  [self performSegueWithIdentifier: segueName sender: self];
}

//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
//{
//  if ([[segue identifier] isEqualToString:@"SplashToPin"])
//  {
//    //The GombotDB is now a singleton global, since multiple pages need access tot,
//    // so there's nothing to do here
//    
//    // Get reference to the destination view controller
//    //UINavigationController *nav = [segue destinationViewController];
//    //PINViewController *pinV = nav.viewControllers[0];
//    
//  }
//}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
