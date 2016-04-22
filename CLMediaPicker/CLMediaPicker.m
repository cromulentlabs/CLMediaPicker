//
//  CLMediaPicker.m
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

#import "CLMediaPicker.h"
#import "CLMediaTypeEntry.h"
#import "CLMediaTableViewCell.h"
#import "UIButton+IndexPath.h"

static NSString *CLMediaPickerTableCell = @"CLMediaPickerTableCell";
static NSString *TableViewHeaderSectionIdentifier = @"TableViewHeaderSectionIdentifier";
static const CGFloat kHeaderHeight = 28;

@interface CLMediaPicker ()<UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, strong) NSMutableArray *pickedItems;
@property(nonatomic, strong) MPMediaQuery *query;
@property(nonatomic) CLMediaPickerType currentMediaType;
@property(nonatomic) BOOL topLevelView;
@property(nonatomic) BOOL useItems;
@property(nonatomic) BOOL isSearching;

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) UISearchBar *searchBar;
@property(nonatomic, strong) UIBarButtonItem *doneButton;
@property(nonatomic, strong) NSDictionary *filteredItems;
@property(nonatomic, strong) NSArray *filteredIndex;
@property(nonatomic, strong) NSArray *filteredIndexTypes;
@property(nonatomic, strong) NSArray *items;
@property(nonatomic, strong) NSArray *sectionIndex;
@property(nonatomic, strong) NSDictionary *sectionIndexDict;

@end

@implementation CLMediaPicker

@synthesize mediaTypes = mediaTypes_;

+ (NSString *)localizedStringForKey:(NSString *)key {
    static NSBundle* bundle = nil;
    if (!bundle) {
	NSString *path = [[NSBundle bundleForClass:[CLMediaPicker class]] pathForResource:@"CLMediaPickerLocalization" ofType:@"bundle"];
	bundle = [NSBundle bundleWithPath:path];
    }
    if (!bundle) {
	return key;
    }
    
    return [bundle localizedStringForKey:key value:key table:@"CLMediaPickerLocalizable"];
}


