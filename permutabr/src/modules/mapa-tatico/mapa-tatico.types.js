// Tipos de ponto do mapa tático

const OPERATIONAL_TYPES = ['ocorrencia_recente', 'suspeito', 'local_interesse'];
const LOGISTICS_TYPES = ['restaurante', 'padaria', 'base'];
const HEALTH_TYPES = ['hospital_trauma', 'hospital', 'ubs', 'upa'];
const NATIONAL_INFRA_TYPES = [
  'delegacia',
  'posto_combustivel',
  'clube_tiro',
  'unidade_pm',
  'estabelecimento_parceiro',
];
const SHARED_TYPES = [...HEALTH_TYPES];
const NATIONAL_TYPES = [...HEALTH_TYPES, ...NATIONAL_INFRA_TYPES];
const ALL_TYPES = [...OPERATIONAL_TYPES, ...LOGISTICS_TYPES, ...SHARED_TYPES, ...NATIONAL_INFRA_TYPES];

/** Tipos que disparam alerta de proximidade no mapa operacional */
const PROXIMITY_ALERT_TYPES = ['ocorrencia_recente', 'suspeito', 'local_interesse'];

const MAP_TYPES = ['OPERATIONAL', 'LOGISTICS', 'SHARED'];

function isHealthType(type) {
  return HEALTH_TYPES.includes(type);
}

function isNationalInfraType(type) {
  return NATIONAL_INFRA_TYPES.includes(type);
}

function resolveMapTypeForPoint(type, requestedMapType) {
  if (isHealthType(type) || isNationalInfraType(type)) return 'SHARED';
  return requestedMapType;
}

module.exports = {
  OPERATIONAL_TYPES,
  LOGISTICS_TYPES,
  HEALTH_TYPES,
  NATIONAL_INFRA_TYPES,
  SHARED_TYPES,
  NATIONAL_TYPES,
  ALL_TYPES,
  PROXIMITY_ALERT_TYPES,
  MAP_TYPES,
  isHealthType,
  isNationalInfraType,
  resolveMapTypeForPoint,
};
