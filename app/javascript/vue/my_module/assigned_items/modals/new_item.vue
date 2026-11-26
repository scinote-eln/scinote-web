<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document" :data-e2e="`e2e-MD-${e2eValue}`">
      <form @submit.prevent="submit">
        <div class="modal-content">
          <div class="modal-header">
            <button
              type="button"
              class="close"
              data-dismiss="modal"
              aria-label="Close"
              :data-e2e="`e2e-BT-${e2eValue}-close`"
            >
              <i class="sn-icon sn-icon-close"></i>
            </button>
            <h4 class="modal-title truncate !block" :data-e2e="`e2e-TX-${e2eValue}-title`">
              {{ i18n.t('my_modules.assigned_items.create_modal.modal_title') }}
            </h4>
          </div>
          <div class="modal-body">
            <p class="mb-6" :data-e2e="`e2e-TX-${e2eValue}-description`">
              {{ i18n.t('my_modules.assigned_items.create_modal.description') }}
            </p>
            <div class="mb-6">
              <label class="sci-label" :data-e2e="`e2e-TX-${e2eValue}-selectInventoryLabel`">
                {{ i18n.t('my_modules.assigned_items.create_modal.inventory_label') }}
              </label>
              <SelectDropdown
                :optionsUrl="repositoriesUrl"
                :value="selectedRepository"
                :disabled="selectedRepositoryValue"
                @change="changeRepository"
                :searchable="true"
                :e2eValue="`e2e-DD-${e2eValue}-selectInventory`"
              />
            </div>
            <div class="mb-6">
              <label class="sci-label" :data-e2e="`e2e-TX-${e2eValue}-itemNameInputLabel`">
                {{ i18n.t('my_modules.assigned_items.create_modal.inventory_item_name') }}
              </label>
              <div class="sci-input-container-v2"
                   :data-e2e="`e2e-TX-${e2eValue}-itemNameError`">
                <input
                  type="text"
                  v-model="inventoryItemName"
                  :placeholder="i18n.t('my_modules.assigned_items.create_modal.inventory_item_name')"
                  :data-e2e="`e2e-IF-${e2eValue}-itemName`"
                >
              </div>
            </div>
            <div class="flex items-center gap-2.5">
                <span class="sci-checkbox-container">
                  <input type="checkbox"
                         class="sci-checkbox"
                         v-model="outputMarked"
                         :data-e2e="`e2e-CB-${e2eValue}`"
                  />
                  <span class="sci-checkbox-label"></span>
                </span>
                {{ i18n.t('my_modules.assigned_items.create_modal.checkbox_label') }}
              </div>
          </div>
          <div class="modal-footer">
            <button
              type="button"
              class="btn btn-secondary"
              data-dismiss="modal"
              :data-e2e="`e2e-BT-${e2eValue}-cancel`"
            >
              {{ i18n.t('general.cancel') }}
            </button>
            <button
              class="btn btn-primary"
              :disabled="!validObject" type="submit"
              :data-e2e="`e2e-BT-${e2eValue}-create`"
            >
              {{ i18n.t('my_modules.assigned_items.create_modal.continue') }}
            </button>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script>

import SelectDropdown from '../../../shared/select_dropdown.vue';
import modalMixin from '../../../shared/modal_mixin.js';
import {
  list_repositories_path
} from '../../../../routes.js';

export default {
  name: 'CreateItemModal',
  props: {
    myModuleId: String,
    selectedRepositoryValue: String,
    e2eValue: {
      type: String,
      default: ''
    }
  },
  emits: ['continue', 'close'],
  mixins: [modalMixin],
  components: {
    SelectDropdown
  },
  data() {
    return {
      selectedRepository: null,
      inventoryItemName: '',
      outputMarked: false
    };
  },
  computed: {
    validObject() {
      return this.selectedRepository && this.inventoryItemName.trim();
    },
    repositoriesUrl() {
      return list_repositories_path({ appendable: true });
    }
  },
  created() {
    this.teamId = document.body.dataset.currentTeamId;
    this.selectedRepository = parseInt(this.selectedRepositoryValue);
  },
  methods: {
    changeRepository(repository) {
      this.selectedRepository = repository;
    },
    submit() {
      this.$emit('continue', {
        repositoryId: this.selectedRepository,
        name: this.inventoryItemName.trim(),
        markAsOutput: this.outputMarked
      });
      this.close();
    }
  }
};
</script>
