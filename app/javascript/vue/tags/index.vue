<template>
  <div class="h-full">
    <DataTable :columnDefs="columnDefs"
               tableId="TagsIndexTable"
               :dataUrl="dataSource"
               :reloadingTable="reloadingTable"
               :toolbarActions="toolbarActions"
               :actionsUrl="actionsUrl"
               :newRowTemplate="newRowTemplate"
               :addingNewRow="addingNewRow"
               @tableReloaded="reloadingTable = false"
               @startCreate="addingNewRow = true"
               @cancelCreation="cancelCreation"
               @changeColor="changeColor"
               @changeName="changeName"
               @createRow="createTag"
               @merge="openMergeModal"
               @delete="deleteTag"
      />
    <merge-modal v-if="mergeIds"
                 :team-id="teamId"
                 :mergeIds="mergeIds"
                 :list-url="listUrl"
                 @close="mergeIds = null; reloadingTable = true"/>
    <confirmationModal
      :title="deleteTitle"
      :description="deleteDescription"
      confirmClass="btn btn-danger"
      :confirmText="i18n.t('tags.delete_modal.confirm')"
      ref="deleteModal"
    ></confirmationModal>
  </div>
</template>

<script>
/* global HelperModule */

import axios from '../../packs/custom_axios.js';

import DataTable from '../shared/datatable/table.vue';
import colorRenderer from './renderers/color.vue';
import nameRenderer from './renderers/name.vue';
import mergeModal from './modals/merge.vue';
import confirmationModal from '../shared/confirmation_modal.vue';

import {
  team_tag_path,
} from '../../routes.js';


export default {
  name: 'TagsTable',
  components: {
    DataTable,
    colorRenderer,
    nameRenderer,
    mergeModal,
    confirmationModal
  },
  props: {
    dataSource: {
      type: String,
      required: true
    },
    actionsUrl: {
      type: String,
      required: true
    },
    createUrl: {
      type: String
    },
    tagsColors: {
      type: Object,
      required: true
    },
    teamId: {
      required: true
    },
    listUrl: {
      type: String,
      required: true
    }
  },
  data() {
    return {
      reloadingTable: false,
      addingNewRow: false,
      mergeIds: null,
      deleteTitle: null,
      deleteDescription: null,
      newRowTemplate: {
        name: {
          value: '',
          isValid: false
        },
        color: {
          value: this.tagsColors[Math.floor(Math.random() * this.tagsColors.length)],
          isValid: true
        }
      },
      columnDefs: [
        {
          field: 'name',
          headerName: this.i18n.t('tags.index.tag_name'),
          sortable: true,
          notSelectable: true,
          cellRenderer: nameRenderer,
        }, {
          field: 'color',
          headerName: this.i18n.t('tags.index.color'),
          sortable: true,
          notSelectable: true,
          cellRenderer: colorRenderer,
          cellRendererParams: {
            colors: this.tagsColors
          },
        }, {
          field: 'taggings_count',
          headerName: this.i18n.t('tags.index.used_in'),
          sortable: true,
          cellRenderer: (params) => {
            const count = params.value;

            if (count === undefined || count === null) {
              return '';
            }

            const placeText = count === 1 ? this.i18n.t('tags.index.place') : this.i18n.t('tags.index.places');
            return `${count} ${placeText}`;
          },
        }, {
          field: 'created_by',
          headerName: this.i18n.t('user_groups.index.created_by'),
          sortable: true
        }, {
          field: 'created_at',
          headerName: this.i18n.t('user_groups.index.created_on'),
          sortable: true
        }, {
          field: 'updated_at',
          headerName: this.i18n.t('user_groups.index.updated_on'),
          sortable: true,
        }
      ]
    };
  },
  computed: {
    toolbarActions() {
      const left = [];
      if (this.createUrl) {
        left.push({
          name: 'startCreate',
          icon: 'sn-icon sn-icon-new-task',
          label: this.i18n.t('tags.index.new_tag'),
          type: 'emit',
          path: this.createUrl,
          buttonStyle: 'btn btn-primary'
        });
      }
      return {
        left,
        right: []
      };
    }
  },
  methods: {
    changeName(name, tag) {
      axios.patch(team_tag_path(tag.id, { team_id: tag.team_id }), {
        tag: {
          name
        }
      }).then(() => {
        this.reloadingTable = true;
      })
    },
    changeColor(color, tag) {
      axios.patch(team_tag_path(tag.id, { team_id: tag.team_id }), {
        tag: {
          color
        }
      }).then(() => {
        this.reloadingTable = true;
      })
    },
    openMergeModal(event, rows) {
      this.mergeIds = rows.map(row => row.id);
    },
    cancelCreation() {
      this.addingNewRow = false;
    },
    createTag(newTag) {
      this.addingNewRow = false;
      axios.post(this.createUrl, {
        tag: {
          name: newTag.name.value,
          color: newTag.color.value
        }
      }).then(() => {
        this.reloadingTable = true;
      });
    },
    async deleteTag(event, rows) {
      if (rows.length === 1) {
        this.deleteTitle = this.i18n.t('tags.delete_modal.single_title', { tag: rows[0].name });
        this.deleteDescription = this.i18n.t('tags.delete_modal.single_description_html', { count: rows[0].taggings_count });
      } else {
        this.deleteTitle = this.i18n.t('tags.delete_modal.multiple_title', { count: rows.length });
        const totalTaggings = rows.reduce((sum, row) => sum + row.taggings_count, 0);
        this.deleteDescription = this.i18n.t('tags.delete_modal.multiple_description_html', { tags_count: rows.length, count: totalTaggings });
      }

      const ok = await this.$refs.deleteModal.show();
      if (ok) {
        axios.delete(event.path).then(() => {
          this.reloadingTable = true;
        });
      }
    }
  }
};

</script>
