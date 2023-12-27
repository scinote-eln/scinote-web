<template>
  <div v-if="params.data.linked_tasks > 0"
       @click.stop="params.dtComponent.$emit('linked_my_modules', {}, [params.data])"
       class="cursor-pointer text-sn-blue"
  >
    {{ params.data.linked_tasks }}
  </div>
  <div v-else>
    0
  </div>
</template>

<script>
export default {
  name: 'LinkedMyModulesRenderer',
  props: {
    params: {
      required: true
    }
  }
};
</script>
