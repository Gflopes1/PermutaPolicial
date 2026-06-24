// Cálculos geográficos para permuta por proximidade

const EARTH_RADIUS_KM = 6371;

function toRadians(degrees) {
  return (degrees * Math.PI) / 180;
}

/**
 * Distância em km entre dois pontos (Haversine).
 * Retorna null se coordenadas inválidas.
 */
function haversineKm(lat1, lon1, lat2, lon2) {
  const la1 = parseFloat(lat1);
  const lo1 = parseFloat(lon1);
  const la2 = parseFloat(lat2);
  const lo2 = parseFloat(lon2);

  if ([la1, lo1, la2, lo2].some((v) => Number.isNaN(v))) {
    return null;
  }

  const dLat = toRadians(la2 - la1);
  const dLon = toRadians(lo2 - lo1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRadians(la1)) * Math.cos(toRadians(la2)) * Math.sin(dLon / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return EARTH_RADIUS_KM * c;
}

/** Expressão SQL Haversine (MySQL) — aliases: origem (lat/lng), destino (lat/lng) */
const SQL_HAVERSINE_KM = `
  (6371 * ACOS(LEAST(1, GREATEST(-1,
    COS(RADIANS(origem.latitude)) * COS(RADIANS(destino.latitude)) *
    COS(RADIANS(destino.longitude) - RADIANS(origem.longitude)) +
    SIN(RADIANS(origem.latitude)) * SIN(RADIANS(destino.latitude))
  ))))
`;

module.exports = {
  EARTH_RADIUS_KM,
  haversineKm,
  SQL_HAVERSINE_KM,
};
