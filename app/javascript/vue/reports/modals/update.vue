<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content" data-e2e="e2e-MD-updateReportContent">
        <div class="modal-header">
          <button
            type="button"
            class="close"
            @click="$emit('dismiss')"
            data-dismiss="modal"
            aria-label="Close"
            data-e2e="e2e-BT-updateReportContentModal-close"
          >
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title truncate !block" id="update-report-modal-label" data-e2e="e2e-TX-updateReportContentModal-title">
            {{ i18n.t('projects.reports.index.generation.regeneration_modal_title') }}
          </h4>
        </div>
        <div class="modal-body">
          <div class="mb-6" data-e2e="e2e-TX-updateReportContentModal-description">
            {{ i18n.t('projects.reports.index.generation.regeneration_modal_body') }}
          </div>
          <h4 data-e2e="e2e-TX-updateReportContentModal-confirmation">
            {{ i18n.t('projects.reports.index.generation.regeneration_modal_confirmation') }}
          </h4>
        </div>
        <div class="modal-footer">
          <button
            type="button"
            class="btn btn-secondary"
            @click="$emit('dismiss')"
            data-dismiss="modal"
            data-e2e="e2e-BT-updateReportContentModal-cancel"
          >
            {{ i18n.t('general.no') }}
          </button>
          <button
            class="btn btn-primary"
            type="button"
            @click.prevent="$emit('confirm')"
            data-e2e="e2e-BT-updateReportContentModal-confirm"
          >
            {{ i18n.t('general.yes') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import modalMixin from '../../shared/modal_mixin';

export default {
  name: 'UpdateReportModal',
  mixins: [modalMixin]
};
</script>
