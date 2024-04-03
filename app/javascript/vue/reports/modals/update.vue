<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" @click="$emit('dismiss')" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title truncate !block" id="update-report-modal-label">
            {{ i18n.t('projects.reports.index.generation.regeneration_modal_title') }}
          </h4>
        </div>
        <div class="modal-body">
          <div class="mb-6">
            {{ i18n.t('projects.reports.index.generation.regeneration_modal_body') }}
          </div>
          <h4>{{ i18n.t('projects.reports.index.generation.regeneration_modal_confirmation') }}</h4>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" @click="$emit('dismiss')" data-dismiss="modal">{{ i18n.t('general.no') }}</button>
          <button class="btn btn-primary" type="button" @click.prevent="$emit('confirm')">
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
