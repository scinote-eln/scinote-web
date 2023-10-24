import TurbolinksAdapter from 'vue-turbolinks';
import { createApp } from 'vue/dist/vue.esm-bundler.js';
import LabelTemplateContainer from '../../vue/label_template/container.vue';

window.initLabelTemplateComponent = () => {
  const app = createApp({
    data() {
      return {
        labelTemplateUrl: $('#labelTemplateContainer').data('label-template-url'),
        labelTemplatesUrl: $('#labelTemplateContainer').data('label-templates-url'),
        previewUrl: $('#labelTemplateContainer').data('preview-url'),
        newLabel: $('#labelTemplateContainer').data('new-label')
      };
    }
  });
  app.component('LabelTemplateContainer', LabelTemplateContainer);
  app.use(TurbolinksAdapter);
  app.config.globalProperties.i18n = window.I18n;
  app.mount('#labelTemplateContainer');
};

initLabelTemplateComponent();
