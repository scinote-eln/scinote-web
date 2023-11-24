<template>
  <div class="flex flex-col gap2">
    <div class="font-inter text-sm font-semibold leading-5 truncate" :title="colName">
      {{ colName }}
    </div>
    <DateTimeComponent
      mode="date"
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
  name: 'RepositoryDateValue',
  components: { DateTimeComponent },
  props: {
    data_type: String,
    colId: Number,
    colName: String,
    colVal: null,
    updatePath: null,
    editingField: null,
    canEdit: { type: Boolean, default: false }
  }
}
</script>
