<template>
  <GeneralDropdown ref="container" :canOpen="canOpen" :fieldOnlyOpen="true" @close="filtersOpened = false; flyoutOpened = false" @open="flyoutOpened = true">
    <template v-slot:field>
      <div class="sci--navigation--top-menu-search left-icon sci-input-container-v2" :class="{'disabled' : !currentTeam}" :title="i18n.t('nav.search')">
        <input ref="searchField" type="text" class="!pr-20" v-model="searchQuery" @keydown="focusHistoryItem"
               :class="{'active': flyoutOpened}"
               @focus="openHistory" :placeholder="i18n.t('nav.search')" @keydown.enter="saveQuery"/>
        <i class="sn-icon sn-icon-search"></i>
        <div v-if="this.searchQuery.length > 1" class="flex items-center gap-1 absolute right-2 top-1.5">
          <div class="btn btn-light icon-btn btn-xs" @click="this.searchQuery = ''; $refs.searchField.focus()">
            <i class="sn-icon sn-icon-close  m-0"></i>
          </div>
          <div class="btn btn-light icon-btn btn-xs" :title="i18n.t('search.quick_search.search_options')"
               :class="{'active': filtersOpened}" @click="filtersOpened = !filtersOpened">
            <i class="sn-icon sn-icon-search-options m-0"></i>
          </div>
        </div>
      </div>
    </template>
    <template v-slot:flyout >
      <SearchFilters
        class="px-3.5"
        v-if="filtersOpened"
        :teamsUrl="teamsUrl"
        :usersUrl="usersUrl"
        :currentTeam="currentTeam"
        :searchUrl="searchUrl"
        :searchQuery="searchQuery"
        @cancel="filtersOpened = false"
      ></SearchFilters>
      <div v-else-if="showHistory" class="max-w-[600px]">
        <div v-for="(query, i) in reversedPreviousQueries" @click="setQuery(query)" :key="i"
             ref="historyItems"
             tabindex="1"
             @keydown="focusHistoryItem"
             @keydown.enter="setQuery(query)"
             class="flex px-3 h-11 items-center gap-2 hover:bg-sn-super-light-grey cursor-pointer">
          <i class="sn-icon sn-icon-history-search"></i>
          {{ query }}
        </div>
      </div>
      <div v-else class="w-[600px]">
        <div class="flex items-center gap-2">
          <button class="btn btn-secondary btn-xs"
                  :class="{'active': quickFilter === 'experiments'}"
                  @click="setQuickFilter('experiments')">
            {{ i18n.t('search.quick_search.experiments') }}
          </button>
          <button class="btn btn-secondary btn-xs"
                  :class="{'active': quickFilter === 'my_modules'}"
                  @click="setQuickFilter('my_modules')">
            {{ i18n.t('search.quick_search.tasks') }}
          </button>
          <button class="btn btn-secondary btn-xs"
                  :class="{'active': quickFilter === 'results'}"
                  @click="setQuickFilter('results')">
            {{ i18n.t('search.quick_search.results') }}
          </button>
        </div>
        <hr class="my-2">
        <a v-if="!loading" v-for="(result, i) in results" :key="i"
           :href="getUrl(result.attributes)"
           class="px-3 py-2 hover:bg-sn-super-light-grey cursor-pointer
                  text-sn-black hover:no-underline active:no-underline hover:text-black block"
        >
          <div class="flex items-center gap-2">
            <i class="sn-icon shrink-0" :class="getIcon(result.type)" :title="getTitle(result.type)"></i>
            <span v-if="result.attributes.archived">(A)</span>
            <StringWithEllipsis class="grow max-w-[400px]" :text="getName(result.attributes)"></StringWithEllipsis>
            <div class="ml-auto pl-4 text-sn-grey text-xs shrink-0">
              {{ result.attributes.updated_at }}
            </div>
          </div>
          <div
            class="text-sn-grey text-xs flex items-center gap-1 pl-8"
            :class="{'opacity-0': result.type.includes('label_templates')}"
          >
            <div v-for="(breadcrumb, i) in getBreadcrumb(result.attributes)" :key="i"
                class="flex items-center gap-1"
            >
              <span v="if" v-if="i !== 0">/</span>
              <span :title="breadcrumb" class="truncate max-w-[130px]">{{ breadcrumb }}</span>
            </div>
          </div>
        </a>
        <div v-else v-for="i in Array(5).fill(5)" class="px-3 py-2">
          <div class="flex items-center gap-2 mb-2">
            <div class="h-5 w-5 bg-sn-light-grey rounded shrink-0"></div>
            <div class="h-5 grow max-w-[200px] bg-sn-light-grey rounded shrink-0"></div>
            <div class="h-5 w-12 bg-sn-light-grey rounded shrink-0 ml-auto"></div>
          </div>
          <div class="flex items-center gap-2 pl-8">
            <div class="h-3 grow max-w-[200px] bg-sn-light-grey rounded shrink-0"></div>
          </div>
        </div>
        <div v-if="!loading && results.length === 0" class="p-2 flex items-center gap-6">
          <i class="sn-icon sn-icon-search text-sn-sleepy-grey" style="font-size: 64px !important;"></i>
          <div>
            <b>{{ i18n.t('search.quick_search.empty_title', {team: currentTeamName}) }}</b>
            <div class="text-xs text-sn-dark-grey">
              {{ i18n.t('search.quick_search.empty_description', {query: searchQuery}) }}
            </div>
          </div>
        </div>
        <hr class="my-2">
        <div class="btn btn-light" @click="searchValue">
          {{ i18n.t('search.quick_search.all_results', {query: searchQuery}) }}
        </div>
      </div>
    </template>
  </GeneralDropdown>
