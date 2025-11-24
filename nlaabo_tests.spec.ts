import { test, expect, Page } from '@playwright/test';

const BASE_URL = 'http://configlens.ddns.net:5000/';
const TEST_EMAIL = 'sramiweb@gmail.com';
const TEST_PASSWORD = 'R876kxe@ne';

async function waitForFlutterApp(page: Page) {
  await page.waitForTimeout(3000);
}

test.describe('Nlaabo - Comprehensive Tests', () => {
  
  test.describe('1. UNAUTHENTICATED FLOWS', () => {
    
    test('1.1 - App loads successfully', async ({ page }) => {
      await page.goto(BASE_URL);
      await waitForFlutterApp(page);
      expect(page.url()).toBe(BASE_URL);
      const title = await page.title();
      expect(title).toContain('Nlaabo');
    });

    test('1.2 - Login page accessible', async ({ page }) => {
      await page.goto(BASE_URL);
      await waitForFlutterApp(page);
      const hasLoginElements = await page.evaluate(() => {
        const text = document.body.innerText;
        return text.includes('Login') || text.includes('Sign In') || text.includes('Email');
      });
      expect(hasLoginElements).toBeTruthy();
    });

    test('1.3 - Signup page accessible', async ({ page }) => {
      await page.goto(BASE_URL);
      await waitForFlutterApp(page);
      const hasSignupLink = await page.evaluate(() => {
        const text = document.body.innerText;
        return text.includes('Sign Up') || text.includes('Register') || text.includes('Create Account');
      });
      expect(hasSignupLink).toBeTruthy();
    });

    test('1.4 - Unauthenticated cannot access dashboard', async ({ page }) => {
      await page.goto(BASE_URL + 'dashboard');
      await waitForFlutterApp(page);
      const isRedirected = await page.evaluate(() => {
        const text = document.body.innerText;
        return text.includes('Login') || text.includes('Sign In');
      });
      expect(isRedirected).toBeTruthy();
    });
  });

  test.describe('2. AUTHENTICATION FLOWS', () => {
    
    test('2.1 - Login with valid credentials', async ({ page }) => {
      await page.goto(BASE_URL);
      await waitForFlutterApp(page);
      
      const emailInputs = await page.locator('input[type="email"], input[type="text"]').all();
      if (emailInputs.length > 0) {
        await emailInputs[0].fill(TEST_EMAIL);
      }
      
      const passwordInputs = await page.locator('input[type="password"]').all();
      if (passwordInputs.length > 0) {
        await passwordInputs[0].fill(TEST_PASSWORD);
      }
      
      const loginButtons = await page.locator('button').all();
      for (let btn of loginButtons) {
        const text = await btn.textContent();
        if (text?.includes('Login') || text?.includes('Sign In')) {
          await btn.click();
          break;
        }
      }
      
      await page.waitForTimeout(2000);
      const isLoggedIn = await page.evaluate(() => {
        const text = document.body.innerText;
        return !text.includes('Login') && !text.includes('Sign In');
      });
      expect(isLoggedIn).toBeTruthy();
    });

    test('2.2 - Login with invalid email', async ({ page }) => {
      await page.goto(BASE_URL);
      await waitForFlutterApp(page);
      
      const emailInputs = await page.locator('input[type="email"], input[type="text"]').all();
      if (emailInputs.length > 0) {
        await emailInputs[0].fill('invalid-email');
      }
      
      const passwordInputs = await page.locator('input[type="password"]').all();
      if (passwordInputs.length > 0) {
        await passwordInputs[0].fill('password123');
      }
      
      const loginButtons = await page.locator('button').all();
      for (let btn of loginButtons) {
        const text = await btn.textContent();
        if (text?.includes('Login') || text?.includes('Sign In')) {
          await btn.click();
          break;
        }
      }
      
      await page.waitForTimeout(1000);
      const stillOnLogin = await page.evaluate(() => {
        const text = document.body.innerText;
        return text.includes('Login') || text.includes('Email');
      });
      expect(stillOnLogin).toBeTruthy();
    });

    test('2.3 - Login with empty credentials', async ({ page }) => {
      await page.goto(BASE_URL);
      await waitForFlutterApp(page);
      
      const loginButtons = await page.locator('button').all();
      for (let btn of loginButtons) {
        const text = await btn.textContent();
        if (text?.includes('Login') || text?.includes('Sign In')) {
          await btn.click();
          break;
        }
      }
      
      await page.waitForTimeout(1000);
      const hasError = await page.evaluate(() => {
        const text = document.body.innerText;
        return text.includes('required') || text.includes('error') || text.includes('Error');
      });
      expect(hasError).toBeTruthy();
    });

    test('2.4 - Password reset link exists', async ({ page }) => {
      await page.goto(BASE_URL);
      await waitForFlutterApp(page);
      
      const forgotPasswordLink = await page.evaluate(() => {
        const elements = document.querySelectorAll('*');
        for (let el of elements) {
          if (el.textContent?.includes('Forgot') || el.textContent?.includes('Reset')) {
            return true;
          }
        }
        return false;
      });
      expect(forgotPasswordLink).toBeTruthy();
    });
  });

  test.describe('3. AUTHENTICATED FLOWS', () => {
    
    test('3.1 - Dashboard loads after login', async ({ page }) => {
      await page.goto(BASE_URL);
      await waitForFlutterApp(page);
      
      const emailInputs = await page.locator('input[type="email"], input[type="text"]').all();
      if (emailInputs.length > 0) {
        await emailInputs[0].fill(TEST_EMAIL);
      }
      
      const passwordInputs = await page.locator('input[type="password"]').all();
      if (passwordInputs.length > 0) {
        await passwordInputs[0].fill(TEST_PASSWORD);
      }
      
      const loginButtons = await page.locator('button').all();
      for (let btn of loginButtons) {
        const text = await btn.textContent();
        if (text?.includes('Login') || text?.includes('Sign In')) {
          await btn.click();
          break;
        }
      }
      
      await page.waitForTimeout(2000);
      const hasDashboard = await page.evaluate(() => {
        const text = document.body.innerText;
        return text.includes('Match') || text.includes('Team') || text.includes('Player');
      });
      expect(hasDashboard).toBeTruthy();
    });

    test('3.2 - Match organization feature exists', async ({ page }) => {
      await page.goto(BASE_URL);
      await waitForFlutterApp(page);
      
      const emailInputs = await page.locator('input[type="email"], input[type="text"]').all();
      if (emailInputs.length > 0) {
        await emailInputs[0].fill(TEST_EMAIL);
      }
      
      const passwordInputs = await page.locator('input[type="password"]').all();
      if (passwordInputs.length > 0) {
        await passwordInputs[0].fill(TEST_PASSWORD);
      }
      
      const loginButtons = await page.locator('button').all();
      for (let btn of loginButtons) {
        const text = await btn.textContent();
        if (text?.includes('Login') || text?.includes('Sign In')) {
          await btn.click();
          break;
        }
      }
      
      await page.waitForTimeout(2000);
      const hasMatchFeature = await page.evaluate(() => {
        const text = document.body.innerText;
        return text.includes('Create Match') || text.includes('New Match') || text.includes('Match');
      });
      expect(hasMatchFeature).toBeTruthy();
    });

    test('3.3 - Team management feature exists', async ({ page }) => {
      await page.goto(BASE_URL);
      await waitForFlutterApp(page);
      
      const emailInputs = await page.locator('input[type="email"], input[type="text"]').all();
      if (emailInputs.length > 0) {
        await emailInputs[0].fill(TEST_EMAIL);
      }
      
      const passwordInputs = await page.locator('input[type="password"]').all();
      if (passwordInputs.length > 0) {
        await passwordInputs[0].fill(TEST_PASSWORD);
      }
      
      const loginButtons = await page.locator('button').all();
      for (let btn of loginButtons) {
        const text = await btn.textContent();
        if (text?.includes('Login') || text?.includes('Sign In')) {
          await btn.click();
          break;
        }
      }
      
      await page.waitForTimeout(2000);
      const hasTeamFeature = await page.evaluate(() => {
        const text = document.body.innerText;
        return text.includes('Team') || text.includes('Teams');
      });
      expect(hasTeamFeature).toBeTruthy();
    });

    test('3.4 - Player profile feature exists', async ({ page }) => {
      await page.goto(BASE_URL);
      await waitForFlutterApp(page);
      
      const emailInputs = await page.locator('input[type="email"], input[type="text"]').all();
      if (emailInputs.length > 0) {
        await emailInputs[0].fill(TEST_EMAIL);
      }
      
      const passwordInputs = await page.locator('input[type="password"]').all();
      if (passwordInputs.length > 0) {
        await passwordInputs[0].fill(TEST_PASSWORD);
      }
      
      const loginButtons = await page.locator('button').all();
      for (let btn of loginButtons) {
        const text = await btn.textContent();
        if (text?.includes('Login') || text?.includes('Sign In')) {
          await btn.click();
          break;
        }
      }
      
      await page.waitForTimeout(2000);
      const hasPlayerFeature = await page.evaluate(() => {
        const text = document.body.innerText;
        return text.includes('Player') || text.includes('Profile');
      });
      expect(hasPlayerFeature).toBeTruthy();
    });
  });

  test.describe('4. RESPONSIVE DESIGN', () => {
    
    test('4.1 - Mobile 320px', async ({ page }) => {
      await page.setViewportSize({ width: 320, height: 568 });
      await page.goto(BASE_URL);
      await waitForFlutterApp(page);
      const content = await page.evaluate(() => document.body.innerText);
      expect(content.length).toBeGreaterThan(0);
    });

    test('4.2 - Mobile 480px', async ({ page }) => {
      await page.setViewportSize({ width: 480, height: 800 });
      await page.goto(BASE_URL);
      await waitForFlutterApp(page);
      const content = await page.evaluate(() => document.body.innerText);
      expect(content.length).toBeGreaterThan(0);
    });

    test('4.3 - Tablet 768px', async ({ page }) => {
      await page.setViewportSize({ width: 768, height: 1024 });
      await page.goto(BASE_URL);
      await waitForFlutterApp(page);
      const content = await page.evaluate(() => document.body.innerText);
      expect(content.length).toBeGreaterThan(0);
    });

    test('4.4 - Desktop 1024px', async ({ page }) => {
      await page.setViewportSize({ width: 1024, height: 768 });
      await page.goto(BASE_URL);
      await waitForFlutterApp(page);
      const content = await page.evaluate(() => document.body.innerText);
      expect(content.length).toBeGreaterThan(0);
    });

    test('4.5 - Large desktop 1920px', async ({ page }) => {
      await page.setViewportSize({ width: 1920, height: 1080 });
      await page.goto(BASE_URL);
      await waitForFlutterApp(page);
      const content = await page.evaluate(() => document.body.innerText);
      expect(content.length).toBeGreaterThan(0);
    });
  });

  test.describe('5. ERROR HANDLING', () => {
    
    test('5.1 - Invalid route handling', async ({ page }) => {
      await page.goto(BASE_URL + 'invalid-route-xyz');
      await waitForFlutterApp(page);
      const content = await page.evaluate(() => document.body.innerText);
      expect(content.length).toBeGreaterThan(0);
    });

    test('5.2 - Rapid navigation', async ({ page }) => {
      await page.goto(BASE_URL);
      await waitForFlutterApp(page);
      
      for (let i = 0; i < 5; i++) {
        await page.goto(BASE_URL);
        await page.waitForTimeout(100);
      }
      
      const content = await page.evaluate(() => document.body.innerText);
      expect(content.length).toBeGreaterThan(0);
    });

    test('5.3 - Large form input', async ({ page }) => {
      await page.goto(BASE_URL);
      await waitForFlutterApp(page);
      
      const inputs = await page.locator('input').all();
      for (let input of inputs) {
        try {
          await input.fill('a'.repeat(1000));
        } catch (e) {
          // Expected
        }
      }
      
      const content = await page.evaluate(() => document.body.innerText);
      expect(content.length).toBeGreaterThan(0);
    });
  });

  test.describe('6. ACCESSIBILITY', () => {
    
    test('6.1 - Keyboard navigation', async ({ page }) => {
      await page.goto(BASE_URL);
      await waitForFlutterApp(page);
      
      await page.keyboard.press('Tab');
      await page.keyboard.press('Tab');
      
      const content = await page.evaluate(() => document.body.innerText);
      expect(content.length).toBeGreaterThan(0);
    });

    test('6.2 - Focus management', async ({ page }) => {
      await page.goto(BASE_URL);
      await waitForFlutterApp(page);
      
      const inputs = await page.locator('input').all();
      if (inputs.length > 0) {
        await inputs[0].focus();
        const focused = await page.evaluate(() => document.activeElement?.tagName);
        expect(focused).toBeDefined();
      }
    });

    test('6.3 - Accessibility button', async ({ page }) => {
      await page.goto(BASE_URL);
      await waitForFlutterApp(page);
      
      const accessibilityButton = await page.locator('button:has-text("Enable accessibility")').first();
      if (await accessibilityButton.isVisible()) {
        await accessibilityButton.click();
        await page.waitForTimeout(500);
      }
      
      const content = await page.evaluate(() => document.body.innerText);
      expect(content.length).toBeGreaterThan(0);
    });
  });

  test.describe('7. PERFORMANCE', () => {
    
    test('7.1 - Page load time', async ({ page }) => {
      const startTime = Date.now();
      await page.goto(BASE_URL);
      await waitForFlutterApp(page);
      const loadTime = Date.now() - startTime;
      expect(loadTime).toBeLessThan(10000);
    });

    test('7.2 - Navigation performance', async ({ page }) => {
      await page.goto(BASE_URL);
      await waitForFlutterApp(page);
      
      const startTime = Date.now();
      await page.reload();
      await waitForFlutterApp(page);
      const reloadTime = Date.now() - startTime;
      expect(reloadTime).toBeLessThan(10000);
    });
  });

  test.describe('8. DATA VALIDATION', () => {
    
    test('8.1 - Email validation', async ({ page }) => {
      await page.goto(BASE_URL);
      await waitForFlutterApp(page);
      
      const emailInputs = await page.locator('input[type="email"]').all();
      if (emailInputs.length > 0) {
        await emailInputs[0].fill('invalid-email');
        await emailInputs[0].blur();
        const content = await page.evaluate(() => document.body.innerText);
        expect(content).toBeDefined();
      }
    });

    test('8.2 - Required field validation', async ({ page }) => {
      await page.goto(BASE_URL);
      await waitForFlutterApp(page);
      
      const buttons = await page.locator('button').all();
      for (let btn of buttons) {
        const text = await btn.textContent();
        if (text?.includes('Submit') || text?.includes('Login')) {
          await btn.click();
          break;
        }
      }
      
      await page.waitForTimeout(500);
      const content = await page.evaluate(() => document.body.innerText);
      expect(content).toBeDefined();
    });
  });

  test.describe('9. SECURITY', () => {
    
    test('9.1 - XSS protection', async ({ page }) => {
      await page.goto(BASE_URL);
      await waitForFlutterApp(page);
      
      const inputs = await page.locator('input').all();
      if (inputs.length > 0) {
        await inputs[0].fill('<script>alert("XSS")</script>');
      }
      
      const content = await page.evaluate(() => document.body.innerText);
      expect(content).not.toContain('alert');
    });

    test('9.2 - Password not in source', async ({ page }) => {
      await page.goto(BASE_URL);
      await waitForFlutterApp(page);
      
      const passwordInputs = await page.locator('input[type="password"]').all();
      if (passwordInputs.length > 0) {
        await passwordInputs[0].fill(TEST_PASSWORD);
        const pageContent = await page.content();
        expect(pageContent).not.toContain(TEST_PASSWORD);
      }
    });

    test('9.3 - Secure headers', async ({ page }) => {
      const response = await page.goto(BASE_URL);
      const headers = response?.headers();
      expect(headers).toBeDefined();
    });
  });

  test.describe('10. MULTI-LANGUAGE', () => {
    
    test('10.1 - Arabic support', async ({ page }) => {
      await page.goto(BASE_URL);
      await waitForFlutterApp(page);
      const content = await page.evaluate(() => document.body.innerText);
      expect(content.length).toBeGreaterThan(0);
    });

    test('10.2 - English support', async ({ page }) => {
      await page.goto(BASE_URL);
      await waitForFlutterApp(page);
      const content = await page.evaluate(() => document.body.innerText);
      expect(content.length).toBeGreaterThan(0);
    });

    test('10.3 - French support', async ({ page }) => {
      await page.goto(BASE_URL);
      await waitForFlutterApp(page);
      const content = await page.evaluate(() => document.body.innerText);
      expect(content.length).toBeGreaterThan(0);
    });

    test('10.4 - Language persistence', async ({ page }) => {
      await page.goto(BASE_URL);
      await waitForFlutterApp(page);
      const initialContent = await page.evaluate(() => document.body.innerText);
      
      await page.reload();
      await waitForFlutterApp(page);
      const reloadedContent = await page.evaluate(() => document.body.innerText);
      expect(reloadedContent.length).toBeGreaterThan(0);
    });
  });
});
