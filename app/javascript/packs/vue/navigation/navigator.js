
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
        reloadCurrentLevel: false,
        reloadChildrenLevel: false
      }
    },
    created() {
      $(document).on('inlineEditing:fieldUpdated', '.title-row .inline-editing-container', () => {
        this.reloadCurrentLevel = true;
      })
    },
    methods: {
      toggleNavigatorState: function(newNavigatorState) {
        let stateUrl = $('#sciNavigationNavigatorContainer').attr('data-navigator-state-url');
        $.post(stateUrl, {state: newNavigatorState ? 'collapsed' : 'open'});
        $('.sci--layout').attr('data-navigator-collapsed', newNavigatorState);
        $('body').toggleClass('navigator-collapsed', newNavigatorState);

        // refresh action toolbar width on navigator toggle, take into account transition time of .4s
        if (window.actionToolbarComponent) setTimeout(window.actionToolbarComponent.setWidth, 401);
      }
    },
    watch: {
      reloadCurrentLevel: function () {
        if (this.reloadCurrentLevel) {
          this.$nextTick(() => {
            this.reloadCurrentLevel = false;
          });
        }
      },
      reloadChildrenLevel: function () {
        if (this.reloadChildrenLevel) {
          this.$nextTick(() => {
            this.reloadChildrenLevel = false;
          });
        }
      }
    }
  });

  window.navigatorContainer = navigator
});
