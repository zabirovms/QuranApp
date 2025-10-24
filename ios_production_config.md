# iOS Production Configuration Guide

## App Store Connect Setup
1. Create App Store Connect account
2. Create new app with bundle ID: com.example.quranapp
3. Set up App Store Connect metadata

## Code Signing Setup
1. Create Apple Developer account ($99/year)
2. Generate Distribution Certificate
3. Create App Store Provisioning Profile
4. Configure Xcode with certificates

## Bundle ID Configuration
- Bundle Identifier: com.example.quranapp
- Display Name: Қуръон бо Тафсири Осонбаён
- Version: 1.0.0
- Build: 1

## Required Capabilities
- Background Modes: Audio
- App Transport Security: Allow arbitrary loads (for API calls)

## App Store Requirements
- Privacy Policy URL: https://www.quran.tj/privacy
- Support URL: https://www.quran.tj/support
- Marketing URL: https://www.quran.tj/

## Screenshots Required
- iPhone: 6.7", 6.5", 5.5" displays
- iPad: 12.9", 11" displays
- App Preview videos (optional)

## App Store Review Guidelines
- Ensure all content is appropriate
- Test on multiple devices
- Verify all features work offline
- Check audio playback functionality
