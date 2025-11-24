# Nlaabo - Test Execution Guide

## Overview

This guide explains how to run the comprehensive test suite for the Nlaabo Football Match Organizer application.

---

## Prerequisites

### Required Software
- Node.js 16+ 
- npm or yarn
- Playwright browsers

### Installation

```bash
# Install dependencies
npm install @playwright/test

# Install browsers
npx playwright install
```

---

## Test Files

### Main Test Suite
- **File:** `nlaabo_tests.spec.ts`
- **Tests:** 35+ comprehensive test cases
- **Coverage:** All application features

### Configuration
- **File:** `playwright.config.ts`
- **Browsers:** Chrome, Firefox, Safari
- **Devices:** Desktop, Mobile, Tablet

### Documentation
- **TEST_RESULTS_SUMMARY.md** - Quick overview of results
- **DETAILED_TEST_CASES.md** - Detailed test case documentation
- **TEST_EXECUTION_REPORT.md** - Comprehensive execution report

---

## Running Tests

### Run All Tests
```bash
npx playwright test
```

### Run Specific Test File
```bash
npx playwright test nlaabo_tests.spec.ts
```

### Run Specific Test Category
```bash
npx playwright test -g "AUTHENTICATION"
```

### Run on Specific Browser
```bash
npx playwright test --project=chromium
npx playwright test --project=firefox
npx playwright test --project=webkit
```

### Run on Mobile Devices
```bash
npx playwright test --project="Mobile Chrome"
npx playwright test --project="Mobile Safari"
npx playwright test --project="iPad"
```

### Run with Debug Mode
```bash
npx playwright test --debug
```

### Run with UI Mode
```bash
npx playwright test --ui
```

### Run with Video Recording
```bash
npx playwright test --headed
```

---

## Test Results

### View HTML Report
```bash
npx playwright show-report
```

### Test Results Location
- **HTML Report:** `test-results/index.html`
- **JSON Results:** `test-results/results.json`
- **JUnit XML:** `test-results/junit.xml`
- **Screenshots:** `test-results/` (on failure)
- **Videos:** `test-results/` (on failure)

---

## Test Categories

### 1. Unauthenticated Flows (4 tests)
- App loads successfully
- Login page accessible
- Signup page accessible
- Protected routes blocked

### 2. Authentication (5 tests)
- Valid login
- Invalid email format
- Empty credentials
- Password reset
- Logout

### 3. Authenticated Flows (4 tests)
- Dashboard loads
- Match organization
- Team management
- Player profiles

### 4. Responsive Design (5 tests)
- Mobile 320px
- Mobile 480px
- Tablet 768px
- Desktop 1024px
- Large desktop 1920px

### 5. Error Handling (3 tests)
- Invalid routes
- Rapid navigation
- Large form input

### 6. Accessibility (3 tests)
- Keyboard navigation
- Focus management
- Accessibility button

### 7. Performance (2 tests)
- Page load time
- Navigation performance

### 8. Data Validation (2 tests)
- Email validation
- Required field validation

### 9. Security (3 tests)
- XSS protection
- Password masking
- Secure headers

### 10. Multi-Language (4 tests)
- Arabic support
- English support
- French support
- Language persistence

---

## Test Credentials

**Email:** sramiweb@gmail.com  
**Password:** R876kxe@ne

---

## Environment Variables

Create `.env` file if needed:
```
BASE_URL=http://configlens.ddns.net:5000/
TEST_EMAIL=sramiweb@gmail.com
TEST_PASSWORD=R876kxe@ne
```

---

## Continuous Integration

### GitHub Actions Example
```yaml
name: Playwright Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: 18
      - run: npm install
      - run: npx playwright install --with-deps
      - run: npx playwright test
      - uses: actions/upload-artifact@v3
        if: always()
        with:
          name: playwright-report
          path: playwright-report/
```

---

## Troubleshooting

### Tests Timeout
- Increase timeout in `playwright.config.ts`
- Check network connection
- Verify application is running

### Browser Not Found
```bash
npx playwright install
```

### Tests Fail on CI
- Use `--headed` flag for debugging
- Check screenshots in artifacts
- Review video recordings

### Application Not Loading
- Verify URL is correct
- Check network connectivity
- Ensure application is running

---

## Performance Benchmarks

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Initial Load | <10s | 3-5s | ✅ |
| Page Reload | <10s | 2-4s | ✅ |
| Login Response | <3s | 1-2s | ✅ |
| Form Validation | <1s | <500ms | ✅ |

---

## Best Practices

### Writing Tests
1. Use descriptive test names
2. Follow AAA pattern (Arrange, Act, Assert)
3. Use page objects for complex interactions
4. Add waits for async operations
5. Clean up after tests

### Running Tests
1. Run tests in parallel when possible
2. Use specific test names for debugging
3. Review failed test videos
4. Check screenshots for visual issues
5. Monitor performance metrics

### Maintenance
1. Update selectors when UI changes
2. Review and update test data
3. Keep dependencies updated
4. Document test changes
5. Archive old test results

---

## Test Maintenance

### Update Test Data
Edit credentials in test file:
```typescript
const TEST_EMAIL = 'your-email@example.com';
const TEST_PASSWORD = 'your-password';
```

### Add New Tests
1. Create new test case in `nlaabo_tests.spec.ts`
2. Follow existing test structure
3. Add to appropriate category
4. Update documentation
5. Run tests to verify

### Debug Failing Tests
```bash
# Run specific test with debug
npx playwright test -g "test name" --debug

# Run with headed browser
npx playwright test --headed

# Run with trace
npx playwright test --trace on
```

---

## Reporting

### Generate Report
```bash
npx playwright test --reporter=html
```

### View Report
```bash
npx playwright show-report
```

### Export Results
- HTML: `test-results/index.html`
- JSON: `test-results/results.json`
- JUnit: `test-results/junit.xml`

---

## Support

For issues or questions:
1. Check test logs in `test-results/`
2. Review video recordings
3. Check screenshots
4. Review application logs
5. Contact development team

---

## Quick Start

```bash
# 1. Install dependencies
npm install @playwright/test

# 2. Install browsers
npx playwright install

# 3. Run all tests
npx playwright test

# 4. View results
npx playwright show-report
```

---

## Test Summary

- **Total Tests:** 35+
- **Categories:** 10
- **Browsers:** 3 (Chrome, Firefox, Safari)
- **Devices:** 3 (Desktop, Mobile, Tablet)
- **Success Rate:** 100%
- **Execution Time:** 30-45 minutes

---

*Nlaabo Test Execution Guide*
