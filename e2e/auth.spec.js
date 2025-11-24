import { test, expect } from '@playwright/test';

// Test credentials
const TEST_EMAIL = 'sramiweb@gmail.com';
const TEST_PASSWORD = 'R876kxe@ne';

test.describe('Authentication Flow', () => {
  test.beforeEach(async ({ page }) => {
    // Clear any existing session
    await page.context().clearCookies();
    await page.goto('/');
  });

  test('should display auth landing page for unauthenticated users', async ({ page }) => {
    await expect(page).toHaveURL(/\/auth$/);

    // Check for main auth elements
    await expect(page.locator('text=Welcome to Nlaabo')).toBeVisible();
    await expect(page.locator('text=Login')).toBeVisible();
    await expect(page.locator('text=Sign Up')).toBeVisible();
  });

  test('should navigate to login page', async ({ page }) => {
    await page.click('text=Login');
    await expect(page).toHaveURL(/\/login$/);

    // Check login form elements
    await expect(page.locator('input[type="email"]')).toBeVisible();
    await expect(page.locator('input[type="password"]')).toBeVisible();
    await expect(page.locator('button:has-text("Login")')).toBeVisible();
  });

  test('should navigate to signup page', async ({ page }) => {
    await page.click('text=Sign Up');
    await expect(page).toHaveURL(/\/signup$/);

    // Check signup form elements
    await expect(page.locator('input[type="email"]')).toBeVisible();
    await expect(page.locator('input[type="password"]')).toBeVisible();
    await expect(page.locator('button:has-text("Sign Up")')).toBeVisible();
  });

  test('should successfully login with valid credentials', async ({ page }) => {
    await page.goto('/login');

    // Fill login form
    await page.fill('input[type="email"]', TEST_EMAIL);
    await page.fill('input[type="password"]', TEST_PASSWORD);

    // Submit form
    await page.click('button:has-text("Login")');

    // Should redirect to home page
    await expect(page).toHaveURL(/\/home$/);

    // Check that we're authenticated (should see user menu or profile elements)
    await expect(page.locator('text=Profile')).toBeVisible();
  });

  test('should show error for invalid login credentials', async ({ page }) => {
    await page.goto('/login');

    // Fill with invalid credentials
    await page.fill('input[type="email"]', 'invalid@example.com');
    await page.fill('input[type="password"]', 'wrongpassword');

    // Submit form
    await page.click('button:has-text("Login")');

    // Should stay on login page and show error
    await expect(page).toHaveURL(/\/login$/);
    await expect(page.locator('text=Invalid email or password')).toBeVisible();
  });

  test('should show error for empty login fields', async ({ page }) => {
    await page.goto('/login');

    // Try to submit without filling fields
    await page.click('button:has-text("Login")');

    // Should show validation errors
    await expect(page.locator('text=Email is required')).toBeVisible();
    await expect(page.locator('text=Password is required')).toBeVisible();
  });

  test('should navigate to forgot password page', async ({ page }) => {
    await page.goto('/login');

    // Click forgot password link
    await page.click('text=Forgot Password?');

    // Should navigate to forgot password page
    await expect(page).toHaveURL(/\/forgot-password$/);
  });

  test('should handle forgot password flow', async ({ page }) => {
    await page.goto('/forgot-password');

    // Fill email
    await page.fill('input[type="email"]', TEST_EMAIL);

    // Submit
    await page.click('button:has-text("Send Reset Link")');

    // Should show confirmation
    await expect(page).toHaveURL(/\/forgot-password-confirmation$/);
    await expect(page.locator(`text=${TEST_EMAIL}`)).toBeVisible();
  });

  test('should redirect authenticated users away from auth pages', async ({ page }) => {
    // First login
    await page.goto('/login');
    await page.fill('input[type="email"]', TEST_EMAIL);
    await page.fill('input[type="password"]', TEST_PASSWORD);
    await page.click('button:has-text("Login")');
    await expect(page).toHaveURL(/\/home$/);

    // Try to access login page again
    await page.goto('/login');

    // Should redirect to home
    await expect(page).toHaveURL(/\/home$/);
  });

  test('should handle logout functionality', async ({ page }) => {
    // Login first
    await page.goto('/login');
    await page.fill('input[type="email"]', TEST_EMAIL);
    await page.fill('input[type="password"]', TEST_PASSWORD);
    await page.click('button:has-text("Login")');
    await expect(page).toHaveURL(/\/home$/);

    // Find and click logout (this might be in a menu)
    await page.click('[data-testid="user-menu"]');
    await page.click('text=Logout');

    // Should redirect to auth page
    await expect(page).toHaveURL(/\/auth$/);
  });

  test('should handle signup with valid data', async ({ page }) => {
    await page.goto('/signup');

    // Generate unique email for testing
    const uniqueEmail = `test${Date.now()}@example.com`;

    // Fill signup form
    await page.fill('input[type="email"]', uniqueEmail);
    await page.fill('input[type="password"]', 'TestPassword123!');
    await page.fill('input[placeholder*="confirm"]', 'TestPassword123!');

    // Submit
    await page.click('button:has-text("Sign Up")');

    // Should either redirect to home or show email verification message
    // (depending on app configuration)
    await expect(page).toHaveURL(/\/(home|email-verification)$/);
  });

  test('should show validation errors for invalid signup data', async ({ page }) => {
    await page.goto('/signup');

    // Fill with invalid data
    await page.fill('input[type="email"]', 'invalid-email');
    await page.fill('input[type="password"]', '123');
    await page.fill('input[placeholder*="confirm"]', '456');

    // Submit
    await page.click('button:has-text("Sign Up")');

    // Should show validation errors
    await expect(page.locator('text=Invalid email format')).toBeVisible();
    await expect(page.locator('text=Password must be at least')).toBeVisible();
    await expect(page.locator('text=Passwords do not match')).toBeVisible();
  });

  test('should handle onboarding flow for new users', async ({ page }) => {
    // This test assumes we can create a new user and check onboarding
    // Skip if onboarding is not implemented or requires special setup
    test.skip();

    await page.goto('/signup');
    const uniqueEmail = `onboarding${Date.now()}@example.com`;

    await page.fill('input[type="email"]', uniqueEmail);
    await page.fill('input[type="password"]', 'TestPassword123!');
    await page.fill('input[placeholder*="confirm"]', 'TestPassword123!');
    await page.click('button:has-text("Sign Up")');

    // Should show onboarding
    await expect(page).toHaveURL(/\/onboarding$/);
  });
});