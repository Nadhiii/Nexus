# Nexus - Personal Finance Management App

A comprehensive personal finance management application built with Flutter, designed to help users take complete control of their financial life through intelligent tracking, AI-powered insights, and smart budgeting tools.

## 🎯 Features

### Core Features
- **Smart Dashboard**: Real-time net worth overview with AI-powered insights
- **Transaction Management**: Multi-source input with smart categorization
- **Budget Management**: Dynamic salary-based budget allocation
- **AI-Powered Insights**: Spending pattern analysis and recommendations
- **Goal Tracking**: SMART financial goals with progress visualization
- **Reports & Analytics**: Comprehensive financial reports and charts
- **Family Sharing**: Multi-user support for family financial management

### Technical Features
- **Dark-First Design**: Beautiful dark theme with light mode support
- **Real-time Sync**: Firebase Firestore for live data synchronization
- **Authentication**: Firebase Auth with email/password and Google Sign-in
- **Responsive UI**: Material Design 3 with custom theming
- **Cross-platform**: Android and iOS support

## 🏗️ Architecture

### Project Structure
```
lib/
├── core/                          # Core services and utilities
│   ├── auth/                      # Authentication services
│   ├── theme/                     # Theme provider and design system
│   └── services/                  # Core business services
├── screens_new/                   # Clean screen architecture
│   ├── main_screen.dart          # Main navigation controller
│   ├── dashboard/                 # Dashboard and home screens
│   ├── insights/                  # AI insights and analytics
│   ├── reports/                   # Financial reports and charts
│   ├── transactions/              # Transaction management
│   └── settings/                  # App settings and preferences
├── widgets/                       # Reusable UI components
│   ├── dashboard/                 # Dashboard-specific widgets
│   ├── charts/                    # Financial visualization components
│   └── common/                    # Shared UI elements
├── services/                      # Business logic services
│   ├── ai/                        # AI analysis services
│   ├── budget/                    # Budget management
│   └── analytics/                 # Financial analytics
└── utils/                         # Utility functions and helpers
```

### Data Models
- **User**: User profile and authentication data
- **Account**: Financial accounts (assets/liabilities)
- **Transaction**: Income and expense transactions
- **Category**: Transaction categories with icons and colors
- **Goal**: Financial goals with progress tracking
- **Subscription**: Recurring bills and subscriptions
- **Debt**: Loan and debt management

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Android Studio / VS Code
- Firebase project setup
- Android/iOS development environment

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd nexus
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project
   - Enable Authentication (Email/Password, Google Sign-in)
   - Enable Firestore Database
   - Download and add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

4. **Run the app**
   ```bash
   flutter run
   ```

## 🎨 Design System

### Color Palette
- **Primary Background**: `#121212` (Dark) / `#FFFFFF` (Light)
- **Surface Background**: `#1E1E1E` (Dark) / `#F5F5F5` (Light)
- **Primary Accent**: `#00A99D` (Teal)
- **Income Green**: `#4CAF50`
- **Expense Red**: `#F44336`
- **Highlight Amber**: `#FFC107`

### Typography
- **Headers**: Rammetto One (Bold, distinctive)
- **Body Text**: Inter (Clean, readable)
- **Numbers**: JetBrains Mono (Clear financial data display)

## 📱 Screenshots

### Dashboard
- Net worth overview with real-time calculations
- Smart insights widget with AI recommendations
- Quick actions for common tasks
- Recent transactions preview
- Primary goal progress tracking

### Transactions
- Comprehensive transaction management
- Multi-source input (manual, SMS, bank import)
- Smart categorization with AI
- Advanced filtering and search
- Bulk operations support

### Insights
- AI-powered spending pattern analysis
- Budget optimization recommendations
- Savings opportunities identification
- Predictive analytics and forecasting

### Reports
- Net worth trend visualization
- Cash flow analysis
- Category breakdown charts
- Monthly comparisons
- Export capabilities (PDF/Excel)

## 🔧 Configuration

### Firebase Configuration
1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Authentication with Email/Password and Google Sign-in
3. Create a Firestore database in test mode
4. Download configuration files and add them to your project

### Environment Variables
Create a `.env` file in the project root:
```env
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_API_KEY=your-api-key
```

## 🛠️ Development

### State Management
- **Provider Pattern**: For theme management and global state
- **Local State**: StatefulWidget for screen-specific state
- **Firebase Realtime**: For live data synchronization

### Key Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.3
  cloud_firestore: ^5.5.0
  provider: ^6.1.2
  google_fonts: ^6.2.1
  fl_chart: ^0.69.0
  shared_preferences: ^2.3.2
  flutter_secure_storage: ^9.2.2
```

## 📊 Data Flow

1. **User Authentication**: Firebase Auth handles user login/signup
2. **Data Storage**: Firestore stores all financial data
3. **Real-time Sync**: Changes are synchronized across devices
4. **AI Analysis**: Backend processes spending patterns
5. **Insights Generation**: AI provides personalized recommendations

## 🔒 Security

- **Authentication**: Firebase Auth with biometric support
- **Data Encryption**: Sensitive data encrypted in transit and at rest
- **Access Control**: User-based data isolation
- **Secure Storage**: Local sensitive data stored securely

## 🚀 Deployment

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Material Design team for design guidelines
- Open source community for various packages

## 📞 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation

---

**Nexus** - Your Personal Financial Intelligence Platform
