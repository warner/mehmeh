//
//  ViewController.m
//  SkyCrane
//
//  Created by Dan Walkowski on 11/9/12.
//  Copyright (c) 2012 Mozilla. All rights reserved.
//

#import "PINViewController.h"
#import "SiteViewController.h"

#define SITES_FILE @"sites.json"

@interface PINViewController ()

@end

@implementation PINViewController

- (IBAction) numEnter:(id) sender;
{
  NSString* buttonString = ((UIButton*)sender).titleLabel.text;
  int value = [buttonString intValue];
  pinAttempt[nextDigit] = value;
  nextDigit++;
  
  if (nextDigit == 4)  //check for correctness
  {
    if ((pinAttempt[0] == actualPin[0]) &&
        (pinAttempt[1] == actualPin[1]) &&
        (pinAttempt[2] == actualPin[2]) &&
        (pinAttempt[3] == actualPin[3]) )
    {
      //success!
      pinAttempt[0] = pinAttempt[1] = pinAttempt[2] = pinAttempt[3] = nextDigit = 0;
      //initiate the segue
      NSLog(@"CORRECT!");
      [self performSegueWithIdentifier: @"Unlock" sender: self];

    }
    else
    {
      //fail!
      pinAttempt[0] = pinAttempt[1] = pinAttempt[2] = pinAttempt[3] = nextDigit = 0;
      failedAttempts++;
      NSLog(@"failed attempts: %i", failedAttempts);
    }
  }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
  pinAttempt[0] = pinAttempt[1] = pinAttempt[2] = pinAttempt[3] = nextDigit = 0;
  failedAttempts = 0;

  // Let's read the file of passwords!  whee!
  NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [pathArray objectAtIndex:0];
  NSString *filePath = [documentsDirectory stringByAppendingPathComponent:SITES_FILE];
  
  NSError *error = nil;
  NSMutableData* fileData = [NSMutableData dataWithContentsOfFile:filePath];
  
  if (error != nil) {
    NSLog(@"There was an error: %@", [error description]);
  } else {
    
   _plaintext  = [self parseJSONdata:fileData];
    NSString* pinStr = [_plaintext objectForKey:@"pin"];
    
    for (int j=0; j<4; j++)
    {
      actualPin[j] = [[pinStr substringWithRange:NSMakeRange(j, 1)] intValue];
//      NSLog(@"PIN digit %i = %i", j, actualPin[j]);
    }
  }

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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if ([[segue identifier] isEqualToString:@"Unlock"]) {
    SiteViewController* siteTable = (SiteViewController*)[segue destinationViewController];
    siteTable.sites =  [_plaintext objectForKey:@"passwords"];
  }
}

@end
