<template>
  <GeneralDropdown>
    <template v-slot:field>
      <button ref="field" class="btn btn-light" @click="isOpen = !isOpen" :data-e2e="dataE2e">
        <span v-if="text">{{ text }}</span>
        <i v-if="isOpen" class="sn-icon sn-icon-up"></i>
        <i v-else class="sn-icon sn-icon-down"></i>
      </button>
    </template>
    <template v-slot:flyout>
      <span class="flex justify-between items-center rounded relative whitespace-nowrap px-3 py-2.5 cursor-pointer hover:!bg-sn-super-light-grey group min-h-14 !min-w-72"
            :class="{
              '!bg-sn-super-light-blue':selectedId == params.defaultVersion,
              'text-sn-grey pointer-events-none': !params.hasLiveVersion
            }"
            @click="selectVersion(null)"> 
        <div>{{ i18n.t('my_modules.repository.version.live_version') }}</div>
        <div v-if="params.hasLiveVersion" class="flex gap-2">
          <i v-if="pinnedId == params.defaultVersion" class="flex sn-icon sn-icon-pinned text-sn-grey items-center justify-center w-10"></i>
          <button v-else-if="params.canManageSnapshots" class="btn btn-light icon-btn" data-toggle="tooltip" :title="i18n.t('my_modules.repository.version.pin')" @click.stop="pinVersion(null)">
            <i class="sn-icon sn-icon-pin"></i>
          </button>
        </div>
      </span>
      <div v-if="versions.length > 0" class="border-0 border-t border-solid border-sn-light-grey"></div>
      <div class="max-h-64 overflow-y-auto">
      <SnapshotItem
        v-for="(item, i) in versions"
        :key="item.id"
        :item="item"
        :pinned="pinnedId == item.id"
        :selected="selectedId == item.id"
        :myModuleId="params.myModuleId"
        :canManageSnapshots="params.canManageSnapshots"
        @deleteVersion="deleteVersion"
        @selectVersion="selectVersion"
        @pinVersion="pinVersion"
      ></SnapshotItem>
      </div>
      <div v-if="params.canCreateSnapshots" class="border-0 border-t border-solid border-sn-light-grey"></div>
      <span v-if="params.canCreateSnapshots" 
            class="flex justify-between items-center rounded relative whitespace-nowrap px-3 py-2 cursor-pointer hover:!bg-sn-super-light-grey group min-h-14"
            @click="createVersion"> 
        <div>{{ i18n.t('my_modules.repository.version.create_snapshot') }}</div>
      </span>
    </template>
  </GeneralDropdown>
</template>

<script>

import axios from '../../../packs/custom_axios.js';
import SnapshotItem from './renderers/snapshot_item.vue'
import GeneralDropdown from '../../shared/general_dropdown.vue';

import {
  my_module_repository_snapshots_path
} from '../../../routes.js';

export default {
  name: 'VersionDropdown',
  props: {
    params: { type: Object, default: {} },
    dataE2e: { type: String, default: '' },
  },
  data() {
    return {
      isOpen: false,
      versions: [],
      selectedId: '',
      pinnedId: '',
      text: this.params.btnText
    };
  },
  components: {
    SnapshotItem,
    GeneralDropdown
  },
  watch: {
    isOpen() {
      if(this.isOpen) {
        this.loadVersions();
      }
    }
  },
  created() {
    this.selectedId = this.params.selectedVersion;
    this.pinnedId = this.params.selectedVersion;
  },
  mounted() {
    window.initTooltip('[data-toggle="tooltip"]');
  },
  beforeUnmount() {
    window.destroyTooltip('[data-toggle="tooltip"]');
  },
  computed: {
    createVersionUrl(){
      return my_module_repository_snapshots_path(this.params.myModuleId, this.params.defaultVersion);
    }
  },
  methods: {
    loadVersions() {
      axios.get(this.params.sourceUrl)
        .then((response) => {
          this.versions = response.data.data;
        });
    },
    selectVersion(item) {
      this.emitAction('selectVersion', item);
    },
    pinVersion(item) {
      this.emitAction('pinVersion', item);
      this.pinnedId = item ? item.id : this.params.defaultVersion;
    },
    createVersion(){
      axios.post(this.createVersionUrl).then((response) => {
        this.versions.unshift(response.data.data);
      });
    },
    deleteVersion(item) {
      if (this.selectedId === item.id) {
        this.selectVersion(null);
      }

      this.versions = this.versions.filter(v => v.id !== item.id);
      axios.delete(my_module_repository_snapshots_path(this.params.myModuleId, item.id));
    },
    emitAction(action, item) {
      $('.tooltip').remove();
      if(item) {
        this.text = this.i18n.t('my_modules.repository.version.snapshot_version', { snapshot_date: item.attributes.name });
        this.selectedId = item.id;
        this.$emit('dtEvent', action, item.id);
      } else {
        this.text = this.i18n.t('my_modules.repository.version.view_version');
        this.selectedId = this.params.defaultVersion;
        this.$emit('dtEvent', action);
      }

      this.$nextTick(() => {
        window.initTooltip('[data-toggle="tooltip"]');
      });
    }
  }
};
</script>
