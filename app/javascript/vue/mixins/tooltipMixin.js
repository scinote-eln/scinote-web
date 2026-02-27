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

            const childElements = removedNode.querySelectorAll ?
              removedNode.querySelectorAll('[data-tooltip-initialized]') : [];

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

            const childElements = addedNode.querySelectorAll ?
              addedNode.querySelectorAll('[title], [data-tooltip]') : [];

            childElements.forEach((childElement) => {
              this.tooltip_initializeElement(childElement);
            });
          }
        });
      }
    },

    tooltip_handleAttributeMutation(mutation) {
      const target = mutation.target;
      if (mutation.attributeName === 'title' || mutation.attributeName === 'data-tooltip') {
        const existingInstance = this.tooltip_instances.find(inst => inst.element === target);

        if (existingInstance) {
          const newContent = target.getAttribute('data-tooltip') || target.getAttribute('title');

          if (newContent) {
            existingInstance.content = newContent;

            if (target.hasAttribute('title')) {
              target.setAttribute('data-tooltip', newContent);
              target.removeAttribute('title');
            }

            if (existingInstance.tooltipEl) {
              existingInstance.tooltipEl.textContent = newContent;
            }
          } else {
            // Content removed, cleanup
            if (existingInstance.cleanup) {
              existingInstance.cleanup();
            }
            const index = this.tooltip_instances.indexOf(existingInstance);
            if (index > -1) {
              this.tooltip_instances.splice(index, 1);
            }
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
      const tooltipElements = element.querySelectorAll('[title], [data-tooltip]');
      tooltipElements.forEach((el) => this.tooltip_initializeElement(el));

      if (element.hasAttribute('title') || element.hasAttribute('data-tooltip')) {
        this.tooltip_initializeElement(element);
      }

      // Create and start observer
      const observer = this.tooltip_createObserver();
      if (!observer) {
        return; // MutationObserver not available
      }

      observer.observe(element, {
        childList: true,
        subtree: true,
        attributes: true,
        attributeFilter: ['title', 'data-tooltip']
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
        attributeFilter: ['title', 'data-tooltip']
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
      if (!this.$el) {
        return;
      }

      const tooltipElements = this.$el.querySelectorAll('[title], [data-tooltip]');
      tooltipElements.forEach((el) => this.tooltip_initializeElement(el));
    },

    tooltip_initializeElement(element) {
      if (element.hasAttribute('data-tooltip-initialized')) {
        return;
      }

      const tooltipContent = element.getAttribute('data-tooltip') || element.getAttribute('title');

      if (!tooltipContent) {
        return;
      }

      element.setAttribute('data-tooltip-initialized', 'true');

      if (element.hasAttribute('title')) {
        element.setAttribute('data-tooltip', tooltipContent);
        element.removeAttribute('title');
      }

      const instance = {
        element,
        tooltipEl: null,
        content: tooltipContent
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
        element.removeAttribute('data-tooltip-initialized');
        this.tooltip_hideTooltip(instance);
      };

      this.tooltip_instances.push(instance);
    },

    tooltip_cleanupTooltipForElement(element) {
      const instance = this.tooltip_instances.find(inst => inst.element === element);

      if (instance) {
        if (instance.cleanup) {
          instance.cleanup();
        }

        const index = this.tooltip_instances.indexOf(instance);
        if (index > -1) {
          this.tooltip_instances.splice(index, 1);
        }
      }
    },

    tooltip_showTooltip(instance, event) {
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

      this.tooltip_updateTooltipPosition(instance, event);

      requestAnimationFrame(() => {
        tooltipEl.style.opacity = '1';
      });
    },

    tooltip_hideTooltip(instance) {
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
