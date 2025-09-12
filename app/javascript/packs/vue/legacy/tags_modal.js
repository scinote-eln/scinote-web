/* global I18n dropdownSelector */

import { createApp } from 'vue/dist/vue.esm-bundler.js';
import TagsModal from '../../../vue/shared/tags_modal.vue';
import { mountWithTurbolinks } from '../helpers/turbolinks.js';

const app = createApp({
  data() {
    return {
      myModuleParams: null,
      myModuleUrl: null,
      tagsModalOpen: false,
      tagDeleted: false
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
      this.myModuleUrl = myModuleUrl;
      $.ajax({
        url: myModuleUrl,
        type: 'GET',
        dataType: 'json',
        success: (data) => {
          this.myModuleParams = data.data;
          this.tagsModalOpen = true;
        }
      });
    },
    close() {
      this.myModuleParams = null;
      this.myModuleUrl = null;
      this.tagsModalOpen = false;

      if ($('#canvas-container').length && this.tagDeleted) {
        window.location.reload();
      }
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
          url: this.myModuleUrl,
          type: 'GET',
          dataType: 'json',
          success(data) {
            $(`div.panel[data-module-id='${data.data.id}']`)
              .find('.edit-tags-link')
              .html(data.data.attributes.tags_html);
          }
        });
      }

      this.close();
    }
  }
});
app.component('tags-modal', TagsModal);
app.config.globalProperties.i18n = window.I18n;
mountWithTurbolinks(app, '#tagsModalContainer');
