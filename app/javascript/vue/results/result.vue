<template>
  <div class="result-wrapper bg-white">
    <div class="result-header flex justify-between p-3">
      <div class="result-head-left">
        <InlineEdit
          :value="result.attributes.name"
          :class="{ 'result-element--locked': !urls.update_url }"
          :characterLimit="255"
          :allowBlank="false"
          :attributeName="`${i18n.t('Result')} ${i18n.t('name')}`"
          :autofocus="editingName"
          :placeholder="i18n.t('my_modules.results.placeholder')"
          :defaultValue="i18n.t('my_modules.results.default_name')"
          @editingEnabled="editingName = true"
          @editingDisabled="editingName = false"
          :editOnload="result.newResult == true"
          @update="updateName"
        />
      </div>
      <div class="result-head-right flex">
        <input type="file" class="hidden" ref="fileSelector" @change="loadFromComputer" multiple />
        <div ref="elementsDropdownButton" v-if="urls.update_url"  class="dropdown">
          <button class="btn btn-light dropdown-toggle insert-button" type="button" :id="'resultInsertMenu_' + result.id" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true">
            {{ i18n.t('protocols.steps.insert.button') }}
            <span class="sn-icon sn-icon-down"></span>
          </button>
          <ul ref="elementsDropdown" class="dropdown-menu insert-element-dropdown dropdown-menu-right" :aria-labelledby="'resultInsertMenu_' + result.id">
            <li class="title">
              <a>
                {{ i18n.t('protocols.steps.insert.title') }}
              </a>
            </li>
            <li class="action" @click="createElement('table')">
              <a class="cursor-pointer">
                <i class="sn-icon sn-icon-tables"></i>
                {{ i18n.t('protocols.steps.insert.table') }}
              </a>
            </li>
            <li class="action dropdown-submenu-item">
              <a class="cursor-pointer">
                <i class="sn-icon sn-icon-tables"></i>
                {{ i18n.t('protocols.steps.insert.well_plate') }}
              </a>
              <span class="caret"></span>

              <ul class="dropdown-submenu">
                <li v-for="option in wellPlateOptions" :key="option.dimensions.toString()" class="action" @click="createElement('table', option.dimensions, true)">
                  <a class="cursor-pointer">
                    {{ i18n.t(option.label) }}
                  </a>
                </li>
              </ul>
            </li>
            <li class="action"  @click="createElement('text')">
              <a class="cursor-pointer">
                <i class="sn-icon sn-icon-result-text"></i>
                {{ i18n.t('protocols.steps.insert.text') }}
              </a>
            </li>
            <li class="action dropdown-submenu-item">
              <a class="cursor-pointer">
                <i class="sn-icon sn-icon-files"></i>
                {{ i18n.t('protocols.steps.insert.attachment') }}
              </a>
              <span class="caret"></span>
              <ul class="dropdown-submenu">
                <li class="action" @click="openLoadFromComputer">
                  <a class="cursor-pointer">
                    {{ i18n.t('protocols.steps.insert.add_file') }}
                  </a>
                </li>
                <li class="action" v-if="result.attributes.wopi_enabled" @click="openWopiFileModal">
                  <a class="cursor-pointer">
                    {{ i18n.t('assets.create_wopi_file.button_text') }}
                  </a>
                </li>
                <li class="action" v-if="result.attributes.marvinjs_enabled" @click="openMarvinJsModal($refs.marvinJsButton)">
                  <a class="cursor-point  er">
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
                  </a>
                </li>
              </ul>
            </li>
          </ul>
        </div>
        <a href="#"
          ref="comments"
          class="open-comments-sidebar btn icon-btn btn-light"
          data-turbolinks="false"
          data-object-type="Result"
          :data-object-id="result.id">
          <i class="sn-icon sn-icon-comments"></i>
        </a>
        <div ref="actionsDropdownButton" class="dropdown">
          <button class="btn btn-light icon-btn dropdown-toggle insert-button" type="button" :id="'resultOptionsMenu_' + result.id" data-toggle="dropdown" data-display="static" aria-haspopup="true" aria-expanded="true">
            <i class="sn-icon sn-icon-more-hori"></i>
          </button>
          <ul ref="actionsDropdown" class="dropdown-menu dropdown-menu-right insert-element-dropdown" :aria-labelledby="'resultOptionsMenu_' + result.id">
            <li class="action"  @click="openReorderModal">
              <a class="cursor-pointer">{{ i18n.t('my_modules.results.actions.rearrange') }}</a>
            </li>
            <li class="action" @click="duplicateResult">
              <a class="cursor-pointer">{{ i18n.t('my_modules.results.actions.duplicate') }}</a>
            </li>
            <li class="action" @click="archiveResult">
              <a class="cursor-pointer">{{ i18n.t('my_modules.results.actions.archive') }}</a>
            </li>
          </ul>
        </div>
      </div>
    </div>
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
          @moved="moveElement"
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
    <hr>
  </div>
</template>

<script>
  import axios from '../../packs/custom_axios.js';
  import ReorderableItemsModal from '../shared/reorderable_items_modal.vue';
  import ResultTable from '../shared/content/table.vue';
  import ResultText from '../shared/content/text.vue';
  import Attachments from '../shared/content/attachments.vue';
  import InlineEdit from '../shared/inline_edit.vue'

  import AttachmentsMixin from '../shared/content/mixins/attachments.js'
  import WopiFileModal from '../shared/content/attachments/mixins/wopi_file_modal.js'
  import UtilsMixin from '../mixins/utils.js'

  export default {
    name: 'Results',
    props: {
      result: { type: Object, required: true },
      resultToReload: { type: Number, required: false }
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
        ],
        editingName: false
      }
    },
    mixins: [UtilsMixin, AttachmentsMixin, WopiFileModal],
    components: {
      ReorderableItemsModal,
      ResultTable,
      ResultText,
      Attachments,
      InlineEdit
    },
    watch: {
      resultToReload() {
        if (this.resultToReload == this.result.id) {
          this.loadElements();
        }
      }
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
          this.$emit('result:elements:loaded');
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
          this.$emit('resultUpdated')
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
      archiveResult() {

      },
      duplicateResult() {
        axios.post(this.urls.duplicate_url).then((_) => {
          this.$emit('duplicated');
        });
      },
      moveElement(position, target_id) {
        this.elements.splice(position, 1)
        let unorderedElements = this.elements.map( e => {
          if (e.attributes.position >= position) {
            e.attributes.position -= 1;
          }
          return e;
        })
        this.$emit('resultUpdated')
        this.$emit('result:move_element', target_id)
      },
      updateName(name) {
        axios.patch(this.urls.update_url, { result: { name: name } }).then((_) => {
          this.$emit('updated');
        });
      }
    }
  }
</script>
