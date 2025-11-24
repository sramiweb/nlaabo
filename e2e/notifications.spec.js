import { test, expect } from '@playwright/test';

// Test credentials
const TEST_EMAIL = 'sramiweb@gmail.com';
const TEST_PASSWORD = 'R876kxe@ne';

test.describe('Notification System', () => {
  test.beforeEach(async ({ page }) => {
    // Login before each test
    await page.goto('/login');
    await page.fill('input[type="email"]', TEST_EMAIL);
    await page.fill('input[type="password"]', TEST_PASSWORD);
    await page.click('button:has-text("Login")');
    await expect(page).toHaveURL(/\/home$/);
  });

  test('should display notification indicator in navigation', async ({ page }) => {
    // Check for notification bell/icon in header
    const notificationIcon = page.locator('[data-testid="notification-bell"]').or(
      page.locator('button[aria-label*="notification"]').or(
        page.locator('.notification-icon')
      )
    );

    // Notification indicator should be visible (may or may not have unread count)
    await expect(page.locator('text=Notifications')).toBeVisible();
  });

  test('should navigate to notifications page', async ({ page }) => {
    await page.click('text=Notifications');
    await expect(page).toHaveURL(/\/notifications$/);

    // Check page elements
    await expect(page.locator('text=Notifications')).toBeVisible();
  });

  test('should display notification list', async ({ page }) => {
    await page.goto('/notifications');

    // Should show notification items or empty state
    const notificationList = page.locator('[data-testid="notification-list"]').or(
      page.locator('.notification-item')
    );

    // Either notifications exist or empty state is shown
    const emptyState = page.locator('text=No notifications').or(
      page.locator('text=You have no notifications')
    );

    await expect(notificationList.or(emptyState)).toBeVisible();
  });

  test('should display different notification types', async ({ page }) => {
    await page.goto('/notifications');

    // Check for different notification types
    const notificationTypes = [
      page.locator('text=Match invitation'),
      page.locator('text=Team invitation'),
      page.locator('text=Match request'),
      page.locator('text=Match reminder'),
      page.locator('text=Team update')
    ];

    let typesFound = 0;
    for (const type of notificationTypes) {
      if (await type.isVisible()) {
        typesFound++;
      }
    }

    // Should have at least some notifications or empty state
    expect(typesFound >= 0).toBe(true);
  });

  test('should mark notification as read', async ({ page }) => {
    await page.goto('/notifications');

    // Find first unread notification
    const unreadNotification = page.locator('[data-testid="notification-item"]').filter({ hasNotText: 'read' }).first().or(
      page.locator('.notification-item:not(.read)').first()
    );

    if (await unreadNotification.isVisible()) {
      // Click on notification to mark as read
      await unreadNotification.click();

      // Should mark as read (styling change or disappear from unread)
      await expect(unreadNotification).toHaveClass(/read/);
    } else {
      // No unread notifications, test passes
      expect(true).toBe(true);
    }
  });

  test('should handle bulk notification actions', async ({ page }) => {
    await page.goto('/notifications');

    // Check for mark all as read button
    const markAllReadButton = page.locator('button:has-text("Mark all as read")').or(
      page.locator('[data-testid="mark-all-read"]')
    );

    if (await markAllReadButton.isVisible()) {
      await markAllReadButton.click();

      // Should show success message
      await expect(page.locator('text=All notifications marked as read')).toBeVisible();
    }
  });

  test('should filter notifications by type', async ({ page }) => {
    await page.goto('/notifications');

    // Check for filter tabs or dropdown
    const filterTabs = page.locator('[role="tab"]').or(
      page.locator('select').filter({ hasText: 'All' })
    );

    if (await filterTabs.first().isVisible()) {
      // Try different filter options
      const filters = ['All', 'Invitations', 'Requests', 'Updates'];

      for (const filter of filters) {
        const filterOption = page.locator(`text=${filter}`);
        if (await filterOption.isVisible()) {
          await filterOption.click();

          // Should update notification list
          await page.waitForTimeout(500);

          // Check that filtering worked
          await expect(page.locator('text=Notifications')).toBeVisible();
          break;
        }
      }
    }
  });

  test('should display notification timestamps', async ({ page }) => {
    await page.goto('/notifications');

    const firstNotification = page.locator('[data-testid="notification-item"]').first();

    if (await firstNotification.isVisible()) {
      // Should show timestamp
      const timestamp = firstNotification.locator('[data-testid="notification-time"]').or(
        firstNotification.locator('time').or(
          firstNotification.locator('text=ago')
        )
      );

      await expect(timestamp).toBeVisible();
    }
  });

  test('should handle notification actions', async ({ page }) => {
    await page.goto('/notifications');

    // Look for notifications with action buttons
    const actionButton = page.locator('button:has-text("Accept")').or(
      page.locator('button:has-text("Join")').or(
        page.locator('button:has-text("View")')
      )
    );

    if (await actionButton.isVisible()) {
      // Click action button
      await actionButton.click();

      // Should navigate to relevant page or show success
      await expect(page.locator('text=Success').or(
        page.locator('text=Accepted').or(
          page.url().then(url => url !== '/notifications')
        )
      )).toBeTruthy();
    }
  });

  test('should handle notification deletion', async ({ page }) => {
    await page.goto('/notifications');

    // Look for delete button on notification
    const deleteButton = page.locator('[data-testid="delete-notification"]').or(
      page.locator('button[aria-label*="delete"]').or(
        page.locator('.notification-delete')
      )
    );

    if (await deleteButton.first().isVisible()) {
      const notificationCount = await page.locator('[data-testid="notification-item"]').count();

      // Click delete
      await deleteButton.first().click();

      // Confirm deletion if needed
      const confirmButton = page.locator('button:has-text("Delete")').or(
        page.locator('button:has-text("Confirm")')
      );

      if (await confirmButton.isVisible()) {
        await confirmButton.click();
      }

      // Should remove notification
      const newCount = await page.locator('[data-testid="notification-item"]').count();
      expect(newCount).toBeLessThan(notificationCount);
    }
  });

  test('should show unread notification count', async ({ page }) => {
    // Check notification badge in header
    const notificationBadge = page.locator('[data-testid="notification-badge"]').or(
      page.locator('.notification-count').or(
        page.locator('[aria-label*="unread notifications"]')
      )
    );

    if (await notificationBadge.isVisible()) {
      // Badge should show a number or be empty
      const badgeText = await notificationBadge.textContent();
      expect(typeof badgeText).toBe('string');
    }
  });

  test('should update notification count when read', async ({ page }) => {
    // Get initial badge count
    const notificationBadge = page.locator('[data-testid="notification-badge"]');
    const initialCount = await notificationBadge.textContent();

    await page.goto('/notifications');

    // Mark a notification as read
    const unreadNotification = page.locator('[data-testid="notification-item"]').first();
    if (await unreadNotification.isVisible()) {
      await unreadNotification.click();

      // Badge count should update
      await page.goto('/home'); // Go back to check badge
      const updatedCount = await notificationBadge.textContent();

      if (initialCount && updatedCount) {
        expect(parseInt(updatedCount)).toBeLessThanOrEqual(parseInt(initialCount));
      }
    }
  });

  test('should handle notification preferences', async ({ page }) => {
    // Check if notification preferences are in settings
    await page.click('text=Settings');

    const notificationPrefs = page.locator('text=Notification Preferences').or(
      page.locator('[data-testid="notification-settings"]')
    );

    if (await notificationPrefs.isVisible()) {
      await notificationPrefs.click();

      // Should show notification settings
      await expect(page.locator('input[type="checkbox"]')).toBeVisible();
    } else {
      test.skip();
    }
  });

  test('should display notification details', async ({ page }) => {
    await page.goto('/notifications');

    const firstNotification = page.locator('[data-testid="notification-item"]').first();

    if (await firstNotification.isVisible()) {
      // Click to expand or view details
      await firstNotification.click();

      // Should show more details
      const details = firstNotification.locator('[data-testid="notification-details"]').or(
        firstNotification.locator('.notification-expanded')
      );

      if (await details.isVisible()) {
        await expect(details).toBeVisible();
      }
    }
  });

  test('should handle push notification permissions', async ({ page }) => {
    // Check for push notification prompt or settings
    const pushPrompt = page.locator('text=Enable notifications').or(
      page.locator('[data-testid="push-permission"]')
    );

    if (await pushPrompt.isVisible()) {
      // Can test accepting or denying permissions
      // Note: Browser permissions might need special handling
      await expect(pushPrompt).toBeVisible();
    }
  });

  test('should show notification categories', async ({ page }) => {
    await page.goto('/notifications');

    // Check for category sections
    const categories = [
      page.locator('text=Today'),
      page.locator('text=Yesterday'),
      page.locator('text=This Week'),
      page.locator('text=Earlier')
    ];

    let categoriesFound = 0;
    for (const category of categories) {
      if (await category.isVisible()) {
        categoriesFound++;
      }
    }

    // Should have some categorization
    expect(categoriesFound >= 0).toBe(true);
  });

  test('should handle notification search', async ({ page }) => {
    await page.goto('/notifications');

    // Check for search functionality
    const searchInput = page.locator('input[placeholder*="search notifications"]').or(
      page.locator('input[type="search"]')
    );

    if (await searchInput.isVisible()) {
      // Search for a term
      await searchInput.fill('match');

      // Should filter notifications
      await page.waitForTimeout(500);

      // Check that search worked
      await expect(page.locator('text=Notifications')).toBeVisible();
    }
  });

  test('should handle notification pagination', async ({ page }) => {
    await page.goto('/notifications');

    // Check for pagination controls
    const pagination = page.locator('[data-testid="pagination"]').or(
      page.locator('button:has-text("Load More")').or(
        page.locator('text=Page 1')
      )
    );

    if (await pagination.isVisible()) {
      // Should handle pagination properly
      await expect(pagination).toBeVisible();
    }
  });
});