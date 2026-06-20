// Tipos de ponto do mapa tático (espelha backend mapa-tatico.types.js)

const operationalPointTypes = ['ocorrencia_recente', 'suspeito', 'local_interesse'];

const logisticsPointTypes = ['restaurante', 'padaria', 'base'];

const healthPointTypes = ['hospital_trauma', 'hospital', 'ubs', 'upa'];

const nationalInfraPointTypes = [
  'delegacia',
  'posto_combustivel',
  'clube_tiro',
  'unidade_pm',
  'estabelecimento_parceiro',
];

const nationalPointTypes = [...healthPointTypes, ...nationalInfraPointTypes];

/// Tipos que disparam alerta de proximidade no mapa operacional
const proximityAlertTypes = ['ocorrencia_recente', 'suspeito', 'local_interesse'];

bool isHealthPointType(String type) => healthPointTypes.contains(type);

bool isNationalInfraPointType(String type) => nationalInfraPointTypes.contains(type);

bool triggersProximityAlert(String type) => proximityAlertTypes.contains(type);

String resolveMapTypeForPointType(String type, String requestedMapType) {
  if (isHealthPointType(type) || isNationalInfraPointType(type)) return 'SHARED';
  return requestedMapType;
}

List<String> creatableTypesForTab(String tabMapType) {
  switch (tabMapType) {
    case 'OPERATIONAL':
      return [...operationalPointTypes, ...healthPointTypes];
    case 'LOGISTICS':
      return [...logisticsPointTypes, ...healthPointTypes];
    case 'NATIONAL':
      return nationalPointTypes;
    default:
      return operationalPointTypes;
  }
}
