# Responsive Fixes - Code Examples

## Quick Reference: Before/After Comparisons

### 1. HOME SCREEN FIXES

#### Fix 1.1: Responsive Card Heights

**File:** `lib/screens/home_screen.dart`

```dart
// ❌ BEFORE (Lines 195-210)
Widget _buildFeaturedMatches(BuildContext context, HomeProvider provider) {
  return FadeInAnimation(
    delay: const Duration(milliseconds: 200),
    child: SizedBox(
      height: 140.0,  // ❌ Fixed height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: provider.featuredMatches.length,
        itemBuilder: (context, index) {
          final match = provider.featuredMatches[index];
          return Padding(
            padding: const EdgeInsets.only(right: 10),  // ❌ Fixed padding
            child: FadeInAnimation(
              delay: Duration(milliseconds: 100 * index),
              child: SizedBox(
                width: 280,  // ❌ Fixed width
                child: MatchCard(key: ValueKey(match.id), match: match),
              ),
            ),
          );
        },
      ),
    ),
  );
}
```

```dart
// ✅ AFTER - Fully Responsive
Widget _buildFeaturedMatches(BuildContext context, HomeProvider provider) {
  return FadeInAnimation(
    delay: const Duration(milliseconds: 200),
    child: SizedBox(
      height: context.getCardHeight(isMatchCard: true),  // ✅ Responsive (160-220px)
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),  // ✅ Design system
        itemCount: provider.featuredMatches.length,
        itemBuilder: (context, index) {
          final match = provider.featuredMatches[index];
          return Padding(
            padding: EdgeInsets.only(right: context.itemSpacing),  // ✅ Responsive (10-24px)
            child: FadeInAnimation(
              delay: Duration(milliseconds: 100 * index),
              child: SizedBox(
                width: context.cardWidth,  // ✅ Responsive (280-400px)
                child: MatchCard(key: ValueKey(match.id), match: match),
              ),
            ),
          );
        },
      ),
    ),
  );
}
```

---

#### Fix 1.2: Responsive Search Field

```dart
// ❌ BEFORE (Lines 90-105)
Widget _buildSearchField(BuildContext context, HomeProvider provider) {
  return Center(
    child: Container(
      constraints: const BoxConstraints(maxWidth: 800),  // ❌ Hardcoded
      height: 44,  // ❌ Fixed height
      child: AppTextField(
        controller: provider.searchController,
        hintText: LocalizationService().translate(TranslationKeys.searchHint),
        prefixIcon: const Icon(Icons.search, size: 20),  // ❌ Fixed icon size
        suffixIcon: provider.searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),  // ❌ Fixed icon size
                onPressed: () => provider.clearSearchController(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            : null,
      ),
    ),
  );
}
```

```dart
// ✅ AFTER - Fully Responsive
Widget _buildSearchField(BuildContext context, HomeProvider provider) {
  return Center(
    child: Container(
      constraints: BoxConstraints(maxWidth: context.maxContentWidth),  // ✅ Responsive
      height: context.buttonHeight,  // ✅ Responsive (44-60px)
      child: AppTextField(
        controller: provider.searchController,
        hintText: LocalizationService().translate(TranslationKeys.searchHint),
        prefixIcon: Icon(
          Icons.search,
          size: ResponsiveUtils.getIconSize(context, 20),  // ✅ Responsive
        ),
        suffixIcon: provider.searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  size: ResponsiveUtils.getIconSize(context, 18),  // ✅ Responsive
                ),
                onPressed: () => provider.clearSearchController(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: ResponsiveUtils.minTouchTargetSize,  // ✅ Accessibility
                  minHeight: ResponsiveUtils.minTouchTargetSize,
                ),
              )
            : null,
      ),
    ),
  );
}
```

---

#### Fix 1.3: Add SafeArea

```dart
// ❌ BEFORE (Lines 45-70)
@override
Widget build(BuildContext context) {
  return Selector<HomeProvider, (bool, String?, bool)>(
    selector: (context, provider) => (provider.isLoading, provider.errorMessage, provider.isUserInTeam),
    builder: (context, data, child) {
      final provider = context.read<HomeProvider>();
      final (isLoading, errorMessage, isUserInTeam) = data;
      
      return isLoading
          ? _buildLoadingState(context)
          : SingleChildScrollView(  // ❌ Missing SafeArea
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(...)
            );
    },
  );
}
```

```dart
// ✅ AFTER - With SafeArea
@override
Widget build(BuildContext context) {
  return Selector<HomeProvider, (bool, String?, bool)>(
    selector: (context, provider) => (provider.isLoading, provider.errorMessage, provider.isUserInTeam),
    builder: (context, data, child) {
      final provider = context.read<HomeProvider>();
      final (isLoading, errorMessage, isUserInTeam) = data;
      
      return SafeArea(  // ✅ Added SafeArea
        child: isLoading
            ? _buildLoadingState(context)
            : SingleChildScrollView(
                padding: context.responsiveHorizontalPadding.copyWith(  // ✅ Responsive
                  top: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                ),
                child: Column(...)
              ),
      );
    },
  );
}
```

