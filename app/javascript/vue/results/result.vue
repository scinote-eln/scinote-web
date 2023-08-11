<template>
  <div class="result-wrapper">
    {{ result.id }}
    {{ result.attributes.name }}
    <button @click="openReorderModal">
      Open Rearrange Modal
    </button>
    <div class="inline-block">
      <input type="file" class="hidden" ref="fileSelector" @change="loadFromComputer" multiple />
      <div ref="elementsDropdownButton" v-if="urls.update_url"  class="dropdown">
        <button class="btn btn-light dropdown-toggle insert-button" type="button" :id="'resultInsertMenu_' + result.id" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true">
          {{ i18n.t('protocols.steps.insert.button') }}
          <span class="sn-icon sn-icon-down"></span>
        </button>
        <ul ref="elementsDropdown" class="dropdown-menu insert-element-dropdown dropdown-menu-right" :aria-labelledby="'resultInsertMenu_' + result.id">
          <li class="title">
            {{ i18n.t('protocols.steps.insert.title') }}
          </li>
          <li class="action" @click="createElement('table')">
            <i class="sn-icon sn-icon-tables"></i>
            {{ i18n.t('protocols.steps.insert.table') }}
          </li>
          <li class="action dropdown-submenu-item">
            <i class="sn-icon sn-icon-tables"></i>
            {{ i18n.t('protocols.steps.insert.well_plate') }}
            <span class="caret"></span>

            <ul class="dropdown-submenu">
              <li v-for="option in wellPlateOptions" :key="option.dimensions.toString()" class="action" @click="createElement('table', option.dimensions, true)">
                {{ i18n.t(option.label) }}
              </li>
            </ul>
          </li>
          <li class="action"  @click="createElement('text')">
            <i class="sn-icon sn-icon-result-text"></i>
            {{ i18n.t('protocols.steps.insert.text') }}
          </li>
          <li class="action dropdown-submenu-item">
            <i class="sn-icon sn-icon-files"></i>
            {{ i18n.t('protocols.steps.insert.attachment') }}
            <span class="caret"></span>
            <ul class="dropdown-submenu">
              <li class="action" @click="openLoadFromComputer">
                {{ i18n.t('protocols.steps.insert.add_file') }}
              </li>
              <li class="action" v-if="result.attributes.wopi_enabled" @click="openWopiFileModal">
                {{ i18n.t('assets.create_wopi_file.button_text') }}
              </li>
              <li class="action" v-if="result.attributes.marvinjs_enabled" @click="openMarvinJsModal($refs.marvinJsButton)">
                <span
                  class="new-marvinjs-upload-button text-sn-black text-decoration-none"
                  :data-object-id="result.id"
                  ref="marvinJsButton"
                  :data-marvin-url="result.attributes.marvinjs_context.marvin_js_asset_url"
                  :data-object-type="result.attributes.type"
                  tabindex="0"
                >
                  {{ i18n.t('marvinjs.new_button') }}
                </span>
              </li>
            </ul>
          </li>
        </ul>
      </div>
    </div>
    <hr>
    <ReorderableItemsModal v-if="reordering"
      title="Placeholder title for this modal"
      :items="reorderableElements"
      @reorder="updateElementOrder"
      @close="closeReorderModal"
    />
    <div>
      <template v-for="(element, index) in orderedElements">
        <component
          :is="elements[index].attributes.orderable_type"
          :key="index"
          :element.sync="elements[index]"
          :inRepository="false"
          :reorderElementUrl="elements.length > 1 ? urls.reorder_elements_url : ''"
          :assignableMyModuleId="result.attributes.my_module_id"
          :isNew="element.isNew"
          @component:delete="deleteElement"
          @update="updateElement"
          @reorder="openReorderModal"
          @component:insert="insertElement"
        />
      </template>
      <Attachments v-if="attachments.length"
                    :parent="result"
                    :attachments="attachments"
                    :attachmentsReady="attachmentsReady"
                    @attachments:openFileModal="showFileModal = true"
                    @attachment:deleted="attachmentDeleted"
                    @attachment:uploaded="loadAttachments"
                    @attachments:order="changeAttachmentsOrder"
                    @attachments:viewMode="changeAttachmentsViewMode"
                    @attachment:viewMode="updateAttachmentViewMode"/>
    </div>
  </div>
</template>

