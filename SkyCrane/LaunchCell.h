//
//  LaunchCell.h
//  SkyCrane
//
//  Created by Dan Walkowski on 11/12/12.
//  Copyright (c) 2012 Mozilla. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Site.h"

@interface LaunchCell : UITableViewCell

@property (nonatomic, retain) IBOutlet UILabel *nameLbl;
@property (nonatomic, retain) IBOutlet UILabel *loginLbl;

@property (nonatomic, retain) Site* site;

- (void) reset;

@end
