<template>
  <div class="relative">
    <GeneralDropdown ref="dropdown" position="right" @close="$emit('applyFilters', filterValues)">
      <template v-slot:field>
        <button class="btn btn-light icon-btn btn-black"
                :title="i18n.t('filters_modal.title')">
          <i class="sn-icon sn-icon-filter"></i>
          <div
            v-if="appliedDotIsShown"
            class="w-1.5 h-1.5 rounded bg-sn-delete-red absolute right-1 top-1"
          ></div>
        </button>
      </template>
      <template v-slot:flyout>
        <div class="p-3.5 pb-4 flex items-center min-w-[400px]">
          <h2>{{ i18n.t('filters_modal.title') }}</h2>
          <button @click="close" type="button"
                  class="ml-auto btn btn-light btn-black icon-btn">
            <i class="sn-icon sn-icon-close"></i>
          </button>
        </div>
        <div class="max-h-[40vh] px-3.5 overflow-y-auto max-w-[400px]">
          <div v-for="filter in filters" :key="filter.key">
            <Component
              :is="`${filter.type}Filter`"
              :filter="filter"
              :values="filterValues"
              @update="updateFilter" />
          </div>
        </div>
        <div class="p-3.5 flex items-center justify-end gap-4">
          <div @click.prevent="clearFilters" class="btn btn-secondary">
            {{ i18n.t('filters_modal.clear_btn') }}
          </div>
          <div @click.prevent="applyFilters" class="btn btn-primary">
            {{ i18n.t('filters_modal.show_btn.one') }}
          </div>
        </div>
      </template>
    </GeneralDropdown>
  </div>
</template>
<script>
import TextFilter from './inputs/text_filter.vue';
import SelectFilter from './inputs/select_filter.vue';
import DateRangeFilter from './inputs/date_range_filter.vue';
import CheckboxFilter from './inputs/checkbox_filter.vue';
import GeneralDropdown from '../general_dropdown.vue';

export default {
  name: 'FilterDropdown',
  props: {
    filters: { type: Array, required: true }
  },
  components: {
    TextFilter,
    SelectFilter,
    DateRangeFilter,
    CheckboxFilter,
    GeneralDropdown
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
      return Object.keys(this.filterValues).length !== 0;
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
      this.$emit('applyFilters', this.filterValues);
      this.close();
    },
    clearFilters() {
      this.filterValues = {};
      this.$emit('applyFilters', this.filterValues);
      this.close();
    },
    close() {
      this.$refs.dropdown.$refs.field.click();
    }
  }
};
</script>
