<template>
  <InfoModal ref="modal"
    :startHidden="true"
    :infoParams="infoParams"
    :title="steps[activeStep].title"
    :helpText="steps[activeStep].helpText">
    <component
      :is="steps[activeStep].component"
      @step:next="proceedToNext"
      @step:back="activeStep -= 1"
      :stepData="stepData"
    />
  </InfoModal>
</template>

<script>
/* global HelperModule */

import { shallowRef } from 'vue';
import InfoModal from '../../shared/info_modal.vue';
import FirstStep from './import/first_step.vue';

export default {
  name: 'ImportRepositoryModal',
  components: { InfoModal, FirstStep },
  props: {
    repositoryUrl: String, required: true
  },
  data() {
    return {
      activeStep: 0,
      steps: [
        {
          id: I18n.t('repositories.import_records.steps.step0.id'),
          icon: I18n.t('repositories.import_records.steps.step0.icon'),
          label: I18n.t('repositories.import_records.steps.step0.label'),
          title: I18n.t('repositories.import_records.steps.step0.title'),
          helpText: I18n.t('repositories.import_records.steps.step0.helpText'),
          component: shallowRef(FirstStep)
        }
      ],
      infoParams: {
        title: I18n.t('repositories.import_records.info_sidebar.title'),
        elements: [
          {
            id: I18n.t('repositories.import_records.info_sidebar.elements.element0.id'),
            icon: I18n.t('repositories.import_records.info_sidebar.elements.element0.icon'),
            label: I18n.t('repositories.import_records.info_sidebar.elements.element0.label'),
            subtext: I18n.t('repositories.import_records.info_sidebar.elements.element0.subtext')
          },
          {
            id: I18n.t('repositories.import_records.info_sidebar.elements.element1.id'),
            icon: I18n.t('repositories.import_records.info_sidebar.elements.element1.icon'),
            label: I18n.t('repositories.import_records.info_sidebar.elements.element1.label'),
            subtext: I18n.t('repositories.import_records.info_sidebar.elements.element1.subtext')
          },
          {
            id: I18n.t('repositories.import_records.info_sidebar.elements.element2.id'),
            icon: I18n.t('repositories.import_records.info_sidebar.elements.element2.icon'),
            label: I18n.t('repositories.import_records.info_sidebar.elements.element2.label'),
            subtext: I18n.t('repositories.import_records.info_sidebar.elements.element2.subtext')
          },
          {
            id: I18n.t('repositories.import_records.info_sidebar.elements.element3.id'),
            icon: I18n.t('repositories.import_records.info_sidebar.elements.element3.icon'),
            label: I18n.t('repositories.import_records.info_sidebar.elements.element3.label'),
            subtext: I18n.t('repositories.import_records.info_sidebar.elements.element3.subtext')
          },
          {
            id: I18n.t('repositories.import_records.info_sidebar.elements.element4.id'),
            icon: I18n.t('repositories.import_records.info_sidebar.elements.element4.icon'),
            label: I18n.t('repositories.import_records.info_sidebar.elements.element4.label'),
            subtext: I18n.t('repositories.import_records.info_sidebar.elements.element4.subtext'),
            linkTo: I18n.t('repositories.import_records.info_sidebar.elements.element4.linkTo')
          }
        ]
      },
      stepData: null
    };
  },
  watch: {
    activeStep(newVal, oldVal) {
      console.log(`${oldVal} -> ${newVal}`);
    },
    stepData(newVal, oldVal) {
      console.log(`${oldVal} -> ${newVal}`);
    }
  },
  created() {
    window.importRepositoryModalComponent = this;
  },
  mounted() {
  },
  methods: {
    open() {
      this.$refs.modal.open();
    },
    proceedToNext(data) {
      console.log('incoming data', data);
      this.stepData = data;
      this.activeStep += 1;
    }
  }
};
</script>
