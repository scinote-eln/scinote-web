<template>
  <div ref="flyout" class="atwho-view bg-sn-white rounded shadow-sn-classic-drop-shadow"
       :class="{ old: everOpened }" :style="positionStyle" @mousedown="onRootMousedown">
    <div class="flex items-center gap-1 bg-sn-grey-100 min-h-10 px-3 py-2 text-sm border-b border-sn-light-grey">
      <span v-if="navStack.length > 0" type="button" class="p-1 text-sn-grey-700 hover:text-sn-black shrink-0 cursor-pointer" @click="navBack">
        <i class="sn-icon sn-icon-close"></i>
      </span>
      <span v-for="(crumb, i) in navStack" :key="i" class="flex items-center gap-1 truncate">
        <i v-if="i > 0" class="text-sn-grey-500 sn-icon sn-icon-right"></i>
        <span type="button" class="truncate hover:underline cursor-pointer"
                :class="i === navStack.length - 1 ? 'text-sn-black font-medium' : 'text-sn-grey-700'"
                @click="navTo(i)">{{ crumb.code }}</span>
      </span>
      <div>
        <i v-if="navStack.length > 0" class="text-sn-grey-500 sn-icon sn-icon-right"></i>
        <input ref="searchInput" type="text" :value="query"
              :placeholder="searchPlaceholder"
              class="border-0 bg-transparent focus:!outline-none focus:ring-0 focus:!border-0"
              autocomplete="off"
              @input="onSearchInput" @keydown="onSearchKeydown" @blur="onSearchBlur" />
      </div>
    </div>

    <div v-if="showPills" class="px-3 py-2">
      <div class="text-xs font-semibold text-sn-grey-700 mb-1.5">{{ i18n.t('atwho.navigate') }}</div>
      <div class="flex flex-wrap gap-1.5">
        <span v-for="(pill, index) in pills" :key="pill.tag" type="button"
                class="px-3 py-1.5 cursor-pointer rounded-full text-sm text-sn-black hover:bg-sn-light-grey"
                :class="isActiveIndex(index) ? 'bg-sn-light-grey' : 'bg-sn-super-light-grey'"
                @click="openPill(pill)">
          {{ pill.label }}
        </span>
      </div>
    </div>

    <div v-else class="max-h-[270px] overflow-y-auto p-2 relative">
      <div v-if="loading" class="loading-overlay p-5"></div>
      <template v-else>
        <div v-for="(item, index) in (items || [])" :key="item.type + '-' + item.id"
             class="group flex items-center gap-2 px-2 min-h-10 rounded cursor-pointer leading-[2.25em] hover:bg-sn-super-light-grey"
             :class="{ 'bg-sn-super-light-grey': isActiveIndex(index) }"
             @click="rowClick(item)">
          <template v-if="flag === '@'">
            <img :src="item.avatar_url" class="w-[30px] h-[30px] rounded-full shrink-0" alt="" />
            <div class="min-w-0 py-1">
              <div class="truncate" v-html="highlightMatch(item.full_name)"></div>
              <div class="truncate text-xs text-sn-grey-700" v-html="highlightMatch(item.email)"></div>
            </div>
          </template>
          <template v-else>
            <span class="text-[0.625rem] font-semibold uppercase text-sn-grey-700 shrink-0" v-html="highlightMatch(item.code)"></span>
            <span class="text-sn-grey-500">&middot;</span>
            <span class="truncate" v-html="highlightMatch(item.name)"></span>
            <span v-if="isDrillable(item)" @click.stop="addToStack(item)" class="sn-icon sn-icon-arrow-right text-sn-grey-700 shrink-0"></span>
            <span class="tw-hidden group-hover:flex items-center gap-1.5 shrink-0 ml-auto">
              <button type="button" class="btn btn-xs btn-light" @click.stop="selectItem(item)">
                <i class="sn-icon sn-icon-assign"></i>
                {{ i18n.t('atwho.buttons.add') }}
              </button>
              <button v-if="item.my_module_id && !item.row_assigned" type="button" class="btn btn-xs btn-light"
                      @click.stop="assignItem(item)">
                <i class="sn-icon sn-icon-assign-to-task"></i>
                {{ i18n.t('atwho.buttons.assign') }}
              </button>
            </span>
          </template>
        </div>

        <div v-if="limitReached" class="text-sn-grey-700 text-sm py-1 px-2">{{ i18n.t('atwho.more_results') }}</div>

        <div v-if="items && items.length === 0 && query" class="py-6 px-8 text-center text-sn-grey-700">
          <h1 class="text-sm font-semibold text-sn-black"
              v-html="i18n.t('atwho.no_results.no_matches_html', { query: escapeHtml(query) })"></h1>
          <div class="text-sm mt-2">{{ i18n.t('atwho.no_results.no_matches_hint') }}</div>
        </div>
        <div v-else-if="items && items.length === 0" class="py-6 px-8 text-center text-sn-grey-700">
          <h1 class="text-sm font-semibold text-sn-black">{{ i18n.t(`atwho.no_results.${noResultsKey}`) }}</h1>
          <div class="text-sm mt-2">{{ i18n.t('atwho.no_results.description') }}</div>
        </div>
      </template>
    </div>
  </div>
</template>

