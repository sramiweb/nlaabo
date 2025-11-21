# Vercel Deployment Guide for Nlaabo

This guide will help you deploy the Nlaabo Flutter web app to Vercel with best practices and optimizations.

## 🚀 Quick Deployment

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.9+)
- [Vercel CLI](https://vercel.com/cli) (`npm i -g vercel`)
- Git repository connected to Vercel

### One-Click Deployment
```bash
# Build and deploy in one command
./deploy-vercel.bat
```

## 📋 Manual Deployment Steps

### 1. Prepare the Build
```bash
# Clean and build for web
flutter clean
flutter pub get
flutter build web --release --web-renderer canvaskit
```

### 2. Configure Vercel
```bash
# Login to Vercel (first time only)
vercel login

# Link project (first time only)
vercel link

# Deploy
vercel --prod
```

### 3. Set Environment Variables
In your Vercel dashboard, add these environment variables:

**Required:**
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_ANON_KEY`: Your Supabase anonymous key

**Optional:**
- `FLUTTER_WEB`: `true`
- `WEB_RENDERER`: `canvaskit`

## ⚙️ Configuration Files

### vercel.json
```json
{
  "buildCommand": "flutter build web --release --web-renderer canvaskit",
  "outputDirectory": "build/web",
  "installCommand": "flutter pub get"
}
```

### Key Features:
- **Security Headers**: XSS protection, content type options
- **Caching Strategy**: Optimized for static assets and dynamic content
- **SPA Routing**: All routes redirect to index.html
- **Performance**: CanvasKit renderer for better performance

## 🔧 Optimizations Applied

### Performance
- ✅ CanvasKit renderer for better graphics performance
- ✅ Tree-shaking for smaller bundle size
- ✅ Asset caching with long-term cache headers
- ✅ Service worker for offline functionality
- ✅ Preloading of critical resources

### Security
- ✅ Content Security Policy headers
- ✅ XSS protection
- ✅ Frame options to prevent clickjacking
- ✅ Referrer policy for privacy

### SEO & PWA
- ✅ Meta tags for social sharing
- ✅ Progressive Web App manifest
- ✅ Service worker for offline support
- ✅ App icons and splash screens

## 🌐 Domain Configuration

### Custom Domain
1. Go to your Vercel project dashboard
2. Navigate to Settings → Domains
3. Add your custom domain
4. Update DNS records as instructed

### SSL Certificate
Vercel automatically provides SSL certificates for all domains.

## 📱 PWA Features

The app is configured as a Progressive Web App with:
- **Offline Support**: Service worker caches essential resources
- **Install Prompt**: Users can install the app on their devices
- **App Shortcuts**: Quick actions from home screen
- **Push Notifications**: Ready for future implementation

## 🔍 Testing Your Deployment

### Automated Checks
```bash
# Test build locally
cd build/web
python -m http.server 8000
# Visit http://localhost:8000
```

### Manual Testing Checklist
- [ ] App loads without errors
- [ ] Authentication works (login/signup)
- [ ] Supabase connection is successful
- [ ] Responsive design on mobile/tablet
- [ ] PWA installation works
- [ ] Offline functionality (basic caching)
- [ ] All routes work correctly
- [ ] Images and assets load properly

## 🐛 Troubleshooting

### Common Issues

**Build Fails:**
```bash
# Clear Flutter cache
flutter clean
flutter pub get
flutter pub deps
```

**Environment Variables Not Working:**
- Ensure variables are set in Vercel dashboard
- Check variable names match exactly
- Redeploy after adding variables

**Supabase Connection Issues:**
- Verify SUPABASE_URL and SUPABASE_ANON_KEY
- Check Supabase project is active
- Ensure RLS policies allow web access

**Routing Issues:**
- Verify vercel.json rewrites configuration
- Check that all routes are defined in main.dart
- Test direct URL access

### Debug Mode
For debugging, you can deploy with debug info:
```bash
flutter build web --profile --source-maps
vercel --prod
```

## 📊 Performance Monitoring

### Vercel Analytics
Enable Vercel Analytics in your project settings for:
- Page load times
- Core Web Vitals
- User engagement metrics

### Lighthouse Scores
Expected scores with current optimizations:
- **Performance**: 90+
- **Accessibility**: 95+
- **Best Practices**: 95+
- **SEO**: 90+

## 🔄 Continuous Deployment

### GitHub Integration
1. Connect your GitHub repository to Vercel
2. Enable automatic deployments
3. Set up branch protection rules
4. Configure preview deployments for PRs

### Deployment Hooks
```bash
# Add to package.json for automated builds
{
  "scripts": {
    "build": "flutter build web --release --web-renderer canvaskit",
    "deploy": "vercel --prod"
  }
}
```

## 📈 Scaling Considerations

### Performance
- Monitor Core Web Vitals
- Optimize images and assets
- Use CDN for static resources
- Implement lazy loading

### Security
- Regular dependency updates
- Monitor for vulnerabilities
- Implement rate limiting
- Use environment variables for secrets

### Monitoring
- Set up error tracking (Sentry)
- Monitor API usage
- Track user analytics
- Set up uptime monitoring

## 🆘 Support

If you encounter issues:
1. Check the [Vercel documentation](https://vercel.com/docs)
2. Review Flutter web [deployment guide](https://flutter.dev/docs/deployment/web)
3. Check Supabase [connection docs](https://supabase.com/docs)
4. Open an issue in the project repository

## 📚 Additional Resources

- [Flutter Web Performance](https://flutter.dev/docs/perf/web-performance)
- [Vercel Edge Functions](https://vercel.com/docs/concepts/functions/edge-functions)
- [PWA Best Practices](https://web.dev/pwa-checklist/)
- [Web Security Headers](https://securityheaders.com/)

---

**Last Updated**: January 2025
**Flutter Version**: 3.9+
**Vercel CLI Version**: Latest