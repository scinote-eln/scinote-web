<template>
  <div class="content-pane flexible with-grey-background" data-e2e="e2e-CO-globalSearch">
    <div class="content-header">
      <div class="title-row">
        <h1 class="mt-0 truncate !inline">
          <StringWithEllipsis
            class="w-full"
            :endCharacters="5"
            :text="i18n.t('search.index.results_title_html', { query: localQuery })"></StringWithEllipsis>
        </h1>
      </div>
    </div>
    <div class="bg-white rounded p-4 flex gap-2.5 z-10 items-center mb-4 sticky top-0">
      <GeneralDropdown ref="historyContainer" :canOpen="canOpenHistory" :fieldOnlyOpen="true" >
        <template v-slot:field>
          <div class="left-icon sci-input-container-v2 w-72 input-sm"
              :title="i18n.t('nav.search')" :class="{'error': invalidQuery}" :data-e2e="'e2e-IF-globalSearch'">
            <input ref="searchField"
              type="text"
              class="!pr-9"
              :value="localQuery"
              @change="changeQuery"
              @keydown="focusHistoryItem"
              @keydown.enter="changeQuery"
              @blur="changeQuery"
              :placeholder="i18n.t('nav.search')"
            />
            <i class="sn-icon sn-icon-search"></i>
            <i v-if="localQuery.length > 0"
              class="sn-icon cursor-pointer sn-icon-close absolute right-0 -top-0.5"
              @click="localQuery = ''; $refs.searchField.focus()" :title="i18n.t('nav.clear')" :data-e2e="'e2e-BT-globalSearch-clearInput'"></i>
          </div>
        </template>
        <template v-slot:flyout >
          <div class="max-w-[600px]">
            <div v-for="(query, i) in reversedPreviousQueries" @click="setQuery(query)" :key="i"
                ref="historyItems"
                @keydown="focusHistoryItem"
                tabindex="1"
                @keydown.enter="setQuery(query)"
                class="flex px-3 min-h-11 items-center gap-2 hover:bg-sn-super-light-grey cursor-pointer">
              <i class="sn-icon sn-icon-history-search"></i>
              {{ query }}
            </div>
          </div>
        </template>
      </GeneralDropdown>
      <div class="flex items-center gap-2.5">
        <button class="btn btn-secondary btn-sm"
            :class="{'active': activeGroup == 'ExperimentsComponent'}"
            @click="setActiveGroup('ExperimentsComponent')"
            :data-e2e="'e2e-BT-globalSearch-experiments'">
          {{ i18n.t('search.index.experiments') }}
        </button>
        <button class="btn btn-secondary btn-sm"
            :class="{'active': activeGroup == 'MyModulesComponent'}"
            @click="setActiveGroup('MyModulesComponent')"
            :data-e2e="'e2e-BT-globalSearch-tasks'">
          {{ i18n.t('search.index.tasks') }}
        </button>
        <button class="btn btn-secondary btn-sm"
            :class="{'active': activeGroup == 'ResultsComponent'}"
            @click="setActiveGroup('ResultsComponent')"
            :data-e2e="'e2e-BT-globalSearch-taskResults'">
          {{ i18n.t('search.index.task_results') }}
        </button>
      </div>
      <button class="btn btn-light btn-sm" @click="filterModalOpened = true" :data-e2e="'e2e-BT-globalSearch-openFilterModal'">
        <i class="sn-icon sn-icon-search-options" :title="i18n.t('search.index.more_search_options')"></i>
        <span class="tw-hidden xl:inline">{{ i18n.t('search.index.more_search_options') }}</span>
        <span
          v-if="activeFilters.length > 0"
          class="absolute -right-1 -top-1 rounded-full bg-sn-science-blue text-white flex items-center justify-center w-4 h-4 text-[9px]"
        >
          {{ activeFilters.length }}
        </span>
      </button>
      <template v-if="activeFilters.length > 0">
        <div class="h-4 w-[1px] bg-sn-grey"></div>
        <button class="btn btn-light btn-sm" @click="resetFilters" :data-e2e="'e2e-BT-globalSearch-resetFilters'">
          <i class="sn-icon sn-icon-close" :title="i18n.t('search.index.clear_filters')"></i>
          <span class="tw-hidden xl:inline">{{ i18n.t('search.index.clear_filters') }}</span>
        </button>
      </template>
      <button v-if="activeGroup" class="btn btn-light btn-sm" @click="resetGroup" :data-e2e="'e2e-BT-globalSearch-resetGroup'">
        <i class="sn-icon sn-icon-undo" :title="i18n.t('search.index.all_results')"></i>
        <span class="tw-hidden xl:inline">{{ i18n.t('search.index.all_results') }}</span>
      </button>
    </div>
    <template v-for="group in searchGroups">
      <component
        ref="groupComponents"
        :key="group"
        :is="group"
        v-if="activeGroup === group || !activeGroup"
        :selected="activeGroup === group"
        :query="localQuery"
        :searchUrl="searchUrl"
        :filters="filters"
        @selectGroup="setActiveGroup"
        @updated="calculateTotalElements"
      />
    </template>
    <div v-if="totalElements === 0 && activeGroup === null" class="bg-white rounded p-4">
      <NoSearchResult />
    </div>
    <teleport to='body'>
      <FiltersModal
        v-if="filterModalOpened"
        :teamsUrl="teamsUrl"
        :usersUrl="usersUrl"
        :filters="filters"
        :currentTeam="currentTeam"
        @search="applyFilters"
        @close="filterModalOpened = false"
      />
    </teleport>
  </div>
