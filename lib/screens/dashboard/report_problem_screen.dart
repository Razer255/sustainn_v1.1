import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/mock_data.dart';
import '../../theme/app_colors.dart';

/// Lets a farmer describe a problem they're facing in the app. Submissions
/// are sent to the backend and reviewed by an admin in the Admin Dashboard.
class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _apiService = ApiService();

  static const int _maxLength = 1000;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final user = MockData.currentUser;
      await _apiService
          .reportIssue(
            userId: user.id,
            userName: user.name,
            userPhone: user.phone,
            message: _messageController.text.trim(),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Connection timed out.'),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thanks — your report has been sent to our team.'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't send report: $message")),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report a Problem'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Tell us what's not working",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Describe the issue you faced — what you were trying to do, '
                'and what went wrong. Our team will review it.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageController,
                maxLines: 8,
                maxLength: _maxLength,
                decoration: const InputDecoration(
                  hintText: 'e.g. "The app crashes when I try to add a crop activity..."',
                  alignLabelWithHint: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please describe the problem';
                  }
                  if (val.trim().length < 10) {
                    return 'Please provide a bit more detail';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(_isSubmitting ? 'Sending...' : 'Submit Report'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
