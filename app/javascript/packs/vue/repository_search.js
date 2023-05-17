import TurbolinksAdapter from 'vue-turbolinks';
import Vue from 'vue/dist/vue.esm';
import RepositorySearchContainer from '../../vue/repository_search/container.vue';

Vue.use(TurbolinksAdapter);
Vue.prototype.i18n = window.I18n;

window.initRepositorySearch = () => {
  window.RepositorySearchComponent = new Vue({
    el: '#inventorySearchComponent',
    name: 'RepositorySearchComponent',
    components: {
      'repository_search_container': RepositorySearchContainer
    }
  });
}
