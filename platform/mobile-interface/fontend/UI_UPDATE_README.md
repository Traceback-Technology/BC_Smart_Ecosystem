# BC Smart UI update

## Install

1. Keep a backup of your current files outside the Flutter project.
2. Extract this archive outside the project.
3. Copy `lib` into `BC_Smart_Ecosystem\platform\mobile-interface\fontend`, replacing matching files. Include all files under `lib/shared/widgets`.
4. Replace `test/ui_responsiveness_test.dart` with this archive's version.
5. Keep your existing `pubspec.yaml`, assets, and platform folders. No dependency changes are needed.
6. In `fontend`, run:

```sh
flutter analyze
flutter test test/ui_responsiveness_test.dart
flutter run
```

The active entry point should be `fontend/lib/main.dart`. Keep backup folders such as `lib (old)` and `lib (new)` outside `fontend`, otherwise the analyzer checks their old code too.

## Transparent images to add

Save the following PNG files under `fontend/assets/images/`. This folder is already declared in the supplied pubspec. After adding images, perform a full stop and restart of the app so the asset bundle is rebuilt.

| Filename | Placement |
| --- | --- |
| `welcome_map.png` | Behind the scattered destination pins and welcome title/tagline |
| `welcome_skyline.png` | Under “Smart campus, Smart you.” on the welcome screen |
| `home_skyline.png` | Behind the Home greeting |
| `ways_illustration.png` | Inside the BC WAYS menu card, below its labels |
| `eats_illustration.png` | Inside the BC EATS menu card, below its labels |

Use transparent backgrounds. Keep text, pins, and action circles out of the images: these are rendered by Flutter so they adapt to the theme and remain readable. The welcome map fills its area and may crop at the edges; keep important artwork away from those edges. The other images use contain fitting. Choose line colours that remain visible on light and dark backgrounds.

The images are optional and are not included in this archive. Missing images leave blank decorative space instead of an error widget. Old `ways_map.png`, `eats_food.png`, and `bg_city.png` files are no longer referenced by Home. The logo uses `BC_Logo.png` in light mode and `BC_Logo_2.png` in dark mode. No backing panel is added.

## Welcome screen

- A smaller 44-pixel logo and reduced BELGIUM CAMPUS / iTversity text sit inside the top of the welcome artwork.
- Compact staggered pins retain the decorative effect without the previous large empty vertical padding. The screen does not scroll: portrait uses a compact column; landscape uses two columns. A final scale-down fit keeps all content visible on unusually small windows or with very large text, at the cost of smaller rendered controls in those extreme cases.
- Kept login icons on the left and their text on the right at every screen width. Reduced normal padding and typography; text still wraps with accessibility settings.
- Added the “Smart campus, Smart you.” slogan between divider lines and space for the skyline underneath it.
- Preserved the device-theme indicator and automatic theme selection.

## Home

- Header contains the same 48-pixel logo used on BC Ways and a notification icon, with no back arrow or BC Ways title.
- Greeting follows local device time: morning 05:00–11:59, afternoon 12:00–16:59, evening 17:00–04:59. It refreshes each minute and when the app resumes.
- BC WAYS and BC EATS stay side by side from a 280-logical-pixel screen width (240 pixels of content plus padding). Only smaller widths stack them. Larger text wraps instead of forcing a column layout.
- Greeting text and artwork occupy separate areas, with a 12-pixel gap and a maximum 45% allocation for the artwork. They cannot overlap. Menu artwork is 10% smaller; action circles retain their size.
- Card titles and subtitles are top-left. The BC WAYS circular arrow is bottom-left; the BC EATS circular restaurant icon is bottom-right. Transparent artwork appears below the labels.
- Removed Frequent Destinations.

Existing sample data (Alex, notifications, lecture, delivery) and unfinished actions remain as before. This update does not add authentication, ordering, or other backends.

## Map and navigation

- Removed the outer scrolling page around the map. The map occupies the remaining space between controls, so map gestures no longer compete with whole-page scrolling.
- Popular Destinations expands within the visible footer and reduces the map's available height. The footer is bottom-anchored so expansion reveals its cards.
- At normal sizes, controls take only the height they need. On very short screens or with large text, header/footer panels can scroll independently; the map remains in place.
- Wide layouts retain the separate map and control panel.
- Recenter now uses the actual map viewport dimensions, rather than the full screen including headers and bottom controls.
- Routing, GPS services, graph data, distance conversion, and navigation logic remain unchanged.

## Validation and limits

Completed here: Dart grammar checks for all 31 source/test files, relative-import checks, and inspection of the changed layout and asset references. Previous analyzer deprecation fixes are retained.

The updated tests cover greeting boundaries, side-by-side Home cards, optional artwork paths, removal of Frequent Destinations, map/footer expansion and gesture isolation, plus the earlier theme, search, and large-text cases. The lazily built search result and post-scroll layout fixes are retained.

Flutter is not installed in this environment. The updated tests, analyzer, device rendering, and real GPS/map interactions have not been run here. Run the commands above on your installation. Check portrait and landscape, both themes, larger text, expanding/collapsing Popular Destinations, map panning/zooming, and recentering with your real assets.

## Theme-specific logo and map assets

Keep these exact, case-sensitive paths in the existing declared asset directories:

| Theme | Logo | Campus map |
| --- | --- | --- |
| Light | `assets/images/BC_Logo.png` | `assets/bc_ways/map/campus.svg` |
| Dark | `assets/images/BC_Logo_2.png` | `assets/bc_ways/map/campus_2.svg` |

The logo has no background container or added white padding. Both map files must depict the same campus geometry with matching SVG viewBox/dimensions so the existing route and pin coordinates remain aligned. Theme changes replace only the SVG artwork, retaining the transformation controller and routing data.

Your theme-specific image/SVG files were not supplied in this turn; put your existing files at the paths above. The pubspec already declares those folders. Fully restart the app after adding assets. Replace `lib` and `test/ui_responsiveness_test.dart` from this archive. Tests now also check that both login options are visible without a scrollable and that the shared logo selects the correct asset.

## Welcome background placement

The welcome map artwork now starts at the top of the page, outside the content's SafeArea and padding. It fits the page width with top alignment. The centred content and login button sizes/padding/typography are unchanged from the previous revision. The page remains non-scrolling. No asset or pubspec changes are needed.
