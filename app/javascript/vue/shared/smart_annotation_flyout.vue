<template>
  <div ref="flyout" class="atwho-view bg-sn-white rounded shadow-sn-classic-drop-shadow"
       :class="{ old: everOpened }" :style="positionStyle" @mousedown.prevent>
    <template v-if="flag === '#'">
      <div class="flex items-center flex-wrap">
        <button v-for="tab in tabs" :key="tab.type" type="button"
                class="px-3 py-2.5 text-sm font-medium border-b-2 -mb-px"
                :class="tab.type === activeTabType
                  ? 'border-sn-science-blue text-sn-science-blue'
                  : 'border-transparent text-sn-grey-700 hover:text-sn-black'"
                @click="selectTab(tab.type)">
          {{ tab.label }}
        </button>
        <button type="button" class="ml-auto px-3 py-2 text-sn-grey-700 hover:text-sn-black" @click="requestClose">
          <span class="sn-icon sn-icon-close"></span>
        </button>
      </div>
      <div v-if="activeTabType === 'REPOSITORY' && repositories.length > 1"
           class="flex flex-wrap gap-1.5 p-2.5 max-h-[100px] overflow-y-auto border-t border-sn-light-grey">
        <button v-for="repository in repositories" :key="repository.id" type="button"
                class="flex items-center gap-1.5 px-2.5 py-1.5 rounded text-sm truncate max-w-[150px]"
                :class="String(repository.id) === String(activeRepositoryId)
                  ? 'bg-sn-blue text-sn-white'
                  : 'bg-sn-super-light-grey text-sn-black hover:bg-sn-light-grey'"
                @click="selectRepository(repository.id)">
          <i v-if="repository.shared_with_team" class="sn-icon sn-icon-user-menu-friends"></i>
          <span class="truncate">{{ repository.name }}</span>
        </button>
      </div>
    </template>
    <div v-else class="flex items-center justify-between px-3 py-2 text-sm text-sn-grey-700 border-b border-sn-light-grey">
      <span>{{ i18n.t('atwho.users.header') }}</span>
      <button type="button" class="p-1 text-sn-grey-700 hover:text-sn-black" @click="requestClose">
        <span class="sn-icon sn-icon-close"></span>
      </button>
    </div>

    <div class="max-h-[200px] overflow-y-auto p-2 relative">
      <div v-if="loading" class="loading-overlay p-5"></div>
      <template v-else>
        <div v-for="(group, groupIndex) in (groups || [])" :key="groupIndex">
          <div v-if="group.projectName" class="flex text-xs text-sn-grey-700 gap-1.5">
            <span class="truncate" :title="group.projectName">{{ group.projectName }}</span>
            <span v-if="group.experimentName">/</span>
            <span v-if="group.experimentName" class="truncate" :title="group.experimentName">{{ group.experimentName }}</span>
          </div>

          <div v-for="item in group.items" :key="item.id" ref="itemRefs"
               class="group flex items-center gap-2 px-2 rounded cursor-pointer leading-[2.25em]"
               :class="isHighlighted(item) ? 'bg-sn-super-light-grey' : 'hover:bg-sn-super-light-grey'"
               @click="selectItem(item)">
            <template v-if="flag === '@'">
              <img :src="item.avatar_url" class="w-[30px] h-[30px] rounded-full shrink-0" alt="" />
              <div class="min-w-0 py-1">
                <div class="truncate">
                  <span v-for="(segment, i) in highlightSegments(item.full_name)" :key="i"
                        :class="{ 'bg-sn-alert-brittlebush-disabled': segment.highlighted }">{{ segment.text }}</span>
                </div>
                <div class="truncate text-xs text-sn-grey-700">{{ item.email }}</div>
              </div>
            </template>
            <template v-else>
              <span class="text-[0.625rem] font-semibold uppercase text-sn-grey-700 shrink-0">{{ item.code }}</span>
              <span class="text-sn-grey-500">&middot;</span>
              <span class="truncate flex-1">
                <span v-for="(segment, i) in highlightSegments(item.name)" :key="i"
                      :class="{ 'bg-sn-alert-brittlebush-disabled': segment.highlighted }">{{ segment.text }}</span>
              </span>
              <span class="hidden group-hover:flex items-center gap-1.5 shrink-0">
                <button type="button" class="btn icon-btn btn-light" @click.stop="selectItem(item)">
                  {{ i18n.t('atwho.buttons.insert') }}
                </button>
                <button v-if="item.assign_url && !item.row_assigned" type="button" class="btn icon-btn btn-light"
                        @click.stop="assignItem(item)">
                  {{ i18n.t('atwho.buttons.assign') }}
                </button>
              </span>
            </template>
          </div>
        </div>

        <div v-if="limitReached" class="text-sn-grey-700 text-sm py-1 px-2">{{ i18n.t('atwho.more_results') }}</div>

        <div v-if="groups && flatItems.length === 0" class="py-6 px-8 text-center text-sn-grey-700">
          <h1 class="text-sm font-semibold text-sn-black">{{ i18n.t(`atwho.no_results.${noResultsKey}`) }}</h1>
          <div class="text-sm mt-2">{{ i18n.t('atwho.no_results.description') }}</div>
        </div>
      </template>
    </div>

    <div class="px-3 py-2 text-xs text-sn-grey-700 border-t border-sn-light-grey whitespace-pre">
      {{ i18n.t('atwho.users.help') }}
    </div>
  </div>
