<template>
  <div class="content-pane flexible with-grey-background">
    <div class="content-header">
      <div class="title-row">
        <h1 class="mt-0">
          {{ i18n.t('search.index.results_title_html', { query: localQuery }) }}
        </h1>
      </div>
    </div>
    <div class="bg-white rounded p-4 flex gap-2.5 z-10 items-center mb-4 sticky top-0">
      <GeneralDropdown ref="historyContainer" :canOpen="canOpenHistory" :fieldOnlyOpen="true" >
        <template v-slot:field>
          <div class="left-icon sci-input-container-v2 w-72 input-sm"
              :title="i18n.t('nav.search')" :class="{'error': invalidQuery}">
            <input ref="searchField"
              type="text"
              class="!pr-9"
              :value="localQuery"
              @change="changeQuery"
              @keydown.enter="changeQuery"
              @blur="changeQuery"
              :placeholder="i18n.t('nav.search')"
            />
            <i class="sn-icon sn-icon-search"></i>
            <i v-if="localQuery.length > 0"
              class="sn-icon cursor-pointer sn-icon-close absolute right-0 -top-0.5"
              @click="localQuery = ''; $refs.searchField.focus()"></i>
          </div>
        </template>
        <template v-slot:flyout >
          <div v-for="(query, i) in reversedPreviousQueries" @click="setQuery(query)" :key="i"
              ref="historyItems"
              tabindex="1"
              @keydown.enter="setQuery(query)"
              class="flex px-3 h-11 items-center gap-2 hover:bg-sn-super-light-grey cursor-pointer">
            <i class="sn-icon sn-icon-history-search"></i>
            {{ query }}
          </div>
        </template>
      </GeneralDropdown>
      <div class="flex items-center gap-2.5">
        <button class="btn btn-secondary btn-sm" :class="{'active': activeGroup == 'ExperimentsComponent'}" @click="setActiveGroup('ExperimentsComponent')">
          {{ i18n.t('search.index.experiments') }}
        </button>
        <button class="btn btn-secondary btn-sm" :class="{'active': activeGroup == 'MyModulesComponent'}" @click="setActiveGroup('MyModulesComponent')">
          {{ i18n.t('search.index.tasks') }}
        </button>
        <button class="btn btn-secondary btn-sm" :class="{'active': activeGroup == 'ResultsComponent'}" @click="setActiveGroup('ResultsComponent')">
          {{ i18n.t('search.index.task_results') }}
        </button>
      </div>
      <button class="btn btn-light btn-sm" @click="filterModalOpened = true">
        <i class="sn-icon sn-icon-search-options"></i>
        <span class="tw-hidden lg:inline">{{ i18n.t('search.index.more_search_options') }}</span>
        <span
          v-if="activeFilters.length > 0"
          class="absolute -right-1 -top-1 rounded-full bg-sn-science-blue text-white flex items-center justify-center w-4 h-4 text-[9px]"
        >
          {{ activeFilters.length }}
        </span>
      </button>
      <template v-if="activeFilters.length > 0">
        <div class="h-4 w-[1px] bg-sn-grey"></div>
        <button class="btn btn-light btn-sm" @click="resetFilters">
          <i class="sn-icon sn-icon-close"></i>
          <span class="tw-hidden lg:inline">{{ i18n.t('search.index.clear_filters') }}</span>
        </button>
      </template>
      <button v-if="activeGroup" class="btn btn-light btn-sm" @click="resetGroup">
        <i class="sn-icon sn-icon-undo"></i>
        <span class="tw-hidden lg:inline">{{ i18n.t('search.index.all_results') }}</span>
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
    <div v-if="totalElements === 0" class="bg-white rounded p-4">
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
    NoSearchResult
  },
  data() {
    return {
      filters: {},
      localQuery: this.query,
      filterModalOpened: false,
      previousQueries: [],
      invalidQuery: false,
      activeGroup: null,
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
      teams: urlParams.getAll('teams[]').map((team) => parseInt(team, 10)),
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

      if (event.target.value.length < 2) {
        this.invalidQuery = true;
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
