const express = require('express');
const http = require('http');
const path = require('path');
const fs = require('fs');
const cors = require('cors');
const multer = require('multer');
const { Server } = require('socket.io');
const db = require('./database');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  },
  maxHttpBufferSize: 50 * 1024 * 1024 // 50 MB buffer for audio/files
});

const PORT = process.env.PORT || 3000;

// Same volume as the database (see database.js) so uploaded files persist.
const DATA_DIR = process.env.DATA_DIR || __dirname;
const UPLOADS_DIR = process.env.UPLOADS_DIR || path.join(DATA_DIR, 'uploads');

// Ensure uploads directory exists
if (!fs.existsSync(UPLOADS_DIR)) {
  fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

// Middleware
app.set('trust proxy', 1); // behind Railway's edge proxy
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));
app.use('/uploads', express.static(UPLOADS_DIR));

// Configure Multer for File Uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, UPLOADS_DIR);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    const sanitizedName = file.originalname.replace(/[^a-zA-Z0-9.-]/g, '_');
    cb(null, `${uniqueSuffix}-${sanitizedName}`);
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 50 * 1024 * 1024 // 50 MB max per file
  }
});

// REST API Endpoints

// Health check — Railway pings this to decide if a deploy is live
app.get('/health', (req, res) => {
  res.json({ status: 'ok', uptime: process.uptime() });
});

