<template>
  <div id="repository-date-time-range-value-wrapper" class="flex flex-col min-min-h-[46px] h-auto gap-[6px]">
    <div class="font-inter text-sm font-semibold leading-5 truncate" :title="colName">
      {{ colName }}
    </div>
    <DateTimeRange
      :editingField="editingField"
      @setEditingField="$emit('setEditingField', $event)"
      dateType="dateTimeRange"
      :startTime="colVal?.start_time"
      :endTime="colVal?.end_time"
      :colVal="colVal"
      :colId="colId"
      :updatePath="updatePath"
      :canEdit="canEdit"
    />
  </div>
</template>

<script>
  import DateTimeRange from './DateTimeRange.vue';

  export default {
    name: 'RepositoryDateTimeRangeValue',
    components: { DateTimeRange },
    props: {
      data_type: String,
      colId: Number,
      colName: String,
      colVal: Object,
      updatePath: null,
      editingField: null,
      canEdit: { type: Boolean, default: false }
    }
  }
</script>
