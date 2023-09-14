<template>
  <div class="content__table-container">
    <div class="border-0 border-b border-dashed border-sn-light-grey my-6" v-if="!inRepository"></div>
    <div class="table-header h-9 flex rounded mb-1 items-center relative w-full group/table-header" :class="{ 'editing-name': editingName, 'locked': locked }">
      <div v-if="!locked || element.attributes.orderable.name" :key="reloadHeader"
           class="grow-1 text-ellipsis whitespace-nowrap grow my-1 font-bold"
           :class="{'pointer-events-none': locked}">
        <InlineEdit
          :value="element.attributes.orderable.name"
          :characterLimit="255"
          :placeholder="i18n.t('protocols.steps.table.table_name')"
          :allowBlank="false"
          :autofocus="editingName"
          :attributeName="`${i18n.t('Table')} ${i18n.t('name')}`"
          @editingEnabled="enableNameEdit"
          @editingDisabled="disableNameEdit"
          @update="updateName"
        />
      </div>
      <MenuDropdown
        class="ml-auto"
        :listItems="this.actionMenu"
        :btnClasses="'btn btn-light icon-btn'"
        :position="'right'"
        :btnIcon="'sn-icon sn-icon-more-hori'"
        @edit="enableNameEdit"
        @duplicate="duplicateElement"
        @move="showMoveModal"
        @delete="showDeleteModal"
      ></MenuDropdown>
    </div>
    <div class="table-body group/table-body relative border-solid border-transparent"
         :class="{'edit border-sn-light-grey': editingTable, 'view': !editingTable, 'locked': !element.attributes.orderable.urls.update_url}"
         tabindex="0"
         @keyup.enter="!editingTable && enableTableEdit()">
      <div ref="hotTable" class="hot-table-container" @click="!editingTable && enableTableEdit()">
      </div>
      <div v-if="editingTable" class="text-xs pt-3 pb-2 text-sn-grey">
        {{ i18n.t('protocols.steps.table.edit_message') }}
      </div>
    </div>
    <div class="flex justify-end mt-1 gap-2" v-if="editingTable">
      <button class="btn icon-btn btn-primary btn-sm" @click="updateTable">
        <i class="sn-icon sn-icon-check"></i>
      </button>
      <button class="btn icon-btn btn-light btn-sm" @click="disableTableEdit">
        <i class="sn-icon sn-icon-close"></i>
      </button>
    </div>
    <deleteElementModal v-if="confirmingDelete" @confirm="deleteElement" @cancel="closeDeleteModal"/>
    <tableNameModal v-if="nameModalOpen" :element="element" @update="updateEmptyName" @cancel="nameModalOpen = false" />
    <moveElementModal v-if="movingElement"
                      :parent_type="element.attributes.orderable.parent_type"
                      :targets_url="element.attributes.orderable.urls.move_targets_url"
                      @confirm="moveElement($event)" @cancel="closeMoveModal"/>
  </div>
