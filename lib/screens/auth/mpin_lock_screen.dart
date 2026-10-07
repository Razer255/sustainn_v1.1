import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../routes/app_router.dart';
import '../../theme/app_colors.dart';

class MpinLockScreen extends StatefulWidget {
  const MpinLockScreen({super.key});

  @override
  State<MpinLockScreen> createState() => _MpinLockScreenState();
}

class _MpinLockScreenState extends State<MpinLockScreen> {
  String _enteredPin = '';
  bool _hasError = false;

  void _onKeyPress(String value) {
    if (_enteredPin.length < 6) {
      setState(() {
        _enteredPin += value;
        _hasError = false;
      });
      if (_enteredPin.length >= 4) {
        // Automatically check if it matches
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _hasError = false;
      });
    }
  }

  Future<void> _verifyPin() async {
    final prefsBox = await Hive.openBox('prefs');
    final storedPin = prefsBox.get('mpin');

    if (_enteredPin == storedPin) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRouter.dashboard);
      }
    } else {
      // If the length reached the stored PIN length (assuming it's either 4 or 6, check accordingly)
      // For simplicity, let's just trigger error if it reaches max length or user presses a button.
      // Wait, let's just use a submit button or auto-submit when length matches stored length.
      if (storedPin != null && _enteredPin.length == storedPin.length) {
        setState(() {
          _hasError = true;
          _enteredPin = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const Icon(Icons.lock_outline, size: 60, color: AppColors.primary),
            const SizedBox(height: 24),
            const Text(
              'Enter MPIN',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (_hasError)
              const Text(
                'Incorrect MPIN. Try again.',
                style: TextStyle(color: Colors.red, fontSize: 14),
              )
            else
              const Text(
                'Enter your secure PIN to access the app',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _enteredPin.length
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                );
              }),
            ),
            const Spacer(),
            _buildKeypad(),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                // To reset MPIN, usually requires OTP again.
                // Navigate to Login screen to re-authenticate
                Navigator.pushReplacementNamed(context, AppRouter.login);
              },
              child: const Text('Forgot MPIN? Login with Phone'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('1'), _buildKey('2'), _buildKey('3'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('4'), _buildKey('5'), _buildKey('6'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('7'), _buildKey('8'), _buildKey('9'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 60), // Empty space
              _buildKey('0'),
              _buildBackspaceKey(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String value) {
    return InkWell(
      onTap: () => _onKeyPress(value),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey() {
    return InkWell(
      onTap: _onBackspace,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        child: const Icon(
          Icons.backspace_outlined,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
