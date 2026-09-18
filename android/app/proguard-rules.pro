# Flutter Wrapper & Platform Channels
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter Play Store Split Install (Deferred Components not used)
-dontwarn com.google.android.play.core.**

# SQLite & Sqflite JNI / Native Reflection
-keep class com.tekartik.sqflite.** { *; }
-keep public class * extends com.tekartik.sqflite.**
-keepclasseswithmembers class * {
    native <methods>;
}

# Flutter Local Notifications & Background Receivers
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.** { *; }
-keep class androidx.core.app.NotificationCompat** { *; }
-keep class androidx.work.** { *; }

# Prevent tree-shaking of serializable / reflective members
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
