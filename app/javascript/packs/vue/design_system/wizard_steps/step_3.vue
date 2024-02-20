<template>
  <div class="modal-header">
      <button type="button" class="close" data-dismiss="modal" aria-label="Close">
        <i class="sn-icon sn-icon-close"></i>
      </button>
      <h4 class="modal-title truncate flex items-center gap-4">
        Step 3 actions
      </h4>
  </div>
  <div class="modal-body grow">
    Our params - {{ params }}<br>

    If you want emit action use wizardComponent
    <br>
    <br>
    <br>

    <button class="btn btn-danger" @click="wizardComponent.$emit('alert')">Launch alert</button>
  </div>
  <div class="modal-footer">
    <button class="btn btn-light" @click="$emit('back')">Back</button>
    <button class="btn btn-primary" @click="$emit('close')">Apply</button>
  </div>
</template>

<script>

export default {
  emits: ['back', 'close', 'alert', 'next'],
  name: 'Step3',
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
