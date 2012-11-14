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
  int actualPin[4];
  
}

@property (strong, nonatomic) NSDictionary* plaintext; //the raw dictionary of stuff from the JSON file
@property (strong, nonatomic) NSArray* pin; //the correct pin, extracted from the json above



- (IBAction) numEnter:(id)sender;
@end

