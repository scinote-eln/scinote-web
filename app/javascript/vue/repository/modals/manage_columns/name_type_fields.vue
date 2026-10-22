<template>
  <div class="flex items-start gap-4">
    <div class="w-1/2">
      <InputField
        :label="i18n.t('libraries.manange_modal_column.name')"
        :placeholder="i18n.t('libraries.manange_modal_column.name_placeholder')"
        :modelValue="name"
        @update:modelValue="$emit('update:name', $event)"
        :error="!!nameError"
        :errorMessage="nameError"
        data-e2e="e2e-IF-invItems-manageColumns-columnName"
      />
    </div>
    <div class="w-1/2">
      <label class="sci-label flex items-center gap-1">
        {{ i18n.t('libraries.manange_modal_column.colum_type') }}
      </label>
      <div class="h-11 my-2" data-e2e="e2e-DD-invItems-manageColumns-columnType">
        <SelectDropdown
          :value="dataType"
          :options="options"
          :disabled="disabledType"
          @change="$emit('update:dataType', $event)"
        />
      </div>
    </div>
  </div>
</template>

<script>
import InputField from '../../../shared/input_field.vue';
import SelectDropdown from '../../../shared/select_dropdown.vue';

export default {
  name: 'ColumnNameTypeFields',
  components: {
    InputField,
    SelectDropdown
  },
  props: {
    name: { type: String, default: '' },
    nameError: { type: String, default: null },
    dataType: { type: String, required: true },
    disabledType: { type: Boolean, default: false },
    options: { type: Array, required: true }
  }
};
</script>
