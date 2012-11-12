//
//  SiteViewController.h
//  SkyCrane
//
//  Created by Dan Walkowski on 11/9/12.
//  Copyright (c) 2012 Mozilla. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SiteViewController : UITableViewController <UITableViewDataSource>

@property (strong, nonatomic) NSDictionary* sites;
@property (strong, nonatomic) NSArray* sortedKeys;
@end
