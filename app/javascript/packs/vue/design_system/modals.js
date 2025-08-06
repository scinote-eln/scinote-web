import { createApp } from 'vue/dist/vue.esm-bundler.js';
import { shallowRef } from 'vue';

import WizardModal from '../../../vue/shared/wizard_modal.vue';
import InfoModal from '../../../vue/shared/info_modal.vue';
import BasicModal from '../../../vue/design_elements/basic_modal.vue';
import Step1 from './wizard_steps/step_1.vue';
import Step2 from './wizard_steps/step_2.vue';
import Step3 from './wizard_steps/step_3.vue';
import { mountWithTurbolinks } from '../helpers/turbolinks.js';

const app = createApp({
  components: {
    Step1,
    Step2,
    Step3,
    WizardModal,
    InfoModal,
    BasicModal
  },
  methods: {
    fireAlert() {
      alert('Fired!');
    }
  },
  data() {
    return {
      showBasicModal: false,
      // Wizard modal
      wizardConfig: {
        title: 'Wizard steps',
        subtitle: 'Wizard subtitle description',
        steps: [
          {
            id: 'step1',
            icon: 'sn-icon-open',
            label: 'Step 1',
            component: shallowRef(Step1)
          },
          {
            id: 'step2',
            icon: 'sn-icon-edit',
            label: 'Step 2',
            component: shallowRef(Step2)
          },
          {
            id: 'step3',
            icon: 'sn-icon-inventory',
            label: 'Step 3',
            component: shallowRef(Step3)
          }
        ]
      },
      wizardParams: {
        text: 'Some text'
      },
      showWizard: false,

      // Info modal
      infoParams: {
        title: 'Guide for updating the inventory',
        elements: [
          {
            id: 'el1',
            icon: 'sn-icon-export',
            label: 'Export inventory',
            subtext: "Before making edits, we advise you to export the latest inventory information. If you're only adding new items, consider exporting empty inventory."
          },
          {
            id: 'el2',
            icon: 'sn-icon-edit',
            label: 'Edit your data',
            subtext: 'Make sure to include header names in first row, followed by item data.'
          },
          {
            id: 'el3',
            icon: 'sn-icon-import',
            label: 'Import new or update items',
            subtext: 'Upload your data using .xlsx, .csv or .txt files.'
          },
          {
            id: 'el4',
            icon: 'sn-icon-tables',
            label: 'Merge your data',
            subtext: 'Complete the process by merging the columns you want to update.'
          },
          {
            id: 'el5',
            icon: 'sn-icon-open',
            label: 'Learn more',
            linkTo: 'https://knowledgebase.scinote.net/en/knowledge/how-to-add-items-to-an-inventory'
          }
        ]
      },
      showInfo: false
    };
  }
});
app.component('WizardModal', WizardModal);
app.component('InfoModal', InfoModal);
app.config.globalProperties.i18n = window.I18n;
mountWithTurbolinks(app, '#modals');
