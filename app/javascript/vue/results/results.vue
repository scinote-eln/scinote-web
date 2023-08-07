<template>
  <div class="results-wrapper">
    <ResultsToolbar :sort="sort" @setSort="setSort" @newResult="createResult" @expandAll="expandAll" @collapseAll="collapseAll" lass="mb-3" />
    <div class="results-list">
      <Result v-for="result in results" :key="result.id" :result="result" />
    </div>
  </div>
</template>

<script>
  import axios from 'axios';
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
        sort: 'created_at_desc'
      }
    },
    created() {
      this.loadResults();
    },
    methods: {
      loadResults() {
        axios.get(
          `${this.url}?sort=${this.sort}`,
          {
            headers: {
              'Accept': 'application/json'
            }
          }
        ).then((response) => this.results = response.data.data);
      },
      setSort(sort) {
        this.sort = sort;
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
