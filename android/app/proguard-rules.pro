# ProGuard rules for Quran App - Optimized for size reduction
# Add project specific ProGuard rules here.

# Keep Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep Quran app specific classes
-keep class com.quran.tj.quranapp.** { *; }

# Keep audio service classes
-keep class androidx.media.** { *; }

# Keep ExoPlayer classes used by just_audio (fixes playback in release/AAB)
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# Keep AndroidX Media3 (ExoPlayer 2.18+) classes used by just_audio
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**

# Keep JSON serialization
-keepattributes *Annotation*
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Google Play Core classes (fix R8 issues)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Keep Flutter deferred components
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Aggressive optimization for size reduction
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify

# Remove debug logs in release
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# Remove unused resources
-dontwarn org.slf4j.**
-dontwarn org.apache.**
-dontwarn javax.annotation.**
-dontwarn javax.inject.**

# Keep only essential classes
-keep class * extends java.lang.Exception
-keep class * extends java.lang.Enum

# Remove unused imports and classes
-dontnote **
-dontwarn **
