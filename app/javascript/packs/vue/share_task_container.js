import TurbolinksAdapter from 'vue-turbolinks';
import Vue from 'vue/dist/vue.esm';
import ShareLinkContainer from '../../vue/shareable_links/container.vue';
import 'vue2-perfect-scrollbar/dist/vue2-perfect-scrollbar.css';

Vue.use(TurbolinksAdapter);
Vue.prototype.i18n = window.I18n;

function initShareTaskComponent() {
  const container = $('.share-task-container');
  if (container.length) {
    window.ShareLinkContainer = new Vue({
      el: '.share-task-container',
      name: 'ShareTaskContainer',
      components: {
        'share-task-container': ShareLinkContainer
      },
      data() {
        return {
          disabled: container.data('shareable-button-disabled'),
          shared: container.data('my-module-shared'),
          urls: {
            shareableLinkUrl: container.data('shareable-object-url')
          }
        };
      }
    });
  }
}

initShareTaskComponent();
