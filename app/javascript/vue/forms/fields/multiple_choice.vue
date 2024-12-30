<template>
  <div>
    <SelectDropdown
      :disabled="fieldDisabled"
      :options="options"
      :value="value"
      @change="saveValue"
      :multiple="true"
      :withCheckboxes="true"
      :clearable="true"
    />
  </div>
</template>

<script>
import fieldMixin from './field_mixin';
import SelectDropdown from '../../shared/select_dropdown.vue';

export default {
  name: 'MultipleChoiceField',
  mixins: [fieldMixin],
  components: {
    SelectDropdown
  },
  computed: {
    value() {
      return (this.field.field_value?.selection || '[]');
    },
    options() {
      if (!this.field.attributes.data.options) {
        return [];
      }
      return this.field.attributes.data.options.map((option) => ([option, option]));
    }
  },
  methods: {
    saveValue(value) {
      this.$emit('save', value);
    }
  }
};
</script>
