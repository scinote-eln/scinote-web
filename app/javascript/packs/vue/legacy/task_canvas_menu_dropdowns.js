import { createApp } from 'vue/dist/vue.esm-bundler.js';
import TaskCanvasMenuDropdowns from '../../../vue/my_modules/state_menu_dropdowns.vue';
import { mountWithTurbolinks } from '../helpers/turbolinks.js';

const app = createApp({});
app.component('TaskCanvasMenuDropdowns', TaskCanvasMenuDropdowns);
mountWithTurbolinks(app, '#taskCanvasDropdowns');
