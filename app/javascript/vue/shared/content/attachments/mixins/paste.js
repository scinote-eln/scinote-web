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
      if (e.clipboardData && e.clipboardData.items) image = e.clipboardData.items[0];
      if (image && image.type.indexOf('image') === -1) image = null
      return image;
    },
  },
};
