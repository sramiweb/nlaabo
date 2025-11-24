import { test, expect } from '@playwright/test';

// Test credentials
const TEST_EMAIL = 'sramiweb@gmail.com';
const TEST_PASSWORD = 'R876kxe@ne';

// Viewport configurations
const viewports = {
  mobile: { width: 375, height: 667 }, // iPhone SE
  tablet: { width: 768, height: 1024 }, // iPad
  desktop: { width: 1920, height: 1080 }, // Desktop
  largeDesktop: { width: 2560, height: 1440 } // Large Desktop
};

test.describe('Responsive Design', () => {
  // Test each viewport
  for (const [name, viewport] of Object.entries(viewports)) {
    test.describe(`${name} viewport`, () => {
      test.use({ viewport });

      test.beforeEach(async ({ page }) => {
        // Login before each test
        await page.goto('/login');
        await page.fill('input[type="email"]', TEST_EMAIL);
        await page.fill('input[type="password"]', TEST_PASSWORD);
        await page.click('button:has-text("Login")');
        await expect(page).toHaveURL(/\/home$/);
      });

      test('should display home page correctly', async ({ page }) => {
        // Check main layout elements are visible
        await expect(page.locator('text=Nlaabo')).toBeVisible();

        // Check navigation is accessible
        const navElements = ['Profile', 'Teams', 'Matches'];
        for (const element of navElements) {
          await expect(page.locator(`text=${element}`)).toBeVisible();
        }

        // Check main content area
        const mainContent = page.locator('[data-testid="main-content"]').or(
          page.locator('main').or(page.locator('.main-content'))
        );
        await expect(mainContent).toBeVisible();
      });

      test('should handle navigation menu on small screens', async ({ page }) => {
        if (viewport.width <= 768) {
          // Check for mobile menu button
          const menuButton = page.locator('[data-testid="mobile-menu"]').or(
            page.locator('button[aria-label*="menu"]').or(
              page.locator('.hamburger-menu')
            )
          );

          if (await menuButton.isVisible()) {
            // Open mobile menu
            await menuButton.click();

            // Check menu items are visible
            await expect(page.locator('text=Profile')).toBeVisible();
            await expect(page.locator('text=Teams')).toBeVisible();

            // Close menu
            await menuButton.click();
          }
        } else {
          // Desktop should show full navigation
          await expect(page.locator('nav')).toBeVisible();
        }
      });

      test('should display teams page responsively', async ({ page }) => {
        await page.goto('/teams');

        // Check page title
        await expect(page.locator('text=Teams')).toBeVisible();

        // Check team cards layout
        const teamCards = page.locator('[data-testid="team-card"]');
        const cardCount = await teamCards.count();

        if (cardCount > 0) {
          // Check card layout adapts to screen size
          const firstCard = teamCards.first();
          await expect(firstCard).toBeVisible();

          // Check card content is readable
          const cardText = await firstCard.textContent();
          expect(cardText?.length).toBeGreaterThan(0);
        }
      });

      test('should display matches page responsively', async ({ page }) => {
        await page.goto('/matches');

        // Check page title
        await expect(page.locator('text=Matches')).toBeVisible();

        // Check match cards layout
        const matchCards = page.locator('[data-testid="match-card"]');
        const cardCount = await matchCards.count();

        if (cardCount > 0) {
          const firstCard = matchCards.first();
          await expect(firstCard).toBeVisible();
        }
      });

      test('should display profile page responsively', async ({ page }) => {
        await page.goto('/profile');

        // Check profile layout
        await expect(page.locator('text=Profile')).toBeVisible();

        // Check profile sections are visible
        const profileSections = [
          page.locator('text=Profile Information'),
          page.locator('[data-testid="profile-avatar"]'),
          page.locator('text=Edit Profile')
        ];

        let sectionsVisible = 0;
        for (const section of profileSections) {
          if (await section.isVisible()) {
            sectionsVisible++;
          }
        }

        expect(sectionsVisible).toBeGreaterThan(0);
      });

      test('should handle form layouts responsively', async ({ page }) => {
        await page.goto('/edit-profile');

        // Check form elements are properly sized
        const inputs = page.locator('input');
        const inputCount = await inputs.count();

        expect(inputCount).toBeGreaterThan(0);

        // Check buttons are accessible
        const buttons = page.locator('button');
        const buttonCount = await buttons.count();

        expect(buttonCount).toBeGreaterThan(0);

        // Check no horizontal scrolling
        const scrollWidth = await page.evaluate(() => {
          return document.documentElement.scrollWidth;
        });
        const clientWidth = await page.evaluate(() => {
          return document.documentElement.clientWidth;
        });

        expect(scrollWidth).toBeLessThanOrEqual(clientWidth + 10); // Allow small margin
      });

      test('should display notifications responsively', async ({ page }) => {
        await page.goto('/notifications');

        // Check notification list layout
        const notifications = page.locator('[data-testid="notification-item"]');
        const count = await notifications.count();

        // Check page is usable
        await expect(page.locator('text=Notifications')).toBeVisible();
      });

      test('should handle modal dialogs responsively', async ({ page }) => {
        // Try to trigger a modal (if available)
        const modalTrigger = page.locator('button[data-testid*="modal"]').or(
          page.locator('button[aria-haspopup="dialog"]')
        );

        if (await modalTrigger.isVisible()) {
          await modalTrigger.click();

          // Check modal is properly sized
          const modal = page.locator('[role="dialog"]').or(
            page.locator('.modal').or(page.locator('.dialog'))
          );

          if (await modal.isVisible()) {
            // Check modal doesn't overflow screen
            const modalBox = await modal.boundingBox();
            expect(modalBox?.width).toBeLessThanOrEqual(viewport.width - 20);
            expect(modalBox?.height).toBeLessThanOrEqual(viewport.height - 20);
          }
        }
      });

      test('should display tables responsively', async ({ page }) => {
        // Check if there are any tables in the app
        const tables = page.locator('table');

        if (await tables.isVisible()) {
          // Check table has horizontal scroll on small screens if needed
          const tableBox = await tables.first().boundingBox();

          if (viewport.width <= 768 && tableBox) {
            // Table should either fit or have horizontal scroll
            const hasScroll = await page.evaluate(() => {
              const table = document.querySelector('table');
              return table && (table.scrollWidth > table.clientWidth);
            });

            if (hasScroll) {
              // Should have horizontal scroll container
              const scrollContainer = page.locator('.table-scroll').or(
                page.locator('[data-testid="table-container"]')
              );
              await expect(scrollContainer).toBeVisible();
            }
          }
        }
      });

      test('should handle touch targets appropriately', async ({ page }) => {
        // Check button sizes on touch devices
        const buttons = page.locator('button');
        const buttonCount = await buttons.count();

        if (buttonCount > 0) {
          for (let i = 0; i < Math.min(buttonCount, 3); i++) {
            const button = buttons.nth(i);
            const box = await button.boundingBox();

            if (box) {
              // Touch targets should be at least 44px on mobile
              if (viewport.width <= 768) {
                expect(box.width).toBeGreaterThanOrEqual(44);
                expect(box.height).toBeGreaterThanOrEqual(44);
              } else {
                // Desktop can be smaller
                expect(box.width).toBeGreaterThanOrEqual(32);
                expect(box.height).toBeGreaterThanOrEqual(32);
              }
            }
          }
        }
      });

      test('should display images responsively', async ({ page }) => {
        // Check all images are properly sized
        const images = page.locator('img');
        const imageCount = await images.count();

        for (let i = 0; i < Math.min(imageCount, 5); i++) {
          const img = images.nth(i);
          const box = await img.boundingBox();

          if (box) {
            // Images should not be too large for viewport
            expect(box.width).toBeLessThanOrEqual(viewport.width);
            expect(box.height).toBeLessThanOrEqual(viewport.height);
          }
        }
      });

      test('should handle text scaling', async ({ page }) => {
        // Check text is readable at different sizes
        const headings = page.locator('h1, h2, h3, h4, h5, h6');
        const headingCount = await headings.count();

        if (headingCount > 0) {
          const firstHeading = headings.first();
          const fontSize = await firstHeading.evaluate(el => {
            return parseFloat(getComputedStyle(el).fontSize);
          });

          // Headings should be reasonably sized
          expect(fontSize).toBeGreaterThan(14);
          expect(fontSize).toBeLessThan(100);
        }
      });
    });
  }

  test('should handle orientation changes', async ({ page, browserName }) => {
    // Skip for non-mobile browsers
    test.skip(browserName !== 'webkit' && browserName !== 'chromium');

    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });

    // Login
    await page.goto('/login');
    await page.fill('input[type="email"]', TEST_EMAIL);
    await page.fill('input[type="password"]', TEST_PASSWORD);
    await page.click('button:has-text("Login")');
    await expect(page).toHaveURL(/\/home$/);

    // Simulate landscape orientation
    await page.setViewportSize({ width: 667, height: 375 });

    // Check layout still works
    await expect(page.locator('text=Nlaabo')).toBeVisible();
    await expect(page.locator('text=Profile')).toBeVisible();
  });

  test('should handle zoom levels', async ({ page }) => {
    await page.goto('/login');
    await page.fill('input[type="email"]', TEST_EMAIL);
    await page.fill('input[type="password"]', TEST_PASSWORD);
    await page.click('button:has-text("Login")');
    await expect(page).toHaveURL(/\/home$/);

    // Test 125% zoom
    await page.evaluate(() => {
      document.body.style.zoom = '1.25';
    });

    // Check content is still accessible
    await expect(page.locator('text=Nlaabo')).toBeVisible();

    // Reset zoom
    await page.evaluate(() => {
      document.body.style.zoom = '1';
    });
  });

  test('should work with high contrast mode', async ({ page }) => {
    // This is more of a visual test, but we can check basic functionality
    await page.emulateMedia({ colorScheme: 'dark' });

    await page.goto('/login');
    await page.fill('input[type="email"]', TEST_EMAIL);
    await page.fill('input[type="password"]', TEST_PASSWORD);
    await page.click('button:has-text("Login")');
    await expect(page).toHaveURL(/\/home$/);

    // Check basic elements are still visible in dark mode
    await expect(page.locator('text=Nlaabo')).toBeVisible();
  });
});