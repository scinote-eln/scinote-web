<template>
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
    <div v-if="loadingOverlay">
      <div class="flex flex-col gap-8">
        <div v-for="_count in loaderResults"
            class="flex flex-col no-wrap gap-4 py-2"
          >
          <div class="h-10 w-full max-w-40 animate-skeleton rounded mr-auto"></div>
          <div class="w-full animate-skeleton rounded h-64"></div>
          <div class="flex items-center gap-6 flex-wrap">
            <div class="w-48 h-64 animate-skeleton rounded"></div>
            <div class="w-48 h-64 animate-skeleton rounded"></div>
            <div class="w-48 h-64 animate-skeleton rounded"></div>
            <div class="w-48 h-64 animate-skeleton rounded"></div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import axios from '../../packs/custom_axios.js';
import Result from '../results/result.vue';

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
  },
  data() {
    return {
      results: [],
      sort: null,
      filters: {},
      resultToReload: null,
      nextPageUrl: null,
      loadingPage: false,
      resultsCollapsed: false,
      loadingOverlay: false,
      loaderResults: 3
    };
  },
  components: {
    Result
  },
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
        });
      }
    },
    checkResultsState() {
      this.resultsCollapsed = this.$refs.results.every((result) => result.isCollapsed);
    },
    collapseResults() {
      $('.result-wrapper .collapse').collapse('hide');
      this.updateResultStateSettings(true);
      this.$refs.results.forEach((result) => { result.isCollapsed = true; });
      this.resultsCollapsed = true;
    },
    expandResults() {
      $('.result-wrapper .collapse').collapse('show');
      this.updateResultStateSettings(false);
      this.$refs.results.forEach((result) => { result.isCollapsed = false; });
      this.resultsCollapsed = false;
    },
    updateResultStateSettings(newState) {
      const data = {};

      if (newState) {
        data.collapsed = true;
      } else {
        data.expanded = true;
      }

      axios.post(this.changeStatesUrl, data);
    },
    removeResult(result_id) {
      this.results = this.results.filter((r) => r.id != result_id);
    },
  }
};
</script>
