//
//  DetailViewController.h
//  SkyCrane
//
//  Created by Dan Walkowski on 11/12/12.
//  Copyright (c) 2012 Mozilla. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Site.h"
@interface DetailViewController : UITableViewController

@property (nonatomic, retain) Site* site;
@end
