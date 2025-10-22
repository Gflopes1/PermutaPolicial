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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          children: [
            Text('Parceiros', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 16),
            
            // Usando o PageView nativo do Flutter
            SizedBox(
              height: 180, // Altura definida para o carrossel
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
                      margin: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                        child: Image.network(
                          parceiro.imagemUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.error);
                          },
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