- (instancetype)init {
	self = [super init];
	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardDidHideNotification object:nil];
	}
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	[self activityStarted];

	if (!self.pickedItems) {
		self.pickedItems = [[NSMutableArray alloc] init];
	}
	
	UIBarButtonItem *backButton = nil;
	if (self.backButtonImage) {
		backButton = [self toolbarItemForImage:self.backButtonImage target:self action:@selector(backButtonAction:) accessibilityLabel:[CLMediaPicker localizedStringForKey:@"Back"]];
	}
	UIBarButtonItem *cancelButton = nil;
	if (self.cancelButtonImage) {
		cancelButton = [self toolbarItemForImage:self.cancelButtonImage target:self action:@selector(cancelButtonAction:) accessibilityLabel:[CLMediaPicker localizedStringForKey:@"Cancel"]];
	}
	else {
		cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonAction:)];
	}
	if (self.doneButtonImage) {
		self.doneButton = [self toolbarItemForImage:self.doneButtonImage target:self action:@selector(doneButtonAction:) accessibilityLabel:[CLMediaPicker localizedStringForKey:@"Done"]];
	}
	else {
		self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonAction:)];
	}
	
	if (!self.isModal && backButton) {
		self.navigationItem.leftBarButtonItem = backButton;
	}
	
	if (self.allowsPickingMultipleItems && self.isModal) {
		self.navigationItem.rightBarButtonItems = @[self.doneButton];
		self.navigationItem.leftBarButtonItems = @[cancelButton];
	}
	else if (self.allowsPickingMultipleItems) {
		self.navigationItem.rightBarButtonItems = @[self.doneButton, cancelButton];
	}
	else if (self.isModal) {
		self.navigationItem.leftBarButtonItems = @[cancelButton];
	}
	else {
		self.navigationItem.rightBarButtonItems = @[cancelButton];
	}
	
	// setup table view
	self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	if (self.tableViewCellBackgroundColor) {
		self.tableView.backgroundColor = self.tableViewCellBackgroundColor;
	}
	self.tableView.sectionIndexBackgroundColor = self.tableViewCellBackgroundColor;
	self.tableView.sectionIndexColor = self.tableViewCellTextColor;
	self.tableView.separatorColor = self.tableViewSeparatorColor;
	[self.tableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:TableViewHeaderSectionIdentifier];
	[self.tableView setTranslatesAutoresizingMaskIntoConstraints:NO];
	[self.view addSubview:self.tableView];
	self.view.backgroundColor = self.tableViewCellBackgroundColor;
	if ([self.tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]) {
		[self.tableView setCellLayoutMarginsFollowReadableWidth:NO];
	}

	[self.view addConstraints:[NSLayoutConstraint
							   constraintsWithVisualFormat:@"H:|[tableView]|"
							   options:NSLayoutFormatAlignAllCenterX
							   metrics:nil
							   views:@{@"tableView" : self.tableView}
							   ]];
	
	// set up search controller
	if (!self.query) {
		self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
		self.searchBar.tintColor = self.tableViewCellTextColor;
		self.searchBar.barTintColor = self.tableViewCellTextColor;
		self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
		self.searchBar.translucent = NO;
		self.searchBar.backgroundColor = self.tableViewCellBackgroundColor;
		self.searchBar.placeholder = [CLMediaPicker localizedStringForKey:@"Search"];
		self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
		[self.searchBar sizeToFit];
		
		self.searchBar.delegate = self;
		self.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
		[self.view addSubview:self.searchBar];
		
		[self.view addConstraints:[NSLayoutConstraint
								   constraintsWithVisualFormat:@"H:|[searchBar]|"
								   options:NSLayoutFormatAlignAllCenterX
								   metrics:nil
								   views:@{@"searchBar" : self.searchBar}
								   ]];
		
		[self.view addConstraints:[NSLayoutConstraint
								   constraintsWithVisualFormat:@"V:|[searchBar][tableView]|"
								   options:NSLayoutFormatAlignAllCenterX
								   metrics:nil
								   views:@{@"searchBar" : self.searchBar, @"tableView" : self.tableView}
								   ]];
	}
	else {
		[self.view addConstraints:[NSLayoutConstraint
								   constraintsWithVisualFormat:@"V:|[tableView]|"
								   options:NSLayoutFormatAlignAllCenterX
								   metrics:nil
								   views:@{@"tableView" : self.tableView}
								   ]];
	}
	
	[self loadItems];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self updateTitle];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)activityStarted {
	// Subclasses can override to show their own activity indicator.
}

