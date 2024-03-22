import axios from '../../../packs/custom_axios.js';
import StringWithEllipsis from '../../shared/string_with_ellipsis.vue';

export default {
  props: {
    searchUrl: String,
    query: String,
    selected: Boolean
  },
  components: {
    StringWithEllipsis
  },
  data() {
    return {
      results: [],
      total: 0,
      loading: false,
      page: 1,
      fullDataLoaded: false
    };
  },
  watch: {
    selected() {
      if (this.selected) {
        if (!this.fullDataLoaded) {
          this.results = [];
          this.loadData();
        }
      }
    },
    query() {
      this.results = [];
      this.page = 1;
      this.fullDataLoaded = false;
      this.loadData();
    }
  },
  mounted() {
    this.loadData();
    window.addEventListener('scroll', this.handleScroll);
  },
  unmounted() {
    window.removeEventListener('scroll', this.handleScroll);
  },
  computed: {
    preparedResults() {
      if (this.selected) {
        return this.results;
      }
      return this.results.slice(0, 4);
    }
  },
  methods: {
    handleScroll() {
      if (this.loading) return;

      if ((window.innerHeight + window.scrollY) >= document.body.offsetHeight) {
        if (this.results.length < this.total) {
          this.loadData();
        }
      }
    },
    loadData() {
      if (this.loading && this.page) return;

      this.loading = true;
      axios.get(this.searchUrl, {
        params: {
          q: this.query,
          group: this.group,
          preview: !this.selected,
          page: this.page
        }
      })
        .then((response) => {
          if (this.selected) this.fullDataLoaded = true;
          this.results = this.results.concat(response.data.data);
          this.total = response.data.meta.total;
          this.loading = false;
          this.page = response.data.meta.next_page;
        })
        .finally(() => {
          this.loading = false;
        });
    }
  }
};
