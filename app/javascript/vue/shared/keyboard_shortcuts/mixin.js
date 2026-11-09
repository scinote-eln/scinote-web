// Registers the shortcuts a component declares and removes them when it unmounts:
//
//   mixins: [keyboardShortcutsMixin],
//   shortcuts() {
//     return [{ keys: KEYMAP.SEARCH, handler: this.focusSearch, when: () => !!this.currentTeam }];
//   }
//
// Each entry takes the options of registerShortcut(). The helpers below are exposed to templates.

import {
  registerShortcut, shortcutLabel, shortcutAria, withShortcut
} from './keyboard_shortcuts.js';

export default {
  mounted() {
    const shortcuts = this.$options.shortcuts ? this.$options.shortcuts.call(this) : [];
    this.unregisterShortcuts = shortcuts.map(({ keys, handler, ...options }) => registerShortcut(keys, handler, options));
  },
  beforeUnmount() {
    (this.unregisterShortcuts || []).forEach((unregister) => unregister());
  },
  methods: {
    shortcutLabel,
    shortcutAria,
    withShortcut
  }
};
