<template>
  <div id="repository-date-range-value-wrapper" class="flex flex-col min-min-h-[46px] h-auto gap-[6px]">
    <div class="font-inter text-sm font-semibold leading-5 truncate" :title="colName">
      {{ colName }}
    </div>
    <DateTimeRange
      dateType="dateRange"
      :startTime="colVal?.start_time"
      :endTime="colVal?.end_time"
      :colVal="colVal"
      :colId="colId"
      :updatePath="updatePath"
      :editingField="editingField"
      @setEditingField="$emit('setEditingField', $event)"
    />
  </div>
</template>

<script>
import DateTimeRange from './DateTimeRange.vue';

  export default {
    name: 'RepositoryDateRangeValue',
    components: { DateTimeRange },
    props: {
      data_type: String,
      colId: Number,
      colName: String,
      colVal: null,
      updatePath: null,
      editingField: null
    }
  }
</script>
