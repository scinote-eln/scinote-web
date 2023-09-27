<template>
  <div id="repository-item-sidebar" class="w-ful h-full bg-white flex flex-col relative">
    <div class="header fixed w-full">
      <div class="flex justify-between m-6 h-[31px]">
        <h4 class="my-auto truncate" :title="defaultColumns?.name">
          {{ !defaultColumns?.archived ? i18n.t('labels.archived') : '' }}
          {{ defaultColumns?.name }}
        </h4>
        <i @click="toggleShowHideSidebar" class="sn-icon sn-icon-close ml-auto cursor-pointer my-auto mx-0"></i>
      </div>
    </div>

    <div id="divider" class="bg-sn-sleepy-grey flex mt-[79px] mx-6 items-center self-stretch h-px"></div>
    <div class="overflow-auto content flex flex-col justify-between px-6 h-full relative scroll-smooth">
      <aside class="navigations fixed top-28 right-6">
        <nav class="w-full">
          <ul class="flex flex-col gap-3 text-right list-none">
            <li v-for="nav in navigations" :key="nav.value" class="cursor-pointer inline-block relative">
              <span :class="`${activeNav === nav.value ? 'text-sn-science-blue' : 'text-sn-grey'} mr-8 transition-colors`"
                @click.prevent="hightlightContent(nav.value)">
                {{ nav.label }}
              </span>
              <span
                :class="`${activeNav === nav.value ? 'bg-sn-science-blue w-1 inset-y-0 right-0.5' : 'transparent hidden'} absolute transition-all rounded`">
              </span>
            </li>
          </ul>
        </nav>
      </aside>
      <div id="body-wrapper" class="grow-1">
        <div class="flex flex-col gap-4 mb-4 mt-4 w-[350px]">
          <section id="information_wrapper">
            <h4 class="font-inter text-base font-semibold leading-7 mb-4">
              {{ i18n.t('repositories.item_card.title.information') }}
            </h4>
            <div class="flex flex-col gap-4">
              <div class="flex flex-col ">
                <span class="inline-block font-semibold pb-[6px]">{{
                  i18n.t('repositories.item_card.default_columns.repository_name') }}</span>
                <span class="text-sn-dark-grey line-clamp-3" :title="repositoryName">
                  {{ repositoryName }}
                </span>
              </div>

              <div id="dashed-divider" class="flex h-[1px] py-0  border-dashed border-[1px] border-sn-light-grey"></div>

              <div class="flex flex-col ">
                <span class="inline-block font-semibold pb-[6px]">{{ i18n.t('repositories.item_card.default_columns.id')
                }}</span>
                <span class="inline-block text-sn-dark-grey">
                  {{ defaultColumns?.code }}
                </span>
              </div>

              <div id="dashed-divider" class="flex h-[1px] py-0  border-dashed border-[1px] border-sn-light-grey"></div>

              <div class="flex flex-col ">
                <span class="inline-block font-semibold pb-[6px]">{{
                  i18n.t('repositories.item_card.default_columns.added_on')
                }}</span>
                <span class="inline-block text-sn-dark-grey">
                  {{ defaultColumns?.added_on }}
                </span>
              </div>

              <div id="dashed-divider" class="flex h-[1px] py-0  border-dashed border-[1px] border-sn-light-grey"></div>

              <div class="flex flex-col ">
                <span class="inline-block font-semibold pb-[6px]">{{
                  i18n.t('repositories.item_card.default_columns.added_by')
                }}</span>
                <span class="inline-block text-sn-dark-grey">
                  {{ defaultColumns?.added_by }}
                </span>

              </div>
            </div>
          </section>

          <div id="divider" class="w-500 bg-sn-light-grey flex items-center self-stretch h-px	"></div>

          <section id="custom_columns_wrapper" class="flex flex-col min-h-[64px] h-auto">
            <h4 id="custom-columns-label" class="font-inter text-base font-semibold leading-7 pb-4">
              {{ i18n.t('repositories.item_card.navigations.custom_columns') }}
            </h4>
            <!-- start of custom columns -->
            <div v-if="customColumns?.length > 0" class="flex flex-col gap-4 w-[350px] h-auto">
              <div v-for="(column, index) in customColumns" class="flex flex-col gap-4 w-[350px] h-auto">

                <component :is="column.data_type" :key="index" :data_type="column.data_type" :colId="column.id"
                  :colName="column.name" :colVal="column.value" />

                <div id="dashed-divider" :class="{ 'hidden': index === customColumns.length - 1 }"
                  class="flex h-[1px] py-0 border-dashed border-[1px] border-sn-light-grey">
                </div>

              </div>
            </div>
            <!-- end of custom columns -->
            <div v-else id="custom-columns-value" class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
              {{ i18n.t('repositories.item_card.no_custom_columns_label') }}
            </div>
          </section>

          <div id="divider" class="w-500 bg-sn-light-grey flex px-8 items-center self-stretch h-px	"></div>

          <section id="assigned_wrapper" class="flex flex-col ">
            <div class="text-base font-semibold w-[350px] my-3 leading-7">
              {{ i18n.t('repositories.item_card.section.assigned', { count: assignedModules ? assignedModules.total_assigned_size : 0 }) }}
            </div>
            <div v-if="assignedModules && assignedModules.total_assigned_size > 0">
              <div v-if="privateModuleSize() > 0" class="pb-6">
                {{ i18n.t('repositories.item_card.assigned.private', { count: privateModuleSize() }) }}
                <hr v-if="assignedModules.viewable_modules.length > 0"
                    class="h-1 w-[350px] m-0 mt-6 border-dashed border-1 border-sn-light-grey"/>
              </div>
              <div v-for="(assigned, index) in assignedModules.viewable_modules" 
                   :key="`assigned_module_${index}`"
                   class="flex flex-col w-[350px] mb-6 h-auto">
                <div class="flex flex-col gap-3">
                  <div v-for="(item, index_assigned) in assigned"
                       :key="`assigned_element_${index_assigned}`">
                    {{ i18n.t(`repositories.item_card.assigned.labels.${item.type}`) }}
                    <a :href="item.url">
                      {{ item.archived ? i18n.t('labels.archived') : '' }} {{ item.value }}
                    </a>
                  </div>
                </div>
                <hr v-if="index < assignedModules.viewable_modules.length - 1" 
                    class="h-1 w-[350px] mt-6 mb-0 border-dashed border-1 border-sn-light-grey"/>
              </div>
            </div>
            <div v-else class="mb-3">
              {{ i18n.t('repositories.item_card.assigned.empty') }}
            </div>
          </section>

          <div id="divider" class="w-500 bg-sn-light-grey flex px-8 items-center self-stretch h-px	"></div>

          <section id="qr_wrapper">
            <h4 class="font-inter text-base font-semibold leading-7 mb-4 mt-0">{{
              i18n.t('repositories.item_card.navigations.qr') }}</h4>
            <div class="bar-code-container">
              <canvas id="bar-code-canvas" class="hidden"></canvas>
              <img id="bar-code-image" />
            </div>
          </section>
        </div>
      </div>

      <div class="footer">
        <div id="divider" class="w-full bg-sn-sleepy-grey flex items-center self-stretch h-px mb-6"></div>
        <div id="bottom-button-wrapper" class="flex mb-6 justify-end">
          <button type="button" class="btn btn-primary print-label-button" :data-rows="JSON.stringify([repositoryRowId])">
            {{ i18n.t('repository_row.modal_print_label.print_label') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import RepositoryStockValue from './repository_values/RepositoryStockValue.vue';
import RepositoryTextValue from './repository_values/RepositoryTextValue.vue';
import RepositoryNumberValue from './repository_values/RepositoryNumberValue.vue';
import RepositoryAssetValue from './repository_values/RepositoryAssetValue.vue';
import RepositoryListValue from './repository_values/RepositoryListValue.vue';
import RepositoryChecklistValue from './repository_values/RepositoryChecklistValue.vue';
import RepositoryStatusValue from './repository_values/RepositoryStatusValue.vue';
import RepositoryDateTimeValue from './repository_values/RepositoryDateTimeValue.vue';
import RepositoryDateTimeRangeValue from './repository_values/RepositoryDateTimeRangeValue.vue';
import RepositoryDateValue from './repository_values/RepositoryDateValue.vue';
import RepositoryDateRangeValue from './repository_values/RepositoryDateRangeValue.vue';
import RepositoryTimeRangeValue from './repository_values/RepositoryTimeRangeValue.vue'
import RepositoryTimeValue from './repository_values/RepositoryTimeValue.vue'

export default {
  name: 'RepositoryItemSidebar',
  components: {
    RepositoryStockValue,
    RepositoryTextValue,
    RepositoryNumberValue,
    RepositoryAssetValue,
    RepositoryListValue,
    RepositoryChecklistValue,
    RepositoryStatusValue,
    RepositoryDateTimeValue,
    RepositoryDateTimeRangeValue,
    RepositoryDateValue,
    RepositoryDateRangeValue,
    RepositoryTimeRangeValue,
    RepositoryTimeValue
  },
  data() {
    return {
      repositoryRowId: null,
      repositoryName: null,
      defaultColumns: null,
      customColumns: null,
      assignedModules: null,
      isShowing: false,
      navClicked: false,
      activeNav: 'information',
      sequenceExpanded: false,
      barCodeSrc: null
    }
  },
  created() {
    window.repositoryItemSidebarComponent = this;
  },
  watch: {
    isShowing(newVal, oldVal) {
      const element = document.getElementById('repositoryItemSidebar')
      if (this.isShowing) {
        element.classList.remove('translate-x-full');
        element.classList.add('translate-x-0');
      } else {
        element.classList.add('transition-transform', 'ease-in-out', 'duration-300', 'transform', 'translate-x-0', 'translate-x-full');
      }
    }
  },
  computed: {
    navigations() {
      return ['information', 'custom_columns', 'assigned', 'qr'].map(nav => (
        { label: I18n.t(`repositories.item_card.navigations.${nav}`), value: nav }
      ));
    }
  },
  beforeDestroy() {
    delete window.repositoryItemSidebarComponent;
  },
  methods: {
    toggleShowHideSidebar(repositoryRowUrl) {
      this.isShowing = !this.isShowing
      this.loadRepositoryRow(repositoryRowUrl);
    },
    toggleExpandSequence() {
      if (this.sequenceExpanded) {
        document.getElementById('sequence-container').classList.remove('h-fit', 'max-h-[600px]')
        document.getElementById('sequence-container').classList.add('h-[60px]')
      } else {
        document.getElementById('sequence-container').classList.remove('h-[60px]')
        document.getElementById('sequence-container').classList.add('h-fit', 'max-h-[600px]')
      }
      this.sequenceExpanded = !this.sequenceExpanded
    },
    loadRepositoryRow(repositoryRowUrl) {
      $.ajax({
        method: 'GET',
        url: repositoryRowUrl,
        dataType: 'json',
        success: (result) => {
          this.repositoryRowId = result.id;
          this.repositoryName = result.repository_name;
          this.defaultColumns = result.default_columns;
          this.customColumns = result.custom_columns;
          this.assignedModules = result.assigned_modules;
          this.$nextTick(() => {
            this.generateBarCode(this.defaultColumns.code);
            this.attachScrollEvent();
          });
        }
      });
    },
    hightlightContent(nav) {
      this.activeNav = nav;
      this.navClicked = true;
      this.$nextTick(function () {
        $(`#repository-item-sidebar #${nav}_wrapper`)[0].scrollIntoView();
      })
    },
    attachScrollEvent() {
      const topOffsets = {}
      const sections = ['information', 'custom_columns', 'assigned', 'qr'];
      for (let idx = 0; idx < sections.length; idx++) {
        topOffsets[sections[idx]] = $(`#repository-item-sidebar #${sections[idx]}_wrapper`).offset().top;
      }
      let isScrolling;
      $('.content').on('scroll', () => {
        if (isScrolling !== null) clearTimeout(isScrolling);
        isScrolling = setTimeout(() => {
          const scrollPosition = $('.content').scrollTop();
          for (let idx = 0; idx < sections.length; idx++) {
            if (scrollPosition < topOffsets[sections[idx + 1]] - topOffsets['information']) {
              // Set nav only when scrolling is not triggered by ckicking nav
              if (sections[idx] !== this.activeNav && !this.navClicked) this.activeNav = sections[idx];
              break;
            }
          }
          this.navClicked = false;
        }, 150)
      })
    },
    generateBarCode(text) {
      if (!text) return;

      const barCodeCanvas = bwipjs.toCanvas('bar-code-canvas', {
        bcid: 'qrcode',
        text,
        scale: 3
      });
      $('#repository-item-sidebar #bar-code-image').attr('src', barCodeCanvas.toDataURL('image/png'));
    },
    privateModuleSize() {
      return this.assignedModules.total_assigned_size - this.assignedModules.viewable_modules.length;
    }
  }
}
</script>
