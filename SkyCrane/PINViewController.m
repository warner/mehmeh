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

- (void) unlock
{
  pinAttempt[0] = pinAttempt[1] = pinAttempt[2] = pinAttempt[3] = nextDigit = failedAttempts = 0;
  for (int i=0; i<4; i++) [digits[i] setHidden:YES];
  for (int j=0; j<3; j++) [fails[j] setHidden:YES];
  [self enableKeypad:TRUE];
  [self performSegueWithIdentifier: @"Unlock" sender: self];
}

- (void) eraseData
{
  pinAttempt[0] = pinAttempt[1] = pinAttempt[2] = pinAttempt[3] = nextDigit = failedAttempts = 0;
  for (int i=0; i<4; i++) [digits[i] setHidden:YES];
  NSLog(@"ERASING DATA");
  [self enableKeypad:TRUE];
  [self performSegueWithIdentifier: @"PinToFetch" sender: self];
}

- (void) blinkAndClear
{
  pinAttempt[0] = pinAttempt[1] = pinAttempt[2] = pinAttempt[3] = nextDigit = 0;
  for (int i=0; i<4; i++) [digits[i] setHidden:YES];
  [self enableKeypad:TRUE];
}

- (void) enableKeypad:(BOOL) enable
{
  for (int i=0; i<9; i++)
 {
   buttons[i].enabled = enable;
 }
}

- (IBAction) numEnter:(id) sender;
{
  NSString* buttonString = ((UIButton*)sender).titleLabel.text;
  int value = [buttonString intValue];
  pinAttempt[nextDigit] = value;
  [digits[nextDigit] setHidden:NO];
  nextDigit++;

  if (nextDigit == 4)  //check for correctness
  {
    [self enableKeypad: FALSE];
    
    if ((pinAttempt[0] == actualPin[0]) &&
        (pinAttempt[1] == actualPin[1]) &&
        (pinAttempt[2] == actualPin[2]) &&
        (pinAttempt[3] == actualPin[3]) )
    {
      //Success! Go to the Site list
      [self performSelector:@selector(unlock) withObject:nil afterDelay:0.35];
    }
    else
    {
      //fail!
      [fails[failedAttempts] setHidden:NO];
      failedAttempts++;

      if (failedAttempts >2)
      {
        [self performSelector:@selector(eraseData) withObject:nil afterDelay:0.35];
      }
      else
      {
        [self performSelector:@selector(blinkAndClear) withObject:nil afterDelay:0.35];
      }
    }
  }
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  //this bit is tedious, but IBObjectCollections do not preserve the order you put things into them. >:
  buttons[0] = _button0;
  buttons[1] = _button1;
  buttons[2] = _button2;
  buttons[3] = _button3;
  buttons[4] = _button4;
  buttons[5] = _button5;
  buttons[6] = _button6;
  buttons[7] = _button7;
  buttons[8] = _button8;

  digits[0] = _digit0;
  digits[1] = _digit1;
  digits[2] = _digit2;
  digits[3] = _digit3;
  
  fails[0] = _fail0;
  fails[1] = _fail1;
  fails[2] = _fail2;


	// Do any additional setup after loading the view, typically from a nib.
  pinAttempt[0] = pinAttempt[1] = pinAttempt[2] = pinAttempt[3] = nextDigit = 0;
  failedAttempts = 0;
    
  NSString* pinStr = [_plaintext objectForKey:@"pin"];
  
  for (int j=0; j<4; j++)
  {
    actualPin[j] = [[pinStr substringWithRange:NSMakeRange(j, 1)] intValue];
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
    siteTable.rawSiteList =  [_plaintext objectForKey:@"passwords"];
  }
}

@end
