<template>
  <div v-if="customColumns?.length > 0" class="flex flex-col gap-4 w-[350px] h-auto">
    <div v-for="(column, index) in customColumns" class="flex flex-col gap-4 w-[350px] h-auto relative">
      <component
        :is="column.data_type"
        :key="index"
        :data_type="column.data_type"
        :colId="column.id"
        :colName="column.name"
        :colVal="column.value"
        :repositoryRowId="repositoryRowId"
        :repositoryId="repositoryId"
        :permissions="permissions"
        :updatePath="updatePath"
        :editingField="editingField"
        @setEditingField="editingField = $event"
      />
      <div class="sci-divider" :class="{ 'hidden': index === customColumns?.length - 1 }"></div>
    </div>
  </div>
</template>

<script>
  import RepositoryStockValue from './repository_values/RepositoryStockValue.vue';
  import RepositoryTextValue from './repository_values/RepositoryTextValue.vue';
  import RepositoryNumberValue from './repository_values/RepositoryNumberValue.vue';
  import RepositoryAssetValue from './repository_values/RepositoryAssetValue.vue';
  import RepositoryListValue from './repository_values/RepositoryListValue.vue';
  import RepositoryChecklistValue from './repository_values/RepositoryChecklistValue.vue';
  import RepositoryStatusValue from './repository_values/RepositoryStatusValue.vue';
  import RepositoryDateTimeValue from './repository_values/RepositoryDateTimeValue.vue';
  import RepositoryDateTimeRangeValue from './repository_values/RepositoryDateTimeRangeValue.vue';
  import RepositoryDateValue from './repository_values/RepositoryDateValue.vue';
  import RepositoryDateRangeValue from './repository_values/RepositoryDateRangeValue.vue';
  import RepositoryTimeRangeValue from './repository_values/RepositoryTimeRangeValue.vue'
  import RepositoryTimeValue from './repository_values/RepositoryTimeValue.vue'

  export default {
    components: {
      RepositoryStockValue,
      RepositoryTextValue,
      RepositoryNumberValue,
      RepositoryAssetValue,
      RepositoryListValue,
      RepositoryChecklistValue,
      RepositoryStatusValue,
      RepositoryDateTimeValue,
      RepositoryDateTimeRangeValue,
      RepositoryDateValue,
      RepositoryDateRangeValue,
      RepositoryTimeRangeValue,
      RepositoryTimeValue
    },
    name: 'CustomColumns',
    props: {
      customColumns: [],
      permissions: null,
      updatePath: null,
      repositoryRowId: null,
      repositoryId: null
    },
    data() {
      return {
        editingField: null
      }
    }
  }
</script>
