<template>
  <div v-if="option" class="sci-tag text-white" :style="{
    'background-color': option[2].color
  }">
    <div class="text-block" :title="option[1]">{{ option[1] }}</div>
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
