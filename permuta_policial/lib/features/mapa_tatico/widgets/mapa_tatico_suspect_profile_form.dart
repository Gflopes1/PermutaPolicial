import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/map_suspect_profile.dart';

class MapaTaticoSuspectProfileFormData {
  String? apelido;
  String? caracteristicasFisicas;
  int? alturaCm;
  String? compleicao;
  String? tatuagensMarcas;
  String? veiculosAssociados;
  String? modusOperandi;
  String nivelPericulosidade = 'BAIXO';
  String? orientacoesAbordagem;
  String? boRaiNumero;
  String fundamentacao = '';

  Map<String, dynamic> toJson() => {
        'apelido': apelido?.trim().isEmpty == true ? null : apelido?.trim(),
        'caracteristicas_fisicas':
            caracteristicasFisicas?.trim().isEmpty == true ? null : caracteristicasFisicas?.trim(),
        'altura_cm': alturaCm,
        'compleicao': compleicao,
        'tatuagens_marcas': tatuagensMarcas?.trim().isEmpty == true ? null : tatuagensMarcas?.trim(),
        'veiculos_associados':
            veiculosAssociados?.trim().isEmpty == true ? null : veiculosAssociados?.trim(),
        'modus_operandi': modusOperandi?.trim().isEmpty == true ? null : modusOperandi?.trim(),
        'nivel_periculosidade': nivelPericulosidade,
        'orientacoes_abordagem':
            orientacoesAbordagem?.trim().isEmpty == true ? null : orientacoesAbordagem?.trim(),
        'bo_rai_numero': boRaiNumero?.trim().isEmpty == true ? null : boRaiNumero?.trim(),
        'fundamentacao': fundamentacao.trim(),
      };

  void applyFromProfile(MapSuspectProfile profile) {
    apelido = profile.apelido;
    caracteristicasFisicas = profile.caracteristicasFisicas;
    alturaCm = profile.alturaCm;
    compleicao = profile.compleicao;
    tatuagensMarcas = profile.tatuagensMarcas;
    veiculosAssociados = profile.veiculosAssociados;
    modusOperandi = profile.modusOperandi;
    nivelPericulosidade = profile.nivelPericulosidade;
    orientacoesAbordagem = profile.orientacoesAbordagem;
    boRaiNumero = profile.boRaiNumero;
    fundamentacao = profile.fundamentacao;
  }
}

Color periculosidadeColor(String nivel) {
  switch (nivel) {
    case 'MEDIO':
      return Colors.amber.shade700;
    case 'ALTO':
      return Colors.orange.shade800;
    case 'ARMADO':
      return Colors.red.shade700;
    default:
      return Colors.grey.shade600;
  }
}

String periculosidadeLabel(String nivel) {
  switch (nivel) {
    case 'MEDIO':
      return 'Médio';
    case 'ALTO':
      return 'Alto';
    case 'ARMADO':
      return 'Armado';
    default:
      return 'Baixo';
  }
}

class MapaTaticoSuspectProfileForm extends StatefulWidget {
  final MapaTaticoSuspectProfileFormData data;
  final bool readOnly;

  const MapaTaticoSuspectProfileForm({
    super.key,
    required this.data,
    this.readOnly = false,
  });

  @override
  State<MapaTaticoSuspectProfileForm> createState() => _MapaTaticoSuspectProfileFormState();
}

