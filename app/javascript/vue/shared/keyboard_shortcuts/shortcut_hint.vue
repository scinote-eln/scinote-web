<template>
  <span class="text-xs text-sn-grey pointer-events-none" aria-hidden="true">{{ label }}</span>
</template>

<script>
import { shortcutLabel } from './keyboard_shortcuts.js';

// Visible shortcut hint, e.g. '⌘K'. Hidden from screen readers: put aria-keyshortcuts on
// the control instead.
export default {
  name: 'ShortcutHint',
  props: {
    keys: { type: String, required: true }
  },
  computed: {
    label() {
      return shortcutLabel(this.keys);
    }
  }
};
</script>