</template>

 <script>
  import DeleteMixin from './mixins/delete.js'
  import MoveMixin from './mixins/move.js'
  import DuplicateMixin from './mixins/duplicate.js'
  import deleteElementModal from './modal/delete.vue'
  import InlineEdit from '../inline_edit.vue'
  import TableNameModal from './modal/table_name.vue'
  import moveElementModal from './modal/move.vue'
  import MenuDropdown from '../menu_dropdown.vue'

  export default {
    name: 'ContentTable',
    components: { deleteElementModal, InlineEdit, TableNameModal, moveElementModal, MenuDropdown },
    mixins: [DeleteMixin, DuplicateMixin, MoveMixin],
    props: {
      element: {
        type: Object,
        required: true
      },
      inRepository: {
        type: Boolean,
        required: true
      },
      reorderElementUrl: {
        type: String
      },
      isNew: {
        type: Boolean, default: false
      },
      assignableMyModuleId: {
        type: Number,
        required: false
      }
    },
    data() {
      return {
        editingName: false,
        editingTable: false,
        tableObject: null,
        nameModalOpen: false,
        reloadHeader: 0,
        updatingTableData: false
      }
    },
    computed: {
      locked() {
        return !this.element.attributes.orderable.urls.update_url
      },
      actionMenu() {
        let menu = [];
        if (this.element.attributes.orderable.urls.update_url) {
          menu.push({
            text: I18n.t('general.edit'),
            emit: 'edit'
          });
        }
        if (this.element.attributes.orderable.urls.duplicate_url) {
          menu.push({
            text: I18n.t('general.duplicate'),
            emit: 'duplicate'
          });
        }
        if (this.element.attributes.orderable.urls.move_targets_url) {
          menu.push({
            text: I18n.t('general.move'),
            emit: 'move'
          });
        }
        if (this.element.attributes.orderable.urls.delete_url) {
          menu.push({
            text: I18n.t('general.delete'),
            emit: 'delete'
          });
        }
        return menu;
      }
    },
    updated() {
      if(!this.updatingTableData) this.loadTableData();
    },
    beforeUpdate() {
      if(!this.updatingTableData) this.tableObject.destroy();
    },
    mounted() {
      this.loadTableData();

      if (this.isNew) this.enableTableEdit();
    },
    methods: {
      enableTableEdit() {
        if(this.locked) {
          return;
        }

        if (!this.element.attributes.orderable.name) {
          this.openNameModal();
          return;
        }

        this.editingTable = true;
        this.$nextTick(() => this.tableObject.selectCell(0,0));
      },
      disableTableEdit() {
        this.editingTable = false;
        this.updatingTableData = false;
      },
      enableNameEdit() {
        this.editingName = true;
      },
      disableNameEdit() {
        this.editingName = false;
      },
      updateName(name) {
        this.element.attributes.orderable.name = name;
        this.update();
      },
      openNameModal() {
        this.tableObject.deselectCell();
        this.nameModalOpen = true;
      },
      updateEmptyName(name) {
        this.disableNameEdit();

        // force reload header to properly reset name inline edit
        this.reloadHeader = this.reloadHeader + 1;

        this.element.attributes.orderable.name = name;
        this.$emit('update', this.element, false, () => {
          this.nameModalOpen = false;
          this.enableTableEdit();
        });
      },
      updateTable() {
        if (this.editingTable == false) return;

        this.update();
        this.editingTable = false;
      },
      update() {
        this.element.attributes.orderable.contents = JSON.stringify({ data: this.tableObject.getData() });
        let metadata = this.element.attributes.orderable.metadata || {};
        if (metadata.plateTemplate) {
            this.element.attributes.orderable.metadata = JSON.stringify({
              cells: this.tableObject
                         .getCellsMeta()
                         .filter(e => !!e)
                         .map((x) => {
                              const {row, col} = x;
                              return {
                                row: row,
                                col: col,
                                className: x.className || '',
                              }
                          })
            });
          } else {
            this.element.attributes.orderable.metadata = JSON.stringify({
              cells: this.tableObject
                         .getCellsMeta()
                         .filter(e => !!e)
                         .map((x) => {
                              const {row, col} = x;
                              const plugins = this.tableObject.plugin;
                              const cellId = plugins.utils.translateCellCoords({row, col});
                              const calculated = plugins.matrix.getItem(cellId)?.value ||
                                this.tableObject.getDataAtCell(row, col) ||
                                null;
                              return {
                                row: row,
                                col: col,
                                className: x.className || '',
                                calculated: calculated
                              }
                          })
            });
        }
        this.$emit('update', this.element)
        this.ajax_update_url()
        this.updatingTableData = false;
      },
      ajax_update_url() {
        $.ajax({
          url: this.element.attributes.orderable.urls.update_url,
          method: 'PUT',
          data: this.element.attributes.orderable,
        })
      },
      loadTableData() {
        let container = this.$refs.hotTable;
        let data = JSON.parse(this.element.attributes.orderable.contents);
        let metadata = this.element.attributes.orderable.metadata || {};
        let formulasEnabled = metadata.plateTemplate ? false : true;

        this.tableObject = new Handsontable(container, {
          data: data.data,
          width: '100%',
          startRows: 5,
          startCols: 5,
          rowHeaders: tableColRowName.tableRowHeaders(metadata.plateTemplate),
          colHeaders: tableColRowName.tableColHeaders(metadata.plateTemplate),
          cell: metadata.cells || [],
          contextMenu: this.editingTable,
          formulas: formulasEnabled,
          preventOverflow: 'horizontal',
          readOnly: !this.editingTable,
          afterUnlisten: () => {
            this.updatingTableData = true;
            setTimeout(this.updateTable, 100) // delay makes cancel button work
          }
        });
        this.$nextTick(this.tableObject.render);
      }
    }
  }
</script>
