<template>
  <div
    class="sci-pill-tab-group"
    :class="{ 'sci-pill-tab-group-sm': size === 'sm' }"
    role="group"
    :aria-label="ariaLabel"
  >
    <button
      v-for="(tab, index) in tabs"
      :key="tab.id"
      type="button"
      class="sci-pill-tab-item"
      :class="{ active: isSelected(tab) }"
      :aria-pressed="isSelected(tab) ? 'true' : 'false'"
      :aria-disabled="tab.disabled ? 'true' : null"
      :tabindex="tab.disabled ? -1 : 0"
      data-e2e="e2e-BT-pillTabGroup-tab"
      @mousedown="tab.disabled && $event.preventDefault()"
      @click="select(tab)"
      @keydown="onKeydown($event, index)"
    >
      <i v-if="tab.icon" class="sn-icon" :class="`sn-icon-${tab.icon}`" aria-hidden="true"></i>
      <span class="sci-pill-tab-item-label" :data-label="tab.label">
        <span class="sci-pill-tab-item-text">{{ tab.label }}</span>
      </span>
      <slot name="append" :tab="tab"></slot>
    </button>
  </div>
</template>

<script>
export default {
  name: 'PillTabGroup',
  props: {
    // [{ id, label, icon?, disabled? }]; `icon` is an SN icon font name without the `sn-icon-` prefix.
    tabs: {
      type: Array,
      required: true
    },
    modelValue: {
      type: [String, Number],
      default: null
    },
    size: {
      type: String,
      default: 'md',
      validator: (value) => ['sm', 'md'].includes(value)
    },
    // Names the group for screen readers, e.g. "Object type".
    ariaLabel: {
      type: String,
      default: null
    }
  },
  emits: ['update:modelValue'],
  // Every enabled tab is a Tab stop, so this is a group of toggle buttons (aria-pressed), not an
  // ARIA tablist. Tab, arrows, Home and End only move focus; Enter/Space (native button click) selects.
  methods: {
    isSelected(tab) {
      return tab.id === this.modelValue;
    },
    select(tab) {
      if (tab.disabled || this.isSelected(tab)) return;
      this.$emit('update:modelValue', tab.id);
    },
    enabledIndexFrom(start, step) {
      const count = this.tabs.length;
      for (let offset = 1; offset <= count; offset += 1) {
        const index = (start + (step * offset) + (count * offset)) % count;
        if (!this.tabs[index].disabled) return index;
      }
      return -1;
    },
    onKeydown(event, index) {
      // Only keys pressed on the tab itself; the append slot is for non-interactive content.
      if (event.target !== event.currentTarget) return;
      let target;
      switch (event.key) {
        case 'ArrowRight':
          target = this.enabledIndexFrom(index, 1);
          break;
        case 'ArrowLeft':
          target = this.enabledIndexFrom(index, -1);
          break;
        case 'Home':
          target = this.enabledIndexFrom(this.tabs.length - 1, 1);
          break;
        case 'End':
          target = this.enabledIndexFrom(0, -1);
          break;
        default:
          return;
      }
      event.preventDefault();
      if (target === -1) return;
      // Read the buttons from the DOM at key time, so removed or reordered tabs can't leave stale refs.
      this.$el.querySelectorAll(':scope > .sci-pill-tab-item')[target].focus();
    }
  }
};
</script>
