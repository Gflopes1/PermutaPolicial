// /lib/features/dashboard/widgets/parceiros_card.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/parceiro.dart';

// Este widget agora é um StatefulWidget para controlar a página atual do carrossel
class ParceirosCard extends StatefulWidget {
  final List<Parceiro> parceiros;
  const ParceirosCard({super.key, required this.parceiros});

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
      return const SizedBox.shrink();
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
            
            // Usando o PageView nativo do Flutter
            SizedBox(
              height: 200,
              child: PageView.builder(
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
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              parceiro.imagemUrl,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text('Erro ao carregar imagem'),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (parceiro.linkUrl != null && parceiro.linkUrl!.isNotEmpty)
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.open_in_new,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
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