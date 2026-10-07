/* global AtWhoFieldAdapter AtWhoMatchers */

// Smart annotation ("@mention"/"#reference") autocomplete controller. This module owns trigger
// matching, caret tracking and text insertion (see atwho_field_adapter.js and
// atwho_matchers.js). Searching, browsing, selection, building the inserted tag text and
// "assign to task" all happen inside the popup itself, a globally-mounted Vue component
// (app/javascript/vue/shared/smart_annotation_flyout.vue) driven imperatively through
// `window.SmartAnnotationFlyout` - see app/javascript/packs/vue/smart_annotation_flyout.js. This
// module only ever receives back a ready-made string to insert - it has no knowledge of item
// shape, tag format, or backend routes/requests.
var SmartAnnotation = (function() {
  'use strict';

  var REPOSITION_INTERVAL_MS = 50;

  var session = null; // { adapter, field, flag, matchLength }
  var repositionTimer = null;

  // ---- session (currently open flyout) -------------------------------------------------------
  // `session` is a singleton: only one field can have an open flyout at a time. There's no more
  // "update the open session in place" case (see openFlyout below) - the query is typed into the
  // flyout's own search box now, not the host field, so every trigger keystroke is a fresh open.

  function stopRepositionLoop() {
    if (repositionTimer) {
      clearInterval(repositionTimer);
      repositionTimer = null;
    }
  }

  function startRepositionLoop() {
    stopRepositionLoop();
    repositionTimer = setInterval(function() {
      if (!session || !window.SmartAnnotationFlyout) return;
      var rect = session.adapter.getCaretRect();
      if (rect) window.SmartAnnotationFlyout.reposition(rect);
    }, REPOSITION_INTERVAL_MS);
  }

  function closeSession() {
    stopRepositionLoop();
    if (session && window.SmartAnnotationFlyout) window.SmartAnnotationFlyout.close();
    session = null;
  }

  // `tagText` is the ready-made string to insert (e.g. '[@Jane Doe~42]' or '[#Sample~tsk~7]') -
  // the flyout built it, this just places it in the field.
  function confirmSelection(tagText) {
    if (!session || !tagText) return;

    var adapter = session.adapter;
    adapter.insertAtCaret(tagText, session.matchLength);
    closeSession();
    adapter.focus();
  }

  function openFlyout(adapter, field, flag, assignableMyModuleId) {
    session = {
      adapter: adapter,
      field: field,
      flag: flag,
      matchLength: flag.length
    };

    var rect = adapter.getCaretRect();
    if (!rect) { closeSession(); return; }

    if (!window.SmartAnnotationFlyout) return; // pack not mounted yet - defensive no-op

    window.SmartAnnotationFlyout.open({
      flag: flag,
      fieldEl: field,
      position: rect,
      assignableMyModuleId: assignableMyModuleId,
      onInsert: confirmSelection,
      onClose: function() { session = null; stopRepositionLoop(); }
    });
    startRepositionLoop();
  }

  // ---- per-field keystroke controller ---------------------------------------------------------

  // True when `field` is the one the currently-open (or just-closed) session belongs to.
  function isSessionFor(field) {
    return !!(session && session.field === field);
  }

  function isFlyoutOpenFor(field) {
    return isSessionFor(field) && !!window.SmartAnnotationFlyout && window.SmartAnnotationFlyout.isOpenFor(field);
  }

  // Once a trigger is detected, searching/selecting all happen inside the flyout itself (it owns
  // its own search input - see smart_annotation_flyout.vue). Opening the flyout moves focus
  // there, which blurs `field` - so, unlike the old at.js-style behavior, a field blur is an
  // expected side effect of opening, not a signal to close.
  function bindField(adapter, field, assignableMyModuleId) {
    var composing = false;

    function evaluateMatch() {
      var subtext = adapter.getSubtext();
      var flag = AtWhoMatchers.isTriggerFlag('#', subtext, true)
        ? '#'
        : (AtWhoMatchers.isTriggerFlag('@', subtext, false) ? '@' : null);

      if (!flag) return;
      openFlyout(adapter, field, flag, assignableMyModuleId);
    }

    field.addEventListener('input', function() { if (!composing) evaluateMatch(); });
    field.addEventListener('compositionstart', function() { composing = true; });
    field.addEventListener('compositionend', function() { composing = false; evaluateMatch(); });
  }

  function initField(field, deferred, assignableMyModuleId) {
    var el = AtWhoFieldAdapter.toElement(field);
    if (!el) return;

    var adapter = AtWhoFieldAdapter.create(el);

    function start() {
      if (el.__atwhoInitialized) return;
      el.__atwhoInitialized = true;
      bindField(adapter, el, assignableMyModuleId);
    }

    if (deferred) {
      el.addEventListener('focus', start);
    } else {
      start();
    }
  }

  function preventPropagation(target) {
    var elements = typeof target === 'string'
      ? document.querySelectorAll(target)
      : [AtWhoFieldAdapter.toElement(target)];

    elements.forEach(function(el) {
      if (!el) return;
      el.addEventListener('click', function(e) {
        e.stopPropagation();
        e.preventDefault();
      });
    });
  }

  function closePopup() {
    closeSession();
  }

  function isSelecting(field) {
    return isFlyoutOpenFor(AtWhoFieldAdapter.toElement(field));
  }

  return Object.freeze({
    init: initField,
    preventPropagation: preventPropagation,
    closePopup: closePopup,
    isSelecting: isSelecting
  });
}());

// Initialize smart annotation for any field that opts in declaratively via `data-atwho-edit`.
// Uses `focusin` (which bubbles), matching how jQuery's delegated `.on('focus', selector, fn)`
// is implemented under the hood - plain `focus` does not bubble.
document.addEventListener('focusin', function(e) {
  var target = e.target;
  if (target && target.matches && target.matches('[data-atwho-edit]')) {
    SmartAnnotation.init(target, false);
  }
});
