<template>
  <div class="modal-header">
    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
      <i class="sn-icon sn-icon-close"></i>
    </button>
    <h4 class="modal-title truncate flex items-center gap-4">
      {{ i18n.t('my_modules.reports.wizard.first_step.title') }}
    </h4>
  </div>
  <div class="modal-body h-full max-h-[450px] overflow-y-auto">
    <div v-if="loading" class="h-full flex items-center justify-center">
      <div class="sci-loader"></div>
    </div>
    <Draggable
      v-else-if="groups.length > 0"
      v-model="groups"
      :group="{ name: 'attachment-groups', pull: false, put: false }"
      :ghostClass="'step-checklist-item-ghost'"
      :dragClass="'step-checklist-item-drag'"
      :chosenClass="'step-checklist-item-chosen'"
      handle=".group-grip"
      :item-key="groupKey"
      class="flex flex-col"
      @choose="onGroupChoose"
      @unchoose="draggingGroupKey = null"
    >
      <template #item="{ element: group }">
        <div>
          <div class="flex items-center gap-2 py-2 font-bold hover:bg-sn-super-light-grey">
            <div class="group-grip cursor-pointer px-2">
              <i class="sn-icon sn-icon-drag"></i>
            </div>
            <div @click="toggleGroup(group)" class="flex items-center gap-2 cursor-pointer min-w-0">
              <div class="sn-checkbox-icon shrink-0" :class="groupSelectState(group)"></div>
              <span class="truncate" :title="group.name">{{ group.name }}</span>
            </div>
          </div>
          <Draggable
            v-show="draggingGroupKey !== groupKey(group)"
            v-model="group.assets"
            :group="{ name: groupKey(group), pull: false, put: false }"
            :ghostClass="'step-checklist-item-ghost'"
            :dragClass="'step-checklist-item-drag'"
            :chosenClass="'step-checklist-item-chosen'"
            handle=".widget-element-grip"
            item-key="id"
            class="pl-6"
          >
            <template #item="{ element }">
              <div class="flex items-center gap-2 py-2 hover:bg-sn-super-light-grey group">
                <div class="widget-element-grip cursor-pointer px-2">
                  <i class="sn-icon sn-icon-drag"></i>
                </div>
                <span class="sci-checkbox-container">
                  <input type="checkbox" class="sci-checkbox" v-model="element.checked" />
                  <span class="sci-checkbox-label"></span>
                </span>
                <div class="text-center flex items-center gap-2 list-attachment-container w-full min-w-0">
                  <i class="text-sn-grey asset-icon sn-icon sn-icon-file-pdf shrink-0"></i>
                  <a
                    class="file-preview-link file-name flex-[2] gap-2"
                    :id="`modal_link${element.id}`"
                    data-no-turbolink="true"
                    :data-id="element.id"
                    :data-preview-url="element.preview"
                  >
                    <span v-if="element.file_title" class="text-sn-black truncate">
                      {{ element.file_title }}
                    </span>
                    <span class="attachment-name truncate" data-toggle="tooltip" data-placement="bottom">
                      {{ element.file_name }}
                    </span>
                  </a>
                  <div v-if="element.medium_preview" class="attachment-image-tooltip bg-white sn-shadow-menu-sm shrink-0">
                    <img :src="element.medium_preview" @error="ActiveStoragePreviews.reCheckPreview"
                          @load="ActiveStoragePreviews.showPreview"/>
                  </div>
                </div>
              </div>
            </template>
          </Draggable>
        </div>
      </template>
    </Draggable>
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
      groups: [],
      draggingGroupKey: null
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
        this.groups = response.data.data.map((group) => ({
          ...group,
          assets: group.assets.map((asset) => ({ ...asset, checked: true }))
        }));
      }).finally(() => {
        this.loading = false;
      });
    },
    groupKey(group) {
      return `${group.type}-${group.id}`;
    },
    onGroupChoose(event) {
      this.draggingGroupKey = this.groupKey(this.groups[event.oldIndex]);
    },
    groupSelectState(group) {
      const checkedCount = group.assets.filter((asset) => asset.checked).length;
      if (checkedCount === 0) return 'unchecked';
      if (checkedCount === group.assets.length) return 'checked';
      return 'indeterminate';
    },
    toggleGroup(group) {
      const checked = this.groupSelectState(group) !== 'checked';
      group.assets.forEach((asset) => { asset.checked = checked; });
    },
    submit() {
      this.$emit('next');
      const assetGroups = this.groups
        .map((group) => ({
          type: group.type,
          id: group.id,
          asset_ids: group.assets.filter((asset) => asset.checked).map((asset) => asset.id)
        }))
        .filter((group) => group.asset_ids.length > 0);
      this.wizardComponent.$emit('setAssetGroups', assetGroups);
    }
  }
};
</script>
