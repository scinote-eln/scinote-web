<template>
  <div class="results-wrapper">
    <ResultsToolbar :urls="{}" class="mb-3" />
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
        results: []
      }
    },
    created() {
      this.loadResults();
    },
    methods: {
      loadResults() {
        axios.get(
          this.url,
          {
            headers: {
              'Accept': 'application/json'
            }
          }
        ).then((response) => this.results = response.data.data);
      }
    }
  }
</script>
