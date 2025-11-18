// /lib/features/marketplace/screens/marketplace_photo_picker_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'marketplace_create_form_screen.dart';
import '../../../core/models/marketplace_item.dart';

class MarketplacePhotoPickerScreen extends StatefulWidget {
final MarketplaceItem? itemToEdit;

  const MarketplacePhotoPickerScreen({
    super.key,
    this.itemToEdit,
  });

  @override
  State<MarketplacePhotoPickerScreen> createState() =>
      _MarketplacePhotoPickerScreenState();
}

class _MarketplacePhotoPickerScreenState 
    extends State<MarketplacePhotoPickerScreen> {
  final List<XFile> _selectedPhotos = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  
  static const int _maxPhotos = 3;

  Future<void> _pickPhoto(ImageSource source) async {
    if (_selectedPhotos.length >= _maxPhotos) {
      _showMessage('Máximo de $_maxPhotos fotos permitidas');
      return;
    }

    try {
      setState(() => _isLoading = true);
      
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );

      if (photo != null) {
        // Na web, não há suporte para image_cropper, então usa a imagem diretamente
        if (kIsWeb) {
          setState(() {
            _selectedPhotos.add(photo);
          });
        } else {
          // Em outras plataformas, oferece opção de cortar a imagem
          final croppedFile = await _cropImage(photo.path);
          
          if (croppedFile != null) {
            setState(() {
              _selectedPhotos.add(XFile(croppedFile.path));
            });
          }
        }
      }
    } catch (e) {
      _showMessage('Erro ao selecionar foto: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<CroppedFile?> _cropImage(String imagePath) async {
    // Verifica se não está na web antes de usar image_cropper
    if (kIsWeb) {
      return null;
    }
    
    try {
      return await ImageCropper().cropImage(
        sourcePath: imagePath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Ajustar Imagem',
            toolbarColor: const Color.fromARGB(255, 33, 150, 243),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Ajustar Imagem',
            minimumAspectRatio: 0.5,
          ),
        ],
      );
    } catch (e) {
      // Se houver erro no image_cropper, retorna null para usar a imagem original
      debugPrint('Erro ao cortar imagem: $e');
      return null;
    }
  }

  void _removePhoto(int index) {
    setState(() => _selectedPhotos.removeAt(index));
  }

  void _reorderPhotos(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final photo = _selectedPhotos.removeAt(oldIndex);
      _selectedPhotos.insert(newIndex, photo);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _continuar() {
    if (_selectedPhotos.isEmpty) {
      _showMessage('Adicione pelo menos 1 foto para continuar');
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MarketplaceCreateFormScreen(
          photos: _selectedPhotos,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAddMore = _selectedPhotos.length < _maxPhotos;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Selecionar Fotos'),
        actions: [
          if (_selectedPhotos.isNotEmpty)
            TextButton(
              onPressed: _continuar,
              child: const Text(
                'Avançar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Informações
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.primaryColor.withAlpha(20),
              border: Border(
                bottom: BorderSide(
                  color: theme.primaryColor.withAlpha(50),
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Adicione de 1 a 3 fotos do item',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'A primeira foto será a capa do anúncio',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),

          // Grid de fotos selecionadas
          if (_selectedPhotos.isNotEmpty)
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _selectedPhotos.length,
                onReorder: _reorderPhotos,
                itemBuilder: (context, index) {
                  return _buildPhotoCard(index, theme);
                },
              ),
            )
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhuma foto selecionada',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toque nos botões abaixo para adicionar',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Botões de ação
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Contador de fotos
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_selectedPhotos.length} / $_maxPhotos fotos',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      // Botão câmera
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: canAddMore && !_isLoading
                              ? () => _pickPhoto(ImageSource.camera)
                              : null,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Câmera'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Botão galeria
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: canAddMore && !_isLoading
                              ? () => _pickPhoto(ImageSource.gallery)
                              : null,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Galeria'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(int index, ThemeData theme) {
    final photo = _selectedPhotos[index];
    final isPrimary = index == 0;

    return Container(
      key: ValueKey(photo.path),
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isPrimary
              ? BorderSide(color: theme.primaryColor, width: 2)
              : BorderSide.none,
        ),
        child: Stack(
          children: [
            // Imagem
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: FutureBuilder<Uint8List>(
                  future: photo.readAsBytes(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, size: 48),
                      );
                    }
                    return Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
            ),

            // Badge "Principal"
            if (isPrimary)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Foto Principal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Botão remover
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => _removePhoto(index),
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ),

            // Indicador de reordenação
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(150),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.drag_handle, color: Colors.white, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}