</template>

<script>
const TAG_TO_TYPE = { 'sa-projects': 'PROJECT', 'sa-experiments': 'EXPERIMENT', 'sa-tasks': 'TASK', 'sa-repositories': 'REPOSITORY' };
const TYPE_TO_NO_RESULTS_KEY = { PROJECT: 'projects', EXPERIMENT: 'experiments', TASK: 'my_modules', REPOSITORY: 'repository_rows' };

const FLYOUT_GAP = 18; // matches the popup's original fixed gap below the caret line
const VIEWPORT_MARGIN = 8; // breathing room from the viewport edge
const MAX_WIDTH = 700;
const MIN_USABLE_HEIGHT = 150;

// Viewport-aware positioning: clamps horizontally so the flyout never overflows the right edge,
// caps its width so it never overflows on a narrow viewport, and flips above the caret when
// there isn't enough room below. A pure function of the caret rect and the current viewport size
// (not a computed property) so the positioning math can be read and reasoned about on its own,
// separately from Vue's reactivity. Mirrors the flip/clamp approach
// app/javascript/vue/shared/mixins/fixed_flyout.js already uses for other flyouts in this
// codebase, applied to a caret point instead of a field's bounding box.
//
// Position/size are returned as inline style (not Tailwind classes) so they never depend on the
// Tailwind build being in sync with this file - only purely cosmetic classes live in the
// template's static `class`.
function computeFlyoutStyle(caret, viewport) {
  const width = Math.min(MAX_WIDTH, viewport.width - VIEWPORT_MARGIN * 2);
  const left = clamp(caret.left, VIEWPORT_MARGIN, viewport.width - width - VIEWPORT_MARGIN);

  const spaceBelow = viewport.height - caret.bottom - FLYOUT_GAP - VIEWPORT_MARGIN;
  const spaceAbove = caret.top - FLYOUT_GAP - VIEWPORT_MARGIN;
  const flipUp = spaceBelow < MIN_USABLE_HEIGHT && spaceAbove > spaceBelow;

  const style = {
    display: 'block',
    position: 'fixed',
    zIndex: 11110,
    overflow: 'auto',
    height: 'fit-content',
    left: `${left}px`,
    width: `${width}px`
  };

  // Both `top` and `bottom` are always set explicitly (the unused one to `auto`) rather than
  // omitted, so a flip never leaves the other edge pinned from a previous render.
  if (flipUp) {
    style.top = 'auto';
    style.bottom = `${viewport.height - caret.top + FLYOUT_GAP}px`;
    style.maxHeight = `${Math.max(spaceAbove, MIN_USABLE_HEIGHT)}px`;
  } else {
    style.top = `${caret.bottom + FLYOUT_GAP}px`;
    style.bottom = 'auto';
    style.maxHeight = `${Math.max(spaceBelow, MIN_USABLE_HEIGHT)}px`;
  }

  return style;
}

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}

