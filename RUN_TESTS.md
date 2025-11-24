# Quick Start - Running Tests

## 🚀 Run the App

### Debug Mode
```bash
flutter run
```

### Profile Mode (Performance Testing)
```bash
flutter run --profile
```

### Release Mode
```bash
flutter run --release
```

---

## 🧪 Run Unit Tests

### All Tests
```bash
flutter test
```

### Specific Test File
```bash
flutter test test/new_screens_test.dart
```

### With Coverage
```bash
flutter test --coverage
```

---

## 🎯 Test New Screens Manually

### 1. Start the App
```bash
flutter run
```

### 2. Test Team Members Screen
```
1. Navigate to a team
2. Click "Team Members" or go to /team/{id}/members
3. Verify members list displays
4. Try removing a member
5. Check error handling
```

### 3. Test Match History Screen
```
1. Go to /match-history
2. Verify past matches display
3. Try filtering by date
4. Try refreshing
5. Click on a match to view details
```

### 4. Test Advanced Search Screen
```
1. Go to /search
2. Search for a match
3. Search for a team
4. Try different filter types
5. Clear search and verify reset
```

---

## 🌐 Test Translations

### Switch Language in App
1. Go to Settings
2. Select Language
3. Choose English, French, or Arabic
4. Verify all labels translate correctly

### Test RTL (Arabic)
1. Switch to Arabic
2. Verify layout is right-to-left
3. Check text alignment
4. Verify navigation works

---

## 📱 Test on Different Devices

### List Available Devices
```bash
flutter devices
```

### Run on Specific Device
```bash
flutter run -d <device_id>
```

### Run on Emulator
```bash
# Start emulator first
emulator -avd <emulator_name>

# Then run
flutter run
```

### Run on iOS Simulator
```bash
open -a Simulator
flutter run
```

---

## 🔍 Debug Mode

### Enable Debug Logging
```bash
flutter run -v
```

### Hot Reload
```
Press 'r' in terminal while app is running
```

### Hot Restart
```
Press 'R' in terminal while app is running
```

### Inspect Widget Tree
```
Press 'w' in terminal while app is running
```

---

## 📊 Check Code Quality

### Analyze Code
```bash
flutter analyze
```

### Format Code
```bash
dart format lib/
```

### Fix Issues
```bash
dart fix --apply
```

---

## 🎓 Common Test Scenarios

### Test Navigation
```bash
# In app:
1. Go to /match-history
2. Go to /search
3. Go to /team/test-id/members
4. Use back button
5. Verify navigation works
```

### Test Error Handling
```bash
# Simulate network error:
1. Turn off internet
2. Try to load screen
3. Verify error message displays
4. Turn on internet
5. Try retry button
```

### Test Loading States
```bash
# Verify loading indicators:
1. Navigate to screen
2. Watch for loading spinner
3. Verify it disappears when data loads
4. Check no loading state remains
```

### Test Empty States
```bash
# Verify empty state messages:
1. Go to screen with no data
2. Verify appropriate message displays
3. Check message is helpful
4. Verify action buttons work
```

---

## 📋 Pre-Release Checklist

- [ ] All unit tests pass
- [ ] App runs without errors
- [ ] All screens load correctly
- [ ] Navigation works
- [ ] Translations display correctly
- [ ] Error handling works
- [ ] Loading states display
- [ ] No console errors
- [ ] No performance issues
- [ ] Accessibility features work

---

## 🆘 Troubleshooting

### App Won't Start
```bash
flutter clean
flutter pub get
flutter run
```

### Tests Won't Run
```bash
flutter clean
flutter pub get
flutter test
```

### Hot Reload Not Working
```bash
# Use hot restart instead
Press 'R' in terminal
```

### Device Not Found
```bash
flutter devices
# Check device is connected
adb devices  # for Android
```

---

## 📞 Support

For issues or questions:
1. Check the error message carefully
2. Run `flutter doctor` to check setup
3. Check documentation in project
4. Review test files for examples

---

**Ready to test! 🚀**
