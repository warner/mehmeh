//
//  AuthViewController.m
//  SkyCrane
//
//  Created by Dan Walkowski on 11/29/12.
//  Copyright (c) 2012 Mozilla. All rights reserved.
//

#import "AuthViewController.h"
#import "GombotDB.h"


@interface AuthViewController ()

@end

@implementation AuthViewController

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
  
  //ERASE THE DATA FILE
  [GombotDB eraseDB];
  //CLEAR THE KEYCHAIN
  [GombotDB clearKeychain];
}

- (IBAction) connect:(id)sender
{
  //get the account and password, and send it off to GombotDB to be saved in the keychain

  [GombotDB updateCredentialsWithAccount:_account.text andPassword:_password.text];
  
  //put up spinner while we -synchronously get their data, since we have no file at all.
  
  
  [self dismissViewControllerAnimated:YES completion:^(void){}];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//////UITextField delegate methods

//Only enable Connect button when there is something in both text fields
- (IBAction) textChanged:(id) sender;
{
  if (_account.text.length && _password.text.length)
    _connectButton.enabled = YES;
  else
    _connectButton.enabled = NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
  [textField resignFirstResponder];

  if (textField == _account)
  {
    [_password becomeFirstResponder];
  }
  else
  {
    [_account becomeFirstResponder];

  }
  return NO;
}

@end