<script>
  import axios from 'axios';
  import ReorderableItemsModal from '../shared/reorderable_items_modal.vue';
  import ResultTable from '../shared/content/table.vue';
  import ResultText from '../shared/content/text.vue';
  import Attachments from '../shared/content/attachments.vue';

  import AttachmentsMixin from '../shared/content/mixins/attachments.js'
  import WopiFileModal from '../shared/content/attachments/mixins/wopi_file_modal.js'
  import UtilsMixin from '../mixins/utils.js'

  export default {
    name: 'Results',
    props: {
      result: { type: Object, required: true }
    },
    data() {
      return {
        reordering: false,
        elements: [],
        attachments: [],
        attachmentsReady: false,
        showFileModal: false,
        wellPlateOptions: [
          { label: 'protocols.steps.insert.well_plate_options.32_x_48', dimensions: [32, 48] },
          { label: 'protocols.steps.insert.well_plate_options.16_x_24', dimensions: [16, 24] },
          { label: 'protocols.steps.insert.well_plate_options.8_x_12', dimensions: [8, 12] },
          { label: 'protocols.steps.insert.well_plate_options.6_x_8', dimensions: [6, 8] },
          { label: 'protocols.steps.insert.well_plate_options.6_x_4', dimensions: [6, 4] },
          { label: 'protocols.steps.insert.well_plate_options.2_x_3', dimensions: [2, 3] }
        ]
      }
    },
    mixins: [UtilsMixin, AttachmentsMixin, WopiFileModal],
    components: {
      ReorderableItemsModal,
      ResultTable,
      ResultText,
      Attachments
    },
    computed: {
      reorderableElements() {
        return this.orderedElements.map((e) => { return { id: e.id, attributes: e.attributes.orderable } })
      },
      orderedElements() {
        return this.elements.sort((a, b) => a.attributes.position - b.attributes.position);
      },
      urls() {
        return this.result.attributes.urls || {}
      }
    },
    created() {
      this.loadAttachments();
      this.loadElements();
    },
    methods: {
      openReorderModal() {
        this.reordering = true;
      },
      closeReorderModal() {
        this.reordering = false;
      },
      updateElementOrder(orderedElements) {
        orderedElements.forEach((element, position) => {
          let index = this.elements.findIndex((e) => e.id === element.id);
          this.elements[index].attributes.position = position;
        });

        let elementPositions = {
          result_orderable_element_positions: this.elements.map(
            (element) => [element.id, element.attributes.position]
          )
        };

        axios.post(this.urls.reorder_elements_url, elementPositions, {
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          }
        })
        .then(() => {
          this.$emit('resultUpdated');
        })
        .catch(() => {
          HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
        });
      },
      deleteElement(position) {
        this.elements.splice(position, 1)
        let unorderedElements = this.elements.map( e => {
          if (e.attributes.position >= position) {
            e.attributes.position -= 1;
          }
          return e;
        })
        this.$emit('resultUpdated')
      },
      updateElement(element, skipRequest=false, callback) {
        let index = this.elements.findIndex((e) => e.id === element.id);
        this.elements[index].isNew = false;

        if (skipRequest) {
          this.elements[index].attributes.orderable = element.attributes.orderable;
          this.$emit('resultUpdated');
        } else {
          $.ajax({
            url: element.attributes.orderable.urls.update_url,
            method: 'PUT',
            data: element.attributes.orderable,
            success: (result) => {
              this.elements[index].attributes.orderable = result.data.attributes;
              this.$emit('resultUpdated');

              // optional callback after successful update
              if(typeof callback === 'function') {
                callback();
              }
            }
          }).fail(() => {
            HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
          })
        }
      },
      insertElement(element) {
        let position = element.attributes.position;
        this.elements = this.elements.map( s => {
          if (s.attributes.position >= position) {
              s.attributes.position += 1;
          }
          return s;
        })
        this.elements.push(element);
      },
      loadElements() {
        $.get(this.urls.elements_url, (result) => {
          this.elements = result.data
        });
      },
      loadAttachments() {
        this.attachmentsReady = false

        $.get(this.urls.attachments_url, (result) => {
          this.attachments = result.data

          if (this.attachments.findIndex((e) => e.attributes.attached === false) >= 0) {
            setTimeout(() => {
              this.loadAttachments()
            }, 10000)
          } else {
            this.attachmentsReady = true
          }
        });
        this.showFileModal = false;
      },
      attachmentDeleted(id) {
        this.attachments = this.attachments.filter((a) => a.id !== id );
        this.$emit('resultUpdated');
      },
      createElement(elementType, tableDimensions = [5,5], plateTemplate = false) {
        $.post(this.urls[`create_${elementType}_url`], { tableDimensions: tableDimensions, plateTemplate: plateTemplate }, (result) => {
          result.data.isNew = true;
          this.elements.push(result.data)
          this.$emit('stepUpdated')
        }).fail(() => {
          HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
        }).done(() => {
          this.$parent.$nextTick(() => {
            const children = this.$children
            const lastChild = children[children.length - 1]
            lastChild.$el.scrollIntoView(false)
            window.scrollBy({
              top: 200,
              behavior: 'smooth'
            });
          })
        });
      },
    }
  }
</script>