- (void)activityEnded {
	// Subclasses can override to hide their own activity indicator.
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if (self.isSearching) {
		return self.filteredIndex.count;
	}
	else {
		return self.currentMediaType == CLMediaPickerSongs && self.topLevelView ? self.sectionIndex.count : 1;
	}
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	return self.currentMediaType == CLMediaPickerSongs && self.topLevelView ? self.sectionIndex : nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (self.isSearching) {
		NSArray *rows = self.filteredItems[self.filteredIndex[section]];
		return rows.count;
	}
	else if (self.currentMediaType == CLMediaPickerSongs && self.topLevelView) {
		NSString *key = self.sectionIndex[section];
		NSArray *indexList = [self.sectionIndexDict objectForKey:key];
		return indexList.count;
	}
	else {
		return self.items.count;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	CLMediaTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CLMediaPickerTableCell];
	if (cell == nil) {
		cell = [[CLMediaTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CLMediaPickerTableCell];
		if (self.tableViewCellBackgroundColor) {
			cell.backgroundColor = self.tableViewCellBackgroundColor;
			UIView *bgColorView = [[UIView alloc] init];
			bgColorView.backgroundColor = self.tableViewSeparatorColor;
			bgColorView.layer.masksToBounds = YES;
			cell.selectedBackgroundView = bgColorView;
		}
		if (self.tableViewCellTextColor) {
			cell.textLabel.textColor = self.tableViewCellTextColor;
		}
		if (self.tableViewCellSubtitleColor) {
			cell.detailTextLabel.textColor = self.tableViewCellSubtitleColor;
		}
		cell.imageView.contentMode = UIViewContentModeScaleToFill;
	}
	cell.detailTextLabel.text = nil;
	cell.textLabel.text = nil;
	cell.accessoryView = nil;
	
	CGSize iconSize = CGSizeMake(37, 37);

	MPMediaItemCollection *collection;
	MPMediaItem *item;
	CLMediaPickerType mediaType = self.currentMediaType;
	BOOL topLevel = NO;
	
	if (self.isSearching) {
		if (self.filteredIndex.count > indexPath.section) {
			NSString *key = self.filteredIndex[indexPath.section];
			NSArray *collections = [self.filteredItems objectForKey:key];
			if (collections.count > indexPath.row) {
				collection = collections[indexPath.row];
				item = [collection representativeItem];
				mediaType = [self.filteredIndexTypes[indexPath.section] intValue];
			}
		}
	}
	else if (self.currentMediaType == CLMediaPickerSongs && self.topLevelView) {
		if (self.sectionIndex.count > indexPath.section) {
			NSString *key = self.sectionIndex[indexPath.section];
			NSArray *secs = [self.sectionIndexDict objectForKey:key];
			if (secs.count > indexPath.row) {
				collection = secs[indexPath.row];
				item = [collection representativeItem];
			}
		}
	}
	else if (self.query) {
		if (self.useItems) {
			if (self.items.count > indexPath.row) {
				item = self.items[indexPath.row];
			}
		}
		else {
			if (self.items.count > indexPath.row) {
				collection = self.items[indexPath.row];
				item = [collection representativeItem];
			}
		}
	}
	else if (indexPath.row < self.items.count) {
		topLevel = YES;
		CLMediaTypeEntry *entry = self.items[indexPath.row];
		cell.imageView.image = entry.icon;
		cell.textLabel.text = entry.title;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	
	if (!topLevel) {
		UIImage *placeholderImage;
		switch (mediaType) {
			case CLMediaPickerArtists:
				cell.textLabel.text = item.artist ? item.artist : item.albumArtist;
				placeholderImage = [UIImage imageNamed:@"artist"];
				break;
			case CLMediaPickerAlbums:
				cell.textLabel.text = item.albumTitle;
				placeholderImage = [UIImage imageNamed:@"album"];
				cell.detailTextLabel.text = item.artist;
				break;
			case CLMediaPickerPodcasts:
				cell.textLabel.text = item.podcastTitle;
				placeholderImage = [UIImage imageNamed:@"podcast"];
				break;
			case CLMediaPickerAudiobooks:
				cell.textLabel.text = item.albumTitle;
				placeholderImage = [UIImage imageNamed:@"audiobook"];
				break;
			case CLMediaPickerPlaylists:
			{
				MPMediaPlaylist *playlist = (MPMediaPlaylist *)collection;
				cell.textLabel.text = playlist.name;
				placeholderImage = [UIImage imageNamed:@"playlist"];
				break;
			}
			case CLMediaPickerGenre:
				cell.textLabel.text = item.genre;
				placeholderImage = [UIImage imageNamed:@"genre"];
				break;
			default:
				if (item) {
					cell.textLabel.text = item.title;
					cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", item.artist, item.albumTitle];
					placeholderImage = [UIImage imageNamed:@"song"];
				}
				break;
		}
		
		if (collection && (!item.artwork || !item.artwork.bounds.size.width || !item.artwork.bounds.size.height)) {
			// try harder to find an item in the collection that has artwork
			for (MPMediaItem *testItem in collection.items) {
				if (testItem.artwork && testItem.artwork.bounds.size.width && testItem.artwork.bounds.size.height) {
					item = testItem;
					break;
				}
			}
		}
		UIImage *icon = item.artwork && item.artwork.bounds.size.width && item.artwork.bounds.size.height ? [item.artwork imageWithSize:iconSize] : placeholderImage;
		cell.imageView.image = icon;
		cell.accessoryType = mediaType == CLMediaPickerSongs ? UITableViewCellAccessoryNone : UITableViewCellAccessoryDisclosureIndicator;
	}
	
	if (self.allowsPickingMultipleItems && (self.isSearching || self.query)) {
		UIButton *addButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[addButton setImage:[UIImage imageNamed:@"add_new"] forState:UIControlStateNormal];
		[addButton setFrame:CGRectMake(7, 7, 30, 30)];
		[addButton setIndexPath:indexPath];
		[addButton addTarget:self action:@selector(addButtonAction:) forControlEvents:UIControlEventTouchUpInside];
		[addButton setAccessibilityLabel:[CLMediaPicker localizedStringForKey:@"Add All"]];
		cell.accessoryView = addButton;
	}
	
	return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return self.isSearching || (self.currentMediaType == CLMediaPickerSongs && self.topLevelView) ? kHeaderHeight : 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	return 0.01f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString *title = nil;
	if (self.isSearching) {
		if (section < self.filteredIndex.count) {
			title = self.filteredIndex[section];
		}
	}
	else if (self.currentMediaType == CLMediaPickerSongs && self.topLevelView) {
		if (section < self.sectionIndex.count) {
			title = self.sectionIndex[section];
		}
	}
	if (title) {
		UITableViewHeaderFooterView *sectionHeaderView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:TableViewHeaderSectionIdentifier];
		sectionHeaderView.contentView.backgroundColor = self.tableViewCellBackgroundColor;
		sectionHeaderView.textLabel.textColor = self.tableViewCellSubtitleColor;
		sectionHeaderView.textLabel.text = title;
		return sectionHeaderView;
	}
	return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	UIView *view = [[UIView alloc] init];
	
	return view;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	MPMediaQuery *newQuery = nil;
	CLMediaPickerType mediaType = self.currentMediaType;
	CLMediaPickerType newMediaType = CLMediaPickerArtists;
	BOOL useItems = NO;
	
	MPMediaItemCollection *collection;
	MPMediaItem *item;
	
	if (self.isSearching) {
		NSString *key = self.filteredIndex[indexPath.section];
		NSArray *collections = [self.filteredItems objectForKey:key];
		collection = collections[indexPath.row];
		item = [collection representativeItem];
		NSNumber *type = self.filteredIndexTypes[indexPath.section];
		mediaType = [type intValue];
	}
	
	if (mediaType == CLMediaPickerSongs) {
		MPMediaItemCollection *col;
		if (!self.isSearching) {
			if (self.topLevelView) {
				NSString *key = self.sectionIndex[indexPath.section];
				col = [self.sectionIndexDict objectForKey:key][indexPath.row];
			}
			else if (self.useItems) {
				col = [MPMediaItemCollection collectionWithItems:@[self.items[indexPath.row]]];
			}
			else {
				col = self.items[indexPath.row];
			}
		}
		else {
			col = collection;
		}
		[self.pickedItems addObject:col];
	}
	else if (self.query) {
		if (self.useItems) {
			item = self.items[indexPath.row];
		}
		else {
			collection = self.items[indexPath.row];
			item = [collection representativeItem];
		}
	}
	else { // top level
		CLMediaPickerType type = 1 << indexPath.row;
		newMediaType = type;
		newQuery = [self queryForType:type];
	}
	
	if (collection) {
		switch (mediaType) {
			case CLMediaPickerArtists:
				newQuery = [MPMediaQuery albumsQuery];
				[newQuery addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:@(item.artistPersistentID) forProperty:MPMediaItemPropertyArtistPersistentID]];
				newMediaType = CLMediaPickerAlbums;
				break;
			case CLMediaPickerAlbums:
				newQuery = [MPMediaQuery songsQuery];
				[newQuery addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:@(item.albumPersistentID) forProperty:MPMediaItemPropertyAlbumPersistentID]];
				newMediaType = CLMediaPickerSongs;
				break;
			case CLMediaPickerPodcasts:
				newQuery = [MPMediaQuery podcastsQuery];
				[newQuery addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:@(item.podcastPersistentID) forProperty:MPMediaItemPropertyPodcastPersistentID]];
				[newQuery setGroupingType:MPMediaGroupingTitle];
				newMediaType = CLMediaPickerSongs;
				break;
			case CLMediaPickerAudiobooks:
				newQuery = [MPMediaQuery audiobooksQuery];
				[newQuery addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:@(item.albumPersistentID) forProperty:MPMediaItemPropertyAlbumPersistentID]];
				[newQuery setGroupingType:MPMediaGroupingTitle];
				newMediaType = CLMediaPickerSongs;
				break;
			case CLMediaPickerPlaylists:
			{
				MPMediaPlaylist *playlist = (MPMediaPlaylist *)collection;
				newQuery = [MPMediaQuery playlistsQuery];
				[newQuery addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:@(playlist.persistentID) forProperty:MPMediaPlaylistPropertyPersistentID]];
				newMediaType = CLMediaPickerSongs;
				useItems = YES;
				break;
			}
			case CLMediaPickerGenre:
				newQuery = [MPMediaQuery genresQuery];
				[newQuery addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:@(item.genrePersistentID) forProperty:MPMediaItemPropertyGenrePersistentID]];
				[newQuery setGroupingType:MPMediaGroupingAlbum];
				newMediaType = CLMediaPickerAlbums;
				break;
			default:
				break;
		}
	}
	
	if (newQuery) {
		[self addPredicates:newQuery];
		CLMediaPicker *picker = [self copy];
		picker.query = newQuery;
		picker.currentMediaType = newMediaType;
		if (!self.query && !self.isSearching) {
			picker.topLevelView = YES;
		}
		picker.useItems = useItems;
		[self.navigationController pushViewController:picker animated:YES];
	}
	
	[self updateTitle];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (!self.allowsPickingMultipleItems && self.currentMediaType == CLMediaPickerSongs) {
		[self doneButtonAction:nil];
	}
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
	searchBar.showsCancelButton = YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	[searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
	if (searchText && searchText.length > 0) {
		self.isSearching = YES;
		[self updateSearchResults];
	}
	else {
		if (self.isSearching) {
			self.isSearching = NO;
			[self.tableView reloadData];
		}
	}
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
	self.isSearching = NO;
	self.searchBar.text = @"";
	[searchBar resignFirstResponder];
	searchBar.showsCancelButton = NO;
	[self.tableView reloadData];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
	CLMediaPicker *picker = [[[self class] allocWithZone:zone] init];
	picker.mediaTypes = self.mediaTypes;
	picker.delegate = self.delegate;
	picker.pickedItems = self.pickedItems;
	picker.query = [self.query copyWithZone:zone];
	picker.showsCloudItems = self.showsCloudItems;
	picker.allowsPickingMultipleItems = self.allowsPickingMultipleItems;
	picker.currentMediaType = self.currentMediaType;
	picker.backButtonImage = self.backButtonImage;
	picker.cancelButtonImage = self.cancelButtonImage;
	picker.doneButtonImage = self.doneButtonImage;
	picker.tableViewSeparatorColor = [self.tableViewSeparatorColor copyWithZone:zone];
	picker.tableViewCellBackgroundColor = [self.tableViewCellBackgroundColor copyWithZone:zone];
	picker.tableViewCellTextColor = [self.tableViewCellTextColor copyWithZone:zone];
	picker.tableViewCellSubtitleColor = [self.tableViewCellSubtitleColor copyWithZone:zone];
	return picker;
}

