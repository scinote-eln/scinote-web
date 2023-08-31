<template>
  <div class="results-wrapper">
    <ResultsToolbar :sort="sort"
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
        @duplicated="loadResults"
      />
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
      url: { type: String, required: true }
    },
    data() {
      return {
        results: [],
        sort: 'created_at_desc',
        filters: {},
        resultToReload: null
      }
    },
    created() {
      this.loadResults();
    },
    methods: {
      reloadResult(result) {
        this.resultToReload = result;
      },
      loadResults() {
        axios.get(
          `${this.url}`,
          {
            params: {
              sort: this.sort,
              ...this.filters
            },
            headers: {
              'Accept': 'application/json'
            }
          },
        ).then((response) => this.results = response.data.data);
      },
      setSort(sort) {
        this.sort = sort;
        this.loadResults();
      },
      setFilters(filters) {
        this.filters = filters;
        this.loadResults();
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
            this.results.unshift(response.data.data)
          }
        );


      },
      expandAll() {
        $('.result-wrapper .collapse').collapse('show')
      },
      collapseAll() {
        $('.result-wrapper .collapse').collapse('hide')
      }
    }
  }
</script>
