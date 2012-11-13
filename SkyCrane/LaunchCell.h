//
//  LaunchCell.h
//  SkyCrane
//
//  Created by Dan Walkowski on 11/12/12.
//  Copyright (c) 2012 Mozilla. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LaunchCell : UITableViewCell

@property (nonatomic, retain) IBOutlet UILabel *nameLbl;
@property (nonatomic, retain) IBOutlet UILabel *loginLbl;
@property (nonatomic, retain) IBOutlet UILabel *urlLbl;

@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* login;
@property (nonatomic, retain) NSString* url;
@property (nonatomic, retain) NSString* pass;

@end
