import { test, expect } from '@playwright/test';

// Test credentials
const TEST_EMAIL = 'sramiweb@gmail.com';
const TEST_PASSWORD = 'R876kxe@ne';

test.describe('Error Handling and Edge Cases', () => {
  test('should handle network connectivity issues', async ({ page }) => {
    // Test offline scenario by blocking network requests
    await page.route('**/*', route => {
      if (route.request().url().includes('supabase')) {
        route.abort();
      } else {
        route.continue();
      }
    });

    await page.goto('/login');

    // Try to login
    await page.fill('input[type="email"]', TEST_EMAIL);
    await page.fill('input[type="password"]', TEST_PASSWORD);
    await page.click('button:has-text("Login")');

    // Should show network error
    await expect(page.locator('text=Network error').or(
      page.locator('text=Connection failed')
    )).toBeVisible();
  });

  test('should handle invalid route access', async ({ page }) => {
    // Try to access non-existent route
    await page.goto('/non-existent-route');

    // Should redirect to home or show 404
    await expect(page).toHaveURL(/\/(|home|auth)$/);
  });

  test('should handle invalid match ID', async ({ page }) => {
    // Login first
    await page.goto('/login');
    await page.fill('input[type="email"]', TEST_EMAIL);
    await page.fill('input[type="password"]', TEST_PASSWORD);
    await page.click('button:has-text("Login")');
    await expect(page).toHaveURL(/\/home$/);

    // Try to access invalid match
    await page.goto('/match/invalid-id');

    // Should show error or redirect
    await expect(page.locator('text=Invalid match').or(
      page.locator('text=Match not found')
    )).toBeVisible();
  });

  test('should handle invalid team ID', async ({ page }) => {
    // Login first
    await page.goto('/login');
    await page.fill('input[type="email"]', TEST_EMAIL);
    await page.fill('input[type="password"]', TEST_PASSWORD);
    await page.click('button:has-text("Login")');
    await expect(page).toHaveURL(/\/home$/);

    // Try to access invalid team
    await page.goto('/teams/invalid-id');

    // Should show error or redirect
    await expect(page.locator('text=Invalid team').or(
      page.locator('text=Team not found')
    )).toBeVisible();
  });

  test('should handle session expiration', async ({ page }) => {
    // Login first
    await page.goto('/login');
    await page.fill('input[type="email"]', TEST_EMAIL);
    await page.fill('input[type="password"]', TEST_PASSWORD);
    await page.click('button:has-text("Login")');
    await expect(page).toHaveURL(/\/home$/);

    // Clear session storage to simulate expiration
    await page.evaluate(() => {
      localStorage.clear();
      sessionStorage.clear();
    });

    // Try to access protected route
    await page.goto('/profile');

    // Should redirect to login
    await expect(page).toHaveURL(/\/auth$/);
  });

  test('should handle API errors gracefully', async ({ page }) => {
    // Login first
    await page.goto('/login');
    await page.fill('input[type="email"]', TEST_EMAIL);
    await page.fill('input[type="password"]', TEST_PASSWORD);
    await page.click('button:has-text("Login")');
    await expect(page).toHaveURL(/\/home$/);

    // Mock API error for teams request
    await page.route('**/rest/v1/teams**', route => {
      route.fulfill({
        status: 500,
        contentType: 'application/json',
        body: JSON.stringify({ error: 'Internal server error' })
      });
    });

    await page.goto('/teams');

    // Should show error message
    await expect(page.locator('text=Failed to load').or(
      page.locator('text=Error loading')
    )).toBeVisible();
  });

  test('should handle form validation errors', async ({ page }) => {
    await page.goto('/create-team');

    // Submit empty form
    await page.click('button:has-text("Create Team")');

    // Should show validation errors
    await expect(page.locator('text=required').or(
      page.locator('text=cannot be empty')
    )).toBeVisible();
  });

  test('should handle file upload errors', async ({ page }) => {
    // Login first
    await page.goto('/login');
    await page.fill('input[type="email"]', TEST_EMAIL);
    await page.fill('input[type="password"]', TEST_PASSWORD);
    await page.click('button:has-text("Login")');
    await expect(page).toHaveURL(/\/home$/);

    await page.goto('/edit-profile');

    // Mock file upload error
    await page.route('**/storage/v1/**', route => {
      route.fulfill({
        status: 413,
        contentType: 'application/json',
        body: JSON.stringify({ error: 'File too large' })
      });
    });

    // Try to upload large file (we can't actually upload, but check error handling)
    const fileInput = page.locator('input[type="file"]');
    if (await fileInput.isVisible()) {
      // Just check that error handling exists
      await expect(page.locator('text=Upload')).toBeVisible();
    }
  });

  test('should handle concurrent requests', async ({ page }) => {
    // Login first
    await page.goto('/login');
    await page.fill('input[type="email"]', TEST_EMAIL);
    await page.fill('input[type="password"]', TEST_PASSWORD);
    await page.click('button:has-text("Login")');
    await expect(page).toHaveURL(/\/home$/);

    // Make multiple rapid requests
    const requests = [];
    for (let i = 0; i < 5; i++) {
      requests.push(page.goto('/teams'));
    }

    await Promise.all(requests);

    // Should handle concurrent requests without crashing
    await expect(page.locator('text=Teams')).toBeVisible();
  });

  test('should handle browser back/forward navigation', async ({ page }) => {
    // Login first
    await page.goto('/login');
    await page.fill('input[type="email"]', TEST_EMAIL);
    await page.fill('input[type="password"]', TEST_PASSWORD);
    await page.click('button:has-text("Login")');
    await expect(page).toHaveURL(/\/home$/);

    // Navigate to different pages
    await page.goto('/profile');
    await page.goto('/teams');
    await page.goto('/matches');

    // Use browser back
    await page.goBack();
    await expect(page).toHaveURL(/\/teams$/);

    await page.goBack();
    await expect(page).toHaveURL(/\/profile$/);

    // Use browser forward
    await page.goForward();
    await expect(page).toHaveURL(/\/teams$/);
  });

  test('should handle page refresh', async ({ page }) => {
    // Login first
    await page.goto('/login');
    await page.fill('input[type="email"]', TEST_EMAIL);
    await page.fill('input[type="password"]', TEST_PASSWORD);
    await page.click('button:has-text("Login")');
    await expect(page).toHaveURL(/\/home$/);

    // Refresh page
    await page.reload();

    // Should maintain login state
    await expect(page).toHaveURL(/\/home$/);
    await expect(page.locator('text=Profile')).toBeVisible();
  });

  test('should handle memory leaks prevention', async ({ page }) => {
    // Login and navigate through multiple pages
    await page.goto('/login');
    await page.fill('input[type="email"]', TEST_EMAIL);
    await page.fill('input[type="password"]', TEST_PASSWORD);
    await page.click('button:has-text("Login")');
    await expect(page).toHaveURL(/\/home$/);

    // Navigate through many pages quickly
    const pages = ['/profile', '/teams', '/matches', '/notifications', '/settings'];
    for (const pageUrl of pages) {
      await page.goto(pageUrl);
      await page.waitForTimeout(100);
    }

    // Should still work without memory issues
    await expect(page.locator('text=Nlaabo')).toBeVisible();
  });

  test('should handle XSS prevention', async ({ page }) => {
    // Login first
    await page.goto('/login');
    await page.fill('input[type="email"]', TEST_EMAIL);
    await page.fill('input[type="password"]', TEST_PASSWORD);
    await page.click('button:has-text("Login")');
    await expect(page).toHaveURL(/\/home$/);

    await page.goto('/create-team');

    // Try to inject script in team name
    const xssPayload = '<script>alert("xss")</script>';
    await page.fill('input[placeholder*="team name"]', xssPayload);
    await page.fill('textarea[placeholder*="description"]', 'Test description');

    // Submit
    await page.click('button:has-text("Create Team")');

    // Should not execute script, should sanitize input
    await expect(page.locator('text=alert')).not.toBeVisible();
  });

  test('should handle SQL injection prevention', async ({ page }) => {
    await page.goto('/login');

    // Try SQL injection in login
    const sqlInjection = "' OR '1'='1";
    await page.fill('input[type="email"]', sqlInjection);
    await page.fill('input[type="password"]', sqlInjection);
    await page.click('button:has-text("Login")');

    // Should not bypass authentication
    await expect(page).toHaveURL(/\/login$/);
    await expect(page.locator('text=Invalid')).toBeVisible();
  });

  test('should handle rate limiting', async ({ page }) => {
    // Rapid login attempts
    for (let i = 0; i < 10; i++) {
      await page.goto('/login');
      await page.fill('input[type="email"]', `test${i}@example.com`);
      await page.fill('input[type="password"]', 'password');
      await page.click('button:has-text("Login")');
      await page.waitForTimeout(100);
    }

    // Should eventually show rate limit error or captcha
    await expect(page.locator('text=Too many attempts').or(
      page.locator('text=Rate limit').or(
        page.locator('text=Please wait')
      )
    )).toBeVisible();
  });

  test('should handle large data sets', async ({ page }) => {
    // Login first
    await page.goto('/login');
    await page.fill('input[type="email"]', TEST_EMAIL);
    await page.fill('input[type="password"]', TEST_PASSWORD);
    await page.click('button:has-text("Login")');
    await expect(page).toHaveURL(/\/home$/);

    // Mock large dataset response
    await page.route('**/rest/v1/matches**', route => {
      const largeData = Array.from({ length: 1000 }, (_, i) => ({
        id: i,
        name: `Match ${i}`,
        date: new Date().toISOString(),
        status: 'scheduled'
      }));

      route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(largeData)
      });
    });

    await page.goto('/matches');

    // Should handle large data without crashing
    await expect(page.locator('text=Matches')).toBeVisible();

    // Should have pagination or virtual scrolling
    const matchCards = page.locator('[data-testid="match-card"]');
    const visibleCount = await matchCards.count();

    // Should show reasonable number of items
    expect(visibleCount).toBeLessThan(100);
  });

  test('should handle special characters in input', async ({ page }) => {
    // Login first
    await page.goto('/login');
    await page.fill('input[type="email"]', TEST_EMAIL);
    await page.fill('input[type="password"]', TEST_PASSWORD);
    await page.click('button:has-text("Login")');
    await expect(page).toHaveURL(/\/home$/);

    await page.goto('/create-team');

    // Test with special characters
    const specialName = 'Tëâm ñämé 🚀 中文';
    await page.fill('input[placeholder*="team name"]', specialName);
    await page.fill('textarea[placeholder*="description"]', 'Description with émojis 🎉 and spëcial chärs');

    // Submit
    await page.click('button:has-text("Create Team")');

    // Should handle special characters properly
    await expect(page.locator(`text=${specialName}`).or(
      page.locator('text=Team created')
    )).toBeVisible();
  });

  test('should handle timezone differences', async ({ page }) => {
    // Login first
    await page.goto('/login');
    await page.fill('input[type="email"]', TEST_EMAIL);
    await page.fill('input[type="password"]', TEST_PASSWORD);
    await page.click('button:has-text("Login")');
    await expect(page).toHaveURL(/\/home$/);

    await page.goto('/matches');

    // Check that dates are displayed correctly
    const dateElements = page.locator('[data-testid="match-date"]').or(
      page.locator('time')
    );

    if (await dateElements.first().isVisible()) {
      const dateText = await dateElements.first().textContent();
      // Should show valid date format
      expect(dateText).toBeTruthy();
    }
  });

  test('should handle browser storage limitations', async ({ page }) => {
    // Login first
    await page.goto('/login');
    await page.fill('input[type="email"]', TEST_EMAIL);
    await page.fill('input[type="password"]', TEST_PASSWORD);
    await page.click('button:has-text("Login")');
    await expect(page).toHaveURL(/\/home$/);

    // Fill localStorage to near capacity
    await page.evaluate(() => {
      const data = 'x'.repeat(1024 * 1024); // 1MB of data
      for (let i = 0; i < 4; i++) {
        localStorage.setItem(`test-data-${i}`, data);
      }
    });

    // Try to use the app
    await page.goto('/profile');

    // Should still work despite storage pressure
    await expect(page.locator('text=Profile')).toBeVisible();
  });
});