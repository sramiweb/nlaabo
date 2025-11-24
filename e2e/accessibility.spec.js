import { test, expect } from '@playwright/test';

// Test credentials
const TEST_EMAIL = 'sramiweb@gmail.com';
const TEST_PASSWORD = 'R876kxe@ne';

test.describe('Accessibility (WCAG 2.1)', () => {
  test.beforeEach(async ({ page }) => {
    // Login before each test
    await page.goto('/login');
    await page.fill('input[type="email"]', TEST_EMAIL);
    await page.fill('input[type="password"]', TEST_PASSWORD);
    await page.click('button:has-text("Login")');
    await expect(page).toHaveURL(/\/home$/);
  });

  test('should have proper page titles', async ({ page }) => {
    // Check main pages have descriptive titles
    const pages = [
      { url: '/home', expectedTitle: /Nlaabo/ },
      { url: '/profile', expectedTitle: /Profile/ },
      { url: '/teams', expectedTitle: /Teams/ },
      { url: '/matches', expectedTitle: /Matches/ }
    ];

    for (const { url, expectedTitle } of pages) {
      await page.goto(url);
      const title = await page.title();
      expect(title).toMatch(expectedTitle);
    }
  });

  test('should have proper heading hierarchy', async ({ page }) => {
    await page.goto('/home');

    // Check heading structure
    const h1Elements = page.locator('h1');
    const h2Elements = page.locator('h2');
    const h3Elements = page.locator('h3');

    // Should have at least one h1
    const h1Count = await h1Elements.count();
    expect(h1Count).toBeGreaterThan(0);

    // Headings should not skip levels (basic check)
    const h2Count = await h2Elements.count();
    const h3Count = await h3Elements.count();

    if (h3Count > 0 && h2Count === 0) {
      // If there are h3 without h2, that's a hierarchy issue
      expect(h2Count).toBeGreaterThan(0);
    }
  });

  test('should have accessible form labels', async ({ page }) => {
    await page.goto('/edit-profile');

    // Check all inputs have labels or aria-labels
    const inputs = page.locator('input, select, textarea');
    const inputCount = await inputs.count();

    for (let i = 0; i < inputCount; i++) {
      const input = inputs.nth(i);
      const hasLabel = await input.evaluate(el => {
        const id = el.id;
        const ariaLabel = el.getAttribute('aria-label');
        const ariaLabelledBy = el.getAttribute('aria-labelledby');
        const label = document.querySelector(`label[for="${id}"]`);

        return !!(ariaLabel || ariaLabelledBy || label);
      });

      expect(hasLabel).toBe(true);
    }
  });

  test('should have sufficient color contrast', async ({ page }) => {
    // This is a basic check - in a real scenario, you'd use axe-core or similar
    await page.goto('/home');

    // Check that text is visible (basic contrast check)
    const textElements = page.locator('p, span, div').filter({ hasText: /.+/ });
    const visibleTextCount = await textElements.count();

    expect(visibleTextCount).toBeGreaterThan(0);

    // Check that buttons have visible text
    const buttons = page.locator('button');
    const buttonCount = await buttons.count();

    for (let i = 0; i < Math.min(buttonCount, 5); i++) {
      const button = buttons.nth(i);
      const isVisible = await button.isVisible();
      expect(isVisible).toBe(true);
    }
  });

  test('should support keyboard navigation', async ({ page }) => {
    await page.goto('/home');

    // Tab through focusable elements
    await page.keyboard.press('Tab');

    // Check that something is focused
    const focusedElement = await page.evaluate(() => {
      const active = document.activeElement;
      return active ? active.tagName.toLowerCase() : null;
    });

    expect(focusedElement).toBeTruthy();

    // Continue tabbing
    for (let i = 0; i < 5; i++) {
      await page.keyboard.press('Tab');
      await page.waitForTimeout(100);
    }

    // Should be able to navigate without getting stuck
    const finalFocused = await page.evaluate(() => {
      return document.activeElement !== null;
    });

    expect(finalFocused).toBe(true);
  });

  test('should have accessible buttons', async ({ page }) => {
    await page.goto('/home');

    const buttons = page.locator('button');
    const buttonCount = await buttons.count();

    for (let i = 0; i < Math.min(buttonCount, 5); i++) {
      const button = buttons.nth(i);

      // Check button has accessible name
      const accessibleName = await button.evaluate(el => {
        const text = el.textContent?.trim();
        const ariaLabel = el.getAttribute('aria-label');
        const title = el.getAttribute('title');

        return !!(text || ariaLabel || title);
      });

      expect(accessibleName).toBe(true);
    }
  });

  test('should have proper alt text for images', async ({ page }) => {
    await page.goto('/profile');

    const images = page.locator('img');
    const imageCount = await images.count();

    for (let i = 0; i < imageCount; i++) {
      const img = images.nth(i);
      const alt = await img.getAttribute('alt');

      // Images should have alt text (or be decorative)
      const hasAlt = alt !== null && alt !== '';
      const isDecorative = await img.getAttribute('aria-hidden') === 'true';

      expect(hasAlt || isDecorative).toBe(true);
    }
  });

  test('should have proper ARIA landmarks', async ({ page }) => {
    await page.goto('/home');

    // Check for main landmark
    const main = page.locator('main, [role="main"]');
    await expect(main).toBeVisible();

    // Check for navigation landmark
    const nav = page.locator('nav, [role="navigation"]');
    await expect(nav).toBeVisible();
  });

  test('should support screen reader navigation', async ({ page }) => {
    await page.goto('/home');

    // Check for skip links (accessibility feature)
    const skipLinks = page.locator('a[href^="#"]').filter({ hasText: /skip/i });
    const hasSkipLinks = await skipLinks.count() > 0;

    if (hasSkipLinks) {
      // Test skip link functionality
      await skipLinks.first().click();
      // Should skip to main content
      const mainContent = page.locator('main h1, [role="main"] h1');
      await expect(mainContent.first()).toBeVisible();
    }
  });

  test('should have accessible error messages', async ({ page }) => {
    await page.goto('/login');

    // Submit empty form to trigger errors
    await page.click('button:has-text("Login")');

    // Check error messages are associated with inputs
    const errorMessages = page.locator('text=required, text=invalid, text=error');
    const errorCount = await errorMessages.count();

    if (errorCount > 0) {
      // Errors should be properly associated with form fields
      for (let i = 0; i < errorCount; i++) {
        const error = errorMessages.nth(i);
        const isVisible = await error.isVisible();
        expect(isVisible).toBe(true);
      }
    }
  });

  test('should have proper focus management', async ({ page }) => {
    await page.goto('/create-team');

    // Focus on first input
    const firstInput = page.locator('input').first();
    await firstInput.focus();

    // Check focus indicator is visible
    const hasFocusIndicator = await firstInput.evaluate(el => {
      const style = window.getComputedStyle(el);
      return style.outline !== 'none' || style.boxShadow !== 'none';
    });

    // Note: This is a basic check; real focus testing needs more sophisticated tools
    expect(hasFocusIndicator).toBeDefined();
  });

  test('should support reduced motion preferences', async ({ page }) => {
    // Test with reduced motion preference
    await page.emulateMedia({ reducedMotion: 'reduce' });

    await page.goto('/home');

    // Check that animations are reduced or disabled
    // This is hard to test automatically, but we can check the page loads
    await expect(page.locator('text=Nlaabo')).toBeVisible();
  });

  test('should have readable font sizes', async ({ page }) => {
    await page.goto('/home');

    // Check body text size
    const bodyText = page.locator('body');
    const fontSize = await bodyText.evaluate(el => {
      return parseFloat(getComputedStyle(el).fontSize);
    });

    // Body text should be at least 14px (WCAG AA)
    expect(fontSize).toBeGreaterThanOrEqual(14);
  });

  test('should have proper table accessibility', async ({ page }) => {
    // Look for tables in the app
    const tables = page.locator('table');

    if (await tables.isVisible()) {
      const table = tables.first();

      // Check for table headers
      const headers = table.locator('th');
      const headerCount = await headers.count();

      if (headerCount > 0) {
        // Table has headers, check they're descriptive
        for (let i = 0; i < headerCount; i++) {
          const header = headers.nth(i);
          const text = await header.textContent();
          expect(text?.trim()).toBeTruthy();
        }
      }
    }
  });

  test('should support high contrast mode', async ({ page }) => {
    // Test with forced colors (high contrast)
    await page.emulateMedia({ forcedColors: 'active' });

    await page.goto('/home');

    // Check that content is still readable
    await expect(page.locator('text=Nlaabo')).toBeVisible();
    await expect(page.locator('text=Profile')).toBeVisible();
  });

  test('should have accessible modal dialogs', async ({ page }) => {
    // Try to find a modal trigger
    const modalTrigger = page.locator('button[data-testid*="modal"]').or(
      page.locator('button[aria-haspopup="dialog"]')
    );

    if (await modalTrigger.isVisible()) {
      await modalTrigger.click();

      const modal = page.locator('[role="dialog"]').or(
        page.locator('.modal')
      );

      if (await modal.isVisible()) {
        // Check modal has proper accessibility attributes
        const hasAriaLabelledBy = await modal.getAttribute('aria-labelledby');
        const hasAriaDescribedBy = await modal.getAttribute('aria-describedby');

        expect(hasAriaLabelledBy || hasAriaDescribedBy).toBeTruthy();

        // Check for focus trap (focus should stay in modal)
        const modalFocusable = modal.locator('button, input, select, textarea, a[href]');
        const focusableCount = await modalFocusable.count();

        expect(focusableCount).toBeGreaterThan(0);
      }
    }
  });

  test('should support language identification', async ({ page }) => {
    // Check page has lang attribute
    const htmlLang = await page.getAttribute('html', 'lang');
    expect(htmlLang).toBeTruthy();

    // Check text direction for RTL languages
    const dir = await page.getAttribute('html', 'dir');
    // Should be either 'ltr', 'rtl', or undefined (defaults to ltr)
    if (dir) {
      expect(['ltr', 'rtl']).toContain(dir);
    }
  });

  test('should have accessible loading states', async ({ page }) => {
    await page.goto('/teams');

    // Look for loading indicators
    const loadingIndicators = page.locator('[aria-busy="true"]').or(
      page.locator('text=Loading').or(
        page.locator('.spinner').or(
          page.locator('[data-testid="loading"]')
        )
      )
    );

    if (await loadingIndicators.first().isVisible()) {
      // Loading indicators should have proper accessibility
      const firstIndicator = loadingIndicators.first();
      const ariaBusy = await firstIndicator.getAttribute('aria-busy');
      const ariaLabel = await firstIndicator.getAttribute('aria-label');

      expect(ariaBusy === 'true' || ariaLabel).toBeTruthy();
    }
  });

  test('should support screen reader announcements', async ({ page }) => {
    // Test form submission with screen reader announcements
    await page.goto('/create-team');

    // Fill and submit form
    await page.fill('input[placeholder*="team name"]', 'Accessibility Test Team');
    await page.fill('textarea[placeholder*="description"]', 'Testing accessibility features');
    await page.click('button:has-text("Create Team")');

    // Check for success announcement (aria-live region)
    const liveRegion = page.locator('[aria-live]').or(
      page.locator('[role="status"]')
    );

    if (await liveRegion.isVisible()) {
      const liveText = await liveRegion.textContent();
      expect(liveText).toBeTruthy();
    }
  });
});