import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permuta_policial/core/config/app_styles.dart';
import 'package:permuta_policial/core/config/app_theme.dart';

/// Layout comum das telas de autenticação (card + footer).
class AuthScaffold extends StatelessWidget {
  final Widget child;
  final bool resizeToAvoidBottomInset;

  const AuthScaffold({
    super.key,
    required this.child,
    this.resizeToAvoidBottomInset = true,
  });

  Future<void> _launchURL(String url) async {
    await launchUrl(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return AppStyles.gradientScaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Card(
                    elevation: 8,
                    color: AppTheme.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppStyles.borderRadiusMD),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: child,
                    ),
                  ),
                  AppStyles.spacingMedium,
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            TextButton(
              onPressed: () => _launchURL('https://br.permutapolicial.com.br/termos.html'),
              child: const Text(
                'Termos de Uso',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
            const Text('|', style: TextStyle(color: Colors.white70)),
            TextButton(
              onPressed: () => _launchURL('https://br.permutapolicial.com.br/privacidade.html'),
              child: const Text(
                'Política de Privacidade',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'contato@permutapolicial.com.br',
          style: TextStyle(
            color: Colors.white70.withAlpha(179),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
