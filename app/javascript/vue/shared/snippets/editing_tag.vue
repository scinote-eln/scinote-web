<template>
  <span
    class="w-6 h-6 cursor-pointer rounded-full flex items-center justify-center text-[10px] font-bold text-white shrink-0"
    :style="{ backgroundColor: color }"
    :data-sn-tooltip="i18n.t('general.editing_tag', { user: user.name })"
  >
    {{ initial }}
  </span>
</template>

<script>
import tooltipMixin from '../../mixins/tooltipMixin.js';

export default {
  name: 'EditingTag',
  mixins: [tooltipMixin],
  props: {
    user: {
      type: Object,
      required: true
    }
  },
  computed: {
    initial() {
      return this.user.name.charAt(0).toUpperCase();
    },
    color() {
      const email = this.user.email;
      let hash = 0;
      for (let i = 0; i < email.length; i++) {
        hash = email.charCodeAt(i) + ((hash << 5) - hash);
      }

      const hue = Math.abs(hash) % 360;

      return `hsl(${hue}, 60%, 45%)`;
    }
  }
};
</script>
