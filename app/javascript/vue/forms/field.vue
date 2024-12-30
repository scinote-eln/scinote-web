<template>
<div class="p-4 rounded bg-white text-sm grid grid-cols-[auto_170px]">
  <div>
    <div class="font-bold">
      {{ field.attributes.name }}
      <span v-if="unit">({{ unit }})</span>
      <span v-if="field.attributes.required" class="text-sn-delete-red">*</span>
    </div>
    <div v-if="field.attributes.description">
      {{ field.attributes.description }}
    </div>
    <div class="mt-2">
      <component :is="field.attributes.data.type" ref="formField" :disabled="disabled" :field="field" :marked_as_na="markAsNa" @save="saveValue" />
    </div>
  </div>
  <div class="flex justify-end items-end">
    <button class="btn btn-secondary mb-0.5"
            :disabled="disabled"
            v-if="field.attributes.allow_not_applicable"
            :class="{'!bg-sn-super-light-blue !border-sn-blue': markAsNa}"
            @click="markAsNa = !markAsNa">
      <div class="w-4 h-4 !border-sn-blue border rounded-sm flex items-center justify-center" :class="{'bg-sn-blue': markAsNa}">
        <i class="sn-icon sn-icon-check text-white" style="font-size: 16px !important;"></i>
      </div>
      {{ i18n.t('forms.fields.mark_as_na') }}
    </button>
  </div>
</div>
</template>

<script>
import DatetimeField from './fields/datetime.vue';
import NumberField from './fields/number.vue';
import SingleChoiceField from './fields/single_choice.vue';
import TextField from './fields/text.vue';
import MultipleChoiceField from './fields/multiple_choice.vue';

export default {
  name: 'ViewField',
  props: {
    field: Object,
    disabled: Boolean,
    formResponse: {
      type: Object,
      default: null
    }
  },
  components: {
    DatetimeField,
    NumberField,
    SingleChoiceField,
    TextField,
    MultipleChoiceField
  },
  data() {
    return {
      markAsNa: this.field.field_value?.not_applicable || false
    };
  },
  watch: {
    markAsNa() {
      this.saveValue(null);
    }
  },
  computed: {
    unit() {
      return this.field.attributes.data.unit;
    }
  },
  methods: {
    saveValue(value) {
      if (this.formResponse) {
        this.$emit(
          'save',
          this.field.id,
          value,
          this.markAsNa
        );
      }
    }
  }
};
</script>
