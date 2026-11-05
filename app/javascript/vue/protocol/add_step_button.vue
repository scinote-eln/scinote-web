<template>
  <!-- 60px strip between step cards; only the button is clickable -->
  <div class="flex justify-center py-2">
    <span :data-sn-tooltip="disabled ? i18n.t('protocols.action_disabled') : i18n.t('protocols.steps.add_step')">
      <button type="button"
              class="btn btn-light btn-black btn-lg icon-btn w-11 hover:!bg-sn-light-grey disabled:hover:!bg-sn-white"
              :disabled="disabled"
              :aria-label="i18n.t('protocols.steps.add_step')"
              data-e2e="e2e-BT-protocol-templateSteps-insertStep"
              @click="$emit('add')">
        <i class="sn-icon sn-icon-new-task" aria-hidden="true"></i>
      </button>
    </span>
  </div>
</template>

<script>
export default {
  name: 'AddStepButton',
  props: {
    disabled: { type: Boolean, default: false }
  },
  emits: ['add']
};
</script>
