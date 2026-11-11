<template>
  <transition enter-from-class="translate-x-full w-0"
              enter-active-class="transition-all ease-sharp duration-[588ms]"
              leave-active-class="transition-all ease-sharp duration-[588ms]"
              leave-to-class="translate-x-full w-0"
              v-click-outside="handleOutsideClick">
    <div ref="wrapper" v-show="isShowing" id="repository-item-sidebar-wrapper"
      class='items-sidebar-wrapper bg-white gap-2.5 self-stretch rounded-tl-4 rounded-bl-4 sn-shadow-menu-lg h-full w-[565px]'>

      <NewItem v-if="newItemRepositoryId" ref="newItem" :key="newItemKey"
        :repositoryId="newItemRepositoryId"
        @created="onNewItemCreated"
        @close="toggleShowHideSidebar(null)" />

      <div v-else id="repository-item-sidebar" data-e2e="e2e-CO-itemCard" class="w-full h-full pl-6 bg-white flex flex-col">

        <div ref="stickyHeaderRef" id="sticky-header-wrapper"
          class="sticky top-0 right-0 bg-white flex z-50 flex-col pt-6">
          <div class="header flex w-full h-[30px] pr-6">
            <repository-item-sidebar-title v-if="row"
              :editable="permissions.can_manage && !row?.archived"
              :name="row.name"
              :archived="row.archived"
              @update="updateTitle"
              data-e2e="e2e-TX-itemCard-title">
            </repository-item-sidebar-title>
            <i id="close-icon" data-e2e="e2e-BT-itemCard-close" @click="toggleShowHideSidebar(null)"
              class="sn-icon sn-icon-close ml-auto cursor-pointer my-auto mx-0"></i>
          </div>
          <div v-if="snapshotAt" class="text-sn-grey mt-2">
            {{ i18n.t('repositories.item_card.snapshot_label', { timestamp: snapshotAt, name: snapshotByName }) }}
          </div>
          <div id="divider" class="bg-sn-light-grey flex items-center self-stretch h-px mt-5 mr-6"></div>
        </div>

        <div ref="bodyWrapper" id="body-wrapper" class="overflow-y-auto overflow-x-hidden h-[calc(100%-78px)] pt-6 ">
          <div v-if="dataLoading" class="h-full flex flex-grow-1">
            <div class="sci-loader"></div>
          </div>

          <div v-else-if="!dataLoading && loadingError" class="h-full flex flex-grow-1">
            <div class="flex flex-col items-center justify-center h-full pr-6 mx-14">
              <i class=" text-sn-alert-passion sn-icon sn-icon-large sn-icon-alert-warning"></i>
              <div class="text-center">
                <h4 class="font-inter text-lg mt-3">{{ i18n.t('repositories.item_card.errors.load_error_header') }}</h4>
                <div class="font-inter text-sm">{{ i18n.t('repositories.item_card.errors.load_error_description') }}</div>
              </div>
            </div>
          </div>

          <div v-else class="flex flex-1 flex-grow-1 justify-between" ref="scrollSpyContent" id="scrollSpyContent">

            <div id="left-col" class="flex flex-col gap-6 max-w-[350px]">

              <default-columns :row="row" :repository="repository" />

              <div id="divider" class="bg-sn-light-grey flex items-center self-stretch h-px "></div>

              <!-- CUSTOM COLUMNS, RELATIONSHIPS, ASSIGNED, QR CODE -->
              <div id="custom-col-assigned-qr-wrapper" class="flex flex-col gap-6">

                <!-- MANDATORY COLUMNS -->
                <template v-if="mandatoryColumnDefs.length > 0">
                  <section id="mandatory-columns-section" class="flex flex-col min-h-[64px] h-auto"
                    data-e2e="e2e-CO-itemCard-mandatoryColumns">
                    <div ref="mandatory-columns-label" id="mandatory-columns-label"
                      class="font-inter text-lg font-semibold leading-7 mb-6 transition-colors duration-300">
                      {{ i18n.t('repositories.item_card.mandatory_columns_label') }}
                    </div>
                    <div class="flex flex-col gap-4 w-[350px] h-auto">
                      <div v-for="(columnDef, index) in mandatoryColumnDefs" :key="columnDef.id" class="flex flex-col gap-4 w-[350px] h-auto relative">
                        <div class="flex items-center justify-between">
                          <div class="font-semibold">
                            {{ columnDef.name }}<span class="text-sn-alert-passion" data-e2e="e2e-TX-itemCard-mandatory">*</span>
                          </div>
                        </div>
                        <sidebar-cell-renderer
                          :row="row"
                          :columnDef="columnDef"
                          :repositoryId="repository?.id"
                          @updateCell="handleCellUpdate"
                          @updateRow="handleRowReplace" />
                        <div class="sci-divider" :class="{ 'hidden': index === mandatoryColumnDefs.length - 1 }"></div>
                      </div>
                    </div>
                  </section>

                  <div id="divider" class="bg-sn-light-grey flex px-8 items-center self-stretch h-px"></div>
                </template>

                <!-- CUSTOM COLUMNS -->
                <section id="custom-columns-section" class="flex flex-col min-h-[64px] h-auto">
                  <div ref="custom-columns-label" id="custom-columns-label"
                    class="font-inter text-lg font-semibold leading-7 mb-6 transition-colors duration-300">
                    {{ i18n.t('repositories.item_card.custom_columns_label') }}
                  </div>
                  <div v-if="customColumnDefs.length > 0" class="flex flex-col gap-4 w-[350px] h-auto">
                    <div v-for="(columnDef, index) in customColumnDefs" :key="columnDef.id" class="flex flex-col gap-4 w-[350px] h-auto relative">
                      <div class="flex items-center justify-between">
                        <div class="font-semibold">{{ columnDef.name }}</div>
                        <a v-if="columnDef.data_type === 'RepositoryStockValue' && permissions.can_export_repository_stock && row?.stock?.value?.stock_formatted"
                          class="btn-text-link font-normal"
                          @click="showExportConsumptionModal = true" data-e2e="e2e-BT-itemCard-stockExport">
                          {{ i18n.t('repositories.item_card.stock_export') }}
                        </a>
                      </div>
                      <sidebar-cell-renderer
                        :row="row"
                        :columnDef="columnDef"
                        :repositoryId="repository?.id"
                        @updateCell="handleCellUpdate"
                        @updateRow="handleRowReplace" />
                      <div class="sci-divider" :class="{ 'hidden': index === customColumnDefs.length - 1 }"></div>
                    </div>
                  </div>
                  <div v-else class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
                    {{ i18n.t('repositories.item_card.no_custom_columns_label') }}
                  </div>
                </section>

                <div id="divider" class="bg-sn-light-grey flex px-8 items-center self-stretch h-px"></div>

                <relationships v-if="repository && !repository.is_snapshot"
                  :repository="repository"
                  :rowId="repositoryRowId"
                  :rowName="row?.name"
                  :permissions="permissions"
                  :icons="icons"
                  :notification="notification" />

                <div v-if="!repository?.is_snapshot" id="divider" class="bg-sn-light-grey flex px-8 items-center self-stretch h-px"></div>

                <assigned-modules v-if="repository && !repository.is_snapshot"
                  :repository="repository"
                  :rowId="repositoryRowId"
                  :rowArchived="row?.archived"
                  :assignToCurrentTask="assignToCurrentTask" />

                <div v-if="!repository?.is_snapshot" id="divider" class="bg-sn-light-grey flex px-8 items-center self-stretch h-px  "></div>
                <!-- Locations -->
                <section v-if="!repository?.is_snapshot" id="locations-section" ref="locationsSectionRef" data-e2e="e2e-CO-itemCard-locations">
                  <Locations :row="row" :repository="repository" :permissions="permissions" />
                </section>
                <div v-if="!repository?.is_snapshot" id="divider" class="bg-sn-light-grey flex px-8 items-center self-stretch h-px  "></div>

                <!-- Schedule -->
                <section v-if="!repository?.is_snapshot" id="schedule-section" ref="scheduleSectionRef" data-e2e="e2e-CO-itemCard-schedule">
                  <Schedule :repositoryRow="repositoryRow" :repository="repository" @reloadRow="reload" />
                </section>
                <div v-if="!repository?.is_snapshot" id="divider" class="bg-sn-light-grey flex px-8 items-center self-stretch h-px  "></div>

                <!-- QR -->
                <section id="qr-section" ref="QR-label">
                  <div id="QR-label" class="font-inter text-lg font-semibold leading-7 mb-6 mt-0 transition-colors duration-300">
                    {{ i18n.t('repositories.item_card.section.qr') }}
                  </div>
                  <div class="bar-code-container">
                    <canvas id="bar-code-canvas" class="hidden"></canvas>
                    <img :src="barCodeSrc" class="w-[90px]" />
                  </div>
                </section>
              </div>
            </div>

            <!-- NAVIGATION -->
            <div v-if="isShowing && !dataLoading" ref="navigationRef" id="navigation"
              class="flex item-end gap-x-4 min-w-[130px] min-h-[130px] h-fit sticky top-0 pr-6 [scrollbar-gutter:stable_both-edges] ">

              <scroll-spy v-show="isShowing" :itemsToCreate="filterNavigationItems()" :initialSectionId="initialSectionId" />
            </div>
          </div>

          <!-- BOTTOM -->
          <div id="bottom" v-show="!dataLoading && !loadingError" class="h-[100px] flex flex-col justify-end mt-4 mr-6"
            :class="{ 'pb-6': columnDefs?.length }">
            <div id="divider" class="bg-sn-light-grey flex px-8 items-center self-stretch h-px mb-6"></div>
            <div id="bottom-button-wrapper" class="flex h-10 justify-end">
              <button type="button" class="btn btn-primary print-label-button" data-e2e="e2e-BT-itemCard-print"
                :data-rows="JSON.stringify([repositoryRowId])"
                :data-repository-id="repository?.id">
                {{ i18n.t('repositories.item_card.print_label') }}
              </button>
            </div>
          </div>
        </div>

      </div>
    </div>
  </transition>

  <Teleport to="body">
    <ExportConsumptionModal
      v-if="showExportConsumptionModal"
      :repository="{ id: repository.id, attributes: { name: repository.name } }"
      :rows="[repositoryRowId]"
      @close="showExportConsumptionModal = false"/>
  </Teleport>
