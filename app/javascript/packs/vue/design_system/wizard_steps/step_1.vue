<template>
  <div class="modal-header">
      <button type="button" class="close" data-dismiss="modal" aria-label="Close">
        <i class="sn-icon sn-icon-close"></i>
      </button>
      <h4 class="modal-title truncate flex items-center gap-4">
        Step 1 actions
      </h4>
  </div>
  <div class="modal-body grow">
    You can add any custom html here or render params like this:

    {{ params }}
  </div>
  <div class="modal-footer">
    <button class="btn btn-light" @click="$emit('close')">Cancel</button>
    <button class="btn btn-primary" @click="$emit('next')">Next</button>
  </div>
</template>

<script>

export default {
  emits: ['close', 'next', 'back'],
  name: 'Step1',
  props: {
    params: {
      type: Object,
      required: true
    },
    wizardComponent: {
      type: Object,
      required: true
    }
  }
};
</script>
