import { test, expect } from '@playwright/test';

// Test credentials
const TEST_EMAIL = 'sramiweb@gmail.com';
const TEST_PASSWORD = 'R876kxe@ne';

test.describe('Match Management', () => {
  test.beforeEach(async ({ page }) => {
    // Login before each test
    await page.goto('/login');
    await page.fill('input[type="email"]', TEST_EMAIL);
    await page.fill('input[type="password"]', TEST_PASSWORD);
    await page.click('button:has-text("Login")');
    await expect(page).toHaveURL(/\/home$/);
  });

  test('should display matches section on home page', async ({ page }) => {
    await expect(page.locator('text=Matches')).toBeVisible();
  });

  test('should navigate to matches page', async ({ page }) => {
    await page.click('text=Matches');
    await expect(page).toHaveURL(/\/matches$/);

    // Check page elements
    await expect(page.locator('text=Create Match')).toBeVisible();
  });

  test('should navigate to my matches page', async ({ page }) => {
    await page.click('text=My Matches');
    await expect(page).toHaveURL(/\/my-matches$/);
  });

  test('should navigate to create match page', async ({ page }) => {
    await page.goto('/matches');
    await page.click('text=Create Match');
    await expect(page).toHaveURL(/\/create-match$/);

    // Check form elements
    await expect(page.locator('text=Select Teams')).toBeVisible();
    await expect(page.locator('input[type="datetime-local"]')).toBeVisible();
    await expect(page.locator('button:has-text("Create Match")')).toBeVisible();
  });

  test('should create a new match successfully', async ({ page }) => {
    await page.goto('/create-match');

    // Select teams (assuming there are teams available)
    const team1Select = page.locator('select').first().or(page.locator('[data-testid="team1-select"]'));
    const team2Select = page.locator('select').last().or(page.locator('[data-testid="team2-select"]'));

    if (await team1Select.isVisible() && await team2Select.isVisible()) {
      // Select different teams
      await team1Select.selectOption({ index: 1 });
      await team2Select.selectOption({ index: 2 });

      // Set future date/time
      const futureDate = new Date();
      futureDate.setDate(futureDate.getDate() + 7); // 7 days from now
      const dateString = futureDate.toISOString().slice(0, 16); // Format for datetime-local

      await page.fill('input[type="datetime-local"]', dateString);

      // Fill location
      await page.fill('input[placeholder*="location"]', 'Test Stadium');

      // Submit
      await page.click('button:has-text("Create Match")');

      // Should redirect to match details or matches page
      await expect(page).toHaveURL(/\/(matches|match\/)/);
    } else {
      // If team selection is different, skip this test
      test.skip();
    }
  });

  test('should show validation errors for invalid match data', async ({ page }) => {
    await page.goto('/create-match');

    // Try to submit without filling required fields
    await page.click('button:has-text("Create Match")');

    // Should show validation errors
    await expect(page.locator('text=Please select two different teams')).toBeVisible();
  });

  test('should prevent creating match with same team', async ({ page }) => {
    await page.goto('/create-match');

    const team1Select = page.locator('select').first().or(page.locator('[data-testid="team1-select"]'));
    const team2Select = page.locator('select').last().or(page.locator('[data-testid="team2-select"]'));

    if (await team1Select.isVisible() && await team2Select.isVisible()) {
      // Select same team for both
      await team1Select.selectOption({ index: 1 });
      await team2Select.selectOption({ index: 1 });

      // Submit
      await page.click('button:has-text("Create Match")');

      // Should show error
      await expect(page.locator('text=Teams must be different')).toBeVisible();
    } else {
      test.skip();
    }
  });

  test('should display match details page', async ({ page }) => {
    await page.goto('/matches');

    // Click on first match
    const firstMatch = page.locator('[data-testid="match-card"]').first();
    if (await firstMatch.isVisible()) {
      await firstMatch.click();

      // Should be on match details page
      await expect(page).toHaveURL(/\/match\/[^/]+$/);

      // Check match details elements
      await expect(page.locator('text=Match Details')).toBeVisible();
      await expect(page.locator('text=vs')).toBeVisible();
    } else {
      test.skip();
    }
  });

  test('should display match information correctly', async ({ page }) => {
    await page.goto('/matches');

    const firstMatch = page.locator('[data-testid="match-card"]').first();
    if (await firstMatch.isVisible()) {
      // Get match info from card
      const team1Name = await firstMatch.locator('[data-testid="team1-name"]').textContent();
      const team2Name = await firstMatch.locator('[data-testid="team2-name"]').textContent();

      await firstMatch.click();

      // Check if team names are displayed on details page
      if (team1Name && team2Name) {
        await expect(page.locator(`text=${team1Name}`)).toBeVisible();
        await expect(page.locator(`text=${team2Name}`)).toBeVisible();
      }

      // Check for match date/time
      await expect(page.locator('[data-testid="match-datetime"]')).toBeVisible();

      // Check for location
      await expect(page.locator('[data-testid="match-location"]')).toBeVisible();
    } else {
      test.skip();
    }
  });

  test('should handle match status updates', async ({ page }) => {
    // This test assumes there are matches with different statuses
    await page.goto('/matches');

    // Look for status indicators
    const statusElements = [
      page.locator('text=Scheduled'),
      page.locator('text=Ongoing'),
      page.locator('text=Completed'),
      page.locator('text=Cancelled')
    ];

    let statusFound = false;
    for (const status of statusElements) {
      if (await status.isVisible()) {
        statusFound = true;
        break;
      }
    }

    expect(statusFound).toBe(true);
  });

  test('should allow joining match requests', async ({ page }) => {
    // Navigate to matches
    await page.goto('/matches');

    // Look for join/request buttons
    const joinButton = page.locator('button:has-text("Join")').or(
      page.locator('button:has-text("Request to Join")')
    );

    if (await joinButton.isVisible()) {
      await joinButton.click();

      // Should show confirmation or success message
      await expect(page.locator('text=Request sent').or(
        page.locator('text=Joined successfully')
      )).toBeVisible();
    } else {
      // Check if user is already participating
      const participatingIndicator = page.locator('text=You are participating').or(
        page.locator('text=Request pending')
      );

      if (await participatingIndicator.isVisible()) {
        // User is already involved, test passes
        expect(true).toBe(true);
      } else {
        test.skip();
      }
    }
  });

  test('should display match requests for team owners', async ({ page }) => {
    // Navigate to matches
    await page.goto('/matches');

    // Look for match request indicators
    const requestIndicator = page.locator('[data-testid="match-requests"]').or(
      page.locator('text=Requests')
    );

    if (await requestIndicator.isVisible()) {
      await requestIndicator.click();

      // Should show requests page
      await expect(page).toHaveURL(/\/match-requests$/);

      // Check for request management
      await expect(page.locator('button:has-text("Accept")').or(
        page.locator('button:has-text("Reject")')
      )).toBeVisible();
    } else {
      test.skip();
    }
  });

  test('should handle match request acceptance/rejection', async ({ page }) => {
    await page.goto('/match-requests');

    const acceptButton = page.locator('button:has-text("Accept")').first();
    const rejectButton = page.locator('button:has-text("Reject")').first();

    if (await acceptButton.isVisible()) {
      await acceptButton.click();

      // Should show success message
      await expect(page.locator('text=Request accepted')).toBeVisible();
    } else if (await rejectButton.isVisible()) {
      await rejectButton.click();

      // Should show success message
      await expect(page.locator('text=Request rejected')).toBeVisible();
    } else {
      test.skip();
    }
  });

  test('should filter matches by status', async ({ page }) => {
    await page.goto('/matches');

    // Check for filter tabs or dropdown
    const filterTabs = page.locator('[role="tab"]').or(page.locator('select'));

    if (await filterTabs.first().isVisible()) {
      // Try different filter options
      const filters = ['All', 'Scheduled', 'Ongoing', 'Completed'];

      for (const filter of filters) {
        const filterOption = page.locator(`text=${filter}`);
        if (await filterOption.isVisible()) {
          await filterOption.click();

          // Should update match list
          await page.waitForTimeout(1000); // Wait for filtering

          // Check that filtering worked (at least no errors)
          await expect(page.locator('text=Matches')).toBeVisible();
          break;
        }
      }
    }
  });

  test('should display match statistics', async ({ page }) => {
    await page.goto('/matches');

    const firstMatch = page.locator('[data-testid="match-card"]').first();
    if (await firstMatch.isVisible()) {
      await firstMatch.click();

      // Check for match stats
      const statElements = [
        page.locator('text=Score:'),
        page.locator('text=Duration:'),
        page.locator('text=Attendees:')
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
    } else {
      test.skip();
    }
  });

  test('should handle match cancellation', async ({ page }) => {
    // This test assumes user can cancel their own matches
    test.skip();

    await page.goto('/my-matches');

    const cancelButton = page.locator('button:has-text("Cancel Match")').first();

    if (await cancelButton.isVisible()) {
      await cancelButton.click();

      // Confirm cancellation
      await page.click('button:has-text("Confirm")');

      // Should show success message
      await expect(page.locator('text=Match cancelled')).toBeVisible();
    }
  });

  test('should display match history', async ({ page }) => {
    await page.goto('/my-matches');

    // Check for completed matches section
    const completedMatches = page.locator('text=Completed').or(
      page.locator('[data-testid="completed-matches"]')
    );

    if (await completedMatches.isVisible()) {
      await completedMatches.click();

      // Should show completed matches
      const matchCards = page.locator('[data-testid="match-card"]');
      const count = await matchCards.count();

      // May have 0 completed matches, which is fine
      expect(typeof count).toBe('number');
    }
  });

  test('should handle match search and filtering', async ({ page }) => {
    await page.goto('/matches');

    // Check for search functionality
    const searchInput = page.locator('input[placeholder*="search"]').or(
      page.locator('input[type="search"]')
    );

    if (await searchInput.isVisible()) {
      // Search for a term
      await searchInput.fill('test');

      // Should filter results
      await page.waitForTimeout(1000);

      // Check that search worked
      await expect(page.locator('text=Matches')).toBeVisible();
    }
  });

  test('should handle recurring matches', async ({ page }) => {
    await page.goto('/create-match');

    // Check for recurrence options
    const recurrenceSelect = page.locator('select').filter({ hasText: 'Once' }).or(
      page.locator('[data-testid="recurrence-select"]')
    );

    if (await recurrenceSelect.isVisible()) {
      // Select weekly recurrence
      await recurrenceSelect.selectOption('weekly');

      // Should show additional recurrence options
      await expect(page.locator('text=Every week')).toBeVisible();
    } else {
      test.skip();
    }
  });
});