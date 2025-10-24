# Android Production Signing Configuration
# This file contains the signing configuration for production releases

# Create a keystore for production signing
# Run this command to generate a keystore:
# keytool -genkey -v -keystore quran-app-release-key.keystore -alias quran-app-key -keyalg RSA -keysize 2048 -validity 10000

# Store these values securely:
# Keystore password: [YOUR_KEYSTORE_PASSWORD]
# Key password: [YOUR_KEY_PASSWORD]
# Key alias: quran-app-key

# Production signing configuration
android {
    signingConfigs {
        release {
            keyAlias 'quran-app-key'
            keyPassword 'YOUR_KEY_PASSWORD'
            storeFile file('quran-app-release-key.keystore')
            storePassword 'YOUR_KEYSTORE_PASSWORD'
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
