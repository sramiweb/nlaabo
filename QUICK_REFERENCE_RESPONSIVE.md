# Quick Reference: Responsive Design Patterns

## Common Replacements

### Spacing
```dart
// ❌ BEFORE
const SizedBox(height: 8)
const SizedBox(height: 12)
const SizedBox(height: 16)
const SizedBox(height: 24)

// ✅ AFTER
SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'sm'))
SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'md'))
SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'lg'))
SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'xl'))
```

### Padding
```dart
// ❌ BEFORE
padding: const EdgeInsets.all(12)
padding: const EdgeInsets.all(16)
padding: const EdgeInsets.symmetric(horizontal: 16)

// ✅ AFTER
padding: ResponsiveConstants.getResponsivePadding(context, 'md')
padding: ResponsiveConstants.getResponsivePadding(context, 'lg')
padding: ResponsiveUtils.getResponsiveHorizontalPadding(context)
```

### Container Heights
```dart
// ❌ BEFORE
Container(height: 48)
Container(height: 56)

// ✅ AFTER
Container(height: ResponsiveUtils.getButtonHeight(context))
Container(height: context.buttonHeight)
```

### Border Radius
```dart
// ❌ BEFORE
borderRadius: BorderRadius.circular(12)
borderRadius: BorderRadius.circular(16)

// ✅ AFTER
borderRadius: BorderRadius.circular(context.borderRadius)
borderRadius: BorderRadius.circular(context.borderRadius * 1.33)
```

### Icon Sizes
```dart
// ❌ BEFORE
Icon(Icons.search, size: 20)
Icon(Icons.person, size: 48)

// ✅ AFTER
Icon(Icons.search, size: ResponsiveUtils.getIconSize(context, 20))
Icon(Icons.person, size: ResponsiveUtils.getIconSize(context, 48))
```

### Font Sizes
```dart
// ❌ BEFORE
style: TextStyle(fontSize: 16)

// ✅ AFTER
style: ResponsiveTextUtils.getScaledTextStyle(
  context,
  TextStyle(fontSize: 16),
)
```

## Spacing Scale Reference

```dart
'xs': 4.0    // Extra small gaps
'xs2': 6.0   // Slightly more breathing room
'sm': 8.0    // Component internal spacing
'sm2': 10.0  // Between small elements
'md': 12.0   // Standard component spacing
'md2': 14.0  // Between medium elements
'lg': 16.0   // Section spacing, card padding
'lg2': 20.0  // Between major sections
'xl': 24.0   // Major section breaks
'xl2': 28.0  // Page section spacing
'2xl': 32.0  // Large section breaks
'2xl2': 40.0 // Generous spacing
'3xl': 48.0  // Page breaks
'4xl': 64.0  // Ultra-wide screen spacing
```

## Landscape Optimization

```dart
// Wrap form fields for automatic landscape layout
OrientationHelper.buildFormFieldLayout(
  context: context,
  fields: [
    _buildField1(),
    _buildField2(),
    _buildField3(),
    _buildField4(),
  ],
)
// Portrait: vertical stack
// Landscape: 2-column grid
```

## SafeArea Pattern

```dart
// Always wrap body content
Scaffold(
  appBar: AppBar(...),
  body: SafeArea(  // ✅ Add this
    child: YourContent(),
  ),
)
```

## Responsive Constraints

```dart
// Limit content width on large screens
Container(
  constraints: BoxConstraints(
    maxWidth: ResponsiveUtils.getMaxContentWidth(context),
  ),
  child: YourContent(),
)
```

## Context Extensions

```dart
// Use these shortcuts
context.isMobile
context.isTablet
context.isDesktop
context.isLandscape
context.buttonHeight
context.borderRadius
context.responsivePadding
context.maxContentWidth
```
