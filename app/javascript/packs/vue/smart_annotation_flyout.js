import { createApp } from 'vue/dist/vue.esm-bundler.js';
import SmartAnnotationFlyout from '../../vue/shared/smart_annotation_flyout.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

const app = createApp({});
app.component('smart-annotation-flyout', SmartAnnotationFlyout);
app.config.globalProperties.i18n = window.I18n;

mountWithTurbolinks(app, '#smartAnnotationFlyoutContainer');
