// /lib/features/calendar/screens/calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/calendar_provider.dart';
import '../widgets/day_modal.dart';
import '../widgets/preset_palette.dart';
import '../widgets/salary_preview_panel.dart';
import '../widgets/simple_calendar.dart';
import '../widgets/calendar_manual.dart';
import '../../../core/models/salary.dart';
import '../../../core/models/preset.dart';
import '../../../core/models/work_day.dart';
import '../../../core/utils/error_handler.dart';
import '../../../shared/widgets/app_bar_helper.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _isMultiSelectMode = false;
  final Set<DateTime> _selectedDates = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      CalendarManual.showIfNeeded(context);
    });
  }

  void _loadData() {
    final provider = Provider.of<CalendarProvider>(context, listen: false);
    provider.loadMonth(_focusedDay.month, _focusedDay.year);
    provider.loadPresets();
    provider.loadSalarySettings();
  }

  void _exitMultiSelect() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedDates.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          _isMultiSelectMode
              ? '${_selectedDates.length} dia(s) selecionado(s)'
              : 'Gestor de Horas',
        ),
        leading: _isMultiSelectMode
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Cancelar seleção',
                onPressed: _exitMultiSelect,
              )
            : null,
        actions: [
          if (!_isMultiSelectMode) ...[
            IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: 'Como usar',
              onPressed: () => CalendarManual.show(context),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Configurações de soldo',
              onPressed: () => _showSettingsDialog(context),
            ),
            ...AppBarHelper.adicionarBotaoRelatarProblema(context),
          ],
        ],
      ),
      body: Consumer<CalendarProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.getWorkDay(_selectedDay) == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              if (provider.errorMessage != null)
                MaterialBanner(
                  content: Text(provider.errorMessage!),
                  leading: const Icon(Icons.error_outline, color: Colors.orange),
                  actions: [
                    TextButton(
                      onPressed: () => _loadData(),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              if (_isMultiSelectMode)
                Material(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Toque nos dias do calendário. Depois use "Aplicar tipo".',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        FilledButton.tonal(
                          onPressed: _selectedDates.isEmpty
                              ? null
                              : () => _applyBulkPreset(context),
                          child: const Text('Aplicar tipo'),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildCalendar(provider),
                    ),
                    if (MediaQuery.of(context).size.width > 800)
                      Container(
                        width: 350,
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                        ),
                        child: SalaryPreviewPanel(
                          month: _focusedDay.month,
                          year: _focusedDay.year,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return SafeArea(
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _BottomAction(
              icon: Icons.summarize_outlined,
              label: 'Resumo',
              onTap: () => _showSummaryDialog(context),
            ),
            _BottomAction(
              icon: Icons.palette_outlined,
              label: 'Tipos',
              onTap: () => _showPresetPalette(context),
            ),
            _BottomAction(
              icon: _isMultiSelectMode ? Icons.check_circle : Icons.checklist,
              label: _isMultiSelectMode ? 'Selecionando' : 'Selecionar',
              selected: _isMultiSelectMode,
              onTap: () {
                if (_isMultiSelectMode) {
                  if (_selectedDates.isNotEmpty) {
                    _applyBulkPreset(context);
                  }
                } else {
                  setState(() => _isMultiSelectMode = true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(CalendarProvider provider) {
    return Column(
      children: [
        _buildLegend(provider),
        _buildCalendarHeader(provider),
        Expanded(
          child: SimpleCalendar(
            focusedDay: _focusedDay,
            selectedDay: _selectedDay,
            isMultiSelectMode: _isMultiSelectMode,
            multiSelectedDays: _selectedDates,
            onDaySelected: (day) {
              if (_isMultiSelectMode) {
                setState(() {
                  final existing = _selectedDates.firstWhere(
                    (d) => d.year == day.year && d.month == day.month && d.day == day.day,
                    orElse: () => DateTime(0),
                  );
                  if (existing.year != 0) {
                    _selectedDates.remove(existing);
                  } else {
                    _selectedDates.add(day);
                  }
                });
              } else {
                setState(() {
                  _selectedDay = day;
                  _focusedDay = day;
                });
                _openDayModal(day);
              }
            },
            onPageChanged: (day) {
              setState(() => _focusedDay = day);
              provider.loadMonth(day.month, day.year);
            },
            onDayLongPress: (day) {
              if (!_isMultiSelectMode) {
                setState(() {
                  _isMultiSelectMode = true;
                  _selectedDates
                    ..clear()
                    ..add(day);
                });
              }
            },
            getWorkDay: (day) => provider.getWorkDay(day),
          ),
        ),
        if (provider.isSaving)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.blue.withAlpha(25),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Salvando alterações...'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCalendarHeader(CalendarProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              final prevMonth = DateTime(_focusedDay.year, _focusedDay.month - 1);
              setState(() => _focusedDay = prevMonth);
              provider.loadMonth(prevMonth.month, prevMonth.year);
            },
          ),
          Text(
            '${_getMonthName(_focusedDay.month)} ${_focusedDay.year}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              final nextMonth = DateTime(_focusedDay.year, _focusedDay.month + 1);
              setState(() => _focusedDay = nextMonth);
              provider.loadMonth(nextMonth.month, nextMonth.year);
            },
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
    ];
    return months[month - 1];
  }

  Widget _buildLegend(CalendarProvider provider) {
    if (provider.presets.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: provider.presets.map((preset) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(int.parse(preset.cor.replaceFirst('#', '0xFF'))),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(preset.nome, style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _openDayModal(DateTime day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DayModal(day: day),
    );
  }

  void _showPresetPalette(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PresetPalette(),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _SettingsDialog(),
    );
  }

  Future<void> _applyBulkPreset(BuildContext context) async {
    if (_selectedDates.isEmpty) return;

    final preset = await showDialog<Preset>(
      context: context,
      builder: (context) => const PresetPalette(selectMode: true),
    );

    if (preset == null || preset.id == null || !mounted) return;

    final provider = Provider.of<CalendarProvider>(context, listen: false);
    final selectedCount = _selectedDates.length;
    final datesToApply = _selectedDates.map(WorkDay.toDateOnly).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      await provider.applyPresetToDays(datesToApply, preset.id!);
      if (!mounted) return;
      Navigator.of(context).pop();
      _exitMultiSelect();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${preset.nome} aplicado em $selectedCount dia(s)!')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.getErrorMessage(e)),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _showSummaryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            maxWidth: MediaQuery.of(context).size.width * 0.95,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Resumo — ${_getMonthName(_focusedDay.month)}/${_focusedDay.year}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SalaryPreviewPanel(
                  month: _focusedDay.month,
                  year: _focusedDay.year,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog();

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late TextEditingController _cargaHorariaController;
  late TextEditingController _valorHoraExtraController;
  late TextEditingController _valeAlimentacaoController;
  late TextEditingController _diaPagamentoVaController;
  late TextEditingController _etapaValueController;
  late TextEditingController _previdenciaAliquotaController;
  late TextEditingController _abatimentoHorasController;
  late TextEditingController _salarioBaseController;
  late TextEditingController _descontoConsignadosController;
  late TextEditingController _outrosDescontosController;
  late TextEditingController _outrasVantagensController;

  String _etapaRule = 'per_6h';
  bool _isLoading = false;
  bool _hasChanges = false;
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<CalendarProvider>(context, listen: false);
    final settings = provider.salarySettings ?? SalarySettings();

    _cargaHorariaController = TextEditingController(text: settings.cargaHorariaDia.toString());
    _valorHoraExtraController = TextEditingController(text: settings.valorHoraExtra.toString());
    _valeAlimentacaoController = TextEditingController(text: settings.valeAlimentacao.toString());
    _diaPagamentoVaController = TextEditingController(text: settings.diaPagamentoVa.toString());
    _etapaValueController = TextEditingController(text: settings.etapaValue.toString());
    _previdenciaAliquotaController = TextEditingController(text: settings.previdenciaAliquota.toString());
    _abatimentoHorasController = TextEditingController(text: settings.abatimentoHoras.toString());
    _salarioBaseController = TextEditingController(text: settings.salarioBase.toString());
    _descontoConsignadosController = TextEditingController(
      text: settings.descontoConsignados?.toString() ?? '',
    );
    _outrosDescontosController = TextEditingController(
      text: settings.outrosDescontos.toString(),
    );
    _outrasVantagensController = TextEditingController(
      text: settings.outrasVantagens.toString(),
    );
    _etapaRule = settings.etapaRule;

    for (final c in [
      _cargaHorariaController,
      _valorHoraExtraController,
      _valeAlimentacaoController,
      _diaPagamentoVaController,
      _etapaValueController,
      _previdenciaAliquotaController,
      _abatimentoHorasController,
      _salarioBaseController,
      _descontoConsignadosController,
      _outrosDescontosController,
      _outrasVantagensController,
    ]) {
      c.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 1), () {
      if (_hasChanges && !_isLoading) _saveSettings(silent: true);
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _cargaHorariaController.dispose();
    _valorHoraExtraController.dispose();
    _valeAlimentacaoController.dispose();
    _diaPagamentoVaController.dispose();
    _etapaValueController.dispose();
    _previdenciaAliquotaController.dispose();
    _abatimentoHorasController.dispose();
    _salarioBaseController.dispose();
    _descontoConsignadosController.dispose();
    _outrosDescontosController.dispose();
    _outrasVantagensController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings({bool silent = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final settings = SalarySettings(
        id: Provider.of<CalendarProvider>(context, listen: false).salarySettings?.id,
        cargaHorariaDia: double.tryParse(_cargaHorariaController.text) ?? 5.7,
        valorHoraExtra: double.tryParse(_valorHoraExtraController.text) ?? 44.0,
        valeAlimentacao: double.tryParse(_valeAlimentacaoController.text) ?? 426.0,
        diaPagamentoVa: int.tryParse(_diaPagamentoVaController.text) ?? 20,
        etapaValue: double.tryParse(_etapaValueController.text) ?? 11.0,
        previdenciaAliquota: double.tryParse(_previdenciaAliquotaController.text) ?? 0.14,
        etapaRule: _etapaRule,
        abatimentoHoras: double.tryParse(_abatimentoHorasController.text) ?? 5.7,
        salarioBase: double.tryParse(_salarioBaseController.text) ?? 0.0,
        descontoConsignados: _descontoConsignadosController.text.isEmpty
            ? null
            : double.tryParse(_descontoConsignadosController.text),
        outrosDescontos: double.tryParse(_outrosDescontosController.text) ?? 0.0,
        outrasVantagens: double.tryParse(_outrasVantagensController.text) ?? 0.0,
      );

      await Provider.of<CalendarProvider>(context, listen: false).updateSalarySettings(settings);

      if (mounted) {
        setState(() => _hasChanges = false);
        if (!silent) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Configurações salvas!')),
          );
        }
      }
    } catch (e) {
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: mediaQuery.size.height * 0.9,
            maxWidth: mediaQuery.size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Configurações de Soldo',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _salarioBaseController,
                        decoration: const InputDecoration(
                          labelText: 'Salário Base (R\$)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cargaHorariaController,
                        decoration: const InputDecoration(
                          labelText: 'Carga Horária Diária (h)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _valorHoraExtraController,
                        decoration: const InputDecoration(
                          labelText: 'Valor Hora Extra (R\$)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _valeAlimentacaoController,
                        decoration: const InputDecoration(
                          labelText: 'Vale Alimentação (R\$)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _diaPagamentoVaController,
                        decoration: const InputDecoration(
                          labelText: 'Dia de Pagamento do VA',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _etapaValueController,
                        decoration: const InputDecoration(
                          labelText: 'Valor da Etapa (R\$)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _etapaRule,
                        decoration: const InputDecoration(
                          labelText: 'Regra de Etapa',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'per_6h', child: Text('Por 6 horas')),
                          DropdownMenuItem(value: 'per_day', child: Text('Por dia')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _etapaRule = value ?? 'per_6h';
                            _hasChanges = true;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _previdenciaAliquotaController,
                        decoration: const InputDecoration(
                          labelText: 'Alíquota Previdência (ex: 0.14)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _abatimentoHorasController,
                        decoration: const InputDecoration(
                          labelText: 'Horas de Abatimento',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descontoConsignadosController,
                        decoration: const InputDecoration(
                          labelText: 'Desconto Consignados (R\$)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _outrosDescontosController,
                        decoration: const InputDecoration(
                          labelText: 'Outros Descontos (R\$)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _outrasVantagensController,
                        decoration: const InputDecoration(
                          labelText: 'Outras Vantagens (R\$)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Fechar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : () => _saveSettings(silent: false),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Salvar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
