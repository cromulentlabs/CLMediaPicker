//
//  CLMockMediaItem.m
//  CLMediaPicker
//
//  Created by Greg Gardner on 12/13/24.
//

#import "CLMediaPicker.h"

@implementation CLMockMediaItem

- (instancetype)initWithTitle:(NSString *)title artist:(NSString *)artist artwork:(UIImage *)artwork {
    self = [super init];
    if (self) {
        self.title = title;
        self.artist = artist;
        self.artwork = artwork;
    }
    return self;
}

@end
