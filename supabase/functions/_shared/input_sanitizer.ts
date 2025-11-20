// Input Sanitization and Validation Utilities

export interface SanitizationResult {
  isValid: boolean;
  sanitized?: string;
  error?: string;
}

/**
 * Sanitize string for logging to prevent log injection
 */
export function sanitizeForLog(input: string, maxLength: number = 100): string {
  if (!input) return '';
  return input
    .replace(/[\n\r\t]/g, ' ')
    .replace(/[^\x20-\x7E]/g, '')
    .substring(0, maxLength);
}

/**
 * Validate and sanitize email
 */
export function sanitizeEmail(email: string): SanitizationResult {
  if (!email || typeof email !== 'string') {
    return { isValid: false, error: 'Email is required' };
  }

  const trimmed = email.trim().toLowerCase();

  if (trimmed.length > 254) {
    return { isValid: false, error: 'Email too long' };
  }

  const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
  if (!emailRegex.test(trimmed)) {
    return { isValid: false, error: 'Invalid email format' };
  }

  return { isValid: true, sanitized: trimmed };
}

/**
 * Validate and sanitize phone number
 */
export function sanitizePhone(phone: string): SanitizationResult {
  if (!phone || typeof phone !== 'string') {
    return { isValid: false, error: 'Phone number is required' };
  }

  const cleaned = phone.replace(/\D/g, '');

  if (cleaned.length < 10 || cleaned.length > 15) {
    return { isValid: false, error: 'Invalid phone number length' };
  }

  return { isValid: true, sanitized: cleaned };
}

/**
 * Sanitize text input (names, titles, etc.)
 */
export function sanitizeText(
  text: string,
  minLength: number = 2,
  maxLength: number = 100
): SanitizationResult {
  if (!text || typeof text !== 'string') {
    return { isValid: false, error: 'Text is required' };
  }

  const trimmed = text.trim();

  if (trimmed.length < minLength) {
    return { isValid: false, error: `Text too short (min: ${minLength})` };
  }

  if (trimmed.length > maxLength) {
    return { isValid: false, error: `Text too long (max: ${maxLength})` };
  }

  // Remove potentially dangerous characters
  const sanitized = trimmed.replace(/[<>\"']/g, '');

  return { isValid: true, sanitized };
}

/**
 * Validate UUID format
 */
export function isValidUUID(uuid: string): boolean {
  if (!uuid || typeof uuid !== 'string') return false;
  
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  return uuidRegex.test(uuid);
}

/**
 * Sanitize search query
 */
export function sanitizeSearchQuery(query: string): SanitizationResult {
  if (!query || typeof query !== 'string') {
    return { isValid: false, error: 'Search query is required' };
  }

  const trimmed = query.trim();

  if (trimmed.length < 2) {
    return { isValid: false, error: 'Search query too short' };
  }

  if (trimmed.length > 100) {
    return { isValid: false, error: 'Search query too long' };
  }

  // Remove SQL injection attempts and special characters
  const sanitized = trimmed
    .replace(/[;'"\\]/g, '')
    .replace(/--/g, '')
    .replace(/\/\*/g, '')
    .replace(/\*\//g, '');

  return { isValid: true, sanitized };
}

/**
 * Validate integer within range
 */
export function validateInteger(
  value: any,
  min: number,
  max: number
): SanitizationResult {
  const num = parseInt(value);

  if (isNaN(num)) {
    return { isValid: false, error: 'Invalid number' };
  }

  if (num < min || num > max) {
    return { isValid: false, error: `Number must be between ${min} and ${max}` };
  }

  return { isValid: true, sanitized: num.toString() };
}

/**
 * Validate date string
 */
export function validateDate(dateStr: string): SanitizationResult {
  if (!dateStr || typeof dateStr !== 'string') {
    return { isValid: false, error: 'Date is required' };
  }

  const date = new Date(dateStr);

  if (isNaN(date.getTime())) {
    return { isValid: false, error: 'Invalid date format' };
  }

  return { isValid: true, sanitized: date.toISOString() };
}
