<template>
  <div class="mb-6">TODO</div>
</template>

<script>
import Select from '../../select.vue';

export default {
  name: 'SelectFilter',
  props: {
    filter: { type: Object, required: true }
  },
  components: { Select }
};
</script>
