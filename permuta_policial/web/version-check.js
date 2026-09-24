/**
 * Detecção de nova versão (Flutter web + landings estáticas).
 * Compara buildId local vs /version.json no servidor.
 * Dispara `permuta-update-available`; use __permutaApplyUpdate() para recarregar limpo.
 */
(function () {
  'use strict';

  var VERSION_KEY = 'permuta_app_build_id';
  var VERSION_URL = '/version.json';
  var CHECK_INTERVAL = 300000;
  var checkInFlight = false;
  var lastCheckAt = 0;
  var updatePending = false;

  /**
   * Força re-fetch dos chunks .part.js após deploy (mesmo URL quebra cache antigo).
   * Sem isso, main.dart.js novo + part.js velho = DeferredLoadException no painel.
   */
  function installDeferredPartCacheBust() {
    if (window.__permutaDeferredLoaderInstalled) return;
    window.__permutaDeferredLoaderInstalled = true;

    function partCacheBust() {
      try {
        if (window.__permutaAppBuild && window.__permutaAppBuild.buildId) {
          return window.__permutaAppBuild.buildId;
        }
      } catch (e) {}
      try {
        if (typeof localStorage !== 'undefined') {
          var stored = localStorage.getItem(VERSION_KEY);
          if (stored) return stored;
        }
      } catch (e2) {}
      return String(Date.now());
    }

    function appendBust(uri, bust) {
      if (!uri || uri.indexOf('.part.js') === -1) return uri;
      var sep = uri.indexOf('?') >= 0 ? '&' : '?';
      return uri + sep + '_b=' + encodeURIComponent(bust);
    }

    function scriptNonce() {
      var script = document.currentScript;
      if (!script) return null;
      return script.nonce || script.getAttribute('nonce');
    }

    function loadScripts(uris, successCallback, errorCallback) {
      var bust = partCacheBust();
      var pending = uris.length;
      var failed = false;
      var nonce = scriptNonce();

      if (pending === 0) {
        successCallback();
        return;
      }

      for (var i = 0; i < uris.length; i++) {
        (function (uri) {
          var script = document.createElement('script');
          script.src = appendBust(uri, bust);
          if (nonce) script.nonce = nonce;
          script.onload = function () {
            if (failed) return;
            pending -= 1;
            if (pending === 0) successCallback();
          };
          script.onerror = function () {
            if (failed) return;
            failed = true;
            errorCallback();
          };
          document.head.appendChild(script);
        })(uris[i]);
      }
    }

    window.dartDeferredLibraryMultiLoader = function (
      uris,
      successCallback,
      errorCallback
    ) {
      loadScripts(uris, successCallback, errorCallback);
    };

    window.dartDeferredLibraryLoader = function (
      uri,
      successCallback,
      errorCallback
    ) {
      loadScripts([uri], successCallback, errorCallback);
    };
  }

  installDeferredPartCacheBust();

  function readMeta(name) {
    var el = document.querySelector('meta[name="' + name + '"]');
    return el ? el.getAttribute('content') : null;
  }

  function getEmbeddedBuild() {
    try {
      if (window.__permutaAppBuild && window.__permutaAppBuild.buildId) {
        return window.__permutaAppBuild;
      }
    } catch (e) {}
    var buildId = readMeta('app-build-id');
    if (!buildId) return null;
    return {
      version: readMeta('app-version'),
      build: readMeta('app-build'),
      buildId: buildId,
    };
  }

  function getStoredBuildId() {
    try {
      if (typeof localStorage !== 'undefined') {
        return localStorage.getItem(VERSION_KEY);
      }
    } catch (e) {}
    return null;
  }

  function saveBuildId(buildId) {
    if (!buildId) return;
    try {
      if (typeof localStorage !== 'undefined') {
        localStorage.setItem(VERSION_KEY, buildId);
      }
    } catch (e) {}
  }

  function shouldSuppressChecks() {
    if (window.__permutaSuppressResumeUntil && Date.now() < window.__permutaSuppressResumeUntil) {
      return true;
    }
    if (window.__permutaOcrInProgress) return true;
    if (window.__permutaApplyingUpdate) return true;
    return false;
  }

  var AUTO_RELOAD_COOLDOWN_MS = 15000;

  function shouldSkipAutoReload() {
    var pathname = location.pathname || '';
    if (pathname.indexOf('/auth/callback') !== -1) return true;
    if (window.__permutaJustAppliedUpdate) return true;
    try {
      if (typeof sessionStorage !== 'undefined') {
        var last = parseInt(sessionStorage.getItem('permuta_auto_reload_at') || '0', 10);
        if (last && Date.now() - last < AUTO_RELOAD_COOLDOWN_MS) return true;
      }
    } catch (e) {}
    return false;
  }

  function markAutoReload() {
    try {
      if (typeof sessionStorage !== 'undefined') {
        sessionStorage.setItem('permuta_auto_reload_at', String(Date.now()));
      }
    } catch (e) {}
  }

  function isFlutterBundleScript(url) {
    if (!url) return false;
    return (
      url.indexOf('main.dart.js') !== -1 ||
      url.indexOf('flutter_bootstrap.js') !== -1 ||
      url.indexOf('flutter.js') !== -1 ||
      /\.part\.js(\?|$)/.test(url) ||
      /\/assets\/.+\.js(\?|$)/.test(url)
    );
  }

  function verifyMainBundleMatches(remote) {
    if (!remote || remote.mainJsSize == null) {
      return Promise.resolve(true);
    }

    var expectedSize = Number(remote.mainJsSize);
    if (!expectedSize || expectedSize <= 0) {
      return Promise.resolve(true);
    }

    return fetch('/main.dart.js?_bundle_check=' + Date.now(), { cache: 'no-store', method: 'HEAD' })
      .then(function (response) {
        if (!response.ok) return false;
        var len = parseInt(response.headers.get('content-length') || '0', 10);
        if (len > 0) {
          return len === expectedSize;
        }
        return fetch('/main.dart.js?_bundle_check=' + Date.now(), { cache: 'no-store' })
          .then(function (fullResponse) {
            if (!fullResponse.ok) return false;
            return fullResponse.blob().then(function (blob) {
              return blob.size === expectedSize;
            });
          });
      })
      .catch(function () {
        return true;
      });
  }

  function isFlutterApp() {
    return !!window.__permutaFlutterReady || !!document.querySelector('flutter-view');
  }

  function clearUpdatePending() {
    updatePending = false;
    try {
      window.__permutaPendingUpdate = null;
      window.__permutaPendingBuildId = null;
      window.dispatchEvent(new CustomEvent('permuta-update-cleared'));
    } catch (e) {}
    hideStaticUpdateBanner();
  }

  function notifyUpdateAvailable(remote) {
    updatePending = true;
    try {
      window.__permutaPendingUpdate = remote || null;
      window.__permutaPendingBuildId = remote && remote.buildId ? remote.buildId : null;
      window.dispatchEvent(
        new CustomEvent('permuta-update-available', { detail: remote || {} })
      );
    } catch (e) {}

    if (!isFlutterApp()) {
      showStaticUpdateBanner(remote);
    }
  }

  function hideStaticUpdateBanner() {
    var el = document.getElementById('permuta-update-banner');
    if (el) el.remove();
  }

  function showStaticUpdateBanner(remote) {
    if (document.getElementById('permuta-update-banner')) return;

    var banner = document.createElement('div');
    banner.id = 'permuta-update-banner';
    banner.setAttribute('role', 'alert');
    banner.style.cssText =
      'position:fixed;top:0;left:0;right:0;z-index:99999;' +
      'background:#014379;color:#fff;padding:12px 16px;' +
      'display:flex;flex-wrap:wrap;align-items:center;justify-content:center;gap:12px;' +
      'font-family:system-ui,-apple-system,sans-serif;font-size:14px;' +
      'box-shadow:0 4px 16px rgba(0,0,0,0.25);';

    var text = document.createElement('span');
    text.textContent = 'Nova versão do Permuta Policial disponível.';
    banner.appendChild(text);

    var btn = document.createElement('button');
    btn.type = 'button';
    btn.textContent = 'Atualizar agora';
    btn.style.cssText =
      'background:#fff;color:#014379;border:none;border-radius:8px;' +
      'padding:8px 14px;font-weight:600;cursor:pointer;';
    btn.addEventListener('click', function () {
      btn.disabled = true;
      btn.textContent = 'Atualizando…';
      applyUpdate(remote, true);
    });
    banner.appendChild(btn);

    document.body.appendChild(banner);
  }

  function handleRemoteVersion(remote) {
    if (!remote || !remote.buildId) return false;

    var embedded = getEmbeddedBuild();
    var embeddedId = embedded && embedded.buildId;

    // buildId embarcado no index.html = versão que está rodando (fonte de verdade)
    if (embeddedId) {
      saveBuildId(embeddedId);
      if (embeddedId === remote.buildId) {
        clearUpdatePending();
        return false;
      }
      if (!updatePending) {
        notifyUpdateAvailable(remote);
      }
      return true;
    }

    var stored = getStoredBuildId();
    if (!stored) {
      saveBuildId(remote.buildId);
      clearUpdatePending();
      return false;
    }

    if (remote.buildId === stored) {
      clearUpdatePending();
      return false;
    }

    if (!updatePending) {
      notifyUpdateAvailable(remote);
    }
    return true;
  }

  function fetchRemoteVersion() {
    if (checkInFlight || shouldSuppressChecks()) return Promise.resolve(null);
    var now = Date.now();
    if (now - lastCheckAt < 5000) return Promise.resolve(null);
    lastCheckAt = now;
    checkInFlight = true;

    return fetch(VERSION_URL + '?_=' + now, { cache: 'no-store' })
      .then(function (response) {
        if (!response.ok) throw new Error('version fetch failed');
        return response.json();
      })
      .catch(function () {
        return fetch('/index.html?_version_check=' + now, { cache: 'no-store' })
          .then(function (response) {
            if (!response.ok) throw new Error('index fallback failed');
            return response.text();
          })
          .then(function (html) {
            var parser = new DOMParser();
            var doc = parser.parseFromString(html, 'text/html');
            var buildId = doc.querySelector('meta[name="app-build-id"]');
            if (!buildId) return null;
            return {
              version: (doc.querySelector('meta[name="app-version"]') || {}).content || null,
              build: (doc.querySelector('meta[name="app-build"]') || {}).content || null,
              buildId: buildId.getAttribute('content'),
            };
          });
      })
      .then(function (remote) {
        if (!remote) return remote;

        return verifyMainBundleMatches(remote).then(function (bundleOk) {
          var embedded = getEmbeddedBuild();
          var buildIdsMatch =
            embedded && embedded.buildId && embedded.buildId === remote.buildId;

          // Só trata mismatch de bytes como deploy pendente se o buildId também divergir.
          // Evita loop quando mainJsSize no version.json está desatualizado (ex.: patch pós-build).
          if (!bundleOk && !buildIdsMatch) {
            notifyUpdateAvailable(remote);
            if (!shouldSkipAutoReload()) {
              applyUpdate(remote, false);
            }
            return remote;
          }

          if (!bundleOk && buildIdsMatch) {
            try {
              console.warn(
                '[Permuta] main.dart.js size difere do version.json, mas buildId coincide — ignorando.'
              );
            } catch (e) {}
          }

          handleRemoteVersion(remote);
          return remote;
        });
      })
      .finally(function () {
        checkInFlight = false;
      });
  }

  function applyUpdate(remoteInfo, forceManual) {
    var manual = forceManual === true;
    if (!manual && shouldSkipAutoReload()) return;
    if (!manual && window.__permutaApplyingUpdate) return;
    window.__permutaApplyingUpdate = true;
    if (!manual) markAutoReload();

    var remote = remoteInfo;
    if (!remote || !remote.buildId) {
      remote = window.__permutaPendingUpdate || null;
    }
    var overlay = document.getElementById('loading');
    if (overlay) {
      overlay.classList.remove('is-hidden');
      overlay.setAttribute('aria-busy', 'true');
      var text = overlay.querySelector('p');
      if (text) text.textContent = 'Atualizando Permuta Policial...';
    }

    function hardReload() {
      window.__permutaJustAppliedUpdate = true;
      try {
        var base = location.href.split('#')[0].split('?')[0];
        location.replace(base + '?_v=' + Date.now());
      } catch (e) {
        location.reload();
      }
    }

    function clearCachesThenReload() {
      var tasks = [];

      if ('serviceWorker' in navigator) {
        tasks.push(
          navigator.serviceWorker.getRegistrations().then(function (regs) {
            return Promise.all(regs.map(function (reg) { return reg.unregister(); }));
          })
        );
      }

      if ('caches' in window) {
        tasks.push(
          caches.keys().then(function (keys) {
            return Promise.all(keys.map(function (key) { return caches.delete(key); }));
          })
        );
      }

      Promise.all(tasks)
        .catch(function () {})
        .finally(function () {
          setTimeout(hardReload, 150);
        });
    }

    clearCachesThenReload();
  }

  function bootstrapLocalVersion() {
    var embedded = getEmbeddedBuild();
    if (embedded && embedded.buildId) {
      saveBuildId(embedded.buildId);
    }
  }

  function scheduleChecks() {
    setInterval(function () {
      if (!shouldSuppressChecks()) {
        fetchRemoteVersion();
      }
    }, CHECK_INTERVAL);

    document.addEventListener('visibilitychange', function () {
      if (document.visibilityState === 'visible' && !shouldSuppressChecks()) {
        fetchRemoteVersion();
      }
    });

    window.addEventListener('permuta-app-resume', function () {
      if (!shouldSuppressChecks()) {
        fetchRemoteVersion();
      }
    });
  }

  window.__permutaCheckForUpdate = function () {
    return fetchRemoteVersion();
  };

  window.__permutaApplyUpdate = function (remoteInfo) {
    if (remoteInfo && remoteInfo.buildId) {
      window.__permutaPendingUpdate = remoteInfo;
    }
    applyUpdate(remoteInfo, true);
  };

  window.addEventListener('permuta-update-available', function (event) {
    try {
      window.__permutaPendingUpdate = (event && event.detail) || null;
      if (window.__permutaPendingUpdate && window.__permutaPendingUpdate.buildId) {
        window.__permutaPendingBuildId = window.__permutaPendingUpdate.buildId;
      }
    } catch (e) {}
  });

  window.addEventListener('permuta-force-update-check', function () {
    fetchRemoteVersion();
  });

  window.addEventListener('permuta-apply-update', function () {
    applyUpdate(window.__permutaPendingUpdate, true);
  });

  window.addEventListener(
    'error',
    function (event) {
      var target = event.target;
      var src = (target && target.src) || event.filename || '';
      if (!isFlutterBundleScript(src)) return;
      if (shouldSkipAutoReload() || window.__permutaApplyingUpdate) return;
      if (updatePending) return;
      var remote = window.__permutaPendingUpdate;
      notifyUpdateAvailable(remote || { buildId: 'bundle-load-error' });
      if (!shouldSkipAutoReload()) {
        applyUpdate(remote, false);
      }
    },
    true
  );

  bootstrapLocalVersion();
  scheduleChecks();
  fetchRemoteVersion();

  if (typeof window !== 'undefined' && window.addEventListener) {
    window.addEventListener('flutter-first-frame', function () {
      window.__permutaFlutterReady = true;
      bootstrapLocalVersion();
      fetchRemoteVersion();
    }, { once: true });
  }
})();
