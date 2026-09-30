/* global HelperModule AtWhoFieldAdapter AtWhoMatchers */

// Smart annotation ("@mention"/"#reference") autocomplete controller. This module owns trigger
// matching, caret tracking, keyboard navigation and text insertion (see atwho_field_adapter.js
// and atwho_matchers.js), while the popup itself is rendered by a globally-mounted Vue component
// (app/javascript/vue/shared/smart_annotation_flyout.vue), driven imperatively through
// `window.SmartAnnotationFlyout` - see app/javascript/packs/vue/smart_annotation_flyout.js.
//
// The backend (app/controllers/at_who_controller.rb) returns plain JSON - no HTML fragments are
// fetched or injected; the Vue component renders every list/tab/item straight from that data.
var SmartAnnotation = (function() {
  'use strict';

  var REPOSITION_INTERVAL_MS = 50;

  var filterTypeEnum = null;
  var cachedMenuDataPromise = null;
  var session = null; // { adapter, field, flag, query, matchLength, assignableMyModuleId }
  var repositionTimer = null;

  function getFilterTypeEnum() {
    if (!filterTypeEnum) {
      var body = document.body;
      filterTypeEnum = Object.freeze({
        USER: { tag: 'users', dataUrl: body.getAttribute('data-atwho-users-url') },
        TASK: { tag: 'sa-tasks', dataUrl: body.getAttribute('data-atwho-task-url') },
        PROJECT: { tag: 'sa-projects', dataUrl: body.getAttribute('data-atwho-project-url') },
        EXPERIMENT: { tag: 'sa-experiments', dataUrl: body.getAttribute('data-atwho-experiment-url') },
        REPOSITORY: { tag: 'sa-repositories', dataUrl: body.getAttribute('data-atwho-rep-items-url') }
      });
    }
    return filterTypeEnum;
  }

  function getCsrfToken() {
    var meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.content : null;
  }

  function fetchJson(url, params) {
    var searchParams = new URLSearchParams();
    Object.keys(params || {}).forEach(function(key) {
      var value = params[key];
      if (value !== undefined && value !== null) searchParams.set(key, value);
    });

    var query = searchParams.toString();
    return fetch(url + (query ? '?' + query : ''), {
      headers: { Accept: 'application/json' },
      credentials: 'same-origin'
    }).then(function(response) { return response.json(); });
  }

  // Lazily fetches the '#' menu data (available repositories, for the tab header) once per page
  // load, cached from then on - every field on the page shares the same team/repository list.
  function getMenuData() {
    if (!cachedMenuDataPromise) {
      cachedMenuDataPromise = fetchJson(document.body.getAttribute('data-atwho-repositories-url'));
    }
    return cachedMenuDataPromise;
  }

  function queryUsers(params) {
    return fetchJson(getFilterTypeEnum().USER.dataUrl, { query: params.query }).then(function(data) {
      return { users: data.users, limitReached: data.limit_reached };
    });
  }

  function queryReference(params) {
    var filterType = getFilterTypeEnum()[params.tabType];
    if (!filterType) return Promise.resolve({ items: [], groups: [] });

    var fetchParams = { query: params.query };
    if (filterType.tag === 'sa-repositories') {
      fetchParams.assignable_my_module_id = session && session.assignableMyModuleId;
      if (params.activeRepositoryId) fetchParams.repository_id = params.activeRepositoryId;
    }

    return fetchJson(filterType.dataUrl, fetchParams).then(function(data) {
      if (data.team) {
        localStorage.setItem('smart_annotation_states/teams/' + data.team, JSON.stringify({
          tag: filterType.tag,
          repository: data.repository
        }));
      }
      return {
        items: data.items || null,
        groups: data.groups || null,
        limitReached: data.limit_reached,
        repositoryId: data.repository || null,
        teamId: data.team || null
      };
    });
  }

  function buildOnQuery(flag) {
    return flag === '@' ? queryUsers : queryReference;
  }

  // ---- session (currently open flyout) -------------------------------------------------------

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

  // `item` is one of the plain objects the flyout was handed (a user, or a project/experiment/
  // task/repository-row) - see AtWhoController's *_json builders for the exact shape.
  function confirmSelection(item) {
    if (!session || !item) return;

    var coreText = session.flag === '@'
      ? '[@' + item.full_name + '~' + item.id + ']'
      : '[#' + item.name + '~' + item.type + '~' + item.id + ']';

    var adapter = session.adapter;
    adapter.insertAtCaret(coreText, session.matchLength);
    closeSession();
    adapter.focus();
  }

  function assignRow(item) {
    if (!item) return;

    fetch(item.assign_url, {
      method: 'POST',
      credentials: 'same-origin',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
        'X-CSRF-Token': getCsrfToken()
      },
      body: JSON.stringify({ repository_row_id: item.repository_row_id })
    })
      .then(function(response) {
        return response.json().then(function(data) { return { ok: response.ok, data: data }; });
      })
      .then(function(result) {
        HelperModule.flashAlertMsg(result.data.flash, result.ok ? 'success' : 'danger');
      });
  }

  // True when `session` is currently primed for exactly this field+flag combination.
  function isSessionCurrent(field, flag) {
    return !!(session && session.field === field && session.flag === flag);
  }

  function openOrUpdateFlyout(adapter, field, flag, query, matchLength, assignableMyModuleId) {
    var isNewSession = !isSessionCurrent(field, flag);
    session = {
      adapter: adapter,
      field: field,
      flag: flag,
      query: query,
      matchLength: matchLength,
      assignableMyModuleId: assignableMyModuleId
    };

    var rect = adapter.getCaretRect();
    if (!rect) { closeSession(); return; }

    if (!window.SmartAnnotationFlyout) return; // pack not mounted yet - defensive no-op

    if (!isNewSession) {
      window.SmartAnnotationFlyout.updateQuery(query);
      window.SmartAnnotationFlyout.reposition(rect);
      return;
    }

    var menuDataPromise = flag === '#' ? getMenuData() : Promise.resolve(null);
    menuDataPromise.then(function(menuData) {
      // The session may have moved on (field/flag switched, or closed) while this was in flight.
      if (!isSessionCurrent(field, flag)) return;

      window.SmartAnnotationFlyout.open({
        flag: flag,
        fieldEl: field,
        position: rect,
        repositories: menuData ? menuData.repositories : [],
        teamId: document.body.getAttribute('data-current-team-id'),
        onQuery: buildOnQuery(flag),
        onSelect: confirmSelection,
        onAssign: assignRow,
        onClose: function() { session = null; stopRepositionLoop(); }
      });
      startRepositionLoop();
    });
  }

  // ---- per-field keystroke controller ---------------------------------------------------------

  // True when `field` is the one the currently-open (or just-closed) session belongs to.
  function isSessionFor(field) {
    return !!(session && session.field === field);
  }

  function isFlyoutOpenFor(field) {
    return isSessionFor(field) && !!window.SmartAnnotationFlyout && window.SmartAnnotationFlyout.isOpenFor(field);
  }

  function bindField(adapter, field, assignableMyModuleId) {
    var composing = false;

    function evaluateMatch() {
      var subtext = adapter.getSubtext();
      var hashQuery = AtWhoMatchers.referenceMatcher('#', subtext, true);
      var atQuery = AtWhoMatchers.defaultMatcher('@', subtext, false);

      var active = hashQuery != null
        ? { flag: '#', query: hashQuery }
        : (atQuery != null ? { flag: '@', query: atQuery } : null);

      if (!active) {
        if (isSessionFor(field)) closeSession();
        return;
      }

      var matchLength = active.flag.length + active.query.length;
      openOrUpdateFlyout(adapter, field, active.flag, active.query, matchLength, assignableMyModuleId);
    }

    field.addEventListener('input', function() { if (!composing) evaluateMatch(); });
    field.addEventListener('compositionstart', function() { composing = true; });
    field.addEventListener('compositionend', function() { composing = false; evaluateMatch(); });
    field.addEventListener('click', function() { if (isSessionFor(field)) evaluateMatch(); });

    field.addEventListener('keydown', function(e) {
      if (!isFlyoutOpenFor(field)) return;

      switch (e.key) {
        case 'Escape':
          e.preventDefault();
          closeSession();
          break;
        case 'ArrowUp':
          e.preventDefault();
          window.SmartAnnotationFlyout.moveHighlight(-1);
          break;
        case 'ArrowDown':
          e.preventDefault();
          window.SmartAnnotationFlyout.moveHighlight(1);
          break;
        case 'Enter':
        case 'Tab':
          if (window.SmartAnnotationFlyout.hasHighlighted()) {
            e.preventDefault();
            window.SmartAnnotationFlyout.confirmHighlighted();
          } else {
            closeSession();
          }
          break;
        default:
          break;
      }
    });

    // The flyout's own interactive elements call preventDefault() on `mousedown` so clicking
    // them never blurs the field in the first place - so a genuine blur here always means focus
    // moved elsewhere, and the flyout should close.
    field.addEventListener('blur', function() {
      if (isSessionFor(field)) closeSession();
    });
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
