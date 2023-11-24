<template>
  <div class="flex flex-col gap-2">
    <div class="text-sm font-bold truncate" :title="colName">
      {{ colName }}
    </div>
    <DateTimeComponent
      mode="time"
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
    name: 'RepositoryTimeValue',
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
