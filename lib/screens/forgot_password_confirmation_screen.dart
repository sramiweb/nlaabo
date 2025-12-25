import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/localization_service.dart';
import '../widgets/enhanced_error_boundary.dart';
import '../widgets/directional_icon.dart';
import '../utils/responsive_utils.dart';
import '../constants/translation_keys.dart';

class ForgotPasswordConfirmationScreen extends StatelessWidget {
  final String email;

  const ForgotPasswordConfirmationScreen({
    super.key,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return ScreenErrorBoundary(
      screenName: 'ForgotPasswordConfirmationScreen',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Success Icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(26 / 255),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_read,
                        size: 50,
                        color: Colors.green,
                      ),
                    ),

                    SizedBox(height: context.itemSpacing * 2),

                    // Title
                    Text(
                      LocalizationService()
                          .translate(TranslationKeys.resetLinkSent),
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: context.itemSpacing),

                    // Instructions
                    Text(
                      LocalizationService()
                          .translate(TranslationKeys.checkEmailInstructions),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: context.itemSpacing),

                    // Email display
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.email,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              email,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: context.itemSpacing * 3),

                    // Back to Login Button
                    SizedBox(
                      width: double.infinity,
                      height: context.buttonHeight,
                      child: ElevatedButton(
                        onPressed: () => context.go('/login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          elevation: 4,
                          shadowColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          LocalizationService()
                              .translate(TranslationKeys.backToLogin),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
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
    );
  }
}