#pragma mark - private

- (void)loadItems {
	// set up query/items
	// this can be expensive, so do it in the background so the view can load quickly
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		if (self.query) {
			if (self.useItems) {
				self.items = [self.query items];
			}
			else {
				NSArray *collections = [self.query collections];
				self.items = collections;
			}
		}
		else {
			NSMutableArray *items = [[NSMutableArray alloc] init];
			for (int i = CLMediaPickerTypeFirst(); i <= CLMediaPickerTypeLast(); i <<= 1) {
				if (self.mediaTypes & i) {
					[items addObject:[[CLMediaTypeEntry alloc] initForMediaType:i]];
				}
			}
			self.items = items;
		}
		
		// setup sections, if needed
		BOOL outlier = NO;
		
		// Setup section index for top-level songs view
		if (self.currentMediaType == CLMediaPickerSongs && self.topLevelView) {
			NSMutableDictionary *sectionIndexDict = [[NSMutableDictionary alloc] init];
			NSMutableSet *sectionKeys = [[NSMutableSet alloc] init];
			for (MPMediaItemCollection *collection in self.items) {
				MPMediaItem *item = [collection representativeItem];
				if (item.title.length > 0) {
					NSString *firstLetter = item ? [[item.title substringToIndex:1] uppercaseString] : @"•";
					if ([[NSCharacterSet alphanumericCharacterSet] characterIsMember:[firstLetter characterAtIndex:0]]) {
						[sectionKeys addObject:firstLetter];
					}
					else {
						outlier = YES;
						firstLetter = @"•";
					}
					NSMutableArray *indexArr = [sectionIndexDict objectForKey:firstLetter];
					if (!indexArr) {
						indexArr = [[NSMutableArray alloc] init];
						[sectionIndexDict setObject:indexArr forKey:firstLetter];
					}
					[indexArr addObject:collection];
				}
			}
			
			NSMutableArray *sectionIndex = [[NSMutableArray alloc] initWithCapacity:[sectionKeys count]];
			[sectionIndex addObjectsFromArray:[[sectionKeys allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
			if (outlier) {
				[sectionIndex addObject:@"•"];
			}
			
			self.sectionIndex = sectionIndex;
			self.sectionIndexDict = sectionIndexDict;
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.tableView reloadData];
			[self activityEnded];
		});
	});
}

