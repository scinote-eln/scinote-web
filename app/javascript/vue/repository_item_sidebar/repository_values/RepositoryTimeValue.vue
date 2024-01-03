<template>
  <div class="flex flex-col gap-2">
    <DateTimeComponent
      mode="time"
      :colVal="colVal"
      :colId="colId"
      :colName="colName"
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
