Pod::Spec.new do |s|
  s.name         = "CLMediaPicker"
  s.version      = "0.5"
  s.summary      = "Drop-in replacement for MPMediaPickerController for iOS that provides much more flexibility"
  s.description  = <<-DESC
CLMediaPicker is an open source (nearly drop-in) replacement for
MPMediaPickerController from the MediaPlayer framework in iOS. It can
be used to choose audio files (music, podcasts, audiobooks) from a
user's media library.

Advantages over MPMediaPickerController:

    1. Displays podcasts and audiobooks (unlike MPMediaPickerController in iOS 8.4+).
    2. Can be used as a modal view controller or within a UINavigationController.
    3. Colors can optionally be customized to match the rest of your app.
    4. Images can optionally be provided as replacements for Back, Done and Cancel buttons.
    5. Displays number of items chosen in title when choosing multiple items.
    6. Supports landscape and portrait.
    7. Supports subclassing for easier customization.

Similar features as MPMediaPickerController:

    1. Displays top-level audio choices for easy browsing (Artists, Albums, Songs, Playlists, etc.)
    2. Can be configured to choose only one or multiple items at once.
    3. Can filter out only audio types requested.
    4. Can filter out cloud items.
    5. Provides a + button to include all items below the current level.
    6. Provides a search bar for searching in addition to browsing.

Other features:

    1. Provides localization in 12 different languages.
                   DESC
  s.homepage     = "https://github.com/cromulentlabs/CLMediaPicker"
  s.license      = "Apache License, Version 2.0"
  s.author       = "Greg Gardner"
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/cromulentlabs/CLMediaPicker.git", :tag => "#{s.version}" }
  s.source_files = "CLMediaPicker/**/*.{h,m}", "CLMediaPicker"
  s.frameworks   = "Foundation", "UIKit", "MediaPlayer"
  s.requires_arc = true
end
