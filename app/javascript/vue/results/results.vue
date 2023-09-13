<template>
  <div class="results-wrapper">
    <ResultsToolbar :sort="sort"
      :canCreate="canCreate == 'true'"
      :archived="archived == 'true'"
      :active_url="active_url"
      :archived_url="archived_url"
      @setSort="setSort"
      @setFilters="setFilters"
      @newResult="createResult"
      @expandAll="expandAll"
      @collapseAll="collapseAll"
      class="my-4"
    />
    <div class="results-list">
      <Result v-for="result in results" :key="result.id"
        :result="result"
        :resultToReload="resultToReload"
        @result:elements:loaded="resultToReload = null"
        @result:move_element="reloadResult"
        @result:attachments:loaded="resultToReload = null"
        @result:move_attachment="reloadResult"
        @result:duplicated="resetPageAndReload"
        @result:archived="removeResult"
        @result:deleted="removeResult"
        @result:restored="removeResult"
      />
    </div>
    <div v-if="results.length > 0" class="p-3 rounded-md bg-sn-white my-4">
      <button v-if="canCreate" :title="i18n.t('my_modules.results.add_title')" class="btn btn-secondary" @click="createResult">
        <i class="sn-icon sn-icon-new-task"></i>
        {{ i18n.t('my_modules.results.add_label') }}
      </button>
    </div>
  </div>
</template>

<script>
  import axios from '../../packs/custom_axios.js';
  import ResultsToolbar from './results_toolbar.vue';
  import Result from './result.vue';

  export default {
    name: 'Results',
    components: { ResultsToolbar, Result },
    props: {
      url: { type: String, required: true },
      canCreate: { type: String, required: true },
      archived: { type: String, required: true },
      active_url: { type: String, required: true },
      archived_url: { type: String, required: true }
    },
    data() {
      return {
        results: [],
        sort: 'created_at_desc',
        filters: {},
        resultToReload: null,
        nextPageUrl: null,
        loadingPage: false
      }
    },
    mounted() {
      window.addEventListener('scroll', this.loadResults, false);
      this.nextPageUrl = this.url;
      this.loadResults();
    },
    beforeDestroy() {
      window.removeEventListener('scroll', this.loadResults, false);
    },
    methods: {
      reloadResult(result) {
        this.resultToReload = result;
      },
      resetPageAndReload(){
        this.nextPageUrl = this.url;
        this.results = [];
        this.$nextTick(() => {
          this.loadResults();
        });
      },
      loadResults() {
        if (this.nextPageUrl === null || this.loadingPage) return;

        if (window.scrollY + window.innerHeight >= document.body.scrollHeight - 20) {
          this.loadingPage = true;
          axios.get(this.nextPageUrl, { params: { sort: this.sort, ...this.filters } }).then((response) => {
            this.results = this.results.concat(response.data.data);
            this.nextPageUrl = response.data.links.next;
            this.loadingPage = false;
          });
        }
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
              'Accept': 'application/json'
            }
          }
        ).then(
          (response) => {
            this.results = [response.data.data, ...this.results];
            window.scrollTo(0, 0);
          }
        );
      },
      expandAll() {
        $('.result-wrapper .collapse').collapse('show')
      },
      collapseAll() {
        $('.result-wrapper .collapse').collapse('hide')
      },
      removeResult(result_id) {
        this.results = this.results.filter((r) => r.attributes.id != result_id);
      }
    }
  }
</script>
