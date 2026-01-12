# Fuel Price API Integration - Complete Guide

## Overview
Your app now has **location-based, real-time fuel price updates** with automatic city detection and API integration support!

---

## 🎯 Features Implemented

✅ **Auto Location Detection** - GPS-based city detection  
✅ **City-based Fuel Prices** - Support for 8+ major Indian cities  
✅ **Multi-Brand Support** - Indian Oil, HPCL, BPCL, Shell, Jio-BP, Nayara  
✅ **Petrol & Diesel Prices** - Toggle between fuel types  
✅ **Smart Caching** - 12-hour cache to reduce API calls  
✅ **Fallback Prices** - Works even without API  
✅ **Refresh Button** - Manual price updates  
✅ **Provider Architecture** - Clean state management

---

## 📦 Files Created/Modified

### New Files:
1. **`lib/core/services/fuel_price_service.dart`** - API integration & caching
2. **`lib/core/services/location_service.dart`** - GPS/city detection  
3. **`lib/core/providers/fuel_price_provider.dart`** - State management

### Modified Files:
1. **`lib/modules/bike/widgets/fuel_price_widget.dart`** - Updated UI to use provider
2. **`lib/main.dart`** - Added FuelPriceProvider
3. **`pubspec.yaml`** - Added geolocator, geocoding, http packages

---

## 🔑 API Configuration

### RapidAPI - India Fuel Prices (RECOMMENDED)

**Step 1: Get Your FREE API Key**

1. **Visit RapidAPI Hub:**
   - Go to: https://rapidapi.com/hub
   - Search for "India fuel price" or "petrol diesel India"

2. **Popular APIs to Try:**
   - Search "fuel price india"
   - Look for APIs with free tier
   - Examples: "India Fuel Price", "Petrol Diesel Price India"

3. **Subscribe to API:**
   - Click on your chosen API
   - Click "Subscribe to Test" or "Pricing"
   - Select **FREE plan** (usually 100-500 requests/month)
   - No credit card required for free tier

4. **Get Your API Key:**
   - After subscribing, go to the API's page
   - Look for **"X-RapidAPI-Key"** in the code snippets
   - Copy your API key (starts with something like: `a1b2c3d4e5...`)

**Step 2: Add API Key to Your App**

```dart
// In your app (e.g., in bike screen's initState or settings):
final priceProvider = context.read<FuelPriceProvider>();
await priceProvider.setAPIKey('YOUR_RAPIDAPI_KEY_HERE');

// Then refresh to get live prices:
await priceProvider.refresh();
```

**Or add to .env file:**
```env
FUEL_API_KEY=your_rapidapi_key_here
```

---

### Free Tier Benefits:
✅ 100-500 requests/month (varies by API)  
✅ No credit card required  
✅ Real-time fuel prices  
✅ Multiple city support  

---

### Option 2: Use Default Prices (Works Immediately)

The app works **out of the box** with built-in default prices for:
- Mumbai, Delhi, Bangalore, Chennai, Hyderabad, Kolkata, Pune, Ahmedabad

Prices are refreshed every 12 hours from cache.

---

### How to Add API Key (If Using collectapi):

```dart
// Method 1: Using shared preferences (recommended)
final priceProvider = context.read<FuelPriceProvider>();
await priceProvider.setAPIKey('YOUR_API_KEY_HERE');

// Method 2: Add to .env file
// Add this line to your .env file:
FUEL_API_KEY=YOUR_API_KEY_HERE
```

---

##  🌍 Supported Cities

Current default cities with fallback prices:
1. **Mumbai** - ₹106.31 (Petrol), ₹94.27 (Diesel)
2. **Delhi** - ₹96.72 (Petrol), ₹89.62 (Diesel)
3. **Bangalore** - ₹101.94 (Petrol), ₹87.89 (Diesel)
4. **Chennai** - ₹102.63 (Petrol), ₹94.24 (Diesel)
5. **Hyderabad** - ₹109.66 (Petrol), ₹97.82 (Diesel)
6. **Kolkata** - ₹106.03 (Petrol), ₹92.76 (Diesel)
7. **Pune** - ₹106.09 (Petrol), ₹94.15 (Diesel)
8. **Ahmedabad** - ₹96.42 (Petrol), ₹92.17 (Diesel)

---

## 🚀 How to Use

### For Users:

1. **Auto-detect location:**
   - Tap the **location icon** (📍) in the fuel price widget
   - Grant location permission when prompted
   - App will auto-select your city

2. **Manual city selection:**
   - Tap the dropdown menu
   - Select your city from the list

3. **Refresh prices:**
   - Tap the **refresh icon** (🔄) to get latest prices
   - Prices update automatically every 12 hours

4. **Select fuel type & brand:**
   - Toggle between **Petrol/Diesel**
   - Select your preferred brand (Indian Oil, Shell, etc.)
   - Price updates automatically

### For Developers:

