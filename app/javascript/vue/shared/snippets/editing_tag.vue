<template>
  <img
    :src="user.avatar_url"
    :alt="user.name"
    class="w-6 h-6 cursor-pointer rounded-full shrink-0"
    :data-sn-tooltip="i18n.t('general.editing_tag', { user: user.name })"
  />
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
  }
};
</script>
