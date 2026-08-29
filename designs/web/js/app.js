// ---------------------------------------------------------------------------
// Demo data
// ---------------------------------------------------------------------------

const conversations = [
  { id: 1, initials: 'RM', color: '#8A5A2B', bg: '#F1E4D8', name: 'Riya Mehta', preview: 'Sounds good, see you then!', time: '09:41', unread: 2, online: true, active: true },
  { id: 2, initials: 'DS', color: '#2E6B5E', bg: '#DCEFE9', name: 'Dev Sharma', preview: 'Sent the files over, check inbox', time: '09:12', unread: 0, online: true },
  { id: 3, initials: 'TW', color: '#5B4B8A', bg: '#E7E1F5', name: 'Team · Work', preview: 'Aria: standup moved to 11am', time: 'Yesterday', unread: 5, online: false },
  { id: 4, initials: 'AK', color: '#8A2B4A', bg: '#F5DDE5', name: 'Aditi Kapoor', preview: 'Haha yes exactly 😄', time: 'Yesterday', unread: 0, online: false },
  { id: 5, initials: 'NP', color: '#2B6B8A', bg: '#DCEBF5', name: 'Nikhil Patwari', preview: 'You: Thanks, appreciate it', time: 'Mon', unread: 0, online: false },
  { id: 6, initials: 'SG', color: '#7A6B2B', bg: '#F1EBDC', name: 'Sara Grover', preview: 'Can we push the call to 3?', time: 'Mon', unread: 0, online: true },
];

const messages = [
  { fromMe: false, text: 'Hey! Are we still on for the design review today?', time: '09:32' },
  { fromMe: true, text: "Yep, I've got the updated flows ready.", time: '09:35', read: true },
  { fromMe: true, text: 'I\'ll share the file 10 minutes before so you have time to skim it.', time: '09:35', read: true },
  { fromMe: false, text: 'Perfect. Should we do it in the usual room or on a call?', time: '09:38' },
  { fromMe: false, text: 'Sounds good, see you then!', time: '09:41' },
];

// ---------------------------------------------------------------------------
// Render conversation list
// ---------------------------------------------------------------------------

const listEl = document.getElementById('conversation-list');
conversations.forEach((c) => {
  const item = document.createElement('div');
  item.className = 'conversation-item' + (c.active ? ' active' : '');
  item.innerHTML = `
    <div class="avatar avatar-md" style="background:${c.bg};color:${c.color};">
      ${c.initials}
      ${c.online ? '<span class="status-dot online"></span>' : ''}
    </div>
    <div class="conversation-meta">
      <div class="conversation-top-row">
        <span class="conversation-name">${c.name}</span>
        <span class="mono">${c.time}</span>
      </div>
      <div class="conversation-top-row">
        <span class="conversation-preview">${c.preview}</span>
        ${c.unread ? `<span class="unread-badge">${c.unread}</span>` : ''}
      </div>
    </div>
  `;
  item.addEventListener('click', () => {
    document.querySelectorAll('.conversation-item').forEach((el) => el.classList.remove('active'));
    item.classList.add('active');
    document.getElementById('screen-app').classList.add('view-chat'); // mobile: reveal chat pane
  });
  listEl.appendChild(item);
});

// ---------------------------------------------------------------------------
// Render message stream
// ---------------------------------------------------------------------------

const readTick = (read) => `
  <svg class="read-tick ${read ? '' : 'unread'}" viewBox="0 0 24 16" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round">
    <path d="M1 8l4 4L13 4"/><path d="M9 8l4 4L21 4"/>
  </svg>`;

const streamEl = document.getElementById('message-stream');
function renderMessages() {
  streamEl.innerHTML = '<div class="day-divider">Today</div>';
  messages.forEach((m) => {
    const row = document.createElement('div');
    row.className = 'bubble-row ' + (m.fromMe ? 'sent' : 'received');
    row.innerHTML = `
      <div>
        <div class="bubble ${m.fromMe ? 'sent' : 'received'}">${m.text}</div>
        <div class="bubble-meta">
          <span class="bubble-time">${m.time}</span>
          ${m.fromMe ? readTick(m.read) : ''}
        </div>
      </div>
    `;
    streamEl.appendChild(row);
  });
  streamEl.scrollTop = streamEl.scrollHeight;
}
renderMessages();

// ---------------------------------------------------------------------------
// Send a message
// ---------------------------------------------------------------------------

const input = document.getElementById('chat-input');
const sendBtn = document.getElementById('send-btn');

function send() {
  const text = input.value.trim();
  if (!text) return;
  const now = new Date();
  const time = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  messages.push({ fromMe: true, text, time, read: false });
  input.value = '';
  input.style.height = 'auto';
  renderMessages();
}
sendBtn.addEventListener('click', send);
input.addEventListener('keydown', (e) => {
  if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); send(); }
});
input.addEventListener('input', () => {
  input.style.height = 'auto';
  input.style.height = Math.min(input.scrollHeight, 120) + 'px';
});

// ---------------------------------------------------------------------------
// Top-level screen navigation (login / signup / app)
// ---------------------------------------------------------------------------

const screens = ['login', 'signup', 'app'];
function showScreen(name) {
  screens.forEach((s) => {
    document.getElementById('screen-' + s).style.display = s === name ? '' : 'none';
  });
}
document.querySelectorAll('[data-nav]').forEach((el) => {
  el.addEventListener('click', (e) => {
    e.preventDefault();
    showScreen(el.dataset.nav);
  });
});

// ---------------------------------------------------------------------------
// Rail navigation: chats / profile / settings
// ---------------------------------------------------------------------------

const appShell = document.getElementById('screen-app');
document.querySelectorAll('[data-mode]').forEach((el) => {
  el.addEventListener('click', () => {
    const mode = el.dataset.mode;
    appShell.classList.remove('mode-chats', 'mode-profile', 'mode-settings');
    appShell.classList.add('mode-' + mode);
    document.querySelectorAll('.rail-btn[data-mode]').forEach((b) => b.classList.remove('active'));
    const railBtn = document.querySelector(`.rail-btn[data-mode="${mode}"]`);
    if (railBtn) railBtn.classList.add('active');
  });
});

// ---------------------------------------------------------------------------
// Mobile: back button returns from chat pane to list pane
// ---------------------------------------------------------------------------

document.querySelectorAll('[data-nav-back]').forEach((el) => {
  el.addEventListener('click', () => appShell.classList.remove('view-chat'));
});

// ---------------------------------------------------------------------------
// Dark mode toggle
// ---------------------------------------------------------------------------

const darkToggle = document.getElementById('dark-mode-toggle');
darkToggle.addEventListener('change', () => {
  document.documentElement.dataset.theme = darkToggle.checked ? 'dark' : 'light';
});
