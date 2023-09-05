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
      <Result v-for="result in results" :key="result.attributes.id"
        :result="result"
        :resultToReload="resultToReload"
        @result:elements:loaded="resultToReload = null"
        @result:move_element="reloadResult"
        @result:attachments:loaded="resultToReload = null"
        @result:move_attachment="reloadResult"
        @duplicated="resetPageAndReload"
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
        resultToReload: null,
        nextPage: 1,
        loadingPage: false
      }
    },
    mounted() {
      window.addEventListener('scroll', this.loadResults, false);
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
        this.nextPage = 1;
        this.results = [];
        this.$nextTick(() => {
          this.loadResults();
        });
      },
      loadResults() {
        if (this.nextPage == null || this.loadingPage) return;

        if (window.scrollY + window.innerHeight >= document.body.scrollHeight - 20) {
          this.loadingPage = true;
          axios.get(
            `${this.url}`,
            {
              params: {
                sort: this.sort,
                page: this.nextPage,
                ...this.filters
              },
              headers: {
                'Accept': 'application/json'
              }
            },
          ).then((response) => {
            this.results = this.results.concat(response.data.results);
            this.nextPage = response.data.next_page;
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
