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
          <p>{{ i18n.t('zip_export.consumption_header_html', { repository: repository.attributes.name }) }} </p>
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

import axios from '../../../packs/custom_axios.js';
import modalMixin from '../../shared/modal_mixin';

import {
  export_repository_stock_items_team_path
} from '../../../routes.js';


export default {
  name: 'ExportStockConsumptionModal',
  props: {
    repository: { type: Object },
    rows: { type: Array, default: () => [] },
  },
  mixins: [modalMixin],
  methods: {
    exportConsumption() {
      axios.get(export_repository_stock_items_team_path(this.repository.attributes.team_id), {
        params: { row_ids: this.rows }
      })
        .then((response) => {
          HelperModule.flashAlertMsg(response.data.message, 'success');
        })
        .catch((error) => {
          HelperModule.flashAlertMsg(error.response.data.message, 'danger');
        })
        .finally(() => {
          this.$emit('close');
        });
    }
  }
};
</script>
