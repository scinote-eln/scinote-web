<template>
  <div class="w-full h-full pl-6 bg-white flex flex-col" data-e2e="e2e-CO-itemCard-create">
    <div class="flex flex-col pt-6">
      <div class="flex items-center gap-4 h-[30px] pr-6">
        <div class="relative flex-1 text-xl font-semibold">
          <input
            ref="nameInput"
            v-model="name"
            type="text"
            class="w-full leading-5 outline-none pl-0 border-0 border-solid border-y border-t-transparent placeholder:text-sn-grey placeholder:font-normal"
            :class="nameError ? 'border-b-sn-delete-red' : 'border-b-transparent focus:border-b-sn-science-blue'"
            :placeholder="i18n.t('repositories.item_card.new_item.title_placeholder')"
            data-e2e="e2e-IF-itemCard-title"
            @blur="nameTouched = true"/>
          <div v-if="nameError" class="absolute -bottom-4 w-full truncate text-xs font-normal text-sn-delete-red"
            data-e2e="e2e-TX-itemCard-titleError">
            {{ nameError }}
          </div>
        </div>
        <i class="sn-icon sn-icon-close cursor-pointer" data-e2e="e2e-BT-itemCard-close" @click="$emit('close')"></i>
      </div>
      <div class="bg-sn-light-grey h-px mt-5 mr-6"></div>
    </div>

    <div id="body-wrapper" class="flex-1 min-h-0 overflow-y-auto overflow-x-hidden pt-6">
      <div v-if="loading" key="loading" class="h-full flex">
        <div class="sci-loader"></div>
      </div>
      <div v-else id="scrollSpyContent" :key="formKey" class="flex justify-between">
        <div class="flex flex-col gap-6 w-[350px]">
          <template v-for="(section, index) in sections" :key="section.sectionId">
            <div v-if="index > 0" class="bg-sn-light-grey h-px"></div>
            <section :id="section.sectionId" class="flex flex-col min-h-[64px]">
              <div :id="section.label" class="font-inter text-lg font-semibold leading-7 mb-6 transition-colors duration-300">
                {{ i18n.t(`repositories.highlight_component.${section.labelAlias}`) }}
              </div>
              <div v-if="section.columns.length" class="flex flex-col gap-4">
                <template v-for="(column, columnIndex) in section.columns" :key="column.id">
                  <div v-if="columnIndex > 0" class="sci-divider"></div>
                  <div class="font-semibold">{{ column.name }}</div>
                  <NewItemCell
                    :column="column"
                    :repositoryId="repositoryId"
                    :itemName="name"
                    :canManageStock="canManageStock"
                    :initialCell="rowToDuplicate?.cells[column.id]"
                    :initialStock="rowToDuplicate?.stock?.column_id === column.id ? rowToDuplicate.stock.draft : null"
                    :showErrors="!!rowToDuplicate"
                    @change="onCellChange(column.id, $event)"/>
                  <div v-if="cellErrors[column.id]"
                       class="-mt-3 text-xs text-sn-delete-red"
                       data-e2e="e2e-TX-itemCard-cellUniqueError">
                    {{ cellErrors[column.id] }}
                  </div>
                </template>
              </div>
              <div v-else class="text-sn-dark-grey text-sm leading-5">
                {{ i18n.t('repositories.item_card.no_custom_columns_label') }}
              </div>
            </section>
          </template>
        </div>
        <div class="min-w-[130px] h-fit sticky top-0 pr-6">
          <ScrollSpy :itemsToCreate="sections"/>
        </div>
      </div>
    </div>

    <div class="pr-6">
      <div class="bg-sn-light-grey h-px"></div>
      <div class="flex items-center justify-between h-[76px]">
        <div class="flex items-center gap-6">
          <label v-if="myModuleId" class="flex items-center gap-2 mb-0 font-normal cursor-pointer">
            <span class="sci-checkbox-container">
              <input v-model="markAsOutput" type="checkbox" class="sci-checkbox" data-e2e="e2e-CB-itemCard-markAsOutput"/>
              <span class="sci-checkbox-label"></span>
            </span>
            {{ i18n.t('repositories.item_card.new_item.mark_as_output') }}
          </label>
          <label class="flex items-center gap-2 mb-0 font-normal cursor-pointer">
            <span class="sci-checkbox-container">
              <input v-model="createAnother" type="checkbox" class="sci-checkbox" data-e2e="e2e-CB-itemCard-createAnother"/>
              <span class="sci-checkbox-label"></span>
            </span>
            {{ i18n.t('repositories.item_card.new_item.create_another') }}
          </label>
        </div>
        <button type="button" class="btn btn-primary" :disabled="!canCreate" data-e2e="e2e-BT-itemCard-createItem"
          @click="createItem">
          {{ i18n.t(`repositories.item_card.new_item.${creating ? 'creating' : 'create_item'}`) }}
        </button>
      </div>
    </div>

    <Teleport to="body">
      <ConfirmationModal
        ref="discardModal"
        :title="i18n.t('repositories.item_card.new_item.discard_title')"
        :description="i18n.t('repositories.item_card.new_item.discard_description')"
        :cancelText="i18n.t('repositories.item_card.new_item.discard_cancel')"
        :confirmText="i18n.t('repositories.item_card.new_item.discard_confirm')"
        confirmClass="btn btn-danger"
        e2eValue="itemCard-discardNewItem"/>
    </Teleport>
  </div>
