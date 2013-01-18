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
}

-(void) viewWillAppear:(BOOL)animated
{
  //ERASE THE DATA FILE
  [GombotDB eraseDB];
  //CLEAR THE KEYCHAIN
  [GombotDB clearKeychain];
}

- (void)working:(BOOL)isWorking
{
  if (isWorking)
  {
    _account.enabled = NO;
    _password.enabled = NO;
    _connectButton.enabled = NO;
    
    [_spinnerFrame setHidden:NO];
    [_spinner startAnimating];
  }
  else
  {
    _account.enabled = YES;
    _password.enabled = YES;
    //_connectButton.enabled = YES;
    _account.text = @"";
    _password.text = @"";
    [_spinnerFrame setHidden:YES];
    [_spinner stopAnimating];
  }
}

- (void) finished
{
  //enable the buttons and fields, and remove the spinner
  [self working:NO];
  
  @try {
    [GombotDB loadDataFile];
    [self dismissViewControllerAnimated:YES completion:^(void){}];
  }
  @catch (NSException *exception) {
    NSLog(@"%@",exception);
    [GombotDB eraseDB];
    [GombotDB clearKeychain];
  }
}

- (IBAction) connect:(id)sender
{
  [self working:YES];
  
  //get the account and password, and send it off to GombotDB to be saved in the keychain
  @try {
    [GombotDB updateCredentialsWithAccount:_account.text andPassword:_password.text];
    
    //put up spinner while we SYNCHRONOUSLY get their data, since we have no file at all.
    [GombotDB updateLocalData:(Notifier)^(BOOL success, NSString* message){
                                                                            [self finished];
                                                                        }];
  }
  @catch (NSException *exception) {
    NSLog(@"%@",exception);
    [self working:NO];
  }
  
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
