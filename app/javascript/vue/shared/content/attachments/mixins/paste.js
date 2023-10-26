export default {
  data() {
    return {
      showClipboardPasteModal: false,
      pasteImages: null,
    };
  },
  mounted() {
    document.addEventListener('paste', this.handlePaste);
  },
  unmounted() {
    document.removeEventListener('paste', this.handlePaste);
  },
  methods: {
    handlePaste(e) {
      if ( e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA' ) return;
      this.pasteImages = this.getImagesFromClipboard(e);
      if (this.pasteImages && this.firstObjectInViewport()) this.showClipboardPasteModal = true;
    },
    getImagesFromClipboard(e) {
      let image = null;
      if (e.clipboardData) {
        for (let i = 0; i < e.clipboardData.items.length; i++) {
          if (e.clipboardData.items[i].type.indexOf('image') !== -1) {
            image = e.clipboardData.items[i];
          }
        }
      }
      return image;
    },
  },
};
