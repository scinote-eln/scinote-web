<template>
  <div class="flex flex-col gap-4">
    <hr class="my-4 w-full">
    <div>
      <h5 class="mb-4">{{ i18n.t('forms.show.dropdown_options_label') }}</h5>
      <div class="sci-input-container-v2 h-40" :class="{'error': !validField}" :data-error="optionFieldErrors">
        <textarea
          class="sci-input"
          v-model="options"
          @change="$emit('updateField')"
          :placeholder="i18n.t('forms.show.dropdown_options_placeholder_html')" />
      </div>
    </div>
    <hr class="my-4 w-full">
  </div>
</template>

<script>

import fieldMixin from './field_mixin';
import optionsMixin from './options_mixin';

export default {
  name: 'MultipleChoiceField',
  mixins: [fieldMixin, optionsMixin]
};
</script>