---

### 2. CREATE MATCH SCREEN FIXES

#### Fix 2.1: Keyboard-Aware Scrolling

```dart
// ❌ BEFORE (Lines 245-260)
body: Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(...)
  ),
  child: Center(
    child: SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width > 600 ? 48.0 : 24.0,
        vertical: 24.0,  // ❌ Fixed, doesn't account for keyboard
      ),
      child: _isLoadingTeams ? ... : _allTeams.isEmpty ? ... : Container(...)
    ),
  ),
)
```

```dart
// ✅ AFTER - Keyboard-Aware
body: Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(...)
  ),
  child: Center(
    child: SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,  // ✅ Dismiss on drag
      padding: EdgeInsets.only(
        left: context.responsiveHorizontalPadding.left,  // ✅ Responsive
        right: context.responsiveHorizontalPadding.right,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,  // ✅ Keyboard-aware
      ),
      child: _isLoadingTeams ? ... : _allTeams.isEmpty ? ... : Container(...)
    ),
  ),
)
```

---

#### Fix 2.2: Responsive Form Fields

```dart
// ❌ BEFORE (Lines 380-400)
Text(
  '${LocalizationService().translate('match_title')} ${RequiredFieldIndicator.text}',
  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
    fontWeight: FontWeight.w600,
    color: context.colors.textPrimary,
  ),
),
const SizedBox(height: 6),  // ❌ Fixed spacing
EnhancedFormField(
  controller: _titleController,
  labelText: LocalizationService().translate('match_title'),
  hintText: LocalizationService().translate('enter_match_title'),
  prefixIcon: Icon(Icons.title, color: context.colors.primary),
  validator: (value) => validateMatchTitle(value),
  showValidationFeedback: true,
),
```

```dart
// ✅ AFTER - Fully Responsive
Text(
  '${LocalizationService().translate('match_title')} ${RequiredFieldIndicator.text}',
  style: AppTextStyles.getResponsiveLabelText(context).copyWith(  // ✅ Responsive text
    fontWeight: FontWeight.w600,
    color: context.colors.textPrimary,
  ),
  maxLines: 1,  // ✅ Overflow protection
  overflow: TextOverflow.ellipsis,
),
AppSpacing.verticalSm,  // ✅ Design system spacing
EnhancedFormField(
  controller: _titleController,
  labelText: LocalizationService().translate('match_title'),
  hintText: LocalizationService().translate('enter_match_title'),
  prefixIcon: Icon(
    Icons.title,
    color: context.colors.primary,
    size: ResponsiveUtils.getIconSize(context, 20),  // ✅ Responsive icon
  ),
  validator: (value) => validateMatchTitle(value),
  showValidationFeedback: true,
),
```

---

### 3. MATCH CARD FIXES

#### Fix 3.1: Responsive Text and Icons

**File:** `lib/widgets/match_card.dart`

```dart
// ❌ BEFORE (Lines 60-90)
Row(
  children: [
    if (!isRTL) ...[ Container(
        padding: const EdgeInsets.all(6),  // ❌ Fixed padding
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.sports_soccer,
          color: Theme.of(context).colorScheme.primary,
          size: 22,  // ❌ Fixed size
        ),
      ),
      const SizedBox(width: 8),  // ❌ Fixed spacing
    ],
    Expanded(
      child: Text(
        displayTitle,
        style: TextStyle(
          fontSize: context.isMobile ? 13 : 15,  // ⚠️ Better but still hardcoded
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        maxLines: 1,  // ✅ Good
        overflow: TextOverflow.ellipsis,  // ✅ Good
        textAlign: isRTL ? TextAlign.right : TextAlign.left,
      ),
    ),
  ],
)
```

```dart
// ✅ AFTER - Fully Responsive
Row(
  children: [
    if (!isRTL) ...[
      Container(
        padding: EdgeInsets.all(AppSpacing.xs),  // ✅ Design system
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.sm),  // ✅ Design system
        ),
        child: Icon(
          Icons.sports_soccer,
          color: Theme.of(context).colorScheme.primary,
          size: ResponsiveUtils.getIconSize(context, 22),  // ✅ Responsive (20-26px)
        ),
      ),
      SizedBox(width: AppSpacing.sm),  // ✅ Design system
    ],
    Expanded(
      child: Text(
        displayTitle,
        style: AppTextStyles.getResponsiveCardTitle(context).copyWith(  // ✅ Responsive
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: isRTL ? TextAlign.right : TextAlign.left,
      ),
    ),
  ],
)
```

---

#### Fix 3.2: Responsive Info Rows

