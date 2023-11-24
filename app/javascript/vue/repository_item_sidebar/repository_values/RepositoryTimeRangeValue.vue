<template>
  <div class="flex flex-col gap-2">
    <div class="text-sm font-bold truncate" :title="colName">
      {{ colName }}
    </div>
    <DateTimeComponent
      mode="time"
      :range="true"
      :colVal="colVal"
      :colId="colId"
      :updatePath="updatePath"
      :canEdit="canEdit"
    />
  </div>
</template>

<script>
  import DateTimeComponent from './date_time_component.vue';
  export default {
    name: 'RepositoryTimeRangeValue',
    components: { DateTimeComponent },
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
