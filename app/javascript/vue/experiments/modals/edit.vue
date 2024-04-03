<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <form @submit.prevent="submit">
        <div class="modal-content">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <i class="sn-icon sn-icon-close"></i>
            </button>
            <h4 class="modal-title truncate !block" :title="experiment.name">
              {{ i18n.t('experiments.edit.modal_title', { experiment: experiment.name }) }}
            </h4>
          </div>
          <div class="modal-body">
            <label class="sci-label">{{ i18n.t('experiments.new.name') }}</label>
            <div  class="sci-input-container-v2 mb-4">
              <input type="text" class="sci-input-field"
                     v-model="name"
                     autofocus
                     ref="input"
                    :placeholder="i18n.t('experiments.new.name_placeholder')">
            </div>
            <label class="sci-label">{{ i18n.t('experiments.new.description') }}</label>
            <div class="sci-input-container-v2 h-40">
              <textarea class="sci-input-field"
                        ref="description"
                        v-model="description">
              </textarea>
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
            <button type="submit" :disabled="!validName" class="btn btn-primary">
              {{ i18n.t('experiments.edit.modal_create') }}
            </button>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
/* global HelperModule SmartAnnotation */

import axios from '../../../packs/custom_axios.js';
import modalMixin from '../../shared/modal_mixin';

export default {
  name: 'EditModal',
  props: {
    experiment: Object,
  },
  data() {
    return {
      name: this.experiment.name,
      description: this.experiment.description,
    };
  },
  computed: {
    validName() {
      return this.name.length > 0;
    },
  },
  mounted() {
    SmartAnnotation.init($(this.$refs.description), false);
  },
  mixins: [modalMixin],
  methods: {
    submit() {
      axios.patch(this.experiment.urls.update, {
        experiment: {
          name: this.name,
          description: this.$refs.description.value,
        },
      }).then((response) => {
        this.$emit('update');
        HelperModule.flashAlertMsg(response.data.message, 'success');
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response.data.message, 'danger');
      });
    },
  },
};
</script>
