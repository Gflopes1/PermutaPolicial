const db = require('../../../config/db');
const mapaTaticoRepository = require('../mapa-tatico.repository');
const { decryptPointRow } = require('../mapa-tatico-crypto.utils');
const { safeLimit, safeOffset } = require('../mapa-tatico-security.utils');

class MapaTaticoAdminRepository {
  async createAdminActionLog(adminId, action, groupId = null, targetId = null, reason = null) {
    try {
      await db.execute(
        `INSERT INTO map_admin_action_logs (admin_id, action, group_id, target_id, reason)
         VALUES (?, ?, ?, ?, ?)`,
        [adminId, action, groupId, targetId, reason]
      );
    } catch (error) {
      if (error?.code === 'ER_NO_SUCH_TABLE') {
        await this._ensureAdminActionLogsTable();
        await db.execute(
          `INSERT INTO map_admin_action_logs (admin_id, action, group_id, target_id, reason)
           VALUES (?, ?, ?, ?, ?)`,
          [adminId, action, groupId, targetId, reason]
        );
        return;
      }
      throw error;
    }
  }

  async _ensureAdminActionLogsTable() {
    await db.execute(`
      CREATE TABLE IF NOT EXISTS map_admin_action_logs (
        id INT AUTO_INCREMENT PRIMARY KEY,
        admin_id INT NOT NULL,
        action ENUM('VIEW_GROUP_LIST','VIEW_GROUP_DETAIL','REMOVE_POINT','REMOVE_MEMBER') NOT NULL,
        group_id INT NULL,
        target_id INT NULL,
        reason TEXT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_admin_created (admin_id, created_at),
        INDEX idx_action_group (action, group_id)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    `);
  }

  async findGroupsForAdmin(search = null, limit = 20, offset = 0) {
    const limitVal = safeLimit(limit, 20, 100);
    const offsetVal = safeOffset(offset);
    let query = `
      SELECT g.id, g.name, g.creator_id, g.created_at, g.is_global,
        p.nome as creator_nome,
        (SELECT COUNT(*) FROM map_group_members m WHERE m.group_id = g.id) as member_count,
        (SELECT COUNT(*) FROM map_points pt WHERE pt.group_id = g.id AND pt.deleted_at IS NULL) as point_count
      FROM map_groups g
      LEFT JOIN policiais p ON p.id = g.creator_id
      WHERE g.is_global = 0
    `;
    const params = [];
    if (search) {
      query += ' AND g.name LIKE ?';
      params.push(`%${search}%`);
    }
    query += ` ORDER BY g.created_at DESC LIMIT ${limitVal} OFFSET ${offsetVal}`;
    const [rows] = await db.execute(query, params);
    return rows;
  }

  async findGroupDetailForAdmin(groupId) {
    const group = await mapaTaticoRepository.findGroupById(groupId);
    if (!group || group.is_global) return null;
    const members = await mapaTaticoRepository.findGroupMembers(groupId);
    return { group, members };
  }

  maskPrivatePointForAdmin(point) {
    if (!point || point.visibility !== 'PRIVATE') return point;
    return {
      id: point.id,
      type: point.type,
      map_type: point.map_type,
      visibility: 'PRIVATE',
      creator_id: point.creator_id,
      creator_nome: point.creator_nome,
      creator_nome_guerra: point.creator_nome_guerra,
      created_at: point.created_at,
      expires_at: point.expires_at,
    };
  }

  async findPointsByGroupForAdmin(groupId, mapType = null, type = null, limit = 50, offset = 0) {
    const limitVal = safeLimit(limit, 50, 100);
    const offsetVal = safeOffset(offset);
    let query = `
      SELECT p.*, m.nome_de_guerra as creator_nome_guerra, pol.nome as creator_nome
      FROM map_points p
      LEFT JOIN map_group_members m ON p.creator_id = m.user_id AND m.group_id = p.group_id
      LEFT JOIN policiais pol ON p.creator_id = pol.id
      WHERE p.group_id = ? AND p.deleted_at IS NULL
    `;
    const params = [groupId];
    if (mapType) {
      query += ' AND p.map_type = ?';
      params.push(mapType);
    }
    if (type) {
      query += ' AND p.type = ?';
      params.push(type);
    }
    query += ` ORDER BY p.created_at DESC LIMIT ${limitVal} OFFSET ${offsetVal}`;
    const [rows] = await db.execute(query, params);
    const photosMap = await mapaTaticoRepository.findPhotosByPointIds(rows.map((r) => r.id));

    return rows.map((row) => {
      if (row.visibility === 'PRIVATE') {
        return this.maskPrivatePointForAdmin(row);
      }
      const decrypted = decryptPointRow(row);
      decrypted.photos = photosMap[row.id] || [];
      return decrypted;
    });
  }
}

module.exports = new MapaTaticoAdminRepository();
