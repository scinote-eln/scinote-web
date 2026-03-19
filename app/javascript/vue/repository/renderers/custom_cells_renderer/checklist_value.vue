<template>
  <div v-if="params.value">
    <template v-if="params.value.value.length == 1">
      <span>{{ params.value.value[0].label }}</span>
    </template>
    <GeneralDropdown v-else>
      <template v-slot:field>
        <span class="text-sn-blue hover:underline cursor-pointer">
          {{ params.value.value.length }}
          {{ i18n.t('libraries.manange_modal_column.checklist_type.multiple_options') }}
        </span>
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
import GeneralDropdown from '../../../shared/general_dropdown.vue';
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
