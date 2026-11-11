<template>
  <div v-if="show"
    class="absolute top-full left-0 w-full truncate text-xs text-sn-delete-red"
    data-e2e="e2e-TX-itemCard-mandatoryError">
    {{ i18n.t('repositories.mandatory_column.field_error') }}
  </div>
</template>

<script>
export default {
  name: 'MandatoryError',
  props: {
    show: { type: Boolean, default: false }
  }
};
</script>
