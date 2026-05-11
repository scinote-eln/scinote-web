export default {
  data() {
    return {
      tooltip_instances: [],
      tooltip_observer: null,
      tooltip_additionalObservers: []
    };
  },
  mounted() {
    this.tooltip_initTooltips();
    this.tooltip_setupObserver();
  },
  updated() {
    this.$nextTick(() => {
      this.tooltip_initTooltips();
    });
  },
  beforeUnmount() {
    this.tooltip_destroyTooltips();
    this.tooltip_disconnectObserver();
    this.tooltip_disconnectAdditionalObservers();
  },
  methods: {
    tooltip_getSelector() {
      return '[title], [data-sn-tooltip]';
    },

    tooltip_getObserverAttributeFilter() {
      return ['title', 'data-sn-tooltip'];
    },

    tooltip_findElementsWithTooltip(root) {
      if (!root || !root.querySelectorAll) {
        return [];
      }

      return root.querySelectorAll(this.tooltip_getSelector());
    },

    tooltip_findInitializedElements(root) {
      if (!root || !root.querySelectorAll) {
        return [];
      }

      return root.querySelectorAll('[data-sn-tooltip-initialized]');
    },

    tooltip_hasTooltipAttributes(element) {
      return element.hasAttribute('title') || element.hasAttribute('data-sn-tooltip');
    },

    tooltip_removeInstance(instance) {
      if (!instance) {
        return;
      }

      if (instance.cleanup) {
        instance.cleanup();
      }

      const index = this.tooltip_instances.indexOf(instance);
      if (index > -1) {
        this.tooltip_instances.splice(index, 1);
      }
    },

    tooltip_initializeTooltipsInContainer(container) {
      const tooltipElements = this.tooltip_findElementsWithTooltip(container);
      tooltipElements.forEach((el) => this.tooltip_initializeElement(el));

      if (this.tooltip_hasTooltipAttributes(container)) {
        this.tooltip_initializeElement(container);
      }
    },

    tooltip_getElementOwnerComponent(element) {
      if (!element || !(element instanceof HTMLElement)) {
        return null;
      }

      if (element.__vueParentComponent) {
        return element.__vueParentComponent;
      }

      let current = element.parentElement;

      while (current) {
        if (current.__vueParentComponent) {
          return current.__vueParentComponent;
        }
        current = current.parentElement;
      }

      return null;
    },

    tooltip_isOwnedByCurrentComponent(element) {
      if (!element || !(element instanceof HTMLElement)) {
        return false;
      }

      if (!this.$) {
        return true;
      }

      const ownerComponent = this.tooltip_getElementOwnerComponent(element);
      if (!ownerComponent) {
        return true;
      }

      return ownerComponent.uid === this.$.uid;
    },

    tooltip_getObservedContainers() {
      const containers = [];

      if (this.$el instanceof HTMLElement) {
        containers.push(this.$el);
      }

      this.tooltip_additionalObservers.forEach(({ element }) => {
        if (element instanceof HTMLElement) {
          containers.push(element);
        }
      });

      return containers;
    },

    tooltip_isInObservedScope(element) {
      if (!element || !(element instanceof HTMLElement)) {
        return false;
      }

      return this.tooltip_getObservedContainers().some((container) => {
        if (!(element === container || container.contains(element))) {
          return false;
        }

        return this.tooltip_isOwnedByCurrentComponent(element);
      });
    },

    // Shared mutation handler for all observers
    tooltip_handleMutations(mutations) {
      mutations.forEach((mutation) => {
        if (mutation.type === 'childList') {
          this.tooltip_handleChildListMutation(mutation);
        } else if (mutation.type === 'attributes') {
          this.tooltip_handleAttributeMutation(mutation);
        }
      });
    },

    tooltip_handleChildListMutation(mutation) {
      // Handle removed nodes
      if (mutation.removedNodes.length > 0) {
        mutation.removedNodes.forEach((removedNode) => {
          if (removedNode.nodeType === 1) {
            this.tooltip_cleanupTooltipForElement(removedNode);

            const childElements = this.tooltip_findInitializedElements(removedNode);

            childElements.forEach((childElement) => {
              this.tooltip_cleanupTooltipForElement(childElement);
            });
          }
        });
      }

      // Handle added nodes
      if (mutation.addedNodes.length > 0) {
        mutation.addedNodes.forEach((addedNode) => {
          if (addedNode.nodeType === 1) {
            this.tooltip_initializeElement(addedNode);

            const childElements = this.tooltip_findElementsWithTooltip(addedNode);

            childElements.forEach((childElement) => {
              this.tooltip_initializeElement(childElement);
            });
          }
        });
      }
    },

    tooltip_handleAttributeMutation(mutation) {
      const target = mutation.target;

      if (!this.tooltip_isInObservedScope(target)) {
        this.tooltip_cleanupTooltipForElement(target);
        return;
      }

      if (mutation.attributeName === 'title' || mutation.attributeName === 'data-sn-tooltip') {
        const existingInstance = this.tooltip_instances.find(inst => inst.element === target);

        if (existingInstance) {
          const newContent = target.getAttribute('data-sn-tooltip') || target.getAttribute('title');

          if (newContent) {
            existingInstance.content = newContent;

            if (target.hasAttribute('title')) {
              target.setAttribute('data-sn-tooltip', newContent);
              target.removeAttribute('title');
            }

            if (existingInstance.tooltipEl) {
              existingInstance.tooltipEl.textContent = newContent;
            }
          } else {
            this.tooltip_removeInstance(existingInstance);
          }
        } else {
          this.tooltip_initializeElement(target);
        }
      }
    },

    tooltip_createObserver() {
      if (typeof MutationObserver === 'undefined') {
        console.warn('Tooltip mixin: MutationObserver is not available in this browser');
        return null;
      }
      return new MutationObserver((mutations) => this.tooltip_handleMutations(mutations));
    },

    tooltip_registerTooltipContainer(element) {
      if (!element || !(element instanceof HTMLElement)) {
        return;
      }

      if (this.tooltip_additionalObservers.some(obs => obs.element === element)) {
        return;
      }

      // Initialize existing tooltips
      this.tooltip_initializeTooltipsInContainer(element);

      // Create and start observer
      const observer = this.tooltip_createObserver();
      if (!observer) {
        return; // MutationObserver not available
      }

      observer.observe(element, {
        childList: true,
        subtree: true,
        attributes: true,
        attributeFilter: this.tooltip_getObserverAttributeFilter()
      });

      this.tooltip_additionalObservers.push({ element, observer });
    },

    tooltip_unregisterTooltipContainer(element) {
      const index = this.tooltip_additionalObservers.findIndex(obs => obs.element === element);

      if (index > -1) {
        this.tooltip_additionalObservers[index].observer.disconnect();
        this.tooltip_additionalObservers.splice(index, 1);
      }
    },

    tooltip_disconnectAdditionalObservers() {
      this.tooltip_additionalObservers.forEach(({ observer }) => {
        observer.disconnect();
      });
      this.tooltip_additionalObservers = [];
    },

    tooltip_setupObserver() {
      // Check if $el exists (component has a root element)
      if (!this.$el) {
        console.warn('Tooltip mixin: Component does not have a root element ($el is undefined)');
        return;
      }

      this.tooltip_observer = this.tooltip_createObserver();
      if (!this.tooltip_observer) {
        return; // MutationObserver not available
      }

      this.tooltip_observer.observe(this.$el, {
        childList: true,
        subtree: true,
        attributes: true,
        attributeFilter: this.tooltip_getObserverAttributeFilter()
      });
    },

    tooltip_disconnectObserver() {
      if (this.tooltip_observer) {
        this.tooltip_observer.disconnect();
        this.tooltip_observer = null;
      }
    },

    tooltip_initTooltips() {
      // Check if $el exists before querying it
      if (!this.$el || !(this.$el instanceof HTMLElement)) {
        return;
      }

      this.tooltip_initializeTooltipsInContainer(this.$el);
    },

    tooltip_initializeElement(element) {
      if (!this.tooltip_isInObservedScope(element)) {
        return;
      }

      if (element.hasAttribute('data-sn-tooltip-initialized')) {
        return;
      }

      const tooltipContent = element.getAttribute('data-sn-tooltip') || element.getAttribute('title');

      if (!tooltipContent) {
        return;
      }

      element.setAttribute('data-sn-tooltip-initialized', 'true');

      if (element.hasAttribute('title')) {
        element.setAttribute('data-sn-tooltip', tooltipContent);
        element.removeAttribute('title');
      }

      const instance = {
        element,
        ownerVm: this,
        tooltipEl: null,
        content: tooltipContent,
        lastMouseX: 0,
        lastMouseY: 0,
        showDelayTimeout: null
      };

      const showTooltip = (e) => this.tooltip_showTooltip(instance, e);
      const hideTooltip = () => this.tooltip_hideTooltip(instance);
      const updatePosition = (e) => this.tooltip_updateTooltipPosition(instance, e);

      element.addEventListener('mouseenter', showTooltip);
      element.addEventListener('mouseleave', hideTooltip);
      element.addEventListener('mousemove', updatePosition);

      instance.cleanup = () => {
        element.removeEventListener('mouseenter', showTooltip);
        element.removeEventListener('mouseleave', hideTooltip);
        element.removeEventListener('mousemove', updatePosition);
        element.removeAttribute('data-sn-tooltip-initialized');
        this.tooltip_hideTooltip(instance);
      };

      this.tooltip_instances.push(instance);
    },

    tooltip_cleanupTooltipForElement(element) {
      const instance = this.tooltip_instances.find(inst => inst.element === element);
      this.tooltip_removeInstance(instance);
    },

    tooltip_getGlobalState() {
      if (typeof window === 'undefined') {
        return null;
      }

      if (!window.__snVueTooltipGlobalState) {
        window.__snVueTooltipGlobalState = {
          activeInstance: null,
          pendingInstance: null
        };
      }

      return window.__snVueTooltipGlobalState;
    },

    tooltip_cancelShowDelay(instance) {
      if (instance.showDelayTimeout) {
        clearTimeout(instance.showDelayTimeout);
        instance.showDelayTimeout = null;
      }
    },

    tooltip_cancelGlobalPending(instanceToKeep = null) {
      const globalState = this.tooltip_getGlobalState();
      if (!globalState || !globalState.pendingInstance || globalState.pendingInstance === instanceToKeep) {
        return;
      }

      const pendingInstance = globalState.pendingInstance;
      globalState.pendingInstance = null;

      if (pendingInstance.ownerVm && typeof pendingInstance.ownerVm.tooltip_cancelShowDelay === 'function') {
        pendingInstance.ownerVm.tooltip_cancelShowDelay(pendingInstance);
      } else if (pendingInstance.showDelayTimeout) {
        clearTimeout(pendingInstance.showDelayTimeout);
        pendingInstance.showDelayTimeout = null;
      }
    },

    tooltip_activateGlobalInstance(instance) {
      const globalState = this.tooltip_getGlobalState();
      if (!globalState) {
        return;
      }

      if (globalState.activeInstance && globalState.activeInstance !== instance) {
        const activeInstance = globalState.activeInstance;
        if (activeInstance.ownerVm && typeof activeInstance.ownerVm.tooltip_hideTooltip === 'function') {
          activeInstance.ownerVm.tooltip_hideTooltip(activeInstance);
        }
      }

      globalState.activeInstance = instance;
    },

    tooltip_releaseGlobalInstance(instance) {
      const globalState = this.tooltip_getGlobalState();
      if (!globalState) {
        return;
      }

      if (globalState.pendingInstance === instance) {
        globalState.pendingInstance = null;
      }

      if (globalState.activeInstance === instance) {
        globalState.activeInstance = null;
      }
    },

    tooltip_hideOtherTooltips(currentInstance) {
      this.tooltip_instances.forEach((instance) => {
        if (instance === currentInstance) {
          return;
        }

        this.tooltip_cancelShowDelay(instance);

        this.tooltip_hideTooltip(instance);
      });
    },

    tooltip_showTooltip(instance, event) {
      this.tooltip_hideOtherTooltips(instance);
      this.tooltip_cancelGlobalPending(instance);

      this.tooltip_cancelShowDelay(instance);

      instance.lastMouseX = event.clientX;
      instance.lastMouseY = event.clientY;

      if (instance.tooltipEl) {
        this.tooltip_activateGlobalInstance(instance);
        return;
      }

      const globalState = this.tooltip_getGlobalState();
      if (globalState) {
        globalState.pendingInstance = instance;
      }

      instance.showDelayTimeout = setTimeout(() => {
        instance.showDelayTimeout = null;

        if (globalState && globalState.pendingInstance === instance) {
          globalState.pendingInstance = null;
        }

        if (!instance.element.matches(':hover') || instance.tooltipEl) {
          return;
        }

        this.tooltip_activateGlobalInstance(instance);

        const tooltipEl = document.createElement('div');
        tooltipEl.className = 'vue-custom-tooltip';
        tooltipEl.style.cssText = `
          position: fixed;
          z-index: 99999;
          background-color: #000;
          color: #fff;
          padding: 6px 8px;
          border-radius: 2px;
          font-size: 12px;
          line-height: 1.4;
          max-width: 300px;
          word-wrap: break-word;
          pointer-events: none;
          opacity: 0;
          transition: opacity 0.2s ease;
          box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
        `;

        document.body.appendChild(tooltipEl);
        tooltipEl.textContent = instance.content;
        instance.tooltipEl = tooltipEl;

        this.tooltip_updateTooltipPosition(instance, {
          clientX: instance.lastMouseX,
          clientY: instance.lastMouseY
        });

        requestAnimationFrame(() => {
          tooltipEl.style.opacity = '1';
        });

      }, 500);
    },

    tooltip_hideTooltip(instance) {
      this.tooltip_cancelShowDelay(instance);
      this.tooltip_releaseGlobalInstance(instance);

      if (!instance.tooltipEl) {
        return;
      }

      instance.tooltipEl.style.opacity = '0';

      setTimeout(() => {
        if (instance.tooltipEl && instance.tooltipEl.parentNode) {
          instance.tooltipEl.parentNode.removeChild(instance.tooltipEl);
          instance.tooltipEl = null;
        }
      }, 200);
    },

    tooltip_updateTooltipPosition(instance, event) {
      instance.lastMouseX = event.clientX;
      instance.lastMouseY = event.clientY;

      if (!instance.tooltipEl) {
        return;
      }

      const tooltipEl = instance.tooltipEl;
      const offset = 10;

      const tooltipRect = tooltipEl.getBoundingClientRect();
      const tooltipWidth = tooltipRect.width;
      const tooltipHeight = tooltipRect.height;

      const viewportWidth = window.innerWidth;
      const viewportHeight = window.innerHeight;

      let left = event.clientX + offset;
      let top = event.clientY + offset;

      if (left + tooltipWidth > viewportWidth) {
        left = event.clientX - tooltipWidth - offset;
      }

      if (top + tooltipHeight > viewportHeight) {
        top = event.clientY - tooltipHeight - offset;
      }

      if (left < 0) {
        left = offset;
      }

      if (top < 0) {
        top = offset;
      }

      tooltipEl.style.left = `${left}px`;
      tooltipEl.style.top = `${top}px`;
    },

    tooltip_destroyTooltips() {
      this.tooltip_instances.forEach((instance) => {
        if (instance.cleanup) {
          instance.cleanup();
        }
      });
      this.tooltip_instances = [];
    }
  }
};
