// /src/core/utils/fontconfig-env.js
//
// sharp (libvips -> librsvg -> pango -> fontconfig) renderiza texto de SVG. O fontconfig grava
// cache em $XDG_CACHE_HOME/fontconfig (padrão: $HOME/.cache/fontconfig). Quando o processo roda
// como um usuário de serviço sem HOME gravável (ex.: `www` no aaPanel), cada renderização loga
// "Fontconfig error: No writable cache directories". A renderização continua funcionando, mas o log
// enche e as fontes são reescaneadas a cada vez.
//
// Este módulo aponta XDG_CACHE_HOME para um diretório gravável em os.tmpdir() quando a variável
// não está definida e o cache padrão não é gravável. Não altera FONTCONFIG_PATH/FONTCONFIG_FILE
// (isso quebraria a localização do fonts.conf do sistema). Deve ser carregado antes da primeira
// renderização de texto; é idempotente e nunca lança exceção.

const fs = require('fs');
const os = require('os');
const path = require('path');

function isWritableDir(dir) {
  try {
    fs.mkdirSync(dir, { recursive: true });
    fs.accessSync(dir, fs.constants.W_OK);
    return true;
  } catch (_) {
    return false;
  }
}

function ensureWritableFontconfigCache() {
  try {
    if (process.env.XDG_CACHE_HOME && isWritableDir(path.join(process.env.XDG_CACHE_HOME, 'fontconfig'))) {
      return process.env.XDG_CACHE_HOME;
    }
    const home = process.env.HOME || (() => { try { return os.homedir(); } catch (_) { return ''; } })();
    if (!process.env.XDG_CACHE_HOME && home && isWritableDir(path.join(home, '.cache', 'fontconfig'))) {
      return path.join(home, '.cache');
    }
    const fallback = path.join(os.tmpdir(), `permuta-cache-${process.getuid ? process.getuid() : 'u'}`);
    if (isWritableDir(path.join(fallback, 'fontconfig'))) {
      process.env.XDG_CACHE_HOME = fallback;
      return fallback;
    }
  } catch (_) {
    // nunca impedir o boot por causa de cache de fontes
  }
  return null;
}

ensureWritableFontconfigCache();

module.exports = { ensureWritableFontconfigCache };
