<template>
  <div class="modal-header">
    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
      <i class="sn-icon sn-icon-close"></i>
    </button>
    <h4 class="modal-title truncate flex items-center gap-4">
      {{ i18n.t('my_modules.reports.wizard.second_step.title') }}
    </h4>
  </div>
  <div class="modal-body flex flex-col gap-4">
    <div class="flex flex-col gap-1">
      <div class="text-base font-semibold">
        {{ i18n.t('my_modules.reports.wizard.second_step.form.header.label') }}
      </div>
      <label class="sci-label">{{ i18n.t('my_modules.reports.wizard.second_step.form.header.description') }}</label>
      <div class="sci-input-container-v2 h-28" :class="{'error': !validHeader}" :data-error="headerFieldErrors" >
        <textarea v-model="header"
          class="sci-input-field"
          :placeholder="i18n.t('my_modules.reports.wizard.second_step.form.header.placeholder')"
        ></textarea>
      </div>
    </div>

    <div class="flex flex-col gap-2">
      <div class="text-base font-semibold">
        {{ i18n.t('my_modules.reports.wizard.second_step.form.footer.label') }}
      </div>
      <div class="flex flex-col gap-3 bg-sn-super-light-grey p-3 rounded">
        <div class="flex items-center gap-4">
          <span class="sci-label font-semibold">{{ i18n.t('my_modules.reports.wizard.second_step.form.footer.display_attachment_references') }}</span>
          <div class="sci-toggle-checkbox-container">
            <input type="checkbox"
                  class="sci-toggle-checkbox"
                  v-model="displayAttachmentReferences"
                  data-e2e="e2e-TG-task-analyticalReport-generateReportModal-displayAttachmentReferences" />
            <span class="sci-toggle-checkbox-label"></span>
          </div>
        </div>
        <div v-if="displayAttachmentReferences" class="flex items-center gap-4">
          <span class="sci-label">{{ i18n.t('my_modules.reports.wizard.second_step.form.footer.add_reference_page_numbers') }}</span>
          <div class="sci-toggle-checkbox-container">
            <input type="checkbox"
                  class="sci-toggle-checkbox"
                  v-model="addReferencePageNumbers"
                  data-e2e="e2e-TG-task-analyticalReport-generateReportModal-addReferencePageNumbers" />
            <span class="sci-toggle-checkbox-label"></span>
          </div>
        </div>
      </div>

      <div class="flex flex-col gap-3 bg-sn-super-light-grey p-3 rounded">
        <div class="flex items-center gap-4">
          <span class="sci-label font-semibold">{{ i18n.t('my_modules.reports.wizard.second_step.form.footer.display_attachment_groups') }}</span>
          <div class="sci-toggle-checkbox-container">
            <input type="checkbox"
                  class="sci-toggle-checkbox"
                  v-model="displayAttachmentGroups"
                  data-e2e="e2e-TG-task-analyticalReport-generateReportModal-displayAttachmentGroups" />
            <span class="sci-toggle-checkbox-label"></span>
          </div>
        </div>
        <div v-if="displayAttachmentGroups" class="flex items-center gap-4">
          <span class="sci-label">{{ i18n.t('my_modules.reports.wizard.second_step.form.footer.add_group_numeration') }}</span>
          <div class="sci-toggle-checkbox-container">
            <input type="checkbox"
                  class="sci-toggle-checkbox"
                  v-model="addGroupNumeration"
                  data-e2e="e2e-TG-task-analyticalReport-generateReportModal-addGroupNumeration" />
            <span class="sci-toggle-checkbox-label"></span>
          </div>
        </div>
      </div>

      <div class="flex items-center gap-4 bg-sn-super-light-grey p-3 rounded">
        <span class="sci-label font-semibold">{{ i18n.t('my_modules.reports.wizard.second_step.form.footer.blank_page_after_group') }}</span>
        <div class="sci-toggle-checkbox-container">
          <input type="checkbox"
                class="sci-toggle-checkbox"
                v-model="addBlankPageAfterGroup"
                data-e2e="e2e-TG-task-analyticalReport-generateReportModal-addBlankPageAfterGroup" />
          <span class="sci-toggle-checkbox-label"></span>
        </div>
      </div>
    </div>
  </div>
  <div class="modal-footer">
    <button class="btn btn-secondary focus:border-sn-blue-hover" @click="$emit('close')" :disabled="submitting">
      {{ i18n.t('my_modules.reports.wizard.actions.cancel') }}
    </button>
    <button
      class="btn btn-primary focus:bg-sn-blue-hover"
      @click="setUp"
      :disabled="!validHeader || submitting"
      data-e2e="e2e-BT-task-analyticalReport-generateReportModal-generate"
    >
      {{ i18n.t('my_modules.reports.generate_button') }}
    </button>
  </div>
</template>

<script>

import axios from '../../../packs/custom_axios.js';
import {
  my_module_my_module_reports_path,
} from '../../../routes.js'


export default {
  name: 'AttachmentInformation',
  emits: ['next', 'back', 'close'],
  props: {
    params: {
      type: Object,
      required: true
    },
    wizardComponent: {
      type: Object,
      required: true
    }
  },
  data() {
    return {
      header: '',
      displayAttachmentReferences: false,
      addReferencePageNumbers: false,
      displayAttachmentGroups: false,
      addGroupNumeration: false,
      addBlankPageAfterGroup: false,
      submitting: false
    }
  },
  watch: {
    displayAttachmentReferences(value) {
      this.addReferencePageNumbers = value;
    },
    displayAttachmentGroups(value) {
      this.addGroupNumeration = value;
    }
  },
  computed: {
    validHeader() {
      return this.validHeaderTextLengthLimit && this.validHeaderLineLengthLimit;
    },
    validHeaderTextLengthLimit() {
      return this.header.length <= GLOBAL_CONSTANTS.MY_MODULE_REPORT_HEADER_MAX_LENGTH;
    },
    validHeaderLineLengthLimit() {
      return this.header.split('\n').length <= GLOBAL_CONSTANTS.MY_MODULE_REPORT_HEADER_MAX_LINES;
    },
    headerFieldErrors() {
      if (!this.validHeaderTextLengthLimit) {
        return this.i18n.t('my_modules.reports.wizard.second_step.form.header.error_size');
      } else if (!this.validHeaderLineLengthLimit) {
        return this.i18n.t('my_modules.reports.wizard.second_step.form.header.error_rows');
      }

      return '';
    }
  },
  methods: {
    setUp() {
      this.submitting = true;

      const reportTemplateParams = {
        ...this.params,
        header: this.header,
        display_attachment_references: this.displayAttachmentReferences,
        add_reference_page_numbers: this.displayAttachmentReferences && this.addReferencePageNumbers,
        display_attachment_groups: this.displayAttachmentGroups,
        add_group_numeration: this.displayAttachmentGroups && this.addGroupNumeration,
        add_blank_page_after_group: this.addBlankPageAfterGroup
      }

      this.wizardComponent.$emit('reportStatus', reportTemplateParams.report_template_id, true);

      axios.post(my_module_my_module_reports_path(reportTemplateParams.myModuleId), reportTemplateParams).then(() => {
        this.submitting = false;
        this.$emit('close');
      }).catch(() => {
        this.wizardComponent.$emit('reportStatus', reportTemplateParams.report_template_id, false);
        this.submitting = false;
        HelperModule.flashAlertMsg(this.i18n.t('general.error'), 'danger');
      });
    }
  }
};
</script>
