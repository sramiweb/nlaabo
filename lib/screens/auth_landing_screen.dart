import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/localization_provider.dart';
import '../services/localization_service.dart';
import '../widgets/phone_input_field.dart';
import '../services/phone_service.dart';
import '../utils/design_system.dart';

enum AuthMode { login, signup }

class AuthLandingScreen extends StatefulWidget {
  const AuthLandingScreen({super.key});

  @override
  State<AuthLandingScreen> createState() => _AuthLandingScreenState();
}

class _AuthLandingScreenState extends State<AuthLandingScreen> {
  void _showLanguageDialog(BuildContext context) {
    final localizationProvider = Provider.of<LocalizationProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizationProvider.translate('language')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('English'),
                leading: const Text('🇺🇸'),
                onTap: () {
                  localizationProvider.setLanguage('en');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Français'),
                leading: const Text('🇫🇷'),
                onTap: () {
                  localizationProvider.setLanguage('fr');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('العربية'),
                leading: const Text('🇲🇦'),
                onTap: () {
                  localizationProvider.setLanguage('ar');
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Colors.grey),
            onPressed: () => _showLanguageDialog(context),
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            tooltip: 'Language',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isWideScreen ? _buildWideScreenLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildWideScreenLayout() {
    return Row(
      children: [
        // Left side - Auth Form
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withAlpha((0.3 * 255).round()),
                  width: 1,
                ),
              ),
            ),
            child: const Center(child: AuthForm()),
          ),
        ),
        // Right side - Welcome Content
        Expanded(
          flex: 1,
          child: Container(
            color: Theme.of(context).colorScheme.primary.withAlpha((0.05 * 255).round()),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(48.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/logo.png',
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      context.watch<LocalizationProvider>().translate('welcome_to_footconnect'),
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.watch<LocalizationProvider>().translate('football_community'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha((0.7 * 255).round()),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withAlpha((0.1 * 255).round()),
                        borderRadius: BorderRadius.circular(BorderRadiusSystem.extraLarge),
                      ),
                      child: Text(
                        context.watch<LocalizationProvider>().translate('join_the_game'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Top - Welcome Content (smaller)
        Container(
          color: Theme.of(context).colorScheme.primary.withAlpha((0.05 * 255).round()),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Image.asset(
                'assets/icons/logo.png',
                height: 100,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              Text(
                context.watch<LocalizationProvider>().translate('welcome_to_footconnect'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                context.watch<LocalizationProvider>().translate('connect_football_community'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withAlpha((0.7 * 255).round()),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        // Bottom - Auth Form
        const Expanded(child: Center(child: AuthForm())),
      ],
    );
  }
}

// Unified Auth Form Widget
class AuthForm extends StatefulWidget {
  const AuthForm({super.key});

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  AuthMode _authMode = AuthMode.login;
  final _formKey = GlobalKey<FormState>();

  // Controllers
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

  void _toggleAuthMode() {
    setState(() {
      _authMode = _authMode == AuthMode.login
          ? AuthMode.signup
          : AuthMode.login;
      // Clear form when switching modes
      _formKey.currentState?.reset();
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _ageController.clear();
      _phoneController.clear();
      _phoneNumber = null;
      _selectedGender = null;
    });
  }


  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (_authMode == AuthMode.login) {
        await authProvider.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (!mounted) return;
        context.go('/home');
      } else {
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
          role: 'player',
        );

        if (!mounted) return;

        if (isConfirmed) {
          context.go('/home');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                LocalizationService().translate('account_created_welcome'),
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                LocalizationService().translate('account_created_check_email'),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (error) {
      if (!mounted) return;

      String errorMessage;
      if (_authMode == AuthMode.login) {
        errorMessage = LocalizationService().translate('login_failed');
        if (error.toString().contains('Invalid login credentials')) {
          errorMessage = LocalizationService().translate('invalid_credentials');
        } else if (error.toString().contains('Email not confirmed')) {
          errorMessage = LocalizationService().translate('email_not_confirmed');
        }
      } else {
        errorMessage = error.toString();
        if (errorMessage.contains('User already registered') ||
            errorMessage.contains('already exists')) {
          errorMessage = LocalizationService().translate(
            'email_already_in_use',
          );
        } else if (errorMessage.contains('Password should be at least') ||
            errorMessage.contains('Password too weak')) {
          errorMessage = LocalizationService().translate('password_too_weak');
        } else {
          errorMessage =
              '${LocalizationService().translate('signup_failed')}: ${error.toString()}';
        }
      }

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
    final isLogin = _authMode == AuthMode.login;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(BorderRadiusSystem.large),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha((0.3 * 255).round()),
            width: 1,
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form Title
              Text(
                isLogin
                    ? context.watch<LocalizationProvider>().translate('login')
                    : context.watch<LocalizationProvider>().translate('signup'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Name Field (Signup only)
              if (!isLogin) ...[
                Text(
                  context.watch<LocalizationProvider>().translate('full_name'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: context.watch<LocalizationProvider>().translate('full_name'),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return LocalizationService().translate(
                        'full_name_required',
                      );
                    }
                    if (value.length < 2) {
                      return LocalizationService().translate(
                        'name_too_short_2',
                      );
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Email Field
              Text(
                context.watch<LocalizationProvider>().translate('email'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: context.watch<LocalizationProvider>().translate('enter_email'),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return LocalizationService().translate('email_required');
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return LocalizationService().translate('invalid_email');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Additional Signup Fields
              if (!isLogin) ...[
                // Phone Field
                Text(
                  context.watch<LocalizationProvider>().translate('phone'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                PhoneInputField(
                  controller: _phoneController,
                  onChanged: (phoneNumber) {
                    setState(() => _phoneNumber = phoneNumber);
                  },
                  hintText: '+212 XX XX XX XX',
                  initialCountryCode: 'MA',
                ),
                const SizedBox(height: 24),

                // Age Field
                Text(
                  context.watch<LocalizationProvider>().translate('age'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ageController,
                  decoration: InputDecoration(
                    hintText: context.watch<LocalizationProvider>().translate('age'),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    prefixIcon: Icon(
                      Icons.calendar_today,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return LocalizationService().translate('age_required');
                    }
                    final age = int.tryParse(value);
                    if (age == null || age < 13 || age > 100) {
                      return LocalizationService().translate(
                        'age_invalid_range',
                      );
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Gender Field
                Text(
                  context.watch<LocalizationProvider>().translate('gender'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedGender,
                  decoration: InputDecoration(
                    hintText: context.watch<LocalizationProvider>().translate('select_gender'),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    prefixIcon: Icon(
                      Icons.person,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'male',
                      child: Text(context.watch<LocalizationProvider>().translate('male')),
                    ),
                    DropdownMenuItem(
                      value: 'female',
                      child: Text(context.watch<LocalizationProvider>().translate('female')),
                    ),
                  ],
                  onChanged: (value) => setState(() => _selectedGender = value),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return LocalizationService().translate('gender_required');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Password Field
              Text(
                context.watch<LocalizationProvider>().translate('password'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  hintText: context.watch<LocalizationProvider>().translate('enter_password'),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    tooltip: 'Toggle password visibility',
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return LocalizationService().translate('password_required');
                  }
                  if (value.length < 6) {
                    return LocalizationService().translate(
                      'password_too_short',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Confirm Password Field (Signup only)
              if (!isLogin) ...[
                Text(
                  context.watch<LocalizationProvider>().translate('confirm_password'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    hintText: context.watch<LocalizationProvider>().translate(
                      'confirm_password',
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                      ),
                      onPressed: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
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
                      return LocalizationService().translate(
                        'confirm_password_required',
                      );
                    }
                    if (value != _passwordController.text) {
                      return LocalizationService().translate(
                        'passwords_not_match',
                      );
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Forgot Password (Login only)
              if (isLogin) ...[
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () => context.go('/forgot-password'),
                    child: Text(
                      context.watch<LocalizationProvider>().translate('forgot_password'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: (authProvider.isLoading || _isSubmitting)
                      ? null
                      : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    disabledBackgroundColor: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha((0.12 * 255).round()),
                    disabledForegroundColor: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha((0.38 * 255).round()),
                    elevation: 4,
                    shadowColor: Theme.of(
                      context,
                    ).colorScheme.primary.withAlpha((0.3 * 255).round()),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(BorderRadiusSystem.large),
                    ),
                  ),
                  child: (authProvider.isLoading || _isSubmitting)
                      ? SizedBox(
                          height: 28,
                          width: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Text(
                          isLogin
                              ? context.watch<LocalizationProvider>().translate('login_button')
                              : context.watch<LocalizationProvider>().translate(
                                  'signup_button',
                                ),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Toggle Mode Button
              Center(
                child: TextButton(
                  onPressed: _toggleAuthMode,
                  child: Text(
                    isLogin
                        ? context.watch<LocalizationProvider>().translate('dont_have_account')
                        : context.watch<LocalizationProvider>().translate(
                            'already_have_account',
                          ),
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
    );
  }
}
