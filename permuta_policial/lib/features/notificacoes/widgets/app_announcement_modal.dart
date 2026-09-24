import 'package:flutter/material.dart';

import '../../../core/services/announcement_service.dart';

class AppAnnouncementModal extends StatelessWidget {
  final AnnouncementCampaign campaign;
  final VoidCallback onPrimary;
  final VoidCallback? onSecondary;
  final VoidCallback? onShare;

  const AppAnnouncementModal({
    super.key,
    required this.campaign,
    required this.onPrimary,
    this.onSecondary,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            campaign.primaryAction == 'referral' ? Icons.people_outline : Icons.campaign_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(campaign.title)),
        ],
      ),
      content: SingleChildScrollView(
        child: Text(
          campaign.description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      actions: [
        if (campaign.showShare && onShare != null)
          TextButton(
            onPressed: onShare,
            child: const Text('Compartilhar agora'),
          ),
        if (campaign.secondaryLabel != null && onSecondary != null)
          TextButton(
            onPressed: onSecondary,
            child: Text(campaign.secondaryLabel!),
          ),
        FilledButton(
          onPressed: onPrimary,
          child: Text(campaign.primaryLabel ?? 'OK'),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