</template>

<script>
/* global I18n */

import { vOnClickOutside } from '@vueuse/components';
import InlineEdit from '../shared/inline_edit.vue';
import ScrollSpy from './scroll_spy.vue';
import SidebarCellRenderer from './sidebar_cell_renderer.vue';
import RepositoryItemSidebarTitle from './title.vue';
import DefaultColumns from './default_columns.vue';
import Relationships from './relationships.vue';
import AssignedModules from './assigned_modules.vue';
import Locations from './locations.vue';
import Schedule from './schedule.vue';
import NewItem from './new_item.vue';
import ExportConsumptionModal from '../repository/modals/export_stock_consumption_modal.vue';
import axios from '../../packs/custom_axios.js';
import { repository_repository_row_path } from '../../routes.js';

const items = [
  {
    id: 'highlight-item-1',
    textId: 'text-item-1',
    labelAlias: 'information_label',
    label: 'information-label',
    sectionId: 'information-section',
    showInSnapshot: true
  },
  {
    id: 'highlight-item-mandatory',
    textId: 'text-item-mandatory',
    labelAlias: 'mandatory_columns_label',
    label: 'mandatory-columns-label',
    sectionId: 'mandatory-columns-section',
    showInSnapshot: true,
    onlyWithMandatoryColumns: true
  },
  {
    id: 'highlight-item-2',
    textId: 'text-item-2',
    labelAlias: 'custom_columns_label',
    label: 'custom-columns-label',
    sectionId: 'custom-columns-section',
    showInSnapshot: true
  },
  {
    id: 'highlight-item-3',
    textId: 'text-item-3',
    labelAlias: 'relationships_label',
    label: 'relationships-label',
    sectionId: 'relationships-section',
    showInSnapshot: false
  },
  {
    id: 'highlight-item-4',
    textId: 'text-item-4',
    labelAlias: 'assigned_label',
    label: 'assigned-label',
    sectionId: 'assigned-section',
    showInSnapshot: false
  },
  {
    id: 'highlight-item-5',
    textId: 'text-item-5',
    labelAlias: 'locations_label',
    label: 'locations-label',
    sectionId: 'locations-section',
    showInSnapshot: false
  },
  {
    id: 'highlight-item-6',
    textId: 'text-item-6',
    labelAlias: 'schedule_label',
    label: 'schedule-label',
    sectionId: 'schedule-section',
    showInSnapshot: false
  },
  {
    id: 'highlight-item-7',
    textId: 'text-item-7',
    labelAlias: 'QR_label',
    label: 'QR-label',
    sectionId: 'qr-section',
    showInSnapshot: true
  }
];

