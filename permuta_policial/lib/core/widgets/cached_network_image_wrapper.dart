// /lib/core/widgets/cached_network_image_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/version_service.dart';

/// Widget wrapper para imagens de rede com cache otimizado
/// Usa cached_network_image no mobile e Image.network na web
/// Inclui cache busting automático baseado na versão do app
class CachedNetworkImageWrapper extends StatelessWidget {
  final String imageUrl;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final double? width;
  final double? height;
  final Map<String, String>? httpHeaders;
  final VersionService? versionService;
  final bool useCacheBusting;

  const CachedNetworkImageWrapper({
    super.key,
    required this.imageUrl,
    this.fit,
    this.placeholder,
    this.errorWidget,
    this.width,
    this.height,
    this.httpHeaders,
    this.versionService,
    this.useCacheBusting = true, // Por padrão, usa cache busting
  });

  /// cacheWidth/cacheHeight não aceitam infinity — quebra Image.network na web.
  static int? _safeCacheDimension(double? value) {
    if (value == null || !value.isFinite || value <= 0) return null;
    return value.toInt();
  }

  @override
  Widget build(BuildContext context) {
    // Obtém a URL com cache busting se necessário
    return FutureBuilder<String>(
      future: _getImageUrlWithCacheBusting(),
      builder: (context, snapshot) {
        final finalUrl = snapshot.data ?? imageUrl;
        
        // Na web, usa Image.network com cache do navegador
        if (kIsWeb) {
          return Image.network(
            finalUrl,
            width: width,
            height: height,
            fit: fit ?? BoxFit.cover,
            headers: httpHeaders,
            cacheWidth: _safeCacheDimension(width),
            cacheHeight: _safeCacheDimension(height),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return placeholder ?? 
                Container(
                  width: width,
                  height: height,
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
            },
            errorBuilder: (context, error, stackTrace) {
              return errorWidget ??
                Container(
                  width: width,
                  height: height,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                  ),
                );
            },
          );
        }

        // No mobile, usa cached_network_image para melhor performance
        return CachedNetworkImage(
          imageUrl: finalUrl,
          width: width,
          height: height,
          fit: fit ?? BoxFit.cover,
          httpHeaders: httpHeaders,
          placeholder: (context, url) => 
            placeholder ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          errorWidget: (context, url, error) =>
            errorWidget ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
              ),
            ),
          // Configurações de cache para mobile
          memCacheWidth: _safeCacheDimension(width),
          memCacheHeight: _safeCacheDimension(height),
          maxWidthDiskCache: 1200,
          maxHeightDiskCache: 1200,
        );
      },
    );
  }

  /// Adiciona cache busting à URL se necessário
  Future<String> _getImageUrlWithCacheBusting() async {
    if (!useCacheBusting || imageUrl.isEmpty) {
      return imageUrl;
    }

    // Se não há versionService fornecido, retorna URL original
    if (versionService == null) {
      return imageUrl;
    }

    try {
      return await versionService!.addCacheBustingToUrl(imageUrl);
    } catch (e) {
      debugPrint('Erro ao adicionar cache busting: $e');
      return imageUrl;
    }
  }
}

