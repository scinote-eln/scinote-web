<template>
  <section id="assigned-section" class="flex flex-col" ref="assignedSectionRef">
    <div
      class="flex flex-row text-lg font-semibold w-[350px] mb-6 leading-7 items-center justify-between transition-colors duration-300"
      ref="assigned-label"
      id="assigned-label"
      data-e2e="e2e-TX-itemCard-assigned"
      >
      {{ i18n.t('repositories.item_card.section.assigned', {
        count: assignedModules ?
          assignedModules.total_assigned_size : 0
      }) }}
      <a v-if="!rowArchived"
        class="btn-text-link font-normal" :class="{ disabled: assignToCurrentTask?.disabled }"
        @click="handleAssignClick" data-e2e="e2e-TL-repoItemSB-assignToTask">
        {{ i18n.t('repositories.item_card.assigned.assign') }}
      </a>
    </div>
    <div v-if="assignedModules && assignedModules.total_assigned_size > 0" class="flex flex-col gap-4">
      <div v-if="privateModuleSize() > 0" class="flex flex-col gap-4">
        <div class="text-sn-dark-grey">{{ i18n.t('repositories.item_card.assigned.private',
          { count: privateModuleSize() }) }}
        </div>
        <div class="sci-divider" :class="{ 'hidden': assignedModules?.viewable_modules?.length == 0 }">
        </div>
      </div>
      <div v-for="(assigned, index) in assignedModules.viewable_modules" :key="`assigned_module_${index}`"
        class="flex flex-col w-[350px] h-auto gap-4">
        <div class="flex flex-col gap-2">
          <div v-for="(item, index_assigned) in assigned" :key="`assigned_element_${index_assigned}`">
            {{ i18n.t(`repositories.item_card.assigned.labels.${item.type}`) }}
            <a :href="item.url" class="text-sn-science-blue hover:text-sn-science-blue hover:no-underline">
              {{ item.archived ? i18n.t('labels.archived') : '' }} {{ item.value }}
            </a>
          </div>
        </div>
        <div class="sci-divider"
          :class="{ 'hidden': index === assignedModules?.viewable_modules?.length - 1 }"></div>
      </div>
    </div>
    <div v-else class="text-sn-dark-grey">
      {{ i18n.t('repositories.item_card.assigned.empty') }}
    </div>

    <Teleport to="body">
      <AssignToTasksModal
        v-if="showAssignModal"
        :rowsToAssign="[rowId]"
        :repositoryId="repository.id"
        @reloadTable="showAssignModal = false"
        @close="showAssignModal = false"/>
    </Teleport>
  </section>
</template>

<script>
/* global HelperModule */

import axios from '../../packs/custom_axios.js';
import AssignToTasksModal from '../repository/modals/assign_to_tasks.vue';
import { assigned_modules_repository_repository_row_path } from '../../routes.js';

export default {
  name: 'RepositoryItemAssignedModules',
  components: {
    AssignToTasksModal
  },
  inject: ['syncTableRow'],
  props: {
    repository: { type: Object, required: true },
    rowId: { type: [Number, String], required: true },
    rowArchived: { type: Boolean, default: false },
    // present only when the sidebar was opened from within a specific task's assigned-items
    // view ({ url, disabled }) - lets "Assign" directly add the row to that task instead of
    // opening the general project/experiment/task picker modal
    assignToCurrentTask: { type: Object, default: null }
  },
  data() {
    return {
      assignedModules: null,
      showAssignModal: false
    };
  },
  created() {
    this.load();
  },
  methods: {
    load() {
      if (!this.repository?.id || !this.rowId) return Promise.resolve();

      return axios.get(assigned_modules_repository_repository_row_path(this.repository.id, this.rowId))
        .then((response) => {
          this.assignedModules = response.data;
          this.syncTableRow({ id: this.rowId, assigned_tasks_count: this.assignedModules.total_assigned_size });
        });
    },
    privateModuleSize() {
      return this.assignedModules.total_assigned_size - this.assignedModules.viewable_modules.length;
    },
    handleAssignClick() {
      if (!this.assignToCurrentTask) {
        this.showAssignModal = true;
        return;
      }
      if (this.assignToCurrentTask.disabled) return;

      axios.post(this.assignToCurrentTask.url, { repository_row_id: this.rowId })
        .then((response) => {
          HelperModule.flashAlertMsg(response.data.flash, 'success');
          window.assignedItemsTable?.$refs?.assignedItems?.loadAssingedRepositories();
          this.load();
        })
        .catch((error) => {
          HelperModule.flashAlertMsg(error.response?.data?.flash, 'danger');
        });
    }
  }
};
</script>
