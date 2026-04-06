# Spotify SDK and Jackson JSON rules
-keep class com.spotify.** { *; }
-dontwarn com.spotify.**

-keep class com.fasterxml.jackson.** { *; }
-dontwarn com.fasterxml.jackson.**

# Keep Flutter wrapper safe
-keep class io.flutter.plugins.** { *; }