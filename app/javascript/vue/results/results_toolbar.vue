<template>
  <div ref="resultsHeaderToolbar" class="result-toolbar sticky top-0 transition p-3 flex justify-between bg-sn-white">
    <div v-if="headerSticked" class="flex items-center truncate grow">
      <i class="sn-icon sn-icon-navigator sci--layout--navigator-open cursor-pointer p-1.5 border rounded border-sn-light-grey mr-4"></i>
      <div @click="scrollTop" class="w-[calc(100%_-_4rem)] cursor-pointer">
        <h2 class="truncate leading-6 mt-2.5 mb-2.5">{{ moduleName }}</h2>
      </div>
    </div>

    <div class="result-toolbar__left flex items-center">
      <button v-if="canCreate" :title="i18n.t('my_modules.results.add_title')" class="btn btn-secondary" :class="{'mr-3': headerSticked}" @click="$emit('newResult')">
        <i class="sn-icon sn-icon-new-task"></i>
        {{ i18n.t('my_modules.results.add_label') }}
      </button>
    </div>

    <div class="dropdown view-switch flex items-center">
      <div class="btn btn-secondary view-switch-button prevent-shrink" :class="{'mr-3': headerSticked}" id="viewSwitchButton" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true">
        <span v-if="archived" class="state-view-switch-btn-name">{{ i18n.t('my_modules.results.archived_results') }}</span>
        <span v-else class="state-view-switch-btn-name">{{ i18n.t('my_modules.results.active_results') }}</span>
        <span class="sn-icon sn-icon-down"></span>
      </div>
      <ul class="dropdown-menu dropdown-menu-right" aria-labelledby="viewSwitchButton">
        <li class="view-switch-active h-34">
          <a class="h-34 dropdown-switch-link" :href="active_url" :class="{'form-dropdown-state-item prevent-shrink': !archived}">
            {{ i18n.t('my_modules.results.active_results') }}
          </a>
        </li>
        <li class="view-switch-archived h-34">
          <a class="h-34 dropdown-switch-link" :href="archived_url" :class="{'form-dropdown-state-item prevent-shrink': archived}">
            {{ i18n.t('my_modules.results.archived_results') }}
          </a>
        </li>
      </ul>
    </div>
    <div class="result-toolbar__right flex items-center [&_.sn-icon-filter]:!text-sn-blue">
      <button class="btn btn-secondary mr-3" @click="collapseResults" tabindex="0">
        {{ i18n.t('my_modules.results.collapse_label') }}
      </button>
      <button class="btn btn-secondary mr-3" @click="expandResults" tabindex="0">
        {{ i18n.t('my_modules.results.expand_label') }}
      </button>

      <FilterDropdown :filters="filters" @applyFilters="setFilters" />
      <MenuDropdown
          :listItems="this.sortMenu"
          :btnClasses="'btn btn-light icon-btn'"
          :position="'right'"
          :btnIcon="'sn-icon sn-icon-sort'"
          @sort="setSort"
        ></MenuDropdown>
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
  name: 'ResultsToolbar',
  props: {
    sort: { type: String, required: true },
    canCreate: { type: Boolean, required: true },
    archived: { type: Boolean, required: true },
    headerSticked: { type: Boolean, required: true },
    active_url: { type: String, required: true },
    archived_url: { type: String, required: true },
    moduleName: { type: String, required: true }
  },
  data() {
    return {
      filters: null
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
      this.$emit('setSort', sort);
    },
    setFilters(filters) {
      this.$emit('setFilters', filters);
    },
    collapseResults() {
      $('.result-wrapper .collapse').collapse('hide');
    },
    expandResults() {
      $('.result-wrapper .collapse').collapse('show');
    },
    scrollTop() {
      window.scrollTo(0, 0);
      setTimeout(() => {
        $('.my_module-name .view-mode').trigger('click');
        $('.my_module-name .input-field').focus();
      }, 300);
    }
  }
};
</script>