// Splits `text` into segments so the template can highlight query matches without `v-html`.
function computeHighlightSegments(text, query) {
  if (!text) return [];

  const terms = (query || '').replace(/[()]/g, '\\$&').split(' ').filter(Boolean);
  if (!terms.length) return [{ text, highlighted: false }];

  const regex = new RegExp(`(${terms.join('|')})`, 'gi');
  // A single capturing group makes String#split interleave the matched substrings into the
  // result at odd indices, with the surrounding text at even indices.
  return text.split(regex)
    .map((part, index) => ({ text: part || '', highlighted: index % 2 === 1 }))
    .filter((segment) => segment.text !== '');
}

// Normalizes a query result (differently shaped per tab/trigger - see AtWhoController) into a
// single `[{ projectName, experimentName, items }]` list the template can render uniformly.
function groupsFromResult(flag, result) {
  if (flag === '@') {
    return [{ projectName: null, experimentName: null, items: result.users || [] }];
  }

  if (result.groups) {
    return result.groups.map((group) => ({
      projectName: group.project_name,
      experimentName: group.experiment_name || null,
      items: group.items
    }));
  }

  return [{ projectName: null, experimentName: null, items: result.items || [] }];
}

export default {
  name: 'SmartAnnotationFlyout',
  data() {
    return {
      isOpen: false,
      everOpened: false,
      flag: '@',
      position: { left: 0, top: 0, height: 0 },
      teamId: null,
      query: '',
      loading: false,
      limitReached: false,
      repositories: [],
      activeTabType: 'REPOSITORY',
      activeRepositoryId: null,
      groups: null, // null until the first query for the current session resolves
      highlightedIndex: -1,
      onQuery: null,
      onSelect: null,
      onAssign: null,
      onCloseCallback: null,
      fieldEl: null
    };
  },
  computed: {
    // `this.position` is the viewport-relative caret rect from AtWhoFieldAdapter#getCaretRect -
    // see computeFlyoutStyle above for the actual positioning logic.
    positionStyle() {
      if (!this.isOpen) return { display: 'none', position: 'fixed' };

      return computeFlyoutStyle(this.position, { width: window.innerWidth, height: window.innerHeight });
    },
    tabs() {
      return [
        { type: 'PROJECT', label: this.i18n.t('atwho.projects') },
        { type: 'EXPERIMENT', label: this.i18n.t('atwho.experiments') },
        { type: 'TASK', label: this.i18n.t('atwho.tasks') },
        { type: 'REPOSITORY', label: this.i18n.t('atwho.inventories') }
      ];
    },
    flatItems() {
      return (this.groups || []).reduce((items, group) => items.concat(group.items), []);
    },
    noResultsKey() {
      if (this.flag === '@') return 'users';
      return TYPE_TO_NO_RESULTS_KEY[this.activeTabType] || 'repository_rows';
    }
  },
  mounted() {
    window.SmartAnnotationFlyout = {
      open: this.open,
      close: this.close,
      updateQuery: this.updateQuery,
      reposition: this.reposition,
      moveHighlight: this.moveHighlight,
      hasHighlighted: this.hasHighlighted,
      confirmHighlighted: this.confirmHighlighted,
      isOpenFor: this.isOpenFor
    };

    // A couple of unrelated Vue modals force-hide any open flyout on close via
    // `$('.atwho-view.old').css('display', 'none')` rather than through this component. Watch
    // for that so our own open/session state doesn't go stale when it happens.
    this.styleObserver = new MutationObserver(() => {
      if (this.isOpen && this.$refs.flyout && this.$refs.flyout.style.display === 'none') {
        this.close();
        if (this.onCloseCallback) this.onCloseCallback();
      }
    });
    this.styleObserver.observe(this.$refs.flyout, { attributes: true, attributeFilter: ['style'] });
  },
  beforeUnmount() {
    if (this.styleObserver) this.styleObserver.disconnect();
    delete window.SmartAnnotationFlyout;
  },
  methods: {
    open(payload) {
      this.flag = payload.flag;
      this.position = payload.position;
      this.teamId = payload.teamId;
      this.onQuery = payload.onQuery;
      this.onSelect = payload.onSelect;
      this.onAssign = payload.onAssign;
      this.onCloseCallback = payload.onClose;
      this.fieldEl = payload.fieldEl;
      this.query = '';
      this.groups = null;
      this.highlightedIndex = -1;

      if (payload.flag === '#') {
        this.repositories = payload.repositories || [];
        this.restoreRememberedTab();
      } else {
        this.repositories = [];
        this.activeTabType = null;
        this.activeRepositoryId = null;
      }

      this.isOpen = true;
      this.everOpened = true;
      this.$nextTick(() => this.runQuery());
    },
    close() {
      this.isOpen = false;
      this.groups = null;
    },
    updateQuery(query) {
      this.query = query;
      this.runQuery();
    },
    reposition(position) {
      this.position = position;
    },
    isOpenFor(fieldEl) {
      return this.isOpen && this.fieldEl === fieldEl;
    },
    restoreRememberedTab() {
      this.activeTabType = 'REPOSITORY';
      this.activeRepositoryId = null;

      if (!this.teamId) return;

      try {
        const remembered = JSON.parse(localStorage.getItem(`smart_annotation_states/teams/${this.teamId}`));
        if (!remembered) return;

        this.activeTabType = TAG_TO_TYPE[remembered.tag] || 'REPOSITORY';
        this.activeRepositoryId = remembered.repository || null;
      } catch (e) {
        // ignore malformed/stale localStorage content
      }
    },
    runQuery() {
      if (!this.onQuery) return;

      const loaderTimeout = setTimeout(() => { this.loading = true; }, 250);

      this.onQuery({
        query: this.query,
        tabType: this.activeTabType,
        activeRepositoryId: this.activeRepositoryId
      }).then((result) => {
        clearTimeout(loaderTimeout);
        this.loading = false;

        this.groups = groupsFromResult(this.flag, result);
        this.limitReached = !!result.limitReached;
        if (result.repositoryId) this.activeRepositoryId = result.repositoryId;

        this.highlightedIndex = this.flatItems.length ? 0 : -1;
      });
    },
    selectTab(type) {
      this.activeTabType = type;
      this.runQuery();
    },
    selectRepository(id) {
      this.activeRepositoryId = id;
      this.runQuery();
    },
    selectItem(item) {
      if (this.onSelect) this.onSelect(item);
    },
    assignItem(item) {
      if (this.onAssign) this.onAssign(item);
    },
    requestClose() {
      this.close();
      if (this.onCloseCallback) this.onCloseCallback();
    },
    highlightSegments(text) {
      return computeHighlightSegments(text, this.query);
    },
    isHighlighted(item) {
      return this.flatItems[this.highlightedIndex] === item;
    },
    moveHighlight(direction) {
      const items = this.flatItems;
      if (!items.length) return;

      const nextIndex = clamp(this.highlightedIndex + direction, 0, items.length - 1);
      this.highlightedIndex = nextIndex;

      this.$nextTick(() => {
        const refs = this.$refs.itemRefs;
        const el = Array.isArray(refs) ? refs[nextIndex] : null;
        if (el) el.scrollIntoView({ block: 'nearest' });
      });
    },
    hasHighlighted() {
      return this.highlightedIndex >= 0 && this.highlightedIndex < this.flatItems.length;
    },
    confirmHighlighted() {
      const item = this.flatItems[this.highlightedIndex];
      if (item && this.onSelect) this.onSelect(item);
    }
  }
};
</script>
