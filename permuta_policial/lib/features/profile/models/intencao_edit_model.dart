// lib/features/profile/models/intencao_edit_model.dart

class IntencaoEditModel {
  String? tipo;
  dynamic selectedEstado;
  dynamic selectedMunicipio;
  dynamic selectedUnidade;
  int? raioKm;

  IntencaoEditModel();

  void clear() {
    tipo = null;
    selectedEstado = null;
    selectedMunicipio = null;
    selectedUnidade = null;
    raioKm = null;
  }
}

const List<int?> opcoesRaioKm = [null, 30, 50, 80, 100, 150, 200];
