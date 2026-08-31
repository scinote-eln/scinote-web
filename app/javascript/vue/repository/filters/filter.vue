<template>
  <div class="filter-container" >
    <div class='filter-title'>{{ filter.column.name }}</div>
    <div class="filter-element">
      <div class="filter-body">
        <component
          :is="filter.column.data_type"
          :filter="filter"
          :repositoryId="repositoryId"
          :my_modules='my_modules'
          @filter:update="updateFilter" />
      </div>
      <div class="filter-remove" :data-e2e="'e2e-BT-invInventoryFilterCO-remove'+filter.column.id">
        <button v-if="filtersCount > 1" class="btn btn-light icon-btn" @click="$emit('filter:delete')">
          <i class="sn-icon sn-icon-delete"></i>
        </button>
      </div>
    </div>
</div>
</template>

<script>
// filter types
import RepositoryNonEmptyTextValue from './repositoryNonEmptyTextValue.vue';
import RepositoryRelationshipValue from './repositoryRelationshipValue.vue';
import RepositoryAssetValue from './repositoryAssetValue.vue';
import RepositoryTextValue from './repositoryTextValue.vue';
import RepositoryNumberValue from './repositoryNumberValue.vue';
import RepositoryMyModuleValue from './repositoryMyModuleValue.vue';
import RepositoryDateValue from './repositoryDateValue.vue';
import RepositoryDateRangeValue from './repositoryDateRangeValue.vue';
import RepositoryDateTimeValue from './repositoryDateTimeValue.vue';
import RepositoryDateTimeRangeValue from './repositoryDateTimeRangeValue.vue';
import RepositoryTimeValue from './repositoryTimeValue.vue';
import RepositoryTimeRangeValue from './repositoryTimeRangeValue.vue';
import RepositoryListValue from './repositoryListValue.vue';
import RepositoryStatusValue from './repositoryStatusValue.vue';
import RepositoryChecklistValue from './repositoryChecklistValue.vue';
import RepositoryUserValue from './repositoryUserValue.vue';
import RepositoryStockValue from './repositoryStockValue.vue';

export default {
  name: 'FilterElement',
  props: {
    repositoryId: Number,
    filter: Object,
    my_modules: Array,
    filtersCount: Number
  },
  components: {
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
