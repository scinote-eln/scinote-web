<template>
  <div class="mb-6">
    <inputWithHistory :modelValue="value" :label="filter.label" @update:modelValue="update" :placeholder="filter.placeholder" :id="'textSearch' + filter.key"/>
  </div>
</template>

<script>
import inputWithHistory from '../../input_with_history.vue';

export default {
  name: 'TextFilter',
  props: {
    filter: { type: Object, required: true },
    value: { type: String }
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