- (void)updateSearchResults {
	// Asynchronously load search results
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSString *searchText = self.searchBar.text;
		NSString *strippedString = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		NSArray *searchItems = nil;
		if (strippedString.length > 0) {
			searchItems = [strippedString componentsSeparatedByString:@" "];
		}
		
		NSMutableDictionary *queries = [[NSMutableDictionary alloc] init];
		for (int i = CLMediaPickerTypeFirst(); i <= CLMediaPickerTypeLast(); i <<= 1) {
			if (self.mediaTypes & i) {
				MPMediaQuery *query = [self queryForType:i];
				for (NSString *searchString in searchItems) {
					MPMediaPropertyPredicate *predicate = [MPMediaPropertyPredicate predicateWithValue:searchString forProperty:[self propertyForType:i] comparisonType:MPMediaPredicateComparisonContains];
					[query addFilterPredicate:predicate];
				}
				[queries setObject:query forKey:@(i)];
			}
		}
		
		NSMutableDictionary *results = [[NSMutableDictionary alloc] init];
		NSMutableArray *index = [[NSMutableArray alloc] init];
		NSMutableArray *indexTypes = [[NSMutableArray alloc] init];
		NSArray *keys = queries.allKeys;
		keys = [keys sortedArrayUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
			if ([obj1 intValue] > [obj2 intValue]) {
				return NSOrderedDescending;
			}
			if ([obj1 intValue] < [obj2 intValue]) {
				return NSOrderedAscending;
			}
			return NSOrderedSame;
		}];
		
		for (NSNumber *type in keys) {
			MPMediaQuery *query = [queries objectForKey:type];
			NSArray *searchResults = [query collections];
			if (searchResults.count) {
				CLMediaTypeEntry *entry = [[CLMediaTypeEntry alloc] initForMediaType:[type intValue]];
				NSString *key = [entry.title uppercaseString];
				[results setObject:searchResults forKey:key];
				[index addObject:key];
				[indexTypes addObject:type];
			}
		}
		
		self.filteredItems = results;
		self.filteredIndex = index;
		self.filteredIndexTypes = indexTypes;
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.tableView reloadData];
		});
	});
}

