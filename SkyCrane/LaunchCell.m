//
//  LaunchCell.m
//  SkyCrane
//
//  Created by Dan Walkowski on 11/12/12.
//  Copyright (c) 2012 Mozilla. All rights reserved.
//

#import "LaunchCell.h"

@implementation LaunchCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
      [self reset];
    }
    return self;
}

- (void) reset {
  _nameLbl.text = _site.name;
  _loginLbl.text = _site.login;
  _urlLbl.text = _site.url;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
