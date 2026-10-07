import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../routes/app_router.dart';
import '../../theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';

/// Registration screen for new farmers.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _apiService = ApiService();
  final _tehsilController = TextEditingController();
  final _villageController = TextEditingController();

  // State → District dropdowns; Tehsil/Village are free text (see
  // _tehsilController / _villageController above).
  LocationOption? _selectedState;
  LocationOption? _selectedDistrict;

  List<LocationOption> _states = [];
  List<LocationOption> _districts = [];

  bool _statesLoading = false;
  bool _districtsLoading = false;
  bool _statesError = false;

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _guardianNameController.dispose();
    _passwordController.dispose();
    _tehsilController.dispose();
    _villageController.dispose();
    super.dispose();
  }

  Future<void> _loadStates() async {
    setState(() {
      _statesLoading = true;
      _statesError = false;
    });
    final states = await _apiService.getStates();
    if (!mounted) return;
    setState(() {
      _states = states;
      _statesLoading = false;
      _statesError = states.isEmpty;
    });
  }

  Future<void> _onStateSelected(LocationOption state) async {
    setState(() {
      _selectedState = state;
      _selectedDistrict = null;
      _districts = [];
      _districtsLoading = true;
    });
    final districts = await _apiService.getDistricts(state.code);
    if (!mounted) return;
    setState(() {
      _districts = districts;
      _districtsLoading = false;
    });
  }

  void _onDistrictSelected(LocationOption district) {
    setState(() => _selectedDistrict = district);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 32,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                gradient: AppColors.headerGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.15),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'signup.title'.tr(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'signup.subtitle'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Registration Form ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Phone Number
                    _buildLabel('Phone Number'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: 'Enter your phone number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (val) {
                        final digits = val?.trim() ?? '';
                        if (digits.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (digits.length != 10) {
                          return 'Phone number must be exactly 10 digits';
                        }
                        if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
                          return 'Enter a valid Indian mobile number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Full Name
                    _buildLabel('signup.full_name'.tr()),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'signup.full_name_hint'.tr(),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Father's / Husband's Name
                    _buildLabel("Father's / Husband's Name"),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _guardianNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: "Enter father's or husband's name",
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return "Please enter father's or husband's name";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // State → District → Tehsil → Village cascade
                    _buildLabel('State'),
                    const SizedBox(height: 8),
                    _buildCascadeDropdown(
                      hint: 'Select state',
                      value: _selectedState,
                      options: _states,
                      isLoading: _statesLoading,
                      hasError: _statesError,
                      onRetry: _loadStates,
                      onSelected: _onStateSelected,
                      errorValidatorMessage: 'Please select your state',
                    ),

                    if (_selectedState != null) ...[
                      const SizedBox(height: 20),
                      _buildLabel('District'),
                      const SizedBox(height: 8),
                      _buildCascadeDropdown(
                        hint: 'Select district',
                        value: _selectedDistrict,
                        options: _districts,
                        isLoading: _districtsLoading,
                        onSelected: _onDistrictSelected,
                        errorValidatorMessage: 'Please select your district',
                      ),
                    ],

                    if (_selectedDistrict != null) ...[
                      const SizedBox(height: 20),
                      _buildLabel('Tehsil'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _tehsilController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Enter your tehsil',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter your tehsil';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),
                      _buildLabel('Village'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _villageController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Enter your village',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter your village';
                          }
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Password
                    _buildLabel('Password'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      onChanged: (_) => setState(() {}), // live-refresh checklist below
                      decoration: InputDecoration(
                        hintText: 'Create a password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (val) {
                        final password = val ?? '';
                        if (password.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        if (!RegExp(r'[A-Z]').hasMatch(password)) {
                          return 'Add at least one uppercase letter';
                        }
                        if (!RegExp(r'[0-9]').hasMatch(password)) {
                          return 'Add at least one number';
                        }
                        if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=~`\[\]/\\;]').hasMatch(password)) {
                          return 'Add at least one special character';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildPasswordChecklist(),

                    const SizedBox(height: 36),

                    // Register button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text('signup.submit'.tr()),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  /// Live checklist of the password rules, ticking off as the farmer types.
  Widget _buildPasswordChecklist() {
    final password = _passwordController.text;
    final rules = <String, bool>{
      'At least 8 characters': password.length >= 8,
      'One uppercase letter (A-Z)': RegExp(r'[A-Z]').hasMatch(password),
      'One number (0-9)': RegExp(r'[0-9]').hasMatch(password),
      'One special character (!@#…)':
          RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=~`\[\]/\\;]').hasMatch(password),
    };

    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: rules.entries.map((entry) {
        final met = entry.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              met ? Icons.check_circle : Icons.circle_outlined,
              size: 14,
              color: met ? AppColors.primary : AppColors.textHint,
            ),
            const SizedBox(width: 4),
            Text(
              entry.key,
              style: TextStyle(
                fontSize: 12,
                color: met ? AppColors.primary : AppColors.textHint,
                fontWeight: met ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  /// One cascade level: State, District, Tehsil or Village.
  /// Tap-to-open a bottom sheet with a live-filtering search box, since no
  /// built-in Flutter dropdown supports type-to-filter directly inline.
  Widget _buildCascadeDropdown({
    required String hint,
    required LocationOption? value,
    required List<LocationOption> options,
    required bool isLoading,
    required ValueChanged<LocationOption> onSelected,
    required String errorValidatorMessage,
    bool hasError = false,
    VoidCallback? onRetry,
  }) {
    return FormField<LocationOption>(
      initialValue: value,
      validator: (_) => value == null ? errorValidatorMessage : null,
      builder: (field) {
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isLoading
              ? null
              : () => _openSearchSheet(
                    title: hint,
                    options: options,
                    onSelected: (opt) {
                      onSelected(opt);
                      field.didChange(opt);
                    },
                  ),
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: const Icon(Icons.location_on_outlined),
              suffixIcon: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.keyboard_arrow_down),
              errorText: field.errorText,
            ),
            child: hasError
                ? Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Couldn't load — tap to retry",
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ),
                      if (onRetry != null)
                        TextButton(onPressed: onRetry, child: const Text('Retry')),
                    ],
                  )
                : Text(
                    value?.name ?? '',
                    style: TextStyle(
                      color: value != null ? AppColors.textPrimary : AppColors.textHint,
                    ),
                  ),
          ),
        );
      },
    );
  }

  void _openSearchSheet({
    required String title,
    required List<LocationOption> options,
    required ValueChanged<LocationOption> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _SearchSheet(
          title: title,
          options: options,
          onSelected: (opt) {
            Navigator.pop(context);
            onSelected(opt);
          },
        );
      },
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final phone = _phoneController.text.trim();
      final password = _passwordController.text.trim();

      // Here we should realistically hit an /auth/signup endpoint on the backend.
      // But based on the current api_service structure, we'll just createUser.
      final userId = DateTime.now().millisecondsSinceEpoch.toString();

      final region = [
        _villageController.text.trim(),
        _tehsilController.text.trim(),
        _selectedDistrict!.name,
        _selectedState!.name,
      ].join(', ');

      final userModel = UserModel(
        id: userId,
        name: _nameController.text.trim(),
        guardianName: _guardianNameController.text.trim(),
        phone: phone,
        region: region,
        language: 'en',
        createdAt: DateTime.now(),
      );

      // Create user profile on backend
      final userMap = userModel.toMap();
      userMap['password'] = password;
      await ApiService().createUser(userId, userMap).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('API connection timed out.'),
      );

      final prefsBox = await Hive.openBox('prefs');
      await prefsBox.put('first_launch', false);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('signup.success'.tr()),
            backgroundColor: AppColors.primary,
          ),
        );
        // Registration only — the farmer logs in explicitly next, rather
        // than being auto-authenticated straight into the dashboard.
        Navigator.pushReplacementNamed(context, AppRouter.login);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    }
  }
}

/// Bottom sheet: search box (autofocus, live filter) + tappable results.
/// Used by every level of the State → District → Tehsil → Village cascade.
class _SearchSheet extends StatefulWidget {
  final String title;
  final List<LocationOption> options;
  final ValueChanged<LocationOption> onSelected;

  const _SearchSheet({
    required this.title,
    required this.options,
    required this.onSelected,
  });

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final _searchController = TextEditingController();
  late List<LocationOption> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.options;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.options
          : widget.options
              .where((o) => o.name.toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  widget.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: _onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Type to search...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No matches found',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final option = _filtered[index];
                          return ListTile(
                            title: Text(option.name),
                            onTap: () => widget.onSelected(option),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
