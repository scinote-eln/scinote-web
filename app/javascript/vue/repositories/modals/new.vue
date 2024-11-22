<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <form @submit.prevent="submit">
        <div class="modal-content" data-e2e="e2e-MD-newInventory">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close" data-e2e="e2e-BT-newInventoryModal-close">
              <i class="sn-icon sn-icon-close"></i>
            </button>
            <h4 class="modal-title truncate !block" id="edit-project-modal-label" data-e2e="e2e-TX-newInventoryModal-title">
              {{ i18n.t('repositories.index.modal_create.title') }}
            </h4>
          </div>
          <div class="modal-body">
            <div class="mb-6">
              <label class="sci-label" data-e2e="e2e-TX-newInventoryModal-inputLabel">{{ i18n.t("repositories.index.modal_create.name_label") }}</label>
              <div class="sci-input-container-v2" :class="{'error': error}" :data-error="error">
                <input type="text" v-model="name"
                       class="sci-input-field"
                       autofocus="true" ref="input"
                       data-e2e="e2e-IF-newInventoryModal-name"
                       :placeholder="i18n.t('repositories.index.modal_create.name_placeholder')" />
              </div>
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal" data-e2e="e2e-BT-newInventoryModal-cancel">{{ i18n.t('general.cancel') }}</button>
            <button class="btn btn-primary" type="submit" :disabled="!validName" data-e2e="e2e-BT-newInventoryModal-create">
              {{ i18n.t('repositories.index.modal_create.submit') }}
            </button>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
/* global HelperModule GLOBAL_CONSTANTS */

import axios from '../../../packs/custom_axios.js';
import modalMixin from '../../shared/modal_mixin';

export default {
  name: 'NewRepositoryModal',
  props: {
    createUrl: String
  },
  mixins: [modalMixin],
  data() {
    return {
      name: '',
      error: null
    };
  },
  computed: {
    validName() {
      return this.name.length >= GLOBAL_CONSTANTS.NAME_MIN_LENGTH;
    }
  },
  methods: {
    submit() {
      axios.post(this.createUrl, {
        repository: {
          name: this.name
        }
      }).then((response) => {
        this.error = null;
        this.$emit('create');
        HelperModule.flashAlertMsg(response.data.message, 'success');
      }).catch((error) => {
        this.error = error.response.data.name;
      });
    }
  }
};
</script>
