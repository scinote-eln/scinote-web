<template>
  <div class="results-wrapper">
    <ResultsToolbar
      ref="resultsToolbar"
      :sort="sort"
      :results="results"
      :canCreate="canCreate == 'true'"
      :archived="archived == 'true'"
      :active_url="active_url"
      :archived_url="archived_url"
      :headerSticked="headerSticked"
      :moduleName="moduleName"
      :resultsCollapsed="resultsCollapsed"
      @setSort="setSort"
      @setFilters="setFilters"
      @newResult="createResult"
      @expandAll="expandResults"
      @collapseAll="collapseResults"
      class="my-4"
    />
    <div class="results-list">
      <Result v-for="result in results" :key="result.id"
        ref="results"
        :result="result"
        :resultToReload="resultToReload"
        :activeDragResult="activeDragResult"
        :userSettingsUrl="userSettingsUrl"
        @result:elements:loaded="resultToReload = null"
        @result:move_element="reloadResult"
        @result:attachments:loaded="resultToReload = null"
        @result:move_attachment="reloadResult"
        @result:duplicated="resetPageAndReload"
        @result:archived="removeResult"
        @result:deleted="removeResult"
        @result:restored="removeResult"
        @result:drag_enter="dragEnter"
        @result:collapsed="checkResultsState"
      />
    </div>
    <clipboardPasteModal v-if="showClipboardPasteModal"
                         :image="pasteImages"
                         :objects="results"
                         :objectType="'result'"
                         :selectedObjectId="firstObjectInViewport()"
                         @files="uploadFilesToResult"
                         @cancel="showClipboardPasteModal = false"
    />
  </div>
</template>

<script>
import axios from '../../packs/custom_axios.js';
import ResultsToolbar from './results_toolbar.vue';
import Result from './result.vue';

import stackableHeadersMixin from '../mixins/stackableHeadersMixin';
import moduleNameObserver from '../mixins/moduleNameObserver';

import clipboardPasteModal from '../shared/content/attachments/clipboard_paste_modal.vue';
import AssetPasteMixin from '../shared/content/attachments/mixins/paste.js';

export default {
  name: 'Results',
  components: { ResultsToolbar, Result, clipboardPasteModal },
  mixins: [stackableHeadersMixin, moduleNameObserver, AssetPasteMixin],
  props: {
    url: { type: String, required: true },
    canCreate: { type: String, required: true },
    archived: { type: String, required: true },
    active_url: { type: String, required: true },
    archived_url: { type: String, required: true },
    userSettingsUrl: { type: String, required: false }
  },
  data() {
    return {
      results: [],
      sort: null,
      filters: {},
      resultToReload: null,
      nextPageUrl: null,
      loadingPage: false,
      activeDragResult: null,
      userSettingsUrl: null,
      resultsCollapsed: false
    };
  },
  mounted() {
    this.userSettingsUrl = document.querySelector('meta[name="user-settings-url"]').getAttribute('content');
    window.addEventListener('scroll', this.infiniteScrollLoad, false);
    window.addEventListener('scroll', this.initStackableHeaders, false);
    this.nextPageUrl = this.url;
    this.loadResults();
    this.initStackableHeaders();
  },
  beforeUnmount() {
    window.removeEventListener('scroll', this.infiniteScrollLoad, false);
    window.removeEventListener('scroll', this.initStackableHeaders, false);
  },
  methods: {
    getHeader() {
      return this.$refs.resultsToolbar.$refs.resultsHeaderToolbar;
    },
    reloadResult(result) {
      this.resultToReload = result;
    },
    resetPageAndReload() {
      this.nextPageUrl = this.url;
      this.results = [];
      this.$nextTick(() => {
        this.loadResults();
      });
    },
    infiniteScrollLoad() {
      if (window.scrollY + window.innerHeight >= document.body.scrollHeight - 20) {
        this.loadResults();
      }
    },
    loadResults() {
      if (this.nextPageUrl === null || this.loadingPage) return;

      this.loadingPage = true;
      const params = this.sort ? { ...this.filters, sort: this.sort } : { ...this.filters };
      axios.get(this.nextPageUrl, { params }).then((response) => {
        this.results = this.results.concat(response.data.data);
        this.sort = response.data.meta.sort;
        this.nextPageUrl = response.data.links.next;
        this.loadingPage = false;
      });
    },
    setSort(sort) {
      this.sort = sort;
      this.resetPageAndReload();
    },
    setFilters(filters) {
      this.filters = filters;
      this.resetPageAndReload();
    },
    createResult() {
      axios.post(
        `${this.url}`,
        {
          headers: {
            Accept: 'application/json'
          }
        }
      ).then(
        (response) => {
          this.results = [{ newResult: true, ...response.data.data }, ...this.results];
          window.scrollTo(0, 0);
        }
      );
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
      const updatedData = this.results.reduce((acc, currentResult) => {
        acc[currentResult.id] = newState;
        return acc;
      }, {});

      this.results = this.results.map((result) => ({
        ...result,
        attributes: {
          ...result.attributes,
          collapsed: newState
        }
      }));

      const settings = {
        key: 'result_states',
        data: updatedData
      };

      axios.put(this.userSettingsUrl, { settings: [settings] });
    },
    removeResult(result_id) {
      this.results = this.results.filter((r) => r.id != result_id);
    },
    dragEnter(id) {
      this.activeDragResult = id;
    },
    uploadFilesToResult(file, resultId) {
      this.$refs.results.find((child) => child.result?.id == resultId).uploadFiles(file);
    },
    firstObjectInViewport() {
      const result = $('.result-wrapper:not(.locked)').toArray().find((element) => {
        const { top, bottom } = element.getBoundingClientRect();
        return bottom > 0 && top < window.innerHeight;
      });
      return result ? result.dataset.id : null;
    }
  }
};
</script>
