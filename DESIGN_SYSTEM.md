# Nexus Modern Design System

## Overview

The Nexus app now features a modern, Revolut-inspired design language that focuses on:
- **Dark-first aesthetics** with gradient backgrounds
- **Glassmorphism effects** for depth and visual hierarchy
- **Clean typography** with clear information hierarchy
- **Smooth animations** and micro-interactions
- **Accessible colors** with high contrast ratios

## Design System Files

### Core Theme Files

```
lib/core/theme/
├── app_colors.dart          # Color palette and gradients
├── app_typography.dart      # Typography system
├── app_spacing.dart         # Spacing, sizing, shadows, animations
└── app_theme.dart           # Main theme configuration
```

### Modern UI Components

```
lib/core/widgets/modern/
└── modern_widgets.dart      # Reusable modern components
```

## Color System

### Brand Colors
- **Primary Blue**: `#2952CC` - Main brand color, used for CTAs and highlights
- **Accent Teal**: `#00D4AA` - Success states, positive actions
- **Accent Purple**: `#8B5CF6` - Premium features, investments
- **Accent Pink**: `#EC4899` - Credit cards, debt
- **Accent Orange**: `#FF9500` - Crypto, warnings

### Semantic Colors
- **Success**: `#10B981` - Income, positive changes
- **Warning**: `#F59E0B` - Alerts, important notices
- **Error**: `#EF4444` - Errors, expenses
- **Info**: `#3B82F6` - Informational states

### Neutral Colors (Dark Mode First)
- **neutral900**: `#0A0A0A` - Primary background
- **neutral800**: `#1A1A1A` - Secondary background
- **neutral700**: `#2A2A2A` - Borders, dividers
- **cardDark**: `#1E1E2D` - Card background
- **cardDarkElevated**: `#252538` - Elevated cards

## Typography Scale

### Display Styles (Hero Text)
- **displayLarge**: 56px, Bold - Onboarding, splash screens
- **displayMedium**: 44px, Bold - Feature highlights
- **displaySmall**: 36px, SemiBold - Section headers

### Headline Styles (Page Titles)
- **headlineLarge**: 32px, Bold - Main page titles
- **headlineMedium**: 28px, SemiBold - Section titles
- **headlineSmall**: 24px, SemiBold - Subsection titles

### Title Styles (Card Headers)
- **titleLarge**: 22px, SemiBold - Card titles
- **titleMedium**: 18px, SemiBold - List headers
- **titleSmall**: 16px, Medium - Item titles

### Body Styles (Content)
- **bodyLarge**: 16px, Regular - Main content
- **bodyMedium**: 14px, Regular - Secondary content
- **bodySmall**: 12px, Regular - Captions, hints

### Label Styles (UI Elements)
- **labelLarge**: 14px, SemiBold - Buttons, CTAs
- **labelMedium**: 12px, SemiBold - Chips, tags
- **labelSmall**: 10px, Medium - Micro labels

### Currency Styles (Special)
- **currencyLarge**: 48px, Bold - Main balance displays
- **currencyMedium**: 32px, Bold - Card balances
- **currencySmall**: 20px, SemiBold - List amounts

## Spacing System

Based on 4px grid:
- **xs**: 4px
- **sm**: 8px
- **md**: 12px
- **lg**: 16px
- **xl**: 20px
- **xl2**: 24px
- **xl3**: 28px
- **xl4**: 32px
- **xl5**: 40px
- **xl6**: 48px

### Border Radius
- **radiusSm**: 8px - Small elements
- **radiusMd**: 12px - Buttons, inputs
- **radiusLg**: 16px - Cards
- **radiusXl**: 20px - Large cards
- **radiusFull**: 9999px - Circular elements

## Modern Components

### 1. ModernBalanceCard
Large gradient card displaying balance with glassmorphic styling.

```dart
ModernBalanceCard(
  title: 'Total Balance',
  amount: 19.98,
  currency: '\$',
  subtitle: 'Personal · All accounts',
  gradientColors: AppColors.blueGradient,
  onTap: () {},
)
```

### 2. GlassCard
Glassmorphic card with blur effect.

```dart
GlassCard(
  padding: AppSpacing.cardPaddingMd,
  child: YourContent(),
)
```

### 3. ModernActionButton
Circular action button with icon and label.

```dart
ModernActionButton(
  icon: Icons.add,
  label: 'Add money',
  onTap: () {},
  backgroundColor: AppColors.cardDark,
)
```

### 4. ModernAccountTile
List tile for displaying accounts with icons and balances.

```dart
ModernAccountTile(
  name: 'Cash',
  balance: '\$14',
  icon: Icons.money,
  iconColor: AppColors.success,
  percentage: '71%',
  onTap: () {},
)
```

