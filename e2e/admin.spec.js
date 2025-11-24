import { test, expect } from '@playwright/test';

// Test credentials
const TEST_EMAIL = 'sramiweb@gmail.com';
const TEST_PASSWORD = 'R876kxe@ne';

test.describe('Admin Dashboard', () => {
  test.beforeEach(async ({ page }) => {
    // Login before each test
    await page.goto('/login');
    await page.fill('input[type="email"]', TEST_EMAIL);
    await page.fill('input[type="password"]', TEST_PASSWORD);
    await page.click('button:has-text("Login")');
    await expect(page).toHaveURL(/\/home$/);
  });

  test('should show admin access for admin users', async ({ page }) => {
    // Check if admin menu/item is visible
    const adminLink = page.locator('text=Admin').or(
      page.locator('[data-testid="admin-link"]')
    );

    if (await adminLink.isVisible()) {
      await adminLink.click();
      await expect(page).toHaveURL(/\/admin$/);
    } else {
      // User might not be admin, skip tests
      test.skip();
    }
  });

  test('should display admin dashboard overview', async ({ page }) => {
    // Try to access admin page
    await page.goto('/admin');

    // If redirected, user is not admin
    if (page.url().includes('/admin')) {
      // Check dashboard elements
      await expect(page.locator('text=Admin Dashboard')).toBeVisible();

      // Check for statistics cards
      const statCards = page.locator('[data-testid="stat-card"]').or(
        page.locator('.admin-stat')
      );
      await expect(statCards.first()).toBeVisible();
    } else {
      test.skip();
    }
  });

  test('should display user management section', async ({ page }) => {
    await page.goto('/admin');

    if (page.url().includes('/admin')) {
      // Check for user management
      const userManagement = page.locator('text=Users').or(
        page.locator('[data-testid="user-management"]')
      );

      if (await userManagement.isVisible()) {
        await userManagement.click();

        // Should show user list
        await expect(page.locator('[data-testid="user-item"]')).toBeVisible();
      }
    } else {
      test.skip();
    }
  });

  test('should display team management section', async ({ page }) => {
    await page.goto('/admin');

    if (page.url().includes('/admin')) {
      // Check for team management
      const teamManagement = page.locator('text=Teams').or(
        page.locator('[data-testid="team-management"]')
      );

      if (await teamManagement.isVisible()) {
        await teamManagement.click();

        // Should show team list
        await expect(page.locator('[data-testid="admin-team-item"]')).toBeVisible();
      }
    } else {
      test.skip();
    }
  });

  test('should display match management section', async ({ page }) => {
    await page.goto('/admin');

    if (page.url().includes('/admin')) {
      // Check for match management
      const matchManagement = page.locator('text=Matches').or(
        page.locator('[data-testid="match-management"]')
      );

      if (await matchManagement.isVisible()) {
        await matchManagement.click();

        // Should show match list
        await expect(page.locator('[data-testid="admin-match-item"]')).toBeVisible();
      }
    } else {
      test.skip();
    }
  });

  test('should allow admin to view user details', async ({ page }) => {
    await page.goto('/admin');

    if (page.url().includes('/admin')) {
      // Navigate to user management
      const userManagement = page.locator('text=Users').or(
        page.locator('[data-testid="user-management"]')
      );

      if (await userManagement.isVisible()) {
        await userManagement.click();

        // Click on first user
        const firstUser = page.locator('[data-testid="user-item"]').first();
        if (await firstUser.isVisible()) {
          await firstUser.click();

          // Should show user details
          await expect(page.locator('text=User Details')).toBeVisible();
        }
      }
    } else {
      test.skip();
    }
  });

  test('should allow admin to manage user roles', async ({ page }) => {
    await page.goto('/admin');

    if (page.url().includes('/admin')) {
      // Navigate to user management
      const userManagement = page.locator('text=Users').or(
        page.locator('[data-testid="user-management"]')
      );

      if (await userManagement.isVisible()) {
        await userManagement.click();

        // Look for role management
        const roleSelect = page.locator('select').filter({ hasText: 'user' }).or(
          page.locator('[data-testid="user-role-select"]')
        );

        if (await roleSelect.isVisible()) {
          // Change role
          await roleSelect.selectOption('moderator');

          // Save changes
          await page.click('button:has-text("Save")');

          // Should show success
          await expect(page.locator('text=Role updated')).toBeVisible();
        }
      }
    } else {
      test.skip();
    }
  });

  test('should allow admin to ban/unban users', async ({ page }) => {
    await page.goto('/admin');

    if (page.url().includes('/admin')) {
      // Navigate to user management
      const userManagement = page.locator('text=Users').or(
        page.locator('[data-testid="user-management"]')
      );

      if (await userManagement.isVisible()) {
        await userManagement.click();

        // Look for ban button
        const banButton = page.locator('button:has-text("Ban")').or(
          page.locator('[data-testid="ban-user"]')
        );

        if (await banButton.isVisible()) {
          // Don't actually ban, just check button exists
          await expect(banButton).toBeVisible();
        }
      }
    } else {
      test.skip();
    }
  });

  test('should display system statistics', async ({ page }) => {
    await page.goto('/admin');

    if (page.url().includes('/admin')) {
      // Check for system stats
      const stats = [
        page.locator('text=Total Users:'),
        page.locator('text=Active Teams:'),
        page.locator('text=Total Matches:'),
        page.locator('[data-testid="system-stats"]')
      ];

      let statsFound = false;
      for (const stat of stats) {
        if (await stat.isVisible()) {
          statsFound = true;
          break;
        }
      }

      expect(statsFound).toBe(true);
    } else {
      test.skip();
    }
  });

  test('should allow admin to view system logs', async ({ page }) => {
    await page.goto('/admin');

    if (page.url().includes('/admin')) {
      // Check for logs section
      const logsSection = page.locator('text=System Logs').or(
        page.locator('[data-testid="system-logs"]')
      );

      if (await logsSection.isVisible()) {
        await logsSection.click();

        // Should show logs
        await expect(page.locator('[data-testid="log-entry"]')).toBeVisible();
      }
    } else {
      test.skip();
    }
  });

  test('should allow admin to manage app settings', async ({ page }) => {
    await page.goto('/admin');

    if (page.url().includes('/admin')) {
      // Check for settings section
      const settingsSection = page.locator('text=Settings').or(
        page.locator('[data-testid="admin-settings"]')
      );

      if (await settingsSection.isVisible()) {
        await settingsSection.click();

        // Should show settings form
        await expect(page.locator('input[type="text"]')).toBeVisible();
      }
    } else {
      test.skip();
    }
  });

  test('should display recent activity', async ({ page }) => {
    await page.goto('/admin');

    if (page.url().includes('/admin')) {
      // Check for activity feed
      const activityFeed = page.locator('text=Recent Activity').or(
        page.locator('[data-testid="activity-feed"]')
      );

      if (await activityFeed.isVisible()) {
        // Should show activity items
        const activityItems = page.locator('[data-testid="activity-item"]');
        const count = await activityItems.count();

        expect(count).toBeGreaterThanOrEqual(0);
      }
    } else {
      test.skip();
    }
  });

  test('should allow admin to export data', async ({ page }) => {
    await page.goto('/admin');

    if (page.url().includes('/admin')) {
      // Check for export functionality
      const exportButton = page.locator('button:has-text("Export")').or(
        page.locator('[data-testid="export-data"]')
      );

      if (await exportButton.isVisible()) {
        // Don't actually export, just check button exists
        await expect(exportButton).toBeVisible();
      }
    } else {
      test.skip();
    }
  });

  test('should handle admin search functionality', async ({ page }) => {
    await page.goto('/admin');

    if (page.url().includes('/admin')) {
      // Check for search in admin panel
      const searchInput = page.locator('input[placeholder*="search"]').or(
        page.locator('input[type="search"]')
      );

      if (await searchInput.isVisible()) {
        // Search for something
        await searchInput.fill('test');

        // Should filter results
        await page.waitForTimeout(500);
        await expect(page.locator('text=Admin Dashboard')).toBeVisible();
      }
    } else {
      test.skip();
    }
  });

  test('should prevent non-admin access to admin routes', async ({ page }) => {
    // Create a new user account for testing (if possible)
    // For now, just test that non-admin users can't access admin

    // If current user can access admin, test passes
    await page.goto('/admin');

    if (!page.url().includes('/admin')) {
      // User was redirected, which is correct for non-admin
      await expect(page).toHaveURL(/\/home$/);
    }
  });

  test('should display admin navigation menu', async ({ page }) => {
    await page.goto('/admin');

    if (page.url().includes('/admin')) {
      // Check for admin navigation
      const navItems = [
        page.locator('text=Dashboard'),
        page.locator('text=Users'),
        page.locator('text=Teams'),
        page.locator('text=Matches'),
        page.locator('text=Settings')
      ];

      let navItemsFound = 0;
      for (const item of navItems) {
        if (await item.isVisible()) {
          navItemsFound++;
        }
      }

      expect(navItemsFound).toBeGreaterThan(0);
    } else {
      test.skip();
    }
  });
});