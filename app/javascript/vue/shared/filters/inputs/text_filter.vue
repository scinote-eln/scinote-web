<template>
  <div class="mb-6">
    <inputWithHistory
      :modelValue="values[filter.key]"
      :label="filter.label || i18n.t('filters_modal.text.label')"
       @update:modelValue="update"
       :placeholder="filter.placeholder || i18n.t('filters_modal.text.placeholder')"
       :id="'textSearch' + filter.key"/>
  </div>
</template>

<script>
import inputWithHistory from '../../input_with_history.vue';

export default {
  name: 'TextFilter',
  props: {
    filter: { type: Object, required: true },
    values: { type: Object }
  },
  components: {
    inputWithHistory
  },
  methods: {
    update(value) {
      this.$emit('update', { key: this.filter.key, value });
    }
  }
};
</script>
