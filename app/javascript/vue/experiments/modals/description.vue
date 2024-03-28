<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title truncate !block" id="edit-project-modal-label" :title="experiment.name">
            {{ experiment.name }}
          </h4>
        </div>
        <div class="modal-body" v-html="experiment.sa_description"></div>
        <div class="modal-footer">
          <button type="button" class="btn btn-primary" data-dismiss="modal">{{ i18n.t('general.close') }}</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>

import modalMixin from '../../shared/modal_mixin';

export default {
  name: 'DescriptionModal',
  props: {
    experiment: Object,
  },
  mixins: [modalMixin],
};
</script>
