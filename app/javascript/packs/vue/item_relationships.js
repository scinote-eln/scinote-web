/* global notTurbolinksPreview */

import TurbolinksAdapter from 'vue-turbolinks';
import Vue from 'vue/dist/vue.esm';
import ItemRelationshipsModal from '../../vue/item_relationships/ItemRelationshipsModal.vue';

Vue.use(TurbolinksAdapter);
Vue.prototype.i18n = window.I18n;

function initItemRelationshipsModal() {
  new Vue({
    el: '#itemRelationshipsModalWrapper',
    components: {
      ItemRelationshipsModal
    }
  });
}

initItemRelationshipsModal();
