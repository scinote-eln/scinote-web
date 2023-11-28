import { createApp } from 'vue/dist/vue.esm-bundler.js';
import SelectDropdown from '../../../vue/shared/select_dropdown.vue';
import PerfectScrollbar from 'vue3-perfect-scrollbar';
import { mountWithTurbolinks } from '../helpers/turbolinks.js';

const app = createApp({
  data() {
    return {
      size: 'md',
    }
  },
  computed: {
    simpleOptions() {
      return [
        ['1', 'One', { icon: 'sn-icon-edit' }],
        ['2', 'Two', { icon: 'sn-icon-drag' }],
        ['3', 'Three', { icon: 'sn-icon-delete' }],
        ['4', 'Four', { icon: 'sn-icon-visibility-show' }],
        ['5', 'Five', { icon: 'sn-icon-edit' }],
        ['6', 'Six', { icon: 'sn-icon-locked-task' }],
        ['7', 'Seven', { icon: 'sn-icon-drag' }],
        ['8', 'Eight', { icon: 'sn-icon-delete' }],
        ['9', 'Nine', { icon: 'sn-icon-edit' }],
        ['10', 'Ten', { icon: 'sn-icon-close' }],
      ];
    },
    longOptions() {
      return [
        ['1', 'Very long long long option and label to test responsivness'],
        ['2', 'Two'],
        ['3', 'Three'],
        ['4', 'Four'],
      ]
    },
    renderer() {
      return (option) => {
        return `<span class="flex items-center gap-2"><i class="sn-icon ${option[2].icon}"></i> ${option[1]}</span>`;
      }
    }
  },
});
app.component('SelectDropdown', SelectDropdown);
app.config.globalProperties.i18n = window.I18n;
app.use(PerfectScrollbar);
mountWithTurbolinks(app, '#selects');
