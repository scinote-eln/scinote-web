<template>
  <div v-if="params.value">
    <GeneralDropdown>
      <template v-slot:field>
        {{ params.value.value.length }}
        {{ i18n.t('libraries.manange_modal_column.checklist_type.multiple_options') }}
      </template>
      <template v-slot:flyout>
        <div v-for="option in params.value.value" :key="option.value" class="px-2 py-1">
          {{ option.label }}
        </div>
      </template>
    </GeneralDropdown>
  </div>
</template>

<script>
import GeneralDropdown from '../../shared/general_dropdown.vue';
export default {
  name: 'ChecklistValue',
  props: {
    params: {
      required: true
    }
  },
  components: {
    GeneralDropdown
  }
};
</script>
