# 🚨 EXACT SOLUTION: SHA-1 Certificate Hash Issue

## ✅ CONFIRMED PROBLEM
Based on your logs:
```
E/FirebaseAuth( 4322): [GetAuthDomainTask] Error getting project config. Failed with INVALID_CERT_HASH 400
I/flutter ( 4322): Firebase signInWithProvider also failed: [firebase_auth/invalid-cert-hash] There was an error while trying to get your package certificate hash.
```

**The issue is**: Your debug keystore SHA-1 fingerprint doesn't match what's configured in Firebase.

## 🎯 IMMEDIATE FIX STEPS

### Step 1: Get Your Actual SHA-1 Fingerprint

**Method A - Using Flutter (Easiest):**
1. Open **Command Prompt** (not PowerShell)
2. Navigate to your project: `cd E:\Nexus\nexus`
3. Run: `flutter doctor -v`
4. Look for Java path, it might show something like: `Java binary at: C:\Program Files\Android\Android Studio\jbr\bin\java`

**Method B - Find Android Studio Java:**
1. Open Android Studio
2. Go to: `File > Settings > Build, Execution, Deployment > Build Tools > Gradle`
3. Note the "Gradle JDK" path
4. Open Command Prompt and run:
   ```cmd
   "C:\Program Files\Android\Android Studio\jbr\bin\keytool" -list -v -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore -storepass android -keypass android
   ```

**Method C - Alternative Manual Approach:**
1. Open **File Explorer**
2. Go to: `%USERPROFILE%\.android\`
3. You should see `debug.keystore` file
4. Note the path for later

### Step 2: Get SHA-1 Using Android Studio (Recommended)

**If you have Android Studio installed:**
1. **Open Android Studio**
2. **Open your project**: `File > Open > E:\Nexus\nexus`
3. **Wait for project to sync**
4. **Click on "Gradle" tab** (right side panel)
5. **Expand**: `nexus > android > Tasks > android`
6. **Double-click**: `signingReport`
7. **Look in the Build Output** for:
   ```
   Variant: debug
   Config: debug
   Store: ~/.android/debug.keystore
   Alias: AndroidDebugKey
   SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
   ```
8. **Copy the SHA1 value**

### Step 3: Update Firebase Configuration

1. **Go to Firebase Console**: https://console.firebase.google.com/project/nexus-ccef7/settings/general
2. **Find your Android app**: `com.mahanadhi.nexus`
3. **Click "Add fingerprint"**
4. **Paste your SHA-1** from Step 2
5. **Click "Save"**

### Step 4: Download New Configuration

1. **Still in Firebase Console**
2. **Click "Download google-services.json"**
3. **Replace the file**: `E:\Nexus\nexus\android\app\google-services.json`

### Step 5: Rebuild App

```bash
flutter clean
flutter pub get
flutter run
```

## 🆘 If You Can't Get SHA-1

**Alternative Temporary Fix:**

1. **Go to Firebase Console**: Authentication > Sign-in method
2. **Click on Google provider**
3. **Temporarily disable it**
4. **Re-enable it**
5. **Don't add any specific SHA-1** (leave it open for now)
6. **Test the app**

## ⚡ Expected SHA-1 Pattern

Your SHA-1 should look like:
```
A1:B2:C3:D4:E5:F6:07:18:29:3A:4B:5C:6D:7E:8F:90:A1:B2:C3:D4
```
- 20 pairs of hexadecimal characters
- Separated by colons

## 🎯 Current Status

- ✅ Google Play Services working
- ✅ Account selector appears  
- ❌ Certificate hash mismatch
- ✅ Enhanced logging working
- ✅ Error properly identified

**Next**: Get your SHA-1 using Android Studio method above, then update Firebase!
