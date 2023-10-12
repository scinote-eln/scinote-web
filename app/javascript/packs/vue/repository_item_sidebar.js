/* global notTurbolinksPreview */

import TurbolinksAdapter from 'vue-turbolinks';
import ScrollSpy from 'vue2-scrollspy';
import Vue from 'vue/dist/vue.esm';
import RepositoryItemSidebar from '../../vue/repository_item_sidebar/RepositoryItemSidebar.vue';

Vue.use(TurbolinksAdapter);
Vue.use(ScrollSpy);
Vue.prototype.i18n = window.I18n;

function initRepositoryItemSidebar() {
  new Vue({
    el: '#repositoryItemSidebar',
    components: {
      RepositoryItemSidebar
    }
  });
}

initRepositoryItemSidebar();
