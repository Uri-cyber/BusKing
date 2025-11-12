# BusAlert Assets

This directory contains all app assets including icons, images, animations, and fonts.

## Directory Structure

```
assets/
├── icons/              # App icons and launcher icons
├── images/            # Images and illustrations
├── animations/        # Lottie animations
└── fonts/            # Custom fonts (Heebo)
```

## App Icon

### Requirements
- Source file: `icons/app_icon.png` (1024x1024px)
- Foreground file: `icons/app_icon_foreground.png` (1024x1024px)
- Format: PNG with transparency

### Generating Icons

1. Place your icon files in `assets/icons/`:
   - `app_icon.png` - Main app icon (1024x1024)
   - `app_icon_foreground.png` - Adaptive icon foreground (Android 8.0+)

2. Run the icon generator:
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

This will generate:
- Android: All density variants (ldpi, mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- iOS: All required sizes (20pt to 1024pt)
- Android Adaptive Icons (API 26+)

## Splash Screen

### Requirements
- Logo file: `images/splash_logo.png` (512x512px)
- Dark logo: `images/splash_logo_dark.png` (512x512px)
- Branding: `images/splash_branding.png` (Optional, for bottom branding)
- Format: PNG with transparency

### Generating Splash Screens

1. Place your splash screen files in `assets/images/`:
   - `splash_logo.png` - Main splash logo (light mode)
   - `splash_logo_dark.png` - Dark mode splash logo
   - `splash_branding.png` - Bottom branding (optional)

2. Run the splash screen generator:
   ```bash
   flutter pub get
   flutter pub run flutter_native_splash:create
   ```

This will generate:
- Android: splash screens for all densities + Android 12 splash
- iOS: LaunchScreen.storyboard with assets
- Dark mode variants

## Image Assets

Place images in `assets/images/`:
- Onboarding illustrations
- Empty state graphics
- Feature icons
- Background patterns

Recommended formats:
- Illustrations: SVG (use flutter_svg)
- Photos: WebP or PNG
- Icons: SVG or PNG

## Animations

Place Lottie JSON files in `assets/animations/`:
- Loading animations
- Success/error states
- Feature demonstrations

Get Lottie animations from:
- https://lottiefiles.com/

## Fonts

The app uses **Heebo** font family (Google Fonts) with Hebrew support:

- `fonts/Heebo-Regular.ttf` (400)
- `fonts/Heebo-Medium.ttf` (500)
- `fonts/Heebo-Bold.ttf` (700)

Download from: https://fonts.google.com/specimen/Heebo

## Design Resources

### Colors
- Primary: #2196F3 (Blue)
- Accent: #FF9800 (Orange)
- Success: #4CAF50 (Green)
- Error: #F44336 (Red)
- Warning: #FFC107 (Amber)
- Info: #00BCD4 (Cyan)

### Icon Guidelines
- Use Material Icons for UI elements
- Custom icons should follow Material Design principles
- Maintain 8dp grid for sizing
- Use 24dp as base icon size

## Asset Optimization

### Before Committing
1. Optimize PNGs: Use tools like TinyPNG or ImageOptim
2. Optimize SVGs: Use SVGO
3. Check file sizes: Keep assets under 100KB when possible
4. Use WebP for large images

### Tools
- [TinyPNG](https://tinypng.com/) - PNG compression
- [SVGOMG](https://jakearchibald.github.io/svgomg/) - SVG optimization
- [ImageOptim](https://imageoptim.com/) - Mac image optimizer

## Updating Assets

After adding new assets:

1. Update `pubspec.yaml` if adding new directories
2. Run `flutter pub get`
3. Restart your app or use hot restart
4. For launcher icons: Run generator and rebuild
5. For splash: Run generator and rebuild

## Notes

- All assets are RTL-compatible (important for Hebrew UI)
- Icons should work in both light and dark themes
- Test splash screen on Android 12+ devices
- Verify adaptive icons on different launchers
