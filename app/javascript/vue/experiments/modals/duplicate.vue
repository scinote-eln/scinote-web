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
              {{ i18n.t("experiments.clone.modal_title", { experiment: experiment.name }) }}
            </h4>
          </div>
          <div class="modal-body">
            <SelectDropdown :optionsUrl="experiment.urls.projects_to_clone"
                            :value="targetProject"
                            :searchable="true"
                            :labelRenderer="optionRenderer"
                            :optionRenderer="optionRenderer"
                            @change="changeProject" />
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
            <button class="btn btn-primary" :disabled="!targetProject" type="submit">
              {{ i18n.t('experiments.clone.modal_submit') }}
            </button>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
/* global I18n HelperModule */

import SelectDropdown from '../../shared/select_dropdown.vue';
import axios from '../../../packs/custom_axios.js';
import modalMixin from '../../shared/modal_mixin';

export default {
  name: 'CloneModal',
  props: {
    experiment: Object,
  },
  mixins: [modalMixin],
  components: {
    SelectDropdown,
  },
  mounted() {
    this.targetProject = this.experiment.project_id;
  },
  data() {
    return {
      targetProject: null,
    };
  },
  methods: {
    submit() {
      axios.post(this.experiment.urls.clone, {
        experiment: {
          project_id: this.targetProject,
        },
      }).then((response) => {
        this.$emit('update');
        window.location.replace(response.data.url);
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response.data.message, 'danger');
      });
    },
    changeProject(project) {
      this.targetProject = project;
    },
    optionRenderer(option) {
      if (option[0] === this.experiment.project_id) {
        return `${option[1]} ${I18n.t('experiments.clone.current_project')}`;
      }

      return option[1];
    }
  },
};
</script>
