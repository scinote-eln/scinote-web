/* global I18n dropdownSelector */

import { createApp } from 'vue/dist/vue.esm-bundler.js';
import TagsModal from '../../../vue/my_modules/modals/tags.vue';
import { mountWithTurbolinks } from '../helpers/turbolinks.js';

const app = createApp({
  data() {
    return {
      myModuleParams: null,
      tagsModalOpen: false,
      tagsUrl: null
    };
  },
  mounted() {
    window.tagsModal = this;
  },
  beforeUnmount() {
    delete window.tagsModal;
  },
  methods: {
    open(myModuleUrl) {
      $.ajax({
        url: myModuleUrl,
        type: 'GET',
        dataType: 'json',
        success: (data) => {
          this.myModuleParams = { ...data.data.attributes, id: data.data.id };
          this.tagsModalOpen = true;
        }
      });
    },
    close() {
      this.myModuleParams = null;
      this.tagsModalOpen = false;
    },
    syncTags(tags) {
      // My module page
      if ($('#module-tags-selector').length) {
        const assignedTags = tags.filter((i) => i.assigned).map((i) => (
          {
            value: i.id,
            label: i.attributes.name,
            params: {
              color: i.attributes.color
            }
          }
        ));
        dropdownSelector.setData('#module-tags-selector', assignedTags);
      }

      // Canvas
      if ($('#canvas-container').length) {
        $.ajax({
          url: this.tagsUrl,
          type: 'GET',
          dataType: 'json',
          success(data) {
            $.each(data.my_modules, (index, myModule) => {
              $(`div.panel[data-module-id='${myModule.id}']`)
                .find('.edit-tags-link')
                .html(myModule.tags_html);
            });
          }
        });
      }
    }
  }
});
app.component('tags-modal', TagsModal);
app.config.globalProperties.i18n = window.I18n;
mountWithTurbolinks(app, '#tagsModalContainer');
