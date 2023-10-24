/* global notTurbolinksPreview */

import TurbolinksAdapter from 'vue-turbolinks';
import Vue from 'vue/dist/vue.esm';
import 'vue2-perfect-scrollbar/dist/vue2-perfect-scrollbar.css';
import PerfectScrollbar from 'vue2-perfect-scrollbar';
import RepositoryItemSidebar from '../../vue/repository_item_sidebar/RepositoryItemSidebar.vue';
import outsideClick from './directives/outside_click';

Vue.use(TurbolinksAdapter);
Vue.directive('click-outside', outsideClick);
Vue.use(PerfectScrollbar);
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
