/*
 * Mixin to observe and reflect DOM changes of a module's name in '.my_module-name .view-mode'.
 * - Initializes a MutationObserver to watch for modifications.
 * - Updates the `moduleName` data property on detected changes.
 */

export default {
  data() {
    return {
      observer: null,
      moduleName: '',
    };
  },
  mounted() {
    this.observeChanges();
  },
  beforeUnmount() {
    if (this.observer) {
      this.observer.disconnect();
    }
  },
  methods: {
    observeChanges() {
      const targetNode = document
        .querySelector('.my_module-name .view-mode, .my_module-name .name-readonly-placeholder');
      if (!targetNode) return;

      this.moduleName = targetNode.textContent;

      const config = { characterData: true, childList: true, subtree: true };

      const callback = (mutationsList) => {
        mutationsList.forEach((mutation) => {
          if (mutation.type === 'childList' || mutation.type === 'characterData') {
            this.moduleName = targetNode.textContent;
          }
        });
      };

      this.observer = new MutationObserver(callback);
      this.observer.observe(targetNode, config);
    },
  },
};
