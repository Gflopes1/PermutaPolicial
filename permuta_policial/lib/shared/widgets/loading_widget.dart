// /lib/shared/widgets/loading_widget.dart

import 'package:flutter/material.dart';
import 'package:permuta_policial/core/constants/app_constants.dart';

/// Widget reutilizável para exibir estados de carregamento
class LoadingWidget extends StatelessWidget {
  final String? message;
  final bool compact;

  const LoadingWidget({
    super.key,
    this.message,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMD),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(height: AppConstants.spacingSM),
                Text(
                  message!,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: AppConstants.spacingMD),
            Text(
              message ?? 'Carregando...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

