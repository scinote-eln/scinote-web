<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <form @submit.prevent="submit">
        <div class="modal-content">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <i class="sn-icon sn-icon-close"></i>
            </button>
            <h4 class="modal-title truncate !block" :title="my_module.name">
              {{ i18n.t('experiments.canvas.edit.modal_edit_module.title') }}
            </h4>
          </div>
          <div class="modal-body">
            <label class="sci-label">{{ i18n.t('experiments.canvas.edit.modal_edit_module.name') }}</label>
            <div  class="sci-input-container-v2 mb-4">
              <input type="text" class="sci-input-field"
                     v-model="name" ref="input"
                     autofocus>
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
            <button type="submit" :disabled="!nameIsValid" class="btn btn-primary">
              {{ i18n.t('experiments.canvas.edit.modal_edit_module.confirm') }}
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
  name: 'EditModal',
  props: {
    my_module: Object
  },
  data() {
    return {
      name: this.my_module.name
    };
  },
  computed: {
    nameIsValid() {
      return this.name.length > 0;
    }
  },
  mixins: [modalMixin],
  methods: {
    submit() {
      axios.patch(this.my_module.urls.update, {
        my_module: {
          name: this.name
        }
      }).then(() => {
        this.$emit('update');
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response.data.message, 'danger');
      });
    }
  }
};
</script>
