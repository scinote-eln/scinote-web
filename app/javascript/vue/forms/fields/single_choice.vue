<template>
  <div :key="marked_as_na">
    <SelectDropdown
      :disabled="fieldDisabled"
      :options="options"
      :value="value"
      @change="saveValue"
      :clearable="true"
      :placeholder="fieldDisabled ? ' ' : null"
    />
  </div>
</template>

<script>
import fieldMixin from './field_mixin';
import SelectDropdown from '../../shared/select_dropdown.vue';

export default {
  name: 'SingleChoiceField',
  mixins: [fieldMixin],
  components: {
    SelectDropdown
  },
  computed: {
    options() {
      if (!this.field.attributes.data.options) {
        return [];
      }
      return this.field.attributes.data.options.map((option) => ([option, option]));
    }
  },
  data() {
    return {
      value: this.field.field_value?.value
    };
  },
  watch: {
    marked_as_na() {
      if (this.marked_as_na) {
        this.value = null;
      }
    }
  },
  methods: {
    saveValue(value) {
      this.$emit('save', value);
    }
  }
};
</script>
