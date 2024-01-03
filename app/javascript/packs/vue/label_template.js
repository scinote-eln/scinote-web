import { createApp } from 'vue/dist/vue.esm-bundler.js';
import LabelTemplateContainer from '../../vue/label_template/container.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

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
  app.config.globalProperties.i18n = window.I18n;
  mountWithTurbolinks(app, '#labelTemplateContainer');
};

initLabelTemplateComponent();
