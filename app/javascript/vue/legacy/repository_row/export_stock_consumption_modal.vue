<template>
  <div ref="modal"
       class="modal fade"
       id="exportStockConsumptionModal"
       tabindex="-1"
       role="dialog"
       aria-labelledby="modal-export-stock-consumption-label"
       data-e2e="e2e-MD-invInventoryExportConsumptionAT">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" :aria-label="i18n.t('general.close')" data-e2e="e2e-BT-exportMD-close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title"> {{ i18n.t('zip_export.consumption_modal_label') }} </h4>
        </div>
        <div class="modal-body">
          <p>{{ i18n.t('zip_export.consumption_header_html', { repository: repository?.name }) }} </p>
          <p v-html="i18n.t('zip_export.consumption_body_html')"> </p>
          <p class='pb-0' v-html="i18n.t('zip_export.consumption_footer_html')"></p>
        </div>
        <div class="modal-footer">
          <button type='button' class='btn btn-secondary' data-dismiss='modal' id='close-modal-export-stock-consumption' data-e2e='e2e-BT-exportMD-cancel'>
            {{ i18n.t('general.cancel') }}
          </button>

          <button class="btn btn-success" id="export-stock-consumption" @click="exportConsumption" data-e2e='e2e-BT-exportMD-export'>
            {{ i18n.t('zip_export.consumption_generate') }}
          </button>
         </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ExportStockConsumptionModal',
  props: {
    exportUrl: { type: String, required: true }
  },
  data() {
    return {
      repository: null,
      selectedRows: []
    };
  },
  created() {
    window.exportStockConsumptionModalComponent = this;
  },
  beforeUnmount() {
    delete window.exportStockConsumptionModalComponent;
  },
  methods: {
    exportConsumption() {
      $.post(this.repository.export_consumption_url, { row_ids: this.selectedRows })
        .done((data) => {
          HelperModule.flashAlertMsg(data.message, 'success');
        })
        .fail((data) => {
          HelperModule.flashAlertMsg(data.responseJSON.message, 'danger');
        })
        .always(() => {
          this.closeModal();
        });
    },
    fetchRepositoryData(selectedRows, params) {
      this.selectedRows = selectedRows;
      $.get(this.exportUrl, params)
        .done((data) => {
          this.repository = data;
          this.showModal();
        });
    },
    closeModal() {
      $(this.$refs.modal).modal('hide');
    },
    showModal() {
      $(this.$refs.modal).modal('show');
    }
  }
};
</script>
