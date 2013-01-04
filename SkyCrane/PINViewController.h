//
//  ViewController.h
//  SkyCrane
//
//  Created by Dan Walkowski on 11/9/12.
//  Copyright (c) 2012 Mozilla. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PINViewController : UIViewController
{
  int nextDigit;
  int pinAttempt[4]; //the current attempt at the pin
  int failedAttempts;
  
  UIButton* buttons[10];
  UIImageView* digits[4];
  UIImageView* fails[3];
  UIImage* greenon;
  UIImage* greenoff;
  UIImage* redon;
  UIImage* redoff;
}

@property IBOutlet UIButton* button0;
@property IBOutlet UIButton* button1;
@property IBOutlet UIButton* button2;
@property IBOutlet UIButton* button3;
@property IBOutlet UIButton* button4;
@property IBOutlet UIButton* button5;
@property IBOutlet UIButton* button6;
@property IBOutlet UIButton* button7;
@property IBOutlet UIButton* button8;
@property IBOutlet UIButton* button9;

@property IBOutlet UIImageView* digit0;
@property IBOutlet UIImageView* digit1;
@property IBOutlet UIImageView* digit2;
@property IBOutlet UIImageView* digit3;

@property IBOutlet UIImageView* fail0;
@property IBOutlet UIImageView* fail1;
@property IBOutlet UIImageView* fail2;


- (IBAction) numEnter:(id)sender;
@end

