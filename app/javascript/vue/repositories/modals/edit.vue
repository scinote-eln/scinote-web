<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <form @submit.prevent="submit">
        <div class="modal-content">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <i class="sn-icon sn-icon-close"></i>
            </button>
            <h4 class="modal-title truncate !block" id="edit-project-modal-label" :title="repository.name">
              {{ i18n.t('repositories.index.modal_rename.title_html', {name: repository.name }) }}
            </h4>
          </div>
          <div class="modal-body">
            <div class="mb-6">
              <label class="sci-label">{{ i18n.t("repositories.index.modal_rename.name") }}</label>
              <div class="sci-input-container-v2" :class="{'error': error}" :data-error="error">
                <input type="text" v-model="name" class="sci-input-field"
                       autofocus="true" ref="input"
                       :placeholder="i18n.t('repositories.index.modal_rename.name_placeholder')" />
              </div>
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
            <button class="btn btn-primary" type="submit">
              {{ i18n.t('repositories.index.modal_rename.rename') }}
            </button>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script>

import axios from '../../../packs/custom_axios.js';
import modalMixin from '../../shared/modal_mixin';

export default {
  name: 'EditRepositoryModal',
  props: {
    repository: Object
  },
  mixins: [modalMixin],
  data() {
    return {
      name: this.repository.name,
      error: null
    };
  },
  methods: {
    submit() {
      axios.put(this.repository.urls.update, {
        repository: {
          name: this.name
        }
      }).then(() => {
        this.error = null;
        this.$emit('update');
      }).catch((error) => {
        this.error = error.response.data.name;
      });
    }
  }
};
</script>
