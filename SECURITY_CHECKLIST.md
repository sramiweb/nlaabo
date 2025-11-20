# Security Checklist

## Environment Variables
- [ ] All API keys are in `.env` file (not hardcoded)
- [ ] `.env` is in `.gitignore`
- [ ] No sensitive URLs logged in production

## Dependencies
- [ ] Run `flutter pub outdated` monthly
- [ ] Update dependencies with security patches
- [ ] Review dependency vulnerabilities

## Code Security
- [ ] No credentials in source code
- [ ] Sensitive data uses `flutter_secure_storage`
- [ ] API responses sanitized before display
- [ ] Input validation on all user inputs

## Git Security
- [ ] Audit `.gitignore` regularly
- [ ] Run `git status` before commits
- [ ] No `.env` files committed
- [ ] No API keys in commit history

## Testing
- [ ] Security tests for authentication
- [ ] Input validation tests
- [ ] Error handling tests
- [ ] Network failure scenarios tested

## Monitoring
- [ ] Error logs sanitized (no PII)
- [ ] Debug logs disabled in production
- [ ] Crash reports anonymized
