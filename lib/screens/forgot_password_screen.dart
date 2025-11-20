import 'package:flutter/material.dart';
import '../widgets/directional_icon.dart';
import 'package:go_router/go_router.dart';

import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../services/error_handler.dart';
import '../services/feedback_service.dart';
import '../widgets/enhanced_error_boundary.dart';
import '../utils/validators.dart';
import '../utils/responsive_utils.dart';
import '../constants/translation_keys.dart';
import '../widgets/animations.dart';
import '../utils/design_system.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _apiService = ApiService();
  
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await _apiService.requestPasswordReset(_emailController.text.trim());
      if (!mounted) return;

      context.showSuccess(LocalizationService().translate(TranslationKeys.resetLinkSent));
      context.go('/forgot-password-confirmation', extra: _emailController.text.trim());
    } catch (error, st) {
      if (!mounted) return;
      ErrorHandler.logError(error, st, 'ForgotPasswordScreen._sendResetLink');
      context.showError(error, onRetry: () => _sendResetLink());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenErrorBoundary(
      screenName: 'ForgotPasswordScreen',
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
                              padding: const EdgeInsets.all(FootConnectSpacing.space5),
                              decoration: BoxDecoration(
                                color: FootConnectColors.primaryBlue.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock_reset,
                                size: 50,
                                color: FootConnectColors.primaryBlue,
                              ),
                            ).withFadeIn(delay: const Duration(milliseconds: 200)),
                            const SizedBox(height: FootConnectSpacing.space6),
                            Text(
                              LocalizationService().translate(TranslationKeys.forgotPasswordTitle),
                              style: FootConnectTypography.h2Style.copyWith(
                                fontWeight: FontWeight.bold,
                                color: FootConnectColors.textPrimary,
                              ),
                            ).withFadeIn(delay: const Duration(milliseconds: 400)),
                            const SizedBox(height: FootConnectSpacing.space2),
                            Text(
                              LocalizationService().translate(TranslationKeys.forgotPasswordSubtitle),
                              style: FootConnectTypography.bodyRegularStyle.copyWith(
                                color: FootConnectColors.textTertiary,
                              ),
                              textAlign: TextAlign.center,
                            ).withFadeIn(delay: const Duration(milliseconds: 600)),
                          ],
                        ),
                      ),

                      const SizedBox(height: FootConnectSpacing.space8),

                      // Email Field
                      Text(
                        LocalizationService().translate(TranslationKeys.email),
                        style: FootConnectTypography.bodyRegularStyle.copyWith(
                          fontWeight: FontWeight.w600,
                          color: FootConnectColors.textPrimary,
                        ),
                      ).withFadeIn(delay: const Duration(milliseconds: 800)),
                      const SizedBox(height: FootConnectSpacing.space2),
                      SizedBox(
                        height: FootConnectComponentSizing.textFieldHeight,
                        child: TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: LocalizationService().translate(TranslationKeys.enterEmail),
                            hintStyle: FootConnectTypography.bodyRegularStyle.copyWith(
                              color: FootConnectColors.textTertiary,
                            ),
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: FootConnectColors.neutralGray,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(FootConnectBorderRadius.input),
                              borderSide: BorderSide(
                                color: FootConnectColors.neutralGray.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(FootConnectBorderRadius.input),
                              borderSide: BorderSide(
                                color: FootConnectColors.neutralGray.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(FootConnectBorderRadius.input),
                              borderSide: const BorderSide(
                                color: FootConnectColors.primaryBlue,
                                width: 2.0,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: FootConnectSpacing.space4,
                              vertical: FootConnectSpacing.space3,
                            ),
                          ),
                          style: FootConnectTypography.bodyRegularStyle.copyWith(
                            color: FootConnectColors.textPrimary,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) => validateEmail(value),
                        ),
                      ).withFadeIn(delay: const Duration(milliseconds: 1000)),

                      const SizedBox(height: FootConnectSpacing.space8),

                      // Send Reset Link Button
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _sendResetLink,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FootConnectColors.primaryBlue,
                            foregroundColor: FootConnectColors.backgroundPrimary,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: FootConnectSpacing.space6,
                              vertical: FootConnectSpacing.space4,
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: FootConnectSpacing.space4,
                                  width: FootConnectSpacing.space4,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(FootConnectColors.backgroundPrimary),
                                  ),
                                )
                              : Text(
                                  LocalizationService().translate(TranslationKeys.sendResetLink),
                                  style: FootConnectTypography.bodyRegularStyle.copyWith(
                                    color: FootConnectColors.backgroundPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ).withFadeIn(delay: const Duration(milliseconds: 1200)),

                      const SizedBox(height: FootConnectSpacing.space6),

                      // Back to Login
                      Center(
                        child: TextButton(
                          onPressed: () => context.go('/login'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: FootConnectSpacing.space4,
                              vertical: FootConnectSpacing.space3,
                            ),
                          ),
                          child: Text(
                            LocalizationService().translate(TranslationKeys.backToLogin),
                            style: FootConnectTypography.bodyRegularStyle.copyWith(
                              color: FootConnectColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ).withFadeIn(delay: const Duration(milliseconds: 1400)),
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
