import PerfectScrollbar from 'vue3-perfect-scrollbar';
import { createApp } from 'vue/dist/vue.esm-bundler.js';
import 'vue3-perfect-scrollbar/dist/vue3-perfect-scrollbar.css';
import NavigatorContainer from '../../../vue/navigation/navigator.vue';

function addNavigationNavigatorContainer() {
  const app = createApp({
    data() {
      return {
        reloadCurrentLevel: false,
        reloadChildrenLevel: false,
        reloadExpandedChildrenLevel: false
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
        $.post(stateUrl, { state: newNavigatorState ? 'collapsed' : 'open' });
        $('.sci--layout').attr('data-navigator-collapsed', newNavigatorState);
        $('body').toggleClass('navigator-collapsed', newNavigatorState);

        // refresh action toolbar width on navigator toggle, take into account transition time of .4s
        if (window.actionToolbarComponent) setTimeout(window.actionToolbarComponent.setWidth, 401);
        // set navigator state in table.
        if (window.resetGridColumns) window.resetGridColumns(newNavigatorState);
      },
      reloadNavigator(withExpandedChildren = false) {
        this.reloadCurrentLevel = true;
        if (withExpandedChildren) {
          this.reloadExpandedChildrenLevel = true;
        } else {
          this.reloadChildrenLevel = true;
        }
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
      },
      reloadExpandedChildrenLevel() {
        if (this.reloadExpandedChildrenLevel) {
          this.$nextTick(() => {
            this.reloadExpandedChildrenLevel = false;
          });
        }
      }
    }
  });
  app.component('NavigatorContainer', NavigatorContainer);
  app.use(PerfectScrollbar);
  app.config.globalProperties.i18n = window.I18n;
  window.navigatorContainer = app.mount('#sciNavigationNavigatorContainer');
}

if (document.readyState !== 'loading') {
  addNavigationNavigatorContainer();
} else {
  window.addEventListener('DOMContentLoaded', () => {
    addNavigationNavigatorContainer();
  });
}
