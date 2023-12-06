<template>
  <DataTable
    :columnDefs="columnDefs"
    tableId="ExperimentsList"
    :dataUrl="dataSource"
    :reloadingTable="reloadingTable"
    :toolbarActions="toolbarActions"
    :actionsUrl="actionsUrl"
    :withRowMenu="true"
    :activePageUrl="activePageUrl"
    :archivedPageUrl="archivedPageUrl"
    :currentViewMode="currentViewMode"
    :filters="filters"
    :viewRenders="viewRenders"
    @tableReloaded="reloadingTable = false"
  >
    <template #card="data"> </template>
  </DataTable>
</template>

<script>
import axios from "../../packs/custom_axios.js";

import DataTable from "../shared/datatable/table.vue";
import DescriptionRenderer from "./renderers/description.vue";
import CompletedTasksRenderer from "./renderers/completed_tasks.vue";
import NameRenderer from "./renderers/name.vue";

export default {
  name: "ExperimentsList",
  components: {
    DataTable
  },
  props: {
    dataSource: { type: String, required: true },
    actionsUrl: { type: String, required: true },
    activePageUrl: { type: String },
    archivedPageUrl: { type: String },
    currentViewMode: { type: String, required: true }
  },
  data() {
    return {
      reloadingTable: false
    };
  },
  computed: {
    columnDefs() {
      let columns = [
        {
          field: "name",
          flex: 1,
          headerName: this.i18n.t("experiments.card.name"),
          sortable: true,
          cellRenderer: NameRenderer
        },
        {
          field: "code",
          headerName: this.i18n.t("experiments.id"),
          sortable: true
        },
        {
          field: "created_at",
          headerName: this.i18n.t("experiments.card.start_date"),
          sortable: true
        },
        {
          field: "updated_at",
          headerName: this.i18n.t("experiments.card.modified_date"),
          sortable: true
        }
      ];

      if (this.currentViewMode == "archived") {
        columns.push({
          field: "archived_on",
          headerName: this.i18n.t("experiments.card.archived_date"),
          sortable: true
        });
      }

      columns.push({
        field: "total_tasks",
        headerName: this.i18n.t("experiments.card.completed_task"),
        cellRenderer: CompletedTasksRenderer,
        sortable: false
      });
      columns.push({
        field: "description",
        headerName: this.i18n.t("experiments.card.description"),
        sortable: false,
        cellStyle: { "white-space": "normal" },
        cellRenderer: DescriptionRenderer,
        autoHeight: true
      });

      return columns;
    },
    viewRenders() {
      return [{ type: "table" }, { type: "cards" }];
    },
    toolbarActions() {
      let left = [];

      left.push({
        name: "create",
        icon: "sn-icon sn-icon-new-task",
        label: this.i18n.t("experiments.toolbar.new_button"),
        type: "emit",
        path: this.createUrl,
        buttonStyle: "btn btn-primary"
      });

      return {
        left: left,
        right: []
      };
    },
    filters() {
      const filters = [
        {
          key: "query",
          type: "Text"
        },
        {
          key: "created_at",
          type: "DateRange",
          label: this.i18n.t("filters_modal.created_on.label")
        }
      ];

      return filters;
    }
  },
  methods: {}
};
</script>