</template>

<script>
/* global ActiveStorage GLOBAL_CONSTANTS HelperModule I18n */

import axios from '../../packs/custom_axios.js';
import ConfirmationModal from '../shared/confirmation_modal.vue';
import ScrollSpy from './scroll_spy.vue';
import NewItemCell from './new_item_cell.vue';
import {
  duplicate_repository_repository_row_path,
  new_repository_repository_row_path,
  repository_repository_rows_path,
  rails_direct_uploads_path
} from '../../routes.js';

const MANDATORY_SECTION = {
  id: 'highlight-item-mandatory',
  textId: 'text-item-mandatory',
  labelAlias: 'mandatory_columns_label',
  label: 'mandatory-columns-label',
  sectionId: 'mandatory-columns-section'
};
const CUSTOM_SECTION = {
  id: 'highlight-item-custom',
  textId: 'text-item-custom',
  labelAlias: 'custom_columns_label',
  label: 'custom-columns-label',
  sectionId: 'custom-columns-section'
};

const isBlank = (value) => {
  if (value === null || value === undefined) return true;
  if (typeof value === 'string') return value.trim() === '';
  if (Array.isArray(value)) return value.length === 0;
  if (value.constructor === Object) return Object.values(value).every(isBlank);

  return false;
};

const directUpload = (file) => new Promise((resolve, reject) => {
  new ActiveStorage.DirectUpload(file, rails_direct_uploads_path()).create((error, blob) => {
    if (error) {
      reject(error);
    } else {
      resolve(blob.signed_id);
    }
  });
});

