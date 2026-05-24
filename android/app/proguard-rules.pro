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
