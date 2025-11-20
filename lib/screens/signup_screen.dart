import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../widgets/directional_icon.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/localization_service.dart';
import '../services/connectivity_service.dart';
import '../services/offline_mode_service.dart';
import '../utils/validators.dart';
import '../utils/responsive_utils.dart';
import '../constants/responsive_constants.dart';
import '../services/error_handler.dart';
import '../widgets/phone_input_field.dart';
import '../services/phone_service.dart';
import '../constants/translation_keys.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_form_field.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_language_selector.dart';
import '../widgets/auth_link.dart';
import '../widgets/animations.dart';
import '../utils/design_system.dart';
import '../constants/form_constants.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  PhoneNumber? _phoneNumber;
  String? _selectedGender;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  // Local flag to disable the submit button while a request is in-flight.
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }


  Future<void> _signup() async {
    // Validate synchronously using Form validators before making any API calls.
    if (!_formKey.currentState!.validate()) return;

    // Check network connectivity before attempting signup
    final networkStatus = await ConnectivityService.checkConnectivity();
    if (!networkStatus.canReachSupabase) {
      if (!mounted) return;

      // Offer offline mode as an option
      final shouldUseOfflineMode = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Connection Issue'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ConnectivityService.getErrorMessageAndSuggestions(networkStatus)),
                const SizedBox(height: 16),
                const Text(
                  'Would you like to save your signup information for when you\'re back online?',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                ExpansionTile(
                  title: const Text('Technical Details'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SelectableText(
                        networkStatus.details,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save for Later'),
            ),
            if (kDebugMode)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                  context.go('/debug');
                },
                child: const Text('Debug'),
              ),
          ],
        ),
      );
      
      if (shouldUseOfflineMode == true) {
        // Store signup data for later processing
        await OfflineModeService.storePendingSignup({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text, // In real app, this should be hashed
          'age': int.parse(_ageController.text.trim()),
          'phone': _phoneNumber?.phoneNumber ?? _phoneController.text.trim(),
          'gender': _selectedGender,
          'role': 'player',
        });
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signup information saved! We\'ll process it when you\'re back online.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
        
        // Clear the form
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        _ageController.clear();
        _phoneController.clear();
        setState(() {
          _phoneNumber = null;
          _selectedGender = null;
        });
      }
      
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // If user is already logged in, log them out first
      if (authProvider.isAuthenticated) {
        await authProvider.logout();
      }

      final isConfirmed = await authProvider.signup(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        age: int.parse(_ageController.text.trim()),
        phone: _phoneNumber?.phoneNumber ?? _phoneController.text.trim(),
        gender: _selectedGender,
        role: 'player', // Always default to player role
      );

      if (!mounted) return;

      if (isConfirmed) {
        // User is now logged in with token, navigate to home
        context.go('/home');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Welcome!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Email confirmation required, navigate to login
        context.go('/login');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created successfully! Please check your email to confirm your account before logging in.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 8),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      // Use the standardized error handler for consistent error messages
      final errorMessage = ErrorHandler.userMessage(error);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLargeScreen = context.isDesktop; // Use responsive utils
    final isMediumScreen = context.isTablet; // Use responsive utils

    // If user is already authenticated, show a message instead of signup form
    if (authProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Already Signed In'),
          leading: IconButton(
            icon: const DirectionalIcon(icon: Icons.arrow_back),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'You are already signed in!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'You are currently logged in as ${authProvider.user?.email ?? 'Unknown'}. If you want to create a new account, please logout first.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Continue to App'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    await authProvider.logout();
                    // After logout, the screen will rebuild and show the signup form
                  },
                  child: const Text('Logout and Create New Account'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Debug Button (only in debug mode)
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report, color: Colors.grey),
              onPressed: () => context.go('/debug'),
              tooltip: 'Network Diagnostics',
            ),
          const AuthLanguageSelector(),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (isLargeScreen) {
              // Large screen layout: Form on the left, empty space on the right
              return Row(
                children: [
                  // Left side - Form
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      padding: ResponsiveUtils.getResponsivePadding(context),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: screenHeight - 48, // Account for SafeArea
                          maxWidth: 400,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: context.itemSpacing * 4),

                            const AuthHeader(
                              titleTranslationKey: 'signup_title',
                              subtitleTranslationKey: 'signup_subtitle',
                              icon: Icons.person_add,
                            ).withFadeIn(delay: const Duration(milliseconds: 200)),

                            const SizedBox(height: FootConnectSpacing.space8),

                            // Signup Form
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: FootConnectComponentSizing.textFieldHeight,
                                    child: AuthFormField(
                                      controller: _nameController,
                                      translationKey: 'full_name',
                                      prefixIcon: Icons.person_outline,
                                      validator: validateName,
                                    ),
                                  ).withFadeIn(delay: const Duration(milliseconds: 400)),

                                  const SizedBox(height: FootConnectSpacing.space4),

                                  SizedBox(
                                    height: FootConnectComponentSizing.textFieldHeight,
                                    child: AuthFormField(
                                      controller: _emailController,
                                      translationKey: 'email',
                                      prefixIcon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: validateEmail,
                                    ),
                                  ).withFadeIn(delay: const Duration(milliseconds: 600)),

                                  const SizedBox(height: FootConnectSpacing.space4),

                                  SizedBox(
                                    height: FootConnectComponentSizing.textFieldHeight,
                                    child: AuthFormField(
                                      controller: _ageController,
                                      translationKey: 'age',
                                      prefixIcon: Icons.calendar_today,
                                      keyboardType: TextInputType.number,
                                      validator: validateAge,
                                    ),
                                  ).withFadeIn(delay: const Duration(milliseconds: 800)),

                                  const SizedBox(height: FormConstants.fieldSpacing),

                                  // Phone Number Field
                                  Text(
                                    LocalizationService().translate('phone'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontSize: context.isMobile ? 16 : 18,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: context.buttonHeight,
                                    child: PhoneInputField(
                                      controller: _phoneController,
                                      onChanged: (phoneNumber) {
                                        setState(() => _phoneNumber = phoneNumber);
                                      },
                                      hintText: LocalizationService().translate('phone'),
                                      initialCountryCode: 'MA',
                                    ),
                                  ),
                                  SizedBox(height: context.itemSpacing * 0.5),
                                  // Phone requirements hint
                                  Container(
                                    padding: ResponsiveConstants.getResponsivePadding(context, 'md'),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surface.withAlpha(51),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outline.withAlpha(77),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          LocalizationService().translate(
                                            TranslationKeys.phoneRequirements,
                                          ),
                                          style: TextStyle(
                                            fontSize: context.isMobile
                                                ? 11
                                                : 12,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                        ),
                                        SizedBox(
                                          height: context.itemSpacing * 0.25,
                                        ),
                                        Text(
                                          '• ${LocalizationService().translate(TranslationKeys.phoneReqDigits)}',
                                          style: TextStyle(
                                            fontSize: context.isMobile
                                                ? 10
                                                : 11,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withAlpha(179),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: FormConstants.fieldSpacing),

                                  // Gender Field
                                  Text(
                                    'Gender',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontSize: context.isMobile ? 16 : 18,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: context.buttonHeight,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _selectedGender,
                                      decoration: InputDecoration(
                                        hintText: 'Select your gender',
                                        prefixIcon: Icon(
                                          Icons.person,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface.withAlpha(153),
                                        ),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'male',
                                          child: Text('Male'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'female',
                                          child: Text('Female'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() => _selectedGender = value);
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please select your gender';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),

                                  const SizedBox(height: FormConstants.fieldSpacing),

                                  // Password Field
                                  Text(
                                    LocalizationService().translate('password'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontSize: context.isMobile ? 16 : 18,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: context.buttonHeight,
                                    child: TextFormField(
                                      controller: _passwordController,
                                      decoration: InputDecoration(
                                        hintText: LocalizationService().translate(
                                          'enter_password',
                                        ),
                                        prefixIcon: Icon(
                                          Icons.lock_outline,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface.withAlpha(153),
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface.withAlpha(153),
                                          ),
                                          onPressed: () {
                                            setState(
                                              () => _obscurePassword =
                                                  !_obscurePassword,
                                            );
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
                                      validator: (value) =>
                                          validatePassword(value),
                                    ),
                                  ),
                                  SizedBox(height: context.itemSpacing * 0.5),
                                  // Password strength hint (weak/strong) to guide the user.
                                  Builder(
                                    builder: (context) {
                                      final pwd = _passwordController.text;
                                      if (pwd.isEmpty) {
                                        return const SizedBox.shrink();
                                      }
                                      if (pwd.length < 8) {
                                        return Text(
                                          LocalizationService().translate(
                                            'password_strength_weak',
                                          ),
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                            fontSize: context.isMobile
                                                ? 11
                                                : 12,
                                          ),
                                        );
                                      }
                                      return Text(
                                        LocalizationService().translate(
                                          'password_strength_strong',
                                        ),
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          fontSize: context.isMobile ? 11 : 12,
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(height: FormConstants.fieldSpacing),
   
                                  // Confirm Password Field
                                  Text(
                                    LocalizationService().translate('confirm_password'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontSize: context.isMobile ? 16 : 18,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: context.buttonHeight,
                                    child: TextFormField(
                                      controller: _confirmPasswordController,
                                      decoration: InputDecoration(
                                        hintText: LocalizationService().translate(
                                          'confirm_password',
                                        ),
                                        prefixIcon: Icon(
                                          Icons.lock_outline,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface.withAlpha(153),
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureConfirmPassword
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface.withAlpha(153),
                                          ),
                                          onPressed: () {
                                            setState(
                                              () => _obscureConfirmPassword =
                                                  !_obscureConfirmPassword,
                                            );
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
                                      validator: (value) =>
                                          validateConfirmPassword(
                                            value,
                                            _passwordController.text,
                                          ),
                                    ),
                                  ),

                                  SizedBox(height: ResponsiveConstants.spacingValue('3xl')),

                                  SizedBox(
                                    height: MediaQuery.of(context).size.width > 600 ? FormConstants.buttonHeightLarge : FormConstants.mobileButtonHeightLarge,
                                    child: AuthButton(
                                      translationKey: 'signup_button',
                                      onPressed: (authProvider.isLoading || _isSubmitting) ? null : _signup,
                                      isLoading: authProvider.isLoading || _isSubmitting,
                                    ),
                                  ),

                                  SizedBox(height: context.itemSpacing * 2),

                                  AuthLink(
                                    textTranslationKey: 'already_have_account',
                                    linkTranslationKey: 'signin_button',
                                    onPressed: () => context.go('/login'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Right side - Empty space or background
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primary.withAlpha(26),
                            Theme.of(
                              context,
                            ).colorScheme.secondary.withAlpha(26),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.sports_soccer,
                          size: 200,
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(26),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              // Mobile/Tablet layout: Centered form
              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMediumScreen ? 48.0 : 24.0,
                    vertical: 24.0,
                  ),
                  child: Container(
                    width: isMediumScreen ? screenWidth * 0.6 : double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),

                        const AuthHeader(
                          titleTranslationKey: 'signup_title',
                          subtitleTranslationKey: 'signup_subtitle',
                          icon: Icons.person_add,
                        ),

                        // Signup Form
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: context.buttonHeight,
                                child: AuthFormField(
                                  controller: _nameController,
                                  translationKey: 'full_name',
                                  prefixIcon: Icons.person_outline,
                                  validator: validateName,
                                ),
                              ),

                              const SizedBox(height: FormConstants.fieldSpacing),

                              SizedBox(
                                height: context.buttonHeight,
                                child: AuthFormField(
                                  controller: _emailController,
                                  translationKey: 'email',
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: validateEmail,
                                ),
                              ),

                              const SizedBox(height: FormConstants.fieldSpacing),

                              SizedBox(
                                height: context.buttonHeight,
                                child: AuthFormField(
                                  controller: _ageController,
                                  translationKey: 'age',
                                  prefixIcon: Icons.calendar_today,
                                  keyboardType: TextInputType.number,
                                  validator: validateAge,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Phone Number Field
                              Text(
                                LocalizationService().translate('phone'),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: context.buttonHeight,
                                child: PhoneInputField(
                                  controller: _phoneController,
                                  onChanged: (phoneNumber) {
                                    setState(() => _phoneNumber = phoneNumber);
                                  },
                                  hintText: LocalizationService().translate('phone'),
                                  initialCountryCode: 'MA',
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Phone requirements hint
                              Container(
                                padding: ResponsiveConstants.getResponsivePadding(context, 'md'),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surface.withAlpha(51),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline.withAlpha(77),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      LocalizationService().translate(
                                        TranslationKeys.phoneRequirements,
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '• ${LocalizationService().translate(TranslationKeys.phoneReqDigits)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface.withAlpha(179),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Gender Field
                              Text(
                                'Gender',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: context.buttonHeight,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedGender,
                                  decoration: InputDecoration(
                                    hintText: 'Select your gender',
                                    prefixIcon: Icon(
                                      Icons.person,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withAlpha(153),
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'male',
                                      child: Text('Male'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'female',
                                      child: Text('Female'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() => _selectedGender = value);
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please select your gender';
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Password Field
                              Text(
                                LocalizationService().translate('password'),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: context.buttonHeight,
                                child: TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    hintText: LocalizationService().translate(
                                      'enter_password',
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withAlpha(153),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface.withAlpha(153),
                                      ),
                                      onPressed: () {
                                        setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        );
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
                              ),
                              const SizedBox(height: 8),
                              // Password requirements hint
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surface.withAlpha(51),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline.withAlpha(77),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      LocalizationService().translate(
                                        'password_requirements',
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ...[
                                      '• ${LocalizationService().translate('password_req_length')}',
                                      '• ${LocalizationService().translate('password_req_uppercase')}',
                                      '• ${LocalizationService().translate('password_req_lowercase')}',
                                      '• ${LocalizationService().translate('password_req_digit')}',
                                    ].map(
                                      (requirement) => Text(
                                        requirement,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withAlpha(179),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Builder(
                                builder: (context) {
                                  final pwd = _passwordController.text;
                                  if (pwd.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  if (pwd.length < 8) {
                                    return Text(
                                      LocalizationService().translate(
                                        'password_strength_weak',
                                      ),
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                        fontSize: 12,
                                      ),
                                    );
                                  }
                                  return Text(
                                    LocalizationService().translate(
                                      'password_strength_strong',
                                    ),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 16),

                              // Confirm Password Field
                              Text(
                                LocalizationService().translate('confirm_password'),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: context.buttonHeight,
                                child: TextFormField(
                                  controller: _confirmPasswordController,
                                  decoration: InputDecoration(
                                    hintText: LocalizationService().translate(
                                      'confirm_password',
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withAlpha(153),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface.withAlpha(153),
                                      ),
                                      onPressed: () {
                                        setState(
                                          () => _obscureConfirmPassword =
                                              !_obscureConfirmPassword,
                                        );
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
                                  validator: (value) => validateConfirmPassword(
                                    value,
                                    _passwordController.text,
                                  ),
                                ),
                              ),

                              const SizedBox(height: FormConstants.sectionSpacing),

                              SizedBox(
                                height: MediaQuery.of(context).size.width > 600 ? FormConstants.buttonHeightLarge : FormConstants.mobileButtonHeightLarge,
                                child: AuthButton(
                                  translationKey: 'signup_button',
                                  onPressed: (authProvider.isLoading || _isSubmitting) ? null : _signup,
                                  isLoading: authProvider.isLoading || _isSubmitting,
                                ),
                              ),

                              const SizedBox(height: FormConstants.fieldSpacing),

                              AuthLink(
                                textTranslationKey: 'already_have_account',
                                linkTranslationKey: 'signin_button',
                                onPressed: () => context.go('/login'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
