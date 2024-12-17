<template>
  <div class="sci-input-container-v2 h-24">
    <textarea class="sci-input" :disabled="marked_as_na" :placeholder="i18n.t('forms.fields.add_text')"></textarea>
  </div>
</template>

<script>
import fieldMixin from './field_mixin';

export default {
  name: 'TextField',
  mixins: [fieldMixin]
};
</script>