</template>

<script>
/* global HelperModule GLOBAL_CONSTANTS */

import FoldersComponent from './groups/folders.vue';
import ProjectsComponent from './groups/projects.vue';
import ExperimentsComponent from './groups/experiments.vue';
import MyModulesComponent from './groups/my_modules.vue';
import MyModuleProtocolsComponent from './groups/my_module_protocols.vue';
import ResultsComponent from './groups/results.vue';
import AssetsComponent from './groups/assets.vue';
import RepositoryRowsComponent from './groups/repository_rows.vue';
import ProtocolsComponent from './groups/protocols.vue';
import LabelTemplatesComponent from './groups/label_templates.vue';
import ReportsComponent from './groups/reports.vue';
import FiltersModal from './filters_modal.vue';
import GeneralDropdown from '../shared/general_dropdown.vue';
import NoSearchResult from './groups/helpers/no_search_result.vue';
import StringWithEllipsis from '../shared/string_with_ellipsis.vue';

export default {
  emits: ['search', 'selectGroup'],
  name: 'GlobalSearch',
  props: {
    query: {
      type: String,
      required: true
    },
    searchUrl: {
      type: String,
      required: true
    },
    teamsUrl: {
      type: String,
      required: true
    },
    usersUrl: {
      type: String,
      required: true
    },
    currentTeam: {
      type: Number || String,
      required: true
    },
    singleTeam: {
      type: Boolean,
      default: false
    }
  },
  components: {
    FoldersComponent,
    ProjectsComponent,
    ExperimentsComponent,
    MyModulesComponent,
    MyModuleProtocolsComponent,
    ResultsComponent,
    AssetsComponent,
    RepositoryRowsComponent,
    ProtocolsComponent,
    LabelTemplatesComponent,
    ReportsComponent,
    FiltersModal,
    GeneralDropdown,
    NoSearchResult,
    StringWithEllipsis
  },
  data() {
    return {
      filters: {},
      localQuery: this.query,
      filterModalOpened: false,
      previousQueries: [],
      invalidQuery: false,
      activeGroup: null,
      focusedHistoryItem: null,
      totalElements: 0,
      searchGroups: [
        'FoldersComponent',
        'ProjectsComponent',
        'ExperimentsComponent',
        'MyModulesComponent',
        'MyModuleProtocolsComponent',
        'ResultsComponent',
        'AssetsComponent',
        'RepositoryRowsComponent',
        'ProtocolsComponent',
        'LabelTemplatesComponent',
        'ReportsComponent'
      ]
    };
  },
  computed: {
    activeFilters() {
      return Object.keys(this.filters).filter((key) => {
        if (key === 'created_at' || key === 'updated_at') {
          return this.filters[key].on || this.filters[key].from || this.filters[key].to;
        } if (key === 'teams' || key === 'users') {
          return this.filters[key].length > 0;
        }
        return this.filters[key];
      });
    },
    canOpenHistory() {
      return this.previousQueries.length > 0 && this.localQuery.length === 0;
    },
    reversedPreviousQueries() {
      return [...this.previousQueries].reverse();
    }
  },
  created() {
    const urlParams = new URLSearchParams(window.location.search);
    this.filters = {
      created_at: {
        on: null,
        from: null,
        to: null
      },
      updated_at: {
        on: null,
        from: null,
        to: null
      },
      include_archived: urlParams.get('include_archived') === 'true',
      teams: (this.singleTeam ? [] : urlParams.getAll('teams[]').map((team) => parseInt(team, 10))),
      users: urlParams.getAll('users[]').map((user) => parseInt(user, 10)),
      group: urlParams.get('group')
    };
    ['created_at', 'updated_at'].forEach((key) => {
      ['on', 'from', 'to', 'mode'].forEach((subKey) => {
        if (urlParams.get(`${key}[${subKey}]`)) {
          this.filters[key][subKey] = subKey !== 'mode' ? new Date(urlParams.get(`${key}[${subKey}]`)) : urlParams.get(`${key}[${subKey}]`);
        }
      });
    });

    if (this.filters.group) {
      this.activeGroup = this.filters.group;
    }

    this.previousQueries = JSON.parse(localStorage.getItem('quickSearchHistory') || '[]');
  },
  methods: {
    calculateTotalElements() {
      let total = 0;
      if (this.$refs.groupComponents) {
        this.$refs.groupComponents.forEach((group) => {
          total += group.total;
        });
      }
      this.totalElements = total;
    },
    setActiveGroup(group) {
      if (group === this.activeGroup) {
        this.activeGroup = null;
      } else {
        this.activeGroup = group;
      }

      this.filters.group = this.activeGroup;
    },
    setQuery(query) {
      this.localQuery = query;
      this.invalidQuery = false;
      this.$refs.historyContainer.isOpen = false;
    },
    changeQuery(event) {
      if (event.target.value === this.localQuery) {
        return;
      }

      this.localQuery = event.target.value;

      if (event.target.value.length < GLOBAL_CONSTANTS.NAME_MIN_LENGTH) {
        this.invalidQuery = true;
        HelperModule.flashAlertMsg(this.i18n.t('general.query.length_too_short', { min_length: GLOBAL_CONSTANTS.NAME_MIN_LENGTH }), 'danger');
        return;
      }

      if (event.target.value.length > GLOBAL_CONSTANTS.NAME_MAX_LENGTH) {
        this.invalidQuery = true;
        HelperModule.flashAlertMsg(this.i18n.t('general.query.length_too_long', { max_length: GLOBAL_CONSTANTS.NAME_MAX_LENGTH }), 'danger');
        return;
      }

      this.invalidQuery = false;
      this.saveQuery();
    },
    saveQuery() {
      if (this.localQuery.length > 1) {
        if (this.previousQueries[this.previousQueries.length - 1] === this.localQuery) return;

        this.previousQueries.push(this.localQuery);

        if (this.previousQueries.length > 5) {
          this.previousQueries.shift();
        }
        localStorage.setItem('quickSearchHistory', JSON.stringify(this.previousQueries));
        this.$refs.historyContainer.isOpen = false;
      }
    },
    applyFilters(filters) {
      this.filters = filters;
      this.filterModalOpened = false;

      this.activeGroup = this.filters.group;
    },
    resetGroup() {
      this.activeGroup = null;
      this.filters.group = null;
    },
    focusHistoryItem(event) {
      if (this.focusedHistoryItem === null && (event.key === 'ArrowDown' || event.key === 'ArrowUp')) {
        this.focusedHistoryItem = 0;
        this.$refs.historyItems[this.focusedHistoryItem].focus();
      } else if (event.key === 'ArrowDown') {
        event.preventDefault();
        this.focusedHistoryItem += 1;
        if (this.focusedHistoryItem >= this.$refs.historyItems.length) {
          this.focusedHistoryItem = 0;
        }
        this.$refs.historyItems[this.focusedHistoryItem].focus();
      } else if (event.key === 'ArrowUp') {
        event.preventDefault();
        this.focusedHistoryItem -= 1;
        if (this.focusedHistoryItem < 0) {
          this.focusedHistoryItem = this.$refs.historyItems.length - 1;
        }
        this.$refs.historyItems[this.focusedHistoryItem].focus();
      } else if (event.key === 'Escape') {
        this.$refs.historyContainer.isOpen = false;
      }
    },
    resetFilters() {
      this.filters = {
        created_at: {
          on: null,
          from: null,
          to: null
        },
        updated_at: {
          on: null,
          from: null,
          to: null
        },
        include_archived: false,
        teams: [],
        users: [],
        group: null
      };
      this.activeGroup = null;
    }
  }
};
</script>
