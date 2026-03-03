<template>
  <div v-if="params.value">
    <div ref="container" class="flex items-center gap-1">
      <span>{{ params.value.value.icon }}</span>
      <span>{{ params.value.value.status }}</span>
    </div>
  </div>
</template>

<script>
import twemoji from 'twemoji';
export default {
  name: 'StatusValue',
  props: {
    params: {
      required: true
    }
  },
  mounted() {
    this.renderEmoji();
  },
  methods: {
    renderEmoji() {
      twemoji.size = '24x24';
      twemoji.base = '/images/twemoji/';
      if (this.$refs.container) {
        twemoji.parse(this.$refs.container);
      }
    }
  }
};
</script>
