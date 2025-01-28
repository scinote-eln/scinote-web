<template>
  <div :key="marked_as_na">
    <SelectDropdown
      v-if="!fieldDisabled"
      :disabled="fieldDisabled"
      :options="options"
      :value="value"
      @change="saveValue"
      :multiple="true"
      :withCheckboxes="true"
      :clearable="true"
      :placeholder="fieldDisabled ? ' ' : null"
    />
    <span v-else-if="value && value.length > 0">
      {{ value.join(' | ') }}
    </span>
    <span v-else class="text-sn-dark-grey">
      {{ i18n.t('forms.fields.no_selection') }}
    </span>
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
  watch: {
    marked_as_na() {
      if (this.marked_as_na) {
        this.value = null;
      }
    }
  },
  data() {
    return {
      value: this.field.field_value?.selection || []
    };
  },
  computed: {
    options() {
      if (!this.field.attributes.data.options) {
        return [];
      }
      return this.field.attributes.data.options.map((option) => ([option, option]));
    }
  },
  methods: {
    saveValue(value) {
      this.value = value;
      this.$emit('save', (value.length === 0 ? null : value));
    }
  }
};
</script>
