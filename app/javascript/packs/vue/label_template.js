import TurbolinksAdapter from 'vue-turbolinks';
import Vue from 'vue/dist/vue.esm';
import LabelTemplateContainer from '../../vue/label_template/container.vue';

Vue.use(TurbolinksAdapter);
Vue.prototype.i18n = window.I18n;

window.initLabelTemplateComponent = () => {

  new Vue({
    el: '#labelTemplateContainer',
    components: {
      'label-template-container': LabelTemplateContainer
    },
    data() {
      return {
        labelTemplateUrl: $('#labelTemplateContainer').data('label-template-url'),
        labelTemplatesUrl: $('#labelTemplateContainer').data('label-templates-url'),
        previewUrl: $('#labelTemplateContainer').data('preview-url'),
        newLabel: $('#labelTemplateContainer').data('new-label')
      };
    }
  });
};

initLabelTemplateComponent();
