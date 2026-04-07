<template>
  <div>
    <ArchiveToolbar
      :mode="'results'"
      :sort="sort"
      :objects="results"
      :objectsCollapsed="resultsCollapsed"
      @setSort="setSort"
      @setFilters="setFilters"
      @expandAll="expandResults"
      @collapseAll="collapseResults"
      @update:mode="$emit('update:mode', $event)"
    />
    <div class="results-wrapper">
      <div
        :class="{ 'tw-hidden': loadingOverlay }"
        class="results-list">
        <Result v-for="result in results" :key="result.id"
          ref="results"
          :result="result"
          :protocolId="protocolId"
          @result:deleted="removeResult"
          @result:restored="removeResult"
          @result:collapsed="checkResultsState"
        />
        <div v-if="!loadingOverlay && results.length === 0" class="px-4 py-6 bg-white my-4 text-gray-500">
          {{ i18n.t('my_modules.results.no_results_placeholder') }}
        </div>
      </div>
      <LoadingOverlay v-if="loadingOverlay" />
    </div>
  </div>
</template>

<script>
import axios from '../../packs/custom_axios.js';
import Result from '../results/archived_result.vue';
import ArchiveToolbar from './archive_toolbar.vue';
import LoadingOverlay from '../results/loading_overlay.vue';
import ResultsCollapseStateMixin from '../results/mixins/results_collapse_state.js';

import {
  my_module_results_path,
  change_results_state_my_module_path
} from '../../routes.js';

export default {
  name: 'ArchiieResults',
  props: {
    myModuleId: {
      required: true
    },
    protocolId: {
      required: true
    }
  },
  data() {
    return {
      results: [],
      sort: null,
      filters: {},
      resultToReload: null,
      nextPageUrl: null,
      loadingPage: false,
      loadingOverlay: false,
      resultsCollapsed: false
    };
  },
  components: {
    Result,
    LoadingOverlay,
    ArchiveToolbar
  },
  mixins: [ResultsCollapseStateMixin],
  created() {
    this.loadingOverlay = true;
  },
  computed: {
    url() {
      return my_module_results_path(this.myModuleId, { view_mode: 'archived' });
    },
    changeStatesUrl() {
      return change_results_state_my_module_path(this.myModuleId);
    }
  },
  mounted() {
    window.addEventListener('scroll', this.infiniteScrollLoad, false);
    this.nextPageUrl = this.url;
    this.loadResults();
  },
  beforeUnmount() {
    window.removeEventListener('scroll', this.infiniteScrollLoad, false);
  },
  methods: {
    reloadResult(result) {
      this.resultToReload = result;
    },
    infiniteScrollLoad() {
      setTimeout(() => {
        if (window.scrollY + window.innerHeight >= document.body.scrollHeight - 20) {
          this.loadResults();
        }
      }, 500);
    },
    resetPageAndReload() {
      this.nextPageUrl = this.url;
      this.loadingOverlay = true;
      this.results = [];
      this.$nextTick(() => {
        this.loadResults();
      });
    },
    loadResults() {
      if (this.nextPageUrl === null || this.loadingPage) return;

      if ((window.scrollY + window.innerHeight >= document.body.scrollHeight - 20) || this.loadingOverlay) {
        this.loadingPage = true;
        const params = this.sort ? { ...this.filters, sort: this.sort } : { ...this.filters };
        params['format'] = 'json';
        axios.get(this.nextPageUrl, { params }).then((response) => {
          this.results = this.results.concat(response.data.data);
          this.results.forEach(result => {
            result.attachments = []
            result.relationships.assets.data.forEach((asset) => {
              result.attachments.push(response.data.included.find((a) => a.id === asset.id && a.type === 'assets'));
            });
            result.elements = [];
            result.relationships.result_orderable_elements.data.forEach((element) => {
              result.elements.push(response.data.included.find((e) => e.id === element.id && e.type === 'result_orderable_elements'));
            });
          });
          this.sort = response.data.meta.sort;
          this.nextPageUrl = response.data.links.next;
          this.loadingPage = false;

          this.infiniteScrollLoad();

          this.loadingOverlay = false;

          setTimeout(() => {
            this.checkResultsState()
          }, 100);
        });
      }
    },
    setSort(sort) {
      this.sort = sort;
      this.loadingOverlay = true;
      this.resetPageAndReload();
    },
    setFilters(filters) {
      this.filters = filters;
      this.loadingOverlay = true;
      this.resetPageAndReload();
    },
    removeResult(result_id) {
      this.results = this.results.filter((r) => r.id != result_id);
    },
  }
};
</script>
