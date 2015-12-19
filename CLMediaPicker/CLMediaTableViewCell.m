//
//  CLMediaTableViewCell.m
//  CLMediaPicker
//
// Copyright [2015] [Cromulent Labs, Inc.]
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "CLMediaTableViewCell.h"

@implementation CLMediaTableViewCell

- (void)layoutSubviews {
	[super layoutSubviews];
	
	self.imageView.frame = CGRectMake(15, (self.frame.size.height - 37) / 2, 37, 37);
	self.textLabel.frame = CGRectMake(67, self.textLabel.frame.origin.y, self.textLabel.frame.size.width + MAX(0, (self.textLabel.frame.origin.x - 67)), self.textLabel.frame.size.height);
	self.detailTextLabel.frame = CGRectMake(67, self.detailTextLabel.frame.origin.y, self.detailTextLabel.frame.size.width + MAX(0, (self.detailTextLabel.frame.origin.x - 67)), self.detailTextLabel.frame.size.height);
}

@end
