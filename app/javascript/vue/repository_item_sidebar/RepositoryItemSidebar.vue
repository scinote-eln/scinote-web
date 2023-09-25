<template>
  <div id="repository-item-sidebar" class="w-ful h-full py-6 px-6 bg-white flex flex-col">
    <div class="header flex w-full">
      <h4 class="item-name my-auto truncate" :title="defaultColumns?.name">
        {{ !defaultColumns?.archived ? i18n.t('labels.archived') : '' }}
        {{ defaultColumns?.name }}
      </h4>
      <i @click="toggleShowHideSidebar" class="sn-icon sn-icon-close ml-auto cursor-pointer my-auto mx-0"></i>
    </div>

    <div id="divider" class="w-500 bg-sn-light-grey flex my-6 items-center self-stretch h-px	"></div>

    <div id="body-wrapper" class="flex flex-1 justify-between">
      <div id="left-col" class="flex flex-col gap-4 mb-4">
        <div id="information">
          <div id="title" class="font-inter text-xl font-semibold leading-7 mb-4">{{
            i18n.t('repositories.item_card.title.information') }}</div>
          <div class="item-details">
            <div class="flex flex-col gap-4">
              <div class="flex flex-col ">
                <span class="inline-block font-semibold pb-[6px]">{{
                  i18n.t('repositories.item_card.default_columns.repository_name') }}</span>
                <span class="repository-name flex text-sn-dark-grey" :title="repositoryName">
                  {{ repositoryName }}
                </span>
              </div>

              <div id="dashed-divider" class="flex h-[1px] py-0  border-dashed border-[1px] border-sn-light-grey"></div>

              <div class="flex flex-col ">
                <span class="inline-block font-semibold pb-[6px]">{{ i18n.t('repositories.item_card.default_columns.id')
                }}</span>
                <span class="inline-block text-sn-dark-grey" :title="defaultColumns?.code">
                  {{ defaultColumns?.code }}
                </span>
              </div>

              <div id="dashed-divider" class="flex h-[1px] py-0  border-dashed border-[1px] border-sn-light-grey"></div>

              <div class="flex flex-col ">
                <span class="inline-block font-semibold pb-[6px]">{{
                  i18n.t('repositories.item_card.default_columns.added_on')
                }}</span>
                <span class="inline-block text-sn-dark-grey" :title="defaultColumns?.added_on">
                  {{ defaultColumns?.added_on }}
                </span>
              </div>

              <div id="dashed-divider" class="flex h-[1px] py-0  border-dashed border-[1px] border-sn-light-grey"></div>

              <div class="flex flex-col ">
                <span class="inline-block font-semibold pb-[6px]">{{
                  i18n.t('repositories.item_card.default_columns.added_by')
                }}</span>
                <span class="inline-block text-sn-dark-grey" :title="defaultColumns?.added_by">
                  {{ defaultColumns?.added_by }}
                </span>

              </div>
            </div>
          </div>
        </div>

        <div id="divider" class="w-500 bg-sn-light-grey flex items-center self-stretch h-px	"></div>

        <div id="custom-col-assigned-qr-wrapper" class="flex flex-col gap-4">
          <div id="custom-columns-wrapper" class="flex flex-col min-h-[64px] h-auto">

            <div id="custom-columns-label" class="font-inter text-base font-semibold leading-7 pb-4">Custom columns</div>
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
          </div>

          <div id="divider" class="w-500 bg-sn-light-grey flex px-8 items-center self-stretch h-px	"></div>

          <div id="assigned-wrapper" class="flex flex-col h-[64px] ">

            <div v-if="this.assigned" id="assigned-label" class="font-inter text-base font-semibold leading-7 pb-4">
              Assigned (3)
            </div>
            <div v-else class="flex justify-between">
              <div id="assigned-label" class="font-inter text-base font-semibold leading-7 pb-4">
                Assigned (0)
              </div>
              <div class="text-sn-blue hover:cursor-pointer text-right font-inter text-sm font-normal leading-5 h-fit">
                Assign to task
              </div>
            </div>
            <div id="assigned-value" class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
              {{ this.assigned }}
            </div>
          </div>

          <div id="divider" class="w-500 bg-sn-light-grey flex px-8 items-center self-stretch h-px	"></div>

          <section id="qr-wrapper">
            <h4 class="font-inter text-base font-semibold leading-7 mb-4 mt-0">{{ i18n.t('repositories.item_card.navigations.qr') }}</h4>
            <div class="bar-code-container">
              <canvas id="bar-code-canvas" class="hidden"></canvas>
              <img id="bar-code-image" />
            </div>
          </section>
        </div>
      </div>
      <div id="navigation" class="min-w-[130px] h-[130px] flex item-end gap-x-4	">
        <div class="flex flex-col py-2 px-0 gap-3 self-stretch w-[130px] h-[130px]  justify-center items-center">
          <div class="flex flex-col w-[130px] h-[130px] justify-between text-right">
            <div @click="handleSideNavClick" id="text-item-1" class="hover:cursor-pointer text-sn-grey">Information</div>
            <div @click="handleSideNavClick" id="text-item-2" class="hover:cursor-pointer text-sn-grey">Custom columns
            </div>
            <div @click="handleSideNavClick" id="text-item-3" class="hover:cursor-pointer text-sn-grey">Assigned</div>
            <div @click="handleSideNavClick" id="text-item-4" class="hover:cursor-pointer text-sn-grey">QR</div>
          </div>
        </div>
      </div>

      <highlight-component
        :items-to-create="['highlight-item-1', 'highlight-item-2', 'highlight-item-3', 'highlight-item-4']">
      </highlight-component>
    </div>

    <div id="bottom" class="h-[100px] flex flex-col justify-end" :class="{ 'pb-6': customColumns?.length }">
      <div id="divider" class="w-500 bg-sn-light-grey flex px-8 items-center self-stretch h-px mb-6"></div>
      <div id="bottom-button-wrapper" class="flex h-10 justify-end">
        <button type="button" class="btn btn-primary print-label-button" :data-rows="JSON.stringify([repositoryRowId])">
          {{ i18n.t('repository_row.modal_print_label.print_label') }}
        </button>
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
import HighlightComponent from './repository_values/HighlightComponent.vue';

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
    'highlight-component': HighlightComponent
  },
  data() {
    // using dummy data for now
    return {
      repositoryRowId: null,
      repositoryName: null,
      defaultColumns: null,
      customColumns: null,
      isShowing: false,
      sequenceExpanded: false,
      assigned: 'Assigned to 3 private tasks that will not be displayed',
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
          this.$nextTick(() => {
            this.generateBarCode(this.defaultColumns.code);
          });
        }
      });
    },
    // determine the identifier value according to the text-item (target) value
    handleSideNavClick(e) {
      let highlightItemId
      const targetId = e.target.id
      switch (targetId) {
        case 'text-item-1':
          highlightItemId = 'highlight-item-1'
          break
        case 'text-item-2':
          highlightItemId = 'highlight-item-2'
          break
        case 'text-item-3':
          highlightItemId = 'highlight-item-3'
          break
        case 'text-item-4':
          highlightItemId = 'highlight-item-4'
          break
        default: null
      }

      const arrOfBurgerItemIds = ['text-item-1', 'text-item-2', 'text-item-3', 'text-item-4']
      const arrOfBurgerHighlightItemIds = ['highlight-item-1', 'highlight-item-2', 'highlight-item-3', 'highlight-item-4']
      const arrToUnhighlight_1 = arrOfBurgerItemIds.filter((i) => i !== targetId)
      const arrToUnhighlight_2 = arrOfBurgerHighlightItemIds.filter((i) => i !== highlightItemId)

      // highlight the target text and corresponding identifier
      document.getElementById(targetId).classList.add('text-sn-science-blue')
      document.getElementById(highlightItemId).classList.add('bg-sn-science-blue')

      //unhighlight the rest of the text and identifiers
      arrToUnhighlight_1.forEach(id => document.getElementById(id).classList.remove('text-sn-science-blue'))
      arrToUnhighlight_2.forEach(id => document.getElementById(id).classList.remove('bg-sn-science-blue'))
    },
    generateBarCode(text) {
      if(!text) return;

      const barCodeCanvas = bwipjs.toCanvas('bar-code-canvas', {
        bcid: 'qrcode',
        text,
        scale: 3
      });
      $('#repository-item-sidebar #bar-code-image').attr('src', barCodeCanvas.toDataURL('image/png'));
    }
  }
}
</script>
