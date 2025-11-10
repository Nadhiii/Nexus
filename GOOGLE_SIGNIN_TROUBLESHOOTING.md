# Google Sign-In Troubleshooting Guide

## Issue: "Continue with Google" button not working

### ✅ What has been fixed:
1. **Updated Google Sign-In implementation**: Changed from `signInWithProvider()` to proper `google_sign_in` package usage
2. **Downgraded to stable version**: Updated from `google_sign_in: ^7.1.1` to `google_sign_in: ^6.2.1` for better compatibility
3. **Improved error handling**: Better user-friendly error messages
4. **Added proper sign-out**: Ensures Google Sign-In state is properly cleared on logout
5. **Fixed GoogleSignInApi null error**: Added proper initialization and fallback handling
6. **Added dual-method approach**: Uses google_sign_in package with Firebase Auth fallback

### 🔧 Common Errors and Solutions:

#### Error: "type 'Null' is not a subtype of type 'GoogleSignInApi'"
**Cause**: Google Play Services not available or not properly initialized
**Solution**: 
- ✅ **Fixed in code**: App now has fallback handling
- User sees: "Google Play Services is not available or needs to be updated. Please try 'Use without account' option."

#### Error: "SIGN_IN_REQUIRED" or "GoogleSignInApi"
**Cause**: Google Play Services issues
**Solution**: 
- ✅ **Fixed in code**: Automatic fallback to Firebase Auth provider
- Update Google Play Services on device
- Use "Use without account" option

### 🔧 If Google Sign-In still doesn't work:

#### 1. Check SHA-1 Fingerprint Configuration
The most common issue is incorrect SHA-1 fingerprint in Firebase Console.

**Get your debug SHA-1 fingerprint:**
```bash
# On Windows (PowerShell)
keytool -list -v -keystore $env:USERPROFILE\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android

# On macOS/Linux
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Or using Gradle
cd android && ./gradlew signingReport
```

**Add SHA-1 to Firebase:**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `nexus-ccef7`
3. Go to Project Settings > General
4. Under "Your apps" section, click on Android app
5. Add the SHA-1 fingerprint to "SHA certificate fingerprints"

#### 2. Verify Package Name
Ensure the package name matches:
- Firebase Console: `com.mahanadhi.nexus`
- `android/app/build.gradle.kts`: `applicationId = "com.mahanadhi.nexus"`

#### 3. Check Google Services Configuration
Verify `android/app/google-services.json` contains the correct configuration for your package name.

#### 4. Enable Google Sign-In in Firebase
1. Go to Firebase Console > Authentication > Sign-in method
2. Enable "Google" provider
3. Add your app's package name if not already added

#### 5. Rebuild the App
After making any changes:
```bash
flutter clean
flutter pub get
flutter run
```

### 🆘 Alternative Options

If Google Sign-In continues to have issues, users can:
1. **Use "Use without account"** - Anonymous authentication is working
2. **Wait for Google Sign-In fix** - Data will sync when they sign in later

### 📱 Testing on Different Devices

Google Sign-In behavior can vary between:
- **Emulator**: May not have Google Play Services
- **Physical device**: Should work if properly configured
- **Different Android versions**: Some versions handle OAuth differently

### 🐛 Debug Information

Current configuration:
- Package: `com.mahanadhi.nexus`
- Firebase Project: `nexus-ccef7`
- SHA-1 in config: `45e99dd9f7fc664d555d16e0ffd81cc4f8e2e9ad`

If you need help, check the Flutter logs for specific error messages:
```bash
flutter logs
```

### 📞 Support

If the issue persists:
1. Check device has Google Play Services installed
2. Ensure device is connected to internet
3. Try on a different device/emulator
4. Check Firebase Console for any error logs
