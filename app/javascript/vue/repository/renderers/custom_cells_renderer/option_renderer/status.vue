<template>
  <div ref="container" class="flex items-center gap-2">
    <template v-if="option">
      <span>{{ option[1] }}</span>
    </template>
  </div>
</template>

<script>
import twemoji from 'twemoji';

export default {
  name: 'StatusOptionRenderer',
  props: {
    option: {
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
