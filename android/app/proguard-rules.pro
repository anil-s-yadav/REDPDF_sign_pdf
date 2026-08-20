## Flutter-specific ProGuard rules ##

# Keep Flutter engine classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep Dart entry points
-keep class io.flutter.app.** { *; }

# Syncfusion PDF Viewer
-keep class com.syncfusion.** { *; }

# Google ML Kit Document Scanner
-keep class com.google.mlkit.** { *; }

# In-App Update
-keep class com.google.android.play.** { *; }

# In-App Review
-keep class com.google.android.play.core.** { *; }

# Keep annotations
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes Exceptions

# Suppress missing class warnings for Play Core, Play Services, and Flutter deferred components
-dontwarn com.google.android.gms.**
-dontwarn com.google.android.play.**
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication

