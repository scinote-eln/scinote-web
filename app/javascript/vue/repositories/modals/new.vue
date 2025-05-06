<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <form @submit.prevent="submit">
        <div class="modal-content" data-e2e="e2e-MD-newInventory">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close" data-e2e="e2e-BT-newInventoryModal-close">
              <i class="sn-icon sn-icon-close"></i>
            </button>
            <h4 class="modal-title truncate !block" id="edit-project-modal-label" data-e2e="e2e-TX-newInventoryModal-title">
              {{ i18n.t('repositories.index.modal_create.title') }}
            </h4>
          </div>
          <div class="modal-body">
            <div class="mb-6">
              <label class="sci-label" data-e2e="e2e-TX-newInventoryModal-inputLabel">{{ i18n.t("repositories.index.modal_create.name_label") }}</label>
              <div class="sci-input-container-v2" :class="{'error': error}" :data-error="error">
                <input type="text" v-model="name"
                       class="sci-input-field"
                       autofocus="true" ref="input"
                       data-e2e="e2e-IF-newInventoryModal-name"
                       :placeholder="i18n.t('repositories.index.modal_create.name_placeholder')" />
              </div>
            </div>
            <div v-if="repositoryTemplatesAvailable">
              <label class="sci-label" data-e2e="e2e-LB-newInventoryModal-inventoryTemplate">
                {{ i18n.t("repositories.index.modal_create.repository_template_label") }}
              </label>
              <SelectDropdown
                :options="repositoryTemplates"
                :value="repositoryTemplate"
                :optionRenderer="repositoryTemplateOptionRenderer"
                @change="repositoryTemplate = $event"
                @close="showColumnInfo = false"
                e2eValue="e2e-DD-newInventoryModal-inventoryTemplate"
              />
              <div v-if="showColumnInfo" class="absolute -right-64 w-60 bg-white border border-radius p-4 min-h-[10rem]">
                <div v-if="loadingHoveredRow" class="flex absolute top-0 left-0 items-center justify-center w-full flex-grow h-full z-10">
                  <img src="/images/medium/loading.svg" alt="Loading" />
                </div>
                <template v-else>
                  <div class="flex gap-4 overflow-hidden items-centers">
                    <div class="truncate font-bold">{{  hoveredRow.name }}</div>
                  </div>
                  <template v-if="hoveredRow.columns?.length !== 0">
                    <div class="flex items-center gap-0.5 overflow-hidden text-xs" v-for="column in hoveredRow.columns">
                      <span class="truncate shrink-c">{{ column[0] }}</span>
                      <span>-</span>
                      <span class="truncate shrink-0">{{ column[1] }}</span>
                    </div>
                  </template>
                  <template v-else>
                    {{ i18n.t('repositories.index.modal_create.only_system_defined_columns') }}
                  </template>
                </template>
              </div>
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal" data-e2e="e2e-BT-newInventoryModal-cancel">{{ i18n.t('general.cancel') }}</button>
            <button class="btn btn-primary" type="submit" :disabled="submitting || !validName || (repositoryTemplatesAvailable && !repositoryTemplate)" data-e2e="e2e-BT-newInventoryModal-create">
              {{ i18n.t('repositories.index.modal_create.submit') }}
            </button>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
/* global HelperModule GLOBAL_CONSTANTS */

import escapeHtml from '../../shared/escape_html.js';
import axios from '../../../packs/custom_axios.js';
import modalMixin from '../../shared/modal_mixin';
import SelectDropdown from '../../shared/select_dropdown.vue';

import {
  repository_templates_path,
  list_repository_columns_repository_template_path
} from '../../../routes.js';

export default {
  name: 'NewRepositoryModal',
  components: {
    SelectDropdown
  },
  props: {
    createUrl: String
  },
  mixins: [modalMixin],
  data() {
    return {
      name: '',
      error: null,
      submitting: false,
      repositoryTemplates: [],
      repositoryTemplate: null,
      showColumnInfo: false,
      hoveredRow: {},
      loadingHoveredRow: false
    };
  },
  created() {
    this.fetctRepositoryTemplates();
  },
  mounted() {
    document.addEventListener('mouseover', this.loadColumnsInfo);
  },
  beforeDestroy() {
    document.removeEventListener('mouseover', this.loadColumnsInfo);
  },
  computed: {
    repositoryTemplateUrl() {
      return repository_templates_path();
    },
    repositoryTemplatesAvailable() {
      return this.repositoryTemplates && this.repositoryTemplates.length !== 0;
    },
    validName() {
      return this.name.length >= GLOBAL_CONSTANTS.NAME_MIN_LENGTH;
    }
  },
  methods: {
    listRepositoryTemplateColumnsUrl(repositoryTemplateId) {
      return list_repository_columns_repository_template_path(repositoryTemplateId);
    },
    submit() {
      this.submitting = true;

      axios.post(this.createUrl, {
        repository: {
          name: this.name,
          repository_template_id: this.repositoryTemplate
        }
      }).then((response) => {
        this.error = null;
        this.$emit('create');
        this.submitting = false;
        HelperModule.flashAlertMsg(response.data.message, 'success');
      }).catch((error) => {
        this.submitting = false;
        this.error = error.response.data.name;
      });
    },
    repositoryTemplateOptionRenderer(row) {
      return `
        <div class="flex items-center gap-4 w-full">
          <div class="grow overflow-hidden">
            <div class="truncate" >${escapeHtml(row[1])}</div>
          </div>
          <i class="sn-icon sn-icon-info show-items-columns" title="" data-item-id="${row[0]}"></i>
        </div>`;
    },
    fetctRepositoryTemplates() {
      axios.get(this.repositoryTemplateUrl)
        .then((response) => {
          this.repositoryTemplates = response.data.data;
          if (this.repositoryTemplates.length !== 0) [this.repositoryTemplate] = this.repositoryTemplates[0];
        });
    },
    loadColumnsInfo(e) {
      if (!e.target.classList.contains('show-items-columns')) {
        this.showColumnInfo = false;
        this.hoveredRow = {};
        return;
      }

      this.loadingHoveredRow = true;

      this.showColumnInfo = true;

      axios.get(this.listRepositoryTemplateColumnsUrl(e.target.dataset.itemId))
        .then((response) => {
          this.loadingHoveredRow = false;
          this.hoveredRow = {
            name: response.data.name,
            columns: response.data.columns
          };
        });

      e.stopPropagation();
      e.preventDefault();
    }
  }
};
</script>
