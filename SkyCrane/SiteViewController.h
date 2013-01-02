//
//  SiteViewController.h
//  SkyCrane
//
//  Created by Dan Walkowski on 11/9/12.
//  Copyright (c) 2012 Mozilla. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SiteViewController : UITableViewController <UITableViewDataSource>

@property (retain, nonatomic) NSDictionary* rawSiteList; //dictionary keyed by url, each value is an array of entries for that url
@property (retain, nonatomic) NSMutableArray* sites;  //This is a sorted array of Site objects, which have all the fields populated.
@property (retain, nonatomic) NSArray* searchHits;  //This is a sorted, filtered array of Site objects.

@end
