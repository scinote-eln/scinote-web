<template>
  <div>
    <div v-if="!fieldDisabled && editing" class="sci-input-container-v2 h-24 mb-1" :class="{'error': !validValue}" :data-error="valueFieldError">
      <textarea
        class="sci-input"
        :value="value"
        ref="input"
        @blur="saveValue"
        :placeholder="fieldDisabled ? '' : i18n.t('forms.fields.add_text')"></textarea>
    </div>
    <div v-else
      @click="startEditing"
      ref="fieldValue"
      class="rounded h-24 border py-0.5  w-full px-2  border-sn-grey overflow-y-auto"
      :class="{
        'cursor-pointer': !fieldDisabled,
        'bg-sn-super-light-grey': fieldDisabled
      }"
    >
      <span>
        {{ value }}
        <span v-if="(!value || value.length == 0) && !fieldDisabled" class="text-sn-grey">
          {{ i18n.t('forms.fields.add_text') }}
        </span>
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
      value: this.field.field_value?.value,
      editing: false
    };
  },
  watch: {
    marked_as_na() {
      if (this.marked_as_na) {
        this.value = null;
      }
    },
    editing() {
      if (!this.editing) {
        this.$nextTick(() => {
          window.renderElementSmartAnnotations(this.$refs.fieldValue, 'span');
        });
      }
    }
  },
  mounted() {
    window.renderElementSmartAnnotations(this.$refs.fieldValue, 'span');
  },
  methods: {
    saveValue(event) {
      this.value = event.target.value;
      const noActiveSA = [...document.querySelectorAll('.atwho-view')].every((el) => !el.style.display || el.style.display !== 'block');
      if (this.validValue && noActiveSA) {
        this.$emit('save', this.value);
        this.editing = false;
      }
    },
    startEditing() {
      if (!this.fieldDisabled) {
        this.editing = true;
        this.$nextTick(() => {
          SmartAnnotation.init($(this.$refs.input), false);
          this.$refs.input.focus();
        });
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
