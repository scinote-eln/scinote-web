<template>
  <div class="relative">
    <div ref="field" class="h-10 w-0"></div>
    <teleport to="body">
      <div v-if="error && error.length > 0" ref="flyout" :id="randomId" class="sn-dropdown fixed z-[3000] left-0">
        <div class="sci-toast sci-toast-error">
          {{ error }}
          <i class="sn-icon sn-icon-close-small cursor-pointer" @click="$emit('close')"></i>
        </div>
      </div>
    </teleport>
  </div>
</template>

<script>
  import FixedFlyoutMixin from '../../shared/mixins/fixed_flyout.js';

  export default {
    name: 'ErrorFlyout',
    props: {
      error: String
    },
    data() {
      return {
        randomId: `error-flyout-${Math.random().toString(36).substring(2, 15)}`,
      };
    },
    watch: {
      error() {
        if (this.error && this.error.length > 0) {
          this.$nextTick(() => {
            this.setPosition();
            this.registerFlyoutForTooltips();
          });
        }
      }
    },
    mixins: [FixedFlyoutMixin]
  };
</script>
