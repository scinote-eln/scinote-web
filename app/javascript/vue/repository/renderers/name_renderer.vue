<template>
  <div class="flex items-center gap-2 relative">
    <template v-if="!editing && this.params.data.id">
      <template v-if="params.data.name">
        <div class="w-full flex relative gap-1 group">
          <a v-if="params.data.name"
            class="hover:no-underline record-info-link truncate cursor-pointer block grow"
            :title="params.data.name"
            :href="recordInfoUrl"
          >
            {{ params.data.name }}
          </a>
          <div v-if="canManage" @click="startEditing" class="tw-hidden group-hover:block">
            <i class="sn-icon sn-icon-edit cursor-pointer "></i>
          </div>
        </div>
      </template>
      <span v-else
        :title="i18n.t('my_modules.assigned_items.repository.private_repository_row_name')"
        class="text-sn-grey truncate"
      >
        <i class="sn-icon sn-icon-locked-task"></i>
        {{ i18n.t('my_modules.assigned_items.repository.private_repository_row_name', {repository_row_code: params.data.code }) }}
      </span>
      <i v-if="params.data.archived" class="sn-icon sn-icon-archived text-sn-grey" :title="i18n.t('general.archived')"></i>

      <span v-if="params.data.output" class="text-sn-grey bg-sn-light-grey text-xs px-1.5 py-1 ">
        {{ i18n.t('general.output') }}
      </span>
    </template>
    <template v-else>
      <div class="flex w-full">
        <errorFlyout :error="error" @close="error = null" />
        <input
        type="text"
        ref="nameInput"
        class="sci-table-input-v2 grow"
        :class="{ 'error': error }"
        :placeholder="this.i18n.t('repositories.table.name.placeholder')"
        @keydown.enter="saveName"
        @keydown.escape="cancelEditing"
        @blur="saveNameClickAway"
        @keydown="handleKeydown"
        v-model="rowName" />
      </div>
    </template>

  </div>
</template>

<script>

import axios from '../../../packs/custom_axios.js';
import GeneralDropdown from '../../shared/general_dropdown.vue';
import errorFlyout from './error_flyout.vue';
import {
  repository_repository_row_path
 } from '../../../routes.js';

export default {
  props: {
    params: {
      type: Object,
      required: true
    }
  },
  computed: {
    canManage() {
      return this.params?.data?.permissions?.manage || false;
    },
    recordInfoUrl() {
      return repository_repository_row_path(
        this.params.data.repository_id,
        this.params.data.id
      );
    },
    isValid() {
      return this.rowName.length > 0 && this.rowName.length <= GLOBAL_CONSTANTS.NAME_MAX_LENGTH;
    }
  },
  components: {
    GeneralDropdown,
    errorFlyout
  },
  data() {
    return {
      editing: false,
      rowName: this.params.data.name,
      error: null,
      saving: false
    };
  },
  mounted() {
    if (this.$refs.nameInput) {
      this.$nextTick(() => {
        this.$refs.nameInput.focus();
      });
    }
  },
  watch: {
    rowName(newVal) {
      if (!this.params.data.id) {
        this.params.dtComponent.setTemplateValue(newVal, 'name', this.isValid);
      }
    }
  },
  methods: {
    startEditing() {
      if (this.editing || !this.params.data.id) return;
      this.rowName = this.params.data.name;
      this.editing = true;
      this.$nextTick(() => {
        this.$refs.nameInput.focus();
      });
    },
    saveNameClickAway() {
      if (this.editing && this.params.data.id) {
        this.saveName();
      }
    },
    cancelEditing() {
      this.editing = false;
      this.rowName = this.params.data.name;
      this.error = null;
      this.params.dtComponent.cancelCreation();
    },
    handleKeydown(event) {
      // Prevent arrow keys from moving the table selection
      if (event.key === 'ArrowLeft') {
        event.stopPropagation();
        this.$refs.nameInput.selectionStart -= 1;
      } else if (event.key === 'ArrowRight') {
        event.stopPropagation();
        this.$refs.nameInput.selectionEnd += 1;
      } else if (event.key === 'Home') {
        event.stopPropagation();
        this.$refs.nameInput.selectionStart = 0;
      } else if (event.key === 'End') {
        event.stopPropagation();
        this.$refs.nameInput.selectionEnd = this.rowName.length;
      } else if ((event.key === 'a' || event.key === 'A') && (event.ctrlKey || event.metaKey)) {
        event.stopPropagation();
      }
    },
    saveName() {
      if (!this.isValid) {
        if (this.rowName.length == 0) {
          this.error = this.i18n.t('repositories.table.name.errors.is_empty');
        } else if (this.rowName.length > GLOBAL_CONSTANTS.NAME_MAX_LENGTH) {
          this.error = this.i18n.t('repositories.table.name.errors.too_long', { max_length: GLOBAL_CONSTANTS.NAME_MAX_LENGTH });
        }
        this.params.dtComponent.setTemplateValue(this.rowName, 'name', this.isValid);
        return;
      } else {
        this.error = null;
      }

      this.editing = false;

      if (this.rowName == this.params.data.name) return;

      if (this.saving) return;

      this.saving = true;

      if (this.params.data.id) {
        this.params.dtComponent.$emit('changeName', this.rowName, this.params.data);
      } else {
        this.params.dtComponent.setTemplateValue(this.rowName, 'name', this.isValid);
        this.params.dtComponent.createRow();
      }
    }
  }
};
</script>
