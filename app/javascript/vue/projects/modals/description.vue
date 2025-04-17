<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title truncate !block" id="edit-project-modal-label" :title="project.name">
            {{ project.name }}
          </h4>
        </div>
        <div class="modal-body">
          <div class="[&_.atwho-user-container]:!whitespace-normal whitespace-pre-wrap">
            {{ project.description }}
          </div>
        </div>
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
    project: Object
  },
  mixins: [modalMixin]
};
</script>
