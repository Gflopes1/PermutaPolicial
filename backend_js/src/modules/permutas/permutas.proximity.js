// Fragmentos SQL reutilizáveis para match por proximidade (Haversine)

function haversineKm(mLat, mLng, nLat, nLng) {
  return `(6371 * ACOS(LEAST(1, GREATEST(-1,
    COS(RADIANS(${mLat})) * COS(RADIANS(${nLat})) *
    COS(RADIANS(${nLng}) - RADIANS(${mLng})) +
    SIN(RADIANS(${mLat})) * SIN(RADIANS(${nLat}))
  ))))`;
}

/** Permuta interestadual (tipo_permuta) permite intenção ESTADO; intraestadual (forca_id) não. */
function allowsEstadoIntentionFromForcaCondition(condition) {
  return typeof condition === 'string' && condition.includes('tipo_permuta');
}

function sqlMutualIntentionMatch(intAlias, targets, allowEstadoIntention = true) {
  const clauses = [
    `(${intAlias}.tipo_intencao = 'UNIDADE' AND ${intAlias}.unidade_id = ${targets.unidadeAtual})`,
    `(${intAlias}.tipo_intencao = 'MUNICIPIO' AND ${intAlias}.municipio_id = ${targets.municipioAtual})`,
  ];
  if (allowEstadoIntention) {
    clauses.push(
      `(${intAlias}.tipo_intencao = 'ESTADO' AND ${intAlias}.estado_id = COALESCE(${targets.eDireto}.id, ${targets.eUnidade}.id))`
    );
  }
  return `(${clauses.join(' OR ')})`;
}

function sqlInteressadoLocationMatch(allowEstadoIntention = true) {
  if (allowEstadoIntention) {
    return `(
      (i2.tipo_intencao = 'UNIDADE' AND i2.unidade_id = ?) OR
      (i2.tipo_intencao = 'MUNICIPIO' AND i2.municipio_id = ?) OR
      (i2.tipo_intencao = 'ESTADO' AND i2.estado_id = ?)
    )`;
  }
  return `(
    (i2.tipo_intencao = 'UNIDADE' AND i2.unidade_id = ?) OR
    (i2.tipo_intencao = 'MUNICIPIO' AND i2.municipio_id = ?)
  )`;
}

function sqlInteressadoProfileMatch(allowEstadoIntention = true) {
  if (allowEstadoIntention) {
    return `(
      (i.tipo_intencao = 'UNIDADE' AND i.unidade_id = ?) OR
      (i.tipo_intencao = 'MUNICIPIO' AND i.municipio_id = ?) OR
      (i.tipo_intencao = 'ESTADO' AND i.estado_id = ?)
    )`;
  }
  return `(
    (i.tipo_intencao = 'UNIDADE' AND i.unidade_id = ?) OR
    (i.tipo_intencao = 'MUNICIPIO' AND i.municipio_id = ?)
  )`;
}

/**
 * intAlias quer ir para a localização atual de target (unidade/município/estado).
 * Inclui match exato + proximidade quando raio_km está definido.
 */
