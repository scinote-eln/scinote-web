import axios from '../../../packs/custom_axios';

import {
  user_setting_path
} from '../../../routes.js';

export default {
  data() {
    return {
      stepCollapsed: false
    };
  },
  methods: {
    checkStepsState() {
      this.stepCollapsed = this.$refs.steps.every((step) => step.isCollapsed);
    },
    collapseSteps() {
      $('.step-container .collapse').collapse('hide');
      this.updateStepStateSettings(true);
      this.$refs.steps.forEach((step) => step.isCollapsed = true);
      this.stepCollapsed = true;
    },
    expandSteps() {
      $('.step-container .collapse').collapse('show');
      this.updateStepStateSettings(false);
      this.$refs.steps.forEach((step) => step.isCollapsed = false);
      this.stepCollapsed = false;
    },
    updateStepStateSettings(newState) {
      const updatedData = this.steps.reduce((acc, currentStep) => {
        acc[currentStep.id] = newState;
        return acc;
      }, {});

      this.steps = this.steps.map((step) => ({
        ...step,
        attributes: {
          ...step.attributes,
          collapsed: newState
        }
      }));

      const settings = {
        value: updatedData
      };

      axios.put(user_setting_path('task_step_states'), {user_setting: settings});
    }
  }
};
