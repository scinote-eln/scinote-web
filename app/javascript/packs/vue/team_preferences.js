import { createApp } from "vue/dist/vue.esm-bundler.js";
import TeamPreferences from "../../vue/team_preferences/container.vue";
import InventorySettings from "../../vue/team_preferences/inventory_settings.vue";
import { mountWithTurbolinks } from "./helpers/turbolinks.js";

const app = createApp({});
app.component("TeamPreferences", TeamPreferences);
app.component("InventorySettings", InventorySettings);
app.config.globalProperties.i18n = window.I18n;
mountWithTurbolinks(app, "#team_preferences");
