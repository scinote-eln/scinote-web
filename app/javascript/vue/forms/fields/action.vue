<template>
  <div :key="marked_as_na">
    <button class="btn btn-secondary mb-0.5"
            :disabled="fieldDisabled"
            :class="{
              '!bg-sn-super-light-blue !border-sn-blue': value && !fieldDisabled
            }"
            @click="saveValue">
      <div class="w-4 h-4  border rounded-sm flex items-center justify-center"
        :class="{
          'bg-sn-blue': value && !fieldDisabled,
          'bg-sn-grey-500': value && fieldDisabled,
          '!border-sn-blue': !fieldDisabled,
          'border-sn-grey-500': fieldDisabled
        }">
        <i class="sn-icon sn-icon-check text-white" style="font-size: 16px !important;"></i>
      </div>
      {{ i18n.t('forms.fields.mark_as_completed') }}
    </button>
  </div>
</template>

<script>
import fieldMixin from './field_mixin';

export default {
  name: 'ActionField',
  mixins: [fieldMixin],
  watch: {
    marked_as_na() {
      if (this.marked_as_na) {
        this.value = null;
      }
    }
  },
  data() {
    return {
      value: this.field.field_value?.value || false
    };
  },
  methods: {
    saveValue() {
      this.value = !this.value;
      this.$emit('save', this.value);
    }
  }
};
</script>
