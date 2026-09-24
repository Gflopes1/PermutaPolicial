import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/referral_provider.dart';
import '../widgets/referral_progress_bar.dart';
import '../widgets/referral_share_buttons.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReferralProvider>().loadMyReferral().then((_) {
        if (mounted) {
          context.read<ReferralProvider>().acknowledgeVerifiedCount();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Indique colegas'),
      ),
      body: Consumer<ReferralProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.data == null) {
            return Center(child: Text(provider.error!));
          }
          final data = provider.data;
          if (data == null) {
            return const Center(child: Text('Não foi possível carregar seus dados.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'O Permuta Policial funciona melhor quando mais policiais da mesma força estão conectados.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                Text('Seu código', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                SelectableText(
                  data.code,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                ),
                const SizedBox(height: 16),
                Text('Seu link', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                SelectableText(
                  data.link.replaceFirst('https://', ''),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ReferralShareButtons(
                  link: data.link,
                  code: data.code,
                  onShared: () => provider.trackShare(),
                ),
                const SizedBox(height: 32),
                Text('Seu progresso', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                ReferralProgressBar(
                  verifiedCount: data.verifiedCount,
                  nextLevel: data.nextLevel,
                  remaining: data.remainingToNext,
                  progress: data.progressToNext,
                  tierLabel: data.tierLabel,
                ),
                if (data.pendingCount > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Pendentes (aguardando confirmação de e-mail): ${data.pendingCount}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
