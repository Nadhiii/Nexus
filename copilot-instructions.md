---

## STRICT CODE GENERATION & REFACTORING RULES

1. ZERO TOLERANCE FOR FRAMEWORK COLORS: Never generate code using raw Flutter `Colors.*` (e.g., `Colors.orange`, `Colors.white`, `Colors.transparent`). You must exclusively use `AppColors.*` equivalents from `lib/core/theme/app_colors.dart`.
2. OPACITY HANDLING: Replace all instances of `Colors.white.withValues(alpha: ...)` with `AppColors.whiteDim`, `AppColors.whiteLight`, or `AppColors.white12`.
3. RADIUS CONSISTENCY: Every card or container must use `AppSpacing.borderRadiusMd` (24.0) or `AppSpacing.borderRadiusLg` (32.0). Never use hardcoded `BorderRadius.circular()`.
4. TYPOGRAPHY ENFORCEMENT: All text components must inherit from `Theme.of(context).textTheme`. Never pass an inline `fontFamily` or hardcoded `fontSize` unless explicitly told to handle a monospace edge-case.

## STRICT FORM FIELD & INPUT DESIGN SYSTEM
Every input field, text field, dropdown, and form-level action must strictly implement the following rules:

1. GEOMETRY & DIMENSIONS:
   - Field Height: All standard TextFormFields must maintain a consistent layout height via internal padding or explicit vertical sizing constraint variables.
   - Border Radius: Input boundaries must match `AppSpacing.borderRadiusLg` (32.0 / Stadium / Pill style matching standard button assets).
   - Padding Grid: Explicitly leverage `AppSpacing.md` (12px vertical) and `AppSpacing.lg` (16px horizontal) inside `EdgeInsets.symmetric`. Never hardcode arbitrary padding values.

2. COLOR SPECIFICATIONS:
   - Surface Fill: Always set `filled: true` using `AppColors.cardElevated` (#334155).
   - Border States:
     - Enabled / Idle Border: Transparent or a clean `AppColors.neutral600` baseline. Never use bright default primary borders.
     - Focused Border: Explicitly highlight matching `AppColors.primaryBlue`.
     - Error State: Swap active outlines to `AppColors.error` textually and visually.

3. TYPOGRAPHY INHERITANCE:
   - Input Content & Input Text: Inherit dynamically from `Theme.of(context).textTheme.bodyLarge` (Inter, 16px).
   - Label & Hint Styles: Force matching scales from `Theme.of(context).textTheme.bodyMedium` styled precisely with `AppColors.textSecondary`.