export default {
  name: 'RepositoryItemSidebar',
  components: {
    SidebarCellRenderer,
    DefaultColumns,
    Relationships,
    AssignedModules,
    Locations,
    Schedule,
    NewItem,
    ExportConsumptionModal,
    'repository-item-sidebar-title': RepositoryItemSidebarTitle,
    'inline-edit': InlineEdit,
    'scroll-spy': ScrollSpy
  },
  directives: {
    'click-outside': vOnClickOutside
  },
  data() {
    return {
      currentItemUrl: null,
      dataLoading: false,
      repositoryRowId: null,
      repository: null,
      row: null,
      repositoryRow: null,
      columnDefs: [],
      isShowing: false,
      showExportConsumptionModal: false,
      barCodeSrc: null,
      permissions: {},
      repositoryRowUrl: null,
      myModuleId: null,
      assignToCurrentTask: null,
      icons: null,
      notification: null,
      initialSectionId: null,
      loadingError: false,
      snapshotAt: null,
      snapshotByName: null,
      newItemRepositoryId: null,
      newItemKey: 0,
      onNewItemCreated: null
    };
  },
  provide() {
    return {
      reloadRepoItemSidebar: this.reload,
      syncTableRow: this.syncTableRow
    };
  },
  created() {
    window.repositoryItemSidebarComponent = this;

    this.handleItemLandingPageLink();
  },
  computed: {
    repositoryRowName() {
      return this.row?.archived ? `${I18n.t('labels.archived')} ${this.row?.name}` : this.row?.name;
    },
    mandatoryColumnDefs() {
      return this.columnDefs.filter((columnDef) => columnDef.mandatory);
    },
    customColumnDefs() {
      return this.columnDefs.filter((columnDef) => !columnDef.mandatory);
    },
    isSameRepository() {
      const openedRepositoryId = window.repositoryAssignTable?.repository?.id || window.repositoryTable?.repositoryId;

      if (openedRepositoryId) {
        return this.repository?.id === openedRepositoryId;
      }
      return false;
    }
  },
  beforeUnmount() {
    delete window.repositoryItemSidebarComponent;
  },
  methods: {
    filterNavigationItems() {
      return items.filter((item) => (
        (!this.repository.is_snapshot || item.showInSnapshot)
        && (!item.onlyWithMandatoryColumns || this.mandatoryColumnDefs.length > 0)
      ));
    },
    handleOutsideClick(event) {
      if (!this.isShowing) return;

      const allowedSelectors = [
        'a',
        '.modal',
        '.dp--instance-calendar',
        '.dp--outer-menu-wrap',
        '.label-printing-progress-modal',
        '.atwho-view',
        '.sn-select-dropdown',
        '.dp--action-button'
      ];

      const excludeSelectors = ['#myModuleRepositoryFullViewModal'];

      const isOutsideSidebar = !event.target.closest('#repository-item-sidebar-wrapper');
      const isAllowedClick = !allowedSelectors.some((selector) => event.target.closest(selector));
      const isExcludedClick = excludeSelectors.some((selector) => event.target.closest(selector));

      if (isOutsideSidebar && (isAllowedClick || isExcludedClick)) {
        this.toggleShowHideSidebar(null);
      }
    },
    async toggleShowHideSidebar(repositoryRowUrl, myModuleId = null, initialSectionId = null) {
      if (this.newItemRepositoryId) {
        if (this.isShowing && !(await this.$refs.newItem.confirmDiscard())) return;
        if (repositoryRowUrl === null) {
          this.isShowing = false;
          return;
        }
        this.newItemRepositoryId = null;
      }

      this.handleOpeningFromBootstrapModal();
      if (initialSectionId) {
        this.initialSectionId = initialSectionId;
      } else this.initialSectionId = null;

      if (this.currentItemUrl === null) {
        this.myModuleId = myModuleId;
        this.isShowing = true;
        this.loadRepositoryRow(repositoryRowUrl);
        this.currentItemUrl = repositoryRowUrl;
        return;
      }
      if (repositoryRowUrl === this.currentItemUrl) {
        if (this.isShowing) {
          this.toggleShowHideSidebar(null);
        }
        return;
      }
      if (repositoryRowUrl === null) {
        this.isShowing = false;
        this.currentItemUrl = null;
        this.myModuleId = null;
        return;
      }
      this.isShowing = true;
      this.myModuleId = myModuleId;
      this.loadRepositoryRow(repositoryRowUrl);
      this.currentItemUrl = repositoryRowUrl;
    },
    async openNewItemCard(repositoryId, onCreated) {
      if (this.newItemRepositoryId && this.isShowing && !(await this.$refs.newItem.confirmDiscard())) return;

      this.currentItemUrl = null;
      this.myModuleId = null;
      this.onNewItemCreated = onCreated;
      this.newItemRepositoryId = repositoryId;
      this.newItemKey += 1;
      this.isShowing = true;
    },
    handleOpeningFromBootstrapModal() {
      const layout = document.querySelector('.sci--layout');
      const openModals = layout.querySelectorAll('.modal.in:not(.modal-full-screen)');
      openModals.forEach((modal) => $(modal).modal('hide'));
    },
    loadRepositoryRow(repositoryRowUrl, scrollTop = 0) {
      this.dataLoading = true;
      this.loadingError = false;
      if (this.row?.name) {
        this.row.name = '';
      }
      return axios.get(
        repositoryRowUrl,
        { params: { my_module_id: this.myModuleId } }
      ).then((response) => {
        const result = response.data;
        this.repositoryRow = result;
        this.repositoryRowId = result.id;
        this.repository = result.repository;
        this.row = result.row;
        this.columnDefs = result.column_defs;
        this.permissions = result.permissions;
        this.assignToCurrentTask = result.assign_to_current_task;
        this.icons = result.icons;
        this.notification = result.notification;
        this.snapshotByName = result.snapshot_by_name;
        this.snapshotAt = result.snapshot_at;
        this.dataLoading = false;

        this.$nextTick(() => {
          this.generateBarCode(this.row.code);

          this.$nextTick(() => { this.$refs.bodyWrapper.scrollTop = scrollTop; });

          if (window.location.hash) {
            this.$nextTick(() => window.location = window.location);
          }
        });
      }).catch(() => {
        this.loadingError = true;
        this.dataLoading = false;
      });
    },
    reload() {
      if (this.isShowing && this.currentItemUrl) {
        this.loadRepositoryRow(this.currentItemUrl, this.$refs.bodyWrapper.scrollTop);
      }
    },
    syncTableRow(updatedRow) {
      if (!this.isSameRepository) return;

      if (window.repositoryAssignTable) {
        window.repositoryAssignTable.updateRowData(updatedRow);
      } else {
        window.repositoryTable?.updateRowData(updatedRow);
      }
    },
    generateBarCode(text) {
      if (!text) return;
      const barCodeCanvas = bwipjs.toCanvas('bar-code-canvas', {
        bcid: 'qrcode',
        text,
        scale: 3
      });
      this.barCodeSrc = barCodeCanvas.toDataURL('image/png');
    },
    updateTitle(params) {
      axios.patch(
        repository_repository_row_path(this.repository.id, this.repositoryRowId),
        params
      ).then((response) => {
        const row = response.data.data;
        if (this.row) this.row.name = row.attributes.name;
        if (this.isSameRepository) {
          this.syncTableRow(row);
          window.assignedItemsTable?.$refs?.assignedItems?.loadAssingedRepositories();
        }
      });
    },
    handleCellUpdate({ field, result, activeRemindersCount }) {
      this.row[field] = result;
      if (this.isSameRepository) {
        const updatedRow = { id: this.repositoryRowId, [field]: result };
        if (activeRemindersCount !== undefined) {
          updatedRow.active_reminders_count = activeRemindersCount;
        }
        this.syncTableRow(updatedRow);
        window.assignedItemsTable?.$refs?.assignedItems?.loadAssingedRepositories();
      }
    },
    handleRowReplace(newRow) {
      Object.assign(this.row, newRow.attributes ? { ...newRow.attributes, id: newRow.id } : newRow);
      this.syncTableRow(newRow);
    },
    handleItemLandingPageLink() {
      const itemLandingPageLink = document.getElementById('itemLandingPagelink');
      if (itemLandingPageLink) {
        this.toggleShowHideSidebar(itemLandingPageLink.getAttribute('href'));
      }
    }
  }
};
</script>
