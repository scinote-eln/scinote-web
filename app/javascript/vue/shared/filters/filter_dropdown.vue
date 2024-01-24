<template>
  <div class="relative">
    <div ref="dropdown" class="filter-container dropdown" :class="{ 'filters-applied': appliedDotIsShown }">
      <button class="btn btn-light icon-btn filter-button" :title="i18n.t('filters_modal.title')" data-toggle="dropdown"><i class="sn-icon sn-icon-filter"></i></button>
      <div class="dropdown-menu dropdown-menu-right sci-flyout" @click.stop.self>
        <div class="sci-flyout-header">
          <div class="sci-flyout-title">{{ i18n.t('filters_modal.title') }}</div>
          <button @click="toggleDropdown" type="button" class="ml-auto btn btn-light btn-black icon-btn" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
        </div>
        <div class="sci-flyout-body max-h-[400px] overflow-y-auto perfect-scrollbar relative w-[calc(100%_+_1.125rem)] pr-5">
          <div v-for="filter in filters" :key="filter.key + resetFilters" class="">
            <Component :is="`${filter.type}Filter`" :filter="filter" :value="filterValues[filter.key]" @update="updateFilter" />
          </div>
        </div>
        <div class="sci-flyout-footer">
          <div @click.prevent="clearFilters" class="btn btn-secondary">
            {{ i18n.t('filters_modal.clear_btn') }}
          </div>
          <div @click.prevent="applyFilters" class="btn btn-primary">
            {{ i18n.t('filters_modal.show_btn.one') }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import TextFilter from './inputs/text_filter.vue';
import SelectFilter from './inputs/select_filter.vue';
import DateRangeFilter from './inputs/date_range_filter.vue';
import CheckboxFilter from './inputs/checkbox_filter.vue';

export default {
  name: 'FilterDropdown',
  props: {
    filters: { type: Array, required: true }
  },
  components: {
    TextFilter, SelectFilter, DateRangeFilter, CheckboxFilter
  },
  data() {
    return {
      filterValues: {},
      filtersApplied: false,
      resetFilters: false
    };
  },
  computed: {
    appliedDotIsShown() {
      return this.filtersApplied && Object.keys(this.filterValues).length !== 0;
    }
  },
  methods: {
    updateFilter(params) {
      if (params.value !== '' && params.value !== undefined && params.value !== null) {
        this.filterValues[params.key] = params.value;
      } else {
        delete this.filterValues[params.key];
      }
    },
    applyFilters() {
      this.filtersApplied = true;
      this.$emit('applyFilters', this.filterValues);
      this.toggleDropdown();
    },
    clearFilters() {
      this.filterValues = {};
      this.filtersApplied = false;

      // This changes filter keys in the v-for, so they get fully reloaded,
      // which prevents perserved state issues with datepickers
      this.resetFilters = !this.resetFilters;
      this.$emit('applyFilters', this.filterValues);
      this.toggleDropdown();
    },
    toggleDropdown() {
      this.$refs.dropdown.click();
    }
  }
};
</script>
