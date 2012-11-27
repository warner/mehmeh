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

#define SITES_FILE @"sites.json"

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

- (NSDictionary*) parseJSONdata: (NSData*)someJSON
{
  NSError* decodingError = nil;
  NSMutableDictionary* jsonBlob = [NSJSONSerialization JSONObjectWithData: someJSON options: NSJSONReadingMutableContainers error: &decodingError];
  if (decodingError)
  {
    NSLog(@"ERROR parsing json: %@", decodingError );
    return nil;
  }
  else
  {
    return jsonBlob;
  }
}

//JUST RETURNS SAME DATA UNTIL DECRYPTION CODE IS AVAILABLE
- (NSData*) decryptDataFile: (NSData*) encryptedData
{
  //REPLACE THIS!!!!
  NSMutableData* plaintext= [NSMutableData dataWithData:encryptedData];
  
  //DECRYPTION CODE GOES HERE!!!!
  
  return plaintext;
}

//We need to check for, and then decrypt yhe data file while showing this screen.  Why?
// Because it contains the PIN, which must be entered correctly on the next screen.
// So, counter-intuitively, we decrypt the data with the password from the keychain, BEFORE the
// user enters the correct PIN.
- (BOOL) getSiteData
{
  //First, check to see if the data file exists
  NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [pathArray objectAtIndex:0];
  NSString *filePath = [documentsDirectory stringByAppendingPathComponent:SITES_FILE];
  
  NSError *error = nil;
  NSMutableData* fileData = [NSMutableData dataWithContentsOfFile:filePath options:0 error:&error];

  
  if (error != nil)
  {
    NSLog(@"Error loading file data: %@", [error description]);
  }
  else
  {
    NSData* decryptedData = [self decryptDataFile: fileData];
    if (decryptedData)
    {
      _siteData  = [self parseJSONdata:decryptedData];
      if (_siteData)
      {
        return TRUE;
      }
      else
      {
        NSLog(@"JSON parsing failed");
        return FALSE;
      }
    }
    else
    {
      NSLog(@"Error decrypting data file");
    }
  }
  _siteData = nil;
  return FALSE;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

  
  [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionAutoreverse|UIViewAnimationOptionRepeat animations:^{_titleView.transform =CGAffineTransformMakeScale(1.25, 1.25);} completion:^(BOOL done){}];

  [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionAutoreverse|UIViewAnimationOptionRepeat animations:^{_robotView.transform = CGAffineTransformMakeRotation(M_PI/12);} completion:^(BOOL done){}];
  
  BOOL hasDataFile = [self getSiteData];
  
  if (hasDataFile)
  {
    [self performSelector:@selector(switchTo:) withObject:@"SplashToPin" afterDelay:1.4];
  }
  else
  {
    [self performSelector:@selector(switchTo:) withObject:@"SplashToFetch" afterDelay:1.4];
  }
}

- (void) switchTo:(NSString*)segueName
{
  [self performSegueWithIdentifier: segueName sender: self];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if ([[segue identifier] isEqualToString:@"SplashToPin"])
  {
    // Get reference to the destination view controller
    UINavigationController *nav = [segue destinationViewController];
    PINViewController *pinV = nav.viewControllers[0];
    
    // Pass the data to the next view controller here
    [pinV setPlaintext:_siteData];
  }
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



//experiment i tried using CATextLyer
//  CATextLayer *titleLayer = [CATextLayer layer];
//
//  titleLayer.bounds = CGRectMake(0.0f, 0.0f, 320.0f, 120.0f);
//  titleLayer.string = @"GomBot!";
//  titleLayer.font = (__bridge CFTypeRef)([UIFont boldSystemFontOfSize:100].fontName);
//  titleLayer.foregroundColor = [UIColor purpleColor].CGColor;
//  titleLayer.position = CGPointMake(200.0, 80.0f);
//  titleLayer.wrapped = NO;
//
//  [self.view.layer addSublayer:titleLayer];
@end
