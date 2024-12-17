<template>
  <div>
    <SelectDropdown
      :disabled="marked_as_na"
      :options="options"
      :clearable="true"
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
  }
};
</script>
