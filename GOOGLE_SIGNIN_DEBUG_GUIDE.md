# 🔧 Google Sign-In Debug Guide

## Current Issue Analysis

**Status**: ✅ Google account selector appears (Google Play Services working)
**Problem**: ❌ Authentication fails after account selection

**Root Cause**: SHA-1 fingerprint mismatch between your debug keystore and Firebase configuration.

## 🎯 Quick Fix Steps

### Step 1: Get Your Current SHA-1 Fingerprint

**Option A - Using Android Studio:**
1. Open your project in Android Studio
2. Open Gradle panel (right side)
3. Navigate to: `nexus > android > Tasks > android > signingReport`
4. Double-click `signingReport`
5. Look for `SHA1:` in the output

**Option B - Using Command Line:**
```bash
# Windows (PowerShell)
keytool -list -v -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore -storepass android -keypass android

# Look for line that starts with "SHA1:"
```

**Option C - Using Gradle:**
```bash
cd android
.\gradlew signingReport
```

### Step 2: Update Firebase Configuration

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select Project**: `nexus-ccef7`
3. **Navigate**: Project Settings > General tab
4. **Find Your App**: Look for Android app with package `com.mahanadhi.nexus`
5. **Add SHA-1**: 
   - Click "Add fingerprint"
   - Paste your SHA-1 fingerprint from Step 1
   - Click "Save"

### Step 3: Update google-services.json (Important!)

1. **Download New Config**: In Firebase Console, click "Download google-services.json"
2. **Replace File**: Replace `android/app/google-services.json` with the new file
3. **Rebuild App**: 
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

## 🔍 Current Configuration

**Your Firebase Project**: `nexus-ccef7`
**Package Name**: `com.mahanadhi.nexus` ✅
**Current SHA-1 in Firebase**: `45e99dd9f7fc664d555d16e0ffd81cc4f8e2e9ad`

## 🚀 Alternative Quick Test

If you want to test immediately without configuring SHA-1:

**Try the fallback method** by temporarily modifying the code to use only Firebase Auth provider (I can help with this if needed).

## 📋 Troubleshooting Checklist

- [ ] Got your current SHA-1 fingerprint
- [ ] Added SHA-1 to Firebase Console
- [ ] Downloaded new google-services.json
- [ ] Replaced the file in android/app/
- [ ] Ran `flutter clean && flutter pub get`
- [ ] Rebuilt and tested the app

## ⚡ Expected Result

After fixing the SHA-1:
- ✅ Google account selector appears
- ✅ Authentication completes successfully
- ✅ User is signed in to the app

## 🆘 If Still Not Working

Try these debugging steps:
1. Check Flutter logs: `flutter logs`
2. Verify package name consistency
3. Ensure Google Sign-In is enabled in Firebase Authentication
4. Try on a different device

---

**Need Help?** Run the commands above and share the output - I can help configure everything correctly!
