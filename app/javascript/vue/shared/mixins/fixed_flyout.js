export default {
  data() {
    return {
      overflowContainerScrollTop: 0,
      overflowContainerScrollLeft: 0
    };
  },
  watch: {
    isOpen() {
      if (this.isOpen) {
        this.$emit('open');
        this.$nextTick(() => {
          this.setPosition();
          this.overflowContainerListener();
        });
      }
    }
  },
  methods: {
    overflowContainerListener() {
      const { field, flyout } = this.$refs;

      if (!field || !flyout) return;

      const fieldRect = field.getBoundingClientRect();

      if (this.overflowContainerScrollTop !== fieldRect.top) {
        this.setPosition();
      }

      if (this.overflowContainerScrollLeft !== fieldRect.left) {
        this.setPosition();
      }

      this.overflowContainerScrollLeft = fieldRect.left;
      this.overflowContainerScrollTop = fieldRect.top;

      setTimeout(() => {
        this.overflowContainerListener();
      }, 10);
    },
    setPosition() {
      const { field, flyout } = this.$refs;

      if (!field || !flyout) return;

      const rect = field.getBoundingClientRect();
      const flyoutRect = flyout.getBoundingClientRect();
      const screenHeight = window.innerHeight;

      const windowHasScroll = document.documentElement.scrollHeight > document.documentElement.clientHeight;
      let rightScrollOffset = 0;
      const { left, width } = rect;
      const top = rect.top + rect.height;
      const bottom = screenHeight - rect.bottom + rect.height;
      const right = window.innerWidth - rect.right;
      if (windowHasScroll) {
        rightScrollOffset = 14;
      }

      if (this.fixedWidth) {
        flyout.style.width = `${width}px`;
      } else {
        flyout.style.minWidth = `${width}px`;
      }

      if (window.innerWidth - (field.x + flyoutRect.width) < 0) { // when flyout is out of screen
        flyout.style.left = 'unset';
        flyout.style.right = `${width - Math.abs(right)}px`;
      } else if (this.position === 'right') {
        flyout.style.right = `${right - rightScrollOffset}px`;
        flyout.style.left = 'unset';
      } else {
        flyout.style.left = `${left}px`;
        flyout.style.right = 'unset';
      }

      if (bottom < top) {
        flyout.style.bottom = `${bottom}px`;
        flyout.style.top = 'unset';
        flyout.style.boxShadow = '0px -16px 32px 0px rgba(16, 24, 40, 0.07)';
        flyout.style.maxHeight = `${screenHeight - bottom - 25}px`;
      } else {
        flyout.style.top = `${top}px`;
        flyout.style.bottom = 'unset';
        flyout.style.boxShadow = '';
        flyout.style.maxHeight = `${screenHeight - top - 25}px`;
      }
    }
  }
};