```dart
// ❌ BEFORE (Lines 140-160)
Widget _buildInfoRow(BuildContext context, IconData icon, String text, Color iconColor) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 11, color: iconColor),  // ❌ Fixed size
      const SizedBox(width: 4),  // ❌ Fixed spacing
      Flexible(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10,  // ❌ Fixed size
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,  // ✅ Good
          overflow: TextOverflow.ellipsis,  // ✅ Good
        ),
      ),
    ],
  );
}
```

```dart
// ✅ AFTER - Fully Responsive
Widget _buildInfoRow(BuildContext context, IconData icon, String text, Color iconColor) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        icon,
        size: ResponsiveUtils.getIconSize(context, 11),  // ✅ Responsive (10-13px)
        color: iconColor,
      ),
      SizedBox(width: AppSpacing.xs),  // ✅ Design system (4px)
      Flexible(
        child: Text(
          text,
          style: AppTextStyles.caption.copyWith(  // ✅ Design system
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w500,
            fontSize: ResponsiveUtils.getTextScaleFactor(context) * 10,  // ✅ Responsive
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}
```

---

### 4. MATCH DETAILS SCREEN FIXES

#### Fix 4.1: Responsive Header

**File:** `lib/screens/match_details_screen.dart`

```dart
// ❌ BEFORE (Lines 240-280)
Card(
  elevation: 3,
  shadowColor: Colors.black.withOpacity(0.15),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  child: Container(
    padding: const EdgeInsets.all(14),  // ❌ Fixed padding
    decoration: BoxDecoration(...),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),  // ❌ Fixed padding
              decoration: BoxDecoration(...),
              child: const Icon(Icons.sports_soccer, color: Colors.white, size: 24),  // ❌ Fixed size
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),  // ❌ Fixed padding
              decoration: BoxDecoration(...),
              child: Text(
                _getLocalizedStatus(match.status),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,  // ❌ Fixed size
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),  // ❌ Fixed spacing
        Text(
          match.displayTitle,
          style: TextStyle(
            fontSize: 18,  // ❌ Fixed size
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            height: 1.2,
          ),
          maxLines: 2,  // ✅ Good
          overflow: TextOverflow.ellipsis,  // ✅ Good
        ),
      ],
    ),
  ),
)
```

```dart
// ✅ AFTER - Fully Responsive
Card(
  elevation: context.cardElevation,  // ✅ Responsive (2-6)
  shadowColor: Colors.black.withOpacity(0.15),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(context.borderRadius),  // ✅ Responsive (12-20px)
  ),
  child: Container(
    padding: EdgeInsets.all(AppSpacing.md),  // ✅ Design system (12px)
    decoration: BoxDecoration(...),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),  // ✅ Design system (8px)
              decoration: BoxDecoration(...),
              child: Icon(
                Icons.sports_soccer,
                color: Colors.white,
                size: ResponsiveUtils.getIconSize(context, 24),  // ✅ Responsive (22-29px)
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,  // ✅ Design system
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(...),
              child: Text(
                _getLocalizedStatus(match.status),
                style: AppTextStyles.caption.copyWith(  // ✅ Design system
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.verticalSm,  // ✅ Design system (8px)
        Text(
          match.displayTitle,
          style: AppTextStyles.getResponsiveCardTitle(context).copyWith(  // ✅ Responsive
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  ),
)
```

---

### 5. PROFILE SCREEN FIXES

#### Fix 5.1: Responsive Avatar and Name

**File:** `lib/screens/profile_screen.dart`

```dart
// ❌ BEFORE (Lines 240-260)
Container(
  padding: const EdgeInsets.all(4),  // ❌ Fixed padding
  decoration: BoxDecoration(...),
  child: user.imageUrl != null
      ? CachedCircleImage(
          imageUrl: user.imageUrl!,
          radius: context.isMobile ? 40 : 50,  // ⚠️ Better but can be improved
        )
      : CircleAvatar(
          radius: context.isMobile ? 40 : 50,
          backgroundColor: context.colors.surface,
          child: Icon(
            Icons.person,
            size: context.isMobile ? 28 : 36,  // ⚠️ Better but can be improved
            color: context.colors.textSubtle,
          ),
        ),
),
const SizedBox(height: 12),  // ❌ Fixed spacing
Text(
  user.name,
  style: AppTextStyles.headingLarge.copyWith(
    fontWeight: FontWeight.bold,
    color: context.colors.textPrimary,
    fontSize: context.isMobile ? 20 : 24,  // ⚠️ Better but can be improved
  ),
  // ❌ Missing maxLines and overflow
),
```

