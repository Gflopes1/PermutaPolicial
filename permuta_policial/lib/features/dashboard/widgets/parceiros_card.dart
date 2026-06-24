// /lib/features/dashboard/widgets/parceiros_card.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/parceiro.dart';

// Este widget agora é um StatefulWidget para controlar a página atual do carrossel
class ParceirosCard extends StatefulWidget {
  final List<Parceiro> parceiros;
  final bool compact;

  const ParceirosCard({
    super.key,
    required this.parceiros,
    this.compact = false,
  });

  @override
  State<ParceirosCard> createState() => _ParceirosCardState();
}

class _ParceirosCardState extends State<ParceirosCard> {
  int _currentPage = 0; // Estado para rastrear a página/imagem atual

  Future<void> _launchURL(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      // Lidar com o erro, se necessário
    }
  }

  // Função auxiliar para construir os pontos indicadores
  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: _currentPage == index ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? Theme.of(context).colorScheme.primary
            : Colors.grey,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.parceiros.isEmpty) {
      return Card(
        margin: widget.compact ? EdgeInsets.zero : null,
        child: Padding(
          padding: EdgeInsets.all(widget.compact ? 12.0 : 16.0),
          child: Center(
            child: Text(
              'Seja um parceiro — fale conosco',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
                fontSize: widget.compact ? 12 : null,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final carousel = PageView.builder(
      itemCount: widget.parceiros.length,
      onPageChanged: (int page) {
        setState(() {
          _currentPage = page;
        });
      },
      itemBuilder: (context, index) {
        final parceiro = widget.parceiros[index];
        return GestureDetector(
          onTap: () {
            if (parceiro.linkUrl != null && parceiro.linkUrl!.isNotEmpty) {
              _launchURL(parceiro.linkUrl!);
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: parceiro.linkUrl != null && parceiro.linkUrl!.isNotEmpty
                    ? Theme.of(context).primaryColor.withAlpha(30)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                parceiro.imagemUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    if (widget.compact) {
      return Card(
        margin: EdgeInsets.zero,
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.business, color: Theme.of(context).primaryColor, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Parceiros',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(child: carousel),
              if (widget.parceiros.length > 1) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.parceiros.length, (index) => _buildDot(index)),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Nossos Parceiros',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              height: 200,
              child: carousel,
            ),
            
            const SizedBox(height: 12),

            // Adicionando os pontos indicadores
            if (widget.parceiros.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.parceiros.length, (index) => _buildDot(index)),
              ),
          ],
        ),
      ),
    );
  }
}