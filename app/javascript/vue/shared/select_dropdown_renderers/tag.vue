<template>
  <div v-if="option" class="sci-tag text-white" :style="{
    'background-color': option[2].color
  }">
    {{ option[1] }}
  </div>
</template>

<script>
export default {
  name: 'TagRenderer',
  props: {
    option: {
      type: Array,
      required: true
    }
  }
};
</script>
