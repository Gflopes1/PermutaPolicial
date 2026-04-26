// /src/modules/mapa-tatico/mapa-tatico.repository.js

const db = require('../../config/db');

const OPERATIONAL_TYPES = ['ocorrencia_recente', 'suspeito', 'local_interesse'];
const LOGISTICS_TYPES = ['restaurante', 'padaria', 'base'];

class MapaTaticoRepository {
  // ========== GRUPOS ==========
  async createGroup(name, creatorId) {
    const [result] = await db.execute(
      'INSERT INTO map_groups (name, creator_id) VALUES (?, ?)',
      [name, creatorId]
    );
    const groupId = result.insertId;
    await db.execute(
      'INSERT INTO map_group_members (group_id, user_id, role, nome_de_guerra) VALUES (?, ?, ?, ?)',
      [groupId, creatorId, 'MODERATOR', null]
    );
    return this.findGroupById(groupId);
  }

  async findGroupById(id) {
    const [rows] = await db.execute(
      `SELECT g.*, p.nome as creator_nome,
        (SELECT COUNT(*) FROM map_group_members WHERE group_id = g.id) as member_count
       FROM map_groups g
       LEFT JOIN policiais p ON g.creator_id = p.id
       WHERE g.id = ?`,
      [id]
    );
    return rows[0] || null;
  }

  async findGroupsByUserId(userId) {
    const [rows] = await db.execute(
      `SELECT g.*, m.role, m.nome_de_guerra, m.is_muted, p.nome as creator_nome
       FROM map_group_members m
       JOIN map_groups g ON m.group_id = g.id
       LEFT JOIN policiais p ON g.creator_id = p.id
       WHERE m.user_id = ?
       ORDER BY g.name ASC`,
      [userId]
    );
    return rows;
  }

  async findMember(groupId, userId) {
    const [rows] = await db.execute(
      'SELECT * FROM map_group_members WHERE group_id = ? AND user_id = ?',
      [groupId, userId]
    );
    return rows[0] || null;
  }

  async updateNomeDeGuerra(groupId, userId, nomeDeGuerra) {
    await db.execute(
      'UPDATE map_group_members SET nome_de_guerra = ? WHERE group_id = ? AND user_id = ?',
      [nomeDeGuerra || null, groupId, userId]
    );
    return this.findMember(groupId, userId);
  }

  async updateMemberNomeDeGuerra(groupId, userId, nomeDeGuerra) {
    await db.execute(
      'UPDATE map_group_members SET nome_de_guerra = ? WHERE group_id = ? AND user_id = ?',
      [nomeDeGuerra || null, groupId, userId]
    );
    return this.findMember(groupId, userId);
  }

  async setMuted(groupId, userId, isMuted) {
    await db.execute(
      'UPDATE map_group_members SET is_muted = ? WHERE group_id = ? AND user_id = ?',
      [!!isMuted, groupId, userId]
    );
  }

  // ========== CONVITES ==========
  async createInvite(groupId, email, invitedById) {
    const [result] = await db.execute(
      'INSERT INTO map_group_invites (group_id, email, invited_by_id, status) VALUES (?, ?, ?, ?)',
      [groupId, email.toLowerCase().trim(), invitedById, 'PENDING']
    );
    return result.insertId;
  }

  async findPendingInviteByGroupAndEmail(groupId, email) {
    const [rows] = await db.execute(
      'SELECT * FROM map_group_invites WHERE group_id = ? AND email = ? AND status = ?',
      [groupId, email.toLowerCase().trim(), 'PENDING']
    );
    return rows[0] || null;
  }

  async acceptInvite(inviteId, userId) {
    const [invites] = await db.execute('SELECT * FROM map_group_invites WHERE id = ? AND status = ?', [inviteId, 'PENDING']);
    if (invites.length === 0) return null;
    const invite = invites[0];
    await db.execute('UPDATE map_group_invites SET status = ? WHERE id = ?', ['ACCEPTED', inviteId]);
    await db.execute(
      'INSERT INTO map_group_members (group_id, user_id, role) VALUES (?, ?, ?)',
      [invite.group_id, userId, 'MEMBER']
    );
    return this.findGroupById(invite.group_id);
  }