export default {
  name: 'NewItem',
  components: {
    ConfirmationModal,
    ScrollSpy,
    NewItemCell
  },
  props: {
    repositoryId: { type: [Number, String], required: true },
    rowToDuplicateId: { type: [Number, String], default: null },
    myModuleId: { type: [Number, String], default: null },
    initialName: { type: String, default: '' },
    initialMarkAsOutput: { type: Boolean, default: false }
  },
  emits: ['created', 'close'],
  data() {
    return {
      loading: true,
      columns: [],
      canManageStock: false,
      name: this.initialName,
      nameTouched: !!this.initialName,
      markAsOutput: this.initialMarkAsOutput,
      itemNameError: null,
      cellErrors: {},
      cells: {},
      rowToDuplicate: null,
      createAnother: false,
      creating: false,
      formKey: 0,
      discardConfirmation: null
    };
  },
  computed: {
    nameError() {
      const name = this.name.trim();
      const attribute = this.i18n.t('repositories.item_card.header_title');

      if (!name && this.nameTouched) {
        return this.i18n.t('inline_edit.errors.blank', { attribute });
      }
      if (name.length > GLOBAL_CONSTANTS.NAME_MAX_LENGTH) {
        return this.i18n.t('inline_edit.errors.over_limit', { attribute, limit: GLOBAL_CONSTANTS.NAME_MAX_LENGTH });
      }
      return this.itemNameError;
    },
    sections() {
      const mandatory = this.columns.filter((column) => column.mandatory);
      const custom = this.columns.filter((column) => !column.mandatory);
      const sections = [];

      if (mandatory.length) sections.push({ ...MANDATORY_SECTION, columns: mandatory });
      if (custom.length || !mandatory.length) sections.push({ ...CUSTOM_SECTION, columns: custom });

      return sections;
    },
    filledCells() {
      return Object.fromEntries(Object.entries(this.cells).filter(([, value]) => !isBlank(value)));
    },
    copiedColumnIds() {
      if (!this.rowToDuplicate) return [];

      return Object.keys(this.rowToDuplicate.cells).filter((columnId) => !(columnId in this.cells));
    },
    isDirty() {
      return this.name.trim() !== '' || Object.keys(this.filledCells).length > 0 || this.copiedColumnIds.length > 0;
    },
    canCreate() {
      return !this.loading && !this.creating && this.name.trim() !== '' && !this.nameError
        && Object.keys(this.cellErrors).length === 0
        && this.columns.every((column) => !column.mandatory || this.isFilled(column.id));
    }
  },
  watch: {
    name() {
      this.itemNameError = null;
    }
  },
  created() {
    const query = this.rowToDuplicateId ? { row_to_duplicate_id: this.rowToDuplicateId } : {};
    axios.get(new_repository_repository_row_path(this.repositoryId, query))
      .then(({ data }) => {
        this.columns = data.column_defs;
        this.canManageStock = data.can_manage_stock;
        if (data.row_to_duplicate) this.prefill(data.row_to_duplicate);
        this.loading = false;
      })
      .catch(() => {
        HelperModule.flashAlertMsg(I18n.t('general.error'), 'danger');
        this.$emit('close');
      });
  },
  mounted() {
    this.focusName();
  },
  methods: {
    prefill(rowToDuplicate) {
      this.rowToDuplicate = { ...rowToDuplicate, id: this.rowToDuplicateId };
      this.name = rowToDuplicate.name;
      this.nameTouched = true;
      if (rowToDuplicate.stock) this.cells[rowToDuplicate.stock.column_id] = rowToDuplicate.stock.draft;
      this.cellErrors = Object.fromEntries(
        Object.entries(rowToDuplicate.errors.unique_cells || {}).map(([columnId, messages]) => [columnId, messages[0]])
      );
      this.$nextTick(() => {
        this.itemNameError = rowToDuplicate.errors.name?.[0] || null;
      });
    },
    isFilled(columnId) {
      return columnId in this.filledCells || this.copiedColumnIds.includes(String(columnId));
    },
    focusName() {
      this.$refs.nameInput.focus({ preventScroll: true });
    },
    confirmDiscard() {
      if (this.creating) return Promise.resolve(false);
      if (!this.isDirty) return Promise.resolve(true);

      if (!this.discardConfirmation) {
        this.discardConfirmation = this.$refs.discardModal.show().finally(() => {
          this.discardConfirmation = null;
        });
      }
      return this.discardConfirmation;
    },
    async createItem() {
      this.creating = true;
      const row = await this.postItem().catch((error) => {
        const nameError = error.response?.data?.name?.[0];
        const uniqueCells = error.response?.data?.unique_cells;
        if (nameError || uniqueCells) {
          if (nameError) this.itemNameError = nameError;
          if (uniqueCells) {
            this.cellErrors = Object.fromEntries(
              Object.entries(uniqueCells).map(([columnId, messages]) => [columnId, messages[0]])
            );
          }
          return;
        }

        HelperModule.flashAlertMsg(I18n.t('general.error'), 'danger');
      });
      this.creating = false;
      if (!row) return;

      this.$emit('created', row);
      this.reset();
      if (this.createAnother) {
        this.focusName();
      } else {
        this.$emit('close');
      }
    },
    async postItem() {
      const repositoryCells = {};
      const cells = this.rowToDuplicate ? this.cells : this.filledCells;
      await Promise.all(Object.entries(cells).map(async ([columnId, value]) => {
        if (isBlank(value)) {
          repositoryCells[columnId] = null;
        } else {
          repositoryCells[columnId] = value instanceof File ? await directUpload(value) : value;
        }
      }));

      const url = this.rowToDuplicate
        ? duplicate_repository_repository_row_path(this.repositoryId, this.rowToDuplicate.id)
        : repository_repository_rows_path(this.repositoryId);
      const taskParams = this.myModuleId ? { my_module_id: this.myModuleId, is_output: this.markAsOutput } : {};
      const response = await axios.post(url, {
        repository_row: { name: this.name.trim() },
        repository_cells: repositoryCells,
        ...taskParams
      });
      return response.data.data;
    },
    onCellChange(columnId, value) {
      this.cells[columnId] = value;
      if (this.cellErrors[columnId]) {
        const { [columnId]: _removed, ...rest } = this.cellErrors;
        this.cellErrors = rest;
      }
    },
    reset() {
      this.rowToDuplicate = null;
      this.cellErrors = {};
      this.name = '';
      this.nameTouched = false;
      this.markAsOutput = false;
      this.cells = {};
      this.formKey += 1;
    }
  }
};
</script>
