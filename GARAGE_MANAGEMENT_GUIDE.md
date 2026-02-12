# Garage Management System - API & Architecture Guide

## Overview
The garage/vehicle management system handles bike/vehicle tracking with entries for fuel, maintenance, repairs, and other expenses. It includes mileage calculations and trip tracking.

## Firebase Collection Structure

```
users/{uid}/
  bikes/{bikeId}/
    - id, userId, name, make, model, year, registrationNumber
    - currentOdometer, isActive, createdAt
    - isDashboardBike, displayOrder
    entries/{entryId}/
      - id, userId, bikeName, date, odometerReading
      - fuelQuantity, fuelAmount, category, notes
      - mileage (calculated), isFullTank
    trips/{tripId}/
      - startOdometer, endOdometer, distance, duration
      - startTime, endTime, routePolyline, notes
```

## Core Models

### Bike
- **Key Fields**: id, userId, name, make, model, year, registrationNumber, currentOdometer
- **Display Fields**: isDashboardBike (featured on dashboard), displayOrder (for reordering)
- **Optional Fields**: ownerName, fuelType, rtoLocation, chassisNumber, engineNumber, insurer, policyExpiry

### BikeEntry
- **Type**: Represents fuel fillups, maintenance, repairs, or expenses
- **Key Fields**: id, userId, bikeName, date, odometerReading, fuelQuantity, fuelAmount, category
- **Important**: isFullTank flag for accurate mileage calculation
- **Categories**: 'fuel', 'maintenance', 'repair', 'insurance', 'modification', 'fine', 'other'

### Trip (Partially Implemented)
- Tracks individual rides/journeys
- Fields: startOdometer, endOdometer, distance, duration, startTime, endTime

## Mileage Calculation Logic

The system uses **full tank methodology** for accurate fuel efficiency:

1. When `isFullTank = true`, the app looks for the previous full tank entry
2. Calculates total distance since last full tank
3. Calculates total fuel consumed (including partial fillups between full tanks)
4. Mileage = Distance / Total Fuel Used

**Example**:
- Full tank at 1000 km, 50L (Start)
- Partial top-up at 1200 km, 10L
- Full tank at 1400 km, 35L (Current)
- Distance: 1400 - 1000 = 400 km
- Total Fuel: 35L + 10L = 45L
- Mileage: 400 / 45 ≈ 8.89 km/l

## State Management (Provider Pattern)

### BikeProvider
- **Extends**: ChangeNotifier
- **Purpose**: Centralized state management for bikes and entries
- **Key Methods**:
  - `fetchBikes()` - Load all bikes
  - `selectBike(bikeId)` - Set active bike
  - `loadBikeEntries(userId, bikeId)` - Subscribe to entries stream
  - `addBikeEntry(entry)` - Create new entry
  - `updateBikeEntry(entry)` - Modify existing entry
  - `deleteBikeEntry(entryId)` - Remove entry
  - `updateBike(bike)` - Modify bike details

### Listeners
- Uses Firestore Stream listeners for real-time updates
- `_entriesSubscription` - Watches entries for selected bike
- `_tripsSubscription` - Watches trips for selected bike
- Automatic cleanup on bike selection change

## UI Components

### ModernBikeScreen
- Main garage/vehicle management screen
- Shows selected bike stats and entry history
- Floating action button to add entries

### GarageManagementScreen
- Reorderable list for organizing bikes
- Drag-and-drop to change displayOrder
- Dashboard bike starring feature

### AddEntryDialog / EditEntryDialog
- Modal for adding/editing fuel and expense entries
- Full tank toggle for mileage calculation
- Category selection with custom category support
- Date picker for backdated entries

## Known API Details

### Firestore Rules
- Users can only access their own bikes and entries
- Real-time listeners provide live updates
- Batch operations for efficient multi-entry updates

### Rate Limiting
- No documented rate limits, standard Firestore limits apply
- Consider pagination for users with 1000+ entries

## Troubleshooting

### "Edit crashes app"
- Usually caused by null values in category dropdown
- Fix-Safe: The editEntry dialog ensures all categories exist before rendering

### "Can't add new log"
- Validate odometer and cost fields are non-empty
- Check that selectedBikeId is set before adding
- Verify Firestore write permissions

### "Entries not appearing"
- Check that loadBikeEntries() was called after selectBike()
- Verify Firestore collection path: users/{uid}/bikes/{bikeId}/entries
- Check network connectivity and Firestore permissions

### "Mileage showing 0"
- isFullTank must be TRUE and previous full tank entry must exist
- Ensure at least 2 full tank entries exist for calculation
- Check that fuelQuantity is > 0
