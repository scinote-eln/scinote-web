<template>
  <div class="flex flex-col gap-2">
    <DateTimeComponent
      mode="datetime"
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
    name: 'RepositoryDateTimeValue',
    components: { DateTimeComponent },
    props: {
      data_type: String,
      colId: Number,
      colName: String,
      colVal: Object,
      updatePath: String,
      canEdit: { type: Boolean, default: false }
    }
  }
</script>
