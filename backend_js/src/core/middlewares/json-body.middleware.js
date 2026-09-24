const express = require('express');

const jsonDefault = express.json({ limit: '100kb' });
const jsonEditalCsvImport = express.json({ limit: '15mb' });

function jsonBodyMiddleware(req, res, next) {
  const isEditalCsvImport = /^\/api\/admin\/editais\/\d+\/importar-(vagas|participantes)\/?$/i.test(
    req.path
  );
  return (isEditalCsvImport ? jsonEditalCsvImport : jsonDefault)(req, res, next);
}

module.exports = { jsonBodyMiddleware };
