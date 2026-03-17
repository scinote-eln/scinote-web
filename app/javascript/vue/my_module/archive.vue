<template>
  <div class="mt-4">
    <div  class="result-toolbar sticky top-0 transition p-3 flex justify-between bg-sn-white">
      <div class="result-toolbar__left flex items-center">
        <div class="p-0.5 bg-sn-super-light-grey flex items-center gap-2 rounded cursor-pointer text-xs">
          <div
            class="h-9 flex items-center px-4"
            :class="{'bg-sn-white rounded-sm font-bold shadow': activeView === 'steps'}"
            @click="activeView = 'steps'"
          >
            {{ i18n.t('my_modules.archive.steps') }}
          </div>
          <div
            class="h-9 flex items-center px-4"
            :class="{'bg-sn-white rounded-sm font-bold shadow': activeView === 'results'}"
            @click="activeView = 'results'"
          >
            {{ i18n.t('my_modules.archive.results') }}
          </div>
        </div>
      </div>
      <div class="result-toolbar__right flex items-center [&_.sn-icon-filter]:!text-sn-blue">
        <template>
          <button :title="i18n.t('protocols.steps.collapse_label')" v-if="!objectsCollapsed" class="btn btn-secondary icon-btn xl:!px-4" @click="collapseObjects" tabindex="0">
            <i class="sn-icon sn-icon-collapse-all"></i>
            <span class="tw-hidden xl:inline">{{ i18n.t("protocols.steps.collapse_label") }}</span>
          </button>
          <button v-else  :title="i18n.t('protocols.steps.expand_label')" class="btn btn-secondary icon-btn xl:!px-4" @click="expandObjects" tabindex="0">
            <i class="sn-icon sn-icon-expand-all"></i>
            <span class="tw-hidden xl:inline">{{ i18n.t("protocols.steps.expand_label") }}</span>
          </button>
        </template>

        <FilterDropdown :filters="filters" @applyFilters="setFilters" />
        <MenuDropdown
            :listItems="this.sortMenu"
            :btnClasses="'btn btn-light icon-btn'"
            :position="'right'"
            :btnIcon="'sn-icon sn-icon-sort-down'"
            @sort="setSort"
          ></MenuDropdown>
      </div>
    </div>
  </div>
</template>

<script>
import FilterDropdown from '../shared/filters/filter_dropdown.vue';
import MenuDropdown from '../shared/menu_dropdown.vue';

const SORTS = [
  'updated_at_asc',
  'updated_at_desc',
  'created_at_asc',
  'created_at_desc',
  'name_asc',
  'name_desc'
];

export default {
  data() {
    return {
      filters: null,
      objectsCollapsed: false,
      activeView: 'steps'
    };
  },
  components: { FilterDropdown, MenuDropdown },
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
  computed: {
    sortMenu() {
      return this.sorts.map((sort) => ({
        text: this.i18n.t(`my_modules.results.sorts.${sort}`),
        emit: 'sort',
        params: sort,
        active: sort == this.sort
      }));
    }
  },
  methods: {
    setSort(sort) {
    },
    setFilters(filters) {
    },
    collapseResults() {
    },
    expandResults() {
    }
  }
}
</script>
