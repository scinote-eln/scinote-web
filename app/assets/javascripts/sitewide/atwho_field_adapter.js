// Replaces at.js + jquery.caret.min.js: normalizes caret-position tracking, text-before-caret
// extraction and text insertion across the three field shapes SmartAnnotation is used on -
// plain <input>/<textarea>, a contenteditable element, and a contenteditable element that lives
// inside a same-origin iframe (TinyMCE's editable body).
var AtWhoFieldAdapter = (function() {
  'use strict';

  var MIRROR_STYLE_PROPS = [
    'boxSizing', 'width', 'borderTopWidth', 'borderRightWidth', 'borderBottomWidth', 'borderLeftWidth',
    'borderTopStyle', 'borderRightStyle', 'borderBottomStyle', 'borderLeftStyle',
    'paddingTop', 'paddingRight', 'paddingBottom', 'paddingLeft',
    'fontStyle', 'fontVariant', 'fontWeight', 'fontStretch', 'fontSize', 'fontFamily',
    'lineHeight', 'textAlign', 'textTransform', 'textIndent', 'letterSpacing', 'wordSpacing',
    'tabSize', 'wordBreak'
  ];

  function copyMirrorStyles(field, mirror) {
    var computed = window.getComputedStyle(field);
    MIRROR_STYLE_PROPS.forEach(function(prop) {
      mirror.style[prop] = computed[prop];
    });
    mirror.style.whiteSpace = field.tagName === 'TEXTAREA' ? 'pre-wrap' : 'pre';
  }

  function getOrCreateMirror(field) {
    if (!field.__atwhoMirror) {
      var mirror = document.createElement('div');
      mirror.style.position = 'absolute';
      mirror.style.visibility = 'hidden';
      mirror.style.top = '-9999px';
      mirror.style.left = '-9999px';
      mirror.style.overflow = 'hidden';
      document.body.appendChild(mirror);
      field.__atwhoMirror = mirror;
    }
    return field.__atwhoMirror;
  }

  // ---- Plain <input>/<textarea> ------------------------------------------------------------

  function InputTextareaAdapter(el) {
    this.el = el;
  }

  InputTextareaAdapter.prototype.getSubtext = function() {
    return this.el.value.slice(0, this.el.selectionStart);
  };

  InputTextareaAdapter.prototype.getCaretRect = function() {
    var el = this.el;
    var mirror = getOrCreateMirror(el);
    copyMirrorStyles(el, mirror);
    mirror.style.width = el.tagName === 'TEXTAREA' ? el.clientWidth + 'px' : 'auto';

    var caretPos = el.selectionStart;
    var before = el.value.slice(0, caretPos);
    var after = el.value.slice(caretPos);

    mirror.textContent = '';
    mirror.appendChild(document.createTextNode(before));
    var marker = document.createElement('span');
    marker.textContent = after.length && after[0] !== '\n' ? after[0] : '.';
    mirror.appendChild(marker);

    var markerRect = marker.getBoundingClientRect();
    var mirrorRect = mirror.getBoundingClientRect();
    var fieldRect = el.getBoundingClientRect();

    var left = fieldRect.left + (markerRect.left - mirrorRect.left) - el.scrollLeft;
    var top = fieldRect.top + (markerRect.top - mirrorRect.top) - el.scrollTop;
    var height = markerRect.height || fieldRect.height;

    // Viewport-relative (like plain getBoundingClientRect()), not document-absolute - the
    // flyout is positioned with `position: fixed`, matching this codebase's other flyouts
    // (see app/javascript/vue/shared/mixins/fixed_flyout.js).
    return { left: left, top: top, bottom: top + height, height: height };
  };

  // `matchLength` is the number of characters (flag + query) ending at the current caret that
  // should be replaced - recomputed fresh at insertion time from the live caret position rather
  // than cached, so it can't go stale if anything shifted between match and confirm.
  InputTextareaAdapter.prototype.insertAtCaret = function(coreText, matchLength) {
    var el = this.el;
    var caretPos = el.selectionStart;
    var start = Math.max(0, caretPos - matchLength);
    var end = caretPos;
    var text = coreText + ' ';

    if (typeof el.setRangeText === 'function') {
      el.setRangeText(text, start, end, 'end');
    } else {
      el.value = el.value.slice(0, start) + text + el.value.slice(end);
      el.selectionStart = el.selectionEnd = start + text.length;
    }

    el.dispatchEvent(new Event('input', { bubbles: true }));
  };

  InputTextareaAdapter.prototype.focus = function() {
    this.el.focus();
  };

  // ---- contenteditable (plain, or inside a same-origin iframe like TinyMCE) ----------------

  function ContentEditableAdapter(el) {
    this.el = el;
    this.win = el.ownerDocument.defaultView || window;
  }

  ContentEditableAdapter.prototype._collapsedCaretRange = function() {
    var sel = this.win.getSelection();
    if (!sel || sel.rangeCount === 0) return null;
    var range = sel.getRangeAt(0).cloneRange();
    range.collapse(true);
    return range;
  };

  ContentEditableAdapter.prototype.getSubtext = function() {
    var caretRange = this._collapsedCaretRange();
    if (!caretRange) return '';
    var range = caretRange.cloneRange();
    range.setStart(this.el, 0);
    return range.toString();
  };

  ContentEditableAdapter.prototype.getCaretRect = function() {
    var caretRange = this._collapsedCaretRange();
    if (!caretRange) return null;

    var rect = caretRange.getClientRects()[0];
    var marker = null;
    if (!rect) {
      // Collapsed ranges at an empty line/node boundary sometimes report no client rects -
      // fall back to briefly inserting a zero-width marker to measure, then remove it.
      marker = this.win.document.createElement('span');
      marker.appendChild(this.win.document.createTextNode('​'));
      caretRange.insertNode(marker);
      rect = marker.getBoundingClientRect();
      marker.parentNode.removeChild(marker);
      if (marker.parentNode && marker.parentNode.normalize) marker.parentNode.normalize();
    }
    if (!rect) return null;

    var left = rect.left;
    var top = rect.top;
    var height = rect.height;

    var frameEl = this.win.frameElement;
    if (frameEl) {
      var frameRect = frameEl.getBoundingClientRect();
      left += frameRect.left;
      top += frameRect.top;
    }

    // Viewport-relative - see the note in InputTextareaAdapter#getCaretRect above.
    return { left: left, top: top, bottom: top + height, height: height };
  };

  // Walks backward `matchLength` characters from the live caret across text-node boundaries to
  // build a fresh Range spanning the matched flag+query text.
  ContentEditableAdapter.prototype._rangeEndingAtCaret = function(matchLength) {
    var caretRange = this._collapsedCaretRange();
    if (!caretRange) return null;

    var doc = this.win.document;
    var walker = doc.createTreeWalker(this.el, NodeFilter.SHOW_TEXT, null);
    var textNodes = [];
    var node;
    while ((node = walker.nextNode())) textNodes.push(node);

    var caretNode = caretRange.startContainer;
    var caretOffset = caretRange.startOffset;

    if (caretNode.nodeType !== Node.TEXT_NODE) {
      caretNode = textNodes[textNodes.length - 1] || this.el;
      caretOffset = caretNode.nodeType === Node.TEXT_NODE ? caretNode.length : 0;
    }

    var endNode = caretNode;
    var endOffset = caretOffset;

    // Walk backward node-by-node, consuming characters from each until `matchLength` is used up.
    var nodeIndex = textNodes.indexOf(caretNode);
    var offsetInNode = caretOffset;
    var charsRemaining = matchLength;

    while (charsRemaining > 0 && nodeIndex >= 0) {
      var charsAvailableInNode = Math.min(offsetInNode, charsRemaining);
      offsetInNode -= charsAvailableInNode;
      charsRemaining -= charsAvailableInNode;

      if (charsRemaining > 0) {
        nodeIndex -= 1;
        if (nodeIndex < 0) break;
        offsetInNode = textNodes[nodeIndex].length;
      }
    }

    var startNode = nodeIndex >= 0 ? textNodes[nodeIndex] : (textNodes[0] || this.el);
    var startOffset = nodeIndex >= 0 ? offsetInNode : 0;

    var range = doc.createRange();
    range.setStart(startNode, startOffset);
    range.setEnd(endNode, endOffset);
    return range;
  };

  // Mirrors at.js's own contenteditable insertion: the inserted tag becomes an atomic,
  // non-editable "chip" (so a mention/reference can't be edited character-by-character into a
  // malformed tag), followed by a plain trailing-space text node.
  ContentEditableAdapter.prototype.insertAtCaret = function(coreText, matchLength) {
    var range = this._rangeEndingAtCaret(matchLength);
    if (!range) return;

    range.deleteContents();

    var chip = this.win.document.createElement('span');
    chip.className = 'atwho-inserted';
    chip.setAttribute('contenteditable', 'false');
    chip.textContent = coreText;
    range.insertNode(chip);

    var spaceNode = this.win.document.createTextNode(' ');
    if (chip.nextSibling) {
      chip.parentNode.insertBefore(spaceNode, chip.nextSibling);
    } else {
      chip.parentNode.appendChild(spaceNode);
    }

    var after = this.win.document.createRange();
    after.setStartAfter(spaceNode);
    after.collapse(true);

    var sel = this.win.getSelection();
    sel.removeAllRanges();
    sel.addRange(after);

    this.el.dispatchEvent(new Event('input', { bubbles: true }));
  };

  ContentEditableAdapter.prototype.focus = function() {
    this.el.focus();
  };

  // ---- factory -------------------------------------------------------------------------------

  // Call sites pass either a raw DOM element or a jQuery-wrapped one inconsistently - normalize
  // to a plain element once here, shared with atwho_res.js.
  function toElement(field) {
    return field && field.jquery ? field[0] : field;
  }

  function create(field) {
    var el = toElement(field);
    if (!el) return null;
    if (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA') {
      return new InputTextareaAdapter(el);
    }
    return new ContentEditableAdapter(el);
  }

  return { create: create, toElement: toElement };
}());