- (void)keyboardDidShow:(NSNotification *)notification {
	NSDictionary *userInfo = [notification userInfo];
	CGSize size = [[userInfo objectForKey: UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
	self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top, self.tableView.contentInset.left, size.height, self.tableView.contentInset.right);
}

- (void)keyboardWillHide:(NSNotification *)notification {
	self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top, self.tableView.contentInset.left, 0, self.tableView.contentInset.right);
}

- (void)backButtonAction:(id)sender {
	if (!self.query) {
		[self confirmChangesWithCompletionBlock:^{
			[self.navigationController popViewControllerAnimated:YES];
		}];
	}
	else {
		[self.navigationController popViewControllerAnimated:YES];
	}
}

- (void)cancelButtonAction:(id)sender {
	[self confirmChangesWithCompletionBlock:^{
		if ([self.delegate respondsToSelector:@selector(clMediaPickerDidCancel:)]) {
			[self.delegate performSelector:@selector(clMediaPickerDidCancel:) withObject:self];
		}
	}];
}

- (void)confirmChangesWithCompletionBlock:(void (^)(void))completionBlock {
	if (self.pickedItems.count > 0) {
		UIAlertController * actionController = [UIAlertController alertControllerWithTitle:[CLMediaPicker localizedStringForKey:@"Alert"]
																				   message:[CLMediaPicker localizedStringForKey:@"Are you sure you want to discard your changes?"]
																			preferredStyle:UIAlertControllerStyleAlert];
		
		UIAlertAction* yesButton = [UIAlertAction actionWithTitle:[CLMediaPicker localizedStringForKey:@"Yes"]
															style:UIAlertActionStyleDefault
														  handler:^(UIAlertAction * action) {
			[actionController dismissViewControllerAnimated:YES completion:nil];
			if (completionBlock) {
				completionBlock();
			}
		}];
		UIAlertAction* noButton = [UIAlertAction actionWithTitle:[CLMediaPicker localizedStringForKey:@"No"]
														   style:UIAlertActionStyleCancel
														 handler:^(UIAlertAction * action) {
			[actionController dismissViewControllerAnimated:YES completion:nil];
		}];
		[actionController addAction:yesButton];
		[actionController addAction:noButton];
		actionController.popoverPresentationController.sourceView = self.view;
		[self presentViewController:actionController animated:YES completion:nil];
	}
	else {
		if (completionBlock) {
			completionBlock();
		}
	}
}

