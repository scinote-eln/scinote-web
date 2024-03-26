<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <form @submit.prevent="submit">
        <div class="modal-content">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <i class="sn-icon sn-icon-close"></i>
            </button>
            <h4 class="modal-title truncate !block" id="edit-project-modal-label" :title="experiment.name">
              {{ i18n.t("experiments.move.modal_title", { experiment: experiment.name }) }}
            </h4>
          </div>
          <div class="modal-body">
            <p><small>{{ i18n.t("experiments.move.notice") }}</small></p>
            <SelectDropdown :optionsUrl="experiment.urls.projects_to_move"
                            :value="targetProject"
                            :searchable="true"
                            @change="changeProject" />
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
            <button class="btn btn-primary" :disabled="!targetProject || disableSubmit" type="submit">
              {{ i18n.t('experiments.move.modal_submit') }}
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
    experiment: Object,
  },
  mixins: [modalMixin],
  components: {
    SelectDropdown,
  },
  data() {
    return {
      targetProject: null,
      disableSubmit: false
    };
  },
  methods: {
    async submit() {
      this.disableSubmit = true;
      await axios.post(this.experiment.movePath, {
        project_id: this.targetProject
      }).then((response) => {
        this.$emit('move');
        window.location.replace(response.data.path);
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response.data.message, 'danger');
      });
      this.disableSubmit = false;
    },
    changeProject(project) {
      this.targetProject = project;
    },
  },
};
</script>
