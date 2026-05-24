# Nexus - Personal Finance Management App

A comprehensive Flutter-based personal finance management app with intelligent automation, built with Firebase backend.

## Overview

Nexus helps you manage your financial life with features ranging from daily transaction tracking to investment management, vehicle maintenance, and family expense sharing. Built with Material Design and a modern dark theme.

---

## Core Features

### Finance Management

**Accounts**
- Create and manage multiple accounts (Savings, Salary, Investment, Cash, etc.)
- Real-time balance tracking
- Support for card details, bank name, and account numbers
- Color-coded account identification
- Account activity tracking

**Transactions**
- Track income, expenses, and account transfers
- Attach receipts and notes
- Bulk operations (multi-select, batch delete)
- Transaction history with advanced filtering
- Smart duplicate detection

**Budgets**
- Set budgets by category with flexible time periods (weekly, monthly, quarterly, etc.)
- Real-time spending tracking with progress indicators
- Alert notifications at 80% threshold
- Overspend detection and warnings
- Daily spending recommendations
- Budget adherence tracking

**Categories**
- Predefined and custom categories with emoji icons
- Color-coded organization
- Category-based reports and filtering

---

### Investment Tracking

**Supported Investment Types**:
- Mutual Funds (with SIP tracking)
- Stocks
- Cryptocurrencies
- Gold
- Real Estate
- Custom investments

**Features**:
- Track invested amount vs current value
- Automatic profit/loss calculation
- Performance metrics and trends
- ISIN/folio tracking for mutual funds
- NAV and unit tracking
- Investment timeline and history

---

### Debt & Loan Management

**Loan Types**:
- Personal, Home, Car, Education, Business loans
- Gold loans, Two-wheeler loans
- Credit cards
- Custom loan types

**Features**:
- EMI calculation and tracking
- Payment schedules with reminders
- Interest vs principal breakdown
- Remaining months and payoff date
- Overdue detection and alerts
- Payment history tracking

**Family Debts (IOUs)**:
- Track money owed to/by family members
- Payment record tracking
- Settlement status and history
- Net balance calculations

---

### Subscription Management

**Features**:
- Track recurring subscriptions with various frequencies (daily to yearly)
- Automatic due date calculation
- Overdue detection and warnings
- Total monthly subscription cost analysis
- Category-wise subscription breakdown
- Status tracking (active/inactive)

---

### Savings Goals

**Features**:
- Set financial goals with target amounts and dates
- Progress tracking with visual indicators
- Remaining amount and time calculations
- Goal achievement notifications
- Milestone celebrations
- Linked account tracking

---

### Vehicle/Bike Management

**Garage Features**:
- Manage multiple vehicles
- Track make, model, year, registration
- Insurance tracking with expiry alerts
- RTO details management
- Dashboard pinning for quick access

**Fuel & Mileage Tracking**:
- Log fuel entries with odometer readings
- Automatic mileage calculation (km/L)
- Fuel efficiency ratings:
  - Excellent: >25 km/L
  - Good: 20-25 km/L
  - Average: 15-20 km/L
  - Poor: <15 km/L
- Cost per km analysis
- Fuel spending trends

**Document Management**:
- Upload RC, insurance, PUC certificates
- Expiry date tracking with alerts
- Google Drive integration for backups
- Document categorization

**Challan Tracking**:
- Log traffic violations and fines
- Payment tracking with deadlines
- Receipt storage
- Violation type categorization

---


<!-- Smart Automation, AI, and PDF features removed as they are not present in the app. -->

---

### Analytics & Insights

**Reports & Analytics**:
- Spending trends by category
- Income vs expense comparison
- Monthly spending patterns
- Investment performance tracking
- Goal progress analysis
- Export reports (PDF, CSV)
- Custom date range analysis

**Expense Trends**:
- Category-wise trend analysis
- Year-over-year comparison
- Spending forecasts
- Anomaly detection

---

### Family & Shared Expenses

**Expense Splitting**:
- Create shared expenses
- Multiple participants
- Flexible split options:
  - Equal split
  - Custom amounts
  - Percentage-based
- Settlement tracking
- Who paid tracking
- Category assignment

**Family Management**:
- Add and manage family members
- Track shared obligations
- Settlement summaries
- Net balance calculations

---

### Payday Checklist

**Smart Post-Income Actions**:
- Auto-generated checklist after income:
  - Debt EMI payments (with due dates)
  - Family debt obligations
  - Subscription payments
  - Budget allocations
  - Goal contributions
  - Savings transfers