- (void)doneButtonAction:(id)sender {
	if ([self.delegate respondsToSelector:@selector(clMediaPicker:didPickMediaItems:)]) {
		NSMutableArray *items = [[NSMutableArray alloc] init];
		for (MPMediaEntity *entity in self.pickedItems) {
			if ([entity isKindOfClass:[MPMediaItemCollection class]]) {
				MPMediaItemCollection *collection = (MPMediaItemCollection *)entity;
				[items addObjectsFromArray:collection.items];
			}
			else {
				MPMediaItem *item = (MPMediaItem *)entity;
				[items addObject:item];
			}
		}
		[self.delegate performSelector:@selector(clMediaPicker:didPickMediaItems:) withObject:self withObject:[MPMediaItemCollection collectionWithItems:items.count > 0 ? items : nil]];
	}
}

- (void)addButtonAction:(UIButton *)sender {
	NSIndexPath *indexPath = sender.indexPath;
	if (!indexPath) {
		return;
	}
	if (self.isSearching) {
		NSString *key = self.filteredIndex[indexPath.section];
		NSArray *collections = [self.filteredItems objectForKey:key];
		MPMediaItemCollection *collection = collections[indexPath.row];
		if (collection.count > 0) {
			[self.pickedItems addObject:collection];
		}
	}
	else if (self.query) {
		if (self.currentMediaType == CLMediaPickerSongs) {
			MPMediaItemCollection *col;
			if (self.topLevelView) {
				NSString *key = self.sectionIndex[indexPath.section];
				col = [self.sectionIndexDict objectForKey:key][indexPath.row];
			}
			else if (self.useItems) {
				col = [MPMediaItemCollection collectionWithItems:@[self.items[indexPath.row]]];
			}
			else {
				col = self.items[indexPath.row];
			}
			[self.pickedItems addObject:col];
		}
		else {
			MPMediaItemCollection *collection = self.items[indexPath.row];
			if ([collection isKindOfClass:[MPMediaPlaylist class]]){
				// Work around bug in MPMediaQuery where the filter predicates aren't applied on playlist items
				MPMediaPlaylist *playlist = (MPMediaPlaylist *)collection;
				MPMediaQuery *query = [MPMediaQuery playlistsQuery];
				[self addPredicates:query];
				[query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:@(playlist.persistentID) forProperty:MPMediaPlaylistPropertyPersistentID]];
				[self.pickedItems addObjectsFromArray:query.items];
			}
			else if (collection.count > 0) {
				[self.pickedItems addObject:collection];
			}
		}
	}
	else { // top level
		CLMediaTypeEntry *entry = self.items[indexPath.row];
		MPMediaQuery *query = [self queryForType:entry.mediaType];
		NSArray *collections = [query collections];
		for (MPMediaItemCollection *collection in collections) {
			if (collection.count > 0) {
				[self.pickedItems addObjectsFromArray:[query collections]];
			}
		}
	}
	[self updateTitle];
}

