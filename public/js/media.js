/* ==========================================================================
   PulseChat Media & File Sharing (Clean UI Kit)
   ========================================================================== */

const MediaManager = {
  pendingFiles: [],

  init() {
    this.setupFileInputs();
    this.setupClipboardPaste();
    this.setupDragAndDrop();
  },

  setupFileInputs() {
    const fileInput = document.getElementById('file-input');
    const attachBtn = document.getElementById('attach-btn');

    attachBtn?.addEventListener('click', () => fileInput?.click());
    fileInput?.addEventListener('change', (e) => {
      if (e.target.files && e.target.files.length > 0) {
        this.addFiles(Array.from(e.target.files));
        fileInput.value = '';
      }
    });
  },

  setupClipboardPaste() {
    window.addEventListener('paste', (e) => {
      const items = (e.clipboardData || e.originalEvent.clipboardData).items;
      const files = [];

      for (let i = 0; i < items.length; i++) {
        if (items[i].kind === 'file') {
          const file = items[i].getAsFile();
          if (file) {
            const ext = file.type.split('/')[1] || 'png';
            files.push(new File([file], `screenshot-${Date.now()}.${ext}`, { type: file.type }));
          }
        }
      }

      if (files.length > 0) {
        this.addFiles(files);
      }
    });
  },

  setupDragAndDrop() {
    const chatPane = document.getElementById('chat-pane');
    if (!chatPane) return;

    ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
      chatPane.addEventListener(eventName, (e) => {
        e.preventDefault();
        e.stopPropagation();
      }, false);
    });

    chatPane.addEventListener('drop', (e) => {
      if (e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files.length > 0) {
        this.addFiles(Array.from(e.dataTransfer.files));
      }
    });
  },

  addFiles(files) {
    this.pendingFiles.push(...files);
    this.renderPendingShelf();
  },

  removeFile(index) {
    this.pendingFiles.splice(index, 1);
    this.renderPendingShelf();
  },

  clearPending() {
    this.pendingFiles = [];
    this.renderPendingShelf();
  },

  renderPendingShelf() {
    const shelf = document.getElementById('pending-shelf');
    if (!shelf) return;

    if (this.pendingFiles.length === 0) {
      shelf.classList.add('hidden');
      shelf.innerHTML = '';
      return;
    }

    shelf.classList.remove('hidden');
    shelf.innerHTML = this.pendingFiles.map((file, idx) => {
      const isImg = file.type.startsWith('image/');
      const src = isImg ? URL.createObjectURL(file) : '';
      return `
        <div class="pending-thumb">
          ${isImg ? `<img src="${src}" alt="preview">` : `<span style="font-size:18px;">📄</span>`}
          <button class="remove-btn" onclick="MediaManager.removeFile(${idx})">&times;</button>
        </div>
      `;
    }).join('');
  },

  async uploadPending() {
    if (this.pendingFiles.length === 0) return [];

    const formData = new FormData();
    this.pendingFiles.forEach(file => {
      formData.append('files', file);
    });

    try {
      const response = await fetch('/api/upload', {
        method: 'POST',
        body: formData
      });

      if (!response.ok) throw new Error('Upload failed');
      const data = await response.json();
      this.clearPending();
      return data.files || [];
    } catch (err) {
      console.error('Upload failed:', err);
      return [];
    }
  },

  openLightbox(url, filename) {
    const modal = document.getElementById('lightbox-modal');
    const img = document.getElementById('lightbox-img');
    const title = document.getElementById('lightbox-title');

    img.src = url;
    title.textContent = filename || 'Photo Preview';
    modal.classList.remove('hidden');
  },

  formatBytes(bytes) {
    if (!bytes || bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
  }
};
