<template>
  <InfoModal ref="modal"
    :startHidden="true"
    :infoParams="infoParams"
    :title="steps[activeStep].title"
    :subtitle="steps[activeStep].subtitle"
    :helpText="steps[activeStep].helpText"
    >
    <component
      :key="steps[activeStep].id"
      :is="steps[activeStep].component"
      @step:next="proceedToNextStep"
      @step:back="goBackToPrevStep"
      :stepProps="steps[activeStep].stepData"
    />
  </InfoModal>
</template>

<script>
/* global HelperModule */

import { shallowRef } from 'vue';
import InfoModal from '../../shared/info_modal.vue';
import FirstStep from './import/first_step.vue';
import SecondStep from './import/second_step.vue';

export default {
  name: 'ImportRepositoryModal',
  components: { InfoModal, FirstStep, SecondStep },
  props: {
    repositoryUrl: String,
    required: true
  },
  data() {
    return {
      activeStep: 0,
      repositoryData: null,
      steps: [
        {
          id: this.i18n.t('repositories.import_records.steps.step1.id'),
          icon: this.i18n.t('repositories.import_records.steps.step1.icon'),
          label: this.i18n.t('repositories.import_records.steps.step1.label'),
          title: this.i18n.t('repositories.import_records.steps.step1.title'),
          subtitle: this.i18n.t('repositories.import_records.steps.step1.subtitle'),
          helpText: this.i18n.t('repositories.import_records.steps.step1.helpText'),
          component: shallowRef(FirstStep),
          stepData: null
        },
        {
          id: this.i18n.t('repositories.import_records.steps.step2.id'),
          icon: this.i18n.t('repositories.import_records.steps.step2.icon'),
          label: this.i18n.t('repositories.import_records.steps.step2.label'),
          title: this.i18n.t('repositories.import_records.steps.step2.title'),
          subtitle: this.i18n.t('repositories.import_records.steps.step2.subtitle'),
          component: shallowRef(SecondStep),
          stepData: null
        }
      ],
      infoParams: {
        title: this.i18n.t('repositories.import_records.info_sidebar.title'),
        elements: [
          {
            id: this.i18n.t('repositories.import_records.info_sidebar.elements.element0.id'),
            icon: this.i18n.t('repositories.import_records.info_sidebar.elements.element0.icon'),
            label: this.i18n.t('repositories.import_records.info_sidebar.elements.element0.label'),
            subtext: this.i18n.t('repositories.import_records.info_sidebar.elements.element0.subtext')
          },
          {
            id: this.i18n.t('repositories.import_records.info_sidebar.elements.element1.id'),
            icon: this.i18n.t('repositories.import_records.info_sidebar.elements.element1.icon'),
            label: this.i18n.t('repositories.import_records.info_sidebar.elements.element1.label'),
            subtext: this.i18n.t('repositories.import_records.info_sidebar.elements.element1.subtext')
          },
          {
            id: this.i18n.t('repositories.import_records.info_sidebar.elements.element2.id'),
            icon: this.i18n.t('repositories.import_records.info_sidebar.elements.element2.icon'),
            label: this.i18n.t('repositories.import_records.info_sidebar.elements.element2.label'),
            subtext: this.i18n.t('repositories.import_records.info_sidebar.elements.element2.subtext')
          },
          {
            id: this.i18n.t('repositories.import_records.info_sidebar.elements.element3.id'),
            icon: this.i18n.t('repositories.import_records.info_sidebar.elements.element3.icon'),
            label: this.i18n.t('repositories.import_records.info_sidebar.elements.element3.label'),
            subtext: this.i18n.t('repositories.import_records.info_sidebar.elements.element3.subtext')
          },
          {
            id: this.i18n.t('repositories.import_records.info_sidebar.elements.element4.id'),
            icon: this.i18n.t('repositories.import_records.info_sidebar.elements.element4.icon'),
            label: this.i18n.t('repositories.import_records.info_sidebar.elements.element4.label'),
            subtext: this.i18n.t('repositories.import_records.info_sidebar.elements.element4.subtext'),
            linkTo: this.i18n.t('repositories.import_records.info_sidebar.elements.element4.linkTo')
          }
        ]
      }
    };
  },
  created() {
    window.importRepositoryModalComponent = this;
  },
  methods: {
    open() {
      this.$refs.modal.open();
    },
    proceedToNextStep(data) {
      this.steps[this.activeStep + 1].stepData = data;
      this.activeStep += 1;
    },
    goBackToPrevStep() {
      this.activeStep -= 1;
    }
  }
};
</script>
