import axios from '../../../packs/custom_axios.js';
import StringWithEllipsis from '../../shared/string_with_ellipsis.vue';
import SortFlyout from './helpers/sort_flyout.vue';
import Loader from '../loader.vue';
import ListEnd from './helpers/list_end.vue';
import NoSearchResult from './helpers/no_search_result.vue';
import CellTemplate from './helpers/cell_template.vue';
import LinkTemplate from './helpers/link_template.vue';
import TableHeader from './helpers/table_header.vue';
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
    NoSearchResult,
    ListEnd,
    CellTemplate,
    LinkTemplate,
    TableHeader
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
    };
  },
  watch: {
    filters() {
      this.reloadData();
    },
    selected() {
      if (this.selected && !this.fullDataLoaded) {
        this.reloadData();
      }
    },
    query() {
      this.reloadData();
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
      return !this.selected ? 4 : 20;
    },
    reachedEnd() {
      return !this.page && this.selected;
    },
    showNoSearchResult() {
      return this.selected && !this.loading && !this.results.length;
    }
  },
  methods: {
    labelName(object) {
      if (!object) return '';

      if (!object.archived) return object.name;

      return `${I18n.t('labels.archived')} ${object.name}`;
    },
    handleScroll() {
      if (this.loading || !this.selected) return;

      if ((window.innerHeight + window.scrollY) >= document.body.offsetHeight - 50) {
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
    reloadData() {
      if (this.query.length > 1) {
        this.results = [];
        this.page = 1;
        this.total = 0;
        this.fullDataLoaded = false;
        this.loadData();
      }
    },
    loadData() {
      if (this.query.length < 2) return;

      if (this.loading && this.page && !(this.selected && !this.fullDataLoaded)) return;

      const fullView = this.selected;
      const currentPage = this.page;
      this.loading = true;
      axios.get(this.searchUrl, {
        params: {
          q: this.query,
          sort: this.sort,
          filters: this.filters,
          group: this.group,
          preview: !fullView,
          page: currentPage
        }
      })
        .then((response) => {
          if (this.selected) this.fullDataLoaded = true;

          if (this.selected === fullView && this.page === currentPage) {
            this.results = this.results.concat(response.data.data);
            this.total = response.data.meta.total;
            this.disabled = response.data.meta.disabled;
            this.loading = false;
            this.page = response.data.meta.next_page;
          }
        })
        .finally(() => {
          if (this.selected === fullView) {
            this.loading = false;
            this.$emit('updated');
          }
        });
    }
  }
};
