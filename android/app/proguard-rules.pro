# AppLovin MAX Proguard / R8 rules
-keep class com.applovin.** { *; }
-dontwarn com.applovin.**

# OMID (IAB Open Measurement) and Amazon PrivacyPass optional references inside AppLovin
-keep class com.iab.omid.** { *; }
-dontwarn com.iab.omid.**
-dontwarn com.amazon.privacypass.**

# Flutter and AndroidX general rules
-dontwarn io.flutter.plugin.**
-keepattributes *Annotation*
-keepattributes JavascriptInterface
