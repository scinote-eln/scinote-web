<template>
  <div v-if="option" class="sci-tag" :class="tagTextColor(option[2].color)" :style="{
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
  },
  methods: {
    tagTextColor(color) {
      return window.isColorBright(color) ? 'text-black' : 'text-white';
    }
  }
};
</script>
