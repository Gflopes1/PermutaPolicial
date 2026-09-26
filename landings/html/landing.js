// Landing page script - extracted from inline to comply with CSP
// Reads configuration from data attributes on <body>

const API_BASE = document.body.dataset.apiBase || '';
const AUTH_URL = document.body.dataset.authUrl || '';
const PRIMARY = document.body.dataset.primary || '#1a365d';
const TIPO_PERMUTA = document.body.dataset.tipoPermuta || 'PM';
const MAP_COLOR = PRIMARY;

function escapeHtml(str) {
  return String(str ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

// ── Menu mobile ──
const menuButton = document.getElementById('menuButton');
const navMenu = document.getElementById('navMenu');
if (menuButton && navMenu) {
  menuButton.addEventListener('click', () => {
    const isOpen = navMenu.classList.toggle('open');
    menuButton.setAttribute('aria-expanded', String(isOpen));
    menuButton.textContent = isOpen ? '✕' : '☰';
  });
  navMenu.querySelectorAll('a').forEach((link) => {
    link.addEventListener('click', () => {
      navMenu.classList.remove('open');
      menuButton.setAttribute('aria-expanded', 'false');
      menuButton.textContent = '☰';
    });
  });
}

const yearEl = document.getElementById('currentYear');
if (yearEl) yearEl.textContent = new Date().getFullYear();

async function loadPublicStats() {
  try {
    const res = await fetch(API_BASE + '/permutas/stats-public');
    if (!res.ok) return;
    const json = await res.json();
    const stats = json.data || json;
    const userCountEl = document.getElementById('userCount');
    const unitCountEl = document.getElementById('unitCount');
    if (stats.usuarios_verificados != null && userCountEl) {
      userCountEl.textContent = stats.usuarios_verificados;
    }
    if (stats.unidades_ativas != null && unitCountEl) {
      unitCountEl.textContent = stats.unidades_ativas;
    }
  } catch (e) {
    console.error('Erro ao carregar estatísticas públicas', e);
  }
}
loadPublicStats();

// ── Mapa Leaflet ──
let mapMain = null, mapHero = null, markersLayer = null, heroLayer = null;
let mapPoints = [];
let simMarkers = [];

function createMap(elId, zoom = 4) {
  const map = L.map(elId, { scrollWheelZoom: false, attributionControl: true }).setView([-15.78, -47.93], zoom);
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '© OpenStreetMap',
    maxZoom: 18,
  }).addTo(map);
  return map;
}

function markerRadius(ponto) {
  return Math.min(Math.max(6, Math.sqrt(ponto.volume || ponto.contagem || 1) * 3), 28);
}

function renderMarkers(map, layer, pontos, clickable = true) {
  if (layer) layer.clearLayers();
  const newLayer = L.layerGroup();
  pontos.forEach((p) => {
    const lat = parseFloat(p.latitude);
    const lng = parseFloat(p.longitude);
    if (isNaN(lat) || isNaN(lng)) return;
    const volume = p.volume || p.contagem || 0;
    const circle = L.circleMarker([lat, lng], {
      radius: markerRadius(p),
      fillColor: MAP_COLOR,
      color: '#fff',
      weight: 1.5,
      opacity: 1,
      fillOpacity: 0.72,
    });
    const popup = '<strong>' + escapeHtml(p.nome) + '</strong><br>Atividade: ' + escapeHtml(volume) +
      (clickable ? '<br><a href="' + AUTH_URL + '">Cadastre-se para explorar</a>' : '');
    circle.bindPopup(popup);
    newLayer.addLayer(circle);
  });
  newLayer.addTo(map);
  return newLayer;
}

async function loadMapData() {
  const statusEl = document.getElementById('mapStatus');
  if (!statusEl) return;
  statusEl.textContent = 'Carregando dados…';
  try {
    let res = await fetch(API_BASE + '/mapa/dados?tipo=volume');
    if (!res.ok) res = await fetch(API_BASE + '/mapa/dados?tipo=balanco');
    if (!res.ok) throw new Error('Falha ao carregar dados do mapa');
    const json = await res.json();
    let pontos = (json.data && json.data.pontos) || json.pontos || [];
    pontos = pontos.map((p) => ({
      ...p,
      volume: p.volume || p.contagem || ((p.saindo || 0) + (p.vindo || 0)),
      contagem: p.contagem || p.volume || ((p.saindo || 0) + (p.vindo || 0)),
    }));
    mapPoints = pontos;
    statusEl.textContent = pontos.length + ' regiões com atividade · atualizado agora';
    if (mapMain) markersLayer = renderMarkers(mapMain, markersLayer, pontos);
    if (mapHero) heroLayer = renderMarkers(mapHero, heroLayer, pontos.slice(0, 40), false);
  } catch (e) {
    statusEl.textContent = 'Não foi possível carregar o mapa. Tente novamente.';
    console.error(e);
  }
}

function bootMaps() {
  if (typeof L === 'undefined') return;
  const mapPreviewEl = document.getElementById('mapPreview');
  const mapHeroEl = document.getElementById('mapHero');
  if (!mapMain && mapPreviewEl) mapMain = createMap('mapPreview', 4);
  if (!mapHero && mapHeroEl) mapHero = createMap('mapHero', 4);
  loadMapData();
}

function initMapsWhenVisible() {
  const targets = [
    document.getElementById('mapPreview'),
    document.getElementById('mapHero'),
  ].filter(Boolean);

  if (!targets.length) return;

  if ('IntersectionObserver' in window) {
    const observer = new IntersectionObserver((entries) => {
      if (entries.some((e) => e.isIntersecting)) {
        bootMaps();
        observer.disconnect();
      }
    }, { rootMargin: '150px' });
    targets.forEach((el) => observer.observe(el));
  } else {
    bootMaps();
  }
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initMapsWhenVisible);
} else {
  initMapsWhenVisible();
}

