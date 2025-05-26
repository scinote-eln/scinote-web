<template>
  <div v-if="this.params.data[this.params.field]" class="flex relative items-center gap-2">
    <DateTimePicker
      v-if="this.params.data[this.params.field].editable"
      class="borderless-input -mt-[1px]"
      :defaultValue="date"
      @change="updateDate"
      :mode="this.params.mode || 'datetime'"
      :placeholder="this.params.placeholder"
      :customIcon="this.params.data[this.params.field].icon"
      :clearable="true"/>
    <template v-else-if="this.params.data[this.params.field].value_formatted">
      <i :class="this.params.data[this.params.field].icon || 'sn-icon sn-icon-calendar'"></i>
      {{ this.params.data[this.params.field].value_formatted }}
    </template>
    <template v-else>
      {{ this.params.emptyPlaceholder }}
    </template>
  </div>
</template>

<script>

import DateTimePicker from '../../date_time_picker.vue';

export default {
  name: 'dateRenderer',
  components: {
    DateTimePicker
  },
  props: {
    params: {
      required: true
    }
  },
  data() {
    return {
      date: null
    };
  },
  created() {
    this.date = new Date(this.params.data[this.params.field]?.value?.replace(/([^!\s])-/g, '$1/'));
  },
  methods: {
    updateDate(value) {
      this.params.dtComponent.$emit(this.params.emitAction, value, this.params);
      this.date = value;
    }
  }
};
</script>
