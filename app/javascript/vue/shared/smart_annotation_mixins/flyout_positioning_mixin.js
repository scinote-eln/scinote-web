const FLYOUT_GAP = 18;
const VIEWPORT_MARGIN = 8;
const MAX_WIDTH = 700;
const MIN_USABLE_HEIGHT = 250;

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}

function computeFlyoutStyle(caret, viewport) {
  const width = Math.min(MAX_WIDTH, viewport.width - VIEWPORT_MARGIN * 2);
  const left = clamp(caret.left, VIEWPORT_MARGIN, viewport.width - width - VIEWPORT_MARGIN);

  const spaceBelow = viewport.height - caret.bottom - FLYOUT_GAP - VIEWPORT_MARGIN;
  const spaceAbove = caret.top - FLYOUT_GAP - VIEWPORT_MARGIN;
  const flipUp = spaceBelow < MIN_USABLE_HEIGHT && spaceAbove > spaceBelow;

  const style = {
    display: 'block',
    position: 'fixed',
    zIndex: 11110,
    overflow: 'auto',
    height: 'fit-content',
    left: `${left}px`,
    width: `${width}px`
  };
  if (flipUp) {
    style.top = 'auto';
    style.bottom = `${viewport.height - caret.top + FLYOUT_GAP}px`;
    style.maxHeight = `${Math.max(spaceAbove, MIN_USABLE_HEIGHT)}px`;
  } else {
    style.top = `${caret.bottom + FLYOUT_GAP}px`;
    style.bottom = 'auto';
    style.maxHeight = `${Math.max(spaceBelow, MIN_USABLE_HEIGHT)}px`;
  }

  return style;
}

export default {
  data() {
    return {
      position: { left: 0, top: 0, height: 0 },
      isOpen: false,
      everOpened: false,
      fieldEl: null,
      onCloseCallback: null
    };
  },
  computed: {
    positionStyle() {
      if (!this.isOpen) return { display: 'none', position: 'fixed' };

      return computeFlyoutStyle(this.position, { width: window.innerWidth, height: window.innerHeight });
    }
  },
  mounted() {
    window.SmartAnnotationFlyout = {
      open: this.open,
      close: this.close,
      reposition: this.reposition,
      isOpenFor: this.isOpenFor
    };
    this.styleObserver = new MutationObserver(() => {
      if (this.isOpen && this.$refs.flyout && this.$refs.flyout.style.display === 'none') {
        this.close();
        if (this.onCloseCallback) this.onCloseCallback();
      }
    });
    this.styleObserver.observe(this.$refs.flyout, { attributes: true, attributeFilter: ['style'] });
  },
  beforeUnmount() {
    if (this.styleObserver) this.styleObserver.disconnect();
    delete window.SmartAnnotationFlyout;
  },
  methods: {
    reposition(position) {
      this.position = position;
    },
    open(payload) {
      this.flag = payload.flag;
      this.position = payload.position;
      this.assignableMyModuleId = payload.assignableMyModuleId || null;
      this.onInsert = payload.onInsert;
      this.onCloseCallback = payload.onClose;
      this.fieldEl = payload.fieldEl;
      this.query = '';
      this.items = null;
      this.navStack = [];
      this.limitReached = false;
      this.loading = false;
      this.resetActiveIndex();

      this.isOpen = true;
      this.everOpened = true;
      this.$nextTick(() => {
        this.runQuery();
        if (this.$refs.searchInput) this.$refs.searchInput.focus();
      });
    },
    close() {
      this.isOpen = false;
      this.items = null;
    },
    isOpenFor(fieldEl) {
      return this.isOpen && this.fieldEl === fieldEl;
    },
    requestClose() {
      this.close();
      if (this.onCloseCallback) this.onCloseCallback();
    },
    closeAndRefocus() {
      const field = this.fieldEl;
      this.requestClose();
      if (field) field.focus();
    },
    onRootMousedown(e) {
      if (e.target !== this.$refs.searchInput) e.preventDefault();
    }
  }
};
