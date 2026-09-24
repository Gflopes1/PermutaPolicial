import 'package:flutter/material.dart';
import 'package:permuta_policial/core/config/app_theme.dart';
import 'package:permuta_policial/features/auth/utils/auth_validators.dart';

class PasswordStrengthMeter extends StatelessWidget {
  final String password;

  const PasswordStrengthMeter({super.key, required this.password});

  Color _color(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.empty:
        return Colors.grey;
      case PasswordStrength.weak:
        return Colors.redAccent;
      case PasswordStrength.fair:
        return Colors.orange;
      case PasswordStrength.good:
        return Colors.lightGreen;
      case PasswordStrength.strong:
        return AppTheme.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strength = PasswordStrengthHelper.evaluate(password);
    if (strength == PasswordStrength.empty) return const SizedBox.shrink();

    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasLower = RegExp(r'[a-z]').hasMatch(password);
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: PasswordStrengthHelper.progress(strength),
            minHeight: 6,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation(_color(strength)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Força: ${PasswordStrengthHelper.label(strength)}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _color(strength),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Recomendado (opcional): maiúscula, minúscula, número e caractere especial.',
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _chip('A-Z', hasUpper),
            _chip('a-z', hasLower),
            _chip('0-9', hasDigit),
            _chip('!@#', hasSpecial),
          ],
        ),
      ],
    );
  }

  Widget _chip(String label, bool ok) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: ok ? AppTheme.success.withAlpha(40) : Colors.white10,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ok ? AppTheme.success.withAlpha(120) : Colors.white24),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: ok ? AppTheme.success : Colors.white54,
        ),
      ),
    );
  }
}
