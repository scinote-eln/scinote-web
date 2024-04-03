<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <form @submit.prevent="submit">
        <div class="modal-content">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <i class="sn-icon sn-icon-close"></i>
            </button>
            <h4 class="modal-title truncate !block" id="edit-project-modal-label" :title="my_module.name">
              {{ i18n.t('experiments.table.modal_move_modules.title') }}
            </h4>
          </div>
          <div class="modal-body">
            <SelectDropdown :optionsUrl="my_module.urls.experiments_to_move"
                            :value="targetExperiment"
                            :seachable="true"
                            @change="changeExperiment" />
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
            <button class="btn btn-primary" :disabled="!targetExperiment" type="submit">
              {{ i18n.t('experiments.table.modal_move_modules.confirm') }}
            </button>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
/* global HelperModule */

import SelectDropdown from '../../shared/select_dropdown.vue';
import axios from '../../../packs/custom_axios.js';
import modalMixin from '../../shared/modal_mixin';

export default {
  name: 'MoveModal',
  props: {
    my_module: Object
  },
  mixins: [modalMixin],
  components: {
    SelectDropdown
  },
  data() {
    return {
      targetExperiment: null
    };
  },
  methods: {
    submit() {
      axios.post(this.my_module.urls.move, {
        to_experiment_id: this.targetExperiment,
        my_module_ids: [this.my_module.id]
      }).then((response) => {
        this.$emit('move');
        HelperModule.flashAlertMsg(response.data.message, 'success');
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response.data.message, 'danger');
      });
    },
    changeExperiment(experiment) {
      this.targetExperiment = experiment;
    }
  }
};
</script>
