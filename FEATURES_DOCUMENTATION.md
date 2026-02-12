# Nexus - Complete Features Documentation

**Last Updated**: January 8, 2026

---

## Table of Contents
1. [App Overview](#app-overview)
2. [Core Features](#core-features)
3. [Module-Specific Features](#module-specific-features)
4. [Technical Architecture](#technical-architecture)
5. [Design System](#design-system)
6. [Setup & Configuration Guides](#setup--configuration-guides)

---

## App Overview

**Nexus** is a comprehensive, AI-powered personal finance management application built with Flutter. It helps users take complete control of their financial life through intelligent tracking, automated insights, smart budgeting, and advanced analytics.

### Vision
Nexus is not just another expense tracker - it's a **financial intelligence platform** that:
- Provides AI-powered insights and recommendations
- Offers dynamic budget management with salary-based allocations
- Enables comprehensive financial analytics and reporting
- Supports family financial sharing and collaboration
- Features dark-first UI design with modern aesthetics

### Platform Support
- **Framework**: Flutter (Latest stable)
- **Backend**: Firebase (Firestore, Auth, Cloud Functions)
- **Platforms**: Android & iOS
- **Design**: Material Design 3 with custom theming

---

## Core Features

### 1. Smart Dashboard
- **Net Worth Overview**: Real-time calculation (Assets - Liabilities)
- **Dynamic Greeting**: Personalized user experience
- **Balance Cards**: Quick-glance view with gradient styling
- **Recent Transactions**: Preview of latest financial activity
- **Pending Bills**: Alerts for upcoming subscriptions/bills
- **Quick Actions**: Fast access to common tasks (Add Income/Expense, Transfer, Set Goals)
- **AI Insights Widget**: Smart spending recommendations
- **Customizable Layout**: Personalize dashboard widgets

### 2. Account Management
**Account Types Supported:**
- Cash accounts
- Bank accounts
- Credit cards
- Investment accounts
- Savings accounts

**Features:**
- Real-time balance tracking
- Account color coding
- Detailed account history view
- Account type-specific features
- Account reconciliation support
- Multiple account management

### 3. Transaction Management

#### Multi-Source Input
- **Manual Entry**: Direct transaction input
- **SMS Parsing**: Automatic detection from bank notifications
- **PDF Import**: Bulk upload from bank statements (with password protection)
- **Bank Statement**: Bulk upload support

#### Smart Categorization
- AI-powered automatic category assignment
- Universal categorization service for accuracy
- Custom category creation and management
- Transaction categorization learning

#### Transaction Features
- Income and expense tracking
- Transaction tags and notes
- Attachment support (receipts)
- Date and time tracking
- **Duplicate Detection**: Prevents duplicate entries (95%+ accuracy)
- Bulk operations (edit/delete multiple)
- Advanced search and filtering
- Full audit trail
- Recurring transaction patterns
- Split transactions support

### 4. Budget Management

#### Dynamic Budget Allocation
- **Salary-Based Auto Distribution**: Automatic budget allocation based on income
- Category-wise budget allocation
- Monthly and yearly budget views
- **Budget Rollover**: Carry unused budget to next period

#### Budget Tracking
- Real-time spending vs budget comparison
- Progress visualization with progress bars
- Category-level budget monitoring
- **Spending Alerts**: Notifications when approaching limits
- Historical budget analysis

#### Budget Features
- Flexible budget adjustments
- Budget templates
- Seasonal budget adjustments
- Zero-based budgeting support
- Envelope budgeting system

### 5. Debt & Loan Management

#### Debt Tracking
- Principal amount tracking
- Interest rate calculation
- EMI/payment schedule management
- Payoff strategy recommendations
- Remaining balance calculation

#### Debt Analysis
- Debt consolidation insights
- Interest paid analysis
- Payoff timeline visualization
- Debt reduction progress tracking
- Monthly payment projections

### 6. Goal Setting & Tracking
- **SMART Goals**: Specific, Measurable, Achievable, Relevant, Time-bound
- Multiple goal types (savings, investment, debt payoff, etc.)
- Progress visualization
- Goal deadline tracking
- Milestone celebrations
- Goal-specific savings allocation

### 7. AI-Powered Financial Intelligence
- **Spending Pattern Analysis**: Identifies trends and anomalies
- **Budget Optimization**: Suggests optimal budget allocations
- **Savings Opportunities**: Finds areas to save money
- **Predictive Analytics**: Forecasts future financial scenarios
- **Personalized Recommendations**: Tailored advice based on behavior

### 8. Advanced Analytics & Reports
- **Net Worth Tracking**: Historical progression
- **Cash Flow Analysis**: Income vs expense trends
- **Category Breakdown**: Detailed spending analysis
- **Goal Progress Tracking**: Visual progress indicators
- **Time Period Analysis**: Daily, weekly, monthly, yearly views

### 9. Bills & Subscription Management
- **Recurring Bill Tracking**: Automatic reminders
- **Subscription Monitor**: Track all subscriptions
- **Payment Scheduling**: Schedule automatic payments
- **Cost Analysis**: Identify expensive subscriptions to cancel

### 10. Investment Portfolio Management
- **Multi-Asset Support**: Stocks, mutual funds, crypto, gold, real estate
- **Real-time Valuation**: Track current values and profit/loss
- **Portfolio Analytics**: Asset allocation and performance metrics
- **Mutual Fund Integration**: Search and track Indian mutual funds with live NAV
- **Investment Tracking**: Monitor invested amount vs current value

### 11. Vehicle/Bike Tracking
- **Multi-Vehicle Support**: Track multiple bikes/vehicles
- **Fuel Efficiency**: Automatic mileage calculation
- **Maintenance Tracking**: Record service and repairs
- **Expense Management**: Track all vehicle-related costs
- **Trip Logging**: Distance-based or odometer-based tracking

---

## Module-Specific Features

### Bike/Vehicle Tracking Module

**Purpose**: Track fuel efficiency, maintenance, and expenses for motorcycles and vehicles.

#### Quick Start
1. Tap the **bike icon** in bottom navigation (4th tab)
2. Tap **"Add Bike"** floating action button
3. Enter bike details (name, model, year, current odometer)

#### Features

**Multi-Bike Support**
- Track unlimited bikes separately
- Switch between bikes with tap
- Separate history for each vehicle

**Automatic Mileage Calculation**
- Calculates km/liter based on fuel quantity and distance
- No manual calculation needed
- Real-time efficiency tracking

**Expense Tracking**
- Fuel costs
- Maintenance
- Insurance
- Repairs
- Custom expense categories

**Dashboard Metrics**
- Total fuel cost
- Average mileage (km/liter)
- Number of fill-ups
- Total distance traveled

**Fuel Entry Logging**
1. Select bike
2. Tap menu (⋮) or "Add Fuel Entry"
3. Enter:
   - Date
   - Category (Fuel, Maintenance, etc.)
   - Odometer reading
   - Fuel quantity (liters)
   - Amount (₹)
   - Notes (optional)

**Trip Tracking** (Alternative to Odometer)
- Log trips by distance only (e.g., "50 km")
- Odometer updates automatically from trip history
- Perfect for when you don't check odometer every time
- Works alongside fuel entries

**Real-time Sync**
- All data syncs with Firebase
- Access from any device

#### Technical Implementation
- **Models**: `lib/core/models/bike.dart`, `trip.dart`
- **Services**: `BikeService` - CRUD operations
- **Providers**: `BikeProvider` - State management
- **UI**: `modern_bike_screen_ui.dart` - Visual rendering
- **Dialogs**: `add_bike_dialog.dart`, `add_trip_dialog.dart`

---

### PDF Bank Statement Importer

**Purpose**: Bulk import transactions from PDF bank statements with automatic parsing and duplicate detection.

#### Features

**Supported Banks** (6+ Indian Banks)
- HDFC Bank
- ICICI Bank
- SBI (State Bank of India)
- Axis Bank
- Kotak Mahindra Bank
- And more...

**Automatic Detection & Parsing**
- Bank identification from PDF format
- Account number extraction
- Account holder name extraction
- Statement period detection
- Transaction parsing (date, amount, description)

**Password Protection Support**
- Handles password-protected PDFs
- Secure password input dialog
- Multiple password attempt handling

**Duplicate Detection**
- **95%+ accuracy** using Levenshtein distance algorithm
- Prevents duplicate transaction entries
- Smart matching based on:
  - Transaction amount
  - Date proximity
  - Description similarity

**Account Management**
- Automatically detects if account exists
- Creates new accounts with user confirmation
- Links transactions to correct accounts

**3-Step Wizard UI**
1. **Upload**: Select PDF file
2. **Select**: Choose/confirm account
3. **Review**: Review transactions before import

#### Usage Flow
1. Navigate to Transactions screen
2. Tap "Import from PDF" button
3. Select PDF bank statement file
4. Enter password if required
5. Review detected account details
6. Confirm or create new account
7. Review parsed transactions
8. Tap "Import" to add to Nexus

#### Technical Implementation
- **Service**: `lib/core/services/pdf_parsing_service.dart`
- **Models**: `ParsedBankStatement`, `ParsedTransaction`
- **UI**: 3-step wizard with professional design
- **Algorithm**: Levenshtein distance for duplicate detection
- **Integration**: Firestore for data persistence

#### Setup Requirements
```bash
flutter pub add pdfx
```

---

## Technical Architecture

### Project Structure
```
lib/
├── core/                          # Core services and utilities
│   ├── auth/                      # Authentication services
│   ├── theme/                     # Theme provider and design system
│   ├── services/                  # Core business services
│   │   ├── pdf_parsing_service.dart
│   │   ├── transaction_service.dart
│   │   ├── ai_service.dart
│   │   ├── bike_service.dart
│   │   ├── budget_service.dart
│   │   └── investment_service.dart
│   ├── models/                    # Data models
│   │   ├── transaction.dart
│   │   ├── account.dart
│   │   ├── bike.dart
│   │   ├── investment.dart
│   │   ├── goal.dart
│   │   └── debt.dart
│   ├── providers/                 # State management
│   │   ├── transaction_provider.dart
│   │   ├── budget_provider.dart
│   │   ├── investment_provider.dart
│   │   └── bike_provider.dart
│   └── widgets/                   # Reusable core widgets
│       └── modern/                # Modern UI components
│
├── screens/                       # Main screens
│   ├── login_screen.dart         # Authentication
│   └── main_screen.dart          # Navigation controller
│
├── modules/                       # Feature modules
│   ├── dashboard/                 # Dashboard screens
│   ├── finance/                   # Transactions & accounts
│   ├── insights/                  # AI insights
│   ├── bike/                      # Vehicle tracking
│   ├── investments/               # Portfolio management
│   ├── budgets/                   # Budget management
│   ├── goals/                     # Goal tracking
│   ├── debts/                     # Debt management
│   ├── subscriptions/             # Subscription tracking
│   ├── nbox/                      # Notification inbox
│   └── more/                      # Settings & preferences
│
└── firebase_options.dart          # Firebase configuration
```

### Architecture Principles
- **Clean Architecture**: Separation of concerns with clear layers
- **UI Separation**: Dedicated UI files for visual rendering (non-programmers can edit safely)
- **Provider Pattern**: State management with Provider package
- **Service Layer**: Business logic isolated from UI
- **Firebase Integration**: Real-time sync and cloud storage

---

## Design System

### Design Philosophy
The Nexus app features a modern, Revolut-inspired design language:
- **Dark-first aesthetics** with gradient backgrounds
- **Glassmorphism effects** for depth and visual hierarchy
- **Clean typography** with clear information hierarchy
- **Smooth animations** and micro-interactions
- **Accessible colors** with high contrast ratios

### Core Theme Files
```
lib/core/theme/
├── app_colors.dart          # Color palette and gradients
├── app_typography.dart      # Typography system
├── app_spacing.dart         # Spacing, sizing, shadows, animations
└── app_theme.dart           # Main theme configuration
```

### Color System

#### Brand Colors
- **Primary Blue**: `#2952CC` - Main brand color, CTAs, highlights
- **Accent Teal**: `#00D4AA` - Success states, positive actions
- **Accent Purple**: `#8B5CF6` - Premium features, investments
- **Accent Pink**: `#EC4899` - Credit cards, debt
- **Accent Orange**: `#FF9500` - Crypto, warnings

#### Semantic Colors
- **Success**: `#10B981` - Income, positive changes
- **Warning**: `#F59E0B` - Alerts, important notices
- **Error**: `#EF4444` - Errors, expenses
- **Info**: `#3B82F6` - Informational states

#### Neutral Colors (Dark Mode)
- **neutral900**: `#0A0A0A` - Primary background
- **neutral800**: `#1A1A1A` - Secondary background
- **neutral700**: `#2A2A2A` - Borders, dividers
- **cardDark**: `#1E1E2D` - Card background
- **cardDarkElevated**: `#252538` - Elevated cards

### Typography Scale

#### Display Styles (Hero Text)
- **displayLarge**: 56px, Bold - Onboarding, splash screens
- **displayMedium**: 44px, Bold - Feature highlights
- **displaySmall**: 36px, SemiBold - Section headers

#### Headline Styles (Page Titles)
- **headlineLarge**: 32px, Bold - Main page titles
- **headlineMedium**: 28px, SemiBold - Section titles
- **headlineSmall**: 24px, SemiBold - Subsection titles

#### Title Styles (Card Headers)
- **titleLarge**: 22px, SemiBold - Card titles
- **titleMedium**: 18px, SemiBold - List headers
- **titleSmall**: 16px, Medium - Item titles

#### Body Styles (Content)
- **bodyLarge**: 16px, Regular - Main content
- **bodyMedium**: 14px, Regular - Secondary content
- **bodySmall**: 12px, Regular - Captions, hints

#### Label Styles (UI Elements)
- **labelLarge**: 14px, SemiBold - Buttons, CTAs
- **labelMedium**: 12px, SemiBold - Chips, tags
- **labelSmall**: 10px, Medium - Micro labels

### Modern UI Components
Reusable components available in `lib/core/widgets/modern/modern_widgets.dart`:
- Modern cards with glassmorphism
- Gradient buttons
- Animated progress bars
- Chart components
- Input fields with modern styling

---

## Setup & Configuration Guides

### Google Sign-In Setup

**Common Issues:**
1. **SHA-1 Certificate Mismatch**
2. **Package Name Mismatch**
3. **Google Services JSON Not Updated**

**Quick Fix Steps:**
1. Get SHA-1 fingerprint:
   ```bash
   cd android
   ./gradlew signingReport
   ```
2. Add SHA-1 to Firebase Console:
   - Go to Project Settings → Your Apps → Android app
   - Add SHA-1 certificate fingerprint
   - Download updated `google-services.json`
3. Replace old `google-services.json`:
   ```bash
   # Backup old file
   mv android/app/google-services.json android/app/google-services.json.bak
   # Add new file to android/app/
   ```
4. Clean and rebuild:
   ```bash
   flutter clean
   flutter pub get
   cd android && ./gradlew clean
   cd .. && flutter run
   ```

**Troubleshooting:**
- Verify package name matches in:
  - `android/app/build.gradle`
  - Firebase Console
  - `google-services.json`
- Ensure OAuth 2.0 Client ID created in Google Cloud Console
- Check if Google Sign-In is enabled in Firebase Authentication

### Android Auto Setup

#### Requirements
- Android Auto app installed on test device
- Android 6.0 (API 23) or higher
- Developer mode enabled in Android Auto

#### Configuration Steps
1. **Add Android Auto Dependencies** (already configured)
2. **Update AndroidManifest.xml**:
   ```xml
   <uses-feature
       android:name="android.hardware.type.automotive"
       android:required="false" />
   ```
3. **Enable Developer Mode**:
   - Open Android Auto app
   - Tap "About" 10 times
   - Enable "Unknown sources"
4. **Test on Device**:
   ```bash
   flutter run
   # Then open Android Auto app
   ```

Detailed guide: See `ANDROID_AUTO_SETUP.md` and `ANDROID_AUTO_INTEGRATION.md`

### Firebase Configuration

**Required Firebase Services:**
- Firebase Authentication (Email/Password, Google Sign-In)
- Cloud Firestore (Database)
- Firebase Analytics (Optional)
- Cloud Functions (For advanced features)

**Setup:**
1. Create Firebase project at console.firebase.google.com
2. Add Android app with package name
3. Download `google-services.json` → `android/app/`
4. Add iOS app and download `GoogleService-Info.plist` → `ios/Runner/`
5. Enable Authentication methods in Firebase Console
6. Set up Firestore security rules (see `firestore.rules`)

### Firestore Security Rules

Key rules implemented in `firestore.rules`:
- Users can only access their own data
- Family sharing with permission checks
- Transaction validation
- Account ownership verification

---

## Feature Implementation Status

### ✅ Fully Implemented
- Core dashboard with net worth tracking
- Account management (assets/liabilities)
- Transaction management (manual, SMS, PDF)
- Budget management with salary-based allocation and rollover
- Bike/vehicle tracking module with fuel efficiency
- Trip tracking and odometer management
- PDF bank statement importer with duplicate detection
- Investment portfolio tracking (stocks, mutual funds, crypto, gold, real estate)
- Goal tracking and progress monitoring
- Debt/loan management
- Subscription tracking and monitoring
- Notification inbox (NBox) for pending transactions
- Modern design system with dark theme
- Google Sign-In authentication
- Firebase real-time sync
- Biometric authentication
- Gmail transaction sync (basic)
- Backup to Google Drive

### ⏳ Planned / Future Features
- Advanced AI-powered insights and predictions
- Family sharing and multi-user support
- Export to PDF/Excel reports
- Multi-currency support
- Voice commands
- Enhanced analytics dashboards
- Automated bill payment reminders

---

## Quick Command Reference

### Development
```bash
# Run app
flutter run

# Run on specific device
flutter devices
flutter run -d <device-id>

# Build APK
flutter build apk --release

# Clean build
flutter clean && flutter pub get

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
dart format lib/
```

### Firebase
```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Firestore indexes
firebase deploy --only firestore:indexes

# View logs
firebase functions:log
```

### Android
```bash
# Get SHA-1
cd android && ./gradlew signingReport

# Clean Gradle
cd android && ./gradlew clean

# Build APK directly
cd android && ./gradlew assembleRelease
```

---

## Support & Resources

### Documentation Files
- **README.md** - Project overview and getting started
- **This File** - Complete features documentation

### Key Directories
- `/lib` - Application source code
- `/assets` - Images, fonts, animations
- `/android` - Android-specific configuration
- `/ios` - iOS-specific configuration

### External Links
- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Material Design 3](https://m3.material.io/)

---

**End of Documentation**

*This is a living document. Last updated: January 8, 2026*