function sqlLegMatch({
  intAlias,
  uTargetAlias,
  mTargetDirAlias,
  mTargetUnitAlias,
  eTargetDirAlias,
  eTargetUnitAlias,
  mDestAlias,
  mUnidadeDestAlias,
  mCurrAlias,
  allowEstadoIntention = true,
}) {
  const h = haversineKm(
    `${mDestAlias}.latitude`,
    `${mDestAlias}.longitude`,
    `${mCurrAlias}.latitude`,
    `${mCurrAlias}.longitude`
  );
  const hUnidade = haversineKm(
    `${mUnidadeDestAlias}.latitude`,
    `${mUnidadeDestAlias}.longitude`,
    `${mCurrAlias}.latitude`,
    `${mCurrAlias}.longitude`
  );

  const estadoClause = allowEstadoIntention
    ? `(${intAlias}.tipo_intencao = 'ESTADO' AND ${intAlias}.estado_id = COALESCE(${eTargetDirAlias}.id, ${eTargetUnitAlias}.id)) OR`
    : '';

  return `(
    (${intAlias}.tipo_intencao = 'UNIDADE' AND ${intAlias}.unidade_id = ${uTargetAlias}.id) OR
    (${intAlias}.tipo_intencao = 'MUNICIPIO' AND ${intAlias}.municipio_id = ${mCurrAlias}.id) OR
    ${estadoClause}
    (
      ${intAlias}.tipo_intencao = 'MUNICIPIO' AND ${intAlias}.raio_km IS NOT NULL
      AND ${mDestAlias}.latitude IS NOT NULL AND ${mCurrAlias}.latitude IS NOT NULL
      AND ${intAlias}.municipio_id <> ${mCurrAlias}.id
      AND ${h} <= ${intAlias}.raio_km
    ) OR
    (
      ${intAlias}.tipo_intencao = 'UNIDADE' AND ${intAlias}.raio_km IS NOT NULL
      AND ${mUnidadeDestAlias}.latitude IS NOT NULL AND ${mCurrAlias}.latitude IS NOT NULL
      AND ${mUnidadeDestAlias}.id <> ${mCurrAlias}.id
      AND ${hUnidade} <= ${intAlias}.raio_km
    )
  )`;
}

function sqlLegExactOnly({
  intAlias,
  uTargetAlias,
  mCurrAlias,
  eTargetDirAlias,
  eTargetUnitAlias,
  allowEstadoIntention = true,
}) {
  const clauses = [
    `(${intAlias}.tipo_intencao = 'UNIDADE' AND ${intAlias}.unidade_id = ${uTargetAlias}.id)`,
    `(${intAlias}.tipo_intencao = 'MUNICIPIO' AND ${intAlias}.municipio_id = ${mCurrAlias}.id)`,
  ];
  if (allowEstadoIntention) {
    clauses.push(
      `(${intAlias}.tipo_intencao = 'ESTADO' AND ${intAlias}.estado_id = COALESCE(${eTargetDirAlias}.id, ${eTargetUnitAlias}.id))`
    );
  }
  return `(${clauses.join(' OR ')})`;
}

function sqlLegProxOnly({
  intAlias,
  mDestAlias,
  mUnidadeDestAlias,
  mCurrAlias,
}) {
  const h = haversineKm(
    `${mDestAlias}.latitude`,
    `${mDestAlias}.longitude`,
    `${mCurrAlias}.latitude`,
    `${mCurrAlias}.longitude`
  );
  const hUnidade = haversineKm(
    `${mUnidadeDestAlias}.latitude`,
    `${mUnidadeDestAlias}.longitude`,
    `${mCurrAlias}.latitude`,
    `${mCurrAlias}.longitude`
  );

  return `(
    (
      ${intAlias}.tipo_intencao = 'MUNICIPIO' AND ${intAlias}.raio_km IS NOT NULL
      AND ${mDestAlias}.latitude IS NOT NULL AND ${mCurrAlias}.latitude IS NOT NULL
      AND ${intAlias}.municipio_id <> ${mCurrAlias}.id
      AND ${h} <= ${intAlias}.raio_km
    ) OR
    (
      ${intAlias}.tipo_intencao = 'UNIDADE' AND ${intAlias}.raio_km IS NOT NULL
      AND ${mUnidadeDestAlias}.latitude IS NOT NULL AND ${mCurrAlias}.latitude IS NOT NULL
      AND ${mUnidadeDestAlias}.id <> ${mCurrAlias}.id
      AND ${hUnidade} <= ${intAlias}.raio_km
    )
  )`;
}

module.exports = {
  haversineKm,
  allowsEstadoIntentionFromForcaCondition,
  sqlMutualIntentionMatch,
  sqlInteressadoLocationMatch,
  sqlInteressadoProfileMatch,
  sqlLegMatch,
  sqlLegExactOnly,
  sqlLegProxOnly,
};
