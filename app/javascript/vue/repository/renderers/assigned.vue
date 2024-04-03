<template>
  <div>
    {{ params.value.tasks }}
  </div>
</template>

<script>
export default {
  name: 'Assigned',
  props: {
    params: {
      required: true
    }
  }
};
</script>