class _MapaTaticoSuspectProfileFormState extends State<MapaTaticoSuspectProfileForm> {
  late final TextEditingController _apelidoController;
  late final TextEditingController _caracteristicasController;
  late final TextEditingController _alturaController;
  late final TextEditingController _tatuagensController;
  late final TextEditingController _veiculosController;
  late final TextEditingController _modusController;
  late final TextEditingController _orientacoesController;
  late final TextEditingController _boController;
  late final TextEditingController _fundamentacaoController;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _apelidoController = TextEditingController(text: d.apelido ?? '');
    _caracteristicasController = TextEditingController(text: d.caracteristicasFisicas ?? '');
    _alturaController = TextEditingController(text: d.alturaCm?.toString() ?? '');
    _tatuagensController = TextEditingController(text: d.tatuagensMarcas ?? '');
    _veiculosController = TextEditingController(text: d.veiculosAssociados ?? '');
    _modusController = TextEditingController(text: d.modusOperandi ?? '');
    _orientacoesController = TextEditingController(text: d.orientacoesAbordagem ?? '');
    _boController = TextEditingController(text: d.boRaiNumero ?? '');
    _fundamentacaoController = TextEditingController(text: d.fundamentacao);
  }

  @override
  void dispose() {
    _apelidoController.dispose();
    _caracteristicasController.dispose();
    _alturaController.dispose();
    _tatuagensController.dispose();
    _veiculosController.dispose();
    _modusController.dispose();
    _orientacoesController.dispose();
    _boController.dispose();
    _fundamentacaoController.dispose();
    super.dispose();
  }

  void _syncToData() {
    final d = widget.data;
    d.apelido = _apelidoController.text;
    d.caracteristicasFisicas = _caracteristicasController.text;
    d.alturaCm = int.tryParse(_alturaController.text.trim());
    d.tatuagensMarcas = _tatuagensController.text;
    d.veiculosAssociados = _veiculosController.text;
    d.modusOperandi = _modusController.text;
    d.orientacoesAbordagem = _orientacoesController.text;
    d.boRaiNumero = _boController.text;
    d.fundamentacao = _fundamentacaoController.text;
  }

  @override
  Widget build(BuildContext context) {
    final readOnly = widget.readOnly;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _apelidoController,
          readOnly: readOnly,
          decoration: const InputDecoration(
            labelText: 'Apelido',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _syncToData(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _caracteristicasController,
          readOnly: readOnly,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Características físicas',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _syncToData(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _alturaController,
                readOnly: readOnly,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Altura (cm)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _syncToData(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: widget.data.compleicao,
                decoration: const InputDecoration(
                  labelText: 'Compleição',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'MAGRA', child: Text('Magra')),
                  DropdownMenuItem(value: 'MEDIA', child: Text('Média')),
                  DropdownMenuItem(value: 'FORTE', child: Text('Forte')),
                ],
                onChanged: readOnly
                    ? null
                    : (v) => setState(() {
                          widget.data.compleicao = v;
                          _syncToData();
                        }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _tatuagensController,
          readOnly: readOnly,
          minLines: 2,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Tatuagens / marcas',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _syncToData(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _veiculosController,
          readOnly: readOnly,
          minLines: 1,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Veículos associados',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _syncToData(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _modusController,
          readOnly: readOnly,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Modus operandi',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _syncToData(),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: widget.data.nivelPericulosidade,
          decoration: InputDecoration(
            labelText: 'Nível de periculosidade',
            border: const OutlineInputBorder(),
            prefixIcon: Icon(
              Icons.warning_amber,
              color: periculosidadeColor(widget.data.nivelPericulosidade),
            ),
          ),
          items: ['BAIXO', 'MEDIO', 'ALTO', 'ARMADO']
              .map(
                (n) => DropdownMenuItem(
                  value: n,
                  child: Text(
                    periculosidadeLabel(n),
                    style: TextStyle(color: periculosidadeColor(n), fontWeight: FontWeight.w600),
                  ),
                ),
              )
              .toList(),
          onChanged: readOnly
              ? null
              : (v) => setState(() {
                    if (v != null) widget.data.nivelPericulosidade = v;
                    _syncToData();
                  }),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _orientacoesController,
          readOnly: readOnly,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Orientações de abordagem',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _syncToData(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _boController,
          readOnly: readOnly,
          decoration: const InputDecoration(
            labelText: 'BO / RAI (recomendado)',
            helperText: 'Preencher quando houver registro formal aumenta a confiabilidade.',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _syncToData(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _fundamentacaoController,
          readOnly: readOnly,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'Fundamentação *',
            helperText: 'Explique por que esta pessoa está sendo cadastrada (mín. 20 caracteres).',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _syncToData(),
        ),
      ],
    );
  }
}
