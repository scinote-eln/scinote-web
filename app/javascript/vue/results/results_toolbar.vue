<template>
  <div class="result-toolbar p-3 flex justify-between rounded-md bg-sn-white">
    <div class="result-toolbar__left">
      <button v-if="canCreate" class="btn btn-secondary" @click="$emit('newResult')">
        <i class="sn-icon sn-icon-new-task"></i>
        {{ i18n.t('my_modules.results.add_label') }}
      </button>
    </div>
    <div class="result-toolbar__right flex items-center" @click="$emit('expandAll')">
      <button class="btn btn-secondary mr-3">
        {{ i18n.t('my_modules.results.expand_label') }}
      </button>
      <button class="btn btn-secondary mr-3" @click="$emit('collapseAll')">
        {{ i18n.t('my_modules.results.collapse_label') }}
      </button>

      <FilterDropdown :filters="filters" @applyFilters="setFilters" />

      <div class="dropdown">
        <button class="dropdown-toggle btn btn-light icon-btn mr-3"  id="sortDropdown" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true">
          <i class="sn-icon sn-icon-sort"></i>
        </button>
        <ul class="dropdown-menu dropdown-menu-right" aria-labelledby="sortDropdown">
          <li v-for="sort in sorts" :key="sort">
            <a class="cursor-pointer" @click="setSort(sort)">
              {{ i18n.t(`my_modules.results.sorts.${sort}`)}}
            </a>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script>
  const SORTS = [
    'updated_at_asc',
    'updated_at_desc',
    'created_at_asc',
    'created_at_desc',
    'name_asc',
    'name_desc'
  ];

  import FilterDropdown from '../shared/filters/filter_dropdown.vue';

  export default {
    name: 'ResultsToolbar',
    props: {
      sort: { type: String, required: true },
      canCreate: { type: Boolean, required: true }
    },
    data() {
      return {
        filters: null
      }
    },
    components: { FilterDropdown },
    created() {
      this.filters = [
        {
          key: 'query',
          type: 'Text',
          label: this.i18n.t('my_modules.results.filters.query.label'),
          placeholder: this.i18n.t('my_modules.results.filters.query.placeholder')
        },
        {
          key: 'created_at',
          type: 'DateRange',
          label: this.i18n.t('my_modules.results.filters.created_at.label')
        },
        {
          key: 'updated_at',
          type: 'DateRange',
          label: this.i18n.t('my_modules.results.filters.updated_at.label')
        }
      ];

      this.sorts = SORTS;
    },
    methods: {
      setSort(sort) {
        this.$emit('setSort', sort);
      },
      setFilters(filters) {
        this.$emit('setFilters', filters);
      }
    }
  }
</script>
