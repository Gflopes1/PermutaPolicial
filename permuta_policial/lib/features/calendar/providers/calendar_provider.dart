// /lib/features/calendar/providers/calendar_provider.dart

import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/api/repositories/work_repository.dart';
import '../../../core/api/repositories/presets_repository.dart';
import '../../../core/api/repositories/salary_repository.dart';
import '../../../core/models/work_day.dart';
import '../../../core/models/preset.dart';
import '../../../core/models/salary.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/salary_calculator.dart';

class CalendarProvider with ChangeNotifier {
  final WorkRepository _workRepository;
  final PresetsRepository _presetsRepository;
  final SalaryRepository _salaryRepository;

  CalendarProvider(
    this._workRepository,
    this._presetsRepository,
    this._salaryRepository,
  );

  // Estado
  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Dados
  Map<String, WorkDay> _workDays = {}; // Key: "YYYY-MM-DD"
  List<Preset> _presets = [];
  SalarySettings? _salarySettings;
  Map<String, dynamic>? _monthPreview;
  SalaryResult? _monthResult;

  // Auto-save
  Timer? _autoSaveTimer;
  final Map<String, WorkDay> _pendingSaves = {};
  bool _isSaving = false;

  // Getters
  int get currentMonth => _currentMonth;
  int get currentYear => _currentYear;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Preset> get presets => _presets;
  SalarySettings? get salarySettings => _salarySettings;
  Map<String, dynamic>? get monthPreview => _monthPreview;
  SalaryResult? get monthResult => _monthResult;
  bool get isSaving => _isSaving;

  WorkDay? getWorkDay(DateTime date) {
    final key = _dateKey(date);
    return _workDays[key];
  }

  String _dateKey(DateTime date) {
    return WorkDay.formatDateOnly(date);
  }

