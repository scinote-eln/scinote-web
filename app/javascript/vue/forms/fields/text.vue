<template>
  <div>
    <div v-if="!fieldDisabled" class="sci-input-container-v2 h-24 mb-1" :class="{'error': !validValue}" :data-error="valueFieldError">
      <textarea
        class="sci-input"
        :value="value"
        ref="input"
        @blur="saveValue"
        :placeholder="fieldDisabled ? '' : i18n.t('forms.fields.add_text')"></textarea>
    </div>
    <div v-else
      ref="fieldValue"
      class="rounded min-h-[120px] border py-2  w-full px-4 bg-sn-super-light-grey border-sn-grey" >
      <span>
        {{ value }}
      </span>
    </div>
  </div>
</template>

<script>
/* global GLOBAL_CONSTANTS SmartAnnotation */

import fieldMixin from './field_mixin';

export default {
  name: 'TextField',
  mixins: [fieldMixin],
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
  mounted() {
    if (this.fieldDisabled) {
      window.renderElementSmartAnnotations(this.$refs.fieldValue, 'span');
    } else {
      SmartAnnotation.init($(this.$refs.input), false);
    }
  },
  methods: {
    saveValue(event) {
      this.value = event.target.value;
      const noActiveSA = [...document.querySelectorAll('.atwho-view')].every((el) => !el.style.display || el.style.display !== 'block');
      if (this.validValue && noActiveSA) {
        this.$emit('save', this.value);
      }
    }
  },
  computed: {
    validValue() {
      if (!this.value) {
        return true;
      }
      return this.value.length <= GLOBAL_CONSTANTS.TEXT_MAX_LENGTH;
    },
    valueFieldError() {
      if (this.value && this.value.length > GLOBAL_CONSTANTS.TEXT_MAX_LENGTH) {
        return this.i18n.t('forms.show.field_too_long_error', { limit: GLOBAL_CONSTANTS.TEXT_MAX_LENGTH });
      }
      return '';
    }
  }
};
</script>
