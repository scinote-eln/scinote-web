<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <form @submit.prevent="submit">
        <div class="modal-content">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <i class="sn-icon sn-icon-close"></i>
            </button>
            <h4 class="modal-title truncate !block" :title="experiment?.name">
              {{ modalHeader }}
            </h4>
          </div>
          <div class="modal-body">
            <label class="sci-label">{{ i18n.t('experiments.new.name') }}</label>
            <div class="sci-input-container-v2 mb-6" :class="{'error': error}" :data-error="error">
              <input type="text" class="sci-input-field"
                     v-model="name"
                     autofocus ref="input"
                    :placeholder="i18n.t('experiments.new.name_placeholder')">
            </div>
            <div class="mb-6">
              <label class="sci-label">{{ i18n.t("experiments.index.start_date") }}</label>
              <DateTimePicker
                @change="updateStartDate"
                :defaultValue="startDate"
                mode="date"
                :clearable="true"
                :placeholder="i18n.t('experiments.index.add_start_date')"
              />
            </div>
            <div class="mb-6">
              <label class="sci-label">{{ i18n.t("experiments.index.due_date") }}</label>
              <DateTimePicker
                @change="updateDueDate"
                :defaultValue="dueDate"
                mode="date"
                :clearable="true"
                :placeholder="i18n.t('experiments.index.add_due_date')"
              />
            </div>
            <div class="mb-6">
              <TinymceEditor
                v-model="description"
                textareaId="descriptionModelInput"
                :placeholder="i18n.t('experiments.index.add_description')"
              ></TinymceEditor>
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
            <button type="submit" :disabled="submitting || !validName" class="btn btn-primary">
              {{ submitButtonLabel }}
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
import modalMixin from '../../shared/modal_mixin.js';
import DateTimePicker from '../../shared/date_time_picker.vue';
import TinymceEditor from '../../shared/tinymce_editor.vue';

export default {
  name: 'NewEditModal',
  props: {
    experiment: Object,
    createUrl: String
  },
  components: {
    DateTimePicker,
    TinymceEditor
  },
  data() {
    return {
      name: this.experiment?.name || '',
      description: this.experiment?.description || '',
      error: null,
      submitting: false,
      startDate: null,
      dueDate: null
    };
  },
  computed: {
    validName() {
      return this.name.length > 0;
    },
    modalHeader() {
      if (this.createUrl) {
        return this.i18n.t('experiments.new.modal_title');
      }

      return this.i18n.t('experiments.edit.modal_title', { experiment: this.experiment.name });
    },
    submitButtonLabel() {
      if (this.createUrl) {
        return this.i18n.t('experiments.new.modal_create');
      }

      return this.i18n.t('experiments.edit.modal_create');
    }
  },
  mounted() {
    SmartAnnotation.init($(this.$refs.description), false);
    $(this.$refs.modal).on('hidden.bs.modal', this.handleAtWhoModalClose);
  },
  created() {
    if (this.experiment?.start_date_cell?.value) {
      this.startDate = new Date(this.experiment.start_date_cell?.value);
    }
    if (this.experiment?.due_date_cell?.value) {
      this.dueDate = new Date(this.experiment.due_date_cell?.value);
    }
  },
  mixins: [modalMixin],
  methods: {
    submit() {
      this.submitting = true;

      const experimentData = {
        name: this.name,
        description: this.description,
        start_on: this.startDate,
        due_date: this.dueDate
      };
      if (this.createUrl) {
        this.createExperiment(experimentData);
      } else {
        this.updateExperiment(experimentData);
      }
    },
    createExperiment(experimentData) {
      axios.post(this.createUrl, {
        experiment: experimentData
      }).then((response) => {
        this.$emit('create');
        window.location.replace(response.data.path);
      }).catch((error) => {
        this.submitting = false;
        [this.error] = error.response.data.name;
      });
    },
    updateExperiment(experimentData) {
      axios.patch(this.experiment.urls.update, {
        experiment: experimentData
      }).then((response) => {
        this.$emit('update');
        this.submitting = false;
        HelperModule.flashAlertMsg(response.data.message, 'success');
      }).catch((error) => {
        this.submitting = false;
        HelperModule.flashAlertMsg(error.response.data.message, 'danger');
      });
    },
    updateStartDate(startDate) {
      this.startDate = this.stripTime(startDate);
    },
    updateDueDate(dueDate) {
      this.dueDate = this.stripTime(dueDate);
    },
    stripTime(date) {
      if (date) {
        return new Date(Date.UTC(
          date.getFullYear(),
          date.getMonth(),
          date.getDate(),
          0, 0, 0, 0
        ));
      }

      return date;
    },
    handleAtWhoModalClose() {
      $('.atwho-view.old').css('display', 'none');
    }
  }
};
</script>
