/// Centralized environment configuration using compile-time --dart-define flags.
///
/// Usage at build time:
/// ```bash
/// flutter run --dart-define=GEMINI_API_KEY=your_key_here
/// flutter build apk --dart-define=GEMINI_API_KEY=your_key_here
/// ```
///
/// This replaces the previous flutter_dotenv approach which bundled .env
/// files into the APK (extractable by anyone). --dart-define values are
/// compiled into the binary as string constants, which is marginally better
/// but still not a secrets vault. For production-grade key management,
/// consider Firebase Remote Config or a backend proxy.
class EnvConfig {
  /// Gemini API key for AI features (if re-enabled in the future)
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// OTA update server URL override
  static const String otaUpdateUrl = String.fromEnvironment(
    'OTA_UPDATE_URL',
    defaultValue: 'https://mahanadhi.space/update.json',
  );

  /// Whether the app is running in debug/staging mode
  static const bool isStaging = bool.fromEnvironment(
    'IS_STAGING',
    defaultValue: false,
  );

  /// Check if a required key is configured
  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;
}
