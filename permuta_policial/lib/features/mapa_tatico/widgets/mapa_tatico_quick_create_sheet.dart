import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

import 'package:image_picker/image_picker.dart';

import 'package:provider/provider.dart';



import '../../../core/config/app_styles.dart';

import '../providers/mapa_tatico_provider.dart';

import '../utils/mapa_tatico_marker_utils.dart';
import '../utils/mapa_tatico_photo_upload.dart';

import '../utils/mapa_tatico_type_constants.dart';



class MapaTaticoQuickCreateSheet extends StatefulWidget {

  final double lat;

  final double lng;

  final String mapType;



  const MapaTaticoQuickCreateSheet({

    super.key,

    required this.lat,

    required this.lng,

    required this.mapType,

  });



  @override

  State<MapaTaticoQuickCreateSheet> createState() => _MapaTaticoQuickCreateSheetState();

}



class _MapaTaticoQuickCreateSheetState extends State<MapaTaticoQuickCreateSheet> {

  final _titleController = TextEditingController();

  late String _selectedType;

  XFile? _photo;

  bool _isSaving = false;



  @override

  void initState() {

    super.initState();

    final types = creatableTypesForTab(widget.mapType);

    _selectedType = types.first;

  }



  List<String> get _types => creatableTypesForTab(widget.mapType);



  String get _tabLabel {

    switch (widget.mapType) {

      case 'LOGISTICS':

        return 'Logística';

      case 'NATIONAL':

        return 'Nacional';

      default:

        return 'Operacional';

    }

  }



  Future<String?> _reverseGeocode(MapaTaticoProvider provider) async {

    return provider.geocodeReverse(widget.lat, widget.lng);

  }



  Future<void> _pickPhoto(ImageSource source) async {

    final file = await ImagePicker().pickImage(source: source, imageQuality: 85);

    if (file != null) setState(() => _photo = file);

  }



  Future<void> _save() async {

    final title = _titleController.text.trim();

    if (title.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(

        AppStyles.errorSnackBar('Informe um título.'),

      );

      return;

    }



    setState(() => _isSaving = true);

    final provider = context.read<MapaTaticoProvider>();

    final address = await _reverseGeocode(provider);



    http.MultipartFile? photoFile;

    if (_photo != null) {

      if (!provider.photoUploadEnabled) {

        if (mounted) {

          ScaffoldMessenger.of(context).showSnackBar(

            AppStyles.errorSnackBar('Upload de fotos indisponível. Crie sem foto.'),

          );

          setState(() => _isSaving = false);

        }

        return;

      }

      final bytes = await _photo!.readAsBytes();

      photoFile = buildMapaTaticoPhotoMultipart(bytes, filename: _photo!.name);

    }



    DateTime? expiresAt;

    if (_selectedType == 'ocorrencia_recente') {

      expiresAt = DateTime.now().add(const Duration(days: 7));

    }



    final point = await provider.createPoint(

      title: title,

      address: address,

      lat: widget.lat,

      lng: widget.lng,

      type: _selectedType,

      mapType: widget.mapType,

      expiresAt: expiresAt,

      photo: photoFile,

    );



    if (!mounted) return;

    setState(() => _isSaving = false);



    if (point != null) {

      Navigator.pop(context, point);

      ScaffoldMessenger.of(context).showSnackBar(

        AppStyles.successSnackBar('Ponto criado!'),

      );



      if (widget.mapType == 'OPERATIONAL') {

        final nearby = provider.logisticsNear(widget.lat, widget.lng);

        if (nearby.isNotEmpty) {

          ScaffoldMessenger.of(context).showSnackBar(

            SnackBar(

              content: Text(

                '${nearby.length} ponto(s) logístico(s) a até 500 m deste local.',

              ),

              action: SnackBarAction(

                label: 'OK',

                onPressed: () {},

              ),

            ),

          );

        }

      }

    }

  }



  @override

  Widget build(BuildContext context) {

    return Padding(

      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),

      child: SafeArea(

        child: SingleChildScrollView(

          padding: const EdgeInsets.all(16),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.stretch,

            mainAxisSize: MainAxisSize.min,

            children: [

              Text(

                'Novo ponto — $_tabLabel',

                style: Theme.of(context).textTheme.titleLarge,

              ),

              Text(

                '${widget.lat.toStringAsFixed(5)}, ${widget.lng.toStringAsFixed(5)}',

                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),

              ),

              const SizedBox(height: 12),

              TextField(

                controller: _titleController,

                autofocus: true,

                decoration: const InputDecoration(

                  labelText: 'Título',

                  border: OutlineInputBorder(),

                ),

              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(

                initialValue: _selectedType,

                decoration: const InputDecoration(

                  labelText: 'Tipo',

                  border: OutlineInputBorder(),

                ),

                items: _types

                    .map((t) => DropdownMenuItem(value: t, child: Text(pointTypeLabel(t))))

                    .toList(),

                onChanged: (v) {

                  if (v != null) setState(() => _selectedType = v);

                },

              ),

              const SizedBox(height: 12),

              Row(

                children: [

                  Expanded(

                    child: OutlinedButton.icon(

                      onPressed: _isSaving ? null : () => _pickPhoto(ImageSource.camera),

                      icon: const Icon(Icons.photo_camera),

                      label: const Text('Câmera'),

                    ),

                  ),

                  const SizedBox(width: 8),

                  Expanded(

                    child: OutlinedButton.icon(

                      onPressed: _isSaving ? null : () => _pickPhoto(ImageSource.gallery),

                      icon: const Icon(Icons.photo_library),

                      label: const Text('Galeria'),

                    ),

                  ),

                ],

              ),

              if (_photo != null)

                Padding(

                  padding: const EdgeInsets.only(top: 8),

                  child: Text('Foto: ${_photo!.name}', style: const TextStyle(fontSize: 12)),

                ),

              const SizedBox(height: 16),

              FilledButton(

                onPressed: _isSaving ? null : _save,

                child: _isSaving

                    ? const SizedBox(

                        height: 20,

                        width: 20,

                        child: CircularProgressIndicator(strokeWidth: 2),

                      )

                    : const Text('Salvar ponto'),

              ),

            ],

          ),

        ),

      ),

    );

  }

}


