# UI / UX Design Tokens — Nexus

This document extracts the app's current design tokens from `lib/core/theme/` and highlights immediate inconsistencies found across the codebase.

**Source files**
- [App Colors](lib/core/theme/app_colors.dart#L1-L400)
- [App Typography](lib/core/theme/app_typography.dart#L1-L400)
- [App Spacing](lib/core/theme/app_spacing.dart#L1-L400)
- [App Theme](lib/core/theme/app_theme.dart#L1-L400)
- Font config: [pubspec.yaml](pubspec.yaml#L1-L200)

---

**Primary Colors**
- `primaryBlue` : #4B6BFB (brand primary)
- `primaryBlueDark` : #324AB2
- `primaryBlueLight` : #7B92FF
- Blue gradient: `blueGradient` = [`primaryBlue`, `primaryBlueDark`]

**Secondary / Accent (Pastel) Colors**
- `pastelTeal` : #2DD4BF
- `pastelPurple` : #A78BFA
- `pastelPink` : #F472B6
- `pastelOrange` : #FB923C
- `pastelGreen` : #34D399
- `pastelYellow` : #FACC15
- `pastelIndigo` : #6366F1

**Semantic Colors**
- `success` : #34D399
- `warning` : #FBBF24
- `error` : #F87171
- `info` : #60A5FA

**Backgrounds & Surfaces**
- `backgroundBlack` : ARGB(255,19,20,39) — scaffold background
- `cardSurface` : #1E293B — primary card surface
- `cardElevated` : #334155 — elevated inputs / highlights
- `summaryCardGradient` : [#1E293B, #0F172A]

**Gradients (notable)**
- `profitGradient` : [#065F46, #064E3B]
- `lossGradient` : [#9F1239, #881337]
- `tealGradient`, `purpleGradient`, `indigoGradient` — accent gradients available

**Neutral Scale (aliases present)**
- `neutral900` = `backgroundBlack` (#0F172A used in some gradients)
- `neutral800` = `cardSurface` (#1E293B)
- `neutral700` = `cardElevated` (#334155)
- `neutral600` = #475569
- `neutral500` = #64748B (also `textTertiary`)
- `neutral400` = `textSecondary` (#94A3B8)
- `neutral300`..`neutral50` present for lighter use

**Category & Account Colors**
- `categoryColors` map (examples): `income` → `pastelGreen`, `food` → `pastelPink`, `transport` → `pastelOrange`.
- `accountTypeColors` map (examples): `cash` → `pastelGreen`, `bank` → `info`, `investment` → `pastelPurple`.

---

**Container / Card Styles**
- App-level `cardTheme` (from `AppTheme`):
  - `color`: `AppColors.cardSurface` (#1E293B)
  - `elevation`: 0
  - `margin`: `EdgeInsets.zero`
  - `shape`: `RoundedRectangleBorder` with `AppSpacing.borderRadiusMd` (24.0)
- Standard card paddings (from `AppSpacing`):
  - `cardPadding` = 20px
  - `cardPaddingMd` = 16px
  - `cardPaddingLg` = 24px
  - `cardPaddingXl` = 32px
- Inputs: `fillColor` = `AppColors.cardElevated`, border radius = `AppSpacing.borderRadiusLg` (32.0)

**Buttons**
- Elevated buttons: background `AppColors.primaryBlue`, foreground white, `minimumSize` height = `AppSpacing.buttonHeightMd` (56.0), shape = `StadiumBorder()`

---

**Typography Rules**
- Fonts configured in `pubspec.yaml`:
  - `Inter` (variable) for body text — family name: `Inter` ([pubspec.yaml](pubspec.yaml#L1-L200))
  - `RammettoOne` for display/headlines — family name: `RammettoOne`

- Headline / Display (RammettoOne):
  - `displayLarge` — 48px, w400, line-height ~1.1
  - `displayMedium` — 40px, w400
  - `displaySmall` — 36px, w400
  - `headlineLarge` — 32px, w400
  - `headlineMedium` — 24px, w400
  - `headlineSmall` — 20px, w400

- Currency styles (RammettoOne for numeric emphasis):
  - `currencyLarge` — 36px, w900, letterSpacing -1.0
  - `currencyMedium` — 26px, w900

- Body / List (Inter):
  - `bodyLarge` — 16px, w400, color `textPrimary`
  - `bodyMedium` — 14px, w400, color `textSecondary`
  - `bodySmall` — 12px, w400

- Titles & Labels (Inter, semibold):
  - titleLarge 22px w600, titleMedium 16px w600, label styles 14/12/11 w600

- `TextTheme` assembled as `AppTypography.textTheme` and applied in `AppTheme`.

---

**Spacing & Radius System**
- Base unit: 4px
- Scale (common): `xs`=4, `sm`=8, `md`=12, `lg`=16, `xl`=20, `xl2`=24, `xl3`=32, `xl4`=40
- Radius tokens:
  - `radiusXs` = 8px (tags)
  - `radiusSm` = 16px (buttons/inputs)
  - `radiusMd` = 24px (cards/containers)
  - `radiusLg` = 32px (modals/dialogs)
  - `radiusFull` = 999px (pill)
- Prebuilt radii: `borderRadiusXs/Sm/Md/Lg/Xl/Full` are provided for consistency
- Icon sizes: 24/32/40. Button heights: 40/56/64.

---

**Immediate inconsistencies & recommendations (observed scan)**

- Mixed use of `Colors.*` literals instead of `AppColors` tokens in several places. Prefer canonical tokens.
  - Example: asset color mapping uses framework colors: [lib/modules/investments/investment_portfolio_screen.dart](lib/modules/investments/investment_portfolio_screen.dart#L752-L763) (returns `Colors.orange`, `Colors.amber`, `Colors.blue`, `Colors.purple`, `Colors.grey`).
  - Example: Many places use `Colors.white.withValues(alpha: ...)` rather than `AppColors.whiteDim`, `whiteLight`, or `white12` aliases (see [lib/modules/investments/widgets/add_investment_modal.dart](lib/modules/investments/widgets/add_investment_modal.dart#L140-L150) and [lib/screens/main_screen.dart](lib/screens/main_screen.dart#L170-L176)).

- Occasional direct usage of `Colors.teal`, `Colors.purple`, `Colors.amber` mixed with `AppColors.accentTeal` etc: prefer `AppColors` equivalents for theme coherence. Example: [lib/modules/payday/payday_checklist_sheet.dart](lib/modules/payday/payday_checklist_sheet.dart#L621-L629).

- Small comment vs value mismatch: `AppSpacing` file says "We moved from 'Squared' (8px) to 'Soft' (16px+)" but `radiusXs` remains 8px; not an error but worth reviewing if `radiusXs` should be removed or renamed.

- A few places use hardcoded `fontFamily: 'monospace'` (e.g., [lib/modules/pdf_import/pdf_password_manager_screen.dart](lib/modules/pdf_import/pdf_password_manager_screen.dart#L200-L212)) — decide whether to keep this or map to a defined token.

- Some components use `Colors.transparent` / `Colors.black` helpers instead of `AppColors.transparent` / `AppColors.black` aliases — minor but worth standardizing.

- Gradients & dark variants: there are several overlapping gradient definitions (e.g., `summaryCardGradient`, `netWorthPositiveGradient`, `netWorthNegativeGradient`) — consider centralizing gradient usage docs (already present but ensure consistent application across screens).

---

**Suggested immediate fixes (small, actionable)**
- Replace direct `Colors.*` usages with `AppColors` equivalents where a semantic token exists.
- Replace `Colors.white.withValues(alpha: ...)` patterns with `AppColors.whiteDim`, `whiteLight`, `white12`, or add missing opacity tokens if needed.
- Consider adding a small `AppColors` alias map for asset/legacy colors used in `investment` mapping to remove `Colors.*` returns.
- Review `AppSpacing` comment and `radiusXs` intent; either update comment or adjust token.

---

If you want, I can:
- Create a lint rule or quick codemod to flag `Colors.*` and `fontFamily` literals and propose replacements.
- Run an automated pass to replace obvious `Colors.white.withValues(alpha: x)` with the best `AppColors` opacity alias.

