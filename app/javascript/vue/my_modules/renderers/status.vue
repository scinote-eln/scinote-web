<template>
  <span
    class="px-2 py-1 border border-solid rounded truncate"
    :class="{'text-sn-white' : !params.data.status.light_color}"
    :style="{'background-color': params.data.status.color}"
  >
    {{ params.data.status.name }}
  </span>
</template>

<script>
export default {
  name: 'StatusRenderer',
  props: {
    params: {
      required: true
    }
  }
};
</script>
