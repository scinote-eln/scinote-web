/* global I18n */

// One keydown listener for the whole app. Features register shortcuts here instead of
// adding their own document listeners.
//
// Keys are written like 'mod+k' or 'alt+shift+n':
//   mod   - Cmd on macOS, Ctrl elsewhere
//   alt   - Option on macOS
//   shift
// The last part is a letter, a digit or a KeyboardEvent.code name (e.g. 'Slash').
// Keys are matched by physical key (event.code), because Option changes the produced
// character on macOS and keyboard layouts differ.
//
// Every shortcut is skipped on key repeat, during IME composition and inside rich-text
// editors. By default it is also skipped while typing in a form field or while a Bootstrap
// modal is open ({ allowInInputs, allowInModals } turn that off).
// When several shortcuts match, the highest scope wins: overlay > page > global. A handler
// that returns false passes the key on to the next match.
//
// Server-rendered markup needs no JS: an element with data-shortcut="alt+shift+1" is clicked
// when those keys are pressed (if it is visible and not aria-current="page"), and gets
// aria-keyshortcuts and the shortcut in its title on every page load (see decorateShortcuts).

const SCOPES = ['global', 'page', 'overlay'];
const RICH_TEXT = '[contenteditable="true"], .mce-content-body';
const FORM_FIELDS = 'input, textarea, select';
const DECLARATIVE = '[data-shortcut]';

export const isMac = /mac|iphone|ipad/i.test(navigator.userAgentData?.platform || navigator.platform || '');

function parseKeys(keys) {
  const parts = keys.split('+');
  const key = parts.pop();
  const modifiers = parts.map((part) => part.toLowerCase());
  let code = key;
  if (/^[a-z]$/i.test(key)) code = `Key${key.toUpperCase()}`;
  if (/^\d$/.test(key)) code = `Digit${key}`;

  return {
    key: key.length === 1 ? key.toUpperCase() : key,
    code,
    mod: modifiers.includes('mod'),
    alt: modifiers.includes('alt'),
    shift: modifiers.includes('shift')
  };
}

function matches(event, combo) {
  const primary = isMac ? event.metaKey : event.ctrlKey;
  const otherPrimary = isMac ? event.ctrlKey : event.metaKey;

  return event.code === combo.code && primary === combo.mod && !otherPrimary
    && event.altKey === combo.alt && event.shiftKey === combo.shift;
}

function allowed(entry, event) {
  const target = event.target.closest ? event.target : null;
  if (target?.closest(RICH_TEXT)) return false;
  if (!entry.allowInInputs && target?.closest(FORM_FIELDS)) return false;
  if (!entry.allowInModals && document.body.classList.contains('modal-open')) return false;

  return !entry.when || entry.when();
}

function elementEntries() {
  return [...document.querySelectorAll(DECLARATIVE)]
    .filter((element) => element.getClientRects().length > 0)
    .map((element) => ({
      combo: parseKeys(element.dataset.shortcut),
      scope: 'page',
      handler: () => {
        if (element.getAttribute('aria-current') !== 'page') element.click();
      }
    }));
}

function createRegistry() {
  const entries = new Set();

  document.addEventListener('keydown', (event) => {
    if (event.repeat || event.isComposing || event.defaultPrevented) return;

    const candidates = [...entries, ...elementEntries()]
      .filter((entry) => matches(event, entry.combo) && allowed(entry, event))
      .sort((a, b) => SCOPES.indexOf(b.scope) - SCOPES.indexOf(a.scope));

    candidates.find((entry) => {
      if (entry.handler(event) === false) return false;

      event.preventDefault();
      return true;
    });
  });

  return entries;
}

function registry() {
  return window.SciNoteShortcuts.entries;
}

// Returns a function that removes the shortcut again
export function registerShortcut(keys, handler, {
  scope = 'global', when = null, allowInInputs = false, allowInModals = false
} = {}) {
  const entry = {
    combo: parseKeys(keys), handler, scope, when, allowInInputs, allowInModals
  };
  registry().add(entry);

  return () => registry().delete(entry);
}

// Visible label, e.g. '⌘K' / 'Ctrl+K' or '⌥⇧N' / 'Alt+Shift+N'
export function shortcutLabel(keys) {
  const combo = parseKeys(keys);
  if (isMac) return `${combo.alt ? '⌥' : ''}${combo.shift ? '⇧' : ''}${combo.mod ? '⌘' : ''}${combo.key}`;

  return [combo.mod && 'Ctrl', combo.alt && 'Alt', combo.shift && 'Shift', combo.key].filter(Boolean).join('+');
}

// Value for the aria-keyshortcuts attribute, e.g. 'Meta+K' / 'Control+K'
export function shortcutAria(keys) {
  const combo = parseKeys(keys);

  return [combo.mod && (isMac ? 'Meta' : 'Control'), combo.alt && 'Alt', combo.shift && 'Shift', combo.key]
    .filter(Boolean).join('+');
}

// Tooltip text with the shortcut appended, e.g. 'New step (⌥⇧N)'
export function withShortcut(label, keys) {
  return I18n.t('keyboard_shortcuts.with_shortcut', { label, shortcut: shortcutLabel(keys) });
}

// Adds aria-keyshortcuts and the shortcut label to the title of [data-shortcut] elements.
// Runs on every page load; call it for markup rendered later, e.g. an AJAX partial.
export function decorateShortcuts(root = document) {
  root.querySelectorAll(`${DECLARATIVE}:not([aria-keyshortcuts])`).forEach((element) => {
    const keys = element.dataset.shortcut;
    element.setAttribute('aria-keyshortcuts', shortcutAria(keys));
    element.setAttribute('title', element.title ? withShortcut(element.title, keys) : shortcutLabel(keys));
  });
}

// Every Vue pack is its own webpack bundle, so the registry lives on window to keep a
// single listener and a single list of shortcuts per page. It is set up on load, so
// [data-shortcut] works even where nothing registers a shortcut. Legacy scripts reach
// decorateShortcuts as window.SciNoteShortcuts.decorate.
if (!window.SciNoteShortcuts) {
  window.SciNoteShortcuts = { entries: createRegistry(), decorate: decorateShortcuts };
  document.addEventListener('turbolinks:load', () => decorateShortcuts());
}
