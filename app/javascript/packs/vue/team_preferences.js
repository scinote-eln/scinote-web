import { createApp } from "vue/dist/vue.esm-bundler.js";
import TeamPreferences from "../../vue/team_preferences/container.vue";
import { mountWithTurbolinks } from "./helpers/turbolinks.js";

const app = createApp({});
app.component("TeamPreferences", TeamPreferences);
app.config.globalProperties.i18n = window.I18n;
mountWithTurbolinks(app, "#team_preferences");
