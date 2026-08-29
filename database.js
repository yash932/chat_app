const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');

// On Railway, set DATA_DIR to the volume mount path (e.g. /data) so the
// database survives redeploys. Locally it falls back to the project folder.
const DATA_DIR = process.env.DATA_DIR || __dirname;
if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
}

const DB_PATH = process.env.DB_PATH || path.join(DATA_DIR, 'chat_data.db');
const db = new sqlite3.Database(DB_PATH);

// Helper for promise-based queries
function run(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function (err) {
      if (err) reject(err);
      else resolve({ id: this.lastID, changes: this.changes });
    });
  });
}

function get(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.get(sql, params, (err, row) => {
      if (err) reject(err);
      else resolve(row);
    });
  });
}

function all(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.all(sql, params, (err, rows) => {
      if (err) reject(err);
      else resolve(rows);
    });
  });
}

async function initDB() {
  await run(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      username TEXT,
      email TEXT UNIQUE,
      password TEXT,
      avatar TEXT,
      status TEXT DEFAULT 'online',
      custom_status TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      last_seen DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  `);

  // Safely add email and password columns if older table without them
  try {
    await run('ALTER TABLE users ADD COLUMN email TEXT');
  } catch (e) {}
  try {
    await run('ALTER TABLE users ADD COLUMN password TEXT');
  } catch (e) {}

  await run(`
    CREATE TABLE IF NOT EXISTS channels (
      id TEXT PRIMARY KEY,
      name TEXT,
      description TEXT,
      is_direct INTEGER DEFAULT 0,
      icon TEXT,
      created_by TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  `);

  try {
    await run('ALTER TABLE channels ADD COLUMN created_by TEXT');
  } catch (e) {}

  await run(`
    CREATE TABLE IF NOT EXISTS channel_members (
      channel_id TEXT,
      user_id TEXT,
      PRIMARY KEY (channel_id, user_id)
    )
  `);

  await run(`
    CREATE TABLE IF NOT EXISTS messages (
      id TEXT PRIMARY KEY,
      channel_id TEXT,
      sender_id TEXT,
      text TEXT,
      reply_to_id TEXT,
      is_edited INTEGER DEFAULT 0,
      is_pinned INTEGER DEFAULT 0,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  `);

  await run(`
    CREATE TABLE IF NOT EXISTS attachments (
      id TEXT PRIMARY KEY,
      message_id TEXT,
      filename TEXT,
      original_name TEXT,
      mimetype TEXT,
      size INTEGER,
      url TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  `);

  await run(`
    CREATE TABLE IF NOT EXISTS reactions (
      id TEXT PRIMARY KEY,
      message_id TEXT,
      user_id TEXT,
      emoji TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(message_id, user_id, emoji)
    )
  `);

}

// User Auth methods
async function signupUser({ username, email, password, avatar, customStatus }) {
  const existing = await get('SELECT * FROM users WHERE email = ?', [email.toLowerCase()]);
  if (existing) {
    throw new Error('An account with this email already exists.');
  }

  const userId = 'usr_' + Date.now() + '_' + Math.random().toString(36).substring(2, 6);
  const userAvatar = avatar || `https://api.dicebear.com/7.x/identicon/svg?seed=${encodeURIComponent(username)}`;

  await run(
    'INSERT INTO users (id, username, email, password, avatar, status, custom_status) VALUES (?, ?, ?, ?, ?, ?, ?)',
    [userId, username, email.toLowerCase(), password, userAvatar, 'online', customStatus || 'Available']
  );

  return get('SELECT id, username, email, avatar, status, custom_status, created_at FROM users WHERE id = ?', [userId]);
}

async function loginUser(emailOrUsername, password) {
  const user = await get(
    'SELECT * FROM users WHERE (email = ? OR username = ?) AND password = ?',
    [emailOrUsername.toLowerCase(), emailOrUsername, password]
  );
  if (!user) {
    // Also support quick login with existing name if password not set
    const fallbackUser = await get(
      'SELECT * FROM users WHERE email = ? OR username = ?',
      [emailOrUsername.toLowerCase(), emailOrUsername]
    );
    if (fallbackUser && !fallbackUser.password) {
      await run('UPDATE users SET password = ? WHERE id = ?', [password, fallbackUser.id]);
      return get('SELECT id, username, email, avatar, status, custom_status, created_at FROM users WHERE id = ?', [fallbackUser.id]);
    }
    throw new Error('Invalid email or password.');
  }

  await run('UPDATE users SET status = "online", last_seen = CURRENT_TIMESTAMP WHERE id = ?', [user.id]);
  return get('SELECT id, username, email, avatar, status, custom_status, created_at FROM users WHERE id = ?', [user.id]);
}

async function upsertUser(user) {
  const existing = await get('SELECT * FROM users WHERE id = ?', [user.id]);
  if (existing) {
    await run(
      'UPDATE users SET username = COALESCE(?, username), avatar = COALESCE(?, avatar), status = COALESCE(?, status), custom_status = COALESCE(?, custom_status), last_seen = CURRENT_TIMESTAMP WHERE id = ?',
      [user.username, user.avatar, user.status, user.custom_status, user.id]
    );
    return get('SELECT id, username, email, avatar, status, custom_status, created_at FROM users WHERE id = ?', [user.id]);
  } else {
    await run(
      'INSERT INTO users (id, username, email, password, avatar, status, custom_status) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [user.id, user.username, user.email || null, user.password || null, user.avatar, user.status || 'online', user.custom_status || '']
    );
    return get('SELECT id, username, email, avatar, status, custom_status, created_at FROM users WHERE id = ?', [user.id]);
  }
}

async function getAllUsers() {
  return all('SELECT id, username, email, avatar, status, custom_status, last_seen FROM users ORDER BY username ASC');
}

async function getUserById(id) {
  return get('SELECT id, username, email, avatar, status, custom_status, last_seen FROM users WHERE id = ?', [id]);
}

// Conversation and Group methods (No static public channels)
async function createGroup(name, description, icon, memberIds = [], createdById) {
  const channelId = `grp_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
  await run(
    'INSERT INTO channels (id, name, description, is_direct, icon, created_by) VALUES (?, ?, ?, 0, ?, ?)',
    [channelId, name, description || '', icon || '👥', createdById]
  );

  const allMembers = Array.from(new Set([...memberIds, createdById].filter(Boolean)));
  for (const uid of allMembers) {
    await run('INSERT OR IGNORE INTO channel_members (channel_id, user_id) VALUES (?, ?)', [channelId, uid]);
  }

  return get('SELECT * FROM channels WHERE id = ?', [channelId]);
}

async function getOrCreateDirectChannel(user1Id, user2Id) {
  const existing = await get(`
    SELECT c.* FROM channels c
    JOIN channel_members cm1 ON c.id = cm1.channel_id AND cm1.user_id = ?
    JOIN channel_members cm2 ON c.id = cm2.channel_id AND cm2.user_id = ?
    WHERE c.is_direct = 1
    LIMIT 1
  `, [user1Id, user2Id]);

  if (existing) {
    return existing;
  }

  const channelId = `dm_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
  await run('INSERT INTO channels (id, name, is_direct, icon, created_by) VALUES (?, ?, 1, ?, ?)', [channelId, 'Direct Message', '💬', user1Id]);
  await run('INSERT INTO channel_members (channel_id, user_id) VALUES (?, ?)', [channelId, user1Id]);
  await run('INSERT INTO channel_members (channel_id, user_id) VALUES (?, ?)', [channelId, user2Id]);

  return get('SELECT * FROM channels WHERE id = ?', [channelId]);
}

async function getUserConversations(userId) {
  // Return all direct message channels and groups that the user is part of
  const channels = await all(`
    SELECT c.*,
      CASE 
        WHEN c.is_direct = 1 THEN other_u.username 
        ELSE c.name 
      END AS display_name,
      CASE 
        WHEN c.is_direct = 1 THEN other_u.avatar 
        ELSE c.icon 
      END AS display_avatar,
      other_u.status AS other_status,
      other_u.custom_status AS other_custom_status,
      other_u.id AS other_user_id,
      (SELECT text FROM messages WHERE channel_id = c.id ORDER BY created_at DESC LIMIT 1) AS last_message_text,
      (SELECT created_at FROM messages WHERE channel_id = c.id ORDER BY created_at DESC LIMIT 1) AS last_message_time
    FROM channels c
    JOIN channel_members cm ON c.id = cm.channel_id AND cm.user_id = ?
    LEFT JOIN channel_members other_cm ON c.id = other_cm.channel_id AND other_cm.user_id != ? AND c.is_direct = 1
    LEFT JOIN users other_u ON other_cm.user_id = other_u.id
    ORDER BY COALESCE(last_message_time, c.created_at) DESC
  `, [userId, userId]);

  return channels;
}

async function getChannelById(id) {
  return get('SELECT * FROM channels WHERE id = ?', [id]);
}

async function getChannelMembers(channelId) {
  return all(`
    SELECT u.id, u.username, u.avatar, u.status, u.custom_status 
    FROM users u
    JOIN channel_members cm ON u.id = cm.user_id
    WHERE cm.channel_id = ?
  `, [channelId]);
}

// Message methods
async function createMessage({ id, channelId, senderId, text, replyToId }) {
  const messageId = id || `msg_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
  await run(
    'INSERT INTO messages (id, channel_id, sender_id, text, reply_to_id) VALUES (?, ?, ?, ?, ?)',
    [messageId, channelId, senderId, text, replyToId || null]
  );
  return getMessageById(messageId);
}

async function getMessageById(id) {
  const msg = await get(`
    SELECT m.*, u.username as sender_name, u.avatar as sender_avatar,
           r.text as reply_to_text, ru.username as reply_to_sender
    FROM messages m
    LEFT JOIN users u ON m.sender_id = u.id
    LEFT JOIN messages r ON m.reply_to_id = r.id
    LEFT JOIN users ru ON r.sender_id = ru.id
    WHERE m.id = ?
  `, [id]);

  if (!msg) return null;

  msg.attachments = await all('SELECT * FROM attachments WHERE message_id = ?', [id]);
  msg.reactions = await all('SELECT * FROM reactions WHERE message_id = ?', [id]);

  if (msg.reply_to_id) {
    msg.replyTo = {
      id: msg.reply_to_id,
      text: msg.reply_to_text,
      sender_name: msg.reply_to_sender
    };
  }

  return msg;
}

async function getChannelMessages(channelId, limit = 100) {
  const rows = await all(`
    SELECT m.*, u.username as sender_name, u.avatar as sender_avatar,
           r.text as reply_to_text, ru.username as reply_to_sender
    FROM messages m
    LEFT JOIN users u ON m.sender_id = u.id
    LEFT JOIN messages r ON m.reply_to_id = r.id
    LEFT JOIN users ru ON r.sender_id = ru.id
    WHERE m.channel_id = ?
    ORDER BY m.created_at ASC
    LIMIT ?
  `, [channelId, limit]);

  for (const msg of rows) {
    msg.attachments = await all('SELECT * FROM attachments WHERE message_id = ?', [msg.id]);
    msg.reactions = await all('SELECT * FROM reactions WHERE message_id = ?', [msg.id]);
    if (msg.reply_to_id) {
      msg.replyTo = {
        id: msg.reply_to_id,
        text: msg.reply_to_text,
        sender_name: msg.reply_to_sender
      };
    }
  }

  return rows;
}

async function deleteMessage(id) {
  await run('DELETE FROM attachments WHERE message_id = ?', [id]);
  await run('DELETE FROM reactions WHERE message_id = ?', [id]);
  return run('DELETE FROM messages WHERE id = ?', [id]);
}

async function togglePinMessage(id) {
  const msg = await get('SELECT is_pinned FROM messages WHERE id = ?', [id]);
  if (!msg) return null;
  const newPin = msg.is_pinned ? 0 : 1;
  await run('UPDATE messages SET is_pinned = ? WHERE id = ?', [newPin, id]);
  return newPin;
}

// Attachment methods
async function addAttachment({ id, messageId, filename, originalName, mimetype, size, url }) {
  const attId = id || `att_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
  await run(
    'INSERT INTO attachments (id, message_id, filename, original_name, mimetype, size, url) VALUES (?, ?, ?, ?, ?, ?, ?)',
    [attId, messageId, filename, originalName, mimetype, size, url]
  );
  return get('SELECT * FROM attachments WHERE id = ?', [attId]);
}

// Reaction methods
async function toggleReaction({ messageId, userId, emoji }) {
  const existing = await get(
    'SELECT * FROM reactions WHERE message_id = ? AND user_id = ? AND emoji = ?',
    [messageId, userId, emoji]
  );

  if (existing) {
    await run('DELETE FROM reactions WHERE id = ?', [existing.id]);
  } else {
    const rxId = `rx_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    await run(
      'INSERT INTO reactions (id, message_id, user_id, emoji) VALUES (?, ?, ?, ?)',
      [rxId, messageId, userId, emoji]
    );
  }

  return all('SELECT * FROM reactions WHERE message_id = ?', [messageId]);
}

// Search
async function searchMessages(query, channelId = null) {
  let sql = `
    SELECT m.*, u.username as sender_name, u.avatar as sender_avatar
    FROM messages m
    LEFT JOIN users u ON m.sender_id = u.id
    WHERE m.text LIKE ?
  `;
  const params = [`%${query}%`];

  if (channelId) {
    sql += ' AND m.channel_id = ?';
    params.push(channelId);
  }

  sql += ' ORDER BY m.created_at DESC LIMIT 50';
  return all(sql, params);
}

module.exports = {
  initDB,
  signupUser,
  loginUser,
  upsertUser,
  getAllUsers,
  getUserById,
  createGroup,
  getOrCreateDirectChannel,
  getUserConversations,
  getChannelById,
  getChannelMembers,
  createMessage,
  getMessageById,
  getChannelMessages,
  deleteMessage,
  togglePinMessage,
  addAttachment,
  toggleReaction,
  searchMessages
};
