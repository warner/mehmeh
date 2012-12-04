//
//  SiteViewController.h
//  SkyCrane
//
//  Created by Dan Walkowski on 11/9/12.
//  Copyright (c) 2012 Mozilla. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SiteViewController : UITableViewController <UITableViewDataSource>

@property (retain, nonatomic) NSArray* rawSiteList;  //this is the parsed blob of sites from the JSON, unsorted, and keyed by URL.
@property (retain, nonatomic) NSMutableArray* sites;  //This is a sorted array of Site objects, which have all the fields populated.
@property (retain, nonatomic) NSArray* searchHits;  //This is a sorted, filtered array of Site objects.

@end
