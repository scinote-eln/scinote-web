<template>
  <div>
    <button v-if="!disabled" class="btn btn-secondary" @click="rowSelectorOpened = true" :disabled="marked_as_na">
      {{  i18n.t('forms.show.add_items') }}
      <i class="sn-icon sn-icon-right"></i>
    </button>
    <span class="text-sn-grey-700" v-if="disabled && !field.field_value?.value">
      {{ i18n.t('forms.show.no_items_selected') }}
    </span>
    <RowSelectorModal v-if="rowSelectorOpened"
                      :excludeRows="assignedIds"
                      @close="rowSelectorOpened = false"
                      @save="addValue" />
    <div v-if="field.field_value" class="flex items-center gap-2 mt-4 flex-wrap">
      <template v-for="(row, index) in field.field_value.value" :key="row.id">
        <div class="flex items-center gap-2">
          <span v-if="index > 0">|</span>
          <a v-if="row.has_access"
            class="cursor-pointer text-sn-blue record-info-link"
            :href="itemCardUrl(row)"
          >{{ row.name }}</a>
          <span v-else class="cursor-pointer"> {{ row.name }}</span>
          <i  v-if="!disabled" @click="removeValue(row.id)" class="sn-icon sn-icon-unlink-italic-s cursor-pointer"></i>
        </div>
      </template>
    </div>
  </div>
</template>

<script>
/* global  */

import fieldMixin from './field_mixin';
import RowSelectorModal from './modals/row_selector.vue';
import {
  repository_repository_row_path,

} from '../../../routes.js';

export default {
  name: 'RepositoryRowsField',
  mixins: [fieldMixin],
  components: {
    RowSelectorModal
  },
  data() {
    return {
      rowSelectorOpened: false
    };
  },
  watch: {
    marked_as_na() {
      if (this.marked_as_na) {
        this.value = null;
      }
    }
  },
  mounted() {
  },
  computed: {
    assignedIds() {
      return this.field.field_value?.value?.map((row) => row.id) || [];
    },
    validValue() {
      return true;
    }
  },
  methods: {
    itemCardUrl(row) {
      return repository_repository_row_path(row.repository_id, row.id, { form_repository_rows_field_value_id: this.field.field_value.id });
    },
    addValue(rows) {
      const rowIds = this.assignedIds;
      rows.forEach((row) => {
        if (!rowIds.includes(row)) {
          rowIds.push(row);
        }
      });
      this.rowSelectorOpened = false;
      this.$emit('save', rowIds.length > 0 ? rowIds : null);
    },
    removeValue(id) {
      const rowIds = this.assignedIds;
      rowIds.splice(rowIds.indexOf(id), 1);
      this.$emit('save', rowIds.length > 0 ? rowIds : null);
    }
  }
};
</script>