### 5. ModernTransactionTile
Transaction list item with icon, title, subtitle, and amount.

```dart
ModernTransactionTile(
  title: 'SGD → USD',
  subtitle: 'Today, 23:27',
  amount: '\$2',
  isIncome: true,
  icon: Icons.currency_exchange,
  iconColor: AppColors.accentTeal,
  onTap: () {},
)
```

## Gradients

### Pre-defined Gradients
```dart
// Dark gradient background
AppColors.darkGradient

// Blue brand gradient
AppColors.blueGradient

// Teal gradient
AppColors.tealGradient

// Purple gradient
AppColors.purpleGradient
```

### Usage
```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: AppColors.blueGradient,
    ),
  ),
)
```

## Shadows & Effects

### Card Shadows
```dart
// Small shadow
decoration: BoxDecoration(
  boxShadow: AppShadows.cardShadowSm,
)

// Medium shadow (default)
decoration: BoxDecoration(
  boxShadow: AppShadows.cardShadowMd,
)

// Large shadow
decoration: BoxDecoration(
  boxShadow: AppShadows.cardShadowLg,
)
```

### Colored Shadows
```dart
BoxDecoration(
  boxShadow: [
    AppShadows.coloredShadow(AppColors.primaryBlue),
  ],
)
```

### Glow Effect
```dart
BoxDecoration(
  boxShadow: [
    AppShadows.glow(AppColors.accentTeal, blur: 20, opacity: 0.5),
  ],
)
```

## Animations

### Durations
```dart
AnimatedContainer(
  duration: AppAnimations.fast,      // 150ms
  // or
  duration: AppAnimations.normal,    // 250ms
  // or
  duration: AppAnimations.slow,      // 400ms
  curve: AppAnimations.defaultCurve,
)
```

### Curves
- `AppAnimations.defaultCurve` - easeInOutCubic
- `AppAnimations.bounceCurve` - easeOutBack
- `AppAnimations.smoothCurve` - easeOut
- `AppAnimations.spring` - elasticOut
- `AppAnimations.ease` - easeInOut

## Migration Guide

### Updating Existing Screens

1. **Import new theme files**:
```dart
import 'package:nexus/core/theme/app_colors.dart';
import 'package:nexus/core/theme/app_typography.dart';
import 'package:nexus/core/theme/app_spacing.dart';
import 'package:nexus/core/widgets/modern/modern_widgets.dart';
```

2. **Replace old color constants**:
```dart
// Old
Color.fromRGBO(0, 122, 255, 1)

// New
AppColors.primaryBlue
```

3. **Use typography styles**:
```dart
// Old
TextStyle(fontSize: 24, fontWeight: FontWeight.bold)

// New
AppTypography.headlineSmall
```

4. **Apply consistent spacing**:
```dart
// Old
EdgeInsets.all(16)

// New
AppSpacing.cardPaddingMd
// or
const EdgeInsets.all(AppSpacing.lg)
```

5. **Use modern components**:
Replace custom cards with `ModernBalanceCard`, `GlassCard`, or other pre-built components.

## Best Practices

### Do's ✅
- Use semantic color names (`AppColors.success`) instead of raw hex codes
- Apply typography styles consistently
- Use the spacing scale for margins, padding, and gaps
- Leverage pre-built components for consistency
- Add appropriate shadows to create depth
- Use gradients for primary surfaces (hero cards, backgrounds)

### Don'ts ❌
- Don't use arbitrary spacing values (use the 4px grid)
- Don't mix old and new color systems in the same screen
- Don't hardcode text styles - use AppTypography
- Don't create one-off card styles - use or extend modern components
- Don't use pure black (#000000) or white (#FFFFFF) without opacity

## Screen Examples

### Modern Dashboard
See `lib/modules/dashboard/modern_dashboard_screen.dart` for a complete implementation featuring:
- Gradient background
- Modern balance card
- Quick action buttons
- Transaction list with glassmorphic cards

### Implementing a New Screen

```dart
import 'package:flutter/material.dart';
import 'package:nexus/core/theme/app_colors.dart';
import 'package:nexus/core/theme/app_typography.dart';
import 'package:nexus/core/theme/app_spacing.dart';
import 'package:nexus/core/widgets/modern/modern_widgets.dart';

class MyModernScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppColors.darkGradient,
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: Padding(
              padding: AppSpacing.screenPaddingAll,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Screen Title',
                    style: AppTypography.headlineLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Your content here
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

## Resources

- **Figma Design File**: [Link to design file]
- **Color Palette**: See `app_colors.dart` for complete list
- **Component Library**: See `modern_widgets.dart`
- **Example Screens**: Check `modules/dashboard/modern_dashboard_screen.dart`

## Questions?

For design system questions or contributions, refer to the project documentation or create an issue in the repository.
