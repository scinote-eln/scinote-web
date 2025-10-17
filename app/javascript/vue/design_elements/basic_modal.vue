<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close"><i class="sn-icon sn-icon-close"></i></button>
          <h4 class="modal-title">
            Modal Title
          </h4>
          <div class="modal-subtitle">
            Modal subtitle
          </div>
        </div>
        <div class="modal-body">
          <div class="h-80">
            Modal body
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" @click="close">Cancel</button>
          <button class="btn btn-primary">Main Button</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import modalMixin from '../shared/modal_mixin';

export default {
  name: 'BasicModal',
  mixins: [modalMixin]
};
</script>
