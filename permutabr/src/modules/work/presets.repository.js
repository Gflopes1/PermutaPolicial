// /src/modules/work/presets.repository.js

const db = require('../../config/db');

class PresetsRepository {
  // Busca todos os presets de um usuário
  async findByPolicialId(policialId) {
    const query = `
      SELECT 
        p.*,
        GROUP_CONCAT(
          JSON_OBJECT(
            'id', pi.id,
            'start_time', TIME_FORMAT(pi.start_time, '%H:%i:%s'),
            'end_time', TIME_FORMAT(pi.end_time, '%H:%i:%s'),
            'ordem', pi.ordem
          )
          ORDER BY pi.ordem ASC
        ) as intervals_json
      FROM presets p
      LEFT JOIN preset_intervals pi ON p.id = pi.preset_id
      WHERE p.policial_id = ?
      GROUP BY p.id
      ORDER BY p.nome ASC
    `;
    const [rows] = await db.execute(query, [policialId]);
    return rows;
  }

  // Busca um preset específico
  async findById(presetId, policialId) {
    const query = `
      SELECT * FROM presets
      WHERE id = ? AND policial_id = ?
    `;
    const [rows] = await db.execute(query, [presetId, policialId]);
    return rows[0] || null;
  }

  // Busca intervalos de um preset
  async findIntervalsByPresetId(presetId) {
    const query = `
      SELECT * FROM preset_intervals
      WHERE preset_id = ?
      ORDER BY ordem ASC
    `;
    const [rows] = await db.execute(query, [presetId]);
    return rows;
  }

  // Cria um novo preset
  async create(policialId, presetData, intervals = []) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();

      const insertQuery = `
        INSERT INTO presets 
        (policial_id, nome, cor, duracao, tipo, flag_abatimento, etapa_rule_override, visibilidade)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      `;
      // Se tipo for 'folga' e duracao não fornecida, usa 0
      // Caso contrário, se duracao não fornecida, usa 5.70 como padrão
      // Se duracao for 0 explicitamente, mantém 0
      let duracao = presetData.duracao;
      if (duracao === undefined || duracao === null) {
        duracao = (presetData.tipo === 'folga') ? 0 : 5.70;
      }

      const [result] = await connection.execute(insertQuery, [
        policialId,
        presetData.nome,
        presetData.cor || '#2196F3',
        duracao,
        presetData.tipo || 'normal',
        presetData.flag_abatimento || false,
        presetData.etapa_rule_override || null,
        presetData.visibilidade || 'private'
      ]);

      const presetId = result.insertId;

      // Insere intervalos se fornecidos
      if (intervals && intervals.length > 0) {
        const intervalValues = intervals.map((interval, index) => [
          presetId,
          interval.start_time,
          interval.end_time,
          index
        ]);

        const placeholders = intervalValues.map(() => '(?, ?, ?, ?)').join(', ');
        await connection.execute(
          `INSERT INTO preset_intervals (preset_id, start_time, end_time, ordem)
           VALUES ${placeholders}`,
          intervalValues.flat()
        );
      }

      await connection.commit();
      return presetId;
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  // Atualiza um preset
  async update(presetId, policialId, presetData, intervals = null) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();

      const updateFields = [];
      const updateValues = [];

      if (presetData.nome !== undefined) {
        updateFields.push('nome = ?');
        updateValues.push(presetData.nome);
      }
      if (presetData.cor !== undefined) {
        updateFields.push('cor = ?');
        updateValues.push(presetData.cor);
      }
      if (presetData.duracao !== undefined) {
        updateFields.push('duracao = ?');
        updateValues.push(presetData.duracao);
      }
      if (presetData.tipo !== undefined) {
        updateFields.push('tipo = ?');
        updateValues.push(presetData.tipo);
      }
      if (presetData.flag_abatimento !== undefined) {
        updateFields.push('flag_abatimento = ?');
        updateValues.push(presetData.flag_abatimento);
      }
      if (presetData.etapa_rule_override !== undefined) {
        updateFields.push('etapa_rule_override = ?');
        updateValues.push(presetData.etapa_rule_override);
      }
      if (presetData.visibilidade !== undefined) {
        updateFields.push('visibilidade = ?');
        updateValues.push(presetData.visibilidade);
      }

      if (updateFields.length > 0) {
        updateFields.push('atualizado_em = CURRENT_TIMESTAMP');
        updateValues.push(presetId, policialId);

        await connection.execute(
          `UPDATE presets 
           SET ${updateFields.join(', ')} 
           WHERE id = ? AND policial_id = ?`,
          updateValues
        );
      }

      // Atualiza intervalos se fornecidos
      if (intervals !== null) {
        // Remove intervalos antigos
        await connection.execute(
          'DELETE FROM preset_intervals WHERE preset_id = ?',
          [presetId]
        );

        // Insere novos intervalos
        if (intervals.length > 0) {
          const intervalValues = intervals.map((interval, index) => [
            presetId,
            interval.start_time,
            interval.end_time,
            index
          ]);

          const placeholders = intervalValues.map(() => '(?, ?, ?, ?)').join(', ');
          await connection.execute(
            `INSERT INTO preset_intervals (preset_id, start_time, end_time, ordem)
             VALUES ${placeholders}`,
            intervalValues.flat()
          );
        }
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

  // Deleta um preset
  async delete(presetId, policialId) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();

      // Remove intervalos primeiro
      await connection.execute(
        'DELETE FROM preset_intervals WHERE preset_id = ?',
        [presetId]
      );

      // Remove o preset
      const [result] = await connection.execute(
        'DELETE FROM presets WHERE id = ? AND policial_id = ?',
        [presetId, policialId]
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

  // Cria presets iniciais para um usuário
  async createInitialPresets(policialId) {
    const initialPresets = [
      {
        nome: '6h',
        cor: '#4CAF50',
        duracao: 6.0,
        tipo: 'normal',
        intervals: [{ start_time: '06:00:00', end_time: '12:00:00' }]
      },
      {
        nome: '12h',
        cor: '#4CAF50',
        duracao: 12.0,
        tipo: 'normal',
        intervals: [{ start_time: '06:00:00', end_time: '18:00:00' }]
      },
      {
        nome: '8h',
        cor: '#2196F3',
        duracao: 8.0,
        tipo: 'normal',
        intervals: [{ start_time: '08:00:00', end_time: '16:00:00' }]
      },
      {
        nome: 'Folga',
        cor: '#607D8B',
        duracao: 0,
        tipo: 'folga',
        intervals: []
      },
      {
        nome: 'Atestado',
        cor: '#F44336',
        duracao: 5.7,
        tipo: 'abatimento',
        flag_abatimento: true,
        intervals: []
      },
      {
        nome: 'Férias',
        cor: '#FFEB3B',
        duracao: 0,
        tipo: 'ferias',
        intervals: []
      }
    ];

    const createdPresets = [];
    for (const preset of initialPresets) {
      const presetId = await this.create(policialId, preset, preset.intervals);
      createdPresets.push(presetId);
    }

    return createdPresets;
  }
}

module.exports = new PresetsRepository();


