<template>

  <WizardModal
    @close="close"
    @set-asset-groups="(params) => setAssetGroups(params)"
    :params="wizardParams"
    :config="wizardConfig"
  />
</template>

<script>
import { vOnClickOutside } from '@vueuse/components';
import { shallowRef } from 'vue';
import WizardModal from '../../shared/wizard_modal.vue'
import SelectAttachment from '../generate_report_wizard_steps/select_attachments_step.vue'
import AttachmentInformation from '../generate_report_wizard_steps/attachment_information_step.vue'
import modalMixin from '../../shared/modal_mixin';


export default {
  name: 'GenerateReportModal',
  directives: {
    'click-outside': vOnClickOutside
  },
  components: {
    WizardModal,
    SelectAttachment
  },
  mixins: [modalMixin],
  props: {
    templateId: null,
    myModuleId: null
  },
  data() {
    return {
      wizardConfig: {
        title: I18n.t('my_modules.reports.wizard.title'),
        subtitle: I18n.t('my_modules.reports.wizard.description'),
        steps: [
          {
            id: 'SelectAttachment',
            icon: 'sn-icon sn-icon-task-data-display',
            label: I18n.t('my_modules.reports.wizard.first_step.label'),
            description: I18n.t('my_modules.reports.wizard.first_step.description'),
            alwaysActive: true,
            component: shallowRef(SelectAttachment)
          },
          {
            id: 'AttachmentInformation',
            icon: 'sn-icon sn-icon-open',
            label: I18n.t('my_modules.reports.wizard.second_step.label'),
            description: I18n.t('my_modules.reports.wizard.second_step.description'),
            disableStepLine: true,
            alwaysActive: true,
            component: shallowRef(AttachmentInformation)
          },
          {
            id: 'AttachmentInformation',
            icon: 'sn-icon sn-icon-info',
            disableStepLine: true,
            alwaysActive: true,
            description: I18n.t('my_modules.reports.wizard.third_step.description')
          }
        ]
      },
      wizardParams: {
        asset_groups: [],
        myModuleId: this.myModuleId,
        report_template_id: this.templateId,
        header: '',
        display_attachment_references: false,
        add_reference_page_numbers: false,
        display_attachment_groups: false,
        add_group_numeration: false,
        add_blank_page_after_group: false
      }
    };
  },
  methods: {
    setAssetGroups(assetGroups) {
      this.wizardParams.asset_groups = assetGroups;
    }
  }
};
</script>
