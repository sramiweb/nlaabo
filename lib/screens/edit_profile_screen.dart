import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../services/error_handler.dart';
import '../utils/validators.dart';
import '../models/user.dart';
import '../widgets/footer.dart';
import '../widgets/focusable_form_field.dart';
import '../widgets/enhanced_form_field.dart';
import '../widgets/required_field_indicator.dart';
import '../widgets/responsive_button.dart';
import '../utils/design_system.dart';
import '../constants/translation_keys.dart';
import '../constants/form_constants.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _apiService = ApiService();

  String? _selectedGender;
  String? _selectedCity;
  String? _selectedSkillLevel;
  String? _selectedPosition;
  List<String> _cities = [];
  final List<String> _positions = [
    'Gardien',
    'Défenseur',
    'Milieu',
    'Attaquant',
  ];
  Uint8List? _avatarImage;
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isInitialized = false;



  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Load cities first, then user data to avoid race conditions
    await _loadCities();
    await _loadUserData();
  }

  Future<void> _loadCities() async {
    try {
      final cities = await _apiService.getCities();
      if (mounted) {
        setState(() {
          _cities = cities.map((c) => c.name).toList();
          if (_cities.isEmpty) {
            _cities = ['Nador', 'Casablanca', 'Rabat', 'Marrakech', 'Fes', 'Tangier', 'Agadir', 'Oujda'];
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to load cities: $e');
      if (mounted) {
        setState(() {
          _cities = ['Nador', 'Casablanca', 'Rabat', 'Marrakech', 'Fes', 'Tangier', 'Agadir', 'Oujda'];
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      // Try to get fresh user data from API
      final authProvider = context.read<AuthProvider>();
      await authProvider.refreshUser();
      final user = authProvider.user;

      if (mounted && user != null) {
        // Initialize form with current user data
        await _initializeFormWithUserData(user);
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      debugPrint('Failed to load fresh user data: $e');
      // Fallback to cached user data from AuthProvider
      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        final user = authProvider.user;

        if (user != null) {
          await _initializeFormWithUserData(user);
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to load profile data. Please try again.'),
              action: SnackBarAction(label: 'Retry', onPressed: _loadUserData),
            ),
          );
        }
      }
    }
  }

  Future<void> _initializeFormWithUserData(User user) async {
    debugPrint('🔄 Initializing form with user data...');
    debugPrint('User data: name=${user.name}, position=${user.position}, location=${user.location}, gender=${user.gender}, skillLevel=${user.skillLevel}');

    // Initialize text controllers
    _nameController.text = user.name;
    _bioController.text = user.bio ?? '';
    _phoneController.text = user.phone ?? '';
    _ageController.text = user.age?.toString() ?? '';

    // Initialize dropdown values with proper validation
    _selectedGender = user.gender;
    _selectedSkillLevel = user.skillLevel;

    // Position dropdown - ensure the value exists in our list
    _selectedPosition = (user.position != null && _positions.contains(user.position))
        ? user.position
        : null;
    debugPrint('Position: user.position="${user.position}", _positions=$_positions, selected=$_selectedPosition');

    // City dropdown - ensure the value exists in our loaded cities
    _selectedCity = (user.location != null && _cities.contains(user.location))
        ? user.location
        : null;
    debugPrint('Location: user.location="${user.location}", _cities.length=${_cities.length}, selected=$_selectedCity');

    debugPrint('✅ Form initialization complete');
    debugPrint('Final dropdown values: gender=$_selectedGender, skillLevel=$_selectedSkillLevel, position=$_selectedPosition, city=$_selectedCity');

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _avatarImage = bytes);
    }
  }

  void _deleteImage() {
    setState(() => _avatarImage = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LocalizationService().translate('picture_deleted')),
      ),
    );
  }

  Future<void> _showSaveConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService().translate('confirm_save')),
        content: Text(LocalizationService().translate('confirm_save_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(LocalizationService().translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(LocalizationService().translate('save')),
          ),
        ],
      ),
    );

    if (result == true) {
      await _saveProfile();
    }
  }

  Future<void> _saveProfile() async {
    debugPrint('🔵 STEP 1: _saveProfile called');
    
    // Debug each field before validation
    debugPrint('📝 Form field values before validation:');
    debugPrint('  - Name: "${_nameController.text}"');
    debugPrint('  - Bio: "${_bioController.text}"');
    debugPrint('  - Phone: "${_phoneController.text}"');
    debugPrint('  - Age: "${_ageController.text}"');
    debugPrint('  - Position: $_selectedPosition');
    debugPrint('  - Selected City: $_selectedCity');
    debugPrint('  - Selected Gender: $_selectedGender');
    debugPrint('  - Selected Skill Level: $_selectedSkillLevel');
    
    debugPrint('🔵 Running form validation...');
    final isValid = _formKey.currentState?.validate() ?? false;
    debugPrint('📝 Form validation result: $isValid');
    
    if (!isValid) {
      debugPrint('❌ STEP 2: Form validation failed');
      debugPrint('⚠️ Check the form for validation errors (red text under fields)');
      debugPrint('⚠️ Scroll through the form to see which field has an error');
      return;
    }
    debugPrint('✅ STEP 2: Form validation passed');

    setState(() => _isSubmitting = true);
    debugPrint('🔵 STEP 3: Set isSubmitting = true');

    try {
      String? imageUrl;
      if (_avatarImage != null) {
        debugPrint('🔵 STEP 4: Uploading avatar image...');
        imageUrl = await _apiService.uploadAvatarBytes(
          _avatarImage!,
          'avatar.jpg',
        );
        debugPrint('✅ STEP 4: Avatar uploaded: $imageUrl');
      } else {
        debugPrint('⚪ STEP 4: No avatar to upload');
      }

      // Always update with current values (API will handle what actually changes)
      final name = _nameController.text.trim();
      final position = _selectedPosition;
      final bio = _bioController.text.trim();
      final phone = _phoneController.text.trim();
      final ageText = _ageController.text.trim();
      final age = ageText.isNotEmpty ? int.tryParse(ageText) : null;
      final location = _selectedCity;
      final gender = _selectedGender;
      final skillLevel = _selectedSkillLevel;

      debugPrint('🔵 STEP 5: Collected form data:');
      debugPrint('  - name: $name');
      debugPrint('  - position: $position');
      debugPrint('  - bio: $bio');
      debugPrint('  - phone: $phone');
      debugPrint('  - age: $age');
      debugPrint('  - location: $location');
      debugPrint('  - gender: $gender');
      debugPrint('  - skillLevel: $skillLevel');
      debugPrint('  - imageUrl: $imageUrl');

      // Validate required fields
      if (name.isEmpty) {
        debugPrint('❌ STEP 6: Name is empty');
        throw ValidationError('Name is required');
      }
      debugPrint('✅ STEP 6: Name validation passed');

      // Update profile with only changed fields
      if (!mounted) {
        debugPrint('❌ STEP 7: Widget not mounted');
        return;
      }
      debugPrint('✅ STEP 7: Widget is mounted');
      
      final authProvider = context.read<AuthProvider>();
      debugPrint('🔵 STEP 8: Calling authProvider.updateProfile...');
      
      await authProvider.updateProfile(
        name: name,
        position: position,
        bio: bio.isNotEmpty ? bio : null,
        phone: phone.isNotEmpty ? phone : null,
        age: age,
        location: location,
        gender: gender,
        skillLevel: skillLevel,
        imageUrl: imageUrl,
      );
      debugPrint('✅ STEP 8: authProvider.updateProfile completed');
      
      debugPrint('🔵 STEP 9: Calling authProvider.refreshUser...');
      await authProvider.refreshUser();
      debugPrint('✅ STEP 9: authProvider.refreshUser completed');

      if (mounted) {
        debugPrint('✅ STEP 10: Showing success message and navigating');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService().translate('profile_updated')),
          ),
        );
        context.go('/profile');
      } else {
        debugPrint('❌ STEP 10: Widget not mounted, skipping navigation');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR in _saveProfile: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationService().translate('error')}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        debugPrint('🔵 STEP 11: Setting isSubmitting = false');
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    if (_isLoading || !_isInitialized || user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(LocalizationService().translate('edit_profile')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/profile'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(LocalizationService().translate('loading')),
            ],
          ),
        ),
        persistentFooterButtons: const [Footer()],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService().translate('edit_profile')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile'),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.02),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width > 900
                      ? 48.0
                      : MediaQuery.of(context).size.width > 600
                      ? 32.0
                      : 24.0,
                  vertical: 24.0,
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width > 900
                      ? constraints.maxWidth * 0.5
                      : MediaQuery.of(context).size.width > 600
                      ? constraints.maxWidth * 0.7
                      : double.infinity,
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: FocusableForm(
                    formKey: _formKey,
                    onSubmit: _showSaveConfirmation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Enhanced Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.edit,
                                  size: 40,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                LocalizationService().translate('edit_profile'),
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                LocalizationService().translate('update_your_information'),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Enhanced Form Section
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Avatar Section
                              Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: _avatarImage != null
                                ? MemoryImage(_avatarImage!)
                                : (user.imageUrl != null
                                          ? NetworkImage(user.imageUrl!)
                                          : null)
                                      as ImageProvider?,
                            child: _avatarImage == null && user.imageUrl == null
                                ? Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  )
                                : null,
                          ),
                          if (_avatarImage != null || user.imageUrl != null)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  onPressed: _deleteImage,
                                  padding: const EdgeInsets.all(12),
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                  tooltip: LocalizationService().translate(
                                    'delete_picture',
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                onPressed: _pickImage,
                                padding: const EdgeInsets.all(12),
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                                tooltip: LocalizationService().translate(
                                  'change_picture',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: FormConstants.sectionSpacing),

                      // Profile Form Fields
                      EnhancedFormField(
                        controller: _nameController,
                        labelText: '${LocalizationService().translate('full_name')} ${RequiredFieldIndicator.text}',
                        hintText: LocalizationService().translate('enter_full_name'),
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: FootConnectColors.primaryBlue,
                        ),
                        validator: (value) {
                          debugPrint('🔍 Validating Name: "$value"');
                          final error = validateName(value);
                          if (error != null) {
                            debugPrint('❌ Name validation error: $error');
                          } else {
                            debugPrint('✅ Name validation passed');
                          }
                          return error;
                        },
                        showValidationFeedback: true,
                      ),

                      const SizedBox(height: FootConnectSpacing.space4),

                      EnhancedFormField(
                        controller: TextEditingController(text: user.email),
                        labelText: LocalizationService().translate('email'),
                        prefixIcon: const Icon(
                          Icons.email,
                          color: FootConnectColors.primaryBlue,
                        ),
                        enabled: false,
                        showValidationFeedback: false,
                      ),

                      const SizedBox(height: FootConnectSpacing.space4),

                      EnhancedFormField(
                        controller: _bioController,
                        labelText: LocalizationService().translate('bio'),
                        hintText: LocalizationService().translate('bio_hint'),
                        prefixIcon: const Icon(
                          Icons.description,
                          color: FootConnectColors.primaryBlue,
                        ),
                        maxLines: 3,
                        maxLength: 200,
                        validator: (value) {
                          debugPrint('🔍 Validating Bio: "$value"');
                          debugPrint('✅ Bio validation passed (optional field)');
                          return null;
                        },
                        showValidationFeedback: true,
                      ),

                      const SizedBox(height: FootConnectSpacing.space4),

                      EnhancedFormField(
                        controller: _phoneController,
                        labelText: LocalizationService().translate('phone'),
                        hintText: LocalizationService().translate(TranslationKeys.phoneHint),
                        prefixIcon: const Icon(
                          Icons.phone,
                          color: FootConnectColors.primaryBlue,
                        ),
                        keyboardType: TextInputType.phone,
                        maxLength: 30,
                        validator: (value) {
                          debugPrint('🔍 Validating Phone: "$value"');
                          if (value == null || value.trim().isEmpty) {
                            debugPrint('✅ Phone validation passed (empty)');
                            return null;
                          }
                          final error = validatePhoneOptional(value);
                          if (error != null) {
                            debugPrint('❌ Phone validation error: $error');
                          } else {
                            debugPrint('✅ Phone validation passed');
                          }
                          return error;
                        },
                        showValidationFeedback: true,
                      ),

                      const SizedBox(height: FootConnectSpacing.space4),

                      EnhancedFormField(
                        controller: _ageController,
                        labelText: LocalizationService().translate('age'),
                        hintText: LocalizationService().translate('age_hint'),
                        prefixIcon: const Icon(
                          Icons.calendar_today,
                          color: FootConnectColors.primaryBlue,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          debugPrint('🔍 Validating Age: "$value"');
                          final error = validateAgeOptional(value);
                          if (error != null) {
                            debugPrint('❌ Age validation error: $error');
                          } else {
                            debugPrint('✅ Age validation passed');
                          }
                          return error;
                        },
                        showValidationFeedback: true,
                      ),

                      const SizedBox(height: FootConnectSpacing.space4),

                      Container(
                        height: FootConnectComponentSizing.textFieldHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(FootConnectBorderRadius.medium),
                          border: Border.all(
                            color: FootConnectColors.neutralGray.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('city_${_selectedCity ?? "null"}'), // Force rebuild when value changes
                          initialValue: _selectedCity,
                          decoration: InputDecoration(
                            labelText: LocalizationService().translate('location'),
                            hintText: LocalizationService().translate('select_city'),
                            prefixIcon: const Icon(
                              Icons.location_on,
                              color: FootConnectColors.primaryBlue,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: _cities.map((city) => DropdownMenuItem(
                            value: city,
                            child: Text(city),
                          )).toList(),
                          validator: (value) {
                            debugPrint('🔍 Validating Location: "$value"');
                            debugPrint('✅ Location validation passed (optional field)');
                            return null;
                          },
                          onChanged: (value) => setState(() => _selectedCity = value),
                          isExpanded: true,
                        ),
                      ),

                      const SizedBox(height: FootConnectSpacing.space4),

                      Container(
                        height: FootConnectComponentSizing.textFieldHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(FootConnectBorderRadius.medium),
                          border: Border.all(
                            color: FootConnectColors.neutralGray.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('position_${_selectedPosition ?? "null"}'), // Force rebuild when value changes
                          initialValue: _selectedPosition,
                          decoration: InputDecoration(
                            labelText: LocalizationService().translate('position'),
                            hintText: LocalizationService().translate('position_hint'),
                            prefixIcon: const Icon(
                              Icons.sports_soccer,
                              color: FootConnectColors.primaryBlue,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: _positions.map((position) => DropdownMenuItem(
                            value: position,
                            child: Text(position),
                          )).toList(),
                          validator: (value) {
                            debugPrint('🔍 Validating Position: "$value"');
                            debugPrint('✅ Position validation passed (optional field)');
                            return null;
                          },
                          onChanged: (value) => setState(() => _selectedPosition = value),
                          isExpanded: true,
                        ),
                      ),

                      const SizedBox(height: FootConnectSpacing.space4),

                      Container(
                        height: FootConnectComponentSizing.textFieldHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(FootConnectBorderRadius.medium),
                          border: Border.all(
                            color: FootConnectColors.neutralGray.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('skill_${_selectedSkillLevel ?? "null"}'), // Force rebuild when value changes
                          initialValue: _selectedSkillLevel,
                          decoration: InputDecoration(
                            labelText: LocalizationService().translate('skill_level'),
                            hintText: LocalizationService().translate('select_skill_level'),
                            prefixIcon: const Icon(
                              Icons.star,
                              color: FootConnectColors.primaryBlue,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: [
                            DropdownMenuItem(value: 'beginner', child: Text(LocalizationService().translate('beginner'))),
                            DropdownMenuItem(value: 'intermediate', child: Text(LocalizationService().translate('intermediate'))),
                            DropdownMenuItem(value: 'advanced', child: Text(LocalizationService().translate('advanced'))),
                          ],
                          validator: (value) {
                            debugPrint('🔍 Validating Skill level: "$value"');
                            debugPrint('✅ Skill level validation passed (optional field)');
                            return null;
                          },
                          onChanged: (value) => setState(() => _selectedSkillLevel = value),
                        ),
                      ),

                      const SizedBox(height: FootConnectSpacing.space4),

                      Container(
                        height: FootConnectComponentSizing.textFieldHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(FootConnectBorderRadius.medium),
                          border: Border.all(
                            color: FootConnectColors.neutralGray.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('gender_${_selectedGender ?? "null"}'), // Force rebuild when value changes
                          initialValue: _selectedGender,
                          decoration: InputDecoration(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  RequiredFieldIndicator.text,
                                  style: TextStyle(color: Colors.red),
                                ),
                                const SizedBox(width: 4),
                                Text(LocalizationService().translate('gender')),
                              ],
                            ),
                            hintText: LocalizationService().translate('select_gender'),
                            prefixIcon: const Icon(
                              Icons.person,
                              color: FootConnectColors.primaryBlue,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'male',
                              child: Text(
                                LocalizationService().translate('male'),
                                style: FootConnectTypography.bodyRegularStyle,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'female',
                              child: Text(
                                LocalizationService().translate('female'),
                                style: FootConnectTypography.bodyRegularStyle,
                              ),
                            ),
                          ],
                          validator: (value) {
                            debugPrint('🔍 Validating Gender: "$value"');
                            if (value == null || value.isEmpty) {
                              debugPrint('❌ Gender validation error: Gender is required');
                              return LocalizationService().translate('gender_required');
                            }
                            debugPrint('✅ Gender validation passed');
                            return null;
                          },
                          onChanged: (value) => setState(() => _selectedGender = value),
                        ),
                      ),

                              const SizedBox(height: FormConstants.sectionSpacing),

                              // Save Button
                              FootConnectButton(
                                text: LocalizationService().translate('save'),
                                onPressed: (_isSubmitting) ? null : _showSaveConfirmation,
                                size: ButtonSize.large,
                                variant: ButtonVariant.primary,
                                fullWidth: true,
                                loading: _isSubmitting,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
