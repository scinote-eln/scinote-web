<template>
  <div class="sci-input-container-v2 h-24">
    <textarea
      class="sci-input"
      :value="value"
      :disabled="fieldDisabled"
      @change="saveValue"
      :placeholder="fieldDisabled ? '' : i18n.t('forms.fields.add_text')"></textarea>
  </div>
</template>

<script>
import fieldMixin from './field_mixin';

export default {
  name: 'TextField',
  mixins: [fieldMixin],
  methods: {
    saveValue(event) {
      this.$emit('save', event.target.value);
    }
  },
  computed: {
    value() {
      return this.field.field_value?.value;
    }
  }
};
</script>
