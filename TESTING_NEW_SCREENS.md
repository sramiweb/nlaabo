# Testing Guide - New Screens

## 🧪 Unit Tests

### Run Tests
```bash
flutter test test/new_screens_test.dart
```

### Test Coverage
- ✅ TeamMembersManagementScreen renders
- ✅ MatchHistoryScreen renders
- ✅ AdvancedSearchScreen renders

---

## 🎯 Manual Testing Checklist

### 1. Team Members Management Screen

**Route:** `/team/:id/members`

#### Test Cases:
- [ ] **Load Screen**
  - Navigate to `/team/test-id/members`
  - Screen loads without errors
  - MainLayout wrapper displays

- [ ] **Display Members**
  - Team members list displays
  - Each member shows name and role
  - Loading state shows while fetching

- [ ] **Remove Member**
  - Click remove button on member
  - Confirmation dialog appears
  - Confirm removal
  - Member removed from list
  - Success message displays

- [ ] **Error Handling**
  - Invalid team ID shows error
  - Network error shows error message
  - Retry button works

- [ ] **Translations**
  - Switch to French - labels display correctly
  - Switch to Arabic - RTL layout works
  - Switch to English - labels display correctly

---

### 2. Match History Screen

**Route:** `/match-history`

#### Test Cases:
- [ ] **Load Screen**
  - Navigate to `/match-history`
  - Screen loads without errors
  - MainLayout wrapper displays

- [ ] **Display Matches**
  - Past matches display in list
  - Each match shows title, date, teams
  - Loading state shows while fetching

- [ ] **Filter by Date**
  - Select date range
  - List filters correctly
  - Empty state shows if no matches

- [ ] **Refresh**
  - Pull to refresh (if implemented)
  - Refresh button works
  - List updates with latest data

- [ ] **Navigate to Details**
  - Click on match
  - Navigate to match details screen
  - Match details load correctly

- [ ] **Error Handling**
  - Network error shows error message
  - Retry button works
  - Empty state displays when no matches

- [ ] **Translations**
  - All labels translate correctly
  - Date format respects locale

---

### 3. Advanced Search Screen

**Route:** `/search`

#### Test Cases:
- [ ] **Load Screen**
  - Navigate to `/search`
  - Screen loads without errors
  - MainLayout wrapper displays

- [ ] **Search Matches**
  - Type match title in search
  - Results display in real-time
  - Click result to view details

- [ ] **Search Teams**
  - Type team name in search
  - Results display in real-time
  - Click result to view team details

- [ ] **Filter by Type**
  - Select "All Results"
  - Both matches and teams display
  - Select "Matches Only"
  - Only matches display
  - Select "Teams Only"
  - Only teams display

- [ ] **Clear Search**
  - Type search query
  - Click clear button
  - Search field clears
  - Results reset

- [ ] **Error Handling**
  - Network error shows error message
  - Empty results show appropriate message
  - Retry button works

- [ ] **Translations**
  - Search placeholder translates
  - Filter labels translate
  - Results labels translate

---

## 📱 Device Testing

### Test on Different Screen Sizes
- [ ] Mobile (320px - 480px)
- [ ] Tablet (768px - 1024px)
- [ ] Desktop (1024px+)

### Test on Different Devices
- [ ] iPhone SE (small phone)
- [ ] iPhone 12/13 (standard phone)
- [ ] iPad (tablet)
- [ ] Android phone
- [ ] Android tablet

### Test Orientations
- [ ] Portrait mode
- [ ] Landscape mode
- [ ] Rotation handling

---

## 🌐 Language Testing

### English (en)
- [ ] All labels display correctly
- [ ] No missing translations
- [ ] Text alignment correct

### French (fr)
- [ ] All labels display correctly
- [ ] No missing translations
- [ ] Text alignment correct

### Arabic (ar)
- [ ] All labels display correctly
- [ ] RTL layout works
- [ ] No missing translations
- [ ] Text alignment correct

---

## ♿ Accessibility Testing

### Screen Reader
- [ ] All interactive elements are announced
- [ ] Labels are associated with inputs
- [ ] Navigation is logical

### Keyboard Navigation
- [ ] Tab through all elements
- [ ] Enter/Space activates buttons
- [ ] Escape closes dialogs

### Color Contrast
- [ ] Text is readable
- [ ] Buttons are distinguishable
- [ ] Error messages are visible

### Touch Targets
- [ ] All buttons are at least 44x44 pixels
- [ ] Spacing between buttons is adequate
- [ ] No overlapping touch targets

---

## 🔄 Navigation Testing

### Route Access
- [ ] `/match-history` loads MatchHistoryScreen
- [ ] `/search` loads AdvancedSearchScreen
- [ ] `/team/:id/members` loads TeamMembersManagementScreen

### Back Navigation
- [ ] Back button works on all screens
- [ ] Navigation history is preserved
- [ ] No navigation loops

### Deep Linking
- [ ] Direct URL access works
- [ ] Parameters are passed correctly
- [ ] Invalid parameters show error

---

## 🔌 API Integration Testing

### Team Members Screen
- [ ] API call to get team members works
- [ ] API call to remove member works
- [ ] Error responses handled correctly
- [ ] Loading states display

### Match History Screen
- [ ] API call to get past matches works
- [ ] Filtering works correctly
- [ ] Pagination works (if implemented)
- [ ] Error responses handled correctly

### Advanced Search Screen
- [ ] API call to search teams works
- [ ] API call to search matches works
- [ ] Real-time search works
- [ ] Error responses handled correctly

---

## 📊 Performance Testing

### Load Time
- [ ] Screen loads in < 2 seconds
- [ ] API calls complete in < 3 seconds
- [ ] No noticeable lag during interactions

### Memory Usage
- [ ] No memory leaks
- [ ] Smooth scrolling
- [ ] No jank during animations

### Battery Usage
- [ ] No excessive CPU usage
- [ ] No excessive network requests
- [ ] Efficient image loading

---

## 🐛 Bug Tracking

### Found Issues
- [ ] Issue: _______________
  - Severity: High/Medium/Low
  - Steps to reproduce: _______________
  - Expected: _______________
  - Actual: _______________

---

## ✅ Sign-Off

- [ ] All unit tests pass
- [ ] All manual tests pass
- [ ] All accessibility tests pass
- [ ] All performance tests pass
- [ ] No critical bugs found
- [ ] Ready for production

---

**Testing Date:** _______________
**Tester Name:** _______________
**Status:** _______________
