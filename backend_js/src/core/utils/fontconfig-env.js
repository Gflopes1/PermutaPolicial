// /src/core/utils/fontconfig-env.js
//
// sharp (libvips -> librsvg -> pango -> fontconfig) renderiza o texto dos SVGs. O fontconfig grava
// cache nos <cachedir> do fonts.conf: /var/cache/fontconfig, $XDG_CACHE_HOME/fontconfig
// (padrão $HOME/.cache/fontconfig) e ~/.fontconfig. Com o processo rodando como `www` e
// HOME=/ (aaPanel), nenhum deles é gravável e cada render loga
// "Fontconfig error: No writable cache directories".
//
// Este módulo, carregado ANTES de qualquer require('sharp') (1º require após o dotenv em
// src/server.js, src/devserver.js e no service de share-intention):
//   - aponta XDG_CACHE_HOME para um diretório gravável (os.tmpdir(), /tmp, /dev/shm ou
//     backend_js/.cache) quando o atual não é gravável;
//   - se HOME não é gravável (ex.: "/"), aponta HOME para o mesmo diretório (cobre o
//     <cachedir>~/.fontconfig</cachedir>). O HOME original fica em PERMUTA_ORIGINAL_HOME.
// Não altera FONTCONFIG_PATH/FONTCONFIG_FILE (quebraria a localização do fonts.conf).
// Loga uma linha "[fontconfig-env]" no boot. Idempotente; nunca lança.

const fs = require('fs');
const os = require('os');
const path = require('path');

let applied = null;

function isWritableDir(dir) {
  if (!dir || typeof dir !== 'string' || !path.isAbsolute(dir)) return false;
  try {
    fs.mkdirSync(dir, { recursive: true });
    fs.accessSync(dir, fs.constants.W_OK);
    const probe = path.join(dir, `.probe-${process.pid}`);
    fs.writeFileSync(probe, '');
    fs.unlinkSync(probe);
    return true;
  } catch (_) {
    return false;
  }
}

function uidTag() {
  try {
    return process.getuid ? String(process.getuid()) : 'u';
  } catch (_) {
    return 'u';
  }
}

function candidateBases() {
  const tag = `permuta-cache-${uidTag()}`;
  const list = [];
  try { list.push(path.join(os.tmpdir(), tag)); } catch (_) { /* ignore */ }
  list.push(path.join('/tmp', tag), path.join('/dev/shm', tag));
  list.push(path.resolve(__dirname, '../../../.cache')); // backend_js/.cache (dono = usuário do app)
  return [...new Set(list)];
}

function ensureWritableFontconfigCache({ log = true } = {}) {
  if (applied) return applied;
  const result = { xdg: null, home: null, changed: [] };
  try {
    const home = process.env.HOME;
    const homeWritable = !!home && home !== '/' && isWritableDir(path.join(home, '.cache', 'fontconfig'));

    const xdg = process.env.XDG_CACHE_HOME;
    if (xdg && isWritableDir(path.join(xdg, 'fontconfig'))) {
      result.xdg = xdg;
    } else if (!xdg && homeWritable) {
      result.xdg = path.join(home, '.cache');
    } else {
      const base = candidateBases().find((b) => isWritableDir(path.join(b, 'fontconfig')));
      if (base) {
        process.env.XDG_CACHE_HOME = base;
        result.xdg = base;
        result.changed.push('XDG_CACHE_HOME');
      }
    }

    if (homeWritable) {
      result.home = home;
    } else if (result.xdg && isWritableDir(result.xdg)) {
      process.env.PERMUTA_ORIGINAL_HOME = home === undefined ? '' : home;
      process.env.HOME = result.xdg;
      result.home = result.xdg;
      result.changed.push('HOME');
    }

    if (log) {
      if (result.xdg) {
        if (result.changed.length) {
          console.info(
            `[fontconfig-env] cache do fontconfig em ${path.join(result.xdg, 'fontconfig')} ` +
              `(ajustado: ${result.changed.join(', ')}; HOME original=${JSON.stringify(home ?? null)})`
          );
        }
      } else {
        console.warn('[fontconfig-env] nenhum diretório gravável para o cache do fontconfig; veja NOTES (fc-cache/chown)');
      }
    }
  } catch (_) {
    // nunca impedir o boot por causa de cache de fontes
  }
  applied = result;
  return result;
}

ensureWritableFontconfigCache();

module.exports = { ensureWritableFontconfigCache };
