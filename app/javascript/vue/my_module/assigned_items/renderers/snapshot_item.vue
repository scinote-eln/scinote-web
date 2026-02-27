<template>
  <div>
    <span v-if="provisioning" class="flex gap-4 items-center rounded relative whitespace-nowrap px-3 py-2 cursor-pointer hover:!bg-sn-super-light-grey group">
      <div class="flex flex-grow-1">
        <div class="sci-loader h-6 w-6 bg-contain"></div>
      </div>
      <div>
        <div>{{ i18n.t('my_modules.repository.version.creating_snapshot') }}</div>
        <div class="text-sn-grey-700">{{ i18n.t('my_modules.repository.version.snapshot_created_by', {user: item.attributes.created_by}) }}</div>
      </div>
    </span>
    <span v-else class="flex justify-between items-center rounded relative whitespace-nowrap px-3 py-2 cursor-pointer hover:!bg-sn-super-light-grey group"
          :class="{'!bg-sn-super-light-blue': selected}"  @click="selectVersion">
      <div>
        <div>{{ item.attributes.name }}</div>
        <div class="text-sn-grey-700">{{ i18n.t('my_modules.repository.version.snapshot_created_by', {user: item.attributes.created_by}) }}</div>
      </div>
      <div class="flex gap-2">
        <button v-if="canManageSnapshots" class="btn btn-light icon-btn opacity-0 group-hover:opacity-100" :title="i18n.t('my_modules.repository.version.delete')" @click.stop="deleteVersion">
          <i class="sn-icon sn-icon-delete"></i>
        </button>
        <i v-if="pinned" class="flex sn-icon sn-icon-pinned text-sn-grey items-center justify-center w-10"></i>
        <button v-else-if="canManageSnapshots" class="btn btn-light icon-btn" :title="i18n.t('my_modules.repository.version.pin')" @click.stop="pinVersion">
          <i class="sn-icon sn-icon-pin"></i>
        </button>
      </div>
    </span>
  </div>
</template>

<script>

import axios from '../../../../packs/custom_axios.js';
import tooltipMixin from '../../../mixins/tooltipMixin.js';
import {
  status_my_module_repository_snapshot_path
} from '../../../../routes.js';

export default {
  name: 'SnapshotItem',
  props: {
    item: { type: Object, required: true },
    pinned: { type: Boolean, default: false },
    selected: { type: Boolean, default: false },
    myModuleId: { type: String, required: true },
    canManageSnapshots: { type: Boolean, default: false }
  },
  data() {
    return {
      provisioning: false
    };
  },
  mixins: [tooltipMixin],
  computed: {
    statusUrl() {
      return status_my_module_repository_snapshot_path(this.myModuleId, this.item.id);
    }
  },
  created() {
    this.provisioning = this.item.attributes.status == 'provisioning';
    this.statusVersion();
  },
  watch: {
    selected() {
      //this.applyTooltips();
    }
  },
  methods: {
    deleteVersion() {
      this.$emit('deleteVersion', this.item);
    },
    selectVersion() {
      this.$emit('selectVersion', this.item);
    },
    pinVersion() {
      this.$emit('pinVersion', this.item);
    },
    statusVersion(){
      if(!this.provisioning) return;

      setTimeout(() => {
        axios.get(this.statusUrl)
        .then((response) => {
          this.provisioning = response.data.status === 'provisioning';
          if (this.provisioning) {
            this.statusVersion();
          } else {
            this.applyTooltips();
          }
        })
      }, GLOBAL_CONSTANTS.SLOW_STATUS_POLLING_INTERVAL);
    }
  }
};
</script>
