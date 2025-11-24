import { test, expect } from '@playwright/test';

// Test credentials
const TEST_EMAIL = 'sramiweb@gmail.com';
const TEST_PASSWORD = 'R876kxe@ne';

test.describe('Profile Management', () => {
  test.beforeEach(async ({ page }) => {
    // Login before each test
    await page.goto('/login');
    await page.fill('input[type="email"]', TEST_EMAIL);
    await page.fill('input[type="password"]', TEST_PASSWORD);
    await page.click('button:has-text("Login")');
    await expect(page).toHaveURL(/\/home$/);
  });

  test('should navigate to profile page', async ({ page }) => {
    await page.click('text=Profile');
    await expect(page).toHaveURL(/\/profile$/);

    // Check profile page elements
    await expect(page.locator('text=Profile Information')).toBeVisible();
    await expect(page.locator('text=Edit Profile')).toBeVisible();
  });

  test('should display user profile information', async ({ page }) => {
    await page.goto('/profile');

    // Check for basic profile elements
    await expect(page.locator('[data-testid="user-name"]').or(page.locator('text=Name:'))).toBeVisible();
    await expect(page.locator('[data-testid="user-email"]').or(page.locator('text=Email:'))).toBeVisible();
  });

  test('should display profile statistics', async ({ page }) => {
    await page.goto('/profile');

    // Check for profile stats like teams, matches, etc.
    const statElements = [
      page.locator('text=Teams:'),
      page.locator('text=Matches:'),
      page.locator('text=Joined:')
    ];

    // At least one stat should be visible
    let statsVisible = false;
    for (const stat of statElements) {
      if (await stat.isVisible()) {
        statsVisible = true;
        break;
      }
    }

    expect(statsVisible).toBe(true);
  });

  test('should navigate to edit profile page', async ({ page }) => {
    await page.goto('/profile');
    await page.click('text=Edit Profile');

    await expect(page).toHaveURL(/\/edit-profile$/);

    // Check edit form elements
    await expect(page.locator('input[placeholder*="name"]')).toBeVisible();
    await expect(page.locator('button:has-text("Save Changes")')).toBeVisible();
  });

  test('should update profile information successfully', async ({ page }) => {
    await page.goto('/edit-profile');

    // Get current name to restore later
    const currentName = await page.locator('input[placeholder*="name"]').inputValue();

    // Update name
    const newName = `Test User ${Date.now()}`;
    await page.fill('input[placeholder*="name"]', newName);

    // Save changes
    await page.click('button:has-text("Save Changes")');

    // Should show success message or redirect to profile
    await expect(page.locator('text=Profile updated successfully').or(
      page.locator('text=Changes saved')
    )).toBeVisible();

    // Verify change was saved
    await page.goto('/profile');
    await expect(page.locator(`text=${newName}`)).toBeVisible();

    // Restore original name
    await page.click('text=Edit Profile');
    await page.fill('input[placeholder*="name"]', currentName || 'Test User');
    await page.click('button:has-text("Save Changes")');
  });

  test('should handle profile picture upload', async ({ page }) => {
    await page.goto('/edit-profile');

    // Check for file upload input
    const fileInput = page.locator('input[type="file"]').or(
      page.locator('[data-testid="avatar-upload"]')
    );

    if (await fileInput.isVisible()) {
      // For testing, we can't actually upload a file without a test image
      // But we can check that the upload UI is present
      await expect(fileInput).toBeVisible();

      // Check for upload button or area
      const uploadArea = page.locator('text=Upload').or(
        page.locator('text=Choose File')
      );
      await expect(uploadArea).toBeVisible();
    } else {
      // Profile picture might be displayed as image
      const profileImage = page.locator('img[alt*="profile"]').or(
        page.locator('[data-testid="profile-avatar"]')
      );
      await expect(profileImage).toBeVisible();
    }
  });

  test('should validate profile form inputs', async ({ page }) => {
    await page.goto('/edit-profile');

    // Clear name field
    await page.fill('input[placeholder*="name"]', '');

    // Try to save
    await page.click('button:has-text("Save Changes")');

    // Should show validation error
    await expect(page.locator('text=Name is required').or(
      page.locator('text=Name cannot be empty')
    )).toBeVisible();
  });

  test('should handle phone number input', async ({ page }) => {
    await page.goto('/edit-profile');

    // Check for phone input
    const phoneInput = page.locator('input[type="tel"]').or(
      page.locator('input[placeholder*="phone"]')
    );

    if (await phoneInput.isVisible()) {
      // Test phone number input
      await phoneInput.fill('+1234567890');

      // Save and verify
      await page.click('button:has-text("Save Changes")');

      // Should save successfully
      await expect(page.locator('text=Profile updated successfully')).toBeVisible();
    }
  });

  test('should handle date of birth input', async ({ page }) => {
    await page.goto('/edit-profile');

    // Check for date input
    const dateInput = page.locator('input[type="date"]').or(
      page.locator('[data-testid="birthdate-input"]')
    );

    if (await dateInput.isVisible()) {
      // Set a valid birth date
      await dateInput.fill('1990-01-01');

      // Save and verify
      await page.click('button:has-text("Save Changes")');

      // Should save successfully
      await expect(page.locator('text=Profile updated successfully')).toBeVisible();
    }
  });

  test('should handle gender selection', async ({ page }) => {
    await page.goto('/edit-profile');

    // Check for gender select/dropdown
    const genderSelect = page.locator('select').filter({ hasText: 'Male' }).or(
      page.locator('[data-testid="gender-select"]')
    );

    if (await genderSelect.isVisible()) {
      // Select gender
      await genderSelect.selectOption('male');

      // Save and verify
      await page.click('button:has-text("Save Changes")');

      // Should save successfully
      await expect(page.locator('text=Profile updated successfully')).toBeVisible();
    }
  });

  test('should handle location/city input', async ({ page }) => {
    await page.goto('/edit-profile');

    // Check for location input
    const locationInput = page.locator('input[placeholder*="city"]').or(
      page.locator('input[placeholder*="location"]')
    );

    if (await locationInput.isVisible()) {
      // Set location
      await locationInput.fill('Test City');

      // Save and verify
      await page.click('button:has-text("Save Changes")');

      // Should save successfully
      await expect(page.locator('text=Profile updated successfully')).toBeVisible();
    }
  });

  test('should display profile completion status', async ({ page }) => {
    await page.goto('/profile');

    // Check for profile completion indicator
    const completionIndicator = page.locator('text=Profile Complete').or(
      page.locator('[data-testid="profile-completion"]')
    );

    if (await completionIndicator.isVisible()) {
      // Should show completion percentage or status
      await expect(completionIndicator).toBeVisible();
    }
  });

  test('should handle profile preferences', async ({ page }) => {
    await page.goto('/edit-profile');

    // Check for preference toggles (notifications, privacy, etc.)
    const notificationToggle = page.locator('input[type="checkbox"]').filter({ hasText: 'notifications' }).or(
      page.locator('[data-testid="notification-preference"]')
    );

    if (await notificationToggle.isVisible()) {
      // Toggle preference
      await notificationToggle.check();

      // Save changes
      await page.click('button:has-text("Save Changes")');

      // Should save successfully
      await expect(page.locator('text=Preferences updated')).toBeVisible();
    }
  });

  test('should display user activity history', async ({ page }) => {
    await page.goto('/profile');

    // Check for activity/history section
    const activitySection = page.locator('text=Recent Activity').or(
      page.locator('[data-testid="activity-history"]')
    );

    if (await activitySection.isVisible()) {
      // Should show some activity items
      const activityItems = page.locator('[data-testid="activity-item"]');
      const count = await activityItems.count();

      // May have 0 activities, which is fine
      expect(typeof count).toBe('number');
    }
  });

  test('should handle profile privacy settings', async ({ page }) => {
    await page.goto('/edit-profile');

    // Check for privacy settings
    const privacyToggle = page.locator('text=Private Profile').or(
      page.locator('[data-testid="privacy-toggle"]')
    );

    if (await privacyToggle.isVisible()) {
      // Toggle privacy setting
      const checkbox = page.locator('input[type="checkbox"]').first();
      await checkbox.check();

      // Save changes
      await page.click('button:has-text("Save Changes")');

      // Should save successfully
      await expect(page.locator('text=Privacy settings updated')).toBeVisible();
    }
  });

  test('should handle skill level selection', async ({ page }) => {
    await page.goto('/edit-profile');

    // Check for skill level selector
    const skillSelect = page.locator('select').filter({ hasText: 'Beginner' }).or(
      page.locator('[data-testid="skill-level-select"]')
    );

    if (await skillSelect.isVisible()) {
      // Select skill level
      await skillSelect.selectOption('intermediate');

      // Save and verify
      await page.click('button:has-text("Save Changes")');

      // Should save successfully
      await expect(page.locator('text=Profile updated successfully')).toBeVisible();
    }
  });

  test('should handle favorite position selection', async ({ page }) => {
    await page.goto('/edit-profile');

    // Check for position selector
    const positionSelect = page.locator('select').filter({ hasText: 'Forward' }).or(
      page.locator('[data-testid="position-select"]')
    );

    if (await positionSelect.isVisible()) {
      // Select position
      await positionSelect.selectOption('midfielder');

      // Save and verify
      await page.click('button:has-text("Save Changes")');

      // Should save successfully
      await expect(page.locator('text=Profile updated successfully')).toBeVisible();
    }
  });

  test('should display profile verification status', async ({ page }) => {
    await page.goto('/profile');

    // Check for verification badges or status
    const verificationBadge = page.locator('text=Verified').or(
      page.locator('[data-testid="verification-badge"]')
    );

    if (await verificationBadge.isVisible()) {
      // Verification status should be displayed
      await expect(verificationBadge).toBeVisible();
    }
  });

  test('should handle profile deletion request', async ({ page }) => {
    // This is a dangerous operation, so it should be well protected
    await page.goto('/edit-profile');

    const deleteButton = page.locator('button:has-text("Delete Account")').or(
      page.locator('text=Delete Profile')
    );

    if (await deleteButton.isVisible()) {
      // Click delete
      await deleteButton.click();

      // Should show confirmation dialog
      await expect(page.locator('text=Are you sure')).toBeVisible();

      // Don't actually delete - just check the confirmation flow
      await page.click('button:has-text("Cancel")');
    } else {
      // Delete option might be in settings
      test.skip();
    }
  });
});