- (MPMediaQuery *)queryForType:(CLMediaPickerType)type {
	MPMediaQuery *query;
	switch (type) {
		case CLMediaPickerArtists:
			query = [MPMediaQuery artistsQuery];
			break;
		case CLMediaPickerAlbums:
			query = [MPMediaQuery albumsQuery];
			break;
		case CLMediaPickerPlaylists:
			query = [MPMediaQuery playlistsQuery];
			break;
		case CLMediaPickerSongs:
			query = [MPMediaQuery songsQuery];
			break;
		case CLMediaPickerPodcasts:
			query = [MPMediaQuery podcastsQuery];
			break;
		case CLMediaPickerAudiobooks:
			query = [MPMediaQuery audiobooksQuery];
			break;
		case CLMediaPickerGenre:
			query = [MPMediaQuery genresQuery];
			break;
		default:
			break;
	}
	[self addPredicates:query];
	return query;
}

- (NSString *)propertyForType:(CLMediaPickerType)type {
	switch (type) {
		case CLMediaPickerArtists:
			return MPMediaItemPropertyArtist;
		case CLMediaPickerAlbums:
			return MPMediaItemPropertyAlbumTitle;
		case CLMediaPickerPlaylists:
			return MPMediaPlaylistPropertyName;
		case CLMediaPickerPodcasts:
			return MPMediaItemPropertyPodcastTitle;
		case CLMediaPickerGenre:
			return MPMediaItemPropertyGenre;
		default:
			return MPMediaItemPropertyTitle;
	}
}

- (void)updateTitle {
	if (self.pickedItems.count == 0) {
		self.title = [CLMediaPicker localizedStringForKey:@"choose items"];
		self.doneButton.enabled = NO;
	}
	else {
		NSUInteger count = 0;
		for (MPMediaEntity *entity in self.pickedItems) {
			if ([entity isKindOfClass:[MPMediaItemCollection class]]) {
				MPMediaItemCollection *collection = (MPMediaItemCollection *)entity;
				count += collection.count;
			}
			else {
				count++;
			}
		}
		self.title = [NSString stringWithFormat:[CLMediaPicker localizedStringForKey:@"%li items"], (unsigned long)count];
		self.doneButton.enabled = YES;
	}
}

- (UIBarButtonItem *)toolbarItemForImage:(UIImage *)image target:(id)target action:(SEL)action accessibilityLabel:(NSString *)label {
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	[button setImage:image forState:UIControlStateNormal];
	[button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
	[button setFrame:CGRectMake(0, 0, 26, 26)];
	UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:button];
	item.accessibilityLabel = label;
	return item;
}

- (void)addPredicates:(MPMediaQuery *)query {
	if (!self.showsCloudItems) {
		[query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:@(0) forProperty:MPMediaItemPropertyIsCloudItem]];
	}
	[query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:@(MPMediaTypeAnyAudio) forProperty:MPMediaItemPropertyMediaType]];
}

@end
