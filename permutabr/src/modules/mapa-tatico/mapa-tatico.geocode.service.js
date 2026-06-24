// Geocoding com cache MySQL (Nominatim)

const axios = require('axios');
const crypto = require('crypto');
const db = require('../../config/db');
const ApiError = require('../../core/utils/ApiError');

const NOMINATIM_HEADERS = {
  Accept: 'application/json',
  'User-Agent': 'PermutaPolicial/1.0 (mapa-tatico)',
};
const CACHE_TTL_HOURS = 24;

function cacheKey(type, payload) {
  return crypto.createHash('sha256').update(`${type}:${payload}`).digest('hex');
}

async function getCached(key) {
  const [rows] = await db.execute(
    `SELECT response_json FROM map_geocode_cache
     WHERE cache_key = ? AND expires_at > NOW() LIMIT 1`,
    [key]
  );
  if (!rows.length) return null;
  return rows[0].response_json;
}

async function setCache(key, type, data) {
  const expires = new Date();
  expires.setHours(expires.getHours() + CACHE_TTL_HOURS);
  await db.execute(
    `INSERT INTO map_geocode_cache (cache_key, cache_type, response_json, expires_at)
     VALUES (?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE response_json = VALUES(response_json), expires_at = VALUES(expires_at)`,
    [key, type, JSON.stringify(data), expires]
  );
}

async function searchAddress(query) {
  const q = (query || '').trim();
  if (q.length < 3) throw new ApiError(400, 'Informe ao menos 3 caracteres para busca.');

  const key = cacheKey('search', q.toLowerCase());
  const cached = await getCached(key);
  if (cached) return cached;

  const { data } = await axios.get('https://nominatim.openstreetmap.org/search', {
    params: { format: 'jsonv2', limit: 5, q, countrycodes: 'br' },
    headers: NOMINATIM_HEADERS,
    timeout: 12000,
  });

  const results = (data || []).map((item) => ({
    display_name: item.display_name,
    lat: parseFloat(item.lat),
    lng: parseFloat(item.lon),
  }));

  await setCache(key, 'search', results);
  return results;
}

async function reverseGeocode(lat, lng) {
  const latitude = parseFloat(lat);
  const longitude = parseFloat(lng);
  if (Number.isNaN(latitude) || Number.isNaN(longitude)) {
    throw new ApiError(400, 'Coordenadas inválidas.');
  }

  const key = cacheKey('reverse', `${latitude.toFixed(5)},${longitude.toFixed(5)}`);
  const cached = await getCached(key);
  if (cached) return cached;

  const { data } = await axios.get('https://nominatim.openstreetmap.org/reverse', {
    params: {
      format: 'jsonv2',
      lat: latitude,
      lon: longitude,
      zoom: 18,
      addressdetails: 1,
    },
    headers: NOMINATIM_HEADERS,
    timeout: 12000,
  });

  const result = { display_name: data?.display_name || null };
  await setCache(key, 'reverse', result);
  return result;
}

module.exports = { searchAddress, reverseGeocode };
