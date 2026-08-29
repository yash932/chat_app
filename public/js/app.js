/* ==========================================================================
   PulseChat App Bootstrap, Auth & State Manager (Clean UI Kit)
   ========================================================================== */

const App = {
  currentUser: null,
  conversations: [],
  allUsers: [],

  async init() {
    UI.init();
    MediaManager.init();
    Chat.init();
    this.setupAuthHandlers();
    this.setupGroupCreation();

    const storedUser = localStorage.getItem('pulse_user');
    if (storedUser) {
      try {
        this.currentUser = JSON.parse(storedUser);
        this.showApp();
      } catch (e) {
        this.showSignup();
      }
    } else {
      this.showSignup();
    }
  },

  showLogin() {
    document.getElementById('screen-login').style.display = 'flex';
    document.getElementById('screen-signup').style.display = 'none';
    document.getElementById('screen-app').style.display = 'none';
  },

  showSignup() {
    document.getElementById('screen-login').style.display = 'none';
    document.getElementById('screen-signup').style.display = 'flex';
    document.getElementById('screen-app').style.display = 'none';
  },

  async showApp() {
    document.getElementById('screen-login').style.display = 'none';
    document.getElementById('screen-signup').style.display = 'none';
    document.getElementById('screen-app').style.display = 'grid';

    this.updateUserViews();
    SocketManager.init(this.currentUser);

    await this.fetchConversations();
    await this.fetchUsers();

    if (this.conversations.length > 0) {
      const first = this.conversations[0];
      Chat.loadChannel(
        first.id,
        first.display_name || first.name,
        first.description || (first.is_direct ? 'Direct conversation' : 'Group chat'),
        first.is_direct ? (first.display_name.substring(0, 2).toUpperCase()) : (first.icon || '👥')
      );
    }
  },

  setupAuthHandlers() {
    document.getElementById('go-to-signup')?.addEventListener('click', (e) => {
      e.preventDefault();
      this.showSignup();
    });

    document.getElementById('go-to-login')?.addEventListener('click', (e) => {
      e.preventDefault();
      this.showLogin();
    });

    // Login Form Submit
    document.getElementById('login-form')?.addEventListener('submit', async (e) => {
      e.preventDefault();
      const email = document.getElementById('login-email').value.trim();
      const password = document.getElementById('login-password').value;
      const errorEl = document.getElementById('login-error');
      errorEl.style.display = 'none';

      try {
        const res = await fetch('/api/auth/login', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ email, password })
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.error || 'Login failed');

        this.currentUser = data.user;
        localStorage.setItem('pulse_user', JSON.stringify(this.currentUser));
        this.showApp();
      } catch (err) {
        errorEl.textContent = err.message;
        errorEl.style.display = 'block';
      }
    });

    // Signup Form Submit
    document.getElementById('signup-form')?.addEventListener('submit', async (e) => {
      e.preventDefault();
      const name = document.getElementById('signup-name').value.trim();
      const email = document.getElementById('signup-email').value.trim();
      const password = document.getElementById('signup-password').value;
      const errorEl = document.getElementById('signup-error');
      errorEl.style.display = 'none';

      try {
        const res = await fetch('/api/auth/signup', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ username: name, email, password })
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.error || 'Signup failed');

        this.currentUser = data.user;
        localStorage.setItem('pulse_user', JSON.stringify(this.currentUser));
        this.showApp();
      } catch (err) {
        errorEl.textContent = err.message;
        errorEl.style.display = 'block';
      }
    });

    // Logout
    document.getElementById('logout-btn')?.addEventListener('click', () => {
      localStorage.removeItem('pulse_user');
      this.currentUser = null;
      this.showLogin();
    });

    // Save profile edit
    document.getElementById('save-profile-btn')?.addEventListener('click', () => {
      const name = document.getElementById('edit-profile-name').value.trim();
      const status = document.getElementById('edit-profile-status').value.trim();
      if (!name) return;

      this.currentUser.username = name;
      this.currentUser.custom_status = status;
      localStorage.setItem('pulse_user', JSON.stringify(this.currentUser));

      this.updateUserViews();
      SocketManager.updateStatus({ username: name, status: 'online', custom_status: status });
      alert('Profile saved!');
    });
  },

  updateUserViews() {
    if (!this.currentUser) return;
    const name = this.currentUser.username || 'User';
    const initials = name.substring(0, Math.min(2, name.length)).toUpperCase();

    // Prominent Home Banner User Info
    const headerName = document.getElementById('header-user-name');
    if (headerName) headerName.textContent = name;

    const headerStatus = document.getElementById('header-user-status');
    if (headerStatus) headerStatus.textContent = `● ${this.currentUser.custom_status || 'Online'}`;

    const headerAvatar = document.getElementById('header-user-avatar');
    if (headerAvatar) headerAvatar.innerHTML = `${initials}<span class="status-dot online"></span>`;

    // Rail Avatar
    const railAvatar = document.getElementById('rail-user-avatar');
    if (railAvatar) railAvatar.textContent = initials;

    // Profile Screen
    const profileAvatar = document.getElementById('profile-avatar-display');
    if (profileAvatar) profileAvatar.innerHTML = `${initials}<span class="status-dot online" style="width:16px;height:16px;right:2px;bottom:2px;"></span>`;

    const profileName = document.getElementById('profile-display-name');
    if (profileName) profileName.textContent = name;

    const profileStatus = document.getElementById('profile-display-status');
    if (profileStatus) profileStatus.textContent = `@${name.toLowerCase().replace(/\s+/g, '')} · ${this.currentUser.custom_status || 'Active'}`;

    const editName = document.getElementById('edit-profile-name');
    if (editName) editName.value = name;

    const editStatus = document.getElementById('edit-profile-status');
    if (editStatus) editStatus.value = this.currentUser.custom_status || '';
  },

  async fetchConversations() {
    if (!this.currentUser) return;
    try {
      const res = await fetch(`/api/users/${this.currentUser.id}/conversations`);
      this.conversations = await res.json();
      this.renderConversationList();
    } catch (e) {}
  },

  async fetchUsers() {
    try {
      const res = await fetch('/api/users');
      this.allUsers = await res.json();
      this.renderActiveMembers();
      this.renderGroupMembersPicker();
    } catch (e) {}
  },

  renderConversationList() {
    const container = document.getElementById('conversation-list');
    if (!container) return;

    const dms = this.conversations.filter(c => c.is_direct === 1);
    const groups = this.conversations.filter(c => c.is_direct === 0);
    const otherUsers = this.allUsers.filter(u => u.id !== this.currentUser?.id);

    let html = '';

    // Direct Messages with messages or active conversations
    if (dms.length > 0) {
      html += '<div class="conversation-section-label">Active Chats</div>';
      dms.forEach(dm => {
        const isActive = dm.id === Chat.currentChannelId;
        const otherName = dm.display_name || 'User';
        const initials = otherName.substring(0, Math.min(2, otherName.length)).toUpperCase();
        html += `
          <div class="conversation-item ${isActive ? 'active' : ''}" data-id="${dm.id}" onclick="App.selectConversation('${dm.id}', '${this.escapeAttr(otherName)}', '${this.escapeAttr(dm.other_custom_status || 'Direct conversation')}', '${initials}')">
            <div class="avatar avatar-md" style="background:#F1E4D8;color:#8A5A2B;">
              ${initials}
              <span class="status-dot ${dm.other_status || 'offline'}"></span>
            </div>
            <div class="conversation-meta">
              <div class="conversation-top-row">
                <div class="conversation-name">${this.escapeHtml(otherName)}</div>
              </div>
              <div class="conversation-preview">${this.escapeHtml(dm.last_message_text || dm.other_custom_status || 'Direct conversation')}</div>
            </div>
          </div>
        `;
      });
    }

    // Groups
    if (groups.length > 0) {
      html += '<div class="conversation-section-label" style="margin-top:10px;">Groups</div>';
      groups.forEach(grp => {
        const isActive = grp.id === Chat.currentChannelId;
        html += `
          <div class="conversation-item ${isActive ? 'active' : ''}" data-id="${grp.id}" onclick="App.selectConversation('${grp.id}', '${this.escapeAttr(grp.name)}', '${this.escapeAttr(grp.description || 'Group chat')}', '${grp.icon || '👥'}')">
            <div class="avatar avatar-md" style="background:var(--color-cobalt-tint);color:var(--color-cobalt);">
              ${grp.icon || '👥'}
            </div>
            <div class="conversation-meta">
              <div class="conversation-top-row">
                <div class="conversation-name">${this.escapeHtml(grp.name)}</div>
              </div>
              <div class="conversation-preview">${this.escapeHtml(grp.last_message_text || grp.description || 'Group conversation')}</div>
            </div>
          </div>
        `;
      });
    }

    // Members list for quick 1-on-1 chatting
    if (otherUsers.length > 0) {
      html += `<div class="conversation-section-label" style="margin-top:12px;">Active Members (${otherUsers.filter(u => u.status === 'online').length} online)</div>`;
      otherUsers.forEach(user => {
        const initials = (user.username || 'U').substring(0, Math.min(2, user.username.length)).toUpperCase();
        html += `
          <div class="conversation-item" style="cursor:pointer;" onclick="App.startDM('${user.id}', '${this.escapeAttr(user.username)}')">
            <div class="avatar avatar-md" style="background:var(--color-cobalt-tint);color:var(--color-cobalt);">
              ${initials}
              <span class="status-dot ${user.status || 'offline'}"></span>
            </div>
            <div class="conversation-meta">
              <div class="conversation-top-row">
                <div class="conversation-name">${this.escapeHtml(user.username)}</div>
                <span style="font-size:11px;color:${user.status === 'online' ? 'var(--color-signal-green)' : 'var(--color-ink-tertiary)'};font-weight:600;">
                  ${user.status === 'online' ? 'Online' : 'Offline'}
                </span>
              </div>
              <div class="conversation-preview">${this.escapeHtml(user.custom_status || 'Click to direct chat')}</div>
            </div>
          </div>
        `;
      });
    } else if (dms.length === 0 && groups.length === 0) {
      html = `
        <div style="padding:28px 16px;text-align:center;color:var(--color-ink-tertiary);">
          <div style="font-size:24px;margin-bottom:8px;">👋</div>
          <p style="font-weight:600;margin-bottom:4px;color:var(--color-ink);">No other users signed up yet</p>
          <p style="font-size:13px;">When other users sign up or log in, they will appear here as active and you can chat with them directly.</p>
        </div>
      `;
    }

    container.innerHTML = html;
  },

  selectConversation(id, name, desc, icon) {
    Chat.loadChannel(id, name, desc, icon);
  },

  renderActiveMembers() {
    const container = document.getElementById('active-members-list-pane');
    if (!container) return;

    const otherUsers = this.allUsers.filter(u => u.id !== this.currentUser?.id);

    if (otherUsers.length === 0) {
      container.innerHTML = `<div style="padding:20px;text-align:center;color:var(--color-ink-secondary);">No other members registered yet</div>`;
      return;
    }

    container.innerHTML = otherUsers.map(user => {
      const initials = (user.username || 'U').substring(0, Math.min(2, user.username.length)).toUpperCase();
      const isOnline = user.status === 'online';
      return `
        <div class="setting-row" style="cursor:pointer;" onclick="App.startDM('${user.id}', '${this.escapeAttr(user.username)}')">
          <div class="avatar avatar-md" style="background:var(--color-cobalt-tint);color:var(--color-cobalt);">
            ${initials}
            <span class="status-dot ${isOnline ? 'online' : 'offline'}"></span>
          </div>
          <div class="setting-row-text">
            <div class="setting-row-title">${this.escapeHtml(user.username)}</div>
            <div class="setting-row-desc">
              <span style="color:${isOnline ? 'var(--color-signal-green)' : 'var(--color-ink-tertiary)'};font-weight:600;">${isOnline ? '● Online' : '○ Offline'}</span>
              ${user.custom_status ? ` · ${this.escapeHtml(user.custom_status)}` : ''}
            </div>
          </div>
          <button class="btn btn-primary btn-ghost" style="font-size:12px;padding:4px 12px;">Chat</button>
        </div>
      `;
    }).join('');
  },

  renderGroupMembersPicker() {
    const container = document.getElementById('group-members-picker');
    if (!container) return;

    const otherUsers = this.allUsers.filter(u => u.id !== this.currentUser?.id);
    if (otherUsers.length === 0) {
      container.innerHTML = '<div style="font-size:12px;color:var(--color-ink-tertiary);">No other users available</div>';
      return;
    }

    container.innerHTML = otherUsers.map(u => `
      <label style="display:flex;align-items:center;gap:8px;padding:4px 0;font-size:13px;cursor:pointer;">
        <input type="checkbox" name="group-member" value="${u.id}" />
        <span>${this.escapeHtml(u.username)}</span>
      </label>
    `).join('');
  },

  setupGroupCreation() {
    const modal = document.getElementById('create-group-modal');
    document.getElementById('new-group-btn')?.addEventListener('click', () => {
      this.renderGroupMembersPicker();
      modal?.classList.remove('hidden');
    });

    document.getElementById('close-group-modal')?.addEventListener('click', () => {
      modal?.classList.add('hidden');
    });

    document.getElementById('submit-group-btn')?.addEventListener('click', async () => {
      const name = document.getElementById('new-group-name').value.trim();
      const desc = document.getElementById('new-group-desc').value.trim();
      if (!name) return;

      const checked = Array.from(document.querySelectorAll('input[name="group-member"]:checked')).map(cb => cb.value);

      try {
        const res = await fetch('/api/groups', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            name,
            description: desc,
            icon: '👥',
            memberIds: checked,
            createdById: this.currentUser?.id
          })
        });
        const grp = await res.json();
        modal.classList.add('hidden');
        document.getElementById('new-group-name').value = '';
        document.getElementById('new-group-desc').value = '';
        await this.fetchConversations();
        this.selectConversation(grp.id, grp.name, grp.description, grp.icon);
      } catch (e) {}
    });
  },

  async startDM(otherUserId, otherUsername) {
    if (!this.currentUser) return;
    try {
      const res = await fetch('/api/direct-messages', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ user1Id: this.currentUser.id, user2Id: otherUserId })
      });
      const dm = await res.json();
      await this.fetchConversations();

      document.querySelector('.rail-btn[data-mode="chats"]')?.click();
      this.selectConversation(dm.id, otherUsername, 'Direct conversation', otherUsername.substring(0, 2).toUpperCase());
    } catch (e) {}
  },

  onSessionReady(user, onlineUsers) {
    if (onlineUsers && onlineUsers.length > 0) {
      onlineUsers.forEach(ou => {
        const idx = this.allUsers.findIndex(u => u.id === ou.id);
        if (idx !== -1) {
          this.allUsers[idx] = { ...this.allUsers[idx], ...ou, status: 'online' };
        } else {
          this.allUsers.push({ ...ou, status: 'online' });
        }
      });
    }
    this.renderActiveMembers();
    this.renderConversationList();
  },

  onUserPresence({ userId, user, online }) {
    const idx = this.allUsers.findIndex(u => u.id === userId);
    if (online) {
      if (idx !== -1) this.allUsers[idx] = { ...this.allUsers[idx], ...user, status: 'online' };
      else if (user) this.allUsers.push({ ...user, status: 'online' });
    } else {
      if (idx !== -1) this.allUsers[idx].status = 'offline';
    }
    this.renderActiveMembers();
    this.renderConversationList();

    // If currently chatting with this user, update status in topbar
    if (user && Chat.currentChannelName === user.username) {
      const headerStatus = document.getElementById('chat-header-status');
      if (headerStatus) {
        headerStatus.textContent = online ? '● Online' : '○ Offline';
      }
    }
  },

  escapeHtml(str) {
    if (!str) return '';
    return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  },

  escapeAttr(str) {
    if (!str) return '';
    return str.replace(/"/g, '&quot;').replace(/'/g, '&#039;');
  }
};

document.addEventListener('DOMContentLoaded', () => {
  App.init();
});
