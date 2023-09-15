<template>
    <div id="repository-item-sidebar" class="repository-item-sidebar w-full h-full px-4 bg-white flex flex-col">
      <div class="header flex w-full">
        <h4 class="item-name my-auto truncate" :title="repositoryRow.name">
          {{ !repositoryRow.archived ? i18n.t('labels.archived') : '' }}
          {{ repositoryRow.name }}
        </h4>
        <i @click="toggleShowHide" class="sn-icon sn-icon-close ml-auto cursor-pointer my-auto mx-0"></i>
      </div>
      <div class="body mt-4">
        <section id="information">
          <h4 class="title mb-0">{{ i18n.t('repositories.item_card.title.information') }}</h4>
          <div class="item-details">
            <div v-for="column in defaultColumns" class="flex flex-col py-3">
              <span class="inline-block font-semibold pb-2">{{ column.label }}</span>
              <span
                class="inline-block text-sn-dark-grey"
                :class="{ 'repository-name': column.label === 'Inventory'}"
                :title="column.label === 'Inventory' ? column.value : null"
              >
                {{ column.value }}
              </span>
            </div>
          </div>
        </section>
        <div>
          <div id="custom-columns-wrapper" class="flex flex-col min-h-[64px] h-auto">
  
            <div id="custom-columns-label" class="font-inter text-base font-semibold leading-7 mb-2">Custom columns</div>
            <div v-if="customColumns?.length > 0" class="flex flex-col gap-4 w-[350px] h-auto">
              <!-- start of custom columns -->
  
              <div id="" class="flex flex-col min-h-[46px] h-auto gap-[6px]">
                <div id="" class="flex justify-between">
                  <div class="font-inter text-sm font-semibold leading-5">Solvent stock</div>
                  <div class="font-inter text-sm font-normal leading-5 text-sn-blue cursor-pointer">Export</div>
                </div>
                <div id="">
                  <div v-if="this.customColumns[0]?.solventStock" class="flex flex-row justify-between">
                    <div class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
                      {{ this.customColumns[0]?.solventStock }}
                    </div>
                    <i class="sn-icon sn-icon-notifications"></i>
                  </div>
                  <div v-else>No stock</div>
                </div>
              </div>
              <div id="dashed-divider" class="flex h-[1px] py-0  border-dashed border-[1px] border-sn-light-grey"></div>
  
              <div id="" class="flex flex-col min-h-[46px] h-auto gap-[6px]">
                <div id="" class="font-inter text-sm font-semibold leading-5">Items in warehouse</div>
                <div id="" class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
                  {{ this.customColumns[0]?.itemsInWarehouse ? 'In stock' : 'No text' }}
                </div>
              </div>
              <div id="dashed-divider" class="flex h-[1px] py-0  border-dashed border-[1px] border-sn-light-grey"></div>
  
              <div id="" class="flex flex-col min-h-[46px] h-auto gap-[6px]">
                <div id="" class="font-inter text-sm font-semibold leading-5">Storage temperature</div>
                <div id="" class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
                  {{ this.customColumns[0]?.storageTemp || 'No text' }}
                </div>
              </div>
              <div id="dashed-divider" class="flex h-[1px] py-0  border-dashed border-[1px] border-sn-light-grey"></div>

              <div id="" class="flex flex-col min-h-[46px] h-auto gap-[6px]">
                <div id="" class="font-inter text-sm font-semibold leading-5">Sampling date & time range</div>
                <div id="" class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
                  {{ this.customColumns[0]?.samplingDateTimeRange || 'No date & time range' }}
                </div>
              </div>
              <div id="dashed-divider" class="flex h-[1px] py-0  border-dashed border-[1px] border-sn-light-grey"></div>
  
              <div id="" class="flex flex-col min-h-[46px] h-auto gap-[6px]">
                <div id="" class="font-inter text-sm font-semibold leading-5">Sampling date & time reminder</div>
                <div id="">
                  <div v-if="this.customColumns[0]?.samplingDateTimeReminder" class="flex flex-row justify-between">
                    <div class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
                      {{ this.customColumns[0]?.samplingDateTimeReminder }}
                    </div>
                    <i class="sn-icon sn-icon-notifications"></i>
                  </div>
                  <div v-else>No Date & time</div>
                </div>
              </div>
              <div id="dashed-divider" class="flex h-[1px] py-0  border-dashed border-[1px] border-sn-light-grey"></div>
  
              <div id="" class="flex flex-col min-h-[46px] h-auto gap-[6px]">
                <div id="" class="font-inter text-sm font-semibold leading-5">Sampling date range</div>
                <div id="" class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
                  {{ this.customColumns[0]?.samplingDateRange || 'No date range' }}
                </div>
              </div>
              <div id="dashed-divider" class="flex h-[1px] py-0  border-dashed border-[1px] border-sn-light-grey"></div>
  
              <div id="" class="flex flex-col min-h-[46px] h-auto gap-[6px]">
                <div id="" class="font-inter text-sm font-semibold leading-5">Sampling date</div>
                <div id="" class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
                  {{ this.customColumns[0]?.samplingDate || 'No date' }}
                </div>
              </div>
              <div id="dashed-divider" class="flex h-[1px] py-0  border-dashed border-[1px] border-sn-light-grey"></div>
  
              <div id="" class="flex flex-col min-h-[46px] h-auto gap-[6px]">
                <div id="" class="font-inter text-sm font-semibold leading-5">Sampling date reminder</div>
                <div id="">
                  <div v-if="this.customColumns[0]?.samplingDateReminder" class="flex flex-row justify-between">
                    <div class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
                      {{ this.customColumns[0]?.samplingDateReminder }}
                    </div>
                    <i class="sn-icon sn-icon-notifications"></i>
                  </div>
                  <div v-else>No Date</div>
                </div>
              </div>
              <div id="dashed-divider" class="flex h-[1px] py-0  border-dashed border-[1px] border-sn-light-grey"></div>
  
              <div id="" class="flex flex-col min-h-[46px] h-auto gap-[6px]">
                <div id="" class="font-inter text-sm font-semibold leading-5">Sampling time range</div>
                <div id="" class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
                  {{ this.customColumns[0]?.samplingTimeRange || 'No time range' }}
                </div>
              </div>
              <div id="dashed-divider" class="flex h-[1px] py-0  border-dashed border-[1px] border-sn-light-grey"></div>
  
              <div id="" class="flex flex-col min-h-[46px] h-auto gap-[6px]">
                <div id="" class="font-inter text-sm font-semibold leading-5">Incubation time</div>
                <div id="" class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
                  {{ this.customColumns[0]?.incubationTime || 'No time' }}
                </div>
              </div>
              <div id="dashed-divider" class="flex h-[1px] py-0  border-dashed border-[1px] border-sn-light-grey"></div>
  
              <div id="" class="flex flex-col min-h-[46px] h-auto gap-[6px]">
                <div id="" class="font-inter text-sm font-semibold leading-5">DNA File</div>
                <div id="" class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
                  <a v-if="this.customColumns[0]?.dnaFile">
                    {{ this.customColumns[0]?.dnaFile }}
                  </a>
                  <div v-else>No file</div>
                </div>
              </div>
              <div id="dashed-divider" class="flex h-[1px] py-0  border-dashed border-[1px] border-sn-light-grey"></div>
  
              <div id="" class="flex flex-col min-h-[46px] h-auto gap-[6px]">
                <div id="" class="font-inter text-sm font-semibold leading-5">Number of aliquots</div>
                <div id="" class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
                  {{ this.customColumns[0]?.numOfAliquots || 'No number' }}
                </div>
              </div>
              <div id="dashed-divider" class="flex h-[1px] py-0  border-dashed border-[1px] border-sn-light-grey"></div>
  
              <div id="" class="flex flex-col min-h-[46px] h-auto gap-[6px]">
                <div id="" class="font-inter text-sm font-semibold leading-5">Color</div>
                <div id="" class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
                  {{ this.customColumns[0]?.color || 'No selection' }}
                </div>
              </div>
              <div id="dashed-divider" class="flex h-[1px] py-0  border-dashed border-[1px] border-sn-light-grey"></div>
  
              <div id="" class="flex flex-col min-h-[46px] h-auto gap-[6px]">
                <div id="" class="font-inter text-sm font-semibold leading-5">Option</div>
                <div id="" class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
                  <div v-if="this.customColumns[0]?.optionArr.length > 0"
                    class="flex flex-row overflow-auto break-normal w-[350px] gap-1 flex-wrap h-auto"> 
                    <div v-for="(option, index) in this.customColumns[0].optionArr" :key="index" class="flex min-w-fit">
                      {{ option + ' |' }}
                    </div>
                  </div>
                  <div v-else>No number</div>
                </div>
              </div>
              <div id="dashed-divider" class="flex h-[1px] py-0  border-dashed border-[1px] border-sn-light-grey"></div>
  
              <div id="" class="flex flex-col min-min-h-[46px] h-auto gap-[6px]">
                <div id="" class="font-inter text-sm font-semibold leading-5">Item status</div>
                <div id="" class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
                  {{ this.customColumns[0]?.itemStatus || 'No selection' }}
                </div>
              </div>
              <div id="dashed-divider" class="flex h-[1px] py-0  border-dashed border-[1px] border-sn-light-grey"></div>
  
              <div id="" class="flex flex-col min-min-h-[46px] h-auto gap-[6px]">
                <div id="" class="flex justify-between">
                  <div class="font-inter text-sm font-semibold leading-5">Sequence</div>
                  <div @click="toggleExpandSequence" class="font-inter text-sm font-normal leading-5 text-sn-blue cursor-pointer">
                    {{ this.sequenceExpanded ? 'Hide' : 'Show' }}
                  </div>
                </div>
                <div 
                  id="sequence-container" 
                  class="text-sn-dark-grey font-inter text-sm font-normal leading-5 flex flex-row overflow-auto break-normal w-[350px] h-[60px] gap-1 flex-wrap">
                  {{ this.customColumns[0]?.sequence || 'No text' }}
                </div>
              </div>
  
              <!-- end of custom columns -->
            </div>
            <div v-else id="custom-columns-value" class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
              {{ this.customColumnsFallback }}
            </div>
          </div>
  
          <div id="divider" class="w-500 bg-sn-light-grey flex px-8 items-center self-stretch h-px	"></div>
  
          <div id="assigned-wrapper" class="flex flex-col h-[64px] gap-[6px]">
          <div id="assigned-label" class="font-inter text-base font-semibold leading-7">Assigned (3)</div>
          <div id="assigned-value" class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
            {{ this.assigned }}
          </div>
          </div>
  
          <div id="divider" class="w-500 bg-sn-light-grey flex px-8 items-center self-stretch h-px	"></div>
  
          <div id="QR-wrapper" class="block">
          <div id="QR-label" class="font-inter text-base font-semibold leading-7 mb-4">QR</div>
          <canvas id="bar-code-canvas" class="hidden" data-id='dummyDataId'></canvas>
          <img id="bar-code-image" />
          </div>
        </div>
      </div>
      <div id="navigation" class="min-w-[130px] h-[130px] flex item-end gap-x-4	">
        <div class="flex flex-col py-2 px-0 gap-3 self-stretch w-[130px] h-[130px]  justify-center items-center">
          <div class="flex flex-col w-[130px] h-[130px] justify-between text-right">
            <div @click="handleSideNavClick" id="text-item-1" class="hover:cursor-pointer text-sn-grey">Information</div>
            <div @click="handleSideNavClick" id="text-item-2" class="hover:cursor-pointer text-sn-grey">Custom columns</div>
            <div @click="handleSideNavClick" id="text-item-3" class="hover:cursor-pointer text-sn-grey">Assigned</div>
            <div @click="handleSideNavClick" id="text-item-4" class="hover:cursor-pointer text-sn-grey">QR</div>
          </div>
        </div>
  
        <div id="highlight-container" class="w-[1px] h-[130px] flex flex-col justify-evenly bg-sn-light-grey">
          <div id="highlight-item-1" class="w-[5px] h-[28px] rounded-[11px]"></div>
          <div id="highlight-item-2" class="w-[5px] h-[28px] rounded-[11px]"></div>
          <div id="highlight-item-3" class="w-[5px] h-[28px] rounded-[11px]"></div>
          <div id="highlight-item-4" class="w-[5px] h-[28px] rounded-[11px]"></div>
        </div>
      </div>
  
      <div id="bottom" class="h-[100px] flex flex-col justify-end">
        <div id="divider" class="w-500 bg-sn-light-grey flex px-8 items-center self-stretch h-px mb-6"></div>
        <div id="bottom-button-wrapper" class="flex h-10 justify-end">
          <button class="btn btn-primary">Print Label</button>
        </div>
      </div>
    </div>
  
