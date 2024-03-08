<template>
  <transition enter-from-class="translate-x-full w-0"
              enter-active-class="transition-all ease-sharp duration-[588ms]"
              leave-active-class="transition-all ease-sharp duration-[588ms]"
              leave-to-class="translate-x-full w-0"
              v-click-outside="handleOutsideClick">
    <div ref="wrapper" v-show="isShowing" id="repository-item-sidebar-wrapper"
      class='items-sidebar-wrapper bg-white gap-2.5 self-stretch rounded-tl-4 rounded-bl-4 sn-shadow-menu-lg h-full w-[565px]'>

      <div id="repository-item-sidebar" class="w-full h-full pl-6 bg-white flex flex-col">

        <div ref="stickyHeaderRef" id="sticky-header-wrapper"
          class="sticky top-0 right-0 bg-white flex z-50 flex-col h-[78px] pt-6">
          <div class="header flex w-full h-[30px] pr-6">
            <repository-item-sidebar-title v-if="defaultColumns"
              :editable="permissions.can_manage && !defaultColumns?.archived"
              :name="defaultColumns.name"
              :archived="defaultColumns.archived"
              @update="update"
              data-e2e="e2e-TX-repoItemSB-title">
            </repository-item-sidebar-title>
            <i id="close-icon" @click="toggleShowHideSidebar(null)"
              class="sn-icon sn-icon-close ml-auto cursor-pointer my-auto mx-0"></i>
          </div>
          <div id="divider" class="w-500 bg-sn-light-grey flex items-center self-stretch h-px mt-6 mr-6"></div>
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

              <!-- INFORMATION -->
              <section id="information-section">
                <div ref="information-label" id="information-label"
                  class="font-inter text-lg font-semibold leading-7 mb-6 transition-colors duration-300">{{
                    i18n.t('repositories.item_card.section.information') }}
                </div>
                <div v-if="defaultColumns">
                  <div class="flex flex-col gap-4">
                    <!-- REPOSITORY NAME -->
                    <div class="flex flex-col ">
                      <span class="inline-block font-semibold pb-[6px]">{{
                        i18n.t('repositories.item_card.default_columns.repository_name') }}</span>
                      <span class="repository-name text-sn-dark-grey line-clamp-3" :title="repository?.name" data-e2e="e2e-TX-repoItemSBinformation-inventory">
                        {{ repository?.name }}
                      </span>
                    </div>

                    <div class="sci-divider"></div>

                    <!-- CODE -->
                    <div class="flex flex-col ">
                      <span class="inline-block font-semibold pb-[6px]">{{
                        i18n.t('repositories.item_card.default_columns.id')
                      }}</span>
                      <span class="inline-block text-sn-dark-grey line-clamp-3" :title="defaultColumns?.code" data-e2e="e2e-TX-repoItemSBinformation-itemID">
                        {{ defaultColumns?.code }}
                      </span>
                    </div>

                    <div class="sci-divider"></div>

                    <!-- ADDED ON -->
                    <div class="flex flex-col ">
                      <span class="inline-block font-semibold pb-[6px]">{{
                        i18n.t('repositories.item_card.default_columns.added_on')
                      }}</span>
                      <span class="inline-block text-sn-dark-grey" :title="defaultColumns?.added_on" data-e2e="e2e-TX-repoItemSBinformation-addedOn">
                        {{ defaultColumns?.added_on }}
                      </span>
                    </div>

                    <div class="sci-divider"></div>

                    <!-- ADDED BY -->
                    <div class="flex flex-col ">
                      <span class="inline-block font-semibold pb-[6px]">{{
                        i18n.t('repositories.item_card.default_columns.added_by')
                      }}</span>
                      <span class="inline-block text-sn-dark-grey line-clamp-3" :title="defaultColumns?.added_by" data-e2e="e2e-TX-repoItemSBinformation-addedBy">
                        {{ defaultColumns?.added_by }}
                      </span>
                    </div>

                    <!-- ARCHIVED ON -->
                    <div v-if="defaultColumns.archived_on" class="flex flex-col ">
                      <div class="sci-divider pb-4"></div>
                      <span class="inline-block font-semibold pb-[6px]">{{
                        i18n.t('repositories.item_card.default_columns.archived_on')
                      }}</span>
                      <span class="inline-block text-sn-dark-grey" :title="defaultColumns.archived_on" data-e2e="e2e-TX-repoItemSBinformation-archivedOn">
                        {{ defaultColumns.archived_on }}
                      </span>
                    </div>

                    <!-- ARCHIVED BY -->
                    <div v-if="defaultColumns.archived_by" class="flex flex-col ">
                      <div class="sci-divider pb-4"></div>
                      <span class="inline-block font-semibold pb-[6px]">{{
                        i18n.t('repositories.item_card.default_columns.archived_by')
                      }}</span>
                      <span class="inline-block text-sn-dark-grey" :title="defaultColumns.archived_by.full_name" data-e2e="e2e-TX-repoItemSBinformation-archivedBy">
                        {{ defaultColumns.archived_by.full_name }}
                      </span>
                    </div>
                  </div>
                </div>
              </section>

              <div id="divider" class="w-500 bg-sn-light-grey flex items-center self-stretch h-px "></div>

              <!-- CUSTOM COLUMNS, RELATIONSHIPS, ASSIGNED, QR CODE -->
              <div id="custom-col-assigned-qr-wrapper" class="flex flex-col gap-6">

                <!-- CUSTOM COLUMNS -->
                <section id="custom-columns-section" class="flex flex-col min-h-[64px] h-auto">
                  <div ref="custom-columns-label" id="custom-columns-label"
                    class="font-inter text-lg font-semibold leading-7 mb-6 transition-colors duration-300">
                    {{ i18n.t('repositories.item_card.custom_columns_label') }}
                  </div>
                  <CustomColumns :customColumns="customColumns" :repositoryRowId="repositoryRowId"
                    :repositoryId="repository?.id" :inArchivedRepositoryRow="defaultColumns?.archived"
                    :permissions="permissions" :updatePath="updatePath" :actions="actions" @update="update" />
                </section>

                <div id="divider" class="w-500 bg-sn-light-grey flex px-8 items-center self-stretch h-px"></div>

                <!-- RELATIONSHIPS -->
                <section v-if="!repository?.is_snapshot" id="relationships-section" class="flex flex-col" ref="relationshipsSectionRef">
                  <div ref="relationships-label" id="relationships-label"
                    class="font-inter text-lg font-semibold leading-7 mb-6 transition-colors duration-300">
                    {{ i18n.t('repositories.item_card.section.relationships') }}
                  </div>
                  <div class="font-inter text-sm leading-5 w-full">
                    <div class="flex flex-row justify-between mb-4">
                      <div class="font-semibold" data-e2e="e2e-TX-repoItemSBrelationships-parents">
                        {{ i18n.t('repositories.item_card.relationships.parents.count', { count: parentsCount || 0 }) }}
                      </div>
                      <a
                        v-if="permissions.can_connect_rows"
                        class="relationships-add-link btn-text-link font-normal"
                        @click="handleOpenAddRelationshipsModal($event, 'parent')"
                        data-e2e="e2e-TL-repoItemSBrelationships-addParents"
                        >
                        {{ i18n.t('repositories.item_card.add_relationship_button_text') }}
                      </a>
                    </div>
                    <div v-if="parentsCount">
                      <details v-for="(parent) in parents" @toggle="updateOpenState(parent.code, $event.target.open)" :key="parent.code" class="flex flex-col font-normal gap-4 group cursor-default">
                        <summary class="flex flex-row gap-3 mb-4 relative group">
                          <img :src="icons.delimiter_path" class="w-3 h-3 cursor-pointer flex-shrink-0 relative top-1"
                               :class="{ 'rotate-90': relationshipDetailsState[parent.code] }" />
                          <span>
                            <span>{{ i18n.t('repositories.item_card.relationships.item') }}</span>
                            <a :href="parent.path" class="record-info-link btn-text-link !text-sn-science-blue">{{ parent.name }}</a>
                            <button v-if="permissions.can_connect_rows" @click="openUnlinkModal(parent)"
                                    class=" ml-2 bg-transparent border-none opacity-0 group-hover:opacity-100 cursor-pointer">
                              <img :src="icons.unlink_path" />
                            </button>
                          </span>
                        </summary>
                        <p class="flex flex-col gap-3 ml-6 mb-4">
                          <span>
                            {{ i18n.t('repositories.item_card.relationships.id', { code: parent.code }) }}
                          </span>
                          <span>
                            <span>{{ i18n.t('repositories.item_card.relationships.inventory') }}</span>
                            <a :href="parent.repository_path" class="btn-text-link !text-sn-science-blue">
                              {{ parent.repository_name }}
                            </a>
                          </span>
                        </p>
                      </details>
                    </div>
                    <div v-else class="text-sn-dark-grey max-h-5">
                      {{ i18n.t('repositories.item_card.relationships.parents.empty') }}
                    </div>
                  </div>

                  <div class="sci-divider pb-4"></div>

                  <div class="font-inter text-sm leading-5 w-full">
                    <div class="flex flex-row justify-between" :class="{ 'mb-4': childrenCount }">
                      <div class="font-semibold" data-e2e="e2e-TX-repoItemSBrelationships-children">
                        {{ i18n.t('repositories.item_card.relationships.children.count', { count: childrenCount || 0 }) }}
                      </div>
                      <a
                        v-if="permissions.can_connect_rows"
                        class="relationships-add-link btn-text-link font-normal"
                        @click="handleOpenAddRelationshipsModal($event, 'child')"
                        data-e2e="e2e-TL-repoItemSBrelationships-addChildren"
                        >
                        {{ i18n.t('repositories.item_card.add_relationship_button_text') }}
                      </a>
                    </div>
                    <div v-if="childrenCount">
                      <details v-for="(child) in children" :key="child.code" @toggle="updateOpenState(child.code, $event.target.open)"
                               class="flex flex-col font-normal gap-4 group-last-of-type:[&>p:last-child]:mb-0">
                        <summary class="flex flex-row gap-3 mb-4 relative group"
                                 :class="{ 'group-last-of-type:mb-0': !relationshipDetailsState[child.code] }">
                          <img :src="icons.delimiter_path" class="w-3 h-3 flex-shrink-0 cursor-pointer relative top-1"
                               :class="{ 'rotate-90': relationshipDetailsState[child.code] }"/>
                          <span class="group/child">
                            <span>{{ i18n.t('repositories.item_card.relationships.item') }}</span>
                            <a :href="child.path" class="record-info-link btn-text-link !text-sn-science-blue">{{ child.name }}</a>
                            <button v-if="permissions.can_connect_rows" @click="openUnlinkModal(child)"
                                    class="ml-2 bg-transparent border-none opacity-0 group-hover:opacity-100 cursor-pointer">
                              <img :src="icons.unlink_path" />
                            </button>
                          </span>
                        </summary>
                        <p class="flex flex-col gap-3 ml-6 mb-4">
                          <span>{{ i18n.t('repositories.item_card.relationships.id', { code: child.code }) }}</span>
                          <span>
                            <span>{{ i18n.t('repositories.item_card.relationships.inventory') }}</span>
                            <a :href="child.repository_path" class="btn-text-link !text-sn-science-blue">
                              {{ child.repository_name }}
                            </a>
                          </span>
                        </p>
                      </details>
                    </div>
                    <div v-else class="text-sn-dark-grey max-h-5">
                      {{ i18n.t('repositories.item_card.relationships.children.empty') }}
                    </div>
                  </div>
                </section>

                <div v-if="!repository?.is_snapshot" id="divider" class="w-500 bg-sn-light-grey flex px-8 items-center self-stretch h-px"></div>

                <!-- ASSIGNED -->
                <section v-if="!repository?.is_snapshot" id="assigned-section" class="flex flex-col" ref="assignedSectionRef">
                  <div
                    class="flex flex-row text-lg font-semibold w-[350px] mb-6 leading-7 items-center justify-between transition-colors duration-300"
                    ref="assigned-label"
                    id="assigned-label"
                    data-e2e="e2e-TX-repoItemSB-assigned"
                    >
                    {{ i18n.t('repositories.item_card.section.assigned', {
                      count: assignedModules ?
                        assignedModules.total_assigned_size : 0
                    }) }}
                    <a v-if="!defaultColumns?.archived && (inRepository || actions?.assign_repository_row)"
                      class="btn-text-link font-normal" :class="{
                        'assign-inventory-button': actions?.assign_repository_row,
                        'disabled': actions?.assign_repository_row && actions.assign_repository_row.disabled
                      }"
                      :data-assign-url="actions?.assign_repository_row ? actions.assign_repository_row.assign_url : ''"
                      :data-repository-row-id="repositoryRowId" @click="showRepositoryAssignModal" data-e2e="e2e-TL-repoItemSBassigned-assignToTask">
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
                </section>

                <div v-if="!repository?.is_snapshot" id="divider" class="w-500 bg-sn-light-grey flex px-8 items-center self-stretch h-px  "></div>

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
            :class="{ 'pb-6': customColumns?.length }">
            <div id="divider" class="w-500 bg-sn-light-grey flex px-8 items-center self-stretch h-px mb-6"></div>
            <div id="bottom-button-wrapper" class="flex h-10 justify-end">
              <button type="button" class="btn btn-primary print-label-button" data-e2e="e2e-BT-repoItemSB-print"
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
    <unlink-modal v-if="selectedToUnlink" @cancel="closeUnlinkModal" @unlink="unlinkItem" />
  </Teleport>
