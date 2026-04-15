
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }
-keep class io.supabase.** { *; }

# Google Play Core (required for deferred components)
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-dontwarn com.google.android.play.core.**

-dontwarn kotlin.**
-dontwarn okhttp3.**
