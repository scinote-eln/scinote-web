import TurbolinksAdapter from 'vue-turbolinks';
import Vue from 'vue/dist/vue.esm';
import RepositorySearchContainer from '../../vue/repository_search/container.vue';

Vue.use(TurbolinksAdapter);
Vue.prototype.i18n = window.I18n;

// register click-ouside directive to detect when inputs loss focus
let handleOutsideClick;
Vue.directive('click-outside', {
  bind(el, binding, vnode) {
    handleOutsideClick = (e) => {
      e.stopPropagation();

      const { handler, exclude } = binding.value;
      let clickedOnExcludedEl = false;
      exclude.forEach(refName => {
        if (!clickedOnExcludedEl) {
          const excludedEl = vnode.context.$refs[refName];
          clickedOnExcludedEl = excludedEl?.contains(e.target);
        }
      });

      if (!el.contains(e.target) && !clickedOnExcludedEl) {
        vnode.context[handler]();
      }
    };

    document.addEventListener('click', handleOutsideClick);
    document.addEventListener('touchstart', handleOutsideClick);
  },
  unbind() {
    document.removeEventListener('click', handleOutsideClick);
    document.removeEventListener('touchstart', handleOutsideClick);
  }
});

window.initRepositorySearch = () => {
  window.RepositorySearchComponent = new Vue({
    el: '#inventorySearchComponent',
    name: 'RepositorySearchComponent',
    components: {
      'repository_search_container': RepositorySearchContainer
    }
  });
}
