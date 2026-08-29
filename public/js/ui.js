/* ==========================================================================
   PulseChat UI Controller & Audio Synthesizer (Minimal & Clean Theme)
   ========================================================================== */

const UI = {
  theme: localStorage.getItem('pulse_theme') || 'light',
  soundEnabled: localStorage.getItem('pulse_sound') !== 'false',
  audioCtx: null,

  init() {
    this.applyTheme(this.theme);
    this.initAudio();
    this.setupRailNavigation();
    this.setupModals();
  },

  applyTheme(theme) {
    this.theme = theme;
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('pulse_theme', theme);

    const toggle = document.getElementById('dark-mode-toggle');
    if (toggle) toggle.checked = (theme === 'dark');
  },

  toggleTheme() {
    this.applyTheme(this.theme === 'dark' ? 'light' : 'dark');
  },

  initAudio() {
    try {
      const AudioContext = window.AudioContext || window.webkitAudioContext;
      if (AudioContext) {
        this.audioCtx = new AudioContext();
      }
    } catch (e) {}
  },

  ensureAudioReady() {
    if (this.audioCtx && this.audioCtx.state === 'suspended') {
      this.audioCtx.resume();
    }
  },

  playSound(type) {
    if (!this.soundEnabled || !this.audioCtx) return;
    this.ensureAudioReady();

    const now = this.audioCtx.currentTime;
    const osc = this.audioCtx.createOscillator();
    const gain = this.audioCtx.createGain();
    osc.connect(gain);
    gain.connect(this.audioCtx.destination);

    if (type === 'sent') {
      osc.type = 'sine';
      osc.frequency.setValueAtTime(600, now);
      osc.frequency.exponentialRampToValueAtTime(900, now + 0.08);
      gain.gain.setValueAtTime(0.1, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.08);
      osc.start(now);
      osc.stop(now + 0.08);
    } else if (type === 'received') {
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(440, now);
      osc.frequency.setValueAtTime(659.25, now + 0.06);
      gain.gain.setValueAtTime(0.12, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.2);
      osc.start(now);
      osc.stop(now + 0.2);
    }
  },

  setupRailNavigation() {
    const appShell = document.getElementById('screen-app');
    const railButtons = document.querySelectorAll('.rail-btn[data-mode]');

    railButtons.forEach(btn => {
      btn.addEventListener('click', () => {
        const mode = btn.getAttribute('data-mode');
        railButtons.forEach(b => b.classList.remove('active'));
        btn.classList.add('active');

        appShell.classList.remove('mode-chats', 'mode-contacts', 'mode-settings', 'mode-profile');
        appShell.classList.add(`mode-${mode}`);
      });
    });

    // Dark mode switch
    document.getElementById('dark-mode-toggle')?.addEventListener('change', (e) => {
      this.applyTheme(e.target.checked ? 'dark' : 'light');
    });

    document.getElementById('theme-quick-toggle')?.addEventListener('click', () => {
      this.toggleTheme();
    });

    // Sounds switch
    document.getElementById('sounds-toggle')?.addEventListener('change', (e) => {
      this.soundEnabled = e.target.checked;
      localStorage.setItem('pulse_sound', this.soundEnabled);
    });

    // Mobile back button
    document.getElementById('chat-back-btn')?.addEventListener('click', () => {
      appShell.classList.remove('view-chat');
    });
  },

  setupModals() {
    const createModal = document.getElementById('create-modal');
    document.getElementById('new-chat-btn')?.addEventListener('click', () => {
      createModal?.classList.remove('hidden');
    });
    document.getElementById('close-create-modal')?.addEventListener('click', () => {
      createModal?.classList.add('hidden');
    });
    createModal?.addEventListener('click', (e) => {
      if (e.target === createModal) createModal.classList.add('hidden');
    });

    // Lightbox close
    document.getElementById('lightbox-close')?.addEventListener('click', () => {
      document.getElementById('lightbox-modal')?.classList.add('hidden');
    });
  }
};
