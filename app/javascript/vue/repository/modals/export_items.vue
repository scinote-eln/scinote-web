<template>
  <div class="modal fade"
     id="exportRowsModal"
     ref="modal"
     tabindex="-1"
     role="dialog"
     aria-labelledby="modal-export-repository-label">
    <div class="modal-dialog" role="document" data-e2e="e2e-MD-invInventoryExportItemsAT">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" data-e2e="e2e-BT-exportMD-close" class="close" data-dismiss="modal" aria-label="Close"><i class="sn-icon sn-icon-close"></i></button>
          <h4 class="modal-title">{{ i18n.t('zip_export.repositories_modal_label') }}</h4>
        </div>
        <div class="modal-body">
          <div class="mb-6" v-html="i18n.t('zip_export.repository_header_html', {repository: repository.attributes.name})">
          </div>
          <div class="mb-6" v-html="i18n.t('zip_export.repository_footer_html')">
          </div>

          <div class="sci-radio-container">
            <input id="file_type_radio" class="sci-radio" type="radio" v-model="format" value="xlsx" name="file_type">
            <span class="sci-radio-label"></span>
          </div>
          <label class="mr-6 ml-3 font-normal" for="file_type_xlsx">.xlsx</label>

          <div class="sci-radio-container">
            <input id="file_type_radio" class="sci-radio" type="radio" v-model="format" value="csv" name="file_type">
            <span class="sci-radio-label"></span>
          </div>
          <label class="mr-6 ml-3 font-normal" for="file_type_csv">.csv</label>
        </div>
        <div class="modal-footer">
          <button type='button' data-e2e='e2e-BT-exportMD-cancel' class='btn btn-secondary' data-dismiss='modal' id='close-modal-export-repository-rows'>
            {{ i18n.t('general.cancel') }}
          </button>
          <button type="button" :disabled="loading" data-e2e="e2e-BT-exportMD-export" @click="exportRepositoryRows" class="btn btn-primary" id="export-repository-rows">
            {{ i18n.t('my_modules.repository.export') }}
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
  export_repository_team_path
} from '../../../routes.js';

export default {
  name: 'ExportItemsModal',
  props: {
    repository: { type: Object },
    params: { type: Object }
  },
  mixins: [modalMixin],
  data() {
    return {
      loading: false,
      format: 'xlsx'
    };
  },
  methods: {
    exportRepositoryRows() {
      this.loading = true;
      axios.post(export_repository_team_path(this.repository.id), {
        row_ids: this.params.rows,
        header_ids: this.params.headers,
        file_type: this.format
      }).then((response) => {
        HelperModule.flashAlertMsg(response.data.message, 'success');
        this.$emit('close');
      }).catch(() => {
        HelperModule.flashAlertMsg(I18n.t('general.error'), 'danger');
      }).finally(() => {
        this.loading = false;
      });
    }
  }
};
</script>
