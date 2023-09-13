<template>
    <div id="repository-item-sidebar" class="w-[500px] h-[1032px] m-[24px] bg-white justify-between flex flex-col">
        <div id="top" class="flex flex-col items-center gap-6 self-stretch min-h-[763px] h-full">

            <div id="modal-title-and-subtitle" class="h-[48px] w-full">
                <div id="title" class="h-[30px] w-full flex justify-between">
                    <p class="my-auto mx-0 w-fit font-inter text-base font-semibold leading-7">{{ this.title }}</p>
                    <i @click="toggleShowHide" class="sn-icon sn-icon-close ml-auto cursor-pointer my-auto mx-0"></i>
                </div>
                <div id="subtitle" class="h-[18px] w-full flex">
                    {{ this.subtitle }}
                </div>
            </div>

            <div id="divider" class="w-500 bg-sn-light-grey flex px-8 items-center self-stretch h-px	"></div>

            <div id="content" class="min-h-[684px] flex flex-row">
                <div id="items" class="min-w-[350px] grid grid-rows-10">
                    <div id="information" class="h-[28px] font-inter text-lg font-semibold leading-7">Information</div>

                    <div id="inventory-wrapper" class="flex flex-col h-[46px]">
                      <div id="inventory-label" class="font-inter text-sm font-semibold leading-5">Inventory</div>
                      <div id="inventory-value" class="text-gray-700 font-inter text-sm font-normal leading-5">{{ this.inventory }}</div>
                    </div>

                    <div id="divider" class="flex h-[1px] py-0  border-dashed border-[1px] border-sn-sleepy-grey"></div>

                    <div id="item-id-wrapper" class="flex flex-col h-[46px]">
                      <div id="item-id-label" class="font-inter text-sm font-semibold leading-5">Item ID</div>
                      <div id="item-id-value" class="text-gray-700 font-inter text-sm font-normal leading-5">{{ this.itemId }}</div>
                    </div>

                    <div id="divider" class="flex h-[1px] py-0  border-dashed border-[1px] border-sn-sleepy-grey"></div>

                    <div id="added-on-wrapper" class="flex flex-col h-[46px]">
                      <div id="added-on-label" class="font-inter text-sm font-semibold leading-5">Added on</div>
                      <div id="added-on-value" class="text-gray-700 font-inter text-sm font-normal leading-5">{{ this.addedOn }}</div>
                    </div>

                    <div id="divider" class="flex h-[1px] py-0  border-dashed border-[1px] border-sn-sleepy-grey"></div>

                    <div id="added-by-wrapper" class="flex flex-col h-[46px]">
                      <div id="added-by-label" class="font-inter text-sm font-semibold leading-5">Added by</div>
                      <div id="added-by-value" class="text-gray-700 font-inter text-sm font-normal leading-5">{{ this.addedBy }}</div>
                    </div>

                    <div id="divider" class="w-500 bg-sn-light-grey flex px-8 items-center self-stretch h-px	"></div>

                    <div id="custom-columns-wrapper" class="flex flex-col h-[64px]">
                      <div id="custom-columns-label" class="font-inter text-base font-semibold leading-7">Custom columns</div>
                      <div id="custom-columns-value" class="text-gray-700 font-inter text-sm font-normal leading-5">{{ this.customColumns }}</div>
                    </div>

                    <div id="divider" class="w-500 bg-sn-light-grey flex px-8 items-center self-stretch h-px	"></div>

                    <div id="assigned-wrapper" class="flex flex-col h-[64px]">
                      <div id="assigned-label" class="font-inter text-base font-semibold leading-7">Assigned (3)</div>
                      <div id="assigned-value" class="text-gray-700 font-inter text-sm font-normal leading-5">{{ this.assigned }}</div>
                    </div>

                    <div id="divider" class="w-500 bg-sn-light-grey flex px-8 items-center self-stretch h-px	"></div>

                    <div id="QR-wrapper" class="block">
                      <div id="QR-label" class="font-inter text-base font-semibold leading-7 mb-4">QR</div>
                      <canvas id="bar-code-canvas" class="hidden" data-id='dummyDataId'></canvas>
                      <img id="bar-code-image" />
                    </div>
                </div>

                <div class="min-w-[130px] h-[130px] flex item-end gap-x-4	">
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
            isShowing: false,
            title: 'DNA sample 01',
            subtitle: 'subtitle',
            inventory: 'Sample',
            itemId: 'IT32823',
            addedOn: '27 June 2023',
            addedBy: 'Alexander Cansbridge',
            customColumns: 'No custom columns',
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
      },
      methods: {
        // component is currently shown/hidden by calling window.repositoryItemSidebarComponent.toggleShowHide()
        toggleShowHide(itemId) {
            this.isShowing = !this.isShowing
            console.log(`Showing details for itemId: ${itemId}`)
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