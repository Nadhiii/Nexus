# OTA Update Integration (Android)

## How it works
- On app open, the app checks a remote JSON endpoint for the latest version.
- If an update is available, a notification is shown.
- User can also tap "Check for Updates" in the About screen to manually check and download.
- Download progress and status are shown via local notifications.
- Once downloaded, user is prompted to install the APK.

## Backend Requirements
- Host a JSON file (e.g. `https://yourdomain.com/update.json`) with:

```
{
  "latest_version": "1.2.0",
  "apk_url": "https://yourdomain.com/app-release.apk",
  "release_notes": "Bug fixes and improvements."
}
```
- Host the APK at the `apk_url` location.

## Caveats
- This method is for Android only and not Play Store compliant (for direct APK distribution).
- User must allow installs from unknown sources.
- For Play Store apps, use the `in_app_update` package instead.
- Update the `currentVersion` string in code to match your app's version.

## Customization
- Edit `/lib/core/services/ota_update_service.dart` to set your endpoint.
- The About screen button and auto-check logic are in place.

---

For questions, see the code comments or ask your friendly Copilot!