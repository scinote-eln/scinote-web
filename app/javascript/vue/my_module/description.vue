<template>
  <div class="bg-white px-4 my-4 task-section">
    <div class="py-4 flex items-center gap-4">
      <i ref="openHandler"
        data-e2e="e2e-BT-task-notes-visibilityToggle"
        @click="toggleContainer"
        class="sn-icon sn-icon-right cursor-pointer">
      </i>
      <h2 class="my-0 flex items-center gap-1" data-e2e="e2e-TX-task-notes-title">
        {{ i18n.t('my_modules.notes.title') }}
      </h2>
    </div>
    <div ref="notesContainer" data-e2e="e2e-IF-task-notes" class="my-module-description overflow-hidden transition-all pr-4 pl-9" style="max-height: 0px;">
      <div class="min-h-[2.25rem] w-full inline-block mb-4 relative group/text_container content__text-body"
        :class="{ 'edit': inEditMode, 'component__element--locked': !canEdit }"
        @keyup.enter="enableEditMode($event)" tabindex="0">
        <Tinymce
          v-if="canEdit"
          :value="myModule.attributes.description"
          :value_html="myModule.attributes.description_view"
          :placeholder="i18n.t('my_modules.notes.empty_description_edit_label')"
          :inEditMode="inEditMode"
          :updateUrl="updateUrl()"
          objectType="MyModule"
          :objectId="parseInt(myModule.id, 10)"
          :fieldName="'my_module[description]'"
          :lastUpdated="myModule.attributes.updated_at_unix"
          :assignableMyModuleId="parseInt(myModule.id, 10)"
          :characterLimit="1000000"
          @update="reloadMyModule"
          @editingDisabled="disableEditMode"
          @editingEnabled="enableEditMode"
          @input="recalculateContainerSize(60)"
        />
        <div class="view-text-element mb-4 numerical-nested-list" v-else-if="myModule.attributes.description_view" v-html="wrappedTables"></div>
        <div v-else class="text-sn-grey mb-4">
          {{ i18n.t("my_modules.notes.no_description") }}
        </div>
      </div>
    </div>
  </div>
</template>


<script>
import Tinymce from '../shared/tinymce.vue';
import {
  my_module_path
} from '../../routes.js';

export default {
  name: 'MyModuleDescription',
  props: {
    myModule: {
      type: Object,
      required: true
    }
  },
  components: {
    Tinymce
  },
  data() {
    return {
      sectionOpened: false,
      inEditMode: false,
      resizeObserver: null
    };
  },
  computed: {
    canEdit() {
      return this.myModule.attributes.permissions.manage_description;
    },
    wrappedTables() {
      return window.wrapTables(this.myModule.attributes.description_view);
    }
  },
  mounted() {
    this.initResizeObserver();
    if (this.myModule.attributes.description_view) {
      this.sectionOpened = true;
      this.recalculateContainerSize(60);
    }
  },
  beforeUnmount() {
    if (this.resizeObserver) {
      this.resizeObserver.disconnect();
    }
  },
  methods: {
    initResizeObserver() {
      this.resizeObserver = new ResizeObserver((_entries) => {
        if (this.sectionOpened && this.inEditMode) {
          this.recalculateContainerSize(60);
        }
      });
    },
    updateUrl() {
      return my_module_path(this.myModule.id);
    },
    disableEditMode() {
      this.inEditMode = false;
    },
    enableEditMode() {
      if (!this.updateUrl()) return;
      if (this.inEditMode) return;
      this.inEditMode = true;

      const editor = document.querySelector('.tiny-mce-editor');
      this.resizeObserver.observe(editor);
    },
    recalculateContainerSize(offset = 0) {
      const container = this.$refs.notesContainer;
      const handler = this.$refs.openHandler;

      if (this.sectionOpened) {
        container.style.maxHeight = `${container.scrollHeight + offset}px`;
        handler.classList.remove('sn-icon-right');
        handler.classList.add('sn-icon-down');
      } else {
        container.style.maxHeight = '0px';
        handler.classList.remove('sn-icon-down');
        handler.classList.add('sn-icon-right');
      }
    },
    toggleContainer() {
      this.sectionOpened = !this.sectionOpened;
      this.recalculateContainerSize(60);
    },
    reloadMyModule() {
      this.$emit('reloadMyModule');
    }
  }
};
</script>
