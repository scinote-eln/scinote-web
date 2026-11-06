// Every keyboard shortcut in SciNote, in one place so clashes are easy to spot.
// Syntax: see keyboard_shortcuts.js.

export default {
  SEARCH: 'mod+k',
  // Item card: jump to the Nth section, n = 1..9
  ITEM_CARD_SECTION: (n) => `alt+shift+${n}`
};
