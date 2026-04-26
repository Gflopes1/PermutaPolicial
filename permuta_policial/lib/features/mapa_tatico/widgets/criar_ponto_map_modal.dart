import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_styles.dart';
import '../models/address_search_result.dart';
import '../providers/mapa_tatico_provider.dart';
import '../services/location_tracking_service.dart';

class CriarPontoMapModal extends StatefulWidget {
  final int groupId;
  final VoidCallback? onCreated;

  const CriarPontoMapModal({
    super.key,
    required this.groupId,
    this.onCreated,
  });

  @override
  State<CriarPontoMapModal> createState() => _CriarPontoMapModalState();
}

class _CriarPontoMapModalState extends State<CriarPontoMapModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  final _mapController = MapController();
  final LocationTrackingService _locationService = createLocationTrackingService();

  String _selectedType = 'local_interesse';
  String _selectedMapType = 'OPERATIONAL';
  double? _lat;
  double? _lng;
  XFile? _photoFile;
  bool _isLoading = false;
  bool _isSearchingAddress = false;
  String? _errorMessage;
  List<AddressSearchResult> _searchResults = [];
  LatLng _mapCenter = const LatLng(-14.2350, -51.9253);
  double _mapZoom = 4.5;

  static const _operationalTypes = [
    ('ocorrencia_recente', 'Ocorrência Recente'),
    ('suspeito', 'Suspeito'),
    ('local_interesse', 'Local de Interesse'),
  ];

  static const _logisticsTypes = [
    ('restaurante', 'Restaurante'),
    ('padaria', 'Padaria'),
    ('base', 'Base'),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    _locationService.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final hasPermission = await _locationService.ensurePermission();
      if (!hasPermission) {
        setState(() {
          _errorMessage = 'Não foi possível acessar sua localização no momento.';
          _isLoading = false;
        });
        return;
      }

      final pos = await _locationService.getCurrentLocation();
      if (pos == null) {
        setState(() {
          _errorMessage = 'Não foi possível obter sua localização atual.';
          _isLoading = false;
        });
        return;
      }

      await _setSelectedLocation(
        pos.latitude,
        pos.longitude,
        updateAddressFromSystem: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erro ao obter localização: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile != null) {
      setState(() => _photoFile = xFile);
    }
  }

  Future<void> _setSelectedLocation(
    double lat,
    double lng, {
    bool updateAddressFromSystem = false,
    String? addressOverride,
  }) async {
    String? resolvedAddress = addressOverride;
    if (updateAddressFromSystem) {
      resolvedAddress = await _reverseGeocode(lat, lng);
    }

    if (!mounted) return;
    setState(() {
      _lat = lat;
      _lng = lng;
      _mapCenter = LatLng(lat, lng);
      _mapZoom = _mapZoom < 15 ? 15 : _mapZoom;
      _isLoading = false;
      if (resolvedAddress != null && resolvedAddress.trim().isNotEmpty) {
        _addressController.text = resolvedAddress;
      }
    });
    _mapController.move(_mapCenter, _mapZoom);
  }

  Future<String?> _reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/reverse',
        {
          'format': 'jsonv2',
          'lat': lat.toString(),
          'lon': lng.toString(),
          'zoom': '18',
          'addressdetails': '1',
        },
      );
      final response = await http.get(
        uri,
        headers: const {
          'Accept': 'application/json',
          'User-Agent': 'PermutaPolicial/1.0',
        },
      );
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return data['display_name'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _searchAddress() async {
    final query = _addressController.text.trim();
    if (query.isEmpty) {
      setState(() => _errorMessage = 'Digite um endereço para buscar.');
      return;
    }

    setState(() {
      _isSearchingAddress = true;
      _errorMessage = null;
      _searchResults = [];
    });

    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {
          'format': 'jsonv2',
          'limit': '5',
          'q': query,
          'countrycodes': 'br',
        },
      );
      final response = await http.get(
        uri,
        headers: const {
          'Accept': 'application/json',
          'User-Agent': 'PermutaPolicial/1.0',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Busca indisponível no momento.');
      }

      final rawList = json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      final results = rawList
          .map((item) => AddressSearchResult.fromJson(item as Map<String, dynamic>))
          .where((item) => item.lat != 0 || item.lng != 0)
          .toList();

      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearchingAddress = false;
        if (results.isEmpty) {
          _errorMessage = 'Nenhum endereço encontrado.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearchingAddress = false;
        _errorMessage = 'Erro ao buscar endereço: $e';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lng == null) {
      setState(() => _errorMessage = 'Selecione o local no mapa, pela busca ou pela sua localização.');
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      final resolvedAddress = await _reverseGeocode(_lat!, _lng!);
      if (resolvedAddress != null && resolvedAddress.trim().isNotEmpty) {
        _addressController.text = resolvedAddress;
      }
    }

    if (_addressController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Informe o endereço manualmente ou selecione um local para preenchimento automático.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = context.read<MapaTaticoProvider>();

      http.MultipartFile? photo;
      if (_photoFile != null) {
        final bytes = await _photoFile!.readAsBytes();
        photo = http.MultipartFile.fromBytes(
          'photo',
          bytes,
          filename: _photoFile!.name,
        );
      }

      DateTime? expiresAt;
      if (_selectedType == 'ocorrencia_recente') {
        expiresAt = DateTime.now().add(const Duration(days: 7));
      }

      final point = await provider.createPoint(
        title: _titleController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        lat: _lat!,
        lng: _lng!,
        type: _selectedType,
        mapType: _selectedMapType,
        expiresAt: expiresAt,
        photo: photo,
      );

      if (point != null && mounted) {
        Navigator.pop(context);
        widget.onCreated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          AppStyles.successSnackBar('Ponto criado com sucesso!'),
        );
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = provider.errorMessage ?? 'Erro ao criar ponto.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.94,
      maxChildSize: 0.98,
      minChildSize: 0.55,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Novo Ponto',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedMapType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Mapa',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'OPERATIONAL', child: Text('Operacional')),
                        DropdownMenuItem(value: 'LOGISTICS', child: Text('Logístico')),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _selectedMapType = v!;
                          _selectedType = _selectedMapType == 'OPERATIONAL'
                              ? 'local_interesse'
                              : 'restaurante';
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Ponto',
                        border: OutlineInputBorder(),
                      ),
                      items: (_selectedMapType == 'OPERATIONAL' ? _operationalTypes : _logisticsTypes)
                          .map(
                            (t) => DropdownMenuItem(
                              value: t.$1,
                              child: Text(t.$2),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedType = v!),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextFormField(
                      controller: _addressController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Endereço',
                        hintText: 'Digite um endereço, busque ou toque no mapa para preencher.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading || _isSearchingAddress ? null : _searchAddress,
                          icon: _isSearchingAddress
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.search),
                          label: const Text('Buscar endereço'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _useMyLocation,
                          icon: const Icon(Icons.my_location),
                          label: const Text('Usar minha localização'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 250,
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _mapCenter,
                            initialZoom: _mapZoom,
                            minZoom: 3,
                            maxZoom: 18,
                            onTap: (_, point) {
                              _setSelectedLocation(
                                point.latitude,
                                point.longitude,
                                updateAddressFromSystem: true,
                              );
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            ),
                            if (_lat != null && _lng != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(_lat!, _lng!),
                                    width: 44,
                                    height: 44,
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
                                      size: 44,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Toque no mapa para pinar o local do fato.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  if (_lat != null && _lng != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Coordenadas: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                  if (_searchResults.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: _searchResults
                              .map(
                                (result) => ListTile(
                                  leading: const Icon(Icons.place_outlined),
                                  title: Text(
                                    result.displayName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () async {
                                    setState(() => _searchResults = []);
                                    await _setSelectedLocation(
                                      result.lat,
                                      result.lng,
                                      addressOverride: result.displayName,
                                    );
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: OutlinedButton.icon(
                      onPressed: _pickPhoto,
                      icon: const Icon(Icons.photo),
                      label: Text(_photoFile != null ? 'Foto selecionada' : 'Adicionar foto'),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Criar Ponto'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