**Priority Levels**:
- Urgent (due within 3 days or overdue)
- High (due within 7 days)
- Medium (due within 14 days)
- Low (suggested/optional)

**Analysis**:
- Total obligations calculation
- Income coverage check
- Suggested savings amount
- Remaining after obligations

---

### Notifications & Alerts

**Smart Notifications**:
- Budget warnings (80% threshold)
- Goal progress and achievements
- Subscription and bill reminders
- Unusual spending alerts
- Transaction confirmations
- Fuel efficiency feedback
- Insurance expiry warnings
- Payment due reminders

**Notification Features**:
- Action buttons for quick response
- Notification history
- Deep linking to relevant screens
- Customizable preferences
- Category-based filtering

---

### Settings & Security

**Biometric Lock**:
- Fingerprint authentication
- Face recognition support
- Secure app access
- Card data encryption

**Backup & Restore**:
- Automatic cloud backup to Firestore
- Complete data restoration
- Profile and metadata backup
- Transaction history preservation

**Theme**:
- Modern dark theme
- Custom color schemes
- Material Design components
- Frosted glass effects

**Notification Settings**:
- Granular control by notification type
- Custom timing preferences
- Enable/disable specific alerts

**Category Management**:
- Create custom categories
- Edit category details (name, emoji, color)
- Category reordering

---

### User Interface

**Navigation**:
Bottom floating navigation bar with 6 tabs:
1. **Home** - Dashboard with financial overview
2. **Wallet** - Accounts and transactions
3. **Wealth** - Investments and analytics
4. **Garage** - Vehicle management
5. **Inbox** - Transaction inbox (if implemented)
6. **More** - Settings and tools

**Design Features**:
- Material Design with custom dark theme
- Frosted glass navigation effects
- Smooth animations and transitions
- Swipe-to-delete actions
- Multi-select operations
- Search and filtering
- Progress indicators
- Color-coded status displays

---

## Technical Stack

**Framework**: Flutter (Dart)

**Backend**:
- Firebase Cloud Firestore (database)
- Firebase Authentication
- Firebase Cloud Storage (documents)
- Firebase Crashlytics (error reporting)

**Integrations**:
- Google Drive (document backup)

**Device Features**:
- Biometric authentication
- File system access
- Android Auto support

**Currency**: Indian Rupee (INR)

---

## Data & Privacy

- All data stored securely in Firebase Cloud Firestore
- User authentication required
- Sensitive data (CVV) stored locally in encrypted storage, not in cloud
- Biometric-protected app access

---

## Key Screens

### Dashboard
- Total balance across accounts
- Recent transactions
- Budget status overview
- Goals progress
- Financial health score
- Quick action buttons

### Finance
- Account detail views
- Transaction history with filtering
- Add/edit transaction screens
- Budget management

### Investments
- Portfolio overview
- Individual investment details
- Performance charts
- Add investment screens

### Debts
- Loan management
- Payment schedules
- Family debt tracking
- EMI calculator

### Garage
- Vehicle list
- Fuel entries
- Mileage statistics
- Document management
- Challan tracking


### Insights
- Financial health dashboard
- Spending trends
- Category breakdowns
- Reports and analytics

### More
- Analytics and reports
- Category management
- Family dashboard
- Expense splitter
- Backup settings
- Notification preferences
- About and help

---

## Getting Started

### Prerequisites
- Flutter SDK
- Firebase project setup

### Installation
1. Clone the repository
2. Run `flutter pub get`
3. Configure Firebase (google-services.json for Android, GoogleService-Info.plist for iOS)
4. Run `flutter run`

---

## Features by Use Case

### For Daily Expense Tracking
Quick transaction entry
Budget alerts

### For Long-term Financial Planning
Goal setting and tracking
Investment portfolio management
Financial health scoring
Spending trend analysis

### For Debt Management
Loan tracking with EMI
Payment reminders
Payoff date calculation
Family debt settlement

### For Vehicle Owners
Mileage tracking
Fuel efficiency monitoring
Document management
Maintenance logging

### For Families
Shared expense splitting
Family member management
Settlement tracking
IOU management

---


## Smart Features Highlights

**Smart Notifications** - Contextual alerts for budgets, goals, and payments
**Trend Analysis** - Spending patterns and forecasts
**Quick Actions** - Payday checklist for post-income tasks

---

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

---


---

## Support

For issues, bugs, or feature requests, please open an issue in the repository.

---

**Built with Flutter**