</template>

<script>
/* global HelperModule I18n */

import { vOnClickOutside } from '@vueuse/components';
import InlineEdit from '../shared/inline_edit.vue';
import ScrollSpy from './repository_values/ScrollSpy.vue';
import CustomColumns from './customColumns.vue';
import RepositoryItemSidebarTitle from './Title.vue';
import UnlinkModal from './unlink_modal.vue';
import axios from '../../packs/custom_axios.js';

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
    labelAlias: 'QR_label',
    label: 'QR-label',
    sectionId: 'qr-section',
    showInSnapshot: true
  }
];

export default {
  name: 'RepositoryItemSidebar',
  components: {
    CustomColumns,
    'repository-item-sidebar-title': RepositoryItemSidebarTitle,
    'inline-edit': InlineEdit,
    'scroll-spy': ScrollSpy,
    'unlink-modal': UnlinkModal
  },
  directives: {
    'click-outside': vOnClickOutside
  },
  data() {
    return {
      currentItemUrl: null,
      updatePath: null,
      dataLoading: false,
      repositoryRowId: null,
      repository: null,
      defaultColumns: null,
      customColumns: null,
      parentsCount: 0,
      childrenCount: 0,
      parents: null,
      children: null,
      assignedModules: null,
      isShowing: false,
      barCodeSrc: null,
      permissions: {},
      repositoryRowUrl: null,
      actions: null,
      myModuleId: null,
      inRepository: false,
      icons: null,
      notification: null,
      relationshipDetailsState: {},
      selectedToUnlink: null,
      initialSectionId: null,
      loadingError: false
    };
  },
  provide() {
    return {
      reloadRepoItemSidebar: this.reload
    };
  },
  created() {
    window.repositoryItemSidebarComponent = this;
  },
  computed: {
    repositoryRowName() {
      return this.defaultColumns?.archived ? `${I18n.t('labels.archived')} ${this.defaultColumns?.name}` : this.defaultColumns?.name;
    }
  },
  watch: {
    parents(newParents) {
      newParents.forEach((parent) => {
        this.relationshipDetailsState[parent.code] = false;
      });
    },
    children(newChildren) {
      newChildren.forEach((child) => {
        this.relationshipDetailsState[child.code] = false;
      });
    }
  },
  mounted() {
    // Add a click event listener to the document
    this.inRepository = $('.assign-items-to-task-modal-container').length > 0;
  },
  beforeUnmount() {
    delete window.repositoryItemSidebarComponent;
  },
  methods: {
    filterNavigationItems() {
      if (this.repository.is_snapshot) {
        return items.filter((item) => item.showInSnapshot);
      }
      return items;
    },
    handleOpenAddRelationshipsModal(event, relation) {
      event.stopPropagation();
      event.preventDefault();
      const addRelationCallback = (data, connectionRelation) => {
        if (connectionRelation === 'parent') {
          this.parentsCount = data.parents.length;
          this.parents = data.parents;
        }
        if (connectionRelation === 'child') {
          this.childrenCount = data.children.length;
          this.children = data.children;
        }
      };
      window.repositoryItemRelationshipsModal.show(
        {
          relation,
          addRelationCallback,
          optionUrls: { ...this.actions.row_connections },
          notificationIconPath: this.icons.notification_path,
          notification: this.notification,
          canConnectRows: this.permissions.can_connect_rows
        }
      );
    },
    handleOutsideClick(event) {
      if (!this.isShowing) return;

      const allowedSelectors = [
        'a',
        '.modal',
        '.dp__instance_calendar',
        '.label-printing-progress-modal',
        '.atwho-view',
        '.sn-select-dropdown'
      ];

      const excludeSelectors = ['#myModuleRepositoryFullViewModal'];

      const isOutsideSidebar = !$(event.target).parents('#repository-item-sidebar-wrapper').length;
      const isAllowedClick = !allowedSelectors.some((selector) => event.target.closest(selector));
      const isExcludedClick = excludeSelectors.some((selector) => event.target.closest(selector));

      if (isOutsideSidebar && (isAllowedClick || isExcludedClick)) {
        this.toggleShowHideSidebar(null);
      }
    },
    toggleShowHideSidebar(repositoryRowUrl, myModuleId = null, initialSectionId = null) {
      // opening from a bootstrap modal - should close the modal upon itemcard open
      this.handleOpeningFromBootstrapModal();
      if (initialSectionId) {
        this.initialSectionId = initialSectionId;
      } else this.initialSectionId = null;

      // initial click
      if (this.currentItemUrl === null) {
        this.myModuleId = myModuleId;
        this.isShowing = true;
        this.loadRepositoryRow(repositoryRowUrl);
        this.currentItemUrl = repositoryRowUrl;
        return;
      }
      // same item click
      if (repositoryRowUrl === this.currentItemUrl) {
        if (this.isShowing) {
          this.toggleShowHideSidebar(null);
        }
        return;
      }
      // explicit close (from emit)
      if (repositoryRowUrl === null) {
        this.isShowing = false;
        this.currentItemUrl = null;
        this.myModuleId = null;
        return;
      }
      // click on a different item - if the item card is already showing should just fetch new data
      this.isShowing = true;
      this.myModuleId = myModuleId;
      this.loadRepositoryRow(repositoryRowUrl);
      this.currentItemUrl = repositoryRowUrl;
    },
    handleOpeningFromBootstrapModal() {
      const layout = document.querySelector('.sci--layout');
      const openModals = layout.querySelectorAll('.modal.in:not(.modal-full-screen)');
      openModals.forEach((modal) => $(modal).modal('hide'));
    },
    loadRepositoryRow(repositoryRowUrl, scrollTop = 0) {
      this.dataLoading = true;
      this.loadingError = false;
      if (this.defaultColumns?.name) {
        this.defaultColumns.name = '';
      }
      axios.get(
        repositoryRowUrl,
        { params: { my_module_id: this.myModuleId } }
      ).then((response) => {
        const result = response.data;
        this.repositoryRowId = result.id;
        this.repository = result.repository;
        this.optionsPath = result.options_path;
        this.updatePath = result.update_path;
        this.defaultColumns = result.default_columns;
        this.parentsCount = result.relationships.parents_count;
        this.childrenCount = result.relationships.children_count;
        this.parents = result.relationships.parents;
        this.children = result.relationships.children;
        this.customColumns = result.custom_columns;
        this.assignedModules = result.assigned_modules;
        this.permissions = result.permissions;
        this.actions = result.actions;
        this.icons = result.icons;
        this.dataLoading = false;
        this.notification = result.notification;
        this.$nextTick(() => {
          this.generateBarCode(this.defaultColumns.code);

          // if scrollTop was provided, scroll to it
          this.$nextTick(() => { this.$refs.bodyWrapper.scrollTop = scrollTop; });
        });
      }).catch(() => {
        this.loadingError = true;
        this.dataLoading = false;
      });
    },
    reload() {
      if (this.isShowing) {
        // perserve scrollTop on reload
        this.loadRepositoryRow(this.currentItemUrl, this.$refs.bodyWrapper.scrollTop);
      }
    },
    showRepositoryAssignModal() {
      if (this.inRepository) {
        window.AssignItemsToTaskModalComponentContainer.showModal([this.repositoryRowId]);
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
    privateModuleSize() {
      return this.assignedModules.total_assigned_size - this.assignedModules.viewable_modules.length;
    },
    update(params) {
      axios.put(
        this.updatePath,
        {
          id: this.id,
          ...params
        }
      ).then((response) => {
        const result = response.data;
        if (result) {
          this.customColumns = this.customColumns.map((col) => (col.id === result.id ? { ...col, ...result } : col));
          if ($('.dataTable.repository-dataTable')[0]) $('.dataTable.repository-dataTable').DataTable().ajax.reload(null, false);
        }
      });
    },
    updateOpenState(code, isOpen) {
      this.relationshipDetailsState[code] = isOpen;
    },
    openUnlinkModal(item) {
      this.selectedToUnlink = item;
    },
    closeUnlinkModal() {
      this.selectedToUnlink = null;
    },
    async unlinkItem() {
      try {
        await axios.delete(this.selectedToUnlink.unlink_path);
        HelperModule.flashAlertMsg(
          I18n.t(
            'repositories.item_card.relationships.unlink_modal.success',
            { from_connection: this.defaultColumns.name, to_connection: this.selectedToUnlink.name }
          ),
          'success'
        );
        this.loadRepositoryRow(this.currentItemUrl);
        if ($('.dataTable.repository-dataTable')[0]) $('.dataTable.repository-dataTable').DataTable().ajax.reload(null, false);
      } catch {
        HelperModule.flashAlertMsg(
          I18n.t(
            'repositories.item_card.relationships.unlink_modal.error',
            { from_connection: this.defaultColumns.name, to_connection: this.selectedToUnlink.name }
          ),
          'danger'
        );
      } finally {
        this.selectedToUnlink = null;
      }
    }
  }
};
</script>
