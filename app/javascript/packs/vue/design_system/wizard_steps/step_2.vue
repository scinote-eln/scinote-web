<template>
  <div class="modal-header">
      <button type="button" class="close" data-dismiss="modal" aria-label="Close">
        <i class="sn-icon sn-icon-close"></i>
      </button>
      <h4 class="modal-title truncate flex items-center gap-4">
        Step 2 actions
      </h4>
  </div>
  <div class="modal-body grow">
    All steps have access to shared params

    <input
      type="text"
      class="form-control"
      placeholder="Type something"
      v-model="params.text"/>
  </div>
  <div class="modal-footer">
    <button class="btn btn-light" @click="$emit('back')">Back</button>
    <button class="btn btn-primary" @click="$emit('next')">Next</button>
  </div>
</template>

<script>

export default {
  emits: ['back', 'next', 'close'],
  name: 'Step2',
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