  // Carrega dados do mês
  Future<void> loadMonth(int month, int year) async {
    _currentMonth = month;
    _currentYear = year;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Carrega dias de trabalho
      final days = await _workRepository.getMonthDays(month, year);
      _workDays = {};
      for (var day in days) {
        final key = _dateKey(day.data);
        _workDays[key] = day;
      }

      // ✅ MELHORIA: Calcula localmente PRIMEIRO para resposta instantânea
      // Sem loading, atualização imediata da UI
      if (_salarySettings != null) {
        _calculateLocalPreview();
      }

      // Carrega preview da API em paralelo (apenas para sincronização/validação)
      // Não bloqueia a UI - usa resultado local que já foi calculado
      _loadMonthPreview().catchError((e) {
        // Ignora erros na sincronização - já temos o cálculo local
        debugPrint('⚠️ Erro ao sincronizar preview da API: $e');
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  // Carrega presets
  Future<void> loadPresets() async {
    try {
      _presets = await _presetsRepository.getPresets();
      notifyListeners();
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      notifyListeners();
    }
  }

  // Carrega configurações de salário
  Future<void> loadSalarySettings() async {
    try {
      _salarySettings = await _salaryRepository.getSettings();
      // Recalcula preview local se já tiver dias carregados
      if (_workDays.isNotEmpty) {
        _calculateLocalPreview();
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      notifyListeners();
    }
  }

  // Carrega preview do mês da API (apenas para sincronização)
  // O cálculo local é sempre usado como fonte primária
  Future<void> _loadMonthPreview() async {
    try {
      final apiPreview = await _salaryRepository.previewMonth(_currentMonth, _currentYear);
      final apiResult = await _salaryRepository.getResult(_currentMonth, _currentYear);
      
      // ✅ MELHORIA: Apenas atualiza se a API retornar dados válidos
      // O cálculo local sempre prevalece para garantir resposta instantânea
      // apiPreview sempre retorna Map<String, dynamic> (nunca null)
      if (apiPreview.isNotEmpty) {
        // Opcionalmente, pode comparar com o cálculo local para detectar divergências
        // Por enquanto, apenas salva o resultado da API como backup
        _monthResult = apiResult;
        // Não sobrescreve _monthPreview - mantém o cálculo local como fonte primária
      }
    } catch (e) {
      // Ignora erros no preview - o cálculo local já fornece o resultado
      debugPrint('⚠️ Preview da API não disponível (usando cálculo local): $e');
    }
  }

  // ✅ MELHORIA: Calcula preview localmente (sem chamar API)
  // Esta é a fonte primária de dados - sempre atualizada instantaneamente
  void _calculateLocalPreview() {
    if (_salarySettings == null) return;

    // Converte _workDays para lista de WorkDay
    final workDaysList = _workDays.values.toList();

    // Calcula usando o SalaryCalculator local (portado do backend)
    // Este cálculo é idêntico ao do backend, garantindo consistência
    _monthPreview = SalaryCalculator.calcSalaryMonth(
      workDaysList,
      _salarySettings!,
      _currentMonth,
      _currentYear,
    );

    // Notifica listeners imediatamente (sem esperar API)
    notifyListeners();
  }

  // Auto-save: agenda salvamento após delay
  void _scheduleAutoSave(WorkDay day) {
    final key = _dateKey(day.data);
    _pendingSaves[key] = day;

    // Cancela timer anterior
    _autoSaveTimer?.cancel();

    // Agenda novo salvamento após 1 segundo de inatividade
    _autoSaveTimer = Timer(const Duration(seconds: 1), () {
      _executeAutoSave();
    });
  }

  // Executa salvamento automático
  Future<void> _executeAutoSave() async {
    if (_pendingSaves.isEmpty || _isSaving) return;

    _isSaving = true;
    notifyListeners();

    try {
      for (var entry in _pendingSaves.entries) {
        final day = entry.value;
        final savedId = await _workRepository.upsertDay(day);
        // Atualiza cache local com o ID retornado
        final updatedDay = WorkDay(
          id: savedId > 0 ? savedId : day.id,
          data: day.data,
          presetId: day.presetId,
          presetNome: day.presetNome,
          presetCor: day.presetCor,
          presetTipo: day.presetTipo,
          totalHours: day.totalHours,
          etapas: day.etapas,
          tipo: day.tipo,
          flagAbatimento: day.flagAbatimento,
          observacoes: day.observacoes,
          intervals: day.intervals,
        );
        _workDays[entry.key] = updatedDay;
      }

      _pendingSaves.clear();
      
      // Recalcula preview localmente
      _calculateLocalPreview();
      
      // Recarrega preview da API em paralelo
      _loadMonthPreview();
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Atualiza ou cria um dia (com auto-save e cálculo local)
  Future<void> upsertDay(WorkDay day) async {
    final key = _dateKey(day.data);
    _workDays[key] = day;
    
    // Atualiza preview localmente instantaneamente
    _calculateLocalPreview();
    notifyListeners();

    // Envia para API em paralelo (não bloqueia a UI)
    _scheduleAutoSave(day);
  }

  // Deleta um dia
  Future<void> deleteDay(DateTime date) async {
    final key = _dateKey(date);
    final day = _workDays[key];
    
    if (day == null || day.id == null) {
      // Se não tem ID, apenas remove do cache
      _workDays.remove(key);
      _calculateLocalPreview();
      notifyListeners();
      return;
    }

    // Remove do cache local primeiro
    _workDays.remove(key);
    _calculateLocalPreview();
    notifyListeners();

    // Envia para API em paralelo
    try {
      await _workRepository.deleteDay(day.id!);
      // Recarrega preview da API para garantir sincronização
      await _loadMonthPreview();
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      notifyListeners();
    }
  }

  // Aplica preset em um ou vários dias (via API dedicada)
  Future<void> applyPresetToDays(List<DateTime> dates, int presetId) async {
    if (dates.isEmpty) return;

    try {
      final dateStrings = dates
          .map((d) => _dateKey(WorkDay.toDateOnly(d)))
          .toList();
      await _workRepository.applyPreset(dateStrings, presetId);
      await loadMonth(_currentMonth, _currentYear);
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> applyPresetToDay(DateTime date, int presetId) async {
    await applyPresetToDays([date], presetId);
  }

  // Cria preset
  Future<void> createPreset(Preset preset) async {
    try {
      final created = await _presetsRepository.createPreset(preset);
      _presets.add(created);
      notifyListeners();
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      notifyListeners();
      rethrow;
    }
  }

  // Atualiza preset
  Future<void> updatePreset(int id, Preset preset) async {
    try {
      final updated = await _presetsRepository.updatePreset(id, preset);
      final index = _presets.indexWhere((p) => p.id == id);
      if (index >= 0) {
        _presets[index] = updated;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      notifyListeners();
      rethrow;
    }
  }

  // Deleta preset
  Future<void> deletePreset(int id) async {
    try {
      await _presetsRepository.deletePreset(id);
      _presets.removeWhere((p) => p.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      notifyListeners();
      rethrow;
    }
  }

  // Atualiza configurações de salário
  Future<void> updateSalarySettings(SalarySettings settings) async {
    try {
      _salarySettings = await _salaryRepository.updateSettings(settings);
      // Recalcula preview local instantaneamente
      if (_workDays.isNotEmpty) {
        _calculateLocalPreview();
      }
      // Também carrega da API em paralelo
      _loadMonthPreview();
      notifyListeners();
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      notifyListeners();
      rethrow;
    }
  }

  // Gera resultado do mês
  Future<void> generateMonthResult() async {
    try {
      await _salaryRepository.generateMonth(_currentMonth, _currentYear);
      _monthResult = await _salaryRepository.getResult(_currentMonth, _currentYear);
      await _loadMonthPreview();
      notifyListeners();
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      notifyListeners();
      rethrow;
    }
  }

  // Exporta mês
  Future<void> exportMonth({String format = 'pdf'}) async {
    try {
      await _salaryRepository.exportMonth(_currentMonth, _currentYear, format: format);
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    // Salva pendências antes de destruir
    if (_pendingSaves.isNotEmpty) {
      _executeAutoSave();
    }
    super.dispose();
  }
}


