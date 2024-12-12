<template>
  <div class="flex flex-col gap-4">
  <hr class="my-4 w-full">
  <div class="flex items-center gap-2.5">
    <span class="sci-checkbox-container">
      <input type="checkbox"
              class="sci-checkbox"
              @change="$emit('updateField')"
              v-model="editField.attributes.data.time" />
      <span class="sci-checkbox-label"></span>
    </span>
    {{ i18n.t('forms.show.time_label') }}
  </div>
  <div class="flex items-center gap-2.5">
    <span class="sci-checkbox-container">
      <input type="checkbox"
              class="sci-checkbox"
              @change="$emit('updateField')"
              v-model="editField.attributes.data.range" />
      <span class="sci-checkbox-label"></span>
    </span>
    {{ i18n.t('forms.show.range_label') }}
  </div>
  <hr class="my-4 w-full">
  </div>
</template>

<script>
import fieldMixin from './field_mixin';

export default {
  name: 'DateTimeField',
  mixins: [fieldMixin]
};
</script>
