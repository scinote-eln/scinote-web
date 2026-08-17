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
    <div>
      <label class="sci-label">{{ i18n.t('my_modules.reports.wizard.second_step.form.header.label') }}</label>
      <div class="sci-input-container-v2 h-28" :class="{'error': !validHeader}" :data-error="headerFieldErrors" >
        <textarea v-model="header"
          class="sci-input-field"
          :placeholder="i18n.t('my_modules.reports.wizard.second_step.form.header.placeholder')"
        ></textarea>
      </div>
    </div>
    <div>
      <label class="sci-label">{{ i18n.t('my_modules.reports.wizard.second_step.form.footer.label') }}</label>
      <div class="sci-input-container-v2" :class="{'error': !validFooter}" :data-error="footerFieldErrors" >
        <input type="text" 
          v-model="footer"
          class="sci-input-field"
          :placeholder="i18n.t('my_modules.reports.wizard.second_step.form.footer.placeholder')"
        />
      </div>
    </div>
    <div class="flex items-center gap-2">
      <span class="sci-checkbox-container">
        <input type="checkbox" class="sci-checkbox" v-model="addNumarization" />
        <span class="sci-checkbox-label"></span>
      </span>
      <span class="sci-label">{{ i18n.t('my_modules.reports.wizard.second_step.form.numarization_checkbox') }}</span>
    </div>
     <div class="flex items-center gap-2">
      <span class="sci-checkbox-container">
        <input type="checkbox" class="sci-checkbox" v-model="addBlankPage" />
        <span class="sci-checkbox-label"></span>
      </span>
      <span class="sci-label">{{ i18n.t('my_modules.reports.wizard.second_step.form.blank_page_checkbox') }}</span>
    </div>
  </div>
  <div class="modal-footer">
    <button class="btn btn-secondary focus:border-sn-blue-hover" @click="$emit('close')" :disabled="submitting">
      {{ i18n.t('my_modules.reports.wizard.actions.cancel') }}
    </button>
    <button class="btn btn-primary focus:bg-sn-blue-hover" @click="setUp" :disabled="!validHeader || !validFooter || submitting">
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
      footer: '',
      addNumarization: false,
      addBlankPage: false,
      submitting: false
    }
  },
  computed: {
    validHeader() {
      return this.validHeaderTextLengthLimit && this.validHeaderLineLengthLimit;
    },
    validFooter() {
      return this.footer.length <= GLOBAL_CONSTANTS.MY_MODULE_REPORT_FOOTER_MAX_LENGTH;
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
      } else if(!this.validHeaderLineLengthLimit) {
        return this.i18n.t('my_modules.reports.wizard.second_step.form.header.error_rows');
      }

      return '';
    },
    footerFieldErrors() {
      if (!this.validFooter) {
        return this.i18n.t('my_modules.reports.wizard.second_step.form.footer.error_size');
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
        footer: this.footer,
        addNumarization: this.addNumarization,
        addBlankPage: this.addBlankPage
      }

      this.wizardComponent.$emit('reportStatus', reportTemplateParams.report_template_id, true);

      axios.post(my_module_my_module_reports_path(reportTemplateParams.myModuleId), reportTemplateParams).then((response) => {
        this.submitting = false;
        this.$emit('close');
      }).catch((error) => {
        this.wizardComponent.$emit('reportStatus', reportTemplateParams.report_template_id, false);
        this.submitting = false;
        HelperModule.flashAlertMsg(this.i18n.t('general.error'), 'danger');
      });
    }
  }
};
</script>
