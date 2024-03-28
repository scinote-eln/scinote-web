<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title truncate !block" id="edit-project-modal-label">
            {{ i18n.t("projects.reports.new.save_PDF_to_inventory") }}
          </h4>
        </div>
        <div class="modal-body">
          <div class="mb-4">{{ i18n.t('projects.reports.new.save_PDF_to_inventory_modal.description_one') }}</div>
          <div class="mb-4">{{ i18n.t('projects.reports.new.save_PDF_to_inventory_modal.description_two') }}</div>
          <div v-if="false && !report.pdf_file.preview_url" class="mb-4">
            <em>{{ i18n.t('projects.reports.new.save_PDF_to_inventory_modal.pdf_not_ready') }}</em>
          </div>
          <template v-else-if="availableRepositories.length > 0">
            <div class="mb-4">
              <label class="sci-label">
                {{ i18n.t("projects.reports.new.save_PDF_to_inventory_modal.inventory") }}
              </label>
              <SelectDropdown :optionsUrl="repositoriesUrl" @change="changeRepository" :searchable="true" />
            </div>
            <div v-if="selectedRepository" class="mb-4">
              <label class="sci-label">
                {{ i18n.t("projects.reports.new.save_PDF_to_inventory_modal.inventory_column") }}
              </label>
              <SelectDropdown :optionsUrl="columnsUrl"
                :urlParams="{repository_id: selectedRepository}"
                :searchable="true"
                @change="changeColumn" />
            </div>
            <div v-if="selectedColumn && !rowsError" class="mb-4">
              <label class="sci-label">
                {{ i18n.t("projects.reports.new.save_PDF_to_inventory_modal.inventory_item") }}
              </label>
              <SelectDropdown :options="formattedRowsList" @change="changeRow" :searchable="true" />
            </div>
            <div v-if="rowsError" class="mb-4" v-html="rowsError"></div>
            <div
              class="text-sn-delete-red"
              v-if="fileAlreadyAttached"
              v-html="i18n.t('projects.reports.new.save_PDF_to_inventory_modal.asset_present_warning_html')">
            </div>
          </template>
          <div class="mb-4" v-else>
            <em>{{ i18n.t('projects.reports.new.save_PDF_to_inventory_modal.no_inventories') }}</em>
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
          <button
            @click="saveToInventory"
            type="button"
            class="btn btn-primary"
            :disabled="!selectedColumn || !selectedRow">
            {{  i18n.t('general.save') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>

import SelectDropdown from '../../shared/select_dropdown.vue';
import axios from '../../../packs/custom_axios.js';
import modalMixin from '../../shared/modal_mixin';

export default {
  name: 'SaveToInventoryModal',
  props: {
    report: Object,
    repositoriesUrl: String,
    columnsUrl: String,
    rowsUrl: String
  },
  mixins: [modalMixin],
  components: {
    SelectDropdown
  },
  mounted() {
    this.getAvailableRepositories();
  },
  computed: {
    formattedRowsList() {
      return this.availableRows.map((row) => (
        [row.id, row.name]
      ));
    },
    fileAlreadyAttached() {
      return this.availableRows.find((row) => (
        row.id === this.selectedRow
      ))?.has_file_attached;
    }
  },
  data() {
    return {
      availableRows: [],
      availableRepositories: [],
      selectedRepository: null,
      selectedColumn: null,
      selectedRow: null,
      rowsError: null
    };
  },
  methods: {
    getAvailableRepositories() {
      axios.get(this.repositoriesUrl)
        .then((response) => {
          this.availableRepositories = response.data.data;
        });
    },
    getAvaialableRows() {
      axios.get(this.rowsUrl, {
        params: {
          repository_id: this.selectedRepository,
          repository_column_id: this.selectedColumn
        }
      })
        .then((response) => {
          this.availableRows = response.data.results;
        })
        .catch((error) => {
          this.rowsError = error.response.data.no_items;
        });
    },
    changeRepository(repository) {
      if (typeof repository === 'object') {
        return;
      }

      this.selectedColumn = null;
      this.selectedRepository = null;
      this.selectedRow = null;
      this.$nextTick(() => {
        this.selectedRepository = repository;
      });
    },
    changeColumn(column) {
      this.selectedColumn = column;
      this.selectedRow = null;
      this.getAvaialableRows();
    },
    changeRow(row) {
      this.selectedRow = row;
    },
    saveToInventory() {
      axios.post(this.report.urls.save_to_inventory, {
        repository_id: this.selectedRepository,
        repository_column_id: this.selectedColumn,
        repository_item_id: this.selectedRow
      })
        .then(() => {
          this.close();
        });
    }
  }
};
</script>
