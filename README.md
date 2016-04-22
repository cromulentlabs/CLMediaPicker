# CLMediaPicker

CLMediaPicker is an open source (nearly drop-in) replacement for 
MPMediaPickerController from the MediaPlayer framework in iOS. It can 
be used to choose audio files (music, podcasts, audiobooks) from a 
user's media library.

## Comparison to MPMediaPickerController

### Advantages over MPMediaPickerController

    1. Displays podcasts and audiobooks (unlike MPMediaPickerController in iOS 8.4+).
    2. Can be used as a modal view controller or within a UINavigationController.
    3. Colors can optionally be customized to match the rest of your app.
    4. Images can optionally be provided as replacements for Back, Done and Cancel buttons.
    5. Displays number of items chosen in title when choosing multiple items.
    6. Supports landscape and portrait.
    7. Supports subclassing for easier customization.

### Similar features as MPMediaPickerController

    1. Displays top-level audio choices for easy browsing (Artists, Albums, Songs, Playlists, etc.)
    2. Can be configured to choose only one or multiple items at once.
    3. Can filter out only audio types requested.
    4. Can filter out cloud items.
    5. Provides a + button to include all items below the current level.
    6. Provides a search bar for searching in addition to browsing.

### Other features

    1. Provides localization in 12 different languages.

## Installation

### CocoaPods

CLMediaPicker is available on CocoaPods and can be install by adding
```
pod 'CLMediaPicker'
```
to your pod file.

### Manually

Alternatively, you can just copy the CLMediaPicker sub-directory into
your project and make sure to include the MediaPlayer framework.

## Example

Step 1: Include header

if using cocoapods:

```
#import <CLMediaPicker/CLMediaPicker.h>
```

or if installed manually:

```
#import "CLMediaPicker.h"
```

Step 2: Mark your class as implementing CLMediaPickerDelegate protocol

```
@interface ViewController : UIViewController<CLMediaPickerDelegate>
```

Step 3: Set up delegate

```
#pragma mark - CLMediaPickerDelegate

- (void)clMediaPicker:(CLMediaPicker *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    if (mediaItemCollection)
    {
	// Do what you want with the collection
    }
}

- (void)clMediaPickerDidCancel:(CLMediaPicker *)mediaPicker
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

```

Step 4: Instantiate and show view controller

```
CLMediaPicker *picker = [[CLMediaPicker alloc] init];
picker.mediaTypes = CLMediaPickerAll;
picker.delegate = self;
picker.allowsPickingMultipleItems = YES;
picker.showsCloudItems = NO;
[self.navigationController pushViewController:picker animated:YES];
```

or if you want to display it modally:

```
CLMediaPicker *picker = [[CLMediaPicker alloc] init];
picker.mediaTypes = CLMediaPickerAll;
picker.delegate = self;
picker.allowsPickingMultipleItems = YES;
picker.showsCloudItems = NO;
picker.isModal = YES;
UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:picker];
[self presentViewController:navController animated:YES completion:nil];
```

