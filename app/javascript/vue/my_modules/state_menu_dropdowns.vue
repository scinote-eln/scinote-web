<template>
  <MenuDropdown
    :listItems="viewTypesMenu"
    :btnClasses="'btn btn-secondary !border-sn-light-grey px-3'"
    :btnText="typeBtnText"
    :caret="true"
    @change="toggleViewType($event)"
    position='right'>
  </MenuDropdown>
  <MenuDropdown
    :listItems="viewModesMenu"
    :btnClasses="'btn btn-secondary !border-sn-light-grey px-3'"
    :btnText="modeBtnText"
    :caret="true"
    position='right'>
  </MenuDropdown>
</template>

<script>
/* global I18n */
import MenuDropdown from '../shared/menu_dropdown.vue';

export default {
  components: {
    MenuDropdown
  },
  name: 'TaskStateDropdowns',
  props: {
    viewMode: { type: String, required: true },
    viewType: { type: String, required: true },
    viewTypePath: { type: String, required: true },
    activePath: { type: String, required: true },
    archivedPath: { type: String, required: true }
  },
  computed: {
    typeBtnText() {
      const currentViewType = this.viewType === 'canvas' ? 'cards' : 'table';
      return I18n.t(`toolbar.${currentViewType}_view`);
    },
    modeBtnText() {
      return I18n.t(`toolbar.${this.viewMode}_state`);
    },
    viewModesMenu() {
      return [
        {
          text: I18n.t('toolbar.active_state'),
          active: this.viewMode === 'active',
          url: this.activePath
        },
        {
          text: I18n.t('toolbar.archived_state'),
          active: this.viewMode === 'archived',
          url: this.archivedPath
        }
      ];
    },
    viewTypesMenu() {
      return [
        {
          text: I18n.t('toolbar.table_view'),
          active: this.viewType === 'table',
          emit: 'change',
          params: { viewType: 'table' }
        },
        {
          text: I18n.t('toolbar.cards_view'),
          active: this.viewType === 'canvas',
          emit: 'change',
          params: { viewType: 'canvas' }
        }
      ];
    }

  },
  methods: {
    toggleViewType(params) {
      if (params.viewType === this.viewType) return;

      $.ajax({
        method: 'put',
        url: this.viewTypePath,
        data: {
          experiment: { view_type: params.viewType }
        }
      });
    }
  }
};
</script>
