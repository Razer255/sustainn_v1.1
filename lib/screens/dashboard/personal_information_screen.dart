import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/mock_data.dart';
import '../../theme/app_colors.dart';

/// View/edit screen for the farmer's personal information
/// (name, guardian name, phone, region). Phone is shown read-only since
/// it is the login identifier.
class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() => _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  late final TextEditingController _nameController;
  late final TextEditingController _guardianNameController;
  late final TextEditingController _regionController;
  late final String _phone;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = MockData.currentUser;
    _nameController = TextEditingController(text: user.name);
    _guardianNameController = TextEditingController(text: user.guardianName);
    _regionController = TextEditingController(text: user.region);
    _phone = user.phone;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _guardianNameController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final userId = MockData.currentUser.id;
      final updated = {
        'name': _nameController.text.trim(),
        'guardianName': _guardianNameController.text.trim(),
        'region': _regionController.text.trim(),
      };

      await _apiService.updateUser(userId, updated).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Connection timed out.'),
      );

      MockData.currentUser = MockData.currentUser.copyWith(
        name: updated['name'],
        guardianName: updated['guardianName'],
        region: updated['region'],
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Information'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildLabel('Full Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Enter your name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

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

              _buildLabel('Phone Number'),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _phone,
                enabled: false,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.phone_outlined),
                  helperText: 'Phone number cannot be changed here',
                ),
              ),
              const SizedBox(height: 20),

              _buildLabel('Farm Address / Region'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _regionController,
                textCapitalization: TextCapitalization.words,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Village, Tehsil, District, State',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 36),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
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
}
