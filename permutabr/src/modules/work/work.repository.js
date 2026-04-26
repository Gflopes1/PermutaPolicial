// /src/modules/work/work.repository.js

const db = require('../../config/db');

class WorkRepository {
  // Busca dias de trabalho de um mês específico
  async findDaysByMonth(policialId, month, year) {
    const query = `
      SELECT 
        wd.*,
        p.nome as preset_nome,
        p.cor as preset_cor,
        p.tipo as preset_tipo,
        GROUP_CONCAT(
          JSON_OBJECT(
            'id', wi.id,
            'start_time', wi.start_time,
            'end_time', wi.end_time,
            'duracao_minutos', wi.duracao_minutos
          )
        ) as intervals_json
      FROM work_days wd
      LEFT JOIN presets p ON wd.preset_id = p.id
      LEFT JOIN work_intervals wi ON wd.id = wi.work_day_id
      WHERE wd.policial_id = ? 
        AND YEAR(wd.data) = ? 
        AND MONTH(wd.data) = ?
      GROUP BY wd.id
      ORDER BY wd.data ASC
    `;
    const [rows] = await db.execute(query, [policialId, year, month]);
    return rows;
  }

  // Busca um dia específico
  async findDayById(workDayId, policialId) {
    const query = `
      SELECT 
        wd.*,
        p.nome as preset_nome,
        p.cor as preset_cor,
        p.tipo as preset_tipo
      FROM work_days wd
      LEFT JOIN presets p ON wd.preset_id = p.id
      WHERE wd.id = ? AND wd.policial_id = ?
    `;
    const [rows] = await db.execute(query, [workDayId, policialId]);
    return rows[0] || null;
  }

  // Busca intervalos de um dia
  async findIntervalsByDayId(workDayId) {
    const query = `
      SELECT * FROM work_intervals
      WHERE work_day_id = ?
      ORDER BY start_time ASC
    `;
    const [rows] = await db.execute(query, [workDayId]);
    return rows;
  }

  // Cria ou atualiza um dia de trabalho (com transação)
  async upsertDay(policialId, data, dayData, intervals) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();

      // Verifica se o dia já existe
      const [existing] = await connection.execute(
        'SELECT id FROM work_days WHERE policial_id = ? AND data = ?',
        [policialId, data]
      );

      let workDayId;
      if (existing.length > 0) {
        // Atualiza dia existente
        workDayId = existing[0].id;
        const updateFields = [];
        const updateValues = [];
        
        if (dayData.preset_id !== undefined) {
          updateFields.push('preset_id = ?');
          updateValues.push(dayData.preset_id);
        }
        if (dayData.total_hours !== undefined) {
          updateFields.push('total_hours = ?');
          updateValues.push(dayData.total_hours);
        }
        if (dayData.etapas !== undefined) {
          updateFields.push('etapas = ?');
          updateValues.push(dayData.etapas);
        }
        if (dayData.tipo !== undefined) {
          updateFields.push('tipo = ?');
          updateValues.push(dayData.tipo);
        }
        if (dayData.flag_abatimento !== undefined) {
          updateFields.push('flag_abatimento = ?');
          updateValues.push(dayData.flag_abatimento ? 1 : 0);
        }
        if (dayData.observacoes !== undefined) {
          updateFields.push('observacoes = ?');
          updateValues.push(dayData.observacoes);
        }

        if (updateFields.length > 0) {
          updateFields.push('atualizado_em = CURRENT_TIMESTAMP');
          
          const updateQuery = `
            UPDATE work_days 
            SET ${updateFields.join(', ')} 
            WHERE id = ?
          `;
          await connection.execute(updateQuery, [...updateValues, workDayId]);
        }

        // SIMPLIFICADO: Remove intervalos antigos apenas se houver novos para inserir
        // (mantém compatibilidade, mas intervalos não são mais necessários)
        if (intervals && intervals.length > 0) {
          await connection.execute(
            'DELETE FROM work_intervals WHERE work_day_id = ?',
            [workDayId]
          );
        }
      } else {
        // Cria novo dia
        const insertQuery = `
          INSERT INTO work_days 
          (policial_id, data, preset_id, total_hours, etapas, tipo, flag_abatimento, observacoes)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        `;
        const [result] = await connection.execute(insertQuery, [
          policialId,
          data,
          dayData.preset_id || null,
          dayData.total_hours || 0,
          dayData.etapas || 0,
          dayData.tipo || 'normal',
          dayData.flag_abatimento || false,
          dayData.observacoes || null
        ]);
        workDayId = result.insertId;
      }

