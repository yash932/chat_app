/* ==========================================================================
   PulseChat Message & Conversation Controller (Clean UI Kit)
   ========================================================================== */

const Chat = {
  currentChannelId: null,
  currentChannelName: '',
  messages: [],
  replyingToMessage: null,

  init() {
    this.setupInputHandlers();
    this.setupFilterSearch();
  },

  setupInputHandlers() {
    const textarea = document.getElementById('chat-input');
    const sendBtn = document.getElementById('send-btn');

    textarea?.addEventListener('input', () => {
      textarea.style.height = 'auto';
      textarea.style.height = Math.min(textarea.scrollHeight, 120) + 'px';
      if (this.currentChannelId) {
        SocketManager.sendTyping(this.currentChannelId, true);
      }
    });

    textarea?.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        this.submitMessage();
      }
    });

    sendBtn?.addEventListener('click', () => {
      this.submitMessage();
    });
  },

  async submitMessage() {
    if (!this.currentChannelId) {
      alert('Please select a conversation or group first.');
      return;
    }

    const textarea = document.getElementById('chat-input');
    const text = textarea.value.trim();
    const hasPending = MediaManager.pendingFiles.length > 0;

    if (!text && !hasPending) return;

    let attachments = [];
    if (hasPending) {
      attachments = await MediaManager.uploadPending();
    }

    const payload = {
      channelId: this.currentChannelId,
      senderId: App.currentUser.id,
      text: text,
      replyToId: this.replyingToMessage ? this.replyingToMessage.id : null,
      attachments: attachments
    };

    SocketManager.sendMessage(payload);

    textarea.value = '';
    textarea.style.height = 'auto';
    this.replyingToMessage = null;
    UI.playSound('sent');
  },

  async loadChannel(channelId, channelName, description = '', icon = '💬') {
    this.currentChannelId = channelId;
    this.currentChannelName = channelName;

    // Update Header
    document.getElementById('chat-header-name').textContent = channelName;
    document.getElementById('chat-header-status').textContent = description || 'Direct conversation or group chat';
    document.getElementById('chat-header-avatar').textContent = icon;

    // Mobile view switch
    document.getElementById('screen-app')?.classList.add('view-chat');

    // Update list active states
    document.querySelectorAll('.conversation-item').forEach(item => {
      item.classList.toggle('active', item.getAttribute('data-id') === channelId);
    });

    SocketManager.joinChannel(channelId);

    const stream = document.getElementById('message-stream');
    stream.innerHTML = '<div style="text-align:center;padding:40px;color:var(--color-ink-tertiary);">Loading messages…</div>';

    try {
      const res = await fetch(`/api/channels/${channelId}/messages`);
      this.messages = await res.json();
      this.renderMessages();
      this.scrollToBottom();
    } catch (err) {
      stream.innerHTML = '<div style="text-align:center;padding:40px;color:var(--color-coral);">Failed to load messages.</div>';
    }
  },

  renderMessages() {
    const stream = document.getElementById('message-stream');
    stream.innerHTML = '';

    if (this.messages.length === 0) {
      stream.innerHTML = `
        <div style="text-align:center;padding:40px;color:var(--color-ink-tertiary);">
          <p style="font-weight:600;margin-bottom:4px;color:var(--color-ink);">No messages yet</p>
          <p style="font-size:13px;">Send a message to start the conversation.</p>
        </div>
      `;
      return;
    }

    let lastDate = null;

    this.messages.forEach(msg => {
      const msgDate = new Date(msg.created_at || Date.now());
      const dateStr = this.formatDateDivider(msgDate);

      if (dateStr !== lastDate) {
        lastDate = dateStr;
        const div = document.createElement('div');
        div.className = 'day-divider';
        div.textContent = dateStr;
        stream.appendChild(div);
      }

      const row = this.createMessageBubble(msg);
      stream.appendChild(row);
    });
  },

  createMessageBubble(msg) {
    const isSelf = App.currentUser && msg.sender_id === App.currentUser.id;
    const row = document.createElement('div');
    row.className = `bubble-row ${isSelf ? 'sent' : 'received'}`;
    row.id = `msg-${msg.id}`;

    const timeStr = this.formatTime(new Date(msg.created_at || Date.now()));

    // Quoted reply
    let replyHtml = '';
    if (msg.replyTo) {
      replyHtml = `
        <div class="reply-quote">
          <strong>@${this.escapeHtml(msg.replyTo.sender_name || 'User')}</strong>: ${this.escapeHtml(msg.replyTo.text || '[Attachment]')}
        </div>
      `;
    }

    // Attachments
    let attHtml = '';
    if (msg.attachments && msg.attachments.length > 0) {
      msg.attachments.forEach(att => {
        if (att.mimetype && att.mimetype.startsWith('image/')) {
          attHtml += `
            <img src="${att.url}" alt="${this.escapeHtml(att.original_name)}" class="bubble-attachment-img" onclick="MediaManager.openLightbox('${att.url}', '${this.escapeHtml(att.original_name)}')" />
          `;
        } else {
          attHtml += `
            <a href="${att.url}" download="${this.escapeHtml(att.original_name)}" class="bubble-attachment-file">
              <span>📄</span>
              <span style="font-weight:500;">${this.escapeHtml(att.original_name)}</span>
              <span class="mono">${MediaManager.formatBytes(att.size)}</span>
            </a>
          `;
        }
      });
    }

    // Reactions
    let rxHtml = '';
    if (msg.reactions && msg.reactions.length > 0) {
      const counts = {};
      msg.reactions.forEach(r => counts[r.emoji] = (counts[r.emoji] || 0) + 1);
      rxHtml = '<div class="bubble-reactions">';
      Object.entries(counts).forEach(([emoji, count]) => {
        rxHtml += `
          <button class="reaction-chip" onclick="Chat.toggleReaction('${msg.id}', '${emoji}')">
            ${emoji} <span class="mono">${count}</span>
          </button>
        `;
      });
      rxHtml += '</div>';
    }

    row.innerHTML = `
      <div class="bubble-wrapper">
        <div class="bubble ${isSelf ? 'sent' : 'received'}">
          ${!isSelf ? `<div style="font-size:11.5px;font-weight:600;margin-bottom:2px;color:var(--color-cobalt);">@${this.escapeHtml(msg.sender_name || 'User')}</div>` : ''}
          ${replyHtml}
          ${msg.text ? `<div>${this.parseMarkdown(msg.text)}</div>` : ''}
          ${attHtml}
        </div>
        <div class="bubble-meta">
          <span class="bubble-time">${timeStr}</span>
          ${isSelf ? `
            <svg class="read-tick" width="13" height="13" viewBox="0 0 16 16" fill="currentColor">
              <path d="M12.736 3.97a.733.733 0 0 1 1.047 0c.286.289.29.756.01 1.05L7.88 12.01a.733.733 0 0 1-1.065.02L3.217 8.384a.757.757 0 0 1 0-1.06.733.733 0 0 1 1.047 0l3.052 3.093 5.4-6.425a.247.247 0 0 1 .02-.022Z"/>
            </svg>
          ` : ''}
        </div>
        <div class="bubble-actions">
          <button onclick="Chat.toggleReaction('${msg.id}', '❤️')">❤️</button>
          <button onclick="Chat.toggleReaction('${msg.id}', '🔥')">🔥</button>
          <button onclick="Chat.toggleReaction('${msg.id}', '👍')">👍</button>
          <button onclick="Chat.startReply('${msg.id}')">Reply</button>
          ${isSelf ? `<button onclick="Chat.deleteMessage('${msg.id}')" style="color:var(--color-coral)">Delete</button>` : ''}
        </div>
        ${rxHtml}
      </div>
    `;

    return row;
  },

  startReply(messageId) {
    const msg = this.messages.find(m => m.id === messageId);
    if (!msg) return;
    this.replyingToMessage = msg;
    const input = document.getElementById('chat-input');
    input.placeholder = `Replying to @${msg.sender_name || 'User'}…`;
    input.focus();
  },

  toggleReaction(messageId, emoji) {
    if (!App.currentUser) return;
    SocketManager.toggleReaction(messageId, App.currentUser.id, emoji);
  },

  deleteMessage(messageId) {
    if (!App.currentUser) return;
    SocketManager.deleteMessage(messageId, App.currentUser.id);
  },

  onNewMessage(msg) {
    if (msg.channel_id === this.currentChannelId) {
      const wasEmpty = this.messages.length === 0;
      this.messages.push(msg);
      if (wasEmpty) {
        this.renderMessages();
      } else {
        const stream = document.getElementById('message-stream');
        const row = this.createMessageBubble(msg);
        stream.appendChild(row);
      }
      this.scrollToBottom();

      if (App.currentUser && msg.sender_id !== App.currentUser.id) {
        UI.playSound('received');
      }
    }
    // Always refresh conversations to update last message preview and active list
    App.fetchConversations();
  },

  onMessageDeleted({ messageId, channelId }) {
    if (channelId === this.currentChannelId) {
      this.messages = this.messages.filter(m => m.id !== messageId);
      document.getElementById(`msg-${messageId}`)?.remove();
    }
  },

  onReactionUpdated({ messageId, reactions, channelId }) {
    if (channelId === this.currentChannelId) {
      const msg = this.messages.find(m => m.id === messageId);
      if (msg) {
        msg.reactions = reactions;
        const existingEl = document.getElementById(`msg-${messageId}`);
        if (existingEl) {
          const newEl = this.createMessageBubble(msg);
          existingEl.replaceWith(newEl);
        }
      }
    }
  },

  scrollToBottom() {
    const stream = document.getElementById('message-stream');
    if (stream) {
      // Natural instant scroll without animation jumps
      stream.scrollTop = stream.scrollHeight;
    }
  },

  setupFilterSearch() {
    const input = document.getElementById('filter-search-input');
    input?.addEventListener('input', (e) => {
      const q = e.target.value.toLowerCase().trim();
      document.querySelectorAll('.conversation-item').forEach(item => {
        const text = item.textContent.toLowerCase();
        item.style.display = text.includes(q) ? 'flex' : 'none';
      });
    });
  },

  escapeHtml(str) {
    if (!str) return '';
    return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  },

  parseMarkdown(text) {
    if (!text) return '';
    let p = this.escapeHtml(text);
    p = p.replace(/```([\s\S]*?)```/g, '<pre><code>$1</code></pre>');
    p = p.replace(/`([^`]+)`/g, '<code>$1</code>');
    p = p.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
    p = p.replace(/\*([^*]+)\*/g, '<em>$1</em>');
    p = p.replace(/\[([^\]]+)\]\((https?:\/\/[^\s)]+)\)/g, '<a href="$2" target="_blank" rel="noopener noreferrer">$1</a>');
    return p;
  },

  formatTime(date) {
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  },

  formatDateDivider(date) {
    const today = new Date();
    const yesterday = new Date();
    yesterday.setDate(today.getDate() - 1);
    if (date.toDateString() === today.toDateString()) return 'Today';
    if (date.toDateString() === yesterday.toDateString()) return 'Yesterday';
    return date.toLocaleDateString([], { month: 'short', day: 'numeric' });
  }
};
