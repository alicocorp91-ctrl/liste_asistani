# flutter_local_notifications
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes *Annotation*
-dontwarn com.google.gson.**
# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter motoru Play Core (ertelenmiş bileşen / dinamik özellik) sınıflarına
# referans verir; uygulama bunları kullanmadığı için R8 uyarıları bastırılır.
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
# Uygulama içinde kullanılmayan ertelenmiş bileşen yöneticisi
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication

# Bildirim eklentisi (flutter_local_notifications) için ek kurallar
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class * implements java.io.Serializable { *; }
