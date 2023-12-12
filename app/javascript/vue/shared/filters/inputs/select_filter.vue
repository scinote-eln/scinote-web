<template>
  <div class="mb-6">
    <label class="sci-label">{{ filter.label }}</label>
    <SelectDropdown
      :optionsUrl="filter.optionsUrl"
      :options="filter.options"
      :selectedValue="value"
      :multiple="true"
      :with-checkboxes="true"
      :placeholder="filter.placeholder"
      :optionRenderer="filter.optionRenderer"
      :labelRenderer="filter.labelRenderer"
      @change="change"
    > </SelectDropdown>
  </div>
</template>

<script>
  import SelectDropdown from '../../select_dropdown.vue';

  export default {
    name: 'SelectFilter',
    props: {
      filter: { type: Object, required: true }
    },
    data: function() {
      return {
        value: []
      }
    },
    watch: {
      value: function() {
        let value = this.value;
        if (this.value.length == 0) {
          value = null;
        }
        this.$emit('update', { key: this.filter.key, value: value });
      }
    },
    components: { SelectDropdown },
    methods: {
      change: function(value) {
        this.value = value;
      }
    },
  }
</script>
