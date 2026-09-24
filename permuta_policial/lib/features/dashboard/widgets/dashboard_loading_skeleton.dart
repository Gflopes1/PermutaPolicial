import 'package:flutter/material.dart';

/// Placeholder visual enquanto o chunk do dashboard carrega — evita tela vazia com spinner.
class DashboardLoadingSkeleton extends StatelessWidget {
  const DashboardLoadingSkeleton({super.key});

  static const _bg = Color(0xFF0F1117);
  static const _card = Color(0xFF1C1F28);
  static const _border = Color(0xFF2A2D36);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _shimmerBox(height: 28, width: 180, radius: 8),
              const SizedBox(height: 20),
              _shimmerBox(height: 120, radius: 16),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _shimmerBox(height: 88, radius: 12)),
                  const SizedBox(width: 12),
                  Expanded(child: _shimmerBox(height: 88, radius: 12)),
                ],
              ),
              const SizedBox(height: 16),
              _shimmerBox(height: 72, radius: 12),
              const SizedBox(height: 12),
              _shimmerBox(height: 72, radius: 12),
              const Spacer(),
              Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox({
    required double height,
    double? width,
    double radius = 8,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _border),
      ),
    );
  }
}
