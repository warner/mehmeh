//
//  AuthViewController.h
//  SkyCrane
//
//  Created by Dan Walkowski on 11/29/12.
//  Copyright (c) 2012 Mozilla. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AuthViewController : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField* account;
@property (strong, nonatomic) IBOutlet UITextField* password;
@property (strong, nonatomic) IBOutlet UIButton* connectButton;

- (IBAction) connect:(id)sender;
- (IBAction) textChanged:(id) sender;

@end
