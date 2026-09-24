// lib/features/profile/widgets/section_card.dart

import 'package:flutter/material.dart';

class ProfileSectionCard extends StatelessWidget {
  final String label;
  final Widget? action;
  final List<Widget> children;
  final EdgeInsets? padding;

  const ProfileSectionCard({
    super.key,
    required this.label,
    required this.children,
    this.action,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                if (action != null) action!,
              ],
            ),
          ),
          Padding(
            padding: padding ?? const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileReadField extends StatelessWidget {
  final String label;
  final String value;
  final bool locked;

  const ProfileReadField({
    super.key,
    required this.label,
    required this.value,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),
              if (locked) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
