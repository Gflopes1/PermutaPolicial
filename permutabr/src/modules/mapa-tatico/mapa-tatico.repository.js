// /src/modules/mapa-tatico/mapa-tatico.repository.js



const db = require('../../config/db');

const { normalizeEmail } = require('./mapa-tatico-security.utils');



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

       ORDER BY g.is_global DESC, g.name ASC`,

      [userId]

    );

    return rows;

  }

  async findGlobalGroup() {
    const [rows] = await db.execute(
      'SELECT * FROM map_groups WHERE is_global = 1 LIMIT 1'
    );
    return rows[0] || null;
  }

  async ensureGlobalGroupMembership(userId) {
    let global = await this.findGlobalGroup();
    if (!global) {
      const [result] = await db.execute(
        'INSERT INTO map_groups (name, creator_id, is_global) VALUES (?, ?, 1)',
        ['Mapa Nacional Colaborativo', userId]
      );
      global = await this.findGroupById(result.insertId);
      await db.execute(
        'INSERT INTO map_group_members (group_id, user_id, role) VALUES (?, ?, ?)',
        [global.id, userId, 'MODERATOR']
      );
      return global;
    }

    const member = await this.findMember(global.id, userId);
    if (!member) {
      await db.execute(
        'INSERT INTO map_group_members (group_id, user_id, role) VALUES (?, ?, ?)',
        [global.id, userId, 'MEMBER']
      );
    }
    return global;
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

  async createInvite(groupId, email, invitedById, expiresAt) {

    const normalized = normalizeEmail(email);

    const [result] = await db.execute(

      'INSERT INTO map_group_invites (group_id, email, invited_by_id, status, expires_at) VALUES (?, ?, ?, ?, ?)',

      [groupId, normalized, invitedById, 'PENDING', expiresAt]

    );

    return result.insertId;

  }



  async findPendingInviteByGroupAndEmail(groupId, email) {

    const normalized = normalizeEmail(email);

    const [rows] = await db.execute(

      `SELECT * FROM map_group_invites

       WHERE group_id = ? AND LOWER(TRIM(email)) = ? AND status = ?

         AND (expires_at IS NULL OR expires_at > NOW())`,

      [groupId, normalized, 'PENDING']

    );

    return rows[0] || null;

  }



  async findPendingInvitesByEmail(email) {

    const normalized = normalizeEmail(email);

    const [rows] = await db.execute(

      `SELECT i.*, g.name as group_name FROM map_group_invites i

       JOIN map_groups g ON i.group_id = g.id

       WHERE LOWER(TRIM(i.email)) = ? AND i.status = ?

         AND (i.expires_at IS NULL OR i.expires_at > NOW())`,

      [normalized, 'PENDING']

    );

    return rows;

  }



  async acceptInvite(inviteId, userId) {

    const [invites] = await db.execute(

      `SELECT * FROM map_group_invites

       WHERE id = ? AND status = ? AND (expires_at IS NULL OR expires_at > NOW())`,

      [inviteId, 'PENDING']

    );

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

    const [invites] = await db.execute(

      `SELECT * FROM map_group_invites

       WHERE id = ? AND status = ? AND (expires_at IS NULL OR expires_at > NOW())`,

      [inviteId, 'PENDING']

    );

    if (invites.length === 0) return false;

    const invite = invites[0];

    const [users] = await db.execute('SELECT email FROM policiais WHERE id = ?', [userId]);

    if (users.length === 0) return false;

    if (normalizeEmail(invite.email) !== normalizeEmail(users[0].email)) return false;

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



  async updateMemberRole(groupId, userId, role) {

    const [result] = await db.execute(

      'UPDATE map_group_members SET role = ? WHERE group_id = ? AND user_id = ?',

      [role, groupId, userId]

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

      groupId, creatorId, title, address, description, lat, lng, type, mapType,

      expiresAt, photoUrl

    } = data;

    const [result] = await db.execute(

      `INSERT INTO map_points (group_id, creator_id, title, address, description, lat, lng, type, map_type, expires_at, photo_url)

       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,

      [groupId, creatorId, title, address || null, description || null, lat, lng, type, mapType, expiresAt || null, photoUrl || null]

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



  async findPointsByGroup(groupId, mapType, since = null) {

    let query = `

      SELECT p.*, m.nome_de_guerra as creator_nome_guerra, pol.nome as creator_nome

      FROM map_points p

      LEFT JOIN map_group_members m ON p.creator_id = m.user_id AND m.group_id = p.group_id

      LEFT JOIN policiais pol ON p.creator_id = pol.id

      WHERE p.group_id = ? AND p.deleted_at IS NULL

        AND (p.expires_at IS NULL OR p.expires_at > NOW())

    `;

    const params = [groupId];

    if (mapType && mapType !== 'ALL') {
      query += ' AND p.map_type = ?';
      params.push(mapType);
    }

    if (since) {
      query += ' AND (p.updated_at > ? OR p.created_at > ?)';
      params.push(since, since);
    }

    query += ' ORDER BY p.created_at DESC';

    const [rows] = await db.execute(query, params);

    return rows;

  }



  async updatePoint(id, data) {

    const fields = [];

    const values = [];

    const allowed = ['title', 'address', 'description', 'lat', 'lng', 'type', 'map_type', 'expires_at', 'photo_url'];

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



  /** Remove ponto e dados relacionados (dados operacionais sensíveis). */

  async hardDeletePoint(id) {

    await db.execute('DELETE FROM map_point_comments WHERE point_id = ?', [id]);

    await db.execute('DELETE FROM map_point_visits WHERE point_id = ?', [id]);

    await db.execute('DELETE FROM map_point_reports WHERE point_id = ?', [id]);

    await db.execute('DELETE FROM map_point_audit_logs WHERE point_id = ?', [id]);

    await db.execute('DELETE FROM map_points WHERE id = ?', [id]);

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



  async findCommentsByPointId(pointId, limit = 50, offset = 0) {

    const safeLimit = Math.min(Math.max(parseInt(limit, 10) || 50, 1), 100);

    const safeOffset = Math.max(parseInt(offset, 10) || 0, 0);

    const [rows] = await db.execute(

      `SELECT c.*, COALESCE(m.nome_de_guerra, pol.nome) as author_display_name

       FROM map_point_comments c

       LEFT JOIN map_points mp ON mp.id = c.point_id

       LEFT JOIN map_group_members m ON m.group_id = mp.group_id AND m.user_id = c.user_id

       LEFT JOIN policiais pol ON c.user_id = pol.id

       WHERE c.point_id = ?

       ORDER BY c.created_at ASC

       LIMIT ${safeLimit} OFFSET ${safeOffset}`,

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



  async findVisitsByPointId(pointId, lastDays = 7, limit = 50, offset = 0) {

    const safeLimit = Math.min(Math.max(parseInt(limit, 10) || 50, 1), 100);

    const safeOffset = Math.max(parseInt(offset, 10) || 0, 0);

    const [rows] = await db.execute(

      `SELECT v.*, COALESCE(m.nome_de_guerra, p.nome) as user_display_name

       FROM map_point_visits v

       LEFT JOIN map_points mp ON mp.id = v.point_id

       LEFT JOIN map_group_members m ON m.group_id = mp.group_id AND m.user_id = v.user_id

       LEFT JOIN policiais p ON v.user_id = p.id

       WHERE v.point_id = ? AND v.visited_at >= DATE_SUB(NOW(), INTERVAL ? DAY)

       ORDER BY v.visited_at DESC

       LIMIT ${safeLimit} OFFSET ${safeOffset}`,

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



  async countRecentReportsByUser(pointId, userId, hours = 24) {

    const [rows] = await db.execute(

      `SELECT COUNT(*) as total FROM map_point_reports

       WHERE point_id = ? AND user_id = ?

         AND created_at >= DATE_SUB(NOW(), INTERVAL ? HOUR)`,

      [pointId, userId, hours]

    );

    return rows[0]?.total || 0;

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

      `SELECT a.id, a.point_id, a.user_id, a.action, a.created_at, p.nome as user_nome

       FROM map_point_audit_logs a

       LEFT JOIN policiais p ON a.user_id = p.id

       WHERE a.point_id = ? ORDER BY a.created_at DESC`,

      [pointId]

    );

    return rows;

  }



  // ========== LOCALIZAÇÃO DA EQUIPE ==========

  async upsertMemberLocation(groupId, userId, lat, lng, sharingEnabled) {

    await db.execute(

      `INSERT INTO map_member_locations (group_id, user_id, lat, lng, sharing_enabled)

       VALUES (?, ?, ?, ?, ?)

       ON DUPLICATE KEY UPDATE lat = VALUES(lat), lng = VALUES(lng),

         sharing_enabled = VALUES(sharing_enabled), updated_at = CURRENT_TIMESTAMP`,

      [groupId, userId, lat, lng, !!sharingEnabled]

    );

    return this.findMemberLocation(groupId, userId);

  }



  async findMemberLocation(groupId, userId) {

    const [rows] = await db.execute(

      'SELECT * FROM map_member_locations WHERE group_id = ? AND user_id = ?',

      [groupId, userId]

    );

    return rows[0] || null;

  }



  async findActiveMemberLocations(groupId, maxAgeMinutes = 30) {

    const [rows] = await db.execute(

      `SELECT l.*, COALESCE(m.nome_de_guerra, p.nome) as display_name

       FROM map_member_locations l

       JOIN policiais p ON p.id = l.user_id

       LEFT JOIN map_group_members m ON m.group_id = l.group_id AND m.user_id = l.user_id

       WHERE l.group_id = ? AND l.sharing_enabled = TRUE

         AND l.updated_at >= DATE_SUB(NOW(), INTERVAL ? MINUTE)`,

      [groupId, maxAgeMinutes]

    );

    return rows;

  }



  async setMemberLocationSharing(groupId, userId, sharingEnabled) {

    await db.execute(

      'UPDATE map_member_locations SET sharing_enabled = ? WHERE group_id = ? AND user_id = ?',

      [!!sharingEnabled, groupId, userId]

    );

  }



  // ========== INTELIGÊNCIA ==========

  async getGroupIntelligence(groupId, mapType, days = 7) {

    const [pointsByType] = await db.execute(

      `SELECT type, COUNT(*) as total FROM map_points

       WHERE group_id = ? AND map_type = ? AND deleted_at IS NULL

         AND created_at >= DATE_SUB(NOW(), INTERVAL ? DAY)

       GROUP BY type ORDER BY total DESC`,

      [groupId, mapType, days]

    );

    const [topCommented] = await db.execute(

      `SELECT p.id, p.title, p.type, COUNT(c.id) as comments_count

       FROM map_points p

       LEFT JOIN map_point_comments c ON c.point_id = p.id

       WHERE p.group_id = ? AND p.map_type = ? AND p.deleted_at IS NULL

       GROUP BY p.id ORDER BY comments_count DESC LIMIT 10`,

      [groupId, mapType]

    );

    const [topVisited] = await db.execute(

      `SELECT p.id, p.title, p.type, COUNT(v.id) as visits_count

       FROM map_points p

       LEFT JOIN map_point_visits v ON v.point_id = p.id

         AND v.visited_at >= DATE_SUB(NOW(), INTERVAL ? DAY)

       WHERE p.group_id = ? AND p.map_type = 'LOGISTICS' AND p.deleted_at IS NULL

       GROUP BY p.id ORDER BY visits_count DESC LIMIT 10`,

      [days, groupId]

    );

    const [timeline] = await db.execute(

      `SELECT 'point' as event_type, p.id as ref_id, p.title, p.type, p.created_at as at

       FROM map_points p

       WHERE p.group_id = ? AND p.map_type = ? AND p.deleted_at IS NULL

         AND p.created_at >= DATE_SUB(NOW(), INTERVAL ? DAY)

       ORDER BY p.created_at DESC LIMIT 50`,

      [groupId, mapType, days]

    );

    return { points_by_type: pointsByType, top_commented: topCommented, top_visited: topVisited, timeline };

  }



  // ========== DENÚNCIAS ADMIN ==========

  async findPendingReportsForUser(userId, isSiteAdmin) {

    let query = `

      SELECT r.*, p.title as point_title, p.group_id, p.map_type, g.name as group_name,

        rep.nome as reporter_nome

      FROM map_point_reports r

      JOIN map_points p ON p.id = r.point_id

      JOIN map_groups g ON g.id = p.group_id

      LEFT JOIN policiais rep ON rep.id = r.user_id

      WHERE r.status = 'PENDING'

    `;

    const params = [];

    if (!isSiteAdmin) {

      query += ` AND p.group_id IN (

        SELECT group_id FROM map_group_members WHERE user_id = ? AND role = 'MODERATOR'

      )`;

      params.push(userId);

    }

    query += ' ORDER BY r.created_at DESC LIMIT 100';

    const [rows] = await db.execute(query, params);

    return rows;

  }



  async updateReportStatus(reportId, status, reviewerId, adminNotes = null) {

    await db.execute(

      `UPDATE map_point_reports SET status = ?, reviewed_by_id = ?, reviewed_at = NOW(), admin_notes = ?

       WHERE id = ?`,

      [status, reviewerId, adminNotes, reportId]

    );

  }

}



module.exports = new MapaTaticoRepository();

