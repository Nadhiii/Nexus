# ProGuard rules to keep mediapipe proto classes for release builds
# This prevents R8 from removing required classes used by mediapipe

# Keep all classes in the com.google.mediapipe.proto package
-keep class com.google.mediapipe.proto.** { *; }

# Keep all classes in the com.google.mediapipe.formats.proto package
-keep class com.google.mediapipe.formats.proto.** { *; }

# Keep all classes in the com.google.protobuf package (if used by mediapipe)
-keep class com.google.protobuf.** { *; }

# Keep all enums and fields for proto classes
-keepclassmembers class * extends com.google.protobuf.GeneratedMessageLite {
    <fields>;
    <methods>;
}

# Keep all enums and fields for proto classes (older protobuf)
-keepclassmembers class * extends com.google.protobuf.GeneratedMessage {
    <fields>;
    <methods>;
}

# Optional: Keep all classes in mediapipe (if you use other mediapipe classes)
-keep class com.google.mediapipe.** { *; }

# Added based on R8 missing_rules.txt output
-dontwarn com.google.mediapipe.proto.CalculatorProfileProto$CalculatorProfile
-dontwarn com.google.mediapipe.proto.GraphTemplateProto$CalculatorGraphTemplate
