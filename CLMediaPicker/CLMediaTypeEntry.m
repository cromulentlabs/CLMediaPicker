//
//  CLMediaTypeEntry.m
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

#import "CLMediaTypeEntry.h"
#import "CLMediaPicker.h"

@implementation CLMediaTypeEntry

- (instancetype)initForMediaType:(CLMediaPickerType)mediaType {
	self = [super init];
	if (self) {
		self.mediaType = mediaType;
		switch (mediaType) {
			case CLMediaPickerAlbums:
				self.title = [CLMediaPicker localizedStringForKey:@"Albums"];
				self.icon = [UIImage systemImageNamed:@"square.stack"];
				break;
			case CLMediaPickerArtists:
				self.title = [CLMediaPicker localizedStringForKey:@"Artists"];
				self.icon = [UIImage systemImageNamed:@"music.mic"];
				break;
			case CLMediaPickerPlaylists:
				self.title = [CLMediaPicker localizedStringForKey:@"Playlists"];
				self.icon = [UIImage systemImageNamed:@"music.note.list"];
				break;
			case CLMediaPickerSongs:
				self.title = [CLMediaPicker localizedStringForKey:@"Songs"];
				self.icon = [UIImage systemImageNamed:@"music.note"];
				break;
			case CLMediaPickerPodcasts:
				self.title = [CLMediaPicker localizedStringForKey:@"Podcasts"];
				self.icon = [UIImage systemImageNamed:@"antenna.radiowaves.left.and.right"];
				break;
			case CLMediaPickerAudiobooks:
				self.title = [CLMediaPicker localizedStringForKey:@"Audiobooks"];
				self.icon = [UIImage systemImageNamed:@"book"];
				break;
			case CLMediaPickerGenre:
				self.title = [CLMediaPicker localizedStringForKey:@"Genres"];
				self.icon = [UIImage systemImageNamed:@"guitars"];
				break;
			default:
				self.title = [CLMediaPicker localizedStringForKey:@"Unknown"];
				self.icon = nil;
				break;
		}
	}
	return self;
}

@end
