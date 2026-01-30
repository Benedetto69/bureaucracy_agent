-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

-dontwarn io.flutter.embedding.android.FlutterActivity
-dontwarn io.flutter.embedding.engine.FlutterEngine

-keep class com.example.bureaucracy_agent.** { *; }

-keepattributes Signature
-keepattributes *Annotation*

-ignorewarnings
