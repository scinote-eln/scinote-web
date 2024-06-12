<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog modal-sm" role="document">
      <div class="modal-content grow">
        <div class="modal-header gap-4">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close" data-e2e="e2e-BT-newInventoryModal-close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title truncate !block" id="edit-project-modal-label" data-e2e="e2e-TX-newInventoryModal-title">
            {{ i18n.t('repositories.import_records.steps.step4.title') }}
          </h4>
        </div>
        <div class="modal-body">
          <p class="text-sn-dark-grey mb-6">
            {{ i18n.t('repositories.import_records.steps.step4.subtitle', { inventory: params.attributes.name }) }}
          </p>
          <div>
            <b>{{ i18n.t('repositories.import_records.steps.step4.import_date') }}</b>
            {{ params.import_date }}
          </div>
          <div>
            <b>{{ i18n.t('repositories.import_records.steps.step4.imported_file') }}</b>
            {{ params.file_name }}
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-primary" @click="close">
            {{ i18n.t('repositories.import_records.steps.step4.close') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import modalMixin from '../../../shared/modal_mixin';


export default {
  name: 'SuccessStep',
  mixins: [modalMixin],
  props: {
    params: {
      type: Object,
      required: true
    }
  }
};
</script>
