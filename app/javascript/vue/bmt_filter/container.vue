<template>
  <div class="filters-container">
    <div class="header">
      <div id="savedFiltersContainer" class="dropdown saved-filters-container" @click="toggleSavedFilters">
        <div class="title" id="savedFilterDropdown">
          {{ i18n.t('repositories.show.bmt_search.title') }}
          <i v-if="savedFilters.length" class="sn-icon sn-icon-down"></i>
        </div>
        <div v-if="savedFilters.length" class="dropdown-menu saved-filters-list">
          <SavedFilterElement
            v-for="(savedFilter, index) in savedFilters"
            :key="savedFilter.id"
            :savedFilter.sync="savedFilters[index]"
            :canManageFilters="canManageFilters"
            @savedFilter:load="loadFilters"
            @savedFilter:delete="savedFilters.splice(index, 1)"
          />
        </div>
      </div>
      <button class="btn btn-light clear-filters-btn" @click="closeSavedFilters() && clearFilters()">
        <i class="sn-icon sn-icon-close"></i>
        {{ i18n.t('repositories.show.bmt_search.clear_all') }}
      </button>
    </div>
    <div class="filters-list" @click="closeSavedFilters">
      <div v-if="filters.length == 0" class="filter-list-notice">
        {{ i18n.t('repositories.show.bmt_search.no_filters') }}
      </div>
      <FilterElement
        v-for="(filter, index) in filters"
        :key="filter.id"
        :filter.sync="filters[index]"
        :additionalDataAttributes="additionalDataAttributes"
        :filterId="filter.id"
        @filter:delete="filters.splice(index, 1)"
        @filter:update="updateFilter"
      />
    </div>
    <div class="footer" @click="closeSavedFilters">
      <button class="btn btn-light add-filter" @click="addFilter">
        <i class="sn-icon sn-icon-new-task"></i>
        {{ i18n.t('repositories.show.bmt_search.add_filter') }}
      </button>
      <button @click="fetchCIDs" class="btn btn-primary">
        {{ i18n.t('repositories.show.bmt_search.apply') }}
      </button>
    </div>
  </div>
</template>

 <script>
  import FilterElement from './filter.vue'
  import SavedFilterElement from './saved_filter.vue'

  export default {
    name: 'FilterContainer',
    data() {
      return {
        filters: [],
        additionalDataAttributes: []
      }
    },
    props: {
      container: Object,
      savedFilters: Array,
      bmtApiBaseUrl: String,
      canManageFilters: Boolean
    },
    created() {
      this.fetchAdditionalDataAttributes();
    },
    components: { FilterElement, SavedFilterElement },
    computed: {
      searchJSON() {
        let mergedFilters = this.filters.map(f => f.data).filter(f => f.type !== 'additionalDataFilter');
        let additionalDataFilters = this.filters.map(f => f.data).filter(f => f.type === 'additionalDataFilter');

        mergedFilters.push(
          {
            'type': 'additionalDataFilter',
            'dataList': additionalDataFilters.map(f => {
              return { 'attribute': f.attribute, 'value': f.value }
            })
          }
        );

        return {
          'filters': mergedFilters,
          'resultAttributeNames': ['Cid']
        }
      }
    },
    watch: {
      filters() {
        $('.open-save-bmt-modal').toggleClass('hidden', !this.filters.length)
        $('.bmt-filters-button').toggleClass('active-filters', !!this.filters.length)
      }
    },
    methods: {
      addFilter() {
        const id = this.filters.length ? this.filters[this.filters.length - 1].id + 1 : 1
        this.filters.push({ id: id, data: { type: "fullsequenceFilter" } });
      },
      updateFilter(filter) {
        this.filters.find((f) => f.id === filter.id).data = filter.data;
        this.$emit('filters:update', this.searchJSON.filters);
      },
      clearFilters() {
        this.filters = [];
        this.$emit('filters:clear');
      },
      fetchCIDs() {
        $.ajax({
          type: 'POST',
          url: this.bmtApiBaseUrl + '/macromolecule/search',
          data: JSON.stringify(this.searchJSON),
          contentType: 'application/json; charset=utf-8',
          dataType: 'json',
          success: (data) => {
            this.$emit('cids:update', data.map(i => i.Cid))
          },
          error: ()=> {
            this.$emit('cids:update', [])
            this.$emit('cids:error', this.i18n.t('repositories.show.error_searching'));
          }
        });
      },
      closeSavedFilters() {
        $('.saved-filters-container').removeClass('open');
        return true;
      },
      toggleSavedFilters() {
        $('.saved-filters-container').toggleClass('open');
      },
      fetchAdditionalDataAttributes() {
        $.get(this.bmtApiBaseUrl + '/admin/macromolecules/attributes', (data) => {
          // Cid filter works as a special filter, not as additional data
          this.additionalDataAttributes = data.filter((a) => a.name != 'Cid')
        });
      },
      loadFilters(filters) {
        this.clearFilters();

        let id = 1;

        filters.forEach(filter => {
          // extract additional filters
          if(filter.type === 'additionalDataFilter') {
            filter.dataList.forEach(additionalDataFilter => {
              this.filters.push(
                {
                  'id': id++,
                  'data': {
                    'type': 'additionalDataFilter',
                    'attribute': additionalDataFilter.attribute,
                    'value': additionalDataFilter.value
                  }
                }
              )
            });
          } else {
            this.filters.push(
              {
                'id': id++,
                'data': filter
              }
            );
          }
        });
      }
    }
  }
 </script>