</template>

<script>
import GeneralDropdown from '../shared/general_dropdown.vue';
import StringWithEllipsis from '../shared/string_with_ellipsis.vue';
import SearchFilters from '../global_search/filters.vue';
import axios from '../../packs/custom_axios.js';

export default {
  name: 'QuickSearch',
  props: {
    quickSearchUrl: {
      type: String,
      required: true
    },
    currentTeam: {
      type: Number
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
    }
  },
  components: {
    GeneralDropdown,
    StringWithEllipsis,
    SearchFilters
  },
  computed: {
    reversedPreviousQueries() {
      return [...this.previousQueries].reverse();
    },
    canOpen() {
      return this.previousQueries.length > 0 || this.searchQuery.length > 1;
    },
    showHistory() {
      return this.searchQuery.length < 2;
    },
    currentTeamName() {
      return document.querySelector('body').dataset.currentTeamName;
    }
  },
  watch: {
    searchQuery() {
      this.openHistory();

      if (this.searchQuery.length > 1) {
        this.fetchQuickSearchResults();
      }
    }
  },
  data() {
    return {
      searchQuery: '',
      previousQueries: [],
      quickFilter: null,
      results: [],
      loading: false,
      filtersOpened: false,
      focusedHistoryItem: null,
      flyoutOpened: false
    };
  },
  mounted() {
    this.previousQueries = JSON.parse(localStorage.getItem('quickSearchHistory') || '[]');
  },
  methods: {
    openHistory() {
      this.$refs.container.isOpen = this.canOpen;
    },
    getIcon(type) {
      switch (type) {
        case 'projects':
          return 'sn-icon-projects';
        case 'experiments':
          return 'sn-icon-experiment';
        case 'my_modules':
          return 'sn-icon-task';
        case 'project_folders':
          return 'sn-icon-folder';
        case 'protocols':
          return 'sn-icon-protocols-templates';
        case 'results':
          return 'sn-icon-results';
        case 'repository_rows':
          return 'sn-icon-inventory';
        case 'reports':
          return 'sn-icon-reports';
        case 'steps':
          return 'sn-icon-steps';
        case 'zebra_label_templates':
          return 'sn-icon-label-templates';
        case 'fluics_label_templates':
          return 'sn-icon-label-templates';
        default:
          return null;
      }
    },
    getTitle(type) {
      switch (type) {
        case 'projects':
          return this.i18n.t('search.quick_search.project');
        case 'experiments':
          return this.i18n.t('search.quick_search.experiment');
        case 'my_modules':
          return this.i18n.t('search.quick_search.task');
        case 'project_folders':
          return this.i18n.t('search.quick_search.folder');
        case 'protocols':
          return this.i18n.t('search.quick_search.protocol');
        case 'results':
          return this.i18n.t('search.quick_search.result');
        case 'repository_rows':
          return this.i18n.t('search.quick_search.inventory_item');
        case 'reports':
          return this.i18n.t('search.quick_search.report');
        case 'steps':
          return this.i18n.t('search.quick_search.step');
        case 'zebra_label_templates':
          return this.i18n.t('search.quick_search.label_template');
        case 'fluics_label_templates':
          return this.i18n.t('search.quick_search.label_template');
        default:
          return null;
      }
    },
    getName(attributes) {
      return attributes.breadcrumbs[attributes.breadcrumbs.length - 1].name;
    },
    getUrl(attributes) {
      return attributes.breadcrumbs[attributes.breadcrumbs.length - 1].url;
    },
    getBreadcrumb(attributes) {
      const breadcrumbs = attributes.breadcrumbs.map((breadcrumb) => breadcrumb.name);
      breadcrumbs.pop();
      breadcrumbs.shift();
      if (attributes.code) {
        breadcrumbs.push(`ID: ${attributes.code}`);
      }
      return breadcrumbs;
    },
    setQuery(query) {
      this.searchQuery = query;
      this.$nextTick(() => {
        this.$refs.searchField.focus();
      });
    },
    saveQuery() {
      if (this.searchQuery.length > 1) {
        this.previousQueries.push(this.searchQuery);

        if (this.previousQueries.length > 5) {
          this.previousQueries = this.previousQueries.slice(1);
        }

        localStorage.setItem('quickSearchHistory', JSON.stringify(this.previousQueries));

        this.searchValue();
      }
    },
    setQuickFilter(filter) {
      this.quickFilter = this.quickFilter === filter ? null : filter;
      this.fetchQuickSearchResults();
    },
    fetchQuickSearchResults() {
      if (this.loading) return;

      this.loading = true;

      const params = {
        query: this.searchQuery,
        filter: this.quickFilter
      };

      axios.get(this.quickSearchUrl, { params })
        .then((response) => {
          this.results = response.data.data;
          this.loading = false;
          if (params.query !== this.searchQuery) {
            this.fetchQuickSearchResults();
          }
        })
        .catch(() => {
          this.results = [];
          this.loading = false;
        });
    },
    searchValue() {
      window.open(`${this.searchUrl}?q=${this.searchQuery}&teams[]=${this.currentTeam}`, '_self');
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
      }
    }
  }
};
</script>
