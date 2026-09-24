// /src/modules/mapa-tatico/mapa-tatico.repository.js



const db = require('../../config/db');

const {
  encryptPointFields,
  decryptPointRow,
  encryptSuspectProfileFields,
  decryptSuspectProfileRow,
  encryptOccurrenceLogFields,
  decryptOccurrenceLogRow,
} = require('./mapa-tatico-crypto.utils');

const { normalizeEmail, MAX_PHOTOS_PER_POINT } = require('./mapa-tatico-security.utils');

function safeLimit(limit, fallback = 50, max = 100) {
  return Math.min(Math.max(parseInt(limit, 10) || fallback, 1), max);
}

function safeOffset(offset) {
  return Math.max(parseInt(offset, 10) || 0, 0);
}

function mapPhotoRow(row) {
  return {
    id: row.id,
    point_id: row.point_id,
    url: row.url,
    caption: row.caption,
    order_index: row.order_index,
    uploaded_by: row.uploaded_by,
    created_at: row.created_at,
  };
}



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



  async findGroupMembers(groupId, limit = null, offset = 0) {

    let query = `SELECT m.*, p.nome, p.email FROM map_group_members m

       JOIN policiais p ON m.user_id = p.id

       WHERE m.group_id = ?

       ORDER BY m.role DESC, m.created_at ASC`;

    const params = [groupId];

    if (limit != null) {
      query += ` LIMIT ${safeLimit(limit, 100, 200)} OFFSET ${safeOffset(offset)}`;
    }

    const [rows] = await db.execute(query, params);

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

      expiresAt, photoUrl, visibility = 'GROUP'

    } = data;

    const encrypted = encryptPointFields(
      { title, address, description },
      type
    );

    const [result] = await db.execute(

      `INSERT INTO map_points (group_id, creator_id, title, address, description, lat, lng, type, map_type, visibility, expires_at, photo_url)

       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,

      [
        groupId,
        creatorId,
        encrypted.title,
        encrypted.address || null,
        encrypted.description || null,
        lat,
        lng,
        type,
        mapType,
        visibility,
        expiresAt || null,
        photoUrl || null,
      ]

    );

    const pointId = result.insertId;

    return this.findPointById(pointId);

  }



  async _hydratePointRow(row) {
    if (!row) return null;
    const decrypted = decryptPointRow(row);
    const photos = await this.findPhotosByPointId(decrypted.id);
    decrypted.photos = photos;
    if (!decrypted.photo_url && photos.length > 0) {
      decrypted.photo_url = photos[0].url;
    }
    if (decrypted.type === 'suspeito') {
      try {
        decrypted.suspect_profile = await this.findSuspectProfileByPointId(decrypted.id);
      } catch (_) {
        decrypted.suspect_profile = null;
      }
    }
    return decrypted;
  }

  async _hydratePointRows(rows) {
    if (!rows.length) return rows;
    const photosMap = await this.findPhotosByPointIds(rows.map((r) => r.id));
    const suspectIds = rows.filter((r) => r.type === 'suspeito').map((r) => r.id);
    const suspectMap = {};
    for (const id of suspectIds) {
      try {
        suspectMap[id] = await this.findSuspectProfileByPointId(id);
      } catch (_) {
        suspectMap[id] = null;
      }
    }
    return rows.map((row) => {
      const decrypted = decryptPointRow(row);
      const photos = photosMap[row.id] || [];
      decrypted.photos = photos;
      if (!decrypted.photo_url && photos.length > 0) {
        decrypted.photo_url = photos[0].url;
      }
      if (row.type === 'suspeito') {
        decrypted.suspect_profile = suspectMap[row.id] || null;
      }
      return decrypted;
    });
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

    return this._hydratePointRow(rows[0] || null);

  }



  async findPointsByGroup(groupId, mapType, since = null, requestingUserId = null, limit = null, offset = 0) {

    let query = `

      SELECT p.*, m.nome_de_guerra as creator_nome_guerra, pol.nome as creator_nome

      FROM map_points p

      LEFT JOIN map_group_members m ON p.creator_id = m.user_id AND m.group_id = p.group_id

      LEFT JOIN policiais pol ON p.creator_id = pol.id

      WHERE p.group_id = ? AND p.deleted_at IS NULL

        AND (p.expires_at IS NULL OR p.expires_at > NOW())

        AND (p.visibility = 'GROUP' OR p.creator_id = ?)

    `;

    const params = [groupId, requestingUserId ?? 0];

    if (mapType && mapType !== 'ALL') {
      query += ' AND p.map_type = ?';
      params.push(mapType);
    }

    if (since) {
      query += ' AND (p.updated_at > ? OR p.created_at > ?)';
      params.push(since, since);
    }

    query += ' ORDER BY p.created_at DESC';

    if (limit != null) {
      const limitVal = safeLimit(limit, 200, 500);
      const offsetVal = safeOffset(offset);
      query += ` LIMIT ${limitVal} OFFSET ${offsetVal}`;
    }

    const [rows] = await db.execute(query, params);

    return this._hydratePointRows(rows);

  }



  async updatePoint(id, data) {

    const existing = await this.findPointById(id);
    const pointType = data.type !== undefined ? data.type : existing?.type;
    const encryptedData = encryptPointFields(data, pointType);

    const fields = [];

    const values = [];

    const allowed = ['title', 'address', 'description', 'lat', 'lng', 'type', 'map_type', 'visibility', 'expires_at', 'photo_url'];

    for (const key of allowed) {

      if (encryptedData[key] !== undefined) {

        fields.push(`${key} = ?`);

        values.push(encryptedData[key]);

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

      [pointId ?? null, userId, action, metadata ? JSON.stringify(metadata) : null]

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

  async getGroupIntelligence(groupId, mapType, days = 7, requestingUserId = null) {

    const visibilityFilter = ` AND (visibility = 'GROUP' OR creator_id = ?)`;
    const visibilityParams = [requestingUserId ?? 0];

    const [pointsByType] = await db.execute(

      `SELECT type, COUNT(*) as total FROM map_points

       WHERE group_id = ? AND map_type = ? AND deleted_at IS NULL

         AND created_at >= DATE_SUB(NOW(), INTERVAL ? DAY)

         ${visibilityFilter}

       GROUP BY type ORDER BY total DESC`,

      [groupId, mapType, days, ...visibilityParams]

    );

    const [topCommented] = await db.execute(

      `SELECT p.id, p.title, p.type, COUNT(c.id) as comments_count

       FROM map_points p

       LEFT JOIN map_point_comments c ON c.point_id = p.id

       WHERE p.group_id = ? AND p.map_type = ? AND p.deleted_at IS NULL

         ${visibilityFilter}

       GROUP BY p.id ORDER BY comments_count DESC LIMIT 10`,

      [groupId, mapType, ...visibilityParams]

    );

    const [topVisited] = await db.execute(

      `SELECT p.id, p.title, p.type, COUNT(v.id) as visits_count

       FROM map_points p

       LEFT JOIN map_point_visits v ON v.point_id = p.id

         AND v.visited_at >= DATE_SUB(NOW(), INTERVAL ? DAY)

       WHERE p.group_id = ? AND p.map_type = 'LOGISTICS' AND p.deleted_at IS NULL

         ${visibilityFilter}

       GROUP BY p.id ORDER BY visits_count DESC LIMIT 10`,

      [days, groupId, ...visibilityParams]

    );

    const [timeline] = await db.execute(

      `SELECT 'point' as event_type, p.id as ref_id, p.title, p.type, p.created_at as at

       FROM map_points p

       WHERE p.group_id = ? AND p.map_type = ? AND p.deleted_at IS NULL

         AND p.created_at >= DATE_SUB(NOW(), INTERVAL ? DAY)

         ${visibilityFilter}

       ORDER BY p.created_at DESC LIMIT 50`,

      [groupId, mapType, days, ...visibilityParams]

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

  // ========== FOTOS ==========

  async findPhotosByPointId(pointId) {
    const [rows] = await db.execute(
      `SELECT id, point_id, url, caption, order_index, uploaded_by, created_at
       FROM map_point_photos WHERE point_id = ? ORDER BY order_index ASC, id ASC`,
      [pointId]
    );
    return rows.map(mapPhotoRow);
  }

  async findPhotosByPointIds(pointIds) {
    if (!pointIds.length) return {};
    const placeholders = pointIds.map(() => '?').join(',');
    const [rows] = await db.execute(
      `SELECT id, point_id, url, caption, order_index, uploaded_by, created_at
       FROM map_point_photos WHERE point_id IN (${placeholders})
       ORDER BY point_id ASC, order_index ASC, id ASC`,
      pointIds
    );
    const map = {};
    for (const row of rows) {
      if (!map[row.point_id]) map[row.point_id] = [];
      map[row.point_id].push(mapPhotoRow(row));
    }
    return map;
  }

  async countPhotosByPointId(pointId) {
    const [rows] = await db.execute(
      'SELECT COUNT(*) as total FROM map_point_photos WHERE point_id = ?',
      [pointId]
    );
    return rows[0]?.total || 0;
  }

  async findPhotoById(photoId) {
    const [rows] = await db.execute('SELECT * FROM map_point_photos WHERE id = ?', [photoId]);
    return rows[0] ? mapPhotoRow(rows[0]) : null;
  }

  async createPointPhotos(pointId, uploadedBy, urls) {
    if (!urls.length) return [];
    const existingCount = await this.countPhotosByPointId(pointId);
    const created = [];
    for (let i = 0; i < urls.length; i += 1) {
      const [result] = await db.execute(
        `INSERT INTO map_point_photos (point_id, url, order_index, uploaded_by)
         VALUES (?, ?, ?, ?)`,
        [pointId, urls[i], existingCount + i, uploadedBy]
      );
      created.push(await this.findPhotoById(result.insertId));
    }
    await this.syncPointCoverPhoto(pointId);
    return created;
  }

  async deletePointPhoto(photoId) {
    const photo = await this.findPhotoById(photoId);
    if (!photo) return null;
    await db.execute('DELETE FROM map_point_photos WHERE id = ?', [photoId]);
    await this.syncPointCoverPhoto(photo.point_id);
    return photo;
  }

  async syncPointCoverPhoto(pointId) {
    const photos = await this.findPhotosByPointId(pointId);
    const cover = photos[0]?.url || null;
    await db.execute('UPDATE map_points SET photo_url = ? WHERE id = ?', [cover, pointId]);
  }

  async deleteAllPointPhotos(pointId) {
    const photos = await this.findPhotosByPointId(pointId);
    await db.execute('DELETE FROM map_point_photos WHERE point_id = ?', [pointId]);
    await db.execute('UPDATE map_points SET photo_url = NULL WHERE id = ?', [pointId]);
    return photos;
  }

  // ========== HISTÓRICO DE OCORRÊNCIA ==========

  async createOccurrenceLog(pointId, authorId, data) {
    const encrypted = encryptOccurrenceLogFields(data);
    const [result] = await db.execute(
      `INSERT INTO map_point_occurrence_logs
        (point_id, author_id, entry_type, narrative, status, occurred_at)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [
        pointId,
        authorId,
        encrypted.entry_type || 'ATUALIZACAO',
        encrypted.narrative,
        encrypted.status || null,
        encrypted.occurred_at,
      ]
    );
    return this.findOccurrenceLogById(result.insertId);
  }

  async findOccurrenceLogById(id) {
    const [rows] = await db.execute(
      `SELECT l.*, COALESCE(m.nome_de_guerra, p.nome) as author_display_name
       FROM map_point_occurrence_logs l
       LEFT JOIN map_points mp ON mp.id = l.point_id
       LEFT JOIN map_group_members m ON m.group_id = mp.group_id AND m.user_id = l.author_id
       LEFT JOIN policiais p ON p.id = l.author_id
       WHERE l.id = ?`,
      [id]
    );
    return rows[0] ? decryptOccurrenceLogRow(rows[0]) : null;
  }

  async findOccurrenceLogsByPointId(pointId) {
    const [rows] = await db.execute(
      `SELECT l.*, COALESCE(m.nome_de_guerra, p.nome) as author_display_name
       FROM map_point_occurrence_logs l
       LEFT JOIN map_points mp ON mp.id = l.point_id
       LEFT JOIN map_group_members m ON m.group_id = mp.group_id AND m.user_id = l.author_id
       LEFT JOIN policiais p ON p.id = l.author_id
       WHERE l.point_id = ?
       ORDER BY l.occurred_at DESC, l.id DESC`,
      [pointId]
    );
    return rows.map(decryptOccurrenceLogRow);
  }

  // ========== PERFIL DE SUSPEITO ==========

  async findSuspectProfileByPointId(pointId, includeArchived = false) {
    let query = 'SELECT * FROM map_point_suspect_profile WHERE point_id = ?';
    if (!includeArchived) query += ' AND archived_at IS NULL';
    const [rows] = await db.execute(query, [pointId]);
    return rows[0] ? decryptSuspectProfileRow(rows[0]) : null;
  }

  async upsertSuspectProfile(pointId, userId, data) {
    const encrypted = encryptSuspectProfileFields(data);
    const existing = await this.findSuspectProfileByPointId(pointId, true);
    if (existing) {
      await db.execute(
        `UPDATE map_point_suspect_profile SET
          apelido = ?, caracteristicas_fisicas = ?, altura_cm = ?, compleicao = ?,
          tatuagens_marcas = ?, veiculos_associados = ?, modus_operandi = ?,
          nivel_periculosidade = ?, orientacoes_abordagem = ?, bo_rai_numero = ?,
          fundamentacao = ?, archived_at = NULL
         WHERE point_id = ?`,
        [
          encrypted.apelido || null,
          encrypted.caracteristicas_fisicas || null,
          encrypted.altura_cm ?? null,
          encrypted.compleicao || null,
          encrypted.tatuagens_marcas || null,
          encrypted.veiculos_associados || null,
          encrypted.modus_operandi || null,
          encrypted.nivel_periculosidade || 'BAIXO',
          encrypted.orientacoes_abordagem || null,
          encrypted.bo_rai_numero || null,
          encrypted.fundamentacao,
          pointId,
        ]
      );
    } else {
      await db.execute(
        `INSERT INTO map_point_suspect_profile (
          point_id, apelido, caracteristicas_fisicas, altura_cm, compleicao,
          tatuagens_marcas, veiculos_associados, modus_operandi, nivel_periculosidade,
          orientacoes_abordagem, bo_rai_numero, fundamentacao, criado_por
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          pointId,
          encrypted.apelido || null,
          encrypted.caracteristicas_fisicas || null,
          encrypted.altura_cm ?? null,
          encrypted.compleicao || null,
          encrypted.tatuagens_marcas || null,
          encrypted.veiculos_associados || null,
          encrypted.modus_operandi || null,
          encrypted.nivel_periculosidade || 'BAIXO',
          encrypted.orientacoes_abordagem || null,
          encrypted.bo_rai_numero || null,
          encrypted.fundamentacao,
          userId,
        ]
      );
    }
    return this.findSuspectProfileByPointId(pointId, true);
  }

  async archiveSuspectProfile(pointId) {
    await db.execute(
      'UPDATE map_point_suspect_profile SET archived_at = NOW() WHERE point_id = ?',
      [pointId]
    );
  }

  async hasSuspectDisclaimerAck(userId) {
    const [rows] = await db.execute(
      'SELECT user_id FROM map_suspect_profile_disclaimer_ack WHERE user_id = ?',
      [userId]
    );
    return rows.length > 0;
  }

  async acknowledgeSuspectDisclaimer(userId) {
    await db.execute(
      `INSERT INTO map_suspect_profile_disclaimer_ack (user_id) VALUES (?)
       ON DUPLICATE KEY UPDATE acknowledged_at = CURRENT_TIMESTAMP`,
      [userId]
    );
  }

  async countRecentSuspectProfilesByUser(userId, hours = 24) {
    const [rows] = await db.execute(
      `SELECT COUNT(*) as total FROM map_point_suspect_profile
       WHERE criado_por = ? AND atualizado_em >= DATE_SUB(NOW(), INTERVAL ? HOUR)`,
      [userId, hours]
    );
    return rows[0]?.total || 0;
  }

  async countRecentPointsByUser(userId, hours = 1) {
    const [rows] = await db.execute(
      `SELECT COUNT(*) as total FROM map_points
       WHERE creator_id = ? AND created_at >= DATE_SUB(NOW(), INTERVAL ? HOUR)`,
      [userId, hours]
    );
    return rows[0]?.total || 0;
  }

}



module.exports = new MapaTaticoRepository();

