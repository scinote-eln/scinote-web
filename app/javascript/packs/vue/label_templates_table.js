import TurbolinksAdapter from 'vue-turbolinks';
import Vue from 'vue/dist/vue.esm';
import PerfectScrollbar from 'vue2-perfect-scrollbar';
import LabelTemplatesTable from '../../vue/label_template/table.vue';

Vue.use(TurbolinksAdapter);
Vue.use(PerfectScrollbar);
Vue.prototype.i18n = window.I18n;

window.initLabelTemplatesTableComponent = () => {
  new Vue({
    el: '#labelTemplatesTable',
    components: {
      'label-templates-table': LabelTemplatesTable,
    },
  });
};

initLabelTemplatesTableComponent();
