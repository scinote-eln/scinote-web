<template>
  <div ref="modal" @keydown.esc="cancel" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <form @submit.prevent="submit" class="modal-content">
        <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-label="Close"><i class="sn-icon sn-icon-close"></i></button>
        <h4 class="modal-title">
          {{ this.i18n.t('repositories.index.modal_export.title') }}
        </h4>
        </div>
        <div class="modal-body">
            <p class="description-p1 mb-6" v-html="i18n.t('repositories.index.modal_export.description_p1_html', {
                team_name: rows[0].team,
                count: rows.length})"></p>
            <p class="bg-sn-super-light-blue p-3 mb-6"> {{ this.i18n.t('repositories.index.modal_export.description_alert') }} </p>
            <p class="mb-6"> {{ this.i18n.t('repositories.index.modal_export.description_p2') }} </p>
            <div class="sci-radio-container mt-3">
              <input type="radio" class="sci-radio" name="file_type" value="xlsx" v-model="selectedOption">
              <span class="sci-radio-label"></span>
            </div>
            <label class="font-normal ml-3 mb-0">.xlsx</label>
            <div class="sci-radio-container ml-[30px]">
              <input type="radio" class="sci-radio" name="file_type" value="csv" v-model="selectedOption">
              <span class="sci-radio-label"></span>
            </div>
            <label class="font-normal ml-3 mb-0">.csv</label>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
          <button type="submit" class="btn btn-primary" :disabled="submitting"> {{ i18n.t('repositories.index.modal_export.export') }} </button>
        </div>
      </form>
    </div>
  </div>
</template>
<script>
/* global HelperModule */

import axios from '../../../packs/custom_axios.js';
import modalMixin from '../../shared/modal_mixin';

export default {
  name: 'ExportRepositoryModal',
  props: {
    rows: Object,
    exportAction: Object
  },
  mixins: [modalMixin],
  data() {
    return {
      selectedOption: this.exportAction.export_file_type,
      submitting: false
    };
  },
  methods: {
    submit() {
      const payload = {
        repository_ids: this.rows.map((row) => row.id),
        file_type: this.selectedOption
      };

      this.submitting = true;

      axios.post(this.exportAction.path, payload).then((response) => {
        this.$emit('export');
        this.submitting = false;
        HelperModule.flashAlertMsg(response.data.message, 'success');
      }).catch((error) => {
        this.submitting = false;
        HelperModule.flashAlertMsg(error.response.data.error, 'danger');
      });
    }
  }
};
</script>
