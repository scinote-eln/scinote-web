import { createApp } from 'vue/dist/vue.esm-bundler.js';
import { shallowRef } from 'vue';

import WizardModal from '../../../vue/shared/wizard_modal.vue';
import Step1 from './wizard_steps/step_1.vue';
import Step2 from './wizard_steps/step_2.vue';
import Step3 from './wizard_steps/step_3.vue';
import { mountWithTurbolinks } from '../helpers/turbolinks.js';

const app = createApp({
  components: {
    Step1,
    Step2,
    Step3
  },
  methods: {
    fireAlert() {
      alert('Fired!');
    }
  },
  data() {
    return {
      wizardConfig: {
        title: 'Wizard steps',
        subtitle: 'Wizard subtitle description',
        steps: [
          {
            id: 'step1',
            icon: 'sn-icon sn-icon-open',
            label: 'Step 1',
            component: shallowRef(Step1)
          },
          {
            id: 'step2',
            icon: 'sn-icon sn-icon-edit',
            label: 'Step 2',
            component: shallowRef(Step2)
          },
          {
            id: 'step3',
            icon: 'sn-icon sn-icon-inventory',
            label: 'Step 3',
            component: shallowRef(Step3)
          }
        ]
      },
      wizardParams: {
        text: 'Some text'
      },
      showWizard: false
    };
  }
});
app.component('WizardModal', WizardModal);
app.config.globalProperties.i18n = window.I18n;
mountWithTurbolinks(app, '#modals');