<script>
import axios from '../../packs/custom_axios.js';
import escapeHtml from './escape_html.js';
import flyoutPositioningMixin from './smart_annotation_mixins/flyout_positioning_mixin.js';
import keyboardNavigationMixin from './smart_annotation_mixins/keyboard_navigation_mixin.js';
import searchHighlightMixin from './smart_annotation_mixins/search_highlight_mixin.js';
import {
  atwho_search_team_path,
  atwho_users_team_path,
  my_module_repositories_path
} from '../../routes.js';

const CHILD_TAG = { prj: 'sa-projects', exp: 'sa-experiments', rep: 'sa-repositories' };
const NO_RESULTS_KEY = {
  'sa-projects': 'projects',
  'sa-experiments': 'experiments',
  'sa-tasks': 'my_modules',
  'sa-repositories': 'repository_rows'
};

export default {
  name: 'SmartAnnotationFlyout',
  mixins: [flyoutPositioningMixin, keyboardNavigationMixin, searchHighlightMixin],
  data() {
    return {
      flag: '@',
      query: '',
      loading: false,
      limitReached: false,
      items: null,
      navStack: [],
      assignableMyModuleId: null,
      onInsert: null
    };
  },
  computed: {
    pills() {
      return [
        { tag: 'sa-projects', label: this.i18n.t('atwho.projects') },
        { tag: 'sa-experiments', label: this.i18n.t('atwho.experiments') },
        { tag: 'sa-tasks', label: this.i18n.t('atwho.tasks') },
        { tag: 'sa-repositories', label: this.i18n.t('atwho.inventories') }
      ];
    },
    showPills() {
      return this.flag === '#' && this.navStack.length === 0 && !this.query;
    },
    noResultsKey() {
      if (this.flag === '@') return 'users';

      const top = this.navStack[this.navStack.length - 1];
      return (top && NO_RESULTS_KEY[top.tag]) || 'mixed';
    },
    searchPlaceholder() {
      if (this.flag === '@') return this.i18n.t('atwho.search_placeholder_users');

      const top = this.navStack[this.navStack.length - 1];
      if (!top) return this.i18n.t('atwho.search_placeholder_reference');

      return this.i18n.t('atwho.search_placeholder_in', { name: top.code });
    }
  },
  methods: {
    escapeHtml,
    teamId() {
      return document.body.dataset.currentTeamId;
    },
    runQuery() {
      const teamId = this.teamId();
      if (!teamId) return;

      const loaderTimeout = setTimeout(() => { this.loading = true; }, 250);
      const request = this.flag === '@' ? this.fetchUsers(teamId) : this.fetchReference(teamId);

      request.then((result) => {
        clearTimeout(loaderTimeout);
        this.loading = false;

        this.items = result.items;
        this.limitReached = result.limitReached;
        this.resetActiveIndex();
      });
    },
    fetchUsers(teamId) {
      return axios.get(atwho_users_team_path(teamId), { params: { query: this.query } })
        .then((response) => ({ items: response.data.users || [], limitReached: !!response.data.limit_reached }));
    },
    fetchReference(teamId) {
      const top = this.navStack[this.navStack.length - 1];
      const params = { query: this.query };
      if (top) params.parent_type = top.tag;
      if (top && top.id) params.parent_id = top.id;
      if (this.assignableMyModuleId) params.assignable_my_module_id = this.assignableMyModuleId;

      return axios.get(atwho_search_team_path(teamId), { params })
        .then((response) => ({ items: response.data.items || [], limitReached: !!response.data.limit_reached }));
    },
    openPill(pill) {
      this.navStack = [{ tag: pill.tag, id: null, code: pill.label }];
      this.query = '';
      this.resetActiveIndex();
      this.runQuery();
    },
    isDrillable(item) {
      return this.flag === '#' && !!CHILD_TAG[item.type];
    },
    rowClick(item) {
      this.selectItem(item);
    },
    addToStack(item) {
      this.navStack.push({ tag: CHILD_TAG[item.type], id: item.id, code: item.code });
      this.query = '';
      this.resetActiveIndex();
      this.runQuery();
    },
    navTo(index) {
      this.navStack = index < 0 ? [] : this.navStack.slice(0, index + 1);
      this.query = '';
      this.resetActiveIndex();
      this.runQuery();
    },
    navBack() {
      this.query = '';
      this.navStack = [];
      this.items = [];
      this.limitReached = false;
      this.resetActiveIndex();
    },
    selectItem(item) {
      if (!this.onInsert) return;

      const tag = this.flag === '@'
        ? `[@${item.full_name}~${item.id}]`
        : `[#${item.name}~${item.type}~${item.id_encoded}]`;
      this.onInsert(tag);
    },
    assignItem(item) {
      axios.post(my_module_repositories_path(item.my_module_id), { repository_row_id: item.repository_row_id })
        .then((response) => {
          HelperModule.flashAlertMsg(response.data.flash, 'success');
        })
        .catch((error) => {
          const flash = error.response && error.response.data && error.response.data.flash;
          HelperModule.flashAlertMsg(flash || this.i18n.t('errors.general'), 'danger');
        });
    },
    onSearchInput(e) {
      this.query = e.target.value;
      this.runQuery();
    },
    onSearchKeydown(e) {
      if (e.key === 'Escape') {
        e.preventDefault();
        this.closeAndRefocus();
        return;
      }
      this.handleNavigationKeydown(e);
    },
    onSearchBlur() {
      this.requestClose();
    }
  }
};
</script>