**Access fuel price programmatically:**
```dart
// Get current fuel price
final priceProvider = context.read<FuelPriceProvider>();
final currentPrice = priceProvider.currentPrice;

print('Petrol: ₹${currentPrice.petrol}');
print('Diesel: ₹${currentPrice.diesel}');
print('City: ${currentPrice.city}');

// Load price for specific city
await priceProvider.loadPriceForCity('Mumbai');

// Refresh prices
await priceProvider.refresh();

// Auto-detect location
await priceProvider.detectAndLoadCity();
```

---

## 🔧 Advanced Configuration

### Add More Cities:

Edit `lib/core/services/fuel_price_service.dart`:
```dart
static final Map<String, FuelPrice> _defaultPrices = {
  'Mumbai': FuelPrice(petrol: 106.31, diesel: 94.27, city: 'Mumbai'),
  'YourCity': FuelPrice(petrol: 100.00, diesel: 90.00, city: 'YourCity'),
  // Add more cities here
};
```

### Change Cache Duration:

```dart
// In fuel_price_service.dart, line 13:
static const Duration _cacheValidity = Duration(hours: 24); // Change to 24 hours
```

### Manually Update Prices (Admin/Testing):

```dart
final priceProvider = context.read<FuelPriceProvider>();
await priceProvider.updatePrice('Mumbai', 107.50, 95.00);
```

---

## 🛡️ Permissions Required

### Android (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS (`ios/Runner/Info.plist`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show fuel prices in your city</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>We need your location to provide accurate fuel prices</string>
```

---

## 🧪 Testing

### Test without API:
```bash
# Run the app - default prices will be used
flutter run
```

### Test with API:
```dart
// Add this to your bike screen's initState:
final priceProvider = context.read<FuelPriceProvider>();
await priceProvider.setAPIKey('YOUR_TEST_API_KEY');
await priceProvider.refresh();
```

### Test location detection:
1. Enable location on your device
2. Tap the location icon in the fuel widget
3. Check console for detected city

---

## 📊 API Response Format (RapidAPI)

The service handles multiple response formats automatically:

**Format 1 - Object by City:**
```json
{
  "Mumbai": {
    "petrol": 106.31,
    "diesel": 94.27
  }
}
```

**Format 2 - Array of Cities:**
```json
[
  {
    "city": "Mumbai",
    "petrol": "106.31",
    "diesel": "94.27",
    "date": "2026-01-08"
  }
]
```

**Format 3 - Nested Data:**
```json
{
  "data": {
    "Mumbai": {
      "petrol": 106.31,
      "diesel": 94.27
    }
  }
}
```

The service automatically detects and parses these formats! 🎯

---

## 🐛 Troubleshooting

### Issue: Location not detected
**Solution:**
- Grant location permission in device settings
- Enable GPS/Location Services
- Try selecting city manually from dropdown

### Issue: API not working
**Solution:**
- Verify API key is correct
- Check internet connection
- Review API quota (100 requests/day for free tier)
- App will fallback to default prices automatically

### Issue: Prices not updating
**Solution:**
- Tap refresh button
- Clear cache: `priceProvider.refresh()`
- Check if 12 hours have passed since last update

---

## 🔄 Finding the Best RapidAPI for India Fuel Prices

### How to Search:

1. **Go to RapidAPI:** https://rapidapi.com/search/india%20fuel%20price

2. **Search Terms to Try:**
   - "india fuel price"
   - "petrol diesel price india"
   - "indian oil prices"
   - "fuel price api india"

3. **What to Look For:**
   - ✅ **Free Tier Available** - Check pricing tab
   - ✅ **Good Rating** - 4+ stars
   - ✅ **Recent Updates** - Updated within last 6 months
   - ✅ **Clear Documentation** - Has example responses
   - ✅ **Multiple Cities** - Supports major Indian cities

4. **Popular APIs (Examples):**
   - Search for APIs by developers who maintain India-specific data
   - Look for keywords: "petrol", "diesel", "fuel", "India", "IOCL"

### Testing Your API:

```dart
// After adding your RapidAPI key:
final priceProvider = context.read<FuelPriceProvider>();

// Test it:
await priceProvider.setAPIKey('YOUR_KEY');
await priceProvider.loadPriceForCity('Mumbai');

// Check result:
print(priceProvider.currentPrice?.petrol);
```

---

## ✅ Summary

You now have a **fully functional, location-aware fuel price system** that:
- ✅ Works immediately with default prices
- ✅ Can integrate with free APIs
- ✅ Auto-detects user location
- ✅ Supports 8+ cities
- ✅ Has smart caching
- ✅ Handles errors gracefully

**No API key needed to start using it right now!**

---

## 🎁 Bonus: Premium Features You Can Add

1. **Price Alerts** - Notify when price drops
2. **Price History Graph** - Show 30-day trends
3. **Nearby Pumps** - Find cheapest fuel nearby
4. **Price Comparison** - Compare brands in real-time

Let me know if you want help implementing any of these! 🚀
