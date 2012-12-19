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
  
  spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
              UIActivityIndicatorViewStyleWhiteLarge];
  
  [self.view addSubview:spinner];
  [spinner setFrame:CGRectMake( floorf((self.view.frame.size.width - spinner.frame.size.width) / 2.0),
                                  floorf((self.view.frame.size.height - spinner.frame.size.height) / 4.0),
                                  spinner.frame.size.width,
                                  spinner.frame.size.height)];

}

-(void) viewWillAppear:(BOOL)animated
{
  //ERASE THE DATA FILE
  [GombotDB eraseDB];
  //CLEAR THE KEYCHAIN
  [GombotDB clearKeychain];
}


- (void) finished
{
  //enable the buttons and fields, and remove the spinner
  _account.enabled = YES;
  _password.enabled = YES;
  _connectButton.enabled = YES;

  [spinner stopAnimating];
  [self dismissViewControllerAnimated:YES completion:^(void){}];
}

- (IBAction) connect:(id)sender
{
  //disable the buttons and fields, and turn on the spinner
  _account.enabled = NO;
  _password.enabled = NO;
  _connectButton.enabled = NO;
  
  [spinner startAnimating];

  //get the account and password, and send it off to GombotDB to be saved in the keychain

  [GombotDB updateCredentialsWithAccount:_account.text andPassword:_password.text];
  
  //put up spinner while we SYNCHRONOUSLY get their data, since we have no file at all.
  
  [GombotDB retrieveDataFromNetwork:^{
    [self finished];
  }];
   
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
