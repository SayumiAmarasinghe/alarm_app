# Spotify SDK and Jackson JSON rules
-keep class com.spotify.** { *; }
-dontwarn com.spotify.**

-keep class com.fasterxml.jackson.** { *; }
-dontwarn com.fasterxml.jackson.**

# Keep Flutter wrapper safe
-keep class io.flutter.plugins.** { *; }
# Flutter Local Notifications & Gson rules
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }