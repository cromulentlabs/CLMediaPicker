//
//  CLMediaPicker.h
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

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@protocol CLMediaPickerDelegate;

typedef enum {
	CLMediaPickerArtists    = 1 << 0,
	CLMediaPickerAlbums     = 1 << 1,
	CLMediaPickerPlaylists  = 1 << 2,
	CLMediaPickerSongs      = 1 << 3,
	CLMediaPickerPodcasts   = 1 << 4,
	CLMediaPickerAudiobooks = 1 << 5,
	CLMediaPickerGenre      = 1 << 6,
	CLMediaPickerAll        = 0xff
} CLMediaPickerType;

static inline CLMediaPickerType CLMediaPickerTypeFirst() { return CLMediaPickerArtists; }
static inline CLMediaPickerType CLMediaPickerTypeLast() { return CLMediaPickerGenre; }

@interface CLMediaPicker : UIViewController<NSCopying, UISearchBarDelegate>

- (instancetype)init;

@property(nonatomic) CLMediaPickerType mediaTypes;
@property(nonatomic, weak) id<CLMediaPickerDelegate> delegate;
@property(nonatomic) BOOL allowsPickingMultipleItems; // default is NO
@property(nonatomic) BOOL showsCloudItems; // default is YES
@property(nonatomic) BOOL isModal; // default is NO

@property(nonatomic, strong) UIImage *backButtonImage; // if unset, uses text-based button
@property(nonatomic, strong) UIImage *cancelButtonImage; // if unset, uses text-based button
@property(nonatomic, strong) UIImage *doneButtonImage; // if unset, uses text-based button

@property(nonatomic, strong) UIColor *tableViewSeparatorColor;
@property(nonatomic, strong) UIColor *tableViewCellBackgroundColor;
@property(nonatomic, strong) UIColor *tableViewCellTextColor;
@property(nonatomic, strong) UIColor *tableViewCellSubtitleColor;

+ (NSString *)localizedStringForKey:(NSString *)key;

- (void)activityStarted; // Subclasses can override to show their own activity indicator.
- (void)activityEnded; // Subclasses can override to hide their own activity indicator.

@end

@protocol CLMediaPickerDelegate <NSObject>
@optional

// It is the delegate's responsibility to dismiss the modal view controller on the parent view controller.

- (void)clMediaPicker:(CLMediaPicker *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection;
- (void)clMediaPickerDidCancel:(CLMediaPicker *)mediaPicker;

@end


