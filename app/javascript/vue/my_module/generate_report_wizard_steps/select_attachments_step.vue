<template>
  <div class="modal-header">
    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
      <i class="sn-icon sn-icon-close"></i>
    </button>
    <h4 class="modal-title truncate flex items-center gap-4">
      {{ i18n.t('my_modules.reports.wizard.first_step.title') }}
    </h4>
  </div>
  <div class="modal-body h-full">
    <div v-if="loading" class="h-full flex items-center justify-center">
      <div class="sci-loader"></div>
    </div>
    <div v-else-if="assets.length > 0">
      <Draggable
        v-model="assets"
        :ghostClass="'step-checklist-item-ghost'"
        :dragClass="'step-checklist-item-drag'"
        :chosenClass="'step-checklist-item-chosen'"
        handle=".widget-element-grip"
        item-key="id"
      >
        <template #item="{element}">
          <div class="flex items-center gap-2 py-2 hover:bg-sn-super-light-grey group">
            <div class="widget-element-grip cursor-pointer opacity-0 group-hover:opacity-100 px-2">
              <i class="sn-icon sn-icon-drag"></i>
            </div>
            <span class="sci-checkbox-container">
              <input type="checkbox" class="sci-checkbox" v-model="element.checked" />
              <span class="sci-checkbox-label"></span>
            </span>
            <div class="text-center flex items-center gap-2 list-attachment-container w-full min-w-0">
              <i class="text-sn-grey asset-icon sn-icon sn-icon-file-pdf shrink-0"></i>
              <a
                class="file-preview-link file-name"
                :id="`modal_link${element.id}`"
                data-no-turbolink="true"
                :data-id="element.id"
                :data-preview-url="element.preview"
              >
                <span class="attachment-name" data-toggle="tooltip" data-placement="bottom">
                  {{ element.file_name }}
                </span>
              </a>
              <div v-if="element.medium_preview" class="attachment-image-tooltip bg-white sn-shadow-menu-sm shrink-0">
                <img :src="element.medium_preview" @error="ActiveStoragePreviews.reCheckPreview"
                      @load="ActiveStoragePreviews.showPreview"/>
              </div>
              <div class="text-sn-grey truncate flex-1 min-w-0 text-right" data-render-tooltip="true" :title="element.parent_name">
                {{ element.parent_name }}
              </div>
            </div>
          </div>
        </template>
      </Draggable>
    </div>
    <div v-else>
      {{ i18n.t('my_modules.reports.wizard.first_step.no_assets') }}
    </div>

  </div>
  <div class="modal-footer">
    <button class="btn btn-secondary focus:border-sn-blue-hover" @click="$emit('close')">
      {{ i18n.t('my_modules.reports.wizard.actions.cancel') }}
    </button>
    <button class="btn btn-primary focus:bg-sn-blue-hover" @click="submit">
      {{ i18n.t('my_modules.reports.wizard.actions.next') }}
    </button>
  </div>
</template>

<script>

import axios from '../../../packs/custom_axios.js';
import Draggable from 'vuedraggable';

import {
  pdfs_my_module_my_module_reports_path
} from '../../../routes.js'

export default {
  emits: ['close', 'back', 'next'],
  name: 'SelectAttachment',
  props: {
    params: {
      type: Object,
      required: true
    },
    wizardComponent: {
      type: Object,
      required: true
    }
  },
  components: {
    Draggable
  },
  data() {
    return {
      loading: true,
      assets: []
    }
  },
  created() {
    this.loadAssets();
  },
  computed: {
    loadPdfsUrl() {
      return pdfs_my_module_my_module_reports_path(this.params.myModuleId);
    }
  },
  methods: {
    loadAssets() {
      axios.get(this.loadPdfsUrl).then((response) => {
        this.loading = false;
        this.assets = response.data.data;
        this.assets = this.assets.map(asset => ({ ...asset, checked: true }));
      });
    },
    submit() {
      this.$emit('next');
      const assetIds = this.assets.filter(asset => asset.checked).map(asset => asset.id);
      this.wizardComponent.$emit('setAssetIds', assetIds);
    }

  }
};
</script>