// ── Simulador (API pública agregada) ──
const searchForm = document.getElementById('searchForm');
const searchFeedback = document.getElementById('searchFeedback');

function normalize(str) {
  return (str || '').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').trim();
}

function findPoint(cidade) {
  const n = normalize(cidade);
  return mapPoints.find((p) => normalize(p.nome).includes(n) || n.includes(normalize(p.nome)));
}

function highlightSimCities(origem, destino) {
  simMarkers.forEach((m) => mapMain.removeLayer(m));
  simMarkers = [];
  [origem, destino].forEach((p, i) => {
    if (!p) return;
    const lat = parseFloat(p.latitude);
    const lng = parseFloat(p.longitude);
    const m = L.circleMarker([lat, lng], {
      radius: 14, fillColor: i === 0 ? MAP_COLOR : '#64748b',
      color: '#fff', weight: 3, fillOpacity: 0.9,
    }).bindPopup('<strong>' + escapeHtml(p.nome) + '</strong>').addTo(mapMain);
    simMarkers.push(m);
  });
  if (simMarkers.length === 2) {
    const lats = simMarkers.map((m) => m.getLatLng().lat);
    const lngs = simMarkers.map((m) => m.getLatLng().lng);
    mapMain.fitBounds([[Math.min(...lats), Math.min(...lngs)], [Math.max(...lats), Math.max(...lngs)]], { padding: [40, 40] });
  } else if (simMarkers.length === 1) {
    mapMain.setView(simMarkers[0].getLatLng(), 8);
  }
}

function parseApiError(json, status) {
  if (json && json.message) return json.message;
  if (status === 404) return 'Serviço de simulação não encontrado. Atualize o backend.';
  if (status === 429) return 'Muitas simulações. Aguarde um momento.';
  return 'Não foi possível simular. Tente novamente.';
}

if (searchForm) {
  searchForm.addEventListener('submit', async (event) => {
    event.preventDefault();
    const cidadeAtual = document.getElementById('cidadeAtual').value.trim();
    const cidadeDestino = document.getElementById('cidadeDestino').value.trim();
    const estado = document.getElementById('estado').value.trim().toUpperCase();
    // Só existe nas landings PF/PRF (permuta interestadual)
    const estadoDestinoEl = document.getElementById('estadoDestino');
    const estadoDestinoRaw = estadoDestinoEl ? estadoDestinoEl.value.trim().toUpperCase() : '';
    const estadoDestino = /^[A-Z]{2}$/.test(estadoDestinoRaw) ? estadoDestinoRaw : '';

    if (!estado || estado.length !== 2) {
      searchFeedback.className = 'sim-results';
      searchFeedback.innerHTML = '<p style="color:#b91c1c;text-align:center;">Informe a UF do estado (ex.: SP).</p>';
      return;
    }
    if (estadoDestinoRaw && !estadoDestino) {
      searchFeedback.className = 'sim-results';
      searchFeedback.innerHTML = '<p style="color:#b91c1c;text-align:center;">UF do destino inválida (ex.: RO).</p>';
      return;
    }

    searchFeedback.className = 'sim-results';
    searchFeedback.innerHTML = '<div class="sim-loading"><div class="spinner"></div>Analisando compatibilidades…</div>';

    try {
      const res = await fetch(API_BASE + '/permutas/preview-simulacao', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(Object.assign({
          tipo_permuta: TIPO_PERMUTA,
          cidade_atual: cidadeAtual,
          cidade_destino: cidadeDestino,
          estado,
          raio_km: 50,
        }, estadoDestino ? { estado_destino: estadoDestino } : {})),
      });

      let json = {};
      try {
        json = await res.json();
      } catch (_) {
        throw new Error(parseApiError(null, res.status));
      }

      if (!res.ok) {
        throw new Error(parseApiError(json, res.status));
      }

      const data = json.data || json;
      if (!mapPoints.length) await loadMapData();
      highlightSimCities(findPoint(cidadeAtual), findPoint(cidadeDestino));

      const zeroHint =
        data.possiveis_permutas === 0 && data.interessados_regiao === 0
          ? '<p style="font-size:0.82rem;color:var(--muted);margin-top:0.75rem;text-align:center;">Nenhuma compatibilidade agora — cadastre-se para ser avisado quando surgir match.</p>'
          : '';

      searchFeedback.innerHTML =
        '<h3 style="font-size:1rem;font-weight:700;color:var(--primary-dark);margin-bottom:1rem;">' +
        escapeHtml(cidadeAtual) + ' (' + escapeHtml(estado) + ') → ' + escapeHtml(cidadeDestino) +
        (estadoDestino && estadoDestino !== estado ? ' (' + escapeHtml(estadoDestino) + ')' : '') + '</h3>' +
        '<div class="sim-stats">' +
          '<div class="sim-stat"><strong>' + escapeHtml(data.possiveis_permutas) + '</strong><span>possíveis permutas encontradas</span></div>' +
          '<div class="sim-stat"><strong>' + escapeHtml(data.interessados_regiao) + '</strong><span>usuários interessados na sua região (50 km)</span></div>' +
        '</div>' +
        zeroHint +
        '<div class="sim-cta"><p>Identidades protegidas. Cadastre-se para ver contatos e detalhes reais.</p>' +
        '<a href="' + AUTH_URL + '" class="btn btn-primary">Criar Conta Grátis</a></div>';
    } catch (err) {
      searchFeedback.innerHTML = '<p style="color:#b91c1c;text-align:center;">' + escapeHtml(err.message || 'Erro na simulação.') + '</p>';
    }
  });
}
