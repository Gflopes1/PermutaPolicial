#!/usr/bin/env node
/**
 * Gera códigos de indicação para usuários existentes sem código.
 * Uso: node scripts/seed-referral-codes.js
 */
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });

const db = require('../src/config/db');
const referralRepository = require('../src/modules/referral/referral.repository');
const { generateReferralCode } = require('../src/modules/referral/referral.utils');

async function main() {
  const [rows] = await db.execute(
    `SELECT p.id, p.nome FROM policiais p
     LEFT JOIN referral_codes rc ON rc.user_id = p.id
     WHERE rc.id IS NULL`
  );

  console.log(`Usuários sem código: ${rows.length}`);

  for (const row of rows) {
    let code;
    let attempts = 0;
    do {
      code = generateReferralCode(row.nome);
      attempts += 1;
      if (attempts > 20) throw new Error(`Falha ao gerar código para user ${row.id}`);
    } while (await referralRepository.codeExists(code));

    await referralRepository.createCode(row.id, code);
    console.log(`  user ${row.id} -> ${code}`);
  }

  console.log('Concluído.');
  process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
