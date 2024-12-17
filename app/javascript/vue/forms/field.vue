<template>
<div class="p-4 rounded bg-white text-sm grid grid-cols-[auto_170px]">
  <div>
    <div class="font-bold">
      {{ field.attributes.name }}
      <span v-if="field.attributes.required" class="text-sn-delete-red">*</span>
    </div>
    <div v-if="field.attributes.description">
      {{ field.attributes.description }}
    </div>
    <div class="mt-2">
      <component :is="field.attributes.data.type" :field="field" :marked_as_na="mark_as_na" />
    </div>
  </div>
  <div class="flex justify-end items-end">
    <button class="btn btn-secondary mb-0.5"
            v-if="field.attributes.allow_not_applicable"
            :class="{'!bg-sn-super-light-blue !border-sn-blue': mark_as_na}"
            @click="mark_as_na = !mark_as_na">
      <div class="w-4 h-4 !border-sn-blue border rounded-sm flex items-center justify-center" :class="{'bg-sn-blue': mark_as_na}">
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
    field: Object
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
      mark_as_na: false
    };
  }
};
</script>