```dart
// ✅ AFTER - Fully Responsive
Container(
  padding: EdgeInsets.all(AppSpacing.xs),  // ✅ Design system
  decoration: BoxDecoration(...),
  child: user.imageUrl != null
      ? CachedCircleImage(
          imageUrl: user.imageUrl!,
          radius: ResponsiveUtils.getIconSize(context, 40),  // ✅ Responsive (36-48px)
        )
      : CircleAvatar(
          radius: ResponsiveUtils.getIconSize(context, 40),
          backgroundColor: context.colors.surface,
          child: Icon(
            Icons.person,
            size: ResponsiveUtils.getIconSize(context, 28),  // ✅ Responsive (25-34px)
            color: context.colors.textSubtle,
          ),
        ),
),
AppSpacing.verticalMd,  // ✅ Design system (12px)
Text(
  user.name,
  style: AppTextStyles.getResponsivePageTitle(context).copyWith(  // ✅ Responsive
    fontWeight: FontWeight.bold,
    color: context.colors.textPrimary,
  ),
  maxLines: 2,  // ✅ Overflow protection
  overflow: TextOverflow.ellipsis,
  textAlign: TextAlign.center,
),
```

---

### 6. TEAMS SCREEN FIXES

#### Fix 6.1: Responsive Grid

**File:** `lib/screens/teams_screen.dart`

```dart
// ❌ BEFORE (Lines 380-410)
GridView.builder(
  key: const PageStorageKey('teams_grid'),
  padding: EdgeInsets.only(
    left: constraints.maxWidth > 600 ? 32 : 16,  // ⚠️ Better but can be improved
    right: constraints.maxWidth > 600 ? 32 : 16,
    top: 16,  // ❌ Fixed
    bottom: 80,  // ❌ Fixed
  ),
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: crossAxisCount,
    childAspectRatio: 3.0,  // ❌ Fixed aspect ratio
    crossAxisSpacing: 16,  // ❌ Fixed spacing
    mainAxisSpacing: 12,  // ❌ Fixed spacing
  ),
  itemCount: teamProvider.teams.length,
  itemBuilder: (context, index) => ...,
)
```

```dart
// ✅ AFTER - Fully Responsive
GridView.builder(
  key: const PageStorageKey('teams_grid'),
  padding: EdgeInsets.only(
    left: context.responsiveHorizontalPadding.left,  // ✅ Responsive
    right: context.responsiveHorizontalPadding.right,
    top: AppSpacing.lg,  // ✅ Design system
    bottom: context.mobileNavHeight + AppSpacing.lg,  // ✅ Responsive nav height
  ),
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: crossAxisCount,
    childAspectRatio: context.isMobile ? 3.0 : 2.5,  // ✅ Responsive aspect ratio
    crossAxisSpacing: context.gridSpacing,  // ✅ Responsive (10-24px)
    mainAxisSpacing: context.gridSpacing,
  ),
  itemCount: teamProvider.teams.length,
  itemBuilder: (context, index) => ...,
)
```

---

### 7. LANDSCAPE ORIENTATION SUPPORT

#### Fix 7.1: Add Orientation Builder

**New Pattern for Screens:**

```dart
// ✅ NEW - Add to screens that need landscape support
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.landscape && context.isMobile) {
          return _buildLandscapeLayout();
        }
        return _buildPortraitLayout();
      },
    );
  }

  Widget _buildPortraitLayout() {
    // Existing layout
    return SafeArea(
      child: SingleChildScrollView(
        padding: context.responsiveHorizontalPadding,
        child: Column(
          children: [
            _buildSearchField(context, provider),
            AppSpacing.verticalSm,
            _buildQuickActionButtons(context, provider),
            // ... rest of content
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    // Optimized for landscape
    return SafeArea(
      child: Row(
        children: [
          // Sidebar with actions
          Container(
            width: 280,
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _buildSearchField(context, provider),
                AppSpacing.verticalMd,
                _buildQuickActionButtons(context, provider),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _buildFeaturedMatches(context, provider),
                  AppSpacing.verticalLg,
                  _buildFeaturedTeams(context, provider),
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

---

## Summary of Changes

### Files to Modify:

1. ✅ `lib/screens/home_screen.dart` - 15 changes
2. ✅ `lib/screens/create_match_screen.dart` - 20 changes
3. ✅ `lib/screens/match_details_screen.dart` - 25 changes
4. ✅ `lib/screens/profile_screen.dart` - 18 changes
5. ✅ `lib/screens/teams_screen.dart` - 10 changes
6. ✅ `lib/widgets/match_card.dart` - 12 changes
7. ✅ `lib/widgets/team_card.dart` - 10 changes

### Total Changes: ~110 fixes

### Estimated Time:
- P0 Fixes: 4-6 hours
- P1 Fixes: 6-8 hours
- P2 Fixes: 8-10 hours
- **Total: 18-24 hours**

### Testing Time:
- Device testing: 4 hours
- Regression testing: 2 hours
- **Total: 6 hours**

### Grand Total: 24-30 hours
