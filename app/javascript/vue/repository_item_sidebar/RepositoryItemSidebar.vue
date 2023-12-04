<template>
  <transition enter-from-class="translate-x-full w-0"
              enter-active-class="transition-all ease-sharp duration-[588ms]"
              leave-active-class="transition-all ease-sharp duration-[588ms]"
              leave-to-class="translate-x-full w-0">
    <div ref="wrapper" v-show="isShowing" id="repository-item-sidebar-wrapper"
      class='items-sidebar-wrapper bg-white gap-2.5 self-stretch rounded-tl-4 rounded-bl-4 shadow-lg h-full w-[565px]'>

      <div id="repository-item-sidebar" class="w-full h-full pl-6 bg-white flex flex-col">

        <div ref="stickyHeaderRef" id="sticky-header-wrapper"
          class="sticky top-0 right-0 bg-white flex z-50 flex-col h-[78px] pt-6">
          <div class="header flex w-full h-[30px] pr-6">
            <repository-item-sidebar-title v-if="defaultColumns"
              :editable="permissions?.can_manage && !defaultColumns?.archived"
              :name="defaultColumns.name"
              :archived="defaultColumns.archived"
              @update="update">
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

          <div v-else class="flex flex-1 flex-grow-1 justify-between" ref="scrollSpyContent" id="scrollSpyContent">

            <div id="left-col" class="flex flex-col gap-4 max-w-[350px]">

              <!-- INFORMATION -->
              <section id="information-section">
                <div ref="information-label" id="information-label"
                  class="font-inter text-lg font-semibold leading-7 mb-4 transition-colors duration-300">{{
                    i18n.t('repositories.item_card.section.information') }}
                </div>
                <div v-if="defaultColumns">
                  <div class="flex flex-col gap-4">
                    <!-- REPOSITORY NAME -->
                    <div class="flex flex-col ">
                      <span class="inline-block font-semibold pb-[6px]">{{
                        i18n.t('repositories.item_card.default_columns.repository_name') }}</span>
                      <span class="repository-name text-sn-dark-grey line-clamp-3" :title="repository?.name">
                        {{ repository?.name }}
                      </span>
                    </div>

                    <div class="sci-divider"></div>

                    <!-- CODE -->
                    <div class="flex flex-col ">
                      <span class="inline-block font-semibold pb-[6px]">{{
                        i18n.t('repositories.item_card.default_columns.id')
                      }}</span>
                      <span class="inline-block text-sn-dark-grey line-clamp-3" :title="defaultColumns?.code">
                        {{ defaultColumns?.code }}
                      </span>
                    </div>

                    <div class="sci-divider"></div>

                    <!-- ADDED ON -->
                    <div class="flex flex-col ">
                      <span class="inline-block font-semibold pb-[6px]">{{
                        i18n.t('repositories.item_card.default_columns.added_on')
                      }}</span>
                      <span class="inline-block text-sn-dark-grey" :title="defaultColumns?.added_on">
                        {{ defaultColumns?.added_on }}
                      </span>
                    </div>

                    <div class="sci-divider"></div>

                    <!-- ADDED BY -->
                    <div class="flex flex-col ">
                      <span class="inline-block font-semibold pb-[6px]">{{
                        i18n.t('repositories.item_card.default_columns.added_by')
                      }}</span>
                      <span class="inline-block text-sn-dark-grey line-clamp-3" :title="defaultColumns?.added_by">
                        {{ defaultColumns?.added_by }}
                      </span>
                    </div>

                    <!-- ARCHIVED ON -->
                    <div v-if="defaultColumns.archived_on" class="flex flex-col ">
                      <div class="sci-divider pb-4"></div>
                      <span class="inline-block font-semibold pb-[6px]">{{
                        i18n.t('repositories.item_card.default_columns.archived_on')
                      }}</span>
                      <span class="inline-block text-sn-dark-grey" :title="defaultColumns.archived_on">
                        {{ defaultColumns.archived_on }}
                      </span>
                    </div>

                    <!-- ARCHIVED BY -->
                    <div v-if="defaultColumns.archived_by" class="flex flex-col ">
                      <div class="sci-divider pb-4"></div>
                      <span class="inline-block font-semibold pb-[6px]">{{
                        i18n.t('repositories.item_card.default_columns.archived_by')
                      }}</span>
                      <span class="inline-block text-sn-dark-grey" :title="defaultColumns.archived_by.full_name">
                        {{ defaultColumns.archived_by.full_name }}
                      </span>
                    </div>
                  </div>
                </div>
              </section>

              <div id="divider" class="w-500 bg-sn-light-grey flex items-center self-stretch h-px "></div>

              <!-- CUSTOM COLUMNS, ASSIGNED, QR CODE -->
              <div id="custom-col-assigned-qr-wrapper" class="flex flex-col gap-4">

                <!-- CUSTOM COLUMNS -->
                <section id="custom-columns-section" class="flex flex-col min-h-[64px] h-auto">
                  <div ref="custom-columns-label" id="custom-columns-label"
                    class="font-inter text-lg font-semibold leading-7 pb-4 transition-colors duration-300">
                    {{ i18n.t('repositories.item_card.custom_columns_label') }}
                  </div>
                  <CustomColumns :customColumns="customColumns" :repositoryRowId="repositoryRowId"
                    :repositoryId="repository?.id" :inArchivedRepositoryRow="defaultColumns?.archived"
                    :permissions="permissions" :updatePath="updatePath" :actions="actions" @update="update" />
                </section>

                <div id="divider" class="w-500 bg-sn-light-grey flex px-8 items-center self-stretch h-px"></div>

                <!-- ASSIGNED -->
                <section id="assigned-section" class="flex flex-col" ref="assignedSectionRef">
                  <div
                    class="flex flex-row text-lg font-semibold w-[350px] pb-4 leading-7 items-center justify-between transition-colors duration-300"
                    ref="assigned-label"
                    id="assigned-label"
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
                      :data-repository-row-id="repositoryRowId" @click="showRepositoryAssignModal">
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

                <div id="divider" class="w-500 bg-sn-light-grey flex px-8 items-center self-stretch h-px  "></div>

                <!-- QR -->
                <section id="qr-section" ref="QR-label">
                  <div id="QR-label" class="font-inter text-lg font-semibold leading-7 mb-4 mt-0 transition-colors duration-300">
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
              <scroll-spy :itemsToCreate="[
                {
                  id: 'highlight-item-1',
                  textId: 'text-item-1',
                  labelAlias: 'information_label',
                  label: 'information-label',
                  sectionId: 'information-section'
                },
                {
                  id: 'highlight-item-2',
                  textId: 'text-item-2',
                  labelAlias: 'custom_columns_label',
                  label: 'custom-columns-label',
                  sectionId: 'custom-columns-section'
                },
                {
                  id: 'highlight-item-3',
                  textId: 'text-item-3',
                  labelAlias: 'assigned_label',
                  label: 'assigned-label',
                  sectionId: 'assigned-section'
                },
                {
                  id: 'highlight-item-4',
                  textId: 'text-item-4',
                  labelAlias: 'QR_label',
                  label: 'QR-label',
                  sectionId: 'qr-section'
                }
              ]" v-show="isShowing">
              </scroll-spy>
            </div>
          </div>

          <!-- BOTTOM -->
          <div id="bottom" v-show="!dataLoading" class="h-[100px] flex flex-col justify-end mt-4 mr-6"
            :class="{ 'pb-6': customColumns?.length }">
            <div id="divider" class="w-500 bg-sn-light-grey flex px-8 items-center self-stretch h-px mb-6"></div>
            <div id="bottom-button-wrapper" class="flex h-10 justify-end">
              <button type="button" class="btn btn-primary print-label-button"
                :data-rows="JSON.stringify([repositoryRowId])">
                {{ i18n.t('repositories.item_card.print_label') }}
              </button>
            </div>
          </div>
        </div>

      </div>
    </div>
  </transition>
