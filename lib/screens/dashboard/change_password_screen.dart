import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/mock_data.dart';
import '../../theme/app_colors.dart';

/// Lets the farmer change their account password. Requires the current
/// password; the backend verifies it before applying the new one.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _apiService
          .changePassword(
            userId: MockData.currentUser.id,
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Connection timed out.'),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildLabel('Current Password'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                decoration: InputDecoration(
                  hintText: 'Enter current password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrent ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              _buildLabel('New Password'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Create a new password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
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
              const SizedBox(height: 20),

              _buildLabel('Confirm New Password'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  hintText: 'Re-enter new password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (val) {
                  if (val != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 36),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Update Password'),
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

  Widget _buildPasswordChecklist() {
    final password = _newPasswordController.text;
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
}
