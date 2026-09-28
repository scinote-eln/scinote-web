<template>
  <div class="flex flex-col gap-4">
  <hr class="my-4 w-full">
  <div class="flex items-center gap-2.5">
    <span class="sci-checkbox-container">
      <input type="checkbox"
              class="sci-checkbox"
              @change="$emit('updateField')"
              v-model="editField.attributes.data.time"
              data-e2e="e2e-CB-forms-builder-editField-dateTime-includeTime"
        />
      <span class="sci-checkbox-label"></span>
    </span>
    {{ i18n.t('forms.show.time_label') }}
  </div>
  <div class="flex items-center gap-2.5">
    <span class="sci-checkbox-container">
      <input type="checkbox"
              class="sci-checkbox"
              @change="$emit('updateField')"
              v-model="editField.attributes.data.range"
              data-e2e="e2e-CB-forms-builder-editField-dateTime-includeRange"
        />
      <span class="sci-checkbox-label"></span>
    </span>
    {{ i18n.t('forms.show.range_label') }}
  </div>
  <hr class="my-4 w-full">
  <div class="bg-sn-super-light-grey rounded p-4">
    <div class="flex items-center gap-4">
      <h5>{{ i18n.t('forms.show.validations.future_dates.title') }}</h5>
      <span class="sci-toggle-checkbox-container">
        <input type="checkbox"
               class="sci-toggle-checkbox"
               @change="$emit('updateField')"
               v-model="editField.attributes.data.validations.disabled_future_dates" />
        <span class="sci-toggle-checkbox-label"></span>
      </span>
    </div>
    <div>{{ i18n.t('forms.show.validations.future_dates.description') }}</div>
  </div>
  </div>
</template>

<script>
import fieldMixin from './field_mixin';

export default {
  name: 'DateTimeField',
  mixins: [fieldMixin]
};
</script>
