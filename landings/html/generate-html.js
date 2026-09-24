const fs = require('fs');
const path = require('path');
const { generateHTML } = require('./landing-template');
const { FORCES } = require('./forces-data');

/** Saídas extras: mesmo HTML de uma corporação, outro nome de arquivo (deploy legado). */
const EXTRA_OUTPUTS = [
  { file: 'novalanding.html', forceId: 'pm' },
];

function generateAll() {
  for (const [forceId, data] of Object.entries(FORCES)) {
    const outPath = path.join(__dirname, `${forceId}.html`);
    fs.writeFileSync(outPath, generateHTML(forceId, data), 'utf8');
    console.log(`✓ ${forceId}.html`);
  }
  for (const { file, forceId } of EXTRA_OUTPUTS) {
    const data = FORCES[forceId];
    if (!data) {
      console.warn(`⚠ ${file}: corporação "${forceId}" não encontrada`);
      continue;
    }
    const outPath = path.join(__dirname, file);
    fs.writeFileSync(outPath, generateHTML(forceId, data), 'utf8');
    console.log(`✓ ${file} (alias de ${forceId})`);
  }
}

if (require.main === module) {
  generateAll();
}

module.exports = { generateHTML, FORCES, generateAll };