  async addMember(groupId, userId, role = 'MEMBER') {
    await db.execute(
      'INSERT INTO map_group_members (group_id, user_id, role) VALUES (?, ?, ?)',
      [groupId, userId, role]
    );
  }

  async rejectInvite(inviteId, userId) {
    const [invites] = await db.execute('SELECT * FROM map_group_invites WHERE id = ? AND status = ?', [inviteId, 'PENDING']);
    if (invites.length === 0) return false;
    const invite = invites[0];
    const [users] = await db.execute('SELECT email FROM policiais WHERE id = ?', [userId]);
    if (users.length === 0) return false;
    if (invite.email.toLowerCase().trim() !== users[0].email?.toLowerCase().trim()) return false;
    await db.execute('UPDATE map_group_invites SET status = ? WHERE id = ?', ['REJECTED', inviteId]);
    return true;
  }

  async findGroupMembers(groupId) {
    const [rows] = await db.execute(
      `SELECT m.*, p.nome, p.email FROM map_group_members m
       JOIN policiais p ON m.user_id = p.id
       WHERE m.group_id = ?
       ORDER BY m.role DESC, m.created_at ASC`,
      [groupId]
    );
    return rows;
  }

  async removeMember(groupId, userId) {
    const [result] = await db.execute(
      'DELETE FROM map_group_members WHERE group_id = ? AND user_id = ?',
      [groupId, userId]
    );
    return result.affectedRows > 0;
  }

  async countGroupMembers(groupId) {
    const [rows] = await db.execute(
      'SELECT COUNT(*) as total FROM map_group_members WHERE group_id = ?',
      [groupId]
    );
    return rows[0]?.total || 0;
  }

  async countGroupModerators(groupId) {
    const [rows] = await db.execute(
      'SELECT COUNT(*) as total FROM map_group_members WHERE group_id = ? AND role = ?',
      [groupId, 'MODERATOR']
    );
    return rows[0]?.total || 0;
  }

