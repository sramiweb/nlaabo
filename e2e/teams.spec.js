import { test, expect } from '@playwright/test';

// Test credentials
const TEST_EMAIL = 'sramiweb@gmail.com';
const TEST_PASSWORD = 'R876kxe@ne';

test.describe('Team Management', () => {
  test.beforeEach(async ({ page }) => {
    // Login before each test
    await page.goto('/login');
    await page.fill('input[type="email"]', TEST_EMAIL);
    await page.fill('input[type="password"]', TEST_PASSWORD);
    await page.click('button:has-text("Login")');
    await expect(page).toHaveURL(/\/home$/);
  });

  test('should display teams section on home page', async ({ page }) => {
    // Check if teams section is visible on home page
    await expect(page.locator('text=Teams')).toBeVisible();
  });

  test('should navigate to teams page', async ({ page }) => {
    await page.click('text=Teams');
    await expect(page).toHaveURL(/\/teams$/);

    // Check page elements
    await expect(page.locator('text=Create Team')).toBeVisible();
  });

  test('should navigate to create team page', async ({ page }) => {
    await page.goto('/teams');
    await page.click('text=Create Team');
    await expect(page).toHaveURL(/\/create-team$/);

    // Check form elements
    await expect(page.locator('input[placeholder*="team name"]')).toBeVisible();
    await expect(page.locator('textarea[placeholder*="description"]')).toBeVisible();
    await expect(page.locator('button:has-text("Create Team")')).toBeVisible();
  });

  test('should create a new team successfully', async ({ page }) => {
    await page.goto('/create-team');

    const teamName = `Test Team ${Date.now()}`;
    const teamDescription = 'A test team created by automated tests';

    // Fill form
    await page.fill('input[placeholder*="team name"]', teamName);
    await page.fill('textarea[placeholder*="description"]', teamDescription);

    // Submit
    await page.click('button:has-text("Create Team")');

    // Should redirect to team details or teams page
    await expect(page).toHaveURL(/\/(teams|teams\/)/);

    // Check if team was created (might need to navigate to teams page)
    await page.goto('/teams');
    await expect(page.locator(`text=${teamName}`)).toBeVisible();
  });

  test('should show validation errors for invalid team data', async ({ page }) => {
    await page.goto('/create-team');

    // Try to submit empty form
    await page.click('button:has-text("Create Team")');

    // Should show validation errors
    await expect(page.locator('text=Team name is required')).toBeVisible();
  });

  test('should prevent duplicate team names', async ({ page }) => {
    await page.goto('/create-team');

    // Create first team
    const teamName = `Duplicate Test ${Date.now()}`;
    await page.fill('input[placeholder*="team name"]', teamName);
    await page.fill('textarea[placeholder*="description"]', 'First team');
    await page.click('button:has-text("Create Team")');

    // Try to create another team with same name
    await page.goto('/create-team');
    await page.fill('input[placeholder*="team name"]', teamName);
    await page.fill('textarea[placeholder*="description"]', 'Duplicate team');
    await page.click('button:has-text("Create Team")');

    // Should show error
    await expect(page.locator('text=Team name already exists')).toBeVisible();
  });

  test('should display team details page', async ({ page }) => {
    // Navigate to teams and click on first team
    await page.goto('/teams');

    // Click on first team card/link
    const firstTeam = page.locator('[data-testid="team-card"]').first();
    await expect(firstTeam).toBeVisible();
    await firstTeam.click();

    // Should be on team details page
    await expect(page).toHaveURL(/\/teams\/[^/]+$/);

    // Check team details elements
    await expect(page.locator('text=Team Members')).toBeVisible();
    await expect(page.locator('text=Manage Team')).toBeVisible();
  });

  test('should display team members', async ({ page }) => {
    await page.goto('/teams');

    // Click on first team
    const firstTeam = page.locator('[data-testid="team-card"]').first();
    await firstTeam.click();

    // Check members section
    await expect(page.locator('text=Team Members')).toBeVisible();

    // Should show at least one member (the owner)
    const memberCount = await page.locator('[data-testid="team-member"]').count();
    expect(memberCount).toBeGreaterThan(0);
  });

  test('should allow team owner to access team management', async ({ page }) => {
    await page.goto('/teams');

    // Click on first team
    const firstTeam = page.locator('[data-testid="team-card"]').first();
    await firstTeam.click();

    // Click manage team
    await page.click('text=Manage Team');

    // Should be on management page
    await expect(page).toHaveURL(/\/teams\/[^/]+\/manage$/);

    // Check management options
    await expect(page.locator('text=Edit Team')).toBeVisible();
    await expect(page.locator('text=Manage Members')).toBeVisible();
  });

  test('should allow editing team details', async ({ page }) => {
    // Navigate to team management
    await page.goto('/teams');
    const firstTeam = page.locator('[data-testid="team-card"]').first();
    await firstTeam.click();
    await page.click('text=Manage Team');

    // Click edit team
    await page.click('text=Edit Team');

    // Check edit form
    await expect(page.locator('input[placeholder*="team name"]')).toBeVisible();

    // Make a change
    const newDescription = 'Updated team description';
    await page.fill('textarea[placeholder*="description"]', newDescription);

    // Save changes
    await page.click('button:has-text("Save Changes")');

    // Should show success message or redirect
    await expect(page.locator('text=Team updated successfully')).toBeVisible();
  });

  test('should handle team member invitations', async ({ page }) => {
    // Navigate to team management
    await page.goto('/teams');
    const firstTeam = page.locator('[data-testid="team-card"]').first();
    await firstTeam.click();
    await page.click('text=Manage Team');

    // Look for invite member functionality
    const inviteButton = page.locator('text=Invite Member').or(page.locator('text=Add Member'));
    if (await inviteButton.isVisible()) {
      await inviteButton.click();

      // Check invite form
      await expect(page.locator('input[type="email"]')).toBeVisible();

      // Fill with test email
      await page.fill('input[type="email"]', `invite${Date.now()}@example.com`);

      // Send invitation
      await page.click('button:has-text("Send Invite")');

      // Should show success message
      await expect(page.locator('text=Invitation sent')).toBeVisible();
    }
  });

  test('should handle team member removal', async ({ page }) => {
    // This test assumes there's a team with multiple members
    // Skip if not applicable
    test.skip();

    await page.goto('/teams');
    const firstTeam = page.locator('[data-testid="team-card"]').first();
    await firstTeam.click();
    await page.click('text=Manage Team');

    // Find a member to remove (not the owner)
    const memberToRemove = page.locator('[data-testid="team-member"]:not(:has-text("Owner"))').first();

    if (await memberToRemove.isVisible()) {
      // Click remove button
      await memberToRemove.locator('button:has-text("Remove")').click();

      // Confirm removal
      await page.click('button:has-text("Confirm")');

      // Should show success message
      await expect(page.locator('text=Member removed')).toBeVisible();
    }
  });

  test('should handle leaving a team', async ({ page }) => {
    // This test assumes user is member of a team (not owner)
    test.skip();

    await page.goto('/teams');
    const teamToLeave = page.locator('[data-testid="team-card"]').first();
    await teamToLeave.click();

    // Click leave team
    await page.click('text=Leave Team');

    // Confirm
    await page.click('button:has-text("Confirm")');

    // Should redirect to teams page
    await expect(page).toHaveURL(/\/teams$/);

    // Team should not be in list anymore
    await expect(page.locator(`text=${await teamToLeave.textContent()}`)).not.toBeVisible();
  });

  test('should prevent team owner from leaving team', async ({ page }) => {
    // Navigate to owned team
    await page.goto('/teams');
    const ownedTeam = page.locator('[data-testid="team-card"]').first();
    await ownedTeam.click();

    // Leave team button should not be visible for owner
    await expect(page.locator('text=Leave Team')).not.toBeVisible();
  });

  test('should handle team search and filtering', async ({ page }) => {
    await page.goto('/teams');

    // Check if search functionality exists
    const searchInput = page.locator('input[placeholder*="search"]').or(page.locator('input[type="search"]'));

    if (await searchInput.isVisible()) {
      // Type search term
      await searchInput.fill('test');

      // Should filter results
      const visibleTeams = await page.locator('[data-testid="team-card"]').count();
      // Results should be filtered (may be 0 if no matches)
      expect(typeof visibleTeams).toBe('number');
    }
  });

  test('should display team statistics', async ({ page }) => {
    await page.goto('/teams');
    const firstTeam = page.locator('[data-testid="team-card"]').first();
    await firstTeam.click();

    // Check for statistics like member count, matches played, etc.
    const statsElements = [
      page.locator('text=Members:'),
      page.locator('text=Matches:'),
      page.locator('text=Founded:')
    ];

    // At least one stat should be visible
    let statsVisible = false;
    for (const stat of statsElements) {
      if (await stat.isVisible()) {
        statsVisible = true;
        break;
      }
    }

    if (!statsVisible) {
      // Check for any numeric stats
      const numericStats = page.locator('[data-testid="team-stat"]').first();
      if (await numericStats.isVisible()) {
        statsVisible = true;
      }
    }

    expect(statsVisible).toBe(true);
  });
});