</template>
  <script>

    export default {
      name: 'RepositoryItemSidebar',
      data() {
        // using dummy data for now
        return {
            repositoryRow: {
              name: 'Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et ma',
              repository_name: 'Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus etma',
              code: 'IT32823',
              added_on: '27 June 2023',
              added_by: 'Alexander Cansbridge',
              archived: false,
            },
            customColumns: [{
              solventStock: '120 mL',
              itemsInWarehouse: true,
              storageTemp: '-20 °C',
              samplingDateTimeRange: '8 August 2023, 10:10 - 16 August 2023, 10:10',
              samplingDateTimeReminder: '27 June 2023, 10:20',
              samplingDateRange: '08/23/2023 - 08/24/2023',
              samplingDate: '30 June 2023',
              samplingDateReminder: '27 June 2023',
              samplingTimeRange: '11:20 - 12:30',
              incubationTime: '11:20',
              dnaFile: 'Metastatic-Cancer-Research.pdf',
              numOfAliquots: '6487325893648732568743622589364873256874362856885687258936487325687436285682646498362463872258936487325687436285686487326748',
              color: 'Green',
              optionArr: ['Option 1', 'Option 10', 'Option 2', 'Option 4', 'Option 5', 'Option 1', 'Option 10', 'Option 2', 'Option 4', 'Option 5','Option 1', 'Option 10', 'Option 2', 'Option 4', 'Option 5'],
              itemStatus: 'Vapour',
              sequence: '>J014514.1 Cloning vector pBR322, complete sequence>J014514.1 Cloning vector pBR322, complete sequence>J014514.1 Cloning vector pBR322, complete sequence>J014514.1 Cloning vector pBR322, complete sequence>J014514.1 Cloning vector pBR322, complete sequence'
            }],
            isShowing: false,
            sequenceExpanded: false,
            customColumnsFallback: 'No custom columns',
            assigned: 'Assigned to 3 private tasks that will not be displayed'
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
      mounted() {
        // generate the QR code
        let barCodeCanvas = bwipjs.toCanvas('bar-code-canvas', {
        bcid: 'qrcode',
        text: $('#repository-item-sidebar #bar-code-canvas').data('id').toString(),
        scale: 3
      });
      $('#repository-item-sidebar #bar-code-image').attr('src', barCodeCanvas.toDataURL('image/png'));
      },
      beforeDestroy() {
        delete window.repositoryItemSidebarComponent;
      },
      computed: {
        defaultColumns() {
          return [
            { label: I18n.t('repositories.item_card.default.repository_name'), value: this.repositoryRow.repository_name },
            { label: I18n.t('repositories.item_card.default.id'), value: this.repositoryRow.code },
            { label: I18n.t('repositories.item_card.default.added_on'), value: this.repositoryRow.added_on },
            { label: I18n.t('repositories.item_card.default.added_by'), value: this.repositoryRow.added_by }
          ]
        }
      },
      methods: {
        // component is currently shown/hidden by calling window.repositoryItemSidebarComponent.toggleShowHideSidebar()
        toggleShowHideSidebar(itemId) {
            this.isShowing = !this.isShowing
            console.log(`Showing details for itemId: ${itemId}`)
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

        // determine the identifier value according to the text-item (target) value
        handleSideNavClick(e) {
          let highlightItemId
          const targetId = e.target.id
          switch(targetId) {
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
        }
      }
    }
  </script>
