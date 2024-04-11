import axios from '../../../packs/custom_axios.js';
import StringWithEllipsis from '../../shared/string_with_ellipsis.vue';
import SortFlyout from './sort_flyout.vue';
import Loader from '../loader.vue';
import NoSearchResult from '../no_search_result.vue';
/* global GLOBAL_CONSTANTS I18n */

export default {
  props: {
    searchUrl: String,
    query: String,
    selected: Boolean,
    filters: Object
  },
  components: {
    StringWithEllipsis,
    SortFlyout,
    Loader,
    NoSearchResult
  },
  data() {
    return {
      sort: 'created_desc',
      results: [],
      total: 0,
      loading: false,
      page: 1,
      disabled: false,
      fullDataLoaded: false,
      loaderHeight: 24,
      loaderGap: 10,
      loaderYPadding: 10,
      noSearchResultHeight: 0
    };
  },
  watch: {
    selected() {
      if (this.selected) {
        if (!this.fullDataLoaded) {
          this.total = 0;
          this.results = [];
          this.loadData();
        }
      }
    },
    query() {
      this.results = [];
      this.page = 1;
      this.total = 0;
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
    },
    viewAll() {
      return !this.selected && this.total > GLOBAL_CONSTANTS.GLOBAL_SEARCH_PREVIEW_LIMIT;
    },
    loaderRows() {
      // h-[24px] gap-y-[10px] py-[10px]
      if (this.loading && (!this.selected || this.total)) return GLOBAL_CONSTANTS.GLOBAL_SEARCH_PREVIEW_LIMIT;
      if (this.selected && this.loading) {
        const availableHeight = window.innerHeight - this.$refs.content.getBoundingClientRect().top;
        // loaderHeight + loaderGap +  headerLoaderHeight + headerContentGap
        const offSet = this.loaderHeight + this.loaderGap + 32 + 20;

        return Math.floor((availableHeight - offSet) / (this.loaderHeight + this.loaderGap + (2 * this.loaderYPadding)));
      }

      return 0;
    },
    reachedEnd() {
      return Math.ceil(this.total / GLOBAL_CONSTANTS.SEARCH_LIMIT) === this.page;
    },
    showNoSearchResult() {
      return this.selected && !this.loading && !this.results.length;
    }
  },
  methods: {
    labelName(object) {
      if (!object.archived) return object.name;

      return `${I18n.t('labels.archived')} ${object.name}`;
    },
    handleScroll() {
      if (this.loading || !this.selected) return;

      if ((window.innerHeight + window.scrollY) >= document.body.offsetHeight) {
        if (this.results.length < this.total) {
          this.loadData();
        }
      }
    },
    changeSort(sort) {
      this.sort = sort;
      this.results = [];
      this.page = 1;
      this.loadData();
    },
    loadData() {
      if (this.loading && this.page) return;

      this.loading = true;
      axios.get(this.searchUrl, {
        params: {
          q: this.query,
          sort: this.sort,
          filters: this.filters,
          group: this.group,
          preview: !this.selected,
          page: this.page
        }
      })
        .then((response) => {
          if (this.selected) this.fullDataLoaded = true;
          this.results = this.results.concat(response.data.data);
          this.total = response.data.meta.total;
          this.disabled = response.data.meta.disabled;
          this.loading = false;
          this.page = response.data.meta.next_page;
          if (this.results.length === 0 && this.selected) {
            const availableHeight = window.innerHeight - this.$refs.content.getBoundingClientRect().top;
            this.noSearchResultHeight = availableHeight - 20;
          }
        })
        .finally(() => {
          this.loading = false;
        });
    }
  }
};
