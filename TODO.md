# Responsive Issues Fix - TODO List

## Phase 1: Critical Web Fixes ✅
- [x] Fix web layout centering on ultra-wide screens in `lib/widgets/main_layout.dart`
- [x] Make side navigation width responsive using `ResponsiveUtils.getResponsiveSideNavWidth()`
- [x] Add missing translation keys to all language files (`en.json`, `fr.json`, `ar.json`)
- [x] Replace hardcoded strings in `lib/screens/home_screen.dart` with translation keys

## Phase 2: Mobile Responsiveness Improvements
- [ ] Adjust tablet breakpoint from 800px to 600px in `lib/utils/responsive_utils.dart`
- [ ] Add specific handling for extra small mobile devices (<360px)
- [ ] Audit and ensure touch target sizes meet 48x48dp minimum in auth widgets

## Phase 3: Translation and RTL Fixes
- [ ] Replace hardcoded "Forgot Password?" in `lib/screens/login_screen.dart` with translation key
- [ ] Verify RTL support for Arabic in main layout and navigation
- [ ] Test navigation labels don't truncate in different languages

## Phase 4: Testing and Validation
- [ ] Run comprehensive responsive tests across device configurations
- [ ] Test translation coverage in all languages
- [ ] Verify touch targets meet accessibility standards
- [ ] Test RTL layout in Arabic
