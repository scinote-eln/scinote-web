<template>
  <div>
    <hr class="my-4 w-full">
    <div>
      <h5 class="mb-4">{{ i18n.t('forms.show.dropdown_options_label') }}</h5>
      <div class="sci-input-container-v2 h-40" >
        <textarea
          class="sci-input"
          v-model="editField.attributes.data.options"
          @change="$emit('updateField')"
          :placeholder="i18n.t('forms.show.dropdown_options_placeholder_html')" />
      </div>
    </div>
    <hr class="my-4 w-full">
  </div>
</template>

<script>

export default {
  name: 'SingleChoiceField',
  props: {
    field: Object
  },
  watch: {
    editField: {
      handler() {
        this.$emit('syncField', this.editField);
      },
      deep: true
    }
  },
  data() {
    return {
      editField: { ...this.field }
    };
  }
};
</script>
