<template>
  <div>
    <div class="mb-4">
      <div class="sci-label">{{ i18n.t(`storage_locations.show.assign_modal.inventory`) }}</div>
      <SelectDropdown
        :optionsUrl="repositoriesUrl"
        placeholder="Select inventory"
        :searchable="true"
        :value="selectedRepository"
        @change="selectedRepository = $event"
      ></SelectDropdown>
    </div>
    <div class="relative">
      <div class="sci-label">{{ i18n.t(`storage_locations.show.assign_modal.item`) }}</div>
      <SelectDropdown
        :key="selectedRepository"
        :disabled="!selectedRepository"
        :optionsUrl="rowsUrl"
        :urlParams="{ repository_id: selectedRepository, excluded_ids: excludeRows }"
        ajaxMethod="post"
        placeholder="Select item"
        :multiple="multiple"
        :withCheckboxes="multiple"
        :searchable="true"
        :optionRenderer="itemRowOptionRenderer"
        :value="selectedRow"
        @close="showItemInfo = false"
        @change="selectedRow= $event"
      ></SelectDropdown>
      <div v-if="showItemInfo" class="absolute -right-64 w-60 bg-white border border-radius p-4 min-h-[10rem]">
        <div v-if="loadingHoveredRow" class="flex absolute top-0 left-0 items-center justify-center w-full flex-grow h-full z-10">
          <img src="/images/medium/loading.svg" alt="Loading" />
        </div>
        <template v-else>
          <div class="flex gap-4 overflow-hidden items-centers">
            <div class="truncate font-bold">{{  hoveredRow.name }}</div>
          </div>
          <template v-if="hoveredRow.columns">
            <div class="flex items-center gap-0.5 overflow-hidden text-xs" v-for="column in hoveredRow.columns" :key="column.id">
              <span class="truncate shrink-0 max-w-[50%]">{{ column.name }}</span>
              <span>:</span>
              <span class="truncate shrink-0" v-if="column.formatted_value">{{ column.formatted_value }}</span>
            </div>
          </template>
        </template>
      </div>
    </div>
  </div>
</template>

<script>
import escapeHtml from '../shared/escape_html.js';
import SelectDropdown from './select_dropdown.vue';
import axios from '../../packs/custom_axios.js';
import {
  list_team_repositories_path,
  rows_list_team_repositories_path,
  repository_repository_row_path
} from '../../routes.js';

export default {
  name: 'RowSelector',
  components: {
    SelectDropdown
  },
  props: {
    multiple: {
      type: Boolean,
      default: false
    },
    preSelectedRepository: {
      type: Number,
      default: null
    },
    preSelectedRows: {
      type: [Array],
      default: null
    },
    excludeRows: {
      type: Array,
      default: () => []
    }
  },
  created() {
    this.teamId = document.body.dataset.currentTeamId;
    if (this.preSelectedRepository) {
      this.selectedRepository = this.preSelectedRepository;
    }
    if (this.preSelectedRows) {
      this.selectedRow = this.preSelectedRows;
    }

    this.$nextTick(() => {
      this.loading = false;
    });
  },
  mounted() {
    document.addEventListener('mouseover', this.loadColumnsInfo);
  },
  beforeUnmount() {
    document.removeEventListener('mouseover', this.loadColumnsInfo);
  },
  watch: {
    selectedRepository() {
      if (this.loading) return;

      this.selectedRow = null;
      this.$emit('repositoryChange', this.selectedRepository);
      this.$emit('change', this.selectedRow);
    },
    selectedRow() {
      if (this.loading) return;

      this.$emit('change', this.selectedRow);
    }
  },
  computed: {
    repositoriesUrl() {
      return list_team_repositories_path(this.teamId, { non_empty: true, active: true });
    },
    rowsUrl() {
      if (!this.selectedRepository) {
        return null;
      }

      return rows_list_team_repositories_path(this.teamId, { active: true });
    }
  },
  data() {
    return {
      selectedRepository: null,
      selectedRow: null,
      teamId: null,
      showItemInfo: false,
      hoveredRow: {},
      loadingHoveredRow: false,
      loading: true
    };
  },
  methods: {
    rowInfoUrl(rowId) {
      return repository_repository_row_path(this.selectedRepository, rowId);
    },
    itemRowOptionRenderer(row) {
      return `
        <div class="flex items-center gap-4 w-full">
          <div class="grow overflow-hidden">
            <div class="truncate" >${escapeHtml(row[1])}</div>
            <div class="text-sn-grey">IT${row[0]}</div>
          </div>
          <i class="sn-icon sn-icon-info show-items-columns" title="" data-item-id="${row[0]}" data-repository-id='${this.selectedRepository}'></i>
        </div>`;
    },
    loadColumnsInfo(e) {
      if (!e.target.classList.contains('show-items-columns')) {
        this.showItemInfo = false;
        this.hoveredRow = {};
        return;
      }

      this.loadingHoveredRow = true;

      this.showItemInfo = true;

      axios.get(this.rowInfoUrl(e.target.dataset.itemId))
        .then((response) => {
          this.loadingHoveredRow = false;
          this.hoveredRow = {
            name: response.data.default_columns.name,
            columns: response.data.custom_columns
          };
        });
      e.stopPropagation();
      e.preventDefault();
    }
  }
};
</script>
