<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <form @submit.prevent="submit">
        <div class="modal-content">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <i class="sn-icon sn-icon-close"></i>
            </button>
            <h4 class="modal-title truncate !block">
              {{ i18n.t('experiments.table.modal_duplicate_modules.title') }}
            </h4>
          </div>
          <div class="modal-body">
            <div class="flex items-center gap-2.5">
              <span class="sci-checkbox-container">
                <input type="checkbox" class="sci-checkbox" v-model="copyResults" />
                <span class="sci-checkbox-label"></span>
              </span>
              {{ i18n.t('experiments.table.modal_duplicate_modules.copy_results') }}
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
            <button class="btn btn-primary" :disabled="submitting" type="submit">
              {{ i18n.t('experiments.table.modal_duplicate_modules.confirm') }}
            </button>
          </div>
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
  name: 'DuplicateModal',
  props: {
    duplicateObject: Object
  },
  mixins: [modalMixin],
  data() {
    return {
      copyResults: false,
      submitting: false
    };
  },
  methods: {
    submit() {
      this.submitting = true;

      axios.post(this.duplicateObject.path, {
        my_module_ids: this.duplicateObject.ids,
        copy_results: this.copyResults
      }).then(() => {
        this.$emit('duplicate');
      }).catch((error) => {
        this.submitting = false;
        HelperModule.flashAlertMsg(error.response.data.error, 'danger');
      });
    }
  }
};
</script>
