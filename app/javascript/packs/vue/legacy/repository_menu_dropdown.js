import { createApp } from 'vue/dist/vue.esm-bundler.js';
import RepositoryStateMenu from '../../../vue/repository/state_menu.vue';
import { mountWithTurbolinks } from '../helpers/turbolinks.js';

window.initRepositoryStateMenu = () => {
  const app = createApp({});
  app.component('RepositoryStateMenu', RepositoryStateMenu);
  mountWithTurbolinks(app, '#repositoryStateMenu');
};