</template>

<script>
import InlineEdit from '../shared/inline_edit.vue';
import ScrollSpy from './repository_values/ScrollSpy.vue';
import CustomColumns from './customColumns.vue';
import RepositoryItemSidebarTitle from './Title.vue'

export default {
  name: 'RepositoryItemSidebar',
  components: {
    CustomColumns,
    'repository-item-sidebar-title': RepositoryItemSidebarTitle,
    'inline-edit': InlineEdit,
    'scroll-spy': ScrollSpy,
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
      assignedModules: null,
      isShowing: false,
      barCodeSrc: null,
      permissions: null,
      repositoryRowUrl: null,
      actions: null,
      myModuleId: null,
      inRepository: false
    }
  },
  provide() {
    return {
      reloadRepoItemSidebar: this.reload,
    }
  },
  created() {
    window.repositoryItemSidebarComponent = this;
  },
  computed: {
    repositoryRowName() {
      return this.defaultColumns?.archived ? `${I18n.t('labels.archived')} ${this.defaultColumns?.name}` : this.defaultColumns?.name;
    }
  },
  mounted() {
    // Add a click event listener to the document
    document.addEventListener('mousedown', this.handleOutsideClick);
    this.inRepository = $('.assign-items-to-task-modal-container').length > 0;
  },
  beforeUnmount() {
    delete window.repositoryItemSidebarComponent;
    document.removeEventListener('mousedown', this.handleOutsideClick);
  },
  methods: {
    handleOutsideClick(event) {
      if (!this.isShowing) return

      // Check if the clicked element is not within the sidebar and it's not another item link or belogs to modals
      const selectors = ['a', '.modal', '.label-printing-progress-modal', '.atwho-view'];

      if (!$(event.target).parents('#repository-item-sidebar-wrapper').length &&
        !selectors.some(selector => event.target.closest(selector))) {
        this.toggleShowHideSidebar(null);
      }
    },
    toggleShowHideSidebar(repositoryRowUrl, myModuleId = null) {
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
    loadRepositoryRow(repositoryRowUrl) {
      this.dataLoading = true
      $.ajax({
        method: 'GET',
        url: repositoryRowUrl,
        data: { my_module_id: this.myModuleId },
        dataType: 'json',
        success: (result) => {
          this.repositoryRowId = result.id;
          this.repository = result.repository;
          this.optionsPath = result.options_path;
          this.updatePath = result.update_path;
          this.defaultColumns = result.default_columns;
          this.customColumns = result.custom_columns;
          this.assignedModules = result.assigned_modules;
          this.permissions = result.permissions;
          this.actions = result.actions;
          this.dataLoading = false;
          this.$nextTick(() => {
            this.generateBarCode(this.defaultColumns.code);
          });
        }
      });
    },
    reload() {
      if (this.isShowing) {
        this.loadRepositoryRow(this.currentItemUrl);
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
      $.ajax({
        method: 'PUT',
        url: this.updatePath,
        dataType: 'json',
        data: {
          id: this.id,
          ...params,
        },
      }).done((response) => {
        if (response) {
          this.customColumns = this.customColumns.map(col => col.id === response.id ? { ...col, ...response } : col)
          if ($('.dataTable')[0]) $('.dataTable').DataTable().ajax.reload(null, false);
        }
      });
    }
  }
}
</script>
