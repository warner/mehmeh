//
//  SplashViewController.h
//  SkyCrane
//
//  Created by Dan Walkowski on 11/20/12.
//  Copyright (c) 2012 Mozilla. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SplashViewController : UIViewController

@property (strong, nonatomic) NSDictionary* siteData; //the raw dictionary of stuff from the JSON file

@property (strong, nonatomic) IBOutlet UIImageView* background;
@property (strong, nonatomic) IBOutlet UIImageView* robotView;
@property (strong, nonatomic) IBOutlet UILabel* titleView;

@end
