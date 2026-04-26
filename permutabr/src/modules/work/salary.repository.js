// /src/modules/work/salary.repository.js

const db = require('../../config/db');

class SalaryRepository {
  // Busca configurações de salário de um usuário
  async findSettingsByPolicialId(policialId) {
    const query = 'SELECT * FROM salary_settings WHERE policial_id = ?';
    const [rows] = await db.execute(query, [policialId]);
    return rows[0] || null;
  }

  // Cria ou atualiza configurações de salário
  async upsertSettings(policialId, settings) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();

      // Verifica se já existe
      const [existing] = await connection.execute(
        'SELECT id FROM salary_settings WHERE policial_id = ?',
        [policialId]
      );

      if (existing.length > 0) {
        // Atualiza
        const updateFields = [];
        const updateValues = [];

        const fields = [
          'carga_horaria_dia', 'valor_hora_extra', 'vale_alimentacao',
          'dia_pagamento_va', 'etapa_value', 'previdencia_aliquota',
          'etapa_rule', 'abatimento_horas', 'salario_base',
          'desconto_consignados', 'outros_descontos', 'outras_vantagens'
        ];

        fields.forEach(field => {
          if (settings[field] !== undefined) {
            updateFields.push(`${field} = ?`);
            updateValues.push(settings[field]);
          }
        });

        if (updateFields.length > 0) {
          updateFields.push('atualizado_em = CURRENT_TIMESTAMP');
          updateValues.push(policialId);

          await connection.execute(
            `UPDATE salary_settings 
             SET ${updateFields.join(', ')} 
             WHERE policial_id = ?`,
            updateValues
          );
        }
      } else {
        // Cria novo
        await connection.execute(
          `INSERT INTO salary_settings 
           (policial_id, carga_horaria_dia, valor_hora_extra, vale_alimentacao,
            dia_pagamento_va, etapa_value, previdencia_aliquota, etapa_rule,
            abatimento_horas, salario_base, desconto_consignados, outros_descontos, outras_vantagens)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
          [
            policialId,
            settings.carga_horaria_dia || 5.70,
            settings.valor_hora_extra || 44.00,
            settings.vale_alimentacao || 426.00,
            settings.dia_pagamento_va || 20,
            settings.etapa_value || 11.00,
            settings.previdencia_aliquota || 0.14,
            settings.etapa_rule || 'per_6h',
            settings.abatimento_horas || 5.70,
            settings.salario_base || 0.00,
            settings.desconto_consignados || 0.00,
            settings.outros_descontos || 0.00,
            settings.outras_vantagens || 0.00
          ]
        );
      }

      await connection.commit();
      return true;
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  // Busca resultado de salário de um mês
  async findResultByMonth(policialId, month, year) {
    const query = `
      SELECT * FROM salary_results
      WHERE policial_id = ? AND mes = ? AND ano = ?
    `;
    const [rows] = await db.execute(query, [policialId, month, year]);
    return rows[0] || null;
  }

  // Cria ou atualiza resultado de salário
  async upsertResult(policialId, month, year, resultData) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();

      // Verifica se já existe
      const [existing] = await connection.execute(
        'SELECT id FROM salary_results WHERE policial_id = ? AND mes = ? AND ano = ?',
        [policialId, month, year]
      );

      if (existing.length > 0) {
        // Atualiza
        const updateFields = [];
        const updateValues = [];

        const fields = [
          'total_horas', 'carga_horaria_mes', 'horas_extras', 'total_etapas',
          'valor_etapas', 'vale_alimentacao', 'outras_vantagens', 'valor_horas_extras',
          'salario_bruto', 'desconto_previdencia', 'desconto_irpf',
          'desconto_consignados', 'outros_descontos', 'salario_liquido', 'dias_trabalhados',
          'dias_ferias', 'status'
        ];

        fields.forEach(field => {
          if (resultData[field] !== undefined) {
            updateFields.push(`${field} = ?`);
            updateValues.push(resultData[field]);
          }
        });

        if (updateFields.length > 0) {
          updateFields.push('atualizado_em = CURRENT_TIMESTAMP');
          if (resultData.status === 'PROCESSADO') {
            updateFields.push('processado_em = CURRENT_TIMESTAMP');
          }
          updateValues.push(policialId, month, year);

          await connection.execute(
            `UPDATE salary_results 
             SET ${updateFields.join(', ')} 
             WHERE policial_id = ? AND mes = ? AND ano = ?`,
            updateValues
          );
        }
      } else {
        // Cria novo
        await connection.execute(
          `INSERT INTO salary_results 
           (policial_id, mes, ano, total_horas, carga_horaria_mes, horas_extras,
            total_etapas, valor_etapas, vale_alimentacao, outras_vantagens, valor_horas_extras,
            salario_bruto, desconto_previdencia, desconto_irpf, desconto_consignados,
            outros_descontos, salario_liquido, dias_trabalhados, dias_ferias, status, processado_em)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
          [
            policialId,
            month,
            year,
            resultData.total_horas || 0,
            resultData.carga_horaria_mes || 0,
            resultData.horas_extras || 0,
            resultData.total_etapas || 0,
            resultData.valor_etapas || 0,
            resultData.vale_alimentacao || 0,
            resultData.outras_vantagens || 0,
            resultData.valor_horas_extras || 0,
            resultData.salario_bruto || 0,
            resultData.desconto_previdencia || 0,
            resultData.desconto_irpf || 0,
            resultData.desconto_consignados || 0,
            resultData.outros_descontos || 0,
            resultData.salario_liquido || 0,
            resultData.dias_trabalhados || 0,
            resultData.dias_ferias || 0,
            resultData.status || 'PENDENTE',
            resultData.status === 'PROCESSADO' ? new Date() : null
          ]
        );
      }

      await connection.commit();
      return true;
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  // Busca todos os resultados de um usuário
  async findAllResultsByPolicialId(policialId, limit = 12) {
    const query = `
      SELECT * FROM salary_results
      WHERE policial_id = ?
      ORDER BY ano DESC, mes DESC
      LIMIT ?
    `;
    const [rows] = await db.execute(query, [policialId, limit]);
    return rows;
  }
}

module.exports = new SalaryRepository();


