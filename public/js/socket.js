/* ==========================================================================
   PulseChat Socket.IO Real-Time Connection Manager
   ========================================================================== */

const SocketManager = {
  socket: null,
  connected: false,

  init(user) {
    if (this.socket) {
      this.socket.disconnect();
    }

    this.socket = io({
      reconnection: true,
      reconnectionAttempts: 10,
      reconnectionDelay: 1000,
      timeout: 10000
    });

    this.setupListeners(user);
  },

  setupListeners(user) {
    this.socket.on('connect', () => {
      this.connected = true;
      console.log('⚡ Connected to PulseChat Real-Time Network');

      // Connect user session
      if (user) {
        this.socket.emit('user_connected', user);
      }
    });

    this.socket.on('session_ready', ({ user, onlineUsers }) => {
      App.onSessionReady(user, onlineUsers);
      // Join default channel
      this.joinChannel(Chat.currentChannelId);
    });

    this.socket.on('user_presence', (data) => {
      App.onUserPresence(data);
    });

    this.socket.on('new_message', (msg) => {
      Chat.onNewMessage(msg);
    });

    this.socket.on('message_updated', (msg) => {
      Chat.onMessageUpdated(msg);
    });

    this.socket.on('message_deleted', (data) => {
      Chat.onMessageDeleted(data);
    });

    this.socket.on('reaction_updated', (data) => {
      Chat.onReactionUpdated(data);
    });

    this.socket.on('pin_updated', (data) => {
      Chat.onPinUpdated(data);
    });

    this.socket.on('user_typing', (data) => {
      Chat.onUserTyping(data);
    });

    this.socket.on('channel_created', (channel) => {
      App.onChannelCreated(channel);
    });

    this.socket.on('disconnect', () => {
      this.connected = false;
      console.warn('Disconnected from PulseChat network');
    });
  },

  joinChannel(channelId) {
    if (this.socket && this.connected) {
      this.socket.emit('join_channel', { channelId });
    }
  },

  leaveChannel(channelId) {
    if (this.socket && this.connected) {
      this.socket.emit('leave_channel', { channelId });
    }
  },

  sendMessage(payload) {
    if (this.socket && this.connected) {
      this.socket.emit('send_message', payload);
    }
  },

  sendTyping(channelId, isTyping) {
    if (this.socket && this.connected && App.currentUser) {
      const event = isTyping ? 'typing_start' : 'typing_stop';
      this.socket.emit(event, {
        channelId,
        username: App.currentUser.username,
        userId: App.currentUser.id
      });
    }
  },

  toggleReaction(messageId, userId, emoji) {
    if (this.socket && this.connected) {
      this.socket.emit('toggle_reaction', { messageId, userId, emoji });
    }
  },

  togglePin(messageId) {
    if (this.socket && this.connected) {
      this.socket.emit('toggle_pin', { messageId });
    }
  },

  deleteMessage(messageId, senderId) {
    if (this.socket && this.connected) {
      this.socket.emit('delete_message', { messageId, senderId });
    }
  },

  updateStatus(statusData) {
    if (this.socket && this.connected) {
      this.socket.emit('update_status', statusData);
    }
  }
};
