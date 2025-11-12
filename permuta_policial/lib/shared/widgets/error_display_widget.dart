// /lib/shared/widgets/error_display_widget.dart

import 'package:flutter/material.dart';
import 'package:permuta_policial/core/api/api_exception.dart';
import 'package:permuta_policial/core/utils/error_message_helper.dart';

/// Widget reutilizável para exibir erros de forma consistente
class ErrorDisplayWidget extends StatelessWidget {
  final ApiException? exception;
  final String? customMessage;
  final String? customTitle;
  final VoidCallback? onRetry;
  final IconData? customIcon;
  final bool compact;

  const ErrorDisplayWidget({
    super.key,
    this.exception,
    this.customMessage,
    this.customTitle,
    this.onRetry,
    this.customIcon,
    this.compact = false,
  }) : assert(
          exception != null || customMessage != null,
          'Deve fornecer exception ou customMessage',
        );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = customTitle ??
        (exception != null
            ? ErrorMessageHelper.getErrorTitle(exception!)
            : 'Erro');
    final message = customMessage ??
        (exception != null
            ? ErrorMessageHelper.getFriendlyMessage(exception!)
            : 'Ocorreu um erro inesperado.');
    final canRetry = exception != null
        ? ErrorMessageHelper.canRetry(exception!)
        : (onRetry != null);
    final suggestedAction = exception != null
        ? ErrorMessageHelper.getSuggestedAction(exception!)
        : null;

    if (compact) {
      return _buildCompactError(context, theme, title, message, canRetry);
    }

    return _buildFullError(context, theme, title, message, canRetry, suggestedAction);
  }

  Widget _buildCompactError(
    BuildContext context,
    ThemeData theme,
    String title,
    String message,
    bool canRetry,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withAlpha(30),
        ),
      ),
      child: Row(
        children: [
          Icon(
            customIcon ?? Icons.error_outline,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onErrorContainer,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: theme.colorScheme.onErrorContainer,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (canRetry && onRetry != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: onRetry,
              tooltip: 'Tentar novamente',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFullError(
    BuildContext context,
    ThemeData theme,
    String title,
    String message,
    bool canRetry,
    String? suggestedAction,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              customIcon ?? Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(70),
              ),
            ),
            if (suggestedAction != null) ...[
              const SizedBox(height: 8),
              Text(
                suggestedAction,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(50),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (canRetry && onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar Novamente'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

