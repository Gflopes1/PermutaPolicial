import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_router.dart';
import '../providers/referral_provider.dart';

class ReferralDashboardCard extends StatelessWidget {
  const ReferralDashboardCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReferralProvider>(
      builder: (context, provider, _) {
        final data = provider.data;
        if (provider.isLoading && data == null) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (data == null) return const SizedBox.shrink();

        final verified = data.verifiedCount;
        final pending = data.pendingCount;
        final remaining = data.remainingToNext;

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Material(
            color: const Color(0xFF1C1F28),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push(AppRoutes.referral),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2D36)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people_outline, color: Color(0xFF4A90D9), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Convide seus colegas',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            verified > 0
                                ? 'Você já trouxe $verified policiais para o Permuta Policial.'
                                : 'Ajude sua força a crescer na plataforma.',
                            style: const TextStyle(color: Color(0x8FFFFFFF), fontSize: 11),
                          ),
                          if (pending > 0)
                            Text(
                              '$pending aguardando verificação',
                              style: const TextStyle(color: Color(0x8FFFFFFF), fontSize: 10),
                            ),
                          if (remaining > 0 && data.nextLevel != null)
                            Text(
                              'Faltam $remaining para ${data.tierLabel == 'Usuário' ? 'Embaixador Bronze' : 'próximo nível'}',
                              style: const TextStyle(color: Color(0xFF4A90D9), fontSize: 10),
                            ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.referral),
                      child: const Text('Convidar', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