// File upload endpoint
app.post('/api/upload', upload.array('files', 10), (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ error: 'No files provided' });
    }

    const uploadedFiles = req.files.map(file => {
      const fileId = `att_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
      return {
        id: fileId,
        filename: file.filename,
        originalName: file.originalname,
        mimetype: file.mimetype,
        size: file.size,
        url: `/uploads/${file.filename}`
      };
    });

    res.json({ success: true, files: uploadedFiles });
  } catch (err) {
    console.error('File upload error:', err);
    res.status(500).json({ error: 'Failed to upload files' });
  }
});

// Authentication Endpoints
app.post('/api/auth/signup', async (req, res) => {
  try {
    const { username, email, password, avatar, custom_status } = req.body;
    if (!username || !email || !password) {
      return res.status(400).json({ error: 'Username, email, and password are required.' });
    }
    const user = await db.signupUser({
      username: username.trim(),
      email: email.trim(),
      password,
      avatar,
      customStatus: custom_status
    });
    // Broadcast user presence to all connected sockets
    io.emit('user_presence', {
      userId: user.id,
      user,
      online: true
    });
    res.json({ success: true, user });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required.' });
    }
    const user = await db.loginUser(email.trim(), password);
    res.json({ success: true, user });
  } catch (err) {
    res.status(401).json({ error: err.message });
  }
});

// Get user conversations (1-on-1 Direct Messages and Groups)
app.get('/api/users/:userId/conversations', async (req, res) => {
  try {
    const conversations = await db.getUserConversations(req.params.userId);
    res.json(conversations);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create a manually formed Group
app.post('/api/groups', async (req, res) => {
  try {
    const { name, description, icon, memberIds, createdById } = req.body;
    if (!name) return res.status(400).json({ error: 'Group name is required' });
    const group = await db.createGroup(name, description, icon || '👥', memberIds || [], createdById);
    io.emit('group_created', group);
    res.json(group);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get channel details
app.get('/api/channels/:id', async (req, res) => {
  try {
    const channel = await db.getChannelById(req.params.id);
    if (!channel) return res.status(400).json({ error: 'Channel not found' });
    res.json(channel);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create/Get Direct Message channel between two users
app.post('/api/direct-messages', async (req, res) => {
  try {
    const { user1Id, user2Id } = req.body;
    if (!user1Id || !user2Id) {
      return res.status(400).json({ error: 'user1Id and user2Id are required' });
    }
    const channel = await db.getOrCreateDirectChannel(user1Id, user2Id);
    res.json(channel);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get messages for a channel/group/DM
app.get('/api/channels/:id/messages', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 100;
    const messages = await db.getChannelMessages(req.params.id, limit);
    res.json(messages);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Search messages
app.get('/api/search', async (req, res) => {
  try {
    const { q, channelId } = req.query;
    if (!q) return res.json([]);
    const results = await db.searchMessages(q, channelId);
    res.json(results);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get all users
app.get('/api/users', async (req, res) => {
  try {
    const users = await db.getAllUsers();
    res.json(users);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Real-Time Socket.IO Handling
const onlineUsers = new Map(); // socketId -> user object
const userSockets = new Map(); // userId -> Set(socketId)

io.on('connection', (socket) => {
  let activeUser = null;

  // Handle user authentication/connection
  const handleUserConnect = async (userData) => {
    if (!userData || !userData.id) return;
    try {
      activeUser = await db.upsertUser(userData);
      onlineUsers.set(socket.id, activeUser);

      if (!userSockets.has(activeUser.id)) {
        userSockets.set(activeUser.id, new Set());
      }
      userSockets.get(activeUser.id).add(socket.id);

      // Broadcast user presence to all connected clients
      io.emit('user_presence', {
        userId: activeUser.id,
        user: activeUser,
        online: true
      });

      // Send current state to newly connected client
      socket.emit('session_ready', {
        user: activeUser,
        onlineUsers: Array.from(new Set(Array.from(onlineUsers.values()).map(u => u.id)))
          .map(id => Array.from(onlineUsers.values()).find(u => u.id === id))
      });
    } catch (err) {
      console.error('Error during user connect:', err);
    }
  };

  socket.on('user_connected', handleUserConnect);
  socket.on('user_login', handleUserConnect);

  // Join a channel/group/DM room
  socket.on('join_channel', ({ channelId }) => {
    if (channelId) socket.join(channelId);
  });

  // Leave a channel room
  socket.on('leave_channel', ({ channelId }) => {
    if (channelId) socket.leave(channelId);
  });

  // Send message
  socket.on('send_message', async (data, callback) => {
    try {
      const { channelId, senderId, text, replyToId, attachments } = data;
      if (!channelId || !senderId || (!text && (!attachments || attachments.length === 0))) {
        if (callback) callback({ error: 'Invalid message payload' });
        return;
      }

      // Save message in SQLite
      const message = await db.createMessage({
        channelId,
        senderId,
        text: text || '',
        replyToId
      });

      // Save attachments if any
      if (attachments && attachments.length > 0) {
        for (const att of attachments) {
          await db.addAttachment({
            messageId: message.id,
            filename: att.filename,
            originalName: att.originalName || att.filename,
            mimetype: att.mimetype,
            size: att.size,
            url: att.url
          });
        }
      }

      // Re-fetch complete message
      const completeMessage = await db.getMessageById(message.id);

      // Broadcast to everyone in channel room
      io.to(channelId).emit('new_message', completeMessage);

      // Also notify sender if not in room
      socket.emit('message_sent', { tempId: data.tempId, message: completeMessage });

      if (callback) callback({ success: true, message: completeMessage });
    } catch (err) {
      console.error('Error in send_message:', err);
      if (callback) callback({ error: 'Failed to send message' });
    }
  });

  // Typing indicators
  socket.on('typing', ({ channelId, isTyping }) => {
    if (!activeUser || !channelId) return;
    socket.to(channelId).emit('user_typing', {
      channelId,
      userId: activeUser.id,
      username: activeUser.username,
      isTyping: !!isTyping
    });
  });

  socket.on('typing_start', ({ channelId }) => {
    if (!activeUser || !channelId) return;
    socket.to(channelId).emit('user_typing', {
      channelId,
      userId: activeUser.id,
      username: activeUser.username,
      isTyping: true
    });
  });

  socket.on('typing_stop', ({ channelId }) => {
    if (!activeUser || !channelId) return;
    socket.to(channelId).emit('user_typing', {
      channelId,
      userId: activeUser.id,
      username: activeUser.username,
      isTyping: false
    });
  });

  // Toggle emoji reactions
  socket.on('toggle_reaction', async ({ messageId, userId, emoji, channelId }) => {
    try {
      const reactions = await db.toggleReaction({ messageId, userId, emoji });
      const targetChannel = channelId || (await db.getMessageById(messageId))?.channel_id;
      if (targetChannel) {
        io.to(targetChannel).emit('reaction_updated', {
          messageId,
          reactions,
          channelId: targetChannel
        });
      }
    } catch (err) {
      console.error('Error toggling reaction:', err);
    }
  });

  // Toggle pin message
  socket.on('toggle_pin', async ({ messageId, channelId }) => {
    try {
      const isPinned = await db.togglePinMessage(messageId);
      const targetChannel = channelId || (await db.getMessageById(messageId))?.channel_id;
      if (targetChannel) {
        io.to(targetChannel).emit('pin_toggled', {
          messageId,
          isPinned,
          channelId: targetChannel
        });
      }
    } catch (err) {
      console.error('Error toggling pin:', err);
    }
  });

  // Delete message
  socket.on('delete_message', async ({ messageId, channelId, senderId, userId }) => {
    try {
      const uId = userId || senderId;
      const msg = await db.getMessageById(messageId);
      if (msg && msg.sender_id === uId) {
        const targetChannel = channelId || msg.channel_id;
        await db.deleteMessage(messageId);
        if (targetChannel) {
          io.to(targetChannel).emit('message_deleted', { messageId, channelId: targetChannel });
        }
      }
    } catch (err) {
      console.error('Error deleting message:', err);
    }
  });

  // Update profile / status
  socket.on('update_status', async (updateData) => {
    if (!activeUser) return;
    try {
      activeUser = await db.upsertUser({
        ...activeUser,
        ...updateData
      });
      onlineUsers.set(socket.id, activeUser);
      io.emit('user_presence', {
        userId: activeUser.id,
        user: activeUser,
        online: true
      });
    } catch (err) {
      console.error('Error updating status:', err);
    }
  });

  // Disconnection
  socket.on('disconnect', async () => {
    if (activeUser) {
      onlineUsers.delete(socket.id);
      const userSocketSet = userSockets.get(activeUser.id);
      if (userSocketSet) {
        userSocketSet.delete(socket.id);
        if (userSocketSet.size === 0) {
          userSockets.delete(activeUser.id);
          // Set user offline in db
          await db.upsertUser({ id: activeUser.id, status: 'offline' });
          io.emit('user_presence', {
            userId: activeUser.id,
            user: { ...activeUser, status: 'offline' },
            online: false
          });
        }
      }
    }
  });
});

// Initialize Database and Start Server
db.initDB()
  .then(() => {
    server.listen(PORT, () => {
      const publicUrl = process.env.RAILWAY_PUBLIC_DOMAIN
        ? `https://${process.env.RAILWAY_PUBLIC_DOMAIN}`
        : `http://localhost:${PORT}`;
      console.log(`🚀 PulseChat Server running on ${publicUrl}`);
      console.log(`   data dir: ${DATA_DIR}`);
    });
  })
  .catch(err => {
    console.error('Failed to initialize database:', err);
  });
