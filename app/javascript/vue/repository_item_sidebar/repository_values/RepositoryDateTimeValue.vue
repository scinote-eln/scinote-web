<template>
  <div id="repository-date-time-value-wrapper" class="flex flex-col min-min-h-[46px] h-auto gap-[6px]">
    <div class="font-inter text-sm font-semibold leading-5 truncate" :title="colName">
      {{ colName }}
    </div>
    <DateTimeRange :editingField="editingField" @setEditingField="$emit('setEditingField', $event)" dateType="dateTime" :colVal="colVal" :colId="colId" :updatePath="updatePath" />
  </div>
</template>

<script>
  import DateTimeRange from './DateTimeRange.vue';

  export default {
    name: 'RepositoryDateTimeValue',
    components: { DateTimeRange },
    props: {
      data_type: String,
      colId: Number,
      colName: String,
      colVal: Object,
      updatePath: String,
      editingField: null
    }
  }
</script>
