import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

import '../services/localization_service.dart';
import '../services/error_handler.dart';
import '../utils/validators.dart';
import '../utils/error_message_formatter.dart';
import '../constants/translation_keys.dart';
import '../design_system/components/buttons/primary_button.dart';
import '../design_system/components/forms/app_text_field.dart';
import '../design_system/components/cards/base_card.dart';
import '../design_system/colors/app_colors_extensions.dart';
import '../design_system/typography/app_text_styles.dart';
import '../design_system/spacing/app_spacing.dart';
import '../widgets/fade_in_animation.dart';
import '../utils/responsive_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;

      if (mounted)
        context.showSuccess(LocalizationService().translate('login_success'));
      if (mounted) context.go('/home');
    } catch (error, st) {
      if (!mounted) return;
      ErrorHandler.logError(error, st, 'LoginScreen._login');
      if (mounted) context.showError(error, onRetry: () => _login());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPaddingInsets,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: BaseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FadeInAnimation(
                      delay: const Duration(milliseconds: 200),
                      child: Column(
                        children: [
                          Icon(
                            Icons.sports_soccer,
                            size: ResponsiveUtils.getIconSize(context, 64),
                            color: context.colors.primary,
                          ),
                          AppSpacing.verticalLg,
                          Text(
                            LocalizationService()
                                .translate(TranslationKeys.loginTitle),
                            style:
                                AppTextStyles.getResponsivePageTitle(context),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          AppSpacing.verticalSm,
                          Text(
                            LocalizationService()
                                .translate(TranslationKeys.loginSubtitle),
                            style: AppTextStyles.getResponsiveBodyText(context)
                                .copyWith(
                              color: context.colors.textSubtle,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.verticalXxl,
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          FadeInAnimation(
                            delay: const Duration(milliseconds: 400),
                            child: AppTextField(
                              controller: _emailController,
                              labelText:
                                  LocalizationService().translate('email'),
                              hintText: LocalizationService()
                                  .translate(TranslationKeys.enterEmail),
                              prefixIcon: const Icon(Icons.email_outlined),
                              keyboardType: TextInputType.emailAddress,
                              validator: validateEmail,
                            ),
                          ),
                          AppSpacing.verticalLg,
                          FadeInAnimation(
                            delay: const Duration(milliseconds: 600),
                            child: AppTextField(
                              controller: _passwordController,
                              labelText: LocalizationService()
                                  .translate(TranslationKeys.password),
                              hintText: LocalizationService()
                                  .translate('enter_password'),
                              prefixIcon: const Icon(Icons.lock_outline),
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                                padding: const EdgeInsets.all(12),
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                                tooltip: 'Toggle password visibility',
                              ),
                              validator: validatePassword,
                            ),
                          ),
                          AppSpacing.verticalMd,
                          FadeInAnimation(
                            delay: const Duration(milliseconds: 800),
                            child: Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: TextButton(
                                onPressed: () => context.go('/forgot-password'),
                                child: Text(
                                  LocalizationService().translate(
                                      TranslationKeys.forgotPassword),
                                  style: AppTextStyles.labelText.copyWith(
                                    color: context.colors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          AppSpacing.verticalXl,
                          FadeInAnimation(
                            delay: const Duration(milliseconds: 1000),
                            child: SizedBox(
                              width: double.infinity,
                              child: PrimaryButton(
                                text: LocalizationService()
                                    .translate(TranslationKeys.loginButton),
                                onPressed:
                                    (authProvider.isLoading || _isSubmitting)
                                        ? null
                                        : _login,
                                isLoading:
                                    authProvider.isLoading || _isSubmitting,
                              ),
                            ),
                          ),
                          AppSpacing.verticalLg,
                          FadeInAnimation(
                            delay: const Duration(milliseconds: 1200),
                            child: Row(
                              children: [
                                Expanded(
                                    child:
                                        Divider(color: context.colors.border)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md),
                                  child: Text(
                                    LocalizationService()
                                        .translate(TranslationKeys.or),
                                    style: AppTextStyles.caption.copyWith(
                                      color: context.colors.textSubtle,
                                    ),
                                  ),
                                ),
                                Expanded(
                                    child:
                                        Divider(color: context.colors.border)),
                              ],
                            ),
                          ),
                          AppSpacing.verticalLg,
                          FadeInAnimation(
                            delay: const Duration(milliseconds: 1400),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  LocalizationService().translate(
                                      TranslationKeys.dontHaveAccount),
                                  style: AppTextStyles.bodyText,
                                ),
                                TextButton(
                                  onPressed: () => context.go('/signup'),
                                  child: Text(
                                    LocalizationService().translate(
                                        TranslationKeys.signupButton),
                                    style: AppTextStyles.labelText.copyWith(
                                      color: context.colors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
