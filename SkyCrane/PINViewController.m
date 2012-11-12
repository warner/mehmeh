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

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
  // Let's read the contents of the file of passwords!  whee!
  NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [pathArray objectAtIndex:0];
  NSString *filePath = [documentsDirectory stringByAppendingPathComponent:SITES_FILE];
  
  NSError *error = nil;
  NSMutableData* fileData = [NSMutableData dataWithContentsOfFile:filePath];
  
  if (error != nil) {
    NSLog(@"There was an error: %@", [error description]);
  } else {
    
   _plaintext  = [self parseJSONdata:fileData];    
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
