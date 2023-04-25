
import Vue from 'vue/dist/vue.esm';
import NavigatorContainer from '../../../vue/navigation/navigator.vue';
import PerfectScrollbar from 'vue2-perfect-scrollbar';
import 'vue2-perfect-scrollbar/dist/vue2-perfect-scrollbar.css';

Vue.use(PerfectScrollbar);

Vue.prototype.i18n = window.I18n;

window.addEventListener('DOMContentLoaded', () => {
  let navigator = new Vue({
    el: '#sciNavigationNavigatorContainer',
    components: {
      'navigator-container': NavigatorContainer
    },
    data() {
      return {
        navigatorCollapsed: false,
      }
    },
    created() {
      this.navigatorCollapsed = $('.sci--layout').attr('data-navigator-collapsed');
    },
    watch: {
      navigatorCollapsed: function () {
        let stateUrl = $('#sciNavigationNavigatorContainer').attr('data-navigator-state-url');
        $('.sci--layout').attr('data-navigator-collapsed', this.navigatorCollapsed);
        $.post(stateUrl, {state: this.navigatorCollapsed ? 'collapsed' : 'open'});
      }
    }
  });

  window.navigatorContainer = navigator
});