      // SIMPLIFICADO: Insere intervalos apenas se fornecidos (opcional, compatibilidade retroativa)
      // Intervalos não são mais necessários - total_hours é a fonte de verdade
      if (intervals && intervals.length > 0) {
        const intervalValues = intervals.map(interval => [
          workDayId,
          interval.start_time,
          interval.end_time,
          interval.duracao_minutos || 0
        ]);

        const placeholders = intervalValues.map(() => '(?, ?, ?, ?)').join(', ');
        const insertIntervalsQuery = `
          INSERT INTO work_intervals (work_day_id, start_time, end_time, duracao_minutos)
          VALUES ${placeholders}
        `;
        await connection.execute(
          insertIntervalsQuery,
          intervalValues.flat()
        );
      }

      await connection.commit();
      return workDayId;
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  // Deleta um dia de trabalho
  async deleteDay(workDayId, policialId) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();

      // Deleta intervalos primeiro (CASCADE deve fazer isso, mas garantimos)
      await connection.execute(
        'DELETE FROM work_intervals WHERE work_day_id = ?',
        [workDayId]
      );

      // Deleta o dia
      const [result] = await connection.execute(
        'DELETE FROM work_days WHERE id = ? AND policial_id = ?',
        [workDayId, policialId]
      );

      await connection.commit();
      return result.affectedRows > 0;
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  // Aplica preset em múltiplos dias (em massa)
  async applyPresetToDays(policialId, dates, presetId, presetData) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();

      const results = [];
      for (const date of dates) {
        // Verifica se o dia já existe
        const [existing] = await connection.execute(
          'SELECT id FROM work_days WHERE policial_id = ? AND data = ?',
          [policialId, date]
        );

        let workDayId;
        if (existing.length > 0) {
          workDayId = existing[0].id;
          // Atualiza dia existente
          await connection.execute(
            `UPDATE work_days 
             SET preset_id = ?, 
                 total_hours = ?,
                 etapas = ?,
                 tipo = ?,
                 flag_abatimento = ?,
                 atualizado_em = CURRENT_TIMESTAMP
             WHERE id = ?`,
            [
              presetId,
              presetData.duracao || 0,
              presetData.etapas || 0,
              presetData.tipo || 'normal',
              presetData.flag_abatimento || false,
              workDayId
            ]
          );

          // Remove intervalos antigos
          await connection.execute(
            'DELETE FROM work_intervals WHERE work_day_id = ?',
            [workDayId]
          );
        } else {
          // Cria novo dia
          const [result] = await connection.execute(
            `INSERT INTO work_days 
             (policial_id, data, preset_id, total_hours, etapas, tipo, flag_abatimento)
             VALUES (?, ?, ?, ?, ?, ?, ?)`,
            [
              policialId,
              date,
              presetId,
              presetData.duracao || 0,
              presetData.etapas || 0,
              presetData.tipo || 'normal',
              presetData.flag_abatimento || false
            ]
          );
          workDayId = result.insertId;
        }

        // SIMPLIFICADO: Não insere intervalos do preset (não são necessários)
        // O total_hours já foi definido acima usando presetData.duracao
        // Intervalos são opcionais e não agregam valor para o caso de uso dos agentes

        results.push({ date, workDayId });
      }

      await connection.commit();
      return results;
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  // Busca estatísticas do mês
  async getMonthStats(policialId, month, year) {
    const query = `
      SELECT 
        COUNT(*) as dias_trabalhados,
        SUM(total_hours) as total_horas,
        SUM(etapas) as total_etapas,
        SUM(CASE WHEN tipo = 'ferias' THEN 1 ELSE 0 END) as dias_ferias
      FROM work_days
      WHERE policial_id = ? 
        AND YEAR(data) = ? 
        AND MONTH(data) = ?
    `;
    const [rows] = await db.execute(query, [policialId, year, month]);
    return rows[0] || { dias_trabalhados: 0, total_horas: 0, total_etapas: 0, dias_ferias: 0 };
  }
}

module.exports = new WorkRepository();