  // ========== PONTOS ==========
  async createPoint(data) {
    const {
      groupId, creatorId, title, address, lat, lng, type, mapType,
      expiresAt, photoUrl
    } = data;
    const [result] = await db.execute(
      `INSERT INTO map_points (group_id, creator_id, title, address, lat, lng, type, map_type, expires_at, photo_url)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [groupId, creatorId, title, address || null, lat, lng, type, mapType, expiresAt || null, photoUrl || null]
    );
    const pointId = result.insertId;
    return this.findPointById(pointId);
  }

  async findPointById(id) {
    const [rows] = await db.execute(
      `SELECT p.*, m.nome_de_guerra as creator_nome_guerra, pol.nome as creator_nome
       FROM map_points p
       LEFT JOIN map_group_members m ON p.creator_id = m.user_id AND m.group_id = p.group_id
       LEFT JOIN policiais pol ON p.creator_id = pol.id
       WHERE p.id = ? AND p.deleted_at IS NULL`,
      [id]
    );
    return rows[0] || null;
  }

  async findPointsByGroup(groupId, mapType = null) {
    let query = `
      SELECT p.*, m.nome_de_guerra as creator_nome_guerra, pol.nome as creator_nome
      FROM map_points p
      LEFT JOIN map_group_members m ON p.creator_id = m.user_id AND m.group_id = p.group_id
      LEFT JOIN policiais pol ON p.creator_id = pol.id
      WHERE p.group_id = ? AND p.deleted_at IS NULL
        AND (p.expires_at IS NULL OR p.expires_at > NOW())
    `;
    const params = [groupId];
    if (mapType) {
      query += ' AND p.map_type = ?';
      params.push(mapType);
    }
    query += ' ORDER BY p.created_at DESC';
    const [rows] = await db.execute(query, params);
    return rows;
  }

  async updatePoint(id, data) {
    const fields = [];
    const values = [];
    const allowed = ['title', 'address', 'lat', 'lng', 'type', 'map_type', 'expires_at', 'photo_url'];
    for (const key of allowed) {
      if (data[key] !== undefined) {
        fields.push(`${key} = ?`);
        values.push(data[key]);
      }
    }
    if (fields.length === 0) return this.findPointById(id);
    values.push(id);
    await db.execute(`UPDATE map_points SET ${fields.join(', ')} WHERE id = ?`, values);
    return this.findPointById(id);
  }

  async softDeletePoint(id) {
    await db.execute('UPDATE map_points SET deleted_at = NOW() WHERE id = ?', [id]);
  }

  // ========== COMENTÁRIOS ==========
  async createComment(pointId, userId, text) {
    const [result] = await db.execute(
      'INSERT INTO map_point_comments (point_id, user_id, text) VALUES (?, ?, ?)',
      [pointId, userId, text]
    );
    return this.findCommentById(result.insertId);
  }

  async findCommentById(id) {
    const [rows] = await db.execute(
      `SELECT c.*, pol.nome as author_nome
       FROM map_point_comments c
       LEFT JOIN policiais pol ON c.user_id = pol.id
       WHERE c.id = ?`,
      [id]
    );
    return rows[0] || null;
  }

  async findCommentsByPointId(pointId) {
    const [rows] = await db.execute(
      `SELECT c.*, COALESCE(m.nome_de_guerra, pol.nome) as author_display_name
       FROM map_point_comments c
       LEFT JOIN map_points mp ON mp.id = c.point_id
       LEFT JOIN map_group_members m ON m.group_id = mp.group_id AND m.user_id = c.user_id
       LEFT JOIN policiais pol ON c.user_id = pol.id
       WHERE c.point_id = ?
       ORDER BY c.created_at ASC`,
      [pointId]
    );
    return rows;
  }

  // ========== VISITAS ==========
  async createVisit(pointId, userId) {
    const [result] = await db.execute(
      'INSERT INTO map_point_visits (point_id, user_id) VALUES (?, ?)',
      [pointId, userId]
    );
    return result.insertId;
  }

  async findVisitsByPointId(pointId, lastDays = 7) {
    const [rows] = await db.execute(
      `SELECT v.*, COALESCE(m.nome_de_guerra, p.nome) as user_display_name
       FROM map_point_visits v
       LEFT JOIN map_points mp ON mp.id = v.point_id
       LEFT JOIN map_group_members m ON m.group_id = mp.group_id AND m.user_id = v.user_id
       LEFT JOIN policiais p ON v.user_id = p.id
       WHERE v.point_id = ? AND v.visited_at >= DATE_SUB(NOW(), INTERVAL ? DAY)
       ORDER BY v.visited_at DESC`,
      [pointId, lastDays]
    );
    return rows;
  }

  // ========== DENÚNCIAS ==========
  async createReport(pointId, userId, reason = null) {
    const [result] = await db.execute(
      'INSERT INTO map_point_reports (point_id, user_id, reason) VALUES (?, ?, ?)',
      [pointId, userId, reason]
    );
    return result.insertId;
  }

  async findReportsByPointId(pointId) {
    const [rows] = await db.execute(
      `SELECT r.*, p.nome as reporter_nome FROM map_point_reports r
       LEFT JOIN policiais p ON r.user_id = p.id
       WHERE r.point_id = ? ORDER BY r.created_at DESC`,
      [pointId]
    );
    return rows;
  }

  // ========== AUDITORIA ==========
  async createAuditLog(pointId, userId, action, metadata = null) {
    await db.execute(
      'INSERT INTO map_point_audit_logs (point_id, user_id, action, metadata) VALUES (?, ?, ?, ?)',
      [pointId, userId, action, metadata ? JSON.stringify(metadata) : null]
    );
  }

  async findAuditLogsByPointId(pointId) {
    const [rows] = await db.execute(
      `SELECT a.*, p.nome as user_nome FROM map_point_audit_logs a
       LEFT JOIN policiais p ON a.user_id = p.id
       WHERE a.point_id = ? ORDER BY a.created_at DESC`,
      [pointId]
    );
    return rows;
  }
}

module.exports = new MapaTaticoRepository();
