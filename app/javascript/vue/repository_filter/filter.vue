<template>
  <div class="filter-container" >
    <div class='filter-title'>{{ filter.column.name }}</div>
    <div class="filter-element">
      <div class="filter-body">
        <component
          :is="filter.column.data_type"
          :filter="filter"
          :my_modules='my_modules'
          @filter:update="updateFilter" />
      </div>
      <div class="filter-remove" :data-e2e="'e2e-BT-invInventoryFilterCO-remove'+filter.column.id">
        <button class="btn btn-light icon-btn" @click="$emit('filter:delete')">
          <i class="sn-icon sn-icon-delete"></i>
        </button>
      </div>
    </div>
</div>
</template>

<script>
// filter types
import RepositoryNonEmptyTextValue from './filters/repositoryNonEmptyTextValue.vue';
import RepositoryRelationshipValue from './filters/repositoryRelationshipValue.vue';
import RepositoryAssetValue from './filters/repositoryAssetValue.vue';
import RepositoryTextValue from './filters/repositoryTextValue.vue';
import RepositoryNumberValue from './filters/repositoryNumberValue.vue';
import RepositoryMyModuleValue from './filters/repositoryMyModuleValue.vue';
import RepositoryDateValue from './filters/repositoryDateValue.vue';
import RepositoryDateRangeValue from './filters/repositoryDateRangeValue.vue';
import RepositoryDateTimeValue from './filters/repositoryDateTimeValue.vue';
import RepositoryDateTimeRangeValue from './filters/repositoryDateTimeRangeValue.vue';
import RepositoryTimeValue from './filters/repositoryTimeValue.vue';
import RepositoryTimeRangeValue from './filters/repositoryTimeRangeValue.vue';
import RepositoryListValue from './filters/repositoryListValue.vue';
import RepositoryStatusValue from './filters/repositoryStatusValue.vue';
import RepositoryChecklistValue from './filters/repositoryChecklistValue.vue';
import RepositoryUserValue from './filters/repositoryUserValue.vue';
import RepositoryStockValue from './filters/repositoryStockValue.vue';
import DropdownSelector from '../shared/legacy/dropdown_selector.vue';

export default {
  name: 'FilterElement',
  props: {
    filter: Object,
    my_modules: Array
  },
  components: {
    DropdownSelector,
    RepositoryNonEmptyTextValue,
    RepositoryRelationshipValue,
    RepositoryAssetValue,
    RepositoryTextValue,
    RepositoryNumberValue,
    RepositoryMyModuleValue,
    RepositoryDateValue,
    RepositoryDateRangeValue,
    RepositoryTimeValue,
    RepositoryTimeRangeValue,
    RepositoryDateTimeValue,
    RepositoryDateTimeRangeValue,
    RepositoryListValue,
    RepositoryStatusValue,
    RepositoryChecklistValue,
    RepositoryUserValue,
    RepositoryStockValue
  },
  methods: {
    updateFilter(value) {
      this.$emit('filter:update', value);
    }
  }
};
</script>
