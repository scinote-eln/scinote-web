<template>
  <div class="step-table-container">
     <div class="step-element-header" :class="{ 'editing-name': editingName }">
      <div class="step-element-grip">
        <i class="fas fa-grip-vertical"></i>
      </div>
      <div class="step-element-name">
        <InlineEdit
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
      </div>
      <div class="step-element-controls">
        <button class="btn icon-btn btn-light" @click="enableNameEdit">
          <i class="fas fa-pen"></i>
        </button>
        <button class="btn icon-btn btn-light" @click="showDeleteModal">
          <i class="fas fa-trash"></i>
        </button>
      </div>
    </div>
    <div :class="'step-table ' + (editingTable ? 'edit' : 'view')">
      <div class="enable-edit-mode" v-if="!editingTable" @click="enableTableEdit">
        <i class="fas fa-pen"></i>
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
    <deleteComponentModal v-if="confirmingDelete" @confirm="deleteComponent" @cancel="closeDeleteModal"/>
  </div>
</template>

 <script>
  import DeleteMixin from 'vue/protocol/mixins/components/delete.js'
  import deleteComponentModal from 'vue/protocol/modals/delete_component.vue'
  import InlineEdit from 'vue/shared/inline_edit.vue'

  export default {
    name: 'StepTable',
    components: { deleteComponentModal, InlineEdit },
    mixins: [DeleteMixin],
    props: {
      element: {
        type: Object,
        required: true
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
    },
    methods: {
      enableTableEdit() {
        this.editingTable = true;
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
          readOnly: !this.editingTable
        });
      }
    }
  }
</script>
