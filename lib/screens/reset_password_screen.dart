import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../services/error_handler.dart';
import '../services/feedback_service.dart';
import '../widgets/enhanced_error_boundary.dart';
import '../widgets/directional_icon.dart';
import '../widgets/loading_overlay.dart';
import '../utils/validators.dart';
import '../utils/responsive_utils.dart';
import '../constants/translation_keys.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = ApiService();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await _apiService.resetPassword(_passwordController.text);
      if (!mounted) return;

      context.showSuccess(LocalizationService().translate(TranslationKeys.passwordResetSuccess));
      context.go('/login');
    } catch (error, st) {
      if (!mounted) return;
      ErrorHandler.logError(error, st, 'ResetPasswordScreen._resetPassword');
      context.showError(error, onRetry: () => _resetPassword());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenErrorBoundary(
      screenName: 'ResetPasswordScreen',
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const DirectionalIcon(icon: Icons.arrow_back),
            onPressed: () => context.go('/login'),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: context.responsivePadding,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withAlpha(26),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.lock_reset,
                                size: 50,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            SizedBox(height: context.itemSpacing * 2),
                            Text(
                              LocalizationService().translate(TranslationKeys.resetPasswordTitle),
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: context.itemSpacing * 3),

                      // New Password Field
                      Text(
                        LocalizationService().translate(TranslationKeys.newPassword),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: context.itemSpacing * 0.5),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          hintText: LocalizationService().translate(TranslationKeys.enterPassword),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                            padding: const EdgeInsets.all(12),
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            tooltip: 'Toggle password visibility',
                          ),
                        ),
                        obscureText: _obscurePassword,
                        validator: (value) => validatePassword(value),
                      ),

                      SizedBox(height: context.itemSpacing * 2),

                      // Confirm Password Field
                      Text(
                        LocalizationService().translate(TranslationKeys.confirmNewPassword),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: context.itemSpacing * 0.5),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          hintText: LocalizationService().translate(TranslationKeys.confirmPassword),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            onPressed: () {
                              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                            },
                            padding: const EdgeInsets.all(12),
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            tooltip: 'Toggle password visibility',
                          ),
                        ),
                        obscureText: _obscureConfirmPassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return LocalizationService().translate(TranslationKeys.confirmPasswordRequired);
                          }
                          if (value != _passwordController.text) {
                            return LocalizationService().translate(TranslationKeys.passwordsNotMatch);
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: context.itemSpacing * 3),

                      // Reset Password Button
                      LoadingButton(
                        isLoading: _isSubmitting,
                        onPressed: _resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          elevation: 4,
                          shadowColor: Theme.of(context).colorScheme.primary.withAlpha((0.3 * 255).round()),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        height: context.buttonHeight,
                        child: Text(
                          LocalizationService().translate(TranslationKeys.resetPassword),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      SizedBox(height: context.itemSpacing * 2),

                      // Back to Login
                      Center(
                        child: TextButton(
                          onPressed: () => context.go('/login'),
                          child: Text(
                            LocalizationService().translate(TranslationKeys.backToLogin),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
