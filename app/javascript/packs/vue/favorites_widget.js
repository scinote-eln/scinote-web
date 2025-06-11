import { createApp } from 'vue/dist/vue.esm-bundler.js';
import FavoritesWidget from '../../vue/favorites/widget.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

const app = createApp();
app.component('FavoritesWidget', FavoritesWidget);
app.config.globalProperties.i18n = window.I18n;
window.favoritesWidget = mountWithTurbolinks(app, '#favoritesWidget');
