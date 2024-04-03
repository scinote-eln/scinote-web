/* global I18n dropdownSelector */

import { createApp } from 'vue/dist/vue.esm-bundler.js';
import TagsModal from '../../../vue/my_modules/modals/tags.vue';
import { mountWithTurbolinks } from '../helpers/turbolinks.js';

window.initTagsModalComponent = (id) => {
  const app = createApp({
    data() {
      return {
        tagsModalOpen: false
      };
    },
    mounted() {
      $(this.$refs.tagsModal).data('tagsModal', this);
    },
    methods: {
      open() {
        this.tagsModalOpen = true;
      },
      close() {
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
            url: $('#canvas-container').attr('data-module-tags-url'),
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
  mountWithTurbolinks(app, id);
};

const tagsModalContainers = document.querySelectorAll('.vue-tags-modal:not(.initialized)');
tagsModalContainers.forEach((container) => {
  $(container).addClass('initialized');
  window.initTagsModalComponent(`#${container.id}`);
});
