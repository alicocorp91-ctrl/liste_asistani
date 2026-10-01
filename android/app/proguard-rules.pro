# flutter_local_notifications
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes *Annotation*
-dontwarn com.google.gson.**

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Play Core / Deferred Components (R8 Eksik Sınıf Hatası Çözümü)
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-dontwarn com.google.android.play.core.**