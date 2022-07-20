<template>
  <div class="step-table-container">
     <div class="step-element-header" :class="{ 'editing-name': editingName }">
      <div v-if="reorderElementUrl" class="step-element-grip" @click="$emit('reorder')">
        <i class="fas fas-rotated-90 fa-exchange-alt"></i>
      </div>
      <div v-else class="step-element-grip-placeholder"></div>
      <div class="step-element-name">
        <InlineEdit
          v-if="element.attributes.orderable.urls.update_url"
          :value="element.attributes.orderable.name"
          :characterLimit="255"
          :placeholder="''"
          :allowBlank="false"
          :autofocus="editingName"
          :attributeName="`${i18n.t('Table')} ${i18n.t('name')}`"
          @editingEnabled="enableNameEdit"
          @editingDisabled="disableNameEdit"
          @update="updateName"
        />
        <span v-else>
          {{ element.attributes.orderable.name }}
        </span>
      </div>
      <div class="step-element-controls">
        <button v-if="element.attributes.orderable.urls.update_url" class="btn icon-btn btn-light" @click="enableNameEdit" tabindex="-1">
          <i class="fas fa-pen"></i>
        </button>
        <button v-if="element.attributes.orderable.urls.delete_url" class="btn icon-btn btn-light" @click="showDeleteModal" tabindex="-1">
          <i class="fas fa-trash"></i>
        </button>
      </div>
    </div>
    <div :class="'step-table ' + (editingTable ? 'edit' : 'view')" tabindex="0" @keyup.enter="!editingTable && enableTableEdit()">
      <div  class="enable-edit-mode" v-if="!editingTable && element.attributes.orderable.urls.update_url" @click="enableTableEdit">
        <div class="enable-edit-mode__icon">
          <i class="fas fa-pen"></i>
        </div>
      </div>
      <div ref="hotTable" class="hot-table-container">
      </div>
      <div v-if="editingTable" class="edit-message">
        {{ i18n.t('protocols.steps.table.edit_message') }}
      </div>
    </div>
    <div class="edit-buttons" v-if="editingTable">
      <button class="btn icon-btn btn-primary" @click="updateTable">
        <i class="fas fa-check"></i>
      </button>
      <button class="btn icon-btn btn-light" @click="disableTableEdit">
        <i class="fas fa-times"></i>
      </button>
    </div>
    <deleteElementModal v-if="confirmingDelete" @confirm="deleteElement" @cancel="closeDeleteModal"/>
  </div>
</template>

 <script>
  import DeleteMixin from 'vue/protocol/mixins/components/delete.js'
  import deleteElementModal from 'vue/protocol/modals/delete_element.vue'
  import InlineEdit from 'vue/shared/inline_edit.vue'

  export default {
    name: 'StepTable',
    components: { deleteElementModal, InlineEdit },
    mixins: [DeleteMixin],
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
      }
    },
    data() {
      return {
        editingName: false,
        editingTable: false,
        tableObject: null
      }
    },
    updated() {
      this.loadTableData();
    },
    beforeUpdate() {
      this.tableObject.destroy();
    },
    mounted() {
      this.loadTableData();

      if (this.isNew) this.enableTableEdit();
    },
    methods: {
      enableTableEdit() {
        this.editingTable = true;
        this.$nextTick(() => this.tableObject.selectCell(0,0));
      },
      disableTableEdit() {
        this.editingTable = false;
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
      updateTable() {
        let tableData = JSON.stringify({data: this.tableObject.getData()});
        this.element.attributes.orderable.contents = tableData;
        this.update();
        this.editingTable = false;
      },
      update() {
        this.$emit('update', this.element)
      },
      loadTableData() {
        let container = this.$refs.hotTable;
        let data = JSON.parse(this.element.attributes.orderable.contents);
        this.tableObject = new Handsontable(container, {
          data: data.data,
          width: '100%',
          startRows: 5,
          startCols: 5,
          rowHeaders: true,
          colHeaders: true,
          contextMenu: this.editingTable,
          formulas: true,
          readOnly: !this.editingTable,
          afterUnlisten: this.updateTable
        });
      }
    }
  }
</script>
