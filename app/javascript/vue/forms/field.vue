<template>
<div class="p-4 rounded bg-white text-sm mb-2">
  <div class="grow">
    <div class="font-bold">
      {{ field.attributes.name }}
      <span v-if="unit">({{ unit }})</span>
      <span v-if="field.attributes.required" class="text-sn-delete-red">*</span>
    </div>
    <div ref="description" v-if="field.attributes.description">
      <span>{{ field.attributes.description }}</span>
    </div>
    <div class="mt-2">
      <component :is="field.attributes.data.type" ref="formField" :disabled="disabled"
                 :field="field" :marked_as_na="markAsNa" @save="saveValue" @validChanged="checkValidField" />
    </div>
  </div>
  <div class="flex items-center justify-end mt-4 gap-4">
    <span class="text-sn-grey-700 text-xs" v-if="field.field_value && field.field_value.submitted_at">
      {{  i18n.t('forms.fields.submitted_by', { date: field.field_value.submitted_at, user: field.field_value.submitted_by_full_name}) }}
    </span>
    <button class="btn btn-secondary mb-0.5"
            :title="i18n.t('forms.fields.mark_as_na_tooltip')"
            data-toggle="tooltip"
            data-placement="top"
            :disabled="disabled"
            v-if="field.attributes.allow_not_applicable"
            :class="{
              '!bg-sn-super-light-blue !border-sn-blue': markAsNa && !disabled
            }"
            @click="markAsNa = !markAsNa">
      <div class="w-4 h-4  border rounded-sm flex items-center justify-center"
        :class="{
          'bg-sn-blue': markAsNa && !disabled,
          'bg-sn-grey-500': markAsNa && disabled,
          '!border-sn-blue': !disabled,
          'border-sn-grey-500': disabled
        }">
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
import ActionField from './fields/action.vue';
import RepositoryRowsField from './fields/repository_rows.vue';

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
    MultipleChoiceField,
    ActionField,
    RepositoryRowsField
  },
  data() {
    return {
      markAsNa: this.field.field_value?.not_applicable || false,
      isValid: false
    };
  },
  watch: {
    markAsNa() {
      this.saveValue(null);
    },
    isValid() {
      this.$emit('validChanged');
    }
  },
  mounted() {
    this.checkValidField();
    if (this.$refs.description) {
      this.$nextTick(() => {
        window.renderElementSmartAnnotations(this.$refs.description, 'span');
      });
    }
    $('[data-toggle="tooltip"]').tooltip();
  },
  computed: {
    unit() {
      return this.field.attributes.data.unit;
    }
  },
  methods: {
    checkValidField() {
      this.isValid = this.$refs.formField?.validValue;
    },
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
